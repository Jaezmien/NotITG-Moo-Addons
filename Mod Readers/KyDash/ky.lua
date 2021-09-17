local reader = {}

-- insert modreader stuff here
------------------------------

-- somehow this is more cursed than xero's reader - Jaez
-- Note: This is based on commit 6c8efa6 at https://github.com/KyDash/nitg-template

reader.init_mods = ''
reader.mods = {}

local max_players = 4
local available_players = {}

local last = GAMESTATE:GetSongBeat()
local first_seen_beat = GAMESTATE:GetSongBeat()

--

local default = {
	timing = 'len',
	player = {},
	ease = function(t, b, c, d) return c * t / d + b end,
}

for i = 1, max_players do table.insert(default.player, i) end

do
    local mods = reader.mods -- im lazy

    local function perframe(values, op)
        op.timing = op.timing or default.timing
        local beat_range = {values[1], values[2] + (op.timing == 'len' and values[1] or 0)} -- convert times to end
        op.func_args = op.func_args and (type(op.func_args) == 'table' and op.func_args or {op.func_args}) or {}
        table.insert(mods, {range = beat_range, func = 'perf', values[3]})
        if op.persist and first_seen_beat > beat_range[2] then
            if type(op.persist) == 'boolean' then op.persist = 9E9 end
            op.persist_timing = op.persist_timing or op.timing
            op.persist = (op.persist or 0.1) + (op.persist_timing == 'len' and values[2] or 0)
            local beat_range = {beat_range[2], beat_range[2]}
            local f = {values[3], op.func_if_persist}
            table.insert(mods, {range = beat_range, func = 'func', f, persist = op.persist, func_args = beat_range[2]})
        end
    end
    local function func(values, op)
        op.timing = op.timing or default.timing
        if op.persist and type(op.persist) == 'boolean' then op.persist = 9E9 end
        op.persist = (op.persist or 0.1) + (op.timing == 'len' and values[1] or 0)
        local beat_range = {values[1], values[1]}
        local f = {values[2], op.func_if_persist}
        table.insert(mods, {range = beat_range, func = 'func', f, persist = op.persist})
    end
    local function func_ease_r(values, op)
        op.timing = op.timing or default.timing
        op.ease = op.ease or default.ease
        local beat_range = {values[1], values[2] + (op.timing == 'len' and values[1] or 0)} -- convert times to end
        local percentages = {values[4], values[5]}
        op.args = op.args and (type(op.args) == 'table' and op.args or {op.args}) or {}
        op.func_args = op.func_args and (type(op.func_args) == 'table' and op.func_args or {op.func_args}) or {}
        table.insert(mods, {range = beat_range, func = 'perfease', percentage = percentages, func_args = op.func_args, args = op.args, ease = op.ease, values[3]})
        if op.persist and first_seen_beat > beat_range[2] then
            if type(op.persist) == 'boolean' then op.persist = 9E9 end
            op.persist_timing = op.persist_timing or op.timing
            op.persist = (op.persist or 0.1) + (op.persist_timing == 'len' and values[2] or 0)
            local beat_range = {beat_range[2], beat_range[2]}
            local f = {values[3], op.func_if_persist}
            table.insert(mods, {range = beat_range, func = 'func', f, persist = op.persist, func_args = {beat = values[2], value = percentages[2]}})
        end
        if op.sustain then
            op.sustain_timing = op.sustain_timing or op.timing
            local beat_range = {values[2] + (op.timing == 'len' and values[1] or 0), op.sustain + (op.sustain_timing == 'len' and (values[2] + (op.timing == 'len' and values[1] or 0)) or 0)}
            local f = {values[3]}
            table.insert(mods, {range = beat_range, func = 'func', f, func_args = {beat = values[2], value = percentages[2]}})
        end
    end
    local function func_ease(values, op)
        -- 10 / 10 function
        -- would write again
        values[3], values[4], values[5] = values[5], values[3], values[4] -- swap values
        func_ease_r(values, op)
    end
    local function s_mod(values, op)
        op.timing = op.timing or default.timing
        op.pn = op.pn and (type(op.pn) == 'table' and op.pn or {op.pn}) or default.player
        local NOT_flag = op.pn[1] < 0
        if NOT_flag then
            local temp = {}
            for i = 1, max_players do
                table.insert(temp, i)
            end
            for i, v in ipairs(op.pn) do
                if v >= 0 then
                    print('Invalid player config', values, op)
                    return
                end
                table.remove(temp, math.abs(v))
            end
            op.pn = temp
        end
        local beat_range = {values[1], values[2] + (op.timing == 'len' and values[1] or 0)} -- convert times to end
        local mod = values[3]
        for k, v in ipairs(op.pn) do
            table.insert(mods, {range = beat_range, player = v, func = 'mod', mod})
        end
    end
    local function s_mod_once(values, op)
        op.timing = op.timing or default.timing
        op.pn = op.pn and (type(op.pn) == 'table' and op.pn or {op.pn}) or default.player
        local NOT_flag = op.pn[1] < 0
        if NOT_flag then
            local temp = {}
            for i = 1, max_players do
                table.insert(temp, i)
            end
            for i, v in ipairs(op.pn) do
                if v >= 0 then
                    print('Invalid player config', values, op)
                    return
                end
                table.remove(temp, math.abs(v))
            end
            op.pn = temp
        end
        local beat_range = {values[1], values[1]}
        local mod = values[2]
        for k, v in ipairs(op.pn) do
            table.insert(mods, {range = beat_range, player = v, func = 'mod', mod})
        end
    end
    local function ease_r(values, op)
        op.timing = op.timing or default.timing
        op.pn = op.pn and (type(op.pn) == 'table' and op.pn or {op.pn}) or default.player
        local NOT_flag = op.pn[1] < 0
        if NOT_flag then
            local temp = {}
            for i = 1, max_players do
                table.insert(temp, i)
            end
            for i, v in ipairs(op.pn) do
                if v >= 0 then
                    print('Invalid player config', values, op)
                    return
                end
                table.remove(temp, math.abs(v))
            end
            op.pn = temp
        end
        op.ease = op.ease or default.ease
        local beat_range = {values[1], values[2] + (op.timing == 'len' and values[1] or 0)} -- convert times to end
        local mod = values[3]
        local percentages = {values[4], values[5]}
        op.args = op.args and (type(op.args) == 'table' and op.args or {op.args}) or {} 
        for k, v in ipairs(op.pn) do
            table.insert(mods, {range = beat_range, player = v, func = 'ease', percentage = percentages, args = op.args, ease = op.ease, mod})
        end
        if op.sustain then
            op.sustain_timing = op.sustain_timing or op.timing
            local beat_range = {values[2] + (op.timing == 'len' and values[1] or 0), op.sustain + (op.sustain_timing == 'len' and (values[2] + (op.timing == 'len' and values[1] or 0)) or 0)}
            for k, v in ipairs(op.pn) do
                local mod = (mod == 'xmod' and percentages[2] .. 'x') or (mod == 'cmod' and 'c' .. percentages[2]) or percentages[2] .. ' ' .. mod
                table.insert(mods, {range = beat_range, player = v, func = 'mod', '*-1 ' .. mod})
            end
        end
    end
    local function ease(values, op)
        -- 10 / 10 function
        -- would write again
        values[3], values[4], values[5] = values[5], values[3], values[4] -- swap values
        ease_r(values, op)
    end

    local valid_inserts = {
        {'number', 'number', 'function', timing = 'string', persist = {'boolean', 'number'}, func_if_persist = 'function', persist_timing = 'string', func_args = {'number', 'string', 'function', 'table', 'userdata'}, ret = perframe}, -- perframe
        {'number', 'function', timing = 'string', persist = {'boolean', 'number'}, func_if_persist = 'function', func_args = {'number', 'string', 'function', 'table', 'userdata'}, ret = func}, -- func
        {'number', 'number', 'number', 'number', 'function', timing = 'string', ease = 'function', persist = {'boolean', 'number'}, func_if_persist = 'function', persist_timing = 'string', args = {'number', 'string', 'function', 'table'}, func_args = {'number', 'string', 'function', 'table', 'userdata'}, sustain = 'number', sustain_timing = 'string', ret = func_ease}, -- func ease
        {'number', 'number', 'function', 'number', 'number', timing = 'string', ease = 'function', persist = {'boolean', 'number'}, func_if_persist = 'function', persist_timing = 'string', args = {'number', 'string', 'function', 'table'}, func_args = {'number', 'string', 'function', 'table', 'userdata'}, sustain = 'number', sustain_timing = 'string', ret = func_ease_r}, -- func ease
        {'number', 'number', 'string', timing = 'string', pn = {'table', 'number'}, ret = s_mod}, -- mod
        {'number', 'string', pn = {'table', 'number'}, ret = s_mod_once}, -- mod

        {'number', 'number', 'number', 'number', 'string', timing = 'string', ease = 'function', pn = {'table', 'number'}, sustain = 'number', sustain_timing = 'string', args = {'number', 'string', 'function', 'table'}, ret = ease}, -- ease mod
        {'number', 'number', 'string', 'number', 'number', timing = 'string', ease = 'function', pn = {'table', 'number'}, sustain = 'number', sustain_timing = 'string', args = {'number', 'string', 'function', 'table'}, ret = ease_r}, -- another ease mod
    }
    local function validate(data) -- contains mod data that will be passed into a function dependand on it's need
        if type(data) == 'table' then -- make sure we're dealing with a table to begin with
            for _, which in ipairs(valid_inserts) do -- run through a list of valid templates
                local final = table.getn(data) -- size of the non optional information a mod call has passed in
                local valid_values = {} -- store the valid information to pass in the return value of the current template
                for pos, value in ipairs(data) do -- run through the data passed in
                    if type(value) == which[pos] then -- check if the value type matches what is expected for the current template
                        valid_values[pos] = value -- value at position matches
                    else
                        break -- otherwise move on to chack the next valid template
                    end
                    if pos == final then -- if we successfully run through the required types
                        local optional_values = {} -- move on to optional values that can be used
                        if which.aliases then -- if we create shorthandles for this entry
                            for shorthand, aliases_to in pairs(which.aliases) do -- link up shorthandles to an optional entry
                                if data[shorthand] then
                                    data[aliases_to] = data[shorthand]
                                end
                            end
                        end
                        for opt_pos, opt_value in pairs(data) do
                            if type(opt_pos) ~= 'number' then -- don't recheck required values, as they are already valid
                                if type(which[opt_pos]) == 'table' then -- if our optional value is a table, run through the data possibilities
                                    for _, opt_type in ipairs(which[opt_pos]) do
                                        if type(opt_value) == opt_type then -- if the optional type is a valid type
                                            optional_values[opt_pos] = opt_value -- add it in to the list of optional values
                                            break
                                        end
                                    end
                                else
                                    if type(opt_value) == which[opt_pos] then -- validate if there can only be a single valid type
                                        optional_values[opt_pos] = opt_value
                                    end
                                end
                            end
                        end
                        local r, err = pcall(which.ret, valid_values, optional_values)
                        if not r then
                            error(err, 3)
                        end
                        return
                    end
                end
            end
            error('Invalid entry: ' .. print(data), 3)
        else
            error('Not a table', 3)
        end
    end

    function reader.mod(data)
        validate(data)
        return reader.mod
    end

