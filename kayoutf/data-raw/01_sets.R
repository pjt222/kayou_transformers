# Define set metadata for all Kayou Transformers sets
# Sources: TCDB, Trading Card Archives, TFW2005, Seibertron, time-weekly.com

library(tibble)

sets <- tribble(
  ~set_code, ~set_name_en, ~set_name_zh, ~product_line, ~release_year, ~theme, ~total_cards,

  "TF01", "Cybertron Collection Series 1", "塞伯坦典藏卡领袖版 第1弹",
  "Cybertron Leader Edition", 2022L, "G1", 124L,

  "TF02", "Cybertron Collection Series 2", "塞伯坦典藏卡领袖版 第2弹",
  "Cybertron Leader Edition", 2023L, "G1", 124L,

  "TF03", "Cybertron Collection Series 3", "塞伯坦典藏卡领袖版 第3弹",
  "Cybertron Leader Edition", 2023L, "G1", 124L,

  "TFH01", "Rise of the Beasts", "超能勇士崛起 享影包",
  "Movie Edition", 2023L, "Rise of the Beasts", 71L,

  "TFO01", "Transformers One", "变形金刚：起源",
  "Movie Edition", 2024L, "Transformers One", 149L,

  "TF40Y", "40th Anniversary", "变形金刚40周年纪念",
  "40th Anniversary Special", 2024L, "40th Anniversary", 150L,

  "TFKB01", "Cybertron Collection Series B", NA_character_,
  "Cybertron Leader Edition", 2023L, "G1 / Movie", 48L,

  "TFEU01", "Energon Universe", "能量临界典藏卡",
  "Energon Universe", 2024L, "Energon Universe Comics", 254L
)

saveRDS(sets, "data-raw/sources/sets.rds")
