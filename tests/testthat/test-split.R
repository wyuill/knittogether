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

  out <- split(tmp_md, qmd = "none")

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

  split(tmp_md, qmd = "separate")

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

  split(tmp_md, qmd = "separate")

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

  split(tmp_md, qmd = "separate", rewrite_includes = FALSE)

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

  out <- split(tmp_md, qmd = "embed")

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
    split(tmp_md, qmd = "none"),
    "No split points found"
  )
})

