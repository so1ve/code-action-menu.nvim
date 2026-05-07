local M = {}

local adapters = {
  snacks = "code-action-menu.pickers.snacks",
  mini = "code-action-menu.pickers.mini",
  native = "code-action-menu.pickers.native",
}

local function normalize_picker_list(picker)
  if picker == nil then
    return require("code-action-menu.config").get().picker
  end

  if type(picker) == "string" then
    return { picker }
  end

  return picker
end

function M.resolve(opts)
  opts = opts or {}

  for _, name in ipairs(normalize_picker_list(opts.picker)) do
    local module_name = adapters[name]

    if module_name then
      local ok, adapter = pcall(require, module_name)
      if ok and adapter.available() then
        return adapter
      end
    end
  end

  error("code-action-menu.nvim: no configured picker is available")
end

function M.select(items, opts, on_select)
  local adapter = M.resolve(opts)

  return adapter.select(items, opts or {}, on_select)
end

return M
