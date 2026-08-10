#' This function is a wrapper for the full knittogether workflow
#'
#' @description This function calls the [convert()], [clean()], and [replace()] functions to extract docx or pptx
#' content to markdown, clean this markdown, and then replace any placeholders with code generated content, simplifying
#' using the workflow.
#'
#' @details
#' The wrapper determines which arguments belong to which function by matching argument names against the formal
#' arguments of [convert()], [replace()], and [clean()]. Arguments not recognised by any function will be ignored.
#' Defaults for all parameters are taken from the underlying functions.
#'
#' @param ... Additional arguments passed to the underlying functions
#'
#' @return Invisibly returns the updated Markdown (character vector).
#'
#' @seealso [convert()], [replace()], [clean()]
#' @export
run_workflow <- function(...) {
	dots <- list(...)

	convert_args <- dots[names(dots) %in% names(formals(convert))]
	clean_args <- dots[names(dots) %in% names(formals(clean))]
	replace_args <- dots[names(dots) %in% names(formals(replace))]

	do.call(convert, convert_args)
	do.call(clean, clean_args)
	output <- do.call(replace, replace_args)

	invisible(output)
}
