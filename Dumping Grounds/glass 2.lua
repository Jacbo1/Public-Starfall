-- Requires the "Proper Clipping" addon: https://steamcommunity.com/sharedfiles/filedetails/?id=2256491552
-- Props of yours that take damage will be cut in half.

--@name Glass 2
--@author Jacbo
--@include spawn_blocking.txt
--@server

local clipLimit = 6

require("spawn_blocking.txt")
hook.add("EntityTakeDamage", "", function(victim, attacker, inflictor, damage, type, position, force)
    if type ~= 1 and inflictor:isPlayer() and victim:getClass() == "prop_physics" and victim:getOwner() == owner() and (force[1] ~= 0 or force[2] ~= 0 or force[3] ~= 0) then
        local clips = victim:getClipping()
        if #clips >= clipLimit or not victim:physicsClipsLeft() then
            victim:remove()
        else
            local pos = victim:worldToLocal(position)
            local normal = victim:worldToLocalVector(force)
            normal = normal:cross(Vector(-normal[2], normal[3], normal[1])):rotateAroundAxis(normal, nil, math.rand(0, 2 * math.pi))
            
            --victim:setCollisionGroup(COLLISION_GROUP.WORLD)
            local copy = prop.create(victim:getPos(), victim:getAngles(), victim:getModel())
            --copy:setCollisionGroup(COLLISION_GROUP.WORLD)
            copy:setVelocity(victim:getVelocity())
            copy:setAngleVelocity(victim:getAngleVelocity())
            copy:setMaterial(victim:getMaterial())
            copy:setColor(victim:getColor())
            copy:setSkin(victim:getSkin())
            copy:setPhysMaterial(victim:getPhysMaterial())
            
            for k, v in pairs(victim:getMaterials()) do
                copy:setSubMaterial(k, v)
            end
            
            try(function()
                for _, clip in ipairs(clips) do
                    copy:addClip(clip.origin, clip.normal, true, true)
                end
                normal:normalize()
                victim:addClip(pos, normal, true, true)
                victim:setFrozen(false)
                copy:addClip(pos, -normal, true, true)
                copy:applyForceOffset(force, position)
            end, function()
                victim:remove()
                copy:remove()
            end)
        end
    end
end)