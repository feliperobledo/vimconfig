--[[
CMake support for C/C++ debugging with Vimspector (plans/cpp-debugging.md, step 7).

- :VimspectorInitCpp (in a CMake project) configures the Debug build and generates one launch
  and two attach configurations per executable target, found through the CMake File API.
- :CMakeDebug [target] builds, puts the output in the quickfix list, and starts Vimspector
  only if the build succeeded.

The build dir comes from the `debug` configure preset (or a picked one), or `build/` when the
project has no presets. An in-source CMakeCache.txt at the project root is never used.
]]

local M = {}

-- File API client name: the query goes in <build>/.cmake/api/v1/query/client-vimconfig/.
local CLIENT = "client-vimconfig"

local DEBUG_BUILD_TYPES = { Debug = true, RelWithDebInfo = true }

-- lldb-dap's exception filters, answered per configuration (see templates/vimspector-cpp.json).
local EXCEPTION_FILTERS = { cpp_throw = "N", cpp_catch = "N", objc_throw = "N", objc_catch = "N" }

-- clang/gcc diagnostics plus CMake's own errors. Paths relative to the build dir (which some
-- generators can print) resolve through a synthetic "Entering directory" first line (%D).
local ERRORFORMAT = table.concat({
  "%f:%l:%c: %trror: %m",
  "%f:%l:%c: %tarning: %m",
  "%f:%l:%c: %tote: %m",
  "%f:%l: %trror: %m",
  "%f:%l: %tarning: %m",
  "CMake %trror at %f:%l %m",
  "CMake %tarning at %f:%l %m",
  "%D%*\\a[%*\\d]: Entering directory %*[`']%f'",
  "%X%*\\a[%*\\d]: Leaving directory %*[`']%f'",
  "%D%*\\a: Entering directory %*[`']%f'",
  "%X%*\\a: Leaving directory %*[`']%f'",
}, ",")

-- Preset picked per project root when there's no `debug` preset, so :CMakeDebug doesn't
-- ask again after :VimspectorInitCpp.
local picked_presets = {}

-- One configure/build at a time.
local busy = false

local function err(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

local function realpath(path)
  return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

-- Real path of a file that may not exist yet (an executable before its first build).
local function realpath_of_file(path)
  return realpath(vim.fs.dirname(path)) .. "/" .. vim.fs.basename(path)
end

local function absolute(base, path)
  if path:sub(1, 1) == "/" then
    return vim.fs.normalize(path)
  end
  return vim.fs.normalize(base .. "/" .. path)
end

local function is_inside(path, dir)
  return vim.fs.relpath(dir, path) ~= nil
end

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, "cannot read " .. path
  end
  local decoded, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded then
    return nil, "cannot parse " .. path .. ": " .. tostring(data)
  end
  return data
end

-- Presets --------------------------------------------------------------------------------

-- Reads CMakePresets.json and CMakeUserPresets.json, following "include". Returns false when
-- neither exists, or nil and a message on error.
local function load_presets(root)
  local presets = { configure = {}, build = {}, order = {} }
  local seen = {}

  local function load(path)
    path = vim.fs.normalize(path)
    if seen[path] then
      return true
    end
    seen[path] = true
    local data, msg = read_json(path)
    if not data then
      return nil, msg
    end
    for _, include in ipairs(data.include or {}) do
      if include:find("%$") then
        return nil, ("%s: macros in \"include\" are not supported (%s)"):format(path, include)
      end
      local ok, include_msg = load(absolute(vim.fs.dirname(path), include))
      if not ok then
        return nil, include_msg
      end
    end
    for _, preset in ipairs(data.configurePresets or {}) do
      if not presets.configure[preset.name] then
        presets.configure[preset.name] = preset
        table.insert(presets.order, preset.name)
      end
    end
    for _, preset in ipairs(data.buildPresets or {}) do
      presets.build[preset.name] = presets.build[preset.name] or preset
    end
    return true
  end

  local found = false
  for _, name in ipairs({ "CMakePresets.json", "CMakeUserPresets.json" }) do
    local path = root .. "/" .. name
    if vim.uv.fs_stat(path) then
      found = true
      local ok, msg = load(path)
      if not ok then
        return nil, msg
      end
    end
  end
  return found and presets or false
end

local function parents_of(preset)
  local inherits = preset.inherits
  if type(inherits) == "string" then
    return { inherits }
  end
  return inherits or {}
end

-- A preset field, following "inherits" (the first parent that sets it wins).
local function preset_field(set, preset, key, depth)
  depth = depth or 0
  if preset[key] ~= nil or depth > 32 then
    return preset[key]
  end
  for _, name in ipairs(parents_of(preset)) do
    local value = set[name] and preset_field(set, set[name], key, depth + 1)
    if value ~= nil then
      return value
    end
  end
end

-- The preset's "environment", merged through "inherits" (the preset's own values win).
local function preset_environment(set, preset, depth)
  depth = depth or 0
  local env = {}
  local parents = parents_of(preset)
  for i = #parents, 1, -1 do
    local parent = set[parents[i]]
    if parent and depth < 32 then
      env = vim.tbl_extend("force", env, preset_environment(set, parent, depth + 1))
    end
  end
  return vim.tbl_extend("force", env, preset.environment or {})
