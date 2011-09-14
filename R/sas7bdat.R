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
               "WIN_ASRV", "XP_PRO", "XP_HOME", "NET_ASRV",
               "NET_DSRV", "NET_SRV", "WIN_98", "W32_VSPR",
               "WIN", "WIN_95", "X64_VSPR", "X64_ESRV")

# Subheader 'signatures'
SUBH_ROWSIZE <- as.raw(c(0xF7,0xF7,0xF7,0xF7))
SUBH_COLSIZE <- as.raw(c(0xF6,0xF6,0xF6,0xF6))
SUBH_COLTEXT <- as.raw(c(0xFD,0xFF,0xFF,0xFF))
SUBH_COLATTR <- as.raw(c(0xFC,0xFF,0xFF,0xFF))
SUBH_COLNAME <- as.raw(c(0xFF,0xFF,0xFF,0xFF))
SUBH_COLLABS <- as.raw(c(0xFE,0xFB,0xFF,0xFF))
SUBH_COLLIST <- as.raw(c(0xFE,0xFF,0xFF,0xFF))
SUBH_SUBHCNT <- as.raw(c(0x00,0xFC,0xFF,0xFF))

# Page types
PAGE_META <- 0
PAGE_DATA <- 256
PAGE_MIX  <- 512
PAGE_AMD  <- 1024
PAGE_MIX_DATA <- c(PAGE_MIX, PAGE_DATA)
PAGE_META_MIX_AMD <- c(PAGE_META, PAGE_MIX, PAGE_AMD)
PAGE_ANY  <- c(PAGE_META_MIX_AMD, PAGE_DATA)

read_subheaders <- function(page) {
    subhs <- list()
    subh_total <- 0
    if(!(page$type %in% PAGE_META_MIX_AMD))
        return(subhs)
    for(i in 1:page$subh_count) {
        subh_total <- subh_total + 1
        base <- 24 + (i - 1) * 12
        subhs[[subh_total]] <- list()
        subhs[[subh_total]]$page <- page$page 
        subhs[[subh_total]]$offset <- read_int(page$data, base, 4)
        subhs[[subh_total]]$length <- read_int(page$data, base + 4, 4)
        if(subhs[[subh_total]]$length > 0) {
            subhs[[subh_total]]$raw <- read_raw(page$data, 
                subhs[[subh_total]]$offset, subhs[[subh_total]]$length)
            subhs[[subh_total]]$signature <- read_raw(subhs[[subh_total]]$raw, 0, 4)
        }
    }
    return(subhs)
}

read_column_names <- function(col_name, col_text) {
    names <- list()
    name_count <- 0
    for(subh in col_name) {
        for(i in 1:((subh$length - 20)/8)) {
            name_count <- name_count + 1
            names[[name_count]] <- list()
            base <- 12 + (i-1) * 8
            txt  <- read_int(subh$raw, base, 2)
            off  <- read_int(subh$raw, base + 2, 2) + 4
            len  <- read_int(subh$raw, base + 4, 2)
            names[[name_count]]$name <- read_str(col_text[[txt+1]]$raw, off, len)
        }
    }
    return(names)
}

read_column_labels_formats <- function(col_labs, col_text) {
    if(length(col_labs) < 1)
        return(NULL)
    labs <- list()
    for(i in 1:length(col_labs)) {
        labs[[i]] <- list()
        base <- 34
        txt  <- read_int(col_labs[[i]]$raw, base, 2)
        off  <- read_int(col_labs[[i]]$raw, base + 2, 2) + 4
        len  <- read_int(col_labs[[i]]$raw, base + 4, 2)
        if(len > 0)
            labs[[i]]$format <- read_str(col_text[[txt+1]]$raw, off, len)
        base <- 40
        txt  <- read_int(col_labs[[i]]$raw, base, 2)
        off  <- read_int(col_labs[[i]]$raw, base + 2, 2) + 4
        len  <- read_int(col_labs[[i]]$raw, base + 4, 2)
        if(len > 0)
            labs[[i]]$label <- read_str(col_text[[txt+1]]$raw, off, len)
    }
    return(labs)
}
 
