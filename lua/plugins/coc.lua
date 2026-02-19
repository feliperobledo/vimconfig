--[[
Legacy CoC configuration that powers completion, diagnostics, and code actions across most languages today.
Kept in place until the native LSP + nvim-cmp stack can replace these features and the listed extensions.
]]
return {
  "neoclide/coc.nvim",
  branch = "release",
  config = function()
    vim.g.coc_global_extensions = {
      "coc-json",
      "coc-tsserver",
      "coc-eslint",
      "coc-python",
      "coc-pyls",
      "coc-css",
      "coc-highlight",
      "coc-lua",
      "coc-rust-analyzer",
      "coc-sql",
    }
  end,
}
