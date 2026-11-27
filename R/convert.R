#' Convert a Word or PowerPoint file to Markdown using Pandoc
#'
#' @description
#' Converts a Microsoft Word (`.docx`) or PowerPoint (`.pptx`) file to Markdown
#' using Pandoc. Media (e.g., embedded images) and citations can be extracted if
#' requested. The function returns the path to the generated Markdown file and,
#' optionally, the directory where media was saved
#'
#' @param input_file
#'   Path to the input file to convert. Must be a `.docx` or `.pptx` file.
#'
#' @param markdown_file
#'   Path to the output Markdown file. The file will be overwritten if it already exists. Defaults to `"markdown_output.md"`.
#'
#' @param media_base_dir
#'   Path to the **base directory** where extracted media should be saved. Pandoc will create a subfolder named `media/`
#'   inside this directory (e.g., `path/to/base/media/`) and extract all embedded media files here. The directory is
#'   only created if media is present in the input file.
#'
#'   * Set to `NULL` to disable media extraction entirely.
#'   * Set to `"."` (the default) to extract media into the current working directory `./media/`.
#'
#' @param pandoc_args
#'   Additional command-line arguments passed to Pandoc, for example
#'   `"--wrap=none"` or `"--to=markdown+pipe_tables+grid_tables"`.
#'   Provide as a single string or character vector. Non-default markdown targets
#'   can change citation escaping, so `clean_markdown(clean_citations = TRUE)` may be
#'   useful downstream. Defaults to `NULL`.
#'
#' @param pandoc_version
#'   Pandoc version to use. Passed directly to `pandoc::pandoc_run()`. Defaults to `"default"`. If the default
#'   Pandoc is missing or older than 3.8.3, a Pandoc bundled with RStudio/Positron (`RSTUDIO_PANDOC`) or Quarto
#'   that meets 3.8.3 is used instead. `"latest"` can select a Pandoc that doesn't match the bundled one, so it is
#'   not the default.
#'
#' @param overwrite
#'   Logical; if `FALSE`, stop rather than write over an existing `markdown_file`. Defaults to `TRUE`. Use
#'   [timestamped_path()] to keep earlier versions.
#'
#' @param verbose
#'   Logical. If `TRUE`, prints informative messages about the Pandoc command being executed and the location of
#'   extracted media (if any). Defaults to `FALSE`.
#'
#' @return
#'   Invisibly returns a named list with:
#'
#'   * `markdown_file` – the path to the created Markdown file
#'   * `media_dir` – the path to the created `media/` directory, or `NULL` if
#'     media extraction was disabled or no media was present
#'
#' @examples
#' \dontrun{
#'   convert_markdown("report.docx", pandoc_version = "latest")
#'   convert_markdown("slides.pptx", media_base_dir = "slides_output")
#' }
#'
#' @export
convert_markdown <- function(
	input_file,
	markdown_file = "markdown_output.md",
	media_base_dir = ".",
	pandoc_args = NULL,
	pandoc_version = "default",
	verbose = FALSE,
	overwrite = TRUE
) {
	# Check inputs and dependencies
	if (!file.exists(input_file)) {
		stop("File not found: ", input_file, call. = FALSE)
	}
	check_overwrite(markdown_file, overwrite)

	ext <- tolower(tools::file_ext(input_file))
	if (!ext %in% c("docx", "pptx")) {
		stop("`input_file` must be a .docx or .pptx file: ", input_file, call. = FALSE)
	}

	pandoc <- .resolve_pandoc(pandoc_version)

	if (identical(ext, "pptx") && pandoc$ver < .pandoc_min_version()) {
		cli::cli_warn(c(
			"!" = "The {.str {as.character(pandoc_version)}} pandoc version selected ({.val {as.character(pandoc$ver)}}) is below that required {.val 3.8.3} for .pptx file conversion.",
			"i" = "This may result in failures or unexpected outputs",
			">" = "You can update your version of pandoc using the {.pkg pandoc} package and running {.run pandoc::pandoc_install()}.\nYou may need to tell R about this new version by running {.run pandoc::pandoc_activate()}."
		))
	}

	media_path <- NULL
	media_base_dir_abs <- NULL

	if (!is.null(media_base_dir)) {
		media <- paste0("--extract-media=", shQuote(media_base_dir))
		media_arg_raw <- paste0("--extract-media=", media_base_dir)
		media_base_dir_abs <- normalizePath(media_base_dir, mustWork = FALSE)
	} else {
		media <- NULL
		media_arg_raw <- NULL
	}

	pandoc_cmd <- c(shQuote(input_file), "-o", shQuote(markdown_file), media, pandoc_args)

	if (verbose) {
		cli::cli_inform(
			"Running pandoc with: {.code {paste(pandoc_cmd, collapse=' ')}}.
                    Media, if present and requested, is available at {.code {media_path}}."
		)
	}

	if (is.null(pandoc$binary)) {
		pandoc::pandoc_run(pandoc_cmd, version = pandoc_version)
	} else {
		# Bundled Pandoc: run the executable directly. system2() quotes arguments itself, so pass them unquoted.
		raw_args <- c(input_file, "-o", markdown_file, media_arg_raw, pandoc_args)
		status <- system2(pandoc$binary, raw_args)
		if (!identical(status, 0L)) {
			stop("Pandoc (", pandoc$binary, ") failed with status ", status, call. = FALSE)
		}
	}

	if (!is.null(media_base_dir_abs)) {
		candidates <- c(
			file.path(media_base_dir_abs, "media"),
			file.path(media_base_dir_abs, "ppt", "media"),
			file.path(media_base_dir_abs, "docx", "media")
		)
		existing <- candidates[dir.exists(candidates)]
		if (length(existing) > 0) {
			media_path <- existing[[1]]
		}
	}

	invisible(list(markdown_file = markdown_file, media_dir = media_path))
}
