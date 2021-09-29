local reader = {}

-- insert modreader stuff here
------------------------------

-- Note: This reader is based on commit 5968d99 at https://github.com/XeroOl/notitg-mirin

reader.plr = {1, 2}

local unstable_sort
local stable_sort
do
	--[[
		this is based on code from Dirk Laurie and Steve Fisher,
		used under license as follows:


			Copyright © 2013 Dirk Laurie and Steve Fisher.
			Permission is hereby granted, free of charge, to any person obtaining a
			copy of this software and associated documentation files (the 'Software'),
			to deal in the Software without restriction, including without limitation
			the rights to use, copy, modify, merge, publish, distribute, sublicense,
			and/or sell copies of the Software, and to permit persons to whom the
			Software is furnished to do so, subject to the following conditions:
			The above copyright notice and this permission notice shall be included in
			all copies or substantial portions of the Software.
			THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
			IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
			FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
			AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
			LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
			FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
			DEALINGS IN THE SOFTWARE.
			
		(modifications by Max Cahill 2018, 2020)
		(modifications by XeroOl 2021)
			
		Found at: https://github.com/1bardesign/batteries/blob/master/sort.lua
	]]--

	local sort = {}

	--tunable size for insertion sort 'bottom out'
	sort.max_chunk_size = 32

	--insertion sort on a section of array
	function sort._insertion_sort_impl(array, first, last, less)
		for i = first + 1, last do
			local k = first
			local v = array[i]
			for j = i, first + 1, -1 do
				if less(v, array[j - 1]) then
					array[j] = array[j - 1]
				else
					k = j
					break
				end
			end
			array[k] = v
		end
	end

	--merge sorted adjacent sections of array
	function sort._merge(array, workspace, low, middle, high, less)
		local i, j, k
		i = 1
		-- copy first half of array to auxiliary array
		for j = low, middle do
			workspace[i] = array[j]
			i = i + 1
		end
		-- sieve through
		i = 1
		j = middle + 1
		k = low
		while true do
			if (k >= j) or (j > high) then
				break
			end
			if less(array[j], workspace[i])  then
				array[k] = array[j]
				j = j + 1
			else
				array[k] = workspace[i]
				i = i + 1
			end
			k = k + 1
		end
		-- copy back any remaining elements of first half
		for k = k, j - 1 do
			array[k] = workspace[i]
			i = i + 1
		end
	end

	--implementation for the merge sort
	function sort._merge_sort_impl(array, workspace, low, high, less)
		if high - low <= sort.max_chunk_size then
			sort._insertion_sort_impl(array, low, high, less)
		else
			local middle = math.floor((low + high) / 2)
			sort._merge_sort_impl(array, workspace, low, middle, less)
			sort._merge_sort_impl(array, workspace, middle + 1, high, less)
			sort._merge(array, workspace, low, middle, high, less)
		end
	end

	--default comparison; hoisted for clarity
	local function default_less(a, b)
		return a < b
	end

	--inline common setup stuff
	function sort._sort_setup(array, less)
		--default less
		less = less or default_less
		--
		local n = #array
		--trivial cases; empty or 1 element
		local trivial = (n <= 1)
		if not trivial then
			--check less
			if less(array[1], array[1]) then
				error('invalid order function for sorting; less(v, v) should not be true for any v.')
			end
		end
		--setup complete
		return trivial, n, less
	end

	function sort.stable_sort(array, less)
		--setup
		local trivial, n, less = sort._sort_setup(array, less)
		if not trivial then
			--temp storage; allocate ahead of time
			local workspace = {}
			local middle = math.ceil(n / 2)
			workspace[middle] = array[1]
			--dive in
			sort._merge_sort_impl( array, workspace, 1, n, less )
		end
		return array
	end

	function sort.insertion_sort(array, less)
		--setup
		local trivial, n, less = sort._sort_setup(array, less)
		if not trivial then
			sort._insertion_sort_impl(array, 1, n, less)
		end
		return array
	end

	unstable_sort = table.sort
	stable_sort = sort.stable_sort
end -- sort.xml

