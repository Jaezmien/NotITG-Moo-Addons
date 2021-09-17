local function create_child_class(orig, args)
    local child = table.clone( orig )
    if args then
        for key, value in pairs( args ) do
            child[ key ] = value
        end
    end
    return child
end

local classes = {}
class = setmetatable(
    {
        New = function(self, id, t, constructor)

            if not id or not t then
                print('[Class] Missing arguments')
                return
            end
            if type(id) ~= 'string' or type(t) ~= 'table' then
                print('[Class] Invalid argument type')
                return
            end

            local c
            if t.__classID  then
                c = t
            else
                c = table.clone( t )
                c.__classID = id
            end

            constructor = constructor or (function() return {} end)

            local v = setmetatable(
                {
                    __parentID = id,
                    Create = function(self,...)
                        local args = {}
                        if type(arg) == 'table' and table.getn(arg) ~= 1 then
                            constructor( args, unpack(arg) )
                        elseif type(arg[1]) == 'table' then
                            args = arg[1]
                        else args = nil end
                            
                        return create_child_class( c, args )
                    end,
                    Inherit = function(_,new_id, new_args, constructor)
                        if not new_id then
                            print('[Class Inherit] Missing arguments')
                            return
                        end
                        if type(new_id) ~= 'string' or type(new_args) ~= 'table' then
                            print('[Class Inherit] Invalid argument type')
                            return
                        end

                        local i = table.clone( c )
                        for key, value in pairs( new_args ) do i[key] = value end
                        i.__classID = new_id

                        return self:New( new_id, i, constructor )
                    end,
                },
                {
                    __call = function(self,...) self:Create( unpack(arg) ) end,
                    __newindex = function(_,k,v) c[k] = v end,
                }
            )

            classes[ id ] = v
            return v

        end
    },
    {
        __newindex = function() end,
        __index = function(s,k) return classes[k] end,
        __call = function(self,...) self:New( unpack(arg) ) end,
    }
)