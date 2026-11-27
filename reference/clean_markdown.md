# Clean Pandoc‑generated Markdown for use in Quarto (.qmd)

Post‑processes Markdown so that it’s suitable for inclusion in Quarto
(`.qmd`) documents. Optionally:

- fixes citation escaping,

- adjusts PowerPoint‑derived heading levels,

- globally offsets headings,

- clears draft blocks written by
  [`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md),
  keeping only the placeholder,

- removes styling from placeholder markers written by
  [`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md).

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
  placeholder_prefix = "placeholder_content",
  output_file = NULL,
  overwrite = TRUE
)
```

## Arguments

- markdown_file:

  Path to the Markdown file to clean (overwritten in place).

- clean_citations:

  Logical; if `TRUE`, removes stray escaping in citations, for example
  `\\[@key\\]` becomes `[@key]`. Defaults to `FALSE`.

- pptx_section_offset:

  Logical; if `TRUE`, headings that have body text before the next
  heading are incremented by one level (max 6). Defaults to `FALSE`.

- heading_offset:

  Logical; if `TRUE`, increments all headings by one level (max 6). This
  applies after `pptx_section_offset`. Defaults to `FALSE`.

- clear_draft:

  Logical; if `TRUE`, remove content between draft markers specified in
  `draft_mode_prefix` and `draft_mode_suffix` while retaining the
  placeholder. Defaults to `FALSE`.

- draft_mode_prefix:

  Start marker (plain string). Default: `"DRAFT_CONTENT_START"`.

- draft_mode_suffix:

  End marker (plain string). Default: `"DRAFT_CONTENT_END"`.

- clear_placeholder_styling:

  Logical; if `TRUE`, removes styling tags applied to placeholder
  markers. For example,
  `"[placeholder_content_test]{custom-style=\"PlaceholderMarker\"}"` is
  cleaned to `"placeholder_content_test"`. Only spans that contain
  nothing but a placeholder token are changed; other `custom-style`
  spans and all whitespace are left as they are. Defaults to `TRUE`.

- placeholder_prefix:

  Prefix used to identify placeholder tokens (e.g.,
  `"placeholder_content"` matches `"placeholder_content_my_id"`).
  Defaults to `"placeholder_content"`.

- output_file:

  Optional path to write the cleaned Markdown to. `markdown_file` is
  then left unchanged. Defaults to `NULL`, which overwrites
  `markdown_file`.

- overwrite:

  Logical; if `FALSE`, stop rather than write over an existing file.
  Defaults to `TRUE`, so existing scripts keep overwriting. Use
  [`timestamped_path()`](https://wyuill.github.io/knittogether/reference/timestamped_path.md)
  to keep earlier versions.

## Value

Invisibly returns the cleaned lines written to the file.

## Examples

``` r
if (FALSE) { # \dontrun{
 # Clean a Markdown file with all options enabled
 clean_markdown(
   markdown_file = "markdown_output.md",
   clean_citations = TRUE,
   pptx_section_offset = TRUE,
   heading_offset = TRUE,
   clear_draft = TRUE,
   draft_mode_prefix = "DRAFT_CONTENT_START",
   draft_mode_suffix = "DRAFT_CONTENT_END",
   clear_placeholder_styling = TRUE
 )
} # }
```
