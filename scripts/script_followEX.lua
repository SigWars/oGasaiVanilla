script_followEX = {
	sigs = include("scripts\\sig\\sig_scripts.lua"),
	waitTimerEx = GetTimeEX()
}

function script_followEX:drawStatus()
	if (script_follow.drawDebug) then
	
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
			script_follow.lootCheck['target'] = 0;
			script_follow.lootCheck['timer'] = 0;
		end
		DrawText('Blacklist: ' .. math.max(0, script_follow.lootCheck['timer']-GetTimeEX()) .. ' ms.', x+200, y-45, 255, 255, 255);
		-- DrawText('IsLooting: ' .. tostring(IsLooting()), x+200, y-35, 255, 255, 255);
	
		
		
		local down, up, lagHome, lagWorld = GetNetStats();
		local xxx, yyy, zzz = GetLocalPlayer():GetPosition();
		local aaa = GetLocalPlayer():GetAngle();
		local cx, cy, cz, ctime = GetTerrainClick();
		local islootable = false;
		if (GetLocalPlayer():GetUnitsTarget() ~= nil and GetLocalPlayer():GetUnitsTarget() ~= 0) then
			islootable = GetLocalPlayer():GetUnitsTarget():IsLootable();
		else 
			islootable = false;
		end
		y = y - 320;
		DrawRect(x - 10, y - 5, x + width, y + 185, 255, 255, 0,  1, 1, 1);
		DrawRectFilled(x - 10, y - 5, x + width, y + 185, 0, 0, 0, 160, 0, 0);
		-- Angle
		DrawText('Angle:', x, y, 255, 255, 255);
		DrawText(math.floor(aaa), x+50, y, 0, 255, 0); y = y + 15;
		-- Position
		DrawText('Postition: ', x, y, 255, 255, 255);
		DrawText('X:' .. math.floor(xxx) .. ' Y:' .. math.floor(yyy) .. ' Z:' .. math.floor(zzz), x+80, y, 0, 255, 0); y = y + 15;
		
		DrawText('Click: ', x, y, 255, 255, 255);
		DrawText('X:' .. math.floor(cx) .. ' Y:' .. math.floor(cy) .. ' Z:' .. math.floor(cz), x+80, y, 0, 255, 0); y = y + 15; 
		
		-- is looting
		DrawText('IsLooting:', x, y, 255, 255, 255);
		if (IsLooting()) then
			DrawText(tostring(IsLooting()), x+80, y, 0, 255, 0); y = y + 15;
		else
			DrawText(tostring(IsLooting()), x+80, y, 255, 0, 0); y = y + 15;
		end
		-- is lootable
		DrawText('IsLootable:', x, y, 255, 255, 255);
		if (islootable) then
			DrawText(tostring(islootable), x+80, y, 0, 255, 0); y = y + 15;
		else
			DrawText(tostring(islootable), x+80, y, 255, 0, 0); y = y + 15;
		end
		-- indoors
		DrawText('IsIndoors:', x, y, 255, 255, 255);
		if (IsIndoors()) then
			DrawText(tostring(IsIndoors()), x+80, y, 0, 255, 0); y = y + 15;
		else
			DrawText(tostring(IsIndoors()), x+80, y, 255, 0, 0); y = y + 15;
		end
		-- navmesh
		DrawText('UsingNavsh:', x, y, 255, 255, 255);
		if (IsUsingNavmesh()) then
			DrawText(tostring(IsUsingNavmesh()), x+80, y, 0, 255, 0); y = y + 15;
		else
			DrawText(tostring(IsUsingNavmesh()), x+80, y, 255, 0, 0); y = y + 15;
		end
		
		-- Swiing
		DrawText('IsSwimming:', x, y, 255, 255, 255);
		if (IsSwimming()) then
			DrawText(tostring(IsSwimming()), x+80, y, 0, 255, 0); y = y + 15;
		else
			DrawText(tostring(IsSwimming()), x+80, y, 255, 0, 0); y = y + 15;
		end
		
		-- lootable items
		DrawText('Lootable items:', x, y, 255, 255, 255);
		DrawText(GetNumLootItems() or 0, x+110, y, 0, 255, 0); y = y + 15;
		
		-- Party Leader
		DrawText('Party Leader:', x, y, 255, 255, 255);
		local leader = nil;
		if (script_follow.ptLeaderExist) then 
			DrawText(tostring(script_follow.ptLeader:GetUnitName()), x+110, y, 0, 255, 0); y = y + 15;
		else
			DrawText("Nil", x+110, y, 0, 255, 0); y = y + 15;
		end
		
		-- Near Elevator
		DrawText('Near elevators:', x, y, 255, 255, 255);
		if (script_follow.nearElevator) then
			DrawText(tostring(script_follow.nearElevator), x+110, y, 0, 255, 0); y = y + 15;
		else
			DrawText(tostring(script_follow.nearElevator), x+110, y, 255, 0, 0); y = y + 15;
		end
		--local teste = GetUnitName("mouseover");
		-- DrawText(tostring(teste), x+110, y, 0, 255, 0); y = y + 15;
		
		
		-- latency
		DrawText('Latency: '..lagHome..' ms.', x, y, 255, 255, 255); y = y + 15;
		
		
	end

	
