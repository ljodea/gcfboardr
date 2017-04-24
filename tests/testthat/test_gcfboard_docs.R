# tests for gcfboard_docs dataset

context("Tidy dataframe for gcf docs")

suppressPackageStartupMessages(library(dplyr))

test_that("tidy frame for GCF Board Docs is right", {
  data(gcfboard_docs)
  d <- gcfboard_docs %>%
    group_by(meeting) %>%
    summarise(total_lines = n())
  expect_equal(nrow(d), 15)
  expect_equal(ncol(d), 2)
})
