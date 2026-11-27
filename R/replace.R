#' Define a content specification for insertion into a document
#'
#' @description
#' `define_content()` creates a structured object describing how a piece of content should be inserted into a
#' Markdown/Quarto document. The `content` is captured as an **unevaluated expression** and later rendered by downstream
#' tooling (e.g., knitr/Quarto).
#'
#' @param description
#'    An optional label describing the content for ease of validating the content is in the correct place.
#' @param placeholder_id
#'    A slug identifying the placeholder (e.g., `"plot1"`). The full placeholder matched in the Markdown file will be
#'   `paste0(placeholder_prefix, "_", placeholder_id)`.
#' @param output_mode
#'    One of:
#'      \itemize{
#'         \item `"inline"` – insert a knitr inline expression using the R engine `` `r <expr>` ``.
#'         \item `"chunk"`  – insert a fenced code block. Chunk language defaults to R but can be overridden via `chunk_options$engine`.
#'         \item `"asis"`   – insert literal text. If `content` is a character literal, it is inserted as-is; otherwise the
#'           expression is deparsed to text and inserted.
#'       }
#' @param content
#'    A quoted or unquoted R expression (captured, not executed). For `"inline"` and `"chunk"`, this expression is
#'    emitted for knitr/Quarto to evaluate. For when `output_mode` is set to `"asis"`, `content` is inserted directly;
#'    otherwise, the expression is deparsed to text.
#' @param content_type
#'    An optional human-readable type (e.g., `"plot"`, `"table"`, `"qmd"`) used for ease of validation.
#' @param chunk_options
#'    Named list of chunk options when `output_mode = "chunk"`.
#'      \itemize{
#'        \item `engine` (default `"r"`) to select language.
#'        \item `as_child = TRUE` to write a child `.qmd` and include it with
#'          `{{< include child_<slug>.qmd >}}` instead of inlining the chunk.
#'        \item `child_dir` optional subdirectory to store child files relative
#'           to the parent markdown file.
#'        \item Any other knitr options, e.g. `echo = FALSE`, `fig.width = 7`.
#'      }
#'
#' @examples
#' \dontrun{
#' spec <- define_content(
#'   description     = "A plot of mtcars",
#'   placeholder_id  = "mtcarsplot",
#'   output_mode     = "chunk",
#'   content         = { plot(mtcars$wt, mtcars$mpg) },
#'   content_type    = "plot",
#'   chunk_options   = list(echo = FALSE, fig.width = 7)
#' )
#' }
#'
#' @return A `"content_spec"` object.
#'
#' @export
define_content <- function(
	description = NULL,
	placeholder_id,
	output_mode = c("inline", "chunk", "asis"),
	content,
	content_type = NULL,
	chunk_options = list()
) {
	output_mode <- match.arg(output_mode)

	# enexpr() (rather than substitute()) so `content` can be passed through a function or injected with `!!`,
	# for example inside lapply().
	structure(
		list(
			description = description,
			placeholder_id = placeholder_id,
			output_mode = output_mode,
			content_expr = rlang::enexpr(content),
			content_type = content_type,
			chunk_options = chunk_options
		),
		class = c("content_spec", "list")
	)
}

#' Create a list of Placeholders with their Content for [replace_placeholders()]
#'
#' @description
#' Constructs a named list for use in [replace_placeholders()] by:
#'
#' * extracting slugs from each `content_spec` in `specs`;
#' * using names of scalar values from `scalars`.
#'
#' @param specs
#'    A list of `content_spec` objects (unnamed).
#' @param scalars
#'    A named list of scalar values. Names become slugs.
#'
#' @examples
#' \dontrun{
#' spec1 <- define_content("A plot", "plot1", "chunk", { plot(1:10) }, "plot")
#' spec2 <- define_content("A table", "table1", "asis", mtcars[1:5, 1:5], "table")
#' map <- placeholder_map(specs = list(spec1, spec2), scalars = list(version = "0.1.0"))
#' }
#'
#' @return A named list mapping slugs to scalars or `content_spec`s.
#'
#' @export
placeholder_map <- function(specs = list(), scalars = list()) {
	# Validate scalars are named
	if (length(scalars) > 0 && is.null(names(scalars))) {
		stop("`scalars` must be a *named* list.")
	}

	# Specs: extract slugs
	spec_entries <- list()

	if (length(specs) > 0) {
		for (obj in specs) {
			if (!inherits(obj, "content_spec")) {
				stop("All elements in `specs` must be content_spec objects.")
			}

			slug <- obj$placeholder_id

			if (!is.character(slug) || length(slug) != 1L) {
				stop("`placeholder_id` must be a single-character string.")
			}

			if (slug %in% names(scalars)) {
				stop("Slug collision: '", slug, "' appears in both specs and scalars.")
			}

			if (slug %in% names(spec_entries)) {
				stop("Duplicate slug in specs: '", slug, "'. Each placeholder_id must be unique.")
			}

			spec_entries[[slug]] <- obj
		}
	}

	c(spec_entries, scalars)
}

