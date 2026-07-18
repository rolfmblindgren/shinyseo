# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`shinyseo` is a small CRAN R package that injects SEO, Open Graph, Twitter
Card, favicon/PWA, schema.org, and site-verification metadata into Shiny
apps. It is not an app itself — it's a library consumed by Shiny apps via
`social_meta()`, `update_meta()`, `write_manifest()`, and `init_meta()`.

`LLM.md` is the authoritative usage reference for the package's public API
(read it before `README.md` if you need to understand how `social_meta()`,
`update_meta()`, `write_manifest()`, or `init_meta()` are meant to be used —
it documents the full YAML field reference that backs `apply_defaults()` and
`build_schema_meta()`).

## Common commands

Run these from an R console with the working directory set to the package
root (or via `Rscript -e '...'`):

- Run all tests: `devtools::test()` or `testthat::test_dir("tests/testthat")`
- Run a single test file: `testthat::test_file("tests/testthat/test-social_meta.R")`
- Load the package for interactive development: `devtools::load_all()`
- Full package check (mirrors CRAN check): `devtools::check()` or
  `R CMD build . && R CMD check --as-cran shinyseo_*.tar.gz`
- Regenerate `NAMESPACE` and `man/*.Rd` from roxygen comments after editing
  exported function docs: `devtools::document()` (uses roxygen2 8.0.0, see
  `Config/roxygen2/version` in `DESCRIPTION`)
- Build vignettes: `devtools::build_vignettes()`

There is no separate lint/format command; follow the existing style (see
below) when editing.

## Release process

- `.github/workflows/R-CMD-check.yaml` runs the CRAN-style check weekly
  (Sunday 06:00 UTC cron) on ubuntu + macOS, not on every push/PR.
- `.github/workflows/release.yaml` fires on `v*` tag pushes: it re-runs the
  check, builds the tarball on macOS, and uploads it to a GitHub Release.
  Cutting a release means bumping `Version` in `DESCRIPTION`, updating
  `NEWS.md`, and pushing a matching `vX.Y.Z` tag.
- `cran-comments.md` is the CRAN-submission cover note (check results,
  summary of changes since the last CRAN version, notes on any
  network/API-touching code). Refresh it before every CRAN submission —
  see recent commit history for the expected tone and level of detail.

## Architecture

The package has a small, linear pipeline. Most exported entry points
(`social_meta()`, `write_manifest()`, `init_meta()`, `generate_assets()`)
funnel metadata through the same two internal helpers before doing their own
thing:

1. **`read_meta()`** (`R/read_meta.R`) — loads metadata from a YAML path. It
   deliberately does *not* use `yaml::read_yaml()` directly: that function
   reads via `readLines()`, whose multibyte handling depends on the active
   locale, and silently truncates files containing non-ASCII characters
   (e.g. Norwegian "æøå") under `LC_CTYPE=C`. Instead it reads raw bytes and
   decodes explicitly as UTF-8. **Keep this raw-byte approach when touching
   YAML loading** — reverting to `yaml::read_yaml()` reintroduces a
   silent-data-loss bug that has already shipped once (see `NEWS.md` 1.0.2).

2. **`apply_defaults()`** (`R/defaults.R`) — fills in package defaults
   (locale, robots, twitter card type, schema type, etc.) using the `%||%`
   null-coalescing operator (`R/utils.R`), and pulls
   `SHINYSEO_BING_SITE_VERIFICATION`, `SHINYSEO_TWITTER_SITE`, and
   `SHINYSEO_TWITTER_CREATOR` from the environment as fallbacks via
   `env_or_null()`. Per-app YAML values always win over environment
   defaults.

From there:

- **`social_meta()`** (`R/social_meta.R`) validates required fields
  (`title`, `description`, `url`, `image`), builds the `<head>` fragment of
  `shiny::tags`, optionally appends a JSON-LD schema.org block via the
  internal `build_schema_meta()`, and registers a JS
  `Shiny.addCustomMessageHandler('shinyseo_update_meta', ...)` that
  `update_meta()` talks to at runtime. UI-side only.
- **`update_meta()`** (`R/update_meta.R`) is the server-side counterpart: it
  sends a `session$sendCustomMessage("shinyseo_update_meta", fields)` that
  the JS handler registered by `social_meta()` consumes to patch
  `document.title`, canonical link, and OG/Twitter meta tags in place
  without a page reload. The JS message-name string and the field names in
  the `fields` list (`title`, `description`, `url`, `image`) are the
  contract between these two functions — change them together.
- **`write_manifest()`** (`R/write_manifest.R`) generates `www/manifest.json`
  for PWA support; meant to be called once from `global.R`.
- **`init_meta()`** (`R/init_meta.R`) is an interactive console wizard that
  writes `meta.yml`; it requires an interactive session (`is_interactive()`)
  and pre-fills prompts from an existing file's values via `read_meta()` so
  pressing Enter keeps the current value.
- **`generate_assets()`** (`R/generate_assets.R`) fills in a missing
  `favicon`, `apple_touch_icon`, or `image` by calling a **caller-supplied**
  `generator(prompt, kind)` function — the function itself is
  vendor-neutral (no hard dependency, API key, or vendor lock-in; see
  `LLM.md` for the rationale). It only builds prompts, dispatches to
  `generator`, and writes the returned bytes/file to `path` (default
  `"www"`) under a fixed filename per `kind`
  (`favicon`/`apple-touch-icon`/`share-image`). Run it once at setup time,
  not from `ui`/`server`, and persist the returned `meta` yourself (e.g.
  `yaml::write_yaml()`).
- **`openai_image_generator()`** (`R/openai_image_generator.R`) is the one
  built-in generator: a constructor returning a `function(prompt, kind)`
  that POSTs to OpenAI's image API and returns raw image bytes. It is
  deliberately the *only* bundled generator — `httr` stays in `Suggests`
  and is loaded via `requireNamespace()` only when the constructor is
  called, so keep it optional; don't promote `httr` to `Imports`. Other
  vendors belong as community contributions per the "Contributing a
  generator" section of `LLM.md`. Anthropic/Claude has no image-generation
  API, so a "Claude generator" is neither shipped nor planned — don't add
  one.

`R/utils.R` holds small shared helpers (`%||%`, `is_interactive()`,
`ask_console()`, `favicon_mime()`).

## Tests

Tests use `testthat` edition 3 (`Config/testthat/edition: 3` in
`DESCRIPTION`) and `htmltools::renderTags()` to render the `shiny::tags$head()`
fragment to HTML and assert on substrings (see `test-social_meta.R` for the
pattern). Test files map roughly 1:1 to feature areas rather than to source
files (`test-custom_meta.R`, `test-favicon.R`, `test-generate_assets.R`,
`test-init_meta.R`, `test-openai_image_generator.R`, `test-social_meta.R`,
`test-update_meta.R`). Tests touching optional dependencies guard with
`skip_if_not_installed("httr")` and never hit the network — they test the
constructor and argument validation only.

## Style

- Two-space indentation, opening brace on the same line (K&R-ish), matching
  the rest of the codebase.
- R source files end with an Emacs local-variables block:
  ```r
  # Local Variables:
  # mode: R
  # End:
  ```
  Add this to new `.R` files for consistency.
- Exported functions are documented with roxygen2 comments; run
  `devtools::document()` after changing them so `NAMESPACE` and `man/*.Rd`
  stay in sync — don't hand-edit those generated files.