end

function script_grindEX:doLoot(localObj)
	local _x, _y, _z = script_follow.lootObj:GetPosition();
	local dist = script_follow.lootObj:GetDistance();
	
	-- Loot checking/reset target
	if (GetTimeEX() > script_follow.lootCheck['timer']) then
		if (script_follow.lootCheck['target'] == script_follow.lootObj:GetGUID()) then
			if (script_follow.lootObj ~= nil) then
				if (dist <= 2) then 
					if (not script_grind:isTargetBlacklisted(script_follow.lootObj:GetGUID())) then
						script_grind:addTargetToBlacklist(script_follow.lootObj:GetGUID());
					end
				end
			end
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
		-- script_nav:resetNavigate();

		-- Dismount
		if (IsMounted()) then DisMount(); script_follow.waitTimer = GetTimeEX() + 450; return;  end
		
		-- local lootmethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod();		
		-- prevents not stuck in loot for bugged servers
		if (script_follow.lootCheck['target'] == script_follow.lootObj:GetGUID()) then
			if (IsLooting()) then
				if (GetNumLootItems() == 0) then
					-- Blacklist target
					if (script_follow.lootObj ~= nil) then
						if (not script_grind:isTargetBlacklisted(script_follow.lootObj:GetGUID())) then
							script_grind:addTargetToBlacklist(script_follow.lootObj:GetGUID());
						end
					end
					-- script_follow.waitTimer = GetTimeEX() + 650;
					
					sig_scripts.lootmessage = "0 items to loot, Blacklisting..";
					CloseLoot();
					ClearTarget();
					return;
				end
			end
		end	

		
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
	sig_scripts.lootmessage = "Moving to loot...";		
	script_follow:moveToTarget(localObj, _x, _y, _z);
	script_grind:setWaitTimer(100);
	if (script_follow.lootObj:GetDistance() < 3) then script_follow.waitTimer = GetTimeEX() + 450; end
end

function script_followEX:sigmenu()
	local wasClicked = false;
	wasClicked, script_follow.squadmode = Checkbox('Squad', script_follow.squadmode);
	SameLine(); wasClicked, script_follow.autoFollow = Checkbox("AutoFollow", script_follow.autoFollow);
	SameLine(); wasClicked, script_follow.drawDebug = Checkbox('Dbg', script_follow.drawDebug);
end

function script_followEX:menu()

	-- if (CollapsingHeader("[Follower - Options")) then
	
	
	local wasClicked = false;
	if (not script_follow.pause) then if (Button("Pause Bot")) then script_follow.pause = true; end
	else if (Button("Resume Bot")) then script_follow.myTime = GetTimeEX(); script_follow.pause = false; end end
	SameLine(); if (Button("Reload Scripts")) then coremenu:reload(); end
	SameLine(); if (Button("Exit Bot")) then StopBot(); end 
	SameLine(); wasClicked, script_follow.drawDebug = Checkbox('Dbg', script_follow.drawDebug);
	wasClicked, script_follow.squadmode = Checkbox('Squad', script_follow.squadmode);
	SameLine(); wasClicked, script_follow.autoFollow = Checkbox("AutoFollow", script_follow.autoFollow);
	
	Separator();
	Text("FOLLOW OPTIONS:");
	Separator();

		if (CollapsingHeader("[Follower - Basic Options")) then
			wasClicked, script_follow.enableGather = Checkbox("Gatgher professions  ", script_follow.enableGather);
			-- SameLine(); wasClicked, script_follow.autoFollow = Checkbox("AutoFollow", script_follow.autoFollow);
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
			script_follow.HealerName = InputText("Healer name", script_follow.HealerName);
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
		coremenu:loadclass();
		
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