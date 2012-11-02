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
  A data frame with records on the following fields:
  \describe{
    \item{\code{filename}}{character, the SAS database filename}
    \item{\code{accessed}}{POSIXct, the date last retrieved}
    \item{\code{uncompressed}}{numeric, file size (bytes)}
    \item{\code{gzip}}{numeric, gzip compressed file size (bytes)}
    \item{\code{bzip2}}{numeric, bzip2 compressed file size (bytes)}
    \item{\code{xz}}{numeric, xz compressed file size (bytes)}
    \item{\code{url}}{character, the Universal Resource Locator}
    \item{\code{PKGversion}}{character, the \pkg{sas7bdat} package version}
    \item{\code{message}}{character, message returned by \code{read.sas7bdat} (if any)}
    \item{\code{SASrelease}}{character, SAS release}
    \item{\code{SAShost}}{character, SAS host platform}
    \item{\code{OSversion}}{character, OS version}
    \item{\code{OSmaker}}{character, OS maker}
    \item{\code{OSname}}{character, OS name}
    \item{\code{endianness}}{character, endianness of header fields}
    \item{\code{winunix}}{character, platform type}
  }
}
\examples{
data(sas7bdat.sources)
}
\keyword{datasets}
