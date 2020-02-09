RotationFramework = CreateFrame("Frame", "RotationFramework", UIParent);
RotationFramework:Show();
RotationFramework.throttle = 0;
--[[
RotationFramework:SetScript("OnUpdate", function()
	self = RotationFramework;
	elapsed = 1/GetFramerate();
	
	if (self.throttle >= 0.1) then
		self:RunRotation();
		self.throttle = 0;
	end
	
	self.throttle = self.throttle + elapsed;
end);]]

--[[
	Registers a table (list/array) of valid RotationStep objects
	This rotation will automatically be executed until unregistered
function RotationFramework:RegisterRotation(rotation)
	self.rotation = rotation;
end

function RotationFramework:UnregisterRotation()
	self.rotation = nil;
end
]]

function RotationFramework:RunRotation(rotation)
	if (rotation ~= nil) then
		-- convert table of unknown structure to table with numeric index, then sort by priority
		local sortedRotation = {};
		for k,v in pairs(rotation) do
			table.insert(sortedRotation, v);
		end
		table.sort(sortedRotation, function(a, b) return a.priority < b.priority end);
		
		for priority, step in pairs(sortedRotation) do
			-- restart rotation if action was sucessfully executed
			if (step:ExecuteStep()) then
				return;
			end
		end
	end
end

--[[
	Creates a rotation step to be used in the framework's rotation
	
	param: action - a RotationAction requiring methods Range():float and Execute():bool
	param: priority - float, sorting order, lowest to highest
	param: predicate - a function taking RotationAction and WoWUnit as targets, returning bool
	param: targetFinder - a function returning a WoWUnit (can be friendly) to execute action upon - this function takes a function as an argument that takes WoWUnit and returns bool
	param: force - a boolean indicating whether this can interrupt the currently casting spell
	param: rangeCheck - a boolean indicating whether we need to check the range for this action
]]
function RotationFramework:CreateStep(action, priority, predicate, targetFinder, force, rangeCheck)
	local step = {
		["action"] = action,
		["priority"] = priority,
		["predicate"] = predicate,
		["targetFinder"] = targetFinder or self.FindTarget,
		["force"] = force or false,
		["rangeCheck"] = rangeCheck or true,
	};
	
	step.ExecuteStep = function(self)
		
		local targetFinderPredicate = function(unit)
			return true
		end;
		
		if (self.rangeCheck) then
			local range = self.action:Range();
			targetFinderPredicate = function(unit)
				return unit:GetDistance() <= (range or 5);
			end
		end
		
		local target = self:targetFinder(targetFinderPredicate);
		if (target ~= 0 and target ~= nil and self.predicate(self.action, target)) then
			return self.action:Execute(target, self.force);
		end
		
		return false;
	end
	
	return step;
end

--[[
	A function returning the current target, if it is valid for the current RotationAction
	More functions like this could be implementing, iterating the ObjectManager and finding a valid target for blind, sap, polymorph or multi-dotting
	Similar functions could also return a friendly unit for buffs, the player himself, etc
]]
function RotationFramework:FindTarget(predicate)

	local target = GetTarget();	
	
	if (target == 0 or target == nil) then
		return nil;
	end
	
	if (predicate(target) and target:IsInLineOfSight()) then
		return target;
	end
	
	return nil;
end

function RotationFramework:FindPlayer(predicate)
	return GetLocalPlayer();
end

function RotationFramework:CreateRawAction(action, range)
	local rawAction = {};
	
	rawAction.Range = function(self)
		return range;
	end;
	
	rawAction.Execute = function(self, target, force)
		action();
	end
	
	return rawAction;
end

