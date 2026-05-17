# academic-poster

A Quarto Typst custom format for academic research posters. The whole thing is plain Markdown plus YAML, with a small Typst template and a Lua filter handling the layout.

```yaml
format:
  academic-poster-typst:
    poster-size: 48x36in
    fontsize: 22pt
    poster-scale: default
```

```bash
quarto render example.qmd
```

---

## Mental Model

```
your-poster.qmd ──► poster-columns.lua ──► typst-show.typ ──► poster() in typst-template.typ
   (YAML + MD)        (Pandoc filter)        (template partial)       (Typst layout)
```

1. **`your-poster.qmd`** — Quarto/Markdown source. YAML keys drive layout; level-1 headings become cards; `.poster-column` / `.poster-callout` / `.poster-feature` divs structure the page.
2. **`poster-columns.lua`** — Pandoc filter that:
   - Resolves `poster-size` aliases (`a0`, `48x36in`, ...) into width/height.
   - Wraps level-1 headings into `#poster-card(role: ..., variant: ...)[...]` calls.
   - Converts `.poster-column` Divs into a `#poster-grid(...)` call.
   - Builds `typography:`, `spacing:`, `colors:` dict literals from nested YAML maps and stashes them as `resolved-*` meta values.
   - Resolves author affiliations into a single institutions string.
3. **`typst-show.typ`** — Pandoc template partial that emits a single `#show: poster.with(...)` call, splicing in the resolved meta.
4. **`typst-template.typ`** — All defaults, helpers, and the top-level `poster()` show rule live here.

When you want to change a default, you change exactly one place: [_extensions/academic-poster/typst-template.typ](_extensions/academic-poster/typst-template.typ) (the three `DEFAULT-*` dicts at the top).

---

## Sizing Model

Everything typographic is expressed as a multiple of the document `fontsize`. Everything structural is expressed in absolute lengths or container percentages. There are three unit families and they map to roles cleanly:

| Use | Unit | Why |
|---|---|---|
| Type sizes (title, body, card titles, callouts) | `em` | Scales with `fontsize`; one knob changes everything |
| Per-element padding and gaps around text | `em` | Stays proportional to type size |
| Poster paper dimensions, margins, column gutters | `in` / `cm` / `mm` / `pt` | Typst `%` does not work for `page` size |
| Header height, footer height, logo width inside header | `%` | Container-relative; lets you target a fraction of the body grid |
| Column widths | `fr` (or bare number, auto-suffixed) | Typst grid fractional units |

A single knob — `poster-scale: compact | default | spacious` — multiplies every `em` typography value at once.

### The typography roles

Defined in `DEFAULT-TYPOGRAPHY` in [_extensions/academic-poster/typst-template.typ](_extensions/academic-poster/typst-template.typ):

| Role | Default | Where it applies |
|---|---|---|
| `title` | 2.4em | Poster title in the header |
| `subtitle` | 1.0em | Subtitle line under the title |
| `authors` | 0.78em | Author byline |
| `institutions` | 0.6em | Affiliations line |
| `footer` | 0.58em | Footer text |
| `card-title` | 1.0em | Section card header (h1 → card) |
| `card-title-large` | 1.18em | Section card with `.large` modifier |
| `card-title-compact` | 0.86em | Section card with `.compact` modifier |
| `callout` | 1.0em | Default `.poster-callout` text |
| `callout-large` | 1.2em | `.poster-callout.large` |
| `callout-compact` | 0.86em | `.poster-callout.compact` |
| `body` | 1em | Body paragraph text |
| `h2` | 0.95em | Plain-mode level-2 heading |
| `h3` | 0.88em | Plain-mode level-3 heading |

### Per-role overrides

Use `poster-typography:` (a YAML map) for one-off tweaks. Values must include a Typst unit:

```yaml
format:
  academic-poster-typst:
    poster-scale: default
    poster-typography:
      title: 2.8em
      card-title-large: 1.4em
```

Same shape for `poster-spacing:` and `poster-colors:`.

---

## Class System

Markdown Divs and headings carry a small set of modifier classes that drive layout and styling. Think of them like reveal.js slide modifiers — adding a class changes the rendering without touching Typst.

### Layout containers

| Class | Effect |
|---|---|
| `.poster-column` | Marks a top-level column. Two or more in a row form a horizontal grid using `poster-columns:` widths. |
| `.poster-feature` | Combined with `.poster-column`, produces a high-contrast filled panel (a "results" column). |
| `.poster-callout` | Bordered emphasis box for short claims. |

### Modifiers (apply to cards and callouts)

| Class | Effect |
|---|---|
| `.compact` | Tighter padding, smaller title/text |
| `.large` | Bigger title/text |
| `.plain` / `.no-card` | Leave an h1 as a normal heading instead of wrapping it in a card |
| `.secondary` | Use the `secondary` color |
| `.accent` | Use the `accent` color |
| `.light` | Light background, dark text |
| `.dark` | Dark background, light text |
| `.inverse` | White card on a dark feature panel |

### Examples

