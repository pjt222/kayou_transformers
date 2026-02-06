# Define rarity tiers for all Kayou Transformers sets
# Sources: Trading Card Archives (TF01 confirmed), TCDB card numbering,
#          TFW2005 forums (TF40Y), Seibertron (TFO01), eBay listings (TFH01)

library(tibble)

# --- TFEU01 rarities (from booklet scans - highest confidence) ---
tfeu01_rarities <- tribble(
  ~rarity_code, ~rarity_name_en, ~rarity_name_zh, ~card_count, ~sort_order, ~notes,
  "BP",    "Box-Pull Exclusive",   "Hit Pack限定",   5L,  1L, "Hit Pack exclusive, 5 cards",
  "XR-DG", "Dark Gold XR",        "暗金辉迪卡",     9L,  2L, "Super Quantum Pack exclusive, limited 9 serial",
  "XR-RD", "Red XR",              "臻红辉迪卡",     4L,  3L, "Limited 4 serial numbered",
  "XR",    "XR",                  "辉迪卡",         9L,  4L, NA_character_,
  "OR-S",  "Assembly Star",       "集结卡☆",        8L,  5L, "Limited 380 copies each",
  "OR",    "Assembly",            "集结卡",         8L,  6L, "Unique card face per pack type",
  "WR",    "War",                 "战役卡",         6L,  7L, "Unique card face per pack type",
  "LR-S",  "Heroes Star",        "群英卡☆",       12L,  8L, "Limited serial numbered",
  "LR",    "Heroes",             "群英卡",        12L,  9L, NA_character_,
  "UR-S",  "Cover Variant Star", "封面变体卡☆",   20L, 10L, "Pack-exclusive art edition",
  "UR",    "Cover Variant",      "封面变体卡",    20L, 11L, NA_character_,
  "SR",    "Montage",            "蒙太奇卡",      36L, 12L, NA_character_,
  "SSR",   "Comic Breakout",     "漫画破格卡",    20L, 13L, NA_character_,
  "HR",    "3D Faction",         "立体阵营卡",     3L, 14L, "Die-cut shaped cards",
  "AR",    "Portrait",           "肖像卡",         3L, 15L, NA_character_,
  "RD",    "Redemption",         "兑换卡",        79L, 16L, "Puzzle cards and binder redemptions"
)
tfeu01_rarities$set_code <- "TFEU01"

# --- TF01 rarities (confirmed from Trading Card Archives box label) ---
tf01_rarities <- tribble(
  ~rarity_code, ~rarity_name_en, ~rarity_name_zh, ~card_count, ~sort_order, ~notes,
  "BP",   "Box-Pull",             NA_character_,  6L, 1L, "Box-Pull exclusive; cards include phone-scannable AR feature",
  "LR",   "Limited Rare",         NA_character_,  7L, 2L, NA_character_,
  "AR",   "Augmented Reality",    "增强现实卡",   8L, 3L, "Phone-scannable AR cards; note: TFEU01 reuses AR code for Portrait (肖像卡)",
  "UR",   "Ultra Rare",           NA_character_,  8L, 4L, NA_character_,
  "SHR",  "Super Holographic Rare", NA_character_, 3L, 5L, "Animated lenticular, more detailed than HR",
  "SSR",  "Super Special Rare",   NA_character_, 16L, 6L, NA_character_,
  "HR",   "Holographic Rare",     NA_character_, 20L, 7L, "Lenticular transformation animation cards",
  "SR",   "Super Rare",           NA_character_, 20L, 8L, NA_character_,
  "R",    "Rare",                 NA_character_, 36L, 9L, "Base cards"
)
tf01_rarities$set_code <- "TF01"

