script_followEX = {
	sigs = include("scripts\\sig\\sig_scripts.lua"),
	waitTimerEx = GetTimeEX()
}

function script_followEX:drawStatus()
	if (script_follow.drawPath) then script_nav:drawPath(); end
	if (script_follow.drawGather) then script_gather:drawGatherNodes(); end
	if (script_follow.drawUnits) then script_nav:drawUnitsDataOnScreen(); end
	-- color
	local r, g, b = 255, 255, 0;
	-- position
	local y, x, width = 120, 25, 370;
	local tX, tY, onScreen = WorldToScreen(GetLocalPlayer():GetPosition());
	if (onScreen) then
		y, x = tY-25, tX+75;
	end
	DrawRect(x - 10, y - 5, x + width, y + 140, 255, 255, 0,  1, 1, 1);
	DrawRectFilled(x - 10, y - 5, x + width, y + 140, 0, 0, 0, 160, 0, 0);
	
	--[[
	if (script_follow:GetPartyLeaderObject() ~= 0) then
		DrawText('[Follower - Range: ' .. math.floor(script_follow.followDistance) .. ' yd. ' .. 
			 	'Master target: ' .. script_follow:GetPartyLeaderObject():GetUnitName(), x-5, y-4, r, g, b) y = y + 15;
	else
		DrawText('[Follower - Follow range: ' .. math.floor(script_follow.followDistance) .. ' yd. ' .. 
			 	'Master target: ' .. '', x-5, y-4, r, g, b) y = y + 15;
	end 
	]]--
	
	local time = ((GetTimeEX()-script_follow.notBreathTime)/1000);
	DrawText('Breath-Timer: ' .. math.floor(time) .. ' s.', x+200, y, 0, 255, 255);
	
	DrawText('Follow Status: ', x, y, 255, 255, 255); y = y + 13; 
	DrawText(script_follow.message or "error", x, y, 255, 255, 0); y = y + 14;
	
	DrawText('Movement Status: ', x, y, 255, 255, 255); y = y + 13;
	DrawText(sig_scripts.movementmessage or "error", x, y, 0, 255, 0); y = y + 12; 
	
	DrawText('Combat script status: ', x, y, 255, 255, 255);y = y + 25;
	RunCombatDraw();
	
	DrawText('Loot status: ', x, y, 255, 255, 255); y = y + 15;
	y = y + 0; DrawText(sig_scripts.lootmessage or "error", x, y, 255, 0, 255);y = y + 15;
	
	DrawText('Sig Debug: ', x, y, 255, 255, 255); y = y + 15;
	y = y + 0; DrawText(sig_scripts.message or "error", x, y, 255, 102, 102);
	
	if (script_follow.lootCheck['timer'] == nil) then
		script_follow.lootCheck['timer'] = 0;
	end
	DrawText('Blacklist: ' .. math.max(0, script_follow.lootCheck['timer']-GetTimeEX()) .. ' ms.', x+200, y-45, 255, 255, 255);

	
end

--[[
function script_grindEX:doLoot(localObj)
	local _x, _y, _z = script_follow.lootObj:GetPosition();
	local dist = script_follow.lootObj:GetDistance();
	
	-- Loot checking/reset target
	if (GetTimeEX() > script_follow.lootCheck['timer']) then
		if (script_follow.lootCheck['target'] == script_follow.lootObj:GetGUID()) then
			script_follow.lootObj = nil; -- reset lootObj
			ClearTarget();
			sig_scripts.lootmessage = 'Reseting loot target...';
		end
		script_follow.lootCheck['timer'] = GetTimeEX() + 10000; -- 10 sec
		if (script_follow.lootObj ~= nil) then 
			script_follow.lootCheck['target'] = script_follow.lootObj:GetGUID();
		else
			script_follow.lootCheck['target'] = 0;
		end
		return;
	end

	if(dist <= script_follow.lootDistance) then
		sig_scripts.lootmessage = "Looting...";
		if(IsMoving() and not localObj:IsMovementDisabed()) then
			StopMoving();
			script_follow.waitTimer = GetTimeEX() + 450;
			return;
		end
		if(not IsStanding()) then
			StopMoving();
			script_follow.waitTimer = GetTimeEX() + 450;
			return;
		end
		
		-- If we reached the loot object, reset the nav path
		script_nav:resetNavigate();

		-- Dismount
		if (IsMounted()) then DisMount(); script_follow.waitTimer = GetTimeEX() + 450; return;  end

		if(not script_follow.lootObj:UnitInteract() and not IsLooting()) then
			script_follow.waitTimer = GetTimeEX() + 950;
			return;
		end
		if (not LootTarget()) then
			script_follow.waitTimer = GetTimeEX() + 650;
			return;
		else
			script_follow.lootObj = nil;
			script_follow.waitTimer = GetTimeEX() + 450;
			return;
		end
	end
	sig_scripts.movementmessage = "Moving to loot...";		
	script_nav:moveToTarget(localObj, _x, _y, _z);	
	script_grind:setWaitTimer(100);
	if (script_follow.lootObj:GetDistance() < 3) then script_follow.waitTimer = GetTimeEX() + 450; end
end
]]--

