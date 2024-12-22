## Better Coroutines
An improved version of `coroutine.wrap()`. It functions identically to `coroutine.wrap()` except it automatically restarts the coroutine when it is run after dying. It also let's you prematurely restart the coroutine without letting it finish.
### Usage
```lua
--@name Better Coroutines Example
--@author Jacbo
--@include https://raw.githubusercontent.com/Jacbo1/Public-Starfall/main/Better%20Coroutines/Better%20Coroutines.lua as CorLib

local corLib = require("CorLib")

local my_func = corLib.wrap(function(arg1, arg2, ...)
    print("Arg1: ", arg1)
    print("Arg2: ", arg2)
    coroutine.yield()
    print("Varargs: ", ...)
    return true
end)

for i = 1, 2 do
    local status
    repeat
        print("Running")
        status = my_func(123, "abc", "Hello, ", "world!")
    until status
    if i == 1 then
        print("Restarting")
    end
end
```
Running `my_func:restart()` would restart it prematurely.
