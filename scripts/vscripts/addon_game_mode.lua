local ORDER_RATE = 10

local orders = {
	{
		items = { 'item_tango' },
		duration = 30
	},
	{
		items = { 'item_branches' },
		duration = 30
	},
	{
		items = { 'item_branches', 'item_branches', 'item_branches' },
		duration = 30
	},
	{
		items = { 'item_tango', 'item_branches', 'item_branches', 'item_branches' },
		duration = 30
	},
}

if OvercookedGameMode == nil then
	OvercookedGameMode = class({})
end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

-- Create the game mode when we activate
function Activate()
	-- OvercookedGameMode()
	OvercookedGameMode:InitGameMode()
end

function OvercookedGameMode:InitGameMode()
	print( "Overcooked addon is loaded." )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 1)
	GameRules:GetGameModeEntity():SetCustomGameForceHero('npc_dota_hero_axe')
	GameRules:LockCustomGameSetupTeamAssignment(true)
	GameRules:SetCustomGameSetupAutoLaunchDelay(0)
	GameRules:SetPreGameTime(30)
	GameRules:GetGameModeEntity().OvercookedGameMode = self

	self.currentOrders = {}

	CustomNetTables:SetTableValue( "overcooked", "orders", self.currentOrders )

	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( OvercookedGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "dota_player_pick_hero", Dynamic_Wrap( OvercookedGameMode, "OnPlayerPickHero" ), self )

end

-- Evaluate the state of the game
function OvercookedGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		
	self:PurgeOverdueOrders()
	if self:ShouldGenerateOrder() then
		self:GenerateOrder()
	end
	self:SpawnCourier()

	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end


function OvercookedGameMode:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() then
		return
	end

	if spawnedUnit:IsRealHero() then
		spawnedUnit:AddItemByName("item_branches")
		spawnedUnit:AddItemByName("item_branches")
		spawnedUnit:AddItemByName("item_tango")
	end
end

function OvercookedGameMode:OnPlayerPickHero( event )
	local hero = EntIndexToHScript(event.heroindex)
	local playerID = hero:GetPlayerID()

	local unit = Entities:FindByName(nil, "npc_dota_creature")
	while unit do
		unit:SetOwner(hero)
		unit:SetControllableByPlayer(playerID, true)
		unit = Entities:FindByName(unit, "npc_dota_creature")
	end
end

function OvercookedGameMode:ShouldGenerateOrder()
	
	if #self.currentOrders >= 5 then return false end

	if self.startTime == nil then
		self.startTime = GameRules:GetGameTime()
	end
	local delta = self.startTime - GameRules:GetGameTime()
	if math.floor(delta % ORDER_RATE) == 0 then
		return true
	end
	return false
end

function OvercookedGameMode:GenerateOrder()

	print('Generate Order')

	local newOrder = {
		content = orders[RandomInt(1, #orders)],
		start_time = GameRules:GetGameTime()
	}
	table.insert(self.currentOrders, newOrder)
	CustomNetTables:SetTableValue( "overcooked", "orders", self.currentOrders )
end

function OvercookedGameMode:PurgeOverdueOrders()

	local validOrders = {}

	for key, order in pairs(self.currentOrders) do
		if GameRules:GetGameTime() < (order.start_time + order.content.duration) then
			table.insert(validOrders, order)
		end
	end

	self.currentOrders = validOrders

	CustomNetTables:SetTableValue( "overcooked", "orders", self.currentOrders );

end

function OvercookedGameMode:CheckOrder( courier )

	local fail = true

	for key, order in pairs(self.currentOrders) do
		local orderItems = order.content.items
		local courierInventory = {}

		for i=1,6 do
			local item = courier:GetItemInSlot(i-1)
			if item then
				table.insert(courierInventory, item:GetName())
			end
		end
		if AreTablesEqual(order.content.items, courierInventory) then
			GameRules:SendCustomMessage('Order completed!', 0, 1)
			fail = false
			table.remove(self.currentOrders, key)
			CustomNetTables:SetTableValue( "overcooked", "orders", self.currentOrders );
			break
		end
	end

	if fail then
		GameRules:SendCustomMessage('Order fail!', 0, 1)
	end

	courier:Destroy()

end

function AreTablesEqual(t1, t2)

	if #t1 ~= #t2 then return false end

	DeepPrintTable(t2)

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

function OvercookedGameMode:SpawnCourier()

	local spawner = Entities:FindByClassname(nil, "info_courier_spawn")

	if spawner == nil then return end

	local units = FindUnitsInRadius(spawner:GetTeam(), 
									spawner:GetAbsOrigin(), 
									nil, 
									32, 
									DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
									DOTA_UNIT_TARGET_ALL, 
									DOTA_UNIT_TARGET_FLAG_NONE, 
									FIND_ANY_ORDER,
									false)
	for _, unit in pairs(units) do
		if unit:GetUnitName() == 'npc_unit_courier' then return end
	end	

	local playerID = 0
	local player = PlayerResource:GetPlayer(playerID)
	local courier = CreateUnitByName('npc_unit_courier', spawner:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)

end