end

-- Expands the macro subset that binaryDir realistically uses; anything else is an error
-- rather than a wrong guess, because the File API query must land in the real build dir.
local function expand_macros(value, set, name, root)
  local preset = set[name]
  local env = preset_environment(set, preset)
  local macros = {
    sourceDir = root,
    sourceParentDir = vim.fs.dirname(root),
    sourceDirName = vim.fs.basename(root),
    presetName = name,
    generator = preset_field(set, preset, "generator"),
    hostSystemName = vim.uv.os_uname().sysname,
    dollar = "$",
    pathListSep = ":",
  }
  local unsupported
  local expanded = value:gsub("%$(%w*){([^}]*)}", function(kind, arg)
    local result
    if kind == "" then
      result = macros[arg]
    elseif kind == "env" then
      result = env[arg]
      if result == nil then
        result = vim.env[arg] or ""
      elseif result == vim.NIL then
        result = ""
      elseif result:find("%$") then
        result = nil -- a macro inside the preset's environment value
      end
    elseif kind == "penv" then
      result = vim.env[arg] or ""
    end
    if result == nil then
      unsupported = unsupported or ("$%s{%s}"):format(kind, arg)
      return ""
    end
    return result
  end)
  if unsupported then
    return nil, "unsupported macro " .. unsupported
  end
  return expanded
end

local function preset_binary_dir(set, name, root)
  local binary_dir = preset_field(set, set[name], "binaryDir")
  if type(binary_dir) ~= "string" then
    return nil, ("configure preset '%s' sets no binaryDir"):format(name)
  end
  local expanded, msg = expand_macros(binary_dir, set, name, root)
  if not expanded then
    return nil, ("configure preset '%s': binaryDir \"%s\": %s"):format(name, binary_dir, msg)
  end
  return absolute(root, expanded)
end

-- Project context -------------------------------------------------------------------------

-- Calls on_ctx with { root, build_dir, preset, configure_cmd, build_cmd }, asking for a preset
-- (vim.ui.select) when presets exist but none is named `debug`.
local function resolve_project(root, on_ctx)
  local presets, msg = load_presets(root)
  if presets == nil then
    return err(msg)
  end

  if not presets then
    -- No presets: build/. The build type is only forced on the first configure, so an
    -- existing build/ keeps its type and gets the build-type check instead of being flipped.
    local build_dir = root .. "/build"
    local configure_cmd = { "cmake", "-S", root, "-B", build_dir, "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" }
    if not vim.uv.fs_stat(build_dir .. "/CMakeCache.txt") then
      table.insert(configure_cmd, "-DCMAKE_BUILD_TYPE=Debug")
    end
    return on_ctx({
      root = root,
      build_dir = build_dir,
      configure_cmd = configure_cmd,
      build_cmd = { "cmake", "--build", build_dir },
    })
  end

  local function use(name)
    local build_dir, dir_msg = preset_binary_dir(presets.configure, name, root)
    if not build_dir then
      return err(dir_msg)
    end
    -- The same-named build preset, if it builds this configure preset; else the plain dir.
    local build_preset = presets.build[name]
    local build_cmd = { "cmake", "--build", build_dir }
    if build_preset and not build_preset.hidden
      and preset_field(presets.build, build_preset, "configurePreset") == name then
      build_cmd = { "cmake", "--build", "--preset", name }
    end
    on_ctx({
      root = root,
      build_dir = build_dir,
      preset = name,
      configure_cmd = { "cmake", "--preset", name },
      build_cmd = build_cmd,
    })
  end

  local debug = presets.configure.debug
  if debug and not debug.hidden then
    return use("debug")
  end
  if picked_presets[root] and presets.configure[picked_presets[root]] then
    return use(picked_presets[root])
  end
  -- "hidden" is not inherited, so only the preset's own flag counts.
  local choices = vim.tbl_filter(function(name)
    return not presets.configure[name].hidden
  end, presets.order)
  if #choices == 0 then
    return err("CMake presets define no visible configure preset")
  end
  vim.ui.select(choices, {
    prompt = "No 'debug' configure preset. Configure preset to debug:",
    format_item = function(name)
      local display = presets.configure[name].displayName
      return display and (name .. " - " .. display) or name
    end,
  }, function(choice)
    if choice then
      picked_presets[root] = choice
      use(choice)
    end
  end)
