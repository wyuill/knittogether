# Split a markdown file into section-specific markdown (and optional Quarto) files

Splits a markdown document at a specified pattern and writes each
section to its own subdirectory. This is useful for converting long
documents into smaller pages that map cleanly onto Quarto side
navigation.

## Usage

``` r
split(
  markdown_file,
  output_dir = NULL,
  split_pattern = "^# ",
  qmd = c("none", "separate", "embed"),
  rewrite_includes = TRUE
)
```

## Arguments

- markdown_file:

  Path to the markdown file to split.

- output_dir:

  Output directory or directories for the split files. If NULL,
  directories are derived from slugified section headings.

- split_pattern:

  Regular expression identifying split points. Defaults to "^# "
  (level-1 headers).

- qmd:

  Controls Quarto output:

  none

  : Do not create Quarto files; headings are preserved in markdown.

  separate

  : Create a markdown file and an index.qmd file that includes it.

  embed

  : Create an index.qmd file with the markdown content embedded
    directly.

- rewrite_includes:

  Logical; whether to rewrite Quarto include statements to account for
  sections being written to subdirectories. Defaults to TRUE. Set to
  FALSE to leave include paths unchanged.

## Value

A character vector of paths to the created files.

## Details

When Quarto output is requested, the level-1 section heading is moved
into Quarto YAML metadata (title and order) and removed from the
markdown body.

Quarto include statements can optionally be rewritten when sections are
written to subdirectories so that relative include paths continue to
resolve correctly. This behaviour is enabled by default but can be
disabled for documents that already use depth-aware or project-root
paths.

## Examples

``` r
if (FALSE) { # \dontrun{
split(
  "slides.md",
  qmd = "separate"
)
} # }
```
