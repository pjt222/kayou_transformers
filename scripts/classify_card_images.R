#!/usr/bin/env Rscript
# Vision-based card image classification for Kayou Transformers
#
# Uses a local Ollama vision model (via ellmer) to classify card images by set,
# rarity, character, and image type. Writes results to CSV and optionally moves
# misattributed images to the correct set directory.
#
# Usage:
#   Rscript scripts/classify_card_images.R                    # classify all
#   Rscript scripts/classify_card_images.R TFKB01             # classify one set
#   Rscript scripts/classify_card_images.R --move             # classify + move
#   Rscript scripts/classify_card_images.R --provider gemini  # use Gemini
#   Rscript scripts/classify_card_images.R --provider claude  # use Claude
#
# Prerequisites:
#   - Ollama running locally with a vision model (ollama pull qwen2.5vl:3b)
#   - ellmer R package installed
#   - kayoutf R package installed (for reference data)
#
# Environment:
#   RENV_CONFIG_SYNCHRONIZED_CHECK=FALSE suppresses renv sync warnings

Sys.setenv(RENV_CONFIG_SYNCHRONIZED_CHECK = "FALSE")
library(ellmer)

# --- Resolve repo root ---
repo_root <- tryCatch(
  normalizePath(file.path(dirname(sys.frame(1)$ofile), "..")),
  error = function(e) {
    args <- commandArgs(trailingOnly = FALSE)
    file_arg <- grep("^--file=", args, value = TRUE)
    if (length(file_arg) > 0) {
      normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), ".."))
    } else {
      normalizePath(".")
    }
  }
)

# --- Parse CLI arguments ---
cli_args <- commandArgs(trailingOnly = TRUE)

target_set <- NULL
do_move <- FALSE
provider <- "ollama"
model_name <- NULL

i <- 1
while (i <= length(cli_args)) {
  arg <- cli_args[i]
  if (arg == "--move") {
    do_move <- TRUE
  } else if (arg == "--provider") {
    i <- i + 1
    provider <- tolower(cli_args[i])
  } else if (arg == "--model") {
    i <- i + 1
    model_name <- cli_args[i]
  } else if (!startsWith(arg, "--")) {
    target_set <- toupper(arg)
  }
  i <- i + 1
}

valid_sets <- c("TF01", "TF02", "TF03", "TFKB01", "TFH01", "TFO01", "TF40Y", "TFEU01")

if (!is.null(target_set) && !target_set %in% valid_sets) {
  stop("Unknown set '", target_set, "'. Valid sets: ",
       paste(valid_sets, collapse = ", "))
}

