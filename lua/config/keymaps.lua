local map = vim.keymap.set

-- Disable arrow keys (insert + normal)
map("i", "<Up>", "<Nop>")
map("i", "<Down>", "<Nop>")
map("i", "<Left>", "<Nop>")
map("i", "<Right>", "<Nop>")

map("", "<Up>", "<Nop>")
map("", "<Down>", "<Nop>")
map("", "<Left>", "<Nop>")
map("", "<Right>", "<Nop>")

-- This keymap changes navigation between windows to only have to use 
-- Ctrl+h/j/k/l
map("n", "<C-J>", "<C-W>j<C-W>_")
map("n", "<C-K>", "<C-W>k<C-W>_")
map("n", "<C-L>", "<C-W>l<C-W>_")
map("n", "<C-H>", "<C-W>h<C-W>_")

-- Collapse each opened file into a single line with its filename
vim.opt.wmh = 0

map("n", "<F8>", ":tabprevious<CR>")
map("n", "<F9>", ":tabnext<CR>")
map("n", "<C-t>", ":tabnew<CR>")
map("i", "<F8>", "<Esc>:tabprevious<CR>i")
map("i", "<F9>", "<Esc>:tabnext<CR>i")
map("i", "<C-t>", "<Esc>:tabnew<CR>i")

-- Sessions
map("n", "<F2>", ":mksession! Session.vim<CR>")
map("n", "<F3>", ":source Session.vim<CR>")

-- Telescope mappings (since “latest Neovim”, we can assume Telescope exists)
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>")
map("n", "<leader>ft", "<cmd>Telescope git_files<cr>")

-- Virtual tabstops using spaces (your my_tab=4)
local my_tab = 4
vim.opt.shiftwidth = my_tab
vim.opt.softtabstop = my_tab
vim.opt.expandtab = true

-- Toggle tabs/spaces (F10 mapping)
-- allow toggling between local and default mode
local function tab_toggle()
  if vim.opt.expandtab:get() then
    vim.opt.shiftwidth = 8
    vim.opt.softtabstop = 0
    vim.opt.expandtab = false
  else
    vim.opt.shiftwidth = my_tab
    vim.opt.softtabstop = my_tab
    vim.opt.expandtab = true
  end
end

map("n", "<F10>", function()
      -- mimic: mz ... 'z (keep cursor position)
      local pos = vim.api.nvim_win_get_cursor(0)
      tab_toggle()
      vim.api.nvim_win_set_cursor(0, pos)
    end
)

-- Move visual selection
map("v", "J", ":m '>+1<cr>gv=gv")
map("v", "K", ":m '<-2<cr>gv=gv")

-- Delete without yanking
-- Resource: https://superuser.com/questions/321547/how-do-i-replace-paste-yanked-text-in-vim-without-yanking-the-deleted-lines
map({ "n", "v" }, "<leader>d", '"_d')

-- Paste over selection without yanking replaced text
map("v", "p", '"_dP')

-- Custom LSP Keybindings
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf })
    end
})

-- [C]odeCompanion [P]rompt]
vim.keymap.set({ "n", "v" }, "<LocalLeader>cp", function()
  return require("codecompanion").cli({ prompt = true })
end, { desc = "Prompt the CLI agent" })
