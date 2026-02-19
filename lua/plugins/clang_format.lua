--[[
Invokes clang-format for C and C++ buffers so we can format code consistently via a simple command.
Acts as a stopgap until we decide whether to rely on LSP formatting or external formatters managed by Mason.
]]
return {
  "rhysd/vim-clang-format",
  ft = { "c", "cpp" },
}
