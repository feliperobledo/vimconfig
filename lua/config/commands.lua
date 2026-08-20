-- :UnMinify (ported from your Vimscript)
vim.api.nvim_create_user_command("UnMinify", function()
  -- Equivalent substitutions
  vim.cmd([[%s/{\ze[^\r\n]/{\r/g]])
  vim.cmd([[%s/){/) {/g]])
  vim.cmd([[%s/};\?\ze[^\r\n]/\0\r/g]])
  vim.cmd([[%s/;\ze[^\r\n]/;\r/g]])
  vim.cmd([[%s/[^\s]\zs[=&|]\+\ze[^\s]/ \0 /g]])
  vim.cmd("normal! ggVG=")
end, {})

-- :PrettyXML (depends on xmllint installed)
vim.api.nvim_create_user_command("PrettyXML", function()
  local origft = vim.bo.filetype
  vim.bo.filetype = ""

  -- delete xml header if exists
  vim.cmd([[1s/<?xml .*?>//e]])

  -- wrap with fake tags
  vim.fn.append(0, "<PrettyXML>")
  vim.fn.append(vim.fn.line("$"), "</PrettyXML>")

  -- format via external command
  vim.cmd([[silent %!xmllint --format -]])

  -- remove fake tags: delete line 2 and last line
  vim.cmd([[2delete]])
  vim.cmd([[$delete]])

  -- fix indent level
  vim.cmd([[silent %<]])

  -- back to top
  vim.cmd([[1]])

  -- restore filetype
  vim.bo.filetype = origft
end, {})
