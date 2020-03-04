sig_scripts = {
	-- sig scripts
	message = "Sig scripts loaded",
	lootmessage = "Waiting for new log",
	combatmessage = "Waiting for new log",
	movementmessage = "Waiting for new log",
	
	debuffableSpells = {"Spell1","Spell2"},
	debuffableCurses = {"Course1","Course2"},
	useitemTime = GetTimeEX(),
	tryAgainTime = GetTimeEX(),
	usingQuestItem = false,
	rotationRunning = false,
}
--------------------
-- BAG SCRIPTS
function sig_scripts:UseContainerItemByName(search)
  for bag = 0,4 do
    for slot = 1,GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag,slot)
      if item and string.find(item,search) then
        UseContainerItem(bag,slot)
      end
    end
  end
end

function sig_scripts:GetItemQuantity(search)
  local itemCount = 0;
  for bag = 0,4 do
	for slot = 1,GetContainerNumSlots(bag) do
	  local item = GetContainerItemLink(bag,slot)
	  local _, stackCount = GetContainerItemInfo(bag,slot)
	  if item and string.find(item,search) then
		itemCount = itemCount + stackCount;
	  end
	end
  end
  return itemCount;
end

--------------------
-- Count tables to get total number of intem inside
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
function sig_scripts:GetPartyLeaderObject() -- Return a party lader Return: OBJECT
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
function sig_scripts:isAreaNearTargetSafe(target) -- check if no will agro near the target Return: BOOL
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
function sig_scripts:getTargetInRangeByName(unitname, range) -- Return a target by the name and range Return: OBJECT
	local targetObj, targetType = GetFirstObject();
	local bestTarget = nil;
	while targetObj ~= 0 do
		if (targetType == 3) then
			if(targetObj:GetUnitName() == unitname) then
				local dist = targetObj:GetDistance();
				if(dist < range) then
					local _x, _y, _z = targetObj:GetPosition();
					if(not IsNodeBlacklisted(_x, _y, _z, 5) and not script_grind:isTargetBlacklisted(targetObj:GetGUID())) then
						return targetObj;
					end
				end
			end
		end
		targetObj, targetType = GetNextObject(targetObj);
	end
	return targetObj;
end

function sig_scripts:searchingTarget(range)
	
	local g, targetType = GetFirstObject();
	while g ~= 0 do
		if ((targetType == 3 or targetType == 4) and not g:IsCritter() and not g:IsDead() and g:CanAttack() and g:GetDistance() < range) then
			if (
				 script_grind:isTargetingMe(g) or
				 script_grind:isTargetingGroup(g) or
				 script_grind:isTargetingPet(g) or
				 script_follow:isTargetMasterPet(g)
				) then
				sig_scripts.message = "Target:" .. tostring(g:GetUnitName()) .. " Found At:" .. math.floor(g:GetDistance()).. " Yrd's";
				return g;
			end
		end
		g, targetType = GetNextObject(g);
	end
	return nil;
end


-- USE ITEM ON PT LEADER TARGET
function sig_scripts:useItemLeaderTarget()

	if (self.useitemTime > GetTimeEX()) then
		return true;
	end
	
	local questItemName = script_follow.questItemName;
	local lista = { strsplit(',', script_follow.objectiveName) };
	local objTarget = 0;
	-- local lista = {'Dying Kodo','Ancient Kodo','Aged Kodo',};
	for i, unitname in ipairs(lista) do 
		local teste = script_follow.targetOfptLeader;
		if (teste ~= 0 and teste ~= nil) then
			if (script_follow.targetOfptLeader:GetUnitName() == unitname) then
				objTarget = teste;
				break;
			end	
		end	
	end
	
	if (objTarget ~= 0 and objTarget ~= nil and not script_grind:isTargetBlacklisted(objTarget:GetGUID())) then
		if(questItemName ~= 'None')then
			-- Follow
			if (objTarget:GetDistance() > 2) then
				local x, y, z = objTarget:GetPosition();
				script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
			else 
				
				-- Stop Move
				if(IsMoving()) then
					StopMoving();
				end
				
				-- Sets waittime before blacklist node Default:7000
				if (GetTimeEX() > self.tryAgainTime) then
					self.tryAgainTime = GetTimeEX() + 10000;
				end
				
				-- UseItem
				if (GetTimeEX() > self.tryAgainTime - 9000) then
					
					if (script_follow.ptLeader ~= nil and script_follow.ptLeader ~= 0) then
						ClearTarget();
						AssistByName(script_follow.ptLeader:GetUnitName());
					end
					-- TargetByName(objTarget:GetUnitName(), true);
					sig_scripts:UseContainerItemByName(questItemName);
					self.useitemTime = GetTimeEX() + 1000;
					DEFAULT_CHAT_FRAME:AddMessage(objTarget:GetUnitName());
				end	
				
				-- Try move back 
				if (GetTimeEX() > self.tryAgainTime - 8000) then
					-- script_follow:runBackwards(objTarget, 1);
				end
				
				
				-- Blacklist target
				if (GetTimeEX() > self.tryAgainTime - 1000) then
					-- Blacklist target
					if (not script_grind:isTargetBlacklisted(objTarget:GetGUID())) then
						self.message = 'Blackliting ' .. objTarget:GetGUID() .. ' Name: ' .. objTarget:GetUnitName();
						script_grind:addTargetToBlacklist(objTarget:GetGUID()); 
						self.tryAgainTime = GetTimeEX();
						ClearTarget();
					end 
				end
				
			end	
			self.usingQuestItem = true;
			return true;
		end	
	end
	self.usingQuestItem = false;
	return false;
