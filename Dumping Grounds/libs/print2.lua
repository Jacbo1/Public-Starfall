--@name print2
--@author Jacbo

local format
format = function(x)
    local typ = type(x)
    if typ == "table" then
        local s = "{"
        local first = true
        if table.isSequential(x) then
            for _, v in ipairs(x) do
                if first then
                    first = false
                    s = s .. format(v)
                else
                    s = s .. ", " .. format(v)
                end
            end
        else
            for k, v in pairs(x) do
                if first then
                    first = false
                    if type(k) == "string" then
                        s = s .. k .. " = " .. format(v)
                    else
                        s = s .. "[" .. format(k) .. "] = " .. format(v)
                    end
                else
                    if type(k) == "string" then
                        s = s .. ", " .. k .. " = " .. format(v)
                    else
                        s = s .. ", [" .. format(k) .. "] = " .. format(v)
                    end
                end
            end
        end
        return s .. "}"
    elseif typ == "string" then
        return x
    elseif typ == "nil" then
        return "nil"
    elseif typ == "Vector" then
        return "Vector(" .. x[1] .. ", " .. x[2] .. ", " .. x[3] .. ")"
    elseif typ == "Angle" then
        return "Angle(" .. x[1] .. ", " .. x[2] .. ", " .. x[3] .. ")"
    elseif typ == "Color" then
        return "Color(" .. x[1] .. ", " .. x[2] .. ", " .. x[3] .. ", " .. x[4] .. ")"
    elseif typ == "Quaternion" then
        return "Quaternion(" .. x[1] .. ", " .. x[2] .. ", " .. x[3] .. ", " .. x[4] .. ")"
    elseif x == true then
        return "true"
    elseif x == false then
        return "false"
    elseif typ == "VMatrix" then
        local s = "Matrix({"
        for row = 1, 4 do
            if row == 1 then
                s = s .. "{"
            else
                s = s .. ", {"
            end
            for col = 1, 4 do
                if col == 1 then
                    s = s .. x:getField(row, col)
                else
                    s = s .. ", " .. x:getField(row, col)
                end
            end
            s = s .. "}"
        end
        return s .. "})"
    end
    return tostring(x)
end

local tabTable
tabTable = function(x, tabs)
    local typ = type(x)
    if typ == "table" then
        local s = "{"
        if table.isSequential(x) then
            for k, v in ipairs(x) do
                s = s .. "\n" .. string.rep(". ", tabs) .. k .. ": " .. tabTable(v, tabs + 1)
            end
        else
            for k, v in pairs(x) do
                if type(k) == "string" then
                    s = s .. "\n" .. string.rep(". ", tabs) .. k .. " = " .. tabTable(v, tabs + 1)
                else
                    s = s .. "\n" .. string.rep(". ", tabs) .. "[" .. tabTable(k, tabs + 1) .. "] = " .. tabTable(v, tabs + 1)
                end
            end
        end
        return s .. "\n" .. string.rep(". ", tabs - 1) .. "}"
    elseif typ == "string" then
        return x
    elseif typ == "nil" then
        return "nil"
    elseif typ == "Vector" then
        return "Vector(" .. x[1] .. ", " .. x[2] .. ", " .. x[3] .. ")"
    elseif typ == "Angle" then
        return "Angle(" .. x[1] .. ", " .. x[2] .. ", " .. x[3] .. ")"
    elseif typ == "Color" then
        return "Color(" .. x[1] .. ", " .. x[2] .. ", " .. x[3] .. ", " .. x[4] .. ")"
    elseif typ == "Quaternion" then
        return "Quaternion(" .. x[1] .. ", " .. x[2] .. ", " .. x[3] .. ", " .. x[4] .. ")"
    elseif x == true then
        return "true"
    elseif x == false then
        return "false"
    elseif typ == "VMatrix" then
        local s = "Matrix({"
        for row = 1, 4 do
            if row == 1 then
                s = s .. "{"
            else
                s = s .. ", {"
            end
            for col = 1, 4 do
                if col == 1 then
                    s = s .. x:getField(row, col)
                else
                    s = s .. ", " .. x:getField(row, col)
                end
            end
            s = s .. "}"
        end
        return s .. "})"
    end
    return tostring(x)
end

local oldPrint = print
function print2(...)
    local count = select("#", ...)
    local s = ""
    local args = {...}
    for i = 1, count do
        s = s .. format(args[i])
    end
    oldPrint(s)
end

function printTable2(...)
    local count = select("#", ...)
    local s = ""
    local args = {...}
    for i = 1, count do
        s = s .. tabTable(args[i], 1)
    end
    oldPrint(s)
end