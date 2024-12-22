--@name Stewart Platform
--@author Jacbo
--@server

local base
local platform
local init = false
local positionScale = 47.45 * 8
local sideDist = positionScale * 0.5
local forwardDist = math.sqrt(positionScale * positionScale - sideDist * sideDist) * 0.5
local ropeSize = 1
local points = {
    {Vector(-forwardDist, 0, 0), {
        {1, Vector(forwardDist, sideDist, 0)},
        {2, Vector(forwardDist, -sideDist, 0)}
    }},
    {Vector(forwardDist, sideDist, 0), {
        {3, Vector(-forwardDist, 0, 0)},
        {4, Vector(forwardDist, -sideDist, 0)}
    }},
    {Vector(forwardDist, -sideDist, 0), {
        {5, Vector(forwardDist, sideDist, 0)},
        {6, Vector(-forwardDist, 0, 0)}
    }}
}
local center1
local center2

--local holo = holograms.create(chip():getPos(), chip():getAngles(), "models/hunter/geometric/tri1x1eq.mdl")
local holo = holograms.create(chip():getPos(), chip():getAngles(), "models/hunter/plates/plate8x8.mdl")
holo:setColor(Color(255,255,255,100))

hook.add("tick", "", function()
    if init then
        --Run
        local time = timer.curtime()
        local deg2rad = math.pi / 180
        local targetPos, targetAng = localToWorld(
            --Vector(math.cos(time * 60 * deg2rad) * 30, math.sin(time * 60 * deg2rad) * 30, 65 + 10 * math.cos(time * 45 * deg2rad)),
            Vector(math.cos(time * 60 * deg2rad) * 30, math.sin(time * 60 * deg2rad) * 30, 65 + 10 * math.cos(time * 45 * deg2rad)) * 5,
            --Angle(22.5 * math.sin(time * 120 * deg2rad), 180, 22.5 * math.cos(time * 120 * deg2rad)),
            Angle(10 * math.sin(time * 120 * deg2rad), 180, 10 * math.cos(time * 120 * deg2rad)),
            base:obbCenterW(),
            base:getAngles()
        )
        local holoPos = localToWorld(-center2, Angle(), targetPos, targetAng)
        holo:setPos(holoPos)
        holo:setAngles(targetAng)
        constraint.breakAll(base)
        --Calculate lengths
        for _, set1 in ipairs(points) do
            local from = base:localToWorld(set1[1])
            for _, set2 in ipairs(set1[2]) do
                local ropeid = set2[1]
                local to = set2[2]
                --to = localToWorld(to, Angle(), targetPos, targetAng)
                to = localToWorld(to, Angle(), targetPos, targetAng)
                local length = from:getDistance(to)
                --constraint.setRopeLength(ropeid, base, length)
                constraint.rope(ropeid, base, platform, nil, nil, set1[1], set2[2] + center2, length, nil, nil, ropeSize, nil, true)
            end
        end
    elseif prop.canSpawn() then
        --Spawn
        if base == nil then
            base = prop.create(chip():localToWorld(Vector(0,0,10)), chip():getAngles(), "models/hunter/plates/plate8x8.mdl", true)
            --base = prop.create(chip():localToWorld(Vector(0,0,10)), chip():getAngles(), "models/hunter/geometric/tri1x1eq.mdl", true)
            center1 = base:obbCenter()
            base:setPos(base:localToWorld(-center1))
        elseif platform == nil then
            platform = prop.create(chip():localToWorld(Vector(0,0,100)), chip():localToWorldAngles(Angle(0,180,0)), "models/hunter/plates/plate8x8.mdl", false)
            --platform = prop.create(chip():localToWorld(Vector(0,0,50)), chip():localToWorldAngles(Angle(0,180,0)), "models/hunter/geometric/tri1x1eq.mdl", false)
            center2 = platform:obbCenter()
            platform:setPos(platform:localToWorld(-center2))
            init = true
            --Make ropes
            for _, set1 in ipairs(points) do
                set1[1] = set1[1] + center1
                local from = set1[1]
                for _, set2 in ipairs(set1[2]) do
                    --set2[2] = set2[2] + center2
                    local ropeid = set2[1]
                    local to = set2[2]
                    constraint.rope(ropeid, base, platform, nil, nil, from, to + center2, nil, nil, nil, ropeSize, nil, true)
                end
            end
        end
    end
end)