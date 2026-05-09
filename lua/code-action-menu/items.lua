local config = require("code-action-menu.config")

local M = {}

local kind_specs = {
  { prefix = "quickfix", icon = "quickfix", hl = "CodeActionMenuQuickfix" },
  { prefix = "refactor.extract", icon = "extract", hl = "CodeActionMenuExtract" },
  { prefix = "refactor.inline", icon = "inline", hl = "CodeActionMenuInline" },
  { prefix = "refactor.rewrite", icon = "rewrite", hl = "CodeActionMenuRewrite" },
  { prefix = "refactor", icon = "refactor", hl = "CodeActionMenuRefactor" },
  { prefix = "source.organizeImports", icon = "organize_imports", hl = "CodeActionMenuOrganizeImports" },
  { prefix = "source", icon = "source", hl = "CodeActionMenuSource" },
}

local fallback_spec = { icon = "fallback", hl = "CodeActionMenuFallback" }

local function kind_matches(kind, prefix)
  return kind == prefix or kind:sub(1, #prefix + 1) == prefix .. "."
end

local function spec_for_kind(kind)
  kind = type(kind) == "string" and kind or ""

  for _, spec in ipairs(kind_specs) do
    if kind_matches(kind, spec.prefix) then
      return spec
    end
  end

  return fallback_spec
end

function M.from_action(action, client, bufnr)
  local opts = config.get()
  local title = action.title or action.command or "Code action"
  local client_name = client and client.name or "LSP"
  local kind_spec = spec_for_kind(action.kind)
  local icon = opts.icons[kind_spec.icon]

  return {
    action = action,
    client = client,
    client_name = client_name,
    bufnr = bufnr,
    icon = icon,
    icon_hl = kind_spec.hl,
    kind = action.kind,
    source_hl = "CodeActionMenuClient",
    source_text = string.format("[%s]", client_name),
    title = title,
    title_hl = "CodeActionMenuTitle",
    title_text = string.format("%s %s", icon, title),
  }
end

local function group_name(item)
  local group = item.action and item.action.group

  return type(group) == "string" and group ~= "" and group or nil
end

local function group_key(item, name)
  local client = item.client

  if client and client.id then
    return string.format("%s:%s", client.id, name)
  end

  return string.format("%s:%s", tostring(client or item.client_name or ""), name)
end

local function group_item(name, children)
  local first = children[1]

  return {
    is_group = true,
    children = children,
    client = first.client,
    client_name = first.client_name,
    bufnr = first.bufnr,
    icon = first.icon,
    icon_hl = first.icon_hl,
    kind = first.kind,
    source_hl = first.source_hl,
    source_text = first.source_text,
    title = name,
    title_hl = first.title_hl,
    title_text = string.format("%s %s", first.icon, name),
  }
end

function M.group(action_items)
  local groups = {}
  local ordered = {}

  for _, item in ipairs(action_items) do
    local name = group_name(item)

    if name then
      local key = group_key(item, name)

      if not groups[key] then
        groups[key] = {}
        ordered[#ordered + 1] = { group = name, key = key }
      end

      groups[key][#groups[key] + 1] = item
    else
      ordered[#ordered + 1] = { item = item }
    end
  end

  local result = {}
  for _, entry in ipairs(ordered) do
    if entry.item then
      result[#result + 1] = entry.item
    else
      local children = groups[entry.key]

      result[#result + 1] = #children == 1 and children[1] or group_item(entry.group, children)
    end
  end

  return result
end

return M
