test_that("init_meta writes answers to a YAML file", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  dest <- file.path(tmp, "meta.yml")

  answers <- c(
    "Example app",            # title
    "A short description.",   # description
    "https://example.no",     # url
    "https://example.no/x.png", # image
    "Example",                # site_name
    "",                       # locale (default)
    "/favicon.png",           # favicon
    "",                       # apple_touch_icon
    "#1a73e8",                # theme_color
    "y",                      # PWA? yes
    "Example",                # short_name
    "",                       # apple_mobile_web_app_title
    "",                       # twitter_site
    ""                        # twitter_creator
  )
  i <- 0
  testthat::local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_console    = function(prompt = "") { i <<- i + 1; answers[[i]] }
  )

  suppressMessages(init_meta(dest))

  meta <- yaml::read_yaml(dest)

  expect_equal(meta$title, "Example app")
  expect_equal(meta$description, "A short description.")
  expect_equal(meta$url, "https://example.no")
  expect_equal(meta$image, "https://example.no/x.png")
  expect_equal(meta$site_name, "Example")
  expect_equal(meta$locale, "en_US")
  expect_equal(meta$favicon, "/favicon.png")
  expect_null(meta$apple_touch_icon)
  expect_equal(meta$theme_color, "#1a73e8")
  expect_equal(meta$manifest, "/manifest.json")
  expect_equal(meta$short_name, "Example")
  expect_true(meta$apple_mobile_web_app_capable)
  expect_null(meta$apple_mobile_web_app_title)
  expect_null(meta$twitter_site)
})

test_that("init_meta asks before overwriting an existing file, and requires an interactive session", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  dest <- file.path(tmp, "meta.yml")
  writeLines("title: Old", dest)

  interactive_flag <- TRUE
  testthat::local_mocked_bindings(
    is_interactive = function() interactive_flag,
    ask_console    = function(prompt = "") "n"
  )
  suppressMessages(init_meta(dest))
  expect_equal(yaml::read_yaml(dest)$title, "Old")

  interactive_flag <- FALSE
  expect_error(init_meta(tempfile()), "interactive")
})
