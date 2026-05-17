// academic-poster Typst template
//
// Single source of truth for sizing, spacing, and color. User overrides flow
// through `poster()` which merges them over the defaults and stores the result
// in module state so helpers (poster-card, poster-callout, ...) read a
// consistent config.
//
// Unit convention:
//   - typography: em ratios of the document `fontsize`
//   - inset/gap between text-like things: em
//   - inset/gap between structural blocks (header, footer, feature): in or cm
//   - poster dimensions: in or cm (Typst `%` does not work for paper-size)
//   - header-height, footer-height, logo-width: % of the body grid (container)

// ---------------------------------------------------------------------------
// Defaults
// ---------------------------------------------------------------------------

#let DEFAULT-TYPOGRAPHY = (
  // Header
  title: 2.4em,
  subtitle: 1.0em,
  authors: 0.78em,
  institutions: 0.6em,
  // Footer
  footer: 0.58em,
  // Cards (level-1 sections rendered as cards)
  "card-title": 1.0em,
  "card-title-large": 1.18em,
  "card-title-compact": 0.86em,
  // Callouts
  callout: 1.0em,
  "callout-large": 1.2em,
  "callout-compact": 0.86em,
  // Body
  body: 1em,
  h2: 0.95em,
  h3: 0.88em,
)

#let DEFAULT-SPACING = (
  "row-gap": 0.35in,
  "column-gap": 0.5in,
  "header-padding": (x: 0.45in, y: 0.25in),
  "footer-padding": (x: 0.45in, y: 0.18in),
  "feature-inset": 0.38in,
  "card-gap": 0.32em,
  "card-gap-compact": 0.22em,
  "card-header-inset": (x: 0.45em, y: 0.26em),
  "card-body-inset": (x: 0.48em, y: 0.34em),
  "card-body-inset-compact": (x: 0.38em, y: 0.22em),
  "callout-inset": (x: 0.42em, y: 0.28em),
  "callout-gap": 0.3em,
  "corner-radius": 5pt,
  "feature-radius": 7pt,
)

#let DEFAULT-COLORS = (
  background: white,
  foreground: rgb("#17212b"),
  primary: rgb("#b01c32"),
  secondary: rgb("#6f1020"),
  accent: rgb("#f4c7cf"),
  light: rgb("#f8e8eb"),
  dark: rgb("#17212b"),
  inverse: white,
  stroke: rgb("#ead8dc"),
  // "on-X" sets the foreground color used on top of color X
  "on-primary": white,
  "on-secondary": white,
  "on-accent": rgb("#6f1020"),
  "on-light": rgb("#6f1020"),
  "on-dark": white,
  "on-inverse": rgb("#6f1020"),
  "on-background": rgb("#17212b"),
)

#let SCALE-PRESETS = (
  compact: 0.88,
  default: 1.0,
  spacious: 1.14,
)

// ---------------------------------------------------------------------------
// State (populated by `poster()`, read by helpers)
// ---------------------------------------------------------------------------

#let _typo = state("poster:typography", DEFAULT-TYPOGRAPHY)
#let _spacing = state("poster:spacing", DEFAULT-SPACING)
#let _colors = state("poster:colors", DEFAULT-COLORS)

#let _merge(defaults, override) = {
  let result = defaults
  if override == none { return result }
  for (k, v) in override {
    result.insert(k, v)
  }
  result
}

#let _scale-typography(typo, factor) = {
  if factor == 1.0 { return typo }
  let scaled = (:)
  for (k, v) in typo {
    scaled.insert(k, v * factor)
  }
  scaled
}

#let _has-content(value) = value != none and repr(value) != "[]"

#let _on(c, variant) = c.at("on-" + variant, default: c.at("on-primary", default: white))

// ---------------------------------------------------------------------------
// Helpers: building blocks emitted by the Lua filter
// ---------------------------------------------------------------------------

#let poster-card(
  body,
  title: none,
  role: "card",        // "card" | "card-large" | "card-compact"
  variant: "primary",  // any color key, e.g. "primary", "secondary", "light"
) = context {
  let t = _typo.get()
  let s = _spacing.get()
  let c = _colors.get()

  // role "card" -> title key "card-title"; "card-large" -> "card-title-large"
  let title-key = if role == "card" { "card-title" } else { "card-title-" + role.slice(5) }
  let title-size = t.at(title-key, default: t.at("card-title"))

  let body-inset = s.at(
    if role == "card-compact" { "card-body-inset-compact" } else { "card-body-inset" },
  )
  let gap = s.at(if role == "card-compact" { "card-gap-compact" } else { "card-gap" })

  let header-fill = c.at(variant, default: c.primary)
  let header-text = _on(c, variant)
  let radius = s.at("corner-radius")

  block(
    width: 100%,
    inset: 0pt,
    radius: radius,
    fill: c.background,
    stroke: 0.8pt + c.stroke,
  )[
    #if _has-content(title) [
      #block(
        width: 100%,
        inset: s.at("card-header-inset"),
        radius: radius,
        fill: header-fill,
      )[
        #set text(fill: header-text, weight: "bold", size: title-size)
        #upper(title)
      ]
    ]
    #block(width: 100%, inset: body-inset)[
      #body
    ]
  ]
  v(gap)
}

