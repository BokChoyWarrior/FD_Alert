-- FD Alert
-- by Intermission, Avast Guild, Frostmourne-US Server
-- with help from Nightblade
-- version 1.1.3
-- 14/08/2008
-- http://www.wowinterface.com/downloads/info10329-FDAlert.html

-- Modified by CGN to track resists/tries per fight

local chat_prefix = "FD Alert: "
local colour = "|cffffff7f"

local GetTime = _G.GetTime
local fd_spell_string = _G.GetSpellInfo(5384)
local fd_primed = 0
-- Resists = [Resists, Tries]
local fd_outcomes = {resists = 0, tries = 0}
local consecutive_resists = 0

local fda_sounds = {}
fda_sounds[1] = "Sound\\Creature\\Mortar Team\\MortarTeamPissed9.wav"
fda_sounds[2] = "Sound\\Creature\\Sporeling\\SporelingDeath.wav"
fda_sounds[3] = "Sound\\Creature\\Voidwalker_VoidWraith\\Voidwalker_VoidWraithAggro.wav"
fda_sounds[4] = "Sound\\Effects\\DeathImpacts\\mDeathImpactColossalSnowA.wav"
fda_sounds[5] = "Sound\\Effects\\DeathImpacts\\mDeathImpactLargeWoodA.wav"
fda_sounds[6] = "Sound\\Item\\Weapons\\Mace1HMetal\\1hMaceMetalHitChainCrit.wav"
fda_sounds[7] = "Sound\\Item\\Weapons\\ParrySounds\\1hParryMetalHitMetalCritical.wav"
fda_sounds[8] = "Sound\\Creature\\Abomination\\AbominationPissed5.wav"
fda_sounds[9] = "Sound\\Doodad\\BellTollHorde.wav"
fda_sounds[10] = "Sound\\Doodad\\BellTollAlliance.wav"

function fda_Defaults()
	local default_prefs = {
		enabled = "on",
		message = "My Feign Death RESISTED!",
		channel = "SAY",
		whispermessage = "my fd broke, halp",
		whispertarget = "0",
		sound = "Sound\\Doodad\\BellTollAlliance.wav",
		tally = "on",
		debug = "off"
		}
	return default_prefs
end

