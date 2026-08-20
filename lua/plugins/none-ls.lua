
return {
    'nvimtools/none-ls.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = function()
        local null_ls = require("null-ls")
        return {
            sources = {
                null_ls.builtins.formatting.prettier,
                null_ls.builtins.formatting.black,
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.formatting.rubocop,
                null_ls.builtins.formatting.sql_formatter,
                null_ls.builtins.formatting.markdownlint,
                null_ls.builtins.formatting.htmlbeautifier,
                null_ls.builtins.diagnostics.markdownlint,
                null_ls.builtins.diagnostics.clang_format
            },
        }
    end
}
