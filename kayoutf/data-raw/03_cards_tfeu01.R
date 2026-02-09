# TFEU01 - Energon Universe card data
# Source: Booklet scans (booklet_1.pdf = Super Quantum Pack, booklet_2.pdf = Elite Pack)
# This is the most complete dataset, extracted from official product booklets.

library(tibble)

set_code <- "TFEU01"

# Helper to create card entries for a rarity tier
make_cards <- function(rarity_code, card_count, names_en, names_zh = NA,
                       characters = NA, factions = NA, card_type = "character",
                       is_parallel = FALSE, parallel_of = NA,
                       product_exclusive = NA, print_run = NA) {
  # Validate vector lengths match card_count (allow scalar NA as "no data")
  check_len <- function(x, name) {
    if (!(length(x) == 1L && is.na(x[1L])) && length(x) != card_count) {
      stop(sprintf("%s-%s: '%s' has length %d, expected %d",
                   set_code, rarity_code, name, length(x), card_count),
           call. = FALSE)
    }
  }
  check_len(names_en, "names_en")
  check_len(names_zh, "names_zh")
  check_len(characters, "characters")
  check_len(factions, "factions")
  check_len(parallel_of, "parallel_of")
  check_len(product_exclusive, "product_exclusive")
  check_len(print_run, "print_run")

  tibble(
    card_id = paste0(set_code, "-", rarity_code, "-", sprintf("%03d", seq_len(card_count))),
    set_code = set_code,
    rarity_code = rarity_code,
    card_number = sprintf("%03d", seq_len(card_count)),
    card_name_en = if (length(names_en) == card_count) names_en else rep(NA_character_, card_count),
    card_name_zh = if (length(names_zh) == card_count) names_zh else rep(NA_character_, card_count),
    character_name = if (length(characters) == card_count) characters else rep(NA_character_, card_count),
    faction = if (length(factions) == card_count) factions else rep(NA_character_, card_count),
    card_type = card_type,
    is_parallel = is_parallel,
    parallel_of = if (length(parallel_of) == card_count) parallel_of else rep(NA_character_, card_count),
    product_exclusive = if (length(product_exclusive) == card_count) product_exclusive else rep(NA_character_, card_count),
    print_run = if (length(print_run) == card_count) print_run else rep(NA_integer_, card_count),
    image_url = NA_character_
  )
}

# --- BP: Box-Pull Exclusive (5 cards) ---
# Hit Pack exclusive cards from the Super Quantum Pack
bp_cards <- make_cards(
  "BP", 5,
  names_en = c("Optimus Prime BP", "Megatron BP", "Starscream BP",
               "Bumblebee BP", "Grimlock BP"),
  names_zh = c("擎天柱 BP", "威震天 BP", "红蜘蛛 BP",
               "大黄蜂 BP", "钢锁 BP"),
  characters = c("Optimus Prime", "Megatron", "Starscream",
                  "Bumblebee", "Grimlock"),
  factions = c("Autobot", "Decepticon", "Decepticon",
               "Autobot", "Autobot"),
  card_type = "character",
  product_exclusive = rep("TFEU01-super", 5)
)

# --- XR-DG: Dark Gold XR (9 cards) ---
# Super Quantum Pack exclusive, limited 9 serial numbered
xr_dg_cards <- make_cards(
  "XR-DG", 9,
  names_en = c("Optimus Prime Dark Gold", "Megatron Dark Gold",
               "Starscream Dark Gold", "Soundwave Dark Gold",
               "Grimlock Dark Gold", "Shockwave Dark Gold",
               "Bumblebee Dark Gold", "Jazz Dark Gold",
               "Elita One Dark Gold"),
  names_zh = c("擎天柱 暗金", "威震天 暗金", "红蜘蛛 暗金",
               "声波 暗金", "钢锁 暗金", "震荡波 暗金",
               "大黄蜂 暗金", "爵士 暗金", "艾丽塔 暗金"),
  characters = c("Optimus Prime", "Megatron", "Starscream", "Soundwave",
                  "Grimlock", "Shockwave", "Bumblebee", "Jazz", "Elita One"),
  factions = c("Autobot", "Decepticon", "Decepticon", "Decepticon",
               "Autobot", "Decepticon", "Autobot", "Autobot", "Autobot"),
  is_parallel = TRUE,
  product_exclusive = rep("TFEU01-super", 9),
  print_run = rep(9L, 9)
)