read_column_attributes <- function(col_attr) {
    info <- list()
    info_count <- 0
    for(subh in col_attr) {
        for(i in 1:((subh$length-20)/12)) {
            info_count <- info_count + 1
            info[[info_count]] <- list()
            base <- 12 + (i-1) * 12
            info[[info_count]]$offset <- read_int(subh$raw, base, 4)
            info[[info_count]]$length <- read_int(subh$raw, base + 4, 4)
            info[[info_count]]$type   <- read_int(subh$raw, base + 10, 2)
            info[[info_count]]$type   <- ifelse(info[[info_count]]$type == 1,
            "numeric", "character")
        }
    }
    return(info)
}

# Alignment
ALIGN_64     <- as.raw(c(0x33,0x33))
ALIGN_32     <- as.raw(c(0x32,0x22))


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

    # Check for 32 or 64 bit alignment
    align <- read_raw(header, 35, 2)
    if(identical(align, ALIGN_32)) {
        halign <- 0 
    } else if(identical(align, ALIGN_64)) {
        halign <- 4 
    } else {
        stop(paste("unrecognized alignment code",
            paste(align, collapse=''), BUGREPORT))
    }
    
    # Timestamp is epoch 01/01/1960
    timestamp <- read_flo(header,164 + halign,8)
    timestamp <- chron(timestamp, origin.=c(month=1, day=1, year=1960)) 


    page_size   <- read_int(header, 200 + halign, 4)
    if(page_size < 0)
        stop(paste("page size is negative", BUGREPORT))

    page_count  <- read_int(header, 204 + halign, 4)
    if(page_count < 1)
        stop(paste("page count is not positive", BUGREPORT))
    

    SAS_release <- read_str(header, 216 + halign, 8)
    SAS_host    <- read_str(header, 224 + halign, 8)
    if(!(SAS_host %in% KNOWNHOST))
        stop(paste("unknown host", SAS_host, BUGREPORT))

    
    # Read pages
    pages <- list()
    for(page_num in 1:page_count) {
        pages[[page_num]] <- list()
        pages[[page_num]]$page <- page_num
        pages[[page_num]]$data <- readBin(con, "raw", page_size, 1)
        pages[[page_num]]$type <- read_int(pages[[page_num]]$data, 16, 2)
        if(pages[[page_num]]$type %in%  PAGE_META_MIX_AMD)
            pages[[page_num]]$subh_count <- read_int(pages[[page_num]]$data, 20, 2)
    }

    if(any(sapply(pages, function(page) !(page$type %in% PAGE_ANY))))
        stop(paste("page", page_num, "has unknown type:",
            pages[[page_num]]$type, BUGREPORT))

    # Read subheaders
    subhs <- list()
    for(page in pages)
        subhs <- c(subhs, read_subheaders(page)) 

    # Parse subheaders

    # Parse subheader count subheader
    # At present, the data stored in this subheader is not
    # necessary, but might be used in the future for verification.
    # The column attribute, text, name, and list subheaders are 
    # known to occur multiple times.

    #subh_cnt <- get_subhs(subhs, SUBH_SUBHCNT)
    #if(length(subh_cnt) != 1)
    #    stop(paste("found", length(subh_cnt),
    #        "subheader count subheaders where 1 expected", BUGREPORT))
    #subh_cnt <- subh_cnt[[1]]
    #subh_cnts <- list()
    #for(scnt in 1:11) {
    #    base <- 84 + (scnt - 1) * 20
    #    subh_cnts[[scnt]]       <- list()
    #    subh_cnts[[scnt]]$sig   <- read_raw(subh_cnt$raw, base, 4)
    #    subh_cnts[[scnt]]$page1 <- read_int(subh_cnt$raw, base + 4, 4)
    #    subh_cnts[[scnt]]$loc1  <- read_int(subh_cnt$raw, base + 8, 4)
    #    subh_cnts[[scnt]]$pagel <- read_int(subh_cnt$raw, base + 12, 4)
    #    subh_cnts[[scnt]]$locl  <- read_int(subh_cnt$raw, base + 16, 4)
    #}

    # Parse row size subheader
    row_size <- get_subhs(subhs, SUBH_ROWSIZE)
    if(length(row_size) != 1)
        stop(paste("found", length(row_size),
            "row size subheaders where 1 expected", BUGREPORT))
    row_size <- row_size[[1]]
    row_length   <- read_int(row_size$raw, 20, 4)
    row_count    <- read_int(row_size$raw, 24, 4)
    col_count_p1 <- read_int(row_size$raw, 36, 4)
    col_count_p2 <- read_int(row_size$raw, 40, 4)
    row_count_fp <- read_int(row_size$raw, 60, 4)

    # Parse col size subheader
    col_size <- get_subhs(subhs, SUBH_COLSIZE)
    if(length(col_size) != 1)
        stop(paste("found", length(col_size),
            "column size subheaders where 1 expected", BUGREPORT))
    col_size <- col_size[[1]]
    col_count_6  <- read_int(col_size$raw, 4, 4)
    col_count    <- col_count_6

    #if((col_count_p1 + col_count_p2) != col_count_6)
    #    warning(paste("column count mismatch" , CAUTION))

    # Read column information
    col_text <- get_subhs(subhs, SUBH_COLTEXT)
    if(length(col_text) < 1)
        stop(paste("no column text subheaders found", BUGREPORT))

    col_attr <- get_subhs(subhs, SUBH_COLATTR)            
    if(length(col_attr) < 1)
        stop(paste("no column attribute subheaders found", BUGREPORT))
    col_attr <- read_column_attributes(col_attr)
    if(length(col_attr) != col_count)
        stop(paste("found", length(col_attr), 
            "column attributes where", col_count,
            "expected", BUGREPORT))

    col_name <- get_subhs(subhs, SUBH_COLNAME)
    if(length(col_name) < 1)
        stop(paste("no column name subheaders found", BUGREPORT))
    col_name <- read_column_names(col_name, col_text)
    if(length(col_name) != col_count)
        stop(paste("found", length(col_name), 
            "column names where", col_count, "expected", BUGREPORT))

    col_labs <- get_subhs(subhs, SUBH_COLLABS)
    col_labs <- read_column_labels_formats(col_labs, col_text)
    if(is.null(col_labs))
        col_labs <- list(length=col_count)
    if(length(col_labs) != col_count)
        stop(paste("found", length(col_labs), 
            "column formats and labels", col_count, "expected", BUGREPORT))

    # Collate column information
    col_info <- list()
    for(i in 1:col_count)
        col_info[[i]] <- c(col_name[[i]], col_attr[[i]], col_labs[[i]]) 

    # Parse data
    data  <- list()
    for(col in col_info)
        if(col$length > 0)
            data[[col$name]] <- vector(col$type, length=row_count)

    row   <- 0
    for(page in pages) {
        #FIXME are there data on pages of type 4?
        if(!(page$type %in% PAGE_MIX_DATA))
            next 
        if(page$type == PAGE_MIX) {
            row_count_p <- row_count_fp
            base <- 24 + page$subh_count * 12
            base <- base + base %% 8
        } else {
            row_count_p <- read_int(page$data, 18, 4)
            base <- 24
        }
        if(row_count_p > row_count)
            row_count_p <- row_count
        for(row in (row+1):(row+row_count_p)) {
            for(col in col_info) {
                off <- base + col$offset
                if(col$length > 0) {
                    raw <- read_raw(page$data, off, col$length)
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

    if(row != row_count)
        warning(paste("found", row, "records where", row_count,
            "expected", BUGREPORT))

    if(close_con)
        close(con)

    data <- as.data.frame(data)
    attr(data, 'column.info') <- col_info
    attr(data, 'timestamp')   <- timestamp
    attr(data, 'SAS.release') <- SAS_release
    attr(data, 'SAS.host')    <- SAS_host
    return(data)
}
