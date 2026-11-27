# Text of a chunk body, with a top-level `{ }` block unwrapped

knitr prints only the last value of a `{ ... }` block, so each statement
is written on its own line instead.

## Usage

``` r
.chunk_body(expr)
```
