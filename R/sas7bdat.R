#    Copyright (C) 2014 Matt Shotwell, VUMC
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

# Download all files listed in sas7bdat.sources
# path - where to save files
# max.size - limit on the size of downloaded files (bytes)
download.sas7bdat.sources <-
  function(ss, path=normalizePath("."), max.size=2^20) {
    # don't download zip files or files larger than max.size
    ss <- subset(ss, !grepl(".zip$", ss$url) & ss$uncompressed < max.size)
    if(!file.exists(path))
        dir.create(path)
    apply(ss, 1, function(r)
      download.file(r["url"], file.path(path, r["filename"])))
}

# Compress a file on disk
# desc - file path
# type - compression type ("gzip", "bzip2", "xz")
file.compress <- function(desc, type = "gzip") {
    if(type == "gzip") {
        ext <- ".gz"; cfile <- gzfile
    } else if(type == "bzip2") {
        ext <- ".bz2"; cfile <- bzfile
    } else if(type == "xz") {
        ext <- ".xz"; cfile <- xzfile
    } else {
        stop("compression 'type' unrecognized")
    }
    inp <- file(desc, open="rb")
    oup <- cfile(paste(desc, ext, sep=""), open="wb")
    while(length(dat <- readBin(inp, "raw", 2^13)) > 0)
        writeBin(dat, oup)
    close(inp)
    close(oup)
    return(paste(desc, ext, sep=""))
}

# Generate an entry for sas7bdat.sources
# fn - a local file name
# url - url of the file
generate.sas7bdat.source <- function(fn, url) {
    dl <- try(download.file(url, fn))
    if(inherits(dl, "try-error") || dl != 0)
        return(FALSE)
    sz <- file.info(fn)$size
    cat("gzip compress...")
    fn.gz <- file.compress(fn, "gzip")
    sz.gz <- file.info(fn.gz)$size
    cat("done\nbzip2 compress...")
    fn.bz2 <- file.compress(fn, "bzip2")
    sz.bz2 <- file.info(fn.bz2)$size
    cat("done\nxz compress...")
    fn.xz <- file.compress(fn, "xz")
    sz.xz <- file.info(fn.xz)$size
    cat("done\nparsing file...")
    dat <- try(read.sas7bdat(fn))
    cat("done\n")
    if(!inherits(dat, "try-error")) {
        # the two date variables below are not used 
        as.character(attr(dat, 'date.created')) -> datecreated 
        as.character(attr(dat, 'date.modified')) -> datemodified
        attr(dat, 'SAS.release') -> SAS_release
        attr(dat, 'SAS.host')    -> SAS_host
        attr(dat, 'OS.version')  -> OS_version
        attr(dat, 'OS.maker')    -> OS_maker
        attr(dat, 'OS.name')     -> OS_name
        attr(dat, 'endian')      -> endian
        attr(dat, 'winunix')     -> winunix
        dat <- "OK"
    } else {
        datecreated  <- ""
        datemodified <- ""
        SAS_release  <- ""
        SAS_host     <- ""
        OS_version   <- ""
        OS_maker     <- ""
        OS_name      <- ""
        endian       <- ""
        winunix      <- ""
        dat <- dat[1]
    }
    data.frame(
        filename = fn, accessed = Sys.time(), uncompressed = sz,
        gzip = sz.gz, bzip2 = sz.bz2, xz = sz.xz, url = url,
        PKGversion = VERSION, message = dat, SASrelease = SAS_release,
        SAShost = SAS_host, OSversion = OS_version, OSmaker = OS_maker,
        OSname = OS_name, endian = endian, winunix = winunix,
        stringsAsFactors=FALSE)
}

update.sas7bdat.source <- function(df) {
    re <- generate.sas7bdat.source(df$filename, df$url)
    if(inherits(re, "logical")) return(df)
    return(re)
}


