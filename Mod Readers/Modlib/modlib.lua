local reader = {}

-- insert modreader stuff here
------------------------------

-- Note: This reader is based on It's a Trap, Mod Rush 1

r = {}

--

do

    local debug = false

    local noop = function() return "" end

    local current = {{}, {}}
    local tweening = {{}, {}}
    local last = -1
    local song

    local mods = {}
    local _modproxy = {
        __newindex = function(tbl, key, value)
            -- clear a call in the mods table
            if not value then
                mods[key] = nil
                return
            end
            -- wrap functions in a one-item table
            if type(value) ~= "table" then value = {value} end
            -- concatenate tables if reassigning
            if mods[key] then
                for _, item in ipairs(value) do
                    table.insert(mods[key], item)
                end
            else
                mods[key] = value
            end
        end
    }
    setmetatable(_modproxy, _modproxy)

    local function _apply_mod(name, value, player, transition, from_tween)
        --[[
        Create a mod command to run imminently.  Will cancel any existing tween on that mod.
  
        Transition time is adjusted such that the change from the current to desired value takes that
        amount of time.  Updates the `current` table with the new value.
  
        Args:
           name (string): mod name
           value (number): new decimal value (1 = 100%)
           player (number): `1` or `2`
           transition (number): number of beats to spend linearly increasing the value
  
        Returns:
           string: mod command
        ]] --
        if not from_tween then tweening[player][name] = nil end
        local factor = math.abs(value - (current[player][name] or 0))
        if factor == 0 then return end
        current[player][name] = value
        value = value == 0 and "no" or tostring(value * 100) .. "%"
        local speed = 10000
        if transition and transition > 0 then
            speed = factor * 2 / transition
        end
        return "*" .. tostring(speed) .. " " .. value .. " " .. name
    end

    local function _tween_mod(name, value, start, player, transition, func, ...)
        --[[
        Queue a new tweened mod command, to be handled by the update loop.  Will replace any existing
        tween on that mod.
  
        Args:
           name (string): mod name
           value (number): new decimal value (1 = 100%)
           start (number): initial beat
           player (number): `1` or `2`
           transition (number): number of beats to spend tweening the value
           func (function(pos, ...)): easing function to calculate the transitional values
              pos: progress through the ease, between 0 and 1
           ...: additional arguments to pass through to `func`
        ]] --
        local initial = current[player][name] or 0
        tweening[player][name] = {convert_ease(func), start, initial, value, transition, arg}
        if debug then
            SCREENMAN:SystemMessage(tostring(start) .. "T/" .. player .. ": " ..
                                        name .. " " .. tostring(initial) ..
                                        " -> " .. tostring(value))
        end
    end

    local function mod(name, value, transition, tween, ...)
        --[[
        Public entrypoint to applying a new basic mod.
  
        Args:
           name (string): mod name
           value (number): new decimal value (1 = 100%)
           transition (number): number of beats to spend linearly increasing the value
           tween (function): easing function to tween the transition (see `_tween_mod()`)
           ...: additional arguments to `tween`
  
        Returns:
           function(start, player): deferred function to apply the mod at the desired start time
              start (number): beat at which the mod is applied to
              player (number): `1` or `2`
        ]] --
        if tween and transition and transition > 0 then
            return function(start, player)
                return _tween_mod(name, value, start, player, transition, tween,
                                  unpack(arg))
            end
        else
            return function(start, player)
                return _apply_mod(name, value, player, transition)
            end
        end
    end

    local function mod_dual(name, p1value, p2value, transition, tween, ...)
        --[[
        Apply a mod using different values for players 1 and 2.  Use a `nil` value to skip a player.
  
        Args:
           name (string): mod name
           p1value (number): new decimal value
           p2value (number): new decimal value
           transition (number): number of beats to spend linearly increasing the value
           tween (function): easing function to tween the transition (see `_tween_mod()`)
           ...: additional arguments to `tween`
  
        Returns:
           function(start, player): deferred function to apply the mod at the desired start time
              start (number): beat at which the mod is applied to
              player (number): `1` or `2`
        ]] --
        if tween and transition and transition > 0 then
            return function(start, player)
                if player == 1 and p1value then
                    return _tween_mod(name, p1value, start, 1, transition,
                                      tween, unpack(arg))
                elseif player == 2 and p2value then
                    return _tween_mod(name, p2value, start, 2, transition,
                                      tween, unpack(arg))
                end
            end
        else
            return function(start, player)
                if player == 1 and p1value then
                    return _apply_mod(name, p1value, 1, transition)
                elseif player == 2 and p2value then
                    return _apply_mod(name, p2value, 2, transition)
                end
            end
        end
    end

    local function mod_table(values, ...)
        --[[
        Apply​ multiple mods with the same transition.
  
        Args:
           values (table): mapping from mod name to new value
           ...: additional arguments to `mod()`, starting with `transition`
  
        Returns:
           table: combined mod function calls
        ]] --
        local moves = {}
        for name, value in pairs(values) do
            table.insert(moves, mod(name, value, unpack(arg)))
        end
        return moves
    end

    local function move_x(lr, du, ...)
        --[[
        Move receptors to the left or right, using flip/invert mods.
  
        A value of 1 corresponds to the arrow width.
  
        Args:
           lr (number): relative position of ← and →
           du (number): relative position of ↓ and ↑
           ...: additional arguments to `mod()` (see `mod_table()`)
        ]] --
        return mod_table({flip = (lr + du) / 4, invert = (lr - 3 * du) / 4},
                         unpack(arg))
    end

    local function move_y(l, d, u, r, ...)
        --[[
        Move individual receptors up or down, using split/cross/alternate/reverse mods.
  
        A value of 1 corresponds to the arrow height.
  
        Args:
           l (number): relative position of ←
           d (number): relative position of ↓
           u (number): relative position of ↑
           r (number): relative position of →
           ...: additional arguments to `mod()` (see `mod_table()`)
        ]] --
        return mod_table({
            split = (-l - d + u + r) / 8,
            cross = (-l + d + u - r) / 8,
            alternate = (-l + d - u + r) / 8,
            reverse = l / 4
        }, unpack(arg))
    end

    local function set(input)
        --[[
        Load an existing table of mods.
  
        Args:
           input (table): beat->mod mapping
        ]] --
        for k, v in pairs(input) do _modproxy[k] = v end
    end

    local function update(beat)
        --[[
        Entrypoint for per-frame application of mods.
  
        Args:
           beat (number): current beat in play
        ]] --
        beat = beat or GAMESTATE:GetSongBeat()
        song = song or GAMESTATE:GetCurrentSong()
        local elapsed = beat
        -- apply ongoing tweens
        for player = 1, 2 do
            for name, tween in pairs(tweening[player]) do
                local func, start, initial, value, transition, args =
                    unpack(tween)
                local ongoing = true
                if beat > start + transition then
                    ongoing = false
                else
                    local from = beat
                    local to = beat + transition
                    local input = (elapsed - from) / (to - from)
                    local output = func(input, unpack(args))
                    value = (value * output) + (initial * (1 - output))
                end
                local command = _apply_mod(name, value, player, 0, ongoing)
                if command then
                    GAMESTATE:ApplyGameCommand("mod," .. command, player)
                end
            end
        end
        -- apply mods due to run this step
        local active = {}
        for at, _ in pairs(mods) do
            if at <= beat and at > last then table.insert(active, at) end
        end
        table.sort(active)
        for _, at in ipairs(active) do
            last = at
            for i, func in ipairs(mods[at]) do
                for player = 1, 2 do
                    local ok, command = pcall(func, at, player)
                    if debug then
                        SCREENMAN:SystemMessage(
                            tostring(at) .. "#" .. i .. "/" .. player .. ": " ..
                                (command or "<no cmd>"))
                    end
                    -- function returned a command, apply it
                    if ok and command and command ~= "" then
                        GAMESTATE:ApplyGameCommand("mod," .. command, player)
                    end
                end
            end
        end
    end

    local function _build_shortcuts()
        --[[
        Create a proxy for looking up children of the top screen, to get named UI elements.
        ]] --
        local screen
        -- use a metatable to lookup actors on demand
        return setmetatable({}, {
            __index = function(tbl, key)
                if not screen then
                    screen = SCREENMAN:GetTopScreen()
                end
                local actor = screen:GetChild(key)
                -- cache the retrieved actor for future use
                tbl[key] = actor
                return actor
            end
        })
    end

    local function _build_easings()
        --[[
        Create a wrapper table for https://github.com/EmmanuelOga/easing, providing functions that
        take a single argument: progress through the ease, between 0 and 1.
  
        The imported easing functions take 4 timing arguments:
        - elapsed time
        - beginning (= 0)
        - change (= 1)
        - duration (= 1)
        ]] --
        --if not easing then return nil end
        -- use a metatable to generate methods on demand
        return setmetatable({}, {
            __index = function(tbl, key)
                local func = _G[key]
                if not func then return nil end
                local wrap = function(pos, ...)
                    return func(pos, 0, 1, 1, unpack(arg))
                end
                -- cache the generated function for future use
                tbl[key] = wrap
                return wrap
            end
        })
    end

    local mgr = {
        -- public API
        noop = noop,
        mod = mod,
        mod_dual = mod_dual,
        mod_table = mod_table,
        move_x = move_x,
        move_y = move_y,
        set = set,
        update = update,
        x = _build_shortcuts(),
        e = _build_easings(),
        -- private API
        _mods = mods,
        _current = current,
        _tweening = tweening,
        --
        __index = mods,
        __newindex = function(tbl, key, value)
            if type(key) ~= "number" then
                error("Read-only modmgr table")
            end
            _modproxy[key] = value
        end
    }
    setmetatable(mgr, mgr)

    reader.init = function(mods)
        local ok, msg = pcall(mods, mgr)
        if debug and not ok then SCREENMAN:SystemMessage("[modmgr] " .. msg) end
    end

end

local setup = false
local update = function()
    if not setup then
        r.ready()
        setup = true
    end
    r.mgr.update()
end

------------------------------
-- insert modreader stuff here

return reader, {
    func = update,
    clear = false
}