# --- TF02 rarities (assumed same structure as TF01) ---
tf02_rarities <- tribble(
  ~rarity_code, ~rarity_name_en, ~rarity_name_zh, ~card_count, ~sort_order, ~notes,
  "BP",   "Box-Pull",             NA_character_,  6L, 1L, NA_character_,
  "LR",   "Limited Rare",         NA_character_,  7L, 2L, NA_character_,
  "AR",   "Augmented Reality",    "增强现实卡",   8L, 3L, "Phone-scannable AR cards; note: TFEU01 reuses AR code for Portrait (肖像卡)",
  "UR",   "Ultra Rare",           NA_character_,  8L, 4L, NA_character_,
  "SHR",  "Super Holographic Rare", NA_character_, 3L, 5L, NA_character_,
  "SSR",  "Super Special Rare",   NA_character_, 16L, 6L, NA_character_,
  "HR",   "Holographic Rare",     NA_character_, 20L, 7L, "Lenticular transformation animation",
  "SR",   "Super Rare",           NA_character_, 20L, 8L, NA_character_,
  "R",    "Rare",                 NA_character_, 36L, 9L, "Base cards"
)
tf02_rarities$set_code <- "TF02"

# --- TF03 rarities (partially confirmed from card numbering) ---
# Confirmed: R:32, SR:20, SSR:16, HR:20, AR:9
# Inferred from TF01 pattern: UR:8, LR:7, SHR:3, BP:6, SE:3
tf03_rarities <- tribble(
  ~rarity_code, ~rarity_name_en, ~rarity_name_zh, ~card_count, ~sort_order, ~notes,
  "SE",   "Special Edition",      NA_character_,  3L, 1L, "Limited to 99 copies each",
  "BP",   "Box-Pull",             NA_character_,  6L, 2L, NA_character_,
  "LR",   "Limited Rare",         NA_character_,  7L, 3L, NA_character_,
  "AR",   "Augmented Reality",    "增强现实卡",   9L, 4L, "Confirmed /009 denominator; phone-scannable AR cards; note: TFEU01 reuses AR code for Portrait (肖像卡)",
  "UR",   "Ultra Rare",           NA_character_,  8L, 5L, NA_character_,
  "SHR",  "Super Holographic Rare", NA_character_, 3L, 6L, NA_character_,
  "SSR",  "Super Special Rare",   NA_character_, 16L, 7L, "Confirmed: combiner team members focus",
  "HR",   "Holographic Rare",     NA_character_, 20L, 8L, "Confirmed /020 denominator",
  "SR",   "Super Rare",           NA_character_, 20L, 9L, "Confirmed /020 denominator",
  "R",    "Rare",                 NA_character_, 32L, 10L, "Confirmed /032 denominator"
)
tf03_rarities$set_code <- "TF03"

# --- TFH01 rarities (from eBay card denominator notation) ---
# Different structure from G1 sets: uses SL and PR tiers
tfh01_rarities <- tribble(
  ~rarity_code, ~rarity_name_en, ~rarity_name_zh, ~card_count, ~sort_order, ~notes,
  "BP",   "Box-Pull",             NA_character_,  6L, 1L, "Confirmed /006 denominator",
  "PR",   "Promotional",          NA_character_,  4L, 2L, "Confirmed TFH01-PR-004",
  "UR",   "Ultra Rare",           NA_character_, 12L, 3L, "Confirmed /012 denominator",
  "SSR",  "Super Special Rare",   NA_character_, 18L, 4L, "Confirmed /018 denominator",
  "SR",   "Super Rare",           NA_character_, 17L, 5L, "Confirmed /017 denominator",
  "SL",   "Scene Landscape",      NA_character_, 14L, 6L, "Unique to TFH01, confirmed TFH01-SL-014"
)
tfh01_rarities$set_code <- "TFH01"

