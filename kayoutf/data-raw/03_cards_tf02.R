# TF02 - Cybertron Collection Series 2 card data
# Source: eBay denominator data, TCDB listings
# Data completeness: Moderate - key rarity counts confirmed from eBay denominators
# Key differences from TF01: R=28 (not 36), new MR rarity (9 cards)
# Known characters: Venom (SR-019), Chopshop (SR-020), Fireflight (SSR-002),
#   Mirage (HR-012), Hound (R-013), Ironhide (SSR-013), Starscream (MR-007),
#   Barricade (MR-008), Aerialbots (SSR-001 through 005)

source("data-raw/00_helpers.R")

set_code <- "TF02"

# --- BP: Box-Pull (6 cards) ---
# Assumed from TF01 pattern (no TF02-BP listings found)
bp_cards <- make_cards(set_code, "BP", 6, card_type = "augmented_reality",
                       data_confidence = "inferred")

# --- LR: Limited Rare (7 cards) ---
# Assumed from TF01 pattern
lr_cards <- make_cards(set_code, "LR", 7,
                       data_confidence = "inferred")

# --- AR: Augmented Reality (8 cards) ---
# Assumed from TF01 pattern
ar_cards <- make_cards(set_code, "AR", 8, card_type = "augmented_reality",
                       data_confidence = "inferred")

# --- UR: Ultra Rare (8 cards) ---
# Assumed from TF01 pattern
ur_cards <- make_cards(set_code, "UR", 8,
                       data_confidence = "inferred")

# --- MR: Metal Rare (9 cards) ---
# NEW: Unique to TF02, not in TF01 or TF03
# Confirmed from eBay denominator /009
# Confirmed: TF02-MR-007 = Starscream, TF02-MR-008 = Barricade
mr_chars <- c(rep(NA_character_, 6), "Starscream", "Barricade", NA_character_)
mr_factions <- c(rep(NA_character_, 6), "Decepticon", "Decepticon", NA_character_)
mr_cards <- make_cards(set_code, "MR", 9, character_name = mr_chars, faction = mr_factions,
                       data_confidence = "inferred")

# --- SHR: Super Holographic Rare (3 cards) ---
# Assumed from TF01 pattern
shr_cards <- make_cards(set_code, "SHR", 3, card_type = "lenticular",
                       data_confidence = "inferred")

# --- SSR: Super Special Rare (16 cards) ---
# Confirmed /016 denominator
# SSR-001 to 005: Aerialbots forming Superion (combiner team, like TF03's pattern)
# Confirmed: TF02-SSR-002 = Fireflight, TF02-SSR-013 = Ironhide
ssr_chars <- c("Silverbolt", "Fireflight", "Air Raid", "Skydive", "Slingshot",
               rep(NA_character_, 7), "Ironhide", rep(NA_character_, 3))
ssr_factions <- c(rep("Autobot", 5),
                  rep(NA_character_, 7), "Autobot", rep(NA_character_, 3))
ssr_cards <- make_cards(set_code, "SSR", 16, character_name = ssr_chars, faction = ssr_factions,
                       data_confidence = "inferred")

# --- HR: Holographic Rare (20 cards) ---
# Confirmed /020 denominator
# Confirmed: TF02-HR-012 = Mirage
hr_chars <- c(rep(NA_character_, 11), "Mirage", rep(NA_character_, 8))
hr_factions <- c(rep(NA_character_, 11), "Autobot", rep(NA_character_, 8))
hr_cards <- make_cards(set_code, "HR", 20, character_name = hr_chars, faction = hr_factions,
                       card_type = "lenticular",
                       data_confidence = "inferred")

# --- SR: Super Rare (20 cards) ---
# Confirmed /020 denominator
# Confirmed: TF02-SR-019 = Venom, TF02-SR-020 = Chopshop
sr_chars <- c(rep(NA_character_, 18), "Venom", "Chopshop")
sr_factions <- c(rep(NA_character_, 18), "Decepticon", "Decepticon")
sr_cards <- make_cards(set_code, "SR", 20, character_name = sr_chars, faction = sr_factions,
                       data_confidence = "inferred")

# --- R: Rare / Base (28 cards) ---
# Confirmed /028 denominator (differs from TF01's 36!)
# Confirmed: TF02-R-013 = Hound
r_chars <- c(rep(NA_character_, 12), "Hound", rep(NA_character_, 15))
r_factions <- c(rep(NA_character_, 12), "Autobot", rep(NA_character_, 15))
r_cards <- make_cards(set_code, "R", 28, character_name = r_chars, faction = r_factions,
                       data_confidence = "inferred")

tf02_cards <- dplyr::bind_rows(
  bp_cards, lr_cards, ar_cards, ur_cards, mr_cards, shr_cards,
  ssr_cards, hr_cards, sr_cards, r_cards
)
saveRDS(tf02_cards, "data-raw/sources/tf02_cards.rds")
