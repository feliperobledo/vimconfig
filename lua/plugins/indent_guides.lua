return {
  "nathanaelkane/vim-indent-guides",
  config = function()
    vim.g.indent_guides_enable_on_vim_startup = 0
    vim.g.indent_guides_auto_colors = 0
    vim.g.indent_guides_start_level = 2
    vim.g.indent_guides_guide_size = 1
    vim.g.indext_guides_color_change_percent = 1

    local group = vim.api.nvim_create_augroup("indent_guides_highlight", { clear = true })
    vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
      group = group,
      callback = function()
        vim.cmd("hi IndentGuidesOdd  ctermbg=22")
        vim.cmd("hi IndentGuidesEven ctermbg=136")
      end,
    })
  end,
}
