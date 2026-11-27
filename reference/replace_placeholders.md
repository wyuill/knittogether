# Fill placeholders with R content

Swaps each placeholder (`placeholder_prefix` followed by an ID) in a
Markdown file for the content given in `code_content`. Code isn't run
here. It's written into the Markdown as inline R or a chunk, and runs
when Quarto renders the document.

Each piece of content is written with a marker naming its placeholder
(see `marker_mode`) and, in draft mode, wrapped in draft markers:

    DRAFT_CONTENT_START
    <marker>
    <content>
    DRAFT_CONTENT_END

Together these let
[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)
turn the content back into its placeholder when the document returns
from Word, so it can be filled again.
[`vignette("knittogether")`](https://wyuill.github.io/knittogether/articles/knittogether.md)
explains the round trip.

## Usage

``` r
replace_placeholders(
  markdown_file,
  placeholder_prefix = "placeholder_",
  code_content = list(),
  draft_mode = TRUE,
  draft_mode_prefix = "DRAFT_CONTENT_START",
  draft_mode_suffix = "DRAFT_CONTENT_END",
  validation_path = NULL,
  marker_mode = c("hidden", "show", "off"),
  placeholder_style_hidden = "PlaceholderMarker",
  placeholder_style_visible = "PlaceholderMarkerVisible",
  log_file = "quality_log.csv",
  html_file = "validation.html",
  output_file_ext = "md",
  output_file = NULL,
  overwrite = TRUE
)
```

## Arguments

- markdown_file:

  Path to the Markdown file to fill.

- placeholder_prefix:

  The text every placeholder starts with, used exactly as given. The
  placeholder is the prefix followed by the ID, so the default
  `"placeholder_"` with the ID `plot` gives `placeholder_plot`. Choose
  any prefix that won't appear by accident in normal writing, such as
  `"knit_"` or `"xyz_"`. Use the same prefix in
  [`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)
  and `replace_placeholders()`. Defaults to `"placeholder_"`.

- code_content:

  The content for each placeholder, as made by
  [`placeholder_map()`](https://wyuill.github.io/knittogether/reference/placeholder_map.md).

- draft_mode:

  Logical. If `TRUE` (the default), wrap each piece of content in draft
  markers. Keep this on while the document is still going back to Word.
  If `FALSE`, no draft markers are written, and any draft blocks already
  in the file are turned back into placeholders and filled, so you can
  make the final version straight from a draft.

- draft_mode_prefix, draft_mode_suffix:

  The lines that start and end a draft block. Defaults to
  `"DRAFT_CONTENT_START"` and `"DRAFT_CONTENT_END"`. Avoid `--`, which
  Word turns into a dash.

- validation_path:

  Folder for the validation log, a CSV of which placeholders were found
  and filled and what changed since the last run. If the `quarto` and
  `reactable` packages are installed, an HTML version is made too.
  Defaults to `NULL`, which writes no log.

- marker_mode:

  How the marker naming each placeholder is written:

  - `"hidden"` (the default) uses the `placeholder_style_hidden` style,
    which can be set to hidden text in Word.

  - `"show"` uses the `placeholder_style_visible` style.

  - `"off"` writes no marker. Use this only for the final version:
    nothing is left to show where the content came from, so it can't be
    refreshed after another round in Word.

  In HTML output,
  [`hide_markers_css()`](https://wyuill.github.io/knittogether/reference/hide_markers_css.md)
  hides the markers.

- placeholder_style_hidden, placeholder_style_visible:

  Names of the Word character styles used for markers. Defaults to
  `"PlaceholderMarker"` and `"PlaceholderMarkerVisible"`. The package
  includes a Word document with both styles set up:
  `system.file("extdata", "PlaceholderMarker_example.docx", package = "knittogether")`.

- log_file, html_file:

  File names for the validation log and its HTML version, inside
  `validation_path`. Set either to `NULL` to skip it. Defaults to
  `"quality_log.csv"` and `"validation.html"`.

- output_file_ext:

  Extension for the output file when `output_file` isn't given. Defaults
  to `"md"`. Use `"qmd"` if Quarto complains about executable code in a
  `.md` file.

- output_file:

  Path to write the result to, leaving the input file unchanged.
  Defaults to `NULL`, which writes to `markdown_file` (with its
  extension changed to `output_file_ext`).

- overwrite:

  Logical. If `FALSE`, stop rather than write over an existing file.
  Defaults to `TRUE`. Use
  [`timestamped_path()`](https://wyuill.github.io/knittogether/reference/timestamped_path.md)
  to keep earlier versions.

## Value

The filled Markdown, invisibly, as a character string.

## See also

[`define_content()`](https://wyuill.github.io/knittogether/reference/define_content.md),
[`placeholder_map()`](https://wyuill.github.io/knittogether/reference/placeholder_map.md),
[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)

Other workflow:
[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md),
[`convert_markdown()`](https://wyuill.github.io/knittogether/reference/convert_markdown.md),
[`run_workflow()`](https://wyuill.github.io/knittogether/reference/run_workflow.md)

## Examples

``` r
if (FALSE) { # \dontrun{
plot <- define_content(
  placeholder_id = "plot",
  description = "Car weight against fuel economy",
  output_mode = "chunk",
  content = { plot(mtcars$wt, mtcars$mpg) },
  chunk_options = list(echo = FALSE)
)

# While the document is still a draft
replace_placeholders(
  markdown_file = "draft.md",
  placeholder_prefix = "placeholder_",
  code_content = placeholder_map(specs = list(plot)),
  validation_path = "validation"
)

# The final version
replace_placeholders(
  markdown_file = "draft.md",
  placeholder_prefix = "placeholder_",
  code_content = placeholder_map(specs = list(plot)),
  draft_mode = FALSE,
  marker_mode = "off"
)
} # }
```
