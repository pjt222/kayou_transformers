library(shiny)
library(bslib)
library(bsicons)
library(DT)
library(kayoutf)

# Source modules
app_dir <- system.file("app", package = "kayoutf")
source(file.path(app_dir, "modules", "mod_cards.R"), local = TRUE)
source(file.path(app_dir, "modules", "mod_gallery.R"), local = TRUE)

# -- Load all data once at startup ------------------------------------------------
all_cards      <- kt_cards()
all_sets       <- kt_sets()
all_rarities   <- kt_rarities()
all_characters <- kt_characters()
all_products   <- kt_products()

set_choices    <- sort(unique(all_cards$set_code))
faction_choices <- sort(unique(all_characters$faction[!is.na(all_characters$faction)]))

cards_display_cols <- c(
  "card_id", "set_code", "rarity_code", "card_number",
  "card_name_en", "card_name_zh", "character_name",
  "faction", "card_type", "is_parallel", "product_exclusive"
)

# -- Gallery: load all images and register resource paths --------------------------
repo_root <- getOption("kayoutf.repo_root")
if (is.null(repo_root)) repo_root <- find_repo_root()

gallery_data <- data.frame()
gallery_available <- FALSE

if (!is.null(repo_root)) {
  gallery_data <- build_gallery_data(repo_root)
}

# Fallback: if provided path didn't work, try auto-detect
if (nrow(gallery_data) == 0) {
  auto_root <- find_repo_root()
  if (!is.null(auto_root) && !identical(auto_root, repo_root)) {
    gallery_data <- build_gallery_data(auto_root)
    if (nrow(gallery_data) > 0) repo_root <- auto_root
  }
}

if (nrow(gallery_data) > 0) {
  gallery_available <- TRUE
  gallery_dirs <- unique(gallery_data$directory)
  for (dir_name in gallery_dirs) {
    cards_path <- file.path(repo_root, dir_name, "cards")
    if (dir.exists(cards_path)) {
      shiny::addResourcePath(paste0("gallery-", dir_name), cards_path)
    }
  }
}

gallery_set_choices <- if (gallery_available) {
  sort(unique(gallery_data$directory))
} else {
  character(0)
}

gallery_tag_choices <- if (gallery_available && !is.null(repo_root)) {
  existing_tags <- load_tags(repo_root)
  sort(unique(existing_tags$tag))
} else {
  character(0)
}

# -- Helper: render a DT with dark-friendly defaults ------------------------------
render_dark_dt <- function(data) {
  DT::renderDataTable({
    DT::datatable(
      data,
      style     = "bootstrap5",
      class     = "table-dark table-striped table-hover",
      rownames  = FALSE,
      options   = list(pageLength = 25, autoWidth = TRUE)
    )
  })
}

