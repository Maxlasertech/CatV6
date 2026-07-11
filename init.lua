--!nocheck
local license = ... or {}
license.Key = script_key or license.Key

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
			return game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catrewrite/profiles/commit.txt')..'/'..select(1, path:gsub('catrewrite/', '')), true)
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


for _, folder in {'catrewrite', 'catrewrite/games', 'catrewrite/profiles', 'catrewrite/assets', 'catrewrite/libraries', 'catrewrite/guis'} do
	if not isfolder(folder) then
		downloader.Text = 'Downloading '.. folder
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local commit = license.Commit or nil
	if not commit then
		local _, subbed = pcall(function() 
			return game:HttpGet('https://github.com/MaxlaserTech/CatV6') 
		end)
		commit = subbed:find('currentOid')
		commit = commit and subbed:sub(commit + 13, commit + 52) or nil
		commit = commit and #commit == 40 and commit or 'main'
	end
	if commit == 'main' or (isfile('catrewrite/profiles/commit.txt') and readfile('catrewrite/profiles/commit.txt') or '') ~= commit then
		if commit ~= 'main' and isfile('catrewrite/profiles/commit.txt') then
			shared.updated = readfile('catrewrite/profiles/commit.txt')
		end
		wipeFolder('catrewrite')
		wipeFolder('catrewrite/games')
		wipeFolder('catrewrite/guis')
		wipeFolder('catrewrite/libraries')
	end
	writefile('catrewrite/profiles/commit.txt', commit)
	if #listfiles('catrewrite/profiles') < 4 then
		local req = request({
			Url = 'https://api.github.com/repos/maxlasertech/catv6/contents/profiles',
			Method = 'GET'
		})
		if req.StatusCode == 200 then
			local body = cloneref(game:GetService('HttpService')):JSONDecode(req.Body)
			if body and typeof(body) == 'table' then
				for _, v in body do
					if v.type == 'file' then
						pcall(downloadFile, 'catrewrite/'.. ({v.path:gsub(' ', '%%20')})[1])
					end
				end
			end
		end
	end
end

downloader.Text = ''
return loadstring(downloadFile('catrewrite/main.lua'), 'main')(license)