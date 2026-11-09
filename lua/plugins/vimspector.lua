--[[
Vimspector is the C/C++ debug client (chosen for its UI), driving Homebrew LLVM's lldb-dap
through a custom adapter rather than a downloaded gadget. nvim-dap stays only for nvim-java.
See plans/cpp-debugging.md.
]]

-- `exepath` hits when Neovim starts from a shell (~/.zshrc puts llvm/bin on PATH);
-- the Homebrew path covers launches that don't inherit it.
local function lldb_dap_path()
  local path = vim.fn.exepath("lldb-dap")
  if path ~= "" then
    return path
  end
  return "/opt/homebrew/opt/llvm/bin/lldb-dap"
end

local function adapter_configuration()
  -- Use vim.empty_dict() so an empty table reaches Vimspector as a dict, not a list.
  local configuration = vim.empty_dict()
  -- The std::expected formatter is optional: only import it once the file exists.
  -- A project's own `initCommands` replaces this list (Vimspector merges shallowly),
  -- so projects should use `sourceMap` etc. instead of `initCommands`.
  local formatter = vim.fn.stdpath("config") .. "/lldb/libcxx_expected.py"
  if vim.fn.filereadable(formatter) == 1 then
    configuration.initCommands = { string.format('command script import "%s"', formatter) }
  end
  return configuration
end

return {
  "puremourning/vimspector",

  -- Builds the helper behind ${PickProcess()}; upstream ships it as Go source only.
  -- Falls back to the default Go install path when Neovim's PATH lacks it.
  build = function(plugin)
    local go = vim.fn.exepath("go")
    if go == "" then
      go = "/usr/local/go/bin/go"
    end
    -- Check first: vim.system would otherwise throw a raw ENOENT spawn error.
    if vim.fn.executable(go) ~= 1 then
      error("go not found: needed to build vimspector_process_list (attach process picker)")
    end
    local result = vim.system({ go, "build" }, {
      cwd = plugin.dir .. "/support/vimspector_process_list",
      text = true,
    }):wait()
    if result.code ~= 0 then
      error("vimspector_process_list build failed: " .. (result.stderr or ""))
    end
  end,

  -- Globals must exist before the plugin's plugin/ file runs, hence `init`, not `config`.
  init = function()
    local lldb_dap = lldb_dap_path()
    if vim.fn.executable(lldb_dap) == 0 then
      vim.schedule(function()
        vim.notify("vimspector: lldb-dap not found (install Homebrew llvm)", vim.log.levels.WARN)
      end)
    end

    vim.g.vimspector_adapters = {
      ["lldb-dap"] = {
        command = { lldb_dap },
        -- No `attach` block: with `pidSelect = "ask"`, Vimspector asks for a PID (from an
        -- unfiltered process list) whenever an attach config has no `pid`, which breaks
        -- `waitFor` configs. Attach configs get their pid from ${PickProcess()} instead.
        configuration = adapter_configuration(),
      },
    }

    -- Above gitgutter's 10 so breakpoints stay visible on changed lines. Vimspector
    -- merges this over its defaults, so the PC/frame signs keep their 200. These must
    -- stay equal for Vimspector to combine the breakpoint and non-active PC signs.
    vim.g.vimspector_sign_priority = {
      vimspectorBP = 12,
      vimspectorBPCond = 12,
      vimspectorBPLog = 12,
      vimspectorBPDisabled = 12,
      vimspectorNonActivePC = 12,
    }
  end,

  -- g:vimspector_enable_mappings stays unset; these are the explicit replacements.
  -- Leader debug keys live under ,D: ,d is the "_d operator and must not wait for more keys.
  config = function()
    local map = vim.keymap.set

    map("n", "<F5>", "<Plug>VimspectorContinue", { desc = "Debug: launch / continue" })
    map("n", "<S-F5>", "<Plug>VimspectorStop", { desc = "Debug: stop" })
    map("n", "<C-S-F5>", "<Plug>VimspectorRestart", { desc = "Debug: restart" })
    map("n", "<F6>", "<Plug>VimspectorPause", { desc = "Debug: pause" })
    map("n", "<F8>", "<Plug>VimspectorAddFunctionBreakpoint", { desc = "Debug: function breakpoint" })
    map("n", "<F9>", "<Plug>VimspectorToggleBreakpoint", { desc = "Debug: toggle breakpoint" })
    map("n", "<leader><F9>", "<Plug>VimspectorToggleConditionalBreakpoint", { desc = "Debug: conditional breakpoint" })
    map("n", "<F10>", "<Plug>VimspectorStepOver", { desc = "Debug: step over" })
    map("n", "<F11>", "<Plug>VimspectorStepInto", { desc = "Debug: step into" })
    map("n", "<S-F11>", "<Plug>VimspectorStepOut", { desc = "Debug: step out" })
    map("n", "<leader><F10>", "<Plug>VimspectorRunToCursor", { desc = "Debug: run to cursor" })
    map({ "n", "x" }, "<leader>Di", "<Plug>VimspectorBalloonEval", { desc = "Debug: inspect value under cursor" })
    -- Non-interactive Reset: unlike :VimspectorReset it never asks "Terminate debuggee?".
    -- It sends a plain disconnect, so lldb-dap detaches: an attached process keeps running. A
    -- launched one (runInTerminal, which lldb-dap attaches to) is then killed by the launch
    -- config's terminateCommands (templates/vimspector-cpp.json, lua/config/cmake_debug.lua).
    map("n", "<leader>DX", "<cmd>call vimspector#Reset()<cr>", { desc = "Debug: reset (detach / end session, close UI)" })
  end,
}
