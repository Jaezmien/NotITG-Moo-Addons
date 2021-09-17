-- Partial Config.lua
hey_config = {
    Mods = {
        -- Put this to true to not clear the mods chose by players
        KeepPlayerMods        = false,
        -- The mods which will be applied instantly (*before* the song starts, at the very 1st frame)
        -- Those mods won't be kept, you need to add them in your mod table, at beat 0, if you want to keep them.
        InitialMods           = '*-1 2.5x'
    },
    Misc = {
        -- The amount of playfields which will be used. (for example 4 will create P1/P2/P3/P4, and SetAwake(true) P3 and P4)
        -- Mods can't be applied on playfields outside of this range!
        PlayerAmount          = 2,
    },
    ClassicModTable = {
        -- Put this to true to have a beat-based mod table. false for a seconds-based mod table.
        BeatBasedMods         = true
    },
    EasingModTable = {
        -- Put this to true to have a beat-based mod table. false for a seconds-based mod table.
        BeatBasedMods         = true
    },
    CommandTable = {
        -- Put this to true to default the commands to the beat. false to default them to the time.
        -- Each command can override this by specifying a 4th argument: 'beat' or 'sec'
        BeatBasedCmds         = true
    },
}

--++==++--

-- format: {start, end, mods, [ len/end, playerNumber ] }
mods = {
    -- {0, 9e9, '*-1 100 beat'}
}

-- format: {start, end, intensityStart, intensityEnd, modName, easeFunc, [ sustainTime, len/end, playerNumber ] }
easeMods = {

}

-- format: {start, func/string}
cmds = {

}