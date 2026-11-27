#' Convert, clean and fill a document in one call
#'
#' @description
#' Runs [convert_markdown()], [clean_markdown()] and [replace_placeholders()] in turn. Each step reads the file the
#' step before it wrote, so if you give `clean_markdown()` an `output_file`, that's the file that gets filled.
#'
#' Pass any argument the three functions take, by name, and it goes to whichever function has it (an argument such
#' as `placeholder_prefix` goes to both functions that use it). Anything you leave out uses that function's
#' default. An argument none of them recognises, or one without a name, is an error, so a typo is caught.
#'
#' If `input_file` is a folder, the newest Word or PowerPoint file in it is used (see [latest_word_file()]).
#'
#' @param ... Named arguments for [convert_markdown()], [clean_markdown()] and [replace_placeholders()].
#' @param base_name Optional. When `input_file` is a folder, only consider files whose names start with this text.
#'
#' @examples
#' \dontrun{
#' run_workflow(
#'   input_file = "drafts",
#'   base_name = "report",
#'   markdown_file = "report.md",
#'   placeholder_prefix = "placeholder_",
#'   heading_offset = TRUE,
#'   code_content = placeholder_map(specs = list(plot))
#' )
#' }
#'
#' @return The filled Markdown, invisibly, as a character string.
#' @family workflow
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