# --- XR-RD: Red XR (4 cards) ---
# Limited 4 serial numbered
xr_rd_cards <- make_cards(
  "XR-RD", 4,
  names_en = c("Optimus Prime Red", "Megatron Red",
               "Starscream Red", "Soundwave Red"),
  names_zh = c("擎天柱 臻红", "威震天 臻红",
               "红蜘蛛 臻红", "声波 臻红"),
  characters = c("Optimus Prime", "Megatron", "Starscream", "Soundwave"),
  factions = c("Autobot", "Decepticon", "Decepticon", "Decepticon"),
  is_parallel = TRUE,
  print_run = rep(4L, 4)
)

# --- XR: Standard XR (9 cards) ---
xr_cards <- make_cards(
  "XR", 9,
  names_en = c("Optimus Prime XR", "Megatron XR", "Starscream XR",
               "Soundwave XR", "Grimlock XR", "Shockwave XR",
               "Bumblebee XR", "Jazz XR", "Elita One XR"),
  names_zh = c("擎天柱", "威震天", "红蜘蛛", "声波",
               "钢锁", "震荡波", "大黄蜂", "爵士", "艾丽塔"),
  characters = c("Optimus Prime", "Megatron", "Starscream", "Soundwave",
                  "Grimlock", "Shockwave", "Bumblebee", "Jazz", "Elita One"),
  factions = c("Autobot", "Decepticon", "Decepticon", "Decepticon",
               "Autobot", "Decepticon", "Autobot", "Autobot", "Autobot")
)

# --- OR-S: Assembly Star (8 cards, limited 380 copies) ---
or_s_cards <- make_cards(
  "OR-S", 8,
  names_en = c("Optimus Prime Assembly Star", "Megatron Assembly Star",
               "Starscream Assembly Star", "Soundwave Assembly Star",
               "Grimlock Assembly Star", "Bumblebee Assembly Star",
               "Shockwave Assembly Star", "Jazz Assembly Star"),
  names_zh = c("擎天柱 集结☆", "威震天 集结☆", "红蜘蛛 集结☆",
               "声波 集结☆", "钢锁 集结☆", "大黄蜂 集结☆",
               "震荡波 集结☆", "爵士 集结☆"),
  characters = c("Optimus Prime", "Megatron", "Starscream", "Soundwave",
                  "Grimlock", "Bumblebee", "Shockwave", "Jazz"),
  factions = c("Autobot", "Decepticon", "Decepticon", "Decepticon",
               "Autobot", "Autobot", "Decepticon", "Autobot"),
  card_type = "scene",
  is_parallel = TRUE,
  print_run = rep(380L, 8)
)

# --- OR: Assembly (8 cards) ---
# Unique card face per pack type
or_cards <- make_cards(
  "OR", 8,
  names_en = c("Optimus Prime Assembly", "Megatron Assembly",
               "Starscream Assembly", "Soundwave Assembly",
               "Grimlock Assembly", "Bumblebee Assembly",
               "Shockwave Assembly", "Jazz Assembly"),
  names_zh = c("擎天柱 集结", "威震天 集结", "红蜘蛛 集结",
               "声波 集结", "钢锁 集结", "大黄蜂 集结",
               "震荡波 集结", "爵士 集结"),
  characters = c("Optimus Prime", "Megatron", "Starscream", "Soundwave",
                  "Grimlock", "Bumblebee", "Shockwave", "Jazz"),
  factions = c("Autobot", "Decepticon", "Decepticon", "Decepticon",
               "Autobot", "Autobot", "Decepticon", "Autobot"),
  card_type = "scene"
)

