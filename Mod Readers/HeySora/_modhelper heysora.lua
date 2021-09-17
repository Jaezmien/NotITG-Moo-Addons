local helper = {}

-- insert modhelper stuff here
------------------------------

function helper.InsertMod(startTime, endTime, mods_, mode, player)
    if hey.ClassicModTable.checked then
        hey.SM('hey.InsertMod(): Please use this method only during the InitCommand.');
        return;
    end

    -- Default values
    mode = mode or (endTime < startTime and 'len' or 'end');
    player = player or 0;

    -- 6th value = "inserted mod"
    table.insert(mods, {startTime, endTime, mods_, mode, player, true});
    
    -- Since hey.InsertMod() can only be used during the InitCommand,
    -- The inserted mod will be checked/optimised by the ReadyCommand
    --[[
        if type(startTime) == 'number' and type(endTime) == 'number' and type(mods) == 'string' then
            if type(mode) ~= 'string' or mode ~= 'end' and mode ~= 'len' then
                mode = endTime <= startTime and 'len' or 'end';
            end
            if type(player) ~= 'number' or player < 0 or player > hey.Config.Misc.PlayerAmount then
                player = 0;
            end
            
            table.insert(hey.mods, {startTime, endTime, mods, mode, player});
        else
            hey.SM('hey.InsertMod(): Invalid parameters.');
        end
    ]]
end

function helper.InsertEaseMod(startTime, endTime, startIntensity, endIntensity, modName, easeFunc, sustainTime, mode, player)
    if hey.EasingModTable.checked then
        SystemMessage('hey.InsertEaseMod(): Please use this method only during the InitCommand.');
        return;
    end

    -- Default values
    sustainTime = sustainTime or 0;
    mode = mode or (endTime < startTime and 'len' or 'end');
    player = player or 0;

    -- 10th value = "inserted mod"
    table.insert(easeMods, {startTime, endTime, startIntensity, endIntensity, modName, easeFunc, sustainTime, mode, player, true});
end

function hey.InsertCmd(time, cmd, args, mode)
    if hey.CommandTable.checked then
        SystemMessage('hey.InsertCmd(): Please use this method only during the InitCommand.');
        return;
    end

    args = args or {};
    mode = mode or (hey_config.CommandTable.BeatBasedCmds and 'beat' or 'sec');
    table.insert(cmds, {time, cmd, args, mode});

    -- Since hey.InsertCmd() can only be used during the InitCommand,
    -- The inserted command will be checked/optimised by the ReadyCommand
    --[[
        if type(time) == 'number' and ( type(cmd) == 'string' or type(cmd) == 'function' ) then
            if type(mode) ~= 'string' or mode ~= 'beat' and mode ~= 'sec' then
                mode = hey.config.CommandTable.BeatBasedCmds and 'beat' or 'sec';
            end
            table.insert(hey.cmds, {time, cmd, mode});
        else
            hey.SM('hey.InsertCmd(): Invalid parameters.');
        end
    ]]
end

------------------------------
-- insert modhelper stuff here

return helper