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
* `safeNet.setTimeout(number seconds)` Sets the timeout for a stream. If server side, the actual timeout length used is the maximum of this and double the player's ping.
* `safeNet.setBPS(number BPS)` Sets the maximum bytes per second the networking can use. Actual networking size is still capped by `net.getBytesLeft()`
* `safeNet.extend(StringStream)` Extends the functions of the given StringStream object to include new ones
* `safeNet.send(target or nil, unreliable or nil)` This is not new but it does now return a stream ID that can be used later to cancel the net message. The target can also be a sequential table of players to send to if used server side
* `safeNet.cancel(number ID)` Cancels the net message with the given ID. Returns true if found, false if not
* `safeNet.cancelAll()` Cancels all pending and in-progress net messages
* `safeNet.writeType(any)` This is not new but it supports more datatypes. Writes a table or datatype. Supported datatypes are 32 bit signed ints, doubles, booleans, tables, angles, vectors, colors, entities, players, strings, quaternions, and vmatrices
* `safeNet.readType(callback or nil, maxQuota or nil)` Reads a table or datatype. This is not a new function but if a callback is given, it will use a coroutine which will yield at the given max quota, or if that is nil, the minimum of quotaMax() * 0.75 and 0.004. There is no coroutine version for `safeNet.writeType()`, use `StringStream:writeType()` if a coroutine is needed. If using a coroutine, this should be the last `safeNet.read...` as it may change to a newly received message during the coroutined reading

[//]: # (Hello)
  Read and write functions
* `safeNet.writeColor(Color, hasAlpha or nil)` This is not new but if `hasAlpha` is given and is false, it will not include the alpha channel, thus using 3 bytes instead of 4. Defaults to writing alpha
* `safeNet.readColor(hasAlpha or nil)` This is not new but if `hasAlpha` is given and false, it will not attempt to read a 4th byte for the alpha. Defaults to reading alpha
* `safeNet.writeData(string, size or nil)` This is not new but the size paramater is now optional. It is not optional for `safeNet.readData()` however
* `safeNet.writeData2(string)` Writes a string of data while allowing the null char
* `safeNet.readData2()` Reads a string of data written by `safeNet.writeData2()`
* `safeNet.writePlayer(Player)` Writes the player's steam ID as a string. Alternatively you can use `safeNet.writeEntity(Player)` and its corresponding `safeNet.readEntity()`
* `safeNet.readPlayer()` Reads the player's steam ID and uses `find.allPlayers()` and returns the first player found with that steam ID
* `safeNet.writeQuat(Quaternion)` Writes a quaternion using doubles
* `safeNet.readQuat()` Reads a quaternion
* `safeNet.writeStringStream(StringStream)` Writes the given StringStream object. Identical to using `safeNet.writeData(ss:getString())`

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
* Vectors, angles, and vmatrices are written with doubles with SafeNet while the native net utils use floats. This gives more precision than the native net utils

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
* `StringStream:readEntity()` Reads an entity by its entity index
* `StringStream:writeInt24(number)` Writes a signed or unsigned 24 bit int depending on how it is read. -8388607 -> 8388608 or 0 -> 16777215
* `StringStream:readInt24()` Reads a signed 24 bit int: -8388607 -> 8388608
* `StringStream:readUInt24()` Reads an unsigned 24 bit int: 0 -> 16777215
* `StringStream:writeMatrix(VMatrix)` Writes a VMatrix using doubles
* `StringStream:readMatrix()` Reads a VMatrix
* `StringStream:writePlayer(Player)` Writes the player's steam ID as a string. Alternatively you can use `StringStream:writeEntity(Player)` and its corresponding `StringStream:readEntity()`
* `StringStream:readPlayer()` Reads the player's steam ID and uses `find.allPlayers()` and returns the first player found with that steam ID
* `StringStream:writeVector(Vector)` Writes a vector using doubles
* `StringStream:readVector()` Reads a vector
* `StringStream:writeQuat(Quaternion)` Writes a quaternion using doubles
* `StringStream:readQuat()` Reads a quaternion
* `StringStream:writeType(any, callback or nil, maxQuota or nil)` Writes a table or datatype. Supported datatypes are 32 bit signed ints, doubles, booleans, tables, angles, vectors, colors, entities, players, strings, quaternions, and vmatrices. If a callback is given, it will use a coroutine which will yield at the given max quota, or if that is nil, the minimum of quotaMax() * 0.75 and 0.004
* `StringStream:readType(callback or nil, maxQuota or nil)` Reads a table or datatype. If a callback is given, it will use a coroutine which will yield at the given max quota, or if that is nil, the minimum of quotaMax() * 0.75 and 0.004
