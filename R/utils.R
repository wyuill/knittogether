#' CSS to hide placeholder markers in DOCX and HTML
#'
#' @description For Word documents a `PlaceholderMarker` style must be created.
#' @return CSS string.
#' @export
hide_markers_css <- function() {
  'span[custom-style="PlaceholderMarker"] { display: none !important; }'
}

#' Check if output is PPTX
#' @rdname is_html
#' @export
is_pptx <- function() {
  knitr::pandoc_to('pptx')
}

#' Check if output is DOCX
#' @rdname is_html
#' @export
is_docx <- function() {
  knitr::pandoc_to('docx')
}

#' Check if output is PDF
#' @rdname is_html
#' @export
is_pdf <- function() {
  knitr::pandoc_to('pdf')
}

#' Check if output is HTML
#' @description Utility functions to detect the current knitr output format.
#' `is_html` checks whether the output is HTML.
#' `is_pdf` checks whether the output is PDF.
#' `is_docx` checks whether the output is DOCX.
#' `is_pptx` checks whether the output is PPTX.
#' @return TRUE if knitr is outputting the relevant file type.
#' @export
is_html <- function() {
  knitr::is_html_output()
}

#' Detect output format
#' @return String identifying output type.
#' @export
output_type <- function() {
  if (is_pptx()) {
    "pptx"
  } else if (is_docx()) {
    "docx"
  } else if (is_pdf()) {
    "pdf"
  } else if (is_html()) {
    "html"
  } else {
    "unknown"
  }
}

#' This allows mocking for testthat
#' @keywords internal
.pandoc_to <- function(fmt) knitr::pandoc_to(fmt)
