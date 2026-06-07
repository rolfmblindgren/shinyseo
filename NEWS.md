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

