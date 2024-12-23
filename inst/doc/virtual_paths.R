## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----connect------------------------------------------------------------------
library(adfExplorer, warn.conflicts = FALSE)

adz_file <- system.file("example.adz", package = "adfExplorer")
my_device <- connect_adf(adz_file)

## ----df0----------------------------------------------------------------------
virtual_path(my_device, "DF0:")

## ----sys----------------------------------------------------------------------
virtual_path(my_device, "SYS:")

## ----diskname-----------------------------------------------------------------
virtual_path(my_device, "adfExampleOFS:")

## ----fullpath-----------------------------------------------------------------
virtual_path(my_device, "DF0:s/startup-sequence")

## ----relativepath-------------------------------------------------------------
virtual_path(my_device, "s/startup-sequence")

## ----finalize-----------------------------------------------------------------
close(my_device)

