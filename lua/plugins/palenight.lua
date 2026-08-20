--[[
Provides the Palenight colorscheme, another fallback theme from the original setup.
We keep it for now to avoid surprising users while UI work is still in flux.
]]
return {
  "drewtempelmeyer/palenight.vim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("palenight")
  end,
}
