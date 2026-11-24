# Step 9 — Review 1

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 9 "Documentation" |
| Branch | `cpp-debugging` (uncommitted, on top of `47f4c4c`) |
| Files reviewed | `CLAUDE.md` (+85), `research/cpp-debugging.md` (+89), `research/vim-pack-migration.md` (1 line) |
| Date | 2026-11-24 |
| Verdict | **Changes requested.** The docs are accurate and complete; two small corrections the subagent itself flagged. |

## Summary

The new `## Debugging` section covers every step-9 item and describes the code as it is, not the
plan. Every key was checked with headless `maparg`, every command with `nvim_get_commands`, and
every path with `ls`. The "Rules for any `.vimspector.json`" subsection is the most useful part
for future work: each rule that cost a review round in steps 5–7 now has its reason in one line.
The research doc gets a dated Outcome section that wins over the original body without rewriting
it, and the `PATH` claim is corrected where it's stated. The subagent's list of contradictions
was honest, and two of them need small fixes.

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Only doc files changed by the subagent | `git status --short` | `CLAUDE.md`, both research files; user's `keymaps.lua` / `settings.local.json` untouched ✅ |
| Clean startup | `nvim --headless "+qa"` | exit 0 ✅ |
| vim-pack build-hook list | `git diff research/vim-pack-migration.md` | `nvim_gdb.lua` → `vimspector.lua` `go build` ✅ |
| "via obsession" claim | `grep -n obsession CLAUDE.md lua/plugins/obsession.lua`; F2 in `keymaps.lua` | F2 runs `mksession!` directly ❌ (finding 1) |
| Template attach comment | `grep -n "answer N or D" templates/vimspector-cpp.json` | line 43, sits in the template next to `Launch` ⚠️ (finding 2) |

## Findings

### 1. "Session.vim via obsession" is wrong — should fix

`CLAUDE.md:44`

```markdown
**Session management**: F2 saves session, F3 loads (`Session.vim` via obsession), plus Vimspector breakpoints in `.vimspector.session` (see Debugging).
```

**Comment:** F2 runs `mksession! Session.vim` (`lua/config/keymaps.lua`), and F3 sources it.
vim-obsession is installed but isn't what these keys use. The error predates this branch, but
this line now points readers at the Debugging section's F2/F3 rules, so it should be right.
Reword to "F2 writes `Session.vim` with `:mksession!`, F3 sources it". Leave the obsession plugin
alone (whether to keep it is the user's call).

### 2. Template comment contradicts the Reset-N trade-off — should fix

`templates/vimspector-cpp.json:43`

```jsonc
      // ... If :VimspectorReset asks "Terminate debuggee?", answer N or D.
```

**Comment:** That's true for the attach configs it introduces, but someone reading the template
could apply it to `Launch`, where N still ends the program (`8d9ef17`). It's a comment change in
a code file, but it's documentation, so it belongs in step 9. Reword so it clearly applies to
attach configs, and add that a launched program is ended either way. Re-run `:VimspectorInitCpp`
in a scratch dir and check the copy still matches the template and parses with Vimspector's
loader.

### 3. Expression results have no review file — no change

**Comment:** They come from the reviewer's own `lldb` tests during planning (before the review
process started), recorded in the plan's "Findings carried into the plan". Citing the plan is
correct.

### 4. Remembered preset, `:CMakeDebug` configuring — no change

**Comment:** Both are documented exactly as the code behaves (contradictions 1 and 2 in the
report). Good.

## Required before approval

- [ ] Finding 1: fix the Session management line.
- [ ] Finding 2: reword the template's attach comment; re-check the template parses and copies.

## Notes for the user

- Magister's `.gitignore` change is still uncommitted, so step 7's last box stays unticked until
  the user confirms.
