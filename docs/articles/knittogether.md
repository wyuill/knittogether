# Getting started with knittogether

knittogether lets you work seamlessly with colleagues who write in Word
or PowerPoint, while you keep analytic content reproducible in R and
Quarto.

The core idea is:

- Your colleagues write content in **Office** (Word/PPT)
- You add **placeholders** where R-generated content should go
- knittogether converts the document → markdown
- You **replace** placeholders with R output (plots, tables, inline
  values)
- You knit back to **Word, PPT, PDF, HTML**, or any Quarto format
- If needed, the resulting Office document can be edited again and
  re-imported

A typical workflow looks like this:

Office (docx/pptx)

↓ convert Markdown + media/ folder

↓ clean Markdown (structured + tidy)

↓ replace Markdown (with R output inserted)

↓ render Quarto output (pptx, docx, html, pdf)

↓ optional Edit in Office

→ repeat

## A minimal example

Suppose your colleague gives you a **Word document** with text and the
following placeholders: `placeholder_content_plot`, which should contain
a plot of your data, and `placeholder_content_total_rows`, which should
give a count of the number of rows in your data.

### 1. Convert Word to markdown

First we `[convert_markdown()]` the docx file into a markdown file,
extracting the contents and structure as well as images, tables, and
citations.

``` r

knittogether::convert_markdown(
  input_file    = "input.docx",
  markdown_file = "report.md",
  media_base_dir = "media"
)
```

### 2. Clean the markdown

Next we
[`clean_markdown()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/clean_markdown.md)
the resulting markdown so that it will be processed correctly by Quarto.

``` r

clean_markdown(
  markdown_file   = "report.md",
  heading_offset  = TRUE,
  clean_citations = TRUE
)
```

### 3. Create R-generated content

We then define the content
([`define_content()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/define_content.md))
we want to replace the placeholders with and map it to the placeholders
([`placeholder_map()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/placeholder_map.md))
so we know what code matches what placeholder.

``` r

plot <- define_content(
  description    = "A scatterplot",
  placeholder_id = "plot",
  output_mode    = "chunk",
  content        = { plot(iris$Sepal.Length, iris$Sepal.Width) },
  content_type   = "plot",
  chunk_options  = list(echo = FALSE, fig.width = 6)
)

rows <- define_content(
  description    = "Number of rows in mtcars",
  placeholder_id = "total_rows",
  output_mode    = "inline",
  content        = { nrow(mtcars) },
  content_type   = "text"
)

content_map <- placeholder_map(specs = list(plot, rows))
```

### 4. Replace placeholders with real content

Next we
[`replace_placeholders()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/replace_placeholders.md)
the placeholders with this content and, optionally, validate the content
is correct.

``` r

replace_placeholders(
  markdown_file      = "report.md",
  code_content       = content_map,
  placeholder_prefix = "placeholder_content",
  validation_path    = "validation"
)
```

If desired the markdown string can be passed to
[`accessibility_scan()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/accessibility_scan.md)
to check whether alt text or captions are present for all images and
tables.

### 5. Render the Quarto document

Finally, we can render the resulting file into whatever format we want
to output from Quarto. In your .qmd (e.g., report.qmd), include: {{{ \<
include report.md \> }}} and then render with
`quarto::quarto_render("report.qmd")`. Or, `[replace_placeholders()]`
invisibly returns the contents of the markdown so it can be inserted
directly into a Quarto file.

If you don’t want to run each step individually you can use
[`run_workflow()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/run_workflow.md)
to run them all at once. Each step reads the output of the step before
it. Pass a folder as `input_file` to use its newest Word file,
optionally narrowed with `base_name`. See the Working with versions
section of the README for keeping earlier versions.

A fuller, ready-to-run example is provided in
[`vignette("extended-workflow")`](https://sturdy-giggle-wwjo5pk.pages.github.io/articles/extended-workflow.md).
Other vignettes provide guidance on working with PowerPoint, citations,
and setting up Office document styling.

## Concepts

Understanding a few core ideas helps make sense of the workflow.

### Placeholders

Placeholders are unique strings in Word or PowerPoint that indicate
where R-generated content should go. For example
`placeholder_content_plot`.

They have two parts:

- **prefix:** This is shared across all placeholders and identifies that
  it is to be replaced (e.g., `"placeholder_content"`)
- **identifier:** This tells knittogether which content to replace it
  with (`"plot"`)

Placeholders must use a shared prefix and should be unlikely to appear
accidentally. They do not have to be unique if the same content is
needed in multiple places.

### Defining and mapping content

[`define_content()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/define_content.md)
tells knittogether what to insert and how to insert it. Content can
either be a single scalar (e.g. a number or string) which are inserted
inline or a chunk (e.g. a plot, table, child Quarto document, or code
block) which are inserted on a new line.

[`placeholder_map()`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/placeholder_map.md)
combines all content definitions into a single object ready to replace
the placeholders in the document.

When defining large or complex content it is advisable to use functions
or ‘child’ documents and using the
[includes](https://quarto.org/docs/authoring/includes.html) feature of
Quarto. Important considerations for doing this are:

- Keeping parent .qmd, child files, and markdown output in the same
  directory to avoid filepath issues when rendering.
- Avoiding YAML in the child files where it may conflict with the parent
  document (e.g., `format`).
- Ensuring data required by children or functions is available in the
  environment they are rendered in.

These can be added to the content argument of `[define_content()]` as
`content= "{{< include child_plot.qmd >}}"`.

## Working Iteratively

You may find yourself going back and forth between Quarto and
Word/PowerPoint. To make this easier you can use use draft mode to show
the output of the code while keeping the placeholders.

``` r

replace_placeholders(
  markdown_file    = "report.md",
  code_content     = content_map,
  draft_mode       = TRUE,
  draft_mode_prefix = "DRAFT_CONTENT_START",
  draft_mode_suffix = "DRAFT_CONTENT_END",
  marker_mode      = "hidden"
)
```

In Word, placeholders can be configured to a “hidden” character style
can be shown/hidden using ¶ to aid readability as shown in
[`vignette("office-styling")`](https://sturdy-giggle-wwjo5pk.pages.github.io/articles/office-styling.md).
