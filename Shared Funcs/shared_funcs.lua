-- THIS IS NOT MEANT TO BE TAKEN SERIOUSLY NOR IS IT A GOOD WAY TO CODE
-- https://github.com/Jacbo1/Public-Starfall/tree/main/Shared%20Funcs

--@name Shared Funcs
--@author Jacbo
--@shared
-- SafeNet can be found at https://github.com/Jacbo1/Public-Starfall/tree/main/SafeNet
--@include safeNet.txt
-- Coroutine Wrapper can be found at https://github.com/Jacbo1/Public-Starfall/tree/main/Coroutine%20Wrapper
--@include cor_wrap.txt

require("safeNet.txt")
local oldNet = net
local net = safeNet
require("cor_wrap.txt")

local net_name = 1
local hook_name = 1

local function return2(name, ply, ...)
    net.start(name, "sf")
    net.writeType(...)
    net.send(ply)
end

-- baseFunc():method(args)
net.receive("1", function(_, ply)
    local methods = getMethods(net.readString())
    if methods then
        local method = methods[net.readString()]
        if method then
            method(net.readType())
        end
    end
end, "sf")

-- return baseFunc():method(args)
net.receive("2", function(_, ply)
    local name = net.readName()
    local methods = getMethods(net.readString())
    if methods then
        local method = methods[net.readString()]
        if method then
            return2(
                name,
                ply,
                method(net.readType())
            )
            return
        end
    end
    return2(name, ply)
end, "sf")

-- baseFunc()
net.receive("3", function(_, ply)
    local func = getfenv()[net.readString()]
    if func then func() end
end, "sf")

-- return baseFunc()
net.receive("4", function(_, ply)
    local name = net.readUInt32()
    local func = getfenv()[net.readString()]
    if func then
        return2(name, ply, func())
    else
        return2(name, ply)
    end
end, "sf")

-- baseFunc(args)
net.receive("5", function(_, ply)
    local s = net.readString()
    local func = getfenv()[s]
    if func then func(net.readType()) end
end, "sf")

-- return baseFunc(args)
net.receive("6", function(_, ply)
    local name = net.readUInt32()
    local func = getfenv()[net.readString()]
    if func then
        return2(name, ply, func(net.readType()))
    else
        return2(name, ply)
    end
end, "sf")

-- table.func()
net.receive("7", function(_, ply)
    local tbl = getfenv()[net.readString()]
    if tbl then
        local func = tbl[net.readString()]
        if func then func() end
    end
end, "sf")

-- return table.func()
net.receive("8", function(_, ply)
    local name = net.readUInt32()
    local tbl = getfenv()[net.readString()]
    if tbl then
        local func = tbl[net.readString()]
        if func then
            return2(
                name,
                ply,
                func()
            )
            return
        end
    end
    return2(name, ply)
end, "sf")

-- table.func(...)
net.receive("9", function(_, ply)
    local tbl = getfenv()[net.readString()]
    if tbl then
        local func = tbl[net.readString()]
        if func then func(net.readType()) end
    end
end, "sf")

-- return table.func(...)
net.receive("10", function(_, ply)
    local name = net.readUInt32()
    local tbl = getfenv()[net.readString()]
    if tbl then
        local func = tbl[net.readString()]
        if func then
            return2(
                name,
                ply,
                func(net.readType())
            )
            return
        end
    end
    return2(name, ply)
end, "sf")

-- table.func(..., callback(...))
net.receive("11", function(_, ply)
    local name = net.readUInt32()
    local tbl = getfenv()[net.readString()]
    if tbl then
        local func = tbl[net.readString()]
        if func then
            func(net.readType(), function(...)
                return2(name, ply, ...)
            end)
            return
        end
    end
    return2(name, ply)
end, "sf")

-- return table.create_ent_func(...) wait for ent to validate
net.receive("12", function(_, ply)
    local name = net.readUInt32()
    local tbl = getfenv()[net.readString()]
    if tbl then
        local func = tbl[net.readString()]
        if func then
            return2(
                name,
                ply,
                func(net.readType()):entIndex()
            )
            return
        end
    end
    return2(name, ply)
end, "sf")

-- return table.table
net.receive("13", function(_, ply)
    local name = net.readUInt32()
    local tbl = getfenv()[net.readString()]
    if tbl then
        return2(
            name,
            ply,
            tbl[net.readString()]
        )
    else
        return2(name, ply)
    end
end, "sf")

-- Player:method(args)
net.receive("14", function(_, ply)
    local methods = getMethods("Player")
    if methods then
        local method = methods[net.readString()]
        if method then
            method(net.readEntity(), net.readType())
        end
    end
end, "sf")

-- return Player:method(args)
net.receive("15", function(_, ply)
    local name = net.readName()
    local methods = getMethods("Player")
    if methods then
        local method = methods[net.readString()]
        if method then
            return2(
                name,
                ply,
                method(net.readEntity(), net.readType())
            )
            return
        end
    end
    return2(name, ply)
end, "sf")

-- Entity:method(args)
net.receive("16", function()
    local methods = getMethods(net.readString())
    if methods then
        local method = methods[net.readString()]
        if method then
            net.readEntity(function(ent)
                method(ent, net.readType())
            end)
        end
    end
end, "sf")

-- return Entity:method()
net.receive("17", function(_, ply)
    local methods = getMethods(net.readString())
    if methods then
        local method = methods[net.readString()]
        if method then
            net.readEntity(function(ent)
                return2(
                    name,
                    ply,
                    method(ent)
                )
            end)
            return
        end
    end
    return2(name, ply)
end, "sf")

local function run1(func_name, method, ...)
    net.start("1", "sf")
    net.writeString(func_name)
    net.writeString(method)
    net.writeType(...)
    net.send(SERVER and owner() or nil)
end

