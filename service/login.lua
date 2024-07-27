local skynet = require "skynet"
local socket = require "skynet.socket"
local runconfig = require "runconfig"
local service = require "service"

local name, id = ...


function service.commonds.login(fd, msg)
	if not fd then
		skynet.error("fd is nil")
		return false
	end
	print(msg)
	local playerid = msg[3]
	local password = msg[4]
	if not playerid or not password then
		socket.write(fd, "login,账号或密码错误\r\n");
		return false
	end

	local node = skynet.getenv("node")
	local isok, agent = skynet.call("agentmgr", "lua", "login", playerid, password)
	if not isok then
		socket.write(fd, "login,登录错误\r\n");
		return false
	end



end


function service.init()
	service.type = "login"
end

service.start(name, id)