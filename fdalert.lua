-- FD Alert
-- by CGN, Netherwing-Atlantiss https://github.com/BokChoyWarrior
-- version 2.0.0
-- 09/05/2021

local player_name = _G.UnitName("player")
local colour = "|cffffff7f"
local GetTime = _G.GetTime
local fd_spell_string = _G.GetSpellInfo(5384)
local fd_primed = 0
local fd_outcomes = {resists = 0, tries = 0}
local consecutive_resists = 0

local sounds = {}
sounds[1] = "Sound/Creature/Mortar Team/MortarTeamPissed9.wav"
sounds[2] = "Sound/Creature/Sporeling/SporelingDeath.wav"
sounds[3] = "Sound/Creature/Voidwalker_VoidWraith/Voidwalker_VoidWraithAggro.wav"
sounds[4] = "Sound/Effects/DeathImpacts/mDeathImpactColossalSnowA.wav"
sounds[5] = "Sound/Effects/DeathImpacts/mDeathImpactLargeWoodA.wav"
sounds[6] = "Sound/Item/Weapons/Mace1HMetal/1hMaceMetalHitChainCrit.wav"
sounds[7] = "Sound/Item/Weapons/ParrySounds/1hParryMetalHitMetalCritical.wav"
sounds[8] = "Sound/Creature/Abomination/AbominationPissed5.wav"
sounds[9] = "Sound/Doodad/BellTollHorde.wav"
sounds[10] = "Sound/Doodad/BellTollAlliance.wav"

function fda_Defaults()
	local default_prefs = {
		enabled = "on",
		message = "%p's feign death RESISTED!",
		channel = "SAY",
		sound = "Sound/Doodad/BellTollAlliance.wav",
		tally = "on",
		debug = "off"
		}
	return default_prefs
end

function fda_OnLoad()
	this:RegisterEvent("UI_ERROR_MESSAGE")
	this:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("UNIT_SPELLCAST_SENT")
	this:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	this:RegisterEvent("PLAYER_REGEN_ENABLED")

	SlashCmdList["FDALERT"] = function(msg) fda_OnSlash(msg) end
	SLASH_FDALERT1 = "/fdalert"
	SLASH_FDALERT2 = "/fda"

	if not fdalert_Prefs then
		fda_ResetSettings()
	end

	-- Check current saved values and fill in missing with defaults, because the user may have uypdated to a version with extra saved vars
	local default_prefs = fda_Defaults()
	for k, v in pairs(default_prefs) do
		if fdalert_Prefs[k] == nil then
			fdalert_Prefs[k] = v
		end
	end
end

function fda_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage( colour .. "FD Alert: " .. "|r" .. msg )
end

function fda_DebugPrint(msg)
	if fdalert_Prefs.debug == "on" then
		DEFAULT_CHAT_FRAME:AddMessage( colour .. "FDA DEBUG: " .. "|r" .. msg )
	end
end

function fda_OnSlash(msg)
	if (not msg or msg == "") then
		fda_Print("Commands:")
		fda_Print("/fda help -- detailed help")
		fda_Print("/fda enable")
		fda_Print("/fda message <message>")
		fda_Print("/fda channel <channel>")
		fda_Print("/fda sound <number 1-10>")
		fda_Print("/fda tally")
		fda_Print("/fda test")
		fda_Print("/fda status")
		fda_Print("/fda reset")
	elseif(msg == "help") then
		fda_ShowHelp()
	elseif(msg == "enable") then
		fda_EnableToggle()
	elseif(strsub(msg, 1, 5) == "sound") then
		fda_SetSound(msg)
	elseif(strsub(msg, 1, 7) == "message") then
		fda_SetMessage(msg)
	elseif(strsub(msg, 1, 7) == "channel") then
		fda_SetChannel(strsub(msg, 9))
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
		fda_Print("unknown option '" .. msg .. "' -- type '/fda help' for help")
	end
end

-- v Functions added by CGN v --
local wait_table = {}
local wait_frame = nil

function fda_Wait(delay,func, ...)
	if(wait_frame == nil) then
		wait_frame = CreateFrame("Frame","wait_frame", UIParent)
		wait_frame:SetScript("onUpdate",function (self,elapse)
			local count = #wait_table
			local i = 1
			while(i<=count) do
				local waitRecord = tremove(wait_table,i)
				local d = tremove(waitRecord,1)
				local f = tremove(waitRecord,1)
				local p = tremove(waitRecord,1)
				if(d>elapse) then
					tinsert(wait_table,i,{d-elapse,f,p})
					i = i + 1
				else
					count = count - 1
					f(unpack(p))
				end
			end
		end)
	end
	tinsert(wait_table,{delay,func,{...}})
	return true
end

function fda_TryReset()
	if GetTime() - fd_primed < 5 then
		fda_DebugPrint("FD success")
		fd_primed = 0
		consecutive_resists = 0
	else
		fda_DebugPrint("FD resisted")
	end
end

function fda_OnEvent()
	if event == "VARIABLES_LOADED" then
		if not fdalert_Prefs then
			fdalert_Prefs = fda_Defaults()
		end
	end
	if event == "UI_ERROR_MESSAGE" then
		-- one of the next two lines should be commented out.
		if arg1 == ERR_FEIGN_DEATH_RESISTED then
		-- if(arg1 == INTERRUPTED or arg1 == ERR_FEIGN_DEATH_RESISTED) then      -- for easy testing using dismiss pet + moving
			fd_outcomes.resists = fd_outcomes.resists + 1
			consecutive_resists = consecutive_resists + 1
			fd_primed = 0
			fda_DebugPrint(tostring(consecutive_resists) .. " " .. tostring(fd_outcomes.resists))

			if(tostring(fdalert_Prefs.enabled) ==  "on") then
				fda_SoundAlert()
				fda_SendMessage()
			end
		end
	end
	-- v added by CGN v --
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		-- fda_DebugPrint("1:" .. tostring(arg1) .. " 2:" .. tostring(arg2) .. " 3:" .. tostring(arg3) .. " 4:" .. tostring(arg4) .. " 5:" .. tostring(arg5))
		if arg1 == "player" and arg2 == fd_spell_string then
			fd_outcomes.tries = fd_outcomes.tries + 1
			fda_Wait(0.5, fda_TryReset)
		end
	end
	if event == "UNIT_SPELLCAST_SENT" then
		if arg1 == "player" and arg2 == fd_spell_string then
			fd_primed = GetTime()
		end
	end
	if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_DEAD" then
		local tries, resists, consecutive = tostring(fd_outcomes.tries), tostring(fd_outcomes.resists), tostring(consecutive_resists)
		fda_DebugPrint("Resists: " .. resists)
		fda_DebugPrint("Tries:" .. tries)
		fda_DebugPrint("Consecutive:" .. consecutive)
		if tries == "0" or fdalert_Prefs.tally ~= "on" then
			return
		else
			local percent = tostring(math.floor(((resists/tries) * 100)))
			fda_Print("Resists/Tries: "..resists.."/"..tries.." - ("..percent.."%)")
		end
		fd_outcomes.tries, fd_outcomes.resists, consecutive_resists = 0, 0, 0
	end
end

function fda_BuildChatMessage()
	local msg = fdalert_Prefs.message:gsub("%%p", player_name)
	if fdalert_Prefs.tally == "on" then
		if consecutive_resists > 1 then
			msg = msg .. " (" .. tostring(consecutive_resists) .. " in a row)"
		end
	end
	return msg
end

function fda_Test()
	if fdalert_Prefs.enabled ==  "on" then
		fda_SoundAlert()
		fda_SendMessage()
	end
end

function fda_SoundAlert()
	if fdalert_Prefs.sound ~= "0" then
		PlaySoundFile(tostring(fdalert_Prefs.sound))
	end
end

function fda_SendMessage()
	msg = fda_BuildChatMessage()
	local announce_chanel = fdalert_Prefs.channel
	if announce_chanel == "0" then
		return
	elseif (
		announce_chanel == "1" or
		announce_chanel == "2" or
		announce_chanel == "3" or
		announce_chanel == "4" or
		announce_chanel == "5" or
		announce_chanel == "6" or
		announce_chanel == "7" or
		announce_chanel == "8" or
		announce_chanel == "9"
	) then
		SendChatMessage(msg, "CHANNEL", nil, fdalert_Prefs.channel)
	else
		SendChatMessage(msg, tostring(fdalert_Prefs.channel))
	end
end

