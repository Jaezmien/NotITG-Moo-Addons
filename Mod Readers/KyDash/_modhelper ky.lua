local helper = {}

-- insert modhelper stuff here
------------------------------

helper.mod_wiggle = function(beat,len,amt,step,str,param)
    local cur,last,f = amt,0,1
    local t = (len-step)
    param.abs = param.abs or false
    param.timing = param.timing or 'len'
    if param.timing == 'end' then t = (len-beat) end
    for i = 0,t,step do
        if i == t then cur = 0 end
        mod {(beat-(step/2))+i, step, tostring(str), last, cur, ease = param.ease, pn = param.pn, timing = 'len'}
        last = cur
        if param.abs then cur = cur-(amt*f) f=-f else cur = -cur end
    end
end
helper.mod_bounce = function(b)
    b.hold = b.hold or 0
    mod {b[1], (b[2]/2), b.mod or b[5], b[3], b[4], ease = b.in_ease or b.ease, pn = b.pn, sustain = b.hold, args = b.iargs or b.args}
    {b[1]+(b[2]/2)+b.hold, (b[2]/2), b.mod or b[5], b[4], b.ev or b[3], ease = b.out_ease or b.ease, pn = b.pn, sustain = b.sustain, args = b.oargs or b.args}
    return helper.mod_bounce
end
-- s/o to BrotherMojo
helper.reverse_rotation = function(angleX, angleY, angleZ)
    local sinX,cosX,sinY,cosY,sinZ,cosZ = math.sin(angleX),math.cos(angleX),math.sin(angleY),math.cos(angleY),math.sin(angleZ),math.cos(angleZ)
    return { math.atan2(-cosX*sinY*sinZ-sinX*cosZ,cosX*cosY), math.asin(-cosX*sinY*cosZ+sinX*sinZ), math.atan2(-sinX*sinY*cosZ-cosX*sinZ,cosY*cosZ) }
end
helper.rotate_and_counter = function(xDegrees, yDegrees, zDegrees, player_or_object)
    local DEG_TO_RAD = math.pi / 180;
    local angles = helper.reverse_rotation(xDegrees * DEG_TO_RAD, yDegrees * DEG_TO_RAD, zDegrees * DEG_TO_RAD);
    local str = ''
    if type(player_or_object) == 'number' then
        str = '*-1 '..xDegrees..' rotationx, *-1 '..
        yDegrees..' rotationy, *-1 '..
        zDegrees..' rotationz, '
    else
        if player_or_object then
            player_or_object:rotationx(xDegrees)
            player_or_object:rotationy(yDegrees)
            player_or_object:rotationz(zDegrees)
        end
    end
    str = str..'*-1 '..(angles[1]*100)..' confusionxoffset, *-1 '..
    (angles[2]*100)..' confusionyoffset, *-1 '..
    (angles[3]*100)..' confusionzoffset';
    return str
end
helper.mod_getCounterRotation = function(xDegrees, yDegrees, zDegrees)
    local DEG_TO_RAD = math.pi / 180;
    local angles = helper.reverse_rotation(xDegrees * DEG_TO_RAD, yDegrees * DEG_TO_RAD, zDegrees * DEG_TO_RAD);
    return {angles[1]*100, angles[2]*100, angles[3]*100}
end

------------------------------
-- insert modhelper stuff here

return helper