
# Test 1: Check if function returns NULL for NULL input
test_that("unionQuery returns NULL for NULL input", {
  expect_null(unionQuery(NULL))
})

# Test 2: Check if function returns NULL for empty list
test_that("unionQuery returns NULL for empty list", {
  expect_null(unionQuery(list()))
})


# Test 3: Check if function returns data.frame for valid input
test_that("unionQuery returns data.frame for valid input", {
  result <- unionQuery(list(DEMO_I = c("RIDAGEYR","RIAGENDR"), DEMO_J = c("RIDAGEYR","RIAGENDR")))
  expect_s3_class(result, "data.frame")
})
