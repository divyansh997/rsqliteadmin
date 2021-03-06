#' create_table UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom DT DTOutput
#' @importFrom DT renderDT
#' @importFrom DT datatable
#' @importFrom RSQLite dbExecute

mod_create_table_ui <- function(id) {
  ns <- NS(id)
  tabPanel(title = "Create Tables",
           column(
             width = 12,
             fluidRow(column(width = 12, h2(
               "Create a New Table"
             ))),
             fluidRow(column(
               width = 12, textInput(
                 inputId = ns("new_table_name"),
                 label = p("Enter New Table Name")
               )
             )),
             fluidRow(column(
               width = 12, conditionalPanel(
                 condition = paste0("input['", ns("new_table_name"), "'] != ''"),
                 column(
                   width = 12,
                   fluidRow(DT::DTOutput(ns(
                     "display_new_table"
                   ))),
                   fluidRow(
                     actionButton(inputId =  ns("add_column"),
                                  label = "Add a New Column"),
                     actionButton(inputId = ns("remove_columns"),
                                  label = "Remove Selected Columns"),
                     actionButton(inputId = ns("reset_columns"),
                                  label = "Reset Columns"),
                     actionButton(inputId = ns("create_new_table"),
                                  label = "Create New Table")
                   )
                 )
               )
             )),
             br()
           ))
}

#' create_table Server Function
#'
#' @noRd

