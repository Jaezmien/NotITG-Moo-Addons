local reader = {}

-- insert modreader stuff here
------------------------------

-- Note: This reader is based on commit f9a8a14 at https://github.com/XeroOl/notitg-mirin

local stable_sort = function() end
local perframe_data_structure = function() end
local stringbuilder = function () end
do
    local function insertion_sort(t, l, h, c)
		for i = l + 1, h do
			local k = l
			local v = t[i]
			for j = i, l + 1, -1 do
				if c(v, t[j - 1]) then
					t[j] = t[j - 1]
				else
					k = j
					break
				end
			end
			t[k] = v
		end
	end

	local function merge(t, b, l, m, h, c)
		if c(t[m], t[m + 1]) then
			return
		end
		local i, j, k
		i = 1
		for j = l, m do
			b[i] = t[j]
			i = i + 1
		end
		i, j, k = 1, m + 1, l
		while k < j and j <= h do
			if c(t[j], b[i]) then
				t[k] = t[j]
				j = j + 1
			else
				t[k] = b[i]
				i = i + 1
			end
			k = k + 1
		end
		for k = k, j - 1 do
			t[k] = b[i]
			i = i + 1
		end
	end

	local magic_number = 12

	local function merge_sort(t, b, l, h, c)
		if h - l < magic_number then
			insertion_sort(t, l, h, c)
		else
			local m = math.floor((l + h) / 2)
			merge_sort(t, b, l, m, c)
			merge_sort(t, b, m + 1, h, c)
			merge(t, b, l, m, h, c)
		end
	end

	local function default_comparator(a, b) return a < b end
	local function flip_comparator(c) return function(a, b) return c(b, a) end end

	stable_sort = function(t, c)
		if not t[2] then return t end
		c = c or default_comparator
		local n = t.n
		local b = {}
		b[math.floor((n + 1) / 2)] = t[1]
		merge_sort(t, b, 1, n, c)
		return t
	end

	local function add(self, obj)
		local stage = self.stage
		self.n = self.n + 1
		stage.n = stage.n + 1
		stage[stage.n] = obj
	end

	local function remove(self)
		local swap = self.swap
		swap[swap.n] = nil
		swap.n = swap.n - 1
		self.n = self.n - 1
	end

	local function next(self)
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

	perframe_data_structure = function(comparator)
		return {
			add = add,
			remove = remove,
			next = next,
			comparator = comparator or default_comparator,
			reverse_comparator = flip_comparator(comparator or default_comparator),
			stage = {n = 0},
			list = {n = 0},
			swap = {n = 0},
			n = 0,
		}
	end
	
	local stringbuilder_mt =  {
		__index = {
			build = table.concat,
			sep = function(self, sep)
				if self[1] then
					self(sep)
				end
			end,
		},
		__tostring = table.concat,
		__call = function(self, a)
			table.insert(self, tostring(a))
			return self
		end,
	}
	
	stringbuilder = function()
		return setmetatable({}, stringbuilder_mt)
	end
end -- std.xml

reader.plr = {1, 2}
local default_plr = {1, 2}

local function get_plr() return reader.plr or default_plr  end

local max_pn = 8
local function screen_error(output, depth, name)
    local depth = 3 + (type(depth) == 'number' and depth or 0)
    local _, err = pcall(error, type(name) == 'string' and (name .. ':' .. output) or output, depth)
    SCREENMAN:SystemMessage(err)
end
local function push(self, obj)
    self.n = self.n + 1
    self[self.n] = obj
end

