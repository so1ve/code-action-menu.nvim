# code-action-menu.nvim

A small Neovim LSP code action picker

## Features

- `require("code-action-menu").setup(opts)` and `require("code-action-menu").code_action(opts)`
- Picker fallback order: `snacks` → `mini` → `native`
- Only shows code actions that are available; disabled actions are hidden
- Supports rust-analyzer grouped code actions when the client advertises `experimental.codeActionGroup`
- Supports diff preview for Snacks picker only

## Requirements

- Neovim >= 0.10
- Optional: [`folke/snacks.nvim`](https://github.com/folke/snacks.nvim) for the Snacks picker and diff preview
- Optional: [`nvim-mini/mini.pick`](https://github.com/nvim-mini/mini.pick) for the mini.pick picker
- Strongly recommended: a Nerd Font, because the default action icons use Nerd Font glyphs

## Installation

### `lazy.nvim`

```lua
{
  "so1ve/code-action-menu.nvim",
  event = "LspAttach",
  opts = {},
}
```

Then map it from your LSP attach logic:

```lua
vim.keymap.set("n", "<leader>ca", function()
  require("code-action-menu").code_action()
end, { buffer = bufnr, desc = "Code action" })
```

## Configuration

```lua
require("code-action-menu").setup({
  -- accepts both a string or a list of strings to specify the picker(s) to use
  picker = { "snacks", "mini", "native" },
  -- notify via `vim.notify`?
  notify = true,
  -- menu prompt shown in the picker header
  prompt = "Code Actions",
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
})
```

To receive rust-analyzer grouped code actions, merge the plugin capability into your LSP client capabilities before
starting rust-analyzer:

```lua
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("code-action-menu").capabilities(capabilities)
```

If your LSP capabilities are built before your plugin manager has placed `code-action-menu.nvim` on `runtimepath`, set
the equivalent flag directly instead:

```lua
capabilities.experimental = capabilities.experimental or {}
capabilities.experimental.codeActionGroup = true
```

`code_action()` accepts the same options for one call. It also accepts `bufnr`, `context`, and `only`:

```lua
require("code-action-menu").code_action({ only = "source.organizeImports" })
```

## Highlights

Action rows use default highlight links, so colors follow your colorscheme:

- `CodeActionMenuQuickfix`
- `CodeActionMenuRefactor`
- `CodeActionMenuExtract`
- `CodeActionMenuInline`
- `CodeActionMenuRewrite`
- `CodeActionMenuSource`
- `CodeActionMenuOrganizeImports`
- `CodeActionMenuFallback`
- `CodeActionMenuClient`

## Pickers

### Snacks

Uses `snacks.picker` when available. This is the only picker with preview support; it shows action diff/details.

### mini.pick

Uses `require("mini.pick").start()` when available. Preview is not supported.

### native

Uses `vim.ui.select` as the final fallback. Preview is not supported.

## 📝 License

[MIT](./LICENSE). Made with ❤️ by [Ray](https://github.com/so1ve)
