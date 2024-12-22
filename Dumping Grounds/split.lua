-- Connect to a screen

--@name Split
--@author Jacbo
--@client

render.createRenderTarget("")
render.createRenderTarget("buffer")
render.createRenderTarget("white")

local lineThickness = 10
local moveDist = 25
local moved = moveDist
local moveSpeed = 100

local function segmentBoxIntersection(x1, y1, x2, y2, l, t, r, b)
    -- normalize segment
    local dx, dy = x2 - x1, y2 - y1
    local d = math.sqrt(dx*dx + dy*dy)
    if d == 0 then
        return
    end
    local nx, ny = dx/d, dy/d
    -- minimum and maximum intersection values
    local tmin, tmax = 0, d
    -- x-axis check
    if nx == 0 then
        if x1 < l or x1 > r then
            return
        end
    else
        local t1, t2 = (l - x1)/nx, (r - x1)/nx
        if t1 > t2 then
            t1, t2 = t2, t1
        end
        tmin = math.max(tmin, t1)
        tmax = math.min(tmax, t2)
        if tmin > tmax then
            return
        end
    end
    -- y-axis check
    if ny == 0 then
        if y1 < t or y1 > b then
            return
        end
    else
        local t1, t2 = (t - y1)/ny, (b - y1)/ny
        if t1 > t2 then
            t1, t2 = t2, t1
        end
        tmin = math.max(tmin, t1)
        tmax = math.min(tmax, t2)
        if tmin > tmax then
            return
        end
    end
    -- points of intersection
    -- one point
    local qx, qy = x1 + nx*tmin, y1 + ny*tmin
    if tmin == tmax then
        return qx, qy
    end
    -- two points
    return qx, qy, x1 + nx*tmax, y1 + ny*tmax
end

local function getUVs(x, y, dx, dy)
    local size = 511
    dx = dx * 4096
    dy = dy * 4096
    --[[if dx < 0 then
        dx = -dx
        dy = -dy
    end]]
    local x1, y1, x2, y2 = segmentBoxIntersection(x - dx, y - dy, x + dx, y + dy, 0, 0, size, size)
    local u1 = x1 / size
    local v1 = y1 / size
    local u2 = x2 / size
    local v2 = y2 / size
    
    local poly1 = {
        {
            x = x1,
            y = y1,
            u = u1,
            v = v1
        },
        {
            x = x2,
            y = y2,
            u = u2,
            v = v2
        }
    }
    
    local poly2 = {
        {
            x = x2,
            y = y2,
            u = u2,
            v = v2
        },
        {
            x = x1,
            y = y1,
            u = u1,
            v = v1
        }
    }
    
    local corners = {
        {
            -- Top left
            x = 0,
            y = 0,
            u = 0,
            v = 0
        },
        {
            -- Top right
            x = size,
            y = 0,
            u = 1,
            v = 0
        },
        {
            -- Bottom right
            x = size,
            y = size,
            u = 1,
            v = 1
        },
        {
            -- Bottom left
            x = 0,
            y = size,
            u = 0,
            v = 1
        }
    }
    
    local start, stop
    
    -- Get start
    if y2 < 1 then
        -- Top
        start = 2
    elseif x2 > size - 1 then
        -- Right
        start = 3
    elseif y2 > size - 1 then
        -- Bottom
        start = 4
    else
        -- Left
        start = 1
    end
    
    -- Get end
    if y1 < 1 then
        -- Top
        stop = 2
    elseif x1 > size - 1 then
        -- Right
        stop = 3
    elseif y1 > size - 1 then
        -- Bottom
        stop = 4
    else
        -- Left
        stop = 1
    end
    
    local i = start
    while i ~= stop do
        table.insert(poly1, corners[i])
        i = i % 4 + 1
    end
    
    --i = (start + 2) % 4 + 1
    while i ~= start do
        table.insert(poly2, corners[i])
        i = i % 4 + 1
    end
    
    return poly1, poly2, {u1, v1, u2, v2}
end