# --- TFO01 rarities (from Seibertron forum detailed breakdown) ---
tfo01_rarities <- tribble(
  ~rarity_code, ~rarity_name_en, ~rarity_name_zh, ~card_count, ~sort_order, ~notes,
  "SE",    "Signed Edition",       NA_character_,  0L, 1L, "Redemption QR codes, limited 99 copies, voice actor signatures",
  "XR",    "Extreme Rare",         NA_character_,  4L, 2L, "Metal art cards; OP/Megs limited 399, others limited 699",
  "SHR",   "Super Holographic Rare", NA_character_, 6L, 3L, "Lenticular transforming cards, much rarer than HR",
  "UR-S",  "Ultra Rare Star",      NA_character_, 10L, 4L, "Fancier bot and alt mode presentations",
  "UR",    "Ultra Rare",           NA_character_, 17L, 5L, "Confirmed /017 denominator",
  "HR",    "Holographic Rare",     NA_character_, 19L, 6L, "Lenticular transforming cards",
  "SSR",   "Super Special Rare",   NA_character_, 35L, 7L, "Dynamic bot mode pose cards, confirmed /035",
  "SR",    "Super Rare",           NA_character_, 45L, 8L, "Static bot mode pose cards, confirmed /045",
  "TP",    "The Primes",           NA_character_, 13L, 9L, "All 13 Primes with big-screen designs"
)
tfo01_rarities$set_code <- "TFO01"

# --- TF40Y rarities (from TFW2005 forum page 3 + Seibertron) ---
tf40y_rarities <- tribble(
  ~rarity_code, ~rarity_name_en, ~rarity_name_zh, ~card_count, ~sort_order, ~notes,
  "XR",   "Extreme Rare",          NA_character_,   4L,  1L, "Limited 199 copies each, white and gold foil",
  "USR",  "Ultra Super Rare",      NA_character_,  17L,  2L, "G1 comic cover art, limited 399 copies",
  "CR",   "Collector Rare",        NA_character_,   3L,  3L, "Special character portraits (Bee, OP, Megs)",
  "LGR",  "Landscape Gold Rare",   NA_character_,   7L,  4L, "Gold foiled action portraits and scenes",
  "UR",   "Ultra Rare",            NA_character_,  21L,  5L, "G1 comic scene cards, confirmed /021",
  "HR",   "Holographic Rare",      NA_character_,  15L,  6L, "Lenticular toy portraits",
  "SSR",  "Super Special Rare",    NA_character_,  18L,  7L, "Landscape cartoon scene cards",
  "SR",   "Super Rare",            NA_character_,  25L,  8L, "Portrait character cards",
  "SCR",  "Special Collector Rare", NA_character_,   3L,  9L, "Deluxe box exclusive (Bee, Optimus, Megatron)",
  "TY",   "Toy Box Art",           NA_character_,  28L, 10L, "Deluxe box exclusive, landscape G1 toy box art style",
  "PR",   "Promotional",           NA_character_,   9L, 11L, "Various promotional cards"
)
tf40y_rarities$set_code <- "TF40Y"

# --- TFKB01 rarities (from physical card denomination inspection) ---
# Parallel subset included in TF02 boxes; likely incomplete
tfkb01_rarities <- tribble(
  ~rarity_code, ~rarity_name_en, ~rarity_name_zh, ~card_count, ~sort_order, ~notes,
  "AR", "Augmented Reality", NA_character_, 8L, 1L, "Confirmed from card denominator /008",
  "HR", "Holographic Rare",  NA_character_, 20L, 2L, "Confirmed from card denominator",
  "SR", "Super Rare",        NA_character_, 20L, 3L, "Confirmed from card denominator"
)
tfkb01_rarities$set_code <- "TFKB01"

# Combine all
rarities <- dplyr::bind_rows(
  tfeu01_rarities, tf01_rarities, tf02_rarities, tf03_rarities,
  tfkb01_rarities, tfh01_rarities, tfo01_rarities, tf40y_rarities
)

# Generate rarity_id
rarities$rarity_id <- paste0(rarities$set_code, "-", rarities$rarity_code)

# Reorder columns
rarities <- rarities[, c("rarity_id", "set_code", "rarity_code",
                          "rarity_name_en", "rarity_name_zh",
                          "card_count", "sort_order", "notes")]

saveRDS(rarities, "data-raw/sources/rarities.rds")
