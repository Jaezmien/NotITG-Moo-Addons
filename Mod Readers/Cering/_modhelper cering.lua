local helper = {}

-- insert mod helper stuff here
-------------------------------

function helper.mod_insert(start, len, amp, mod, pn)
    table.insert(mods, {'mi', start, len, amp, mod, pn})
end

function helper.mod_ease(start, len, amp0, amp, mod, ease, pn)
    table.insert(mods, {'me', start, len, amp0, amp, mod, ease, pn})
end

function helper.mod_clear(start, list, pn)
    for i, v in pairs(list) do
        table.insert(mods, {'mi', start, 1, 0, v, pn})
    end
end

function helper.mod_perframe(start, en, fx)
    table.insert(mods_pf, {start, en, fx})
end

function helper.mod_message(start, msg, per)
    table.insert(mods_msg, {start, msg, per})
end

--aux easers--
function helper.aux_ease(start, len, amp0, amp, ease, actor, effect)
    local beat = GAMESTATE:GetSongBeat()
    local actual_ease = ease_convertion[ ease ]
    local ampappl = actual_ease(beat - start, amp0, amp - amp0, len)
    actor:cmd(effect..','..ampappl)
end

function helper.aux_smooth(start, len, amp0, amp, ease, actor, effect)
    local beat = GAMESTATE:GetSongBeat()
    local midp = (amp0 + amp) / 2
    if beat >= start and beat < start + len / 2 then
        helper.aux_ease(start, len / 2, amp0, midp, ease..'in', actor, effect)
    elseif beat >= start + len / 2 and beat < start + len then
        helper.aux_ease(start + len / 2, len / 2, midp, amp, ease..'out', actor, effect)
    end
end

function helper.aux_bounce(start, len, amp0, apex, ease, actor, effect)
    local beat = GAMESTATE:GetSongBeat()
    if beat >= start and beat < start + len / 2 then
        helper.aux_ease(start, len / 2, amp0, apex, ease..'out', actor, effect)
    elseif beat >= start + len / 2 and beat < start + len then
        helper.aux_ease(start + len / 2, len / 2, apex, amp0, ease..'in', actor, effect)
    end
end

-- where did CERiNG pull these functions (ref: Paqqin) ???? - Jaez --
function helper.mod_smooth(start, len, amp0, amp, mod, ease, pn)
    local beat = GAMESTATE:GetSongBeat()
    local midp = (amp0 + amp) / 2
    if beat >= start and beat < start + len / 2 then
        helper.mod_ease(start, len / 2, amp0, midp, mod, ease..'in', pn)
    elseif beat >= start + len / 2 and beat < start + len then
        helper.mod_ease(start + len / 2, len / 2, midp, amp, mod, ease..'out', pn)
    end
end

function helper.mod_bounce(start, len, amp0, apex, mod, ease, pn)
    local beat = GAMESTATE:GetSongBeat()
    if beat >= start and beat < start + len / 2 then
        helper.mod_ease(start, len / 2, amp0, apex, mod, ease..'out', pn)
    elseif beat >= start + len / 2 and beat < start + len then
        helper.mod_ease(start + len / 2, len / 2, apex, amp0, mod, ease..'in', pn)
    end
end
-------------------------------
-- insert mod helper stuff here

return helper