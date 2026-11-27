# Break text into a new slide once, before a character limit

If `text` is longer than `limit` characters, adds one slide break at the
best place before the limit. It looks, in order, for a heading that
doesn't start a slide by itself (level 3 to 6 by default), the end of a
sentence, a paragraph break or a space, and cuts at `limit` only if it
finds none. A heading at the very start of `text` is ignored.
[`auto_slide_break()`](https://wyuill.github.io/knittogether/reference/auto_slide_break.md)
repeats this until the whole text fits.

## Usage

``` r
insert_slide_break(
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

`text`, with a slide break added if it was longer than `limit`.

## See also

Other PowerPoint:
[`add_pptx_backgrounds_to_headers()`](https://wyuill.github.io/knittogether/reference/add_pptx_backgrounds_to_headers.md),
[`auto_slide_break()`](https://wyuill.github.io/knittogether/reference/auto_slide_break.md),
[`pptx_col_start()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md),
[`pptx_section_slide()`](https://wyuill.github.io/knittogether/reference/pptx_section_slide.md),
[`slide_break()`](https://wyuill.github.io/knittogether/reference/slide_break.md)

## Examples

``` r
text <- paste(rep("A sentence of text.", 60), collapse = " ")
insert_slide_break(text, limit = 200, break_fun = function() "---")
#> [1] "A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. \n\n---\n\nA sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text. A sentence of text."
```
