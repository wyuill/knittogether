test_that("R >= 4.4.0 is declared, so %||% comes from base R", {
	depends <- utils::packageDescription("knittogether", fields = "Depends")
	expect_match(depends, "R \\(>= 4\\.4\\.0\\)", perl = TRUE)
	expect_true(exists("%||%", envir = baseenv()))
})

test_that("tools is declared in Imports", {
	imports <- utils::packageDescription("knittogether", fields = "Imports")
	expect_match(imports, "\\btools\\b", perl = TRUE)
})

test_that(".code_or_yaml_lines marks fences, their contents and front matter", {
	lines <- c("---", "a: 1", "---", "text", "````", "```", "inner", "````", "after")
	expect_identical(
		.code_or_yaml_lines(lines),
		c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, FALSE)
	)
	expect_identical(.code_or_yaml_lines(character()), logical())
})

test_that(".is_heading_line needs a space after the hashes", {
	expect_identical(
		.is_heading_line(c("# A", "#| opt", "#tag", "####### seven", "##")),
		c(TRUE, FALSE, FALSE, FALSE, TRUE)
	)
})

test_that("is_pdf() detects latex and beamer output", {
	old <- knitr::opts_knit$get("rmarkdown.pandoc.to")
	on.exit(knitr::opts_knit$set(rmarkdown.pandoc.to = old), add = TRUE)
	knitr::opts_knit$set(rmarkdown.pandoc.to = "latex")
	expect_true(is_pdf())
	knitr::opts_knit$set(rmarkdown.pandoc.to = "beamer")
	expect_true(is_pdf())
	knitr::opts_knit$set(rmarkdown.pandoc.to = "html")
	expect_false(is_pdf())
})

test_that("hide_markers_css() targets the data-custom-style attribute Pandoc writes", {
	css <- hide_markers_css()
	expect_match(css, 'span[data-custom-style="PlaceholderMarker"]', fixed = TRUE)
	expect_no_match(css, 'span[custom-style=', fixed = TRUE)
})
