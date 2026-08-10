#' Clean Pandoc‑generated Markdown for use in Quarto (.qmd)
#'
#' @description
#' Post‑processes Markdown so that it’s suitable for inclusion in Quarto (`.qmd`) documents. Optionally:
#' * fixes citation escaping,
#' * adjusts PowerPoint‑derived heading levels,
#' * globally offsets headings,
#' * clears draft blocks written by [replace()], keeping only the placeholder,
#' * removes styling from placeholder markers written by [replace()].
#'
#' @param markdown_file
#'    Path to the Markdown file to clean (overwritten in place).
#' @param clean_citations
#'    Logical; if `TRUE`, removes stray escaping in citations, for example
#'    `\\[@key\\]` becomes `[@key]`. Defaults to `FALSE`.
#' @param pptx_section_offset
#'    Logical; if `TRUE`, headings that have body text before the next heading are incremented by one level (max 6).
#'    Defaults to `FALSE`.
#' @param heading_offset
#'    Logical; if `TRUE`, increments all headings by one level (max 6). This applies after `pptx_section_offset`.
#'     Defaults to `FALSE`.
#' @param clear_draft
#'    Logical; if `TRUE`, remove content between draft markers specified in `draft_mode_prefix` and `draft_mode_suffix`
#'    while retaining the placeholder. Defaults to `FALSE`.
#' @param draft_mode_prefix
#'    Start marker (plain string). Default: `"--DRAFT_CONTENT--"`.
#' @param draft_mode_suffix
#'    End marker (plain string). Default: `"--END_DRAFT_CONTENT--"`.
#' @param clear_placeholder_styling
#'    Logical; if `TRUE`, removes styling tags applied to placeholder markers.
#'    For example, `"[placeholder_content_test]{custom-style=\"PlaceholderMarker\"}"`
#'    is cleaned to `"placeholder_content_test"`. Defaults to `TRUE`.
#'
#' @param placeholder_prefix
#'    Prefix used to identify placeholder tokens (e.g., `"placeholder_content"` matches
#'    `"placeholder_content_my_id"`). Defaults to `"placeholder_content"`.
#'
#' @examples
#' \dontrun{
#'  # Clean a Markdown file with all options enabled
#'  clean(
#'    markdown_file = "markdown_output.md",
#'    clean_citations = TRUE,
#'    pptx_section_offset = TRUE,
#'    heading_offset = TRUE,
#'    clear_draft = TRUE,
#'    draft_mode_prefix = "--DRAFT_CONTENT--",
#'    draft_mode_suffix = "--END_DRAFT_CONTENT--",
#'    clear_placeholder_styling = TRUE
#'  )
#' }
#'
#' @return Invisibly returns the cleaned lines written to the file.
#'
#' @export
clean <- function(
	markdown_file = "markdown_output.md",
	clean_citations = FALSE,
	pptx_section_offset = FALSE,
	heading_offset = FALSE,
	clear_draft = FALSE,
	draft_mode_prefix = "--DRAFT_CONTENT--",
	draft_mode_suffix = "--END_DRAFT_CONTENT--",
	clear_placeholder_styling = TRUE,
	placeholder_prefix = "placeholder_content"
) {
	if (!file.exists(markdown_file)) {
		stop("File not found: ", markdown_file, call. = FALSE)
	}

	text <- readLines(markdown_file, warn = FALSE)

	# Draft mode
	if (isTRUE(clear_draft)) {
		text <- .clear_draft_stream(
			text,
			draft_mode_prefix,
			draft_mode_suffix,
			placeholder_prefix = placeholder_prefix
		)
	}

	# Placeholder styling
	if (isTRUE(clear_placeholder_styling)) {
		# Remove '[' and ']' only when the content is a placeholder token
		placeholder_pattern <- paste0(
			"\\[(\\s*",
			gsub("([.|()\\^{}+$*?\\[\\]\\\\])", "\\\\\\1", placeholder_prefix),
			"_[A-Za-z0-9_]+\\s*)\\]"
		)
		text <- gsub(placeholder_pattern, "\\1", text, perl = TRUE)
		# Remove trailing {custom-style="..."} anywhere
		text <- gsub("\\{\\s*custom-style\\s*=\\s*\"[^\"]+\"\\s*\\}", "", text, perl = TRUE)
		# Normalise spaces within lines
		text <- trimws(gsub("\\s+", " ", text, perl = TRUE))
	}

	# Citations
	if (isTRUE(clean_citations)) {
		text <- gsub("\\\\\\[@", "[@", text)
		text <- gsub("\\\\@", "@", text)
		text <- gsub("\\\\]", "]", text)
	}

	# PowerPoint section headers
	if (isTRUE(pptx_section_offset)) {
		is_heading <- grepl("^#{1,6}\\s", text)

		for (k in seq_along(text)) {
			if (!is_heading[k]) {
				next
			}

			non_empty <- which(trimws(text) != "")
			j <- non_empty[non_empty > k][1]

			has_body <- !(is.na(j) || is_heading[j])

			if (has_body) {
				m <- regexpr("^(#+)\\s", text[k], perl = TRUE)
				n_hash <- attr(m, "match.length") - 1L
				new_level <- min(n_hash + 1L, 6L)
				new_marks <- paste0(rep("#", new_level), collapse = "")
				text[k] <- sub("^#+", new_marks, text[k])
			}
		}
	}

	# Heading offset
	if (isTRUE(heading_offset)) {
		pattern <- "(?m)^(#+)(\\s*)"
		locs <- gregexpr(pattern, text, perl = TRUE)
		matches <- regmatches(text, locs)

		matches_new <- lapply(matches, function(block) {
			vapply(
				block,
				function(h) {
					m2 <- regexec(pattern, h, perl = TRUE)
					parts <- regmatches(h, m2)[[1]]
					hashes <- parts[2]
					spaces <- parts[3]
					n <- nchar(hashes)
					new_hashes <- if (n < 6) paste0(hashes, "#") else hashes
					paste0(new_hashes, spaces)
				},
				character(1)
			)
		})

		regmatches(text, locs) <- matches_new
	}

	writeLines(text, markdown_file)
	invisible(text)
}

