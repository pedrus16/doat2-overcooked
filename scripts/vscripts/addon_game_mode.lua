if COvercookedGameMode == nil then
	COvercookedGameMode = class({})
	_G.COvercookedGameMode = COvercookedGameMode
end

require("overcooked_game_round")
require("overcooked_game_order")
require("overcooked_game_ui")

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
	GameRules.overcooked = COvercookedGameMode()
	GameRules.overcooked:InitGameMode()
end

function COvercookedGameMode:InitGameMode()
	self.currentOrders = {}
	self.roundNumber = 1
	self.currentRound = nil

	CustomNetTables:SetTableValue( "overcooked", "orders", self.currentOrders )

	GameRules:SetCustomGameSetupTimeout( 0 ) 
	GameRules:SetCustomGameSetupAutoLaunchDelay( 0 )
	GameRules:GetGameModeEntity():SetCustomGameForceHero('npc_dota_hero_axe')
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 5 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )

	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		PlayerResource:SetCustomTeamAssignment( nPlayerID, DOTA_TEAM_GOODGUYS )
	end

	self:ReadGameConfiguration()

	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetHeroSelectionTime( 0.0 )
	GameRules:SetStrategyTime( 0.0 )
	GameRules:SetShowcaseTime( 0.0 )
	GameRules:SetPreGameTime( 1.0 )
	GameRules:SetPostGameTime( 45.0 )
	GameRules:SetGoldTickTime( 60.0 )
	GameRules:SetGoldPerTick( 0 )
	GameRules:GetGameModeEntity():SetDaynightCycleDisabled( true )

	GameRules:GetGameModeEntity():SetExecuteOrderFilter(Dynamic_Wrap( COvercookedGameMode, "OrderFilter" ), self)

	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( COvercookedGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "dota_player_pick_hero", Dynamic_Wrap( COvercookedGameMode, "OnPlayerPickHero" ), self )

	CustomGameEventManager:RegisterListener( "request_item", Dynamic_Wrap( COvercookedGameMode, "OnItemRequest" ))

	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 0.25)

	self.currentRound = self.rounds[self.roundNumber]
	self.currentRound:Begin()
end

function COvercookedGameMode:ReadGameConfiguration()

	local kv = LoadKeyValues( "scripts/maps/" .. GetMapName() .. ".txt" )
	kv = kv or {} -- Handle the case where there is not keyvalues file

	self.rounds = {}
	while true do
		local szRoundName = string.format("Round%d", #self.rounds + 1 )
		local kvRoundData = kv[ szRoundName ]
		if kvRoundData == nil then
			return
		end
		local roundObj = COvercookedGameRound()
		roundObj:ReadConfiguration( kvRoundData, self, #self.rounds + 1 )
		table.insert( self.rounds, roundObj )
	end

end

-- Evaluate the state of the game
function COvercookedGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		
		if self.currentRound ~= nil then
			self.currentRound:Think()
			if self.currentRound:IsFinished() then
				self:RoundFinished()
			end
		end

		self:SpawnCourier()

	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end

function COvercookedGameMode:RoundFinished()

	self.roundNumber = self.roundNumber + 1
	if self.roundNumber > #self.rounds then
		self.currentRound = nil	
		return
	end
	self.currentRound = self.rounds[self.roundNumber]
	self.currentRound:Begin()

end

function COvercookedGameMode:OrderFilter( table )

	local playerID = table.issuer_player_id_const
	-- CustomUI:DynamicHud_Destroy(playerID, "DispenserMenu")

	if table.order_type ~= DOTA_UNIT_ORDER_MOVE_TO_TARGET then return true end

	local targetID = table.entindex_target
	if targetID == 0 then return true end

	local target = EntIndexToHScript(targetID)
	
	if target:GetUnitName() ~= "npc_unit_dispenser_attribute" then return true end
	
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()

	if table.units['0'] ~= hero:GetEntityIndex() then return true end

	-- CustomUI:DynamicHud_Create(playerID, "DispenserMenu", "file://{resources}/layout/custom_game/overcooked_chest_context_menu.xml", {
	-- 	items = { "item_branches", "item_tango" } -- TODO Fetch items from the entity
	-- })
	
	return true

end

function COvercookedGameMode:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() then
		return
	end
end

function COvercookedGameMode:OnPlayerPickHero( event )
	local hero = EntIndexToHScript(event.heroindex)
	local playerID = hero:GetPlayerID()

	local unit = Entities:FindByName(nil, "npc_dota_creature")
	while unit do
		if unit:GetUnitName() == "npc_unit_courier" then
			unit:SetControllableByPlayer(playerID, true)
		end
		unit = Entities:FindByName(unit, "npc_dota_creature")
	end
end

function COvercookedGameMode:SpawnCourier()

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

function COvercookedGameMode:OnItemRequest( event )
	local playerID = event.PlayerID
	local item = event.name

	local hero = PlayerResource:GetSelectedHeroEntity(playerID)

	hero:AddItemByName(item)
	CustomUI:DynamicHud_Destroy(playerID, "DispenserMenu")
end
