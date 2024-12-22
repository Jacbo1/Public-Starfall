--@name Better Coroutines
--@author Jacbo
-- https://github.com/Jacbo1/Public-Starfall/tree/main/Better%20Coroutines
-- To include add this to the top of your file and omit the require() (remove the space between --@ and include):
-- --@ include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/main/Better%20Coroutines/Better%20Coroutines.lua as CorLib

-- When you require this, it returns BetterCoroutine
-- e.g. local corLib = require("CorLib")
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

return BetterCoroutine
