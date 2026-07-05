-- academic-poster: structural Pandoc -> Typst transform.
--
-- Responsibilities (kept deliberately narrow):
--   1. Resolve `poster-size` / paper presets into width + height.
--   2. Resolve preset options into layout/style/density choices.
--   3. Resolve an automatic paper-aware base font size.
--   4. Build typography/spacing/colors dict literals from nested YAML maps
--      so typst-show.typ can splice them in verbatim.
--   5. Convert `.poster-column` Divs into a `#poster-grid(...)` call.
--   6. Wrap level-1 headings in `#poster-card(role: ..., variant: ...)[...]`.
--   7. Convert `.poster-callout` Divs into `#poster-callout(...)[...]`.
--
-- All sizing, color, and inset *defaults* live in typst-template.typ. This
-- filter does not compute em values — it only decides which role a block
-- plays (card / card-compact / callout-large / ...) and which color variant
-- it uses (primary / secondary / light / ...).

-- ---------------------------------------------------------------------------
-- Meta helpers
-- ---------------------------------------------------------------------------

local function has_class(block, class)
  if block.t ~= "Div" and block.t ~= "Header" then return false end
  for _, value in ipairs(block.classes) do
    if value == class then return true end
  end
  return false
end

local function meta_string(meta, key)
  local value = meta[key]
  if value == nil then return nil end
  if type(value) == "string" then return value end
  return pandoc.utils.stringify(value)
end

local function meta_list(meta, key)
  local value = meta[key]
  if value == nil then return nil end
  if type(value) == "table" and value.t == "MetaList" then
    local result = {}
    for _, item in ipairs(value) do
      table.insert(result, pandoc.utils.stringify(item))
    end
    return result
  end
  if type(value) == "table" and #value > 0 then
    local result = {}
    for _, item in ipairs(value) do
      table.insert(result, pandoc.utils.stringify(item))
    end
    return result
  end
  return { pandoc.utils.stringify(value) }
end

local function warn(message)
  io.stderr:write("[academic-poster] " .. message .. "\n")
end

local function canonical(value)
  if value == nil then return nil end
  local key = tostring(value):lower()
  key = key:gsub("^%s+", ""):gsub("%s+$", "")
  key = key:gsub("_", "-"):gsub("%s+", "-")
  if key == "" then return nil end
  return key
end

-- ---------------------------------------------------------------------------
-- Preset option resolution
-- ---------------------------------------------------------------------------

local LAYOUT_PRESETS = {
  ["three-column"] = {count = 3, columns = {"1fr", "1fr", "1fr"}},
  ["two-column"] = {count = 2, columns = {"1fr", "1fr"}},
  ["feature-center"] = {count = 3, columns = {"0.95fr", "1.35fr", "0.95fr"}},
  ["feature-right"] = {count = 3, columns = {"1fr", "1fr", "1.25fr"}},
  ["flow"] = {count = 3},
}

local LAYOUT_ALIASES = {
  ["3-column"] = "three-column",
  ["3-col"] = "three-column",
  ["three-col"] = "three-column",
  ["three"] = "three-column",
  ["2-column"] = "two-column",
  ["2-col"] = "two-column",
  ["two-col"] = "two-column",
  ["two"] = "two-column",
  ["feature"] = "feature-center",
  ["results"] = "feature-center",
  ["results-first"] = "feature-center",
}

local STYLE_PRESETS = {
  clean = true,
  classic = true,
  bold = true,
  minimal = true,
}

local STYLE_ALIASES = {
  default = "clean",
  result = "bold",
  results = "bold",
  ["results-first"] = "bold",
}

local DENSITY_PRESETS = {
  compact = true,
  default = true,
  spacious = true,
}

local PRESET_OPTIONS = {
  default = {layout = "three-column", style = "clean", density = "default"},
  clean = {layout = "three-column", style = "clean", density = "default"},
  classic = {layout = "three-column", style = "classic", density = "default"},
  ["results-first"] = {layout = "feature-center", style = "bold", density = "compact"},
  ["methods-heavy"] = {layout = "two-column", style = "clean", density = "compact"},
  minimal = {layout = "three-column", style = "minimal", density = "default"},
}

local PRESET_ALIASES = {
  results = "results-first",
  feature = "results-first",
  methods = "methods-heavy",
}

