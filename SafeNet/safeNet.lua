--@name SafeNet
--@author Jacbo
--https://github.com/Jacbo1/Public-Starfall/tree/main/SafeNet

-- You can extend stringstreams functions for use with this with safeNet.extend(stringstream) or creating one with safeNet.stringstream(stream, i, endian) (same params as bit.stringstream())
-- You should be able to just override net with safeNet at the top of your file ie local net = safeNet (MAKE SURE TO KEEP IT LOCAL)
-- This should be impossible to error from net burst or spamming streams and will automatically stream all data
-- Can read and write signed and unsigned int8, int16, int24, int32, and booleans, strings, players, entities, vectors, angles, chars, vmatrices, quaternions, tables

-- Has all the same read and write functions as net and more



-- Differences include:

-- safeNet.start(string name, string or nil prefix)
-- name is the name of the net message but the prefix is useful for libraries implementing this one
-- as they can use their own prefixes instead of the default "snstream" prefix
-- this would allow the front end code to effectively use the same net message names without interfering
-- with the library

-- safeNet.send(player or table or nil targets, boolean or nil unreliable) returns a net index that can be used to cancel that specific stream
-- targets can be nil to send to all clients from the server or send to the server from the client
-- targets can be a player to send to that player from the server
-- targets can be a table of players to send to from the server

-- safeNet.receive(string name, function or nil callback, string or nil prefix)
-- name is the name of the net message
-- callback is the callback used when a message is received
-- The prefix is useful for libraries implementing safeNet because they can use their own prefix
-- instead of the default "snstream" prefix so front end code can effectively use the same
-- net message names as those in the library

-- safeNet.isSending() checks for out-going streams

-- Extended StringStreams will have all the same read and write methods as safeNet with the exception of
--   - writeUInt methods as the writeInt methods essenitally write uints already
--   - writeInt(), writeUInt(), readInt(), readUInt()
--   - writeChar(), readChar(), just use :write(c) and :read(1)
--   - There is no writeTable and readTable; writeType and readType are exactly the same
--   - writeHologram() and readHologram()

-- safeNet.cancel(ID) cancels the stream corresponding to this ID (removes queued items too)

-- safeNet.cancelAll() cancels all streams and clears the queue

-- writeData2() acts the same as writeData() but it saves the length too and readData2() can be called later without a byte length (this does require a byte count)

-- writeColor() has an optional input for whether or not it should use an extra byte to write the alpha
-- readColor() has an optional input for whether or not it should read this extra byte for the alpha
-- Both default to true

-- It is recommended to use writeData2 and readData2 as opposed to writeStream and readStream
-- The stream functions still work for compatibility reasons (as long as there are no null chars) but it is pointless as this library automatically streams everything when required

-- safeNet.writeHologram(hologram)
-- safeNet.readHologram()

-- safeNet.stringstream(stream, i, endian) creates a StringStream object with extended functions

-- safeNet.extend(stringstream) extends an existing string stream, giving it the extra functions

-- safeNet.setTimeout(number) sets the timeout delay for receiving networks

-- safeNet.setBPS(number) sets the partition size. This is the bytes per second cap

-- safeNet.readType(), safeNet.readTable(), StringStream:writeType(), and StringStream:readType() can be called with a callback and max quota for a coroutine instead of instant running
-- StringStream:writeType(obj, cb or nil, maxQuota or nil)
-- StringStream:readType(cb or nil, maxQuota or nil)
-- If called with no inputs it will try to isntantly write/read
-- Else it will use a coroutine and a callback
-- maxQuota can be nil and will default to math.min(quotaMax() * 0.75, 0.004)
-- safeNet reads may not work correctly after reading a type/table with a callback as it may have changed due to a different receive

-- safeNet.writeType, writeTable, readType, and readTable accept varargs
-- readType and readTable still allow the use of a callback with varargs

-- safeNet.writeBools(booleans ...) writes up to 8 booleans using the same amount of bytes (1) as safeNet.writeBool()
-- safeNet.readBools(number count) reads up to 8 booleans written with safeNet.writeBools()

-- safeNet.writeBits(bits ...) writes up to 8 bits using the same amount of bytes (1) as safeNet.writeBit()
-- safeNet.readBits() reads up to 8 bits written with safeNet.writeBits()

-- safeNet.init(callback or nil) is an initialization utility and acts differently on the server and client
-- Useful for e.g. clients ping the server when are initialized or after doing something and the server responds immediately or after doing something itself
-- e.g. Clients ping the server and the server responds with a table of entities that it may or may not be able to spawn all at once
-- On the client, it pings the server when called and if a callback is provided, runs the callback with the server's response
-- On the server, a queue is kept until safeNet.init() is called. When called, it will respond to all clients with the result returned by the callback here
-- The response can be vararg
-- Example usage of safeNet.init():
--[[
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
]]

if safeNet then return end

-- This is the bytes per second cap
local BPS = 1024 * 1024
local timeout = 10
    
local curReceive, curSend, curSendName, curPrefix

--safeNet object
local bit_rshift = bit.rshift
local bit_lshift = bit.lshift
local string_char = string.char
local string_sub = string.sub
local string_byte = string.byte
local string_find = string.find
local string_replace = string.replace
local table_insert = table.insert
local null_char = string_char(0)
local waitForEntities = true
local bit_band = bit.band
safeNet = {}

local sends = {}
local streaming = false
local canceling = false
local playerQueue
local playerCancelQueue
local cancelQueue = false

function safeNet.setTimeout(newTimeout) timeout = newTimeout end

-- Sets the bytes per second cap
function safeNet.setBPS(newBPS) BPS = newBPS end

function safeNet.start(name, prefix)
    curPrefix = prefix or "snstream"
    curSend = safeNet.stringstream()
    curSendName = name
end

-- Writes a boolean
function safeNet.writeBool(bool)
    curSend:write(bool and "1" or "0")
end

-- Reads a boolean
function safeNet.readBool()
    return curReceive:read(1) ~= "0"
end

-- Writes up to 8 booleans using the same size as 1 bool
function safeNet.writeBools(...)
    local int = 0
    local args = {...}
    for i = 0, #args-1 do
        int = int + (args[i+1] and bit_lshift(1, i) or 0)
    end
    curSend:writeInt8(int)
end

-- Reads up to 8 booleans using the same size as 1 bool
function safeNet.readBools(count)
    local int = curReceive:readUInt8()
    local bools = {}
    for i = 0, count-1 do
        bools[i+1] = (bit_and(int, bit_lshift(1, i)) ~= 0)
    end
    return unpack(bools)
end

-- Writes a char
function safeNet.writeChar(c)
    curSend:write(c)
end

-- Reads a char
function safeNet.readChar()
    return curReceive:read(1)
end

-- Writes a color
-- hasAlpha defaults to true
function safeNet.writeColor(color, hasAlpha)
    curSend:writeInt8(color[1])
    curSend:writeInt8(color[2])
    curSend:writeInt8(color[3])
    if hasAlpha == nil or hasAlpha then
        curSend:writeInt8(color[4])
    end
end

-- Reads a color
-- hasAlpha defaults to true
function safeNet.readColor(hasAlpha)
    return Color(
        curReceive:readUInt8(),
        curReceive:readUInt8(),
        curReceive:readUInt8(), 
        (hasAlpha == nil or hasAlpha) and curReceive:readUInt8() or nil)
end

-- Writes a player
function safeNet.writePlayer(ply)
    curSend:writeString(ply:getSteamID())
end

-- Reads a player
function safeNet.readPlayer()
    local steamID = curReceive:readString()
    return find.allPlayers(function(ply)
        return ply:getSteamID() == steamID
    end)[1]
end

-- Writes an 8 bit int
-- -127 to 128
function safeNet.writeInt8(num) curSend:writeInt8(num) end
-- 0 to 255
safeNet.writeUInt8 = safeNet.writeInt8

-- Reads an unsigned 8 bit int
-- 0 to 255
function safeNet.readUInt8()
    return curReceive:readUInt8()
end

-- Reads a signed 8 bit int
-- -127 to 128
function safeNet.readInt8()
    return curReceive:readInt8()
end

-- Writes a 16 bit int
-- -32767 to 32768
function safeNet.writeInt16(num) curSend:writeInt16(num) end
-- 0 to 65535
safeNet.writeUInt16 = safeNet.writeInt16

-- Reads an unsigned 16 bit int
-- 0 to 65535
function safeNet.readUInt16()
    return curReceive:readUInt16()
end

-- Reads a signed 16 bit int
-- -32767 to 32768
function safeNet.readInt16()
    return curReceive:readInt16()
end

-- Writes a 24 bit int
-- -8388607 to 8388608
function safeNet.writeInt24(num) curSend:writeInt24(num) end
-- 0 to 16777215
safeNet.writeUInt24 = safeNet.writeInt24

-- Reads an unsigned 24 bit int
-- 0 to 16777215
function safeNet.readUInt24()
    return curReceive:readUInt24()
end

-- Reads a signed 24 bit int
-- -8388607 to 8388608
function safeNet.readInt24()
    return curReceive:readInt24()
end

-- Writes a 32 bit int
-- -2147483647 to 2147483648
function safeNet.writeInt32(num) curSend:writeInt32(num) end
-- 0 to 4294967295
safeNet.writeUInt32 = safeNet.writeInt32

-- Reads an unsigned 32 bit int
-- 0 to 4294967295
function safeNet.readUInt32(num)
    return curReceive:readUInt32()
end

-- Reads a signed 32 bit int
-- -2147483647 to 2147483648
function safeNet.readInt32()
    return curReceive:readInt32()
end

-- Writes an int (compatibility function)
-- Use one of the other writeInt functions instead
function safeNet.writeInt(num, bits)
    if bits <= 8 then curSend:writeInt8(num)
    elseif bits <= 16 then curSend:writeInt16(num)
    elseif bits <= 24 then curSend:writeInt24(num)
    else curSend:writeInt32(num) end
end
safeNet.writeUInt = safeNet.writeInt

-- Reads a signed int (compatibility function)
-- Use one of the other readInt functions instead
function safeNet.readInt(bits)
    if bits <= 8 then return curReceive:readInt8()
    elseif bits <= 16 then return curReceive:readInt16()
    elseif bits <= 24 then return curReceive:readInt24()
    else return curReceive:readInt32() end
end

-- Reads an unsigned int (compatibility function)
-- Use one of the other readUInt functions instead
function safeNet.readUInt(bits)
    if bits <= 8 then return curReceive:readUInt8()
    elseif bits <= 16 then return curReceive:readUInt16()
    elseif bits <= 24 then return curReceive:readUInt24()
    else return curReceive:readUInt32() end
end

-- Writes an entity
function safeNet.writeEntity(ent)
    curSend:writeInt16(ent:entIndex())
end

-- Reads an entity
function safeNet.readEntity()
    return entity(curReceive:readUInt16())
end

-- Writes a hologram
safeNet.writeHologram = safeNet.writeEntity

-- Reads a hologram
function safeNet.readHologram()
    return entity(curReceive:readUInt16()):toHologram()
end

-- Writes a "bit" (mainly here for compatibility)
function safeNet.writeBit(b)
    curSend:write(b == 0 and "0" or "1")
end

-- Reads a "bit" (mainly here for compatibility)
function safeNet.readBit(b)
    return curReceive:read(1) == "0" and 0 or 1
end

-- Writes up to 8 bits using the same size as 1 bit
function safeNet.writeBits(...)
    local int = 0
    local args = {...}
    for i = 0, #args-1 do
        int = int + ((args[i+1] ~= 0) and bit_lshift(1, i) or 0)
    end
    --curSend:writeInt8((a and 1 or 0) + (b and 2 or 0) + (c and 4 or 0) + (d and 16 or 0))
    curSend:writeInt8(int)
end

-- Reads up to 8 bits using the same size as 1 bit
function safeNet.readBits(count)
    local int = curReceive:readUInt8()
    local bits = {}
    for i = 0, count-1 do
        bits[i+1] = (bit_and(int, bit_lshift(1, i)) ~= 0) and 1 or 0
    end
    return unpack(bits)
end

-- Writes a float
function safeNet.writeFloat(num)
    curSend:writeFloat(num)
end

-- Reads a float
function safeNet.readFloat()
    return curReceive:readFloat()
end

-- Writes a double
function safeNet.writeDouble(num)
    curSend:writeDouble(num)
end

-- Reads a double
function safeNet.readDouble()
    return curReceive:readDouble()
end

-- Writes a vector
function safeNet.writeVector(vec)
    curSend:writeDouble(vec[1])
    curSend:writeDouble(vec[2])
    curSend:writeDouble(vec[3])
end

-- Reads a vector
function safeNet.readVector()
    return Vector(curReceive:readDouble(), curReceive:readDouble(), curReceive:readDouble())
end

-- Writes an angle
function safeNet.writeAngle(ang)
    curSend:writeDouble(ang[1])
    curSend:writeDouble(ang[2])
    curSend:writeDouble(ang[3])
end

-- Reads an angle
function safeNet.readAngle()
    return Angle(curReceive:readDouble(), curReceive:readDouble(), curReceive:readDouble())
end

-- Writes a quaternion
function safeNet.writeQuat(quat)
    curSend:writeDouble(quat[1])
    curSend:writeDouble(quat[2])
    curSend:writeDouble(quat[3])
    curSend:writeDouble(quat[4])
end

-- Reads a quaternion
function safeNet.readQuat()
    return Quaternion(curReceive:readDouble(), curReceive:readDouble(), curReceive:readDouble(), curReceive:readDouble())
end

-- Writes a matrix
function safeNet.writeMatrix(matrix)
    for row = 1, 4 do
        for col = 1, 4 do
            curSend:writeDouble(matrix:getField(row, col))
        end
    end
end

-- Reads a matrix
function safeNet.readMatrix()
    local matrix = {}
    for row = 1, 4 do
        local rowt = {}
        for col = 1, 4 do
            table.insert(rowt, curReceive:readDouble())
        end
        table.insert(matrix, rowt)
    end
    return Matrix(matrix)
end

-- Writes a string
-- USE WRITEDATA IF STRING CONTAINS \0
function safeNet.writeString(str)
    curSend:writeString(str)
end

-- Reads a string
function safeNet.readString()
    return curReceive:readString()
end

-- Writes a specified amount of data
-- Byte length optional
function safeNet.writeData(str, bytes)
    if bytes then curSend:write(string_sub(str, 1, bytes))
    else curSend:write(str) end
end

-- Reads a specified amount of data
function safeNet.readData(bytes)
    return curReceive:read(bytes)
end

-- Same as safeNet.writeData() but does not require a length
function safeNet.writeData2(str)
    curSend:writeInt32(#str)
    curSend:write(str)
end

-- Same as safeNet.readData() but does not require a length
function safeNet.readData2()
    local length = curReceive:readUInt32()
    return curReceive:read(length)
end

-- Writes a "stream" (mainly here for compatibility)
-- Use writeString() or writeData() instead
-- DO NOT USE NULL CHARS
safeNet.writeStream = safeNet.writeData2

-- Reads a "stream" (mainly here for compatibility)
-- Use readString() or readData() instead
-- DO NOT USE NULL CHARS
function safeNet.readStream(cb)
    cb(curReceive:readData2())
end

-- Writes an object(s)
-- Accepts varargs
function safeNet.writeType(...)
    local count = select("#", ...)
    curSend:writeInt8(count)
    local args = {...}
    for i = 1, count do
        curSend:writeType(args[i])
    end
end
-- Writes a table
safeNet.writeTable = safeNet.writeType

-- Reads an object
-- If called with no inputs it will try to isntantly read
-- Else it will use a coroutine and a callback
-- maxQuota can be nil and will default to math.min(quotaMax() * 0.75, 0.004)
-- Returns varargs or runs the callback with varargs
function safeNet.readType(cb, maxQuota)
    local count = curReceive:readUInt8()
    local results = {}
    if cb then
        if count > 1 then
            local i = 1
            local recurse
            recurse = function()
                curReceive:readType(function(result)
                    table_insert(results, result)
                    i = i + 1
                    if i > count then
                        cb(unpack(results))
                    else
                        recurse()
                    end
                end, maxQuota)
            end
            recurse()
        else
            cb()
        end
    else
        for i = 1, count do
            table_insert(results, curReceive:readType())
        end
        
        return unpack(results)
    end
end

-- Reads a table
safeNet.readTable = safeNet.readType

local encode, decode, encodeCoroutine, decodeCoroutine

-- Elseifs have been found faster than a lookup table seemingly only when mapping to functions
function safeNet.extend(stringStream)
    function stringStream:writeData2(str)
        self:writeInt32(#str)
        self:write(str)
    end
    
    function stringStream:readData2()
        local len = self:readUInt32()
        return self:read(len)
    end
    
    function stringStream:writeBool(b)
        self:write(b and "1" or "0")
    end
    
    function stringStream:readBool()
        return self:read(1) ~= "0"
    end

    -- Writes a signed 24 bit int
    -- -8388607 to 8388608
    function stringStream:writeInt24(num)
        if num < 0 then num = num + 16777216 end
        self:write(string_char(num%0x100, bit_rshift(num, 8)%0x100, bit_rshift(num, 16)%0x100))
    end
    
    -- Reads an unsigned 24 bit int
    -- 0 to 16777215
    function stringStream:readUInt24()
        local a, b, c = string_byte(self:read(3), 1, 3)
        return (a or 0) + (b or 0)*0x100 + (c or 0)*0x10000
    end

    -- Reads a signed 24 bit int
    -- -8388607 to 8388608
    function stringStream:readInt24()
        local a, b, c = string_byte(self:read(3), 1, 3)
        a = (a or 0) + (b or 0)*0x100 + (c or 0)*0x10000
        if a > 8388608 then return a - 16777216 end
        return a
    end
    
    function stringStream:writeVector(v)
        self:writeDouble(v[1])
        self:writeDouble(v[2])
        self:writeDouble(v[3])
    end
    
    function stringStream:readVector()
        return Vector(self:readDouble(), self:readDouble(), self:readDouble())
    end
    
    function stringStream:writeAngle(ang)
        self:writeDouble(ang[1])
        self:writeDouble(ang[2])
        self:writeDouble(ang[3])
    end
    
    function stringStream:readAngle()
        return Angle(self:readDouble(), self:readDouble(), self:readDouble())
    end
    
    function stringStream:writeColor(c, hasAlpha)
        -- hasAlpha defaults to true
        self:writeInt8(c[1])
        self:writeInt8(c[2])
        self:writeInt8(c[3])
        if hasAlpha == nil or hasAlpha then
            self:writeInt8(c[4])
        end
    end
    
    function stringStream:readColor(c, hasAlpha)
        -- hasAlpha defaults to true
        return Color(
            self:readUInt8(),
            self:readUInt8(),
            self:readUInt8(), 
            (hasAlpha == nil or hasAlpha) and self:readUInt8() or nil)
    end
    
    function stringStream:writeEntity(ent)
        self:writeInt16(ent:entIndex())
    end
    
    function stringStream:readEntity()
        return entity(self:readUInt16())
    end
    
    function stringStream:writeHologram(ent)
        self:writeInt16(ent:entIndex())
    end
    
    function stringStream:readHologram()
        return entity(self:readUInt16()):toHologram()
    end
    
    function stringStream:writePlayer(ply)
        self:writeString(ply:getSteamID())
    end
    
    function stringStream:readPlayer()
        local id = self:readString()
        return find.allPlayers(function(ply)
            return ply:getSteamID() == id
        end)[1]
    end
    
    -- Writes a quaternion
    function stringStream:writeQuat(quat)
        self:writeDouble(quat[1])
        self:writeDouble(quat[2])
        self:writeDouble(quat[3])
        self:writeDouble(quat[4])
    end

    -- Reads a quaternion
    function stringStream:readQuat()
        return Quaternion(self:readDouble(), self:readDouble(), self:readDouble(), self:readDouble())
    end

    -- Writes a VMatrix
    function stringStream:writeMatrix(matrix)
        for row = 1, 4 do
            for col = 1, 4 do
                self:writeDouble(matrix:getField(row, col))
            end
        end
    end

    -- Reads a VMatrix
    function stringStream:readMatrix()
        local matrix = {}
        for row = 1, 4 do
            local rowt = {}
            for col = 1, 4 do
                table.insert(rowt, self:readDouble())
            end
            table.insert(matrix, rowt)
        end
        return Matrix(matrix)
    end

    -- Writes an object
    -- If called with just an object it will try to isntantly write
    -- Else it will use a coroutine and a callback
    -- maxQuota can be nil and will default to math.min(quotaMax() * 0.75, 0.004)
    function stringStream:writeType(obj, cb, maxQuota)
        if cb then
            maxQuota = maxQuota or math.min(quotaMax() * 0.75, 0.004)
            local running = false
            local encode2 = coroutine.wrap(function()
                encodeCoroutine(obj, self, maxQuota)
                cb()
                return true
            end)
            running = true
            if encode2() ~= true then
                local name = "encode " .. math.rand(0,1)
                running = false
                hook.add("think", name, function()
                    if not running then
                        running = true
                        if encode2() == true then
                            hook.remove("think", name)
                        end
                        running = false
                    end
                end)
            end
        else
            encode(obj, self)
        end
    end

    -- Reads an object
    -- If called with no inputs it will try to isntantly read
    -- Else it will use a coroutine and a callback
    -- maxQuota can be nil and will default to math.min(quotaMax() * 0.75, 0.004)
    function stringStream:readType(cb, maxQuota)
        if cb then
            maxQuota = maxQuota or math.min(quotaMax() * 0.75, 0.004)
            local running = false
            local decode2 = coroutine.wrap(function()
                cb(decodeCoroutine(self, maxQuota))
                return true
            end)
            running = true
            if decode2() ~= true then
                local name = "decode " .. math.rand(0,1)
                running = false
                hook.add("think", name, function()
                    if not running then
                        running = true
                        if decode2() == true then
                            hook.remove("think", name)
                        end
                        running = false
                    end
                end)
            end
        else
            return decode(self)
        end
    end
    
    return stringStream
end

-- Creates and extends a StringStream
function safeNet.stringstream(stream, i, endian)
    return safeNet.extend(bit.stringstream(stream, i, endian))
end
-- Here for typos :) use the function above
safeNet.stringStream = safeNet.stringstream

-- Writes a StringStream
function safeNet.writeStringStream(stream)
    curSend:writeData(stream:getString())
end

-- Elseifs have been found faster in general than a lookup table seemingly only when mapping to functions
encode = function(obj, stream)
    local type = type(obj)
    if type == "table" then
        stream:write("T")
        local seq = table.isSequential(obj)
        stream:write(seq and "1" or "0")
        if seq then
            stream:writeInt32(#obj)
            for _, var in ipairs(obj) do encode(var, stream) end
        else
            stream:writeInt32(#table.getKeys(obj))
            for key, var in pairs(obj) do
                stream:writeString(tostring(key))
                encode(var, stream)
            end
        end
    elseif type == "number" then
        if obj <= 2147483648 and obj % 1 == 0 then
            stream:write("I")
            stream:writeInt32(obj)
        else
            stream:write("D")
            stream:writeDouble(obj)
        end
    elseif type == "string" then
        stream:write("S")
        stream:writeData2(obj)
    elseif type == "boolean" then
        stream:write("B")
        stream:write(obj and "1" or "0")
    elseif type == "Vector" then
        stream:write("V")
        stream:writeVector(obj)
    elseif type == "Angle" then
        stream:write("A")
        stream:writeDouble(obj[1])
        stream:writeDouble(obj[2])
        stream:writeDouble(obj[3])
    elseif type == "Color" then
        stream:write("C")
        stream:writeInt8(obj[1])
        stream:writeInt8(obj[2])
        stream:writeInt8(obj[3])
        stream:writeInt8(obj[4])
    elseif type == "Entity" then
        stream:write("E")
        stream:writeInt16(obj:entIndex())
    elseif type == "Hologram" then
        stream:write("H")
        stream:writeInt16(obj:entIndex())
    elseif type == "Player" then
        stream:write("P")
        stream:writeString(obj:getSteamID())
    elseif type == "Quaternion" then
        stream:write("Q")
        stream:writeDouble(obj[1])
        stream:writeDouble(obj[2])
        stream:writeDouble(obj[3])
        stream:writeDouble(obj[4])
    elseif type == "VMatrix" then
        stream:write("M")
        for row = 1, 4 do
            for col = 1, 4 do
                stream:writeDouble(matrix:getField(row, col))
            end
        end
    elseif type == "nil" then
        stream:write("N")
    else
        stream:write("0")
    end
end

-- Elseifs have been found faster in general than a lookup table seemingly only when mapping to functions
decode = function(stream)
    local type = stream:read(1)
    if type == "T" then
        local seq = stream:read(1) ~= "0"
        local count = stream:readUInt32()
        local t = {}
        if seq then
            for i = 1, count do
                table_insert(t, decode(stream))
            end
        else
            for i = 1, count do
                t[stream:readString()] = decode(stream)
            end
        end
        return t
    elseif type == "I" then return stream:readInt32()
    elseif type == "D" then return stream:readDouble()
    elseif type == "S" then return stream:readData2()
    elseif type == "B" then return stream:read(1) ~= "0"
    elseif type == "V" then return Vector(stream:readDouble(), stream:readDouble(), stream:readDouble())
    elseif type == "A" then return Angle(stream:readDouble(), stream:readDouble(), stream:readDouble())
    elseif type == "C" then return Color(stream:readUInt8(), stream:readUInt8(), stream:readUInt8(), stream:readUInt8())
    elseif type == "E" then return entity(stream:readUInt16())
    elseif type == "H" then return entity(stream:readUInt16()):toHologram()
    elseif type == "P" then
        local id = stream:readString()
        return find.allPlayers(function(ply)
            return ply:getSteamID() == id
        end)[1]
    elseif type == "Q" then return Quaternion(stream:readDouble(), stream:readDouble(), stream:readDouble(), stream:readDouble())
    elseif type == "M" then
        local matrix = {}
        for row = 1, 4 do
            local rowt = {}
            for col = 1, 4 do
                table.insert(rowt, stream:readDouble())
            end
            table.insert(matrix, rowt)
        end
        return Matrix(matrix)
    elseif type == "nil" then
        return nil
    end
end

-- Elseifs have been found faster in general than a lookup table seemingly only when mapping to functions
-- Second function to avoid any excess cpu from non-coroutined version
encodeCoroutine = function(obj, stream, maxQuota)
    while quotaAverage() >= maxQuota do coroutine.yield() end
    local type = type(obj)
    if type == "table" then
        stream:write("T")
        local seq = table.isSequential(obj)
        stream:write(seq and "1" or "0")
        if seq then
            stream:writeInt32(#obj)
            for _, var in ipairs(obj) do encode(var, stream) end
        else
            stream:writeInt32(#table.getKeys(obj))
            for key, var in pairs(obj) do
                stream:writeString(tostring(key))
                encode(var, stream)
            end
        end
    elseif type == "number" then
        if obj <= 2147483648 and obj % 1 == 0 then
            stream:write("I")
            stream:writeInt32(obj)
        else
            stream:write("D")
            stream:writeDouble(obj)
        end
    elseif type == "string" then
        stream:write("S")
        stream:writeData2(obj)
    elseif type == "boolean" then
        stream:write("B")
        stream:write(obj and "1" or "0")
    elseif type == "Vector" then
        stream:write("V")
        stream:writeVector(obj)
    elseif type == "Angle" then
        stream:write("A")
        stream:writeDouble(obj[1])
        stream:writeDouble(obj[2])
        stream:writeDouble(obj[3])
    elseif type == "Color" then
        stream:write("C")
        stream:writeInt8(obj[1])
        stream:writeInt8(obj[2])
        stream:writeInt8(obj[3])
        stream:writeInt8(obj[4])
    elseif type == "Entity" then
        stream:write("E")
        stream:writeInt16(obj:entIndex())
    elseif type == "Hologram" then
        stream:write("H")
        stream:writeInt16(obj:entIndex())
    elseif type == "Player" then
        stream:write("P")
        stream:writeString(obj:getSteamID())
    elseif type == "Quaternion" then
        stream:write("Q")
        stream:writeDouble(obj[1])
        stream:writeDouble(obj[2])
        stream:writeDouble(obj[3])
        stream:writeDouble(obj[4])
    elseif type == "VMatrix" then
        stream:write("M")
        for row = 1, 4 do
            for col = 1, 4 do
                stream:writeDouble(matrix:getField(row, col))
            end
        end
    elseif type == "nil" then
        stream:write("N")
    else
        stream:write("0")
    end
end

-- Elseifs have been found faster in general than a lookup table seemingly only when mapping to functions
-- Second function to avoid any excess cpu from non-coroutined version
decodeCoroutine = function(stream, maxQuota)
    while quotaAverage() >= maxQuota do coroutine.yield() end
    local type = stream:read(1)
    if type == "T" then
        local seq = stream:read(1) ~= "0"
        local count = stream:readUInt32()
        local t = {}
        if seq then
            for i = 1, count do
                table_insert(t, decode(stream))
            end
        else
            for i = 1, count do
                t[stream:readString()] = decode(stream)
            end
        end
        return t
    elseif type == "I" then return stream:readInt32()
    elseif type == "D" then return stream:readDouble()
    elseif type == "S" then return stream:readData2()
    elseif type == "B" then return stream:read(1) ~= "0"
    elseif type == "V" then return Vector(stream:readDouble(), stream:readDouble(), stream:readDouble())
    elseif type == "A" then return Angle(stream:readDouble(), stream:readDouble(), stream:readDouble())
    elseif type == "C" then return Color(stream:readUInt8(), stream:readUInt8(), stream:readUInt8(), stream:readUInt8())
    elseif type == "E" then return entity(stream:readUInt16())
    elseif type == "H" then return entity(stream:readUInt16()):toHologram()
    elseif type == "P" then
        local id = stream:readString()
        return find.allPlayers(function(ply)
            return ply:getSteamID() == id
        end)[1]
    elseif type == "Q" then return Quaternion(stream:readDouble(), stream:readDouble(), stream:readDouble(), stream:readDouble())
    elseif type == "M" then
        local matrix = {}
        for row = 1, 4 do
            local rowt = {}
            for col = 1, 4 do
                table.insert(rowt, stream:readDouble())
            end
            table.insert(matrix, rowt)
        end
        return Matrix(matrix)
    elseif type == "N" then
        return nil
    end
end

----------------------------------------

--{name, data, length, unreliable, targets}

local function refillPlayerQueue(isCancel)
    if SERVER then
        if sends[1][5] then
            local queue
            if isCancel then
                playerCancelQueue = {}
                queue = playerCancelQueue
            else
                playerQueue = {}
                queue = playerQueue
            end
            for _, ply in ipairs(sends[1][5]) do
                if ply and ply:isValid() and ply:isPlayer() then
                    table.insert(queue, ply)
                end
            end
        elseif isCancel then playerCancelQueue = nil
        else playerQueue = nil end
    end
end

local bytesLeft = 0
local netTime

local function cancelStream()
    local stream = sends[1]
    if not stream then
        cancelQueue = false
        return
    end
    if not canceling then
        canceling = true
        refillPlayerQueue(true)
    end
    local name = stream[1]
    local maxSize = math.min(bytesLeft - #name, net.getBytesLeft() - #name - 15)
    if maxSize <= 0 then return end
    bytesLeft = bytesLeft - #name
    local plys = stream[5]
    if SERVER and plys then
        local ply = plys[#plys]
        if ply and ply:isValid() and ply:isPlayer() then
            net.start(name)
            net.writeBool(true)
            net.send(ply, stream[4])
        end
        table.remove(plys)
        if #plys == 0 then
            table.remove(sends, 1)
            canceling = false
        end
    else
        net.start(name)
        net.writeBool(true)
        net.send(nil, stream[4])
        table.remove(sends, 1)
        canceling = false
    end
    cancelQueue = false
end

local function network()
    if cancelQueue then
        cancelStream()
        if cancelQueue then return end
    end
    local stream = sends[1]
    while stream do
        local first = not stream[8]
        if not streaming then
            streaming = true
            refillPlayerQueue(false)
        end
        local size = stream[3]
        local name = stream[1]
        local maxSize = math.min(bytesLeft - #name, net.getBytesLeft() - #name - 15)
        if maxSize <= 0 then return end
        if size <= maxSize then
            --Last partition
            bytesLeft = bytesLeft - size - #name
            local plys = stream[5]
            if SERVER and plys then
                local ply = plys[#plys]
                if ply and ply:isValid() and ply:isPlayer() then
                    net.start(name)
                    net.writeBool(first) -- First
                    net.writeBool(false) -- Cancel
                    net.writeBool(true) -- Last
                    net.writeUInt(size, 32)
                    net.writeData(stream[2], size)
                    net.send(ply, stream[4])
                    stream[8] = true
                end
                table.remove(plys)
                if #plys == 0 then
                    table.remove(sends, 1)
                    streaming = false
                end
            else
                net.start(name)
                net.writeBool(first)
                net.writeBool(false)
                net.writeBool(true)
                net.writeUInt(size, 32)
                net.writeData(stream[2], size)
                net.send(nil, stream[4])
                stream[8] = true
                table.remove(sends, 1)
                streaming = false
            end
        else
            --Not last partition
            bytesLeft = bytesLeft - maxSize - #name
            if playerQueue then
                local ply = playerQueue[#playerQueue]
                if ply and ply:isValid() and ply:isPlayer() then
                    net.start(name)
                    net.writeBool(first)
                    net.writeBool(false)
                    net.writeBool(false)
                    net.writeUInt(maxSize, 32)
                    net.writeData(string.sub(stream[2], 1, maxSize), maxSize)
                    net.send(ply, stream[4])
                    stream[8] = true
                end
                table.remove(playerQueue)
                if #playerQueue == 0 then
                    refillPlayerQueue(false)
                    stream[2] = string.sub(stream[2], maxSize+1)
                    stream[3] = stream[3] - maxSize
                end
            else
                net.start(name)
                net.writeBool(first)
                net.writeBool(false)
                net.writeBool(false)
                net.writeUInt(maxSize, 32)
                net.writeData(string.sub(stream[2], 1, maxSize), maxSize)
                net.send(nil, stream[4])
                stream[2] = string.sub(stream[2], maxSize+1)
                stream[3] = stream[3] - maxSize
                stream[8] = true
            end
            stream[7] = true
            return
        end
        stream = sends[1]
    end
end

hook.add("think", "SafeNet", function()
    local time = timer.systime()
    if netTime then
        bytesLeft = math.round((time - netTime) * BPS)
    end
    netTime = time
    network()
end)

function safeNet.receive(name, cb, prefix)
    prefix = prefix or "snstream"
    local name2 = prefix .. name
    if cb then
        local data = ""
        local size = 0
        local receiving = false
        net.receive(name2, function(_, ply)
            local timeout2
            if ply then timeout2 = math.max(ply:getPing() / 500, timeout)
            else timeout2 = timeout end
            if timer.exists("sn stream timeout " .. name2) then
                timer.adjust("sn stream timeout " .. name2, timeout2)
            else
                timer.create("sn stream timeout " .. name2, timeout2, 1, function()
                    data = ""
                    size = 0
                end)
            end
            local first = net.readBool()
            if first then receiving = true end
            local cancel = net.readBool()
            if cancel then
                data = ""
                size = 0
                timer.remove("sn stream timeout " .. name2)
                return
            end
            local last = net.readBool()
            if receiving then
                local length = net.readUInt(32)
                size = size + length
                data = data .. net.readData(length)
                if last then
                    timer.remove("sn stream timeout " .. name2)
                    curReceive = safeNet.stringstream(data)
                    cb(size, ply)
                    data = ""
                    size = 0
                end
            end
            if last then receiving = false end
        end)
    else
        net.receive(name2)
    end
end

local netID = 1

function safeNet.send(targets, unreliable)
    local name = curPrefix .. curSendName
    local targets2
    if SERVER and targets ~= nil then
        if type(targets) == "Player" then targets2 = {targets}
        elseif type(targets) == "table" then targets2 = targets
        else error("Targets parameter is not nil/Player/Player list") end
    end
    table.insert(sends, {name, curSend:getString(), curSend:size(), unreliable, targets2, netID})
    curSend = nil
    network()
    netID = netID + 1
    return netID - 1
end

-- Cancels a specific stream
-- Returns true if cancelled and false if not
function safeNet.cancel(ID)
    for i, send in ipairs(sends) do
        if send[6] == ID then
            if send[7] then
                -- Cancel this (this should only happen for the first element)
                cancelQueue = true
                cancelStream()
            else table.remove(sends, i) end
            return true
        end
    end
    return false
end

function safeNet.cancelAll()
    if sends[7] then
        cancelQueue = true
        local remove = table.remove
        for i = 1, #sends-1 do
            remove(sends)
        end
    else sends = {} end
end

function safeNet.isSending()
    return sends[1] ~= nil
end

------------------------------------------------------------------

-- Initialization utilities
-- Useful for e.g. clients ping the server when are initialized or after doing something and the server responds immediately or after doing something itself
-- e.g. Clients ping the server and the server responds with a table of entities that it may or may not be able to spawn all at once
-- SERVER
--  safeNet.init(callback)
--      Retroactively responds to all queued pings from clients and will immediately respond to future pings
--      If a callback is provided, the arguments passed into it will be cb(ply, args ...)
--      and it will respond to the client and send back whatever is returned by the callback (can be vararg or not return anything)
-- CLIENT
--  safeNet.init(callback, args ...)
--      Pings the server with the varargs provided by args (they are optional)
--      If a callback is provided and is not nil, it will be called with cb(args ...) which will be the arguments returned from the server
if SERVER then
    local plyQueue = {}
    safeNet.receive("sninit", function(_, ply)
        table.insert(plyQueue, {ply, {safeNet.readType()}})
    end, "")
    
    local function respond(ply, ...)
        safeNet.start("sninit", "")
        safeNet.writeType(...)
        safeNet.send(ply)
    end
    
    function safeNet.init(callback)
        for _, plySet in pairs(plyQueue) do
            local ply = plySet[1]
            if ply and ply:isValid() and ply:isPlayer() then
                if callback then
                    respond(ply, callback(ply, unpack(plySet[2])))
                else
                    respond(ply)
                end
            end
        end
        
        safeNet.receive("sninit", function(_, ply)
            if ply and ply:isValid() and ply:isPlayer() then -- Chance that the client disconnected between sending the ping and the server receiving it
                if callback then
                    respond(ply, callback(ply, safeNet.readType()))
                else
                    respond(ply)
                end
            end
        end, "")
        
        plyQueue = nil
    end
else -- CLIENT
    -- Callback, args to send to server
    function safeNet.init(callback, ...)
        if callback then
            safeNet.receive("sninit", function()
                callback(safeNet.readType())
            end, "")
        end
        
        safeNet.start("sninit", "")
        safeNet.writeType(...)
        safeNet.send()
    end
end
