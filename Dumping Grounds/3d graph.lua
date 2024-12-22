--@name 3D Graph
--@author Jacbo
--@shared

if SERVER then
    local holo = holograms.create(chip():getPos(), Angle(), "models/props_junk/PopCan01a.mdl", Vector(1, 1, 1))
    holo:setParent(chip())
    net.receive("", function(_, ply)
        net.start("")
        net.writeUInt(holo:entIndex(), 13)
        --net.writeEntity(holo)
        net.send(ply)
    end)
elseif CLIENT then--Client
    --0 = cut in half
    --1 = cut in half randomly
    --2 = cut in 4 pieces
    local breakMode = 0
    
    --local mat = "models/eli/eli_tex4z"
    local mat = "models/kleiner/walter_face"
    
    local Min = -1
    local Max = 1
    
    local d = (Max - Min) / 40
    local scale = 200 / (Max - Min)
    local textureScale = 1
    
    --local scale = 25
    local window = {
        min = {
            x = Min,
            y = Min
        },
        max = {
            x = Max,
            y = Max
        },
        dx = d,
        dy = d
    }
    local maxCPU = math.min(0.004, quotaMax() * 0.8)
    
    local sign = function(a)
        if a == 0 then
            return a
        elseif a < 0 then
            return -1
        else
            return 1
        end
    end
    
    local abs = function(a)
        return math.abs(a)
    end
    
    local getZ = function(x, y)
        --return math.sqrt(x + y)
        --return math.sqrt(((x-3)^2+(y-1)^2)-4 )-2
        --return ((1-sign(-x-.9+abs(y*2)))/3*(sign(.9-x)+1)/3)*(sign(x+.65)+1)/2 - ((1-sign(-x-.39+abs(y*2)))/3*(sign(.9-x)+1)/3) + ((1-sign(-x-.39+abs(y*2)))/3*(sign(.6-x)+1)/3)*(sign(x-.35)+1)/2
        --return (x^2+y^2)^0.5
        --return math.sin(10*(x^2+y^2))/10
        --return (0.4^2-(0.6-(x^2+y^2)^0.5)^2)^0.5
        return math.cos(5*x) * math.cos(5*y) / 3
    end
    
    --------------------------------------------------
    
    local getUV = function(v)
        local u = (v.x - window.min.x) / (window.max.x - window.min.x) / textureScale
        local v = (v.y - window.min.y) / (window.max.y - window.min.y) / textureScale
        if u < 0 then
            if math.floor(u) == u then
                u = 1 - u
            else
                u = u - (math.ceil(u) - 1)
            end
        end
        if v < 0 then
            if math.floor(v) == v then
                v = 1 - v
            else
                v = v - (math.ceil(v) - 1)
            end
        end
        if u > 1 then
            u = u - (u - 1)
        end
        if v > 1 then
            v = v - (v - 1)
        end
        return 
            u,
            v
    end
        
    local breakQuad = function(c1, c2, c3, c4)
        --c1  c2
        --
        --c3  c4
        local c1u, c1v = getUV(c1 / scale)
        local c2u, c2v = getUV(c2 / scale)
        local c3u, c3v = getUV(c3 / scale)
        local c4u, c4v = getUV(c4 / scale)
        if breakMode == 0 then
            --cut in half
            return {
                {pos = c1, u = c1u, v = c1v},
                {pos = c2, u = c2u, v = c2v},
                {pos = c3, u = c3u, v = c3v},
                
                {pos = c1, u = c1u, v = c1v},
                {pos = c3, u = c3u, v = c3v},
                {pos = c4, u = c4u, v = c4v}
            }
        elseif breakMode == 1 then
            --cut in half randomly
            if math.rand(0,1) > 0.5 then
                return {
                    {pos = c1},
                    {pos = c2},
                    {pos = c3},
                    {pos = c3},
                    {pos = c2},
                    {pos = c1},
                    
                    {pos = c2},
                    {pos = c3},
                    {pos = c4},
                    {pos = c4},
                    {pos = c3},
                    {pos = c2}
                }
            else
                return {
                    {pos = c1},
                    {pos = c2},
                    {pos = c4},
                    {pos = c4},
                    {pos = c2},
                    {pos = c1},
                    
                    {pos = c1},
                    {pos = c3},
                    {pos = c4},
                    {pos = c4},
                    {pos = c3},
                    {pos = c1}
                }
            end
        else
            --cut in 4 pieces
            local center = (c1 + c2 + c3 + c4) / 4
            return {
                {pos = c1},
                {pos = c2},
                {pos = center},
                {pos = center},
                {pos = c2},
                {pos = c1},
                
                {pos = c2},
                {pos = c4},
                {pos = center},
                {pos = center},
                {pos = c4},
                {pos = c2},
            
                {pos = c4},
                {pos = c3},
                {pos = center},
                {pos = center},
                {pos = c3},
                {pos = c4},
                
                {pos = c3},
                {pos = c1},
                {pos = center},
                {pos = center},
                {pos = c1},
                {pos = c3},
            }
        end
    end
    
    local tris = {}
    
    local graph = coroutine.wrap(function()
        for x = window.min.x, window.max.x - window.dx, window.dx do
            for y = window.min.y, window.max.y - window.dy, window.dy do
                while quotaAverage() >= maxCPU do
                    coroutine.yield()
                end
                for v, k in pairs(breakQuad(
                        Vector(x, y, getZ(x, y)) * scale,
                        Vector(x + window.dx, y, getZ(x + window.dx, y)) * scale,
                        Vector(x + window.dx, y + window.dy, getZ(x + window.dx, y + window.dy)) * scale,
                        Vector(x, y + window.dy, getZ(x, y + window.dy)) * scale
                    )) do
                    table.insert(tris, k)
                end
            end
        end
        return true
    end)
    
    local graphing = true
    
    hook.add("think", "", function()
        if graphing then
            if graph() then
                graphing = false
            end
        else
            hook.remove("think", "")
            --Make model
            --mesh.generateUV(tris, 1/scale)
            mesh.generateNormals(tris)
            local Mesh
            local texture = material.create("VertexLitGeneric")
            render.createRenderTarget("mesh")
            --texture:setTexture("$basetexture", "hunter/myplastic")
            texture:setTexture("$basetexture", mat)
            --texture:setTexture("$basetexture", "models/props_canal/rock_riverbed01a")
            local loadmesh = coroutine.wrap(function() Mesh = mesh.createFromTable(tris, true) return true end)
                hook.add("think","loadingMesh",function()
                while quotaAverage() < maxCPU do
                    if loadmesh() == true then
                        net.start("")
                        net.send()
                        net.receive("", function()
                            local holo = entity(net.readUInt(13)):toHologram()
                            timer.simple(1, function()
                                holo:setMesh(Mesh)
                                holo:setMeshMaterial(texture)
                                holo:setRenderBounds(Vector(-2000),Vector(2000))
                            end)
                        end)
                        hook.remove("think","loadingMesh")
                        return
                    end
                end
            end)
        end
    end)
end    