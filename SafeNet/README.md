# SafeNet
Made to be a one and done net library replacement, SafeNet will automatically stream all data if it is too large to be sent immediately. You can use it the same way you use the native Starfall net utils and it has full backwards compatibility. You can just insert `local net = safeNet` at the top of the code and not change anything and it will work perfectly.

## Purpose
* Automatic streaming of all data that is too large to be sent immediately
* Eliminating the occurrence of the net burst limit error
* No organization needed for streaming large data
* No errors from attempting to start a net stream while another is in progress
* Spammable streaming utilities that do not require careful organization to not crash the chip

## Usage
* Optional: Add `local net = safeNet` to the top of the file. This is especially useful for retroactively adding the library to older files since it has full backwards compatibility.
* Add `--@include safeNet.txt` to the top of the file and `require("safeNet.txt")` in the code
* When `require("safeNet.txt")` is ran, it creates a global table named `safeNet` which has all of the functions
* Identical usage as native net utils i.e.
```lua
safeNet.start("hi")
safeNet.writeUInt8(123)
safeNet.writeEntity(chip())
safeNet.writeString("Hello, world!")
safeNet.send()
```

```lua
safeNet.receive("hi", function(size, ply)
  print("UInt8: " .. safeNet.readUInt8())
  print("Entity: " .. tostring(safeNet.readEntity()))
  print("String: " .. safeNet.readString())
end)
```
* Adds the ability to extend StringStream's functions, either by calling `safeNet.extend(StringStream)` or creating one and extending it at the same time with `safeNet.stringstream(stream, i or nil, endian or nil)` which uses the same parameters as `bit.stringstream()`

## Functions
### New Functions
#### safeNet
SafeNet includes new functions that the native net library does not.
All of the native net library's functions are still present, but will only be mentioned if there is a difference.
* `safeNet.writeReceived()` Writes the entire received stringstream for bouncing messages off of server/client to client/server. This is the only function that reads but does not advanced the buffer. This means that data can be bounced off the client/server while still allowing the reading of its contents. This can be done before or after reading.
* `safeNet.setTimeout(number seconds)` Sets the timeout for a stream. If server side, the actual timeout length used is the maximum of this and double the player's ping.
* `safeNet.setBPS(number BPS)` Sets the maximum bytes per second the networking can use. Actual networking size is still capped by `net.getBytesLeft()`
* `safeNet.extend(StringStream)` Extends the functions of the given StringStream object to include new ones
* `safeNet.start(string name, string or nil prefix)` Starts a net message using this name and prefix. The prefix defaults to `snm` and the real net message name becomes `prefix .. name`. Specifying a prefix is useful for libraries implementing safeNet because it allows the front end code or other libraries to effectively use the same net message names without interfering with each other.
* `safeNet.send(player or table or nil target, boolean or nil unreliable, string or nil prefix)` The target can be a specific player to send to, nil to send to all players/the server, and can also be a sequential table of players to send to if used server side. Specifying a prefix is useful for libraries implementing safeNet because it allows the front end code or other libraries to effectively use the same net message names without interfering with each other.
* `safeNet.cancel(number ID)` Cancels the net message with the given ID. Returns true if found, false if not
* `safeNet.cancelAll()` Cancels all pending and in-progress net messages
* `safeNet.writeType(any ...)` This is not new but it supports more datatypes. Writes a table or datatype. Supported datatypes are 32 bit signed ints, doubles, booleans, tables, angles, vectors, colors, entities, players, strings, quaternions, and vmatrices
* `safeNet.writeTable(any ...)` Is an alias to `safeNet.writeType()`
* `safeNet.readType(callback or nil, maxQuota or nil)` Reads a table or datatype. This is not a new function but if a callback is given, it will use a coroutine which will yield at the given max quota, or if that is nil, the minimum of quotaMax() * 0.75 and 0.004. There is no coroutine version for `safeNet.writeType()`, use `StringStream:writeType()` if a coroutine is needed. If using a coroutine, this should be the last `safeNet.read...` as it may change to a newly received message during the coroutined reading
* `safeNet.writeType()` and `safeNet.writeTable()` now accept varargs
* `safeNet.readType(function callback or nil, maxQuota or nil)` and `safeNet.readTable(function callback or nil, maxQuota or nil)` can now return varargs or run the callback with varargs. When providing a callback i.e. making it asynchronous, they will no longer return the results, even if they did not yield. Those results will only be sent into the function now. When used without a callback, they will still return the values normally.
* `safeNet.init(function callback or nil)` can be used to easily handle client ping and server response for initializations. E.g. clients ping the server when they spawn (does not have to be immediately) and the server responds with a list of props (not necessarily immediately). See example code at the bottom. When called on the client, it will ping the server, and if a callback is given, will run the callback with the server's response (will be varargs i.e. server responds with 2 vars, callback is called with 2 args). The server will keep a queue of players who pinged until `safeNet.init()` is called on the server. Then it will respond to all players in the queue and will immediately respond to incoming pings afterwards. If a callback is provided, the values returned by the it will be sent to the client. The callback passed to `safeNet.init()` on the server will be called with the player who pinged as an argument.
* `safeNet.writeBools(booleans ...)` writes up to 8 booleans in the same amount of bytes (1) as `safeNet.writeBool()`
* `safeNet.readBools(number count)` reads up to 8 booleans written by `safeNet.writeBools()`. Returns varargs.
* `safeNet.writeBits(numbers ...)` writes up to 8 bits in the same amount of bytes (1) as `safeNet.writeBit()`. If a number is 0, a 0 is written; otherwise a 1 is written.
* `safeNet.readBits(number count)` reads up to 8 booleans written by `safeNet.writeBools()`. Returns varargs.

