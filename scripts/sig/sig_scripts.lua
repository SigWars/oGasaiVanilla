sig_scripts = {
	-- sig scripts
	debuffableSpells = {"Spell1","Spell2"},
	debuffableCurses = {"Course1","Course2"}
}
--------------------
-- Count Spell table
function sig_scripts:countTable(stringTable)
	local counter = 0;
	for index in pairs(self.stringTable) do
		counter = counter + 1;
	end
	return counter
end
---------------------
-- Debuffs
function sig_scripts:isSpellDebuffable(spellName) 
	for i=0,sig_scripts:countTable(self.debuffableSpells) do
		if (spellName == self.debuffableSpells[i]) then
			return true;
		end
	end
	return false;
end

function sig_scripts:isCurseDebuffable(curseName) 
	for i=0,sig_scripts:countTable(self.debuffableCurses) do
		if (curseName == self.debuffableCurses[i]) then
			return true;
		end
	end
	return false;
end
----------------------------------------
-- PARTY FUNCTIONS
----------------------------------------
function sig_scripts:GetPartyLeaderObject() 
	if GetNumPartyMembers() > 0 then -- are we in a party?
		leaderObj = GetPartyMember(GetPartyLeaderIndex());
		if (leaderObj ~= nil) then
			return leaderObj;
		end
	end
	return 0;
end
----------------------------------------
-- AREA FUNCTIONS
----------------------------------------
function sig_scripts:isAreaNearTargetSafe(target) 
	local localObj = GetLocalPlayer();
	local countUnitsInRange = 0;
	local currentObj, typeObj = GetFirstObject();
	local aggro = 0;
	local tx, ty, tz = target:GetPosition();
	local cx, cy, cz = 0, 0, 0;

	while currentObj ~= 0 do
 		if (typeObj == 3 and currentObj:GetGUID() ~= target:GetGUID()) then
			aggro = currentObj:GetLevel() - localObj:GetLevel() + 21;
			cx, cy, cz = currentObj:GetPosition();
			if currentObj:CanAttack() and not currentObj:IsDead() and not currentObj:IsCritter() and GetDistance3D(tx, ty, tz, cx, cy, cz) <= aggro then	
				countUnitsInRange = countUnitsInRange + 1;
 			end
 		end
 		currentObj, typeObj = GetNextObject(currentObj);
 	end

	-- avoid pull if more than 1 add
	if (countUnitsInRange > 1) then
		return false;
	end

	return true;
end
----------------------------------------
-- TARGETING FUNCTIONS
----------------------------------------

function sig_scripts:isTargetingGroup(y) 
-- usage:
-- local result, pguiD =  sig_scripts:isTargetingGroup(EnemyObject);

	for i = 1, GetNumPartyMembers() do
		local partyMember = GetPartyMember(i);
		if (partyMember ~= nil and partyMember ~= 0 and not partyMember:IsDead()) then
			if (y:GetUnitsTarget() ~= nil and y:GetUnitsTarget() ~= 0 and not script_grind:isTargetingPet(y)) then
				return y:GetUnitsTarget():GetGUID() == partyMember:GetGUID(),  partyMember;
			end
		end
	end

	return false, nil;
end

function sig_scripts:needTaunt(range)
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
		
		local result, pguiD =  sig_scripts:isTargetingGroup(currentObj);
    	
		if (typeObj == 3 and not currentObj:IsDead()) then
			if (currentObj:GetDistance() < range and result and not script_follow:isTargetingMe(currentObj)) then 
				return currentObj;
			end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return 0;
end

-- DISTANCE FUNCTIONS
function sig_scripts:CalculateDistance(unit,otherUnit)
	local _lx, _ly, _lz = unit:GetPosition();
	local _2x, _2y, _2z = otherUnit:GetPosition();
	local Distance = GetDistance3D(_lx, _ly, _lz, _2x, _2y, _2z);
	return Distance;
end

--MISC FUNCTION NOT WORK
function sig_scripts:IsUsableAction(SpellName) 
	for z=1,172 do 
		local isUsable, _ = IsUsableAction(z);
		if (isUsable == 1) then 
			if (GetActionText(Z) == SpellName and not IsSpellOnCD(SpellName)) then
				return true;
			end
		end
	end
	return false;
end

