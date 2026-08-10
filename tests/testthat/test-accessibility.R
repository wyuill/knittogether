testthat::test_that("Markdown image: descriptive alt passes; generic alt fails", {
	lines <- c(
		'![Figure 1 Age distribution](./media/img1.png){width="4in"}', # OK: good descriptive alt
		'![Figure 1](./media/img2.png){width="6.2in"', # FAIL: generic alt (with multi-line attributes)
		'height="3.9in"}',
		'![](./media/img3.png)' # FAIL: empty alt
	)
	df <- accessibility_scan(lines)

	testthat::expect_true(all(df$kind %in% c("image-md")))
	testthat::expect_equal(nrow(df), 2L)
	testthat::expect_true(all(df$issue == "missing-or-generic-alt"))
	testthat::expect_setequal(unique(df$line), c(2L, 4L))
})

test_that("HTML image: inside figure with figcaption is OK; otherwise needs descriptive alt", {
	html <- htmltools::HTML(
		'
  <img src="img1.jpg" style="width:100%">
  <img src="img2.jpg" alt = "Fig 1">
  <img src="img3.jpg" alt = "This is some good alt text">
  <figure><img src="img4.jpg"><figcaption>Fig.1 This is a good caption</figcaption></figure>
  <figure><img src="img5.jpg"><figcaption>Fig.1</figcaption></figure>
  <figure><img src="img6.jpg"></figure>'
	)

	df <- accessibility_scan(html)

	expect_true(all(df$kind == "image-html"))
	expect_true(any(grepl("img1.jpg", df$snippet)))
	expect_true(any(grepl("img2.jpg", df$snippet)))
	expect_true(any(grepl("img5.jpg", df$snippet)))
	expect_true(any(grepl("img6.jpg", df$snippet)))

	expect_false(any(grepl("img3.jpg", df$snippet)))
	expect_false(any(grepl("img4.jpg", df$snippet)))
})

testthat::test_that("Markdown table: missing or generic caption fails; descriptive caption passes", {
	lines <- c(
		# 1-3: table with descriptive caption OK
		'Table: Regression coefficients',
		'| Term | Est |',
		'|------|-----|',
		# 4–6: second table with generic caption (FAIL)
		'Table: Table 2',
		'| A | B |',
		'|---|---|',
		# 7: filler breaks the table block so the next table is a new block
		'Some filler text to separate tables',
		# 8–10: third table with NO caption (FAIL)
		'| X | Y |',
		'|---|---|',
		'| 1 | 2 |'
	)

	df <- accessibility_scan(lines)

	# Should flag the generic-caption table at line 5 and the no-caption table at line 7
	testthat::expect_true(all(df$kind == "table-md"))
	testthat::expect_equal(nrow(df), 2L)
	testthat::expect_true(all(df$issue == "missing-or-generic-caption"))
	testthat::expect_setequal(df$line, c(5L, 8L))
})

testthat::test_that("HTML table: caption/aria-label descriptive OK; generic/missing fails", {
	lines <- c(
		'<table><caption>Age by borough</caption><tr><td>...</td></tr></table>', # OK: descriptive <caption>
		'<table aria-label="Regression summary"><tr><td>...</td></tr></table>', # OK: aria-label descriptive
		'<table><caption>Table 1</caption><tr><td>...</td></tr></table>', # FAIL: generic caption
		'<table class="wide"><tr><td>...</td></tr></table>', # FAIL: missing caption and aria-label
		'<table aria-label="Fig. 3"><tr><td>...</td></tr></table>' # FAIL: aria-label present but generic
	)
	df <- accessibility_scan(lines)

	testthat::expect_true(all(df$kind == "table-html"))
	testthat::expect_equal(nrow(df), 3L)
	testthat::expect_true(all(df$issue == "missing-or-generic-caption"))
	testthat::expect_setequal(df$line, c(3L, 4L, 5L))
})

testthat::test_that("reactable: requires descriptive caption or aria-label", {
	lines <- c(
		'<div class="reactable"><caption>Ward metrics</caption><div>...</div></div>', # OK: descriptive caption
		'<div class="reactable" aria-label="KPIs by month"><div>...</div></div>', # OK: descriptive aria-label
		'<div class="reactable"><caption>Table 7</caption></div>', # FAIL: generic caption
		'<div class="reactable"><div>...</div></div>', # FAIL: missing caption/aria-label
		'<div class="reactable" aria-label="Figure 2"></div>' # FAIL: generic aria-label
	)

	df <- accessibility_scan(lines)

	testthat::expect_true(all(df$kind == "reactable"))
	testthat::expect_equal(nrow(df), 3L)
	testthat::expect_true(all(df$issue == "missing-or-generic-caption"))
	testthat::expect_setequal(df$line, c(3L, 4L, 5L))
})

testthat::test_that("NA safety: missing alt/caption values do not crash and are handled", {
	# Construct tags that *lack* the attribute being searched
	lines <- c(
		'<img src="x.png">', # no alt
		'<table><tr><td>no caption and no aria</td></tr></table>', # no caption or aria
		'<div class="reactable"></div>' # no caption or aria
	)
	# Should simply flag three issues without errors
	df <- accessibility_scan(lines)

	testthat::expect_equal(nrow(df), 3L)
	testthat::expect_true(all(df$issue %in% c("missing-or-generic-alt", "missing-or-generic-caption")))
})

testthat::test_that("No issues => empty data.frame with correct columns", {
	lines <- c(
		'![Alt is descriptive](./a.png){width="3in"}',
		'Table: Borough populations',
		'| Borough | Pop |',
		'|---------|-----|',
		'<table aria-label="Descriptive label"><tr><td>ok</td></tr></table>',
		'<figure><img src="x.png" alt=""><figcaption>Meaningful caption</figcaption></figure>'
	)
	df <- accessibility_scan(lines)

	testthat::expect_true(is.data.frame(df))
	testthat::expect_equal(nrow(df), 0L)
	testthat::expect_setequal(names(df), c("kind", "line", "src", "issue", "snippet"))
})

testthat::test_that("Line numbers roughly match positions for mixed content", {
	lines <- c(
		'Intro text',
		'![Figure 1](./bad.png){width="1in"}', # generic -> fail at line 2
		'Some text',
		'<img src="b.png" alt="Figure 2">', # generic -> fail at line 4
		'Table: Table 9', # generic -> table starts next line
		'| a | b |',
		'|---|---|',
		'End'
	)
	df <- accessibility_scan(lines)

	testthat::expect_true(all(df$issue %in% c("missing-or-generic-alt", "missing-or-generic-caption")))
	# We expect flags at lines 2 (md image), 4 (html image), and 6 (md table start)
	testthat::expect_setequal(df$line, c(2L, 4L, 6L))
})
