mod config;
mod csv_log;
mod download;
mod rate_limiter;
mod sources;
mod types;

use std::collections::{BTreeMap, HashSet};
use std::path::PathBuf;

use anyhow::{bail, Result};
use clap::Parser;

use types::{ImageCandidate, VALID_SETS};

#[derive(Parser)]
#[command(
    name = "scrape",
    about = "Multi-source card image scraper for Kayou Transformers"
)]
struct Cli {
    /// Target set (TF01, TF02, etc.). Omit to scrape all sets.
    #[arg(short, long)]
    set: Option<String>,

    /// Sources to use (comma-separated: tca,ebay,google,reddit,forum,direct). Omit for all.
    #[arg(short = 'S', long, value_delimiter = ',')]
    source: Option<Vec<String>>,

    /// Concurrent downloads per source
    #[arg(short = 'j', long, default_value_t = 4)]
    concurrency: usize,

    /// Output scrape log CSV path
    #[arg(short, long, default_value = "scripts/scrape_log.csv")]
    output: String,

    /// Repository root directory (auto-detected via CLAUDE.md)
    #[arg(long)]
    root: Option<String>,

    /// Discover URLs without downloading
    #[arg(long)]
    dry_run: bool,

    /// Direct URLs to download (use with --source direct --url-set SET)
    #[arg(long, value_delimiter = ',')]
    urls: Option<Vec<String>>,

    /// Target set for direct URLs
    #[arg(long, default_value = "")]
    url_set: String,

    /// Override rate limit delay per source (seconds)
    #[arg(long)]
    delay: Option<f64>,

    /// Enable SHA-256 content deduplication
    #[arg(long)]
    dedup_hash: bool,
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    // Validate set
    if let Some(ref set) = cli.set {
        let upper = set.to_uppercase();
        if !VALID_SETS.contains(&upper.as_str()) {
            bail!(
                "Unknown set '{}'. Valid sets: {}",
                set,
                VALID_SETS.join(", ")
            );
        }
    }

    // Validate sources
    let enabled_sources: Vec<String> = match &cli.source {
        Some(sources) => {
            for s in sources {
                if !sources::SOURCE_NAMES.contains(&s.as_str()) {
                    bail!(
                        "Unknown source '{}'. Valid sources: {}",
                        s,
                        sources::SOURCE_NAMES.join(", ")
                    );
                }
            }
            sources.clone()
        }
        None => {
            // Default: all sources except direct (requires explicit --urls)
            sources::SOURCE_NAMES
                .iter()
                .filter(|s| **s != "direct")
                .map(|s| s.to_string())
                .collect()
        }
    };

    // Resolve root
    let root = match &cli.root {
        Some(r) => PathBuf::from(r),
        None => detect_root()?,
    };

    if !root.is_dir() {
        bail!("Root directory not found: {}", root.display());
    }

    // Resolve output path
    let output_path = if PathBuf::from(&cli.output).is_absolute() {
        PathBuf::from(&cli.output)
    } else {
        root.join(&cli.output)
    };

    eprintln!("=== Kayou Transformers Multi-Source Card Image Scraper (Rust) ===\n");
    eprintln!("Root:        {}", root.display());
    eprintln!("Sources:     {}", enabled_sources.join(", "));
    eprintln!("Concurrency: {}", cli.concurrency);
    eprintln!("Output:      {}", output_path.display());
    if let Some(ref set) = cli.set {
        eprintln!("Target set:  {}", set.to_uppercase());
    }
    if cli.dry_run {
        eprintln!("Mode:        dry-run (discover only)");
    }
    if cli.dedup_hash {
        eprintln!("Dedup:       SHA-256 content hash");
    }
    eprintln!();

    // Load existing scrape log for idempotency
    let (existing_rows, seen_urls) = csv_log::read_existing(&output_path)?;
    if !seen_urls.is_empty() {
        eprintln!("Found {} already-scraped URLs in log", seen_urls.len());
    }

    // Determine target sets
    let target_sets: Vec<String> = match &cli.set {
        Some(set) => vec![set.to_uppercase()],
        None => VALID_SETS.iter().map(|s| s.to_string()).collect(),
    };

    // Build sources
    let direct_urls = cli.urls.clone().unwrap_or_default();
    let source_instances: Vec<Box<dyn sources::Source>> = enabled_sources
        .iter()
        .filter_map(|name| {
            sources::create_source(name, cli.delay, &direct_urls, &cli.url_set)
        })
        .collect();

    // Discovery phase: collect all candidates
    let mut all_candidates: Vec<ImageCandidate> = Vec::new();

