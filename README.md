# research-poster

A Quarto Typst custom format for academic posters with configurable layout, branding, and metadata.

## What this provides

This repository includes a Quarto extension in `_extensions/research-poster` with:

- a Typst poster template function (`typst-template.typ`)
- a Quarto/Pandoc bridge (`typst-show.typ`)
- extension metadata (`_extension.yml`)
- a starter poster document (`template.qmd`)

## Design goals

- Reuse standard Quarto metadata where possible (`title`, `subtitle`, `author`, affiliation data).
- Provide poster-specific controls through YAML options.
- Keep sectioning natural by relying on regular Markdown headings.

## Supported YAML options

Set options in your document under:

```yaml
format:
  research-poster-typst:
    ...
```

### Core layout

- `poster-width` (default `48in`)
- `poster-height` (default `36in`)
- `poster-margin-x` (default `1in`)
- `poster-margin-y` (default `0.75in`)
- `poster-columns` (default `3`)
- `poster-column-gap` (default `0.5in`)
- `poster-column-widths` (example: `[1.1fr, 1fr, 0.9fr]`)
- `poster-header-height` (default `17%`)
- `poster-footer-height` (default `8%`)

### Header / footer content

- Uses standard metadata: `title`, `subtitle`, and `author`.
- Optional logos:
  - `logo-left`
  - `logo-right`
- Optional footer fields:
  - `footer-left`
  - `footer-center`
  - `footer-right`

### Typography

- `mainfont` (default `Libertinus Serif`)
- `font-size` (default `22pt`)

### Theme colors

- `poster-background`
- `poster-foreground`
- `poster-primary`
- `poster-secondary`
- `poster-accent`
- `poster-section-bg`
- `poster-section-fg`
- `poster-footer-bg`
- `poster-footer-fg`

## Quick start

1. Copy or install this extension in a Quarto project.
2. Create a `.qmd` poster file.
3. Set `format: research-poster-typst` and configure YAML options.
4. Render with Quarto.

A complete example is available in `_extensions/research-poster/template.qmd`.
