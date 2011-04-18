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

# This file is a placeholder for experiments using the test data referenced in
# data/sources. These scripts assume that test files are downloaded and 'xz'
# compressed in the data/files/ directory. 

source("sas7bdat.R")
dirpath <- file.path("..","data","files")
dirlist <- file.path(dirpath, list.files(dirpath))

# Header read test 
headers <- list()
for(i in 1:length(dirlist)) {
    con <- xzfile(dirlist[i], "rb")
    headers[[i]] <- read.sas7bdat(con, debug=1)
    close(con)
}
# consider platform polymorphisms in the header
# sapply(headers, function(x) c(x$header[36:41], x$header[217:240]))

# Subheader read test
subread <- list()
for(i in 1:length(dirlist)) {
    con <- xzfile(dirlist[i], "rb")
    subread[[i]] <- read.sas7bdat(con, debug=2)
    close(con)
}

# Subheader parse test
subparse <- list()
for(i in 1:length(dirlist)) {
    con <- xzfile(dirlist[i], "rb")
    subparse[[i]] <- read.sas7bdat(con, debug=3)
    close(con)
}

# Data read test
data_test <- list()
for(i in 1:length(dirlist)) {
    cat("data read test:", dirlist[i], "\n")
    con <- xzfile(dirlist[i], "rb")
    data_test[[i]] <- read.sas7bdat(con, debug=4)
    close(con)
}

complete_read_test <- list()
for(i in 1:length(dirlist)) {
    cat("complete read test:", dirlist[i], "\n")
    con <- xzfile(dirlist[i], "rb")
    complete_read_test[[i]] <- tryCatch(read.sas7bdat(con),
        error=function(e)e)
    close(con)
}
