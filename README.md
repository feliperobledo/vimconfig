# vimconfig

My neovim configuration files

## Neovim Version Management

Neovim is managed with `bob`, not Homebrew. This makes it easier to pin or switch Neovim versions during migrations without changing the system package manager state.

Typical workflow:

```bash
bob install 0.12.0
bob use 0.12.0
```

The shell should prepend `~/.local/share/bob/nvim-bin` to `PATH` so `nvim` resolves to the Bob-managed version.

## Stack

| Plugin                              | Role                           | Responsibilities                                                                             | Interactions                                                                                                                                         |
| ----------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `neovim/nvim-lspconfig`             | LSP client configuration layer | Provides the native LSP client integration used by Neovim `0.12` defaults and plugin-managed servers. | Works with `mason-lspconfig`, feeds diagnostics to native tooling such as `vim.diagnostic`, and underpins server-specific integrations like Java and GraphQL. |
| `williamboman/mason.nvim`           | External tool manager          | Install and update language servers, formatters, and linters from the Mason registry.        | Uses the registry API to auto-install required language servers listed in `lua/plugins/mason.lua`.                                                  |
| `hrsh7th/nvim-cmp`                  | Completion engine              | Provide completion UI, sorting, and mappings in insert and command-line modes.               | Aggregates sources (LSP, buffer, path) and uses Neovim's built-in snippet API for any server-supplied snippets.                                      |
| `hrsh7th/cmp-nvim-lsp`              | LSP completion source          | Surface LSP completion items in `nvim-cmp` and provide an opt-in capabilities helper for explicit server setups. | Relies on active LSP clients; useful if the config later adds server-specific capability overrides.                                                   |
| `hrsh7th/cmp-buffer`                | Buffer completion source       | Offer buffer words as completion suggestions.                                                | Loaded as an `nvim-cmp` source alongside LSP entries.                                                                                                |
| `hrsh7th/cmp-path`                  | Filesystem completion source   | Suggest filesystem paths in insert or command-line completion.                               | Enabled through the `nvim-cmp` source list; complements command-line completion.                                                                     |
| `hrsh7th/cmp-cmdline`               | Command-line completion source | Provide `:` and `/` completion via `nvim-cmp`.                                               | Configured with `cmp.setup.cmdline`; pairs with buffer/path sources.                                                                                 |
| `folke/neodev.nvim`                 | Neovim Lua helper              | Improve `lua_ls` behavior when editing Neovim configs and plugins.                           | Complements the native LSP stack for Lua development.                                                                                                 |
| `j-hui/fidget.nvim`                 | LSP progress UI                | Display asynchronous LSP request progress without blocking editing.                          | Hooks into handlers registered via `nvim-lspconfig`.                                                                                                 |
| `folke/trouble.nvim`                | Diagnostics/workspace list     | Visualize diagnostics, references, and quickfix items in a dedicated panel.                  | Consumes `vim.diagnostic` data from LSP servers and integrates with Telescope pickers.                                                               |
| `Hoffs/omnisharp-extended-lsp.nvim` | OmniSharp navigation helper    | Provide enhanced definition handlers for C# LSP responses if explicit OmniSharp customization is added later. | Not currently wired through a shared LSP module in this repo.                                                                                         |

## TODO

- [ ] Learn how to use MCP hub
- [ ] Learn how to use Codecompanion

