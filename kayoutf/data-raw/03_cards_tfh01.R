# TFH01 - Rise of the Beasts card data
# Source: eBay listings with card denominator notation
# Data completeness: Rarity structure confirmed from card numbering, individual cards partial
# Internal product code: DCH-001

library(tibble)

set_code <- "TFH01"

make_cards <- function(rarity_code, card_count, characters = NA, factions = NA,
                       card_type = "character") {
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

# --- BP: Box-Pull (6 cards) ---
# Confirmed: TFH01-BP-003 = Arcee, TFH01-BP-005 = unknown
bp_chars <- c(NA_character_, NA_character_, "Arcee", NA_character_, NA_character_, NA_character_)
bp_factions <- c(NA_character_, NA_character_, "Autobot", NA_character_, NA_character_, NA_character_)
bp_cards <- make_cards("BP", 6, characters = bp_chars, factions = bp_factions)

# --- PR: Promotional (4 cards) ---
# Confirmed: TFH01-PR-004 = Airazor (Beast Mode)
pr_chars <- c(rep(NA_character_, 3), "Airazor")
pr_factions <- c(rep(NA_character_, 3), "Maximal")
pr_cards <- make_cards("PR", 4, characters = pr_chars, factions = pr_factions)

# --- UR: Ultra Rare (12 cards) ---
# Confirmed: TFH01-UR-012 = Airazor
ur_chars <- c(rep(NA_character_, 11), "Airazor")
ur_factions <- c(rep(NA_character_, 11), "Maximal")
ur_cards <- make_cards("UR", 12, characters = ur_chars, factions = ur_factions)

# --- SSR: Super Special Rare (18 cards) ---
# Confirmed: TFH01-SSR-001 = Optimus Prime, TFH01-SSR-004 = Transit,
#            TFH01-SSR-014 = Transit
ssr_chars <- c("Optimus Prime", rep(NA_character_, 2), "Transit",
               rep(NA_character_, 9), "Transit", rep(NA_character_, 4))
ssr_factions <- c("Autobot", rep(NA_character_, 2), "Autobot",
                  rep(NA_character_, 9), "Autobot", rep(NA_character_, 4))
ssr_cards <- make_cards("SSR", 18, characters = ssr_chars, factions = ssr_factions)

# --- SR: Super Rare (17 cards) ---
# Confirmed: TFH01-SR-006 = Stratosphere
sr_chars <- c(rep(NA_character_, 5), "Stratosphere", rep(NA_character_, 11))
sr_factions <- c(rep(NA_character_, 5), "Autobot", rep(NA_character_, 11))
sr_cards <- make_cards("SR", 17, characters = sr_chars, factions = sr_factions)

# --- SL: Scene Landscape (14 cards) ---
# Confirmed: TFH01-SL-014 = Transit
# Unique rarity tier to TFH01
sl_chars <- c(rep(NA_character_, 13), "Transit")
sl_factions <- c(rep(NA_character_, 13), "Autobot")
sl_cards <- make_cards("SL", 14, characters = sl_chars, factions = sl_factions,
                        card_type = "scene")

tfh01_cards <- dplyr::bind_rows(
  bp_cards, pr_cards, ur_cards, ssr_cards, sr_cards, sl_cards
)
saveRDS(tfh01_cards, "data-raw/sources/tfh01_cards.rds")