# --- Build reference context from kayoutf ---
build_system_prompt <- function() {
  set_descriptions <- tryCatch({
    sets <- kayoutf::kt_sets()
    rarities <- kayoutf::kt_rarities()

    set_lines <- vapply(seq_len(nrow(sets)), function(i) {
      set_code <- sets$set_code[i]
      set_name <- sets$set_name_en[i]
      total <- sets$total_cards[i]
      set_rarities <- rarities[rarities$set_code == set_code, ]
      rarity_codes <- paste(set_rarities$rarity_code, collapse = "/")
      sprintf("- %s (%s): %d cards, rarities: %s",
              set_code, set_name, total, rarity_codes)
    }, character(1))

    paste(set_lines, collapse = "\n")
  }, error = function(e) {
    # Fallback if kayoutf not available
    paste(
      "- TF01 (Series 1): 124 cards, rarities: BP/LR/AR/UR/SHR/SSR/HR/SR/R",
      "- TF02 (Series 2): 124 cards, rarities: BP/LR/AR/UR/SHR/SSR/HR/SR/R",
      "- TF03 (Series 3): 124 cards, rarities: BP/LR/AR/UR/SHR/SSR/HR/SR/R",
      "- TFKB01 (Movie Subset): 48 cards, rarities: AR/HR/SR",
      "- TFH01 (Headmasters): 71 cards, rarities: BP/PR/UR/SSR/SR/SL",
      "- TFO01 (Transformers One): 149 cards, rarities: XR/SHR/UR-S/UR/HR/SSR/SR/TP",
      "- TF40Y (40th Anniversary): 150 cards, rarities: XR/USR/CR/LGR/UR/HR/SSR/SR/SCR/TY/PR",
      "- TFEU01 (Energon Universe): 254 cards, rarities: BP/XR-star/XR/OR-star/OR/WR/LR-star/LR/UR-star/UR/SR/SSR/HR/AR",
      sep = "\n"
    )
  })

  paste0(
    "You are classifying Kayou (\u5361\u6e38) Transformers trading card images.\n\n",
    "SETS (with rarity systems):\n",
    set_descriptions, "\n\n",
    "KEY VISUAL DIFFERENCES:\n",
    "- TFEU01 (Energon Universe): Modern Western comic art style (IDW/Skybound), ",
    "English text, bold colors. Rarities include XR/OR/WR/LR/UR/SR/SSR/HR/AR/BP. ",
    "Cards have a distinctive comic-panel aesthetic with English character names.\n",
    "- TF01-TF03 (Series 1-3): G1 cartoon style, Chinese text on cards, ",
    "rarities BP/LR/AR/UR/SHR/SSR/HR/SR/R. Card numbers like R-001, SR-005.\n",
    "- TFKB01 (Movie Subset): Movie character art (Drift, Crosshairs, Barricade, ",
    "Nitro Zeus, Wheelie), parallel subset from TF02 boxes, only AR/HR/SR rarities.\n",
    "- TFH01 (Headmasters): Headmasters anime style, includes SL (Scene Landscape) ",
    "horizontal cards. Rarities: BP/PR/UR/SSR/SR/SL.\n",
    "- TFO01 (Transformers One): Movie style from 2024 animated film. Includes ",
    "TP (The Primes) subset with all 13 Primes. Rarities: XR/SHR/UR-S/UR/HR/SSR/SR/TP.\n",
    "- TF40Y (40th Anniversary): Mixed G1/Beast Wars/Movie art. XR limited to 199 copies. ",
    "Rarities: XR/USR/CR/LGR/UR/HR/SSR/SR + SCR/TY/PR exclusives.\n\n",
    "CLASSIFICATION INSTRUCTIONS:\n",
    "Look for: rarity code printed on card face, art style, language (Chinese vs English), ",
    "card numbering format, and overall design aesthetic.\n",
    "If image is NOT a single card front (packaging, box photo, multiple cards, ",
    "back of card, thumbnail, watermarked listing photo), set is_card = FALSE.\n",
    "If you can see the rarity code printed on the card, report it exactly.\n",
    "If you can read a card number, report it (e.g. '007' or 'SR-005').\n",
    "For character names, use the English name (e.g. 'Optimus Prime', 'Megatron')."
  )
}

# --- Classification schema ---
card_classification <- type_object(
  "Classification of a Kayou Transformers trading card image",
  is_card = type_boolean(
    "TRUE if image shows a single trading card front, FALSE if packaging/box/multiple cards/back/other"
  ),
  set_code = type_enum(
    c("TF01", "TF02", "TF03", "TFKB01", "TFH01", "TFO01", "TF40Y", "TFEU01", "UNKNOWN"),
    "Which set this card belongs to based on art style and text. Use UNKNOWN if uncertain."
  ),
  rarity_code = type_string(
    "Rarity code visible on card (e.g. SR, SSR, HR, UR, BP, XR, AR, R, SL, TP). NA if not visible."
  ),
  character_name = type_string(
    "Character name depicted (English). NA if not identifiable."
  ),
  card_number = type_string(
    "Card number if visible (e.g. '007', 'SR-005'). NA if not visible."
  ),
  confidence = type_enum(
    c("high", "medium", "low"),
    "Confidence in the overall classification"
  ),
  notes = type_string(
    "Brief notes on what is visible or why classification is uncertain"
  )
)

