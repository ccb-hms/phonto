test_that("nhanesTables returns a dataframe", {
  ph = nhanesTables('EXAM', 2008)
  nhsA = nhanesA::nhanesTables('EXAM', 2008)
  expect_equal(colnames(ph), colnames(nhsA))
  # Spirometry - Raw Curve Data (SPXRAW_E)
  # expect_equal(dim(ph), dim(nhsA))
})
