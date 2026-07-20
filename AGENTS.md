# Repository Guidelines

## Project Structure & Module Organization

`shinyseo` is an R package for adding SEO, social metadata, favicon/PWA, schema.org, and verification tags to Shiny apps. Package code lives in `R/`, with exported functions such as `social_meta()`, `update_meta()`, `write_manifest()`, `init_meta()`, `generate_assets()`, and `openai_image_generator()`. Tests are under `tests/testthat/`, with `tests/testthat.R` as the test entrypoint. Generated documentation lives in `man/`, long-form references in `vignettes/`, and release notes in `NEWS.md`. `LLM.md` is the detailed public API reference; `CLAUDE.md` contains deeper maintainer notes.

## Build, Test, and Development Commands

Run commands from the package root, either in R or through `Rscript -e`.

- `devtools::load_all()` loads the package for interactive development.
- `devtools::test()` runs the full test suite.
- `testthat::test_file("tests/testthat/test-social_meta.R")` runs one focused test file.
- `devtools::document()` regenerates `NAMESPACE` and `man/*.Rd` after roxygen changes.
- `devtools::check()` runs a CRAN-style package check.
- `devtools::build_vignettes()` rebuilds the vignette outputs.

## Coding Style & Naming Conventions

Follow the existing R style: two-space indentation, opening braces on the same line, descriptive snake_case function and file names, and small helper functions kept in `R/utils.R` when shared. Exported functions need roxygen2 documentation; do not hand-edit generated `NAMESPACE` or `man/*.Rd` files except as part of generated documentation output. New `.R` files should include the repository's Emacs local-variables footer.

## Testing Guidelines

Tests use `testthat` edition 3. Keep tests in `tests/testthat/` and name files by feature, for example `test-favicon.R` or `test-generate_assets.R`. Prefer focused assertions on rendered `shiny::tags` output via `htmltools::renderTags()` when testing UI metadata. Tests for optional dependencies should use `skip_if_not_installed()` and must not make network calls.

## Commit & Pull Request Guidelines

Recent history uses short Conventional Commit-style subjects such as `fix: ...`, `docs: ...`, `feat: ...`, and `chore: ...`; match that format. Pull requests should describe the behavior change, list test commands run, link related issues when applicable, and include rendered output or screenshots only when UI-facing metadata output is easier to review visually.

## Security & Configuration Tips

Keep API keys out of source files. `openai_image_generator()` should read `OPENAI_API_KEY` from the environment unless a caller explicitly passes a key. Preserve optional dependency behavior: `httr` belongs in `Suggests` and should be loaded only with `requireNamespace()`.
