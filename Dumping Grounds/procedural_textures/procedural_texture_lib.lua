--@name Procedural Texture Lib
--@author Jacbo

procText = {}

local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min
local abs = math.abs
local sharedRandom = math.sharedRandom
local format = string.format
local sin = math.sin
local cos = math.cos
local pi = math.pi
rad2deg = 180 / pi
deg2rad = pi / 180

local brickShiftSeed = 1234
local brickColorSeed = 5678
local whiteNoise1DSeed = 12345678
local whiteNoise2DSeed = 87654321

--Randomize seed
procText.randomizeSeeds = function()
    brickShiftSeed = math.rand(1, 10000)
    brickColorSeed = math.rand(1, 10000)
    whiteNoise1DSeed = math.rand(1, 10000)
    whiteNoise2DSeed = math.rand(1, 10000)
end

local function addBricks()
    --Brick
    --returns 0-1
    --number x, number y, number brickWidth, number shift 0-1, boolean randomRowShift, number borderThickness, number borderValue, number brickMinValue 0-1, number brickMaxValue 0-1

    --Cache values
    local oldRow = nil
    local oldShift = nil

    local oldRow2 = nil
    local oldColumn = nil
    local oldBrickValue = nil

    procText.brick = function(x, y, brickWidth, brickHeight, shift, randomRowShift, borderThickness, borderValue, brickMinValue, brickMaxValue)
        shift = shift or 0.5                        --0-1 shifts every other row by this percent of the width
        randomRowShift = randomRowShift or false    --Randomly shift the rows
        brickWidth = brickWidth or 20               --Includes brick and border
        brickHeight = brickHeight or 5              --Includes brick and border
        borderThickness = borderThickness * 0.5 or 1      --borderThickness <= brickWidth and borderThickness <= brickHeight
        borderValue = borderValue or 0
        brickMinValue = brickMinValue or 1          --0-1
        brickMaxValue = brickMaxValue or 1          --0-1
        
        local rowf = y / brickHeight
        local row = floor(rowf)
        local rowfrac = rowf - row
        
        --Shift
        if randomRowShift then
            if row == oldRow then
                x = x + oldShift
            else
                oldRow = row
                oldShift = brickWidth * sharedRandom(tostring(row), 0, 1, brickShiftSeed)
                x = x + oldShift
            end
        elseif row%2 == 0 then
            x = x + brickWidth * shift
        end
        
        local columnf = x / brickWidth
        local column = floor(columnf)
        local columnfrac = columnf - column
        
        --Find borders
        local xborder = borderThickness / brickWidth
        local yborder = borderThickness / brickHeight
        if columnfrac <= xborder or columnfrac >= 1 - xborder or
        rowfrac <= yborder or rowfrac >= 1 - yborder then
            --On border
            return borderValue
        end
        
        --Get brick value
        if brickMinValue == brickMaxValue then
            return brickMinValue
        end
        
        --Get random brick value
        if row == oldRow2 and column == oldColumn then
            return oldBrickValue
        else
            oldRow2 = row
            oldColumn = column
            oldBrickValue = sharedRandom(column .. "x" .. row, brickMinValue, brickMaxValue, brickColorSeed)
            return oldBrickValue
        end
    end
end
addBricks()

--White noise 1D
--returns 0-1
--number x
procText.whiteNoise1D = function(x)
    return sharedRandom(tostring(x), 0, 1, whiteNoise1DSeed)
end

--White noise 2D
--returns 0-1
--number x, number y
procText.whiteNoise2D = function(x, y)
    return sharedRandom(x .. "x" .. y, 0, 1, whiteNoise2DSeed)
end

--Sin wave
--number x, number scale
procText.sinWave = function(x, scale)
    return 1 - ((sin(x) + 1) * 0.5)^scale
end