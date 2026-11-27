#' This function is a wrapper for the full knittogether workflow
#'
#' @description This function calls the [convert_markdown()], [clean_markdown()], and [replace_placeholders()] functions to extract docx or pptx
#' content to markdown, clean this markdown, and then replace any placeholders with code generated content, simplifying
#' using the workflow.
#'
#' @details
#' The wrapper determines which arguments belong to which function by matching argument names against the formal
#' arguments of [convert_markdown()], [replace_placeholders()], and [clean_markdown()]. Arguments not recognised by any function will be ignored.
#' Defaults for all parameters are taken from the underlying functions.
#'
#' Each step takes the previous step's output as its input. The markdown written by [convert_markdown()] is cleaned,
#' and the file [clean_markdown()] writes (its `output_file`, if one is given) is the file filled in by
#' [replace_placeholders()]. So `output_file` in `clean_markdown` is used, not ignored.
#'
#' If `input_file` is a folder, the newest Word or PowerPoint file in it is used, optionally restricted to names that
#' start with `base_name` (see [latest_word_file()]).
#'
#' @param ... Additional arguments passed to the underlying functions
#' @param base_name Optional. When `input_file` is a folder, only files whose names start with this text are
#'   considered.
#'
#' @return Invisibly returns the updated Markdown (character vector).
#'
#' @seealso [convert_markdown()], [replace_placeholders()], [clean_markdown()], [latest_word_file()]
#' @export
run_workflow <- function(..., base_name = NULL) {
	dots <- list(...)

	# A misspelt argument (e.g. heading_ofset = TRUE) would otherwise be dropped without a word
	known <- unique(c(
		names(formals(convert_markdown)),
		names(formals(clean_markdown)),
		names(formals(replace_placeholders)),
		"base_name"
	))
	arg_names <- names(dots)
	if (length(dots) && (is.null(arg_names) || any(!nzchar(arg_names)))) {
		stop("All arguments to `run_workflow()` must be named.", call. = FALSE)
	}
	unknown <- setdiff(arg_names, known)
	if (length(unknown)) {
		stop(
			"Unrecognised argument(s) to `run_workflow()`: ",
			paste0("`", unknown, "`", collapse = ", "),
			". Check the spelling against `convert_markdown()`, `clean_markdown()` and `replace_placeholders()`.",
			call. = FALSE
		)
	}

	convert_args <- dots[names(dots) %in% names(formals(convert_markdown))]
	clean_args <- dots[names(dots) %in% names(formals(clean_markdown))]
	replace_args <- dots[names(dots) %in% names(formals(replace_placeholders))]

	# A folder as input means "the newest Word file in this folder"
	if (!is.null(convert_args$input_file) && dir.exists(convert_args$input_file)) {
		convert_args$input_file <- latest_word_file(convert_args$input_file, base_name = base_name)
	}

	# Step 1: convert writes markdown, which the later steps then read
	markdown <- if (!is.null(convert_args$markdown_file)) {
		convert_args$markdown_file
	} else {
		formals(convert_markdown)$markdown_file
	}
	convert_args$markdown_file <- markdown
	do.call(convert_markdown, convert_args)

	# Step 2: clean reads that markdown; its output (if output_file is set) becomes the input to step 3
	clean_args$markdown_file <- markdown
	do.call(clean_markdown, clean_args)
	cleaned <- if (!is.null(clean_args$output_file)) clean_args$output_file else markdown

	# Step 3: replace reads the cleaned markdown
	replace_args$markdown_file <- cleaned
	output <- do.call(replace_placeholders, replace_args)

	invisible(output)
}
