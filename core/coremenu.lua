coremenu = {
	--Setup
	isSetup = false,
}

function coremenu:reload()
	self.isSetup = false;
	coremenu:draw();
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
		include("scripts\\sig\\sig_scripts.lua");


		--[[
			----------------------------
			Class Rotations
			----------------------------
		]]--
		
		sig_scripts:coreloadclass();

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
		sig_scripts:loadclass();
	end
	
end