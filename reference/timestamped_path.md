# Add the date and time to a file name

Adds the current time to a file name, for example `report.docx` becomes
`report_20261127_093015.docx`, so each output is kept and the input is
never overwritten. If a file with that name already exists (for example
two outputs made in the same second), a counter is added:
`report_20261127_093015_2.docx`.

## Usage

``` r
timestamped_path(path, time = Sys.time(), format = "%Y%m%d_%H%M%S")
```

## Arguments

- path:

  Path to the file the name is based on. Only its folder, base name and
  extension are used.

- time:

  The time to stamp. Defaults to now.

- format:

  A [`strftime()`](https://rdrr.io/r/base/strptime.html) format for the
  stamp. Defaults to `"%Y%m%d_%H%M%S"`.

## Value

A path that does not yet exist.

## See also

Other versions:
[`latest_word_file()`](https://wyuill.github.io/knittogether/reference/latest_word_file.md)

## Examples

``` r
if (FALSE) { # \dontrun{
out <- timestamped_path("output/report.docx")
} # }
```
