base_meta <- list(
  title       = "Test App",
  description = "A test.",
  url         = "https://example.no",
  image       = "https://example.no/share.png"
)

test_that("social_meta injects custom name/content tags", {
  html <- htmltools::renderTags(social_meta(c(base_meta, list(
    custom = list(
      list(name = "x-custom-field", content = "my-value")
    )
  ))))$head

  expect_match(html, 'name="x-custom-field"',  fixed = TRUE)
  expect_match(html, 'content="my-value"',      fixed = TRUE)
})

test_that("social_meta injects custom property tags", {
  html <- htmltools::renderTags(social_meta(c(base_meta, list(
    custom = list(
      list(property = "og:video", content = "https://example.no/video.mp4")
    )
  ))))$head

  expect_match(html, 'property="og:video"',                       fixed = TRUE)
  expect_match(html, 'content="https://example.no/video.mp4"',   fixed = TRUE)
})

test_that("social_meta injects multiple custom tags", {
  html <- htmltools::renderTags(social_meta(c(base_meta, list(
    custom = list(
      list(name = "viewport",   content = "width=device-width, initial-scale=1"),
      list(name = "x-app-env",  content = "production")
    )
  ))))$head

  expect_match(html, 'name="viewport"',   fixed = TRUE)
  expect_match(html, 'name="x-app-env"', fixed = TRUE)
})

test_that("social_meta omits custom tags when not set", {
  html <- htmltools::renderTags(social_meta(base_meta))$head
  expect_false(grepl("x-custom", html, fixed = TRUE))
})

# Local Variables:
# mode: R
# End:
