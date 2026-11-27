# Convert, clean and fill a document in one call

Runs
[`convert_markdown()`](https://wyuill.github.io/knittogether/reference/convert_markdown.md),
[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)
and
[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
in turn. Each step reads the file the step before it wrote, so if you
give
[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)
an `output_file`, that's the file that gets filled.

Pass any argument the three functions take, by name, and it goes to
whichever function has it (an argument such as `placeholder_prefix` goes
to both functions that use it). Anything you leave out uses that
function's default. An argument none of them recognises, or one without
a name, is an error, so a typo is caught.

If `input_file` is a folder, the newest Word or PowerPoint file in it is
used (see
[`latest_word_file()`](https://wyuill.github.io/knittogether/reference/latest_word_file.md)).

## Usage

``` r
run_workflow(..., base_name = NULL)
```

## Arguments

- ...:

  Named arguments for
  [`convert_markdown()`](https://wyuill.github.io/knittogether/reference/convert_markdown.md),
  [`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)
  and
  [`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md).

- base_name:

  Optional. When `input_file` is a folder, only consider files whose
  names start with this text.

## Value

The filled Markdown, invisibly, as a character string.

## See also

Other workflow:
[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md),
[`convert_markdown()`](https://wyuill.github.io/knittogether/reference/convert_markdown.md),
[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)

## Examples

``` r
if (FALSE) { # \dontrun{
run_workflow(
  input_file = "drafts",
  base_name = "report",
  markdown_file = "report.md",
  placeholder_prefix = "placeholder_",
  heading_offset = TRUE,
  code_content = placeholder_map(specs = list(plot))
)
} # }
```
