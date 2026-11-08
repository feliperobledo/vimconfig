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

-- :VimspectorInitCpp[!] — write a C/C++ .vimspector.json into the cwd (the project root,
-- same rule as the F2/F3 .vimspector.session). Vimspector finds it by searching upward
-- from the current buffer, and ${workspaceRoot} is the directory it was found in.
local function vimspector_json_path()
  return vim.fn.getcwd() .. "/.vimspector.json"
end

-- Writes `lines` to <cwd>/.vimspector.json; refuses to replace an existing file unless `force`.
local function write_vimspector_json(lines, force)
  local target = vimspector_json_path()
  if vim.uv.fs_stat(target) and not force then
    vim.notify(target .. " already exists; use :VimspectorInitCpp! to overwrite it", vim.log.levels.ERROR)
    return
  end
  -- writefile raises E482 (rather than returning -1) when called through vim.fn.
  local ok, result = pcall(vim.fn.writefile, lines, target)
  if not ok or result ~= 0 then
    vim.notify("Could not write " .. target .. (ok and "" or (": " .. tostring(result))), vim.log.levels.ERROR)
    return
  end
  vim.notify("Wrote " .. target)
end

vim.api.nvim_create_user_command("VimspectorInitCpp", function(opts)
  local template = vim.fn.stdpath("config") .. "/templates/vimspector-cpp.json"
  if vim.fn.filereadable(template) == 0 then
    vim.notify("Template not found: " .. template, vim.log.levels.ERROR)
    return
  end
  write_vimspector_json(vim.fn.readfile(template), opts.bang)
end, { bang = true, desc = "Write a C/C++ .vimspector.json (lldb-dap) into the cwd; ! overwrites" })
