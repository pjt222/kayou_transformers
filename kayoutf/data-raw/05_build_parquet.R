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