end

-- USE ITEM ON OBJECT IN RANGE
function sig_scripts:usequestItem(range)

	if (self.useitemTime > GetTimeEX()) then
		return true;
	end
	
	local questItemName = script_follow.questItemName;
	local lista = { strsplit(',', script_follow.objectiveName) };
	local objTarget = 0;
	-- local lista = {'Dying Kodo','Ancient Kodo','Aged Kodo',};
	for i, unitname in ipairs(lista) do 
		
		local teste = sig_scripts:getTargetInRangeByName(unitname, range);
		if (teste ~= 0 and teste ~= nil) then
			objTarget = teste;
			-- ClearTarget();
			-- TargetByName(objTarget:GetUnitName());
			break;
		else
			objTarget = 0;
		end
	end	
	
	if (objTarget ~= 0 and objTarget ~= nil and not script_grind:isTargetBlacklisted(objTarget:GetGUID())) then
		if(questItemName ~= 'None')then
			-- Follow
			if (objTarget:GetDistance() > 2) then
				local x, y, z = objTarget:GetPosition();
				script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
			else 
				
				-- Stop Move
				if(IsMoving()) then
					StopMoving();
				end
				
				-- Sets waittime before blacklist node Default:7000
				if (GetTimeEX() > self.tryAgainTime) then
					self.tryAgainTime = GetTimeEX() + 10000;
				end
				
				-- UseItem
				if (GetTimeEX() > self.tryAgainTime - 9000) then
					
					if (script_follow.ptLeader ~= nil and script_follow.ptLeader ~= 0) then
						ClearTarget();
						AssistByName(script_follow.ptLeader:GetUnitName());
					end
					-- TargetByName(objTarget:GetUnitName(), true);
					sig_scripts:UseContainerItemByName(questItemName);
					self.useitemTime = GetTimeEX() + 1000;
					DEFAULT_CHAT_FRAME:AddMessage(objTarget:GetUnitName());
				end	
				
				-- Try move back 
				if (GetTimeEX() > self.tryAgainTime - 8000) then
					-- script_follow:runBackwards(objTarget, 1);
				end
				
				
				-- Blacklist target
				if (GetTimeEX() > self.tryAgainTime - 1000) then
					-- Blacklist target
					if (not script_grind:isTargetBlacklisted(objTarget:GetGUID())) then
						self.message = 'Blackliting ' .. objTarget:GetGUID() .. ' Name: ' .. objTarget:GetUnitName();
						script_grind:addTargetToBlacklist(objTarget:GetGUID()); 
						self.tryAgainTime = GetTimeEX();
						ClearTarget();
					end 
				end
				
			end	
			self.usingQuestItem = true;
			return true;
		end	
	end
	self.usingQuestItem = false;
	return false;
end

function sig_scripts:needTaunt(range) -- return a object in ranger if attacking group memeber and not targeting me. Return: OBJECT
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
		
		local result =  script_grind:isTargetingGroup(currentObj);
    	
		if (result and typeObj == 3 and not currentObj:IsDead()) then
			if (currentObj:GetDistance() < range and not script_follow:isTargetingMe(currentObj)) then 
				return currentObj;
			end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nil;
end

function sig_scripts:isAttakingGroup() -- Return a object is attacking group Return: OBJECT
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
		
		local result =  script_grind:isTargetingGroup(currentObj);
    	
		if (typeObj == 3 and not currentObj:IsDead()) then
			if (result) then 
				return currentObj;
			end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nil;
end

function sig_scripts:isAttakingHealer() -- Return a object is attacking group Return: OBJECT
	local currentObj, typeObj = GetFirstObject();
	local result = false;
	local objTarget = nil;
	while currentObj ~= 0 do 
		
		if (typeObj == 3) then
			result =  script_grind:isTargetingGroup(currentObj);
			objTarget = currentObj:GetUnitsTarget();
			if (result and not currentObj:IsDead()) then 
				if (objTarget ~= nil and objTarget ~= 0) then
					if (objTarget:GetUnitName() == script_follow.HealerName) then
						return currentObj;
					end
				end
			end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nil;
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
		if (arg == "maxFollowDist") then return 8; end
		if (arg == "dpsHp") then return 99; end		
	
	elseif (class == 'Druid' or class == 'Shaman') then
		if (arg == "minFollowDist") then return 6; end
		if (arg == "maxFollowDist") then return 12; end
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