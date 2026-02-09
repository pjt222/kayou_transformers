# TF01 - Cybertron Collection Series 1 card data
# Source: Trading Card Archives (confirmed 124 cards, 9 rarities), TCDB, COMC, eBay
# Data completeness: Good rarity structure, partial individual card assignments
# Known characters: Optimus Prime, Bumblebee, Windblade, Ravage, Red Alert,
#                   Bombshell, Thundercracker, Bludgeon, Starscream, Greenlight

library(tibble)

set_code <- "TF01"

make_cards <- function(rarity_code, card_count, characters = NA, factions = NA,
                       card_type = "character") {
  # Validate vector lengths match card_count (allow scalar NA as "no data")
  check_len <- function(x, name) {
    if (!(length(x) == 1L && is.na(x[1L])) && length(x) != card_count) {
      stop(sprintf("%s-%s: '%s' has length %d, expected %d",
                   set_code, rarity_code, name, length(x), card_count),
           call. = FALSE)
    }
  }
  check_len(characters, "characters")
  check_len(factions, "factions")

  tibble(
    card_id = paste0(set_code, "-", rarity_code, "-", sprintf("%03d", seq_len(card_count))),
    set_code = set_code,
    rarity_code = rarity_code,
    card_number = sprintf("%03d", seq_len(card_count)),
    card_name_en = rep(NA_character_, card_count),
    card_name_zh = rep(NA_character_, card_count),
    character_name = if (length(characters) == card_count) characters else rep(NA_character_, card_count),
    faction = if (length(factions) == card_count) factions else rep(NA_character_, card_count),
    card_type = card_type,
    is_parallel = FALSE,
    parallel_of = NA_character_,
    product_exclusive = NA_character_,
    print_run = NA_integer_,
    image_url = NA_character_
  )
}

# --- BP: Box-Pull (6 cards) - AR/Augmented Reality phone integration ---
bp_cards <- make_cards("BP", 6, card_type = "augmented_reality")

# --- LR: Limited Rare (7 cards) ---
lr_cards <- make_cards("LR", 7)

# --- AR: Augmented Reality (8 cards) ---
# Confirmed: TF01-AR-001 = Optimus Prime
ar_chars <- c("Optimus Prime", rep(NA_character_, 7))
ar_factions <- c("Autobot", rep(NA_character_, 7))
ar_cards <- make_cards("AR", 8, characters = ar_chars, factions = ar_factions,
                        card_type = "augmented_reality")

# --- UR: Ultra Rare (8 cards) ---
# Confirmed: TF01-UR-002 = Bumblebee
ur_chars <- c(NA_character_, "Bumblebee", rep(NA_character_, 6))
ur_factions <- c(NA_character_, "Autobot", rep(NA_character_, 6))
ur_cards <- make_cards("UR", 8, characters = ur_chars, factions = ur_factions)

# --- SHR: Super Holographic Rare (3 cards) ---
# Animated lenticular, more detailed than HR
shr_cards <- make_cards("SHR", 3, card_type = "lenticular")

# --- SSR: Super Special Rare (16 cards) ---
# Confirmed: TF01-SSR-008 = Greenlight (from COMC)
# SSR Optimus Prime features rainbow-inlaid foil on white areas
ssr_chars <- c(rep(NA_character_, 7), "Greenlight", rep(NA_character_, 8))
ssr_factions <- c(rep(NA_character_, 7), "Autobot", rep(NA_character_, 8))
ssr_cards <- make_cards("SSR", 16, characters = ssr_chars, factions = ssr_factions)

# --- HR: Holographic Rare (20 cards) ---
# Lenticular transformation animation cards
hr_cards <- make_cards("HR", 20, card_type = "lenticular")

# --- SR: Super Rare (20 cards) ---
sr_cards <- make_cards("SR", 20)

# --- R: Rare / Base (36 cards) ---
# Confirmed: TF01-R-001 = Optimus Prime
r_chars <- c("Optimus Prime", rep(NA_character_, 35))
r_factions <- c("Autobot", rep(NA_character_, 35))
r_cards <- make_cards("R", 36, characters = r_chars, factions = r_factions)

tf01_cards <- dplyr::bind_rows(
  bp_cards, lr_cards, ar_cards, ur_cards, shr_cards,
  ssr_cards, hr_cards, sr_cards, r_cards
)
saveRDS(tf01_cards, "data-raw/sources/tf01_cards.rds")
