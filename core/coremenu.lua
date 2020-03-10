coremenu = {
	--Setup
	isSetup = false,
}

function coremenu:reload()
	self.isSetup = false;
	coremenu:draw();
end

function coremenu:coreloadclass()
		-- add to core menu
		local class = UnitClass("player");
		
		if (class == 'Mage') then
			LoadScript("Frostbite - Mage", "scripts\\combat\\script_mage_frostbite.lua");
			AddScriptToCombat("Frostbite - Mage", "script_mage");
			
		elseif (class == 'Hunter') then
			LoadScript("Beastmaster - Hunter", "scripts\\combat\\script_hunter_beastmaster.lua");
			AddScriptToCombat("Beastmaster - Hunter", "script_hunter");
			
		elseif (class == 'Warlock') then
			LoadScript("Shadowmaster - Warlock", "scripts\\combat\\script_warlock_shadowmaster.lua");
			AddScriptToCombat("Shadowmaster - Warlock", "script_warlock");
			
		elseif (class == 'Paladin') then
			LoadScript("Ret - Paladin", "scripts\\combat\\script_paladin_ret.lua");
			AddScriptToCombat("Ret - Paladin", "script_paladin");
			
		elseif (class == 'Druid') then
			LoadScript("Feral - Druid", "scripts\\combat\\script_druid_feral.lua");
			AddScriptToCombat("Feral - Druid", "script_druid");
			
		elseif (class == 'Priest') then
			-- Discipline
			LoadScript("Disc - Priest", "scripts\\combat\\script_priest_disc.lua");
			AddScriptToCombat("Disc - Priest", "script_priest");
			-- Shadow
			LoadScript("Shadow - Priest", "scripts\\combat\\script_priest_shadow.lua");
			AddScriptToCombat("Shadow - Priest", "script_priest_shadow");
			
		elseif (class == 'Warrior') then
			LoadScript("Fury - Warrior", "scripts\\combat\\script_warrior_fury.lua");
			AddScriptToCombat("Fury - Warrior", "script_warrior");
			
		elseif (class == 'Rogue') then
			LoadScript("Hidden - Rogue", "scripts\\combat\\script_rogue_hidden.lua");
			AddScriptToCombat("Hidden - Rogue", "script_rogue");
			
		elseif (class == 'Shaman') then
			LoadScript("Enhance - Shaman", "scripts\\combat\\script_shaman_enhance.lua");
			AddScriptToCombat("Enhance - Shaman", "script_shaman");
	end

end	

function coremenu:loadclass()
	-- Load combat menu by class
	local class = UnitClass("player");
		if (class == 'Mage') then
			script_mage:menu();
		elseif (class == 'Hunter') then
			script_hunter:menu();
		elseif (class == 'Warlock') then
			script_warlock:menu();
		elseif (class == 'Paladin') then
			script_paladin:menu();
		elseif (class == 'Druid') then
			script_druid:menu();
		elseif (class == 'Priest') then
			script_priest:menu();
			script_priest_shadow:menu();
		elseif (class == 'Warrior') then
			script_warrior:menu();
		elseif (class == 'Rogue') then
			script_rogue:menu();
		elseif (class == 'Shaman') then
			script_shaman:menu();
	end
end

function coremenu:draw()

	if (self.isSetup == false) then
		
		self.isSetup = true;
		
		DEFAULT_CHAT_FRAME:AddMessage('Loading Scripts!');
		
		--[[
			----------------------------
			Core Files
			----------------------------
		]]--
		
		include("core\\core.lua");	
        
		-- Load DBs
		include("scripts\\db\\vendorDB.lua");
		include("scripts\\db\\hotspotDB.lua");
		include("scripts\\sig\\sig_global_vars.lua");


		--[[
			----------------------------
			Class Rotations
			----------------------------
		]]--
		
		coremenu:coreloadclass();

		--[[
			----------------------------
			Bot Types
			----------------------------
		]]--
	
		LoadScript("Grinder", "scripts\\script_grind.lua");
		AddScriptToMode("Grinder", "script_grind");

		LoadScript("Follower", "scripts\\script_follow.lua");
		AddScriptToMode("Follower", "script_follow");
		
		LoadScript("Follower OP", "scripts\\script_followOP.lua");
		AddScriptToMode("Follow Out of Party", "script_followOP");

		LoadScript("Rotation", "scripts\\script_rotation.lua");
		AddScriptToMode("Rotation", "script_rotation");

		LoadScript("Fishing", "scripts\\script_fish.lua");
		AddScriptToMode("Fishing", "script_fish");

		-- Nav Mesh Runner by Rot, Improved by Logitech
		LoadScript("Runner", "scripts\\script_runner.lua");
		AddScriptToMode("Runner", "script_runner");

		LoadScript("Unstuck Test", "scripts\\script_unstuck.lua");
		AddScriptToMode("Unstuck Test", "script_unstuck");

		LoadScript("Pather", "scripts\\script_pather.lua");
		AddScriptToMode("Pather Debug", "script_pather");
		
		--[[
			----------------------------
			Override Settings
			----------------------------
		]]--
	
		DrawPath(true);
		
		--NewTheme(false);
		
	end

	--[[
		----------------------------
		Append To Menu
		----------------------------
	]]--

	-- Grind 
	Separator();
	if (CollapsingHeader("[Grind options")) then
		script_grindMenu:menu();
	end

	if (CollapsingHeader("[Follower options")) then
		script_followEX:menu();
	end

	if (CollapsingHeader("[Fishing options")) then
		script_fish:menu();
	end
	
	Separator();

	-- Add Combat scripts menus
	if (CollapsingHeader("[Combat options")) then
		coremenu:loadclass();
	end
	
end