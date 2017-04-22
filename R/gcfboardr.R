#' gcfboardr: A text dataset harvested from Green Climate Fund Board documents.
#'
#' The package also includes the script used to harvest data from the pdfs.
#'
#'
#' @docType package
#' @name gcfboardr
NULL

#' 500,000+ lines of text from Green Climate Fund board documents
#'
#' A dataset containing 520,000 lines of text from Green Climate Fund (GCF)
#' board documents, dating from 2012 to 2017.
#'
#' @source \url{http://www.greenclimate.fund/boardroom/board-meetings/documents}
#' @format A data frame with 520,024 rows and 3 variables.
#' \describe{
#'   \item{title}{document titles as described in the GCF document library}
#'   \item{meeting}{code used to refer to distinct board meetings, in the form of "B.01" to designate the first meeting, "B.16" to designate the 16th meeting}
#'   \item{text}{lines of text extracted from the documentation}
#' }
"gcfboard_docs"
