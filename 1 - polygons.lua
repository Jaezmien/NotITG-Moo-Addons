poly = {}

--

local polygons = {}

poly.add_polygon = function(k,t)
    if polygons[k] then print('## POLYGON (' .. k ..') ALREADY EXISTS ##') else polygons[k] = t end
end
poly.remove_polygon = function(k)
    if polygons[k] then polygons[k] = nil else print('## POLYGON ('.. k ..' DOESN\'T EXIST ##') end
end
poly.get_polygon = function(k)
    return polygons[k]
end

--

poly.npot = function(val)
    local out = 2
    while out < val do out = out * 2 end
    return out
end

--+ SHAPNES +--

poly.create_tri = function(actor,id,size)
    size = size or 90
    actor:SetDrawMode('triangles')
    actor:SetNumVertices(3)
    actor:SetVertexPosition(0,0,-size/2,0)
    actor:SetVertexPosition(1,size/2, size/2,0)
    actor:SetVertexPosition(2,-size/2, size/2,0)

    if id then poly.add_polygon(id,actor) end
end

-- create quad using polygon
-- pros: actually can be rotated if it has separate zoom values without shit dying
-- cons: a bit tricky to set up, since you'd need a %function
poly.create_quad = function(actor,id,w,h)
    if not h then h = w end
    
    actor:SetDrawMode('quads')
    actor:SetNumVertices(4)
    actor:SetVertexPosition(0,-w/2,-h/2,0)
    actor:SetVertexPosition(1, w/2,-h/2,0)
    actor:SetVertexPosition(2, w/2, h/2,0)
    actor:SetVertexPosition(3,-w/2, h/2,0)

    if id then poly.add_polygon(id,actor) end
end

-- ...dont diffuse the vertices
-- someone please tell me a much more better way to do this
poly.create_circ = function(actor,id,rad,step_mult)
    local steps = math.pow(2,step_mult or 5) -- the higher the step_mult is, the smoother the circle is
    actor:SetDrawMode('fan')
    actor:SetNumVertices(steps)

    for i=1,steps do
        local m = i/steps
        actor:SetVertexPosition(i-1, math.cos(m*math.pi*2) * rad , math.sin(m*math.pi*2) * rad ,0)
    end

    if id then poly.add_polygon(id,actor) end
end

poly.create_hollow_circ = function(actor,id,rad,hollow_size_mult,step_mult)
    hollow_size_mult = hollow_size_mult or 0.8
    local steps = math.pow(2,step_mult or 6) -- the higher the step_mult is, the smoother the circle is
    actor:SetDrawMode('strip')
    actor:SetNumVertices( steps+2 )

    local step_type = 1
    for i=1,steps+2 do
        local m = i/steps
        if step_type==1 then -- outside
            local vx,vy = math.cos(m*math.pi*2) * rad , math.sin(m*math.pi*2) * rad
            actor:SetVertexPosition(i-1,vx,vy,0)
        elseif step_type==-1 then -- inside
            local vx,vy = math.cos(m*math.pi*2) * (rad * hollow_size_mult) , math.sin(m*math.pi*2) * (rad * hollow_size_mult)
            actor:SetVertexPosition(i-1,vx,vy,0)
        end

        step_type = -step_type
    end

    if id then poly.add_polygon(id,actor) end
end

--
poly.create_divided_line = function(actor,id,split,x_mult)
    split = split or 1
    x_mult = x_mult or 1
    actor:SetDrawMode('linestrip')
    actor:SetNumVertices( 1 + split )
    actor:SetPolygonMode(1)
    actor:SetLineWidth(2)
    for i=1,split+1 do
        local x_offset = ( (i-1) / split )
        actor:SetVertexPosition(i-1,x_offset * x_mult,0,0)
    end

    if id then poly.add_polygon(id,actor) end
end