function script_grindEX:doLoot(localObj)
	--[[
	if (script_follow.lootObj == nil or script_follow.lootObj == 0) then
		return;
	end
	]]--
	
	local _x, _y, _z = script_follow.lootObj:GetPosition();
	local dist = script_follow.lootObj:GetDistance();
	
	

	-- Add mpore time if is resting or other
	if (script_follow.lootCheck['target'] == script_follow.lootObj:GetGUID()) then
		if (IsCasting() or IsChanneling() or IsDrinking() or IsEating() or IsInCombat() or script_follow:enemiesAttackingParty() > 0 or RunRestScript() or script_follow.lootObj:GetDistance() > 3) then
			if (GetTimeEX() > script_follow.lootCheck['timer']) then
				script_follow.lootCheck['timer'] = GetTimeEX() + 10000; -- 10 sec
				if (script_follow.lootObj ~= nil) then 
					script_follow.lootCheck['target'] = script_follow.lootObj:GetGUID();
				else
					script_follow.lootCheck['target'] = 0;
				end
				return;
			end	
		end	
	end
	
	-- Loot checking/reset target
	if (GetTimeEX() > script_follow.lootCheck['timer']) then
	
		-- Add to blacklist
		if (script_follow.lootCheck['target'] == script_follow.lootObj:GetGUID() and script_follow.lootObj:GetDistance() < 3) then
			-- script_follow.waitTimer = GetTimeEX() + 2000;
			script_grind:addTargetToBlacklist(script_follow.lootObj:GetGUID());
			script_follow.lootObj = nil; -- reset lootObj
			ClearTarget();
			CloseLoot();
			sig_scripts.lootmessage = 'Reseting loot target...';
			return;
		end
		
		-- sets new check time
		script_follow.lootCheck['timer'] = GetTimeEX() + 5000; -- 10 sec
		if (script_follow.lootObj ~= nil) then 
			script_follow.lootCheck['target'] = script_follow.lootObj:GetGUID();
		else
			script_follow.lootCheck['target'] = 0;
		end
		
		return;
	end

	if(dist <= script_follow.lootDistance) then
		sig_scripts.lootmessage = "Looting " .. script_follow.lootObj:GetGUID() .. "...";
		if(IsMoving() and not localObj:IsMovementDisabed()) then
			StopMoving();
			script_follow.waitTimer = GetTimeEX() + 450;
			return;
		end
		if(not IsStanding()) then
			StopMoving();
			script_follow.waitTimer = GetTimeEX() + 450;
			return;
		end
		
		-- If we reached the loot object, reset the nav path
		script_nav:resetNavigate();

		-- Dismount
		if (IsMounted()) then DisMount(); script_follow.waitTimer = GetTimeEX() + 450; return;  end

		if(not script_follow.lootObj:UnitInteract() and not IsLooting()) then
			script_follow.waitTimer = GetTimeEX() + 950;
			return;
		end
		-- Sucess on loot
		if (script_follow.lootCheck['target'] == script_follow.lootObj:GetGUID()) then
				sig_scripts.lootmessage = "End Loot " .. script_follow.lootObj:GetGUID() .. "...";
				-- script_follow.lootCheck['timer'] = GetTimeEX() + 3000;
		end
		
		if (not LootTarget()) then
			script_follow.waitTimer = GetTimeEX() + 650;
			return;
		else
			script_follow.lootObj = nil;
			script_follow.waitTimer = GetTimeEX() + 450;
			return;
		end
	end

	-- Blacklist loot target if swimming or we are close to aggro blacklisted targets and not close to loot target
	--[[if (script_follow.lootObj ~= nil) then
		if (IsSwimming() or (script_aggro:closeToBlacklistedTargets() and script_follow.lootObj:GetDistance() > 5)) then
			script_grind:addTargetToBlacklist(script_follow.lootObj:GetGUID());
			DEFAULT_CHAT_FRAME:AddMessage('script_grind: Blacklisting loot target to avoid aggro/swimming...');
			return;
		end
	end]]--
	sig_scripts.lootmessage = "Moving to loot...";		
	script_nav:moveToTarget(localObj, _x, _y, _z);	
	script_grind:setWaitTimer(100);
	if (script_follow.lootObj:GetDistance() < 3) then script_follow.waitTimer = GetTimeEX() + 450; end
end


