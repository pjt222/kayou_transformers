# Gallery tab Shiny module
# Image gallery with classification, feedback, tags, and filtering

mod_gallery_ui <- function(id, gallery_available, gallery_set_choices,
                           gallery_tag_choices) {
  ns <- NS(id)

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
      selectInput(ns("set"), "Set",
                  choices = c("All" = "", gallery_set_choices),
                  selected = ""),
      selectInput(ns("source"), "Source",
                  choices = c("All" = "", "Classified" = "classified",
                              "Unclassified" = "unclassified"),
                  selected = ""),
      radioButtons(ns("type"), "Type",
                   choices = c("Cards" = "card", "Non-cards" = "non_card",
                               "All" = "all"),
                   selected = "all", inline = TRUE),
      selectInput(ns("rarity"), "Rarity",
                  choices = c("All" = ""), selected = ""),
      textInput(ns("character"), "Character search",
                placeholder = "e.g. Optimus"),
      selectInput(ns("confidence"), "Confidence",
                  choices = c("All" = "", "high", "medium", "low"),
                  selected = ""),
      selectInput(ns("review"), "Review status",
                  choices = c("All" = "", "Unreviewed" = "unreviewed",
                              "Correct" = "correct", "Incorrect" = "incorrect"),
                  selected = ""),
      selectizeInput(ns("tags"), "Tags",
                     choices = gallery_tag_choices,
                     selected = NULL, multiple = TRUE,
                     options = list(placeholder = "Filter by tags...")),
      selectInput(ns("page_size"), "Per page",
                  choices = c("12", "24", "48"),
                  selected = "24"),
      actionButton(ns("reset"), "Reset filters",
                   class = "btn-outline-secondary btn-sm mt-2")
    ),
    div(
      class = "mb-3",
      textOutput(ns("count"), inline = TRUE)
    ),
    uiOutput(ns("grid")),
    div(
      class = "gallery-pagination d-flex justify-content-center mt-3 mb-3",
      uiOutput(ns("pagination"))
    )
  )
}

