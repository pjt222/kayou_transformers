# TFH01 - Rise of the Beasts card data
# Source: eBay listings with card denominator notation
# Data completeness: Rarity structure confirmed from card numbering, individual cards partial
# Internal product code: DCH-001

source("data-raw/00_helpers.R")

set_code <- "TFH01"

# --- BP: Box-Pull (6 cards) ---
# Confirmed: TFH01-BP-003 = Arcee, TFH01-BP-005 = unknown
bp_chars <- c(NA_character_, NA_character_, "Arcee", NA_character_, NA_character_, NA_character_)
bp_factions <- c(NA_character_, NA_character_, "Autobot", NA_character_, NA_character_, NA_character_)
bp_cards <- make_cards(set_code, "BP", 6, character_name = bp_chars, faction = bp_factions,
                       data_confidence = "inferred")

# --- PR: Promotional (4 cards) ---
# Confirmed: TFH01-PR-004 = Airazor (Beast Mode)
pr_chars <- c(rep(NA_character_, 3), "Airazor")
pr_factions <- c(rep(NA_character_, 3), "Maximal")
pr_cards <- make_cards(set_code, "PR", 4, character_name = pr_chars, faction = pr_factions,
                       data_confidence = "inferred")

# --- UR: Ultra Rare (12 cards) ---
# Confirmed: TFH01-UR-012 = Airazor
ur_chars <- c(rep(NA_character_, 11), "Airazor")
ur_factions <- c(rep(NA_character_, 11), "Maximal")
ur_cards <- make_cards(set_code, "UR", 12, character_name = ur_chars, faction = ur_factions,
                       data_confidence = "inferred")

# --- SSR: Super Special Rare (18 cards) ---
# Confirmed: TFH01-SSR-001 = Optimus Prime, TFH01-SSR-004 = Transit,
#            TFH01-SSR-014 = Transit
ssr_chars <- c("Optimus Prime", rep(NA_character_, 2), "Transit",
               rep(NA_character_, 9), "Transit", rep(NA_character_, 4))
ssr_factions <- c("Autobot", rep(NA_character_, 2), "Autobot",
                  rep(NA_character_, 9), "Autobot", rep(NA_character_, 4))
ssr_cards <- make_cards(set_code, "SSR", 18, character_name = ssr_chars, faction = ssr_factions,
                       data_confidence = "inferred")

# --- SR: Super Rare (17 cards) ---
# Confirmed: TFH01-SR-006 = Stratosphere
sr_chars <- c(rep(NA_character_, 5), "Stratosphere", rep(NA_character_, 11))
sr_factions <- c(rep(NA_character_, 5), "Autobot", rep(NA_character_, 11))
sr_cards <- make_cards(set_code, "SR", 17, character_name = sr_chars, faction = sr_factions,
                       data_confidence = "inferred")

# --- SL: Scene Landscape (14 cards) ---
# Confirmed: TFH01-SL-014 = Transit
# Unique rarity tier to TFH01
sl_chars <- c(rep(NA_character_, 13), "Transit")
sl_factions <- c(rep(NA_character_, 13), "Autobot")
sl_cards <- make_cards(set_code, "SL", 14, character_name = sl_chars, faction = sl_factions,
                       card_type = "scene",
                       data_confidence = "inferred")

tfh01_cards <- dplyr::bind_rows(
  bp_cards, pr_cards, ur_cards, ssr_cards, sr_cards, sl_cards
)
saveRDS(tfh01_cards, "data-raw/sources/tfh01_cards.rds")
