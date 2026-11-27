# Helpers
test_that(".extract_placeholder extracts correctly", {
	# simple
	expect_equal(.extract_placeholder("This has placeholder_content_abc123 inside"), "placeholder_content_abc123")

	# multiple placeholders → extract first
	expect_equal(.extract_placeholder("x placeholder_content_a y placeholder_content_b"), "placeholder_content_a")

	# no placeholder → NA
	expect_true(is.na(.extract_placeholder("no token here")))

	# punctuation adjacent
	expect_equal(.extract_placeholder("prefix (placeholder_content_test)."), "placeholder_content_test")

	# underscores and digits
	expect_equal(.extract_placeholder("placeholder_content_x_y_123_z"), "placeholder_content_x_y_123_z")
})

test_that(".extract_placeholder supports custom prefix", {
	expect_equal(
		.extract_placeholder("This has placeholder_plot inside", placeholder_prefix = "placeholder"),
		"placeholder_plot"
	)
	expect_equal(
		.extract_placeholder("This has placeholder_content_plot inside", placeholder_prefix = "placeholder"),
		"placeholder_content_plot"
	)
})

# Clean

test_that("clean errors if file does not exist", {
	expect_error(clean_markdown("no_such_file.md"))
})

test_that("clean returns invisible cleaned text", {
	tmp <- withr::local_tempfile(fileext = ".md")
	writeLines("Hello", tmp)

	res <- expect_invisible(clean_markdown(tmp))
	expect_type(res, "character")
})

# Citations ----
test_that("clean_citations removes escaped citations", {
	tmp <- withr::local_tempfile(fileext = ".md")
	writeLines(c("Solo: \\[@ref1\\]", "In text: more\\[@ref1\\] text"), tmp)

	out <- clean_markdown(tmp, clean_citations = TRUE)
	expect_equal(out[1], "Solo: [@ref1]")
	expect_equal(out[2], "In text: more[@ref1] text")
})

test_that("clean_citations leaves text unchanged when disabled", {
	tmp <- withr::local_tempfile(fileext = ".md")
	original <- "\\\\[@abc]"
	writeLines(original, tmp)

	out <- clean_markdown(tmp, clean_citations = FALSE)
	expect_equal(out, original)
})

#  pptx_section_offset ----
test_that("pptx_section_offset bumps headings for normal slides", {
	# A slide heading followed by content → becomes ## heading
	tmp <- withr::local_tempfile(fileext = ".md")

	writeLines(c("# Slide Title", "", "Some body text"), tmp)

	out <- clean_markdown(tmp, pptx_section_offset = TRUE)
	expect_equal(out[1], "## Slide Title")
})

test_that("pptx_section_offset leaves section-only slides untouched", {
	# Title only → intended to remain level 1
	tmp <- withr::local_tempfile(fileext = ".md")

	writeLines(c("# Section Title", "", ""), tmp)

	out <- clean_markdown(tmp, pptx_section_offset = TRUE)
	expect_equal(out[1], "# Section Title")
})

test_that("`heading_offset = sections` can be disabled", {
	tmp <- withr::local_tempfile(fileext = ".md")
	writeLines(c("# Title", "Text"), tmp)

	out <- clean_markdown(tmp, pptx_section_offset = FALSE)
	expect_equal(out[1], "# Title")
})

# heading_offset ----
test_that("`heading_offset = all` increments headings by one", {
	tmp <- withr::local_tempfile(fileext = ".md")

	writeLines(c("# H1", "## H2", "No heading", "###### H6"), tmp)

	out <- clean_markdown(tmp, heading_offset = TRUE)

	expect_equal(out[1], "## H1") # 1 → 2
	expect_equal(out[2], "### H2") # 2 → 3
	expect_equal(out[3], "No heading") # unchanged
	expect_equal(out[4], "###### H6") # capped at level 6
})

test_that("heading_offset can be disabled", {
	tmp <- withr::local_tempfile(fileext = ".md")
	writeLines("# Title", tmp)

	out <- clean_markdown(tmp, heading_offset = FALSE)
	expect_equal(out[1], "# Title")
})