-- core menu uses ti set base menu
function sig_scripts:loadclass()
	-- Load combat menu by class
	local class = UnitClass("player");
		if (class == 'Mage') then
			script_mage:menu();
		elseif (class == 'Hunter') then
			script_hunter:menu();
		elseif (class == 'Warlock') then
			script_warlock:menu();
		elseif (class == 'Paladin') then
			script_paladin:menu();
		elseif (class == 'Druid') then
			script_druid:menu();
		elseif (class == 'Priest') then
			script_priest:menu();
			script_priest_shadow:menu();
		elseif (class == 'Warrior') then
			script_warrior:menu();
		elseif (class == 'Rogue') then
			script_rogue:menu();
		elseif (class == 'Shaman') then
			script_shaman:menu();
	end
end

-- teste
function sig_scripts:setRegenVar()
	if (GetNumPartyMembers() > 1) then
		return 1;
	else
		return 50;
	end
end

function sig_scripts:classVars(arg)
	-- Load combat menu by class
	local class = UnitClass("player");
	
	if (class == 'Mage' or class == 'Hunter' ) then
		if (arg == "minFollowDist") then return 12; end
		if (arg == "maxFollowDist") then return 16; end
		if (arg == "dpsHp") then return 99; end
	
	elseif (class == 'Warlock' or class == 'Priest') then
		if (arg == "minFollowDist") then return 8; end
		if (arg == "maxFollowDist") then return 12; end
		if (arg == "dpsHp") then return 99; end	
	
	elseif (class == 'Paladin' or class == 'Warrior' or class == 'Rogue') then
		if (arg == "minFollowDist") then return 4; end
		if (arg == "maxFollowDist") then return 7; end
		if (arg == "dpsHp") then return 99; end		
	
	elseif (class == 'Druid' or class == 'Shaman') then
		if (arg == "minFollowDist") then return 6; end
		if (arg == "maxFollowDist") then return 10; end
		if (arg == "dpsHp") then return 95; end
	end
end

function sig_scripts:randomgatherMsg()
	
	local rand = math.random(9);
	
	if (rand == 1) then
		return "catar essa besteirinha aqui";
	elseif (rand == 2) then
		return "pera pera outra besteirinha aqui";
	elseif (rand == 3) then
		return "achei outra";
	elseif (rand == 4) then
		return "aqui tem +1";
	elseif (rand == 6) then
		return "opa";
	elseif (rand == 7) then
		return "tem outro aqui";
	elseif (rand == 8) then
		return "espera";
	elseif (rand == 9) then
		return "ai sim";		
	end
end

function sig_scripts:coreloadclass()
		-- add to core menu
		local class = UnitClass("player");
		
		if (class == 'Mage') then
			LoadScript("Frostbite - Mage", "scripts\\combat\\script_mage_frostbite.lua");
			AddScriptToCombat("Frostbite - Mage", "script_mage");
			
		elseif (class == 'Hunter') then
			LoadScript("Beastmaster - Hunter", "scripts\\combat\\script_hunter_beastmaster.lua");
			AddScriptToCombat("Beastmaster - Hunter", "script_hunter");
			
		elseif (class == 'Warlock') then
			LoadScript("Shadowmaster - Warlock", "scripts\\combat\\script_warlock_shadowmaster.lua");
			AddScriptToCombat("Shadowmaster - Warlock", "script_warlock");
			
		elseif (class == 'Paladin') then
			LoadScript("Ret - Paladin", "scripts\\combat\\script_paladin_ret.lua");
			AddScriptToCombat("Ret - Paladin", "script_paladin");
			
		elseif (class == 'Druid') then
			LoadScript("Feral - Druid", "scripts\\combat\\script_druid_feral.lua");
			AddScriptToCombat("Feral - Druid", "script_druid");
			
		elseif (class == 'Priest') then
			-- Discipline
			LoadScript("Disc - Priest", "scripts\\combat\\script_priest_disc.lua");
			AddScriptToCombat("Disc - Priest", "script_priest");
			-- Shadow
			LoadScript("Shadow - Priest", "scripts\\combat\\script_priest_shadow.lua");
			AddScriptToCombat("Shadow - Priest", "script_priest_shadow");
			
		elseif (class == 'Warrior') then
			LoadScript("Fury - Warrior", "scripts\\combat\\script_warrior_fury.lua");
			AddScriptToCombat("Fury - Warrior", "script_warrior");
			
		elseif (class == 'Rogue') then
			LoadScript("Hidden - Rogue", "scripts\\combat\\script_rogue_hidden.lua");
			AddScriptToCombat("Hidden - Rogue", "script_rogue");
			
		elseif (class == 'Shaman') then
			LoadScript("Enhance - Shaman", "scripts\\combat\\script_shaman_enhance.lua");
			AddScriptToCombat("Enhance - Shaman", "script_shaman");
	end

end	