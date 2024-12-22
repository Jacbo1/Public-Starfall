-- Connect to and activate HUD

--@name Lockpicking
--@author Jacbo
--@shared

if SERVER then
    
else
    local baseMinFallTime = 1.5
    local baseMaxFallTime = 3
    local fps = 60
    local pinSpeed = 100 / fps
    local pickingSoundURLs = {"https://dl.dropboxusercontent.com/s/e92b1oq0ftw6o8m/misc1-01.mp3","https://dl.dropboxusercontent.com/s/4x8268waxyet8f2/misc1-02.mp3","https://dl.dropboxusercontent.com/s/dk63pqbryiahtok/misc1-03.mp3","https://dl.dropboxusercontent.com/s/hfqp595pmwzr6t5/misc1-04.mp3","https://dl.dropboxusercontent.com/s/eph24cghbfh7npd/misc1-05.mp3","https://dl.dropboxusercontent.com/s/wm8xbgcrwx4cr91/misc1-06.mp3","https://dl.dropboxusercontent.com/s/d671ag7fh7regz3/misc1-07.mp3","https://dl.dropboxusercontent.com/s/mpvkcugpntrwlnw/misc1-08.mp3","https://dl.dropboxusercontent.com/s/3tfbntbjle2ghgf/misc1-09.mp3","https://dl.dropboxusercontent.com/s/mnd8uo7rw2d4orj/misc1-10.mp3","https://dl.dropboxusercontent.com/s/prxznprd5s259ei/misc1-11.mp3","https://dl.dropboxusercontent.com/s/v4yaqcx45111ey6/misc1-12.mp3","https://dl.dropboxusercontent.com/s/nt4ubvyiwzf41vo/misc1-13.mp3","https://dl.dropboxusercontent.com/s/huu9u83dqz5mq87/misc1-14.mp3","https://dl.dropboxusercontent.com/s/6p0wpbp9eng1hxx/misc1-15.mp3"}
    local openSoundURLs = {"https://dl.dropboxusercontent.com/s/0rj76hfw2hu7eld/open%201.mp3","https://dl.dropboxusercontent.com/s/ayz5jjuxz606t0w/open%202.mp3","https://dl.dropboxusercontent.com/s/9p6tieqtro6ht42/open%203.mp3"}
    local chip = chip()
    local picked = false
    local pickingSounds = {}
    local openSounds = {}
    local pickx = 0
    local picky = 0
    local targetPickx = 0
    local targetPicky = 0
    local inUse = false
    local screenx = 1
    local screeny = 1
    local initIndex = 1
    local pickThickness = 24
    local pickTipLength = 100
    local loadIndex = 0
    local pinCount = 6
    --local pinCount = 100
    local shaftHeight = 150
    local pinStickHeight = math.round(512 - shaftHeight/2 - 75)
    local collisionRects = {}
    local pins = {}
    local pinSize = {w = 60, h = 120}
    local springHeight = pinStickHeight - pinSize.h - 50
    local minPinHeight = math.round(512 - shaftHeight/2 - pinSize.h)
    local pickCollision = {
        {x = math.round(-1024 + pickThickness/2), y = math.round(-pickThickness/2), w = 1024, h = pickThickness},
        {x = math.round(-pickThickness/2), y = math.ceil(-pickThickness/2 - pickTipLength), w = pickThickness, h = pickTipLength}
    }
    local nextFrameTime = timer.curtime()
    local ogPins = {}
    local pinPressNumber = 1
    local pinPressOrder = {}
    
    render.createRenderTarget("screen")
    render.createRenderTarget("pick")
    render.createRenderTarget("spring")
    render.createRenderTarget("pin")
    render.createRenderTarget("bg")
    
    local loadSound = function(URL, Table, index)
        bass.loadURL( URL, "3d noblock", function(Sound)
            if Sound then
                if inUse and index == loadIndex then
                    table.insert(Table,Sound)
                else
                    Sound:destroy()
                end
            end
        end)
    end
    
    local pickSound = function()
        local Sound = pickingSounds[math.random(1,#pickingSounds)]
        if Sound then
            Sound:setPos(chip:getPos())
            Sound:play()
        end
    end
    
    local openSound = function()
        local Sound = openSounds[math.random(1,#openSounds)]
        if Sound then
            Sound:setPos(chip:getPos())
            Sound:play()
        end
    end
    
    local resetPinOrder = function()
        pinPressNumber = 1
        pinPressOrder = {}
        for i = 1, pinCount do
            pins[i].fallTime = 0
            pins[i].falling = true
            table.insert(pinPressOrder, math.random(1, #pinPressOrder + 1), i)
        end
    end
    
    local movePins = function()
        local time = timer.curtime()
        for i, pin in pairs(pins) do
        
            if not pin.falling and pin.y <= pinStickHeight - pinSize.h and (pin.fallTime == 0 or time < pin.fallTime or picked) then
                pin.y = math.min(pin.y + pinSpeed, pinStickHeight - pinSize.h)
                if not pin.high then
                    pin.high = true
                    pickSound()
                    pin.fallTime = time + math.rand(baseMinFallTime * pinCount, baseMaxFallTime * pinCount)
                end
            else
                if pin.y > pinStickHeight - pinSize.h then
                    if pin.fallTime != 0 then
                        pin.fallTime = 0
                        pin.high = false
                        pickSound()
                    end
                    if pin.falling then
                        pin.falling = false
                        pin.fallTime = 0
                        pin.high = false
                    end
                end
                pin.y = math.min(pin.y + pinSpeed, minPinHeight)
            end
            
            if pickx >= pin.x and pickx < pin.x + pinSize.w then
                --pick is in or under pin hole
                local tip = picky - pickTipLength - pickThickness/2
                if tip < pin.y + pinSize.h then
                    --pick is pressing pin
                    pin.y = tip - pinSize.h
                    if pin.y <= pinStickHeight - pinSize.h then
                        --pin pushed pin to stick height
                        pin.fallTime = time + math.rand(baseMinFallTime * pinCount, baseMaxFallTime * pinCount)
                        if not pin.high then
                            --check for correct order
                            for j, pinOrder in pairs(pinPressOrder) do
                                if pinOrder == i then
                                    if j == pinPressNumber then
                                        --next pin
                                        pinPressNumber = pinPressNumber + 1
                                    elseif j > pinPressNumber then
                                        --wrong pin
                                        for k = 1, pinCount do
                                            pins[k].fallTime = 0
                                            pins[k].falling = true
                                        end
                                    end
                                    break
                                end
                            end
                            if pinPressNumber > pinCount then
                                local allHigh = true
                                for j = 1, pinCount do
                                    if j != i and not pins[j].high then
                                        allHigh = false
                                        break
                                    end
                                end
                                if allHigh then
                                    picked = true
                                    openSound()
                                end
                            end
                        end
                    end
                    if not pin.collide then
                        pin.collide = true
                        pickSound()
                    end
                else
                    pin.collide = false
                end
            else
                pin.collide = false
            end
        end
    end
    
    local checkCollision = function()
        for i, pickBox in pairs(pickCollision) do
            for j, boundary in pairs(collisionRects) do
                if 
                    pickx + pickBox.x < boundary.x + boundary.w and 
                    pickx + pickBox.x + pickBox.w > boundary.x and
                    picky + pickBox.y < boundary.y + boundary.h and 
                    picky + pickBox.y + pickBox.h > boundary.y
                then
                    return true
                end
            end
        end
        return false
    end
    
    local movePick = function()
        local cpuMax = quotaMax()*0.5
        local oldx = pickx
        local oldy = picky
        local oldoldx = -1
        local oldoldy = -1
        local stepSize = pickThickness
        local maxRuns = 4
        local runs = 0
        while quotaAverage() < cpuMax and runs < maxRuns and (pickx != targetPickx or picky != targetPicky) and (oldoldx != pickx or oldoldy != picky)do
            runs = runs + 1
            oldoldx = pickx
            oldoldy = picky
            pickx = pickx + math.clamp(targetPickx - pickx, -stepSize, stepSize)
            if checkCollision() then
                local step = math.floor(stepSize/2)
                local switch = true
                while quotaAverage() < cpuMax and step >= 1 do
                    if switch then
                        pickx = pickx - math.clamp(targetPickx - pickx, -step, step)
                    else
                        pickx = pickx + math.clamp(targetPickx - pickx, -step, step)
                    end
                    if checkCollision() then
                        switch = true
                        step = math.floor(step/2)
                        if step < 1 then
                            pickx = oldx
                            break
                        end
                    else
                        switch = false
                        oldx = pickx
                    end
                end
            end
            
            picky = picky + math.clamp(targetPicky - picky, -stepSize, stepSize)
            if checkCollision() then
                local step = math.floor(stepSize/2)
                local switch = true
                while quotaAverage() < cpuMax and step >= 1 do
                    if switch then
                        picky = picky - math.clamp(targetPicky - picky, -step, step)
                    else
                        picky = picky + math.clamp(targetPicky - picky, -step, step)
                    end
                    if checkCollision() then
                        switch = true
                        step = math.floor(step/2)
                        if step < 1 then
                            picky = oldy
                            break
                        end
                    else
                        switch = false
                        oldy = picky
                    end
                end
            end
        end
        movePins()
    end
    
    local reset = function()
        pickx = 0
        picky = math.floor(512 - shaftHeight/2 + pickTipLength + pickThickness)
        pins = table.copy(ogPins)
        picked = false
        resetPinOrder()
    end
    
    local drawArc = function(x, y, radius, thickness, startAng, arcAng, interval)
        interval = arcAng/math.abs(math.floor(arcAng/interval))
        local x1 = x + radius
        local y1 = y + radius
        local innerRadius = radius-thickness
        local lastPoint = {x = x1 + radius * math.cos(startAng), y = y1 + radius * math.sin(startAng)}
        local lastInnerPoint = {x = x1 + innerRadius * math.cos(startAng), y = y1 + innerRadius * math.sin(startAng)}
        for i = startAng+interval, startAng+arcAng, interval do
            local point = {x = x1 + radius * math.cos(i), y = y1 + radius * math.sin(i)}
            local innerPoint = {x = x1 + innerRadius * math.cos(i), y = y1 + innerRadius * math.sin(i)}
            render.drawPoly({lastPoint,point,innerPoint,lastInnerPoint})
            lastPoint = point
            lastInnerPoint = innerPoint
        end
    end
    
    hook.add("ComponentLinked","",function(ent)
        hook.add("drawhud","",function()
            screenx, screeny = render.getResolution()
            local size = math.min(screenx, screeny, 1024)
            render.setRenderTargetTexture("screen")
            render.drawTexturedRect((screenx - size)/2, (screeny - size)/2, size, size)
            
            render.setRenderTargetTexture("pick")
            render.drawTexturedRect(pickx - 1024 + pickThickness/2 + (screenx - size)/2, picky - pickTipLength - pickThickness/2 + (screeny - size)/2, 1024, 1024)
        end)
        
        hook.add("renderoffscreen","",function()
            if initIndex == 1 then
                --Make pick
                render.selectRenderTarget("pick")
                render.clear(Color(0,0,0,0))
                render.setRGBA(60,60,60,255)
                render.drawRect(0, pickTipLength, 1024 - pickThickness, pickThickness)
                render.drawRect(1024 - pickThickness, 0, pickThickness, pickTipLength)
                drawArc(1024 - pickThickness, pickTipLength, 0, pickThickness, -math.pi/2, -math.pi/2, math.rad(1))
                initIndex = 2
            elseif initIndex == 2 then
                --Make spring
                render.selectRenderTarget("spring")
                render.clear(Color(0,0,0,0))
                render.setRGBA(100,100,100,255)
                local layers = 10
                local layerHeight = 1024 / layers
                local springThickness = layerHeight/4
                for y = 0, 1023, layerHeight do
                    render.drawPoly({
                        {x = 0, y = y},
                        {x = 0, y = y - springThickness},
                        {x = 1023, y = y + layerHeight/2 - springThickness},
                        {x = 1023, y = y + layerHeight/2}
                    })
                end
                render.setRGBA(140,140,140,255)
                for y = 0, 1023, layerHeight do
                    render.drawPoly({
                        {x = 1023, y = y + layerHeight/2},
                        {x = 0, y = y + layerHeight},
                        {x = 0, y = y + layerHeight - springThickness},
                        {x = 1023, y = y - springThickness + layerHeight/2}
                    })
                end
                initIndex = 3
            elseif initIndex == 3 then
                --Make pin
                render.selectRenderTarget("pin")
                local color = Color(181, 166, 66)
                --local minMult = 0.75
                local minMult = 0.75
                --local maxMult = 1.25
                local maxMult = 1.25
                --print(color * math.clamp(maxMult - (512/512)^2 * (minMult - maxMult), 0, 255))
                for x = 0, 512 do
                    --render.setColor(color * math.clamp(maxMult - (x/512)^2 * (minMult - maxMult), 0, 1))
                    render.setColor(color * math.clamp((x/512)^2 * (maxMult - minMult) + minMult, 0, 1))
                    render.drawLine(x, 0, x, 1023)
                end
                for x = 0, 512 do
                    render.setColor(color * math.clamp((x/512)^2 * (maxMult - minMult) + minMult, 0, 1))
                    render.drawLine(1023 - x, 0, 1023 - x, 1023)
                end
                initIndex = 4
            elseif initIndex == 4 then
                --Make background
                render.selectRenderTarget("bg")
                render.clear(Color(0,0,0,0))
                local chamberColor = Color(181, 166, 66)
                local externalColor = Color(120, 120, 120)
                render.setRGBA(255,0,0, 255)
                local maxLength = 1024
                local endSize = 50
                local pinSpacing = math.floor((maxLength - pinSize.w * pinCount - endSize * 2) / (pinCount - 1))
                local length = pinSpacing * (pinCount - 1) + pinSize.w * pinCount + endSize * 2
                local x = endSize
                local top = springHeight - endSize
                local shaftTop = 512 - shaftHeight/2
                render.setColor(Color(60, 60, 60))
                render.drawRect(0, springHeight, 1024, pinStickHeight - springHeight)
                
                render.setColor(externalColor)
                render.drawRect(0, springHeight - endSize, 1024, endSize)
                render.drawRect(0, springHeight, endSize, pinStickHeight - springHeight)
                
                render.setColor(Color(181/2, 166/2, 66/2))
                render.drawRect(0, pinStickHeight, 1024, math.round(512 + shaftHeight/2 + endSize - pinStickHeight))
                
                render.setColor(chamberColor)
                render.drawRect(0, pinStickHeight, endSize, shaftTop - pinStickHeight)
                render.drawRect(length - endSize, pinStickHeight, endSize, shaftTop - pinStickHeight)
                render.drawRect(0, math.round(512 + shaftHeight/2), length, shaftTop - pinStickHeight)
                render.drawRect(math.round(length - endSize/2), pinStickHeight, 1024, math.round(512 + shaftHeight/2 + endSize - pinStickHeight))
                table.insert(collisionRects,{x = 0, y = 0, w = 1024, h = pinStickHeight - 4})
                table.insert(collisionRects,{x = 0, y = math.round(512 + shaftHeight/2), w = 1024, h = 1024})
                table.insert(collisionRects,{x = 0, y = 0, w = endSize, h = shaftTop})
                table.insert(collisionRects,{x = math.round(length - endSize/2), y = 0, w = 1024, h = 1024})
                for i = 1, pinCount do
                    table.insert(ogPins,{x = x, y = shaftTop - pinSize.h, collide = false, high = false, fallTime = 0, falling = false})
                    x = x + pinSize.w + pinSpacing
                    table.insert(collisionRects,{x = x - pinSpacing, y = 0, w = pinSpacing, h = shaftTop})
                    
                    render.setColor(chamberColor)
                    render.drawRect(x - pinSpacing, pinStickHeight, pinSpacing, shaftTop - pinStickHeight)
                    
                    render.setColor(externalColor)
                    render.drawRect(x - pinSpacing, springHeight, pinSpacing, pinStickHeight - springHeight)
                end
                pins = table.copy(ogPins)
                initIndex = 5
            end
            
            if inUse then
                local time = timer.curtime()
                if time >= nextFrameTime then
                    nextFrameTime = nextFrameTime + 1/fps
                    render.selectRenderTarget("screen")
                    render.clear(Color(0,0,0,0))
                    render.setRenderTargetTexture("bg")
                    render.drawTexturedRect(0,0,1024,1024)
                    local x, y = input.getCursorPos()
                    local size = math.min(screenx, screeny, 1024)
                    targetPickx = math.clamp(math.round((x - (screenx - size)/2) * 1024 / size), 0, 1023)
                    targetPicky = math.clamp(math.round((y - (screeny - size)/2) * 1024 / size), 0, 1023)
                    movePick()
                    
                    for i, pin in pairs(pins) do
                        render.setRenderTargetTexture("spring")
                        render.drawTexturedRect(pin.x, springHeight, pinSize.w, pin.y - springHeight)
                        render.setRenderTargetTexture("pin")
                        render.drawTexturedRect(pin.x, pin.y, pinSize.w, pinSize.h)
                    end
                end
            end
        end)
        
        if not hasPermission("bass.loadURL") then
            setupPermissionRequest({"bass.loadURL"}," ",true)
            hook.add("permissionrequest","",function()
                if permissionRequestSatisfied() then
                    hook.remove("permissionrequest","")
                end
            end)
        end
        
        hook.add("hudconnected","",function()
            input.enableCursor(true)
            inUse = true
            loadIndex = loadIndex + 1
            for i, url in pairs(pickingSoundURLs) do
                loadSound(url, pickingSounds, loadIndex)
            end
            for i, url in pairs(openSoundURLs) do
                loadSound(url, openSounds, loadIndex)
            end
            reset()
        end)
        
        hook.add("huddisconnected","",function()
            inUse = false
            for i, Sound in pairs(pickingSounds) do
                Sound:destroy()
            end
            for i, Sound in pairs(openSounds) do
                Sound:destroy()
            end
            pickingSounds = {}
            openSounds = {}
        end)
        
        hook.remove("ComponentLinked","")
    end)
end

--[[hook.add("render","",function()
    render.setRenderTargetTexture("screen")
    render.drawTexturedRect(0,0,512,512)
end)]]