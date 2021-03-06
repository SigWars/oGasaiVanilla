script_followOP = {
	useMount = true,
	disMountRange = 32,
	mountTimer = 0,
	enemyObj = nil,
	lootObj = nil,
	timer = GetTimeEX(),
	tickRate = 150,
	waitTimer = GetTimeEX(),
	pullDistance = 150,
	findLootDistance = 60,
	lootDistance = 2.5,
	skipLooting = false,
	lootCheck = {},
	ressDistance = 25,
	combatError = 0,
	myX = 0,
	myY = 0,
	myZ = 0,
	myTime = GetTimeEX(),
	message = 'Starting the follower...',
	navFunctionsLoaded = include("scripts\\script_nav.lua"),
	helperLoaded = include("scripts\\script_helper.lua"),
	extraFunctions = include("scripts\\script_followEXOP.lua"),
	unstuckLoaded = include("scripts\\script_unstuck.lua"),
	nextToNodeDist = 4, -- (Set to about half your nav smoothness)
	isSetup = false,
	drawUnits = false,
	acceptTimer = GetTimeEX(),
	followDistance = 10,
	followTimer = GetTimeEX(),
	dpsHp = 90,
	isChecked = true,
	pause = false,
	minFollowDist = 8,
	maxFollowDist = 12,
	drawPath = false,
	npclastTarget = 'Sig',
	Interacting = false,
	OPMode = false,
	PartyName = 'Atantu',
	PetName = 'Catuca',
	PetObject = 0,
	MasterObject = 0,
	masterSetup = false,
	IsMoving = false
}

function script_followOP:playersNear()
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    	if (typeObj == 4 and not currentObj:IsDead()) then
			if (currentObj:GetDistance() < 500 and currentObj:GetUnitName() == self.PartyName ) then 
				-- return currentObj;
				self.MasterObject = currentObj;
				--self.message = "Master with name " .. currentObj:GetUnitName() .. " Found..";
				break
			else
				self.MasterObject = 0;
				-- self.message = "Cant find master... move close 200 meters";
			end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nil;
end

function script_followOP:GetMasterPet()
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    	if (typeObj == 3 and not currentObj:IsDead()) then
			if (currentObj:GetDistance() < 500 and currentObj:GetUnitName() == self.PetName ) then 
				-- return currentObj;
				self.PetObject = currentObj;
				--self.message = "Master with name " .. currentObj:GetUnitName() .. " Found..";
				break
			else
				self.PetObject = 0;
				-- self.message = "Cant find master... move close 200 meters";
			end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nil;
end

function script_followOP:window()
	if (self.isChecked) then EndWindow();
		if(NewWindow("Follower OP", 320, 300)) then script_followEXOP:menu(); end
	end
end


function script_followOP:moveInLineOfSight(partyMember)
	if (not partyMember:IsInLineOfSight() or partyMember:GetDistance() > 30) then
		local x, y, z = partyMember:GetPosition();
		script_nav:moveToTarget(GetLocalPlayer(), x , y, z);
		self.timer = GetTimeEX() + 200;
		return true;
	end

	return false;
end

function script_followOP:healBuffParty()
	local localManaM = GetLocalPlayer():GetManaPercentage();
	if (not IsStanding()) then StopMoving(); end
	-- Priest heal and buff
	if (GetNumPartyMembers() > 0) then
		for i = 1, GetNumPartyMembers()+1 do
			local partyM = GetPartyMember(i);
			if (i == GetNumPartyMembers()+1) then partyM = GetLocalPlayer(); end
			local partyMHP = partyM:GetHealthPercentage();
			if (partyMHP > 0 and partyMHP < 90 and localManaM > 5) then
				
				-- Move in line of sight and in range of the party member
				if (script_followOP:moveInLineOfSight(partyM)) then 
					return true; 
				end
				
				-- Renew
				if (localManaM > 10 and partyMHP < 90 and not partyM:HasBuff("Renew") and HasSpell("Renew")) then
					if (Buff('Renew', partyM)) then
						return true;
					end
				end

				-- Shield
				if (localManaM > 10 and partyMHP < 80 and not partyM:HasDebuff("Weakened Soul") and IsInCombat() and HasSpell("Power Word: Shield")) then
					if (Buff('Power Word: Shield', partyM)) then 
						return true; 
					end
				end

				-- Lesser Heal
				if (localManaM > 10 and partyMHP < 70) then
					if (Cast('Lesser Heal', partyM)) then
						self.waitTimer = GetTimeEX() + 3500;
						return true;
					end
				end

				-- Heal
				if (localManaM > 15 and partyMHP < 50 and HasSpell("Heal")) then
					if (Cast('Heal', partyM)) then
						self.waitTimer = GetTimeEX() + 4500;
						return true;
					end
				end

				-- Greater Heal
				if (localManaM > 25 and partyMHP < 30 and HasSpell("Greater Heal")) then
					if (Cast('Greater Heal', partyM)) then
						self.waitTimer = GetTimeEX() + 5500;
						return true;
					end
				end
			end

			if (UnitClass("player") ~= 'Warrior' and UnitClass("player") ~= 'Rogue' and not IsInCombat() and localManaM > 40) then -- buff
				if (not partyM:HasBuff("Power Word: Fortitude") and HasSpell("Power Word: Fortitude")) then
					if (script_followOP:moveInLineOfSight(partyM)) then return true; end -- move to member
					if (Buff("Power Word: Fortitude", partyM)) then
						return true;
					end
				end	
			end

		end
	end -- novo
	return false;
end


function script_followOP:healAndBuffMaster()
	local localMana = GetLocalPlayer():GetManaPercentage();
	if (not IsStanding()) then StopMoving(); end
	-- Priest heal and buff
	-- for i = 1, GetNumPartyMembers()+1 do
	--	local partyMember = GetPartyMember(i);
		local partyMember = self.MasterObject;
		if (partyMember ~= 0) then
	--	self.message = partyMember:GetUnitName(); 
		-- if (i == GetNumPartyMembers()+1) then partyMember = GetLocalPlayer(); end
		local partyMembersHP = partyMember:GetHealthPercentage();
		if (partyMembersHP > 0 and partyMembersHP < 90 and localMana > 5) then
			
			-- Move in line of sight and in range of the party member
			if (script_followOP:moveInLineOfSight(partyMember)) then 
				return true; 
			end
			
			-- Renew
			if (localMana > 10 and partyMembersHP < 90 and not partyMember:HasBuff("Renew") and HasSpell("Renew")) then
				if (Buff('Renew', partyMember)) then
					return true;
				end
			end

			-- Shield
			if (localMana > 10 and partyMembersHP < 80 and not partyMember:HasDebuff("Weakened Soul") and IsInCombat() and HasSpell("Power Word: Shield")) then
				if (Buff('Power Word: Shield', partyMember)) then 
					return true; 
				end
			end

			-- Lesser Heal
			if (localMana > 10 and partyMembersHP < 70) then
				if (Cast('Lesser Heal', partyMember)) then
					self.waitTimer = GetTimeEX() + 3500;
					return true;
				end
			end

			-- Heal
			if (localMana > 15 and partyMembersHP < 50 and HasSpell("Heal")) then
				if (Cast('Heal', partyMember)) then
					self.waitTimer = GetTimeEX() + 4500;
					return true;
				end
			end

			-- Greater Heal
			if (localMana > 25 and partyMembersHP < 30 and HasSpell("Greater Heal")) then
				if (Cast('Greater Heal', partyMember)) then
					self.waitTimer = GetTimeEX() + 5500;
					return true;
				end
			end
		end

		if (not IsInCombat() and localMana > 40) then -- buff
			if (not partyMember:HasBuff("Power Word: Fortitude") and HasSpell("Power Word: Fortitude")) then
				if (script_followOP:moveInLineOfSight(partyMember)) then return true; end -- move to member
				if (Buff("Power Word: Fortitude", partyMember)) then
					return true;
				end
			end	
		end
	-- end
	end -- novo
	return false;
end

function script_followOP:HelpPets()
	local localMana = GetLocalPlayer():GetManaPercentage();
	if (not IsStanding()) then StopMoving(); end

		local partyMember = self.PetObject;
		if (partyMember ~= 0) then
		local partyMembersHP = partyMember:GetHealthPercentage();
		
		-- Ress partMaster Master
		if (partyMember ~= 0 and partyMember:GetUnitName() == self.PetName and not IsInCombat() and partyMember:IsDead()) then
			TargetByName(partyMember:GetUnitName());
			if (Cast('Resurrection', partyMember)) then
				self.message = "Ressurrecting Master...";
				self.waitTimer = GetTimeEX() + 5500;
				return true;
			end
		end
		
		if (partyMembersHP > 0 and partyMembersHP < 90 and localMana > 5 and partyMember:GetUnitName() == self.PetName) then
			
			-- Move in line of sight and in range of the party member
			if (script_followOP:moveInLineOfSight(partyMember)) then 
				return true; 
			end
			
			-- Renew
			if (localMana > 10 and partyMembersHP < 90 and not partyMember:HasBuff("Renew") and HasSpell("Renew")) then
				if (Buff('Renew', partyMember)) then
					return true;
				end
			end

			-- Shield
			if (localMana > 10 and partyMembersHP < 80 and not partyMember:HasDebuff("Weakened Soul") and IsInCombat() and HasSpell("Power Word: Shield")) then
				if (Buff('Power Word: Shield', partyMember)) then 
					return true; 
				end
			end

			-- Lesser Heal
			if (localMana > 10 and partyMembersHP < 70) then
				if (Cast('Lesser Heal', partyMember)) then
					self.waitTimer = GetTimeEX() + 3500;
					return true;
				end
			end

			-- Heal
			if (localMana > 15 and partyMembersHP < 50 and HasSpell("Heal")) then
				if (Cast('Heal', partyMember)) then
					self.waitTimer = GetTimeEX() + 4500;
					return true;
				end
			end

			-- Greater Heal
			if (localMana > 25 and partyMembersHP < 30 and HasSpell("Greater Heal")) then
				if (Cast('Greater Heal', partyMember)) then
					self.waitTimer = GetTimeEX() + 5500;
					return true;
				end
			end
		end

		if (not IsInCombat() and localMana > 40) then -- buff
			if (not partyMember:HasBuff("Power Word: Fortitude") and HasSpell("Power Word: Fortitude")) then
				if (script_followOP:moveInLineOfSight(partyMember)) then return true; end -- move to member
				if (Buff("Power Word: Fortitude", partyMember)) then
					return true;
				end
			end	
		end
	-- end
	end -- novo
	return false;
end

function script_followOP:setup()
	self.lootCheck['timer'] = 0;
	self.lootCheck['target'] = 0;
	script_helper:setup();
	self.isSetup = true;
end

function script_followOP:setWaitTimer(ms)
	self.waitTimer = GetTimeEX() + ms;
end

function script_followOP:GetPartyLeaderObject() 
	return script_followOP:playersNear();
end

function script_followOP:run()
	
	localObj = GetLocalPlayer();
	script_followOP:window();
	
	-- get master player
	if (not localObj:IsDead() and self.MasterObject == 0 or self.MasterObject == nil) then
		self.masterSetup = false;
		script_followOP:playersNear();
		self.message = "Finding master...";
		return;
	else 
		if (not self.masterSetup and self.MasterObject ~= 0) then
			self.message = "Master called " .. self.MasterObject:GetUnitName() .. " Found.";
			self.masterSetup = true;
		end
	end
	-- get master pet
	if 	(self.PetObject == nil or self.PetObject == 0) then
		script_followOP:GetMasterPet();
	end
	
	-- Set next to node distance and nav-mesh smoothness to double that number
	if (IsMounted()) then
		script_nav:setNextToNodeDist(5); NavmeshSmooth(10);
	else
		script_nav:setNextToNodeDist(self.nextToNodeDist); NavmeshSmooth(self.nextToNodeDist*2);
	end
	
	if (not self.isSetup) then
		script_followOP:setup();
	end
	
	if (not self.navFunctionsLoaded) then self.message = "Error script_nav not loaded..."; return; end
	if (not self.helperLoaded) then self.message = "Error script_helper not loaded..."; return; end

	if (self.pause) then self.message = "Paused by user..."; return; end

	-- auto unstuck feature
	if (not script_unstuck:pathClearAuto(2)) then
		self.message = script_unstuck.message;
		return;
	end

	if(GetTimeEX() > self.timer) then
		self.timer = GetTimeEX() + self.tickRate;
		
		-- Wait out the wait-timer and/or casting or channeling
		if (self.waitTimer > GetTimeEX() or IsCasting() or IsChanneling()) then return; end

		-- Automatic loading of the nav mesh
		if (not IsUsingNavmesh()) then UseNavmesh(true); return; end
		if (not LoadNavmesh()) then self.message = "Make sure you have mmaps-files..."; return; end
		if (GetLoadNavmeshProgress() ~= 1) then self.message = "Loading the nav mesh... " return; end

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
				if (script_aggro:safeRess()) then
					script_followOP.message = "Finding a safe spot to ress...";
					return true;
				end
				RetrieveCorpse();
			end
			return;
		end

		-- Check: Rogue only, If we just Vanished, move away from enemies within 30 yards
		if (localObj:HasBuff("Vanish")) then if (script_nav:runBackwards(1, 30)) then 
			ClearTarget(); self.message = "Moving away from enemies..."; return; end 
		end
		
		-- Rest
		if (not IsInCombat() and script_followOP:enemiesAttackingUs() == 0 and not localObj:HasBuff('Feign Death')) then
			-- Move out of water before resting/mounting
			--if (IsSwimming()) then self.message = "Moving out of the water..."; script_nav:navigate(GetLocalPlayer()); return; end
			-- Rest before looting, fighting, pathing etc
			if(RunRestScript()) then
				self.message = "Resting...";
				-- Stop moving
				if (IsMoving() and not localObj:IsMovementDisabed()) then StopMoving(); return; end
				-- Dismount
				if (IsMounted()) then DisMount(); return; end
				-- Add 2500 ms timer to the rest script rotations (timer could be set already)
				if ((self.waitTimer - GetTimeEX()) < 2500) then self.waitTimer = GetTimeEX()+2500 end;
				return;	
			end
		end
		
		-- If bags are full
		if (AreBagsFull() and not IsInCombat()) then
			self.message = 'Warning bags are full...';
		end

		-- Clear dead/tapped targets
		if (self.enemyObj ~= 0 and self.enemyObj ~= nil) then
			if (self.enemyObj:IsDead()) then
			--if ((self.enemyObj:IsTapped() and not self.enemyObj:IsTappedByMe()) 
				--or self.enemyObj:IsDead()) then
				self.enemyObj = nil;
				ClearTarget();
			end
			if (self.MasterObject:GetUnitsTarget() == 0 or self.MasterObject:GetUnitsTarget() == nil) then
				self.enemyObj = nil;
				ClearTarget();
			end
		end

		-- Accept group invite
		if (GetNumPartyMembers() < 1 and self.acceptTimer < GetTimeEX()) then 
			self.acceptTimer = GetTimeEX() + 5000;
			AcceptGroup(); 
		end

		-- Healer check: heal/buff the Master
		if (script_followOP:healAndBuffMaster() and HasSpell('Smite')) then
			self.message = "Healing/buffing the Master...";
			return;
		end
		
		if (script_followOP:HelpPets() and HasSpell('Smite')) then
			self.message = "Healing/buffing the Pets...";
			return;
		end

		-- Healer check: heal/buff the party
		if (GetNumPartyMembers() > 0 and script_followOP:healBuffParty() and HasSpell('Smite')) then
			self.message = "Healing/buffing the party...";
			return;
		end

		-- Loot
		if (not IsInCombat() and script_followOP:enemiesAttackingUs() == 0 and not localObj:HasBuff('Feign Death')) then
			-- Loot if there is anything lootable and we are not in combat and if our bags aren't full
			if (not self.skipLooting and not AreBagsFull()) then 
				self.lootObj = script_nav:getLootTarget(self.findLootDistance);
			else
				self.lootObj = nil;
			end
			if (self.lootObj == 0) then self.lootObj = nil; end
			local isLoot = not IsInCombat() and not (self.lootObj == nil);
			if (isLoot and not AreBagsFull()) then
				script_grindEX:doLoote(localObj);
				return;
			elseif (AreBagsFull() and not hsWhenFull) then
				self.lootObj = nil;
				self.message = "Warning the bags are full...";
			end
		end
		
		-- Randomize the follow range
		if (self.followTimer < GetTimeEX()) then 
			self.followTimer = GetTimeEX() + 20000;
			self.followDistance = math.random(self.minFollowDist,self.maxFollowDist); -- 15,25
		end
		
		-- Follow our master
		--  if (self.MasterObject ~= 0) then
		--	if(self.MasterObject:GetDistance() > self.followDistance 
		--		and not self.MasterObject:IsDead() 
		--		and not self.Interacting 
		--		and not IsInCombat()) then
			
		--		local x, y, z = self.MasterObject:GetPosition();
		--		self.message = "Following " .. self.MasterObject:GetUnitName() .. "...";
		--		script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
		--		return;
		--	end
		-- end
			
		-- Assign the next valid target to be killed
		-- Check if anything is attacking us
		if (script_followOP:enemiesAttackingUs() >= 1) then
			if (HasSpell('Fade') and not IsSpellOnCD('Fade')) then
				CastSpellByName('Fade');
				return;
			end
			if (GetTarget() ~= 0 and GetTarget() ~= nil) then
				local target = GetTarget();
				if (target:CanAttack()) then
					self.enemyObj = target;
				else
					self.enemyObj = nil;
				end
			end
		else
			if (self.MasterObject ~= 0 and self.MasterObject:GetUnitsTarget() ~= 0 and not self.MasterObject:IsDead() and self.MasterObject:GetUnitsTarget():CanAttack()) then
				if (self.MasterObject:GetUnitsTarget():GetHealthPercentage() < self.dpsHp) then
					self.enemyObj = self.MasterObject:GetUnitsTarget();
				else
					self.enemyObj = nil;
				end
			end
		end
		
		-- Check: If we are a priest and we are at least 3 party members, dont do damage if mana below 70%
		if (HasSpell('Smite') and GetNumPartyMembers() > 2 and GetLocalPlayer():GetManaPercentage() < 70) then
			self.enemyObj = nil;
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
			self.followDistance = 35;
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
				ClearTarget(); self.waitTimer = GetTimeEX()+5000; return;
			end
			-- Stop bot, request from a combat script
			if(self.combatError == 6) then self.message = "Combat script request stop bot..."; Logout(); StopBot(); return; end
		else 
			self.followDistance = math.random(self.minFollowDist,self.maxFollowDist);
		end

		-- Pre checks before navigating
		if(IsLooting() or IsCasting() or IsChanneling() or IsDrinking() or IsEating() or IsInCombat()) then return; end

		-- Mount before we follow our master
		if (script_followOP:mountUp()) then return; end		
		
		-- Follow our master
		if (self.MasterObject ~= 0) then
			if(self.MasterObject:GetDistance() > self.followDistance and not self.MasterObject:IsDead() and not self.Interacting) then
				local x, y, z = self.MasterObject:GetPosition();
				self.message = "Following our master...";
				script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
				return;
			end
		end
		
		-- interact with the master target
		if (self.MasterObject ~= 0 and not IsInCombat() and not RunRestScript()) then
			
			local newTarget = self.MasterObject:GetUnitsTarget();
			
			if (newTarget ~= 0 and newTarget ~= nil and not self.MasterObject:IsDead() and not newTarget:IsDead() and not newTarget:CanAttack()) then	
				local interactTarget = nil;

				--TargetByName(self.MasterObject:GetUnitsTarget():GetUnitName());
				--if (GetTarget() ~= 0 and GetTarget() ~= nil and not RunRestScript() and not IsInCombat()) then
				--	interactTarget = GetTarget();
				-- end
				interactTarget = self.MasterObject:GetUnitsTarget();
				
				if (self.npclastTarget ~= interactTarget:GetUnitName()) then
					CloseWindows();
				end
				
				if (interactTarget ~= nil and not interactTarget:CanAttack() and not RunRestScript() and not IsInCombat()) then
					self.Interacting = true;
					self.message = 'Interact...';
					if (interactTarget:GetDistance() > 5) then
						TargetByName(self.MasterObject:GetUnitsTarget():GetUnitName());
						local x, y, z = interactTarget:GetPosition();
						self.message = "Moving to " interactTarget:GetUnitName();
						script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
						return;
					end
					
					if (not IsVendorWindowOpen()) then
						-- SkipGossip();
						if (interactTarget:UnitInteract()) then
							self.npclastTarget = interactTarget:GetUnitName(); 
							--return true;
						end
					end
				end
			else
				self.Interacting = false;
				-- ClearTarget();
			end	
		end
	end 
