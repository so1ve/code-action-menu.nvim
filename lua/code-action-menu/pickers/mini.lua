local display = require("code-action-menu.display")

local M = { name = "mini" }

local source_ns = vim.api.nvim_create_namespace("code-action-menu.mini-source")

local function mini_pick()
  local ok, pick = pcall(require, "mini.pick")

  if ok then
    return pick
  end
end

local function show_items(bufnr, items)
  local source_col = display.source_column(items, function(item)
    return item.item
  end)
  local lines = {}
  local line_parts = {}

  vim.api.nvim_buf_clear_namespace(bufnr, source_ns, 0, -1)

  for index, item in ipairs(items) do
    lines[index], line_parts[index] = display.line_parts(item.item, source_col)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  for index, parts in ipairs(line_parts) do
    for _, part in ipairs(parts) do
      if part.hl_group and part.start_col < part.end_col then
        vim.api.nvim_buf_set_extmark(bufnr, source_ns, index - 1, part.start_col, {
          end_col = part.end_col,
          hl_group = part.hl_group,
        })
      end
    end
  end
end

function M.available()
  local pick = mini_pick()

  return type(pick) == "table" and type(pick.start) == "function"
end

function M.select(items, opts, on_select)
  local pick = assert(mini_pick(), "mini.pick is not available")
  local picker_items = {}

  for _, item in ipairs(items) do
    picker_items[#picker_items + 1] = {
      item = item,
      text = item.title_text .. " " .. item.source_text,
    }
  end

  pick.start({
    source = {
      items = picker_items,
      name = opts.prompt,
      show = function(bufnr, shown_items)
        show_items(bufnr, shown_items)
      end,
      choose = function(item)
        on_select(item and item.item)
      end,
    },
  })
end

return M
