local auxvars = {}
local auxvars_dictionary = {}
local auxvars_public_dictionary = {}

local linear = function(t) return t end

aux = setmetatable(
    {
        Create = function (self,id)
            local private = {
                value = 0,
                tweens = {}
            }
            local public = {}

            --
            public.getaux = function(self)
                return private.value
            end
            
            public.tween = function(self,seconds,tween)
                if not seconds then return end
                if not tween or type(tween(1)) ~= 'number' then tween = linear end

                local t = {
                    time_passed = 0,
                    time_length = seconds,
                    end_value = nil,
                    start_value = nil,
                    ease = tween or linear,
                }
                table.insert( private.tweens, t )

                return self
            end
            public.sleep = function(self,seconds)
                public:tween( seconds, linear )
                public:tween( 0, linear )
                return self
            end

            public.stoptweening = function(self)
                private.tweens = {}
                return self
            end
            public.stop = public.stoptweening

            public.finishtweening = function(self)
                private.value = private.tweens[ table.getn(private.tweens) ].end_value
                public:stoptweening()
                return self
            end
            public.finish = public.finishtweening

            public.hurrytweening = function(self,factor)
                factor = factor or 1
                for i,tween in pairs( private.tweens ) do
                    tween.time_passed = tween.time_passed / factor
                    tween.time_length = tween.time_length / factor
                end
                return self
            end
            public.hurry = public.hurrytweening

            public.aux = function(self,value)
                if table.getn( private.tweens ) > 0 then
                    private.tweens[ table.getn( private.tweens ) ].end_value = value
                else
                    private.value = value
                end
                return self
            end
            public.addaux = function(self,value)
                if table.getn( private.tweens ) > 0 then
                    private.tweens[ table.getn( private.tweens ) ].end_value = private.tweens[ table.getn( private.tweens ) ].end_value + value
                else
                    private.value = private.value + value
                end
                return self
            end
            public.Delete = function(self)
                local private_id = auxvars_dictionary[ self ]
                auxvars[ private_id ] = nil
                auxvars_public_dictionary[ private_id ] = nil
            end
            --

            if id and type(id) == 'string' then
                auxvars[ id ] = private
                auxvars_public_dictionary[ id ] = public
                auxvars_dictionary[ public ] = id
            else

                table.insert( auxvars, private )
                auxvars_public_dictionary[ table.getn( auxvars ) ] = public
                auxvars_dictionary[ public ] = table.getn( auxvars )
            end
            return public
        end,
    },
    {
        __index = function(t,k)
            return type(k) ~= 'string' and nil or auxvars_public_dictionary[ k ]
        end,
        __newindex = function() end,
    }
)

local last_seen_time = -1
update_hooks{ 'auxvar update', function()
    local current_time = get_song_time()
    if last_seen_time ~= current_time then
        last_seen_time = current_time
        --
        for id,auxvar in pairs( auxvars ) do
            if table.getn( auxvar.tweens ) > 0 then

                local tween = auxvar.tweens[1]

                if( tween.time_passed == 0 ) then
                    tween.start_value = auxvar.value
                    if not tween.end_value then tween.end_value = auxvar.value end
                end

                tween.time_passed = math.min( tween.time_passed + delta_time, tween.time_length )
                if tween.time_passed == tween.time_length then
                    auxvar.value = tween.end_value
                    table.remove(auxvar.tweens,1)
                else
					auxvar.value = tween.start_value + tween.ease( tween.time_passed / tween.time_length ) * ( tween.end_value - tween.start_value )
                end

            end
        end
    end
end }