#let safe-content(value) = {
  if value == none { [] } else { value }
}

#let has-content(value) = {
  value != none and repr(value) != "[]"
}

#let poster-card(
  body,
  title: none,
  fill: white,
  stroke-color: rgb("#ead8dc"),
  header-fill: rgb("#b01c32"),
  header-text: white,
  radius: 5pt,
  header-inset: (x: 0.45em, y: 0.26em),
  body-inset: (x: 0.48em, y: 0.34em),
  gap: 0.32em,
  title-size: 0.92em,
) = [
  #block(width: 100%, inset: 0pt, radius: radius, fill: fill, stroke: 0.8pt + stroke-color)[
    #if has-content(title) [
      #block(width: 100%, inset: header-inset, radius: radius, fill: header-fill)[
        #set text(fill: header-text, weight: "bold", size: title-size)
        #upper(title)
      ]
    ]
    #block(width: 100%, inset: body-inset)[
      #body
    ]
  ]
  #v(gap)
]

#let poster-callout(
  body,
  fill: white,
  text-fill: rgb("#17212b"),
  stroke-color: rgb("#ead8dc"),
  accent: rgb("#b01c32"),
  radius: 5pt,
  inset: (x: 0.42em, y: 0.28em),
  text-size: 0.88em,
  weight: "semibold",
) = [
  #block(width: 100%, inset: inset, radius: radius, fill: fill, stroke: 1.2pt + accent)[
    #set text(fill: text-fill, size: text-size, weight: weight)
    #body
  ]
  #v(0.3em)
]

#let poster-feature-column(
  body,
  fill: rgb("#b01c32"),
  inset: 0.38in,
  radius: 7pt,
) = {
  block(width: 100%, height: 100%, inset: inset, radius: radius, fill: fill)[
    #body
  ]
}

#let maybe-image(path, height: 100%) = {
  if path == none {
    []
  } else {
    image(path, height: height)
  }
}

#let footer-item(text-value, logo: none, reverse: false, logo-height: 70%) = {
  if logo == none and text-value == none {
    []
  } else if logo == none {
    text-value
  } else if text-value == none {
    image(logo, height: logo-height)
  } else if reverse {
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

#let poster-grid(..children, columns: (1fr, 1fr, 1fr), gutter: 0.5in) = {
  grid(
    columns: columns,
    column-gutter: gutter,
    align: top,
    ..children,
  )
}

#let poster-body(body, column-layout: "flow", column-count: 3, column-gap: 0.5in) = {
  if column-layout == "flow" and column-count > 1 {
    columns(column-count, gutter: column-gap)[#body]
  } else {
    body
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
  gap: 0.35in,
  padding: (x: 0.45in, y: 0.25in),
  radius: 0pt,
  theme: (:),
) = {
  block(width: 100%, height: 100%, inset: padding, radius: radius, fill: theme.header-bg)[
    #align(center + horizon)[
      #grid(
        columns: (logo-width, 1fr, logo-width),
        column-gutter: gap,
        align: (left + horizon, center + horizon, right + horizon),
        [
          #maybe-image(logo-left, height: logo-height)
        ],
        [
          #align(center + horizon)[
            #if has-content(title) [
              #set text(weight: "bold", size: theme.title-size, fill: theme.title-fg)
              #title
            ]
            #if has-content(subtitle) [
              #v(0.18em)
              #set text(weight: "regular", size: theme.subtitle-size, fill: theme.subtitle-fg)
              #subtitle
            ]
            #if has-content(authors) [
              #v(0.24em)
              #set text(weight: "medium", size: theme.author-size, fill: theme.header-fg)
              #authors
            ]
            #if has-content(institutions) [
              #v(0.16em)
              #set text(weight: "regular", size: theme.institution-size, fill: theme.header-fg)
              #institutions
            ]
          ]
        ],
        [
          #align(right + horizon)[
            #maybe-image(logo-right, height: logo-height)
          ]
        ],
      )
    ]
  ]
}

