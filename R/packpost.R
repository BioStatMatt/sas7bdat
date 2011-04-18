#    Copyright (C) 2011 Matt Shotwell, VUMC
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# This function compresses a file using 'xz -9' compression 
# and uploads the file to a server using the HTTP POST method.
# 'packpost' is shorthand for 'compress and upload'. The receiving
# server should be set up to receive this upload using a server-side
# scripting mechanism.
packpost <- function(file, host="localhost", port="80",
    location="/", quiet = FALSE, query = URLencode(file)) {

    if(!is.character(file) || length(file) != 1)
        stop("'file' must be a character vector of length 1")
    if(!is.character(host) || length(host) != 1)
        stop("'host' must be a character vector of length 1")
    if(!is.character(port) || length(port) != 1)
        stop("'port' must be a character vector of length 1")
    if(!is.character(location) || length(location) != 1)
        stop("'location' must be a character vector of length 1")
    if(!is.logical(quiet) || length(quiet) != 1)
        stop("'quiet' must be a logical vector of length 1")
    if(!is.character(query) || length(query) != 1)
        stop("'query' must be a character vector of length 1")

    # pack
    cfile <- tempfile()
    fcon  <- file(file, open="rb")
    ccon  <- xzfile(cfile, open="wb", compression=9)
    if(!quiet)
        cat("packpost: compressing", file, "->", cfile, "\n")
    while(length(buff <- readBin(fcon, "raw", 1024)) > 0)
        writeBin(buff, ccon)
    close(fcon)
    close(ccon)
    if(!quiet)
        cat("packpost: compression ratio:", 
            file.info(file)$size / file.info(cfile)$size, "\n") 

    # post 
    if(!quiet)
        cat("packpost: uploading", cfile, "\n")
    location <- paste(URLencode(location), "?", URLencode(query), sep="")
    header <- paste("POST ", location, " HTTP/1.1\r\n",
                    "Host: ", paste(host, port, sep=":"), "\r\n",
                    "Content-Length: ", file.info(cfile)$size, "\r\n",
                    "Content-Type: application/x-xz\r\n\r\n", sep="")

    ccon <- file(cfile, open="rb")
    scon <- socketConnection(host, port, open="w+b", blocking=TRUE)
    cat(header, file=scon)
    while(length(buff <- readBin(ccon, "raw", 1024)) > 0)
        writeBin(buff, scon)
    response <- readLines(scon, n=1)
    close(scon)
    close(ccon)
    if(!quiet)
        cat("packpost: removing", cfile, "\n")
    unlink(cfile)
    return(response)
}
