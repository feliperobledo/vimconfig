--[[
Installs Mason, the external tool manager that downloads LSP servers, formatters, and linters.
This will own server lifecycle once we retire manual installs from CoC and ALE.
]]
return {
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
  config = function(_, opts)
      require("mason").setup(opts)
      local mr = require "mason-registry"

      mr.refresh(function()
        for _, tool in ipairs {
          "pyright",
          "solargraph",
          "omnisharp",
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
        } do
          local p = mr.get_package(tool)
          if not p:is_installed() then p:install() end
        end
    end)
  end
}
