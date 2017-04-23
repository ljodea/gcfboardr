## Resubmission
This is a resubmission. In this version I have:

* Added proper web references to DESCRIPTION

* Reduced the size of the tarball to less than 5Mb

## Test environments
* Local OS X install: R 3.3.3
* Ubuntu 12.04 (on Travis-CI): R 3.3.3
* Win-builder: R-devel and R-release

## R CMD check results
There were no ERRORs or WARNINGs. 

There were 2 NOTEs:

* checking CRAN incoming feasibility ... NOTE
Maintainer: 'Liam O'Dea <liam.j.odea@gmail.com>'

New submission

This is my first submission.

* checking installed package size ... NOTE
  installed size is  5.6Mb
  sub-directories of 1Mb or more:
    data   5.5Mb

The data is in its own package and won’t be updated frequently. 
I tested different compression types and achieved the smallest
file size with "xz".

## Downstream dependencies
There are currently no downstream dependencies for this package.
