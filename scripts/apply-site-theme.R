apply_site_theme <- function(path) {
  lesson_root <- normalizePath(path, mustWork = TRUE)
  styles_path <- file.path(lesson_root, "site", "docs", "assets", "styles.css")
  theme_path <- file.path(lesson_root, "pkgdown", "extra.css")
  font_source <- file.path(lesson_root, "episodes", "files", "RINGM___.TTF")
  font_destination <- file.path(lesson_root, "site", "docs", "assets", "fonts", "RINGM___.TTF")
  marker <- "/* Ringbearer display font */"
  append_once <- function(lines, addition) {
    if (marker %in% lines) lines else c(lines, "", addition)
  }
  styles <- readLines(styles_path, warn = FALSE)
  theme <- readLines(theme_path, warn = FALSE)
  writeLines(append_once(styles, theme), styles_path, useBytes = TRUE)
  if (file.exists(font_source)) {
    dir.create(dirname(font_destination), recursive = TRUE, showWarnings = FALSE)
    invisible(file.copy(font_source, font_destination, overwrite = TRUE))
  } else if (file.exists(font_destination)) {
    invisible(unlink(font_destination))
  }
  invisible(NULL)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  apply_site_theme(args[[1]])
}
