# Break text into slides that fit

Adds slide breaks to `text` until no stretch between breaks is longer
than `limit` characters, using
[`insert_slide_break()`](https://wyuill.github.io/knittogether/reference/insert_slide_break.md)
to choose each break.

## Usage

``` r
auto_slide_break(
  text,
  limit = 800,
  break_fun = slide_break,
  slide_levels = c(1, 2)
)
```

## Arguments

- text:

  A single string of Markdown.

- limit:

  Maximum number of characters before a break. Defaults to 800.

- break_fun:

  A function that returns the slide break. Defaults to
  [`slide_break()`](https://wyuill.github.io/knittogether/reference/slide_break.md).

- slide_levels:

  Heading levels that already start a new slide. Defaults to `c(1, 2)`.

## Value

`text`, with slide breaks added.

## See also

Other PowerPoint:
[`add_pptx_backgrounds_to_headers()`](https://wyuill.github.io/knittogether/reference/add_pptx_backgrounds_to_headers.md),
[`insert_slide_break()`](https://wyuill.github.io/knittogether/reference/insert_slide_break.md),
[`pptx_col_start()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md),
[`pptx_section_slide()`](https://wyuill.github.io/knittogether/reference/pptx_section_slide.md),
[`slide_break()`](https://wyuill.github.io/knittogether/reference/slide_break.md)

## Examples

``` r
text <- paste(rep("A sentence of text.", 100), collapse = " ")
auto_slide_break(text, limit = 400, break_fun = function() "---")
#> [1] "A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. \n\n---\n\nA sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. \n\n---\n\nA sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. \n\n---\n\nA sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. \n\n---\n\nA sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text."
```
