setGeneric("put.adf.file", function(x, source, destination, date, comment) standardGeneric("put.adf.file"))

#' Put a file onto an amigaDisk object
#'
#' Put a file onto a virtual Amiga floppy disk represented by
#' an [`amigaDisk`] object.
#'
#' Put a file or raw data from your local system onto a virtual
#' Amiga floppy disk represented by an [`amigaDisk`]
#' object. Make sure that the virtual disk is DOS formatted.
#' This method can only put one file at a time onto the virtual
#' virtual disk. It is therefore not allowed to use wild cards
#' in the source or destination names. Use loops to add multiple
#' files onto a virtual disk.
#'
#' @docType methods
#' @name put.adf.file
#' @rdname put.adf.file
#' @aliases put.adf.file,amigaDisk,raw,character,POSIXt,character-method
#' @param x An [`amigaDisk`] onto which the file should be put.
#' @param source Either a `character` string of the source
#' file's path; or a `vector` of `raw` data that
#' should be written to the destination file. Wildcards are not allowed (see details)
#' @param destination A `character` string of the destination
#' path on the virtual floppy disk where the source file should be put. The
#' path should be conform Amiga specs (see [`current.adf.dir`]). When
#' the destination is missing or only specifies a directory, the file will be put
#' into the current directory ([`current.adf.dir`]) or specified path of
#' `x` respectively. In that case, the same file name as that
#' of the source file is used. Wild cards are not allowed (see details).
#' @param date A [`POSIXt`][base::DateTimeClasses] object that will be used as the
#' file modification date. When missing the system time will used.
#' @param comment An optional `character` string that will be included
#' in the file header as a comment. Should not be longer than 79 characters.
#' @return Returns an [`amigaDisk`] object onto which the
#' source file is put at the specified destination.
#' @examples
#' \dontrun{
#' ## create a blank disk to put files onto:
#' blank.disk <- blank.amigaDOSDisk("blank", "DD", "OFS", TRUE, FALSE, FALSE)
#' 
#' ## let's copy the base package 'INDEX' file onto the
#' ## virtual disk:
#' blank.disk <- put.adf.file(blank.disk, system.file("INDEX"))
#' 
#' ## We can also put raw data onto the virtual disk:
#' blank.disk <- put.adf.file(blank.disk, raw(2048), "DF0:null.dat")
#' 
#' ## check whether we succeeded:
#' list.adf.files(blank.disk)
#' }
#' @author Pepijn de Vries
#' @export
setMethod("put.adf.file", c("amigaDisk", "raw", "character", "POSIXt", "character"), function(x, source, destination, date, comment) {
  .put.file(x, source, destination, "ST_FILE", date, comment)
})

#' @name put.adf.file
#' @rdname put.adf.file
#' @aliases put.adf.file,amigaDisk,raw,character,POSIXt,missing-method
#' @export
setMethod("put.adf.file", c("amigaDisk", "raw", "character", "POSIXt", "missing"), function(x, source, destination, date, comment) {
  .put.file(x, source, destination, "ST_FILE", date)
})

#' @name put.adf.file
#' @rdname put.adf.file
#' @aliases put.adf.file,amigaDisk,raw,character,missing,missing-method
#' @export
setMethod("put.adf.file", c("amigaDisk", "raw", "character", "missing", "missing"), function(x, source, destination, date, comment) {
  .put.file(x, source, destination, "ST_FILE")
})

#' @name put.adf.file
#' @rdname put.adf.file
#' @aliases put.adf.file,amigaDisk,character,character,POSIXt,character-method
#' @export
setMethod("put.adf.file", c("amigaDisk", "character", "character", "POSIXt", "character"), function(x, source, destination, date, comment) {
  .put.file(x, source, destination, "ST_FILE", date, comment)
})

#' @name put.adf.file
#' @rdname put.adf.file
#' @aliases put.adf.file,amigaDisk,character,character,POSIXt,missing-method
#' @export
setMethod("put.adf.file", c("amigaDisk", "character", "character", "POSIXt", "missing"), function(x, source, destination, date, comment) {
  .put.file(x, source, destination, "ST_FILE", date)
})

#' @name put.adf.file
#' @rdname put.adf.file
#' @aliases put.adf.file,amigaDisk,character,character,missing,missing-method
#' @export
setMethod("put.adf.file", c("amigaDisk", "character", "character", "missing", "missing"), function(x, source, destination, date, comment) {
  .put.file(x, source, destination, "ST_FILE")
})

#' @name put.adf.file
#' @rdname put.adf.file
#' @aliases put.adf.file,amigaDisk,character,missing,missing,missing-method
#' @export
setMethod("put.adf.file", c("amigaDisk", "character", "missing", "missing", "missing"), function(x, source, destination, date, comment) {
  .put.file(x, source, type = "ST_FILE")
})