# -- Custom CSS -------------------------------------------------------------------
dark_dt_css <- tags$style(HTML("
  /* DataTables search/length controls */
  .dataTables_wrapper .dataTables_filter input,
  .dataTables_wrapper .dataTables_length select {
    background-color: #303030;
    color: #fff;
    border-color: #444;
  }
  .dataTables_wrapper .dataTables_filter label,
  .dataTables_wrapper .dataTables_length label,
  .dataTables_wrapper .dataTables_info {
    color: #adb5bd;
  }
  /* Pagination buttons */
  .dataTables_wrapper .dataTables_paginate .paginate_button {
    color: #adb5bd !important;
  }
  .dataTables_wrapper .dataTables_paginate .paginate_button.current {
    background: #375a7f !important;
    color: #fff !important;
    border-color: #375a7f !important;
  }
  .dataTables_wrapper .dataTables_paginate .paginate_button:hover {
    background: #444 !important;
    color: #fff !important;
    border-color: #444 !important;
  }
  /* Gallery card styling */
  .gallery-card {
    position: relative;
    background-color: #303030;
    border: 1px solid #444;
    border-radius: 8px;
    overflow: hidden;
    transition: transform 0.2s, box-shadow 0.2s;
    cursor: pointer;
  }
  .gallery-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 6px 20px rgba(0,0,0,0.4);
  }
  .gallery-card img {
    width: 100%;
    height: 200px;
    object-fit: cover;
  }
  .gallery-card .card-body { padding: 8px 10px; }
  .gallery-card .card-title {
    font-size: 0.85rem;
    margin-bottom: 4px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .gallery-card .card-text {
    font-size: 0.75rem;
    color: #adb5bd;
    margin-bottom: 2px;
  }
  .gallery-badge { font-size: 0.7rem; }
  .gallery-pagination .btn { margin: 0 2px; }
  .modal-gallery-img {
    max-width: 100%;
    max-height: 80vh;
    display: block;
    margin: 0 auto;
  }
  /* Feedback overlay icon */
  .feedback-overlay {
    position: absolute;
    top: 6px;
    right: 6px;
    font-size: 1.2rem;
    line-height: 1;
    z-index: 2;
    text-shadow: 0 1px 3px rgba(0,0,0,0.7);
  }
  .feedback-overlay.correct { color: #2ecc40; }
  .feedback-overlay.incorrect { color: #e74c3c; }
  /* Feedback icon buttons */
  .feedback-btn {
    border: none;
    background: transparent;
    cursor: pointer;
    padding: 2px 5px;
    font-size: 0.85rem;
    opacity: 0.5;
    transition: opacity 0.15s;
  }
  .feedback-btn:hover { opacity: 1; }
  .feedback-btn.active { opacity: 1; }
  .feedback-btn.correct { color: #2ecc40; }
  .feedback-btn.incorrect { color: #e74c3c; }
  /* Modal feedback section */
  .modal-feedback-section {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-top: 12px;
    padding-top: 10px;
    border-top: 1px solid #444;
  }
  .modal-feedback-btn {
    padding: 6px 14px;
    border-radius: 6px;
    border: 1px solid #555;
    cursor: pointer;
    font-size: 0.85rem;
    background: #303030;
    color: #adb5bd;
    transition: all 0.15s;
  }
  .modal-feedback-btn:hover { border-color: #888; color: #fff; }
  .modal-feedback-btn.active-correct {
    background: rgba(46, 204, 64, 0.2);
    border-color: #2ecc40;
    color: #2ecc40;
  }
  .modal-feedback-btn.active-incorrect {
    background: rgba(231, 76, 60, 0.2);
    border-color: #e74c3c;
    color: #e74c3c;
  }
  .feedback-status-label {
    font-size: 0.8rem;
    color: #adb5bd;
    margin-left: auto;
  }
  /* Tag badges on gallery cards */
  .tag-badge { font-size: 0.65rem; margin: 1px; cursor: default; }
  /* Tag chips in modal */
  .tag-chip {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 2px 8px;
    border-radius: 12px;
    background: #444;
    color: #ddd;
    font-size: 0.8rem;
    margin: 2px;
  }
  .tag-chip .remove-tag { cursor: pointer; opacity: 0.7; }
  .tag-chip .remove-tag:hover { opacity: 1; color: #e74c3c; }
  .modal-tag-section {
    margin-top: 12px;
    padding-top: 10px;
    border-top: 1px solid #444;
  }
  /* Skip link for keyboard navigation */
  .skip-link {
    position: absolute;
    top: -100px;
    left: 10px;
    z-index: 9999;
    padding: 8px 16px;
    background: #375a7f;
    color: #fff;
    border-radius: 4px;
    text-decoration: none;
    font-size: 0.9rem;
  }
  .skip-link:focus {
    top: 10px;
  }
  /* Focus styles for keyboard navigation */
  .gallery-card:focus-visible {
    outline: 2px solid #375a7f;
    outline-offset: 2px;
    box-shadow: 0 0 0 4px rgba(55, 90, 127, 0.3);
  }
  .remove-tag:focus-visible {
    outline: 2px solid #375a7f;
    border-radius: 50%;
  }
"))

# -- UI ---------------------------------------------------------------------------
ui <- page_navbar(
  title = "kayoutf",
  theme = bs_theme(bootswatch = "darkly"),
  header = dark_dt_css,

  nav_panel(
    title = "Cards",
    icon  = bs_icon("collection"),
    mod_cards_ui("cards")
  ),

  nav_panel(
    title = "Gallery",
    icon  = bs_icon("images"),
    mod_gallery_ui("gallery", gallery_available, gallery_set_choices,
                   gallery_tag_choices)
  ),

  nav_panel(
    title = "Sets",
    icon  = bs_icon("stack"),
    DT::dataTableOutput("sets_table")
  ),

  nav_panel(
    title = "Rarities",
    icon  = bs_icon("gem"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        width = 250,
        selectInput("rarity_set", "Set",
                    choices = c("All" = "", set_choices), selected = "")
      ),
      DT::dataTableOutput("rarities_table")
    )
  ),

  nav_panel(
    title = "Characters",
    icon  = bs_icon("person"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        width = 250,
        selectInput("char_faction", "Faction",
                    choices = c("All" = "", faction_choices), selected = "")
      ),
      DT::dataTableOutput("characters_table")
    )
  ),

  nav_panel(
    title = "Products",
    icon  = bs_icon("box"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        width = 250,
        selectInput("product_set", "Set",
                    choices = c("All" = "", set_choices), selected = "")
      ),
      DT::dataTableOutput("products_table")
    )
  ),

  nav_spacer(),
  nav_item(input_dark_mode(id = "dark_mode", mode = "dark"))
)

# -- Server -----------------------------------------------------------------------
server <- function(input, output, session) {

  # Modules
  mod_cards_server("cards", all_cards, set_choices, faction_choices,
                   cards_display_cols)
  mod_gallery_server("gallery", gallery_data, gallery_available, repo_root)

  # Simple table tabs
  output$sets_table <- render_dark_dt(all_sets)

  output$rarities_table <- DT::renderDataTable({
    data <- all_rarities
    if (input$rarity_set != "") {
      data <- data[data$set_code == input$rarity_set, ]
    }
    DT::datatable(
      data,
      style    = "bootstrap5",
      class    = "table-dark table-striped table-hover",
      rownames = FALSE,
      options  = list(pageLength = 25, autoWidth = TRUE)
    )
  })

  output$characters_table <- DT::renderDataTable({
    data <- all_characters
    if (input$char_faction != "") {
      data <- data[!is.na(data$faction) & data$faction == input$char_faction, ]
    }
    DT::datatable(
      data,
      style    = "bootstrap5",
      class    = "table-dark table-striped table-hover",
      rownames = FALSE,
      options  = list(pageLength = 25, autoWidth = TRUE)
    )
  })

  output$products_table <- DT::renderDataTable({
    data <- all_products
    if (input$product_set != "") {
      data <- data[data$set_code == input$product_set, ]
    }
    DT::datatable(
      data,
      style    = "bootstrap5",
      class    = "table-dark table-striped table-hover",
      rownames = FALSE,
      options  = list(pageLength = 25, autoWidth = TRUE)
    )
  })
}

shinyApp(ui, server)
