\encoding{utf8}
\name{rank.probability}
\alias{rank.probability}
\title{Calculating rank-probabilities}
\description{
Rank probabilities indicate the probability for each treatment to be best, second best, etc.
}
\details{
For each MCMC iteration, the treatments are ranked by their effect relative to an arbitrary baseline.
A frequency table is constructed from these rankings and normalized by the number of iterations to give the rank probabilities.
}
\usage{
rank.probability(result, preferredDirection=1)
}
\arguments{
  \item{result}{Object of S3 class \code{mtc.result} to be used in creation of the rank probability table}
  \item{preferredDirection}{Preferential direction of the outcome. Set 1 if higher values are preferred, -1 if lower values are preferred.}
}
\value{A matrix with the treatments as rows and the ranks as columns.
The matrix is given class \code{mtc.rank.probability}, for which \code{print} and \code{plot} are overriden. }

\author{Gert van Valkenhoef, Joël Kuiper}

\seealso{
\code{\link{relative.effect}}
}
\examples{
model <- mtc.model(smoking)
# To save computation time we load the samples instead of running the model
\dontrun{results <- mtc.run(model)}
results <- dget(system.file("extdata/luades-smoking.samples.gz", package="gemtc"))

ranks <- rank.probability(results)
print(ranks)
## Rank probability; preferred direction = 1
##       [,1]     [,2]     [,3]     [,4]
## A 0.000000 0.003000 0.105125 0.891875
## B 0.057875 0.175875 0.661500 0.104750
## C 0.228250 0.600500 0.170875 0.000375
## D 0.713875 0.220625 0.062500 0.003000

plot(ranks) # plot a cumulative rank plot
plot(ranks, beside=TRUE) # plot a 'rankogram'
}
