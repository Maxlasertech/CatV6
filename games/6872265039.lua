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
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
		Flamework = Flamework
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
    Render
]]

run(function()
    run(function()
        local NametagSpoofer
        local NameBox
        local ClanBox
        local LevelBox
        local WinstreakBox
        local RankDrop

        local TIER_BASE = {Bronze = 0, Silver = 4, Gold = 8, Platinum = 12, Diamond = 16, Emerald = 20}
        local NIGHTMARE_DIVISION = 24
        local GRADIENT_NAME = 'SpooferLevelGradient'

        local PlayerLevelUtil
        local function getPLU()
            if PlayerLevelUtil then return PlayerLevelUtil end
            local ok, res = pcall(function()
                return require(replicatedStorage.TS['player-level']['player-level-util']).PlayerLevelUtil
            end)
            if ok then PlayerLevelUtil = res end
            return PlayerLevelUtil
        end

        local RankMeta
        local function getRankMeta()
            if RankMeta then return RankMeta end
            local ok, res = pcall(function()
                return require(replicatedStorage.TS.rank['rank-meta']).RankMeta
            end)
            if ok then RankMeta = res end
            return RankMeta
        end

        local function trim(s)
            return (s or ''):match('^%s*(.-)%s*$')
        end

        local function applyLevelColour(label, level, plu)
            local ok, col = pcall(plu.getLevelColor, level)
            if ok and typeof(col) == 'Color3' then
                label.TextColor3 = col
            end
            local meta
            local ok2, m = pcall(plu.getLevelMeta, level)
            if ok2 and type(m) == 'table' then meta = m end
            local grad = label:FindFirstChild(GRADIENT_NAME)
            if meta and typeof(meta.gradient) == 'ColorSequence' then
                if not grad then
                    grad = Instance.new('UIGradient')
                    grad.Name = GRADIENT_NAME
                    grad.Parent = label
                end
                grad.Color = meta.gradient
            elseif grad then
                grad:Destroy()
            end
        end

        local function clearGradient(label)
            local grad = label:FindFirstChild(GRADIENT_NAME)
            if grad then grad:Destroy() end
        end

        local function resolve(plr)
            local ok, t = pcall(function()
                local n = plr.Character.Head.Nametag
                local wsc = n:FindFirstChild('WinStreakCounter')
                return {
                    level = n.PlayerLevel,
                    name = n.DisplayNameContainer.DisplayName,
                    rankIcon = n.RankDisplay,
                    win = wsc and wsc:FindFirstChild('WinStreakValue')
                }
            end)
            return ok and t or nil
        end

        local orig
        local function capture(t)
            if orig then return end
            orig = {
                levelText = t.level.Text,
                levelColor = t.level.TextColor3,
                nameText = t.name.Text,
                icon = t.rankIcon.Image,
                win = t.win and t.win.Text
            }
            orig.name = t.name.Text:match('<b>(.-)</b>') or ''
            orig.clan = t.name.Text:match('%[(.-)%]')
        end

        local function apply(plr)
            if not NametagSpoofer.Enabled then return end
            local t = resolve(plr)
            if not t then return end
            capture(t)

            local nameVal = trim(NameBox.Value)
            local clanVal = trim(ClanBox.Value)
            local finalName = nameVal ~= '' and nameVal or orig.name
            local finalClan = clanVal ~= '' and clanVal or orig.clan
            if finalClan and finalClan ~= '' then
                t.name.Text = '<font color="rgb(219,219,219)">[' .. finalClan .. ']</font> <b>' .. finalName .. '</b>'
            else
                t.name.Text = '<b>' .. finalName .. '</b>'
            end

            --[[local lvStr = trim(LevelBox.Value)
            local lvNum = tonumber(lvStr)
            local plu = getPLU()
            if lvStr ~= '' and lvNum and plu then
                t.level.Text = '(' .. math.floor(lvNum) .. ') '
                applyLevelColour(t.level, math.floor(lvNum), plu)
            else
                t.level.Text = orig.levelText
                t.level.TextColor3 = orig.levelColor
                clearGradient(t.level)
            end

            if t.win then
                local wsVal = trim(WinstreakBox.Value)
                t.win.Text = wsVal ~= '' and wsVal or (orig.win or t.win.Text)
            end

            local tier = RankDrop.Value
            if tier ~= 'Off' then
                local rm = getRankMeta()
                if rm then
                    local division = tier == 'Nightmare' and NIGHTMARE_DIVISION or TIER_BASE[tier]
                    local meta = division and rm[division]
                    if meta then t.rankIcon.Image = meta.image end
                end
            else
                t.rankIcon.Image = orig.icon
            end]]
        end

        local function revert()
            local t = resolve()
            if t and orig then
                pcall(function()
                    t.level.Text = orig.levelText
                    t.level.TextColor3 = orig.levelColor
                    clearGradient(t.level)
                    t.name.Text = orig.nameText
                    t.rankIcon.Image = orig.icon
                    if t.win and orig.win then t.win.Text = orig.win end
                end)
            end
            orig = nil
        end

        NametagSpoofer = vape.Categories.Minigames:CreateModule({
            Name = 'Nametag Spoofer',
            Function = function(callback)
                if callback then
                    orig = nil
                    NametagSpoofer:Clean(game.RunService.RenderStepped:Connect(function()
                        for _, v in playersService:GetPlayers() do
                            apply(v)
                        end
                    end))
                    NametagSpoofer:Clean(revert)
                end
            end,
            Tooltip = 'spoofs the nametag above your head.'
        })

        NameBox = NametagSpoofer:CreateTextBox({
            Name = 'Display Name',
            Placeholder = 'Display name'
        })
        ClanBox = NametagSpoofer:CreateTextBox({
            Name = 'Clan',
            Placeholder = 'Clan tag (no brackets)'
        })
        LevelBox = NametagSpoofer:CreateTextBox({
            Name = 'Level',
            Placeholder = 'e.g. 1000 (dev gradient)'
        })
        WinstreakBox = NametagSpoofer:CreateTextBox({
            Name = 'Winstreak',
            Placeholder = 'Winstreak'
        })
        RankDrop = NametagSpoofer:CreateDropdown({
            Name = 'Rank',
            List = {'Off', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Emerald', 'Nightmare'},
            Default = 'Off'
        })
    end)

    run(function()
        local Spoofer
        local NameBox
        local LevelBox
        local XPBox
        local RankDrop
        local RankGroupDrop
        local RankNameBox
        local LeaderboardBox
        local RPBox
        local WinsBox
        local BedsBox
        local FinalsBox
        local HonorBox

        local TIER_BASE = {Bronze = 0, Silver = 4, Gold = 8, Platinum = 12, Diamond = 16, Emerald = 20}
        local NIGHTMARE_DIVISION = 24
        local GRADIENT_NAME = 'SpooferLevelGradient'

        local PlayerLevelUtil
        local function getPLU()
            if PlayerLevelUtil then return PlayerLevelUtil end
            local ok, res = pcall(function()
                return require(replicatedStorage.TS['player-level']['player-level-util']).PlayerLevelUtil
            end)
            if ok then PlayerLevelUtil = res end
            return PlayerLevelUtil
        end

        local RankMeta
        local function getRankMeta()
            if RankMeta then return RankMeta end
            local ok, res = pcall(function()
                return require(replicatedStorage.TS.rank['rank-meta']).RankMeta
            end)
            if ok then RankMeta = res end
            return RankMeta
        end

        local function trim(s)
            return (s or ''):match('^%s*(.-)%s*$')
        end

        local function digits(s)
            local out = {}
            for n in s:gmatch('%d[%d,]*') do
                out[#out + 1] = tonumber((n:gsub(',', '')))
            end
            return out
        end

        local function esc(s)
            return (s:gsub('%%', '%%%%'))
        end

        local function applyLevelColour(label, level, plu)
            local ok, col = pcall(plu.getLevelColor, level)
            if ok and typeof(col) == 'Color3' then
                label.TextColor3 = col
            end
            local meta
            local ok2, m = pcall(plu.getLevelMeta, level)
            if ok2 and type(m) == 'table' then meta = m end
            local grad = label:FindFirstChild(GRADIENT_NAME)
            if meta and typeof(meta.gradient) == 'ColorSequence' then
                if not grad then
                    grad = Instance.new('UIGradient')
                    grad.Name = GRADIENT_NAME
                    grad.Parent = label
                end
                grad.Color = meta.gradient
            elseif grad then
                grad:Destroy()
            end
        end

        local function clearGradient(label)
            local grad = label:FindFirstChild(GRADIENT_NAME)
            if grad then grad:Destroy() end
        end

        local function resolve()
            local ok, t = pcall(function()
                local sf = workspace.Lobby.Boards.StatsBoard.Board.StatsBoard['1']['1']
                local canvas = sf.AutoCanvasScrollingFrame
                local ranked = canvas['4']['3']['3']
                local tab = {
                    title = sf['1']['3'],
                    level = canvas['3']['2'],
                    xpText = canvas['3']['3'],
                    xpFill = canvas['3'].ProgressBar.CurrProgress,
                    rankIcon = canvas['4']['3']['2'],
                    rankName = ranked['2'].RankName,
                    leaderboard = ranked['2'].LeaderboardRank,
                    rpText = ranked['3'].CurrentRP,
                    rpContainer = ranked['3'].ProgressBarContainer,
                    rpFill = ranked['3'].ProgressBarContainer.ProgressBar
                }
                for _, cell in ipairs(canvas['5']['3']['2']:GetChildren()) do
                    if cell:IsA('GuiObject') then
                        local title = cell:FindFirstChild('4')
                        local value = cell:FindFirstChild('5')
                        if title and value then
                            if title.Text == 'Wins' then tab.wins = value
                            elseif title.Text == 'Bed Breaks' then tab.beds = value
                            elseif title.Text == 'Final Kills' then tab.finals = value
                            elseif title.Text == 'Honor' then tab.honor = value end
                        end
                    end
                end
                return tab
            end)
            return ok and t or nil
        end

        local orig
        local function capture(t)
            if orig then return end
            orig = {
                title = t.title.Text,
                level = t.level.Text,
                levelColor = t.level.TextColor3,
                xpText = t.xpText.Text,
                xpSize = t.xpFill.Size,
                rankIcon = t.rankIcon.Image,
                rankName = t.rankName.Text,
                leaderboard = t.leaderboard.Text,
                rpText = t.rpText.Text,
                rpSize = t.rpFill.Size,
                rpBarColor = t.rpFill.BackgroundColor3,
                rpVisible = t.rpContainer.Visible,
                rpTextColor = t.rpText.TextColor3,
                rpXAlign = t.rpText.TextXAlignment,
                rpRich = t.rpText.RichText,
                rpFont = t.rpText.FontFace,
                boldFont = t.rankName.FontFace,
                wins = t.wins and t.wins.Text,
                beds = t.beds and t.beds.Text,
                finals = t.finals and t.finals.Text,
                honor = t.honor and t.honor.Text
            }
            orig.xpNums = digits(orig.xpText)
            orig.rpNums = digits(orig.rpText)
        end

        local function setValue(inst, boxValue, original)
            if not inst then return end
            local v = trim(boxValue)
            inst.Text = v ~= '' and v or (original or inst.Text)
        end

        local function selectedRankMeta()
            local tier = RankDrop.Value
            if tier == 'Off' then return nil end
            local rm = getRankMeta()
            if not rm then return nil end
            if tier == 'Nightmare' then
                return rm[NIGHTMARE_DIVISION]
            end
            local base = TIER_BASE[tier]
            if not base then return nil end
            local grp = math.clamp(tonumber(RankGroupDrop.Value) or 1, 1, 4)
            return rm[base + (grp - 1)]
        end

        local function apply()
            if not Spoofer.Enabled then return end
            local t = resolve()
            if not t then return end
            capture(t)

            local nm = trim(NameBox.Value)
            t.title.Text = nm ~= '' and (nm .. "'s Stats") or orig.title

            local lvStr = trim(LevelBox.Value)
            local lvNum = tonumber(lvStr)
            if lvStr ~= '' and lvNum then
                local lv = math.floor(lvNum)
                t.level.Text = 'Player Level ' .. lv
                local plu = getPLU()
                if plu then
                    applyLevelColour(t.level, lv, plu)
                end
            else
                t.level.Text = orig.level
                t.level.TextColor3 = orig.levelColor
                clearGradient(t.level)
            end

            local xpStr = trim(XPBox.Value)
            if xpStr ~= '' then
                local p = digits(xpStr)
                local cur = p[1] or orig.xpNums[1] or 0
                local max = p[2] or orig.xpNums[2] or 0
                t.xpText.Text = tostring(cur) .. ' / ' .. tostring(max)
                t.xpFill.Size = UDim2.new(max > 0 and math.clamp(cur / max, 0, 1) or 0, 0, 1, 0)
            else
                t.xpText.Text = orig.xpText
                t.xpFill.Size = orig.xpSize
            end

            local meta = selectedRankMeta()

            t.rankIcon.Image = meta and meta.image or orig.rankIcon

            local rn = trim(RankNameBox.Value)
            if rn ~= '' then
                t.rankName.Text = rn
            elseif meta then
                t.rankName.Text = meta.name
            else
                t.rankName.Text = orig.rankName
            end

            local lb = trim(LeaderboardBox.Value)
            if lb ~= '' then
                t.leaderboard.Text = orig.leaderboard:gsub('(>)%d[%d,]*(</font>)', '%1' .. esc(lb) .. '%2')
            else
                t.leaderboard.Text = orig.leaderboard
            end

            local noLimit = meta ~= nil and meta.noRPLimit and true or false
            local rpStr = trim(RPBox.Value)
            local rpNums = rpStr ~= '' and digits(rpStr) or {}
            local cur = rpNums[1] or orig.rpNums[1] or 0
            local max = rpNums[2] or orig.rpNums[2] or 0

            if noLimit then
                t.rpText.Text = tostring(cur) .. ' RP'
                t.rpText.RichText = false
                t.rpText.FontFace = orig.boldFont
                t.rpText.TextColor3 = Color3.fromRGB(255, 255, 255)
                t.rpText.TextXAlignment = Enum.TextXAlignment.Left
                t.rpContainer.Visible = false
            else
                local rpBase = orig.rpText:gsub('%s*/%s*[%d,]+%s*$', ''):gsub('(>)%d[%d,]*( RP)', '%1' .. cur .. '%2')
                t.rpText.Text = rpBase .. ' / ' .. max
                t.rpText.RichText = orig.rpRich
                t.rpText.FontFace = orig.rpFont
                t.rpText.TextColor3 = orig.rpTextColor
                t.rpText.TextXAlignment = orig.rpXAlign
                t.rpContainer.Visible = meta and true or orig.rpVisible
                t.rpFill.Size = UDim2.new(max > 0 and math.clamp(cur / max, 0, 1) or 0, 0, 1, 0)
            end
            t.rpFill.BackgroundColor3 = meta and meta.color or orig.rpBarColor

            setValue(t.wins, WinsBox.Value, orig.wins)
            setValue(t.beds, BedsBox.Value, orig.beds)
            setValue(t.finals, FinalsBox.Value, orig.finals)
            setValue(t.honor, HonorBox.Value, orig.honor)
        end

        local function revert()
            local t = resolve()
            if t and orig then
                pcall(function()
                    t.title.Text = orig.title
                    t.level.Text = orig.level
                    t.level.TextColor3 = orig.levelColor
                    clearGradient(t.level)
                    t.xpText.Text = orig.xpText
                    t.xpFill.Size = orig.xpSize
                    t.rankIcon.Image = orig.rankIcon
                    t.rankName.Text = orig.rankName
                    t.leaderboard.Text = orig.leaderboard
                    t.rpText.Text = orig.rpText
                    t.rpText.RichText = orig.rpRich
                    t.rpText.FontFace = orig.rpFont
                    t.rpText.TextColor3 = orig.rpTextColor
                    t.rpText.TextXAlignment = orig.rpXAlign
                    t.rpFill.Size = orig.rpSize
                    t.rpFill.BackgroundColor3 = orig.rpBarColor
                    t.rpContainer.Visible = orig.rpVisible
                    if t.wins and orig.wins then t.wins.Text = orig.wins end
                    if t.beds and orig.beds then t.beds.Text = orig.beds end
                    if t.finals and orig.finals then t.finals.Text = orig.finals end
                    if t.honor and orig.honor then t.honor.Text = orig.honor end
                end)
            end
            orig = nil
        end

        Spoofer = vape.Categories.Minigames:CreateModule({
            Name = 'Spoofer',
            Function = function(callback)
                if callback then
                    orig = nil
                    Spoofer:Clean(runService.RenderStepped:Connect(apply))
                    Spoofer:Clean(revert)
                end
            end,
            Tooltip = 'spoofs the lobby stats board.'
        })

        NameBox = Spoofer:CreateTextBox({
            Name = 'Name',
            Placeholder = 'Name at top'
        })
        LevelBox = Spoofer:CreateTextBox({
            Name = 'Player Level',
            Placeholder = 'e.g. 200 (colours too)'
        })
        XPBox = Spoofer:CreateTextBox({
            Name = 'Level XP',
            Placeholder = 'cur / max e.g. 14807 / 52000'
        })
        RankDrop = Spoofer:CreateDropdown({
            Name = 'Rank',
            List = {'Off', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Emerald', 'Nightmare'},
            Default = 'Off'
        })
        RankGroupDrop = Spoofer:CreateDropdown({
            Name = 'Rank Group',
            List = {'1', '2', '3', '4'},
            Default = '1'
        })
        RankNameBox = Spoofer:CreateTextBox({
            Name = 'Rank Name',
            Placeholder = 'override (blank = auto)'
        })
        LeaderboardBox = Spoofer:CreateTextBox({
            Name = 'Leaderboard Rank',
            Placeholder = 'e.g. 1'
        })
        RPBox = Spoofer:CreateTextBox({
            Name = 'RP',
            Placeholder = 'cur / max e.g. 8 / 100'
        })
        WinsBox = Spoofer:CreateTextBox({
            Name = 'Wins',
            Placeholder = 'Wins'
        })
        BedsBox = Spoofer:CreateTextBox({
            Name = 'Bed Breaks',
            Placeholder = 'Bed Breaks'
        })
        FinalsBox = Spoofer:CreateTextBox({
            Name = 'Final Kills',
            Placeholder = 'Final Kills'
        })
        HonorBox = Spoofer:CreateTextBox({
            Name = 'Honor',
            Placeholder = 'Honor'
        })
    end)

    run(function()
        local TitleSpoofer
        local SeasonDrop

        local NIGHTMARE_COLOR = Color3.fromRGB(252, 70, 170)

        local NIGHTMARE_FONT
        local function getFont()
            if not NIGHTMARE_FONT then
                local f = Font.fromEnum(Enum.Font.Roboto)
                f.Weight = Enum.FontWeight.Bold
                NIGHTMARE_FONT = f
            end
            return NIGHTMARE_FONT
        end

        local function resolve()
            local ok, lt = pcall(function()
                return lplr.Character.Head.Nametag.LobbyTitle
            end)
            return ok and lt or nil
        end

        local orig
        local function capture(lt)
            if orig then return end
            orig = {
                text = lt.Text,
                color = lt.TextColor3,
                font = lt.FontFace,
                visible = lt.Visible
            }
        end

        local function apply()
            if not TitleSpoofer.Enabled then return end
            local lt = resolve()
            if not lt then return end
            capture(lt)

            local text = 'NIGHTMARE (Season ' .. SeasonDrop.Value .. ')'
            if lt.Text ~= text then lt.Text = text end
            if lt.TextColor3 ~= NIGHTMARE_COLOR then lt.TextColor3 = NIGHTMARE_COLOR end
            local font = getFont()
            if lt.FontFace ~= font then lt.FontFace = font end
            if not lt.Visible then lt.Visible = true end
        end

        local function revert()
            local lt = resolve()
            if lt and orig then
                pcall(function()
                    lt.Text = orig.text
                    lt.TextColor3 = orig.color
                    lt.FontFace = orig.font
                    lt.Visible = orig.visible
                end)
            end
            orig = nil
        end

        TitleSpoofer = vape.Categories.Minigames:CreateModule({
            Name = 'Title Spoofer',
            Function = function(callback)
                if callback then
                    orig = nil
                    TitleSpoofer:Clean(runService.RenderStepped:Connect(apply))
                    TitleSpoofer:Clean(revert)
                end
            end,
            Tooltip = 'spoofs the title above your head to a nightmare rank title.'
        })

        SeasonDrop = TitleSpoofer:CreateDropdown({
            Name = 'Season',
            List = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'},
            Default = '15'
        })
    end)
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
    local MatchHistory

    MatchHistory = vape.Categories.Minigames:CreateModule({
        Name = 'Match History',
        Function = function(callback)
            if callback then
                bedwars.Flamework.resolveDependency('client/controllers/app-controller@AppController'):openApp({
                    app = bedwars.ModeratorApp,
                    appId = 'MatchHistoryApp'
                }, {
                    player = lplr,
                    matchHistory = {}
                })
                MatchHistory:Toggle()
            end
        end
    })
end)
