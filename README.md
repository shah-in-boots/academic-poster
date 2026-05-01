# academic-poster

A Quarto Typst custom format for configurable academic posters.

The extension lives in `_extensions/academic-poster` and is used with:

```yaml
format:
  academic-poster-typst:
    ...
```

## Design Goals

- Reuse Quarto metadata where practical: `title`, `subtitle`, `author`, author `affiliation`, `institution`, `mainfont`, `fontsize`, `margin`, and `columns`.
- Keep poster-specific controls namespaced with `poster-*`.
- Let ordinary level-1 Markdown headings create poster section cards.
- Support both simple flowing columns and explicit unequal-width poster columns.

## Quick Start

Render the included example from the repository root:

```bash
quarto render example.qmd
```

The example uses R + ggplot2 to generate two local figure PNGs in `figures/`, then places them into a PowerPoint-style poster layout.

For another project, copy `_extensions/academic-poster` into that project and set `format: academic-poster-typst` in a `.qmd` file.

## Brand Colors

Quarto Typst exposes `_brand.yml` colors as Typst expressions such as `brand-color.primary` or, more safely, `brand-color.at("primary", default: rgb("#b01c32"))`.

This extension uses brand defaults for poster colors when available. You can add a `_brand.yml` like:

```yaml
color:
  palette:
    cardinal: "#b01c32"
    cardinal-dark: "#6f1020"
    blush: "#f8e8eb"
    ink: "#17212b"
  background: white
  foreground: ink
  primary: cardinal
  secondary: cardinal-dark
  tertiary: blush
  light: blush
```

Then opt in from a document:

```yaml
brand: _brand.yml
```

## Metadata

The header automatically uses:

- `title`
- `subtitle`
- `author`
- author-level `affiliation`
- `institution` or `institutions`

Posterdown-style aliases are also accepted where useful:

- `poster-authors`
- `departments`
- `institution-logo`
- `footer-text`
- `footer-emails`
- `footer-color`

## Layout Options

Set these under `format: academic-poster-typst`.

```yaml
poster-width: 56in
poster-height: 31.5in
margin:
  x: 0.55in
  y: 0.45in
poster-header-height: 15%
poster-footer-height: 6%
poster-row-gap: 0.35in
poster-corner-radius: 7pt
```

You can also use the legacy margin aliases:

```yaml
poster-margin-x: 0.8in
poster-margin-y: 0.6in
```

## Columns

For simple posters, omit `.poster-column` containers and let content flow through equal Typst columns:

```yaml
poster-columns: 3
poster-column-gap: 0.45in
```

The standard Quarto `columns` option is also accepted as an alias for `poster-columns`.

For unequal-width columns, wrap top-level content in consecutive `.poster-column` Divs and set `poster-column-widths`:

```yaml
poster-column-gap: 0.45in
poster-column-widths: [1.1fr, 1fr, 0.9fr]
```

```markdown
::: {.poster-column}
# Background
...
:::

::: {.poster-column}
# Results
...
:::

::: {.poster-column}
# Conclusion
...
:::
```

This uses a small Lua filter to convert the Divs into a Typst `grid()`. Without explicit Divs, Typst's native `columns()` is used, which supports equal-width flow columns.

Add `.poster-feature` to a column to create a high-contrast feature/results panel:

```markdown
::: {.poster-column .poster-feature}
# Key Findings
...
:::
```

Feature panels can also use color modifiers:

```markdown
::: {.poster-column .poster-feature .secondary}
...
:::
```

## Sections And Callouts

Level-1 headings become poster cards automatically:

```markdown
# Background

Poster section text goes here.
```

Use `.poster-callout` for short emphasized findings:

```markdown
::: {.poster-callout .large}
Main result or take-home message.
:::
```

Supported heading/card modifiers:

- `.compact` reduces section card spacing.
- `.large` increases the section title size.
- `.light`, `.secondary`, `.accent`, `.dark`, and `.inverse` change the card header color treatment.
- `.plain` or `.no-card` leaves an H1 as a normal heading instead of making a card.

Supported callout modifiers:

- `.large` or `.compact` changes callout text size.
- `.light`, `.secondary`, `.accent`, `.dark`, and `.inverse` change the accent color.

## Header And Footer

```yaml
logo-left: images/lab-logo.png
logo-right: images/university-logo.png
poster-logo-width: 16%
poster-logo-height: 86%
footer-left: "Scan for preprint"
footer-center: "Conference Name 2026"
footer-right: "contact@example.edu"
footer-logo-left: images/sponsor.png
footer-logo-right: images/qr-code.png
```

Header and footer heights are controlled by `poster-header-height` and `poster-footer-height`, usually as percentages of the poster body area.

## Typography

Prefer Quarto's standard Typst options:

```yaml
mainfont: "Libertinus Serif"
fontsize: 22pt
```

Poster-specific typography options:

```yaml
poster-line-spacing: 1.15em
poster-title-size: 1.85em
poster-subtitle-size: 0.86em
poster-author-size: 0.72em
poster-institution-size: 0.62em
poster-footer-size: 0.58em
poster-h1-size: 0.78em
poster-h2-size: 0.72em
poster-h3-size: 0.68em
poster-card-title-size: 0.78em
poster-card-gap: 0.26em
poster-callout-size: 0.78em
```

## Theme Colors

Color values are Typst expressions. These can be literal colors or brand lookups:

```yaml
poster-primary: brand-color.at("primary", default: rgb("#b01c32"))
poster-secondary: rgb("#6f1020")
poster-subsection-bg: rgb("#f8e8eb")
```

Additional card and feature-panel color controls:

```yaml
poster-card-bg: white
poster-card-stroke: rgb("#ead8dc")
poster-feature-bg: brand-color.at("primary", default: rgb("#b01c32"))
poster-callout-bg: white
poster-callout-accent: rgb("#b01c32")
```

## Files

- `_extensions/academic-poster/_extension.yml` defines the Quarto format.
- `_extensions/academic-poster/typst-template.typ` defines the Typst layout functions.
- `_extensions/academic-poster/typst-show.typ` maps Quarto/Pandoc metadata into the Typst template.
- `_extensions/academic-poster/poster-columns.lua` enables explicit unequal-width poster columns.
- `_extensions/academic-poster/template.qmd` is the template copied by `quarto use template`.
- `example.qmd` is a root-level render test and starting example.
