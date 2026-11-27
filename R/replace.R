#' Describe the content for one placeholder
#'
#' @description
#' Says what should replace a placeholder and how it goes in. The code in `content` isn't run now: it's written into
#' the Markdown by [replace_placeholders()] and runs when Quarto renders the document. Collect the results with
#' [placeholder_map()].
#'
#' @param description
#'    Optional. A short description of the content, shown in the validation log to help you check the right output
#'    is in the right place.
#' @param placeholder_id
#'    The part of the placeholder after the prefix. With the default prefix `"placeholder_"`, the ID `"plot"` fills
#'    `placeholder_plot`.
#' @param output_mode
#'    How the content goes in:
#'    * `"inline"` writes inline R code, `` `r <content>` ``, for a value inside a sentence.
#'    * `"chunk"` writes a code chunk on its own line, for plots, tables or anything longer. The chunk is R unless
#'      you set `chunk_options$engine`.
#'    * `"asis"` writes text exactly as given. If `content` is a string it's inserted as it is; otherwise the code
#'      itself is inserted as text, not its result.
#' @param content
#'    The code to insert, for example `{ plot(mtcars$wt, mtcars$mpg) }` or `nrow(mtcars)`. It can also be passed in
#'    from a function or with `!!`, for example inside `lapply()`.
#' @param content_type
#'    Optional. A label such as `"plot"`, `"table"` or `"qmd"`, shown in the validation log.
#' @param chunk_options
#'    A named list of chunk options, used when `output_mode = "chunk"`. Any knitr option works, such as
#'    `echo = FALSE` or `fig.width = 7`. Three more control how the chunk is written:
#'    * `engine`: the chunk language. Defaults to `"r"`.
#'    * `as_child`: if `TRUE`, write the chunk to its own file, `child_<id>.qmd`, and include that file instead.
#'    * `child_dir`: the folder for child files, relative to the Markdown file.
#'
#' @examples
#' plot <- define_content(
#'   placeholder_id = "plot",
#'   description = "Car weight against fuel economy",
#'   output_mode = "chunk",
#'   content = { plot(mtcars$wt, mtcars$mpg) },
#'   chunk_options = list(echo = FALSE, fig.width = 7)
#' )
#'
#' total <- define_content(
#'   placeholder_id = "total",
#'   output_mode = "inline",
#'   content = nrow(mtcars)
#' )
#'
#' @return A `content_spec` object, to pass to [placeholder_map()].
#' @family content
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

#' Collect the content for every placeholder
#'
#' @description
#' Combines content made with [define_content()], and any plain values, into the list that
#' [replace_placeholders()] takes as `code_content`.
#'
#' @param specs
#'    A list of objects made with [define_content()].
#' @param scalars
#'    A named list of plain values, each inserted inline. The name is the placeholder ID, so
#'    `list(total = 42)` fills `placeholder_total`. Quicker than [define_content()], but with no description in the
#'    validation log.
#'
#' @examples
#' plot <- define_content(
#'   placeholder_id = "plot",
#'   output_mode = "chunk",
#'   content = { plot(1:10) }
#' )
#' placeholder_map(specs = list(plot), scalars = list(version = "0.1.0"))
#'
#' @return A named list, with one entry per placeholder ID.
#' @family content
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
#' @noRd
.is_content_spec <- function(x) {
	inherits(x, "content_spec")
}

#' Deparse an expression to a single string
#'
#' Uses a high width cutoff and collapses multiple lines.
#'
#' @keywords internal
#' @noRd
.deparse1 <- function(expr) {
	paste(deparse(expr, width.cutoff = 500), collapse = "\n")
}

#' Format an expression as an inline knitr `r` expression
#'
#' Collapses whitespace and newlines to produce: 'r expr'
#'
#' @keywords internal
#' @noRd
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
#' @noRd
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
#' @noRd
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
#' @noRd
.combine_chunk_options <- function(opts) {
	if (length(opts) == 0) {
		return("")
	}
	paste(mapply(function(n, v) sprintf("%s=%s", n, .stringify_chunk_value(v)), names(opts), opts), collapse = ", ")
}

#' Extract the engine from a chunk options list (default "r")
#'
#' @keywords internal
#' @noRd
.get_engine <- function(opts) {
	if ("engine" %in% names(opts)) opts$engine else "r"
}

#' Format an expression as a fenced code block for knitr
#'
#' @keywords internal
#' @noRd
.format_chunk_expr <- function(expr, slug, chunk_options) {
	paste0("```", .chunk_header(slug, chunk_options), "\n", .chunk_body(expr), "\n```")
}

#' Build the knitr chunk header, e.g. `{r plot, echo=FALSE}`
#'
#' Shared by inline chunks and child files. Options that control how knittogether writes the chunk (`engine`,
#' `as_child`, `child_dir`) are not knitr options, so they are dropped here.
#'
#' @keywords internal
#' @noRd
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
#' @noRd
.sanitize_fname <- function(x) {
	gsub("[^A-Za-z0-9_.-]", "_", x)
}

