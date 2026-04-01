--[[
Specific plugin for java development.
Uses jdtls as the LSP server, which is a popular choice for Java development in Neovim. This plugin provides additional features and configurations tailored for Java development, such as code navigation, refactoring, and debugging support.
]]
return {
  'nvim-java/nvim-java',
  config = function()
    local lsp = require("config.lsp")

    require('java').setup({
      jdk = {
        auto_install = false,
      },
    })
    vim.lsp.config('jdtls', {
      capabilities = lsp.capabilities,
      on_attach = lsp.on_attach,
    })
    vim.lsp.enable('jdtls')
  end,
}
