-- C# filetype settings

vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true

-- C# region folding (zf% folds, zo unfolds)
vim.b.match_words = [[\s*#\s*region.*$:\s*#\s*endregion]]

vim.cmd("colorscheme codedark")
