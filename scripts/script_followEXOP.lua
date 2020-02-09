script_followEXOP = {
	sigs = include("scripts\\sig\\sig_scripts.lua")
}

function script_followEXOP:drawStatus()
	if (script_followOP.drawPath) then script_nav:drawPath(); end

	if (script_followOP.drawUnits) then script_nav:drawUnitsDataOnScreen(); end
	-- color
	local r, g, b = 255, 255, 0;
	-- position
	local y, x, width = 120, 25, 370;
	local tX, tY, onScreen = WorldToScreen(GetLocalPlayer():GetPosition());
	if (onScreen) then
		y, x = tY-25, tX+75;
	end
	DrawRect(x - 10, y - 5, x + width, y + 80, 255, 255, 0,  1, 1, 1);
	DrawRectFilled(x - 10, y - 5, x + width, y + 80, 0, 0, 0, 160, 0, 0);
	if (script_followOP.MasterObject ~= 0) then
		DrawText('[Follower - Range: ' .. math.floor(script_followOP.followDistance) .. ' yd. ' .. 
			 	'Master target: ' .. script_followOP.MasterObject:GetUnitName(), x-5, y-4, r, g, b) y = y + 15;
	else
		DrawText('[Follower - Follow range: ' .. math.floor(script_followOP.followDistance) .. ' yd. ' .. 
			 	'Master target: ' .. '', x-5, y-4, r, g, b) y = y + 15;
	end 
	DrawText('Status: ', x, y, r, g, b); 
	y = y + 15; DrawText(script_followOP.message or "error", x, y, 0, 255, 255);
	y = y + 20; DrawText('Combat script status: ', x, y, r, g, b); y = y + 15;
	RunCombatDraw();
end

function script_grindEX:doLoote(localObj)
	local _x, _y, _z = script_followOP.lootObj:GetPosition();
	local dist = script_followOP.lootObj:GetDistance();
	
	-- Loot checking/reset target
	if (GetTimeEX() > script_followOP.lootCheck['timer']) then
		if (script_followOP.lootCheck['target'] == script_followOP.lootObj:GetGUID()) then
			script_followOP.lootObj = nil; -- reset lootObj
			ClearTarget();
			script_followOP.message = 'Reseting loot target...';
		end
		script_followOP.lootCheck['timer'] = GetTimeEX() + 10000; -- 10 sec
		if (script_followOP.lootObj ~= nil) then 
			script_followOP.lootCheck['target'] = script_followOP.lootObj:GetGUID();
		else
			script_followOP.lootCheck['target'] = 0;
		end
		return;
	end

	if(dist <= script_followOP.lootDistance) then
		script_followOP.message = "Looting...";
		if(IsMoving() and not localObj:IsMovementDisabed()) then
			StopMoving();
			script_followOP.waitTimer = GetTimeEX() + 450;
			return;
		end
		if(not IsStanding()) then
			StopMoving();
			script_followOP.waitTimer = GetTimeEX() + 450;
			return;
		end
		
		-- If we reached the loot object, reset the nav path
		script_nav:resetNavigate();

		-- Dismount
		if (IsMounted()) then DisMount(); script_followOP.waitTimer = GetTimeEX() + 450; return;  end

		if(not script_followOP.lootObj:UnitInteract() and not IsLooting()) then
			script_followOP.waitTimer = GetTimeEX() + 950;
			return;
		end
		if (not LootTarget()) then
			script_followOP.waitTimer = GetTimeEX() + 650;
			return;
		else
			script_followOP.lootObj = nil;
			script_followOP.waitTimer = GetTimeEX() + 450;
			return;
		end
	end
	script_followOP.message = "Moving to loot...";		
	script_nav:moveToTarget(localObj, _x, _y, _z);	
	script_grind:setWaitTimer(100);
	if (script_followOP.lootObj:GetDistance() < 3) then script_followOP.waitTimer = GetTimeEX() + 450; end
end

function script_followEXOP:menu()
--	local wasClicked = false;
--	wasClicked, script_followOP.OPMode = Checkbox("Use OPMode?", script_followOP.OPMode);
	if (not script_followOP.pause) then if (Button("Pause Bot")) then script_followOP.pause = true; end
	else if (Button("Resume Bot")) then script_followOP.myTime = GetTimeEX(); script_followOP.pause = false; end end
	SameLine(); if (Button("Reload Scripts")) then coremenu:reload(); end
	SameLine(); if (Button("Exit Bot")) then StopBot(); end
	script_followOP.PartyName = InputText("Name of The player", script_followOP.PartyName);
	Separator();

	-- Load combat menu by class
	local class = UnitClass("player");
	
	sig_scripts:loadclass();
	
	

	if (CollapsingHeader("[Follower - Options")) then
		
		-- Text("If use Follow Op mode:");
		-- wasClicked, script_followOP.OPMode = Checkbox("Use OPMode?", script_followOP.OPMode);
		-- script_followOP.PartyName = InputText("Name of The player", script_followOP.PartyName);
		-- Separator();
		
		Text("Combat options:");
		script_followOP.minFollowDist  = SliderInt("Minimal Follow Distance", 3, 25, script_followOP.minFollowDist);
		script_followOP.maxFollowDist  = SliderInt("Maximun Follow Distance", 3, 25, script_followOP.maxFollowDist);
		-- script_followOP.minFollowDist = InputText("Minimal Follow Distance", script_followOP.minFollowDist);
		-- script_followOP.maxFollowDist = InputText("Maximun Follow Distance", script_followOP.maxFollowDist);
		script_followOP.dpsHp = SliderInt("Monster health when we DPS", 1, 100, script_followOP.dpsHp);
		Separator();
		Text("Loot options:");
		wasClicked, script_followOP.skipLooting = Checkbox("Skip Looting", script_followOP.skipLooting);
		script_followOP.findLootDistance = SliderFloat("Find Loot Distance (yd)", 1, 100, script_followOP.findLootDistance);	
		script_followOP.lootDistance = SliderFloat("Loot Distance (yd)", 1, 6, script_followOP.lootDistance);
		Separator();
		Text("Mount options:");
		wasClicked, script_followOP.useMount = Checkbox("Use Mount", script_followOP.useMount);
		script_followOP.disMountRange = SliderInt("Dismount range", 1, 100, script_followOP.disMountRange);
		Separator();
		Text("Script tick rate options:");
		script_followOP.tickRate = SliderFloat("Tick rate (ms)", 0, 2000, script_followOP.tickRate);
	end
	
	script_gather:menu();
	if (CollapsingHeader('[Display options')) then
		local wasClicked = false;
		wasClicked, script_followOP.drawPath = Checkbox('Show move path', script_followOP.drawPath);
		wasClicked, script_followOP.drawUnits = Checkbox("Show unit info on screen", script_followOP.drawUnits);
	end
end