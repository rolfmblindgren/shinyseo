base_meta <- list(
  title       = "Test App",
  description = "A test.",
  url         = "https://example.no",
  image       = "https://example.no/share.png"
)

test_that("generate_assets fills in missing fields and writes files", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  calls <- list()
  generator <- function(prompt, kind) {
    calls[[length(calls) + 1]] <<- list(prompt = prompt, kind = kind)
    as.raw(c(0x89, 0x50, 0x4e, 0x47))
  }

  meta <- generate_assets(base_meta, generator, path = tmp)

  expect_setequal(vapply(calls, `[[`, character(1), "kind"),
                  c("favicon", "apple_touch_icon"))
  expect_true(any(grepl("Test App", vapply(calls, `[[`, character(1), "prompt"), fixed = TRUE)))

  expect_equal(meta$favicon, "/favicon.png")
  expect_equal(meta$apple_touch_icon, "/apple-touch-icon.png")
  expect_equal(meta$image, "https://example.no/share.png")

  expect_true(file.exists(file.path(tmp, "favicon.png")))
  expect_true(file.exists(file.path(tmp, "apple-touch-icon.png")))
})

test_that("generate_assets leaves existing fields untouched and skips the generator", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  full_meta <- c(base_meta, list(
    favicon          = "/favicon.png",
    apple_touch_icon = "/apple-touch-icon.png"
  ))

  generator <- function(prompt, kind) stop("generator should not be called")

  meta <- generate_assets(full_meta, generator, path = tmp)

  expect_equal(meta, full_meta)
  expect_false(file.exists(file.path(tmp, "favicon.png")))
})

test_that("generate_assets accepts a file path from the generator and keeps its extension", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  src <- file.path(tmp, "source.jpg")
  writeBin(as.raw(c(0xff, 0xd8, 0xff)), src)

  meta_without_image <- base_meta
  meta_without_image$image <- NULL

  generator <- function(prompt, kind) src

  meta <- generate_assets(meta_without_image, generator, path = tmp, assets = "image")

  expect_equal(meta$image, "/share-image.jpg")
  expect_true(file.exists(file.path(tmp, "share-image.jpg")))
})

test_that("generate_assets detects the format of raw bytes from magic numbers", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  meta_without_image <- base_meta
  meta_without_image$image <- NULL

  generator <- function(prompt, kind) as.raw(c(0xff, 0xd8, 0xff, 0xe0))

  meta <- generate_assets(meta_without_image, generator, path = tmp, assets = "image")

  expect_equal(meta$image, "/share-image.jpg")
  expect_true(file.exists(file.path(tmp, "share-image.jpg")))
})

test_that("generate_assets validates the assets argument", {
  expect_error(
    generate_assets(base_meta, function(...) NULL, assets = "logo"),
    "must be one or more of"
  )
})

test_that("generate_assets requires a raw vector or file path from the generator", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  generator <- function(prompt, kind) 42

  expect_error(
    generate_assets(base_meta, generator, path = tmp, assets = "favicon"),
    "raw vector"
  )
})

# Local Variables:
# mode: R
# End:
