# C/C++ Debugging with Breakpoints — Research

## Research Metadata

- Research date: 2026-09-20
- Machine used for verification: macOS `26.6.2` (Darwin 25.6.0, build `25G83`), Apple Silicon (`arm64`), SIP enabled
- Neovim: `0.12.0`
- Config state reviewed from this repo on: 2026-09-20
- Updated 2026-09-20 after the decision to use Vimspector as the debug client (see "Decision: Vimspector")
- Updated 2026-09-20 with attach-mode verification on macOS (see "Attach Mode on macOS")
- Claims marked **[verified]** were tested on this machine during the research; everything else is reasoning about the config or about upstream behavior.
- Updated 2026-11-24 with the implementation outcome (see "Outcome (2026-11-24)") and a correction: `lldb-dap` *is* on `PATH` in shells (see section 1 under "Adapter Options").

Research only for the debugging work — no debugging code has been written. The one exception is the
Mason `ensure_installed` bug documented below, which was fixed in the same session at the user's
request.

## Outcome (2026-11-24)

The plan built from this research: [`plans/cpp-debugging.md`](/Users/feliperobledo/src/vimconfig/plans/cpp-debugging.md),
with per-step reviews under [`reviews/plans/cpp-debugging/`](/Users/feliperobledo/src/vimconfig/reviews/plans/cpp-debugging/).
How to use and maintain the result is in `CLAUDE.md`, "Debugging". The body below is the original
research, left as written apart from the `PATH` correction; where it disagrees with this section,
this section wins.

### Final decisions

- **Adapter: a custom Vimspector adapter for Homebrew's `lldb-dap`** (22.1.8), declared in
  `g:vimspector_adapters` in `lua/plugins/vimspector.lua`. Not the `CodeLLDB` gadget the research
  recommended: no `install_gadget.py`, no Mason package. The lazy `build` step only does the
  `go build` of `vimspector_process_list`.
- **`nvim-gdb` removed** (`lua/plugins/nvim_gdb.lua` deleted), which also freed `,d` from its
  `timeoutlen` wait. Debug leader keys live under `,D`.
- **`nvim-dap` left to `nvim-java`**, no keymaps or UI.
- **Keys:** explicit `<Plug>` mappings on a Visual-Studio-like F-row (`F5`, `S-F5`, `C-S-F5`, `F6`,
  `F8`–`F11`, `S-F11`), plus `,F9`, `,F10`, `,Di`, `,DX`. `g:vimspector_enable_mappings` unset.
- **Attach and CMake integration were required**, not optional. `:VimspectorInitCpp` copies a
  generic template or, in a CMake project, generates per-target configs through the CMake File API
  (presets first); `:CMakeDebug [target]` builds and launches. Acceptance testing ran on the
  magister project (Apple clang 21, not the Homebrew clang 22 used here).
- **Breakpoints persist** through the existing `F2`/`F3` session keys (`.vimspector.session`).

### Test results

- **Formatters.** LLDB 22's built-in libc++ formatters render `vector`, `string`, `map`,
  `optional`, `variant`, `span` and `unique_ptr`. `std::expected` showed raw internals, so
  `lldb/libcxx_expected.py` adds a summary (`has value` / `has error`) and one `Value` / `Error`
  child, finding members by name because libc++'s layout varies by type. Verified in plain `lldb`
  (value, error, `expected<void, E>`, trivially destructible `E`, `vector` payload, tail-padded
  types) with both Homebrew clang 22 and Apple clang 21 builds, which had identical layouts, and
  later in Vimspector's variables window.
- **Expressions.** Evaluation works, but only for functions present in the binary: `v.size()`
  works when the program calls it; `v[1]`, `o.value()` and `*up` fail. Hover (`,Di`) only
  evaluates variable/member paths, not arithmetic; watches do arithmetic.
- **`target.import-std-module`.** Setting it `true` fixed some of those expressions but **crashed
  LLDB** on `m.at("b")`. It stays off.

### Findings that change what the research said

