#' Minimum Pandoc version needed to convert .pptx files (internal)
#' @keywords internal
#' @noRd
.pandoc_min_version <- function() numeric_version("3.8.3")

#' Read the version of a Pandoc binary (internal)
#'
#' @param bin Path to a pandoc executable.
#' @return A `numeric_version`, or `NULL` if the binary can't be run or reports no version.
#' @keywords internal
#' @noRd
.pandoc_version_at <- function(bin) {
	out <- tryCatch(
		suppressWarnings(system2(bin, "--version", stdout = TRUE, stderr = FALSE)),
		error = function(e) character()
	)
	if (!length(out)) {
		return(NULL)
	}
	v <- regmatches(out[1], regexpr("[0-9]+(\\.[0-9]+)+", out[1]))
	if (length(v) != 1L) {
		return(NULL)
	}
	numeric_version(v)
}

#' Locate Pandoc binaries bundled with RStudio/Positron or Quarto (internal)
#'
#' Checks the `RSTUDIO_PANDOC` directory and the `tools` folder beside the Quarto binary.
#'
#' @return Character vector of existing pandoc executables, possibly empty.
#' @keywords internal
#' @noRd
.bundled_pandoc_bins <- function() {
	dirs <- Sys.getenv("RSTUDIO_PANDOC", unset = "")

	if (requireNamespace("quarto", quietly = TRUE)) {
		qp <- tryCatch(quarto::quarto_path(), error = function(e) NA_character_)
		if (!is.na(qp)) {
			dirs <- c(dirs, file.path(dirname(qp), "tools"))
		}
	}

	dirs <- dirs[nzchar(dirs)]
	exe <- if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc"
	bins <- file.path(dirs, exe)
	bins[file.exists(bins)]
}

#' Choose the Pandoc to use (internal)
#'
#' Shared by [convert_markdown()] and the package start-up check, so both agree on what counts as usable.
#' If `pandoc_version` is `"default"` and the default Pandoc is missing or older than 3.8.3, a bundled Pandoc from
#' `RSTUDIO_PANDOC` or Quarto is used when it meets the minimum. Other version selections never fall back.
#'
#' @param pandoc_version The version requested, as passed to `pandoc::pandoc_version()`.
#' @return A list with `ver` (the version that will be used, or `numeric_version("0")` if none found),
#'   `binary` (path to a fallback executable, or `NULL` to use `pandoc::pandoc_run()`), and `fallback`
#'   (`TRUE` if a bundled binary was selected).
#' @keywords internal
#' @noRd
.resolve_pandoc <- function(pandoc_version = "default") {
	min_ver <- .pandoc_min_version()
	ver <- tryCatch(pandoc::pandoc_version(pandoc_version), error = function(e) NULL)

	if (!is.null(ver) && ver >= min_ver) {
		# For "default", run the executable that was checked. pandoc::pandoc_run(version = "default") can fail to
		# locate the binary even when pandoc_version() reports it, so use the one on PATH directly.
		binary <- if (identical(pandoc_version, "default")) unname(Sys.which("pandoc")) else ""
		return(list(ver = ver, binary = if (nzchar(binary)) binary else NULL, fallback = FALSE))
	}

	if (identical(pandoc_version, "default")) {
		for (bin in .bundled_pandoc_bins()) {
			bundled <- .pandoc_version_at(bin)
			if (!is.null(bundled) && bundled >= min_ver) {
				return(list(ver = bundled, binary = bin, fallback = TRUE))
			}
		}
	}

	list(ver = if (is.null(ver)) numeric_version("0") else ver, binary = NULL, fallback = FALSE)
}
