#' Reactively update social metadata from the server
#'
#' Call this inside a Shiny \code{server} function to update one or more
#' metadata fields after the page has loaded — for example when the user
#' navigates between tabs or routes.  Only the fields you supply are changed;
#' all others stay at whatever value \code{social_meta()} set at startup.
#'
#' @param session The Shiny \code{session} object passed to \code{server}.
#' @param title New page title.  Also updates \code{og:title} and
#'   \code{twitter:title}.
#' @param description New description.  Also updates \code{og:description} and
#'   \code{twitter:description}.
#' @param url New canonical URL.  Also updates \code{og:url} and
#'   \code{twitter:url}.
#' @param image New share image URL.  Also updates \code{og:image} and
#'   \code{twitter:image}, and removes any \code{og:image:width},
#'   \code{og:image:height}, \code{og:image:type}, \code{og:image:alt}, and
#'   \code{twitter:image:alt} tags, since those described the old image.
#' @return Called for its side-effect; returns \code{invisible(NULL)}.
#' @export
update_meta <- function(session, title = NULL, description = NULL,
                        url = NULL, image = NULL) {
  fields <- list(title = title, description = description,
                 url = url, image = image)
  fields <- Filter(Negate(is.null), fields)
  if (length(fields) == 0L) {
    return(invisible(NULL))
  }
  session$sendCustomMessage("shinyseo_update_meta", fields)
  invisible(NULL)
}

# Local Variables:
# mode: R
# End:
