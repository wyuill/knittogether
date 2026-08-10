# Accessibility Scanner for Images and Tables

Scans Markdown/HTML text for accessibility issues: • Missing or generic
alt text (images outside figures) • Missing or generic captions (images
inside figures; tables; reactable) • reactable / ggiraph widgets lacking
descriptive captions

## Usage

``` r
accessibility_scan(lines, output = NULL)
```

## Arguments

- lines:

  Character vector (one element per line), a single string containing
  newlines, or an htmltools::HTML object.

- output:

  If a path is provided, the results will be written to a csv file. If
  `NULL` results will only be returned. Defaults to `NULL`.

## Value

A data.frame with columns: kind, line, src, issue, snippet

## Details

Rules (Option A, WCAG-aligned):

- If an `&lt;img&gt;` is inside a `&lt;figure&gt;` with a
  `&lt;figcaption&gt;`, the CAPTION is the accessible name. Alt text is
  ignored. If the caption is missing or generic → FAIL.

- If an `&lt;img&gt;` is NOT inside a figure → must have descriptive alt
  → otherwise FAIL.

- Tables: need a descriptive caption (Markdown "Table:" line above, or
  HTML `&lt;caption&gt;`, or aria-label).
