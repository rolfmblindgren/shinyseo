# shinyseo

[![CRAN version](https://www.r-pkg.org/badges/version/shinyseo)](https://CRAN.R-project.org/package=shinyseo)
[![CRAN total downloads](https://cranlogs.r-pkg.org/badges/grand-total/shinyseo?color=blue)](https://CRAN.R-project.org/package=shinyseo)

`shinyseo` is a small helper package for Shiny apps that need social, search, and PWA metadata.

It builds one `shiny::tags$head()` fragment containing:

- canonical URL and description
- Open Graph tags for Facebook, LinkedIn, Slack, and similar previews
- Twitter Card tags
- favicon, apple-touch-icon, theme-color, and web app manifest links
- optional schema.org JSON-LD
- optional Bing, Google, Yandex, Baidu, Naver, Facebook, and Pinterest verification
- arbitrary custom meta tags

The package accepts either a YAML file path or a named list.

Six exported functions:

- `init_meta(path)` — interactively answer a few questions at the console and
  write the result to a YAML file, so you can get started without reading the
  field reference below
- `social_meta(meta)` — inject metadata into the UI at startup
- `update_meta(session, ...)` — update title, description, url, or image reactively from the server
- `write_manifest(meta, ...)` — generate `www/manifest.json` for PWA support
- `generate_assets(meta, generator, ...)` — fill in a missing favicon, Apple
  touch icon, or share image by calling your own LLM/image-generation
  function, or one of the built-in generators below
- `openai_image_generator(api_key, model)` — a ready-made `generator` for
  `generate_assets()` that calls OpenAI's image API

## Getting started

Run `shinyseo::init_meta()` in the console. It will ask for your title,
description, URL, image, and a handful of optional fields (favicon, theme
colour, home screen shortcut support, and so on), then write the answers to
`meta.yml`. Pass that file straight to `social_meta()`:

```r
shinyseo::social_meta("meta.yml")
```

## What it does

When you call `social_meta()`, the package:

1. Reads metadata from YAML or uses the list you pass in.
2. Fills in safe defaults for common fields like locale, robots, and Twitter card type.
3. Checks that the required fields exist.
4. Builds HTML tags for Shiny UI.
5. Adds JSON-LD unless you turn schema off.
6. Registers a JavaScript handler so `update_meta()` can update tags at runtime.

## API in short

`social_meta(meta)`:

- `meta` may be a YAML path or a named list
- `title`, `description`, `url`, and `image` are required
- if `meta` is a character string, it is read as a UTF-8 YAML file path
- missing keys use package defaults where provided
- `schema = FALSE` disables JSON-LD output
- any other value of `schema` keeps JSON-LD enabled

`update_meta(session, title, description, url, image)`:

- call from the server to update metadata without a page reload
- only the fields you supply are changed
- requires `social_meta()` to be present in the UI

`write_manifest(meta, path, display, start_url, background_color)`:

- generates `www/manifest.json` for PWA support
- call once in `global.R` before the app starts
- reference the result with `manifest = "/manifest.json"` in `social_meta()`

`generate_assets(meta, generator, path, assets)`:

- fills in a missing `favicon`, `apple_touch_icon`, or `image` by calling
  a `generator` function — either one you write yourself, or a built-in
  one such as `openai_image_generator()`
- `generator` is `function(prompt, kind)`; it talks to whatever LLM/image
  API it's written against, and returns either raw image bytes or a path
  to a file on disk
- only missing fields are generated; existing values are left untouched
- run it once at setup time (e.g. from the console), then persist the
  updated `meta` with `yaml::write_yaml()`

```r
meta <- shinyseo::generate_assets(meta,
  generator = shinyseo::openai_image_generator()
)
yaml::write_yaml(meta, "meta.yml")
```

Or supply your own, against whatever service you already have access to:

```r
meta <- shinyseo::generate_assets(meta, generator = function(prompt, kind) {
  # your own call to Adobe Firefly, a local model, ...
})
yaml::write_yaml(meta, "meta.yml")
```

`openai_image_generator(api_key, model)`:

- builds a ready-made `generator` for `generate_assets()` that calls
  OpenAI's image API (`gpt-image-1` by default) and returns the generated
  image bytes
- `api_key` defaults to the `OPENAI_API_KEY` environment variable
- requires the `httr` package, but only loads it (via `requireNamespace()`)
  when you call this constructor — it costs nothing if you never use it
- shinyseo ships only this one built-in generator. OpenAI's image API is a
  straightforward fit for the job; most other LLM vendors either don't
  generate images at all (e.g. Claude/Anthropic, which can *see* images but
  not generate them) or need enough vendor-specific glue that they're
  better suited to a community-contributed `generator` — see
  [LLM.md](https://github.com/rolfmblindgren/shinyseo/blob/main/LLM.md#contributing-a-generator)
  for the shape a contribution should take

```r
meta <- shinyseo::generate_assets(meta,
  generator = shinyseo::openai_image_generator(api_key = "sk-...")
)
```

## Config cheat sheet

Minimal configuration:

```yaml
title: "Example app"
description: "A short app description."
url: "https://example.no"
image: "https://example.no/share.png"
```

Common extras:

| Field | What it does |
| --- | --- |
| `locale` | Sets Open Graph locale and schema language default |
| `robots` | Controls the robots meta tag |
| `twitter_card` | Sets the Twitter card type |
| `site_name` | Sets `og:site_name` |
| `twitter_site` | Sets `twitter:site` |
| `twitter_creator` | Sets `twitter:creator` |
| `image_alt` | Sets `og:image:alt` |
| `twitter_image_alt` | Sets `twitter:image:alt` |
| `favicon` | Sets `<link rel="icon">` with auto-detected MIME type |
| `favicon_type` | Overrides the MIME type inferred from `favicon` |
| `favicon_png` | Adds a PNG `<link rel="icon">` fallback — set this when `favicon` is an SVG; Chromium address bars don't render SVG favicons and show a generic globe icon without a PNG fallback |
| `favicon_png_sizes` | Overrides the `sizes` attribute on `favicon_png` (defaults to `"32x32"`) |
| `apple_touch_icon` | Sets `<link rel="apple-touch-icon">` |
| `theme_color` | Sets `<meta name="theme-color">` |
| `manifest` | Sets `<link rel="manifest">` |
| `short_name` | Used by `write_manifest()` for the manifest short name |
| `apple_mobile_web_app_capable` | Set to `TRUE` to run standalone when added to a phone's home screen (`apple-mobile-web-app-capable` and `mobile-web-app-capable`) |
| `apple_mobile_web_app_title` | Sets the name shown under the home screen icon (`apple-mobile-web-app-title`) |
| `apple_mobile_web_app_status_bar_style` | Sets the iOS status bar style (`apple-mobile-web-app-status-bar-style`) |
| `custom` | List of lists — each becomes an arbitrary `<meta>` tag |
| `bing_site_verification` | Sets Bing verification |
| `google_site_verification` | Sets Google Search Console verification |
| `yandex_site_verification` | Sets Yandex Webmaster verification |
| `baidu_site_verification` | Sets Baidu Webmaster verification |
| `naver_site_verification` | Sets Naver Webmaster verification |
| `facebook_domain_verification` | Sets Facebook domain verification |
| `pinterest_domain_verification` | Sets Pinterest domain verification |
| `schema` | Set to `FALSE` to disable JSON-LD |

If you want shared defaults across several apps, you can set these in
`.Renviron` and let app-level YAML override them when needed:

- `SHINYSEO_BING_SITE_VERIFICATION`
- `SHINYSEO_TWITTER_SITE`
- `SHINYSEO_TWITTER_CREATOR`

## What belongs where

Use `.Renviron` for values that are shared across many apps on the same
machine or deployment:

- `SHINYSEO_BING_SITE_VERIFICATION`
- `SHINYSEO_TWITTER_SITE`
- `SHINYSEO_TWITTER_CREATOR`

Keep per-app values in each app's `meta.yml`:

- `title`
- `description`
- `url`
- `image`
- `locale` if one app differs from the shared default
- `site_name` if one app needs a different display name
- `twitter_site` or `twitter_creator` if one app should override the shared default
- `bing_site_verification` if one app needs a different Bing token

`SHINYSEO_GOOGLE_ANALYTICS_MEASUREMENT_ID` is not used by `shinyseo` itself.
If you use GA4, keep that in your server or deployment config instead of in
`meta.yml`.

## Quick use

```r
# global.R — generate manifest once at startup
shinyseo::write_manifest("meta.yml")

# ui.R
ui <- fluidPage(
  shinyseo::social_meta("meta.yml"),
  h1("My app")
)

# server.R — update metadata when the user navigates
server <- function(input, output, session) {
  observeEvent(input$tabs, {
    shinyseo::update_meta(session, title = paste(input$tabs, "– My App"))
  })
}
```

You can also pass a list directly instead of a YAML file:

```r
shinyseo::social_meta(list(
  title       = "Example app",
  description = "A short app description.",
  url         = "https://example.no",
  image       = "https://example.no/share.png",
  favicon     = "/favicon.png",
  theme_color = "#1a73e8"
))
```

## Vignettes

The long-form package docs live in vignettes:

- [API contract](vignettes/API.Rmd)
- [Reference guide](vignettes/REFERENCE.Rmd)

If the package is installed, you can also open them with `browseVignettes("shinyseo")`.

For LLM use, see [LLM.md](https://github.com/rolfmblindgren/shinyseo/blob/main/LLM.md).