# --- Initialize chat provider ---
init_chat <- function(provider, model_name, system_prompt, quiet = FALSE) {
  switch(provider,
    ollama = {
      model <- model_name %||% "qwen2.5vl:3b"
      if (!quiet) cat("Using Ollama model:", model, "\n")
      chat_ollama(model = model, system_prompt = system_prompt)
    },
    gemini = {
      model <- model_name %||% "gemini-2.0-flash"
      if (!quiet) cat("Using Google Gemini model:", model, "\n")
      chat_google_gemini(model = model, system_prompt = system_prompt)
    },
    claude = {
      model <- model_name %||% "claude-sonnet-4-5-20250929"
      if (!quiet) cat("Using Anthropic Claude model:", model, "\n")
      chat_anthropic(model = model, system_prompt = system_prompt)
    },
    stop("Unknown provider '", provider, "'. Use: ollama, gemini, claude")
  )
}

# --- Classify a single image ---
classify_image <- function(provider, model_name, system_prompt, image_path) {
  tryCatch({
    # Create a fresh chat per image to avoid context accumulation
    fresh_chat <- init_chat(provider, model_name, system_prompt, quiet = TRUE)
    result <- fresh_chat$chat_structured(
      content_image_file(image_path),
      type = card_classification
    )
    as.data.frame(result, stringsAsFactors = FALSE)
  }, error = function(e) {
    warning("Failed to classify ", basename(image_path), ": ",
            conditionMessage(e), call. = FALSE)
    data.frame(
      is_card = NA,
      set_code = "UNKNOWN",
      rarity_code = NA_character_,
      character_name = NA_character_,
      card_number = NA_character_,
      confidence = "low",
      notes = paste("ERROR:", conditionMessage(e)),
      stringsAsFactors = FALSE
    )
  })
}

# --- Main ---
cat("=== Kayou Transformers Card Image Classifier ===\n\n")
cat("Repository root:", repo_root, "\n")
cat("Provider:", provider, "\n")
if (!is.null(target_set)) cat("Target set:", target_set, "\n")
if (do_move) cat("Mode: classify + move\n")
cat("\n")

# Scan for images
scan_dirs <- if (!is.null(target_set)) {
  file.path(repo_root, target_set)
} else {
  file.path(repo_root, valid_sets)
}

# Only include directories that exist
scan_dirs <- scan_dirs[dir.exists(scan_dirs)]

image_files <- list.files(
  path = scan_dirs,
  pattern = "\\.(jpg|jpeg|png|webp)$",
  full.names = TRUE,
  recursive = TRUE,
  ignore.case = TRUE
)

# Filter to only files in cards/ subdirectories
image_files <- image_files[grepl("/cards/", image_files)]

if (length(image_files) == 0) {
  cat("No card images found.\n")
  quit(status = 0)
}

cat("Found", length(image_files), "images to classify\n\n")

# Build prompt and verify provider works
system_prompt <- build_system_prompt()
test_chat <- init_chat(provider, model_name, system_prompt)
cat("Provider initialized successfully.\n\n")

# Classify each image
results <- vector("list", length(image_files))

for (i in seq_along(image_files)) {
  img_path <- image_files[i]
  current_set <- basename(dirname(dirname(img_path)))
  filename <- basename(img_path)

  cat(sprintf("[%d/%d] %s/%s ... ", i, length(image_files), current_set, filename))

  result <- classify_image(provider, model_name, system_prompt, img_path)

  result$file_path <- img_path
  result$filename <- filename
  result$current_directory <- current_set
  result$needs_move <- !is.na(result$is_card) & result$is_card &
                       result$set_code != current_set &
                       result$set_code != "UNKNOWN"
  result$move_to <- ifelse(result$needs_move, result$set_code, NA_character_)

  results[[i]] <- result

  # Print summary
  if (isTRUE(result$is_card)) {
    cat(sprintf("%s %s %s (%s)\n",
                result$set_code,
                ifelse(is.na(result$rarity_code), "?", result$rarity_code),
                ifelse(is.na(result$character_name), "?", result$character_name),
                result$confidence))
  } else if (isFALSE(result$is_card)) {
    cat(sprintf("NOT A CARD - %s\n", result$notes))
  } else {
    cat(sprintf("ERROR - %s\n", result$notes))
  }
}

