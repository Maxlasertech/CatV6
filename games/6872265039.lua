local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local sessioninfo = vape.Libraries.sessioninfo
local bedwars = {}

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function() return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9) end)
		if KnitInit then break end
		task.wait()
	until KnitInit
	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end
	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client

	bedwars = setmetatable({
		AchievementId = require(replicatedStorage.TS.achievement['achievement-id']).AchievementId,
		Client = Client,
		CrateItemMeta = debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3),
		QueueMeta = require(replicatedStorage.TS.game['queue-meta']).QueueMeta,
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})

	sessioninfo:AddItem('Kills')
	sessioninfo:AddItem('Beds')
	sessioninfo:AddItem('Wins')
	sessioninfo:AddItem('Games')

	vape:Clean(function()
		table.clear(bedwars)
	end)
end)

for i, v in vape.Modules do
	if v.Category == 'Combat' or v.Category == 'Minigames' then
		vape:Remove(i)
	end
end

--[[
    Combat
]]

run(function()
    local Sprint
    local old
    
    Sprint = vape.Categories.Combat:CreateModule({
        Name = 'Sprint',
        Function = function(callback)
            if callback then
                old = bedwars.SprintController.stopSprinting
                bedwars.SprintController.stopSprinting = function(...)
                    local call = old(...)
                    bedwars.SprintController:startSprinting()
                    return call
                end
                Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() bedwars.SprintController:stopSprinting() end))
                bedwars.SprintController:stopSprinting()
            else
                bedwars.SprintController.stopSprinting = old
                bedwars.SprintController:stopSprinting()
            end
        end,
        Tooltip = 'Sets your sprinting to true.'
    })
end)

--[[
    Utility
]]

run(function()
    local AutoQueue
    local QueueType
    local Leave
    
    local Categories = {}
    
    AutoQueue = vape.Categories.Utility:CreateModule({
        Name = 'Auto Queue',
        Function = function(call)
            if call then
                repeat
                    local partyData = bedwars.Store:getState().Party
                    if partyData.leader.userId == lplr.UserId then
                        if partyData.queueState == 3 and partyData.queueState ~= Categories[QueueType.Value] then
                            replicatedStorage['events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events'].leaveQueue:FireServer()
                        elseif partyData.queueState < 2 then
                            replicatedStorage['events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events'].joinQueue:FireServer({
                                queueType = Categories[QueueType.Value]
                            })
                            task.wait(1)
                        end
                    elseif Leave.Enabled then
                        replicatedStorage['events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events'].leaveParty:FireServer()
                    end
                    task.wait(0.1)
                until not AutoQueue.Enabled
    
            else
                replicatedStorage['events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events'].leaveQueue:FireServer()
            end
        end
    })
    
    local list = {}
    for i,v in bedwars.QueueMeta do
        if not v.disabled then
            Categories[v.title] = i
            table.insert(list, v.title)
        end
    end
    QueueType = AutoQueue:CreateDropdown({
        Name = 'Queue Type',
        List = list,
        Default = 'Duels (2v2)'
    })
    Leave = AutoQueue:CreateToggle({
        Name = 'Leave Party',
        Default = true
    })
end)

--[[
    Minigames
]]

run(function()
    local AutoGamble
    
    AutoGamble = vape.Categories.Minigames:CreateModule({
        Name = 'AutoGamble',
        Function = function(callback)
            if callback then
                AutoGamble:Clean(bedwars.Client:GetNamespace('RewardCrate'):Get('CrateOpened'):Connect(function(data)
                    if data.openingPlayer == lplr then
                        local tab = bedwars.CrateItemMeta[data.reward.itemType] or {displayName = data.reward.itemType or 'unknown'}
                        notif('AutoGamble', 'Won '..tab.displayName, 5)
                    end
                end))
    
                repeat
                    if not bedwars.CrateAltarController.activeCrates[1] then
                        for _, v in bedwars.Store:getState().Consumable.inventory do
                            if v.consumable:find('crate') then
                                bedwars.CrateAltarController:pickCrate(v.consumable, 1)
                                task.wait(1.2)
                                if bedwars.CrateAltarController.activeCrates[1] and bedwars.CrateAltarController.activeCrates[1][2] then
                                    bedwars.Client:GetNamespace('RewardCrate'):Get('OpenRewardCrate'):SendToServer({
                                        crateId = bedwars.CrateAltarController.activeCrates[1][2].attributes.crateId
                                    })
                                end
                                break
                            end
                        end
                    end
                    task.wait(1)
                until not AutoGamble.Enabled
            end
        end,
        Tooltip = 'Automatically opens lucky crates, piston inspired!'
    })
end)

