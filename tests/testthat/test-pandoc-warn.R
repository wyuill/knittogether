test_that("convert_markdown() warns for pptx when no Pandoc meets 3.8.3", {
	tmp <- withr::local_tempdir()
	input <- file.path(tmp, "slides.pptx")
	output <- file.path(tmp, "slides.md")
	writeLines("dummy", input)

	local_mocked_bindings(
		pandoc_version = function(...) numeric_version("3.7.0"),
		pandoc_run = function(...) NULL,
		.package = "pandoc"
	)
	local_mocked_bindings(.bundled_pandoc_bins = function() character())

	expect_warning(
		convert_markdown(input_file = input, markdown_file = output, pandoc_version = "default"),
		"below"
	)
})

test_that("convert_markdown() does not warn when a bundled Pandoc meets 3.8.3", {
	tmp <- withr::local_tempdir()
	input <- file.path(tmp, "slides.pptx")
	output <- file.path(tmp, "slides.md")
	writeLines("dummy", input)

	local_mocked_bindings(
		pandoc_version = function(...) numeric_version("3.7.0"),
		.package = "pandoc"
	)
	local_mocked_bindings(
		.resolve_pandoc = function(pandoc_version = "default") {
			list(ver = numeric_version("3.10"), binary = "bundled-pandoc", fallback = TRUE)
		}
	)
	local_mocked_bindings(
		system2 = function(...) 0L,
		.package = "base"
	)

	expect_no_warning(
		convert_markdown(input_file = input, markdown_file = output, pandoc_version = "default")
	)
})
