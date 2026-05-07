local M = {}

M.defaults = {
  picker = { "snacks", "mini", "native" },
  prompt = "Code actions",
  notify = true,
  icons = {
    quickfix = "󰁨",
    refactor = "󰊕",
    extract = "󰈌",
    inline = "󰏖",
    rewrite = "󰷈",
    source = "󰒓",
    organize_imports = "󰉕",
    fallback = "󰌵",
  },
}

local options = vim.deepcopy(M.defaults)

function M.setup(opts)
  options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})

  return options
end

function M.get()
  return options
end

return M
