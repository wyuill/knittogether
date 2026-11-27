# Add a background image to headings in Markdown

Adds a background image to every heading of the given levels in `text`,
for example all section slides in converted Markdown. Headings inside
code blocks are left alone.

## Usage

``` r
add_pptx_backgrounds_to_headers(text, levels = 1, bg, bg_dir, overwrite = TRUE)
```

## Arguments

- text:

  A single string of Markdown.

- levels:

  The heading levels to change. Defaults to 1.

- bg:

  The image's file name without the extension, for example `"blue"` for
  `blue.png`.

- bg_dir:

  The folder that holds the background images.

- overwrite:

  Logical. If `TRUE` (the default), replace a background a heading
  already has.

## Value

`text`, with the background added to those headings.

## See also

Other PowerPoint:
[`auto_slide_break()`](https://wyuill.github.io/knittogether/reference/auto_slide_break.md),
[`insert_slide_break()`](https://wyuill.github.io/knittogether/reference/insert_slide_break.md),
[`pptx_col_start()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md),
[`pptx_section_slide()`](https://wyuill.github.io/knittogether/reference/pptx_section_slide.md),
[`slide_break()`](https://wyuill.github.io/knittogether/reference/slide_break.md)

## Examples

``` r
if (FALSE) { # \dontrun{
add_pptx_backgrounds_to_headers(text, levels = 1, bg = "blue", bg_dir = "backgrounds")
} # }
```
