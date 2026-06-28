--!nocheck

local API_BASE = 'https://aethercore-api.plutoxqq.workers.dev'

local AUTH_ENDPOINT = '/auth'
local MODULE_ENDPOINT = '/module/'
local ALLOWED_MODULES = {
	free = true,
	admin = true,
	premium = true,
	dev = true,
}

local loaderOptions = ... or {}
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')

local function log(message)
	print('[AetherCore] ' .. tostring(message))
end

local function trimTrailingSlash(value)
	return tostring(value):gsub('/+$', '')
end

local function buildUrl(path, query)
	local url = trimTrailingSlash(API_BASE) .. path
	if query and query ~= '' then
		url = url .. '?' .. query
	end
	return url
end

local function urlEncode(value)
	return HttpService:UrlEncode(tostring(value))
end

local function safeHttpGet(url)
	local success, response = pcall(function()
		return game:HttpGet(url, true)
	end)

	if not success then
		return false, 'Request failed: ' .. tostring(response)
	end

	if type(response) ~= 'string' or response == '' then
		return false, 'Request returned an empty response.'
	end

	return true, response
end

local function safeJsonDecode(jsonText)
	local success, decoded = pcall(function()
		return HttpService:JSONDecode(jsonText)
	end)

	if not success then
		return false, 'Invalid JSON response: ' .. tostring(decoded)
	end

	if type(decoded) ~= 'table' then
		return false, 'JSON response was not an object.'
	end

	return true, decoded
end

local function getUserId()
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return nil, 'LocalPlayer is not available yet.'
	end

	local userId = localPlayer.UserId
	if not userId or userId <= 0 then
		return nil, 'Unable to read a valid Roblox UserId.'
	end

	return tostring(userId)
end

local function authenticate(userId)
	local authUrl = buildUrl(AUTH_ENDPOINT, 'userId=' .. urlEncode(userId))
	log('Authenticating user ' .. userId .. '...')

	local requestSuccess, response = safeHttpGet(authUrl)
	if not requestSuccess then
		return nil, response
	end

	local decodeSuccess, authData = safeJsonDecode(response)
	if not decodeSuccess then
		return nil, authData
	end

	if tostring(authData.userId or '') ~= userId then
		return nil, 'Authentication response UserId did not match the current player.'
	end

	if type(authData.modules) ~= 'table' then
		return nil, 'Authentication response did not include a valid modules list.'
	end

	return authData
end

local function getAllowedModules(authData)
	local modules = {}
	local seen = {}

	for _, moduleName in ipairs(authData.modules) do
		moduleName = tostring(moduleName):lower()
		if ALLOWED_MODULES[moduleName] and not seen[moduleName] then
			seen[moduleName] = true
			table.insert(modules, moduleName)
		else
			log('Skipping unknown or duplicate module: ' .. moduleName)
		end
	end

	return modules
end

local function downloadModule(moduleName, authData)
	local moduleUrl = buildUrl(MODULE_ENDPOINT .. urlEncode(moduleName), 'userId=' .. urlEncode(authData.userId))
	log('Downloading module: ' .. moduleName)

	local requestSuccess, source = safeHttpGet(moduleUrl)
	if not requestSuccess then
		return nil, source
	end

	return source
end

local function executeModule(moduleName, source, authData)
	log('Executing module: ' .. moduleName)

	local compileSuccess, compiledOrError = pcall(function()
		return loadstring(source, 'AetherCore/' .. moduleName)
	end)

	if not compileSuccess then
		return false, 'Failed to compile module "' .. moduleName .. '": ' .. tostring(compiledOrError)
	end

	if type(compiledOrError) ~= 'function' then
		return false, 'Module "' .. moduleName .. '" did not compile into a function.'
	end

	local runSuccess, runError = pcall(function()
		return compiledOrError({
			apiBase = API_BASE,
			auth = authData,
			loaderOptions = loaderOptions,
			moduleName = moduleName,
		})
	end)

	if not runSuccess then
		return false, 'Module "' .. moduleName .. '" crashed: ' .. tostring(runError)
	end

	return true
end

local function main()
	log('Secure loader started.')

	local userId, userIdError = getUserId()
	if not userId then
		log('Authentication stopped: ' .. userIdError)
		return false
	end

	local authData, authError = authenticate(userId)
	if not authData then
		log('Authentication failed: ' .. tostring(authError))
		return false
	end

	log('Authenticated as role: ' .. tostring(authData.role or 'unknown'))

	local modules = getAllowedModules(authData)
	if #modules == 0 then
		log('No modules are available for this account.')
		return false
	end

	for index, moduleName in ipairs(modules) do
		log('Loading module ' .. index .. '/' .. #modules .. ': ' .. moduleName)

		local source, downloadError = downloadModule(moduleName, authData)
		if not source then
			log('Failed to download module "' .. moduleName .. '": ' .. tostring(downloadError))
			continue
		end

		local executed, executeError = executeModule(moduleName, source, authData)
		if executed then
			log('Loaded module: ' .. moduleName)
		else
			log(tostring(executeError))
		end
	end

	log('Secure loader finished.')
	return true
end

local success, result = pcall(main)
if not success then
	log('Unexpected loader error: ' .. tostring(result))
	return false
end

return result
