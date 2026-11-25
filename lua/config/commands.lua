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

-- True (after saying so) when <cwd>/.vimspector.json exists and `force` isn't set.
local function vimspector_json_blocked(force)
  local target = vimspector_json_path()
  if vim.uv.fs_stat(target) and not force then
    vim.notify(target .. " already exists; use :VimspectorInitCpp! to overwrite it", vim.log.levels.ERROR)
    return true
  end
  return false
end

-- Writes `lines` to <cwd>/.vimspector.json; refuses to replace an existing file unless `force`.
local function write_vimspector_json(lines, force)
  if vimspector_json_blocked(force) then
    return
  end
  local target = vimspector_json_path()
  -- writefile raises E482 (rather than returning -1) when called through vim.fn.
  local ok, result = pcall(vim.fn.writefile, lines, target)
  if not ok or result ~= 0 then
    vim.notify("Could not write " .. target .. (ok and "" or (": " .. tostring(result))), vim.log.levels.ERROR)
    return
  end
  vim.notify("Wrote " .. target)
end

-- With a CMakeLists.txt in the cwd, the file is generated per executable target instead
-- (lua/config/cmake_debug.lua); otherwise it's a copy of the generic template.
vim.api.nvim_create_user_command("VimspectorInitCpp", function(opts)
  local root = vim.fn.getcwd()
  if vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 then
    -- Checked up front too: configuring can take a while before the write would refuse.
    if not vimspector_json_blocked(opts.bang) then
      require("config.cmake_debug").init_vimspector(root, function(lines)
        write_vimspector_json(lines, opts.bang)
      end)
    end
    return
  end
  local template = vim.fn.stdpath("config") .. "/templates/vimspector-cpp.json"
  if vim.fn.filereadable(template) == 0 then
    vim.notify("Template not found: " .. template, vim.log.levels.ERROR)
    return
  end
  write_vimspector_json(vim.fn.readfile(template), opts.bang)
end, { bang = true, desc = "Write a C/C++ .vimspector.json (lldb-dap) into the cwd; ! overwrites" })

-- :CMakeDebug [target] — build the target in the background (asks which one when omitted and
-- there are several); on success start its "<target>: Launch" configuration. Build output goes
-- to the quickfix list, which opens on failure. Doesn't regenerate .vimspector.json.
vim.api.nvim_create_user_command("CMakeDebug", function(opts)
  require("config.cmake_debug").debug(vim.fn.getcwd(), opts.args ~= "" and opts.args or nil)
end, {
  nargs = "?",
  complete = function(arglead)
    return vim.tbl_filter(function(name)
      return vim.startswith(name, arglead)
    end, require("config.cmake_debug").launch_targets(vim.fn.getcwd()))
  end,
  desc = "Build the CMake project, then debug a target with Vimspector",
})
