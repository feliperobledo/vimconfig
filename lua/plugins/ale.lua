return {
  "dense-analysis/ale",
  config = function()
    vim.g.ale_linters = { cs = { "OmniSharp" } }
    vim.g.ale_linters_explicit = 1
  end,
}
