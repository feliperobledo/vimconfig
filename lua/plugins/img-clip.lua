--[[
For pasting images into buffers that are on the clipboard.
Source: https://github.com/hakonharnes/img-clip.nvim
--]]
return {
    "hakonharnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
    },
    keys = {
        { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    }
}
