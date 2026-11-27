real_pandoc <- function() {
	p <- unname(Sys.which("pandoc"))
	if (!nzchar(p)) testthat::skip("pandoc not installed")
	p
}

test_that("minimum Pandoc version for pptx is 3.8.3", {
	expect_identical(.pandoc_min_version(), numeric_version("3.8.3"))
})

test_that(".pandoc_version_at() reads the version of a real pandoc", {
	v <- .pandoc_version_at(real_pandoc())
	expect_s3_class(v, "numeric_version")
	expect_gt(length(unlist(v)), 1L)
})

test_that(".pandoc_version_at() returns NULL for a missing binary", {
	expect_null(.pandoc_version_at(file.path(tempdir(), "no-such-pandoc-binary")))
})

test_that("convert_markdown() defaults to pandoc_version = 'default'", {
	expect_identical(formals(convert_markdown)$pandoc_version, "default")
})

test_that(".resolve_pandoc() uses the default pandoc when it meets the minimum", {
	local_mocked_bindings(pandoc_version = function(version) numeric_version("3.9"), .package = "pandoc")
	r <- .resolve_pandoc("default")
	expect_false(r$fallback)
	expect_identical(r$ver, numeric_version("3.9"))
	# The executable on PATH is the one that is run, not pandoc::pandoc_run()
	expect_identical(r$binary, unname(Sys.which("pandoc")))
})

test_that(".resolve_pandoc() uses pandoc::pandoc_run() for an explicit version", {
	local_mocked_bindings(pandoc_version = function(version) numeric_version("3.9"), .package = "pandoc")
	r <- .resolve_pandoc("3.9")
	expect_null(r$binary)
})

test_that(".resolve_pandoc() falls back to a bundled pandoc when the default is missing", {
	p <- real_pandoc()
	if (.pandoc_version_at(p) < .pandoc_min_version()) testthat::skip("bundled pandoc is older than 3.8.3")

	withr::local_envvar(RSTUDIO_PANDOC = dirname(p))
	local_mocked_bindings(pandoc_version = function(version) stop("not installed"), .package = "pandoc")

	r <- .resolve_pandoc("default")
	expect_true(r$fallback)
	expect_identical(normalizePath(r$binary), normalizePath(p))
	expect_gte(r$ver, .pandoc_min_version())
})

test_that(".resolve_pandoc() never falls back for an explicit version", {
	withr::local_envvar(RSTUDIO_PANDOC = dirname(real_pandoc()))
	local_mocked_bindings(pandoc_version = function(version) stop("not installed"), .package = "pandoc")

	r <- .resolve_pandoc("latest")
	expect_null(r$binary)
	expect_false(r$fallback)
	expect_identical(r$ver, numeric_version("0"))
})

test_that(".bundled_pandoc_bins() copes with Quarto not being installed", {
	skip_if_not_installed("quarto")
	# quarto_path() returns NULL, not NA, when Quarto can't be found
	local_mocked_bindings(quarto_path = function(...) NULL, .package = "quarto")
	withr::local_envvar(RSTUDIO_PANDOC = "")
	expect_identical(.bundled_pandoc_bins(), character())
})
