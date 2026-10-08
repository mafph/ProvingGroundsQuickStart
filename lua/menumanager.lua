-- Proving Grounds Quickstart – sauberer Start

local LEVEL_ID = "modders_devmap"
local JOB_ID   = "modders_devmap"

local auto_start_requested = false
local auto_start_hook_registered = false

Hooks:Add("MenuManagerBuildCustomMenus", "ProvingGrounds_Quickstart_BuildMenu", function(menu_manager, nodes)
	if not nodes.main then
		return
	end

	local params = {
		name = "proving_grounds_quickstart",
		text_id = "Proving Grounds",
		localize = false,
		callback = "start_proving_grounds",
		font = tweak_data.menu.pd2_large_font,
		font_size = 35
	}

	local data_node = {}
	local new_item = nodes.main:create_item(data_node, params)
	nodes.main:insert_item(new_item, 3)
end)

function MenuCallbackHandler:start_proving_grounds()
	-- Level vorhanden?
	if not tweak_data.levels[LEVEL_ID] then
		managers.menu:show_error_dialog({
			title = "Proving Grounds",
			text = "Level 'modders_devmap' wurde nicht gefunden.\nIst die Map korrekt im Ordner /maps und BeardLib aktiv?"
		})
		return
	end

	-- Alten Job sauber beenden
	managers.job:deactivate_current_job()

	-- Job aktivieren (Narrative + Chain aus der main.xml)
	local ok = managers.job:activate_job(JOB_ID)
	if not ok then
		managers.menu:show_error_dialog({
			title = "Proving Grounds",
			text = "Job 'modders_devmap' konnte nicht aktiviert werden."
		})
		return
	end

	-- Game Settings vollständig setzen
	Global.game_settings.single_player = true
	Global.game_settings.team_ai = true
	Global.game_settings.team_ai_option = math.min(Global.game_settings.team_ai_option or 1, 1)
	Global.game_settings.permission = "private"
	Global.game_settings.drop_in_allowed = false
	Global.game_settings.level_id = LEVEL_ID
	Global.game_settings.mission = managers.job:current_mission() or "none"
	Global.game_settings.world_setting = managers.job:current_world_setting()
	Global.game_settings.difficulty = "normal"
	Global.game_settings.one_down = false
	Global.game_settings.weekly_skirmish = false

	-- Sicherstellen, dass current_level_id stimmt
	if managers.job:current_level_id() ~= LEVEL_ID then
		-- Fallback falls die Chain nicht greift
		managers.job._global.current_job.current_stage = 1
	end

	-- Netzwerk hosten
	managers.network:host_game()
	Network:set_server()

	-- mission "none" -> nil, wie Vanilla start_the_game es macht
	local mission = Global.game_settings.mission ~= "none" and Global.game_settings.mission or nil

	-- Ready-Screen nur beim ersten Start ueberspringen
	auto_start_requested = true

	if not auto_start_hook_registered then
		auto_start_hook_registered = true
		Hooks:PostHook(IngameWaitingForPlayersState, "at_enter", "ProvingGroundsQuickstartAutoStart", function(self)
			if auto_start_requested then
				auto_start_requested = false
				-- skips the ready/loading menu (Verhalten des -auto_enter_level Arguments)
				self:start_game_intro()
			end
		end)
	end

	-- Level-Daten holen
	local level_data = tweak_data.levels[LEVEL_ID]
	local world_name = level_data and level_data.world_name or LEVEL_ID

	-- Direkt laden (umgeht den fehlerhaften Teil in start_single_player_job)
	local session = managers.network:session()
	if session then
		session:load_level(
			world_name,
			mission,
			Global.game_settings.world_setting,
			nil,
			LEVEL_ID
		)
	else
		managers.menu:show_error_dialog({
			title = "Proving Grounds",
			text = "Netzwerk-Session konnte nicht erstellt werden."
		})
	end
end