local display = require("code-action-menu.display")

local M = { name = "native" }

function M.available()
  return vim.ui and type(vim.ui.select) == "function"
end

function M.select(items, opts, on_select)
  local source_col = display.source_column(items)

  vim.ui.select(items, {
    prompt = opts.prompt,
    format_item = function(item)
      return display.line(item, source_col)
    end,
  }, on_select)
end

return M