function fda_OnLoad()
	this:RegisterEvent("UI_ERROR_MESSAGE")
	this:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	this:RegisterEvent("VARIABLES_LOADED")

	-- V CGN V --
	this:RegisterEvent("UNIT_SPELLCAST_SENT")
	this:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	this:RegisterEvent("PLAYER_REGEN_ENABLED")
	-- ^ CGN ^ --

	SlashCmdList["FDALERT"] = function(msg) fda_OnSlash(msg) end
	SLASH_FDALERT1 = "/fdalert"
	SLASH_FDALERT2 = "/fda"

	if not fdalert_Prefs then
		fdalert_Prefs = fda_Defaults()
	end

	-- added by CGN v v v v
	-- Ideally we wouldnt have to do this, but the creator decided to raw get values from the fda_Prefs 
	-- rather than use a getter func that can set defaults if not existing :( 

	-- Check current saved values and fill in missing with defaults, because the user may have uypdated to a version with extra saved vars
	local default_prefs = fda_Defaults()
	for k, v in pairs(default_prefs) do
		if fdalert_Prefs[k] == nil then
			fdalert_Prefs[k] = v
		end
	end
end

function fda_print(msg)
	DEFAULT_CHAT_FRAME:AddMessage( colour .. chat_prefix .. "|r" .. msg );
end

function fda_debug_print(msg)
	if fdalert_Prefs.debug == "on" then
		DEFAULT_CHAT_FRAME:AddMessage( colour .. "FDA DEBUG: " .. "|r" .. msg );
	end
end

function fda_OnSlash(msg)
	if (not msg or msg == "") then
		fda_print("commands:")
		fda_print("/fda help    -- detailed help")
		fda_print("/fda enable")
		fda_print("/fda message <message>")
		fda_print("/fda chan <channel>")
		fda_print("/fda wm <whisper message>")
		fda_print("/fda wt <name>")
		fda_print("/fda sound <number 1-10>")
		fda_print("/fda tally")
		fda_print("/fda test")
		fda_print("/fda status")
		fda_print("/fda reset")
	elseif(msg == "help") then
		fda_ShowHelp()
	elseif(msg == "enable") then
		fda_EnableToggle()
	elseif(strsub(msg, 1, 5) == "sound") then
		fda_SoundSet(msg)
	elseif(strsub(msg, 1, 7) == "message") then
		fda_MessageSet(msg)
	elseif(strsub(msg, 1, 4) == "chan") then
		fda_ChannelSet(msg)
	elseif(strsub(msg, 1, 2) == "wm") then
		fda_WMessageSet(msg)
	elseif(strsub(msg, 1, 2) == "wt") then
		fda_WTargetSet(msg)
	elseif(msg == "status") then
		fda_Status()
	elseif(msg == "test") then
		fda_Test()
	elseif(msg == "reset" or msg == "default") then
		fda_ResetSettings()
	elseif(msg == "tally") then
		fda_TallyToggle()
	elseif(msg == "debug") then
		fda_DebugToggle()
	else
		fda_print("unknown option '" .. msg .. "' -- type '/fda' for help")
	end
end

-- v Functions added by CGN v --
local wait_table = {};
local wait_frame = nil;

function fda_Wait(delay,func, ...)
	-- if(type(delay)~="number" or type(func)~="function") then
	-- ThreatLib:Debug("delay false!")
	-- return false;
	-- end
	if(wait_frame == nil) then
		wait_frame = CreateFrame("Frame","wait_frame", UIParent);
		wait_frame:SetScript("onUpdate",function (self,elapse)
			local count = #wait_table;
			local i = 1;
			while(i<=count) do
				local waitRecord = tremove(wait_table,i);
				local d = tremove(waitRecord,1);
				local f = tremove(waitRecord,1);
				local p = tremove(waitRecord,1);
				if(d>elapse) then
					tinsert(wait_table,i,{d-elapse,f,p});
					i = i + 1;
				else
					count = count - 1;
					f(unpack(p));
				end
			end
		end);
	end
	tinsert(wait_table,{delay,func,{...}});
	return true;
end

function fda_TryReset()
	if GetTime() - fd_primed < 5 then
		fda_debug_print("FD Success")
		fd_primed = 0
		consecutive_resists = 0
	else
		fda_debug_print("FD must have resisted")
	end
end

function fda_OnEvent()
	if event == "VARIABLES_LOADED" then
		if not fdalert_Prefs then
			fdalert_Prefs = fda_Defaults()
		end
	end
	if(event == "UI_ERROR_MESSAGE") then
		-- one of the next two lines should be commented out.
		if(arg1 == ERR_FEIGN_DEATH_RESISTED) then
		-- if(arg1 == INTERRUPTED or arg1 == ERR_FEIGN_DEATH_RESISTED) then      -- for easy testing using dismiss pet + moving
			-- v CGN v --
			fd_outcomes.resists = fd_outcomes.resists + 1
			consecutive_resists = consecutive_resists + 1
			fd_primed = 0
			fda_debug_print(tostring(consecutive_resists) .. " " .. tostring(fd_outcomes.resists))
			-- ^ CGN ^ --
			if(tostring(fdalert_Prefs.enabled) ==  "on") then
				fda_SoundAlert()
				fda_SendMessages()
			end
		end
	end
	-- v added by CGN v --
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		-- fda_debug_print("1:" .. tostring(arg1) .. " 2:" .. tostring(arg2) .. " 3:" .. tostring(arg3) .. " 4:" .. tostring(arg4) .. " 5:" .. tostring(arg5))
		if arg1 == "player" and arg2 == fd_spell_string then
			fd_outcomes.tries = fd_outcomes.tries + 1
			fda_Wait(0.5, fda_TryReset, self)
		end
	end
	if event == "UNIT_SPELLCAST_SENT" then
		if arg1 == "player" and arg2 == fd_spell_string then
			fd_primed = GetTime()
		end
	end
	if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_DEAD" then
		local tries, resists, consecutive = tostring(fd_outcomes.tries), tostring(fd_outcomes.resists), tostring(consecutive_resists)
		fda_debug_print("Resists: " .. resists)
		fda_debug_print("Tries:" .. tries)
		fda_debug_print("Consecutive:" .. consecutive)
		if tries == "0" or fdalert_Prefs.tally ~= "on" then
			return
		else
			local percent = tostring(math.floor(((resists/tries) * 100)))
			fda_print("Resists/Tries: "..resists.."/"..tries.." - ("..percent.."%)")
		end
		fd_outcomes.tries, fd_outcomes.resists, consecutive_resists = 0, 0, 0
	end
end

function fda_BuildChatMessage()
	local msg = fdalert_Prefs.message
	if fdalert_Prefs.tally == "on" then
		if consecutive_resists > 1 then
			msg = msg .. " (" .. tostring(consecutive_resists) .. " in a row)"
		end
	end
	return msg
end

function fda_Test()
	if(tostring(fdalert_Prefs.enabled) ==  "on") then
		fda_SoundAlert()
		fda_SendMessages()
	end
end

function fda_SoundAlert()
	if(tostring(fdalert_Prefs.sound) ~= "0") then
		PlaySoundFile(tostring(fdalert_Prefs.sound));
	end
end

function fda_SendMessages()
	msg = fda_BuildChatMessage()
	local channelwork = tostring(fdalert_Prefs.channel)
	if(channelwork == "1" or channelwork == "2" or channelwork == "3" or channelwork == "4" or channelwork == "5" or channelwork == "6" or channelwork == "7" or channelwork == "8" or channelwork == "9") then
		SendChatMessage(msg, "CHANNEL", nil, tostring(fdalert_Prefs.channel));
	elseif(channelwork == "0") then
	else
		SendChatMessage(msg, tostring(fdalert_Prefs.channel));
	end
	local whispertargetwork = tostring(fdalert_Prefs.whispertarget)
	if(whispertargetwork ~= "0") then
		SendChatMessage(tostring(fdalert_Prefs.whispermessage), "WHISPER", nil, tostring(fdalert_Prefs.whispertarget));
	end
end

function fda_EnableToggle()
	if(fdalert_Prefs.enabled == "off") then
		fda_print("addon enabled");
		fdalert_Prefs.enabled = "on";
  return
  else
		fda_print("addon disabled");
  	fdalert_Prefs.enabled = "off";
  end
end

function fda_MessageSet(msg)
	fda_print("message changed to: " .. strsub(msg, 9));
	fdalert_Prefs.message = strsub(msg, 9);
end

function fda_SoundSet(msg)
	local sound_number = strsub(msg, 7)
	if(strsub(msg, 7) == "1") then
		fdalert_Prefs.sound = "Sound\\Creature\\Mortar Team\\MortarTeamPissed9.wav"
		fda_print("sound file changed to: " .. strsub(msg, 7));
		fda_SoundAlert()
	elseif(strsub(msg, 7) == "2") then
		fdalert_Prefs.sound = "Sound\\Creature\\Sporeling\\SporelingDeath.wav"
		fda_print("sound file changed to: " .. strsub(msg, 7));
		fda_SoundAlert()
	elseif(strsub(msg, 7) == "3") then
		fdalert_Prefs.sound = "Sound\\Creature\\Voidwalker_VoidWraith\\Voidwalker_VoidWraithAggro.wav"
		fda_print("sound file changed to: " .. strsub(msg, 7));
		fda_SoundAlert()
	elseif(strsub(msg, 7) == "4") then
		fdalert_Prefs.sound = "Sound\\Effects\\DeathImpacts\\mDeathImpactColossalSnowA.wav"
		fda_print("sound file changed to: " .. strsub(msg, 7));
		fda_SoundAlert()
	elseif(strsub(msg, 7) == "5") then
		fdalert_Prefs.sound = "Sound\\Effects\\DeathImpacts\\mDeathImpactLargeWoodA.wav"
		fda_print("sound file changed to: " .. strsub(msg, 7));
		fda_SoundAlert()
	elseif(strsub(msg, 7) == "6") then
		fdalert_Prefs.sound = "Sound\\Item\\Weapons\\Mace1HMetal\\1hMaceMetalHitChainCrit.wav"
		fda_print("sound file changed to: " .. strsub(msg, 7));
		fda_SoundAlert()
	elseif(strsub(msg, 7) == "7") then
		fdalert_Prefs.sound = "Sound\\Item\\Weapons\\ParrySounds\\1hParryMetalHitMetalCritical.wav"
		fda_print("sound file changed to: " .. strsub(msg, 7));
		fda_SoundAlert()
	elseif(strsub(msg, 7) == "8") then
		fdalert_Prefs.sound = "Sound\\Creature\\Abomination\\AbominationPissed5.wav"
		fda_print("sound file changed to: " .. strsub(msg, 7));
		fda_SoundAlert()
	elseif(strsub(msg, 7) == "9") then
		fdalert_Prefs.sound = "Sound\\Doodad\\BellTollHorde.wav"
		fda_print("sound file changed to: " .. strsub(msg, 7));
		fda_SoundAlert()
	elseif(strsub(msg, 7) == "10") then
		fdalert_Prefs.sound = "Sound\\Doodad\\BellTollAlliance.wav"
		fda_print("sound file changed to: " .. strsub(msg, 7));
		fda_SoundAlert()
	elseif(strsub(msg, 7) == "0" or strsub(msg, 7) == "off" or strsub(msg, 7) == "disable") then
		fdalert_Prefs.sound = "0"
		fda_print("sound turned off");
	else
		fda_print("'" .. strsub(msg, 7).. "' not recognised. Valid choices are 1 to 10, or 0 for off.")
	end
end

function fda_ChannelSet(msg)
	if(strsub(msg, 6) == "say" or strsub(msg, 6) == "yell" or strsub(msg, 6) == "emote" or strsub(msg, 6) == "party" or strsub(msg, 6) == "guild" or strsub(msg, 6) == "officer" or strsub(msg, 6) == "raid" or strsub(msg, 6) == "raid_warning" or strsub(msg, 6) == "1" or strsub(msg, 6) == "2" or strsub(msg, 6) == "3" or strsub(msg, 6) == "4" or strsub(msg, 6) == "5" or strsub(msg, 6) == "6" or strsub(msg, 6) == "7" or strsub(msg, 6) == "8" or strsub(msg, 6) == "9" or strsub(msg, 6) == "0") then
		fda_print("channel changed to: " .. strsub(msg, 6));
		fdalert_Prefs.channel = string.upper((strsub(msg, 6)));
  	return
  else
  	fda_print("'" .. msg .. "' is not a valid channel name or number. Valid channels are:");
  	fda_print("say, emote, yell, party, raid, raid_warning, guild, officer, 1-9. '0' to disable the message.");
  	return
  end
end

function fda_WMessageSet(msg)
	fda_print("whisper message changed to: " .. strsub(msg, 4));
	fdalert_Prefs.whispermessage = strsub(msg, 4);
  return
end

function fda_WTargetSet(msg)
	fda_print("whisper target changed to: " .. strsub(msg, 4));
	fdalert_Prefs.whispertarget = strsub(msg, 4);
  return
end

-- v CGN v --
function fda_TallyToggle()
	if (fdalert_Prefs.tally == "off") then
		fda_print("tallying enabled");
		fdalert_Prefs.tally = "on";
		return
	else
		  fda_print("tally disabled");
		fdalert_Prefs.tally = "off";
	end
end

function fda_DebugToggle()
	if (fdalert_Prefs.debug == "off") then
		fdalert_Prefs.debug = "on";
		fda_debug_print("debug enabled");
		return
	else
		fda_print("debug disabled");
		fdalert_Prefs.debug = "off";
	end
end
-- ^ CGN ^ --

function fda_Status()
	fda_print("current mod settings:");
	fda_print("/fda enable = " .. tostring(fdalert_Prefs.enabled));
	fda_print("/fda message = " .. tostring(fdalert_Prefs.message));
	fda_print("/fda chan = " .. string.lower(tostring(fdalert_Prefs.channel)));
	fda_print("/fda wm = " .. tostring(fdalert_Prefs.whispermessage));
	fda_print("/fda wt = " .. tostring(fdalert_Prefs.whispertarget));
	fda_print("/fda sound = " .. tostring(fdalert_Prefs.sound));
	fda_print("/fda tally = " .. tostring(fdalert_Prefs.tally));
end

function fda_ShowHelp()
	fda_print("help:")
	fda_print("/fda help  = brings up this help list")
	fda_print("/fda enable  = toggles the mod on/off")
	fda_print("/fda message <message>  = sets the message that will be sent to the channel")
	fda_print("/fda chan <channel>  = sets the channel that the message will be sent to. Valid chat channels: say, emote, yell, party, raid, raid_warning, guild, officer, and the channel numbers 1 to 9. Set to '0' to disable channel messages.")
	fda_print("/fda wm <whisper message>  = sets the message that will be sent in whispers")
	fda_print("/fda wt <name>  = sets the target for the whisper. Set to '0' to disable whisper messages.")
	fda_print("/fda sound <number>  = selects a sound. Valid choices are 1-10. Set to '0' to disable sound.")
	fda_print("/fda tally  = Changes whether FDA will tally your resists.")
	fda_print("/fda test  = simulates an FD resist based on your current settings")
	fda_print("/fda status  = displays your current FD Alert configuration")
	fda_print("/fda reset  = resets all settings back to their default state")
end

function fda_ResetSettings()
	fda_print("settings have been reset to default values, type '/fda status' to check settings");
	fda_Defaults()
end
