serve_lesson <- function(path, host, port) {
  lesson_root <- normalizePath(path, mustWork = TRUE)
  site_path <- file.path(lesson_root, "site")
  git_path <- file.path(lesson_root, ".git")
  source(file.path(lesson_root, "scripts", "apply-site-theme.R"), local = TRUE)
  build_targets <- function(paths) {
    if (!any(fs::is_file(paths))) {
      paths
    } else {
      markdown <- paths[endsWith(paths, "md")]
      if (length(markdown)) markdown else lesson_root
    }
  }
  render <- function(paths = lesson_root) {
    targets <- build_targets(paths)
    invisible(lapply(targets, sandpaper::build_lesson, preview = FALSE, quiet = FALSE))
    apply_site_theme(lesson_root)
  }
  filter <- function(paths) {
    paths[!startsWith(paths, site_path) & !startsWith(paths, git_path)]
  }
  render()
  servr::httw(
    file.path(site_path, "docs"),
    watch = lesson_root,
    filter = filter,
    handler = render,
    host = host,
    port = port
  )
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  serve_lesson(args[[1]], args[[2]], as.integer(args[[3]]))
}
