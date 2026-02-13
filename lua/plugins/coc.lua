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
