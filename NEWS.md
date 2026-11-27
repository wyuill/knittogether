# knittogether 0.1.5

## Breaking changes
* Functions are renamed to a verb-noun pattern so they don't clash with functions in other packages. The old names are removed without deprecation:
  * `convert()` is now `convert_markdown()`
  * `clean()` is now `clean_markdown()`
  * `split()` is now `split_markdown()`
  * `replace()` is now `replace_placeholders()`
## Bug fixes
* `%||%` is now imported from rlang, so the package no longer needs R >= 4.4.0 without declaring it. `tools` is now listed in Imports.
* `auto_slide_break()` no longer loops forever when a section starts with a heading and is longer than `limit`. `insert_slide_break()` now ignores a heading at the very start of the text when choosing where to break.
* `replace_placeholders()` matches each placeholder as a whole word and handles longer slugs first, so `placeholder_content_plot` no longer overwrites part of `placeholder_content_plot_2`, or of a marker that has already been inserted.
* `replace_placeholders()` gives each copy of a chunk placeholder its own label (`plot`, `plot_2`, ...). Previously a placeholder used twice produced duplicate labels, which stops knitr.
* `as_child`, `child_dir` and `engine` are no longer written into chunk headers. Inline and child chunks now share one header builder.
* `clean_markdown(clear_placeholder_styling = TRUE)` (the default) now only unwraps spans that contain a placeholder token. It previously collapsed all whitespace on every line, which flattened nested lists, code and grid tables and removed hard line breaks, and it deleted every `{custom-style="..."}` attribute in the document.
* Heading offsets, PowerPoint section offsets, slide-break and background-header processing now only treat real Markdown headings as headings (a space after the `#`s, outside fenced code and YAML). Previously `#| echo: false` and `# comment` lines inside code chunks could be edited.
* `is_pdf()` now detects PDF output (it always returned `FALSE`).
* `hide_markers_css()` targets `data-custom-style`, the attribute Pandoc writes to HTML, so hidden markers are actually hidden.
* `run_workflow()` now errors on unrecognised or unnamed arguments. Previously a misspelt argument such as `heading_ofset = TRUE` was silently ignored.
* `clean_markdown()` removes Word formatting (superscript, subscript, bold, italic) that sits tight against a placeholder, so the formatting is no longer wrapped round the code output (PHDAT-1198).
* `convert_markdown()` now defaults to `pandoc_version = "default"`. If the default Pandoc is missing or older than 3.8.3, a Pandoc bundled with RStudio/Positron or Quarto that meets 3.8.3 is used. Start-up checks use the same logic.
* `clean_markdown()` also removes the U+27E6 / U+27E7 brackets the example template puts around placeholders, and the superscript and subscript formatting those placeholders carry in Word. A test runs the example docx through convert and clean (PHDAT-1198).
* `clean_markdown()` no longer errors on documents without the example template's bracket characters. The patterns used `\x{...}` escapes that PCRE rejects in non-UTF-8 text.
* Draft markers default to `DRAFT_CONTENT_START` and `DRAFT_CONTENT_END` instead of `--DRAFT_CONTENT--` and `--END_DRAFT_CONTENT--`, because Word turns `--` into a dash and the markers could not be found on re-import. Documents written with the old markers must have them replaced before running `clean_markdown()`. `draft_mode` still defaults to `TRUE`.
* `replace_placeholders()` docs now state that `marker_mode = "off"` writes no marker and that content inserted this way can't be refreshed on re-import. The extended-workflow vignette shows the `pre-render` step that builds the markdown before each Quarto render (PHDAT-1199, PHDAT-1004).
* `replace_placeholders(draft_mode = FALSE)` now removes draft markers left by an earlier draft pass, so the output has none and the final render can run straight from the draft. Draft blocks with no placeholder marker are left alone.
* `define_content()` works without `description` or `content_type`. A top-level `{ }` block is unwrapped so every value prints in a chunk. `content` can be passed through a function or injected with `!!`, for example inside `lapply()`.
* `split_markdown()` gives each section its own subfolder when one `output_dir` is supplied, so sections no longer overwrite one `output.md`. Repeated headings get `-2`, `-3`, ... folder names. Content before the first split point is saved to `split_preamble.md` instead of being dropped. Titles containing quotes or backslashes are escaped in the YAML header.
* The package now depends on R >= 4.4.0 (for base `%||%`) rather than importing `%||%` from rlang.
* The README has a quick start following the workflow poster (writer adds placeholders, coder fills them from R, writer edits, coder re-imports, final render), with the terms placeholder, marker and draft block.
* `latest_word_file()` finds the most recently saved .docx or .pptx in a folder, optionally by base name, ignoring Word lock files. `timestamped_path()` adds a time stamp to an output name so it is never overwritten (PHDAT-1200).
* `convert_markdown()`, `clean_markdown()` and `replace_placeholders()` take `overwrite`. With `overwrite = FALSE` they stop rather than write over an existing file. `clean_markdown()` and `replace_placeholders()` also take `output_file`, which writes the result somewhere else and leaves the input unchanged. The default still overwrites, so existing scripts behave as before.
* `run_workflow()` takes a folder as `input_file` and uses its newest Word or PowerPoint file, optionally restricted by `base_name`. Each step now reads the previous step's output, so `output_file` from `clean_markdown()` is what `replace_placeholders()` fills.
* `clean_markdown(clear_draft = TRUE)` needs the same `placeholder_prefix` used to fill the draft. Documented in the README and extended workflow vignette.
