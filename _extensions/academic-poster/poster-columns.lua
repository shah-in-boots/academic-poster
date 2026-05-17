-- academic-poster: structural Pandoc -> Typst transform.
--
-- Responsibilities (kept deliberately narrow):
--   1. Resolve `poster-size` / paper presets into width + height.
--   2. Build typography/spacing/colors dict literals from nested YAML maps
--      so typst-show.typ can splice them in verbatim.
--   3. Convert `.poster-column` Divs into a `#poster-grid(...)` call.
--   4. Wrap level-1 headings in `#poster-card(role: ..., variant: ...)[...]`.
--   5. Convert `.poster-callout` Divs into `#poster-callout(...)[...]`.
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

-- ---------------------------------------------------------------------------
-- Paper size resolution
-- ---------------------------------------------------------------------------

local PAPER_PRESETS = {
  ["a0"] = {width = "841mm", height = "1189mm"},
  ["a0-landscape"] = {width = "1189mm", height = "841mm"},
  ["a1"] = {width = "594mm", height = "841mm"},
  ["a1-landscape"] = {width = "841mm", height = "594mm"},
  ["a2"] = {width = "420mm", height = "594mm"},
  ["a3"] = {width = "297mm", height = "420mm"},
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
  end

  local width = meta_string(meta, "poster-width") or "48in"
  local height = meta_string(meta, "poster-height") or "36in"
  return width, height
end

-- ---------------------------------------------------------------------------
-- Column widths
-- ---------------------------------------------------------------------------

local function normalize_track(value)
  if value == nil or value == "" then return "1fr" end
  -- Already has a unit (em, in, cm, pt, mm, %, fr)
  if value:match("[a-zA-Z%%]") then return value end
  return value .. "fr"
end

local function column_widths_literal(meta, count)
  local widths = meta_list(meta, "poster-columns") or meta_list(meta, "poster-column-widths")
  if widths == nil or #widths == 0 or (#widths == 1 and tonumber(widths[1])) then
    -- single integer (column count) or absent -> equal columns
    local n = count
    if widths and #widths == 1 then n = tonumber(widths[1]) end
    local tracks = {}
    for _ = 1, n do table.insert(tracks, "1fr") end
    return "(" .. table.concat(tracks, ", ") .. ")"
  end

  local tracks = {}
  for _, w in ipairs(widths) do table.insert(tracks, normalize_track(w)) end
  return "(" .. table.concat(tracks, ", ") .. ")"
end

local function column_count(meta)
  local widths = meta_list(meta, "poster-columns") or meta_list(meta, "poster-column-widths")
  if widths and #widths == 1 and tonumber(widths[1]) then
    return tonumber(widths[1])
  end
  if widths and #widths > 1 then return #widths end
  return 3
end

-- ---------------------------------------------------------------------------
-- Nested YAML map -> Typst dict literal
-- ---------------------------------------------------------------------------

-- A value coming from YAML may look like a literal Typst expression (e.g.
-- "1.1em", "rgb(\"#b01c32\")"), a color hex ("#b01c32"), or a bare number.
-- This function emits the Typst-side representation.
local function typst_value(raw)
  if raw == nil then return "none" end
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

local function map_to_dict_literal(meta_value)
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
  local widths = column_widths_literal(meta, #column_divs)

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

function Pandoc(doc)
  local meta = doc.meta

  -- Detect explicit column layout
  local found_columns = false
  for _, block in ipairs(doc.blocks) do
    if block.t == "Div" and has_class(block, "poster-column") then
      found_columns = true
      break
    end
  end

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

  -- Column count for flow mode
  meta["resolved-column-count"] = raw_typst(tostring(column_count(meta)))
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
