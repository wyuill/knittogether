# Find the newest Word or PowerPoint file in a folder

Returns the path to the newest `.docx` or `.pptx` file in `dir`, so a
workflow can pick up the latest version a writer has saved. Lock files
Word creates while a document is open (names starting with `~$`) are
ignored.

## Usage

``` r
latest_word_file(dir = ".", base_name = NULL, ext = c("docx", "pptx"))
```

## Arguments

- dir:

  Folder to search. Defaults to the working directory.

- base_name:

  Optional. Only files whose name starts with this text are considered,
  for example `"report"` matches `report.docx` and `report_1031.docx`.

- ext:

  File extensions to consider. Defaults to `c("docx", "pptx")`.

## Value

The path to the newest matching file, as a character string. Errors if
no file matches.

## See also

Other versions:
[`timestamped_path()`](https://wyuill.github.io/knittogether/reference/timestamped_path.md)

## Examples

``` r
if (FALSE) { # \dontrun{
input <- latest_word_file("drafts", base_name = "report")
convert_markdown(input, markdown_file = "report.md")
} # }
```
