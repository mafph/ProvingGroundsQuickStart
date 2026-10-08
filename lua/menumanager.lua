-- Proving Grounds Quickstart - selected map quick launch + clean start

local DEFAULT_LEVEL_ID = "modders_devmap"

local auto_start_requested = false
local auto_start_hook_registered = false

local function error_dialog(text)
	managers.menu:show_error_dialog({ title = managers.localization:text("pg_quicklaunch"), text = text })
end

Hooks:Add("MenuManagerBuildCustomMenus", "ProvingGrounds_Quickstart_BuildMenu", function(menu_manager, nodes)
	if not nodes.main then
		return
	end

	-- Show the selected map as the button label
	local s = mod_settings() or {}
	local job_id = s.level or DEFAULT_LEVEL_ID
	local job = tweak_data.narrative.jobs[job_id]
	local map_name = (job and job.name_id and managers.localization:text(job.name_id)) or job_id

	local params = {
		name = "proving_grounds_quickstart",
		text_id = managers.localization:text("pg_quicklaunch") .. ": " .. map_name,
		localize = false,
		callback = "start_proving_grounds",
		font = tweak_data.menu.pd2_large_font,
		font_size = 35
	}

	nodes.main:insert_item(nodes.main:create_item({}, params), 3)
end)

function MenuCallbackHandler:start_proving_grounds()
	local s = mod_settings() or {}
	local job_id = s.level or DEFAULT_LEVEL_ID

	-- Validate job, level and settings
	if not tweak_data.narrative.jobs[job_id] then
		error_dialog(managers.localization:text("pg_error_job_missing") .. "\n'" .. tostring(job_id) .. "'")
		return
	end

	managers.job:deactivate_current_job()

	if not managers.job:activate_job(job_id, 1) then
		error_dialog(managers.localization:text("pg_error_job_activate") .. "\n'" .. tostring(job_id) .. "'")
		return
	end

	local level_id = managers.job:current_level_id()
	if not level_id or not tweak_data.levels[level_id] then
		error_dialog(managers.localization:text("pg_error_level_missing") .. "\n'" .. tostring(job_id) .. "'")
		return
	end

	-- Apply game settings (defaults match the previous behaviour)
	Global.game_settings.single_player = not s.online
	Global.game_settings.team_ai = s.team_ai ~= false
	Global.game_settings.team_ai_option = s.team_ai ~= false and 1 or 0
	Global.game_settings.permission = s.online and "public" or "private"
	Global.game_settings.drop_in_allowed = s.online
	Global.game_settings.level_id = level_id
	Global.game_settings.mission = managers.job:current_mission() or "none"
	Global.game_settings.world_setting = managers.job:current_world_setting()
	Global.game_settings.difficulty = s.difficulty or "normal"
	Global.game_settings.one_down = s.one_down or false
	Global.game_settings.weekly_skirmish = false

	managers.network:host_game()
	Network:set_server()

	-- mission "none" -> nil (as vanilla start_the_game does)
	local mission = Global.game_settings.mission ~= "none" and Global.game_settings.mission or nil

	-- Skip the ready screen on first start only
	if s.skip_ready ~= false then
		auto_start_requested = true
	end

	if not auto_start_hook_registered then
		auto_start_hook_registered = true
		Hooks:PostHook(IngameWaitingForPlayersState, "at_enter", "ProvingGroundsQuickstartAutoStart", function(self)
			if auto_start_requested then
				auto_start_requested = false
				-- skips the ready/loading menu (equivalent to the -auto_enter_level argument)
				self:start_game_intro()
			end
		end)
	end

	-- Load directly, bypassing the broken part in start_single_player_job
	local session = managers.network:session()
	if session then
		local level_data = tweak_data.levels[level_id]
		session:load_level(
			level_data and level_data.world_name or level_id,
			mission,
			Global.game_settings.world_setting,
			nil,
			level_id
		)
	else
		error_dialog(managers.localization:text("pg_error_no_session"))
	end
end