.put.file <- function(x, source, destination, type = "ST_FILE", date = Sys.time(), comment = "") {
  NUMBER_OF_SECTORS <- ifelse(x@type == "DD", NUMBER_OF_SECTORS_DD, NUMBER_OF_SECTORS_HD)
  if (missing(destination)) {
    ## use file name from source when destination is missing
    destination <- basename(source)
  }
  if (adf.file.exists(x, destination) && inherits(source, "character")) {
    if (substr(destination, nchar(destination), nchar(destination)) != "/")
      destination <- paste0(destination, "/")
    destination <- paste0(destination, basename(source))
  }
  if (adf.file.exists(x, destination)) {
    stop("File already exists! Remove it first before putting a file with the same name there.")
  }
  
  if (type == "ST_USERDIR") source <- raw(0)
  if (inherits(source, "character")) {
    con <- file(source, "rb")
    temp <- readBin(con, "raw", (NUMBER_OF_SIDES*NUMBER_OF_CYLINDERS*NUMBER_OF_SECTORS - 3)*BLOCK_SIZE)
    test.byte <- readBin(con, "raw", 1)
    close(con)
    if (length(test.byte) > 0) stop ("Not enough space on virtual disk for source file.")
    source <- temp
    rm(temp, test.byte)
  }
  date <- as.POSIXct(date)
  ## hash table size
  ht_length  <- BLOCK_SIZE/4 - 56
  ## file size:
  fsize <- length(source)
  
  dest.split <- strsplit(destination[[1]], "[/]|[:]")[[1]]
  dest.base <- substr(destination, 0, nchar(destination) - nchar(dest.split[[length(dest.split)]]))
  destination <- dest.split[[length(dest.split)]]
  if (nchar(destination) > 30 || nchar(destination) == 0) stop("Destination filename should be between 1 and 30 characters long.")
  ## TODO Comment in cache block can only be 22 characters long...
  if (nchar(comment) > 79) stop("Comment cannot be longer than 79 characters.")
  
  ## get the pointer to the base directory
  ## for the destination file
  if (nchar(dest.base) == 0) {
    cur.dir <- x@current.dir
  } else {
    cur.dir <- find.file.header(x, dest.base)
  }
  
  bi <- boot.info(x)
  hi <- header.info(x, cur.dir)[[1]]
  ri <- root.info(x)
  ######################################################
  ##  1: ALLOCATE FREE BLOCKS
  ######################################################
  
  ## required number of data blocks
  ndata <- ceiling(fsize/BLOCK_SIZE)
  ## If the disk uses the Old File System, data blocks hold 24 bytes less data:
  if (!bi$flag$fast.file.system) ndata <- ceiling(fsize/(BLOCK_SIZE - 24))
  
  ## a header / extension block is needed for every ht_length data blocks
  nheader <- ceiling(ndata / ht_length)
  ## But also for an empty file, a header is required:
  nheader[nheader == 0] <- 1

  extra.dc.blocks <- -1
  ## check if the disk uses directory cache mode and if
  ## the directory cache block can hold the file info
  ## or whether a new block needs to be reserved.
  if (bi$flag$dir.cache.mode) {
    record.required.length <- 25 + nchar(destination) + nchar(comment)
    record.required.length <- 2*ceiling(record.required.length/2)
    dc <- dir.cache.info(x, cur.dir)
    current.dc.blocks <- attributes(dc)$dc.blocks
    dc <- lapply(dc, function(rec) {
      rec$protect[1:4] <- !rec$protect[1:4]
      rec$protect <- rawToAmigaInt(bitmapToRaw(rec$protect, T, T), 32, F)
      as.data.frame(rec)
    })
    dc <- do.call(rbind, dc)

    ## if the dc is empty (NULL) then we don't need to create additional dc blocks
    if (!is.null(dc)) {
      rec.length <- cumsum(with(dc, 25 + as.numeric(as.character(name_len)) +
                                  as.numeric(as.character(comment_len))))
      rec.length <- c(rec.length, rec.length[[length(rec.length)]] +
                        record.required.length)
      while (any(rec.length > (BLOCK_SIZE - 24))) {
        rec.length[rec.length > (BLOCK_SIZE - 24)] <-
          rec.length[rec.length > (BLOCK_SIZE - 24)] -
          rec.length[which(rec.length > (BLOCK_SIZE - 24))[[1]] - 1]
      }
      ## records in table that should start in a new block
      tab.start.new <- which(diff(c(BLOCK_SIZE, rec.length)) < 0)
      extra.dc.blocks <- length(tab.start.new) - length(current.dc.blocks)
      if (extra.dc.blocks < 0) {
        ## clear the blocks that are no longer necessary
        x <- clear.amigaBlock(x, current.dc.blocks[(1 + length(current.dc.blocks) + extra.dc.blocks):length(current.dc.blocks)])
        current.dc.blocks <- current.dc.blocks[1:(length(current.dc.blocks) + extra.dc.blocks)]
        extra.dc.blocks <- 0
      }
    } else {
      extra.dc.blocks <- 0
    }
  }

  nblocks <- ndata + nheader
  ndircache <- 0
  if (extra.dc.blocks > -1){
    nblocks <- nblocks + extra.dc.blocks
    ndircache <- extra.dc.blocks
  }

  n.sub.dc <- 0
  if (type == "ST_USERDIR" && bi$flag$dir.cache.mode) {
    n.sub.dc <- 1
    nblocks <- nblocks + 1
  }

  allocated.blocks <- NULL
  try(allocated.blocks <- allocate.amigaBlock(x, nblocks), T)
  if (is.null(allocated.blocks)) stop("Not enough space on virtual disk for source file.")
  
  new.dir.cache <- numeric(0)
  if (extra.dc.blocks > 0) new.dir.cache <- allocated.blocks[1:extra.dc.blocks]
  
  if (bi$flag$fast.file.system) {
    header.blocks <- allocated.blocks[ndircache + 1]
    if (nheader > 1) {
      ## max. 3 extension blocks after each other (so it seems)
      sep <- (((2:nheader) - 2) %% 3) +
        (ht_length + 1)*3*floor(((2:nheader) - 2) / 3)
      header.blocks <- c(header.blocks, allocated.blocks[ndircache + ht_length + sep + 2])
    }
  } else {
    header.blocks <- allocated.blocks[ndircache + (ht_length + 1)*((1:nheader) - 1) + 1]
  }
  if (ndata == 0) {
    data.blocks <- numeric(0)
  } else {
    data.blocks   <- allocated.blocks[!(allocated.blocks %in% c(header.blocks, new.dir.cache))]
  }

  if (type == "ST_USERDIR" && bi$flag$dir.cache.mode) sub.dc.block <- allocated.blocks[nheader + 1]
  
  ######################################################
  ##  2: ADD FILE TO DESTINATION HASHTABLE
  ######################################################

  hash.value <- hash.name(destination, bi$flag$intl.mode || bi$flag$dir.cache.mode)
  
  hashchain <- hi$datablocks[[hash.value + 1]]
  
  protect.count <- 0
  while (hashchain[[length(hashchain)]] > 0) {
    hashchain <- c(hashchain, header.info(x, hashchain[[length(hashchain)]])[[1]]$hash_chain)
    protect.count <- protect.count + 1
    if (protect.count > NUMBER_OF_SECTORS*NUMBER_OF_CYLINDERS*NUMBER_OF_SIDES) {
      stop("Hash chain is unrealistically long.")
      break
    }
  }
  ## Hash chain should be sorted by block id...
  hashchain <- c(sort(c(hashchain[hashchain != 0], header.blocks[[1]])), 0)
  x@data[cur.dir*BLOCK_SIZE + 25:28 + hash.value*4] <- amigaIntToRaw(hashchain[[1]], 32)
  x@data[cur.dir*BLOCK_SIZE + 21:24] <- calculate.checksum(x@data[cur.dir*BLOCK_SIZE + 1:BLOCK_SIZE])

  if (length(hashchain) > 2){
    ## set new hash values
    x@data[as.vector(outer(-15:-12, (hashchain[-length(hashchain)] + 1)*BLOCK_SIZE, "+"))] <-
      amigaIntToRaw(hashchain[-1], 32)
    ## calculate and update checksums for each file header in the hash chain
    for (i in hashchain[-length(hashchain)]) {
      x@data[i*BLOCK_SIZE + 21:24] <- calculate.checksum(x@data[i*BLOCK_SIZE + 1:BLOCK_SIZE])
    }
  }
  
  ######################################################
  ##  3: CREATE FILE HEADER(S)
  ######################################################

  file.headers <- lapply(1:nheader, function(y) {
    db <- data.blocks[(y - 1)*ht_length + 1:ht_length]
    db[is.na(db)] <- 0
    db <- rev(db)
    fname <- charToRaw(destination)
    fname <- rawToAmigaInt(c(as.raw(nchar(destination)), fname[1:30], raw(1)), 32)
    extension <- ifelse(type == "ST_USERDIR" && bi$flag$dir.cache.mode, sub.dc.block, 0)
    if (nheader > y) extension <- header.blocks[y + 1]
    if (y == 1) {
      fh <- c(TYPES$value[TYPES$type == "T_HEADER"], # primary block type
              header.blocks[[y]],                    # self pointer
              sum(db != 0),                          # high seq
              0,                                     # data size (not used)
              db[[length(db)]],                      # first_data
              0,                                     # checksum, calculate later
              db,                                    # data block pointers
              rep(0, 3),                             # unused, UID, GID, protection flags
              fsize,                                 # byte size
              rep(0, 23),                            # comm_len, com, unused
              rawToAmigaInt(amigaDateToRaw(date, tz = "UTC"), 32), # change date
              fname,                                 # file name length, file name and unused
              0,                                     # unused
              0,                                     # real_entry (FFS unused)
              0,                                     # next_link (unused)
              rep(0, 5),                             # unused
              0,                                     # next hash (zero as it is put at the end of the hash chain)
              cur.dir,                               # same as parent directory of current dir
              extension,                             # next extension block
              SEC_TYPES$value[SEC_TYPES$type == type]
      )
    } else {
      fh <- c(TYPES$value[TYPES$type == "T_LIST"],   # primary block type (Extension)
              header.blocks[[y]],                    # self pointer
              sum(db != 0),                          # high seq
              0,                                     # data size (not used)
              0,                                     # Not used in extension
              0,                                     # checksum, calculate later
              db,                                    # data block pointers
              rep(0, 47),                            # unused
              header.blocks[[1]],                    # file header
              extension,                             # next extension block
              SEC_TYPES$value[SEC_TYPES$type == type]
      )
    }
    fh <- amigaIntToRaw(fh, 32)
    fh[21:24] <- calculate.checksum(fh)
    ## put the header block in the disk object:
    x@data[header.blocks[[y]]*BLOCK_SIZE + 1:BLOCK_SIZE] <<- fh
  })

  ######################################################
  ##  3A: IF THE WE PUT A DIRECTORY ON THE DISK CREATE A NEW DIR CACHE IF REQUIRED
  ######################################################
  
  if (type == "ST_USERDIR" && bi$flag$dir.cache.mode) {
    sub.dc <- .make.dir.cache.block(data.frame(), cur.dir, sub.dc.block)[[1]]
    x@data[sub.dc.block*BLOCK_SIZE + 1:BLOCK_SIZE] <- sub.dc
  }
  
  ######################################################
  ##  4: ADD DATA BLOCKS
  ######################################################
  
  if (ndata > 0) {
    data.idx <- lapply(1:ndata, function(y) {
      if (bi$flag$fast.file.system) {
        idx <- (y - 1)*BLOCK_SIZE + 1:BLOCK_SIZE
      } else {
        idx <- (y - 1)*(BLOCK_SIZE - 24) + 1:(BLOCK_SIZE - 24)
      }
      if (bi$flag$fast.file.system) {
        rep.range <- 1:BLOCK_SIZE
        if (length(idx) < length(25:BLOCK_SIZE)){
          rep.range <- 1:length(idx)
          x@data[data.blocks[[y]]*BLOCK_SIZE + 1:BLOCK_SIZE] <- raw(1)
        }
        x@data[data.blocks[[y]]*BLOCK_SIZE + rep.range] <<- source[idx]
      } else {
        ## Write OFS stuff to first 24 bytes...
        temp <- (1:fsize)[idx]
        nextblock <- 0
        if (y < ndata) nextblock <- data.blocks[[y + 1]]
        data_head <- c(
          TYPES$value[TYPES$type == "T_DATA"],  ## block primary type
          header.blocks[[1]],                   ## self pointer
          y,                                    ## seq_num
          sum(!is.na(temp)),                    ## data_size
          nextblock,
          0                                     ## checksum, caculate below
        )
        x@data[data.blocks[[y]]*BLOCK_SIZE + 1:24] <<- amigaIntToRaw(data_head, 32)
        rep.range <- 25:BLOCK_SIZE
        if (length(idx) < length(25:BLOCK_SIZE)){
          rep.range <- 25:(24 + length(idx))
          x@data[data.blocks[[y]]*BLOCK_SIZE + 25:BLOCK_SIZE] <- raw(1)
        }
        x@data[data.blocks[[y]]*BLOCK_SIZE + rep.range] <<- source[idx]
        x@data[data.blocks[[y]]*BLOCK_SIZE + 21:24] <<- calculate.checksum(x@data[data.blocks[[y]]*BLOCK_SIZE + 1:BLOCK_SIZE])
      }
    })
  }
  
  ######################################################
  ##  5: UPDATE DIRECTORY CACHE BLOCK (IF AVAILABLE)
  ######################################################
  
  if (bi$flag$dir.cache.mode) {
    dc.blocks   <- c(current.dc.blocks, new.dir.cache)
    prot        <- 0L # TODO let user provide flags
    dc <- rbind(dc, data.frame(
      dir.cache   = dc.blocks[length(dc.blocks)],
      header      = header.blocks[[1]],
      size        = fsize,
      protect     = prot,
      UID         = 0,
      GID         = 0,
      date        = date,
      type        = type,
      name_len    = nchar(destination),
      name        = destination,
      comment_len = nchar(comment),
      comment     = comment
    ))
    dc.block <- .make.dir.cache.block(dc, cur.dir, dc.blocks)
    x@data[as.vector(outer(1:BLOCK_SIZE, dc.blocks*BLOCK_SIZE, "+"))] <-
      unlist(dc.block)
  }
  
  ######################################################
  ##  6: UPDATE BITMAP BLOCK
  ######################################################
  
  x <- reserve.amigaBlock(x, allocated.blocks)

  return(x)
}

