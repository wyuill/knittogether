# Add Slide Background Images

Returns a header (`#`, `##`, …) with a provided background image

## Usage

``` r
pptx_section_slide(level = 1, title, bg = NULL, include_html = TRUE, bg_dir)
```

## Arguments

- level:

  Header level numeric (1 = `#`, 2 = `##`, etc.).

- title:

  Slide title.

- bg:

  The name of the background image file (without extension e.g.,
  `"blue"` rather than `"blue.png"`).

- include_html:

  If TRUE, emit a header for HTML; otherwise suppress. Defaults to
  `TRUE`.

- bg_dir:

  Directory containing background images.

## Value

A
[`knitr::asis_output()`](https://rdrr.io/pkg/knitr/man/asis_output.html)
object.
