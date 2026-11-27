# This function is a wrapper for the full knittogether workflow

This function calls the
[`convert()`](https://wyuill.github.io/knittogether/reference/convert.md),
[`clean()`](https://wyuill.github.io/knittogether/reference/clean.md),
and
[`replace()`](https://wyuill.github.io/knittogether/reference/replace.md)
functions to extract docx or pptx content to markdown, clean this
markdown, and then replace any placeholders with code generated content,
simplifying using the workflow.

## Usage

``` r
run_workflow(...)
```

## Arguments

- ...:

  Additional arguments passed to the underlying functions

## Value

Invisibly returns the updated Markdown (character vector).

## Details

The wrapper determines which arguments belong to which function by
matching argument names against the formal arguments of
[`convert()`](https://wyuill.github.io/knittogether/reference/convert.md),
[`replace()`](https://wyuill.github.io/knittogether/reference/replace.md),
and
[`clean()`](https://wyuill.github.io/knittogether/reference/clean.md).
Arguments not recognised by any function will be ignored. Defaults for
all parameters are taken from the underlying functions.

## See also

[`convert()`](https://wyuill.github.io/knittogether/reference/convert.md),
[`replace()`](https://wyuill.github.io/knittogether/reference/replace.md),
[`clean()`](https://wyuill.github.io/knittogether/reference/clean.md)