end

-- CMake steps -----------------------------------------------------------------------------

-- Runs cmd asynchronously; on_exit(code, output_lines, stdout) runs on the main loop.
local function run(cmd, cwd, on_exit)
  busy = true
  vim.system(cmd, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      busy = false
      local stdout = result.stdout or ""
      local output = vim.split(stdout .. "\n" .. (result.stderr or ""), "\n", { trimempty = true })
      on_exit(result.code, output, stdout)
    end)
  end)
end

-- Replaces the quickfix list with a command's output.
local function set_quickfix(title, dir, output)
  local lines = { ("cmake: Entering directory '%s'"):format(dir) }
  vim.list_extend(lines, output)
  vim.fn.setqflist({}, " ", { title = title, lines = lines, efm = ERRORFORMAT })
end

local function check_build_type(ctx)
  local cache = ctx.build_dir .. "/CMakeCache.txt"
  local ok, lines = pcall(vim.fn.readfile, cache)
  if not ok then
    return false, "No " .. cache .. ": configure first"
  end
  local build_type = ""
  for _, line in ipairs(lines) do
    local value = line:match("^CMAKE_BUILD_TYPE:[^=]*=(.*)$")
    if value then
      build_type = value
      break
    end
  end
  if DEBUG_BUILD_TYPES[build_type] then
    return true
  end
  picked_presets[ctx.root] = nil -- ask again next time
  local hint = ctx.preset and ("preset '" .. ctx.preset .. "' is not a debug build")
    or ("reconfigure with cmake -B build -DCMAKE_BUILD_TYPE=Debug")
  return false, ("Refusing to debug %s: CMAKE_BUILD_TYPE is %s, needs Debug or RelWithDebInfo (%s)"):format(
    ctx.build_dir, build_type == "" and "empty" or build_type, hint)
end

-- Writes the File API query, then configures; on_done runs only on success.
local function configure(ctx, on_done)
  -- A stateless query: an empty file named after the object kind. It must exist before
  -- configuring for CMake to write the codemodel reply.
  local query_dir = ctx.build_dir .. "/.cmake/api/v1/query/" .. CLIENT
  local ok = pcall(vim.fn.mkdir, query_dir, "p") and pcall(vim.fn.writefile, {}, query_dir .. "/codemodel-v2")
  if not ok then
    return err("Could not write the CMake File API query in " .. query_dir)
  end
  vim.notify("CMake: " .. table.concat(ctx.configure_cmd, " "))
  run(ctx.configure_cmd, ctx.root, function(code, output, stdout)
    if code ~= 0 then
      set_quickfix("CMake configure", ctx.root, output)
      vim.cmd("copen")
      return err("CMake configure failed (output in quickfix)")
    end
    -- Cross-check the resolved build dir against CMake's own answer.
    local written = stdout:match("Build files have been written to: ([^\n]+)")
    if written and realpath(written) ~= realpath(ctx.build_dir) then
      return err(("CMake configured %s, but the build dir resolved here is %s"):format(written, ctx.build_dir))
    end
    on_done()
  end)
end

