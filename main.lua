local license = ... or {}
repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end
license.Key = license.Key or '_key'

if isfolder('catrewrite') and isfolder('catrewrite/profiles') then
	for _, v in listfiles('catrewrite/profiles') do
		if not v:find('commit.txt') then
			local old = v
			v = v:gsub('catrewrite', 'catsix')
			writefile(v, readfile(old))
		end
	end
	delfolder('catrewrite/profiles')
end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))
local httpService = cloneref(game:GetService("HttpService"))

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catsix/profiles/commit.txt')..'/'..select(1, path:gsub('catsix/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()
	vape.Init = nil
	vape:Load()

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('catsix/main.lua'), 'main')(_scriptconfig)
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catsix/profiles/commit.txt')..'/init.lua', true), 'init')(_scriptconfig)
				end
			]]
			local teleportConfig = httpService:JSONEncode(license)
			teleportConfig = teleportConfig:gsub('":true', "=true"):gsub('{"', '{')
			teleportConfig = teleportConfig:gsub(',"', ','):gsub('":', '=')
			teleportConfig = teleportConfig:gsub('%[', '{'):gsub('%]', '}')
			teleportScript = teleportScript:gsub('_key', tostring(license.Key or '_key'))
			teleportScript = teleportScript:gsub('_scriptconfig', teleportConfig)
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if getgenv().catrole == 'HWID MISMATCH' then
			vape:CreateNotification('Cat', 'HWID MISMATCH, Go to the script panel to reset hwid', 25, 'alert')
			getgenv().catrole = ''
			task.wait(0.1)
		end
		if not shared.vapereload then
			vape:CreateNotification('Finished Loading', (getgenv().catname and `Authenticated as {getgenv().catname} with {getgenv().catrole}, ` or '').. (vape.VapeButton and 'Press the button in the top right' or 'Press '..table.concat(vape.Keybind, ' + '):upper())..' to open GUI', 5)
			task.delay(0.05 + cloneref(game:GetService('RunService')).PostSimulation:Wait(), function()
				if shared.updated then
					vape:CreateNotification('Cat', `Script has updated from {shared.updated} to {readfile('catsix/profiles/commit.txt')}`, 10, 'info')
				end
			end)
		end	
	end
end

if not isfile('catsix/profiles/gui.txt') then
	writefile('catsix/profiles/gui.txt', 'new')
end
local gui = 'new'--readfile('catsix/profiles/gui.txt')

if not isfolder('catsix/assets/'..gui) then
	makefolder('catsix/assets/'..gui)
end
vape = loadstring(downloadFile('catsix/guis/'..gui..'.lua'), 'gui')(license)
shared.vape = vape
shared.vapesmooth = true
_G.vape = vape
getgenv().used_init = true

if hookmetamethod and not getgenv().run then
	getgenv().run = true
	local old; old = hookmetamethod(game, '__namecall', function(self, Remote, ...)
		if not checkcaller() and getnamecallmethod() == 'FireServer' then
			if typeof(Remote) == "Instance" and Remote.Name == 'TabFreezeAnticheat_ClientToServerReport' then
				return
			end
		end
		return old(self, Remote, ...)
	end)
end

if shared.maincat then
	redirect()
	playersService.LocalPlayer:Kick('Your script is outdated, Get new one at discord.gg/catvape')
	return
end

if not shared.VapeIndependent then
	loadstring(downloadFile('catsix/games/universal.lua'), 'universal')(license)
	if isfile('catsix/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('catsix/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
	else
		if not shared.VapeDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catsix/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('catsix/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
			end
		end
	end
	if shared.VapeDeveloper then
		loadstring(downloadFile('catsix/libraries/premium.lua'), 'premium')(license)
	else
		loadstring(game:HttpGet('https://api.catvape.dev/download/libraries/premium.lua'), 'premium')(license)
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end