local function normalize_option(value, known, aliases, fallback, label)
  local key = canonical(value)
  if key == nil then return fallback end
  key = aliases[key] or key
  if known[key] ~= nil then return key end
  warn("Unknown " .. label .. " '" .. tostring(value) .. "'; using '" .. fallback .. "'.")
  return fallback
end

local function resolve_options(meta)
  local preset_name = normalize_option(
    meta_string(meta, "poster-preset"),
    PRESET_OPTIONS,
    PRESET_ALIASES,
    "default",
    "poster-preset"
  )
  local preset = PRESET_OPTIONS[preset_name]

  local layout = normalize_option(
    meta_string(meta, "poster-layout"),
    LAYOUT_PRESETS,
    LAYOUT_ALIASES,
    preset.layout,
    "poster-layout"
  )
  local style = normalize_option(
    meta_string(meta, "poster-style"),
    STYLE_PRESETS,
    STYLE_ALIASES,
    preset.style,
    "poster-style"
  )
  local density_value = meta_string(meta, "poster-density") or meta_string(meta, "poster-scale")
  local density = normalize_option(
    density_value,
    DENSITY_PRESETS,
    {},
    preset.density,
    "poster-density"
  )

  return {
    preset = preset_name,
    layout = layout,
    style = style,
    density = density,
  }
end

-- ---------------------------------------------------------------------------
-- Paper size resolution
-- ---------------------------------------------------------------------------

local PAPER_PRESETS = {
  ["a0"] = {width = "841mm", height = "1189mm"},
  ["a0-landscape"] = {width = "1189mm", height = "841mm"},
  ["a1"] = {width = "594mm", height = "841mm"},
  ["a1-landscape"] = {width = "841mm", height = "594mm"},
  ["a2"] = {width = "420mm", height = "594mm"},
  ["a2-landscape"] = {width = "594mm", height = "420mm"},
  ["a3"] = {width = "297mm", height = "420mm"},
  ["a3-landscape"] = {width = "420mm", height = "297mm"},
}

local function resolve_paper_size(meta)
  local size = meta_string(meta, "poster-size")
  if size then
    local lower = size:lower():gsub("%s+", "")
    if PAPER_PRESETS[lower] then
      local p = PAPER_PRESETS[lower]
      return p.width, p.height
    end
    -- "WxH<unit>" form, e.g. "48x36in", "56x31.5in", "120x90cm"
    local w, h, unit = lower:match("^([%d%.]+)x([%d%.]+)(%a+)$")
    if w and h and unit then
      return w .. unit, h .. unit
    end
    warn("Could not parse poster-size '" .. size .. "'; using poster-width/poster-height or 48in x 36in.")
  end

  local width = meta_string(meta, "poster-width") or "48in"
  local height = meta_string(meta, "poster-height") or "36in"
  return width, height
end

-- ---------------------------------------------------------------------------
-- Paper-aware type size
-- ---------------------------------------------------------------------------

local UNIT_TO_INCHES = {
  ["in"] = 1,
  ["cm"] = 1 / 2.54,
  ["mm"] = 1 / 25.4,
  ["pt"] = 1 / 72,
}

local function length_to_inches(value)
  if value == nil then return nil end
  local raw = tostring(value):lower():gsub("%s+", "")
  local n, unit = raw:match("^([%d%.]+)(%a+)$")
  if n == nil or unit == nil or UNIT_TO_INCHES[unit] == nil then return nil end
  return tonumber(n) * UNIT_TO_INCHES[unit]
end

local function format_pt(value)
  local rounded = math.floor(value * 10 + 0.5) / 10
  if rounded == math.floor(rounded) then
    return tostring(math.floor(rounded)) .. "pt"
  end
  return tostring(rounded) .. "pt"
end

local function clamp(value, lower, upper)
  if value < lower then return lower end
  if value > upper then return upper end
  return value
end

local function auto_font_size(width, height)
  local w = length_to_inches(width)
  local h = length_to_inches(height)
  if w == nil or h == nil then return "36pt" end

  -- A readable poster body size tracks the shorter paper side more reliably
  -- than a fixed default. Density presets still apply after this base size.
  local short_side = math.min(w, h)
  return format_pt(clamp(short_side * 1.1, 24, 44))
end

