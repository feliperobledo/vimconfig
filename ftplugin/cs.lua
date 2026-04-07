-- C# filetype settings and LSP keymaps
-- Replaces the old OmniSharp Vimscript plugin keymaps with vim.lsp.buf.* equivalents.

vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true

-- C# region folding (zf% folds, zo unfolds)
vim.b.match_words = [[\s*#\s*region.*$:\s*#\s*endregion]]

vim.cmd("colorscheme codedark")

local map = function(lhs, rhs, desc, mode)
  vim.keymap.set(mode or "n", lhs, rhs, { buffer = true, desc = desc })
end

-- Navigation (on_attach already sets gd, but buffer-local is fine)
map("gd",          vim.lsp.buf.definition,        "LSP: Go to definition")
map("<Leader>fi",  vim.lsp.buf.implementation,    "LSP: Find implementations")
map("<Leader>fs",  vim.lsp.buf.workspace_symbol,  "LSP: Find symbol")
map("<Leader>fu",  vim.lsp.buf.references,        "LSP: Find usages")
map("<Leader>fm",  vim.lsp.buf.document_symbol,   "LSP: Find members")

-- Code actions / fixes
map("<Leader>fx",  vim.lsp.buf.code_action,       "LSP: Fix / code actions")
map("<Leader>cc",  function() vim.diagnostic.setqflist() end, "LSP: All diagnostics to quickfix")

-- Info
map("<Leader>tt",  vim.lsp.buf.hover,             "LSP: Type / hover info")
map("<Leader>dc",  vim.lsp.buf.hover,             "LSP: Documentation hover")
map("<C-\\>",      vim.lsp.buf.signature_help,    "LSP: Signature help")
map("<C-\\>",      vim.lsp.buf.signature_help,    "LSP: Signature help", "i")

-- Show diagnostics float on cursor hold (replaces OmniSharpTypeLookup autocmd)
vim.api.nvim_create_autocmd("CursorHold", {
  buffer = 0,
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})
