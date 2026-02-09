library(shiny)
library(bslib)
library(bsicons)
library(DT)
library(kayoutf)

# -- Load all data once at startup ------------------------------------------------
all_cards      <- kt_cards()
all_sets       <- kt_sets()
all_rarities   <- kt_rarities()
all_characters <- kt_characters()
all_products   <- kt_products()

set_choices    <- sort(unique(all_cards$set_code))
faction_choices <- sort(unique(all_characters$faction[!is.na(all_characters$faction)]))

# -- Gallery: load all images and register resource paths --------------------------
repo_root <- getOption("kayoutf.repo_root")
if (is.null(repo_root)) repo_root <- find_repo_root()

gallery_data <- NULL
gallery_available <- FALSE

if (!is.null(repo_root)) {
  gallery_data <- build_gallery_data(repo_root)
}

# Fallback: if provided path didn't work (e.g. WSL vs Windows), try auto-detect
if (is.null(gallery_data)) {
  auto_root <- find_repo_root()
  if (!is.null(auto_root) && !identical(auto_root, repo_root)) {
    gallery_data <- build_gallery_data(auto_root)
    if (!is.null(gallery_data)) repo_root <- auto_root
  }
}

if (!is.null(gallery_data)) {
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

# Load existing tags for filter choices
gallery_tag_choices <- if (gallery_available && !is.null(repo_root)) {
  existing_tags <- load_tags(repo_root)
  sort(unique(existing_tags$tag))
} else {
  character(0)
}

# -- Display columns for cards table ----------------------------------------------
cards_display_cols <- c(
  "card_id", "set_code", "rarity_code", "card_number",
  "card_name_en", "card_name_zh", "character_name",
  "faction", "card_type", "is_parallel", "product_exclusive"
)

# -- Custom CSS for DT dark-theme + gallery ----------------------------------------
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
  .gallery-card .card-body {
    padding: 8px 10px;
  }
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
  .gallery-badge {
    font-size: 0.7rem;
  }
  .gallery-pagination .btn {
    margin: 0 2px;
  }
  .modal-gallery-img {
    max-width: 100%;
    max-height: 80vh;
    display: block;
    margin: 0 auto;
  }
  /* Feedback overlay icon on gallery cards */
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
  .tag-badge {
    font-size: 0.65rem;
    margin: 1px;
    cursor: default;
  }
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
  .tag-chip .remove-tag {
    cursor: pointer;
    opacity: 0.7;
  }
  .tag-chip .remove-tag:hover {
    opacity: 1;
    color: #e74c3c;
  }
  .modal-tag-section {
    margin-top: 12px;
    padding-top: 10px;
    border-top: 1px solid #444;
  }
"))

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

# -- Gallery UI builder (conditional) ---------------------------------------------
build_gallery_ui <- function() {
  if (!gallery_available) {
    return(
      div(
        class = "alert alert-warning mt-3",
        style = "max-width: 600px; margin: 40px auto;",
        tags$h5(bs_icon("exclamation-triangle"), " Gallery Unavailable"),
        tags$p(
          "Card images require the repository root directory. ",
          "Launch with:"
        ),
        tags$pre(
          'kt_browse(repo_root = "/path/to/kayou_transformers")'
        )
      )
    )
  }

  layout_sidebar(
    sidebar = sidebar(
      title = "Filters",
      width = 280,
      selectInput("gallery_set", "Set",
                  choices = c("All" = "", gallery_set_choices),
                  selected = ""),
      selectInput("gallery_source", "Source",
                  choices = c("All" = "", "Classified" = "classified",
                              "Unclassified" = "unclassified"),
                  selected = ""),
      radioButtons("gallery_type", "Type",
                   choices = c("Cards" = "card", "Non-cards" = "non_card",
                               "All" = "all"),
                   selected = "all", inline = TRUE),
      selectInput("gallery_rarity", "Rarity",
                  choices = c("All" = ""), selected = ""),
      textInput("gallery_character", "Character search",
                placeholder = "e.g. Optimus"),
      selectInput("gallery_confidence", "Confidence",
                  choices = c("All" = "", "high", "medium", "low"),
                  selected = ""),
      selectInput("gallery_review", "Review status",
                  choices = c("All" = "", "Unreviewed" = "unreviewed",
                              "Correct" = "correct", "Incorrect" = "incorrect"),
                  selected = ""),
      selectizeInput("gallery_tags", "Tags",
                     choices = gallery_tag_choices,
                     selected = NULL, multiple = TRUE,
                     options = list(placeholder = "Filter by tags...")),
      selectInput("gallery_page_size", "Per page",
                  choices = c("12", "24", "48"),
                  selected = "24"),
      actionButton("gallery_reset", "Reset filters",
                   class = "btn-outline-secondary btn-sm mt-2")
    ),
    div(
      class = "mb-3",
      textOutput("gallery_count", inline = TRUE)
    ),
    uiOutput("gallery_grid"),
    div(
      class = "gallery-pagination d-flex justify-content-center mt-3 mb-3",
      uiOutput("gallery_pagination")
    )
  )
}

# -- UI ---------------------------------------------------------------------------
ui <- page_navbar(
  title = "kayoutf",
  theme = bs_theme(bootswatch = "darkly"),
  header = dark_dt_css,

  # Cards tab -------------------------------------------------------------------
  nav_panel(
    title = "Cards",
    icon  = bs_icon("collection"),
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        width = 280,
        selectInput("card_set", "Set",
                    choices = c("All" = "", set_choices), selected = ""),
        selectInput("card_rarity", "Rarity",
                    choices = c("All" = ""), selected = ""),
        selectInput("card_faction", "Faction",
                    choices = c("All" = "", faction_choices), selected = ""),
        textInput("card_character", "Character search", placeholder = "e.g. Optimus"),
        actionButton("card_reset", "Reset filters",
                     class = "btn-outline-secondary btn-sm mt-2")
      ),
      layout_column_wrap(
        width = 1 / 4,
        value_box(
          title = "Cards", value = textOutput("vb_cards"),
          showcase = bs_icon("card-heading"), theme = "primary"
        ),
        value_box(
          title = "Sets", value = textOutput("vb_sets"),
          showcase = bs_icon("stack"), theme = "info"
        ),
        value_box(
          title = "Characters", value = textOutput("vb_characters"),
          showcase = bs_icon("person"), theme = "success"
        ),
        value_box(
          title = "Factions", value = textOutput("vb_factions"),
          showcase = bs_icon("shield"), theme = "warning"
        )
      ),
      DT::dataTableOutput("cards_table")
    )
  ),

  # Gallery tab -----------------------------------------------------------------
  nav_panel(
    title = "Gallery",
    icon  = bs_icon("images"),
    build_gallery_ui()
  ),

  # Sets tab --------------------------------------------------------------------
  nav_panel(
    title = "Sets",
    icon  = bs_icon("stack"),
    DT::dataTableOutput("sets_table")
  ),

  # Rarities tab ----------------------------------------------------------------
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

  # Characters tab --------------------------------------------------------------
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

  # Products tab ----------------------------------------------------------------
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

  # Dark-mode toggle in navbar
  nav_spacer(),
  nav_item(input_dark_mode(id = "dark_mode", mode = "dark"))
)

