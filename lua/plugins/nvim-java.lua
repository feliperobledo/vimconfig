--[[
Specific plugin for java development.
Uses jdtls as the LSP server, which is a popular choice for Java development in Neovim. This plugin provides additional features and configurations tailored for Java development, such as code navigation, refactoring, and debugging support.
]]
return {
  'nvim-java/nvim-java',
  config = function()
    require('java').setup()
    vim.lsp.enable('jdtls')
  end,
}
