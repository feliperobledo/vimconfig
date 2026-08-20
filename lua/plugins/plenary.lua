--[[
Pulls in plenary, the utility library required by Telescope and many modern plugins.
Acts as a shared dependency so we explicitly track it instead of relying on implicit loads.
]]
return {
  "nvim-lua/plenary.nvim",
}
