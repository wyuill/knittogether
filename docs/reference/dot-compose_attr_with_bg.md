# Compose/merge a background-image attribute (internal)

Internal utility used by header-processing functions. It takes the inner
contents of a header attribute block (e.g., `"foo='bar' size=large"`)
and either inserts or replaces a `background-image='...'` attribute.

## Usage

``` r
.compose_attr_with_bg(attr_inner, bg_path, overwrite = TRUE)
```

## Arguments

- attr_inner:

  Character string containing attributes without braces.

- bg_path:

  The background image path to insert.

- overwrite:

  Should existing `background-image` be replaced?

## Value

A character string representing the merged attribute list, without
braces.
