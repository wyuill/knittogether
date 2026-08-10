# Check if output is PPTX

Utility functions to detect the current knitr output format. `is_html`
checks whether the output is HTML. `is_pdf` checks whether the output is
PDF. `is_docx` checks whether the output is DOCX. `is_pptx` checks
whether the output is PPTX.

## Usage

``` r
is_pptx()

is_docx()

is_pdf()

is_html()
```

## Value

TRUE if knitr is outputting the relevant file type.
