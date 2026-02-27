--[[
Registers nvim-cmp, the completion engine that will replace CoC's insert-mode UI.
Dependencies declared here pull in snippet support and the various completion sources we rely on.
]]
return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
  }
}