# Combine results
results_df <- do.call(rbind, results)

# Save classification results
output_path <- file.path(repo_root, "scripts", "classification_results.csv")
write.csv(results_df, output_path, row.names = FALSE)
cat("\n=== Results saved to:", output_path, "===\n\n")

# --- Summary ---
cat("=== Classification Summary ===\n\n")

n_cards <- sum(results_df$is_card == TRUE, na.rm = TRUE)
n_not_cards <- sum(results_df$is_card == FALSE, na.rm = TRUE)
n_errors <- sum(is.na(results_df$is_card))
n_needs_move <- sum(results_df$needs_move, na.rm = TRUE)

cat(sprintf("Cards identified:     %d\n", n_cards))
cat(sprintf("Non-card images:      %d\n", n_not_cards))
cat(sprintf("Errors:               %d\n", n_errors))
cat(sprintf("Needs reclassifying:  %d\n", n_needs_move))

if (n_cards > 0) {
  card_rows <- results_df[results_df$is_card == TRUE & !is.na(results_df$is_card), ]

  cat("\nCards by detected set:\n")
  set_counts <- table(card_rows$set_code)
  for (set_name in names(set_counts)) {
    cat(sprintf("  %s: %d\n", set_name, set_counts[set_name]))
  }

  cat("\nConfidence breakdown:\n")
  conf_counts <- table(card_rows$confidence)
  for (conf_name in names(conf_counts)) {
    cat(sprintf("  %s: %d\n", conf_name, conf_counts[conf_name]))
  }
}

# --- File moves ---
if (n_needs_move > 0) {
  move_rows <- results_df[results_df$needs_move & !is.na(results_df$needs_move), ]

  cat("\n=== Proposed Moves ===\n\n")
  for (j in seq_len(nrow(move_rows))) {
    row <- move_rows[j, ]
    dest_dir <- file.path(repo_root, row$move_to, "cards")
    dest_path <- file.path(dest_dir, row$filename)
    rarity_label <- ifelse(is.na(row$rarity_code), "?", row$rarity_code)
    cat(sprintf("  %s/cards/%s -> %s/cards/%s  (%s %s, %s confidence)\n",
                row$current_directory, row$filename,
                row$move_to, row$filename,
                row$move_to, rarity_label, row$confidence))
  }

  if (do_move) {
    cat("\nExecuting moves...\n")
    moved <- 0
    skipped <- 0

    for (j in seq_len(nrow(move_rows))) {
      row <- move_rows[j, ]
      dest_dir <- file.path(repo_root, row$move_to, "cards")
      dest_path <- file.path(dest_dir, row$filename)

      # Create destination directory if needed
      if (!dir.exists(dest_dir)) {
        dir.create(dest_dir, recursive = TRUE)
      }

      # Skip if destination already exists
      if (file.exists(dest_path)) {
        cat(sprintf("  SKIP (exists): %s\n", row$filename))
        skipped <- skipped + 1
        next
      }

      success <- file.rename(row$file_path, dest_path)
      if (success) {
        cat(sprintf("  MOVED: %s -> %s/cards/\n", row$filename, row$move_to))
        moved <- moved + 1
      } else {
        # file.rename fails across filesystems, fall back to copy+delete
        file.copy(row$file_path, dest_path)
        file.remove(row$file_path)
        cat(sprintf("  MOVED (copy): %s -> %s/cards/\n", row$filename, row$move_to))
        moved <- moved + 1
      }
    }

    cat(sprintf("\nMoved: %d, Skipped: %d\n", moved, skipped))
  } else {
    cat("\nTo execute moves, re-run with --move flag.\n")
  }
}

if (n_not_cards > 0) {
  cat("\n=== Non-Card Images (review manually) ===\n\n")
  non_card_rows <- results_df[results_df$is_card == FALSE & !is.na(results_df$is_card), ]
  for (j in seq_len(nrow(non_card_rows))) {
    row <- non_card_rows[j, ]
    cat(sprintf("  %s/cards/%s - %s\n",
                row$current_directory, row$filename, row$notes))
  }
}

cat("\nDone.\n")