.make.dir.cache.block <- function(records, dir.header.block, dir.cache.blocks){
  # Maybe code below can/should be made more efficient:
  if (nrow(records) > 0) {
    records$type    <- as.character(records$type)
    records$header  <- lapply(apply(matrix(amigaIntToRaw(records$header, 32), 4), 2, list), unlist)
    records$size    <- lapply(apply(matrix(amigaIntToRaw(records$size, 32), 4), 2, list), unlist)

    records$protect <- lapply(apply(matrix(amigaIntToRaw(records$protect, 32), 4), 2, list), unlist)
    records$UID     <- lapply(apply(matrix(amigaIntToRaw(records$UID, 16), 2), 2, list), unlist)
    records$GID     <- lapply(apply(matrix(amigaIntToRaw(records$GID, 16), 2), 2, list), unlist)
    records$date    <- lapply(apply(matrix(amigaDateToRaw(records$date, "short"), 6), 2, list), unlist)
    records$type <- lapply(1:nrow(records), function(x) {
      id  <- apply(outer(records$type, SEC_TYPES$type, "=="), 1, which)
      val <- SEC_TYPES$value[id]
      amigaIntToRaw(val, 32)[(x - 1)*4 + 4]
    })
    records$name_len    <- lapply(apply(matrix(amigaIntToRaw(records$name_len, 8), 1), 2, list), unlist)
    records$name <- lapply(1:nrow(records), function(x) {
      charToRaw(as.character(records$name[[x]]))
    })
    records$comment_len <- lapply(apply(matrix(amigaIntToRaw(records$comment_len, 8), 1), 2, list), unlist)
    records$comment <- lapply(1:nrow(records), function(x) {
      charToRaw(as.character(records$comment[[x]]))
    })
    records <- records[, names(records) != "dir.cache", drop = F]
    
    records <- apply(records, 1, unlist)

    if (inherits(records, "matrix")) records <- as.data.frame(records)
    records <- lapply(records, unlist)
    records <- lapply(records, function (x) if ((length(x) %% 2) == 1) c(x, raw(1)) else x)
    lengths <- lapply(records, length)
  } else {
    records <- list(raw(0))
    lengths <- list(0)
  }
  
  recs <- list()
  dirc <- TYPES$value[TYPES$type == "DIRCACHE"]
  i <- 1
  while (length(records) > 0) {
    sel <- cumsum(unlist(lengths)) <= (BLOCK_SIZE - 24)
    sum_sel <- ifelse(lengths[[1]] != 0, sum(sel), 0)
    next.dc <- ifelse(i < length(dir.cache.blocks), dir.cache.blocks[i + 1], 0)
    recs[[length(recs) + 1]] <- c(
      amigaIntToRaw(c(dirc, dir.cache.blocks[i], dir.header.block, sum_sel, next.dc, 0),
                    32),
      unlist(records[sel])
    )
    recs[[length(recs)]] <- c(
      recs[[length(recs)]],
      raw(BLOCK_SIZE - length(recs[[length(recs)]]))
    )
    recs[[length(recs)]][21:24] <- calculate.checksum(recs[[length(recs)]])
    records <- records[!sel]
    lengths <- lengths[!sel]
    i <- i + 1
  }
  return(recs)
}

