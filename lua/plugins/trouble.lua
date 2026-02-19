--[[
Adds Trouble for a structured diagnostics and references list that rides on top of the LSP client.
Pairs with Telescope and vim.diagnostic mappings to modernize how we triage issues.
]]
return {
  "folke/trouble.nvim",
  cmd = "TroubleToggle",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
}
