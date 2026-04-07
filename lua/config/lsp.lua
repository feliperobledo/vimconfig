local M = {}

local cmp_capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
  cmp_capabilities = cmp_nvim_lsp.default_capabilities(cmp_capabilities)
end

M.capabilities = cmp_capabilities

function M.on_attach(client, bufnr)
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
  end

  local type_definition = function()
    -- jdtls currently returns an invalid response for typeDefinition requests.
    if client.name == "jdtls" then
      vim.notify("LSP: type definition is not supported reliably for jdtls", vim.log.levels.WARN)
      return
    end

    vim.lsp.buf.type_definition()
  end

  map("gd", vim.lsp.buf.definition, "LSP: Go to definition")
  if client:supports_method("textDocument/typeDefinition") then
    map("gy", type_definition, "LSP: Type definition")
  end
  map("gr", vim.lsp.buf.references, "LSP: References")
  map("gI", vim.lsp.buf.implementation, "LSP: Implementation")
  map("K", vim.lsp.buf.hover, "LSP: Hover")
  map("<leader>rn", vim.lsp.buf.rename, "LSP: Rename symbol")
  map("<leader>ca", vim.lsp.buf.code_action, "LSP: Code action")
  map("<leader>f", function()
    vim.lsp.buf.format({ async = true })
  end, "LSP: Format buffer")

  map("[d", vim.diagnostic.goto_prev, "LSP: Previous diagnostic")
  map("]d", vim.diagnostic.goto_next, "LSP: Next diagnostic")
  map("<leader>e", vim.diagnostic.open_float, "LSP: Diagnostics float")
  map("<leader>q", vim.diagnostic.setloclist, "LSP: Diagnostics loclist")
end

return M