end

local str = {}

local addmods = function( string, player )
    if string == '' then return end
    if not player then
        for i = 1, max_players do
            addmods( string, i )
        end
        return
    end
    if str[player] then table.insert( str[player], string )
    else str[player] = { string } end
end
local apply = addmods

local applymods = function()
    for pn = 1, max_players do
		if str[pn] then
			if melody['P'..pn]:IsAwake() then mod_do(table.concat(str[pn], ', '), available_players[pn]) end
			str[pn] = nil
		end
	end
end

local add = {
    mod = function(a, b)
		if first_seen_beat > a.range[2] then return end
		addmods(a[1], a.player)
    end,

	func = function(a, b)
		if a.persist and first_seen_beat > a.range[2] and first_seen_beat < a.persist then
			local func = a[1][2] or a[1][1]
			func(a.func_args)
		else
			if first_seen_beat > a.range[2] then return end
			a[1][1](a.func_args)
		end
    end,

	perf = function(a, b)
		if first_seen_beat > a.range[2] then return end
		a[1](b, a.func_args)
    end,

	ease = function(a, b)
		if first_seen_beat > a.range[2] then return end
		local duration = a.range[2] - a.range[1]
		local time = math.min(b, a.range[2]) - a.range[1]
		local percent = a.ease(time, a.percentage[1], a.percentage[2] - a.percentage[1], duration, unpack(a.args))
		local mod = (a[1] == 'xmod' and percent .. 'x') or (a[1] == 'cmod' and 'c' .. percent) or percent .. ' ' .. a[1]
		addmods('*-1 ' .. mod, a.player)
    end,
 
	perfease = function(a, b)
		if first_seen_beat > a.range[2] then return end
		local duration = a.range[2] - a.range[1]
		local time = math.min(b, a.range[2]) - a.range[1]
		local percent = a.ease(time, a.percentage[1], a.percentage[2] - a.percentage[1], duration, unpack(a.args))
		a[1]({value = percent, beat = b}, a.func_args)
	end
}

local update = function() -- actually run()
    local beat = GAMESTATE:GetSongBeat()
    if beat == last then return end

    for k, v in pairs( reader.mods ) do
        if v.func ~= 'func' and first_seen_beat > v.range[2] then reader.mods[ k ] = nil end
        if beat >= v.range[1] then
            add[ v.func ]( v, beat )
            v.persist = nil
        end
        if beat > v.range[2] and beat > (v.persist or 0) then reader.mods[ k ] = nil end
        if reader.mods[k + 1] and beat < reader.mods[k + 1].range[1] then break end
    end

    applymods()
    last = beat
end
local set = function()
    for pn = 1, 2 do
		if SCREENMAN:GetTopScreen():GetChild('PlayerP' .. pn) then
			for i = pn, 8, 2 do table.insert(available_players, i) end
		end
	end
    table.sort(available_players)

    for i, v in pairs(reader.mods) do
		v.iter = i
    end

    table.sort(reader.mods, function(a, b) return a.range[1] == b.range[1] and (a.iter < b.iter) or (a.range[1] < b.range[1]) end)
end

------------------------------
-- insert modreader stuff here

set()
return reader, {
    func = update,
    clear = true,
}