#let poster-callout(
  body,
  role: "callout",     // "callout" | "callout-large" | "callout-compact"
  variant: "primary",
) = context {
  let t = _typo.get()
  let s = _spacing.get()
  let c = _colors.get()

  let text-size = t.at(role, default: t.at("callout"))
  let accent-color = c.at(variant, default: c.primary)

  block(
    width: 100%,
    inset: s.at("callout-inset"),
    radius: s.at("corner-radius"),
    fill: c.background,
    stroke: 1.2pt + accent-color,
  )[
    #set text(fill: c.foreground, size: text-size, weight: "semibold")
    #body
  ]
  v(s.at("callout-gap"))
}

#let poster-feature-column(
  body,
  variant: "primary",
) = context {
  let s = _spacing.get()
  let c = _colors.get()
  block(
    width: 100%,
    height: 100%,
    inset: s.at("feature-inset"),
    radius: s.at("feature-radius"),
    fill: c.at(variant, default: c.primary),
  )[
    #body
  ]
}

#let poster-grid(..children, columns: (1fr, 1fr, 1fr)) = context {
  let s = _spacing.get()
  grid(
    columns: columns,
    column-gutter: s.at("column-gap"),
    align: top,
    ..children,
  )
}

// ---------------------------------------------------------------------------
// Header / footer
// ---------------------------------------------------------------------------

#let _maybe-image(path, height: 100%) = {
  if path == none { [] } else { image(path, height: height) }
}

#let _footer-item(text-value, logo: none, reverse: false, logo-height: 70%) = {
  if logo == none and text-value == none { [] }
  else if logo == none { text-value }
  else if text-value == none { image(logo, height: logo-height) }
  else if reverse {
    grid(
      columns: (1fr, auto),
      column-gutter: 0.35em,
      align: (right + horizon, right + horizon),
      text-value,
      image(logo, height: logo-height),
    )
  } else {
    grid(
      columns: (auto, 1fr),
      column-gutter: 0.35em,
      align: (left + horizon, left + horizon),
      image(logo, height: logo-height),
      text-value,
    )
  }
}

#let poster-header(
  title: none,
  subtitle: none,
  authors: none,
  institutions: none,
  logo-left: none,
  logo-right: none,
  logo-width: 16%,
  logo-height: 86%,
) = context {
  let t = _typo.get()
  let s = _spacing.get()
  let c = _colors.get()

  block(
    width: 100%,
    height: 100%,
    inset: s.at("header-padding"),
    fill: c.primary,
  )[
    #grid(
      columns: (logo-width, 1fr, logo-width),
      column-gutter: 0.35in,
      align: (left + horizon, center + horizon, right + horizon),
      _maybe-image(logo-left, height: logo-height),
      align(center + horizon)[
        #if _has-content(title) [
          #set text(weight: "bold", size: t.at("title"), fill: c.at("on-primary"))
          #title
        ]
        #if _has-content(subtitle) [
          #v(0.18em)
          #set text(weight: "regular", size: t.at("subtitle"), fill: c.at("on-primary"))
          #subtitle
        ]
        #if _has-content(authors) [
          #v(0.24em)
          #set text(weight: "medium", size: t.at("authors"), fill: c.at("on-primary"))
          #authors
        ]
        #if _has-content(institutions) [
          #v(0.16em)
          #set text(weight: "regular", size: t.at("institutions"), fill: c.at("on-primary"))
          #institutions
        ]
      ],
      align(right + horizon)[
        #_maybe-image(logo-right, height: logo-height)
      ],
    )
  ]
}

#let poster-footer(
  footer-left: none,
  footer-center: none,
  footer-right: none,
  footer-logo-left: none,
  footer-logo-right: none,
  logo-height: 70%,
) = context {
  let t = _typo.get()
  let s = _spacing.get()
  let c = _colors.get()

  block(
    width: 100%,
    height: 100%,
    inset: s.at("footer-padding"),
    fill: c.primary,
  )[
    #align(center + horizon)[
      #set text(size: t.at("footer"), fill: c.at("on-primary"))
      #grid(
        columns: (1fr, auto, 1fr),
        column-gutter: 0.35in,
        align: (left + horizon, center + horizon, right + horizon),
        _footer-item(footer-left, logo: footer-logo-left, logo-height: logo-height),
        [
          #set text(weight: "semibold")
          #if footer-center != none { footer-center }
        ],
        _footer-item(footer-right, logo: footer-logo-right, reverse: true, logo-height: logo-height),
      )
    ]
  ]
}

