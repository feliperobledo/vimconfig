# vimconfig

My neovim configuration files

## Neovim Version Management

Neovim is managed with `bob`, not Homebrew. This makes it easier to pin or switch Neovim versions during migrations without changing the system package manager state.

Typical workflow:

```bash
bob install 0.12.0
bob use 0.12.0
```

The shell should prepend `~/.local/share/bob/nvim-bin` to `PATH` so `nvim` resolves to the Bob-managed version.

## Stack

| Plugin                              | Role                           | Responsibilities                                                                             | Interactions                                                                                                                                         |
| ----------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `neovim/nvim-lspconfig`             | LSP client configuration layer | Provides the native LSP client integration used by Neovim `0.12` defaults and plugin-managed servers. | Works with `mason-lspconfig`, feeds diagnostics to native tooling such as `vim.diagnostic`, and underpins server-specific integrations like Java and GraphQL. |
| `williamboman/mason.nvim`           | External tool manager          | Install and update language servers, formatters, and linters from the Mason registry.        | Uses the registry API to auto-install required language servers listed in `lua/plugins/mason.lua`.                                                  |
| `hrsh7th/nvim-cmp`                  | Completion engine              | Provide completion UI, sorting, and mappings in insert and command-line modes.               | Aggregates sources (LSP, buffer, path) and uses Neovim's built-in snippet API for any server-supplied snippets.                                      |
| `hrsh7th/cmp-nvim-lsp`              | LSP completion source          | Surface LSP completion items in `nvim-cmp` and provide an opt-in capabilities helper for explicit server setups. | Relies on active LSP clients; useful if the config later adds server-specific capability overrides.                                                   |
| `hrsh7th/cmp-buffer`                | Buffer completion source       | Offer buffer words as completion suggestions.                                                | Loaded as an `nvim-cmp` source alongside LSP entries.                                                                                                |
| `hrsh7th/cmp-path`                  | Filesystem completion source   | Suggest filesystem paths in insert or command-line completion.                               | Enabled through the `nvim-cmp` source list; complements command-line completion.                                                                     |
| `hrsh7th/cmp-cmdline`               | Command-line completion source | Provide `:` and `/` completion via `nvim-cmp`.                                               | Configured with `cmp.setup.cmdline`; pairs with buffer/path sources.                                                                                 |
| `folke/neodev.nvim`                 | Neovim Lua helper              | Improve `lua_ls` behavior when editing Neovim configs and plugins.                           | Complements the native LSP stack for Lua development.                                                                                                 |
| `j-hui/fidget.nvim`                 | LSP progress UI                | Display asynchronous LSP request progress without blocking editing.                          | Hooks into handlers registered via `nvim-lspconfig`.                                                                                                 |
| `folke/trouble.nvim`                | Diagnostics/workspace list     | Visualize diagnostics, references, and quickfix items in a dedicated panel.                  | Consumes `vim.diagnostic` data from LSP servers and integrates with Telescope pickers.                                                               |
| `Hoffs/omnisharp-extended-lsp.nvim` | OmniSharp navigation helper    | Provide enhanced definition handlers for C# LSP responses if explicit OmniSharp customization is added later. | Not currently wired through a shared LSP module in this repo.                                                                                         |


## Debugging

C/C++ debugging. Background and decisions: `plans/cpp-debugging.md`, `research/cpp-debugging.md`.

### Stack

