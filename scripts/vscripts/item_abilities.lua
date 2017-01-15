local ITEM_BASECLASS = 'npc_dota_earth_spirit_stone'

function PickUpItem( key )

	local caster = key.caster

	if caster == nil then return end
	if caster.heldItem then return end

	local units = FindUnitsInFront(caster)

	for _,unit in pairs(units) do
		if unit:FindModifierByName('modifier_item') then
			local item = unit
			local attachmentAttack = caster:ScriptLookupAttachment('attach_attack1')
			local vAttachmentAngles = caster:GetAttachmentAngles(attachmentAttack)
			local vAttachmentOrigin = caster:GetAttachmentOrigin(attachmentAttack)

			if item.holder then 
				local holder = item.holder
				local ability = holder:FindAbilityByName('ability_anvil')
				ability:ApplyDataDrivenModifier(holder, holder, 'modifier_anvil_disable', {})
				holder:RemoveModifierByName('modifier_anvil_active')
				holder.heldItem = nil 
			end
			item.holder = caster
			item:SetAngles(vAttachmentAngles.x, vAttachmentAngles.y, vAttachmentAngles.z)
			item:SetOrigin(vAttachmentOrigin)
			item:SetParent(caster, 'attach_attack1')
			caster.heldItem = item

			caster:SwapAbilities('drop_item', 'pickup_item', true, false)
			return
		end
	end

end

function DropItem( key )

	local caster = key.caster

	if caster == nil then return end
	if caster.heldItem == nil then return end

	local item = caster.heldItem
	local vDropPos = caster:GetAbsOrigin() + caster:GetForwardVector() * 50
	local angles = caster:GetAnglesAsVector()


	caster:SwapAbilities('pickup_item', 'drop_item', true, false)
	caster.heldItem = nil

	-- Look for a place to put the item
	local units = FindUnitsInFront(caster)
	for _,unit in pairs(units) do
		if unit:FindModifierByName('modifier_anvil') and unit.heldItem == nil then
			local anvil = unit
			local vAnvilAngles = anvil:GetAnglesAsVector()
			local vAnvilOrigin = anvil:GetAbsOrigin()

			item:SetAngles(vAnvilAngles.x, vAnvilAngles.y, vAnvilAngles.z)
			item:SetOrigin(vAnvilOrigin + Vector(0,0,128))
			item:SetParent(anvil, nil)
			item.holder = anvil
			anvil.heldItem = item

			local ability = anvil:FindAbilityByName('ability_anvil')
			ability:ApplyDataDrivenModifier(anvil, anvil, 'modifier_anvil_active', {})
			item.holder:RemoveModifierByName('modifier_anvil_disable')

			return
		end
	end

	-- No place found, dropping it on the ground
	item.holder = nil
	item:SetParent(nil, nil)
	item:SetAngles(angles.x, angles.y, angles.z)
	FindClearSpaceForUnit(item, vDropPos, true)

end

function FindUnitsInFront( caster )

	local team = caster:GetTeam()
	local vStartPos = caster:GetAbsOrigin() + caster:GetForwardVector() * 50
	local vEndPos = vStartPos + caster:GetForwardVector() * 50
	local radius = 50
	local teams = DOTA_UNIT_TARGET_TEAM_BOTH
	local types = DOTA_UNIT_TARGET_ALL
	local flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE

	DebugDrawCircle(vStartPos, Vector(255, 255, 255), 0, radius, true, 0.5)

	return FindUnitsInRadius(team, vStartPos, caster, radius, teams, types, flags, FIND_CLOSEST, false)

end