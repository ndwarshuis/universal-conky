local M = {}

local i_o = require 'i_o'
local pure = require 'pure'

local __string_match = string.match
local __string_gmatch = string.gmatch
local __string_format = string.format
local __tonumber = tonumber

local dirname = function(s)
   return __string_match(s, '(.*)/name')
end

local read_micro = function(path)
   return i_o.read_file(path, nil, '*n') * 0.000001
end

local gmatch_to_table1 = function(pat, s)
   return pure.iter_to_table1(__string_gmatch(s, pat))
end

local gmatch_to_tableN = function(pat, s)
   return pure.iter_to_tableN(__string_gmatch(s, pat))
end

--------------------------------------------------------------------------------
-- memory

local MEMINFO_PATH = '/proc/meminfo'

local fmt_mem_field = function(field)
   return field..':%s+(%d+)'
end

local meminfo_regex = function(read_swap)
   -- ASSUME the order of the meminfo file will never change, but some options
   -- (like swap) might not exist
   local free_fields = {
         'MemFree',
         'Buffers',
         'Cached'
   }
   local swap_field = 'SwapFree'
   local slab_fields = {
      'Shmem',
      'SReclaimable'
   }
   local all_fields = read_swap == true
      and {free_fields, {swap_field}, slab_fields}
      or {free_fields, slab_fields}
   local patterns = pure.map(fmt_mem_field, pure.flatten(all_fields))
   return table.concat(patterns, '.+\n')
end

M.meminfo_updater_swap = function(mem_state, swap_state)
   local regex = meminfo_regex(true)
   return function()
      mem_state.memfree,
         mem_state.buffers,
         mem_state.cached,
         swap_state.free,
         mem_state.shmem,
         mem_state.sreclaimable
         = __string_match(i_o.read_file(MEMINFO_PATH), regex)
   end
end

M.meminfo_updater_noswap = function(mem_state)
   local regex = meminfo_regex(false)
   return function()
      mem_state.memfree,
         mem_state.buffers,
         mem_state.cached,
         mem_state.shmem,
         mem_state.sreclaimable
         = __string_match(i_o.read_file(MEMINFO_PATH), regex)
   end
end

M.meminfo_field_reader = function(field)
   local pattern = fmt_mem_field(field)
   return function()
      return tonumber(i_o.read_file(MEMINFO_PATH, pattern))
   end
end

--------------------------------------------------------------------------------
-- intel powercap

local SYSFS_RAPL = '/sys/class/powercap'

M.intel_powercap_reader = function(dev)
   local uj = __string_format('%s/%s/energy_uj', SYSFS_RAPL, dev)
   i_o.assert_file_readable(uj)
   return function()
      return read_micro(uj)
   end
end

--------------------------------------------------------------------------------
-- battery

local SYSFS_POWER = '/sys/class/power_supply'

local format_power_path = function(battery, property)
   local p = __string_format('%s/%s/%s', SYSFS_POWER, battery, property)
   i_o.assert_file_readable(p)
   return p
end

M.battery_power_reader = function(battery)
   local current = format_power_path(battery, 'current_now')
   local voltage = format_power_path(battery, 'voltage_now')
   return function()
      return read_micro(current) * read_micro(voltage)
   end
end

M.battery_status_reader = function(battery)
   local status = format_power_path(battery, 'status')
   return function()
      return i_o.read_file(status, nil, '*l') ~= 'Discharging'
   end
end

--------------------------------------------------------------------------------
-- disk io

M.get_disk_paths = function(devs)
   return pure.map(pure.partial(string.format, '/sys/block/%s/stat', true), devs)
end

-- fields 3 and 7 (sectors read and written)
local RW_REGEX = '%s+%d+%s+%d+%s+(%d+)%s+%d+%s+%d+%s+%d+%s+(%d+)'

-- the sector size of any block device in linux is 512 bytes
-- see https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/include/linux/types.h?id=v4.4-rc6#n121
local BLOCK_SIZE_BYTES = 512

M.get_disk_io = function(path)
   local r, w = __string_match(i_o.read_file(path), RW_REGEX)
   return __tonumber(r) * BLOCK_SIZE_BYTES, __tonumber(w) * BLOCK_SIZE_BYTES
end

M.get_total_disk_io = function(paths)
   local r = 0
   local w = 0
   for i = 1, #paths do
      local _r, _w = M.get_disk_io(paths[i])
      r = r + _r
      w = w + _w
   end
   return r, w
end

--------------------------------------------------------------------------------
-- network

-- ASSUME realpath exists (part of coreutils)

local NET_DIR = '/sys/class/net'

local get_interfaces = function()
   local cmd = string.format('realpath %s/* | grep -v virtual', NET_DIR)
   local f = pure.partial(gmatch_to_table1, '/([^/\n]+)\n')
   return pure.maybe({}, f, i_o.execute_cmd(cmd))
end

M.get_net_interface_paths = function()
   local is = get_interfaces()
   return pure.map(
      function(s)
         local dir = string.format('%s/%s/statistics/', NET_DIR, s)
         return {rx = dir..'rx_bytes', tx = dir..'tx_bytes'}
      end,
      is
   )
end

--------------------------------------------------------------------------------
-- cpu

-- ASSUME nproc and lscpu will always be available

M.get_core_number = function()
   return tonumber(i_o.read_file('/proc/cpuinfo', 'cpu cores%s+:%s(%d+)'))
end

M.get_cpu_number = function()
   return tonumber(i_o.execute_cmd('nproc', nil, '*n'))
end

