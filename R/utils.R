#' CSS to hide placeholder markers in DOCX and HTML
#'
#' @description For Word documents a `PlaceholderMarker` style must be created.
#' @return CSS string.
#' @export
hide_markers_css <- function() {
  'span[data-custom-style="PlaceholderMarker"] { display: none !important; }'
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
  knitr::is_latex_output()
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

#' Flag lines that are code or YAML front matter (internal)
#'
#' Marks lines inside fenced code blocks (```` ``` ```` or `~~~`, including the fence lines) and inside YAML front
#' matter at the top of the document. Header scanners use this so that `#| echo: false` and `# comments` in code are
#' never treated as headings.
#'
#' @param lines Character vector, one element per line.
#' @return Logical vector the same length as `lines`.
#' @keywords internal
#' @noRd
.code_or_yaml_lines <- function(lines) {
  out <- logical(length(lines))
  if (!length(lines)) {
    return(out)
  }

  i <- 1L
  if (grepl("^---\\s*$", lines[1])) {
    end <- which(grepl("^(---|\\.\\.\\.)\\s*$", lines))
    end <- end[end > 1L][1]
    if (!is.na(end)) {
      out[1:end] <- TRUE
      i <- end + 1L
    }
  }

  fence <- NULL
  while (i <= length(lines)) {
    line <- lines[i]
    if (is.null(fence)) {
      m <- regmatches(line, regexec("^ {0,3}(`{3,}|~{3,})", line))[[1]]
      if (length(m)) {
        fence <- m[2]
        out[i] <- TRUE
      }
    } else {
      out[i] <- TRUE
      ch <- substr(fence, 1, 1)
      close_re <- paste0("^ {0,3}", if (ch == "`") "`" else "~", "{", nchar(fence), ",}\\s*$")
      if (grepl(close_re, line)) {
        fence <- NULL
      }
    }
    i <- i + 1L
  }

  out
}

#' Flag Markdown ATX heading lines outside code and YAML (internal)
#'
#' @param lines Character vector, one element per line.
#' @return Logical vector the same length as `lines`.
#' @keywords internal
#' @noRd
.is_heading_line <- function(lines) {
  grepl("^#{1,6}([ \t]|$)", lines) & !.code_or_yaml_lines(lines)
}

#' This allows mocking for testthat
#' @keywords internal
.pandoc_to <- function(fmt) knitr::pandoc_to(fmt)
