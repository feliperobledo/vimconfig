local augroup = vim.api.nvim_create_augroup

-- Relative toggle group (from 'augroup numbertoggle')
local numbertoggle = augroup('numbertoggle', { clear = true })

vim.api.nvim_create_autocmd(
  { 'BufEnter', 'FocusGained', 'InsertLeave' },
  {
    group = numbertoggle,
    callback = function()
        vim.opt.relativenumber = true
    end
  }
)

vim.api.nvim_create_autocmd(
    { 'BufLeave', 'FocusLost', 'InsertEnter' },
    {
      group = numbertoggle,
      callback = function()
          vim.opt.relativenumber = false
      end
    }
)

-- Close neovim if the only window left is a NERDTree
-- (todo: switch to nvim-tree and update this)
vim.api.nvim_create_autocmd(
  'BufEnter',
  {
    group = augroup('nerdtree_close', { clear = true }),
    callback = function()
        -- Equivalent to: if (winnr("$")==1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
        if vim.fn.winnr('$') == 1 and vim.b.NERDTree and vim.b.NERDTree.isTabTree and vim.b.NERDTree.isTabTree() then
            vim.cmd('quit')
        end
    end
  }
)

-- Filetype-specific indentation (my autocmd file)
local ft = augroup('filetype_indent', { clear = true })

local function set_indent(sw, expandtab)
    vim.opt_local.tabstop = sw
    vim.opt_local.shiftwidth = sw
    vim.opt_local.softtabstop = sw
    vim.opt_local.expandtab = expandtab
end

vim.api.nvim_create_autocmd(
    'FileType',
    {
        group = ft,
        pattern = { "javascript", "cpp", "html", "typescript"},
        callback = function()
            set_indent(4, true)
        end
    }
)

vim.api.nvim_create_autocmd(
    'FileType',
    {
        group = ft,
        pattern = { "json", "ruby" },
        callback = function()
            set_indent(2, true)
        end
    }
)

-- *.feature treated as ruby syntax
vim.api.nvim_create_autocmd(
    { 'BufRead', 'BufNewFile' },
    {
        group = ft,
        pattern = "*.feature",
        callback = function() 
            vim.bo.filetype = "ruby"
        end
    }
)
