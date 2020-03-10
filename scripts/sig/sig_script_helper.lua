sig_helper = {
	-- sig scripts
	debuffableSpells = {"Spell1","Spell2"},
	debuffableCurses = {"Course1","Course2"}
}

function sig_helper:isSpellDebuffable(spellName) 
	for i=0,sig_scripts:countTable(self.debuffableSpells) do
		if (spellName == self.debuffableSpells[i]) then
			return true;
		end
	end
	return false;
end

function sig_helper:isCurseDebuffable(curseName)
	for i=0,sig_scripts:countTable(self.debuffableCurses) do
		if (curseName == self.debuffableCurses[i]) then
			return true;
		end
	end
	return false;
end

function sig_helper:HealsAndBuffs()

local class = UnitClass("player");

	local localMana = GetLocalPlayer():GetManaPercentage();
	local manaValor = GetLocalPlayer():GetMana();
	local localHath = GetLocalPlayer():GetHealthPercentage();
	local leaderobject = script_follow.ptLeader; 
		
	if (not IsStanding()) then StopMoving(); end
	-- Priest heal and buff
	for i = 1, GetNumPartyMembers()+1 do
		local partyMember = GetPartyMember(i);
		if (i == GetNumPartyMembers()+1) then partyMember = GetLocalPlayer(); end
		local partyMembersHP = partyMember:GetHealthPercentage();
		local partyGUID = partyMember:GetGUID();
		
		---------------------------
		-- PRIEST
		---------------------------
		if (class == 'Priest') then
			if (partyMember ~= nil and partyMember ~= 0 and sig_scripts:CalculateDistance(script_follow.ptLeader,partyMember) < 50) then
				
				-- Revive
				if (not IsInCombat() and partyMember:IsDead()) then
					if (not partyMember:IsSpellInRange('Resurrection')) then
						if (script_follow:moveInLineOfSight(partyMember)) then 
							return true; 
						end
					end
					if (Cast('Resurrection', partyMember)) then
						sig_scripts.message = "Ressurrecting Master...";
						script_follow.waitTimer = GetTimeEX() + 5500;
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
							script_follow.waitTimer = GetTimeEX() + 3500;
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
							script_follow.waitTimer = GetTimeEX() + 4500;
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
							script_follow.waitTimer = GetTimeEX() + 5500;
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
							script_follow.waitTimer = GetTimeEX() + 4500;
							return true;
						end
					end
					]]--
					
					--------------------
					-- Buffs
					--------------------
					if (not IsInCombat() and localMana > 40 and not partyMember:IsDead()) then -- buff
						if (not partyMember:HasBuff("Arcane Intellect") and HasSpell("Arcane Intellect")) then
							if (script_follow:moveInLineOfSight(partyMember)) then return true; end -- move to member
							if (Buff("Arcane Intellect", partyMember)) then
								script_follow.waitTimer = GetTimeEX() + 1500;
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
			if (leaderobject ~= nil and partyMember ~= nil and partyMember ~= 0 and partyMember:GetDistance() < 50) then
					--*****************
					-- Out Of Combat --
					--*****************
					-- Revive
					if (not IsInCombat() and partyMember:IsDead() and HasSpell("Ancestral Spirit") and sig_scripts:isAreaNearTargetSafe(partyMember)) then
						if (script_follow:moveInLineOfSight(partyMember)) then 
							return true; 
						end
						if (Cast('Ancestral Spirit', partyMember)) then
							script_follow.waitTimer = GetTimeEX() + 1500;
							sig_scripts.message = "Casting Ancestral Spirit on " .. partyMember:GetUnitName();
							return true;
						end
					end
				
				if (partyMembersHP > 0 and partyMembersHP < 99 and localMana > 5 and not partyMember:IsDead()) then -- and partyMember:GetGUID() == script_follow.ptLeader:GetGUID()
					
					--*****************			
					-- Leader heals --
					--*****************
					-- Lesser Heal
					if (manaValor >= 99 and leaderobject:GetHealthPercentage() <= 30 and HasSpell("Lesser Healing Wave")) then
						-- Move in line of sight and in range of the party member
						if (IsCasting()) then
							SpellStopCasting();
						end	
						if (script_follow:moveInLineOfSight(leaderobject)) then 
							return true; 
						end
						if (Cast('Lesser Healing Wave', leaderobject)) then
							script_follow.waitTimer = GetTimeEX() + 2500;
							return true;
						end
					end
					
					-- Heal
					if (manaValor >= 147 and leaderobject:GetHealthPercentage() <= 80 and HasSpell("Healing Wave")) then
						-- Move in line of sight and in range of the party member
						if (script_follow:moveInLineOfSight(leaderobject)) then 
							return true; 
						end
						if (Cast('Healing Wave', leaderobject)) then
							script_follow.waitTimer = GetTimeEX() + 3000;
							return true;
						end
					end	
					
					--****************************
					-- Other party mebers heals --
					--****************************
					-- Lesser Heal
					if (manaValor >= 99 and partyMembersHP < 40 and HasSpell("Lesser Healing Wave") and leaderobject:GetHealthPercentage() > 50) then
						-- Move in line of sight and in range of the party member
						if (IsCasting()) then
							SpellStopCasting();
						end	
						if (script_follow:moveInLineOfSight(partyMember)) then 
							return true; 
						end
						if (Cast('Lesser Healing Wave', partyMember)) then
							script_follow.waitTimer = GetTimeEX() + 2500;
							return true;
						end
					end
					
					-- Heal
					if (manaValor >= 147 and partyMembersHP < 80 and HasSpell("Healing Wave") and leaderobject:GetHealthPercentage() > 60) then
						-- Move in line of sight and in range of the party member
						if (script_follow:moveInLineOfSight(partyMember)) then 
							return true; 
						end
						if (Cast('Healing Wave', partyMember)) then
							script_follow.waitTimer = GetTimeEX() + 3000;
							return true;
						end
					end
				end
			end 
		end -- Shaman
		
		---------------------------
		-- WARLOCK
		---------------------------
		
		if (class == 'Warlock') then
			if (partyMember ~= nil and partyMember ~= 0 and partyMember:GetDistance() < 50) then
			
				if (partyMembersHP > 0 and partyMembersHP <= 100 and localMana > 5 and not partyMember:IsDead()) then -- and partyMember:GetGUID() == script_follow.ptLeader:GetGUID()
					
					-- Unending Breath					
					if (HasSpell('Unending Breath') and IsSwimming() and not partyMember:HasBuff('Unending Breath')) then
						if (script_follow:moveInLineOfSight(partyMember)) then return true; end -- move to member
						if (Buff('Unending Breath', partyMember)) then
							return true;
						end
					end
					
				end
			end 
		end -- Warlock
		
		---------------------------
		-- WARRIOR
		---------------------------
		if (class == 'Warrior') then
			if (partyMember ~= nil and partyMember ~= 0 and partyMember:GetDistance() < 50) then
			
				if (partyMembersHP > 0 and partyMembersHP < 99 and localMana > 5 and not partyMember:IsDead()) then -- and partyMember:GetGUID() == script_follow.ptLeader:GetGUID()
					
					-- Unending Breath					
				end
			end 
		end -- Warrior

	end -- For Loop

	return false;	
		
end

function sig_helper:classSpecifics()
	local class = UnitClass("player");
	
	if (class == 'Shaman') then
		local emcombat = sig_scripts:searchingTarget(100);
		if (emcombat ~= nil and emcombat ~= 0) then
			local x, y, z = emcombat:GetPosition();
			
			if (emcombat:GetDistance() > 20) then
				script_follow:moveToTarget(GetLocalPlayer(),x,y,z);
				return true;
			else
				if (IsMoving()) then StopMoving(); end
			end
			emcombat:FaceTarget();
			-- Totem 2
			if (HasSpell(script_shaman.totem2) and not localObj:HasBuff(script_shaman.totemBuff2)) then
				CastSpellByName(script_shaman.totem2);
				-- script_shaman.waitTimer = GetTimeEX() + 1500;
			end
			
			-- Totem 1
			if (HasSpell(script_shaman.totem) and not localObj:HasBuff(script_shaman.totemBuff)) then
				CastSpellByName(script_shaman.totem);
				-- script_shaman.waitTimer = GetTimeEX() + 1500;
			end
			return true;
		end
	end	
	
	return false;
end

function sig_helper:HealsAndBuffsPets()
	
	-- Prevent run away bug	
	if (script_follow.PetObject ~= 0 and script_follow.PetObject ~= nil and sig_scripts:CalculateDistance(localObj,script_follow.PetObject) < 150) then
	
		local localMana = GetLocalPlayer():GetManaPercentage();
		if (not IsStanding()) then StopMoving(); end
		
		local PetHP = script_follow.PetObject:GetHealthPercentage();
		
		-- Revive
		if (not IsInCombat() and script_follow.PetObject:IsDead()) then
			if (script_follow.PetObject:GetDistance() > 20) then
				if (script_follow:moveInLineOfSight(script_follow.PetObject)) then 
					return true; 
				end
			end
			if (Cast('Resurrection', script_follow.PetObject)) then
				sig_scripts.message = "Ressurrecting Master...";
				script_follow.waitTimer = GetTimeEX() + 5500;
				return true;
			end
		end
		
		--[[
		-- Ress partMaster Master
		if (script_follow.PetObject:GetUnitName() == script_follow.PetName and not IsInCombat() and script_follow.PetObject:IsDead()) then
			-- TargetByName(script_follow.PetObject:GetUnitName());
			if (Cast('Resurrection', script_follow.PetObject)) then
				script_follow.message = "Ressurrecting Master Pet...";
				script_follow.waitTimer = GetTimeEX() + 5500;
				return true;
			end
		end]]--
		
		if (PetHP > 0 and PetHP < 90 and localMana > 5 and script_follow.PetObject:GetUnitName() == script_follow.PetName) then
			
			-- Move in line of sight and in range of the party member
			 if (script_follow:moveInLineOfSight(script_follow.PetObject)) then 
				return true; 
			 end
			
			-- Renew
			if (localMana > 10 and PetHP < 90 and not script_follow.PetObject:HasBuff("Renew") and HasSpell("Renew")) then
				if (Buff('Renew', script_follow.PetObject)) then
					return true;
				end
			end

			-- Shield
			if (localMana > 10 and PetHP < 80 and not script_follow.PetObject:HasDebuff("Weakened Soul") and IsInCombat() and HasSpell("Power Word: Shield")) then
				if (Buff('Power Word: Shield', script_follow.PetObject)) then 
					return true; 
				end
			end

			-- Lesser Heal
			if (localMana > 10 and PetHP < 70) then
				if (Cast('Lesser Heal', script_follow.PetObject)) then
					script_follow.waitTimer = GetTimeEX() + 3500;
					return true;
				end
			end

			-- Heal
			if (localMana > 15 and PetHP < 50 and HasSpell("Heal")) then
				if (Cast('Heal', script_follow.PetObject)) then
					script_follow.waitTimer = GetTimeEX() + 4500;
					return true;
				end
			end

			-- Greater Heal
			if (localMana > 25 and PetHP < 30 and HasSpell("Greater Heal")) then
				if (Cast('Greater Heal', script_follow.PetObject)) then
					script_follow.waitTimer = GetTimeEX() + 5500;
					return true;
				end
			end
		end
		-- Buffs
		if (not IsInCombat() and localMana > 40) then -- buff
			if (not script_follow.PetObject:HasBuff("Shadow Protection") and HasSpell("Shadow Protection")) then
				if (script_follow:moveInLineOfSight(script_follow.PetObject)) then return true; end -- move to member
				if (Buff("Shadow Protection", script_follow.PetObject)) then
					return true;
				end
			end	
		end
		
		if (not IsInCombat() and localMana > 40) then -- buff
			if (not script_follow.PetObject:HasBuff("Power Word: Fortitude") and HasSpell("Power Word: Fortitude")) then
				if (script_follow:moveInLineOfSight(script_follow.PetObject)) then return true; end -- move to member
				if (Buff("Power Word: Fortitude", script_follow.PetObject)) then
					return true;
				end
			end	
		end
	
	end -- Primeira
	return false;
end -- function

