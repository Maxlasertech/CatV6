--!nocheck

local loaderOptions = ... or {}

if type(loaderOptions) ~= 'table' then
	loaderOptions = {}
end

loaderOptions.Closet = loaderOptions.Closet == true

local function runMain(source)
	local chunk, compileError = loadstring(source, 'main')
	if not chunk then
		error('Failed to compile AetherCore main: ' .. tostring(compileError))
	end
	return chunk(loaderOptions)
end

if shared and shared.VapeDeveloper and isfile and isfile('aethercorev2/main.lua') then
	return runMain(readfile('aethercorev2/main.lua'))
end

return runMain(game:HttpGet('https://raw.githubusercontent.com/plutoxqqq/AetherCoreV2/main/main.lua', true))
