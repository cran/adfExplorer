% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/02amigaDiskBasics.r
\name{blank.amigaDOSDisk}
\alias{blank.amigaDOSDisk}
\alias{blank.amigaDOSDisk,character-method}
\title{Create blank disk with file system}
\usage{
\S4method{blank.amigaDOSDisk}{character}(
  diskname,
  disktype = c("DD", "HD"),
  filesystem = c("OFS", "FFS"),
  international = F,
  dir.cache = F,
  bootable = T,
  creation.date = Sys.time()
)
}
\arguments{
\item{diskname}{A \code{character} string of the desired disk name.
Disk name should be between 1 and 30 characters long, and should
not contain any colon or forward slash characters.}

\item{disktype}{Either "\code{DD}" (double density, most common and
therefore default) or "\code{HD}" (high denisity). The type of disk
the blank disk should represent.}

\item{filesystem}{Either "\code{OFS}" (old file system) or "\code{FFS}"
(fast file system). \code{FFS} is not compatible with Amiga OS <2.0.
On the original system, the FFS was slightly faster and can requires
less data for the file system. It is however less robust: on corrupt
disks, file recovery is more difficult.}

\item{international}{The international mode was introduced in Amiga
OS 2.0. In lower versions, international characters were mistakenly
not converted to uppercase when comparing file names. The international
mode (set this argument to \code{TRUE}) corrects this mistake.
The international mode is not compatible with Amiga OS <2.0.}

\item{dir.cache}{The directory cache mode (set this argument to
\code{TRUE}) was introduced with Amiga OS 3.0 (and is not compatible
with lower versions). On real machines this allowed for slightly faster
directory listing (but costs disk space). The directory cache mode is
always used in combination with the 'international mode'.}

\item{bootable}{When this argument is set to \code{TRUE}. Minimal
executable code is added to the bootblock. This code will open the
command line interface when the disk is used to boot the system. In
Amiga OS >2.0, the 'Startup-Sequence' file needs to be present
for this, otherwise the screen will remain black on booting. See also the
\code{\link{boot.block.code}} data.}

\item{creation.date}{A \code{\link[base:DateTimeClasses]{POSIXt}} object. Will be used
and stored as the creation date of the virtual disk. Note that the Amiga
does not store the time zone and UTC is assumed as default. The Amiga
stores the date and time as positive integers, relative to 1st of
January in 1978. As a result, dates before that are not allowed.}
}
\value{
Returns a blank \code{\link{amigaDisk}} object with a file
system installed on it.
}
\description{
Create a virtual blank DOS formatted floppy disk with a file system on it.
}
\details{
Creates a blank \code{\link{amigaDisk}} object. This method differs
from the object constructor (\code{new("amigaDisk")}) because it also
installs a file system on the disk. The blank disk can thus be used to
write files onto, and is also usable in Amiga emulators. For use in
emulators, the object needs to be saved with the \code{\link{write.adf}}
method.
}
\examples{
## Create a blank virtual disk compatible with
## Amiga OS 1.x and up (Note that spaces in file and
## disk names are allowed but not recommended):
disk.os1x <- blank.amigaDOSDisk(diskname = "I'm_OS_1.x_compatible",
                                disktype = "DD",
                                filesystem = "OFS",
                                international = FALSE,
                                dir.cache = FALSE,
                                bootable = TRUE)

## create a disk that is compatible with OS 2.x and up
## (no backward compatibility):
disk.os2x <- blank.amigaDOSDisk(diskname = "I'm_OS_2.x_compatible",
                                disktype = "DD",
                                filesystem = "FFS",
                                international = TRUE,
                                dir.cache = FALSE,
                                bootable = TRUE)

## create a disk that is compatible with OS 3.x and up
## (no backward compatibility):
disk.os3x <- blank.amigaDOSDisk(diskname = "I'm_OS_3.x_compatible",
                                disktype = "DD",
                                filesystem = "FFS",
                                international = TRUE,
                                dir.cache = TRUE,
                                bootable = TRUE)
}
\author{
Pepijn de Vries
}
