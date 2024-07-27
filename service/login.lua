local skynet = require "skynet"
local socket = require "skynet.socket"
local runconfig = require "runconfig"
local service = require "service"

local name, id = ...

--[[
	msg = {
		[1] = "login",
		[2] = "login",
		[3] = playerid,
		[4] = password
	}
 --]]
function service.commonds.login(fd, msg)
	if not fd then
		skynet.error("fd is nil")
		return false
	end
	print(msg)
	local playerid = msg[3]
	local password = msg[4]
	if not playerid or not password then
		service:respClient(fd, false, "账号或密码错误")
		return false
	end

	local node = skynet.getenv("node")
	local isok, agent = skynet.call("agentmgr", "lua", "login", playerid, password)
	if not isok then
		service:respClient(fd, false, "登录错误")
		return false
	end

	local isok = skynet.call("gateway", "lua", "login", fd, playerid, password)
	if not isok then
		service:respClient(fd, false, "gateway错误")
		return false
	end

	return true
end


function service.init()
	service.type = "login"
end

service.start(name, id)