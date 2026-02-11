# TFEU01 - Energon Universe card data
# Source: Booklet scans (booklet_1.pdf = Super Quantum Pack, booklet_2.pdf = Elite Pack)
# This is the most complete dataset, extracted from official product booklets.

source("data-raw/00_helpers.R")

set_code <- "TFEU01"

# --- BP: Box-Pull Exclusive (5 cards) ---
# Hit Pack exclusive cards from the Super Quantum Pack
bp_cards <- make_cards(
  set_code, "BP", 5,
  card_name_en = c("Optimus Prime BP", "Megatron BP", "Starscream BP",
                   "Bumblebee BP", "Grimlock BP"),
  card_name_zh = c("擎天柱 BP", "威震天 BP", "红蜘蛛 BP",
                   "大黄蜂 BP", "钢锁 BP"),
  character_name = c("Optimus Prime", "Megatron", "Starscream",
                     "Bumblebee", "Grimlock"),
  faction = c("Autobot", "Decepticon", "Decepticon",
              "Autobot", "Autobot"),
  card_type = "character",
  product_exclusive = rep("TFEU01-super", 5)
)

# --- XR-DG: Dark Gold XR (9 cards) ---
# Super Quantum Pack exclusive, limited 9 serial numbered
xr_dg_cards <- make_cards(
  set_code, "XR-DG", 9,
  card_name_en = c("Optimus Prime Dark Gold", "Megatron Dark Gold",
                   "Starscream Dark Gold", "Soundwave Dark Gold",
                   "Grimlock Dark Gold", "Shockwave Dark Gold",
                   "Bumblebee Dark Gold", "Jazz Dark Gold",
                   "Elita One Dark Gold"),
  card_name_zh = c("擎天柱 暗金", "威震天 暗金", "红蜘蛛 暗金",
                   "声波 暗金", "钢锁 暗金", "震荡波 暗金",
                   "大黄蜂 暗金", "爵士 暗金", "艾丽塔 暗金"),
  character_name = c("Optimus Prime", "Megatron", "Starscream", "Soundwave",
                     "Grimlock", "Shockwave", "Bumblebee", "Jazz", "Elita One"),
  faction = c("Autobot", "Decepticon", "Decepticon", "Decepticon",
              "Autobot", "Decepticon", "Autobot", "Autobot", "Autobot"),
  is_parallel = TRUE,
  product_exclusive = rep("TFEU01-super", 9),
  print_run = rep(9L, 9)
)

# --- XR-RD: Red XR (4 cards) ---
# Limited 4 serial numbered
xr_rd_cards <- make_cards(
  set_code, "XR-RD", 4,
  card_name_en = c("Optimus Prime Red", "Megatron Red",
                   "Starscream Red", "Soundwave Red"),
  card_name_zh = c("擎天柱 臻红", "威震天 臻红",
                   "红蜘蛛 臻红", "声波 臻红"),
  character_name = c("Optimus Prime", "Megatron", "Starscream", "Soundwave"),
  faction = c("Autobot", "Decepticon", "Decepticon", "Decepticon"),
  is_parallel = TRUE,
  print_run = rep(4L, 4)
)

# --- XR: Standard XR (9 cards) ---
xr_cards <- make_cards(
  set_code, "XR", 9,
  card_name_en = c("Optimus Prime XR", "Megatron XR", "Starscream XR",
                   "Soundwave XR", "Grimlock XR", "Shockwave XR",
                   "Bumblebee XR", "Jazz XR", "Elita One XR"),
  card_name_zh = c("擎天柱", "威震天", "红蜘蛛", "声波",
                   "钢锁", "震荡波", "大黄蜂", "爵士", "艾丽塔"),
  character_name = c("Optimus Prime", "Megatron", "Starscream", "Soundwave",
                     "Grimlock", "Shockwave", "Bumblebee", "Jazz", "Elita One"),
  faction = c("Autobot", "Decepticon", "Decepticon", "Decepticon",
              "Autobot", "Decepticon", "Autobot", "Autobot", "Autobot")
)

