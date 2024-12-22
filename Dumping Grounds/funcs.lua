-- Random functions used in several chips

--@name Funcs
--@author Jacbo

local net = safeNet or net

funcs = {}

funcs.linkToClosestScreen = function(cb)
    local owner = owner()
    local pos = chip():getPos()
    local screen = find.closest(find.byClass("starfall_screen", function(ent)
        return ent:getOwner() == owner
    end), pos)
    if screen then
        screen:linkComponent(chip())
        if cb then
            cb(screen)
        end
    else
        hook.add("tick", "find screen", function()
            screen = find.closest(find.byClass("starfall_screen", function(ent)
                return ent:getOwner() == owner
            end), pos)
            if screen then
                screen:linkComponent(chip())
                if cb then
                    cb(screen)
                end
                hook.remove("tick", "find screen")
            end
        end)
    end
end

-- This isn't uniformly distributed and I dislike this now
funcs.randInCircle = function(centerx, centery, radius)
    local r = math.rand(0, radius)
    return centerx + math.cos(math.rand(-math.pi, math.pi)) * r,
        centery + math.sin(math.rand(-math.pi, math.pi)) * r
end

funcs.copy = function(var)
    local type = type(var)
    if type == "table" then
        local newVar = {}
        if table.isSequential(var) then
            for _, val in pairs(var) do
                table.insert(newVar, funcs.copy(val))
            end
        else
            for key, val in pairs(var) do
                newVar[key] = funcs.copy(val)
            end
        end
        return newVar
    elseif type == "Vector" then
        return Vector(var[1], var[2], var[3])
    elseif type == "Angle" then
        return Angle(var[1], var[2], var[3])
    elseif type == "Color" then
        return Color(var[1], var[2], var[3], var[4])
    end
    return var
end

funcs.round = function(var, digits)
    local type = type(var)
    if type == "table" then
        local newVar = {}
        if table.isSequential(var) then
            for _, val in pairs(var) do
                table.insert(newVar, funcs.round(val, digits))
            end
        else
            for key, val in pairs(var) do
                newVar[key] = funcs.round(val, digits)
            end
        end
        return newVar
    elseif type == "Vector" then
        return Vector(math.round(var[1], digits), math.round(var[2], digidts), math.round(var[3], digits))
    elseif type == "Angle" then
        return Angle(math.round(var[1], digits), math.round(var[2], digits), math.round(var[3], digits))
    elseif type == "Color" then
        return Color(math.round(var[1], digits), math.round(var[2], digits), math.round(var[3], digits), math.round(var[4], digits))
    elseif type == "number" then
        return math.round(var, digits)
    end
    return var
end

funcs.randVec = function(min, max)
    local rand = math.rand
    local minv = min
    local maxv = max
    if type(min) == "number" then minv = Vector(min) end
    if type(max) == "number" then maxv = Vector(max) end
    return Vector(rand(minv[1], maxv[1]), rand(minv[2], maxv[2]), rand(minv[3], maxv[3]))
end

funcs.randAng = function(min, max)
    local rand = math.rand
    local mina = min
    local maxa = max
    if type(min) == "number" then mina = Angle(min) end
    if type(max) == "number" then maxa = Angle(max) end
    return Angle(rand(mina[1], maxa[1]), rand(mina[2], maxa[2]), rand(mina[3], maxa[3]))
end

funcs.randColor = function(min, max)
    local rand = math.rand
    local minc = min
    local minc = max
    if type(min) == "number" then minc = Color(min, min, min) end
    if type(max) == "number" then minc = Color(max, max, max) end
    return Color(rand(minc[1], minc[1]), rand(minc[2], minc[2]), rand(minc[3], minc[3]), rand(minc[4], minc[4]))
end

funcs.clamp = function(var, min, max)
    local type = type(var)
    if type == "table" then
        local newVar = {}
        if table.isSequential(var) then
            for _, val in pairs(var) do
                table.insert(newVar, funcs.clamp(val, min, max))
            end
        else
            for key, val in pairs(var) do
                newVar[key] = funcs.clamp(val, min, max)
            end
        end
        return newVar
    elseif type == "Vector" then
        local minv = min
        local maxv = max
        if type(min) == "number" then minv = Vector(min) end
        if type(max) == "number" then maxv = Vector(max) end
        return Vector(math.clamp(var[1], minv[1], maxv[1]), math.clamp(var[2], minv[2], maxv[2]), math.clamp(var[3], minv[3], maxv[3]))
    elseif type == "Angle" then
        local mina = min
        local mina = max
        if type(min) == "number" then mina = Angle(min) end
        if type(max) == "number" then mina = Angle(max) end
        return Angle(math.clamp(var[1], mina[1], mina[1]), math.clamp(var[2], mina[2], mina[2]), math.clamp(var[3], mina[3], mina[3]))
    elseif type == "Color" then
        local minc = min
        local minc = max
        if type(min) == "number" then minc = Color(min, min, min, 255) end
        if type(max) == "number" then minc = Color(max, max, max, 0) end
        return Color(math.clamp(var[1], minc[1], minc[1]), math.clamp(var[2], minc[2], minc[2]), math.clamp(var[3], minc[3], minc[3]), math.clamp(var[4], minc[4], minc[4]))
    elseif type == "number" then
        return math.clamp(var, min, max)
    end
    return var
