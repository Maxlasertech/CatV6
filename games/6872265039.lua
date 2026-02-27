local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local sessioninfo = vape.Libraries.sessioninfo
local bedwars = nil

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
		Client = Client,
		CrateItemMeta = debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3),
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
	local old
	
	Sprint = vape.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = false end) end
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					bedwars.SprintController:startSprinting()
					return call
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() bedwars.SprintController:stopSprinting() end))
				bedwars.SprintController:stopSprinting()
			else
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = true end) end
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.'
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
	
-- aero

run(function()
	local StreamProof
	local originalNames = {}
	local nametagConnection = nil
	
	local function modifyPlayerName(element)
		if element:IsA("TextLabel") and element.Name == "PlayerName" then
			if element.Text:find(lplr.Name) or element.Text:find(lplr.DisplayName) then
				if not originalNames[element] then
					originalNames[element] = element.Text
				end
				element.Text = "Me"
			end
		end
		
		if element:IsA("TextLabel") and element.Name == "EntityName" then
			if element.Text:find(lplr.Name) or element.Text:find(lplr.DisplayName) then
				if not originalNames[element] then
					originalNames[element] = element.Text
				end
				element.Text = "Me"
			end
		end
		
		if element:IsA("TextLabel") and element.Name == "DisplayName" then
			if element.Text:find(lplr.Name) or element.Text:find(lplr.DisplayName) then
				if not originalNames[element] then
					originalNames[element] = element.Text
				end
				element.Text = "Me"
			end
		end
	end
	
	local function restorePlayerName(element)
		if originalNames[element] then
			element.Text = originalNames[element]
			originalNames[element] = nil
		end
	end
	
	local function processGui(gui)
		for _, descendant in gui:GetDescendants() do
			modifyPlayerName(descendant)
		end
	end
	
	local function modifyNametag(character)
		if not character then return end
		
		local head = character:FindFirstChild("Head")
		if not head then return end
		
		local nametag = head:FindFirstChild("Nametag")
		if not nametag then return end
		
		local displayNameContainer = nametag:FindFirstChild("DisplayNameContainer")
		if not displayNameContainer then return end
		
		local displayName = displayNameContainer:FindFirstChild("DisplayName")
		if displayName and displayName:IsA("TextLabel") then
			modifyPlayerName(displayName)
		end
	end
	
	local function restoreNametag(character)
		if not character then return end
		
		local head = character:FindFirstChild("Head")
		if not head then return end
		
		local nametag = head:FindFirstChild("Nametag")
		if not nametag then return end
		
		local displayNameContainer = nametag:FindFirstChild("DisplayNameContainer")
		if not displayNameContainer then return end
		
		local displayName = displayNameContainer:FindFirstChild("DisplayName")
		if displayName and displayName:IsA("TextLabel") then
			restorePlayerName(displayName)
		end
	end
	
	StreamProof = vape.Categories.Render:CreateModule({
		Name = 'Stream Proof',
		Function = function(callback)
			if callback then
				local existingTabList = lplr.PlayerGui:FindFirstChild("TabListScreenGui")
				if existingTabList then
					processGui(existingTabList)
					
					StreamProof:Clean(existingTabList.DescendantAdded:Connect(function(descendant)
						modifyPlayerName(descendant)
					end))
				end
				
				local existingKillFeed = lplr.PlayerGui:FindFirstChild("KillFeedGui")
				if existingKillFeed then
					processGui(existingKillFeed)
					
					StreamProof:Clean(existingKillFeed.DescendantAdded:Connect(function(descendant)
						modifyPlayerName(descendant)
					end))
				end
				
				StreamProof:Clean(lplr.PlayerGui.ChildAdded:Connect(function(gui)
					if gui.Name == "TabListScreenGui" then
						processGui(gui)
						
						StreamProof:Clean(gui.DescendantAdded:Connect(function(descendant)
							modifyPlayerName(descendant)
						end))
					elseif gui.Name == "KillFeedGui" then
						processGui(gui)
						
						StreamProof:Clean(gui.DescendantAdded:Connect(function(descendant)
							modifyPlayerName(descendant)
						end))
					end
				end))
				
				if lplr.Character then
					modifyNametag(lplr.Character)
				end
				
				StreamProof:Clean(lplr.CharacterAdded:Connect(function(character)
					task.wait(0.5)
					if StreamProof.Enabled then
						modifyNametag(character)
					end
				end))
				
				nametagConnection = runService.RenderStepped:Connect(function()
					if StreamProof.Enabled and lplr.Character then
						pcall(function()
							modifyNametag(lplr.Character)
						end)
					end
				end)
				
			else
				if nametagConnection then
					nametagConnection:Disconnect()
					nametagConnection = nil
				end
				
				local existingTabList = lplr.PlayerGui:FindFirstChild("TabListScreenGui")
				if existingTabList then
					for _, descendant in existingTabList:GetDescendants() do
						restorePlayerName(descendant)
					end
				end
				
				local existingKillFeed = lplr.PlayerGui:FindFirstChild("KillFeedGui")
				if existingKillFeed then
					for _, descendant in existingKillFeed:GetDescendants() do
						restorePlayerName(descendant)
					end
				end
				
				if lplr.Character then
					restoreNametag(lplr.Character)
				end
				
				table.clear(originalNames)
			end
		end,
		Tooltip = 'Hides your name as much as possible  in TabList, KillFeed, and Nametag'
	})
end)