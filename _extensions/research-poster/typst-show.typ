#import "typst-template.typ": poster

#show: poster.with(
  title: [$title$],
  subtitle: [$if(subtitle)$$subtitle$$endif$],
  authors: "$for(author)$$if(it.name)$$it.name.literal$$else$$it$$endif$$sep$, $endfor$",
  institutions: "$for(author)$$for(it.affiliation)$$if(it.name)$$it.name$$else$$it$$endif$$sep$, $endfor$$sep$, $endfor$",

  logo-left: $if(logo-left)$"$logo-left$"$else$none$endif$,
  logo-right: $if(logo-right)$"$logo-right$"$else$none$endif$,

  footer-left: [$if(footer-left)$$footer-left$$endif$],
  footer-center: [$if(footer-center)$$footer-center$$endif$],
  footer-right: [$if(footer-right)$$footer-right$$endif$],

  paper-size: (
    width: $if(poster-width)$$poster-width$$else$48in$endif$,
    height: $if(poster-height)$$poster-height$$else$36in$endif$,
  ),
  margin: (
    x: $if(poster-margin-x)$$poster-margin-x$$else$1in$endif$,
    y: $if(poster-margin-y)$$poster-margin-y$$else$0.75in$endif$,
  ),

  column-count: $if(poster-columns)$$poster-columns$$else$3$endif$,
  column-gap: $if(poster-column-gap)$$poster-column-gap$$else$0.5in$endif$,
  column-widths: ($if(poster-column-widths)$$for(poster-column-widths)$$it$$sep$, $endfor$$endif$),

  font-family: "$if(mainfont)$$mainfont$$else$Libertinus Serif$endif$",
  font-size: $if(font-size)$$font-size$$else$22pt$endif$,

  header-height: $if(poster-header-height)$$poster-header-height$$else$17%$endif$,
  footer-height: $if(poster-footer-height)$$poster-footer-height$$else$8%$endif$,

  theme: (
    background: $if(poster-background)$$poster-background$$else$white$endif$,
    foreground: $if(poster-foreground)$$poster-foreground$$else$rgb("#17212b")$endif$,
    primary: $if(poster-primary)$$poster-primary$$else$rgb("#0d3b66")$endif$,
    secondary: $if(poster-secondary)$$poster-secondary$$else$rgb("#2a9d8f")$endif$,
    accent: $if(poster-accent)$$poster-accent$$else$rgb("#e76f51")$endif$,
    section-bg: $if(poster-section-bg)$$poster-section-bg$$else$rgb("#e9f0f8")$endif$,
    section-fg: $if(poster-section-fg)$$poster-section-fg$$else$rgb("#0d3b66")$endif$,
    footer-bg: $if(poster-footer-bg)$$poster-footer-bg$$else$rgb("#0d3b66")$endif$,
    footer-fg: $if(poster-footer-fg)$$poster-footer-fg$$else$white$endif$,
  ),
)

$body$
