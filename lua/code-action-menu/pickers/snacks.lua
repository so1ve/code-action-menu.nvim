local M = { name = "snacks" }

local resolve_method = vim.lsp.protocol.Methods.codeAction_resolve or "codeAction/resolve"
local preview_ns = vim.api.nvim_create_namespace("code-action-menu.preview")
local no_preview_message = "No preview available"
local diff_renderer_module

local function picker_module()
  local ok, picker = pcall(require, "snacks.picker")

  if ok and picker then
    return picker
  end

  if _G.Snacks and _G.Snacks.picker then
    return _G.Snacks.picker
  end
end

local function diff_renderer()
  if diff_renderer_module then
    return diff_renderer_module
  end

  local ok, renderer = pcall(require, "snacks.picker.util.diff")
  diff_renderer_module = ok and renderer or nil

  return diff_renderer_module
end

local function format_item(item)
  local action_item = item.item

  return {
    { action_item.icon, action_item.icon_hl },
    { " " },
    { action_item.title, action_item.title_hl },
    {
      col = 0,
      virt_text = { { action_item.source_text, action_item.source_hl } },
      virt_text_pos = "right_align",
      hl_mode = "combine",
    },
  }
end

local function uri_label(uri)
  local filename = vim.uri_to_fname(uri)

  if filename == "" then
    return uri
  end

  return vim.fn.fnamemodify(filename, ":~:.")
end

local function loaded_bufnr_for_uri(uri)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.uri_from_bufnr(bufnr) == uri then
      return bufnr
    end
  end
end

local function original_lines(uri)
  local bufnr = loaded_bufnr_for_uri(uri)
  if bufnr then
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end

  local ok, lines = pcall(vim.fn.readfile, vim.uri_to_fname(uri))
  return ok and lines or {}
end

local function apply_text_edits(lines, edits, offset_encoding)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  local ok = pcall(vim.lsp.util.apply_text_edits, edits, bufnr, offset_encoding or "utf-16")

  if not ok then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return lines
  end

  local edited = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  vim.api.nvim_buf_delete(bufnr, { force = true })

  return edited
end

local function lines_to_text(lines)
  return table.concat(lines, "\n") .. "\n"
end

local function append_file_diff(diff_lines, uri, edits, offset_encoding)
  if not uri or not edits or #edits == 0 then
    return false
  end

  local before = original_lines(uri)
  local after = apply_text_edits(before, edits, offset_encoding)
  local diff = vim.diff(lines_to_text(before), lines_to_text(after), { result_type = "unified", ctxlen = 3 })

  if not diff or diff == "" then
    return false
  end

  local label = uri_label(uri)
  diff_lines[#diff_lines + 1] = string.format("diff --git a/%s b/%s", label, label)
  diff_lines[#diff_lines + 1] = "--- a/" .. label
  diff_lines[#diff_lines + 1] = "+++ b/" .. label
  vim.list_extend(diff_lines, vim.split(diff, "\n", { plain = true }))

  return true
end

local function workspace_edit_diff(edit, offset_encoding)
  if not edit then
    return {}
  end

  local diff_lines = {}
  for uri, edits in pairs(edit.changes or {}) do
    append_file_diff(diff_lines, uri, edits, offset_encoding)
  end

  for _, change in ipairs(edit.documentChanges or {}) do
    if change.textDocument and change.edits then
      append_file_diff(diff_lines, change.textDocument.uri, change.edits, offset_encoding)
    end
  end

  return diff_lines
end

local function reset_preview(ctx, title)
  ctx.preview:reset()
  ctx.preview:set_title(title or "Code action")
end

local function render_text_preview(ctx, title, lines)
  reset_preview(ctx, title)
  ctx.preview:set_lines(lines)
end

local function render_no_preview(ctx, title)
  render_text_preview(ctx, title, { no_preview_message })
end

local function render_resolving_preview(ctx, title)
  render_text_preview(ctx, title, { "Resolving preview..." })
end

local function render_preview(ctx, action, action_item)
  local diff_lines = workspace_edit_diff(action.edit, action_item.client and action_item.client.offset_encoding)

  if #diff_lines == 0 then
    render_no_preview(ctx, action.title)
    return
  end

  reset_preview(ctx, action.title)
  local bufnr = ctx.preview:scratch()
  local renderer = diff_renderer()
  local ok = renderer and pcall(renderer.render, bufnr, preview_ns, diff_lines)

  if not ok then
    ctx.preview:set_lines(diff_lines)
    ctx.preview:highlight({ ft = "diff" })
  end
end

local function preview_item(ctx)
  local action_item = ctx.item.item
  local action = action_item.action

  if action.edit then
    render_preview(ctx, action, action_item)
    return
  end

  if
    action.data
    and action_item.client
    and action_item.client.supports_method
    and action_item.client:supports_method(resolve_method)
  then
    render_resolving_preview(ctx, action.title)

    action_item.client:request(resolve_method, action, function(_, resolved)
      vim.schedule(function()
        render_preview(ctx, resolved or action, action_item)
      end)
    end, action_item.bufnr or vim.api.nvim_get_current_buf())

    return
  end

  render_no_preview(ctx, action.title)
end

function M.available()
  local picker = picker_module()

  return type(picker) == "table" and type(picker.pick) == "function"
end

function M.select(items, opts, on_select)
  local picker = assert(picker_module(), "snacks.picker is not available")

  return picker.pick({
    title = opts.prompt,
    source = "code-action-menu",
    preview = preview_item,
    finder = function()
      local found = {}

      for index, item in ipairs(items) do
        found[#found + 1] = {
          idx = index,
          item = item,
          text = item.title_text .. " " .. item.source_text,
        }
      end

      return found
    end,
    format = format_item,
    actions = {
      confirm = function(p, item)
        p:close()
        vim.schedule(function()
          on_select(item and item.item, item and item.idx)
        end)
      end,
    },
  })
end

return M
