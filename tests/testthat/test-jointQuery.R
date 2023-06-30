# Test 1: Check if function returns NULL for NULL input
test_that("jointQuery returns NULL for NULL input", {
  expect_equal(jointQuery(NULL), NULL)
})

# Test 2: Check if function returns NULL for empty input
test_that("jointQuery returns NULL for empty input", {
  expect_equal(jointQuery(list()), NULL)
})

# Test 3: Check if function returns a dataframe
test_that("jointQuery returns a dataframe", {
  result = jointQuery(list(BPQ_J=c("BPQ020", "BPQ050A"), DEMO_J=c("RIDAGEYR","RIAGENDR")))
  expect_s3_class(result, "data.frame")
})

# Test 4: Check if function returns correct columns
test_that("jointQuery returns correct columns", {
  result = jointQuery(list(DEMO_J=c("RIDAGEYR","RIAGENDR")))
  expect_equal(colnames(result), c("SEQN", "RIDAGEYR", "RIAGENDR", "Begin.Year", "EndYear"))
})

# Test 5: Check if function handles inconsistent variable names
test_that("jointQuery handles inconsistent variable names", {
  result = jointQuery(list(DEMO_J=c("RIDAGEYR","RIAGENDR","RANDOM_VAR")))
  expect_null(result)
})

