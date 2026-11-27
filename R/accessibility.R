#' Check images and tables have alt text or captions
#'
#' @description
#' Scans Markdown or HTML for images and tables a screen reader user couldn't make sense of:
#'
#' * An image inside a figure needs a descriptive caption. Its alt text isn't checked, because the caption is what
#'   gets read out.
#' * An image outside a figure needs descriptive alt text.
#' * A table needs a descriptive caption: a Markdown `Table:` line, an HTML `<caption>` or an `aria-label`.
#' * `reactable` and `ggiraph` widgets need a descriptive caption.
#'
#' Missing text, and text that says nothing about the content such as "Figure 1" or "Img 4", are both reported.
#'
#' @param lines The text to check: a character vector with one line per element, a single string with line breaks,
#'   or an `htmltools::HTML()` object.
#' @param output Optional. A path to save the results to as a CSV file. Defaults to `NULL`.
#' @return A data frame with one row per problem and columns `kind`, `line`, `src`, `issue` and `snippet`.
#' @examples
#' accessibility_scan(c("![](plot.png)", "", "![A line chart of rising costs](costs.png)"))
#' @export
accessibility_scan <- function(lines, output = NULL) {
	requireNamespace("stringi", quietly = TRUE)

	# ---- Normalize input -------------------------------------------------------
	if (!is.character(lines)) {
		lines <- as.character(lines)
	}
	# If one big blob, split to lines for stable line numbers
	if (length(lines) == 1L && grepl("\n", lines, fixed = TRUE)) {
		lines <- strsplit(lines, "\n", fixed = TRUE)[[1]]
	}
	lines <- as.character(lines)
	text <- paste(lines, collapse = "\n")

	# ---- Helpers ---------------------------------------------------------------
	norm_chr <- function(x) {
		x[is.na(x)] <- ""
		x
	}

	# text judged "generic" if empty/whitespace OR "Figure 1", "Fig. 2", "Table 3", "Img 4", "Plot 5"
	safe_is_non_descriptive <- function(txt) {
		# Normalize
		txt <- as.character(txt)
		txt[is.na(txt)] <- ""

		# Trim (including NBSP), collapse internal whitespace
		txt <- stringi::stri_trim_both(txt)
		txt <- stringi::stri_replace_all_regex(txt, "\\s+", " ")

		# Empty/whitespace = non‑descriptive
		empty <- txt == ""

		# Generic labels like: "Figure 1", "Fig 1", "Fig.1", "Table 2", "Img 3", etc.
		# Accept optional dot after the word and optional trailing '.' or ':' after the number.
		generic <- stringi::stri_detect_regex(txt, "^(?i)(figure|fig|table|tbl|image|img|plot)\\.?\\s*\\d+\\s*[:\\.]?$")
		generic[is.na(generic)] <- FALSE

		empty | generic
	}

	to_line <- function(offset) {
		# 1-based line number from character offset in `text`
		stringi::stri_count_fixed(substr(text, 1, offset), "\n") + 1L
	}

	# ---- Strict FIGURE parsing (no proximity windows) -------------------------
	# Find all <figure>…</figure> blocks and their ranges; extract first <figcaption>
	fig_opts <- stringi::stri_opts_regex(dotall = TRUE) # allow '.' to match newlines
	fig_locs <- stringi::stri_locate_all_regex(text, "<figure[^>]*>.*?</figure>", opts_regex = fig_opts)[[1]]
	figure_info <- NULL

	if (!is.null(dim(fig_locs)) && nrow(fig_locs) > 0) {
		figs <- substring(text, fig_locs[, 1], fig_locs[, 2])

		figure_info <- lapply(seq_along(figs), function(i) {
			blk <- figs[i]
			start <- fig_locs[i, 1]
			stop <- fig_locs[i, 2]

			# caption (first)
			cap <- stringi::stri_match_first_regex(blk, "<figcaption[^>]*>(.*?)</figcaption>", opts_regex = fig_opts)
			cap_txt <- norm_chr(cap)[2]
			cap_ok <- nzchar(cap_txt) && !safe_is_non_descriptive(cap_txt)

			# all <img> inside this figure
			imgs_in_fig <- stringi::stri_locate_all_regex(blk, "<img\\b[^>]*?>")[[1]]
			if (!is.null(dim(imgs_in_fig)) && nrow(imgs_in_fig) > 0) {
				# translate local offsets to global offsets in `text`
				img_starts <- start + imgs_in_fig[, 1] - 1L
			} else {
				img_starts <- integer(0)
			}

			list(start = start, stop = stop, caption_ok = cap_ok, img_starts = img_starts)
		})
	}

	# Fast predicates for images/widgets:
	is_inside_any_figure <- function(pos) {
		if (is.null(figure_info) || is.na(pos)) {
			return(FALSE)
		}
		any(
			vapply(
				figure_info,
				function(fi) {
					if (any(is.na(c(fi$start, fi$stop)))) {
						return(FALSE)
					}
					pos >= fi$start && pos <= fi$stop
				},
				logical(1)
			),
			na.rm = TRUE
		)
	}

	is_inside_good_figure <- function(pos) {
		if (is.null(figure_info) || is.na(pos)) {
			return(FALSE)
		}
		any(
			vapply(
				figure_info,
				function(fi) {
					if (any(is.na(c(fi$start, fi$stop, fi$caption_ok)))) {
						return(FALSE)
					}
					fi$caption_ok && pos >= fi$start && pos <= fi$stop
				},
				logical(1)
			),
			na.rm = TRUE
		)
	}

	# ---- 1) Markdown images ----------------------------------------------------
	md_pat <- "!\\[([^\\]]*)]\\(([^)]+)\\)(?:\\{[^}]*\\})?"
	md_imgs <- stringi::stri_extract_all_regex(text, md_pat)[[1]]
	md_locs <- stringi::stri_locate_all_regex(text, md_pat)[[1]]

	md_rows <- NULL
	if (!is.null(dim(md_locs)) && nrow(md_locs) > 0) {
		md_alt <- vapply(
			md_imgs,
			function(m) norm_chr(stringi::stri_match_first_regex(m, "!\\[([^\\]]*)]"))[2],
			character(1)
		)
		md_src <- vapply(
			md_imgs,
			function(m) norm_chr(stringi::stri_match_first_regex(m, "\\(([^)]+)\\)"))[2],
			character(1)
		)
		bad <- safe_is_non_descriptive(md_alt)

		if (isTRUE(any(bad))) {
			locs <- md_locs[bad, , drop = FALSE][, 1]
			md_lines <- vapply(locs, to_line, integer(1))
			md_rows <- data.frame(
				kind = "image-md",
				line = md_lines,
				src = md_src[bad],
				issue = "missing-or-generic-alt",
				snippet = substr(md_imgs[bad], 1, 180),
				stringsAsFactors = FALSE
			)
		}
	}

	# ---- 2) HTML images --------------------------------------------------------
	html_img_pat <- "<img\\b[^>]*?>" # supports <img ...> and <img ... />
	html_imgs <- stringi::stri_extract_all_regex(text, html_img_pat)[[1]]
	html_locs <- stringi::stri_locate_all_regex(text, html_img_pat)[[1]]

	html_rows <- NULL
	if (!is.null(dim(html_locs)) && nrow(html_locs) > 0) {
		# Extract alt=""
		html_alt <- vapply(
			html_imgs,
			function(tag) {
				m <- stringi::stri_match_first_regex(tag, "alt\\s*=\\s*(['\"])(.*?)\\1")
				norm_chr(m)[3]
			},
			character(1)
		)

		img_pos <- html_locs[, 1]
		in_fig <- vapply(img_pos, is_inside_any_figure, logical(1))
		in_good <- vapply(img_pos, is_inside_good_figure, logical(1))

		# Images in GOOD figures → OK (caption overrides alt)
		# Images in figures WITHOUT good caption → FAIL (caption issue)
		fail_caption <- in_fig & !in_good

		# Images OUTSIDE figures → must have descriptive alt
		fail_alt <- !in_fig & safe_is_non_descriptive(html_alt)

		bad <- fail_caption | fail_alt
		if (isTRUE(any(bad))) {
			locs <- html_locs[bad, , drop = FALSE][, 1]
			html_lines <- vapply(locs, to_line, integer(1))

			issues <- ifelse(fail_caption[bad], "missing-or-generic-caption", "missing-or-generic-alt")

			html_rows <- data.frame(
				kind = "image-html",
				line = html_lines,
				src = "", # (extracting HTML src is optional; add if you need)
				issue = issues,
				snippet = substr(html_imgs[bad], 1, 180),
				stringsAsFactors = FALSE
			)
		}
	}

	# ---- 3) Markdown tables ----------------------------------------------------
	# =========================================================
	# 3) MARKDOWN TABLES  (flag at most once per table block)
	# =========================================================

	.scan_is_table_line <- function(ln) {
		# Pipe tables or grid tables
		stringi::stri_detect_regex(ln, "^\\s*\\|") | stringi::stri_detect_regex(ln, "^\\s*\\+")
	}

	.scan_md_tables_blocked <- function(lines, safe_is_non_descriptive) {
		n <- length(lines)
		i <- 1L
		out <- list()

		while (i <= n) {
			# Find the next potential table line
			if (!isTRUE(.scan_is_table_line(lines[i]))) {
				i <- i + 1L
				next
			}

			# We are at the first line of a (possibly) contiguous table block.
			# Ensure it's the FIRST line of the block (previous nonblank not a table line).
			j_prev <- i - 1L
			while (j_prev >= 1L && !stringi::stri_detect_regex(lines[j_prev], "\\S")) {
				j_prev <- j_prev - 1L
			}
			is_first_of_block <- (j_prev < 1L) || !isTRUE(.scan_is_table_line(lines[j_prev]))

			if (!is_first_of_block) {
				# If it's not the first line, skip ahead to the end-of-block fast.
				i <- i + 1L
				next
			}

			# Identify block end
			j_end <- i
			while (j_end + 1L <= n && isTRUE(.scan_is_table_line(lines[j_end + 1L]))) {
				j_end <- j_end + 1L
			}

			# Determine caption line just above the block (skip blank lines)
			cap <- ""
			j_cap <- i - 1L
			while (j_cap >= 1L && !stringi::stri_detect_regex(lines[j_cap], "\\S")) {
				j_cap <- j_cap - 1L
			}
			if (j_cap >= 1L && isTRUE(stringi::stri_detect_regex(lines[j_cap], "^\\s*Table:"))) {
				cap <- sub("^\\s*Table:\\s*", "", lines[j_cap])
			}

			# Flag once per block: if caption missing or generic
			if (!(nzchar(cap) && !safe_is_non_descriptive(cap))) {
				out[[length(out) + 1L]] <- data.frame(
					kind = "table-md",
					line = i, # first line of this table block
					src = "",
					issue = "missing-or-generic-caption",
					snippet = substr(lines[i], 1, 180),
					stringsAsFactors = FALSE
				)
			}

			# Advance i to end of block + 1
			i <- j_end + 1L
		}

		if (length(out) == 0L) {
			return(NULL)
		} else {
			do.call(rbind, out)
		}
	}

	md_table_rows <- .scan_md_tables_blocked(lines, safe_is_non_descriptive)

	# ---- 4) HTML tables --------------------------------------------------------
	html_table_pat <- "<table[^>]*>.*?</table>"
	html_tables <- stringi::stri_extract_all_regex(text, html_table_pat, opts_regex = fig_opts)[[1]]
	html_locs_t <- stringi::stri_locate_all_regex(text, html_table_pat, opts_regex = fig_opts)[[1]]

	html_table_rows <- NULL
	if (!is.null(dim(html_locs_t)) && nrow(html_locs_t) > 0) {
		html_table_rows <- do.call(
			rbind,
			lapply(seq_len(nrow(html_locs_t)), function(i) {
				tbl <- substring(text, html_locs_t[i, 1], html_locs_t[i, 2])

				cap <- stringi::stri_match_first_regex(tbl, "<caption[^>]*>(.*?)</caption>")
				cap <- norm_chr(cap)[2]
				aria <- stringi::stri_match_first_regex(tbl, "aria-label\\s*=\\s*(['\"])(.*?)\\1")
				aria <- norm_chr(aria)[3]

				if ((nzchar(cap) && !safe_is_non_descriptive(cap)) || (nzchar(aria) && !safe_is_non_descriptive(aria))) {
					return(NULL)
				}

				data.frame(
					kind = "table-html",
					line = to_line(html_locs_t[i, 1]),
					src = "",
					issue = "missing-or-generic-caption",
					snippet = substr(tbl, 1, 180),
					stringsAsFactors = FALSE
				)
			})
		)
	}

	# ---- 5) reactable blocks ---------------------------------------------------
	react_pat <- "<div[^>]*class=[\"'][^\"']*reactable[^\"']*[\"'][^>]*>.*?</div>"
	react_locs <- stringi::stri_locate_all_regex(text, react_pat, opts_regex = fig_opts)[[1]]

	react_rows <- NULL
	if (!is.null(dim(react_locs)) && nrow(react_locs) > 0) {
		react_rows <- do.call(
			rbind,
			lapply(seq_len(nrow(react_locs)), function(i) {
				div <- substring(text, react_locs[i, 1], react_locs[i, 2])

				cap <- stringi::stri_match_first_regex(div, "<caption[^>]*>(.*?)</caption>")
				cap <- norm_chr(cap)[2]
				aria <- stringi::stri_match_first_regex(div, "aria-label\\s*=\\s*(['\"])(.*?)\\1")
				aria <- norm_chr(aria)[3]

				if ((nzchar(cap) && !safe_is_non_descriptive(cap)) || (nzchar(aria) && !safe_is_non_descriptive(aria))) {
					return(NULL)
				}

				data.frame(
					kind = "reactable",
					line = to_line(react_locs[i, 1]),
					src = "",
					issue = "missing-or-generic-caption",
					snippet = substr(div, 1, 180),
					stringsAsFactors = FALSE
				)
			})
		)
	}

	# ---- Combine & clean -------------------------------------------------------
	df <- do.call(rbind, Filter(Negate(is.null), list(md_rows, html_rows, md_table_rows, html_table_rows, react_rows)))

	if (!is.null(df) && nrow(df) > 0L) {
		df <- df[!is.na(df$line) & nzchar(df$kind) & nzchar(df$issue), , drop = FALSE]
	}

	if (is.null(df) || nrow(df) == 0L) {
		df <- data.frame(
			kind = character(),
			line = integer(),
			src = character(),
			issue = character(),
			snippet = character()
		)
	} else {
		df <- df[order(df$line, df$kind), , drop = FALSE]
	}

	if (!is.null(output)) {
		utils::write.csv(df, output, row.names = FALSE)
	}

	invisible(df)
}
