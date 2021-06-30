## SafeNet
Made to be a one and done net library replacement, SafeNet will automatically stream all data if it is too large to be sent immediately. You can use it the same way you use the native Starfall net utils and it has full backwards compatibility. You can just insert `local net = safeNet` at the top of the code and not change anything and it will work perfectly.

### Purpose
* Automatic streaming of all data that is too large to be sent immediately
* Eliminating the occurrence of the net burst limit error
* Spammable streaming utilities that do not require careful organization to not crash the chip

### Usage
* Optional: Add `local net = safeNet` to the top of the file
This is especially useful for retroactively adding the library to older files since it has full backwards compatibility.
* Add `--@include safeNet.txt` to the top of the file and `require("safeNet.txt")` in the code
* When `require("safeNet.txt")` is ran, it creates a global table named `safeNet` which has all of the functions
* Identical usage as native net utils i.e.```lua
safeNet.start("hi")
safeNet.writeUInt8(123)
safeNet.writeEntity(chip())
safeNet.writeString("Hello, world!")
safeNet.send()```
```lua
safeNet.receive("hi", function(size, ply)
  print("UInt8: " .. safeNet.readUInt8())
  print("Entity: " .. tostring(safeNet.readEntity()))
  print("String: " .. safeNet.readString())
end)```
* Adds the ability to extend StringStream's functions, either by calling `safeNet.extend(stringstream)` or creating one and extending it at the same time with `safeNet.stringstream(stream, i or nil, endian or nil)` which uses the same parameters as `bit.stringstream()`

### Functions
#### SafeNet
##### New Functions
SafeNet includes new functions that the native net library does not.
* safeNet.writeData2(string)
Writes a string of data while allowing the null char
* safeNet.readData2()
Reads a string of data written by `safeNet.writeData2()`
* safeNet.writePlayer(string)
