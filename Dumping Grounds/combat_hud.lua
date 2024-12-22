--@name Combat HUD
--@author Jacbo
--@client

if player() ~= owner() then return end

--local bulletColor = Color(248, 216, 50, 255)
local bulletColor = Color(255, 255, 255, 255)
local firedBulletColorR = 128
local firedBulletColorG = 128
local firedBulletColorB = 128
local gravity = 0.015
--  1  2  3  4  5   6   7    8     9
-- {x, y, w, h, dx, dy, ang, dang, alpha}
local fallingBullets = {}
local oldClip = 0
local oldMaxClip = 0

local render_drawRect = render.drawRect
local render_drawTexturedRectRotated = render.drawTexturedRectRotated
local render_setRGBA = render.setRGBA

hook.add("drawhud", "", function()
    local ftime = timer.frametime()
    local width, height = render.getGameResolution()
    local rowMaxWidth = width * 0.9
    
    local weapon = player():getActiveWeapon()
    local maxClip = weapon:maxClip1()
    local clip = weapon:clip1()
    if maxClip > 0 then
        local gravity = height * gravity * ftime
        
        local bulletY = height * 0.54
        local bulletW = height * 0.005
        bulletW = math.min(rowMaxWidth / (maxClip * 1.75), bulletW)
        local bulletH = bulletW * 3
        local bulletSpacing = bulletW * 0.75
        
        local bulletX = (width - bulletW * clip - bulletSpacing * (clip - 1)) / 2
        
        -- Draw unfired bullets
        render.setColor(bulletColor)
        local interval = bulletW + bulletSpacing
        for i = 0, clip - 1 do
            render_drawRect(i * interval + bulletX, bulletY, bulletW, bulletH)
        end
    end
    
    if oldClip > clip then
        -- Drop bullet
        local bulletY = height * 0.54
        local bulletW = height * 0.005
        bulletW = math.min(rowMaxWidth / (oldMaxClip * 1.75), bulletW)
        local bulletH = bulletW * 3
        local bulletSpacing = bulletW * 0.75
        
        local bulletX = (width - bulletW * oldClip - bulletSpacing * (oldClip - 1)) / 2
        
        bulletY = bulletY + bulletH * 0.5
        bulletX = bulletX + bulletW * 0.5
        
        local interval = bulletW + bulletSpacing
        for i = clip, oldClip - 1 do
            table.insert(fallingBullets, {i * interval + bulletX, bulletY, bulletW, bulletH, bulletW * 0.15, -bulletH * 0.25, 0, math.rand(90, 360), 255})
            --table.insert(fallingBullets, {i * interval + bulletX, bulletY, bulletW, bulletH, 0, 0, 0, 1, 255})
        end
    end
    
    oldClip = clip
    oldMaxClip = maxClip
    
    local i = 1
    local count = #fallingBullets
    while i <= count do
        local bullet = fallingBullets[i]
        
        if bullet[9] <= 0 or bullet[2] - bullet[4] * 2 > height then
            table.remove(fallingBullets, i)
            count = count - 1
            continue
        end
        
        render_setRGBA(firedBulletColorR, firedBulletColorG, firedBulletColorB, bullet[9])
        render_drawTexturedRectRotated(bullet[1], bullet[2], bullet[3], bullet[4], bullet[7])
        
        bullet[1] = bullet[1] + bullet[5]
        bullet[2] = bullet[2] + bullet[6]
        bullet[6] = bullet[6] + gravity * ftime * height
        bullet[7] = bullet[7] + bullet[8] * ftime
        bullet[9] = bullet[9] - ftime / 2.5
        
        i = i + 1
    end
end)

enableHud(player(), true)