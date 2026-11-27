# Check the format being rendered

Use these in a Quarto or R Markdown document to do something only for
one output format, for example to add slide breaks only in PowerPoint.
Outside a render, they all return `FALSE`.

## Usage

``` r
is_pptx()

is_docx()

is_pdf()

is_html()
```

## Value

`TRUE` if the document is being rendered to that format, otherwise
`FALSE`.

## See also

Other output format:
[`hide_markers_css()`](https://wyuill.github.io/knittogether/reference/hide_markers_css.md),
[`output_type()`](https://wyuill.github.io/knittogether/reference/output_type.md)

## Examples

``` r
if (is_pptx()) "Only in the slides"
```
