test_that("draft_mode = FALSE removes draft markers left by an earlier draft pass", {
	tmp <- withr::local_tempfile(fileext = ".md")
	writeLines(c("placeholder_total", "", "placeholder_plot"), tmp)

	replace_placeholders(tmp, code_content = list(total = "42", plot = "PLOT"), draft_mode = TRUE, marker_mode = "hidden")
	expect_true(any(grepl("DRAFT_CONTENT_START", readLines(tmp), fixed = TRUE)))

	out <- replace_placeholders(tmp, code_content = list(total = "43", plot = "PLOT2"), draft_mode = FALSE,
		marker_mode = "hidden")
	expect_false(any(grepl("DRAFT_CONTENT", out, fixed = TRUE)))
	expect_true(any(grepl("43", out, fixed = TRUE)))
	expect_true(any(grepl("PLOT2", out, fixed = TRUE)))
	expect_false(any(grepl("42", out, fixed = TRUE)))
	expect_false(any(grepl("PLOT\\b", out, perl = TRUE)))
})

test_that("draft_mode = FALSE leaves draft blocks without a placeholder marker unchanged", {
	tmp <- withr::local_tempfile(fileext = ".md")
	writeLines(c("DRAFT_CONTENT_START", "hand-written text", "DRAFT_CONTENT_END", "", "placeholder_total"), tmp)

	out <- replace_placeholders(tmp, code_content = list(total = "7"), draft_mode = FALSE, marker_mode = "off")
	expect_true(any(out == "hand-written text"))
	expect_true(any(out == "DRAFT_CONTENT_START"))
	expect_true(any(out == "7"))
})

test_that("draft_mode = TRUE still writes draft blocks", {
	tmp <- withr::local_tempfile(fileext = ".md")
	writeLines("placeholder_total", tmp)
	out <- replace_placeholders(tmp, code_content = list(total = "7"), draft_mode = TRUE, marker_mode = "off")
	expect_true(any(out == "DRAFT_CONTENT_START"))
	expect_true(any(out == "DRAFT_CONTENT_END"))
})