function fda_EnableToggle()
	if fdalert_Prefs.enabled == "off" then
		fda_Print("FD Alert enabled")
		fdalert_Prefs.enabled = "on"
  		return
  else
	fda_Print("FD Alert disabled")
  	fdalert_Prefs.enabled = "off"
  end
end

function fda_SetMessage(msg)
	msg = msg:gsub("%%p", player_name)
	fda_Print("Message changed to: `" .. tostring(strsub(msg, 9)) .. "`")
	fdalert_Prefs.message = strsub(msg, 9)
end

function fda_SetSound(msg)
	local sound = strsub(msg, 7)
	local sound_number = tonumber(sound)
	local number_of_sounds = #sounds
	fda_DebugPrint("sound, sound_number, num_of_sounds = " .. tostring(sound) .. " ".. tostring(sound_number) .. " " .. tostring(number_of_sounds))
	if sound == "0" or sound == "off" or sound == "disable" or sound_number == nil then
		fdalert_Prefs.sound = "0"
		fda_Print("Sound turned off")
	elseif sound_number > 0 and sound_number <= number_of_sounds then
		fdalert_Prefs.sound = sounds[sound_number]
		fda_Print("Sound file changed to: " .. fdalert_Prefs.sound)
		fda_SoundAlert()
	else
		fda_Print("'" .. sound .. "' not recognised. Valid choices are 1 to " .. number_of_sounds .. ", or 0 for off.")
	end
end

function fda_SetChannel(given_channel)
	if (
		given_channel == "say" or
		given_channel == "yell" or
		given_channel == "party" or
		given_channel == "raid" or
		given_channel == "raid_warning" or
		given_channel == "1" or
		given_channel == "2" or
		given_channel == "3" or
		given_channel == "4" or
		given_channel == "5" or
		given_channel == "6" or
		given_channel == "7" or
		given_channel == "8" or
		given_channel == "9" or
		given_channel == "0"
	) then
		fda_Print("Channel changed to: " .. given_channel)
		fdalert_Prefs.channel = string.upper(given_channel)
  		return
  	else
		fda_Print("'" .. given_channel .. "' is not a valid channel name or number. Valid channels are:")
		fda_Print("say, yell, party, raid, raid_warning, 1-9. '0' to disable the message.")
  	end
end

function fda_TallyToggle()
	if fdalert_Prefs.tally == "off" then
		fda_Print("tallying enabled")
		fdalert_Prefs.tally = "on"
		return
	else
		  fda_Print("tally disabled")
		fdalert_Prefs.tally = "off"
	end
end

function fda_DebugToggle()
	if fdalert_Prefs.debug == "off" then
		fdalert_Prefs.debug = "on"
		fda_DebugPrint("debug enabled")
		return
	else
		fda_Print("debug disabled")
		fdalert_Prefs.debug = "off"
	end
end

function fda_Status()
	fda_Print("FD Alert settings:")
	fda_Print("/fda enable = " .. tostring(fdalert_Prefs.enabled))
	fda_Print("/fda message = " .. tostring(fdalert_Prefs.message))
	fda_Print("/fda channel = " .. string.lower(tostring(fdalert_Prefs.channel)))
	fda_Print("/fda sound = " .. tostring(fdalert_Prefs.sound))
	fda_Print("/fda tally = " .. tostring(fdalert_Prefs.tally))
end

function fda_ShowHelp()
	fda_Print("/fda  = brings up this help list")
	fda_Print("/fda enable  = Toggle addon on/off")
	fda_Print("/fda message <message>  = Set the message that will be sent to the channel")
	fda_Print("/fda channel <channel>  = Set the channel to send message in. Valid: say, yell, party, raid, raid_warning, and the channel numbers 1 to 9. - '0' to disable.")
	fda_Print("/fda sound <number>  = Select a sound. Valid choices are 1-10. - '0' to disable sound")
	fda_Print("/fda tally  = Change whether FDA will tally your resists")
	fda_Print("/fda test  = Simulate a FD resist based on your current settings")
	fda_Print("/fda status  = Display your current FD Alert configuration")
	fda_Print("/fda reset  = Reset all settings back to their default state")
end

function fda_ResetSettings()
	fda_Print("Settings have been reset to default values, type '/fda status' to check settings")
	fdalert_Prefs = fda_Defaults()
end