end

function script_followOP:mountUp()
	local __, lastError = GetLastError();
	if (lastError ~= 75 and self.mountTimer < GetTimeEX()) then
		-- TODO: change in 2.1.11
		-- local _, isSwimming = IsSwimming();
		if(GetLocalPlayer():GetLevel() >= 40 and self.useMount and not IsIndoors() and not IsMounted() and self.lootObj == nil) then
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

function script_followOP:getTarget()
	return self.enemyObj;
end

function script_followOP:getTargetAttackingUs() 
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

function script_followOP:assignTarget() 
	-- Instantly return the last target if we attacked it and it's still alive and we are in combat
	if (self.enemyObj ~= 0 and self.enemyObj ~= nil and not self.enemyObj:IsDead()) then -- and IsInCombat()
		if (script_followOP:isTargetingMe(self.enemyObj)
			or script_followOP:isTargetMasterPet(self.enemyObj)
			or script_followOP:isTargetingPet(self.enemyObj) 
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
			if (script_followOP:enemyIsValid(i)) then
				-- save the closest mob or mobs attacking us
				if (mobDistance > i:GetDistance()) then
					mobDistance = i:GetDistance();	
					closestTarget = i;
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

function script_followOP:isTargetingPet(i) 
	local pet = GetPet();
	if (pet ~= nil and pet ~= 0 and not pet:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == pet:GetGUID();
		end
	end
	return false;
end

function script_followOP:isTargetingMe(i) 
	local localPlayer = GetLocalPlayer();
	if (localPlayer ~= nil and localPlayer ~= 0 and not localPlayer:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == localPlayer:GetGUID();
		end
	end
	return false;
end

function script_followOP:isTargetingMaster(i) 
	if (self.MasterObject ~= 0 and not self.MasterObject:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == self.MasterObject:GetGUID();
		end
	end
	return false;
end

function script_followOP:isTargetMasterPet(i) 
	local pet = self.PetObject;
	if (pet ~= nil and pet ~= 0 and not pet:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == pet:GetGUID();
		end
	end
	return false;
end

function script_followOP:enemyIsValid(i)
	if (i ~= 0) then
		-- Valid Targets: Tapped by us, or is attacking us or our pet
		if (script_followOP:isTargetingMe(i)
			or script_followOP:isTargetingMaster(i)
			or script_followOP:isTargetMasterPet(i)
			or (script_followOP:isTargetingPet(i) and (i:IsTappedByMe() or not i:IsTapped())) 
			or (i:IsTappedByMe() and not i:IsDead())) then 
				return true; 
		end
	end
	return false;
end

function script_followOP:enemiesAttackingUs() -- returns number of enemies attacking us
	local unitsAttackingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    		if typeObj == 3 then
			if (currentObj:CanAttack() and not currentObj:IsDead()) then
                		if (script_followOP:isTargetingMe(currentObj)) then 
                			unitsAttackingUs = unitsAttackingUs + 1; 
                		end 
            		end 
       		end
      	currentObj, typeObj = GetNextObject(currentObj); 
	end
   	return unitsAttackingUs;
end

function script_followOP:playersTargetingUs() -- returns number of players attacking us
	local nrPlayersTargetingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
	if typeObj == 4 then
		if (script_followOP:isTargetingMe(currentObj)) then 
                	nrPlayersTargetingUs = nrPlayersTargetingUs + 1; 
                end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nrPlayersTargetingUs;
end

function script_followOP:playersWithinRange(range)
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

function script_followOP:getDistanceDif()
	local x, y, z = GetLocalPlayer():GetPosition();
	local xV, yV, zV = self.myX-x, self.myY-y, self.myZ-z;
	return math.sqrt(xV^2 + yV^2 + zV^2);
end

function script_followOP:draw()
	script_followEXOP:drawStatus();
	-- if (IsMoving()) then script_nav:drawPath() end
	-- if (self.drawPath) then script_nav:drawPath() end
end