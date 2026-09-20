--[[
Installs the Mason packages that are not language servers, so mason-lspconfig cannot own them.
These are the formatters and linters none-ls drives; without this they have to be installed by hand
with :MasonInstall, and none-ls silently skips any source whose binary it cannot find.
]]
return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = { "williamboman/mason.nvim" },
  opts = {
    ensure_installed = {
      -- Python
      "black",

      -- HTML
      "htmlbeautifier",
      "htmlhint",

      -- Markdown
      "markdownlint",
    },
    run_on_start = true,
  },
}
