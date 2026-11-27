# Using references

Your colleagues will probably add citations in Word with Zotero, and
they’ll want to see them in a normal style such as APA or Vancouver, not
as Pandoc citation keys. This article shows how to bring Zotero
citations from Word into Markdown, and how to send a document back to
Word with the citations still live, so they can carry on editing them in
Zotero.

You need [Zotero](https://www.zotero.org/download) and its [Better
BibTeX](https://retorque.re/zotero-better-bibtex/installation/) add-on.

## From Word to Markdown

Before converting the document, swap its citations for citation keys and
export a bibliography:

1.  Open the document in Word. Save a copy first if you want to keep the
    linked citations, although knittogether can give you working
    citations back later.
2.  On the Zotero tab, click Document Preferences, choose the citation
    style “Better BibTeX Citekeys” and click OK.
3.  Still on the Zotero tab, click Unlink Citations and accept the
    warning. Each citation is now plain text such as
    `[@roseRosesStrategyPreventive2008]`, which Pandoc understands.
4.  In Zotero, right-click the collection that holds the references,
    choose Export Collection, pick Better BibTeX as the format and save
    the `.bib` file in your project.

It’s easiest if each project has its own Zotero collection, so the
bibliography holds only the references you use.

Then convert and clean as usual, with `clean_citations = TRUE` (see
[`vignette("knittogether")`](https://wyuill.github.io/knittogether/articles/knittogether.md)),
and list the `.bib` file under `bibliography` in your Quarto document.

## From Markdown back to Word, with live citations

To give your colleague a Word document where the citations still work in
Zotero, you need three files:

- **The `.bib` file** you exported above.
- **A citation style (`.csl`)**, for example from the [Citation Style
  Language styles
  repository](https://github.com/citation-style-language/styles).
- **`zotero.lua`**, a [Lua filter from Better
  BibTeX](https://retorque.re/zotero-better-bibtex/exporting/pandoc/#from-markdown-to-zotero-live-citations)
  that turns citation keys back into live Zotero citations.

Add them to the YAML of your `.qmd`:

``` yaml
format:
  docx: default
csl: elsevier-vancouver.csl
bibliography: example.bib
filters:
  - zotero.lua
```

Zotero needs to be running when you render. You can then go round as
often as you like: Word to Markdown to Word, with live references each
time. Just remember to unlink the citations (steps 2 and 3 above) each
time before converting.

## If something goes wrong

- **Citations show up with backslashes, such as `\[@key\]`.** Converting
  to a different Markdown flavour, for example with
  `convert_markdown(pandoc_args = "--to=markdown_strict")`, can add
  extra escaping. Run `clean_markdown(clean_citations = TRUE)` to remove
  it.
- **A citation doesn’t link to its reference.** The key in the document
  doesn’t match the key in the `.bib` file. In Zotero, check or edit the
  item’s citation key so the two agree, then export the bibliography
  again.

[`vignette("extended-workflow")`](https://wyuill.github.io/knittogether/articles/extended-workflow.md)
includes a document with a citation you can try this on.
