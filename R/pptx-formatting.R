# Slide break ----
#' Start a new slide
#'
#' @description
#' Returns `---`, which starts a new slide, when the document isn't being rendered to HTML. In HTML it returns
#' nothing, so the same document can render to both. Use it in inline code, `` `r slide_break()` ``, or as the
#' `break_fun` of [auto_slide_break()].
#'
#' @return `"---"`, or `NULL` in HTML output.
#' @examples
#' slide_break()
#' @family PowerPoint
#' @export
slide_break <- function() {
	if (!is_html()) {
		"---"
	}
}

#' Break text into a new slide once, before a character limit
#'
#' @description
#' If `text` is longer than `limit` characters, adds one slide break at the best place before the limit. It looks,
#' in order, for a heading that doesn't start a slide by itself (level 3 to 6 by default), the end of a sentence, a
#' paragraph break or a space, and cuts at `limit` only if it finds none. A heading at the very start of `text` is
#' ignored. [auto_slide_break()] repeats this until the whole text fits.
#'
#' @param text A single string of Markdown.
#' @param limit Maximum number of characters before a break. Defaults to 800.
#' @param break_fun A function that returns the slide break. Defaults to [slide_break()].
#' @param slide_levels Heading levels that already start a new slide. Defaults to `c(1, 2)`.
#'
#' @return `text`, with a slide break added if it was longer than `limit`.
#' @examples
#' text <- paste(rep("A sentence of text.", 60), collapse = " ")
#' insert_slide_break(text, limit = 200, break_fun = function() "---")
#' @family PowerPoint
#' @export
insert_slide_break <- function(text, limit = 800, break_fun = slide_break, slide_levels = c(1, 2)) {
	if (nchar(text) <= limit) {
		return(text)
	}

	br <- break_fun()
	if (is.null(br)) {
		br <- ""
	}
	BREAK_TOKEN <- paste0("\n\n", br, "\n\n")

	# If a slide break already exists BEFORE the limit, do nothing
	existing_break <- gregexpr(BREAK_TOKEN, text, fixed = TRUE)[[1]]
	if (any(existing_break != -1 & existing_break <= limit)) {
		return(text)
	}

	# Header breaks
	# Headings outside code and YAML, with their character position in `text`
	lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
	line_start <- cumsum(c(1L, nchar(lines[-length(lines)]) + 1L))
	is_hdr <- .is_heading_line(lines)

	if (any(is_hdr)) {
		header_lvls <- nchar(sub("^(#+).*", "\\1", lines[is_hdr]))
		header_pos <- line_start[is_hdr]

		# A header at the very start of the text can't be broken before: doing so would insert an empty segment and
		# leave the text unchanged, so auto_slide_break() would loop forever.
		header_lvls <- header_lvls[header_pos > 1]
		header_pos <- header_pos[header_pos > 1]

		# slide-level headers (natural break)
		slide_hdrs <- header_pos[header_lvls %in% slide_levels & header_pos <= limit]

		if (length(slide_hdrs)) {
			pos <- max(slide_hdrs) - 1
			if (substr(text, pos + 1, pos + nchar(BREAK_TOKEN)) == BREAK_TOKEN) {
				return(text)
			}
			return(paste0(substr(text, 1, pos), BREAK_TOKEN, substr(text, pos + 1, nchar(text))))
		}

		# non-slide headers (nice breaks)
		nice_hdrs <- header_pos[!header_lvls %in% slide_levels & header_pos <= limit]

		if (length(nice_hdrs)) {
			pos <- max(nice_hdrs) - 1
			if (substr(text, pos + 1, pos + nchar(BREAK_TOKEN)) == BREAK_TOKEN) {
				return(text)
			}
			return(paste0(substr(text, 1, pos), BREAK_TOKEN, substr(text, pos + 1, nchar(text))))
		}
	}

	# Other good break locations
	safe_max <- function(x) if (length(x) == 0) -Inf else max(x)
	pick <- function(pos) pos[pos <= limit & pos != -1]

	sentence <- safe_max(pick(gregexpr("[\\.\\?\\!]", text)[[1]]))
	para <- safe_max(pick(gregexpr("\n\n", text)[[1]]))
	space <- safe_max(pick(gregexpr(" ", text)[[1]]))

	pos <- max(sentence, para, space)

	if (!is.finite(pos)) {
		pos <- limit
	}

	if (substr(text, pos + 1, pos + nchar(BREAK_TOKEN)) == BREAK_TOKEN) {
		return(text)
	}

	paste0(substr(text, 1, pos), BREAK_TOKEN, substr(text, pos + 1, nchar(text)))
}

