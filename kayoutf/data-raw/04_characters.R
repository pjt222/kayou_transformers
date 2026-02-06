# Character reference table
# Canonical character names, factions, Chinese names, and alt modes
# Sources: All sets combined, Transformers wiki

library(tibble)

characters <- tribble(
  ~character_name, ~character_name_zh, ~faction, ~alt_mode,

  # --- Core Autobots (G1) ---
  "Optimus Prime",   "擎天柱",   "Autobot",    "Truck",
  "Bumblebee",       "大黄蜂",   "Autobot",    "Car",
  "Jazz",            "爵士",     "Autobot",    "Car",
  "Ironhide",        "铁皮",     "Autobot",    "Van",
  "Ratchet",         "救护车",   "Autobot",    "Ambulance",
  "Wheeljack",       "千斤顶",   "Autobot",    "Car",
  "Prowl",           "警车",     "Autobot",    "Police Car",
  "Sideswipe",       "横炮",     "Autobot",    "Car",
  "Sunstreaker",     "飞毛腿",   "Autobot",    "Car",
  "Mirage",          "幻影",     "Autobot",    "Race Car",
  "Hound",           "探长",     "Autobot",    "Jeep",
  "Trailbreaker",    "开路先锋", "Autobot",    "SUV",
  "Bluestreak",      "蓝霹雳",   "Autobot",    "Car",
  "Cliffjumper",     "飞过山",   "Autobot",    "Car",
  "Brawn",           "大力金刚", "Autobot",    "SUV",
  "Windcharger",     "风暴",     "Autobot",    "Car",
  "Gears",           "齿轮",     "Autobot",    "Truck",
  "Huffer",          "拖斗",     "Autobot",    "Truck",
  "Arcee",           "阿尔茜",   "Autobot",    "Car",
  "Elita One",       "艾丽塔",   "Autobot",    "Car",
  "Windblade",       "疾风刃",   "Autobot",    "Jet",
  "Red Alert",       "红色警报", "Autobot",    "Car",
  "Smokescreen",     "烟幕",     "Autobot",    "Car",
  "Greenlight",      "绿光",     "Autobot",    "Car",
  "Chromia",         "克劳莉亚", "Autobot",    "Motorcycle",
  "Moonracer",       "月行者",   "Autobot",    "Car",
  "Firestar",        "火焰星",   "Autobot",    "Car",

  # --- G1 Leadership / Movie Era ---
  "Ultra Magnus",    "通天晓",   "Autobot",    "Car Carrier",
  "Hot Rod",         "热破",     "Autobot",    "Car",
  "Rodimus Prime",   "补天士",   "Autobot",    "Truck",
  "Springer",        "弹簧",     "Autobot",    "Helicopter/Car",
  "Kup",             "杯子",     "Autobot",    "Truck",
  "Blurr",           "罗嗦",     "Autobot",    "Car",
  "Perceptor",       "感知器",   "Autobot",    "Microscope",
  "Wreck-Gar",       "营救车",   "Autobot",    "Motorcycle",
  "Wheelie",         "轮胎",     "Autobot",    "Car",

  # --- Core Decepticons (G1) ---
  "Megatron",        "威震天",   "Decepticon", "Gun/Tank",
  "Starscream",      "红蜘蛛",   "Decepticon", "Jet",
  "Soundwave",       "声波",     "Decepticon", "Cassette Player",
  "Shockwave",       "震荡波",   "Decepticon", "Gun/Space Station",
  "Skywarp",         "闹翻天",   "Decepticon", "Jet",
  "Thundercracker",  "惊天雷",   "Decepticon", "Jet",
  "Ravage",          "机器狗",   "Decepticon", "Cassette/Jaguar",
  "Laserbeak",       "激光鸟",   "Decepticon", "Cassette/Condor",
  "Rumble",          "迷乱",     "Decepticon", "Cassette",
  "Frenzy",          "狂飙",     "Decepticon", "Cassette",
  "Galvatron",       "惊破天",   "Decepticon", "Cannon",
  "Cyclonus",        "瘟疫",     "Decepticon", "Jet",
  "Scourge",         "诈骗",     "Decepticon", "Hovercraft",
  "Astrotrain",      "大火车",   "Decepticon", "Shuttle/Train",
  "Blitzwing",       "闪电",     "Decepticon", "Tank/Jet",
  "Bombshell",       "炸弹",     "Decepticon", "Beetle",
  "Bludgeon",        "恶棍",     "Decepticon", "Tank",
  "Venom",           "毒液",     "Decepticon", "Cicada",
  "Chopshop",        "斩波",     "Decepticon", "Beetle",
  "Fireflight",      "飞火",     "Autobot",    "Jet",

  # --- Dinobots ---
  "Grimlock",        "钢锁",     "Autobot",    "T-Rex",
  "Slag",            "铁渣",     "Autobot",    "Triceratops",
  "Snarl",           "嚎叫",     "Autobot",    "Stegosaurus",
  "Sludge",          "淤泥",     "Autobot",    "Brontosaurus",
  "Swoop",           "俯冲",     "Autobot",    "Pteranodon",

  # --- Combaticons (TF03 SSR confirmed) ---
  "Onslaught",       "袭击",     "Decepticon", "Truck",
  "Blast Off",       "爆炸",     "Decepticon", "Shuttle",
  "Vortex",          "旋风",     "Decepticon", "Helicopter",
  "Swindle",         "诡诈",     "Decepticon", "Jeep",
  "Brawl",           "争吵",     "Decepticon", "Tank",

  # --- Protectobots (TF03 SSR confirmed) ---
  "Hot Spot",        "热点",     "Autobot",    "Fire Engine",
  "Groove",          "车辙",     "Autobot",    "Motorcycle",
  "Blades",          "刀刃",     "Autobot",    "Helicopter",
  "Streetwise",      "街智",     "Autobot",    "Car",
  "First Aid",       "急救员",   "Autobot",    "Ambulance",
  "Rook",            "城堡",     "Autobot",    "Armored Car",

  # --- Other individuals (TF03) ---
  "Sky Lynx",        "天山遁甲", "Autobot",    "Shuttle/Lynx",
  "Scavenger",       "清道夫",   "Decepticon", "Excavator",

  # --- Combiners ---
  "Devastator",      "大力神",   "Decepticon", "Combiner",
  "Superion",        "大无畏",   "Autobot",    "Combiner",
  "Defensor",        "守护神",   "Autobot",    "Combiner",
  "Bruticus",        "混天豹",   "Decepticon", "Combiner",
  "Menasor",         "飞天虎",   "Decepticon", "Combiner",
  "Predaking",       "冲云霄",   "Decepticon", "Combiner",

  # --- Titans / Large characters ---
  "Omega Supreme",     "大力金刚", "Autobot",    "Base/Rocket",
  "Metroplex",         "猛大帅",   "Autobot",    "City",
  "Trypticon",         "铁甲龙",   "Decepticon", "City/Dinosaur",
  "Fortress Maximus",  "巨无霸福特", "Autobot",  "City/Headmaster",
  "Scorponok",         "萨克巨人", "Decepticon", "City/Scorpion",

  # --- Beast Wars ---
  "Optimus Primal",    "擎天圣",   "Maximal",    "Gorilla",
  "Megatron (BW)",     "威震天(BW)", "Predacon",  "T-Rex/Dragon",
  "Cheetor",           "黄豹",     "Maximal",    "Cheetah",
  "Rhinox",            "犀牛",     "Maximal",    "Rhinoceros",
  "Airazor",           "飞箭",     "Maximal",    "Falcon",

  # --- Rise of the Beasts movie ---
  "Scourge (RotB)",    "天灾",     "Terrorcon",  "Truck",
  "Battletrap",        "战斗陷阱", "Terrorcon",  "Truck",
  "Nightbird",         "夜鸟",     "Terrorcon",  "Car",
  "Transit",           "幻影(电影)", "Autobot",  "Porsche",
  "Stratosphere",      "平流层",   "Autobot",    "Cargo Plane",
  "Unicron",           "宇宙大帝", "Other",      "Planet",

  # --- Transformers One movie ---
  "Orion Pax",         "猎户座",   "Autobot",    "Truck (pre-transformation)",
  "D-16",              "D-16",     "Decepticon", "Tank (pre-transformation)",
  "B-127",             "B-127",    "Autobot",    "Car (pre-transformation)",
  "Elita-1",           "艾丽塔-1", "Autobot",   "Car (pre-transformation)",
  "Alpha Trion",       "钛师傅",   "Autobot",    "None",
  "Sentinel Prime",    "御天敌",   "Other",      "Truck",
  "Airachnid",         "黑寡妇",   "Decepticon", "Spider/Helicopter",
  "Silver Tracker",    "银色追踪者", "Autobot",  "Car",

  # --- The 13 Primes (TFO01 TP subset) ---
  "Prima Prime",       "至尊金刚",  "Prime",     "None",
  "Vector Prime",      "向量金刚",  "Prime",     "Spaceship",
  "Solus Prime",       "索拉斯金刚", "Prime",    "None",
  "Nexus Prime",       "连接金刚",  "Prime",     "Combiner",
  "Liege Maximo",      "至尊骗子",  "Prime",     "None",
  "Onyx Prime",        "玛瑙金刚",  "Prime",     "Beast",
  "Micronus Prime",    "微型金刚",  "Prime",     "Mini-Con",
  "Quintus Prime",     "五面金刚",  "Prime",     "None"
)

saveRDS(characters, "data-raw/sources/characters.rds")
