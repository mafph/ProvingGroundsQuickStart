dofile(ModPath .. "lua/settings/core.lua")
local T = _G.ProvingGroundsQuickstartSettings

local MENU = "pg_settings"

Hooks:Add("LocalizationManagerPostInit", "ProvingGroundsQuickstart_loc", function(loc)
	local file = "loc/english.txt"
	local lang = BLT.Localization and BLT.Localization:get_language()
	if lang and lang.language == "de" then
		file = "loc/german.txt"
	end
	loc:load_localization_file(T._path .. file)
end)

local DIFFICULTIES = {
	{ "normal",       "pg_difficulty_normal" },
	{ "hard",         "pg_difficulty_hard" },
	{ "overkill",     "pg_difficulty_very_hard" },
	{ "overkill_145", "pg_difficulty_overkill" },
	{ "easy_wish",    "pg_difficulty_easy_wish" },
	{ "overkill_290", "pg_difficulty_death_wish" },
	{ "sm_wish",      "pg_difficulty_sm_wish" }
}
local DIFFICULTY_IDS = {}
local DIFFICULTY_KEYS = {}
for _, d in ipairs(DIFFICULTIES) do
	table.insert(DIFFICULTY_IDS, d[1])
	table.insert(DIFFICULTY_KEYS, d[2])
end

local function level_list()
	local list = {}
	for job_id, job in pairs(tweak_data.narrative.jobs or {}) do
		if type(job) == "table" and job.chain then
			local name = job.name_id and managers.localization:text(job.name_id) or job_id
			table.insert(list, { id = job_id, name = name })
		end
	end
	table.sort(list, function(a, b)
		return a.name < b.name
	end)
	local ids, items = {}, {}
	for _, entry in ipairs(list) do
		table.insert(ids, entry.id)
		table.insert(items, entry.name)
	end
	return ids, items
end

local function refresh_active_menu(menu_id)
	local menu = MenuHelper:GetMenu(menu_id)
	if not (menu and menu._items) then
		return
	end
	for _, item in pairs(menu._items) do
		local p = item._parameters
		if p and p.name then
			local key = p.name:match("^pg_(.+)$")
			if key and T.settings[key] ~= nil then
				local v = T.settings[key]
				if type(v) == "boolean" then
					v = v and "on" or "off"
				end
				item:set_value(v)
			end
		end
	end
end

Hooks:Add("MenuManagerInitialize", "ProvingGroundsQuickstart_callbacks", function(menu_manager)
	local function set(key, value)
		T.settings[key] = value
	end
	local function toggle(key)
		return function(self, item)
			set(key, item:value() == "on")
		end
	end
	local function choice(key)
		return function(self, item)
			set(key, item:value())
		end
	end

	MenuCallbackHandler.pg_set_skip_ready = toggle("skip_ready")
	MenuCallbackHandler.pg_set_level = choice("level")
	MenuCallbackHandler.pg_set_difficulty = choice("difficulty")
	MenuCallbackHandler.pg_set_one_down = toggle("one_down")
	MenuCallbackHandler.pg_set_team_ai = toggle("team_ai")
	MenuCallbackHandler.pg_set_online = toggle("online")
	MenuCallbackHandler.pg_reset = function()
		for k, v in pairs(T.defaults) do
			T.settings[k] = v
		end
		refresh_active_menu(MENU)
		QuickMenu:new(managers.localization:text("pg_reset_title"), managers.localization:text("pg_reset_done"), {}, true)
	end
	MenuCallbackHandler.pg_save = function() T:save() end
end)

Hooks:Add("MenuManagerSetupCustomMenus", "ProvingGroundsQuickstart_setup", function()
	MenuHelper:NewMenu(MENU)
end)

local function add_toggle(id, data)
	data.id = "pg_" .. id
	data.title = "pg_" .. id .. "_title"
	data.desc = "pg_" .. id .. "_desc"
	if not data.callback then
		data.callback = "pg_set_" .. id
	end
	data.menu_id = MENU
	data.priority = data.priority or 100
	MenuHelper:AddToggle(data)
end

local function add_choice(id, data)
	data.id = "pg_" .. id
	data.title = "pg_" .. id .. "_title"
	data.desc = "pg_" .. id .. "_desc"
	if not data.callback then
		data.callback = "pg_set_" .. id
	end
	data.menu_id = MENU
	data.priority = data.priority or 100
	MenuHelper:AddMultipleChoice(data)
end

Hooks:Add("MenuManagerPopulateCustomMenus", "ProvingGroundsQuickstart_populate", function()
	local s = T.settings
	local level_ids, level_items = level_list()

	add_choice("level", { value = s.level, items = level_items, item_values = level_ids, localized_items = false, priority = 101 })
	add_toggle("skip_ready", { value = s.skip_ready, priority = 100 })
	add_choice("difficulty", { value = s.difficulty, items = DIFFICULTY_KEYS, item_values = DIFFICULTY_IDS, localized_items = true, priority = 99 })
	add_toggle("one_down", { value = s.one_down, priority = 98 })
	add_toggle("team_ai", { value = s.team_ai, priority = 97 })
	add_toggle("online", { value = s.online, priority = 96 })
	MenuHelper:AddButton({ id = "pg_reset", title = "pg_reset_title", desc = "pg_reset_desc", callback = "pg_reset", menu_id = MENU, priority = 10 })
end)

Hooks:Add("MenuManagerBuildCustomMenus", "ProvingGroundsQuickstart_build", function(menu_manager, nodes)
	nodes[MENU] = MenuHelper:BuildMenu(MENU, { back_callback = "pg_save" })
	MenuHelper:AddMenuItem(nodes.blt_options, MENU, "pg_menu_title", "pg_menu_desc")
end)