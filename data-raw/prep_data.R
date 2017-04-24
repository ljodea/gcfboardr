## This is the script used to download the GCF Board Documents as PDF files and
## pre-process them before adding them to the gcfboardr package for v0.1.0

library(rvest)
library(RCurl)
library(tidyr)
library(dplyr)
library(tidytext)
library(purrr)
library(readr)
library(stringr)
library(pdftools)
library(devtools)
library(roxygen2)
library(knitr)
library(testthat)

## Custom Functions For Harvesting -------

## extract date from pdf metadata; it's a wrapper for pdf_info from pdftools package
pdf_date <- function(infilename) {
  meta <- pdftools::pdf_info(infilename)
  meta$created
}

## read the links from one B.XX page
read_gcf_pdf_links <- function(specific_B.XX_link) {
  read_html(specific_B.XX_link) %>% html_nodes(".title a") %>% html_attr(name = "href")
}

## pull out the anchor text for use as labels in the df
read_gcf_pdf_anchors <- function(specific_B.XX_link) {
  read_html(specific_B.XX_link) %>% html_nodes(".title a") %>% html_text()
}

## read just the meeting name from the html tags in a B.XX index page
read_gcf_meeting_number <- function(specific_B.XX_link) {
  read_html(specific_B.XX_link) %>% html_nodes(".content-title") %>%
    html_text()
}

## harvest all the lines from all the extant pdfs belonging to a single board meeting (takes a single index link) ------
harvest_one_bm <- function(index_page_link) {
  data_frame(file = read_gcf_pdf_links(index_page_link),
             meeting = read_gcf_meeting_number(index_page_link),
             title = read_gcf_pdf_anchors(index_page_link)) %>%
    mutate(exists = as.logical(map(file, url.exists))) %>% filter(exists == TRUE) %>% select(-exists) %>%
    transmute(pagetext = map(file, pdf_text), title, meeting) %>% unnest(pagetext) %>%
    filter(str_detect(pagetext, "\n")) %>%
    transmute(text = map(pagetext, read_lines), title, meeting) %>%
    unnest(text)
}

## Pre-Processing script ------

## Harvest a list of links to board meeting pages on GCF site, each of which hosts the individual
## document list for a separate board meeting
meeting_links_list <- read_html("http://www.greenclimate.fund/boardroom/board-meetings/documents?p_p_id=122_INSTANCE_8e72dTqCP5qa&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=_118_INSTANCE_jUGwSITWV8c5__column-2&p_p_col_count=1&p_r_p_564233524_resetCur=true&p_r_p_564233524_categoryId=568746#nav-category") %>%
  html_nodes("#search-by-meeting a") %>% html_attr(name = "href")

## Get the complete list of meeting numbers
meeting_names <- as.factor(unlist(map(meeting_links_list, read_gcf_meeting_number)))

## Build data itself, one tbl per board meeting, before calling bind_rows and returning the whole dataset ------
gcfboard_docs <- map_df(meeting_links_list, harvest_one_bm)

# Meeting should be a factor
gcfboard_docs$meeting <- as.factor(gcfboard_docs$meeting)

## Clean text with regex -----

# trim leading and traling whitespace to cut down file size. Before: 71.8Mb AFter: 64.2Mb
gcfboard_docs$text <- trimws(gcfboard_docs$text)

# remove website links. AFter: 64Mb
gcfboard_docs$text <- str_replace_all(gcfboard_docs$text, " ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "")

# remove email addresses. After size: 64Mb
gcfboard_docs$text <- str_replace_all(gcfboard_docs$text, "\\S+@\\S+", "")

# remove "page x" from strings, After size: 64Mb
gcfboard_docs$text <- stringr::str_replace_all(gcfboard_docs$text,
                         "Page \\d+ of \\d+|page \\d+|Page \\d+|Page.\\d+|page.\\d+|page.\\w+|Page.\\w+|page \\w+|Page \\w+",
                         "")

# remove board meeting/document references i.e. "GCF/B.16/23",A fter size: 63.8Mb
gcfboard_docs$text <- str_replace_all(gcfboard_docs$text,
                                      "GCF/B.\\d+/\\d+|gcf/B.\\d+/\\d+|gcf/b.\\d+/\\d+|GCF/\\w+.\\d+/\\d+|gcf/\\w+.\\d+|gcf/\\d+.\\d+|B.\\d+/\\d+|GCF/\\w./\\d+",
                                      "")

# remove punctuation which isn't useful (i.e. retain colons, semi-colons, infixed hyphens etc). After size: 63.5Mb
gcfboard_docs$text <- str_replace_all(gcfboard_docs$text,
                                      "((\\w\\s[–]\\s\\w)|(\\w\\s[-]\\s\\w)|\\w['-/]\\w)|[^[:alnum:] ,.?%:;]",
                                      "\\1")
str_replace_all("4 – 6 April hyphens, 4-6 hyphens, ------, //////, 4 -- 6 hyphens, What about 4 - 6",
                "((\\w\\s[–]\\s\\w)|(\\w\\s[-]\\s\\w)|\\w['-/]\\w)|[^[:alnum:] ,.?%:;]",
                "\\1") # this works for the example, but not on the proper text itself

## In response to feedback from CRAN, reduce the size of the tarball to less than 5Mb ------
## B.03 documents are encoded in a strange way, producing multiple unreadable documents, so omit
## After removing both B.03 and any extra whitespace. Result: 5.3Mb (winbuilder said 5743268, tarball was 5.6Mb)
data("gcfboard_docs")
str(gcfboard_docs)
gcfboard_docs <- gcfboard_docs %>%
  filter(meeting != "B.03") %>%
  transmute(title, meeting, text = str_replace_all(text,"[\\s]+", " "))

## After 2nd rejection from CRAN, try to remove all "in-between" board meeting docs, 17,000 lines of text. Result: removes 1.7Mb
str(gcfboard_docs)
gcfboard_docs$meeting <- as.character(gcfboard_docs$meeting)
gcfboard_docs <- filter(gcfboard_docs, nchar(meeting) <= 4)

## Try saving the data now. Result size: 5.2Mb

## Try with both meeting and title as factors. Before: 56.5 Mb, after: 52.8Mb
gcfboard_docs$meeting <- as.factor(gcfboard_docs$meeting)
gcfboard_docs$title <- as.factor(gcfboard_docs$title)

## Try saving the data now. Result size: still 5.2Mb

## Don't try a lookup table! It makes zero difference!

## Try saving the data now. Result size: still 5.2Mb, with bzip2: 6.9Mb, with gzip: 9.8Mb

## Try removing all numbers. Before: 50.8Mb. After: 47.4Mb
gcfboard_docs <- gcfboard_docs %>%
  transmute(text = str_replace_all(text, "[[:digit:]]", "")) %>%
  filter(text != "")

## Try saving the data now. Result size: 5Mb. Still not small enough for CRAN

## Try remov

## clean up empty lines caused by removing links, emails, superfluous punctuation, etc
gcfboard_docs <- filter(gcfboard_docs, text != "")

## How large will it be if I just save the text alone? Answer: 48.9Mb (or 3.9Mb smaller than the 3-column tbl)
temp <- gcfboard_docs %>%
  select(text)

# Finally save the .rda file using xz compression
devtools::use_data(gcfboard_docs, compress = "xz", overwrite = TRUE)

## Better solution: just grab it from my github URL and make the package one that just compiles that data from my URL and loads it.
## Much better: then I can avoid all this other shit.

## Finished!
