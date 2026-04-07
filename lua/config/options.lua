-- Leader (must be set before many plugins read it)
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Enable filetype plugins/indent in Lua style
vim.cmd('filetype plugin indent on')

-- Enable default vim completion
vim.opt.omnifunc = 'syntaxcomplete#Complete'

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Text width
vim.opt.textwidth = 140

-- Enable mouse support
vim.opt.mouse = 'a'

-- Show whitespace
vim.opt.list = true
vim.opt.listchars = {
  tab = ">-",
  trail = ".",
  precedes = "<",
  extends = ">",
}

--[[ 
Folding

Types
1. manual: in visual mode, press 
    z+f to fold
    z+o to open fold
    z+d to delete all lines in the fold
--]]
vim.opt.foldmethod = 'manual'

-- Keep cursor vertically cendered
vim.opt.scrolloff = 999

-- Use osX clipboard default
vim.opt.clipboard = 'unnamedplus'

-- Use project specific .vimrc files
vim.opt.exrc = true
vim.opt.secure = true -- TODO: verify

-- Cache / swap / undo directories
local cache = vim.fn.stdpath('cache')
local state = vim.fn.stdpath('state')

vim.opt.undodir = state .. '/undo'
vim.opt.backupdir = state .. '/backup'
vim.opt.directory = cache .. '/swap'

-- Keep sessions focused on the visible workspace instead of every hidden buffer.
-- This avoids restoring special buffers such as health pages or logs when using
-- `nvim -S`, which can trigger extra plugin/autocmd work during startup.
vim.opt.sessionoptions = {
  'curdir',
  'folds',
  'globals',
  'localoptions',
  'tabpages',
  'terminal',
  'winsize',
}

vim.opt.undofile = true
vim.opt.backup = true
vim.opt.swapfile = true

-- Python providers (Neovim still reads these globals)
vim.g.python_host_prog = vim.env.HOME .. '/.pyenv/versions/neovim2/bin/python'
vim.g.python3_host_prog = vim.env.HOME .. '/.pyenv/versions/3.9.8/bin/python'

-- Language/plugin globals
vim.g.coc_config_suggest_noselect = 1

-- C Language options (globals expected by syntax tooling)
vim.g.c_no_trail_space_error = 1
vim.g.c_no_tab_space_error = 1

-- Completion UI
vim.opt.completeopt = {'longest', 'menuone', 'preview'}

vim.api.nvim_set_hl(0, "CmpPMenu", { link = "NormalFloat" })
vim.api.nvim_set_hl(0, "CmpPMenuBorder", { link = "FloatBorder" })
vim.api.nvim_set_hl(0, "CmpPMenuSel", { link = "PmenuSel" })
vim.api.nvim_set_hl(0, "CmpDoc", { link = "NormalFloat" })
vim.api.nvim_set_hl(0, "CmpDocBorder", { link = "FloatBorder" })
