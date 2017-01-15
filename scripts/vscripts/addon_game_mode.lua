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
	PrecacheItemByNameSync( "item_pickable", context )
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
		local pickupAbility = spawnedUnit:FindAbilityByName('pickup_item')
		spawnedUnit:UpgradeAbility(pickupAbility)

		local interactAbility = spawnedUnit:FindAbilityByName('interact')
		spawnedUnit:UpgradeAbility(interactAbility)

		local dropAbility = spawnedUnit:FindAbilityByName('drop_item')
		spawnedUnit:UpgradeAbility(dropAbility)

		local hammerAbility = spawnedUnit:FindAbilityByName('anvil_hammer')
		spawnedUnit:UpgradeAbility(hammerAbility)

		-- spawnedUnit:SwapAbilities('pickup_item', 'drop_item', true, false)
	end
end