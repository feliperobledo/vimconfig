--[[
Provides Tree-sitter parsing so highlighting, indentation, and text objects stay modern without legacy syntax packs.
Auto-installs parsers for our main languages and keeps them updated via :TSUpdate.
]]
local treesitter_by_parser = {
  bash = "bash",
  c = "c",
  cpp = "cpp",
  css = "css",
  gitignore = "gitignore",
  graphql = "graphql",
  hcl = "hcl",
  html = "html",
  java = "java",
  javascript = { "javascript", "javascriptreact" },
  javadoc = false,
  json = "json",
  lua = "lua",
  markdown = "markdown",
  markdown_inline = false,
  python = "python",
  terraform = "terraform",
  tsx = "typescriptreact",
  typescript = "typescript",
  vim = "vim",
  yaml = "yaml",
}

local function collect_treesitter_parsers()
  local parsers = {}
  for parser, _ in pairs(treesitter_by_parser) do
    table.insert(parsers, parser)
  end

  table.sort(parsers)
  return parsers
end

local function collect_treesitter_filetypes()
  local filetypes = {}
  for _, filetype in pairs(treesitter_by_parser) do
    if type(filetype) == "table" then
      for _, alias in ipairs(filetype) do
        table.insert(filetypes, alias)
      end
    elseif filetype then
      table.insert(filetypes, filetype)
    end
  end

  table.sort(filetypes)
  return filetypes
end

local treesitter_languages = collect_treesitter_parsers()
local treesitter_filetypes = collect_treesitter_filetypes()

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = treesitter_filetypes,
      callback = function(args)
        local bufnr = args.buf
        local ok = pcall(vim.treesitter.start, bufnr)
        if ok then
          vim.bo[bufnr].syntax = "off"
        end
      end,
    })
  end,
  config = function()
    -- On the main branch, setup() only accepts install_dir; parsers must be
    -- requested explicitly. install() skips languages already on disk.
    require("nvim-treesitter").setup()
    require("nvim-treesitter").install(treesitter_languages)
  end,
}
