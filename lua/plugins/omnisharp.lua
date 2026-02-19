--[[
Legacy OmniSharp Vim client that currently powers C# language features.
Will be removed after the native LSP stack wires up omnisharp-roslyn through mason-lspconfig.
]]
return {
  "OmniSharp/omnisharp-vim",
  config = function()
    vim.g.OmniSharp_server_stdio = 1
    vim.g.OmniSharp_server_use_mono = 1
  end,
}
