local function has_class(block, class)
  if block.t ~= "Div" and block.t ~= "Header" then
    return false
  end

  for _, value in ipairs(block.classes) do
    if value == class then
      return true
    end
  end

  return false
end

local function meta_string(meta, key)
  local value = meta[key]
  if value == nil then
    return nil
  end

  if type(value) == "string" then
    return value
  end

  return pandoc.utils.stringify(value)
end

local function meta_expr(meta, key, default)
  local value = meta_string(meta, key)
  if value == nil or value == "" then
    return default
  end

  return value
end

local function meta_list(meta, key)
  local value = meta[key]
  if value == nil then
    return nil
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

local function normalize_track(value)
  if value == nil or value == "" then
    return "1fr"
  end

  if value:match("[a-zA-Z%%]") then
    return value
  end

  return value .. "fr"
end

local function columns_expr(meta, count)
  local widths = meta_list(meta, "poster-column-widths") or meta_list(meta, "column-widths")

  if widths == nil or #widths == 0 then
    local tracks = {}
    for _ = 1, count do
      table.insert(tracks, "1fr")
    end
    return "(" .. table.concat(tracks, ", ") .. ")"
  end

  local tracks = {}
  for _, width in ipairs(widths) do
    table.insert(tracks, normalize_track(width))
  end
  return "(" .. table.concat(tracks, ", ") .. ")"
end

local function inlines_to_typst(inlines)
  local doc = pandoc.Pandoc({ pandoc.Plain(inlines) })
  return pandoc.write(doc, "typst"):gsub("%s+$", "")
end

local function append_all(target, source)
  for _, block in ipairs(source) do
    target:insert(block)
  end
end

local function raw_wrap(start, content, finish)
  local blocks = pandoc.List()
  blocks:insert(pandoc.RawBlock("typst", start))
  append_all(blocks, content)
  blocks:insert(pandoc.RawBlock("typst", finish))
  return blocks
end

local function primary(meta)
  return meta_expr(meta, "poster-primary", "rgb(\"#b01c32\")")
end

local function secondary(meta)
  return meta_expr(meta, "poster-secondary", "rgb(\"#6f1020\")")
end

local function section_bg(meta)
  return meta_expr(meta, "poster-section-bg", primary(meta))
end

local function section_fg(meta)
  return meta_expr(meta, "poster-section-fg", "white")
end

local function subsection_bg(meta)
  return meta_expr(meta, "poster-subsection-bg", "brand-color.at(\"light\", default: rgb(\"#f8e8eb\"))")
end

local function subsection_fg(meta)
  return meta_expr(meta, "poster-subsection-fg", secondary(meta))
end

local function accent(meta)
  return meta_expr(meta, "poster-accent", "brand-color.at(\"tertiary\", default: rgb(\"#f4c7cf\"))")
end

local function card_fill(meta)
  return meta_expr(meta, "poster-card-bg", "white")
end

local function card_stroke(meta)
  return meta_expr(meta, "poster-card-stroke", "rgb(\"#ead8dc\")")
end

local function card_radius(meta)
  return meta_expr(meta, "poster-card-radius", meta_expr(meta, "poster-corner-radius", "5pt"))
end

local function variant(block)
  if has_class(block, "secondary") then
    return "secondary"
  elseif has_class(block, "accent") then
    return "accent"
  elseif has_class(block, "light") or has_class(block, "muted") then
    return "light"
  elseif has_class(block, "dark") then
    return "dark"
  elseif has_class(block, "inverse") then
    return "inverse"
  end

  return "primary"
end

local function variant_fill(meta, name)
  if name == "secondary" then
    return secondary(meta)
  elseif name == "accent" then
    return accent(meta)
  elseif name == "light" then
    return subsection_bg(meta)
  elseif name == "dark" then
    return meta_expr(meta, "poster-dark", "rgb(\"#17212b\")")
  elseif name == "inverse" then
    return "white"
  end

  return section_bg(meta)
end

local function variant_text(meta, name)
  if name == "accent" or name == "light" or name == "inverse" then
    return subsection_fg(meta)
  end

  return section_fg(meta)
end

local function card_title_size(meta, block)
  if has_class(block, "large") then
    return meta_expr(meta, "poster-h1-large-size", "1.1em")
  elseif has_class(block, "compact") then
    return meta_expr(meta, "poster-h1-compact-size", "0.82em")
  end

  return meta_expr(meta, "poster-card-title-size", meta_expr(meta, "poster-h1-size", "0.92em"))
end