mod_create_table_server <- function(input, output, session, conn) {
  ns <- session$ns
  
  # info$new_table_columns - information about the columns user is adding along with the corresponding
  #                          column details query in the first column.
  
  info <- reactiveValues(
    new_table_columns = data.frame(
      column_query = character(),
      Column_Name = character(),
      Data_Type = character(),
      Primary_Key = logical(),
      Unique = logical(),
      Not_Null = logical(),
      Default = logical(),
      Check_Condition = logical(),
      Collate = logical(),
      Foreign_Key = logical(),
      stringsAsFactors = FALSE
    )
  )
  
  # action_create_table$created_table - reactive value to notify other modules of creating a table.
  
  action_create_table <- reactiveValues(created_table = NULL)
  
  output$display_new_table <-
    DT::renderDT(expr = {
      DT::datatable(
        data = info$new_table_columns[, c(-1)],
        rownames = FALSE,
        selection = "multiple"
      )
    })
  
  # Displaying the new table structure inside the modal dialog box.
  
  output$display_new_table_modal <-
    DT::renderDT(expr = {
      DT::datatable(
        data = info$new_table_columns[, c(-1,-4:-10)],
        rownames = FALSE,
        selection = "multiple"
      )
    })
  
  # Reference for how to write conditions for conditional panels here:
  # https://github.com/rstudio/shiny/issues/1586
  
  observeEvent(input$add_column, {
    showModal(modalDialog(
      size = "l",
      title = "Add New Columns",
      column(
        width = 12,
        fluidRow(
          column(width = 6,
                 textInput(
                   inputId = ns("column_name"), label = "Column Name"
                 )),
          column(
            width = 6,
            selectInput(
              inputId = ns("data_type"),
              label = "Data Type",
              choices = c(
                "BIGINT",
                "BLOB",
                "BOOLEAN",
                "CHAR",
                "DATE",
                "DATETIME",
                "DECIMAL",
                "DOUBLE",
                "INTEGER",
                "INT",
                "NONE",
                "NUMERIC",
                "REAL",
                "STRING",
                "TEXT",
                "TIME",
                "VARCHAR"
              )
            )
          )
        ),
        fluidRow(
          column(width = 3, checkboxInput(
            inputId = ns("primary_key"), label = "Primary Key"
          )),
          column(
            width = 9,
            conditionalPanel(
              condition = paste0("input['", ns("primary_key"), "'] == true"),
              fluidRow(column(
                width = 12,
                checkboxInput(
                  inputId = ns("autoincrement_primary_key"),
                  label = "Autoincrement"
                )
              )),
              fluidRow(
                column(
                  width = 6,
                  selectizeInput(
                    inputId = ns("sort_order_primary_key"),
                    label = "Sort Order",
                    choices = c("ASC", "DEC"),
                    options = list(
                      placeholder = "Select an Option/ Leave Empty",
                      onInitialize = I('function() { this.setValue(""); }')
                    )
                  )
                ),
                column(
                  width = 6,
                  selectizeInput(
                    inputId = ns("on_conflict_primary_key"),
                    label = "On Conflict",
                    choices = c("ROLLBACK", "ABORT", "FAIL", "IGNORE", "REPLACE"),
                    options = list(
                      placeholder = "Select an Option/ Leave Empty",
                      onInitialize = I('function() { this.setValue(""); }')
                    )
                  )
                )
              )
            )
          )
        ),
        fluidRow(
          column(width = 3,
                 checkboxInput(
                   inputId = ns("unique"), label = "Unique"
                 )),
          column(width = 9,
                 conditionalPanel(
                   condition = paste0("input['", ns("unique"), "'] == true"),
                   fluidRow(column(
                     width = 12,
                     selectizeInput(
                       inputId = ns("on_conflict_unique"),
                       label = "On Conflict",
                       choices = c("ROLLBACK", "ABORT", "FAIL", "IGNORE", "REPLACE"),
                       options = list(
                         placeholder = "Select an Option/ Leave Empty",
                         onInitialize = I('function() { this.setValue(""); }')
                       )
                     )
                   ))
                 ))
        ),
        fluidRow(
          column(width = 3,
                 checkboxInput(
                   inputId = ns("not_null"), label = "Not Null"
                 )),
          column(width = 9,
                 conditionalPanel(
                   condition = paste0("input['", ns("not_null"), "'] == true"),
                   fluidRow(column(
                     width = 12,
                     selectizeInput(
                       inputId = ns("on_conflict_not_null"),
                       label = "On Conflict",
                       choices = c("ROLLBACK", "ABORT", "FAIL", "IGNORE", "REPLACE"),
                       options = list(
                         placeholder = "Select an Option/ Leave Empty",
                         onInitialize = I('function() { this.setValue(""); }')
                       )
                     )
                   ))
                 ))
        ),
        fluidRow(
          column(width = 3,
                 checkboxInput(
                   inputId = ns("default"), label = "Default Value"
                 )),
          column(width = 9,
                 conditionalPanel(
                   condition = paste0("input['", ns("default"), "'] == true"),
                   fluidRow(column(
                     width = 12,
                     textInput(
                       inputId = ns("default_value_default"),
                       label = "Specify Default Value"
                     )
                   ))
                 ))
        ),
        fluidRow(
          column(
            width = 3,
            checkboxInput(inputId = ns("check_condition"),
                          label = "Check Condition")
          ),
          column(width = 9,
                 conditionalPanel(
                   condition = paste0("input['", ns("check_condition"), "'] == true"),
                   fluidRow(column(
                     width = 12,
                     textInput(
                       inputId = ns("specify_condition_check_condition"),
                       label = "Specify Condition"
                     )
                   ))
                 ))
        ),
        fluidRow(
          column(width = 3,
                 checkboxInput(
                   inputId = ns("collate"), label = "Collate"
                 )),
          column(width = 9,
                 conditionalPanel(
                   condition = paste0("input['", ns("collate"), "'] == true"),
                   fluidRow(column(
                     width = 12,
                     selectInput(
                       inputId = ns("collation_type_collate"),
                       label = "Collation Type",
                       choices = c("RTRIM", "NOCASE", "BINARY")
                     )
                   ))
                 ))
        ),
        fluidRow(
          column(width = 3,
                 checkboxInput(
                   inputId = ns("foreign_key"),
                   label = "Foreign Key"
                 )),
          column(
            width = 9,
            conditionalPanel(
              condition = paste0("input['", ns("foreign_key"), "'] == true"),
              fluidRow(
                column(
                  width = 6,
                  selectInput(
                    inputId = ns("foreign_table_foreign_key"),
                    label = "Select Foreign Table",
                    choices = NULL
                  )
                ),
                column(
                  width = 6,
                  selectInput(
                    inputId = ns("foreign_column_foreign_key"),
                    label = "Select Foreign Column",
                    choices = NULL
                  )
                )
              ),
              fluidRow(
                column(
                  width = 6,
                  selectizeInput(
                    inputId = ns("on_update_foreign_key"),
                    label = "ON UPDATE",
                    choices = c("NO ACTION",
                                "SET NULL",
                                "SET DEFAULT",
                                "CASCADE",
                                "RESTRICT"),
                    options = list(
                      placeholder = "Select an Option/ Leave Empty",
                      onInitialize = I('function() { this.setValue(""); }')
                    )
                  )
                ),
                column(
                  width = 6,
                  selectizeInput(
                    inputId = ns("on_delete_foreign_key"),
                    label = "ON DELETE",
                    choices = c("NO ACTION",
                                "SET NULL",
                                "SET DEFAULT",
                                "CASCADE",
                                "RESTRICT"),
                    options = list(
                      placeholder = "Select an Option/ Leave Empty",
                      onInitialize = I('function() { this.setValue(""); }')
                    )
                  )
                )
              ),
              fluidRow(
                column(
                  width = 6,
                  selectizeInput(
                    inputId = ns("match_foreign_key"),
                    label = "MATCH",
                    choices = c("SIMPLE", "PARTIAL", "FULL"),
                    options = list(
                      placeholder = "Select an Option/ Leave Empty",
                      onInitialize = I('function() { this.setValue(""); }')
                    )
                  )
                ),
                column(
                  width = 6,
                  selectizeInput(
                    inputId = ns("defer_first_foreign_key"),
                    choices = c("DEFERRABLE", "NON DEFERRABLE"),
                    label = "Deferred Foreign Key:",
                    options = list(
                      placeholder = "Select an Option/ Leave Empty",
                      onInitialize = I('function() { this.setValue(""); }')
                    )
                  )
                )
              ),
              fluidRow(column(
                width = 6,
                selectizeInput(
                  inputId = ns("defer_second_foreign_key"),
                  choices = c("DEFERRED", "IMMEDIATE"),
                  label = "Initially:",
                  options = list(
                    placeholder = "Select an Option/ Leave Empty",
                    onInitialize = I('function() { this.setValue(""); }')
                  )
                )
              ))
            )
          )
        ),
        fluidRow(column(
          width = 12,
          actionButton(inputId = ns("confirm_column"),
                       label = "Confirm Column Details")
        )),
        br(),
        br(),
        fluidRow(column(width = 12,
                        DT::DTOutput(
                          ns("display_new_table_modal")
                        )))
      )
    ))
  })
  
  observeEvent(input$foreign_key, {
    if (!is.null(conn$active_db)) {
      updateSelectInput(
        session = session,
        inputId = "foreign_table_foreign_key",
        choices = RSQLite::dbListTables(conn$active_db)
      )
    }
  })
  
  observeEvent(input$foreign_table_foreign_key, {
    if (input$foreign_table_foreign_key != "") {
      updateSelectInput(
        session = session,
        inputId = "foreign_column_foreign_key",
        choices = RSQLite::dbGetQuery(
          conn$active_db,
          table_structure_query(input$foreign_table_foreign_key)
        )$name
      )
    }
  })
  
  observeEvent(input$confirm_column, {
    if (input$column_name == "")
      showNotification(ui = "Please enter column name.",
                       duration = 3,
                       type = "error")
    else if (isTRUE(input$default) &&
             input$default_value_default == "")
      showNotification(ui = "Please specify default value.",
                       duration = 3,
                       type = "error")
    else if (isTRUE(input$check_condition) &&
             input$specify_condition_check_condition == "")
      showNotification(ui = "Please specify check condition.",
                       duration = 3,
                       type = "error")
    else if (input$defer_first_foreign_key == "" &&
             input$defer_second_foreign_key != "")
      showNotification(ui = "Deferred foreign key constraints not completely specified.",
                       duration = 3,
                       type = "error")
    else{
      column_details_query <-
        column_details_query(
          column_name = input$column_name,
          data_type = input$data_type,
          primary_key = input$primary_key,
          autoincrement_primary_key = input$autoincrement_primary_key,
          sort_order_primary_key = input$sort_order_primary_key,
          on_conflict_primary_key = input$on_conflict_primary_key,
          unique = input$unique,
          on_conflict_unique = input$on_conflict_unique,
          not_null = input$not_null,
          on_conflict_not_null = input$on_conflict_not_null,
          default = input$default,
          default_value_default = input$default_value_default,
          check_condition = input$check_condition,
          specify_condition_check_condition = input$specify_condition_check_condition,
          collate = input$collate,
          collation_type_collate = input$collation_type_collate,
          foreign_key = input$foreign_key,
          foreign_table_foreign_key = input$foreign_table_foreign_key,
          foreign_column_foreign_key = input$foreign_column_foreign_key,
          on_update_foreign_key = input$on_update_foreign_key,
          on_delete_foreign_key = input$on_delete_foreign_key,
          match_foreign_key = input$match_foreign_key,
          defer_first_foreign_key = input$defer_first_foreign_key,
          defer_second_foreign_key = input$defer_second_foreign_key
        )
      
      # rbind() messes with column names
      # Reference here: https://stackoverflow.com/q/5231540/
      
      info$new_table_columns[nrow(info$new_table_columns) + 1,] <-
        c(
          column_details_query,
          input$column_name,
          input$data_type,
          input$primary_key,
          input$unique,
          input$not_null,
          input$default,
          input$check_condition,
          input$collate,
          input$foreign_key
        )
      showNotification(ui = "Column added successfully.",
                       duration = 3,
                       type = "message")
    }
  })
  
  observeEvent(input$create_new_table, {
    if (input$new_table_name == "")
      showNotification(ui = "Please specify a table name.",
                       duration = 3,
                       type = "error")
    else if (nrow(info$new_table_columns) == 0)
      showNotification(ui = "Please add atleast one column first.",
                       duration = 3,
                       type = "error")
    else{
      create_table_query <- create_table_query(input$new_table_name,
                                               info$new_table_columns$column_query)
      tryCatch({
        RSQLite::dbExecute(conn$active_db, create_table_query)
        
        action_create_table$created_table <-
          input$create_new_table
        
        updateTextInput(session,
                        inputId = "new_table_name",
                        value = "")
        
        info$new_table_columns <- data.frame(
          column_query = character(),
          Column_Name = character(),
          Data_Type = character(),
          Primary_Key = logical(),
          Unique = logical(),
          Not_Null = logical(),
          Default = logical(),
          Check_Condition = logical(),
          Collate = logical(),
          Foreign_Key = logical(),
          stringsAsFactors = FALSE
        )
        
        showNotification(ui = "Table Created Successfully.",
                         duration = 3,
                         type = "message")
      },
      error = function(err) {
        showNotification(
          ui =  paste0(err, ". Table not created."),
          duration = 3,
          type = "error"
        )
      })
    }
  })
  
  # Recreate an empty table to reset columns.
  
  observeEvent(input$reset_columns, {
    info$new_table_columns <- data.frame(
      column_query = character(),
      Column_Name = character(),
      Data_Type = character(),
      Primary_Key = logical(),
      Unique = logical(),
      Not_Null = logical(),
      Default = logical(),
      Check_Condition = logical(),
      Collate = logical(),
      Foreign_Key = logical(),
      stringsAsFactors = FALSE
    )
  })
  
  observeEvent(input$remove_columns, {
    if (is.null(input$display_new_table_rows_selected))
      showNotification(ui = "No column selected",
                       duration = 3,
                       type = "error")
    else{
      info$new_table_columns <-
        info$new_table_columns[-as.numeric(input$display_new_table_rows_selected),]
    }
  })
  
  return(action_create_table)
}

## To be copied in the UI
# mod_create_table_ui("create_table_ui_1")

## To be copied in the server
# callModule(mod_create_table_server, "create_table_ui_1")

