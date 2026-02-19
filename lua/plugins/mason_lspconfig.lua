--[[
Bridges Mason packages with nvim-lspconfig so servers install automatically and share defaults.
Crucial glue for Phase 3 where we declare ensure_installed and common on_attach logic.
]]
return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",
  },
}
