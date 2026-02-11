# TF40Y - 40th Anniversary card data
# Source: TFW2005 forum (detailed rarity breakdown), Seibertron, news.tfw2005.com
# Data completeness: Good (rarity structure confirmed), partial individual cards
# Production: 36,000 regular boxes; 6,666 deluxe/collector boxes
# Notable: Skywarp and Thundercracker names are switched on all cards (manufacturing error)

source("data-raw/00_helpers.R")

set_code <- "TF40Y"

# --- XR: Extreme Rare (4 cards) - Limited 199 copies each ---
# Pull odds: 1 in 723.6 packs. Mix of CR and LGR styles, white and gold foil
xr_cards <- make_cards(set_code, "XR", 4, print_run = rep(199L, 4),
                       data_confidence = "inferred")

# --- USR: Ultra Super Rare (17 cards) - Limited 399 copies ---
# G1 comic cover art. Pull odds: 1 in 63.7 packs
usr_cards <- make_cards(set_code, "USR", 17, print_run = rep(399L, 17),
                        card_type = "comic_cover",
                        data_confidence = "inferred")

# --- CR: Collector Rare (3 cards) ---
# Special character portraits
cr_cards <- make_cards(
  set_code, "CR", 3,
  character_name = c("Bumblebee", "Optimus Prime", "Megatron"),
  faction = c("Autobot", "Autobot", "Decepticon"),
  card_type = "portrait",
  data_confidence = "inferred"
)

# --- LGR: Landscape Gold Rare (7 cards) ---
# Gold foiled action portraits and scenes
# Confirmed: TF40Y-LGR-006 = Optimus Prime/Megatron dual card
lgr_chars <- c(rep(NA_character_, 5), "Optimus Prime", NA_character_)
lgr_factions <- c(rep(NA_character_, 5), "Autobot", NA_character_)
lgr_cards <- make_cards(set_code, "LGR", 7, character_name = lgr_chars, faction = lgr_factions,
                        card_type = "scene",
                       data_confidence = "inferred")

# --- UR: Ultra Rare (21 cards) ---
# G1 comic scene cards
# Confirmed: TF40Y-UR-020 = Laserbeak, TF40Y-UR-021 = Megatron
ur_chars <- c(rep(NA_character_, 19), "Laserbeak", "Megatron")
ur_factions <- c(rep(NA_character_, 19), "Decepticon", "Decepticon")
ur_cards <- make_cards(set_code, "UR", 21, character_name = ur_chars, faction = ur_factions,
                       card_type = "comic_scene",
                       data_confidence = "inferred")

# --- HR: Holographic Rare (15 cards) ---
# Lenticular toy portraits
# Confirmed: TF40Y-HR-002 = Megatron
hr_chars <- c(NA_character_, "Megatron", rep(NA_character_, 13))
hr_factions <- c(NA_character_, "Decepticon", rep(NA_character_, 13))
hr_cards <- make_cards(set_code, "HR", 15, character_name = hr_chars, faction = hr_factions,
                       card_type = "lenticular",
                       data_confidence = "inferred")

# --- SSR: Super Special Rare (18 cards) ---
# Landscape cartoon scene cards
# Pack distribution: 2 SSR per pack
ssr_cards <- make_cards(set_code, "SSR", 18, card_type = "scene",
                       data_confidence = "inferred")

# --- SR: Super Rare (25 cards) ---
# Portrait character cards
# Pack distribution: 2 SR per pack
# Confirmed: TF40Y-SR-017 = Starscream
sr_chars <- c(rep(NA_character_, 16), "Starscream", rep(NA_character_, 8))
sr_factions <- c(rep(NA_character_, 16), "Decepticon", rep(NA_character_, 8))
sr_cards <- make_cards(set_code, "SR", 25, character_name = sr_chars, faction = sr_factions,
                       card_type = "portrait",
                       data_confidence = "inferred")

# --- SCR: Special Collector Rare (3 cards) - Deluxe box exclusive ---
scr_cards <- make_cards(
  set_code, "SCR", 3,
  character_name = c("Bumblebee", "Optimus Prime", "Megatron"),
  faction = c("Autobot", "Autobot", "Decepticon"),
  product_exclusive = rep("TF40Y-deluxe", 3),
  data_confidence = "inferred"
)

# --- TY: Toy Box Art (28 cards) - Deluxe box exclusive ---
# Landscape G1 toy box art style cards
ty_cards <- make_cards(set_code, "TY", 28, card_type = "toy_box_art",
                       product_exclusive = rep("TF40Y-deluxe", 28),
                       data_confidence = "inferred")

# --- PR: Promotional (9 cards) ---
pr_cards <- make_cards(set_code, "PR", 9,
                       data_confidence = "inferred")

tf40y_cards <- dplyr::bind_rows(
  xr_cards, usr_cards, cr_cards, lgr_cards,
  ur_cards, hr_cards, ssr_cards, sr_cards,
  scr_cards, ty_cards, pr_cards
)
saveRDS(tf40y_cards, "data-raw/sources/tf40y_cards.rds")
