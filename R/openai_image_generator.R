#' Build a generator that calls OpenAI's image API
#'
#' Returns a function suitable for the \code{generator} argument of
#' \code{generate_assets()}. The returned function calls OpenAI's image
#' generation endpoint and hands back the raw image bytes, so
#' \code{generate_assets()} can write them straight to disk.
#'
#' This is the only built-in generator shinyseo ships. It exists because
#' OpenAI's image API is a straightforward fit for the job -- one endpoint,
#' one request shape, raster images back. Other providers are welcome as
#' community contributions (see \code{LLM.md}); shinyseo does not bundle a
#' generator for every LLM vendor, only ones that can actually generate
#' images and pull their weight as a built-in.
#'
#' Calling this function does not make any network request -- it only builds
#' and returns the generator. The 'httr' package is required, but only
#' loaded (via \code{requireNamespace()}) when you call this constructor, so
#' it costs nothing if you never use OpenAI generation.
#'
#' @param api_key OpenAI API key. Defaults to the \code{OPENAI_API_KEY}
#'   environment variable.
#' @param model OpenAI image model to call. Defaults to \code{"gpt-image-1"}.
#' @return A function \code{function(prompt, kind)} that POSTs to
#'   \code{https://api.openai.com/v1/images/generations} and returns the
#'   generated image as a raw vector of bytes.
#' @export
openai_image_generator <- function(api_key = Sys.getenv("OPENAI_API_KEY"),
                                   model = "gpt-image-1") {
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("openai_image_generator() requires the 'httr' package. ",
         "Install it with install.packages(\"httr\").")
  }
  if (!nzchar(api_key)) {
    stop("openai_image_generator() needs an OpenAI API key. Pass `api_key = ` ",
         "or set the OPENAI_API_KEY environment variable.")
  }

  function(prompt, kind) {
    size <- switch(kind,
      favicon          = "1024x1024",
      apple_touch_icon = "1024x1024",
      image            = "1536x1024",
      stop("Unknown asset kind: ", kind)
    )

    response <- httr::POST(
      "https://api.openai.com/v1/images/generations",
      httr::add_headers(Authorization = paste("Bearer", api_key)),
      encode = "json",
      body = list(model = model, prompt = prompt, size = size, n = 1L)
    )

    if (httr::http_error(response)) {
      # Error bodies are usually JSON, but a proxy or gateway may answer
      # with HTML; fall back to the status line rather than a parse error.
      detail <- tryCatch(
        httr::content(response, as = "parsed", type = "application/json")$error$message,
        error = function(e) NULL
      )
      stop("OpenAI image generation failed: ",
           detail %||% httr::http_status(response)$message)
    }

    parsed <- httr::content(response, as = "parsed", type = "application/json")
    jsonlite::base64_dec(parsed$data[[1L]]$b64_json)
  }
}

# Local Variables:
# mode: R
# End:
