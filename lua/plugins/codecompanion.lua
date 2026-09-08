return {
    "olimorris/codecompanion.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "ravitemer/mcphub.nvim", -- for extended MCP capabilities
    },
    opts = {
       adapters = {
          http = {
            openai_responses = function()
              return require("codecompanion.adapters").extend("openai_responses", {
                schema = {
                  top_p = {
                    ---@type fun(self: CodeCompanion.HTTPAdapter): boolean | boolean
                    enabled = function(self)
                      local model = self.schema.model.default
                      if model:find("codex%") or model:find("luna") then
                        return false
                      end
                      return true
                    end
                  },
                },
              })
            end,
          },
        },
        interactions = {
          chat = {
            adapter = "openai",
            model = "gpt-5.6-terra"
          },
          inline = {
              adapter = "openai_responses",
              model = "gpt-5.6-luna"
          },
          cli = {
            agent = "claude_code",
            agents = {
              claude_code = {
                cmd = "claude",
                args = {},
                description = "Claude Code CLI",
                provider = "terminal",
              },
            },
          },
        },
        opts = {
            log_level = "DEBUG",
        }
    }
}