local function noop() end
local clear = noop
local iclear = noop
local perframe_data_structure = noop
local stringbuilder = noop
local methods = {}
do
	clear = function(t)
		for k, v in pairs(t) do
			t[k] = nil
		end
		return t
	end

	iclear = function(t)
		for i = 1, #t do
			table.remove(t)
		end
		return t
	end

	function methods:add(obj)
		local stage = self.stage
		self.n = self.n + 1
		stage.n = stage.n + 1
		stage[stage.n] = obj
	end

	function methods:remove()
		local swap = self.swap
		swap[swap.n] = nil
		swap.n = swap.n - 1
		self.n = self.n - 1
	end

	function methods:next()
		if self.n == 0 then return end
		
		local swap = self.swap
		local stage = self.stage
		local list = self.list
		
		if swap.n == 0 then
			stable_sort(stage, self.reverse_comparator)
		end
		if stage.n == 0 then
			if list.n == 0 then
				while swap.n ~= 0 do
					list.n = list.n + 1
					list[list.n] = swap[swap.n]
					swap[swap.n] = nil
					swap.n = swap.n - 1
				end
			else
				swap.n = swap.n + 1
				swap[swap.n] = list[list.n]
				list[list.n] = nil
				list.n = list.n - 1
			end
		else
			if list.n == 0 then
				swap.n = swap.n + 1
				swap[swap.n] = stage[stage.n]
				stage[stage.n] = nil
				stage.n = stage.n - 1
			else
				if self.comparator(list[list.n], stage[stage.n]) then
					swap.n = swap.n + 1
					swap[swap.n] = list[list.n]
					list[list.n] = nil
					list.n = list.n - 1
				else
					swap.n = swap.n + 1
					swap[swap.n] = stage[stage.n]
					stage[stage.n] = nil
					stage.n = stage.n - 1
				end
			end
		end
		return swap[swap.n]
	end

	local mt = {__index = methods}

	perframe_data_structure = function(comparator)
		return setmetatable({
			comparator = comparator,
			reverse_comparator = function(a, b) return comparator(b, a) end,
			stage = {n = 0},
			list = {n = 0},
			swap = {n = 0},
			n = 0,
		}, mt)
	end

	-- the behavior of a stringbuilder
	local stringbuilder_mt =  {
		__index = {
			-- :build() method converts a stringbuilder into a string, with optional delimiter
			build = table.concat,
			-- :clear() method empties the stringbuilder
			clear = iclear,
		},

		-- calling a stringbuilder appends to it
		__call = function(self, a)
			table.insert(self, tostring(a))
			return self
		end,

		-- stringbuilder can convert to a string
		__tostring = table.concat,
	}

	-- stringbuilder constructor
	stringbuilder = function()
		return setmetatable({}, stringbuilder_mt)
	end

end -- std.xml

local function instant() return 1 end
local function linear(t) return t end
reader.instant = instant
reader.linear = linear
do
    reader.flip = setmetatable({}, {
		__call = function(self, fn)
			self[fn] = self[fn] or function(x) return 1 - fn(x) end
			return self[fn]
		end
	})

	local function with1param(fn, defaultparam1)
		local function params(param1)
			return function(x)
				return fn(x, param1)
			end
		end
		return setmetatable({
			params = params,
			param = params,
		}, {
			__call = function(self, x, param1)
				return fn(x, param1 or defaultparam1)
			end
		})
	end

	local function with2params(fn, defaultparam1, defaultparam2)
		local function params(param1, param2)
			return function(x)
				return fn(x, param1, param2)
			end
		end
		return setmetatable({
			params = params,
			param = params,
		}, {
			__call = function(self, x, param1, param2)
				return fn(x, param1 or defaultparam1, param2 or defaultparam2)
			end
		})
	end

	function reader.bounce(t) return 4 * t * (1 - t) end
	function reader.tri(t) return 1 - abs(2 * t - 1) end
	function reader.bell(t) return inOutQuint(tri(t)) end
	function reader.pop(t) return 3.5 * (1 - t) * (1 - t) * sqrt(t) end
	function reader.tap(t) return 3.5 * t * t * sqrt(1 - t) end
	function reader.pulse(t) return t < .5 and tap(t * 2) or -pop(t * 2 - 1) end

	function reader.spike(t) return exp(-10 * abs(2 * t - 1)) end
	function reader.inverse(t) return t * t * (1 - t) * (1 - t) / (0.5 - t) end

	local function popElasticInternal(t, damp, count)
		return (1000 ^ -(t ^ damp) - 0.001) * sin(count * pi * t)
	end

	local function tapElasticInternal(t, damp, count)
		return (1000 ^ -((1 - t) ^ damp) - 0.001) * sin(count * pi * (1 - t))
	end

	local function pulseElasticInternal(t, damp, count)
		if t < .5 then
			return tapElasticInternal(t * 2, damp, count)
		else
			return -popElasticInternal(t * 2 - 1, damp, count)
		end
	end

	reader.popElastic = with2params(popElasticInternal, 1.4, 6)
	reader.tapElastic = with2params(tapElasticInternal, 1.4, 6)
	reader.pulseElastic = with2params(pulseElasticInternal, 1.4, 6)

	reader.impulse = with1param(function(t, damp)
		t = t ^ damp
		return t * (1000 ^ -t - 0.001) * 18.6
	end, 0.9)

	function reader.outElasticInternal(t, a, p)
		return a * pow(2, -10 * t) * sin((t - p / (2 * pi) * asin(1/a)) * 2 * pi / p) + 1
	end
	local function inElasticInternal(t, a, p)
		return 1 - outElasticInternal(1 - t, a, p)
	end
	function reader.inOutElasticInternal(t, a, p)
		return t < 0.5
			and  0.5 * inElasticInternal(t * 2, a, p)
			or  0.5 + 0.5 * outElasticInternal(t * 2 - 1, a, p)
	end

	reader.inElastic = with2params(inElasticInternal, 1, 0.3)
	reader.outElastic = with2params(outElasticInternal, 1, 0.3)
	reader.inOutElastic = with2params(inOutElasticInternal, 1, 0.3)

	function reader.inBackInternal(t, a) return t * t * (a * t + t - a) end
	function reader.outBackInternal(t, a) t = t - 1 return t * t * ((a + 1) * t + a) + 1 end
	function reader.inOutBackInternal(t, a)
		return t < 0.5
			and  0.5 * inBackInternal(t * 2, a)
			or  0.5 + 0.5 * outBackInternal(t * 2 - 1, a)
	end

	reader.inBack = with1param(inBackInternal, 1.70158)
	reader.outBack = with1param(outBackInternal, 1.70158)
	reader.inOutBack = with1param(inOutBackInternal, 1.70158)
