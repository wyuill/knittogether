# Slide break ----
#' Insert a Slide Break
#'
#' Returns a slide break marker ("---") when the output format is not HTML.
#'
#' @return A character string if non-HTML output, otherwise NULL.
#' @export
slide_break <- function() {
	if (!is_html()) {
		"---"
	}
}

#' Insert a Slide Break After a Character Limit
#'
#' Inserts a slide break at the closest clean boundary before `limit`.
#'
#' Break priority order:
#' 1. Non-slide header levels (e.g., 3–6)
#' 2. Sentence boundary
#' 3. Paragraph break
#' 4. Word boundary
#' 5. Hard cut at `limit`
#'
#' @param text A character string.
#' @param limit Character width before attempting a break.
#' @param break_fun Function returning the slide break marker.
#' @param slide_levels Integer vector of header levels that automatically start new slides (default: c(1, 2)).
#'
#' @return Modified text with a slide break inserted.
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
	header_regex <- "(?m)^(#{1,6})\\s"
	header_matches <- gregexpr(header_regex, text, perl = TRUE)[[1]]

	if (length(header_matches) > 0 && header_matches[1] != -1) {
		headers <- regmatches(text, gregexpr(header_regex, text, perl = TRUE))[[1]]
		header_lvls <- nchar(gsub(" .*", "", headers))

		header_pos <- header_matches

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

#' Automatically Insert Slide Breaks (Header-Aware)
#'
#' Applies \code{\link{insert_slide_break}} repeatedly respecting header rules
#' until no more breaks can be inserted.
#'
#' @param text Text to segment.
#' @param limit Character target for each segment.
#' @param break_fun Slide break generator.
#' @param slide_levels Which header levels automatically create slides.
#'
#' @return Text with slide breaks inserted.
#' @export
auto_slide_break <- function(text, limit = 800, break_fun = slide_break, slide_levels = c(1, 2)) {
	BREAK_TOKEN <- paste0("\n\n", break_fun(), "\n\n")

	repeat {
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
#' Initiating column structure of PowerPoint slide
#'
#' @description These functions allow the insertion of columns into markdown output and are primarily intended for .pptx outputs.
#' `pptx_col_start` initiates the column.
#' `pptx_col_break` creates a column break. In .pptx outputs there can only be one column break ordinarily.
#' `pptx_col_end` ends the column section, returning to full width content.
#' @param width Column width as a percentage from 0 to 100.
#'   In `pptx_col_start()` this is the first column width; in
#'   `pptx_col_break()` this is the second column width.
#' @examples
#'
#'  pptx_col_start(width = 40)
#'
#'  # column content (e.g. plot(mtcars))
#'
#'  pptx_col_break(width = 60)
#'
#'  # column content (e.g. head(mtcars))
#'
#'  pptx_col_end()
#'
#' @export
pptx_col_start <- function(width = 50) {
	if (!is_html()) {
		paste0(":::: columns\n::: {.column width='", width, "%'}")
	}
}

#' Initiating the second column of a PowerPoint slide
#'
#' @rdname pptx_col_start
#' @export
pptx_col_break <- function(width = 50) {
	if (!is_html()) {
		paste0(":::\n::: {.column width='", width, "%'}")
	}
}

#' End column structuring on PowerPoint slide
#'
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

#' Add Slide Background Images
#'
#' @description
#' Returns a header (`#`, `##`, …) with a provided background image
#'
#' @param level Header level numeric (1 = `#`, 2 = `##`, etc.).
#' @param title Slide title.
#' @param bg The name of the background image file (without extension e.g., `"blue"` rather than `"blue.png"`).
#' @param include_html If TRUE, emit a header for HTML; otherwise suppress. Defaults to `TRUE`.
#' @param bg_dir Directory containing background images.
#'
#' @return A `knitr::asis_output()` object.
#'
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

#' Add a Background Image to All Headers of Selected Levels in a String
#'
#' @description
#' Scans a Markdown/Quarto text string, finds headers, and inserts or replaces a `background-image` attribute on all
#' headers whose level is in `levels`.
#'
#' @param text Markdown/Quarto content as a single string.
#' @param levels Integer vector of header levels to target.
#' @param bg The name of the background image file (without extension e.g., `"blue"` rather than `"blue.png"`).
#' @param bg_dir Directory where background files live.
#' @param overwrite Replace an existing `background-image` attribute?
#'
#' @return Modified text string with updated headers.
#'
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

	# Handle YAML front matter
	in_yaml <- FALSE
	yaml_started <- grepl("^---\\s*$", lines[1])
	if (yaml_started) {
		in_yaml <- TRUE
	}

	is_yaml_delim <- function(x) grepl("^---\\s*$|^\\.\\.\\.\\s*$", x)

	header_re <- "^\\s{0,3}(#{1,6})[ \\t]+(.+?)([ \\t]+\\{[^}]*\\})?\\s*$"

	extract_attr_inner <- function(x) {
		sub("^\\{(.*)\\}$", "\\1", trimws(x))
	}

	output <- lines

	for (i in seq_along(lines)) {
		line <- lines[i]

		# Skip inside YAML
		if (in_yaml) {
			if (i > 1 && is_yaml_delim(line)) {
				in_yaml <- FALSE
			}
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
