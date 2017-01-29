function COvercookedGameMode:SendOrderToClient( order )
	
	local netTable = {}

	netTable['start_time'] = order.start_time
	netTable['duration'] = order.model:GetDuration()
	netTable['items'] = order.model:GetItems()
	CustomGameEventManager:Send_ServerToTeam( DOTA_TEAM_GOODGUYS, "new_order", netTable )

end

function COvercookedGameMode:NotifyClientOfCompleteOrder( order )

	local netTable = {}

	netTable['start_time'] = order.start_time
	CustomGameEventManager:Send_ServerToTeam( DOTA_TEAM_GOODGUYS, "order_complete", netTable )

end