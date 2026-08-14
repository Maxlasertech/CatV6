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
	local function dumpRemote(tab)
		local ind = table.find(tab, 'Client')
		return ind and tab[ind + 1] or ''
	end

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
		Client = Client,
		CrateItemMeta = debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3),
		MilestoneRewards = require(replicatedStorage.TS.milestones.milestones).MilestoneRewards,
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

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

run(function()
	local ClaimRewards
	local CratesOnly
	local Notify
	
	local function getClaimed()
		local claimed = bedwars.MilestonesController.milestoneRewardsClaimed
		if claimed then return claimed end
		local state = bedwars.Store:getState().Bedwars
		return state and state.milestoneRewardsClaimed or {}
	end
	
	ClaimRewards = vape.Categories.Utility:CreateModule({
		Name = 'ClaimRewards',
		Function = function(callback)
			if callback then
				repeat
					local level = bedwars.Store:getState().Bedwars.playerLevel or 0
					local claimed = getClaimed()
	
					for _, reward in bedwars.MilestoneRewards do
						if reward.levelRequirement <= level and not table.find(claimed, reward.id) and (not CratesOnly.Enabled or reward.instantClaim) then
							if bedwars.Client:Get('ClaimMilestoneReward'):CallServer(reward.id) then
								table.insert(claimed, reward.id)
								if Notify.Enabled then
									notif('ClaimRewards', `Claimed {reward.description or reward.id}`, 5)
								end
							end
							task.wait(1)
							if not ClaimRewards.Enabled then break end
						end
					end
	
					task.wait(5)
				until not ClaimRewards.Enabled
			end
		end,
		Tooltip = 'Automatically claims every level milestone reward as soon as you unlock it'
	})
	CratesOnly = ClaimRewards:CreateToggle({
		Name = 'Crates only',
		Tooltip = 'Only claims the instant rewards like the lucky and diamond crates, leaves kits and cosmetics alone'
	})
	Notify = ClaimRewards:CreateToggle({
		Name = 'Notify',
		Default = true,
		Tooltip = 'Tells you what got claimed'
	})
end)

run(function()
	local DeviceSpoofer
	local Device
	local oldDevice, old
	
	DeviceSpoofer = vape.Categories.Utility:CreateModule({
		Name = 'DeviceSpoofer',
		Function = function(callback)
			if callback then
				oldDevice, old = bedwars.UserInputController:getUserInputType(), bedwars.UserInputController.getUserInputType
				bedwars.UserInputController.getUserInputType = function()
					return Device.Value:upper()
				end
				bedwars.Client:Get('SendUserInputType'):SendToServer({userInputType = Device.Value:upper()})
			else
				bedwars.UserInputController.getUserInputType = old
				bedwars.Client:Get('SendUserInputType'):SendToServer({userInputType = oldDevice})
				old = nil
			end
		end,
		Tooltip = 'Spoofs the device you show up as to the server',
		ExtraText = function()
			return Device.Value
		end
	})
	Device = DeviceSpoofer:CreateDropdown({
		Name = 'Device',
		List = {'Mobile', 'PC', 'Gamepad'},
		Function = function(val)
			if DeviceSpoofer.Enabled then
				bedwars.Client:Get('SendUserInputType'):SendToServer({userInputType = val:upper()})
			end
		end
	})
end)

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