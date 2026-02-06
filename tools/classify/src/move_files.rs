use std::path::Path;

use anyhow::Result;

use crate::types::CsvRow;

/// Move misattributed images to their correct set directories.
/// Returns (moved_count, skipped_count).
pub fn move_misattributed(root: &Path, rows: &[CsvRow]) -> Result<(usize, usize)> {
    let mut moved = 0usize;
    let mut skipped = 0usize;

    for row in rows {
        if row.needs_move != "TRUE" {
            continue;
        }

        let dest_dir = root.join(&row.move_to).join("cards");
        let dest_path = dest_dir.join(&row.filename);

        // Create destination directory if needed
        if !dest_dir.exists() {
            std::fs::create_dir_all(&dest_dir)?;
        }

        // Skip if destination already exists
        if dest_path.exists() {
            eprintln!("  SKIP (exists): {}", row.filename);
            skipped += 1;
            continue;
        }

        let source = Path::new(&row.file_path);
        if !source.exists() {
            eprintln!("  SKIP (source missing): {}", row.filename);
            skipped += 1;
            continue;
        }

        // Try rename first, fall back to copy+delete
        if std::fs::rename(source, &dest_path).is_ok() {
            eprintln!("  MOVED: {} -> {}/cards/", row.filename, row.move_to);
            moved += 1;
        } else {
            std::fs::copy(source, &dest_path)?;
            std::fs::remove_file(source)?;
            eprintln!("  MOVED (copy): {} -> {}/cards/", row.filename, row.move_to);
            moved += 1;
        }
    }

    Ok((moved, skipped))
}
