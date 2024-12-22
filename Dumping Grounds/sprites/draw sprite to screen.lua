--@name Sprite Sheet Manager Test
--@author Jacbo
--@shared
--@include spritemngr.txt
--@include funcs.txt

if SERVER then
require("funcs.txt")
funcs.linkToClosestScreen()
else
local mngr = require("spritemngr.txt")

--mngr.loadURL("https://i.imgur.com/5CrjnW3.png", 6, 7, function(mngr)
--local mngr = mngr.loadURL("https://cdn.discordapp.com/attachments/607371740540305424/871450930741129276/1.png", 3, 5)
--mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/871450943282102382/2.png")

--[[local mngr = mngr.loadURL("https://cdn.discordapp.com/attachments/607371740540305424/871451841886572604/1.png", 4, 3)
mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/871451857908826153/2.png")
mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/871451871796150382/3.png")
mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/871451882902683699/4.png")]]

--[[local mngr = mngr.loadURL("https://cdn.discordapp.com/attachments/607371740540305424/871456722873618442/1.png", 8, 8)
mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/871456756759404584/2.png")
mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/871456772580335737/3.png")]]

--local mngr = mngr.loadURL("https://i.imgur.com/5CrjnW3.png", 6, 7)
-- NPC
local delay = 0.03
local frameCount = 93
local mngr = mngr.loadURL("https://cdn.discordapp.com/attachments/607371740540305424/1003732490420244602/1.png", 5, 5)
mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/1003732490881605693/2.png")
mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/1003732491150037042/3.png")
mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/1003732491485577236/4.png")
-- Gigachad
--[[local delay = 0.03
local frameCount = 135
local mngr = mngr.loadURL("https://cdn.discordapp.com/attachments/607371740540305424/1003728067807678475/1.png", 10, 6)
mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/1003728068147413062/2.png")
mngr:appendURL("https://cdn.discordapp.com/attachments/607371740540305424/1003728068482969700/3.png")
]]

local index = 1
local target_index = frameCount
local next_time = timer.systime()

local size = {128*0.7, 114*0.7}
local pos = {256, 256}
pos[1] = math.rand(1, 511-size[1])
pos[2] = math.rand(1, 511-size[2])
local dir = {1/math.sqrt(2), 1/math.sqrt(2)}
if math.rand(0, 1) >= 0.5 then dir[1] = -dir[1] end
if math.rand(0, 1) >= 0.5 then dir[2] = -dir[2] end

local function sin(x, max, min)
    return (math.sin(x) + 1) * 0.5 * (max - min) + min
end

local heightBound = math.round(1080/1920*512/2)*2
local yBound = math.round((512 - heightBound)/2)
local yBound2 = yBound + heightBound

local oldTime = timer.systime()

mngr:setCallback(function()
    oldTime = timer.systime()
    hook.add("render", "", function()
        mngr:drawSprite(
            0, 0, 512, 512,
            --sin(timer.systime()*9, 0.5, 40.49)
            --index
            math.floor(timer.systime() / delay) % frameCount + 1
        )
        
        --[[render.drawRect(0, 0, 512, yBound)
        render.drawRect(0, yBound2, 512, yBound)
        
        local time = timer.systime()
        local delta_time = time - oldTime
        oldTime = time
        
        pos[1] = pos[1] + dir[1] * delta_time * 150
        pos[2] = pos[2] + dir[2] * delta_time * 150
        
        local bounced = false
        
        if (pos[1] <= 0 and dir[1] < 0) or (pos[1]+size[1] >= 511 and dir[1] > 0) then
            dir[1] = -dir[1]
            bounced = true
        end
        if (pos[2] <= yBound and dir[2] < 0) or (pos[2]+size[2] >= yBound2 and dir[2] > 0) then
            dir[2] = -dir[2]
            bounced = true
        end
        
        if bounced then
            if target_index == 1 then
                target_index = frameCount
            else
                target_index = 1
            end
        end
        local ticks = math.floor((time - next_time) / delay)
        index = index + math.clamp(target_index - index, -ticks, ticks)
        next_time = next_time + delay * ticks
        
        mngr:drawSprite(
            --0, 0, 512, 512,
            math.clamp(pos[1], 0, 511-size[1]),
            math.clamp(pos[2], 0, 511-size[2]),
            size[1], size[2],
            --sin(timer.systime()*9, 0.5, 40.49)
            index
            --math.floor(timer.systime() / delay) % frameCount + 1
        )]]
    end)
end)



end