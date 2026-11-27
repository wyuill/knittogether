# Write a child .qmd file to disk

Called by replace_placeholders() when a chunk uses `as_child = TRUE`.

## Usage

``` r
.write_child_qmd(
  parent_md_path,
  slug,
  expr,
  chunk_options = list(),
  child_dir = NULL,
  overwrite = TRUE
)
```
