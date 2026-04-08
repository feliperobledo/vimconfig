# Neovim 0.12.0 Migration

## Migration Steps

1. Verify the runtime under Neovim 0.12.
2. Verify LSP behavior in real files.
3. Audit for the `shelltemp` change in Neovim 0.12.
4. Clean up incidental files and prepare the final commit.

## Current Steps

- Step 1 is done: runtime under Neovim 0.12 verified.
- Step 3 is done: `shelltemp` audit verified.
- Remaining main verification step is Step 2: verify LSP behavior in real files.
- Known open issue for Java: `gy` / `vim.lsp.buf.type_definition()` with `jdtls` returns `INVALID_SERVER_MESSAGE`. Current mitigation is in `lua/config/lsp.lua`, where `gy` is guarded and short-circuited for `jdtls`.

## Next Steps

- Open real TypeScript, Python, Java, and C# files.
- Check `gd`, `gy`, `gr`, `gI`, `K`, `<leader>ca`, signature help, and diagnostics navigation.
- Capture any filetype-specific failures separately so they can be fixed one at a time.
- Prioritize TypeScript next, since that is the next area being tested.

## Handoff Note

- Neovim is now managed with `bob`, not Homebrew.
- `python3_host_prog` now uses `vim.fn.exepath("python3")`.
- Runtime verification and `shelltemp` audit are already complete.
- Remaining work is LSP behavior verification and any follow-up fixes.
