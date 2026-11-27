# Insert a Slide Break After a Character Limit

Inserts a slide break at the closest clean boundary before `limit`.

## Usage

``` r
insert_slide_break(
  text,
  limit = 800,
  break_fun = slide_break,
  slide_levels = c(1, 2)
)
```

## Arguments

- text:

  A character string.

- limit:

  Character width before attempting a break.

- break_fun:

  Function returning the slide break marker.

- slide_levels:

  Integer vector of header levels that automatically start new slides
  (default: c(1, 2)).

## Value

Modified text with a slide break inserted.

## Details

Break priority order:

1.  Non-slide header levels (e.g., 3–6)

2.  Sentence boundary

3.  Paragraph break

4.  Word boundary

5.  Hard cut at `limit`
