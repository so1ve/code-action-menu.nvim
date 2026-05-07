local M = {}

function M.notify(message, level, opts)
  if opts and opts.notify == false then
    return
  end

  vim.notify(message, level or vim.log.levels.INFO, { title = "code-action-menu.nvim" })
end

return M
