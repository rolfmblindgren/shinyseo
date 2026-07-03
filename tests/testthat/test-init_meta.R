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

test_that("init_meta offers existing values as defaults and keeps them on Enter", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  dest <- file.path(tmp, "meta.yml")

  yaml::write_yaml(list(
    title       = "Old title",
    description = "Old description",
    url         = "https://old.example.no",
    image       = "https://old.example.no/x.png",
    locale      = "nb_NO",
    theme_color = "#000000",
    manifest    = "/manifest.json",
    short_name  = "Old",
    apple_mobile_web_app_capable = TRUE
  ), dest)

  prompts <- character()
  testthat::local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_console    = function(prompt = "") { prompts <<- c(prompts, prompt); "" }
  )

  suppressMessages(init_meta(dest))

  meta <- yaml::read_yaml(dest)

  # Pressing Enter on every prompt should keep the existing values.
  expect_equal(meta$title, "Old title")
  expect_equal(meta$description, "Old description")
  expect_equal(meta$url, "https://old.example.no")
  expect_equal(meta$image, "https://old.example.no/x.png")
  expect_equal(meta$locale, "nb_NO")
  expect_equal(meta$theme_color, "#000000")
  expect_equal(meta$manifest, "/manifest.json")
  expect_equal(meta$short_name, "Old")
  expect_true(meta$apple_mobile_web_app_capable)

  # The prompts should have shown the existing values as defaults.
  expect_true(any(grepl("Old title", prompts, fixed = TRUE)))
  expect_true(any(grepl("nb_NO", prompts, fixed = TRUE)))
  expect_true(any(grepl("#000000", prompts, fixed = TRUE)))
})

test_that("init_meta preserves fields it does not ask about", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  dest <- file.path(tmp, "meta.yml")

  yaml::write_yaml(list(
    title       = "Old title",
    description = "Old description",
    url         = "https://old.example.no",
    image       = "https://old.example.no/x.png",
    google_site_verification = "tok-123",
    robots      = "noindex",
    image_alt   = "A picture of the app",
    custom      = list(list(name = "author", content = "Example Author"))
  ), dest)

  testthat::local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_console    = function(prompt = "") ""
  )

  suppressMessages(init_meta(dest))

  meta <- yaml::read_yaml(dest)

  expect_equal(meta$google_site_verification, "tok-123")
  expect_equal(meta$robots, "noindex")
  expect_equal(meta$image_alt, "A picture of the app")
  expect_equal(meta$custom[[1]]$content, "Example Author")
  expect_equal(meta$title, "Old title")
})

test_that("init_meta drops manifest fields when the PWA question is declined", {
  tmp <- tempfile()
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  dest <- file.path(tmp, "meta.yml")

  yaml::write_yaml(list(
    title       = "Old title",
    description = "Old description",
    url         = "https://old.example.no",
    image       = "https://old.example.no/x.png",
    manifest    = "/manifest.json",
    short_name  = "Old",
    apple_mobile_web_app_capable = TRUE,
    apple_mobile_web_app_title   = "Old"
  ), dest)

  answers <- c(
    rep("", 9), # keep everything up to the PWA question
    "n",        # PWA? no
    "", ""      # twitter_site, twitter_creator
  )
  i <- 0
  testthat::local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_console    = function(prompt = "") { i <<- i + 1; answers[[i]] }
  )

  suppressMessages(init_meta(dest))

  meta <- yaml::read_yaml(dest)

  expect_null(meta$manifest)
  expect_null(meta$short_name)
  expect_null(meta$apple_mobile_web_app_capable)
  expect_null(meta$apple_mobile_web_app_title)
  expect_equal(meta$title, "Old title")
})

test_that("init_meta requires an interactive session", {
  testthat::local_mocked_bindings(is_interactive = function() FALSE)

  expect_error(init_meta(tempfile()), "interactive")
})
