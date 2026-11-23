test_that("social_meta builds metadata head tags", {
  tags <- social_meta(list(
    title = "Example app",
    description = "Short app description.",
    url = "https://example.no",
    image = "https://example.no/share.png"
  ))

  html <- htmltools::renderTags(tags)$head

  expect_match(html, "rel=\"canonical\"", fixed = TRUE)
  expect_match(html, "property=\"og:title\" content=\"Example app\"", fixed = TRUE)
  expect_match(html, "name=\"twitter:card\" content=\"summary_large_image\"", fixed = TRUE)
  expect_match(html, "application/ld\\+json")
  expect_false(grepl("og:site_name", html, fixed = TRUE))
  expect_false(grepl("applicationCategory", html, fixed = TRUE))
})

test_that("social_meta can read YAML files", {
  path <- tempfile(fileext = ".yml")
  yaml::write_yaml(list(
    title = "From YAML",
    description = "Loaded from a file.",
    url = "https://example.no",
    image = "https://example.no/share.png"
  ), path)

  html <- htmltools::renderTags(social_meta(path))$head

  expect_match(html, "From YAML", fixed = TRUE)
})

test_that("social_meta validates required fields", {
  expect_error(
    social_meta(list(title = "Only title")),
    "Missing required meta fields"
  )
})

test_that("social_meta rejects invalid required field values", {
  meta <- list(
    title = "App",
    description = "Description",
    url = "https://example.no",
    image = "/share.png"
  )

  meta$title <- " \t"
  meta$description <- NA_character_
  meta$url <- c("https://example.no", "https://example.org")
  meta$image <- 42
  expect_error(social_meta(meta), "non-blank character strings: title, description, url, image")
})

test_that("schema can be disabled", {
  html <- htmltools::renderTags(social_meta(list(
    title = "No schema",
    description = "Short app description.",
    url = "https://example.no",
    image = "https://example.no/share.png",
    schema = FALSE
  )))$head

  expect_false(grepl("application/ld\\+json", html))
})

test_that("twitter metadata can fall back to environment defaults", {
  old_site <- Sys.getenv("SHINYSEO_TWITTER_SITE", unset = NA_character_)
  old_creator <- Sys.getenv("SHINYSEO_TWITTER_CREATOR", unset = NA_character_)
  on.exit({
    if (is.na(old_site)) {
      Sys.unsetenv("SHINYSEO_TWITTER_SITE")
    } else {
      Sys.setenv(SHINYSEO_TWITTER_SITE = old_site)
    }
    if (is.na(old_creator)) {
      Sys.unsetenv("SHINYSEO_TWITTER_CREATOR")
    } else {
      Sys.setenv(SHINYSEO_TWITTER_CREATOR = old_creator)
    }
  }, add = TRUE)

  Sys.setenv(
    SHINYSEO_TWITTER_SITE = "@example_site",
    SHINYSEO_TWITTER_CREATOR = "@example_creator"
  )

  html <- htmltools::renderTags(social_meta(list(
    title = "Env defaults",
    description = "Short app description.",
    url = "https://example.no",
    image = "https://example.no/share.png"
  )))$head

  expect_match(html, "name=\"twitter:site\" content=\"@example_site\"", fixed = TRUE)
  expect_match(html, "name=\"twitter:creator\" content=\"@example_creator\"", fixed = TRUE)
})

test_that("bing verification can fall back to environment defaults", {
  old_bing <- Sys.getenv("SHINYSEO_BING_SITE_VERIFICATION", unset = NA_character_)
  on.exit({
    if (is.na(old_bing)) {
      Sys.unsetenv("SHINYSEO_BING_SITE_VERIFICATION")
    } else {
      Sys.setenv(SHINYSEO_BING_SITE_VERIFICATION = old_bing)
    }
  }, add = TRUE)

  Sys.setenv(SHINYSEO_BING_SITE_VERIFICATION = "bing-env-token")

  html <- htmltools::renderTags(social_meta(list(
    title = "Bing env defaults",
    description = "Short app description.",
    url = "https://example.no",
    image = "https://example.no/share.png"
  )))$head

  expect_match(html, "name=\"msvalidate.01\" content=\"bing-env-token\"", fixed = TRUE)
})

test_that("social_meta includes verification tags when configured", {
  html <- htmltools::renderTags(social_meta(list(
    title = "Verified app",
    description = "Short app description.",
    url = "https://example.no",
    image = "https://example.no/share.png",
    bing_site_verification = "bing-token",
    google_site_verification = "google-token",
    yandex_site_verification = "yandex-token",
    baidu_site_verification = "baidu-token",
    naver_site_verification = "naver-token",
    facebook_domain_verification = "facebook-token",
    pinterest_domain_verification = "pinterest-token"
  )))$head

  expect_match(html, "name=\"msvalidate.01\" content=\"bing-token\"", fixed = TRUE)
  expect_match(html, "name=\"google-site-verification\" content=\"google-token\"", fixed = TRUE)
  expect_match(html, "name=\"yandex-verification\" content=\"yandex-token\"", fixed = TRUE)
  expect_match(html, "name=\"baidu-site-verification\" content=\"baidu-token\"", fixed = TRUE)
  expect_match(html, "name=\"naver-site-verification\" content=\"naver-token\"", fixed = TRUE)
  expect_match(html, "name=\"facebook-domain-verification\" content=\"facebook-token\"", fixed = TRUE)
  expect_match(html, "name=\"p:domain_verify\" content=\"pinterest-token\"", fixed = TRUE)
})

# Local Variables:
# mode: R
# End:
