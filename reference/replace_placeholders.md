# Replace placeholders in a Markdown / Quarto document

Replace tokens of the form `<placeholder_prefix>_<slug>` using scalars
or `content_spec` from
[`define_content()`](https://wyuill.github.io/knittogether/reference/define_content.md).
Execution is deferred to knitr/Quarto.

### Marker behavior

One (and only one) marker is emitted per replacement, **independent of
`draft_mode`**, controlled by `marker_mode`:

- `"hidden"` (default): `[token]{custom-style="PlaceholderMarker"}`

- `"show"`: `[token]{custom-style="PlaceholderMarkerVisible"}`

- `"off"`: *(no marker)*

For DOCX, define both character styles in your reference DOCX. For HTML,
hide hidden markers by including the following CSS in your document:
`span[data-custom-style="PlaceholderMarker"] { display: none !important; }`

### Draft mode

If `draft_mode = TRUE`, the placeholder is bookended with markers. For
example, a block would appear as:

    DRAFT_CONTENT_START
    <marker if any>
    <content>
    DRAFT_CONTENT_END

## Usage

``` r
replace_placeholders(
  markdown_file,
  placeholder_prefix = "placeholder_content",
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

  Path to the Markdown/Quarto file (overwritten).

- placeholder_prefix:

  Character prefix identifying the placeholder. Defaults to
  `"placeholder_content"`.

- code_content:

  Named list mapping slugs to scalars or `content_spec`. Defaults to an
  empty list.

- draft_mode:

  Logical; if `TRUE`, wrap in plain draft markers. Defaults to `TRUE`.
  Keep this on for any document that will be read back from Word: the
  draft markers are how the inserted content is found and cleared on the
  next pass (see
  [`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)).
  With `FALSE` the output has no draft markers: any draft blocks already
  in the file are reduced to their placeholders and filled in, so a
  final render can be run straight from a draft.

- draft_mode_prefix, draft_mode_suffix:

  Strings for draft boundaries. Defaults to `"DRAFT_CONTENT_START"` and
  `"DRAFT_CONTENT_END"` respectively. These are used instead of
  `--DRAFT_CONTENT--` because Word turns `--` into a dash, which stopped
  the markers being found on re-import. Documents made with the old
  markers need them replaced before they are cleaned.

- validation_path:

  Optional directory for a CSV log of what has been replaced. Setting
  this to `NULL` disables the creation of the log. Defaults to `NULL`.

- marker_mode:

  Controls the styling, if any, applied to placeholder markers. One of:

  - `"hidden"` (default) where markers are included but the
    `PlaceholderMarker` style is applied, for example,
    `[placeholder_content_value]{custom-style="PlaceholderMarker"}`,

  - `"show"` where markers are included and the
    `PlaceholderMarkerVisible` style is applied, for example,
    `[placeholder_content_value]{custom-style="PlaceholderMarkerVisible"}`,

  - `"off"` where no marker is written at all. Nothing is left in the
    document to say where the inserted content came from. Use this only
    when the document will not be read back in from Word, because
    content inserted with `"off"` cannot be found and refreshed on a
    later import. The marker is not replaced with a plain placeholder
    token; the inserted content is all that remains. The names of the
    relevant styles are defined in `placeholder_style_hidden` and
    `placeholder_style_visible`.

- placeholder_style_hidden, placeholder_style_visible:

  The names of the styles used for hidden/visible markers as applied in
  `marker_mode`. Defaults to `"PlaceholderMarker"` and
  `"PlaceholderMarkerVisible"` respectively. An example of a Word
  document with these styles is included within the package. Run the
  following code to access it:


      path <- system.file("extdata", "PlaceholderMarker_example.docx",
                          package = "knittogether")
      utils::browseURL(path)

- log_file:

  CSV log file name (within `validation_path`) to be generated and to
  read (if already exists). If `NULL` the log is not generated. Defaults
  to `"quality_log.csv"`.

- html_file:

  HTML report file name (within `validation_path`) to be generated. If
  this already exists it will be overwritten. If `NULL` the report is
  not generated. Default: `"validation.html"`.

- output_file_ext:

  The extension for the output file. Typically, `'md'` but Quarto can
  sometimes raise errors if it detects executable code in markdown and
  require a '.qmd' file instead, regardless of whether there is
  executable code present. Defaults to `'md'`.

- output_file:

  Optional path to write the result to. `markdown_file` is then left
  unchanged, and `output_file_ext` is ignored. Defaults to `NULL`, which
  writes next to `markdown_file` as before.

- overwrite:

  Logical; if `FALSE`, stop rather than write over an existing output
  file. Defaults to `TRUE`, so existing scripts keep overwriting. Use
  [`timestamped_path()`](https://wyuill.github.io/knittogether/reference/timestamped_path.md)
  to keep earlier versions.

## Value

Invisibly returns the updated Markdown (character vector).

## Examples

``` r
if (FALSE) { # \dontrun{
spec <- define_content(
  description     = "A plot of mtcars",
  placeholder_id  = "mtcarsplot",
  output_mode     = "chunk",
  content         = { plot(mtcars$wt, mtcars$mpg) },
  content_type    = "plot",
  chunk_options   = list(echo = FALSE, fig.width = 7)
)
code_map <- placeholder_map(specs = list(spec))
replace_placeholders(
  markdown_file = "markdown_output.md",
  placeholder_prefix = "placeholder_content",
  code_content = code_map,
  draft_mode = TRUE,
  draft_mode_prefix = "DRAFT_CONTENT_START",
  draft_mode_suffix = "DRAFT_CONTENT_END",
  validation_path = "validation",
  marker_mode = "hidden",
  placeholder_style_hidden = "PlaceholderMarker",
  placeholder_style_visible = "PlaceholderMarkerVisible"
  )
} # }
```