#' Extract the first placeholder token (internal)
#'
#' @param x A character string to scan.
#' @param placeholder_prefix Placeholder prefix to match.
#' @return The first match of `<placeholder_prefix>_[A-Za-z0-9_]+` or `NA_character_` if none.
#' @keywords internal
#' @noRd
.extract_placeholder <- function(x, placeholder_prefix = "placeholder_content") {
	prefix <- gsub("([.|()\\^{}+$*?\\[\\]\\\\])", "\\\\\\1", placeholder_prefix)
	m <- regexpr(paste0(prefix, "_[A-Za-z0-9_]+"), x, perl = TRUE)
	if (m[1] == -1) {
		return(NA_character_)
	}
	regmatches(x, m)
}

#' Clear draft blocks across the entire text stream (internal)
#'
#' Treats the input as a single stream (joined by `\n`) and repeatedly replaces `prefix ... suffix` spans with the
#' extracted placeholder. Works across line breaks and preserves surrounding text, including punctuation after the suffix.
#'
#' @param lines Character vector of lines.
#' @param draft_mode_prefix Start marker (plain string).
#' @param draft_mode_suffix End marker (plain string).
#' @param placeholder_prefix Placeholder prefix to preserve when clearing draft blocks.
#' @return Character vector of cleaned lines.
#' @keywords internal
#' @noRd
.clear_draft_stream <- function(lines, draft_mode_prefix, draft_mode_suffix, placeholder_prefix = "placeholder_content") {
	txt <- paste(lines, collapse = "\n")

	repeat {
		s_pos <- regexpr(draft_mode_prefix, txt, fixed = TRUE)
		if (s_pos[1] == -1) {
			break
		}

		# split around the first prefix
		start <- s_pos[1]
		plen <- attr(s_pos, "match.length")
		before <- substr(txt, 1L, start - 1L)
		after_start <- substr(txt, start + plen, nchar(txt))

		# find the first suffix AFTER the prefix
		e_pos <- regexpr(draft_mode_suffix, after_start, fixed = TRUE)
		if (e_pos[1] == -1) {
			# Malformed (no closing suffix): do not alter further; stop.
			break
		}

		# content between prefix and suffix (may contain newlines)
		between <- substr(after_start, 1L, e_pos[1] - 1L)
		placeholder <- .extract_placeholder(between, placeholder_prefix = placeholder_prefix)
		if (is.na(placeholder)) {
			placeholder <- ""
		}

		# trailing content after suffix
		tail <- substr(after_start, e_pos[1] + attr(e_pos, "match.length"), nchar(after_start))

		# rebuild stream and continue
		txt <- paste0(before, placeholder, tail)
	}

	# split back to lines
	strsplit(txt, "\n", fixed = TRUE)[[1]]
}
