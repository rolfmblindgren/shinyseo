# shinyseo — instructions for LLM use

This file is the authoritative reference for using shinyseo in a Shiny app.
Read this before reading any other file in the package.

## What the package does

shinyseo injects SEO, social sharing, favicon, and PWA metadata into a Shiny
app's `<head>` element.  It also provides a function to update metadata
reactively at runtime and a function to generate a web app manifest file.

## Exported functions

### `social_meta(meta)`

Call this in the **UI**, not the server.  Returns a `shiny::tags$head()`
fragment.  Place it as the first child of any top-level UI container.

```r
ui <- fluidPage(
  shinyseo::social_meta("meta.yaml"),
  ...
)
```

`meta` is either:
- a string path to a YAML file, or
- a named list

Required fields (the function stops with an error if any are missing):
- `title`
- `description`
- `url`
- `image`

---

### `update_meta(session, title, description, url, image)`

Call this in the **server** to update metadata without a page reload.
`social_meta()` must be present in the UI — it registers the JavaScript
handler that `update_meta()` depends on.

All arguments except `session` are optional.  Only supplied fields change;
omitted fields keep their current values.  Passing no fields is a no-op.

```r
server <- function(input, output, session) {
  observeEvent(input$tabs, {
    shinyseo::update_meta(session,
      title       = paste(input$tabs, "– My App"),
      description = tab_descriptions[[input$tabs]]
    )
  })
}
```

Fields updated by each argument:

| argument      | tags updated |
|---------------|-------------|
| `title`       | `document.title`, `og:title`, `twitter:title` |
| `description` | `meta[name=description]`, `og:description`, `twitter:description` |
| `url`         | `link[rel=canonical]`, `og:url`, `twitter:url` |
| `image`       | `og:image`, `twitter:image` |

---

### `write_manifest(meta, path, display, start_url, background_color)`

Call this in **`global.R`** before the app starts.  Writes `manifest.json`
to the `www/` directory so Shiny can serve it at `/manifest.json`.

```r
# global.R
shinyseo::write_manifest("meta.yaml")
```

Then reference the manifest from the UI:

```r
shinyseo::social_meta(list(
  ...,
  manifest = "/manifest.json"
))
```

Parameters:
- `meta` — same YAML path or list as `social_meta()`
- `path` — output directory, default `"www"`
- `display` — PWA display mode: `"standalone"` (default), `"fullscreen"`, `"minimal-ui"`, `"browser"`
- `start_url` — default `"/"`
- `background_color` — splash screen colour; defaults to `theme_color` if set, else `"#ffffff"`

---

## Complete field reference

### Required

| field         | used for |
|---------------|----------|
| `title`       | OG title, Twitter title, schema name, manifest name |
| `description` | meta description, OG description, Twitter description, schema description, manifest description |
| `url`         | canonical URL, OG URL, Twitter URL, schema URL |
| `image`       | OG image, Twitter image |

### Social and Open Graph

| field          | used for |
|----------------|----------|
| `site_name`    | `og:site_name` |
| `locale`       | `og:locale`; default `"en_US"` |
| `image_alt`    | `og:image:alt`, `twitter:image:alt` |
| `image_width`  | `og:image:width` |
| `image_height` | `og:image:height` |
| `image_type`   | `og:image:type` (MIME type) |

### Twitter / X

| field              | used for |
|--------------------|----------|
| `twitter_card`     | `twitter:card`; default `"summary_large_image"` |
| `twitter_site`     | `twitter:site`; falls back to `SHINYSEO_TWITTER_SITE` env var |
| `twitter_creator`  | `twitter:creator`; falls back to `SHINYSEO_TWITTER_CREATOR` env var |
| `twitter_image_alt`| `twitter:image:alt` |

### Favicon and PWA

| field              | used for |
|--------------------|----------|
| `favicon`          | `<link rel="icon">` with auto-detected MIME type |
| `favicon_type`     | overrides the MIME type inferred from `favicon`'s extension |
| `apple_touch_icon` | `<link rel="apple-touch-icon">`; also included in manifest icons |
| `manifest`         | `<link rel="manifest">`; typically `"/manifest.json"` |
| `theme_color`      | `<meta name="theme-color">`; also used in manifest |
| `short_name`       | manifest `short_name`; defaults to `title` |

Favicon MIME types inferred from extension: `.ico` → `image/x-icon`,
`.png` → `image/png`, `.svg` → `image/svg+xml`, `.webp` → `image/webp`,
`.gif` → `image/gif`.  Anything else defaults to `image/x-icon`.

