# Define data sources and provenance for all Kayou Transformers sets
# Tracks where card data, images, and metadata originate from

library(tibble)

sources <- tribble(
  ~source_id, ~set_code, ~source_type, ~source_url, ~local_path,
  ~description, ~access_date, ~confidence, ~notes,

# --- TFEU01: Energon Universe ---

  "TFEU01-booklet-1", "TFEU01", "booklet", NA_character_, "TFEU01/booklets/booklet_1.pdf",
  "Super Quantum Pack checklist booklet", as.Date("2024-12-01"), "primary",
  "Scanned from physical booklet; 254 cards across 16 rarities",

  "TFEU01-booklet-2", "TFEU01", "booklet", NA_character_, "TFEU01/booklets/booklet_2.pdf",
  "Elite Pack checklist booklet", as.Date("2024-12-01"), "primary",
  "Scanned from physical booklet; 239 cards across 14 rarities",

# --- TF01: Cybertron Collection Series 1 ---

  "TF01-TCA-review", "TF01", "website",
  "https://tradingcardarchives.com/2023/05/25/kayou-transformers-cards/", NA_character_,
  "TF01 box review with rarity breakdown and card scans", as.Date("2024-12-01"), "secondary",
  "Confirmed 124 cards, 9 rarities (BP/LR/AR/UR/SHR/SSR/HR/SR/R)",

  "TF01-TCA-part2", "TF01", "website",
  "https://tradingcardarchives.com/2023/06/05/kayou-transformers-cards-part-2/", NA_character_,
  "TF01 part 2 review with additional card scans", as.Date("2024-12-01"), "secondary",
  "Additional card images and rarity confirmation",

# --- TF02: Cybertron Collection Series 2 ---

  "TF02-TCA-review", "TF02", "website",
  "https://tradingcardarchives.com/2023/11/01/kayou-transformers-cards-series-2/", NA_character_,
  "TF02 box review with card scans", as.Date("2024-12-01"), "secondary",
  "Confirmed 4 individual cards; structure assumed same as TF01",

# --- TF03: Cybertron Collection Series 3 ---

  "TF03-TCA-review", "TF03", "website",
  "https://tradingcardarchives.com/2024/05/09/kayou-transformers-cards-series-3/", NA_character_,
  "TF03 box review with combiner team SSR details", as.Date("2024-12-01"), "secondary",
  "SSR fully confirmed: 16 combiner team cards; R/SR/HR/AR counts confirmed",

# --- TFH01: Rise of the Beasts ---

  "TFH01-ebay-listings", "TFH01", "website", NA_character_, NA_character_,
  "eBay listings with card denominators for TFH01", as.Date("2024-12-01"), "secondary",
  "All rarity counts derived from eBay card numbering denominators (e.g. xx/71)",

# --- TFO01: Transformers One ---

  "TFO01-seibertron", "TFO01", "website",
  "https://www.seibertron.com/transformers/news/kayou-transformers-one-trading-cards-detailed-breakdown/51962/",
  NA_character_,
  "Detailed breakdown of TFO01 rarities and card counts", as.Date("2024-12-01"), "secondary",
  "149 cards across 8 rarities; 13 Primes in TP subset",

# --- TF40Y: 40th Anniversary ---

  "TF40Y-tfw2005", "TF40Y", "website",
  "https://www.tfw2005.com/boards/threads/kayou-transformers-40th-anniversary-cards.1262011/",
  NA_character_,
  "TFW2005 forum thread with 40th Anniversary card details", as.Date("2024-12-01"), "secondary",
  "150 cards; XR limited to 199 copies; USR limited to 399; Skywarp/Thundercracker name swap error",

  "TF40Y-time-weekly", "TF40Y", "website",
  "https://www.time-weekly.com/post/305612", NA_character_,
  "Time Weekly article on 40th Anniversary release", as.Date("2024-12-01"), "secondary",
  "Chinese-language source with product details and pricing",

# --- TFKB01: Cybertron Collection Series B ---

  "TFKB01-physical-cards", "TFKB01", "card_scan", NA_character_, NA_character_,
  "Physical card inspection for TFKB01 rarity denominators",
  as.Date("2025-02-06"), "secondary",
  "Confirmed AR/008, SR/020, HR/020 from physical cards"
)

saveRDS(sources, "data-raw/sources/sources.rds")