local function run2(func_name, method, ...)
    local name = net_name
    net_name = net_name + 1
    local results
    net.receive(name, function()
        net.receive(name, nil, "sf")
        results = {net.readType()}
    end, "sf")
    
    net.start("2", "sf")
    net.writeUInt32(name)
    net.writeString(func_name)
    net.writeString(method)
    net.writeType(...)
    net.send(SERVER and owner() or nil)
    
    while not results do coroutine.yield() end
    return unpack(results, 1, table.count(results))
end

local function run3(func_name)
    net.start("3", "sf")
    net.writeString(func_name)
    net.send(SERVER and owner() or nil)
end
    
local function run4(func_name)
    local name = net_name
    net_name = net_name + 1
    local results
    net.receive(name, function()
        net.receive(name, nil, "sf")
        results = {net.readType()}
    end, "sf")
    
    net.start("4", "sf")
    net.writeUInt32(name)
    net.writeString(func_name)
    net.send(SERVER and owner() or nil)
    
    while not results do coroutine.yield() end
    return unpack(results, 1, table.count(results))
end

local function run5(func_name, ...)
    net.start("5", "sf")
    net.writeString(func_name)
    net.writeType(...)
    net.send(SERVER and owner() or nil)
end

local function run6(func_name, ...)
    local name = net_name
    net_name = net_name + 1
    local results
    net.receive(name, function()
        net.receive(name, nil, "sf")
        results = {net.readType()}
    end, "sf")
    
    net.start("6", "sf")
    net.writeUInt32(name)
    net.writeString(func_name)
    net.writeType(...)
    net.send(SERVER and owner() or nil)
    
    while not results do coroutine.yield() end
    return unpack(results, 1, table.count(results))
end

local function run7(table_name, func_name)
    net.start("7", "sf")
    net.writeString(table_name)
    net.writeString(func_name)
    net.send(SERVER and owner() or nil)
end

local function run8(table_name, func_name)
    local name = net_name
    net_name = net_name + 1
    local results
    net.receive(name, function()
        net.receive(name, nil, "sf")
        results = {net.readType()}
    end, "sf")
    
    net.start("8", "sf")
    net.writeUInt32(name)
    net.writeString(table_name)
    net.writeString(func_name)
    net.send(SERVER and owner() or nil)
    
    while not results do coroutine.yield() end
    return unpack(results, 1, table.count(results))
end

local function run9(table_name, func_name, ...)
    net.start("9", "sf")
    net.writeString(table_name)
    net.writeString(func_name)
    net.writeType(...)
    net.send(SERVER and owner() or nil)
end

local function run10(table_name, func_name, ...)
    local name = net_name
    net_name = net_name + 1
    local results
    net.receive(name, function()
        net.receive(name, nil, "sf")
        results = {net.readType()}
    end, "sf")
    
    net.start("10", "sf")
    net.writeUInt32(name)
    net.writeString(table_name)
    net.writeString(func_name)
    net.writeType(...)
    net.send(SERVER and owner() or nil)
    
    while not results do coroutine.yield() end
    return unpack(results, 1, table.count(results))
end

local function run11(table_name, func_name, callback, ...)
    local name = net_name
    net_name = net_name + 1
    net.receive(name, function()
        net.receive(name, nil, "sf")
        callback(net.readType())
    end, "sf")
    
    net.start("11", "sf")
    net.writeUInt32(name)
    net.writeString(table_name)
    net.writeString(func_name)
    net.writeType(...)
    net.send(SERVER and owner() or nil)
end

local function run12(table_name, func_name, ...)
    local name = net_name
    net_name = net_name + 1
    local ent
    local received = false
    net.receive(name, function()
        net.receive(name, nil, "sf")
        local id = net.readType()
        if CLIENT then
            local ss = bit.stringstream(string.char(id % 0x100, bit.rshift(id, 8) % 0x100))
            ss:readEntity(function(e)
                ent = e
                timer.simple(0.1, function()
                    received = true
                end)
            end)
        else
            ent = entity(id)
            received = true
        end
    end, "sf")
    
    net.start("12", "sf")
    net.writeUInt32(name)
    net.writeString(table_name)
    net.writeString(func_name)
    net.writeType(...)
    net.send(SERVER and owner() or nil)
    
    while not received do coroutine.yield() end
    return ent
end

local function run13(table_name, table2_name)
    local name = net_name
    net_name = net_name + 1
    local results
    net.receive(name, function()
        net.receive(name, nil, "sf")
        results = {net.readType()}
    end, "sf")
    
    net.start("13", "sf")
    net.writeUInt32(name)
    net.writeString(table_name)
    net.writeString(table2_name)
    net.send(SERVER and owner() or nil)
    
    while not results do coroutine.yield() end
    return unpack(results)
end

local function run14(method, player, ...)
    net.start("14", "sf")
    net.writeString(method)
    net.writeEntity(player)
    net.writeType(...)
    net.send(SERVER and player or nil)
end

local function run15(method, player, ...)
    local name = net_name
    net_name = net_name + 1
    local results
    net.receive(name, function()
        net.receive(name, nil, "sf")
        results = {net.readType()}
    end, "sf")
    
    net.start("15", "sf")
    net.writeUInt32(name)
    net.writeString(method)
    net.writeEntity(player)
    net.writeType(...)
    net.send(SERVER and player or nil)
    
    while not results do coroutine.yield() end
    return unpack(results, 1, table.count(results))
end

-- Entity:method(args)
local function run16(class, method, ent, ...)
    net.start("16", "sf")
    net.writeString(class)
    net.writeString(method)
    net.writeEntity(ent)
    net.writeType(...)
    net.send(SERVER and owner() or nil)
end

-- return Entity:method()
local function run17(class, method, ent)
    local name = net_name
    net_name = net_name + 1
    local results
    net.receive(name, function()
        net.receive(name, nil, "sf")
        results = {net.readType()}
    end, "sf")
    
    net.start("17", "sf")
    net.writeUInt32(name)
    net.writeString(class)
    net.writeString(method)
    net.writeEntity(ent)
    net.send(SERVER and owner() or nil)
    
    while not results do coroutine.yield() end
    return unpack(results, 1, table.count(results))
