--[[
Provides automatic installation of LSP servers via mason.nvim. This plugin is a bridge between mason.nvim and nvim-lspconfig, allowing you to easily manage and install LSP servers for your Neovim setup.
]]
return {
  "mason-org/mason-lspconfig.nvim",
  -- Per the docs, this plugin should be loaded after mason.nvim and nvim-lspconfig
  dependencies = { "mason.nvim", "nvim-lspconfig" },
  opts = {
      ensure_installed ={
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

          -- Java
          "java-language-server",
      },
      automatic_installation = true,
      audomatic_update = true,
  },
}
