# Build the knitr chunk header, e.g. `{r plot, echo=FALSE}`

Shared by inline chunks and child files. Options that control how
knittogether writes the chunk (`engine`, `as_child`, `child_dir`) are
not knitr options, so they are dropped here.

## Usage

``` r
.chunk_header(slug, chunk_options)
```
