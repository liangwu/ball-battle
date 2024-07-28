local skynet = require "skynet"
local socket = require "skynet.socket"
local runconfig = require "runconfig"
local service = require "service"

local name, id = ...


local connection = {
    conntable = {},
}

connection.conntable = setmetatable(connection.conntable, {
	__index = function(_table, key)
		key = tonumber(key)
		local conn = {
			fd = key,
			player = nil
		}
		_table[key] = conn
		return conn
	end
})

-- @param {number,string} fd
-- @param {table} conn
function connection.getconn(fd)
	return connection.conntable[tonumber(fd)]
end


local players = {
    playertable = {}, -- [playerid] = gateplayer
    -- 玩家类
    getplayer = function(playerid)
        return players.playertable[tonumber(playerid)]
    end,

	delplayer = function(playerid)
		players.playertable[tonumber(playerid)] = nil
	end,
}

players.playertable = setmetatable(players.playertable, {
	__index = function(_table, key)
		local player = {
			fd = nil,
			playerid = key,
			agent = nil,		--agent service
		}
		_table[key] = player
		return player
	end
})


function connection.disconnect(fd)
    local conn = connection.getconn(fd)

    local playerid = conn.playerid
    
    if not playerid then
		-- 还没完成登录
        return
    else
		-- 已在游戏中
		players.delplayer(playerid)
        local reason = "断线"
        skynet.call("agentmgr", "lua", "reqkick", playerid, reason)
    end
end


-- gateway: 转发数据包
local process_msg = function(fd, msgstr)
    local service_name, cmd, msg = service.unpack(msgstr)
	if not service_name then
		skynet.error("service_name is nil")
		return
	end
	if not cmd then
		skynet.error("cmd is nil")
		return
	end
    skynet.error("recv " .. fd .. " [" ..service_name .. ":" .. cmd .. "] {" .. table.concat(msg, ",") .. "}")

    local conn = connection.getconn(fd)
    local playerid = conn.playerid
    -- 尚未完成登录流程
    if not playerid then
        local node = skynet.getenv("node")
        local nodecfg = runconfig[node]
        local loginid = math.random(1, #nodecfg.login)
        local login = "login" .. loginid
        skynet.send(login, service.PROTOCOL.client, "login", fd, {msg[3], msg[4]})
        -- 完成登录流程
    else
        local gplayer = players.getplayer(playerid)
        local agent = gplayer.agent
        skynet.send(agent, "lua", "client", cmd, msg)
    end
end

-- 以分隔符{\r\n}区分一个数据包
local process_buff = function(fd, readbuff)
    while true do
        local msgstr, rest = string.match(readbuff, "(.-)\r\n(.*)")
        if msgstr then
            readbuff = rest
            process_msg(fd, msgstr)
        else
            return readbuff
        end
    end
end


-- 每一条连接接收数据处理
-- 协议格式 cmd,arg1,arg2,...#
local recv_loop = function(fd)
    socket.start(fd)
    skynet.error("socket connected " .. fd)
    local readbuff = ""
    while true do
        local recvstr = socket.read(fd)
        if recvstr then
            readbuff = readbuff .. recvstr
            readbuff = process_buff(fd, readbuff)
        else
            skynet.error("socket close " .. fd)
            connection.disconnect(fd)
            socket.close(fd)
            return
        end
    end
end

function connection.connect(fd, addr)
	fd = tonumber(fd)
	print("connect from " .. addr .. " " .. fd)
    local conn = connection.getconn(fd)
    skynet.fork(recv_loop, fd)
end





function service.init()
    skynet.error("[start]" .. service.name .. service.id)
    local node = skynet.getenv("node")
    local nodecfg = runconfig[node]
    local port = nodecfg.gateway[service.id].port

    local listenfd = socket.listen("0.0.0.0", port)
    skynet.error("Listen socket :", "0.0.0.0", port)
    socket.start(listenfd, connection.connect)
end

service.start(name, id)
