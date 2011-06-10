\name{read.sas7bdat}
\alias{read.sas7bdat}
\title{
SAS Database Reader (experimental)
}
\description{
Read SAS files in the sas7bdat data format.
}
\usage{
read.sas7bdat(file)
}
\arguments{
  \item{file}{Path to a file or an URL.}
}
\section{Warning}{
The functionality in this package is EXPERIMENTAL and may not work for all SAS databases having the extension \code{sas7bdat}! Use at your own risk. For more details, see the package vignettes. 
}
\value{
   A data frame corresponding to the SAS database. The returned data frame has an \code{column.info} attribute, which contains additional information about each field in the data frame, respectively. The \code{column.info} attribute is a list of lists, containing zero or more of the following:
   \item{name}{The field name}
   \item{label}{The field label (usually a longer description)}
   \item{offset}{The field offset in packed binary row data (bytes)}
   \item{length}{The field length (bytes)}
   \item{type}{The field type, either 'character' or 'numeric'}
}
\references{
http://biostatmatt.com/archives/tag/sas7bdat
}
\author{
Matt Shotwell
}

\examples{
# read.sas7bdat("http://bus.utk.edu/stat/stat579/hotel.sas7bdat")
}
