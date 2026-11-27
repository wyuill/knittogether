# Tidy converted Markdown for Quarto

Fixes things that Word and PowerPoint leave behind after
[`convert_markdown()`](https://wyuill.github.io/knittogether/reference/convert_markdown.md),
so the Markdown works in Quarto. Each fix is optional:

- removes stray escaping from citations,

- moves headings down a level, for all headings or for PowerPoint slides
  under a section,

- turns draft blocks written by
  [`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
  back into their placeholders, ready to fill again,

- removes Word styling and formatting from placeholders.

## Usage

``` r
clean_markdown(
  markdown_file = "markdown_output.md",
  clean_citations = FALSE,
  pptx_section_offset = FALSE,
  heading_offset = FALSE,
  clear_draft = FALSE,
  draft_mode_prefix = "DRAFT_CONTENT_START",
  draft_mode_suffix = "DRAFT_CONTENT_END",
  clear_placeholder_styling = TRUE,
  placeholder_prefix = "placeholder_",
  output_file = NULL,
  overwrite = TRUE
)
```

## Arguments

- markdown_file:

  Path to the Markdown file to clean.

- clean_citations:

  Logical. If `TRUE`, remove the backslashes Pandoc adds to citations,
  so `\[@key\]` becomes `[@key]`. Defaults to `FALSE`.

- pptx_section_offset:

  Logical. If `TRUE`, move each heading that has body text under it down
  one level (to a maximum of 6). For slides, this keeps Section Header
  slides at the top level and puts the slides beneath them. Defaults to
  `FALSE`.

- heading_offset:

  Logical. If `TRUE`, move every heading down one level (to a maximum of
  6), so a Word "Heading 1" doesn't become the page title in HTML.
  Applied after `pptx_section_offset`. Defaults to `FALSE`.

- clear_draft:

  Logical. If `TRUE`, replace each draft block with the placeholder it
  was filled from, ready for
  [`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
  to fill again. `placeholder_prefix` must match the one used to fill
  the draft: otherwise no placeholder is found and the draft content is
  removed with nothing to refill. Defaults to `FALSE`.

- draft_mode_prefix, draft_mode_suffix:

  The lines that start and end a draft block. Defaults to
  `"DRAFT_CONTENT_START"` and `"DRAFT_CONTENT_END"`. Avoid `--`, which
  Word turns into a dash.

- clear_placeholder_styling:

  Logical. If `TRUE` (the default), remove the Word style and any bold,
  italic, superscript or subscript from placeholders, so
  `[placeholder_total]{custom-style="PlaceholderMarker"}` becomes
  `placeholder_total`. Only placeholders are changed.

- placeholder_prefix:

  The text every placeholder starts with, used exactly as given. The
  placeholder is the prefix followed by the ID, so the default
  `"placeholder_"` with the ID `plot` gives `placeholder_plot`. Choose
  any prefix that won't appear by accident in normal writing, such as
  `"knit_"` or `"xyz_"`. Use the same prefix in `clean_markdown()` and
  [`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md).
  Defaults to `"placeholder_"`.

- output_file:

  Path to write the result to, leaving `markdown_file` unchanged.
  Defaults to `NULL`, which overwrites `markdown_file`.

- overwrite:

  Logical. If `FALSE`, stop rather than write over an existing file.
  Defaults to `TRUE`. Use
  [`timestamped_path()`](https://wyuill.github.io/knittogether/reference/timestamped_path.md)
  to keep earlier versions.

## Value

The cleaned lines, invisibly.

## See also

Other workflow:
[`convert_markdown()`](https://wyuill.github.io/knittogether/reference/convert_markdown.md),
[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md),
[`run_workflow()`](https://wyuill.github.io/knittogether/reference/run_workflow.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# After converting a Word document for the first time
clean_markdown(
  "draft.md",
  placeholder_prefix = "placeholder_",
  heading_offset = TRUE,
  clean_citations = TRUE
)

# After the writer has edited a filled draft
clean_markdown(
  "draft.md",
  placeholder_prefix = "placeholder_",
  clear_draft = TRUE
)
} # }
```
