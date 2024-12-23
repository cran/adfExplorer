## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(adfExplorer, warn.conflicts = FALSE)
adz_file <- system.file("example.adz", package = "adfExplorer")
my_device <- connect_adf(adz_file)

## ----create-------------------------------------------------------------------
adf_file <- tempfile(fileext = ".adf")
new_device <- create_adf_device(adf_file)

## ----list-entries-------------------------------------------------------------
list_adf_entries(my_device)

## ----close-devices------------------------------------------------------------
close(new_device)
## Let's keep `my_device` open to be used in examples below

## ----open-con-----------------------------------------------------------------
con <- adf_file_con(my_device, "DF0:mods/mod.intro")

summary(con)

## ----read-bin-----------------------------------------------------------------
readBin(con, "raw", 20L)

## ----seek---------------------------------------------------------------------
seek(con)
seek(con, 30L)

## ----close-file---------------------------------------------------------------
close(con)

## ----virtual-path-------------------------------------------------------------
virtual_path(my_device, "DF0:s/startup-sequence")
virtual_path(my_device, "idontexist")

## ----init-block---------------------------------------------------------------
block1 <- new_adf_block()
## a block with random data
block2 <- as_adf_block(as.raw(sample.int(n=256L, size = 512L, replace = TRUE) - 1L))

## ----read-block---------------------------------------------------------------
## This will read the initial 'boot' block
## from the virtual device
block3 <- read_adf_block(my_device, 0L)

## ----remove-block-------------------------------------------------------------
rm(block1, block2, block3)

