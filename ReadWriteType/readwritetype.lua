--@name TypeReadWrite
--@author Jacbo
--@client

if CLIENT then
    local string_char = string.char
    local file_append = file.append
    local string_sub = string.sub
    local bit_band = bit.band
    local string_byte = string.byte
    local bit_rshift = bit.rshift
    local bit_lshift = bit.lshift
    local math_huge = math.huge
    local math_frexp = math.frexp
    local math_ldexp = math.ldexp
    local math_floor = math.floor
    local table_insert = table.insert
    
    FileReader = setmetatable({}, {__call = function(t, ...) return t.create(...) end})
    FileReader.__index = FileReader
    
    FileWriter = setmetatable({}, {__call = function(t, ...) return t.create(...) end})
    FileWriter.__index = FileWriter
    
    -- Create a FileReader
    function FileReader.create(path)
        local data = file.read(path)
        -- {buffer, bufferPos, bufferSize}
        local reader = {data, 1, #data}
        setmetatable(reader, FileReader)
        return reader
    end
    
    function FileWriter.create(path, bufferSize)
        -- {path, buffer, bufferMaxSize}
        local writer = {path, "", bufferSize or 1024}
        setmetatable(writer, FileWriter)
        return writer
    end
    
    -- Writes and clears the buffer
    function FileWriter:writeBuffer()
        file_append(self[1], self[2])
        self[2] = ""
    end
    
    -- Returns the file text
    function FileReader:getBuffer()
        return self[1]
    end
    
    -- Get the position of the buffer reader
    function FileReader:getBufferPos()
        return self[2]
    end
    
    -- Get the size of the buffer
    function FileReader:getBufferSize()
        return self[3]
    end
    
    -- Set the position of the buffer reader
    function FileReader:setBufferPos(pos)
        self[2] = pos
    end
    
    -- Skip x amount of bytes for reading (shift the reader position)
    function FileReader:skip(bytes)
        self[2] = self[2] + bytes
    end
    
    -- Read x bytes
    function FileReader:read(bytes)
        local s = string_sub(self[1], self[2], self[2] + bytes - 1)
        self[2] = self[2] + bytes
        return s
    end
    
    -- Write string (so it can be read with FileReader)
    function FileWriter:writeString(str)
        local x = #str
        self[2] = self[2] .. string_char(x % 0x100, bit_rshift(x, 8) % 0x100, bit_rshift(x, 16) % 0x100, bit_rshift(x, 24) % 0x100) .. str
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read string
    function FileReader:readString(length)
        if length then
            local str = string_sub(self[1], self[2], self[2] + length - 1)
            self[2] = self[2] + length
            return str
        end
        local a, b, c, d = string_byte(self[1], self[2], self[2] + 3)
        length = d * 0x1000000 + c * 0x10000 + b * 0x100 + a
        local str = string_sub(self[1], self[2] + 4, self[2] + 3 + length)
        self[2] = self[2] + 4 + length
        return str
    end
    
    -- Append up to 4 booleans
    function FileWriter:writeBool(bool1, bool2, bool3, bool4)
        self[2] = self[2] .. string_char((bool1 and 1 or 0) + (bool2 and 2 or 0) + (bool3 and 4 or 0) + (bool4 and 8 or 0))
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read 4 booleans
    function FileReader:readBool()
        local char = string_sub(self[1], self[2], self[2])
        self[2] = self[2] + 1
        return bit_band(char, 1) == 1,
            bit_band(char, 2) == 2,
            bit_band(char, 4) == 4,
            bit_band(char, 8) == 8
    end
    
    -- Write an 8 bit int
    -- -127 to 128
    -- 0 to 255
    function FileWriter:writeInt8(x)
        if x < 0 then x = x + 0x100 end
        self[2] = self[2] .. string_char(x)
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read an 8 bit int
    -- -127 to 128
    function FileReader:readInt8()
        local x = string_byte(self[1], self[2], self[2])
        self[2] = self[2] + 1
        if x >= 0x80 then return x - 0x100 end
        return x
    end
    
    -- Read an unsigned 8 bit int
    -- 0 to 255
    function FileReader:readUInt8()
        local x = string_byte(self[1], self[2], self[2])
        self[2] = self[2] + 1
        return x
    end
    
    -- Write a 16 bit int
    -- -32767 to 32768
    -- 0 to 65535
    function FileWriter:writeInt16(x)
        if x < 0 then x = x + 0x10000 end
        self[2] = self[2] .. string_char(x % 0x100, bit_rshift(x, 8) % 0x100)
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read a 16 bit int
    -- -32767 to 32768
    function FileReader:readInt16()
        local a, b = string_byte(self[1], self[2], self[2] + 1)
        self[2] = self[2] + 2
        local x = b * 0x100 + a
        if x >= 0x8000 then return x - 0x10000 end
        return x
    end
    
    -- Read an unsigned 16 bit int
    -- 0 to 65535
    function FileReader:readUInt16()
        local a, b = string_byte(self[1], self[2], self[2] + 1)
        self[2] = self[2] + 2
        return b * 0x100 + a
    end
    
    -- Write a 24 bit int
    -- -8388607 to 8388608
    -- 0 to 16777215
    function FileWriter:writeInt24(x)
        if x < 0 then x = x + 0x1000000 end
        self[2] = self[2] .. string_char(x % 0x100, bit_rshift(x, 8) % 0x100, bit_rshift(x, 16) % 0x100)
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read a 24 bit int
    -- -8388607 to 8388608
    function FileReader:readInt24()
        local a, b, c = string_byte(self[1], self[2], self[2] + 2)
        self[2] = self[2] + 3
        local x = c * 0x10000 + b * 0x100 + a
        if x >= 0x800000 then return x - 0x1000000 end
        return x
    end
    
    -- Read an unsigned 24 bit int
    -- 0 to 16777215
    function FileReader:readUInt24()
        local a, b, c = string_byte(self[1], self[2], self[2] + 2)
        self[2] = self[2] + 3
        return c * 0x10000 + b * 0x100 + a
    end
    
    -- Write a 32 bit int
    -- -2147483647 to 2147483648
    -- 0 to 4294967295
    function FileWriter:writeInt32(x)
        if x < 0 then x = x + 0x100000000 end
        self[2] = self[2] .. string_char(x % 0x100, bit_rshift(x, 8) % 0x100, bit_rshift(x, 16) % 0x100, bit_rshift(x, 24) % 0x100)
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read a 32 bit int
    -- -2147483647 to 2147483648
    function FileReader:readInt32()
        local a, b, c, d = string_byte(self[1], self[2], self[2] + 3)
        self[2] = self[2] + 4
        local x = d * 0x1000000 + c * 0x10000 + b * 0x100 + a
        if x >= 0x80000000 then return x - 0x100000000 end
        return x
    end
    
    -- Read an unsigned 32 bit int
    -- 0 to 4294967295
    function FileReader:readUInt32()
        local a, b, c, d = string_byte(self[1], self[2], self[2] + 3)
        self[2] = self[2] + 4
        return d * 0x1000000 + c * 0x10000 + b * 0x100 + a
    end
    
    -- Write a color
    function FileWriter:writeColor(color)
        self[2] = self[2] .. string_char(color[1], color[2], color[3], color[4])
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read a color
    function FileReader:readColor()
        local r, g, b, a = string_byte(self[1], self[2], self[2] + 3)
        self[2] = self[2] + 4
        return Color(r, g, b, a)
    end
    
    local function packFloat(number)
        if number == 0 then
            return string_char(0x00, 0x00, 0x00, 0x00)
        elseif number == math_huge then
            return string_char(0x00, 0x00, 0x80, 0x7F)
        elseif number == -math_huge then
            return string_char(0x00, 0x00, 0x80, 0xFF)
        elseif number ~= number then
            return string_char(0x00, 0x00, 0xC0, 0xFF)
        else
            local sign = 0x00
            if number < 0 then
                sign = 0x80
                number = -number
            end
            local mantissa, exponent = math_frexp(number)
            exponent = exponent + 0x7F
            if exponent <= 0 then
                mantissa = math_ldexp(mantissa, exponent - 1)
                exponent = 0
            elseif exponent > 0 then
                if exponent >= 0xFF then
                    return string_char(0x00, 0x00, 0x80, sign + 0x7F)
                elseif exponent == 1 then
                    exponent = 0
                else
                    mantissa = mantissa * 2 - 1
                    exponent = exponent - 1
                end
            end
            mantissa = math_floor(math_ldexp(mantissa, 23) + 0.5)
            return string_char(mantissa % 0x100,
                bit_rshift(mantissa, 8) % 0x100,
                (exponent % 2) * 0x80 + bit_rshift(mantissa, 16),
                sign + bit_rshift(exponent, 1))
        end
    end
    
    -- Write a float
    function FileWriter:writeFloat(number)
        self[2] = self[2] .. packFloat(number)
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read a float
    function FileReader:readFloat()
        local b4, b3, b2, b1 = string_byte(self[1], self[2], self[2] + 3)
        self[2] = self[2] + 4
        local exponent = (b1 % 0x80) * 0x02 + bit_rshift(b2, 7)
        local mantissa = math_ldexp(((b2 % 0x80) * 0x100 + b3) * 0x100 + b4, -23)
        if exponent == 0xFF then
            if mantissa > 0 then
                return 0 / 0
            else
                if b1 >= 0x80 then
                    return -math_huge
                else
                    return math_huge
                end
            end
        elseif exponent > 0 then
            mantissa = mantissa + 1
        else
            exponent = exponent + 1
        end
        if b1 >= 0x80 then
            mantissa = -mantissa
        end
        return math_ldexp(mantissa, exponent - 0x7F)
    end
    
    local function packDouble(number)
        if number == 0 then
            return string_char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
        elseif number == math_huge then
            return string_char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x7F)
        elseif number == -math_huge then
            return string_char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0xFF)
        elseif number ~= number then
            return string_char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF8, 0xFF)
        else
            local sign = 0x00
            if number < 0 then
                sign = 0x80
                number = -number
            end
            local mantissa, exponent = math_frexp(number)
            exponent = exponent + 0x3FF
            if exponent <= 0 then
                mantissa = math_ldexp(mantissa, exponent - 1)
                exponent = 0
            elseif exponent > 0 then
                if exponent >= 0x7FF then
                    return string_char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, sign + 0x7F)
                elseif exponent == 1 then
                    exponent = 0
                else
                    mantissa = mantissa * 2 - 1
                    exponent = exponent - 1
                end
            end
            mantissa = math_floor(math_ldexp(mantissa, 52) + 0.5)
            return string_char(mantissa % 0x100,
                math_floor(mantissa / 0x100) % 0x100,  --can only rshift up to 32 bit numbers. mantissa is too big
                math_floor(mantissa / 0x10000) % 0x100,
                math_floor(mantissa / 0x1000000) % 0x100,
                math_floor(mantissa / 0x100000000) % 0x100,
                math_floor(mantissa / 0x10000000000) % 0x100,
                (exponent % 0x10) * 0x10 + math_floor(mantissa / 0x1000000000000),
                sign + bit_rshift(exponent, 4))
        end
    end
    
    -- Write a double
    function FileWriter:writeDouble(number)
        self[2] = self[2] .. packDouble(number)
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read a double
    function FileReader:readDouble()
        local b8, b7, b6, b5, b4, b3, b2, b1 = string_byte(self[1], self[2], self[2] + 7)
        self[2] = self[2] + 8
        local exponent = (b1 % 0x80) * 0x10 + bit_rshift(b2, 4)
        local mantissa = math_ldexp(((((((b2 % 0x10) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8, -52)
        if exponent == 0x7FF then
            if mantissa > 0 then
                return 0 / 0
            else
                if b1 >= 0x80 then
                    return -math_huge
                else
                    return math_huge
                end
            end
        elseif exponent > 0 then
            mantissa = mantissa + 1
        else
            exponent = exponent + 1
        end
        if b1 >= 0x80 then
            mantissa = -mantissa
        end
        return math_ldexp(mantissa, exponent - 0x3FF)
    end
    
    -- Write a vector
    function FileWriter:writeVector(vec)
        self[2] = self[2] .. packDouble(vec[1]) .. packDouble(vec[2]) .. packDouble(vec[3])
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read a vector
    function FileReader:readVector()
        return Vector(self:readDouble(), self:readDouble(), self:readDouble())
    end
    
    -- Write an angle
    function FileWriter:writeAngle(ang)
        self[2] = self[2] .. packDouble(ang[1]) .. packDouble(ang[2]) .. packDouble(ang[3])
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read an angle
    function FileReader:readAngle()
        return Angle(self:readDouble(), self:readDouble(), self:readDouble())
    end
    
    -- Write a quaternion
    function FileWriter:writeQuaternion(quat)
        self[2] = self[2] .. packDouble(quat[1]) .. packDouble(quat[2]) .. packDouble(quat[3]) .. packDouble(quat[4])
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read a quaternion
    function FileReader:readQuaternion()
        return Quaternion(self:readDouble(), self:readDouble(), self:readDouble(), self:readDouble())
    end
    
    -- Write a matrix
    function FileWriter:writeMatrix(matrix)
        for row = 1, 4 do
            for col = 1, 4 do
                self[2] = self[2] .. packDouble(matrix:getField(row, col))
            end
        end
        
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Read a matrix
    function FileReader:readMatrix()
        local matrix = {}
        for row = 1, 4 do
            local rowt = {}
            for col = 1, 4 do
                table_insert(rowt, self:readDouble())
            end
            table_insert(matrix, rowt)
        end
        return Matrix(matrix)
    end
    
    -- Write a type
    -- ifelse found to be generally faster here than lookup table
    function FileWriter:writeType(obj, maxQuota)
        while maxQuota and quotaAverage() >= maxQuota do
            coroutine.yield()
        end
        local type = type(obj)
        if type == "table" then
            local seq = table.isSequential(obj)
            self[2] = self[2] .. "T" .. (seq and "1" or "0")
            if seq then
                self:writeInt32(#obj)
                for _, var in ipairs(obj) do
                    self:writeType(var, maxQuota)
                end
            else
                self:writeInt32(#table.getKeys(obj))
                for key, var in pairs(obj) do
                    self:writeType(key, maxQuota)
                    self:writeType(var, maxQuota)
                end
            end
        elseif type == "number" then
            if obj <= 2147483648 and obj % 1 == 0 then
                self[2] = self[2] .. "I"
                self:writeInt32(obj)
            else
                self[2] = self[2] .. "D" .. packDouble(obj)
            end
        elseif type == "string" then
            self[2] = self[2] .. "S"
            self:writeString(obj)
        elseif type == "boolean" then
            self[2] = self[2] .. "B" .. (obj and "1" or "0")
        elseif type == "Vector" then
            self[2] = self[2] .. "V" .. packDouble(obj[1]) .. packDouble(obj[2]) .. packDouble(obj[3])
        elseif type == "Angle" then
            self[2] = self[2] .. "A" .. packDouble(obj[1]) .. packDouble(obj[2]) .. packDouble(obj[3])
        elseif type == "Color" then
            self[2] = self[2] .. "C" .. string_char(obj[1], obj[2], obj[3], obj[4])
        elseif type == "Quaternion" then
            self[2] = self[2] .. "Q" .. packDouble(obj[1]) .. packDouble(obj[2]) .. packDouble(obj[3]) .. packDouble(obj[4])
        elseif type == "VMatrix" then
            self[2] = self[2] .. "M"
            for row = 1, 4 do
                for col = 1, 4 do
                    self[2] = self[2] .. packDouble(obj:getField(row, col))
                end
            end
        elseif type == "nil" then
            self[2] = self[2] .. "N"
        end
        
        if #self[2] >= self[3] then
            file_append(self[1], self[2])
            self[2] = ""
        end
    end
    
    -- Write multiple
    function FileWriter:writeMulti(maxQuota, ...)
        local count = select("#", ...)
        self[2] = self[2] .. string_char(count)
        local args = {...}
        for i = 1, count do
            self:writeType(args[i], maxQuota)
        end
    end
    
    -- Write a table
    FileWriter.writeTable = FileWriter.writeType
    
    -- Write multi asynchronously
    function FileWriter:writeMultiAsync(maxQuota, cb, ...)
        maxQuota = maxQuota or math.min(quotaMax() * 0.75, 0.004)
        local count = select("#", ...)
        self[2] = self[2] .. string_char(count)
        local args = {...}
        
        local writer = self
        
        local writeType2 = coroutine.wrap(function()
            for i = 1, count do
                writer:writeType(args[i], maxQuota)
            end
            cb()
            return true
        end)
        
        if writeType2() ~= true then
            local running = false
            local name = "read " .. math.rand(0,1)
            hook.add("think", name, function()
                if not running then
                    running = true
                    if writeType2() == true then
                        hook.remove("think", name)
                    end
                    running = false
                end
            end)
        end
    end
    
    -- Write a table asynchronously
    function FileWriter:writeTableAsync(maxQuota, cb, tbl)
        maxQuota = maxQuota or math.min(quotaMax() * 0.75, 0.004)
        local writer = self
        
        local writeType2 = coroutine.wrap(function()
            writer:writeType(tbl, maxQuota)
            cb()
            return true
        end)
        
        if writeType2() ~= true then
            local running = false
            local name = "read " .. math.rand(0,1)
            hook.add("think", name, function()
                if not running then
                    running = true
                    if writeType2() == true then
                        hook.remove("think", name)
                    end
                    running = false
                end
            end)
        end
    end
    
    -- elseif found to be generally faster here than a lookup table
    function FileReader:readType(maxQuota)
        while maxQuota and quotaAverage() >= maxQuota do
            coroutine.yield()
        end
        local type = self:read(1)
        if type == "T" then
            local seq = self:read(1) ~= "0"
            local count = self:readUInt32()
            local t = {}
            if seq then
                for i = 1, count do
                    table_insert(t, self:readType(maxQuota))
                end
            else
                for i = 1, count do
                    t[self:readType(maxQuota)] = self:readType(maxQuota)
                end
            end
            return t
        elseif type == "I" then return self:readInt32()
        elseif type == "D" then return self:readDouble()
        elseif type == "S" then return self:readString()
        elseif type == "B" then return self:read(1) ~= "0"
        elseif type == "V" then return self:readVector()
        elseif type == "A" then return self:readAngle()
        elseif type == "C" then return self:readColor()
        elseif type == "Q" then return self:readQuaternion()
        elseif type == "M" then return self:readMatrix()
        elseif type == "N" then return nil end
    end
    
    -- Read multi
    function FileReader:readMulti(maxQuota)
        local count = self:readUInt8()
        if count > 0 then
            local i = 0
            local recurse
            
            local reader = self
            
            recurse = function()
                i = i + 1
                if i <= count then
                    return reader:readType(maxQuota), recurse()
                end
            end
            return recurse()
        end
    end
    
    -- Read a table
    FileReader.readTable = FileReader.readType
    
    -- Read multi asynchronously
    function FileReader:readMultiAsync(maxQuota, cb)
        maxQuota = maxQuota or math.min(quotaMax() * 0.75, 0.004)
        local count = self:readUInt8()
        local fr = self
        
        local readType2 = coroutine.wrap(function()
            if count > 0 then
                local i = 0
                local recurse
                recurse = function()
                    i = i + 1
                    if i <= count then
                        return fr:readType(maxQuota), recurse()
                    end
                end
                cb(recurse())
                return true
            end
            cb()
            return true
        end)
        if readType2() ~= true then
            local running = false
            local name = "read " .. math.rand(0,1)
            hook.add("think", name, function()
                if not running then
                    running = true
                    if readType2() == true then
                        hook.remove("think", name)
                    end
                    running = false
                end
            end)
        end
    end
    
    -- Read a table asynchronously
    function FileReader:readTableAsync(maxQuota, cb)
        maxQuota = maxQuota or math.min(quotaMax() * 0.75, 0.004)
        local fr = self
        
        local readType2 = coroutine.wrap(function()
            cb(fr:readType(maxQuota))
            return true
        end)
        
        if readType2() ~= true then
            local running = false
            local name = "read " .. math.rand(0,1)
            hook.add("think", name, function()
                if not running then
                    running = true
                    if readType2() == true then
                        hook.remove("think", name)
                    end
                    running = false
                end
            end)
        end
    end
end
