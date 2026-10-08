-- Proving Grounds Quickstart - ready screen skip for the game script instance
-- This script is hooked to lib/states/ingamewaitingforplayers.lua and therefore
-- runs in the exact script instance that will execute IngameWaitingForPlayersState
-- ("game" instance, not the main menu instance). The menu instance writes a
-- marker file right before load_level; we pick it up in at_enter, so only a
-- quick launch is affected and normal heists are never touched.

local MARKER_FILE = "mods/saves/pgqs_pending_auto_enter.dat"

local function pgqs_log(msg)
	log("[PGQS] " .. tostring(msg))
end

pgqs_log("states script loaded (IngameWaitingForPlayersState=" .. tostring(IngameWaitingForPlayersState) .. ")")

local function consume_marker()
	local f = io.open(MARKER_FILE, "r")
	if not f then
		return false
	end

	local content = f:read("*a")
	f:close()

	-- consume the marker so it cannot skip a later heist (io.remove/os.remove
	-- are not available in PAYDAY 2, so truncate to empty instead)
	local w = io.open(MARKER_FILE, "w")
	if w then
		w:close()
	end

	return content ~= nil and content ~= ""
end

if IngameWaitingForPlayersState then
	Hooks:PostHook(IngameWaitingForPlayersState, "at_enter", "ProvingGrounds_Quickstart_AutoEnter", function(self)
		if not consume_marker() then
			return
		end

		pgqs_log("at_enter fired, skipping ready screen")
		self:start_game_intro()
	end)
end