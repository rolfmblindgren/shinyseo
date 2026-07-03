`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

is_interactive <- function() {
  interactive()
}

ask_console <- function(prompt) {
  readline(prompt)
}

favicon_mime <- function(path, explicit_type = NULL) {
  if (!is.null(explicit_type)) return(explicit_type)
  ext <- tolower(tools::file_ext(path))
  switch(ext,
    ico  = "image/x-icon",
    png  = "image/png",
    svg  = "image/svg+xml",
    webp = "image/webp",
    gif  = "image/gif",
    jpg  = ,
    jpeg = "image/jpeg",
    "image/x-icon"
  )
}

# Local Variables:
# mode: R
# End:
