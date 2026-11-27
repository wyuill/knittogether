# Check images and tables have alt text or captions

Scans Markdown or HTML for images and tables a screen reader user
couldn't make sense of:

- An image inside a figure needs a descriptive caption. Its alt text
  isn't checked, because the caption is what gets read out.

- An image outside a figure needs descriptive alt text.

- A table needs a descriptive caption: a Markdown `Table:` line, an HTML
  `<caption>` or an `aria-label`.

- `reactable` and `ggiraph` widgets need a descriptive caption.

Missing text, and text that says nothing about the content such as
"Figure 1" or "Img 4", are both reported.

## Usage

``` r
accessibility_scan(lines, output = NULL)
```

## Arguments

- lines:

  The text to check: a character vector with one line per element, a
  single string with line breaks, or an
  [`htmltools::HTML()`](https://rstudio.github.io/htmltools/reference/HTML.html)
  object.

- output:

  Optional. A path to save the results to as a CSV file. Defaults to
  `NULL`.

## Value

A data frame with one row per problem and columns `kind`, `line`, `src`,
`issue` and `snippet`.

## Examples

``` r
accessibility_scan(c("![](plot.png)", "", "![A line chart of rising costs](costs.png)"))
```
