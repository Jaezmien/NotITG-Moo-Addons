local reader = {}

-- insert modreader stuff here
------------------------------

-- this mod reader is held on by toothpicks and glue please send help

local default_max_pn = version_minimum('V2') and 8 or 2
local pmod_layers = config.modreader.jaezmien.layers or 2
reader.apply_mods = true

local default_layer = 1
reader.set_default_layer = function( layer ) default_layer = math.clamp( layer, 1, pmod_layers ) end

local init = {}; for pn=1,default_max_pn do init[pn]={} end
setmetatable(init,{
	__newindex = function(t, k, v)
		if type(k)=='string' and type(v)=='number' then for pn=1,default_max_pn do init[pn][k]=v end
		elseif type(k)=='number' and type(v)=='table' then init[pn][ k ]=v; end
	end
})
reader.init = init
reader.init.overhead = 100
reader.init.xmod = 1

local min_pn = 1
local max_pn = default_max_pn
reader.set_default_pn = function(min,max)
	if type(min) == 'table' then max, min = min[2], min[1] end

	min = math.max( 1, min or 1 )
	max = math.min( default_max_pn, max or default_max_pn )

	min_pn, max_pn = min, max
end

local default = setmetatable({}, { __index = function() return 0 end })
local redirs = {}
local eases = {}
local ease_funcs = {}
local funcs = {}

-- Column-specific mod expansion
local expand_mods = { ['dark'] = true, ['reverse'] = true, ['dizzy'] = true, ['drunk'] = true, ['stealth'] = true }
for _, dir in ipairs({'x', 'y', 'z'}) do
	for _, m in ipairs({ 'confusionoffset', 'move' }) do expand_mods[ m..dir ] = true end
end

local _recalc_mods = {
	['dark'] = function(v) return 50 + (v / 100) * 50 end,
	['reverse'] = function(v) return v == 100 and 99.99 or v end,
	['confusionoffset'] = function(v) return v * math.pi / 1.8 end,
}
local find_recalc_mod = function(modname)
	if _recalc_mods[modname] then return _recalc_mods[modname] end
	local result, _, mod = string.find(modname, "(%a+[^xz])[0-7xyz]+")
	if result ~= nil and _recalc_mods[mod] then return _recalc_mods[ mod ] end
	return function(v) return v end
end
local recalc_mods = setmetatable( {},
	{
		__index = function(t, k)
			_recalc_mods[k] = _recalc_mods[k] or find_recalc_mod(k); return _recalc_mods[k]
		end,
	}
)

local setup = false

local function parse_mod( modname, modvalue, pn )
	modvalue = recalc_mods[ modname ]( modvalue )
	if redirs[ modname ] and type( redirs[ modname ] ) == 'function' then return redirs[ modname ]( modvalue, pn ) end
	return '*-1 ' .. modvalue ..' '.. modname
end
local function apply_mod( modstr, pn ) if modstr and reader.apply_mods then mod_do( modstr, pn ) end end
local function noop() end
local function create_pmod()
	local m = {} -- m[ pn ][ layer ][ mod ] = value

	for pn=1, default_max_pn do
		local pn=pn
		local p = {}

		for layer=1, pmod_layers do
			local mods = setmetatable( {}, { __index = function(_, k) return default[k] end, } )
			local handler = {}
			handler.get = function(_,k) return k and mods[k] or mods end
			handler.set = function(_,k,v) mods[k]=v end
			handler.clear = function() mods={}; handler.n=0 end
			handler.n = 0

			setmetatable(
				handler,
				{
					__index = function(_, mod) return mods[mod] end,
					__newindex = function(_, mod, val)
						local mod = string.lower( mod )
						if type(redirs[ mod ]) == 'string' then mod = redirs[mod] end
						if expand_mods[ mod ] then
							for c=0, 7 do local c = (OPENITG and 0 or 1) + c; _[ mod .. c ] = val; end
							return
						end
						if mods[ mod ] == val then return end
						
						local apply = val and val ~= default[ mod ]

						-- ew
						local rw = rawget( mods, mod )
						if not rw and apply then
							handler.n = handler.n + 1
							apply_mod( parse_mod(mod, val) )
						elseif rw and not apply then
							handler.n = handler.n - 1
							apply_mod( parse_mod(mod, default[mod]) )
						end

						mods[ mod ] = apply and val or nil
					end,
					__len = function(t) return t.n end, -- lua 5.2+
				}
			)

			p[ layer ] = handler
		end

		m[ pn ] = setmetatable(
			{},
			{
				__index = function(_, k)
					if type(k) == 'number' then return p[k] end
					if type(k) == 'string' then return p[default_layer][k] end
				end,
				__newindex = function(_, mod, val) p[ default_layer ][ mod ] = val end, -- pmod[ pn ][ mod ] = value
				__call = function(_, layer) return p[ layer ] end,
			}
		)
	end

	local m_cache = {}

	return setmetatable(
		{},
		{
			__index = function(_, pn) return m[ pn ] end, -- pmod[ pn ]
			__call = function(_, layer)
				m_cache[ layer ] = m_cache[ layer ] or setmetatable(
					{},
					{
						__newindex = function(_, mod, val)
							for pn=min_pn, max_pn do m[ pn ][ layer ][ mod ] = val end -- pmod( layer )[ mod ] = value
						end,
					}
				)
				return m_cache[ layer ]
			end, -- pmod( layer )
			__newindex = function(_, mod, val) for pn=min_pn, max_pn do m[ pn ][ default_layer ][ mod ] = val end end, -- pmod[ mod ] = value
		}
	)
