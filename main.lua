local license = ... or {}
license.Whitelist = getgenv().whitelist or license.Whitelist
local acceptedWhitelistKey = '1234-5678-9012-3456'

local function isWhitelisted()
	return tostring(getgenv().whitelist or license.Whitelist or '') == acceptedWhitelistKey
end
repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

local vape
local compile = loadstring
local loadstring = function(...)
	local res, err = compile(...)
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

local redirect = function()
	local body = httpService:JSONEncode({
		nonce = httpService:GenerateGUID(false),
		args = {
			invite = {code = 'aethercorev2'},
			code = 'aethercorev2'
		},
		cmd = 'INVITE_BROWSER'
	})

	for i = 1, 2 do
		task.spawn(function()
			request({
				Method = 'POST',
				Url = 'http://127.0.0.1:6463/rpc?v=1',
				Headers = {
					['Content-Type'] = 'application/json',
					Origin = 'https://discord.com'
				},
				Body = body
			})
		end)
	end
end

local function downloadFile(path, func)
	if not isfile(path) then
		warn(path)
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/plutoxqqq/AetherCoreV2/'..readfile('aethercorev2/profiles/commit.txt')..'/'..select(1, path:gsub('aethercorev2/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			task.spawn(error, res)
		end
		if suc then
			if path:find('.lua') then
				res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
			end
			writefile(path, res)
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
				getgenv().whitelist = '_whitelist'
				if shared.VapeDeveloper then
					loadstring(readfile('aethercorev2/main.lua'), 'main')(_scriptconfig)
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/plutoxqqq/AetherCoreV2/main/init.lua', true), 'init.lua')(_scriptconfig)
				end
			]]
			local teleportConfig = httpService:JSONEncode(license)
			teleportConfig = teleportConfig:gsub('":true', "=true"):gsub('{"', '{')
			teleportConfig = teleportConfig:gsub(',"', ','):gsub('":', '=')
			teleportConfig = teleportConfig:gsub('%[', '{'):gsub('%]', '}')
			teleportScript = teleportScript:gsub('_whitelist', tostring(getgenv().whitelist or license.Whitelist or 'KEY_HERE'))
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
			if vape.Place ~= 6872274481 then
				--task.spawn(redirect)
			end
			vape:CreateNotification('Finished Loading', (vape.VapeButton and 'Press the button in the top right' or 'Press '..table.concat(vape.Keybind, ' + '):upper())..' to open GUI', 5)
			if isWhitelisted() then
				vape:CreateNotification('AetherCore', 'You are whitelisted.', 5, 'info')
			end
			task.delay(1, function()
				if shared.updated then
					vape:CreateNotification('AetherCore', `Script has updated from {shared.updated} to {readfile('aethercorev2/profiles/commit.txt')}`, 10, 'info')
				end
			end)
		end
	end
end

if not isfile('aethercorev2/profiles/gui.txt') then
	writefile('aethercorev2/profiles/gui.txt', 'new')
end
local gui = 'new'--readfile('aethercorev2/profiles/gui.txt')

if not isfolder('aethercorev2/assets/'..gui) then
	makefolder('aethercorev2/assets/'..gui)
end
if not isfile('aethercorev2/profiles/commit.txt') then
	writefile('aethercorev2/profiles/commit.txt', 'main')
end

getgenv().used_init = true
vape = loadstring(downloadFile('aethercorev2/guis/'..gui..'.lua'), 'gui')(license)
_G.vape = vape
shared.vape = vape

if shared.mainAether then
	redirect()
	playersService.LocalPlayer:Kick('Your script is outdated, Get new one at discord.gg/aethercorev2')
	return
end

if not shared.VapeIndependent then
	loadstring(downloadFile('aethercorev2/games/universal.lua'), 'universal')(license)
	if isfile('aethercorev2/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('aethercorev2/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
	else
		if not shared.VapeDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/plutoxqqq/AetherCoreV2/'..readfile('aethercorev2/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('aethercorev2/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(license)
			end
		end
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end