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

return M
