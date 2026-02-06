use std::collections::HashSet;
use std::path::{Path, PathBuf};
use std::sync::Arc;

use anyhow::{Context, Result};
use base64::Engine;
use indicatif::{ProgressBar, ProgressStyle};
use tokio::sync::mpsc;

use crate::api::ApiClient;
use crate::types::CsvRow;

pub const VALID_SETS: &[&str] = &[
    "TF01", "TF02", "TF03", "TFKB01", "TFH01", "TFO01", "TF40Y", "TFEU01",
];

pub fn build_system_prompt() -> String {
    let set_descriptions = [
        "- TF01 (Series 1): 124 cards, rarities: BP/LR/AR/UR/SHR/SSR/HR/SR/R",
        "- TF02 (Series 2): 124 cards, rarities: BP/LR/AR/UR/SHR/SSR/HR/SR/R",
        "- TF03 (Series 3): 124 cards, rarities: BP/LR/AR/UR/SHR/SSR/HR/SR/R",
        "- TFKB01 (Movie Subset): 48 cards, rarities: AR/HR/SR",
        "- TFH01 (Headmasters): 71 cards, rarities: BP/PR/UR/SSR/SR/SL",
        "- TFO01 (Transformers One): 149 cards, rarities: XR/SHR/UR-S/UR/HR/SSR/SR/TP",
        "- TF40Y (40th Anniversary): 150 cards, rarities: XR/USR/CR/LGR/UR/HR/SSR/SR/SCR/TY/PR",
        "- TFEU01 (Energon Universe): 254 cards, rarities: BP/XR-star/XR/OR-star/OR/WR/LR-star/LR/UR-star/UR/SR/SSR/HR/AR",
    ];

    format!(
        "You are classifying Kayou (卡游) Transformers trading card images.\n\n\
         SETS (with rarity systems):\n{}\n\n\
         KEY VISUAL DIFFERENCES:\n\
         - TFEU01 (Energon Universe): Modern Western comic art style (IDW/Skybound), \
         English text, bold colors. Rarities include XR/OR/WR/LR/UR/SR/SSR/HR/AR/BP. \
         Cards have a distinctive comic-panel aesthetic with English character names.\n\
         - TF01-TF03 (Series 1-3): G1 cartoon style, Chinese text on cards, \
         rarities BP/LR/AR/UR/SHR/SSR/HR/SR/R. Card numbers like R-001, SR-005.\n\
         - TFKB01 (Movie Subset): Movie character art (Drift, Crosshairs, Barricade, \
         Nitro Zeus, Wheelie), parallel subset from TF02 boxes, only AR/HR/SR rarities.\n\
         - TFH01 (Headmasters): Headmasters anime style, includes SL (Scene Landscape) \
         horizontal cards. Rarities: BP/PR/UR/SSR/SR/SL.\n\
         - TFO01 (Transformers One): Movie style from 2024 animated film. Includes \
         TP (The Primes) subset with all 13 Primes. Rarities: XR/SHR/UR-S/UR/HR/SSR/SR/TP.\n\
         - TF40Y (40th Anniversary): Mixed G1/Beast Wars/Movie art. XR limited to 199 copies. \
         Rarities: XR/USR/CR/LGR/UR/HR/SSR/SR + SCR/TY/PR exclusives.\n\n\
         CLASSIFICATION INSTRUCTIONS:\n\
         Look for: rarity code printed on card face, art style, language (Chinese vs English), \
         card numbering format, and overall design aesthetic.\n\
         If image is NOT a single card front (packaging, box photo, multiple cards, \
         back of card, thumbnail, watermarked listing photo), set is_card = false.\n\
         If you can see the rarity code printed on the card, report it exactly.\n\
         If you can read a card number, report it (e.g. '007' or 'SR-005').\n\
         For character names, use the English name (e.g. 'Optimus Prime', 'Megatron').",
        set_descriptions.join("\n")
    )
}

