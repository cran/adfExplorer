% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/device_create.R
\name{create_adf_device}
\alias{create_adf_device}
\alias{prepare_adf_device}
\alias{prepare_adf_device.adf_device}
\title{Create and format a virtual ADF device}
\usage{
create_adf_device(destination, type = "DD", ..., connect = TRUE)

prepare_adf_device(
  dev,
  name = "EMPTY",
  ffs = TRUE,
  international = TRUE,
  dircache = FALSE,
  bootable = TRUE,
  ...
)

\method{prepare_adf_device}{adf_device}(
  dev,
  name = "EMPTY",
  ffs = TRUE,
  international = TRUE,
  dircache = FALSE,
  bootable = TRUE,
  ...
)
}
\arguments{
\item{destination}{File path where the virtual device needs to be stored.}

\item{type}{Specify the type of virtual device you wish to create.
Should be one of \code{"DD"} (double density floppy disk) or \code{"HD"} (high
density floppy disk).}

\item{...}{Ignored for \code{prepare_adf_device()}.}

\item{connect}{A \code{logical} value. If set to \code{TRUE} a connection is opened to the
newly created virtual device and is returned as a \code{adf_device} class object. If
it is set to \code{FALSE}, the file is just created and no connection is opened. In the
latter case \code{NULL} is returned invisibly.}

\item{dev}{The virtual adf device for which information needs to be obtained.
It should be of class \code{adf_device} which can be created with \code{\link[=create_adf_device]{create_adf_device()}}
or \code{\link[=connect_adf]{connect_adf()}}.}

\item{name}{A \code{character} string specifying the disk name for the volume on the
virtual device. It will be truncated automatically when too long.}

\item{ffs}{A \code{logical} value indicating which file system to be used. If \code{TRUE}
the 'Fast File System' (FFS) is used, when \code{FALSE}, the 'Old File System' is used.
See also \code{vignette("file_system_modes")}.}

\item{international}{A \code{logical} value indicating whether the international mode
should be used for file naming. See also \code{vignette("file_system_modes")}.}

\item{dircache}{A \code{logical} value indicating whether directory caching should be
used. See also \code{vignette("file_system_modes")}.}

\item{bootable}{A \code{logical} value indicating whether you want to include executable
code on the boot block. If set to \code{TRUE} minimal code will be added to the boot block.
In an Amiga emulator, this code will load the Amiga Disk Operating System library
and start the Amiga Command line interface (CLI). It will then run the startup
sequence file from the disk (if available).

If set to \code{FALSE} no such code is added. In that case the file system will still be
accessible by the Amiga operating system (if the file system mode is compatible).
You just can't use the disk to start up a (virtual) Amiga machine.}
}
\value{
Either an \code{adf_device} connection or \code{NULL} depending on the value of
\code{connect}.
}
\description{
These functions help you to create an empty virtual device that can be used
in Commodore Amiga emulation. \code{create_adf_device()} simply creates a file
of the proper size (the file size represents the device capacity) and fills it
with \code{raw} zeros. In order to use the device in the Amiga operating system, a
file system needs to be installed on the device. This can be achieved with
\code{prepare_adf_device()}. Note that the file system itself will also consume
disk space on the virtual device.
}
\examples{
## Filepath to store the virtual device:
dest <- tempfile(fileext = ".adf")

## Create a blank unformated virtual device (a double density floppy disk):
my_device <- create_adf_device(dest, "DD", connect = TRUE, write_protected = FALSE)

print(my_device)

## Format the floppy and create a file system on the device:
prepare_adf_device(my_device, name = "foobar")

print(my_device)

## don't forget to close the device connection after use:
close(my_device)
}
\author{
Pepijn de Vries
}
