# Add a Background Image to All Headers of Selected Levels in a String

Scans a Markdown/Quarto text string, finds headers, and inserts or
replaces a `background-image` attribute on all headers whose level is in
`levels`.

## Usage

``` r
add_pptx_backgrounds_to_headers(text, levels = 1, bg, bg_dir, overwrite = TRUE)
```

## Arguments

- text:

  Markdown/Quarto content as a single string.

- levels:

  Integer vector of header levels to target.

- bg:

  The name of the background image file (without extension e.g.,
  `"blue"` rather than `"blue.png"`).

- bg_dir:

  Directory where background files live.

- overwrite:

  Replace an existing `background-image` attribute?

## Value

Modified text string with updated headers.
