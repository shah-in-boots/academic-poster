#import "typst-template.typ": poster, poster-card, poster-callout, poster-feature-column, poster-grid

#show: poster.with(
  title: $if(title)$[$title$]$else$none$endif$,
  subtitle: $if(subtitle)$[$subtitle$]$else$none$endif$,

  authors: $if(poster-authors)$[$poster-authors$]$else$$if(author)$[$for(author)$$if(it.name)$$it.name.literal$$else$$it$$endif$$sep$ · $endfor$]$else$none$endif$$endif$,
  institutions: $if(institutions)$[$for(institutions)$$it$$sep$ · $endfor$]$else$$if(institution)$[$for(institution)$$it$$sep$ · $endfor$]$else$$if(departments)$[$for(departments)$$it$$sep$ · $endfor$]$else$$if(author)$[$for(author)$$for(it.affiliation)$$if(it.name)$$it.name$$else$$it$$endif$$sep$ · $endfor$$sep$ · $endfor$]$else$none$endif$$endif$$endif$$endif$,

  logo-left: $if(logo-left)$"$logo-left$"$else$$if(logo)$"$logo$"$else$none$endif$$endif$,
  logo-right: $if(logo-right)$"$logo-right$"$else$$if(institution-logo)$"$institution-logo$"$else$none$endif$$endif$,

  footer-left: $if(footer-left)$[$footer-left$]$else$none$endif$,
  footer-center: $if(footer-center)$[$footer-center$]$else$$if(footer-text)$[$footer-text$]$else$none$endif$$endif$,
  footer-right: $if(footer-right)$[$footer-right$]$else$$if(footer-emails)$[$footer-emails$]$else$none$endif$$endif$,
  footer-logo-left: $if(footer-logo-left)$"$footer-logo-left$"$else$none$endif$,
  footer-logo-right: $if(footer-logo-right)$"$footer-logo-right$"$else$none$endif$,

  paper-size: (
    width: $if(poster-width)$$poster-width$$else$48in$endif$,
    height: $if(poster-height)$$poster-height$$else$36in$endif$,
  ),
  margin: (
    $if(margin.left)$left: $margin.left$,$endif$
    $if(margin.right)$right: $margin.right$,$endif$
    $if(margin.top)$top: $margin.top$,$endif$
    $if(margin.bottom)$bottom: $margin.bottom$,$endif$
    x: $if(margin.x)$$margin.x$$else$$if(poster-margin-x)$$poster-margin-x$$else$1in$endif$$endif$,
    y: $if(margin.y)$$margin.y$$else$$if(poster-margin-y)$$poster-margin-y$$else$0.75in$endif$$endif$,
  ),

  column-layout: "$if(poster-manual-columns)$manual$else$$if(poster-column-layout)$$poster-column-layout$$else$flow$endif$$endif$",
  column-count: $if(columns)$$columns$$else$$if(poster-columns)$$poster-columns$$else$3$endif$$endif$,
  column-gap: $if(poster-column-gap)$$poster-column-gap$$else$0.5in$endif$,

  font-family: "$if(mainfont)$$mainfont$$else$Libertinus Serif$endif$",
  font-size: $if(fontsize)$$fontsize$$else$$if(font-size)$$font-size$$else$22pt$endif$$endif$,
  line-spacing: $if(poster-line-spacing)$$poster-line-spacing$$else$1.15em$endif$,

  header-height: $if(poster-header-height)$$poster-header-height$$else$17%$endif$,
  footer-height: $if(poster-footer-height)$$poster-footer-height$$else$8%$endif$,
  row-gap: $if(poster-row-gap)$$poster-row-gap$$else$0.35in$endif$,
  logo-width: $if(poster-logo-width)$$poster-logo-width$$else$16%$endif$,
  logo-height: $if(poster-logo-height)$$poster-logo-height$$else$86%$endif$,
  footer-logo-height: $if(poster-footer-logo-height)$$poster-footer-logo-height$$else$70%$endif$,
  header-padding: (
    x: $if(poster-header-padding-x)$$poster-header-padding-x$$else$0.45in$endif$,
    y: $if(poster-header-padding-y)$$poster-header-padding-y$$else$0.25in$endif$,
  ),
  footer-padding: (
    x: $if(poster-footer-padding-x)$$poster-footer-padding-x$$else$0.45in$endif$,
    y: $if(poster-footer-padding-y)$$poster-footer-padding-y$$else$0.18in$endif$,
  ),
  corner-radius: $if(poster-corner-radius)$$poster-corner-radius$$else$0pt$endif$,

  theme: (
    background: $if(poster-background)$$poster-background$$else$brand-color.at("background", default: white)$endif$,
    foreground: $if(poster-foreground)$$poster-foreground$$else$brand-color.at("foreground", default: rgb("#17212b"))$endif$,
    primary: $if(poster-primary)$$poster-primary$$else$brand-color.at("primary", default: rgb("#b01c32"))$endif$,
    secondary: $if(poster-secondary)$$poster-secondary$$else$brand-color.at("secondary", default: rgb("#6f1020"))$endif$,
    accent: $if(poster-accent)$$poster-accent$$else$brand-color.at("tertiary", default: rgb("#f4c7cf"))$endif$,
    header-bg: $if(poster-header-bg)$$poster-header-bg$$else$$if(poster-primary)$$poster-primary$$else$brand-color.at("primary", default: rgb("#b01c32"))$endif$$endif$,
    header-fg: $if(poster-header-fg)$$poster-header-fg$$else$white$endif$,
    title-fg: $if(poster-title-fg)$$poster-title-fg$$else$white$endif$,
    subtitle-fg: $if(poster-subtitle-fg)$$poster-subtitle-fg$$else$white$endif$,
    section-bg: $if(poster-section-bg)$$poster-section-bg$$else$$if(poster-primary)$$poster-primary$$else$brand-color.at("primary", default: rgb("#b01c32"))$endif$$endif$,
    section-fg: $if(poster-section-fg)$$poster-section-fg$$else$white$endif$,
    subsection-bg: $if(poster-subsection-bg)$$poster-subsection-bg$$else$brand-color.at("light", default: rgb("#f8e8eb"))$endif$,
    subsection-fg: $if(poster-subsection-fg)$$poster-subsection-fg$$else$$if(poster-secondary)$$poster-secondary$$else$brand-color.at("secondary", default: rgb("#6f1020"))$endif$$endif$,
    footer-bg: $if(poster-footer-bg)$$poster-footer-bg$$else$$if(footer-color)$rgb("#$footer-color$")$else$$if(poster-primary)$$poster-primary$$else$brand-color.at("primary", default: rgb("#b01c32"))$endif$$endif$$endif$,
    footer-fg: $if(poster-footer-fg)$$poster-footer-fg$$else$white$endif$,
    title-size: $if(poster-title-size)$$poster-title-size$$else$1.85em$endif$,
    subtitle-size: $if(poster-subtitle-size)$$poster-subtitle-size$$else$0.86em$endif$,
    author-size: $if(poster-author-size)$$poster-author-size$$else$0.72em$endif$,
    institution-size: $if(poster-institution-size)$$poster-institution-size$$else$0.62em$endif$,
    footer-size: $if(poster-footer-size)$$poster-footer-size$$else$0.58em$endif$,
    h1-size: $if(poster-h1-size)$$poster-h1-size$$else$1.06em$endif$,
    h2-size: $if(poster-h2-size)$$poster-h2-size$$else$0.94em$endif$,
    h3-size: $if(poster-h3-size)$$poster-h3-size$$else$0.9em$endif$,
  ),
)
