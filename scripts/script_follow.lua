script_follow = {
	squadmode = true,
	jump = false,
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
	sigScriptHelper = include("scripts\\sig\\sig_script_helper.lua"),
	enableGather = false,
	gatherForQuest = true,
	gatherQuestDistance = 40,
	QuestObjectName1 = 'Sack of Meat',
	QuestObjectName2 = 'Rocket Car Rubble',
	QuestObjectName3 = 'Number',
	useQuestItem = false,
	questItemName = "Kodo Kombobulator",
	objectiveName = 'Aged Kodo,Ancient Kodo',
	drawGather = false,
	nextToNodeDist = 4, -- (Set to about half your nav smoothness)
	isSetup = false,
	drawUnits = false,
	acceptTimer = GetTimeEX(),
	followDistance = 10,
	followTimer = GetTimeEX(),
	dpsHp = sig_scripts:classVars("dpsHp"),
	isChecked = true,
	isCheckedSig = true,
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
	objAttackingHealer = nil,
	PetName = 'Hukgorg', --Kuppep,Hukgorg
	HealerName = 'Twoslaps',
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
	isAttackingHealer = false,
	autoRepop = false,
	randPlus = 0; -- Raandom psotion to follow
	randMinus = 0; -- Random positiont o follow
	randSquadPosTime = GetTimeEX(),
	drawDebug = false,
	tankMode = false,
	nearElevID = false,
	nearElevator = false, 
}

function script_follow:window()
	if (self.isChecked) then EndWindow();
		if(NewWindow("Follower", 320, 300)) then script_followEX:menu(); end
	end
end

function script_follow:sigwindow()
	if (self.isCheckedSig) then EndWindow();
		if(NewWindow("Sig", 100, 100)) then script_followEX:sigmenu(); end
	end
end


function script_follow:moveInLineOfSight(target)
	if (not target:IsInLineOfSight() or target:GetDistance() > 30) then
		local x, y, z = target:GetPosition();
		script_follow:moveToTarget(GetLocalPlayer(), x , y, z);
		return true;
	end

	return false;
end

function script_follow:moveInMeleeSight(target)
	if (not target:IsInLineOfSight() or target:GetDistance() > 2.5) then
		local x, y, z = target:GetPosition();
		script_follow:moveToTarget(GetLocalPlayer(), x , y, z);
		return true;
	end

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
 			script_follow:moveToTarget(localObj, moveX, moveY, moveZ);
 			return true;
 		end
	end
	return false;
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
	local pet = script_follow:GetMasterPet();
	if (pet ~= nil and pet ~= 0 and not pet:IsDead() and i ~= nil) then
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

function script_follow:moveToTarget(objeto,x,y,z)
	if (IsSwimming())then
		Move(x, y, z);
	else
		script_nav:moveToTarget(obj, x, y, z);
	end
end

function script_follow:IsNearElevator()
	local objList = { "eleva", "brid"};
	local targetObj, targetType = GetFirstObject();
	while targetObj ~= 0 do
		if (targetType == 5) then -- GameObject
			if (targetObj:GetDistance() < 50) then
				for _,objeto in pairs(objList) do
					-- sig_scripts.message = targetObj:GetUnitName();
					if(string.find(string.lower(targetObj:GetUnitName()),objeto)) then
						sig_scripts.message = targetObj:GetUnitName() .. " With string " .. objeto .. " At: " .. math.floor(targetObj:GetDistance()) .. " Yrds: ";
						return true;
					end
				end
			end	
		end
		targetObj, targetType = GetNextObject(targetObj);
	end
	--sig_scripts.message = "Nothing";
	return false;
end

