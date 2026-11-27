# Create a list of Placeholders with their Content for [`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)

Constructs a named list for use in
[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
by:

- extracting slugs from each `content_spec` in `specs`;

- using names of scalar values from `scalars`.

## Usage

``` r
placeholder_map(specs = list(), scalars = list())
```

## Arguments

- specs:

  A list of `content_spec` objects (unnamed).

- scalars:

  A named list of scalar values. Names become slugs.

## Value

A named list mapping slugs to scalars or `content_spec`s.

## Examples

``` r
if (FALSE) { # \dontrun{
spec1 <- define_content("A plot", "plot1", "chunk", { plot(1:10) }, "plot")
spec2 <- define_content("A table", "table1", "asis", mtcars[1:5, 1:5], "table")
map <- placeholder_map(specs = list(spec1, spec2), scalars = list(version = "0.1.0"))
} # }
```
