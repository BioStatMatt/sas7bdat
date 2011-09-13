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
The functionality in this package is EXPERIMENTAL. Use at your own risk. For the latest details, see the \sQuote{sas7bdat} vignette (\emph{i.e.}, \code{vignette('sas7bdat')}). 
}
\value{
   A data frame corresponding to the SAS database. The returned data frame has an \code{column.info} attribute, which contains additional information about each field in the data frame, respectively. The \code{column.info} attribute is a list of lists, containing each of the following:
   \item{name}{The field name}
   \item{offset}{The field offset in packed binary row data (bytes)}
   \item{length}{The field length (bytes)}
   \item{type}{The field type, either 'character' or 'numeric'}
When the database specifies a field format and/or label, the following may also be present:
   \item{format}{The field display format}
   \item{label}{The field label (usually a longer description)}
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