#' Detect whether an object is a content_spec
#'
#' @keywords internal
.is_content_spec <- function(x) {
	inherits(x, "content_spec")
}

#' Deparse an expression to a single string
#'
#' Uses a high width cutoff and collapses multiple lines.
#'
#' @keywords internal
.deparse1 <- function(expr) {
	paste(deparse(expr, width.cutoff = 500), collapse = "\n")
}

#' Format an expression as an inline knitr `r` expression
#'
#' Collapses whitespace and newlines to produce: 'r expr'
#'
#' @keywords internal
.format_inline_expr <- function(expr) {
	one <- gsub("[\r\n]+", " ", .deparse1(expr))
	one <- gsub("\\s+", " ", one)
	sprintf("`r %s`", one)
}

#' Text of a chunk body, with a top-level `{ }` block unwrapped
#'
#' knitr prints only the last value of a `{ ... }` block, so each statement is written on its own line instead.
#'
#' @keywords internal
.chunk_body <- function(expr) {
	if (is.call(expr) && identical(expr[[1]], as.name("{"))) {
		statements <- as.list(expr)[-1]
		return(paste(vapply(statements, .deparse1, character(1)), collapse = "\n"))
	}
	.deparse1(expr)
}

#' Convert an R object to a chunk option value string
#'
#' This is needed because knitr options require literal text.
#'
#' @keywords internal
.stringify_chunk_value <- function(x) {
	if (isTRUE(x) || identical(x, FALSE)) {
		return(if (x) "TRUE" else "FALSE")
	}
	if (is.numeric(x)) {
		return(as.character(x))
	}
	if (is.character(x)) {
		return(sprintf('"%s"', x))
	}
	.deparse1(x)
}

#' Combine chunk options into a single `name=value, ...` string
#'
#' @keywords internal
.combine_chunk_options <- function(opts) {
	if (length(opts) == 0) {
		return("")
	}
	paste(mapply(function(n, v) sprintf("%s=%s", n, .stringify_chunk_value(v)), names(opts), opts), collapse = ", ")
}

#' Extract the engine from a chunk options list (default "r")
#'
#' @keywords internal
.get_engine <- function(opts) {
	if ("engine" %in% names(opts)) opts$engine else "r"
}

#' Format an expression as a fenced code block for knitr
#'
#' @keywords internal
.format_chunk_expr <- function(expr, slug, chunk_options) {
	paste0("```", .chunk_header(slug, chunk_options), "\n", .chunk_body(expr), "\n```")
}

#' Build the knitr chunk header, e.g. `{r plot, echo=FALSE}`
#'
#' Shared by inline chunks and child files. Options that control how knittogether writes the chunk (`engine`,
#' `as_child`, `child_dir`) are not knitr options, so they are dropped here.
#'
#' @keywords internal
.chunk_header <- function(slug, chunk_options) {
	engine <- .get_engine(chunk_options)
	knitr_opts <- chunk_options[setdiff(names(chunk_options), c("engine", "as_child", "child_dir"))]
	opt_str <- .combine_chunk_options(knitr_opts)

	if (nzchar(opt_str)) {
		sprintf("{%s %s, %s}", engine, slug, opt_str)
	} else {
		sprintf("{%s %s}", engine, slug)
	}
}

