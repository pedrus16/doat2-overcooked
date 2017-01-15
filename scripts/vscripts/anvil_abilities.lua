function Hammer( key )
	
	local caster = key.caster
	local target = key.target

	if caster == nil then return end
	if target == nil or target:GetUnitName() ~= 'npc_unit_anvil' then return end

	local item = target.heldItem

	if item == nil then return end

	print(item:GetUnitName())
end