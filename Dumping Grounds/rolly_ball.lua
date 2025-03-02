--@name Rolly Ball
--@author Jacbo
--@include safeNet.txt
--@include spawn_blocking.txt

---------- SETTINGS ----------
local ballRadius = 15
local keys = {
    voice = {
        misc = KEY.H,
        yes = KEY.KEY1,
        no = KEY.KEY2
    },
    anchor = KEY.J
}
------------------------------

local net = require("safeNet.txt")
require("spawn_blocking.txt")

if SERVER then
    --require("libs/ezsound.txt")
    
    ---------- SETTINGS ----------
    local baseForce = 40000
    local shiftForce = 80000
    local ballMass = 100
    local hullMinZ = ballRadius / 2
    local frictionCoef = 0.1
    local physicsSteps = 4
    local headScale = Vector(1)
    local bounciness = 0.3
    local bounceThreshold = 30
    local soundSettings = {
        impact = {
            soft = {
                minVel = 100,
                maxVel = 400,
                minVol = 0,
                maxVol = 1
            },
            hard = {
                minVel = 400,
                maxVel = 800,
                minVol = 1,
                maxVol = 1
            }
        },
        scrape = {
            minVelIn = 0,
            maxVelIn = 10,
            minVelAlong = 0,
            maxVelAlong = 600,
            minVol = 0,
            maxVol = 1
        },
        roll = {
            minVel = 0,
            maxVel = 600,
            minVol = 0,
            maxVol = 0.5
        }
    }
    ------------------------------
    --soundSettings.scrape.minDotL = math.acos(soundSettings.scrape.minDot) / math.pi
    --soundSettings.scrape.maxDotL = math.acos(soundSettings.scrape.maxDot) / math.pi
    
    local function remap(t, inMin, inMax, outMin, outMax)
        return math.clamp(math.remap(t, inMin, inMax, outMin, outMax), outMin, outMax)
    end
    
    local soundEnts = {}
    local function playSound(path, duration)
        if not sound.canCreate() or #soundEnts == 0 then return nil end
        local ent = table.remove(soundEnts, 1)
        local snd = sound.create(ent, path, true)
        snd:play()
        if duration then
            timer.simple(duration, function()
                snd:destroy()
                table.insert(soundEnts, ent)
            end)
        else
            table.insert(soundEnts, ent)
        end
        
        return snd
    end
    
    corWrap(function()
        local sounds = {
            objects = {},
            soft = {
                {
                    path = "physics/metal/metal_box_impact_soft1.wav",
                    dur = 0.531
                },
                {
                    path = "physics/metal/metal_box_impact_soft2.wav",
                    dur = 0.329
                },
                {
                    path = "physics/metal/metal_box_impact_soft3.wav",
                    dur = 0.453
                }
            },
            hard = {
                {
                    path = "physics/metal/metal_box_impact_hard1.wav",
                    dur = 0.723
                },
                {
                    path = "physics/metal/metal_box_impact_hard2.wav",
                    dur = 0.659
                },
                {
                    path = "physics/metal/metal_box_impact_hard3.wav",
                    dur = 0.601
                }
            },
            scrape = "physics/metal/metal_box_scrape_smooth_loop1.wav",
            roll = {
                grass = {
                    path = "physics/cardboard/cardboard_box_scrape_rough_loop1.wav",
                    mat = {
                        MAT.GRASS,
                        MAT.FOLIAGE
                    }
                },
                hard_rough = {
                    path = 'physics/metal/paintcan_roll_loop1.wav', --"simulated_vehicles/sfx/tire_damaged.wav",
                    mat = {
                        MAT.CONCRETE
                    }
                },
                flesh = {
                    path = "physics/body/body_medium_scrape_smooth_loop1.wav",
                    mat = {
                        MAT.FLESH,
                        MAT.BLOODYFLESH,
                        MAT.ALIENFLESH,
                        MAT.ANTLION
                    }
                },
                plastic = {
                    path = 'physics/metal/paintcan_roll_loop1.wav',
                    mat = {
                        MAT.PLASTIC,
                        MAT.TILE,
                        MAT.METAL,
                        MAT.GRATE,
                        MAT.CLIP,
                        MAT.COMPUTER,
                        MAT.VENT
                    }
                },
                dirt = {
                    path = 'simulated_vehicles/sfx/dirt_roll.wav',
                    mat = {
                        MAT.DIRT,
                        MAT.SAND
                    }
                },
                default = {
                    path = "physics/plastic/plastic_barrel_roll_loop1.wav"
                }
            },
            voice = {
                no = {
                    {
                        path = "buttons/button10.wav",
                        dur = 0.189
                    },
                    {
                        path = "buttons/button11.wav",
                        dur = 0.462
                    },
                    {
                        path = "buttons/button2.wav",
                        dur = 0.697
                    },
                    {
                        path = "buttons/button8.wav",
                        dur = 0.638
                    },
                    {
                        path = "buttons/weapon_cant_buy.wav",
                        dur = 0.427
                    }
                },
                yes = {
                    {
                        path = "buttons/button24.wav",
                        dur = 0.203
                    },
                    {
                        path = "npc/roller/remote_yes.wav",
                        dur = 0.39
                    }
                },
                misc = {
                    {
                        path = "buttons/button18.wav",
                        dur = 0.191
                    },
                    {
                        path = "buttons/blip1.wav",
                        dur = 0.109
                    },
                    {
                        path = "buttons/button7.wav",
                        dur = 0.227
                    },
                    {
                        path = "buttons/combine_button1.wav",
                        dur = 0.594
                    },
                    {
                        path = "buttons/combine_button2.wav",
                        dur = 0.893
                    },
                    {
                        path = "buttons/combine_button3.wav",
                        dur = 0.745
                    },
                    {
                        path = "buttons/combine_button5.wav",
                        dur = 0.825
                    },
                    {
                        path = "buttons/combine_button7.wav",
                        dur = 0.616
                    },
                    {
                        path = "buttons/combine_button_locked.wav",
                        dur = 0.778
                    },
                    {
                        path = "npc/roller/mine/combine_mine_deploy1.wav",
                        dur = 0.412
                    },
                    {
                        path = "npc/roller/mine/rmine_blip3.wav",
                        dur = 0.224
                    },
                    {
                        path = "npc/roller/mine/rmine_reprogram.wav",
                        dur = 1.435
                    }
                }
            },
            anchor = {
                on = {
                    path = "npc/roller/blade_cut.wav",
                    dur = 0.107
                },
                off = {
                    path = "npc/roller/blade_in.wav",
                    dur = 0.227
                },
                cant = {
                    path = "npc/roller/code2.wav",
                    dur = 0.491
                }
            }
        }
        
    local anchored = false
    local anchoredToEnt = false
    local anchoredEnt = nil
    local anchoredPos = Vector()
    local anchoredAngle = Angle()
    local anchoredGroundAngle = Angle()
    local groundEnt = nil
    local groundNormal = Vector(0,0,1)
    
    local hullMin = Vector(-ballRadius, -ballRadius, hullMinZ)
    local hullMax = Vector(ballRadius, ballRadius, ballRadius * 2)
    local seat = prop.createSeat(chip():getPos() + Vector(-45,0,30), Angle(0, -90, 0), "models/props_phx/carseat2.mdl", true)
    local ballPos = chip():getPos()
    local ball = hologram.create(ballPos + Vector(0,0,ballRadius), Angle(), "models/XQM/Rails/trackball_1.mdl", Vector(ballRadius / 15))
    table.insert(soundEnts, ball)
    local anchor = hologram.create(ballPos, Angle(), "models/props_combine/combine_mine01.mdl", Vector(ballRadius / 15))
    anchor:setNoDraw(true)
    local anchorCenterOffset = Vector(0, 0, -anchor:obbCenter()[3] * ballRadius / 15 - ballRadius * 0.6)
    
    -- Create head
    local head = hologram.create(ballPos, Angle(), "models/holograms/hq_sphere.mdl", headScale)
    table.insert(soundEnts, head)
    do
        head:setColor(Color(180,180,180))
        head:setClip(1, true, Vector(), Vector(0,0,1), head)
        local holo = hologram.create(ballPos, Angle(180,0,0), "models/holograms/cplane.mdl", headScale)
        table.insert(soundEnts, holo)
        holo:setParent(head)
        
        local eyeSize = 0.25 * headScale
        local dir = Vector(1):getNormalized() * (headScale * 6 - eyeSize * 4)
        local holo2 = hologram.create(ballPos + dir, Angle(), "models/holograms/hq_sphere.mdl", eyeSize)
        table.insert(soundEnts, holo2)
        holo2:setColor(Color(0,0,0))
        holo2:setParent(head)
        
        dir = Vector(1,-1,1):getNormalized() * (headScale * 6 - eyeSize * 4)
        local holo3 = hologram.create(ballPos + dir, Angle(), "models/holograms/hq_sphere.mdl", eyeSize)
        table.insert(soundEnts, holo3)
        holo3:setColor(Color(0,0,0))
        holo3:setParent(head)
    end
    
    net.init(function(ply)
        net.start("send ents")
        net.writeEntity(ball)
        net.writeEntity(head)
        net.writeEntity(anchor)
        net.send(ply)
    end)
    
    local headZ = 0
    local vel = Vector()
    local onGround = true
    local user
    local oldUser
    local headYaw = 0
    local angVel = {Vector(1,0,0), 0}
    
    local function Unanchor()
        anchor:setNoDraw(true)
        anchor:setPos(chip():getPos())
        anchored = false
        anchoredToEnt = false
        
        local snd = sounds.anchor.off
        playSound(snd.path, snd.dur)
    end
    
    hook.add("think", "", function()
        local oldPos = ballPos
        local ftime = timer.frametime()
        vel = vel + physenv.getGravity() * ftime
        
        user = seat:getDriver()
        
        -- Handle user changing
        if user ~= oldUser then
            if user and user:isValid() and user:isPlayer() then
                -- Enter new user
                net.start("enter")
                net.writeEntity(ball)
                net.send(user)
            end
            
            if oldUser and oldUser:isValid() and oldUser:isPlayer() then
                -- Exit oldUser
                net.start("exit")
                net.send(oldUser)
            end
            
            oldUser = user
        end
        
        if user and user:isValid() and user:isPlayer() then
            local camAng = Angle(0, user:getEyeAngles()[2], 0)
            headYaw = camAng[2]
            if onGround then
                -- Handle user input
                local move = Vector(
                    (user:keyDown(IN_KEY.FORWARD) and 1 or 0) - (user:keyDown(IN_KEY.BACK) and 1 or 0),
                    (user:keyDown(IN_KEY.MOVELEFT) and 1 or 0) - (user:keyDown(IN_KEY.MOVERIGHT) and 1 or 0),
                    0) * (user:keyDown(IN_KEY.SPEED) and shiftForce or baseForce)
                move = localToWorld(move, Angle(), Vector(), camAng)
                vel = vel + move / ballMass * ftime
            end
        end
        
        local downHullTrace
        
        if anchored and anchoredToEnt and (not anchoredEnt or not anchoredEnt:isValid()) then
            -- Anchor ent deleted
            Unanchor()
        end
        
        if anchored then
            -- Anchored
            if anchoredToEnt then
                -- Anchored to entity
                ballPos = anchoredEnt:localToWorld(anchoredPos) - Vector(0, 0, ballRadius)
                ball:setAngles(anchoredEnt:localToWorldAngles(anchoredAngle))
                local angVel = anchoredEnt:getAngleVelocity()
                local angVelLength = angVel:getLength()
                local pointVel
                if angVelLength > 0.001 then
                    pointVel = (angVel / angVelLength):cross(anchoredPos + anchoredEnt:getMassCenter()) * angVelLength * math.pi/180
                else
                    pointVel = Vector()
                end
                
                vel = anchoredEnt:getVelocity() + anchoredEnt:localToWorldVector(pointVel)
                local ang = anchoredEnt:localToWorldAngles(anchoredGroundAngle)
                anchor:setAngles(ang)
                anchor:setPos(localToWorld(anchorCenterOffset, Angle(), ballPos + Vector(0,0,ballRadius), ang))
                anchor:setLocalVelocity(vel)
            else
                -- Anchored to world
                ballPos = anchoredPos
                ball:setAngles(anchoredAngle)
                vel = Vector(0,0,0)
            end
            
        else
            -- Not anchored
            -- Handle collisions
            local impactPlayed = false
            local collided = false
            local maxScrapeVol = 0
            local dt = ftime / physicsSteps
            local velf = vel * dt
            for i = 1, physicsSteps do
                local filter = {}
                local hullTrace = trace.hull(ballPos, ballPos + velf, hullMin, hullMax)
                while hullTrace.StartSolid and hullTrace.Entity and hullTrace.Entity:isValid() do
                    table.insert(filter, hullTrace.Entity)
                    hullTrace = trace.hull(ballPos, ballPos + velf, hullMin, hullMax, filter)
                end
                ballPos = ballPos + hullTrace.Fraction * velf
            
                local dot = vel:dot(hullTrace.HitNormal)
                if dot < 0 then
                    collided = true
                    local absDot = math.abs(dot)
                    
                    -- Try to play impact sound
                    if not impactPlayed then
                        if absDot >= soundSettings.impact.soft.minVel and absDot < soundSettings.impact.soft.maxVel then
                            -- Play soft impact sound
                            impactPlayed = true
                            local snd = sounds.soft[math.random(#sounds.soft)]
                            snd = playSound(snd.path, snd.dur)
                            if snd then snd:setVolume(remap(absDot, soundSettings.impact.soft.minVel, soundSettings.impact.soft.maxVel, soundSettings.impact.soft.minVol, soundSettings.impact.soft.maxVol)) end
                        elseif absDot >= soundSettings.impact.hard.minVel then
                            -- Play hard impact sound
                            impactPlayed = true
                            local snd = sounds.hard[math.random(#sounds.hard)]
                            snd = playSound(snd.path, snd.dur)
                            if snd then snd:setVolume(remap(absDot, soundSettings.impact.hard.minVel, soundSettings.impact.hard.maxVel, soundSettings.impact.hard.minVol, soundSettings.impact.hard.maxVol)) end
                        end
                    end
                    
                    -- Try to play scraping sound
                    if not impactPlayed and not sounds.objects.scrape then
                        sounds.objects.scrape = playSound(sounds.scrape)
                    end
                        
                    if sounds.objects.scrape then
                        local inVal = remap(absDot, soundSettings.scrape.minVelIn, soundSettings.scrape.maxVelIn, 0, 1)
                        local alongVal = remap((vel - dot * hullTrace.HitNormal):getLength(), soundSettings.scrape.minVelAlong, soundSettings.scrape.maxVelAlong, 0, 1)
                        maxScrapeVol = math.max(maxScrapeVol, math.lerp(inVal * alongVal, soundSettings.scrape.minVol, soundSettings.scrape.maxVol))
                    end
                    
                    if -dot > bounceThreshold then
                        -- Bounce
                        vel = (vel - dot * hullTrace.HitNormal) * (1 - bounciness) + (vel - 2 * dot * hullTrace.HitNormal) * bounciness
                        local dotf = velf:dot(hullTrace.HitNormal)
                        velf = (velf - dotf * hullTrace.HitNormal) * (1 - bounciness) + (velf - 2 * dotf * hullTrace.HitNormal) * bounciness
                    else
                        -- Don't bounce
                        vel = vel - dot * hullTrace.HitNormal
                        velf = velf - velf:dot(hullTrace.HitNormal) * hullTrace.HitNormal
                    end
                end
            end
            
            if sounds.objects.scrape then
                if not collided then
                    sounds.objects.scrape:destroy()
                    sounds.objects.scrape = nil
                else
                    sounds.objects.scrape:setVolume(maxScrapeVol)
                end
            end
    
            filter = {}
            downHullTrace = trace.hull(ballPos, ballPos - Vector(0, 0, hullMinZ), hullMin, hullMax)
            while downHullTrace.StartSolid and downHullTrace.Entity and downHullTrace.Entity:isValid() do
                table.insert(filter, downHullTrace.Entity)
                downHullTrace = trace.hull(ballPos, ballPos - Vector(0, 0, hullMinZ), hullMin, hullMax, filter)
            end
            ballPos = ballPos + Vector(0, 0, (1 - downHullTrace.Fraction) * hullMinZ)
            onGround = downHullTrace.Hit
            if downHullTrace.HitWorld then
                groundEnt = nil
            else
                groundEnt = downHullTrace.Entity
            end
            
            if downHullTrace.Hit then
                groundNormal = downHullTrace.HitNormal
            end
            
            dot = vel:dot(downHullTrace.HitNormal)
            if dot < 0 then
                -- Try to play impact sound
                if not impactPlayed then
                    local absDot = math.abs(dot)
                    if absDot >= soundSettings.impact.soft.minVel and absDot < soundSettings.impact.soft.maxVel then
                        -- Play soft impact sound
                        impactPlayed = true
                        local snd = sounds.soft[math.random(#sounds.soft)]
                        snd = playSound(snd.path, snd.dur)
                        if snd then snd:setVolume(remap(absDot, soundSettings.impact.soft.minVel, soundSettings.impact.soft.maxVel, soundSettings.impact.soft.minVol, soundSettings.impact.soft.maxVol)) end
                    elseif absDot >= soundSettings.impact.hard.minVel then
                        -- Play hard impact sound
                        impactPlayed = true
                        local snd = sounds.hard[math.random(#sounds.hard)]
                        snd = playSound(snd.path, snd.dur)
                        if snd then snd:setVolume(remap(absDot, soundSettings.impact.hard.minVel, soundSettings.impact.hard.maxVel, soundSettings.impact.hard.minVol, soundSettings.impact.hard.maxVol)) end
                    end
                end
                
                if -dot > bounceThreshold then
                    -- Bounce
                    vel = (vel - dot * downHullTrace.HitNormal) * (1 - bounciness) + (vel - 2 * dot * downHullTrace.HitNormal) * bounciness
                    local dotf = velf:dot(downHullTrace.HitNormal)
                    velf = (velf - dotf * downHullTrace.HitNormal) * (1 - bounciness) + (velf - 2 * dotf * downHullTrace.HitNormal) * bounciness
                else
                    -- Don't bounce
                    vel = vel - dot * downHullTrace.HitNormal
                    velf = velf - velf:dot(downHullTrace.HitNormal) * downHullTrace.HitNormal
                end
            end
            
            -- Handle friction
            if onGround then
                local friction = frictionCoef * ballMass * vel:getLength()
                vel[1] = vel[1] - math.sign(vel[1]) * math.min(math.abs(vel[1]), friction) * ftime
                vel[2] = vel[2] - math.sign(vel[2]) * math.min(math.abs(vel[2]), friction) * ftime
            end
        end
            
        -- Try to play rolling sound
        if downHullTrace and not anchored and onGround and vel:getLengthSqr() > 0.01 * 0.01 then
            local type = 'default'
            for k, v in pairs(sounds.roll) do
                if k == 'default' then continue end
                if table.hasValue(v.mat, downHullTrace.MatType) then
                    type = k
                end
            end
            
            if sounds.objects.roll and sounds.objects.rollType ~= type then
                sounds.objects.roll:destroy()
                sounds.objects.roll = nil
            end
            
            if not sounds.objects.roll then
                sounds.objects.roll = playSound(sounds.roll[type].path)
                sounds.objects.rollType = type
            end
                    
            if sounds.objects.roll then
                sounds.objects.roll:setVolume(remap((vel - downHullTrace.HitNormal * dot):getLength(), soundSettings.roll.minVel, soundSettings.roll.maxVel, soundSettings.roll.minVol, soundSettings.roll.maxVol))
            end
        elseif sounds.objects.roll then
            sounds.objects.roll:destroy()
            sounds.objects.roll = nil
        end
        
        ball:setPos(ballPos + Vector(0, 0, ballRadius))
        
        -- Handle head angles
        headAng = Angle(0, headYaw, 0)
        if vel ~= Vector() then
            -- Applying force so rotate
            local length = vel:getLength()
            if length > 0.01 then
                local axis = (vel / length):cross(Vector(0,0,1))
                local rad = -length / ballRadius
                headAng = headAng:rotateAroundAxis(axis, nil, rad / 100)
            end
        end
        head:setAngles(headAng)
        
        -- Handle head position
        local velShift = vel[3] * ftime * 0.75
        if onGround then velShift = math.max(velShift, 0) end
        headZ = math.max(0, headZ - velShift - (headZ * 10 * ftime) ^ 2)
        head:setPos(ballPos + Vector(0, 0, ballRadius + headZ) + headAng:getUp() * ballRadius)
        
        -- Handle angles
        if not anchored then
            if onGround then
                -- On ground
                if oldPos and oldPos ~= ballPos then
                    -- Moved so rotate
                    local dir = ballPos - oldPos
                    local length = dir:getLength()
                    local axis = (dir / length):cross(Vector(0,0,1))
                    local rad = -length / ballRadius
                    angVel = {axis, rad}
                    ball:setAngles(ball:getAngles():rotateAroundAxis(axis, nil, rad))
                else
                    -- Didn't move so don't rotate
                    angVel[2] = 0
                end
            elseif angVel[2] ~= 0 and angVel[2] == angVel[2] and angVel[2] ~= 1/0 and angVel[2] ~= -1/0 then
                -- Midair and rotating
                --angVel[2] = angVel[2] * (1 - math.sqrt(ftime * ftime / 8)) -- This slows down the rolling while mid-air
                ball:setAngles(ball:getAngles():rotateAroundAxis(angVel[1], nil, angVel[2]))
            end
        end
        
        ball:setLocalVelocity(vel)
        head:setLocalVelocity(vel)
    end)
    
    hook.add("KeyPress", "", function(ply, key)
        if not onGround or ply ~= user or key ~= IN_KEY.JUMP then return end
        
        -- Jump
        vel = vel + Vector(0, 0, 175)
    end)
    
    -- Handle voice sounds
    net.receive("voice", function()
        local soundTable = sounds.voice[net.readString()]
        local snd = soundTable[math.random(#soundTable)]
        snd = playSound(snd.path, snd.dur)
    end)
    
    -- Toggle anchoring
    net.receive("anchor", function()
        if anchored then
            -- Unanchor
            Unanchor()
            return
        end
        
        -- Try anchor
        if not onGround then
            -- Can't anchor
            local snd = sounds.anchor.cant
            playSound(snd.path, snd.dur)
            return
        end
        
        -- Anchor
        anchor:setNoDraw(false)
        angVel[2] = 0
        anchored = true
        anchoredToEnt = groundEnt and groundEnt:isValid()
        local _, groundAngle = localToWorld(Vector(), Angle(90,0,0), Vector(), groundNormal:getAngle())
        if anchoredToEnt then
            -- Anchor to entity
            anchoredEnt = groundEnt
            anchoredPos = anchoredEnt:worldToLocal(ballPos + Vector(0,0,ballRadius))
            anchoredAngle = anchoredEnt:worldToLocalAngles(ball:getAngles())
            anchoredGroundAngle = anchoredEnt:worldToLocalAngles(groundAngle)
            anchor:setPos(ballPos)
        else
            -- Anchor to world
            anchoredEnt = nil
            anchoredPos = ballPos
            anchoredAngle = ball:getAngles()
            anchoredGroundAngle = groundAngle
            anchor:setLocalVelocity(Vector())
            anchor:setAngles(anchoredGroundAngle)
            anchor:setPos(localToWorld(anchorCenterOffset, Angle(), ballPos + Vector(0,0,ballRadius), anchoredGroundAngle))
        end
        
        local snd = sounds.anchor.on
        playSound(snd.path, snd.dur)
    end)
    end)
else -- CLIENT
    local ball
    local camPos
    
    net.receive("enter", function()
        -- Local player is now driving
        net.readEntity(function(ent)
            ball = ent
            camPos = ball:getPos()
            hook.add("think", "enter", function()
                if player():inVehicle() then
                    enableHud(player(), true)
                    hook.remove("think", "enter")
                end
            end)
        end)
        
        hook.add("inputPressed", "", function(key)
            local type = nil
            if key == keys.voice.misc then type = "misc"
            elseif key == keys.voice.yes then type = "yes"
            elseif key == keys.voice.no then type = "no"
            elseif key == keys.anchor then
                net.start("anchor")
                net.send()
            end
            
            if not type then return end
            net.start("voice")
            net.writeString(type)
            net.send()
        end)
    end)
    
    net.receive("exit", function()
        -- Local player is no longer driving
        try(function()
            enableHud(player(), false)
        end)
        hook.remove("inputPressed", "")
        hook.remove("think", "enter")
    end)
    
    hook.add("calcview", "", function(_, camAng)
        -- Control camera
        local ballCenter = ball:getPos()
        local targetPos = ballCenter - camAng:getForward() * 100 * ballRadius / 15
        camPos = camPos + (targetPos - camPos) * 8 * timer.frametime()
        local dir = camPos - ballCenter
        local length = dir:getLength()
        local adjustedLength = length + 5
        local camTrace = trace.trace(ballCenter, ballCenter + dir * adjustedLength / length)
        camPos = ballCenter + dir * (length - adjustedLength + adjustedLength * camTrace.Fraction) / length
        return {
            origin = camPos
        }
    end)
    
    net.receive("send ents", function()
        try(function()
        local function celShade(ent)
            pcall(function()
                local og = ent:getMaterials()[1]
                local mat = material.create("VertexLitGeneric")
                mat:setTexture("$basetexture", material.getTexture(og, "$basetexture"))
                local bump = material.getTexture(og, "$bumpmap")
                if bump ~= "error" then mat:setTexture("$bumpmap", bump) end
                mat:setInt("$phong", 1)
                mat:setFloat("$phongboost", 0)
                mat:setTextureURL("$lightwarptexture", "https://i.imgur.com/llNfLZi.png", function(_, _, width, height, layout)
                    layout(0, 0, 1024, 1024)
                end, function()
                    ent:setMaterial("!" .. mat:getName())
                end)
            end)
        end
        
        for i = 1, 3 do
            net.readHologram(function(ent)
                celShade(ent)
            end)
        end
        end)
    end)
    
    net.init()
end