# Update sas7bdat.sources
update.sas7bdat.sources <- function(ss) {
    for(i in 1:nrow(ss))
        ss[i,] <- update.sas7bdat.source(ss[i,])
    return(ss)
}
    
VERSION   <- "0.5"
BUGREPORT <- "please report bugs to maintainer"
CAUTION   <- "please verify data correctness"

# Host systems known to work
KNOWNHOST <- c("WIN_PRO", "WIN_NT", "WIN_NTSV", "WIN_SRV",
               "WIN_ASRV", "XP_PRO", "XP_HOME", "NET_ASRV",
               "NET_DSRV", "NET_SRV", "WIN_98", "W32_VSPR",
               "WIN", "WIN_95", "X64_VSPR", "X64_ESRV",
               "W32_ESRV", "W32_7PRO", "W32_VSHO", "X64_7HOM",
               "X64_7PRO", "X64_SRV0", "W32_SRV0", "X64_ES08",
               "Linux")

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
PAGE_DATA <- 256        #1<<8
PAGE_MIX  <- c(512,640) #1<<9,1<<9|1<<7
PAGE_AMD  <- 1024       #1<<10
PAGE_METC <- 16384      #1<<14 (compressed data)
PAGE_COMP <- -28672     #~(1<<14|1<<13|1<<12) 
PAGE_MIX_DATA <- c(PAGE_MIX, PAGE_DATA)
PAGE_META_MIX_AMD <- c(PAGE_META, PAGE_MIX, PAGE_AMD)
PAGE_ANY  <- c(PAGE_META_MIX_AMD, PAGE_DATA, PAGE_METC, PAGE_COMP)

page_type_strng <- function(type) {
    if(type %in% PAGE_META)
        return('meta')
    if(type %in% PAGE_DATA)
        return('data')
    if(type %in% PAGE_MIX)
        return('mix')
    if(type %in% PAGE_AMD)
        return('amd')
    return('unknown')
}

read_subheaders <- function(page, u64) {
    subhs <- list()
    subh_total <- 0
    if(!(page$type %in% PAGE_META_MIX_AMD))
        return(subhs)
    # page offset of subheader pointers
    oshp <- if(u64) 40 else 24
    # length of subheader pointers
    lshp <- if(u64) 24 else 12
    # length of first two subheader fields
    lshf <- if(u64) 8  else 4
    for(i in 1:page$subh_count) {
        subh_total <- subh_total + 1
        base <- oshp + (i - 1) * lshp
        subhs[[subh_total]] <- list()
        subhs[[subh_total]]$page <- page$page 
        subhs[[subh_total]]$offset <- read_int(page$data, base, lshf)
        subhs[[subh_total]]$length <- read_int(page$data, base + lshf, lshf)
        if(subhs[[subh_total]]$length > 0) {
            subhs[[subh_total]]$raw <- read_raw(page$data, 
                subhs[[subh_total]]$offset, subhs[[subh_total]]$length)
            subhs[[subh_total]]$signature <- read_raw(subhs[[subh_total]]$raw, 0, 4)
        }
    }
    return(subhs)
}

read_column_names <- function(col_name, col_text, u64) {
    names <- list()
    name_count <- 0
    offp <- if(u64) 8 else 4
    for(subh in col_name) {
        cmax <- (subh$length - if(u64) 28 else 20)/8
        for(i in 1:cmax) {
            name_count <- name_count + 1
            names[[name_count]] <- list()
            base <- (if(u64) 16 else 12) + (i-1) * 8
            hdr  <- read_int(subh$raw, base, 2)
            off  <- read_int(subh$raw, base + 2, 2)
            len  <- read_int(subh$raw, base + 4, 2)
            names[[name_count]]$name <- read_str(col_text[[hdr+1]]$raw,
                                                 off + offp, len)
        }
    }
    return(names)
}