function script_follow:IsNearElevbyID()
	local objList = { "7051", "brid"};
	local targetObj, targetType = GetFirstObject();
	while targetObj ~= 0 do
		 if (targetType == 5) then -- GameObject
			local x, y, z = targetObj:GetObjectPosition();
			if (targetObj:GetDistance() < 100) then
				sig_scripts.message = targetObj:GetObjectDisplayID() .. " At: " ..math.floor(x).. " " ..math.floor(y).. " "..math.floor(z).. " "..targetObj:GetUnitName().. " State:"..targetObj:GetObjectState();
				if (targetObj:GetObjectDisplayID() == 7051) then
					-- sig_scripts.message = targetObj:GetObjectDisplayID() .. " At: " .. targetObj:GetObjectPosition();
					return true;
				end
				--[[
				for _,objeto in pairs(objList) do
					-- sig_scripts.message = targetObj:GetUnitName();
					if(string.find(string.lower(targetObj:GetUnitName()),objeto)) then
						sig_scripts.message = targetObj:GetUnitName() .. " With string " .. objeto .. " At: " .. math.floor(targetObj:GetDistance()) .. " Yrds: ";
						return true;
					end
				end
				]]--
			end	
		end
		targetObj, targetType = GetNextObject(targetObj);
	end
	--sig_scripts.message = "Nothing";
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
	
	self.nearElevator = script_follow:IsNearElevator();
	self.nearElevID = script_follow:IsNearElevbyID();
	----------------------------------------------------------
	--  	 			PAUSE IF IS FLYING					--
	----------------------------------------------------------
	local voando = UnitOnTaxi("player"); -- self.message = "Voando  =" .. tostring(voando);
	if (voando ~= nil and not self.nearElevator) then
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
	-- Diable Features while indoors 
	local canJump = true;
	local canSquadmode = true;
	
	-- Disable jump and squadmode while indoor
	if (self.IgnoreAttacks) then canJump = false; end
	if (IsIndoors() and self.squadmode) then 
		canSquadmode = false; 
		canJump = false;
	end
	
	-- Disable Navmesh if autofollow is off
	if (not self.autoFollow and not GetLocalPlayer():IsDead()) then
		if (IsUsingNavmesh()) then UseNavmesh(false); end
	else
		-- Enable navmesh if off
		if (not IsUsingNavmesh()) then UseNavmesh(true); return; end
		if (not LoadNavmesh()) then self.message = "Make sure you have mmaps-files..."; return; end	
		
		-- Disable unstuck if Sqimming or Follow/Ignoring Attacks -> Feature to use ingame to move direct from you ignoring Elevations
		if (not self.IgnoreAttacks and not IsSwimming() and not script_unstuck:pathClearAuto(2)) then
			self.message = script_unstuck.message;
			JumpOrAscendStart();
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
		self.objAttackingHealer = sig_scripts:isAttakingHealer(); -- object

		-- SET VARAIBLES TO NIL IF EQUAL ZERO --
		if (self.ptLeader == 0) then self.ptLeader = nil;	end
		if (self.targetOfptLeader == 0) then self.targetOfptLeader = nil;	end
		if (self.PetObject == 0) then self.PetObject = nil;	end
		----------------------------------------------------------
		self.ptLeaderExist = (self.ptLeader ~= nil and self.ptLeader ~= 0); -- true/false
		self.targetPtLeaderExist = (self.targetOfptLeader ~= nil and self.targetOfptLeader ~= 0); -- true/false
		self.enemyAtkPartyExist = (self.enemyAtkParty ~= nil and self.enemyAtkParty ~= 0); -- true/false
		self.isAttackingHealer = (self.objAttackingHealer ~= nil and self.objAttackingHealer ~= 0); -- true/false
		----------------------------------------------------------
		
		-- Wait out the wait-timer and/or casting or channeling
		if (self.waitTimer > GetTimeEX() or IsCasting() or IsChanneling()) then return; end

		-- Automatic loading of the nav mesh
		if (GetLoadNavmeshProgress() ~= 1) then self.message = "Loading the nav mesh... " .. math.floor(GetLoadNavmeshProgress()*100); return; end

		----------------------------------------------------------
		--				    	NEAR ELEVATOR					--
		----------------------------------------------------------
		if (self.nearElevator) then
			self.message = "Near elevator stoping follow and set game follow";
			if (IsChanneling() or IsCasting()) then
				SpellStopCasting();
			end
			if (self.ptLeader:GetDistance() > 4) then
				if (self.ptLeaderExist) then 
					RunMacro("FOLLOW")
					self.timer = GetTimeEX() + self.tickRate + 3000;
				end
			end	
			return;
		end
		
		----------------------------------------------------------
		--				    	RANDOM JUMPS					--
		----------------------------------------------------------
		-- Jump
		if (self.jump and not IsIndoors() and canJump) then
			local jr = random(1, 100);
			if (jr > 98 and IsMoving() and not IsInCombat() and not IsSwimming()) then
				JumpOrAscendStart();
			end
		end
		
		----------------------------------------------------------
		--				MOVE TO CORPSE DEAD/GHOST				--
		----------------------------------------------------------
		if(localObj:IsDead()) then
			self.message = "Dead...";
			-- Release body
			if (self.autoRepop) then
				if(not IsGhost()) then 
					RepopMe(); 
					self.waitTimer = GetTimeEX() + 5000; 
					return;
				end
			end
			 
			if (IsGhost())then
				self.message = "Walking to corpse...";
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
			end	
			return;
		end
		
		----------------------------------------------------------
		--  					BREATH:			    			--
		----------------------------------------------------------
		self.breathTime = ((GetTimeEX()-self.notBreathTime)/1000);
		if (UnitRace("player") == "Undead") then
			if (self.breathTime > 220.000) then
				if (IsLooting()) then CloseLoot(); end
				while (self.breathTime > 1.000) do
					JumpOrAscendStart();
					return;
				end
			end	
		elseif (self.breathTime > 45.000) then
			if (IsLooting()) then CloseLoot(); end
			while (self.breathTime > 1.000) do
				JumpOrAscendStart();
				return;
			end	
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
				
				if (IsSwimming()) then
					script_nav:navigate(GetLocalPlayer());
				end
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
		if (sig_helper:HealsAndBuffs()) then
			self.message = "Healing / Buff / Support Party ";
			return;
		end
		
		if (sig_helper:HealsAndBuffsPets()) then
			self.message = "Healing / Buff / Support Pets ";
			return;
		end
		
		if (sig_helper:classSpecifics()) then
			self.message = "Class especific action ";
			return;
		end
		
		----------------------------------------------------------
		-- 				FOLLOW RANGE VARIATION					--
		----------------------------------------------------------
		-- Randomize the follow range
		if (self.followTimer < GetTimeEX()) then 
			self.followTimer = GetTimeEX() + 5000;
			self.followDistance = math.random(self.minFollowDist,self.maxFollowDist); -- 15,25
		end
		
		--if (IsIndoors()) then
		--	self.followDistance = 3;
		-- end
		
	
		----------------------------------------------------------
		--  				FOLLOW IGNORE COMBAT				--
		----------------------------------------------------------
		-- Follow ignoing combat self.IgnoreAttacks 
		if (self.ptLeaderExist and self.targetPtLeaderExist) then
			if(self.targetOfptLeader:GetGUID() == self.ptLeader:GetGUID()) then
				
				-- Disable Combat Script and Target Script
				self.IgnoreAttacks = true;
				self.enemyObj = nil
				ClearTarget();
				sig_scripts.movementmessage = "Following " .. self.ptLeader:GetUnitName() .. " ignoring combat...";
				if (IsLooting()) then CloseLoot(); end
				
				-- Follow
				if (self.ptLeader:GetDistance() > 3 and self.autoFollow) then
					local x, y, z = self.ptLeader:GetPosition();
					-- script_follow:moveToTarget(GetLocalPlayer(), x, y, z);
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
		--  					     LOOT						--
		----------------------------------------------------------
		if (not IsInCombat() and IsLooting()) then
			if (GetNumLootItems() == 0) then
				sig_scripts.lootmessage = "Fixed..";
				CloseLoot();
				ClearTarget();
			end
		end
		
		if (not IsInCombat() and script_grind:enemiesAttackingUs() == 0 and not localObj:HasBuff('Feign Death')) then
			
			local canloot = true;
			if (self.targetPtLeaderExist) then
				if (not self.targetOfptLeader:IsDead() and self.targetOfptLeader:CanAttack()) then
					canloot = false;
				end
			end
			
			-- Check if Have body Lootable
			if (not self.skipLooting and not AreBagsFull() and canloot) then 
				self.lootObj = script_nav:getLootTarget(self.findLootDistance);
			else
				self.lootObj = nil;
				sig_scripts.lootmessage = "Nothing to loot..";
			end
			
			-- Sets variable
			if (self.lootObj == 0) then self.lootObj = nil; end
			
			
			if (self.lootObj ~= nil) then
				-- Not loot Blacklisted Copses
				if (script_grind:isTargetBlacklisted(self.lootObj:GetGUID())) then canloot = false; sig_scripts.lootmessage = "Blacklisted.."; end
				-- Not Loot Bodyes near the another mob
				if (not sig_scripts:isAreaNearTargetSafe(self.lootObj)) then canloot = false; sig_scripts.lootmessage = "Not safe.."; end
				-- Not loot if enemyes attacking friends
				if (script_follow:enemiesAttackingParty() >=1) then canloot = false; sig_scripts.lootmessage = "Party aggro.."; end
			end
			
			if (not canloot) then self.lootObj = nil; end
			
			-- local isLoot = not IsInCombat() and not (self.lootObj == nil);
			local isLoot = not IsInCombat() and not (self.lootObj == nil) and canloot;
			if (isLoot and not AreBagsFull()) then
				script_grindEX:doLoot(localObj);
				return;
			elseif (AreBagsFull() and not hsWhenFull) then
				self.lootObj = nil;
				sig_scripts.lootmessage = "Warning the bags are full...";
			end
		end
		
		
		
		----------------------------------------------------------
		--  				GATHER / USE ITEM					--
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
		if (not self.IgnoreAttacks and not self.targetPtLeaderExist) then
			
			-- HAVE ENEMY ATTACKING US
			if (script_grind:enemiesAttackingUs() >= 1) then
			
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
				-- Return target is attacking group/pet if not in combat
				local foundTarget = sig_scripts:searchingTarget(70);
				if (foundTarget ~= nil and foundTarget ~= 0) then
					sig_scripts.message = tostring(foundTarget:GetUnitName());
					if (foundTarget:GetHealthPercentage() <= self.dpsHp) then
						self.enemyObj = foundTarget;
					else
						self.enemyObj = nil;
					end
				else
					self.enemyObj = nil;
				end
				
			end
			
			-- Protect the healer
			if (self.isAttackingHealer) then -- and self.targetPtLeaderExist
				--if (self.targetOfptLeader:GetUnitsTarget() ~= nil) then
				--	if (self.targetOfptLeader:GetUnitsTarget():GetUnitName() == self.HealerName) then
						self.enemyObj = self.objAttackingHealer;
				--	end
				--end
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
		
		-- Check: If we are in combat but no valid target, kill the "unvalid" target attacking us
		if (self.enemyObj == nil and IsInCombat() and not self.targetPtLeaderExist) then
			if (GetTarget() ~= 0) then
				self.enemyObj = GetTarget();
			end
		end
		
		local isTaunting = sig_scripts:tauntInhealer();
		if (HasSpell('Defensive Stance') and isTaunting ~= nil) then
			self.enemyObj = isTaunting;
		end
		
		----------------------------------------------------------
		--				DISABLE TARGET FOR HEALERS				--
		----------------------------------------------------------
		-- Priest
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
		 
		 --Shamman
		 -- Check: If we are a priest and not do damage if Leader life below 70%
		 --if (HasSpell('Healing Wave') and self.ptLeaderExist and not self.ptLeader:IsDead() and self.ptLeader:GetHealthPercentage() < 70 and localObj:GetHealthPercentage() > 50) then
		 --	self.enemyObj = nil;
		 --end
		 -- Check: If we are a priest and we are at least 3 party members, dont do damage if mana below 90%
		 if (HasSpell('Healing Wave') and GetNumPartyMembers() > 2 and localObj:GetHealthPercentage() > 50) then
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
					if (IsSwimming()) then
						self.message = Move(_x, _y, _z);
					else
						self.message = script_nav:moveToTarget(GetLocalPlayer(), _x, _y, _z);
					end
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
		--  					INTERACT						--
		----------------------------------------------------------
		if (self.ptLeaderExist and not IsInCombat() and not script_gather.isGatheringQuest) then -- and not self.useQuestItem
			
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
					if (interactTarget:GetDistance() > 3) then
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
		
		----------------------------------------------------------
		--  					FOLLOW NORMAL					--
		----------------------------------------------------------
		
		-- Follow our master
		if (self.ptLeaderExist and not self.Interacting and self.autoFollow and not script_gather.isGatheringQuest) then
			if(self.ptLeader:GetDistance() > self.followDistance and not self.ptLeader:IsDead()) then
				
				local x, y, z = self.ptLeader:GetPosition();
				sig_scripts.movementmessage = "Following " .. self.ptLeader:GetUnitName() .. "...";
				
				-- Move in squadmode, including in water
				if (self.squadmode and canSquadmode) then
				
					if (not IsSwimming()) then
					
						if (IsIndoors()) then
							self.randPlus = 0;
							self.randMinus = 0;
						else
							if (GetTimeEX() > self.randSquadPosTime) then
								self.randSquadPosTime = GetTimeEX() + 5000;
								self.randPlus = math.random(1,4);
								self.randMinus = math.random(1,4);
							end
						end
						
						-- Stop move if near ptLeader
						if (self.ptLeader:GetDistance() <= 3) then
							if(IsMoving()) then
								StopMoving();
							end
						end
					
						if (GetLocalPlayer():GetUnitName() == "Bolazul") then
							script_nav:moveToTarget(GetLocalPlayer(), x+self.randPlus, y+self.randPlus, z);
						elseif (GetLocalPlayer():GetUnitName() == "Cutuca") then
							script_nav:moveToTarget(GetLocalPlayer(), x-self.randMinus, y-self.randMinus, z);
						elseif (GetLocalPlayer():GetUnitName() == "Sodot") then
							script_nav:moveToTarget(GetLocalPlayer(), x+self.randPlus, y-self.randMinus, z);
						else
							script_nav:moveToTarget(GetLocalPlayer(), x-self.randMinus, y+self.randPlus, z);
						end
					else
						Move(x, y, z);
					end
				else
					-- Stop move if near ptLeader
					if (self.ptLeader:GetDistance() <= 3) then
						if(IsMoving()) then
							StopMoving();
						end
					end
					-- Move in line, including water
					if (IsSwimming())then
						Move(x, y, z);
					else
						script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
					end
				end
				
				
				
				return;
			end
		end
		
	end 
end
