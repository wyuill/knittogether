# Convert a Word or PowerPoint file to Markdown using Pandoc

Converts a Microsoft Word (`.docx`) or PowerPoint (`.pptx`) file to
Markdown using Pandoc. Media (e.g., embedded images) and citations can
be extracted if requested. The function returns the path to the
generated Markdown file and, optionally, the directory where media was
saved

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

  Path to the input file to convert. Must be a `.docx` or `.pptx` file.

- markdown_file:

  Path to the output Markdown file. The file will be overwritten if it
  already exists. Defaults to `"markdown_output.md"`.

- media_base_dir:

  Path to the **base directory** where extracted media should be saved.
  Pandoc will create a subfolder named `media/` inside this directory
  (e.g., `path/to/base/media/`) and extract all embedded media files
  here. The directory is only created if media is present in the input
  file.

  - Set to `NULL` to disable media extraction entirely.

  - Set to `"."` (the default) to extract media into the current working
    directory `./media/`.

- pandoc_args:

  Additional command-line arguments passed to Pandoc, for example
  `"--wrap=none"` or `"--to=markdown+pipe_tables+grid_tables"`. Provide
  as a single string or character vector. Non-default markdown targets
  can change citation escaping, so
  `clean_markdown(clean_citations = TRUE)` may be useful downstream.
  Defaults to `NULL`.

- pandoc_version:

  Pandoc version to use. Passed directly to
  [`pandoc::pandoc_run()`](https://cderv.github.io/pandoc/reference/pandoc_run.html).
  Defaults to `"default"`. If the default Pandoc is missing or older
  than 3.8.3, a Pandoc bundled with RStudio/Positron (`RSTUDIO_PANDOC`)
  or Quarto that meets 3.8.3 is used instead. `"latest"` can select a
  Pandoc that doesn't match the bundled one, so it is not the default.

- verbose:

  Logical. If `TRUE`, prints informative messages about the Pandoc
  command being executed and the location of extracted media (if any).
  Defaults to `FALSE`.

- overwrite:

  Logical; if `FALSE`, stop rather than write over an existing
  `markdown_file`. Defaults to `TRUE`. Use
  [`timestamped_path()`](https://wyuill.github.io/knittogether/reference/timestamped_path.md)
  to keep earlier versions.

## Value

Invisibly returns a named list with:

- `markdown_file` – the path to the created Markdown file

- `media_dir` – the path to the created `media/` directory, or `NULL` if
  media extraction was disabled or no media was present

## Examples

``` r
if (FALSE) { # \dontrun{
  convert_markdown("report.docx", pandoc_version = "latest")
  convert_markdown("slides.pptx", media_base_dir = "slides_output")
} # }
```
