context("Write GeMTC XML files")

# Test a dichotomous data file
test_that("write.mtc.network('luades-smoking.gemtc') has expected result", {
  network <- fix.network(dget("../data/luades-smoking.txt"))
  file <- tempfile()
  write.mtc.network(network, file)
  expect_that(read.mtc.network(file), equals(network))
  unlink(file)
})

# Test a continuous data file
test_that("read.mtc.network('parkinson.gemtc') has expected result", {
  network <- fix.network(dget("../data/parkinson.txt"))
  file <- tempfile()
  write.mtc.network(network, file)
  expect_that(read.mtc.network(file), equals(network))
  unlink(file)
})
