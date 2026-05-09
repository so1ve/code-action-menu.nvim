local items = require("code-action-menu.items")
local utils = require("code-action-menu.utils")

local M = {}

local code_action_method = vim.lsp.protocol.Methods.textDocument_codeAction or "textDocument/codeAction"
local resolve_method = vim.lsp.protocol.Methods.codeAction_resolve or "codeAction/resolve"

local function get_clients(bufnr)
  if vim.lsp.get_clients then
    return vim.lsp.get_clients({ bufnr = bufnr, method = code_action_method })
  end

  return vim.lsp.get_active_clients({ bufnr = bufnr })
end

local function client_supports(client, method, bufnr)
  if client.supports_method then
    return client:supports_method(method, bufnr)
  end

  return true
end

local function make_params(opts)
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  local range_params = vim.lsp.util.make_range_params(0, opts.offset_encoding or "utf-16")
  local diagnostics = vim.tbl_map(function(diagnostic)
    return diagnostic.user_data and diagnostic.user_data.lsp or diagnostic
  end, vim.diagnostic.get(bufnr, { lnum = range_params.range.start.line }))

  range_params.context = vim.tbl_deep_extend("force", {
    diagnostics = diagnostics,
  }, opts.context or {})

  if opts.only then
    range_params.context.only = type(opts.only) == "table" and opts.only or { opts.only }
  end

  return range_params
end

function M.collect(opts, callback)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  local clients = vim.tbl_filter(function(client)
    return client_supports(client, code_action_method, bufnr)
  end, get_clients(bufnr))

  if #clients == 0 then
    callback({})
    return
  end

  local pending = #clients
  local results = {}

  local function finish_client(client, err, actions)
    if err then
      utils.notify(
        string.format("%s failed to provide code actions", client.name or "LSP client"),
        vim.log.levels.WARN,
        opts
      )
    end

    for _, action in ipairs(actions or {}) do
      if not action.disabled then
        results[#results + 1] = items.from_action(action, client, bufnr)
      end
    end

    pending = pending - 1
    if pending == 0 then
      callback(items.group(results))
    end
  end

  for _, client in ipairs(clients) do
    local params = make_params({
      bufnr = bufnr,
      context = opts.context,
      offset_encoding = client.offset_encoding,
      only = opts.only,
    })

    client:request(code_action_method, params, function(err, result)
      finish_client(client, err, result)
    end, bufnr)
  end
end

function M.capabilities(capabilities)
  local result = capabilities and vim.deepcopy(capabilities) or vim.lsp.protocol.make_client_capabilities()

  if type(result.experimental) ~= "table" then
    result.experimental = {}
  end

  result.experimental.codeActionGroup = true

  return result
end

local function execute_command(item, command, bufnr)
  if not command then
    return
  end

  item.client:exec_cmd(command, {
    bufnr = bufnr,
    client_id = item.client.id,
  })
end

local function apply_action(item, action, bufnr)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, item.client.offset_encoding or "utf-16")
  end

  local action_command = action.command
  if action_command then
    local command = type(action_command) == "table" and action_command or action
    execute_command(item, command, bufnr)
  end
end

function M.apply(item, opts)
  opts = opts or {}

  if not item or not item.action or not item.client then
    return
  end

  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  local action = item.action

  if action.disabled then
    local reason = action.disabled.reason and (": " .. action.disabled.reason) or ""
    utils.notify("Code action is disabled" .. reason, vim.log.levels.INFO, opts)

    return
  end

  if action.data and client_supports(item.client, resolve_method, bufnr) then
    item.client:request(resolve_method, action, function(err, resolved)
      if err then
        utils.notify("Failed to resolve code action", vim.log.levels.WARN, opts)
      end

      vim.schedule(function()
        apply_action(item, resolved or action, bufnr)
      end)
    end, bufnr)

    return
  end

  apply_action(item, action, bufnr)
end

return M
