# Getting started with knittogether

This article follows one report from the first Word draft to the
finished output. It explains each step, then shows how to go back and
forth with a colleague who edits in Word.

## Three terms

**Placeholder.** Plain text in the Word document that marks where R
output should go, such as `placeholder_plot`. It has two parts: a prefix
that every placeholder shares (`placeholder_`) and an ID that says which
piece of content goes there (`plot`). The prefix is up to you. Set it
with `placeholder_prefix`, and it’s used exactly as you give it, so
`"xyz_"` gives `xyz_plot`. Pick one that won’t turn up by accident in
normal writing, and use the same one throughout. The same placeholder
can appear more than once if you need the same output in several places.

**Marker.** When knittogether fills a placeholder, it leaves a small
styled tag with the placeholder’s name next to the output. That’s how it
finds the output again next time. You control markers with
`marker_mode`.

**Draft block.** While the report is still a draft, each piece of R
output is wrapped between `DRAFT_CONTENT_START` and `DRAFT_CONTENT_END`.
The writer edits around these lines. When you bring the document back
in, knittogether swaps each block for its placeholder so it can be
filled again with fresh output.

## The first pass

Suppose a colleague sends you `draft.docx`. They’ve typed
`placeholder_plot` where a chart should go and `placeholder_total` where
a count of rows should go.

``` r

library(knittogether)
```

### 1. Convert

[`convert_markdown()`](https://wyuill.github.io/knittogether/reference/convert_markdown.md)
turns the Word file into Markdown. It keeps the headings, lists, tables,
footnotes and citations, and saves the images into a `media/` folder.

``` r

convert_markdown(
  input_file = "draft.docx",
  markdown_file = "draft.md",
  media_base_dir = "."
)
```

PowerPoint files work the same way. See
[`vignette("powerpoint")`](https://wyuill.github.io/knittogether/articles/powerpoint.md)
for the differences.

### 2. Clean

[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)
fixes things that Word leaves behind and Quarto doesn’t like.

``` r

clean_markdown(
  markdown_file = "draft.md",
  placeholder_prefix = "placeholder_",
  heading_offset = TRUE,
  clean_citations = TRUE
)
```

Here `heading_offset = TRUE` moves every heading down a level, because a
Word “Heading 1” would otherwise become the page title in HTML.
`clean_citations = TRUE` removes stray backslashes from citations. Pass
your `placeholder_prefix` so knittogether can tidy up any Word
formatting stuck to the placeholders.

### 3. Say what goes in each placeholder

[`define_content()`](https://wyuill.github.io/knittogether/reference/define_content.md)
describes one piece of content.
[`placeholder_map()`](https://wyuill.github.io/knittogether/reference/placeholder_map.md)
collects them all together.

``` r

plot <- define_content(
  placeholder_id = "plot",
  description = "Car weight against fuel economy",
  output_mode = "chunk",
  content = { plot(mtcars$wt, mtcars$mpg) },
  chunk_options = list(echo = FALSE, fig.width = 6)
)

total <- define_content(
  placeholder_id = "total",
  description = "Number of cars",
  output_mode = "inline",
  content = { nrow(mtcars) }
)

content <- placeholder_map(specs = list(plot, total))
```

`output_mode` decides how the content goes in:

- `"inline"` puts a value inside a sentence, as inline R code.
- `"chunk"` puts a code chunk on its own line, for plots, tables or
  anything longer.
- `"asis"` pastes in text exactly as you give it.

The code in `content` isn’t run yet. It’s written into the Markdown and
runs when Quarto renders the document.

`description` is optional but worth adding. It goes into the validation
log (see step 4), which makes it much easier to check the right output
has landed in the right place.

For a plain value that doesn’t need a description, you can skip
[`define_content()`](https://wyuill.github.io/knittogether/reference/define_content.md)
and pass it straight to the map:

``` r

content <- placeholder_map(specs = list(plot), scalars = list(total = 32))
```

For longer pieces of analysis, put the code in a separate Quarto file
and [include it](https://quarto.org/docs/authoring/includes.html), for
example `content = "{{< include child_plot.qmd >}}"`. A few things help
this go smoothly:

- Keep the main `.qmd`, the child files and the Markdown in the same
  folder, so relative paths work when you render.
- Leave the YAML header out of child files, so settings such as `format`
  don’t clash with the main document.
- Make sure any data the child file uses has been loaded before it runs.

### 4. Fill the placeholders

``` r

replace_placeholders(
  markdown_file = "draft.md",
  placeholder_prefix = "placeholder_",
  code_content = content,
  validation_path = "validation"
)
```

Each placeholder is swapped for its content. With `validation_path` set,
knittogether also writes a log of which placeholders it found and
filled, and what changed since the last run. If the `quarto` and
`reactable` packages are installed you also get an HTML page that’s
easier to browse. Smaller, more specific placeholders give you a more
useful log.

To check that every image and table has alt text or a caption, pass the
Markdown to
[`accessibility_scan()`](https://wyuill.github.io/knittogether/reference/accessibility_scan.md):

``` r

accessibility_scan(readLines("draft.md"))
```

### 5. Render

Include the Markdown in a Quarto document and render it:

``` markdown
---
title: "My report"
format: docx
---

{{< include draft.md >}}
```

Rendering to Word gives your colleague a draft with the R output in
place. You can render the same file to HTML, PDF or PowerPoint by
changing `format`.

[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
also returns the Markdown invisibly, so you can insert it into a Quarto
document directly instead of using an include.

Quarto can’t include a file that doesn’t exist yet, so the Markdown has
to be built before each render. In a Quarto project you can make this
happen automatically. Put the steps above in a script, say `build.R`,
and add this to `_quarto.yml`:

``` yaml
project:
  pre-render: Rscript build.R
```

## Going back and forth with Word

By default,
[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
runs with `draft_mode = TRUE` and `marker_mode = "hidden"`. That’s what
makes the round trip work: each piece of output sits in a draft block
with a marker naming its placeholder.

When your colleague has edited the Word draft and sent it back:

1.  **Convert the new version.** If they save new copies into a folder,
    `latest_word_file("drafts")` finds the most recent one.

2.  **Clean it with `clear_draft = TRUE`.** This turns each draft block
    back into its placeholder. Use the same `placeholder_prefix` you
    filled the draft with. If you don’t, the placeholders won’t be
    recognised and the draft content is removed with nothing to refill
    it.

    ``` r

    clean_markdown(
      markdown_file = "draft.md",
      placeholder_prefix = "placeholder_",
      clear_draft = TRUE
    )
    ```

3.  **Fill the placeholders again** with
    [`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md).
    Your output is refreshed, not duplicated, so you can update the
    analysis at the same time.

Ask your colleague to leave the `DRAFT_CONTENT_START` and
`DRAFT_CONTENT_END` lines alone. Everything around them is theirs to
edit. If those lines get in the way, you can set up a Word style that
hides them until you press ¶.
[`vignette("office-styling")`](https://wyuill.github.io/knittogether/articles/office-styling.md)
shows how, and the package includes an example document already set up
this way:

``` r

system.file("extdata", "PlaceholderMarker_example.docx", package = "knittogether")
```

## The final version

When the words are final, fill the placeholders one last time with draft
mode and markers turned off:

``` r

replace_placeholders(
  markdown_file = "draft.md",
  placeholder_prefix = "placeholder_",
  code_content = content,
  draft_mode = FALSE,
  marker_mode = "off"
)
```

You can run this straight on the latest draft: any draft blocks are
removed first. The result has no placeholder names or markers left in
it.

Only do this at the end. With `marker_mode = "off"` there’s nothing left
to show where the output came from, so a document rendered this way
can’t be brought back in and refreshed.

## Keeping earlier versions

By default each step overwrites its file. To keep a history instead,
give
[`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)
or
[`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
an `output_file`, and use
[`timestamped_path()`](https://wyuill.github.io/knittogether/reference/timestamped_path.md)
to add the date and time to the name:

``` r

replace_placeholders(
  markdown_file = "draft.md",
  placeholder_prefix = "placeholder_",
  code_content = content,
  output_file = timestamped_path("drafts/draft.md")
)
```

Set `overwrite = FALSE` if you’d rather get an error than overwrite an
existing file.

## Running every step at once

[`run_workflow()`](https://wyuill.github.io/knittogether/reference/run_workflow.md)
runs convert, clean and replace in one call. Give it any argument the
three functions take. Each step uses the previous step’s output. If you
give a folder as `input_file`, it uses the newest Word or PowerPoint
file in it, and `base_name` narrows the choice to files whose names
start with that text.

``` r

run_workflow(
  input_file = "drafts",
  base_name = "report",
  markdown_file = "report.md",
  placeholder_prefix = "placeholder_",
  heading_offset = TRUE,
  code_content = content
)
```

## Where next

- [`vignette("extended-workflow")`](https://wyuill.github.io/knittogether/articles/extended-workflow.md)
  is a complete example you can copy and run.
- [`vignette("office-styling")`](https://wyuill.github.io/knittogether/articles/office-styling.md)
  covers setting up Word files so they convert cleanly.
- [`vignette("powerpoint")`](https://wyuill.github.io/knittogether/articles/powerpoint.md)
  covers slides.
- [`vignette("citations")`](https://wyuill.github.io/knittogether/articles/citations.md)
  covers keeping Zotero references working.
