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

local function createInlineLoadingScreen()
	local parent = gethui and gethui() or cloneref(game:GetService('CoreGui'))
	local existing = parent:FindFirstChild('AetherCoreLoading')
	if existing and _G.AetherCoreSetLoadingStatus then return existing end

	local screen = existing or Instance.new('ScreenGui')
	screen.Name = 'AetherCoreLoading'
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 2147483647
	screen.Parent = parent
	screen:ClearAllChildren()

	local background = Instance.new('Frame')
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(8, 9, 14)
	background.BackgroundTransparency = 0.18
	background.BorderSizePixel = 0
	background.Parent = screen

	local gradient = Instance.new('UIGradient')
	gradient.Rotation = 25
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 10, 18)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(16, 22, 34)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 9, 14))
	})
	gradient.Parent = background

	local card = Instance.new('Frame')
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(430, 260)
	card.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.Parent = background
	local cardCorner = Instance.new('UICorner')
	cardCorner.CornerRadius = UDim.new(0, 18)
	cardCorner.Parent = card
	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(90, 230, 210)
	stroke.Transparency = 0.74
	stroke.Thickness = 1
	stroke.Parent = card

	local glow = Instance.new('Frame')
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromOffset(360, 3)
	glow.BackgroundColor3 = Color3.fromRGB(90, 230, 210)
	glow.BackgroundTransparency = 0.68
	glow.BorderSizePixel = 0
	glow.Parent = card
	local glowCorner = Instance.new('UICorner')
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent = glow

	local logo = Instance.new('ImageLabel')
	logo.Name = 'Logo'
	logo.AnchorPoint = Vector2.new(0.5, 0)
	logo.Position = UDim2.new(0.5, 0, 0, 32)
	logo.Size = UDim2.fromOffset(290, 96)
	logo.BackgroundTransparency = 1
	logo.ImageTransparency = 0.02
	logo.ScaleType = Enum.ScaleType.Fit
	logo.Image = isfile('aethercorev2/assets/new/loading.png') and (getcustomasset and getcustomasset('aethercorev2/assets/new/loading.png') or 'aethercorev2/assets/new/loading.png') or ''
	logo.Parent = card

	local version = Instance.new('TextLabel')
	version.Name = 'Version'
	version.AnchorPoint = Vector2.new(0.5, 0)
	version.Position = UDim2.new(0.5, 0, 0, 128)
	version.Size = UDim2.fromOffset(260, 22)
	version.BackgroundTransparency = 1
	version.Font = Enum.Font.GothamMedium
	version.TextSize = 14
	version.TextColor3 = Color3.fromRGB(190, 196, 220)
	version.Text = isfile('aethercorev2/version.txt') and ('Version '..readfile('aethercorev2/version.txt')) or 'Version loading...'
	version.Parent = card

	local status = Instance.new('TextLabel')
	status.Name = 'Status'
	status.Position = UDim2.fromOffset(35, 166)
	status.Size = UDim2.fromOffset(360, 20)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.Gotham
	status.TextSize = 13
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextColor3 = Color3.fromRGB(235, 238, 255)
	status.Text = 'Starting AetherCore...'
	status.Parent = card

	local track = Instance.new('Frame')
	track.Name = 'ProgressTrack'
	track.Position = UDim2.fromOffset(35, 196)
	track.Size = UDim2.fromOffset(360, 8)
	track.BackgroundColor3 = Color3.fromRGB(28, 34, 50)
	track.BackgroundTransparency = 0.18
	track.BorderSizePixel = 0
	track.Parent = card
	local trackCorner = Instance.new('UICorner')
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new('Frame')
	fill.Name = 'ProgressFill'
	fill.Size = UDim2.fromScale(0.06, 1)
	fill.BackgroundColor3 = Color3.fromRGB(90, 230, 210)
	fill.BorderSizePixel = 0
	fill.Parent = track
	local fillCorner = Instance.new('UICorner')
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local detail = Instance.new('TextLabel')
	detail.Name = 'Detail'
	detail.Position = UDim2.fromOffset(35, 214)
	detail.Size = UDim2.fromOffset(360, 18)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.Gotham
	detail.TextSize = 11
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.TextColor3 = Color3.fromRGB(130, 142, 170)
	detail.Text = 'Preparing files and assets.'
	detail.Parent = card

	local lastProgress = 0.06
	_G.AetherCoreLoadingScreen = screen
	_G.AetherCoreSetLoadingStatus = function(text, progress)
		if not screen.Parent then return end
		lastProgress = math.clamp(progress or lastProgress, lastProgress, 1)
		if status.Parent then status.Text = text end
		if detail.Parent then detail.Text = math.floor(lastProgress * 100)..'% complete' end
		if fill.Parent then fill.Size = UDim2.fromScale(lastProgress, 1) end
		if version.Parent and isfile('aethercorev2/version.txt') then version.Text = 'Version '..readfile('aethercorev2/version.txt') end
		if logo.Parent and logo.Image == '' and isfile('aethercorev2/assets/new/loading.png') then
			logo.Image = getcustomasset and getcustomasset('aethercorev2/assets/new/loading.png') or 'aethercorev2/assets/new/loading.png'
		end
	end
	return screen
end

local function setLoadingStatus(text, progress)
	createInlineLoadingScreen()
	if _G.AetherCoreSetLoadingStatus then
		pcall(_G.AetherCoreSetLoadingStatus, text, progress)
	end
end

local function closeLoadingScreen()
	local screen = _G.AetherCoreLoadingScreen
	if screen and screen.Parent then
		screen:Destroy()
	end
	_G.AetherCoreLoadingScreen = nil
	_G.AetherCoreSetLoadingStatus = nil
end

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
		setLoadingStatus('Downloading '..path, 0.60)
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
			setLoadingStatus('Downloaded '..path, 0.72)
		end
	end
	return (func or readfile)(path)
end

local function finishLoading()
	setLoadingStatus('Finalizing...', 0.94)
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

	closeLoadingScreen()
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
setLoadingStatus('Loading interface...', 0.84)
vape = loadstring(downloadFile('aethercorev2/guis/'..gui..'.lua'), 'gui')(license)
_G.vape = vape
shared.vape = vape

if shared.mainAether then
	closeLoadingScreen()
	redirect()
	playersService.LocalPlayer:Kick('Your script is outdated, Get new one at discord.gg/aethercorev2')
	return
end

if not shared.VapeIndependent then
	setLoadingStatus('Loading universal modules...', 0.88)
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
	setLoadingStatus('Ready for independent initialization.', 1)
	task.delay(1, closeLoadingScreen)
	return vape
end
