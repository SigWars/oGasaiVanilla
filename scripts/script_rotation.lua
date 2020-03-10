script_rotation = {
	useMount = true,
	disMountRange = 25,
	timer = GetTimeEX(),
	tickRate = 200,
	combatError = 0,
	ressDistance = 25,
	message = 'Rotation by SigWar',
	enemyObj = 0,
	pause = false,
	aggroLoaded = include("scripts\\script_aggro.lua"),
	gatherLoaded = include("scripts\\script_gather.lua"),
	navFunctionsLoaded = include("scripts\\script_nav.lua"),
	helperLoaded = include("scripts\\script_helper.lua"),
	sigs = include("scripts\\sig\\sig_scripts.lua"),
	drawEnabled = false,
	drawAggro = false,
	drawGather = false,
	drawUnits = false,
	autoRepop = false,
	isSetup = false,
}

------------------------------------------------------------------------------------------------------------------------
-- REMOVE OR EDIT SM_Extended from supermacro addon folder!!!!otherwise it will autopassloot and do alot of others fings
------------------------------------------------------------------------------------------------------------------------

function script_rotation:setup()
	script_helper:setup();
	script_gather:setup();
	DEFAULT_CHAT_FRAME:AddMessage('script_rotation: loaded...');

	self.isSetup = true;
end

function script_rotation:window()

	EndWindow();

	if(NewWindow("Rotation", 320, 300)) then 
		script_rotation:menu(); 
	end
end

function script_rotation:run()

	
	if (not self.isSetup) then 
		script_rotation:setup(); 
	end

	if (self.pause) then 
		self.message = "Paused by user..."; 
		return; 
	end
	
	localObj = GetLocalPlayer();

	if (IsCasting() or IsChanneling()) then 
		return; 
	end
	
	if(self.timer > GetTimeEX()) then
		return;
	end
	

	self.timer = GetTimeEX() + self.tickRate;
	
	-- Automatic loading of the nav mesh
	if (not IsUsingNavmesh()) then UseNavmesh(true); return; end
	if (not LoadNavmesh()) then self.message = "Make sure you have mmaps-files..."; return; end
	if (GetLoadNavmeshProgress() ~= 1) then self.message = "Loading the nav mesh... " return; end
	
	-- Corpse-walk if we are dead
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
	
	if (not localObj:IsDead()) then
		
		self.enemyObj = GetTarget();		

		if(self.enemyObj ~= 0) then
			sig_scripts.rotationRunning = true;

			-- Auto dismount if in range
			if (IsMounted()) then 
				
				self.message = "Auto dismount if in range...";

				if (self.enemyObj:GetDistance() <= self.disMountRange) then
					DisMount(); 
					return; 
				end
			else
				-- Attack the target
				self.message = "Running the combat script on target...";
				RunCombatScript(self.enemyObj:GetGUID());
			end

			return;
			
		else
			-- Rest
			if (script_rotation:runRest()) then
				return;
			end
			
			-- Mount if not moving
			if (not IsMoving() and localObj:GetLevel() >= 40) then
				self.message = "Trying to mount up...";
				script_grind:mountUp();
				
			end

			self.message = "Waiting for a target...";
			sig_scripts.rotationRunning = false;
	
			return;
		end
	else
		-- Auto ress?

	end 
end

function script_grind:mountUp()
	local __, lastError = GetLastError();
	if (lastError ~= 75) then
		if(not IsSwimming() and not IsIndoors() and not IsMounted()) then
			
			if (script_helper:useMount()) then 
				self.timer = GetTimeEX() + 4000; 
				return true; 
			end
		end
	else
		ClearLastError();
		self.timer = GetTimeEX() + 4000; 
		return false;
	end
end

