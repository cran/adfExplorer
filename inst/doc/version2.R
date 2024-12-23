## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----opendisk-----------------------------------------------------------------
adz_file <- system.file("example.adz", package = "adfExplorer")

# ---------------- adfExplorer
library(adfExplorer, warn.conflicts = FALSE)

# ---------------- Old code
# my_disk1 <- read.adz(adz_file)

# ---------------- New code
my_disk2 <- connect_adf(adz_file)


## ----curdir-------------------------------------------------------------------
# ---------------- Old code
# current.adf.dir(my_disk1)
# current.adf.dir(my_disk1) <- "s"

# ---------------- New code
adf_directory(my_disk2)
adf_directory(my_disk2) <- "s"


## ----listdir------------------------------------------------------------------
# ---------------- Old code
# list.adf.files(my_disk1, "DF0:")

# ---------------- New code
list_adf_entries(my_disk2, "DF0:", recursive = TRUE)


## ----fileread-----------------------------------------------------------------
# ---------------- Old code
# get.adf.file(my_disk1, "startup-sequence") |>
#   rawToChar()

# ---------------- New code
con <- adf_file_con(my_disk2, "startup-sequence")
readLines(con, warn = FALSE)
close(con)

## ----cleanup------------------------------------------------------------------
# ---------------- Old code
# rm(my_disk1)

# ---------------- New code
close(my_disk2)
rm(my_disk2)

