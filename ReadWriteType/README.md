# ReadWriteType
Read and write more than just strings to files. Can read and write Angle, boolean, Color, double, float, int8, uint8, int16, uint16, int24, uint24, int32, uint32, Quaternion, string, table, varargs, Vector, and VMatrix.

## Example
```lua
--@name Test
--@author Jacbo
--@include readwritetype.txt
--@client

require("readwritetype.txt")

if player() ~= owner() then return end

file.write("test.txt", "")
file.appendDouble("test.txt", 12.45)
file.appendInt24("test.txt", 2567)
local t = {123, "Hello, world!", Vector(4,5,6), Angle(-7,-8,-9), {test = Quaternion(1,2,3,4), abc = Color(1,2,3,4), Matrix({{1,2,3,4},{5,6,7,8},{9,10,11,12},{13,14,15,16}})}}
file.appendTable("test.txt", t)
file.appendType("test.txt", 123, "hello")
file.appendVector("test.txt", Vector(1,2354.653,-35.21))

local reader = FileReader("test.txt")
print(reader:readDouble())
print(reader:readUInt24())
printTable(reader:readTable())
print(reader:readType())
print(reader:readVector())
```

## Usage
**NOTE: You need to use file.appendString() instead of file.append() so the string can be read with the FileReader.** file.appendString() stores the length of the string with the string itself so FileReader:readString() knows how many bytes to read.  
### Appending
* `file.appendAngle(string path, Angle angle)` Appends an angle using 3 doubles.
* `file.appendBool(string path, boolean bool1, boolean bool2, boolean bool3, boolean bool4)` Appends up to 4 booleans in 1 byte. All of the bool inputs are optional.
* `file.appendColor(string path, Color color)` Appends a color using 4 8 bit ints.
* `file.appendDouble(string path, number number)` Appends a double using 8 bytes.
* `file.appendFloat(string path, number number)` Appends a float using 4 bytes.
* `file.appendInt8(string path, number number)` Appends an 8 bit int (-127 to 128). Also works with unsigned 8 bit ints (0 to 255).
* `file.appendInt16(string path, number number)` Appends a 16 bit int (-32767 to 32768). Also works with unsigned 16 bit ints (0 to 65535).
* `file.appendInt24(string path, number number)` Appends a 24 bit int (-8388607 to 8388608). Also works with unsigned 24 bit ints (0 to 16777215).
* `file.appendInt32(string path, number number)` Appends a 32 bit int (-2147483647 to 2147483648). Also works with unsigned 32 bit ints (0 to 4294967295).
* `file.appendMatrix(string path, VMatrix matrix)` Appends a VMatrix using 16 doubles.
* `file.appendQuaternion(string path, Quaternion quat)` Appends a quaternion using 4 doubles.
* `file.appendString(string path, string string)` Appends a string and stores the length with it using a 32 bit int. **Use this instead of `file.append()`**
* `file.appendTable(string path, table table)` Appends a table. Supports all listed types.
* `file.appendTableAsync(string path, table tbl, number or nil maxQuota, function callback)` Appends a table asynchronously. Useful for large tables that would otherwise exceed the quota limit. If maxQuota is nil, `math.min(quotaMax() * 0.75, 0.004)` will be used instead.
* `file.appendType(string path, ...)` Appends varargs. Supports all listed types and nil.
* `file.appendTypeAsync(string path, number or nil maxQuota, function callback, ...)` Appends varargs asynchronously. If maxQuota is nil, `math.min(quotaMax() * 0.75, 0.004)` will be used instead.
* `file.appendVector(string path, Vector vector)` Appends a vector using 3 doubles.
### FileReader
Use `FileReader(string path)` to create a FileReader which can read types.
* `FileReader:getBuffer()` Returns the buffer (the file text). Equivalent to, but slower than, `FileReader[1]`
* `FileReader:getBufferPos()` Returns the buffer reader position. Equivalent to, but slower than, `FileReader[2]`
* `FileReader:getBufferSize()` Returns the size of the buffer (length of the file text). Equivalent to, but slower than, `FileReader[3]`
* `FileReader:setBufferPos(number pos)` Sets the position of the buffer reader.
* `FileReader:skip(number bytes)` Advances the buffer reader position by this many bytes.
### Reading
* `FileReader:read(number bytes)` Reads this many bytes.
* `FileReader:readAngle()` Reads an angle
* `FileReader:readBool()` Reads 4 booleans from 1 byte (just ignore trailing return values if you didn't write all 4).
* `FileReader:readColor()` Reads a color.
* `FileReader:readDouble()` Reads a double.
* `FileReader:readFloat()` Reads a float.
* `FileReader:readInt8()` Reads an 8 bit int (-127 to 128).
* `FileReader:readUInt8()` Reads an unsigned 8 bit int (0 to 255).
* `FileReader:readInt16()` Reads a 16 bit int (-32767 to 32768).
* `FileReader:readUInt16()` Reads an unsigned 16 bit int (0 to 65535).
* `FileReader:readInt24()` Reads a 24 bit int (-8388607 to 8388608).
* `FileReader:readUInt24()` Reads an unsigned 24 bit int (0 to 16777215).
* `FileReader:readInt32()` Reads a 32 bit int (-2147483647 to 2147483648).
* `FileReader:readUInt32()` Reads an unsigned 32 bit int (0 to 4294967295).
* `FileReader:readMatrix()` Reads a VMatrix.
* `FileReader:readQuaternion()` Reads a quaternion.
* `FileReader:readString(number or nil length)` Reads a string. Input length to use it as `FileReader:read(number length)`. Do not input length if it was written with `file.appendString()` as it will instead read the length stored with the string, then the string itself.
* `FileReader:readTable()` Reads a table.
* `FileReader:readTableAsync(number or nil maxQuota, function callback)` Read a table asynchonously. Useful for large tables that would otherwise exceed the quota limit. The callback will be called with the table as the only parameter. If maxQuota is nil, `math.min(quotaMax() * 0.75, 0.004)` will be used instead.
* `FileReader:readType()` Reads a type or varargs.
* `FileReader:readTypeAsync(number or nil maxQuota, function calback)` Read a type or vararg asynchronously. The callback is called with the varargs it read. If maxQuota is nil, `math.min(quotaMax() * 0.75, 0.004)` will be used instead.
