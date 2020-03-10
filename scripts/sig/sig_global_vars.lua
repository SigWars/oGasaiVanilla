sig_globalVars = {
	-- Combat time
	combatTime = 0,
	combatTimeStarted = false,
	combatProgressTime = 0,
	-- Combat End Time
	endCombatTime = GetTimeEX(),
	endCombatTimeSet = false,
	endCombatProgressTime = GetTimeEX(),
	-- Looting Time
	lootTime = 0,
	lootTimeStarted = false,
	lootProgressTime = 0,
	
}

function sig_globalVars:getCombatTime()
	if (IsInCombat()) then
		if (not combatTimeStarted) then
			combatTimeStarted = true;
			self.combatTime = GetTimeEX();
		end
		self.combatProgressTime = GetTimeEX() - self.combatTime;
	else
		if (combatTimeStarted) then
			combatTimeStarted = false;
			self.combatProgressTime = 0;
		end	
	end
	return self.combatProgressTime;
end

function sig_globalVars:getEndcombatTime()
	if (not IsInCombat()) then
		if (not endCombatTimeSet) then
			endCombatTimeSet = true;
			self.endCombatTime = GetTimeEX();
		end
		self.endCombatProgressTime = GetTimeEX() - self.endCombatTime;
	else
		if (endCombatTimeSet) then
			endCombatTimeSet = false;
			self.endCombatProgressTime = 0;
		end	
	end
	return self.endCombatProgressTime;
end

function sig_globalVars:getLootTime()
	if (IsLooting()) then
		if (not lootTimeStarted) then
			lootTimeStarted = true;
			self.lootTime = GetTimeEX();
		end
		self.lootProgressTime = GetTimeEX() - self.lootTime;
	else
		if (lootTimeStarted) then
			lootTimeStarted = false;
			self.lootProgressTime = 0;
		end	
	end
	return self.lootProgressTime;
end