script_follow = {
	useMount = true,
	disMountRange = 32,
	mountTimer = 0,
	enemyObj = nil,
	lootObj = nil,
	timer = GetTimeEX(),
	msgTimer = GetTimeEX() + 10000,
	tickRate = 150,
	waitTimer = GetTimeEX(),
	pullDistance = 150,
	findLootDistance = 60,
	lootDistance = 2.5,
	skipLooting = false,
	lootCheck = {},
	lootWait = GetTimeEX(),
	ressDistance = 25,
	combatError = 0,
	myX = 0,
	myY = 0,
	myZ = 0,
	myTime = GetTimeEX(),
	message = 'Starting the follower...',
	navFunctionsLoaded = include("scripts\\script_nav.lua"),
	helperLoaded = include("scripts\\script_helper.lua"),
	extraFunctions = include("scripts\\script_followEX.lua"),
	unstuckLoaded = include("scripts\\script_unstuck.lua"),
	gatherLoaded = include("scripts\\script_gather.lua"),
	talentLoaded = include("scripts\\script_talent.lua"),
	enableGather = fale,
	gatherForQuest = false,
	gatherQuestDistance = 10,
	QuestObjectName1 = 'None',
	QuestObjectName2 = 'None',
	QuestObjectName3 = 'Number',
	useQuestItem = false,
	questItemName = "Foreman's Blackjack",
	objectiveName = 'Lazy Peon,None',
	drawGather = false,
	nextToNodeDist = 3, -- (Set to about half your nav smoothness)
	isSetup = false,
	drawUnits = false,
	acceptTimer = GetTimeEX(),
	followDistance = 10,
	followTimer = GetTimeEX(),
	dpsHp = sig_scripts:classVars("dpsHp"),
	isChecked = true,
	pause = false,
	pauseFly  = false,
	minFollowDist = sig_scripts:classVars("minFollowDist"),
	maxFollowDist = sig_scripts:classVars("maxFollowDist"),
	drawPath = false,
	npclastTarget = 'Sig',
	Interacting = false,
	PetObject = nil,
	ptLeader = nil,
	targetOfptLeader = nil,
	PetName = 'Gelpit',
	IgnoreAttacks = false,
	autoTalent = false,
	tankMode = false
}

function script_follow:window()
	if (self.isChecked) then EndWindow();
		if(NewWindow("Logitech's Follower", 320, 300)) then script_followEX:menu(); end
	end
end


function script_follow:moveInLineOfSight(partyMember)
	if (not partyMember:IsInLineOfSight() or partyMember:GetDistance() > 30) then
		local x, y, z = partyMember:GetPosition();
		script_nav:moveToTarget(GetLocalPlayer(), x , y, z);
		self.timer = GetTimeEX() + 200;
		return true;
	end

	return false;
end

