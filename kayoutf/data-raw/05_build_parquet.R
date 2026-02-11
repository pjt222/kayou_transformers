# Master build script: Run all data-raw scripts and write Parquet files
# Usage: source("data-raw/05_build_parquet.R") from the package root

library(arrow)
library(dplyr)

pkg_root <- if (basename(getwd()) == "kayoutf") getwd() else file.path(getwd(), "kayoutf")
setwd(pkg_root)

cat("Building kayoutf parquet files...\n")
cat("Working directory:", getwd(), "\n\n")

# Ensure output directories exist
dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
dir.create("data-raw/sources", recursive = TRUE, showWarnings = FALSE)

# --- Step 1: Run data definition scripts ---
cat("Step 1: Running data definition scripts...\n")

source("data-raw/01_sets.R")
cat("  - Sets:", nrow(sets), "rows\n")

source("data-raw/02_rarities.R")
cat("  - Rarities:", nrow(rarities), "rows\n")

source("data-raw/03_products.R")
cat("  - Products:", nrow(products), "rows\n")

source("data-raw/04_characters.R")
cat("  - Characters:", nrow(characters), "rows\n")

source("data-raw/06_sources.R")
cat("  - Sources:", nrow(sources), "rows\n")

# --- Step 2: Run card data scripts for each set ---
cat("\nStep 2: Building card data per set...\n")

source("data-raw/03_cards_tfeu01.R")
cat("  - TFEU01:", nrow(tfeu01_cards), "cards\n")

source("data-raw/03_cards_tf01.R")
cat("  - TF01:", nrow(tf01_cards), "cards\n")

source("data-raw/03_cards_tf02.R")
cat("  - TF02:", nrow(tf02_cards), "cards\n")

source("data-raw/03_cards_tf03.R")
cat("  - TF03:", nrow(tf03_cards), "cards\n")

source("data-raw/03_cards_tfkb01.R")
cat("  - TFKB01:", nrow(tfkb01_cards), "cards\n")

source("data-raw/03_cards_tfh01.R")
cat("  - TFH01:", nrow(tfh01_cards), "cards\n")

source("data-raw/03_cards_tfo01.R")
cat("  - TFO01:", nrow(tfo01_cards), "cards\n")

source("data-raw/03_cards_tf40y.R")
cat("  - TF40Y:", nrow(tf40y_cards), "cards\n")

# --- Step 3: Combine all cards ---
cat("\nStep 3: Combining all card data...\n")

all_cards <- bind_rows(
  tfeu01_cards, tf01_cards, tf02_cards, tf03_cards,
  tfkb01_cards, tfh01_cards, tfo01_cards, tf40y_cards
)
cat("  - Total cards:", nrow(all_cards), "\n")

# --- Step 3b: Validate combined data ---
cat("\nStep 3b: Validating combined data...\n")

# Check expected columns
expected_card_cols <- c("card_id", "set_code", "rarity_code", "card_number",
                        "card_name_en", "card_name_zh", "character_name",
                        "faction", "card_type", "is_parallel",
                        "product_exclusive", "print_run", "notes",
                        "data_confidence")
missing_cols <- setdiff(expected_card_cols, names(all_cards))
if (length(missing_cols) > 0) {
  stop("Cards missing columns: ", paste(missing_cols, collapse = ", "))
}

# Check for duplicate card_ids
dup_ids <- all_cards$card_id[duplicated(all_cards$card_id)]
if (length(dup_ids) > 0) {
  stop("Duplicate card_ids: ", paste(head(dup_ids, 10), collapse = ", "))
}

# Check total matches sum of set totals
expected_total <- sum(sets$total_cards)
if (nrow(all_cards) != expected_total) {
  stop(sprintf("Card count mismatch: got %d, expected %d (sum of sets$total_cards)",
               nrow(all_cards), expected_total))
}

# Check all card set_codes exist in sets
invalid_card_sets <- setdiff(unique(all_cards$set_code), sets$set_code)
if (length(invalid_card_sets) > 0) {
  stop("Cards reference unknown sets: ", paste(invalid_card_sets, collapse = ", "))
}

# Check all rarity_codes per set exist in rarities table
card_rarity_keys <- unique(paste0(all_cards$set_code, "-", all_cards$rarity_code))
rarity_keys <- paste0(rarities$set_code, "-", rarities$rarity_code)
invalid_rarities <- setdiff(card_rarity_keys, rarity_keys)
if (length(invalid_rarities) > 0) {
  stop("Cards reference unknown rarities: ", paste(invalid_rarities, collapse = ", "))
}

# Validate column types
expected_types <- list(
  card_id = "character", set_code = "character", rarity_code = "character",
  card_number = "character", card_name_en = "character", card_name_zh = "character",
  character_name = "character", faction = "character", card_type = "character",
  is_parallel = "logical", product_exclusive = "character", print_run = "integer",
  notes = "character", data_confidence = "character"
)
for (col_name in names(expected_types)) {
  actual <- class(all_cards[[col_name]])[1L]
  expected <- expected_types[[col_name]]
  if (actual != expected) {
    stop(sprintf("Column '%s' has type '%s', expected '%s'", col_name, actual, expected))
  }
}

# Validate data_confidence values
valid_conf <- c("confirmed", "inferred", "placeholder")
bad_conf <- setdiff(unique(all_cards$data_confidence), valid_conf)
if (length(bad_conf) > 0) {
  stop("Invalid data_confidence values: ", paste(bad_conf, collapse = ", "))
}

# Cross-check rarity card counts
for (i in seq_len(nrow(rarities))) {
  set_cd <- rarities$set_code[i]
  rar_cd <- rarities$rarity_code[i]
  expected_n <- rarities$card_count[i]
  actual_n <- sum(all_cards$set_code == set_cd & all_cards$rarity_code == rar_cd)
  if (actual_n != expected_n) {
    stop(sprintf("Rarity %s-%s declares %d cards but found %d in cards table",
                 set_cd, rar_cd, expected_n, actual_n))
  }
}

cat("  - All validations passed\n")

# --- Step 4: Write Parquet files ---
cat("\nStep 4: Writing Parquet files to inst/extdata/...\n")

write_parquet(sets, "inst/extdata/sets.parquet")
cat("  - sets.parquet written\n")

write_parquet(products, "inst/extdata/products.parquet")
cat("  - products.parquet written\n")

write_parquet(rarities, "inst/extdata/rarities.parquet")
cat("  - rarities.parquet written\n")

write_parquet(all_cards, "inst/extdata/cards.parquet")
cat("  - cards.parquet written\n")

write_parquet(characters, "inst/extdata/characters.parquet")
cat("  - characters.parquet written\n")

write_parquet(sources, "inst/extdata/sources.parquet")
cat("  - sources.parquet written\n")

# --- Step 5: Verify ---
cat("\nStep 5: Verification...\n")
parquet_files <- list.files("inst/extdata", pattern = "\\.parquet$", full.names = TRUE)
for (parquet_file in parquet_files) {
  file_data <- read_parquet(parquet_file)
  cat(sprintf("  - %s: %d rows, %d cols, %.1f KB\n",
              basename(parquet_file), nrow(file_data), ncol(file_data),
              file.size(parquet_file) / 1024))
}

cat("\nDone! All Parquet files written successfully.\n")
cat("Total cards across all sets:", nrow(all_cards), "\n")
cat("Sets:", paste(unique(all_cards$set_code), collapse = ", "), "\n")
