local function Plr(pn) return melody['P'..pn] end

init_modsp1 = '';
init_modsp2 = '';

local mi = mod_insert
local me = mod_ease
local ms = mod_smooth
local mb = mod_bounce
local mc = mod_clear
local mm = mod_message
local pf = mod_perframe
local ae = aux_ease
local as = aux_smooth
local ab = aux_bounce

-- format: { 'mi', beat_start, beat_end, mod_percentage, mod, pn (optional) }
--     or: { 'me', beat_start, beat_end, mod_start, mod_end, mod, ease, pn (optional) }
mods = {
    -- { 'mi', 0, 9e9, 100, 'beat' },
}

-- format: { beat_start, function/string }
mods_msg = {
    
}

-- format: { beat_start, beat_end, function }
mods_pf = {
    
}