#' Break text into slides that fit
#'
#' @description
#' Adds slide breaks to `text` until no stretch between breaks is longer than `limit` characters, using
#' [insert_slide_break()] to choose each break.
#'
#' @inheritParams insert_slide_break
#'
#' @return `text`, with slide breaks added.
#' @examples
#' text <- paste(rep("A sentence of text.", 100), collapse = " ")
#' auto_slide_break(text, limit = 400, break_fun = function() "---")
#' @family PowerPoint
#' @export
auto_slide_break <- function(text, limit = 800, break_fun = slide_break, slide_levels = c(1, 2)) {
	BREAK_TOKEN <- paste0("\n\n", break_fun(), "\n\n")

	# Every pass that changes the text adds at least one break before a later character, so there can never be more
	# passes than characters. Exceeding that means no progress is being made.
	max_passes <- nchar(text) + 1L
	passes <- 0L

	repeat {
		passes <- passes + 1L
		if (passes > max_passes) {
			stop("auto_slide_break() could not make progress splitting the text.", call. = FALSE)
		}
		# Split into existing segments
		segments <- strsplit(text, BREAK_TOKEN, fixed = TRUE)[[1]]

		changed <- FALSE
		new_segments <- character(length(segments))

		for (i in seq_along(segments)) {
			seg <- segments[i]
			new_seg <- insert_slide_break(seg, limit = limit, break_fun = break_fun, slide_levels = slide_levels)
			if (!identical(seg, new_seg)) {
				changed <- TRUE
			}
			new_segments[i] <- new_seg
		}

		if (!changed) {
			return(paste(new_segments, collapse = BREAK_TOKEN))
		}
		text <- paste(new_segments, collapse = BREAK_TOKEN)
	}
}

# Slide columns ----
#' Split a slide into two columns
#'
#' @description
#' Put `pptx_col_start()` before the first column's content, `pptx_col_break()` between the columns and
#' `pptx_col_end()` after the second column. Each returns the Markdown for that point, so use them in inline code.
#' In HTML output they return nothing, and the content runs down the page as normal.
#'
#' @param width The column's width, as a percentage of the slide. In `pptx_col_start()` this is the first column; in
#'   `pptx_col_break()` the second. Defaults to 50.
#'
#' @return The Markdown that starts, divides or ends the columns, or `NULL` in HTML output.
#' @examples
#' pptx_col_start(width = 40)
#' pptx_col_break(width = 60)
#' pptx_col_end()
#' @family PowerPoint
#' @export
pptx_col_start <- function(width = 50) {
	if (!is_html()) {
		paste0(":::: columns\n::: {.column width='", width, "%'}")
	}
}

#' @rdname pptx_col_start
#' @export
pptx_col_break <- function(width = 50) {
	if (!is_html()) {
		paste0(":::\n::: {.column width='", width, "%'}")
	}
}

#' @rdname pptx_col_start
#' @export
pptx_col_end <- function() {
	if (!is_html()) {
		paste0(":::\n::::")
	}
}

# Slide backgrounds ----

#' Compose/merge a background-image attribute (internal)
#'
#' @description
#' Internal utility used by header-processing functions. It takes the inner
#' contents of a header attribute block (e.g., `"foo='bar' size=large"`) and
#' either inserts or replaces a `background-image='...'` attribute.
#'
#' @param attr_inner Character string containing attributes without braces.
#' @param bg_path The background image path to insert.
#' @param overwrite Should existing `background-image` be replaced?
#'
#' @return A character string representing the merged attribute list, without
#'   braces.
#'
#' @keywords internal
#' @noRd
.compose_attr_with_bg <- function(attr_inner, bg_path, overwrite = TRUE) {
	has_bg <- grepl("background-image\\s*=\\s*(['\"]).*?\\1", attr_inner, perl = TRUE)

	if (has_bg) {
		if (overwrite) {
			return(sub(
				"background-image\\s*=\\s*(['\"]).*?\\1",
				paste0("background-image='", bg_path, "'"),
				attr_inner,
				perl = TRUE
			))
		} else {
			return(attr_inner)
		}
	}

	# Append new attribute
	if (nzchar(attr_inner)) {
		paste(attr_inner, paste0("background-image='", bg_path, "'"))
	} else {
		paste0("background-image='", bg_path, "'")
	}
}