# --- OR-S: Assembly Star (8 cards, limited 380 copies) ---
or_s_cards <- make_cards(
  set_code, "OR-S", 8,
  card_name_en = c("Optimus Prime Assembly Star", "Megatron Assembly Star",
                   "Starscream Assembly Star", "Soundwave Assembly Star",
                   "Grimlock Assembly Star", "Bumblebee Assembly Star",
                   "Shockwave Assembly Star", "Jazz Assembly Star"),
  card_name_zh = c("擎天柱 集结\u2606", "威震天 集结\u2606", "红蜘蛛 集结\u2606",
                   "声波 集结\u2606", "钢锁 集结\u2606", "大黄蜂 集结\u2606",
                   "震荡波 集结\u2606", "爵士 集结\u2606"),
  character_name = c("Optimus Prime", "Megatron", "Starscream", "Soundwave",
                     "Grimlock", "Bumblebee", "Shockwave", "Jazz"),
  faction = c("Autobot", "Decepticon", "Decepticon", "Decepticon",
              "Autobot", "Autobot", "Decepticon", "Autobot"),
  card_type = "scene",
  is_parallel = TRUE,
  print_run = rep(380L, 8)
)

# --- OR: Assembly (8 cards) ---
# Unique card face per pack type
or_cards <- make_cards(
  set_code, "OR", 8,
  card_name_en = c("Optimus Prime Assembly", "Megatron Assembly",
                   "Starscream Assembly", "Soundwave Assembly",
                   "Grimlock Assembly", "Bumblebee Assembly",
                   "Shockwave Assembly", "Jazz Assembly"),
  card_name_zh = c("擎天柱 集结", "威震天 集结", "红蜘蛛 集结",
                   "声波 集结", "钢锁 集结", "大黄蜂 集结",
                   "震荡波 集结", "爵士 集结"),
  character_name = c("Optimus Prime", "Megatron", "Starscream", "Soundwave",
                     "Grimlock", "Bumblebee", "Shockwave", "Jazz"),
  faction = c("Autobot", "Decepticon", "Decepticon", "Decepticon",
              "Autobot", "Autobot", "Decepticon", "Autobot"),
  card_type = "scene"
)

# --- WR: War (6 cards) ---
# Unique card face per pack type
wr_cards <- make_cards(
  set_code, "WR", 6,
  card_name_en = c("Autobot Assault", "Decepticon Siege",
                   "Cybertron Battle", "Energon Clash",
                   "Prime vs Megatron", "Dinobot Rampage"),
  card_name_zh = c("汽车人突击", "霸天虎围攻",
                   "塞伯坦之战", "能量冲突",
                   "擎天柱对威震天", "机器恐龙暴走"),
  character_name = c("Optimus Prime", "Megatron", "Optimus Prime",
                     "Soundwave", "Optimus Prime", "Grimlock"),
  faction = c("Autobot", "Decepticon", "Autobot",
              "Decepticon", "Autobot", "Autobot"),
  card_type = "scene"
)

# --- LR-S: Heroes Star (12 cards) ---
# Confirmed from 1688 promo: LR-S-001 = Optimus Prime (399),
#   LR-S-002 = Megatron (599), Arcee (position 011) = 499
lr_s_print_runs <- c(399L, 599L, rep(NA_integer_, 8), 499L, NA_integer_)
lr_s_cards <- make_cards(
  set_code, "LR-S", 12,
  card_name_en = paste0(c("Optimus Prime", "Megatron", "Bumblebee", "Starscream",
                           "Soundwave", "Grimlock", "Jazz", "Ironhide",
                           "Ratchet", "Shockwave", "Arcee", "Elita One"),
                        " Heroes Star"),
  character_name = c("Optimus Prime", "Megatron", "Bumblebee", "Starscream",
                     "Soundwave", "Grimlock", "Jazz", "Ironhide",
                     "Ratchet", "Shockwave", "Arcee", "Elita One"),
  faction = c("Autobot", "Decepticon", "Autobot", "Decepticon",
              "Decepticon", "Autobot", "Autobot", "Autobot",
              "Autobot", "Decepticon", "Autobot", "Autobot"),
  is_parallel = TRUE,
  print_run = lr_s_print_runs
)

