--[[
Provides Tree-sitter parsing so highlighting, indentation, and text objects stay modern without legacy syntax packs.
Auto-installs parsers for our main languages and keeps them updated via :TSUpdate.
]]
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
    },
    ensure_installed = {
      "bash",
      "c",
      "cpp",
      "css",
      "gitignore",
      "graphql",
      "html",
      "java",
      "javadoc",
      "javascript",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "python",
      "tsx",
      "typescript",
      "vim",
      "yaml",
    },
  }
}
