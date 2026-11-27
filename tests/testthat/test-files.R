make_file <- function(dir, name, when) {
	path <- file.path(dir, name)
	writeLines("x", path)
	Sys.setFileTime(path, when)
	path
}

test_that("latest_word_file() returns the most recently modified file", {
	dir <- withr::local_tempdir()
	make_file(dir, "old.docx", as.POSIXct("2026-01-01 10:00:00", tz = "UTC"))
	newest <- make_file(dir, "new.docx", as.POSIXct("2026-06-01 10:00:00", tz = "UTC"))
	make_file(dir, "mid.pptx", as.POSIXct("2026-03-01 10:00:00", tz = "UTC"))
	expect_identical(normalizePath(latest_word_file(dir)), normalizePath(newest))
})

test_that("latest_word_file() ignores Word lock files", {
	dir <- withr::local_tempdir()
	make_file(dir, "report.docx", as.POSIXct("2026-01-01 10:00:00", tz = "UTC"))
	make_file(dir, "~$report.docx", as.POSIXct("2026-06-01 10:00:00", tz = "UTC"))
	expect_identical(basename(latest_word_file(dir)), "report.docx")
})

test_that("latest_word_file() filters by base_name", {
	dir <- withr::local_tempdir()
	make_file(dir, "report_1031.docx", as.POSIXct("2026-06-01 10:00:00", tz = "UTC"))
	make_file(dir, "other.docx", as.POSIXct("2026-07-01 10:00:00", tz = "UTC"))
	expect_identical(basename(latest_word_file(dir, base_name = "report")), "report_1031.docx")
})

test_that("latest_word_file() only considers the requested extensions", {
	dir <- withr::local_tempdir()
	make_file(dir, "notes.txt", as.POSIXct("2026-07-01 10:00:00", tz = "UTC"))
	make_file(dir, "deck.pptx", as.POSIXct("2026-01-01 10:00:00", tz = "UTC"))
	expect_identical(basename(latest_word_file(dir)), "deck.pptx")
	expect_identical(basename(latest_word_file(dir, ext = "pptx")), "deck.pptx")
})

test_that("latest_word_file() errors clearly when nothing matches", {
	dir <- withr::local_tempdir()
	expect_error(latest_word_file(dir), "No docx or pptx file found")
	expect_error(latest_word_file(file.path(dir, "missing")), "Folder not found")
})

test_that("timestamped_path() stamps the name with the time", {
	p <- timestamped_path(file.path(tempdir(), "report.docx"),
		time = as.POSIXct("2026-11-27 09:30:15", tz = "UTC"), format = "%Y%m%d_%H%M%S")
	expect_identical(basename(p), "report_20261127_093015.docx")
})

test_that("timestamped_path() never returns the name of an existing file", {
	dir <- withr::local_tempdir()
	t <- as.POSIXct("2026-11-27 09:30:15", tz = "UTC")
	first <- timestamped_path(file.path(dir, "report.docx"), time = t)
	file.create(first)
	second <- timestamped_path(file.path(dir, "report.docx"), time = t)
	expect_false(file.exists(second))
	expect_identical(basename(second), "report_20261127_093015_2.docx")
})