end
--

local pmods = create_pmod()
local pmods_target = create_pmod() -- for ease

reader.pmods = {}
setmetatable( reader.pmods,
	{
		__index = pmods,
		__call = function(_, layer) return pmods(layer) end,
		__newindex = function(_, mod, val) pmods[mod]=val end,
	}
)

reader.default = {}
setmetatable(
	reader.default,
	{
		__index = function(_, k) return default[ string.lower(k) ] end,
		__newindex = function(_, k, v)
			if type(k) ~= 'string' or type(v) ~= 'number' then print("[Mods] Invalid default, ignoring..."); return end
			default[ string.lower(k) ] = v
		end,
		__call = function(t, args)
			if type(args) ~= 'table' then
				print("[Mods] Invalid default call, ignoring...")
			elseif type(args[1]) ~= 'string' or type(args[2]) ~= 'number' then
				print("[Mods] Invalid default, ignoring...")
			else
				default[ args[1] ] = args[2]
			end
			return t
		end,
	}
)
reader.default{'zoom', 100}{'zoomx', 100}{'zoomy', 100}{'zoomz', 100}{'grain', 400}

reader.redirs = {}
setmetatable(
	reader.redirs,
	{
		__index = function(t, k) return redirs[ string.lower(k) ] end,
		__newindex = function(t, k, v)
			if v == nil then v = noop end
			if type(k) ~= 'string' or (type(v) ~= 'function' and type(v) ~= 'string') then print("[Mods] Invalid redirs, ignoring..."); return end
			redirs[ string.lower(k) ] = v
		end,
		__call = function(t, args)
			if type(args) ~= 'table' then
				print("[Mods] Invalid redirs call, ignoring...")
			elseif type(args[1]) ~= 'string' or
				(type(args[2]) ~= 'string' and type(args[2]) ~= 'function' and type(args[2]) ~= 'nil') then
				print("[Mods] Invalid alias, ignoring...")
			else
				if args.col then
					for i=0,7 do
						local i = OPENITG and i or i + 1
						redirs[ args[1] .. i ] = args[2] or noop
					end
				else
					redirs[ args[1] ] = args[2] or noop
				end
			end
			return t
		end,
	}
)
reader.redirs{'xmod', function(v) return '*-1 '.. v ..'x' end}
{'cmod', function(v) return '*-1 c'.. v end}
{'noteskew', 'noteskewx'}
if not FUCK_EXE then
	reader.redirs{'rotationx', function(v,pn) mod_plr[pn]:rotationx( v ) end}
	{'rotationy', function(v,pn) mod_plr[pn]:rotationy( v ) end}
	{'rotationz', function(v,pn) mod_plr[pn]:rotationz( v ) end}
end
if not OPENITG then
	reader.redirs{'attenuate', 'attenuatex'}
	{'hideholds', 'stealthholds'}
	{'modtimer', 'modtimersong'}
	{'arrowpath', 'notepath'}
	{'arrowpathdrawsize', 'notepathdrawsize'}
	{'arrowpathdrawsizeback', 'notepathdrawsizeback'}
	{'centered2', 'centeredpath'}
end