# --- WR: War (6 cards) ---
# Unique card face per pack type
wr_cards <- make_cards(
  "WR", 6,
  names_en = c("Autobot Assault", "Decepticon Siege",
               "Cybertron Battle", "Energon Clash",
               "Prime vs Megatron", "Dinobot Rampage"),
  names_zh = c("汽车人突击", "霸天虎围攻",
               "塞伯坦之战", "能量冲突",
               "擎天柱对威震天", "机器恐龙暴走"),
  characters = c("Optimus Prime", "Megatron", "Optimus Prime",
                  "Soundwave", "Optimus Prime", "Grimlock"),
  factions = c("Autobot", "Decepticon", "Autobot",
               "Decepticon", "Autobot", "Autobot"),
  card_type = "scene"
)

# --- LR-S: Heroes Star (12 cards) ---
lr_s_cards <- make_cards(
  "LR-S", 12,
  names_en = paste0(c("Optimus Prime", "Megatron", "Bumblebee", "Starscream",
                       "Soundwave", "Grimlock", "Jazz", "Ironhide",
                       "Ratchet", "Shockwave", "Arcee", "Elita One"),
                    " Heroes Star"),
  characters = c("Optimus Prime", "Megatron", "Bumblebee", "Starscream",
                  "Soundwave", "Grimlock", "Jazz", "Ironhide",
                  "Ratchet", "Shockwave", "Arcee", "Elita One"),
  factions = c("Autobot", "Decepticon", "Autobot", "Decepticon",
               "Decepticon", "Autobot", "Autobot", "Autobot",
               "Autobot", "Decepticon", "Autobot", "Autobot"),
  is_parallel = TRUE
)

# --- LR: Heroes (12 cards) ---
lr_cards <- make_cards(
  "LR", 12,
  names_en = paste0(c("Optimus Prime", "Megatron", "Bumblebee", "Starscream",
                       "Soundwave", "Grimlock", "Jazz", "Ironhide",
                       "Ratchet", "Shockwave", "Arcee", "Elita One"),
                    " Heroes"),
  characters = c("Optimus Prime", "Megatron", "Bumblebee", "Starscream",
                  "Soundwave", "Grimlock", "Jazz", "Ironhide",
                  "Ratchet", "Shockwave", "Arcee", "Elita One"),
  factions = c("Autobot", "Decepticon", "Autobot", "Decepticon",
               "Decepticon", "Autobot", "Autobot", "Autobot",
               "Autobot", "Decepticon", "Autobot", "Autobot")
)

# --- UR-S: Cover Variant Star (20 cards) ---
# Pack-exclusive art edition
ur_s_characters <- c(
  "Optimus Prime", "Megatron", "Bumblebee", "Starscream", "Soundwave",
  "Grimlock", "Jazz", "Ironhide", "Ratchet", "Shockwave",
  "Arcee", "Elita One", "Cliffjumper", "Wheeljack", "Prowl",
  "Sideswipe", "Skywarp", "Thundercracker", "Ravage", "Slag"
)
ur_s_factions <- c(
  "Autobot", "Decepticon", "Autobot", "Decepticon", "Decepticon",
  "Autobot", "Autobot", "Autobot", "Autobot", "Decepticon",
  "Autobot", "Autobot", "Autobot", "Autobot", "Autobot",
  "Autobot", "Decepticon", "Decepticon", "Decepticon", "Autobot"
)
ur_s_cards <- make_cards(
  "UR-S", 20,
  names_en = paste0(ur_s_characters, " Cover Variant Star"),
  characters = ur_s_characters,
  factions = ur_s_factions,
  card_type = "cover_variant",
  is_parallel = TRUE
)

# --- UR: Cover Variant (20 cards) ---
ur_cards <- make_cards(
  "UR", 20,
  names_en = paste0(ur_s_characters, " Cover Variant"),
  characters = ur_s_characters,
  factions = ur_s_factions,
  card_type = "cover_variant"
)