setGeneric("adf.file.exists", function(x, file) standardGeneric("adf.file.exists"))

#' Test file or directory existence in an amigaDisk object
#'
#' Tests whether a specific file (or directory) exists in an
#' [`amigaDisk`] object.
#'
#' This method will look for a file/directory header, based on its name.
#' If such a header exists, it is assumed that the file exists. The
#' file/directory itself is not checked for validity.
#'
#' @docType methods
#' @name adf.file.exists
#' @rdname adf.exists
#' @aliases adf.file.exists,amigaDisk,character-method
#' @param x An [`amigaDisk`] object in which this method
#' will check for the file's existence.
#' @param file A (`vector` of) `character` string(s) representing a file or directory name.
#' Use Amiga specifications for file name (see [`current.adf.dir`]). Wildcards are not allowed.
#' @return Returns a `logical` value indicating whether the file exists
#' or not. In case of `dir.exists.adf` the path needs to exist and it needs to be a directory in order
#' to return `TRUE`.
#' @examples
#' data(adf.example)
#' 
#' ## This file exists:
#' adf.file.exists(adf.example, "df0:mods/mod.intro")
#' 
#' ## But it doesn't exist as a directory
#' dir.exists.adf(adf.example, "df0:mods/mod.intro")
#' 
#' ## This file also doesn't:
#' adf.file.exists(adf.example, "df0:idontexist")
#' @author Pepijn de Vries
#' @export
setMethod("adf.file.exists", c("amigaDisk", "character"), function(x, file){
  res <- F
  unlist(lapply(file, function(f) {
    try(res <- !is.null(find.file.header(x, f)), T)
    return(res)
  }))
})