Place image files in the `www/` directory of the app so Shiny serves them.

### Custom meta tags

| field    | used for |
|----------|----------|
| `custom` | list of lists — each inner list becomes one `<meta>` tag with its keys as HTML attributes |

Each entry in `custom` is a named list whose keys map directly to HTML attributes.
Use `name` for standard meta tags, `property` for Open Graph-style tags, or any
other valid attribute.

```r
custom = list(
  list(name     = "viewport",   content = "width=device-width, initial-scale=1"),
  list(name     = "x-app-env",  content = "production"),
  list(property = "og:video",   content = "https://example.com/video.mp4")
)
```

### Robots

| field    | used for |
|----------|----------|
| `robots` | `<meta name="robots">`; default `"index,follow,max-image-preview:large,max-snippet:-1,max-video-preview:-1"` |

### Webmaster verification

| field                        | tag produced |
|------------------------------|-------------|
| `bing_site_verification`     | `msvalidate.01`; falls back to `SHINYSEO_BING_SITE_VERIFICATION` env var |
| `google_site_verification`   | `google-site-verification` |
| `yandex_site_verification`   | `yandex-verification` |
| `baidu_site_verification`    | `baidu-site-verification` |
| `naver_site_verification`    | `naver-site-verification` |
| `facebook_domain_verification` | `facebook-domain-verification` |
| `pinterest_domain_verification`| `p:domain_verify` |

### Schema.org JSON-LD

JSON-LD is emitted by default.  Set `schema = FALSE` to suppress it.

| field                   | schema.org field |
|-------------------------|-----------------|
| `schema`                | `FALSE` disables JSON-LD entirely |
| `schema_type`           | `@type`; default `"WebApplication"` |
| `in_language`           | `inLanguage`; defaults to `locale` |
| `application_category`  | `applicationCategory` |
| `operating_system`      | `operatingSystem`; default `"Any"` |
| `educational_use`       | `educationalUse` |
| `is_accessible_for_free`| `isAccessibleForFree` (boolean) |
| `disclaimer`            | `disclaimer` |
| `author_name`           | `author.name` |
| `author_type`           | `author.@type`; default `"Person"` |
| `publisher_name`        | `publisher.name` |
| `publisher_type`        | `publisher.@type`; default `"Organization"` |

---

## Typical patterns

### Minimal app

```r
# ui.R
ui <- fluidPage(
  shinyseo::social_meta(list(
    title       = "My App",
    description = "A short description.",
    url         = "https://example.com",
    image       = "https://example.com/share.png"
  ))
)
```

### YAML-based configuration

```yaml
# meta.yaml
title: My App
description: A short description.
url: https://example.com
image: https://example.com/share.png
twitter_site: "@myhandle"
theme_color: "#1a73e8"
favicon: /favicon.png
apple_touch_icon: /apple-touch-icon.png
manifest: /manifest.json
```

```r
# global.R
shinyseo::write_manifest("meta.yaml")

# ui.R
shinyseo::social_meta("meta.yaml")
```

### Multi-tab app with reactive metadata

```r
# global.R
shinyseo::write_manifest("meta.yaml")

# ui.R
ui <- navbarPage("My App",
  shinyseo::social_meta("meta.yaml"),
  tabPanel("Home"),
  tabPanel("About")
)

# server.R
server <- function(input, output, session) {
  observeEvent(input$tabs, {
    if (input$tabs == "About") {
      shinyseo::update_meta(session,
        title       = "About – My App",
        description = "Learn more about the team."
      )
    } else {
      shinyseo::update_meta(session,
        title       = "My App",
        description = "A short description."
      )
    }
  })
}
```

---

## What NOT to do

- Do not call `update_meta()` without `social_meta()` in the UI — the
  JavaScript handler will not exist and the call silently does nothing.
- Do not call `write_manifest()` inside `server` or `ui` — it writes a file
  and belongs in `global.R` or a startup script.
- Do not pass `manifest = "/manifest.json"` without calling `write_manifest()`
  first — the browser will get a 404 for the manifest.
- Do not use `social_meta()` more than once in the same UI — duplicate meta
  tags will confuse crawlers.
- The package does not emit a `<title>` tag.  Set the page title via the
  Shiny UI (e.g. the `title` argument of `navbarPage()` or `fluidPage()`).
