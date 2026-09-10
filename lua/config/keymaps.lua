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

-- Find a window already showing `path`, preferring one in the current tab.
-- Paths are compared after resolving symlinks, since the LSP reports real paths.
local function find_win_for_file(path)
  local target = vim.uv.fs_realpath(path) or path
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" and (vim.uv.fs_realpath(name) or name) == target then
      local wins = vim.fn.win_findbuf(buf)
      local current_tab = vim.api.nvim_get_current_tabpage()
      for _, win in ipairs(wins) do
        if vim.api.nvim_win_get_tabpage(win) == current_tab then
          return win
        end
      end
      return wins[1]
    end
  end
end

-- Jump to definition, reusing a tab that already shows the file and opening a
-- new tab only when none does.
local function goto_definition()
  vim.lsp.buf.definition({
    -- on_list runs only after the server answers, so we never open an empty
    -- tab when there is no definition to jump to.
    on_list = function(result)
      local items = result.items
      if #items == 0 then
        vim.notify("No definition found", vim.log.levels.WARN)
        return
      end
      if #items > 1 then
        -- Ambiguous: fall back to the quickfix list instead of guessing.
        vim.fn.setqflist({}, " ", result)
        vim.cmd("botright copen")
        return
      end

      local item = items[1]
      local win = find_win_for_file(item.filename)
      if win then
        -- Also switches to the window's tab if it lives in another one.
        vim.api.nvim_set_current_win(win)
      else
        -- :tabedit opens the file in a fresh tab and focuses it.
        vim.cmd.tabedit(vim.fn.fnameescape(item.filename))
      end
      -- Record the pre-jump position so <C-o> works for jumps within a file.
      vim.cmd("normal! m'")
      vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
      vim.cmd("normal! zz")
    end,
  })
end

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        vim.keymap.set("n", "gd", goto_definition, { buffer = args.buf })
    end
})

-- [C]odeCompanion [P]rompt]
vim.keymap.set({ "n", "v" }, "<LocalLeader>cp", function()
  return require("codecompanion").cli({ prompt = true })
end, { desc = "Prompt the CLI agent" })