setGeneric("dir.exists.adf", function(x, path) standardGeneric("dir.exists.adf"))

#' @param path file A (`vector` of) `character` string(s) representing a directory name.
#' Use Amiga specifications for the path name (see [`current.adf.dir`]). Wildcards are not allowed.
#' @name dir.exists.adf
#' @rdname adf.exists
#' @aliases dir.exists.adf,amigaDisk,character-method
#' @export
setMethod("dir.exists.adf", c("amigaDisk", "character"), function(x, path) {
  fh <- NULL
  unlist(lapply(path, function(p) {
    try(fh <- find.file.header(x, p), T)
    if (is.null(fh)) {
      return(F)
    } else {
      res <- F
      try(res <- header.info(x, fh)[[1]]$sec_type == "ST_USERDIR", T)
      return(res)
    }
  }))
})

setGeneric("dir.create.adf", function(x, path, date, comment) standardGeneric("dir.create.adf"))

#' Create a directory on an amigaDisk object
#'
#' Create a directory on a virtual Amiga floppy disk represented by
#' an [`amigaDisk`] object.
#'
#' Create a directory on a virtual Amiga floppy disk represented by
#' an [`amigaDisk`] object. Make sure that the virtual disk
#' is DOS formatted.
#'
#' @docType methods
#' @name dir.create.adf
#' @rdname dir.create.adf
#' @aliases dir.create.adf,amigaDisk,character,missing,missing-method
#' @param x An [`amigaDisk`] on which the directory should be created.
#' @param path Specify the directory that should be created on `x`.
#' You can specify the full path on the virtual disk conform Amiga DOS syntax
#' (see [`current.adf.dir`] details). When no full path is specified
#' the new directory will be created in the current directory. Note that
#' wild cards are not allowed.
#' @param date A [`POSIXt`][base::DateTimeClasses] object that will be used as the
#' directory modification date. When missing the system time will used.
#' @param comment An optional `character` string that will be included
#' in the directory header as a comment. Should not be longer than 79 characters.
#' @return Returns an [`amigaDisk`] object on which the
#' directory is created.
#' @examples
#' \dontrun{
#' ## create a blank DOS disk:
#' blank.disk <- blank.amigaDOSDisk("blank", "DD", "FFS", TRUE, FALSE, FALSE)
#' 
#' ## creating a new directory on the blank disk is easy:
#' blank.disk <- dir.create.adf(blank.disk, "new_dir")
#' 
#' ## in the line above, the directory is placed in the
#' ## current directory (the root in this case). Directories
#' ## can also be created by specifying the full path:
#' 
#' blank.disk <- dir.create.adf(blank.disk, "DF0:new_dir/sub_dir")
#' 
#' ## check whether we succeeded:
#' list.adf.files(blank.disk)
#' 
#' ## we can even make it the current dir:
#' current.adf.dir(blank.disk) <- "DF0:new_dir/sub_dir"
#' }
#' @author Pepijn de Vries
#' @export
setMethod("dir.create.adf", c("amigaDisk", "character", "missing", "missing"), function(x, path, date, comment) {
  .put.file(x, raw(0), path, "ST_USERDIR")
})

