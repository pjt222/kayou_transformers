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

# -- Display columns for cards table ----------------------------------------------
cards_display_cols <- c(
  "card_id", "set_code", "rarity_code", "card_number",
  "card_name_en", "card_name_zh", "character_name",
  "faction", "card_type", "is_parallel", "product_exclusive"
)

# -- Custom CSS for DT dark-theme compatibility ------------------------------------
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
}

shinyApp(ui, server)
