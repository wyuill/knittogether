test_that("slide_break() returns '---' for non-HTML output", {
	local_mocked_bindings(is_html = function() FALSE)
	expect_equal(slide_break(), "---")
})

test_that("slide_break() returns NULL for HTML output", {
	local_mocked_bindings(is_html = function() TRUE)
	expect_null(slide_break())
})

# insert_slide_break ----------------------------------------------------------

test_that("insert_slide_break() returns text unchanged when below limit", {
	txt <- "Short text."
	expect_equal(insert_slide_break(txt, limit = 50), txt)
})

test_that("insert_slide_break() inserts break at sentence boundary", {
	txt <- "This is sentence one. This is sentence two."
	out <- insert_slide_break(txt, limit = 22, break_fun = function() "---")
	expect_true(grepl("\\n\\n---\\n\\n", out))
	expect_match(out, "one\\.")
})

test_that("insert_slide_break() handles break at limit", {
	txt <- "This is sentence one. This is sentence two."
	out <- insert_slide_break(txt, limit = 20, break_fun = function() "---")
	expect_true(grepl("\\n\\n---\\n\\n", out))
	expect_match(out, "one\\.")
})

test_that("insert_slide_break() prefers non-slide headers (###) over sentence/paragraph/word breaks", {
	txt <- paste0(
		"First sentence ends here. ", # sentence boundary
		"Then some more words to create space. ",
		"\n\n", # paragraph break
		"More filler text here.\n",
		"### NonSlideHeader\n", # the header break
		"A short sentence. ", # sentence boundary
		"Some more text continues after the heading."
	)

	out <- insert_slide_break(txt, limit = 110, break_fun = function() "---", slide_levels = c(1, 2))
	parts <- strsplit(out, "\\n\\n---\\n\\n")[[1]]

	expect_equal(length(parts), 2)
	expect_true(grepl("More filler text here\\.$", trimws(parts[1])))
	expect_true(grepl("^### NonSlideHeader", trimws(parts[2])))
})

test_that("insert_slide_break() treats slide-level headers as natural breaks", {
	txt <- "Intro text\n# Slide\nMore text"
	out <- insert_slide_break(txt, limit = 20, break_fun = function() "---", slide_levels = c(1))
	expect_true(grepl("\\n\\n---\\n\\n# Slide", out))
})

# auto_slide_break ------------------------------------------------------------

test_that("auto_slide_break() repeatedly applies insert_slide_break()", {
	txt <- paste(rep("Sentence. ", 20), collapse = "")
	out <- auto_slide_break(txt, limit = 60, break_fun = function() "---")
	expect_true(length(gregexpr("\\n\\n---\\n\\n", out)[[1]]) > 1)
})

# Column helpers --------------------------------------------------------------

test_that("pptx_col_start/break/end return text for non-HTML", {
	local_mocked_bindings(is_html = function() FALSE)
	expect_equal(pptx_col_start(40), ":::: columns\n::: {.column width='40%'}")
	expect_equal(pptx_col_break(60), ":::\n::: {.column width='60%'}")
	expect_equal(pptx_col_end(), ":::\n::::")
})

test_that("pptx_col_* return NULL for HTML (no output)", {
	local_mocked_bindings(is_html = function() TRUE)
	expect_null(pptx_col_start(40))
	expect_null(pptx_col_break(60))
	expect_null(pptx_col_end())
})

# .compose_attr_with_bg -------------------------------------------------------

test_that(".compose_attr_with_bg() inserts bg into empty attribute", {
	out <- .compose_attr_with_bg("", "path/bg.png")
	expect_equal(out, "background-image='path/bg.png'")
})

test_that(".compose_attr_with_bg() appends bg to existing attributes", {
	out <- .compose_attr_with_bg("size=large", "img/bg.png")
	expect_equal(out, "size=large background-image='img/bg.png'")
})

test_that(".compose_attr_with_bg() overwrites existing background-image", {
	out <- .compose_attr_with_bg("background-image='old.png' size=large", "new.png", overwrite = TRUE)
	expect_match(out, "background-image='new.png'")
})

test_that(".compose_attr_with_bg() preserves existing bg when overwrite=FALSE", {
	out <- .compose_attr_with_bg("background-image='old.png'", "new.png", overwrite = FALSE)
	expect_equal(out, "background-image='old.png'")
})

# pptx_section_slide ----------------------------------------------------------

test_that("pptx_section_slide() selects correct background file and emits PPTX header", {
	dir <- withr::local_tempdir()
	file.create(file.path(dir, "blue.png"))

	local_mocked_bindings(.pandoc_to = function(fmt) fmt == "pptx", is_html = function() FALSE)

	out <- pptx_section_slide(level = 1, title = "Intro", bg = "blue", bg_dir = dir)

	# asis_output() prints its content when coerced to character
	out_chr <- as.character(out)
	expect_match(out_chr, "^# Intro \\{background-image='")
	expect_match(out_chr, "blue\\.png'\\}$")
})

