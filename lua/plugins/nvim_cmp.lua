--[[
Registers nvim-cmp, the completion engine that replaces the old CoC completion UI.
Everything needed to configure sources, mappings, and windows lives here so the plugin
remains self-contained.
]]
return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "onsails/lspkind-nvim",
  },
  config = function()
    local cmp = require("cmp")
    local lspkind = require("lspkind")

    local function has_words_before()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      if col == 0 then
        return false
      end
      local current = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
      return current:sub(col, col):match("%s") == nil
    end

    cmp.setup({
      snippet = {
        expand = function(args)
          if vim.snippet and vim.snippet.expand then
            vim.snippet.expand(args.body)
          else
            vim.api.nvim_put({ args.body }, "c", true, true)
          end
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
      }, {
        { name = "buffer" },
        { name = "path" },
      }),
      window = {
        completion = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:CmpDoc,FloatBorder:CmpDocBorder",
        }),
        documentation = cmp.config.window.bordered({
            border = "rounded",
            winhighlight = "Normal:CmpDoc,FloatBorder:CmpDocBorder",
        }),
      },
      formatting = {
       fields = { "abbr", "icon", "kind", "menu" },
        format = lspkind.cmp_format({
            maxwidth = {
               -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
               -- can also be a function to dynamically calculate max width such as
               -- menu = function() return math.floor(0.45 * vim.o.columns) end,
               menu = 50, -- leading text (labelDetails)
               abbr = 50, -- actual suggestion item
             },
             ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
             show_labelDetails = false, -- show labelDetails in menu. Disabled by default
             menu = {
               nvim_lsp = "[LSP]",
               buffer = "[Buf]",
               path = "[Path]",
               cmdline = "[Cmd]",
             },

             -- The function below will be called before any actual modifications from lspkind
             -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
             before = function (entry, vim_item)
               -- ...
               return vim_item
             end
        })
      },
    })

    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })

    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = "path" },
      }, {
        { name = "cmdline" },
      }),
    })
  end,
}