run(function()
    local Claim = bedwars.Client:Get('ClaimAchievementRewards')

    vape.Categories.Minigames:CreateModule({
        Name = 'Infinite Rewards',
        Function = function(callback)
            if callback then
                for i in bedwars.AchievementId do
                    Claim:SendToServer({id = i:lower()})
                end
            end
        end,
        Tooltip = 'Automatically claims all rewards ingame.'
    })
end)

--[[
    Utility
]]

run(function()
    local pl  = cloneref(game:GetService('Players'))
    local hs  = cloneref(game:GetService('HttpService'))

    local BEDWARS_LOBBY_PLACE = 6872265039
    local BEDWARS_GAME_PLACE  = 6872274481
    local BEDWARS_UNIVERSE    = 2619619496

    local _gui = nil
    local function destroyGui()
        if _gui then _gui:Destroy(); _gui = nil end
    end

    local function getFriendGamemode(username)
        local pg = lplr:FindFirstChild('PlayerGui')
        if not pg then return nil end
        local fl = pg:FindFirstChild('FriendsList')
        if not fl then return nil end
        local f2 = fl:FindFirstChild('2')
        if not f2 then return nil end
        local img = f2:FindFirstChild('1')
        if not img then return nil end
        local scroll = img:FindFirstChild('AutoCanvasScrollingFrame')
        if not scroll then return nil end
        for _, row in scroll:GetChildren() do
            if row.Name == 'PlayerRow' then
                local nc = row:FindFirstChild('PlayerNameContainer')
                if nc then
                    local nf = nc:FindFirstChild('2')
                    if nf then
                        local ul = nf:FindFirstChild('3')
                        if ul and ul:IsA('TextLabel') and ul.Text:gsub('^@',''):lower() == username:lower() then
                            local sf = nc:FindFirstChild('3')
                            if sf then
                                local sl = sf:FindFirstChild('2')
                                return (sl and sl.Text) or ''
                            end
                            return ''
                        end
                    end
                end
            end
        end
        return nil
    end

    local function getPresence(userId)
        if pl:GetPlayerByUserId(userId) then
            return 'BedWars Lobby (same server)', 'lobby', nil
        end
        local req = (syn and syn.request) or request or http_request
        local ok, res = pcall(req, {
            Url    = 'https://presence.roblox.com/v1/presence/users',
            Method = 'POST',
            Headers = { ['Content-Type'] = 'application/json' },
            Body   = hs:JSONEncode({ userIds = { userId } }),
        })
        if not ok or not res or res.StatusCode ~= 200 then return nil, nil, 'API error' end
        local d = hs:JSONDecode(res.Body)
        local p = d.userPresences and d.userPresences[1]
        if not p then return nil, nil, 'No data' end
        local t   = p.userPresenceType
        local loc = (p.lastLocation or ''):match('^%s*(.-)%s*$')
        local uni = p.universeId
        if t == 0 then return 'Offline',         'offline', nil end
        if t == 1 then return 'Online (website)', 'website', nil end
        if t == 3 then return 'In Studio',        'studio',  nil end
        if t == 2 then
            local tok, placeId = pcall(function()
                return cloneref(game:GetService('TeleportService')):GetPlayerPlaceInstanceAsync(userId)
            end)
            placeId = tok and placeId or p.placeId or 0
            if placeId == BEDWARS_LOBBY_PLACE or (uni == BEDWARS_UNIVERSE and placeId == 0) then
                return 'BedWars Lobby', 'lobby', nil
            end
            if placeId == BEDWARS_GAME_PLACE or uni == BEDWARS_UNIVERSE then
                local mode = (loc == '' or loc:lower() == 'bedwars') and 'Game' or loc
                return 'BedWars · ' .. mode, 'game', nil
            end
            return loc ~= '' and loc or 'In Game', 'other', nil
        end
        return 'Unknown', 'offline', nil
    end

    local function getAvatar(userId)
        local req = (syn and syn.request) or request or http_request
        local ok, res = pcall(req, {
            Url    = 'https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=' .. userId .. '&size=150x150&format=Png&isCircular=false',
            Method = 'GET',
        })
        if not ok or not res or res.StatusCode ~= 200 then return nil end
        local ok2, data = pcall(hs.JSONDecode, hs, res.Body)
        if not ok2 or not data or not data.data or not data.data[1] then return nil end
        return data.data[1].imageUrl
    end

    local STATUS_COLORS = {
        lobby   = Color3.fromRGB(80,  180, 255),
        game    = Color3.fromRGB(80,  220, 100),
        offline = Color3.fromRGB(110, 110, 120),
        website = Color3.fromRGB(200, 180, 80),
        other   = Color3.fromRGB(200, 140, 80),
        studio  = Color3.fromRGB(180, 100, 255),
    }

    local function openGui()
        destroyGui()
        local sg = Instance.new('ScreenGui')
        sg.Name           = 'PlayerLookupGui'
        sg.ResetOnSpawn   = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder   = 999
        sg.Parent         = lplr:WaitForChild('PlayerGui')
        _gui = sg

        local shadow = Instance.new('Frame')
        shadow.Size                   = UDim2.fromOffset(354, 234)
        shadow.Position               = UDim2.fromScale(0.5, 0.5)
        shadow.AnchorPoint            = Vector2.new(0.5, 0.5)
        shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.5
        shadow.BorderSizePixel        = 0
        shadow.Parent                 = sg
        Instance.new('UICorner', shadow).CornerRadius = UDim.new(0, 12)

        local card = Instance.new('Frame')
        card.Size             = UDim2.fromOffset(340, 220)
        card.Position         = UDim2.fromScale(0.5, 0.5)
        card.AnchorPoint      = Vector2.new(0.5, 0.5)
        card.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        card.BorderSizePixel  = 0
        card.Parent           = sg
        Instance.new('UICorner', card).CornerRadius = UDim.new(0, 10)

        local accent = Instance.new('Frame')
        accent.Size             = UDim2.new(1, 0, 0, 3)
        accent.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
        accent.BorderSizePixel  = 0
        accent.Parent           = card
        Instance.new('UICorner', accent).CornerRadius = UDim.new(0, 10)
        local acFix = Instance.new('Frame')
        acFix.Size             = UDim2.new(1, 0, 0.5, 0)
        acFix.Position         = UDim2.fromScale(0, 0.5)
        acFix.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
        acFix.BorderSizePixel  = 0
        acFix.Parent           = accent

        local headerLabel = Instance.new('TextLabel')
        headerLabel.Size                = UDim2.new(1, -44, 0, 32)
        headerLabel.Position            = UDim2.fromOffset(14, 10)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Text                = 'Player Lookup'
        headerLabel.TextColor3          = Color3.fromRGB(230, 230, 230)
        headerLabel.TextSize            = 15
        headerLabel.Font                = Enum.Font.GothamBold
        headerLabel.TextXAlignment      = Enum.TextXAlignment.Left
        headerLabel.Parent              = card

        local closeBtn = Instance.new('TextButton')
        closeBtn.Size             = UDim2.fromOffset(26, 26)
        closeBtn.Position         = UDim2.new(1, -36, 0, 10)
        closeBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
        closeBtn.BorderSizePixel  = 0
        closeBtn.Text             = '✕'
        closeBtn.TextColor3       = Color3.fromRGB(200, 70, 70)
        closeBtn.TextSize         = 12
        closeBtn.Font             = Enum.Font.GothamBold
        closeBtn.Parent           = card
        Instance.new('UICorner', closeBtn).CornerRadius = UDim.new(0, 5)
        closeBtn.MouseButton1Click:Connect(destroyGui)

        local div = Instance.new('Frame')
        div.Size             = UDim2.new(1, -28, 0, 1)
        div.Position         = UDim2.fromOffset(14, 46)
        div.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
        div.BorderSizePixel  = 0
        div.Parent           = card

        local searchBox = Instance.new('TextBox')
        searchBox.Size              = UDim2.new(1, -100, 0, 36)
        searchBox.Position          = UDim2.fromOffset(14, 56)
        searchBox.BackgroundColor3  = Color3.fromRGB(24, 24, 32)
        searchBox.BorderSizePixel   = 0
        searchBox.PlaceholderText   = 'Enter username...'
        searchBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
        searchBox.Text              = ''
        searchBox.TextColor3        = Color3.fromRGB(220, 220, 230)
        searchBox.TextSize          = 14
        searchBox.Font              = Enum.Font.Gotham
        searchBox.ClearTextOnFocus  = false
        searchBox.Parent            = card
        Instance.new('UICorner', searchBox).CornerRadius = UDim.new(0, 7)
        local sbp = Instance.new('UIPadding', searchBox); sbp.PaddingLeft = UDim.new(0, 10)

        local searchBtn = Instance.new('TextButton')
        searchBtn.Size             = UDim2.fromOffset(76, 36)
        searchBtn.Position         = UDim2.new(1, -90, 0, 56)
        searchBtn.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
        searchBtn.BorderSizePixel  = 0
        searchBtn.Text             = 'Search'
        searchBtn.TextColor3       = Color3.new(1, 1, 1)
        searchBtn.TextSize         = 13
        searchBtn.Font             = Enum.Font.GothamBold
        searchBtn.Parent           = card
        Instance.new('UICorner', searchBtn).CornerRadius = UDim.new(0, 7)

        local resultCard = Instance.new('Frame')
        resultCard.Size             = UDim2.new(1, -28, 0, 104)
        resultCard.Position         = UDim2.fromOffset(14, 104)
        resultCard.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        resultCard.BorderSizePixel  = 0
        resultCard.Visible          = false
        resultCard.Parent           = card
        Instance.new('UICorner', resultCard).CornerRadius = UDim.new(0, 8)

        local statusBar = Instance.new('Frame')
        statusBar.Size             = UDim2.fromOffset(3, 60)
        statusBar.Position         = UDim2.fromOffset(10, 18)
        statusBar.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
        statusBar.BorderSizePixel  = 0
        statusBar.Parent           = resultCard
        Instance.new('UICorner', statusBar).CornerRadius = UDim.new(0, 2)

        local avatarImg = Instance.new('ImageLabel')
        avatarImg.Size             = UDim2.fromOffset(60, 60)
        avatarImg.Position         = UDim2.fromOffset(18, 18)
        avatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        avatarImg.BorderSizePixel  = 0
        avatarImg.Image            = ''
        avatarImg.Parent           = resultCard
        Instance.new('UICorner', avatarImg).CornerRadius = UDim.new(0, 6)

        local nameLabel = Instance.new('TextLabel')
        nameLabel.Size                = UDim2.new(1, -92, 0, 22)
        nameLabel.Position            = UDim2.fromOffset(88, 16)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text                = ''
        nameLabel.TextColor3          = Color3.fromRGB(230, 230, 230)
        nameLabel.TextSize            = 15
        nameLabel.Font                = Enum.Font.GothamBold
        nameLabel.TextXAlignment      = Enum.TextXAlignment.Left
        nameLabel.TextTruncate        = Enum.TextTruncate.AtEnd
        nameLabel.Parent              = resultCard

        local statusLabel = Instance.new('TextLabel')
        statusLabel.Size                = UDim2.new(1, -92, 0, 20)
        statusLabel.Position            = UDim2.fromOffset(88, 40)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text                = ''
        statusLabel.TextColor3          = Color3.fromRGB(160, 160, 170)
        statusLabel.TextSize            = 13
        statusLabel.Font                = Enum.Font.Gotham
        statusLabel.TextXAlignment      = Enum.TextXAlignment.Left
        statusLabel.TextTruncate        = Enum.TextTruncate.AtEnd
        statusLabel.Parent              = resultCard

        local hintLabel = Instance.new('TextLabel')
        hintLabel.Size                = UDim2.new(1, -92, 0, 14)
        hintLabel.Position            = UDim2.fromOffset(88, 62)
        hintLabel.BackgroundTransparency = 1
        hintLabel.Text                = ''
        hintLabel.TextColor3          = Color3.fromRGB(90, 90, 105)
        hintLabel.TextSize            = 11
        hintLabel.Font                = Enum.Font.Gotham
        hintLabel.TextXAlignment      = Enum.TextXAlignment.Left
        hintLabel.Parent              = resultCard

        local spectateBtn = Instance.new('TextButton')
        spectateBtn.Size             = UDim2.fromOffset(100, 22)
        spectateBtn.Position         = UDim2.fromOffset(88, 78)
        spectateBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 80)
        spectateBtn.BorderSizePixel  = 0
        spectateBtn.Text             = '▶  Join'
        spectateBtn.TextColor3       = Color3.new(1, 1, 1)
        spectateBtn.TextSize         = 11
        spectateBtn.Font             = Enum.Font.GothamBold
        spectateBtn.Visible          = false
        spectateBtn.Parent           = resultCard
        Instance.new('UICorner', spectateBtn).CornerRadius = UDim.new(0, 5)

        local statusMsg = Instance.new('TextLabel')
        statusMsg.Size                = UDim2.new(1, -28, 0, 96)
        statusMsg.Position            = UDim2.fromOffset(14, 104)
        statusMsg.BackgroundTransparency = 1
        statusMsg.Text                = ''
        statusMsg.TextColor3          = Color3.fromRGB(150, 150, 160)
        statusMsg.TextSize            = 13
        statusMsg.Font                = Enum.Font.Gotham
        statusMsg.TextWrapped         = true
        statusMsg.Visible             = false
        statusMsg.Parent              = card

        local _searching = false
        local _specConn  = nil

        local function doSearch()
            if _searching then return end
            local name = searchBox.Text:match('^%s*(.-)%s*$')
            if name == '' then return end
            _searching = true
            resultCard.Visible = false
            statusMsg.Visible  = true
            statusMsg.Text     = 'Looking up "' .. name .. '"...'
            statusMsg.TextColor3 = Color3.fromRGB(150, 150, 160)
            searchBtn.BackgroundColor3 = Color3.fromRGB(40, 65, 140)

            task.spawn(function()
                local ok, userId = pcall(function() return pl:GetUserIdFromNameAsync(name) end)
                if not ok or not userId then
                    statusMsg.Text     = '✕  Player "' .. name .. '" not found.'
                    statusMsg.TextColor3 = Color3.fromRGB(220, 70, 70)
                    _searching = false
                    searchBtn.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
                    return
                end

                local friendGM = getFriendGamemode(name)
                local status, statusKey, err

                if friendGM ~= nil then
                    local gm = friendGM:match('^%s*(.-)%s*$')
                    if gm == '' or gm:upper() == 'LOBBY' then
                        status, statusKey = 'BedWars Lobby', 'lobby'
                    else
                        status, statusKey = 'BedWars · ' .. gm, 'game'
                    end
                else
                    status, statusKey, err = getPresence(userId)
                    if not status then
                        statusMsg.Text     = '✕  ' .. tostring(err)
                        statusMsg.TextColor3 = Color3.fromRGB(220, 70, 70)
                        _searching = false
                        searchBtn.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
                        return
                    end
                end

                local col = STATUS_COLORS[statusKey] or Color3.fromRGB(160, 160, 160)
                statusBar.BackgroundColor3 = col
                nameLabel.Text   = name
                statusLabel.Text = status
                statusLabel.TextColor3 = col

                local noMode = statusKey == 'other' or (statusKey == 'game' and status:find('· Game'))
                hintLabel.Text = (friendGM == nil and noMode) and 'Open Social › Friends for exact mode' or ''

                if _specConn then pcall(function() _specConn:Disconnect() end); _specConn = nil end
                spectateBtn.Visible = statusKey == 'lobby' or statusKey == 'game'
                if statusKey == 'lobby' then
                    spectateBtn.Text = '▶  Join Lobby'
                    spectateBtn.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
                    _specConn = spectateBtn.MouseButton1Click:Connect(function()
                        pcall(function() bedwars.Client:Get('JoinFriend'):SendToServer(userId) end)
                    end)
                elseif statusKey == 'game' then
                    spectateBtn.Text = '▶  Spectate'
                    spectateBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 80)
                    _specConn = spectateBtn.MouseButton1Click:Connect(function()
                        pcall(function() bedwars.Client:Get('SpectatePlayer'):SendToServer(userId) end)
                    end)
                end

                avatarImg.Image = ''
                task.spawn(function()
                    local url = getAvatar(userId)
                    if url and avatarImg and avatarImg.Parent then avatarImg.Image = url end
                end)

                statusMsg.Visible  = false
                resultCard.Visible = true
                _searching = false
                searchBtn.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
            end)
        end

        searchBtn.MouseButton1Click:Connect(doSearch)
        searchBox.FocusLost:Connect(function(enter) if enter then doSearch() end end)
    end

    local PlayerLookup
    PlayerLookup = vape.Categories.Utility:CreateModule({
        Name    = 'Player Lookup',
        Tooltip = 'Search any player to see if they are in BedWars lobby, which game mode, or offline',
        Function = function(callback)
            if callback then
                openGui()
            else
                destroyGui()
            end
        end
    })
end)