#' @name dir.create.adf
#' @rdname dir.create.adf
#' @aliases dir.create.adf,amigaDisk,character,POSIXt,missing-method
#' @export
setMethod("dir.create.adf", c("amigaDisk", "character", "POSIXt", "missing"), function(x, path, date, comment) {
  .put.file(x, raw(0), path, "ST_USERDIR", date)
})

#' @name dir.create.adf
#' @rdname dir.create.adf
#' @aliases dir.create.adf,amigaDisk,character,POSIXt,character-method
#' @export
setMethod("dir.create.adf", c("amigaDisk", "character", "POSIXt", "character"), function(x, path, date, comment) {
  .put.file(x, raw(0), path, "ST_USERDIR", date, comment)
})

setGeneric("adf.file.info", function(x, path) standardGeneric("adf.file.info"))

#' File information on virtual amigaDisk objects
#' 
#' Obtain file information of file from a virtual [`amigaDisk`] object.
#' 
#' Use `adf.file.mode` to obtain or set a `character` string reflecting which
#' file mode flags are set, where:
#' 
#'  * `D`: deletable
#'  * `E`: executable
#'  * `W`: writeable
#'  * `R`: readable
#'  * `A`: archived
#'  * `P`: pure command
#'  * `S`: script
#'  * `H`: hold
#'  * starting without lower case: applies to user
#'  * starting with lower case `g`: applies to group
#'  * starting with lower case `o`: applies to other
#' 
#' Use `adf.file.time` to obtain or set the [base::POSIXt] properties of
#' a file on an [`amigaDisk`].
#' 
#' Use `adf.file.info` to obtain a combination of the information
#' listed above in a `data.frame`.
#' @aliases adf.file.info,amigaDisk,character-method
#' @param x An [`amigaDisk`] object in which this method
#' will obtain file information.
#' @param path A (`vector` of) `character` string(s) representing a file or directory name.
#' Use Amiga specifications for file name (see [`current.adf.dir`]). Wildcards are not allowed.
#' @param which Character indicating which time to obtain/modify. One of
#' `"m"` (date modified), `"c"` (date created), or `"a"` (date root modification).
#' This parameter works only on the disk's root and will be ignored for any
#' other directory or file.
#' @param value In case of `adf.file.time` an object of class [`base::POSIXt`].
#' In case of `adf.file.mode` either a character string representing the flags,
#' or a `vector` of named `logical` values, where the name of the `logical`
#' represents the flag to be altered (see also details).
#' @return In case of the replace methods, an [`amigaDisk`] class object is returned with the file
#' information updated. Otherwise, it will return the requested file information (see also details).
#' @docType methods
#' @name adf.file.info
#' @rdname file.info
#' @examples
#' \dontrun{
#' data(adf.example)
#' 
#' adf.file.mode(adf.example,  c("mods", "mods/mod.intro"))
#' adf.file.time(adf.example, c("mods", "mods/mod.intro"))
#' adf.file.size(adf.example,  c("mods", "mods/mod.intro"))
#' adf.file.info(adf.example,  c("mods", "mods/mod.intro"))
#' 
#' ## set the writeable flag for a group to TRUE
#' adf.file.mode(adf.example, "mods/mod.intro") <- c(gW = T)
#' 
#' ## Set the modified time-stamp to the current system time
#' adf.file.time(adf.example, "mods/mod.intro") <- Sys.time()
#' }
#' @author Pepijn de Vries
#' @export
setMethod("adf.file.info", c("amigaDisk", "character"), function(x, path) {
  root.id <- get.root.id(x)
  result <- do.call(rbind, lapply(path, function(p) {
    fh <- find.file.header(x, p)
    hi <- header.info(x, fh)
    if (hi[[1]]$sec_type == "ST_ROOT") ri <- root.info(x)
    prot.string <- .protect.string(hi, root.id)
    exe         <- attributes(prot.string)$exe
    attributes(prot.string) <- NULL
    data.frame(name  = hi[[1]]$file_name, size = hi[[1]]$bytesize, isdir = hi[[1]]$sec_type %in% c("ST_ROOT", "ST_USERDIR"),
               mode  = .protect.string(hi, root.id),
               mtime = if(exists("ri")) ri$v_datetime else hi[[1]]$datetime, ## for root last modification anywhere on disk
               ctime = if(exists("ri")) ri$c_datetime else hi[[1]]$datetime, ## for root creation date
               atime = if(exists("ri")) ri$r_datetime else hi[[1]]$datetime, ## for root last modification to root
               exe   = exe)
  }))
  row.names(result) <- result$name
  result$name       <- NULL
  return(result)
})

