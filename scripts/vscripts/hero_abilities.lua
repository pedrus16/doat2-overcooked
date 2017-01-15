function Interact( key )

	local caster = key.caster

	if caster == nil then return end
	if caster.heldItem then return end

	local units = FindUnitsInFront(caster)

	for _,unit in pairs(units) do
		if unit:FindModifierByName('modifier_anvil') then
			local anvil = unit
			local hHammerAbility = anvil:FindAbilityByName('anvil_hammer')
			anvil:CastAbilityOnTarget(caster, hHammerAbility, caster:GetPlayerID())
			return
		end
	end

end

function FindUnitsInFront( caster )

	local team = caster:GetTeam()
	local vStartPos = caster:GetAbsOrigin() + caster:GetForwardVector() * 100
	local vEndPos = vStartPos + caster:GetForwardVector() * 50
	local radius = 50
	local teams = DOTA_UNIT_TARGET_TEAM_BOTH
	local types = DOTA_UNIT_TARGET_ALL
	local flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE

	DebugDrawCircle(vStartPos, Vector(255, 255, 255), 0, radius, true, 0.5)

	return FindUnitsInRadius(team, vStartPos, caster, radius, teams, types, flags, FIND_CLOSEST, false)

end