-- Inside joke about Mee's trademarked "Mee++" bad code. Connect to a screen.

--@name Powered by Mee++
--@author Jacbo
--@shared
--@include better_coroutines.txt
--@include funcs.txt

local corlib = require("better_coroutines.txt")
require("funcs.txt")

if SERVER then
    funcs.linkToClosestScreen()
else--CLIENT

    --Time until fade = 2.5
    --Fade duration = 0.75
    --Time for sound glitch = 5.25
    --Time for glitchor = 8
    --Time for bsod = 10
    --https://www.dropbox.com/s/ru2jty3ju766sjy/Mee%2B%2B_Intro_Sound.mp3?dl=0
    local interval = 0.05
    render.createRenderTarget("")
    render.createRenderTarget("screen")
    local maxUsage = 0.003
    local maxQuota = math.min(maxUsage, quotaMax() * 0.75)
    local lowerText = "@ 2020 Mee Corporation. All rights reserved. Mee++ and the Mee++ logo are\ntrademarks and/or registered trademarks of Mee Corporation in the United States\nand other countries."
    
    local drawGlitchor = corlib.wrap(function(intensity, colorIntensity, rows, columns)
        local min = -intensity * 512
        local max = 511 + intensity * 512
        colorIntensity = colorIntensity * 255
        local mmax = math.max
        local rand = math.rand
        local setRGBA = render.setRGBA
        local drawTexturedRectUV = render.drawTexturedRectUV
        local drawRect = render.drawRect
        local setRenderTargetTexture = render.setRenderTargetTexture
        setRenderTargetTexture("screen")
        local dh = 512 / (rows-1)
        local dv = dh / 512
        local dw = 512 / (columns-1)
        local start = 512 * intensity
        for y = 0, rows-1 do
            while quotaAverage() > maxQuota do coroutine.yield() end
            local x2 = rand(-start, start)
            local y2 = y * dh
            local v = y * dv
            setRGBA(0,0,0,255)
            drawRect(0, y2, 512, dh)
            
            setRenderTargetTexture("screen")
            setRGBA(255,255,255,255)
            drawTexturedRectUV(x2, y2, 512, dh, 0, v, 1, v+dv)
            for x = x2, x2 + 511, dw do
                if rand(0, 1) < 0.5 then
                    local color = Vector(rand(0, 1), rand(0, 1), rand(0, 1))
                    color = color * 255/mmax(color[1], color[2], color[3])
                    setRGBA(color[1], color[2], color[3], colorIntensity)
                    drawRect(x, y2, dw, dh)
                end
            end
        end
    end)
    
    local ready1 = false
    local ready2 = false
    local ready3 = false
    
    local bsodMat
    local logoMat
    local introSound
    
    local function run()
        if not(ready1 and ready2 and ready3) then return end
        
        try(function()
            introSound:play()
        end)
        local startTime = timer.curtime()
        
        hook.add("render", "", function()
            try(function()
                if introSound and introSound:isValid() then
                    introSound:setPos(render.getScreenEntity():obbCenterW())
                end
            end)
            render.setRenderTargetTexture("screen")
            local timex = timer.curtime() - startTime
            if timex < 8 then
                if timex >= 2.5 then
                    --Fade in
                    render.setRGBA(255,255,255, math.min(255, (timex-2.5) / 0.75 * 255))
                    render.drawTexturedRect(0,0,512,512)
                end
            elseif timex < 10 then
                --Glitchor
                drawGlitchor(0.05, 0.125, 30, 10)
            else
                try(function()
                    introSound:destroy()
                end)
                render.setMaterial(bsodMat)
                render.drawTexturedRect(0,0,512,512)
            end
        end)
    end
    
    try(function()
        bass.loadURL("https://dl.dropboxusercontent.com/s/ru2jty3ju766sjy/Mee%2B%2B_Intro_Sound.mp3", "3d", function(sound)
            introSound = sound
            ready1 = true
            run()
        end)
    end, function()
        ready1 = true
        run()
    end)
    
    bsodMat = material.create("UnlitGeneric")
    bsodMat:setTextureURL("$basetexture", "https://i.imgur.com/EcQ5C6o.png", function()
        --[[hook.add("render", "init bsod", function()
            render.setMaterial(bsodMat)
            render.drawTexturedRect(0,0,1,1)
            hook.remove("render", "init bsod")
            ready2 = true
            run()
        end)]]
        ready2 = true
    end)
    
    logoMat = material.create("UnlitGeneric")
    local width, height
    logoMat:setTextureURL("$basetexture", "https://i.imgur.com/kBtbq5Z.png", function(_, _, inWidth, inHeight)
        width = inWidth
        height = inHeight
    end, function()
        hook.add("render", "init", function()
            render.setMaterial(logoMat)
            render.drawTexturedRect(0,0,1,1)
            hook.remove("render", "init")
            hook.add("renderoffscreen", "", function()
                render.selectRenderTarget("")
                render.clear(Color(0,0,0,0))
                render.setMaterial(logoMat)
                render.drawTexturedRect(0,0,1024^2/width,1024^2/height)
                
                render.selectRenderTarget("screen")
                render.clear()
                render.setRGBA(255,255,255,255)
                render.setFont(render.createFont("arial", 30))
                render.drawText(55, 750, lowerText)
            
                render.setFont(render.createFont("arial", 60))
                render.drawSimpleText(512, 512-400/2-60, "Powered be Mee++", 1, 0)
            
                render.setRenderTargetTexture("")
                render.drawTexturedRect(512-400/2, 512-400/2, 400, 400)
                
                hook.remove("renderoffscreen", "")
                ready3 = true
                run()
            end)
        end)
    end)
end