read_column_labels_formats <- function(col_labs, col_text, u64) {
    if(length(col_labs) < 1)
        return(NULL)
    offp <- if(u64) 8  else 4
    labs <- list()
    for(i in 1:length(col_labs)) {
        labs[[i]] <- list()
        base <- if(u64) 46 else 34
        hdr  <- read_int(col_labs[[i]]$raw, base, 2)
        off  <- read_int(col_labs[[i]]$raw, base + 2, 2)
        len  <- read_int(col_labs[[i]]$raw, base + 4, 2)
        if(len > 0)
            labs[[i]]$format <- read_str(col_text[[hdr+1]]$raw,
                                         off + offp, len)
        labs[[i]]$fhdr <- hdr;
        labs[[i]]$foff <- off
        labs[[i]]$flen <- len
        base <- if(u64) 52 else 40
        hdr  <- read_int(col_labs[[i]]$raw, base, 2)
        off  <- read_int(col_labs[[i]]$raw, base + 2, 2)
        len  <- read_int(col_labs[[i]]$raw, base + 4, 2)
        if(len > 0)
            labs[[i]]$label <- read_str(col_text[[hdr+1]]$raw,
                                        off + offp, len)
        labs[[i]]$lhdr <- hdr;
        labs[[i]]$loff <- off
        labs[[i]]$llen <- len
    }
    return(labs)
}
 
read_column_attributes <- function(col_attr, u64) {
    info <- list()
    info_ct <- 0
    lcav <- if(u64) 16 else 12
    for(subh in col_attr) {
        cmax <- (subh$length - if(u64) 28 else 20)/lcav
        for(i in 1:cmax) {
            info_ct <- info_ct + 1
            info[[info_ct]] <- list()
            base <- lcav + (i-1) * lcav
            info[[info_ct]]$offset <- read_int(subh$raw, base,
                                               if(u64) 8 else 4)
            info[[info_ct]]$length <- read_int(subh$raw,
                                               base + if(u64) 8 else 4,
                                               4)
            info[[info_ct]]$type   <- read_int(subh$raw,
                                               base + if(u64) 14 else 10,
                                               1)
            info[[info_ct]]$type   <- ifelse(info[[info_ct]]$type == 1,
                                             "numeric", "character")
        }
    }
    return(info)
}

# Magic number
MAGIC     <- as.raw(c(0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                      0x0, 0x0, 0x0, 0x0, 0xc2,0xea,0x81,0x60,
                      0xb3,0x14,0x11,0xcf,0xbd,0x92,0x8, 0x0,
                      0x9, 0xc7,0x31,0x8c,0x18,0x1f,0x10,0x11))

check_magic_number <- function(data)
    identical(data[1:length(MAGIC)], MAGIC)

# These functions utilize offset + length addressing
read_bin <- function(buf, off, len, type, ...)
    readBin(buf[(off+1):(off+len)], type, 1, len, ...)
read_raw <- function(buf, off, len, ...)
    readBin(buf[(off+1):(off+len)], "raw", len, 1, ...)
read_int <- function(buf, off, len, ...)
    read_bin(buf, off, len, "integer", ...)
read_str <- function(buf, off, len, ...)
    read_bin(buf, off, len, "character", ...)
read_flo <- function(buf, off, len, ...)
    read_bin(buf, off, len, "double", ...)

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

