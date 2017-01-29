function OpenMenu( trigger )

	local hero = trigger.activator
	if hero == nil then return end
	local player = hero:GetPlayerOwner()
	local dispensers = Entities:FindAllByClassname("npc_dota_creature")

	for _, ent in pairs(dispensers) do
		if ent:GetUnitName() == "npc_unit_dispenser_attribute" then
			CustomGameEventManager:Send_ServerToPlayer( player, "dispenser_activate", { entity_index = ent:GetEntityIndex() } )
		end
	end

end