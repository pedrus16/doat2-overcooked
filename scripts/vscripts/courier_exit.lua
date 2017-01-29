function CourierExit( trigger )

	local courier = trigger.activator

	if courier == nil then return end

	local courierInventory = {}
	for i=1,6 do
		local item = courier:GetItemInSlot(i-1)
		if item then
			table.insert(courierInventory, item:GetName())
		end
	end

	GameRules.overcooked.currentRound:CheckForMatchingOrder(courierInventory)
	courier:Destroy()
end