    for source in &source_instances {
        eprintln!("\n========== Source: {} ==========", source.name());

        for set_code in &target_sets {
            let request = config::search_requests_for_set(set_code);

            if request.english_terms.is_empty() && request.chinese_terms.is_empty() {
                // Direct source with no terms is fine
                if source.name() != "direct" {
                    continue;
                }
            }

            eprintln!("\n--- {} / {} ---", source.name(), set_code);

            match source.discover(&request).await {
                Ok(candidates) => {
                    eprintln!(
                        "  Discovered {} candidates for {}",
                        candidates.len(),
                        set_code
                    );
                    all_candidates.extend(candidates);
                }
                Err(e) => {
                    eprintln!("  Error discovering {} for {}: {}", source.name(), set_code, e);
                }
            }
        }
    }

    eprintln!("\n=== Discovery Complete ===");
    eprintln!("Total candidates: {}", all_candidates.len());

    // Deduplicate by URL against existing log + within batch
    let mut unique_urls = HashSet::new();
    let mut deduped_candidates = Vec::new();
    let mut skipped_existing = 0usize;
    let mut skipped_duplicate = 0usize;

    for candidate in all_candidates {
        if seen_urls.contains(&candidate.image_url) {
            skipped_existing += 1;
            continue;
        }
        if !unique_urls.insert(candidate.image_url.clone()) {
            skipped_duplicate += 1;
            continue;
        }
        deduped_candidates.push(candidate);
    }

    eprintln!("After dedup: {} new ({} already in log, {} duplicates)",
        deduped_candidates.len(), skipped_existing, skipped_duplicate
    );

    if cli.dry_run {
        // Print discovered URLs and exit
        eprintln!("\n=== Dry Run Results ===\n");
        print_discovery_summary(&deduped_candidates);
        return Ok(());
    }

    if deduped_candidates.is_empty() {
        eprintln!("\nNo new images to download.");
        return Ok(());
    }

    // Download phase
    eprintln!("\n=== Downloading {} images ===\n", deduped_candidates.len());

    let downloader = download::Downloader::new(cli.concurrency, cli.dedup_hash);
    let mut content_hashes = HashSet::new();
    let new_entries = downloader
        .download_all(deduped_candidates, &root, &mut content_hashes)
        .await;

    // Merge and write log
    let mut all_rows = existing_rows;
    let new_count = new_entries.len();
    let success_count = new_entries.iter().filter(|e| e.success == "TRUE").count();
    all_rows.extend(new_entries);

    csv_log::write_csv(&output_path, &all_rows)?;
    eprintln!(
        "\nWrote {} rows ({} new, {} successful) to {}",
        all_rows.len(),
        new_count,
        success_count,
        output_path.display()
    );

    // Print summary
    print_summary(&all_rows);

    eprintln!("\nDone.");
    Ok(())
}

fn detect_root() -> Result<PathBuf> {
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

    Ok(cwd)
}

fn print_discovery_summary(candidates: &[ImageCandidate]) {
    let mut by_source_set: BTreeMap<(&str, &str), usize> = BTreeMap::new();
    for c in candidates {
        *by_source_set
            .entry((c.source.as_str(), c.set_code.as_str()))
            .or_insert(0) += 1;
    }

    eprintln!("Candidates by source × set:");
    for ((source, set), count) in &by_source_set {
        eprintln!("  {} / {}: {}", source, set, count);
    }

    // Print individual URLs for small batches
    if candidates.len() <= 50 {
        eprintln!("\nAll discovered URLs:");
        for c in candidates {
            eprintln!("  [{}] {} → {}", c.source, c.set_code, c.image_url);
        }
    }
}

fn print_summary(rows: &[types::ScrapeLogEntry]) {
    let success_count = rows.iter().filter(|r| r.success == "TRUE").count();
    let fail_count = rows.iter().filter(|r| r.success == "FALSE").count();

    eprintln!("\n=== Scrape Summary ===\n");
    eprintln!("Total entries: {}", rows.len());
    eprintln!("Successful:    {}", success_count);
    eprintln!("Failed:        {}", fail_count);

    // By source
    let mut by_source: BTreeMap<&str, (usize, usize)> = BTreeMap::new();
    for row in rows {
        let entry = by_source.entry(row.source.as_str()).or_insert((0, 0));
        if row.success == "TRUE" {
            entry.0 += 1;
        }
        entry.1 += 1;
    }

    if !by_source.is_empty() {
        eprintln!("\nBy source:");
        for (source, (ok, total)) in &by_source {
            eprintln!("  {}: {}/{}", source, ok, total);
        }
    }

    // By set
    let mut by_set: BTreeMap<&str, (usize, usize)> = BTreeMap::new();
    for row in rows {
        let entry = by_set.entry(row.set_code.as_str()).or_insert((0, 0));
        if row.success == "TRUE" {
            entry.0 += 1;
        }
        entry.1 += 1;
    }

    if !by_set.is_empty() {
        eprintln!("\nBy set:");
        for (set, (ok, total)) in &by_set {
            eprintln!("  {}: {}/{}", set, ok, total);
        }
    }
}
