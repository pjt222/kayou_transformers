# Product/pack type definitions for all sets
# Sources: Trading Card Archives (TF01), eBay listings (TFH01), TFW2005 (TF40Y),
#          Seibertron (TFO01), booklet scans (TFEU01)

library(tibble)

products <- tribble(
  ~product_id, ~set_code, ~product_name_en, ~product_name_zh, ~cards_per_pack, ~packs_per_box, ~total_cards, ~barcode,

  # TFEU01 - Confirmed from booklet scans
  "TFEU01-super", "TFEU01", "Super Quantum Pack", "超量包",
  10L, 10L, 254L, NA_character_,

  "TFEU01-elite", "TFEU01", "Elite Pack", "精英包",
  15L, 10L, 239L, NA_character_,

  # TF01 - Confirmed from Trading Card Archives (purple box, TF-DC-001)
  "TF01-standard", "TF01", "Standard Box", "领袖版",
  5L, 18L, 124L, NA_character_,

  # TF02 - Confirmed red box, same format as TF01
  "TF02-standard", "TF02", "Standard Box", "领袖版",
  5L, 18L, 124L, NA_character_,

  # TF03 - Same format
  "TF03-standard", "TF03", "Standard Box", "领袖版",
  5L, 18L, 124L, NA_character_,

  # TFH01 - Confirmed from eBay: 12 packs per box, 3 cards per pack (DCH-001)
  "TFH01-booster", "TFH01", "Booster Box", "享影包",
  3L, 12L, 71L, NA_character_,

  # TFO01 - From Seibertron, same 5/18 format as TF01-TF03
  "TFO01-standard", "TFO01", "Standard Box", "标准包",
  5L, 18L, 149L, NA_character_,

  # TF40Y - Confirmed from TFW2005: two box types
  "TF40Y-regular", "TF40Y", "Energy Gift Box", "能量礼盒",
  5L, 6L, 110L, NA_character_,

  "TF40Y-deluxe", "TF40Y", "Memorial Gift Box", "纪念礼盒",
  5L, 12L, 150L, NA_character_
)

saveRDS(products, "data-raw/sources/products.rds")
