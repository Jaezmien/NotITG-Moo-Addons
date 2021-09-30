--[[

-- arbitrary functions:
    mgr[ 0.0 ] = function(start)
       SCREENMAN:SystemMessage("Test at beat " .. tostring(start))
    end
    -- applying a single mod:
    -- mod(name, decimal value, transition time [beats], easing function)
    mgr[ 3.75 ] = mgr.mod("invert", 1, 0.25)
    mgr[ 6.0 ] = mgr.mod("invert", 0, 0.25)
    -- multiple mods, as an array:
    -- instant if no transition specified
    mgr[ 8.0 ] = {mgr.mod("mini", 0),
                    mgr.mod("dizzy", 4)}
    -- alternatively, just assign more mods to the same beat
    mge[ 8.0 ] = mgr.mod("beat", 1)
    -- moving the receptors:
    -- move_y(l, d, u, r, speed) applies split/cross/alternate/reverse
    -- move_x(lr, du, speed) applies flip/invert
    -- each unit in value = half the arrow width/height
    mgr[ 15.75 ] = mgr.move_y( 2,  2,  0,  0, 0.25),
    mgr[ 17.75 ] = mgr.move_x(-1.5, -0.5, 2),

-- blocks and repeating sections:
    for i = 20, 32, 4 do
        mgr.set({
           -- with easing:
           [i    ] = mgr.mod("dizzy", 4, 2, mgr.e.inOutQuad)
           [i + 2] = mgr.mod("dizzy", 0),
        })
    end

-- misc
    mgr.mod_dual(mod, p1_value, p2_value, length, tween)

-- "how to apply?"
    modreader.modlib.init( lua{"fg/modlib mods", env=modreader.modlib} )

]]

return function (mgr)
    r.mgr = mgr
    r.var = {}
    r.ready = function() end
    --
    -- mgr[ 0 ] = mgr.mod("beat", 1, 0)
end