test_that("markdown is split into folders with correct content (qmd = none)", {

  tmp_dir <- withr::local_tempdir()
  withr::local_dir(tmp_dir)
  tmp_md <- withr::local_tempfile(fileext = ".md")

  writeLines(
    c(
      "# Heading 1",
      "",
      "Text1",
      "",
      "## subheading 1",
      "",
      "Text2",
      "",
      "# Heading 2",
      "",
      "Text3"
    ),
    tmp_md
  )

  out <- split_markdown(tmp_md, qmd = "none")

  expect_length(out, 2)

  expect_true(dir.exists("heading-1"))
  expect_true(dir.exists("heading-2"))

  md1 <- readLines("heading-1/output.md")
  md2 <- readLines("heading-2/output.md")

  expect_equal(
    md1,
    c(
      "# Heading 1",
      "",
      "Text1",
      "",
      "## subheading 1",
      "",
      "Text2",
      ""
    )
  )

  expect_equal(
    md2,
    c(
      "# Heading 2",
      "",
      "Text3"
    )
  )
})

test_that("qmd files are created with correct yaml and include", {

  tmp_dir <- withr::local_tempdir()
  withr::local_dir(tmp_dir)
  tmp_md <- withr::local_tempfile(fileext = ".md")

  writeLines(
    c(
      "# Heading 1",
      "Text1",
      "",
      "# Heading 2",
      "Text2"
    ),
    tmp_md
  )

  split_markdown(tmp_md, qmd = "separate")

  expect_true(file.exists("heading-1/index.qmd"))
  expect_true(file.exists("heading-1/output.md"))

  qmd1 <- readLines("heading-1/index.qmd")

  expect_equal(
    qmd1,
    c(
      "---",
      "title: \"Heading 1\"",
      "order: 1",
      "---",
      "",
      "{{< include output.md >}}"
    )
  )

  md1 <- readLines("heading-1/output.md")
  expect_false(any(grepl("^# ", md1)))
})

test_that("include paths are rewritten when qmd != none and rewrite_includes = auto", {

  tmp_dir <- withr::local_tempdir()
  withr::local_dir(tmp_dir)
  tmp_md <- withr::local_tempfile(fileext = ".md")

  writeLines(
    c(
      "# Heading 1",
      "{{< include includes/example.qmd >}}"
    ),
    tmp_md
  )

  split_markdown(tmp_md, qmd = "separate")

  md <- readLines("heading-1/output.md")

  expect_true(any(grepl("\\{\\{< include ../includes/example.qmd >\\}\\}", md)))
})

test_that("include paths are not rewritten when rewrite_includes = FALSE", {

  tmp_dir <- withr::local_tempdir()
  withr::local_dir(tmp_dir)
  tmp_md <- withr::local_tempfile(fileext = ".md")

  writeLines(
    c(
      "# Heading 1",
      "{{< include includes/example.qmd >}}"
    ),
    tmp_md
  )

  split_markdown(tmp_md, qmd = "separate", rewrite_includes = FALSE)

  md <- readLines("heading-1/output.md")

  expect_true(any(grepl("\\{\\{< include includes/example.qmd >\\}\\}", md)))
})

test_that("markdown is embedded directly in index.qmd when qmd = embed", {

  tmp_dir <- withr::local_tempdir()
  withr::local_dir(tmp_dir)
  tmp_md <- withr::local_tempfile(fileext = ".md")

  writeLines(
    c(
      "# Heading 1",
      "Text1"
    ),
    tmp_md
  )

  out <- split_markdown(tmp_md, qmd = "embed")

  expect_true(file.exists("heading-1/index.qmd"))
  expect_false(file.exists("heading-1/output.md"))

  qmd <- readLines("heading-1/index.qmd")

  expect_true(any(grepl("Text1", qmd)))
  expect_false(any(grepl("^# Heading", qmd)))
})

test_that("error is thrown when no split headers are found", {

  tmp_dir <- withr::local_tempdir()
  withr::local_dir(tmp_dir)
  tmp_md <- withr::local_tempfile(fileext = ".md")

  writeLines(
    c(
      "No headings here",
      "Just text"
    ),
    tmp_md
  )

  expect_error(
    split_markdown(tmp_md, qmd = "none"),
    "No split points found"
  )
})


# Edge cases (PHDAT-NEW split) ----
test_that("a single output_dir gives each section its own subfolder", {
	tmp <- withr::local_tempdir()
	md <- file.path(tmp, "doc.md")
	writeLines(c("# Alpha", "", "a text", "# Beta", "", "b text"), md)
	paths <- split_markdown(md, output_dir = file.path(tmp, "out"), qmd = "none")
	expect_identical(readLines(file.path(tmp, "out", "alpha", "output.md")), c("# Alpha", "", "a text"))
	expect_identical(readLines(file.path(tmp, "out", "beta", "output.md")), c("# Beta", "", "b text"))
	expect_length(paths, 2L)
})

test_that("repeated headings get distinct folders", {
	tmp <- withr::local_tempdir()
	md <- file.path(tmp, "doc.md")
	writeLines(c("# Intro", "one", "# Intro", "two", "# Intro", "three"), md)
	withr::local_dir(tmp)
	split_markdown(md, qmd = "none")
	expect_true(all(c("intro", "intro-2", "intro-3") %in% list.dirs(tmp, full.names = FALSE, recursive = FALSE)))
	expect_identical(readLines(file.path(tmp, "intro-2", "output.md"))[2], "two")
})

test_that("content before the first split point is kept in a file, not dropped", {
	tmp <- withr::local_tempdir()
	md <- file.path(tmp, "doc.md")
	writeLines(c("---", "title: Report", "---", "# First", "text"), md)
	paths <- suppressMessages(split_markdown(md, output_dir = file.path(tmp, "out"), qmd = "none"))
	preamble <- file.path(tmp, "split_preamble.md")
	expect_identical(normalizePath(paths[1], winslash = "/"), normalizePath(preamble, winslash = "/"))
	expect_identical(readLines(preamble), c("---", "title: Report", "---"))
})

test_that("titles containing quotes are escaped in the YAML header", {
	tmp <- withr::local_tempdir()
	md <- file.path(tmp, "doc.md")
	writeLines(c('# Say "hi"', "text"), md)
	split_markdown(md, output_dir = file.path(tmp, "out"), qmd = "separate")
	lines <- readLines(file.path(tmp, "out", "say-hi", "index.qmd"))
	expect_identical(lines[2], paste0("title: ", .yaml_string('Say "hi"')))
})

test_that(".yaml_string() escapes quotes and backslashes", {
	expect_identical(.yaml_string("plain"), "\"plain\"")
	expect_identical(.yaml_string('a"b'), '"a\\"b"')
	expect_identical(.yaml_string("a\\b"), "\"a\\\\b\"")
})