function script_follow:HelpPets()
	
	-- Prevent run away bug	
	if (self.PetObject ~= 0 and self.PetObject ~= nil and sig_scripts:CalculateDistance(localObj,self.PetObject) < 150) then
	
		local localMana = GetLocalPlayer():GetManaPercentage();
		if (not IsStanding()) then StopMoving(); end
		
		local PetHP = self.PetObject:GetHealthPercentage();
		
		-- Revive
		if (not IsInCombat() and self.PetObject:IsDead()) then
			if (self.PetObject:GetDistance() > 20) then
				if (script_follow:moveInLineOfSight(self.PetObject)) then 
					return true; 
				end
			end
			if (Cast('Resurrection', self.PetObject)) then
				self.message = "Ressurrecting Master...";
				self.waitTimer = GetTimeEX() + 5500;
				return true;
			end
		end
		
		--[[
		-- Ress partMaster Master
		if (self.PetObject:GetUnitName() == self.PetName and not IsInCombat() and self.PetObject:IsDead()) then
			-- TargetByName(self.PetObject:GetUnitName());
			if (Cast('Resurrection', self.PetObject)) then
				self.message = "Ressurrecting Master Pet...";
				self.waitTimer = GetTimeEX() + 5500;
				return true;
			end
		end]]--
		
		if (PetHP > 0 and PetHP < 90 and localMana > 5 and self.PetObject:GetUnitName() == self.PetName) then
			
			-- Move in line of sight and in range of the party member
			 if (script_follow:moveInLineOfSight(self.PetObject)) then 
				return true; 
			 end
			
			-- Renew
			if (localMana > 10 and PetHP < 90 and not self.PetObject:HasBuff("Renew") and HasSpell("Renew")) then
				if (Buff('Renew', self.PetObject)) then
					return true;
				end
			end

			-- Shield
			if (localMana > 10 and PetHP < 80 and not self.PetObject:HasDebuff("Weakened Soul") and IsInCombat() and HasSpell("Power Word: Shield")) then
				if (Buff('Power Word: Shield', self.PetObject)) then 
					return true; 
				end
			end

			-- Lesser Heal
			if (localMana > 10 and PetHP < 70) then
				if (Cast('Lesser Heal', self.PetObject)) then
					self.waitTimer = GetTimeEX() + 3500;
					return true;
				end
			end

			-- Heal
			if (localMana > 15 and PetHP < 50 and HasSpell("Heal")) then
				if (Cast('Heal', self.PetObject)) then
					self.waitTimer = GetTimeEX() + 4500;
					return true;
				end
			end

			-- Greater Heal
			if (localMana > 25 and PetHP < 30 and HasSpell("Greater Heal")) then
				if (Cast('Greater Heal', self.PetObject)) then
					self.waitTimer = GetTimeEX() + 5500;
					return true;
				end
			end
		end
		-- Buffs
		if (not IsInCombat() and localMana > 40) then -- buff
			if (not self.PetObject:HasBuff("Shadow Protection") and HasSpell("Shadow Protection")) then
				if (script_follow:moveInLineOfSight(self.PetObject)) then return true; end -- move to member
				if (Buff("Shadow Protection", self.PetObject)) then
					return true;
				end
			end	
		end
		
		if (not IsInCombat() and localMana > 40) then -- buff
			if (not self.PetObject:HasBuff("Power Word: Fortitude") and HasSpell("Power Word: Fortitude")) then
				if (script_follow:moveInLineOfSight(self.PetObject)) then return true; end -- move to member
				if (Buff("Power Word: Fortitude", self.PetObject)) then
					return true;
				end
			end	
		end
	
	end -- Primeira
	return false;
end -- function

