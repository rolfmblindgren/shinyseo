## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a resubmission. The previous submission of 1.2.0 was flagged for
  invalid file URIs: README.md linked to `LLM.md` with a relative path, but
  `LLM.md` is excluded from the built package via `.Rbuildignore`. Both
  links now point to the file's GitHub URL instead.
* Checked with `R CMD check --as-cran` under R 4.6.1 on Fedora Linux
  (x86_64), including the PDF manual and both vignettes.
* This is an update from 0.1.1 to 1.2.0; see `NEWS.md` for the changes
  (new `init_meta()`, `update_meta()`, `generate_assets()`, and
  `openai_image_generator()` functions, plus bug fixes).
* The new `openai_image_generator()` only constructs a function; no
  network access occurs in examples, tests, or vignettes. Its `httr`
  dependency is in Suggests and loaded via `requireNamespace()`.
