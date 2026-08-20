--[[
Tightens lua-language-server setup for editing Neovim configs and plugins.
Helps the new LSP stack understand Neovim globals and runtime files automatically.
]]
return {
  "folke/neodev.nvim",
  ft = { "lua" },
}