#let poster-footer(
  footer-left: none,
  footer-center: none,
  footer-right: none,
  footer-logo-left: none,
  footer-logo-right: none,
  logo-height: 70%,
  padding: (x: 0.45in, y: 0.18in),
  radius: 0pt,
  theme: (:),
) = {
  block(width: 100%, height: 100%, inset: padding, radius: radius, fill: theme.footer-bg)[
    #align(center + horizon)[
      #set text(size: theme.footer-size, fill: theme.footer-fg)
      #grid(
        columns: (1fr, auto, 1fr),
        column-gutter: 0.35in,
        align: (left + horizon, center + horizon, right + horizon),
        [#footer-item(footer-left, logo: footer-logo-left, logo-height: logo-height)],
        [
          #set text(weight: "semibold")
          #safe-content(footer-center)
        ],
        [#footer-item(footer-right, logo: footer-logo-right, reverse: true, logo-height: logo-height)],
      )
    ]
  ]
}

#let poster(
  body,
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

  paper-size: (width: 48in, height: 36in),
  margin: (x: 1in, y: 0.75in),
  column-layout: "flow",
  column-count: 3,
  column-gap: 0.5in,

  font-family: "Libertinus Serif",
  font-size: 22pt,
  line-spacing: 1.15em,

  header-height: 17%,
  footer-height: 8%,
  row-gap: 0.35in,
  logo-width: 16%,
  logo-height: 86%,
  footer-logo-height: 70%,
  header-padding: (x: 0.45in, y: 0.25in),
  footer-padding: (x: 0.45in, y: 0.18in),
  corner-radius: 0pt,

  theme: (
    background: white,
    foreground: rgb("#17212b"),
    primary: rgb("#b01c32"),
    secondary: rgb("#6f1020"),
    accent: rgb("#f4c7cf"),
    header-bg: rgb("#b01c32"),
    header-fg: white,
    title-fg: white,
    subtitle-fg: white,
    section-bg: rgb("#b01c32"),
    section-fg: white,
    subsection-bg: rgb("#f8e8eb"),
    subsection-fg: rgb("#6f1020"),
    footer-bg: rgb("#b01c32"),
    footer-fg: white,
    title-size: 1.85em,
    subtitle-size: 0.86em,
    author-size: 0.72em,
    institution-size: 0.62em,
    footer-size: 0.58em,
    h1-size: 1.06em,
    h2-size: 0.94em,
    h3-size: 0.9em,
  ),
) = {
  set page(
    width: paper-size.width,
    height: paper-size.height,
    margin: margin,
    fill: theme.background,
    numbering: none,
  )
  set text(font: font-family, size: font-size, fill: theme.foreground)
  set par(justify: false, leading: line-spacing)

  show heading.where(level: 1): it => [
    #block(width: 100%, inset: (x: 0.45em, y: 0.25em), radius: 5pt, fill: theme.section-bg)[
      #set text(fill: theme.section-fg, weight: "bold", size: theme.h1-size)
      #upper(it.body)
    ]
    #v(0.18em)
  ]

  show heading.where(level: 2): it => [
    #block(width: 100%, inset: (x: 0.4em, y: 0.22em), radius: 4pt, fill: theme.subsection-bg)[
      #set text(fill: theme.subsection-fg, weight: "semibold", size: theme.h2-size)
      #it.body
    ]
    #v(0.14em)
  ]

  show heading.where(level: 3): it => [
    #block(width: 100%)[
      #set text(fill: theme.secondary, weight: "semibold", size: theme.h3-size)
      #it.body
    ]
    #v(0.08em)
  ]

  block(width: 100%, height: 100%)[
    #grid(
      columns: (1fr,),
      rows: (header-height, 1fr, footer-height),
      row-gutter: row-gap,
      [
        #poster-header(
          title: title,
          subtitle: subtitle,
          authors: authors,
          institutions: institutions,
          logo-left: logo-left,
          logo-right: logo-right,
          logo-width: logo-width,
          logo-height: logo-height,
          padding: header-padding,
          radius: corner-radius,
          theme: theme,
        )
      ],
      [
        #block(width: 100%, height: 100%)[
          #poster-body(
            body,
            column-layout: column-layout,
            column-count: column-count,
            column-gap: column-gap,
          )
        ]
      ],
      [
        #poster-footer(
          footer-left: footer-left,
          footer-center: footer-center,
          footer-right: footer-right,
          footer-logo-left: footer-logo-left,
          footer-logo-right: footer-logo-right,
          logo-height: footer-logo-height,
          padding: footer-padding,
          radius: corner-radius,
          theme: theme,
        )
      ],
    )
  ]
}
