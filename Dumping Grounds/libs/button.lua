--@name Button Library
--@author Jacbo

if CLIENT then
    local button = {}
    button.__index = button
    
    function render.createButton(x, y, w, h, text, bgCol, outlineCol, textCol, bgHoverCol, outlineHoverCol, textHoverCol, rounded, radius, hoverCB, unhoverCB, pressCB, releaseCB)
        local t = {
            x = x,
            y = y,
            w = w,
            h = h,
            text = text,
            bgCol = bgCol,
            bgHoverCol = bgHoverCol,
            outlineCol = outlineCol or bgCol,
            outlineHoverCol = outlineHoverCol or bgHoverCol,
            textCol = textCol,
            textHoverCol = textHoverCol or textCol,
            rounded = rounded or false,
            radius = radius or 5,
            hoverCB = hoverCB,
            unhoverCB = unhoverCB,
            pressCB = pressCB,
            releaseCB = releaseCB,
            pressed = false,
            hovering = false
        }
        setmetatable(t, button)
        return t
    end
    
    function render.drawButtons(buttons, cursorx, cursory, usePress, useRelease)
        for _, btn in ipairs(buttons) do
            -- Check for hovering
            local hovering = false
            if cursorx and cursory then
                hovering = cursorx >= btn.x and
                    cursorx < btn.x + btn.w and
                    cursory >= btn.y and
                    cursory < btn.y + btn.h
            end
            
            -- Handle button press
            if usePress and hovering and not btn.pressed then
                btn.pressed = true
                if btn.pressCB then
                    -- Call press callback
                    btn.pressCB()
                end
            end
            
            -- Handle buttn release
            if useRelease and btn.pressed then
                btn.pressed = false
                if btn.releaseCB then
                    -- Call release callback
                    btn.releaseCB()
                end
            end
            
            local bgCol = hovering and btn.bgHoverCol or btn.bgCol
            local outlineCol = hovering and btn.outlineHoverCol or btn.outlineCol
            local textCol = hovering and btn.textHoverCol or btn.textCol
            
            -- Handle hover callbacks
            if hovering ~= btn.hovering then
                btn.hovering = hovering
                if hovering then
                    if btn.hoverCB then
                        -- Call hover callback
                        btn.hoverCB()
                    end
                elseif btn.unhoverCB then
                    -- Call unhover callback
                    btn.unhoverCB()
                end
            end
            
            -- Draw button
            if btn.rounded then
                -- Rounded button
                if outlineCol == bgCol then
                    -- Don't waste resources making an outline
                    render.setColor(bgCol)
                    render.drawRoundedBox(btn.radius, btn.x, btn.y, btn.w, btn.h)
                else
                    -- Draw outline
                    render.setColor(outlineCol)
                    render.drawRoundedBox(btn.radius, btn.x, btn.y, btn.w, btn.h)
                    render.setColor(bgCol)
                    render.drawRoundedBox(btn.radius, btn.x + 1, btn.y + 1, btn.w - 2, btn.h - 2)
                end
            else
                -- Square button
                render.setColor(bgCol)
                render.drawRect(btn.x, btn.y, btn.w, btn.h)
                if outlineCol ~= bgCol then
                    -- Draw outline
                    render.setColor(outlineCol)
                    render.drawRectOutline(btn.x, btn.y, btn.w, btn.h)
                end
            end
        end
    end
end