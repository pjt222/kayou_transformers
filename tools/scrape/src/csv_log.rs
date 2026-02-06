use std::collections::HashSet;
use std::path::Path;

use anyhow::{Context, Result};

use crate::types::ScrapeLogEntry;

const HEADERS: &[&str] = &[
    "timestamp",
    "source",
    "set_code",
    "search_term",
    "image_url",
    "local_path",
    "success",
];

/// Read existing scrape log CSV. Returns (rows, set of already-scraped URLs).
pub fn read_existing(path: &Path) -> Result<(Vec<ScrapeLogEntry>, HashSet<String>)> {
    if !path.exists() {
        return Ok((Vec::new(), HashSet::new()));
    }

    let mut reader = csv::ReaderBuilder::new()
        .has_headers(true)
        .flexible(true)
        .from_path(path)
        .context("failed to open existing scrape log CSV")?;

    let mut rows = Vec::new();
    let mut seen_urls = HashSet::new();

    for record in reader.records() {
        let record = match record {
            Ok(r) => r,
            Err(_) => continue,
        };

        if record.len() < 7 {
            continue;
        }

        let image_url = record.get(4).unwrap_or("").to_string();
        if !image_url.is_empty() {
            seen_urls.insert(image_url.clone());
        }

        rows.push(ScrapeLogEntry {
            timestamp: record.get(0).unwrap_or("").to_string(),
            source: record.get(1).unwrap_or("").to_string(),
            set_code: record.get(2).unwrap_or("").to_string(),
            search_term: record.get(3).unwrap_or("").to_string(),
            image_url,
            local_path: record.get(5).unwrap_or("").to_string(),
            success: record.get(6).unwrap_or("FALSE").to_string(),
        });
    }

    Ok((rows, seen_urls))
}

/// Write all rows to scrape log CSV with R-compatible format.
pub fn write_csv(path: &Path, rows: &[ScrapeLogEntry]) -> Result<()> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).ok();
    }

    let mut writer = csv::WriterBuilder::new()
        .quote_style(csv::QuoteStyle::Necessary)
        .from_path(path)
        .context("failed to create CSV writer")?;

    writer.write_record(HEADERS)?;

    for row in rows {
        writer.write_record([
            &row.timestamp,
            &row.source,
            &row.set_code,
            &row.search_term,
            &row.image_url,
            &row.local_path,
            &row.success,
        ])?;
    }

    writer.flush()?;
    Ok(())
}
