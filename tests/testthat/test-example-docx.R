# The example template styles its placeholders as superscript (PlaceholderMarkerVisible) and subscript
# (PlaceholderMarker), and brackets them with U+27E6 / U+27E7. (PHDAT-1198 follow-up)
test_that("cleaning the example docx removes the superscript/subscript wrapping and the brackets", {
	skip_if_not(pandoc::pandoc_available(), "Pandoc not available")
	docx <- system.file("extdata", "PlaceholderMarker_example.docx", package = "knittogether")
	skip_if(!nzchar(docx), "example docx not installed")

	tmp <- withr::local_tempdir()
	md <- file.path(tmp, "example.md")
	convert_markdown(docx, markdown_file = md, media_base_dir = NULL)
	clean_markdown(md, clear_placeholder_styling = TRUE, placeholder_prefix = "placeholder")
	out <- readLines(md, warn = FALSE)

	visible <- "placeholder_visible"
	hidden <- "placeholder_invisible"
	expect_true(any(out == visible))
	expect_true(any(out == hidden))

	wrap_before <- "[\\^~]"
	expect_false(any(grepl(paste0(wrap_before, visible), out)))
	expect_false(any(grepl(paste0(visible, wrap_before), out)))
	expect_false(any(grepl(paste0(wrap_before, hidden), out)))
	expect_false(any(grepl(paste0(hidden, wrap_before), out)))

	placeholder_lines <- out[grepl("placeholder_", out, fixed = TRUE)]
	expect_false(any(grepl("⟦", placeholder_lines, fixed = TRUE)))
	expect_false(any(grepl("⟧", placeholder_lines, fixed = TRUE)))
})
