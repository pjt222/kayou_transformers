# kayoutf

A comprehensive, queryable database of Kayou Transformers trading cards
across all known Chinese-market sets. Data is stored as Parquet files and
queried via DuckDB, with convenience functions returning tibbles.

## Installation

```r
# Install from GitHub
remotes::install_github("pjt222/kayou_transformers", subdir = "kayoutf")
```

## Quick Start

```r
library(kayoutf)

# Browse all 1045 cards
kt_cards()

# Filter by set, rarity, faction, or character
kt_cards(set = "TFEU01")
kt_cards(set = "TFEU01", rarity = "SSR")
kt_cards(faction = "Autobot")
kt_cards(character = "Optimus Prime")

# Vector filters
kt_cards(set = c("TF01", "TF02"))
kt_cards(rarity = c("SSR", "UR"))

# Other tables
kt_sets()
kt_rarities(set = "TFEU01")
kt_characters(faction = "Decepticon")
kt_products(set = "TFEU01")
kt_sources()

# Lazy dbplyr table for advanced queries
kt_tbl("cards") |>
  dplyr::filter(faction == "Autobot", data_confidence == "confirmed") |>
  dplyr::collect()

# Interactive Shiny browser
kt_browse()
```

## Sets

| Code | Name | Year | Cards | Rarities | Theme |
|------|------|------|------:|:--------:|-------|
| TF01 | Cybertron Collection Series 1 | 2022 | 124 | 9 | G1 |
| TF02 | Cybertron Collection Series 2 | 2023 | 125 | 10 | G1 |
| TF03 | Cybertron Collection Series 3 | 2023 | 124 | 10 | G1 |
| TFH01 | Rise of the Beasts | 2023 | 71 | 6 | Movie |
| TFO01 | Transformers One | 2024 | 149 | 8 | Movie |
| TF40Y | 40th Anniversary | 2024 | 150 | 11 | Anniversary |
| TFKB01 | Cybertron Collection Series B | 2023 | 48 | 3 | G1/Movie |
| TFEU01 | Energon Universe | 2024 | 254 | 16 | Comics |

## Data Confidence

Each card has a `data_confidence` column indicating how certain we are about
its attributes:

- **confirmed**: Verified from primary sources (booklet scans, physical card
  inspection, official checklists). TFEU01 cards are mostly confirmed from
  product booklets.
- **inferred**: Rarity structure confirmed from secondary evidence (eBay card
  denominators, forum breakdowns, Trading Card Archives), but individual card
  details may be incomplete.
- **placeholder**: Minimal evidence. The card slot exists but specific data
  (character, name) is largely unknown. TFKB01 cards fall in this category.

Data sources are tracked separately via `kt_sources()`, where
`confidence = "primary"` means first-party sources (booklets) and
`"secondary"` means third-party sources (websites, forums, eBay listings).

## License

MIT
