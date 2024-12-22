--@name Animation Library
--@author Jacbo
-- https://github.com/Jacbo1/Public-Starfall/tree/main/pac3-anim-lib

if CLIENT then
    local table_getKeys = table.getKeys
    local math_lerpVector = math.lerpVector
    local math_lerpAngle = math.lerpAngle
    local pi = math.pi
    local math_cos = math.cos

    anim = {}
    anim.__index = anim
    
    function anim.create(ent, data)
        local frameData = data.FrameData
        
        local v0 = Vector()
        local a0 = Angle()
        local frame0 = {
            BoneInfo = {}
        }
        local info = frame0.BoneInfo
        
        local boneLookup = {}
        for bone, _ in pairs(frameData[1].BoneInfo) do
            local id = ent:lookupBone(bone)
            if id then
                boneLookup[bone] = id
                info[id] = {v0, a0}
            end
        end
        
        for _, frame in ipairs(frameData) do
            if frame.FrameRate == 0 then
                frame.Len = 0
            else
                frame.Len = 1 / frame.FrameRate
            end
            frame.FrameRate = nil
            local bones = frame.BoneInfo
            local t = {}
            for bone, id in pairs(boneLookup) do
                local data = bones[bone]
                t[id] = {
                    Vector(data.MF, -data.MR, data.MU),
                    Angle(data.RR, data.RU, data.RF)
                }
            end
            frame.BoneInfo = t
        end
        
        local t = {
            ent,                    -- Entity
            frameData,              -- Frames
            0,                      -- Time
            data.TimeScale or 1,    -- Speed
            data.StartFrame or 1,   -- Frame
            data.Interpolation,     -- Interpolation mode
            data.RestartFrame or 1, -- Restart frame
            data.StartFrame or 1,   -- Start frame
            frame0,                 -- Reference frame (frame 0)
            frame0.BoneInfo         -- Current pose
        }
        setmetatable(t, anim)
        return t
    end
    
    local playingAnims = {}
    
    -- Delete the animation
    function anim:destroy()
        playingAnims[self] = nil
        self = nil
    end
    
    -- Start playing
    function anim:play()
        playingAnims[self] = true
    end
    
    -- Pause
    function anim:pause()
        playingAnims[self] = nil
    end
    
    -- Stop playing and reset progress
    function anim:stop()
        playingAnims[self] = nil
        self[2] = 0
        self[5] = self[8]
    end
    
    -- Reset
    function anim:restart()
        playingAnims[self] = true
        self[2] = 0
        self[5] = self[8]
    end
    
    -- Set speed
    function anim:setSpeed(speed)
        self[4] = speed
    end
    
    -- Set the frame and time
    function anim:setFrame(frame, time)
        self[2] = time or 0
        self[5] = frame
    end
    
    -- Set the start frame
    function anim:setStart(frame)
        self[8] = frame
    end
    
    -- Set the restart frame
    function anim:setRestart(frame)
        self[7] = frame
    end
    
    -- Set the interpolation mode
    function anim:setInterpolation(mode)
        self[6] = mode
    end
    
    hook.add("think", "anim_lib playAnimations", function()
        local ftime = timer.frametime()
        local destroy = {}
        for anim, _ in pairs(playingAnims) do
            try(function()
                local time = anim[3] + ftime * anim[4]
                local frames = anim[2]
                local len = frames[anim[5]].Len
                while time >= len do
                    time = time - len
                    anim[5] = anim[5] + 1
                    if anim[5] > #frames then
                        anim[5] = anim[7]       -- Set frame to restart frame
                    end
                    len = frames[anim[5]].Len
                end
                anim[3] = time
            
                local ent = anim[1]
                local ratio = time / len
                local frame1 = (frames[anim[5] - 1] or anim[9]).BoneInfo
                local frame2 = frames[anim[5]].BoneInfo
                local curPose = anim[10]
            
                if anim[6] == "none" then
                    -- Not interpolated
                    for bone, info in pairs(frame2) do
                        local cur = curPose[bone]
                        if info[1] ~= cur[1] then
                            ent:manipulateBonePosition(bone, info[1])
                        end
                        if info[2] ~= cur[2] then
                            ent:manipulateBoneAngles(bone, info[2])
                        end
                    end
                else
                    -- Interpolated
                    if anim[6] == "cubic" then
                        -- Cubic interpolation
                        -- Math taken from pac3 github https://github.com/CapsAdmin/pac3/blob/master/lua/pac3/libraries/animations.lua
                        if frames[anim[5] - 2] or anim[5] - 2 == 0 then
                            local frame0 = (frames[anim[5] - 2] or anim[9]).BoneInfo
                            local frame3 = frames[anim[5] + 1 > #frames and anim[7] or anim[5] + 1].BoneInfo
                            local cosRatio = (1 - math_cos(ratio * pi)) * 0.5
                            local ratioSqr = ratio * ratio
                            for bone, info1 in pairs(frame1) do
                                local info0 = frame0[bone]
                                local info2 = frame2[bone]
                                local info3 = frame3[bone]
                                
                                -- Cubic position
                                local pos = info3[1] - info2[1] - info0[1] + info1[1]
                                local pos = pos * ratio * ratioSqr + (info0[1] - info1[1] - pos) * ratioSqr + (info2[1] - info0[1]) * ratio + info1[1]
                                ent:manipulateBonePosition(bone, pos)
                            
                                -- Cubic angles
                                local ang = info3[2] - info2[2] - info0[2] + info1[2]
                                local ang = ang * ratio * ratioSqr + (info0[2] - info1[2] - ang) * ratioSqr + (info2[2] - info0[2]) * ratio + info1[2]
                                ent:manipulateBoneAngles(bone, ang)
                            end
                            return
                        else
                            -- Default to cosine
                            ratio = (1 - math_cos(ratio * pi)) * 0.5
                        end
                    end
                    if anim[6] == "cosine" then
                        ratio = (1 - math_cos(ratio * pi)) * 0.5
                    end
                    
                    for bone, info1 in pairs(frame1) do
                        local info2 = frame2[bone]
                        local cur = curPose[bone]
                        if info1[1] == info2[1] then
                            if info1[1] ~= cur[1] then
                                ent:manipulateBonePosition(bone, info1[1])
                            end
                        else
                            ent:manipulateBonePosition(bone, math_lerpVector(ratio, info1[1], info2[1]))
                        end
                        if info1[2] == info2[2] then
                            if info1[2] ~= cur[2] then
                                ent:manipulateBoneAngles(bone, info1[2])
                            end
                        else
                            ent:manipulateBoneAngles(bone, math_lerpAngle(ratio, info1[2], info2[2]))
                        end
                    end
                end
                curPose = frame1
            end,
            function(err)
                print(err)
                table.insert(destroy, anim)
            end)
        end
        for _, anim in ipairs(destroy) do
            anim:destroy()
        end
    end)
end