local function card_body_inset(meta, block)
  if has_class(block, "compact") then
    return meta_expr(meta, "poster-card-compact-body-inset", "(x: 0.38em, y: 0.22em)")
  end

  return meta_expr(meta, "poster-card-body-inset", "(x: 0.48em, y: 0.34em)")
end

local function card_gap(meta, block)
  if has_class(block, "compact") then
    return meta_expr(meta, "poster-card-compact-gap", "0.22em")
  end

  return meta_expr(meta, "poster-card-gap", "0.32em")
end

local function callout_text_size(meta, block)
  if has_class(block, "large") then
    return meta_expr(meta, "poster-callout-large-size", "1.02em")
  elseif has_class(block, "compact") then
    return meta_expr(meta, "poster-callout-compact-size", "0.78em")
  end

  return meta_expr(meta, "poster-callout-size", "0.88em")
end

local function feature_fill(meta, block)
  local name = variant(block)
  if name == "primary" then
    return meta_expr(meta, "poster-feature-bg", section_bg(meta))
  end

  return variant_fill(meta, name)
end

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
        goto continue
      end

      local title = inlines_to_typst(block.content)
      local section = pandoc.List()
      index = index + 1

      while index <= #blocks do
        local next_block = blocks[index]
        if next_block.t == "Header" and next_block.level == 1 then
          break
        end
        if next_block.t == "Div" and has_class(next_block, "poster-column") then
          break
        end

        append_all(section, transform_blocks(pandoc.List({ next_block }), meta))
        index = index + 1
      end

      local card_variant = variant(block)
      local start = "#poster-card("
        .. "title: [" .. title .. "], "
        .. "fill: " .. card_fill(meta) .. ", "
        .. "stroke-color: " .. card_stroke(meta) .. ", "
        .. "header-fill: " .. variant_fill(meta, card_variant) .. ", "
        .. "header-text: " .. variant_text(meta, card_variant) .. ", "
        .. "radius: " .. card_radius(meta) .. ", "
        .. "body-inset: " .. card_body_inset(meta, block) .. ", "
        .. "gap: " .. card_gap(meta, block) .. ", "
        .. "title-size: " .. card_title_size(meta, block)
        .. ")["
      append_all(out, raw_wrap(start, section, "]"))
    elseif block.t == "Div" and has_class(block, "poster-callout") then
      local content = transform_blocks(block.content, meta)
      local callout_variant = variant(block)
      local start = "#poster-callout("
        .. "fill: " .. meta_expr(meta, "poster-callout-bg", "white") .. ", "
        .. "text-fill: " .. meta_expr(meta, "poster-callout-fg", "rgb(\"#17212b\")") .. ", "
        .. "stroke-color: " .. meta_expr(meta, "poster-callout-stroke", card_stroke(meta)) .. ", "
        .. "accent: " .. meta_expr(meta, "poster-callout-accent", variant_fill(meta, callout_variant)) .. ", "
        .. "radius: " .. meta_expr(meta, "poster-callout-radius", card_radius(meta)) .. ", "
        .. "text-size: " .. callout_text_size(meta, block)
        .. ")["
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

    ::continue::
  end

  return out
end

function wrap_columns(column_divs, meta)
  local blocks = pandoc.List()
  local gutter = meta_string(meta, "poster-column-gap") or meta_string(meta, "column-gap") or "0.5in"
  local feature_radius = meta_expr(meta, "poster-feature-radius", meta_expr(meta, "poster-corner-radius", "7pt"))
  local feature_inset = meta_expr(meta, "poster-feature-inset", "0.38in")

  blocks:insert(pandoc.RawBlock("typst", "#poster-grid(\n  columns: " .. columns_expr(meta, #column_divs) .. ",\n  gutter: " .. gutter .. ",\n  ["))

  for column_index, div in ipairs(column_divs) do
    local featured = has_class(div, "poster-feature") or has_class(div, "feature")

    if featured then
      blocks:insert(pandoc.RawBlock("typst", "#poster-feature-column(fill: " .. feature_fill(meta, div) .. ", inset: " .. feature_inset .. ", radius: " .. feature_radius .. ")["))
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

function Pandoc(doc)
  local found_columns = false

  for _, block in ipairs(doc.blocks) do
    if block.t == "Div" and has_class(block, "poster-column") then
      found_columns = true
      break
    end
  end

  doc.blocks = transform_blocks(doc.blocks, doc.meta)

  if found_columns then
    doc.meta["poster-manual-columns"] = pandoc.MetaBool(true)
  end

  return doc
end
