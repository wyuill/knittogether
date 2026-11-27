# Manual end-to-end test of the standard knittogether workflow (run from the package root).
#
#   source("scripts/test-new-process.R")
#
# It uses the example template shipped with the package (inst/extdata/PlaceholderMarker_example.docx). The template
# has four placeholders, all with the prefix "placeholder":
#   placeholder_visible    (styled, visible marker)
#   placeholder_invisible  (styled, hidden marker)
#   placeholder_nmtcars    (inline R value)
#   placeholder_mtcarsplot (R chunk)
# The steps follow the README:
#   writer's draft -> convert -> clean -> replace (draft) -> writer edits in Word -> re-import and refresh
#   -> final replace -> render.
# Each check prints PASS or FAIL. The working folder is kept so you can open the outputs; its path is printed
# at the start and end. Nothing outside that folder is changed.
#
# Requires: Pandoc (for convert and for the simulated Word round trip). Quarto is optional (last section).

devtools::load_all(quiet = TRUE)

results <- data.frame(check = character(), passed = logical(), stringsAsFactors = FALSE)
check <- function(name, passed) {
	results[nrow(results) + 1L, ] <<- list(name, isTRUE(passed))
	cat(if (isTRUE(passed)) "PASS  " else "FAIL  ", name, "\n", sep = "")
	invisible(passed)
}
section <- function(title) cat("\n== ", title, " ==\n", sep = "")
count_fixed <- function(x, pattern) sum(grepl(pattern, x, fixed = TRUE))

prefix <- "placeholder"
ids <- c("visible", "invisible", "nmtcars", "mtcarsplot")

# Working folder: kept after the run so the outputs can be inspected
# tempdir() is deleted when an Rscript run ends, so use the system temp folder, which keeps the outputs
base_tmp <- if (nzchar(Sys.getenv("TEMP"))) Sys.getenv("TEMP") else tempdir()
work <- file.path(base_tmp, "knittogether-process-test")
unlink(work, recursive = TRUE)
drafts <- file.path(work, "drafts")
dir.create(drafts, recursive = TRUE)
cat("Working folder: ", normalizePath(work), "\n", sep = "")

pandoc <- unname(Sys.which("pandoc"))
section("Environment")
check("pandoc is on PATH", nzchar(pandoc))
if (!nzchar(pandoc)) stop("Pandoc is needed for this test. Install it and run again.", call. = FALSE)
resolved <- .resolve_pandoc("default")
check("default pandoc meets 3.8.3 (directly or via bundled fallback)", resolved$ver >= .pandoc_min_version())
cat("       using ", as.character(resolved$ver), if (resolved$fallback) " (bundled fallback)" else "", "\n", sep = "")
template <- system.file("extdata", "PlaceholderMarker_example.docx", package = "knittogether")
check("example template is installed", nzchar(template))
if (!nzchar(template)) stop("The example template is missing from the package.", call. = FALSE)

# The R content for each placeholder
visible_spec <- define_content(
	description = "Number of rows in mtcars (visible marker)",
	placeholder_id = "visible",
	output_mode = "inline",
	content_type = "text",
	content = { nrow(mtcars) }
)
invisible_spec <- define_content(
	description = "A fixed string (hidden marker)",
	placeholder_id = "invisible",
	output_mode = "inline",
	content_type = "text",
	content = { "first value" }
)
nmtcars_spec <- define_content(
	description = "Number of rows in mtcars",
	placeholder_id = "nmtcars",
	output_mode = "inline",
	content_type = "text",
	content = { nrow(mtcars) }
)
mtcarsplot_spec <- define_content(
	description = "Plot of mtcars",
	placeholder_id = "mtcarsplot",
	output_mode = "chunk",
	content_type = "plot",
	content = { plot(mtcars$wt, mtcars$mpg) },
	chunk_options = list(echo = FALSE)
)
all_specs <- list(visible_spec, invisible_spec, nmtcars_spec, mtcarsplot_spec)
n_placeholders <- length(all_specs)

# 1. The writer's draft. Two copies of the template stand in for an earlier and a newer version of the report.
section("1. Writer's drafts (the example template)")
invisible(file.copy(template, file.path(drafts, "report_v1.docx")))
Sys.setFileTime(file.path(drafts, "report_v1.docx"), Sys.time() - 3600)
invisible(file.copy(template, file.path(drafts, "report_v2.docx")))
check("two Word drafts are in the drafts folder", all(file.exists(file.path(drafts, c("report_v1.docx", "report_v2.docx")))))

# 2. Choosing the file
section("2. Latest file selection")
latest <- latest_word_file(drafts, base_name = "report")
check("latest_word_file() picks the newest draft", basename(latest) == "report_v2.docx")
check("latest_word_file() ignores ~$ lock files", {
	writeLines("lock", file.path(drafts, "~$report_v2.docx"))
	basename(latest_word_file(drafts)) == "report_v2.docx"
})
check("latest_word_file() errors when nothing matches",
	inherits(tryCatch(latest_word_file(drafts, base_name = "nothing"), error = function(e) e), "error"))

# 3. Convert and clean (README steps 1 and 2)
section("3. Convert and clean")
md <- file.path(work, "work.md")
convert_markdown(latest, markdown_file = md, media_base_dir = NULL)
raw <- readLines(md, warn = FALSE)
check("convert_markdown() converts the latest Word file", file.exists(md))
check("converted markdown has all four placeholders",
	all(vapply(ids, function(id) count_fixed(raw, paste0(prefix, "_", id)) >= 1, logical(1))))

cleaned <- timestamped_path(file.path(work, "work.md"))
clean_markdown(md, clear_placeholder_styling = TRUE, placeholder_prefix = prefix, output_file = cleaned)
cleaned_text <- readLines(cleaned, warn = FALSE)
check("clean_markdown(output_file=) writes the cleaned file", file.exists(cleaned))
check("clean_markdown(output_file=) leaves the input unchanged", identical(readLines(md, warn = FALSE), raw))
check("cleaned styled placeholders are bare tokens (styling and brackets removed)",
	any(cleaned_text == paste0(prefix, "_visible")) && any(cleaned_text == paste0(prefix, "_invisible")))

# 4. Replace in draft mode (README step 2 continued): R output goes in, the placeholders are kept
section("4. Replace (draft mode)")
map <- placeholder_map(specs = all_specs)
filled <- timestamped_path(file.path(work, "filled.md"))
replace_placeholders(cleaned, placeholder_prefix = prefix, code_content = map,
	draft_mode = TRUE, marker_mode = "hidden", output_file = filled)
filled_text <- readLines(filled, warn = FALSE)
check("replace_placeholders(output_file=) writes the filled file", file.exists(filled))
check("one draft block per placeholder", count_fixed(filled_text, "DRAFT_CONTENT_START") == n_placeholders &&
	count_fixed(filled_text, "DRAFT_CONTENT_END") == n_placeholders)
check("no old -- draft markers are written", count_fixed(filled_text, "--DRAFT_CONTENT") == 0)
check("the markers are kept in the draft", count_fixed(filled_text, "[placeholder_visible]{custom-style") == 1 &&
	count_fixed(filled_text, "[placeholder_invisible]{custom-style") == 1)
check("the R output is in the draft", any(grepl("nrow(mtcars)", filled_text, fixed = TRUE)) &&
	any(grepl("first value", filled_text, fixed = TRUE)) &&
	any(grepl("```{r mtcarsplot", filled_text, fixed = TRUE)))

# 5. The writer edits in Word (simulated by a Word round trip), then the coder re-imports (README steps 3 and 4)
section("5. Writer edit and re-import (refresh, not duplicate)")
edited_docx <- file.path(drafts, "report_v3_edited.docx")
system2(pandoc, c(shQuote(filled), "-o", shQuote(edited_docx)))
Sys.setFileTime(edited_docx, Sys.time() + 60)
check("the edited draft was written", file.exists(edited_docx))
reimport_md <- file.path(work, "reimport.md")
convert_markdown(latest_word_file(drafts, base_name = "report"), markdown_file = reimport_md, media_base_dir = NULL)
check("the newest file (the writer's edit) is the one converted",
	basename(latest_word_file(drafts, base_name = "report")) == "report_v3_edited.docx")
clean_markdown(reimport_md, clear_draft = TRUE, clear_placeholder_styling = TRUE, placeholder_prefix = prefix)
after_clear <- readLines(reimport_md, warn = FALSE)
check("clear_draft removes the draft content", count_fixed(after_clear, "DRAFT_CONTENT") == 0)
check("each placeholder is back exactly once after clearing",
	all(vapply(ids, function(id) count_fixed(after_clear, paste0(prefix, "_", id)) == 1, logical(1))))

# 6. New R result: replacing again refreshes the draft
section("6. Refresh with a new value")
refresh_map <- placeholder_map(specs = list(
	visible_spec,
	define_content(
		placeholder_id = "invisible",
		output_mode = "inline",
		content_type = "text",
		content = { "refreshed value" }
	),
	nmtcars_spec,
	mtcarsplot_spec
))
replace_placeholders(reimport_md, placeholder_prefix = prefix, code_content = refresh_map,
	draft_mode = TRUE, marker_mode = "hidden")
refreshed <- readLines(reimport_md, warn = FALSE)
check("the refreshed draft still has one draft block per placeholder",
	count_fixed(refreshed, "DRAFT_CONTENT_START") == n_placeholders)
check("the new value is in place", any(grepl("refreshed value", refreshed, fixed = TRUE)))
check("the old value has gone", !any(grepl("first value", refreshed, fixed = TRUE)))

# 7. Final render: draft_mode = FALSE straight from the draft, with no draft markers in the output
section("7. Final replace (draft_mode = FALSE)")
final <- file.path(work, "final.md")
replace_placeholders(reimport_md, placeholder_prefix = prefix, code_content = refresh_map,
	draft_mode = FALSE, marker_mode = "off", output_file = final)
final_text <- readLines(final, warn = FALSE)
check("the final file has no draft markers", count_fixed(final_text, "DRAFT_CONTENT") == 0)
check("the final file has the refreshed value", any(grepl("refreshed value", final_text, fixed = TRUE)))
check("the final file has no placeholder names or markers left (marker_mode = \"off\")",
	count_fixed(final_text, paste0(prefix, "_")) == 0)

# 8. overwrite = FALSE stops before writing
section("8. overwrite = FALSE")
check("replace_placeholders(overwrite = FALSE) refuses an existing output", inherits(tryCatch(
	replace_placeholders(cleaned, placeholder_prefix = prefix, code_content = map,
		draft_mode = TRUE, output_file = filled, overwrite = FALSE), error = function(e) e), "error"))
check("convert_markdown(overwrite = FALSE) refuses an existing markdown file", inherits(tryCatch(
	convert_markdown(latest, markdown_file = md, overwrite = FALSE), error = function(e) e), "error"))

# 9. run_workflow: a folder with a base_name, and each step feeding the next
section("9. run_workflow (folder input, chained steps)")
chain <- file.path(work, "chain")
dir.create(chain)
invisible(file.copy(template, file.path(chain, "report_chain.docx")))
chained_md <- file.path(work, "chained.md")
out <- run_workflow(
	input_file = chain,
	base_name = "report",
	markdown_file = chained_md,
	placeholder_prefix = prefix,
	code_content = refresh_map,
	draft_mode = TRUE,
	marker_mode = "hidden"
)
check("run_workflow() returns the filled markdown", count_fixed(out, "DRAFT_CONTENT_START") == n_placeholders)
check("run_workflow() fills in the refreshed value", any(grepl("refreshed value", out, fixed = TRUE)))
check("run_workflow() leaves no bare placeholder outside its marker",
	count_fixed(out, paste0(prefix, "_")) == count_fixed(out, "custom-style=\"PlaceholderMarker"))

# 10. define_content usability
section("10. define_content usability")
spec <- define_content(placeholder_id = "x", output_mode = "chunk", content = {
	a <- 1
	a + 1
})
body <- .chunk_body(spec$content_expr)
check("define_content works without description/content_type", is.null(spec$description))
check("a { } block is written one statement per line",
	identical(strsplit(body, "\n", fixed = TRUE)[[1]], c("a <- 1", "a + 1")))

# 11. Quarto render of the final markdown, the way the README describes (optional)
section("11. Quarto render (optional)")
quarto_ok <- requireNamespace("quarto", quietly = TRUE) && !inherits(tryCatch(quarto::quarto_path(),
	error = function(e) e), "error")
if (quarto_ok) {
	qmd <- file.path(work, "report.qmd")
	writeLines(c("---", "title: Test report", "format: html", "---", "", "{{< include final.md >}}"), qmd)
	ok <- tryCatch({
		quarto::quarto_render(qmd, quiet = TRUE)
		html <- file.path(work, "report.html")
		file.exists(html) && any(grepl("refreshed value", readLines(html, warn = FALSE), fixed = TRUE))
	}, error = function(e) FALSE)
	check("the final markdown renders with Quarto and shows the value", ok)
} else {
	cat("SKIP  Quarto not found; skipping the render check\n")
}

# Summary
section("Summary")
cat(sum(results$passed), "of", nrow(results), "checks passed\n")
if (any(!results$passed)) {
	cat("Failed:\n")
	print(results[!results$passed, "check", drop = FALSE], row.names = FALSE)
}
cat("\nOpen the outputs in: ", normalizePath(work), "\n", sep = "")
invisible(results)