--[[
	Creates a spell object of type RotationAction
]]
function RotationFramework:CreateSpell(spellName, rank)
	local spell = { 
		["name"] = spellName,
		["rank"] = rank or 1,
		["luaRank"] = rank or 0,
		["rawRank"] = rank,
	};

	spell.NotEnoughMana = function(self)
		local i = 1
        local rank = self.luaRank;
        local lastIndex = 0;
        local lastRank = "Rank 1";
        while true do
            local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL);
            if not spellName then
                break;
            end
   
            -- use spellName and spellRank here
            if(spellName == self.name and (rank == 0 or (rank > 0 and (spellRank == "Rank " .. rank or spellRank == "" or spellRank == "Summon" or spellRank == "Shapeshift")))) then
                --DEFAULT_CHAT_FRAME:AddMessage("isUsable: "" .. spellName);
                lastIndex = i;
                lastRank = spellRank;
            end

            i = i + 1;
        end

        if (lastIndex ~= 0) then
            PickupSpell(lastIndex, BOOKTYPE_SPELL);
            PlaceAction(1);
            ClearCursor();
            local isUsable, notEnoughMana = IsUsableAction(1);
            return notEnoughMana;
        end
        
        return false;
	end
	
	spell.IsUsable = function(self)
		local i = 1
        local rank = self.luaRank;
        local lastIndex = 0;
        local lastRank = "Rank 1";
        while true do
            local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL);
            if not spellName then
                break;
            end
   
            -- use spellName and spellRank here
            if(spellName == self.name and (rank == 0 or (rank > 0 and (spellRank == "Rank " .. rank or spellRank == "" or spellRank == "Summon" or spellRank == "Shapeshift")))) then
                --DEFAULT_CHAT_FRAME:AddMessage("isUsable: "" .. spellName);
                lastIndex = i;
                lastRank = spellRank;
            end

            i = i + 1;
        end

        if (lastIndex ~= 0) then
            PickupSpell(lastIndex, BOOKTYPE_SPELL);
            PlaceAction(1);
            ClearCursor();
            return IsUsableAction(1);
        end
        
        return false;
	end
	
	spell.IsAutoRepeating = function(self)
		local i = 1
        while true do
            local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL);
            if not spellName then
                break;
            end
   
            -- use spellName and spellRank here
            if(spellName == self.name) then
                PickupSpell(i, BOOKTYPE_SPELL);
                PlaceAction(1);
                ClearCursor();
                return IsAutoRepeatAction(1)
            end

            i = i + 1;
        end
        return false;
	end
	
	spell.CanCast = function(self)
		return not IsSpellOnCD(self.name) and self:IsUsable();
	end
	
	spell.IsKnown = function(self)
		local i = 1;
        local rank = self.rank;

        while true do
            local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL);
            if not spellName then
                break;
            end

            local _, _, currentRankString = string.find(spellRank, " (%d+)$");
            local currentRank = tonumber(currentRankString);
            
            -- use spellName and spellRank here
            if(spellName == self.name and ((currentRank and currentRank > rank) or spellRank == "Rank " .. rank or spellRank == "" or spellRank == "Summon" or spellRank == "Shapeshift")) then
                --DEFAULT_CHAT_FRAME:AddMessage('know spell: ' .. spellName);
                return true;
            end

            i = i + 1;
        end
        return false;
	end
	
	spell.FullName = function(self)
		if (self.rawRank) then
			return self.name .. "(Rank " .. self.rawRank .. ")";
		end
		return self.name .. "()";
	end
	
	spell.Range = function(self)
		local castTime, maxRange, minRange = GetSpellInfo(self.name);
		return maxRange;
	end
	
	spell.GetCastTime = function(self)
		local castTime, maxRange, minRange = GetSpellInfo(self.name);
		return castTime;
	end
	
	spell.Execute = function(self, target, force)
		RotationFramework:CastSpell(self, target, force);
	end
	
	return spell;
end

--[[
	Takes spell object, checks all necessary conditions and then casts the spell
]]
function RotationFramework:CastSpell(spell, target, force)

	--DEFAULT_CHAT_FRAME:AddMessage("Trying to cast spell " .. spell.name .. " on " .. target:GetUnitName() .. " IsKnown: " .. (spell:IsKnown() and "true" or "false") .. "  CanCast: " .. (spell:CanCast() and "true" or "false"));

	local player = GetLocalPlayer();

	-- silly vanilla logic to break druid forms
	if (target ~= 0 and target ~= nil and not target:IsDead() and not IsSpellOnCD(spell.name) and not spell:IsUsable() and not spell:NotEnoughMana()) then
		if (player:HasBuff("Bear Form")) then
			CastSpellByName("Bear Form");
		end
		if (player:HasBuff("Dire Bear Form")) then
			CastSpellByName("Dire Bear Form");
		end
		if (player:HasBuff("Cat Form")) then
			CastSpellByName("Cat Form");
		end
		if (player:HasBuff("Ghost Wolf")) then
			CastSpellByName("Ghost Wolf");
		end
	end
	
	-- targetfinder function already checks that they are in LoS
	if (target == 0 or target == nil or not spell:IsKnown() or not spell:CanCast() or target:IsDead()) then
		return false;
	end
	
	-- dismount before casting
	if (IsMounted()) then
		DisMount()
	end
	
	-- already wanding, don't turn it on again!
	if (spell.name == "Shoot" and IsAutoRepeating("Shoot")) then
		return true;
	end
	
	if ((IsChanneling() or IsCasting()) and not force) then
		return false;
	end
	
	if (IsMoving() and spell:GetCastTime() > 0) then
		--StopMoving();
	end
	
	if (force) then
		SpellStopCasting();
	end
	
	local oldTarget = GetTarget();
	local onSelf = (target:GetGUID() == player:GetGUID());
	
	if (not onSelf) then
		target:FaceTarget();
		target:UnitInteract();
		target:TargetEnemy();
	end
	
	--target:CastSpell(spell:FullName());
	CastSpellByName(spell:FullName(), onSelf);
	
	if (not onSelf) then
		
		if (oldTarget == 0 or oldTarget == nil) then
			ClearTarget();
		else
			oldTarget:FaceTarget();
			oldTarget:UnitInteract();
			oldTarget:TargetEnemy();
		end
	end
	
	return true;
	
end

function RotationFramework:GetNumberAttackingMe(range)
	local currentObj, typeObj = GetFirstObject();
	local targetingMe = 0;
	range = range or 50;
	
    while currentObj ~= 0 do 
    	if typeObj == 3 then
			local objTarget = (currentObj:GetUnitsTarget() ~= 0) and currentObj:GetUnitsTarget():GetGUID() or 0;
			if (currentObj:CanAttack() and objTarget == GetLocalPlayer():GetGUID() and currentObj:GetDistance() <= range) then
				targetingMe = targetingMe + 1;
			end
		end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
	
	return targetingMe;
end

function RotationFramework:HasMainHandEnchant()
	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo();
	return hasMainHandEnchant;
end

function RotationFramework:HasOffhandEnchant()
	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo();
	return hasOffHandEnchant;
end