end

if SERVER then
    function eyeAngles() return owner():getEyeAngles() end
    function eyePos() return owner():getEyePos() end
    function eyeVector() return owner():getEyeAngles():getForward() end
    function canPrintLocal() return run4("canPrintLocal") end
    function permissionRequestSatisfied() return run4("permissionRequestSatisfied") end
    function printLocal(...) return run6("printLocal", ...) end
    function printLocalLimits() return run4("printLocalLimits") end
    function printMessage(...) run5("printMessage", ...) end
    function sendPermissionRequest() run3("sendPermissionRequest") end
    function setClipboardText(...) run5("setClipboardText", ...) end
    function setName(...) run5("setName", ...) end
    function setupPermissionRequest(...) run5("setupPermissionRequest", ...) end
    convar = {}
    function convar.exists(...) return run10("convar", "exists", ...) end
    function convar.getBool(...) return run10("convar", "getBool", ...) end
    function convar.getDefault(...) return run10("convar", "getDefault", ...) end
    function convar.getFlags(...) return run10("convar", "getFlags", ...) end
    function convar.getFloat(...) return run10("convar", "getFloat", ...) end
    function convar.getInt(...) return run10("convar", "getInt", ...) end
    function convar.getMax(...) return run10("convar", "getMax", ...) end
    function convar.getMin(...) return run10("convar", "getMin", ...) end
    function convar.getString(...) return run10("convar", "getString", ...) end
    function convar.hasFlag(...) return run10("convar", "hasFlag", ...) end
    file = {}
    function file.append(...) run9("file", "append", ...) end
    function file.asyncRead(path, callback) run11("file", "append", callback, path) end
    function file.createDir(...) run9("file", "createDir", ...) end
    function file.delete(...) return run10("file", "delete", ...) end
    function file.exists(...) return run10("file", "exists", ...) end
    function file.existsTemp(...) return run10("file", "existsTemp", ...) end
    function file.find(...) return run10("file", "find", ...) end
    function file.findInGame(...) return run10("file", "findInGame", ...) end
    function file.read(...) return run10("file", "read", ...) end
    function file.readTemp(...) return run10("file", "readTemp", ...) end
    function file.write(...) return run10("file", "write", ...) end
    function file.writeTemp(...) return run10("file", "writeTemp", ...) end
    
    function game.getSunInfo() return run8("game", "getSunInfo") end
    function game.hasFocus() return run8("game", "hasFocus") end
    function game.isSkyboxVisibleFromPoint(...) return run10("game", "isSkyboxVisibleFromPoint", ...) end
    function game.serverFrameTime() return run8("game", "serverFrameTime") end
    input = {}
    function input.canLockControls() return run8("input", "canLockControls") end
    function input.enableCursor(...) run9("input", "enableCursor", ...) end
    function input.getCursorPos() return run8("input", "getCursorPos") end
    function input.getCursorVisible() return run8("input", "getCursorVisible") end
    function input.getKeyName(...) return run10("input", "getKeyName", ...) end
    function input.isControlDown() return run8("input", "isControlDown") end
    function input.isControlLocked() return run8("input", "isControlLocked") end
    function input.isKeyDown(...) return run10("input", "isKeyDown", ...) end
    function input.isMouseDown(...) return run10("input", "isMouseDown", ...) end
    function input.isShiftDown() return run8("input", "isShiftDown") end
    function input.lockControls(...) run9("input", "lockControls", ...) end
    function input.lookupBinding(...) return run10("input", "lookupBinding", ...) end
    function input.screenToVector(...) return run10("input", "screenToVector", ...) end
    function input.selectWeapon(...) run9("input", "selectWeapon", ...) end
    joystick = {}
    function joystick.getAxis(...) return run10("joystick", "getAxis", ...) end
    function joystick.getButton(...) return run10("joystick", "getButton", ...) end
    function joystick.getName(...) return run10("joystick", "getName", ...) end
    function joystick.getPov(...) return run10("joystick", "getPov", ...) end
    function joystick.numAxes(...) return run10("joystick", "numAxes", ...) end
    function joystick.numButtons(...) return run10("joystick", "numButtons", ...) end
    function joystick.numJoysticks() return run8("joystick", "numJoysticks") end
    function joystick.numPovs(...) return run10("joystick", "numPovs", ...) end
    notification = {}
    function notification.addLegacy(...) run9("notification", "addLegacy", ...) end
    function notification.addProgress(...) run9("notification", "addProgress", ...) end
    function notification.kill(...) run9("notification", "kill", ...) end
    particle = {}
    function particle.particleEmittersLeft() return run8("particle", "particleEmittersLeft") end
    socket = {}
    function socket.connect(...) return run10("socket", "connect", ...) end
    function socket.connect4(...) return run10("socket", "connect4", ...) end
    function socket.connect6(...) return run10("socket", "connect6", ...) end
    function socket.tcp() return run8("socket", "tcp") end
    function socket.tcp4() return run8("socket", "tcp4") end
    function socket.tcp6() return run8("socket", "tcp6") end
    sql = {}
    function sql.query(...) return run10("sql", "query", ...) end
    function sql.SQLStr(...) return run10("sql", "SQLStr", ...) end
    function sql.tableExists(...) return run10("sql", "tableExists", ...) end
    function sql.tableRemove(...) return run10("sql", "tableRemove", ...) end
    
    local vr_getHMDAng = vr.getHMDAng
    local vr_getHMDPos = vr.getHMDPos
    local vr_getHMDPose = vr.getHMDPose
    local vr_getLeftHandAng = vr.getLeftHandAng
    local vr_getLeftHandPos = vr.getLeftHandPos
    local vr_getLeftHandPose = vr.getLeftHandPose
    local vr_getRightHandAng = vr.getRightHandAng
    local vr_getRightHandPos = vr.getRightHandPos
    local vr_getRightHandPose = vr.getRightHandPose
    local vr_isPlayerInVR = vr.isPlayerInVR
    local vr_usingEmptyHands = vr.usingEmptyHands
    vr = setmetatable({}, {
        __index = function(self, key)
            if key == "VR" then
                return run13("vr", "VR")
            end
        end
    })
    vr.getHMDAng = vr_getHMDAng
    vr.getHMDPos = vr_getHMDPos
    vr.getHMDPose = vr_getHMDPose
    vr.getLeftHandAng = vr_getLeftHandAng
    vr.getLeftHandPos = vr_getLeftHandPos
    vr.getLeftHandPose = vr_getLeftHandPose
    vr.getRightHandAng = vr_getRightHandAng
    vr.getRightHandPos = vr_getRightHandPos
    vr.getRightHandPose = vr_getRightHandPose
    vr.isPlayerInVR = vr_isPlayerInVR
    vr.usingEmptyHands = vr_usingEmptyHands