local copy = table.weak_clone
local convert_ease
do
    local function cache(func)
		return setmetatable({}, {
			__index = function(self, k)
				self[k] = func(k)
				return self[k]
			end
		})
	end
	
	-- make a function cache its results from previous calls
	local function fncache(func)
		local cache = {}
		return function(arg)
			cache[arg] = cache[arg] or func(arg)
			return cache[arg]
		end
    end

    local abs, exp, pi, sin, sqrt = math.abs, math.exp, math.pi, math.sin, math.sqrt

    function reader.flip(fn) return function(x) return 1 - fn(x,0,1,1) end end
	reader.flip = fncache(reader.flip)
    
    function reader.bounce(t) return 4 * t * (1 - t) end
    function reader.tri(t) return 1 - abs(2 * t - 1) end
    function reader.bell(t) return inOutQuint(reader.tri(t),0,1,1) end
    function reader.pop(t) return 3.5 * (1 - t) * (1 - t) * sqrt(t) end
    function reader.tap(t) return 3.5 * t * t * sqrt(1 - t) end
    function reader.pulse(t) return t < .5 and reader.tap(t * 2) or -reader.pop(t * 2 - 1) end
    function reader.spike(t) return exp(-10 * abs(2 * t - 1)) end
    function reader.inverse(t) return t * t * (1 - t) * (1 - t) / (0.5 - t) end
	
	reader.popElastic = cache(function(damp)
		return cache(function(count)
			return function(t)
				return (1000 ^ -(t ^ damp) - 0.001) * sin(count * pi * t)
			end
		end)
	end)
	reader.tapElastic = cache(function(damp)
		return cache(function(count)
			return function(t)
				return (1000 ^ -((1 - t) ^ damp) - 0.001) * sin(count * pi * (1 - t))
			end
		end)
	end)
	reader.pulseElastic = cache(function(damp)
		return cache(function(count)
			local tap_e = reader.tapElastic[damp][count]
			local pop_e = reader.popElastic[damp][count]
			return function(t)
				return t > .5 and -pop_e(t * 2 - 1) or tap_e(t * 2)
			end
		end)
	end)
	reader.impulse = cache(function(damp)
		return function(t)
			t = t ^ damp
			return t * (1000 ^ -t - 0.001) * 18.6
		end
    end)

    function reader.instant() return 1 end

    local reverse_lookup = {
        [reader.flip] = reader.flip,
        [reader.popElastic] = reader.popElastic,
        [reader.tapElastic] = reader.tapElastic,
        [reader.pulseElastic] = reader.pulseElastic,
        [reader.impulse] = reader.pulseElastic,
        [reader.instant] = reader.instant,
    }
    
    convert_ease = function( e ) return reverse_lookup[e] or function( t ) return e( t, 0, 1, 1 ) end end
end

local aliases = {}
local reverse_aliases = {}
local function alias(self, depth, name)
    local depth = 1 + (type(depth) == 'number' and depth or 0)
    local name = name or 'alias'
    if type(self) ~= 'table' then
        screen_error('curly braces expected', depth, name)
        return alias
    end
    local a, b = self[1], self[2]
    if type(a) ~= 'string' then
        screen_error('unexpected argument 1', depth, name)
        return alias
    end
    if type(b) ~= 'string' then
        screen_error('unexpected argument 2', depth, name)
        return alias
    end
    a, b = string.lower(a), string.lower(b)
    -- TODO make alias logic clearer
    local collection = {a}
    while aliases[b] do
        if reverse_aliases[b] then
            for _, item in ipairs(reverse_aliases[b]) do
                table.insert(collection, item)
            end
            reverse_aliases[b] = nil
        end
        b = aliases[b]
    end
    reverse_aliases[b] = reverse_aliases[b] or {}
    for _, name in ipairs(collection) do
        aliases[name] = b
        table.insert(reverse_aliases[b], name)
    end
    return alias
end; reader.alias = alias
local function normalize_mod(name)
    name = string.lower(name)
    return aliases[name] or name
end

local eases = {n = 0}
local function ease(self, depth, name)
    local depth = 1 + (type(depth) == 'number' and depth or 0)
    local name = name or 'ease'
    if type(self) ~= 'table' then
        screen_error('curly braces expected', depth, name)
        return ease
    end
    if type(self[1]) ~= 'number' then
        screen_error('beat missing', depth, name)
        return ease
    end
    if type(self[2]) ~= 'number' then
        screen_error('len / end missing', depth, name)
        return ease
    end
    if type(self[3]) ~= 'function' then
        screen_error('invalid ease function', depth, name)
        return ease
    end
    local i = 4
    while self[i] do
        if type(self[i]) ~= 'number' then
            screen_error('invalid mod percent', depth, name)
            return ease
        end
        if type(self[i + 1]) ~= 'string' then
            screen_error('invalid mod', depth, name)
            return ease
        end
        i = i + 2
    end
    self.n = i - 1
    self[3] = convert_ease(self[3])
    local result = self[3](1)
    if type(result) ~= 'number' then
        screen_error('invalid ease function', depth, name)
        return ease
    end
    if result < 0.5 then
        self.transient = 1
    end
    if self.mode or self.m then
        self[2] = self[2] - self[1]
    end
    local plr = self.plr or get_plr()
    if type(plr) == 'number' then
        self.plr = plr
        push(eases, self)
    elseif type(plr) == 'table' then
        self.plr = nil
        for _, plr in ipairs(plr) do
            local copy = copy(self)
            copy.plr = plr
            push(eases, copy)
        end
    else
        screen_error('invalid plr', depth, name)
    end
    return ease
end; reader.ease = ease

local function add(self, depth, name)
    local depth = 1 + (type(depth) == 'number' and depth or 0)
    local name = name or 'add'
    self.relative = true
    ease(self, depth, name)
    return add
end; reader.add = add

local function instant() return 1 end
local function set(self, depth, name)
    local depth = 1 + (type(depth) == 'number' and depth or 0)
    local a, b, i = 0, instant, 2
    while a do
        a, self[i] = self[i], a
        b, self[i + 1] = self[i + 1], b
        i = i + 2
    end
    ease(self, depth, name)
    return set
end; reader.set = set

local funcs = { n = 0 }
local function func(self, depth, name)
    local name = name or 'func'
    local depth = 1 + (type(depth) == 'number' and depth or 0)
    if type(self) ~= 'table' then
        screen_error('curly braces expected', depth, name)
        return func
    end

    if self.mode or self.m then
        if type(self[2]) == 'number' then
            self[2] = self[2] - self[1]
        end
        if type(self.persist) == 'number' then
            self.persist = self.persist - self[1]
        end
    end

    local can_use_poptions = false
    local a, b, c, d, e, f = self[1], self[2], self[3], self[4], self[5], self[6]
    -- function ease, type 3
    if type(a) == 'number' and type(b) == 'number' and type(c) == 'function' and type(d) == 'number' and type(e) == 'number' and type(f) == 'function' then
        local eas = convert_ease(c)
        a, b, c = a, b, function(beat)
            f(d + (e - d) * eas((beat - a) / b))
        end
    -- function ease, type 2
    elseif type(a) == 'number' and type(b) == 'number' and type(c) == 'function' and type(d) == 'number' and type(e) == 'function' then
        local eas = convert_ease(c)
        a, b, c = a, b, function(beat)
            e(d * eas((beat - a) / b))
        end
    -- function ease, type 1
    elseif type(a) == 'number' and type(b) == 'number' and type(c) == 'function' and type(d) == 'function' then
        local eas = convert_ease(c)
        a, b, c = a, b, function(beat)
            d(eas((beat - a) / b))
        end
    -- perframe
    elseif type(a) == 'number' and type(b) == 'number' and type(c) == 'function' then
        a, b, c = a, b, convert_ease(c)
        can_use_poptions = true
    -- scheduling a message
    elseif type(a) == 'number' and type(b) == 'function' then
        a, b, c = a, nil, b
        local fn = c
        if self.persist ~= nil and self.persist ~= true then
            if self.persist == false then
                self.persist = 0.5
            end
            local len = self.persist
            c = function(beat)
                if beat < a + len then
                    fn(beat)
                end
            end
        end
    else
        screen_error('overload resolution failed: check argument types', depth, name)
        return func
    end
    self[1], self[2], self[3], self[4], self[5], self[6] = a, b, c, nil, nil, nil
    if can_use_poptions then
        self.mods = {}
        for pn = 1, max_pn do
            self.mods[pn] = {}
        end
    end
    push(funcs, self)
    if self.defer then
        self.priority = -funcs.n
    else
        self.priority = funcs.n
    end
    -- if it's a function-ease variant then make it persist
    if d then
        local end_beat = a + b
        func {end_beat, function() c(end_beat) end, persist = self.persist, defer = self.defer}
    end
    return func
