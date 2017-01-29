--[[
	COvercookedGameOrder - A single order for Overcooked
]]

if COvercookedGameOrder == nil then
	COvercookedGameOrder = class({})
end

ORDER_DEFAULT_DURATION = 30

function COvercookedGameOrder:ReadConfiguration( name, kv, gameRound )

	self._gameRound = gameRound

	self._fDuration = tonumber(kv.Duration or DEFAULT_DURATION)
	self._items = {}
	for k, v in pairs( kv.Items ) do
		table.insert(self._items, v)
	end

end

function COvercookedGameOrder:IsOverdue( startTime )

	return GameRules:GetGameTime() >= (startTime + self._fDuration)

end

function COvercookedGameOrder:GetDuration()
	return self._fDuration
end

function COvercookedGameOrder:GetItems()
	return self._items
end

function COvercookedGameOrder:ItemsMatch( items )
	return TableEqual(self._items, items)
end

function TableEqual(t1, t2)

	if #t1 ~= #t2 then return false end

	for _, val1 in pairs(t1) do
		local indexOf = -1
		for key, val2 in pairs(t2) do
			if val1 == val2 then
				indexOf = key
				break
			end
		end
		if indexOf == -1 then return false end
		table.remove(t2, indexOf)
	end

	return true

end