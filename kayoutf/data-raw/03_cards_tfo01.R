# TFO01 - Transformers One card data
# Source: Seibertron forum (detailed rarity breakdown), Axalon Underground
# Data completeness: Good structure, partial individual cards
# Characters: Orion Pax/Optimus, D-16/Megatron, B-127/Bumblebee, Elita-1,
#             Alpha Trion, Sentinel Prime, + full 13 Primes subset

library(tibble)

set_code <- "TFO01"

make_cards <- function(rarity_code, card_count, characters = NA, factions = NA,
                       card_type = "character", print_run = NA) {
  check_len <- function(x, name) {
    if (!(length(x) == 1L && is.na(x[1L])) && length(x) != card_count) {
      stop(sprintf("%s-%s: '%s' has length %d, expected %d",
                   set_code, rarity_code, name, length(x), card_count),
           call. = FALSE)
    }
  }
  check_len(characters, "characters")
  check_len(factions, "factions")
  check_len(print_run, "print_run")

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

# --- XR: Extreme Rare (4 cards) - Metal art cards ---
# OP and Megs limited to 399, others limited to 699
xr_cards <- make_cards(
  "XR", 4,
  characters = c("Optimus Prime", "Megatron", NA_character_, NA_character_),
  factions = c("Autobot", "Decepticon", NA_character_, NA_character_),
  print_run = c(399L, 399L, 699L, 699L)
)

# --- SHR: Super Holographic Rare (6 cards) ---
# Lenticular transforming cards, much rarer than HR
# Confirmed: TFO01-SHR-003 = Elita-1
shr_chars <- c(NA_character_, NA_character_, "Elita-1", rep(NA_character_, 3))
shr_factions <- c(NA_character_, NA_character_, "Autobot", rep(NA_character_, 3))
shr_cards <- make_cards("SHR", 6, characters = shr_chars, factions = shr_factions,
                         card_type = "lenticular")

# --- UR-S: Ultra Rare Star (10 cards) ---
# Fancier bot and alt mode presentations
ur_s_cards <- make_cards("UR-S", 10)

# --- UR: Ultra Rare (17 cards) ---
# Confirmed: UR-005 = Chromia, UR-012 = Alpha Trion, UR-013 = Starscream, UR-015 = Soundwave
ur_chars <- c(rep(NA_character_, 4), "Chromia", rep(NA_character_, 6),
              "Alpha Trion", "Starscream", NA_character_, "Soundwave",
              rep(NA_character_, 2))
ur_factions <- c(rep(NA_character_, 4), "Autobot", rep(NA_character_, 6),
                 "Autobot", "Decepticon", NA_character_, "Decepticon",
                 rep(NA_character_, 2))
ur_cards <- make_cards("UR", 17, characters = ur_chars, factions = ur_factions)

# --- HR: Holographic Rare (19 cards) ---
hr_cards <- make_cards("HR", 19, card_type = "lenticular")

# --- SSR: Super Special Rare (35 cards) ---
# Dynamic bot mode pose cards
# Confirmed: TFO01-SSR-030 = Silver Tracker
ssr_chars <- c(rep(NA_character_, 29), "Silver Tracker", rep(NA_character_, 5))
ssr_factions <- c(rep(NA_character_, 29), "Autobot", rep(NA_character_, 5))
ssr_cards <- make_cards("SSR", 35, characters = ssr_chars, factions = ssr_factions)

# --- SR: Super Rare (45 cards) ---
# Static bot mode pose cards
sr_cards <- make_cards("SR", 45)

# --- TP: The Primes (13 cards) ---
# All 13 Primes with big-screen designs
# Confirmed: TP-001=Prima, TP-004=Vector, TP-005=Solus, TP-007=Nexus,
#            TP-008=Liege Maximo, TP-009=Onyx, TP-010=Micronus, TP-011=Quintus
tp_cards <- make_cards(
  "TP", 13,
  characters = c(
    "Prima Prime", NA_character_, NA_character_, "Vector Prime",
    "Solus Prime", NA_character_, "Nexus Prime", "Liege Maximo",
    "Onyx Prime", "Micronus Prime", "Quintus Prime",
    NA_character_, NA_character_
  ),
  factions = c(
    "Prime", NA_character_, NA_character_, "Prime",
    "Prime", NA_character_, "Prime", "Prime",
    "Prime", "Prime", "Prime",
    NA_character_, NA_character_
  ),
  card_type = "prime"
)

tfo01_cards <- dplyr::bind_rows(
  xr_cards, shr_cards, ur_s_cards, ur_cards,
  hr_cards, ssr_cards, sr_cards, tp_cards
)
saveRDS(tfo01_cards, "data-raw/sources/tfo01_cards.rds")
