# Generate a quality check log for placeholder replacements (developer utility)

Internal developer-facing utility used by
[`replace_placeholders()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace_placeholders.md)
to compare current placeholder code content against the latest logged
state (CSV) and record change metadata. Optionally generates an HTML
report (Quarto + reactable) from the same CSV.

## Usage

``` r
generate_quality_check(
  code_content,
  markdown_file,
  placeholder_prefix = "placeholder_content",
  validation_path = "validation",
  log_file = "quality_log.csv",
  html_file = "validation.html"
)
```

## Arguments

- code_content:

  A named list of content specifications and scalars, typically from
  [`placeholder_map()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/placeholder_map.md).

- markdown_file:

  Path to the markdown file used to extract nearby context for
  placeholders.

- placeholder_prefix:

  Prefix used for placeholders in the markdown. Defaults to
  `"placeholder_content"`.

- validation_path:

  Directory where outputs are saved (CSV, HTML). Defaults to
  `"validation"`.

- log_file:

  CSV log file name (within `validation_path`) to be generated and to
  read (if already exists). If `NULL` the log is not generated. Defaults
  to `"quality_log.csv"`.

- html_file:

  HTML report file name (within `validation_path`) to be generated. If
  this already exists it will be overwritten. If `NULL` the report is
  not generated. Default: `"validation.html"`.

## Value

Invisibly returns the current validation data frame (including change
flags).
