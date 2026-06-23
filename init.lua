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

local downloader = Instance.new('TextLabel')
downloader.Size = UDim2.new(1, 0, 0, 40)
downloader.BackgroundTransparency = 1
downloader.TextStrokeTransparency = 0
downloader.TextSize = 20
downloader.TextColor3 = Color3.new(1, 1, 1)
downloader.Font = Enum.Font.Arial
downloader.Text = ''
downloader.Parent = Instance.new('ScreenGui', gethui and gethui() or cloneref(game:GetService('CoreGui')))

local function downloadFile(path, func)
	if not isfile(path) then
		if not license.Closet then
			downloader.Text = 'Downloading '.. path
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
		downloader.Text = ''
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


for _, folder in {'aethercorev2', 'aethercorev2/games', 'aethercorev2/profiles', 'aethercorev2/assets', 'aethercorev2/libraries', 'aethercorev2/guis', 'aethercorev2/configs'} do
	if not isfolder(folder) then
		downloader.Text = 'Downloading '.. folder
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

downloader.Text = ''
if downloader.Parent then
	downloader.Parent:Destroy()
end
return loadstring(downloadFile('aethercorev2/main.lua'), 'main')(license)