reader.ease = {}
setmetatable(
	reader.ease,
	{
		__newindex = noop,
		__call = function(t, args)
			if type(args) ~= 'table' then print("[Mods] Invalid mod ease call, ignoring...") return t; end

			local el = {}
			el.beat_start = args[ 1 ]

			local index = 2
			if type( args[2] ) == 'number' and type( args[3] ) == 'function' then
				el.beat_length = args[ 2 ] > args[ 1 ] and args[ 2 ] - args[ 1 ] or args[ 2 ]
				el.ease = args[ 3 ]
				index = 4
			else
				el.beat_length = 0
				el.ease = linear
			end

			el.mods = {}
			local mod_value = 100
			while args[ index ] do
				local v = args[ index ]
				if type(v) == 'number' then
					mod_value = v
				elseif type(v) == 'string' then
					if expand_mods[ string.lower(v) ] then
						for c=0, 7 do local c = (OPENITG and 0 or 1) + c; el.mods[ string.lower(v) .. c ] = mod_value; end
					else
						el.mods[ string.lower(v) ] = mod_value
					end
				else
					print("[Mods] Invalid mod table, ignoring..."); return t
				end

				index = index + 1
			end

			el.layer = args.layer or default_layer

			args.plr = args.plr or args.pn
			
			if not args.plr then args.plr = {}; local i = 1; for pn=min_pn, max_pn do args.plr[i] = pn; i=i+1 end
			elseif args.plr and type( args.plr ) == 'number' then args.plr = { args.plr }
			end

			for _,pn in ipairs( args.plr ) do
				local _el = table.weak_clone( el )
				_el.plr = pn
				_el.index = table.getn( eases ) + 1
				table.insert( eases, _el )
			end

			return t
		end,
	}
)

reader.clear = {}
setmetatable(
	reader.clear,
	{
		__newindex = noop,
		__call = function(t, args)
			if type(args) ~= 'table' then print("[Mods] Invalid mod ease call, ignoring...") return t; end

			local el = {}
			el.beat_start = args[1]

			el.beat_length = 0
			el.ease = linear

			el.mods = {}
			
			el.layer = args.layer or default_layer
			el.clear = true

			args.plr = args.plr or args.pn
			
			if not args.plr then args.plr = {}; local i = 1; for pn=min_pn, max_pn do args.plr[i] = pn; i=i+1 end
			elseif args.plr and type( args.plr ) == 'number' then args.plr = { args.plr }
			end

			for _,pn in ipairs( args.plr ) do
				local _el = table.weak_clone( el )
				_el.plr = pn
				_el.index = table.getn( eases ) + 1
				table.insert( eases, _el )
			end

			return t
		end
	}
)

reader.easef = {}
setmetatable(
	reader.easef,
	{
		__newindex = noop,
		__call = function(t, args)
			if type(args) ~= 'table' then print("[Mods] Invalid function ease call, ignoring...") return t; end
			
			local el = {}
			el.beat_start = args[1]
			el.beat_length = args[2] > args[1] and args[2] - args[1] or args[2]

			el.range = { args[3], args[4] }
			el.func = args[5]
			el.ease = args[6] or linear

			table.insert( ease_funcs, el )
			return t
		end,
	}
)

reader.func = {}
setmetatable(
	reader.func,
	{
		__newindex = noop,
		__call = function(t, args)
			if type(args) ~= 'table' then print("[Mods] Invalid func call, ignoring...") return t; end
			
			local el = {}
			el.beat_start = args[1]

			if type(args[2]) == 'number' and type(args[3]) == 'function' then
				el.beat_length = args[2] > args[1] and args[2] - args[1] or args[2]
				el.func = args[3]
			elseif type(args[2] == 'function') then
				el.func = args[2]
				el.persist = args[3] or args.persist or false
			else
				print('[Mods] Invalid func, ignoring...'); return t
			end

			table.insert( funcs, el )
			return t
		end,
	}
)

-- Update

local last_seen_beat = GAMESTATE:GetSongBeat()
local last_seen_time = get_song_time()

reader.reset = function()
	eases, ease_funcs, funcs = {}, {}, {}
	for l=1, pmod_layers do for pn=1, default_max_pn do reader.pmods( l )[ pn ]:clear() end end
	setup = false
end

