# shinyseo 1.2.0

## New features

- New `favicon_png` (and `favicon_png_sizes`) fields for `social_meta()`,
  `write_manifest()`, and `init_meta()`. Add a PNG fallback alongside an SVG
  `favicon`: Chromium-based browsers (Chrome, Edge, Comet, etc.) don't render
  SVG favicons in the address bar and fall back to a generic globe icon without
  one, even though the browser tab shows the SVG correctly.
  `favicon_png_sizes` defaults to `"32x32"`.

- Added `openai_image_generator()`, a ready-made `generator` for
  `generate_assets()` that calls OpenAI's image API (`gpt-image-1` by
  default) and returns the generated image bytes. It is shinyseo's only
  built-in generator: OpenAI's image API is a clean fit for this job (one
  endpoint, one request shape, raster bytes back), and the `httr` package
  it needs is an optional `Suggests` dependency loaded only when the
  constructor is called.

  Other LLM vendors are welcome as community-contributed generators -- see
  the new "Contributing a generator" section in `LLM.md` for the shape a
  contribution should take. Notably, Claude/Anthropic has no
  image-generation API (it can see images but not generate them), so no
  "Claude generator" is shipped or planned as a parallel to the OpenAI one.

## Bug fixes

- `init_meta()` no longer discards fields it does not ask about. Re-running
  the wizard on an existing `meta.yml` used to silently drop hand-added
  fields such as `google_site_verification`, `robots`, `image_alt`, and
  `custom`; they are now carried over untouched. Answering "no" to the PWA
  question still removes the manifest-related fields, since that is an
  explicit choice.

- `favicon_mime()` now recognises `.jpg`/`.jpeg` favicons as `image/jpeg`
  instead of falling back to `image/x-icon`.

- `update_meta()`'s client-side handler now removes `og:image:width`,
  `og:image:height`, `og:image:type`, `og:image:alt`, and
  `twitter:image:alt` when the share image is replaced at runtime, instead
  of leaving values that described the old image.

- `generate_assets()` now detects the image format of raw bytes returned by
  a generator (PNG, JPEG, GIF, WebP) from their magic numbers instead of
  assuming PNG.

- `openai_image_generator()` reports the HTTP status line when an error
  response is not JSON (e.g. HTML from a proxy), instead of failing with a
  parse error, and rejects unknown asset kinds with a clear message.

- `DESCRIPTION` no longer declares `LazyData` (the package has no data
  directory), and its `URL`/`BugReports` now point at the package's actual
  GitHub repository.

# shinyseo 1.1.0

## New feature

- Added `generate_assets()`, which fills in a missing `favicon`,
  `apple_touch_icon`, or `image` by calling a caller-supplied `generator`
  function. shinyseo does not integrate with any particular LLM or
  image-generation service itself -- `generator` is the caller's own
  function, written against whatever API they already have access to (OpenAI,
  Adobe Firefly, a local model, and so on). This keeps the package free of
  any vendor dependency, API key, or running cost of its own.

# shinyseo 1.0.2

## Bug fix

- `read_meta()` (used internally by `social_meta()`, `write_manifest()`, and
  `init_meta()`) now decodes the YAML file as raw UTF-8 bytes instead of
  going through `yaml::read_yaml()`'s `readLines()`-based reader. Under a
  non-UTF-8 locale (`LC_CTYPE=C`, common on minimal servers/CI runners),
  the old reader silently stopped at the first non-ASCII character (e.g.
  Norwegian "æøå"), dropping every field after it with no warning or error.

# shinyseo 1.0.1

## Improvements

- `init_meta()` now reads an existing meta file (if any) and shows its current
  values as defaults for each prompt, so pressing Enter keeps what's already
  there instead of clearing it.

# shinyseo 1.0.0

First stable release. The API (`social_meta()`, `update_meta()`,
`write_manifest()`, `init_meta()`, and the `meta` field names) is now
considered stable.

# shinyseo 0.2.0

## New features

- `init_meta(path)` — interactively answer a few questions at the console and
  write the result to a `meta.yml` file, so new users can get started without
  reading the field reference first.

- `update_meta(session, title, description, url, image)` — update metadata
  reactively from the server without a page reload.  Useful for multi-tab and
  multi-route apps.  `social_meta()` now injects the JavaScript handler
  automatically; no extra setup required.

- `write_manifest(meta, path, display, start_url, background_color)` — generate
  a `www/manifest.json` web app manifest from the same metadata object used by
  `social_meta()`.  Call once in `global.R`.

- Favicon and PWA fields in `social_meta()`:
  - `favicon` + `favicon_type` → `<link rel="icon">` with automatic MIME type
    detection from file extension
  - `apple_touch_icon` → `<link rel="apple-touch-icon">`
  - `manifest` → `<link rel="manifest">`
  - `theme_color` → `<meta name="theme-color">`
  - `short_name` → used by `write_manifest()` for the manifest `short_name`
  - `apple_mobile_web_app_capable` → `<meta name="apple-mobile-web-app-capable">`
    and `<meta name="mobile-web-app-capable">`, so the app runs standalone when
    added to a phone's home screen
  - `apple_mobile_web_app_title` → `<meta name="apple-mobile-web-app-title">`
  - `apple_mobile_web_app_status_bar_style` →
    `<meta name="apple-mobile-web-app-status-bar-style">`

- Custom meta tags via the `custom` field — a list of lists where each inner
  list's keys map directly to HTML attributes on a `<meta>` tag.  Supports both
  `name=` and `property=` style tags.

# shinyseo 0.1.1

## Documentation

- Rewrote all documentation from Norwegian to English.

# shinyseo 0.1.0

## First CRAN release

- Released on CRAN as `shinyseo`.
- Reached 158 downloads early on.
- Was ranked 32nd among the newest CRAN packages in the public tracking list.

