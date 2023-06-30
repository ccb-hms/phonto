# Test 1: Check if function returns an error for invalid survey group
test_that("nhanesTables returns an error for invalid survey group", {
  expect_error(nhanesTables("INVALID_GROUP", 2000), "Invalid survey group")
})


# Test 2: Check if function returns a dataframe by default
test_that("nhanesTables returns a dataframe by default", {
  result =  nhanesTables("DEMO", 2000)
  expect_s3_class(result, "data.frame")
})

# Test 3: Check if function returns a character vector for namesonly=TRUE
test_that("nhanesTables returns a character vector for namesonly=TRUE", {
  result = nhanesTables("DEMO", 2000, namesonly=TRUE)
  expect_type(result, "character")
})

