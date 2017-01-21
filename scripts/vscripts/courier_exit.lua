function CourierExit( trigger )

	local courier = trigger.activator

	if courier == nil then return end

	GameRules:GetGameModeEntity().OvercookedGameMode:CheckOrder(courier)
end