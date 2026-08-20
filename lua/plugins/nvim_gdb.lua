--[[
Adds nvim-gdb for interactive debugging sessions directly inside Neovim.
Still valuable even after the LSP migration because it focuses on gdb integration rather than language servers.
]]
return {
  "sakhnik/nvim-gdb",
  build = "./install.sh",
}
