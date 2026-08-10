# Initiating column structure of PowerPoint slide

These functions allow the insertion of columns into markdown output and
are primarily intended for .pptx outputs. `pptx_col_start` initiates the
column. `pptx_col_break` creates a column break. In .pptx outputs there
can only be one column break ordinarily. `pptx_col_end` ends the column
section, returning to full width content.

## Usage

``` r
pptx_col_start(width = 50)

pptx_col_break(width = 50)

pptx_col_end()
```

## Arguments

- width:

  Column width as a percentage from 0 to 100. In `pptx_col_start()` this
  is the first column width; in `pptx_col_break()` this is the second
  column width.

## Examples

``` r

 pptx_col_start(width = 40)
#> [1] ":::: columns\n::: {.column width='40%'}"

 # column content (e.g. plot(mtcars))

 pptx_col_break(width = 60)
#> [1] ":::\n::: {.column width='60%'}"

 # column content (e.g. head(mtcars))

 pptx_col_end()
#> [1] ":::\n::::"
```