mod_gallery_server <- function(id, gallery_data, gallery_available,
                               repo_root) {
  moduleServer(id, function(input, output, session) {
    if (!gallery_available) return()

    ns <- session$ns
    current_page <- reactiveVal(1)

    character_d <- debounce(reactive(input$character), 300)

    # -- Feedback reactive -------------------------------------------------------
    initial_feedback <- load_feedback_data(repo_root)
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

    # -- Tags reactive -----------------------------------------------------------
    tags_rv <- reactiveVal(load_tags(repo_root))

    # -- Cascading rarity filter -------------------------------------------------
    observeEvent(input$set, {
      if (input$set == "") {
        rarity_options <- sort(unique(
          gallery_data$rarity_code[!is.na(gallery_data$rarity_code) &
                                     gallery_data$rarity_code != ""]
        ))
      } else {
        subset <- gallery_data[gallery_data$directory == input$set, ]
        rarity_options <- sort(unique(
          subset$rarity_code[!is.na(subset$rarity_code) &
                               subset$rarity_code != ""]
        ))
      }
      updateSelectInput(session, "rarity",
                        choices = c("All" = "", rarity_options),
                        selected = "")
    })

    # -- Reset filters -----------------------------------------------------------
    observeEvent(input$reset, {
      updateSelectInput(session, "set", selected = "")
      updateSelectInput(session, "source", selected = "")
      updateRadioButtons(session, "type", selected = "all")
      updateSelectInput(session, "rarity", selected = "")
      updateTextInput(session, "character", value = "")
      updateSelectInput(session, "confidence", selected = "")
      updateSelectInput(session, "review", selected = "")
      updateSelectizeInput(session, "tags", selected = character(0))
      updateSelectInput(session, "page_size", selected = "24")
    })

    # -- Filtered gallery data ---------------------------------------------------
    filtered <- reactive({
      data <- gallery_data
      if (input$set != "") {
        data <- data[data$directory == input$set, ]
      }
      if (input$source != "") {
        data <- data[data$source == input$source, ]
      }
      if (input$type == "card") {
        data <- data[!is.na(data$is_card) & data$is_card == TRUE, ]
      } else if (input$type == "non_card") {
        data <- data[!is.na(data$is_card) & data$is_card == FALSE, ]
      }
      if (input$rarity != "") {
        data <- data[!is.na(data$rarity_code) &
                       data$rarity_code == input$rarity, ]
      }
      if (nzchar(character_d())) {
        data <- data[
          !is.na(data$character_name) &
            grepl(character_d(), data$character_name, ignore.case = TRUE),
        ]
      }
      if (input$confidence != "") {
        data <- data[!is.na(data$confidence) &
                       data$confidence == input$confidence, ]
      }

      # Review status filter
      if (input$review != "") {
        fb <- feedback_rv()
        data$fb_key <- paste0(data$filename, "|", data$directory)
        if (input$review == "unreviewed") {
          data <- data[!(data$fb_key %in% names(fb)), ]
        } else if (input$review == "correct") {
          correct_keys <- names(fb)[fb == TRUE]
          data <- data[data$fb_key %in% correct_keys, ]
        } else if (input$review == "incorrect") {
          incorrect_keys <- names(fb)[fb == FALSE]
          data <- data[data$fb_key %in% incorrect_keys, ]
        }
        data$fb_key <- NULL
      }

      # Tag filter
      selected_tags <- input$tags
      if (length(selected_tags) > 0) {
        all_tags <- tags_rv()
        if (nrow(all_tags) > 0) {
          data$tag_key <- paste0(data$filename, "|", data$directory)
          all_tags$tag_key <- paste0(all_tags$filename, "|", all_tags$directory)
          keep_keys <- vapply(unique(data$tag_key), function(k) {
            img_tags <- all_tags$tag[all_tags$tag_key == k]
            all(selected_tags %in% img_tags)
          }, logical(1))
          keep_keys <- names(keep_keys)[keep_keys]
          data <- data[data$tag_key %in% keep_keys, ]
          data$tag_key <- NULL
        } else {
          data <- data[0, , drop = FALSE]
        }
      }

      data
    })

    # -- Reset page on filter change ---------------------------------------------
    observeEvent(list(
      input$set, input$source, input$type,
      input$rarity, character_d(),
      input$confidence, input$review,
      input$tags, input$page_size
    ), {
      current_page(1)
    })

    # -- Page navigation ---------------------------------------------------------
    observeEvent(input$page_nav, {
      current_page(input$page_nav)
    })

    # -- Current page data -------------------------------------------------------
    page_data <- reactive({
      data <- filtered()
      page_size <- as.integer(input$page_size)
      page <- current_page()
      start_idx <- (page - 1) * page_size + 1
      end_idx <- min(page * page_size, nrow(data))
      if (start_idx > nrow(data)) return(data[0, ])
      data[start_idx:end_idx, ]
    })

    # -- Count display -----------------------------------------------------------
    output$count <- renderText({
      n <- nrow(filtered())
      page_size <- as.integer(input$page_size)
      total_pages <- max(1, ceiling(n / page_size))
      paste0(n, " images | Page ", current_page(), " of ", total_pages)
    })

    # -- Image grid --------------------------------------------------------------
    output$grid <- renderUI({
      data <- page_data()
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

        # Status badge
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

        # Feedback overlay
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

        safe_filename <- gsub("'", "\\\\'", row$filename)
        safe_dir <- gsub("'", "\\\\'", dir_name)

        # Feedback buttons (classified only)
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
                "event.stopPropagation(); Shiny.setInputValue('%s', {filename:'%s', dir:'%s', is_correct:true}, {priority:'event'})",
                ns("gallery_feedback"), safe_filename, safe_dir
              ),
              HTML("&#9650;")
            ),
            tags$button(
              class = paste0("feedback-btn incorrect", down_active),
              title = "Incorrect",
              onclick = sprintf(
                "event.stopPropagation(); Shiny.setInputValue('%s', {filename:'%s', dir:'%s', is_correct:false}, {priority:'event'})",
                ns("gallery_feedback"), safe_filename, safe_dir
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
              "Shiny.setInputValue('%s', {url:'%s', filename:'%s', dir:'%s', source:'%s'}, {priority:'event'})",
              ns("click"), img_url, safe_filename, safe_dir,
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

    # -- Pagination controls -----------------------------------------------------
    output$pagination <- renderUI({
      n <- nrow(filtered())
      page_size <- as.integer(input$page_size)
      total_pages <- max(1, ceiling(n / page_size))
      current <- current_page()

      if (total_pages <= 1) return(NULL)

      page_window <- 5
      start_page <- max(1, current - floor(page_window / 2))
      end_page <- min(total_pages, start_page + page_window - 1)
      start_page <- max(1, end_page - page_window + 1)

      buttons <- list()

      # Previous
      if (current > 1) {
        buttons <- c(buttons, list(
          tags$button(
            class = "btn btn-sm btn-outline-light",
            onclick = sprintf(
              "Shiny.setInputValue('%s', %d, {priority:'event'})",
              ns("page_nav"), current - 1
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
            onclick = sprintf(
              "Shiny.setInputValue('%s', 1, {priority:'event'})",
              ns("page_nav")
            ),
            "1"
          )
        ))
        if (start_page > 2) {
          buttons <- c(buttons, list(
            tags$span(class = "mx-1 text-muted", "...")
          ))
        }
      }

      # Page numbers
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
              "Shiny.setInputValue('%s', %d, {priority:'event'})",
              ns("page_nav"), p
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
              "Shiny.setInputValue('%s', %d, {priority:'event'})",
              ns("page_nav"), total_pages
            ),
            as.character(total_pages)
          )
        ))
      }

      # Next
      if (current < total_pages) {
        buttons <- c(buttons, list(
          tags$button(
            class = "btn btn-sm btn-outline-light",
            onclick = sprintf(
              "Shiny.setInputValue('%s', %d, {priority:'event'})",
              ns("page_nav"), current + 1
            ),
            bs_icon("chevron-right")
          )
        ))
      }

      do.call(tagList, buttons)
    })

    # -- Click-to-enlarge modal --------------------------------------------------
    observeEvent(input$click, {
      click_data <- input$click
      img_url <- click_data$url
      click_filename <- click_data$filename
      click_dir <- click_data$dir
      is_classified <- identical(click_data$source, "classified")
      fb_key <- paste0(click_filename, "|", click_dir)

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

      # Feedback UI (classified only)
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
              "Shiny.setInputValue('%s', {filename:'%s', dir:'%s', is_correct:true}, {priority:'event'})",
              ns("modal_feedback"), safe_fn, safe_d
            ),
            HTML("&#10003; Correct")
          ),
          tags$button(
            class = paste0("modal-feedback-btn", incorrect_class),
            onclick = sprintf(
              "Shiny.setInputValue('%s', {filename:'%s', dir:'%s', is_correct:false}, {priority:'event'})",
              ns("modal_feedback"), safe_fn, safe_d
            ),
            HTML("&#10007; Incorrect")
          ),
          status_label
        )
      }

      # Tag management
      all_tags <- tags_rv()
      img_tags <- if (nrow(all_tags) > 0) {
        unique(all_tags$tag[all_tags$filename == click_filename &
                             all_tags$directory == click_dir])
      } else {
        character(0)
      }

      tag_chips <- if (length(img_tags) > 0) {
        lapply(img_tags, function(t) {
          safe_tag <- gsub("'", "\\\\'", t)
          tags$span(
            class = "tag-chip",
            t,
            tags$span(
              class = "remove-tag",
              onclick = sprintf(
                "Shiny.setInputValue('%s', {filename:'%s', dir:'%s', tag:'%s'}, {priority:'event'})",
                ns("remove_tag"), safe_fn, safe_d, safe_tag
              ),
              HTML("&times;")
            )
          )
        })
      }

      all_tag_names <- sort(unique(all_tags$tag))

      # Use a namespaced ID for the text input so it doesn't clash
      tag_input_id <- ns("modal_tag_input")

      tag_ui <- div(
        class = "modal-tag-section",
        tags$strong("Tags", style = "color:#adb5bd; font-size:0.85rem;"),
        div(style = "margin:6px 0;", tag_chips),
        div(
          style = "display:flex; gap:6px; align-items:center;",
          tags$input(
            id = tag_input_id, type = "text",
            class = "form-control form-control-sm",
            style = "max-width:200px; background:#303030; color:#ddd; border-color:#555;",
            placeholder = "Add tag...",
            list = ns("tag_suggestions")
          ),
          tags$datalist(
            id = ns("tag_suggestions"),
            lapply(all_tag_names, function(t) tags$option(value = t))
          ),
          tags$button(
            class = "btn btn-sm btn-outline-primary",
            onclick = sprintf(
              "var v=document.getElementById('%s').value.trim(); if(v){Shiny.setInputValue('%s', {filename:'%s', dir:'%s', tag:v}, {priority:'event'}); document.getElementById('%s').value='';}",
              tag_input_id, ns("add_tag"), safe_fn, safe_d, tag_input_id
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

    # -- Feedback handlers -------------------------------------------------------
    observeEvent(input$gallery_feedback, {
      fb_data <- input$gallery_feedback
      save_feedback(repo_root, fb_data$filename, fb_data$dir, fb_data$is_correct)
      fb <- feedback_rv()
      key <- paste0(fb_data$filename, "|", fb_data$dir)
      fb[[key]] <- fb_data$is_correct
      feedback_rv(fb)
    })

    observeEvent(input$modal_feedback, {
      fb_data <- input$modal_feedback
      save_feedback(repo_root, fb_data$filename, fb_data$dir, fb_data$is_correct)
      fb <- feedback_rv()
      key <- paste0(fb_data$filename, "|", fb_data$dir)
      fb[[key]] <- fb_data$is_correct
      feedback_rv(fb)
      removeModal()
    })

    # -- Tag handlers ------------------------------------------------------------
    observeEvent(input$add_tag, {
      tag_data <- input$add_tag
      save_tag(repo_root, tag_data$filename, tag_data$dir, tag_data$tag)
      tags_rv(load_tags(repo_root))
      updateSelectizeInput(session, "tags",
                           choices = sort(unique(tags_rv()$tag)),
                           selected = input$tags)
      removeModal()
    })

    observeEvent(input$remove_tag, {
      tag_data <- input$remove_tag
      remove_tag(repo_root, tag_data$filename, tag_data$dir, tag_data$tag)
      tags_rv(load_tags(repo_root))
      updateSelectizeInput(session, "tags",
                           choices = sort(unique(tags_rv()$tag)),
                           selected = input$tags)
      removeModal()
    })
  })
}
