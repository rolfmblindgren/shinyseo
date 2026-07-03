base_meta <- list(
  title       = "Test App",
  description = "A test.",
  url         = "https://example.no",
  image       = "https://example.no/share.png"
)

test_that("social_meta injects favicon link tag", {
  html <- htmltools::renderTags(social_meta(c(base_meta, list(
    favicon = "/favicon.png"
  ))))$head

  expect_match(html, 'rel="icon"',              fixed = TRUE)
  expect_match(html, 'href="/favicon.png"',      fixed = TRUE)
  expect_match(html, 'type="image/png"',         fixed = TRUE)
})

test_that("social_meta infers correct MIME types", {
  expect_equal(favicon_mime("/favicon.ico"),  "image/x-icon")
  expect_equal(favicon_mime("/favicon.png"),  "image/png")
  expect_equal(favicon_mime("/favicon.svg"),  "image/svg+xml")
  expect_equal(favicon_mime("/favicon.webp"), "image/webp")
  expect_equal(favicon_mime("/favicon.gif"),  "image/gif")
  expect_equal(favicon_mime("/favicon.jpg"),  "image/jpeg")
  expect_equal(favicon_mime("/favicon.jpeg"), "image/jpeg")
  expect_equal(favicon_mime("/favicon.ico", "image/png"), "image/png")
})

test_that("social_meta injects apple-touch-icon", {
  html <- htmltools::renderTags(social_meta(c(base_meta, list(
    apple_touch_icon = "/apple-touch-icon.png"
  ))))$head

  expect_match(html, 'rel="apple-touch-icon"',          fixed = TRUE)
  expect_match(html, 'href="/apple-touch-icon.png"',    fixed = TRUE)
})

test_that("social_meta injects theme-color and manifest", {
  html <- htmltools::renderTags(social_meta(c(base_meta, list(
    theme_color = "#1a73e8",
    manifest    = "/manifest.json"
  ))))$head

  expect_match(html, 'name="theme-color" content="#1a73e8"', fixed = TRUE)
  expect_match(html, 'rel="manifest"',                       fixed = TRUE)
  expect_match(html, 'href="/manifest.json"',                fixed = TRUE)
})

test_that("social_meta injects PWA home screen meta tags", {
  html <- htmltools::renderTags(social_meta(c(base_meta, list(
    apple_mobile_web_app_capable = TRUE,
    apple_mobile_web_app_title = "MyApp",
    apple_mobile_web_app_status_bar_style = "black-translucent"
  ))))$head

  expect_match(html, 'name="apple-mobile-web-app-capable" content="yes"',          fixed = TRUE)
  expect_match(html, 'name="mobile-web-app-capable" content="yes"',                fixed = TRUE)
  expect_match(html, 'name="apple-mobile-web-app-title" content="MyApp"',          fixed = TRUE)
  expect_match(html, 'name="apple-mobile-web-app-status-bar-style" content="black-translucent"', fixed = TRUE)
})

test_that("social_meta omits PWA home screen meta tags when not configured", {
  html <- htmltools::renderTags(social_meta(base_meta))$head

  expect_false(grepl('apple-mobile-web-app-capable',     html, fixed = TRUE))
  expect_false(grepl('mobile-web-app-capable',           html, fixed = TRUE))
  expect_false(grepl('apple-mobile-web-app-title',       html, fixed = TRUE))
  expect_false(grepl('apple-mobile-web-app-status-bar-style', html, fixed = TRUE))
})

test_that("social_meta omits favicon tags when not configured", {
  html <- htmltools::renderTags(social_meta(base_meta))$head

  expect_false(grepl('rel="icon"',             html, fixed = TRUE))
  expect_false(grepl('rel="apple-touch-icon"', html, fixed = TRUE))
  expect_false(grepl('rel="manifest"',         html, fixed = TRUE))
  expect_false(grepl('theme-color',            html, fixed = TRUE))
})

test_that("write_manifest creates a valid manifest.json", {
  tmp <- tempfile()
  dir.create(tmp)

  dest <- write_manifest(c(base_meta, list(
    theme_color      = "#1a73e8",
    apple_touch_icon = "/apple-touch-icon.png",
    favicon          = "/favicon.png",
    short_name       = "TestApp"
  )), path = tmp)

  expect_true(file.exists(dest))

  parsed <- jsonlite::fromJSON(dest)
  expect_equal(parsed$name,             "Test App")
  expect_equal(parsed$short_name,       "TestApp")
  expect_equal(parsed$description,      "A test.")
  expect_equal(parsed$theme_color,      "#1a73e8")
  expect_equal(parsed$background_color, "#1a73e8")
  expect_equal(parsed$display,          "standalone")
  expect_equal(parsed$start_url,        "/")
  expect_true(nrow(parsed$icons) > 0)
})

test_that("write_manifest falls back to white background when no theme_color", {
  tmp <- tempfile()
  dir.create(tmp)
  dest <- write_manifest(base_meta, path = tmp)
  parsed <- jsonlite::fromJSON(dest)
  expect_equal(parsed$background_color, "#ffffff")
})

# Local Variables:
# mode: R
# End:
