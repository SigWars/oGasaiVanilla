script_grind = {
useVendor = true,
	stopWhenFull = true,
	hsWhenFull = false,
	useMount = false,
	disMountRange = 32,
	mountTimer = 0,
	enemyObj = nil,
	lootObj = nil,
	timer = 0,
	tickRate = 50,
	waitTimer = 0,
	pullDistance = 150,
	avoidElite = false,
	avoidRange = 40,
	findLootDistance = 60,
	lootDistance = 3,
	skipLooting = false,
	lootCheck = {},
	minLevel = GetLocalPlayer():GetLevel()-5,
	maxLevel = GetLocalPlayer():GetLevel()+1,
	ressDistance = 25,
	combatError = 0,
	stuckTimeout = 25,
	logOutIfStuck = true,
	myX = 0,
	myY = 0,
	myZ = 0,
	myTime = 0,
	message = 'Starting the grinder...',
	skipHumanoid = true,
	skipElemental = false,
	skipUndead = true,
	skipDemon = true,
	skipBeast = false,
	skipNotspecified = false,
	skipDragonkin = false,
	skipMechanical = false,
	skipElites = true,
	skipRares = false,
	skipPlayerTargeted = true,
	skipIsTargetingOtherPlayer = true,
	skipMultiPull = false,
	paranoidOn = false,
	paranoidOnTargeted = true,
	paranoidRange = 60,
	navFunctionsLoaded = include("scripts\\script_nav.lua"),
	helperLoaded = include("scripts\\script_helper.lua"),
	nextToNodeDist = 4, -- (Set to about half your nav smoothness)
	blacklistedTargets = {},
	blacklistedNum = 0,
	blacklistedNameTargets = {},
	blacklistedNameNum = 0,
	NPCdb = {},
	NPCdbNum = 0,
	isSetup = false,
	drawUnits = true,
	pathName = "", -- set to e.g. "paths\1-5 Durator.xml" for auto load at startup
	pathLoaded = "",
	drawPath = true,
	autoPath = true,
	distToHotSpot = 325,
	staticHotSpot = false,
	hotSpotTimer = 0,
	currentLevel = GetLocalPlayer():GetLevel(),
	skinning = true,
	lastTarget = 0,
	newTargetTime = 0,
	blacklistTime = 30,
	targetTime = 4,
}


function script_grind:setup()
	self.lootCheck['timer'] = 0;
	self.lootCheck['target'] = 0;
	script_helper:setup();
	self.isSetup = true;
end

function script_grind:setWaitTimer(ms)
	self.waitTimer = GetTimeEX() + ms;
end

function script_grind:addTargetToBlacklist(targetGUID)
	if (targetGUID ~= nil and targetGUID ~= 0 and targetGUID ~= '') then	
		self.blacklistedTargets[self.blacklistedNum] = targetGUID;
		self.blacklistedNum = self.blacklistedNum + 1;
	end
end

function script_grind:isTargetBlacklisted(targetGUID) 
	for i=0,self.blacklistedNum do
		if (targetGUID == self.blacklistedTargets[i]) then
			return true;
		end
	end
	return false;
end

function script_grind:isTargetNameBlacklisted(name) --IS TARGET BLACKLISTED BY NAME?
	for i=0,self.blacklistedNameNum do
		if (name == self.blacklistedNameTargets[i]) then
			return true;
		end
	end
	return false;
end

function script_grind:addTargetToNameBlacklist(name) --ADD BLACKLIST BY NAME
	if (name ~= nil and name ~= 0 and name ~= '') then	
		self.blacklistedNameTargets[self.blacklistedNameNum] = name;
		self.blacklistedNameNum = self.blacklistedNameNum + 1;
	end
end

function script_grind:run()
	-- Set next to node distance and nav-mesh smoothness to double that number
	if (IsMounted()) then
		script_nav:setNextToNodeDist(5); NavmeshSmooth(10);
	else
		script_nav:setNextToNodeDist(self.nextToNodeDist); NavmeshSmooth(self.nextToNodeDist*2);
	end
	
	if (not self.isSetup) then
		script_grind:setup();
	end
	
	if (not self.navFunctionsLoaded) then self.message = "Error script_nav not loaded..."; return; end
	if (not self.helperLoaded) then self.message = "Error script_helper not loaded..."; return; end

	localObj = GetLocalPlayer();

	-- Unstuck feature: Try to unstuck if more then a third of the stuck timer passed
	if(self.logOutIfStuck) then script_grind:stopIfStuck(); end
	if ((GetTimeEX()-self.myTime)/1000 > self.stuckTimeout/3 and not IsInCombat()
		and not AreBagsFull() and not IsCasting() and self.logOutIfStuck) then -- Don't unstuck if bags full
		if (script_nav:unStuck()) then
			script_nav:resetNavigate();
			self.message = "Trying to unstuck...";
			self.timer = GetTimeEX() + 2000;
			return;
		end
	end

	-- Check: Paranoid feature
	if (not localObj:IsDead() and self.paranoidOn and not IsInCombat()) then 
		if (self.paranoidOnTargeted and script_grind:playersTargetingUs() > 0) then
			self.message = "Player(s) targeting us, pausing...";
			script_grind:savePos();
			ClearTarget();
			return;
		end
		if (script_grind:playersWithinRange(self.paranoidRange)) then
			self.message = "Player(s) within paranoid range, pausing...";
			script_grind:savePos();
			ClearTarget();
			return;
		end
	end

	if(GetTimeEX() > self.timer) then
		self.timer = GetTimeEX() + self.tickRate;

		-- Wait out the wait-timer and/or casting or channeling
		if (self.waitTimer > GetTimeEX() or IsCasting() or IsChanneling()) then script_grind:savePos(); return; end
		
		-- Check: Avoid elite function
		if (self.avoidElite and not localObj:IsDead()) then 
			if (script_nav:avoidElite(self.avoidRange)) then
				self.message = "Elite within " .. self.avoidRange .. " yd. running away...";
				self.waitTimer = GetTimeEX() + 1500;
				return; 
			end 
		end

		-- Automatic loading of the nav mesh
		if (not IsUsingNavmesh()) then UseNavmesh(true); return; end
		if (not LoadNavmesh()) then self.message = "Make sure you have mmaps-files..."; return; end
		if (GetLoadNavmeshProgress() ~= 1) then self.message = "Loading the nav mesh... " script_grind:savePos(); return; end

		-- Corpse-walk if we are dead
		if(localObj:IsDead()) then
			self.message = "Walking to corpse...";
			-- Release body
			if(not IsGhost()) then RepopMe(); self.waitTimer = GetTimeEX() + 5000; return; end
			-- Ressurrect within the ress distance to our corpse
			local _lx, _ly, _lz = localObj:GetPosition();
			if(GetDistance3D(_lx, _ly, _lz, GetCorpsePosition()) > self.ressDistance) then
				script_nav:moveToNav(localObj, GetCorpsePosition());
				return;
			else
				script_grind:savePos(); -- save pos so we don't log out (stuck feature)
				RetrieveCorpse();
			end
			return;
		end

		-- Check: If in group wait for members to be within 60 yards and 75% mana
		local groupMana = 0;
		local manaUsers = 0;
		for i = 1, GetNumPartyMembers() do
			local partyMember = GetPartyMember(i);
			if (partyMember:GetManaPercentage() > 0) then
				groupMana = groupMana + partyMember:GetManaPercentage();
				manaUsers = manaUsers + 1;
			end
			if (partyMember:GetDistance() > 60 and not IsInCombat()) then
				StopMoving();
				self.message = 'Waiting for group members...';
				script_grind:savePos();
				return;
			end
		end
		if (groupMana/manaUsers < 75 and GetNumPartyMembers() >= 1 and not IsInCombat()) then
			StopMoving();
				self.message = 'Waiting for group to regen mana (75%+)...';
				script_grind:savePos();
				return;
		end

		-- Check: Rogue only, If we just Vanished, move away from enemies within 30 yards
		if (localObj:HasBuff("Vanish")) then if (script_nav:runBackwards(1, 30)) then 
			ClearTarget(); self.message = "Moving away from enemies..."; return; end 
		end
		
		local rest = true;
		if (self.enemyObj ~= nil and self.enemyObj ~= 0) then
			if (script_grind:enemiesAttackingUs() > 0 or self.enemyObj:IsFleeing() or self.enemyObj:IsStunned()) then
				rest = false;
			end
		end

		-- Finish the vendor routine if it's been called
		local vendorStatus = script_vendor:getStatus();
		if (vendorStatus >= 1 and self.useMount and not IsInCombat()) then
			if (script_grind:mountUp()) then return; end
		end
		if (not IsInCombat() or IsMounted()) then
			if (vendorStatus == 1) then
				self.message = "Running the repair at vendor routine...";
				if (script_vendor:repair()) then return; end
			elseif (vendorStatus == 2) then
				self.message = "Running the sell to vendor routine...";
				script_grind:savePos();
				if (script_vendor:sell()) then return; end
			elseif (vendorStatus == 3) then
				self.message = "Running the buy ammo at vendor routine...";
				if (script_vendor:continueBuyAmmo()) then return; end
			elseif (vendorStatus == 4) then
				self.message = "Running the buy at vendor routine...";
				if (script_vendor:continueBuy()) then return; end
			end
		end

		-- Clear dead/blacklisted/tapped targets
		if (self.enemyObj ~= 0 and self.enemyObj ~= nil) then
			-- Save location for auto pathing
			if (self.enemyObj:IsDead() and self.enemyObj:GetLevel() >= self.minLevel and self.enemyObj:GetLevel() <= self.maxLevel) then 
				script_nav:saveTargetLocation(self.enemyObj, self.enemyObj:GetLevel()); end
			if ((self.enemyObj:IsTapped() and not self.enemyObj:IsTappedByMe()) 
				or (script_grind:isTargetBlacklisted(self.enemyObj:GetGUID()) and not IsInCombat()) or self.enemyObj:IsDead()) then
				self.enemyObj = nil;
				ClearTarget();
			end
		end

		if (not IsInCombat() and not localObj:HasBuff('Feign Death')) then
			-- Move out of water before resting/mounting
			if (IsSwimming()) then self.message = "Moving out of the water..."; script_nav:navigate(GetLocalPlayer()); return; end
			if (rest) then
				-- Rest before looting, fighting, pathing etc
				if(RunRestScript()) then
					self.message = "Resting...";
					self.newTargetTime = GetTimeEX();
					script_grind:savePos();
					-- Stop moving
					if (IsMoving() and not localObj:IsMovementDisabed()) then StopMoving(); return; end
					-- Dismount
					if (IsMounted()) then DisMount(); return; end
					-- Add 2500 ms timer to the rest script rotations (timer could be set already)
					if ((self.waitTimer - GetTimeEX()) < 2500) then self.waitTimer = GetTimeEX()+2500 end;
					return;	
				end
			end
			-- Loot if there is anything lootable and we are not in combat and if our bags aren't full
			if (not self.skipLooting and not AreBagsFull()) then 
				self.lootObj = script_nav:getLootTarget(self.findLootDistance);
			else
				self.lootObj = nil;
			end
			if (self.lootObj == 0) then self.lootObj = nil; end
			local isLoot = not IsInCombat() and not (self.lootObj == nil);
			if (isLoot and not AreBagsFull()) then
				script_grind:doLoot(localObj);
				return;
			elseif (AreBagsFull() and not hsWhenFull) then
				self.lootObj = nil;
				self.message = "Warning the bags are full...";
			end
			-- Skin if there is anything skinnable within the loot radius
			if (HasSpell('Skinning') and self.skinning and HasItem('Skinning Knife')) then
				self.lootObj = nil;
				self.lootObj = script_grind:getSkinTarget(self.findLootDistance);
				if (not AreBagsFull() and self.lootObj ~= nil) then
					script_grind:doLoot(localObj);
					return;
				end
			end
		end

		-- If bags are full
		if (AreBagsFull() and not IsInCombat()) then
			if(self.useVendor and script_vendor:sell()) then
				self.message = "Running the vendor routine: sell..."; 
				return;
			elseif (self.hsWhenFull and HasItem("Hearthstone")) then
				-- For druids, cant HS if shapeshifted
				script_vendor:removeShapeShift();
				self.message = 'Inventory is full, using Hearthstone...';
				-- Dismount
				if (IsMounted()) then DisMount(); self.waitTimer = GetTimeEX()+3000; return; end
				UseItem("Hearthstone");
				return;
			elseif (self.stopWhenFull) then
				self.message = 'Bags are full, stopping...';
				Logout(); StopBot(); return;
			else	
				self.message = 'Warning bags are full...';
				if (self.hsWHenFull) then self.message = 'Warning bags are full, pausing...'; return; end -- dont move if we should hs when bags are full
			end
		end

		-- Update pull levels if we leveled up
		if (self.currentLevel < GetLocalPlayer():GetLevel()) then
			self.currentLevel = GetLocalPlayer():GetLevel();
			self.minLevel = self.minLevel + 1;
			self.maxLevel = self.maxLevel + 1;
		end
		
		-- Update/load hot spot distance and location
		if (self.autoPath) then 
			-- Update hotspot location, static hotspots depends on your level/faction (see script_nav.lua)
			script_nav:updateHotSpot(GetLocalPlayer():GetLevel(), GetFaction(), self.staticHotSpot);
			-- Update distance to hotspot
			script_nav:setHotSpotDistance(self.distToHotSpot); 
		end
		
		-- Auto path: keep us inside the distance to the current hotspot, if mounted keep running even if in combat
		if ((not IsInCombat() or IsMounted()) and self.autoPath and vendorStatus == 0 and
			(script_nav:getDistanceToHotspot() > self.distToHotSpot or self.hotSpotTimer > GetTimeEX())) then
			if (not (self.hotSpotTimer > GetTimeEX())) then self.hotSpotTimer = GetTimeEX() + 20000; end
			if (script_grind:mountUp()) then return; end
			-- Druid cat form is faster if you specc talents
			if (self.currentLevel < 40 and HasSpell('Cat Form') and not localObj:HasBuff('Cat Form')) then
				CastSpellByName('Cat Form');
			end
			-- Shaman Ghost Wolf 
			if (self.currentLevel < 40 and HasSpell('Ghost Wolf') and not localObj:HasBuff('Ghost Wolf')) then
				CastSpellByName('Ghost Wolf');
			end
			self.message = script_nav:moveToHotspot(localObj);
			return;
		end
			

		-- Assign the next valid target to be killed within the pull range
		if (self.enemyObj ~= 0 and self.enemyObj ~= nil) then
			self.lastTarget = self.enemyObj:GetGUID();
		end
		self.enemyObj = script_grind:assignTarget();
		
		if (self.enemyObj ~= 0 and self.enemyObj ~= nil) then
			-- Fix bug, when not targeting correctly
			if (self.lastTarget ~= self.enemyObj:GetGUID()) then
				self.newTargetTime = GetTimeEX();
				ClearTarget();
			elseif (self.lastTarget == self.enemyObj:GetGUID() and not IsStanding() and not IsInCombat()) then
				self.newTargetTime = GetTimeEX(); -- reset time if we rest
			-- blacklist the target if we had it for a long time and hp is high
			elseif (((GetTimeEX()-self.newTargetTime)/1000) > self.blacklistTime and self.enemyObj:GetHealthPercentage() > 80) then 
				script_grind:addTargetToBlacklist(self.enemyObj:GetGUID());
				ClearTarget();
				return;
			end
		end

		-- Finish loot before we engage new targets or navigate
		if (self.lootObj ~= nil and not IsInCombat()) then 
			return; 
		else
			-- reset the combat status
			self.combatError = nil; 
			-- Run the combat script and retrieve combat script status if we have a valid target
			if (self.enemyObj ~= nil and self.enemyObj ~= 0) then
				self.combatError = RunCombatScript(self.enemyObj:GetGUID());
			end
		end

		if(self.enemyObj ~= nil or IsInCombat()) then
			self.message = "Running the combat script...";
			-- In range: attack the target, combat script returns 0
			if(self.combatError == 0) then
				script_nav:resetNavigate();
				if IsMoving() then StopMoving(); return; end
				-- Dismount
				if (IsMounted()) then DisMount(); return; end
			end
			-- Invalid target: combat script return 2
			if(self.combatError == 2) then
				-- TODO: add blacklist GUID here
				self.enemyObj = nil;
				ClearTarget();
				return;
			end
			-- Move in range: combat script return 3
			if (self.combatError == 3) then
				self.message = "Moving to target...";
				if (self.enemyObj:GetDistance() < self.disMountRange) then
					-- Dismount
					if (IsMounted()) then DisMount(); return; end
				end
				local _x, _y, _z = self.enemyObj:GetPosition();
				self.message = script_nav:moveToTarget(GetLocalPlayer(), _x, _y, _z);
				return;
			end
			-- Do nothing, return : combat script return 4
			if(self.combatError == 4) then return; end
			-- Target player pet/totem: pause for 5 seconds, combat script should add target to blacklist
			if(self.combatError == 5) then
				self.message = "Targeted a player pet pausing 5s...";
				ClearTarget(); script_grind:savePos(); self.waitTimer = GetTimeEX()+5000; return;
			end
			-- Stop bot, request from a combat script
			if(self.combatError == 6) then self.message = "Combat script request stop bot..."; Logout(); StopBot(); return; end
		end

		-- Pre checks before navigating
		if(IsLooting() or IsCasting() or IsChanneling() or IsDrinking() or IsEating() or IsInCombat()) then return; end

		-- Mount before we navigate through the path, error check to get around indoors
		if (script_grind:mountUp()) then return; end	

		-- Use auto pathing or walk paths
		if (self.autoPath) then
			self.message = script_nav:moveToSavedLocation(localObj, self.minLevel, self.maxLevel, self.staticHotSpot);
		else
			-- Check: Load/Refresh the walk path
			if (self.pathName ~= self.pathLoaded) then
				if (not LoadPath(self.pathName, 0)) then self.message = "No walk path has been loaded..."; return; end
				self.pathLoaded = self.pathName;
			end
			-- Navigate
			self.message = script_nav:navigate(localObj);
		end
	end 
end

function script_grind:mountUp()
	local __, lastError = GetLastError();
	if (lastError ~= 75 and self.mountTimer < GetTimeEX()) then
		if(GetLocalPlayer():GetLevel() >= 40 and self.useMount and not IsSwimming() and not IsIndoors() and not IsMounted() and self.lootObj == nil) then
			self.message = "Mounting...";
			if (not IsStanding()) then StopMoving(); end
			if (script_helper:useMount()) then self.waitTimer = GetTimeEX() + 4000; return true; end
		end
	else
		ClearLastError();
		self.mountTimer = GetTimeEX() + 15000;
		return false;
	end
end

function script_grind:getTarget()
	return self.enemyObj;
end

function script_grind:getTargetAttackingUs() 
    local currentObj, typeObj = GetFirstObject(); 
    while currentObj ~= 0 do 
    	if typeObj == 3 then
		if (currentObj:CanAttack() and not currentObj:IsDead()) then
			local localObj = GetLocalPlayer();		
                	if (currentObj:GetUnitsTarget() == localObj) then 
                		return currentObj;
                	end 
            	end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nil;
end

function script_grind:assignTarget() 
	-- Return a target attacking our group
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (script_grind:isTargetingGroup(i)) then
			return i;
		end
		i, targetType = GetNextObject(i);
	end

	-- Instantly return the last target if we attacked it and it's still alive and we are in combat
	if (self.enemyObj ~= 0 and self.enemyObj ~= nil and not self.enemyObj:IsDead() and IsInCombat()) then
		if (script_grind:isTargetingMe(self.enemyObj) 
			or script_grind:isTargetingPet(self.enemyObj) 
			or self.enemyObj:IsTappedByMe()) then
			return self.enemyObj;
		end
	end

	-- Find the closest valid target if we have no target or we are not in combat
	local mobDistance = self.pullDistance;
	local closestTarget = nil;
	local i, targetType = GetFirstObject();
	while i ~= 0 do
		if (targetType == 3 and not i:IsCritter() and not i:IsDead() and i:CanAttack()) then
			if (script_grind:enemyIsValid(i)) then
				-- save the closest mob or mobs attacking us
				if (mobDistance > i:GetDistance()) then
					local _x, _y, _z = i:GetPosition();
					if(not IsNodeBlacklisted(_x, _y, _z, self.nextNavNodeDistance)) then
						mobDistance = i:GetDistance();	
						closestTarget = i;
					end
				end
			end
		end
		i, targetType = GetNextObject(i);
	end
	
	-- Check: If we are in combat but no valid target, kill the "unvalid" target attacking us
	if (closestTarget == nil and IsInCombat()) then
		if (GetTarget() ~= 0) then
			return GetTarget();
		end
	end

	-- Return the closest valid target or nil
	return closestTarget;
