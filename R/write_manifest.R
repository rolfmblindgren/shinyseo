#' Write a web app manifest to the Shiny www directory
#'
#' Generates a \href{https://developer.mozilla.org/en-US/docs/Web/Manifest}{Web
#' App Manifest} (\code{manifest.json}) and writes it to \code{www/} so Shiny
#' can serve it at \code{/manifest.json}.  Call this once in \code{global.R}
#' before the app starts.
#'
#' Reference \code{manifest.json} from the UI by passing
#' \code{manifest = "/manifest.json"} to \code{social_meta()}.
#'
#' @param meta Either a path to a YAML file or a named list.  The same object
#'   you pass to \code{social_meta()} works here.
#' @param path Directory to write \code{manifest.json} into.  Defaults to
#'   \code{"www"} relative to the working directory.
#' @param display Browser display mode.  One of \code{"standalone"},
#'   \code{"fullscreen"}, \code{"minimal-ui"}, or \code{"browser"}.  Defaults
#'   to \code{"standalone"}.
#' @param start_url Start URL passed to the manifest.  Defaults to \code{"/"}.
#' @param background_color Background colour shown on the splash screen while
#'   the app loads.  Defaults to \code{theme_color} when set, otherwise
#'   \code{"#ffffff"}.
#' @return The path to the written file, invisibly.
#' @export
write_manifest <- function(meta, path = "www", display = "standalone",
                           start_url = "/", background_color = NULL) {
  if (is.character(meta)) {
    meta <- read_meta(meta)
  }
  meta <- apply_defaults(meta)

  required <- c("title", "description")
  missing  <- setdiff(required, names(meta))
  if (length(missing)) {
    stop("Missing required meta fields for manifest: ", paste(missing, collapse = ", "))
  }

  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  bg <- background_color %||% meta$theme_color %||% "#ffffff"

  manifest <- list(
    name        = meta$title,
    short_name  = meta$short_name %||% meta$title,
    description = meta$description,
    display     = display,
    start_url   = start_url,
    lang        = gsub("_", "-", meta$locale)
  )

  if (!is.null(meta$theme_color)) {
    manifest$theme_color <- meta$theme_color
  }
  manifest$background_color <- bg

  icons <- list()
  if (!is.null(meta$apple_touch_icon)) {
    icons <- c(icons, list(list(
      src   = meta$apple_touch_icon,
      sizes = "180x180",
      type  = "image/png"
    )))
  }
  if (!is.null(meta$favicon) && grepl("\\.png$", meta$favicon, ignore.case = TRUE)) {
    icons <- c(icons, list(list(
      src   = meta$favicon,
      sizes = "any",
      type  = "image/png"
    )))
  }
  if (!is.null(meta$favicon_png)) {
    icons <- c(icons, list(list(
      src   = meta$favicon_png,
      sizes = meta$favicon_png_sizes %||% "32x32",
      type  = "image/png"
    )))
  }
  if (length(icons)) {
    manifest$icons <- icons
  }

  dest <- file.path(path, "manifest.json")
  writeLines(jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE), dest)
  invisible(dest)
}

# Local Variables:
# mode: R
# End:
