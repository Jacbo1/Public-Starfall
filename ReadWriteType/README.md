# ReadWriteType
Read and write more than just strings to files. Can read and write Angle, boolean, Color, double, float, int8, uint8, int16, uint16, int24, uint24, int32, uint32, Quaternion, string, table, varargs, Vector, VMatrix, and nil.

## Example
```lua
--@name Test
--@author Jacbo
--@include readwritetype.txt
--@client

require("readwritetype.txt")

if player() ~= owner() then return end

file.write("test.txt", "")
local writer = FileWriter("test.txt", 1024)
writer:writeDouble(12.45)
writer:writeInt24(2567)
local t = {123, "Hello, world!", Vector(4,5,6), Angle(-7,-8,-9), {test = Quaternion(1,2,3,4), abc = Color(1,2,3,4), Matrix({{1,2,3,4},{5,6,7,8},{9,10,11,12},{13,14,15,16}})}}
writer:writeTable(t)
writer:writeMulti(123, "hello")
writer:writeVector(Vector(1,2354.653,-35.21))

writer:writeBuffer() -- VERY IMPORTANT

local reader = FileReader("test.txt")
print(reader:readDouble())
print(reader:readUInt24())
printTable(reader:readTable())
print(reader:readMulti())
print(reader:readVector())
```

## Usage
### Writing
* `FileWriter(string path, number or nil maxBufferSize)` Creates a FileWriter to the file at `path`. The second parameter determines how long the buffer string can be before it is appended to the file. This helps with performance. Default is 1024.
* `FileWriter:writeBuffer()` This **MUST** be called when finished writing. It writes the remaining data in the buffer string to the file and clears the buffer. If you do not call this, it will not finish writing.
* `FileWriter:writeAngle(Angle angle)` Appends an angle using 3 doubles.
* `FileWriter:writeBool(boolean bool1, boolean bool2, boolean bool3, boolean bool4)` Appends up to 4 booleans in 1 byte. All of the bool inputs are optional.
* `FileWriter:writeColor(Color color)` Appends a color using 4 8 bit ints.
* `FileWriter:writeDouble(number number)` Appends a double using 8 bytes.
* `FileWriter:writeFloat(number number)` Appends a float using 4 bytes.
* `FileWriter:writeInt8(number number)` Appends an 8 bit int (-127 to 128). Also works with unsigned 8 bit ints (0 to 255).
* `FileWriter:writeInt16(number number)` Appends a 16 bit int (-32767 to 32768). Also works with unsigned 16 bit ints (0 to 65535).
* `FileWriter:writeInt24(number number)` Appends a 24 bit int (-8388607 to 8388608). Also works with unsigned 24 bit ints (0 to 16777215).
* `FileWriter:writeInt32(number number)` Appends a 32 bit int (-2147483647 to 2147483648). Also works with unsigned 32 bit ints (0 to 4294967295).
* `FileWriter:writeMatrix(VMatrix matrix)` Appends a VMatrix using 16 doubles.
* `FileWriter:writeQuaternion(Quaternion quat)` Appends a quaternion using 4 doubles.
* `FileWriter:writeString(string string, number or nil length)` Appends a string and stores the length with it using a 32 bit int unless `length` is provided. If `length` is not nil, the string is appended without the string length which is assumed to be the same as `length`. This can save space and cpu with large amounts of uniform length strings.
* `FileWriter:writeTable(table table, number or nil maxQuota)` Appends a table. Supports all listed types. If maxQuota is not nil, it will `coroutine.yield()` if `quotaAverage()` exceeds maxQuota.
* `FileWriter:writeTableAsync(table tbl, number or nil maxQuota, function callback)` Appends a table asynchronously. Useful for large tables that would otherwise exceed the quota limit. If maxQuota is nil, `math.min(quotaMax() * 0.75, 0.004)` will be used instead.
* `FileWriter:writeType(any data, number or nil maxQuota)` Appends a type. Supports all listed types. If maxQuota is not nil, it will `coroutine.yield()` if `quotaAverage()` exceeds maxQuota.
* `FileWriter:writeMulti(number or nil maxQuota, ... args)` Appends multiple types. Supports all listed types. If maxQuota is not nil, it will `coroutine.yield()` if `quotaAverage()` exceeds maxQuota.
* `FileWriter:writeMultiAsync(number or nil maxQuota, function callback, ...)` Appends varargs asynchronously and runs the callback when done. Supports all listed types. If maxQuota is nil, `math.min(quotaMax() * 0.75, 0.004)` will be used instead.
* `FileWriter:writeVector(Vector vector)` Appends a vector using 3 doubles.
### FileReader
* `FileReader(string path)` Creates a FileReader which can read types from a file written by a FileWriter.
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
* `FileReader:readString(number or nil length)` Reads a string.
* `FileReader:readType(number or nil maxQuota)` Reads a type. Supports all listed types. If maxQuota is not nil, it will `coroutine.yield()` if `quotaAverage()` exceeds maxQuota.
* `FileReader:readFileReader:readTable(number or nil maxQuota)` Alias for `FileReader:readType()` for readability.
* `FileReader:readTableAsync(number or nil maxQuota, function callback)` Read a table asynchonously. Useful for large tables that would otherwise exceed the quota limit. The callback will be called with the table as the only parameter. If maxQuota is nil, `math.min(quotaMax() * 0.75, 0.004)` will be used instead.
* `FileReader:readType()` Reads a type or varargs.
* `FileReader:readMulti(number or nil maxQuota)` Reads and returns multiple types. If maxQuota is not nil, it will `coroutine.yield()` if `quotaAverage()` exceeds maxQuota.
* `FileReader:readMultiAsync(number or nil maxQuota, function calback)` Reads multiple types asynchronously. The callback is called with the varargs it read. If maxQuota is nil, `math.min(quotaMax() * 0.75, 0.004)` will be used instead.
