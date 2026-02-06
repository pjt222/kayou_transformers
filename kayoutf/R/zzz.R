# Package environment for storing DuckDB connection
.kt_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .kt_env$con <- NULL
  .kt_env$tables_registered <- FALSE
}

.onUnload <- function(libpath) {
  kt_disconnect()
}

#' Disconnect the internal DuckDB connection
#'
#' @keywords internal
kt_disconnect <- function() {
  if (!is.null(.kt_env$con)) {
    tryCatch(
      DBI::dbDisconnect(.kt_env$con, shutdown = TRUE),
      error = function(e) NULL
    )
    .kt_env$con <- NULL
    .kt_env$tables_registered <- FALSE
  }
  invisible(NULL)
}
