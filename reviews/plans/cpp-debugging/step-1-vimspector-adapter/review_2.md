# Step 1 — Review 2

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 1 "Vimspector + lldb-dap adapter" |
| Branch | `cpp-debugging` (uncommitted, on top of `3581d50`) |
| Files reviewed | `lua/plugins/vimspector.lua` (round-2 change: +4), `plans/cpp-debugging.md` (+7 / −3) |
| Previous review | `review_1.md` |
| Date | 2026-11-08 |
| Verdict | **Approved.** All items from review 1 are resolved; ready to commit. |

## Summary

All four items from review 1 were addressed, and each fix is no bigger than it needed to be. The
subagent actually ran the missing-`go` path instead of only reading the code, and then restored
the file and confirmed the normal build still works. The plan corrections match the decisions
made in this session.

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Changed files | `git status --short` | ` M lua/plugins/vimspector.lua`, ` M plans/cpp-debugging.md`, `?? reviews/` ✅ |
| Clean startup | `nvim --headless "+qa"` | no output, exit 0 ✅ |
| Helper binary present after rebuild | `ls -la …/support/vimspector_process_list/vimspector_process_list` | 755, 3.6M ✅ |
| Fallback restored | `sed -n 33,52p lua/plugins/vimspector.lua` | `go = "/usr/local/go/bin/go"` (not the `/nonexistent/go` test value) ✅ |
| No stray `,di` left in plan | `grep -n ",di\b" plans/cpp-debugging.md` | no matches ✅ |
| Only the agreed box ticked | `grep -c "\[x\]" plans/cpp-debugging.md` | 1 (the "keys reach Neovim" item) ✅ |

## Review 1 items

### Finding 1 — missing-`go` error: resolved

`lua/plugins/vimspector.lua:35-51`

```lua
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
```

**Comment:** This is what was asked for. The check runs before the spawn, and the message says
what failed and why it matters. The subagent's test with `go` missing produced the message in
`:Lazy`'s output:
`vimspector.lua:42: go not found: needed to build vimspector_process_list (attach process picker)`.
lazy still prints "Finished task build" after the error, but that's lazy's own output, not
something to fix here.

### Finding 2 — plan step 8 `,di` → `,Di`: resolved

`plans/cpp-debugging.md:219`

```markdown
- [ ] Watches and hover (`,Di`) evaluate expressions; `target.import-std-module` remains off.
```

**Comment:** Fixed. No other `,di` references are left.

### Finding 3 — `pidSelect` fallback note in step 6: resolved

`plans/cpp-debugging.md:159-161`

```markdown
      Note: the step-1 adapter's `pidSelect = "ask"` only prompts when an attach config has no
      `pid`, and then lists every process with no name filter (`debug_session.py:1734-1742`).
      `${PickProcess(...)}` sets `pid` itself, so the adapter block is only a fallback.
```

**Comment:** Clear, and it cites the source. Making it a note instead of a new checkbox was the
right call: it's context for step 6, not a task to do.

### User follow-up — F11 note and checkbox: resolved

`plans/cpp-debugging.md:113-115`

```markdown
- [x] Verify each key reaches Neovim in the terminal in use. macOS's Show Desktop shortcut on `F11`
      (System Settings → Keyboard → Keyboard Shortcuts → Mission Control) must stay disabled, or it
      swallows step-into.
```

**Comment:** Correct. The wrong "step-out" fallback is gone, and the box is ticked because of the
user's manual check. When step 9 updates `CLAUDE.md`, this macOS requirement should be carried
into its debugging section.

## New findings

None.

## Next actions (subagent)

- [ ] Tick the remaining step-1 checkboxes in `plans/cpp-debugging.md`.
- [ ] Commit step 1 on `cpp-debugging`: `lua/plugins/vimspector.lua`, `plans/cpp-debugging.md`,
      and `reviews/plans/cpp-debugging/step-1-vimspector-adapter/`.

## Step 1 checklist status

| Item | Status |
| --- | --- |
| Resolve adapter path + warn | ✅ |
| `vimspector_adapters["lldb-dap"]`: command / attach / configuration | ✅ |
| Sign priority 12 for BP family + NonActivePC | ✅ |
| `g:vimspector_enable_mappings` unset | ✅ |
| `build` compiles `vimspector_process_list` | ✅ (finding 1 resolved) |
| Key table mapped | ✅ |
| Keys reach Neovim in the terminal | ✅ verified by user |
