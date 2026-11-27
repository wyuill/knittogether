# This function is a wrapper for the full knittogether workflow

This function calls the
[`convert_markdown()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/convert_markdown.md),
[`clean_markdown()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/clean_markdown.md),
and
[`replace_placeholders()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace_placeholders.md)
functions to extract docx or pptx content to markdown, clean this
markdown, and then replace any placeholders with code generated content,
simplifying using the workflow.

## Usage

``` r
run_workflow(..., base_name = NULL)
```

## Arguments

- ...:

  Additional arguments passed to the underlying functions

- base_name:

  Optional. When `input_file` is a folder, only files whose names start
  with this text are considered.

## Value

Invisibly returns the updated Markdown (character vector).

## Details

The wrapper determines which arguments belong to which function by
matching argument names against the formal arguments of
[`convert_markdown()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/convert_markdown.md),
[`replace_placeholders()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace_placeholders.md),
and
[`clean_markdown()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/clean_markdown.md).
Arguments not recognised by any function will be ignored. Defaults for
all parameters are taken from the underlying functions.

Each step takes the previous step's output as its input. The markdown
written by
[`convert_markdown()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/convert_markdown.md)
is cleaned, and the file
[`clean_markdown()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/clean_markdown.md)
writes (its `output_file`, if one is given) is the file filled in by
[`replace_placeholders()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace_placeholders.md).
So `output_file` in `clean_markdown` is used, not ignored.

If `input_file` is a folder, the newest Word or PowerPoint file in it is
used, optionally restricted to names that start with `base_name` (see
[`latest_word_file()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/latest_word_file.md)).

## See also

[`convert_markdown()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/convert_markdown.md),
[`replace_placeholders()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace_placeholders.md),
[`clean_markdown()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/clean_markdown.md),
[`latest_word_file()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/latest_word_file.md)