test_that("pptx_section_slide() errors when no match", {
	dir <- withr::local_tempdir()
	file.create(file.path(dir, "red.png"))

	local_mocked_bindings(.pandoc_to = function(fmt) fmt == "pptx", is_html = function() FALSE)

	expect_error(pptx_section_slide(1, "Title", bg = "blue", bg_dir = dir), "No matching background")
})

test_that("pptx_section_slide() emits plain header for HTML when include_html=TRUE", {
	local_mocked_bindings(.pandoc_to = function(fmt) FALSE, is_html = function() TRUE)
	out <- pptx_section_slide(level = 2, title = "HTML Header", bg_dir = tempdir())
	expect_match(as.character(out), "^## HTML Header$")
})

test_that("pptx_section_slide() emits nothing for HTML when include_html=FALSE", {
	local_mocked_bindings(.pandoc_to = function(fmt) FALSE, is_html = function() TRUE)
	expect_invisible(pptx_section_slide(1, "Hidden", include_html = FALSE, bg_dir = tempdir()))
})

# add_pptx_backgrounds_to_headers --------------------------------------------

test_that("add_pptx_backgrounds_to_headers() applies backgrounds to selected levels", {
	dir <- withr::local_tempdir()
	file.create(file.path(dir, "blue.png"))

	txt <- "# Title\nParagraph\n## Subtitle\nMore text"
	out <- add_pptx_backgrounds_to_headers(text = txt, levels = c(1), bg = "blue", bg_dir = dir)

	# Only level-1 should be updated
	lines <- strsplit(out, "\n")[[1]]
	expect_match(lines[1], "^# Title \\{background-image=")
	expect_false(grepl("\\{background-image=", lines[3]))
})

test_that("add_pptx_backgrounds_to_headers() preserves YAML", {
	dir <- withr::local_tempdir()
	file.create(file.path(dir, "blue.png"))

	txt <- "---\ntitle: Test\n---\n# Title"
	out <- add_pptx_backgrounds_to_headers(text = txt, levels = 1, bg = "blue", bg_dir = dir)

	yaml <- strsplit(out, "\n")[[1]][1:3]
	expect_false(any(grepl("background-image", yaml)))
})

test_that("add_pptx_backgrounds_to_headers() errors when bg name not found", {
	dir <- withr::local_tempdir()
	file.create(file.path(dir, "red.png"))

	txt <- "# Title"
	expect_error(
		add_pptx_backgrounds_to_headers(text = txt, levels = 1, bg = "blue", bg_dir = dir),
		"No matching background"
	)
})

# pptx ----

## helpers ----
skip_if_pandoc_too_old <- function() {
  testthat::skip_if_not(pandoc::pandoc_available())
  testthat::skip_if(pandoc::pandoc_version() < numeric_version("3.8.3"),
                    message = "Pandoc < 3.8.3 does not support reliable PPTX conversion")
}

# Create a PPTX from Markdown using pandoc (returns path to created PPTX)
make_pptx_from_md <- function(md_text, target_pptx) {
  md_file <- tempfile(fileext = ".md")
  writeLines(md_text, md_file)
  pandoc::pandoc_run(paste0(shQuote(md_file), " -f markdown -t pptx -o ", shQuote(target_pptx)))
  target_pptx
}

test_that("convert creates a markdown file from pptx", {
  skip_if_pandoc_too_old()

  tmp <- withr::local_tempdir()

  input  <- file.path(tmp, "simple.pptx")
  output <- file.path(tmp, "simple_from_pptx.md")

  make_pptx_from_md("Hello **slides**", input)

  res <- convert(
    input_file     = input,
    markdown_file  = output,
    media_base_dir = NULL,
    pandoc_version = "default"
  )

  expect_true(file.exists(output))
  expect_null(res$media_dir)
  expect_equal(res$markdown_file, output)
})

test_that("media extraction works with a PPTX containing embedded images", {
  skip_if(pandoc::pandoc_version() < numeric_version("3.8.3"),
          "Pandoc < 3.8.3 does not fully support PPTX media extraction")

  tmp <- withr::local_tempdir()

  input      <- file.path(tmp, "with_media.pptx")
  output     <- file.path(tmp, "with_media_from_pptx.md")
  media_base <- tmp

  img <- file.path(tmp, "image.png")
  png(img, width = 200, height = 200)
  plot(1, main = "Test image")
  dev.off()

  md <- file.path(tmp, "slide.md")
  writeLines(c(
    "# Slide with image",
    "",
    "Here is an embedded image:",
    "",
    "![alt text](image.png)"
  ), md)

  withr::with_dir(tmp, {
    pandoc::pandoc_run(c("slide.md", "-f", "markdown", "-t", "pptx", "-o", "with_media.pptx"))
  })

  res <- convert(
    input_file     = input,
    markdown_file  = output,
    media_base_dir = media_base,
    pandoc_version = "default"
  )

  expect_true(file.exists(output))
  expect_false(is.null(res$media_dir))
  expect_true(dir.exists(res$media_dir))
  extracted <- list.files(res$media_dir, recursive = TRUE)
  expect_true(length(extracted) >= 1)
  expect_equal(res$markdown_file, output)
})
