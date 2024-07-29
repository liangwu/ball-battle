local skynet = require "skynet"
local service = require "service"


STATUS = {
    LOGIN = 2,
    GAME = 3,
    LOGOUT = 4,
}


--玩家列表
local players = {
	playertable = {},
}

function players:createplayer(playerid)
	if type(playerid) ~= "integer" then
		skynet.error("playerid is not integer")
		return nil
	end
	playerid = tonumber(playerid)

	local player = {
        playerid = 0,
        node = nil,
        agent = nil,
        status = nil,
        gate = nil,
    }

	player.playerid = playerid
	self.playertable[playerid] = player

	return player
end

function players:getplayer(playerid)
	if type(playerid) ~= "integer" then
		skynet.error("playerid is not integer")
		return nil
	end
	return self.playertable[tonumber(playerid)]
end


function players:delplayer(playerid)
	if type(playerid) ~= "integer" then
		skynet.error("playerid is not integer")
		return false
	end
	self.playertable[tonumber(playerid)] = nil
	return true
end




function service.commonds.login(msg)
	
end