- **Client: Vimspector** (`lua/plugins/vimspector.lua`), chosen for its UI. `g:vimspector_enable_mappings` stays unset; keys are explicit `<Plug>` mappings.
- **Adapter: Homebrew LLVM's `lldb-dap`**, declared as a custom adapter `lldb-dap` in `g:vimspector_adapters`. Path is `exepath("lldb-dap")` (on `PATH` via `~/.zshrc`), falling back to `/opt/homebrew/opt/llvm/bin/lldb-dap`; warns once if it isn't executable. No Mason package, no Vimspector gadget download.
- **Build step:** the lazy spec's `build` runs `go build` in the plugin's `support/vimspector_process_list/` (the helper behind `${PickProcess()}`; upstream ships Go source only). Falls back to `/usr/local/go/bin/go`.
- **nvim-dap is only nvim-java's dependency** for Java debugging. Give it no keymaps or UI.
- Breakpoint sign priorities are 12 (above gitgutter's 10) and must stay equal to each other so Vimspector can combine them.

### Keys

| Key | Action | `<Plug>` target |
| --- | --- | --- |
| `F5` | Launch / continue | `VimspectorContinue` |
| `S-F5` | Stop | `VimspectorStop` |
| `C-S-F5` | Restart | `VimspectorRestart` |
| `F6` | Pause | `VimspectorPause` |
| `F8` | Function breakpoint | `VimspectorAddFunctionBreakpoint` |
| `F9` | Toggle breakpoint | `VimspectorToggleBreakpoint` |
| `,F9` | Conditional breakpoint | `VimspectorToggleConditionalBreakpoint` |
| `F10` | Step over | `VimspectorStepOver` |
| `F11` | Step into | `VimspectorStepInto` |
| `S-F11` | Step out | `VimspectorStepOut` |
| `,F10` | Run to cursor | `VimspectorRunToCursor` |
| `,Di` | Inspect value under cursor (normal + visual) | `VimspectorBalloonEval` |
| `,DX` | Reset: end session, close the UI, never prompts | `vimspector#Reset()` (not `:VimspectorReset`) |

All normal mode except `,Di`. macOS's Show Desktop shortcut on `F11` (System Settings → Keyboard → Keyboard Shortcuts → Mission Control) must stay disabled, or it swallows step-into. Leader debug keys go under `,D`, never `,d`: `,d` is the `"_d` operator, and any `,d…` mapping makes it wait for `timeoutlen`.

### Commands

- **`:VimspectorInitCpp[!]`** writes `<cwd>/.vimspector.json`; refuses to overwrite unless `!`. Defined in `lua/config/commands.lua`.
  - No `CMakeLists.txt` in the cwd: copies `templates/vimspector-cpp.json` (`Launch` prompting for `${program}` / `${args}`, `Attach (pick process)`, `Attach (wait for launch)`).
  - With `CMakeLists.txt`: generates the file (`lua/config/cmake_debug.lua`). Uses the `debug` configure preset if `CMakePresets.json` has one (otherwise asks which preset, remembered per project for the Neovim session), with the build dir from the preset's `binaryDir`; without presets, `build/` (`-DCMAKE_BUILD_TYPE=Debug` only on its first configure). Never uses an in-source `CMakeCache.txt`. Writes a CMake File API `codemodel-v2` query, configures, and lists the project's own `EXECUTABLE` targets (not under the build dir, so no FetchContent `_deps`, and not outside the project root). Each target gets `<target>: Launch`, `<target>: Attach (pick process)` and `<target>: Attach (wait for launch)`; `cwd` is the executable's directory. Refuses unless `CMAKE_BUILD_TYPE` is `Debug` or `RelWithDebInfo`. Configure errors go to the quickfix list.
  - Generated Launch configs have `"args": []`: add arguments there by hand. `:VimspectorInitCpp!` regenerates and discards edits.
  - `.vimspector.json` and `.vimspector.session` are not committed: add them to each project's own `.gitignore`.
- **`:CMakeDebug [target]`** (completes target names) builds just that target in the background (`cmake --build --preset <name>` or `cmake --build <build>`, plus `--target`), fills the quickfix list with the output (opened only on failure), and on success starts `<target>: Launch` by name. Without an argument it uses the only Launch target or asks with `vim.ui.select` (Vimspector's own picker filters by the current buffer's filetype). It configures only if the build dir has no `CMakeCache.txt`, never regenerates `.vimspector.json`, and refuses outside a CMake project or without a `.vimspector.json`.

### Rules for any `.vimspector.json` configuration

Hand-written or generated, launch or attach:

- **`breakpoints.exception`** answering `cpp_throw`, `cpp_catch`, `objc_throw`, `objc_catch` in every configuration: otherwise every start asks four Y/N questions. Vimspector reads it per configuration only, so it can't go in the adapter.
- **`"request"` must be set** (`launch` / `attach`): Vimspector has no default for it.
- **Attach by picker** uses `"pid#json": "${PickProcess(\"^<basename>$$\")}"`: the picker matches a regex against the process *name*, not a path; anchoring pre-fills a single match; `#json` sends a number (lldb-dap rejects a string pid); `$$` is a literal `$`.
- **Remap paths with lldb-dap's `sourceMap`, never `initCommands`**: Vimspector merges the adapter's `configuration` shallowly, so a project `initCommands` replaces the adapter's list and drops the `std::expected` formatter import.
- **Launch configs carry `"runInTerminal": true` plus the `terminateCommands` kill-if-detached script** (copy it from the template). `runInTerminal` gives the program a real TTY (colours, stdin) instead of the Console, which shows escape codes raw; but lldb-dap then *attaches* to the program it started, so the script SIGKILLs it when the session ended by detaching. **Attach configs carry neither**, so stopping only detaches from them.
- No `attach`/`pidSelect` block in the adapter: it would take over every attach config without a `pid`, including `waitFor` ones.

### Stopping

- `S-F5`, `,DX` and `C-S-F5` end a launched program (via `terminateCommands`) and detach from an attached one, which keeps running. Restart leaves exactly one instance.
- `:VimspectorReset` asks "Terminate debuggee?" while the process is alive. Y kills, attached or launched. N detaches from an attached process but still ends a launched one (accepted trade-off of the `terminateCommands` fix).
- To keep a program running after the debugger lets go, start it yourself and attach.

### Breakpoints and sessions

- `F2` (`lua/config/keymaps.lua`) also writes `<cwd>/.vimspector.session` next to `Session.vim`, but only when breakpoints exist or the file already exists (so clearing all breakpoints sticks, and projects that never debug stay clean). Watches or exception settings alone don't create it.
- `F3` sources `Session.vim`, then reads `<cwd>/.vimspector.session` if it exists (path resolved before sourcing).
- `signcolumn=auto:2` (`lua/config/options.lua`) shows a breakpoint next to gitgutter's marker on the same line. The column widens to four cells for the whole window while any line has two signs.
- `sessionoptions` includes `localoptions`, so a `Session.vim` saved before a window-option change (e.g. `signcolumn`) restores the old value on `F3` until it's re-saved with `F2`.

### `std::expected` formatter

LLDB 22 has built-in libc++ formatters for `vector`, `string`, `map`, `optional`, `variant`, `span`, `unique_ptr`, but not `std::expected`. `lldb/libcxx_expected.py` adds a summary (`has value` / `has error`) and a single `Value` or `Error` child (none for `expected<void, E>`), finding libc++'s members by name because the layout varies by type. The adapter's `initCommands` imports it by absolute path (`stdpath("config") .. "/lldb/libcxx_expected.py"`), only if the file exists. By hand: `command script import <path>/libcxx_expected.py`. Verified against Homebrew clang 22 and Apple clang 21 builds.

### Known issues and limits

- **Clearing all breakpoints** (`vimspector#ClearBreakpoints()`, or "Clr All" in the breakpoints window) during a session leaves them active in lldb-dap: Vimspector only re-sends files still in its list. Clear them one by one with `F9`, or restart the session.
- **`waitFor` attaches about 40–50 ms after the process starts**, so it catches startup code but not the first lines of `main`.
- **Hover (`,Di`) evaluates variable and member paths only**, not arithmetic. Use watches for expressions.
- **Expressions can only call functions present in the binary** (`v.size()` works if the program calls it; `v[1]`, `o.value()`, `*up` fail).
- **Keep `target.import-std-module` off**: it fixes some of those expressions but crashed LLDB (on `m.at("b")`).
- **Each Vimspector run overwrites `~/.vimspector.log`**: copy it before the next run if you need it.
- **Attach fails on hardened-runtime binaries.** Symptom: "Attached to process N", then "Trying to resume but the async thread is dead". The target's signature refuses the debugger; the config is fine.
  - Check: `codesign -dv --entitlements - <bin>`. Plain `clang++` / CMake `Debug` builds show `flags=0x20002(adhoc,linker-signed)` and attach fine. `runtime` in the flags without `com.apple.security.get-task-allow` means attach is refused.
  - Workaround for a local copy: `codesign -f -s - -o runtime --entitlements gta.plist <bin>`, where `gta.plist` is a plist containing `<key>com.apple.security.get-task-allow</key><true/>`.


## TODO

- [ ] Learn how to use MCP hub
- [ ] Learn how to use Codecompanion

