# TF01 - Cybertron Collection Series 1 card data
# Source: Trading Card Archives (confirmed 124 cards, 9 rarities), TCDB, COMC, eBay
# Data completeness: Good rarity structure, partial individual card assignments
# Known characters: Optimus Prime, Bumblebee, Windblade, Ravage, Red Alert,
#                   Bombshell, Thundercracker, Bludgeon, Starscream, Greenlight

source("data-raw/00_helpers.R")

set_code <- "TF01"

# --- BP: Box-Pull (6 cards) - AR/Augmented Reality phone integration ---
bp_cards <- make_cards(set_code, "BP", 6, card_type = "augmented_reality",
                       data_confidence = "inferred")

# --- LR: Limited Rare (7 cards) ---
lr_cards <- make_cards(set_code, "LR", 7,
                       data_confidence = "inferred")

# --- AR: Augmented Reality (8 cards) ---
# Confirmed: TF01-AR-001 = Optimus Prime
ar_chars <- c("Optimus Prime", rep(NA_character_, 7))
ar_factions <- c("Autobot", rep(NA_character_, 7))
ar_cards <- make_cards(set_code, "AR", 8, character_name = ar_chars, faction = ar_factions,
                       card_type = "augmented_reality",
                       data_confidence = "inferred")

# --- UR: Ultra Rare (8 cards) ---
# Confirmed from 1688 promo images:
#   TF01-UR-004/008 = Windblade, TF01-UR-005/008 = Megatron,
#   TF01-UR-006/008 = Starscream, TF01-UR-007/008 = Soundwave
# Confirmed from card grid position: UR-001 = Optimus Prime, UR-003 = Grimlock
# Pre-existing: TF01-UR-002 = Bumblebee
ur_chars <- c("Optimus Prime", "Bumblebee", "Grimlock", "Windblade",
              "Megatron", "Starscream", "Soundwave", NA_character_)
ur_factions <- c("Autobot", "Autobot", "Autobot", "Autobot",
                 "Decepticon", "Decepticon", "Decepticon", NA_character_)
ur_cards <- make_cards(set_code, "UR", 8, character_name = ur_chars, faction = ur_factions,
                       data_confidence = "inferred")

# --- SHR: Super Holographic Rare (3 cards) ---
# Animated lenticular, 4-panel transformation sequence
# Confirmed from 1688 promo: TF01-SHR-001/003 = Optimus Prime (四帧变形)
shr_chars <- c("Optimus Prime", rep(NA_character_, 2))
shr_factions <- c("Autobot", rep(NA_character_, 2))
shr_cards <- make_cards(set_code, "SHR", 3, character_name = shr_chars, faction = shr_factions,
                        card_type = "lenticular",
                       data_confidence = "inferred")

# --- SSR: Super Special Rare (16 cards) ---
# Confirmed: TF01-SSR-008 = Greenlight (from COMC)
# SSR Optimus Prime features rainbow-inlaid foil on white areas
ssr_chars <- c(rep(NA_character_, 7), "Greenlight", rep(NA_character_, 8))
ssr_factions <- c(rep(NA_character_, 7), "Autobot", rep(NA_character_, 8))
ssr_cards <- make_cards(set_code, "SSR", 16, character_name = ssr_chars, faction = ssr_factions,
                       data_confidence = "inferred")

# --- HR: Holographic Rare (20 cards) ---
# Lenticular transformation animation cards
hr_cards <- make_cards(set_code, "HR", 20, card_type = "lenticular",
                       data_confidence = "inferred")

# --- SR: Super Rare (20 cards) ---
sr_cards <- make_cards(set_code, "SR", 20,
                       data_confidence = "inferred")

# --- R: Rare / Base (36 cards) ---
# Confirmed: TF01-R-001 = Optimus Prime
r_chars <- c("Optimus Prime", rep(NA_character_, 35))
r_factions <- c("Autobot", rep(NA_character_, 35))
r_cards <- make_cards(set_code, "R", 36, character_name = r_chars, faction = r_factions,
                       data_confidence = "inferred")

tf01_cards <- dplyr::bind_rows(
  bp_cards, lr_cards, ar_cards, ur_cards, shr_cards,
  ssr_cards, hr_cards, sr_cards, r_cards
)
saveRDS(tf01_cards, "data-raw/sources/tf01_cards.rds")
