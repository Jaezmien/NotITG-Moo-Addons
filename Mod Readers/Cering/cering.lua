local reader = {}

-- insert modreader stuff here
------------------------------

-- Note: This reader is based on Paqqin, Secret Satan

reader.init_modsp1 = ''
reader.init_modsp2 = ''
reader.npu = 2
reader.speed = 200

reader.mods = {}
reader.mods_pf = {}
reader.mods_msg = {}

--


reader.ease_convertion = {
    ['lin'] = linear,
}
for _,v in pairs({ 'Sine','Quad','Cube','Quart','Quint','Expo','Circ','Back','Elast' }) do
    local l = string.lower( v )
    reader.ease_convertion[ l..'in' ] = _G['in'..v]
    reader.ease_convertion[ l..'out' ] = _G['out'..v]
    reader.ease_convertion[ l..'s' ] = _G['inOut'..v]
    reader.ease_convertion[ l..'b' ] = _G['outIn'..v]
end

local function mod_parser(amp, mod)
    if not (string.find(mod, 'reverse') and amp == 100) then
        local ampappl = (mod == 'xmod' and amp..'x') or (mod == 'cmod' and 'C'..amp) or amp..' '..mod
        return '*-1 '..ampappl..', '
    else
        return '*-1 99.9999 '..mod..', '
    end
end

local atable = {}
local function mod_applier(amp, mod, pn)
    if pn then atable[pn + 1] = atable[pn + 1]..mod_parser(amp, mod)
    else atable[1] = atable[1]..mod_parser(amp, mod)
    end
end

--

local first_seen_beat = GAMESTATE:GetSongBeat()
local setup = false
local curaction = 1
local update = function()
    local beat = GAMESTATE:GetSongBeat()

    if not setup then
        for i = 1, reader.npu + 1 do table.insert(atable, '') end -- do this here instead :)
        
        local function compare1(a, b) return a[1] < b[1] end
        local function compare2(a, b) return a[2] < b[2] end
        if table.getn(reader.mods) > 1 then table.sort(reader.mods, compare2) end
        if table.getn(reader.mods_pf) > 1 then table.sort(reader.mods_pf, compare1) end
        if table.getn(reader.mods_msg) > 1 then table.sort(reader.mods_msg, compare1) end

        setup = true
    end

    local disable = false;

    if disable then return end
    if beat <= first_seen_beat + 0.1 then return end -- performance coding!! --

    --player mod resets--
    for i=1, reader.npu do
        -- mod_do( 'clearall', i )
        if reader['init_modsp'..i] then mod_do( reader['init_modsp'..i], i ) end
    end

    --cering's wacky all-in-one concat reader [v1912]--
    mod_do( '*-1 overhead, *-1 approachtype, *-1 dizzyholds, *-1 modtimer, *-1 stealthpastreceptors, *-1 no mini *-1 C'.. reader.speed )
    local expired = {}
    for i, v in pairs( reader.mods ) do
        if beat < v[2] then break
        elseif beat >= v[2] and beat <= v[2] + v[3] then
            if v[1] == 'mi' then
                if v and v[2] and v[3] and v[4] and v[5] then
                    mod_applier( v[4], v[5], v[6] )
                end
            elseif v[1] == 'me' then
                if v and v[2] and v[3] and v[4] and v[5] and v[6] and v[7] then
                    local ease = reader.ease_convertion[ v[7] ]
                    local amp = ease(beat - v[2], v[4], v[5] - v[4], v[3])
                    mod_applier(amp, v[6], v[8])
                end
            end
        elseif beat > v[2] + v[3] then table.insert( expired, i ) end
    end
    for i, v in pairs( expired ) do table.remove( reader.mods, v - i + 1 ) end
    for j = 0, reader.npu do
        local pn; if j ~= 0 then pn = j end
        mod_do( string.sub(atable[j + 1], 1, -3), pn)
        atable[ j + 1 ] = ''
    end

    --perframe reader--
    if table.getn( reader.mods_pf ) > 0 then
        for i=1, table.getn( reader.mods_pf ) do
            local a = reader.mods_pf[i]
            if beat > a[1] and beat < a[2] then a[3]( beat, delta_time ) end
        end
    end

    --actions table--
    while curaction <= table.getn(reader.mods_msg) and beat >= reader.mods_msg[curaction][1] do
        local msg = reader.mods_msg[ curaction ]
        if msg[3] or beat < msg[1] + 2 then
            if type(msg[2]) == 'function' then msg[2]()
            elseif type(msg[2]) == 'string' then MESSAGEMAN:Broadcast(msg[2])
            end
        end
        curaction = curaction + 1
    end
end

------------------------------
-- insert modreader stuff here

return reader, {
    func = update,
    clear = true
}