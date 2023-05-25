test_that("nhanesTranslate returns a list of dataframes", {
  expect_equal(nhanesTranslate("DEMO_C",c("RIAGENDR","RIDRETH1")),
               nhanesA::nhanesTranslate("DEMO_C",c("RIAGENDR","RIDRETH1"))
               )
})


test_that("nhanesTranslate returns a list of dataframes", {
  expect_equal(nhanesTranslate("DEMO_C",c("RIAGENDR","RIDRETH1"),details =TRUE),
               nhanesA::nhanesTranslate("DEMO_C",c("RIAGENDR","RIDRETH1"),details =TRUE)
  )
})