end; reader.func = func

local auxes = {}
local function aux(self, depth, name)
    local depth = 1 + (type(depth) == 'number' and depth or 0)
    local name = name or 'aux'
    if type(self) == 'string' then
        local v = self
        auxes[v] = true
    elseif type(self) == 'table' then
        for i = 1, #self do
            aux(self[i], depth, name)
        end
    else
        screen_error('aux var name must be a string', depth, name)
    end
    return aux
end; reader.aux = aux

local nodes = {n = 0}
local node_start
local function node(self, depth, name)
    local depth = 1 + (type(depth) == 'number' and depth or 0)
    local name = name or 'node'
    if type(self) ~= 'table' then
        screen_error('curly braces expected', depth, name)
        return node
    end
    local i = 1
    local inputs = {}
    local reverse_in = {}
    while type(self[i]) == 'string' do
        table.insert(inputs, self[i])
        set({-9e9, 0, self[i]}, depth, name)
        i = i + 1
    end
    if i == 1 then
        screen_error('inputs to node expected', depth, name)
    end
    local fn = self[i]
    if type(fn) ~= 'function' then
        screen_error('node function expected', depth, name)
    end
    i = i + 1
    local out = {}
    while type(self[i]) == 'string' do
        table.insert(out, self[i])
        i = i + 1
    end
    local result = {inputs, out, fn}
    result.priority = self.defer and -nodes.n or nodes.n
    push(nodes, result)
    return node
end; reader.node = node

local mods = {}
local mod_buffer = stringbuilder()

local function compile_nodes()
    local terminators = {}
    for _, nd in ipairs(nodes) do
        for _, mod in ipairs(nd[2]) do
            terminators[mod] = true
        end
    end
    for k, _ in pairs(terminators) do
        push(nodes, {{k}, {}, nil, nil, nil, nil, nil, true})
    end
    local start = {}
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
        
        local compiled = assert(loadstring(code:build()))()
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
    node_start = start
end

local function resolve_aliases()
    -- ease
    for _, e in ipairs(eases) do
        for i = 5, e.n, 2 do e[i] = normalize_mod(e[i]) end
    end
    -- aux
    local new_auxes = {}
    for mod, _ in pairs(auxes) do
        new_auxes[normalize_mod(mod)] = true
    end
    auxes = new_auxes
    -- node
    for _, node_entry in ipairs(nodes) do
        local input = node_entry[1]
        local output = node_entry[2]
        for i = 1, #input do input[i] = normalize_mod(input[i]) end
        for i = 1, #output do output[i] = normalize_mod(output[i]) end
    end
end

--

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
set {-9e9, 100, 'zoom', 100, 'zoomx', 100, 'zoomy'}

-- movex
for _, a in ipairs {'x', 'y', 'z'} do
    aux {'move' .. a}
    node {
        'move' .. a,
        function(a)
            return a, a, a, a, a, a, a, a
        end,
        'move'..a..'0', 'move'..a..'1', 'move'..a..'2', 'move'..a..'3',
        'move'..a..'4', 'move'..a..'5', 'move'..a..'6', 'move'..a..'7',
        defer = true,
    }
end

-- xmod
aux 'xmod' 'cmod'
node {
    'xmod', 'cmod',
    function(xmod, cmod)
        if cmod == 0 then
            mod_buffer(string.format('*-1 %fx', xmod))
        else
            mod_buffer(string.format('*-1 %fx,*-1 c%f', xmod, cmod))
        end
    end,
    defer = true,
}
set {-9e9+1, 1, 'xmod'}

