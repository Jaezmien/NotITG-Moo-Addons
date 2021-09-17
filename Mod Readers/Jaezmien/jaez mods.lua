--[[
    Jaezmien's Wierd Mod Reader Syntax
    
    -------------------------------------------
    pmods, pmods_offset
    > These are tables that contain the player's current mods
    > You can do: `pmods[1].invert = 100` to apply invert to Player 1
    > Or, `pmods.flip = 100` to apply flip to all players*
    
    * Only in the default pn range
    -------------------------------------------
    redirs
    > This is a table that you can use to create a mod that uses a function
    > For example the `xmod` mod converts regular mod format into the proper XMod format.
    > You can also do the following:
    >   -- Create a redirect that, just applies flip for now
    >   redirs['flip_alternative'] = function(value,pn)
    >       return '*-1 '.. value ..' flip'
    >   end
    >   pmods.flip_alternative = 100 -- Applies `flip_alternative` to all players.
    >
    > There's also the alternative method:
    >   redirs{'mod name', function(value, player_number) (Optional)}

    -------------------------------------------
    ease, ease_offset
    > Eases a mod value to another value
    > Base Format:
    >   ease{ start_beat, length*, ease**, [mods]... }
    >
    > Mods Format:
    >   `new_value (optional), mod_string`. (Can be followed by more mods)
    >   The new value will be determined by the last seen number (default, 0)
    >       `200,' Drunk', 300, 'Tipsy'` will apply 200% Drunk and 300% Tipsy
    >       `100, 'invert', 'flip'` will apply 100% Invert and 100% Flip
    >   There's also optional parameters:
    >       `extra` (Number[]) = Used for extra parameters on specific eases
    >       `offset` (Boolean) = Will modify `pmods_offset` instead of `pmods`
    >       `plr` (Number[2] / Number) = Will call either a specific player or players instead of the default.
    >
    > Like Ky_Dash and Xero's Mod Reader. This returns the table itself, so you can stack call these!
    >
    > `ease_offset` does the same thing as `ease`, but applies the `offset` parameter automatically.
    >
    > Example:
    >   ease
    >   { 0, 360, 'rotationz' } -- Apply 360 rotationz
    >   { 0, 5, linear, 0, 'rotationz', 100, 'drunk' } -- Set rotationz to 0, and drunk to 100 in 5 beats, with linear ease.

    * Optional, will return `0` if not specified. Length is `len` by default. If the value is higher than `start_beat`, it will be treated as `end`
    ** Optional, will return `linear` if not specified. You can also use `ease=`, if you want to for some reason.
    -------------------------------------------
    func
    > `func` does two things:
    >   Perframe, with the format:
    >       { beat_start, beat_end, function }
    >   Message broadcast with the format:
    >       { beat_start, function (string/function) }
    >       `persist` (number/boolean) is optional.
    >           If it's a number, it will run the function if the song started past `beat_start+4` and the beat haven't gotten past the persist number.
    >           If it's a boolean, it will always run the function if the song started past `beat_start+4`.

    -------------------------------------------
    func_ease
    > Does an Exschwasion func_ease
    > Format:
    >   { beat_start, beat_length*, value_min, value_max, function, ease** }
    >   There's also optional parameters:
    >       `extra` (Number[]) = Used for extra parameters on specific eases

    * Length is `len` by default. If the value is higher than `start_beat`, it will be treated as `end`
    ** Optional, will return `linear` if not specified. You can also use `ease=`, if you want to for some reason.
    -------------------------------------------
    Extra stuffs:
        Dont want P1 and P2 to be the default players for some mod lines?
        Use `set_default_pn` to set the new players.
        Format:
            `set_default_pn( min, max ) -- [min - max]`
            `set_default_pn( {min, max} ) -- [min - max]`
            `set_default_pn( max ) -- [1 - max]`
            `set_default_pn() -- [1 - 2]`
            
    Oh! And even though this is in a mod reader environment, any variables created here will be visible in the `melody` env, so you don't have to worry about that.
]]

-- Insert mods here! --
-----------------------
local l, e = 'len', 'end'

-- ease{0,9e9,'beat'}