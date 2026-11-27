# Write a heading with a background image

In PowerPoint output, returns a heading with a background image, for
section or title slides. In other formats it returns a plain heading, or
nothing if `include_html = FALSE`.

The image is looked up in `bg_dir` by file name without its extension.
It can be named after the heading level (`level1.png` or `1.png`) or
after `bg`. Exactly one file must match. Make the image the same size as
your slides.

## Usage

``` r
pptx_section_slide(level = 1, title, bg = NULL, include_html = TRUE, bg_dir)
```

## Arguments

- level:

  Heading level: 1 for `#`, 2 for `##` and so on. Defaults to 1.

- title:

  The heading text.

- bg:

  Optional. The image's file name without the extension, for example
  `"blue"` for `blue.png`.

- include_html:

  Logical. If `FALSE`, write nothing when the output isn't PowerPoint.
  Defaults to `TRUE`.

- bg_dir:

  The folder that holds the background images.

## Value

The heading, ready to print in a chunk with `output: asis`, or `NULL`.

## See also

Other PowerPoint:
[`add_pptx_backgrounds_to_headers()`](https://wyuill.github.io/knittogether/reference/add_pptx_backgrounds_to_headers.md),
[`auto_slide_break()`](https://wyuill.github.io/knittogether/reference/auto_slide_break.md),
[`insert_slide_break()`](https://wyuill.github.io/knittogether/reference/insert_slide_break.md),
[`pptx_col_start()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md),
[`slide_break()`](https://wyuill.github.io/knittogether/reference/slide_break.md)

## Examples

``` r
if (FALSE) { # \dontrun{
pptx_section_slide(level = 1, title = "Results", bg = "blue", bg_dir = "backgrounds")
} # }
```
