# Cards tab Shiny module
# Provides filterable card browser with value boxes and DT table

mod_cards_ui <- function(id) {
  ns <- NS(id)

  layout_sidebar(
    sidebar = sidebar(
      title = "Filters",
      width = 280,
      selectInput(ns("set"), "Set",
                  choices = c("All" = ""), selected = ""),
      selectInput(ns("rarity"), "Rarity",
                  choices = c("All" = ""), selected = ""),
      selectInput(ns("faction"), "Faction",
                  choices = c("All" = ""), selected = ""),
      textInput(ns("character"), "Character search",
                placeholder = "e.g. Optimus"),
      actionButton(ns("reset"), "Reset filters",
                   class = "btn-outline-secondary btn-sm mt-2")
    ),
    layout_column_wrap(
      width = 1 / 4,
      value_box(
        title = "Cards", value = textOutput(ns("vb_cards")),
        showcase = bs_icon("card-heading"), theme = "primary"
      ),
      value_box(
        title = "Sets", value = textOutput(ns("vb_sets")),
        showcase = bs_icon("stack"), theme = "info"
      ),
      value_box(
        title = "Characters", value = textOutput(ns("vb_characters")),
        showcase = bs_icon("person"), theme = "success"
      ),
      value_box(
        title = "Factions", value = textOutput(ns("vb_factions")),
        showcase = bs_icon("shield"), theme = "warning"
      )
    ),
    DT::dataTableOutput(ns("table"))
  )
}

mod_cards_server <- function(id, all_cards, set_choices, faction_choices,
                             display_cols) {
  moduleServer(id, function(input, output, session) {

    character_d <- debounce(reactive(input$character), 300)

    # Cascading rarity filter
    observeEvent(input$set, {
      if (input$set == "") {
        rarity_options <- sort(unique(all_cards$rarity_code))
      } else {
        rarity_options <- sort(unique(
          all_cards$rarity_code[all_cards$set_code == input$set]
        ))
      }
      updateSelectInput(session, "rarity",
                        choices = c("All" = "", rarity_options),
                        selected = "")
    })

    # Populate set/faction choices once
    updateSelectInput(session, "set",
                      choices = c("All" = "", set_choices))
    updateSelectInput(session, "faction",
                      choices = c("All" = "", faction_choices))

    # Reset
    observeEvent(input$reset, {
      updateSelectInput(session, "set", selected = "")
      updateSelectInput(session, "rarity", selected = "")
      updateSelectInput(session, "faction", selected = "")
      updateTextInput(session, "character", value = "")
    })

    # Filtered cards
    filtered <- reactive({
      cards <- all_cards
      if (input$set != "") {
        cards <- cards[cards$set_code == input$set, ]
      }
      if (input$rarity != "") {
        cards <- cards[cards$rarity_code == input$rarity, ]
      }
      if (input$faction != "") {
        cards <- cards[!is.na(cards$faction) &
                         cards$faction == input$faction, ]
      }
      if (nzchar(character_d())) {
        cards <- cards[
          !is.na(cards$character_name) &
            grepl(character_d(), cards$character_name, ignore.case = TRUE),
        ]
      }
      cards[, display_cols, drop = FALSE]
    })

    # Value boxes
    output$vb_cards <- renderText(nrow(filtered()))
    output$vb_sets  <- renderText(length(unique(filtered()$set_code)))
    output$vb_characters <- renderText({
      chars <- filtered()$character_name
      length(unique(chars[!is.na(chars)]))
    })
    output$vb_factions <- renderText({
      factions <- filtered()$faction
      length(unique(factions[!is.na(factions)]))
    })

    # Data table
    output$table <- DT::renderDataTable({
      DT::datatable(
        filtered(),
        style    = "bootstrap5",
        class    = "table-dark table-striped table-hover",
        rownames = FALSE,
        options  = list(pageLength = 25, autoWidth = TRUE)
      )
    })
  })
}
