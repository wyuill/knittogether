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
#'   can change citation escaping, so `clean(clean_citations = TRUE)` may be
#'   useful downstream. Defaults to `NULL`.
#'
#' @param pandoc_version
#'   Pandoc version to use. Passed directly to `pandoc::pandoc_run()`. Defaults to `"default"`.
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
#'   convert("report.docx", pandoc_version = "latest")
#'   convert("slides.pptx", media_base_dir = "slides_output")
#' }
#'
#' @export
convert <- function(
	input_file,
	markdown_file = "markdown_output.md",
	media_base_dir = ".",
	pandoc_args = NULL,
	pandoc_version = "default",
	verbose = FALSE
) {
	# Check inputs and dependencies
	if (!file.exists(input_file)) {
		stop("File not found: ", input_file, call. = FALSE)
	}

	ext <- tolower(tools::file_ext(input_file))
	if (!ext %in% c("docx", "pptx")) {
		stop("`input_file` must be a .docx or .pptx file: ", input_file, call. = FALSE)
	}

	if (identical(ext, "pptx")) {
		min_ver <- numeric_version("3.8.3")
		ver_sel <- tryCatch(pandoc::pandoc_version(pandoc_version), error = function(e) numeric_version("0"))

		if (ver_sel < min_ver) {
			cli::cli_warn(c(
				"!" = "The {.str {as.character(pandoc_version)}} pandoc version selected ({.val {as.character(ver_sel)}}) is below that required {.val 3.8.3} for .pptx file conversion.",
				"i" = "This may result in failures or unexpected outputs",
				">" = "You can update your version of pandoc using the {.pkg pandoc} package and running {.run pandoc::pandoc_install()}.\nYou may need to tell R about this new version by running {.run pandoc::pandoc_activate()}."
			))
		}
	}

	media_path <- NULL
	media_base_dir_abs <- NULL

	if (!is.null(media_base_dir)) {
		media <- paste0("--extract-media=", shQuote(media_base_dir))
		media_base_dir_abs <- normalizePath(media_base_dir, mustWork = FALSE)
	} else {
		media <- NULL
	}

	pandoc_cmd <- c(shQuote(input_file), "-o", shQuote(markdown_file), media, pandoc_args)

	if (verbose) {
		cli::cli_inform(
			"Running pandoc with: {.code {paste(pandoc_cmd, collapse=' ')}}.
                    Media, if present and requested, is available at {.code {media_path}}."
		)
	}

	pandoc::pandoc_run(pandoc_cmd, version = pandoc_version)

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
