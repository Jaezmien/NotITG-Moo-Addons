collisions = {}

-- :(
local function deg_to_rad(deg) return ( (deg / 90) * math.pi ) / 2 end

local function width(spr)
    if actor_type(spr) == 'Quad' then
        return spr:GetZoomX()
    elseif actor_type(spr) == 'Sprite' then
        return spr:GetWidth() * spr:GetZoom()
    end
end
local function height(spr)
    if actor_type(spr) == 'Quad' then
        return spr:GetZoomY()
    elseif actor_type(spr) == 'Sprite' then
        return spr:GetHeight() * spr:GetZoom()
    end
end

collisions.quadToQuad = function(a, b)
    local x = {0, 0, 0, 0}
    local y = {0, 0, 0, 0}
    --
    x = type(a) == 'userdata' and {a:GetX(), a:GetY(), width(a), height(a)} or a
    y = type(b) == 'userdata' and {b:GetX(), b:GetY(), width(b), height(b)} or b
    --
    return (x[1] - (x[3] / 2) < y[1] + (y[3] / 2)) and
               (x[2] + (x[4] / 2) > y[2] - (y[4] / 2)) and
               (x[2] - (x[4] / 2) < y[2] + (y[4] / 2)) and
               (x[1] + (x[3] / 2) > y[1] - (y[3] / 2))
end

--+ youtube.com/watch?v=7Ik2vowGcU0 & https://github.com/OneLoneCoder/olcPixelGameEngine/blob/master/Videos/OneLoneCoder_PGE_PolygonCollisions1.cpp
local rot_quadToQuad_sat = function(x, y)

    local max_num = (1/0)
    local min_num = -(1/0)

    for i=1,2 do

        local obj1 = i==1 and x or y
        local obj2 = i==1 and y or x

        for _,edge in pairs( collisions.edges_cw(obj1) ) do -- { current_corner, next_corner } -> { x, y }

            local axisProj = {
                -( edge[2][2] - edge[1][2] ),
                   edge[2][1] - edge[1][1]
            }
            local d = math.sqrt( axisProj[1] * axisProj[1] + axisProj[2] * axisProj[2] )
            axisProj[1] = axisProj[1] / d
            axisProj[2] = axisProj[2] / d

            --

            local min_r1, max_r1 = max_num, min_num
            for _, corner in pairs( collisions.corners(obj1) ) do
                local q = corner[1] * axisProj[1] + corner[2] * axisProj[2]
                min_r1 = math.min(min_r1, q)
                max_r1 = math.max(max_r1, q)
            end

            local min_r2, max_r2 = max_num, min_num
            for _, corner in pairs( collisions.corners(obj2) ) do
                local q = corner[1] * axisProj[1] + corner[2] * axisProj[2]
                min_r2 = math.min(min_r2, q)
                max_r2 = math.max(max_r2, q)
            end

            if not (max_r2 >= min_r1 and max_r1 >= min_r2) then
                return false
            end

        end

    end

    return true
end
local rot_quadToQuad_sat_static = function(x, y, xobj)

    local max_num = (1/0)
    local min_num = -(1/0)

    local overlap = max_num

    for i=1,2 do

        local obj1 = i==1 and x or y
        local obj2 = i==1 and y or x

        for _,edge in pairs( collisions.edges_cw(obj1) ) do -- { current_corner, next_corner } -> { x, y }

            local axisProj = {
                -( edge[2][2] - edge[1][2] ),
                   edge[2][1] - edge[1][1]
            }
            local d = math.sqrt( axisProj[1] * axisProj[1] + axisProj[2] * axisProj[2] )
            axisProj[1] = axisProj[1] / d
            axisProj[2] = axisProj[2] / d

            --

            local min_r1, max_r1 = max_num, min_num
            for _, corner in pairs( collisions.corners(obj1) ) do
                local q = corner[1] * axisProj[1] + corner[2] * axisProj[2]
                min_r1 = math.min(min_r1, q)
                max_r1 = math.max(max_r1, q)
            end

            local min_r2, max_r2 = max_num, min_num
            for _, corner in pairs( collisions.corners(obj2) ) do
                local q = corner[1] * axisProj[1] + corner[2] * axisProj[2]
                min_r2 = math.min(min_r2, q)
                max_r2 = math.max(max_r2, q)
            end

            if not (max_r2 >= min_r1 and max_r1 >= min_r2) then
                return false
            end
            
            overlap = math.min( math.min(max_r1,max_r2) - math.max(min_r1,min_r2) , overlap )

        end

    end

    local d = {
        y[1] - x[1],
        y[2] - x[2]
    }
    local s = math.sqrt( d[1]*d[1] + d[2]*d[2] );
    if type(xobj) == 'userdata' then
        xobj:addx( -(overlap * d[1] / s) );
        xobj:addy( -(overlap * d[2] / s) );
    else
        x[1] = x[1] - (overlap * d[1] / s)
        x[2] = x[2] - (overlap * d[2] / s)
    end
    return false
end

-- good for general
collisions.rot_quadToQuad_sat = function(a, b, static)
    local x = {0, 0, 0, 0, 0} -- {x,y,w,h,r}
    local y = {0, 0, 0, 0, 0}

    --
    if type(a) == 'userdata' then
        local rx,ry,rz = a:getrotation()
        x = {a:GetX(), a:GetY(), width(a), height(a), math.mod(rz,360)}
    else x = a end
    local rotx = deg_to_rad(x[5])
    if type(b) == 'userdata' then
        local rx,ry,rz = b:getrotation()
        y = {b:GetX(), b:GetY(), width(b), height(b), math.mod(rz,360)}
    else y = b end
    local roty = deg_to_rad(y[5])
    --

    return static and rot_quadToQuad_sat_static(x,y,a) or rot_quadToQuad_sat(x, y)
end

-- good for static collisions
-- cons: if a is inside b, it outputs false
collisions.rot_quadToQuad_diag = function(a, b, static, return_disp)
    local x = {0, 0, 0, 0, 0} -- {x,y,w,h,r}
    local y = {0, 0, 0, 0, 0}

    --
    if type(a) == 'userdata' then
        local rx,ry,rz = a:getrotation()
        x = {a:GetX(), a:GetY(), width(a), height(a), math.mod(rz,360)}
    else x = a end
    local rotx = deg_to_rad(x[5])
    if type(b) == 'userdata' then
        local rx,ry,rz = b:getrotation()
        y = {b:GetX(), b:GetY(), width(b), height(b), math.mod(rz,360)}
    else y = b end
    local roty = deg_to_rad(y[5])
    --

    for i=1,2 do

        local obj1 = i==1 and x or y
        local obj2 = i==1 and y or x

        --

        for _,corner in pairs( collisions.corners(obj1) ) do

            local diag = {
                {obj1[1],obj1[2]},
                {corner[1],corner[2]}
            }
            local disp = {0,0}

            for _,edge in pairs( collisions.edges(obj2) ) do

                local collided = collisions.lineToLine(diag,edge)
                if collided then

                    if not static then return true; end
                    disp[1] = disp[1] + (1 - collided[1]) * (diag[2][1] - diag[1][1])
                    disp[2] = disp[2] + (1 - collided[1]) * (diag[2][2] - diag[2][2])

                end

            end

            if static then

                if return_disp then
                    return (disp[1] * (i==1 and -1 or 1)), (disp[2] * (i==1 and -1 or 1))
                end

                if type(a) == 'userdata' then
                    a:addx( disp[1] * (i==1 and -1 or 1) )
                    a:addy( disp[2] * (i==1 and -1 or 1) )
                else
                    a[1] = a[1] + (disp[1] * (i==1 and -1 or 1))
                    a[2] = a[2] + (disp[2] * (i==1 and -1 or 1))
                end

            end

        end

    end

    --
    return false
end
--+

collisions.circleToQuad = function(a, b)
    local x = {0, 0, 0} -- {x,y,rad}
    local y = {0, 0, 0, 0} -- {x,y,w,h}
    --
    x = type(a) == 'userdata' and {a:GetX(), a:GetY(), width(a) / 2} or a
    y = type(b) == 'userdata' and {b:GetX(), b:GetY(), width(b), height(b)} or b
    -- ++ https://stackoverflow.com/a/1879223 & https://yal.cc/rectangle-circle-intersection-test/
    local nearX = math.max(y[1] - y[3] / 2, math.min(x[1], y[1] + y[3] / 2))
    local nearY = math.max(y[2] - y[4] / 2, math.min(x[2], y[2] + y[4] / 2))
    local dx = x[1] - nearX
    local dy = x[2] - nearY
    return (dx * dx + dy * dy) < (x[3] * x[3])
end
collisions.rot_circleToQuad = function(a, b)
    local x = {0, 0, 0} -- {x,y,rad}
    local y = {0, 0, 0, 0, 0} -- {x,y,w,h,rot}
    --
    x = type(a) == 'userdata' and {a:GetX(), a:GetY(), width(a) / 2} or a
    if type(b) == 'userdata' then
        local rx, ry, rz = b:getrotation()
        y = type(b) == 'userdata' and {b:GetX(), b:GetY(), width(b), height(b), math.mod(rz, 360)} or b
    else y = b end
    --
    if math.mod(y[5], 90) == 0 then
        if y[5] == 90 or y[5] == 270 then y[4], y[3] = y[3], y[4] end -- swap width and height
        -- ++ https://stackoverflow.com/a/1879223 & https://yal.cc/rectangle-circle-intersection-test/
        local nearX = math.max(y[1] - y[3] / 2, math.min(x[1], y[1] + y[3] / 2))
        local nearY = math.max(y[2] - y[4] / 2, math.min(x[2], y[2] + y[4] / 2))
        local dx = x[1] - nearX
        local dy = x[2] - nearY
        return (dx * dx + dy * dy) < (x[3] * x[3])
    else
        -- ++ http://www.migapro.com/circle-and-rotated-rectangle-collision-detection/

        -- convert degrees to radians
        local rz = -deg_to_rad(y[5]) -- weird bug, had to flip rotation
        --
        local rx = y[1] - y[3]/2
        local ry = y[2] - y[4]/2
        local rw = y[3]
        local rh = y[4]
        -- calculate unrotated position of circle
        local npos = {
            math.cos(rz) * (x[1] - y[1]) - math.sin(rz) * (x[2] - y[2]) + y[1],
            math.sin(rz) * (x[1] - y[1]) + math.cos(rz) * (x[2] - y[2]) + y[2]
        }
        -- get nearest point from rectangle
        local nx = math.clamp(npos[1],rx,rx+rw)
        local ny = math.clamp(npos[2],ry,ry+rh)
        -- get distance + check collision
        return math.dist(npos, {nx, ny}) < x[3]
    end
end

collisions.circleToCircle = function(a, b)
    local x = a -- {x,y,rad}
    local y = b -- {x,y,rad}
    x = type(a) == 'userdata' and {a:GetX(), a:GetY(), width(a) / 2} or a
    y = type(b) == 'userdata' and {b:GetX(), b:GetY(), width(b) / 2} or b
    -- ++ https://stackoverflow.com/a/1736741 & https://gamedevelopment.tutsplus.com/tutorials/when-worlds-collide-simulating-circle-circle-collisions--gamedev-769
    return math.dist(x, y) < x[3] + y[3]
end

collisions.lineToLine = function(a, b)
    --+ https://github.com/processing/processing/wiki/Line-Collision-Detection
    --+ http://jeffreythompson.org/collision-detection/line-line.php

    local x1,y1 = a[1][1],a[1][2]
    local x2,y2 = a[2][1],a[2][2]
    local x3,y3 = b[1][1],b[1][2]
    local x4,y4 = b[2][1],b[2][2]
    --
    local d = ((x2-x1) * (y4-y3)) - ((y2-y1) * (x4-x3))
    local r = ((y1-y3) * (x4-x3)) - ((x1-x3) * (y4-y3))
    local s = ((y1-y3) * (x2-x1)) - ((x1-x3) * (y2-y1))
    
    if d==0 then
        if r == 0 and s == 0 then
            return { r,s }
        else
            return nil
        end
    end

    r = r / d; s = s / d;
    --
    if (r>=0 and r<=1) and (s>=0 and s<=1) then return { r,s }
    else return nil end
end

--

collisions.sides = function(a)
    local x = type(a) == 'userdata' and {a:GetX(), a:GetY(), width(a), height(a)} or a
    return {
        Left = a[1] - a[3] / 2,
        Bottom = a[2] + a[4] / 2,
        Top = a[2] - a[4] / 2,
        Right = a[1] + a[3] / 2
    }
end
collisions.corners = function(a)
    local x = {0, 0, 0, 0, 0} -- {x,y,w,h,r}

    if type(a) == 'userdata' then
        local rx, ry, rz = a:getrotation()
        x = {a:GetX(), a:GetY(), width(a), height(a), math.mod(rz,360) }
    else x = a end

    local rot = deg_to_rad(x[5])

    local c = {
        TL = {0,0},
        TR = {0,0},
        BR = {0,0},
        BL = {0,0},
    }
    local c_guide = {'TL','TR','BL','BR'}
    local a_corners = {
        { x[1]-x[3]/2 , x[2]-x[4]/2 }, -- TL
        { x[1]+x[3]/2 , x[2]-x[4]/2 }, -- TR
        { x[1]-x[3]/2 , x[2]+x[4]/2 }, -- BL
        { x[1]+x[3]/2 , x[2]+x[4]/2 }, -- BR
    }
    
    for i,v in pairs(a_corners) do
        --+ https://gamedev.stackexchange.com/a/86784
        local tx = v[1] - x[1]
        local ty = v[2] - x[2]

        local rx = tx * math.cos(rot) - ty * math.sin(rot)
        local ry = tx * math.sin(rot) + ty * math.cos(rot)

        local corn = c[ c_guide[i] ]
        corn[1] = rx + x[1]
        corn[2] = ry + x[2]
    end
    return c
end
collisions.edges = function(a)

    local corners = collisions.corners(a)
    return {
        Left = { corners.TL, corners.BL },
        Bottom = { corners.BL, corners.BR },
        Top = { corners.TL, corners.TR },
        Right = { corners.TR, corners.BR }
    }

end
collisions.edges_cw = function(a)

    local corners = collisions.corners(a)
    return {
        { corners.TL, corners.TR },
        { corners.TR, corners.BR },
        { corners.BR, corners.BL },
        { corners.BL, corners.TL }
    }

end