local get_coretemp_dir = function()
   i_o.assert_exe_exists('grep')
   local s = i_o.execute_cmd('grep -l \'^coretemp$\' /sys/class/hwmon/*/name')
   return pure.fmap_maybe(dirname, s)
end

-- map cores to integer values starting at 1; this is necessary since some cpus
-- don't report their core id's as a sequence of integers starting at 0
local get_core_id_indexer = function()
   local make_indexer = pure.compose(
      pure.array_to_map,
      pure.partial(pure.imap, function(i, c) return {tonumber(c), i} end),
      pure.partial(gmatch_to_table1, '(%d+)')
   )
   return pure.fmap_maybe(
      make_indexer,
      i_o.execute_cmd('lscpu -p=CORE | tail -n+5 | sort | uniq')
   )
end

local get_core_mappings = function()
   local ncpus = M.get_cpu_number()
   local ncores = M.get_core_number()
   local nthreads = ncpus / ncores
   local map_ids = function(indexer)
      local f = function(acc, next)
         local cpu_id = tonumber(next[1]) + 1
         local core_id = next[2]
         local conky_core_idx = indexer[tonumber(core_id)]
         acc.mappings[cpu_id] = {
            conky_core_idx = conky_core_idx,
            conky_thread_id = acc.thread_ids[conky_core_idx],
         }
         acc.thread_ids[conky_core_idx] = acc.thread_ids[conky_core_idx] - 1
         return acc
      end
      local cpu_to_core_map = pure.maybe(
         {},
         pure.partial(gmatch_to_tableN, '(%d+),(%d+)'),
         i_o.execute_cmd('lscpu -p=cpu,CORE | tail -n+5')
      )
      local init = {mappings = {}, thread_ids = pure.rep(ncores, nthreads)}
      return pure.reduce(f, init, cpu_to_core_map).mappings
   end
   return pure.fmap_maybe(map_ids, get_core_id_indexer())
end

M.get_coretemp_paths = function()
   local get_paths = function(indexer)
      local d = get_coretemp_dir()
      local get_labels = function(dir)
         i_o.assert_exe_exists('grep')
         return i_o.execute_cmd(string.format('grep Core %s/temp*_label', dir))
      end
      local to_tuple = function(m)
         return {
            indexer[tonumber(m[2])],
            string.format('%s/%s_input', d, m[1])
         }
      end
      local f = pure.compose(
         pure.array_to_map,
         pure.partial(pure.map, to_tuple),
         pure.partial(gmatch_to_tableN, '/([^/\n]+)_label:Core (%d+)\n')
      )
      return pure.maybe({}, f, pure.fmap_maybe(get_labels, d))
   end
   return pure.maybe({}, get_paths, get_core_id_indexer())
end

local match_freq = function(c)
   local f = 0
   local n = 0
   for s in __string_gmatch(c, '(%d+%.%d+)') do
      f = f + __tonumber(s)
      n = n + 1
   end
   return __string_format('%.0f Mhz', f / n)
end

M.read_freq = function()
   -- NOTE: Using the builtin conky functions for getting cpu freq seems to make
   -- the entire loop jittery due to high variance latency. Querying
   -- scaling_cur_freq in sysfs seems to do the same thing. It appears lscpu
   -- (which queries /proc/cpuinfo) is much faster and doesn't have this jittery
   -- problem.
   return pure.maybe('N/A', match_freq, i_o.execute_cmd('lscpu -p=MHZ'))
end

M.get_hwp_paths = function()
   -- ASSUME this will never fail
   return pure.map_n(
      function(i)
         return '/sys/devices/system/cpu/cpu'
            .. (i - 1)
            .. '/cpufreq/energy_performance_preference'
      end,
      M.get_cpu_number()
   )
end

M.read_hwp = function(hwp_paths)
   -- read HWP of first cpu, then test all others to see if they match
   local hwp_pref = i_o.read_file(hwp_paths[1], nil, "*l")
   local mixed = false
   local i = 2

   while not mixed and i <= #hwp_paths do
      if hwp_pref ~= i_o.read_file(hwp_paths[i], nil, '*l') then
         mixed = true
      end
      i = i + 1
   end

   if mixed then
      return 'Mixed'
   elseif hwp_pref == 'power' then
      return 'Power'
   elseif hwp_pref == 'balance_power' then
      return 'Bal. Power'
   elseif hwp_pref == 'balance_performance' then
      return 'Bal. Performance'
   elseif hwp_pref == 'performance' then
      return 'Performance'
   elseif hwp_pref == 'default' then
      return 'Default'
   else
      return 'Unknown'
   end
end

M.init_cpu_loads = function()
   local m = get_core_mappings()
   local cpu_loads = {}
   for cpu_id, core in pairs(m) do
      cpu_loads[cpu_id] = {
         active_prev = 0,
         total_prev = 0,
         percent_active = 0,
         conky_core_idx = core.conky_core_idx,
         conky_thread_id = core.conky_thread_id,
      }
   end
   return cpu_loads
end

M.read_cpu_loads = function(cpu_loads)
   local ncpus = #cpu_loads
   local i = 1
   local iter = io.lines('/proc/stat')
   iter() -- ignore first line
   for ln in iter do
      if i > ncpus then break end
      local user, system, idle = __string_match(ln, '(%d+) %d+ (%d+) (%d+)', 5)
      local active = user + system
      local total = active + idle
      local c = cpu_loads[i]
      if total > c.total_prev then -- guard against 1/0 errors
         c.percent_active = (active - c.active_prev) / (total - c.total_prev)
         c.active_prev = active
         c.total_prev = total
      end
      i = i + 1
   end
   return cpu_loads
end

return M
