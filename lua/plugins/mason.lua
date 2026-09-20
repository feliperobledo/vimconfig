--[[
Installs Mason, the external tool manager that downloads LSP servers, formatters, and linters.
Mason itself only provides the UI and the installer; what actually gets installed is declared by
mason-lspconfig below (language servers) and by mason-tool-installer (formatters and linters).
]]
return {
  {
    "williamboman/mason.nvim",
    -- This calls setup() automatically
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      -- lspconfig server names, not Mason package names. mason-lspconfig translates
      -- them to packages itself (e.g. cssls -> css-lsp).
      ensure_installed = {
        -- Python
        "pyright",

        -- Ruby
        "solargraph",

        -- C#
        "omnisharp",

        -- SQL
        "sqlls",

        -- C/C++
        "clangd",
        "neocmake",

        -- Shader Languages
        "slangd",

        -- HTML / CSS / JSON
        "html",
        "cssls",
        "jsonls",

        -- Typescript
        "ts_ls",
        "eslint",

        -- Terraform
        "ms_terraform_lsp",

        -- Lua
        "lua_ls",

        -- Structural search
        "ast_grep",
      },
      automatic_enable = true,
    },
  },
}
