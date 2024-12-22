-- Spawn 6 32x32 plate screens then spawn this chip (read below first). It will put the screens in a box and create basically a skybox inside.
-- This was made when you could easily use Discord as a file host (lol) but now Discord URLs expire but can be refreshed.
-- urlList is full of Discord image URLs that are likely all expired. You can refresh them by posting each link in Discord.
-- It would be a good idea to just upload them somewhere else instead like Dropbox.

--@name Room
--@author Jacbo
--@shared

--Get an hdri from https://hdrihaven.com/hdris/
--Convert it to 6 separate images with https://matheowis.github.io/HDRI-to-CubeMap/
--URL order from images: image 2, image 1, image 3, image 4, image 6, image 5
local randomURLs = true
local size = 32
if SERVER then
    local urlInterval = 60
    local screens = find.byClass("starfall_screen", function(ent)
        if ent:getOwner() != owner() then
            return false
        end
        return true
    end)
    if #screens != 6 then
        print("Spawn 6 starfall screens")
        chip():remove()
    else
        local center = chip():getPos() + Vector(0,0,3 + 47.45 * size / 2)
        local origin = chip():getPos() + Vector(0,0,3)
        local pos, ang, ent = origin, Angle(0,90,0), screens[1]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        ent:setNocollideAll(false)
        
        pos, ang, ent = origin + Vector(47.45, 0, 47.45) * size / 2, Angle(90,180,0), screens[2]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        ent:setNocollideAll(true)
        
        pos, ang, ent = origin + Vector(0, 47.45, 47.45) * size / 2, Angle(0,0,90), screens[3]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        ent:setNocollideAll(true)
        
        pos, ang, ent = origin + Vector(-47.45, 0, 47.45) * size / 2, Angle(90,0,0), screens[4]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        ent:setNocollideAll(true)
        
        pos, ang, ent = origin + Vector(0, -47.45, 47.45) * size / 2, Angle(0,180,90), screens[5]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        ent:setNocollideAll(true)
        
        pos, ang, ent = origin + Vector(0, 0, 47.45) * size, Angle(180,90,0), screens[6]
        pos, ang = localToWorld(-ent:obbCenter(), Angle(0,0,0), pos, ang)
        ent:setPos(pos)
        ent:setAngles(ang)
        ent:setNocollideAll(false)
        
        for i = 1, 6 do
            screens[i]:linkComponent(chip())
            screens[i]:setFrozen(true)
            screens[i]:setColor(Color(255,255,255,1))
        end
        
        if randomURLs then
            local urlList = {
                {"https://cdn.discordapp.com/attachments/607371740540305424/791309795013033984/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791309962391060480/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791317496674254858/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791318110979883018/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791318211877404672/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791318195361415188/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791337085898457148/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791337095050428436/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791337106563661844/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791337117074194432/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791337143607099392/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791337152427982868/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791345338383466496/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791345348345724958/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791345359557361675/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791345367794057246/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791345379504554026/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791345394901581935/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791353058533310495/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791353071045312512/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791353084760031265/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791353101213892618/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791353113587482684/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791353123842162698/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791354786313273354/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791354795533402112/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791354807164076032/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791354817711702036/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791354827501600789/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791354834984501258/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791357111870685204/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791357121106804756/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791357130443063306/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791360221943431168/px_-_Copy.png", "https://cdn.discordapp.com/attachments/607371740540305424/791357158394560542/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791357169987485747/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png", "https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png", "https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png", "https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png", "https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png", "https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791403574273638490/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791403586591653918/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791403598830764102/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791403610649919508/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791403624508293140/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791403633429970984/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791422875248099359/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791422884975214652/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791422897721573376/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791422907854094346/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791422919170457620/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791422933737799730/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791720708912840764/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791720722762170378/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791720735940018196/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791720746333372476/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791720759306485790/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791720771562635334/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791718601135751178/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791718615849631754/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791718629224873994/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791718642311102504/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791718655540854794/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791718666190323762/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791424713237856276/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791424722242895932/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791424732742025246/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791424746973167676/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791424765562191902/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791424777810214912/py.png"},
                {"https://cdn.discordapp.com/attachments/607371740540305424/791400820621049926/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791400838039076884/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791400848076963871/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791400863398232095/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791400876509757450/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791400887733190676/py.png"}
            }
            local available = {}
            local currentSet = {}
            
            local function getNewSet()
                local current = 1
                if #available == 0 then
                    local t = {}
                    for i = 1, #urlList do
                        table.insert(t, i)
                    end
                    for i = 1, #urlList do
                        table.insert(available, table.remove(t, math.random(1, #t)))
                    end
                end
                current = available[#available]
                table.remove(available)
                currentSet = urlList[current]
                
                net.start("new set")
                net.writeTable(currentSet)
                net.send()
                
                net.start("room")
                for i = 1, 6 do
                    net.writeEntity(screens[i])
                end
                net.writeVector(center)
                net.send()
            end
            
            getNewSet()
            
            timer.create("url timer", urlInterval, 0, getNewSet)
            
            net.receive("room", function(_, ply)
                net.start("room")
                for i = 1, 6 do
                    net.writeEntity(screens[i])
                end
                net.writeVector(center)
                net.send(ply)
                net.start("new set")
                net.writeTable(currentSet)
                net.send(ply)
            end)
        else
            net.receive("room", function(_, ply)
                net.start("room")
                for i = 1, 6 do
                    net.writeEntity(screens[i])
                end
                net.writeVector(center)
                net.send(ply)
            end)
        end
    end
else --CLIENT
    net.start("room")
    net.send()
    local screens = nil
    local images = {}
    for i = 1, 6 do
        images[i] = material.create("UnlitGeneric")
    end
    local urls = {}
    if randomURLs then
        net.receive("new set", function()
            urls = net.readTable()
            images[1]:setTextureURL("$basetexture", urls[1])
            images[2]:setTextureURL("$basetexture", urls[2])
            images[3]:setTextureURL("$basetexture", urls[3])
            images[4]:setTextureURL("$basetexture", urls[4])
            images[5]:setTextureURL("$basetexture", urls[5])
            images[6]:setTextureURL("$basetexture", urls[6])
        end)
    else
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791309795013033984/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791309962391060480/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791317496674254858/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791318110979883018/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791318211877404672/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791318195361415188/py.png"}
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791337085898457148/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791337095050428436/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791337106563661844/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791337117074194432/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791337143607099392/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791337152427982868/py.png"}
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791345338383466496/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791345348345724958/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791345359557361675/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791345367794057246/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791345379504554026/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791345394901581935/py.png"}
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791353058533310495/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791353071045312512/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791353084760031265/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791353101213892618/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791353113587482684/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791353123842162698/py.png"}
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791354786313273354/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791354795533402112/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791354807164076032/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791354817711702036/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791354827501600789/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791354834984501258/py.png"}
        --Cave face
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791357111870685204/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791357121106804756/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791357130443063306/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791360221943431168/px_-_Copy.png", "https://cdn.discordapp.com/attachments/607371740540305424/791357158394560542/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791357169987485747/py.png"}
        --risitas
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png", "https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png", "https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png", "https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png", "https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png", "https://cdn.discordapp.com/attachments/607371740540305424/791369273880084510/risitaskek.png"}
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791403574273638490/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791403586591653918/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791403598830764102/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791403610649919508/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791403624508293140/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791403633429970984/py.png"}
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791422875248099359/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791422884975214652/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791422897721573376/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791422907854094346/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791422919170457620/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791422933737799730/py.png"}
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791720708912840764/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791720722762170378/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791720735940018196/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791720746333372476/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791720759306485790/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791720771562635334/py.png"}
        --night town
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791718601135751178/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791718615849631754/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791718629224873994/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791718642311102504/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791718655540854794/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791718666190323762/py.png"}
        --Mountaintop
        urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791424713237856276/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791424722242895932/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791424732742025246/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791424746973167676/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791424765562191902/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791424777810214912/py.png"}
        --local urls = {"https://cdn.discordapp.com/attachments/607371740540305424/791400820621049926/ny.png", "https://cdn.discordapp.com/attachments/607371740540305424/791400838039076884/nx.png", "https://cdn.discordapp.com/attachments/607371740540305424/791400848076963871/nz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791400863398232095/px.png", "https://cdn.discordapp.com/attachments/607371740540305424/791400876509757450/pz.png", "https://cdn.discordapp.com/attachments/607371740540305424/791400887733190676/py.png"}
        images[1]:setTextureURL("$basetexture", urls[1])
        images[2]:setTextureURL("$basetexture", urls[2])
        images[3]:setTextureURL("$basetexture", urls[3])
        images[4]:setTextureURL("$basetexture", urls[4])
        images[5]:setTextureURL("$basetexture", urls[5])
        images[6]:setTextureURL("$basetexture", urls[6])
    end
    local center = Vector(0,0,0)
    local length = 25000 / 2
    net.receive("room",function()
        screens = {}
        for i = 1, 6 do
            screens[i] = net.readEntity()
        end
        center = net.readVector()
    end)
        --local length = 47.45 * 32 / 2
        local minU = 1 / 1024
        local minV = 1 / 1024
        local maxU = 1023 / 1024
        local maxV = 1023 / 1024
        --[[hook.add("think", "", function()
            local min = 32 * 47.45 / 2
            local max = 25000 / 2
            length = (math.sin(timer.systime()) / 2 + 0.5) * (max - min) + min
        end)]]
        --center = center + Vector(0,0,Length)
        if true then
        hook.add("render", "", function()
            center = eyePos()
            local screen = render.getScreenEntity()
            render.pushMatrix(Matrix(), true)
            render.setMaterial(images[1])
            render.draw3DQuadUV(
                {-length + center[1], length + center[2], -length + center[3], minU, minV},
                {length + center[1], length + center[2], -length + center[3], maxU, minV},
                {length + center[1], -length + center[2], -length + center[3], maxU, maxV},
                {-length + center[1], -length + center[2], -length + center[3], minU, maxV}
            )
            render.setMaterial(images[2])
            render.draw3DQuadUV(
                {-length + center[1], -length + center[2], length + center[3], minU, minV},
                {-length + center[1], length + center[2], length + center[3], maxU, minV},
                {-length + center[1], length + center[2], -length + center[3], maxU, maxV},
                {-length + center[1], -length + center[2], -length + center[3], minU, maxV}
            )
            render.setMaterial(images[3])
            render.draw3DQuadUV(
                {-length + center[1], -length + center[2], -length + center[3], maxU, maxV},
                {length + center[1], -length + center[2], -length + center[3], minU, maxV},
                {length + center[1], -length + center[2], length + center[3], minU, minV},
                {-length + center[1], -length + center[2], length + center[3], maxU, minV}
            )
            render.setMaterial(images[4])
            render.draw3DQuadUV(
                {length + center[1], -length + center[2], -length + center[3], maxU, maxV},
                {length + center[1], length + center[2], -length + center[3], minU, maxV},
                {length + center[1], length + center[2], length + center[3], minU, minV},
                {length + center[1], -length + center[2], length + center[3], maxU, minV}
            )
            render.setMaterial(images[5])
            render.draw3DQuadUV(
                {-length + center[1], length + center[2], length + center[3], minU, minV},
                {length + center[1], length + center[2], length + center[3], maxU, minV},
                {length + center[1], length + center[2], -length + center[3], maxU, maxV},
                {-length + center[1], length + center[2], -length + center[3], minU, maxV}
            )
            render.setMaterial(images[6])
            render.draw3DQuadUV(
                {-length + center[1], -length + center[2], length + center[3], minU, minV},
                {length + center[1], -length + center[2], length + center[3], maxU, minV},
                {length + center[1], length + center[2], length + center[3], maxU, maxV},
                {-length + center[1], length + center[2], length + center[3], minU, maxV}
            )
            render.popMatrix()
        end)
        else
        local corners = {
            {
                Vector(-length, length, -length),
                Vector(length, length, -length),
                Vector(length, -length, -length),
                Vector(-length, -length, -length)
            },
            {
                Vector(-length, -length, length),
                Vector(-length, length, length),
                Vector(-length, length, -length),
                Vector(-length, -length, -length)
            },
            {
                Vector(-length, -length, -length),
                Vector(length, -length, -length),
                Vector(length, -length, length),
                Vector(-length, -length, length)
            },
            {
                Vector(length, -length, -length),
                Vector(length, length, -length),
                Vector(length, length, length),
                Vector(length, -length, length)
            },
            {
                Vector(-length, length, length),
                Vector(length, length, length),
                Vector(length, length, -length),
                Vector(-length, length, -length)
            },
            {
                Vector(-length, -length, length),
                Vector(length, -length, length),
                Vector(length, length, length),
                Vector(-length, length, length)
            }
        }
        local newCorners = {}
        for v,k in pairs(corners) do
            local t = {}
            for j,l in pairs(k) do
                table.insert(t, l:clone())
            end
            table.insert(newCorners, t)
        end
        local ang = Angle(0,0,0)
        local angDir = Angle(45, 39, 26)
        --local angDir = Angle(0, 39, 0)
        
        --local n = 0
        
        hook.add("think", "", function()
        local min = 32 * 47.45 / 2 * math.sqrt(3)
            local max = 25000 / 2
            length = (math.sin(timer.systime()) / 2 + 0.5) * (max - min) + min
            corners = {
            {
                Vector(-length, length, -length),
                Vector(length, length, -length),
                Vector(length, -length, -length),
                Vector(-length, -length, -length)
            },
            {
                Vector(-length, -length, length),
                Vector(-length, length, length),
                Vector(-length, length, -length),
                Vector(-length, -length, -length)
            },
            {
                Vector(-length, -length, -length),
                Vector(length, -length, -length),
                Vector(length, -length, length),
                Vector(-length, -length, length)
            },
            {
                Vector(length, -length, -length),
                Vector(length, length, -length),
                Vector(length, length, length),
                Vector(length, -length, length)
            },
            {
                Vector(-length, length, length),
                Vector(length, length, length),
                Vector(length, length, -length),
                Vector(-length, length, -length)
            },
            {
                Vector(-length, -length, length),
                Vector(length, -length, length),
                Vector(length, length, length),
                Vector(-length, length, length)
            }
        }
            ang = ang + angDir * timer.frametime()
            for v,k in pairs(corners) do
                for j,l in pairs(k) do
                    --n = n + 1
                    --if n % 3 != 0 then
                        newCorners[v][j] = localToWorld(l, Angle(0,0,0), center, ang)
                    --end
                end
            end
        end)
        hook.add("render", "", function()
            local screen = render.getScreenEntity()
            render.pushMatrix(Matrix(), true)
            render.setMaterial(images[1])
            render.draw3DQuadUV(
                {newCorners[1][1][1], newCorners[1][1][2], newCorners[1][1][3], minU, minV},
                {newCorners[1][2][1], newCorners[1][2][2], newCorners[1][2][3], maxU, minV},
                {newCorners[1][3][1], newCorners[1][3][2], newCorners[1][3][3], maxU, maxV},
                {newCorners[1][4][1], newCorners[1][4][2], newCorners[1][4][3], minU, maxV}
            )
            render.setMaterial(images[2])
            render.draw3DQuadUV(
                {newCorners[2][1][1], newCorners[2][1][2], newCorners[2][1][3], minU, minV},
                {newCorners[2][2][1], newCorners[2][2][2], newCorners[2][2][3], maxU, minV},
                {newCorners[2][3][1], newCorners[2][3][2], newCorners[2][3][3], maxU, maxV},
                {newCorners[2][4][1], newCorners[2][4][2], newCorners[2][4][3], minU, maxV}
            )
            render.setMaterial(images[3])
            render.draw3DQuadUV(
                {newCorners[3][1][1], newCorners[3][1][2], newCorners[3][1][3], maxU, maxV},
                {newCorners[3][2][1], newCorners[3][2][2], newCorners[3][2][3], minU, maxV},
                {newCorners[3][3][1], newCorners[3][3][2], newCorners[3][3][3], minU, minV},
                {newCorners[3][4][1], newCorners[3][4][2], newCorners[3][4][3], maxU, minV}
            )
            render.setMaterial(images[4])
            render.draw3DQuadUV(
                {newCorners[4][1][1], newCorners[4][1][2], newCorners[4][1][3], maxU, maxV},
                {newCorners[4][2][1], newCorners[4][2][2], newCorners[4][2][3], minU, maxV},
                {newCorners[4][3][1], newCorners[4][3][2], newCorners[4][3][3], minU, minV},
                {newCorners[4][4][1], newCorners[4][4][2], newCorners[4][4][3], maxU, minV}
            )
            render.setMaterial(images[5])
            render.draw3DQuadUV(
                {newCorners[5][1][1], newCorners[5][1][2], newCorners[5][1][3], minU, minV},
                {newCorners[5][2][1], newCorners[5][2][2], newCorners[5][2][3], maxU, minV},
                {newCorners[5][3][1], newCorners[5][3][2], newCorners[5][3][3], maxU, maxV},
                {newCorners[5][4][1], newCorners[5][4][2], newCorners[5][4][3], minU, maxV}
            )
            render.setMaterial(images[6])
            render.draw3DQuadUV(
                {newCorners[6][1][1], newCorners[6][1][2], newCorners[6][1][3], minU, minV},
                {newCorners[6][2][1], newCorners[6][2][2], newCorners[6][2][3], maxU, minV},
                {newCorners[6][3][1], newCorners[6][3][2], newCorners[6][3][3], maxU, maxV},
                {newCorners[6][4][1], newCorners[6][4][2], newCorners[6][4][3], minU, maxV}
            )
            render.popMatrix()
        end)
        end
end