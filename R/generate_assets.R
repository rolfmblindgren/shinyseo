#' Generate missing visual assets with a user-supplied LLM or image API
#'
#' Looks for missing favicon, Apple touch icon, and share image fields in
#' \code{meta} and asks a caller-supplied \code{generator} function to create
#' them. shinyseo does not call any image-generation service itself --
#' \code{generator} is the caller's own function, written against whatever
#' LLM or image-generation API they already have access to (OpenAI, Adobe
#' Firefly, a local model, and so on). This keeps the package free of any
#' particular vendor's dependencies, API keys, formats, or running costs --
#' the caller's function is the only thing that needs to know which service
#' it is talking to.
#'
#' @param meta Either a path to a YAML file or a named list, as for
#'   \code{social_meta()}.
#' @param generator A function taking \code{(prompt, kind)} and returning
#'   either a raw vector of image bytes or a path to an image file on disk.
#'   \code{kind} is one of \code{"favicon"}, \code{"apple_touch_icon"}, or
#'   \code{"image"}, so the same generator can vary size, aspect ratio, or
#'   style depending on what is being made.
#' @param path Directory to write generated files into. Defaults to
#'   \code{"www"}, matching \code{write_manifest()}.
#' @param assets Character vector naming which fields to fill in if missing.
#'   Defaults to all three: \code{c("favicon", "apple_touch_icon", "image")}.
#' @return The updated \code{meta} list, with newly generated fields set to
#'   paths under \code{path} (e.g. \code{"/favicon.png"}). Fields already
#'   present in \code{meta} are left untouched. Write the result back with
#'   \code{yaml::write_yaml()} to persist it.
#' @export
generate_assets <- function(meta, generator, path = "www",
                            assets = c("favicon", "apple_touch_icon", "image")) {
  if (is.character(meta)) {
    meta <- read_meta(meta)
  }
  stopifnot(is.list(meta), is.function(generator))

  valid <- c("favicon", "apple_touch_icon", "image")
  if (!all(assets %in% valid)) {
    stop("`assets` must be one or more of: ", paste(valid, collapse = ", "))
  }

  missing <- Filter(function(kind) is.null(meta[[kind]]), assets)
  if (length(missing) == 0L) {
    return(meta)
  }

  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  for (kind in missing) {
    result <- generator(asset_prompt(kind, meta), kind)
    meta[[kind]] <- write_generated_asset(result, kind, path)
  }

  meta
}

asset_prompt <- function(kind, meta) {
  subject <- meta$site_name %||% meta$title
  blurb   <- meta$description %||% ""

  switch(kind,
    favicon = paste0(
      "A simple, square favicon for an app called \"", subject, "\". ",
      "Flat design, bold shapes, no text, recognizable at 16x16 pixels."
    ),
    apple_touch_icon = paste0(
      "A square home-screen icon (180x180) for an app called \"", subject, "\". ",
      blurb, " Bold, simple, and legible at small sizes, no text."
    ),
    image = paste0(
      "A wide social share image (1200x630) for \"", subject, "\". ",
      blurb, " Suitable for Open Graph and Twitter Card link previews."
    )
  )
}

asset_filename <- function(kind) {
  switch(kind,
    favicon          = "favicon",
    apple_touch_icon = "apple-touch-icon",
    image            = "share-image"
  )
}

raw_image_ext <- function(bytes) {
  starts_with <- function(...) {
    prefix <- as.raw(c(...))
    length(bytes) >= length(prefix) && identical(bytes[seq_along(prefix)], prefix)
  }
  if (starts_with(0x89, 0x50, 0x4e, 0x47)) return("png")
  if (starts_with(0xff, 0xd8, 0xff))       return("jpg")
  if (starts_with(0x47, 0x49, 0x46, 0x38)) return("gif")
  if (length(bytes) >= 12L &&
      identical(bytes[1:4],  as.raw(c(0x52, 0x49, 0x46, 0x46))) &&
      identical(bytes[9:12], as.raw(c(0x57, 0x45, 0x42, 0x50)))) return("webp")
  "png"
}

write_generated_asset <- function(result, kind, path) {
  if (is.raw(result)) {
    bytes <- result
    ext   <- raw_image_ext(bytes)
  } else if (is.character(result) && length(result) == 1L) {
    if (!file.exists(result)) {
      stop("generator() returned a path that does not exist: ", result)
    }
    bytes <- readBin(result, "raw", n = file.info(result)$size)
    ext   <- tools::file_ext(result)
    if (!nzchar(ext)) ext <- "png"
  } else {
    stop("generator() must return a raw vector of image bytes or a single file path, not ",
         class(result)[1])
  }

  filename <- paste0(asset_filename(kind), ".", ext)
  writeBin(bytes, file.path(path, filename))

  paste0("/", filename)
}

# Local Variables:
# mode: R
# End:
