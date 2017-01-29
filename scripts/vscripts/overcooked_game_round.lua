--[[
	COvercookedGameRound - A single round of Overcooked
]]

if COvercookedGameRound == nil then
	COvercookedGameRound = class({})
end

ROUND_DEFAULT_DURATION = 120
ROUND_DEFAULT_ORDER_INTERVAL = 5

function COvercookedGameRound:ReadConfiguration( kv, gameMode, roundNumber )

	self._gameMode = gameMode
	self._nRoundNumber = roundNumber
	self._szRoundTitle = kv.round_title or string.format( "Round%d", roundNumber )

	self._fDuration = tonumber(kv.Duration or ROUND_DEFAULT_DURATION)
	self._fOrderInterval = tonumber(kv.OrderInterval or ROUND_DEFAULT_ORDER_INTERVAL)

	self.orderPool = {}
	for k, v in pairs( kv ) do
		if type( v ) == "table" and v.Items then
			local order = COvercookedGameOrder()
			order:ReadConfiguration( k, v, self )
			table.insert(self.orderPool, order)
		end
	end

end

function COvercookedGameRound:Begin()

	print("Round " .. self._nRoundNumber .. " Begin")

	self._fStartTime = GameRules:GetGameTime()
	self._fNextOrderTime = self._fStartTime
	self.currentOrders = {}

end

function COvercookedGameRound:Think()

	if self._fStartTime ~= nil then

		if GameRules:GetGameTime() >= self._fStartTime + self._fDuration then
			self:End()
			return
		end
		self:PurgeOverdueOrders()
		if not self._fNextOrderTime then
			return 
		end
		if GameRules:GetGameTime() >= self._fNextOrderTime then
			self:CreateRandomOrder()
			self._fNextOrderTime = GameRules:GetGameTime() + self._fOrderInterval
		end

	end

end

function COvercookedGameRound:End()

	print("Round " .. self._nRoundNumber .. " End")

end

function COvercookedGameRound:IsFinished()

	return GameRules:GetGameTime() >= self._fStartTime + self._fDuration

end

function COvercookedGameRound:CreateRandomOrder()

	local order = {
		model = self.orderPool[RandomInt(1, #self.orderPool)],
		start_time = GameRules:GetGameTime()
	}
	table.insert(self.currentOrders, order)
	self._gameMode:SendOrderToClient(order)
end

function COvercookedGameRound:PurgeOverdueOrders()

	local validOrders = {}

	for key, order in pairs(self.currentOrders) do
		if not order.model:IsOverdue(order.start_time) then
			table.insert(validOrders, order)
		end
	end

	self.currentOrders = validOrders

end

function COvercookedGameRound:PurgeCompleteOrders()

	local validOrders = {}

	for key, order in pairs(self.currentOrders) do
		if not order.complete then
			table.insert(validOrders, order)
		end
	end

	self.currentOrders = validOrders

end

function COvercookedGameRound:CheckForMatchingOrder( items )

	local order = self:FindOrderMatch(items)

	if order then
		GameRules:SendCustomMessage('Order completed!', 0, 1)
		self:CompleteOrder(order)
	else
		GameRules:SendCustomMessage('Order failed!', 0, 1)
	end

end

function COvercookedGameRound:FindOrderMatch( items )

	local fail = true

	for key, order in pairs(self.currentOrders) do
		if order.model:ItemsMatch(items) then
			return order
		end
	end

	return false

end

function COvercookedGameRound:CompleteOrder( order )
	order.complete = true
	self:PurgeCompleteOrders()
	self._gameMode:NotifyClientOfCompleteOrder(order)
end