--[[
Configures lualine for a themable statusline that plays nicely with lazy loading.
Keeps the Onedark look consistent while we iterate on other UI pieces.
]]
return {
  "nvim-lualine/lualine.nvim",
  config = function()
    require("lualine").setup({
        options = {
            theme = "onedark"
        }
    })
  end
}
