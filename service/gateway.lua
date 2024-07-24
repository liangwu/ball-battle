local skynet = require "skynet"
local socket = require "skynet.socket"
local runconfig = require "runconfig"
local service = require "service"

local name, id = ...


connection = {
    conntable = {},

	-- @param {number} fd
    getconn = function(fd)
		fd = tonumber(fd)
		local conn = connection.conntable[fd]
		if not conn then
			conn.fd = fd
			conn.player = nil
		end
        return conn
    end
}

local process_msg = function(fd, msgstr)
    local cmd, msg = str_unpack(msgstr)
    skynet.error("recv " .. fd .. " [" .. cmd .. "] {" .. table.concat(msg, ",") .. "}")

    local conn = connection.conntable[tonumber(fd)]
    local playerid = conn.playerid
    -- 尚未完成登录流程
    if not playerid then
        local node = skynet.getenv("node")
        local nodecfg = runconfig[node]
        local loginid = math.random(1, #nodecfg.login)
        local login = "login" .. loginid
        skynet.send(login, "lua", "client", fd, cmd, msg)
        -- 完成登录流程
    else
        local gplayer = players[playerid]
        local agent = gplayer.agent
        skynet.send(agent, "lua", "client", cmd, msg)
    end
end

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
connection.recv_loop = function(fd)
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
            disconnect(fd)
            socket.close(fd)
            return
        end
    end
end



function connection.conntion(fd, addr)
	fd = tonumber(fd)
	print("connect from " .. addr .. " " .. fd)
    local conn = connection.getconn(fd)
    connection.conntable[fd] = conn
    skynet.fork(recv_loop, fd)
end

player = {
    playertable = {}, -- [playerid] = gateplayer
    -- 玩家类
    getplayer = function()
        local m = {
            playerid = nil,
            agent = nil,
            conn = nil
        }
        return m
    end
}


local str_unpack = function(msgstr)
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
    return msg[1], msg
end

local str_pack = function(cmd, msg)
    return table.concat(msg, ",") .. "\r\n"
end





local disconnect = function(fd)
    local c = conns[fd]
    if not c then
        return
    end

    local playerid = c.playerid
    -- 还没完成登录
    if not playerid then
        return
        -- 已在游戏中
    else
        players[playerid] = nil
        local reason = "断线"
        skynet.call("agentmgr", "lua", "reqkick", playerid, reason)
    end
end



-- 有新连接时
local connect = function(fd, addr)
    print("connect from " .. addr .. " " .. fd)
    local c = getconn()
    conns[fd] = c
    c.fd = fd
    skynet.fork(recv_loop, fd)
end

function service.init()
    skynet.error("[start]" .. service.name .. service.id)
    local node = skynet.getenv("node")
    local nodecfg = runconfig[node]
    local port = nodecfg.gateway[s.id].port

    local listenfd = socket.listen("0.0.0.0", port)
    skynet.error("Listen socket :", "0.0.0.0", port)
    socket.start(listenfd, connect)
end

service.start(name, id)
