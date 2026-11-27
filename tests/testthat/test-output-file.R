test_that("clean_markdown() writes to output_file and leaves the input unchanged", {
	tmp <- withr::local_tempdir()
	input <- file.path(tmp, "in.md")
	output <- file.path(tmp, "out.md")
	writeLines(c("Text [placeholder_a]{custom-style=\"PlaceholderMarker\"} end"), input)
	before <- readLines(input)

	clean_markdown(input, clear_placeholder_styling = TRUE, output_file = output)

	expect_identical(readLines(input), before)
	expect_identical(readLines(output), "Text placeholder_a end")
})

test_that("clean_markdown() overwrites in place by default", {
	tmp <- withr::local_tempdir()
	input <- file.path(tmp, "in.md")
	writeLines("Text [placeholder_a]{custom-style=\"PlaceholderMarker\"}", input)
	clean_markdown(input, clear_placeholder_styling = TRUE)
	expect_identical(readLines(input), "Text placeholder_a")
})

test_that("clean_markdown() with overwrite = FALSE refuses to write over an existing file", {
	tmp <- withr::local_tempdir()
	input <- file.path(tmp, "in.md")
	output <- file.path(tmp, "out.md")
	writeLines("a", input)
	writeLines("keep me", output)

	expect_error(clean_markdown(input, output_file = output, overwrite = FALSE), "overwrite = FALSE")
	expect_identical(readLines(output), "keep me")
})

test_that("replace_placeholders() writes to output_file and leaves the input unchanged", {
	tmp <- withr::local_tempdir()
	input <- file.path(tmp, "in.md")
	output <- file.path(tmp, "filled.md")
	writeLines("Total: placeholder_total", input)
	before <- readLines(input)

	replace_placeholders(input, code_content = list(total = "42"), draft_mode = FALSE,
		marker_mode = "off", output_file = output)

	expect_identical(readLines(input), before)
	expect_identical(readLines(output), "Total: 42")
})

test_that("replace_placeholders() with overwrite = FALSE refuses to write over an existing output", {
	tmp <- withr::local_tempdir()
	input <- file.path(tmp, "in.md")
	output <- file.path(tmp, "filled.md")
	writeLines("Total: placeholder_total", input)
	writeLines("keep me", output)

	expect_error(
		replace_placeholders(input, code_content = list(total = "42"), draft_mode = FALSE,
			marker_mode = "off", output_file = output, overwrite = FALSE),
		"overwrite = FALSE"
	)
	expect_identical(readLines(output), "keep me")
})

test_that("convert_markdown() with overwrite = FALSE refuses an existing markdown file before running pandoc", {
	tmp <- withr::local_tempdir()
	input <- file.path(tmp, "draft.docx")
	md <- file.path(tmp, "draft.md")
	writeLines("dummy", input)
	writeLines("keep me", md)

	expect_error(
		convert_markdown(input, markdown_file = md, overwrite = FALSE),
		"overwrite = FALSE"
	)
	expect_identical(readLines(md), "keep me")
})
