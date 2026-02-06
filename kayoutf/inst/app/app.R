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

# -- Gallery: load classification data and register resource paths -----------------
repo_root <- getOption("kayoutf.repo_root")
if (is.null(repo_root)) repo_root <- find_repo_root()

gallery_data <- NULL
gallery_available <- FALSE

if (!is.null(repo_root)) {
  gallery_data <- load_classification_data(repo_root)
  if (!is.null(gallery_data)) {
    gallery_available <- TRUE
    # Register resource paths per set so images are servable
    gallery_sets <- unique(gallery_data$current_directory)
    for (set_dir in gallery_sets) {
      cards_path <- file.path(repo_root, set_dir, "cards")
      if (dir.exists(cards_path)) {
        shiny::addResourcePath(paste0("gallery-", set_dir), cards_path)
      }
    }
  }
}

gallery_set_choices <- if (gallery_available) {
  sort(unique(gallery_data$current_directory))
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
      radioButtons("gallery_type", "Type",
                   choices = c("Cards" = "card", "Non-cards" = "non_card",
                               "All" = "all"),
                   selected = "card", inline = TRUE),
      selectInput("gallery_rarity", "Rarity",
                  choices = c("All" = ""), selected = ""),
      textInput("gallery_character", "Character search",
                placeholder = "e.g. Optimus"),
      selectInput("gallery_confidence", "Confidence",
                  choices = c("All" = "", "high", "medium", "low"),
                  selected = ""),
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

    # Cascading rarity filter based on gallery set
    observeEvent(input$gallery_set, {
      if (input$gallery_set == "") {
        rarity_options <- sort(unique(
          gallery_data$rarity_code[!is.na(gallery_data$rarity_code) &
                                     gallery_data$rarity_code != ""]
        ))
      } else {
        subset <- gallery_data[gallery_data$current_directory == input$gallery_set, ]
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
      updateRadioButtons(session, "gallery_type", selected = "card")
      updateSelectInput(session, "gallery_rarity", selected = "")
      updateTextInput(session, "gallery_character", value = "")
      updateSelectInput(session, "gallery_confidence", selected = "")
      updateSelectInput(session, "gallery_page_size", selected = "24")
    })

    # Filtered gallery data
    filtered_gallery <- reactive({
      data <- gallery_data

      if (input$gallery_set != "") {
        data <- data[data$current_directory == input$gallery_set, ]
      }
      if (input$gallery_type == "card") {
        data <- data[data$is_card == TRUE, ]
      } else if (input$gallery_type == "non_card") {
        data <- data[data$is_card == FALSE, ]
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

      data
    })

    # Reset page on filter change
    observeEvent(list(
      input$gallery_set, input$gallery_type, input$gallery_rarity,
      input$gallery_character, input$gallery_confidence,
      input$gallery_page_size
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

      card_elements <- lapply(seq_len(nrow(data)), function(i) {
        row <- data[i, ]
        img_url <- paste0("gallery-", row$current_directory, "/",
                          row$filename)
        is_card_badge <- if (isTRUE(row$is_card)) {
          tags$span(class = "badge bg-success gallery-badge", "Card")
        } else {
          tags$span(class = "badge bg-secondary gallery-badge", "Non-card")
        }
        rarity_badge <- if (!is.na(row$rarity_code) &&
                            nzchar(row$rarity_code)) {
          tags$span(class = "badge bg-info gallery-badge ms-1",
                    row$rarity_code)
        }
        conf_badge <- if (!is.na(row$confidence) && nzchar(row$confidence)) {
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

        # Unique id for click handler
        card_id <- paste0("gallery_img_", i)

        div(
          class = "col",
          div(
            class = "gallery-card",
            onclick = sprintf(
              "Shiny.setInputValue('gallery_click', '%s', {priority:'event'})",
              img_url
            ),
            tags$img(
              src = img_url,
              loading = "lazy",
              alt = row$filename
            ),
            div(
              class = "card-body",
              div(is_card_badge, rarity_badge, conf_badge),
              char_name,
              tags$p(
                class = "card-text",
                style = "font-size:0.65rem; color:#888;",
                row$filename
              )
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

    # Click-to-enlarge modal
    observeEvent(input$gallery_click, {
      img_url <- input$gallery_click
      showModal(modalDialog(
        tags$img(
          src = img_url,
          class = "modal-gallery-img"
        ),
        size = "l",
        easyClose = TRUE,
        footer = modalButton("Close")
      ))
    })
  }
}

shinyApp(ui, server)