/// Discover image files in `{root}/{set}/cards/*.jpg|jpeg|png|webp`.
pub fn discover_images(root: &Path, target_set: Option<&str>) -> Result<Vec<PathBuf>> {
    let sets: Vec<&str> = match target_set {
        Some(s) => vec![s],
        None => VALID_SETS.to_vec(),
    };

    let mut images = Vec::new();
    let extensions = ["jpg", "jpeg", "png", "webp"];

    for set in sets {
        let cards_dir = root.join(set).join("cards");
        if !cards_dir.is_dir() {
            continue;
        }

        let entries = std::fs::read_dir(&cards_dir)
            .with_context(|| format!("failed to read {}", cards_dir.display()))?;

        for entry in entries {
            let entry = entry?;
            let path = entry.path();
            if !path.is_file() {
                continue;
            }
            if let Some(ext) = path.extension().and_then(|e| e.to_str()) {
                if extensions.contains(&ext.to_lowercase().as_str()) {
                    images.push(path);
                }
            }
        }
    }

    images.sort();
    Ok(images)
}

/// Determine media type from file extension.
fn media_type_for(path: &Path) -> &'static str {
    match path
        .extension()
        .and_then(|e| e.to_str())
        .map(|e| e.to_lowercase())
        .as_deref()
    {
        Some("png") => "image/png",
        Some("webp") => "image/webp",
        _ => "image/jpeg",
    }
}

/// Extract the set directory name from a path like `.../TF01/cards/foo.jpg`.
fn set_from_path(path: &Path) -> String {
    path.parent() // cards/
        .and_then(|p| p.parent()) // TF01/
        .and_then(|p| p.file_name())
        .and_then(|n| n.to_str())
        .unwrap_or("UNKNOWN")
        .to_string()
}

/// Classify all images, returning new CsvRows.
pub async fn classify_all(
    client: Arc<ApiClient>,
    images: Vec<PathBuf>,
    already_classified: &HashSet<String>,
) -> Vec<CsvRow> {
    let to_classify: Vec<PathBuf> = images
        .into_iter()
        .filter(|p| {
            let filename = p.file_name().unwrap_or_default().to_string_lossy().to_string();
            let directory = set_from_path(p);
            let key = format!("{}/{}", directory, filename);
            !already_classified.contains(&key)
        })
        .collect();

    if to_classify.is_empty() {
        eprintln!("All images already classified (idempotent skip).");
        return Vec::new();
    }

    let total = to_classify.len();
    eprintln!("Classifying {} images...", total);

    let progress = ProgressBar::new(total as u64);
    progress.set_style(
        ProgressStyle::default_bar()
            .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} ({per_sec}) {msg}")
            .unwrap()
            .progress_chars("=> "),
    );

    let (tx, mut rx) = mpsc::channel::<CsvRow>(total);

    for image_path in to_classify {
        let client = Arc::clone(&client);
        let tx = tx.clone();
        let pb = progress.clone();

        tokio::spawn(async move {
            let filename = image_path
                .file_name()
                .unwrap_or_default()
                .to_string_lossy()
                .to_string();
            let current_directory = set_from_path(&image_path);
            let file_path_str = image_path.to_string_lossy().to_string();

            let row = match classify_single(&client, &image_path).await {
                Ok(result) => CsvRow::from_classification(
                    &result,
                    &file_path_str,
                    &filename,
                    &current_directory,
                ),
                Err(e) => CsvRow::error_row(
                    &file_path_str,
                    &filename,
                    &current_directory,
                    &e.to_string(),
                ),
            };

            pb.set_message(format!("{}/{}", current_directory, filename));
            pb.inc(1);
            let _ = tx.send(row).await;
        });
    }

    // Drop the sender so the receiver finishes when all tasks complete
    drop(tx);

    let mut results = Vec::with_capacity(total);
    while let Some(row) = rx.recv().await {
        results.push(row);
    }

    progress.finish_with_message("done");

    // Sort by filename for deterministic output
    results.sort_by(|a, b| a.filename.cmp(&b.filename));
    results
}

async fn classify_single(
    client: &ApiClient,
    image_path: &Path,
) -> Result<crate::types::ClassificationResult> {
    let data = std::fs::read(image_path)
        .with_context(|| format!("failed to read {}", image_path.display()))?;

    let encoded = base64::engine::general_purpose::STANDARD.encode(&data);
    let media_type = media_type_for(image_path).to_string();

    client.classify_image(encoded, media_type).await
}
