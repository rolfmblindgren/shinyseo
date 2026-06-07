#' Interactively create a metadata YAML file
#'
#' Walks through the fields used by \code{social_meta()} and
#' \code{write_manifest()} at the console and writes the answers to a YAML
#' file. Meant as a quick on-ramp so new users can get a working
#' \code{meta.yml} without first reading the field reference.
#'
#' @param path File to write the metadata to. Defaults to \code{"meta.yml"}.
#'   If the file already exists, you will be asked whether to overwrite it.
#' @return The path to the written file, invisibly.
#' @export
init_meta <- function(path = "meta.yml") {
  if (!is_interactive()) {
    stop("init_meta() requires an interactive session.")
  }

  if (file.exists(path) &&
      !ask_yes_no(paste0(path, " already exists. Overwrite?"), default = FALSE)) {
    message("Cancelled; ", path, " left untouched.")
    return(invisible(path))
  }

  message("Let's set up your metadata. Press Enter to skip an optional field.\n")

  meta <- list()

  meta$title       <- ask_field("Title (required)", required = TRUE)
  meta$description <- ask_field("Description (required)", required = TRUE)
  meta$url         <- ask_field("Canonical URL, e.g. https://example.no (required)", required = TRUE)
  meta$image       <- ask_field("Share image URL, e.g. https://example.no/share.png (required)", required = TRUE)

  meta$site_name <- ask_field("Site name (optional, shown in social previews)")
  meta$locale    <- ask_field("Locale (optional)", default = "en_US")

  meta$favicon          <- ask_field("Favicon path (optional, e.g. /favicon.png)")
  meta$apple_touch_icon <- ask_field("Apple touch icon path (optional, e.g. /apple-touch-icon.png)")
  meta$theme_color      <- ask_field("Theme colour (optional, e.g. #1a73e8)")

  if (ask_yes_no("Should the app be installable as a home screen shortcut (PWA)?", default = FALSE)) {
    meta$manifest <- "/manifest.json"
    meta$short_name <- ask_field("Short name shown under the home screen icon (optional)")
    meta$apple_mobile_web_app_capable <- TRUE
    meta$apple_mobile_web_app_title <- ask_field("Home screen title (optional, defaults to the short name or title)")
    message("Note: call write_manifest() once at startup (e.g. in global.R) to generate manifest.json.")
  }

  meta$twitter_site    <- ask_field("Twitter/X site handle, e.g. @example (optional)")
  meta$twitter_creator <- ask_field("Twitter/X creator handle, e.g. @example (optional)")

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
