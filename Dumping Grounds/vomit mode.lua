-- Connect to HUD component and activate HUD :)
-- Quaternion math from Expression 2 repo because Starfall quat math was broken at the time. Can't be bothered to change it back.

--@name Vomit Mode
--@author Jacbo
--@client
--@include funcs.txt

--if player() ~= owner() then return end

--Quat stuff
local deg2rad = math.pi / 180
local rad2deg = 180 / math.pi

local function qmul(lhs, rhs)
    local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
    local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
    return {
        lhs1 * rhs1 - lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
        lhs1 * rhs2 + lhs2 * rhs1 + lhs3 * rhs4 - lhs4 * rhs3,
        lhs1 * rhs3 + lhs3 * rhs1 + lhs4 * rhs2 - lhs2 * rhs4,
        lhs1 * rhs4 + lhs4 * rhs1 + lhs2 * rhs3 - lhs3 * rhs2
    }
end

local function qNormalize(q)
    local len = math.sqrt(q[1]^2 + q[2]^2 + q[3]^2 + q[4]^2)
    q[1] = q[1]/len
    q[2] = q[2]/len
    q[3] = q[3]/len
    q[4] = q[4]/len
end

local function qDot(q1, q2)
    return q1[1]*q2[1] + q1[2]*q2[2] + q1[3]*q2[3] + q1[4]*q2[4]
end

local function angToQuat(ang)
    local p, y, r = ang[1], ang[2], ang[3]
    p = p*deg2rad*0.5
    y = y*deg2rad*0.5
    r = r*deg2rad*0.5
    local qr = {math.cos(r), math.sin(r), 0, 0}
    local qp = {math.cos(p), 0, math.sin(p), 0}
    local qy = {math.cos(y), 0, 0, math.sin(y)}
    return qmul(qy,qmul(qp,qr))
end

local function quatToAng(quat)
    local l = math.sqrt(quat[1]*quat[1]+quat[2]*quat[2]+quat[3]*quat[3]+quat[4]*quat[4])
    if l == 0 then return Angle() end
    local q1, q2, q3, q4 = quat[1]/l, quat[2]/l, quat[3]/l, quat[4]/l
    
    local x = Vector(q1*q1 + q2*q2 - q3*q3 - q4*q4,
        2*q3*q2 + 2*q4*q1,
        2*q4*q2 - 2*q3*q1)

    local y = Vector(2*q2*q3 - 2*q4*q1,
        q1*q1 - q2*q2 + q3*q3 - q4*q4,
        2*q2*q1 + 2*q3*q4)

    local ang = x:getAngle()
    
    if ang.p > 180 then ang.p = ang.p - 360 end
    if ang.y > 180 then ang.y = ang.y - 360 end

    local yyaw = Vector(0,1,0)
    yyaw:rotate(Angle(0,ang.y,0))

    local roll = math.acos(math.clamp(y:dot(yyaw), -1, 1))*rad2deg

    local dot = q2*q1 + q3*q4
    if dot < 0 then roll = -roll end
    
    return Angle(ang.p, ang.y, roll)
end

local function slerp(q0, q1, t)
    local dot = qDot(q0, q1)

    if dot < 0 then
        q1 = {-q1[1], -q1[2], -q1[3], -q1[4]}
        dot = -dot
    end

    -- Really small theta, transcendental functions approximate to linear
    if dot > 0.9995 then
        local lerped = {
            q0[1] + t*(q1[1] - q0[1]),
            q0[2] + t*(q1[2] - q0[2]),
            q0[3] + t*(q1[3] - q0[3]),
            q0[4] + t*(q1[4] - q0[4]),
        }
        qNormalize(lerped)
        return quatToAng(lerped)
    end

    local theta_0 = math.acos(dot)
    local theta = theta_0*t
    local sin_theta = math.sin(theta)
    local sin_theta_0 = math.sin(theta_0)

    local s0 = math.cos(theta) - dot * sin_theta / sin_theta_0
    local s1 = sin_theta / sin_theta_0

    local slerped = {
        q0[1]*s0 + q1[1]*s1,
        q0[2]*s0 + q1[2]*s1,
        q0[3]*s0 + q1[3]*s1,
        q0[4]*s0 + q1[4]*s1,
    }
    qNormalize(slerped)
    return slerped
end
--

local funcs = require("funcs.txt")

setupPermissionRequest({ "render.renderscene", "render.renderView" }, "See an example of render.renderView.", true)
local permissionSatisfied = hasPermission("render.renderView")

local rtName = "vomit_rt"
render.createRenderTarget(rtName)

local mat = material.create("gmodscreenspace")
mat:setTextureRenderTarget("$basetexture", rtName)

