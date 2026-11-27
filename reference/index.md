# Package index

## Workflow

Bring a Word or PowerPoint file into Markdown, fill its placeholders and
tidy it for Quarto.

- [`convert_markdown()`](https://wyuill.github.io/knittogether/reference/convert_markdown.md)
  : Convert a Word or PowerPoint file to Markdown
- [`clean_markdown()`](https://wyuill.github.io/knittogether/reference/clean_markdown.md)
  : Tidy converted Markdown for Quarto
- [`replace_placeholders()`](https://wyuill.github.io/knittogether/reference/replace_placeholders.md)
  : Fill placeholders with R content
- [`run_workflow()`](https://wyuill.github.io/knittogether/reference/run_workflow.md)
  : Convert, clean and fill a document in one call

## Defining content

Say what goes in each placeholder.

- [`define_content()`](https://wyuill.github.io/knittogether/reference/define_content.md)
  : Describe the content for one placeholder
- [`placeholder_map()`](https://wyuill.github.io/knittogether/reference/placeholder_map.md)
  : Collect the content for every placeholder

## Versions

Pick up the latest draft and keep earlier ones.

- [`latest_word_file()`](https://wyuill.github.io/knittogether/reference/latest_word_file.md)
  : Find the newest Word or PowerPoint file in a folder
- [`timestamped_path()`](https://wyuill.github.io/knittogether/reference/timestamped_path.md)
  : Add the date and time to a file name

## PowerPoint

Slide breaks, columns and backgrounds for slides.

- [`slide_break()`](https://wyuill.github.io/knittogether/reference/slide_break.md)
  : Start a new slide
- [`insert_slide_break()`](https://wyuill.github.io/knittogether/reference/insert_slide_break.md)
  : Break text into a new slide once, before a character limit
- [`auto_slide_break()`](https://wyuill.github.io/knittogether/reference/auto_slide_break.md)
  : Break text into slides that fit
- [`pptx_col_start()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md)
  [`pptx_col_break()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md)
  [`pptx_col_end()`](https://wyuill.github.io/knittogether/reference/pptx_col_start.md)
  : Split a slide into two columns
- [`pptx_section_slide()`](https://wyuill.github.io/knittogether/reference/pptx_section_slide.md)
  : Write a heading with a background image
- [`add_pptx_backgrounds_to_headers()`](https://wyuill.github.io/knittogether/reference/add_pptx_backgrounds_to_headers.md)
  : Add a background image to headings in Markdown

## Output format

Do something only for one output format, or hide markers in HTML.

- [`is_pptx()`](https://wyuill.github.io/knittogether/reference/is_html.md)
  [`is_docx()`](https://wyuill.github.io/knittogether/reference/is_html.md)
  [`is_pdf()`](https://wyuill.github.io/knittogether/reference/is_html.md)
  [`is_html()`](https://wyuill.github.io/knittogether/reference/is_html.md)
  : Check the format being rendered
- [`output_type()`](https://wyuill.github.io/knittogether/reference/output_type.md)
  : Name the format being rendered
- [`hide_markers_css()`](https://wyuill.github.io/knittogether/reference/hide_markers_css.md)
  : CSS that hides placeholder markers in HTML

## Checking and long documents

- [`accessibility_scan()`](https://wyuill.github.io/knittogether/reference/accessibility_scan.md)
  : Check images and tables have alt text or captions
- [`split_markdown()`](https://wyuill.github.io/knittogether/reference/split_markdown.md)
  : Split a long Markdown file into one file per section