local targets_mt = {__index = function() return 0 end}

local targets = {}
for pn = 1, max_pn do
    targets[pn] = setmetatable({}, targets_mt)
end

local mods_mt = {}
for pn = 1, max_pn do
    mods_mt[pn] = {__index = targets[pn]}
end
-- defined earlier
local mods = mods
for pn = 1, max_pn do
    mods[pn] = setmetatable({}, mods_mt[pn])
end
local poptions = {}
local poptions_mt = {}
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
    poptions_mt[pn] = mt
    poptions[pn] = setmetatable({}, mt)
end

local eases_index = 1
local funcs_index = 1

local active_eases = {n = 0}
local active_funcs = perframe_data_structure(function(a, b)
    local x, y = a.priority, b.priority
    return x * x * y < x * y * y
end)

mod_do('clearall,*0 0x,*-1 overhead')
-- default eases
local apply_modifiers = mod_do

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

--

local oldbeat = 0
local setup = false
local update = function()
    if not setup then
        stable_sort(eases, function(a, b) return a[1] < b[1] end)
		stable_sort(funcs, function(a, b)
			if a[1] == b[1] then
				local x, y = a.priority, b.priority
				return x * x * y < x * y * y
			else
				return a[1] < b[1]
			end
		end)
		stable_sort(nodes, function(a, b)
			local x, y = a.priority, b.priority
			return x * x * y < x * y * y
		end)
		resolve_aliases()
        compile_nodes()

        setup = true
    end

    local beat = GAMESTATE:GetSongBeat()
	if beat == oldbeat then return end
    oldbeat = beat

    while eases_index <= eases.n and eases[eases_index][1] < beat do
        local e = eases[eases_index]
        local plr = e.plr
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
        push(active_eases, e)
        eases_index = eases_index + 1
    end

    local active_eases_index = 1
    while active_eases_index <= active_eases.n do
        local e = active_eases[active_eases_index]
        local plr = e.plr
        if beat < e[1] + e[2] then
            local e3 = e[3]((beat - e[1]) / e[2]) - e.offset
            for i = 4, e.n, 2 do
                local mod = e[i + 1]
                mods[plr][mod] = mods[plr][mod] + e3 * e[i]
            end
            active_eases_index = active_eases_index + 1
        else
            for i = 4, e.n, 2 do
                local mod = e[i + 1]
                mods[plr][mod] = mods[plr][mod] + 0
            end
            active_eases[active_eases_index] = active_eases[active_eases.n]
            active_eases[active_eases.n] = nil
            active_eases.n = active_eases.n - 1
        end
    end

    while funcs_index <= funcs.n and funcs[funcs_index][1] < beat do
        local e = funcs[funcs_index]
        if not e[2] then
            e[3](beat)
        elseif beat < e[1] + e[2] then
            active_funcs:add(e)
        end
        funcs_index = funcs_index + 1
    end

    while true do
        local e = active_funcs:next()
        if not e then break end
        if beat < e[1] + e[2] then
            poptions_logging_target = e.mods
            e[3](beat, poptions)
        else
            if e.mods then
                for pn = 1, max_pn do
                    for mod, _ in e.mods[pn] do
                        mods[pn][mod] = mods[pn][mod] + 0
                    end
                end
            end
            active_funcs:remove()
        end
    end

    for pn = 1, max_pn do
        if melody['P'..pn] and melody['P'..pn]:IsAwake() then
            mod_buffer = stringbuilder()
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
            for mod, percent in pairs(mods[pn]) do
                if not auxes[mod] then
                    mod_buffer('*-1 '..percent..' '..mod)
                end
                mods[pn][mod] = nil
            end
            if mod_buffer[1] then
                apply_modifiers(mod_buffer:build(','), pn)
            end
        end
    end
end

------------------------------
-- insert modreader stuff here

return reader, {
    func = update,
    clear = false,
}