#' Find the newest Word or PowerPoint file in a folder
#'
#' @description
#' Returns the path to the newest `.docx` or `.pptx` file in `dir`, so a workflow can pick up the latest version
#' a writer has saved. Lock files Word creates while a document is open (names starting with `~$`) are ignored.
#'
#' @param dir Folder to search. Defaults to the working directory.
#' @param base_name Optional. Only files whose name starts with this text are considered, for example
#'   `"report"` matches `report.docx` and `report_1031.docx`.
#' @param ext File extensions to consider. Defaults to `c("docx", "pptx")`.
#'
#' @return The path to the newest matching file, as a character string. Errors if no file matches.
#' @family versions
#' @export
#'
#' @examples
#' \dontrun{
#' input <- latest_word_file("drafts", base_name = "report")
#' convert_markdown(input, markdown_file = "report.md")
#' }
latest_word_file <- function(dir = ".", base_name = NULL, ext = c("docx", "pptx")) {
	if (!dir.exists(dir)) {
		stop("Folder not found: ", dir, call. = FALSE)
	}

	pattern <- paste0("\\.(", paste(tolower(ext), collapse = "|"), ")$")
	files <- list.files(dir, full.names = TRUE)
	files <- files[grepl(pattern, tolower(basename(files)))]
	files <- files[!startsWith(basename(files), "~$")]

	if (!is.null(base_name)) {
		files <- files[startsWith(basename(files), base_name)]
	}

	if (length(files) == 0L) {
		stop(
			"No ", paste(ext, collapse = " or "), " file found in ", dir,
			if (!is.null(base_name)) paste0(" starting with '", base_name, "'"),
			".",
			call. = FALSE
		)
	}

	mtimes <- file.info(files)$mtime
	files[which.max(mtimes)]
}

#' Add the date and time to a file name
#'
#' @description
#' Adds the current time to a file name, for example `report.docx` becomes `report_20261127_093015.docx`, so each
#' output is kept and the input is never overwritten. If a file with that name already exists (for example two
#' outputs made in the same second), a counter is added: `report_20261127_093015_2.docx`.
#'
#' @param path Path to the file the name is based on. Only its folder, base name and extension are used.
#' @param time The time to stamp. Defaults to now.
#' @param format A `strftime()` format for the stamp. Defaults to `"%Y%m%d_%H%M%S"`.
#'
#' @return A path that does not yet exist.
#' @family versions
#' @export
#'
#' @examples
#' \dontrun{
#' out <- timestamped_path("output/report.docx")
#' }
timestamped_path <- function(path, time = Sys.time(), format = "%Y%m%d_%H%M%S") {
	dir <- dirname(path)
	ext <- tools::file_ext(path)
	base <- tools::file_path_sans_ext(basename(path))
	stamp <- format(time, format)
	stem <- paste0(base, "_", stamp)

	candidate <- file.path(dir, paste0(stem, if (nzchar(ext)) paste0(".", ext) else ""))
	n <- 1L
	while (file.exists(candidate)) {
		n <- n + 1L
		candidate <- file.path(dir, paste0(stem, "_", n, if (nzchar(ext)) paste0(".", ext) else ""))
	}
	candidate
}

#' Stop before writing over an existing file when overwriting is turned off (internal)
#'
#' @param path The file about to be written.
#' @param overwrite Logical. If `TRUE` nothing is checked.
#' @keywords internal
#' @noRd
check_overwrite <- function(path, overwrite) {
	if (!isTRUE(overwrite) && file.exists(path)) {
		stop(
			"`", path, "` already exists and `overwrite = FALSE`. Use `timestamped_path()` for a new name, ",
			"or set `overwrite = TRUE`.",
			call. = FALSE
		)
	}
	invisible(path)
}
