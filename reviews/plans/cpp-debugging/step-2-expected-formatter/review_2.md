# Step 2 — Review 2

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 2 "`std::expected` formatter" |
| Branch | `cpp-debugging` (uncommitted, on top of `b1168ee`) |
| Files reviewed | `lldb/libcxx_expected.py` (round-2 change: +5), `plans/cpp-debugging.md` (step 2 + magister note) |
| Previous review | `review_1.md` |
| Date | 2026-11-08 |
| Verdict | **Approved.** All required items from review 1 are resolved; ready to commit. |

## Summary

Every item from review 1 is addressed, and the evidence is solid. The new layouts render
correctly on both compilers. The `std::unexpected` local is shown not to match, using LLDB's own
`type summary info` rather than by reading the output. And the pointer guard is shown to matter:
the subagent built a `Decoy` struct that fools a copy of the module without the guard
(`has value { Value = 1 }`), while the real module falls back correctly.

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Changed files | `git status --porcelain --untracked-files=all` | ` M plans/…`, `?? lldb/libcxx_expected.py`, `?? reviews/…/review_1.md` ✅ |
| New layouts, Homebrew clang 22 | `lldb --batch -o "command script import …" -o "b test.cpp:54" -o run -o "frame variable ipaderr vpad vpaderr loose ok err vec" t_brew` | all correct ✅ |
| New layouts, Apple clang 21 | same, `t_apple` | identical to `t_brew` ✅ |
| `unexpected` not matched | `type summary info loose` | `no summary applies to (std::unexpected<std::string>) loose` ✅ (both) |
| Pointer guard | provider + summary added to `Decoy`, then `frame variable decoy` | `<unknown expected layout> { p = 0x… }` ✅ (both) |
| No step-2 boxes ticked yet | `grep -c '\[x\]'` within step 2 | 0 ✅ |

Output from the reviewer's run (identical on both binaries):

```
(std::expected<int, Padded>) ipaderr = has error {
  Error = (a = 1, b = '\x02')
}
(std::expected<void, Padded>) vpad = has value
(std::expected<void, Padded>) vpaderr = has error {
  Error = (a = 1, b = '\x02')
}
(std::unexpected<std::string>) loose = (__unex_ = "loose")
...
(Decoy) decoy = <unknown expected layout> {
  p = 0x000000016fdfda48
}
```

## Review 1 items

### Finding 1 — untested layouts: resolved

**Comment:** `expected<int, Padded>` (error state) and `expected<void, Padded>` (both states) use
the tail-padding variant of the layout on both compilers, and the name-based search handles them
without changes. That's what the search-by-name approach was for. `loose` keeps its plain
struct rendering, so the regex doesn't catch `unexpected`.

### Finding 2 — pointer/reference guard: resolved

`lldb/libcxx_expected.py:44-49`

```python
              # expected stores its members inline. Following pointers on an unknown
              # layout would read arbitrary (possibly uninitialised) memory.
              child_type = child.GetType()
              if child_type.IsPointerType() or child_type.IsReferenceType():
                  continue
```

**Comment:** Correct placement. The check comes after the name match, so a pointer-typed payload
(e.g. `expected<int*, E>`) is still picked up as `__val_`; only the *search* stops at pointers.
The comment says why. The `Decoy` experiment proves the guard does real work. Nothing regressed
in the full re-run.

### Finding 4 — plan text: resolved

**Comment:** Step 2 now states the regex that was actually built and why. The magister section
records that Apple clang 21 supports `<expected>` and that the tested layouts matched, while
keeping "check both compilers" as the rule.

### Finding 5 — Vimspector window check deferred: resolved

`plans/cpp-debugging.md`, step 2

```markdown
Note: rendering in Vimspector's variables window is verified in step 8 (it needs step 5's launch
configuration). Interim evidence is a DAP harness that sends Vimspector's request sequence to
lldb-dap; it got the same values from both compilers' builds.
```

**Comment:** Good. Step 8's existing checkbox already includes `expected`, so leaving that one as
it is was right.

## New findings

None.

## Next actions (subagent)

- [ ] Tick every step-2 checkbox in `plans/cpp-debugging.md`.
- [ ] Commit step 2 on `cpp-debugging`: `lldb/libcxx_expected.py`, `plans/cpp-debugging.md`,
      `reviews/plans/cpp-debugging/step-2-expected-formatter/`.

## Step 2 checklist status

| Item | Status |
| --- | --- |
| Provider + summary, own category | ✅ |
| Summary `has value` / `has error` | ✅ |
| One child keeping its own formatter | ✅ |
| Members found by name (pointer-safe) | ✅ |
| `expected<void, E>` | ✅ (`std::string` and `Padded` `E`) |
| `__lldb_init_module` registers both | ✅ |
| Plain `lldb`, Homebrew clang 22 + Apple clang 21 | ✅ |
| Vimspector variables window | ↪️ verified in step 8 |
