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

### `generate_assets(meta, generator, path, assets)`

Fills in a missing `favicon`, `apple_touch_icon`, or `image` by calling a
`generator` function — either the built-in `openai_image_generator()`, or
one you write yourself against whatever LLM/image API you have access to.
shinyseo itself makes no network calls and has no vendor dependency; all of
that lives behind the `generator` you choose to pass in.  Use this once at
setup time (e.g. from the console or a setup script), not from `ui`/`server`.

```r
meta <- shinyseo::read_meta("meta.yaml")  # or build the list directly

meta <- shinyseo::generate_assets(meta,
  generator = shinyseo::openai_image_generator()
)

yaml::write_yaml(meta, "meta.yaml")
```

Or write your own generator against another service:

```r
meta <- shinyseo::generate_assets(meta, generator = function(prompt, kind) {
  # Your own code against whatever LLM/image API you have access to.
  # `kind` is "favicon", "apple_touch_icon", or "image" — branch on it
  # to vary size, aspect ratio, or style.
  # Return either a raw vector of image bytes or a path to a file on disk.
})
```

Parameters:
- `meta` — same YAML path or list as `social_meta()`
- `generator` — a function `function(prompt, kind)` that talks to an
  LLM/image-generation API and returns either a raw vector of image bytes
  or a single file path. `openai_image_generator()` builds one of these for
  you; see below.
- `path` — directory to write generated files into, default `"www"`
- `assets` — which fields to fill in if missing; defaults to all three:
  `c("favicon", "apple_touch_icon", "image")`

Behaviour:
- Only fields that are *missing* from `meta` are generated — existing values
  are left untouched and the generator is not called for them.
- Generated files are written as `favicon.<ext>`, `apple-touch-icon.<ext>`,
  or `share-image.<ext>` under `path`, and `meta` is updated with `"/"`-
  prefixed paths to them (e.g. `"/favicon.png"`).
- If the generator returns a raw vector, the file is written as `.png`. If
  it returns a file path, the original extension is kept.
- The function does not persist `meta` — write it back yourself (e.g. with
  `yaml::write_yaml()`) if you want the generated paths to stick.

---

### `openai_image_generator(api_key, model)`

Builds a ready-made `generator` for `generate_assets()` that calls OpenAI's
image API (`https://api.openai.com/v1/images/generations`, model
`"gpt-image-1"` by default) and returns the generated image as raw bytes.

```r
generator <- shinyseo::openai_image_generator()       # uses OPENAI_API_KEY
generator <- shinyseo::openai_image_generator(api_key = "sk-...")
```

Parameters:
- `api_key` — OpenAI API key; defaults to the `OPENAI_API_KEY` environment
  variable
- `model` — OpenAI image model to call; defaults to `"gpt-image-1"`

Notes:
- Requires the `httr` package (in `Suggests`). It is loaded with
  `requireNamespace()` only when you call this constructor, so it costs
  nothing if you never use OpenAI generation.
- Calling the constructor makes no network request by itself — it just
  builds and returns the `function(prompt, kind)` that `generate_assets()`
  will call.
- This is the *only* generator shinyseo ships built-in. See "Contributing a
  generator" below for why, and for how to add support for another provider.

---

## Contributing a generator

shinyseo ships exactly one built-in generator, `openai_image_generator()`,
because OpenAI's image API is a clean fit for this job: one endpoint, one
request shape, raster image bytes back.

Not every popular LLM vendor fits that shape. Notably, **Claude/Anthropic
has no image-generation API** — Claude can *see* images (vision input) and
can *write code* that draws simple graphics (e.g. SVG or matplotlib via the
code-execution tool), but it cannot generate raster images the way OpenAI's
`gpt-image-1`/DALL-E or Adobe Firefly can. A "Claude generator" parallel to
`openai_image_generator()` isn't possible as a thin wrapper around an
image-generation endpoint, because no such endpoint exists. shinyseo
therefore does not ship one; if you want Claude involved at all, the
realistic options are using it to draft prompts or write SVG markup that
some other renderer turns into a raster image — both of which are better
suited to a caller-supplied `generator` than to a one-size-fits-all built-in.

If you'd like to add a built-in generator for another provider that *does*
generate images, contributions are welcome on
<https://github.com/rolfmblindgren/grendelMeta>. To keep things tidy:

- Name it `<provider>_image_generator(...)`, e.g. `firefly_image_generator()`.
- Put it in its own file, `R/<provider>_image_generator.R`.
- Match the existing shape: the constructor takes provider-specific
  arguments (at minimum an `api_key`, defaulting to a sensible environment
  variable) and returns a `function(prompt, kind)` that returns raw image
  bytes or a file path — the same contract `generate_assets()` already
  expects from any `generator`.
- Gate any new HTTP/JSON dependency behind `requireNamespace()` and add it
  to `Suggests`, not `Imports` — shinyseo's core functionality must keep
  working with no vendor packages installed.
- Document it in `LLM.md` and `README.md` next to `openai_image_generator()`,
  following the same structure.

This keeps every built-in generator held to the same bar — a real
image-generation API behind it, an optional dependency, and a consistent
shape — rather than growing a long tail of half-working vendor wrappers.

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
| `favicon_png`      | **PNG fallback** `<link rel="icon" type="image/png" sizes="...">`; set this when `favicon` is an SVG — Chromium browsers don't render SVG favicons in the address bar and show a generic globe icon without a PNG fallback; also included in manifest icons |
| `favicon_png_sizes`| overrides the `sizes` attribute on `favicon_png` (defaults to `"32x32"`) |
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
favicon: /favicon.svg
favicon_png: /favicon-32.png
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
- Do not call `generate_assets()` from `ui`/`server` — it makes (potentially
  slow, costly) calls to whatever service the caller's `generator` talks to,
  and writes files to disk.  Run it once at setup time and persist the
  result.
- Do not expect `generate_assets()` to call any LLM or image API on its
  own — `generate_assets()` itself has no vendor integration.  Pass it
  either the built-in `openai_image_generator()` or your own `generator`
  function written against whatever service you have access to (Adobe
  Firefly, a local model, and so on).
- Do not assume a "Claude generator" exists or could be added as a thin
  wrapper like `openai_image_generator()` — Claude/Anthropic has no
  image-generation API.  See "Contributing a generator" above.