local margin = 100
local function split()
    local x = math.rand(margin, 511 - margin)
    local y = math.rand(margin, 511 - margin)
    local dx = math.rand(-1, 1)
    local dy = math.rand(-1, 1)
    local length = math.sqrt(dx * dx + dy * dy)
    dx = dx / length
    dy = dy / length
    
    local poly1, poly2, uvs = getUVs(x, y, dx, dy)
    
    -- Create line
    return {
        x = x,
        y = y,
        dx = dx,
        dy = dy,
        poly1 = poly1,
        poly2 = poly2,
        move = {
            -dy,
            dx
        }
    }
end

local function drawLine(x, y, dx, dy)
    x = x * 2
    y = y * 2
    local line_dx = dx * 4096 - dy * lineThickness / 2
    local line_dy = dy * 4096 + dx * lineThickness / 2
    
    render.drawPoly({
        {
            x = x - line_dx,
            y = y - line_dy
        },
        {
            x = x + line_dx,
            y = y - line_dy
        },
        {
            x = x + line_dx,
            y = y + line_dy
        },
        {
            x = x - line_dx,
            y = y + line_dy
        }
    })
end

local currentSplit = split()
local first = true
hook.add("renderoffscreen", "", function()
    if first then
        render.selectRenderTarget("white")
        render.drawRect(0, 0, 1024, 1024)
        first = false
        
        render.selectRenderTarget("")
        local mat = material.create("UnlitGeneric")
        mat:setTexture("$basetexture", material.getTexture("models/eli/eli_tex4z", "$basetexture"))
        render.setMaterial(mat)
        render.drawTexturedRect(0, 0, 1024, 1024)
        
        render.setRenderTargetTexture("white")
        local rot = math.deg(math.atan2(currentSplit.dy, currentSplit.dx))
        render.drawTexturedRectRotated(currentSplit.x * 2, currentSplit.y * 2, 4096, lineThickness, rot)
    end
    
    if moved >= moveDist then
        render.selectRenderTarget("buffer")
        render.clear(Color(0,0,0,255))
        render.setRenderTargetTexture("")
        
        local move = currentSplit.move
        local dx = move[1] * moved
        local dy = move[2] * moved
        
        local poly = {}
        for _, t in ipairs(currentSplit.poly1) do
            table.insert(poly, {
                x = t.x * 2 + dx,
                y = t.y * 2 + dy,
                u = t.u,
                v = t.v
            })
        end
        render.drawPoly(poly)
        
        poly = {}
        for _, t in ipairs(currentSplit.poly2) do
            table.insert(poly, {
                x = t.x * 2 - dx,
                y = t.y * 2 - dy,
                u = t.u,
                v = t.v
            })
        end
        render.drawPoly(poly)
        
        render.selectRenderTarget("")
        render.setRenderTargetTexture("buffer")
        render.drawTexturedRect(0, 0, 1024, 1024)
        
        currentSplit = split()
        
        render.setRenderTargetTexture("white")
        local rot = math.deg(math.atan2(currentSplit.dy, currentSplit.dx))
        render.drawTexturedRectRotated(currentSplit.x * 2, currentSplit.y * 2, 4096, lineThickness, rot)
        
        moved = 0
    end
end)

local scale = 1.25

hook.add("render", "", function()
    render.setRenderTargetTexture("")
    --render.drawTexturedRect(0, 0, 512, 512)
    local dx = currentSplit.move[1] * moved
    local dy = currentSplit.move[2] * moved
    --local dx = 0
    --local dy = 0
    
    local poly = {}
    for _, t in ipairs(currentSplit.poly1) do
        table.insert(poly, {
            x = (t.x - 256) * scale + 256 + dx,
            y = (t.y - 256) * scale + 256 + dy,
            u = t.u,
            v = t.v
        })
    end
    render.drawPoly(poly)
    
    poly = {}
    for _, t in ipairs(currentSplit.poly2) do
        table.insert(poly, {
            x = (t.x - 256) * scale + 256 - dx,
            y = (t.y - 256) * scale + 256 - dy,
            u = t.u,
            v = t.v
        })
    end
    render.drawPoly(poly)
    moved = moved + moveSpeed * timer.frametime()
end)