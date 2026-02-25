local Args = ...
local commit = Args.Commit
shared.VapeDeveloper = shared.VapeDeveloper or Args.Developer

local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local cloneref = cloneref or function(ref) return ref end

local downloader = Instance.new('TextLabel')
downloader.Size = UDim2.new(1, 0, 0, 40)
downloader.BackgroundTransparency = 1
downloader.TextStrokeTransparency = 0
downloader.Text = ''
downloader.TextSize = 20
downloader.TextColor3 = Color3.new(1, 1, 1)
downloader.Font = Enum.Font.Arimo
downloader.Parent = gethui and gethui() or cloneref(game:GetService('Players')).LocalPlayer:WaitForChild('PlayerGui', 9e9)
getgenv().catdownloader = downloader

print('yo')

local function downloadFile(path, func)
	if not isfile(path) then
		if path ~= 'catrewrite/main.lua' then
			downloader.Text = `Downloading {path}`
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
	end
	downloader.Text = ''
	return (func or readfile)(path)
end

warn('pmo')

local function wipeFolder(path)
	if isfolder(path) then
		print('Wiping', path)
		for _, v in listfiles(path) do
			if isfile(v) then
				warn('Deleting', v)
				delfile(v)
				print('Deleted', v)
			end
		end
		print('Wiped', path)
	end
end

for _, folder in {'catrewrite', 'catrewrite/games', 'catrewrite/profiles', 'catrewrite/assets', 'catrewrite/libraries', 'catrewrite/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

getgenv().used_init = true

if not shared.VapeDeveloper then
	if not isfile('catrewrite/profiles/commit.txt') or readfile('catrewrite/profiles/commit.txt') ~= commit then
		wipeFolder('catrewrite')
		wipeFolder('catrewrite/games')
		wipeFolder('catrewrite/guis')
		wipeFolder('catrewrite/libraries')
	end
end
writefile('catrewrite/profiles/commit.txt', commit)

return loadstring(downloadFile('catrewrite/main.lua'), 'main')(Args)