#' Sanitize a filename for writing child qmds
#'
#' @keywords internal
.sanitize_fname <- function(x) {
	gsub("[^A-Za-z0-9_.-]", "_", x)
}

#' Write a child .qmd file to disk
#'
#' Called by replace_placeholders() when a chunk uses `as_child = TRUE`.
#'
#' @keywords internal
.write_child_qmd <- function(parent_md_path, slug, expr, chunk_options = list(), child_dir = NULL, overwrite = TRUE) {
	base_dir <- dirname(normalizePath(parent_md_path))
	dir_out <- if (is.null(child_dir)) base_dir else file.path(base_dir, child_dir)
	if (!dir.exists(dir_out)) {
		dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)
	}

	fname <- paste0("child_", .sanitize_fname(slug), ".qmd")
	path <- file.path(dir_out, fname)

	if (file.exists(path) && !overwrite) {
		stop("Child qmd already exists and overwrite=FALSE: ", path, call. = FALSE)
	}

	child_text <- c(paste0("```", .chunk_header(slug, chunk_options)), .chunk_body(expr), "```")

	writeLines(child_text, path, useBytes = TRUE)

	# Return path relative to the parent document
	if (is.null(child_dir)) basename(path) else file.path(child_dir, basename(path))
}


#' Regular expression matching a placeholder token as a whole word
#'
#' Matches `token` literally, but only where it is not part of a longer identifier, so `placeholder_content_plot`
#' does not match inside `placeholder_content_plot_2` or `my_placeholder_content_plot`.
#'
#' @keywords internal
#' @noRd
.token_regex <- function(token) {
	paste0("(?<![A-Za-z0-9_])", .regex_escape(token), "(?![A-Za-z0-9_])")
}

#' Escape regex metacharacters in a literal string
#'
#' @keywords internal
#' @noRd
.regex_escape <- function(x) {
	gsub("([.|()\\^{}+$*?\\[\\]\\\\])", "\\\\\\1", x)
}

#' Reduce existing draft blocks to their bare placeholders
#'
#' A draft block is the R output between the draft markers, with the placeholder marker as its first line. When
#' `draft_mode = FALSE`, each block whose first line is a marker is replaced by that bare placeholder, so the normal
#' replacement fills it in without leaving draft markers. Blocks without a marker are left unchanged.
#'
#' @keywords internal
#' @noRd
.strip_draft_blocks <- function(text, placeholder_prefix, draft_mode_prefix, draft_mode_suffix) {
	block_re <- paste0("(?s)", .regex_escape(draft_mode_prefix), "\n(.*?)\n", .regex_escape(draft_mode_suffix))
	marker_re <- paste0("^\\[(", .regex_escape(placeholder_prefix), "_[^\\]]+)\\]\\{.*\\}$")

	m <- gregexpr(block_re, text, perl = TRUE)
	blocks <- regmatches(text, m)[[1]]
	if (!length(blocks)) {
		return(text)
	}

	bare <- vapply(blocks, function(b) {
		inner <- sub(paste0("^", block_re, "$"), "\\1", b, perl = TRUE)
		first <- strsplit(inner, "\n", fixed = TRUE)[[1]][1]
		if (!is.na(first) && grepl(marker_re, first, perl = TRUE)) {
			sub(marker_re, "\\1", first, perl = TRUE)
		} else {
			b
		}
	}, character(1))

	regmatches(text, m) <- list(bare)
	text
}

#' Build a placeholder marker span
#'
#' Constructs a Pandoc-style span representing a placeholder marker with styling applied according to `marker_mode` in [replace_placeholders()].
#'
#' @keywords internal
.build_marker <- function(token, marker_mode, style_hidden, style_visible) {
	if (identical(marker_mode, "off")) {
		return("")
	}

	cs <- if (identical(marker_mode, "show")) style_visible else style_hidden

	sprintf("[%s]{custom-style=\"%s\"}", token, cs)
}