#' Write a heading with a background image
#'
#' @description
#' In PowerPoint output, returns a heading with a background image, for section or title slides. In other formats it
#' returns a plain heading, or nothing if `include_html = FALSE`.
#'
#' The image is looked up in `bg_dir` by file name without its extension. It can be named after the heading level
#' (`level1.png` or `1.png`) or after `bg`. Exactly one file must match. Make the image the same size as your
#' slides.
#'
#' @param level Heading level: 1 for `#`, 2 for `##` and so on. Defaults to 1.
#' @param title The heading text.
#' @param bg Optional. The image's file name without the extension, for example `"blue"` for `blue.png`.
#' @param include_html Logical. If `FALSE`, write nothing when the output isn't PowerPoint. Defaults to `TRUE`.
#' @param bg_dir The folder that holds the background images.
#'
#' @return The heading, ready to print in a chunk with `output: asis`, or `NULL`.
#' @examples
#' \dontrun{
#' pptx_section_slide(level = 1, title = "Results", bg = "blue", bg_dir = "backgrounds")
#' }
#' @family PowerPoint
#' @export
pptx_section_slide <- function(level = 1, title, bg = NULL, include_html = TRUE, bg_dir) {
	if (!is.numeric(level) || length(level) != 1L) {
		stop("`level` must be a single number.", call. = FALSE)
	}

	if (!is.character(title) || length(title) != 1L) {
		stop("`title` must be a single character string.", call. = FALSE)
	}

	if (missing(bg_dir)) {
		stop("You must supply `bg_dir`.", call. = FALSE)
	}

	hashes <- paste(rep("#", level), collapse = "")

	if (.pandoc_to("pptx")) {
		files <- list.files(bg_dir, full.names = TRUE)
		base <- tools::file_path_sans_ext(basename(files))

		keys <- c(paste0("level", level), as.character(level), if (!is.null(bg)) as.character(bg))

		hit <- match(base, keys, nomatch = 0)

		if (sum(hit != 0) == 0) {
			stop("No matching background in '", bg_dir, "'. Tried: ", paste(keys, collapse = ", "), call. = FALSE)
		}

		if (sum(hit != 0) > 1) {
			stop("Multiple matches found in '", bg_dir, "'. Exactly one must match.", call. = FALSE)
		}

		bg_path <- files[hit != 0]

		# Build attribute block using internal helper
		attr_inner <- .compose_attr_with_bg("", bg_path, overwrite = TRUE)
		attr_block <- paste0(" {", attr_inner, "}")

		header <- paste0(hashes, " ", title, attr_block)
		return(knitr::asis_output(header))
	} else if (include_html) {
		return(knitr::asis_output(paste(hashes, title)))
	} else {
		return(invisible(NULL))
	}
}

#' Add a background image to headings in Markdown
#'
#' @description
#' Adds a background image to every heading of the given levels in `text`, for example all section slides in
#' converted Markdown. Headings inside code blocks are left alone.
#'
#' @param text A single string of Markdown.
#' @param levels The heading levels to change. Defaults to 1.
#' @param bg The image's file name without the extension, for example `"blue"` for `blue.png`.
#' @param bg_dir The folder that holds the background images.
#' @param overwrite Logical. If `TRUE` (the default), replace a background a heading already has.
#'
#' @return `text`, with the background added to those headings.
#' @examples
#' \dontrun{
#' add_pptx_backgrounds_to_headers(text, levels = 1, bg = "blue", bg_dir = "backgrounds")
#' }
#' @family PowerPoint
#' @export
add_pptx_backgrounds_to_headers <- function(text, levels = 1, bg, bg_dir, overwrite = TRUE) {
	if (!is.character(text) || length(text) != 1L) {
		stop("`text` must be a single character string.")
	}

	if (missing(bg_dir)) {
		stop("You must supply `bg_dir`.")
	}

	if (!is.character(bg) || length(bg) != 1L) {
		stop("`bg` must be a single string (e.g., 'blue').")
	}

	files <- list.files(bg_dir, full.names = TRUE)
	base <- tools::file_path_sans_ext(basename(files))

	bg_match <- match(base, bg, nomatch = 0)

	if (sum(bg_match != 0) == 0) {
		stop("No matching background found in ", bg_dir, ". Tried: ", bg)
	}

	if (sum(bg_match != 0) > 1) {
		stop("Multiple matches found for background '", bg, "' in ", bg_dir, ".")
	}

	bg_from_name <- files[bg_match != 0]

	# Process string
	lines <- strsplit(text, "\n", fixed = TRUE)[[1]]

	# Skip YAML front matter and fenced code, where `#` lines are not headings
	skip <- .code_or_yaml_lines(lines)

	header_re <- "^\\s{0,3}(#{1,6})[ \\t]+(.+?)([ \\t]+\\{[^}]*\\})?\\s*$"

	extract_attr_inner <- function(x) {
		sub("^\\{(.*)\\}$", "\\1", trimws(x))
	}

	output <- lines

	for (i in seq_along(lines)) {
		line <- lines[i]

		if (skip[i]) {
			next
		}

		m <- regexec(header_re, line, perl = TRUE)
		reg <- regmatches(line, m)[[1]]

		if (length(reg) > 0) {
			hashes <- reg[2]
			title <- reg[3]
			attr <- reg[4]
			level <- nchar(hashes)

			if (level %in% levels) {
				# Compose attribute block
				if (!is.na(attr) && nzchar(trimws(attr))) {
					inner <- extract_attr_inner(attr)
					new_inner <- .compose_attr_with_bg(inner, bg_from_name, overwrite)
					attr_new <- paste0(" {", new_inner, "}")
				} else {
					inner <- .compose_attr_with_bg("", bg_from_name, overwrite)
					attr_new <- paste0(" {", inner, "}")
				}

				output[i] <- paste0(hashes, " ", trimws(title), attr_new)
			}
		}
	}

	paste(output, collapse = "\n")
}
