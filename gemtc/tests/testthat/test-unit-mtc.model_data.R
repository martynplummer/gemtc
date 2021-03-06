context("mtc.model.data");

test_that("mtc.model.data runs on simple data", {
  data <- read.table(textConnection('
study treatment responders sampleSize
1     A         3          10
1     B         4          12'), header=T)
  network <- mtc.network(data)
  model <- list(network=network, likelihood='binom', link='logit', om.scale=2.5)
  model <- mtc.model.data(model)
  expect_that(model$r, equals(t(c(3, 4))))
  expect_that(model$n, equals(t(c(10, 12))))
  expect_that(model$t, equals(t(as.numeric(network$data$treatment))))
})

test_that("mtc.model.data complains about NAs in data.ab", {
  data <- read.table(textConnection('
study treatment responders sampleSize
1     A         3          10
1     B         NA         12'), header=T)
  network <- mtc.network(data)
  model <- list(network=network, likelihood='binom', link='logit', om.scale=2.5)
  expect_error(mtc.model.data(model), 'data.ab contains NAs in column "responders"')

  data <- read.table(textConnection('
study treatment responders sampleSize
1     A         3          10
1     B         4          NA'), header=T)
  network <- mtc.network(data)
  model <- list(network=network, likelihood='binom', link='logit', om.scale=2.5)
  expect_error(mtc.model.data(model), 'data.ab contains NAs in column "sampleSize"')
})

test_that("mtc.model.data includes correct fields for data.ab, binom.logit", {
  data.ab <- read.table(textConnection('
study treatment responders sampleSize exposure
1     A         3          10         20
1     B         4          12         24'), header=T)
  network <- mtc.network(data.ab)
  model <- list(network=network, likelihood='binom', link='logit', om.scale=2.5)
  data <- mtc.model.data(model)
  expect_that(sort(names(data)), equals(
    sort(c(
      'ns.a', 'ns.r2', 'ns.rm', 'ns', 'nt', 'om.scale',
      'na', 't', 'r', 'n'))
  ))
})

test_that("mtc.model.data includes correct fields for data.ab, binom.cloglog", {
  data.ab <- read.table(textConnection('
study treatment responders sampleSize exposure
1     A         3          10         20
1     B         4          12         24'), header=T)
  network <- mtc.network(data.ab)
  model <- list(network=network, likelihood='binom', link='cloglog', om.scale=2.5)
  data <- mtc.model.data(model)
  expect_that(sort(names(data)), equals(
    sort(c(
      'ns.a', 'ns.r2', 'ns.rm', 'ns', 'nt', 'om.scale',
      'na', 't', 'r', 'n'))
  ))
})

test_that("mtc.model.data includes correct fields for data.ab, poisson.log", {
  data.ab <- read.table(textConnection('
study treatment responders sampleSize exposure
1     A         3          10         20
1     B         4          12         24'), header=T)
  network <- mtc.network(data.ab)
  model <- list(network=network, likelihood='poisson', link='log', om.scale=2.5)
  data <- mtc.model.data(model)
  expect_that(sort(names(data)), equals(
    sort(c(
      'ns.a', 'ns.r2', 'ns.rm', 'ns', 'nt', 'om.scale',
      'na', 't', 'r', 'E'))
  ))
})

test_that("mtc.model.data includes correct fields for data.ab, normal.identity", {
  data.ab <- read.table(textConnection('
study treatment mean std.err
1     A         3.4  0.21
1     B         4.0  0.19'), header=T)
  network <- mtc.network(data.ab)
  model <- list(network=network, likelihood='normal', link='identity', om.scale=2.5)
  data <- mtc.model.data(model)
  expect_that(sort(names(data)), equals(
    sort(c(
      'ns.a', 'ns.r2', 'ns.rm', 'ns', 'nt', 'om.scale',
      'na', 't', 'm', 'e'))
  ))
})

test_that("mtc.model.data includes correct fields for data.re", {
  data.re <- read.table(textConnection('
study treatment diff std.err
1     A         NA   0.21
1     B         4.0  0.19'), header=T)
  network <- mtc.network(data.re=data.re)
  model <- list(network=network, likelihood='normal', link='identity', om.scale=2.5)
  data <- mtc.model.data(model)
  expect_that(sort(names(data)), equals(
    sort(c(
      'ns.a', 'ns.r2', 'ns.rm', 'ns', 'nt', 'om.scale',
      'na', 't', 'm', 'e'))
  ))
})

test_that("mtc.model.data includes correct fields for data.ab, normal.identity + data.re", {
  data.ab <- read.table(textConnection('
study treatment mean std.err
1     A         3.4  0.21
1     B         4.0  0.19'), header=T)
  data.re <- read.table(textConnection('
study treatment diff std.err
2     A         NA   0.21
2     B         4.0  0.19'), header=T)
  network <- mtc.network(data.ab, data.re=data.re)
  model <- list(network=network, likelihood='normal', link='identity', om.scale=2.5)
  data <- mtc.model.data(model)
  expect_that(sort(names(data)), equals(
    sort(c(
      'ns.a', 'ns.r2', 'ns.rm', 'ns', 'nt', 'om.scale',
      'na', 't', 'm', 'e'))
  ))
})

test_that("mtc.model.data includes correct fields for data.ab, binom.logit + data.re", {
  data.ab <- read.table(textConnection('
study treatment responders sampleSize
1     A         3          10
1     B         4          12'), header=T)
  data.re <- read.table(textConnection('
study treatment diff std.err
2     A         NA   0.21
2     B         4.0  0.19'), header=T)
  network <- mtc.network(data.ab, data.re=data.re)
  model <- list(network=network, likelihood='binom', link='logit', om.scale=2.5)
  data <- mtc.model.data(model)
  expect_that(sort(names(data)), equals(
    sort(c(
      'ns.a', 'ns.r2', 'ns.rm', 'ns', 'nt', 'om.scale',
      'na', 't', 'r', 'n', 'm', 'e'))
  ))
})

test_that("mtc.model.data has correct values (1)", {
  data.ab <- read.table(textConnection('
study treatment responders sampleSize
1     A         3          10
1     B         4          12
1     C         8          20
1     D         7          21
2     B         3          11
2     C         5          13'), header=T)
  data.re <- read.table(textConnection('
study treatment diff std.err
3     A         NA   0.21
3     B         4.0  0.19'), header=T)
  network <- mtc.network(data.ab, data.re=data.re)
  model <- list(network=network, likelihood='binom', link='logit', om.scale=2.5)
  data <- mtc.model.data(model)
  expect_that(data[['om.scale']], equals(model$om.scale))
  expect_that(data[['ns.a']], equals(2))
  expect_that(data[['ns.r2']], equals(1))
  expect_that(data[['ns.rm']], equals(0))
  expect_that(data[['ns']], equals(3))
  expect_that(data[['nt']], equals(4))
  expect_that(data[['na']], equals(c(4,2,2)))
  expect_that(data[['t']], equals(rbind(
    c(  1,  2,  3,  4),
    c(  2,  3, NA, NA),
    c(  1,  2, NA, NA)
  )))
  expect_that(data[['r']], equals(rbind(
    c(  3,  4,  8,  7),
    c(  3,  5, NA, NA),
    c( NA, NA, NA, NA)
  )))
  expect_that(data[['n']], equals(rbind(
    c( 10, 12, 20, 21),
    c( 11, 13, NA, NA),
    c( NA, NA, NA, NA)
  )))
  expect_that(data[['m']], equals(rbind(
    c( NA,  NA, NA, NA),
    c( NA,  NA, NA, NA),
    c( NA, 4.0, NA, NA)
  )))
  expect_that(data[['e']], equals(rbind(
    c(   NA,   NA, NA, NA),
    c(   NA,   NA, NA, NA),
    c( 0.21, 0.19, NA, NA)
  )))
})

test_that("mtc.model.data has correct values (2)", {
  data.ab <- read.table(textConnection('
study treatment mean std.err
1     A         10.5 0.18
1     B         15.3 0.17
2     B         15.7 0.12
2     C         18.3 0.15
3     B         13.1 0.19
3     C         14.2 0.20'), header=T)
  data.re <- read.table(textConnection('
study treatment diff std.err
4     A         NA   0.15
4     B         3.1  0.22
4     C         4.2  0.24
5     A         2.9  0.28
5     B         NA   NA
6     A         0.2  0.23
6     B         0.8  0.27
6     C         NA   0.16
7     A         NA   0.18
7     B         4.3  0.21
8     B         NA   NA
8     C         4.0  0.19'), header=T)
  network <- mtc.network(data.ab, data.re=data.re)
  model <- list(network=network, likelihood='normal', link='identity', om.scale=2.5)
  data <- mtc.model.data(model)
  expect_that(data[['om.scale']], equals(model$om.scale))
  expect_that(data[['ns.a']], equals(3))
  expect_that(data[['ns.r2']], equals(3))
  expect_that(data[['ns.rm']], equals(2))
  expect_that(data[['ns']], equals(8))
  expect_that(data[['nt']], equals(3))
  expect_that(data[['na']], equals(c(2,2,2,2,2,2,3,3)))
  expect_that(data[['t']], equals(rbind(
    c(  1,  2, NA), # 1
    c(  2,  3, NA), # 2
    c(  2,  3, NA), # 3
    c(  2,  1, NA), # 5
    c(  1,  2, NA), # 7
    c(  2,  3, NA), # 8
    c(  1,  2,  3), # 4
    c(  3,  1,  2)  # 6
  )))
  expect_that(data[['m']], equals(rbind(
    c( 10.5, 15.3,   NA), # 1
    c( 15.7, 18.3,   NA), # 2
    c( 13.1, 14.2,   NA), # 3
    c(   NA,  2.9,   NA), # 5
    c(   NA,  4.3,   NA), # 7
    c(   NA,  4.0,   NA), # 8
    c(   NA,  3.1,  4.2), # 4
    c(   NA,  0.2,  0.8)  # 6
  )))
  expect_that(data[['e']], equals(rbind(
    c( 0.18, 0.17,   NA), # 1
    c( 0.12, 0.15,   NA), # 2
    c( 0.19, 0.20,   NA), # 3
    c(   NA, 0.28,   NA), # 5
    c( 0.18, 0.21,   NA), # 7
    c(   NA, 0.19,   NA), # 8
    c( 0.15, 0.22, 0.24), # 4
    c( 0.16, 0.23, 0.27)  # 6
  )))
})