#' Append a placeholder marker to rendered content
#'
#' Attaches a marker (built via `.build_marker()`) to the rendered replacement body.
#'
#' @keywords internal
.append_marker <- function(body, token, output_mode, marker_mode, style_hidden, style_visible) {
	if (identical(marker_mode, "off")) {
		return(body)
	}

	marker <- .build_marker(
		token = token,
		marker_mode = marker_mode,
		style_hidden = style_hidden,
		style_visible = style_visible
	)

	if (output_mode %in% c("inline", "asis")) {
		paste0(body, " ", marker)
	} else {
		paste(body, marker, sep = "\n")
	}
}

#' Replace placeholders in a Markdown / Quarto document
#'
#' @description
#' Replace tokens of the form `<placeholder_prefix>_<slug>` using scalars or `content_spec` from `define_content()`.
#' Execution is deferred to knitr/Quarto.
#'
#' ## Marker behavior
#' One (and only one) marker is emitted per replacement, **independent of `draft_mode`**,
#' controlled by `marker_mode`:
#' - `"hidden"` (default): `[token]{custom-style="PlaceholderMarker"}`
#' - `"show"`:             `[token]{custom-style="PlaceholderMarkerVisible"}`
#' - `"off"`:              *(no marker)*
#'
#' For DOCX, define both character styles in your reference DOCX. For HTML, hide hidden markers by including the
#' following CSS in your document: `span[data-custom-style="PlaceholderMarker"] { display: none !important; }`
#'
#' ## Draft mode
#' If `draft_mode = TRUE`, the placeholder is bookended with markers. For example, a block would appear as:
#' ```
#' DRAFT_CONTENT_START
#' <marker if any>
#' <content>
#' DRAFT_CONTENT_END
#' ```
#'
#' @inheritParams generate_quality_check
#' @param markdown_file
#'    Path to the Markdown/Quarto file (overwritten).
#' @param placeholder_prefix
#'    Character prefix identifying the placeholder. Defaults to `"placeholder_content"`.
#' @param code_content
#'    Named list mapping slugs to scalars or `content_spec`. Defaults to an empty list.
#' @param draft_mode
#'    Logical; if `TRUE`, wrap in plain draft markers. Defaults to `TRUE`. Keep this on for any document that will be
#'    read back from Word: the draft markers are how the inserted content is found and cleared on the next pass
#'    (see [clean_markdown()]). With `FALSE` the output has no draft markers: any draft blocks already in the file are
#'    reduced to their placeholders and filled in, so a final render can be run straight from a draft.
#' @param draft_mode_prefix,draft_mode_suffix
#'    Strings for draft boundaries. Defaults to `"DRAFT_CONTENT_START"` and `"DRAFT_CONTENT_END"` respectively. These
#'    are used instead of `--DRAFT_CONTENT--` because Word turns `--` into a dash, which stopped the markers being
#'    found on re-import. Documents made with the old markers need them replaced before they are cleaned.
#' @param validation_path
#'    Optional directory for a CSV log of what has been replaced. Setting this to `NULL` disables the creation of the log.
#'    Defaults to `NULL`.
#' @param marker_mode
#'    Controls the styling, if any, applied to placeholder markers. One of:
#'    * `"hidden"` (default) where markers are included but the `PlaceholderMarker` style is applied, for example,
#'      `[placeholder_content_value]{custom-style="PlaceholderMarker"}`,
#'    * `"show"` where markers are included and the `PlaceholderMarkerVisible` style is applied, for example,
#'      `[placeholder_content_value]{custom-style="PlaceholderMarkerVisible"}`,
#'    * `"off"` where no marker is written at all. Nothing is left in the document to say where the inserted content came
#'      from. Use this only when the document will not be read back in from Word, because content inserted with `"off"`
#'      cannot be found and refreshed on a later import. The marker is not replaced with a plain placeholder token; the
#'      inserted content is all that remains.
#'    The names of the relevant styles are defined in `placeholder_style_hidden` and `placeholder_style_visible`.
#' @param placeholder_style_hidden,placeholder_style_visible
#'    The names of the styles used for hidden/visible markers as applied in `marker_mode`. Defaults to
#'    `"PlaceholderMarker"` and `"PlaceholderMarkerVisible"` respectively. An example of a Word document
#'    with these styles is included within the package. Run the following code to access it:
#' \preformatted{
#' path <- system.file("extdata", "PlaceholderMarker_example.docx",
#'                     package = "knittogether")
#' utils::browseURL(path)
#' }
#'
#' @param output_file
#'    Optional path to write the result to. `markdown_file` is then left unchanged, and `output_file_ext` is
#'    ignored. Defaults to `NULL`, which writes next to `markdown_file` as before.
#' @param overwrite
#'    Logical; if `FALSE`, stop rather than write over an existing output file. Defaults to `TRUE`, so existing
#'    scripts keep overwriting. Use [timestamped_path()] to keep earlier versions.
#'
#' @param output_file_ext
#'    The extension for the output file. Typically, `'md'` but Quarto can sometimes raise errors if it detects
#'    executable code in markdown and require a '.qmd' file instead, regardless of whether there is executable code
#'    present. Defaults to `'md'`.
#'
#' @examples
#' \dontrun{
#' spec <- define_content(
#'   description     = "A plot of mtcars",
#'   placeholder_id  = "mtcarsplot",
#'   output_mode     = "chunk",
#'   content         = { plot(mtcars$wt, mtcars$mpg) },
#'   content_type    = "plot",
#'   chunk_options   = list(echo = FALSE, fig.width = 7)
#' )
#' code_map <- placeholder_map(specs = list(spec))
#' replace_placeholders(
#'   markdown_file = "markdown_output.md",
#'   placeholder_prefix = "placeholder_content",
#'   code_content = code_map,
#'   draft_mode = TRUE,
#'   draft_mode_prefix = "DRAFT_CONTENT_START",
#'   draft_mode_suffix = "DRAFT_CONTENT_END",
#'   validation_path = "validation",
#'   marker_mode = "hidden",
#'   placeholder_style_hidden = "PlaceholderMarker",
#'   placeholder_style_visible = "PlaceholderMarkerVisible"
#'   )
#' }
#'
#' @return Invisibly returns the updated Markdown (character vector).
#'
#' @export
replace_placeholders <- function(
	markdown_file,
	placeholder_prefix = "placeholder_content",
	code_content = list(),
	draft_mode = TRUE,
	draft_mode_prefix = "DRAFT_CONTENT_START",
	draft_mode_suffix = "DRAFT_CONTENT_END",
	validation_path = NULL,
	marker_mode = c("hidden", "show", "off"),
	placeholder_style_hidden = "PlaceholderMarker",
	placeholder_style_visible = "PlaceholderMarkerVisible",
	log_file = "quality_log.csv",
	html_file = "validation.html",
	output_file_ext = "md",
	output_file = NULL,
	overwrite = TRUE
) {
	marker_mode <- match.arg(marker_mode)

	if (!file.exists(markdown_file)) {
		stop("Markdown file does not exist: ", markdown_file, call. = FALSE)
	}
	if (!is.list(code_content) || is.null(names(code_content))) {
		stop("`code_content` must be a *named* list.", call. = FALSE)
	}

	text <- paste(readLines(markdown_file, warn = FALSE), collapse = "\n")

	# Draft mode off: draft blocks from an earlier draft pass are reduced to their placeholders first,
	# so the output has no draft markers
	if (!draft_mode) {
		text <- .strip_draft_blocks(text, placeholder_prefix, draft_mode_prefix, draft_mode_suffix)
	}

	log <- data.frame(
		slug = character(),
		token = character(),
		found = logical(),
		replaced = integer(),
		kind = character(),
		output_mode = character(),
		stringsAsFactors = FALSE
	)

	# Main replacement loop. Longest slugs first, and each token is matched as a whole word, so that
	# `placeholder_content_plot` never matches inside `placeholder_content_plot_2`.
	slugs <- names(code_content)
	slugs <- slugs[order(-nchar(slugs))]

	for (slug in slugs) {
		val <- code_content[[slug]]
		token <- paste0(placeholder_prefix, "_", slug)
		token_re <- .token_regex(token)

		found <- grepl(token_re, text, perl = TRUE)
		n_matches <- if (found) sum(gregexpr(token_re, text, perl = TRUE)[[1]] > 0) else 0L

		if (!found) {
			log <- rbind(
				log,
				data.frame(
					slug,
					token,
					found = FALSE,
					replaced = 0,
					kind = if (.is_content_spec(val)) "content_spec" else "scalar",
					output_mode = if (.is_content_spec(val)) val$output_mode else "inline",
					stringsAsFactors = FALSE
				)
			)
			next
		}

		# Build the replacement body
		if (.is_content_spec(val)) {
			mode <- val$output_mode
			kind <- "content_spec"

			if (mode == "inline") {
				body <- .format_inline_expr(val$content_expr)
			} else if (mode == "chunk") {
				as_child <- isTRUE(val$chunk_options$as_child)
				child_dir <- val$chunk_options$child_dir %||% NULL

				if (as_child) {
					include_path <- .write_child_qmd(
						parent_md_path = markdown_file,
						slug = slug,
						expr = val$content_expr,
						chunk_options = val$chunk_options,
						child_dir = child_dir,
						overwrite = TRUE
					)
					body <- paste0("{{< include ", include_path, " >}}")
				} else {
					body <- .format_chunk_expr(val$content_expr, slug, val$chunk_options)
				}
			} else if (mode == "asis") {
				if (is.character(val$content_expr) && length(val$content_expr) == 1L) {
					body <- val$content_expr
				} else {
					body <- .deparse1(val$content_expr)
				}
			} else {
				stop("Unknown `output_mode`: ", mode, call. = FALSE)
			}
		} else if (is.atomic(val) && length(val) == 1L) {
			body <- as.character(val)
			mode <- "inline"
			kind <- "scalar"
		} else {
			stop("Invalid value for slug '", slug, "'. Expected scalar or content_spec().", call. = FALSE)
		}

		# Apply markers and draft mode
		make_replacement <- function(body) {
			if (!draft_mode) {
				return(.append_marker(
					body = body,
					token = token,
					output_mode = mode,
					marker_mode = marker_mode,
					style_hidden = placeholder_style_hidden,
					style_visible = placeholder_style_visible
				))
			}
			marker_line <- .build_marker(
				token = token,
				marker_mode = marker_mode,
				style_hidden = placeholder_style_hidden,
				style_visible = placeholder_style_visible
			)
			inner <- if (nzchar(marker_line)) {
				paste0(marker_line, "\n", body)
			} else {
				body
			}
			paste0(draft_mode_prefix, "\n", inner, "\n", draft_mode_suffix)
		}

		# A chunk used more than once needs a distinct label for each copy; a repeated label stops knitr. Each copy
		# is built with its own label (slug, slug_2, slug_3, ...).
		per_occurrence <- .is_content_spec(val) &&
			identical(mode, "chunk") &&
			!isTRUE(val$chunk_options$as_child) &&
			n_matches > 1
		if (per_occurrence) {
			labels <- c(slug, paste0(slug, "_", seq_len(n_matches - 1L) + 1L))
			replacements <- vapply(
				labels,
				function(lbl) make_replacement(.format_chunk_expr(val$content_expr, lbl, val$chunk_options)),
				character(1)
			)
		} else {
			replacements <- rep(make_replacement(body), n_matches)
		}

		# regmatches<- inserts text literally, so backslashes in the content need no escaping
		regmatches(text, gregexpr(token_re, text, perl = TRUE)) <- list(replacements)

		log <- rbind(
			log,
			data.frame(
				slug = slug,
				token = token,
				found = TRUE,
				replaced = n_matches,
				kind = kind,
				output_mode = mode,
				stringsAsFactors = FALSE
			)
		)
	}

	final <- strsplit(text, "\n", fixed = TRUE)[[1]]

	# Allow writing directly to qmd
	ext <- tolower(gsub("^\\.", "", output_file_ext))
	markdown_file2 <- if (is.null(output_file)) paste0(sub("\\.[^.]+$", "", markdown_file), ".", ext) else output_file
	check_overwrite(markdown_file2, overwrite)
	writeLines(final, markdown_file2, useBytes = TRUE)

	# Optional validation
	if (!is.null(validation_path)) {
		generate_quality_check(
			code_content = code_content,
			markdown_file = markdown_file,
			placeholder_prefix = placeholder_prefix,
			validation_path = validation_path,
			log_file = file.path(validation_path, log_file),
			html_file = html_file
		)
	}

	invisible(final)
}
