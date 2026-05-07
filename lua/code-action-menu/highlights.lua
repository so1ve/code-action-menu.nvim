local M = {}

local groups = {
  CodeActionMenuTitle = { link = "Normal" },
  CodeActionMenuClient = { link = "Comment" },
  CodeActionMenuQuickfix = { link = "DiagnosticWarn" },
  CodeActionMenuRefactor = { link = "Function" },
  CodeActionMenuExtract = { link = "Type" },
  CodeActionMenuInline = { link = "String" },
  CodeActionMenuRewrite = { link = "Constant" },
  CodeActionMenuSource = { link = "Keyword" },
  CodeActionMenuOrganizeImports = { link = "Include" },
  CodeActionMenuFallback = { link = "Special" },
}

function M.setup()
  for group, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", opts, { default = true }))
  end
end

return M
