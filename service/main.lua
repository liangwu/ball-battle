local skynet = require "skynet"
local runconfig = require "runconfig"

local server_id = 0

local function gen_id()
	local id = server_id
	server_id = server_id + 1
	return id
end


skynet.start(function()
    --初始化
	local node = skynet.getenv("node")
	local nodeconf = assert(runconfig[node])
	
    skynet.error("[start main]")
    skynet.newservice("gateway", "gateway", 1)
	for k, _ in pairs(nodeconf.login) do
		local address = skynet.newservice("login", "login", k)
	end
	
    
    --退出自身
    skynet.exit()
end)