_G.ProvingGroundsQuickstartSettings = _G.ProvingGroundsQuickstartSettings or {}
local T = _G.ProvingGroundsQuickstartSettings

if T._core_loaded then
	return
end
T._core_loaded = true

T._path = ModPath
T._save = SavePath .. "proving_grounds_quickstart_settings.json"

T.defaults = {
	skip_ready = true,
	difficulty = "normal",
	one_down = false,
	team_ai = true
}

T.settings = {}
for k, v in pairs(T.defaults) do
	T.settings[k] = v
end

function T:load()
	local f = io.open(self._save, "r")
	if not f then
		return
	end
	local data = json.decode(f:read("*all"))
	f:close()
	if type(data) ~= "table" then
		return
	end
	for k, v in pairs(data) do
		if self.defaults[k] ~= nil and type(v) == type(self.defaults[k]) then
			self.settings[k] = v
		end
	end
end

function T:save()
	local f = io.open(self._save, "w+")
	if f then
		f:write(json.encode(self.settings))
		f:close()
	end
end

T:load()