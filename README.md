
<!-- README.md is generated from README.Rmd. Please edit that file -->
gcfboardr
=========

A Text Data Set Harvested from Green Climate Fund Board Documents
-----------------------------------------------------------------

> “Words can be like X-rays if you use them properly -- they’ll go through anything. You read and you’re pierced.”

**Aldous Huxley** *Brave New World*

This package provides access to the full texts of board meeting documents published by The Green Climate Fund, up to and including their 16th board meeting in April 2017. The text for each of over 500 Pdf documents was sourced from the [Green Climate Fund website](http://www.greenclimate.fund/boardroom/board-meetings/documents), processed a bit, and made ready for text analysis. Each line of text is in a character vector with elements of about 70 characters. The package contains 520,000+ lines of text from over 500 documents.

Installation
------------

To install the package type the following:

    install.packages("gcfboardr")
    library(gcfboardr)

Or you can install the development version from Github:

    library(devtools)
    install_github("ljodea/gcfboardr")
    library(gcfboardr)

How to Use This Package
-----------------------

After installing `gcfboardr` and loading the package library, you can load the data as follows:

``` r
data(gcfboard_docs)
```

This package was built to be ready for tidy analysis of text data. As such, I recommend using it in conjunction with the `tidytext` package, written by Julia Silge and David Robinson, along with the `dplyr` and `ggplot2` packages written by Hadley Wickham.
