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

-- Tab navigation uses the built-in gt/gT; F8 and F9 are left free for the debugger.
map("n", "<C-t>", ":tabnew<CR>")
map("i", "<C-t>", "<Esc>:tabnew<CR>i")

-- Sessions
-- Vimspector's session (breakpoints) lives next to Session.vim, in the cwd. An explicit
-- path skips Vimspector's upward search from the current buffer, which could pick up a
-- stray session file in a parent directory.
local function vimspector_session_file()
  local name = vim.g.vimspector_session_file_name or ".vimspector.session"
  return vim.fn.getcwd() .. "/" .. name
end

map("n", "<F2>", function()
  vim.cmd("mksession! Session.vim")
  local file = vimspector_session_file()
  local breakpoints = vim.fn["vimspector#GetBreakpointsAsQuickFix"]()
  local has_breakpoints = type(breakpoints) == "table" and #breakpoints > 0
  -- Save only when there is something to keep, or a file to update, so clearing
  -- every breakpoint still sticks but projects that never debug stay clean.
  if has_breakpoints or vim.fn.filereadable(file) == 1 then
    -- What :VimspectorMkSession runs; calling it directly avoids escaping the path.
    vim.fn["vimspector#WriteSessionFile"](file)
  end
end)

map("n", "<F3>", function()
  -- Resolve before sourcing: Session.vim may change the cwd.
  local file = vimspector_session_file()
  -- pcall keeps a missing Session.vim to the one-line Vim error, not a Lua traceback.
  local ok, err = pcall(vim.cmd, "source Session.vim")
  if not ok then
    vim.notify(err:match("E%d+:.*") or err, vim.log.levels.ERROR)
    return
  end
  -- After Session.vim, so signs go straight into the buffers it reopened (Vimspector
  -- places signs for files opened later itself). Skipped when there's no file: the bare
  -- command would report an error.
  if vim.fn.filereadable(file) == 1 then
    vim.fn["vimspector#ReadSessionFile"](file)
  end
end)

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

-- Toggle tabs/spaces
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

map("n", "<leader>ts", function()
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

-- Wrap an `vim.lsp.buf` jump function so it reuses a tab that already shows the
-- target file and opens a new tab only when none does. `what` names the thing
-- being looked up, for the "not found" message.
local function tab_jump(lsp_fn, what)
  return function()
    lsp_fn({
      -- on_list runs only after the server answers, so we never open an empty
      -- tab when there is nothing to jump to.
      on_list = function(result)
        local items = result.items
        if #items == 0 then
          vim.notify("No " .. what .. " found", vim.log.levels.WARN)
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
end

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local opts = { buffer = args.buf }
        vim.keymap.set("n", "gd", tab_jump(vim.lsp.buf.definition, "definition"), opts)
        -- Override the stock gri/grt so they land in a tab like gd does.
        vim.keymap.set("n", "gri", tab_jump(vim.lsp.buf.implementation, "implementation"), opts)
        vim.keymap.set("n", "grt", tab_jump(vim.lsp.buf.type_definition, "type definition"), opts)
    end
})

-- [C]odeCompanion [P]rompt]
vim.keymap.set({ "n", "v" }, "<LocalLeader>cp", function()
  return require("codecompanion").cli({ prompt = true })
end, { desc = "Prompt the CLI agent" })
