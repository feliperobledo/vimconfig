# Step 2 — Review 1

| | |
| --- | --- |
| Plan | `plans/cpp-debugging.md`, step 2 "`std::expected` formatter" |
| Branch | `cpp-debugging` (uncommitted, on top of `b1168ee`) |
| Files reviewed | `lldb/libcxx_expected.py` (new, 160 lines) |
| Date | 2026-11-08 |
| Verdict | **Changes requested.** The formatter works; two small code/test gaps and two plan corrections. |

## Summary

The formatter does what step 2 asks. In the value state it shows a `has value` summary with one
`Value` child; in the error state, `has error` with one `Error` child. Each child keeps its own
formatter: `"bad"` for strings and `size=3 {…}` for vectors. `expected<void, E>` in the value
state shows no child. It works identically with Homebrew clang 22 and Apple clang 21, in plain
`lldb` and over lldb-dap.

The design is sound:
- It finds the fields by searching for their names, and stops searching inside a field once
  found, so a nested `expected` can't be mistaken for the outer one.
- It uses `Clone` to make the child, which keeps the child's own formatter.
- Every entry point catches exceptions, so an unknown layout can't break the variables view.

The subagent also found a real requirement on its own: the summary has to be registered with
`-e`, or the children disappear.

What's requested: two layouts the tests didn't cover, a guard against following pointers while
searching unknown layouts, and making the plan match what was actually built.

## Checks re-run by the reviewer

| Check | Command | Result |
| --- | --- | --- |
| Only the expected file is new | `git status --porcelain --untracked-files=all` | `?? lldb/libcxx_expected.py` ✅ |
| Formatter on the Homebrew clang 22 build | `lldb --batch -o "command script import …/lldb/libcxx_expected.py" -o "b test.cpp:39" -o run -o "frame variable ok err vok verr vec pad paderr" t_brew` | matches the subagent's output ✅ |
| Formatter on the Apple clang 21 build | same, `t_apple` | identical to `t_brew` ✅ |
| Category registered and on | `type category list libcxx-expected` | `Category: libcxx-expected (enabled)` ✅ |

Representative output (both binaries):

```
(std::expected<int, std::string>) err = has error {
  Error = "bad"
}
(std::expected<void, std::string>) vok = has value
(std::expected<Padded, int>) pad = has value {
  Value = (a = 1, b = '\x02')
}
```

## Findings

### 1. Two layouts not tested — should fix (tests)

The subagent's report lists these as not tested:

```
- `expected<T, E>` whose `E` has tail padding, and `expected<void, Padded>`, were not tested.
```

**Comment:** These are exactly the cases where libc++ changes the layout. Your own `Padded` test
showed the `<false, __repr>` / `<true, __union_t>` variant appears only when a payload has tail
padding. The void base (`__expected_void_base<E>`) is a separate code path again. Name-based
search should handle both, but this step exists to check that rather than assume it. Add to
`test.cpp`:

- `std::expected<int, Padded>` in the error state (an `E` with tail padding)
- `std::expected<void, Padded>` in both states
- a plain `std::unexpected<std::string>` local. This proves the regex doesn't also match
  `unexpected<…>`. Reading the regex, it shouldn't, but nothing in the tests proves it.

Run them with both compilers in plain `lldb` and through the DAP harness, and paste the output.

### 2. The search follows pointers on unknown layouts — should fix

`lldb/libcxx_expected.py`, `_find_members`

```python
          for i in range(node.GetNumChildren()):
              child = node.GetChildAtIndex(i)
              if not child.IsValid():
                  continue
              name = child.GetName()
              if name in found:
                  if found[name] is None:
                      found[name] = child
                  # Don't descend into the payload: a nested expected would match too.
                  continue
              if depth + 1 < _MAX_DEPTH:
                  queue.append((child, depth + 1))
```

**Comment:** For a real `expected` this never matters, because the three members are reached
before any pointer. But the fallback exists for layouts the code *doesn't* know, and there the
search goes into a pointer child's target. In the debugger, that means reading whatever memory
the pointer holds, which is garbage for an uninitialised variable at a breakpoint above its
construction. The depth cap stops it from running away, but it can still produce slow or
misleading reads. Skip pointer and reference children: `child.GetType().IsPointerType()` /
`IsReferenceType()`. Add a short comment saying why, and show one fallback run still working
afterwards.

### 3. The search runs twice per variable — no change

`summary()` and `ExpectedSynthProvider.update()` each build their own `_State(...)`.

**Comment:** That's two short searches per `expected` per stop. It's cheap at these depths and
keeps the two entry points independent, which is the simpler design. No change; noted in case
large frames ever feel slow.

### 4. Plan text doesn't match what was built — should fix (doc)

`plans/cpp-debugging.md`, step 2 and the magister section

```markdown
- [ ] Write an LLDB synthetic-children provider + summary for `^std::__1::expected<.+>$`:
```

```markdown
  tests. So the binary uses Apple's libc++, and the "lldb-dap matches the compiler" argument no
  longer holds exactly. The formatter (step 2) must also be checked against an Apple clang build.
```

**Comment:** The broader regex `^std::(__[[:alnum:]]+::)?expected<.+>$` is the right call: LLDB
reports both `std::__1::expected<…>` and the display name `std::expected<…>`. Update step 2's
wording to that regex with a short reason. In the magister section, add one line saying Apple
clang 21 supports `-std=c++23` `<expected>`, and that the tested layouts matched Homebrew's
libc++. Keep "checked against both" as the rule, since untested cases may still differ.

### 5. Vimspector's variables window can't be checked yet — defer to step 8

`plans/cpp-debugging.md`, step 2

```markdown
- [ ] Verify the same rendering through Vimspector's variables window.
```

**Comment:** The DAP harness is a good substitute: it sends the same requests Vimspector sends,
and the values come back correct for both compilers. A real check in Vimspector needs a launch
configuration, which arrives in step 5. Step 8 already has the same check ("Variables window
renders … `expected`"). Change this item to a note saying it's verified in step 8 with the
harness as interim evidence, so step 2 can close without an item it can't meet.

### 6. `-O0` only — no change

**Comment:** The plan's builds are always `-O0` / CMake `Debug`. Copying a value the optimizer
moved into a register is untested, but that's outside scope. No change.

## Required before approval

- [ ] Finding 1: add `expected<int, Padded>` error, `expected<void, Padded>` both states, and a
      `std::unexpected<std::string>` local; re-run both compilers in plain `lldb` and the DAP
      harness.
- [ ] Finding 2: don't descend into pointer/reference children; show a fallback run still works.
- [ ] Finding 4: update step 2's regex text and the magister note in the plan.
- [ ] Finding 5: change step 2's Vimspector-window item into a note pointing to step 8.

## Needs the user (manual)

None for this step. The Vimspector variables-window check moves to step 8.

## Step 2 checklist status

| Item | Status |
| --- | --- |
| Provider + summary, own category | ✅ |
| Summary `has value` / `has error` | ✅ |
| One child keeping its own formatter | ✅ |
| Members found by name | ✅ (finding 2 hardens it) |
| `expected<void, E>` | ✅ string `E`; ⚠️ `Padded` `E` untested (finding 1) |
| `__lldb_init_module` registers both | ✅ |
| Plain `lldb`, Homebrew clang 22 | ✅ |
| Plain `lldb`, Apple clang 21 | ✅ |
| Vimspector variables window | ↪️ moves to step 8 (finding 5) |