setGeneric("adf.file.mode", function(x, path) standardGeneric("adf.file.mode"))

#' @name adf.file.mode
#' @rdname file.info
#' @aliases adf.file.mode,amigaDisk,character-method
#' @export
setMethod("adf.file.mode", c("amigaDisk", "character"), function(x, path) {
  root.id <- get.root.id(x)
  unlist(lapply(path, function(p) {
    fh <- find.file.header(x, p)
    .protect.string(header.info(x, fh), root.id)
  }))
})

setGeneric("adf.file.mode<-", function(x, path, value) standardGeneric("adf.file.mode<-"))

#' @name adf.file.mode<-
#' @rdname file.info
#' @aliases adf.file.mode<-,amigaDisk,character,character-method
#' @export
setMethod("adf.file.mode<-", c("amigaDisk", "character", "character"), function(x, path, value) {
  value    <- rep_len(value, length(path))
  fl       <- .protection.flags[!grepl("reserved|SUID", .protection.flags)]
  nchar_fl <- cumsum(nchar(fl))
  for (i in seq_along(path)) {
    args     <- mapply(function(a, b){ substr(value[[i]], a, b) }, a = utils::head(c(0, nchar_fl), -1) + 1, b = nchar_fl)
    args     <- args[args != ""]
    not_set  <- args %in% c("-", "--")
    set      <- args == fl[seq_along(args)]
    if (!all(not_set | set)) stop("Unexpected characters in mode string")
    if (!all(xor(set, not_set))) stop("Unexpected input!")
    args     <- set & !not_set
    names(args) <- fl[seq_along(args)]
    adf.file.mode(x, path[[i]]) <- args
  }
  x
})

#' @name adf.file.mode<-
#' @rdname file.info
#' @aliases adf.file.mode<-,amigaDisk,character,logical-method
#' @export
setMethod("adf.file.mode<-", c("amigaDisk", "character", "logical"), function(x, path, value) {
  root.id <- get.root.id(x)
  bt      <- boot.info(x)
  for (i in seq_along(path)) {
    fh      <- find.file.header(x, path[[i]])
    if (fh == root.id) stop("File mode cannot be set for the root!")
    hi      <- header.info(x, fh)[[1]]
    current <- hi$protect
    if (any(duplicated(names(value))) || !any((names(value) %in% names(current)))) stop("Unknown, unnamed or duplicated mode flag in 'value'")
    current[names(value)] <- value
    ## first four flags are negated:
    current[1:4]          <- !current[1:4]
    current               <- bitmapToRaw(current, T, T)
    ## Put updated flag on disk
    x@data[fh*BLOCK_SIZE + (BLOCK_SIZE/4 - 56)*4 + 33:36] <- current
    ## Update checksum
    x@data[fh*BLOCK_SIZE + 21:24] <- calculate.checksum(x, fh)
    if (bt$flag[["dir.cache.mode"]]) {
      parent <- header.info(x, fh)[[1]]$parent
      dc <- dir.cache.info(x, parent)
      dc.cur <- attributes(dc)$dc.blocks
      sel <- base::which(unlist(lapply(dc, function(y) y$header == fh)))
      
      ## update date in dir cache block (checksums are automatically updated in .make.dir.cache)
      dc[[sel]]$protect <- rawToAmigaInt(current, 32, F)
      x@data[as.vector(outer(1:BLOCK_SIZE, dc.cur*BLOCK_SIZE, "+"))] <-
        unlist(
          .make.dir.cache.block(do.call(rbind, lapply(dc, data.frame)), parent, dc.cur)
        )
    }
  }
  x
})

