--!nocheck
local license = ... or {}
license.Whitelist = getgenv().whitelist or license.Whitelist

local cloneref = cloneref or function(ref) return ref end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function isLoadingScreenDisabled()
	return isfile('aethercorev2/profiles/disableloading.txt') and readfile('aethercorev2/profiles/disableloading.txt') == 'true'
end

local function getLoadingScreenParent()
	local parent
	if gethui then
		local ok, result = pcall(gethui)
		if ok and result then parent = result end
	end
	if not parent then
		local ok, result = pcall(function()
			return cloneref(game:GetService('CoreGui'))
		end)
		if ok then parent = result end
	end
	return parent
end

local function createLoadingScreen()
	if isLoadingScreenDisabled() then return nil end
	local parent = getLoadingScreenParent()
	if not parent then return nil end
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
	card.Size = UDim2.fromOffset(540, 330)
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
	glow.Size = UDim2.fromOffset(430, 3)
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
	logo.Position = UDim2.new(0.5, 0, 0, 28)
	logo.Size = UDim2.fromOffset(250, 108)
	logo.BackgroundTransparency = 1
	logo.ImageTransparency = 0.02
	logo.ScaleType = Enum.ScaleType.Fit
	logo.Image = isfile('aethercorev2/assets/new/loading.png') and (getcustomasset and getcustomasset('aethercorev2/assets/new/loading.png') or 'aethercorev2/assets/new/loading.png') or ''
	logo.Parent = card

	local version = Instance.new('TextLabel')
	version.Name = 'Version'
	version.AnchorPoint = Vector2.new(0.5, 0)
	version.Position = UDim2.new(0.5, 0, 0, 142)
	version.Size = UDim2.fromOffset(260, 22)
	version.BackgroundTransparency = 1
	version.Font = Enum.Font.GothamMedium
	version.TextSize = 14
	version.TextColor3 = Color3.fromRGB(190, 196, 220)
	version.Text = isfile('aethercorev2/version.txt') and ('Version '..readfile('aethercorev2/version.txt')) or 'Version loading...'
	version.Parent = card

	local status = Instance.new('TextLabel')
	status.Name = 'Status'
	status.Position = UDim2.fromOffset(54, 202)
	status.Size = UDim2.fromOffset(432, 22)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.Gotham
	status.TextSize = 14
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextColor3 = Color3.fromRGB(235, 238, 255)
	status.Text = 'Starting AetherCore...'
	status.Parent = card

	local track = Instance.new('Frame')
	track.Name = 'ProgressTrack'
	track.Position = UDim2.fromOffset(54, 238)
	track.Size = UDim2.fromOffset(432, 10)
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
	detail.Position = UDim2.fromOffset(54, 260)
	detail.Size = UDim2.fromOffset(432, 20)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.Gotham
	detail.TextSize = 12
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.TextColor3 = Color3.fromRGB(130, 142, 170)
	detail.Text = 'Preparing files and assets.'
	detail.Parent = card

	local lastProgress = 0.06
	local function closeScreen()
		if screen and screen.Parent then
			screen:Destroy()
		end
	end
	_G.AetherCoreLoadingScreen = screen
	_G.AetherCoreCloseLoadingScreen = closeScreen
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

local loadingScreen = createLoadingScreen()
if not _G.AetherCoreSetLoadingStatus then
	_G.AetherCoreSetLoadingStatus = function() end
end

local function downloadFile(path, func)
	if not isfile(path) then
		if not license.Closet then
			_G.AetherCoreSetLoadingStatus('Downloading '..path, 0.35)
		end
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/plutoxqqq/AetherCoreV2/'..readfile('aethercorev2/profiles/commit.txt')..'/'..select(1, path:gsub('aethercorev2/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
		_G.AetherCoreSetLoadingStatus('Downloaded '..path, 0.55)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('init') then continue end
		if file:find('profile') then continue end
		if isfile(file) then
			delfile(file)
		elseif isfolder(file) then
			wipeFolder(file)
		end
	end
end


for _, folder in {'aethercorev2', 'aethercorev2/games', 'aethercorev2/profiles', 'aethercorev2/assets', 'aethercorev2/assets/new', 'aethercorev2/libraries', 'aethercorev2/guis', 'aethercorev2/configs'} do
	if not isfolder(folder) then
		_G.AetherCoreSetLoadingStatus('Creating '..folder, 0.18)
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local commit = license.Commit or nil
	if not commit then
		local _, subbed = pcall(function()
			return game:HttpGet('https://github.com/plutoxqqq/AetherCoreV2')
		end)
		commit = subbed:find('currentOid')
		commit = commit and subbed:sub(commit + 13, commit + 52) or nil
		commit = commit and #commit == 40 and commit or 'main'
	end
	local oldCommit = isfile('aethercorev2/profiles/commit.txt') and readfile('aethercorev2/profiles/commit.txt') or ''
	if oldCommit ~= commit then
		if commit ~= 'main' and oldCommit ~= '' then
			shared.updated = oldCommit
		end
		wipeFolder('aethercorev2')
		wipeFolder('aethercorev2/games')
		wipeFolder('aethercorev2/guis')
		wipeFolder('aethercorev2/libraries')
	end
	writefile('aethercorev2/profiles/commit.txt', commit)
end

if not isfile('aethercorev2/profiles/disableloading.txt') then
	writefile('aethercorev2/profiles/disableloading.txt', 'false')
end

_G.AetherCoreSetLoadingStatus('Checking version...', 0.62)
downloadFile('aethercorev2/version.txt')
_G.AetherCoreSetLoadingStatus('Preparing loading artwork...', 0.70)
pcall(downloadFile, 'aethercorev2/assets/new/loading.png')

_G.AetherCoreSetLoadingStatus('Loading main script...', 0.82)
return loadstring(downloadFile('aethercorev2/main.lua'), 'main')(license)