[//]: # (Hello)
  Read and write functions
* `safeNet.writeColor(Color, hasAlpha or nil)` This is not new but if `hasAlpha` is given and is false, it will not include the alpha channel, thus using 3 bytes instead of 4. Defaults to writing alpha
* `safeNet.readColor(hasAlpha or nil)` This is not new but if `hasAlpha` is given and false, it will not attempt to read a 4th byte for the alpha. Defaults to reading alpha
* `safeNet.writeData(string, size or nil)` This is not new but the size paramater is now optional. It is not optional for `safeNet.readData()` however
* `safeNet.writeData2(string)` Writes a string of data while allowing the null char
* `safeNet.readData2()` Reads a string of data written by `safeNet.writeData2()`
* `safeNet.writeQuat(Quaternion)` Writes a quaternion using doubles
* `safeNet.readQuat()` Reads a quaternion
* `safeNet.writeStringStream(StringStream)` Writes the given StringStream object. Identical to using `safeNet.writeData(ss:getString())`
* `safeNet.writeHologram(Hologram)` Writes a hologram
* `safeNet.readHologram(callback or nil)` Reads a hologram. If on client and a callback is provided, it will wait for the entity to become valid like net.readEntity(callback)

[//]: # (Hello)
  Note that it is preferable to use the following functions for writing and reading ints as opposed to `safeNet.writeInt(number n, number bits)`, `safeNet.writeUInt(number n, number bits)`, `safeNet.readInt(number n, number bits)`, or `safeNet.readUInt(number n, number bits)` as those functions call these after checking which one to use.
* `safeNet.writeInt8(number)` Writes a signed 8 bit int: -127 -> 128
* `safeNet.readInt8()` Reads a signed 8 bit int: -127 -> 128
* `safeNet.writeUInt8(number)` Writes an unsigned 8 bit int: 0 -> 255
* `safeNet.readUInt8()` Reads an unsigned 8 bit int: 0 -> 255
* `safeNet.writeInt16(number)` Writes a signed 16 bit int: -32767 -> 32768
* `safeNet.readInt16()` Reads a signed 16 bit int: -32767 -> 32768
* `safeNet.writeUInt16(number)` Writes an unsigned 16 bit int: 0 -> 65535
* `safeNet.readUInt16()` Reads an unsigned 16 bit int: 0 -> 65535
* `safeNet.writeInt24(number)` Writes a signed 24 bit int: -8388607 -> 8388608
* `safeNet.readInt24()` Reads a signed 24 bit int: -8388607 -> 8388608
* `safeNet.writeUInt24(number)` Writes an unsigned 24 bit int: 0 -> 16777215
* `safeNet.readUInt24()` Reads an unsigned 24 bit int: 0 -> 16777215
* `safeNet.writeInt32(number)` Writes a signed 32 bit int: -2147483647 -> 2147483648
* `safeNet.readInt32()` Reads a signed 32 bit int: -2147483647 -> 2147483648
* `safeNet.writeUInt32(number)` Writes an unsigned 32 bit int: 0 -> 4294967295
* `safeNet.readUInt32()` Reads an unsigned 32 bit int: 0 -> 4294967295
<br>
* Vectors, angles, quaternions, and vmatrices are written with doubles with SafeNet while the native net utils use floats. This gives more precision than the native net utils

#### StringStream
SafeNet can extend the functions of StringSream objects.
All of the native StringStream functions are present, but only new ones will be mentioned.
* `StringStream:writeAngle(Angle)` Writes an angle using doubles
* `StringStream:readAngle()` Reads an angle
* `StringStream:writeBool(boolean)` Writes a boolean. Uses a full byte however.
* `StringStream:readBool()` Reads a boolean
* `StringStream:writeColor(Color, hasAlpha or nil)` Writes a color using 3 or 4 unsigned int8's. If `hasAlpha` is given and is false, it will not include the alpha channel, thus using 3 bytes instead of 4. Defaults to writing alpha
* `StringStream:readColor(hasAlpha or nil)` Reads a color. If `hasAlpha` is given and false, it will not attempt to read a 4th byte for the alpha. Defaults to reading alpha
* `StringStream:writeData2(string)` Writes a string and its length and accepts null chars
* `StringStream:readData2()` Reads a string written by `StringSream:writeData2(string)` and accepts null chars
* `StringStream:writeEntity(Entity)` Writes an entity using its entity index written as an unsigned 16 bit int
* `StringStream:readEntity(callback or nil)` Reads an entity by its entity index. If on client and a callback is provided, it will wait for the entity to become valid like net.readEntity(callback)
* `StringStream:writeHologram(Hologram)` Writes a hologram
* `StringStream:readHologram(callback or nil)` Readsa hologram. If on client and a callback is provided, it will wait for the entity to become valid like net.readEntity(callback)
* `StringStream:writeInt24(number)` Writes a signed or unsigned 24 bit int depending on how it is read. -8388607 -> 8388608 or 0 -> 16777215
* `StringStream:readInt24()` Reads a signed 24 bit int: -8388607 -> 8388608
* `StringStream:readUInt24()` Reads an unsigned 24 bit int: 0 -> 16777215
* `StringStream:writeMatrix(VMatrix)` Writes a VMatrix using doubles
* `StringStream:readMatrix()` Reads a VMatrix
* `StringStream:writeVector(Vector)` Writes a vector using doubles
* `StringStream:readVector()` Reads a vector
* `StringStream:writeQuat(Quaternion)` Writes a quaternion using doubles
* `StringStream:readQuat()` Reads a quaternion
* `StringStream:writeType(any, callback or nil, maxQuota or nil)` Writes a table or datatype. Supported datatypes are 32 bit signed ints, doubles, booleans, tables, angles, vectors, colors, entities, players, strings, quaternions, vmatrices, holograms, vehicles, weapons, npcs, and p2m. If a callback is given, it will use a coroutine which will yield at the given max quota, or if that is nil, the minimum of quotaMax() * 0.75 and 0.004
* `StringStream:readType(callback or nil, maxQuota or nil)` Reads a table or datatype. If a callback is given, it will use a coroutine which will yield at the given max quota, or if that is nil, the minimum of quotaMax() * 0.75 and 0.004

## safeNet.init() example
```lua
--@name init example
--@author Jacbo
--@shared
--@include safeNet.txt

require("safeNet.txt")
local net = safeNet

if SERVER then
    local a = 123
    local s = "Hello, world!"
    print("The following will be sent to clients when they init:")
    print(a, s)
    
    -- You could do stuff here that needed to be done before the ping response or respond instantly
    timer.simple(5, function()
        print("init")
        
        net.init(function(ply, arg1, arg2)
            print("Pinged by " .. ply:getName())
            print("arg1: ", arg1)
            print("arg2: ", arg2)
            return a, s -- This will be sent to the clients
        end)
    end)
else -- CLIENT
    print("Pinging...")
    -- Client can do stuff before sending the init ping or send it now
    net.init(function(...)
        print("Got response")
        print(...)
    end, "hi", player():getName())
end
```