test_that("clear_draft keeps non-draft content unchanged", {
	tmp <- tempfile(fileext = ".md")

	writeLines(
		c("Line 1", "DRAFT_CONTENT_START", "placeholder_content_x", "Generated stuff", "DRAFT_CONTENT_END", "Line 2"),
		tmp
	)

	clean_markdown(tmp, clear_draft = TRUE)

	result <- readLines(tmp)

	expect_equal(result, c("Line 1", "placeholder_content_x", "Line 2"))
})

test_that("clear_draft works with custom draft markers", {
	tmp <- tempfile(fileext = ".md")

	writeLines(c("AAA", "<<<START>>>", "placeholder_content_custom", "Extra content", "<<<END>>>", "BBB"), tmp)

	clean_markdown(tmp, clear_draft = TRUE, draft_mode_prefix = "<<<START>>>", draft_mode_suffix = "<<<END>>>")

	result <- readLines(tmp)

	expect_equal(result, c("AAA", "placeholder_content_custom", "BBB"))
})

test_that("clear_draft handles multiple draft blocks independently", {
	tmp <- tempfile(fileext = ".md")

	writeLines(
		c(
			"Top",
			"DRAFT_CONTENT_START",
			"placeholder_content_a",
			"A1",
			"DRAFT_CONTENT_END",
			"Middle",
			"DRAFT_CONTENT_START",
			"placeholder_content_b",
			"B1",
			"DRAFT_CONTENT_END",
			"Bottom"
		),
		tmp
	)

	clean_markdown(tmp, clear_draft = TRUE)

	result <- readLines(tmp)

	expect_equal(result, c("Top", "placeholder_content_a", "Middle", "placeholder_content_b", "Bottom"))
})

test_that("clear_draft does nothing if no draft markers are present", {
	tmp <- tempfile(fileext = ".md")

	original <- c("Just text", "placeholder_content_total", "Still text")

	writeLines(original, tmp)

	clean_markdown(tmp, clear_draft = TRUE)

	result <- readLines(tmp)

	expect_equal(result, original)
})

# clear_draft
test_that("clear_draft removes content but keeps placeholder (default markers, own lines)", {
	tmp <- tempfile(fileext = ".md")

	writeLines(
		c("Before text", "DRAFT_CONTENT_START", "placeholder_content_total", "42", "DRAFT_CONTENT_END", "After text"),
		tmp
	)

	clean_markdown(tmp, clear_draft = TRUE)

	result <- readLines(tmp)

	expect_equal(result, c("Before text", "placeholder_content_total", "After text"))
})

test_that("clear_draft handles inline prefix/suffix with punctuation and preserves surrounding text", {
	tmp <- tempfile(fileext = ".md")

	writeLines(
		c(
			"Some more text with scalar added DRAFT_CONTENT_START",
			"placeholder_content_total",
			"42",
			"DRAFT_CONTENT_END. And another inline but this time as an expression DRAFT_CONTENT_START",
			"placeholder_content_dfmax",
			"`r { max(df$c1) }`",
			"DRAFT_CONTENT_END.",
			"Tail"
		),
		tmp
	)

	clean_markdown(tmp, clear_draft = TRUE)

	result <- readLines(tmp)

	expect_equal(
		result,
		c(
			"Some more text with scalar added placeholder_content_total. And another inline but this time as an expression placeholder_content_dfmax.",
			"Tail"
		)
	)
})

test_that("clear_draft works with custom draft markers (inline-safe)", {
	tmp <- tempfile(fileext = ".md")

	writeLines(c("AAA <<<START>>>", "placeholder_content_custom", "Extra content", "<<<END>>> BBB"), tmp)

	clean_markdown(tmp, clear_draft = TRUE, draft_mode_prefix = "<<<START>>>", draft_mode_suffix = "<<<END>>>")

	result <- readLines(tmp)

	# Placeholder retained, prefix before and suffix after text preserved
	expect_equal(result, "AAA placeholder_content_custom BBB")
})

test_that("clear_draft supports custom placeholder_prefix", {
	tmp <- tempfile(fileext = ".md")

	writeLines(
		c("Top", "DRAFT_CONTENT_START", "placeholder_plot", "99", "DRAFT_CONTENT_END", "Bottom"),
		tmp
	)

	clean_markdown(tmp, clear_draft = TRUE, placeholder_prefix = "placeholder")

	result <- readLines(tmp)

	expect_equal(result, c("Top", "placeholder_plot", "Bottom"))
})

test_that("clear_draft removes chunk bodies and keeps only the placeholder", {
	tmp <- tempfile(fileext = ".md")

	writeLines(
		c(
			"Intro",
			"DRAFT_CONTENT_START",
			"placeholder_content_mtcarsplot",
			"```{r mtcarsplot, echo=FALSE, warning=FALSE, message=FALSE, fig.width=7}",
			"{",
			"  plot(mtcars$wt, mtcars$mpg)",
			"}",
			"```",
			"DRAFT_CONTENT_END",
			"Outro"
		),
		tmp
	)

	clean_markdown(tmp, clear_draft = TRUE)

	result <- readLines(tmp)

	expect_equal(result, c("Intro", "placeholder_content_mtcarsplot", "Outro"))
})

test_that("placeholder_markers removes brackets and custom-style blocks", {
	# Sample markdown including multiple markers
	input <- c(
		"Some text [placeholder_content_a]{custom-style=\"PlaceholderMarker\"} more text",
		"Two markers: [placeholder_content_1]{custom-style=\"One\"} and [placeholder_content_2]{custom-style=\"Two\"}.",
		"Unaffected line without markers."
	)

	# Expected output
	expected <- c(
		"Some text placeholder_content_a more text",
		"Two markers: placeholder_content_1 and placeholder_content_2.",
		"Unaffected line without markers."
	)

	# Write temporary file
	tf <- tempfile(fileext = ".md")
	writeLines(input, tf)

	# Run cleaner
	clean_markdown(markdown_file = tf, clear_placeholder_styling = TRUE)

	# Read back output
	result <- readLines(tf, warn = FALSE)

	expect_identical(result, expected)
})

test_that("placeholder_markers supports custom placeholder_prefix", {
	input <- c(
		"Some text [placeholder_plot]{custom-style=\"PlaceholderMarker\"} more text",
		"Another marker: [placeholder_table_1]{custom-style=\"Two\"}."
	)

	expected <- c(
		"Some text placeholder_plot more text",
		"Another marker: placeholder_table_1."
	)

	tf <- tempfile(fileext = ".md")
	writeLines(input, tf)

	clean_markdown(markdown_file = tf, clear_placeholder_styling = TRUE, placeholder_prefix = "placeholder")

	result <- readLines(tf, warn = FALSE)

	expect_identical(result, expected)
})

test_that("clear_placeholder_styling leaves whitespace alone", {
	input <- c(
		"- item",
		"    - nested item",
		"Line with a hard break  ",
		"```{r}",
		"x  <-   1",
		"```",
		"+-----+-----+",
		"| a   | b   |",
		"+-----+-----+",
		"Text [placeholder_content_a]{custom-style=\"PlaceholderMarker\"} more"
	)
	tf <- tempfile(fileext = ".md")
	writeLines(input, tf)

	result <- clean_markdown(tf, clear_placeholder_styling = TRUE)

	expect_identical(result[1:9], input[1:9])
	expect_identical(result[10], "Text placeholder_content_a more")
})

test_that("clear_placeholder_styling keeps custom styles that are not on placeholders", {
	input <- c(
		"[Note to readers]{custom-style=\"Callout\"}",
		"See [placeholder_content_a]{custom-style=\"PlaceholderMarker\"} and [Key point]{custom-style=\"Emphasis\"}."
	)
	tf <- tempfile(fileext = ".md")
	writeLines(input, tf)

	result <- clean_markdown(tf, clear_placeholder_styling = TRUE)

	expect_identical(result[1], input[1])
	expect_identical(result[2], "See placeholder_content_a and [Key point]{custom-style=\"Emphasis\"}.")
})

test_that("clear_placeholder_styling does not unwrap a link whose text is a placeholder", {
	input <- "[placeholder_content_a](https://example.com)"
	tf <- tempfile(fileext = ".md")
	writeLines(input, tf)

	expect_identical(clean_markdown(tf, clear_placeholder_styling = TRUE), input)
})

