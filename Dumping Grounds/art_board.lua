-- Connect to screen. The larger the better.
-- Draw with left click. Erase with right click.

--@name Drawing Board
--@author Jacbo
--@shared
--@include better_coroutines.txt
--@include funcs.txt
--@include safeNet.txt

require("safeNet.txt")
local net = safeNet
local netMax = 30
require("funcs.txt")
local corlib = require("better_coroutines.txt")
if SERVER then
    funcs.linkToClosestScreen(function(screen)
        screen:setColor(Color(255,255,255,1))
    end)
    
    net.receive("lines", function(_, ply)
        net.start("lines")
        net.writeEntity(ply)
        net.writeColor(net.readColor())
        net.writeUInt16(net.readUInt16())
        net.writeUInt16(net.readUInt16())
        net.writeUInt16(net.readUInt16())
        net.writeUInt16(net.readUInt16())
        net.writeUInt16(net.readUInt16())
        net.send()
    end)
else--CLIENT
    local blacklist = {
        ["STEAM_0:0:512398178"] = true,
        ["STEAM_0:0:228617778"] = true,
        ["STEAM_0:1:5424085"] = true
    }
    blacklist = blacklist[player():getSteamID()]
    render.createRenderTarget("")
    render.createRenderTarget("capture")
    render.createRenderTarget("circle")
    render.createRenderTarget("checker")
    local pencilMat = material.create("UnlitGeneric")
    pencilMat:setTextureURL("$basetexture", "https://i.imgur.com/Q5c5grT.png")
    local eraserMat = material.create("UnlitGeneric")
    eraserMat:setTextureURL("$basetexture", "https://i.imgur.com/kx5fW5S.png")
    local colorPickerMat = material.create("UnlitGeneric")
    colorPickerMat:setTextureURL("$basetexture", "https://i.imgur.com/7CBW1c8.png")
    --local fillToolMat = material.create("UnlitGeneric")
    --fillToolMat:setTextureURL("$basetexture", "https://i.imgur.com/Q0EWvZO.png")
    local fillToolMat = funcs.loadMat("https://i.imgur.com/in9pHMA.png")
    local eyedropperMat = material.create("UnlitGeneric")
    eyedropperMat:setTextureURL("$basetexture", "https://i.imgur.com/YevDkgQ.png")
    local eraserScale = 1024^2/981
    local gradientl = material.create("UnlitGeneric")
    gradientl:setTexture("$basetexture", "vgui/gradient-l")
    local gradientd = material.create("UnlitGeneric")
    gradientd:setTexture("$basetexture", "vgui/gradient-d")
    local gradientu = material.create("UnlitGeneric")
    gradientu:setTexture("$basetexture", "vgui/gradient-u")
    local barMat = material.create("UnlitGeneric")
    barMat:setTexture("$basetexture", "vgui/hsv-bar")
    
    local usingFillTool = false
    local usingEyedropper = false
    local dontDraw = false
    local toolSize = 30
    
    hook.add("renderoffscreen", "make checker", function()
        render.selectRenderTarget("checker")
        render.clear(Color(0,0,0,0))
        render.setRGBA(191, 191, 191, 255)
        local d = 10
        local shift = false
        for y = 0, 943, d do
            shift = not shift
            if y + d <= 943 then
                for x = shift and d or 0, 59, d*2 do
                    render.drawRect(x+2, y, d, d)
                end
            else
                local h = 944 - y
                for x = shift and d or 0, 59, d*2 do
                    render.drawRect(x+2, y, d, h)
                end
            end
        end
        
        for y = 0, 159, d do
            shift = not shift
            for x = 1023 - (shift and d or 0), 1023 - 160, -d*2 do
                render.drawRect(x, y, d, d)
            end
        end
        
        hook.remove("renderoffscreen", "make checker")
    end)
    
    local thickness, eraserThickness = 4, 12
    local colors = {Color(math.rand(0,360), 0.75, 0.75):hsvToRGB(), Color(255,255,255), Color(255, 0, 0), Color(0, 255, 0), Color(0, 0, 255)}
    local cursor = {0, 0}
    local m1, m2 = false, false
    local oldM1, oldM2 = false, false
    local clicking1, clicking2 = false, false
    local suspendClick = false
    
    local queue = {}
    local maxQuota = 0
    local CPUStepSizeMult = 0.0001
    
    local drawQueue = corlib.wrap(function()
        local setColor = render.setColor
        local drawRect = render.drawRect
        while #queue ~= 0 do
            setColor(queue[1][1])
            local ax, ay, bx, by, thickness = queue[1][2], queue[1][3], queue[1][4], queue[1][5], queue[1][6]
            local halfThickness = thickness * 0.5
            if ax == bx then
                if ay == by then
                    --Single square
                    render.drawRect(ax-halfThickness, ay-halfThickness, thickness, thickness)
                else
                    --Vertical line
                    local x = ax-halfThickness
                    for y = ay-halfThickness, by-halfThickness, math.sign(by-ay) do
                        render.drawRect(x, y, thickness, thickness)
                        if quotaAverage() > maxQuota then
                            while quotaAverage() > maxQuota do coroutine.yield() end
                            setColor(queue[1][1])
                        end
                    end
                end
            elseif ay == by then
                --Horizontal line
                local y = ay - halfThickness
                for x = ax-halfThickness, bx-halfThickness, math.sign(bx-ax) do
                    render.drawRect(x, y, thickness, thickness)
                    if quotaAverage() > maxQuota then
                        while quotaAverage() > maxQuota do coroutine.yield() end
                        setColor(queue[1][1])
                    end
                end
            else
                --Line
                local slopex = (by - ay) / (bx - ax)
                local slopey = (bx - ax) / (by - ay)
                if math.abs(slopex) < math.abs(slopey) then
                    local start = ax - halfThickness
                    local y = ay - halfThickness
                    for x = start, bx-halfThickness, math.sign(bx - ax) do
                        render.drawRect(x, (x - start) * slopex + y, thickness, thickness)
                        if quotaAverage() > maxQuota then
                            while quotaAverage() > maxQuota do coroutine.yield() end
                            setColor(queue[1][1])
                        end
                    end
                else
                    local start = ay - halfThickness
                    local x = ax - halfThickness
                    for y = start, by-halfThickness, math.sign(by - ay) do
                        render.drawRect((y - start) * slopey + x, y, thickness, thickness)
                        if quotaAverage() > maxQuota then
                            while quotaAverage() > maxQuota do coroutine.yield() end
                            setColor(queue[1][1])
                        end
                    end
                end
            end
            table.remove(queue, 1)
        end
    end)
    
    net.receive("lines", function()
        if net.readEntity() ~= player() then
            --queue = table.add(queue, net.readTable())
            --table.insert(queue, net.readTable())
            table.insert(queue, {
                net.readColor(),
                net.readUInt16(),
                net.readUInt16(),
                net.readUInt16(),
                net.readUInt16(),
                net.readUInt16()
            })
        end
    end)
    
    hook.add("renderoffscreen", "init", function()
        render.selectRenderTarget("circle")
        render.clear(Color(0,0,0,0))
        render.setRGBA(255, 255, 255, 255)
        funcs.drawCircle(0, 0, 512, 360)
        hook.remove("renderoffscreen", "init")
    end)
    
    hook.add("renderoffscreen", "", function()
        render.selectRenderTarget("")
        if not dontDraw then
            drawQueue()
        end
    end)
    
    --[[local netQueue = {}
    timer.create("network", 0.1, 0, function()
    --hook.add("tick", "", function()
        if #netQueue ~= 0 then
            net.start("lines")
            if #netQueue > netMax then
                local t = {}
                for i = 1, netMax do
                    table.insert(t, netQueue[i])
                end
                net.writeTable(t)
                net.send()
                for i = 1, netMax do
                    table.remove(netQueue, 1)
                end
            else
                net.writeTable(netQueue)
                net.send()
                netQueue = {}
            end
        end
    end)]]
    
    local function addLine(tbl)
        net.start("lines")
        --net.writeTable(tbl)
        net.writeColor(tbl[1])
        net.writeUInt16(tbl[2])
        net.writeUInt16(tbl[3])
        net.writeUInt16(tbl[4])
        net.writeUInt16(tbl[5])
        net.writeUInt16(tbl[6])
        net.send()
        table.insert(queue, tbl)
        --table.insert(netQueue, tbl)
    end
    
    local menu = {
        x = 455,
        y = 455,
        w = 45,
        h = 45,
        bounds = {},
        openSpeed = 5,
        open = 0,
        openLerp = 0,
        padding = 10,
        elements = {},
        colorPicker = {
            pickingColor = false,
            x = 0,
            y = 0,
            alpha = 255,
            hue = 0,
            selectedComponent = false,
            bounds = nil,
            dontClick = false
        }
    }
    
    local colorPickerFont = render.createFont("Coolvetica", 28, nil, true)
    local function drawColorPicker(x, y, alpha, hue)
        x = x or menu.colorPicker.x
        y = y or menu.colorPicker.y
        alpha = alpha or menu.colorPicker.alpha
        hue = hue or menu.colorPicker.hue
        alpha = alpha / 255
        local padding = 20
        local sliderThickness = 30
        local color = funcs.hsvToRGB(hue, 1, 1)
        hue = hue / 360
        render.setRGBA(255, 255, 255, 255)
        render.drawRect(0, 0, 512, 512)
        
        local x1, y1, w1, h1, x2, w2, h2, x3
        if menu.colorPicker.bounds then
            local bounds = menu.colorPicker.bounds
            x1 = bounds[1].x
            y1 = bounds[1].y
            w1 = bounds[1].w
            h1 = bounds[1].h
            
            x2 = bounds[2].x
            w2 = bounds[2].w
            h2 = bounds[2].h
            
            x3 = bounds[3].x
        else
            --Init bounds
            x1 = padding
            y1 = padding
            w1 = 512-padding*4-sliderThickness*2
            h1 = 512-padding*4-sliderThickness*2
        
            x2 = 512-padding*2-sliderThickness*2
            w2 = sliderThickness
            h2 = 512-padding*2
        
            x3 = 512-padding-sliderThickness
            
            menu.colorPicker.bounds = {
                {
                    x = x1,
                    y = y1,
                    w = w1,
                    h = h1
                },
                {
                    x = x2,
                    y = y1,
                    w = w2,
                    h = h2
                },
                {
                    x = x3,
                    y = y1,
                    w = w2,
                    h = h2
                }
            }
        end
        
        --Draw outlines
        render.setRGBA(0, 0, 0, 255)
        render.drawRectOutline(x1-1, y1-1, w1+2, h1+2) --box
        render.drawRectOutline(x2-1, y1-1, w2+2, h2+2) --alpha
        render.drawRectOutline(x3-1, y1-1, w2+2, h2+2) --hue
        
        --Draw big box
        render.setMaterial(gradientl)
        render.setRGBA(color[1], color[2], color[3], 255)
        render.drawTexturedRect(x1, y1, w1, h1)
        render.setRGBA(0, 0, 0, 255)
        render.setMaterial(gradientd)
        render.drawTexturedRect(x1, y1, w1, h1)
        local cx = x * w1 + x1
        local cy = y * h1 + y1
        local cd = 3
        local cl = 3
        render.setRGBA(255, 255, 255, 255)
        render.drawRect(cx-1, cy-cd-cl-1, 3, cl+2)
        render.drawRect(cx-cd-cl-1, cy-1, cl+2, 3)
        render.drawRect(cx-1, cy+cd, 3, cl+2)
        render.drawRect(cx+cd, cy-1, cl+2, 3)
        render.setRGBA(0, 0, 0, 255)
        render.drawRect(cx, cy-cd-cl, 1, cl)
        render.drawRect(cx-cd-cl, cy, cl, 1)
        render.drawRect(cx, cy+cd+1, 1, cl)
        render.drawRect(cx+cd+1, cy, cl, 1)
        
        --Draw alpha bar
        render.setRGBA(255, 255, 255, 255)
        render.setRenderTargetTexture("checker")
        render.drawTexturedRect(x2-1, y1, 512, 512)
        render.setMaterial(gradientu)
        render.drawTexturedRect(x2, y1, w2, h2)
        local ax = x2-1
        local aw = w2+2
        local ay = (1 - alpha) * (h2-1) + y1
        render.drawRect(ax, ay, aw, 1)
        render.setRGBA(0, 0, 0, 255)
        render.drawRect(ax, ay-1, aw, 1)
        render.drawRect(ax, ay+1, aw, 1)
        
        --Draw hue bar
        render.setRGBA(255, 255, 255, 255)
        render.setMaterial(barMat)
        render.drawTexturedRect(x3, y1, w2, h2)
        local hx = x3-1
        local hw = w2+2
        local hy = hue * (h2-1) + y1
        render.drawRect(hx, hy, hw, 1)
        render.setRGBA(0, 0, 0, 255)
        render.drawRect(hx, hy-1, hw, 1)
        render.drawRect(hx, hy+1, hw, 1)
        
        color = math.lerpVector(x, color, Vector(255)) * (1 - y)
        color = Color(math.round(color[1]), math.round(color[2]), math.round(color[3]), math.round(alpha * 255))
        
        --Draw color display
        local size = 512-(512-padding-sliderThickness*2)
        local y4 = 512-padding*2-sliderThickness*2
        render.setRGBA(0, 0, 0, 255)
        render.drawRect(padding+size*0.5, y4, size*0.5, size)
        render.setRGBA(255, 255, 255, 255)
        render.setRenderTargetTexture("checker")
        render.drawTexturedRect(padding-(512-padding-sliderThickness*2)+0.5, y4, 512, 512)
        render.setColor(color)
        render.drawRect(padding, y4, size, size)
        render.setRGBA(0, 0, 0, 255)
        render.drawRectOutline(padding-1, y4 - 1, size+2, size+2)
        
        --Right RGBA Text
        local x = padding*2 + size
        render.setRGBA(150, 150, 150, 255)
        render.drawRectOutline(x-3, y4-1, 257, 31)
        render.setRGBA(225, 225, 225, 255)
        render.drawRect(x - 2, y4, 255, 29)
        
        render.setFont(colorPickerFont)
        render.setRGBA(0, 0, 0, 255)
        render.drawSimpleText(x, y4, "RGBA: ", 0, 0)
        render.setRGBA(0, 0, 0, 255)
        --R
        render.setRGBA(150, 150, 150, 255)
        render.drawRectOutline(x + 70, y4+3, 42, 23)
        render.setRGBA(200, 200, 200, 255)
        render.drawRect(x + 71, y4+4, 40, 21)
        render.setRGBA(255, 0, 0, 255)
        render.drawSimpleText(x + 72, y4, tostring(color[1]), 0, 0)
        --G
        render.setRGBA(150, 150, 150, 255)
        render.drawRectOutline(x + 116, y4+3, 42, 23)
        render.setRGBA(200, 200, 200, 255)
        render.drawRect(x + 117, y4+4, 40, 21)
        render.setRGBA(0, 200, 0, 255)
        render.drawSimpleText(x + 118, y4, tostring(color[2]), 0, 0)
        --B
        render.setRGBA(150, 150, 150, 255)
        render.drawRectOutline(x + 162, y4+3, 42, 23)
        render.setRGBA(200, 200, 200, 255)
        render.drawRect(x + 163, y4+4, 40, 21)
        render.setRGBA(0, 0, 255, 255)
        render.drawSimpleText(x + 164, y4, tostring(color[3]), 0, 0)
        --A
        render.setRGBA(150, 150, 150, 255)
        render.drawRectOutline(x + 208, y4+3, 42, 23)
        render.setRGBA(200, 200, 200, 255)
        render.drawRect(x + 209, y4+4, 40, 21)
        render.setRGBA(0, 0, 0, 255)
        render.drawSimpleText(x + 210, y4, tostring(color[4]), 0, 0)
        
        --Draw buttons
        local y = y4 + 25 + padding
        local w = w1 - size - padding
        w = math.round(w * 0.5) * 2+1
        local h = size - padding - 25
        render.setRGBA(150, 150, 150, 255)
        render.drawRectOutline(x-1, y-1, w+2, h+2)
        render.setRGBA(225, 225, 225, 255)
        render.drawRect(x, y, w, h)
        x1 = x + 4
        y1 = y + 4
        w1 = (w - 1) * 0.5 - 6
        h1 = h - 8
        --Draw confirm box
        render.setRGBA(150, 150, 150, 255)
        render.drawRectOutline(x1-1, y1-1, w1+2, h1+2)
        render.setRGBA(200, 200, 200, 255)
        render.drawRect(x1, y1, w1, h1)
        render.setRGBA(0, 200, 0, 255)
        render.drawSimpleText(x1+w1*0.5, y1+h1*0.5, "Confirm", 1, 1)
        --Draw cancel box
        x2 = x1 + w1 + 5
        render.setRGBA(150, 150, 150, 255)
        render.drawRectOutline(x2-1, y1-1, w1+2, h1+2)
        render.setRGBA(200, 200, 200, 255)
        render.drawRect(x2, y1, w1, h1)
        render.setRGBA(255, 0, 0, 255)
        render.drawSimpleText(x2+w1*0.5, y1+h1*0.5, "Cancel", 1, 1)
        --Check for click
        if clicking1 and cursor[1] and cursor[2] then
            if cursor[2] >= y1 and cursor[2] < y1 + h1 then
                if cursor[1] >= x1 and cursor[1] < x1 + w1 then
                    --Click confirm
                    table.insert(colors, table.remove(colors, 1))
                    colors[1] = color
                    menu.pickingColor = false
                    suspendClick = true
                elseif cursor[1] >= x2 and cursor[1] < x2 + w1 then
                    --Click cancel
                    menu.pickingColor = false
                    suspendClick = true
                end
            end
        end
        
        return color
    end
    
    menu.colorPicker.getComponents = function(color)
        color = color or colors[1]
        menu.colorPicker.alpha = color[4]
        local hsv = funcs.rgbToHSV(color[1], color[2], color[3])
        menu.colorPicker.hue = hsv[1]
        menu.colorPicker.y = 1 - math.max(color[1], color[2], color[3]) / 255
        menu.colorPicker.x = math.min(color[1], color[2], color[3]) / 255
    end
    
    local function pickColor()
        --if m1 and not menu.colorPicker.dontClick then
        if m1 then
            --Clicking
            if cursor[1] and cursor[2] then
                if selectedComponent then
                    local bounds = menu.colorPicker.bounds[selectedComponent]
                    if selectedComponent == 1 then
                        --Big box
                        menu.colorPicker.x = math.clamp((cursor[1]-bounds.x)/bounds.w, 0, 1)
                        menu.colorPicker.y = math.clamp((cursor[2]-bounds.y)/bounds.h, 0, 1)
                    elseif selectedComponent == 2 then
                        --Alpha slider
                        menu.colorPicker.alpha = math.clamp(255-(cursor[2]-bounds.y)/bounds.h*255, 0, 255)
                    else
                        --Hue slider
                        menu.colorPicker.hue = math.clamp((cursor[2]-bounds.y)/bounds.h*360, 0, 360)
                    end
                else
                    if menu.colorPicker.bounds then
                        for i, bounds in ipairs(menu.colorPicker.bounds) do
                            if cursor[1] >= bounds.x and cursor[1] < bounds.x + bounds.w and cursor[2] >= bounds.y and cursor[2] < bounds.y + bounds.h then
                                --Clicking in here
                                selectedComponent = i
                                if selectedComponent == 1 then
                                    --Big box
                                    menu.colorPicker.x = math.clamp((cursor[1]-bounds.x)/bounds.w, 0, 1)
                                    menu.colorPicker.y = math.clamp((cursor[2]-bounds.y)/bounds.h, 0, 1)
                                elseif selectedComponent == 2 then
                                    --Alpha slider
                                    menu.colorPicker.alpha = math.clamp(255-(cursor[2]-bounds.y)/bounds.h*255, 0, 255)
                                else
                                    --Hue slider
                                    menu.colorPicker.hue = math.clamp((cursor[2]-bounds.y)/bounds.h*360, 0, 360)
                                end
                                break
                            end
                        end
                    end
                end
            end
        else
            --[[if not m1 and menu.colorPicker.dontClick then
                menu.colorPicker.dontClick = false
            end]]
            selectedComponent = false
        end
    end
    
    menu.lerpOpen = function(opening)
        menu.openLerp = math.clamp(menu.openLerp + menu.openSpeed * timer.frametime() * (opening and 1 or -1), 0, 1)
        menu.open = math.cos((menu.openLerp-1) * math.pi)*0.5 + 0.5
    end
    
    menu.calcBounds = function()
        local w, x
        if menu.open == 0 then
            w = menu.w
            x = menu.x
        else
            w = menu.w * 2
            x = menu.x + (menu.w - w)*0.5
        end
        local height = menu.h + menu.open * (#menu.elements * (menu.h + menu.padding))
        menu.bounds = {
            x = x,
            y = menu.y - height + menu.h,
            w = w,
            h = height
        }
        return menu.bounds
    end
    
    menu.draw = function()
        if menu.pickingColor then
            pickColor()
            drawColorPicker()
        else
            for _, element in ipairs(menu.elements) do
            --for i = #menu.elements, 1, -1 do
                local x, y, w, h = element.draw()
                if (clicking1 or clicking2) and cursor[1] and cursor[2] then
                    if cursor[1] >= x and cursor[1] < x + w and cursor[2] >= y and cursor[2] < y + h then
                        element.onClick(clicking1, clicking2)
                    end
                end
            end
        
            render.setRGBA(255, 255, 255, 255)
            render.setRenderTargetTexture("circle")
            render.drawTexturedRect(menu.x, menu.y, menu.w, menu.h)
            render.setRGBA(colors[1][1], colors[1][2], colors[1][3], 255)
            render.drawTexturedRect(menu.x+1, menu.y+1, menu.w-2, menu.h-2)
        end
    end
    
    menu.calcBounds()
    
    local function addMenuElement(width, height, onClick, draw)
        local index = #menu.elements
        table.insert(menu.elements, {
            w = width,
            h = height,
            onClick = onClick,
            draw = function()
                local x = menu.bounds.x + (menu.bounds.w - width)*0.5
                local y = menu.bounds.y + menu.open * index * (menu.h + menu.padding)
                draw(x, y)
                return x, menu.bounds.y + index * (menu.h + menu.padding), width, height
            end
        })
    end
    
    local function capturePixels(cb)
        hook.add("renderoffscreen", "capture pixels", function()
            hook.remove("renderoffscreen", "capture pixels")
            render.selectRenderTarget("capture")
            render.setRGBA(255, 255, 255, 255)
            render.setRenderTargetTexture("")
            render.drawTexturedRect(0, 0, 1024, 1024)
            render.capturePixels()
            if cb then
                cb()
            end
        end)
    end
    
    --[[--Add fill tool button
    addMenuElement(
        menu.w,
        menu.h,
        function(m1, m2)
            if m1 then
                usingEyedropper = false
                usingFillTool = not usingFillTool
                if not usingFillTool then
                    dontDraw = true
                end
            end
        end,
        function(x, y)
            render.setRGBA(255, 255, 255, 255)
            render.setRenderTargetTexture("circle")
            render.drawTexturedRect(x, y, menu.w, menu.h)
            render.setRGBA(173, 173, 173, 255)
            render.drawTexturedRect(x+1, y+1, menu.w-2, menu.h-2)
            render.setRGBA(255, 255, 255, 255)
            render.setMaterial(fillToolMat)
            render.drawTexturedRect(x+7, y+5, menu.w-13, menu.h-13)
        end
    )]]
    
    --Add eyedropper button
    addMenuElement(
        menu.w,
        menu.h,
        function(m1, m2)
            if m1 then
                usingFillTool = false
                usingEyedropper = not usingEyedropper
                if usingEyedropper then
                    dontDraw = true
                    capturePixels()
                else
                    dontDraw = true
                end
            end
        end,
        function(x, y)
            render.setRGBA(255, 255, 255, 255)
            render.setRenderTargetTexture("circle")
            render.drawTexturedRect(x, y, menu.w, menu.h)
            render.setRGBA(173, 173, 173, 255)
            render.drawTexturedRect(x+1, y+1, menu.w-2, menu.h-2)
            render.setRGBA(255, 255, 255, 255)
            render.setMaterial(eyedropperMat)
            render.drawTexturedRect(x+7, y+5, menu.w-13, menu.h-13)
        end
    )
    
    --Add pencil scale button
    addMenuElement(
        menu.w,
        menu.h,
        function(m1, m2)
            if m1 then
                thickness = math.min(math.max(math.round(thickness * 1.25), thickness + 1), 50)
            end
            if m2 then
                thickness = math.max(math.min(math.round(thickness / 1.25), thickness - 1), 1)
            end
        end,
        function(x, y)
            render.setRGBA(255, 255, 255, 255)
            render.setRenderTargetTexture("circle")
            render.drawTexturedRect(x, y, menu.w, menu.h)
            render.setRGBA(173, 173, 173, 255)
            render.drawTexturedRect(x+1, y+1, menu.w-2, menu.h-2)
            render.setRGBA(255, 255, 255, 255)
            render.setMaterial(pencilMat)
            render.drawTexturedRect(x+7, y+5, menu.w-13, menu.h-13)
        end
    )
    
    --Add eraser scale button
    addMenuElement(
        menu.w,
        menu.h,
        function(m1, m2)
            if m1 then
                eraserThickness = math.min(math.max(math.round(eraserThickness * 1.25), eraserThickness + 1), 50)
            end
            if m2 then
                eraserThickness = math.max(math.min(math.round(eraserThickness / 1.25), eraserThickness - 1), 1)
            end
        end,
        function(x, y)
            render.setRGBA(255, 255, 255, 255)
            render.setRenderTargetTexture("circle")
            render.drawTexturedRect(x, y, menu.w, menu.h)
            render.setRGBA(173, 173, 173, 255)
            render.drawTexturedRect(x+1, y+1, menu.w-2, menu.h-2)
            render.setRGBA(255, 255, 255, 255)
            render.setMaterial(eraserMat)
            render.drawTexturedRect(x+6.5, y+6.5, menu.w-13, menu.h-13)
        end
    )
    
    --Add color picker button
    addMenuElement(
        menu.w,
        menu.h,
        function(m1, m2)
            if m1 then
                --menu.colorPicker.dontClick = true
                suspendClick = true
                menu.colorPicker.getComponents()
                menu.pickingColor = true
            end
        end,
        function(x, y)
            render.setRGBA(255, 255, 255, 255)
            render.setRenderTargetTexture("circle")
            render.drawTexturedRect(x, y, menu.w, menu.h)
            render.setMaterial(colorPickerMat)
            render.drawTexturedRect(x+1, y+1, menu.w-2, menu.h-2)
        end
    )
    
    --Add color switch buttons
    for i = 2, #colors do
        local width = menu.w*0.8
        local height = menu.h*0.8
        addMenuElement(
            width,
            height,
            function(m1, m2)
                --Change color
                if m1 then
                    for j = #colors, i, -1 do
                        table.insert(colors, 1, table.remove(colors))
                    end
                end
                if m2 then
                    table.insert(colors, table.remove(colors, 1))
                end
            end,
            function(x, y)
                render.setRGBA(255, 255, 255, 255)
                render.setRenderTargetTexture("circle")
                render.drawTexturedRect(x, y, width, height)
                render.setRGBA(colors[i][1], colors[i][2], colors[i][3], 255)
                render.drawTexturedRect(x+1, y+1, width-2, height-2)
            end
        )
    end
    
    local function drawMenu()
        local hovering
        local bounds = menu.calcBounds()
        if cursor[1] and cursor[2] then
            hovering = cursor[1] >= bounds.x and cursor[1] < bounds.x + bounds.w and cursor[2] >= bounds.y and cursor[2] < bounds.y + bounds.h
            if (clicking1 or clicking2) and cursor[1] >= menu.x and cursor[1] < menu.x + menu.w and cursor[2] >= menu.y and cursor[2] < menu.y + menu.h then
                --Change color
                if clicking1 then
                    table.insert(colors, 1, table.remove(colors))
                end
                if clicking2 then
                    table.insert(colors, table.remove(colors, 1))
                end
            end
        else
            hovering = false
        end
        menu.lerpOpen(hovering)
        menu.draw()
        return hovering or menu.pickingColor
    end
    
    local floodFillQueue = {{}, {}}
    local floodFillGrid = {}
    
    hook.add("renderoffscreen", "flood fill", function()
        --print(#(floodFillQueue[1]))
        if #floodFillQueue[1] ~= 0 then
            render.selectRenderTarget("capture")
            local remove = table.remove
            local insert = table.insert
            local readPixel = render.readPixel
            local drawQueue = queue
            local parameters = floodFillQueue[1][1]
            local from = parameters[3]
            local to = parameters[4]
            local queue = floodFillQueue[2]
            local count = #queue
            --print("a")
            if count == 0 then
                insert(queue, {parameters[1], parameters[2]})
                count = 1
                maxQuota = 0
            end
            while quotaAverage() < maxQuota and count ~= 0 do
                count = count - 1
                local point = remove(queue)
                local x, y = point[1], point[2]
                
                local x1, y1 = x+1, y
                if x1 < 1024 then
                    local col = floodFillGrid[x1]
                    if (not col or not col[y1]) and readPixel(x1, y1) == from then
                        if col then
                            col[y1] = true
                        else
                            floodFillGrid[x1] = {[y1] = true}
                        end
                        count = count + 1
                        insert(queue, {x1, y1})
                        local t = {to, x1+1, y1+1, x1+1, y1+1, 1}
                        insert(drawQueue, t)
                        insert(netQueue, t)
                    end
                end
                
                x1, y1 = x, y+1
                if y1 < 1024 then
                    local col = floodFillGrid[x1]
                    if (not col or not col[y1]) and readPixel(x1, y1) == from then
                        if col then
                            col[y1] = true
                        else
                            floodFillGrid[x1] = {[y1] = true}
                        end
                        count = count + 1
                        insert(queue, {x1, y1})
                        local t = {to, x1+1, y1+1, x1+1, y1+1, 1}
                        insert(drawQueue, t)
                        insert(netQueue, t)
                    end
                end
                
                x1, y1 = x-1, y
                if x1 >= 0 then
                    local col = floodFillGrid[x1]
                    if (not col or not col[y1]) and readPixel(x1, y1) == from then
                        if col then
                            col[y1] = true
                        else
                            floodFillGrid[x1] = {[y1] = true}
                        end
                        count = count + 1
                        insert(queue, {x1, y1})
                        local t = {to, x1+1, y1+1, x1+1, y1+1, 1}
                        insert(drawQueue, t)
                        insert(netQueue, t)
                    end
                end
                
                x1, y1 = x, y-1
                if y1 >= 0 then
                    local col = floodFillGrid[x1]
                    if (not col or not col[y1]) and readPixel(x1, y1) == from then
                        if col then
                            col[y1] = true
                        else
                            floodFillGrid[x1] = {[y1] = true}
                        end
                        count = count + 1
                        insert(queue, {x1, y1})
                        local t = {to, x1+1, y1+1, x1+1, y1+1, 1}
                        insert(drawQueue, t)
                        insert(netQueue, t)
                    end
                end
            end
            
            if count <= 0 then
                --Remove
                floodFillGrid = {}
                remove(floodFillQueue[1], 1)
                print(#floodFillQueue[1])
                print(#floodFillQueue[2])
            end
        end
    end)
    
    local function floodFill(x, y, from, to)
        addLine({to, x, y, x, y, 1})
        table.insert(floodFillQueue[1], {x, y, Color(from[1], from[2], from[3], from[4]), Color(to[1], to[2], to[3], to[4])})
        --print(#floodFillQueue[1])
    end

    local oldDraw, oldErase
    hook.add("render", "", function()
        render.setRenderTargetTexture("")
        render.drawTexturedRect(0, 0, 512, 512)
        local screenEnt = render.getScreenEntity()
        if screenEnt and player():getEyeTrace().Entity == screenEnt then
            --try(function()
                cursor[1], cursor[2] = render.cursorPos()
            --[[end, function(error)
                if type(error) == "table" then
                    printTable(error)
                else
                    print(error)
                end
                cursor[1], cursor[2] = nil, nil
            end)]]
        else
            cursor[1], cursor[2] = nil, nil
        end
        local m1a = input.isMouseDown(MOUSE.MOUSE1)
        if suspendClick then
            m1 = false
            if not m1a then
                suspendClick = false
            end
        else
            m1 = m1a
        end
        m2 = input.isMouseDown(MOUSE.MOUSE2)
        clicking1 = m1 and not oldM1
        clicking2 = m2 and not oldM2
        oldM1 = m1
        oldM2 = m2
        
        if cursor[1] and cursor[2] then
            cursor[1] = math.round(cursor[1]*2)*0.5
            cursor[2] = math.round(cursor[2]*2)*0.5
            
            if not drawMenu() and not blacklist and not suspendClick then
                if usingFillTool then
                    --Fill tool
                    oldDraw = nil
                    oldErase = nil
                    render.setRGBA(255, 255, 255, 255)
                    render.setMaterial(fillToolMat)
                    render.drawTexturedRect(cursor[1], cursor[2]-toolSize, toolSize, toolSize)
                    render.setRGBA(255, 255, 255, 255)
                    render.drawRect(cursor[1]-1, cursor[2]-1, 3, 3)
                    render.setColor(colors[1])
                    render.drawRect(cursor[1], cursor[2], 1, 1)
                    if clicking1 then
                        suspendClick = true
                        usingFillTool = false
                        local x = cursor[1]*2
                        local y = cursor[2]*2
                        capturePixels(function()
                            dontDraw = false
                            floodFill(x, y, render.readPixel(x, y), colors[1])
                        end)
                    end
                elseif usingEyedropper then
                    --Eyedropper
                    oldDraw = nil
                    oldErase = nil
                    render.setRGBA(255, 255, 255, 255)
                    render.setMaterial(eyedropperMat)
                    render.drawTexturedRect(cursor[1], cursor[2]-toolSize+1, toolSize, toolSize)
                    render.setRGBA(255, 255, 255, 255)
                    render.drawRect(cursor[1]-1, cursor[2]-1, 3, 3)
                    render.setColor(colors[1])
                    render.drawRect(cursor[1], cursor[2], 1, 1)
                    if clicking1 then
                        suspendClick = true
                        usingEyedropper = false
                        local x = cursor[1]*2
                        local y = cursor[2]*2
                        capturePixels(function()
                            table.insert(colors, table.remove(colors, 1))
                            colors[1] = render.readPixel(x, y)
                            dontDraw = false
                        end)
                    end
                else
                    --Draw
                    if m1 then
                        if oldDraw then
                            --if cursor[1]*2 ~= oldDraw[1] and cursor[2]*2 ~= oldDraw[2] then
                                addLine({colors[1], oldDraw[1], oldDraw[2], cursor[1]*2, cursor[2]*2, thickness})
                            --end
                        else
                            addLine({colors[1], cursor[1]*2, cursor[2]*2, cursor[1]*2, cursor[2]*2, thickness})
                        end
                        oldDraw = {cursor[1]*2, cursor[2]*2}
                    else
                        oldDraw = nil
                    end
            
                    --Erase
                    if m2 then
                        if oldErase then
                            --if cursor[1]*2 ~= oldErase[1] and cursor[2]*2 ~= oldErase[2] then
                                addLine({Color(0,0,0), oldErase[1], oldErase[2], cursor[1]*2, cursor[2]*2, eraserThickness})
                            --end
                        else
                            addLine({Color(0,0,0), cursor[1]*2, cursor[2]*2, cursor[1]*2, cursor[2]*2, eraserThickness})
                        end
                        oldErase = {cursor[1]*2, cursor[2]*2}
                    else
                        oldErase = nil
                    end
            
                    render.setColor(colors[1])
                    render.drawRectOutline(cursor[1] - thickness*0.25, cursor[2] - thickness*0.25, thickness*0.5, thickness*0.5)
                    render.setRGBA(255, 255, 255, 100)
                    render.drawRectOutline(cursor[1] - eraserThickness*0.25, cursor[2] - eraserThickness*0.25, eraserThickness*0.5, eraserThickness*0.5)
                end
            end
        else
            oldDraw = nil
            oldErase = nil
            drawMenu()
        end
    end)
    
    hook.add("think", "cpu", function()
        local max = 0.002
        if player() == owner() then
            max = 0.01
        end
        maxQuota = maxQuota + math.min(math.min(max, quotaMax()*0.75) - maxQuota, CPUStepSizeMult)
        maxQuota = math.min(quotaAverage() + CPUStepSizeMult, maxQuota)
    end)
end