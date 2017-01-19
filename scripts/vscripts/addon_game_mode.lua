-- Generated from template

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
	GameRules.gamemode = OvercookedGameMode()
	GameRules.gamemode:InitGameMode()
end

function OvercookedGameMode:InitGameMode()
	print( "Overcooked addon is loaded." )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
	GameRules:GetGameModeEntity():SetCustomGameForceHero('npc_dota_hero_axe')
	GameRules:LockCustomGameSetupTeamAssignment(true)
	GameRules:SetCustomGameSetupAutoLaunchDelay(0)
	GameRules:SetPreGameTime(0)

	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( OvercookedGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "dota_player_pick_hero", Dynamic_Wrap( OvercookedGameMode, "OnPlayerPickHero" ), self )
	
end

-- Evaluate the state of the game
function OvercookedGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "Template addon script is running." )
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
	else
		print(spawnedUnit:GetUnitName())
		spawnedUnit:SetControllableByPlayer(0, false)
	end
end

function OvercookedGameMode:OnPlayerPickHero( event )
	local hero = EntIndexToHScript(event.heroindex)
	local playerID = hero:GetPlayerID()

	-- local couriers = Entities:FindAllByName("npc_unit_courier")	

	-- local unit = Entities:FindByName(nil, 'npc_dota_creature')
	-- print("-----------------------------------------")
	-- while unit do
	-- 	print(unit:GetUnitName())
	-- 	print(playerID)
	-- 	unit:SetOwner(hero)
	-- 	unit:SetControllableByPlayer(playerID, true)
	-- 	print(unit:IsControllableByAnyPlayer())
	-- 	unit:SetHasInventory(true)
	-- 	unit = Entities:FindByName(unit, 'npc_dota_creature')
	-- end

	-- for _, courier in pairs(couriers) do
	-- 	print('UNIT')
	-- 	print(courier:GetUnitName())
	-- end
end