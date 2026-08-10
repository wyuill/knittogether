# knittogether

## Overview

knittogether is an R package for reproducible collaboration between R
users and non-R users. It helps teams produce high-quality Quarto
outputs while reducing the friction of moving between Office and Quarto.

- Import .docx / .pptx into markdown
- Replace placeholders with R-generated content
- Render back to Word, PowerPoint, HTML, etc.
- Support round‑trip editing when working with non‑R colleagues
  iteratively

### Motivation

Working with non-R users often involves tedious manual steps such as
copy-pasting text, reformatting images, adjusting slide breaks, redoing
citations, and then starting again when someone changes something. Yet
their contributions are often essential for creating meaningful reports
and presentations. knittogether streamlines this process by allowing you
to seamlessly combine content from Quarto, Microsoft Word, and Microsoft
PowerPoint, including:

- Text sections
- Images and tables
- Citations and footnotes
- Slide breaks and sections

The result is a single, reproducible workflow that outputs to any
Quarto-supported format (HTML, PDF, Word, PowerPoint, etc.), reducing
errors and saving time for R users whilst allowing non-R users to
contribute without technical barriers.

## Installation

    # install.packages("pak")
    pak::pak("LBCamden/knittogether")

As noted in the DESCRIPTION, if functions involving the import and/or
export of citations are used then
[Zotero](https://www.zotero.org/download) and
[BetterBibTeX](https://github.com/retorquere/zotero-better-bibtex/releases)
are required. To export live citations to .docx format, a [Lua
filter](https://retorque.re/zotero-better-bibtex/exporting/zotero.lua)
is required and must be specified in the YAML of the .qmd.

## Usage

knittogether follows a standard workflow convert→clean→replace.

    library(knittogether)

    # example.docx is a Word document containing placeholders indicating what and where code content should be added (e.g. `placeholder_content_plot`). It is converted into a markdown file.
    convert(input_file = "example.docx", markdown_file = "example.md")

    # The markdown is cleaned to ensure it works with Quarto
    clean(markdown_file = "example.md")

    # Code content is created and mapped onto the placeholders
    plot <- define_content(
      description = "A plot",
      placeholder_id = "plot",
      output_mode = "chunk",
      content = { plot(1, 1) },
      content_type = "plot",
      chunk_options  = list(echo = FALSE))

    map <- placeholder_map(specs = list(plot))

    # The placeholders in the markdown are switched for the code content. The output is ready to use within a Quarto file and rendered to any format
    replace(markdown_file = "example.md",
      placeholder_prefix = "placeholder_content",
      code_content = map)

## Getting help

- Browse the function documentation
  (e.g. [`?knittogether::clean`](https://sturdy-giggle-wwjo5pk.pages.github.io/reference/clean.md))
  and vignettes.

- Please open an issue on GitHub or [get in
  touch](https://jsna.camden.gov.uk/about/#get-in-touch).