local scrW, scrH
local screenEnt
local first = true
--local quat1 = Angle():getQuaternion()
--local quat2 = Angle():getQuaternion()
local quat1 = angToQuat(Angle())
local quat2 = angToQuat(Angle(1))
local quatLerp = 1
local quatLerpMult = 1
local oldTime = nil

local function sin(rad, min, max)
    return (math.sin(rad) + 1)/2 * (max - min) + min
end

local function cos(rad, min, max)
    return (math.cos(rad) + 1)/2 * (max - min) + min
end

local connected = false

hook.add("hudconnected", "", function()
    connected = true
end)

hook.add("huddisconnected", "", function()
    connected = false
end)

hook.add("renderscene", "render_view", function()
    if not permissionSatisfied or not connected then return end
        local time = timer.curtime()
        local timeDelta
        if oldTime == nil then
            timeDelta = 0
        else
            timeDelta = time - oldTime
        end
        oldTime = time
        if first then
            first = false
            scrW, scrH = render.getGameResolution()
        end
        render.selectRenderTarget(rtName)
        
        --render.enableClipping(true)
        if quatLerp >= 1 then
            quatLerp = 0
            quatLerpMult = 0.75
            --quat1 = quat2:clone()
            --quat1 = quat2:getEulerAngle():getQuaternion()
            quat1 = {quat2[1], quat2[2], quat2[3], quat2[4]}
            --quat1 = angToQuat(quatToAng(quat2))
            --quat2 = funcs.randAng(-22.5, 22.5):getQuaternion()
            quat2 = angToQuat(funcs.randAng(-22.5, 22.5))
            --printTable(quat2)
        end
        quatLerp = math.clamp(quatLerp + timeDelta * quatLerpMult, 0, 1)
        --print(math.round(1 - cos(quatLerp * math.pi, 0, 1), 2) .. " / " .. math.round(quatLerp, 2))
        
        local clipNormal = eyeVector()
        --render.pushCustomClipPlane(clipNormal, (eyePos() + clipNormal):dot(clipNormal))
        local aspectMult = sin(time*2, 0.75, 1.25)
        --local _, ang = localToWorld(Vector(), math.slerpQuaternion(quat1, quat2, 1 - cos(quatLerp * math.pi, 0, 1)):getEulerAngle(), Vector(), eyeAngles())
        --local _, ang = localToWorld(Vector(), math.slerpQuaternion(quat1, quat2, quatLerp):getEulerAngle(), Vector(), eyeAngles())
        --local ang = math.slerpQuaternion(quat1, quat2, quatLerp):getEulerAngle()
        --local ang = quatToAng(slerp(quat1, quat2, sin(quatLerp * math.pi, 0, 1)))
        local _, ang = localToWorld(Vector(), quatToAng(slerp(quat1, quat2, 1 - cos(quatLerp * math.pi, 0, 1))), Vector(), eyeAngles())
        render.renderView({
            origin = eyePos(),
            angles = ang,
            aspectratio = scrW / scrH * aspectMult,
            x = 0,
            y = 0,
            w = 1024,
            h = 1024,
            drawviewmodel = false,
            drawviewer = false,
            fov = sin(time*1.5, 60, 120)
        })
        
        --render.popCustomClipPlane()
        render.drawTexturedRect(0,0,1024,1024)
end)

hook.add("DrawHud", "render_screen", function()
    if not permissionSatisfied then
        render.setColor(Color(255, 255, 255))
        render.setFont("DermaLarge")
        render.drawText(256, 256 - 32, "Use me", 1)
        return
    end

    --[[render.pushViewMatrix({ type = "2D" })
    render.setMaterial(mat)
    render.setColor(Color(255, 255, 255))
    --render.drawTexturedRect(scrW, 0, -scrW, scrH)
    render.drawTexturedRect(0, 0, scrW, scrH)
    render.popViewMatrix()]]
    
    render.setRenderTargetTexture(rtName)
    render.drawTexturedRect(0,0,scrW,scrH)
end)

--[[hook.add("render", "render_screen", function()
    if not permissionSatisfied then
        render.setColor(Color(255, 255, 255))
        render.setFont("DermaLarge")
        render.drawText(256, 256 - 32, "Use me", 1)
        return
    end

    if render.isInRenderView() then
        render.setColor(Color(0, 0, 0))
        render.drawRect(0, 0, 512, 512)
        render.setColor(Color(255, 255, 0))
        render.setFont("DermaLarge")
        render.drawText(256, 256 - 32, "RenderView", 1)
        return
    end

    scrW, scrH = render.getGameResolution()
    screenEnt = screenEnt or render.getScreenEntity()

    render.pushViewMatrix({ type = "2D" })
    render.setMaterial(mat)
    render.setColor(Color(255, 255, 255))
    render.drawTexturedRect(scrW, 0, -scrW, scrH)
    render.popViewMatrix()
end)]]

hook.add("permissionrequest", "", function()
    permissionSatisfied = hasPermission("render.renderView")
end)