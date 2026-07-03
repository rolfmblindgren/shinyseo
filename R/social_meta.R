#' Inject social metadata into Shiny UI
#'
#' @param meta Either a path to a YAML file or a named list. The final
#'   metadata must include \code{title}, \code{description}, \code{url}, and
#'   \code{image}.
#' @return A \code{shiny::tags$head()} fragment containing canonical, Open
#'   Graph, Twitter Card, and optional schema.org metadata.
#' @details If \code{meta} is a character string, it is treated as a YAML file
#'   path and decoded as UTF-8 regardless of the active locale. Set the
#'   \code{schema} field in \code{meta} to \code{FALSE} to suppress JSON-LD
#'   output. \code{bing_site_verification} falls back to
#'   \code{SHINYSEO_BING_SITE_VERIFICATION} when that environment variable is
#'   set. \code{twitter_site} and \code{twitter_creator} fall back to
#'   \code{SHINYSEO_TWITTER_SITE} and
#'   \code{SHINYSEO_TWITTER_CREATOR} when those environment variables are set.
#'   The helper does not emit a \code{<title>} tag; set the document title in
#'   the app UI so it does not clash with an existing Shiny title.
#'   If \code{favicon} points to an SVG, also set \code{favicon_png} to a PNG
#'   fallback (e.g. 32x32) -- Chromium-based browsers' address bar does not
#'   render SVG favicons and shows a generic globe icon without one.
#'   \code{favicon_png_sizes} overrides the \code{sizes} attribute (defaults
#'   to \code{"32x32"}).
#'   Set \code{apple_mobile_web_app_capable = TRUE} to let the app run in
#'   standalone mode when added to a phone's home screen (emits
#'   \code{apple-mobile-web-app-capable} and \code{mobile-web-app-capable}).
#'   \code{apple_mobile_web_app_title} sets the name shown under the home
#'   screen icon, and \code{apple_mobile_web_app_status_bar_style} controls
#'   the iOS status bar appearance.
#'   Optional verification fields include
#'   \code{bing_site_verification}, \code{google_site_verification},
#'   \code{yandex_site_verification}, \code{baidu_site_verification},
#'   \code{naver_site_verification}, \code{facebook_domain_verification},
#'   and \code{pinterest_domain_verification}.
#' @export
social_meta <- function(meta) {
  if (is.character(meta)) {
    meta <- read_meta(meta)
  }
  meta <- apply_defaults(meta)

  required <- c("title", "description", "url", "image")
  missing <- setdiff(required, names(meta))
  if (length(missing)) {
    stop("Missing required meta fields: ", paste(missing, collapse = ", "))
  }

  schema <- build_schema_meta(meta)

  shiny::tags$head(
    shiny::tags$link(rel="canonical", href=meta$url),

    if (!is.null(meta$favicon))
      shiny::tags$link(rel="icon", type=favicon_mime(meta$favicon, meta$favicon_type),
                       href=meta$favicon),

    if (!is.null(meta$favicon_png))
      shiny::tags$link(rel="icon", type="image/png",
                       sizes=meta$favicon_png_sizes %||% "32x32",
                       href=meta$favicon_png),

    if (!is.null(meta$apple_touch_icon))
      shiny::tags$link(rel="apple-touch-icon", href=meta$apple_touch_icon),

    if (!is.null(meta$manifest))
      shiny::tags$link(rel="manifest", href=meta$manifest),

    if (!is.null(meta$theme_color))
      shiny::tags$meta(name="theme-color", content=meta$theme_color),

    if (isTRUE(meta$apple_mobile_web_app_capable))
      shiny::tags$meta(name="apple-mobile-web-app-capable", content="yes"),

    if (isTRUE(meta$apple_mobile_web_app_capable))
      shiny::tags$meta(name="mobile-web-app-capable", content="yes"),

    if (!is.null(meta$apple_mobile_web_app_title))
      shiny::tags$meta(name="apple-mobile-web-app-title", content=meta$apple_mobile_web_app_title),

    if (!is.null(meta$apple_mobile_web_app_status_bar_style))
      shiny::tags$meta(name="apple-mobile-web-app-status-bar-style", content=meta$apple_mobile_web_app_status_bar_style),

    shiny::tags$meta(name="description", content=meta$description),
    shiny::tags$meta(name="robots", content=meta$robots),

    shiny::tags$meta(property="og:type", content="website"),
    shiny::tags$meta(property="og:title", content=meta$title),
    shiny::tags$meta(property="og:description", content=meta$description),
    shiny::tags$meta(property="og:url", content=meta$url),
    shiny::tags$meta(property="og:image", content=meta$image),

    if (!is.null(meta$site_name))
      shiny::tags$meta(property="og:site_name", content=meta$site_name),

    if (!is.null(meta$locale))
      shiny::tags$meta(property="og:locale", content=meta$locale),

    if (!is.null(meta$image_width))
      shiny::tags$meta(property="og:image:width", content=as.character(meta$image_width)),

    if (!is.null(meta$image_height))
      shiny::tags$meta(property="og:image:height", content=as.character(meta$image_height)),

    if (!is.null(meta$image_type))
      shiny::tags$meta(property="og:image:type", content=meta$image_type),

    if (!is.null(meta$image_alt))
      shiny::tags$meta(property="og:image:alt", content=meta$image_alt),

    shiny::tags$meta(name="twitter:card", content=meta$twitter_card),
    shiny::tags$meta(name="twitter:title", content=meta$title),
    shiny::tags$meta(name="twitter:description", content=meta$description),
    shiny::tags$meta(name="twitter:image", content=meta$image),
    shiny::tags$meta(name="twitter:url", content=meta$url),

    if (!is.null(meta$twitter_site))
      shiny::tags$meta(name="twitter:site", content=meta$twitter_site),

    if (!is.null(meta$twitter_creator))
      shiny::tags$meta(name="twitter:creator", content=meta$twitter_creator),

    if (!is.null(meta$twitter_image_alt))
      shiny::tags$meta(name="twitter:image:alt", content=meta$twitter_image_alt),

    if (!is.null(meta$bing_site_verification))
      shiny::tags$meta(name="msvalidate.01", content=meta$bing_site_verification),

    if (!is.null(meta$google_site_verification))
      shiny::tags$meta(name="google-site-verification", content=meta$google_site_verification),

    if (!is.null(meta$yandex_site_verification))
      shiny::tags$meta(name="yandex-verification", content=meta$yandex_site_verification),

    if (!is.null(meta$baidu_site_verification))
      shiny::tags$meta(name="baidu-site-verification", content=meta$baidu_site_verification),

    if (!is.null(meta$naver_site_verification))
      shiny::tags$meta(name="naver-site-verification", content=meta$naver_site_verification),

    if (!is.null(meta$facebook_domain_verification))
      shiny::tags$meta(name="facebook-domain-verification", content=meta$facebook_domain_verification),

    if (!is.null(meta$pinterest_domain_verification))
      shiny::tags$meta(name="p:domain_verify", content=meta$pinterest_domain_verification),

    if (!is.null(meta$custom))
      lapply(meta$custom, function(tag) do.call(shiny::tags$meta, tag)),

    if (!is.null(schema))
      shiny::tags$script(
        type = "application/ld+json",
        shiny::HTML(jsonlite::toJSON(schema, auto_unbox = TRUE))
      ),

    shiny::tags$script(shiny::HTML(
      "Shiny.addCustomMessageHandler('shinyseo_update_meta', function(fields) {
        var setMeta = function(sel, val) {
          var el = document.querySelector(sel);
          if (el) el.setAttribute('content', val);
        };
        if (fields.title) {
          document.title = fields.title;
          setMeta('meta[property=\"og:title\"]', fields.title);
          setMeta('meta[name=\"twitter:title\"]', fields.title);
        }
        if (fields.description) {
          setMeta('meta[name=\"description\"]', fields.description);
          setMeta('meta[property=\"og:description\"]', fields.description);
          setMeta('meta[name=\"twitter:description\"]', fields.description);
        }
        if (fields.url) {
          var canon = document.querySelector('link[rel=\"canonical\"]');
          if (canon) canon.setAttribute('href', fields.url);
          setMeta('meta[property=\"og:url\"]', fields.url);
          setMeta('meta[name=\"twitter:url\"]', fields.url);
        }
        if (fields.image) {
          setMeta('meta[property=\"og:image\"]', fields.image);
          setMeta('meta[name=\"twitter:image\"]', fields.image);
          // Width, height, type, and alt described the old image; drop them
          // rather than leave stale values on the new one.
          ['meta[property=\"og:image:width\"]',
           'meta[property=\"og:image:height\"]',
           'meta[property=\"og:image:type\"]',
           'meta[property=\"og:image:alt\"]',
           'meta[name=\"twitter:image:alt\"]'].forEach(function(sel) {
            var el = document.querySelector(sel);
            if (el) el.parentNode.removeChild(el);
          });
        }
      });"
    ))
  )
}

build_schema_meta <- function(meta) {
  if (isFALSE(meta$schema)) {
    return(NULL)
  }

  schema <- list(
    "@context" = "https://schema.org",
    "@type" = meta$schema_type,
    name = meta$title,
    description = meta$description,
    url = meta$url,
    inLanguage = meta$in_language
  )

  if (!is.null(meta$application_category)) {
    schema$applicationCategory <- meta$application_category
  }

  if (!is.null(meta$operating_system)) {
    schema$operatingSystem <- meta$operating_system
  }

  if (!is.null(meta$educational_use)) {
    schema$educationalUse <- meta$educational_use
  }

  if (!is.null(meta$is_accessible_for_free)) {
    schema$isAccessibleForFree <- isTRUE(meta$is_accessible_for_free)
  }

  if (!is.null(meta$disclaimer)) {
    schema$disclaimer <- meta$disclaimer
  }

  if (!is.null(meta$author_name)) {
    schema$author <- list(
      "@type" = meta$author_type,
      name = meta$author_name
    )
  }

  if (!is.null(meta$publisher_name)) {
    schema$publisher <- list(
      "@type" = meta$publisher_type,
      name = meta$publisher_name
    )
  }

  schema
}

# Local Variables:
# mode: R
# End:
