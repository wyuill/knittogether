# Tests for helpers
test_that(".deparse1 collapses expressions into a single string", {
	expr <- quote({
		x <- 1
		y <- 2
		x + y
	})

	out <- .deparse1(expr)

	expect_type(out, "character")
	expect_length(out, 1L)
	expect_true(grepl("x <- 1", out))
	expect_true(grepl("x \\+ y", out))
})

test_that(".format_inline_expr produces a compact inline `r` expression", {
	expr <- quote({
		x <- 1
		x + 2
	})

	out <- .format_inline_expr(expr)

	expect_match(out, "^`r .+`$")
	expect_false(grepl("\n", out))
	expect_true(grepl("x <- 1", out))
})

test_that(".stringify_chunk_value formats values correctly", {
	expect_equal(.stringify_chunk_value(TRUE), "TRUE")
	expect_equal(.stringify_chunk_value(FALSE), "FALSE")
	expect_equal(.stringify_chunk_value(3.14), "3.14")
	expect_equal(.stringify_chunk_value("abc"), '"abc"')
})

test_that(".combine_chunk_options produces a proper option string", {
	opts <- list(echo = FALSE, fig.width = 7, engine = "r")

	out <- .combine_chunk_options(opts)

	# engine is intentionally ignored in .format_chunk_expr, so it's OK here
	expect_true(grepl("echo=FALSE", out))
	expect_true(grepl("fig.width=7", out))
})

test_that(".format_chunk_expr creates a valid fenced chunk", {
	expr <- quote(plot(1:10))

	out <- .format_chunk_expr(expr, slug = "testslug", chunk_options = list(echo = FALSE, fig.width = 5))

	expect_true(startsWith(out, "```{r testslug"))
	expect_true(grepl("echo=FALSE", out))
	expect_true(grepl("fig.width=5", out))
	expect_true(grepl("plot", out))
	expect_true(endsWith(out, "```"))
})

test_that(".build_marker returns empty string when off", {
	out <- .build_marker(
		token = "placeholder_x",
		marker_mode = "off",
		style_hidden = "PlaceholderMarker",
		style_visible = "PlaceholderMarkerVisible"
	)

	expect_identical(out, "")
})

test_that(".build_marker creates hidden and visible markers", {
	hidden <- .build_marker(
		token = "placeholder_x",
		marker_mode = "hidden",
		style_hidden = "HiddenStyle",
		style_visible = "VisibleStyle"
	)
	visible <- .build_marker(
		token = "placeholder_x",
		marker_mode = "show",
		style_hidden = "HiddenStyle",
		style_visible = "VisibleStyle"
	)

	expect_identical(hidden, '[placeholder_x]{custom-style="HiddenStyle"}')
	expect_identical(visible, '[placeholder_x]{custom-style="VisibleStyle"}')
})

test_that(".append_marker behaves correctly for inline and block modes", {
	inline <- .append_marker(
		body = "value",
		token = "placeholder_x",
		output_mode = "inline",
		marker_mode = "hidden",
		style_hidden = "HiddenStyle",
		style_visible = "VisibleStyle"
	)

	block <- .append_marker(
		body = "value",
		token = "placeholder_x",
		output_mode = "chunk",
		marker_mode = "hidden",
		style_hidden = "HiddenStyle",
		style_visible = "VisibleStyle"
	)

	expect_equal(inline, 'value [placeholder_x]{custom-style="HiddenStyle"}')

	expect_equal(block, "value\n[placeholder_x]{custom-style=\"HiddenStyle\"}")
})

test_that(".append_marker returns body unchanged when off", {
	out <- .append_marker(
		body = "value",
		token = "placeholder_x",
		output_mode = "inline",
		marker_mode = "off",
		style_hidden = "HiddenStyle",
		style_visible = "VisibleStyle"
	)

	expect_identical(out, "value")
})

test_that(".write_child_qmd writes a valid child qmd and returns relative path", {
	tmpdir <- tempdir()
	mdfile <- file.path(tmpdir, "parent.md")
	writeLines("dummy", mdfile)

	expr <- quote(plot(1:5))

	result <- .write_child_qmd(
		parent_md_path = mdfile,
		slug = "plot1",
		expr = expr,
		chunk_options = list(echo = FALSE),
		child_dir = NULL,
		overwrite = TRUE
	)

	# Returned filename is correct
	expect_identical(result, "child_plot1.qmd")

	child_path <- file.path(tmpdir, result)

	expect_true(file.exists(child_path))

	# Contents look like a chunk
	child <- readLines(child_path)
	expect_true(any(grepl("^```\\{r plot1", child)))
	expect_true(any(grepl("plot", child)))
	expect_true(any(grepl("```$", child)))
})

# Tests for define_content()
test_that("define_content creates a valid content_spec with correct fields", {
	spec <- define_content(
		description = "Test plot",
		placeholder_id = "plot1",
		output_mode = "chunk",
		content = {
			plot(1:10)
		},
		content_type = "plot",
		chunk_options = list(echo = FALSE, fig.width = 6)
	)

	expect_s3_class(spec, "content_spec")
	expect_equal(spec$description, "Test plot")
	expect_equal(spec$placeholder_id, "plot1")
	expect_equal(spec$output_mode, "chunk")
	expect_equal(spec$content_type, "plot")

	# content_expr must be an unevaluated expression
	expect_true(is.language(spec$content_expr))

	expect_equal(spec$chunk_options, list(echo = FALSE, fig.width = 6))
})

test_that("define_content rejects invalid output_mode", {
	expect_error(define_content("desc", "id", "WRONG", content = 1, content_type = "txt"))
})

test_that("define_content stores string literal correctly in asis mode", {
	spec <- define_content(
		description = "literal",
		placeholder_id = "include_qmd",
		output_mode = "asis",
		content = "{{< include file.qmd >}}",
		content_type = "qmd"
	)

	expect_equal(spec$output_mode, "asis")
	expect_false(is.language(spec$content_expr))
})

# ------------------------------------------------------------
# placeholder_map()
# ------------------------------------------------------------

test_that("placeholder_map builds correct slug → spec mapping", {
	spec1 <- define_content("A", "slug1", "inline", content = 1, content_type = "txt")
	spec2 <- define_content("B", "slug2", "asis", content = "abc", content_type = "txt")

	map <- placeholder_map(specs = list(spec1, spec2))

	expect_equal(names(map), c("slug1", "slug2"))
	expect_s3_class(map$slug1, "content_spec")
	expect_s3_class(map$slug2, "content_spec")
})

test_that("placeholder_map includes scalars and spec slugs without collision", {
	spec <- define_content("A", "slug1", "inline", content = 1, content_type = "txt")

	map <- placeholder_map(specs = list(spec), scalars = list(total = 42))

	expect_equal(names(map), c("slug1", "total"))
	expect_equal(map$total, 42)
})

test_that("placeholder_map errors when specs contain duplicates or scalar collisions", {
	s1 <- define_content("one", "dup", "inline", content = 1, content_type = "txt")
	s2 <- define_content("two", "dup", "chunk", content = 2, content_type = "txt")

	# Duplicate slug IDs in specs
	expect_error(placeholder_map(specs = list(s1, s2)))

	# Collision between scalar and spec slug
	expect_error(placeholder_map(specs = list(s1), scalars = list(dup = 99)))
})

test_that("placeholder_map errors when scalars are unnamed", {
	expect_error(placeholder_map(scalars = list(1, 2)))
})

# ------------------------------------------------------------
# replace_placeholders(): minimal integration behaviour with define_content + placeholder_map
# ------------------------------------------------------------

test_that("replace_placeholders() inserts scalar and content_spec (inline, chunk, asis) correctly", {
	tmp <- tempfile(fileext = ".md")

	writeLines(
		c(
			"Value: placeholder_total",
			"Inline: placeholder_inline",
			"Chunk: placeholder_plot",
			"Asis: placeholder_raw"
		),
		tmp
	)

	# specs
	spec_inline <- define_content(
		"inline test",
		"inline",
		"inline",
		content = {
			mean(1:3)
		},
		content_type = "txt"
	)

	spec_chunk <- define_content(
		"chunk test",
		"plot",
		"chunk",
		content = {
			plot(1:3)
		},
		content_type = "plot",
		chunk_options = list(echo = FALSE)
	)

	spec_asis <- define_content("asis test", "raw", "asis", content = "{{< include file.qmd >}}", content_type = "qmd")

	# build code map
	map <- placeholder_map(specs = list(spec_inline, spec_chunk, spec_asis), scalars = list(total = 42))

	out <- replace_placeholders(tmp, code_content = map, draft_mode = FALSE)

	# scalar
	expect_true(any(grepl("42", out)))

	# inline R: must contain inline `r expression`
	expect_true(any(grepl("`r \\{ mean", out)))

	# chunk header (R by default)
	expect_true(any(grepl("```\\{r plot", out)))

	# literal text from asis
	expect_true(any(grepl("include file.qmd", out)))
})

test_that("replace_placeholders() does not let one placeholder match inside a longer one", {
	tmp <- tempfile(fileext = ".md")

	for (draft in c(FALSE, TRUE)) {
		writeLines(c("A: placeholder_plot", "B: placeholder_plot_2"), tmp)
		out <- replace_placeholders(tmp, code_content = list(plot = "ONE", plot_2 = "TWO"), draft_mode = draft)
		txt <- paste(out, collapse = "\n")

		expect_equal(lengths(regmatches(txt, gregexpr("ONE", txt))), 1L)
		expect_equal(lengths(regmatches(txt, gregexpr("TWO", txt))), 1L)
		expect_match(txt, "[placeholder_plot]{custom-style=\"PlaceholderMarker\"}", fixed = TRUE)
		expect_match(txt, "[placeholder_plot_2]{custom-style=\"PlaceholderMarker\"}", fixed = TRUE)
		expect_no_match(txt, "}_2", fixed = TRUE)
	}
})

test_that("replace_placeholders() result does not depend on the order of code_content", {
	tmp <- tempfile(fileext = ".md")
	lines <- c("placeholder_a placeholder_a_b placeholder_a_b_c")

	writeLines(lines, tmp)
	out1 <- replace_placeholders(tmp, code_content = list(a = "1", a_b = "2", a_b_c = "3"), draft_mode = FALSE, marker_mode = "off")
	writeLines(lines, tmp)
	out2 <- replace_placeholders(tmp, code_content = list(a_b_c = "3", a = "1", a_b = "2"), draft_mode = FALSE, marker_mode = "off")

	expect_identical(out1, "1 2 3")
	expect_identical(out2, "1 2 3")
})

test_that("replace_placeholders() ignores tokens embedded in longer identifiers", {
	tmp <- tempfile(fileext = ".md")
	writeLines("my_placeholder_x and placeholder_x", tmp)
	out <- replace_placeholders(tmp, code_content = list(x = "X"), draft_mode = FALSE, marker_mode = "off")
	expect_identical(out, "my_placeholder_x and X")
})

test_that("replace_placeholders() inserts backslashes in content literally", {
	tmp <- tempfile(fileext = ".md")
	writeLines("placeholder_path", tmp)
	out <- replace_placeholders(tmp, code_content = list(path = "C:\\data\\1"), draft_mode = FALSE, marker_mode = "off")
	expect_identical(out, "C:\\data\\1")
})

test_that("a chunk used more than once gets a distinct label for each copy", {
	tmp <- tempfile(fileext = ".md")
	writeLines(c("first placeholder_plot", "second placeholder_plot"), tmp)
	spec <- define_content("plot", "plot", "chunk", content = { plot(1:3) }, content_type = "plot")

	out <- replace_placeholders(tmp, code_content = list(plot = spec), draft_mode = FALSE, marker_mode = "off")
	txt <- paste(out, collapse = "\n")

	expect_match(txt, "```{r plot}", fixed = TRUE)
	expect_match(txt, "```{r plot_2}", fixed = TRUE)
	labels <- regmatches(txt, gregexpr("```\\{r [A-Za-z0-9_]+", txt))[[1]]
	expect_false(anyDuplicated(labels) > 0)
})

test_that("a chunk used once keeps its plain label", {
	tmp <- tempfile(fileext = ".md")
	writeLines("only placeholder_plot", tmp)
	spec <- define_content("plot", "plot", "chunk", content = { plot(1:3) }, content_type = "plot")

	out <- replace_placeholders(tmp, code_content = list(plot = spec), draft_mode = FALSE, marker_mode = "off")
	expect_true(any(grepl("```{r plot}", out, fixed = TRUE)))
	expect_false(any(grepl("plot_2", out, fixed = TRUE)))
})

test_that("as_child, child_dir and engine are not written as chunk options", {
	opts <- list(engine = "r", echo = FALSE, as_child = TRUE, child_dir = "kids")
	header <- .chunk_header("slug1", opts)
	expect_identical(header, "{r slug1, echo=FALSE}")
	expect_false(grepl("as_child|child_dir|engine", header))

	inline <- .format_chunk_expr(quote(1 + 1), "slug1", opts)
	expect_true(startsWith(inline, "```{r slug1, echo=FALSE}"))
})

test_that("child qmd header matches the inline chunk header", {
	tmp_dir <- withr::local_tempdir()
	parent <- file.path(tmp_dir, "doc.md")
	writeLines("x", parent)
	opts <- list(echo = FALSE, as_child = TRUE, child_dir = NULL)
	.write_child_qmd(parent, "plot", quote(plot(1)), chunk_options = opts)
	child <- readLines(file.path(tmp_dir, "child_plot.qmd"))
	expect_identical(child[1], "```{r plot, echo=FALSE}")
})

# define_content() usability (NEW) ----
test_that("define_content() works without description or content_type", {
	spec <- define_content(placeholder_id = "p", output_mode = "inline", content = mean(1:3))
	expect_null(spec$description)
	expect_null(spec$content_type)
	expect_identical(spec$content_expr, quote(mean(1:3)))
})

test_that("define_content() captures content injected with !! (for use in functions and lapply)", {
	exprs <- list(quote(mean(1:3)), quote(sum(1:3)))
	specs <- lapply(seq_along(exprs), function(i) {
		define_content(placeholder_id = paste0("s", i), output_mode = "inline", content = !!exprs[[i]])
	})
	expect_identical(specs[[1]]$content_expr, quote(mean(1:3)))
	expect_identical(specs[[2]]$content_expr, quote(sum(1:3)))
})

test_that("a top-level { } block is unwrapped so each statement is its own line in a chunk", {
	spec <- define_content(
		placeholder_id = "two",
		output_mode = "chunk",
		content = {
			a <- 1
			a + 1
		}
	)
	chunk <- .format_chunk_expr(spec$content_expr, "two", list())
	lines <- strsplit(chunk, "\n", fixed = TRUE)[[1]]
	expect_identical(lines[1], "```{r two}")
	expect_identical(lines[2:3], c("a <- 1", "a + 1"))
	expect_identical(lines[4], "```")
})

test_that("expressions that are not a { } block are written unchanged in a chunk", {
	expect_identical(.chunk_body(quote(mean(1:3))), "mean(1:3)")
})
