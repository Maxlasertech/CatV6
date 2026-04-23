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
local httpService = cloneref(game:GetService('HttpService'))
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
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
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('catrewrite/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catrewrite/profiles/commit.txt')..'/loader.lua', true), 'loader')()
				end
			]]
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
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
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
_G.vape = vape

if not shared.VapeIndependent then
	loadstring(downloadFile('catrewrite/games/universal.lua'), 'universal')()
	if isfile('catrewrite/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('catrewrite/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		local suc, res = pcall(function()
			return not shared.VapeDeveloper and game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catrewrite/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true) or '404: Not Found'
		end)
		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile('catrewrite/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
		else
			local found = false
			local callback = shared.VapeDeveloper and readfile or downloadFile
			
			for i, v in httpService:JSONDecode(callback("catrewrite/profiles/supported.json")) do
				print('fr')
				if found then break; end
				if game.GameId == v.gameid then
					print('yo')
					for i2, v2 in v do
						if typeof(v2) == 'table' and table.find(v2.Ids, game.PlaceId) then
							found = true
							vape.Place = v2.Place
							loadstring(callback('catrewrite/games/'.. i.. '/'.. i2.. '.luau'), tostring(game.PlaceId))(...)
							break
						end
					end
				end
			end
		end
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end