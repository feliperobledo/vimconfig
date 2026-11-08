# Step 6 — Review 1

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 6 "Attach to a running process" |
| Branch | `cpp-debugging` (uncommitted, on top of `342324d`) |
| Files reviewed | `templates/vimspector-cpp.json` (+48), `lua/plugins/vimspector.lua` (+3 / −2), `CLAUDE.md` (+4) |
| Date | 2026-11-08 |
| Verdict | **Changes requested.** Attach works on magister. One safety fix for `,DX`, and plan corrections. |

## Summary

Attach works end to end, on the real target. On magister the subagent:
- attached by PID while the triangle was rendering;
- stopped in `drawFrame` with locals (`images: size=3`, `recordSuccess: true`);
- continued, detached, and confirmed with `sample` that the render loop was still running;
- caught startup code with `waitFor`.

The investigation found four places where the plan was wrong, each backed by source and a test:

1. **`${PickProcess("${program}")}` matches nothing.** The picker filters by process *name* with
   a regex, and `${program}` is a path. Fixed with a `basename` shell variable and an anchored
   `^…$$` pattern.
2. **The `pid` must be `pid#json`.** Vimspector's substitution always produces a string, and
   lldb-dap rejects it: `expected uint64_t at arguments.pid`.
3. **The step-1 adapter's `pidSelect = "ask"` is not a harmless fallback.** It takes over every
   attach configuration without a `pid`, which includes `waitFor`, and it hung the headless run.
4. **`waitFor` arrives about 40–50 ms late**, so it can't catch the first lines of `main`.

The subagent removed the adapter `attach` block, which is a step-1 file outside its scope.
Removing it is the right fix, and the change is justified in the code comment and the report.
The rejected alternatives (`pid: 0`, an inline `extends` adapter) would have been worse.

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Changed files | `git status --porcelain --untracked-files=all` | `CLAUDE.md`, `lua/plugins/vimspector.lua`, `templates/vimspector-cpp.json` ✅ |
| Template parses with Vimspector's loader | `python3 -I`: `json.loads(minify(...))` | 3 configs: `Launch` (launch), `Attach (pick process)` (attach, `pid#json`), `Attach (wait for launch)` (attach, `waitFor`); all with the 4 exception filters ✅ |
| Adapter change is only the `attach` block | `git diff lua/plugins/vimspector.lua` | −`attach = {…}`, +3-line comment ✅ |
| No stray processes | `pgrep -fl "magister\|looper"` | none ✅ |
| magister untouched | `git -C …/magister status --porcelain` | empty ✅ |
| Clean startup | `nvim --headless "+qa"` | no output, exit 0 ✅ |
| Can `,DX` skip the terminate prompt? | `plugin/vimspector.vim:182-183`, `autoload/vimspector.vim:150-158`, `debug_session.py:612-633` | yes; see finding 1 |

## Findings

### 1. `,DX` can kill an attached game with one wrong keystroke — should fix

`lua/plugins/vimspector.lua`, `config`

```lua
    map("n", "<leader>DX", "<cmd>VimspectorReset<cr>", { desc = "Debug: reset (close debug UI)" })
```

**Comment:** The subagent showed that `:VimspectorReset` always asks "Terminate debuggee?
(Y)es (N)o (D)efault" for a live attached process, and that Y kills it. Step 6's requirement is
that stopping the debugger never kills an attached process. A muscle-memory "y" breaks that. The
command is defined as:

```vim
command! -bar
      \ VimspectorReset
      \ call vimspector#Reset( { 'interactive': v:true } )
```

and `debug_session.py:630-633` takes `interactive = False` by default. Called *without* the
option, Reset uses `StopAllSessions(interactive=False)`, which sends a plain `disconnect {}`. The
subagent already proved that leaves an attached process running. For a *launched* process,
lldb-dap's default for `disconnect {}` should be to terminate it, which is what you want there.
Map `,DX` to `<cmd>call vimspector#Reset()<cr>`, update the comment and `desc`, and verify both
cases with the driver:

- attach → `,DX` → process alive and output still growing;
- launch → `,DX` → the launched debuggee is gone (no orphan).

