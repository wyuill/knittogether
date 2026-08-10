testthat::skip_if_not_installed("withr")

test_that("generate_quality_check creates log on first run and marks new content as changed", {
	td <- withr::local_tempdir() # auto-cleaned after the test
	validation_dir <- file.path(td, "validation")
	md_file <- file.path(td, "test.md")

	# simple markdown with two placeholders
	writeLines(c("Some text", "placeholder_content_id1", "More text", "placeholder_content_id2"), md_file)

	code_map <- list(
		id1 = list(
			placeholder_id = "id1",
			description = "desc1",
			content_type = "R",
			output_mode = "inline",
			content_expr = "1+1"
		),
		id2 = list(
			placeholder_id = "id2",
			description = "desc2",
			content_type = "R",
			output_mode = "inline",
			content_expr = "2+2"
		),
		# scalar example
		version = "0.1.0"
	)

	df <- generate_quality_check(code_map, markdown_file = md_file, validation_path = validation_dir)

	# files created?
	expect_true(file.exists(file.path(validation_dir, "quality_log.csv")))

	# correct structure of returned df (base-R check)
	expect_true(all(c("placeholder_id", "changed_code") %in% names(df)))

	# all rows should be flagged changed (no previous rows in this context)
	expect_true(all(df$changed_code))
})

testthat::skip_if_not_installed("withr")

test_that("generate_quality_check detects unchanged code on second run", {
	td <- withr::local_tempdir()
	validation_dir <- file.path(td, "validation2")
	md_file <- file.path(td, "test2.md")

	writeLines("placeholder_content_id1", md_file)

	code_map <- list(
		id1 = list(
			placeholder_id = "id1",
			description = "desc1",
			content_type = "R",
			output_mode = "inline",
			content_expr = "1+1"
		)
	)

	# first run (fresh dir/context) -> changed == TRUE
	df1 <- generate_quality_check(code_map, markdown_file = md_file, validation_path = validation_dir)
	expect_true(all(df1$changed_code))

	# second run (same dir/context and same code) -> changed == FALSE
	df2 <- generate_quality_check(code_map, markdown_file = md_file, validation_path = validation_dir)

	expect_true(all(df2$changed_code == FALSE))
	expect_equal(sum(df2$changed_code), 0) # no changed placeholders
})

testthat::skip_if_not_installed("withr")

test_that("markdown context snippet is extracted correctly", {
	td <- withr::local_tempdir()
	validation_dir <- file.path(td, "validation3")
	md_file <- file.path(td, "test3.md")

	writeLines(c("alpha beta gamma", "placeholder_content_ctx1 here", "delta epsilon zeta"), md_file)

	code_map <- list(ctx1 = list(placeholder_id = "ctx1", content_expr = "99"))

	df <- generate_quality_check(code_map, markdown_file = md_file, validation_path = validation_dir)

	# Ensure we have the row for ctx1
	expect_true(any(df$placeholder_id == "ctx1"))
})

testthat::skip_if_not_installed("withr")

test_that("generate_quality_check handles malformed existing log by treating it as empty", {
	td <- withr::local_tempdir()
	validation_dir <- file.path(td, "validation_malformed")
	dir.create(validation_dir, recursive = TRUE)
	md_file <- file.path(td, "test_malformed.md")
	writeLines("placeholder_content_id1", md_file)

	# Missing required columns on purpose
	utils::write.csv(data.frame(bad_col = "x"), file.path(validation_dir, "quality_log.csv"), row.names = FALSE)

	code_map <- list(
		id1 = list(
			placeholder_id = "id1",
			description = "desc1",
			content_type = "R",
			output_mode = "inline",
			content_expr = "1+1"
		)
	)

	df <- generate_quality_check(code_map, markdown_file = md_file, validation_path = validation_dir)

	expect_true(any(df$placeholder_id == "id1"))
	expect_true(all(df$changed_code))
})

test_that("generate_quality_check works when log and html outputs are disabled", {
	td <- withr::local_tempdir()
	validation_dir <- file.path(td, "validation_disabled")
	md_file <- file.path(td, "test_disabled.md")
	writeLines("placeholder_content_id1", md_file)

	code_map <- list(
		id1 = list(
			placeholder_id = "id1",
			description = "desc1",
			content_type = "R",
			output_mode = "inline",
			content_expr = "1+1"
		)
	)

	df <- generate_quality_check(
		code_content = code_map,
		markdown_file = md_file,
		validation_path = validation_dir,
		log_file = NULL,
		html_file = NULL
	)

	expect_true(any(df$placeholder_id == "id1"))
	expect_false(file.exists(file.path(validation_dir, "quality_log.csv")))
	expect_false(file.exists(file.path(validation_dir, "validation.html")))
})

test_that("scalars are included as rows with NA context fields", {
	td <- withr::local_tempdir()
	validation_dir <- file.path(td, "validation4")
	md_file <- file.path(td, "test4.md")
	writeLines("", md_file)

	code_map <- list(
		id1 = list(placeholder_id = "id1", content_expr = "123"),
		version = "0.2.0" # scalar
	)

	df <- generate_quality_check(code_map, markdown_file = md_file, validation_path = validation_dir)

	# scalar row is present
	expect_true(any(df$placeholder_id == "version"))

	scalar_row <- df[df$placeholder_id == "version", , drop = FALSE]
	expect_equal(scalar_row$content_preview, "0.2.0")

	# Scalars don't have description/content_type/output_mode in the map -> NA expected
	expect_true(is.na(scalar_row$description))
})
