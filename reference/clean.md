# Clean Pandoc‑generated Markdown for use in Quarto (.qmd)

Post‑processes Markdown so that it’s suitable for inclusion in Quarto
(`.qmd`) documents. Optionally:

- fixes citation escaping,

- adjusts PowerPoint‑derived heading levels,

- globally offsets headings,

- clears draft blocks written by
  [`replace()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace.md),
  keeping only the placeholder,

- removes styling from placeholder markers written by
  [`replace()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace.md).

## Usage

``` r
clean(
  markdown_file = "markdown_output.md",
  clean_citations = FALSE,
  pptx_section_offset = FALSE,
  heading_offset = FALSE,
  clear_draft = FALSE,
  draft_mode_prefix = "--DRAFT_CONTENT--",
  draft_mode_suffix = "--END_DRAFT_CONTENT--",
  clear_placeholder_styling = TRUE,
  placeholder_prefix = "placeholder_content"
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

  Start marker (plain string). Default: `"--DRAFT_CONTENT--"`.

- draft_mode_suffix:

  End marker (plain string). Default: `"--END_DRAFT_CONTENT--"`.

- clear_placeholder_styling:

  Logical; if `TRUE`, removes styling tags applied to placeholder
  markers. For example,
  `"[placeholder_content_test]{custom-style=\"PlaceholderMarker\"}"` is
  cleaned to `"placeholder_content_test"`. Defaults to `TRUE`.

- placeholder_prefix:

  Prefix used to identify placeholder tokens (e.g.,
  `"placeholder_content"` matches `"placeholder_content_my_id"`).
  Defaults to `"placeholder_content"`.

## Value

Invisibly returns the cleaned lines written to the file.

## Examples

``` r
if (FALSE) { # \dontrun{
 # Clean a Markdown file with all options enabled
 clean(
   markdown_file = "markdown_output.md",
   clean_citations = TRUE,
   pptx_section_offset = TRUE,
   heading_offset = TRUE,
   clear_draft = TRUE,
   draft_mode_prefix = "--DRAFT_CONTENT--",
   draft_mode_suffix = "--END_DRAFT_CONTENT--",
   clear_placeholder_styling = TRUE
 )
} # }
```
