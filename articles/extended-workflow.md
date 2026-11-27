# Extended workflow

This is a complete example you can copy into an R script or Quarto
document and run. It uses a Word document with an image, a table, a
citation and four placeholders, and shows a child Quarto file, a chunk,
an inline value and a plain value side by side.

If you haven’t already, read
[`vignette("knittogether")`](https://wyuill.github.io/knittogether/articles/knittogether.md)
first. It explains the terms used here and how to work back and forth
with Word.

## Example files

Normally your colleague would give you the Word document. So the example
can run anywhere, the code below creates one, along with an image, a
bibliography and a child Quarto file. Everything goes into a temporary
folder, which is why the paths below are wrapped in
`file.path(temp_dir, ...)`. You won’t need that in your own work.

> **Code to create the example files**
>
> `create_base_files()` can also make a PowerPoint version with
> `output = "pptx"`. That needs Pandoc 3.8.3 or later.
>
> Code
>
> ``` r
>
> library(pandoc)
> library(withr)
> # Use a temporary working directory for this vignette
> temp_dir <- file.path(tempdir(), "knittogether_vignette_workflow")
> dir.create(temp_dir, showWarnings = FALSE, recursive = TRUE)
>
> # Recreates the starting files, so the example can be run again from scratch
> create_base_files <- function(output = "docx", child_qmd = TRUE, image = TRUE, bib = TRUE, render = TRUE) {
>
>   if (child_qmd) {
>   child_qmd <- paste(
>     "## Content from a child qmd",
>     "",
>     "```{r}",
>     "plot(1, 1)",
>     "```",
>     "",
>     "The addition of 1 and 1 is `r 1+1`.",
>     "",
>     sep = "\n")
>
>   writeLines(child_qmd, file.path(temp_dir, "child_example.qmd"))
>   }
>
>   if (image) {
>   png(file.path(temp_dir, "image.png"), width = 600, height = 400)
>   x <- 1:10
>   plot(x, x^2, type = "b", col = "blue", pch = 19,
>        main = "Example Image Created in R", xlab = "X values", ylab = "Y values (squared)")
>   dev.off()
>   }
>
>   if (bib) {
>   bib <- ("@book{roseRosesStrategyPreventive2008,
>           title = {Rose's {{Strategy}} of {{Preventive Medicine}}},
>           author = {Rose, Geoffrey},
>           year = 2008,
>           month = jan,
>           publisher = {OUP Oxford},
>           abstract = {},
>           isbn = {978-0-19-101559-5}
>           }"
>           )
>
>     writeLines(bib, file.path(temp_dir, "example.bib"))
>   }
>
>   if (output == "docx") {
>   example_qmd <- r"(
> ---
> title: "Example Word Document"
> subtitle: "This document is used as a knittogether example"
> format: docx
> ---
>
> # Introduction
>
> Lorem ipsum dolor sit amet.[@roseRosesStrategyPreventive2008]
>
> ![Fig 1. A plot](image.png){fig-alt="A image"}
>
> ## More info
>
>   -   Lorem ipsum dolor sit amet consectetur adipiscing elit.
>   -   Quisque faucibus ex sapien vitae pellentesque sem placerat.
>   -   Tempus leo eu aenean sed diam urna tempor.
>
> # Main content
>
> Lorem ipsum dolor sit amet consectetur adipiscing elit. placeholder_total.
>
>   1.  Quisque faucibus ex sapien vitae pellentesque sem placerat.
>       1.  In id cursus mi pretium tellus duis convallis.
>   2.  Tempus leo eu aenean sed diam urna tempor.
>
> | Col1 | Col2 | Col3 |
> |------|------|------|
> | A    | 1    | 4    |
> | B    | 2    | 5    |
> | C    | 3    | 6    |
>
> : Table 1. This is a table
>
> Lorem ipsum dolor sit amet consectetur adipiscing elit.
>
> placeholder_childqmd
>
> Lorem ipsum dolor sit amet consectetur adipiscing elit.
>
> placeholder_1x1plot
>
> Lorem ipsum dolor sit amet consectetur adipiscing elit.
>
> The number of rows in the data set is placeholder_mtcarsrows.
> )"
>
>   writeLines(example_qmd, file.path(temp_dir, "example.qmd"))
>
>   if (render) {
>     pandoc::pandoc_run(c(file.path(temp_dir, "example.qmd"), "-f",
>                          "markdown", "-o", file.path(temp_dir, "example.docx")))
>     }
>   } else if (output == "pptx") {
>     example_qmd <- r"(
> ---
> title: "Example PowerPoint Presentation"
> subtitle: "This presentation is used as a knittogether example"
> format: pptx
> ---
>
> # Introduction
>
> ## Background
>
> Lorem ipsum dolor sit amet.
>
> # Main Content
>
> ## Dinner
>
>   -   Lorem ipsum dolor sit amet consectetur adipiscing elit.
>   -   Quisque faucibus ex sapien vitae pellentesque sem placerat.
>   -   Tempus leo eu aenean sed diam urna tempor.
>
> Lorem ipsum dolor sit amet consectetur adipiscing elit. placeholder_total.
>
>   1.  Quisque faucibus ex sapien vitae pellentesque sem placerat.
>       1.  In id cursus mi pretium tellus duis convallis.
>   2.  Tempus leo eu aenean sed diam urna tempor.
>
> ## A plot
>
> placeholder_1x1plot
>
> )"
>
>   writeLines(example_qmd, file.path(temp_dir, "example.qmd"))
>
>     if (render) {
>       pandoc::pandoc_run(c(file.path(temp_dir, "example.qmd"), "-f",
>                            "markdown", "-o", file.path(temp_dir, "example.pptx")))
>       }
>   }
> }
>
> create_base_files(output = "docx")
> ```

## Convert

Turn the Word document into Markdown. The image goes into a `media/`
folder inside `media_base_dir`.

``` r

knittogether::convert_markdown(
  input_file = file.path(temp_dir, "example.docx"),
  markdown_file = file.path(temp_dir, "example.md"),
  media_base_dir = file.path(temp_dir, "workflow")
)
```

This document is simple, so the default settings are fine. Tables with
long text or line breaks inside cells may convert better as
GitHub-flavoured Markdown, which you can ask for with
`pandoc_args = "-t gfm"`. For full control over Pandoc, call
[`pandoc::pandoc_run()`](https://cderv.github.io/pandoc/reference/pandoc_run.html)
yourself. Other Markdown flavours can leave extra escaping behind, which
[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)
then needs to tidy up.

## Clean

``` r

knittogether::clean_markdown(
  markdown_file = file.path(temp_dir, "example.md"),
  placeholder_prefix = "placeholder_",
  heading_offset = TRUE,
  clean_citations = TRUE
)
```

`heading_offset = TRUE` moves each heading down a level, so the Word
“Heading 1” sections don’t compete with the page title in HTML.
`clean_citations = TRUE` removes the extra `\` that Pandoc puts in front
of citation brackets.

## Define the content

There are four placeholders in the document, each filled in a different
way:

``` r

# A chunk that comes from a separate Quarto file
child <- knittogether::define_content(
  description = "A plot in a child qmd",
  placeholder_id = "childqmd",
  output_mode = "chunk",
  content = "{{< include child_example.qmd >}}",
  content_type = "plot",
  chunk_options = list(engine = "r", as_child = TRUE,
                       child_dir = "children", echo = FALSE, fig.width = 7))

# A chunk written here
plot <- knittogether::define_content(
  description = "A plot",
  placeholder_id = "1x1plot",
  output_mode = "chunk",
  content = { plot(1, 1) },
  content_type = "plot",
  chunk_options = list(echo = FALSE, warning = FALSE, message = FALSE, fig.width = 7))

# An inline value, worked out when the document renders
inline <- knittogether::define_content(
  description = "Number of rows in mtcars",
  placeholder_id = "mtcarsrows",
  output_mode = "inline",
  content = { nrow(mtcars) },
  content_type = "text")

map <- knittogether::placeholder_map(
  specs = list(child, plot, inline),
  scalars = list(total = 42)
)
```

`total` is a scalar: a plain value passed straight to
[`placeholder_map()`](https://wyuill.github.io/knittogether/reference/placeholder_map.md).
Scalars are quick, but they can only go inline and they don’t carry a
description, so the validation log tells you less about them.

`as_child = TRUE` writes the chunk to its own file in `children/` and
includes that file, instead of putting the chunk in the main Markdown.
Child files run in the same session as the main document, so any data
they use must already be loaded. If several child files need the same
data, give each one an include of a shared data script, such as
`{{< include data_processing.qmd >}}`.

## Fill the placeholders

This example goes straight to the final version, so draft mode and
markers are off. For a draft you’ll send back to Word, leave both at
their defaults. See “Going back and forth with Word” in
[`vignette("knittogether")`](https://wyuill.github.io/knittogether/articles/knittogether.md).

``` r

knittogether::replace_placeholders(
  markdown_file = file.path(temp_dir, "example.md"),
  placeholder_prefix = "placeholder_",
  validation_path = file.path(temp_dir, "validation"),
  code_content = map,
  draft_mode = FALSE,
  marker_mode = "off"
)
```

The end of the Markdown now looks like this:

```` markdown
Lorem ipsum dolor sit amet consectetur adipiscing elit.

{{< include children/child_childqmd.qmd >}}

Lorem ipsum dolor sit amet consectetur adipiscing elit.

```{r 1x1plot, echo=FALSE, warning=FALSE, message=FALSE, fig.width=7}
{
    plot(1, 1)
}
```

Lorem ipsum dolor sit amet consectetur adipiscing elit.

The number of rows in the data set is `r { nrow(mtcars) }`.
````

## Check the output

Because `validation_path` was set, the `validation/` folder now has a
CSV log listing each placeholder, whether it was found, what it was
filled with, and whether that changed since the last run. If the
`quarto` and `reactable` packages are installed there’s also an HTML
version you can search and sort.

## Render

Include the Markdown in a Quarto document and render it to whatever
format you need:

``` markdown
---
format: docx
bibliography: example.bib
---

{{< include example.md >}}
```

The Quarto document must be in the same folder as `example.md`, so the
include and the child file paths work.

## Long documents

A long report can work better as several web pages.
[`split_markdown()`](https://wyuill.github.io/knittogether/reference/split_markdown.md)
splits the Markdown at each top-level heading and writes each section to
its own folder, ready for [Quarto side
navigation](https://quarto.org/docs/websites/website-navigation.html#side-navigation):

``` r

knittogether::split_markdown(file.path(temp_dir, "example.md"), qmd = "separate")
```

If you’d rather keep one Markdown file, the
[quarto-external](https://github.com/mcanouil/quarto-external) extension
can pull a single section into a page with
`{{< external example.md#section >}}`.
