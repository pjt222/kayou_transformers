use std::collections::HashSet;
use std::path::Path;

use anyhow::{Context, Result};

use crate::types::CsvRow;

const HEADERS: &[&str] = &[
    "is_card",
    "set_code",
    "rarity_code",
    "character_name",
    "card_number",
    "confidence",
    "notes",
    "file_path",
    "filename",
    "current_directory",
    "needs_move",
    "move_to",
];

/// Read existing CSV and return (rows, set of already-classified filenames).
pub fn read_existing(path: &Path) -> Result<(Vec<CsvRow>, HashSet<String>)> {
    if !path.exists() {
        return Ok((Vec::new(), HashSet::new()));
    }

    let mut reader = csv::ReaderBuilder::new()
        .has_headers(true)
        .flexible(true)
        .from_path(path)
        .context("failed to open existing CSV")?;

    let mut rows = Vec::new();
    let mut seen = HashSet::new();

    for record in reader.records() {
        let record = match record {
            Ok(r) => r,
            Err(_) => continue, // skip malformed rows
        };

        if record.len() < 12 {
            continue;
        }

        let filename = record.get(8).unwrap_or("").to_string();
        let current_directory = record.get(9).unwrap_or("").to_string();
        // Use directory/filename as key since filenames aren't unique across sets
        seen.insert(format!("{}/{}", current_directory, filename));

        rows.push(CsvRow {
            is_card: record.get(0).unwrap_or("NA").to_string(),
            set_code: record.get(1).unwrap_or("UNKNOWN").to_string(),
            rarity_code: record.get(2).unwrap_or("NA").to_string(),
            character_name: record.get(3).unwrap_or("NA").to_string(),
            card_number: record.get(4).unwrap_or("NA").to_string(),
            confidence: record.get(5).unwrap_or("low").to_string(),
            notes: record.get(6).unwrap_or("").to_string(),
            file_path: record.get(7).unwrap_or("").to_string(),
            filename,
            current_directory: record.get(9).unwrap_or("").to_string(),
            needs_move: record.get(10).unwrap_or("FALSE").to_string(),
            move_to: record.get(11).unwrap_or("NA").to_string(),
        });
    }

    Ok((rows, seen))
}

/// Write all rows to CSV with R-compatible quoting.
pub fn write_csv(path: &Path, rows: &[CsvRow]) -> Result<()> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).ok();
    }

    let mut writer = csv::WriterBuilder::new()
        .quote_style(csv::QuoteStyle::Necessary)
        .from_path(path)
        .context("failed to create CSV writer")?;

    // Write header
    writer.write_record(HEADERS)?;

    for row in rows {
        writer.write_record(&[
            &row.is_card,
            &row.set_code,
            &row.rarity_code,
            &row.character_name,
            &row.card_number,
            &row.confidence,
            &row.notes,
            &row.file_path,
            &row.filename,
            &row.current_directory,
            &row.needs_move,
            &row.move_to,
        ])?;
    }

    writer.flush()?;
    Ok(())
}
