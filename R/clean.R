#' Clean Pandoc‑generated Markdown for use in Quarto (.qmd)
#'
#' @description
#' Post‑processes Markdown so that it’s suitable for inclusion in Quarto (`.qmd`) documents. Optionally:
#' * fixes citation escaping,
#' * adjusts PowerPoint‑derived heading levels,
#' * globally offsets headings,
#' * clears draft blocks written by [replace_placeholders()], keeping only the placeholder,
#' * removes styling from placeholder markers written by [replace_placeholders()].
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
#'    Start marker (plain string). Default: `"DRAFT_CONTENT_START"`.
#' @param draft_mode_suffix
#'    End marker (plain string). Default: `"DRAFT_CONTENT_END"`.
#' @param clear_placeholder_styling
#'    Logical; if `TRUE`, removes styling tags applied to placeholder markers.
#'    For example, `"[placeholder_content_test]{custom-style=\"PlaceholderMarker\"}"`
#'    is cleaned to `"placeholder_content_test"`. Only spans that contain nothing but a placeholder token are changed;
#'    other `custom-style` spans and all whitespace are left as they are. Defaults to `TRUE`.
#'
#' @param placeholder_prefix
#'    Prefix used to identify placeholder tokens (e.g., `"placeholder_content"` matches
#'    `"placeholder_content_my_id"`). Defaults to `"placeholder_content"`.
#' @param output_file
#'    Optional path to write the cleaned Markdown to. `markdown_file` is then left unchanged. Defaults to `NULL`,
#'    which overwrites `markdown_file`.
#' @param overwrite
#'    Logical; if `FALSE`, stop rather than write over an existing file. Defaults to `TRUE`, so existing scripts
#'    keep overwriting. Use [timestamped_path()] to keep earlier versions.
#'
#' @examples
#' \dontrun{
#'  # Clean a Markdown file with all options enabled
#'  clean_markdown(
#'    markdown_file = "markdown_output.md",
#'    clean_citations = TRUE,
#'    pptx_section_offset = TRUE,
#'    heading_offset = TRUE,
#'    clear_draft = TRUE,
#'    draft_mode_prefix = "DRAFT_CONTENT_START",
#'    draft_mode_suffix = "DRAFT_CONTENT_END",
#'    clear_placeholder_styling = TRUE
#'  )
#' }
#'
#' @return Invisibly returns the cleaned lines written to the file.
#'
#' @export
clean_markdown <- function(
	markdown_file = "markdown_output.md",
	clean_citations = FALSE,
	pptx_section_offset = FALSE,
	heading_offset = FALSE,
	clear_draft = FALSE,
	draft_mode_prefix = "DRAFT_CONTENT_START",
	draft_mode_suffix = "DRAFT_CONTENT_END",
	clear_placeholder_styling = TRUE,
	placeholder_prefix = "placeholder_content",
	output_file = NULL,
	overwrite = TRUE
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
		# Only touch spans whose whole content is a placeholder token: `[token]{custom-style="..."}` and bare
		# `[token]` become `token`. Other styled spans, and whitespace elsewhere (list indents, code, tables, hard
		# line breaks), are left alone.
		token <- paste0(gsub("([.|()\\^{}+$*?\\[\\]\\\\])", "\\\\\\1", placeholder_prefix), "_[A-Za-z0-9_]+")
		# Word formatting (superscript ^, subscript ~, bold **, italic *) applied to a placeholder wraps it in the
		# output, e.g. ^placeholder_content_x^ or **[placeholder_content_x]{...}**. Remove formatting that sits tight
		# against the token so it isn't applied to the code output.
		formatting <- "[\\^~*]+"
		# The example template brackets placeholders with U+27E6 / U+27E7 (see inst/extdata), and the formatting can
		# sit outside or inside those brackets, so both are allowed here.
		open_b <- "\u27E6?"
		close_b <- "\u27E7?"
		wrapped_bare <- paste0("(?<![\\^~*])(", formatting, ")", open_b, "(", token, ")", close_b, "\\1(?![\\^~*])")
		wrapped_span <- paste0("(?<![\\^~*])(", formatting, ")(\\[\\s*", token, "\\s*\\](?:\\{[^}]*\\})?)\\1(?![\\^~*])")
		text <- gsub(wrapped_bare, "\\2", text, perl = TRUE)
		text <- gsub(wrapped_span, "\\2", text, perl = TRUE)
		# Bracket characters the template puts around a placeholder are authoring aids, not content
		text <- gsub(paste0("\u27E6\\s*(", token, ")\\s*\u27E7?"), "\\1", text, perl = TRUE)
		text <- gsub(paste0("(", token, ")\\s*\u27E7"), "\\1", text, perl = TRUE)

		styled_pattern <- paste0("\\[\\s*(", token, ")\\s*\\]\\{\\s*custom-style\\s*=\\s*\"[^\"]+\"\\s*\\}")
		bare_pattern <- paste0("\\[\\s*(", token, ")\\s*\\](?![({\\[])")
		text <- gsub(styled_pattern, "\\1", text, perl = TRUE)
		text <- gsub(bare_pattern, "\\1", text, perl = TRUE)
	}

	# Citations
	if (isTRUE(clean_citations)) {
		text <- gsub("\\\\\\[@", "[@", text)
		text <- gsub("\\\\@", "@", text)
		text <- gsub("\\\\]", "]", text)
	}

	# PowerPoint section headers
	if (isTRUE(pptx_section_offset)) {
		is_heading <- .is_heading_line(text)

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
		# Only real headings (a space after the hashes, outside code and YAML), so `#| echo: false` and R comments
		# are never changed. Level-6 headings stay at 6.
		bump <- .is_heading_line(text) & !grepl("^#{6}", text)
		text[bump] <- paste0("#", text[bump])
	}

	destination <- if (is.null(output_file)) markdown_file else output_file
	check_overwrite(destination, overwrite)
	writeLines(text, destination)
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