local func_lookup = {
    canPrintLocal,
    permissionRequestSatisfied,
    printLocal,
    printLocalLimits,
    printMessage,
    printLocalLimits,
    sendPermissionRequest,
    setClipboardText,
    setName,
    setupPermissionRequest,
    convar and convar.exists or nil,
    convar and convar.getBool or nil,
    convar and convar.getDefault or nil,
    convar and convar.getFlags or nil,
    convar and convar.getFloat or nil,
    convar and convar.getInt or nil,
    convar and convar.getMax or nil,
    convar and convar.getMin or nil,
    convar and convar.getString or nil,
    convar and convar.hasFlag or nil,
    file and file.append or nil,
    file and file.asyncRead or nil,
    file and file.createDir or nil,
    file and file.delete or nil,
    file and file.exists or nil,
    file and file.existsTemp or nil,
    file and file.find or nil,
    file and file.findInGame or nil,
    file and file.read or nil,
    file and file.readTemp or nil,
    file and file.write or nil,
    file and file.writeTemp or nil,
    game.getSunInfo,
    game.hasFocus,
    game.isSkyboxVisibleFromPoint,
    game.serverFrameTime,
    input and input.canLockControls or nil,
    input and input.enableCursor or nil,
    input and input.getCursorPos or nil,
    input and input.getCursorVisible or nil,
    input and input.getKeyName or nil,
    input and input.isControlDown or nil,
    input and input.isControlLocked or nil,
    input and input.isKeyDown or nil,
    input and input.isMouseDown or nil,
    input and input.isShiftDown or nil,
    input and input.lockControls or nil,
    input and input.lookupBinding or nil,
    input and input.screenToVector or nil,
    input and input.selectWeapon or nil,
    joystick and joystick.getAxis or nil,
    joystick and joystick.getButton or nil,
    joystick and joystick.getName or nil,
    joystick and joystick.getPov or nil,
    joystick and joystick.numAxes or nil,
    joystick and joystick.numButtons or nil,
    joystick and joystick.numJoysticks or nil,
    joystick and joystick.numPovs or nil,
    notification and notification.addLegacy or nil,
    notification and notification.addProgress or nil,
    notification and notification.kill or nil,
    particle and particle.particleEmittersLeft or nil,
    socket and socket.connect or nil,
    socket and socket.connect4 or nil,
    socket and socket.connect6 or nil,
    socket and socket.tcp or nil,
    socket and socket.tcp4 or nil,
    socket and socket.tcp6 or nil,
    sql and sql.query or nil,
    sql and sql.SQLStr or nil,
    sql and sql.tableExists or nil,
    sql and sql.tableRemove or nil,
}
local id_lookup = {
    "canPrintLocal",
    "permissionRequestSatisfied",
    "printLocal",
    "printLocalLimits",
    "printMessage",
    "sendPermissionRequest",
    "setClipboardText",
    "setName",
    "setupPermissionRequest",
    "convar.exists",
    "convar.getBool",
    "convar.getDefault",
    "convar.getFlags",
    "convar.getFloat",
    "convar.getInt",
    "convar.getMax",
    "convar.getMin",
    "convar.getString",
    "convar.hasFlag",
    "file.append",
    "file.asyncRead",
    "file.createDir",
    "file.delete",
    "file.exists",
    "file.existsTemp",
    "file.find",
    "file.findInGame",
    "file.read",
    "file.readTemp",
    "file.write",
    "file.writeTemp",
    "game.getSunInfo",
    "game.hasFocus",
    "game.isSkyboxVisibleFromPoint",
    "game.serverFrameTime",
    "input.canLockControls",
    "input.enableCursor",
    "input.getCursorPos",
    "input.getCursorVisible",
    "input.getKeyName",
    "input.isControlDown",
    "input.isControlLocked",
    "input.isKeyDown",
    "input.isMouseDown",
    "input.isShiftDown",
    "input.lockControls",
    "input.lookupBinding",
    "input.screenToVector",
    "input.selectWeapon",
    "joystick.getAxis",
    "joystick.getButton",
    "joystick.getName",
    "joystick.getPov",
    "joystick.numAxes",
    "joystick.numButtons",
    "joystick.numJoysticks",
    "joystick.numPovs",
    "notification.addLegacy",
    "notification.addProgress",
    "notification.kill",
    "particle.particleEmittersLeft",
    "socket.connect",
    "socket.connect4",
    "socket.connect6",
    "socket.tcp",
    "socket.tcp4",
    "socket.tcp6",
    "sql.query",
    "sql.SQLStr",
    "sql.tableExists",
    "sql.tableRemove",
}
for i = 1, #id_lookup do
    id_lookup[id_lookup[i]] = i
    id_lookup[i] = nil
