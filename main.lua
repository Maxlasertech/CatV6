local license = ...
repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end
print(shared.VapeDeveloper)

if identifyexecutor then
	if table.find({'Argon', 'Wave', 'Seliware', 'Volt'}, ({identifyexecutor()})[1]) then
		print('thanks bro')
		getgenv().setthreadidentity = nil
	end
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
local httpService = cloneref(game:GetService('HttpService'))

if shared.maincat then 
	local body = httpService:JSONEncode({
		nonce = httpService:GenerateGUID(false),
		args = {
			invite = {code = 'catvape'},
			code = 'catvape'
		},
		cmd = 'INVITE_BROWSER'
	})

	for i = 1, 2 do
		task.spawn(pcall, function()
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
	setclipboard([[loadstring(game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/main/init.lua'), 'init.lua')({})]])
	playersService.LocalPlayer:Kick('Your using an outdated loader of catvape\nYou may be getting ip logged. Please change ur loader now') 
end

local function downloadFile(path, func)
	warn(path)
	if not isfile(path) then
		print('broo')
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catrewrite/profiles/commit.txt')..'/'..select(1, path:gsub('catrewrite/', '')), true)
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
shared.catdata = license

local function compileTable(tab)
	local json = '{'
	for i, v in tab do
		json = `{json}\n					    {i} = {typeof(v) == 'string' and '"'.. v.. '"' or v},`
	end
	return `{json}\n					}`
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	vape:Clean(task.spawn(function()
		repeat
			pcall(function() vape:Save() end)
			task.wait(10)
		until false
	end))

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) and vape.AutoTeleport.Enabled then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('catrewrite/loader.lua'), 'loader')(sharedData)
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catrewrite/profiles/commit.txt')..'/loader.lua', true), 'loader')(sharedData)
				end
			]]
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			teleportScript = teleportScript:gsub('sharedData', compileTable(license))
			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		local body = httpService:JSONEncode({
			nonce = httpService:GenerateGUID(false),
			args = {
				invite = {code = 'catvape'},
				code = 'catvape'
			},
			cmd = 'INVITE_BROWSER'
		})

		for i = 1, 2 do
			task.spawn(pcall, function()
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
		vape:CreateNotification('Cat', 'Our last server got limited, Join our backup server discord.gg/catvape', 30, 'warning')
		
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			task.wait(0.5)
			vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
			task.wait(0.5)
			vape:CreateNotification('Cat', `Initalized as {getgenv().catname} with {getgenv().catrole}`, 5, 'info')
		end
	end
end

if not isfile('catrewrite/profiles/gui.txt') then
	writefile('catrewrite/profiles/gui.txt', 'new')
end
local gui = readfile('catrewrite/profiles/gui.txt')

if not isfolder('catrewrite/assets/'..gui) then
	makefolder('catrewrite/assets/'..gui)
end
vape = loadstring(downloadFile('catrewrite/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape

if not shared.VapeIndependent then
	loadstring(downloadFile('catrewrite/games/universal.lua'), 'universal')()
	if isfile('catrewrite/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('catrewrite/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		if not shared.VapeDeveloper then
			local success, result = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catrewrite/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua')
			end)

			if success and result ~= '404: Not Found' then
				writefile(`catrewrite/games/{game.PlaceId}.lua`, result)
				loadstring(result, tostring(game.PlaceId))(...)
			end
		end
	end
	loadstring(downloadFile('catrewrite/libraries/script.lua'), 'script.lua')(license.Key)
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end

