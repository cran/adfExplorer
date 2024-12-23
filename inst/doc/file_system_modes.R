## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(adfExplorer, warn.conflicts = FALSE)

disk_file <- tempfile(fileext = ".adf")

## Create a blank device and create a connection to it:
new_device <- create_adf_device(disk_file, write_protected = FALSE)

## Format the device and install a file system:
prepare_adf_device(
  dev           = new_device,
  name          = "Example_disk",
  ffs           = TRUE,  ## Use fast file system
  international = TRUE,  ## Use international mode
  dircache      = FALSE) ## Don't use directory caching.

## Don't forget to close the connection when you are done:
close(new_device)

