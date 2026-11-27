# Working with PowerPoint

The workflow itself does not require much adjustment to work with
PowerPoint, though `clean_markdown(pptx_section_offset = TRUE)` is often
useful to adjust header levels when Section Header slides are used. A
number of specific helper functions can also help.

Quarto-produced PowerPoint presentations often require different styling
and formatting than other output types. knittogether has a set of
functions to make these easier to apply, typically with checks to ensure
these styles do not apply to HTML outputs. These functions are simplest
to use in Quarto-generated content but can be inserted into content
imported from markdown if desired.

### Slide templates

A limited number of [slide
layouts](https://pandoc.org/demo/example33/10.1-structuring-the-slide-show.html)
are supported by Pandoc. It is advisable to create a master slide
template limited to these layouts, with useful features such as slide
numbers and styling applied to elements such as text.

### Backgrounds

The function
[`pptx_section_slide()`](https://wyuill.github.io/knittogether/reference/pptx_section_slide.md)
allows for background images to be added to slides. These images need to
be provided in the right dimensions.

### Columns

The functions
[`pptx_col_start()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md),
[`pptx_col_break()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md),
and
[`pptx_col_end()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md)
allow easy addition of columns.

### Starting a new slide

By default, level 1 (`#`) and level 2 (`##`) headings create a new
slide, with all subsequent content placed on that slide. This can
produce content that exceeds slide size and, unlike HTML slide formats,
there is currently no practical way to resize text except by globally
reducing text size in the master template. It can therefore be useful to
add slide breaks throughout the text. This can be done manually with
[`slide_break()`](https://wyuill.github.io/knittogether/reference/slide_break.md)
and automatically on a string with
[`auto_slide_break()`](https://wyuill.github.io/knittogether/reference/auto_slide_break.md).
In Quarto-generated documents, these are straightforward to apply,
though some trial and error may be needed to ensure content fits slides.
If exact locations are required within Word/markdown documents, breaks
can be added manually in markdown (with reproducibility trade-offs),
added programmatically (e.g., matching text or at specific line
numbers), or with inline code such as
`` `r knittogether::slide_break()` `` at the relevant location.

### Citations

There is no Zotero support for PowerPoint. Therefore it can often be
easier to create them in R. If citations are done in PowerPoint they
must be done so manually by creating a library in Zotero, adding the
references and then copying the Citation Key for each reference into the
PowerPoint, prefixing it with `[@` and suffixing it with `]` so that it
aligns with the pandoc syntax outlined in
[`vignette("citations")`](https://wyuill.github.io/knittogether/articles/citations.md)
and matches the bibliography. These references will be read into
markdown and subsequent qmd outputs.
