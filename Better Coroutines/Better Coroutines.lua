--@name Better Coroutines
--@author Jacbo

-- When you require this, it returns BetterCoroutine
-- e.g. local corLib = require("better_coroutines.txt")
-- You use this exactly the same as coroutine.wrap() except it will
-- automatically restart when called after it has finished.
-- corLib.wrap(func) returns a coroutineObject
-- You can call coroutineObject:restart() to restart the coroutine without letting it finish
-- Arguments can be passed in when calling the coroutineObject

local BetterCoroutine = {}
local coroutineObject = {}
coroutineObject.__index = coroutineObject

--Creates new coroutine
BetterCoroutine.wrap = function(func)
    local cor = coroutine.create(func)
    local t = {cor, func}
    setmetatable(t, coroutineObject)
    return t
end

--Run the wrapped function
function coroutineObject:__call(...)
    local status = coroutine.status(self[1])
    if status == "dead" then
        self[1] = coroutine.create(self[2])
    end
    return coroutine.resume(self[1], ...)
end

--Restart coroutine wrapped
function coroutineObject:restart()
    self[1] = coroutine.create(self[2])
end

--Gradually raises cpu to prevent lag spikes
--startCPU and stepSize can be nil
function BetterCoroutine.easeCPU(maxCPU, startCPU, stepSize, callback)
    if startCPU == nil then
        startCPU = 1/1000
    end
    if stepSize == nil then
        stepSize = 1/100
    end
    local easeCPU = coroutine.wrap(function()
        --while quotaAverage() < 1/5000 do end
        --coroutine.yield()
        --for cpu = startCPU, maxCPU + stepSize/2, stepSize do
        local e = math.exp(1)
        for i = 0, 1, stepSize do
            local cpu = startCPU + (maxCPU - startCPU) * i*i
            --local cpu = startCPU + (maxCPU - startCPU) / (1+math.exp(-(i-0.5)*3*e))
            if quotaAverage() < cpu then
                while quotaAverage() < cpu do end
                coroutine.yield()
            end
        end
        return true
    end)
    hook.add("think", "ease cpu", function()
        if easeCPU() == true then
            hook.remove("think", "ease cpu")
            callback()
        end
    end)
end

return BetterCoroutine