end

function script_grind:isTargetingPet(i) 
	local pet = GetPet();
	if (pet ~= nil and pet ~= 0 and not pet:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == pet:GetGUID();
		end
	end
	return false;
end

function script_grind:isTargetingGroup(y) 
	for i = 1, GetNumPartyMembers() do
		local partyMember = GetPartyMember(i);
		if (partyMember ~= nil and partyMember ~= 0 and not partyMember:IsDead()) then
			if (y:GetUnitsTarget() ~= nil and y:GetUnitsTarget() ~= 0 and not script_grind:isTargetingPet(y)) then
				return y:GetUnitsTarget():GetGUID() == partyMember:GetGUID();
			end
		end
	end

	return false;
end

function script_grind:isTargetingMe(i) 
	local localPlayer = GetLocalPlayer();
	if (localPlayer ~= nil and localPlayer ~= 0 and not localPlayer:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
		
			return i:GetUnitsTarget():GetGUID() == localPlayer:GetGUID();
			
		end
	end
	return false;
end

function script_grind:playerIsTargetingObj(i)
	local currentObj, typeObj = GetFirstObject();
	if self.skipPlayerTargeted then
		while currentObj ~= 0 do 
			if typeObj == 4 then
				if (currentObj:GetGUID() ~= GetLocalPlayer():GetGUID()) then
					if (currentObj:GetUnitsTarget() ~= 0) then
						if currentObj:GetUnitsTarget():GetGUID() == i:GetGUID() then
							if script_grind:CalculateDistance(currentObj,i) < 40 then
								return true;
							end
						end
					end		
				end 
			end
			currentObj, typeObj = GetNextObject(currentObj); 
		end	
	end
    return false;
end



function script_grind:objIsTargetingOtherPlayer(i)
	if self.skipIsTargetingOtherPlayer then
		if (i:GetUnitsTarget() ~= 0) then
			if i:GetUnitsTarget():GetGUID() ~= (GetLocalPlayer():GetGUID() or GetPet:GetGUID()) then
					return true;
			end
		end			
	end
	return false;
end	

function script_grind:CalculateDistance(unit,otherUnit)
	local _lx, _ly, _lz = unit:GetPosition();
	local _2x, _2y, _2z = otherUnit:GetPosition();
	local Distance = GetDistance3D(_lx, _ly, _lz, _2x, _2y, _2z);
	return Distance;
end

function script_grind:calculateAggroRadius(i) 
local localObjlvl = GetLocalPlayer():GetLevel();
local targetObjlvl = i:GetLevel();
local lvlcalc = targetObjlvl- localObjlvl;
local aggroRange = lvlcalc + 20; -- 20 is the default aggro range for same lvl targets.

	if aggroRange <= 0 then 
	  local aggroRange = 5; --Lowest aggro range possible.
	  return aggroRange;
	elseif aggroRange >= 45 then
	  local aggroRange = 45;--Highest aggro range possible.
	  return aggroRange;
	end
return aggroRange;
end

function script_grind:multiPull(i) --Check if the target is close enough to pull unwanted enemies when pulled.
local currentObj, typeObj = GetFirstObject();
	if self.skipMultiPull then
		while currentObj ~= 0 do 
			if typeObj == 3 then
				if (typeObj == 3 and not currentObj:IsCritter() and not currentObj:IsDead() and currentObj:CanAttack()) then
					if (currentObj:GetGUID() ~= i:GetGUID()) then
						if i:GetCreatureType() == currentObj:GetCreatureType() then
							if script_grind:CalculateDistance(currentObj,i) < 15 then --Not sure about the 15 yards range... Approximate guess.
							  return true;
							end
						end
					end 
				end
			end
			currentObj, typeObj = GetNextObject(currentObj); 
		end	
	end
    return false;
end

function script_grind:rangedPull(i) --Check to determine if it is wise to use a ranged, or melee attack to pull aggro.  true=Ranged(we will get unwanted aggro if we go meele)  false=Melee(Melee is safe)
local currentObj, typeObj = GetFirstObject();
	while currentObj ~= 0 do 
		if (typeObj == 3 and not currentObj:IsCritter() and not currentObj:IsDead() and currentObj:CanAttack()) then
			if (currentObj:GetGUID() ~= i:GetGUID()) then
				if (script_grind:CalculateDistance(currentObj,i)) < ((script_grind:calculateAggroRadius(currentObj)+4)) then
					return true;			
				end
			end 
		end
		currentObj, typeObj = GetNextObject(currentObj); 
	end	
	return false;	
end

function script_grind:enemyIsValid(i)
	if (i ~= 0) then
		-- Valid Targets: Tapped by us, or is attacking us or our pet
		if (script_grind:isTargetingMe(i)
			or (script_grind:isTargetingPet(i) and (i:IsTappedByMe() or not i:IsTapped())) 
			or (script_grind:isTargetingGroup(i) and (i:IsTappedByMe() or not i:IsTapped())) 
			or (i:IsTappedByMe() and not i:IsDead())) then 
				return true; 
		end
		-- Valid Targets: Within pull range, levelrange, not tapped, not skipped etc
		if (not i:IsDead() and i:CanAttack() and not i:IsCritter()
			and ((i:GetLevel() <= self.maxLevel and i:GetLevel() >= self.minLevel))
			and i:GetDistance() < self.pullDistance and (not i:IsTapped() or i:IsTappedByMe())
			and not script_grind:playerIsTargetingObj(i)
			and not script_grind:isTargetBlacklisted(i:GetGUID()) 
			and not script_grind:isTargetNameBlacklisted(i:GetUnitName()) 
			and not (self.skipHumanoid and i:GetCreatureType() == 'Humanoid')
			and not (self.skipDemon and i:GetCreatureType() == 'Demon')
			and not (self.skipBeast and i:GetCreatureType() == 'Beast')
			and not (self.skipElemental and i:GetCreatureType() == 'Elemental')
			and not (self.skipUndead and i:GetCreatureType() == 'Undead')		
			and not (self.skipDragonkin and i:GetCreatureType() == 'Dragonkin')
			and not (self.skipMechanical and i:GetCreatureType() == 'Mechanical')
			and not (self.skipNotspecified and i:GetCreatureType() == 'Not specified')
			and not (self.skipElites and (i:GetClassification() == 1 or i:GetClassification() == 2))
			and not script_grind:objIsTargetingOtherPlayer(i)
			and not script_grind:multiPull(i)
			) then
			return true;
		end
	end
	return false;
end

function script_grind:enemiesAttackingUs() -- returns number of enemies attacking us
	local unitsAttackingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    	if typeObj == 3 then
		if (currentObj:CanAttack() and not currentObj:IsDead()) then
                	if (script_grind:isTargetingMe(currentObj) or script_grind:isTargetingPet(currentObj)) then 
                		unitsAttackingUs = unitsAttackingUs + 1; 
                	end 
            	end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return unitsAttackingUs;
end

function script_grind:playersTargetingUs() -- returns number of players attacking us
	local nrPlayersTargetingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
	if typeObj == 4 then
		if (script_grind:isTargetingMe(currentObj)) then 
                	nrPlayersTargetingUs = nrPlayersTargetingUs + 1; 
                end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nrPlayersTargetingUs;
end

function script_grind:playersWithinRange(range)
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    	if (typeObj == 4 and not currentObj:IsDead()) then
		if (currentObj:GetDistance() < range) then 
			local localObj = GetLocalPlayer();
			if (localObj:GetGUID() ~= currentObj:GetGUID()) then
                		return true;
			end
                end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return false;
end

function script_grind:savePos() 
	self.myX, self.myY, self.myZ = GetLocalPlayer():GetPosition();
	self.myTime = GetTimeEX();
end

function script_grind:getDistanceDif()
	local x, y, z = GetLocalPlayer():GetPosition();
	local xV, yV, zV = self.myX-x, self.myY-y, self.myZ-z;
	return math.sqrt(xV^2 + yV^2 + zV^2);
end

function script_grind:stopIfStuck()
	-- Save our pos if we moved more then 5 yards or if we are in combat or eating/drinking
	if (script_grind:getDistanceDif() > 5 or IsInCombat() or IsEating() or IsDrinking()) then script_grind:savePos(); return; end
	-- Check if we are stuck/standing still (moved less than 5 yards) since stuckTimeOut seconds since last saved position
	if (script_grind:getDistanceDif() < 5 and (GetTimeEX()-self.myTime)/1000 > self.stuckTimeout) then
		if (self.logOutIfStuck) then Logout(); end StopBot(); return; end
end

function script_grind:drawStatus()
	if (self.autoPath) then script_nav:drawSavedTargetLocations(); end
	if (self.drawPath) then script_nav:drawPath(); end

	if (self.drawUnits) then script_nav:drawUnitsDataOnScreen(); end
	-- color
	local r, g, b = 255, 255, 0;
	-- position
	local y, x, width = 120, 25, 370;
	local tX, tY, onScreen = WorldToScreen(GetLocalPlayer():GetPosition());
	if (onScreen) then
		y, x = tY-25, tX+75;
	end
	-- info
	DrawRectFilled(x - 10, y - 5, x + width, y + 140, 0, 0, 0, 160, 0, 0);
	DrawText('[Grinder - Pull range: ' .. math.floor(self.pullDistance) .. ' yd. ' .. 
			 	'Level range: ' .. self.minLevel .. '-' .. self.maxLevel, x-5, y-4, r, g, b) y = y + 15;
	DrawLine(x-10, y-20, x - 10, y + 124, 255, 255, 255, 2); -- left horizontal line
	DrawLine(x-10, y-3, x + width, y-3, 255, 255, 255, 2); 
	DrawLine(x-10, y-20, x + width, y-20, 255, 255, 255, 2); -- upper line
	DrawLine(x+width, y-20, x+width, y + 124, 255, 255, 255, 2); -- right horizontal line
	DrawLine(x-11, y+32, x +width+2, y+32, 255, 255, 255, 2); -- middle line
	DrawLine(x-11, y+68, x +width+2, y+68, 255, 255, 255, 2); -- middle line
	DrawLine(x-11, y+88, x +width+2, y+88, 255, 255, 255, 2); -- middle line
	DrawLine(x-11, y+123, x +width+2, y+123, 255, 255, 255, 2); -- middle line
	DrawText('Status: ', x, y, r, g, b); DrawText("        " .. (self.message or "error"), x, y, 0, 255, 255); y = y + 15;
	-- Draw stuck feature on screen
	if (self.logOutIfStuck) then 
		DrawText('Stuck timeout: ', x, y, 255, 255, 0);
		local logoutTime = math.floor(self.stuckTimeout-((GetTimeEX()-self.myTime)/1000));
		DrawText('               Logging out in' .. ' ' .. logoutTime .. 's...', x, y, 0, 255, 255); 
	else
		DrawText('Stuck feature: Disabled...', x, y, 255, 255, 0); 
	end
	y = y + 20; DrawText('Combat script status: ', x, y, r, g, b); y = y + 15;
	RunCombatDraw(); y = y + 20;
	if (self.autoPath) then 
		DrawText('Auto path: ON! Hotspot: ' .. script_nav:getHotSpotName(), x, y, r, g, b); y = y + 20;
	else
		DrawText('Auto path: OFF!', x, y, r, g, b); y = y + 20;
	end
	DrawText('Vendor - ' .. script_vendor:getInfo(), x, y, r, g, b); y = y + 15;
	DrawText('Status: ', x, y, r, g, b); DrawText(script_vendor:getMessage(), x+52, y, 0, 255, 255);
	local time = ((GetTimeEX()-self.newTargetTime)/1000); 
	if (self.enemyObj ~= 0 and self.enemyObj ~= nil) then
		DrawRectFilled(x-10, y+20, x + width, y + 45, 0, 0, 0, 160, 0, 0);
		DrawText(self.enemyObj:GetUnitName() .. ' targeted for: ' .. time .. ' s.', x, y+20, 225, 0, 0); 
		DrawText('Blacklisting monster after ' .. self.blacklistTime .. " s. If above 80% HP.", x, y+30, 225, 0, 0);
	end
end

function script_grind:draw()
	script_grind:drawStatus();
end

function script_grind:doLoot(localObj)
	local _x, _y, _z = self.lootObj:GetPosition();
	local dist = self.lootObj:GetDistance();
	
	-- Loot checking/reset target
	if (GetTimeEX() > self.lootCheck['timer']) then
		if (self.lootCheck['target'] == self.lootObj:GetGUID()) then
			self.lootObj = nil; -- reset lootObj
			ClearTarget();
			self.message = 'Reseting loot target...';
		end
		self.lootCheck['timer'] = GetTimeEX() + 10000; -- 10 sec
		if (self.lootObj ~= nil) then 
			self.lootCheck['target'] = self.lootObj:GetGUID();
		else
			self.lootCheck['target'] = 0;
		end
		return;
	end

	if(dist <= self.lootDistance) then
		self.message = "Looting...";
		if(IsMoving() and not localObj:IsMovementDisabed()) then
			StopMoving();
			self.waitTimer = GetTimeEX() + 450;
			return;
		end
		if(not IsStanding()) then
			StopMoving();
			self.waitTimer = GetTimeEX() + 450;
			return;
		end
		
		-- If we reached the loot object, reset the nav path
		script_nav:resetNavigate();

		-- Dismount
		if (IsMounted()) then DisMount(); self.waitTimer = GetTimeEX() + 450; return;  end

		if(not self.lootObj:UnitInteract() and not IsLooting()) then
			self.waitTimer = GetTimeEX() + 1350;
			return;
		end
		if (not LootTarget()) then
			self.waitTimer = GetTimeEX() + 850;
			return;
		else
			self.lootObj = nil;
			self.waitTimer = GetTimeEX() + 650;
			return;
		end
	end
	self.message = "Moving to loot...";		
	script_nav:moveToTarget(localObj, _x, _y, _z);	
	if (self.lootObj:GetDistance() < 3) then self.waitTimer = GetTimeEX() + 1150; end
end

function script_grind:getSkinTarget(lootRadius)
	local targetObj, targetType = GetFirstObject();
	local bestDist = lootRadius;
	local bestTarget = nil;
	while targetObj ~= 0 do
		if (targetType == 3) then -- Unit
			if(targetObj:IsDead()) then
				if (targetObj:IsSkinnable() and targetObj:IsTappedByMe() and not targetObj:IsLootable()) then
					local dist = targetObj:GetDistance();
					if(dist < lootRadius and bestDist > dist) then
						bestDist = dist;
						bestTarget = targetObj;
					end
				end
			end
		end
		targetObj, targetType = GetNextObject(targetObj);
	end

	return bestTarget;
end

function script_grind:menu()
	if (CollapsingHeader("[Logitech's Grinder - Options ")) then
		local wasClicked = false;
		Text("Path options:");
		wasClicked, self.autoPath = Checkbox("Auto pathing (disable if you wanna use walk path)", self.autoPath);
		if self.autoPath then
		Text("Auto pathing use mob's kill locations to build a path...");
		Separator();
		wasClicked, self.staticHotSpot = Checkbox("Use static hotspots (see script_nav.lua)", self.staticHotSpot);
		self.distToHotSpot = SliderInt("Max distance to hotspot (yd)", 1, 1000, self.distToHotSpot);
		Text("You can add level-specific hot spots in script_nav.lua...");
		end
		if not self.autoPath then
		Separator();
		self.pathName = InputText("Current walk path", self.pathName);
		Text("E.g. paths\\1-5 Durotar.xml");
		end
		Separator();
		wasClicked, self.drawPath = Checkbox("Draw move path", self.drawPath);
		wasClicked, self.drawUnits = Checkbox("Draw unit info on screen (players/creatures)", self.drawUnits);
		self.nextToNodeDist = SliderFloat("Next node distance (yd)", 1, 10, self.nextToNodeDist);
		self.ressDistance = SliderFloat("Ress corpse distance (yd)", 1, 30, self.ressDistance);
		Text("");
		Separator();
		Separator();
		Text("Loot options:");
		wasClicked, self.skipLooting = Checkbox("Skip Looting", self.skipLooting); SameLine();
		wasClicked, self.skinning = Checkbox("Use Skinning", self.skinning);
		self.findLootDistance = SliderFloat("Find Loot Distance (yd)", 1, 100, self.findLootDistance);	
		self.lootDistance = SliderFloat("Loot Distance (yd)", 1, 6, self.lootDistance);
		Text("");
		Separator();
		Separator();
		Text("Vendor, Bag and Stop options:");
		wasClicked, self.useVendor = Checkbox("Use Vendor (simple sell/repair)", self.useVendor);
		wasClicked, self.hsWhenFull = Checkbox("Use Hearthstone when bags are full", self.hsWhenFull);
		wasClicked, self.stopWhenFull = Checkbox("Stop the bot when bags are full", self.stopWhenFull);
		Text("");
		Separator();
		Separator();
		Text("Mount options:");
		wasClicked, self.useMount = Checkbox("Use Mount", self.useMount);
		if self.useMount then
		self.disMountRange = SliderInt("Dismount range", 1, 100, self.disMountRange);
		end
		Text("");
		Separator();
		Separator();
		Text("Stuck options:");
		wasClicked, self.logOutIfStuck = Checkbox("Logout when stuck", self.logOutIfStuck);
		if self.logOutIfStuck then
		self.stuckTimeout = SliderInt("Stuck timeout (s)", 1, 120, self.stuckTimeout);
		end
		Text("");
		Separator();
		Separator();
		Text("Paranoia options:");	
		wasClicked, self.paranoidOn = Checkbox("Enable Paranoia", self.paranoidOn);
		wasClicked, self.paranoidOnTargeted = Checkbox("Paranoid when targeted", self.paranoidOnTargeted);
		if self.paranoidOnTargeted then
	 	self.paranoidRange = SliderInt("Paranoia Range (yd)", 1, 120, self.paranoidRange);
		end
		Text("");
		Separator();
		Separator();
		Text("Pull options:");
		self.pullDistance = SliderFloat("Pull distance", 1, 150, self.pullDistance);
		self.blacklistTime = SliderInt("Blacklist time (s)", 1, 120, self.blacklistTime);
		self.minLevel = SliderInt("Minimum mob level", 1, 60, self.minLevel);
		self.maxLevel = SliderInt("Maximum mob level", 1, 60, self.maxLevel);
		Separator();
		wasClicked, self.avoidElite = Checkbox("Avoid elites", self.avoidElite);
		if self.avoidElite then
		self.avoidRange = SliderInt("Avoid elite range", 1, 100, self.avoidRange);
		end
		Separator();
		wasClicked, self.skipElites = Checkbox("Skip pulling elites(and rare elites)", self.skipElites);
		wasClicked, self.skipRares = Checkbox("Skip pulling rares", self.skipRares);
		Separator();
		wasClicked, self.skipHumanoid = Checkbox("Skip pulling humanoids", self.skipHumanoid);
		wasClicked, self.skipElemental = Checkbox("Skip pulling elementals", self.skipElemental);
		wasClicked, self.skipUndead = Checkbox("Skip pulling undeads", self.skipUndead);
		wasClicked, self.skipDemon = Checkbox("Skip pulling demons", self.skipDemon);
		wasClicked, self.skipBeast = Checkbox("Skip pulling beasts", self.skipBeast);
		wasClicked, self.skipMechanical = Checkbox("Skip pulling mechanical", self.skipMechanical);	
		wasClicked, self.skipDragonkin = Checkbox("Skip pulling dragonkin", self.skipDragonkin);	
		wasClicked, self.skipNotspecified = Checkbox("Skip pulling not specified (slimes ect.)", self.skipNotspecified);
		Separator();
		wasClicked, self.skipPlayerTargeted = Checkbox("Skip pulling mobs targeted by other players", self.skipPlayerTargeted);
		wasClicked, self.skipIsTargetingOtherPlayer = Checkbox("Skip pulling mobs targeting other players(Stop stealing mobs from AOE grinders)", self.skipIsTargetingOtherPlayer);
		wasClicked, self.skipMultiPull = Checkbox("Skip pulling multiple mobs at once [EXPERIMENTAL]*", self.skipMultiPull);
		Text("* WARNING: The bot will still walk into their aggro range!");
		Separator();
		Text("Blacklisting (Resets on Reload Script):");
		if (Button("BLACKLIST BY GUID")) then
			if UnitExists("target") then
				DEFAULT_CHAT_FRAME:AddMessage('Blacklisted "'..GetTarget():GetUnitName()..'" GUID: "'..GetTarget():GetGUID()..'"');
				script_grind:addTargetToBlacklist(GetTarget():GetGUID());
			end
		end SameLine();
		if (Button("BLACKLIST BY NAME")) then
			if UnitExists("target") then
				DEFAULT_CHAT_FRAME:AddMessage('Blacklisted "'..GetTarget():GetUnitName()..'" by NAME');
				script_grind:addTargetToNameBlacklist(GetTarget():GetUnitName());
			end
		end
		Text("Target an NPC in game, and press the desired blacklisting method above.");
		Text("");
		Separator();
		Separator();
		Text("Script tick rate options:");
		self.tickRate = SliderFloat("Tick rate (ms)", 0, 2000, self.tickRate);
	end
end