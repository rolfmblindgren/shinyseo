test_that("update_meta sends correct message for all fields", {
  sent <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      sent[[type]] <<- message
    }
  )

  update_meta(session,
    title       = "New title",
    description = "New description",
    url         = "https://example.no/page2",
    image       = "https://example.no/page2.png"
  )

  expect_equal(sent$shinyseo_update_meta$title,       "New title")
  expect_equal(sent$shinyseo_update_meta$description, "New description")
  expect_equal(sent$shinyseo_update_meta$url,         "https://example.no/page2")
  expect_equal(sent$shinyseo_update_meta$image,       "https://example.no/page2.png")
})

test_that("update_meta sends only supplied fields", {
  sent <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      sent[[type]] <<- message
    }
  )

  update_meta(session, title = "Just a title")

  expect_equal(sent$shinyseo_update_meta$title, "Just a title")
  expect_null(sent$shinyseo_update_meta$description)
  expect_null(sent$shinyseo_update_meta$url)
  expect_null(sent$shinyseo_update_meta$image)
})

test_that("update_meta does nothing when no fields are supplied", {
  called <- FALSE
  session <- list(
    sendCustomMessage = function(type, message) {
      called <<- TRUE
    }
  )

  update_meta(session)

  expect_false(called)
})

test_that("social_meta injects the shinyseo_update_meta handler script", {
  html <- htmltools::renderTags(social_meta(list(
    title       = "App",
    description = "Desc",
    url         = "https://example.no",
    image       = "https://example.no/share.png"
  )))$head

  expect_match(html, "shinyseo_update_meta", fixed = TRUE)
})

# Local Variables:
# mode: R
# End:
