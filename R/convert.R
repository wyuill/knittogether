#' Convert a Word or PowerPoint file to Markdown
#'
#' @description
#' Uses Pandoc to turn a `.docx` or `.pptx` file into Markdown, keeping headings, lists, tables, footnotes and
#' citations, and saving the images into a `media/` folder. Run [clean_markdown()] on the result next.
#'
#' @param input_file
#'   Path to the `.docx` or `.pptx` file.
#' @param markdown_file
#'   Path for the Markdown file. Defaults to `"markdown_output.md"`.
#' @param media_base_dir
#'   Folder to save images in. Pandoc creates a `media/` folder inside it, but only if the document has images.
#'   Defaults to `"."`, the working directory. Use `NULL` to skip saving images.
#' @param pandoc_args
#'   Extra Pandoc arguments, as a string or character vector, for example `"--wrap=none"`, or `"-t gfm"` for tables
#'   with long text. Some Markdown flavours add escaping to citations, which `clean_markdown(clean_citations = TRUE)`
#'   removes. Defaults to `NULL`.
#' @param pandoc_version
#'   Which Pandoc to use, passed to `pandoc::pandoc_run()`. Defaults to `"default"`. If that Pandoc is missing or
#'   older than 3.8.3 (needed for PowerPoint), the one bundled with RStudio, Positron or Quarto is used instead.
#' @param verbose
#'   Logical. If `TRUE`, print the Pandoc command and where images were saved. Defaults to `FALSE`.
#' @param overwrite
#'   Logical. If `FALSE`, stop rather than write over an existing `markdown_file`. Defaults to `TRUE`. Use
#'   [timestamped_path()] to keep earlier versions.
#'
#' @return
#'   Invisibly, a list with `markdown_file` (the path to the Markdown) and `media_dir` (the path to the `media/`
#'   folder, or `NULL` if no images were saved).
#'
#' @examples
#' \dontrun{
#' convert_markdown("draft.docx", markdown_file = "draft.md")
#' convert_markdown("slides.pptx", markdown_file = "slides.md", media_base_dir = "slides")
#' }
#'
#' @family workflow
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
