\name{sas7bdat.sources}
\alias{sas7bdat.sources}
\docType{data}
\title{
Internet SAS Database Resources
}
\description{
These data are a collection of internet resources for SAS database files in the sas7bdat format.
}
\usage{data(sas7bdat.sources)}
\format{
  A data frame with 290 observations on the following 7 variables.
  \describe{
    \item{\code{filename}}{a character vector, the SAS database filename}
    \item{\code{date}}{a POSIXct, the date last retrieved}
    \item{\code{uncompressed}}{a numeric vector, file size (bytes)}
    \item{\code{gzip}}{a numeric vector, gzip compressed file size (bytes)}
    \item{\code{bzip2}}{a numeric vector, bzip2 compressed file size (bytes)}
    \item{\code{xz}}{a numeric vector, xz compressed file size (bytes)}
    \item{\code{url}}{a character vector, the Universal Resource Locator}
  }
}
\examples{
data(sas7bdat.sources)
}
\keyword{datasets}