end -- ease.xml

local copy = table.weak_clone
local update_command = noop
do
	local max_pn = 8 -- default: `8`
	local debug_print_applymodifier_input = false -- default: `false`
	local debug_print_mod_targets = false -- default: `false`
	---------------------
	-- DATA STRUCTURES --
	---------------------

	-- the table of eases/add/set
	local eases = {}

	-- the table of scheduled functions and perframes
	local funcs = {}

	-- auxilliary variables
	local auxes = {}

	-- the table of nodes
	local nodes = {}

	-- mod aliases
	local aliases = {}

	-- mods whose values have changed that need to be applied
	local touched_mods = {}
	for pn = 1, max_pn do
		touched_mods[pn] = {}
	end

	-- store the default values for every mod
	local default_mods = {}

	-- the default_mods table defaults to 0
	setmetatable(default_mods, {
		__index = function(self, i)
			self[i] = 0
			return 0
		end
	})

	local song = GAMESTATE:GetCurrentSong()

	---------------
	-- FUNCTIONS --
	---------------

	-- the `plr=` system
	local default_plr = {1, 2}

	-- for reading the `plr` variable from the xero environment
	-- without falling back to the global table
	local function get_plr()
		return reader.plr or default_plr
	end

	local banned_chars = {}
	string.gsub('\'\\{}(),;* ', '.', function(t) banned_chars[t] = true end)
	-- convert a mod to its lowercase dealiased name
	local function normalize_mod(name)
		if banned_chars[string.sub(name, 1, 1)] or banned_chars[string.sub(name, #name, #name)] then
			error(
				'You have a typo in your mod name. '..
				'You wrote \''..name..'\', but you probably meant '..
				'\''..string.gsub(name, '[\'\\{}(),;* ]', '')..'\''
			)
		end
		name = string.lower(name)
		return aliases[name] or name
	end

	-- ease {start, len, eas, percent, 'mod'}
	-- adds an ease to the ease table
	local function ease(self)
		self.n = #self

		if self[3](1) < 0.5 then
			self.transient = 1
		end
		if self.mode or self.m then
			self[2] = self[2] - self[1]
		end

		self.start_time = self.time and self[1] or song:GetElapsedTimeFromBeat(self[1])

		local plr = self.plr or get_plr()
		if type(plr) == 'table' then
			for _, plr in ipairs(plr) do
				local copy = copy(self)
				copy.plr = plr
				table.insert(eases, copy)
			end
		else
			self.plr = plr
			table.insert(eases, self)
		end

	end

	-- add {start, len, eas, percent, mod}
	-- adds an ease to the ease table
	local function add(self)
		self.relative = true
		ease(self)
	end

	-- set {start, percent, mod}
	-- adds a set to the ease table
	local function set(self)
		table.insert(self, 2, 0)
		table.insert(self, 3, instant)
		ease(self)
	end


	-- acc {start, percent, mod}
	-- adds a relative set to the ease table
	local function acc(self)
		self.relative = true
		table.insert(self, 2, 0)
		table.insert(self, 3, instant)
		ease(self)
	end

	-- reset {start, [len, eas], [exclude = {mod list}]}
	-- adds a reset to the ease table
	local function reset(self)
		self[2] = self[2] or 0
		self[3] = self[3] or instant
		self.reset = true
		if self.only then
			if type(self.only) == 'string' then
				self.only = {self.only}
			end
		else
			self.exclude = self.exclude or {}
			if type(self.exclude) == 'string' then
				self.exclude = {self.exclude}
			end
			local exclude = {}
			for _, v in ipairs(self.exclude) do
				exclude[v] = true
			end
			self.exclude = exclude
		end
		ease(self)
	end

	-- func helper for scheduling a function
	local function func_function(self)
		-- func {5, 'P1:xy', 2, 3}
		if type(self[2]) == 'string' then
			local args, syms = {}, {}
			for i = 1, #self - 2 do
				syms[i] = 'arg' .. i
				args[i] = self[i + 2]
			end
			local syms = table.concat(syms, ', ')
			local code = 'return function('..syms..') return function() '..self[2]..'('..syms..') end end'
			self[2] = melody(assert(loadstring(code, 'func_generated')))()(unpack(args))
			while self[3] do
				table.remove(self)
			end
		end
		self[2], self[3] = nil, self[2]
		local persist = self.persist
		if type(persist) == 'number' and self.mode then
			persist = persist - self[1]
		end
		if persist == false then
			persist = 0.5
		end
		if type(persist) == 'number' then
			local fn = self[3]
			local final_time = self[1] + persist
			self[3] = function(beat)
				if beat < final_time then
					fn(beat)
				end
			end
		end
		self.priority = (self.defer and -1 or 1) * table.getn(funcs)
		self.start_time = self.time and self[1] or song:GetElapsedTimeFromBeat(self[1])
		table.insert(funcs, self)
	end

	-- func helper for scheduling a perframe
	local function func_perframe(self, can_use_poptions)
		if can_use_poptions then
			self.mods = {}
			for pn = 1, max_pn do
				self.mods[pn] = {}
			end
		end
		self.priority = (self.defer and -1 or 1) * table.getn(funcs)
		self.start_time = self.time and self[1] or song:GetElapsedTimeFromBeat(self[1])
		table.insert(funcs, self)
	end

	-- func helper for function eases
	local function func_ease(self)
		-- use the mode to adjust len
		if self.mode or self.m then
			self[2] = self[2] - self[1]
		end
		local fn = table.remove(self)
		local eas = self[3]
		local start_percent = #self >= 5 and table.remove(self, 4) or 0
		local end_percent = #self >= 4 and table.remove(self, 4) or 1
		local end_beat = self[1] + self[2]

		if type(fn) == 'string' then
			fn = melody(assert(loadstring('return function(p) '..fn..'(p) end', 'func_generated')))()
		end

		self[3] = function(beat)
			local progress = (beat - self[1]) / self[2]
			fn(start_percent + (end_percent - start_percent) * eas(progress))
		end

		func_perframe(self)
		-- it's a function-ease variant, so make it persist
		if self.persist ~= false then
			func_function {
				end_beat,
				function()
					fn(end_percent)
				end,
				persist = self.persist,
				defer = self.defer,
				mode = self.mode
			}
		end
	end

	-- func dispatcher
	local function func(self)

		-- scheduled function variant
		if type(self[2]) == 'string' or #self == 2 then
			func_function(self)

		-- basic perframe variant
		elseif #self == 3 then
			func_perframe(self, true)

		-- function ease variant
		else
			func_ease(self)
		end
	end

	-- alias {'old', 'new'}
	-- aliases a mod
	local function alias(self)
		local a, b = self[1], self[2]
		a, b = string.lower(a), string.lower(b)
		aliases[a] = b
	end

	-- setdefault {percent, 'mod'}
	-- set the default value of a mod
	local function setdefault(self)
		for i = 1, #self, 2 do
			default_mods[self[i + 1]] = self[i]
		end
		return setdefault
	end

	-- aux {'mod'}
	-- mark a mod as an aux, which won't get sent to `ApplyModifiers`
	local function aux(self)
		if type(self) == 'string' then
			local v = self
			auxes[v] = true
		elseif type(self) == 'table' then
			for i = 1, #self do
				aux(self[i])
			end
		end
		return aux
	end

	-- node {'inputs', function(inputs) return outputs end, 'outputs'}
	-- create a listener that gets run whenever a mod value gets changed
	local function node(self)

		if type(self[2]) == 'number' then
			-- transform the shorthand into the full version
			local multipliers = {}
			local i = 2
			while self[i] do
				local amt = string.format('p * %f', table.remove(self, i) * 0.01)
				table.insert(multipliers, amt)
				i = i + 1
			end
			local ret = table.concat(multipliers, ', ')
			local code = 'return function(p) return '..ret..' end'
			local fn = loadstring(code, 'node_generated')()
			table.insert(self, 2, fn)
		end

		local i = 1
		local inputs = {}
		while type(self[i]) == 'string' do
			table.insert(inputs, self[i])
			i = i + 1
		end
		local fn = self[i]
		i = i + 1
		local out = {}
		while self[i] do
			table.insert(out, self[i])
			i = i + 1
		end
		local result = {inputs, out, fn}
		result.priority = (self.defer and -1 or 1) * table.getn(nodes)
		table.insert(nodes, result)
		return node
	end

	-- definemod{'mod', function(mod, pn) end}
	-- calls aux and node on the provided arguments
	local function definemod(self)
		local depth = 1 + (type(depth) == 'number' and depth or 0)
		local name = name or 'definemod'
		for i = 1, #self do
			if type(self[i]) ~= 'string' then
				break
			end
			aux(self[i])
		end
		node(self)
		return definemod
	end

	-------------
	-- RUNTIME --
	-------------

	-- mod targets are the values that the mod would be at if the current eases finished
	local targets = {}
	local targets_mt = {__index = default_mods}
	for pn = 1, max_pn do
		targets[pn] = setmetatable({}, targets_mt)
	end

	-- the live value of the current mods. Gets recomputed each frame
	local mods = {}
	local mods_mt = {}
	for pn = 1, max_pn do
		mods_mt[pn] = {__index = targets[pn]}
		mods[pn] = setmetatable({}, mods_mt[pn])
	end

	-- a stringbuilder of the modstring that is being applied
	local mod_buffer = {}
	for pn = 1, max_pn do
		mod_buffer[pn] = stringbuilder()
	end

	-- data structure for nodes
	local node_start = {}

	-- keep track of which players are awake
	local last_seen_awake = {}

	-- poptions table
	local poptions = {}
	local poptions_logging_target
	for pn = 1, max_pn do
		local pn = pn
		local mods_pn = mods[pn]
		local mt = {
			__index = function(self, k)
				return mods_pn[normalize_mod(k)]
			end,
			__newindex = function(self, k, v)
				k = normalize_mod(k)
				mods_pn[k] = v
				if v then
					poptions_logging_target[pn][k] = true
				end
			end,
		}
		poptions[pn] = setmetatable({}, mt)
	end

	local function touch_mod(mod, pn)
		-- run metatables to ensure that the mod gets applied this frame
		if pn then
			mods[pn][mod] = mods[pn][mod]
		else
			-- if no player is provided, run for every player
			for pn = 1, max_pn do
				touch_mod(mod, pn)
			end
		end
	end

	local function touch_all_mods(pn)
		for mod in pairs(default_mods) do
			touch_mod(mod)
		end
		if pn then
			for mod in pairs(targets[pn]) do
				touch_mod(mod, pn)
			end
		else
			for pn = 1, 8 do
				for mod in pairs(targets[pn]) do
					touch_mod(mod, pn)
				end
			end
		end
	end

	-- runs once during ScreenReadyCommand, after the user code is loaded
	-- sorts the mod tables so that things can be processed in order
	local function sort_tables()
		-- sort eases by their beat
		stable_sort(eases, function(a, b) return a.start_time < b.start_time end)

		-- sort the funcs by their beat and priority
		stable_sort(funcs, function(a, b)
			if a.start_time == b.start_time then
				local x, y = a.priority, b.priority
				return x * x * y < x * y * y
			else
				return a.start_time < b.start_time
			end
		end)

		-- sort the nodes by their priority
		stable_sort(nodes, function(a, b)
			local x, y = a.priority, b.priority
			return x * x * y < x * y * y
		end)
	end

	-- runs once during ScreenReadyCommand, after the user code is loaded
	-- replaces aliases with their respective mods
	local function resolve_aliases()
		-- ease
		for _, e in ipairs(eases) do
			for i = 5, e.n, 2 do
				e[i] = normalize_mod(e[i])
			end
			if e.exclude then
				local exclude = {}
				for k, v in pairs(e.exclude) do
					exclude[normalize_mod(k)] = v
				end
				e.exclude = exclude
			end
			if e.only then
				for i = 1, #e.only do
					e.only[i] = normalize_mod(e.only[i])
				end
			end
		end
		-- aux
		local old_auxes = copy(auxes)
		clear(auxes)
		for mod, _ in pairs(old_auxes) do
			auxes[normalize_mod(mod)] = true
		end
		-- node
		for _, node_entry in ipairs(nodes) do
			local input = node_entry[1]
			local output = node_entry[2]
			for i = 1, #input do input[i] = normalize_mod(input[i]) end
			for i = 1, #output do output[i] = normalize_mod(output[i]) end
		end
		-- default_mods
		local old_default_mods = copy(default_mods)
		clear(default_mods)
		for mod, percent in pairs(old_default_mods) do
			local normalized = normalize_mod(mod)
			default_mods[normalized] = percent
			for pn = 1, max_pn do
				touched_mods[pn][normalized] = true
			end
		end
	end

	-- runs once during ScreenReadyCommand
	local function compile_nodes()
		local terminators = {}
		for _, nd in ipairs(nodes) do
			for _, mod in ipairs(nd[2]) do
				terminators[mod] = true
			end
		end
		for k, _ in pairs(terminators) do
			table.insert(nodes, {{k}, {}, nil, nil, nil, nil, nil, true})
		end
		local start = node_start
		local locked = {}
		local last = {}
		for _, nd in ipairs(nodes) do
			-- struct node {
			--     list<string> inputs;
			--     list<string> out;
			--     lua_function fn;
			--     list<struct node> children;
			--     list<list<struct node>> parents; // the inner lists also have a [0] field that is a boolean
			--     lua_function real_fn;
			--     list<map<string, float>> outputs;
			--     bool terminator;
			--     int seen;
			-- }
			local terminator = nd[8]
			if not terminator then
				nd[4] = {} -- children
				nd[7] = {} -- outputs
				for pn = 1, max_pn do
					nd[7][pn] = {}
				end
			end
			nd[5] = {} -- parents
			local inputs = nd[1]
			local out = nd[2]
			local fn = nd[3]
			local parents = nd[5]
			local outputs = nd[7]
			local reverse_in = {}
			for i, v in ipairs(inputs) do
				reverse_in[v] = true
				start[v] = start[v] or {}
				parents[i] = {}
				if not start[v][locked] then
					table.insert(start[v], nd)
				end
				if start[v][locked] then
					parents[i][0] = true
				end
				for _, pre in ipairs(last[v] or {}) do
					table.insert(pre[4], nd)
					table.insert(parents[i], pre[7])
				end
			end
			for i, v in ipairs(out) do
				if reverse_in[v] then
					start[v][locked] = true
					last[v] = {nd}
				elseif not last[v] then
					last[v] = {nd}
				else
					table.insert(last[v], nd)
				end
			end

			local function escapestr(s)
				return '\'' .. string.gsub(s, '[\\\']', '\\%1') .. '\''
			end
			local function list(code, i, sep)
				if i ~= 1 then code(sep) end
			end

			local code = stringbuilder()
			local function emit_inputs()
				for i, mod in ipairs(inputs) do
					list(code, i, ',')
					for j = 1, #parents[i] do
						list(code, j, '+')
						code'parents['(i)']['(j)'][pn]['(escapestr(mod))']'
					end
					if not parents[i][0] then
						list(code, #parents[i] + 1, '+')
						code'mods[pn]['(escapestr(mod))']'
					end
				end
			end
			local function emit_outputs()
				for i, mod in ipairs(out) do
					list(code, i, ',')
					code'outputs[pn]['(escapestr(mod))']'
				end
				return out[1]
			end
			code
			'return function(outputs, parents, mods, fn)\n'
				'return function(pn)\n'
					if terminator then
						code'mods[pn]['(escapestr(inputs[1]))'] = ' emit_inputs() code'\n'
					else
						if emit_outputs() then code' = ' end code 'fn(' emit_inputs() code', pn)\n'
					end
					code
				'end\n'
			'end\n'

			local compiled = assert(loadstring(code:build(), 'node_generated'))()
			nd[6] = compiled(outputs, parents, mods, fn)
			if not terminator then
				for pn = 1, max_pn do
					nd[6](pn)
				end
			end
		end
		for mod, v in pairs(start) do
			v[locked] = nil
		end
	end

	local function disable_functions()
		ease = function() error('ease cannot be run after beat 0') end
		add = function() error('add cannot be run after beat 0') end
		func = function() error('func cannot be run after beat 0') end
		set = function() error('set cannot be run after beat 0') end
		acc = function() error('acc cannot be run after beat 0') end
		setdefault = function() error('setdefault cannot be run after beat 0') end
		reset = function() error('reset cannot be run after beat 0') end
		node = function() error('node cannot be run after beat 0') end
		definemod = function() error('definemod cannot be run after beat 0') end
		aux = function() error('aux cannot be run after beat 0') end
		alias = function() error('alias cannot be run after beat 0') end
	end

	local apply_modifiers = mod_do

	if debug_print_applymodifier_input then
		local old_apply_modifiers = apply_modifiers
		apply_modifiers = function(str, pn)
			if debug_print_applymodifier_input == true or debug_print_applymodifier_input < beat then
				print('PLAYER ' .. pn .. ': ' .. str)
				if debug_print_applymodifier_input ~= true then
					apply_modifiers = old_apply_modifiers
				end
			end
			GAMESTATE:ApplyModifiers(str, pn)
		end
	end

	local eases_index = 1
	local active_eases = {}


	local function run_eases(beat, time)
		-- {start_beat, len, ease, p0, m0, p1, m1, p2, m2, p3, m3}
		while eases_index <= #eases do
			local e = eases[eases_index]
			local measure = e.time and time or beat
			if measure < e[1] then break end
			local plr = e.plr
			if e.reset then
				if e.only then
					for _, mod in ipairs(e.only) do
						table.insert(e, default_mods[mod])
						table.insert(e, mod)
					end
				else
					for mod, percent in pairs(targets[plr]) do
						if not e.exclude[mod] and targets[plr][mod] ~= default_mods[mod] then
							table.insert(e, default_mods[mod])
							table.insert(e, mod)
						end
					end
				end
			end
			e.offset = e.transient and 0 or 1
			if not e.relative then
				for i = 4, e.n, 2 do
					local mod = e[i + 1]
					e[i] = e[i] - targets[plr][mod]
				end
			end
			if not e.transient then
				for i = 4, e.n, 2 do
					local mod = e[i + 1]
					targets[plr][mod] = targets[plr][mod] + e[i]
				end
			end
			table.insert(active_eases, e)
			eases_index = eases_index + 1
		end

		local active_eases_index = 1
		while active_eases_index <= #active_eases do
			local e = active_eases[active_eases_index]
			local plr = e.plr
			local measure = e.time and time or beat
			if measure < e[1] + e[2] then
				local e3 = e[3]((measure - e[1]) / e[2]) - e.offset
				for i = 4, e.n, 2 do
					local mod = e[i + 1]
					mods[plr][mod] = mods[plr][mod] + e3 * e[i]
				end
				active_eases_index = active_eases_index + 1
			else
				for i = 4, e.n, 2 do
					local mod = e[i + 1]
					touch_mod(mod, plr)
				end
				active_eases[active_eases_index] = table.remove(active_eases)
			end
		end
	end

	local funcs_index = 1
	local active_funcs = perframe_data_structure(function(a, b)
		local x, y = a.priority, b.priority
		return x * x * y < x * y * y
	end)
	local function run_funcs(beat, time)
		while funcs_index <= #funcs do
			local e = funcs[funcs_index]
			local measure = e.time and time or beat
			if measure < e[1] then break end
			if not e[2] then
				e[3](measure)
			elseif measure < e[1] + e[2] then
				active_funcs:add(e)
			end
			funcs_index = funcs_index + 1
		end

		while true do
			local e = active_funcs:next()
			if not e then break end
			local measure = e.time and time or beat
			if measure < e[1] + e[2] then
				poptions_logging_target = e.mods
				e[3](measure, poptions)
			else
				if e.mods then
					for pn = 1, max_pn do
						for mod, _ in pairs(e.mods[pn]) do
							touch_mod(mod, pn)
						end
					end
				end
				active_funcs:remove()
			end
		end
	end

	local seen = 1
	local active_nodes = {}
	local active_terminators = {}
	local propagateAll, propagate
	function propagateAll(nodes)
		if nodes then
			for _, nd in ipairs(nodes) do
				propagate(nd)
			end
		end
	end
	function propagate(nd)
		if nd[9] ~= seen then
			nd[9] = seen
			if nd[8] then
				table.insert(active_terminators, nd)
			else
				propagateAll(nd[4])
				table.insert(active_nodes, nd)
			end
		end
	end

	local function run_nodes()
		for pn = 1, max_pn do
			if mod_plr[pn] and mod_plr[pn]:IsAwake() then
				if not last_seen_awake[pn] then
					last_seen_awake[pn] = true
					for mod, percent in pairs(touched_mods[pn]) do
						touch_mod(mod, pn)
						touched_mods[pn][mod] = nil
					end
				end
				seen = seen + 1
				for k in pairs(mods[pn]) do
					-- identify all nodes to execute this frame
					propagateAll(node_start[k])
				end
				for i = 1, #active_nodes do
					-- run all the nodes
					table.remove(active_nodes)[6](pn)
				end
				for i = 1, #active_terminators do
					-- run all the nodes marked as 'terminator'
					table.remove(active_terminators)[6](pn)
				end
			else
				last_seen_awake[pn] = false
				for mod, percent in pairs(mods[pn]) do
					mods[pn][mod] = nil
					touched_mods[pn][mod] = true
				end
			end
		end
	end

	local function run_mods()
		for pn = 1, max_pn do
			if mod_plr[pn] and mod_plr[pn]:IsAwake() then
				local buffer = mod_buffer[pn]
				for mod, percent in pairs(mods[pn]) do
					if not auxes[mod] then
						buffer('*-1 '..percent..' '..mod)
					end
					mods[pn][mod] = nil
				end
				if buffer[1] then
					apply_modifiers(buffer:build(','), pn)
					buffer:clear()
				end
			end
		end
	end

	local function run_debug_print_mod_targets(beat)
		if debug_print_mod_targets then
			if debug_print_mod_targets == true or debug_print_mod_targets < beat then
				for pn = 1, max_pn do
					if mod_plr[pn] and mod_plr[pn]:IsAwake() then
						local outputs = {}
						local i = 0
						for k, v in pairs(targets[pn]) do
							if v ~= default_mods[k] then
								i = i + 1
								outputs[i] = tostring(k)..': '..tostring(v)
							end
						end
						print('Player '..pn..' at beat '..beat..' --> '..table.concat(outputs, ', '))
					end
				end
				debug_print_mod_targets = (debug_print_mod_targets == true)
			end
		end
	end

	local function screen_ready_command()
		sort_tables()
		resolve_aliases()
		compile_nodes()

		-- disable all the table inserters during runtime
		disable_functions()

		-- make sure nodes are up to date
		run_nodes()
		run_mods()
	end

	local oldtime = 0
	local setup = false
	local update_command2 = function(beat, time)
		run_eases(beat, time)
		run_funcs(beat, time)
		run_nodes()
		run_mods()
	end
	update_command = function()
		if not setup then
			screen_ready_command()
			setup = true
		end

		local beat = GAMESTATE:GetSongBeat()
		local time = get_song_time()

		-- don't run multiple times if the game hasn't 'ticked' yet
		if time == oldtime then return end
		oldtime = time

		-- self:hidden(1)

		-- if no errors have occurred, unhide self
		-- to make the update_command run again next frame
		-- self:hidden(0)

		-- change to pcall and disable update command on error -jaez
		local res, err = pcall( update_command2, beat, time )
		if not res then
			update_command = noop
		end

		run_debug_print_mod_targets(beat)
	end

	---------------------------------------------------------------------------------------
	mod_do('clearall')


	-- zoom
	aux 'zoom'
	node {
		'zoom', 'zoomx', 'zoomy',
		function(zoom, x, y)
			local m = zoom * 0.01
			return m * x, m * y
		end,
		'zoomx', 'zoomy',
		defer = true,
	}

	setdefault {
		100, 'zoom',
		100, 'zoomx',
		100, 'zoomy',
		100, 'zoomz',
	}

	setdefault {400, 'grain'}

	-- movex
	local function repeat8(a)
		return a, a, a, a, a, a, a, a
	end

	for _, a in ipairs {'x', 'y', 'z'} do
		definemod {
			'move' .. a,
			repeat8,
			'move'..a..'0', 'move'..a..'1', 'move'..a..'2', 'move'..a..'3',
			'move'..a..'4', 'move'..a..'5', 'move'..a..'6', 'move'..a..'7',
			defer = true,
		}
	end

	-- xmod
	setdefault {1, 'xmod'}
	definemod {
		'xmod', 'cmod',
		function(xmod, cmod, pn)
			if cmod == 0 then
				mod_buffer[pn](string.format('*-1 %fx', xmod))
			else
				mod_buffer[pn](string.format('*-1 %fx,*-1 c%f', xmod, cmod))
			end
		end,
		defer = true,
	}

	--------------------
	-- ERROR CHECKING --
	--------------------

	local function is_valid_ease(eas)
		local err = type(eas) ~= 'function' and (not getmetatable(eas) or not getmetatable(eas).__call)
		if not err then
			local result = eas(1)
			err = type(result) ~= 'number'
		end
		return not err
	end

	local function check_ease_errors(self, name)
		if type(self) ~= 'table' then
			return 'curly braces expected'
		end
		if type(self[1]) ~= 'number' then
			return 'beat missing'
		end
		local is_set = name == 'set' or name == 'acc'
		if not is_set then
			if type(self[2]) ~= 'number' then
				return 'len / end missing'
			end
			if not is_valid_ease(self[3]) then
				return 'invalid ease function'
			end
		end
		local i = is_set and 2 or 4
		while self[i] do
			if type(self[i]) ~= 'number' then
				return 'invalid mod percent'
			end
			if type(self[i + 1]) ~= 'string' then
				return 'invalid mod'
			end
			i = i + 2
		end
		local plr = self.plr or get_plr()
		if type(plr) ~= 'number' and type(plr) ~= 'table' then
			return 'invalid plr'
		end
	end

	local function check_reset_errors(self)
		if type(self) ~= 'table' then
			return 'curly braces expected'
		end
		if type(self[1]) ~= 'number' then
			return 'invalid beat number'
		end
		if self[2] and self[3] then
			if type(self[2]) ~= 'number' then
				return 'invalid length'
			end
			if not is_valid_ease(self[3]) then
				return 'invalid ease'
			end
		elseif self[2] or self[3] then
			return 'needs both length and ease'
		end
		if type(self.exclude) ~= 'nil' and type(self.exclude) ~= 'string' and type(self.exclude) ~= 'table' then
			return 'invalid `exclude=` value: ' .. tostring(self.exclude)
		end
		if type(self.only) ~= 'nil' and type(self.only) ~= 'string' and type(self.only) ~= 'table' then
			return 'invalid `only=` value: `' .. tostring(self.only)
		end
		if self.exclude and self.only then
			return 'exclude= and only= are mutually exclusive'
		end
	end

	local valid_func_signatures = {
		['number, function'] = true,
		['number, number, function'] = true,
		['number, number, ease, function'] = true,
		['number, number, ease, string'] = true,
		['number, number, ease, number, function'] = true,
		['number, number, ease, number, string'] = true,
		['number, number, ease, number, number, function'] = true,
		['number, number, ease, number, number, string'] = true,
		['number, string, ?'] = true,
	}

	local function check_func_errors(self)
		if type(self) ~= 'table' then
			return 'curly braces expected'
		end
		local types = stringbuilder()
		for i, v in ipairs(self) do
			types(type(v))
		end
		if #types >= 2 and types[2] == 'string' then
			types[3] = '?'
			while types[4] do
				table.remove(types, 4)
			end
		end
		if #types > 3 then
			if is_valid_ease(self[3]) then
				types[3] = 'ease'
			end
		end
		local signature = types:build(', ')
		if signature == 'number, number, function' and self.persist ~= nil then
			return 'persist is not supported for perframes'
		end
		if not valid_func_signatures[signature] then
			return 'something is wrong with your func'
		end
	end

	local function check_alias_errors(self)
		if type(self) ~= 'table' then
			return 'curly braces expected'
		end
		local a, b = self[1], self[2]
		if type(a) ~= 'string' then
			return 'argument 1 should be a string'
		end
		if type(b) ~= 'string' then
			return 'argument 2 should be a string'
		end
	end

	local function check_setdefault_errors(self)
		if type(self) ~= 'table' then
			return 'curly braces expected'
		end
		for i = 1, #self, 2 do
			if type(self[i]) ~= 'number' then
				return 'invalid mod percent'
			end
			if type(self[i + 1]) ~= 'string' then
				return 'invalid mod name'
			end
		end
	end

	local function check_aux_errrors(self, name)
		if type(self) ~= 'string' and type(self) ~= 'table' then
			return 'expecting curly braces'
		end
		if type(self) == 'table' then
			for i, v in ipairs(self) do
				if type(v) ~= 'string' then
					return 'invalid mod to aux: '.. tostring(v)
				end
			end
		end
	end

	local function check_node_errors(self)
		if type(self) ~= 'table' then
			return 'curly braces expected'
		end
		if type(self[2]) == 'number' then
			-- the shorthand version
			for i = 2, #self, 2 do
				if type(self[i]) ~= 'number' then
					return 'invalid mod percent'
				end
				if type(self[i + 1]) ~= 'string' then
					return 'invalid mod name'
				end
			end
		else
			-- the function form
			local i = 1
			while type(self[i]) == 'string' do
				i = i + 1
			end
			if i == 1 then
				return 'the first argument needs to be the mod name'
			end
			if type(self[i]) ~= 'function' then
				return 'mod definition expected'
			end
			i = i + 1
			while self[i] do
				if type(self[i]) ~= 'string' then
					return 'unexpected argument '..tostring(self[i])..', expected a string'
				end
				i = i + 1
			end
		end
	end

	-------------
	-- EXPORTS --
	-------------

	local function export(fn, check_errors, name)
		local function inner(self)
			local err = check_errors(self, name)
			if err then
				error(name..': '..err, 2)
			else
				fn(self)
			end
			return inner
		end
		reader[name] = inner
	end

	export(ease, check_ease_errors, 'ease')
	export(add, check_ease_errors, 'add')
	export(set, check_ease_errors, 'set')
	export(acc, check_ease_errors, 'acc')
	export(reset, check_reset_errors, 'reset')
	export(func, check_func_errors, 'func')
	export(alias, check_alias_errors, 'alias')
	export(setdefault, check_setdefault_errors, 'setdefault')
	export(aux, check_aux_errrors, 'aux')
	export(node, check_node_errors, 'node')
	export(definemod, check_node_errors, 'definemod')
	reader.get_plr = get_plr
	reader.touch_mod = touch_mod
	reader.touch_all_mods = touch_all_mods
end -- template.xml

------------------------------
-- insert modreader stuff here

return reader, {
    func = update_command,
    clear = false,
}