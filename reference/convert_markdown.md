# Convert a Word or PowerPoint file to Markdown

Uses Pandoc to turn a `.docx` or `.pptx` file into Markdown, keeping
headings, lists, tables, footnotes and citations, and saving the images
into a `media/` folder. Run
[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)
on the result next.

## Usage

``` r
convert_markdown(
  input_file,
  markdown_file = "markdown_output.md",
  media_base_dir = ".",
  pandoc_args = NULL,
  pandoc_version = "default",
  verbose = FALSE,
  overwrite = TRUE
)
```

## Arguments

- input_file:

  Path to the `.docx` or `.pptx` file.

- markdown_file:

  Path for the Markdown file. Defaults to `"markdown_output.md"`.

- media_base_dir:

  Folder to save images in. Pandoc creates a `media/` folder inside it,
  but only if the document has images. Defaults to `"."`, the working
  directory. Use `NULL` to skip saving images.

- pandoc_args:

  Extra Pandoc arguments, as a string or character vector, for example
  `"--wrap=none"`, or `"-t gfm"` for tables with long text. Some
  Markdown flavours add escaping to citations, which
  `clean_markdown(clean_citations = TRUE)` removes. Defaults to `NULL`.

- pandoc_version:

  Which Pandoc to use, passed to
  [`pandoc::pandoc_run()`](https://cderv.github.io/pandoc/reference/pandoc_run.html).
  Defaults to `"default"`. If that Pandoc is missing or older than 3.8.3
  (needed for PowerPoint), the one bundled with RStudio, Positron or
  Quarto is used instead.

- verbose:

  Logical. If `TRUE`, print the Pandoc command and where images were
  saved. Defaults to `FALSE`.

- overwrite:

  Logical. If `FALSE`, stop rather than write over an existing
  `markdown_file`. Defaults to `TRUE`. Use
  [`timestamped_path()`](https://wyuill.github.io/knittogether/reference/timestamped_path.md)
  to keep earlier versions.

## Value

Invisibly, a list with `markdown_file` (the path to the Markdown) and
`media_dir` (the path to the `media/` folder, or `NULL` if no images
were saved).

## See also

Other workflow:
[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md),
[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md),
[`run_workflow()`](https://wyuill.github.io/knittogether/reference/run_workflow.md)

## Examples

``` r
if (FALSE) { # \dontrun{
convert_markdown("draft.docx", markdown_file = "draft.md")
convert_markdown("slides.pptx", markdown_file = "slides.md", media_base_dir = "slides")
} # }
```
