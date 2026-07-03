#' Interactively create a metadata YAML file
#'
#' Walks through the fields used by \code{social_meta()} and
#' \code{write_manifest()} at the console and writes the answers to a YAML
#' file. Meant as a quick on-ramp so new users can get a working
#' \code{meta.yml} without first reading the field reference.
#'
#' @param path File to write the metadata to. Defaults to \code{"meta.yml"}.
#'   If the file already exists, its current values are shown as defaults —
#'   press Enter on any field to keep what's already there. Fields the wizard
#'   does not ask about (verification codes, \code{robots}, \code{custom}
#'   tags, and so on) are carried over from the existing file untouched.
#' @return The path to the written file, invisibly.
#' @export
init_meta <- function(path = "meta.yml") {
  if (!is_interactive()) {
    stop("init_meta() requires an interactive session.")
  }

  existing <- list()
  if (file.exists(path)) {
    existing <- read_meta(path)
    message("Found existing ", path, " - press Enter to keep a value as is.\n")
  } else {
    message("Let's set up your metadata. Press Enter to skip an optional field.\n")
  }

  # Start from the existing file so fields the wizard does not ask about
  # (verification codes, robots, custom tags, ...) survive a re-run.
  meta <- existing

  meta$title       <- ask_field("Title (required)", default = existing$title, required = TRUE)
  meta$description <- ask_field("Description (required)", default = existing$description, required = TRUE)
  meta$url         <- ask_field("Canonical URL, e.g. https://example.no (required)", default = existing$url, required = TRUE)
  meta$image       <- ask_field("Share image URL, e.g. https://example.no/share.png (required)", default = existing$image, required = TRUE)

  meta$site_name <- ask_field("Site name (optional, shown in social previews)", default = existing$site_name)
  meta$locale    <- ask_field("Locale (optional)", default = existing$locale %||% "en_US")

  meta$favicon          <- ask_field("Favicon path (optional, e.g. /favicon.svg or /favicon.png)", default = existing$favicon)
  if (!is.null(meta$favicon) && grepl("\\.svg$", meta$favicon, ignore.case = TRUE)) {
    meta$favicon_png <- ask_field(
      "PNG favicon fallback (recommended for SVG favicons -- Chromium address bars don't render SVG icons, e.g. /favicon-32.png)",
      default = existing$favicon_png
    )
  }
  meta$apple_touch_icon <- ask_field("Apple touch icon path (optional, e.g. /apple-touch-icon.png)", default = existing$apple_touch_icon)
  meta$theme_color      <- ask_field("Theme colour (optional, e.g. #1a73e8)", default = existing$theme_color)

  pwa_default <- isTRUE(existing$apple_mobile_web_app_capable) || !is.null(existing$manifest)
  if (ask_yes_no("Should the app be installable as a home screen shortcut (PWA)?", default = pwa_default)) {
    meta$manifest <- existing$manifest %||% "/manifest.json"
    meta$short_name <- ask_field("Short name shown under the home screen icon (optional)", default = existing$short_name)
    meta$apple_mobile_web_app_capable <- TRUE
    meta$apple_mobile_web_app_title <- ask_field("Home screen title (optional, defaults to the short name or title)", default = existing$apple_mobile_web_app_title)
    message("Note: call write_manifest() once at startup (e.g. in global.R) to generate manifest.json.")
  } else {
    # Declining the PWA question is an explicit choice; drop the fields
    # rather than carry them over from the existing file.
    meta$manifest <- NULL
    meta$short_name <- NULL
    meta$apple_mobile_web_app_capable <- NULL
    meta$apple_mobile_web_app_title <- NULL
  }

  meta$twitter_site    <- ask_field("Twitter/X site handle, e.g. @example (optional)", default = existing$twitter_site)
  meta$twitter_creator <- ask_field("Twitter/X creator handle, e.g. @example (optional)", default = existing$twitter_creator)

  meta <- Filter(Negate(is.null), meta)
  meta <- Filter(function(x) !(is.character(x) && !nzchar(x)), meta)

  yaml::write_yaml(meta, path)
  message("\nWrote ", path, ". Use it with social_meta(\"", path, "\").")
  invisible(path)
}

ask_field <- function(prompt, default = NULL, required = FALSE) {
  repeat {
    suffix <- if (!is.null(default)) paste0(" [", default, "]") else ""
    answer <- trimws(ask_console(paste0(prompt, suffix, ": ")))
    if (!nzchar(answer)) {
      if (!is.null(default)) return(default)
      if (!required) return(NULL)
      message("This field is required.")
    } else {
      return(answer)
    }
  }
}

ask_yes_no <- function(prompt, default = TRUE) {
  hint <- if (default) "[Y/n]" else "[y/N]"
  answer <- tolower(trimws(ask_console(paste0(prompt, " ", hint, ": "))))
  if (!nzchar(answer)) return(default)
  identical(answer, "y") || identical(answer, "yes")
}

# Local Variables:
# mode: R
# End:
