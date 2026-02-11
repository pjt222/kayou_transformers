# TF03 - Cybertron Collection Series 3 card data
# Source: TCDB (subsets: New Journey, Transformations, Beyond Vision), eBay
# Data completeness: SSR set fully confirmed (16 cards), other rarities partial
# Theme: G1 combiner teams (Combaticons, Protectobots) + individual characters

source("data-raw/00_helpers.R")

set_code <- "TF03"

# --- SE: Special Edition (3 cards, limited 99 copies each) ---
se_cards <- make_cards(set_code, "SE", 3, print_run = rep(99L, 3))

# --- BP: Box-Pull (6 cards) ---
bp_cards <- make_cards(set_code, "BP", 6, card_type = "augmented_reality")

# --- LR: Limited Rare (7 cards) ---
lr_cards <- make_cards(set_code, "LR", 7)

# --- AR: Augmented Reality (9 cards) ---
# Confirmed: TF03-AR-003 = Hot Rod
ar_chars <- c(NA_character_, NA_character_, "Hot Rod", rep(NA_character_, 6))
ar_factions <- c(NA_character_, NA_character_, "Autobot", rep(NA_character_, 6))
ar_cards <- make_cards(set_code, "AR", 9, character_name = ar_chars, faction = ar_factions,
                       card_type = "augmented_reality")

# --- UR: Ultra Rare (8 cards) ---
ur_cards <- make_cards(set_code, "UR", 8)

# --- SHR: Super Holographic Rare (3 cards) ---
shr_cards <- make_cards(set_code, "SHR", 3, card_type = "lenticular")

# --- SSR: Super Special Rare (16 cards) - FULLY CONFIRMED ---
ssr_cards <- make_cards(
  set_code, "SSR", 16,
  character_name = c(
    "Sky Lynx", "Wheeljack", "Hound", "Smokescreen",
    "Trailbreaker", "Onslaught", "Blast Off", "Vortex",
    "Swindle", "Brawl", "Hot Spot", "Groove",
    "Blades", "Streetwise", "First Aid", "Rook"
  ),
  faction = c(
    "Autobot", "Autobot", "Autobot", "Autobot",
    "Autobot", "Decepticon", "Decepticon", "Decepticon",
    "Decepticon", "Decepticon", "Autobot", "Autobot",
    "Autobot", "Autobot", "Autobot", "Autobot"
  )
)

# --- HR: Holographic Rare (20 cards) ---
# Confirmed: TF03-HR-018 = Scavenger
hr_chars <- c(rep(NA_character_, 17), "Scavenger", rep(NA_character_, 2))
hr_factions <- c(rep(NA_character_, 17), "Decepticon", rep(NA_character_, 2))
hr_cards <- make_cards(set_code, "HR", 20, character_name = hr_chars, faction = hr_factions,
                       card_type = "lenticular")

# --- SR: Super Rare (20 cards) ---
sr_cards <- make_cards(set_code, "SR", 20)

# --- R: Rare / Base (32 cards) ---
# Confirmed: TF03-R-003 = Wreck-Gar
r_chars <- c(NA_character_, NA_character_, "Wreck-Gar", rep(NA_character_, 29))
r_factions <- c(NA_character_, NA_character_, "Autobot", rep(NA_character_, 29))
r_cards <- make_cards(set_code, "R", 32, character_name = r_chars, faction = r_factions)

tf03_cards <- dplyr::bind_rows(
  se_cards, bp_cards, lr_cards, ar_cards, ur_cards,
  shr_cards, ssr_cards, hr_cards, sr_cards, r_cards
)
saveRDS(tf03_cards, "data-raw/sources/tf03_cards.rds")
