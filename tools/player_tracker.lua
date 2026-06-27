-- Player Tracker — standalone, works in any game / Bedwars lobby
-- Inject this with your executor. Add usernames, toggle on, watch status update.

local BEDWARS_LOBBY = 6872265039  -- lobby place id (root/entry of the universe)
local BEDWARS_GAME  = 6872274481  -- in-game place id

local Players    = game:GetService('Players')
local HttpSvc    = game:GetService('HttpService')
local UserInput  = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local CoreGui    = game:GetService('CoreGui')

local lplr = Players.LocalPlayer

-- ── HTTP helpers ────────────────────────────────────────────────────────────

local req = request or (syn and syn.request) or http_request or nil

local function getCookie()
    local c = ''
    pcall(function() c = getcookies()['.ROBLOSECURITY'] or '' end)
    if c ~= '' then return c end
    pcall(function() c = syn.get_cookie('.ROBLOSECURITY') or '' end)
    if c ~= '' then return c end
    pcall(function() c = (getrbxauth and getrbxauth()) or '' end)
    return c
end

local function httpPost(url, body)
    if not req then return nil end
    local cookie = getCookie()
    local opts = {
        Url     = url,
        Method  = 'POST',
        Headers = { ['Content-Type'] = 'application/json' },
        Body    = body,
    }
    if cookie ~= '' then opts.Headers['Cookie'] = '.ROBLOSECURITY=' .. cookie end
    local ok, r = pcall(req, opts)
    return (ok and r) or nil
end

local function jsonDecode(s)
    local ok, r = pcall(function() return HttpSvc:JSONDecode(s) end)
    return ok and r or nil
end

-- ── Roblox API ──────────────────────────────────────────────────────────────

local userIdCache = {}  -- name → id

local function getUserId(name)
    local key = name:lower()
    if userIdCache[key] then return userIdCache[key] end
    local r = httpPost(
        'https://users.roblox.com/v1/usernames/users',
        HttpSvc:JSONEncode({ usernames = { name }, excludeBannedUsers = false })
    )
    if not r or r.StatusCode ~= 200 then return nil end
    local d = jsonDecode(r.Body)
    if not d or not d.data or #d.data == 0 then return nil end
    userIdCache[key] = d.data[1].id
    return d.data[1].id
end

local STATUS = {
    OFFLINE   = { text = 'Offline',    color = Color3.fromRGB(90,  90,  90)  },
    ONLINE    = { text = 'Online',     color = Color3.fromRGB(100, 200, 255) },
    LOBBY     = { text = 'Lobby',      color = Color3.fromRGB(255, 200, 60)  },
    INGAME    = { text = 'In Game',    color = Color3.fromRGB(80,  220, 80)  },
    OTHER     = { text = 'Other Game', color = Color3.fromRGB(200, 100, 255) },
    ERROR     = { text = 'Error',      color = Color3.fromRGB(150, 80,  80)  },
}

local function getStatus(name)
    local id = getUserId(name)
    if not id then return STATUS.ERROR end
    local r = httpPost(
        'https://presence.roblox.com/v1/presence/users',
        HttpSvc:JSONEncode({ userIds = { id } })
    )
    if not r or r.StatusCode ~= 200 then return STATUS.ERROR end
    local d = jsonDecode(r.Body)
    if not d or not d.userPresences or #d.userPresences == 0 then return STATUS.ERROR end
    local p = d.userPresences[1]
    local pt = p.userPresenceType
    if pt == 0 then return STATUS.OFFLINE end
    if pt == 1 then return STATUS.ONLINE  end
    if pt == 2 then
        local root  = p.rootPlaceId
        local place = p.placeId
        local loc   = (p.lastLocation or ''):match('^%s*(.-)%s*$')

        if root == BEDWARS_LOBBY or root == BEDWARS_GAME then
            if place == BEDWARS_LOBBY then return STATUS.LOBBY end
            if loc ~= '' and loc:lower() ~= 'bedwars' then
                return { text = loc, color = STATUS.INGAME.color }
            end
            return STATUS.INGAME
        end

        -- IDs don't match — show lastLocation so we can see what Roblox reports,
        -- plus the rootPlaceId so we can fix the constants above.
        local display = loc ~= '' and (loc .. ' [' .. tostring(root) .. ']') or ('root:' .. tostring(root))
        return { text = display, color = STATUS.OTHER.color }
    end
    return STATUS.ERROR
end

-- ── GUI ─────────────────────────────────────────────────────────────────────

-- Remove old instance if re-injected
pcall(function()
    local old = CoreGui:FindFirstChild('PTTrackerGui')
    if old then old:Destroy() end
end)

local gui = Instance.new('ScreenGui')
gui.Name            = 'PTTrackerGui'
gui.ResetOnSpawn    = false
gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset  = true
gui.Parent          = CoreGui

