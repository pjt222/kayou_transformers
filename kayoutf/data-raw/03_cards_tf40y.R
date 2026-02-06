# TF40Y - 40th Anniversary card data
# Source: TFW2005 forum (detailed rarity breakdown), Seibertron, news.tfw2005.com
# Data completeness: Good (rarity structure confirmed), partial individual cards
# Production: 36,000 regular boxes; 6,666 deluxe/collector boxes
# Notable: Skywarp and Thundercracker names are switched on all cards (manufacturing error)

library(tibble)

set_code <- "TF40Y"

make_cards <- function(rarity_code, card_count, characters = NA, factions = NA,
                       card_type = "character", print_run = NA,
                       product_exclusive = NA) {
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
    product_exclusive = if (length(product_exclusive) == card_count) product_exclusive else rep(NA_character_, card_count),
    print_run = if (length(print_run) == card_count) print_run else rep(NA_integer_, card_count),
    image_url = NA_character_
  )
}

# --- XR: Extreme Rare (4 cards) - Limited 199 copies each ---
# Pull odds: 1 in 723.6 packs. Mix of CR and LGR styles, white and gold foil
xr_cards <- make_cards("XR", 4, print_run = rep(199L, 4))

# --- USR: Ultra Super Rare (17 cards) - Limited 399 copies ---
# G1 comic cover art. Pull odds: 1 in 63.7 packs
usr_cards <- make_cards("USR", 17, print_run = rep(399L, 17),
                         card_type = "comic_cover")

# --- CR: Collector Rare (3 cards) ---
# Special character portraits
cr_cards <- make_cards(
  "CR", 3,
  characters = c("Bumblebee", "Optimus Prime", "Megatron"),
  factions = c("Autobot", "Autobot", "Decepticon"),
  card_type = "portrait"
)

# --- LGR: Landscape Gold Rare (7 cards) ---
# Gold foiled action portraits and scenes
# Confirmed: TF40Y-LGR-006 = Optimus Prime/Megatron dual card
lgr_chars <- c(rep(NA_character_, 5), "Optimus Prime", NA_character_)
lgr_factions <- c(rep(NA_character_, 5), "Autobot", NA_character_)
lgr_cards <- make_cards("LGR", 7, characters = lgr_chars, factions = lgr_factions,
                         card_type = "scene")

# --- UR: Ultra Rare (21 cards) ---
# G1 comic scene cards
# Confirmed: TF40Y-UR-020 = Laserbeak, TF40Y-UR-021 = Megatron
ur_chars <- c(rep(NA_character_, 19), "Laserbeak", "Megatron")
ur_factions <- c(rep(NA_character_, 19), "Decepticon", "Decepticon")
ur_cards <- make_cards("UR", 21, characters = ur_chars, factions = ur_factions,
                        card_type = "comic_scene")

# --- HR: Holographic Rare (15 cards) ---
# Lenticular toy portraits
# Confirmed: TF40Y-HR-002 = Megatron
hr_chars <- c(NA_character_, "Megatron", rep(NA_character_, 13))
hr_factions <- c(NA_character_, "Decepticon", rep(NA_character_, 13))
hr_cards <- make_cards("HR", 15, characters = hr_chars, factions = hr_factions,
                        card_type = "lenticular")

# --- SSR: Super Special Rare (18 cards) ---
# Landscape cartoon scene cards
# Pack distribution: 2 SSR per pack
ssr_cards <- make_cards("SSR", 18, card_type = "scene")

# --- SR: Super Rare (25 cards) ---
# Portrait character cards
# Pack distribution: 2 SR per pack
# Confirmed: TF40Y-SR-017 = Starscream
sr_chars <- c(rep(NA_character_, 16), "Starscream", rep(NA_character_, 8))
sr_factions <- c(rep(NA_character_, 16), "Decepticon", rep(NA_character_, 8))
sr_cards <- make_cards("SR", 25, characters = sr_chars, factions = sr_factions,
                        card_type = "portrait")

# --- SCR: Special Collector Rare (3 cards) - Deluxe box exclusive ---
scr_cards <- make_cards(
  "SCR", 3,
  characters = c("Bumblebee", "Optimus Prime", "Megatron"),
  factions = c("Autobot", "Autobot", "Decepticon"),
  product_exclusive = rep("TF40Y-deluxe", 3)
)

# --- TY: Toy Box Art (28 cards) - Deluxe box exclusive ---
# Landscape G1 toy box art style cards
ty_cards <- make_cards("TY", 28, card_type = "toy_box_art",
                        product_exclusive = rep("TF40Y-deluxe", 28))

# --- PR: Promotional (9 cards) ---
pr_cards <- make_cards("PR", 9)

tf40y_cards <- dplyr::bind_rows(
  xr_cards, usr_cards, cr_cards, lgr_cards,
  ur_cards, hr_cards, ssr_cards, sr_cards,
  scr_cards, ty_cards, pr_cards
)
saveRDS(tf40y_cards, "data-raw/sources/tf40y_cards.rds")
