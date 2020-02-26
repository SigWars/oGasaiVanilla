script_follow = {
	useMount = false,
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
	enableGather = false,
	gatherForQuest = false,
	gatherQuestDistance = 25,
	QuestObjectName1 = 'Resonite Crystal',
	QuestObjectName2 = 'Stolen Supply Sack',
	QuestObjectName3 = 'Number',
	useQuestItem = false,
	questItemName = "Foreman's Blackjack",
	objectiveName = 'Lazy Peon,None',
	drawGather = false,
	nextToNodeDist = 4, -- (Set to about half your nav smoothness)
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
	enemyAtkParty = nil,
	PetName = 'Kuppep',
	IgnoreAttacks = false,
	autoTalent = false,
	autoFollow = true,
	registerStart = false,
	registerStop = false,
	registerParty = false,
	breathTime = GetTimeEX(),
	notBreathTime = GetTimeEX(),
	ptLeaderExist = false,
	targetPtLeaderExist = false,
	enemyAtkPartyExist = false,
	autoRepop = true,
	tankMode = false
}

function script_follow:window()
	if (self.isChecked) then EndWindow();
		if(NewWindow("Follower", 320, 300)) then script_followEX:menu(); end
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
				sig_scripts.message = "Ressurrecting Master...";
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
	local manaValor = GetLocalPlayer():GetMana();
	local localHath = GetLocalPlayer():GetHealthPercentage();
	
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
			if (partyMember ~= nil and partyMember ~= 0 and sig_scripts:CalculateDistance(self.ptLeader,partyMember) < 50) then
				
				-- Revive
				if (not IsInCombat() and partyMember:IsDead()) then
					if (not partyMember:IsSpellInRange('Resurrection')) then
						if (script_follow:moveInLineOfSight(partyMember)) then 
							return true; 
						end
					end
					if (Cast('Resurrection', partyMember)) then
						sig_scripts.message = "Ressurrecting Master...";
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
			if (partyMember ~= nil and partyMember ~= 0 and partyMember:GetDistance() < 50 and not partyMember:IsDead()) then
				
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
					if (partyMember ~= nil and partyMember ~= 0 and not IsInCombat() and localMana > 40 and partyMember:GetDistance() < 50 and not partyMember:IsDead()) then -- buff
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
			if (partyMember ~= nil and partyMember ~= 0 and partyMember:GetDistance() < 50 and not partyMember:IsDead()) then
				
				if (partyMembersHP > 0 and partyMembersHP < 99 and localMana > 5) then -- and partyMember:GetGUID() == self.ptLeader:GetGUID()
								
								-- Lesser Heal
								if (manaValor >= 99 and partyMembersHP < 40 and HasSpell("Lesser Healing Wave")) then
									-- Move in line of sight and in range of the party member
									if (IsCasting()) then
										SpellStopCasting();
									end	
									if (script_follow:moveInLineOfSight(partyMember)) then 
										return true; 
									end
									if (Cast('Lesser Healing Wave', partyMember)) then
										self.waitTimer = GetTimeEX() + 2500;
										return true;
									end
								end
								
								-- Heal
								if (manaValor >= 147 and partyMembersHP < 85 and HasSpell("Healing Wave")) then
									-- Move in line of sight and in range of the party member
									if (script_follow:moveInLineOfSight(partyMember)) then 
										return true; 
									end
									if (Cast('Healing Wave', partyMember)) then
										self.waitTimer = GetTimeEX() + 3000;
										return true;
									end
								--[[
								elseif (localMana >= 76 and partyMembersHP < 70 and HasSpell("Healing Wave")) then
									-- Move in line of sight and in range of the party member
									if (script_follow:moveInLineOfSight(partyMember)) then 
										return true; 
									end
									TargetByName(partyMember:GetUnitName());
									CastSpellByName("Healing Wave(Rank 3)");
									sig_scripts.message = "Casting Healing Wave(Rank 3) on " .. partyMember:GetUnitName();
									self.waitTimer = GetTimeEX() + 2500;
									return true;
								
								elseif (localMana >= 42 and partyMembersHP < 80 and HasSpell("Healing Wave")) then
									-- Move in line of sight and in range of the party member
									if (script_follow:moveInLineOfSight(partyMember)) then 
										return true; 
									end
									TargetByName(partyMember:GetUnitName());
									CastSpellByName("Healing Wave(Rank 2)");
									sig_scripts.message = "Casting Healing Wave(Rank 2) on " .. partyMember:GetUnitName();
									self.waitTimer = GetTimeEX() + 1500;
									return true;
									]]--
								end
					--[[
					-- Heal Self
					if (localHath < 80 and HasSpell("Healing Wave") and  partyMember:GetGUID() == GetLocalPlayer():GetGUID()) then
						if (not partyMember:IsSpellInRange('Healing Wave')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								self.waitTimer = GetTimeEX() + 1500;
								return true; 
							end
						end
						if (Cast('Healing Wave', partyMember)) then
							sig_scripts.message = "Casting Healing Wave on " .. partyMember:GetUnitName();
							self.waitTimer = GetTimeEX() + 2500;
							return true;
						end
					end
					
					
					-- Heal Wave max level
					if (localMana > 5 and partyMembersHP < 60 and HasSpell("Healing Wave") and not partyMember:IsDead() and partyMember:GetGUID() == self.ptLeader:GetGUID()) then
						if (not partyMember:IsSpellInRange('Healing Wave')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								self.waitTimer = GetTimeEX() + 1500;
								return true; 
							end
						end
						if (Cast('Healing Wave', partyMember)) then
							sig_scripts.message = "Casting Healing Wave on " .. partyMember:GetUnitName();
							self.waitTimer = GetTimeEX() + 2500;
							return true;
						end
					end
					
					-- Try Heal with Lesser healing wave max  else Use Ranked Healing Wave
					if (localMana > 5 and partyMembersHP < 85 and HasSpell("Lesser Healing Wave") and not partyMember:IsDead() and partyMember:GetGUID() == self.ptLeader:GetGUID()) then
						if (not partyMember:IsSpellInRange('Lesser Healing Wave')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								self.waitTimer = GetTimeEX() + 1500;
								return true; 
							end
						end
						if (Cast('Lesser Healing Wave', partyMember)) then
							sig_scripts.message = "Casting Lesser Healing Wave on " .. partyMember:GetUnitName();
							self.waitTimer = GetTimeEX() + 2500;
							return true;
						end
					else 
						if (localMana > 5 and partyMembersHP < 85 and HasSpell("Healing Wave") and not partyMember:IsDead() and partyMember:GetGUID() == self.ptLeader:GetGUID()) then
							if (not partyMember:IsSpellInRange('Healing Wave')) then
								if (script_follow:moveInLineOfSight(partyMember)) then 
									self.waitTimer = GetTimeEX() + 1500;
									return true; 
								end
							else 
								TargetByName(partyMember:GetUnitName());
								CastSpellByName("Healing Wave(Rank 2)");
								sig_scripts.message = "Casting Healing Wave(Rank 2) on " .. partyMember:GetUnitName();
								self.waitTimer = GetTimeEX() + 2500;
								return true;
							end
						end
					end
					
					-- Out of combat
					if (localMana > 5 and partyMembersHP < 85 and HasSpell("Lesser Healing Wave") and not IsInCombat()) then
						if (not partyMember:IsSpellInRange('Lesser Healing Wave')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								self.waitTimer = GetTimeEX() + 1500;
								return true; 
							end
						end
						if (Cast('Lesser Healing Wave', partyMember)) then
							sig_scripts.message = "Casting Lesser Healing Wave) on " .. partyMember:GetUnitName();
							self.waitTimer = GetTimeEX() + 2500;
							return true;
						end
					else 
						if (localMana > 5 and partyMembersHP < 85 and HasSpell("Healing Wave") and not IsInCombat()) then
							if (not partyMember:IsSpellInRange('Healing Wave')) then
								if (script_follow:moveInLineOfSight(partyMember)) then 
									self.waitTimer = GetTimeEX() + 1500;
									return true; 
								end
							else 
								TargetByName(partyMember:GetUnitName());
								CastSpellByName("Healing Wave(Rank 2)");
								self.waitTimer = GetTimeEX() + 2500
								sig_scripts.message = "Casting Healing Wave(Rank 2) on " .. partyMember:GetUnitName();
								return true;
							end
						end
					end
					
					if (localMana > 5 and partyMembersHP < 60 and HasSpell("Healing Wave") and not IsInCombat()) then
						if (not partyMember:IsSpellInRange('Healing Wave')) then
							if (script_follow:moveInLineOfSight(partyMember)) then 
								self.waitTimer = GetTimeEX() + 1500;
								return true; 
							end
						end
						if (Cast('Healing Wave', partyMember)) then
							sig_scripts.message = "Casting Healing Wave) on " .. partyMember:GetUnitName();
							self.waitTimer = GetTimeEX() + 2500;
							return true;
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
	self.lootCheck['timer'] = GetTimeEX();
	self.lootCheck['target'] = 0;
	script_helper:setup();
	script_talent:setup();
	script_gather:setup();
	
	---------------------------------------
	--   REGISTER FRAME TO CHECK BREATH  --
	---------------------------------------
	if (not self.registerParty) then
		local chatframe = CreateFrame("Frame");
		self.registerParty = chatframe:RegisterEvent("CHAT_MSG_PARTY");
		chatframe:SetScript("OnEvent", function(self, event, msg) 
			if msg == "teste" then
				DEFAULT_CHAT_FRAME:AddMessage("alguem disse teste...");
			end	
		end);
	end
	
	if (not self.registerStart) then
		local frame = CreateFrame("Frame");
		self.registerStart = frame:RegisterEvent("MIRROR_TIMER_START");
		frame:SetScript("OnEvent", function(timer, value, maxvalue, scale, paused, label)
			afogando = true;
		end);
	end
	
		
	if (not self.registerStop) then
		local frame = CreateFrame("Frame");
		self.registerStop = frame:RegisterEvent("MIRROR_TIMER_STOP");
		frame:SetScript("OnEvent", function(timer, value, maxvalue, scale, paused, label)
			afogando = false;	
		end);
	end
	
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
	return nil;
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
	return nil;
end

function script_follow:runBackwards(targetObj, range) 
	local localObj = GetLocalPlayer();
 	if targetObj ~= 0 then
 		local xT, yT, zT = targetObj:GetPosition();
 		local xP, yP, zP = localObj:GetPosition();
 		local distance = targetObj:GetDistance();
 		local xV, yV, zV = xP - xT, yP - yT, zP - zT;	
 		local vectorLength = math.sqrt(xV^2 + yV^2 + zV^2);
 		local xUV, yUV, zUV = (1/vectorLength)*xV, (1/vectorLength)*yV, (1/vectorLength)*zV;		
 		local moveX, moveY, moveZ = xT + xUV*20, yT + yUV*20, zT + zUV;		
 		if (distance < range and targetObj:IsInLineOfSight()) then 
 			script_nav:moveToTarget(localObj, moveX, moveY, moveZ);
 			return true;
 		end
	end
	return false;
end

function script_follow:run()

	script_follow:window();
	
	----------------------------------------------------------
	--  	 			BREATH VARIABLE						--
	----------------------------------------------------------
	if (not afogando) then
		self.notBreathTime = GetTimeEX();
	end
	
	----------------------------------------------------------
	--  	 			PAUSE IF IS FLYING					--
	----------------------------------------------------------
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
	
	----------------------------------------------------------
	--  	  DISBLE NAVIGATION IF AUTOFOLLOW IS OFF		--
	----------------------------------------------------------
	if (not self.autoFollow and not GetLocalPlayer():IsDead()) then
		UseNavmesh(false);
	else
		if (not IsUsingNavmesh()) then UseNavmesh(true); return; end
		if (not LoadNavmesh()) then self.message = "Make sure you have mmaps-files..."; return; end	
		
		-- auto unstuck feature
		if (not self.IgnoreAttacks and not script_unstuck:pathClearAuto(2)) then
			self.message = script_unstuck.message;
			return;
		end
	end
	
	if (not self.navFunctionsLoaded) then self.message = "Error script_nav not loaded..."; return; end
	if (not self.helperLoaded) then self.message = "Error script_helper not loaded..."; return; end

	if (self.pause) then self.message = "Paused by user..."; return; end
	
	if (self.pauseFly) then self.message = "Paused when flying..."; return; end
	
	----------------------------------------------------------
	--  					TALENT POINTS					--
	----------------------------------------------------------
	if (not IsInCombat() and not GetLocalPlayer():IsDead() and self.autoTalent) then
		if (script_talent:learnTalents()) then
			self.message = "Checking/learning talent: " .. script_talent:getNextTalentName();
			return;
		end
	end
	
	if(GetTimeEX() > self.timer) then
		self.timer = GetTimeEX() + self.tickRate;
		
		----------------------------------------------------------
		--  					VARIABLES						--
		----------------------------------------------------------
		localObj = GetLocalPlayer(); -- object 
		self.ptLeader = script_follow:GetPartyLeaderObject(); -- object 
		self.targetOfptLeader = self.ptLeader:GetUnitsTarget(); -- object 
		self.PetObject = script_follow:GetMasterPet(); -- object 
		self.enemyAtkParty = sig_scripts:isAttakingGroup(); -- object 

		-- SET VARAIBLES TO NIL IF EQUAL ZERO --
		if (self.ptLeader == 0) then self.ptLeader = nil;	end
		if (self.targetOfptLeader == 0) then self.targetOfptLeader = nil;	end
		if (self.PetObject == 0) then self.PetObject = nil;	end
		----------------------------------------------------------
		self.ptLeaderExist = (self.ptLeader ~= nil and self.ptLeader ~= 0); -- true/false
		self.targetPtLeaderExist = (self.targetOfptLeader ~= nil and self.targetOfptLeader ~= 0); -- true/false
		self.enemyAtkPartyExist = (self.enemyAtkParty ~= nil and self.enemyAtkParty ~= 0); -- true/false
		----------------------------------------------------------
		
		-- Wait out the wait-timer and/or casting or channeling
		if (self.waitTimer > GetTimeEX() or IsCasting() or IsChanneling()) then return; end

		-- Automatic loading of the nav mesh
		if (GetLoadNavmeshProgress() ~= 1) then self.message = "Loading the nav mesh... " .. math.floor(GetLoadNavmeshProgress()*100); return; end

		----------------------------------------------------------
		--				MOVE TO CORPSE DEAD/GHOST				--
		----------------------------------------------------------
		if(localObj:IsDead() and self.autoRepop) then
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
		
		----------------------------------------------------------
		--  		RESET STATUS OF GATHER/QUEST				--
		----------------------------------------------------------
		if (IsInCombat()) then
			script_gather.timeGather = GetTimeEX() + 1000;
			script_gather.isGathering = false;
			sig_scripts.usingQuestItem = false;
		end
		
		----------------------------------------------------------
		--  					ROGUE							--
		----------------------------------------------------------
		-- Check: Rogue only, If we just Vanished, move away from enemies within 30 yards
		if (localObj:HasBuff("Vanish")) then if (script_nav:runBackwards(1, 30)) then 
			ClearTarget(); self.message = "Moving away from enemies..."; return; end 
		end
		
		----------------------------------------------------------
		--  						REST						--
		----------------------------------------------------------
		if (not IsInCombat() and script_grind:enemiesAttackingUs() == 0 and not localObj:HasBuff('Feign Death') and not self.targetPtLeaderExist and not self.enemyAtkPartyExist and script_follow:enemiesAttackingParty() == 0) then
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
		
		----------------------------------------------------------
		-- 					CHACK IF BAG IS FULL				--
		----------------------------------------------------------
		if (AreBagsFull() and not IsInCombat()) then
			self.message = 'Warning bags are full...';
		end
		
		----------------------------------------------------------
		--  			CLEAR DEAD/TAPPED TARGETS				--
		----------------------------------------------------------
		if (self.enemyObj ~= 0 and self.enemyObj ~= nil) then
			if ((self.enemyObj:IsTapped() and not self.enemyObj:IsTappedByMe()) 
				or self.enemyObj:IsDead()) then
				self.enemyObj = nil;
				ClearTarget();
			end
		end

		----------------------------------------------------------
		--  				CLEAR TARGET IF	NOT	  				--
		-- Combat/Agrroed/Looting and target of master is clear --
		---------------------------------------------------------- 
		-- if (not IsInCombat() and script_grind:enemiesAttackingUs() == 0 and not self.targetPtLeaderExist and self.lootObj == nil and (self.enemyObj == 0 or self.enemyObj == nil)) then
		-- 	ClearTarget();
		-- end
		
		
		-- Accept group invite
		if (GetNumPartyMembers() < 1 and self.acceptTimer < GetTimeEX()) then 
			self.acceptTimer = GetTimeEX() + 5000;
			AcceptGroup(); 
		end
		
		
		----------------------------------------------------------
		-- 					HEALS AND BUFFS				--
		----------------------------------------------------------
		-- Healer check: heal/buff the party
		if (script_follow:healAndBuff()) then
			self.message = "Healing / Buff / Support Party ";
			return;
		end
		--[[
		if (script_follow:healAndBuff() and HasSpell('Smite')) then
			self.message = "Healing/buffing the party ";
			return;
		end
		-- Priest heal Master Pet
		if (self.PetObject ~= 0 and script_follow:HelpPets() and HasSpell('Smite')) then
			self.message = "Healing/buffing pet " .. self.PetObject:GetUnitName() .. "...";
			return;
		end
		]]--
		
		----------------------------------------------------------
		--  					     LOOT						--
		----------------------------------------------------------
		if (not IsInCombat() and script_grind:enemiesAttackingUs() == 0 and not localObj:HasBuff('Feign Death')) then
			
			local canloot = true;
			if (self.targetPtLeaderExist) then
				if (not self.targetOfptLeader:IsDead() and self.targetOfptLeader:CanAttack()) then
					canloot = false;
				end
			end
			
			-- Loot if there is anything lootable and we are not in combat and if our bags aren't full
			if (not self.skipLooting and not AreBagsFull() and canloot) then 
				self.lootObj = script_nav:getLootTarget(self.findLootDistance);
			else
				self.lootObj = nil;
				sig_scripts.lootmessage = "Nothing to loot..";
			end
			if (self.lootObj == 0) then self.lootObj = nil; end
			-- local isLoot = not IsInCombat() and not (self.lootObj == nil);
			local isLoot = not IsInCombat() and not (self.lootObj == nil) and sig_scripts:isAreaNearTargetSafe(self.lootObj) and not script_grind:isTargetBlacklisted(self.lootObj:GetGUID()) and (script_follow:enemiesAttackingParty() == 0 and canloot);
			if (isLoot and not AreBagsFull()) then
				script_grindEX:doLoot(localObj);
				return;
			elseif (AreBagsFull() and not hsWhenFull) then
				self.lootObj = nil;
				if (IsLooting()) then CloseLoot(); end
				sig_scripts.lootmessage = "Warning the bags are full...";
			elseif (not (self.lootObj == nil) and not sig_scripts:isAreaNearTargetSafe(self.lootObj)) then
				sig_scripts.lootmessage = "Corpose is in unsafe area...";
				self.lootObj = nil;
			elseif (not (self.lootObj == nil) and script_grind:isTargetBlacklisted(self.lootObj:GetGUID())) then
				sig_scripts.lootmessage = "Corpose GUID:" .. self.lootObj:GetGUID() .. " is Blacklisted:";
				self.lootObj = nil;
				if (IsLooting()) then CloseLoot(); end
			elseif (not (self.lootObj == nil) and script_follow:enemiesAttackingParty() > 0) then
				sig_scripts.lootmessage = "Party member in combat..";
				self.lootObj = nil;
				if (IsLooting()) then CloseLoot(); end				
			end
		end
		--[[if ((self.enemyObj == 0 or self.enemyObj == nil or (self.targetPtLeaderExist and self.targetOfptLeader:IsDead()))
			and not IsInCombat() 
			and script_grind:enemiesAttackingUs() == 0 
			and script_follow:enemiesAttackingParty() == 0
			and not localObj:HasBuff('Feign Death')) then
			-- Loot if there is anything lootable and we are not in combat and if our bags aren't full
			
			if (not self.skipLooting and not AreBagsFull()) then 
				self.lootObj = script_nav:getLootTarget(self.findLootDistance);
			else
				self.lootObj = nil;
			end
			if (self.lootObj == 0) then self.lootObj = nil; end
			local isLoot = (not self.lootObj == nil) and not IsInCombat() and sig_scripts:isAreaNearTargetSafe(self.lootObj) and not script_grind:isTargetBlacklisted(self.lootObj:GetGUID()) and (script_follow:enemiesAttackingParty() == 0);
			if (isLoot and not AreBagsFull()) then
				script_grindEX:doLoot(localObj);
				return;
			elseif (AreBagsFull() and not hsWhenFull) then
				self.lootObj = nil;
				self.message = "Warning the bags are full...";
			elseif (not (self.lootObj == nil) and not sig_scripts:isAreaNearTargetSafe(self.lootObj)) then
				self.message = "Corpose is in unsafe area...";
				self.lootObj = nil;
			elseif (not (self.lootObj == nil) and script_grind:isTargetBlacklisted(self.lootObj:GetGUID())) then
				self.message = "Corpose GUID:" .. self.lootObj:GetGUID() .. " is Blacklisted:";
				self.lootObj = nil;	
			end
		end]]--
		
		
		----------------------------------------------------------
		-- 				FOLLOW RANGE VARIATION					--
		----------------------------------------------------------
		-- Randomize the follow range
		if (self.followTimer < GetTimeEX()) then 
			self.followTimer = GetTimeEX() + 5000;
			self.followDistance = math.random(self.minFollowDist,self.maxFollowDist); -- 15,25
		end
		
	
		----------------------------------------------------------
		--  					BREATH TODO:					--
		----------------------------------------------------------
		self.breathTime = ((GetTimeEX()-self.notBreathTime)/1000);
		if (self.breathTime > 50.000 and self.autoFollow) then
			local xb, yb, zb = self.ptLeader:GetPosition();
			-- Move(xb, yb, zb+10);
			script_nav:resetNavigate();
			self.waitTimer = GetTimeEX() + 5000;
			script_nav:moveToTarget(GetLocalPlayer(), xb, yb, zb);
			-- RunMacro("FOLLOW");
			return;
		end
		
		----------------------------------------------------------
		--  				FOLLOW IGNORE COMBAT				--
		----------------------------------------------------------
		-- Follow ignoing combat self.IgnoreAttacks 
		if (self.ptLeaderExist and self.targetPtLeaderExist) then
			if(self.targetOfptLeader:GetGUID() == self.ptLeader:GetGUID()) then
				
				-- Disable Combat Script and Target Script
				self.enemyObj = nil
				ClearTarget();
				self.IgnoreAttacks = true;
				sig_scripts.movementmessage = "Following " .. self.ptLeader:GetUnitName() .. " ignoring combat...";
				
				-- Follow
				if (self.ptLeader:GetDistance() > 3 and self.autoFollow) then
					local x, y, z = self.ptLeader:GetPosition();
					-- script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
					Move(x, y, z);
				end
				
				-- Return
				return;
			else
				self.IgnoreAttacks = false;
			end
		else	
			self.IgnoreAttacks = false;
		end 
		
		----------------------------------------------------------
		--  				GATHER OR USE ITEM					--
		----------------------------------------------------------
		-- Use item for quests in target of the party leader
		if (self.useQuestItem) then
			--[[if (self.targetPtLeaderExist) then
				
				local reatchHP = false;
				local useOnEnemy = false;
				self.useOnTargetHp = 0;
				self.useOnEnemy = true;
				
				-- Set HP ok if valor = 0
				if (self.useOnTargetHp == 0) then
					reatchHP = true;
				end
				
				-- Set HP ok if Valor ~= 0 and < self.useOnTargetHp
				if (targetOfptLeader:GetHealthPercentage() <= self.useOnTargetHp) then
				end
					
				-- Target Enemy or Friendly
				if (self.useOnEnemy) then
					-- Enemy Target
					if (targetOfptLeader:CanAttack()) then
						useOnEnemy = true;
					end
				end
				
				-- use item
				sig_scripts:usequestItem(30);
				
			end]]--
			-- sig_scripts:usequestItem(50); 
			sig_scripts:useItemLeaderTarget();
			-- return;
			--[[if (self.ptLeaderExist) then
				if (self.targetPtLeaderExist) then
					if (sig_scripts:useItemOnTarget()) then
						return;
					end
				end
			end]]--
			
		end
		
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
				-- return;
			else
				script_gather.isGatheringQuest = false;
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
		
		----------------------------------------------------------
		--  					TARGET							--
		----------------------------------------------------------
		if (script_grind:enemiesAttackingUs() >= 1 and not self.IgnoreAttacks) then
			if (HasSpell('Fade') and not IsSpellOnCD('Fade')) then
				CastSpellByName('Fade');
				return;
			end
			if (HasSpell('Stoneclaw Totem') and not IsSpellOnCD('Stoneclaw Totem')) then
				CastSpellByName('Stoneclaw Totem');
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
			if (script_follow:GetPartyLeaderObject() ~= 0 and not self.IgnoreAttacks) then
				if (self.targetPtLeaderExist and not self.targetOfptLeader:IsDead() and self.targetOfptLeader:CanAttack()) then
					if (self.targetOfptLeader:GetHealthPercentage() <= self.dpsHp) then
						self.enemyObj = self.targetOfptLeader;
					else
						self.enemyObj = nil;
					end
				end
			end
		end
		
		-- Return target is attacking group/pet if not in combat
		if (not self.IgnoreAttacks and not IsInCombat()) then
			local foundTarget = sig_scripts:searchingTarget(50);
			if (foundTarget ~= nil and foundTarget ~= 0) then
				-- sig_scripts.message = tostring(foundTarget:GetUnitName());
				if (foundTarget:GetHealthPercentage() <= self.dpsHp) then
					self.enemyObj = foundTarget;
				else
					self.enemyObj = nil;
				end
			else
				self.enemyObj = nil;
			end
		end
		
		-- Check: If we are in combat but no valid target, kill the "unvalid" target attacking us
		if (self.enemyObj == nil and IsInCombat()) then
			if (GetTarget() ~= 0) then
				self.enemyObj = GetTarget();
			end
		end
		
		--[[
		if (self.ptLeaderExist and not self.ptLeader:IsDead() and not self.IgnoreAttacks) then
			
			-- Check if anything is attacking us
			if (script_grind:enemiesAttackingUs() >= 1) then
				if (HasSpell('Fade') and not IsSpellOnCD('Fade')) then
					CastSpellByName('Fade');
					return;
				end
				
				if (HasSpell('Stoneclaw Totem') and not IsSpellOnCD('Stoneclaw Totem')) then
					CastSpellByName('Stoneclaw Totem');
					return;
				end
				
				-- Get Target attack you
				if (GetTarget() ~= 0 and GetTarget() ~= nil) then
					local target = GetTarget();
					if (target:CanAttack()) then
						self.enemyObj = target;
					else
						self.enemyObj = nil;
					end
				end
			end	
			
			-- Target enemyes attacking party if master not have target not in combar and target not is dead
			if (not IsInCombat() and self.enemyAtkParty ~= nil and self.enemyAtkParty ~= 0) then
				if (not self.enemyAtkParty:IsDead() and self.enemyAtkParty:GetHealthPercentage() <= self.dpsHp) then
					self.enemyObj = self.enemyAtkParty;
				end
			end
			
			-- Set target of PTleader you target
			if (self.targetPtLeaderExist 
				and not self.targetOfptLeader:IsDead()    
				and self.targetOfptLeader:GetHealthPercentage() <= self.dpsHp 
				and self.targetOfptLeader:CanAttack()) then
				
				-- self.lootWait = GetTimeEX() + 1000;
				self.enemyObj = self.targetOfptLeader;
			end
			
		
		end
		]]--
		

		
		----------------------------------------------------------
		--				DISABLE TARGET FOR HEALERS				--
		----------------------------------------------------------
		 -- Check: If we are a priest and we are at least 3 party members, dont do damage if mana below 90%
		 if (HasSpell('Smite') and GetNumPartyMembers() > 1 and GetLocalPlayer():GetManaPercentage() < 90) then
		 	self.enemyObj = nil;
		 end
		 -- Check: If we are a priest and not do damage if pet life below 70%
		 if (HasSpell('Smite') and self.PetObject ~= nil and self.PetObject ~= 0 and self.PetObject:GetHealthPercentage() < 70) then
		 	self.enemyObj = nil;
		 end
		 -- Check: If we are a priest and not do damage if Leader life below 70%
		 if (HasSpell('Smite') and self.ptLeaderExist and self.ptLeader:GetHealthPercentage() < 70) then
		 	self.enemyObj = nil;
		 end
		 
		 -- Check: If we are a priest and not do damage if Leader life below 70%
		 if (HasSpell('Healing Wave') and self.ptLeaderExist and self.ptLeader:GetHealthPercentage() < 70) then
		 	self.enemyObj = nil;
		 end
		 -- Check: If we are a priest and we are at least 3 party members, dont do damage if mana below 90%
		 if (HasSpell('Healing Wave') and GetNumPartyMembers() > 2 and IsInCombat()) then
		 	self.enemyObj = nil;
		 end
		
		
		
		-- Finish loot before we engage new targets or navigate
		if (GetTimeEX() > self.lootWait and self.lootObj ~= nil and self.enemyObj == nil and not self.targetPtLeaderExist) then 
			return; 
		else
			-- reset the combat status
			self.combatError = nil; 
			-- Run the combat script and retrieve combat script status if we have a valid target
			if (self.enemyObj ~= nil and self.enemyObj ~= 0 and not self.IgnoreAttacks) then
				self.combatError = RunCombatScript(self.enemyObj:GetGUID());
			end
		end

		if((not self.IgnoreAttacks and IsInCombat()) or (self.enemyObj ~= nil and self.enemyObj ~= 0)) then
		
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
		if (script_follow:shaperShift()) then return; end
	

		-- Do not follow or intercat of Gathering/Node or Quest or is using quest item o autofollow option is unchecked
		if (script_gather.isGathering or script_gather.isGatheringQuest or sig_scripts.usingQuestItem or not self.autoFollow) then
			return; 
		end
		
		----------------------------------------------------------
		--  					FOLLOW NORMAL					--
		----------------------------------------------------------
		-- Follow our master
		if (self.ptLeaderExist and not self.Interacting and self.autoFollow) then
			if(self.ptLeader:GetDistance() > self.followDistance and not self.ptLeader:IsDead()) then
				
				if (self.ptLeader:GetDistance() <= 5) then
					if(IsMoving()) then
						StopMoving();
					end
				end
				
				local x, y, z = self.ptLeader:GetPosition();
				sig_scripts.movementmessage = "Following " .. self.ptLeader:GetUnitName() .. "...";
				script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
				return;
			end
		end
		
		----------------------------------------------------------
		--  					INTERACT						--
		----------------------------------------------------------
		if (self.ptLeaderExist and not IsInCombat() and not self.useQuestItem) then
			
			local newTarget = self.ptLeader:GetUnitsTarget();
			
			if (newTarget ~= 0 and newTarget ~= nil and not self.ptLeader:IsDead() and not newTarget:IsDead() and not newTarget:CanAttack()) then	
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
					sig_scripts.message = "Interacting with " .. interactTarget:GetUnitName();
					if (interactTarget:GetDistance() > 4) then
						TargetByName(self.ptLeader:GetUnitsTarget():GetUnitName());
						local x, y, z = interactTarget:GetPosition();
						sig_scripts.movementmessage = "Moving to " .. interactTarget:GetUnitName();
						script_nav:moveToNav(GetLocalPlayer(), x, y, z);
					else
						if(IsMoving()) then
							StopMoving();
						end
						
						if (not IsVendorWindowOpen()) then
							-- SkipGossip();
							if (interactTarget:UnitInteract()) then
								self.npclastTarget = interactTarget:GetUnitName(); 
								-- return;
							end
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

function script_follow:shaperShift()
	local __, lastError = GetLastError();
	if (lastError ~= 75 and self.mountTimer < GetTimeEX()) then
		-- TODO: change in 2.1.11
		-- local _, isSwimming = IsSwimming();
		if(GetLocalPlayer():GetLevel() >= 20 and self.useMount and not IsIndoors() and not IsMounted() and self.lootObj == nil and not GetLocalPlayer():HasBuff("Ghost Wolf") and not self.Interacting) then
			self.message = "Mounting...";
			if (not IsStanding()) then StopMoving(); end
			--if (script_helper:useMount()) then self.waitTimer = GetTimeEX() + 4000; return true; end
			if (HasSpell("Ghost Wolf") and not GetLocalPlayer():HasBuff("Ghost Wolf")) then
				CastSpellByName("Ghost Wolf");
				self.waitTimer = GetTimeEX() + 4000; 
				return true;
			end
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

function script_follow:enemiesAttackingParty() -- returns number of enemies attacking us
	local unitsAttackingPt = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    		if typeObj == 3 then
				for i = 1, GetNumPartyMembers() do
					local ptMember = GetPartyMember(i)
					if (ptMember ~= 0 and ptMember ~= nil) then
						if (currentObj:CanAttack() and not currentObj:IsDead()) then
							if (currentObj:GetUnitsTarget() ~= nil and currentObj:GetUnitsTarget() ~= 0) then 
								if (currentObj:GetUnitsTarget():GetGUID() == ptMember:GetGUID()) then
									unitsAttackingPt = unitsAttackingPt + 1;
								end
							end 
						end
					end	
				end
       		end
      	currentObj, typeObj = GetNextObject(currentObj); 
	end
   	return unitsAttackingPt;
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

function script_follow:draw()
	script_followEX:drawStatus();
	-- if (IsMoving()) then script_nav:drawPath() end
	-- if (self.drawPath) then script_nav:drawPath() end
end