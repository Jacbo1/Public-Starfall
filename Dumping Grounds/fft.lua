--@name Singing Cubes
--@author Jacbo
--@client

local fps = 60
local samples = 6
local count = 40
--local max = 0.125
local max = 0.05
local size = 10
local volumeMult = 10

local halfSize = size/2
local xscale = size/12
local zscale = halfSize/12
local bottomHeight = size/4
local topHeight = size*3/4
local fft = {}
local interval = 256 * 2^samples * max / count
local eyeScale = size/5/12
local topxscale = size/47.45
local topzscale = halfSize/47.45

local spacing = size/10
local radius = count * (size + spacing) / (2 * math.pi)
local angInterval = math.pi / count * 2
local chip = chip()
local cp = chip:getPos()

local bottoms = {}
local hinges = {}
local tops = {}

local nextFrameTime = timer.curtime()

--local topMat = render.createRenderTarget("top")
--local circle = render.createRenderTarget("circle")
--11.8125
for i = 1, count do
    local ang = i * angInterval
    local yaw = math.deg(ang)
    
    local bottom = holograms.create(cp + Vector(radius * math.cos(ang), radius * math.sin(ang), bottomHeight), Angle(0,yaw,0), "models/holograms/cube.mdl", Vector(xscale,xscale,zscale))
    bottom:setParent(chip)
    table.insert(bottoms,bottom)
    
    local hinge = holograms.create(cp + Vector((radius - halfSize) * math.cos(ang), (radius - halfSize) * math.sin(ang), halfSize), Angle(0,yaw,0), "models/holograms/cube.mdl", Vector())
    hinge:setParent(bottom)
    table.insert(hinges,hinge)
    
    local top = holograms.create(cp + Vector(radius * math.cos(ang), radius * math.sin(ang), topHeight), Angle(0,yaw,0), "models/holograms/cube.mdl", Vector(xscale,xscale,zscale))
    --local top = holograms.create(cp + Vector(radius * math.cos(ang), radius * math.sin(ang), topHeight), Angle(0,yaw,0), "models/hunter/blocks/cube1x1x1.mdl", Vector(topxscale,topxscale,topzscale))
    table.insert(tops,top)
    top:setParent(hinge)
    
    local eyeAng = Angle(90,yaw,0)
    local eyeRight = eyeAng:getRight() * size/3
    
    local eye = holograms.create(cp + eyeRight + Vector((radius + halfSize+0.25) * math.cos(ang), (radius + halfSize+1) * math.sin(ang), topHeight), eyeAng, "models/holograms/cplane.mdl", Vector(eyeScale,eyeScale,eyeScale))
    eye:setColor(Color(0,0,0))
    eye:setParent(top)
    
    local eye2 = holograms.create(cp - eyeRight + Vector((radius + halfSize+0.25) * math.cos(ang), (radius + halfSize+1) * math.sin(ang), topHeight), eyeAng, "models/holograms/cplane.mdl", Vector(eyeScale,eyeScale,eyeScale))
    eye2:setColor(Color(0,0,0))
    eye2:setParent(top)
