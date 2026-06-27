repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

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
local httpService = cloneref(game:GetService('HttpService'))

if not isfolder('fart') then
	makefolder('fart')
end
if not isfolder('fart/profiles') then
	makefolder('fart/profiles')
end
if not isfile('fart/profiles/commit.txt') then
	writefile('fart/profiles/commit.txt', 'main')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/5rmsn4tt2c-ux/fart_/'..readfile('fart/profiles/commit.txt')..'/'..select(1, path:gsub('fart/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	else
		local content = readfile(path)
		if not content:find('--This watermark') then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/5rmsn4tt2c-ux/fart_/'..readfile('fart/profiles/commit.txt')..'/'..select(1, path:gsub('fart/', '')), true)
			end)
			if suc and res ~= '404: Not Found' then
				res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
				writefile(path, res)
			end
		end
	end
	return (func or readfile)(path)
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function(state)
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				if shared.VapeDeveloper then
					loadstring(readfile('fart/main.lua'), 'main')(_scriptconfig)
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/5rmsn4tt2c-ux/fart_/main/main.lua'), 'init')(_scriptconfig)
				end
			]]
			local teleportConfig = httpService:JSONEncode({})
			teleportConfig = teleportConfig:gsub('":true', "=true"):gsub('{"', '{')
			teleportConfig = teleportConfig:gsub(',"', ','):gsub('":', '=')
			teleportConfig = teleportConfig:gsub('%[', '{'):gsub('%]', '}')
			teleportScript = teleportScript:gsub('_scriptconfig', teleportConfig)
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', (vape.VapeButton and 'Press the button in the top right' or 'Press '..table.concat(vape.Keybind, ' + '):upper())..' to open GUI', 5)
		end
	end
end

if not isfile('fart/profiles/gui.txt') then
	writefile('fart/profiles/gui.txt', 'new')
end
local gui = 'new'

if not isfolder('fart/assets/'..gui) then
	makefolder('fart/assets/'..gui)
end
vape = loadstring(downloadFile('fart/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape

if not shared.VapeIndependent then
	loadstring(downloadFile('fart/games/universal.lua'), 'universal')()
	local suc, err = pcall(function()
    loadstring(downloadFile('fart/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))()
end)
if not suc then
    vape:CreateNotification('Fart', 'Game file failed: '..tostring(err), 10, 'warning')
end
	loadstring(downloadFile('fart/libraries/premium.lua'), 'premium')()
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