- **`lldb-dap` is on `PATH`** in shells (`~/.zshrc` adds Homebrew's `llvm/bin`), so
  `exepath("lldb-dap")` normally hits. The absolute fallback is kept for launches that don't
  inherit the shell's `PATH`.
- **No `pidSelect` in the adapter.** An adapter-level `attach = { pidSelect = "ask" }` was tried
  and removed: Vimspector applies it to every attach config without a `pid`, which hijacked
  `waitFor` configs with an unfiltered PID prompt.
- **`PickProcess` filters by process name with a regex**, not by path. The attach-by-PID entry
  sketched under "Vimspector-specific notes for attach" doesn't work as written: the working form
  is `"pid#json": "${PickProcess(\"^<basename>$$\")}"`. The anchored basename pre-fills a single
  match; `#json` is required because substitution yields a string and lldb-dap rejects a string
  `pid`.
- **`waitFor` attaches about 40–50 ms after the process starts** (measured on magister, where
  it stops after `glfwContext.init()`). The "caught it at the very first iteration" result above
  was a slow test loop; `waitFor` can't catch the first lines of `main`.
- **Exception-filter prompts.** Without a `breakpoints.exception` block answering lldb-dap's four
  filters (`cpp_throw`, `cpp_catch`, `objc_throw`, `objc_catch`), Vimspector asks four Y/N
  questions on every start (headless, the launch stalled). Vimspector reads the block per
  configuration only, so every configuration carries it.
- **`initCommands` vs. `sourceMap`.** Vimspector merges the adapter's `configuration` and the
  project's shallowly, so a project `initCommands` replaces the adapter's list (and the formatter
  import). The `target.source-map` via `initCommands` advice under "Things That Will Bite" is
  replaced by lldb-dap's `sourceMap`.
- **`runInTerminal`.** Without it, the program's output goes to Vimspector's Console, which shows
  colour escape codes raw. Launch configs set `"runInTerminal": true`: lldb-dap starts the program
  through `lldb-dap --launch-target` in a Vimspector terminal and attaches to it.
- **`terminateCommands`.** Because of that attach, Stop / Reset / Restart (a bare `disconnect`)
  only detached, leaving launched programs running (and two after Restart). lldb-dap 22.1.8 has no
  option to change that, and `terminateCommands` run *after* the detach, so `process kill` fails.
  Launch configs carry a `terminateCommands` script that SIGKILLs the pid lldb remembers when the
  state is `detached` (not `exited`). Attach configs don't, so they still only detach. Trade-off:
  `:VimspectorReset` → "Terminate debuggee?" → N also ends a launched program.
- **`ClearBreakpoints` quirk.** `vimspector#ClearBreakpoints()` ("Clr All") during a session
  empties Vimspector's list but never re-sends the emptied files, so lldb-dap keeps stopping
  there. Clearing one by one (`F9`) or restarting works.
- **Signs.** Breakpoint sign priority 12 beats gitgutter's 10, and `signcolumn=auto:2` shows both
  on one line instead of hiding the gitgutter marker.

## Summary

Breakpoint debugging in Neovim means running a **Debug Adapter Protocol (DAP)** client inside Neovim
and pointing it at an external debug adapter that drives a real debugger. The mature client is
`mfussenegger/nvim-dap`.

Three relevant findings:

1. **`nvim-dap` is already installed in this config** — but only as a transitive dependency of
   `nvim-java`, with no spec of ours, no adapter, no configuration, and no keymaps. Nothing in
   `lua/` references `dap` outside of `nvim-java`. So today there is effectively no C++ debugging.
2. **Two older debug plugins are installed and unconfigured**: `sakhnik/nvim-gdb`
   (`lua/plugins/nvim_gdb.lua`) and `puremourning/vimspector` (`lua/plugins/vimspector.lua`). Both
   predate the native-LSP migration, both overlap with `nvim-dap`, and neither has any config in
   this repo. They are a decision to make, not a foundation to build on.
3. **`lldb-dap` is the right adapter for this machine and it already works** — `lldb-dap 22.1.8`
   ships with the Homebrew LLVM at `/opt/homebrew/opt/llvm/bin/lldb-dap`. It was driven end-to-end
   over DAP during this research: source breakpoint bound, process stopped on it, stack trace and
   locals returned. **[verified]**

So the honest answer to "what would it take": roughly **one plugin spec plus ~60 lines of
adapter/config/keymap wiring**, plus a decision about what to do with the other debug plugins. The
hard part is not the plugin — it is choosing how launch configurations get supplied per project.

**The client has since been decided: Vimspector**, for its UI. That changes the adapter plumbing and
the per-project config format but none of the debugger-level findings; see
"Decision: Vimspector" for the delta.

## Current State of the Repo

| Piece | Status |
| --- | --- |
| `mfussenegger/nvim-dap` | Installed (in `lazy-lock.json`, on disk, version `9e848e0`, 2026-06-19). Pulled in by `nvim-java`, not by a spec of ours. |
| `sakhnik/nvim-gdb` | Installed via `lua/plugins/nvim_gdb.lua`. No config, no keymaps. |
| `puremourning/vimspector` | Installed via `lua/plugins/vimspector.lua`. No config, no `.vimspector.json`, no `HUMAN` mappings enabled. |
| `nvim-dap-ui`, `nvim-dap-virtual-text` | Not installed. |
| `clangd` | Installed via Mason. Gives the LSP side only; unrelated to debugging. |
| C++ toolchain | `clang++` 22.x and `cmake` from Homebrew, `lldb` 22.1.8, plus GNU `gdb` 17.1. |

### Finding: the Mason `ensure_installed` block was a no-op — FIXED 2026-09-20

`lua/plugins/mason.lua` passes `ensure_installed = { ..., "cpptools", ... }` to `mason.nvim`'s
`opts`. **`mason.nvim` does not support `ensure_installed`** — the string does not appear anywhere
in the installed `mason.nvim` source (`2a6940a`, 2026-06-11), and it is absent from
`lua/mason/settings.lua` defaults. Unknown keys are merged into the settings table and silently
ignored. **[verified]**

Consistent with that, the Mason package directory contains only LSP servers; `cpptools`, `black`,
`markdownlint`, `htmlbeautifier`, `ast-grep` and `json-lsp` are **not installed** even though they
are listed there. The `mason-lspconfig` `ensure_installed` list below it is real and does work.

This mattered for debugging because `cpptools` — the package someone was presumably reaching for as
a C++ debug adapter — was never actually installed.

**Resolution applied 2026-09-20.** The dead block was removed from `lua/plugins/mason.lua`. Its
entries were split by what can actually install them:

- **Language servers** moved into `mason-lspconfig`'s `ensure_installed`, translated from Mason
  package names to lspconfig server names, which is what that option expects (`css-lsp` → `cssls`,
  `html-lsp` → `html`, `json-lsp` → `jsonls`, `typescript-language-server` → `ts_ls`, `eslint-lsp` →
  `eslint`, `neocmakelsp` → `neocmake`, `slang` → `slangd`, `ms-terraform-lsp` → `ms_terraform_lsp`,
  `ast-grep` → `ast_grep`). The translations were read out of `mason-lspconfig.mappings`, not
  guessed. **[verified]**
- **Formatters and linters** (`black`, `htmlbeautifier`, `htmlhint`, `markdownlint`) moved to a new
  `lua/plugins/mason-tool-installer.lua`, since `mason-lspconfig` only knows about language servers.
- **`cpptools` was dropped.** Vimspector downloads its own debug adapters and never consults Mason,
  so a Mason-managed `cpptools` would be an unused ~80 MB. One line to add back if that changes.

Two more dead options were found while fixing this: `automatic_installation` is not a setting in
`mason-lspconfig` v2 either (it appears nowhere in `40276c4`, 2026-08-27), so it was removed too; and
`ensure_installed` is deliberately **skipped in headless mode** (`init.lua`: `if not
platform.is_headless and #settings.current.ensure_installed > 0`), which is why `nvim --headless`
never installs anything. **[verified]**

After the fix, all 19 expected packages are installed and startup is clean. **[verified]**

### Related, not fixed: none-ls formatters that were never in any list

`lua/plugins/none-ls.lua` registers `prettier`, `stylua`, `rubocop` and `sql_formatter`, none of
which appear in the old `ensure_installed` list and none of which are on `PATH`. none-ls silently
skips sources whose binary it cannot find, so those four formatters do nothing today. `clang_format`
and `black` and `markdownlint` do resolve. Adding the missing four to
`lua/plugins/mason-tool-installer.lua` would fix it — left alone because it is outside what was
asked. **[verified]**

## How DAP Debugging Works

```
Neovim ── nvim-dap (client) ──stdio/TCP, DAP JSON──▶ debug adapter ──▶ debugger ──▶ your process
```

- **`nvim-dap`** owns breakpoints, the stepping commands, the REPL, and the sign column. It is
  language-agnostic and ships no adapters.
- **The adapter** is an external binary. For C++ it wraps LLDB or GDB.
- **A "configuration"** is the per-project launch description: which binary, which args, which cwd,
  stop-on-entry or not. This is the part that has to come from somewhere per project.

Breakpoints themselves are cheap: `require('dap').toggle_breakpoint()` places one, signs
(`DapBreakpoint`, `DapBreakpointCondition`, `DapLogPoint`, `DapBreakpointRejected`, `DapStopped`) are
definable, and conditional breakpoints / hit-count breakpoints / logpoints all exist in the client.
`nvim-dap` requires Neovim `0.11.7` or `0.12.x` (0.12.x recommended) — this config is on `0.12.0`.

## Adapter Options for C++ on Apple Silicon

### 1. `lldb-dap` — recommended

The DAP server that ships as part of LLVM itself (formerly `lldb-vscode`). Already present at
`/opt/homebrew/opt/llvm/bin/lldb-dap`, version 22.1.8, because Homebrew `llvm` is installed.

Verified capabilities reported by this binary's `initialize` response **[verified]**:

```
supportsConditionalBreakpoints, supportsHitConditionalBreakpoints, supportsLogPoints,
supportsFunctionBreakpoints, supportsInstructionBreakpoints, supportsDataBreakpoints,
supportsDataBreakpointBytes, supportsEvaluateForHovers, supportsSetVariable,
supportsDisassembleRequest, supportsReadMemoryRequest, supportsWriteMemoryRequest,
supportsSteppingGranularity, supportsCompletionsRequest, supportsExceptionInfoRequest,
supportsExceptionFilterOptions, supportsModulesRequest, supportsDelayedStackTraceLoading,
supportsCancelRequest, supportsClipboardContext, supportTerminateDebuggee
```

Exception breakpoint filters offered: `cpp_throw`, `cpp_catch`, `objc_throw`, `objc_catch`.

Pros: no Mason package to maintain, no VSIX unpacking, versioned in lockstep with the `clang++` that
built the binary, native `arm64`, maintained by the LLVM project. Cons: it is a Homebrew dependency
outside Mason's management, so the path must be resolved rather than assumed
(`vim.fn.exepath("lldb-dap")` is empty unless Homebrew's `llvm/bin` is on `PATH`. Homebrew keeps
`llvm` keg-only, but *corrected 2026-11-24*: `~/.zshrc` puts `llvm/bin` on `PATH`, so `exepath`
hits when Neovim starts from a shell. The absolute path is still needed as a fallback for launches
that don't inherit it).

`nvim-dap` talks to it as a plain `executable` adapter over stdio.

### 2. `codelldb` — the fallback

Vadim Chugunov's LLDB wrapper from the VSCode extension. Available in the Mason registry with a
`darwin_arm64` asset (`codelldb-darwin-arm64.vsix`, bin `exec:extension/adapter/codelldb`), not
currently installed. **[verified registry entry]**

It runs as a TCP `server` adapter, so the `nvim-dap` spec needs the `port = "${port}"` /
`--port ${port}` form. It adds nice-to-haves over `lldb-dap` — richer Rust/C++ summary formatters,
`sourceLanguages`, built-in `expressions` modes — at the cost of an extra ~50 MB download managed by
Mason. Worth reaching for only if `lldb-dap`'s value rendering proves too bare.

### 3. `cpptools` (Microsoft, `OpenDebugAD7`) — not recommended here

In the Mason registry with a `darwin_arm64` asset, currently **not installed** (see the
`ensure_installed` finding). On macOS it drives LLDB through an MI bridge rather than natively, is
the slowest of the three to start, and is the least-used path on Apple Silicon. It is the right
choice mainly on Windows/MSVC. Recommend dropping `"cpptools"` from the Mason list rather than
fixing its installation.

### 4. GNU `gdb` — do not use on this machine

`gdb 17.1` is installed via Homebrew, but GDB has no working Apple Silicon (`arm64` Mach-O) target,
and even on Intel macOS it needs manual codesigning with `gdb-cert`. `sakhnik/nvim-gdb` is built
around driving `gdb`/`lldb` as a terminal REPL with a thin Neovim layer — it is a different model
from DAP (no adapter, no DAP UI, its own `:GdbStart` commands and `\b` mappings). Keeping it is
defensible only as a deliberate "raw debugger in a terminal split" workflow; it is not a path to
IDE-style breakpoints.

### 5. `vimspector` — the chosen client

Vimspector is a complete, batteries-included DAP client: it downloads its own adapters ("gadgets"),
ships its own tabbed UI, and is configured through `.vimspector.json` per project. It is a
*competitor* to `nvim-dap`, not a complement — running both with keymaps and UI would mean two
breakpoint stores and two sign sets.

It is currently installed with **zero configuration**: no `.vimspector.json`, no gadgets installed
(`install_gadget.py` was never run, and the lazy spec has no `build` step), and
`g:vimspector_enable_mappings` is unset. It does nothing today.

Its UI is genuinely the strongest part of it, and that is the basis of the decision below.

## Verification Performed

A minimal C++ program was compiled with `clang++ -g -O0 -std=c++20` and debugged two ways.

**Plain LLDB, as a sanity check that debugging works at all on this machine** — breakpoint hit,
source shown, argument values correct:

```
(lldb) b add
Breakpoint 1: 2 locations.
(lldb) run
Process 93662 stopped
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
    frame #0: 0x00000001000004a4 hello`add(a=2, b=3) at hello.cpp:2:33
```

**`lldb-dap` driven directly over the wire** (a small Python harness sending `initialize`, `launch`,
`setBreakpoints`, `configurationDone` and reading events — exactly what `nvim-dap` does):

```
RESP initialize    True   lldb version 22.1.8
EVENT initialized
RESP setBreakpoints True  breakpoints: [{line: 2, verified, id: 1, ...}]
EVENT process      launch, isLocalProcess: true
RESP launch        True
EVENT stopped      reason: breakpoint, hitBreakpointIds: [1]
FRAME add(int, int) hello.cpp 2
FRAME main          hello.cpp 3
```

This settles the two questions that usually sink macOS debugging setups:

- **Codesigning/entitlements**: `lldb-dap` from Homebrew carries *no* debugging entitlement, but it
  does not need one for launching its own child processes — LLDB finds Apple's properly signed
  `debugserver` under `/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Resources/`.
  Launch-and-debug works out of the box. **[verified]**
- **Attaching to an already-running process now tested — it works, with one clear failure mode.**
  See "Attach Mode on macOS" below. Short version: attaching to your own, locally built binary
  started outside the debugger works with no prompt; hardened-runtime binaries without
  `get-task-allow` are refused; other users' processes are refused.

One cosmetic gotcha observed: a function-name breakpoint (`b add`) matched a symbol in
`libobjc.A.dylib` as well, so the first stop was in system code. Source-line breakpoints (what
`nvim-dap` sends) do not have this problem.

## Attach Mode on macOS — tested 2026-09-20

Tested on macOS `26.6.2` (`25G83`), Apple Silicon, SIP **enabled**, with `lldb-dap 22.1.8` driven
over the wire by the same kind of Python DAP harness used above. The target was a `clang++ -g -O0
-std=c++20` binary that loops calling `tick(int)`, started from a plain shell — *not* by the
debugger — and attached to by PID after the fact.

### Result matrix **[all rows verified on this machine]**

| Scenario | Result |
| --- | --- |
| Attach by PID, own process, ad-hoc linker-signed (a normal `clang++`/CMake build) | **Works.** No prompt. |
| Attach by `program` + `waitFor: true` (attach the next launch of that binary) | **Works.** |
| Attach to hardened-runtime binary **without** `get-task-allow` | **Refused.** |
| Attach to hardened-runtime binary **with** `com.apple.security.get-task-allow` | **Works.** |
| Attach to a process owned by another user (`pid 1`, root) | **Refused.** |
| Detach with `terminateDebuggee: false` | **Works** — target resumes and keeps running. |

### The normal case works, cleanly

Attaching by PID to an ordinary local build produced a full working session: the `attach` request
succeeded in **0.10 s**, the source breakpoint bound (`verified: true`) against the
already-running process, execution stopped on it, and the stack and locals were correct:

```
ATTACH_LATENCY_S 0.10
EVENT output    "Attached to process 18290."
EVENT process   startMethod: attach, isLocalProcess: true
EVENT stopped   reason: breakpoint, hitBreakpointIds: [1]
FRAME tick(int) spin.cpp 6
FRAME main      spin.cpp 13
SCOPE Locals    [('n', '29'), ('x', '1000928')]
RESP evaluate   (int) $0 = 29
```

`continue`, `disconnect` with `terminateDebuggee: false`, and the target carrying on afterwards all
behaved — the process was still printing ticks after the debugger let go.

**No authorization prompt appeared**, even though `DevToolsSecurity -status` reports *"Developer
mode is currently disabled"*. The reason is that this account is already a member of the
`_developer` group (`dseditgroup -o checkmember -m $(whoami) _developer` → yes), which is what
actually gates `task_for_pid` for same-user debugging. On an account that is *not* in `_developer`,
expect the one-time "Developer Tools Access needs to take control…" dialog instead. **[verified]**

`lldb-dap` uses Apple's signed `debugserver` for this, same as in launch mode — observed running as
`/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Resources/debugserver
--native-regs --setsid --fd=14` during the attach. The Homebrew `lldb-dap` still needs no
entitlement of its own.

### `waitFor` works and is the more useful form

`{"program": "<path>", "waitFor": true}` blocks until the next process with that image name starts,
then attaches. Tested by starting the target 4 s after issuing the request; it caught it at the
very first iteration (`n = 1`), which is early enough to be useful for debugging startup paths that
`launch` cannot reproduce. **[verified]**

### The failure mode: hardened runtime

This is the one that will actually bite, and it fails *confusingly* through DAP. Signing the same
binary with `codesign -f -s - -o runtime` and attaching gave:

```
EVENT output         "Attached to process 18566."        <- misleading
EVENT process        name: "", pointerSize: 0            <- nothing was really attached
RESP setBreakpoints  verified: false
RESP configurationDone False  "Trying to resume but the async thread is dead."
RESP attach          False
```

`lldb-dap` reports "Attached to process N" and only fails several messages later, with an error
that says nothing about permissions. Running the same attach under plain `lldb` gives the real
reason:

```
error: attach failed: attach failed (Not allowed to attach to process. ...
       The subsystem that denied the attach permission will likely have logged
       an informative message about why it was denied.)
```

So: **if a Vimspector attach dies with "Trying to resume but the async thread is dead", check the
target's signature, not the debugger config.** Re-signing with `com.apple.security.get-task-allow`
set to `true` (`codesign -f -s - -o runtime --entitlements gta.plist`) makes the identical attach
succeed immediately. **[verified both directions]**

Practical impact is low for the C++ workflow this research is about: plain `clang++` and CMake
`Debug` builds are ad-hoc *linker*-signed without the hardened runtime, so they attach fine. It
matters when attaching to an app bundle, anything signed for distribution/notarization, or a
third-party binary.

### Other users' processes

Refused outright, with a clear message — no prompt, no SIP subtlety:

```
error: attach failed: tried to attach to process as user 'feliperobledo'
       and process is running as user 'root'
```

Attaching to a root process would mean running the whole adapter under `sudo`, which means running
`lldb-dap` (and therefore part of Neovim's debug session) as root. Not recommended, and not needed
for this workflow.

### Vimspector-specific notes for attach

Two things found in the installed plugin that matter if attach is ever wired up **[verified in
source]**:

- **The `CodeLLDB` gadget definition has no `attach` block** (`python3/vimspector/gadgets.py`), so
  Vimspector's built-in PID picker (`"pidSelect": "ask"`) is *not* available for it — unlike
  `vscode-cpptools`, which declares `{"pidProperty": "processId", "pidSelect": "ask"}`. Under
  CodeLLDB the PID has to be supplied by the configuration itself.
- **`${PickProcess()}` is the way to do that**, and it needs a helper that is not built. Vimspector
  resolves `${PickProcess()}` / `${PickProcess(\"name\")}` via `_SelectProcess`
  (`debug_session.py:2353`), which looks for a `vimspector_process_list` binary on `PATH` or in
  `support/vimspector_process_list/`. That directory ships **Go source only**. `go` is installed
  here (`/usr/local/go/bin/go`); building the helper out-of-tree and running it against the test
  program produced the expected PID/PPID/CWD table. So this is a one-line `go build` away, not a
  blocker. **[verified]**

A working `.vimspector.json` attach entry under CodeLLDB would therefore look roughly like:

```json
{
  "configurations": {
    "attach": {
      "adapter": "CodeLLDB",
      "configuration": {
        "request": "attach",
        "program": "${workspaceRoot}/build/myapp",
        "pid": "${PickProcess(\"myapp\")}"
      }
    }
  }
}
```

### Protocol gotcha worth recording

`lldb-dap` does **not** answer the `attach` request until after `configurationDone`. A client that
blocks waiting for the `attach` response before sending `setBreakpoints` deadlocks. Real clients
(`nvim-dap`, Vimspector) get this right; it only cost time in the hand-rolled test harness. The
correct order is `initialize` → send `attach` → wait for the `initialized` **event** →
`setBreakpoints` → `configurationDone` → *then* collect the `attach` response. **[verified]**

## Decision: Vimspector — What Changes

Preferring Vimspector's UI is a reasonable call and **does not invalidate the research above**. The
debugger-level findings — compiler flags, `dSYM`, path mapping, breakpoint persistence, macOS
attach — are properties of LLDB and the platform, not of the client. What changes is the plumbing.

### What changes

| | `nvim-dap` path | Vimspector path |
| --- | --- | --- |
| Adapter source | Mason, or a Homebrew binary | Vimspector's own `install_gadget.py` — **Mason is not involved at all** |
| Adapter for C++ | `lldb-dap` (already on disk, verified) | `CodeLLDB` gadget (recommended) or `vscode-cpptools` gadget |
| Per-project config | Lua table, or `.vscode/launch.json` | `.vimspector.json` (required — there is no "just prompt me" default) |
| UI | add `nvim-dap-ui` + `nvim-nio` | built in |
| Config language | Lua | VimL/JSON |
| Extra runtime dep | none | Neovim's `python3` provider |
| Telescope / virtual-text integrations | available | not applicable |

### What Vimspector needs that it does not have today

1. **A `build` step in the lazy spec.** `lua/plugins/vimspector.lua` has none, so no gadget was ever
   downloaded and the plugin is inert. It needs something like
   `build = "./install_gadget.py --enable-c"`, or a `--force-enable-` flag to select CodeLLDB.
2. **A gadget choice.** Both C++ gadgets have real Apple Silicon assets — read out of the installed
   `python3/vimspector/gadgets.py` **[verified]**:
   - `CodeLLDB` v1.12.1 → `codelldb-darwin-arm64.vsix` — **recommended**, native LLDB, same engine
     as the `lldb-dap` that was verified working here
   - `vscode-cpptools` 1.29.3 → `cpptools-macOS-arm64.vsix` — the MI-bridge path, slower, same
     reservations as in section 3 above
3. **A `.vimspector.json` per project.** Vimspector substitutes `${...}` variables and prompts for
   any that are undefined, so a single generic config with `"program": "${program}"` gets close to
   the nvim-dap "prompt me for the binary" behavior.
4. **Keymaps that do not fight the existing F-row** — see the table below.

### What it does not need

The `python3` provider is already working: `has('python3')` is 1 and `pynvim` 0.6.0 is importable
from the interpreter `vim.g.python3_host_prog` resolves to. **[verified]** This is the usual
Vimspector installation blocker and it is already satisfied here.

### `lldb-dap` is still usable

Vimspector is not limited to its published gadgets — a custom adapter can be declared in
`g:vimspector_adapters` or a `.gadgets.d/*.json` file. Since `lldb-dap` is already installed and
verified working end-to-end on this machine, pointing Vimspector at it directly is an option that
skips the gadget download entirely. The gadget route is better trodden; the custom route is one
small JSON file.

### The cost of the choice

`nvim-dap` stays on disk regardless, because `nvim-java` depends on it and populates
`dap.configurations.java`. That is fine — two DAP clients coexist without conflict as long as only
one of them has keymaps and a UI. It does mean Java debugging (if it is ever used) would go through
`nvim-dap` while C++ goes through Vimspector, i.e. two different UIs for the same task. Worth
knowing before committing.

## Appendix: What the `nvim-dap` Setup Would Have Looked Like

Kept for reference and for sizing, since the two clients need comparable amounts of wiring. Sketch
only — **not applied**, and superseded by the Vimspector decision above.

```lua
-- lua/plugins/nvim-dap.lua
return {
  "mfussenegger/nvim-dap",
  config = function()
    local dap = require("dap")

    -- Homebrew keeps llvm keg-only; ~/.zshrc puts it on PATH, but not every launch inherits that.
    local lldb_dap = vim.fn.exepath("lldb-dap")
    if lldb_dap == "" then lldb_dap = "/opt/homebrew/opt/llvm/bin/lldb-dap" end

    dap.adapters.lldb = { type = "executable", command = lldb_dap, name = "lldb" }

    dap.configurations.cpp = {
      {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
      },
    }
    dap.configurations.c = dap.configurations.cpp

    -- Picks up .vscode/launch.json when a project has one.
    require("dap.ext.vscode").load_launchjs(nil, { lldb = { "c", "cpp" } })
  end,
}
```

Plus signs, plus keymaps, plus (optionally) a UI.

### Keymap conflicts to resolve

Vimspector ships two mapping schemes, enabled with `g:vimspector_enable_mappings`. Neither is active
today (the variable is unset), so the plugin currently maps nothing. Read out of the installed
`plugin/vimspector.vim` **[verified]**:

| Scheme | Keys used |
| --- | --- |
| `HUMAN` | `F3` stop, `F4` restart, `F5` continue, `F6` pause, `F8` add function breakpoint, `F9` toggle breakpoint, `F10` step over, `F11` step into, `F12` step out (+ `<leader>F5/F8/F9`) |
| `VISUAL_STUDIO` | `F5` continue, `F6` pause, `F8` jump to next breakpoint, `F9` toggle breakpoint, `F10` step over, `F11` step into (+ `S-F5` stop, `C-S-F5` restart, `S-F8`, `S-F9`, `C-F10` run to cursor, `S-F11` step out) |

**Changes applied 2026-09-20.** The `F8`/`F9` tab-navigation mappings were removed (normal and
insert mode) in favour of Neovim's built-in `gt` / `gT`, keeping `<C-t>` for a new tab. The
tabs/spaces toggle moved from `F10` to `,ts`. That clears every key either Vimspector scheme needs
except `F3`.

Current F-row state:

| Key | Bound to | `HUMAN` wants | `VISUAL_STUDIO` wants |
| --- | --- | --- | --- |
| `F1` | — (Neovim's built-in help key) | — | — |
| `F2` | session save | — | — |
| `F3` | session load | **stop** ✗ | — |
| `F4`–`F12` | free | ✓ | ✓ |

**`VISUAL_STUDIO` is now collision-free.** `HUMAN` has one conflict left, `F3` (stop) against session
load; its stop command would need remapping, or `VISUAL_STUDIO` adopted instead, which puts stop on
`S-F5` and leaves `F3` alone.

For reference, the `,` namespace is now `,c` (trouble/codecompanion), `,d` (`"_d` **and** nvim-gdb's
`,db`/`,dd`/`,dl`/`,dp`/`,dr`), `,f` (telescope), `,h` (gitgutter), `,i` (indent guides), `,p`
(img-clip), `,t` (tabs/spaces toggle) and `,x` (trouble). **[verified at runtime]** Note that `,d`
already sits behind a `timeoutlen` delay because of nvim-gdb's sub-mappings; removing nvim-gdb both
fixes that and frees `,d*` as the natural debug namespace if a leader-based scheme is ever preferred
over the F-row.

Two things worth knowing about the mechanics:

- **`F1` is not free in the way `:map <F1>` suggests.** It reports "No mapping found" because Neovim
  treats `F1` as a built-in help key in normal and insert mode rather than as a mapping. **[verified]**
  Binding it shadows that; harmless if `:help` is typed out, but it is a real default being
  overridden, not an unused key.
- **Repo mappings win.** `init.lua` loads `config.lazy` before `config.keymaps`, so
  `lua/config/keymaps.lua` runs after Vimspector's `plugin/` file. A collision means Vimspector
  silently loses the key — no error, no warning. Worth remembering when a debug key "does nothing".

The lowest-friction option is to leave `g:vimspector_enable_mappings` unset and map the `<Plug>`
targets explicitly onto the keys that are actually free. That also sidesteps the question of which
scheme to adopt.

### Optional UI layer (nvim-dap only)

- `rcarriga/nvim-dap-ui` (requires `nvim-neotest/nvim-nio`) — scopes/watches/stacks/breakpoints
  panels and a REPL, auto-opened on `dap.listeners` events. This is what makes it feel like an IDE.
- `theHamsta/nvim-dap-virtual-text` — inline variable values as virtual text next to the source.
  Requires treesitter, which is already configured here.
- `nvim-telescope/telescope-dap.nvim` — pick a launch configuration or list breakpoints through
  Telescope, which this config already uses heavily.
- None of these apply to Vimspector, which brings its own variables/watches/stack/console/terminal
  layout — the reason it was chosen.
- `nvim-dap` also has built-in lightweight widgets (`require('dap.ui.widgets').hover()`,
  `.centered_float(widgets.scopes)`) if a full UI feels like too much.

## Per-Project Launch Configuration — the Real Design Question

Breakpoints are trivial; telling the debugger *what to run* is where C++ setups get bespoke. With
Vimspector this is `.vimspector.json`, and there is no way around having one — but how it gets
filled is still a choice:

1. **One generic config with prompts.** `"program": "${program}"` and `"cwd": "${workspaceRoot}"`;
   Vimspector prompts for any `${...}` it cannot resolve, so a single file covers a lot of ground.
   Undefined variables can also be pre-seeded per project.
2. **A checked-in `.vimspector.json` per project**, with one entry per target. Standard Vimspector
   practice, shareable with teammates, and the file format is close enough to VSCode's `launch.json`
   that translating between them is mechanical.
3. **CMake-aware.** `Civitasv/cmake-tools.nvim` knows the build directory and target list. Its
   integration is written for `nvim-dap`, so under Vimspector it would be a helper that writes or
   templates `.vimspector.json` rather than a drop-in. `neocmakelsp` is installed here, which hints
   CMake is the build system in use — worth confirming before deciding whether this is worth the
   work.

A reasonable path: start with (1), graduate to (2) per project as the targets stabilize, and only
look at (3) if picking targets by hand becomes the friction.

## Things That Will Bite

- **Build flags.** Breakpoints only bind against DWARF. `-g` is required and `-O0` (or `-Og`) is
  strongly advised; with `-O2`, lines get merged and locals get optimized out. If builds go through
  CMake, that means `-DCMAKE_BUILD_TYPE=Debug`.
- **`dSYM` on macOS.** Clang leaves debug info in the `.o` files unless `dsymutil` runs. Single-file
  builds work because LLDB finds the objects; for larger projects, `-g` plus a `dSYM` bundle (CMake
  does this for `Debug`/`RelWithDebInfo` on Apple platforms) avoids "breakpoint not resolved" after
  the object files move or get cleaned.
- **Paths must match.** The path `nvim-dap` sends in `setBreakpoints` must match the compilation
  path. Out-of-tree builds, symlinked source roots (this config already resolves symlinks for LSP
  jumps in `keymaps.lua` — the same class of problem), or containers need
  `initCommands = { "settings set target.source-map ..." }`.
- **Breakpoint persistence is a point in Vimspector's favour.** `nvim-dap` keeps breakpoints in
  memory only, and `Session.vim` via `obsession` (F2/F3) does not save them — that path needs
  `Weissle/persistent-breakpoints.nvim`. Vimspector has it built in: `:VimspectorMkSession` /
  `:VimspectorLoadSession` (`vimspector#WriteSessionFile` / `#ReadSessionFile`) persist breakpoints
  and configuration to a session file. **[verified present in the installed plugin]** That pairs
  naturally with the existing F2/F3 session keys.
- **`termguicolors`, signs and the sign column.** Already fine here (`termguicolors` is on), but the
  breakpoint sign shares the sign column with `gitgutter` and LSP diagnostics; sign priority may
  need tuning so breakpoints are not hidden.
- **`nvim-java` also uses `nvim-dap`.** Under the Vimspector decision this mostly stops mattering —
  just do not give `nvim-dap` keymaps or a UI, and leave `dap.configurations.java` to `nvim-java`.

## Recommendation

**Effort estimate: an afternoon**, in four steps.

1. **Prune.** Vimspector is the client, so `nvim-dap` should not also get keymaps or a UI — leave it
   to `nvim-java` and forget about it. Decide whether `sakhnik/nvim-gdb` earns its place as a
   separate raw-debugger-in-a-terminal workflow; if not, remove `lua/plugins/nvim_gdb.lua`. Note
   that `gdb` itself is unusable on this machine, so `nvim-gdb` would have to be pointed at `lldb`.
2. **Make Vimspector real.** Add a `build` step to `lua/plugins/vimspector.lua` that installs the
   `CodeLLDB` gadget, and confirm the gadget lands under the plugin's `gadgets/macos*` directory.
   This is the step that turns an inert plugin into a working debugger.
3. **Pick keymaps.** The proposed `F10` → `F1` and `F9` → `F12` move frees the two keys that matter
   most. Adopting `VISUAL_STUDIO` on top of it leaves only `F8` in conflict; moving `:tabprevious`
   to the free `F7` clears that too. Alternatively skip `g:vimspector_enable_mappings` and map the
   `<Plug>` targets by hand.
4. **Write one `.vimspector.json`** against a real project and step through it, before investing in
   templating or CMake integration.

## Open Questions

- Is the target C++ workflow CMake-based? That decides how much `.vimspector.json` templating is worth.
- Attach-to-running-process on macOS is now verified and works for ordinary local builds — is it
  actually wanted in the workflow? If so it costs one `go build` for `vimspector_process_list` plus
  an `attach` entry per project.
- Should breakpoints persist across sessions (they would pair naturally with the existing F2/F3
  session workflow)?
- Keep `nvim-gdb` for raw-debugger use, or consolidate entirely on Vimspector?
- `CodeLLDB` gadget vs. pointing Vimspector at the already-installed, already-verified `lldb-dap`
  via a custom adapter definition — the second avoids a download but is the less-travelled path.
- Java debugging would run through `nvim-dap` while C++ runs through Vimspector. Acceptable, or
  should Java move too?
- Should the four none-ls formatters that are missing from `PATH` (`prettier`, `stylua`, `rubocop`,
  `sql_formatter`) be added to `lua/plugins/mason-tool-installer.lua`?
