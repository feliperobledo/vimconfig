--[[
Provides ALE's asynchronous lint engine, currently used only to run OmniSharp checks for C# files.
This will be removed once the native LSP diagnostics pipeline replicates the same coverage.
]]
return {
  "dense-analysis/ale",
  config = function()
    vim.g.ale_linters = { cs = { "OmniSharp" } }
    vim.g.ale_linters_explicit = 1
  end,
}