function script_followEX:menu()

	-- if (CollapsingHeader("[Follower - Options")) then
	
	
	local wasClicked = false;
	if (not script_follow.pause) then if (Button("Pause Bot")) then script_follow.pause = true; end
	else if (Button("Resume Bot")) then script_follow.myTime = GetTimeEX(); script_follow.pause = false; end end
	SameLine(); if (Button("Reload Scripts")) then coremenu:reload(); end
	SameLine(); if (Button("Exit Bot")) then StopBot(); end 
	
	Separator();
	Text("FOLLOW OPTIONS:");
	Separator();

		if (CollapsingHeader("[Follower - Basic Options")) then
			wasClicked, script_follow.enableGather = Checkbox("Gatgher professions  ", script_follow.enableGather);
			SameLine(); wasClicked, script_follow.autoFollow = Checkbox("AutoFollow", script_follow.autoFollow);
			wasClicked, script_follow.gatherForQuest = Checkbox("Gather for quests    ", script_follow.gatherForQuest);
			SameLine();wasClicked, script_follow.autoTalent = Checkbox("Auto Talent", script_follow.autoTalent);
			wasClicked, script_follow.useQuestItem = Checkbox("Use Quest Item       ", script_follow.useQuestItem);
			SameLine(); wasClicked, script_follow.autoRepop = Checkbox("Auto Revive", script_follow.autoRepop);
			wasClicked, script_follow.IgnoreAttacks = Checkbox("Ignore Attacks       ", script_follow.IgnoreAttacks);
			SameLine(); wasClicked, script_follow.skipLooting = Checkbox("Skip Looting", script_follow.skipLooting);
			wasClicked, script_follow.tankMode = Checkbox("Tank Warrior         ", script_follow.tankMode);
			SameLine(); wasClicked, script_follow.useMount = Checkbox("Use Mount", script_follow.useMount);

		end
		-- Quest Objectives
		if (script_follow.gatherForQuest)then
			Text("#### OBJECTS TO INTERACT ####");	
			script_follow.QuestObjectName1 = InputText("Name GameObject 1", script_follow.QuestObjectName1);
			script_follow.QuestObjectName2 = InputText("Name GameObject 2", script_follow.QuestObjectName2);
			script_follow.QuestObjectName3 = InputText("Or GameObject DisplayID", script_follow.QuestObjectName3);
			script_follow.gatherQuestDistance  = SliderInt("Gather Distance", 0, 150, script_follow.gatherQuestDistance);
		end		
		if (script_follow.useQuestItem) then
			Separator();
				Text("#### ITEM ####");	
				script_follow.questItemName = InputText("Item Name", script_follow.questItemName);
				script_follow.objectiveName = InputText("Object/Unit will use item", script_follow.objectiveName);
		end
		

		if (CollapsingHeader("[Follower - Combat")) then
			local wasClicked = false;
			Text("#### ESPECIFICS ####");
			Text("Name of pet Healed/Assited - Preiest Heals and Warrior Taunts");
			script_follow.PetName = InputText("Party pet name", script_follow.PetName);
			script_follow.minFollowDist  = SliderInt("Minimal Follow Distance", 5, 25, script_follow.minFollowDist);
			script_follow.maxFollowDist  = SliderInt("Maximun Follow Distance", 5, 25, script_follow.maxFollowDist);
			-- script_follow.minFollowDist = InputText("Minimal Follow Distance", script_follow.minFollowDist);
			-- script_follow.maxFollowDist = InputText("Maximun Follow Distance", script_follow.maxFollowDist);
			script_follow.dpsHp = SliderInt("Monster health when we DPS", 1, 100, script_follow.dpsHp);
			Separator();
			Text("#### LOOT ####");
			script_follow.findLootDistance = SliderFloat("Find Loot Distance (yd)", 1, 100, script_follow.findLootDistance);	
			script_follow.lootDistance = SliderFloat("Loot Distance (yd)", 1, 6, script_follow.lootDistance);
			Separator();
			Text("#### MOUNT ####");
			script_follow.disMountRange = SliderInt("Dismount range", 1, 100, script_follow.disMountRange);
			Separator();
			Text("Script tick rate options:");
			script_follow.tickRate = SliderFloat("Tick rate (ms)", 0, 2000, script_follow.tickRate);
		end	
	-- end

		Separator();
		Separator();
		sig_scripts:loadclass();
		
		if (script_follow.enableGather)then
			script_gather:menu();
		end
		

	
	if (CollapsingHeader('[Display options')) then
		local wasClicked = false;
		wasClicked, script_follow.drawPath = Checkbox('Show move path', script_follow.drawPath);
		wasClicked, script_follow.drawUnits = Checkbox("Show unit info on screen", script_follow.drawUnits);
		wasClicked, script_follow.drawGather = Checkbox('DrawGather', script_follow.drawGather);
	end
end