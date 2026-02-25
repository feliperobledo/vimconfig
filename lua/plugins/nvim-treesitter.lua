--[[
    nvim-treesitter configuration for Neovim.

    This configuration sets up the nvim-treesitter plugin to provide enhanced syntax highlighting and indentation
    for various programming languages. The plugin is configured to automatically install parsers for a specified
    list of languages and to update them when necessary.

    Key Features:
    - Automatic installation of language parsers.
    - Syntax highlighting based on tree-sitter parsing.
    - Improved indentation based on syntax structure.
    - Commands for managing tree-sitter parsers.

    Usage:
    - The plugin will be loaded when a buffer is read (BufReadPost event).
    - You can use the provided commands to manage tree-sitter parsers, such as installing new ones or updating existing ones.

    Note:
    - Ensure that you have the necessary build tools installed to compile tree-sitter parsers.
]]
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  auto_install = true,
  lazy = false,
  cmd = {
    "TSInstall",
    "TSUpdate",
    "TSInstallInfo",
    "TSEnable",
    "TSDisable",
    "TSModuleInfo",
    "TSUninstall",
  },
  opts = {
    ensure_installed = {
      "c",
      "cpp",
      "css",
      "gitignore",
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
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
    },
  },
}
