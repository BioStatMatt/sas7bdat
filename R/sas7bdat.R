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

BUGREPORT <- "please report bugs to sas7bdatRbugs@gmail.com"
CAUTION   <- "please verify data correctness"

# Host systems known to work
KNOWNHOST <- c("WIN_PRO", "WIN_NT", "WIN_NTSV", "WIN_SRV",
               "WIN_ASRV", "XP_PRO", "XP_HOME", "W32_VSPRO",
               "NET_ASRV", "NET_DSRV", "NET_SRV", "WIN_98",
               "W32_VSPR", "WIN")

# Subheader 'signatures'
SUBH_ROWSIZE <- as.raw(c(0xf7,0xf7,0xf7,0xf7))
SUBH_COLSIZE <- as.raw(c(0xf6,0xf6,0xf6,0xf6))
SUBH_COLTEXT <- as.raw(c(0xFD,0xFF,0xFF,0xFF))
SUBH_COLATTR <- as.raw(c(0xFC,0xFF,0xFF,0xFF))
SUBH_COLNAME <- as.raw(c(0xFF,0xFF,0xFF,0xFF))
SUBH_COLLABS <- as.raw(c(0xFE,0xFB,0xFF,0xFF))

# Magic number
MAGIC     <- as.raw(c(0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                      0x0, 0x0, 0x0, 0x0, 0xc2,0xea,0x81,0x60,
                      0xb3,0x14,0x11,0xcf,0xbd,0x92,0x8, 0x0,
                      0x9, 0xc7,0x31,0x8c,0x18,0x1f,0x10,0x11))

check_magic_number <- function(data)
    identical(data[1:length(MAGIC)], MAGIC)

# These functions utilize offset + length addressing
read_bin <- function(buf, off, len, type)
    readBin(buf[(off+1):(off+len)], type, 1, len)
read_raw <- function(buf, off, len)
    readBin(buf[(off+1):(off+len)], "raw", len, 1)
read_int <- function(buf, off, len)
    read_bin(buf, off, len, "integer")
read_str <- function(buf, off, len)
    read_bin(buf, off, len, "character")
read_flo <- function(buf, off, len)
    read_bin(buf, off, len, "double")

get_subhs <- function(subhs, signature) {
    keep <- sapply(subhs, function(subh) {
        identical(subh$signature, signature)
    })
    subhs[keep]
} 

# Sometimes there is more than one column attribute subheader.
# In these cases, the column attribute data are spliced together
# so that the appear to have been in the same subheader
splice_col_attr_subheaders <- function(col_attr) {
    raw <- read_raw(col_attr[[1]]$raw, 0, col_attr[[1]]$length - 8)
    for(i in 2:length(col_attr))
        raw <- c(raw, read_raw(col_attr[[i]]$raw, 12,
            col_attr[[i]]$length - 20))
    return(list(raw=raw))
}

