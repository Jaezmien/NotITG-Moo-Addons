local linear = function(t, b, c, d) return c * t / d + b end

local tweens = {}

--

local function Create_Tween( min, max, length, tween )
    local t = {}

    t.Range = { min, max }
    t.Tween = tween or linear
    t.Time = length
    t.MaxTime = length

    t.OnStart = function() end
    t.OnTick = function() end
    t.OnEnd = function() return false end

    t.Paused = false

    return t
end

Tweeny = setmetatable(
    {
        Tween = function( self, _min, _max, _len, _tween )
            local min, max = 0, 0
            local len, tween = 0, linear

            if not _max and not _len and not _tween then
                if type( _min ) == 'number' then
                    min, max = 0, 1
                    len, tween = _min, linear
                else
                    print('[Tweeny] Invalid Tween')
                    return
                end
            else
                min, max = _min, _max
                len, tween = _len, _tween
            end

            local tw = Create_Tween( min, max, len, tween )
            local id = tostring( tw )
            tweens[ id ] = tw
            
            return setmetatable(
                {
                    OnStart = function(self, func) tw.OnStart = func; return self end,
                    OnTick = function(self, func) tw.OnTick = func; return self end,
                    OnEnd = function(self, func) tw.OnEnd = func; return self end,

                    Stop = function(self) tweens[ id ] = nil; return self end,
                    Pause = function(self) tw.Paused = true; return self end,
                    Start = function(self) tw.Paused = false; return self end,
                    Reset = function(self) tw.Time = tw.MaxTime; return self end,
                },
                {
                    __newindex = function() end,
                }
            )
        end,
    },
    {
        __newindex = function() end,
    }
)

--

update_hooks{
    'tweeny update',
    function()

        for id, tween in pairs( tweens ) do

            if not tween.Paused then

                if tween.Time == tween.MaxTime then tween.OnStart() end
                tween.Time = math.max( tween.Time - delta_time, 0 )
                tween.OnTick( tween.Tween(tween.MaxTime - tween.Time, tween.Range[1], tween.Range[2] - tween.Range[1], tween.MaxTime) )
                if tween.Time == 0 then

                    -- If the OnEnd function returns false, we're deleting the Tweeny instance
                    -- Else, we reset it :D
                    local do_reset = tween.OnEnd() == false
                    if not do_reset then
                        tweens[ id ] = nil
                    else
                        tween.Time = tween.MaxTime
                    end

                end

            end

        end

    end,
}