--[[
Adds a small badge at the top of posts made with the help of an AI assistant.

Front matter of a post:
  ai-assistance: assisted | generated
  ai-assistance-note: "short description of what the AI assistant did" (optional)

Site-wide options (top level of _quarto.yml):
  ai-badge-icon: path of an image to use as icon (optional, defaults to a
                 Bootstrap icon)
  ai-badge-link: page explaining the badges (defaults to /ai-assistance.qmd)
]]

local LABELS = {
  assisted = "AI-assisted",
  generated = "AI-generated",
}

local DESCRIPTIONS = {
  assisted = "Written by me, with an AI assistant helping on parts of it",
  generated = "Mostly produced by an AI assistant under my direction and review",
}

local function meta_string(meta, key)
  local value = meta[key]
  if value == nil then
    return nil
  end
  local text = pandoc.utils.stringify(value)
  if text == "" then
    return nil
  end
  return text
end

local function make_badge(level, note, icon, link)
  local content = {}
  if icon then
    table.insert(content, pandoc.Image({}, icon, "", pandoc.Attr("", { "ai-badge-icon" })))
  else
    table.insert(
      content,
      pandoc.RawInline("html", '<i class="bi bi-robot ai-badge-icon" aria-hidden="true"></i>')
    )
  end
  table.insert(content, pandoc.Str(LABELS[level]))

  local inlines = {
    pandoc.Link(content, link, DESCRIPTIONS[level], pandoc.Attr("", { "ai-badge-pill" })),
  }
  if note then
    table.insert(inlines, pandoc.Space())
    table.insert(inlines, pandoc.Span(note, pandoc.Attr("", { "ai-badge-note" })))
  end

  return pandoc.Div(
    { pandoc.Plain(inlines) },
    pandoc.Attr("", { "ai-badge", "ai-badge-" .. level })
  )
end

function Pandoc(doc)
  if not quarto.doc.is_format("html") then
    return doc
  end

  local level = meta_string(doc.meta, "ai-assistance")
  if level == nil then
    return doc
  end
  if LABELS[level] == nil then
    quarto.log.warning(
      "ai-assistance must be 'assisted' or 'generated', got '" .. level .. "': no badge added"
    )
    return doc
  end

  local badge = make_badge(
    level,
    meta_string(doc.meta, "ai-assistance-note"),
    meta_string(doc.meta, "ai-badge-icon"),
    meta_string(doc.meta, "ai-badge-link") or "/ai-assistance.qmd"
  )
  table.insert(doc.blocks, 1, badge)
  return doc
end
