sig_class_especifics = {

}

function sig_class_especifics:classSpecifics()
	local class = UnitClass("player");
	local meObj = GetLocalPlayer();
	
	if (class == 'Shaman') then
		-- Totems
		local emcombat = sig_scripts:searchingTarget(100);
		if (emcombat ~= nil and emcombat ~= 0) then
			local x, y, z = emcombat:GetPosition();
			
			if (emcombat:GetDistance() > 20) then
				script_follow:moveToTarget(GetLocalPlayer(),x,y,z);
				return true;
			else
				if (IsMoving()) then StopMoving(); end
			end
			emcombat:FaceTarget();
			
			--[[
			for i = 1, GetNumPartyMembers() do
				local ptm = GetPartyMember(i);
				if (ptm:HasBuff(script_shaman.totemBuff) and HasSpell(script_shaman.totem3) and not ptm:HasBuff(script_shaman.totemBuff3)) then
					CastSpellByName(script_shaman.totem3);
				end
				
			end
			]]--
			
			local haveWFtotem = sig_scripts:getTargetInRangeByName("Windfury Totem", 20)
			if (not (haveWFtotem ~= nil and haveWFtotem ~= 0)) then
				CastSpellByName(script_shaman.totem3);
			end
			
			-- Totem 2
			if (HasSpell(script_shaman.totem2) and not meObj:HasBuff(script_shaman.totemBuff2)) then
				CastSpellByName(script_shaman.totem2);
				-- script_shaman.waitTimer = GetTimeEX() + 1500;
			end
			
			-- Totem 1
			if (HasSpell(script_shaman.totem) and not meObj:HasBuff(script_shaman.totemBuff)) then
				CastSpellByName(script_shaman.totem);
				-- script_shaman.waitTimer = GetTimeEX() + 1500;
			end
			return true;
		end
	end	
	
	return false;
end