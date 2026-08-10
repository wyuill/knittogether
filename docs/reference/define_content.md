# Define a content specification for insertion into a document

`define_content()` creates a structured object describing how a piece of
content should be inserted into a Markdown/Quarto document. The
`content` is captured as an **unevaluated expression** and later
rendered by downstream tooling (e.g., knitr/Quarto).

## Usage

``` r
define_content(
  description,
  placeholder_id,
  output_mode = c("inline", "chunk", "asis"),
  content,
  content_type,
  chunk_options = list()
)
```

## Arguments

- description:

  An optional label describing the content for ease of validating the
  content is in the correct place.

- placeholder_id:

  A slug identifying the placeholder (e.g., `"plot1"`). The full
  placeholder matched in the Markdown file will be
  `paste0(placeholder_prefix, "_", placeholder_id)`.

- output_mode:

  One of:

  - `"inline"` – insert a knitr inline expression using the R engine
    `` `r <expr>` ``.

  - `"chunk"` – insert a fenced code block. Chunk language defaults to R
    but can be overridden via `chunk_options$engine`.

  - `"asis"` – insert literal text. If `content` is a character literal,
    it is inserted as-is; otherwise the expression is deparsed to text
    and inserted.

- content:

  A quoted or unquoted R expression (captured, not executed). For
  `"inline"` and `"chunk"`, this expression is emitted for knitr/Quarto
  to evaluate. For when `output_mode` is set to `"asis"`, `content` is
  inserted directly; otherwise, the expression is deparsed to text.

- content_type:

  An optional human-readable type (e.g., `"plot"`, `"table"`, `"qmd"`)
  used for ease of validation.

- chunk_options:

  Named list of chunk options when `output_mode = "chunk"`.

  - `engine` (default `"r"`) to select language.

  - `as_child = TRUE` to write a child `.qmd` and include it with
    `{{< include child_<slug>.qmd >}}` instead of inlining the chunk.

  - `child_dir` optional subdirectory to store child files relative to
    the parent markdown file.

  - Any other knitr options, e.g. `echo = FALSE`, `fig.width = 7`.

## Value

A `"content_spec"` object.

## Examples

``` r
if (FALSE) { # \dontrun{
spec <- define_content(
  description     = "A plot of mtcars",
  placeholder_id  = "mtcarsplot",
  output_mode     = "chunk",
  content         = { plot(mtcars$wt, mtcars$mpg) },
  content_type    = "plot",
  chunk_options   = list(echo = FALSE, fig.width = 7)
)
} # }
```
