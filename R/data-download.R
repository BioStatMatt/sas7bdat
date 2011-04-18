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
#
# This code attempts to download some of the data files references in 
# data/sources.csv. Not all files are downloaded. Files that are compressed,
# part of an archive, or larger than MAXSIZE are not downloaded. It is
# recommended to compress these files using the 'xz -9' algorithm after
# download for efficient storage and unpacking.


# Read source information
sources <- read.csv(file.path("..","data","sources.csv"),
     colClasses=c(rep("character",2), rep("numeric", 4), "character"))

# Don't download compressed archives, duplicates, or files larger
# than MAXSIZE
MAXSIZE <- 1024L * 1024L
sources <- subset(sources, !grepl(".zip$", url) & uncompressed <= MAXSIZE)

for(i in 1:nrow(sources)) {
    path <- file.path("..", "data", "files", sources$filename[i])
    tryCatch(download.file(sources$url[i], path), error=function(e) unlink(path))
}
