# Helper: create a DOCX from Markdown using pandoc
make_docx_from_md <- function(md_text, target_docx) {
	md_file <- tempfile(fileext = ".md")
	writeLines(md_text, md_file)
	pandoc::pandoc_run(paste0(md_file, " -f markdown -t docx -o ", target_docx))
	target_docx
}

# Helper: create a DOCX containing an embedded image
make_docx_with_image <- function(target_docx) {
	img <- tempfile(fileext = ".png")

	# Create a real PNG image
	png(img, width = 200, height = 200)
	plot(1, main = "Test image")
	dev.off()

	# Use proper Markdown image embedding syntax
	md <- c("# Document with image", "", "Here is an embedded image:", "", sprintf("![](%s)", img))

	make_docx_from_md(md, target_docx)
}

testthat::skip_if_not_installed("withr")
testthat::skip_if_not(pandoc::pandoc_available())

test_that("convert creates a markdown file from docx", {
	tmp <- withr::local_tempdir()

	input <- file.path(tmp, "simple.docx")
	output <- file.path(tmp, "simple.md")

	make_docx_from_md("Hello **world**", input)

	res <- convert_markdown(input_file = input, markdown_file = output, media_base_dir = NULL, pandoc_version = "default")

	expect_true(file.exists(output))
	expect_null(res$media_dir)
	expect_equal(res$markdown_file, output)
})

testthat::skip_if_not_installed("withr")
testthat::skip_if_not(pandoc::pandoc_available())

test_that("media extraction works with a DOCX containing embedded images", {
	tmp <- withr::local_tempdir()

	input <- file.path(tmp, "with_media.docx")
	output <- file.path(tmp, "with_media.md")
	media_base <- file.path(tmp, "")

	make_docx_with_image(input)

	res <- convert_markdown(input_file = input, markdown_file = output, media_base_dir = media_base, pandoc_version = "default")

	media_dir <- file.path(media_base, "media")

	expect_true(dir.exists(media_dir))
	expect_true(length(list.files(media_dir, recursive = TRUE)) >= 1)

	expect_equal(res$markdown_file, output)
	expect_equal(
		normalizePath(res$media_dir, mustWork = FALSE),
		normalizePath(media_dir, mustWork = FALSE)
	)
})

testthat::skip_if_not_installed("withr")
testthat::skip_if_not(pandoc::pandoc_available())

test_that("media extraction is disabled with NULL", {
	tmp <- withr::local_tempdir()

	input <- file.path(tmp, "no_media.docx")
	output <- file.path(tmp, "no_media.md")

	make_docx_from_md("Just text, no media here.", input)

	res <- convert_markdown(input_file = input, markdown_file = output, media_base_dir = NULL, pandoc_version = "default")

	expect_true(file.exists(output))
	expect_null(res$media_dir)
})

testthat::skip_if_not_installed("withr")
testthat::skip_if_not(pandoc::pandoc_available())

test_that("pandoc_args are passed safely", {
	tmp <- withr::local_tempdir()

	input <- file.path(tmp, "args.docx")
	output <- file.path(tmp, "args.md")

	make_docx_from_md("Some *emphasis* text.", input)

	res <- convert_markdown(input_file = input, markdown_file = output, pandoc_args = "--citeproc", pandoc_version = "default")

	expect_true(file.exists(res$markdown_file))
})

testthat::skip_if_not_installed("withr")
testthat::skip_if_not(pandoc::pandoc_available())

test_that("convert errors when input file does not exist", {
	tmp <- withr::local_tempdir()
	missing <- file.path(tmp, "missing.docx")
	out <- file.path(tmp, "out.md")

	expect_error(
		convert_markdown(input_file = missing, markdown_file = out),
		"File not found"
	)
})

test_that("convert errors for unsupported extension", {
	tmp <- withr::local_tempdir()
	input <- file.path(tmp, "not_supported.txt")
	out <- file.path(tmp, "out.md")
	writeLines("hello", input)

	expect_error(
		convert_markdown(input_file = input, markdown_file = out),
		"must be a .docx or .pptx"
	)
})

test_that("function returns invisible named list with expected fields", {
	tmp <- withr::local_tempdir()

	input <- file.path(tmp, "shape.docx")
	output <- file.path(tmp, "shape.md")

	make_docx_from_md("Ok.", input)

	result <- expect_invisible(convert_markdown(
		input_file = input,
		markdown_file = output,
		media_base_dir = NULL,
		pandoc_version = "default"
	))

	expect_type(result, "list")
	expect_named(result, c("markdown_file", "media_dir"))
	expect_identical(result$markdown_file, output)
	expect_null(result$media_dir)
})
