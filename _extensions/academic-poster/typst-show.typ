#import "typst-template.typ": poster, poster-card, poster-callout, poster-feature-column, poster-grid

#show: poster.with(
  title: $if(title)$[$title$]$else$none$endif$,
  subtitle: $if(subtitle)$[$subtitle$]$else$none$endif$,

  authors: $if(author)$[$for(author)$$if(it.name)$$it.name.literal$$else$$it$$endif$$sep$ · $endfor$]$else$none$endif$,
  institutions: $if(resolved-institutions)$[$resolved-institutions$]$else$none$endif$,

  logo-left: $if(logo-left)$"$logo-left$"$else$none$endif$,
  logo-right: $if(logo-right)$"$logo-right$"$else$none$endif$,

  footer-left: $if(footer-left)$[$footer-left$]$else$none$endif$,
  footer-center: $if(footer-center)$[$footer-center$]$else$none$endif$,
  footer-right: $if(footer-right)$[$footer-right$]$else$none$endif$,
  footer-logo-left: $if(footer-logo-left)$"$footer-logo-left$"$else$none$endif$,
  footer-logo-right: $if(footer-logo-right)$"$footer-logo-right$"$else$none$endif$,

  // Paper + margins (Lua resolves poster-size aliases into _poster-width/_poster-height)
  paper-size: (
    width: $resolved-poster-width$,
    height: $resolved-poster-height$,
  ),
  margin: (
    $if(margin.left)$left: $margin.left$,$endif$
    $if(margin.right)$right: $margin.right$,$endif$
    $if(margin.top)$top: $margin.top$,$endif$
    $if(margin.bottom)$bottom: $margin.bottom$,$endif$
    x: $if(margin.x)$$margin.x$$else$0.55in$endif$,
    y: $if(margin.y)$$margin.y$$else$0.45in$endif$,
  ),

  // Body layout
  column-layout: "$resolved-column-layout$",
  column-count: $resolved-column-count$,

  // Quarto-native typography knobs
  font-family: "$if(mainfont)$$mainfont$$else$Libertinus Serif$endif$",
  font-size: $if(fontsize)$$fontsize$$else$22pt$endif$,
  line-spacing: $if(poster-line-spacing)$$poster-line-spacing$$else$1.15em$endif$,

  // One-knob scale + per-key override dicts (built by the Lua filter).
  // The colors dict pulls brand-color values first, then spreads user
  // `poster-colors:` overrides on top.
  scale: "$if(poster-scale)$$poster-scale$$else$default$endif$",
  typography: $resolved-typography$,
  spacing: $resolved-spacing$,
  colors: (
    background: brand-color.at("background", default: white),
    foreground: brand-color.at("foreground", default: rgb("#17212b")),
    primary: brand-color.at("primary", default: rgb("#b01c32")),
    secondary: brand-color.at("secondary", default: rgb("#6f1020")),
    accent: brand-color.at("tertiary", default: rgb("#f4c7cf")),
    light: brand-color.at("light", default: rgb("#f8e8eb")),
    ..$resolved-colors$,
  ),

  // Structural rows (these accept % of the body grid)
  header-height: $if(poster-header-height)$$poster-header-height$$else$15%$endif$,
  footer-height: $if(poster-footer-height)$$poster-footer-height$$else$7%$endif$,
  logo-width: $if(poster-logo-width)$$poster-logo-width$$else$14%$endif$,
  logo-height: $if(poster-logo-height)$$poster-logo-height$$else$86%$endif$,
  footer-logo-height: $if(poster-footer-logo-height)$$poster-footer-logo-height$$else$70%$endif$,
)
