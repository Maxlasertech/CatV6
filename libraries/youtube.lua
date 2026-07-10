local httpService = cloneref(game:GetService('HttpService'))
local req = (syn and syn.request) or request or http_request

local YouTube = {}

YouTube.PipedInstances = {
	'https://pipedapi.kavin.rocks',
	'https://pipedapi.leptons.xyz',
	'https://pipedapi.nosebs.ru',
}

YouTube.InvidiousInstances = {
	'https://inv.nadeko.net',
	'https://invidious.nerdvpn.de',
	'https://invidious.jing.rocks',
}

YouTube.ApiMode = 'piped'
YouTube.ApiIndex = 1

local INSTANCE_FILE = 'fart/profiles/yt_instance.txt'

function YouTube:GetBaseUrl()
	if self.ApiMode == 'piped' then
		return self.PipedInstances[self.ApiIndex] or self.PipedInstances[1]
	else
		return self.InvidiousInstances[self.ApiIndex] or self.InvidiousInstances[1]
	end
end

function YouTube:LoadSettings()
	pcall(function()
		local data = readfile(INSTANCE_FILE)
		if data and data ~= '' then
			local parts = data:split('|')
			if parts[1] then self.ApiMode = parts[1] end
			if parts[2] then self.ApiIndex = tonumber(parts[2]) or 1 end
		end
	end)
end

function YouTube:SaveSettings()
	pcall(writefile, INSTANCE_FILE, self.ApiMode .. '|' .. tostring(self.ApiIndex))
end

function YouTube:Request(endpoint)
	local url = self:GetBaseUrl() .. endpoint
	local ok, res = pcall(req, {
		Url = url,
		Method = 'GET',
		Headers = { ['Accept'] = 'application/json' },
	})
	if not ok then
		ok, res = pcall(function()
			return { Body = game:HttpGet(url, true), StatusCode = 200 }
		end)
	end
	if not ok then return nil, 'Request failed' end
	local body = type(res) == 'string' and res or (res.Body or res.body)
	local status = type(res) == 'table' and (res.StatusCode or res.statusCode) or 200
	if status and (status < 200 or status >= 300) then
		return nil, 'HTTP ' .. tostring(status)
	end
	if body and body ~= '' then
		local ok2, data = pcall(httpService.JSONDecode, httpService, body)
		if ok2 then
			if data.error then
				return nil, tostring(data.error)
			end
			return data, nil
		end
		return nil, 'JSON parse error'
	end
	return nil, 'Empty response'
end

function YouTube:DownloadAudio(audioUrl, filename)
	if not audioUrl or audioUrl == '' then
		return nil, 'No audio URL'
	end
	local filepath = 'fart/youtube/' .. filename
	local ok, res = pcall(req, {
		Url = audioUrl,
		Method = 'GET',
	})
	if not ok then
		ok, res = pcall(function()
			return { Body = game:HttpGet(audioUrl, true), StatusCode = 200 }
		end)
	end
	if not ok then return nil, 'Download failed' end
	local body = type(res) == 'string' and res or (res.Body or res.body)
	if not body or body == '' then return nil, 'Empty download' end
	local wok = pcall(writefile, filepath, body)
	if not wok then return nil, 'Write failed' end
	return filepath, nil
end

function YouTube:Search(query, limit)
	limit = limit or 5
	local encoded = query:gsub(' ', '+'):gsub('[^%w%+]', function(c)
		return string.format('%%%02X', string.byte(c))
	end)
	if self.ApiMode == 'piped' then
		return self:Request('/search?q=' .. encoded .. '&filter=music_songs')
	else
		return self:Request('/api/v1/search?q=' .. encoded .. '&type=video&sort_by=relevance')
	end
end

function YouTube:GetStreams(videoId)
	if self.ApiMode == 'piped' then
		return self:Request('/streams/' .. videoId)
	else
		return self:Request('/api/v1/videos/' .. videoId .. '?local=true')
	end
end

function YouTube:GetBestAudio(streamData)
	if not streamData then return nil end

	if self.ApiMode == 'piped' then
		local streams = streamData.audioStreams
		if not streams or #streams == 0 then return nil end
		local best = nil
		for _, s in streams do
			if s.url and s.url ~= '' then
				if not best or (s.bitrate or 0) > (best.bitrate or 0) then
					best = s
				end
			end
		end
		return best and best.url or nil
	else
		local formats = streamData.adaptiveFormats
		if not formats or #formats == 0 then return nil end
		local best = nil
		for _, f in formats do
			local ftype = f.type or ''
			if ftype:find('audio') and f.url and f.url ~= '' then
				if not best or (f.bitrate or 0) > (best.bitrate or 0) then
					best = f
				end
			end
		end
		return best and best.url or nil
	end
end

function YouTube:GetVideoTitle(streamData)
	if not streamData then return '???', '???' end
	if self.ApiMode == 'piped' then
		return streamData.title or '???', streamData.uploader or '???'
	else
		return streamData.title or '???', streamData.author or '???'
	end
end

function YouTube:GetSearchResults(data)
	if not data then return {} end
	local results = {}

	if self.ApiMode == 'piped' then
		local items = data.items or data
		if type(items) ~= 'table' then return {} end
		for _, item in items do
			if item.url or item.videoId then
				local videoId = item.url and item.url:match('/watch%?v=(.+)') or item.videoId
				table.insert(results, {
					id = videoId,
					title = item.title or '???',
					artist = item.uploaderName or item.uploader or '???',
					duration = item.duration or 0,
				})
			end
		end
	else
		for _, item in data do
			if item.videoId then
				table.insert(results, {
					id = item.videoId,
					title = item.title or '???',
					artist = item.author or '???',
					duration = item.lengthSeconds or 0,
				})
			end
		end
	end

	return results
end

function YouTube:FormatDuration(seconds)
	if not seconds or seconds <= 0 then return '?' end
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format('%d:%02d', m, s)
end

function YouTube:TrySwitchInstance()
	local instances = self.ApiMode == 'piped' and self.PipedInstances or self.InvidiousInstances
	self.ApiIndex = self.ApiIndex + 1
	if self.ApiIndex > #instances then
		if self.ApiMode == 'piped' then
			self.ApiMode = 'invidious'
			self.ApiIndex = 1
		else
			self.ApiMode = 'piped'
			self.ApiIndex = 1
		end
	end
	self:SaveSettings()
	return self:GetBaseUrl()
end

return YouTube