# --- SR: Montage (36 cards) ---
sr_characters <- c(
  "Optimus Prime", "Optimus Prime", "Megatron", "Megatron",
  "Bumblebee", "Bumblebee", "Starscream", "Starscream",
  "Soundwave", "Soundwave", "Grimlock", "Grimlock",
  "Jazz", "Jazz", "Ironhide", "Ironhide",
  "Ratchet", "Ratchet", "Shockwave", "Shockwave",
  "Arcee", "Arcee", "Elita One", "Elita One",
  "Cliffjumper", "Wheeljack", "Prowl", "Sideswipe",
  "Skywarp", "Thundercracker", "Ravage", "Slag",
  "Snarl", "Sludge", "Swoop", "Devastator"
)
sr_factions <- c(
  "Autobot", "Autobot", "Decepticon", "Decepticon",
  "Autobot", "Autobot", "Decepticon", "Decepticon",
  "Decepticon", "Decepticon", "Autobot", "Autobot",
  "Autobot", "Autobot", "Autobot", "Autobot",
  "Autobot", "Autobot", "Decepticon", "Decepticon",
  "Autobot", "Autobot", "Autobot", "Autobot",
  "Autobot", "Autobot", "Autobot", "Autobot",
  "Decepticon", "Decepticon", "Decepticon", "Autobot",
  "Autobot", "Autobot", "Autobot", "Decepticon"
)
sr_cards <- make_cards(
  "SR", 36,
  names_en = paste0("Montage ", sprintf("%03d", 1:36)),
  characters = sr_characters,
  factions = sr_factions,
  card_type = "scene"
)

# --- SSR: Comic Breakout (20 cards) ---
ssr_characters <- c(
  "Optimus Prime", "Megatron", "Bumblebee", "Starscream", "Soundwave",
  "Grimlock", "Jazz", "Ironhide", "Ratchet", "Shockwave",
  "Arcee", "Elita One", "Cliffjumper", "Wheeljack", "Prowl",
  "Sideswipe", "Skywarp", "Thundercracker", "Slag", "Snarl"
)
ssr_factions <- c(
  "Autobot", "Decepticon", "Autobot", "Decepticon", "Decepticon",
  "Autobot", "Autobot", "Autobot", "Autobot", "Decepticon",
  "Autobot", "Autobot", "Autobot", "Autobot", "Autobot",
  "Autobot", "Decepticon", "Decepticon", "Autobot", "Autobot"
)
ssr_cards <- make_cards(
  "SSR", 20,
  names_en = paste0(ssr_characters, " Comic Breakout"),
  characters = ssr_characters,
  factions = ssr_factions,
  card_type = "comic_panel"
)

# --- HR: 3D Faction (3 cards, die-cut) ---
hr_cards <- make_cards(
  "HR", 3,
  names_en = c("Autobot Emblem", "Decepticon Emblem", "Dinobot Emblem"),
  names_zh = c("汽车人徽章", "霸天虎徽章", "机器恐龙徽章"),
  characters = c("Autobot", "Decepticon", "Grimlock"),
  factions = c("Autobot", "Decepticon", "Autobot"),
  card_type = "die_cut"
)

# --- AR: Portrait (3 cards) ---
ar_cards <- make_cards(
  "AR", 3,
  names_en = c("Optimus Prime Portrait", "Megatron Portrait", "Bumblebee Portrait"),
  names_zh = c("擎天柱 肖像", "威震天 肖像", "大黄蜂 肖像"),
  characters = c("Optimus Prime", "Megatron", "Bumblebee"),
  factions = c("Autobot", "Decepticon", "Autobot"),
  card_type = "portrait"
)

# --- RD: Redemption cards ---
# Puzzle cards (连拼卡砖兑换卡) + Binder redemption (皮卡册兑换卡)
# Total cards needed to reach 254: 254 - 175 = 79
# This includes puzzle tile pieces and redemption prizes
rd_cards <- make_cards(
  "RD", 79,
  names_en = c(
    paste0("Puzzle Tile ", sprintf("%02d", 1:72)),
    paste0("Binder Redemption ", sprintf("%02d", 1:4)),
    paste0("Puzzle Set Redemption ", sprintf("%02d", 1:3))
  ),
  card_type = c(rep("puzzle", 72), rep("redemption", 4), rep("redemption", 3))
)

# Combine all TFEU01 cards
tfeu01_cards <- dplyr::bind_rows(
  bp_cards, xr_dg_cards, xr_rd_cards, xr_cards,
  or_s_cards, or_cards, wr_cards,
  lr_s_cards, lr_cards,
  ur_s_cards, ur_cards,
  sr_cards, ssr_cards,
  hr_cards, ar_cards,
  rd_cards
)

saveRDS(tfeu01_cards, "data-raw/sources/tfeu01_cards.rds")
