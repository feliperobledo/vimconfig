# Step 4 — Review 1

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 4 "Breakpoint persistence" |
| Branch | `cpp-debugging` (uncommitted, on top of `1a00f49`) |
| Files reviewed | `lua/config/keymaps.lua` (+32 / −2) |
| Date | 2026-11-08 |
| Verdict | **Changes requested.** The design is good; one small error-message regression and a plan update. |

## Summary

F2 now also saves Vimspector's breakpoints, and F3 restores them. Three design choices go beyond
the plan's literal wording, and all three are better:

- **Write only when it's meaningful.** F2 saves the Vimspector file when there are breakpoints or
  the file already exists. Projects that never debug stay clean, and clearing every breakpoint is
  still saved.
- **Explicit path in the cwd, next to `Session.vim`.** Vimspector's default looks upward from the
  current buffer, which could land on a stray session file in a parent directory.
- **Load after `Session.vim`**, using a path worked out *before* sourcing, because `Session.vim`
  runs `cd`.

The plugin research is thorough and cites file:line. All five behaviours were tested through the
real mappings. The two things to fix are both small.

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Only `keymaps.lua` changed | `git status --short` | ` M lua/config/keymaps.lua` ✅ |
| Fresh round trip | in a new dir: set BPs at 4 and 10 (conditional), `Press('<F2>')`, quit; fresh nvim, `Press('<F3>')`, dump | `breakpoints=2`, `main.cpp:4`, `main.cpp:10 {"condition": "i == 2"}`, signs `vimspectorBP@4, vimspectorBPCond@10` ✅ |
| Cleared state stays cleared | `Press('<F3>')` in the subagent's `cpp/` dir after its clear test | `breakpoints=0` ✅ |
| No litter | `Press('<F2>')` in `plain/` (no BPs) | `ls -A` → `Session.vim notes.txt`, no `.vimspector.session` ✅ |
| F3 without `Session.vim` | `Press('<F3>')` in an empty dir | `E5108: Lua: … Vim(source):E484: Can't open file Session.vim` + stack traceback ❌ (finding 1) |
| Cost of F2 | `time nvim --headless … Press('<F2>')` ×3 vs `time nvim --headless +qa` ×3 | 0.21–0.22 s vs 0.08–0.09 s, so about 0.13 s on first F2 ✅ acceptable (finding 3) |

## Findings

### 1. F3 without `Session.vim` now shows a stack trace — should fix

`lua/config/keymaps.lua`, F3 mapping

```lua
map("n", "<F3>", function()
  -- Resolve before sourcing: Session.vim may change the cwd.
  local file = vimspector_session_file()
  vim.cmd("source Session.vim")
```

**Comment:** Before this change, F3 with no `Session.vim` showed one line:
`E484: Can't open file Session.vim`. Now that the mapping is a Lua function, the same mistake
shows `E5108: Lua: vim/_core/editor.lua:0: command line..script nvim_exec2() …` plus a stack
traceback. That's a regression this step introduced, so it belongs in this step even though the
brief said not to widen scope. Wrap `source` in `pcall`. On failure, show the original Vim error
as a single error message (e.g. `vim.notify(err:match("E%d+:.*") or err, vim.log.levels.ERROR)`)
and return before the Vimspector part. Re-run the empty-dir case and paste the message.

### 2. Plan step 4 doesn't match the design — should fix (doc)

`plans/cpp-debugging.md`, step 4

```markdown
- [ ] `F2` also runs `:VimspectorMkSession`.
- [ ] `F3` also runs `:VimspectorLoadSession`, only if `.vimspector.session` exists.
```

**Comment:** The plan is the record of what was built and why. Update these two items to say:
- F2 writes `<cwd>/.vimspector.session` (next to `Session.vim`) only when breakpoints exist or
  the file already exists;
- F3 loads it after `Session.vim`, using the path worked out before sourcing;
- both call `vimspector#WriteSessionFile` / `vimspector#ReadSessionFile` with an explicit path.

Add a one-line known limitation: watches alone, or exception-breakpoint settings alone, don't
create the file. Step 9's `CLAUDE.md` section can repeat this later.

### 3. First F2 starts Vimspector — no change

`lua/config/keymaps.lua`, F2 mapping

```lua
  local breakpoints = vim.fn["vimspector#GetBreakpointsAsQuickFix"]()
```

**Comment:** In a project that never debugs, this call starts Vimspector's Python side the first
time F2 is pressed. I measured it at about 0.13 s, once per Neovim session, on a key the user
presses. Avoiding it would mean guessing breakpoint state from signs, which misses breakpoints in
files that aren't open. Not worth it. No change.

### 4. Vimspector prints "Wrote …" / "Loaded session file …" — no change

**Comment:** Vimspector prints these itself on each F2/F3 that touches the file. That's useful
confirmation that breakpoints were saved, and it says nothing in projects without a session
file. No change.

## Required before approval

- [ ] Finding 1: `pcall` around `source Session.vim` with a single-line error; re-test.
- [ ] Finding 2: update plan step 4's two items and add the known-limitation line.

## Needs the user (manual)

None for this step. The real-editor check (set breakpoints in magister, F2, quit, reopen, F3)
happens during step 8's end-to-end run.

## Step 4 checklist status

| Item | Status |
| --- | --- |
| F2 also saves Vimspector's session | ✅ (conditional, by design) |
| F3 also loads it, only if it exists | ✅ ⚠️ finding 1 (error message on missing `Session.vim`) |
| Round-trip verification | ✅ headless, through the real mappings |
