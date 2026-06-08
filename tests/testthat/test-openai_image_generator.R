test_that("openai_image_generator requires an API key", {
  skip_if_not_installed("httr")

  expect_error(
    openai_image_generator(api_key = ""),
    "needs an OpenAI API key"
  )
})

test_that("openai_image_generator returns a function(prompt, kind) without making a request", {
  skip_if_not_installed("httr")

  generator <- openai_image_generator(api_key = "sk-test")

  expect_true(is.function(generator))
  expect_equal(names(formals(generator)), c("prompt", "kind"))
})

# Local Variables:
# mode: R
# End:
