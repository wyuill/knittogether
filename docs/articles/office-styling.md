# Office styling and layout

`knittogether` works by converting **Office documents → markdown →
Quarto → Office**.\
To keep formatting consistent throughout this round‑trip, it’s important
to structure and style your **Word** and **PowerPoint** files correctly.

This guide covers:

- How Word styles translate to markdown
- Using reference `.docx` and `.pptx` templates
- Managing captions, headings, lists, and layout
- Creating hidden placeholder styles
- Avoiding Word formatting that Pandoc cannot interpret
- Ensuring PowerPoint output respects your template
- Common pitfalls and how to avoid them

## Word Styling

Word documents are best treated as **structured**, not manually
formatted, documents. Pandoc relies heavily on Word’s built‑in styles to
produce correct markdown.

Ensure all content uses Word’s official styles such as Title Heading
1-6, Normal, List Paragraph, and Caption.

Pandoc ignores or flattens items such as text boxes, SmartArt, WordArt,
and shapes containing text. Converting these to text format or saving as
an image with appropriate caption allows them to be rendered as desired.

Tables with long text or line breaks may need adjustment to the Pandoc
conversion process as described in
[`vignette("extended-workflow")`](https://sturdy-giggle-wwjo5pk.pages.github.io/articles/extended-workflow.md).
Merged cells in tables should be avoided.

Avoid manually changing font, size, alignment, or colour on individual
paragraphs. Instead, modify the style itself (Home → Styles → Modify).
This is because pandoc converts these into markdown as follows:

| Word style     | Markdown output                      |
|----------------|--------------------------------------|
| Heading 1      | `#`                                  |
| Heading 2      | `##`                                 |
| Heading 3      | `###`                                |
| Caption        | Markdown figure/table caption syntax |
| Normal         | Plain paragraphs                     |
| List Paragraph | `-` / `1.` lists                     |

### Captions (images & tables)

Word captions must be inserted via Word’s built‑in tool: Right‑click
image/table → Insert Caption

This ensures Pandoc recognises the caption as:

- an image/table
- with a formal caption
- with a stable anchor to the media file

Avoid typing captions manually below images as they will not be
detected.

## Reference documents

Quarto lets you specify a custom Word or PowerPoint template:

    format:
      docx:
        reference-doc: reference.docx

### Word

Your reference document should define the Styles supported by pandoc
markdown such as Headers 1-6, body text and lists. It is advisable to
take a blank Word file, ideally one generated via Quarto/pandoc and:

- Modify only the Styles, not the body text
- Save as reference.docx
- Store it in your project or shared template folder
- Reference it from your .qmd

To prevent formatting outside of supported and tested style from being
used. This can be achieved by going through Review → Protect → Restrict
Editing.

### PowerPoint

PowerPoint styling is controlled via a template (.pptx) master slide
deck. Pandoc supports a limited set of [slide
layouts](https://pandoc.org/demo/example33/10.1-structuring-the-slide-show.html).

## Advanced features

### Callouts and other components

While not ideal for readability in Word, it is possible to specify
components such as callouts by adding the syntax directly in the
document. For instance, this will render a callout when read into
Quarto.

    This is a word document.

    ::: {.callout-warning}
    # Warning!
    This is a callout warning.
    :::

### Making placeholders less disruptive

For the ease of reading, placeholders are wrapped in a custom styling.
If Word or HTML documents have the relevant styling, placeholders can be
hidden from view. In Word this can be toggled with the ¶ button on the
Home tab or with `CTRL + *`. Consideration should be made to whether
this makes it easier or harder for users editing the Word document as
invisible content is easier to accidentally delete.

An example Word document is provided in this package and is accessible
via
`system.file("extdata", "PlaceholderMarker_example.docx", package = "knittogether")`.
To apply the style to an arbitrary Word document, create a custom
character style with the Hidden font attribute enabled. In Word: Home →
Styles → New Style → Style type: Character → Format → Font → tick
Hidden. Reveal placeholders by toggling Show/Hide (¶).