-- The project's own executables from the codemodel reply: not generator-provided, source dir
-- inside the project root and outside the build dir (FetchContent's _deps live there).
local function read_targets(ctx)
  local reply_dir = ctx.build_dir .. "/.cmake/api/v1/reply"
  local indexes = vim.fn.glob(reply_dir .. "/index-*.json", false, true)
  if #indexes == 0 then
    return nil, "No CMake File API reply in " .. reply_dir
  end
  table.sort(indexes) -- the lexicographically last index is the newest
  local index, msg = read_json(indexes[#indexes])
  if not index then
    return nil, msg
  end
  local reply = vim.tbl_get(index, "reply", CLIENT, "codemodel-v2")
  if not (reply and reply.jsonFile) then
    return nil, "No codemodel-v2 in the CMake File API reply" .. (reply and reply.error and (": " .. reply.error) or "")
  end
  local codemodel, codemodel_msg = read_json(reply_dir .. "/" .. reply.jsonFile)
  if not codemodel then
    return nil, codemodel_msg
  end
  if #codemodel.configurations ~= 1 then
    return nil, "Multi-config generators are not supported (configurations: " .. #codemodel.configurations .. ")"
  end

  local root, build = realpath(ctx.root), realpath(ctx.build_dir)
  local targets = {}
  for _, entry in ipairs(codemodel.configurations[1].targets) do
    local target, target_msg = read_json(reply_dir .. "/" .. entry.jsonFile)
    if not target then
      return nil, target_msg
    end
    if target.type == "EXECUTABLE" and not target.isGeneratorProvided and target.artifacts then
      local source = realpath(absolute(codemodel.paths.source, target.paths.source))
      if is_inside(source, root) and not is_inside(source, build) then
        local program = realpath_of_file(absolute(codemodel.paths.build, target.artifacts[1].path))
        table.insert(targets, { name = target.name, program = program })
      end
    end
  end
  table.sort(targets, function(a, b)
    return a.name < b.name
  end)
  return targets
end

-- .vimspector.json ------------------------------------------------------------------------

-- Relative to ${workspaceRoot} (the .vimspector.json directory, i.e. the project root) where
-- possible, so the file holds no absolute paths.
local function workspace_path(root, path)
  local relative = vim.fs.relpath(realpath(root), path)
  return relative and ("${workspaceRoot}/" .. relative) or path
end

-- ${PickProcess()} filter: an anchored regex on the process name (the binary's basename),
-- with regex metacharacters escaped. Vimspector reads "$$" as a literal "$".
local function process_filter(program)
  local name = vim.fs.basename(program):gsub("[%^%$%.%*%+%?%(%)%[%]{}|\\]", "\\%0"):gsub("%$", "$$")
  return ('${PickProcess("^%s$$")}'):format(name)
end

local function target_configurations(root, target)
  local program = workspace_path(root, target.program)
  local function entry(configuration)
    return {
      adapter = "lldb-dap",
      filetypes = { "c", "cpp" },
      breakpoints = { exception = vim.deepcopy(EXCEPTION_FILTERS) },
      configuration = configuration,
    }
  end
  return {
    [target.name .. ": Launch"] = entry({
      request = "launch",
      program = program,
      args = {},
      -- The executable's dir: runtime files such as vk_layer_settings.txt are read from cwd.
      cwd = workspace_path(root, vim.fs.dirname(target.program)),
      stopOnEntry = false,
      -- Output goes to a Vimspector terminal (a real TTY, so colours render), not the Console.
      runInTerminal = true,
    }),
    [target.name .. ": Attach (pick process)"] = entry({
      request = "attach",
      ["pid#json"] = process_filter(target.program),
    }),
    [target.name .. ": Attach (wait for launch)"] = entry({
      request = "attach",
      program = program,
      waitFor = true,
    }),
  }
end

local function vimspector_json_lines(ctx, targets)
  local configurations = {}
  for _, target in ipairs(targets) do
    configurations = vim.tbl_extend("error", configurations, target_configurations(ctx.root, target))
  end
  local document = {
    ["$schema"] = "https://puremourning.github.io/vimspector/schema/vimspector.schema.json",
    configurations = configurations,
  }
  local from = ctx.preset and ("preset '" .. ctx.preset .. "'") or "no preset"
  local lines = {
    ("// Generated by :VimspectorInitCpp from %s (%s)."):format(workspace_path(ctx.root, realpath(ctx.build_dir)), from),
    "// :VimspectorInitCpp! regenerates it, discarding edits. Launch configurations pass no",
    "// arguments: add them to \"args\". Remap paths with \"sourceMap\", never \"initCommands\".",
  }
  return vim.list_extend(lines, vim.split(vim.json.encode(document, { indent = "  ", sort_keys = true }), "\n"))
end

-- Names of the targets with a "<target>: Launch" configuration in <root>/.vimspector.json.
function M.launch_targets(root)
  local ok, lines = pcall(vim.fn.readfile, root .. "/.vimspector.json")
  if not ok then
    return {}
  end
  -- Vimspector allows comments; dropping whole-line // comments covers the generated file.
  lines = vim.tbl_filter(function(line)
    return not line:match("^%s*//")
  end, lines)
  local decoded, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  local names = {}
  for name in pairs(decoded and type(data) == "table" and data.configurations or {}) do
    local target = name:match("^(.+): Launch$")
    if target then
      table.insert(names, target)
    end
  end
  table.sort(names)
  return names
end

-- Commands --------------------------------------------------------------------------------

local function check_ready()
  if busy then
    err("A CMake configure or build is already running")
    return false
  end
  if vim.fn.executable("cmake") == 0 then
    err("cmake not found on PATH")
    return false
  end
  return true
end

-- :VimspectorInitCpp for a CMake project: configure, discover targets, then write(lines).
function M.init_vimspector(root, write)
  if not check_ready() then
    return
  end
  resolve_project(root, function(ctx)
    configure(ctx, function()
      local ok, msg = check_build_type(ctx)
      if not ok then
        return err(msg)
      end
      local targets, targets_msg = read_targets(ctx)
      if not targets then
        return err(targets_msg)
      end
      if #targets == 0 then
        return err("No executable targets of this project in " .. ctx.build_dir)
      end
      vim.notify("CMake executables: " .. table.concat(vim.tbl_map(function(t)
        return t.name
      end, targets), ", "))
      write(vimspector_json_lines(ctx, targets))
    end)
  end)
end

-- :CMakeDebug [target]: build `target`, then start its "<target>: Launch" configuration.
-- Without a target, asks which one first (Vimspector's own picker would hide configurations
-- whose "filetypes" don't match the current buffer, e.g. from CMakeLists.txt).
function M.debug(root, target)
  if vim.fn.filereadable(root .. "/CMakeLists.txt") == 0 then
    return err("Not a CMake project (no CMakeLists.txt in " .. root .. ")")
  end
  if not check_ready() then
    return
  end
  if vim.fn.filereadable(root .. "/.vimspector.json") == 0 then
    return err("No .vimspector.json in " .. root .. ": run :VimspectorInitCpp first")
  end
  local targets = M.launch_targets(root)
  if not target then
    if #targets == 0 then
      return err("No \"<target>: Launch\" configurations in .vimspector.json")
    elseif #targets == 1 then
      return M.debug(root, targets[1])
    end
    return vim.ui.select(targets, { prompt = "Target to build and debug:" }, function(choice)
      if choice then
        M.debug(root, choice)
      end
    end)
  end
  if not vim.tbl_contains(targets, target) then
    return err(("No \"%s: Launch\" configuration in .vimspector.json (:VimspectorInitCpp! regenerates it)"):format(target))
  end

  resolve_project(root, function(ctx)
    local function build()
      local ok, msg = check_build_type(ctx)
      if not ok then
        return err(msg)
      end
      local cmd = vim.list_extend(vim.deepcopy(ctx.build_cmd), { "--target", target })
      local title = table.concat(cmd, " ")
      vim.notify("CMake: " .. title)
      run(cmd, root, function(code, output)
        -- Always fill the quickfix list (warnings stay reachable); open it only on failure.
        set_quickfix(title, ctx.build_dir, output)
        if code ~= 0 then
          vim.cmd("copen")
          return err("Build failed (output in quickfix); not starting the debugger")
        end
        vim.notify("Build succeeded")
        -- By name, Vimspector also finds configurations filtered out for the current filetype.
        vim.fn["vimspector#LaunchWithSettings"]({ configuration = target .. ": Launch" })
      end)
    end

    if vim.uv.fs_stat(ctx.build_dir .. "/CMakeCache.txt") then
      build()
    else
      configure(ctx, build)
    end
  end)
end

return M
