touch_at <- function(path, when) {
	writeLines("x", path)
	Sys.setFileTime(path, when)
	path
}

# Stands in for pandoc: writes markdown with a styled placeholder, as a Word file would give
fake_convert <- function(input_file, markdown_file = "markdown_output.md", ...) {
	writeLines("Total: [placeholder_total]{custom-style=\"PlaceholderMarker\"}", markdown_file)
	invisible(markdown_file)
}

mock_convert <- function(env = parent.frame()) {
	local_mocked_bindings(
		convert_markdown = function(input_file, markdown_file = "markdown_output.md", ...) {
			fake_convert(input_file, markdown_file)
		},
		.package = "knittogether",
		.env = env
	)
}

test_that("run_workflow() uses the newest Word file in a folder", {
	dir <- withr::local_tempdir()
	touch_at(file.path(dir, "report_old.docx"), as.POSIXct("2026-01-01", tz = "UTC"))
	newest <- touch_at(file.path(dir, "report_new.docx"), as.POSIXct("2026-06-01", tz = "UTC"))

	seen <- NULL
	local_mocked_bindings(
		convert_markdown = function(input_file, markdown_file = "markdown_output.md", ...) {
			seen <<- input_file
			fake_convert(input_file, markdown_file)
		},
		.package = "knittogether"
	)

	run_workflow(
		input_file = dir,
		markdown_file = file.path(dir, "work.md"),
		code_content = list(total = "42"),
		draft_mode = FALSE,
		marker_mode = "off"
	)
	expect_identical(normalizePath(seen), normalizePath(newest))
})

test_that("run_workflow() base_name limits which folder file is used", {
	dir <- withr::local_tempdir()
	chosen <- touch_at(file.path(dir, "report_1.docx"), as.POSIXct("2026-01-01", tz = "UTC"))
	touch_at(file.path(dir, "other.docx"), as.POSIXct("2026-06-01", tz = "UTC"))

	seen <- NULL
	local_mocked_bindings(
		convert_markdown = function(input_file, markdown_file = "markdown_output.md", ...) {
			seen <<- input_file
			fake_convert(input_file, markdown_file)
		},
		.package = "knittogether"
	)

	run_workflow(
		input_file = dir,
		base_name = "report",
		markdown_file = file.path(dir, "work.md"),
		code_content = list(total = "42"),
		draft_mode = FALSE,
		marker_mode = "off"
	)
	expect_identical(normalizePath(seen), normalizePath(chosen))
})

test_that("run_workflow() fills the file clean_markdown wrote when output_file is set", {
	dir <- withr::local_tempdir()
	mock_convert()
	raw <- file.path(dir, "work.md")
	cleaned <- file.path(dir, "cleaned.md")

	out <- run_workflow(
		input_file = file.path(dir, "draft.docx"),
		markdown_file = raw,
		output_file = cleaned,
		code_content = list(total = "42"),
		draft_mode = FALSE,
		marker_mode = "off"
	)
	# The replacement works on the cleaned text: the styled marker is gone
	expect_identical(out, "Total: 42")
	expect_identical(readLines(cleaned), "Total: 42")
	# The raw convert output is left as convert wrote it
	expect_true(any(grepl("PlaceholderMarker", readLines(raw), fixed = TRUE)))
})

test_that("run_workflow() overwrites the markdown in place when no output_file is given", {
	dir <- withr::local_tempdir()
	mock_convert()
	raw <- file.path(dir, "work.md")

	out <- run_workflow(
		input_file = file.path(dir, "draft.docx"),
		markdown_file = raw,
		code_content = list(total = "42"),
		draft_mode = FALSE,
		marker_mode = "off"
	)
	expect_identical(out, "Total: 42")
	expect_identical(readLines(raw), "Total: 42")
})