function script_rotation:draw()

	script_rotation:window();

	if (self.drawAggro) then 
		script_aggro:drawAggroCircles(100); 
	end

	if (self.drawGather) then 
		script_gather:drawGatherNodes(); 
	end

	if (self.drawUnits) then 
		script_nav:drawUnitsDataOnScreen(); 
	end

	-- color
	local r, g, b = 255, 255, 0;

	-- position
	local y, x, width = 120, 25, 370;
	local tX, tY, onScreen = WorldToScreen(GetLocalPlayer():GetPosition());
	if (onScreen) then
		-- y, x = tY, tX;
		y, x = tY+100, tX+200;
	end
	
	-- DrawText('Taunting: ' .. tostring(script_warrior.isTaunting), x, y, 255, 255, 255); y = y + 20;
	local toltext = sig_globalVars:getLootTime();
	DrawText('Loot Time: ' .. math.floor(toltext), x, y, 255, 255, 255); y = y + 20;
	
	local toltext = sig_globalVars:getCombatTime();
	DrawText('Start Combat Time: ' .. math.floor(toltext), x, y, 255, 255, 255); y = y + 20;
	
	local toltext = sig_globalVars:getEndcombatTime();
	DrawText('End Combat Time: ' .. math.floor(toltext), x, y, 255, 255, 255); y = y + 20;
	 
	
	if (not self.drawEnabled) then 
		return;
	end
	
	-- info
	if (not self.pause) then
		DrawRect(x - 10, y - 5, x + width, y + 80, 255, 255, 0,  1, 1, 1);
		DrawRectFilled(x - 10, y - 5, x + width, y + 80, 0, 0, 0, 60, 0, 0);
		DrawText('[Rotation - by SigWar', x-5, y-4, r, g, b) y = y + 15;
		DrawText('Script Idle: ' .. math.max(0, math.floor(self.timer-GetTimeEX())) .. ' ms.', x, y, 255, 255, 255); y = y + 20;
		
		DrawText('Rotation status: ', x, y, r, g, b); y = y + 20;
		DrawText(self.message or "error", x, y, 0, 255, 255); y = y + 30;
		
		local debug = true;
		if (debug) then	
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
			y = y - 250;
			DrawRect(x - 10, y - 5, x + width, y + 150, 255, 255, 0,  1, 1, 1);
			DrawRectFilled(x - 10, y - 5, x + width, y + 150, 0, 0, 0, 160, 0, 0);
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
			
			-- latency
			DrawText('Latency: '..lagHome..' ms.', x, y, 255, 255, 255); y = y + 15;
		end
		
	else
		DrawText('Rotation paused by user...', x-5, y-4, r, g, b);
	end
end

function script_rotation:runRest()
	if(RunRestScript()) then
		self.message = "Resting...";

		-- Stop moving
		if (IsMoving() or IsMounted()) then 
			return true; 
		end

		-- Add 2500 ms timer to the rest script rotations (timer could be set already)
		if ((self.timer - GetTimeEX()) < 2500) then 
			self.timer = GetTimeEX() + 2500;
		end

		return true;	
	end

	return false;
end

function script_rotation:menu()
	if (not script_grind.pause) then 
		if (Button("Pause")) then 
			self.pause = true; 
		end
	else 
		if (Button("Resume")) then 
			self.pause = false; 
		end 
	end

	SameLine(); 

	if (Button("Reload Scripts")) then 
		coremenu:reload(); 
	end

	SameLine(); 
	
	if (Button("Turn Off")) then 
		StopBot(); 
	end

	Separator();

	coremenu:loadclass();

	Text('Script tic rate (ms)');
	self.tickRate = SliderInt("TR", 50, 500, self.tickRate);

	Text('Dismount within range to target');
	self.disMountRange = SliderInt("DR", 1, 100, self.disMountRange);

	Separator();

	if (CollapsingHeader('[Display options')) then
		local wasClicked = false;
		wasClicked, self.drawEnabled = Checkbox('Show status window', self.drawEnabled);
		wasClicked, self.drawGather = Checkbox('Show gather nodes', self.drawGather);
		wasClicked, self.drawUnits = Checkbox("Show unit info on screen", self.drawUnits);
		wasClicked, self.drawAggro = Checkbox('Show aggro range circles', self.drawAggro);
	end
end