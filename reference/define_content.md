# Describe the content for one placeholder

Says what should replace a placeholder and how it goes in. The code in
`content` isn't run now: it's written into the Markdown by
[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
and runs when Quarto renders the document. Collect the results with
[`placeholder_map()`](https://wyuill.github.io/knittogether/reference/placeholder_map.md).

## Usage

``` r
define_content(
  description = NULL,
  placeholder_id,
  output_mode = c("inline", "chunk", "asis"),
  content,
  content_type = NULL,
  chunk_options = list()
)
```

## Arguments

- description:

  Optional. A short description of the content, shown in the validation
  log to help you check the right output is in the right place.

- placeholder_id:

  The part of the placeholder after the prefix. With the default prefix
  `"placeholder_"`, the ID `"plot"` fills `placeholder_plot`.

- output_mode:

  How the content goes in:

  - `"inline"` writes inline R code, `` `r <content>` ``, for a value
    inside a sentence.

  - `"chunk"` writes a code chunk on its own line, for plots, tables or
    anything longer. The chunk is R unless you set
    `chunk_options$engine`.

  - `"asis"` writes text exactly as given. If `content` is a string it's
    inserted as it is; otherwise the code itself is inserted as text,
    not its result.

- content:

  The code to insert, for example `{ plot(mtcars$wt, mtcars$mpg) }` or
  `nrow(mtcars)`. It can also be passed in from a function or with `!!`,
  for example inside [`lapply()`](https://rdrr.io/r/base/lapply.html).

- content_type:

  Optional. A label such as `"plot"`, `"table"` or `"qmd"`, shown in the
  validation log.

- chunk_options:

  A named list of chunk options, used when `output_mode = "chunk"`. Any
  knitr option works, such as `echo = FALSE` or `fig.width = 7`. Three
  more control how the chunk is written:

  - `engine`: the chunk language. Defaults to `"r"`.

  - `as_child`: if `TRUE`, write the chunk to its own file,
    `child_<id>.qmd`, and include that file instead.

  - `child_dir`: the folder for child files, relative to the Markdown
    file.

## Value

A `content_spec` object, to pass to
[`placeholder_map()`](https://wyuill.github.io/knittogether/reference/placeholder_map.md).

## See also

Other content:
[`placeholder_map()`](https://wyuill.github.io/knittogether/reference/placeholder_map.md)

## Examples

``` r
plot <- define_content(
  placeholder_id = "plot",
  description = "Car weight against fuel economy",
  output_mode = "chunk",
  content = { plot(mtcars$wt, mtcars$mpg) },
  chunk_options = list(echo = FALSE, fig.width = 7)
)

total <- define_content(
  placeholder_id = "total",
  output_mode = "inline",
  content = nrow(mtcars)
)
```
