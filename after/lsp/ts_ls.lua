--[[
Mason's typescript-language-server ships typescript 7.x, which has no tsserver.js,
so ts_ls fails to initialize in projects without a local typescript dependency.
Point it at a pinned 5.x install, but only when the workspace has none of its own.
]]
local fallback = vim.fs.normalize("~/.local/share/nvim/ts-fallback/node_modules/typescript/lib")

return {
  before_init = function(params, _)
    local root = params.rootPath
    if type(root) ~= "string" then
      return
    end

    if vim.uv.fs_stat(root .. "/node_modules/typescript/lib/tsserver.js") then
      return
    end

    if not vim.uv.fs_stat(fallback .. "/tsserver.js") then
      vim.notify_once(
        "ts_ls: no workspace typescript and no fallback install.\n"
          .. "Run: npm i --prefix ~/.local/share/nvim/ts-fallback typescript@5",
        vim.log.levels.WARN
      )
      return
    end

    params.initializationOptions = vim.tbl_deep_extend("force", params.initializationOptions or {}, {
      tsserver = { path = fallback },
    })
  end,
}
