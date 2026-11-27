test_that("run_workflow() errors on an unrecognised argument name before doing any work", {
	tmp <- tempfile(fileext = ".md")
	writeLines("untouched", tmp)
	expect_error(
		run_workflow(markdown_file = tmp, heading_ofset = TRUE),
		"heading_ofset"
	)
	expect_identical(readLines(tmp), "untouched")
})

test_that("run_workflow() reports every unrecognised name", {
	expect_error(run_workflow(bogus_one = 1, bogus_two = 2), "bogus_one.*bogus_two")
})

test_that("run_workflow() requires named arguments", {
	expect_error(run_workflow("markdown.md"), "must be named")
})