local function resolve_font_size(meta, width, height)
  local explicit =
    meta_string(meta, "poster-font-size") or
    meta_string(meta, "poster-fontsize") or
    meta_string(meta, "fontsize")

  if explicit and canonical(explicit) ~= "auto" then return explicit end
  return auto_font_size(width, height)
end

-- ---------------------------------------------------------------------------
-- Column widths
-- ---------------------------------------------------------------------------

local function equal_tracks(count)
  local tracks = {}
  for _ = 1, count do table.insert(tracks, "1fr") end
  return tracks
end

local function tracks_literal(tracks)
  return "(" .. table.concat(tracks, ", ") .. ")"
end

local function normalize_track(value)
  if value == nil or value == "" then return "1fr" end
  -- Already has a unit (em, in, cm, pt, mm, %, fr)
  if value:match("[a-zA-Z%%]") then return value end
  return value .. "fr"
end

local function explicit_column_widths(meta)
  return meta_list(meta, "poster-columns") or meta_list(meta, "poster-column-widths")
end

local function column_widths_literal(meta, count, layout)
  local widths = explicit_column_widths(meta)
  if widths == nil or #widths == 0 or (#widths == 1 and tonumber(widths[1])) then
    -- Single integer column counts always mean equal columns. If widths are
    -- absent, layout presets may provide a more opinionated default.
    if widths and #widths == 1 then
      return tracks_literal(equal_tracks(tonumber(widths[1])))
    end

    local preset = LAYOUT_PRESETS[layout]
    if preset and preset.columns and #preset.columns == count then
      return tracks_literal(preset.columns)
    end
    if preset and preset.columns and #preset.columns ~= count then
      warn("Layout '" .. layout .. "' defines " .. tostring(#preset.columns) ..
        " columns but the document has " .. tostring(count) .. "; using equal widths.")
    end
    return tracks_literal(equal_tracks(count))
  end

  local tracks = {}
  for _, w in ipairs(widths) do table.insert(tracks, normalize_track(w)) end
  if count and #tracks ~= count then
    warn("poster-columns defines " .. tostring(#tracks) ..
      " widths but the document has " .. tostring(count) .. " .poster-column blocks.")
  end
  return tracks_literal(tracks)
end

local function column_count(meta, layout)
  local widths = explicit_column_widths(meta)
  if widths and #widths == 1 and tonumber(widths[1]) then
    return tonumber(widths[1])
  end
  if widths and #widths > 1 then return #widths end
  local preset = LAYOUT_PRESETS[layout]
  return (preset and preset.count) or 3
end

-- ---------------------------------------------------------------------------
-- Nested YAML map -> Typst dict literal
-- ---------------------------------------------------------------------------

-- A value coming from YAML may look like a literal Typst expression (e.g.
-- "1.1em", "rgb(\"#b01c32\")"), a color hex ("#b01c32"), or a bare number.
-- This function emits the Typst-side representation.
local map_to_dict_literal

local function is_meta_map(value)
  if type(value) ~= "table" then return false end
  if value.t ~= nil and value.t ~= "MetaMap" then return false end
  if #value > 0 then return false end
  for k, _ in pairs(value) do
    if k ~= "t" and k ~= "c" then return true end
  end
  return false
end

local function typst_value(raw)
  if raw == nil then return "none" end
  if is_meta_map(raw) then return map_to_dict_literal(raw) end
  local s = pandoc.utils.stringify(raw)
  if s == "" then return "none" end

  -- Already a Typst expression: rgb(...), em, pt, in, cm, mm, %, fr, none, true, false, white, black
  if s:match("^rgb%(") or s:match("^cmyk%(") or s:match("^luma%(") then return s end
  if s:match("[%d%.]+%s*[a-zA-Z%%]+$") then return s end
  if s == "none" or s == "true" or s == "false" or s == "auto" then return s end
  if s == "white" or s == "black" then return s end

  -- Hex color: "#rgb" / "#rrggbb"
  if s:match("^#[%x][%x][%x]$") or s:match("^#[%x][%x][%x][%x][%x][%x]$") then
    return 'rgb("' .. s .. '")'
  end

  -- A bare number (no unit) — leave as-is for things like font factors
  if tonumber(s) then return s end

  -- Fall back: assume it's already a valid Typst expression
  return s
end

-- Quote dict keys; em-keys with hyphens need quoting.
local function dict_key(k)
  return '"' .. k .. '"'
end

map_to_dict_literal = function(meta_value)
  if meta_value == nil then return "(:)" end
  if type(meta_value) ~= "table" then return "(:)" end

  local entries = {}
  -- MetaMap in Pandoc is iterable as a table; preserve insertion order
  local keys = {}
  for k, _ in pairs(meta_value) do
    if k ~= "t" and k ~= "c" then table.insert(keys, k) end
  end
  table.sort(keys)

  for _, k in ipairs(keys) do
    local v = meta_value[k]
    table.insert(entries, dict_key(k) .. ": " .. typst_value(v))
  end

  if #entries == 0 then return "(:)" end
  return "(" .. table.concat(entries, ", ") .. ")"
end

-- ---------------------------------------------------------------------------
-- Role + variant detection
-- ---------------------------------------------------------------------------

local function card_role(block)
  if has_class(block, "large") then return "card-large" end
  if has_class(block, "compact") then return "card-compact" end
  return "card"
end

local function callout_role(block)
  if has_class(block, "large") then return "callout-large" end
  if has_class(block, "compact") then return "callout-compact" end
  return "callout"
end

local VARIANT_CLASSES = {"secondary", "accent", "light", "dark", "inverse"}

local function variant_of(block)
  for _, name in ipairs(VARIANT_CLASSES) do
    if has_class(block, name) then return name end
  end
  if has_class(block, "muted") then return "light" end
  return "primary"
end

-- ---------------------------------------------------------------------------
-- Inline / block helpers
-- ---------------------------------------------------------------------------

local function inlines_to_typst(inlines)
  local doc = pandoc.Pandoc({ pandoc.Plain(inlines) })
  return pandoc.write(doc, "typst"):gsub("%s+$", "")
end

local function append_all(target, source)
  for _, block in ipairs(source) do target:insert(block) end
end

local function raw_wrap(start, content, finish)
  local blocks = pandoc.List()
  blocks:insert(pandoc.RawBlock("typst", start))
  append_all(blocks, content)
  blocks:insert(pandoc.RawBlock("typst", finish))
  return blocks
end

-- ---------------------------------------------------------------------------
-- Block transformation
-- ---------------------------------------------------------------------------

local wrap_columns -- forward declaration

local function transform_blocks(blocks, meta)
  local out = pandoc.List()
  local index = 1

  while index <= #blocks do
    local block = blocks[index]

    if block.t == "Div" and has_class(block, "poster-column") then
      local column_divs = {}
      while index <= #blocks and blocks[index].t == "Div" and has_class(blocks[index], "poster-column") do
        local div = blocks[index]
        div.content = transform_blocks(div.content, meta)
        table.insert(column_divs, div)
        index = index + 1
      end
      append_all(out, wrap_columns(column_divs, meta))

    elseif block.t == "Header" and block.level == 1 then
      if has_class(block, "plain") or has_class(block, "no-card") then
        out:insert(block)
        index = index + 1
      else
        local title = inlines_to_typst(block.content)
        local role = card_role(block)
        local variant = variant_of(block)
        local section = pandoc.List()
        index = index + 1

        while index <= #blocks do
          local next_block = blocks[index]
          if next_block.t == "Header" and next_block.level == 1 then break end
          if next_block.t == "Div" and has_class(next_block, "poster-column") then break end
          append_all(section, transform_blocks(pandoc.List({ next_block }), meta))
          index = index + 1
        end

        local start = string.format(
          '#poster-card(title: [%s], role: "%s", variant: "%s")[',
          title, role, variant
        )
        append_all(out, raw_wrap(start, section, "]"))
      end

    elseif block.t == "Div" and has_class(block, "poster-callout") then
      local content = transform_blocks(block.content, meta)
      local role = callout_role(block)
      local variant = variant_of(block)
      local start = string.format(
        '#poster-callout(role: "%s", variant: "%s")[',
        role, variant
      )
      append_all(out, raw_wrap(start, content, "]"))
      index = index + 1

    elseif block.t == "Div" then
      block.content = transform_blocks(block.content, meta)
      out:insert(block)
      index = index + 1

    else
      out:insert(block)
      index = index + 1
    end
  end

  return out
end

wrap_columns = function(column_divs, meta)
  local blocks = pandoc.List()
  local layout = meta_string(meta, "resolved-poster-layout") or "three-column"
  local widths = column_widths_literal(meta, #column_divs, layout)

  blocks:insert(pandoc.RawBlock("typst",
    "#poster-grid(\n  columns: " .. widths .. ",\n  ["))

  for column_index, div in ipairs(column_divs) do
    local featured = has_class(div, "poster-feature") or has_class(div, "feature")
    local variant = variant_of(div)

    if featured then
      blocks:insert(pandoc.RawBlock("typst",
        '#poster-feature-column(variant: "' .. variant .. '")['))
    end

    append_all(blocks, div.content)

    if featured then
      blocks:insert(pandoc.RawBlock("typst", "]"))
    end

    if column_index < #column_divs then
      blocks:insert(pandoc.RawBlock("typst", "],\n  ["))
    else
      blocks:insert(pandoc.RawBlock("typst", "]\n)"))
    end
  end

  return blocks
end

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------

local function contains_poster_column(blocks)
  for _, block in ipairs(blocks) do
    if block.t == "Div" and has_class(block, "poster-column") then
      return true
    end
    if (block.t == "Div" or block.t == "BlockQuote") and type(block.content) == "table" then
      if contains_poster_column(block.content) then return true end
    end
  end
  return false
end

function Pandoc(doc)
  local meta = doc.meta
  local options = resolve_options(meta)

  -- Detect explicit column layout
  local found_columns = contains_poster_column(doc.blocks)

  -- Resolve paper size into width/height meta the partial can splice in.
  -- (Pandoc templates don't accept underscore-leading variable names, so use
  -- the `resolved-` prefix for derived values.)
  --
  -- Values that contain Typst syntax like `(`, `:`, `..` must be emitted as
  -- RawInline("typst", ...) — MetaString routes through Markdown/Typst
  -- escaping and would backslash-escape parens.
  local function raw_typst(s)
    return pandoc.MetaInlines({ pandoc.RawInline("typst", s) })
  end

  local pw, ph = resolve_paper_size(meta)
  meta["resolved-poster-width"] = raw_typst(pw)
  meta["resolved-poster-height"] = raw_typst(ph)
  meta["resolved-font-size"] = raw_typst(resolve_font_size(meta, pw, ph))

  -- Resolved user-facing preset options
  meta["resolved-poster-preset"] = pandoc.MetaString(options.preset)
  meta["resolved-poster-layout"] = pandoc.MetaString(options.layout)
  meta["resolved-poster-style"] = pandoc.MetaString(options.style)
  meta["resolved-poster-density"] = pandoc.MetaString(options.density)

  -- Column count for flow mode
  meta["resolved-column-count"] = raw_typst(tostring(column_count(meta, options.layout)))
  meta["resolved-column-layout"] = pandoc.MetaString(found_columns and "manual" or "flow")

  -- Build dict literals from nested YAML maps
  meta["resolved-typography"] = raw_typst(map_to_dict_literal(meta["poster-typography"]))
  meta["resolved-spacing"] = raw_typst(map_to_dict_literal(meta["poster-spacing"]))
  meta["resolved-colors"] = raw_typst(map_to_dict_literal(meta["poster-colors"]))

  -- Resolve institutions: prefer explicit `institutions:`/`institution:`,
  -- otherwise pull names from Quarto's canonicalized `affiliations` array
  -- (each author's `affiliation: "..."` becomes a top-level affiliation entry
  -- with a `name` field).
  local inst_text = nil
  local explicit = meta_list(meta, "institutions") or meta_list(meta, "institution")
  if explicit and #explicit > 0 then
    inst_text = table.concat(explicit, " · ")
  else
    local affs = meta["affiliations"]
    if type(affs) == "table" then
      local seen, names = {}, {}
      for _, aff in ipairs(affs) do
        local name = nil
        if type(aff) == "table" then name = aff["name"] end
        if name ~= nil then
          local text = pandoc.utils.stringify(name)
          if text ~= "" and not seen[text] then
            seen[text] = true
            table.insert(names, text)
          end
        end
      end
      if #names > 0 then inst_text = table.concat(names, " · ") end
    end
  end
  if inst_text then
    meta["resolved-institutions"] = pandoc.MetaInlines({ pandoc.Str(inst_text) })
  end

  doc.meta = meta
  doc.blocks = pandoc.Blocks(transform_blocks(doc.blocks, meta))

  return doc
end
