# Step 1 — Review 1

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 1 "Vimspector + lldb-dap adapter" |
| Branch | `cpp-debugging` (uncommitted working tree) |
| Files reviewed | `lua/plugins/vimspector.lua` (+93 / −2) |
| Date | 2026-11-08 |
| Verdict | **Changes requested.** Nothing blocking; 3 small fixes, then approve. |

## Summary

The implementation matches the step-1 spec and the plugin source. Every `<Plug>` name, the
`vimspector_adapters` / `vimspector_sign_priority` settings, the attach keys and the process-list
lookup were checked against the installed Vimspector, with file:line references. Using
`vim.empty_dict()` was a good catch: without it, an empty table would reach Vimspector as a list.
Making the formatter import conditional means step 2 can land without editing this file.

What's requested: a clearer error when `go` is missing, and two corrections to the plan document.
One checklist item needs the user to check by hand (do the keys reach Neovim in the terminal).

## Checks re-run by the reviewer

I didn't rely on the subagent's report. I re-ran these myself:

| Check | Command | Result |
| --- | --- | --- |
| Only the expected file changed | `git status --short` | ` M lua/plugins/vimspector.lua` ✅ |
| Clean startup | `nvim --headless "+qa"` | no output, exit 0 ✅ |
| `,D` mappings, n + x | `nmap ,D` / `xmap ,D` | `n ,DX`, `n ,Di`, `x ,Di` with descs ✅ |
| Spot-check F-keys | `nmap <F5>` / `nmap <S-F11>` | `<Plug>VimspectorContinue` / `<Plug>VimspectorStepOut` ✅ |
| Plugin loads eagerly | `lua/config/lazy.lua` | no `defaults.lazy = true`, so `config` runs at startup ✅ |
| `~/.lldbinit` concern | `ls ~/.lldbinit` | does not exist, so nothing can leak in today ✅ |

## Findings

### 1. Build step: unclear failure when `go` is missing — should fix

`lua/plugins/vimspector.lua:35-46`

```lua
  build = function(plugin)
    local go = vim.fn.exepath("go")
    if go == "" then
      go = "/usr/local/go/bin/go"
    end
    local result = vim.system({ go, "build" }, {
      cwd = plugin.dir .. "/support/vimspector_process_list",
      text = true,
    }):wait()
    if result.code ~= 0 then
      error("vimspector_process_list build failed: " .. (result.stderr or ""))
    end
  end,
```

**Comment:** If `go` isn't installed at all, `vim.system` throws its own spawn error (`ENOENT …`)
before the `result.code` check runs. You'd see a raw libuv error in `:Lazy` instead of the
helpful message. The subagent's report says this path was read but not tested. Check
`vim.fn.executable(go) == 1` before spawning, and raise a clear error that says *why* the helper
matters, e.g. `"go not found: needed to build vimspector_process_list (attach process picker)"`.
Then test it by pointing the fallback at a path that doesn't exist.

### 2. Plan: step 8 still says `,di` — should fix (doc)

`plans/cpp-debugging.md`, step 8

```markdown
- [ ] Watches and hover (`,di`) evaluate expressions; `target.import-std-module` remains off.
```

**Comment:** Debug keys moved to `,D` (decided 2026-11-08), so this should read `,Di`. The
subagent spotted this. It's a one-word fix, and keeping the plan correct is part of finishing
the step.

### 3. Plan: record how the adapter-level `pidSelect` behaves — should fix (doc)

`lua/plugins/vimspector.lua:61-62`

```lua
        -- Lets an attach config without a `pid` prompt for one.
        attach = { pidProperty = "pid", pidSelect = "ask" },
```

**Comment:** The code and its comment are correct. Vimspector only prompts when the attach config
has no `pid` (`debug_session.py:1734-1742`), and then it calls `_SelectProcess()` *without a name
filter*. Step 6 plans to set `pid` through `${PickProcess(...)}`, so this block is only a
fallback. Add one line to step 6 in the plan saying so. Otherwise whoever does step 6 may think
the adapter already provides the filtered picker.

### 4. Warning fires on every startup — no change

`lua/plugins/vimspector.lua:51-56`

```lua
    local lldb_dap = lldb_dap_path()
    if vim.fn.executable(lldb_dap) == 0 then
      vim.schedule(function()
        vim.notify("vimspector: lldb-dap not found (install Homebrew llvm)", vim.log.levels.WARN)
      end)
    end
```

**Comment:** This meets the plan's "warn once": once per startup. On a machine without LLVM it
would warn even in sessions with no debugging. Deferring the warning until a debug session starts
would be nicer, but it's not worth the complexity for a single-machine config. No change.

### 5. `<C-S-F5>` and `<S-F11>` may not reach Neovim — needs the user

`lua/plugins/vimspector.lua:86, 93`

```lua
    map("n", "<C-S-F5>", "<Plug>VimspectorRestart", { desc = "Debug: restart" })
    ...
    map("n", "<S-F11>", "<Plug>VimspectorStepOut", { desc = "Debug: step out" })
```

**Comment:** The mappings themselves are right. Whether the terminal sends distinct codes for
Ctrl+Shift+F5 and Shift+F11, and whether macOS takes F11 for Show Desktop, can only be checked by
pressing the keys. That's the step-1 checklist item "Verify each key reaches Neovim". It's left
for the user, and the F12 fallback from the plan applies if needed. Not something the subagent
can fix.

## Required before approval

- [ ] Finding 1: guard the `go` lookup and raise a clear error; test the missing-`go` path.
- [ ] Finding 2: fix `,di` → `,Di` in plan step 8.
- [ ] Finding 3: add the `pidSelect` fallback note to plan step 6.
- [ ] User result follow-up: in plan step 1, replace the "move step-out to F12" fallback with a
      note that macOS's Show Desktop shortcut (F11) must stay disabled, and tick the
      "keys reach Neovim" checkbox.

## Needs the user (manual)

- [ ] Press every key in the step-1 table in a normal buffer; report any that don't fire
      (`:verbose map` shows the mapping exists; the question is whether the terminal delivers
      the key).

### User result (2026-11-08)

- Every key except F11 showed "Vimspector not connected, start a debug session", which means it
  reached Vimspector. That includes `C-S-F5` and `S-F11`.
- F11 showed nothing because macOS took it for **Show Desktop**. The user turned that shortcut off
  (System Settings → Keyboard → Keyboard Shortcuts → Mission Control), and F11 now behaves like
  the rest. ✅
- Follow-up for the plan: step 1's fallback text says to move "step-out" to F12, but F11 is
  **step into**. Since F11 is now free, the fallback isn't needed; replace the text with a note
  saying the macOS Show Desktop shortcut must stay disabled.

## Step 1 checklist status

| Item | Status |
| --- | --- |
| Resolve adapter path + warn | ✅ done |
| `vimspector_adapters["lldb-dap"]`: command / attach / configuration | ✅ done |
| Sign priority 12 for BP family + NonActivePC | ✅ done (merge over defaults confirmed) |
| `g:vimspector_enable_mappings` unset | ✅ done |
| `build` compiles `vimspector_process_list` | ⚠️ done, finding 1 open |
| Key table mapped | ✅ done |
| Keys reach Neovim in the terminal | ✅ verified by user (after freeing F11 from macOS) |