#' Write a child .qmd file to disk
#'
#' Called by replace_placeholders() when a chunk uses `as_child = TRUE`.
#'
#' @keywords internal
#' @noRd
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
	marker_re <- paste0("^\\[(", .regex_escape(placeholder_prefix), "[^\\]]+)\\]\\{.*\\}$")

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
#' @noRd
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
#' @noRd
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

#' Fill placeholders with R content
#'
#' @description
#' Swaps each placeholder (`placeholder_prefix` followed by an ID) in a Markdown file for the content given in `code_content`.
#' Code isn't run here. It's written into the Markdown as inline R or a chunk, and runs when Quarto renders the
#' document.
#'
#' Each piece of content is written with a marker naming its placeholder (see `marker_mode`) and, in draft mode,
#' wrapped in draft markers:
#'
#' ```
#' DRAFT_CONTENT_START
#' <marker>
#' <content>
#' DRAFT_CONTENT_END
#' ```
#'
#' Together these let [clean_markdown()] turn the content back into its placeholder when the document returns from
#' Word, so it can be filled again. `vignette("knittogether")` explains the round trip.
#'
#' @param markdown_file
#'    Path to the Markdown file to fill.
#' @param placeholder_prefix
#'    The text every placeholder starts with, used exactly as given. The placeholder is the prefix followed by the
#'    ID, so the default `"placeholder_"` with the ID `plot` gives `placeholder_plot`. Choose any prefix that won't
#'    appear by accident in normal writing, such as `"knit_"` or `"xyz_"`. Use the same prefix in [clean_markdown()]
#'    and [replace_placeholders()]. Defaults to `"placeholder_"`.
#' @param code_content
#'    The content for each placeholder, as made by [placeholder_map()].
#' @param draft_mode
#'    Logical. If `TRUE` (the default), wrap each piece of content in draft markers. Keep this on while the document
#'    is still going back to Word. If `FALSE`, no draft markers are written, and any draft blocks already in the file
#'    are turned back into placeholders and filled, so you can make the final version straight from a draft.
#' @param draft_mode_prefix,draft_mode_suffix
#'    The lines that start and end a draft block. Defaults to `"DRAFT_CONTENT_START"` and `"DRAFT_CONTENT_END"`.
#'    Avoid `--`, which Word turns into a dash.
#' @param validation_path
#'    Folder for the validation log, a CSV of which placeholders were found and filled and what changed since the
#'    last run. If the `quarto` and `reactable` packages are installed, an HTML version is made too. Defaults to
#'    `NULL`, which writes no log.
#' @param marker_mode
#'    How the marker naming each placeholder is written:
#'    * `"hidden"` (the default) uses the `placeholder_style_hidden` style, which can be set to hidden text in Word.
#'    * `"show"` uses the `placeholder_style_visible` style.
#'    * `"off"` writes no marker. Use this only for the final version: nothing is left to show where the content came
#'      from, so it can't be refreshed after another round in Word.
#'
#'    In HTML output, [hide_markers_css()] hides the markers.
#' @param placeholder_style_hidden,placeholder_style_visible
#'    Names of the Word character styles used for markers. Defaults to `"PlaceholderMarker"` and
#'    `"PlaceholderMarkerVisible"`. The package includes a Word document with both styles set up:
#'    `system.file("extdata", "PlaceholderMarker_example.docx", package = "knittogether")`.
#' @param log_file,html_file
#'    File names for the validation log and its HTML version, inside `validation_path`. Set either to `NULL` to skip
#'    it. Defaults to `"quality_log.csv"` and `"validation.html"`.
#' @param output_file_ext
#'    Extension for the output file when `output_file` isn't given. Defaults to `"md"`. Use `"qmd"` if Quarto
#'    complains about executable code in a `.md` file.
#' @param output_file
#'    Path to write the result to, leaving the input file unchanged. Defaults to `NULL`, which writes to
#'    `markdown_file` (with its extension changed to `output_file_ext`).
#' @param overwrite
#'    Logical. If `FALSE`, stop rather than write over an existing file. Defaults to `TRUE`. Use [timestamped_path()]
#'    to keep earlier versions.
#'
#' @examples
#' \dontrun{
#' plot <- define_content(
#'   placeholder_id = "plot",
#'   description = "Car weight against fuel economy",
#'   output_mode = "chunk",
#'   content = { plot(mtcars$wt, mtcars$mpg) },
#'   chunk_options = list(echo = FALSE)
#' )
#'
#' # While the document is still a draft
#' replace_placeholders(
#'   markdown_file = "draft.md",
#'   placeholder_prefix = "placeholder_",
#'   code_content = placeholder_map(specs = list(plot)),
#'   validation_path = "validation"
#' )
#'
#' # The final version
#' replace_placeholders(
#'   markdown_file = "draft.md",
#'   placeholder_prefix = "placeholder_",
#'   code_content = placeholder_map(specs = list(plot)),
#'   draft_mode = FALSE,
#'   marker_mode = "off"
#' )
#' }
#'
#' @return The filled Markdown, invisibly, as a character string.
#' @seealso [define_content()], [placeholder_map()], [clean_markdown()]
#' @family workflow
#' @export
replace_placeholders <- function(
	markdown_file,
	placeholder_prefix = "placeholder_",
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
		token <- paste0(placeholder_prefix, slug)
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
