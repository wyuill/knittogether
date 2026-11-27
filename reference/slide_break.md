# Start a new slide

Returns `---`, which starts a new slide, when the document isn't being
rendered to HTML. In HTML it returns nothing, so the same document can
render to both. Use it in inline code, `` `r slide_break()` ``, or as
the `break_fun` of
[`auto_slide_break()`](https://wyuill.github.io/knittogether/reference/auto_slide_break.md).

## Usage

``` r
slide_break()
```

## Value

`"---"`, or `NULL` in HTML output.

## See also

Other PowerPoint:
[`add_pptx_backgrounds_to_headers()`](https://wyuill.github.io/knittogether/reference/add_pptx_backgrounds_to_headers.md),
[`auto_slide_break()`](https://wyuill.github.io/knittogether/reference/auto_slide_break.md),
[`insert_slide_break()`](https://wyuill.github.io/knittogether/reference/insert_slide_break.md),
[`pptx_col_start()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md),
[`pptx_section_slide()`](https://wyuill.github.io/knittogether/reference/pptx_section_slide.md)

## Examples

``` r
slide_break()
#> [1] "---"
```
