# Working with PowerPoint

PowerPoint works much like Word. You convert, clean and fill
placeholders in the same way (see
[`vignette("knittogether")`](https://wyuill.github.io/knittogether/articles/knittogether.md)).
This article covers the differences, and the helpers knittogether
provides for slides.

Most of these helpers check the output format, so the same Quarto
document can still render to HTML. They’re easiest to use in a document
you write in Quarto, but you can also add them to Markdown converted
from Office.

## Converting slides

Reading `.pptx` files needs Pandoc 3.8.3 or later. If you use Section
Header slides, clean the Markdown with `pptx_section_offset = TRUE`:

``` r

clean_markdown("slides.md", pptx_section_offset = TRUE)
```

That keeps the section titles as top-level headings and moves each
slide’s heading down a level beneath its section.

## Slide templates

Quarto takes the look of your slides from a template, set with
`reference-doc` like a Word reference document. Pandoc only supports [a
few slide
layouts](https://pandoc.org/MANUAL.html#powerpoint-layout-choice), so
build a master deck with just those layouts. Put slide numbers, logos
and text styles in the master rather than on individual slides.

``` yaml
format:
  pptx:
    reference-doc: template.pptx
```

## Background images

[`pptx_section_slide()`](https://wyuill.github.io/knittogether/reference/pptx_section_slide.md)
writes a heading with a background image when the output is PowerPoint,
and a plain heading otherwise. It looks in `bg_dir` for an image named
after the heading level (`level1.png` or `1.png`) or the name you give
in `bg`. Make the image the same size as your slides.

``` r

pptx_section_slide(level = 1, title = "Results", bg = "blue", bg_dir = "backgrounds")
```

To add a background to every heading of a level in some existing
Markdown, use
[`add_pptx_backgrounds_to_headers()`](https://wyuill.github.io/knittogether/reference/add_pptx_backgrounds_to_headers.md).

## Columns

Put
[`pptx_col_start()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md),
[`pptx_col_break()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md)
and
[`pptx_col_end()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md)
around content to split a slide into two columns. `width` is each
column’s share of the slide, in per cent. In a Quarto document:

```` markdown
`r knittogether::pptx_col_start(width = 40)`

```{r}
plot(mtcars$wt, mtcars$mpg)
```

`r knittogether::pptx_col_break(width = 60)`

```{r}
head(mtcars)
```

`r knittogether::pptx_col_end()`
````

In HTML output the columns are left out and the content runs down the
page as normal.

## Slide breaks

Every level 1 (`#`) and level 2 (`##`) heading starts a new slide, and
everything up to the next heading goes on that slide. Unlike HTML
slides, PowerPoint won’t shrink text to fit. The only way to make text
smaller is to change the template, which affects every slide. Long
sections need breaking up.

- [`slide_break()`](https://wyuill.github.io/knittogether/reference/slide_break.md)
  adds a break where you put it. In converted Markdown you can type
  `` `r knittogether::slide_break()` `` at the right spot.
- [`auto_slide_break()`](https://wyuill.github.io/knittogether/reference/auto_slide_break.md)
  takes a block of text and breaks it into slides of no more than
  `limit` characters (800 by default). It breaks at a sub-heading, the
  end of a sentence or a paragraph where it can.

Both do nothing in HTML output. Expect some trial and error before
everything fits.

## Citations

Zotero’s Word plugin doesn’t work in PowerPoint, so citations there have
to be typed by hand. Add the references to a Zotero collection, copy
each one’s citation key, and type it into the slide as `[@citekey]`. If
the keys match your `.bib` file, they come through to Markdown and the
rendered output as ordinary citations. Often it’s simpler to add
citations in R instead. See
[`vignette("citations")`](https://wyuill.github.io/knittogether/articles/citations.md)
for the bibliography set-up.
