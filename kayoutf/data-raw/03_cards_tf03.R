# TF03 - Cybertron Collection Series 3 card data
# Source: TCDB (subsets: New Journey, Transformations, Beyond Vision), eBay
# Data completeness: SSR set fully confirmed (16 cards), other rarities partial
# Theme: G1 combiner teams (Combaticons, Protectobots) + individual characters

library(tibble)

set_code <- "TF03"

make_cards <- function(rarity_code, card_count, characters = NA, factions = NA,
                       card_type = "character", print_run = NA) {
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
    print_run = if (length(print_run) == card_count) print_run else rep(NA_integer_, card_count),
    image_url = NA_character_
  )
}

# --- SE: Special Edition (3 cards, limited 99 copies each) ---
se_cards <- make_cards("SE", 3, print_run = rep(99L, 3))

# --- BP: Box-Pull (6 cards) ---
bp_cards <- make_cards("BP", 6, card_type = "augmented_reality")

# --- LR: Limited Rare (7 cards) ---
lr_cards <- make_cards("LR", 7)

# --- AR: Augmented Reality (9 cards) ---
# Confirmed: TF03-AR-003 = Hot Rod
ar_chars <- c(NA_character_, NA_character_, "Hot Rod", rep(NA_character_, 6))
ar_factions <- c(NA_character_, NA_character_, "Autobot", rep(NA_character_, 6))
ar_cards <- make_cards("AR", 9, characters = ar_chars, factions = ar_factions,
                        card_type = "augmented_reality")

# --- UR: Ultra Rare (8 cards) ---
ur_cards <- make_cards("UR", 8)

# --- SHR: Super Holographic Rare (3 cards) ---
shr_cards <- make_cards("SHR", 3, card_type = "lenticular")

# --- SSR: Super Special Rare (16 cards) - FULLY CONFIRMED ---
ssr_cards <- make_cards(
  "SSR", 16,
  characters = c(
    "Sky Lynx", "Wheeljack", "Hound", "Smokescreen",
    "Trailbreaker", "Onslaught", "Blast Off", "Vortex",
    "Swindle", "Brawl", "Hot Spot", "Groove",
    "Blades", "Streetwise", "First Aid", "Rook"
  ),
  factions = c(
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
hr_cards <- make_cards("HR", 20, characters = hr_chars, factions = hr_factions,
                        card_type = "lenticular")

# --- SR: Super Rare (20 cards) ---
sr_cards <- make_cards("SR", 20)

# --- R: Rare / Base (32 cards) ---
# Confirmed: TF03-R-003 = Wreck-Gar
r_chars <- c(NA_character_, NA_character_, "Wreck-Gar", rep(NA_character_, 29))
r_factions <- c(NA_character_, NA_character_, "Autobot", rep(NA_character_, 29))
r_cards <- make_cards("R", 32, characters = r_chars, factions = r_factions)

tf03_cards <- dplyr::bind_rows(
  se_cards, bp_cards, lr_cards, ar_cards, ur_cards,
  shr_cards, ssr_cards, hr_cards, sr_cards, r_cards
)
saveRDS(tf03_cards, "data-raw/sources/tf03_cards.rds")
