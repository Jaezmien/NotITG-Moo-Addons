local reader = {}

if not FUCK_EXE then return end

-- insert modreader stuff here
------------------------------

-- Note: This reader is based on HeySora's Purple People Eater Modfile

reader.hey_config = {
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

reader.mods = {}
reader.easeMods = {}
reader.cmds = {}

--

hey = {}

hey.ClassicModTable = {};
hey.ClassicModTable.lastFoundMod = true;
hey.ClassicModTable.lastMods = {};

hey.EasingModTable = {};
hey.CommandTable = {};

function hey.Mod(mods, p)
    if mods == '' then return; end
    hey.ClassicModTable.lastFoundMod = true;

    if p and p > 0 then mod_do( mods, p ) else mod_do( mods ) end
end

local ready = function()
    -- Sorting the mod table by starting beat, allowing great optimisations during the UpdateCommand.
    local function sort_table(a,b) return a[1] < b[1] end

    do
        if not reader.mods or type(reader.mods) ~= 'table' then
            SystemMessage('hey.mods: The table doesn\'t exist, or is invalid!');
            reader.mods = {};
        else
            for i,v in ipairs(reader.mods) do
                local n = table.getn(v);
                if type(v) == 'table' and n >= 3 and n <= 6
                and type(v[1]) == 'number' and type(v[2]) == 'number' and type(v[3]) == 'string' then
                    -- Default values
                    if n < 4 or type(v[4]) ~= 'string' or v[4] ~= 'end' and v[4] ~= 'len' then
                        -- If the end/len time is lesser than the beginning time, it's the length. Otherwise, it's *probably* the end time.
                        v[4] = v[2] <= v[1] and 'len' or 'end';
                    end
                    if n < 5 or type(v[5]) ~= 'number' or v[5] < 0 or v[5] > reader.hey_config.Misc.PlayerAmount then
                        -- Apply for both players
                        v[5] = 0;
                    end
                else
                    SystemMessage(
                        (n == 6 and v[6])
                        and 'hey.mods: Invalid inserted mod.'
                        or 'hey.mods: Invalid mod at index #'.. i ..'.'
                    );
                    table.remove(reader.mods, i);
                end
            end

            if table.getn(reader.mods) > 1 then table.sort(reader.mods, sort_table) end
        end
    
        hey.ClassicModTable.checked = true;
    end -- ClassicModTable

    do
        if not reader.easeMods or type(reader.easeMods) ~= 'table' then
            SystemMessage('hey.easeMods: The table doesn\'t exist, or is invalid!');
            reader.easeMods = {};
        else
            for i,v in ipairs(reader.easeMods) do
                local n = table.getn(v);
                if type(v) == 'table' and n >= 6 and n <= 10
                and type(v[1]) == 'number' and type(v[2]) == 'number' and type(v[3]) == 'number'
                and type(v[4]) == 'number' and type(v[5]) == 'string' and type(v[6]) == 'function' then
                    -- Default values
                    if n < 7 or type(v[7]) ~= 'number' or v[7] < 0 then
                        v[7] = 0;
                    end
                    if n < 8 or type(v[8]) ~= 'string' or v[8] ~= 'end' and v[8] ~= 'len' then
                        -- If the end/len time is lesser than the beginning time, it's the length. Otherwise, it's *probably* the end time.
                        v[8] = v[2] <= v[1] and 'len' or 'end';
                    end
                    if n < 9 or type(v[9]) ~= 'number' or v[9] < 0 or v[9] > reader.hey_config.Misc.PlayerAmount then
                        -- Apply for both players
                        v[9] = 0;
                    end

                    -- Allow 'len' sustain time with 'end' mods
                    if v[7] ~= 0 and v[8] == 'end' and v[7] < v[2] then
                        v[7] = v[2] + v[7];
                    end
                else
                    SystemMessage(
                        (n == 10 and v[10])
                        and 'hey.easeMods: Invalid inserted mod.'
                        or 'hey.easeMods: Invalid mod at index #'.. i ..'.'
                    );
                    table.remove(reader.easeMods, i);
                end
            end
            if table.getn(reader.easeMods) > 1 then table.sort(reader.easeMods, sort_table) end
        end
    
        hey.EasingModTable.checked = true;
    end -- EasingModTable

    do
        if not reader.cmds or type(reader.cmds) ~= 'table' then
            SystemMessage('hey.cmds: The table doesn\'t exist, or is invalid!');
            reader.cmds = {};
        else
            for i,v in ipairs(reader.cmds) do
                local n = table.getn(v);
                if type(v) ~= 'table' or n < 2 or n > 4
                or type(v[1]) ~= 'number' or type(v[2]) ~= 'string' and type(v[2]) ~= 'function' then
                    SystemMessage('hey.cmds: Invalid command at index #'.. i .. '.'); 
                    table.remove(reader.cmds, i);
                else
                    if type(v[3]) ~= 'table' then
                        v[3] = {};
                    end
                    if type(v[4]) ~= 'string' or v[4] ~= 'beat' and v[4] ~= 'sec' then
                        v[4] = reader.hey_config.CommandTable.BeatBasedCmds and 'beat' or 'sec';
                    end
                end
            end
            
            if table.getn(reader.cmds) > 1 then table.sort(reader.cmds, sort_table) end
        end
    
        hey.CommandTable.checked = true;
    end -- CommandTable
end
local update = function()
    if not hey.ClassicModTable.checked then ready() end

    local beat = GAMESTATE:GetSongBeat()
    local time = get_song_time()

    do
        -- index is mod[5], player number; 0 is both players
        local mods = {};
        for i=0,reader.hey_config.Misc.PlayerAmount do
            mods[i] = '';
        end

        local foundMod = false;

        -- Parse Mod table
        for i,v in ipairs(reader.mods) do
            if reader.hey_config.ClassicModTable.BeatBasedMods and beat >= v[1] or time >= v[1] then
                if
                    reader.hey_config.ClassicModTable.BeatBasedMods and (v[4] == 'len' and beat <= v[1] + v[2] or v[4] == 'end' and beat <= v[2])
                    or not reader.hey_config.ClassicModTable.BeatBasedMods and (v[4] == 'len' and time <= v[1] + v[2] or v[4] == 'end' and time <= v[2])
                then
                    foundMod = true;
                    mods[v[5]] = mods[v[5]] .. v[3] .. ',';
                    --hey.Mod(v[3], v[5]);
                end
            else
                break;
            end
        end

        -- idk but this clears mods for some reason so YEET
        --[[if foundMod then
            foundMod = false;
            local lastMods = hey.ClassicModTable.lastMods;
            for i=0,reader.hey_config.Misc.PlayerAmount do
                if mods[i] ~= lastMods[i] then
                    foundMod = true;
                    break;
                end
            end
        end]]

        if hey.ClassicModTable.lastFoundMod or foundMod then
            -- Clear all mods
            --hey.Mod('clearall');

            -- Re-apply players initial mods, if enabled in the configuration
            if reader.hey_config.Mods.KeepPlayerMods then
                for i=1,reader.hey_config.Misc.PlayerAmount do
                    -- Put original mods BEFORE mods in the table
                    local options = screen:GetChild('PlayerOptionsP'.. i);
                    local pmods = options and options:GetText() or ''
                    mods[i] = pmods .. ',' .. mods[i];
                end
            end

            -- Apply all mods at once
            for i=0,reader.hey_config.Misc.PlayerAmount do
                hey.Mod(mods[i], i);
            end

            hey.ClassicModTable.lastFoundMod = foundMod;
            hey.ClassicModTable.lastMods = mods;
        end
    end -- ClassicModTable

    do
        local mods = {};
        for i=0,reader.hey_config.Misc.PlayerAmount do
            mods[i] = '';
        end

        -- Parse Mod table
        for i,v in ipairs(reader.easeMods) do
            if reader.hey_config.EasingModTable.BeatBasedMods and beat >= v[1] or time >= v[1] then
                if
                    reader.hey_config.EasingModTable.BeatBasedMods and (v[8] == 'len' and beat <= v[1] + v[2] or v[8] == 'end' and beat <= v[2])
                    or not reader.hey_config.EasingModTable.BeatBasedMods and (v[8] == 'len' and time <= v[1] + v[2] or v[8] == 'end' and time <= v[2])
                then
                    -- local strength = v[6](
                    --     (reader.hey_config.EasingModTable.BeatBasedMods and beat or time) - v[1], -- Elapsed time
                    --     v[3], -- Beginning
                    --     v[4] - v[3], -- Change (ending - beginning)
                    --     v[8] == 'end' and v[2] - v[1] or v[2] -- Duration (total time)
                    -- );
					local elapsed = (reader.hey_config.EasingModTable.BeatBasedMods and beat or time) - v[1]
					local duration = v[8] == 'end' and v[2] - v[1] or v[2]
					local beginning = v[3]
					local change = v[4] - v[3]
					local strength = beginning + v[6](elapsed / duration) * change
                    local modstr = v[5] == 'xmod' and strength..'x' or (v[5] == 'cmod' and 'C'..strength or strength..' '..v[5]);
                    mods[v[9]] = mods[v[9]] .. '*-1 ' .. modstr .. ',';
                    --hey.Mod(v[3], v[9]);
                elseif v[7] > 0 and (
                    reader.hey_config.EasingModTable.BeatBasedMods and (v[8] == 'len' and beat <= v[1] + v[2] + v[7] or v[8] == 'end' and beat <= v[7])
                    or not reader.hey_config.EasingModTable.BeatBasedMods and (v[8] == 'len' and time <= v[1] + v[2] + v[7] or v[8] == 'end' and time <= v[7])
                ) then
                    local modstr = v[5] == 'xmod' and v[4]..'x' or (v[5] == 'cmod' and 'C'..v[4] or v[4]..' '..v[5]);
                    mods[v[9]] = mods[v[9]] .. '*-1 ' .. modstr .. ',';
                    --hey.Mod('*-1' .. modstr, v[9]);
                end
            else
                break;
            end
        end

        -- Apply all mods at once
        for i=0,reader.hey_config.Misc.PlayerAmount do
            hey.Mod(mods[i], i);
        end
    end -- EasingModTable

    do
        for i,v in ipairs(reader.cmds) do
            if v[4] == 'beat' and beat >= v[1] or v[4] == 'sec' and time >= v[1] then
                if type(v[2]) == 'function' then
                    v[2](unpack(v[3]));
                else -- type(v[2]) == 'string'
                    MESSAGEMAN:Broadcast( v[2] )
                end
                table.remove(reader.cmds, i);
            else
                break;
            end
        end
    end -- CommandTable

    MESSAGEMAN:Broadcast('HeyUpdate')
end

------------------------------
-- insert modreader stuff here

return reader, {
    func = update,
    clear = true,
}