end
radius = (halfSize^2 + (size / 4)^2)^0.5
--bass.loadURL( "https://play.sas-media.ru/play_256", "3d noblock", function(Sound)
--bass.loadURL( "https://skspoof.000webhostapp.com/Audio/17%20Burning%20Sunset.mp3", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/ewstmtg3bamwt8p/untitled.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/sfyr7xwe4dm3ysp/aaaaaaaaaaaaaaaaaaaa.mp3?dl=1", "3d noblock", function(Sound)
--bass.loadURL( "https://www.dropbox.com/s/tkksfzk3nim8mlb/dinosaur.mp3?dl=1", "3d noblock", function(Sound)
    --bass.loadURL( "https://www.dropbox.com/s/tkksfzk3nim8mlb/dinosaur.mp3?dl=1", "3d noblock", function(Sound)
    --bass.loadURL( "https://www.dropbox.com/s/ga3816zqx8uq26u/big%20iron.mp3?dl=1", "3d noblock", function(Sound)
    --bass.loadURL( "https://www.soundboard.com/handler/DownLoadTrack.ashx?cliptitle=Never+Gonna+Give+You+Up-+Original&filename=mz/Mzg1ODMxNTIzMzg1ODM3_JzthsfvUY24.MP3", "3d noblock", function(Sound)
local play = function()
    --bass.loadURL( "https://www.dropbox.com/s/vq9ihz9t62bzilo/Bohemian%20Rhapsody.mp3?dl=1", "3d noblock", function(Sound)
    bass.loadURL( "https://dl.dropboxusercontent.com/s/vq9ihz9t62bzilo/Bohemian%20Rhapsody.mp3", "3d noblock", function(Sound)
    --bass.loadURL( "https://www.dropbox.com/s/xbnr3hwe133bkjs/WALKIN%27%20-%20JerryTerry.mp3?dl=1", "3d noblock", function(Sound)
    --bass.loadURL( "https://www.dropbox.com/s/d0mi89fqfk3gcby/Stick%20Bug%20song%20%28Bee%20Swarm%20Simulator%29.mp3?dl=1", "3d noblock", function(Sound)
        if Sound then
            Sound:play()
        end
        hook.add("think","",function()
            if Sound then
                Sound:setPos(chip:getPos())
                local time = timer.curtime()
                if time > nextFrameTime then
                    nextFrameTime = nextFrameTime + 1/fps
                    fft = Sound:getFFT(samples)
                    local last = 1
                    for i = 1, count do
                        local next = math.round(i * interval)
                        local fftVal = 0
                        for i2 = last, next, 1 do
                            fftVal = math.max(fftVal,(fft[i2] or 0))
                        end
                        last = next+1
                        local ang =  math.max(-fftVal * 90 * volumeMult, -180)
                        hinges[i]:setAngles(bottoms[i]:localToWorldAngles(Angle(ang,0,0)))
                        --top:setPos(bottom:localToWorld(Vector(halfSize + halfSize * math.cos(angr) + math.cos(angr + math.pi/2) * halfSize, 0, size*3/4 + halfSize * math.sin(angr) + math.sin(angr + math.pi/2) * size/4)))
                    end
                else
                    --hook.remove("think","")
                end
            end
        end)
    end)
end
if hasPermission("bass.loadURL") then
    --print("yes")
    play()
else
    --print("no")
    setupPermissionRequest({"bass.loadURL"},"Allows cubes to sing",true)
    hook.add("permissionrequest","",function()
        if permissionRequestSatisfied() then
            hook.remove("permissionrequest","")
            play()
        end
    end)
end

--[[local m = material.create("VertexLitGeneric")
m:setTextureRenderTarget("$basetexture", "top")

local function doRender()
    render.selectRenderTarget("top")
    render.clear(Color(255,255,255))
    render.setRenderTargetTexture("circle")
    render.setColor(Color(0,0,0))
    render.drawTexturedRect(705,595,110,110)
    render.drawTexturedRect(855,595,110,110)
    render.selectRenderTarget()
    for i = 1, count do
        tops[i]:setMaterial("!"..m:getName())
    end
    hook.remove("renderoffscreen","go")
end

local function initRender()
    render.selectRenderTarget("circle")
    local poly = {}
    for i=1, 360 do
        local theta = i*math.pi/180
        poly[i] = {x=math.cos(theta)*512+512, y=math.sin(theta)*512+512}
    end
    render.clear(Color(0,0,0,0))
    render.setColor(Color(0,0,0))
    render.drawPoly(poly)
    render.selectRenderTarget()
    hook.remove("renderoffscreen","init")
    hook.add("renderoffscreen","go",doRender)
end

hook.add("renderoffscreen","init",initRender)
--[[for i=0,count-1,1 do
        render.setColor(Color(i*4*50/count,1,1):hsvToRGB())
        --render.draw3DBox(Vector(0+i*10*50/count,512,250),Angle(),Vector(),Vector(10*50/count,-50-(fft[i+1] or 0)*350,10))
        render.draw3DBox(Vector(0+i*10*50/count,512,250),Angle(),Vector(),Vector(10*50/count,-50-(fft[math.round(i*interval)] or 0)*350,10))
    end]]
--[[local init = false
hook.add("net","",function(name,len,ply)
    net.start("")
    net.writeEntity(weldedTo)
    net.send(ply)
end)

hook.add("renderoffscreen","",function()
    if not init then
        init = true
        render.selectRenderTarget("circle")
        render.clear(0,0,0,0)
        local count = 360
        local interval = math.pi * 2 / count
        local poly = {}
        for i = 1, count do
            table.insert(poly,{x = 512 + 512 * math.cos(i * interval),y = 512 + 512 * math.sin(i * interval)})
        end
        render.setColor(Color(0,0,0))
        render.drawPoly(poly)
        
        render.selectRenderTarget("top")
        render.setRenderTargetTexture("circle")
        --render.drawTexturedRect(
        render.drawTexturedRect(710,600,100,100)
        render.drawTexturedRect(860,600,100,100)
    end
end)

hook.add("render","",function()
    render.setRenderTargetTexture("screen")
    render.drawTexturedRectFast(0,0,512,512)
end)]]