end

funcs.findLast = function(haystack, needle)
    local pos = string.find(string.reverse(haystack), string.reverse(needle), 1, true)
    if pos == nil then
        return nil
    end
    return #haystack - pos - #needle + 2
end

funcs.stringSwap = function(text, with, start, stop)
    if start == 1 and stop == #text then
        return with
    elseif start == 1 then
        return with .. string.sub(text, stop + 1, #text)
    elseif stop == #text then
        return string.sub(text, 1, start - 1) .. with
    else
        return string.sub(text, 1, start - 1) .. with .. string.sub(text, stop + 1, #text)
    end
end

local printCode
printCode = function(var)
    if var == nil then return "nil" end
    local str = ""
    local type = type(var)
    if type == "table" then
        str = str .. "{"
        local skipComma = true
        if table.isSequential(var) then
            for _, val in ipairs(var) do
                if skipComma then
                    skipComma = false
                else
                    str = str .. ", "
                end
                str = str .. printCode(val)
            end
        else
            for key, val in pairs(var) do
                if skipComma then
                    skipComma = false
                else
                    str = str .. ", "
                end
                str = str .. "[" .. tostring(key) .. "] = " .. printCode(val)
            end
        end
        str = str .. "}"
    elseif type == "Vector" then
        str = str .. "Vector(" .. var[1] .. ", " .. var[2] .. ", " .. var[3] .. ")"
    elseif type == "Angle" then
        str = str .. "Angle(" .. var[1] .. ", " .. var[2] .. ", " .. var[3] .. ")"
    elseif type == "Color" then
        if var[4] == 255 then
            str = str .. "Color(" .. var[1] .. ", " .. var[2] .. ", " .. var[3] .. ")"
        else
            str = str .. "Color(" .. var[1] .. ", " .. var[2] .. ", " .. var[3] .. ", " .. var[4] .. ")"
        end
    elseif type == "string" then
        str = str .. "\"" .. var .. "\""
    elseif type == "Quaternion" then
        str = "Quaternion(" .. var[1] .. ", " .. var[2] .. ", " .. var[3] .. ", " .. var[4] .. ")"
    elseif type == "Entity" then
        str = "Ent[" .. var:entIndex() .. "]"
    elseif type == "Player" then
        str = "Ply[" .. var:getSteamID() .. "]"
    elseif var == true then
        str = str .. "true"
    elseif var == false then
        str = str .. "false"
    else
        try(function() str = str .. var end)
    end
    return str
end

funcs.formatTable = printCode

funcs.printCode = function(var)
    print(printCode(var))
end

funcs.padLeft = function(val, chars)
    local s = tostring(val)
    return string.rep(" ", math.max(0, chars - #s)) .. s
end

funcs.padRight = function(val, chars)
    local s = tostring(val)
    return s .. string.rep(" ", math.max(0, chars - #s))
end

local compactTablePrint
compactTablePrint = function(var)
    local str = ""
    local skipComma = true
    for key, val in pairs(var) do
        if skipComma then
            skipComma = false
        else
            str = str .. "\n"
        end
        if type(val) == "table" then
            str = str .. key .. " = " .. compactTablePrint(val)
        else
            str = str .. key .. " = " .. val
        end
    end
    return str
end

funcs.ctprint = function(var)
    print(compactTablePrint(var))
end

funcs.lineSegIntersect = function(x1, y1, x2, y2, x3, y3, x4, y4)
    if x1 > x2 then
        local tempx, tempy = x1, y1
        x1 = x2
        y1 = y2
        x2 = tempx
        y2 = tempy
    end
    if x3 > x4 then
        local tempx, tempy = x3, y3
        x3 = x4
        y3 = y4
        x4 = tempx
        y4 = tempy
    end
    local denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
    if denom == 0 then return end
    local ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
    local ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom
    if ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1 then
        return x1 + ua*(x2-x1), y1 + ua*(y2-y1)
    end
end

funcs.lineIntersect = function(x1, y1, x2, y2, x3, y3, x4, y4)
    if x1 > x2 then
        local tempx, tempy = x1, y1
        x1 = x2
        y1 = y2
        x2 = tempx
        y2 = tempy
    end
    if x3 > x4 then
        local tempx, tempy = x3, y3
        x3 = x4
        y3 = y4
        x4 = tempx
        y4 = tempy
    end
    local denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
    if denom == 0 then return end
    local ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
    local ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom
    return x1 + ua*(x2-x1), y1 + ua*(y2-y1)
end

--cb(vismesh)
funcs.processVisMesh = function(meshTable, quotaMax, cb)
    local name = "loading vis mesh" .. math.rand(0, 1)
    local vismesh
    local loadmesh = coroutine.wrap(function() vismesh = mesh.createFromTable(meshTable, true) return true end)
    hook.add("think", name, function()
        while quotaAverage() < quotaMax do
            if loadmesh() == true then
                hook.remove("think", name)
                cb(vismesh)
                break
            end
        end
    end)
end

-- Rescales the dimensions to fit inside the new dimensions while maintaining aspect ratio
funcs.rescale = function(oldWidth, oldHeight, newWidth, newHeight)
    local ratio = math.min(newWidth / oldWidth, newHeight / oldHeight)
    return oldWidth * ratio,
        oldHeight * ratio,
        ratio
end

funcs.minValue = function(tbl)
    local min = math.huge
    local mindex = nil
    for i, j in pairs(tbl) do
        if j < min then
            min = j
            mindex = i
        end
    end
    return min, mindex
end

funcs.maxValue = function(tbl)
    local max = -math.huge
    local maxdex = nil
    for i, j in pairs(tbl) do
        if j > max then
            max = j
            maxdex = i
        end
    end
    return max, maxdex
end

funcs.tableAdd = function(a, b)
    local result = {}
    if type(b) == "table" then
        for i = 1, math.min(#a, #b) do
            table.insert(result, a[i] + b[i])
        end
    else
        for _, i in ipairs(a) do
            table.insert(result, i + b)
        end
    end
    return result
end

funcs.tableSub = function(a, b)
    local result = {}
    if type(b) == "table" then
        for i = 1, math.min(#a, #b) do
            table.insert(result, a[i] - b[i])
        end
    else
        for _, i in ipairs(a) do
            table.insert(result, i - b)
        end
    end
    return result
end

funcs.tableMult = function(a, b)
    local result = {}
    if type(b) == "table" then
        for i = 1, math.min(#a, #b) do
            table.insert(result, a[i] * b[i])
        end
    else
        for _, i in ipairs(a) do
            table.insert(result, i * b)
        end
    end
    return result
end

funcs.tableDiv = function(a, b)
    local result = {}
    if type(b) == "table" then
        for i = 1, math.min(#a, #b) do
            table.insert(result, a[i] / b[i])
        end
    else
        for _, i in ipairs(a) do
            table.insert(result, i / b)
        end
    end
    return result
end

funcs.drawCircle = function(x, y, radius, steps)
    local poly = {}
    local deg2rad = math.pi/180
    local interval = 360/steps
    for i=1, 360-interval*0.5, interval do
        local theta = i*deg2rad
        table.insert(poly, {x=x+radius+radius*math.cos(theta), y=y+radius+radius*math.sin(theta)})
    end
    render.drawPoly(poly)
end

funcs.drawArc = function(x, y, radius, thickness, startAng, arcAng, interval)
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

funcs.drawLine = function(ax, ay, bx, by, thickness)
    if ax == bx and ay == by then
        render.drawRect(ax-thickness*0.5, ay-thickness*0.5, thickness, thickness)
        return
    end
    local sidex = by - ay
    local sidey = ax - bx
    local length = math.sqrt(sidex * sidex + sidey * sidey)
    sidex = sidex * thickness * 0.5 / length
    sidey = sidey * thickness * 0.5 / length
    render.drawPoly({
        {x = ax - sidex, y = ay - sidey},
        {x = ax + sidex, y = ay + sidey},
        {x = bx + sidex, y = by + sidey},
        {x = bx - sidex, y = by - sidey}
    })
end

funcs.httpGetAsync = function(url, cb, badcb, hookToUse)
    if http.canRequest() then
        http.get(url, cb, badcb)
    else
        hook.add(hookToUse or "think", "http.get " .. url, function()
            if http.canRequest() then
                http.get(url, cb, badcb)
                hook.remove(hookToUse or "think", "http.get " .. url)
            end
        end)
    end
end

--Made for floating point calculations
funcs.hsvToRGB = function(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    c = c * 255
    x = x * 255
    if h < 60 then return Vector(c, x, 0) end
    if h < 120 then return Vector(x, c, 0) end
    if h < 180 then return Vector(0, c, x) end
    if h < 240 then return Vector(0, x, c) end
    if h < 300 then return Vector(x, 0, c) end
    return Vector(c, 0, x)
end

--Made for floating point calculations
funcs.rgbToHSV = function(r, g, b)
    r = r / 255
    g = g / 255
    b = b / 255
    local cmax = math.max(r, g, b)
    local cmin = math.min(r, g, b)
    local delta = cmax - cmin
    
    --Calculate hue
    local hue
    if delta == 0 then
        hue = 0
    elseif cmax == r then
        hue = 60 * (((g - b) / delta) % 6)
    elseif cmax == g then
        hue = 60 * ((b - r) / delta + 2)
    else
        hue = 60 * ((r - g) / delta + 4)
    end
    
    --Calculate saturation
    local sat
    if cmax == 0 then
        sat = 0
    else
        sat = delta / cmax
    end
    
    return Vector(hue, sat, cmax)
end


--[[
    Loads an uncropped image
    
    url = image url
    
    xAlignment = nil, 0, 1, 2 <> defaults to nil
    0 = Left, 1 = Center, 2 = Right
    
    yAlignment = nil, 0, 1, 2 <> defaults to nil
    0 = Top, 1 = Center, 2 = Bottom
    
    mat = material input or nil <> defaults to material.create("UnlitGeneric")
    
    key = texture key or nil <> defaults to $basetexture
    
    scaleUp = boolean or nil <> defaults to true
    true = do scale up/down, false = don't scale up but scale down to prevent cropping
    
    successCB = function or nil
    Called with mat, url, x, y, width, height when the image is loaded
    
    failCB = function or nil
    Called with no input when image fails
    
    doneCB = function or nil
    Same as the done callback in material:setTextureURL()
    Called when the image is finished loading
]]
funcs.loadMat = function(url, xAlignment, yAlignment, mat, key, scaleUp, successCB, failCB, doneCB)
    local createdMat = false
    if not mat then
        mat = material.create("UnlitGeneric")
        createdMat = true
    end
    key = key or "$basetexture"
    if scaleUp == nil then
        scaleUp = true
    end
    xAlignment = xAlignment or 0
    yAlignment = yAlignment or 0
    mat:setTextureURL(key, url, function(_, _, width, height, layout)
        if width then
            --Success
            local w, h, x, y
            if scaleUp or (width > 1024 or height > 1024) then
                --Rescale
                local ratio = math.min(1024 / width, 1024 / height)
                w = width * ratio
                h = height * ratio
            else
                w = width
                h = height
            end
            --Align x
            if xAlignment == 0 then
                --Left
                x = 0
            elseif xAlignment == 1 then
                --Center
                x = (1024 - w) * 0.5
            elseif xAlignment == 2 then
                --Right
                x = 1024 - w
            else
                error("xAlignment must be nil, 0, 1, or 2")
            end
            --Align y
            if yAlignment == 0 then
                --Top
                y = 0
            elseif yAlignment == 1 then
                --Center
                y = (1024 - h) * 0.5
            elseif yAlignment == 2 then
                --Bottom
                y = 1024 - h
            else
                error("yAlignment must be nil, 0, 1, or 2")
            end
            
            layout(x, y, w, h)
            if successCB then
                successCB(mat, url, x, y, w, h)
            end
        else
            --Fail
            if createdMat then
                mat:destroy()
                mat = nil
            end
            if failCB then
                failCB()
            end
        end
    end,
    doneCB)
    
    return mat
end

function find.byType(type, filter)
    local filter_func
    if filter then
        filter_func = function(ent)
            return type(ent) == type and filter(ent)
        end
    else
        filter_func = function(ent)
            return type(ent) == type
        end
    end
    
    return find.all(filter_func)
end

function find.playersBySteamID(id, filter)
    local filter_func
    if filter then
        filter_func = function(ply)
            return ply:getSteamID() == id and filter(ply)
        end
    else
        filter_func = function(ply)
            return ply:getSteamID() == id
        end
    end
    
    find.allPlayers(filter_func)
end

getMethods("Player")["getAimEnt"] = function(ply)
    return ply:getEyeTrace().Entity
end

if SERVER then
    net.receive("self destruct", function()
        chip():remove()
    end)
    function funcs.selfDestruct()
        chip():remove()
    end
else
    function funcs.selfDestruct()
        net.start("self destruct")
        net.send()
    end
end
        

return funcs