--[[
Provides Marko/GraphQL syntax support and toggles advanced C++ highlighting globals.
Was ported from the old Vimscript setup and keeps those language tweaks alive during the migration.
]]
return {
  "Epitrochoid/marko-vim-syntax",
  config = function()
    vim.g.cpp_class_scope_highlight = 1
    vim.g.cpp_member_variable_highlight = 1
    vim.g.cpp_class_decl_highlight = 1
    vim.g.cpp_experimental_simple_template_highlight = 1
    vim.g.cpp_concepts_highlight = 1
  end,
}
