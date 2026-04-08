--[[
Installs Mason, the external tool manager that downloads LSP servers, formatters, and linters.
This will own server lifecycle once we retire manual installs from CoC and ALE.
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
      ensure_installed = {
        -- Python
        "pyright",
        "black",

        -- Ruby
        "solargraph",

        -- C#
        "omnisharp",

        -- SQL
        "sqlls",

        -- HTML
        "html-lsp",
        "htmlbeautifier",
        "htmlhint",

        -- C++
        "ast-grep",
        "cpptools",

        -- Markdown
        "markdownlint",

        -- Typescript
        "typescript-language-server",
        "eslint-lsp",
        "json-lsp",
        "css-lsp",
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
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

        -- Typescript
        "ts_ls",
        "eslint",

        -- Lua
        "lua_ls",
      },
      automatic_installation = true,
      automatic_enable = true,
    },
  },
}