-- Main panel
local panel = Instance.new('Frame')
panel.Size              = UDim2.fromOffset(220, 36)
panel.Position          = UDim2.fromOffset(20, 80)
panel.BackgroundColor3  = Color3.fromRGB(10, 10, 10)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel   = 0
panel.AutomaticSize     = Enum.AutomaticSize.Y
panel.Parent            = gui
Instance.new('UICorner', panel).CornerRadius = UDim.new(0, 8)
local panelStroke = Instance.new('UIStroke', panel)
panelStroke.Color     = Color3.fromRGB(60, 60, 60)
panelStroke.Thickness = 1

local layout = Instance.new('UIListLayout', panel)
layout.Padding    = UDim.new(0, 0)
layout.SortOrder  = Enum.SortOrder.LayoutOrder
local pad = Instance.new('UIPadding', panel)
pad.PaddingLeft   = UDim.new(0, 8)
pad.PaddingRight  = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 6)

-- Title bar (also drag handle)
local titleBar = Instance.new('Frame')
titleBar.Size             = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundTransparency = 1
titleBar.LayoutOrder      = 0
titleBar.Parent           = panel

local title = Instance.new('TextLabel')
title.Size                = UDim2.new(1, -28, 1, 0)
title.BackgroundTransparency = 1
title.Text                = 'Player Tracker'
title.TextColor3          = Color3.new(1, 1, 1)
title.TextSize            = 13
title.Font                = Enum.Font.GothamBold
title.TextXAlignment      = Enum.TextXAlignment.Left
title.Parent              = titleBar

local closeBtn = Instance.new('TextButton')
closeBtn.Size             = UDim2.fromOffset(20, 20)
closeBtn.Position         = UDim2.new(1, -20, 0.5, -10)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.BorderSizePixel  = 0
closeBtn.Text             = '×'
closeBtn.TextColor3       = Color3.new(1, 1, 1)
closeBtn.TextSize         = 14
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.Parent           = titleBar
Instance.new('UICorner', closeBtn).CornerRadius = UDim.new(0, 4)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Input row
local inputRow = Instance.new('Frame')
inputRow.Size             = UDim2.new(1, 0, 0, 26)
inputRow.BackgroundTransparency = 1
inputRow.LayoutOrder      = 1
inputRow.Parent           = panel

local textBox = Instance.new('TextBox')
textBox.Size              = UDim2.new(1, -54, 1, 0)
textBox.BackgroundColor3  = Color3.fromRGB(25, 25, 25)
textBox.BorderSizePixel   = 0
textBox.PlaceholderText   = 'username…'
textBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
textBox.Text              = ''
textBox.TextColor3        = Color3.new(1, 1, 1)
textBox.TextSize          = 11
textBox.Font              = Enum.Font.Gotham
textBox.ClearTextOnFocus  = false
textBox.Parent            = inputRow
Instance.new('UICorner', textBox).CornerRadius = UDim.new(0, 5)

local addBtn = Instance.new('TextButton')
addBtn.Size               = UDim2.fromOffset(48, 26)
addBtn.Position           = UDim2.new(1, -48, 0, 0)
addBtn.BackgroundColor3   = Color3.fromRGB(40, 160, 90)
addBtn.BorderSizePixel    = 0
addBtn.Text               = 'Add'
addBtn.TextColor3         = Color3.new(1, 1, 1)
addBtn.TextSize           = 11
addBtn.Font               = Enum.Font.GothamBold
addBtn.Parent             = inputRow
Instance.new('UICorner', addBtn).CornerRadius = UDim.new(0, 5)

-- Player rows container
local listContainer = Instance.new('Frame')
listContainer.Size             = UDim2.new(1, 0, 0, 0)
listContainer.BackgroundTransparency = 1
listContainer.AutomaticSize   = Enum.AutomaticSize.Y
listContainer.LayoutOrder     = 2
listContainer.Parent          = panel
local listLayout = Instance.new('UIListLayout', listContainer)
listLayout.Padding   = UDim.new(0, 2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ── Drag logic ──────────────────────────────────────────────────────────────

local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = inp.Position
        startPos  = panel.Position
    end
end)
UserInput.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        panel.Position = UDim2.fromOffset(
            startPos.X.Offset + delta.X,
            startPos.Y.Offset + delta.Y
        )
    end
end)
UserInput.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ── Player row management ────────────────────────────────────────────────────

local tracked   = {}   -- ordered list of names
local rowFrames = {}   -- name → { frame, dot, nameLabel, statusLabel, removeBtn }
local lastStatuses = {}

