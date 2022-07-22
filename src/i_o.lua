local M = {}

local __string_format = string.format
local __tonumber = tonumber
local __os_execute = os.execute
local __io_popen = io.popen
local __io_open = io.open
local __string_match = string.match
local __conky_parse	= conky_parse

--------------------------------------------------------------------------------
-- logging/printing

M.printf = function(fmt, ...)
   print(__string_format(fmt, ...))
end

M.logf = function(level, fmt, ...)
   M.printf(level..': '..fmt, ...)
end

M.errorf = function(fmt, ...)
   M.logf('ERROR', fmt, ...)
end

M.warnf = function(fmt, ...)
   M.logf('WARN', fmt, ...)
end

M.infof = function(fmt, ...)
   M.logf('INFO', fmt, ...)
end

M.assertf = function(test, fmt, ...)
   -- NOTE use exit here because the assert command will only break one loop
   -- in the conky update cycle rather than quit the entire program
   if not test then
      M.errorf(fmt, ...)
      print(debug.traceback())
      os.exit(1)
   end
end

--------------------------------------------------------------------------------
-- reading files/command output

--[[
available modes per lua docs
*n: number (actually returns a number)
*a: entire file (default here)
*l: reads one line and strips \n (default for read cmd)
*L; reads one line and keeps \n
N: reads number of lines (where N is a number)
--]]
local read_entire_file = function(file, regex, mode)
	if not file then return end
	local str = file:read(mode or '*a')
	file:close()
	if not str then return end
	if regex then return __string_match(str, regex) else return str end
end

M.read_file = function(path, regex, mode)
	return read_entire_file(__io_open(path, 'rb'), regex, mode)
end

M.execute_cmd = function(cmd, regex, mode)
	return read_entire_file(__io_popen(cmd), regex, mode)
end

--------------------------------------------------------------------------------
-- boolean tests

M.exit_code_cmd = function(cmd)
   local _, _, rc = __os_execute(cmd)
   return rc
end

M.exe_exists = function(exe)
   return M.exit_code_cmd('command -v '..exe..' > /dev/null') == 0
end

M.assert_exe_exists = function(exe)
   M.assertf(M.exe_exists(exe), 'executable %s not found', exe)
end

M.file_exists = function(path)
   return M.exit_code_cmd('stat '..path..' > /dev/null 2>&1') == 0
end

M.file_readable = function(path)
   return M.exit_code_cmd('test -r '..path) == 0
end

M.assert_file_exists = function(path)
   M.assertf(M.file_exists(path), '%s does not exist', path)
end

M.assert_file_readable = function(path)
   M.assertf(M.file_exists(path), '%s does not exist', path)
   M.assertf(M.file_readable(path), '%s is not readable', path)
end

--------------------------------------------------------------------------------
-- conky object execution

M.conky = function(expr, regex)
	local ans = __conky_parse(expr)
	if regex then return __string_match(ans, regex) or '' else return ans end
end

M.conky_numeric = function(expr, regex)
	return __tonumber(M.conky(expr, regex)) or 0
end

return M