end

    function vr.getEyePos() return run8("vr", "getEyePos") end
    function vr.getHMDAngularVelocity() return run8("vr", "getHMDAngularVelocity") end
    function vr.getHMDVelocities() return run8("vr", "getHMDVelocities") end
    function vr.getHMDVelocity() return run8("vr", "getHMDVelocity") end
    function vr.getInput(...) return run10("vr", "getInput", ...) end
    function vr.getLeftEyePos() return run8("vr", "getLeftEyePos") end
    function vr.getLeftHandAngularVelocity() return run8("vr", "getLeftHandAngularVelocity") end
    function vr.getLeftHandVelocities() return run8("vr", "getLeftHandVelocities") end
    function vr.getLeftHandVelocity() return run8("vr", "getLeftHandVelocity") end
    function vr.getOrigin() return run8("vr", "getOrigin") end
    function vr.getOriginAng() return run8("vr", "getOriginAng") end
    function vr.getOriginPos() return run8("vr", "getOriginPos") end
    function vr.getRightEyePos() return run8("vr", "getRightEyePos") end
    function vr.getRightHandAngularVelocity() return run8("vr", "getRightHandAngularVelocity") end
    function vr.getRightHandVelocities() return run8("vr", "getRightHandVelocities") end
    function vr.getRightHandVelocity() return run8("vr", "getRightHandVelocity") end
    xinput = {}
    function xinput.getBatteryLevel(...) return run10("xinput", "getBatteryLevel", ...) end
    function xinput.getButton(...) return run10("xinput", "getButton", ...) end
    function xinput.getControllers() return run8("xinput", "getControllers") end
    function xinput.getState(...) return run10("xinput", "getState", ...) end
    function xinput.getStick(...) return run10("xinput", "getStick", ...) end
    function xinput.getTrigger(...) return run10("xinput", "getTrigger", ...) end
    function xinput.setRumble(...) run9("xinput", "setRumble", ...) end
    
    getMethods("Entity")["canDraw"] = function(...)
        return run17("Entity", "canDraw", ...)
    end
    getMethods("Entity")["manipulateBoneAngles"] = function(...)
        run16("Entity", "manipulateBoneAngles", ...)
    end
    getMethods("Entity")["manipulateBoneJiggle"] = function(...)
        run16("Entity", "manipulateBoneJiggle", ...)
    end
    getMethods("Entity")["manipulateBonePosition"] = function(...)
        run16("Entity", "manipulateBonePosition", ...)
    end
    getMethods("Entity")["manipulateBoneScale"] = function(...)
        run16("Entity", "manipulateBoneScale", ...)
    end
    getMethods("Entity")["setRenderBounds"] = function(...)
        run16("Entity", "setRenderBounds", ...)
    end
    
    
    getMethods("Hologram")["setFilterMag"] = function(...)
        run16("Hologram", "setFilterMag", ...)
    end
    getMethods("Hologram")["setFilterMin"] = function(...)
        run16("Hologram", "setFilterMin", ...)
    end
    getMethods("Hologram")["setRenderMatrix"] = function(...)
        run16("Hologram", "setRenderMatrix", ...)
    end
    
    
    getMethods("Player")["getAnimationProgress"] = function(...)
        return run2("Player", "getAnimationProgress", ...)
    end
    getMethods("Player")["getAnimationTime"] = function(...)
        return run2("Player", "getAnimationTime", ...)
    end
    getMethods("Player")["getFriendStatus"] = function(...)
        return run2("Player", "getFriendStatus", ...)
    end
    getMethods("Player")["isMuted"] = function(...)
        return run15("isMuted", ...)
    end
    getMethods("Player")["isPlayingAnimation"] = function(...)
        return run15("isPlayingAnimation", ...)
    end
    getMethods("Player")["isSpeaking"] = function(...)
        return run15("isSpeaking", ...)
    end
    getMethods("Player")["playGesture"] = function(...)
        run1("Player", "playGesture", ...)
    end
    getMethods("Player")["resetAnimation"] = function(...)
        run1("Player", "resetAnimation", ...)
    end
    getMethods("Player")["resetGesture"] = function(...)
        run1("Player", "resetGesture", ...)
    end
    getMethods("Player")["setAnimation"] = function(...)
        run1("Player", "setAnimation", ...)
    end
    getMethods("Player")["setAnimationActivity"] = function(...)
        run1("Player", "setAnimationActivity", ...)
    end
    getMethods("Player")["setAnimationAutoAdvance"] = function(...)
        run1("Player", "setAnimationAutoAdvance", ...)
    end
    getMethods("Player")["setAnimationBounce"] = function(...)
        run1("Player", "setAnimationBounce", ...)
    end
    getMethods("Player")["setAnimationLoop"] = function(...)
        run1("Player", "setAnimationLoop", ...)
    end
    getMethods("Player")["setAnimationProgress"] = function(...)
        run1("Player", "setAnimationProgress", ...)
    end
    getMethods("Player")["setAnimationRange"] = function(...)
        run1("Player", "setAnimationRange", ...)
    end
    getMethods("Player")["setAnimationRate"] = function(...)
        run1("Player", "setAnimationRate", ...)
    end
    getMethods("Player")["setAnimationTime"] = function(...)
        run1("Player", "setAnimationTime", ...)
    end
    getMethods("Player")["setGestureWeight"] = function(...)
        run1("Player", "setGestureWeight", ...)
    end
    getMethods("Player")["voiceVolume"] = function(...)
        return run2("Player", "voiceVolume", ...)
    end
    
    
    getMethods("Weapon")["getPrintName"] = function(...)
        return run2("Weapon", "getPrintName", ...)
    end
    getMethods("Weapon")["isCarriedByLocalPlayer"] = function(...)
        return run2("Weapon", "isCarriedByLocalPlayer", ...)
    end
    --[[
    1 = baseFunc():method(args)
    2 = return baseFunc():method(args)
    3 = baseFunc()
    4 = return baseFunc()
    5 = baseFunc(args)
    6 = return baseFunc(args)
    7 = table.func()
    8 = return table.func()
    9 = table.func(...)
    10 = return table.func(...)
    11 = table.func(..., callback(...))
    12 = return table.create_ent_func(...) wait for ent to validate
    13 = return table.table
    14 = Player:method(...)
    15 = return Player:method(...)
    ]]
    
    -- prop.create()
    net.receive("prop", function(_, ply)
        local name = net.readUInt32()
        return2(name, ply, prop.create(net.readType()):entIndex())
    end, "sf")
    
    -- prop.createComponent()
    net.receive("comp", function(_, ply)
        local name = net.readUInt32()
        return2(name, ply, prop.createComponent(net.readType()):entIndex())
    end, "sf")
    
    -- prop.createCustom()
    net.receive("cust", function(_, ply)
        local name = net.readUInt32()
        return2(name, ply, prop.createCustom(net.readType()):entIndex())
    end, "sf")
    
    -- prop.createRagdoll()
    net.receive("rag", function(_, ply)
        local name = net.readUInt32()
        return2(name, ply, prop.createRagdoll(net.readType()):entIndex())
    end, "sf")
    
    -- prop.createSeat()
    net.receive("seat", function(_, ply)
        local name = net.readUInt32()
        return2(name, ply, prop.createSeat(net.readType()):entIndex())
    end, "sf")
    
    -- prop.createSent()
    net.receive("sent", function(_, ply)
        local name = net.readUInt32()
        return2(name, ply, prop.createSent(net.readType()):entIndex())
    end, "sf")
    
    -- prop2mesh.create()
    net.receive("p2m", function(_, ply)
        local name = net.readUInt32()
        return2(name, ply, prop2mesh.create(net.readType()):entIndex())
    end, "sf")
