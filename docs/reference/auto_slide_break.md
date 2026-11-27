# Automatically Insert Slide Breaks (Header-Aware)

Applies
[`insert_slide_break`](https://wyuill.github.io/knittogether/reference/insert_slide_break.md)
repeatedly respecting header rules until no more breaks can be inserted.

## Usage

``` r
auto_slide_break(
  text,
  limit = 800,
  break_fun = slide_break,
  slide_levels = c(1, 2)
)
```

## Arguments

- text:

  Text to segment.

- limit:

  Character target for each segment.

- break_fun:

  Slide break generator.

- slide_levels:

  Which header levels automatically create slides.

## Value

Text with slide breaks inserted.
