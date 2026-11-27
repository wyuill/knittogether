# Split a slide into two columns

Put `pptx_col_start()` before the first column's content,
`pptx_col_break()` between the columns and `pptx_col_end()` after the
second column. Each returns the Markdown for that point, so use them in
inline code. In HTML output they return nothing, and the content runs
down the page as normal.

## Usage

``` r
pptx_col_start(width = 50)

pptx_col_break(width = 50)

pptx_col_end()
```

## Arguments

- width:

  The column's width, as a percentage of the slide. In
  `pptx_col_start()` this is the first column; in `pptx_col_break()` the
  second. Defaults to 50.

## Value

The Markdown that starts, divides or ends the columns, or `NULL` in HTML
output.

## See also

Other PowerPoint:
[`add_pptx_backgrounds_to_headers()`](https://wyuill.github.io/knittogether/reference/add_pptx_backgrounds_to_headers.md),
[`auto_slide_break()`](https://wyuill.github.io/knittogether/reference/auto_slide_break.md),
[`insert_slide_break()`](https://wyuill.github.io/knittogether/reference/insert_slide_break.md),
[`pptx_section_slide()`](https://wyuill.github.io/knittogether/reference/pptx_section_slide.md),
[`slide_break()`](https://wyuill.github.io/knittogether/reference/slide_break.md)

## Examples

``` r
pptx_col_start(width = 40)
#> [1] ":::: columns\n::: {.column width='40%'}"
pptx_col_break(width = 60)
#> [1] ":::\n::: {.column width='60%'}"
pptx_col_end()
#> [1] ":::\n::::"
```