// ---------------------------------------------------------------------------
// Body layout
// ---------------------------------------------------------------------------

#let poster-body(body, column-layout: "flow", column-count: 3) = context {
  let s = _spacing.get()
  if column-layout == "flow" and column-count > 1 {
    columns(column-count, gutter: s.at("column-gap"))[#body]
  } else {
    body
  }
}

// ---------------------------------------------------------------------------
// Top-level `poster()` — applied with `#show: poster.with(...)`
// ---------------------------------------------------------------------------

#let poster(
  body,
  // Header / footer slots
  title: none,
  subtitle: none,
  authors: none,
  institutions: none,
  logo-left: none,
  logo-right: none,
  footer-center: none,
  footer-left: none,
  footer-right: none,
  footer-logo-left: none,
  footer-logo-right: none,

  // Paper + body layout
  paper-size: (width: 48in, height: 36in),
  margin: (x: 1in, y: 0.75in),
  column-layout: "flow",
  column-count: 3,

  // Typography knobs (Quarto-native)
  font-family: "Libertinus Serif",
  font-size: 22pt,
  line-spacing: 1.15em,

  // Single-knob preset + per-key overrides
  scale: "default",
  typography: (:),
  spacing: (:),
  colors: (:),

  // Structural rows
  header-height: 17%,
  footer-height: 8%,
  logo-width: 16%,
  logo-height: 86%,
  footer-logo-height: 70%,
) = {
  let factor = SCALE-PRESETS.at(scale, default: 1.0)
  let merged-typo = _scale-typography(_merge(DEFAULT-TYPOGRAPHY, typography), factor)
  let merged-spacing = _merge(DEFAULT-SPACING, spacing)
  let merged-colors = _merge(DEFAULT-COLORS, colors)

  _typo.update(merged-typo)
  _spacing.update(merged-spacing)
  _colors.update(merged-colors)

  set page(
    width: paper-size.width,
    height: paper-size.height,
    margin: margin,
    fill: merged-colors.background,
    numbering: none,
  )
  set text(font: font-family, size: font-size, fill: merged-colors.foreground)
  set par(justify: false, leading: line-spacing)

  // Plain-mode (.plain / .no-card) headings — Lua bypasses card wrapping for these
  show heading.where(level: 1): it => context {
    let t = _typo.get()
    let s = _spacing.get()
    let c = _colors.get()
    block(width: 100%, inset: s.at("card-header-inset"), radius: s.at("corner-radius"), fill: c.primary)[
      #set text(fill: c.at("on-primary"), weight: "bold", size: t.at("card-title"))
      #upper(it.body)
    ]
    v(0.18em)
  }
  show heading.where(level: 2): it => context {
    let t = _typo.get()
    let s = _spacing.get()
    let c = _colors.get()
    block(width: 100%, inset: (x: 0.4em, y: 0.22em), radius: s.at("corner-radius"), fill: c.light)[
      #set text(fill: c.at("on-light"), weight: "semibold", size: t.at("h2"))
      #it.body
    ]
    v(0.14em)
  }
  show heading.where(level: 3): it => context {
    let t = _typo.get()
    let c = _colors.get()
    block(width: 100%)[
      #set text(fill: c.secondary, weight: "semibold", size: t.at("h3"))
      #it.body
    ]
    v(0.08em)
  }

  context {
    let s = _spacing.get()
    block(width: 100%, height: 100%)[
      #grid(
        columns: (1fr,),
        rows: (header-height, 1fr, footer-height),
        row-gutter: s.at("row-gap"),
        poster-header(
          title: title,
          subtitle: subtitle,
          authors: authors,
          institutions: institutions,
          logo-left: logo-left,
          logo-right: logo-right,
          logo-width: logo-width,
          logo-height: logo-height,
        ),
        block(width: 100%, height: 100%)[
          #poster-body(body, column-layout: column-layout, column-count: column-count)
        ],
        poster-footer(
          footer-left: footer-left,
          footer-center: footer-center,
          footer-right: footer-right,
          footer-logo-left: footer-logo-left,
          footer-logo-right: footer-logo-right,
          logo-height: footer-logo-height,
        ),
      )
    ]
  }
}
