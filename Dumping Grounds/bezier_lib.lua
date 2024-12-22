--@name Bezier Lib
--@author Jacbo

local Bezier = {}
local Curve = {}
Curve.__index = Curve

Curve.newCurve = function(points, closed, autoControlStrength, angles)
    local t = {points = {}, closed = closed, autoControlStrength = autoControlStrength}
    if angles == nil then
        t.hasAngles = false
    else
        t.hasAngles = true
        t.angles = {}
        for _, ang in pairs(angles) do
            table.insert(t.angles, ang:getQuaternion())
        end
    end
    for _, point in pairs(points) do
        table.insert(t.points, Vector(point[1], point[2], point[3]))
    end
    setmetatable(t, Curve)
    return t
end

function Curve:getSegments()
    return #self.points / 3
end

local function setPoints(i, points, autoControlStrength, closed)
    local anchorPos = points[(i - 1) % #points + 1]
    local dir = Vector()
    local dist1 = 0
    local dist2 = 0
    if i - 3 >= 1 then
        local offset = points[i - 3] - anchorPos
        dist1 = offset:getLength()
        dir = dir + offset
    elseif closed then
        local offset = points[(i - 4) % #points + 1] - anchorPos
        dist1 = offset:getLength()
        dir = dir + offset
    end
    
    if i + 3 <= #points then
        local offset = points[i + 3] - anchorPos
        dist2 = offset:getLength()
        dir = dir - offset
    elseif closed then
        local offset = points[(i + 2) % #points + 1] - anchorPos
        dist2 = offset:getLength()
        dir = dir - offset
    end
    
    dir:normalize()
    
    if i - 1 >= 1 then
        points[i - 1] = anchorPos + dir * dist1 * autoControlStrength
    elseif closed then
        points[(i - 2) % #points + 1] = anchorPos + dir * dist1 * autoControlStrength
    end
    
    if i + 1 <= #points then
        points[i + 1] = anchorPos - dir * dist2 * autoControlStrength
    elseif closed then
        points[i % #points + 1] = anchorPos - dir * dist2 * autoControlStrength
    end
    
    if not closed then
        --Set ends
        points[2] = (points[1] + points[3]) / 2
        points[#points - 1] = (points[#points] + points[#points - 2]) / 2
    end
end

--[[
    Returns a Curve object (anchor, control, control)
    Get points with Curve.points
    Automatically sets control points. Strength determined by autoControlStrength
    (Optional) Set closed to true to make the ends connect. Defaults to false
    (Optional) angles - angle at each anchor
]]
Bezier.makeCubicCurve = function(anchors, autoControlStrength, closed, angles)
    if closed == nil then
        closed = false
    end
    local points = {}
    for _, anchor in pairs(anchors) do
        for i = 1, 3 do
            table.insert(points, anchor)
        end
    end
    
    if #points == 6 then
        --2 anchors
        local dir = points[4] - points[1]
        dir = dir * 2 / dir:getLength()
        points[2] = points[1] + dir
        points[6] = points[1] - dir
        points[3] = points[4] + dir
        points[5] = points[4] - dir
        return Curve.newCurve(points, closed, autoControlStrength, angles)
    elseif #points < 6 then
        --Less than 2 anchors so there is no curve (you shouldn't have even called this function)
        return Curve.newCurve(points, closed, autoControlStrength, angles)
    else
        --More than 2 anchors
        for i = (closed and 1 or 4), #points - (closed and 0 or 3), 3 do
            setPoints(i, points, autoControlStrength, closed)
        end
        return Curve.newCurve(points, closed, autoControlStrength, angles)
    end
end

--[[
    Calculates the length of the curve curveIndex in the path
    Higher values of precision improve the accuracy and increase cpu usage
    O(N)
    Splits curve into N segments where N = precision and sums the distance between the ends of these segments
]]
function Curve:getLength(curveIndex, precision)
    curveIndex = curveIndex - 1
    local points = self.points
    local A = points[(curveIndex * 3) % #points + 1]
    local B = points[(curveIndex * 3 + 1) % #points + 1]
    local C = points[(curveIndex * 3 + 2) % #points + 1]
    local D = points[(curveIndex * 3 + 3) % #points + 1]
    local lastPoint = A
    local length = 0
    for lerp = 1 / precision, 1, 1 / precision do
        local ilerp = 1 - lerp
        local newPoint = A*ilerp^3 + 3*B*lerp*ilerp^2 + 3*C*lerp^2*ilerp + D*lerp^3
        length = length + lastPoint:getDistance(newPoint)
        lastPoint = newPoint
    end
    return length
end

local function updateAnchor(anchorIndexTriple, points, autoControlStrength, closed)
    if #points == 6 then
        --2 anchors
        local dir = points[4] - points[1]
        dir = dir * 2 / dir:getLength()
        points[2] = points[1] + dir
        points[6] = points[1] - dir
        points[3] = points[4] + dir
        points[5] = points[4] - dir
    elseif #points > 6 then
        --More than 2 anchors
        for i = (closed and anchorIndexTriple - 5 or math.max(anchorIndexTriple - 5, 4)), (closed and anchorIndexTriple + 1 or math.min(anchorIndexTriple + 1, #points - 3)), 3 do
            setPoints(i, points, autoControlStrength, closed)
        end
    end
end

--[[
    Updates the affected points around anchorIndex
    Use this if you manually set an anchor
]]
function Curve:updateAnchor(anchorIndex)
    local anchorIndexTriple = anchorIndex * 3
    if anchorIndexTriple > #self.points then
        error("Anchor index out of bounds " .. anchorIndex .. " / " .. #self.points / 3)
    end
    updateAnchor(anchorIndexTriple, self.points, self.autoControlStrength, self.closed)
end

--[[
    Updates the control points affected by changing the specified anchor
    anchorIndex is the anchor number
    Indices higher than the current segment count will be appended
    (Kind of optional) newAngle - the new angle of the anchor. Not required if the curve wasn't created with angles
]]
function Curve:setAnchor(anchorIndex, newValue, newAngle)
    local points = self.points
    local closed = self.closed
    local autoControlStrength = self.autoControlStrength
    local anchorIndexTriple = anchorIndex * 3
    local quat
    local angles
    if self.hasAngles and newAngle ~= nil then
        quat = newAngle:getQuaternion()
        angles = self.angles
    end
    if anchorIndexTriple > #points then
        for i = #points+1, anchorIndexTriple do
            table.insert(points, newValue)
        end
        if self.hasAngles and quat ~= nil then
            for i = #angles+1, anchorIndex do
                table.insert(angles, quat)
            end
        end
    else
        points[anchorIndexTriple - 2] = newValue
        if self.hasAngles and quat ~= nil then
            angles[anchorIndex] = quat
        end
    end
    
    updateAnchor(anchorIndexTriple, points, self.autoControlStrength, self.closed)
end

--[[
    Gets a point on the curve curveIndex
    Lerp is 0-1
]]
function Curve:getPoint(curveIndex, lerp)
    curveIndex = curveIndex - 1
    local points = self.points
    local A = points[(curveIndex * 3) % #points + 1]
    local B = points[(curveIndex * 3 + 1) % #points + 1]
    local C = points[(curveIndex * 3 + 2) % #points + 1]
    local D = points[(curveIndex * 3 + 3) % #points + 1]
    local ilerp = 1 - lerp
    local pos = A*ilerp^3 + 3*B*lerp*ilerp^2 + 3*C*lerp^2*ilerp + D*lerp^3
    if self.hasAngles then
        return pos, math.slerpQuaternion(self.angles[curveIndex % (#points / 3) + 1], self.angles[(curveIndex + 1) % (#points / 3) + 1], lerp):getEulerAngle()
    end
    return pos
end

--[[
    Gets the first derivative aka the tangent vector at a point on the curve in the path
    Lerp is 0-1
]]
function Curve:getD1Point(curveIndex, lerp)
    curveIndex = curveIndex - 1
    local points = self.points
    local A = points[(curveIndex * 3) % #points + 1]
    local B = points[(curveIndex * 3 + 1) % #points + 1]
    local C = points[(curveIndex * 3 + 2) % #points + 1]
    local D = points[(curveIndex * 3 + 3) % #points + 1]
    local ilerp = 1 - lerp
    return 3*(B-A)*ilerp^3 + 6*(C-B)*lerp*ilerp + 3*(D-C)*lerp^2
end

--[[
    Gets the second derivative at a point on the curve in the path
    Lerp is 0-1
]]
function Curve:getD2Point(curveIndex, lerp)
    curveIndex = curveIndex - 1
    local points = self.points
    local A = points[(curveIndex * 3) % #points + 1]
    local B = points[(curveIndex * 3 + 1) % #points + 1]
    local C = points[(curveIndex * 3 + 2) % #points + 1]
    local D = points[(curveIndex * 3 + 3) % #points + 1]
    return 6*(C-2*B+A)*(1-lerp) + 6*(D-2*C+B)*lerp
end

return Bezier