read.sas7bdat <- function(file) {
    require('chron')
    if(inherits(file, "connection") && isOpen(file, "read")) {
        con <- file
        close_con <- FALSE
    } else if (is.character(file)) {
        con <- file(file, "rb")
        close_con <- TRUE
    } else {
        stop("invalid 'file' argument")
    }

    # Check magic number
    header <- readBin(con, "raw", 1024, 1)
    if(length(header) < 1024)
        stop("header too short (not a sas7bdat file?)")
    if(!check_magic_number(header))
        stop(paste("magic number mismatch", BUGREPORT))

    # Timestamp is epoch 01/01/1960
    timestamp <- read_flo(header,164,8)
    timestamp <- chron(timestamp, origin=c(month=1, day=1, year=1960)) 

    page_size   <- read_int(header, 200, 4)
    if(page_size < 0)
        stop(paste("page size is negative", BUGREPORT))

    page_count  <- read_int(header, 204, 4)
    if(page_count < 1)
        stop(paste("page count is not positive", BUGREPORT))

    SAS_release <- read_str(header, 216, 8)
    SAS_host    <- read_str(header, 224, 8)
    if(!(SAS_host %in% KNOWNHOST))
        stop(paste("unknown host", SAS_host, BUGREPORT))

    # Read pages
    pages <- list()
    subhs <- list()
    col_info <- list()
    subhs_parsed <- FALSE
    data  <- list()
    row   <- 0
    for(page_num in 1:page_count) {
        pages[[page_num]] <- list()
        pages[[page_num]]$data <- readBin(con, "raw", page_size, 1)
        pages[[page_num]]$type <- read_int(pages[[page_num]]$data, 17, 1)

        if(!(pages[[page_num]]$type %in% c(0,1,2,4)))
            stop(paste("page", page_num, "has unknown type:",
                pages[[page_num]]$type, BUGREPORT))

        # There isn't enough information in the current data collection to 
        # decipher the purpose of this page type. But, it doesn't appear 
        # to be critical. For now, it's ignored with a warning.
        if(pages[[page_num]]$type == 4)
            warning(paste("page", page_num, "has unknown type: 4", CAUTION))

        # Read subheaders
        if(pages[[page_num]]$type %in% c(0,2)) {
            pages[[page_num]]$subh_count <- read_int(pages[[page_num]]$data, 20, 4)
            for(i in 1:pages[[page_num]]$subh_count) {
                base <- 24 + (i - 1) * 12
                ind  <- length(subhs) + 1
                subhs[[ind]] <- list()
                subhs[[ind]]$page <- page_num
                subhs[[ind]]$offset <- read_int(pages[[page_num]]$data, base, 4)
                subhs[[ind]]$length <- read_int(pages[[page_num]]$data, base + 4, 4)
                if(subhs[[ind]]$length > 0) {
                    subhs[[ind]]$raw <- read_raw(pages[[page_num]]$data, 
                        subhs[[ind]]$offset, subhs[[ind]]$length)
                    subhs[[ind]]$signature <- read_raw(subhs[[ind]]$raw, 0, 4)
                }
            }
        }

        # Parse subheaders
        # If we encounter a page with data (type 1 or 2), then all required subheaders
        # should be present at this point. Of course, it's possible that pages with 
        # subheaders could come after pages with data. In that case, this code would
        # fail. But, this hasn't been observed in test files.
        if(pages[[page_num]]$type %in% c(1, 2) && !subhs_parsed) {

            row_size <- get_subhs(subhs, SUBH_ROWSIZE)
            if(length(row_size) != 1)
                stop(paste("found", length(row_size),
                    "row size subheaders where 1 expected", BUGREPORT))
            row_size <- row_size[[1]]
            row_length   <- read_int(row_size$raw, 20, 4)
            row_count    <- read_int(row_size$raw, 24, 4)
            col_count_7  <- read_int(row_size$raw, 36, 4)
            row_count_fp <- read_int(row_size$raw, 60, 4)

            col_size <- get_subhs(subhs, SUBH_COLSIZE)
            if(length(col_size) != 1)
                stop(paste("found", length(col_size),
                    "column size subheaders where 1 expected", BUGREPORT))
            col_size <- col_size[[1]]
            col_count_6  <- read_int(col_size$raw, 4, 4)
            col_count    <- col_count_6

            if(col_count_7 != col_count_6)
                warning(paste("column count mismatch" , CAUTION))

            # Read column information
            col_text <- get_subhs(subhs, SUBH_COLTEXT)
            if(length(col_text) != 1)
                stop(paste("found", length(col_text),
                    "column text subheaders where 1 expected", BUGREPORT))
            col_text <- col_text[[1]]

            col_attr <- get_subhs(subhs, SUBH_COLATTR)            
            if(length(col_attr) < 1) {
                stop(paste("no column attribute subheader found", BUGREPORT))
            } else if(length(col_attr) == 1) {
                col_attr <- col_attr[[1]]
            } else {
                col_attr <- splice_col_attr_subheaders(col_attr)
            }

            col_name <- get_subhs(subhs, SUBH_COLNAME)
            if(length(col_name) != 1) 
                stop(paste("found", length(col_name),
                    "column name subheaders where 1 expected", BUGREPORT))
            col_name <- col_name[[1]]

            col_labs <- get_subhs(subhs, SUBH_COLLABS)
            if(length(col_labs) < 1)
                col_labs <- NULL
            if(length(col_labs) > 0 && length(col_labs) < col_count)
                stop(paste("found", length(col_labs),
                    "column label subheaders where", col_count,
                    "expected", BUGREPORT))
            
            for(i in 1:col_count) {
                col_info[[i]] <- list()
                
                # Read column names (required)
                base <- 12 + (i-1) * 8
                amd  <- read_int(col_name$raw, base, 1)
                if(amd == 0) {
                    off  <- read_int(col_name$raw, base + 2, 2) + 4
                    len  <- read_int(col_name$raw, base + 4, 2)
                    col_info[[i]]$name <- read_str(col_text$raw, off, len)
                } else {
                    col_info[[i]]$name <- paste("COL", i, sep="")
                    #FIXME if amd == 01, then the column name is located
                    #in an "amendment page" (page type 04)
                }
        
                # Read column labels
                if(!is.null(col_labs)) {
                    base <- 42
                    off  <- read_int(col_labs[[i]]$raw, base, 2) + 4
                    len  <- read_int(col_labs[[i]]$raw, base + 2, 2)
                    if(len > 0)
                        col_info[[i]]$label <- read_str(col_text$raw, off, len)
                }

                # Read column offset, width, type (required)
                base <- 12 + (i-1) * 12
                col_info[[i]]$offset <- read_int(col_attr$raw, base, 4)
                col_info[[i]]$length <- read_int(col_attr$raw, base + 4, 4)
                col_info[[i]]$type   <- read_int(col_attr$raw, base + 10, 2)
                col_info[[i]]$type   <- ifelse(col_info[[i]]$type == 1,
                    "numeric", "character")
            }
            for(col in col_info) {
                if(col$length > 0)
                    data[[col$name]] <- vector(col$type, length=row_count)
            }
            subhs_parsed <- TRUE
        }

        # Read data
        if(pages[[page_num]]$type %in% c(1, 2)) {
            if(!subhs_parsed)
                stop(paste("subheaders were not found", BUGREPORT))
            if(pages[[page_num]]$type == 2) {
                row_count_p <- row_count_fp
                base <- 24 + pages[[page_num]]$subh_count * 12
                base <- base + base %% 8
            } else {
                row_count_p <- read_int(pages[[page_num]]$data, 18, 4)
                base <- 24
            }
            if(row_count_p > row_count)
                row_count_p <- row_count
            for(row in (row+1):(row+row_count_p)) {
                for(col in col_info) {
                    off <- base + col$offset
                    if(col$length > 0) {
                        raw <- read_raw(pages[[page_num]]$data, off, col$length)
                        if(col$type == "numeric" && col$length < 8) {
                            raw <- c(as.raw(rep(0x00, 8 - col$length)),raw)
                            col$length <- 8
                        }
                        data[[col$name]][row] <- readBin(raw, col$type, 1, col$length)
                        # Strip beginning and trailing spaces
                        if(col$type == "character")
                            data[[col$name]][row] <- gsub('^ +| +$', '', data[[col$name]][row])

                    }
                }
                base <- base + row_length
            }
        }        
    }

    if(close_con)
        close(con)

    data <- as.data.frame(data)
    attr(data, 'column.info') <- col_info
    return(data)
}
