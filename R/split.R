#' Split a long Markdown file into one file per section
#'
#' Splits a markdown document at a specified pattern and writes each section to its
#' own subdirectory. This is useful for converting long documents into smaller pages
#' that map cleanly onto Quarto side navigation.
#'
#' When Quarto output is requested, the level-1 section heading is moved into Quarto
#' YAML metadata (title and order) and removed from the markdown body.
#'
#' Quarto include statements can optionally be rewritten when sections are written
#' to subdirectories so that relative include paths continue to resolve correctly.
#' This behaviour is enabled by default but can be disabled for documents that
#' already use depth-aware or project-root paths.
#'
#' @param markdown_file Path to the markdown file to split.
#' @param output_dir Output directory or directories for the split files.
#'   If NULL, directories are derived from slugified section headings.
#' @param split_pattern Regular expression identifying split points.
#'   Defaults to "^# " (level-1 headers).
#' @param qmd Controls Quarto output:
#'   \describe{
#'     \item{none}{Do not create Quarto files; headings are preserved in markdown.}
#'     \item{separate}{Create a markdown file and an index.qmd file that includes it.}
#'     \item{embed}{Create an index.qmd file with the markdown content embedded directly.}
#'   }
#' @param rewrite_includes Logical; whether to rewrite Quarto include statements to
#'   account for sections being written to subdirectories. Defaults to TRUE. Set to
#'   FALSE to leave include paths unchanged.
#'
#' @return A character vector of paths to the created files. If there was content before the first split point (for
#'   example YAML front matter), it is saved to `split_preamble.md` beside the input file and its path comes first.
#' @export
#'
#' @examples
#' \dontrun{
#' split_markdown(
#'   "slides.md",
#'   qmd = "separate"
#' )
#' }
split_markdown <- function(markdown_file,
                  output_dir = NULL,
                  split_pattern = "^# ",
                  qmd = c("none", "separate", "embed"),
                  rewrite_includes = TRUE) {

  qmd <- match.arg(qmd)

  if (!file.exists(markdown_file)) {
    stop("File not found: ", markdown_file, call. = FALSE)
  }

  lines <- readLines(markdown_file, warn = FALSE)

  split_idx <- grep(split_pattern, lines)
  if (length(split_idx) == 0) {
    stop("No split points found using split_pattern", call. = FALSE)
  }

  # Content before the first split point (for example YAML front matter) is not part of any section. Keep it in its
  # own file rather than dropping it.
  preamble_lines <- if (split_idx[1] > 1) lines[seq_len(split_idx[1] - 1)] else character()

  split_idx <- c(split_idx, length(lines) + 1)

  sections <- lapply(seq_len(length(split_idx) - 1), function(i) {
    lines[split_idx[i]:(split_idx[i + 1] - 1)]
  })

  headers <- sub("^# +", "", vapply(sections, `[[`, "", 1))

  slugify <- function(x) {
    tolower(x) %>%
      gsub("[^a-z0-9]+", "-", x = .) %>%
      gsub("(^-|-$)", "", x = .)
  }

  # Section folders come from the headings. Empty slugs get a name, and repeated headings get a numeric suffix so
  # that two sections with the same heading don't write to the same folder.
  slugs <- slugify(headers)
  slugs[!nzchar(slugs)] <- "section"
  # Position of each slug among those with the same name (1 for the first, 2 for the second, ...)
  repeat_n <- vapply(seq_along(slugs), function(i) sum(slugs[seq_len(i)] == slugs[i]), integer(1))
  slugs <- ifelse(repeat_n > 1, paste0(slugs, "-", repeat_n), slugs)

  if (is.null(output_dir)) {
    output_dirs <- slugs
  } else if (length(output_dir) == 1) {
    # One parent folder: each section gets its own subfolder inside it
    output_dirs <- file.path(output_dir, slugs)
  } else {
    if (length(output_dir) != length(sections)) {
      stop("Length of output_dir must equal number of splits", call. = FALSE)
    }
    output_dirs <- output_dir
  }

  rewrite_include_paths <- function(lines, depth = 1) {
    prefix <- paste(rep("..", depth), collapse = "/")
    prefix <- paste0(prefix, "/")

    gsub(
      "\\{\\{<\\s*include\\s+([^ >]+)\\s*>\\}\\}",
      paste0("{{< include ", prefix, "\\1 >}}"),
      lines
    )
  }

  output_paths <- character(length(sections))

  preamble_path <- NULL
  if (any(nzchar(trimws(preamble_lines)))) {
    preamble_path <- file.path(dirname(markdown_file), "split_preamble.md")
    writeLines(preamble_lines, preamble_path)
    cli::cli_inform(
      "Content before the first split point was saved to {.file {preamble_path}} rather than dropped."
    )
  }

  for (i in seq_along(sections)) {

    dir <- output_dirs[i]
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)

    section <- sections[[i]]
    title <- headers[i]

    md_body <- if (qmd == "none") section else section[-1]

    if (qmd != "none" && rewrite_includes == TRUE) {
      md_body <- rewrite_include_paths(md_body, depth = 1)
    }

    if (qmd == "embed") {

      qmd_lines <- c(
        "---",
        paste0("title: ", .yaml_string(title)),
        paste0("order: ", i),
        "---",
        "",
        md_body
      )

      out <- file.path(dir, "index.qmd")
      writeLines(qmd_lines, out)

    } else {

      md_path <- file.path(dir, "output.md")
      writeLines(md_body, md_path)
      out <- md_path

      if (qmd == "separate") {
        qmd_lines <- c(
          "---",
          paste0("title: ", .yaml_string(title)),
          paste0("order: ", i),
          "---",
          "",
          "{{< include output.md >}}"
        )

        writeLines(qmd_lines, file.path(dir, "index.qmd"))
      }
    }

    output_paths[i] <- out
  }

  c(preamble_path, output_paths)
}

#' Quote a string for YAML (internal)
#'
#' Wraps the value in double quotes, escaping backslashes and double quotes, so titles containing `"` or `\`
#' don't break the front matter.
#' @keywords internal
#' @noRd
.yaml_string <- function(x) {
	x <- gsub("\\\\", "\\\\\\\\", x)
	x <- gsub("\"", "\\\\\"", x)
	paste0("\"", x, "\"")
}