`:VimspectorReset` itself is still there for anyone who wants the prompt.

### 2. Plan step 1 and step 6 describe the old adapter — should fix (doc)

`plans/cpp-debugging.md`, step 1 (ticked) and step 6

```markdown
  - [x] `attach = { pidProperty = "pid", pidSelect = "ask" }`
```

```markdown
      Note: the step-1 adapter's `pidSelect = "ask"` only prompts when an attach config has no
      `pid`, and then lists every process with no name filter (`debug_session.py:1734-1742`).
      `${PickProcess(...)}` sets `pid` itself, so the adapter block is only a fallback.
```

**Comment:** Both are now false. Keep step 1's ticked line (it's history), but add a note under
it: "removed in step 6: it hijacked `waitFor` configs" (with a pointer to step 6). Replace step 6's
"only a fallback" note with what was learned: the block took over every attach config without a
`pid`, so it was removed.

### 3. Step 6 items still carry the wrong suggestions — should fix (doc)

`plans/cpp-debugging.md`, step 6

```markdown
- [ ] Add an `Attach (pick process)` configuration to the template: `request: "attach"`,
      `pid: "${PickProcess(\"${program}\")}"` or equivalent.
...
- [ ] Verify `waitFor` on magister: issue the attach, then start the game, and catch it in startup
      code (e.g. Vulkan/GLFW initialisation).
```

**Comment:** Update these to match what was built and found:
- the `programName` basename variable plus the anchored `^${programName}$$` filter;
- `pid#json`, with the lldb-dap error it prevents;
- `waitFor` attaches about 40–50 ms after start, so it catches code after `glfwContext.init()`
  (magister `main.cpp:334`), not GLFW init itself.

Also add a step-9 checkbox. The Debugging docs must say that `<S-F5>` (Stop) and `,DX` detach
silently, while `:VimspectorReset` asks "Terminate debuggee?", and answering Y kills an attached
process.

### 4. `CLAUDE.md` Debugging note — no change

```markdown
## Debugging

**Attach fails on hardened-runtime binaries.** If a Vimspector attach reports "Attached to process N" and then dies with "Trying to resume but the async thread is dead", ...
```

**Comment:** It's accurate, scoped to the attach note as asked, and the `codesign` output shapes
were checked on a scratch copy. One long paragraph is denser than the rest of `CLAUDE.md`, but
step 9 rewrites this section, so leave it.

### 5. Side effect: `~/.vimspector.log` overwritten — no change

**Comment:** Every Vimspector run, including the test runs, replaces the user's
`~/.vimspector.log`. Nothing to fix; reported to the user.

## Required before approval

- [ ] Finding 1: `,DX` → `vimspector#Reset()` without the interactive flag; verify on an attached
      process (stays alive) and on a launched one (terminated).
- [ ] Finding 2: plan step 1 note + step 6 note about the removed adapter `attach` block.
- [ ] Finding 3: plan step 6 items updated; new step-9 checkbox for the Stop / Reset / `,DX`
      behaviour.

## Needs the user (manual), batched after this step is approved

- [ ] On magister in a real Neovim, run **Attach (pick process)**. The "Enter Process ID:" list
      should show only `magister`, with its PID pre-filled; Enter attaches.
- [ ] While attached and stopped, then continued, then detached with `,DX`, the triangle keeps
      rendering.
- [ ] `:VimspectorReset` asks "Terminate debuggee?"; answering N leaves the game running.

## Step 6 checklist status

| Item | Status |
| --- | --- |
| `Attach (pick process)` config | ✅ (basename filter, `pid#json`) |
| `Attach (wait for launch)` config | ✅ |
| `vimspector_process_list` built and found | ✅ (support dir, not PATH) |
| Attach by PID on magister | ✅ headless; ⏳ interactive picker (user) |
| `waitFor` on magister | ✅ (`init()` line 334) |
| Detach leaves the game running | ✅ headless; ⚠️ `,DX` (finding 1); ⏳ visual check (user) |
| Hardened-runtime note in `CLAUDE.md` | ✅ |
