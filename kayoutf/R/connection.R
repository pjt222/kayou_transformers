#' Get DuckDB connection to kayoutf data
#'
#' Returns a singleton DuckDB connection with all Parquet tables registered
#' as views. The connection is created on first use and reused for subsequent
#' calls. It is automatically closed when the package is unloaded.
#'
#' @return A [DBI::dbConnect()] DuckDB connection object.
#' @export
#'
#' @examples
#' \dontrun{
#' con <- kt_connection()
#' DBI::dbListTables(con)
#' DBI::dbGetQuery(con, "SELECT * FROM cards WHERE set_code = 'TFEU01' LIMIT 5")
#' }
kt_connection <- function() {
  if (is.null(.kt_env$con)) {
    .kt_env$con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
    .kt_env$tables_registered <- FALSE
  }

  if (!.kt_env$tables_registered) {
    register_parquet_tables(.kt_env$con)
    .kt_env$tables_registered <- TRUE
  }

  .kt_env$con
}

#' Register Parquet files as DuckDB views
#'
#' @param con A DuckDB connection
#' @keywords internal
register_parquet_tables <- function(con) {
  data_dir <- system.file("extdata", package = "kayoutf")
  tables <- c("sets", "products", "rarities", "cards", "characters", "sources")

  for (table_name in tables) {
    parquet_path <- file.path(data_dir, paste0(table_name, ".parquet"))
    if (file.exists(parquet_path)) {
      query <- sprintf(
        "CREATE OR REPLACE VIEW %s AS SELECT * FROM read_parquet('%s')",
        table_name,
        parquet_path
      )
      DBI::dbExecute(con, query)
    }
  }
}