# -- Server -----------------------------------------------------------------------
server <- function(input, output, session) {


  # -- Cards tab: cascading rarity filter ----------------------------------------
  observeEvent(input$card_set, {
    if (input$card_set == "") {
      rarity_options <- sort(unique(all_cards$rarity_code))
    } else {
      rarity_options <- sort(unique(
        all_cards$rarity_code[all_cards$set_code == input$card_set]
      ))
    }
    updateSelectInput(session, "card_rarity",
                      choices = c("All" = "", rarity_options),
                      selected = "")
  })

  # Reset button

  observeEvent(input$card_reset, {
    updateSelectInput(session, "card_set", selected = "")
    updateSelectInput(session, "card_rarity", selected = "")
    updateSelectInput(session, "card_faction", selected = "")
    updateTextInput(session, "card_character", value = "")
  })

  # Filtered cards reactive
  filtered_cards <- reactive({
    cards <- all_cards

    if (input$card_set != "") {
      cards <- cards[cards$set_code == input$card_set, ]
    }
    if (input$card_rarity != "") {
      cards <- cards[cards$rarity_code == input$card_rarity, ]
    }
    if (input$card_faction != "") {
      cards <- cards[!is.na(cards$faction) & cards$faction == input$card_faction, ]
    }
    if (nzchar(input$card_character)) {
      cards <- cards[
        !is.na(cards$character_name) &
          grepl(input$card_character, cards$character_name, ignore.case = TRUE),
      ]
    }

    cards[, cards_display_cols, drop = FALSE]
  })

  # Value boxes
  output$vb_cards <- renderText(nrow(filtered_cards()))
  output$vb_sets  <- renderText(length(unique(filtered_cards()$set_code)))
  output$vb_characters <- renderText({
    chars <- filtered_cards()$character_name
    length(unique(chars[!is.na(chars)]))
  })
  output$vb_factions <- renderText({
    factions <- filtered_cards()$faction
    length(unique(factions[!is.na(factions)]))
  })

  # Cards table
  output$cards_table <- DT::renderDataTable({
    DT::datatable(
      filtered_cards(),
      style    = "bootstrap5",
      class    = "table-dark table-striped table-hover",
      rownames = FALSE,
      options  = list(pageLength = 25, autoWidth = TRUE)
    )
  })

  # -- Sets tab ------------------------------------------------------------------
  output$sets_table <- render_dark_dt(all_sets)

  # -- Rarities tab --------------------------------------------------------------
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

  # -- Characters tab ------------------------------------------------------------
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

  # -- Products tab --------------------------------------------------------------
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

  # -- Gallery tab ---------------------------------------------------------------
  if (gallery_available) {

    gallery_current_page <- reactiveVal(1)

    # Feedback reactive: keyed by "filename|current_directory" -> is_correct
    initial_feedback <- load_feedback_data(repo_root)
    # De-duplicate: keep latest row per image (last row wins)
    if (nrow(initial_feedback) > 0) {
      initial_feedback$key <- paste0(initial_feedback$filename, "|",
                                      initial_feedback$current_directory)
      initial_feedback <- initial_feedback[!duplicated(initial_feedback$key,
                                                        fromLast = TRUE), ]
      feedback_init <- stats::setNames(initial_feedback$is_correct,
                                        initial_feedback$key)
    } else {
      feedback_init <- stats::setNames(logical(0), character(0))
    }
    feedback_rv <- reactiveVal(feedback_init)

    # Tags reactive: load once at startup, updated on add/remove
    tags_rv <- reactiveVal(load_tags(repo_root))

    # Cascading rarity filter based on gallery set
    observeEvent(input$gallery_set, {
      if (input$gallery_set == "") {
        rarity_options <- sort(unique(
          gallery_data$rarity_code[!is.na(gallery_data$rarity_code) &
                                     gallery_data$rarity_code != ""]
        ))
      } else {
        subset <- gallery_data[gallery_data$directory == input$gallery_set, ]
        rarity_options <- sort(unique(
          subset$rarity_code[!is.na(subset$rarity_code) &
                               subset$rarity_code != ""]
        ))
      }
      updateSelectInput(session, "gallery_rarity",
                        choices = c("All" = "", rarity_options),
                        selected = "")
    })

    # Reset gallery filters
    observeEvent(input$gallery_reset, {
      updateSelectInput(session, "gallery_set", selected = "")
      updateSelectInput(session, "gallery_source", selected = "")
      updateRadioButtons(session, "gallery_type", selected = "all")
      updateSelectInput(session, "gallery_rarity", selected = "")
      updateTextInput(session, "gallery_character", value = "")
      updateSelectInput(session, "gallery_confidence", selected = "")
      updateSelectInput(session, "gallery_review", selected = "")
      updateSelectizeInput(session, "gallery_tags", selected = character(0))
      updateSelectInput(session, "gallery_page_size", selected = "24")
    })

    # Filtered gallery data
    filtered_gallery <- reactive({
      data <- gallery_data

      if (input$gallery_set != "") {
        data <- data[data$directory == input$gallery_set, ]
      }
      if (input$gallery_source != "") {
        data <- data[data$source == input$gallery_source, ]
      }
      if (input$gallery_type == "card") {
        data <- data[!is.na(data$is_card) & data$is_card == TRUE, ]
      } else if (input$gallery_type == "non_card") {
        data <- data[!is.na(data$is_card) & data$is_card == FALSE, ]
      }
      if (input$gallery_rarity != "") {
        data <- data[!is.na(data$rarity_code) &
                       data$rarity_code == input$gallery_rarity, ]
      }
      if (nzchar(input$gallery_character)) {
        data <- data[
          !is.na(data$character_name) &
            grepl(input$gallery_character, data$character_name,
                  ignore.case = TRUE),
        ]
      }
      if (input$gallery_confidence != "") {
        data <- data[!is.na(data$confidence) &
                       data$confidence == input$gallery_confidence, ]
      }

      # Review status filter
      if (input$gallery_review != "") {
        fb <- feedback_rv()
        data$fb_key <- paste0(data$filename, "|", data$directory)
        if (input$gallery_review == "unreviewed") {
          data <- data[!(data$fb_key %in% names(fb)), ]
        } else if (input$gallery_review == "correct") {
          correct_keys <- names(fb)[fb == TRUE]
          data <- data[data$fb_key %in% correct_keys, ]
        } else if (input$gallery_review == "incorrect") {
          incorrect_keys <- names(fb)[fb == FALSE]
          data <- data[data$fb_key %in% incorrect_keys, ]
        }
        data$fb_key <- NULL
      }

      # Tag filter: show only images that have ALL selected tags
      selected_tags <- input$gallery_tags
      if (length(selected_tags) > 0) {
        all_tags <- tags_rv()
        if (nrow(all_tags) > 0) {
          data$tag_key <- paste0(data$filename, "|", data$directory)
          all_tags$tag_key <- paste0(all_tags$filename, "|", all_tags$directory)
          # For each image, check it has all selected tags
          keep_keys <- vapply(unique(data$tag_key), function(k) {
            img_tags <- all_tags$tag[all_tags$tag_key == k]
            all(selected_tags %in% img_tags)
          }, logical(1))
          keep_keys <- names(keep_keys)[keep_keys]
          data <- data[data$tag_key %in% keep_keys, ]
          data$tag_key <- NULL
        } else {
          # No tags exist, so no images can match
          data <- data[0, , drop = FALSE]
        }
      }

      data
    })

    # Reset page on filter change
    observeEvent(list(
      input$gallery_set, input$gallery_source, input$gallery_type,
      input$gallery_rarity, input$gallery_character,
      input$gallery_confidence, input$gallery_review,
      input$gallery_tags, input$gallery_page_size
    ), {
      gallery_current_page(1)
    })

    # Page navigation from JS
    observeEvent(input$gallery_page_nav, {
      gallery_current_page(input$gallery_page_nav)
    })

    # Current page data
    gallery_page_data <- reactive({
      data <- filtered_gallery()
      page_size <- as.integer(input$gallery_page_size)
      page <- gallery_current_page()
      start_idx <- (page - 1) * page_size + 1
      end_idx <- min(page * page_size, nrow(data))
      if (start_idx > nrow(data)) return(data[0, ])
      data[start_idx:end_idx, ]
    })

    # Count display
    output$gallery_count <- renderText({
      n <- nrow(filtered_gallery())
      page_size <- as.integer(input$gallery_page_size)
      total_pages <- max(1, ceiling(n / page_size))
      paste0(n, " images | Page ", gallery_current_page(), " of ", total_pages)
    })

    # Image grid
    output$gallery_grid <- renderUI({
      data <- gallery_page_data()
      if (nrow(data) == 0) {
        return(div(
          class = "text-center text-muted mt-4",
          tags$h5("No images match the current filters.")
        ))
      }

      fb <- feedback_rv()
      all_tags <- tags_rv()

      card_elements <- lapply(seq_len(nrow(data)), function(i) {
        row <- data[i, ]
        is_classified <- identical(row$source, "classified")
        dir_name <- row$directory
        img_url <- paste0("gallery-", dir_name, "/", row$filename)
        fb_key <- paste0(row$filename, "|", dir_name)

        # Status badge: classified vs unclassified
        if (is_classified) {
          is_card_badge <- if (isTRUE(row$is_card)) {
            tags$span(class = "badge bg-success gallery-badge", "Card")
          } else {
            tags$span(class = "badge bg-secondary gallery-badge", "Non-card")
          }
        } else {
          is_card_badge <- tags$span(
            class = "badge bg-dark gallery-badge",
            style = "border:1px solid #666;",
            "Unclassified"
          )
        }

        rarity_badge <- if (!is.na(row$rarity_code) &&
                            nzchar(row$rarity_code)) {
          tags$span(class = "badge bg-info gallery-badge ms-1",
                    row$rarity_code)
        }
        conf_badge <- if (is_classified && !is.na(row$confidence) &&
                          nzchar(row$confidence)) {
          conf_class <- switch(row$confidence,
            high   = "bg-success",
            medium = "bg-warning",
            low    = "bg-danger",
            "bg-secondary"
          )
          tags$span(class = paste("badge gallery-badge ms-1", conf_class),
                    row$confidence)
        }
        char_name <- if (!is.na(row$character_name) &&
                         nzchar(row$character_name)) {
          tags$p(class = "card-text", row$character_name)
        }

        # Tag badges
        img_tags <- if (nrow(all_tags) > 0) {
          all_tags$tag[all_tags$filename == row$filename &
                        all_tags$directory == dir_name]
        } else {
          character(0)
        }
        tag_badges <- if (length(img_tags) > 0) {
          div(style = "margin-top:2px;",
            lapply(unique(img_tags), function(t) {
              tags$span(class = "badge bg-primary tag-badge", t)
            })
          )
        }

        # Feedback overlay icon (classified only)
        feedback_icon <- NULL
        if (is_classified) {
          has_feedback <- fb_key %in% names(fb)
          if (has_feedback) {
            if (isTRUE(fb[[fb_key]])) {
              feedback_icon <- tags$span(class = "feedback-overlay correct",
                                         HTML("&#10003;"))
            } else {
              feedback_icon <- tags$span(class = "feedback-overlay incorrect",
                                         HTML("&#10007;"))
            }
          }
        }

        # Escape single quotes in filename for JS
        safe_filename <- gsub("'", "\\\\'", row$filename)
        safe_dir <- gsub("'", "\\\\'", dir_name)

        # Feedback buttons only for classified images
        feedback_buttons <- NULL
        if (is_classified) {
          has_feedback <- fb_key %in% names(fb)
          up_active <- if (has_feedback && isTRUE(fb[[fb_key]])) " active" else ""
          down_active <- if (has_feedback && !isTRUE(fb[[fb_key]])) " active" else ""

          feedback_buttons <- div(
            style = "display:inline-flex; gap:2px; margin-top:4px;",
            tags$button(
              class = paste0("feedback-btn correct", up_active),
              title = "Correct",
              onclick = sprintf(
                "event.stopPropagation(); Shiny.setInputValue('gallery_feedback', {filename:'%s', dir:'%s', is_correct:true}, {priority:'event'})",
                safe_filename, safe_dir
              ),
              HTML("&#9650;")
            ),
            tags$button(
              class = paste0("feedback-btn incorrect", down_active),
              title = "Incorrect",
              onclick = sprintf(
                "event.stopPropagation(); Shiny.setInputValue('gallery_feedback', {filename:'%s', dir:'%s', is_correct:false}, {priority:'event'})",
                safe_filename, safe_dir
              ),
              HTML("&#9660;")
            )
          )
        }

        div(
          class = "col",
          div(
            class = "gallery-card",
            onclick = sprintf(
              "Shiny.setInputValue('gallery_click', {url:'%s', filename:'%s', dir:'%s', source:'%s'}, {priority:'event'})",
              img_url, safe_filename, safe_dir,
              if (is_classified) "classified" else "unclassified"
            ),
            feedback_icon,
            tags$img(
              src = img_url,
              loading = "lazy",
              alt = row$filename
            ),
            div(
              class = "card-body",
              div(is_card_badge, rarity_badge, conf_badge),
              char_name,
              tag_badges,
              tags$p(
                class = "card-text",
                style = "font-size:0.65rem; color:#888;",
                row$filename
              ),
              feedback_buttons
            )
          )
        )
      })

      div(
        class = "row row-cols-2 row-cols-md-3 row-cols-lg-4 row-cols-xl-6 g-3",
        card_elements
      )
    })

    # Pagination controls
    output$gallery_pagination <- renderUI({
      n <- nrow(filtered_gallery())
      page_size <- as.integer(input$gallery_page_size)
      total_pages <- max(1, ceiling(n / page_size))
      current <- gallery_current_page()

      if (total_pages <= 1) return(NULL)

      # Show limited window of page buttons
      page_window <- 5
      start_page <- max(1, current - floor(page_window / 2))
      end_page <- min(total_pages, start_page + page_window - 1)
      start_page <- max(1, end_page - page_window + 1)

      buttons <- list()

      # Previous button
      if (current > 1) {
        buttons <- c(buttons, list(
          tags$button(
            class = "btn btn-sm btn-outline-light",
            onclick = sprintf(
              "Shiny.setInputValue('gallery_page_nav', %d, {priority:'event'})",
              current - 1
            ),
            bs_icon("chevron-left")
          )
        ))
      }

      # First page + ellipsis
      if (start_page > 1) {
        buttons <- c(buttons, list(
          tags$button(
            class = "btn btn-sm btn-outline-light",
            onclick = "Shiny.setInputValue('gallery_page_nav', 1, {priority:'event'})",
            "1"
          )
        ))
        if (start_page > 2) {
          buttons <- c(buttons, list(
            tags$span(class = "mx-1 text-muted", "...")
          ))
        }
      }

      # Page number buttons
      for (p in start_page:end_page) {
        btn_class <- if (p == current) {
          "btn btn-sm btn-primary"
        } else {
          "btn btn-sm btn-outline-light"
        }
        buttons <- c(buttons, list(
          tags$button(
            class = btn_class,
            onclick = sprintf(
              "Shiny.setInputValue('gallery_page_nav', %d, {priority:'event'})",
              p
            ),
            as.character(p)
          )
        ))
      }

      # Last page + ellipsis
      if (end_page < total_pages) {
        if (end_page < total_pages - 1) {
          buttons <- c(buttons, list(
            tags$span(class = "mx-1 text-muted", "...")
          ))
        }
        buttons <- c(buttons, list(
          tags$button(
            class = "btn btn-sm btn-outline-light",
            onclick = sprintf(
              "Shiny.setInputValue('gallery_page_nav', %d, {priority:'event'})",
              total_pages
            ),
            as.character(total_pages)
          )
        ))
      }

      # Next button
      if (current < total_pages) {
        buttons <- c(buttons, list(
          tags$button(
            class = "btn btn-sm btn-outline-light",
            onclick = sprintf(
              "Shiny.setInputValue('gallery_page_nav', %d, {priority:'event'})",
              current + 1
            ),
            bs_icon("chevron-right")
          )
        ))
      }

      do.call(tagList, buttons)
    })

    # Click-to-enlarge modal with feedback and tags
    observeEvent(input$gallery_click, {
      click_data <- input$gallery_click
      img_url <- click_data$url
      click_filename <- click_data$filename
      click_dir <- click_data$dir
      is_classified <- identical(click_data$source, "classified")
      fb_key <- paste0(click_filename, "|", click_dir)

      # Look up details
      match_row <- gallery_data[gallery_data$filename == click_filename &
                                  gallery_data$directory == click_dir, ]

      detail_tags <- if (nrow(match_row) > 0) {
        r <- match_row[1, ]
        tagList(
          tags$div(
            style = "margin-top:10px; font-size:0.85rem; color:#adb5bd;",
            tags$span(tags$strong("Set: "), r$directory, " | "),
            if (!is.na(r$rarity_code) && nzchar(r$rarity_code))
              tags$span(tags$strong("Rarity: "), r$rarity_code, " | "),
            if (!is.na(r$character_name) && nzchar(r$character_name))
              tags$span(tags$strong("Character: "), r$character_name, " | "),
            if (is_classified && !is.na(r$confidence) && nzchar(r$confidence))
              tags$span(tags$strong("Confidence: "), r$confidence)
          )
        )
      }

      safe_fn <- gsub("'", "\\\\'", click_filename)
      safe_d <- gsub("'", "\\\\'", click_dir)

      # Feedback UI — only for classified images
      feedback_ui <- NULL
      if (is_classified) {
        fb <- feedback_rv()
        has_fb <- fb_key %in% names(fb)
        status_label <- if (has_fb) {
          if (isTRUE(fb[[fb_key]])) {
            tags$span(class = "feedback-status-label",
                      HTML("&#10003; Marked correct"))
          } else {
            tags$span(class = "feedback-status-label",
                      HTML("&#10007; Marked incorrect"))
          }
        }

        correct_class <- if (has_fb && isTRUE(fb[[fb_key]])) " active-correct" else ""
        incorrect_class <- if (has_fb && !isTRUE(fb[[fb_key]])) " active-incorrect" else ""

        feedback_ui <- div(
          class = "modal-feedback-section",
          tags$button(
            class = paste0("modal-feedback-btn", correct_class),
            onclick = sprintf(
              "Shiny.setInputValue('modal_feedback', {filename:'%s', dir:'%s', is_correct:true}, {priority:'event'})",
              safe_fn, safe_d
            ),
            HTML("&#10003; Correct")
          ),
          tags$button(
            class = paste0("modal-feedback-btn", incorrect_class),
            onclick = sprintf(
              "Shiny.setInputValue('modal_feedback', {filename:'%s', dir:'%s', is_correct:false}, {priority:'event'})",
              safe_fn, safe_d
            ),
            HTML("&#10007; Incorrect")
          ),
          status_label
        )
      }

      # Tag management section
      all_tags <- tags_rv()
      img_tags <- if (nrow(all_tags) > 0) {
        unique(all_tags$tag[all_tags$filename == click_filename &
                             all_tags$directory == click_dir])
      } else {
        character(0)
      }

      # Existing tags as removable chips
      tag_chips <- if (length(img_tags) > 0) {
        lapply(img_tags, function(t) {
          safe_tag <- gsub("'", "\\\\'", t)
          tags$span(
            class = "tag-chip",
            t,
            tags$span(
              class = "remove-tag",
              onclick = sprintf(
                "Shiny.setInputValue('remove_tag', {filename:'%s', dir:'%s', tag:'%s'}, {priority:'event'})",
                safe_fn, safe_d, safe_tag
              ),
              HTML("&times;")
            )
          )
        })
      }

      # All existing tag names for suggestions
      all_tag_names <- sort(unique(all_tags$tag))

      tag_ui <- div(
        class = "modal-tag-section",
        tags$strong("Tags", style = "color:#adb5bd; font-size:0.85rem;"),
        div(style = "margin:6px 0;", tag_chips),
        div(
          style = "display:flex; gap:6px; align-items:center;",
          tags$input(
            id = "modal_tag_input", type = "text",
            class = "form-control form-control-sm",
            style = "max-width:200px; background:#303030; color:#ddd; border-color:#555;",
            placeholder = "Add tag...",
            list = "tag_suggestions"
          ),
          tags$datalist(
            id = "tag_suggestions",
            lapply(all_tag_names, function(t) tags$option(value = t))
          ),
          tags$button(
            class = "btn btn-sm btn-outline-primary",
            onclick = sprintf(
              "var v=document.getElementById('modal_tag_input').value.trim(); if(v){Shiny.setInputValue('add_tag', {filename:'%s', dir:'%s', tag:v}, {priority:'event'}); document.getElementById('modal_tag_input').value='';}",
              safe_fn, safe_d
            ),
            "Add"
          )
        )
      )

      showModal(modalDialog(
        tags$img(
          src = img_url,
          class = "modal-gallery-img"
        ),
        detail_tags,
        feedback_ui,
        tag_ui,
        size = "l",
        easyClose = TRUE,
        footer = modalButton("Close")
      ))
    })

    # Feedback handler for gallery card buttons
    observeEvent(input$gallery_feedback, {
      fb_data <- input$gallery_feedback
      save_feedback(repo_root, fb_data$filename, fb_data$dir, fb_data$is_correct)
      fb <- feedback_rv()
      key <- paste0(fb_data$filename, "|", fb_data$dir)
      fb[[key]] <- fb_data$is_correct
      feedback_rv(fb)
    })

    # Feedback handler for modal buttons
    observeEvent(input$modal_feedback, {
      fb_data <- input$modal_feedback
      save_feedback(repo_root, fb_data$filename, fb_data$dir, fb_data$is_correct)
      fb <- feedback_rv()
      key <- paste0(fb_data$filename, "|", fb_data$dir)
      fb[[key]] <- fb_data$is_correct
      feedback_rv(fb)
      removeModal()
    })

    # Tag add handler
    observeEvent(input$add_tag, {
      tag_data <- input$add_tag
      save_tag(repo_root, tag_data$filename, tag_data$dir, tag_data$tag)
      tags_rv(load_tags(repo_root))
      # Update sidebar tag filter choices
      updateSelectizeInput(session, "gallery_tags",
                           choices = sort(unique(tags_rv()$tag)),
                           selected = input$gallery_tags)
      removeModal()
    })

    # Tag remove handler
    observeEvent(input$remove_tag, {
      tag_data <- input$remove_tag
      remove_tag(repo_root, tag_data$filename, tag_data$dir, tag_data$tag)
      tags_rv(load_tags(repo_root))
      updateSelectizeInput(session, "gallery_tags",
                           choices = sort(unique(tags_rv()$tag)),
                           selected = input$gallery_tags)
      removeModal()
    })
  }
}

shinyApp(ui, server)
