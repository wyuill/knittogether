# This function is a wrapper for the full knittogether workflow

This function calls the
[`convert()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/convert.md),
[`clean()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/clean.md),
and
[`replace()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace.md)
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
[`convert()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/convert.md),
[`replace()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace.md),
and
[`clean()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/clean.md).
Arguments not recognised by any function will be ignored. Defaults for
all parameters are taken from the underlying functions.

## See also

[`convert()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/convert.md),
[`replace()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace.md),
[`clean()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/clean.md)