# Combined behaviour ----
test_that("all cleaning steps interact predictably including clear_draft and placeholder_markers", {
	tmp <- tempfile(fileext = ".md")

	writeLines(
		c(
			"# Section title",
			"",
			"",
			"# A normal heading",
			"Some text\\[@cite\\].",
			"",
			"Inline example DRAFT_CONTENT_START",
			"[placeholder_content_value]{custom-style=\"PlaceholderMarker\"}",
			"99",
			"DRAFT_CONTENT_END and more text."
		),
		tmp
	)

	out <- clean_markdown(
		tmp,
		clean_citations = TRUE,
		heading_offset = TRUE,
		pptx_section_offset = TRUE,
		clear_draft = TRUE,
		clear_placeholder_styling = TRUE # NEW OPTION
	)

	# Headings:
	expect_equal(out[1], "## Section title") # heading_offset
	expect_equal(out[2], "") # preserved
	expect_equal(out[3], "") # preserved
	expect_equal(out[4], "### A normal heading") # pptx offset + global offset

	# Citation cleaned:
	expect_equal(out[5], "Some text[@cite].")

	# Draft block collapsed, placeholder extracted AND marker formatting stripped
	expect_equal(out[7], "Inline example placeholder_content_value and more text.")
})

# Headings inside code ----
test_that("heading_offset does not touch chunk options, code comments or YAML", {
	input <- c(
		"---",
		"# yaml comment",
		"title: x",
		"---",
		"# Heading",
		"#Not a heading",
		"```{r}",
		"#| echo: false",
		"# an R comment",
		"```",
		"~~~",
		"## also code",
		"~~~",
		"###### Six"
	)
	tf <- tempfile(fileext = ".md")
	writeLines(input, tf)

	out <- clean_markdown(tf, heading_offset = TRUE)

	expected <- input
	expected[5] <- "## Heading"
	expect_identical(out, expected)
})

test_that("pptx_section_offset ignores # lines inside code", {
	input <- c(
		"# Slide",
		"Body text",
		"```{r}",
		"# comment",
		"x <- 1",
		"```"
	)
	tf <- tempfile(fileext = ".md")
	writeLines(input, tf)

	out <- clean_markdown(tf, pptx_section_offset = TRUE)

	expect_identical(out[1], "## Slide")
	expect_identical(out[4], "# comment")
})

# Word formatting on placeholders (PHDAT-1198) ----
test_that("clean() removes superscript and subscript formatting tight around a placeholder", {
	tf <- tempfile(fileext = ".md")
	writeLines(c("^placeholder_content_plot^", "H~placeholder_content_sub~O"), tf)
	out <- clean_markdown(tf, clear_placeholder_styling = TRUE)
	expect_identical(out, c("placeholder_content_plot", "Hplaceholder_content_subO"))
})

test_that("clean() removes bold and italic formatting wrapped round a styled placeholder", {
	tf <- tempfile(fileext = ".md")
	writeLines(c(
		'**[placeholder_content_plot]{custom-style="PlaceholderMarker"}**',
		'*[placeholder_content_tab]{custom-style="PlaceholderMarker"}*'
	), tf)
	out <- clean_markdown(tf, clear_placeholder_styling = TRUE)
	expect_identical(out, c("placeholder_content_plot", "placeholder_content_tab"))
})

test_that("clean() leaves formatting that is not tight against a placeholder", {
	tf <- tempfile(fileext = ".md")
	writeLines(c("Some ^superscript^ text and **bold** words", "x^2^ then placeholder_content_a"), tf)
	out <- clean_markdown(tf, clear_placeholder_styling = TRUE)
	expect_identical(out, c("Some ^superscript^ text and **bold** words", "x^2^ then placeholder_content_a"))
})

test_that("formatting removal only applies when clear_placeholder_styling is TRUE", {
	tf <- tempfile(fileext = ".md")
	writeLines("^placeholder_content_plot^", tf)
	out <- clean_markdown(tf, clear_placeholder_styling = FALSE)
	expect_identical(out, "^placeholder_content_plot^")
})