read.sas7bdat <- function(file, debug=FALSE) {
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
    header <- readBin(con, "raw", 288, 1)
    if(length(header) < 288)
        stop("header too short (not a sas7bdat file?)")
    if(!check_magic_number(header))
        stop(paste("magic number mismatch", BUGREPORT))

    # Check for 32 or 64 bit alignment
    align1 <- read_raw(header, 32, 1)
    if(identical(align1, as.raw(0x33))) {
        align1 <- 4
    } else {
        align1 <- 0
    }

    # If align1 == 4, file is u64 type
    if(align1 == 4) {
        u64 <- TRUE
    } else {
        u64 <- FALSE
    }

    align2 <- read_raw(header, 35, 1)
    if(identical(align2, as.raw(0x33))) {
        align2 <- 4
    } else {
        align2 <- 0
    }

    endian <- read_raw(header, 37, 1)
    if(identical(endian, as.raw(0x01))) {
        endian <- "little"
    } else {
        endian <- "big"
        stop("big endian files are not supported")
    }

    winunix <- read_str(header, 39, 1)
    if(identical(winunix, "1")) {
        winunix <- "unix"
    } else if(identical(winunix, "2")) {
        winunix <- "windows"
    } else {
        winunix <- "unknown"
    }   

    # Timestamp is epoch 01/01/1960
    datecreated <- read_flo(header, 164+align1, 8)
    datecreated <- datecreated + as.POSIXct("1960/01/01", format="%Y/%m/%d")
    datemodified <- read_flo(header, 172+align1, 8)
    datemodified <- datemodified + as.POSIXct("1960/01/01", format="%Y/%m/%d")
    
    # Read the remaining header
    header_length <- read_int(header, 196 + align2, 4)
    header <- c(header, readBin(con, "raw", header_length-288, 1))
    if(length(header) < header_length)
        stop("header too short (not a sas7bdat file?)")

    page_size   <- read_int(header, 200 + align2, 4)
    if(page_size < 0)
        stop(paste("page size is negative", BUGREPORT))

    page_count  <- read_int(header, 204 + align2, 4)
    if(page_count < 1)
        stop(paste("page count is not positive", BUGREPORT))
    

    SAS_release <- read_str(header, 216 + align1 + align2, 8)

    # SAS_host is a 16 byte field, but only the first eight are used
    # FIXME: It would be preferable to eliminate this check
    SAS_host    <- read_str(header, 224 + align1 + align2, 8)
    #if(!(SAS_host %in% KNOWNHOST))
    #    stop(paste("unknown host", SAS_host, BUGREPORT))

    OS_version  <- read_str(header, 240 + align1 + align2, 16) 
    OS_maker    <- read_str(header, 256 + align1 + align2, 16) 
    OS_name     <- read_str(header, 272 + align1 + align2, 16) 

    # Read pages
    pages <- list()
    for(page_num in 1:page_count) {
        pages[[page_num]] <- list()
        pages[[page_num]]$page <- page_num
        pages[[page_num]]$data <- readBin(con, "raw", page_size, 1)
        pages[[page_num]]$type <- read_int(pages[[page_num]]$data, if(u64) 32 else 16, 2)
        pages[[page_num]]$type_strng <- page_type_strng(pages[[page_num]]$type)
        pages[[page_num]]$blck_count <- read_int(pages[[page_num]]$data, if(u64) 34 else 18, 2) 
        pages[[page_num]]$subh_count <- read_int(pages[[page_num]]$data, if(u64) 36 else 20, 2)
    }

    # Read all subheaders
    subhs <- list()
    for(page in pages)
        subhs <- c(subhs, read_subheaders(page, u64)) 

    # Parse row size subheader
    row_size <- get_subhs(subhs, SUBH_ROWSIZE)
    if(length(row_size) != 1)
        stop(paste("found", length(row_size),
            "row size subheaders where 1 expected", BUGREPORT))
    row_size <- row_size[[1]]
    row_length   <- read_int(row_size$raw,
                             if(u64) 40 else 20,
                             if(u64) 8  else 4)
    row_count    <- read_int(row_size$raw,
                             if(u64) 48 else 24,
                             if(u64) 8  else 4)
    col_count_p1 <- read_int(row_size$raw,
                             if(u64) 72 else 36,
                             if(u64) 8  else 4)
    col_count_p2 <- read_int(row_size$raw,
                             if(u64) 80 else 40,
                             if(u64) 8  else 4)
    row_count_fp <- read_int(row_size$raw,
                             if(u64) 120 else 60,
                             if(u64) 8   else 4)

    # Parse col size subheader
    col_size <- get_subhs(subhs, SUBH_COLSIZE)
    if(length(col_size) != 1)
        stop(paste("found", length(col_size),
            "column size subheaders where 1 expected", BUGREPORT))
    col_size <- col_size[[1]]
    col_count_6  <- read_int(col_size$raw,
                             if(u64) 8 else 4,
                             if(u64) 8 else 4)
    col_count    <- col_count_6

    #if((col_count_p1 + col_count_p2) != col_count_6)
    #    warning(paste("column count mismatch" , CAUTION))

    # Read column information
    col_text <- get_subhs(subhs, SUBH_COLTEXT)
    if(length(col_text) < 1)
        stop(paste("no column text subheaders found", BUGREPORT))

    # Test for COMPRESS=CHAR compression
    # This test is done earlier at the page level
    #if("SASYZCRL" == read_str(col_text[[1]]$raw, 16, 8))
    #    stop(paste("file uses unsupported CHAR compression"))

    col_attr <- get_subhs(subhs, SUBH_COLATTR)            
    if(length(col_attr) < 1)
        stop(paste("no column attribute subheaders found", BUGREPORT))

    col_attr <- read_column_attributes(col_attr, u64)
    if(length(col_attr) != col_count)
        stop(paste("found", length(col_attr), 
            "column attributes where", col_count,
            "expected", BUGREPORT))

    col_name <- get_subhs(subhs, SUBH_COLNAME)
    if(length(col_name) < 1)
        stop(paste("no column name subheaders found", BUGREPORT))

    col_name <- read_column_names(col_name, col_text, u64)
    if(length(col_name) != col_count)
        stop(paste("found", length(col_name), 
            "column names where", col_count, "expected", BUGREPORT))

    # Make column names unique, if not already
    col_name_uni <- make.unique(sapply(col_name, function(x)x$name)) 
    for(i in 1:length(col_name_uni))
        col_name[[i]]$name <- col_name_uni[i]

    col_labs <- get_subhs(subhs, SUBH_COLLABS)
    col_labs <- read_column_labels_formats(col_labs, col_text, u64)
    if(is.null(col_labs))
        col_labs <- list(length=col_count)
    if(length(col_labs) != col_count)
        stop(paste("found", length(col_labs), 
            "column formats and labels", col_count, "expected", BUGREPORT))

    # Collate column information
    col_info <- list()
    for(i in 1:col_count)
        col_info[[i]] <- c(col_name[[i]], col_attr[[i]], col_labs[[i]]) 

    # Check pages for known type 
    for(page_num in 1:page_count) {
        if(!(pages[[page_num]]$type %in% PAGE_ANY))
            stop(paste("page", page_num, "has unknown type:",
                pages[[page_num]]$type, BUGREPORT))
        if(pages[[page_num]]$type %in% c(PAGE_METC, PAGE_COMP))
            stop("file contains compressed data")
    }
        
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
        base <- (if(u64) 32 else 16) + 8
        if(page$type %in% PAGE_MIX) {
            row_count_p <- row_count_fp
            # skip subheader pointers
            base <- base + page$subh_count * if(u64) 24 else 12
            base <- base + base %% 8
        } else {
            row_count_p <- read_int(page$data, if(u64) 34 else 18, 2)
        }
        # round up to 8-byte boundary	
        base <- ((base+7) %/% 8) * 8 + base %% 8
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
    attr(data, 'pkg.version')   <- VERSION
    attr(data, 'column.info')   <- col_info
    attr(data, 'date.created')  <- datecreated
    attr(data, 'date.modified') <- datemodified
    attr(data, 'SAS.release')   <- SAS_release
    attr(data, 'SAS.host')      <- SAS_host
    attr(data, 'OS.version')    <- OS_version
    attr(data, 'OS.maker')      <- OS_maker
    attr(data, 'OS.name')       <- OS_name
    attr(data, 'endian')        <- endian
    attr(data, 'winunix')       <- winunix
    if(debug)
        attr(data, 'debug')     <- sys.frame(1)
    return(data)
}