```markdown
::: {.poster-column}

# Background {.compact}

Body text.

# Methods {.compact}

- Bullet one
- Bullet two

:::

::: {.poster-column .poster-feature}

# Key Findings {.compact .inverse}

::: {.poster-callout .large}
Headline result in one sentence.
:::

![](figures/main.png){width=100%}

:::
```

---

## YAML Reference

### Paper

```yaml
poster-size: 48x36in     # presets: a0 a1 a2 a3 (+ -landscape); or WxH<unit>
# or explicit:
poster-width: 56in
poster-height: 31.5in

margin:
  x: 0.55in              # Quarto-native key
  y: 0.45in
```

### Body layout

```yaml
poster-columns: [1, 1.3, 1]   # widths in fr (bare numbers => Nfr)
# or just a count for equal columns:
poster-columns: 3

poster-header-height: 15%     # % of the poster body grid
poster-footer-height: 6%
poster-logo-width: 14%        # % of the header strip
poster-logo-height: 86%       # % of the header strip
```

### Typography

```yaml
fontsize: 22pt                # Quarto-native; the anchor for every em ratio
mainfont: "Libertinus Serif"  # Quarto-native

poster-scale: default         # compact | default | spacious
poster-typography:            # advanced per-key override
  title: 2.8em
  card-title-compact: 0.78em
```

### Colors

Brand colors via `_brand.yml` are automatically wired into `primary`, `secondary`, `accent`, `light`, `background`, and `foreground`. To override:

```yaml
poster-colors:
  primary: '#b01c32'
  secondary: '#6f1020'
  accent: '#f4c7cf'
  light: '#f8e8eb'
  # plus the "on-X" foreground used on top of X:
  on-primary: white
```

### Spacing

```yaml
poster-spacing:
  row-gap: 0.4in
  column-gap: 0.6in
  card-gap: 0.32em
  feature-inset: 0.4in
  corner-radius: 6pt
```

### Header / footer slots

```yaml
logo-left: images/lab-logo.png
logo-right: images/conference-logo.png
footer-left: "Scan for preprint"
footer-center: "Conference Name 2026"
footer-right: "@handle"
footer-logo-left: images/sponsor.png
footer-logo-right: images/qr-code.png
```

Institutions auto-resolve from per-author `affiliation` entries; override with explicit `institutions:` or `institution:` if you want full control.

---

## Recipes

### Render the included example

```bash
quarto render example.qmd
```

The example uses R + ggplot2 to generate two PNGs in `figures/`, then assembles them with a feature column.

### Start a new poster from the template

```bash
quarto use template <path-to-this-repo>
```

Or copy `_extensions/academic-poster` into an existing project and add to your `.qmd`:

```yaml
format:
  academic-poster-typst: default
```

### Two-column poster

```yaml
poster-columns: [1, 1]
```

Or omit `.poster-column` Divs entirely and use Quarto's flowing columns:

```yaml
poster-columns: 2
```

### Swap to a different brand color

In `_brand.yml`:

```yaml
color:
  palette:
    navy: "#1a3a6e"
  primary: navy
```

Or, without `_brand.yml`:

```yaml
poster-colors:
  primary: '#1a3a6e'
  secondary: '#0f1f3a'
```

### A more compact poster (tighter type, same dimensions)

```yaml
poster-scale: compact
```

### One specific card title is too big

```yaml
poster-typography:
  card-title-large: 1.05em
```

---

## Known Limitations / Work in Progress

- **No automatic column balancing across `.poster-column` Divs.** Each column gets the content you place in it; if one runs short, the bottom of that column is blank. (Use `poster-columns: 3` without explicit Divs if you want Typst's flowing columns instead.)
- **No bibliography styling yet.** Quarto's citeproc still works but the bibliography card has no custom rendering. Wrap it in a `.compact` section if you use it.
- **Brand colors only read 6 slots** (`primary`, `secondary`, `tertiary` → accent, `light`, `background`, `foreground`). Other brand keys are ignored.
- **`a0`/`a1`/`a2`/`a3` are the only paper presets.** US-Letter-derived sizes need explicit `WxH<unit>`.
- **Feature columns don't yet expose individual padding.** `poster-spacing.feature-inset` is global.
- **Heading levels 4+ have no custom rendering.**

---

## Files

| File | Role |
|---|---|
| [_extensions/academic-poster/_extension.yml](_extensions/academic-poster/_extension.yml) | Quarto format manifest |
| [_extensions/academic-poster/typst-template.typ](_extensions/academic-poster/typst-template.typ) | Defaults + helpers + `poster()` show rule |
| [_extensions/academic-poster/typst-show.typ](_extensions/academic-poster/typst-show.typ) | Pandoc → Typst metadata splice |
| [_extensions/academic-poster/poster-columns.lua](_extensions/academic-poster/poster-columns.lua) | Pandoc AST → structural Typst calls |
| [_extensions/academic-poster/template.qmd](_extensions/academic-poster/template.qmd) | Starter copied by `quarto use template` |
| [example.qmd](example.qmd) | Render test and starting example |
| [_brand.yml](_brand.yml) | Brand color palette |
