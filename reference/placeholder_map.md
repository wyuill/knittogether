# Collect the content for every placeholder

Combines content made with
[`define_content()`](https://wyuill.github.io/knittogether/reference/define_content.md),
and any plain values, into the list that
[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
takes as `code_content`.

## Usage

``` r
placeholder_map(specs = list(), scalars = list())
```

## Arguments

- specs:

  A list of objects made with
  [`define_content()`](https://wyuill.github.io/knittogether/reference/define_content.md).

- scalars:

  A named list of plain values, each inserted inline. The name is the
  placeholder ID, so `list(total = 42)` fills `placeholder_total`.
  Quicker than
  [`define_content()`](https://wyuill.github.io/knittogether/reference/define_content.md),
  but with no description in the validation log.

## Value

A named list, with one entry per placeholder ID.

## See also

Other content:
[`define_content()`](https://wyuill.github.io/knittogether/reference/define_content.md)

## Examples

``` r
plot <- define_content(
  placeholder_id = "plot",
  output_mode = "chunk",
  content = { plot(1:10) }
)
placeholder_map(specs = list(plot), scalars = list(version = "0.1.0"))
#> $plot
#> $description
#> NULL
#> 
#> $placeholder_id
#> [1] "plot"
#> 
#> $output_mode
#> [1] "chunk"
#> 
#> $content_expr
#> {
#>     plot(1:10)
#> }
#> 
#> $content_type
#> NULL
#> 
#> $chunk_options
#> list()
#> 
#> attr(,"class")
#> [1] "content_spec" "list"        
#> 
#> $version
#> [1] "0.1.0"
#> 
```
