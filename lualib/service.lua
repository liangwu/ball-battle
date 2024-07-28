local skynet = require "skynet"
local socket = require "skynet.socket"
local cluster = require "skynet.cluster"

local _M = {
    -- 类型和id
    name = "",
    id = 0,
    type = nil, -- [login, gateway, agentmgr...]
    -- 回调函数
    exit = nil,
    init = nil,
    -- protocol
    PROTOCOL = {
        client = "client",
        lua = "lua"
    },
    -- lua 消息处理
    lua_commonds = {},
    -- 客户端响应
    client_commands = {}
}

function _M.call(node, srv, ...)
    local mynode = skynet.getenv("node")
    if node == mynode then
        return skynet.call(srv, "lua", ...)
    else
        return cluster.call(node, srv, ...)
    end
end

function _M.send(node, srv, ...)
    local mynode = skynet.getenv("node")
    if node == mynode then
        return skynet.send(srv, "lua", ...)
    else
        return cluster.send(node, srv, ...)
    end
end

function _M:respClient(fd, ok, msg)
    local msgT = type(msg)
    if msgT == "string" then
        socket.write(fd, string.format("%s, %d, %s/r/n", self.type, ok and 0 or 1, msg));
        return true
    elseif msgT == "table" then
        socket.write(fd, string.format("%s, %d, %s", self.type, ok and 0 or 1, _M.pack(msg)));
        return true
    end

    return false
end

-- 协议设计：service_name,cmd,args...\r\n

-- @param {string}msgstr
-- @return {string}service_name, {string}cmd, {table}msg
function _M.unpack(msgstr)
    local msg = {}

    while true do
        local arg, rest = string.match(msgstr, "(.-),(.*)")
        if arg then
            msgstr = rest
            table.insert(msg, arg)
        else
            table.insert(msg, msgstr)
            break
        end
    end
    return msg[1], msg[2], msg
end

-- @param {table} msg
function _M.pack(msg)
    return table.concat(msg, ",") .. "\r\n"
end

function traceback(err)
    skynet.error(tostring(err))
    skynet.error(debug.traceback())
end

local function client_dispatch(session, address, cmd, fd, tmsg)
    local fun = _M.client_commands[cmd]
    if not fun then
        skynet.error()
        return
    end

    local isok, resp = xpcall(fun, traceback, tmsg)
    if not resp then
        return
    end

    local msg = string.format("%s, %d, %s/r/n", self.type, isok and 0 or 1, table.concat(resp, ","))
    socket.write(fd, msg)
end

local lua_dispatch = function(session, address, cmd, ...)
    local fun = _M.lua_commonds[cmd]
    if not fun then
        skynet.ret()
        return
    end

    local ret = table.pack(xpcall(fun, traceback, ...))
    local isok = ret[1]

    if not isok then
        skynet.ret()
        return
    end

    skynet.retpack(table.unpack(ret, 2))
end

local function string2table(str)
    local t = {}
    for value in string.gmatch(str, '([^,]+)') do
        table.insert(t, value)
    end
    return t
end

function init()
    skynet.dispatch("lua", lua_dispatch)

    skynet.register_protocol {
        name = "client",
        id = skynet.PTYPE_CLIENT,

        -- @param {integer}fd
        -- @param {table}msg
        pack = function(cmd, fd, msg)
            assert(type(msg) == "table")
            return cmd .. "|", tostring(fd) .. "|" .. table.concat(msg, ",")
        end,
        unpack = function(msg, size)
            local str = skynet.tostring(msg, size)
            local _first = string.find(str, "|", 1, true)
            local _second = string.find(str, "|", _first + 1, true)
            local fd = tonumber(string.sub(str, 1, _first - 1))
            local cmd = string.sub(str, _first + 1, _second - 1)
            return cmd, fd, string2table(string.sub(str, _ss + 1))
        end,
        dispatch = client_dispatch
    }
    if _M.init then
        _M.init()
    end
end

function _M.start(name, id, ...)
    _M.name = name
    _M.id = tonumber(id)
    skynet.start(init)
end

return _M
