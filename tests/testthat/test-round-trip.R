# The workflow's central claim: content written from R survives a trip through Word and back, and is refreshed (not
# duplicated) when the R code changes. Needs Pandoc to stand in for Word.
pandoc_bin <- function() {
	p <- unname(Sys.which("pandoc"))
	if (!nzchar(p)) testthat::skip("pandoc not installed")
	p
}

to_docx <- function(md, docx, bin) {
	status <- system2(bin, c(shQuote(md), "-o", shQuote(docx)))
	if (!identical(status, 0L)) stop("pandoc failed to write ", docx, call. = FALSE)
	invisible(docx)
}

test_that("draft content survives a Word round trip and is refreshed, not duplicated", {
	bin <- pandoc_bin()
	tmp <- withr::local_tempdir()

	# 1. A Word draft with a placeholder, as the writer would have it
	draft_md <- file.path(tmp, "draft.md")
	writeLines(c("# Report", "", "In total, placeholder_total people were referred."), draft_md)
	draft_docx <- file.path(tmp, "draft.docx")
	to_docx(draft_md, draft_docx, bin)

	# 2. The coder converts it, cleans it and fills in R output (draft mode on, as the default)
	md <- file.path(tmp, "work.md")
	convert_markdown(draft_docx, markdown_file = md, media_base_dir = NULL)
	clean_markdown(md, clear_placeholder_styling = TRUE)
	replace_placeholders(md, code_content = list(total = "42"), draft_mode = TRUE, marker_mode = "hidden")
	filled <- paste(readLines(md, warn = FALSE), collapse = "\n")
	start_marker <- eval(formals(replace_placeholders)$draft_mode_prefix); expect_match(filled, start_marker, fixed = TRUE)
	expect_match(filled, "42", fixed = TRUE)

	# 3. The writer edits the filled draft in Word (modelled by pandoc round trip) and it comes back to the coder
	edited_docx <- file.path(tmp, "edited.docx")
	to_docx(md, edited_docx, bin)
	md2 <- file.path(tmp, "back.md")
	convert_markdown(edited_docx, markdown_file = md2, media_base_dir = NULL)
	clean_markdown(md2, clear_draft = TRUE, clear_placeholder_styling = TRUE)
	cleared <- readLines(md2, warn = FALSE)
	expect_false(any(grepl("DRAFT_CONTENT", cleared, fixed = TRUE)))
	expect_false(any(grepl("42", cleared, fixed = TRUE)))
	expect_equal(sum(grepl("placeholder_total", cleared, fixed = TRUE)), 1L)

	# 4. The R result changes; re-running replaces the old output rather than adding a second copy
	replace_placeholders(md2, code_content = list(total = "43"), draft_mode = TRUE, marker_mode = "hidden")
	refreshed <- readLines(md2, warn = FALSE)
	expect_equal(sum(grepl("43", refreshed, fixed = TRUE)), 1L)
	expect_false(any(grepl("42", refreshed, fixed = TRUE)))
	expect_equal(sum(grepl(start_marker, refreshed, fixed = TRUE)), 1L)
})

test_that("a placeholder inserted with marker_mode = 'off' cannot be found again on re-import", {
	tmp <- withr::local_tempdir()
	md <- file.path(tmp, "work.md")
	writeLines("Total: placeholder_total", md)
	replace_placeholders(md, code_content = list(total = "42"), draft_mode = FALSE, marker_mode = "off")

	# Nothing marks the inserted value, so a later pass has no placeholder to refresh
	expect_identical(readLines(md, warn = FALSE), "Total: 42")
})