else -- CLIENT
    local function spawnEnt(net_target, ...)
        local name = net_name
        net_name = net_name + 1
        local ent
        local received = false
        net.receive(name, function()
            net.receive(name, nil, "sf")
            local id = net.readType()
            if CLIENT then
                local ss = bit.stringstream(string.char(id % 0x100, bit.rshift(id, 8) % 0x100))
                ss:readEntity(function(e)
                    ent = e
                    timer.simple(0.1, function()
                        received = true
                    end)
                end)
            else
                ent = entity(id)
                received = true
            end
        end, "sf")
        
        net.start(net_target, "sf")
        net.writeUInt32(name)
        net.writeType(...)
        net.send(SERVER and owner() or nil)
        
        while not received do coroutine.yield() end
        return ent
    end

    function getUserdata() return run4("getUserdata") end
    function setUserdata(...) run5("setUserdata", ...) end
    constraint = {}
    function constraint.axis(...) run9("constraint", "axis", ...) end
    function constraint.ballsocket(...) run9("constraint", "ballsocket", ...) end
    function constraint.ballsocketadv(...) run9("constraint", "ballsocketadv", ...) end
    function constraint.breakAll(...) run9("constraint", "breakAll", ...) end
    function constraint.breakType(...) run9("constraint", "breakType", ...) end
    function constraint.constraintsLeft() return run8("constraint", "constraintsLeft") end
    function constraint.elastic(...) run9("constraint", "elastic", ...) end
    function constraint.getTable(...) return run10("constraint", "getTable", ...) end
    function constraint.keepupright(...) run9("constraint", "keepupright", ...) end
    function constraint.nocollide(...) run9("constraint", "nocollide", ...) end
    function constraint.rope(...) run9("constraint", "rope", ...) end
    function constraint.setConstraintClean(...) run9("constraint", "setConstraintClean", ...) end
    function constraint.setElasticLength(...) run9("constraint", "setElasticLength", ...) end
    function constraint.setRopeLength(...) run9("constraint", "setRopeLength", ...) end
    function constraint.slider(...) run9("constraint", "slider", ...) end
    function constraint.weld(...) run9("constraint", "weld", ...) end
    function find.inPVS(...) return run10("find", "inPVS", ...) end
    function game.blastDamage(...) run9("game", "blastDamage", ...) end
    prop = setmetatable({}, {
        __index = function(self, key)
            if key == "SENT_Data_Structures" then
                return run13("prop", "SENT_Data_Structures")
            end
        end
    })
    function prop.canSpawn() return run8("prop", "canSpawn") end
    function prop.create(...) return spawnEnt("prop", ...) end
    function prop.createComponent(...) return spawnEnt("comp", ...) end
    function prop.createCustom(...) return spawnEnt("cust", ...) end
    function prop.createRagdoll(...) return spawnEnt("rag", ...) end
    function prop.createSeat(...) return spawnEnt("seat", ...) end
    function prop.createSent(...) return spawnEnt("sent", ...) end
    function prop.getSpawnableSents(...) return run10("prop", "getSpawnableSents", ...) end
    function prop.propsLeft() return run8("prop", "propsLeft") end
    function prop.setPropClean(...) run9("prop", "setPropClean", ...) end
    function prop.setPropUndo(...) run9("prop", "setPropUndo", ...) end
    function prop.spawnRate() return run8("prop", "spawnRate") end
    prop2mesh = {}
    function prop2mesh.create(...) return spawnEnt("p2m", ...) end
    wire = {}
    function wire.adjustInputs(...) run9("wire", "adjustInputs", ...) end
    function wire.adjustOutputs(...) run9("wire", "adjustOutputs", ...) end
    function wire.adjustPorts(...) run9("wire", "adjustPorts", ...) end
    function wire.create(...) run9("wire", "create", ...) end
    function wire.delete(...) run9("wire", "delete", ...) end
    function wire.getInputs(...) return run10("wire", "getInputs", ...) end
    function wire.getOutputs(...) return run10("wire", "getOutputs", ...) end
    function wire.serverUUID() run7("wire", "serverUUID") end
    
    getMethods("Entity")["acfPower"] = function(...)
        return run2("Entity", "acfPower", ...)
    end
    getMethods("Entity")["addAngleVelocity"] = function(...)
        run1("Entity", "addAngleVelocity", ...)
    end
    getMethods("Entity")["addClip"] = function(...)
        return run2("Entity", "addClip", ...)
    end
    getMethods("Entity")["addVelocity"] = function(...)
        run1("Entity", "addVelocity", ...)
    end
    getMethods("Entity")["applyAngForce"] = function(...)
        run1("Entity", "applyAngForce", ...)
    end
    getMethods("Entity")["applyDamage"] = function(...)
        run1("Entity", "applyDamage", ...)
    end
    getMethods("Entity")["applyForceCenter"] = function(...)
        run1("Entity", "applyForceCenter", ...)
    end
    getMethods("Entity")["applyForceOffset"] = function(...)
        run1("Entity", "applyForceOffset", ...)
    end
    getMethods("Entity")["applyTorque"] = function(...)
        run1("Entity", "applyTorque", ...)
    end
    getMethods("Entity")["breakEnt"] = function(...)
        run1("Entity", "breakEnt", ...)
    end
    getMethods("Entity")["clipExists"] = function(...)
        return run2("Entity", "clipExists", ...)
    end
    getMethods("Entity")["enableDrag"] = function(...)
        run1("Entity", "enableDrag", ...)
    end
    getMethods("Entity")["enableGravity"] = function(...)
        run1("Entity", "enableGravity", ...)
    end
    getMethods("Entity")["enableMotion"] = function(...)
        run1("Entity", "enableMotion", ...)
    end
    getMethods("Entity")["enableSphere"] = function(...)
        run1("Entity", "enableSphere", ...)
    end
    getMethods("Entity")["extinguish"] = function(...)
        run1("Entity", "extinguish", ...)
    end
    getMethods("Entity")["getAllConstrained"] = function(...)
        run1("Entity", "getAllConstrained", ...)
    end
    getMethods("Entity")["getClipIndex"] = function(...)
        return run2("Entity", "getClipIndex", ...)
    end
    getMethods("Entity")["getCreationID"] = function(...)
        return run2("Entity", "getCreationID", ...)
    end
    getMethods("Entity")["getErroredPlayers"] = function(...)
        return run2("Entity", "getErroredPlayers", ...)
    end
    getMethods("Entity")["getFriction"] = function(...)
        return run2("Entity", "getFriction", ...)
    end
    getMethods("Entity")["getPhysMaterial"] = function(...)
        return run2("Entity", "getPhysMaterial", ...)
    end
    getMethods("Entity")["ignite"] = function(...)
        run1("Entity", "ignite", ...)
    end
    getMethods("Entity")["isConstraint"] = function(...)
        return run2("Entity", "isConstraint", ...)
    end
    getMethods("Entity")["isFrozen"] = function(...)
        return run2("Entity", "isFrozen", ...)
    end
    getMethods("Entity")["isPlayerHolding"] = function(...)
        return run2("Entity", "isPlayerHolding", ...)
    end
    getMethods("Entity")["isValidPhys"] = function(...)
        return run2("Entity", "isValidPhys", ...)
    end
    getMethods("Entity")["isWeldedTo"] = function(...)
        return run2("Entity", "isWeldedTo", ...)
    end
    getMethods("Entity")["linkComponent"] = function(...)
        run1("Entity", "linkComponent", ...)
    end
    getMethods("Entity")["physicsClipsLeft"] = function(...)
        return run2("Entity", "physicsClipsLeft", ...)
    end
    getMethods("Entity")["remove"] = function(...)
        run1("Entity", "remove", ...)
    end
    getMethods("Entity")["removeClip"] = function(...)
        return run2("Entity", "removeClip", ...)
    end
    getMethods("Entity")["removeClipByIndex"] = function(...)
        return run2("Entity", "removeClipByIndex", ...)
    end
    getMethods("Entity")["removeClips"] = function(...)
        return run2("Entity", "removeClips", ...)
    end
    getMethods("Entity")["removeTrails"] = function(...)
        run1("Entity", "removeTrails", ...)
    end
    getMethods("Entity")["setAngles"] = function(...)
        run1("Entity", "setAngles", ...)
    end
    getMethods("Entity")["setAngleVelocity"] = function(...)
        run1("Entity", "setAngleVelocity", ...)
    end
    getMethods("Entity")["setCollisionGroup"] = function(...)
        run1("Entity", "setCollisionGroup", ...)
    end
    getMethods("Entity")["setComponentLocksControls"] = function(...)
        run1("Entity", "setComponentLocksControls", ...)
    end
    getMethods("Entity")["setCustomPropForces"] = function(...)
        run1("Entity", "setCustomPropForces", ...)
    end
    getMethods("Entity")["setDrawShadow"] = function(...)
        run1("Entity", "setDrawShadow", ...)
    end
    getMethods("Entity")["setElasticity"] = function(...)
        run1("Entity", "setElasticity", ...)
    end
    getMethods("Entity")["setFriction"] = function(...)
        run1("Entity", "setFriction", ...)
    end
    getMethods("Entity")["setFrozen"] = function(...)
        run1("Entity", "setFrozen", ...)
    end
    getMethods("Entity")["setInertia"] = function(...)
        run1("Entity", "setInertia", ...)
    end
    getMethods("Entity")["setMass"] = function(...)
        run1("Entity", "setMass", ...)
    end
    getMethods("Entity")["setNocollideAll"] = function(...)
        run1("Entity", "setNocollideAll", ...)
    end
    getMethods("Entity")["setParent"] = function(...)
        run1("Entity", "setParent", ...)
    end
    getMethods("Entity")["setPhysMaterial"] = function(...)
        run1("Entity", "setPhysMaterial", ...)
    end
    getMethods("Entity")["setPos"] = function(...)
        run1("Entity", "setPos", ...)
    end
    getMethods("Entity")["setSolid"] = function(...)
        run1("Entity", "setSolid", ...)
    end
    getMethods("Entity")["setTrails"] = function(...)
        run1("Entity", "setTrails", ...)
    end
    getMethods("Entity")["setUnbreakable"] = function(...)
        run1("Entity", "setUnbreakable", ...)
    end
    getMethods("Entity")["setVelocity"] = function(...)
        run1("Entity", "setVelocity", ...)
    end
    getMethods("Entity")["testPVS"] = function(...)
        return run2("Entity", "testPVS", ...)
    end
    getMethods("Entity")["unparent"] = function(...)
        run1("Entity", "unparent", ...)
    end
    getMethods("Entity")["use"] = function(...)
        run1("Entity", "use", ...)
    end
    
    
    getMethods("Hologram")["setAngVel"] = function(...)
        run1("Hologram", "setAngVel", ...)
    end
    getMethods("Hologram")["setVel"] = function(...)
        run1("Hologram", "setVel", ...)
    end
    
    
    getMethods("Npc")["addEntityRelationship"] = function(...)
        run1("Npc", "addEntityRelationship", ...)
    end
    getMethods("Npc")["addRelationship"] = function(...)
        run1("Npc", "addRelationship", ...)
    end
    getMethods("Npc")["attackMelee"] = function(...)
        run1("Npc", "attackMelee", ...)
    end
    getMethods("Npc")["attackRange"] = function(...)
        run1("Npc", "attackRange", ...)
    end
    getMethods("Npc")["getEnemy"] = function(...)
        return run2("Npc", "getEnemy", ...)
    end
    getMethods("Npc")["getRelationship"] = function(...)
        return run2("Npc", "getRelationship", ...)
    end
    getMethods("Npc")["giveWeapon"] = function(...)
        run1("Npc", "giveWeapon", ...)
    end
    getMethods("Npc")["goRun"] = function(...)
        run1("Npc", "goRun", ...)
    end
    getMethods("Npc")["goWalk"] = function(...)
        run1("Npc", "goWalk", ...)
    end
    getMethods("Npc")["setEnemy"] = function(...)
        run1("Npc", "setEnemy", ...)
    end
    getMethods("Npc")["stop"] = function(...)
        run1("Npc", "stop", ...)
    end
    
    if getMethods("p2m") then
        getMethods("p2m")["build"] = function(...)
            run1("p2m", "build", ...)
        end
        getMethods("p2m")["getColor"] = function(...)
            return run2("p2m", "getColor", ...)
        end
        getMethods("p2m")["getCount"] = function(...)
            return run2("p2m", "getCount", ...)
        end
        getMethods("p2m")["getMaterial"] = function(...)
            return run2("p2m", "getMaterial", ...)
        end
        getMethods("p2m")["pushModel"] = function(...)
            run1("p2m", "pushModel", ...)
        end
        getMethods("p2m")["setAlpha"] = function(...)
            run1("p2m", "setAlpha", ...)
        end
        getMethods("p2m")["setColor"] = function(...)
            run1("p2m", "setColor", ...)
        end
        getMethods("p2m")["setLink"] = function(...)
            run1("p2m", "setLink", ...)
        end
        getMethods("p2m")["setMaterial"] = function(...)
            run1("p2m", "setMaterial", ...)
        end
        getMethods("p2m")["setScale"] = function(...)
            run1("p2m", "setScale", ...)
        end
        getMethods("p2m")["setUV"] = function(...)
            run1("p2m", "setUV", ...)
        end
    end
    
    
    getMethods("Player")["dropWeapon"] = function(...)
        run14("dropWeapon", ...)
    end
    getMethods("Player")["getPacketLoss"] = function(...)
        return run15("getPacketLoss", ...)
    end
    getMethods("Player")["getTimeConnected"] = function(...)
        return run15("getTimeConnected", ...)
    end
    getMethods("Player")["getTimeoutSeconds"] = function(...)
        return run15("getTimeoutSeconds", ...)
    end
    getMethods("Player")["hasGodMode"] = function(...)
        return run15("hasGodMode", ...)
    end
    getMethods("Player")["isTimingOut"] = function(...)
        return run15("isTimingOut", ...)
    end
    getMethods("Player")["lastHitGroup"] = function(...)
        return run15("lastHitGroup", ...)
    end
    getMethods("Player")["say"] = function(...)
        run14("say", ...)
    end
    getMethods("Player")["setEyeAngles"] = function(...)
        run14("setEyeAngles", ...)
    end
    getMethods("Player")["setModelScale"] = function(...)
        run14("setModelScale", ...)
    end
    getMethods("Player")["setViewEntity"] = function(...)
        run14("setViewEntity", ...)
    end
    
    
    getMethods("Vector")["isInWorld"] = function(...)
        return run2("Vector", "isInWorld", ...)
    end
    getMethods("Vehicle")["ejectDriver"] = function(...)
        run1("Vehicle", "ejectDriver", ...)
    end
    getMethods("Vehicle")["getDriver"] = function(...)
        return run2("Vehicle", "getDriver", ...)
    end
    getMethods("Vehicle")["getPassenger"] = function(...)
        return run2("Vehicle", "getPassenger", ...)
    end
    getMethods("Vehicle")["killDriver"] = function(...)
        run1("Vehicle", "killDriver", ...)
    end
    getMethods("Vehicle")["lock"] = function(...)
        run1("Vehicle", "lock", ...)
    end
    getMethods("Vehicle")["stripDriver"] = function(...)
        run1("Vehicle", "stripDriver", ...)
    end
    getMethods("Vehicle")["unlock"] = function(...)
        run1("Vehicle", "unlock", ...)
    end
end