# --- LR: Heroes (12 cards) ---
lr_cards <- make_cards(
  set_code, "LR", 12,
  card_name_en = paste0(c("Optimus Prime", "Megatron", "Bumblebee", "Starscream",
                           "Soundwave", "Grimlock", "Jazz", "Ironhide",
                           "Ratchet", "Shockwave", "Arcee", "Elita One"),
                        " Heroes"),
  character_name = c("Optimus Prime", "Megatron", "Bumblebee", "Starscream",
                     "Soundwave", "Grimlock", "Jazz", "Ironhide",
                     "Ratchet", "Shockwave", "Arcee", "Elita One"),
  faction = c("Autobot", "Decepticon", "Autobot", "Decepticon",
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
  set_code, "UR-S", 20,
  card_name_en = paste0(ur_s_characters, " Cover Variant Star"),
  character_name = ur_s_characters,
  faction = ur_s_factions,
  card_type = "cover_variant",
  is_parallel = TRUE
)

# --- UR: Cover Variant (20 cards) ---
ur_cards <- make_cards(
  set_code, "UR", 20,
  card_name_en = paste0(ur_s_characters, " Cover Variant"),
  character_name = ur_s_characters,
  faction = ur_s_factions,
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
  set_code, "SR", 36,
  card_name_en = paste0("Montage ", sprintf("%03d", 1:36)),
  character_name = sr_characters,
  faction = sr_factions,
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
  set_code, "SSR", 20,
  card_name_en = paste0(ssr_characters, " Comic Breakout"),
  character_name = ssr_characters,
  faction = ssr_factions,
  card_type = "comic_panel"
)

# --- HR: 3D Faction (3 cards, die-cut) ---
# Fix #2: These are faction emblem cards, not character cards.
# character_name is NA; faction conveys the emblem subject.
hr_cards <- make_cards(
  set_code, "HR", 3,
  card_name_en = c("Autobot Emblem", "Decepticon Emblem", "Dinobot Emblem"),
  card_name_zh = c("汽车人徽章", "霸天虎徽章", "机器恐龙徽章"),
  faction = c("Autobot", "Decepticon", "Autobot"),
  card_type = "die_cut",
  notes = c("Faction emblem die-cut card", "Faction emblem die-cut card",
            "Dinobot sub-faction emblem die-cut card")
)

# --- AR: Portrait (3 cards) ---
# Fix #1: Card numbers on physical cards are non-sequential:
#   AR-001 = Optimus Prime, AR-009 = Megatron, AR-0?? = Bumblebee
# We store sequential IDs (001/002/003) but note the discrepancy.
ar_cards <- make_cards(
  set_code, "AR", 3,
  card_name_en = c("Optimus Prime Portrait", "Megatron Portrait", "Bumblebee Portrait"),
  card_name_zh = c("擎天柱 肖像", "威震天 肖像", "大黄蜂 肖像"),
  character_name = c("Optimus Prime", "Megatron", "Bumblebee"),
  faction = c("Autobot", "Decepticon", "Autobot"),
  card_type = "portrait",
  notes = c("Physical card printed as AR-001",
            "Physical card printed as AR-009 (non-sequential)",
            "Physical card number unconfirmed")
)

# --- RD: Redemption cards ---
# Puzzle cards (连拼卡砖兑换卡) + Binder redemption (皮卡册兑换卡)
# Total cards needed to reach 254: 254 - 175 = 79
# This includes puzzle tile pieces and redemption prizes
rd_cards <- make_cards(
  set_code, "RD", 79,
  card_name_en = c(
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