function script_follow:healAndBuff()
	
	local class = UnitClass("player");

	local localMana = GetLocalPlayer():GetManaPercentage();
	if (not IsStanding()) then StopMoving(); end
	-- Priest heal and buff
	for i = 1, GetNumPartyMembers()+1 do
		local partyMember = GetPartyMember(i);
		if (i == GetNumPartyMembers()+1) then partyMember = GetLocalPlayer(); end
		local partyMembersHP = partyMember:GetHealthPercentage();
		
		---------------------------
		-- PRIEST
		---------------------------
		if (class == 'Priest') then
			if (partyMember ~= nil and partyMember ~= 0 and sig_scripts:CalculateDistance(localObj,partyMember) < 100) then
				
				-- Revive
				if (not IsInCombat() and partyMember:IsDead()) then
					if (not partyMember:IsSpellInRange('Resurrection')) then
						if (script_follow:moveInLineOfSight(partyMember)) then 
							return true; 
						end
					end
					if (Cast('Resurrection', partyMember)) then
						self.message = "Ressurrecting Master...";
						self.waitTimer = GetTimeEX() + 5500;
						return true;
					end
				end
				
				if (partyMembersHP > 0 and partyMembersHP < 99 and localMana > 5) then
					
					
					-- Renew
					if (localMana > 10 and partyMembersHP < 90 and not partyMember:HasBuff("Renew") and HasSpell("Renew")) then
						if (not partyMember:IsSpellInRange('Renew')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								return true; 
							end
						end
						if (Buff('Renew', partyMember)) then
							return true;
						end
					end

					-- Shield
					if (localMana > 10 and partyMembersHP < 80 and not partyMember:HasDebuff("Weakened Soul") and IsInCombat() and HasSpell("Power Word: Shield")) then
						if (not partyMember:IsSpellInRange('Power Word: Shield')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								return true; 
							end
						end
						if (Buff('Power Word: Shield', partyMember)) then 
							return true; 
						end
					end

					-- Lesser Heal
					if (localMana > 10 and partyMembersHP < 70) then
						if (not partyMember:IsSpellInRange('Lesser Heal')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								return true; 
							end
						end
						if (Cast('Lesser Heal', partyMember)) then
							self.waitTimer = GetTimeEX() + 3500;
							return true;
						end
					end

					-- Heal
					if (localMana > 15 and partyMembersHP < 50 and HasSpell("Heal")) then
						if (not partyMember:IsSpellInRange('Heal')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								return true; 
							end
						end
						if (Cast('Heal', partyMember)) then
							self.waitTimer = GetTimeEX() + 4500;
							return true;
						end
					end

					-- Greater Heal
					if (localMana > 25 and partyMembersHP < 30 and HasSpell("Greater Heal")) then
						if (not partyMember:IsSpellInRange('Greater Heal')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								return true; 
							end
						end
						if (Cast('Greater Heal', partyMember)) then
							self.waitTimer = GetTimeEX() + 5500;
							return true;
						end
					end
				end
				
				-- Buffs
				if (partyMember ~= nil and partyMember ~= 0 and not IsInCombat() and localMana > 40 and partyMember:GetDistance() < 100) then -- buff
					if (not partyMember:HasBuff("Shadow Protection") and HasSpell("Shadow Protection")) then
						if (script_follow:moveInLineOfSight(partyMember)) then return true; end -- move to member
						if (Buff("Shadow Protection", partyMember)) then
							return true;
						end
					end	
				end

				if (partyMember ~= nil and partyMember ~= 0 and not IsInCombat() and localMana > 40 and partyMember:GetDistance() < 100) then -- buff
					if (not partyMember:HasBuff("Power Word: Fortitude") and HasSpell("Power Word: Fortitude")) then
						if (script_follow:moveInLineOfSight(partyMember)) then return true; end -- move to member
						if (Buff("Power Word: Fortitude", partyMember)) then
							return true;
						end
					end	
				end
			end -- Primeira
		end -- Priest
		
		---------------------------
		-- MAGE
		---------------------------
		if (class == 'Mage') then
			if (partyMember ~= nil and partyMember ~= 0 and sig_scripts:CalculateDistance(localObj,partyMember) < 100) then
				
				if (partyMembersHP > 0 and localMana > 5) then
			

					-- Heal
					--[[
					if (localMana > 15 and partyMembersHP < 50 and HasSpell("Heal")) then
						if (not partyMember:IsSpellInRange('Greater Heal')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								return true; 
							end
						end
						if (Cast('Heal', partyMember)) then
							self.waitTimer = GetTimeEX() + 4500;
							return true;
						end
					end
					]]--
					
					--------------------
					-- Buffs
					--------------------
					if (partyMember ~= nil and partyMember ~= 0 and not IsInCombat() and localMana > 40 and partyMember:GetDistance() < 100) then -- buff
						if (not partyMember:HasBuff("Arcane Intellect") and HasSpell("Arcane Intellect")) then
							if (script_follow:moveInLineOfSight(partyMember)) then return true; end -- move to member
							if (Buff("Arcane Intellect", partyMember)) then
								return true;
							end
						end	
					end

				end
			end 
		end -- Mage
		
		---------------------------
		-- SHAMAN
		---------------------------
		if (class == 'Shaman') then
			if (partyMember ~= nil and partyMember ~= 0 and sig_scripts:CalculateDistance(localObj,partyMember) < 100) then
				
				if (partyMembersHP > 0 and localMana > 5) then

					-- Heal
					if (localMana > 15 and partyMembersHP < 50 and HasSpell("Healing Wave")) then
						if (not partyMember:IsSpellInRange('Greater Heal')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								return true; 
							end
						end
						if (Cast('Healing Wave', partyMember)) then
							self.waitTimer = GetTimeEX() + 2500;
							return true;
						end
					end
					
					--------------------
					-- Buffs
					--------------------
					--[[
					if (partyMember ~= nil and partyMember ~= 0 and not IsInCombat() and localMana > 40 and partyMember:GetDistance() < 100) then -- buff
						if (not partyMember:HasBuff("Arcane Intellect") and HasSpell("Arcane Intellect")) then
							if (script_follow:moveInLineOfSight(partyMember)) then return true; end -- move to member
							if (Buff("Arcane Intellect", partyMember)) then
								return true;
							end
						end	
					end
					]]--

				end
			end 
		end -- Shaman
			
	end -- For Loop

	return false;
end

function script_follow:setup()
	self.lootCheck['timer'] = 0;
	self.lootCheck['target'] = 0;
	script_helper:setup();
	script_talent:setup();
	script_gather:setup();
	self.isSetup = true;
end

function script_follow:setWaitTimer(ms)
	self.waitTimer = GetTimeEX() + ms;
end

function script_follow:GetPartyLeaderObject() 
	if GetNumPartyMembers() > 0 then -- are we in a party?
		leaderObj = GetPartyMember(GetPartyLeaderIndex());
		if (leaderObj ~= nil) then
			return leaderObj;
		end
	end
	return 0;
end

function script_follow:GetMasterPet()
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    	if (typeObj == 3 and not currentObj:IsDead()) then
			if (currentObj:GetUnitName() == self.PetName ) then 
				return currentObj;
				--self.message = "Master with name " .. currentObj:GetUnitName() .. " Found..";
			end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return 0;
end

function script_follow:run()

	script_follow:window();
	
	-- Pause bot on fly to prevent lose master and pet
	local voando = UnitOnTaxi("player"); -- self.message = "Voando  =" .. tostring(voando);
	if (voando ~= nil) then
		if (voando == 1) then
			self.pauseFly = true;
			self.PetObject = 0;
		end
	else
		self.pauseFly = false;
	end
	
	-- Set next to node distance and nav-mesh smoothness to double that number
	if (IsMounted()) then
		script_nav:setNextToNodeDist(5); NavmeshSmooth(10);
	else
		script_nav:setNextToNodeDist(self.nextToNodeDist); NavmeshSmooth(self.nextToNodeDist*2);
	end
	
	if (not self.isSetup) then
		script_follow:setup();
	end
	
	if (not self.navFunctionsLoaded) then self.message = "Error script_nav not loaded..."; return; end
	if (not self.helperLoaded) then self.message = "Error script_helper not loaded..."; return; end

	if (self.pause) then self.message = "Paused by user..."; return; end
	
	if (self.pauseFly) then self.message = "Paused when flying..."; return; end
	
	-- Check: Spend talent points
	if (not IsInCombat() and not GetLocalPlayer():IsDead() and self.autoTalent) then
		if (script_talent:learnTalents()) then
			self.message = "Checking/learning talent: " .. script_talent:getNextTalentName();
			return;
		end
	end
	
	-- auto unstuck feature
	if (not script_unstuck:pathClearAuto(2)) then
		self.message = script_unstuck.message;
		return;
	end
	
	localObj = GetLocalPlayer();
	self.ptLeader = script_follow:GetPartyLeaderObject();
	self.targetOfptLeader = self.ptLeader:GetUnitsTarget();
	self.PetObject = script_follow:GetMasterPet();
	
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
				if (script_aggro:safeRess(_lx, _ly, _lz, self.ressDistance)) then
					script_follow.message = "Finding a safe spot to ress...";
					return true;
				end
				RetrieveCorpse();
			end
			return;
		end
		
		-- Automatically reset gather status and time to loot
		if (IsInCombat()) then
			-- self.lootWait = GetTimeEX() + 3000;
			script_gather.timeGather = GetTimeEX() + 1000;
			script_gather.isGathering = false;
		end

		-- Check: Rogue only, If we just Vanished, move away from enemies within 30 yards
		if (localObj:HasBuff("Vanish")) then if (script_nav:runBackwards(1, 30)) then 
			ClearTarget(); self.message = "Moving away from enemies..."; return; end 
		end
		
		-- Rest
		if (not IsInCombat() and script_follow:enemiesAttackingUs() == 0 and not localObj:HasBuff('Feign Death')) then
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
			if ((self.enemyObj:IsTapped() and not self.enemyObj:IsTappedByMe()) 
				or self.enemyObj:IsDead()) then
				self.enemyObj = nil;
				ClearTarget();
			end
		end

		-- Accept group invite
		if (GetNumPartyMembers() < 1 and self.acceptTimer < GetTimeEX()) then 
			self.acceptTimer = GetTimeEX() + 5000;
			AcceptGroup(); 
		end

		-- Healer check: heal/buff the party
		if (script_follow:healAndBuff() and HasSpell('Smite')) then
			self.message = "Healing/buffing the party ";
			return;
		end
		-- Priest heal Master Pet
		if (self.PetObject ~= 0 and script_follow:HelpPets() and HasSpell('Smite')) then
			self.message = "Healing/buffing pet " .. self.PetObject:GetUnitName() .. "...";
			return;
		end
		
		-- Loot
		if ((self.enemyObj == 0 or self.enemyObj == nil)
			and not IsInCombat() 
			and script_follow:enemiesAttackingUs() == 0 
			and not localObj:HasBuff('Feign Death') 
			-- and GetTimeEX() > self.lootWait 
			and (self.targetOfptLeader == 0 or self.targetOfptLeader == nil)) then
			-- Loot if there is anything lootable and we are not in combat and if our bags aren't full
			if (not self.skipLooting and not AreBagsFull()) then 
				self.lootObj = script_nav:getLootTarget(self.findLootDistance);
			else
				self.lootObj = nil;
			end
			if (self.lootObj == 0) then self.lootObj = nil; end
			local isLoot = not IsInCombat() and not (self.lootObj == nil) and sig_scripts:isAreaNearTargetSafe(self.lootObj);
			if (isLoot and not AreBagsFull()) then
				script_grindEX:doLoot(localObj);
				return;
			elseif (AreBagsFull() and not hsWhenFull) then
				self.lootObj = nil;
				self.message = "Warning the bags are full...";
			elseif (not (self.lootObj == nil) and not sig_scripts:isAreaNearTargetSafe(self.lootObj)) then
				self.message = "Corpose is in unsafe area...";
				self.lootObj = nil;
			end
		end
		
		--[[if (not IsInCombat() and script_follow:enemiesAttackingUs() == 0 and not localObj:HasBuff('Feign Death')) then
			-- Loot if there is anything lootable and we are not in combat and if our bags aren't full
			if (not self.skipLooting and not AreBagsFull()) then 
				self.lootObj = script_nav:getLootTarget(self.findLootDistance);
			else
				self.lootObj = nil;
			end
			if (self.lootObj == 0) then self.lootObj = nil; end
			local isLoot = not IsInCombat() and not (self.lootObj == nil) and sig_scripts:isAreaNearTargetSafe(self.lootObj);
			if (isLoot and not AreBagsFull()) then
				script_grindEX:doLoot(localObj);
				return;
			elseif (AreBagsFull() and not hsWhenFull) then
				self.lootObj = nil;
				sig_scripts.message = "Warning the bags are full...";
			elseif (not (self.lootObj == nil) and not sig_scripts:isAreaNearTargetSafe(self.lootObj)) then
				sig_scripts.message = "Corpose is in unsafe area...";
				self.lootObj = nil;	
			end
		end]]--
				
		-- Randomize the follow range
		if (self.followTimer < GetTimeEX()) then 
			self.followTimer = GetTimeEX() + 5000;
			self.followDistance = math.random(self.minFollowDist,self.maxFollowDist); -- 15,25
		end

		-- Follow in combat self.IgnoreAttacks 
		if (self.ptLeader ~= 0 and self.ptLeader ~= nil and self.targetOfptLeader ~= 0 and self.targetOfptLeader ~= nil) then
			if(self.targetOfptLeader:GetGUID() == self.ptLeader:GetGUID()) then
				-- Disable Combat Script and Target Script
				self.enemyObj = nil
				ClearTarget();
				self.IgnoreAttacks = true;
				self.message = "Following " .. self.ptLeader:GetUnitName() .. " ignoring combat...";
				
				-- Follow
				if (self.ptLeader:GetDistance() > self.followDistance) then
					local x, y, z = self.ptLeader:GetPosition();
					script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
				end	
				
				-- Return
				return;
			else
				self.IgnoreAttacks = false;
			end
		else	
			self.IgnoreAttacks = false;
		end 
		
		-- Use item for quests in target of the party leader
		-- Kodo Kombobulator
		if ((self.enemyObj == 0 or self.enemyObj == nil) and self.useQuestItem and not IsInCombat()) then
			--[[if (sig_scripts:usequestItem(self.objectiveName, self.questItemName, 40)) then
				self.waitTimer = GetTimeEX() + 5000;
				return;
			end]]--
			
			if (self.ptLeader ~= 0) then
				
				if (self.targetOfptLeader ~= 0) then
					local lista = { strsplit(',', self.objectiveName) };
					
					for i, unitname in ipairs(lista) do 
						-- DEFAULT_CHAT_FRAME:AddMessage(unitname);
						
						if (self.targetOfptLeader:GetUnitName() == unitname) then
							if(self.questItemName ~= 'None')then
								-- Follow
								if (self.targetOfptLeader:GetDistance() > 2.5) then
									local x, y, z = self.targetOfptLeader:GetPosition();
									script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
									-- self.waitTime = GetTimeEX() + 1000
								else 
								-- UseItem
									TargetByName(self.targetOfptLeader:GetUnitName());
									sig_scripts:UseContainerItemByName(self.questItemName);
									-- self.waitTime = GetTimeEX() + 5000
								end	
								return;
							end	
						end
					end 
					
				end
				
			end
			
		end
		
		
		--[[if ((self.enemyObj == 0 or self.enemyObj == nil) and self.useQuestItem and not IsInCombat()) then
			if (sig_scripts:usequestItem(self.objectiveName, self.questItemName, 40)) then
				self.waitTimer = GetTimeEX() + 5000;
				return;
			end
		end]]--
		
		
		-- Gather for Quests
		if ((self.enemyObj == 0 or self.enemyObj == nil) and not IsInCombat() and not AreBagsFull() and not self.bagsFull and not self.Interacting and self.gatherForQuest) then 
			if (script_gather:gatherquest()) then
				-- self.message = 'Gathering ' .. '...';
				if (GetNumPartyMembers() > 1) then
					if (GetTimeEX() > self.msgTimer) then
						self.msgTimer = GetTimeEX() + 100000;
						SendChatMessage(sig_scripts:randomgatherMsg() ,"PARTY" ,"ORCISH" ,"");	
					end
				end
				return;
			end
		end
		
		-- Gather
		if ((self.enemyObj == 0 or self.enemyObj == nil) and not IsInCombat() and not AreBagsFull() and not self.bagsFull and not self.Interacting and self.enableGather) then 
			if (script_gather:haveGathernode()) then
				-- if (not script_gather.isGathering) then
					script_gather:gather(); -- Gather node
					self.message = script_gather.message; --'Gathering ' .. script_gather:currentGatherName() .. '...';
					-- send mensage to partymembers
					if (GetNumPartyMembers() > 1) then
						if (GetTimeEX() > self.msgTimer) then
							self.msgTimer = GetTimeEX() + 100000;
							SendChatMessage(sig_scripts:randomgatherMsg() ,"PARTY" ,"ORCISH" ,"");	
						end
					end
				-- end
				return;
			end
		end

		-- Assign the next valid target to be killed
		-- Check if anything is attacking us
		if (self.ptLeader ~= 0 and not self.ptLeader:IsDead() and not self.IgnoreAttacks) then
			-- local result, pguiD =  sig_scripts:isTargetingGroup(self.targetOfptLeader);
			
			if (script_follow:enemiesAttackingUs() >= 1) then
				if (HasSpell('Fade') and not IsSpellOnCD('Fade')) then
					CastSpellByName('Fade');
					return;
				end
			end	
			
			if (self.targetOfptLeader ~= 0 
				and not self.targetOfptLeader:IsDead()    
				and self.targetOfptLeader:GetHealthPercentage() <= self.dpsHp 
				and self.targetOfptLeader:CanAttack()) then
				
				-- self.lootWait = GetTimeEX() + 1000;
				self.enemyObj = self.targetOfptLeader;
			else
				self.enemyObj = nil;
			end
		end
		-- Attack if Leader not have target or AFK
		if (IsInCombat() and script_follow:enemiesAttackingUs() >= 1 and not self.IgnoreAttacks and (self.targetOfptLeader == 0 or self.targetOfptLeader == nil)) then
			-- Try to avoid Agro first
			if (HasSpell('Fade') and not IsSpellOnCD('Fade')) then
				CastSpellByName('Fade');
				return;
			end
			-- Get Target Again
			if (GetTarget() ~= 0 and GetTarget() ~= nil) then
				local target = GetTarget();
				if (target:CanAttack()) then
					self.enemyObj = target;
				else
					self.enemyObj = nil;
				end
			end
		end
		-- check all time if have enemyes attacking group memeber and return eneny
		if (sig_scripts:needTaunt(50) ~= 0 and not self.IgnoreAttacks) then
			local newTarget = sig_scripts:needTaunt(50);
			if (self.targetOfptLeader == 0 or self.targetOfptLeader == nil) then
					self.enemyObj = newTarget; 
			end
		end	
		
		 --[[
		 -- Check: If we are a priest and we are at least 3 party members, dont do damage if mana below 90%
		 if (HasSpell('Smite') and GetNumPartyMembers() > 1 and GetLocalPlayer():GetManaPercentage() < 90) then
		 	self.enemyObj = nil;
		 end
		 ]]--
		
		-- Check: If we are a priest and not do damage if pet life below 70%
		 if (HasSpell('Smite') and self.PetObject ~= nil and self.PetObject ~= 0 and self.PetObject:GetHealthPercentage() < 70) then
		 	self.enemyObj = nil;
		 end

		-- Check: If we are a priest and not do damage if Leader life below 70%
		 if (HasSpell('Smite') and self.ptLeader ~= 0 and self.ptLeader:GetHealthPercentage() < 70) then
		 	self.enemyObj = nil;
		 end
		 
		 -- Check: If we are a priest and not do damage if Leader life below 70%
		 if (HasSpell('Healing Wave') and self.ptLeader ~= 0 and self.ptLeader:GetHealthPercentage() < 70) then
		 	self.enemyObj = nil;
		 end
		
		
		
		-- Finish loot before we engage new targets or navigate
		if (GetTimeEX() > self.lootWait and self.lootObj ~= nil and self.enemyObj == nil and (self.ptLeader:GetUnitsTarget() == nil or self.ptLeader:GetUnitsTarget() == 0)) then 
			return; 
		else
			-- reset the combat status
			self.combatError = nil; 
			-- Run the combat script and retrieve combat script status if we have a valid target
			if (self.enemyObj ~= nil and self.enemyObj ~= 0 and not self.IgnoreAttacks) then
				self.combatError = RunCombatScript(self.enemyObj:GetGUID());
			end
		end

		if(not self.IgnoreAttacks and IsInCombat() or (self.enemyObj ~= nil and self.enemyObj ~= 0)) then
		
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
		end

		-- Pre checks before navigating
		if(IsLooting() or IsCasting() or IsChanneling() or IsDrinking() or IsEating() or IsInCombat()) then return; end

		-- Mount before we follow our master
		if (script_follow:mountUp()) then return; end		
		
		-- Follow our master
		if (self.ptLeader ~= 0 and not self.Interacting and not script_gather.isGathering and not script_gather.isGatheringQuest) then
			if(self.ptLeader:GetDistance() > self.followDistance and not self.ptLeader:IsDead()) then
				local x, y, z = self.ptLeader:GetPosition();
				-- self.message = "Following " .. self.ptLeader:GetUnitName() .. "...";
				script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
				return;
			end
		end
		
		-- interact with the master target
		if (self.ptLeader ~= 0 and not IsInCombat() and not self.useQuestItem) then
			
			local newTarget = self.ptLeader:GetUnitsTarget();
			
			if (newTarget ~= 0 and newTarget ~= nil and not self.ptLeader:IsDead() and not newTarget:IsDead()) then	
				local interactTarget = nil;

				--TargetByName(self.ptLeader:GetUnitsTarget():GetUnitName());
				--if (GetTarget() ~= 0 and GetTarget() ~= nil and not RunRestScript() and not IsInCombat()) then
				--	interactTarget = GetTarget();
				-- end
				interactTarget = self.ptLeader:GetUnitsTarget();
				
				if (self.npclastTarget ~= interactTarget:GetUnitName()) then
					CloseWindows();
				end
				
				if (interactTarget ~= nil and not interactTarget:CanAttack() and not IsInCombat() 
				and interactTarget:GetGUID() ~= self.ptLeader:GetGUID()) then
					self.Interacting = true;
					self.message = "Interacting with " .. interactTarget:GetUnitName();
					if (interactTarget:GetDistance() > 4) then
						TargetByName(self.ptLeader:GetUnitsTarget():GetUnitName());
						local x, y, z = interactTarget:GetPosition();
						self.message = "Moving to " .. interactTarget:GetUnitName();
						script_nav:moveToNav(GetLocalPlayer(), x, y, z);
					end
					
					if (not IsVendorWindowOpen()) then
						-- SkipGossip();
						if (interactTarget:UnitInteract()) then
							self.npclastTarget = interactTarget:GetUnitName(); 
							-- return;
						end
					end
					return;
				end
			else
				self.Interacting = false;
			end	
		end
	end 
end

function script_follow:mountUp()
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

function script_follow:getTarget()
	return self.enemyObj;
end

function script_follow:getTargetAttackingUs() 
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

function script_follow:assignTarget() 
	-- Instantly return the last target if we attacked it and it's still alive and we are in combat
	if (self.enemyObj ~= 0 and self.enemyObj ~= nil and not self.enemyObj:IsDead() and IsInCombat()) then
		if (script_follow:isTargetingMe(self.enemyObj)
			or script_follow:isTargetMasterPet(self.enemyObj)
			or script_follow:isTargetingPet(self.enemyObj) 
			or script_grind:isTargetingGroup(self.enemyObj)
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
			if (script_follow:enemyIsValid(i)) then
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

function script_follow:isTargetingPet(i) 
	local pet = GetPet();
	if (pet ~= nil and pet ~= 0 and not pet:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == pet:GetGUID();
		end
	end
	return false;
end

function script_follow:isTargetMasterPet(i) 
	local pet = self.PetObject;
	if (pet ~= nil and pet ~= 0 and not pet:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == pet:GetGUID();
		end
	end
	return false;
end

function script_follow:isTargetingMe(i) 
	local localPlayer = GetLocalPlayer();
	if (localPlayer ~= nil and localPlayer ~= 0 and not localPlayer:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == localPlayer:GetGUID();
		end
	end
	return false;
end

function script_follow:enemyIsValid(i)
	if (i ~= 0) then
		-- Valid Targets: Tapped by us, or is attacking us or our pet
		if (script_follow:isTargetingMe(i)
			or (self.targetOfptLeader:Get() == i:GetGUID() and i:CanAttack()) -- hack to attack players
			or  script_follow:isTargetMasterPet(i)
			or (script_grind:isTargetingGroup(i) and (i:IsTappedByMe() or not i:IsTapped())) 
			or (script_follow:isTargetingPet(i) and (i:IsTappedByMe() or not i:IsTapped())) 
			or (i:IsTappedByMe() and not i:IsDead())) then 
				return true; 
		end
		-- Valid Targets: Within pull range, levelrange, not tapped, not skipped etc
		if (not i:IsDead() and i:CanAttack() and not i:IsCritter()
			and ((i:GetLevel() <= self.maxLevel and i:GetLevel() >= self.minLevel))
			and i:GetDistance() < self.pullDistance and (not i:IsTapped() or i:IsTappedByMe())
			and not (self.skipHumanoid and i:GetCreatureType() == 'Humanoid')
			and not (self.skipDemon and i:GetCreatureType() == 'Demon')
			and not (self.skipBeast and i:GetCreatureType() == 'Beast')
			and not (self.skipElemental and i:GetCreatureType() == 'Elemental')
			and not (self.skipUndead and i:GetCreatureType() == 'Undead') 
			and not (self.skipElites and (i:GetClassification() == 1 or i:GetClassification() == 2))
			) then
			return true;
		end
	end
	return false;
end

function script_follow:enemiesAttackingUs() -- returns number of enemies attacking us
	local unitsAttackingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    		if typeObj == 3 then
			if (currentObj:CanAttack() and not currentObj:IsDead()) then
                		if (script_follow:isTargetingMe(currentObj)) then 
                			unitsAttackingUs = unitsAttackingUs + 1; 
                		end 
            		end 
       		end
      	currentObj, typeObj = GetNextObject(currentObj); 
	end
   	return unitsAttackingUs;
end

function script_follow:enemiesAttackingParty() -- returns number of enemies attacking party
	
	local unitsAttackingPt = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	
	while currentObj ~= 0 do 
		for i = 1, GetNumPartyMembers()+1 do
				if typeObj == 3 then
					if (currentObj:CanAttack() and not currentObj:IsDead()) then
						if (currentObj:GetUnitsTarget() ~= nil and currentObj:GetUnitsTarget() ~= 0) then 
							if (currentObj:GetUnitsTarget():GetGUID() == i:GetGUID()) then
								unitsAttackingPt = unitsAttackingPt + 1;
							end
						end 
					end 
				end
			currentObj, typeObj = GetNextObject(currentObj); 
		end
	end
	return unitsAttackingPt;
end

function script_follow:playersTargetingUs() -- returns number of players attacking us
	local nrPlayersTargetingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
	if typeObj == 4 then
		if (script_follow:isTargetingMe(currentObj)) then 
                	nrPlayersTargetingUs = nrPlayersTargetingUs + 1; 
                end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nrPlayersTargetingUs;
end

function script_follow:playersWithinRange(range)
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

function script_follow:getDistanceDif()
	local x, y, z = GetLocalPlayer():GetPosition();
	local xV, yV, zV = self.myX-x, self.myY-y, self.myZ-z;
	return math.sqrt(xV^2 + yV^2 + zV^2);
end

function script_follow:draw()
	script_followEX:drawStatus();
	-- if (IsMoving()) then script_nav:drawPath() end
	-- if (self.drawPath) then script_nav:drawPath() end
end