local function update()
	local beat = GAMESTATE:GetSongBeat()
	local time = get_song_time()
	if beat == last_seen_beat and time == last_seen_time then return end
	last_seen_beat, last_seen_time = beat, time

	if not setup then
		apply_mod( '*-1 clearall' )

		for pn, mods in ipairs( init ) do
			for mod, value in pairs( mods ) do
				if pmods[ pn]( 1 )[ mod ] ~= default[ mod ] then print("[Mods] Pmod " .. mod .. " will be overidden by init value") end
				pmods[ pn ]( 1 )[ mod ] = value
			end
		end

		table.sort( eases , function(x,y)
			if (x.beat_start == y.beat_start) then return x.index < y.index end -- oh well
			return (x.beat_start < y.beat_start)
		end )
		table.sort( ease_funcs , function(x,y) return (x.beat_start < y.beat_start) end )
		table.sort( funcs      , function(x,y) return (x.beat_start < y.beat_start) end )
		
		setup = true
	end

	-- Ease calculation
	for index,ease in pairs( eases ) do
		
		if beat < ease.beat_start then break end

		local core = pmods
		local target = pmods_target
		local layer = ease.layer
		local plr = ease.plr

		local mod_layer = core[ plr ][ layer ]
		local mod_layer_target = target[ plr ][ layer ]

		if not ease.set then

			if ease.clear then
				for mod,_ in pairs( mod_layer:get() ) do
					ease.mods[ mod ] = default[ mod ]
				end
				for mod, value in pairs( init[ plr ] ) do
					ease.mods[ mod ] = value
				end
			end

			for mod, value in pairs( ease.mods ) do
				mod_layer_target[ mod ] = mod_layer[ mod ] * ease.ease(1)
				ease.mods[ mod ] = value - mod_layer_target[ mod ]
				mod_layer_target[ mod ] = mod_layer_target[ mod ] + ease.mods[ mod ]
			end

			ease.set = true
		end

		--

		if ease.beat_length > 0 and beat < ease.beat_start + ease.beat_length then

			local mult = 1 - ease.ease( (beat - ease.beat_start) / ease.beat_length )
			for mod, value in pairs( ease.mods ) do
				mod_layer[ mod ] = mod_layer_target[ mod ] - (value * mult)
			end

		else

			for mod, value in pairs( ease.mods ) do
				mod_layer[ mod ] = mod_layer_target[ mod ] * ease.ease(1)
			end

			eases[ index ] = nil

		end

	end

	-- Functions
	for index, func in pairs( ease_funcs ) do
		
		if beat < func.beat_start then break end

		if beat < func.beat_start + func.beat_length then
			local percent = func.range[1] + func.ease( (beat - func.beat_start) / func.beat_length ) * ( func.range[2] - func.range[1] )
			func.func( percent )
		else
			func.func( func.range[2] )
			ease_funcs[ index ] = nil
		end

	end
	for index,func in pairs( funcs ) do

		if beat < func.beat_start then break end
		
		if func.beat_length then
			func.func( beat )
			if beat > func.beat_start + func.beat_length then
				funcs[ index ] = nil
			end
		else
			if beat <= func.beat_start+4 or (func.persist and beat <= func.persist) then
				if type(func.func) == 'string' then MESSAGEMAN:Broadcast( func.func )
				else func.func( beat )
				end
				funcs[ index ] = nil
			end
		end

	end

	-- Pmods application
	if reader.apply_mods then

		for pn=1, default_max_pn do
			local pn=pn
	
			-- Create mod table (mod => value)
			local mod_table = {}
			local active_mods = {}

			-- Iterate through layers
			for l=1, pmod_layers do
				local mod_layer = reader.pmods[ pn ]( l )
				if table.getn( mod_layer ) > 0 then
					for mod,value in pairs( mod_layer:get() ) do
						if not mod_table[ mod ] then active_mods[ table.getn(active_mods) + 1 ] = mod end
						mod_table[ mod ] = (mod_table[ mod ] or 0) + value
	
						if value == default[ mod ] then mod_layer:set( mod, nil ) end
					end
				end
			end
			
			-- Apply mod table
			if table.getn( active_mods ) > 0 then
				local mod_builder = {}

				-- Insert into mod builder
				for i = 1, table.getn( active_mods ) do
					local modname = active_mods[ i ]
					local modvalue = mod_table[ modname ]

					local modstr = parse_mod( modname, modvalue, pn )

					if modstr then table.insert( mod_builder, modstr ) end
				end

				local applystr = table.concat(mod_builder, ",")
				if applystr ~= "" then apply_mod( applystr, pn ) end
			end

		end

	end
end
------------------------------
-- insert modreader stuff here

return reader, {
	func = update,
	clear = false,
	disable = function() reader.apply_mods = false end,
}