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

# trim leading and traling whitespace to cut down file size (took it down to 62.1Mb!)
gcfboard_docs$text <- trimws(gcfboard_docs$text)

# remove website links, b4 size: 62.1Mb, after size: 62Mb
gcfboard_docs$text <- str_replace_all(gcfboard_docs$text, " ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "")

# remove email addresses, b4 size: 62Mb, after size: 61.9Mb
gcfboard_docs$text <- str_replace_all(gcfboard_docs$text, "\\S+@\\S+", "")

# remove "page x" from strings, b4 size: 61.9Mb, after size: 61.9Mb
gcfboard_docs$text <- stringr::str_replace_all(gcfboard_docs$text,
                         "Page \\d+ of \\d+|page \\d+|Page \\d+|Page.\\d+|page.\\d+|page.\\w+|Page.\\w+|page \\w+|Page \\w+",
                         "")

# remove board meeting/document references i.e. "GCF/B.16/23", b4 size: 61.9Mb, after size: 61.8Mb
gcfboard_docs$text <- str_replace_all(gcfboard_docs$text,
                                      "GCF/B.\\d+/\\d+|gcf/B.\\d+/\\d+|gcf/b.\\d+/\\d+|GCF/\\w+.\\d+/\\d+|gcf/\\w+.\\d+|gcf/\\d+.\\d+|B.\\d+/\\d+",
                                      "")

# remove punctuation which isn't useful (i.e. retain colons, semi-colons, infixed hyphens etc)
gcfboard_docs$text <- str_replace_all(gcfboard_docs$text,
                                      "((\\w\\s[–]\\s\\w)|(\\w\\s[-]\\s\\w)|\\w['-/]\\w)|[^[:alnum:] ,.?%:;]",
                                      "\\1")
str_replace_all("4 – 6 April hyphens, 4-6 hyphens, ------, //////, 4 -- 6 hyphens, What about 4 - 6",
                "((\\w\\s[–]\\s\\w)|(\\w\\s[-]\\s\\w)|\\w['-/]\\w)|[^[:alnum:] ,.?%:;]",
                "\\1") # this works for the example, but not on the proper text itself

## clean up empty lines caused by removing links, emails, superfluous punctuation, etc
gcfboard_docs <- filter(gcfboard_docs, text != "")

## In response to feedback from CRAN, reduce the size of the tarball to less than 5Mb ------
## B.03 documents are encoded in a strange way, producing multiple unreadable documents, so omit
## After removing both B.03 and any extra whitespace. Result: 5.3Mb

# Now test whether the tarball will be less than 7.5Mb after using LazyDataCompression == xz in DESCRIPTION
# So run the whole thing now, using original data. Result:
str(gcfboard_docs)
gcfboard_docs <- gcfboard_docs %>%
  filter(meeting != "B.03") %>%
  transmute(title, meeting, text = str_replace_all(text,"[\\s]+", " "))

# Finally save the .rda file using xz compression
devtools::use_data(gcfboard_docs, compress = "xz", overwrite = TRUE)

## Finished!
