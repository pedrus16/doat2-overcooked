function SetControllableByEveryone( key ) 

	local courier = key.caster
	local team = courier:GetTeam()
	local playerCount = PlayerResource:GetPlayerCountForTeam(team)

	for i=1, playerCount do
		local playerID = PlayerResource:GetNthPlayerIDOnTeam(team, i)
		courier:SetControllableByPlayer(playerID, true)
	end

end