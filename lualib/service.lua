local skynet = require "skynet"
local cluster = require "skynet.cluster"

local _M = {
    --类型和id
    name = "",
    id = 0,
    --回调函数
    exit = nil,
    init = nil,
    --分发方法
    commonds = {},
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

local dispatch = function(session, address, cmd, ...)
    local fun = _M.commonds[cmd]
    if not fun then
        skynet.ret()
        return
    end
    
    local ret = table.pack(xpcall(fun, traceback, address, ...))
    local isok = ret[1]
    
    if not isok then
        skynet.ret()
        return
    end

    skynet.retpack(table.unpack(ret,2))
end


function init()
    skynet.dispatch("lua", dispatch)
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