sig_scripts = {
	-- sig scripts
	message = "Sig scripts loaded",
	lootmessage = "Waiting for new log",
	combatmessage = "Waiting for new log",
	movementmessage = "Waiting for new log",
	useitemTime = GetTimeEX(),
	tryAgainTime = GetTimeEX(),
	usingQuestItem = false,
	rotationRunning = false,
	usetaunt = true,
	usemockingblow = false,
	lastTargetGuid = GetLocalPlayer():GetGUID(),
	tauntEnemy = GetLocalPlayer():GetGUID()
}

function sig_scripts:tauntInhealer()
	------------------------
	-- Taunt by SigWar
	------------------------
	local needTaunt = sig_scripts:isAttakingHealer(); -- Returne object is attacking healer by name in script_follow
	if (needTaunt ~= nil and needTaunt ~= 0 and not GetLocalPlayer():IsMovementDisabed()) then
		
		local needTauntGuid = needTaunt:GetGUID();
		
		
		-- Check last target no more attaking healer before swap target
		if (needTauntGuid ~= self.lastTargetGuid and not sig_scripts:isInHealerBool(self.lastTargetGuid)) then
			self.lastTargetGuid = needTauntGuid;
			self.tauntEnemy = needTaunt;
			
			-- Change target
			ClearTarget();
			self.tauntEnemy:TargetEnemy();
		else
			self.tauntEnemy = GetGUIDObject(self.lastTargetGuid);
		end
		
		if (self.tauntEnemy ~= nil and self.tauntEnemy ~= 0) then
			if (self.tauntEnemy:GetDistance() > 2.5) then
				self.tauntEnemy:TargetEnemy();
				local x,y,z = self.tauntEnemy:GetPosition();
				script_follow:moveToTarget(localObj,x,y,z);
				-- return 0;
				return self.tauntEnemy;
			end -- move to member

			-- Mocking Blow
			if (self.usemockingblow and HasSpell('Mocking Blow') and not IsSpellOnCD('Mocking Blow')) then
				if (Cast('Mocking Blow', self.tauntEnemy)) then
					return nil;
				end
			-- Taunt
			elseif (self.usetaunt and HasSpell('Taunt')) then  -- and not IsSpellOnCD('Taunt') and localRageValor >= 5
				if (self.tauntEnemy:GetDistance() <= 2.5) then
					if (not localObj:HasBuff('Defensive Stance')) then CastSpellByName('Defensive Stance'); end
				end
				if (Cast('Taunt', self.tauntEnemy)) then
					-- if (not localObj:HasBuff(self.combatStance)) then CastSpellByName(self.combatStance); end
					return nil;
				end
			end
		end
	end
	return nil;
end

function getCreaturebyName(target)

	local creaturename = target:GetUnitName();
	
	for namelist in pairs(script_grind.creaturelist) do
        --  Check to see if you have the buff:
        if (namelist == creaturename) then
            return true;
        end
    end
	return false;
end

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

function sig_scripts:countTable(stringTable)
	local counter = 0;
	for index in pairs(self.stringTable) do
		counter = counter + 1;
	end
	return counter
end

function sig_scripts:GetPartyLeaderObject() -- Return a party lader Return: OBJECT
	if GetNumPartyMembers() > 0 then -- are we in a party?
		leaderObj = GetPartyMember(GetPartyLeaderIndex());
		if (leaderObj ~= nil) then
			return leaderObj;
		end
	end
	return 0;
end

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

function sig_scripts:useItemLeaderTarget()

	if (self.useitemTime > GetTimeEX()) then
		return true;
	end
	
	local questItemName = script_follow.questItemName;
	-- local lista = { strsplit(',', script_follow.objectiveName) };
	local objTarget = 0;
	local lista = {'Dying Kodo','Ancient Kodo','Aged Kodo',};
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

function sig_scripts:isInHealerBool(targetGuid) -- Return boll if passed GUID is attacking healer: BOOL
	local target = GetGUIDObject(targetGuid);
	if (target ~= nil and target ~= 0) then
		local targetofTarget = target:GetUnitsTarget();
		if (targetofTarget ~= nil and targetofTarget ~= 0) then
			if (targetofTarget:GetUnitName() == script_follow.HealerName) then
				return true;
			end
		end
	end	
	return false;
end

function sig_scripts:CalculateDistance(unit,otherUnit)
	local _lx, _ly, _lz = unit:GetPosition();
	local _2x, _2y, _2z = otherUnit:GetPosition();
	local Distance = GetDistance3D(_lx, _ly, _lz, _2x, _2y, _2z);
	return Distance;
end

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
