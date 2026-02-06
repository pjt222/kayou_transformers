mod api;
mod classify;
mod csv_io;
mod move_files;
mod types;

use std::path::PathBuf;
use std::sync::Arc;

use anyhow::{bail, Context, Result};
use clap::Parser;

#[derive(Parser)]
#[command(name = "classify", about = "Classify Kayou Transformers card images via Claude API")]
struct Cli {
    /// Target set (TF01, TFKB01, etc.). Omit to classify all sets.
    #[arg(short, long)]
    set: Option<String>,

    /// Concurrent API requests
    #[arg(short = 'j', long, default_value_t = 20)]
    concurrency: usize,

    /// Output CSV path
    #[arg(short, long, default_value = "scripts/classification_results.csv")]
    output: String,

    /// Move misattributed images after classifying
    #[arg(long)]
    r#move: bool,

    /// Claude model to use
    #[arg(long, default_value = "claude-sonnet-4-5-20250929")]
    model: String,

    /// Repository root directory (auto-detected from binary location)
    #[arg(long)]
    root: Option<String>,
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    // Validate set
    if let Some(ref set) = cli.set {
        let upper = set.to_uppercase();
        if !classify::VALID_SETS.contains(&upper.as_str()) {
            bail!(
                "Unknown set '{}'. Valid sets: {}",
                set,
                classify::VALID_SETS.join(", ")
            );
        }
    }

    // Resolve root
    let root = match &cli.root {
        Some(r) => PathBuf::from(r),
        None => detect_root()?,
    };

    if !root.is_dir() {
        bail!("Root directory not found: {}", root.display());
    }

    // Resolve output path (relative to root)
    let output_path = if PathBuf::from(&cli.output).is_absolute() {
        PathBuf::from(&cli.output)
    } else {
        root.join(&cli.output)
    };

    // Read API key
    let api_key = std::env::var("ANTHROPIC_API_KEY")
        .context("ANTHROPIC_API_KEY environment variable not set")?;

    eprintln!("=== Kayou Transformers Card Image Classifier (Rust) ===\n");
    eprintln!("Root:        {}", root.display());
    eprintln!("Model:       {}", cli.model);
    eprintln!("Concurrency: {}", cli.concurrency);
    eprintln!("Output:      {}", output_path.display());
    if let Some(ref set) = cli.set {
        eprintln!("Target set:  {}", set.to_uppercase());
    }
    if cli.r#move {
        eprintln!("Mode:        classify + move");
    }
    eprintln!();

    // Load existing CSV for idempotency
    let (existing_rows, already_classified) = csv_io::read_existing(&output_path)?;
    if !already_classified.is_empty() {
        eprintln!("Found {} already-classified images in CSV", already_classified.len());
    }

    // Discover images
    let target_set = cli.set.as_deref().map(|s| s.to_uppercase());
    let images = classify::discover_images(&root, target_set.as_deref())?;

    if images.is_empty() {
        eprintln!("No card images found.");
        return Ok(());
    }

    eprintln!("Found {} images total", images.len());

    // Build client
    let system_prompt = classify::build_system_prompt();
    let client = Arc::new(api::ApiClient::new(
        api_key,
        cli.model.clone(),
        system_prompt,
        cli.concurrency,
    ));

    // Classify
    let new_rows = classify::classify_all(client, images, &already_classified).await;

    // Merge and write
    let mut all_rows = existing_rows;
    let new_count = new_rows.len();
    all_rows.extend(new_rows);

    csv_io::write_csv(&output_path, &all_rows)?;
    eprintln!("\nWrote {} rows ({} new) to {}", all_rows.len(), new_count, output_path.display());

    // Print summary
    print_summary(&all_rows);

    // Move files if requested
    if cli.r#move {
        let needs_move: Vec<_> = all_rows.iter().filter(|r| r.needs_move == "TRUE").collect();
        if needs_move.is_empty() {
            eprintln!("\nNo files need moving.");
        } else {
            eprintln!("\n=== Moving {} misattributed files ===\n", needs_move.len());
            let (moved, skipped) = move_files::move_misattributed(&root, &all_rows)?;
            eprintln!("\nMoved: {}, Skipped: {}", moved, skipped);
        }
    } else {
        let move_count = all_rows.iter().filter(|r| r.needs_move == "TRUE").count();
        if move_count > 0 {
            eprintln!("\n{} files need moving. Re-run with --move to relocate.", move_count);
        }
    }

    eprintln!("\nDone.");
    Ok(())
}

fn detect_root() -> Result<PathBuf> {
    // Try current directory first
    let cwd = std::env::current_dir()?;

    // Walk up looking for CLAUDE.md (repo marker)
    let mut dir = cwd.as_path();
    loop {
        if dir.join("CLAUDE.md").exists() {
            return Ok(dir.to_path_buf());
        }
        match dir.parent() {
            Some(parent) => dir = parent,
            None => break,
        }
    }

    // Fall back to cwd
    Ok(cwd)
}

fn print_summary(rows: &[types::CsvRow]) {
    let n_cards = rows.iter().filter(|r| r.is_card == "TRUE").count();
    let n_not_cards = rows.iter().filter(|r| r.is_card == "FALSE").count();
    let n_errors = rows.iter().filter(|r| r.is_card == "NA").count();
    let n_needs_move = rows.iter().filter(|r| r.needs_move == "TRUE").count();

    eprintln!("\n=== Classification Summary ===\n");
    eprintln!("Cards identified:    {}", n_cards);
    eprintln!("Non-card images:     {}", n_not_cards);
    eprintln!("Errors:              {}", n_errors);
    eprintln!("Needs reclassifying: {}", n_needs_move);

    if n_cards > 0 {
        let card_rows: Vec<_> = rows.iter().filter(|r| r.is_card == "TRUE").collect();

        eprintln!("\nCards by detected set:");
        let mut set_counts = std::collections::BTreeMap::new();
        for row in &card_rows {
            *set_counts.entry(row.set_code.as_str()).or_insert(0usize) += 1;
        }
        for (set, count) in &set_counts {
            eprintln!("  {}: {}", set, count);
        }

        eprintln!("\nConfidence breakdown:");
        let mut conf_counts = std::collections::BTreeMap::new();
        for row in &card_rows {
            *conf_counts.entry(row.confidence.as_str()).or_insert(0usize) += 1;
        }
        for (conf, count) in &conf_counts {
            eprintln!("  {}: {}", conf, count);
        }
    }
}
