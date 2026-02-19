--[[
Shows lightweight progress notifications for LSP requests so long-running tasks are visible.
We use the legacy branch for stability until the rewritten version matures.
]]
return {
  "j-hui/fidget.nvim",
  branch = "legacy",
  event = "LspAttach",
}
