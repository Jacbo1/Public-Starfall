--@name Sprite sheet Manager
--@author Jacbo
-- https://github.com/Jacbo1/Public-Starfall/tree/main/Sprite%20Sheet%20Manager

if CLIENT then
    local mngr = {}
    mngr.__index = mngr
    
    -- Creates a sprite sheet manager and loads the image
    function mngr.loadURL(url, columns, rows, callback)
        local mat = material.create("UnlitGeneric")
        local t = {
            loading = true,
            rows = rows,
            columns = columns,
            mats = {mat},
            loadings = {true},
            cb = callback
        }
        setmetatable(t, mngr)

        mat:setTextureURL("$basetexture", url, function(_, _, width, height, layout)
            -- Scale down to fit on a 1024x1024 RenderTarget
            if width > 1024 or height > 1024 then
                if width > height then
                    height = height * 1024 / width
                    width = 1024
                else
                    width = width * 1024 / height
                    height = 1024
                end
                layout(0, 0, width, height)
            end
            t.width = width
            t.height = height
            t.swidth = width / columns
            t.sheight = height / rows
        end, function()
            t.loadings[1] = false
            for _, loading in ipairs(t.loadings) do
                if loading then return end
            end
            t.loading = false
            if t.cb then t.cb(t) end
        end)
        
        return t
    end
    
    -- Gets the width of a sprite
    function mngr:getSpriteWidth()
        return self.swidth
    end
    
    -- Gets the height of a sprite
    function mngr:getSpriteHeight()
        return self.sheight
    end
    
    -- Sets a callback to run when it finishes loading all sprite sheet images
    -- Instantly calls it if it is already loaded
    function mngr:setCallback(callback)
        self.cb = callback
        if not self.loading then
            callback(self)
        end
    end
    
    -- Appends another piece of the sprite sheet
    function mngr:appendURL(url)
        local mat = material.create("UnlitGeneric")
        
        table.insert(self.mats, mat)
        table.insert(self.loadings, true)
        self.loading = true
        local index = #self.loadings
        
        mat:setTextureURL("$basetexture", url,
            function(_, _, width, height, layout)
                -- Scale down to fit on a 1024x1024 RenderTarget
                if width > 1024 or height > 1024 then
                    if width > height then
                        height = height * 1024 / width
                        width = 1024
                    else
                        width = width * 1024 / height
                        height = 1024
                    end
                    layout(0, 0, width, height)
                end
            end,
            function()
                self.loadings[index] = false
                for _, loading in ipairs(self.loadings) do
                    if loading then return end
                end
                self.loading = false
                if self.cb then self.cb(self) end
            end
        )
    end
    
    -- Draws a sprite in a rectangle
    function mngr:drawSprite(x, y, width, height, index)
        if self.loading then return end
        index = math.round(index)
        local cols, rows, swidth, sheight = self.columns, self.rows, self.swidth, self.sheight
        local sprites = cols * rows
        render.setMaterial(self.mats[math.ceil(index / sprites)])
        index = (index - 1) % sprites + 1
        local u = ((index - 1) % cols) * swidth
        local v = math.floor((index - 1) / cols) * sheight
        render.drawTexturedRectUV(x, y, width, height, u/1024, v/1024, (u + swidth)/1024, (v + sheight)/1024)
    end
    
    -- Checks if it is loading sprite sheet pieces
    function mngr:isLoading()
        return self.loading
    end
    
    return mngr
end
