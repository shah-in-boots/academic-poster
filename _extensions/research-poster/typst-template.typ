#let split-csv(value) = {
  if type(value) == array {
    value
  } else if value == none {
    ()
  } else {
    let text-value = str(value)
    text-value.split(",").map(v => v.trim()).filter(v => v != "")
  }
}

#let norm-ratios(ratios, fallback: (1fr, 1fr, 1fr)) = {
  if type(ratios) == array and ratios.len() > 0 {
    ratios.map(r => {
      if type(r) == ratio {
        r
      } else if type(r) == int or type(r) == float {
        r * 1fr
      } else {
        1fr
      }
    })
  } else {
    fallback
  }
}

#let poster(
  body,
  title: none,
  subtitle: none,
  authors: (),
  institutions: (),
  logo-left: none,
  logo-right: none,
  footer-center: none,
  footer-left: none,
  footer-right: none,

  paper-size: (width: 48in, height: 36in),
  margin: (x: 1in, y: 0.75in),
  column-count: 3,
  column-gap: 0.5in,
  column-widths: (),

  font-family: "Libertinus Serif",
  font-size: 22pt,
  line-spacing: 1.15em,

  theme: (
    background: white,
    foreground: rgb("#17212b"),
    primary: rgb("#0d3b66"),
    secondary: rgb("#2a9d8f"),
    accent: rgb("#e76f51"),
    section-bg: rgb("#e9f0f8"),
    section-fg: rgb("#0d3b66"),
    footer-bg: rgb("#0d3b66"),
    footer-fg: white,
  ),

  header-height: 17%,
  footer-height: 8%,
) = {
  set page(width: paper-size.width, height: paper-size.height, margin: margin, fill: theme.background)
  set text(font: font-family, size: font-size, fill: theme.foreground)
  set par(justify: false, leading: line-spacing)

  show heading.where(level: 1): it => {
    block(width: 100%, inset: (x: 0.45em, y: 0.25em), radius: 5pt, fill: theme.primary)[
      #set text(fill: white, weight: "bold", size: 1.06em)
      #upper(it.body)
    ]
  }

  show heading.where(level: 2): it => {
    block(width: 100%, inset: (x: 0.4em, y: 0.22em), radius: 4pt, fill: theme.section-bg)[
      #set text(fill: theme.section-fg, weight: "semibold", size: 0.94em)
      #it.body
    ]
  }

  show heading.where(level: 3): it => {
    block(width: 100%)[
      #set text(fill: theme.secondary, weight: "semibold", size: 0.9em)
      #it.body
    ]
  }

  let normalized-columns = if column-widths != () {
    norm-ratios(column-widths)
  } else {
    (1fr,) * column-count
  }

  let author-list = split-csv(authors)
  let institution-list = split-csv(institutions)

  grid(
    rows: (header-height, 1fr, footer-height),
    columns: (1fr,),
    row-gutter: 0.4in,
    [
      grid(
        columns: (18%, 64%, 18%),
        align: (left + horizon, center + horizon, right + horizon),
        [
          if logo-left != none {
            image(logo-left, height: 92%)
          }
        ],
        [
          align(center + horizon)[
            #set text(weight: "bold", size: 1.8em, fill: theme.primary)
            #title
            if subtitle != none [
              #v(0.2em)
              #set text(weight: "regular", size: 0.86em, fill: theme.secondary)
              #subtitle
            ]
            if author-list.len() > 0 [
              #v(0.24em)
              #set text(weight: "medium", size: 0.72em, fill: theme.foreground)
              #author-list.join(" · ")
            ]
            if institution-list.len() > 0 [
              #v(0.2em)
              #set text(weight: "regular", size: 0.64em, fill: theme.foreground)
              #institution-list.join(" • ")
            ]
          ]
        ],
        [
          if logo-right != none {
            align(right + horizon)[
              #image(logo-right, height: 92%)
            ]
          }
        ],
      )
    ],
    [
      columns(
        count: normalized-columns.len(),
        gutter: column-gap,
        ..normalized-columns,
        body,
      )
    ],
    [
      block(width: 100%, inset: (x: 0.5em, y: 0.35em), radius: 4pt, fill: theme.footer-bg)[
        #grid(
          columns: (1fr, auto, 1fr),
          align: (left + horizon, center + horizon, right + horizon),
          [#set text(size: 0.58em, fill: theme.footer-fg) #footer-left],
          [#set text(size: 0.6em, fill: theme.footer-fg, weight: "semibold") #footer-center],
          [#set text(size: 0.58em, fill: theme.footer-fg) #footer-right],
        )
      ]
    ],
  )
}
