# CSS that hides placeholder markers in HTML

Returns a CSS rule that hides markers written with the
`PlaceholderMarker` style by
[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
(`marker_mode = "hidden"`). Add it to an HTML document's styles. In
Word, give the `PlaceholderMarker` character style the Hidden font
setting instead (see
[`vignette("office-styling")`](https://wyuill.github.io/knittogether/articles/office-styling.md)).

## Usage

``` r
hide_markers_css()
```

## Value

A CSS rule, as a string.

## See also

Other output format:
[`is_pptx()`](https://wyuill.github.io/knittogether/reference/is_html.md),
[`output_type()`](https://wyuill.github.io/knittogether/reference/output_type.md)

## Examples

``` r
hide_markers_css()
#> [1] "span[data-custom-style=\"PlaceholderMarker\"] { display: none !important; }"
```