.protect.string <- function(header_info, root.id) {
  if (header_info[[1]]$header_key %in% c(0, root.id)) {
    result <- strrep("-", sum(nchar(.protection.flags[!grepl("reserved|SUID", .protection.flags)])))
    prot   <- F
  } else {
    prot   <- header_info[[1]]$protect
    result <- names(prot)
    result[!prot] <- strrep("-", nchar(result[!prot]))
    result <- result[!grepl("reserved|SUID", names(prot))]
    result <- paste(result, collapse = "")
    prot   <- any(prot[c("E", "gE", "oE")])
  }
  attributes(result)$exe <- prot
  return(result)
}

setGeneric("adf.file.time", function(x, path, which) standardGeneric("adf.file.time"))

#' @name adf.file.time
#' @rdname file.info
#' @aliases adf.file.time,amigaDisk,character,missing-method
#' @export
setMethod("adf.file.time", c("amigaDisk", "character", "missing"), function(x, path, which) {
  do.call(c, lapply(path, function(p) {
    fh <- find.file.header(x, p)
    rawToAmigaDate(x@data[fh*BLOCK_SIZE + (BLOCK_SIZE/4 - 56)*4 + 133:144])
  }))
})

#' @name adf.file.time
#' @rdname file.info
#' @aliases adf.file.time,amigaDisk,character,character-method
#' @export
setMethod("adf.file.time", c("amigaDisk", "character", "character"), function(x, path, which = c("m", "c", "a")) {
  which   <- match.arg(which, c("m", "c", "a"))
  root.id <- get.root.id(x)
  do.call(c, lapply(path, function(p) {
    fh <- find.file.header(x, p)
    if (fh == root.id) {
      pos <- root.id*BLOCK_SIZE + (BLOCK_SIZE/4 - 56)*4 + switch(which, a = 132, m = 184, c = 196) + 1:12
    } else {
      pos <- fh*BLOCK_SIZE + (BLOCK_SIZE/4 - 56)*4 + 133:144
    }
    rawToAmigaDate(x@data[pos])
  }))
})

setGeneric("adf.file.time<-", function(x, path, which, value) standardGeneric("adf.file.time<-"))

#' @name adf.file.time<-
#' @rdname file.info
#' @aliases adf.file.time<-,amigaDisk,character,missing,POSIXt-method
#' @export
setMethod("adf.file.time<-", c("amigaDisk", "character", "missing", "POSIXt"), function(x, path, which, value) {
  .adf.file.time(x, path, value = value)
})

#' @name adf.file.time<-
#' @rdname file.info
#' @aliases adf.file.time<-,amigaDisk,character,character,POSIXt-method
#' @export
setMethod("adf.file.time<-", c("amigaDisk", "character", "character", "POSIXt"), function(x, path, which = c("m", "c", "a"), value) {
  ## TODO test if updating file time works in emulator, also for dir cache disks...
  .adf.file.time(x, path, which, value)
})

.adf.file.time <- function(x, path, which, value) {
  ismissing <- missing(which)
  if (ismissing) which <- "m"
  which   <- match.arg(which, c("m", "c", "a"))
  bt      <- boot.info(x)
  root.id <- get.root.id(x)
  which   <- rep_len(which, length(path))
  value   <- value[rep_len(seq_along(value), length(path))]
  for (i in seq_along(path)) {
    fh <- find.file.header(x, path[[i]])
    if (fh == root.id) {
      pos     <- root.id*BLOCK_SIZE + (BLOCK_SIZE/4 - 56)*4 + switch(which[[i]], a = 132, m = 184, c = 196) + 1:12
    } else {
      if (!ismissing) warning("'which' is specified, but ignored since 'path' does not point to root.")
      pos <- fh*BLOCK_SIZE + (BLOCK_SIZE/4 - 56)*4 + 133:144
      if (bt$flag[["dir.cache.mode"]]) {
        parent <- header.info(x, fh)[[1]]$parent
        dc <- dir.cache.info(x, parent)
        dc.cur <- attributes(dc)$dc.blocks
        sel <- base::which(unlist(lapply(dc, function(y) y$header == fh)))
        
        ## update date in dir cache block (checksums are automatically updated in .make.dir.cache)
        dc[[sel]]$date <- value[[i]]
        x@data[as.vector(outer(1:BLOCK_SIZE, dc.cur*BLOCK_SIZE, "+"))] <-
          unlist(
            .make.dir.cache.block(do.call(rbind, lapply(dc, data.frame)), parent, dc.cur)
          )
      }
    }
    ## update date in file header:
    x@data[pos] <- amigaDateToRaw(value[[i]])
    ## Update file header checksum
    x@data[fh*BLOCK_SIZE + 21:24] <- calculate.checksum(x, fh)
  }
  x
}

setGeneric("adf.file.size", function(x, path) standardGeneric("adf.file.size"))

#' @name adf.file.size
#' @rdname file.info
#' @aliases adf.file.size,amigaDisk,character-method
#' @export
setMethod("adf.file.size", c("amigaDisk", "character"), function(x, path) {
  unlist(lapply(path, function(p) {
    fh <- find.file.header(x, p)
    as.integer(header.info(x, fh)[[1]]$bytesize)
  }))
})
