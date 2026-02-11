# TFO01 - Transformers One card data
# Source: Seibertron forum (detailed rarity breakdown), Axalon Underground
# Data completeness: Good structure, partial individual cards
# Characters: Orion Pax/Optimus, D-16/Megatron, B-127/Bumblebee, Elita-1,
#             Alpha Trion, Sentinel Prime, + full 13 Primes subset

source("data-raw/00_helpers.R")

set_code <- "TFO01"

# --- XR: Extreme Rare (4 cards) - Metal art cards ---
# OP and Megs limited to 399, others limited to 699
xr_cards <- make_cards(
  set_code, "XR", 4,
  character_name = c("Optimus Prime", "Megatron", NA_character_, NA_character_),
  faction = c("Autobot", "Decepticon", NA_character_, NA_character_),
  print_run = c(399L, 399L, 699L, 699L),
  data_confidence = "inferred"
)

# --- SHR: Super Holographic Rare (6 cards) ---
# Lenticular transforming cards, much rarer than HR
# Confirmed: TFO01-SHR-003 = Elita-1
shr_chars <- c(NA_character_, NA_character_, "Elita-1", rep(NA_character_, 3))
shr_factions <- c(NA_character_, NA_character_, "Autobot", rep(NA_character_, 3))
shr_cards <- make_cards(set_code, "SHR", 6, character_name = shr_chars, faction = shr_factions,
                        card_type = "lenticular",
                        data_confidence = "inferred")

# --- UR-S: Ultra Rare Star (10 cards) ---
# Fancier bot and alt mode presentations
ur_s_cards <- make_cards(set_code, "UR-S", 10,
                       data_confidence = "inferred")

# --- UR: Ultra Rare (17 cards) ---
# Confirmed: UR-005 = Chromia, UR-012 = Alpha Trion, UR-013 = Starscream, UR-015 = Soundwave
ur_chars <- c(rep(NA_character_, 4), "Chromia", rep(NA_character_, 6),
              "Alpha Trion", "Starscream", NA_character_, "Soundwave",
              rep(NA_character_, 2))
ur_factions <- c(rep(NA_character_, 4), "Autobot", rep(NA_character_, 6),
                 "Autobot", "Decepticon", NA_character_, "Decepticon",
                 rep(NA_character_, 2))
ur_cards <- make_cards(set_code, "UR", 17, character_name = ur_chars, faction = ur_factions,
                       data_confidence = "inferred")

# --- HR: Holographic Rare (19 cards) ---
hr_cards <- make_cards(set_code, "HR", 19, card_type = "lenticular",
                       data_confidence = "inferred")

# --- SSR: Super Special Rare (35 cards) ---
# Dynamic bot mode pose cards
# Confirmed: TFO01-SSR-030 = Silver Tracker
ssr_chars <- c(rep(NA_character_, 29), "Silver Tracker", rep(NA_character_, 5))
ssr_factions <- c(rep(NA_character_, 29), "Autobot", rep(NA_character_, 5))
ssr_cards <- make_cards(set_code, "SSR", 35, character_name = ssr_chars, faction = ssr_factions,
                       data_confidence = "inferred")

# --- SR: Super Rare (45 cards) ---
# Static bot mode pose cards
sr_cards <- make_cards(set_code, "SR", 45,
                       data_confidence = "inferred")

# --- TP: The Primes (13 cards) ---
# All 13 Primes with big-screen designs
# Confirmed: TP-001=Prima, TP-004=Vector, TP-005=Solus, TP-007=Nexus,
#            TP-008=Liege Maximo, TP-009=Onyx, TP-010=Micronus, TP-011=Quintus
tp_cards <- make_cards(
  set_code, "TP", 13,
  character_name = c(
    "Prima Prime", NA_character_, NA_character_, "Vector Prime",
    "Solus Prime", NA_character_, "Nexus Prime", "Liege Maximo",
    "Onyx Prime", "Micronus Prime", "Quintus Prime",
    NA_character_, NA_character_
  ),
  faction = c(
    "Prime", NA_character_, NA_character_, "Prime",
    "Prime", NA_character_, "Prime", "Prime",
    "Prime", "Prime", "Prime",
    NA_character_, NA_character_
  ),
  card_type = "prime",
  data_confidence = "confirmed"
)

tfo01_cards <- dplyr::bind_rows(
  xr_cards, shr_cards, ur_s_cards, ur_cards,
  hr_cards, ssr_cards, sr_cards, tp_cards
)
saveRDS(tfo01_cards, "data-raw/sources/tfo01_cards.rds")
