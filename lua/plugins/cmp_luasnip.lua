--[[
Registers LuaSnip as a completion source so snippet expansions show up in the nvim-cmp menu.
Provides the glue that lets us confirm a completion and immediately expand snippet bodies.
]]
return {
  "saadparwaiz1/cmp_luasnip",
  dependencies = {
    "hrsh7th/nvim-cmp",
    "L3MON4D3/LuaSnip",
  },
}