local function makeRow(name, order)
    local row = Instance.new('Frame')
    row.Size              = UDim2.new(1, 0, 0, 22)
    row.BackgroundColor3  = Color3.fromRGB(20, 20, 20)
    row.BorderSizePixel   = 0
    row.LayoutOrder       = order
    row.Parent            = listContainer
    Instance.new('UICorner', row).CornerRadius = UDim.new(0, 5)

    local dot = Instance.new('Frame')
    dot.Size              = UDim2.fromOffset(7, 7)
    dot.Position          = UDim2.new(0, 6, 0.5, -3)
    dot.BackgroundColor3  = Color3.fromRGB(100, 100, 100)
    dot.BorderSizePixel   = 0
    dot.Parent            = row
    Instance.new('UICorner', dot).CornerRadius = UDim.new(1, 0)

    local nameLbl = Instance.new('TextLabel')
    nameLbl.Size              = UDim2.new(0.5, -14, 1, 0)
    nameLbl.Position          = UDim2.fromOffset(18, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text              = name
    nameLbl.TextColor3        = Color3.new(1, 1, 1)
    nameLbl.TextSize          = 10
    nameLbl.Font              = Enum.Font.Gotham
    nameLbl.TextXAlignment    = Enum.TextXAlignment.Left
    nameLbl.TextTruncate      = Enum.TextTruncate.AtEnd
    nameLbl.Parent            = row

    local statusLbl = Instance.new('TextLabel')
    statusLbl.Size              = UDim2.new(0.5, -20, 1, 0)
    statusLbl.Position          = UDim2.new(0.5, 0, 0, 0)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text              = '…'
    statusLbl.TextColor3        = Color3.fromRGB(130, 130, 130)
    statusLbl.TextSize          = 10
    statusLbl.Font              = Enum.Font.Gotham
    statusLbl.TextXAlignment    = Enum.TextXAlignment.Left
    statusLbl.Parent            = row

    local removeBtn = Instance.new('TextButton')
    removeBtn.Size              = UDim2.fromOffset(16, 16)
    removeBtn.Position          = UDim2.new(1, -18, 0.5, -8)
    removeBtn.BackgroundColor3  = Color3.fromRGB(140, 40, 40)
    removeBtn.BorderSizePixel   = 0
    removeBtn.Text              = '−'
    removeBtn.TextColor3        = Color3.new(1, 1, 1)
    removeBtn.TextSize          = 12
    removeBtn.Font              = Enum.Font.GothamBold
    removeBtn.Parent            = row
    Instance.new('UICorner', removeBtn).CornerRadius = UDim.new(0, 4)

    removeBtn.MouseButton1Click:Connect(function()
        local idx = table.find(tracked, name)
        if idx then table.remove(tracked, idx) end
        lastStatuses[name] = nil
        rowFrames[name] = nil
        row:Destroy()
    end)

    rowFrames[name] = { frame = row, dot = dot, status = statusLbl }
end

local function addPlayer(name)
    name = name:match('^%s*(.-)%s*$')  -- trim
    if name == '' or table.find(tracked, name) then return end
    table.insert(tracked, name)
    makeRow(name, #tracked)
end

addBtn.MouseButton1Click:Connect(function()
    addPlayer(textBox.Text)
    textBox.Text = ''
end)
textBox.FocusLost:Connect(function(enter)
    if enter then
        addPlayer(textBox.Text)
        textBox.Text = ''
    end
end)

-- ── Refresh loop ─────────────────────────────────────────────────────────────

local REFRESH_INTERVAL = 30

task.spawn(function()
    while gui.Parent do
        for _, name in ipairs(tracked) do
            if not gui.Parent then break end
            local r = rowFrames[name]
            if not r then continue end

            r.status.Text      = '…'
            r.dot.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

            local s = getStatus(name)
            if not rowFrames[name] then continue end  -- removed while fetching

            r.status.Text      = s.text
            r.dot.BackgroundColor3 = s.color
            r.status.TextColor3   = s.color

            local prev = lastStatuses[name]
            if prev and prev ~= s.text then
                local wasInGame = prev ~= 'Offline' and prev ~= 'Online' and prev ~= 'Lobby' and prev ~= 'Other Game' and prev ~= 'Error'
                local nowInGame = s.text ~= 'Offline' and s.text ~= 'Online' and s.text ~= 'Lobby' and s.text ~= 'Other Game' and s.text ~= 'Error'
                local msg
                if s.text == 'Lobby' and prev ~= 'Lobby' then
                    msg = name .. ' is in Lobby'
                elseif nowInGame and not wasInGame then
                    msg = name .. ' joined ' .. s.text
                elseif nowInGame and wasInGame then
                    msg = name .. ' → ' .. s.text  -- mode switched
                elseif s.text == 'Offline' and prev ~= 'Offline' then
                    msg = name .. ' went offline'
                end
                if msg then
                    -- Simple toast notification via ScreenGui
                    task.spawn(function()
                        local toast = Instance.new('TextLabel')
                        toast.Size             = UDim2.fromOffset(240, 28)
                        toast.Position         = UDim2.new(0.5, -120, 0, 60)
                        toast.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                        toast.BackgroundTransparency = 0.1
                        toast.BorderSizePixel  = 0
                        toast.Text             = '🔔 ' .. msg
                        toast.TextColor3       = Color3.new(1, 1, 1)
                        toast.TextSize         = 11
                        toast.Font             = Enum.Font.Gotham
                        toast.Parent           = gui
                        Instance.new('UICorner', toast).CornerRadius = UDim.new(0, 6)
                        task.wait(4)
                        toast:Destroy()
                    end)
                end
            end
            lastStatuses[name] = s.text

            task.wait(0.2)  -- small gap between fetches so we don't blast the API
        end

        local elapsed = 0
        while elapsed < REFRESH_INTERVAL and gui.Parent do
            task.wait(1)
            elapsed += 1
        end
    end
end)
