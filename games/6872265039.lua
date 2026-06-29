local license = ... or {}
if type(license) ~= 'table' then license = {} end

local canDebug = not license.Closet
local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local sessioninfo = vape.Libraries.sessioninfo
local bedwars = {}

local function notif(...)
	return vape:CreateNotification(...)
end

local LARPKitsDefaultList = {
	'abaddon',
	'adetunde',
	'aery',
	'agni',
	'alchemist',
	'arachne',
	'archer',
	'ares',
	'axolotl_amy',
	'baker',
	'barbarian',
	'beekeeper_beatrix',
	'bekzat',
	'bounty_hunter',
	'builder',
	'caitlyn',
	'cobalt',
	'cogsworth',
	'conqueror',
	'crocowolf',
	'crypt',
	'cyber',
	'death_adder',
	'dino_tamer_dom',
	'drill',
	'eldertree',
	'eldric',
	'elektra',
	'ember',
	'evelynn',
	'farmer_cletus',
	'fisherman',
	'flora',
	'fortuna',
	'freiya',
	'frosty',
	'gingerbread_man',
	'gompy',
	'grim_reaper',
	'grove',
	'hannah',
	'hephaestus',
	'ignis',
	'shielder',
	'isabel',
	'jack',
	'jade',
	'kaida',
	'kaliyah',
	'krystal',
	'lani',
	'lassy',
	'lian',
	'lucia',
	'lumen',
	'lyla',
	'marcel',
	'marina',
	'marrow',
	'martin',
	'melody',
	'merchant_marco',
	'metal_detector',
	'milo',
	'miner',
	'nahla',
	'nazar',
	'noelle',
	'none',
	'nyoka',
	'nyx',
	'pirate_davey',
	'pyro',
	'ragnar',
	'ramil',
	'random',
	'raven',
	'santa',
	'sheep_herder',
	'sheila',
	'sigrid',
	'silas',
	'skoll',
	'smoke',
	'sophia',
	'spirit_catcher',
	'star_collector_stella',
	'styx',
	'taliyah',
	'terra',
	'trapper',
	'trinity',
	'triton',
	'trixie',
	'uma',
	'umbra',
	'umeko',
	'vanessa',
	'void_knight',
	'void_regent',
	'vulcan',
	'warden',
	'warrior',
	'whim',
	'whisper',
	'wizard',
	'wren',
	'xu_rot',
	'yamini',
	'yeti',
	'yuzi',
	'zarrah',
	'zenith',
	'zeno',
	'zephyr',
	'zola'
}

run(function()
	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function()
			return canDebug and debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9) or require(replicatedStorage.rbxts_include.node_modules['@easy-games'].knit.src).KnitClient
		end)
		if KnitInit then break end
		task.wait()
	until KnitInit

	if canDebug and not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end

	local Flamework = require(replicatedStorage.rbxts_include.node_modules['@flamework'].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client

	bedwars = setmetatable({
		AchievementId = require(replicatedStorage.TS.achievement['achievement-id']).AchievementId,
		Client = Client,
		CrateItemMeta = canDebug and debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3) or {},
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

run(function()
	local Sprint
	local oldStopSprinting

	Sprint = vape.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				oldStopSprinting = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local result = oldStopSprinting(...)
					bedwars.SprintController:startSprinting()
					return result
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function()
					bedwars.SprintController:stopSprinting()
				end))
				bedwars.SprintController:stopSprinting()
			elseif oldStopSprinting then
				bedwars.SprintController.stopSprinting = oldStopSprinting
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Keeps sprint enabled in the BedWars lobby.'
	})
end)

run(function()
	local AutoQueue
	local QueueType
	local LeaveParty
	local categories = {}
	local lobbyEvents = replicatedStorage:WaitForChild('events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events')

	AutoQueue = vape.Categories.Utility:CreateModule({
		Name = 'AutoQueue',
		Function = function(callback)
			if callback then
				repeat
					local state = bedwars.Store:getState()
					local partyData = state and state.Party
					local queueType = categories[QueueType.Value]
					if partyData and queueType then
						if partyData.leader and partyData.leader.userId == lplr.UserId then
							if partyData.queueState == 3 and partyData.queueType ~= queueType then
								lobbyEvents.leaveQueue:FireServer()
							elseif partyData.queueState < 2 then
								lobbyEvents.joinQueue:FireServer({queueType = queueType})
								task.wait(1)
							end
						elseif LeaveParty.Enabled then
							lobbyEvents.leaveParty:FireServer()
						end
					end
					task.wait(0.1)
				until not AutoQueue.Enabled
			else
				lobbyEvents.leaveQueue:FireServer()
			end
		end,
		Tooltip = 'Automatically joins a selected BedWars lobby queue.'
	})

	local list = {}
	for id, meta in bedwars.QueueMeta do
		if not meta.disabled and meta.title then
			categories[meta.title] = id
			table.insert(list, meta.title)
		end
	end
	table.sort(list)
	QueueType = AutoQueue:CreateDropdown({
		Name = 'Queue Type',
		List = list,
		Default = table.find(list, 'Duels (2v2)') and 'Duels (2v2)' or list[1]
	})
	LeaveParty = AutoQueue:CreateToggle({
		Name = 'Leave Party',
		Default = true
	})
end)

run(function()
	local LARPKits
	local KitToggles = {}

	LARPKits = vape.Categories.Kits:CreateModule({
		Name = 'LARPKits',
		Function = function() end,
		Tooltip = 'Configures the BedWars lobby kits enabled for LARP.'
	})

	for _, kit in LARPKitsDefaultList do
		KitToggles[kit] = LARPKits:CreateToggle({
			Name = kit,
			Default = true
		})
	end
end)

run(function()
	local WinstreakSpoofer
	local Amount
	local originals = {}
	local pattern = '[Ww]in%s*[Ss]treak'

	local function applyToLabel(label)
		if not (label:IsA('TextLabel') or label:IsA('TextButton')) then return end
		local original = originals[label] or label.Text
		if not original:find(pattern) then return end
		originals[label] = original
		label.Text = original:gsub('%d+', Amount.Value)
	end

	local function applyAll()
		local playerGui = lplr:FindFirstChildOfClass('PlayerGui')
		if not playerGui then return end
		for _, descendant in playerGui:GetDescendants() do
			applyToLabel(descendant)
		end
	end

	local function restoreAll()
		for label, text in originals do
			if label and label.Parent then
				label.Text = text
			end
		end
		table.clear(originals)
	end

	WinstreakSpoofer = vape.Categories.Utility:CreateModule({
		Name = 'WinstreakSpoofer',
		Function = function(callback)
			if callback then
				applyAll()
				local playerGui = lplr:FindFirstChildOfClass('PlayerGui')
				if playerGui then
					WinstreakSpoofer:Clean(playerGui.DescendantAdded:Connect(function(descendant)
						task.defer(applyToLabel, descendant)
					end))
				end
				task.spawn(function()
					repeat
						applyAll()
						task.wait(1)
					until not WinstreakSpoofer.Enabled
				end)
			else
				restoreAll()
			end
		end,
		Tooltip = 'Spoofs visible BedWars lobby winstreak text locally.'
	})
	Amount = WinstreakSpoofer:CreateTextBox({
		Name = 'Amount',
		Default = '0',
		Placeholder = 'Winstreak amount',
		Function = function()
			Amount.Value = tostring(tonumber(Amount.Value) or 0)
			if WinstreakSpoofer.Enabled then
				applyAll()
			end
		end
	})
end)
