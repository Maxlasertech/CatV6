local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local proximityPromptService = cloneref(game:GetService('ProximityPromptService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local starterGui = cloneref(game:GetService('StarterGui'))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local tween = vape.Libraries.tween
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

local rankCache = {}
local store = {
	attackReach = 0,
	lastHit = 0,
	attackReachUpdate = tick(),
	damageBlockFail = tick(),
	hand = {},
	inventory = {
		inventory = {
			items = {},
			armor = {}
		},
		hotbar = {}
	},
	rank = setmetatable({}, {
		__index = function(self, index)
			return {async = function()
				if rankCache[index] then
					return rankCache[index]
				end

				if index then
					local rank = bedwars.Handler:Get('FetchRanks'):Fire('CallServer', {index.UserId})
					if typeof(rank) == 'table' and rank[1] and rank[1].rankDivision then
						rankCache[index] = rank[1].rankDivision
						return rankCache[index]
					end
				end

				return nil
			end}
		end
	}),
	inventories = {},
	matchState = 0,
	queueType = 'bedwars_test',
	tools = {},
	ping = {}
}
local Reach = {}
local HitBoxes = {}
local InfiniteFly = {}
local TrapDisabler
local AntiFallPart
local bedwars, remotes, sides, oldinvrender, oldSwing = {}, {}, {}

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('catsix/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end

local function collection(tags, module, customadd, customremove)
	tags = typeof(tags) ~= 'table' and {tags} or tags
	local objs, connections = {}, {}

	for _, tag in tags do
		table.insert(connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			if customadd then
				customadd(objs, v, tag)
				return
			end
			table.insert(objs, v)
		end))
		table.insert(connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if customremove then
				customremove(objs, v, tag)
				return
			end
			v = table.find(objs, v)
			if v then
				table.remove(objs, v)
			end
		end))

		for _, v in collectionService:GetTagged(tag) do
			if customadd then
				customadd(objs, v, tag)
				continue
			end
			table.insert(objs, v)
		end
	end

	local cleanFunc = function(self)
		for _, v in connections do
			v:Disconnect()
		end
		table.clear(connections)
		table.clear(objs)
		table.clear(self)
	end
	if module then
		module:Clean(cleanFunc)
	end
	return objs, cleanFunc
end
getgenv().collection = collection

local function getBestArmor(slot)
	local closest, mag = nil, 0

	for _, item in store.inventory.inventory.items do
		local meta = item and bedwars.ItemMeta[item.itemType] or {}

		if meta.armor and meta.armor.slot == slot then
			local newmag = (meta.armor.damageReductionMultiplier or 0)

			if newmag > mag then
				closest, mag = item, newmag
			end
		end
	end

	return closest
end
getgenv().getBestArmor = getBestArmor

local function getBow()
	local bestBow, bestBowSlot, bestBowDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local bowMeta = bedwars.ItemMeta[item.itemType].projectileSource
		if bowMeta and table.find(bowMeta.ammoItemTypes, 'arrow') then
			local bowDamage = bedwars.ProjectileMeta[bowMeta.projectileType('arrow')].combat.damage or 0
			if bowDamage > bestBowDamage then
				bestBow, bestBowSlot, bestBowDamage = item, slot, bowDamage
			end
		end
	end
	return bestBow, bestBowSlot
end
getgenv().getBow = getBow

local function getItem(itemName, inv)
	for slot, item in (inv or store.inventory.inventory.items) do
		if item.itemType == itemName then
			return item, slot
		end
	end
	return nil
end
getgenv().getItem = getItem

local function getRoactRender(func)
	return debug.getupvalue(debug.getupvalue(debug.getupvalue(func, 3).render, 2).render, 1)
end

local function getSword()
	local bestSword, bestSwordSlot, bestSwordDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local swordMeta = bedwars.ItemMeta[item.itemType].sword
		if swordMeta then
			local swordDamage = swordMeta.damage or 0
			if swordDamage > bestSwordDamage then
				bestSword, bestSwordSlot, bestSwordDamage = item, slot, swordDamage
			end
		end
	end
	return bestSword, bestSwordSlot
end
getgenv().getSword = getSword

local function getTool(breakType)
	local bestTool, bestToolSlot, bestToolDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local toolMeta = bedwars.ItemMeta[item.itemType].breakBlock
		if toolMeta then
			local toolDamage = toolMeta[breakType] or 0
			if toolDamage > bestToolDamage then
				bestTool, bestToolSlot, bestToolDamage = item, slot, toolDamage
			end
		end
	end
	return bestTool, bestToolSlot
end
getgenv().getTool = getTool

local function getWool()
	for _, wool in (inv or store.inventory.inventory.items) do
		if wool.itemType:find('wool') then
			return wool and wool.itemType, wool and wool.amount
		end
	end
end
getgenv().getWool = getWool

local function getStrength(plr)
	if not plr.Player then
		return 0
	end

	local strength = 0
	for _, v in (store.inventories[plr.Player] or {items = {}}).items do
		local itemmeta = bedwars.ItemMeta[v.itemType]
		if itemmeta and itemmeta.sword and itemmeta.sword.damage > strength then
			strength = itemmeta.sword.damage
		end
	end

	return strength
end
getgenv().getStrength = getStrength

local function getPlacedBlock(pos)
	if not pos then
		return
	end
	local roundedPosition = bedwars.BlockController:getBlockPosition(pos)
	return bedwars.BlockController:getStore():getBlockAt(roundedPosition), roundedPosition
end
getgenv().getPlacedBlock = getPlacedBlock

local function getBlocksInPoints(s, e)
	local blocks, list = bedwars.BlockController:getStore(), {}
	for x = s.X, e.X do
		for y = s.Y, e.Y do
			for z = s.Z, e.Z do
				local vec = Vector3.new(x, y, z)
				if blocks:getBlockAt(vec) then
					table.insert(list, vec * 3)
				end
			end
		end
	end
	return list
end
getgenv().getBlocksInPoints = getBlocksInPoints

local function getNearGround(range)
	range = Vector3.new(3, 3, 3) * (range or 10)
	local localPosition, mag, closest = entitylib.character.RootPart.Position, 60
	local blocks = getBlocksInPoints(bedwars.BlockController:getBlockPosition(localPosition - range), bedwars.BlockController:getBlockPosition(localPosition + range))

	for _, v in blocks do
		if not getPlacedBlock(v + Vector3.new(0, 3, 0)) then
			local newmag = (localPosition - v).Magnitude
			if newmag < mag then
				mag, closest = newmag, v + Vector3.new(0, 3, 0)
			end
		end
	end

	table.clear(blocks)
	return closest
end
getgenv().getNearGround = getNearGround

local function getShieldAttribute(char)
	local returned = 0
	for name, val in char:GetAttributes() do
		if name:find('Shield') and type(val) == 'number' and val > 0 then
			returned += val
		end
	end
	return returned
end
getgenv().getShieldAttribute = getShieldAttribute

local knockbackSpeed, knockbackBoost = 0, tick()
local function getSpeed()
	local multi, increase, modifiers = 0, true, bedwars.SprintController:getMovementStatusModifier():getModifiers()

	for v in modifiers do
		local val = v.constantSpeedMultiplier and v.constantSpeedMultiplier or 0
		if val and val > math.max(multi, 1) then
			increase = false
			multi = val - (0.06 * math.round(val))
		end
	end

	for v in modifiers do
		multi += math.max((v.moveSpeedMultiplier or 0) - 1, 0)
	end

	if multi > 0 and increase then
		multi += 0.16 + (0.02 * math.round(multi))
	end

	return (20 + (knockbackBoost > tick() and knockbackSpeed or 0)) * (multi + 1)
end
getgenv().getSpeed = getSpeed

local function getTableSize(tab)
	local ind = 0
	for _ in tab do
		ind += 1
	end
	return ind
end
getgenv().getTableSize = getTableSize

local function getHotbar(tool)
	for i, v in (store.inventory.hotbar or {}) do
		if v.item and v.item.tool == tool then
			return i - 1
		end
	end
	return nil
end
getgenv().getHotbar = getHotbar

local function hotbarSwitch(slot)
	if slot and store.inventory.hotbarSlot ~= slot then
		bedwars.Store:dispatch({
			type = 'InventorySelectHotbarSlot',
			slot = slot
		})
		vapeEvents.InventoryChanged.Event:Wait()
		return true
	end
	return false
end
getgenv().hotbarSwitch = hotbarSwitch

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function notif(...) return
	vape:CreateNotification(...)
end
getgenv().notif = notif

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end
getgenv().removeTags = removeTags

local function roundPos(vec)
	return Vector3.new(math.round(vec.X / 3) * 3, math.round(vec.Y / 3) * 3, math.round(vec.Z / 3) * 3)
end
getgenv().roundPos = roundPos

local function switchItem(tool, delayTime)
	delayTime = delayTime or 0.05
	local check = lplr.Character and lplr.Character:FindFirstChild('HandInvItem') or nil
	if check and check.Value ~= tool and tool.Parent ~= nil then
		task.spawn(function()
			bedwars.Handler:Get('SetInvItem'):Fire('CallServerAsync', {hand = tool})
		end)
		check.Value = tool
		if delayTime > 0 then
			task.wait(delayTime)
		end
		return true
	end
end
getgenv().switchItem = switchItem

local function waitForChildOfType(obj, name, timeout, prop)
	local check, returned = tick() + timeout
	repeat
		returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
		if returned and returned.Name ~= 'UpperTorso' or check < tick() then
			break
		end
		task.wait()
	until false
	return returned
end

local frictionTable, oldfrict = {}, {}
local frictionConnection
local frictionState

local function modifyVelocity(v)
	if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and not oldfrict[v] then
		oldfrict[v] = v.CustomPhysicalProperties or 'none'
		v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
	end
end

local function updateVelocity(force)
	local newState = getTableSize(frictionTable) > 0
	if frictionState ~= newState or force then
		if frictionConnection then
			frictionConnection:Disconnect()
		end
		if newState then
			if entitylib.isAlive then
				for _, v in entitylib.character.Character:GetDescendants() do
					modifyVelocity(v)
				end
				frictionConnection = entitylib.character.Character.DescendantAdded:Connect(modifyVelocity)
			end
		else
			for i, v in oldfrict do
				i.CustomPhysicalProperties = v ~= 'none' and v or nil
			end
			table.clear(oldfrict)
		end
	end
	frictionState = newState
end

local kitorder = {
	hannah = 5,
	spirit_assassin = 4,
	dasher = 3,
	jade = 2,
	regent = 1
}

local sortmethods = {
	Damage = function(a, b)
		return a.Entity.Character:GetAttribute('LastDamageTakenTime') < b.Entity.Character:GetAttribute('LastDamageTakenTime')
	end,
	Threat = function(a, b)
		return getStrength(a.Entity) > getStrength(b.Entity)
	end,
	Kit = function(a, b)
		return (a.Entity.Player and kitorder[a.Entity.Player:GetAttribute('PlayingAsKits')] or 0) > (b.Entity.Player and kitorder[b.Entity.Player:GetAttribute('PlayingAsKits')] or 0)
	end,
	Health = function(a, b)
		return a.Entity.Health < b.Entity.Health
	end,
	Angle = function(a, b)
		local selfrootpos = entitylib.character.RootPart.Position
		local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
		local direction = (a.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)
		local direction2 = (b.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)
		local angle = direction.Magnitude > 0 and math.acos(math.clamp(localfacing:Dot(direction.Unit), -1, 1)) or 0
		local angle2 = direction2.Magnitude > 0 and math.acos(math.clamp(localfacing:Dot(direction2.Unit), -1, 1)) or 0
		return angle < angle2
	end,
	Mouse = function(a, b)
		local mouse = lplr:GetMouse()
		local origin = Vector2.new(mouse.X, mouse.Y)

		local posa, visa = gameCamera:WorldToScreenPoint(a.Entity.RootPart.Position)
		local posb, visb = gameCamera:WorldToScreenPoint(b.Entity.RootPart.Position)
		local dista = visa and (Vector2.new(posa.X, posa.Y) - origin).Magnitude or math.huge
        local distb = visb and (Vector2.new(posb.X, posb.Y) - origin).Magnitude or math.huge
        return (dista == dista and dista or math.huge) < (distb == distb and distb or math.huge)
	end
}
getgenv().sortmethods = sortmethods
local getBlockHits
local function getBlockDistance(a)
	local pos = (entitylib.isAlive and (entitylib.character.RootPart.Position - Vector3.new(0, 1, 0)) or Vector3.zero)
	return (pos - Vector3.new(a.Position.X, pos.Y, a.Position.Z)).Magnitude
end

local breakmethods = {
	Health = function(a, b)
		return getBlockHits(a, b)
	end,
	Distance = function(a, b)
		return getBlockDistance(a) + getBlockHits(a, b) * 0.01
	end
}

run(function()
	local oldstart = entitylib.start
	local function customEntity(ent)
		if ent:HasTag('inventory-entity') and not ent:HasTag('Monster') and not ent:HasTag('trainingRoomDummy') then
			return
		end

		entitylib.addEntity(ent, nil, ent:HasTag('Drone') and function(self)
			local droneplr = playersService:GetPlayerByUserId(self.Character:GetAttribute('PlayerUserId'))
			return not droneplr or lplr:GetAttribute('Team') ~= droneplr:GetAttribute('Team')
		end or function(self)
			return lplr:GetAttribute('Team') ~= self.Character:GetAttribute('Team')
		end)
	end

	entitylib.start = function()
		oldstart()
		if entitylib.Running then
			for _, ent in collectionService:GetTagged('entity') do
				customEntity(ent)
			end
			table.insert(entitylib.Connections, collectionService:GetInstanceAddedSignal('entity'):Connect(customEntity))
			table.insert(entitylib.Connections, collectionService:GetInstanceRemovedSignal('entity'):Connect(function(ent)
				entitylib.removeEntity(ent)
			end))
		end
	end

	entitylib.addPlayer = function(plr)
		if plr.Character then
			entitylib.refreshEntity(plr.Character, plr)
		end
		entitylib.PlayerConnections[plr] = {
			plr.CharacterAdded:Connect(function(char)
				entitylib.refreshEntity(char, plr)
			end),
			plr.CharacterRemoving:Connect(function(char)
				entitylib.removeEntity(char, plr == lplr)
			end),
			plr:GetAttributeChangedSignal('Team'):Connect(function()
				for _, v in entitylib.List do
					if v.Targetable ~= entitylib.targetCheck(v) then
						entitylib.refreshEntity(v.Character, v.Player)
					end
				end

				if plr == lplr then
					entitylib.start()
				else
					entitylib.refreshEntity(plr.Character, plr)
				end
			end)
		}
	end

	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum, humrootpart, head
			if plr then
				hum = waitForChildOfType(char, 'Humanoid', 10)
				humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
				head = char:WaitForChild('Head', 10) or humrootpart
			else
				hum = {HipHeight = 0.5}
				humrootpart = waitForChildOfType(char, 'PrimaryPart', 10, true)
				head = humrootpart
			end
			local updateobjects = plr and plr ~= lplr and {
				char:WaitForChild('ArmorInvItem_0', 5),
				char:WaitForChild('ArmorInvItem_1', 5),
				char:WaitForChild('ArmorInvItem_2', 5),
				char:WaitForChild('HandInvItem', 5)
			} or {}

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = (char:GetAttribute('Health') or 100) + getShieldAttribute(char),
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
					Jumps = 0,
					JumpTick = tick(),
					Jumping = false,
					LandTick = tick(),
					MaxHealth = char:GetAttribute('MaxHealth') or 100,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc
				}

				if plr == lplr then
					entity.AirTime = tick()
					entitylib.character = entity
					entitylib.isAlive = true
					entitylib.Events.LocalAdded:Fire(entity)
					table.insert(entitylib.Connections, char.AttributeChanged:Connect(function(attr)
						vapeEvents.AttributeChanged:Fire(attr)
					end))
				else
					entity.Targetable = entitylib.targetCheck(entity)

					for _, v in entitylib.getUpdateConnections(entity) do
						table.insert(entity.Connections, v:Connect(function()
							entity.Health = (char:GetAttribute('Health') or 100) + getShieldAttribute(char)
							entity.MaxHealth = char:GetAttribute('MaxHealth') or 100
							entitylib.Events.EntityUpdated:Fire(entity)
						end))
					end

					for _, v in updateobjects do
						table.insert(entity.Connections, v:GetPropertyChangedSignal('Value'):Connect(function()
							task.delay(0.1, function()
								if bedwars.getInventory then
									store.inventories[plr] = bedwars.getInventory(plr)
									entitylib.Events.EntityUpdated:Fire(entity)
								end
							end)
						end))
					end

					if plr then
						local anim = char:FindFirstChild('Animate')
						if anim then
							pcall(function()
								anim = anim.jump:FindFirstChildWhichIsA('Animation').AnimationId
								table.insert(entity.Connections, hum.Animator.AnimationPlayed:Connect(function(playedanim)
									if playedanim.Animation.AnimationId == anim then
										entity.JumpTick = tick()
										entity.Jumps += 1
										entity.LandTick = tick() + 1
										entity.Jumping = entity.Jumps > 1
									end
								end))
							end)
						end

						task.delay(0.1, function()
							if bedwars.getInventory then
								store.inventories[plr] = bedwars.getInventory(plr)
							end
						end)
					end
					table.insert(entitylib.List, entity)
					entitylib.Events.EntityAdded:Fire(entity)
				end

				table.insert(entity.Connections, char.ChildRemoved:Connect(function(part)
					if part == humrootpart or part == hum or part == head then
						if part == humrootpart and hum.RootPart then
							humrootpart = hum.RootPart
							entity.RootPart = hum.RootPart
							entity.HumanoidRootPart = hum.RootPart
							return
						end
						entitylib.removeEntity(char, plr == lplr)
					end
				end))
			end
			entitylib.EntityThreads[char] = nil
		end)
	end

	entitylib.getUpdateConnections = function(ent)
		local char = ent.Character
		local tab = {
			char:GetAttributeChangedSignal('Health'),
			char:GetAttributeChangedSignal('MaxHealth'),
			{
				Connect = function()
					ent.Friend = ent.Player and isFriend(ent.Player) or nil
					ent.Target = ent.Player and isTarget(ent.Player) or nil
					return {Disconnect = function() end}
				end
			}
		}

		if ent.Player then
			table.insert(tab, ent.Player:GetAttributeChangedSignal('PlayingAsKits'))
		end

		for name, val in char:GetAttributes() do
			if name:find('Shield') and type(val) == 'number' then
				table.insert(tab, char:GetAttributeChangedSignal(name))
			end
		end

		return tab
	end

	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then
			return ent:TeamCheck()
		end
		if ent.NPC then return true end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		return lplr:GetAttribute('Team') ~= ent.Player:GetAttribute('Team')
	end
	vape:Clean(entitylib.Events.LocalAdded:Connect(updateVelocity))
end)
entitylib.start()

local calculatePath
run(function()
	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function()
			return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
		end)
		if KnitInit then break end
		task.wait()
	until KnitInit

	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end

	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local InventoryUtil = require(replicatedStorage.TS.inventory['inventory-util']).InventoryUtil
	local Remotes = require(game:GetService("ReplicatedStorage").TS.remotes).default

	local Client = Remotes.Client
	local OldGet, OldBreak, OldHit = Client.Get

	local RemoteHandler = {} -- thanks lr <3
	RemoteHandler.CachedRemotes = {}
	RemoteHandler.__index = RemoteHandler

	local RemoteDefinitionConstruct, RemotesInConstruct = next(getupvalue(getrawmetatable(Remotes.Server).Get, 1))
	local GlobalMiddleware = RemoteDefinitionConstruct and getupvalue(RemoteDefinitionConstruct.globalMiddleware[2], 1)
	if not GlobalMiddleware or typeof(GlobalMiddleware) ~= "table" then
		notif('Cat', 'Failed to load ratelimits, report this to a developer.', 30, 'alert')
	end

	function RemoteHandler.Get(self, RemoteID: string)
		if RemoteHandler.CachedRemotes[RemoteID] then
			return RemoteHandler.CachedRemotes[RemoteID]
		end

		local Remote = {}
		setmetatable(Remote, RemoteHandler)

		Remote.ID = RemoteID
		Remote.RequestsInLastMinute = 0
		Remote.MaxRequestsPerMinute = Remote:GetRateLimit()
		Remote.LastRateLimitReset = 0
		
		local Success, AttempedRemote = pcall(Client.Get, Client, Remote.ID)
		Remote.Success = Success
		Remote.Remote = AttempedRemote

		if not Success or not Remote.Remote then
			notif('Cat', `Tried to Get remote {Remote.ID}, remote is invalid`, 15, 'alert')
			Remote.Remote = nil
		end

		RemoteHandler.CachedRemotes[RemoteID] = Remote
		return Remote
	end

	local lastNotify = 0
	function RemoteHandler:Fire(Method: string?, ...)
		local Remote = self.Remote
		if not self.Success or not Remote then
			if tick() - lastNotify > 0.5 then
				lastNotify = tick()
				notif('Cat', `Tried to Fire remote {Remote.ID}, remote is invalid`, 10, 'alert')
			end
			return {
				andThen = function() end
			}
		end

		if (os.clock() - self.LastRateLimitReset) >= 60 then
			self:ResetRateLimit()
		end

		if self:GetCurrentRequests() >= self:GetRateLimit() then
			if tick() - lastNotify > 0.5 then
				lastNotify = tick()
				notif('Cat', `{self.ID} has hit its rate limit of {self.MaxRequestsPerMinute} requests per min`, 15, 'alert')
			end
			return {andThen = function() end}
		end

		self:IncrementRequests()
		local CallingFunction = (Method and Remote[Method]) or (Remote.CallServer or Remote.CallServerAsync or Remote.SendToServer)
		if CallingFunction then
			return CallingFunction(Remote, ...)
		end

		return
	end

	function RemoteHandler:ResetRateLimit()
		self.RequestsInLastMinute = 0
		self.LastRateLimitReset = os.clock()
	end

	function RemoteHandler:GetCurrentRequests()
		return self.RequestsInLastMinute
	end

	function RemoteHandler:IncrementRequests()
		self.RequestsInLastMinute = self.RequestsInLastMinute + 1
	end

	function RemoteHandler:GetRateLimit()
		local RemoteName: string = self.ID
		if self.CachedRemotes[RemoteName] then
			return self.CachedRemotes[RemoteName].MaxRequestsPerMinute
		end

		if not GlobalMiddleware then
			return 300
		end

		local GlobalFind = GlobalMiddleware[RemoteName]
		local RateLimitValue: number = (typeof(GlobalFind) ~= "number" and 300) or GlobalFind

		if not GlobalFind then
			local TargetRemote = RemotesInConstruct[RemoteName]
			local RemoteRateLimit = (TargetRemote and TargetRemote.ServerMiddleware)
			if RemoteRateLimit and typeof(RemoteRateLimit) == "table" then
				for i,v in RemoteRateLimit do
					if typeof(v) == "function" and (#getupvalues(v) >= 6 and tostring(getupvalue(v, 6)):find("Request limit")) then
						local Value: number = getupvalue(v, 3)
						RateLimitValue = (typeof(Value) == "number" and Value) or RateLimitValue
						break
					end
				end
			end
		end
		
		return RateLimitValue
	end

	bedwars = setmetatable({
		AbilityController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController'),
		AnimationType = require(replicatedStorage.TS.animation['animation-type']).AnimationType,
		AnimationUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out['shared'].util['animation-util']).AnimationUtil,
		AdetundeUtil = require(replicatedStorage.TS.games.bedwars.items['frosty-hammer']['frosty-hammer-util']).FrostyHammerUtil,
		AdetundeUpgradeMeta = require(replicatedStorage.TS.games.bedwars.items['frosty-hammer']['frosty-hammer-upgrades']).FrostyHammerUpgradeMeta,
		AppController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.controllers['app-controller']).AppController,
		BedBreakEffectMeta = require(replicatedStorage.TS.locker['bed-break-effect']['bed-break-effect-meta']).BedBreakEffectMeta,
		BedwarsKitMeta = require(replicatedStorage.TS.games.bedwars.kit['bedwars-kit-meta']).BedwarsKitMeta,
		BlockBreaker = Knit.Controllers.BlockBreakController.blockBreaker,
		BlockController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out).BlockEngine,
		BlockEngine = require(lplr.PlayerScripts.TS.lib['block-engine']['client-block-engine']).ClientBlockEngine,
		BlockPlacer = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.client.placement['block-placer']).BlockPlacer,
		BowConstantsTable = debug.getupvalue(Knit.Controllers.ProjectileController.enableBeam, 8),
		BlockSelector = require(replicatedStorage.rbxts_include.node_modules['@easy-games']['block-engine'].out.client.select['block-selector']).BlockSelector,
		BlockSelectorMode = require(replicatedStorage.rbxts_include.node_modules['@easy-games']['block-engine'].out.client.select['block-selector']).BlockSelectorMode,
		ClickHold = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.ui.lib.util['click-hold']).ClickHold,
		Client = Client,
		ClientConstructor = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts'].net.out.client),
		ClientDamageBlock = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.shared.remotes).BlockEngineRemotes.Client,
		CombatConstant = require(replicatedStorage.TS.combat['combat-constant']).CombatConstant,
		DamageIndicator = Knit.Controllers.DamageIndicatorController.spawnDamageIndicator,
		DefaultKillEffect = require(lplr.PlayerScripts.TS.controllers.global.locker['kill-effect'].effects['default-kill-effect']),
		EmoteType = require(replicatedStorage.TS.locker.emote['emote-type']).EmoteType,
		EmoteMeta = require(replicatedStorage.TS.locker.emote['emote-meta']).EmoteMeta,
		EnchantMeta = require(replicatedStorage.TS.enchant['enchant-meta']).EnchantMeta,
		GameAnimationUtil = require(replicatedStorage.TS.animation['animation-util']).GameAnimationUtil,
		getIcon = function(item, showinv)
			local itemmeta = bedwars.ItemMeta[item.itemType]
			return itemmeta and showinv and itemmeta.image or ''
		end,
		getItemSkinMeta = require(replicatedStorage.TS.games.bedwars['item-skin']['item-skin-meta']).getItemSkinMeta,
		getInventory = function(plr)
			local suc, res = pcall(function()
				return InventoryUtil.getInventory(plr)
			end)
			return suc and res or {
				items = {},
				armor = {}
			}
		end,
		Handler = RemoteHandler,
		HudAliveCount = require(lplr.PlayerScripts.TS.controllers.global['top-bar'].ui.game['hud-alive-player-counts']).HudAlivePlayerCounts,
		ItemMeta = debug.getupvalue(require(replicatedStorage.TS.item['item-meta']).getItemMeta, 1),
		ItemSkinType = require(replicatedStorage.TS.games.bedwars['item-skin']['item-skin-types']).ItemSkinType,
		KillEffectMeta = require(replicatedStorage.TS.locker['kill-effect']['kill-effect-meta']).KillEffectMeta,
		KillFeedController = Flamework.resolveDependency('client/controllers/game/kill-feed/kill-feed-controller@KillFeedController'),
		Knit = Knit,
		KnockbackUtil = require(replicatedStorage.TS.damage['knockback-util']).KnockbackUtil,
		MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage['mage-kit-util']).MageKitUtil,
		NametagController = Knit.Controllers.NametagController,
		PartyController = Flamework.resolveDependency('@easy-games/lobby:client/controllers/party-controller@PartyController'),
		ProjectileMeta = require(replicatedStorage.TS.projectile['projectile-meta']).ProjectileMeta,
		QueryUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil,
		QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui['queue-card']).QueueCard,
		QueueMeta = require(replicatedStorage.TS.game['queue-meta']).QueueMeta,
		RankMeta = require(replicatedStorage.TS.rank['rank-meta']).RankMeta,
		Roact = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts']['roact'].src),
		RuntimeLib = require(replicatedStorage['rbxts_include'].RuntimeLib),
		StatusEffectUtil = require(replicatedStorage.TS['status-effect']['status-effect-util']).StatusEffectUtil,
		StatusEffectMeta = require(replicatedStorage.TS['status-effect']['status-effect-type']).StatusEffectType,
		SoundList = require(replicatedStorage.TS.sound['game-sound']).GameSound,
		SettingsMeta = require(replicatedStorage.TS.settings['settings-meta']).SettingMeta,
		SharedConstants = require(replicatedStorage.TS['shared-constants']).CpsConstants,
		SoundManager = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).SoundManager,
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
		TeamUpgradeMeta = debug.getupvalue(require(replicatedStorage.TS.games.bedwars['team-upgrade']['team-upgrade-meta']).getTeamUpgradeMetaForQueue, 2),
		UILayers = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).UILayers,
		VisualizerUtils = require(lplr.PlayerScripts.TS.lib.visualizer['visualizer-utils']).VisualizerUtils,
		WeldTable = require(replicatedStorage.TS.util['weld-util']).WeldUtil,
		WinEffectMeta = require(replicatedStorage.TS.locker['win-effect']['win-effect-meta']).WinEffectMeta,
		ZapNetworking = require(lplr.PlayerScripts.TS.lib.network)
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})
	store.enchants = setmetatable({}, {
		__index = function(self, plr)
			return {
				async = function()
					if plr and plr.Character then
						for i in plr.Character:GetAttributes() do
							if i:find('StatusEffect_') and not i:find('_stacks') then
								local name = bedwars.StatusEffectMeta[({i:gsub('StatusEffect_', '')})[1]]
								if bedwars.StatusEffectMeta[name] then
									name = bedwars.StatusEffectMeta[name]
									for num = 1, 3 do
										name = name:gsub(`_{num}`, '')
									end

									if bedwars.EnchantMeta[name] then
										return bedwars.EnchantMeta[name].image
									end
								end
							end
						end
					end
					return nil
				end,
			}
		end
	})
	getgenv().store = store
	getgenv().bedwars = bedwars

	OldBreak = bedwars.BlockController.isBlockBreakable
	OldHit = bedwars.BlockBreaker.hitBlock

	Client.Get = function(self, remoteName)
		local call = OldGet(self, remoteName)

		if remoteName == 'SwordHit' then
			return {
				instance = call.instance,
				SendToServer = function(_, attackTable, ...)
					local selfpos = attackTable.validate.selfPosition.value
					local targetpos = attackTable.validate.targetPosition.value
					store.attackReach = ((selfpos - targetpos).Magnitude * 100) // 1 / 100
					store.attackReachUpdate = tick() + 1

					if Reach.Enabled or HitBoxes.Enabled then
						attackTable.validate.raycast = attackTable.validate.raycast or {}
						attackTable.validate.selfPosition.value += CFrame.lookAt(selfpos, targetpos).LookVector * math.max((selfpos - targetpos).Magnitude - 14.399, 0)
					end

					return call:SendToServer(attackTable, ...)
				end
			}
		elseif remoteName == 'StepOnSnapTrap' and TrapDisabler.Enabled then
			return {SendToServer = function() end}
		end

		return call
	end

	bedwars.BlockController.isBlockBreakable = function(self, breakTable, plr)
		local obj = bedwars.BlockController:getStore():getBlockAt(breakTable.blockPosition)

		if obj and obj.Name == 'bed' then
			for _, plr in playersService:GetPlayers() do
				if obj:GetAttribute('Team'..(plr:GetAttribute('Team') or 0)..'NoBreak') and not select(2, whitelist:get(plr)) then
					return false
				end
			end
		end

		return OldBreak(self, breakTable, plr)
	end
	bedwars.BlockBreaker.hitBlock = function(...)
        store.lastHit = tick()
        return OldHit(...)
    end

	local cache, blockhealthbar = {}, {blockHealth = -1, breakingBlockPosition = Vector3.zero}
	store.blockPlacer = bedwars.BlockPlacer.new(bedwars.BlockEngine, 'wool_white')

	local function getBlockHealth(block, blockpos)
		local blockdata = bedwars.BlockController:getStore():getBlockData(blockpos)
		return (blockdata and (blockdata:GetAttribute('1') or blockdata:GetAttribute('Health')) or block:GetAttribute('Health'))
	end

	getBlockHits = function(block, blockpos)
		if not block then return 0 end
		local breaktype = bedwars.ItemMeta[block.Name].block.breakType
		local tool = store.tools[breaktype]
		tool = tool and bedwars.ItemMeta[tool.itemType].breakBlock[breaktype] or 2
		return getBlockHealth(block, bedwars.BlockController:getBlockPosition(blockpos)) / tool
	end

	--[[
		Pathfinding using a luau version of dijkstra's algorithm
		Source: https://stackoverflow.com/questions/39355587/speeding-up-dijkstras-algorithm-to-solve-a-3d-maze
	]]
	calculatePath = function(target, blockpos, solidonly, breakmethod)
		local heap = {}
		local function push(cost, node)
			local index = #heap + 1
			heap[index] = {cost, node}

			while index > 1 do
				local parent = index // 2
				if heap[parent][1] <= heap[index][1] then break end
				heap[parent], heap[index] = heap[index], heap[parent]
				index = parent
			end
		end

		local function pop()
			local size = #heap
			if size == 0 then return end
			local root = heap[1]

			heap[1], heap[size], size = heap[size], nil, size - 1
			local index = 1

			while true do
				local left, right, smallest = index * 2, (index * 2) + 1, index
				if left <= size and heap[left][1] < heap[smallest][1] then smallest = left end
				if right <= size and heap[right][1] < heap[smallest][1] then smallest = right end
				if smallest == index then break end

				heap[index], heap[smallest] = heap[smallest], heap[index]
				index = smallest
			end

			return root[1], root[2]
		end

		local visited, distances, exposed, path = {}, {[blockpos] = 0}, {}, {}
		local gaps, sources = {[blockpos] = 0}, {[blockpos] = blockpos}
		push(0, blockpos)

		for _ = 1, 10000 do
			local cost, node = pop()
			if not node then break end
			if visited[node] then continue end
			visited[node] = true
			local current, source = getPlacedBlock(node), sources[node]

			for _, side in sides do
				side = node + side
				if visited[side] then continue end

				local block = getPlacedBlock(side)
				if not block then
					if current then
						local cells = exposed[node]
						if cells then
							table.insert(cells, side)
						else
							exposed[node] = {side}
						end
					end

					local gap = current and 1 or (gaps[node] + 1)
					if not solidonly and gap <= 2 and (side - blockpos).Magnitude <= 15 and cost < (distances[side] or math.huge) then
						distances[side] = cost
						gaps[side] = gap
						sources[side] = source
						push(cost, side)
					end
					continue
				end

				if block:GetAttribute('NoBreak') or block == target then continue end

				local curdist = cost + (breakmethod or getBlockHits)(block, side)
				if curdist < (distances[side] or math.huge) then
					distances[side] = curdist
					gaps[side] = 0
					sources[side] = side
					path[side] = source
					push(curdist, side)
				end
			end
		end

		local origin = entitylib.character.RootPart.Position
		local candidates = {}
		for node, cells in exposed do
			table.insert(candidates, {distances[node], node, cells})
		end
		table.sort(candidates, function(a, b)
			if a[1] == b[1] then
				return (a[2] - origin).Magnitude < (b[2] - origin).Magnitude
			end
			return a[1] < b[1]
		end)

		local routes = {}
		local function isOpen(cell)
			if routes[cell] ~= nil then
				return routes[cell]
			end
			local queue, seen, open = {cell}, {[cell] = true}, true

			for _ = 1, 400 do
				local current = table.remove(queue)
				if not current then
					open = false
					break
				end
				if (current - blockpos).Magnitude > 15 then break end

				for _, side in sides do
					side = current + side
					if seen[side] or getPlacedBlock(side) then continue end
					seen[side] = true
					table.insert(queue, side)
				end
			end

			for reached in seen do
				routes[reached] = open
			end
			return open
		end

		--[[
			Sampling a line every stud rounds each point to a cell and can report a block
			the line never enters, so the grid is walked one crossing at a time instead.
		]]
		local function boundary(index, component, delta)
			if delta == 0 then
				return 0, math.huge, math.huge
			end
			local step = delta > 0 and 1 or -1
			return step, ((((index + (step * 0.5)) * 3) - component) / delta), (3 / math.abs(delta))
		end

		local sightlines = {}
		local function canSee(cell)
			if sightlines[cell] ~= nil then
				return sightlines[cell]
			end
			local start, direction = bedwars.BlockController:getBlockPosition(origin), cell - origin
			local x, y, z, clear = start.X, start.Y, start.Z, true

			local stepx, nextx, deltax = boundary(x, origin.X, direction.X)
			local stepy, nexty, deltay = boundary(y, origin.Y, direction.Y)
			local stepz, nextz, deltaz = boundary(z, origin.Z, direction.Z)

			for _ = 1, 100 do
				if nextx > 1 and nexty > 1 and nextz > 1 then break end

				if nextx <= nexty and nextx <= nextz then
					x, nextx = x + stepx, nextx + deltax
				elseif nexty <= nextz then
					y, nexty = y + stepy, nexty + deltay
				else
					z, nextz = z + stepz, nextz + deltaz
				end

				if getPlacedBlock(Vector3.new(x, y, z) * 3) then
					clear = false
					break
				end
			end

			sightlines[cell] = clear
			return clear
		end

		local pos, cost = nil, nil
		for _, candidate in candidates do
			if (candidate[2] - origin).Magnitude > 30 then continue end
			local bed = not solidonly and getPlacedBlock(candidate[2]) == target

			for _, cell in candidate[3] do
				if isOpen(cell) and (not bed or canSee(cell)) then
					pos, cost = candidate[2], candidate[1]
					break
				end
			end

			if pos then break end
		end

		if not pos then
			for _, candidate in candidates do
				if solidonly or getPlacedBlock(candidate[2]) ~= target then
					pos, cost = candidate[2], candidate[1]
					break
				end
			end
		end

		if pos then
			cache[blockpos] = {
				pos,
				cost,
				path
			}
			return pos, cost, path
		end

		return
	end

	bedwars.placeBlock = function(pos, item)
		if getItem(item) then
			store.blockPlacer.blockType = item
			return store.blockPlacer:placeBlock(bedwars.BlockController:getBlockPosition(pos))
		end
	end

	bedwars.breakBlock = function(block, effects, anim, customHealthbar, autotool, wallcheck, method)
		if lplr:GetAttribute('DenyBlockBreak') or not entitylib.isAlive or InfiniteFly.Enabled then return end
		local handler = bedwars.BlockController:getHandlerRegistry():getHandler(block.Name)
		local cost, pos, target, path = math.huge

		for _, v in (handler and handler:getContainedPositions(block) or {block.Position / 3}) do
			local dpos, dcost, dpath = calculatePath(block, v * 3, not wallcheck, method or nil)
			if dpos and dcost < cost then
				cost, pos, target, path = dcost, dpos, v * 3, dpath
			end
		end

		if pos then
			if (entitylib.character.RootPart.Position - pos).Magnitude > 30 then return end
			local dblock, dpos = getPlacedBlock(pos)
			if not dblock then return end

			if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 0.4 then
				local breaktype = bedwars.ItemMeta[dblock.Name].block.breakType
				local tool = store.tools[breaktype]
				if tool then
					if autotool then
						local hotbar = getHotbar(tool.tool)
						if hotbar then
							hotbarSwitch(hotbar)
						end
					else
						switchItem(tool.tool)
					end
				end
			end

			if blockhealthbar.blockHealth == -1 or dpos ~= blockhealthbar.breakingBlockPosition then
				blockhealthbar.blockHealth = getBlockHealth(dblock, dpos)
				blockhealthbar.breakingBlockPosition = dpos
			end

			bedwars.ClientDamageBlock:Get('DamageBlock'):CallServerAsync({
				blockRef = {blockPosition = dpos},
				hitPosition = pos,
				hitNormal = Vector3.FromNormalId(Enum.NormalId.Top)
			}):andThen(function(result)
				if result then
					if result == 'cancelled' then
						store.damageBlockFail = tick() + 1
						return
					end

					if effects then
						local blockdmg = (blockhealthbar.blockHealth - (result == 'destroyed' and 0 or getBlockHealth(dblock, dpos)))
						customHealthbar = customHealthbar or bedwars.BlockBreaker.updateHealthbar
						customHealthbar(bedwars.BlockBreaker, {blockPosition = dpos}, blockhealthbar.blockHealth, dblock:GetAttribute('MaxHealth'), blockdmg, dblock)
						blockhealthbar.blockHealth = math.max(blockhealthbar.blockHealth - blockdmg, 0)

						if blockhealthbar.blockHealth <= 0 then
							bedwars.BlockBreaker.breakEffect:playBreak(dblock.Name, dpos, lplr)
							bedwars.BlockBreaker.blockHealthbar:destroy()
							blockhealthbar.breakingBlockPosition = Vector3.zero
						else
							bedwars.BlockBreaker.breakEffect:playHit(dblock.Name, dpos, lplr)
						end
					end

					if anim then
						local animation = bedwars.AnimationUtil:playAnimation(lplr, bedwars.BlockController:getAnimationController():getAssetId(1))
						bedwars.ViewmodelController:playAnimation(15)
						task.wait(0.3)
						animation:Stop()
						animation:Destroy()
					end
				end
			end)

			if effects then
				return pos, path, target
			end
		end
	end

	for _, v in Enum.NormalId:GetEnumItems() do
		table.insert(sides, Vector3.FromNormalId(v) * 3)
	end

	local function updateStore(new, old)
		if new.Bedwars ~= old.Bedwars then
			store.equippedKit = new.Bedwars.kit ~= 'none' and new.Bedwars.kit or ''
		end

		if new.Game ~= old.Game then
			store.matchState = new.Game.matchState
			store.queueType = new.Game.queueType or 'bedwars_test'
		end

		if new.Inventory ~= old.Inventory then
			local newinv = (new.Inventory and new.Inventory.observedInventory or {inventory = {}})
			local oldinv = (old.Inventory and old.Inventory.observedInventory or {inventory = {}})
			store.inventory = newinv

			if newinv ~= oldinv then
				vapeEvents.InventoryChanged:Fire()
			end

			if newinv.inventory.items ~= oldinv.inventory.items then
				vapeEvents.InventoryAmountChanged:Fire()
				store.tools.sword = getSword()
				for _, v in {'stone', 'wood', 'wool'} do
					store.tools[v] = getTool(v)
				end
			end

			if newinv.inventory.hand ~= oldinv.inventory.hand then
				local currentHand, toolType = new.Inventory.observedInventory.inventory.hand, ''
				if currentHand then
					local handData = bedwars.ItemMeta[currentHand.itemType]
					toolType = handData.sword and 'sword' or handData.block and 'block' or currentHand.itemType:find('bow') and 'bow'
				end

				store.hand = {
					tool = currentHand and currentHand.tool,
					amount = currentHand and currentHand.amount or 0,
					toolType = toolType
				}
			end
		end
	end

	local storeChanged = bedwars.Store.changed:connect(updateStore)
	updateStore(bedwars.Store:getState(), {})

	for _, event in {'MatchEndEvent', 'EntityDeathEvent', 'BedwarsBedBreak', 'BalloonPopped', 'AngelProgress', 'GrapplingHookFunctions'} do
		if not vape.Connections then return end
		bedwars.Client:WaitFor(event):andThen(function(connection)
			vape:Clean(connection:Connect(function(...)
				vapeEvents[event]:Fire(...)
			end))
		end)
	end

	vape:Clean(bedwars.ZapNetworking.EntityDamageEventZap.On(function(...)
		vapeEvents.EntityDamageEvent:Fire({
			entityInstance = ...,
			damage = select(2, ...),
			damageType = select(3, ...),
			fromPosition = select(4, ...),
			fromEntity = select(5, ...),
			knockbackMultiplier = select(6, ...),
			knockbackId = select(7, ...),
			disableDamageHighlight = select(13, ...)
		})
	end))

	vape:Clean(bedwars.ZapNetworking.BreakBlockEventZap.On(function(...)
		local data = {
			blockRef = {
				blockPosition = ...,
			},
			player = select(5, ...)
		}
		for i, v in cache do
			if ((data.blockRef.blockPosition * 3) - v[1]).Magnitude <= 30 then
				table.clear(v[3])
				table.clear(v)
				cache[i] = nil
			end
		end
		vapeEvents.BreakBlockEvent:Fire(data)
	end))

	store.blocks = collection('block', vape)
	store.shop = collection({'BedwarsItemShop', 'TeamUpgradeShopkeeper'}, vape, function(tab, obj)
		table.insert(tab, {
			Id = obj.Name,
			RootPart = obj,
			Shop = obj:HasTag('BedwarsItemShop'),
			Upgrades = obj:HasTag('TeamUpgradeShopkeeper')
		})
	end)
	store.enchant = collection({'enchant-table', 'broken-enchant-table'}, vape, nil, function(tab, obj, tag)
		if obj:HasTag('enchant-table') and tag == 'broken-enchant-table' then return end
		obj = table.find(tab, obj)
		if obj then
			table.remove(tab, obj)
		end
	end)

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	local mapname = 'Unknown'
	sessioninfo:AddItem('Map', 0, function()
		return mapname
	end, false)

	task.delay(1, function()
		games:Increment()
	end)

	task.spawn(function()
		pcall(function()
			repeat task.wait() until store.matchState ~= 0 or vape.Loaded == nil
			if vape.Loaded == nil then return end
			local map = workspace:WaitForChild('Map', 9e9):WaitForChild('Worlds', 9e9):GetChildren()[1]
			mapname = map.Name
			mapname = string.gsub(string.split(mapname, '_')[2] or mapname, '-', '') or 'Blank'
			store.map = map
			vape:Clean(map.Blocks.ChildAdded:Connect(function(v)
				task.defer(function()
					if v:IsA('BasePart') and v:GetAttribute('Block') and (v:GetAttribute('PlacedByUserId') or 0) ~= 0 then
						local pos = v.Position / 3
						vapeEvents.PlaceBlockEvent:Fire({
							blockRef = {blockPosition = Vector3.new(math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))},
							player = playersService:GetPlayerByUserId(v:GetAttribute('PlacedByUserId'))
						})
					end
				end)
			end))
		end)
	end)

	vape:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
		if bedTable.player and bedTable.player.UserId == lplr.UserId then
			beds:Increment()
		end
	end))

	vape:Clean(vapeEvents.MatchEndEvent.Event:Connect(function(winTable)
		if (bedwars.Store:getState().Game.myTeam or {}).id == winTable.winningTeamId or lplr.Neutral then
			wins:Increment()
		end
	end))

	vape:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
		local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
		local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
		if not killed or not killer then return end

		if killed ~= lplr and killer == lplr then
			kills:Increment()
		end
	end))

	task.spawn(function()
		repeat task.wait() until store.map or vape.Loaded == nil
		if vape.Loaded == nil then return end
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Include
		rayParams.FilterDescendantsInstances = {store.map}
		store.airRay = rayParams

		repeat
			if entitylib.isAlive then
				entitylib.character.AirTime = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and tick() or entitylib.character.AirTime
			end

			for _, v in entitylib.List do
				v.LandTick = math.abs(v.RootPart.Velocity.Y) < 0.1 and v.LandTick or tick()
				if (tick() - v.LandTick) > 0.2 and v.Jumps ~= 0 then
					v.Jumps = 0
					v.Jumping = false
				end
			end
			task.wait()
		until vape.Loaded == nil
	end)

	pcall(function()
		if getthreadidentity and setthreadidentity then
			local old = getthreadidentity()
			setthreadidentity(2)

			bedwars.Shop = require(replicatedStorage.TS.games.bedwars.shop['bedwars-shop']).BedwarsShop
			bedwars.ShopItems = debug.getupvalue(debug.getupvalue(bedwars.Shop.getShopItem, 1), 2)
			bedwars.Shop.getShopItem('iron_sword', lplr)

			setthreadidentity(old)
			store.shopLoaded = true
		else
			task.spawn(function()
				repeat
					task.wait(0.1)
				until vape.Loaded == nil or bedwars.AppController:isAppOpen('BedwarsItemShopApp')

				bedwars.Shop = require(replicatedStorage.TS.games.bedwars.shop['bedwars-shop']).BedwarsShop
				bedwars.ShopItems = debug.getupvalue(debug.getupvalue(bedwars.Shop.getShopItem, 1), 2)
				store.shopLoaded = true
			end)
		end
	end)

	vape:Clean(function()
		task.wait(1)
		Client.Get = OldGet
		bedwars.BlockBreaker.hitBlock = OldHit
		bedwars.BlockController.isBlockBreakable = OldBreak
		store.blockPlacer:disable()
		for _, v in vapeEvents do
			v:Destroy()
		end
		for _, v in cache do
			table.clear(v[3])
			table.clear(v)
		end
		table.clear(store.blockPlacer)
		table.clear(vapeEvents)
		table.clear(bedwars)
		table.clear(store)
		table.clear(cache)
		table.clear(sides)
		table.clear(remotes)
		storeChanged:disconnect()
		storeChanged = nil
	end)
end)

local function getFunctionRange(func)
	local last = false
	for _, v in debug.getconstants(func) do
		if v == 'maxActivationDistance' then
			last = true
		elseif last then
			return v and typeof(v) == 'number' and v or nil
		end
	end
	return nil
end
getgenv().getFunctionRange = getFunctionRange

for _, v in {'AntiRagdoll', 'TriggerBot', 'SafeWalk', 'SilentAim', 'Jesus', 'AutoRejoin', 'Rejoin', 'Disabler', 'Timer', 'ServerHop', 'Wallhop', 'Xray', 'MouseTP', 'MurderMystery'} do
	vape:Remove(v)
end

run(function()
	local AimAssist
	local AimMode
	local Mode
	local Targets
	local Sort
	local AimPart
	local AimSpeed
	local Shake
	local Distance
	local AngleSlider
	local StrafeIncrease
	local BlockBreak
	local KillauraTarget
	local ClickAim
	local Mouse
	local Limit
	
	local function ease(t)
		return t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2
	end
	
	local cache = setmetatable({}, { __mode = 'k' })
	local function getMousePosition()
		if inputService.TouchEnabled then
			return gameCamera.ViewportSize / 2
		end
		return inputService.GetMouseLocation(inputService)
	end
	
	local function getAim(ent)
		if AimPart.Value == 'Closest' then
			if not cache[ent.Character] then
				cache[ent.Character] = ent.Character:GetChildren()
			end
			local localPosition, magnitude, part = getMousePosition(), 9e9, nil
			for _, v in cache[ent.Character] do
				if v and v.Parent and v:IsA('BasePart') then
					local position, vis = gameCamera.WorldToViewportPoint(gameCamera, v.Position)
	
					if vis then
						local mag = (localPosition - Vector2.new(position.x, position.y)).Magnitude
	
						if mag < magnitude then
							magnitude = mag
							part = v
						end
					end
				end
			end
			if part then
				return part.Position
			end
		end
		return ent.RootPart.Position
	end
	
	local started, lasttarget = 0, nil
	local aimfuncs = {
		Simple = function(localcframe, ent, fps)
			local rng = Random.new()
			local speed = (AimSpeed.Value + (StrafeIncrease.Enabled and (inputService:IsKeyDown(Enum.KeyCode.A) or inputService:IsKeyDown(Enum.KeyCode.D)) and 10 or 0))
	
			return localcframe:Lerp(CFrame.lookAt(localcframe.p, getAim(ent) + Vector3.new((rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps)), speed * fps), speed
		end,
		Adaptive = function(localcframe, ent, fps)
			local prog, rng = ease(math.min(tick() - started, 1)), Random.new()
			local speed = (AimSpeed.Value * 0.1 * prog) + (1 - prog) + (StrafeIncrease.Enabled and (inputService:IsKeyDown(Enum.KeyCode.A) or inputService:IsKeyDown(Enum.KeyCode.D)) and 10 or 5)
			return localcframe:Lerp(CFrame.lookAt(localcframe.p, getAim(ent) + Vector3.new((rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps)), speed * fps), speed
		end
	}
	
	local function GetTarget()
		if lasttarget then
			local localPosition = entitylib.character.RootPart.Position
			if not lasttarget or not lasttarget.RootPart or not lasttarget.Humanoid or not lasttarget.Humanoid.Health or lasttarget.Humanoid.Health <= 0 then
				return false
			end
			if (localPosition - lasttarget.RootPart.Position).Magnitude > Distance.Value then
				return false
			end
			if Targets.Walls.Enabled and entitylib.Wallcheck(localPosition, lasttarget.RootPart.Position, Targets.Walls.Enabled) then
				return false
			end
			return lasttarget
		end
	
		return false
	end
	
	local function getAttackData()
		if Mouse.Enabled and not inputService:IsMouseButtonPressed(0) and (tick() - bedwars.SwordController.lastSwing) > 0.15 then
			return false
		end
		if ClickAim.Enabled and (tick() - bedwars.SwordController.lastSwing) > 0.3 then
			return false
		end
		if BlockBreak.Enabled and (tick() - store.lastHit) < 0.3 then
			return false
		end
		if Limit.Enabled and store.hand.toolType ~= 'sword' then
			return false
		end
	
		if (tick() - started) > 1 or not lasttarget or not lasttarget.Parent or not lasttarget.Humanoid or lasttarget.Humanoid.Health <= 0 then
			local ent = GetTarget() or KillauraTarget.Enabled and store.KillauraTarget or entitylib.EntityPosition({
				Range = Distance.Value,
				Part = 'RootPart',
				Wallcheck = Targets.Walls.Enabled,
				Players = Targets.Players.Enabled,
				NPCs = Targets.NPCs.Enabled,
				Sort = sortmethods[Sort.Value],
			})
			if ent then
				started = tick()
			end
			lasttarget = ent
		else
			lasttarget = nil
		end
		return lasttarget
	end
	
	AimAssist = vape.Categories.Combat:CreateModule({
		Name = 'AimAssist',
		Function = function(callback)
			if callback then
				local rotate = 0
				
				AimAssist:Clean(runService.PostSimulation:Connect(function(dt)
					if entitylib.isAlive then
						entitylib.character.Humanoid.AutoRotate = tick() > rotate
	
						local ent = getAttackData()
						if ent then
							local root = entitylib.character.RootPart
							local delta = (ent.RootPart.Position - root.Position)
							local localfacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
							local horizontal = delta * Vector3.new(1, 0, 1)
							local angle = localfacing.Magnitude > 0 and horizontal.Magnitude > 0 and math.acos(math.clamp(localfacing.Unit:Dot(horizontal.Unit), -1, 1)) or 0
							if angle >= (math.rad(AngleSlider.Value) / 2) then
								return
							end
							targetinfo.Targets[ent] = tick() + 1
	
							local firstPerson = entitylib.character.Head.LocalTransparencyModifier == 1
							local perspective = AimMode.Value
	
							if perspective == 'Mouse' then
								local cframe, speed = aimfuncs[Mode.Value](gameCamera.CFrame, ent, dt)
								local viewport = gameCamera:WorldToViewportPoint(cframe.Position)
								local pos = (Vector2.new(viewport.X, viewport.Y) - inputService:GetMouseLocation()) * (speed / 15)
								mousemoverel(pos.X, pos.Y)
							elseif perspective == 'First person' or (perspective == 'Dynamic' and firstPerson) then
								if not firstPerson then return end
								local cframe = aimfuncs[Mode.Value](gameCamera.CFrame, ent, dt)
								gameCamera.CFrame = cframe
							elseif perspective == 'Third person' or (perspective == 'Dynamic' and not firstPerson) then
								if firstPerson then return end
								local cframe = aimfuncs[Mode.Value](root.CFrame, ent, dt)
								local direction = cframe.LookVector * Vector3.new(1, 0, 1)
								if direction.Magnitude > 0 then
									entitylib.character.Humanoid.AutoRotate = false
									root.CFrame = CFrame.lookAlong(root.Position, direction)
									rotate = tick() + 0.1
								end
							end
						end
					end
				end))
			else
				if entitylib.isAlive then
					entitylib.character.Humanoid.AutoRotate = true
				end
			end
		end,
		Tooltip = 'Smoothly aims to closest valid target with sword'
	})
	local modes = {}
	for i in aimfuncs do
		table.insert(modes, i)
	end
	AimMode = AimAssist:CreateDropdown({
		Name = 'Aim perspective',
		Tooltip = 'First person - Uses your camera to aim\nThird person - Moves your character to where your supposed to look\nMouse - Moves your mouse & camera\nDynamic - Uses first person mode if ur in first person, and uses third person if ur in third person',
		List = {'First person', 'Third person', 'Dynamic'},
		Default = 'First person'
	})
	Mode = AimAssist:CreateDropdown({
		Name = 'Mode',
		List = modes,
		Tooltip = 'Simple - Smooth aiming\nAdaptive - Advanced tracking with adaptive behavior',
		Default = modes[1],
	})
	Targets = AimAssist:CreateTargets({
		Players = true,
		Walls = true,
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	ClickAim = AimAssist:CreateToggle({
		Name = 'Click aim',
		Default = true,
	})
	Mouse = AimAssist:CreateToggle({Name = 'Require mouse down'})
	StrafeIncrease = AimAssist:CreateToggle({Name = 'Strafe increase'})
	BlockBreak = AimAssist:CreateToggle({Name = 'Check block break'})
	KillauraTarget = AimAssist:CreateToggle({Name = 'Use killaura target'})
	AimSpeed = AimAssist:CreateSlider({
		Name = 'Aim speed',
		Min = 1,
		Max = 20,
		Default = 6,
	})
	Distance = AimAssist:CreateSlider({
		Name = 'Distance',
		Min = 1,
		Max = 30,
		Default = 30,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
	})
	Shake = AimAssist:CreateSlider({
		Name = 'Shake',
		Min = 0,
		Max = 100,
		Default = 0,
		Tooltip = 'Adds random jitter to simulate human aim',
	})
	AngleSlider = AimAssist:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 70,
	})
	Limit = AimAssist:CreateToggle({
		Name = 'Limit to items',
		Tooltip = 'Only attacks when sword is held',
	})
	Sort = AimAssist:CreateDropdown({
		Name = 'Target mode',
		List = methods,
		Default = 'Angle',
	})
	AimPart = AimAssist:CreateDropdown({
		Name = 'Target area',
		List = {'Center', 'Closest'},
		Default = 'Center',
	})
end)

run(function()
	local AutoClicker
	local CPS
	local Wool
	local BlockCPS = {}
	local Thread
	
	local function AutoClick()
		if Thread then
			task.cancel(Thread)
		end
	
		Thread = task.delay(1 / (store.hand.toolType == 'block' and BlockCPS or CPS).GetRandomValue(), function()
			repeat
				if not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
					local blockPlacer = bedwars.BlockPlacementController.blockPlacer
					if store.hand.toolType == 'block' and (Wool.Enabled and store.hand.tool.Name:find('wool_') or not Wool.Enabled) and blockPlacer then
						if inputService.TouchEnabled then
							task.spawn(blockPlacer.autoBridge, blockPlacer, workspace:GetServerTimeNow() - bedwars.KnockbackController:getLastKnockbackTime() >= 0.2)
						else
							if (workspace:GetServerTimeNow() - bedwars.BlockCpsController.lastPlaceTimestamp) >= ((1 / 12) * 0.5) then
								local mouseinfo = blockPlacer.clientManager:getBlockSelector():getMouseInfo(0)
								if mouseinfo and mouseinfo.placementPosition == mouseinfo.placementPosition then
									task.spawn(blockPlacer.placeBlock, blockPlacer, mouseinfo.placementPosition)
								end
							end
						end
					elseif store.hand.toolType == 'sword' then
						bedwars.SwordController:swingSwordAtMouse(0.39)
					end
				end
	
				task.wait(1 / (store.hand.toolType == 'block' and BlockCPS or CPS).GetRandomValue())
			until not AutoClicker.Enabled
		end)
	end
	
	AutoClicker = vape.Categories.Combat:CreateModule({
		Name = 'AutoClicker',
		Function = function(callback)
			if callback then
				AutoClicker:Clean(inputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						AutoClick()
					end
				end))
	
				AutoClicker:Clean(inputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and Thread then
						task.cancel(Thread)
						Thread = nil
					end
				end))
	
				if inputService.TouchEnabled then
					for _, v in {'2', '5'} do
						pcall(function()
							AutoClicker:Clean(lplr.PlayerGui.MobileUI[v].MouseButton1Down:Connect(AutoClick))
							AutoClicker:Clean(lplr.PlayerGui.MobileUI[v].MouseButton1Up:Connect(function()
								if Thread then
									task.cancel(Thread)
									Thread = nil
								end
							end))
						end)
					end
				end
			else
				if Thread then
					task.cancel(Thread)
					Thread = nil
				end
			end
		end,
		Tooltip = 'Hold attack button to automatically click'
	})
	CPS = AutoClicker:CreateTwoSlider({
		Name = 'CPS',
		Min = 1,
		Max = 9,
		DefaultMin = 7,
		DefaultMax = 7
	})
	AutoClicker:CreateToggle({
		Name = 'Place Blocks',
		Default = true,
		Function = function(callback)
			if BlockCPS.Object then
				BlockCPS.Object.Visible = callback
			end
	
			if Wool and Wool.Object then
				Wool.Object.Visible = callback
			end
		end
	})
	Wool = AutoClicker:CreateToggle({Name = 'Wool only', Tooltip = 'Only clicks when you are holding wool.', Darker = true})
	BlockCPS = AutoClicker:CreateTwoSlider({
		Name = 'Block CPS',
		Min = 1,
		Max = 12,
		DefaultMin = 12,
		DefaultMax = 12,
		Darker = true
	})
end)

run(function()
	local BlockReach
	local BlockRange
	local BreakReach
	local BreakRange
	local SwordReach
	local SwordRange
	
	local old
	
	Reach = vape.Categories.Combat:CreateModule({
		Name = 'Reach',
		Tooltip = 'Allows you to place, attack, and break further',
		Function = function(callback)
			bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = callback and SwordReach.Enabled and SwordRange.Value + 2 or 14.4
			if callback then
				old = bedwars.BlockSelector.getMouseInfo
				bedwars.BlockSelector.getMouseInfo = function(...)
					local Self, Select, Args = ...
					if not Args then
						Args = {}
					end
					if Select == 0 then
						Args.range = BlockReach.Enabled and BlockRange.Value or 24
					elseif Select == 1 then
						Args.range = BreakReach.Enabled and BreakRange.Value or 18
					end
					return old(Self, Select, Args)
				end
			else
				bedwars.BlockSelector.getMouseInfo = old
				old = nil
			end
		end,
	})
	SwordReach = Reach:CreateToggle({
		Name = 'Sword Reach',
		Function = function(callback)
			bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = Reach.Enabled and callback and SwordRange.Value + 2 or 14.4
			pcall(function()
				SwordRange.Object.Visible = callback
			end)
		end,
		Default = true
	})
	SwordRange = Reach:CreateSlider({
		Name = 'Sword Range',
		Min = 1,
		Max = 18,
		Default = 18,
		Decimal = 5,
		Darker = true,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end,
		Function = function(val)
			bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = Reach.Enabled and SwordReach.Enabled and val or 14.4
		end
	})
	BlockReach = Reach:CreateToggle({
		Name = 'Placement Reach',
		Function = function(callback)
			BlockRange.Object.Visible = callback
		end
	})
	BlockRange = Reach:CreateSlider({
		Name = 'Placement Range',
		Min = 1,
		Max = 60,
		Default = 18,
		Darker = true,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end,
		Visible = false
	})
	BreakReach = Reach:CreateToggle({
		Name = 'Break Reach',
		Function = function(callback)
			BreakRange.Object.Visible = callback
		end
	})
	BreakRange = Reach:CreateSlider({
		Name = 'Break Range',
		Min = 1,
		Max = 30,
		Default = 30,
		Decimal = 5,
		Darker = true,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end,
		Visible = false
	})
	Reach:CreateButton({
		Name = 'Reset to default reach',
		Tooltip = 'Resets every range back to default',
		Function = function()
			BreakRange:SetValue(18)
			BlockRange:SetValue(24)
			SwordRange:SetValue(12.4)
		end
	})
end)

run(function()
	local SilentAim
	local Targets
	local TargetPart
	local Sort
	local Prediction
	local FOV
	local OtherProjectiles
	local Blacklist
	
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Include
	rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild('Map')}
	
	local hooked = false
	local removeNamecall
	local fireRemote
	local hookVersion = 0
	
	local function getMousePosition()
		if inputService.TouchEnabled then
			return gameCamera.ViewportSize / 2
		end
		return inputService.GetMouseLocation(inputService)
	end
	
	local function getPosition(ent)
		if TargetPart.Value == 'Closest' then
			local localPosition, magnitude, part = getMousePosition(), 9e9, nil
			for _, v in ent:GetChildren() do
				if v:IsA('BasePart') then
					local position, vis = gameCamera.WorldToViewportPoint(gameCamera, v.Position)
					if vis then
						local mag = (localPosition - Vector2.new(position.x, position.y)).Magnitude
						if mag < magnitude then
							magnitude = mag
							part = v
						end
					end
				end
			end
			return part and part.Position or ent.PrimaryPart and ent.PrimaryPart.Position
		elseif TargetPart.Value == 'Dynamic' then
			local tool = store.hand.tool
			if tool and tool.Name:find('headhunter') and ent:FindFirstChild('Head') then
				return ent.Head.Position
			end
			return ent.PrimaryPart and ent.PrimaryPart.Position
		end
		return
	end
	
	local function solveSilent(args)
		local origin, velocity, projType = args[4], args[6], args[3]
		if typeof(origin) ~= 'Vector3' or typeof(velocity) ~= 'Vector3' or type(projType) ~= 'string' then
			return
		end
	
		if (not OtherProjectiles.Enabled) and not projType:find('arrow') then
			return
		end
	
		if table.find(Blacklist.ListEnabled or {}, ((projType == 'glue_trap' or projType == 'glue_projectile') and 'gloop' or projType)) then
			return
		end
	
		local meta = bedwars.ProjectileMeta[projType]
		if not meta then return end
	
		local speed = velocity.Magnitude
		if speed <= 0 then return end
		local gravity = meta.gravitationalAcceleration or 196.2
	
		local plr = entitylib.EntityMouse({
			Part = 'RootPart',
			Range = FOV.Value,
			Players = Targets.Players.Enabled,
			NPCs = Targets.NPCs.Enabled,
			Wallcheck = Targets.Walls.Enabled,
			Sort = sortmethods[Sort.Value or 'Distance'],
			Origin = origin,
		})
		if not plr then return end
	
		local targetpart = plr[TargetPart.Value]
		local targetpos = getPosition(plr.Character) or targetpart and targetpart.Position
		if not targetpos then return end
		local playerGravity = workspace.Gravity
		local balloons = plr.Character:GetAttribute('InflatedBalloons')
		if balloons and balloons > 0 then
			playerGravity = workspace.Gravity * (1 - (balloons >= 4 and 1.2 or balloons >= 3 and 1 or 0.975))
		end
	
		local pearl = projType == 'telepearl'
		local targetVelocity = pearl and Vector3.zero or plr.RootPart.AssemblyLinearVelocity
		local targetAirborne = not pearl and plr.Humanoid.FloorMaterial == Enum.Material.Air or math.abs(targetVelocity.Y) > 0.01
		local calc, _, travelTime = prediction.SolveTrajectory(origin, speed * Prediction.Value, gravity, targetpos, targetVelocity, playerGravity, plr.HipHeight, plr.Jumping and 42.6 or nil, rayCheck, targetAirborne, plr.RootPart.Position, plr.RootPart, nil, true)
		if not calc or not travelTime or travelTime > (meta.lifetimeSec or 3) then return end
	
		targetinfo.Targets[plr] = tick() + 1
		return CFrame.lookAt(origin, calc).LookVector * speed
	end
	
	SilentAim = vape.Categories.Combat:CreateModule({
		Name = 'SilentAim',
		Function = function(callback)
			hookVersion += 1
			if callback and not namecall then
				namecall = hookmetamethod(game, '__namecall', newcclosure(function(...)
					if SilentAim.Enabled and not checkcaller() and getnamecallmethod() == 'InvokeServer' and tostring(...) == 'ProjectileFire' then
						local self = ...
						local args = {select(2, ...)}
						print('yo its kinda working')
						local newVelocity = solveSilent(args)
						if newVelocity then
							args[6] = newVelocity
						end
						return namecall(self, self.InvokeServer(self, unpack(args)))
					end
					return namecall(...)
				end))
			end
		end,
		Tooltip = 'Redirects only the projectile values sent to the server, so enemies get hit while your shot flies exactly where you aimed on your own screen'
	})
	Targets = SilentAim:CreateTargets({
		Players = true,
		Walls = true,
	})
	TargetPart = SilentAim:CreateDropdown({
		Name = 'Part',
		List = {'RootPart', 'Head', 'Dynamic', 'Closest'},
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	Sort = SilentAim:CreateDropdown({
		Name = 'Target Mode',
		List = methods,
		Default = 'Distance'
	})
	Prediction = SilentAim:CreateSlider({
		Name = 'Prediction',
		Min = 0.1,
		Max = 2,
		Default = 1,
		Decimal = 10
	})
	FOV = SilentAim:CreateSlider({
		Name = 'FOV',
		Min = 1,
		Max = 1000,
		Default = 1000
	})
	OtherProjectiles = SilentAim:CreateToggle({
		Name = 'Other Projectiles',
		Function = function(call)
			if Blacklist and Blacklist.Object then
				Blacklist.Object.Visible = call
			end
		end,
	    Default = true
	})
	Blacklist = SilentAim:CreateTextList({
		Name = 'Blacklist',
		Default = {'gloop', 'telepearl'},
		Darker = true,
		Placeholder = 'projectile'
	})
end)

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
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() 
					task.delay(0.1, function() 
						bedwars.SprintController:stopSprinting() 
					end) 
				end))
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
	local TriggerBot
	local CPS
	local rayParams = RaycastParams.new()
	
	TriggerBot = vape.Categories.Combat:CreateModule({
		Name = 'TriggerBot',
		Function = function(callback)
			if callback then
				repeat
					local doAttack
					if not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
						if entitylib.isAlive and store.hand.toolType == 'sword' and bedwars.DaoController.chargingMaid == nil then
							local attackRange = bedwars.ItemMeta[store.hand.tool.Name].sword.attackRange
							rayParams.FilterDescendantsInstances = {lplr.Character}
	
							local unit = lplr:GetMouse().UnitRay
							local localPos = entitylib.character.RootPart.Position
							local rayRange = (attackRange or 14.4)
							local ray = bedwars.QueryUtil:raycast(unit.Origin, unit.Direction * 200, rayParams)
							if ray and (localPos - ray.Instance.Position).Magnitude <= rayRange then
								local limit = (attackRange)
								for _, ent in entitylib.List do
									doAttack = ent.Targetable and ray.Instance:IsDescendantOf(ent.Character) and (localPos - ent.RootPart.Position).Magnitude <= rayRange
									if doAttack then
										break
									end
								end
							end
	
							doAttack = doAttack or bedwars.SwordController:getTargetInRegion(attackRange or 3.8 * 3, 0)
							if doAttack then
								bedwars.SwordController:swingSwordAtMouse()
							end
						end
					end
	
					task.wait(doAttack and 1 / CPS.GetRandomValue() or 0.016)
				until not TriggerBot.Enabled
			end
		end,
		Tooltip = 'Automatically swings when hovering over a entity'
	})
	CPS = TriggerBot:CreateTwoSlider({
		Name = 'CPS',
		Min = 1,
		Max = 9,
		DefaultMin = 7,
		DefaultMax = 7
	})
end)

run(function()
	local Velocity
	local Horizontal
	local Vertical
	local Chance
	local TargetCheck
	local rand, old = Random.new()
	
	Velocity = vape.Categories.Combat:CreateModule({
		Name = 'Velocity',
		Function = function(callback)
			if callback then
				old = bedwars.KnockbackUtil.applyKnockback
				bedwars.KnockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
					if rand:NextNumber(0, 100) > Chance.Value then return end
					local check = (not TargetCheck.Enabled) or entitylib.EntityPosition({
						Range = 50,
						Part = 'RootPart',
						Players = true
					})
	
					if check then
						knockback = knockback or {}
						if Horizontal.Value == 0 and Vertical.Value == 0 then return end
						knockback.horizontal = (knockback.horizontal or 1) * (Horizontal.Value / 100)
						knockback.vertical = (knockback.vertical or 1) * (Vertical.Value / 100)
					end
					
					return old(root, mass, dir, knockback, ...)
				end
			else
				bedwars.KnockbackUtil.applyKnockback = old
			end
		end,
		Tooltip = 'Reduces knockback taken'
	})
	Horizontal = Velocity:CreateSlider({
		Name = 'Horizontal',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%'
	})
	Vertical = Velocity:CreateSlider({
		Name = 'Vertical',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%'
	})
	Chance = Velocity:CreateSlider({
		Name = 'Chance',
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
	TargetCheck = Velocity:CreateToggle({Name = 'Only when targeting'})
end)

run(function()
	local AntiDeath
	local StopThreshold
	local Threshold
	local Notify
	local Delay
	local Mode
	
	local oldroot, clone, hip = nil, nil, 2.7
	
	local function createClone()
	    if store.rootpart then return false end
	    if entitylib.isAlive and entitylib.character.Humanoid.Health > 0 and (not oldroot or not oldroot.Parent) then
	        hip = entitylib.character.Humanoid.HipHeight
	        oldroot = entitylib.character.HumanoidRootPart
	        if not lplr.Character.Parent then return false end
	        lplr.Character.Parent = replicatedStorage
	        clone = oldroot:Clone()
	        clone.Parent = lplr.Character
	        oldroot.Transparency = 1
	        oldroot.Parent = workspace
	        store.rootpart = oldroot
	        lplr.Character.PrimaryPart = clone
	        lplr.Character.Parent = workspace
	        bedwars.QueryUtil:setQueryIgnored(clone, true)
	        bedwars.QueryUtil:setQueryIgnored(oldroot, true)
	        return true
	    end
	    return false
	end
	
	local function destroyClone()
	    local char = lplr.Character
	    if oldroot and oldroot.Parent and char then 
	        char.Parent = replicatedStorage
	        oldroot.Parent = char
	        if clone then
	            clone:Destroy()
	            clone = nil
	        end
	        char.PrimaryPart = oldroot
	        char.Parent = workspace
	        oldroot.CanCollide = true
	        local humanoid = char:FindFirstChildOfClass('Humanoid')
	        if humanoid then
	            humanoid.HipHeight = hip or 2.6
	        end
	        oldroot.Transparency = 1
	        oldroot = nil
	        store.rootpart = nil
	        return true
	    end
	    if clone then
	        clone:Destroy()
	        clone = nil
	    end
	    oldroot = nil
	    store.rootpart = nil
	    return false
	end
	
	local Paused, Activated = 0, 0
	
	AntiDeath = vape.Categories.Blatant:CreateModule({
	    Name = 'AntiDeath',
	    Function = function(call)
	        if call then
	            local FloatTime = tick();
	
	            AntiDeath:Clean(runService.PreSimulation:Connect(function()
	                if oldroot and oldroot.Parent then
	                    if (tick() - entitylib.character.AirTime) > 1.7 then
	                        FloatTime = tick() + 0.2
	                    end
	                    oldroot.Velocity = Vector3.new(0, 1, 0)
	                    oldroot.CFrame = clone.CFrame - (tick() > FloatTime and Vector3.new(0, 200, 0) or Vector3.zero)
	                end
	            end))
	
	            repeat
	                if tick() > Paused and entitylib.isAlive and (entitylib.character.Humanoid.Health <= Threshold.Value) then
	                    if (tick() - Activated) >= Delay.Value then
	                        Activated = tick()
	
	                        if Notify.Enabled then
	                            notif('AntiDeath', `Health below {Threshold.Value}%`, 12, 'warning')
	                        end
	
	                        if Mode.Value == 'Teleport' then
	                            lplr.Character.PrimaryPart.CFrame += Vector3.new(0, 100, 0)
	                            Paused = tick() + 5
	                        elseif Mode.Value == 'Invincibility' then
	                            if createClone() then
	                                Paused = tick() + 5
	                                task.delay(0, function()
	                                    repeat task.wait() until not AntiDeath.Enabled or not entitylib.isAlive or (entitylib.character.Humanoid.Health >= StopThreshold.Value)
	                                    local old = clone and clone.CFrame or nil
	                                    if destroyClone() and old then
	                                        entitylib.character.RootPart.CFrame = old
	                                    end
	                                    Paused = tick() + 5
	
	                                    if AntiDeath.Enabled and Notify.Enabled then
	                                        notif('AntiDeath', 'You are visible again', 12, 'info')
	                                    end
	                                end)
	                            end
	                        end
	                    end
	                end
	                task.wait()
	            until not AntiDeath.Enabled
	        else
	            destroyClone()
	        end
	    end,
	    Tooltip = 'Uses selected mode when on a threshold'
	})
	
	Mode = AntiDeath:CreateDropdown({
	    Name = 'Mode',
	    List = {'Teleport', 'Invincibility'},
	    Default = 'Invincibility',
	    Tooltip = 'Teleport - Teleports you high up\nInvincibility - Makes you unhittable'
	})
	StopThreshold = AntiDeath:CreateSlider({
	    Name = 'Stop Threshold',
	    Min = 1,
	    Max = 100,
	    Default = 30,
	    Suffix = function()
	        return '%'
	    end,
	    Tooltip = 'Health percentage to untrigger at'
	})
	Threshold = AntiDeath:CreateSlider({
	    Name = 'Threshold',
	    Min = 1,
	    Max = 100,
	    Default = 30,
	    Suffix = function()
	        return '%'
	    end,
	    Tooltip = 'Health percentage to trigger at'
	})
	Delay = AntiDeath:CreateSlider({
	    Name = 'Delay',
	    Min = 1,
	    Max = 20,
	    Default = 5,
	    Suffix = function(val)
	        return val <= 1 and 'sec' or 'secs'
	    end,
	    Tooltip = 'Delay between triggers'
	})
	Notify = AntiDeath:CreateToggle({
	    Name = 'Notify on trigger',
	    Default = true
	})
	
end)

local AntiFallDirection
run(function()
	local AntiFall
	local Mode
	local Material
	local Color
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true

	local function getLowGround()
		local mag = math.huge
		for _, pos in bedwars.BlockController:getStore():getAllBlockPositions() do
			pos = pos * 3
			if pos.Y < mag and not getPlacedBlock(pos + Vector3.new(0, 3, 0)) then
				mag = pos.Y
			end
		end
		return mag
	end

	AntiFall = vape.Categories.Blatant:CreateModule({
		Name = 'AntiFall',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.matchState ~= 0 or (not AntiFall.Enabled)
				if not AntiFall.Enabled then return end

				local pos, debounce = getLowGround(), tick()
				if pos ~= math.huge then
					AntiFallPart = Instance.new('Part')
					AntiFallPart.Size = Vector3.new(10000, 1, 10000)
					AntiFallPart.Transparency = 1 - Color.Opacity
					AntiFallPart.Material = Enum.Material[Material.Value]
					AntiFallPart.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
					AntiFallPart.Position = Vector3.new(0, pos - 2, 0)
					AntiFallPart.CanCollide = Mode.Value == 'Collide'
					AntiFallPart.Anchored = true
					AntiFallPart.CanQuery = false
					AntiFallPart.Parent = workspace
					AntiFall:Clean(AntiFallPart)
					AntiFall:Clean(AntiFallPart.Touched:Connect(function(touched)
						if touched.Parent == lplr.Character and entitylib.isAlive and debounce < tick() then
							debounce = tick() + 0.1
							if Mode.Value == 'Normal' then
								local top = getNearGround()
								if top then
									local lastTeleport = lplr:GetAttribute('LastTeleported')
									local connection
									connection = runService.PreSimulation:Connect(function()
										if vape.Modules.Fly.Enabled or vape.Modules.LongJump.Enabled then
											connection:Disconnect() -- i fixed, inffly doesnt exist
											AntiFallDirection = nil
											return
										end

										if entitylib.isAlive and lplr:GetAttribute('LastTeleported') == lastTeleport then
											local delta = ((top - entitylib.character.RootPart.Position) * Vector3.new(1, 0, 1))
											local root = entitylib.character.RootPart
											AntiFallDirection = delta.Unit == delta.Unit and delta.Unit or Vector3.zero
											root.Velocity *= Vector3.new(1, 0, 1)
											rayCheck.FilterDescendantsInstances = {gameCamera, lplr.Character}
											rayCheck.CollisionGroup = root.CollisionGroup

											local ray = workspace:Raycast(root.Position, AntiFallDirection, rayCheck)
											if ray then
												for _ = 1, 10 do
													local dpos = roundPos(ray.Position + ray.Normal * 1.5) + Vector3.new(0, 3, 0)
													if not getPlacedBlock(dpos) then
														top = Vector3.new(top.X, pos.Y, top.Z)
														break
													end
												end
											end

											root.CFrame += Vector3.new(0, top.Y - root.Position.Y, 0)
											if not frictionTable.Speed then
												root.AssemblyLinearVelocity = (AntiFallDirection * getSpeed()) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
											end

											if delta.Magnitude < 1 then
												connection:Disconnect()
												AntiFallDirection = nil
											end
										else
											connection:Disconnect()
											AntiFallDirection = nil
										end
									end)
									AntiFall:Clean(connection)
								end
							elseif Mode.Value == 'Velocity' then
								entitylib.character.RootPart.Velocity = Vector3.new(entitylib.character.RootPart.Velocity.X, 100, entitylib.character.RootPart.Velocity.Z)
							end
						end
					end))
				end
			else
				AntiFallDirection = nil
			end
		end,
		Tooltip = 'Help\'s you with your Parkinson\'s\nPrevents you from falling into the void.'
	})
	Mode = AntiFall:CreateDropdown({
		Name = 'Move Mode',
		List = {'Normal', 'Collide', 'Velocity'},
		Function = function(val)
			if AntiFallPart then
				AntiFallPart.CanCollide = val == 'Collide'
			end
		end,
	Tooltip = 'Normal - Smoothly moves you towards the nearest safe point\nVelocity - Launches you upward after touching\nCollide - Allows you to walk on the part'
	})
	local materials = {'ForceField'}
	for _, v in Enum.Material:GetEnumItems() do
		if v.Name ~= 'ForceField' then
			table.insert(materials, v.Name)
		end
	end
	Material = AntiFall:CreateDropdown({
		Name = 'Material',
		List = materials,
		Function = function(val)
			if AntiFallPart then
				AntiFallPart.Material = Enum.Material[val]
			end
		end
	})
	Color = AntiFall:CreateColorSlider({
		Name = 'Color',
		DefaultOpacity = 0.5,
		Function = function(h, s, v, o)
			if AntiFallPart then
				AntiFallPart.Color = Color3.fromHSV(h, s, v)
				AntiFallPart.Transparency = 1 - o
			end
		end
	})
end)

run(function()
    local AutoChargeProj
    local Percentage

    local old

    AutoChargeProj = vape.Categories.Blatant:CreateModule({
        Name = 'AutoChargeProj',
        Function = function(callback)
            if callback then
                old = bedwars.ProjectileController.calculateImportantLaunchValues
                bedwars.ProjectileController.calculateImportantLaunchValues = function(...)
                    local args = {...}
                    args[2].drawDurationSeconds = math.max(args[2].drawDurationSeconds, bedwars.ProjectileMeta[args[2].projectile].predictionLifetimeSec * (Percentage.Value / 100))
                    args[2].velocityMultiplier = math.max(args[2].velocityMultiplier, 1 * (Percentage.Value / 100))
                    return old(unpack(args))
                end
            elseif old then
                bedwars.ProjectileController.calculateImportantLaunchValues = old
                old = nil
            end
        end,
        Tooltip = 'Instantly charges your projectile item to a certain percentage'
    })

    Percentage = AutoChargeProj:CreateSlider({
        Name = 'Percentage',
        Min = 0,
        Max = 100,
        Default = 50,
        Suffix = '%'
    })
end)

run(function()
	local CannonSpeed
	local Value
	
	CannonSpeed = vape.Categories.Blatant:CreateModule({
	    Name = 'CannonSpeed',
	    Function = function(callback)
	        debug.setconstant(bedwars.CannonHandController.launchSelf, 15, callback and Value.Value or 200)
	    end,
	    Tooltip = 'Makes you go faster with cannon.'
	})
	
	Value = CannonSpeed:CreateSlider({
	    Name = 'Speed',
	    Min = 1,
	    Max = 400,
	    Default = 200,
	    Function = function(val)
	        if CannonSpeed.Enabled then
	            debug.setconstant(bedwars.CannonHandController.launchSelf, 15, val)
	        end
	    end,
	    Suffix = function(val)
	        return val <= 1 and 'stud' or 'studs'
	    end
	})
	CannonSpeed:CreateButton({
	    Name = 'Sync to legit speed',
	    Function = function()
	        Value:SetValue(200)
	    end
	})
end)

run(function()
	local DamageBoost
	local stack
	
	DamageBoost = vape.Categories.Blatant:CreateModule({
		Name = 'DamageBoost',
		Function = function(callback)
			if callback then
				DamageBoost:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if entitylib.isAlive and tick() > (stack or 0) and damageTable.entityInstance == lplr.Character and not vape.Modules.LongJump.Enabled then
						local horizontal = (damageTable.knockbackMultiplier and damageTable.knockbackMultiplier.horizontal or 0)
						knockbackSpeed = bedwars.KnockbackUtil.calculateKnockbackVelocity(Vector3.one, 1, {
							vertical = 0,
							horizontal = horizontal,
						}).Magnitude * (0.9 + store.ping.total)
	                    stack = tick() + (knockbackSpeed / 45)
	                    knockbackBoost = tick() + (horizontal / 3.5)
					end
				end))
			end
		end,
	    Tooltip = 'Makes you go slightly faster when damaged'
	})
end)

run(function()
	local FastBreak
	local BedCheck
	local Blacklist
	local Blacklisted
	local Time
	
	local newlist, old = {}, nil
	local function find(tab, ind)
		for i, v in tab do
			if v == ind or v:find(ind) then
				return i
			end
		end
		return nil
	end
	
	FastBreak = vape.Categories.Blatant:CreateModule({
		Name = 'FastBreak',
		Function = function(callback)
			if callback then
				old = bedwars.BlockBreaker.hitBlock
				bedwars.BlockBreaker.hitBlock = function(self, ...)
					local _, params = unpack({...})
					pcall(function()
						local block, info = nil, self.clientManager:getBlockSelector():getMouseInfo(1, {ray = params})
						block = info and info.target and info.target.blockInstance or nil
						if block and (not Blacklist.Enabled or not find(newlist, block.Name)) and (not BedCheck.Enabled or block.Name ~= 'bed') then
							bedwars.BlockBreakController.blockBreaker:setCooldown(Time.Value)
						end
					end)
	
					return old(self, ...)
				end
	
				repeat
					if (tick() - store.lastHit) > 0.3 then
						bedwars.BlockBreakController.blockBreaker:setCooldown(0.3)
					end
					task.wait(0.1)
				until not FastBreak.Enabled
			elseif old then
				bedwars.BlockBreaker.hitBlock = old
				bedwars.BlockBreakController.blockBreaker:setCooldown(0.3)
			end
		end,
		Tooltip = 'Decreases block hit cooldown'
	})
	Time = FastBreak:CreateSlider({
		Name = 'Break speed',
		Min = 0,
		Max = 0.3,
		Default = 0.25,
		Decimal = 100,
		Suffix = 'seconds'
	})
	FastBreak:CreateButton({
		Name = 'Sync to legit speed',
		Function = function()
			Time:SetValue(0.3)
		end
	})
	BedCheck = FastBreak:CreateToggle({
		Name = 'Bed Check',
		Tooltip = 'Doesn\'t increase speed if ur breaking a bed'
	})
	Blacklist = FastBreak:CreateToggle({
		Name = 'Use blacklist',
		Function = function(callback)
			if Blacklisted and Blacklisted.Object then
				Blacklisted.Object.Visible = callback
			end
		end
	})
	Blacklisted = FastBreak:CreateTextList({
		Name = 'Blocks',
		Function = function(list)
			newlist = {}
			for _, v in list do
				if v:find('iron') then
					table.insert(newlist, 'iron_ore_mesh_block')
				else
					table.insert(newlist, v)
				end
			end
		end,
		Darker = true,
		Visible = false
	})
end)

local Fly
local LongJump
run(function()
	local Value
	local VerticalValue
	local WallCheck
	local PopBalloons
	local TP
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local up, down, old = 0, 0

	Fly = vape.Categories.Blatant:CreateModule({
		Name = 'Fly',
		Function = function(callback)
			frictionTable.Fly = callback or nil
			updateVelocity()
			if callback then
				up, down, old = 0, 0, bedwars.BalloonController.deflateBalloon
				bedwars.BalloonController.deflateBalloon = function() end
				local tpTick, tpToggle, oldy = tick(), true

				if lplr.Character and (lplr.Character:GetAttribute('InflatedBalloons') or 0) == 0 and getItem('balloon') then
					bedwars.BalloonController:inflateBalloon()
				end
				Fly:Clean(vapeEvents.AttributeChanged.Event:Connect(function(changed)
					if changed == 'InflatedBalloons' and (lplr.Character:GetAttribute('InflatedBalloons') or 0) == 0 and getItem('balloon') then
						bedwars.BalloonController:inflateBalloon()
					end
				end))
				Fly:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive and not InfiniteFly.Enabled and isnetworkowner(entitylib.character.RootPart) then
						local flyAllowed = (lplr.Character:GetAttribute('InflatedBalloons') and lplr.Character:GetAttribute('InflatedBalloons') > 0) or store.matchState == 2
						local mass = (1.5 + (flyAllowed and 6 or 0) * (tick() % 0.4 < 0.2 and -1 or 1)) + ((up + down) * VerticalValue.Value)
						local root, moveDirection = entitylib.character.RootPart, entitylib.character.Humanoid.MoveDirection
						local velo = getSpeed()
						local destination = (moveDirection * math.max(Value.Value - velo, 0) * dt)
						rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, AntiFallPart}
						rayCheck.CollisionGroup = root.CollisionGroup

						if WallCheck.Enabled then
							local ray = workspace:Raycast(root.Position, destination, rayCheck)
							if ray then
								destination = ((ray.Position + ray.Normal) - root.Position)
							end
						end

						if not flyAllowed then
							if tpToggle then
								local airleft = (tick() - entitylib.character.AirTime)
								if airleft > 2 then
									if not oldy then
										local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
										if ray and TP.Enabled then
											tpToggle = false
											oldy = root.Position.Y
											tpTick = tick() + 0.11
											root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, ray.Position.Y + entitylib.character.HipHeight, root.Position.Z), root.CFrame.LookVector)
										end
									end
								end
							else
								if oldy then
									if tpTick < tick() then
										local newpos = Vector3.new(root.Position.X, oldy, root.Position.Z)
										root.CFrame = CFrame.lookAlong(newpos, root.CFrame.LookVector)
										tpToggle = true
										oldy = nil
									else
										mass = 0
									end
								end
							end
						end

						root.CFrame += destination
						root.AssemblyLinearVelocity = (moveDirection * velo) + Vector3.new(0, mass, 0)
					end
				end))
				Fly:Clean(inputService.InputBegan:Connect(function(input)
					if not inputService:GetFocusedTextBox() then
						if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
							up = 1
						elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
							down = -1
						end
					end
				end))
				Fly:Clean(inputService.InputEnded:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
						up = 0
					elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
						down = 0
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						Fly:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
							up = jumpButton.ImageRectOffset.X == 146 and 1 or 0
						end))
					end)
				end
			else
				bedwars.BalloonController.deflateBalloon = old
				if PopBalloons.Enabled and entitylib.isAlive and (lplr.Character:GetAttribute('InflatedBalloons') or 0) > 0 then
					for _ = 1, 3 do
						bedwars.BalloonController:deflateBalloon()
					end
				end
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end,
		Tooltip = 'Makes you go zoom.'
	})
	Value = Fly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 23,
		Default = 23,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	VerticalValue = Fly:CreateSlider({
		Name = 'Vertical Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	WallCheck = Fly:CreateToggle({
		Name = 'Wall Check',
		Default = true
	})
	PopBalloons = Fly:CreateToggle({
		Name = 'Pop Balloons',
		Default = true
	})
	TP = Fly:CreateToggle({
		Name = 'TP Down',
		Default = true
	})
end)

run(function()
	local Mode
	local Expand
	local objects, set = {}
	
	local function createHitbox(ent)
		if ent.Targetable and ent.Player then
			local hitbox = Instance.new('Part')
			hitbox.Size = Vector3.new(3, 6, 3) + Vector3.one * (Expand.Value / 5)
			hitbox.Position = ent.RootPart.Position
			hitbox.CanCollide = false
			hitbox.Massless = true
			hitbox.Transparency = 1
			hitbox.Parent = ent.Character
			local weld = Instance.new('Motor6D')
			weld.Part0 = hitbox
			weld.Part1 = ent.RootPart
			weld.Parent = hitbox
			objects[ent] = hitbox
		end
	end
	
	HitBoxes = vape.Categories.Blatant:CreateModule({
		Name = 'HitBoxes',
		Function = function(callback)
			if callback then
				if Mode.Value == 'Sword' then
					debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, (Expand.Value / 3))
					set = true
				else
					HitBoxes:Clean(entitylib.Events.EntityAdded:Connect(createHitbox))
					HitBoxes:Clean(entitylib.Events.EntityRemoving:Connect(function(ent)
						if objects[ent] then
							objects[ent]:Destroy()
							objects[ent] = nil
						end
					end))
					for _, ent in entitylib.List do
						createHitbox(ent)
					end
				end
			else
				if set then
					debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, 3.8)
					set = nil
				end
				for _, part in objects do
					part:Destroy()
				end
				table.clear(objects)
			end
		end,
		Tooltip = 'Expands attack hitbox'
	})
	Mode = HitBoxes:CreateDropdown({
		Name = 'Mode',
		List = {'Sword', 'Player'},
		Function = function()
			if HitBoxes.Enabled then
				HitBoxes:Toggle()
				HitBoxes:Toggle()
			end
		end,
		Tooltip = 'Sword - Increases the range around you to hit entities\nPlayer - Increases the players hitbox'
	})
	Expand = HitBoxes:CreateSlider({
		Name = 'Expand amount',
		Min = 0,
		Max = 14.4,
		Default = 14.4,
		Decimal = 10,
		Function = function(val)
			if HitBoxes.Enabled then
				if Mode.Value == 'Sword' then
					debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, (val / 3))
				else
					for _, part in objects do
						part.Size = Vector3.new(3, 6, 3) + Vector3.one * (val / 5)
					end
				end
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	vape.Categories.Blatant:CreateModule({
		Name = 'KeepSprint',
		Function = function(callback)
			debug.setconstant(bedwars.SprintController.startSprinting, 5, callback and 'blockSprinting' or 'blockSprint')
			bedwars.SprintController:stopSprinting()
		end,
		Tooltip = 'Lets you sprint with a speed potion.'
	})
end)

local Attacking
run(function()
	local Killaura
	local Targets
	local Sort
	local FastHits
	local SwingRange
	local AttackRange
	local SwingTime
	local AttackSpeed
	-- local Sync = {}
	local AngleSlider
	-- local ChanceSlider
	local HitRegChance
	local MaxTargets
	local Mouse
	local Attackable
	local Swing
	local GUI
	local BoxSwingColor
	local BoxAttackColor
	local BoxAttackTween
	local BoxAttackSpeed
	local BoxAttackSpeedEnd
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local Face
	local Animation
	local AnimationMode
	local AnimationSpeed
	local AnimationTween
	local Limit
	local LegitAura
	local Particles, Boxes = {}, {}
	local anims, AnimDelay, AnimTween, armC0 = vape.Libraries.auraanims, tick()
	local AttackRemote = {FireServer = function() end}
	local SwordSwingMiss = {FireServer = function() end}
	local projectileRemote = bedwars.Handler:Get('ProjectileFire')
	local fastHitPending, lastShot = nil, 0
	task.spawn(function()
		AttackRemote = bedwars.Handler:Get('SwordHit')
		SwordSwingMiss = bedwars.Handler:Get('SwordSwingMiss')
	end)

	local function getAttackData()
		if Mouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end

		if GUI.Enabled then
			if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then return false end
		end

		if Attackable.Enabled then
			if not entitylib.isAlive then return false end
			if (lplr.Character:GetAttribute('StunnedUntilTime') or 0) > workspace:GetServerTimeNow() then return false end
			if lplr.Character:FindFirstChild('elk') then return false end
			if bedwars.StatusEffectUtil:isActive(lplr.Character, 'frozen') then return false end
		end

		local sword = Limit.Enabled and store.hand or store.tools.sword
		if not sword or not sword.tool then return false end

		local meta = bedwars.ItemMeta[sword.tool.Name]
		if Limit.Enabled then
			if store.hand.toolType ~= 'sword' or bedwars.DaoController.chargingMaid then return false end
		end

		if LegitAura.Enabled then
			if (tick() - bedwars.SwordController.lastSwing) > 0.2 then return false end
		end

		return sword, meta
	end

	local FireRates = {}
	local function getAmmo(check)
		for _, item in store.inventory.inventory.items do
			if check.ammoItemTypes and table.find(check.ammoItemTypes, item.itemType) then
				return item.itemType
			end
		end
		return nil
	end
	local function getProjectiles()
		local items = {}
		for _, item in store.inventory.inventory.items do
			local data = bedwars.ItemMeta[item.itemType]
			local proj = data and data.projectileSource
			local ammo = proj and getAmmo(proj)
			if ammo and (table.find(Whitelist.ListEnabled, ammo) or table.find(Whitelist.ListEnabled, item.itemType) or table.find(Whitelist.ListEnabled, data.displayName)) then
				table.insert(items, {
					item,
					ammo,
					proj.projectileType(ammo),
					proj
				})
			end
		end
		return items
	end
		
	local lastvelos = setmetatable({}, {
		__index = function(self, index)
			self[index] = {}
			return self[index]
		end
	})
	local function getMultiplier(ent, root)
		if #lastvelos[ent] > 18 then
			table.remove(lastvelos[ent], 1)
		end

		local newvelo, velo = root.AssemblyLinearVelocity, Vector3.zero
		for _, v in lastvelos[ent] do
			velo += v
		end
		local delta = #lastvelos * (1/60)
		table.insert(lastvelos[ent], newvelo)
		if delta <= 0 then
			return velo
		end
		return (newvelo - (velo / (#lastvelos - 1)))
	end
	local function getPosition(ent, root)
		local multi, pos = getMultiplier(ent, root), root.Position + (root.AssemblyLinearVelocity * (store.ping.total))
		if #lastvelos > 1 then
			pos = pos + (0.5 * multi * (store.ping.total * store.ping.total))
		end
		return pos
	end

	Killaura = vape.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				if Animation.Enabled and not (identifyexecutor and table.find({'Argon', 'Delta'}, ({identifyexecutor()})[1])) then
					local fake = {
						Controllers = {
							ViewmodelController = {
								isVisible = function()
									return not Attacking
								end,
								playAnimation = function(...)
									if not Attacking then
										bedwars.ViewmodelController:playAnimation(select(2, ...))
									end
								end
							}
						}
					}
					debug.setupvalue(oldSwing or bedwars.SwordController.playSwordEffect, 7, fake)
					debug.setupvalue(bedwars.ScytheController.playLocalAnimation, 3, fake)

					task.spawn(function()
						local started = false
						repeat
							if Attacking then
								if not armC0 then
									armC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
								end
								local first = not started
								started = true

								if AnimationMode.Value == 'Random' then
									anims.Random = {{CFrame = CFrame.Angles(math.rad(math.random(1, 360)), math.rad(math.random(1, 360)), math.rad(math.random(1, 360))), Time = 0.12}}
								end

								for _, v in anims[AnimationMode.Value] do
									AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(first and (AnimationTween.Enabled and 0.001 or 0.1) or v.Time / AnimationSpeed.Value, Enum.EasingStyle.Linear), {
										C0 = armC0 * v.CFrame
									})
									AnimTween:Play()
									AnimTween.Completed:Wait()
									first = false
									if (not Killaura.Enabled) or (not Attacking) then break end
								end
							elseif started then
								started = false
								AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
									C0 = armC0
								})
								AnimTween:Play()
							end

							if not started then
								task.wait()
							end
						until (not Killaura.Enabled) or (not Animation.Enabled)
					end)
				end

				local swingCooldown, BoxData = tick(), {}
				repeat
					local attacked, sword, meta = {}, getAttackData()
					Attacking = false
					store.KillauraTarget = nil
					if sword then
						local plrs = entitylib.AllPosition({
							Range = SwingRange.Value,
							Wallcheck = Targets.Walls.Enabled or nil,
							Part = 'RootPart',
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Limit = MaxTargets.Value,
							Sort = sortmethods[Sort.Value]
						})

						if #plrs > 0 then
							switchItem(sword.tool, 0)
							local selfpos = entitylib.character.RootPart.Position
							local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
							local tinker = meta.displayName:find(' Chainsaw')

							for _, v in plrs do
								local delta = (v.RootPart.Position - selfpos)
								local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
								if angle > (math.rad(AngleSlider.Value) / 2) then continue end

								table.insert(attacked, {
									Entity = v,
									Check = delta.Magnitude > AttackRange.Value and BoxSwingColor or BoxAttackColor
								})
								targetinfo.Targets[v] = tick() + 1

								local Swung = false
								if not Attacking then
									Attacking = true
									store.KillauraTarget = v
									if not Swing.Enabled and AnimDelay < tick() and not LegitAura.Enabled then
										AnimDelay = tick() + math.max(SwingTime.Value, 0.11)
										Swung = true
										if tinker and lplr.Character:FindFirstChild('tinker') then
                                            AnimDelay = tick() + math.max(SwingTime.Value, 0.35)
                                            bedwars.SoundManager:playSound(bedwars.SoundList.DRILL_ATTACK_1)
                                            bedwars.MountAnimationController:playAnimationInMount(lplr.Character.tinker, bedwars.AnimationType.TINKER_ATTACK, 1.85)
                                        else
                                            bedwars.SwordController:playSwordEffect(meta, false)
                                            if meta.displayName:find(' Scythe') then
                                                bedwars.ScytheController:playLocalAnimation()
                                            end
                                        end
										if vape.ThreadFix then
											setthreadidentity(8)
										end
									end
								end

								if delta.Magnitude > AttackRange.Value then
									if Swung then
										SwordSwingMiss:Fire(nil, {
											weapon = sword.tool,
											chargeRatio = 0	
										})
									end
									continue 
								end

								local actualRoot = v.Character.PrimaryPart
								local Meta = bedwars.ItemMeta[sword.itemType].sword
								local BaseCooldown = math.max((bedwars.SwordController.lastAttack + Meta.attackSpeed) - workspace:GetServerTimeNow(), 0) + (store.ping.incoming - 0.0165)
								local Cooldown = math.max(AttackSpeed.Value, BaseCooldown)
								warn(Cooldown)
								if actualRoot and (tick() - swingCooldown) >= Cooldown then
									local Hit = Random.new():NextNumber(1, 100) <= HitRegChance.Value
									local dir = CFrame.lookAt(selfpos, actualRoot.Position).LookVector
									local pos = selfpos + dir * math.max(delta.Magnitude - 14.399, 0)
									bedwars.SwordController.lastAttack = workspace:GetServerTimeNow() 
									store.attackReach = (delta.Magnitude * 100) // 1 / 100
									swingCooldown = tick()
									store.attackReachUpdate = tick() + 1

									if Hit then 
										AttackRemote:Fire(nil, {
											weapon = sword.tool,
											chargedAttack = {chargeRatio = 0},
											entityInstance = v.Character,
											validate = {
												raycast = {
													cameraPosition = {value = pos},
													cursorDirection = {value = dir}
												},
												targetPosition = {value = getPosition(v.Character, actualRoot)},
												selfPosition = {value = pos}
											}
										})
										if FastHits.Enabled and not fastHitPending and tick() > lastShot and not entitylib.Wallcheck(entitylib.character.RootPart.Position, actualRoot.Position, {gameCamera, lplr.Character, v.Character}) then
											local projectiles = getProjectiles()
											if #projectiles > 0 then
												projectileIndex += 1
												if not projectiles[projectileIndex] then
													projectileIndex = 1
												end
												
												local item, ammo, projectile, itemMeta = unpack(projectiles[projectileIndex])
												if (tick() - store.total.ping) > (FireRates[item.itemType] or 0) then
												local projmeta = bedwars.ProjectileMeta[projectile]
												if not projmeta or type(projmeta.launchVelocity) ~= 'number' then continue end
													local projSpeed, gravity = projmeta.launchVelocity, projmeta.gravitationalAcceleration or 196.2
													local oldhotbar, oldtool = store.inventory.hotbarSlot, store.hand.tool
													local hotbar = getHotbar(item.tool)
													if hotbar then
														switchItem(item.tool)
														if Legit.Enabled then
															hotbarSwitch(hotbar)
														end
													end
													
													local targetPosition = v.RootPart.Position
													local shootPosition = (CFrame.new(selfpos, targetPosition) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).Position
													local calc = prediction.SolveTrajectory(shootPosition, projSpeed, gravity, targetPosition, v.RootPart.AssemblyLinearVelocity, workspace.Gravity, v.HipHeight, v.Jumping and 42.6 or nil, nil, v.Humanoid.FloorMaterial == Enum.Material.Air or math.abs(v.RootPart.AssemblyLinearVelocity.Y) > 0.01, v.RootPart.Position, v.RootPart, nil, true)
													if calc then
														local sdir, id = CFrame.lookAt(shootPosition, calc).LookVector, httpService:GenerateGUID(true)

														bedwars.ProjectileController:createLocalProjectile(itemMeta, ammo, projectile, shootPosition, id, sdir * projSpeed, {drawDurationSeconds = 1})
														fastHitPending = true
														FireRates[item.itemType] = tick() + (itemMeta.fireDelaySec or 0.1)
														lastShot = tick() + FireRate.Value
														task.spawn(function()
															local res = projectileRemote:Fire('CallServer',
																item.tool,
																ammo,
																projectile,
																shootPosition,
																pos,
																sdir * projSpeed,
																id,
																{
																	drawDurationSeconds = 1, 
																	shotId = httpService:GenerateGUID(false)
																},
																workspace:GetServerTimeNow() - (store.ping.total / 10)
															)
															fastHitPending = false
															if res and typeof(res) == 'Instance' and res.Parent then
																res.Parent = replicatedStorage
																local shoot = itemMeta.launchSound
																shoot = shoot and shoot[math.random(1, #shoot)] or nil
																if shoot then
																	bedwars.SoundManager:playSound(shoot)
																end
															end
														end)
													end
													if oldtool then
														switchItem(oldtool)
													end
													task.spawn(function()
														if Legit.Enabled then
															hotbarSwitch(oldhotbar)
														end
													end)
												end
											end
										end
									else
										SwordSwingMiss:Fire(nil, {
											weapon = sword.tool,
											chargeRatio = 0	
										})
									end
								end
							end
						end
					end

					for i, v in Boxes do
						if BoxData[v] == nil and attacked[i] then
							v.Size = Vector3.zero
							tweenService:Create(v, TweenInfo.new(BoxAttackSpeed.Value, Enum.EasingStyle[BoxAttackTween.Value]), {
								Size = Vector3.new(4, 6, 4)
							}):Play()
						elseif BoxData[v] and not attacked[i] then
							tweenService:Create(v, TweenInfo.new(BoxAttackSpeedEnd.Value, Enum.EasingStyle[BoxAttackTween.Value]), {
								Size = Vector3.zero
							}):Play()
						end
						BoxData[v] = attacked[i] or nil
						if attacked[i] then
							v.Adornee = attacked[i].Entity.RootPart
							v.Color3 = Color3.fromHSV(attacked[i].Check.Hue, attacked[i].Check.Sat, attacked[i].Check.Value)
							v.Transparency = 1 - attacked[i].Check.Opacity
						end
					end

					for i, v in Particles do
						v.Position = attacked[i] and attacked[i].Entity.RootPart.Position or Vector3.new(9e9, 9e9, 9e9)
						v.Parent = attacked[i] and gameCamera or nil
					end

					if Face.Enabled and attacked[1] then
						local vec = attacked[1].Entity.RootPart.Position * Vector3.new(1, 0, 1)
						entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position, Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.001, vec.Z))
					end

					task.wait()
				until not Killaura.Enabled
			else
				store.KillauraTarget = nil
				for _, v in Boxes do
					v.Adornee = nil
					v.Size = Vector3.zero
				end
				for _, v in Particles do
					v.Parent = nil
				end
				debug.setupvalue(oldSwing or bedwars.SwordController.playSwordEffect, 7, bedwars.Knit)
				debug.setupvalue(bedwars.ScytheController.playLocalAnimation, 3, bedwars.Knit)
				Attacking = false
				if armC0 then
					AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
						C0 = armC0
					})
					AnimTween:Play()
				end
			end
		end,
		Tooltip = 'Attack players around you\nwithout aiming at them.'
	})
	Targets = Killaura:CreateTargets({
		Players = true,
		NPCs = true
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	SwingRange = Killaura:CreateSlider({
		Name = 'Swing range',
		Min = 1,
		Max = 28,
		Default = 28,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AttackRange = Killaura:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = 20,
		Default = 20,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AngleSlider = Killaura:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 360
	})
	HitRegChance = Killaura:CreateSlider({
		Name = 'Hit chance',
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
	--[[ChanceSlider = Killaura:CreateSlider({
		Name = 'Air hit chance',
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})]]
	SwingTime = Killaura:CreateSlider({
		Name = 'Swing time',
		Min = 0.11,
		Max = 2,
		Decimal = 100,
		Default = 0.11,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	AttackSpeed = Killaura:CreateSlider({
		Name = 'Attack speed',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Default = 0,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	--[[Sync = Killaura:CreateToggle({
		Name = 'Sync with hitreg',
		Darker = true,
		Tooltip = 'Syncs ur hitreg with the swing time'
	})]]
		
	MaxTargets = Killaura:CreateSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 5,
		Default = 5
	})
	Sort = Killaura:CreateDropdown({
		Name = 'Target Mode',
		List = methods
	})
	FastHits = Killaura:CreateToggle({
		Name = 'Fast Hits',
		Default = false,
		Function = function(callback)
			pcall(function()
				Legit.Object.Visible = callback
				FireRate.Object.Visible = callback
				Whitelist.Object.Visible = callback
			end)
		end,
		Tooltip = 'Deals more damage quicker using projectiles'
	})
	Whitelist = Killaura:CreateTextList({
		Name = 'Projectiles',
		Default = {'arrow', 'snowball'},
		Darker = true,
		Visible = false,
		Tooltip = 'Projectiles to use for fasthits'
	})
	Legit = Killaura:CreateToggle({
		Name = 'Legit Switch',
		Darker = true,
		Visible = false
	})
	FireRate = Killaura:CreateSlider({
		Name = 'Fire rate',
		Suffix = 'seconds',
		Min = 0,
		Max = 2,
		Decimal = 100,
		Darker = true,
		Visible = false,
		Default = 0.05
	})
	Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
	Attackable = Killaura:CreateToggle({Name = 'Attackable check'})
	Swing = Killaura:CreateToggle({Name = 'No Swing'})
	GUI = Killaura:CreateToggle({Name = 'GUI check'})
	Killaura:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxSwingColor.Object.Visible = callback
			BoxAttackColor.Object.Visible = callback
			BoxAttackTween.Object.Visible = callback
			BoxAttackSpeed.Object.Visible = callback
			BoxAttackSpeedEnd.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.zero
					box.CFrame = CFrame.new(0, -0.5, 0)
					box.ZIndex = 0
					box.Parent = vape.gui
					Boxes[i] = box
				end
			else
				for _, v in Boxes do
					v:Destroy()
				end
				table.clear(Boxes)
			end
		end
	})
	local animlist = {'Bounce'}
	for _, v in Enum.EasingStyle:GetEnumItems() do
		if not table.find(animlist, v.Name) then
			table.insert(animlist, v.Name)
		end
	end
	BoxAttackTween = Killaura:CreateDropdown({
		Name = 'Box Animation',
		List = animlist,
		Darker = true,
		Visible = false
	})
	BoxAttackSpeed = Killaura:CreateSlider({
		Name = 'Start Animation Speed',
		Min = 0,
		Max = 10,
		Default = 0.9,
		Decimal = 30,
		Darker = true,
		Visible = false
	})
	BoxAttackSpeedEnd = Killaura:CreateSlider({
		Name = 'End Animation Speed',
		Min = 0,
		Max = 10,
		Default = 1.4,
		Decimal = 30,
		Darker = true,
		Visible = false
	})
	BoxSwingColor = Killaura:CreateColorSlider({
		Name = 'Target Color',
		Darker = true,
		DefaultHue = 0.6,
		DefaultOpacity = 0.5,
		Visible = false
	})
	BoxAttackColor = Killaura:CreateColorSlider({
		Name = 'Attack Color',
		Darker = true,
		DefaultOpacity = 0.5,
		Visible = false
	})
	Killaura:CreateToggle({
		Name = 'Target particles',
		Function = function(callback)
			ParticleTexture.Object.Visible = callback
			ParticleColor1.Object.Visible = callback
			ParticleColor2.Object.Visible = callback
			ParticleSize.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local part = Instance.new('Part')
					part.Size = Vector3.new(2, 4, 2)
					part.Anchored = true
					part.CanCollide = false
					part.Transparency = 1
					part.CanQuery = false
					part.Parent = Killaura.Enabled and gameCamera or nil
					local particles = Instance.new('ParticleEmitter')
					particles.Brightness = 1.5
					particles.Size = NumberSequence.new(ParticleSize.Value)
					particles.Shape = Enum.ParticleEmitterShape.Sphere
					particles.Texture = ParticleTexture.Value
					particles.Transparency = NumberSequence.new(0)
					particles.Lifetime = NumberRange.new(0.4)
					particles.Speed = NumberRange.new(16)
					particles.Rate = 128
					particles.Drag = 16
					particles.ShapePartial = 1
					particles.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
					})
					particles.Parent = part
					Particles[i] = part
				end
			else
				for _, v in Particles do
					v:Destroy()
				end
				table.clear(Particles)
			end
		end
	})
	ParticleTexture = Killaura:CreateTextBox({
		Name = 'Texture',
		Default = 'rbxassetid://14736249347',
		Function = function()
			for _, v in Particles do
				v.ParticleEmitter.Texture = ParticleTexture.Value
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor1 = Killaura:CreateColorSlider({
		Name = 'Color Begin',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor2 = Killaura:CreateColorSlider({
		Name = 'Color End',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, val))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleSize = Killaura:CreateSlider({
		Name = 'Size',
		Min = 0,
		Max = 1,
		Default = 0.2,
		Decimal = 100,
		Function = function(val)
			for _, v in Particles do
				v.ParticleEmitter.Size = NumberSequence.new(val)
			end
		end,
		Darker = true,
		Visible = false
	})
	Face = Killaura:CreateToggle({Name = 'Face target'})
	Animation = Killaura:CreateToggle({
		Name = 'Custom Animation',
		Function = function(callback)
			AnimationMode.Object.Visible = callback
			AnimationTween.Object.Visible = callback
			AnimationSpeed.Object.Visible = callback
			if Killaura.Enabled then
				Killaura:Toggle()
				Killaura:Toggle()
			end
		end
	})
	local animnames = {}
	for i in anims do
		table.insert(animnames, i)
	end
	AnimationMode = Killaura:CreateDropdown({
		Name = 'Animation Mode',
		List = animnames,
		Darker = true,
		Visible = false
	})
	AnimationSpeed = Killaura:CreateSlider({
		Name = 'Animation Speed',
		Min = 0,
		Max = 2,
		Default = 1,
		Decimal = 10,
		Darker = true,
		Visible = false
	})
	AnimationTween = Killaura:CreateToggle({
		Name = 'No Tween',
		Darker = true,
		Visible = false
	})
	Limit = Killaura:CreateToggle({
		Name = 'Limit to items',
		Function = function(callback)
			if inputService.TouchEnabled and Killaura.Enabled then
				pcall(function()
					lplr.PlayerGui.MobileUI['2'].Visible = callback
				end)
			end
		end,
		Tooltip = 'Only attacks when the sword is held'
	})
	LegitAura = Killaura:CreateToggle({
		Name = 'Swing only',
		Tooltip = 'Only attacks while swinging manually'
	})
end)

run(function()
	local Value
	local CameraDir
	local start
	local JumpTick, JumpSpeed, Direction = tick(), 0
	local projectileRemote = {InvokeServer = function() end}
	task.spawn(function()
		projectileRemote = bedwars.Handler:Get('ProjectileFire').Remote.instance
	end)
	
	local function launchProjectile(item, pos, proj, speed, dir)
		if not pos then return end
	
		pos = pos - dir * 0.1
		local shootPosition = (CFrame.lookAlong(pos, Vector3.new(0, -speed, 0)) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ)))
		switchItem(item.tool, 0)
		task.wait(0.1)
		bedwars.ProjectileController:createLocalProjectile(bedwars.ProjectileMeta[proj], proj, proj, shootPosition.Position, '', shootPosition.LookVector * speed, {drawDurationSeconds = 1})
		if projectileRemote:InvokeServer(item.tool, proj, proj, shootPosition.Position, pos, shootPosition.LookVector * speed, httpService:GenerateGUID(true), {drawDurationSeconds = 1}, workspace:GetServerTimeNow() - 0.045) then
			local shoot = bedwars.ItemMeta[item.itemType].projectileSource.launchSound
			shoot = shoot and shoot[math.random(1, #shoot)] or nil
			if shoot then
				bedwars.SoundManager:playSound(shoot)
			end
		end
	end
	
	local LongJumpMethods = {
		cannon = function(_, pos, dir)
			pos = pos - Vector3.new(0, (entitylib.character.HipHeight + (entitylib.character.RootPart.Size.Y / 2)) - 3, 0)
			local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
			bedwars.placeBlock(rounded, 'cannon', false)
	
			task.delay(0, function()
				local block, blockpos = getPlacedBlock(rounded)
				if block and block.Name == 'cannon' and (entitylib.character.RootPart.Position - block.Position).Magnitude < 20 then
					local breaktype = bedwars.ItemMeta[block.Name].block.breakType
					local tool = store.tools[breaktype]
					if tool then
						switchItem(tool.tool)
					end
	
					bedwars.Handler:Get(AimCannon):Fire('SendToServer', {
						cannonBlockPos = blockpos,
						lookVector = dir
					})
	
					local broken = 0.1
					if bedwars.BlockController:calculateBlockDamage(lplr, {blockPosition = blockpos}) < block:GetAttribute('Health') then
						broken = 0.4
						bedwars.breakBlock(block, true, true)
					end
	
					task.delay(broken, function()
						for _ = 1, 3 do
							local call = bedwars.Handler:Get('LaunchSelfFromCannon'):Fire('CallServer', {cannonBlockPos = blockpos})
							if call then
								bedwars.breakBlock(block, true, true)
								JumpSpeed = 5.25 * Value.Value
								JumpTick = tick() + 2.3
								Direction = Vector3.new(dir.X, 0, dir.Z).Unit
								break
							end
							task.wait(0.1)
						end
					end)
				end
			end)
		end,
		cat = function(_, _, dir)
			LongJump:Clean(vapeEvents.CatPounce.Event:Connect(function()
				JumpSpeed = 4 * Value.Value
				JumpTick = tick() + 2.5
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit
				entitylib.character.RootPart.Velocity = Vector3.zero
			end))
	
			if not bedwars.AbilityController:canUseAbility('CAT_POUNCE') then
				repeat task.wait() until bedwars.AbilityController:canUseAbility('CAT_POUNCE') or not LongJump.Enabled
			end
	
			if bedwars.AbilityController:canUseAbility('CAT_POUNCE') and LongJump.Enabled then
				bedwars.AbilityController:useAbility('CAT_POUNCE')
			end
		end,
		fireball = function(item, pos, dir)
			launchProjectile(item, pos, 'fireball', 60, dir)
		end,
		grappling_hook = function(item, pos, dir)
			launchProjectile(item, pos, 'grappling_hook_projectile', 140, dir)
		end,
		jade_hammer = function(item, _, dir)
			if not bedwars.AbilityController:canUseAbility(item.itemType..'_jump') then
				repeat task.wait() until bedwars.AbilityController:canUseAbility(item.itemType..'_jump') or not LongJump.Enabled
			end
	
			if bedwars.AbilityController:canUseAbility(item.itemType..'_jump') and LongJump.Enabled then
				bedwars.AbilityController:useAbility(item.itemType..'_jump')
				JumpSpeed = 1.4 * Value.Value
				JumpTick = tick() + 2.5
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit
			end
		end,
		tnt = function(item, pos, dir)
			pos = pos - Vector3.new(0, (entitylib.character.HipHeight + (entitylib.character.RootPart.Size.Y / 2)) - 3, 0)
			local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
			start = Vector3.new(rounded.X, start.Y, rounded.Z) + (dir * (item.itemType == 'pirate_gunpowder_barrel' and 2.6 or 0.2))
			bedwars.placeBlock(rounded, item.itemType, false)
		end,
		wood_dao = function(item, pos, dir)
			if (lplr.Character:GetAttribute('CanDashNext') or 0) > workspace:GetServerTimeNow() or not bedwars.AbilityController:canUseAbility('dash') then
				repeat task.wait() until (lplr.Character:GetAttribute('CanDashNext') or 0) < workspace:GetServerTimeNow() and bedwars.AbilityController:canUseAbility('dash') or not LongJump.Enabled
			end
	
			if LongJump.Enabled then
				bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
				switchItem(item.tool, 0.1)
				replicatedStorage['events-@easy-games/game-core:shared/game-core-networking@getEvents.Events'].useAbility:FireServer('dash', {
					direction = dir,
					origin = pos,
					weapon = item.itemType
				})
				JumpSpeed = 4.5 * Value.Value
				JumpTick = tick() + 2.4
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit
			end
		end
	}
	for _, v in {'stone_dao', 'iron_dao', 'diamond_dao', 'emerald_dao'} do
		LongJumpMethods[v] = LongJumpMethods.wood_dao
	end
	LongJumpMethods.void_axe = LongJumpMethods.jade_hammer
	LongJumpMethods.siege_tnt = LongJumpMethods.tnt
	LongJumpMethods.pirate_gunpowder_barrel = LongJumpMethods.tnt
	
	LongJump = vape.Categories.Blatant:CreateModule({
		Name = 'LongJump',
		Function = function(callback)
			frictionTable.LongJump = callback or nil
			updateVelocity()
			if callback then
				LongJump:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if damageTable.entityInstance == lplr.Character and damageTable.fromEntity == lplr.Character and (not damageTable.knockbackMultiplier or not damageTable.knockbackMultiplier.disabled) then
						local knockbackBoost = bedwars.KnockbackUtil.calculateKnockbackVelocity(Vector3.one, 1, {
							vertical = 0,
							horizontal = (damageTable.knockbackMultiplier and damageTable.knockbackMultiplier.horizontal or 1)
						}).Magnitude * 1.1
	
						if knockbackBoost >= JumpSpeed then
							local pos = damageTable.fromPosition and Vector3.new(damageTable.fromPosition.X, damageTable.fromPosition.Y, damageTable.fromPosition.Z) or damageTable.fromEntity and damageTable.fromEntity.PrimaryPart.Position
							if not pos then return end
							local vec = (entitylib.character.RootPart.Position - pos)
							JumpSpeed = knockbackBoost
							JumpTick = tick() + 2.5
							Direction = Vector3.new(vec.X, 0, vec.Z).Unit
						end
					end
				end))
				LongJump:Clean(vapeEvents.GrapplingHookFunctions.Event:Connect(function(dataTable)
					if dataTable.hookFunction == 'PLAYER_IN_TRANSIT' then
						local vec = entitylib.character.RootPart.CFrame.LookVector
						JumpSpeed = 2.5 * Value.Value
						JumpTick = tick() + 2.5
						Direction = Vector3.new(vec.X, 0, vec.Z).Unit
					end
				end))
	
				start = entitylib.isAlive and entitylib.character.RootPart.Position or nil
				LongJump:Clean(runService.PreSimulation:Connect(function(dt)
					local root = entitylib.isAlive and entitylib.character.RootPart or nil
	
					if root and isnetworkowner(root) then
						if JumpTick > tick() then
							root.AssemblyLinearVelocity = Direction * (getSpeed() + ((JumpTick - tick()) > 1.1 and JumpSpeed or 0)) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
							if entitylib.character.Humanoid.FloorMaterial == Enum.Material.Air and not start then
								root.AssemblyLinearVelocity += Vector3.new(0, dt * (workspace.Gravity - 23), 0)
							else
								root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 15, root.AssemblyLinearVelocity.Z)
							end
							start = nil
						else
							if start then
								root.CFrame = CFrame.lookAlong(start, root.CFrame.LookVector)
							end
							root.AssemblyLinearVelocity = Vector3.zero
							JumpSpeed = 0
						end
					else
						start = nil
					end
				end))
	
				if store.hand and LongJumpMethods[store.hand.tool.Name] then
					task.spawn(LongJumpMethods[store.hand.tool.Name], getItem(store.hand.tool.Name), start, (CameraDir.Enabled and gameCamera or entitylib.character.RootPart).CFrame.LookVector)
					return
				end
	
				for i, v in LongJumpMethods do
					local item = getItem(i)
					if item or store.equippedKit == i then
						task.spawn(v, item, start, (CameraDir.Enabled and gameCamera or entitylib.character.RootPart).CFrame.LookVector)
						break
					end
				end
			else
				JumpTick = tick()
				Direction = nil
				JumpSpeed = 0
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end,
		Tooltip = 'Lets you jump farther'
	})
	Value = LongJump:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 37,
		Default = 37,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	CameraDir = LongJump:CreateToggle({
		Name = 'Camera Direction'
	})
end)

run(function()
	local NoFall
	
	NoFall = vape.Categories.Blatant:CreateModule({
		Name = 'NoFall',
		Function = function(callback)
			if callback then
				NoFall:Clean(runService.PostSimulation:Connect(function(dt)
					if entitylib.isAlive and store.matchState == 1 then
						local root = entitylib.character.RootPart
						local velo = root.Velocity
	
						if root.Velocity.Y < -30 then
							root.Velocity = Vector3.new(0, 2.5 - dt, 0)
							entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
							runService.PreRender:Wait()
							root.Velocity = velo
						end
					end
				end))
	
				NoFall:Clean(entitylib.Events.LocalAdded:Connect(function(ent)
					local animator = ent.Humanoid:WaitForChild('Animator', 5)
					if animator and NoFall.Enabled then
						task.wait(.5)
						NoFall:Toggle()
						NoFall:Toggle()
					end
				end))
			end
		end,
		Tooltip = 'Prevents taking fall damage.'
	})
end)

run(function()
	local old
	
	vape.Categories.Blatant:CreateModule({
		Name = 'NoSlow',
		Function = function(callback)
			local modifier = bedwars.SprintController:getMovementStatusModifier()
			if callback then
				old = modifier.addModifier
				modifier.addModifier = function(self, tab)
					if tab.moveSpeedMultiplier then
						tab.moveSpeedMultiplier = math.max(tab.moveSpeedMultiplier, 1)
					end
					return old(self, tab)
				end
	
				for i in modifier.modifiers do
					if (i.moveSpeedMultiplier or 1) < 1 then
						modifier:removeModifier(i)
					end
				end
			else
				modifier.addModifier = old
				old = nil
			end
		end,
		Tooltip = 'Prevents slowing down when using items.'
	})
end)

run(function()
	local OwlAura
	local Targets
	local Mode
	local Range
	
	OwlAura = vape.Categories.Blatant:CreateModule({
	    Name = 'OwlAura',
	    Function = function(callback)
	        if callback then
	            local owls = collection('Owl', OwlAura, function(self, obj)
	                task.delay(1, function()
	                    if obj and obj.Parent and obj:GetAttribute('Owner') == lplr.UserId then
	                        table.insert(self, obj)
	                    end
	                end)
	            end)
	            repeat
	                if store.equippedKit ~= 'owl' then
	                    task.wait(1)
	                    continue
	                end
	
	                if entitylib.isAlive then
	                    local owl = owls[1]
	                    if owl then
	                        local origin = owl.Part.Position
	                        local plr = entitylib.EntityPosition({
	                            Origin = origin,
	                            Range = Range.Value,
	                            Part = 'RootPart',
	                            Players = Targets.Players.Enabled,
	                            NPCs = Targets.NPCs.Enabled,
	                            Wallcheck = Targets.Walls.Enabled,
	                            Sort = sortmethods[Mode.Value]
	                        })
	
	                        if plr then
	                            local meta = bedwars.ProjectileMeta.owl_projectile
	                            local targetVelocity = plr.RootPart.AssemblyLinearVelocity
	                            local targetAirborne = plr.Humanoid.FloorMaterial == Enum.Material.Air or math.abs(targetVelocity.Y) > 0.01
	                            local calc, _, travelTime = prediction.SolveTrajectory(origin, meta.launchVelocity, meta.gravitationalAcceleration, plr.RootPart.Position, targetVelocity, workspace.Gravity, plr.HipHeight, plr.Jumping and 42.6 or nil, store.airRay, targetAirborne, plr.RootPart.Position, plr.RootPart, nil, true)
	                            if calc and travelTime and travelTime <= (meta.lifetimeSec or 3) then
	                                local dir = CFrame.lookAt(origin, calc).LookVector * meta.launchVelocity
	                                bedwars.Handler:Get('OwlAiming'):Fire('SendToServer', {
	                                    owl = owl.Part,
	                                    starting = true
	                                })
	                                bedwars.Handler:Get('OwlFireProjectile'):Fire('SendToServer', {
	                                    ProjectileRefId = httpService:GenerateGUID(true),
	                                    direction = dir,
	                                    fromPosition = origin,
	                                    initialVelocity = dir
	                                })
	                                bedwars.Handler:Get('TridentUnanchor'):Fire('CallServer')
	                            end
	                        end
	                    end
	                end
	                task.wait(0.1)
	            until not OwlAura.Enabled
	        else
	            bedwars.Handler:Get('OwlAiming'):Fire('SendToServer', {starting = false})
	        end
	    end,
	    Tooltip = 'Automatically shoots projectiles with whisper kit'
	})
	
	Targets = OwlAura:CreateTargets({
	    Players = true,
	    Wallcheck = true
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
	    if not table.find(methods, i) then
	        table.insert(methods, i)
	    end
	end
	Mode = OwlAura:CreateDropdown({
	    Name = 'Target mode',
	    List = methods,
	    Default = 'Distance'
	})
	Range = OwlAura:CreateSlider({
	    Name = 'Range',
	    Min = 1,
	    Max = 50,
	    Default = 50,
	    Suffix = function(val)
	        return val <= 0 and 'stud' or 'studs'
	    end
	})
end)

run(function()
	local TargetPart
	local Targets
	local FOV
	local AutoCharge
	local Aim = {}
	local OtherProjectiles
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Include
	rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild('Map')}
	local old
	
	local ProjectileAimbot = vape.Categories.Blatant:CreateModule({
		Name = 'ProjectileAimbot',
		Function = function(callback)
			if callback then
				old = bedwars.ProjectileController.calculateImportantLaunchValues
				bedwars.ProjectileController.calculateImportantLaunchValues = function(...)
					local self, projmeta, worldmeta, origin, shootpos = ...
					local plr = entitylib.EntityMouse({
						Part = 'RootPart',
						Range = FOV.Value,
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
						Wallcheck = Targets.Walls.Enabled,
						Origin = entitylib.isAlive and (shootpos or entitylib.character.RootPart.Position) or Vector3.zero
					})
					if plr then
						local pos = shootpos or self:getLaunchPosition(origin)
						if not pos then
							return old(...)
						end
	
						if (not OtherProjectiles.Enabled) and not projmeta.projectile:find('arrow') then
							return old(...)
						end
	
						if table.find(Blacklist.ListEnabled or {}, ((projmeta.projectile == 'glue_trap' or projmeta.projectile == 'glue_projectile') and 'gloop' or projmeta.projectile)) then
							return old(...)
						end
	
						local meta = projmeta:getProjectileMeta()
						local lifetime = (worldmeta and meta.predictionLifetimeSec or meta.lifetimeSec or 3)
						local gravity = (meta.gravitationalAcceleration or 196.2) * projmeta.gravityMultiplier
						local projSpeed = (meta.launchVelocity or 100)
						local offsetpos = pos + (projmeta.projectile == 'owl_projectile' and Vector3.zero or projmeta.fromPositionOffset)
						local balloons = plr.Character:GetAttribute('InflatedBalloons')
						local playerGravity = workspace.Gravity
	
						if balloons and balloons > 0 then
							playerGravity = (workspace.Gravity * (1 - ((balloons >= 4 and 1.2 or balloons >= 3 and 1 or 0.975))))
						end
	
						if plr.Character.PrimaryPart:FindFirstChild('rbxassetid://8200754399') then
							playerGravity = 6
						end
	
						if plr.Player and plr.Player:GetAttribute('IsOwlTarget') then
							for _, owl in collectionService:GetTagged('Owl') do
								if owl:GetAttribute('Target') == plr.Player.UserId and owl:GetAttribute('Status') == 2 then
									playerGravity = 0
								end
							end
						end
	
						local newlook = CFrame.new(offsetpos, plr[TargetPart.Value].Position) * CFrame.new(projmeta.projectile == 'owl_projectile' and Vector3.zero or Vector3.new(bedwars.BowConstantsTable.RelX, bedwars.BowConstantsTable.RelY, bedwars.BowConstantsTable.RelZ))
						local calc = prediction.SolveTrajectory(newlook.p, projSpeed, gravity, plr[TargetPart.Value].Position, projmeta.projectile == 'telepearl' and Vector3.zero or plr[TargetPart.Value].Velocity, playerGravity, plr.HipHeight, plr.Jumping and 42.6 or nil, rayCheck, plr.Humanoid.FloorMaterial == Enum.Material.Air or math.abs(plr.RootPart.Velocity.Y) > 0.01, plr.RootPart.Position, plr.RootPart, nil, true)
						if calc then
							targetinfo.Targets[plr] = tick() + 1
							return {
								initialVelocity = (CFrame.new(newlook.Position, calc).LookVector * projSpeed) * ((AutoCharge.Enabled or not Aim.Enabled) and 1 or projmeta.velocityMultiplier),
								positionFrom = offsetpos,
								deltaT = lifetime,
								gravitationalAcceleration = gravity,
								drawDurationSeconds = AutoCharge.Enabled and 5 or projmeta.drawDurationSeconds
							}
						end
					end
	
					return old(...)
				end
			else
				bedwars.ProjectileController.calculateImportantLaunchValues = old
			end
		end,
		Tooltip = 'Silently adjusts your aim towards the enemy'
	})
	Targets = ProjectileAimbot:CreateTargets({
		Players = true,
		Walls = true
	})
	TargetPart = ProjectileAimbot:CreateDropdown({
		Name = 'Part',
		List = {'RootPart', 'Head'}
	})
	FOV = ProjectileAimbot:CreateSlider({
		Name = 'FOV',
		Min = 1,
		Max = 1000,
		Default = 1000
	})
	AutoCharge = ProjectileAimbot:CreateToggle({
		Name = 'Auto Charge',
		Function = function(callback)
			if Aim.Object then
				Aim.Object.Visible = callback
			end
		end,
		Default = true,
		Tooltip = 'Fully charges your bow, Allowing your projectile to deal more damage'
	})
	Aim = ProjectileAimbot:CreateToggle({
		Name = 'Aim change',
		Default = true,
		Darker = true,
		Tooltip = 'Changes your trajectory to match charge percentage.'
	})
	OtherProjectiles = ProjectileAimbot:CreateToggle({
		Name = 'Other Projectiles',
		Default = true
	})
	Blacklist = ProjectileAimbot:CreateTextList({
		Name = 'Blacklist',
		Default = {'telepearl'}
	})
end)

run(function()
	local ProjectileAura
	local Targets
	local Range
	local List
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	local projectileRemote = {InvokeServer = function() end}
	local FireDelays = {}
	task.spawn(function()
		projectileRemote = bedwars.Handler:Get('ProjectileFire').Remote.instance
	end)
	
	local function getAmmo(check)
		for _, item in store.inventory.inventory.items do
			if check.ammoItemTypes and table.find(check.ammoItemTypes, item.itemType) then
				return item.itemType
			end
		end
	end
	
	local function getProjectiles()
		local items = {}
		for _, item in store.inventory.inventory.items do
			local proj = bedwars.ItemMeta[item.itemType].projectileSource
			local ammo = proj and getAmmo(proj)
			if ammo and table.find(List.ListEnabled, ammo) then
				table.insert(items, {
					item,
					ammo,
					proj.projectileType(ammo),
					proj
				})
			end
		end
		return items
	end
	
	ProjectileAura = vape.Categories.Blatant:CreateModule({
		Name = 'ProjectileAura',
		Function = function(callback)
			if callback then
				repeat
					if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 0.5 then
						local ent = entitylib.EntityPosition({
							Part = 'RootPart',
							Range = Range.Value,
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Wallcheck = Targets.Walls.Enabled
						})
	
						if ent then
							local pos = entitylib.character.RootPart.Position
							for _, data in getProjectiles() do
								local item, ammo, projectile, itemMeta = unpack(data)
								if (FireDelays[item.itemType] or 0) < tick() then
									rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
									local meta = bedwars.ProjectileMeta[projectile]
									local projSpeed, gravity = meta.launchVelocity, meta.gravitationalAcceleration or 196.2
									local switched = switchItem(item.tool)
									local calc = prediction.SolveTrajectory(pos, projSpeed, gravity, ent.RootPart.Position, ent.RootPart.Velocity, workspace.Gravity, ent.HipHeight, ent.Jumping and 42.6 or nil, rayCheck, ent.Humanoid.FloorMaterial == Enum.Material.Air or math.abs(ent.RootPart.Velocity.Y) > 0.01, ent.RootPart.Position, ent.RootPart, nil, true)
									if calc then
										targetinfo.Targets[ent] = tick() + 1
	
										task.spawn(function()
											local dir, id = CFrame.lookAt(pos, calc).LookVector, httpService:GenerateGUID(true)
											local shootPosition = (CFrame.new(pos, calc) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).Position
											bedwars.ProjectileController:createLocalProjectile(meta, ammo, projectile, shootPosition, id, dir * projSpeed, {drawDurationSeconds = 1})
											local res = projectileRemote:InvokeServer(item.tool, ammo, projectile, shootPosition, pos, dir * projSpeed, id, {drawDurationSeconds = 1, shotId = httpService:GenerateGUID(false)}, workspace:GetServerTimeNow() - 0.045)
											if not res then
												FireDelays[item.itemType] = tick()
											else
												pcall(function() res.Parent = replicatedStorage end)
												local shoot = itemMeta.launchSound
												shoot = shoot and shoot[math.random(1, #shoot)] or nil
												if shoot then
													bedwars.SoundManager:playSound(shoot)
												end
											end
										end)
	
										FireDelays[item.itemType] = tick() + itemMeta.fireDelaySec
										if switched then
											task.wait(0.05)
										end
									end
								end
							end
						end
					end
					task.wait(0.1)
				until not ProjectileAura.Enabled
			end
		end,
		Tooltip = 'Shoots people around you'
	})
	Targets = ProjectileAura:CreateTargets({
		Players = true,
		Walls = true
	})
	List = ProjectileAura:CreateTextList({
		Name = 'Projectiles',
		Default = {'arrow', 'snowball'}
	})
	Range = ProjectileAura:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 50,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local Speed
	local Value
	local WallCheck
	local AutoJump
	local AlwaysJump
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	
	Speed = vape.Categories.Blatant:CreateModule({
		Name = 'Speed',
		Function = function(callback)
			frictionTable.Speed = callback or nil
			updateVelocity()
			pcall(function()
				debug.setconstant(bedwars.WindWalkerController.updateSpeed, 7, callback and 'constantSpeedMultiplier' or 'moveSpeedMultiplier')
			end)
	
			if callback then
				Speed:Clean(runService.PreSimulation:Connect(function(dt)
					bedwars.StatefulEntityKnockbackController.lastImpulseTime = callback and math.huge or time()
					if entitylib.isAlive and not Fly.Enabled and not InfiniteFly.Enabled and not LongJump.Enabled and isnetworkowner(entitylib.character.RootPart) then
						local state = entitylib.character.Humanoid:GetState()
						if state == Enum.HumanoidStateType.Climbing then return end
	
						local root, velo = entitylib.character.RootPart, getSpeed()
						local moveDirection = AntiFallDirection or entitylib.character.Humanoid.MoveDirection
						local destination = (moveDirection * math.max(Value.Value - velo, 0) * dt)
	
						if WallCheck.Enabled then
							rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
							rayCheck.CollisionGroup = root.CollisionGroup
							local ray = workspace:Raycast(root.Position, destination, rayCheck)
							if ray then
								destination = ((ray.Position + ray.Normal) - root.Position)
							end
						end
	
						root.CFrame += destination
						root.AssemblyLinearVelocity = (moveDirection * velo) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
						if AutoJump.Enabled and (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed) and moveDirection ~= Vector3.zero and (Attacking or AlwaysJump.Enabled) then
							entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
						end
					end
				end))
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end,
		Tooltip = 'Increases your movement with various methods.'
	})
	Value = Speed:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 23,
		Default = 23,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	WallCheck = Speed:CreateToggle({
		Name = 'Wall Check',
		Default = true
	})
	AutoJump = Speed:CreateToggle({
		Name = 'AutoJump',
		Function = function(callback)
			AlwaysJump.Object.Visible = callback
		end
	})
	AlwaysJump = Speed:CreateToggle({
		Name = 'Always Jump',
		Visible = false,
		Darker = true
	})
end)

run(function()
	local BedESP
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local function Added(bed)
		if not BedESP.Enabled then return end
		local BedFolder = Instance.new('Folder')
		BedFolder.Parent = Folder
		Reference[bed] = BedFolder
		local parts = bed:GetChildren()
		table.sort(parts, function(a, b)
			return a.Name > b.Name
		end)
	
		for _, part in parts do
			if part:IsA('BasePart') and part.Name ~= 'Blanket' then
				local handle = Instance.new('BoxHandleAdornment')
				handle.Size = part.Size + Vector3.new(.01, .01, .01)
				handle.AlwaysOnTop = true
				handle.ZIndex = 2
				handle.Visible = true
				handle.Adornee = part
				handle.Color3 = part.Color
				if part.Name == 'Legs' then
					handle.Color3 = Color3.fromRGB(167, 112, 64)
					handle.Size = part.Size + Vector3.new(.01, -1, .01)
					handle.CFrame = CFrame.new(0, -0.4, 0)
					handle.ZIndex = 0
				end
				handle.Parent = BedFolder
			end
		end
	
		table.clear(parts)
	end
	
	BedESP = vape.Categories.Render:CreateModule({
		Name = 'BedESP',
		Function = function(callback)
			if callback then
				BedESP:Clean(collectionService:GetInstanceAddedSignal('bed'):Connect(function(bed)
					task.delay(0.2, Added, bed)
				end))
				BedESP:Clean(collectionService:GetInstanceRemovedSignal('bed'):Connect(function(bed)
					if Reference[bed] then
						Reference[bed]:Destroy()
						Reference[bed] = nil
					end
				end))
				for _, bed in collectionService:GetTagged('bed') do
					Added(bed)
				end
			else
				Folder:ClearAllChildren()
				table.clear(Reference)
			end
		end,
		Tooltip = 'Render Beds through walls'
	})
end)

run(function()
	local HiveESP
	local Color
	local Transparency
	local Scale
	
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local Reference, Strings = {}, {}
	local function Added(ent)
		local Name = playersService:GetNameFromUserIdAsync(ent:GetAttribute('PlacedByUserId')) or 'Unknown'
	
		Strings[ent] = `{Name}'s beehive | %s Bee%s`
		local nametag = Instance.new('TextLabel')
		nametag.TextSize = 14 * Scale.Value
		nametag.Font = Enum.Font.Arial
		local format = string.format(Strings[ent], tostring(ent:GetAttribute('Level') or 0), (ent:GetAttribute('Level') or 0) >= 2 and 's' or '')
		local size = getfontsize(format, nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
		nametag.Name = Name
		nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
		nametag.AnchorPoint = Vector2.new(0.5, 1)
		nametag.BackgroundColor3 = Color3.new()
		nametag.BackgroundTransparency = 0.5
		nametag.BorderSizePixel = 0
		nametag.Visible = false
		nametag.Text = format
		nametag.TextColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		nametag.RichText = true
		nametag.Parent = Folder
		Reference[ent] = nametag
	end
	local function Updated(ent)
		if Reference[ent] then
			Reference[ent].TextSize = 14 * Scale.Value
			Reference[ent].TextColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			Reference[ent].BackgroundTransparency = Transparency.Value
		end
	end
	local function Removing(ent)
		if Reference[ent] then
			Reference[ent]:Destroy()
			Reference[ent] = nil
		end
	end
	
	HiveESP = vape.Categories.Render:CreateModule({
		Name = 'BeehiveESP',
		Function = function(call)
			if call then
				for _, v in collectionService:GetTagged('beehive') do
					Added(v)
				end
				HiveESP:Clean(collectionService:GetInstanceAddedSignal('beehive'):Connect(Added))
				HiveESP:Clean(collectionService:GetInstanceRemovedSignal('beehive'):Connect(Removing))
				HiveESP:Clean(runService.PreRender:Connect(function()
					for ent, nametag in Reference do
						local headPos, headVis = gameCamera:WorldToViewportPoint(ent.Position + Vector3.new(0, 1, 0))
						nametag.Visible = headVis
						if not headVis then
							continue
						end
	
	                    nametag.Text = string.format(Strings[ent], tostring(ent:GetAttribute('Level') or 0), (ent:GetAttribute('Level') or 0) >= 2 and 's' or '')
	                    local size = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
	                    nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
						nametag.Position = UDim2.fromOffset(headPos.X, headPos.Y)
					end
				end))
			else
				for i in Reference do
					Removing(i)
				end
			end
		end,
		Tooltip = 'Renders hives locations and info'
	})
	
	Color = HiveESP:CreateColorSlider({
		Name = 'Text Color',
		Function = function(hue, sat, val)
			if HiveESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end
	})
	Transparency = HiveESP:CreateSlider({
		Name = 'Transparency',
		Function = function()
			if HiveESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end,
		Default = 0.5,
		Min = 0,
		Max = 1,
		Decimal = 100
	})
	Scale = HiveESP:CreateSlider({
		Name = 'Scale',
	    Function = function()
			if HiveESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end,
		Min = 0.1,
		Max = 1.5,
		Decimal = 10,
	    Default = 1
	})
end)

run(function()
	local GeneratorESP
	local Transparency
	local Scale
	local Whitelist
	local Whitelisted = {}
	
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local Reference, Strings, Cooldown = {}, {}, {}
	
	local function getNumber(text)
		if not text or text == '' then
			return 0
		end
		local seconds = text:match('%[(%d+)%]')
		if seconds then
			return tonumber(seconds) or 0
		end
		local justNumber = text:match('(%d+)')
		if justNumber then
			return tonumber(justNumber) or 0
		end
		return 0
	end
	
	local function Added(ent)
		local App = ent.RoactTree.TeamOreGeneratorApp
		local Name = (App:FindFirstChild('GlobalOreGenerator') or App:FindFirstChild('TeamGenMain'))
		if Name then
			Name = Name:FindFirstChild('Title')
		end
	
		local TierType = ''
		if Name then
			Name = Name.Text
			TierType = 'iron'
		else
			local Ore = ent:GetAttribute('Id')
			Ore = Ore:sub(0, #Ore - 2)
			TierType = (Ore:sub(0, 1):upper() .. Ore:sub(2, #Ore)):lower()
			Name = Ore:sub(0, 1):upper() .. Ore:sub(2, #Ore) .. ' Generator'
		end
	
		if Whitelist.Enabled and not table.find(Whitelisted.ListEnabled, TierType) then
			return
		end
	
		Strings[ent] = `{Name} %s%s`
		local nametag = Instance.new('TextLabel')
		nametag.TextSize = 14 * Scale.Value
		nametag.Font = Enum.Font.Arial
		local format = string.format(Strings[ent], `| T{ent:GetAttribute('GeneratorLevel')}`, '')
		local size = getfontsize(format, nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
		nametag.Name = Name
		nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
		nametag.AnchorPoint = Vector2.new(0.5, 1)
		nametag.BackgroundColor3 = Color3.new()
		nametag.BackgroundTransparency = 0.5
		nametag.BorderSizePixel = 0
		nametag.Visible = false
		nametag.Text = format
		nametag.TextColor3 = Color3.new(1, 1, 1)
		nametag.RichText = true
		nametag.Parent = Folder
		Reference[ent] = nametag
	end
	local function Updated(ent)
		if Reference[ent] then
			Reference[ent].TextSize = 14 * Scale.Value
			Reference[ent].BackgroundTransparency = Transparency.Value
		end
	end
	local function Removing(ent)
		if Reference[ent] then
			Reference[ent]:Destroy()
			Reference[ent] = nil
		end
	end
	
	GeneratorESP = vape.Categories.Render:CreateModule({
		Name = 'GeneratorESP',
		Function = function(callback)
			if callback then
				for _, v in collectionService:GetTagged('Generator') do
					Added(v)
				end
				GeneratorESP:Clean(collectionService:GetInstanceAddedSignal('Generator'):Connect(Added))
				GeneratorESP:Clean(collectionService:GetInstanceRemovedSignal('Generator'):Connect(Removing))
				GeneratorESP:Clean(runService.PreRender:Connect(function()
					for ent, nametag in Reference do
						local headPos, headVis = gameCamera:WorldToViewportPoint(ent.Position + Vector3.new(0, 1, 0))
						nametag.Visible = headVis
						if not headVis then
							continue
						end
						
						nametag.Text = string.format(Strings[ent], `| T{ent:GetAttribute('GeneratorLevel')}`, Cooldown[ent] and ` | {getNumber(Cooldown[ent].Text)}s` or '')
						local size = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
						nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
						nametag.Position = UDim2.fromOffset(headPos.X, headPos.Y)
					end
				end))
			else
				for i in Reference do
					Removing(i)
				end
			end
		end,
		Tooltip = 'Renders generator locations and info'
	})
	
	Transparency = GeneratorESP:CreateSlider({
		Name = 'Transparency',
		Function = function()
			if GeneratorESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end,
		Default = 0.5,
		Min = 0,
		Max = 1,
		Decimal = 100
	})
	Scale = GeneratorESP:CreateSlider({
		Name = 'Scale',
		Default = 1,
		Min = 0.1,
		Max = 1.5,
		Decimal = 10,
		Function = function()
			if GeneratorESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end
	})
	Whitelist = GeneratorESP:CreateToggle({
		Name = 'Use whitelist',
		Default = true,
		Function = function(call)
			if Whitelisted.Object then
				Whitelisted.Object.Visible = call
			end
		end
	})
	Whitelisted = GeneratorESP:CreateTextList({
		Name = 'Generators',
		Darker = true,
		Default = {'diamond', 'iron'}
	})
end)

run(function()
	local Health
	
	Health = vape.Categories.Render:CreateModule({
		Name = 'Health',
		Function = function(callback)
			if callback then
				local label = Instance.new('TextLabel')
				label.Size = UDim2.fromOffset(100, 20)
				label.Position = UDim2.new(0.5, 6, 0.5, 30)
				label.BackgroundTransparency = 1
				label.AnchorPoint = Vector2.new(0.5, 0)
				label.Text = entitylib.isAlive and math.round(lplr.Character:GetAttribute('Health'))..' ❤️' or ''
				label.TextColor3 = entitylib.isAlive and Color3.fromHSV((lplr.Character:GetAttribute('Health') / lplr.Character:GetAttribute('MaxHealth')) / 2.8, 0.86, 1) or Color3.new()
				label.TextSize = 18
				label.Font = Enum.Font.Arial
				label.Parent = vape.gui
				Health:Clean(label)
				Health:Clean(vapeEvents.AttributeChanged.Event:Connect(function()
					label.Text = entitylib.isAlive and math.round(lplr.Character:GetAttribute('Health'))..' ❤️' or ''
					label.TextColor3 = entitylib.isAlive and Color3.fromHSV((lplr.Character:GetAttribute('Health') / lplr.Character:GetAttribute('MaxHealth')) / 2.8, 0.86, 1) or Color3.new()
				end))
			end
		end,
		Tooltip = 'Displays your health in the center of your screen.'
	})
end)

run(function()
	local ItemESP
	local Distance
	local Transparency
	local Scale
	local WhitelistOnly
	local Whitelist = {}
	
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local Reference, Strings, Sizes = {}, {}, {}
	local function Added(ent)
		local Name = bedwars.ItemMeta[ent.Name] and bedwars.ItemMeta[ent.Name].displayName or ent.Name
		if WhitelistOnly.Enabled and not table.find(Whitelist.ListEnabled, Name:lower()) then
			return
		end
	
		Strings[ent] = Name .. '%s'
		if Distance.Enabled then
			Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '.. Strings[ent]
		end
	
		local nametag = Instance.new('TextLabel')
		nametag.TextSize = 14 * Scale.Value
		nametag.Font = Enum.Font.Arial
		local size = getfontsize(removeTags(ent.Name), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
		nametag.Name = ent.Name
		nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
		nametag.AnchorPoint = Vector2.new(0.5, 1)
		nametag.BackgroundColor3 = Color3.new()
		nametag.BackgroundTransparency = 0.5
		nametag.BorderSizePixel = 0
		nametag.Visible = false
		nametag.Text = string.format(Strings[ent], '', ent:GetAttribute('Amount') >= 2 and ' x' .. tostring(ent:GetAttribute('Amount')) or '')
		nametag.TextColor3 = Color3.new(1, 1, 1)
		nametag.RichText = true
		nametag.Parent = Folder
		Reference[ent] = nametag
	end
	local function Updated(ent)
		if Reference[ent] then
			Reference[ent].TextSize = 14 * Scale.Value
			Reference[ent].BackgroundTransparency = Transparency.Value
		end
	end
	local function Removing(ent)
		if Reference[ent] then
			Reference[ent]:Destroy()
			Reference[ent] = nil
		end
	end
	
	ItemESP = vape.Categories.Render:CreateModule({
		Name = 'ItemESP',
		Function = function(call)
			if call then
				ItemESP:Clean(collectionService:GetInstanceAddedSignal('ItemDrop'):Connect(Added))
				ItemESP:Clean(collectionService:GetInstanceRemovedSignal('ItemDrop'):Connect(Removing))
				ItemESP:Clean(runService.PreRender:Connect(function()
					for ent, nametag in Reference do
						local headPos, headVis = gameCamera:WorldToViewportPoint(ent.Position + Vector3.new(0, 1, 0))
						nametag.Visible = headVis
						if not headVis then
							continue
						end
	
						if ent.Position.Y > -200 then
							if Distance.Enabled then
								local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - ent.Position).Magnitude) or 0
								if Sizes[ent] ~= mag then
									nametag.Text = string.format(Strings[ent], mag, ent:GetAttribute('Amount') >= 2 and ' x' .. tostring(ent:GetAttribute('Amount')) or '')
									local size = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
									nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
									Sizes[ent] = mag
								end
							else
								nametag.Text = string.format(Strings[ent], '')
								local size = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
								nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
							end
							nametag.Position = UDim2.fromOffset(headPos.X, headPos.Y)
						else
							nametag.Visible = false
						end
					end
				end))
	
				for _, v in collectionService:GetTagged('ItemDrop') do
					Added(v)
				end
			else
				for i in Reference do
					Removing(i)
				end
			end
		end,
		Tooltip = 'Renders tags dropped items'
	})
	Distance = ItemESP:CreateToggle({
		Name = 'Distance',
		Function = function(callback)
			if ItemESP.Enabled then
				for ent in Reference do
					local Name = bedwars.ItemMeta[ent.Name] and bedwars.ItemMeta[ent.Name].displayName or ent.Name
					Strings[ent] = callback and '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '.. Strings[ent] or Name.. '%s'
				end
			end
		end,
	    Tooltip = 'Shows the distance of the item'
	})
	Transparency = ItemESP:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Decimal = 100,
	    Function = function()
			if ItemESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end,
	    Default = 0.5
	})
	Scale = ItemESP:CreateSlider({
		Name = 'Scale',
		Default = 1,
		Min = 0.1,
		Max = 1.5,
		Decimal = 10,
		Function = function()
			if ItemESP.Enabled then
				for ent in Reference do
					Updated(ent)
				end
			end
		end
	})
	WhitelistOnly = ItemESP:CreateToggle({
		Name = 'Whitelist Only',
		Function = function(callback)
			if Whitelist.Object then
				Whitelist.Object.Visible = callback
			end
	        if ItemESP.Enabled then
	            ItemESP:Toggle()
	            ItemESP:Toggle()
	        end
		end,
	    Tooltip = 'Only renders whitelisted items'
	})
	Whitelist = ItemESP:CreateTextList({
		Name = 'Allowed items',
		Function = function()
			if ItemESP.Enabled then
				ItemESP:Toggle()
				ItemESP:Toggle()
			end
		end,
		Darker = true,
	    Visible = false
	})
end)

run(function()
	local ItemPlates
	local Whitelist
	local Background
	local Color = {}
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local function scanSide(self, start, tab)
		for _, side in sides do
			for i = 1, 15 do
				local block = getPlacedBlock(start + (side * i))
				if not block or block == self then break end
				if not block:GetAttribute('NoBreak') and not table.find(tab, block.Name) then
					table.insert(tab, block.Name)
				end
			end
		end
	end
	
	local function refreshAdornee(v)
		for _, obj in v.Frame:GetChildren() do
			if obj:IsA('ImageLabel') and obj.Name ~= 'Blur' then
				obj:Destroy()
			end
		end
	
		local start = v.Adornee.Position
		local alreadygot = {}
		scanSide(v.Adornee, start, alreadygot)
		scanSide(v.Adornee, start + Vector3.new(0, 0, 3), alreadygot)
		table.sort(alreadygot, function(a, b)
			return (bedwars.ItemMeta[a].block and bedwars.ItemMeta[a].block.health or 0) > (bedwars.ItemMeta[b].block and bedwars.ItemMeta[b].block.health or 0)
		end)
		v.Enabled = #alreadygot > 0
	
		for _, block in alreadygot do
			local blockimage = Instance.new('ImageLabel')
			blockimage.Size = UDim2.fromOffset(32, 32)
			blockimage.BackgroundTransparency = 1
			blockimage.Image = bedwars.getIcon({itemType = block}, true)
			blockimage.Parent = v.Frame
		end
	end
	
	local function Added(v)
		if not table.find(Whitelist.ListEnabled, v.Name) then return end
		local billboard = Instance.new('BillboardGui')
		billboard.Parent = Folder
		billboard.Name = 'bed'
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		billboard.Size = UDim2.fromOffset(36, 36)
		billboard.AlwaysOnTop = true
		billboard.ClipsDescendants = false
		billboard.Adornee = v
		local blur = addBlur(billboard)
		blur.Visible = Background.Enabled
		local frame = Instance.new('Frame')
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		frame.BackgroundTransparency = 1 - (Background.Enabled and Color.Opacity or 0)
		frame.Parent = billboard
		local layout = Instance.new('UIListLayout')
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			billboard.Size = UDim2.fromOffset(math.max(layout.AbsoluteContentSize.X + 4, 36), 36)
		end)
		layout.Parent = frame
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = frame
		Reference[v] = billboard
		refreshAdornee(billboard)
	end
	
	local function refreshNear(data)
		data = data.blockRef.blockPosition * 3
		for i, v in Reference do
			if (data - i.Position).Magnitude <= 30 then
				refreshAdornee(v)
			end
		end
	end
	
	ItemPlates = vape.Categories.Render:CreateModule({
		Name = 'ItemPlates',
		Function = function(callback)
			if callback then
				for _, v in collectionService:GetTagged('block') do
					task.spawn(Added, v)
				end
				ItemPlates:Clean(vapeEvents.PlaceBlockEvent.Event:Connect(refreshNear))
				ItemPlates:Clean(vapeEvents.BreakBlockEvent.Event:Connect(refreshNear))
				ItemPlates:Clean(collectionService:GetInstanceAddedSignal('block'):Connect(Added))
				ItemPlates:Clean(collectionService:GetInstanceRemovedSignal('block'):Connect(function(v)
					if Reference[v] then
						Reference[v]:Destroy()
						Reference[v]:ClearAllChildren()
						Reference[v] = nil
					end
				end))
			else
				table.clear(Reference)
				Folder:ClearAllChildren()
			end
		end,
		Tooltip = 'Displays surrounding blocks around the item.'
	})
	Whitelist = ItemPlates:CreateTextList({
		Name = 'Whitelist',
		Default = {'beehive'}
	})
	Background = ItemPlates:CreateToggle({
		Name = 'Background',
		Function = function(callback)
			if Color.Object then 
				Color.Object.Visible = callback 
			end
			for _, v in Reference do
				v.Frame.BackgroundTransparency = 1 - (callback and Color.Opacity or 0)
				v.Blur.Visible = callback
			end
		end,
		Default = true
	})
	Color = ItemPlates:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in Reference do
				v.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.Frame.BackgroundTransparency = 1 - opacity
			end
		end,
		Darker = true
	})
end)

run(function()
	local KitDisplay
	
	local function waitForChild(start, ...)
	    local parent = start
	    for _, v in {...} do
	        local deadline = tick() + 10
	        local child
	        repeat
	            child = parent and parent:FindFirstChild(v)
	            if not child then task.wait(0.1) end
	        until child or not KitDisplay.Enabled or tick() >= deadline
	        parent = child
	        if not parent then
	            break
	        end
	    end
	    return parent
	end
	
	local function getPlayerDraft(name) 
	    for _, v in playersService:GetPlayers() do
	        if name and (v.Name == name or v.DisplayName == name or v:GetAttribute('DisguiseDisplayName') == name) then
	            return v
	        end
	
	        local displayName = bedwars.StreamerModeController and bedwars.StreamerModeController:getDisplayName(v)
	        if name and displayName == name then
	            return v
	        end
	    end
	    return nil
	end
	
	local function tweenKit(roact, image)
	    roact.Image = image
	    roact.Position = UDim2.fromScale(1.05, 0)
	    tweenService:Create(roact, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
	        Position = UDim2.fromScale(1.05, 0.5)
	    }):Play()
	end
	
	local function renderKit(v)
	    task.wait(0.3)
		if not KitDisplay.Enabled or not v.Parent then return end
	    local name = v:FindFirstChild('PlayerName', true)
	    if name then
	        local player = getPlayerDraft(name.Text)
	        if player then
	            local frame = v:FindFirstChild('1')
	            local card = frame and frame:FindFirstChild('MatchDraftPlayerCard')
	            if not card then return end
	            local roact, image = card:FindFirstChild('KitImage'), bedwars.BedwarsKitMeta[player:GetAttribute('PlayingAsKits')] or bedwars.BedwarsKitMeta.none
	            if not roact then
	                roact = Instance.new('ImageLabel')
	                roact.BackgroundTransparency = 1
	                roact.AnchorPoint = Vector2.new(1, 0.5)
	                roact.Position = UDim2.fromScale(1.05, 0)
	                roact.Name = 'KitImage'
	                roact.Size = UDim2.fromScale(1.5, 1.5)
	                roact.ZIndex = 1
	                roact.ImageTransparency = 0.4
	                roact.SliceCenter = Rect.new(0, 0, 0, 0)
	                roact.SliceScale = 1
	                roact.ScaleType = Enum.ScaleType.Crop
	                roact.Parent = card
	
	                KitDisplay:Clean(roact)
	
	                local ratio = Instance.new('UIAspectRatioConstraint', roact)
	                ratio.Name = '1'
	                ratio.AspectRatio = 1
	                ratio.AspectType = Enum.AspectType.FitWithinMaxSize
	                ratio.DominantAxis = Enum.DominantAxis.Width
	            end
	
	            tweenKit(roact, image.renderImage)
	
	            local connection = player:GetAttributeChangedSignal('PlayingAsKits'):Connect(function()
	                if not KitDisplay.Enabled or not roact.Parent then return end
	                image = bedwars.BedwarsKitMeta[player:GetAttribute('PlayingAsKits')] or bedwars.BedwarsKitMeta.none
	                tweenKit(roact, image.renderImage)
	            end)
	            KitDisplay:Clean(name:GetPropertyChangedSignal('Text'):Once(function()
	                if connection then
	                    connection:Disconnect()
	                    connection = nil
	                end
	                renderKit(v)
	            end))
	            KitDisplay:Clean(connection)
	        end
	    end
	end
	
	KitDisplay = vape.Categories.Render:CreateModule({
	    Name = 'KitDisplay',
	    Function = function(callback)
	        if callback then
	            local bodyContainer
	            repeat
	                local app = lplr.PlayerGui:FindFirstChild('MatchDraftApp')
	                local background = app and app:FindFirstChild('DraftAppBackground')
	                local frame = background and background:FindFirstChild('1')
	                bodyContainer = frame and frame:FindFirstChild('BodyContainer')
	                if not bodyContainer then task.wait(0.1) end
	            until bodyContainer or not KitDisplay.Enabled
	            if not KitDisplay.Enabled then return end
	            if bodyContainer then
	                for i = 1, 2 do
	                    local column = waitForChild(bodyContainer, 'Team' .. i .. 'Column')
	                    if column then
	                        KitDisplay:Clean(column.ChildAdded:Connect(renderKit))
	                        for _, v in column:GetChildren() do
	                            task.spawn(renderKit, v)
	                        end
	                    end
	                end
	            end
	        end
	    end,
	    Tooltip = 'Allows you to view opponent\'s kit in match draft.'
	})
	
end)

run(function()
	local KitESP
	local Background
	local Color = {}
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local ESPKits = {
		alchemist = {'alchemist_ingedients', 'wild_flower'},
		beekeeper = {'bee', 'bee'},
		bigman = {'treeOrb', 'natures_essence_1'},
		ghost_catcher = {'ghost', 'ghost_orb'},
		metal_detector = {'hidden-metal', 'iron'},
		sheep_herder = {'SheepModel', 'purple_hay_bale'},
		sorcerer = {'alchemy_crystal', 'wild_flower'},
		star_collector = {'stars', 'crit_star'}
	}
	
	local function Added(v, icon)
		local billboard = Instance.new('BillboardGui')
		billboard.Parent = Folder
		billboard.Name = icon
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		billboard.Size = UDim2.fromOffset(36, 36)
		billboard.AlwaysOnTop = true
		billboard.ClipsDescendants = false
		billboard.Adornee = v
		local blur = addBlur(billboard)
		blur.Visible = Background.Enabled
		local image = Instance.new('ImageLabel')
		image.Size = UDim2.fromOffset(36, 36)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		image.BackgroundTransparency = 1 - (Background.Enabled and Color.Opacity or 0)
		image.BorderSizePixel = 0
		image.Image = bedwars.getIcon({itemType = icon}, true)
		image.Parent = billboard
		local uicorner = Instance.new('UICorner')
		uicorner.CornerRadius = UDim.new(0, 4)
		uicorner.Parent = image
		Reference[v] = billboard
	end
	
	local function addKit(tag, icon)
		KitESP:Clean(collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			Added(v.PrimaryPart, icon)
		end))
		KitESP:Clean(collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if Reference[v.PrimaryPart] then
				Reference[v.PrimaryPart]:Destroy()
				Reference[v.PrimaryPart] = nil
			end
		end))
		for _, v in collectionService:GetTagged(tag) do
			Added(v.PrimaryPart, icon)
		end
	end
	
	KitESP = vape.Categories.Render:CreateModule({
		Name = 'KitESP',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.equippedKit ~= '' or (not KitESP.Enabled)
				local kit = KitESP.Enabled and ESPKits[store.equippedKit] or nil
				if kit then
					addKit(kit[1], kit[2])
				end
			else
				Folder:ClearAllChildren()
				table.clear(Reference)
			end
		end,
		Tooltip = 'ESP for certain kit related objects'
	})
	Background = KitESP:CreateToggle({
		Name = 'Background',
		Function = function(callback)
			if Color.Object then Color.Object.Visible = callback end
			for _, v in Reference do
				v.ImageLabel.BackgroundTransparency = 1 - (callback and Color.Opacity or 0)
				v.Blur.Visible = callback
			end
		end,
		Default = true
	})
	Color = KitESP:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in Reference do
				v.ImageLabel.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.ImageLabel.BackgroundTransparency = 1 - opacity
			end
		end,
		Darker = true
	})
end)

run(function()
	local NameTags
	local Targets
	local Color
	local Background
	local DisplayName
	local Health
	local Distance
	local Rank
	local Enchant
	local Equipment
	local DrawingToggle
	local Scale
	local FontOption
	local Teammates
	local DistanceCheck
	local DistanceLimit
	local Strings, Sizes, Reference = {}, {}, {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	local methodused
	
	local Added = {
		Normal = function(ent)
			if not Targets.Players.Enabled and ent.Player then return end
			if not Targets.NPCs.Enabled and ent.NPC then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
	
			local nametag = Instance.new('TextLabel')
			Strings[ent] = ent.Player and whitelist:tag(ent.Player, true, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
			if Health.Enabled then
				local healthColor = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
				Strings[ent] = Strings[ent]..' <font color="rgb('..tostring(math.floor(healthColor.R * 255))..','..tostring(math.floor(healthColor.G * 255))..','..tostring(math.floor(healthColor.B * 255))..')">'..math.round(ent.Health)..'</font>'
			end
	
			if Distance.Enabled then
				Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..Strings[ent]
			end
	
			if Equipment.Enabled then
				for i, v in {'Hand', 'Helmet', 'Chestplate', 'Boots', 'Kit'} do
					local Icon = Instance.new('ImageLabel')
					Icon.Name = v
					Icon.Size = UDim2.fromOffset(30, 30)
					Icon.Position = UDim2.fromOffset(-60 + (i * 30), -30)
					Icon.BackgroundTransparency = 1
					Icon.Image = ''
					Icon.Parent = nametag
				end
			end
	
			task.spawn(function()
				if Rank.Enabled and ent.Player then
					local Icon = Instance.new('ImageLabel')
					Icon.Name = 'RankIcon'
					Icon.Size = UDim2.fromOffset(30, 30)
					Icon.Position = UDim2.fromOffset(size.X + 10, -4)
					Icon.BackgroundTransparency = 1
					Icon.Image = store.rank[ent.Player]:async() and bedwars.RankMeta[store.rank[ent.Player]:async()].image or ''
					Icon.Parent = nametag
				end
			end)
	
			task.spawn(function()
				if Enchant.Enabled and ent.Player then
					local Icon = Instance.new('ImageLabel')
					Icon.Name = 'EnchantIcon'
					Icon.Size = UDim2.fromOffset(30, 30)
					Icon.Position = UDim2.fromOffset(-30, -4)
					Icon.BackgroundTransparency = 1
					Icon.Image = store.enchants[ent.Player]:async() or ''
					Icon.Parent = nametag
				end
			end)
	
			nametag.TextSize = 14 * Scale.Value
			nametag.FontFace = FontOption.Value
			local size = getfontsize(removeTags(Strings[ent]), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
			nametag.Name = ent.Player and ent.Player.Name or ent.Character.Name
			nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
			nametag.AnchorPoint = Vector2.new(0.5, 1)
			nametag.BackgroundColor3 = Color3.new()
			nametag.BackgroundTransparency = Background.Value
			nametag.BorderSizePixel = 0
			nametag.Visible = false
			nametag.Text = Strings[ent]
			nametag.TextColor3 = entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			nametag.RichText = true
			nametag.Parent = Folder
			Reference[ent] = nametag
		end,
		Drawing = function(ent)
			if not Targets.Players.Enabled and ent.Player then return end
			if not Targets.NPCs.Enabled and ent.NPC then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
	
			local nametag = {}
			nametag.BG = Drawing.new('Square')
			nametag.BG.Filled = true
			nametag.BG.Transparency = 1 - Background.Value
			nametag.BG.Color = Color3.new()
			nametag.BG.ZIndex = 1
			nametag.Text = Drawing.new('Text')
			nametag.Text.Size = 15 * Scale.Value
			nametag.Text.Font = 0
			nametag.Text.ZIndex = 2
			Strings[ent] = ent.Player and whitelist:tag(ent.Player, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
			if Health.Enabled then
				Strings[ent] = Strings[ent]..' '..math.round(ent.Health)
			end
	
			if Distance.Enabled then
				Strings[ent] = '[%s] '..Strings[ent]
			end
	
			nametag.Text.Text = Strings[ent]
			nametag.Text.Color = entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
			Reference[ent] = nametag
		end
	}
	
	local Removed = {
		Normal = function(ent)
			local v = Reference[ent]
			if v then
				Reference[ent] = nil
				Strings[ent] = nil
				Sizes[ent] = nil
				v:Destroy()
			end
		end,
		Drawing = function(ent)
			local v = Reference[ent]
			if v then
				Reference[ent] = nil
				Strings[ent] = nil
				Sizes[ent] = nil
				for _, obj in v do
					pcall(function()
						obj.Visible = false
						obj:Remove()
					end)
				end
			end
		end
	}
	
	local Updated = {
		Normal = function(ent)
			local nametag = Reference[ent]
			if nametag then
				Sizes[ent] = nil
				Strings[ent] = ent.Player and whitelist:tag(ent.Player, true, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
				if Health.Enabled then
					local healthColor = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
					Strings[ent] = Strings[ent]..' <font color="rgb('..tostring(math.floor(healthColor.R * 255))..','..tostring(math.floor(healthColor.G * 255))..','..tostring(math.floor(healthColor.B * 255))..')">'..math.round(ent.Health)..'</font>'
				end
	
				if Distance.Enabled then
					Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..Strings[ent]
				end
	
				if Equipment.Enabled and store.inventories[ent.Player] then
					local kit = ent.Player:GetAttribute('PlayingAsKits')
					local inventory = store.inventories[ent.Player]
					nametag.Hand.Image = bedwars.getIcon(inventory.hand or {itemType = ''}, true)
					nametag.Helmet.Image = bedwars.getIcon(inventory.armor[4] or {itemType = ''}, true)
					nametag.Chestplate.Image = bedwars.getIcon(inventory.armor[5] or {itemType = ''}, true)
					nametag.Boots.Image = bedwars.getIcon(inventory.armor[6] or {itemType = ''}, true)
					nametag.Kit.Image = kit and kit ~= 'none' and bedwars.BedwarsKitMeta[kit].renderImage or ''
				end
				
				if Enchant.Enabled and nametag:FindFirstChild('EnchantIcon') then
					nametag.EnchantIcon.Image = store.enchants[ent.Player]:async() or ''
				end
	
				local size = getfontsize(removeTags(Strings[ent]), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
				nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
				nametag.Text = Strings[ent]
			end
		end,
		Drawing = function(ent)
			local nametag = Reference[ent]
			if nametag then
				if vape.ThreadFix then
					setthreadidentity(8)
				end
				Sizes[ent] = nil
				Strings[ent] = ent.Player and whitelist:tag(ent.Player, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
				if Health.Enabled then
					Strings[ent] = Strings[ent]..' '..math.round(ent.Health)
				end
	
				if Distance.Enabled then
					Strings[ent] = '[%s] '..Strings[ent]
					nametag.Text.Text = entitylib.isAlive and string.format(Strings[ent], math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude)) or Strings[ent]
				else
					nametag.Text.Text = Strings[ent]
				end
	
				nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
				nametag.Text.Color = entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			end
		end
	}
	
	local ColorFunc = {
		Normal = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for i, v in Reference do
				v.TextColor3 = entitylib.getEntityColor(i) or color
			end
		end,
		Drawing = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for i, v in Reference do
				v.Text.Color = entitylib.getEntityColor(i) or color
			end
		end
	}
	
	local Loop = {
		Normal = function()
			for ent, nametag in Reference do
				if DistanceCheck.Enabled then
					local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
					if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
						nametag.Visible = false
						continue
					end
				end
	
				local headPos, headVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
				nametag.Visible = headVis
				if not headVis then
					continue
				end
	
				if Distance.Enabled then
					local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude) or 0
					if Sizes[ent] ~= mag then
						nametag.Text = string.format(Strings[ent], mag)
						local ize = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
						nametag.Size = UDim2.fromOffset(ize.X + 8, ize.Y + 7)
						Sizes[ent] = mag
					end
				end
				nametag.Position = UDim2.fromOffset(headPos.X, headPos.Y)
			end
		end,
		Drawing = function()
			for ent, nametag in Reference do
				if DistanceCheck.Enabled then
					local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
					if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
						nametag.Text.Visible = false
						nametag.BG.Visible = false
						continue
					end
				end
	
				local headPos, headVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
				nametag.Text.Visible = headVis
				nametag.BG.Visible = headVis
				if not headVis then
					continue
				end
	
				if Distance.Enabled then
					local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude) or 0
					if Sizes[ent] ~= mag then
						nametag.Text.Text = string.format(Strings[ent], mag)
						nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
						Sizes[ent] = mag
					end
				end
				nametag.BG.Position = Vector2.new(headPos.X - (nametag.BG.Size.X / 2), headPos.Y - nametag.BG.Size.Y)
				nametag.Text.Position = nametag.BG.Position + Vector2.new(4, 3)
			end
		end
	}
	
	NameTags = vape.Categories.Render:CreateModule({
		Name = 'NameTags',
		Function = function(callback)
			if callback then
				methodused = DrawingToggle.Enabled and 'Drawing' or 'Normal'
				if Removed[methodused] then
					NameTags:Clean(entitylib.Events.EntityRemoved:Connect(Removed[methodused]))
				end
				if Added[methodused] then
					for _, v in entitylib.List do
						if Reference[v] then
							Removed[methodused](v)
						end
						Added[methodused](v)
					end
					NameTags:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
						if Reference[ent] then
							Removed[methodused](ent)
						end
						Added[methodused](ent)
					end))
				end
				if Updated[methodused] then
					NameTags:Clean(entitylib.Events.EntityUpdated:Connect(Updated[methodused]))
					for _, v in entitylib.List do
						Updated[methodused](v)
					end
				end
				if ColorFunc[methodused] then
					NameTags:Clean(vape.Categories.Friends.ColorUpdate.Event:Connect(function()
						ColorFunc[methodused](Color.Hue, Color.Sat, Color.Value)
					end))
				end
				if Loop[methodused] then
					NameTags:Clean(runService.RenderStepped:Connect(Loop[methodused]))
				end
			else
				if Removed[methodused] then
					for i in Reference do
						Removed[methodused](i)
					end
				end
			end
		end,
		Tooltip = 'Renders nametags on entities through walls.'
	})
	Targets = NameTags:CreateTargets({
		Players = true,
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	FontOption = NameTags:CreateFont({
		Name = 'Font',
		Blacklist = 'Arial',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Color = NameTags:CreateColorSlider({
		Name = 'Player Color',
		Function = function(hue, sat, val)
			if NameTags.Enabled and ColorFunc[methodused] then
				ColorFunc[methodused](hue, sat, val)
			end
		end
	})
	Scale = NameTags:CreateSlider({
		Name = 'Scale',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = 1,
		Min = 0.1,
		Max = 1.5,
		Decimal = 10
	})
	Background = NameTags:CreateSlider({
		Name = 'Transparency',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = 0.5,
		Min = 0,
		Max = 1,
		Decimal = 10
	})
	Health = NameTags:CreateToggle({
		Name = 'Health',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Distance = NameTags:CreateToggle({
		Name = 'Distance',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Equipment = NameTags:CreateToggle({
		Name = 'Equipment',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Enchant = NameTags:CreateToggle({
		Name = 'Show Enchant',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Rank = NameTags:CreateToggle({
		Name = 'Show Rank',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	DisplayName = NameTags:CreateToggle({
		Name = 'Use Displayname',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = true
	})
	Teammates = NameTags:CreateToggle({
		Name = 'Priority Only',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = true
	})
	DrawingToggle = NameTags:CreateToggle({
		Name = 'Drawing',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
	})
	DistanceCheck = NameTags:CreateToggle({
		Name = 'Distance Check',
		Function = function(callback)
			DistanceLimit.Object.Visible = callback
		end
	})
	DistanceLimit = NameTags:CreateTwoSlider({
		Name = 'Player Distance',
		Min = 0,
		Max = 256,
		DefaultMin = 0,
		DefaultMax = 64,
		Darker = true,
		Visible = false
	})
end)

run(function()
	local NoTextures
	local Materials = {}
	local Decals = {}
	local Meshes = {}
	local reference = {}
	
	local function remember(obj, property)
		local props = reference[obj]
		if not props then
			props = {}
			reference[obj] = props
		end
	
		if props[property] == nil then
			props[property] = obj[property]
		end
	end
	
	local function stripObject(obj)
		if Decals.Enabled and obj:IsA('Decal') then
			remember(obj, 'Transparency')
			obj.Transparency = 1
			return
		end
	
		if Decals.Enabled and obj:IsA('SurfaceAppearance') then
			remember(obj, 'Parent')
			obj.Parent = nil
			return
		end
	
		if Meshes.Enabled and obj:IsA('SpecialMesh') then
			remember(obj, 'TextureId')
			obj.TextureId = ''
			return
		end
	
		if obj:IsA('BasePart') then
			if Meshes.Enabled and obj:IsA('MeshPart') then
				remember(obj, 'TextureID')
				obj.TextureID = ''
			end
	
			if Materials.Enabled then
				remember(obj, 'Material')
				obj.Material = Enum.Material.SmoothPlastic
			end
		end
	end
	
	local function restore()
		for i, v in reference do
			pcall(function()
				for property, value in v do
					i[property] = value
				end
			end)
		end
		table.clear(reference)
	end
	
	local function scan()
		local descendants = store.map:GetDescendants()
	
		for i, v in descendants do
			if not NoTextures.Enabled then return end
			stripObject(v)
	
			if i % 500 == 0 then
				task.wait()
			end
		end
	end
	
	local function refresh()
		if not NoTextures.Enabled then return end
		restore()
		scan()
	end
	
	NoTextures = vape.Categories.Render:CreateModule({
		Name = 'NoTextures',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.map or not NoTextures.Enabled
				if not NoTextures.Enabled then return end
	
				NoTextures:Clean(store.map.DescendantAdded:Connect(function(obj)
					task.defer(stripObject, obj)
				end))
				scan()
			else
				restore()
			end
		end,
		Tooltip = 'Removes textures and materials from the map'
	})
	Materials = NoTextures:CreateToggle({
		Name = 'Materials',
		Default = true,
		Function = refresh,
		Tooltip = 'Flattens every part to smooth plastic'
	})
	Decals = NoTextures:CreateToggle({
		Name = 'Decals',
		Default = true,
		Function = refresh,
		Tooltip = 'Hides decals, textures and PBR surfaces'
	})
	Meshes = NoTextures:CreateToggle({
		Name = 'Meshes',
		Default = true,
		Function = refresh,
		Tooltip = 'Clears textures off meshes'
	})
	
end)

run(function()
	local BulletTracers
	local Material
	local Lifetime
	local Curve
	local Opacity
	local Thickness
	local Color
	local Fade
	
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	
	BulletTracers = vape.Categories.Render:CreateModule({
		Name = 'ProjectileTracers',
		Function = function(callback)
			if callback then
				BulletTracers:Clean(workspace.ChildAdded:Connect(function(projectile)
					task.delay(0, function()
						if not BulletTracers.Enabled or not projectile.Parent or projectile:GetAttribute('ProjectileShooter') ~= lplr.UserId then
							return
						end
						local filter = {projectile}
						if lplr.Character then table.insert(filter, lplr.Character) end
						rayCheck.FilterDescendantsInstances = filter
						local root = projectile:IsA('BasePart') and projectile or projectile:IsA('Model') and projectile.PrimaryPart
						local meta = bedwars.ProjectileMeta[projectile.Name]
						if not root or not meta then return end
						local origin = root.Position
						local velocity = root.AssemblyLinearVelocity
						local velocityMagnitude = velocity.Magnitude
						if velocityMagnitude <= 0 then
							return
						end
						local velocityUnit = velocity / velocityMagnitude
						local gravity = meta.gravitationalAcceleration or workspace.Gravity
						local ray = workspace:Raycast(origin, velocityUnit * 2000, rayCheck)
						local endpoint = ray and ray.Position or (origin + velocityUnit * 2000)
						local travelTime = (endpoint - origin).Magnitude / velocityMagnitude
	
						prediction.SpawnArcTracer(origin, velocityUnit, velocityMagnitude, gravity, travelTime, Curve.Value, {
	                        Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value),
	                        Transparency = Opacity.Value,
	                        Thick = Thickness.Value,
	                        Material = Enum.Material[Material.Value],
	                        Lifetime = Lifetime.Value,
	                        Fade = Fade.Enabled
	                    })
					end)
				end))
			end
		end,
		Tooltip = 'Replacement tracers for projectiles'
	})
	
	local materials = {'SmoothPlastic'}
	for _, v in Enum.Material:GetEnumItems() do
		if v.Name ~= 'SmoothPlastic' then
			table.insert(materials, v.Name)
		end
	end
	Material = BulletTracers:CreateDropdown({
		Name = 'Material',
		List = materials
	})
	Color = BulletTracers:CreateColorSlider({
		Name = 'Tracer Color',
		DefaultOpacity = 0.5
	})
	Thickness = BulletTracers:CreateSlider({
		Name = 'Thickness',
		Min = 0.01,
		Max = 1,
		Default = 0.1,
		Decimal = 100
	})
	Curve = BulletTracers:CreateSlider({
		Name = 'Curveness',
		Min = 1,
		Max = 100,
		Default = 40,
		Tooltip = 'How curve the projectile is gonna be\n(More curve = more lag)'
	})
	Opacity = BulletTracers:CreateSlider({
		Name = 'Opacity',
		Min = 0,
		Max = 1,
		Default = 0,
		Decimal = 100
	})
	Lifetime = BulletTracers:CreateSlider({
		Name = 'Lifetime',
		Min = 0,
		Max = 5,
		Decimal = 100,
		Default = 2,
		Suffix = 'secs'
	})
	Fade = BulletTracers:CreateToggle({
		Name = 'Fade',
		Default = true
	})
end)

run(function()
	local StorageESP
	local List
	local Background
	local Color = {}
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local function nearStorageItem(item)
		for _, v in List.ListEnabled do
			if item:find(v) then return v end
		end
	end
	
	local function refreshAdornee(v)
		local chest = v.Adornee:FindFirstChild('ChestFolderValue')
		chest = chest and chest.Value or nil
		if not chest then
			v.Enabled = false
			return
		end
	
		local chestitems = chest and chest:GetChildren() or {}
		for _, obj in v.Frame:GetChildren() do
			if obj:IsA('ImageLabel') and obj.Name ~= 'Blur' then
				obj:Destroy()
			end
		end
	
		v.Enabled = false
		local alreadygot = {}
		for _, item in chestitems do
			if not alreadygot[item.Name] and (table.find(List.ListEnabled, item.Name) or nearStorageItem(item.Name)) then
				alreadygot[item.Name] = true
				v.Enabled = true
				local blockimage = Instance.new('ImageLabel')
				blockimage.Size = UDim2.fromOffset(32, 32)
				blockimage.BackgroundTransparency = 1
				blockimage.Image = bedwars.getIcon({itemType = item.Name}, true)
				blockimage.Parent = v.Frame
			end
		end
		table.clear(chestitems)
	end
	
	local function Added(v)
		local chest = v:WaitForChild('ChestFolderValue', 3)
		if not (chest and StorageESP.Enabled) then return end
		chest = chest.Value
		local billboard = Instance.new('BillboardGui')
		billboard.Parent = Folder
		billboard.Name = 'chest'
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		billboard.Size = UDim2.fromOffset(36, 36)
		billboard.AlwaysOnTop = true
		billboard.ClipsDescendants = false
		billboard.Adornee = v
		local blur = addBlur(billboard)
		blur.Visible = Background.Enabled
		local frame = Instance.new('Frame')
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		frame.BackgroundTransparency = 1 - (Background.Enabled and Color.Opacity or 0)
		frame.Parent = billboard
		local layout = Instance.new('UIListLayout')
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			billboard.Size = UDim2.fromOffset(math.max(layout.AbsoluteContentSize.X + 4, 36), 36)
		end)
		layout.Parent = frame
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = frame
		Reference[v] = billboard
		StorageESP:Clean(chest.ChildAdded:Connect(function(item)
			if table.find(List.ListEnabled, item.Name) or nearStorageItem(item.Name) then
				refreshAdornee(billboard)
			end
		end))
		StorageESP:Clean(chest.ChildRemoved:Connect(function(item)
			if table.find(List.ListEnabled, item.Name) or nearStorageItem(item.Name) then
				refreshAdornee(billboard)
			end
		end))
		task.spawn(refreshAdornee, billboard)
	end
	
	StorageESP = vape.Categories.Render:CreateModule({
		Name = 'StorageESP',
		Function = function(callback)
			if callback then
				StorageESP:Clean(collectionService:GetInstanceAddedSignal('chest'):Connect(Added))
				for _, v in collectionService:GetTagged('chest') do
					task.spawn(Added, v)
				end
			else
				table.clear(Reference)
				Folder:ClearAllChildren()
			end
		end,
		Tooltip = 'Displays items in chests'
	})
	List = StorageESP:CreateTextList({
		Name = 'Item',
		Function = function()
			for _, v in Reference do
				task.spawn(refreshAdornee, v)
			end
		end
	})
	Background = StorageESP:CreateToggle({
		Name = 'Background',
		Function = function(callback)
			if Color.Object then Color.Object.Visible = callback end
			for _, v in Reference do
				v.Frame.BackgroundTransparency = 1 - (callback and Color.Opacity or 0)
				v.Blur.Visible = callback
			end
		end,
		Default = true
	})
	Color = StorageESP:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in Reference do
				v.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.Frame.BackgroundTransparency = 1 - opacity
			end
		end,
		Darker = true
	})
end)

run(function()
	local AntiLasso
	local Chance
	local Check
	
	local function Added(ent)
	    AntiLasso:Clean(ent.ChildAdded:Connect(function(v)
	        if v:IsA('Accessory') and v:FindFirstChild('Rope') and Random.new(os.clock()):NextNumber(1, 100) < Chance.Value and (not Check.Enabled or entitylib.EntityPosition({
	            Range = 50,
	            Part = 'RootPart',
	            Players = true
	        })) then
	            ent.PrimaryPart.Anchored = true
	            v.Destroying:Once(function()
	                task.wait(0.5)
	                ent.PrimaryPart.Anchored = false
	            end)
	        end
	    end))
	end
	
	AntiLasso = vape.Categories.Utility:CreateModule({
	    Name = 'AntiLasso',
	    Function = function(callback)
	        if callback then
	            AntiLasso:Clean(entitylib.Events.LocalAdded:Connect(function(ent)
	                task.delay(1, function()
	                    Added(ent.Character)
	                end)
	            end))
	            if entitylib.isAlive then
	                Added(lplr.Character)
	            end
	        end
	    end,
	    Tooltip = 'Prevents you from getting pulled by lasso projectile.'
	})
	
	Chance = AntiLasso:CreateSlider({
	    Name = 'Chance',
	    Min = 0,
	    Max = 100,
	    Default = 100,
	    Suffix = '%'
	})
	Check = AntiLasso:CreateToggle({Name = 'Only when targeting'})
end)

run(function()
	local AutoBalloon
	
	AutoBalloon = vape.Categories.Utility:CreateModule({
		Name = 'AutoBalloon',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.matchState ~= 0 or (not AutoBalloon.Enabled)
				if not AutoBalloon.Enabled then return end
	
				local lowestpoint = math.huge
				for _, v in store.blocks do
					local point = (v.Position.Y - (v.Size.Y / 2)) - 50
					if point < lowestpoint then 
						lowestpoint = point 
					end
				end
	
				repeat
					if entitylib.isAlive then
						if entitylib.character.RootPart.Position.Y < lowestpoint and (lplr.Character:GetAttribute('InflatedBalloons') or 0) < 3 then
							local balloon = getItem('balloon')
							if balloon then
								for _ = 1, 3 do 
									bedwars.BalloonController:inflateBalloon() 
								end
							end
							task.wait(0.1)
						end
					end
					task.wait(0.1)
				until not AutoBalloon.Enabled
			end
		end,
		Tooltip = 'Inflates when you fall into the void'
	})
end)

run(function()
	local AutoBlockUp
	local LimitItem
	local lastPlace = 0
	
	local function getBlockUpItem()
		if store.hand.toolType == 'block' then
			return store.hand.tool and store.hand.tool.Name
		elseif not LimitItem.Enabled then
			for _, item in store.inventory.inventory.items do
				local meta = bedwars.ItemMeta[item.itemType]
				if meta and meta.block then
					return item.itemType
				end
			end
		end
		return nil
	end
	
	AutoBlockUp = vape.Categories.Utility:CreateModule({
		Name = 'AutoBlockUp',
		Function = function(callback)
			if callback then
				AutoBlockUp:Clean(runService.Heartbeat:Connect(function()
	                if entitylib.isAlive and up then
	                    local item = getBlockUpItem()
	                    if item then
	                        local pos = roundPos(entitylib.character.RootPart.Position - Vector3.new(0, entitylib.character.HipHeight + 1.5, 0))
	                        if tick() >= lastPlace and not getPlacedBlock(pos) then
	                            lastPlace = tick() + 0.15
	                            bedwars.placeBlock(pos, item, false)
	                        end
	
	                        entitylib.character.RootPart.Velocity = Vector3.new(entitylib.character.RootPart.Velocity.X, 35, entitylib.character.RootPart.Velocity.Z)
	                    end
	                end
				end))
	            AutoBlockUp:Clean(inputService.InputBegan:Connect(function(input)
	                if not inputService:GetFocusedTextBox() then
	                    if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
	                        up = true
	                    end
	                end
	            end))
	            AutoBlockUp:Clean(inputService.InputEnded:Connect(function(input)
	                if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
	                    up = false
	                    entitylib.character.RootPart.Velocity = Vector3.new(entitylib.character.RootPart.Velocity.X, 0, entitylib.character.RootPart.Velocity.Z)
	                end
	            end))
	            if inputService.TouchEnabled then
	                pcall(function()
	                    local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
	                    AutoBlockUp:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
	                        up = jumpButton.ImageRectOffset.X == 146 and true or false
	                    end))
	                end)
	            end
			end
		end,
		Tooltip = 'Places a block beneath you while holding jump so you can tower up instantly'
	})
	
	LimitItem = AutoBlockUp:CreateToggle({Name = 'Limit to items'})
end)

run(function()
	local AutoCounter
	local Mode
	local Range
	local Limit
	local AutoSwitch = {}
	
	local function getAttackData()
	    if Limit.Enabled then
	        local tool = store.hand.tool
	        return tool and tool.Name == 'tnt' and tool or nil
	    end
	    local item = getItem('tnt')
	    return item and item.tool or nil
	end
	
	AutoCounter = vape.Categories.Utility:CreateModule({
	    Name = 'AutoCounterTNT',
	    Function = function(callback)
	        if callback then
	            local tnts, placed = {}, {}
	            AutoCounter:Clean(workspace.ChildAdded:Connect(function(v)
	                if v.Name == 'tnt' then
	                    table.insert(tnts, v)
	                    v.Destroying:Once(function()
	                        local index = table.find(tnts, v)
	                        if index then
	                            table.remove(tnts, index)
	                        end
	                    end)
	                end
	            end))
	            repeat
	                for pos, expiry in placed do
	                    if expiry <= tick() then
	                        placed[pos] = nil
	                    end
	                end
	                if entitylib.isAlive then
	                    local item = getAttackData()
	                    if item then
	                        local localPosition = entitylib.character.RootPart.Position
	                        for _, v in tnts do
	                            local roundedPos = Vector3.new(math.round(v.Position.X), math.round(v.Position.Y), math.round(v.Position.Z))
	                            if v.Velocity.Y >= 0 and not placed[roundedPos] and (localPosition - v.Position).Magnitude <= Range.Value then
	                                if not Limit.Enabled and AutoSwitch.Enabled then
	                                    local hotbar = getHotbar(item)
	                                    switchItem(item)
	                                    if hotbar then
	                                        hotbarSwitch(hotbar)
	                                    end
	                                end
	                                placed[roundedPos] = tick() + 3
	                                task.spawn(bedwars.placeBlock, v.Position, item.Name)
	                                task.wait(0.12)
	                            end
	                        end
	                    end
	                end
	                task.wait(0.1)
	            until not AutoCounter.Enabled
	        end
	    end,
	    Tooltip = 'Automatically places tnt on opponent\'s tnt'
	})
	
	Mode = AutoCounter:CreateDropdown({
	    Name = 'Mode',
	    List = {'Toggle', 'On key'},
	    Default = 'Toggle'
	})
	Range = AutoCounter:CreateSlider({
	    Name = 'Range',
	    Min = 1,
	    Max = 60,
	    Default = 30
	})
	Limit = AutoCounter:CreateToggle({
	    Name = 'Limit to item',
	    Function = function(callback)
	        if AutoSwitch.Object then
	            AutoSwitch.Object.Visible = not callback
	        end
	    end
	})
	AutoSwitch = AutoCounter:CreateToggle({
	    Name = 'Auto Switch',
	    Function = function(callback)
	        Limit.Object.Visible = not callback
	    end,
	    Default = true
	})
end)

run(function()
	local AutoHonor
	local Delay
	
	local Honored = {}
	local function honor()
	    if #Honored > 1 then return end
	    local list, team = table.clone(entitylib.List), lplr:GetAttribute('Team')
	    table.sort(list, function(a, b)
	        return a.Player:GetAttribute('Team') == team and b.Player:GetAttribute('Team') ~= team
	    end)
	    for _, v in list do
	        if #Honored > 1 then break end
	        if not table.find(Honored, v.Player) then
	            bedwars.HonorController:honorPlayer(v.Player.UserId)
	            table.insert(Honored, v.Player)
	            task.wait(Delay.Value)
	        end
	    end
	end
	
	AutoHonor = vape.Categories.Utility:CreateModule({
	    Name = 'AutoHonor',
	    Function = function(callback)
	        if callback then
	            AutoHonor:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
	                if deathTable.finalKill and deathTable.entityInstance == lplr.Character and #bedwars.Store:getState().Party.members <= 0 and store.matchState ~= 2 then
	                    honor()
	                end
	            end))
	            AutoHonor:Clean(vapeEvents.MatchEndEvent.Event:Connect(honor))
	        end
	    end,
	    Tooltip = 'Automatically honor your teammates'
	})
	
	Delay = AutoHonor:CreateSlider({
	    Name = 'Delay',
	    Min = 0,
	    Max = 2,
	    Decimal = 100,
	    Suffix = 'seconds',
	    Default = 0.1
	})
end)

run(function()
	local AutoKit
	local Legit
	local Toggles = {}
	
	local function kitCollection(id, func, range, specific)
		local objs = type(id) == 'table' and id or collection(id, AutoKit)
		repeat
			if entitylib.isAlive then
				local localPosition = entitylib.character.RootPart.Position
				for _, v in objs do
					if InfiniteFly.Enabled or not AutoKit.Enabled then break end
					local part = not v:IsA('Model') and v or v.PrimaryPart
					if part and (part.Position - localPosition).Magnitude <= (not Legit.Enabled and specific and math.huge or range) then
						func(v)
					end
				end
			end
			task.wait(0.1)
		until not AutoKit.Enabled
	end
	
	local AutoKitFunctions = {
		battery = function()
			repeat
				if entitylib.isAlive then
					local localPosition = entitylib.character.RootPart.Position
					for i, v in bedwars.BatteryEffectsController.liveBatteries do
						if (v.position - localPosition).Magnitude <= 10 then
							local BatteryInfo = bedwars.BatteryEffectsController:getBatteryInfo(i)
							if not BatteryInfo or BatteryInfo.activateTime >= workspace:GetServerTimeNow() or BatteryInfo.consumeTime + 0.1 >= workspace:GetServerTimeNow() then continue end
							BatteryInfo.consumeTime = workspace:GetServerTimeNow()
							bedwars.Handler:Get('ConsumeBattery'):Fire('SendToServer', {batteryId = i})
						end
					end
				end
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		beekeeper = function()
			kitCollection('bee', function(v)
				bedwars.Handler:Get('PickUpBee'):Fire('SendToServer', {beeId = v:GetAttribute('BeeId')})
			end, 18, false)
		end,
		bigman = function()
			kitCollection('treeOrb', function(v)
				if bedwars.Handler:Get('ConsumeTreeOrb'):Fire('CallServer', {treeOrbSecret = v:GetAttribute('TreeOrbSecret')}) then
					v:Destroy()
				end
			end, 12, false)
		end,
		block_kicker = function()
			local old = bedwars.BlockKickerKitController.getKickBlockProjectileOriginPosition
			bedwars.BlockKickerKitController.getKickBlockProjectileOriginPosition = function(...)
				local origin, dir = select(2, ...)
				local plr = entitylib.EntityMouse({
					Part = 'RootPart',
					Range = 1000,
					Origin = origin,
					Players = true,
					Wallcheck = true
				})
	
				if plr then
					local calc = prediction.SolveTrajectory(origin, 100, 20, plr.RootPart.Position, plr.RootPart.Velocity, workspace.Gravity, plr.HipHeight, plr.Jumping and 42.6 or nil)
	
					if calc then
						for i, v in debug.getstack(2) do
							if v == dir then
								debug.setstack(2, i, CFrame.lookAt(origin, calc).LookVector)
							end
						end
					end
				end
	
				return old(...)
			end
	
			AutoKit:Clean(function()
				bedwars.BlockKickerKitController.getKickBlockProjectileOriginPosition = old
			end)
		end,
		cat = function()
			local old = bedwars.CatController.leap
			bedwars.CatController.leap = function(...)
				vapeEvents.CatPounce:Fire()
				return old(...)
			end
	
			AutoKit:Clean(function()
				bedwars.CatController.leap = old
			end)
		end,
		davey = function()
			local old = bedwars.CannonHandController.launchSelf
			bedwars.CannonHandController.launchSelf = function(...)
				local res = {old(...)}
				local self, block = ...
	
				if block:GetAttribute('PlacedByUserId') == lplr.UserId and (block.Position - entitylib.character.RootPart.Position).Magnitude < 30 then
					task.spawn(bedwars.breakBlock, block, false, nil, true)
				end
	
				return unpack(res)
			end
	
			AutoKit:Clean(function()
				bedwars.CannonHandController.launchSelf = old
			end)
		end,
		dragon_slayer = function()
			kitCollection('KaliyahPunchInteraction', function(v)
				bedwars.DragonSlayerController:deleteEmblem(v)
				bedwars.DragonSlayerController:playPunchAnimation(Vector3.zero)
				bedwars.Handler:Get('RequestDragonPunch'):Fire('SendToServer', {
					target = v
				})
			end, 18, true)
		end,
		farmer_cletus = function()
			kitCollection('HarvestableCrop', function(v)
				if bedwars.Handler:Get('HarvestCrop'):Fire('CallServer', {position = bedwars.BlockController:getBlockPosition(v.Position)}) then
					bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.PUNCH)
					bedwars.SoundManager:playSound(bedwars.SoundList.CROP_HARVEST)
				end
			end, 10, false)
		end,
		fisherman = function()
			local old = bedwars.FishingMinigameController.startMinigame
			bedwars.FishingMinigameController.startMinigame = function(_, _, result)
				result({win = true})
			end
	
			AutoKit:Clean(function()
				bedwars.FishingMinigameController.startMinigame = old
			end)
		end,
		gingerbread_man = function()
			local old = bedwars.LaunchPadController.attemptLaunch
			bedwars.LaunchPadController.attemptLaunch = function(...)
				local res = {old(...)}
				local self, block = ...
	
				if (workspace:GetServerTimeNow() - self.lastLaunch) < 0.4 then
					if block:GetAttribute('PlacedByUserId') == lplr.UserId and (block.Position - entitylib.character.RootPart.Position).Magnitude < 30 then
						task.spawn(bedwars.breakBlock, block, false, nil, true)
					end
				end
	
				return unpack(res)
			end
	
			AutoKit:Clean(function()
				bedwars.LaunchPadController.attemptLaunch = old
			end)
		end,
		hannah = function()
			kitCollection('HannahExecuteInteraction', function(v)
				local billboard = bedwars.Handler:Get('HannahPromptTrigger'):Fire('CallServer', {
					user = lplr,
					victimEntity = v
				}) and v:FindFirstChild('Hannah Execution Icon')
	
				if billboard then
					billboard:Destroy()
				end
			end, 30, true)
		end,
		jailor = function()
			kitCollection('jailor_soul', function(v)
				bedwars.JailorController:collectEntity(lplr, v, 'JailorSoul')
			end, 20, false)
		end,
		grim_reaper = function()
			kitCollection(bedwars.GrimReaperController.soulsByPosition, function(v)
				if entitylib.isAlive and lplr.Character:GetAttribute('Health') <= (lplr.Character:GetAttribute('MaxHealth') / 4) and (not lplr.Character:GetAttribute('GrimReaperChannel')) then
					bedwars.Handler:Get('ConsumeGrimReaperSoul'):Fire('CallServer', {
						secret = v:GetAttribute('GrimReaperSoulSecret')
					})
				end
			end, 120, false)
		end,
		melody = function()
			repeat
				local mag, hp, ent = 30, math.huge
				if entitylib.isAlive then
					local localPosition = entitylib.character.RootPart.Position
					for _, v in entitylib.List do
						if v.Player and v.Player:GetAttribute('Team') == lplr:GetAttribute('Team') then
							local newmag = (localPosition - v.RootPart.Position).Magnitude
							if newmag <= mag and v.Health < hp and v.Health < v.MaxHealth then
								mag, hp, ent = newmag, v.Health, v
							end
						end
					end
				end
	
				if ent and getItem('guitar') then
					bedwars.Handler:Get('GuitarHeal'):Fire('SendToServer', {
						healTarget = ent.Character
					})
				end
	
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		metal_detector = function()
			kitCollection('hidden-metal', function(v)
				bedwars.Handler:Get('CollectCollectableEntity'):Fire('SendToServer', {
					id = v:GetAttribute('Id')
				})
			end, 20, false)
		end,
		miner = function()
			kitCollection('petrified-player', function(v)
				bedwars.Handler:Get('DestroyPetrifiedPlayer'):Fire('SendToServer', {
					petrifyId = v:GetAttribute('PetrifyId')
				})
			end, 6, true)
		end,
		pinata = function()
			kitCollection(lplr.Name..':pinata', function(v)
				if getItem('candy') then
					bedwars.Handler:Get('DepositCoins'):Fire('CallServer', v)
				end
			end, 6, true)
		end,
		spirit_assassin = function()
			kitCollection('EvelynnSoul', function(v)
				bedwars.SpiritAssassinController:useSpirit(lplr, v)
			end, 120, true)
		end,
		star_collector = function()
			kitCollection('stars', function(v)
				bedwars.StarCollectorController:collectEntity(lplr, v, v.Name)
			end, 20, false)
		end,
		summoner = function()
			repeat
				local plr = entitylib.EntityPosition({
					Range = 31,
					Part = 'RootPart',
					Players = true,
					Sort = sortmethods.Health
				})
	
				if plr and (not Legit.Enabled or (lplr.Character:GetAttribute('Health') or 0) > 0) then
					local localPosition = entitylib.character.RootPart.Position
					local shootDir = CFrame.lookAt(localPosition, plr.RootPart.Position).LookVector
					localPosition += shootDir * math.max((localPosition - plr.RootPart.Position).Magnitude - 16, 0)
	
					bedwars.Handler:Get('SummonerClawAttackRequest'):Fire('SendToServer', {
						position = localPosition,
						direction = shootDir,
						clientTime = workspace:GetServerTimeNow()
					})
				end
	
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		void_dragon = function()
			local oldflap = bedwars.VoidDragonController.flapWings
			local flapped
	
			bedwars.VoidDragonController.flapWings = function(self)
				if not flapped and bedwars.Handler:Get('DragonFlap'):Fire('CallServer') then
					local modifier = bedwars.SprintController:getMovementStatusModifier():addModifier({
						blockSprint = true,
						constantSpeedMultiplier = 2
					})
					self.SpeedMaid:GiveTask(modifier)
					self.SpeedMaid:GiveTask(function()
						flapped = false
					end)
					flapped = true
				end
			end
	
			AutoKit:Clean(function()
				bedwars.VoidDragonController.flapWings = oldflap
			end)
	
			repeat
				if bedwars.VoidDragonController.inDragonForm then
					local plr = entitylib.EntityPosition({
						Range = 30,
						Part = 'RootPart',
						Players = true
					})
	
					if plr then
						bedwars.Handler:Get('DragonBreath'):Fire('SendToServer', {
							player = lplr,
							targetPoint = plr.RootPart.Position
						})
					end
				end
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		warlock = function()
			local lastTarget
			repeat
				if store.hand.tool and store.hand.tool.Name == 'warlock_staff' then
					local plr = entitylib.EntityPosition({
						Range = 30,
						Part = 'RootPart',
						Players = true,
						NPCs = true
					})
	
					if plr and plr.Character ~= lastTarget then
						if not bedwars.Handler:Get('WarlockLinkTarget'):Fire('CallServer', {
							target = plr.Character
						}) then
							plr = nil
						end
					end
	
					lastTarget = plr and plr.Character
				else
					lastTarget = nil
				end
	
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		wizard = function()
			repeat
				local ability = lplr:GetAttribute('WizardAbility')
				if ability and bedwars.AbilityController:canUseAbility(ability) then
					local plr = entitylib.EntityPosition({
						Range = 50,
						Part = 'RootPart',
						Players = true,
						Sort = sortmethods.Health
					})
	
					if plr then
						bedwars.AbilityController:useAbility(ability, newproxy(true), {target = plr.RootPart.Position})
					end
				end
	
				task.wait(0.1)
			until not AutoKit.Enabled
		end
	}
	
	AutoKit = vape.Categories.Utility:CreateModule({
		Name = 'AutoKit',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.equippedKit ~= '' and store.matchState ~= 0 or (not AutoKit.Enabled)
				if AutoKit.Enabled and AutoKitFunctions[store.equippedKit] and Toggles[store.equippedKit].Enabled then
					AutoKitFunctions[store.equippedKit]()
				end
			end
		end,
		Tooltip = 'Automatically uses kit abilities.'
	})
	Legit = AutoKit:CreateToggle({Name = 'Legit Range'})
	local sortTable = {}
	for i in AutoKitFunctions do
		table.insert(sortTable, i)
	end
	table.sort(sortTable, function(a, b)
		return bedwars.BedwarsKitMeta[a].name < bedwars.BedwarsKitMeta[b].name
	end)
	for _, v in sortTable do
		Toggles[v] = AutoKit:CreateToggle({
			Name = bedwars.BedwarsKitMeta[v].name,
			Default = true
		})
	end
end)

run(function()
	local AutoPearl
	local Legit
	local Back
	local Check
	local LandCheck
	local BackDelay
	local Limit
	
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	rayCheck.FilterType = Enum.RaycastFilterType.Include
	
	local function firePearl(pos, spot, item)
		if Check.Enabled then
			--[[for _, v in store.selfProjectiles do -- later maybe
				if v.Name == 'telepearl' then
					return
				end
			end]]
		end
		local hotbar, old = getHotbar(item.tool), store.hand
	
		switchItem(item.tool)
		if Legit.Enabled and hotbar then
			hotbarSwitch(hotbar)
		end
	
		local meta = bedwars.ProjectileMeta.telepearl
		local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)
		local landed = false
	
		if calc then
			local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
			local projectile = bedwars.ProjectileController:createLocalProjectile(meta, 'telepearl', 'telepearl', pos, nil, dir, {drawDurationSeconds = 1})
			local res = bedwars.Handler:Get('ProjectileFire'):Fire('CallServer',
				item.tool,
				'telepearl',
				'telepearl',
				pos,
				pos,
				dir,
				httpService:GenerateGUID(true),
				{ 
	                drawDurationSeconds = 1, 
	                shotId = httpService:GenerateGUID(false) 
	            },
				workspace:GetServerTimeNow() - 0.045
			)
			task.spawn(function()
				local timeout = tick() + 10
				repeat
					task.wait()
				until not AutoPearl.Enabled or not projectile or not projectile.Parent or tick() >= timeout
				landed = true
			end)
			if res then
				pcall(function()
					res.Parent = replicatedStorage
				end)
			end
		else
			landed = true
		end
	
		if Back.Enabled and LandCheck.Enabled then
			repeat
				task.wait()
			until landed or not AutoPearl.Enabled
		end
		if Back.Enabled and old and old.tool then
			task.wait(BackDelay:GetRandomValue())
			switchItem(old.tool)
			if Legit.Enabled and getHotbar(old.tool) then
				hotbarSwitch(getHotbar(old.tool))
			end
		end
	end
	
	local function findNearGround(origin)
		for _, v in {Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0), Vector3.new(0, 0, -1)} do
			for i = 1, 24 do
				local ray = workspace:Raycast((origin.Position + (Vector3.yAxis * 3)) + (v * i), Vector3.new(0, -60, 0), rayCheck)
				if ray then
					return ray.Position
				end
			end
		end
		return nil
	end
	
	AutoPearl = vape.Categories.Utility:CreateModule({
		Name = 'AutoPearl',
		Function = function(callback)
			if callback then
				local check, lasty
				repeat
					if entitylib.isAlive and (not Limit.Enabled or store.hand.tool and store.hand.tool.Name == 'telepearl') then
						local root = entitylib.character.RootPart
						local pearl = getItem('telepearl')
						rayCheck.FilterDescendantsInstances = {store.map}
						rayCheck.CollisionGroup = root.CollisionGroup
	
						if entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
							lasty = root.CFrame
						end
	
						if pearl and root.Velocity.Y < -100 and not workspace:Raycast(root.Position, Vector3.new(0, -200, 0), rayCheck) then
							if not check then
								check = true
								local ground = findNearGround(root.CFrame + Vector3.new(0, 40, 0)) or findNearGround(lasty and lasty + Vector3.new(0, 5, 0) or root.CFrame)
								if ground then
									firePearl(root.Position, ground, pearl)
								end
							end
						else
							check = false
						end
					end
					task.wait(0.1)
				until not AutoPearl.Enabled
			end
		end,
		Tooltip = 'Automatically throws a pearl onto nearby ground after\nfalling a certain distance.'
	})
	
	Legit = AutoPearl:CreateToggle({
		Name = 'Legit Switch',
		Tooltip = 'Visualizes the switching clientside',
		Default = true
	})
	Back = AutoPearl:CreateToggle({
		Name = 'Switch back',
		Default = true,
		Function = function(callback)
			if BackDelay then
				BackDelay.Object.Visible = callback
			end
			if LandCheck then
				LandCheck.Object.Visible = callback
			end
		end,
		Tooltip = 'Switches back to the last slot before pearl'
	})
	LandCheck = AutoPearl:CreateToggle({
		Name = 'Only after landed',
		Tooltip = 'Only switches back after your pearl landed',
		Darker = true
	})
	Check = AutoPearl:CreateToggle({
		Name = 'Pearl check',
		Tooltip = 'Doesn\'t throw a pearl if ur already pearling',
		Default = true
	})
	BackDelay = AutoPearl:CreateTwoSlider({
		Name = 'Switch Back Delay',
		Min = 0,
		Max = 2,
		DefaultMin = 0.1,
		DefaultMax = 0.2,
		Darker = true
	})
	Limit = AutoPearl:CreateToggle({
		Name = 'Limit to item',
		Tooltip = 'Only throws pearl when holding a pearl'
	})
end)

run(function()
	local AutoPlay
	local Random
	
	local function isEveryoneDead()
		return #bedwars.Store:getState().Party.members <= 0
	end
	
	local function joinQueue()
		if not bedwars.Store:getState().Game.customMatch and bedwars.Store:getState().Party.leader.userId == lplr.UserId and bedwars.Store:getState().Party.queueState == 0 then
			if Random.Enabled then
				local listofmodes = {}
				for i, v in bedwars.QueueMeta do
					if not v.disabled and not v.voiceChatOnly and not v.rankCategory then 
						table.insert(listofmodes, i) 
					end
				end
				bedwars.QueueController:joinQueue(listofmodes[math.random(1, #listofmodes)])
			else
				bedwars.QueueController:joinQueue(store.queueType)
			end
		end
	end
	
	AutoPlay = vape.Categories.Utility:CreateModule({
		Name = 'AutoPlay',
		Function = function(callback)
			if callback then
				AutoPlay:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill and deathTable.entityInstance == lplr.Character and isEveryoneDead() and store.matchState ~= 2 then
						joinQueue()
					end
				end))
				AutoPlay:Clean(vapeEvents.MatchEndEvent.Event:Connect(joinQueue))
			end
		end,
		Tooltip = 'Automatically queues after the match ends.'
	})
	Random = AutoPlay:CreateToggle({
		Name = 'Random',
		Tooltip = 'Chooses a random mode'
	})
end)

run(function()
	local AutoShoot
	local Targets
	local Check
	local Projectiles
	local FireRate
	local SwitchDelay
	
	local FireDelays = {}
	local function getAmmo(check)
		for _, item in store.inventory.inventory.items do
			if check.ammoItemTypes and table.find(check.ammoItemTypes, item.itemType) then
				return item.itemType
			end
		end
		return
	end
	
	local function getProjectiles()
		local items = {}
		for _, item in store.inventory.inventory.items do
			local meta = bedwars.ItemMeta[item.itemType]
			local proj = meta.projectileSource
			local ammo = proj and getAmmo(proj)
			if ammo and (table.find(Projectiles.ListEnabled, ammo) or table.find(Projectiles.ListEnabled, item.itemType) or table.find(Projectiles.ListEnabled, meta.displayName)) then
				table.insert(items, {
					item,
					ammo,
					proj.projectileType(ammo),
					proj
				})
			end
		end
		return items
	end
	
	local function getEntity()
		local selfpos = entitylib.character.RootPart.Position
		local plrs = entitylib.AllPosition({
			Origin = selfpos,
			Part = 'RootPart',
			Range = 22,
			Players = Targets.Players.Enabled,
			NPCs = Targets.NPCs.Enabled,
			Wallcheck = Targets.Walls.Enabled,
			Limit = 10
		})
		if #plrs > 0 then
			for _, ent in plrs do
				local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
				local delta = (ent.RootPart.Position - selfpos) * Vector3.new(1, 0, 1)
				local angle = localfacing.Magnitude > 0 and delta.Magnitude > 0 and math.acos(math.clamp(localfacing.Unit:Dot(delta.Unit), -1, 1)) or 0
				if angle > (math.rad(120) / 2) then continue end
				return ent
			end
		end
		return nil
	end
	
	AutoShoot = vape.Categories.Utility:CreateModule({
		Name = 'AutoShoot',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive and store.hand.toolType == 'sword' and (tick() - bedwars.SwordController.lastSwing) < 0.2 then
						local hotbar = store.hand.tool and getHotbar(store.hand.tool) or nil
						for _, data in getProjectiles() do
							local item, ammo, projectile, itemMeta = unpack(data)
							if (FireDelays[item.itemType] or 0) < tick() then
								local ent = getEntity()
								if (not Check.Enabled or ent) and hotbarSwitch(getHotbar(item.tool)) then
									bedwars.Handler:Get('TridentUnanchor'):Fire('CallServer')
									local meta = bedwars.ProjectileMeta[projectile]
									local projSpeed, gravity = meta.launchVelocity, meta.gravitationalAcceleration or 196.2
									local calc = ent and prediction.SolveTrajectory(entitylib.character.RootPart.Position, projSpeed, gravity, ent.RootPart.Position, ent.RootPart.Velocity, workspace.Gravity, ent.HipHeight, ent.Jumping and 42.6 or nil, rayCheck, ent.Humanoid.FloorMaterial == Enum.Material.Air or math.abs(ent.RootPart.Velocity.Y) > 0.01, ent.RootPart.Position, ent.RootPart, nil, true) or nil
									if calc then
										local shootPosition = (CFrame.new(entitylib.character.RootPart.Position, calc) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ))).Position
										local dir, id = CFrame.lookAt(shootPosition, calc).LookVector, httpService:GenerateGUID(true)
										bedwars.ProjectileController:createLocalProjectile(meta, ammo, projectile, shootPosition, id, dir * projSpeed, {drawDurationSeconds = 1})
										bedwars.Handler:Get('ProjectileFire'):Fire('CallServerAsync', 
											item.tool, 
											ammo, 
											projectile, 
											shootPosition, 
											entitylib.character.RootPart.Position, 
											dir * projSpeed, 
											id, 
											{
												drawDurationSeconds = 1,
												shotId = httpService:GenerateGUID(false),
											}, 
											workspace:GetServerTimeNow() - 0.045
										):andThen(function(res)
											if res then
												res.Parent = replicatedStorage
											end
										end)
										FireDelays[item.itemType] = tick() + (itemMeta.fireDelaySec + FireRate:GetRandomValue())
										task.wait(SwitchDelay.Value)
									end
								end
							end
						end
						hotbarSwitch(hotbar)
					end
					task.wait(0.1)
				until not AutoShoot.Enabled
			else
				bedwars.ProjectileController.createLocalProjectile = old
			end
		end,
		Tooltip = 'Automatically crossbow macro\'s'
	})
	
	Targets = AutoShoot:CreateTargets({Players = true})
	Check = AutoShoot:CreateToggle({
		Name = 'Target check',
		Default = true,
		Function = function(callback)
			if Targets.Object then
				Targets.Object.Visible = callback
			end
		end
	})
	Projectiles = AutoShoot:CreateTextList({
		Name = 'Projectiles',
		Default = {'arrow', 'snowball'}
	})
	FireRate = AutoShoot:CreateTwoSlider({
		Name = 'Fire Rate',
		Min = 0,
		Max = 1,
		DefaultMin = 0.05,
		DefaultMax = 0.12,
		Decimal = 100
	})
	SwitchDelay = AutoShoot:CreateSlider({
		Name = 'Switch Delay',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Suffix = 'seconds',
		Default = 0.02
	})
end)

run(function()
	local AutoToxic
	local GG
	local Toggles, Lists, said, dead = {}, {}, {}
	
	local function sendMessage(name, obj, default)
		local tab = Lists[name].ListEnabled
		local custommsg = #tab > 0 and tab[math.random(1, #tab)] or default
		if not custommsg then return end
		if #tab > 1 and custommsg == said[name] then
			repeat 
				task.wait() 
				custommsg = tab[math.random(1, #tab)] 
			until custommsg ~= said[name]
		end
		said[name] = custommsg
	
		custommsg = custommsg and custommsg:gsub('<obj>', obj or '') or ''
		if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
		else
			replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
		end
	end
	
	AutoToxic = vape.Categories.Utility:CreateModule({
		Name = 'AutoToxic',
		Function = function(callback)
			if callback then
				AutoToxic:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
					if Toggles.BedDestroyed.Enabled and bedTable.brokenBedTeam.id == lplr:GetAttribute('Team') then
						sendMessage('BedDestroyed', (bedTable.player.DisplayName or bedTable.player.Name), 'how dare you >:( | <obj>')
					elseif Toggles.Bed.Enabled and bedTable.player.UserId == lplr.UserId then
						local team = bedwars.QueueMeta[store.queueType].teams[tonumber(bedTable.brokenBedTeam.id)]
						sendMessage('Bed', team and team.displayName:lower() or 'white', 'nice bed lul | <obj>')
					end
				end))
				AutoToxic:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill then
						local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
						local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
						if not killed or not killer then return end
						if killed == lplr then
							if (not dead) and killer ~= lplr and Toggles.Death.Enabled then
								dead = true
								sendMessage('Death', (killer.DisplayName or killer.Name), 'my gaming chair subscription expired :( | <obj>')
							end
						elseif killer == lplr and Toggles.Kill.Enabled then
							sendMessage('Kill', (killed.DisplayName or killed.Name), 'vxp on top | <obj>')
						end
					end
				end))
				AutoToxic:Clean(vapeEvents.MatchEndEvent.Event:Connect(function(winstuff)
					if GG.Enabled then
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync('gg')
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer('gg', 'All')
						end
					end
					
					local myTeam = bedwars.Store:getState().Game.myTeam
					if myTeam and myTeam.id == winstuff.winningTeamId or lplr.Neutral then
						if Toggles.Win.Enabled then 
							sendMessage('Win', nil, 'yall garbage') 
						end
					end
				end))
			end
		end,
		Tooltip = 'Says a message after a certain action'
	})
	GG = AutoToxic:CreateToggle({
		Name = 'AutoGG',
		Default = true
	})
	for _, v in {'Kill', 'Death', 'Bed', 'BedDestroyed', 'Win'} do
		Toggles[v] = AutoToxic:CreateToggle({
			Name = v..' ',
			Function = function(callback)
				if Lists[v] then
					Lists[v].Object.Visible = callback
				end
			end
		})
		Lists[v] = AutoToxic:CreateTextList({
			Name = v,
			Darker = true,
			Visible = false
		})
	end
end)

run(function()
	local AutoVoidDrop
	local OwlCheck
	
	AutoVoidDrop = vape.Categories.Utility:CreateModule({
		Name = 'AutoVoidDrop',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.matchState ~= 0 or (not AutoVoidDrop.Enabled)
				if not AutoVoidDrop.Enabled then return end
	
				local lowestpoint = math.huge
				for _, v in store.blocks do
					local point = (v.Position.Y - (v.Size.Y / 2)) - 50
					if point < lowestpoint then
						lowestpoint = point
					end
				end
	
				repeat
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						if root.Position.Y < lowestpoint and (lplr.Character:GetAttribute('InflatedBalloons') or 0) <= 0 and not getItem('balloon') then
							if not OwlCheck.Enabled or not root:FindFirstChild('OwlLiftForce') then
								for _, item in {'iron', 'diamond', 'emerald', 'gold'} do
									item = getItem(item)
									if item then
										item = bedwars.Handler:Get('DropItem'):Fire('CallServer', {
											item = item.tool,
											amount = item.amount
										})
	
										if item then
											item:SetAttribute('ClientDropTime', tick() + 100)
										end
									end
								end
							end
						end
					end
	
					task.wait(0.1)
				until not AutoVoidDrop.Enabled
			end
		end,
		Tooltip = 'Drops resources when you fall into the void'
	})
	OwlCheck = AutoVoidDrop:CreateToggle({
		Name = 'Owl check',
		Default = true,
		Tooltip = 'Refuses to drop items if being picked up by an owl'
	})
end)

run(function()
	local EquipKit
	local Kit
	
	local old = {}
	
	EquipKit = vape.Categories.Utility:CreateModule({
	    Name = 'EquipKit',
	    Function = function(callback)
	        if callback then
	            EquipKit:Toggle()
	            notif('EquipKit', `{bedwars.Handler:Get('BedwarsActivateKit'):Fire('CallServer', {kit = old[Kit.Value]}) and 'Successfully equipped' or 'Failed to equip'} {Kit.Value}.`, 10, 'info')
	        end
	    end
	})
	
	local list = {}
	for i, v in bedwars.BedwarsKitMeta do
	    table.insert(list, v.name)
	    old[v.name] = i
	end
	table.sort(list)
	Kit = EquipKit:CreateDropdown({
	    Name = 'Equip kit',
	    List = list,
	    Default = store.equippedKit or 'Ragnar'
	})
end)

run(function()
	local KnockbackDelay
	local Chance
	local AirDelay
	local GroundDelay
	local TargetCheck
	
	local old, rand
	local function apply(type, env, ...)
		local root, mass, dir, knockback = ...
		knockback = knockback and table.clone(knockback) or {}
		knockback[type] = env[type] and knockback[type] or 0
		return old(root, mass, dir, knockback, select(5, ...))
	end
	
	KnockbackDelay = vape.Categories.Utility:CreateModule({
		Name = 'KnockbackDelay',
		Function = function(callback)
			if callback then
				old, rand = bedwars.KnockbackUtil.applyKnockback, Random.new()
				bedwars.KnockbackUtil.applyKnockback = function(...)
					if rand:NextNumber(0, 100) > Chance.Value then
						return old(...)
					end
	
					local root, mass, dir, knockback = ...
					if not TargetCheck.Enabled or entitylib.EntityPosition({
						Range = 50,
						Part = 'RootPart',
						Players = true,
					}) then
						local env = {}
						task.delay(AirDelay:GetRandomValue() / 1000, apply, 'horizontal', env, root, mass, dir, knockback, select(5, ...))
						task.delay(GroundDelay:GetRandomValue() / 1000, apply, 'vertical', env, root, mass, dir, knockback, select(5, ...))
						return
					end
					return old(...)
				end
			else
				bedwars.KnockbackUtil.applyKnockback = old or bedwars.KnockbackUtil.applyKnockback
			end
		end,
		Tooltip = 'Delays incoming knockback packets'
	})
	
	Chance = KnockbackDelay:CreateSlider({
		Name = 'Chance',
		Min = 1,
		Max = 100,
		Suffix = '%',
	    Default = 40
	})
	AirDelay = KnockbackDelay:CreateTwoSlider({
		Name = 'Air delay',
		Min = 0,
		Max = 500,
		DefaultMin = 50,
		DefaultMax = 200
	})
	GroundDelay = KnockbackDelay:CreateTwoSlider({
		Name = 'Ground delay',
		Min = 0,
		Max = 500,
		DefaultMin = 50,
		DefaultMax = 200
	})
	TargetCheck = KnockbackDelay:CreateToggle({Name = 'Target check'})
end)

run(function()
	local LeaveParty; LeaveParty = vape.Categories.Utility:CreateModule({
	    Name = 'LeaveParty',
	    Function = function(callback)
	        if callback then
	            bedwars.PartyController:leaveParty()
	            LeaveParty:Toggle()
	        end
	    end
	})
end)

run(function()
	local MissileTP
	
	MissileTP = vape.Categories.Utility:CreateModule({
		Name = 'MissileTP',
		Function = function(callback)
			if callback then
				MissileTP:Toggle()
				local plr = entitylib.EntityMouse({
					Range = 1000,
					Players = true,
					Part = 'RootPart'
				})
	
				if getItem('guided_missile') and plr then
					local projectile = bedwars.RuntimeLib.await(bedwars.GuidedProjectileController.fireGuidedProjectile:CallServerAsync('guided_missile'))
					if projectile then
						local projectilemodel = projectile.model
						if not projectilemodel.PrimaryPart then
							projectilemodel:GetPropertyChangedSignal('PrimaryPart'):Wait()
						end
	
						local bodyforce = Instance.new('BodyForce')
						bodyforce.Force = Vector3.new(0, projectilemodel.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
						bodyforce.Name = 'AntiGravity'
						bodyforce.Parent = projectilemodel.PrimaryPart
	
						repeat
							projectile.model:SetPrimaryPartCFrame(CFrame.lookAlong(plr.RootPart.CFrame.p, gameCamera.CFrame.LookVector))
							task.wait(0.1)
						until not projectile.model or not projectile.model.Parent
					else
						notif('MissileTP', 'Missile on cooldown.', 3)
					end
				end
			end
		end,
		Tooltip = 'Spawns and teleports a missile to a player\nnear your mouse.'
	})
end)

run(function()
	local PickupRange
	local Range
	local Network
	local Lower
	local Picked = {}
	
	PickupRange = vape.Categories.Utility:CreateModule({
		Name = 'PickupRange',
		Function = function(callback)
			if callback then
				local items = collection('ItemDrop', PickupRange)
				repeat
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in items do
							if tick() - (v:GetAttribute('ClientDropTime') or 0) < 2 or table.find(Picked, v) then continue end
							if isnetworkowner(v) and Network.Enabled and entitylib.character.Humanoid.Health > 0 then 
								v.CFrame = CFrame.new(localPosition - Vector3.new(0, 3, 0)) 
							end
							
							if (localPosition - v.Position).Magnitude <= Range.Value then
								if Lower.Enabled and (localPosition.Y - v.Position.Y) < (entitylib.character.HipHeight - 1) then continue end
								local InsertPosition = #Picked + 1
								table.insert(Picked, InsertPosition, v)
								task.spawn(function()
									bedwars.Handler:Get('PickupItemDrop'):Fire('CallServerAsync', {
										itemDrop = v
									}):andThen(function(suc)
										table.remove(Picked, InsertPosition)
										if suc and bedwars.SoundList then
											bedwars.SoundManager:playSound(bedwars.SoundList.PICKUP_ITEM_DROP)
											local sound = bedwars.ItemMeta[v.Name].pickUpOverlaySound
											if sound then
												bedwars.SoundManager:playSound(sound, {
													position = v.Position,
													volumeMultiplier = 0.9
												})
											end
										end
									end)
								end)
							end
						end
					end
					task.wait(0.1)
				until not PickupRange.Enabled
			end
		end,
		Tooltip = 'Picks up items from a farther distance'
	})
	Range = PickupRange:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 10,
		Default = 10,
		Suffix = function(val) 
			return val == 1 and 'stud' or 'studs' 
		end
	})
	Network = PickupRange:CreateToggle({
		Name = 'Network TP',
		Default = true
	})
	Lower = PickupRange:CreateToggle({Name = 'Feet Check'})
end)

run(function()
	local RavenTP
	
	RavenTP = vape.Categories.Utility:CreateModule({
		Name = 'RavenTP',
		Function = function(callback)
			if callback then
				RavenTP:Toggle()
				local plr = entitylib.EntityMouse({
					Range = 1000,
					Players = true,
					Part = 'RootPart'
				})
	
				if getItem('raven') and plr then
					bedwars.Handler:Get('SpawnRaven'):Fire('CallServerAsync'):andThen(function(projectile)
						if projectile then
							local bodyforce = Instance.new('BodyForce')
							bodyforce.Force = Vector3.new(0, projectile.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
							bodyforce.Parent = projectile.PrimaryPart
	
							if plr then
								task.spawn(function()
									for _ = 1, 20 do
										if plr.RootPart and projectile then
											projectile:SetPrimaryPartCFrame(CFrame.lookAlong(plr.RootPart.Position, gameCamera.CFrame.LookVector))
										end
										task.wait(0.05)
									end
								end)
								task.wait(0.3)
								bedwars.RavenController:detonateRaven()
							end
						end
					end)
				end
			end
		end,
		Tooltip = 'Spawns and teleports a raven to a player\nnear your mouse.'
	})
end)

run(function()
	local Scaffold
	local Expand
	local Tower
	local Downwards
	local Diagonal
	local LimitItem
	local Mouse
	local Visual
	local FillColor
	local OutlineColor
	local adjacent, lastpos, label, visualBlock = {}, Vector3.zero
	
	for x = -3, 3, 3 do
		for y = -3, 3, 3 do
			for z = -3, 3, 3 do
				local vec = Vector3.new(x, y, z)
				if vec ~= Vector3.zero then
					table.insert(adjacent, vec)
				end
			end
		end
	end
	
	local function nearCorner(poscheck, pos)
		local startpos = poscheck - Vector3.new(3, 3, 3)
		local endpos = poscheck + Vector3.new(3, 3, 3)
		local check = poscheck + (pos - poscheck).Unit * 100
		return Vector3.new(math.clamp(check.X, startpos.X, endpos.X), math.clamp(check.Y, startpos.Y, endpos.Y), math.clamp(check.Z, startpos.Z, endpos.Z))
	end
	
	local function blockProximity(pos)
		local mag, returned = 60
		local tab = getBlocksInPoints(bedwars.BlockController:getBlockPosition(pos - Vector3.new(21, 21, 21)), bedwars.BlockController:getBlockPosition(pos + Vector3.new(21, 21, 21)))
		for _, v in tab do
			local blockpos = nearCorner(v, pos)
			local newmag = (pos - blockpos).Magnitude
			if newmag < mag then
				mag, returned = newmag, blockpos
			end
		end
		table.clear(tab)
		return returned
	end
	
	local function checkAdjacent(pos)
		for _, v in adjacent do
			if getPlacedBlock(pos + v) then
				return true
			end
		end
		return false
	end
	
	local function getScaffoldBlock()
		if store.hand.toolType == 'block' then
			return store.hand.tool.Name, store.hand.amount
		elseif (not LimitItem.Enabled) then
			local wool, amount = getWool()
			if wool then
				return wool, amount
			else
				for _, item in store.inventory.inventory.items do
					if bedwars.ItemMeta[item.itemType].block then
						return item.itemType, item.amount
					end
				end
			end
		end
	
		return nil, 0
	end
	
	local function updateVisual(pos)
		if visualBlock then
			visualBlock.CFrame = pos and CFrame.new(bedwars.BlockController:getBlockPosition(pos) * 3) or visualBlock.CFrame
			visualBlock.Parent = pos and gameCamera or nil
		end
	end
	
	Scaffold = vape.Categories.Utility:CreateModule({
		Name = 'Scaffold',
		Function = function(callback)
			if label then
				label.Visible = callback
			end
	
			if callback then
				repeat
					local preview
					if entitylib.isAlive then
						local wool, amount = getScaffoldBlock()
	
						if Mouse.Enabled then
							if not inputService:IsMouseButtonPressed(0) then
								wool = nil
							end
						end
	
						if label then
							amount = amount or 0
							label.Text = amount..' <font color="rgb(170, 170, 170)">(Scaffold)</font>'
							label.TextColor3 = Color3.fromHSV((amount / 128) / 2.8, 0.86, 1)
						end
	
						if wool then
							local root = entitylib.character.RootPart
							if Tower.Enabled and inputService:IsKeyDown(Enum.KeyCode.Space) and (not inputService:GetFocusedTextBox()) then
								root.Velocity = Vector3.new(root.Velocity.X, 38, root.Velocity.Z)
							end
	
							for i = Expand.Value, 1, -1 do
								local currentpos = roundPos(root.Position - Vector3.new(0, entitylib.character.HipHeight + (Downwards.Enabled and inputService:IsKeyDown(Enum.KeyCode.LeftShift) and 4.5 or 1.5), 0) + entitylib.character.Humanoid.MoveDirection * (i * 3))
								if Diagonal.Enabled then
									if math.abs(math.round(math.deg(math.atan2(-entitylib.character.Humanoid.MoveDirection.X, -entitylib.character.Humanoid.MoveDirection.Z)) / 45) * 45) % 90 == 45 then
										local dt = (lastpos - currentpos)
										if ((dt.X == 0 and dt.Z ~= 0) or (dt.X ~= 0 and dt.Z == 0)) and ((lastpos - root.Position) * Vector3.new(1, 0, 1)).Magnitude < 2.5 then
											currentpos = lastpos
										end
									end
								end
	
								local block, blockpos = getPlacedBlock(currentpos)
								if not block then
									blockpos = checkAdjacent(blockpos * 3) and blockpos * 3 or blockProximity(currentpos)
									if blockpos then
										preview = blockpos
										task.spawn(bedwars.placeBlock, blockpos, wool, false)
									end
								end
								lastpos = currentpos
							end
						end
					end
	
					updateVisual(preview)
					task.wait(0.03)
				until not Scaffold.Enabled
			else
				updateVisual()
			end
		end,
		Tooltip = 'Helps you make bridges/scaffold walk.'
	})
	Expand = Scaffold:CreateSlider({
		Name = 'Expand',
		Min = 1,
		Max = 6
	})
	Tower = Scaffold:CreateToggle({
		Name = 'Tower',
		Default = true
	})
	Downwards = Scaffold:CreateToggle({
		Name = 'Downwards',
		Default = true
	})
	Diagonal = Scaffold:CreateToggle({
		Name = 'Diagonal',
		Default = true
	})
	LimitItem = Scaffold:CreateToggle({Name = 'Limit to items'})
	Mouse = Scaffold:CreateToggle({Name = 'Require mouse down'})
	Visual = Scaffold:CreateToggle({
		Name = 'Visual',
		Tooltip = 'Renders an overlay on the block about to be placed',
		Function = function(callback)
			FillColor.Object.Visible = callback
			OutlineColor.Object.Visible = callback
			if callback then
				visualBlock = Instance.new('Part')
				visualBlock.Size = Vector3.new(3, 3, 3)
				visualBlock.Anchored = true
				visualBlock.CanCollide = false
				visualBlock.CanQuery = false
				visualBlock.CanTouch = false
				visualBlock.CastShadow = false
				visualBlock.Transparency = 1
				local selection = Instance.new('SelectionBox')
				selection.Adornee = visualBlock
				selection.LineThickness = 0.04
				selection.Color3 = Color3.fromHSV(OutlineColor.Hue, OutlineColor.Sat, OutlineColor.Value)
				selection.Transparency = 1 - OutlineColor.Opacity
				selection.SurfaceColor3 = Color3.fromHSV(FillColor.Hue, FillColor.Sat, FillColor.Value)
				selection.SurfaceTransparency = 1 - FillColor.Opacity
				selection.Parent = visualBlock
				bedwars.QueryUtil:setQueryIgnored(visualBlock, true)
			else
				visualBlock:Destroy()
				visualBlock = nil
			end
		end
	})
	FillColor = Scaffold:CreateColorSlider({
		Name = 'Fill Color',
		DefaultSat = 0,
		DefaultOpacity = 0.4,
		Darker = true,
		Visible = false,
		Function = function(hue, sat, val, opacity)
			if visualBlock then
				visualBlock.SelectionBox.SurfaceColor3 = Color3.fromHSV(hue, sat, val)
				visualBlock.SelectionBox.SurfaceTransparency = 1 - opacity
			end
		end
	})
	OutlineColor = Scaffold:CreateColorSlider({
		Name = 'Outline Color',
		DefaultValue = 0,
		Darker = true,
		Visible = false,
		Function = function(hue, sat, val, opacity)
			if visualBlock then
				visualBlock.SelectionBox.Color3 = Color3.fromHSV(hue, sat, val)
				visualBlock.SelectionBox.Transparency = 1 - opacity
			end
		end
	})
	Count = Scaffold:CreateToggle({
		Name = 'Block Count',
		Function = function(callback)
			if callback then
				label = Instance.new('TextLabel')
				label.Size = UDim2.fromOffset(100, 20)
				label.Position = UDim2.new(0.5, 6, 0.5, 60)
				label.BackgroundTransparency = 1
				label.AnchorPoint = Vector2.new(0.5, 0)
				label.Text = '0'
				label.TextColor3 = Color3.new(0, 1, 0)
				label.TextSize = 18
				label.RichText = true
				label.Font = Enum.Font.Arial
				label.Visible = Scaffold.Enabled
				label.Parent = vape.gui
			else
				label:Destroy()
				label = nil
			end
		end
	})
end)

run(function()
	local SetEmote
	local Emote
	local track
	
	local list, old = {}, {}
	for i, v in bedwars.EmoteMeta do
	    if i ~= bedwars.EmoteType.NONE and v.name and not old[v.name] then
	        old[v.name] = i
	        table.insert(list, v.name)
	    end
	end
	table.sort(list)
	
	local function cancelEmote()
	    if entitylib.isAlive then
	        if track then
	            track:Stop()
	            track:Destroy()
	            track = nil
	        end
	        if lplr.Character:GetAttribute('PlayingEmote') then
	            lplr.Character:SetAttribute('PlayingEmote', nil)
	        end
	    end
	end
	
	SetEmote = vape.Categories.Utility:CreateModule({
	    Name = 'SetEmote',
	    Function = function(callback)
	        if callback then
	            SetEmote:Toggle()
	            if entitylib.isAlive then
	                local emoteType = old[Emote.Value]
	                local meta = bedwars.EmoteMeta[emoteType]
	                if meta then
	                    lplr.Character:SetAttribute('PlayingEmote', emoteType)
	                    bedwars.EmoteController:playEmoteBeginSounds(emoteType, lplr)
	                    local animation = meta.animation
	                    if not animation and animation.emoteDisplayType then
	                        local display = bedwars.EmoteDisplayMeta[meta.emoteDisplayType]
	                        animation = display and display.animation
	                    end
	                    if animation and not noAutoPlayAnimation then
	                        track = lplr.Character.Humanoid:LoadAnimation(bedwars.GameAnimationUtil:getAnimation(animation.type))
	                        track.Looped = animation.looped or false
	                        track:Play(nil, nil, animation.speed or 1)
	                    end
	                    if not meta.animation then
	                        local gui = Instance.new('BillboardGui')
	                        gui.Size = UDim2.fromScale(6, 2.5)
	                        gui.StudsOffset = Vector3.new(0, 2, 0)
	                        gui.AlwaysOnTop = true
	                        gui.Adornee = lplr.Character.Head
	
	                        local image = Instance.new('ImageLabel')
	                        image.AnchorPoint = Vector2.new(0.5, 1)
	                        image.Position = UDim2.fromScale(0.5, 1)
	                        image.Size = UDim2.fromScale(0, 0)
	                        image.Image = meta.image
	                        image.BackgroundTransparency = 1
	                        image.ImageTransparency = 1
	                        image.ScaleType = Enum.ScaleType.Fit
	                        image.Parent = gui
	
	                        gui.Parent = lplr.Character.Head
	                        tweenService:Create(image, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
	                            Position = UDim2.fromScale(0.5, 0.5),
	                            Size = UDim2.fromScale(1, 1),
	                            ImageTransparency = 0
	                        }):Play()
	                    end
	                    if meta.allowMovement then
	                        task.delay(6, cancelEmote)
	                    else
	                        lplr.Character.Humanoid:GetPropertyChangedSignal('MoveDirection'):Once(cancelEmote)
	                    end
	                end
	            end
	        end
	    end,
	    Tooltip = 'Plays selected emote clientsidedly'
	})
	
	Emote = SetEmote:CreateDropdown({
	    Name = 'Emote',
	    List = list,
	    Default = 'nightmare'
	})
end)

run(function()
	local SetSettings
	local old = bedwars.SettingsController.settings or {}
	local options = {}
	
	SetSettings = vape.Categories.Utility:CreateModule({
	    Name = 'SetSettings',
	    Function = function(callback)
	        if callback then
	            for i in old do
	                local module = options[i]
	                if module then
	                    bedwars.SettingsController:setSetting(i, module.Value)
	                end
	            end
	        end
	    end,
	    Tooltip = 'Adds bedwars settings options to cat vape (also carries the settings with your cv config).'
	})
	
	for i, v in old do
	    if bedwars.SettingsMeta[i] and bedwars.SettingsMeta[i].tab == 'Mobile' then
	        continue
	    end
	    local create = typeof(v) == 'boolean' and 'Toggle' or typeof(v) == 'number' and 'Slider' or nil
	    if create and bedwars.SettingsMeta[i] then
	        options[i] = SetSettings["Create".. create](SetSettings, {
	            Name = bedwars.SettingsMeta[i].name,
	            Default = v,
	            Min = 1,
	            Max = 360,
	            Decimal = 5,
	            Function = function(val)
	                if SetSettings.Enabled then
	                    bedwars.SettingsController:setSetting(i, val)
	                end
	            end
	        })
	    elseif shared.VapeDeveloper then
	        notif('Vape', 'Unknown bedwars setting detected ('.. i.. ')', 20, 'alert')
	    end
	end
end)

run(function()
	local ShopQuickBuy -- coded by seven
	local HoldDelay
	local CPS
	
	local holding = false
	local clickThread
	
	local function getShopId()
	    if not entitylib.isAlive then return nil end
	    local localPosition = entitylib.character.RootPart.Position
	    local id
	    for _, v in store.shop do
	        if v.Shop and (v.RootPart.Position - localPosition).Magnitude <= 20 then
	            id = v.Id
	        end
	    end
	    return id
	end
	
	local function getHoveredItem()
	    local mousepos = (inputService:GetMouseLocation() - guiService:GetGuiInset())
	    for _, v in lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
	        local obj = v
	        while obj and obj ~= lplr.PlayerGui do
	            local itemType = obj.Name:match('^(.+)_ShopItemCard$')
	            if itemType then
	                return itemType
	            end
	            obj = obj.Parent
	        end
	    end
	end
	
	local function canBuy(item)
	    if item.ignoredByKit and table.find(item.ignoredByKit, store.equippedKit or '') then return false end
	    if item.lockedByForge or item.disabled then return false end
	    if item.require and item.require.teamUpgrade then
	        if (bedwars.Store:getState().Bedwars.teamUpgrades[item.require.teamUpgrade.upgradeId] or -1) < item.require.teamUpgrade.lowestTierIndex then
	            return false
	        end
	    end
	    local currency = getItem(item.currency)
	    return (currency and currency.amount or 0) >= item.price
	end
	
	local function purchase(itemType, shopId)
	    if bedwars.BedwarsShopController.alreadyPurchasedMap[itemType] ~= nil then return end
	
	    local item = bedwars.Shop.getShopItem(itemType, lplr, {shopId = shopId})
	    if not item or not canBuy(item) then return end
	
	    bedwars.Handler:Get('BedwarsPurchaseItem'):Fire('CallServerAsync', {
	        shopItem = item,
	        shopId = shopId
	    }):andThen(function(suc)
	        if not suc then return end
	        bedwars.SoundManager:playSound(bedwars.SoundList.BEDWARS_PURCHASE_ITEM)
	        bedwars.Store:dispatch({
	            type = 'BedwarsAddItemPurchased',
	            itemType = itemType
	        })
	        if item.tiered then
	            bedwars.BedwarsShopController.alreadyPurchasedMap[itemType] = true
	        end
	    end)
	end
	
	local function startClicking(itemType)
	    if clickThread then
	        task.cancel(clickThread)
	    end
	    clickThread = task.spawn(function()
	        repeat
	            local shopId = bedwars.AppController:isAppOpen('BedwarsItemShopApp') and store.shopLoaded and getShopId()
	            if shopId then
	                purchase(itemType, shopId)
	            end
	            task.wait(1 / CPS.Value)
	        until not holding
	        clickThread = nil
	    end)
	end
	
	ShopQuickBuy = vape.Categories.Utility:CreateModule({
	    Name = 'ShopClicker',
	    Function = function(callback)
	        if callback then
	            ShopQuickBuy:Clean(inputService.InputBegan:Connect(function(input)
	                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	                if not bedwars.AppController:isAppOpen('BedwarsItemShopApp') then return end
	
	                local itemType = getHoveredItem()
	                if not itemType then return end
	
	                holding = true
	                task.delay(HoldDelay.Value, function()
	                    if holding and getHoveredItem() == itemType then
	                        startClicking(itemType)
	                    end
	                end)
	            end))
	
	            ShopQuickBuy:Clean(inputService.InputEnded:Connect(function(input)
	                if input.UserInputType == Enum.UserInputType.MouseButton1 then
	                    holding = false
	                end
	            end))
	        else
	            holding = false
	            if clickThread then
	                task.cancel(clickThread)
	                clickThread = nil
	            end
	        end
	    end,
	    Tooltip = 'Hold on a shop item to rapidly buy it.'
	})
	HoldDelay = ShopQuickBuy:CreateSlider({
	    Name = 'Hold Delay',
	    Min = 0,
	    Max = 1,
	    Default = 0.15,
	    Decimal = 20,
	    Suffix = 'seconds'
	})
	CPS = ShopQuickBuy:CreateSlider({
	    Name = 'CPS',
	    Min = 1,
	    Max = 20,
	    Default = 20,
	    Darker = true
	})
end)

run(function()
	local StaffDetector
	local Mode
	local Clans
	local Party
	local Profile
	local Users
	local blacklistedclans = {'gg', 'gg2', 'DV', 'DV2'}
	local blacklisteduserids = {1502104539, 3826146717, 4531785383, 1049767300, 4926350670, 653085195, 184655415, 2752307430, 5087196317, 5744061325, 1536265275}
	local joined = {}
	
	local function getRole(plr, id)
		local suc, res = pcall(function()
			return plr:GetRankInGroup(id)
		end)
		if not suc then
			notif('StaffDetector', res, 30, 'alert')
		end
		return suc and res or 0
	end
	
	local function staffFunction(plr, checktype)
		if not vape.Loaded then
			repeat task.wait() until vape.Loaded
		end
	
		notif('StaffDetector', 'Staff Detected ('..checktype..'): '..plr.Name..' ('..plr.UserId..')', 60, 'alert')
		whitelist.customtags[plr.Name] = {{text = 'GAME STAFF', color = Color3.new(1, 0, 0)}}
	
		if Party.Enabled and not checktype:find('clan') then
			bedwars.PartyController:leaveParty()
		end
	
		if Mode.Value == 'Uninject' then
			task.spawn(function()
				vape:Uninject()
			end)
			game:GetService('StarterGui'):SetCore('SendNotification', {
				Title = 'StaffDetector',
				Text = 'Staff Detected ('..checktype..')\n'..plr.Name..' ('..plr.UserId..')',
				Duration = 60,
			})
		elseif Mode.Value == 'Requeue' then
			bedwars.QueueController:joinQueue(store.queueType)
		elseif Mode.Value == 'Profile' then
			vape.Save = function() end
			if vape.Profile ~= Profile.Value then
				vape:Load(true, Profile.Value)
			end
		elseif Mode.Value == 'AutoConfig' then
			local safe = {'AutoClicker', 'Reach', 'Sprint', 'HitFix', 'StaffDetector'}
			vape.Save = function() end
			for i, v in vape.Modules do
				if not (table.find(safe, i) or v.Category == 'Render') then
					if v.Enabled then
						v:Toggle()
					end
					v:SetBind('')
				end
			end
		end
	end
	
	local function checkFriends(list)
		for _, v in list do
			if joined[v] then
				return joined[v]
			end
		end
		return nil
	end
	
	local function checkJoin(plr, connection)
		if not plr:GetAttribute('Team') and plr:GetAttribute('Spectator') and not bedwars.Store:getState().Game.customMatch then
			connection:Disconnect()
			local tab, pages = {}, playersService:GetFriendsAsync(plr.UserId)
			for _ = 1, 4 do
				for _, v in pages:GetCurrentPage() do
					table.insert(tab, v.Id)
				end
				if pages.IsFinished then break end
				pages:AdvanceToNextPageAsync()
			end
	
			local friend = checkFriends(tab)
			if not friend then
				staffFunction(plr, 'impossible_join')
				return true
			else
				notif('StaffDetector', string.format('Spectator %s joined from %s', plr.Name, friend), 20, 'warning')
			end
		end
	end
	
	local function playerAdded(plr)
		joined[plr.UserId] = plr.Name
		if plr == lplr then return end
	
		if table.find(blacklisteduserids, plr.UserId) or table.find(Users.ListEnabled, tostring(plr.UserId)) then
			staffFunction(plr, 'blacklisted_user')
		elseif getRole(plr, 5774246) >= 100 then
			staffFunction(plr, 'staff_role')
		else
			local connection
			connection = plr:GetAttributeChangedSignal('Spectator'):Connect(function()
				checkJoin(plr, connection)
			end)
			StaffDetector:Clean(connection)
			if checkJoin(plr, connection) then
				return
			end
	
			if not plr:GetAttribute('ClanTag') then
				plr:GetAttributeChangedSignal('ClanTag'):Wait()
			end
	
			if table.find(blacklistedclans, plr:GetAttribute('ClanTag')) and vape.Loaded and Clans.Enabled then
				connection:Disconnect()
				staffFunction(plr, 'blacklisted_clan_'..plr:GetAttribute('ClanTag'):lower())
			end
		end
	end
	
	StaffDetector = vape.Categories.Utility:CreateModule({
		Name = 'StaffDetector',
		Function = function(callback)
			if callback then
				StaffDetector:Clean(playersService.PlayerAdded:Connect(playerAdded))
				for _, v in playersService:GetPlayers() do
					task.spawn(playerAdded, v)
				end
			else
				table.clear(joined)
			end
		end,
		Tooltip = 'Detects people with a staff rank ingame'
	})
	Mode = StaffDetector:CreateDropdown({
		Name = 'Mode',
		List = {'Uninject', 'Profile', 'Requeue', 'AutoConfig', 'Notify'},
		Function = function(val)
			if Profile.Object then
				Profile.Object.Visible = val == 'Profile'
			end
		end
	})
	Clans = StaffDetector:CreateToggle({
		Name = 'Blacklist clans',
		Default = true
	})
	Party = StaffDetector:CreateToggle({
		Name = 'Leave party'
	})
	Profile = StaffDetector:CreateTextBox({
		Name = 'Profile',
		Default = 'default',
		Darker = true,
		Visible = false
	})
	Users = StaffDetector:CreateTextList({
		Name = 'Users',
		Placeholder = 'player (userid)'
	})
	
	task.spawn(function()
		repeat task.wait(1) until vape.Loaded or vape.Loaded == nil
		if vape.Loaded and not StaffDetector.Enabled then
			StaffDetector:Toggle()
		end
	end)
end)

run(function()
	TrapDisabler = vape.Categories.Utility:CreateModule({
		Name = 'TrapDisabler',
		Tooltip = 'Disables Snap Traps'
	})
end)

run(function()
	vape.Categories.World:CreateModule({
		Name = 'Anti-AFK',
		Function = function(callback)
			if callback then
				for _, v in getconnections(lplr.Idled) do
					v:Disconnect()
				end
	
				for _, v in getconnections(runService.Heartbeat) do
					if type(v.Function) == 'function' and table.find(debug.getconstants(v.Function), 'AfkInfo') then
						v:Disconnect()
					end
				end
	
				bedwars.Handler:Get('AfkInfo'):Fire('SendToServer', {
					afk = false
				})
			end
		end,
		Tooltip = 'Lets you stay ingame without getting kicked'
	})
end)

run(function()
	local AutoTool
	local old, event
	
	local function switchHotbarItem(block)
		if block and not block:GetAttribute('NoBreak') and not block:GetAttribute('Team'..(lplr:GetAttribute('Team') or 0)..'NoBreak') then
			local tool, slot = store.tools[bedwars.ItemMeta[block.Name].block.breakType], nil
			if tool then
				for i, v in store.inventory.hotbar do
					if v.item and v.item.itemType == tool.itemType then slot = i - 1 break end
				end
	
				if hotbarSwitch(slot) then
					if inputService:IsMouseButtonPressed(0) then 
						event:Fire() 
					end
					return true
				end
			end
		end
	end
	
	AutoTool = vape.Categories.World:CreateModule({
		Name = 'AutoTool',
		Function = function(callback)
			if callback then
				event = Instance.new('BindableEvent')
				AutoTool:Clean(event)
				AutoTool:Clean(event.Event:Connect(function()
					contextActionService:CallFunction('block-break', Enum.UserInputState.Begin, newproxy(true))
				end))
				old = bedwars.BlockBreaker.hitBlock
				bedwars.BlockBreaker.hitBlock = function(self, maid, raycastparams, ...)
					local block = self.clientManager:getBlockSelector():getMouseInfo(1, {ray = raycastparams})
					if switchHotbarItem(block and block.target and block.target.blockInstance or nil) then return end
					return old(self, maid, raycastparams, ...)
				end
			else
				bedwars.BlockBreaker.hitBlock = old
				old = nil
			end
		end,
		Tooltip = 'Automatically selects the correct tool'
	})
end)

run(function()
	local BedAssist
	local AimMode
	local Speed
	local Range
	local Shake
	local Mode
	local Limit
	
	local function ease(t)
	    return t < 0.5 and 4 * t * t * t or 1 - math.pow(-2 * t + 2, 3) / 2
	end
	
	local started = 0
	local aimfuncs = {
	    Simple = function(localcframe, pos, fps)
	        local rng = Random.new()
	        return localcframe:Lerp(CFrame.lookAt(localcframe.p, pos + Vector3.new((rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps)), Speed.Value * fps), Speed.Value
	    end,
	    Adaptive = function(localcframe, pos, fps)
	        local prog, rng = ease(math.min((tick() - started) / (1 / (Speed.Value * 0.5)), 1)), Random.new()
	        local speed = Speed.Value * prog
	        return localcframe:Lerp(CFrame.lookAt(localcframe.p, pos + Vector3.new((rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps, (rng:NextNumber() - 0.5) * Shake.Value * fps)), speed * fps), speed
	    end
	}
	
	local function getBestPosition(block)
	    local handler = bedwars.BlockController:getHandlerRegistry():getHandler(block.Name)
	    local cost, pos = math.huge, nil
	    local mag = 9e9
	
	    local positions = (handler and handler:getContainedPositions(block) or {block.Position / 3})
	
	    for _, v in positions do
	        local dpos, dcost = calculatePath(block, v * 3)
	        local dmag = dpos and (entitylib.character.RootPart.Position - dpos).Magnitude
	
	        if dpos then
	            if dcost < cost or (dcost == cost and dmag < mag) then
	                cost, pos, mag = dcost, dpos, dmag
	            end
	        end
	    end
	
	    if pos and (entitylib.character.RootPart.Position - pos).Magnitude <= Range.Value then
	        return pos
	    end
	    return nil
	end
	
	BedAssist = vape.Categories.World:CreateModule({
	    Name = 'BedAssist',
	    Function = function(call)
	        if call then
	            repeat
	                task.wait()
	            until store.matchState ~= 0 or not BedAssist.Enabled
	            if not BedAssist.Enabled then
	                return
	            end
	
	            local beds = collection('bed', BedAssist, function(tab, obj)
	                task.delay(0, function()
	                    if not obj:GetAttribute('Team' .. (lplr:GetAttribute('Team') or -1) .. 'NoBreak') then
	                        table.insert(tab, obj)
	                    end
	                end)
	            end)
	            local rng = Random.new()
	            local lastbed = nil
	
	            BedAssist:Clean(runService.PostSimulation:Connect(function(dt)
	                if entitylib.isAlive and (not Limit.Enabled or store.hand.tool and bedwars.ItemMeta[store.hand.tool.Name].breakBlock) then
	                    local localPosition = entitylib.character.RootPart.Position
	                    for _, v in beds do
	                        if (localPosition - v.Position).Magnitude <= Range.Value then
	                            if lastbed ~= v then
	                                started = tick()
	                            end
	                            lastbed = v
	
	                            local pos = getBestPosition(v)
	                            if pos then
	                                local pred, speed = aimfuncs[AimMode.Value](gameCamera.CFrame, pos, dt)
	
	                                if Mode.Value == 'Mouse' then
	                                    pos += Vector3.new(
	                                        (rng:NextNumber() - 0.5) * Shake.Value * 0.1,
	                                        (rng:NextNumber() - 0.5) * Shake.Value * 0.1,
	                                        (rng:NextNumber() - 0.5) * Shake.Value * 0.1
	                                    )
	                                    local campos, vis = gameCamera:WorldToViewportPoint(pos)
	                                    if vis then
	                                        local vec2 = (Vector2.new(campos.X, campos.Y) - inputService:GetMouseLocation()) * (speed * dt)
	                                        mousemoverel(vec2.X, vec2.Y)
	                                    end
	                                else
	                                    gameCamera.CFrame = pred
	                                end
	                            end
	                            break
	                        end
	                    end
	                end
	            end))
	        end
	    end,
	    Tooltip = 'Smoothly aims towards a bed close to your mouse'
	})
	
	local list = {'Camera'}
	if inputService.MouseEnabled and mousemoverel then
	    table.insert(list, 'Mouse')
	end
	AimMode = BedAssist:CreateDropdown({
	    Name = 'Mode',
	    List = {'Simple', 'Adaptive'},
	    Default = 'Simple'
	})
	Mode = BedAssist:CreateDropdown({
	    Name = 'Aim mode',
	    List = list,
	    Default = 'Camera'
	})
	Speed = BedAssist:CreateSlider({
	    Name = 'Aim speed',
	    Min = 1,
	    Max = 20,
	    Default = 7
	})
	Range = BedAssist:CreateSlider({
	    Name = 'Range',
	    Min = 1,
	    Max = 30,
	    Default = 20,
	    Suffix = function(val)
	        return val <= 1 and 'stud' or 'studs'
	    end
	})
	Shake = BedAssist:CreateSlider({
	    Name = 'Shake',
	    Min = 1,
	    Max = 100,
	    Default = 3
	})
	Limit = BedAssist:CreateToggle({Name = 'Limit to item', Default = true})
end)

run(function()
	local BedProtector
	local PlaceRange
	local Blacklist
	local Wool
	local Mode
	local Smart
	local Switch
	
	local function getBedNear()
	    local localPosition = entitylib.isAlive and entitylib.character.RootPart.Position or Vector3.zero
	    for _, v in collectionService:GetTagged('bed') do
	        if (localPosition - v.Position).Magnitude < 14 and v:GetAttribute('Team' .. (lplr:GetAttribute('Team') or -1) .. 'NoBreak') then
	            return v
	        end
	    end
	    return nil
	end
	
	local function getBlocks()
	    local blocks = {}
	    for _, item in store.inventory.inventory.items do
	        local block = bedwars.ItemMeta[item.itemType].block
	        if block and (Wool.Enabled and item.itemType:find('wool') or not Wool.Enabled and not table.find(Blacklist.ListEnabled, item.itemType:find('wool') and 'wool' or item.itemType)) then
	            table.insert(blocks, {item.itemType, block.health, item.tool})
	        end
	    end
	    if #blocks > 1 then
	        table.sort(blocks, function(a, b)
	            return a[2] > b[2]
	        end)
	    end
	    return blocks
	end
	
	local function getPyramid(size, grid)
	    local positions = {}
	    for h = size, 0, -1 do
	        for w = h, 0, -1 do
	            table.insert(positions, Vector3.new(w, (size - h), ((h + 1) - w)) * grid)
	            table.insert(positions, Vector3.new(w * -1, (size - h), ((h + 1) - w)) * grid)
	            table.insert(positions, Vector3.new(w, (size - h), (h - w) * -1) * grid)
	            table.insert(positions, Vector3.new(w * -1, (size - h), (h - w) * -1) * grid)
	        end
	    end
	    return positions
	end
	
	BedProtector = vape.Categories.World:CreateModule({
	    Name = 'BedProtector',
	    Function = function(callback)
	        if callback then
	            repeat
	                local bed = getBedNear()
	                if bed then
	                    for i, block in getBlocks() do
	                        local switch, old = Switch.Enabled, store.hand and store.hand.tool and getHotbar(store.hand.tool) or nil
	                        local hotbar = nil
	
	                        if switch then
	                            hotbar = getHotbar(block[3])
	                        end
	
	                        for _, pos in getPyramid(i, 3) do
	                            if not BedProtector.Enabled then
	                                break
	                            end
	                            pos = (bed.CFrame * CFrame.new(pos)).Position
	                            if getPlacedBlock(pos) then
	                                continue
	                            end
	                            if (entitylib.character.RootPart.Position - pos).Magnitude > PlaceRange.Value then
	                                continue
	                            end
	                            if hotbar and hotbarSwitch(hotbar) then
	                                task.wait()
	                            end
	                            task.spawn(bedwars.placeBlock, pos, block[1], false)
	                            task.wait(0.1)
	                        end
	
	                        if switch and old and hotbarSwitch(old) then
	                            task.wait()
	                        end
	                    end
	                else
	                    if Mode.Value == 'On Key' then
	                        notif('BedProtector', 'Unable to locate bed', 5)
	                        BedProtector:Toggle()
	                    end
	                end
	                task.wait(0.5)
	                if Mode.Value == 'On Key' then
	                    BedProtector:Toggle()
	                    break
	                end
	            until not BedProtector.Enabled
	        end
	    end,
	    Tooltip = 'Automatically places strong blocks around the bed.'
	})
	
	Mode = BedProtector:CreateDropdown({
	    Name = 'Mode',
	    List = {'Toggle', 'On Key'},
	    Default = 'Toggle',
	    Function = function(val)
	        if Smart then
	            Smart.Object.Visible = val == 'Toggle'
	        end
	    end
	})
	Blacklist = BedProtector:CreateTextList({
	    Name = 'Blacklist',
	    Default = {'siege_tnt', 'tnt'}
	})
	PlaceRange = BedProtector:CreateSlider({
	    Name = 'Place Range',
	    Min = 1,
	    Max = 30,
	    Default = 15
	})
	Wool = BedProtector:CreateToggle({Name = 'Wool only', Tooltip = 'Only uses wools to bed defend.'})
	Switch = BedProtector:CreateToggle({Name = 'Auto Switch'})
	Smart = BedProtector:CreateToggle({Name = 'Smart', Default = true})
end)

run(function()
	local ChestSteal
	local Range
	local Open
	local Skywars
	local Delays = {}
	
	local function lootChest(chest)
		chest = chest and chest.Value or nil
		local chestitems = chest and chest:GetChildren() or {}
		if #chestitems > 1 and (Delays[chest] or 0) < tick() then
			Delays[chest] = tick() + 0.2
			bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(chest)
	
			for _, v in chestitems do
				if v:IsA('Accessory') then
					task.spawn(function()
						pcall(function()
							bedwars.Client:GetNamespace('Inventory'):Get('ChestGetItem'):CallServer(chest, v)
						end)
					end)
					task.wait(0.01)
				end
			end
	
			bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(nil)
		end
	end
	
	ChestSteal = vape.Categories.World:CreateModule({
		Name = 'ChestSteal',
		Function = function(callback)
			if callback then
				local chests = collection('chest', ChestSteal)
				repeat task.wait() until store.queueType ~= 'bedwars_test'
				if (not Skywars.Enabled) or store.queueType:find('skywars') then
					repeat
						if entitylib.isAlive and store.matchState ~= 2 then
							if Open.Enabled then
								if bedwars.AppController:isAppOpen('ChestApp') then
									lootChest(lplr.Character:FindFirstChild('ObservedChestFolder'))
								end
							else
								local localPosition = entitylib.character.RootPart.Position
								for _, v in chests do
									if (localPosition - v.Position).Magnitude <= Range.Value then
										lootChest(v:FindFirstChild('ChestFolderValue'))
									end
								end
							end
						end
						task.wait(0.1)
					until not ChestSteal.Enabled
				end
			end
		end,
		Tooltip = 'Grabs items from near chests.'
	})
	Range = ChestSteal:CreateSlider({
		Name = 'Range',
		Min = 0,
		Max = 18,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Open = ChestSteal:CreateToggle({Name = 'GUI Check'})
	Skywars = ChestSteal:CreateToggle({
		Name = 'Only Skywars',
		Function = function()
			if ChestSteal.Enabled then
				ChestSteal:Toggle()
				ChestSteal:Toggle()
			end
		end,
		Default = true
	})
end)

run(function()
	local FastPlace
	local CPS
	
	FastPlace = vape.Categories.World:CreateModule({
		Name = 'FastPlace',
		Function = function(callback)
			bedwars.SharedConstants.BLOCK_PLACE_CPS = callback and CPS.Value or 12
		end,
	    Tooltip = 'Changes the block place delay'
	})
	CPS = FastPlace:CreateSlider({
		Name = 'Cps',
		Min = 1,
		Max = 100,
		Function = function(val)
			if FastPlace.Enabled then
				bedwars.SharedConstants.BLOCK_PLACE_CPS = val
			end
		end,
	    Default = 13
	})
	FastPlace:CreateButton({
		Name = 'Reset to bedwars cps',
		Function = function()
			CPS:SetValue(12)
		end
	})
end)

run(function()
	local ArmorSwitch
	local Mode
	local Targets
	local Range
	
	ArmorSwitch = vape.Categories.Inventory:CreateModule({
		Name = 'ArmorSwitch',
		Function = function(callback)
			if callback then
				if Mode.Value == 'Toggle' then
					repeat
						local state = entitylib.EntityPosition({
							Part = 'RootPart',
							Range = Range.Value,
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Wallcheck = Targets.Walls.Enabled
						}) and true or false
	
						for i = 0, 2 do
							if (store.inventory.inventory.armor[i + 1] ~= 'empty') ~= state and ArmorSwitch.Enabled then
								bedwars.Store:dispatch({
									type = 'InventorySetArmorItem',
									item = store.inventory.inventory.armor[i + 1] == 'empty' and state and getBestArmor(i) or nil,
									armorSlot = i
								})
								vapeEvents.InventoryChanged.Event:Wait()
							end
						end
						task.wait(0.1)
					until not ArmorSwitch.Enabled
				else
					ArmorSwitch:Toggle()
					for i = 0, 2 do
						bedwars.Store:dispatch({
							type = 'InventorySetArmorItem',
							item = store.inventory.inventory.armor[i + 1] == 'empty' and getBestArmor(i) or nil,
							armorSlot = i
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
				end
			end
		end,
		Tooltip = 'Puts on / takes off armor when toggled for baiting.'
	})
	Mode = ArmorSwitch:CreateDropdown({
		Name = 'Mode',
		List = {'Toggle', 'On Key'}
	})
	Targets = ArmorSwitch:CreateTargets({
		Players = true,
		NPCs = true
	})
	Range = ArmorSwitch:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 30,
		Default = 30,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local AutoBuy
	local Sword
	local Armor
	local Upgrades
	local TierCheck
	local BedwarsCheck
	local GUI
	local SmartCheck
	local Custom = {}
	local CustomPost = {}
	local UpgradeToggles = {}
	local Functions, id = {}
	local Callbacks = {Custom, Functions, CustomPost}
	local npctick = tick()
	
	local swords = {
		'wood_sword',
		'stone_sword',
		'iron_sword',
		'diamond_sword',
		'emerald_sword'
	}
	
	local armors = {
		'none',
		'leather_chestplate',
		'iron_chestplate',
		'diamond_chestplate',
		'emerald_chestplate'
	}
	
	local axes = {
		'none',
		'wood_axe',
		'stone_axe',
		'iron_axe',
		'diamond_axe'
	}
	
	local pickaxes = {
		'none',
		'wood_pickaxe',
		'stone_pickaxe',
		'iron_pickaxe',
		'diamond_pickaxe'
	}
	
	local function getShopNPC()
		local shop, items, upgrades, newid = nil, false, false, nil
		if entitylib.isAlive then
			local localPosition = entitylib.character.RootPart.Position
			for _, v in store.shop do
				if (v.RootPart.Position - localPosition).Magnitude <= 20 then
					shop = v.Upgrades or v.Shop or nil
					upgrades = upgrades or v.Upgrades
					items = items or v.Shop
					newid = v.Shop and v.Id or newid
				end
			end
		end
		return shop, items, upgrades, newid
	end
	
	local function canBuy(item, currencytable, amount)
		amount = amount or 1
		if not currencytable[item.currency] then
			local currency = getItem(item.currency)
			currencytable[item.currency] = currency and currency.amount or 0
		end
		if item.ignoredByKit and table.find(item.ignoredByKit, store.equippedKit or '') then return false end
		if item.lockedByForge or item.disabled then return false end
		if item.require and item.require.teamUpgrade then
			if (bedwars.Store:getState().Bedwars.teamUpgrades[item.require.teamUpgrade.upgradeId] or -1) < item.require.teamUpgrade.lowestTierIndex then
				return false
			end
		end
		return currencytable[item.currency] >= (item.price * amount)
	end
	
	local function buyItem(item, currencytable)
		if not id then return end
		notif('AutoBuy', 'Bought '..bedwars.ItemMeta[item.itemType].displayName, 3)
		bedwars.Handler:Get('BedwarsPurchaseItem'):Fire('CallServerAsync', {
			shopItem = item,
			shopId = id
		}):andThen(function(suc)
			if suc then
				bedwars.SoundManager:playSound(bedwars.SoundList.BEDWARS_PURCHASE_ITEM)
				bedwars.Store:dispatch({
					type = 'BedwarsAddItemPurchased',
					itemType = item.itemType
				})
				bedwars.BedwarsShopController.alreadyPurchasedMap[item.itemType] = true
			end
		end)
		currencytable[item.currency] -= item.price
	end
	
	local function buyUpgrade(upgradeType, currencytable)
		if not Upgrades.Enabled then return end
		local upgrade = bedwars.TeamUpgradeMeta[upgradeType]
		local currentUpgrades = bedwars.Store:getState().Bedwars.teamUpgrades[lplr:GetAttribute('Team')] or {}
		local currentTier = (currentUpgrades[upgradeType] or 0) + 1
		local bought = false
	
		for i = currentTier, #upgrade.tiers do
			local tier = upgrade.tiers[i]
			if tier.availableOnlyInQueue and not table.find(tier.availableOnlyInQueue, store.queueType) then continue end
	
			if canBuy({currency = 'diamond', price = tier.cost}, currencytable) then
				notif('AutoBuy', 'Bought '..(upgrade.name == 'Armor' and 'Protection' or upgrade.name)..' '..i, 3)
				bedwars.Handler:Get('RequestPurchaseTeamUpgrade'):Fire('CallServerAsync', upgradeType)
				currencytable.diamond -= tier.cost
				bought = true
			else
				break
			end
		end
	
		return bought
	end
	
	local function buyTool(tool, tools, currencytable)
		local bought, buyable = false
		tool = tool and table.find(tools, tool.itemType) and table.find(tools, tool.itemType) + 1 or math.huge
	
		for i = tool, #tools do
			local v = bedwars.Shop.getShopItem(tools[i], lplr)
			if canBuy(v, currencytable) then
				if SmartCheck.Enabled and bedwars.ItemMeta[tools[i]].breakBlock and i > 2 then
					if Armor.Enabled then
						local currentarmor = store.inventory.inventory.armor[2]
						currentarmor = currentarmor and currentarmor ~= 'empty' and currentarmor.itemType or 'none'
						if (table.find(armors, currentarmor) or 3) < 3 then break end
					end
					if Sword.Enabled then
						if store.tools.sword and (table.find(swords, store.tools.sword.itemType) or 2) < 2 then break end
					end
				end
				bought = true
				buyable = v
			end
			if TierCheck.Enabled and v.nextTier then break end
		end
	
		if buyable then
			buyItem(buyable, currencytable)
		end
	
		return bought
	end
	
	AutoBuy = vape.Categories.Inventory:CreateModule({
		Name = 'AutoBuy',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.queueType ~= 'bedwars_test'
				if BedwarsCheck.Enabled and not store.queueType:find('bedwars') then return end
	
				local lastupgrades
				AutoBuy:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(function()
					if (npctick - tick()) > 1 then npctick = tick() end
				end))
	
				repeat
					local npc, shop, upgrades, newid = getShopNPC()
					id = newid
					if GUI.Enabled then
						if not (bedwars.AppController:isAppOpen('BedwarsItemShopApp') or bedwars.AppController:isAppOpen('TeamUpgradeApp')) then
							npc = nil
						end
					end
	
					if npc and lastupgrades ~= upgrades then
						if (npctick - tick()) > 1 then npctick = tick() end
						lastupgrades = upgrades
					end
	
					if npc and npctick <= tick() and store.matchState ~= 2 and store.shopLoaded then
						local currencytable = {}
						local waitcheck
						for _, tab in Callbacks do
							for _, callback in tab do
								if callback(currencytable, shop, upgrades) then
									waitcheck = true
								end
							end
						end
						npctick = tick() + (waitcheck and 0.4 or math.huge)
					end
	
					task.wait(0.1)
				until not AutoBuy.Enabled
			else
				npctick = tick()
			end
		end,
		Tooltip = 'Automatically buys items when you go near the shop'
	})
	Sword = AutoBuy:CreateToggle({
		Name = 'Buy Sword',
		Function = function(callback)
			npctick = tick()
			Functions[2] = callback and function(currencytable, shop)
				if not shop then return end
	
				if store.equippedKit == 'dasher' then
					swords = {
						[1] = 'wood_dao',
						[2] = 'stone_dao',
						[3] = 'iron_dao',
						[4] = 'diamond_dao',
						[5] = 'emerald_dao'
					}
				elseif store.equippedKit == 'ice_queen' then
					swords[5] = 'ice_sword'
				elseif store.equippedKit == 'ember' then
					swords[5] = 'infernal_saber'
				elseif store.equippedKit == 'lumen' then
					swords[5] = 'light_sword'
				end
	
				return buyTool(store.tools.sword, swords, currencytable)
			end or nil
		end
	})
	Armor = AutoBuy:CreateToggle({
		Name = 'Buy Armor',
		Function = function(callback)
			npctick = tick()
			Functions[1] = callback and function(currencytable, shop)
				if not shop then return end
				local currentarmor = store.inventory.inventory.armor[2] ~= 'empty' and store.inventory.inventory.armor[2] or getBestArmor(1)
				currentarmor = currentarmor and currentarmor.itemType or 'none'
				return buyTool({itemType = currentarmor}, armors, currencytable)
			end or nil
		end,
		Default = true
	})
	AutoBuy:CreateToggle({
		Name = 'Buy Axe',
		Function = function(callback)
			npctick = tick()
			Functions[3] = callback and function(currencytable, shop)
				if not shop then return end
				return buyTool(store.tools.wood or {itemType = 'none'}, axes, currencytable)
			end or nil
		end
	})
	AutoBuy:CreateToggle({
		Name = 'Buy Pickaxe',
		Function = function(callback)
			npctick = tick()
			Functions[4] = callback and function(currencytable, shop)
				if not shop then return end
				return buyTool(store.tools.stone, pickaxes, currencytable)
			end or nil
		end
	})
	Upgrades = AutoBuy:CreateToggle({
		Name = 'Buy Upgrades',
		Function = function(callback)
			for _, v in UpgradeToggles do
				v.Object.Visible = callback
			end
		end,
		Default = true
	})
	local count = 0
	for i, v in bedwars.TeamUpgradeMeta do
		local toggleCount = count
		table.insert(UpgradeToggles, AutoBuy:CreateToggle({
			Name = 'Buy '..(v.name == 'Armor' and 'Protection' or v.name),
			Function = function(callback)
				npctick = tick()
				Functions[5 + toggleCount + (v.name == 'Armor' and 20 or 0)] = callback and function(currencytable, shop, upgrades)
					if not upgrades then return end
					if v.disabledInQueue and table.find(v.disabledInQueue, store.queueType) then return end
					return buyUpgrade(i, currencytable)
				end or nil
			end,
			Darker = true,
			Default = (i == 'ARMOR' or i == 'DAMAGE')
		}))
		count += 1
	end
	TierCheck = AutoBuy:CreateToggle({Name = 'Tier Check'})
	BedwarsCheck = AutoBuy:CreateToggle({
		Name = 'Only Bedwars',
		Function = function()
			if AutoBuy.Enabled then
				AutoBuy:Toggle()
				AutoBuy:Toggle()
			end
		end,
		Default = true
	})
	GUI = AutoBuy:CreateToggle({Name = 'GUI check'})
	SmartCheck = AutoBuy:CreateToggle({
		Name = 'Smart check',
		Default = true,
		Tooltip = 'Buys iron armor before iron axe'
	})
	AutoBuy:CreateTextList({
		Name = 'Item',
		Placeholder = 'priority/item/amount/after',
		Function = function(list)
			table.clear(Custom)
			table.clear(CustomPost)
			for _, entry in list do
				local tab = entry:split('/')
				local ind = tonumber(tab[1])
				if ind then
					(tab[4] and CustomPost or Custom)[ind] = function(currencytable, shop)
						if not shop then return end
	
						local v = bedwars.Shop.getShopItem(tab[2], lplr)
						if v then
							local item = getItem(tab[2] == 'wool_white' and bedwars.Shop.getTeamWool(lplr:GetAttribute('Team')) or tab[2])
							item = (item and tonumber(tab[3]) - item.amount or tonumber(tab[3])) // v.amount
							if item > 0 and canBuy(v, currencytable, item) then
								for _ = 1, item do
									buyItem(v, currencytable)
								end
								return true
							end
						end
					end
				end
			end
		end
	})
end)

run(function()
	local AutoConsume
	local Health
	local SpeedPotion
	local Apple
	local ShieldPotion
	
	local function consumeCheck(attribute)
		if entitylib.isAlive then
			if SpeedPotion.Enabled and (not attribute or attribute == 'StatusEffect_speed') then
				local speedpotion = getItem('speed_potion')
				if speedpotion and (not lplr.Character:GetAttribute('StatusEffect_speed')) then
					for _ = 1, 4 do
						if bedwars.Handler:Get('ConsumeItem'):Fire('CallServer', {item = speedpotion.tool}) then break end
					end
				end
			end
	
			if Apple.Enabled and (not attribute or attribute:find('Health')) then
				if (lplr.Character:GetAttribute('Health') / lplr.Character:GetAttribute('MaxHealth')) <= (Health.Value / 100) then
					local apple = getItem('orange') or (not lplr.Character:GetAttribute('StatusEffect_golden_apple') and getItem('golden_apple')) or getItem('apple')
					
					if apple then
						bedwars.Handler:Get('ConsumeItem'):Fire('CallServerAsync', {
							item = apple.tool
						})
					end
				end
			end
	
			if ShieldPotion.Enabled and (not attribute or attribute:find('Shield')) then
				if (lplr.Character:GetAttribute('Shield_POTION') or 0) == 0 then
					local shield = getItem('big_shield') or getItem('mini_shield')
	
					if shield then
						bedwars.Handler:Get('ConsumeItem'):Fire('CallServerAsync', {
							item = shield.tool
						})
					end
				end
			end
		end
	end
	
	AutoConsume = vape.Categories.Inventory:CreateModule({
		Name = 'AutoConsume',
		Function = function(callback)
			if callback then
				AutoConsume:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(consumeCheck))
				AutoConsume:Clean(vapeEvents.AttributeChanged.Event:Connect(function(attribute)
					if attribute:find('Shield') or attribute:find('Health') or attribute == 'StatusEffect_speed' then
						consumeCheck(attribute)
					end
				end))
				consumeCheck()
			end
		end,
		Tooltip = 'Automatically heals for you when health or shield is under threshold.'
	})
	Health = AutoConsume:CreateSlider({
		Name = 'Health Percent',
		Min = 1,
		Max = 99,
		Default = 70,
		Suffix = '%'
	})
	SpeedPotion = AutoConsume:CreateToggle({
		Name = 'Speed Potions',
		Default = true
	})
	Apple = AutoConsume:CreateToggle({
		Name = 'Apple',
		Default = true
	})
	ShieldPotion = AutoConsume:CreateToggle({
		Name = 'Shield Potions',
		Default = true
	})
end)

run(function()
	local AutoFish
	local Show
	local Blacklist
	local Minigame
	local CompleteDelay = {}
	local Cast
	local CastDelay = {}
	
	local old, newMinigame
	local function getBait()
		for _, v in workspace:GetChildren() do
			if v.Name == 'fisherman_bobber' and v:GetAttribute('ProjectileShooter') == lplr.UserId then
				return v
			end
		end
		return nil
	end
	
	AutoFish = vape.Categories.Inventory:CreateModule({
		Name = 'AutoFish',
		Function = function(call)
			if call then
				old = bedwars.FishingMinigameController.startMinigame
				bedwars.FishingMinigameController.startMinigame = function(...)
	                if Minigame.Enabled then
	                    task.wait(CompleteDelay:GetRandomValue())
	                    return select(3, ...)({win = true})
	                end
	                return (old or bedwars.FishingMinigameController.startMinigame)(...)
				end
	
				AutoFish:Clean(bedwars.Handler:Get('FishFound').Remote:Connect(function(data)
	                for _, v in data.dropData.drops do
	                    local amount = tonumber(v.amount) or 0
	                    if Show.Enabled then
	                        local itemDisplay = bedwars.ItemMeta[v.itemType] and bedwars.ItemMeta[v.itemType].displayName or v.itemType
	                        notif('AutoFish', `You can get {amount} {itemDisplay:lower()}{amount >= 2 and 's' or ''} on ur next fish`, 20, 'info')
	                    end
	                    if entitylib.isAlive and table.find(Blacklist.ListEnabled, v.itemType) then
	                        lplr.Character.Humanoid.Jump = true
	                    end
	                end
				end))
				repeat
					if entitylib.isAlive and Cast.Enabled and (store.hand.tool and store.hand.tool.Name == 'fishing_rod') then
						local ray = cloneref(lplr:GetMouse()).UnitRay
						if not getBait() and not workspace:Raycast(entitylib.character.Head.Position + (ray.Direction * 6), Vector3.new(0, -20, 0)) then
							task.wait(CastDelay:GetRandomValue())
							if AutoFish.Enabled then 
	                            bedwars.FishingRodController:beginHolding(handItem, nil, controller.aimingMaid, true)
	                            task.wait()
	                            bedwars.FishingRodController:releaseChargeInput(bedwars.FishingRodController.aimingMaid, function() 
	                                return true 
	                            end, nil)
	                        end
							task.wait(0.1)
						end
					end
					task.wait(0.1)
				until not AutoFish.Enabled
			elseif old then
	            bedwars.FishingMinigameController.startMinigame = old
	            old = nil
			end
		end,
		Tooltip = 'Automatically fishes with fishing rod'
	})
	
	Blacklist = AutoFish:CreateTextList({
		Name = 'Blacklisted loot',
		Default = {'iron'},
	    Tooltip = 'Automatically jumps if u found a fish with the blacklisted item'
	})
	Show = AutoFish:CreateToggle({
		Name = 'Show loot drops',
		Tooltip = 'Notifies ur next lootdrops'
	})
	Minigame = AutoFish:CreateToggle({
		Name = 'Auto Minigame',
		Function = function(callback)
			if CompleteDelay.Object then
				CompleteDelay.Object.Visible = callback
			end
		end,
	    Default = true,
	    Tooltip = 'Automatically completes the minigame'
	})
	CompleteDelay = AutoFish:CreateTwoSlider({
		Name = 'Complete delay',
		Min = 0,
		Max = 25,
		Decimal = 5,
		DefaultMin = 0.1,
		DefaultMax = 0.9,
		Darker = true
	})
	Cast = AutoFish:CreateToggle({
		Name = 'Auto Cast',
		Function = function(callback)
			if CastDelay.Object then
				CastDelay.Object.Visible = callback
			end
		end,
	    Tooltip = 'Automatically casts ur fishng rod'
	})
	CastDelay = AutoFish:CreateTwoSlider({
		Name = 'Cast delay',
		Min = 0,
		Max = 5,
		Decimal = 5,
		DefaultMin = 0.3,
		DefaultMax = 1.2,
		Darker = true,
		Visible = false
	})
end)

run(function()
	local AutoHotbar
	local Mode
	local Clear
	local List
	local Active
	
	local function CreateWindow(self)
		local selectedslot = 1
		local window = Instance.new('Frame')
		window.Name = 'HotbarGUI'
		window.Size = UDim2.fromOffset(660, 465)
		window.Position = UDim2.fromScale(0.5, 0.5)
		window.BackgroundColor3 = uipallet.Main
		window.AnchorPoint = Vector2.new(0.5, 0.5)
		window.Visible = false
		window.Parent = vape.gui.ScaledGui
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -10, 0, 20)
		title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 12)
		title.BackgroundTransparency = 1
		title.Text = 'AutoHotbar'
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = window
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.fromOffset(0, 40)
		divider.BackgroundColor3 = color.Light(uipallet.Main, 0.04)
		divider.BorderSizePixel = 0
		divider.Parent = window
		addBlur(window)
		local modal = Instance.new('TextButton')
		modal.Text = ''
		modal.BackgroundTransparency = 1
		modal.Modal = true
		modal.Parent = window
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = window
		local close = Instance.new('ImageButton')
		close.Name = 'Close'
		close.Size = UDim2.fromOffset(24, 24)
		close.Position = UDim2.new(1, -35, 0, 9)
		close.BackgroundColor3 = Color3.new(1, 1, 1)
		close.BackgroundTransparency = 1
		close.Image = getcustomasset('catsix/assets/new/close.png')
		close.ImageColor3 = color.Light(uipallet.Text, 0.2)
		close.ImageTransparency = 0.5
		close.AutoButtonColor = false
		close.Parent = window
		close.MouseEnter:Connect(function()
			close.ImageTransparency = 0.3
			tween:Tween(close, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.6
			})
		end)
		close.MouseLeave:Connect(function()
			close.ImageTransparency = 0.5
			tween:Tween(close, TweenInfo.new(0.2), {
				BackgroundTransparency = 1
			})
		end)
		close.MouseButton1Click:Connect(function()
			window.Visible = false
			vape.gui.ScaledGui.ClickGui.Visible = true
		end)
		local closecorner = Instance.new('UICorner')
		closecorner.CornerRadius = UDim.new(1, 0)
		closecorner.Parent = close
		local bigslot = Instance.new('Frame')
		bigslot.Size = UDim2.fromOffset(110, 111)
		bigslot.Position = UDim2.fromOffset(11, 71)
		bigslot.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		bigslot.Parent = window
		local bigslotcorner = Instance.new('UICorner')
		bigslotcorner.CornerRadius = UDim.new(0, 4)
		bigslotcorner.Parent = bigslot
		local bigslotstroke = Instance.new('UIStroke')
		bigslotstroke.Color = color.Light(uipallet.Main, 0.034)
		bigslotstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		bigslotstroke.Parent = bigslot
		local slotnum = Instance.new('TextLabel')
		slotnum.Size = UDim2.fromOffset(80, 20)
		slotnum.Position = UDim2.fromOffset(25, 200)
		slotnum.BackgroundTransparency = 1
		slotnum.Text = 'SLOT 1'
		slotnum.TextColor3 = color.Dark(uipallet.Text, 0.1)
		slotnum.TextSize = 12
		slotnum.FontFace = uipallet.Font
		slotnum.Parent = window
		for i = 1, 9 do
			local slotbkg = Instance.new('TextButton')
			slotbkg.Name = 'Slot'..i
			slotbkg.Size = UDim2.fromOffset(51, 52)
			slotbkg.Position = UDim2.fromOffset(89 + (i * 55), 382)
			slotbkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
			slotbkg.Text = ''
			slotbkg.AutoButtonColor = false
			slotbkg.Parent = window
			local slotimage = Instance.new('ImageLabel')
			slotimage.Size = UDim2.fromOffset(32, 32)
			slotimage.Position = UDim2.new(0.5, -16, 0.5, -16)
			slotimage.BackgroundTransparency = 1
			slotimage.Image = ''
			slotimage.Parent = slotbkg
			local slotcorner = Instance.new('UICorner')
			slotcorner.CornerRadius = UDim.new(0, 4)
			slotcorner.Parent = slotbkg
			local slotstroke = Instance.new('UIStroke')
			slotstroke.Color = color.Light(uipallet.Main, 0.04)
			slotstroke.Thickness = 2
			slotstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			slotstroke.Enabled = i == selectedslot
			slotstroke.Parent = slotbkg
			slotbkg.MouseEnter:Connect(function()
				slotbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
			end)
			slotbkg.MouseLeave:Connect(function()
				slotbkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
			end)
			slotbkg.MouseButton1Click:Connect(function()
				window['Slot'..selectedslot].UIStroke.Enabled = false
				selectedslot = i
				slotstroke.Enabled = true
				slotnum.Text = 'SLOT '..selectedslot
			end)
			slotbkg.MouseButton2Click:Connect(function()
				local obj = self.Hotbars[self.Selected]
				if obj then
					window['Slot'..i].ImageLabel.Image = ''
					obj.Hotbar[tostring(i)] = nil
					obj.Object['Slot'..i].Image = '	'
				end
			end)
		end
		local searchbkg = Instance.new('Frame')
		searchbkg.Size = UDim2.fromOffset(496, 31)
		searchbkg.Position = UDim2.fromOffset(142, 80)
		searchbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		searchbkg.Parent = window
		local search = Instance.new('TextBox')
		search.Size = UDim2.new(1, -10, 0, 31)
		search.Position = UDim2.fromOffset(10, 0)
		search.BackgroundTransparency = 1
		search.Text = ''
		search.PlaceholderText = ''
		search.TextXAlignment = Enum.TextXAlignment.Left
		search.TextColor3 = uipallet.Text
		search.TextSize = 12
		search.FontFace = uipallet.Font
		search.ClearTextOnFocus = false
		search.Parent = searchbkg
		local searchcorner = Instance.new('UICorner')
		searchcorner.CornerRadius = UDim.new(0, 4)
		searchcorner.Parent = searchbkg
		local searchicon = Instance.new('ImageLabel')
		searchicon.Size = UDim2.fromOffset(14, 14)
		searchicon.Position = UDim2.new(1, -26, 0, 8)
		searchicon.BackgroundTransparency = 1
		searchicon.Image = getcustomasset('catsix/assets/new/search.png')
		searchicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
		searchicon.Parent = searchbkg
		local children = Instance.new('ScrollingFrame')
		children.Name = 'Children'
		children.Size = UDim2.fromOffset(500, 240)
		children.Position = UDim2.fromOffset(144, 122)
		children.BackgroundTransparency = 1
		children.BorderSizePixel = 0
		children.ScrollBarThickness = 2
		children.ScrollBarImageTransparency = 0.75
		children.CanvasSize = UDim2.new()
		children.Parent = window
		local windowlist = Instance.new('UIGridLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.FillDirectionMaxCells = 9
		windowlist.CellSize = UDim2.fromOffset(51, 52)
		windowlist.CellPadding = UDim2.fromOffset(4, 3)
		windowlist.Parent = children
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if vape.ThreadFix then
				setthreadidentity(8)
			end
			children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / vape.guiscale.Scale)
		end)
		table.insert(vape.Windows, window)
	
		local function createitem(id, image)
			local slotbkg = Instance.new('TextButton')
			slotbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			slotbkg.Text = ''
			slotbkg.AutoButtonColor = false
			slotbkg.Parent = children
			local slotimage = Instance.new('ImageLabel')
			slotimage.Size = UDim2.fromOffset(32, 32)
			slotimage.Position = UDim2.new(0.5, -16, 0.5, -16)
			slotimage.BackgroundTransparency = 1
			slotimage.Image = image
			slotimage.Parent = slotbkg
			local slotcorner = Instance.new('UICorner')
			slotcorner.CornerRadius = UDim.new(0, 4)
			slotcorner.Parent = slotbkg
			slotbkg.MouseEnter:Connect(function()
				slotbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.04)
			end)
			slotbkg.MouseLeave:Connect(function()
				slotbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			end)
			slotbkg.MouseButton1Click:Connect(function()
				local obj = self.Hotbars[self.Selected]
				if obj then
					window['Slot'..selectedslot].ImageLabel.Image = image
					obj.Hotbar[tostring(selectedslot)] = id
					obj.Object['Slot'..selectedslot].Image = image
				end
			end)
		end
	
		local function indexSearch(text)
			for _, v in children:GetChildren() do
				if v:IsA('TextButton') then
					v:ClearAllChildren()
					v:Destroy()
				end
			end
	
			if text == '' then
				for _, v in {'diamond_sword', 'diamond_pickaxe', 'diamond_axe', 'shears', 'wood_bow', 'wool_white', 'fireball', 'apple', 'iron', 'gold', 'diamond', 'emerald'} do
					createitem(v, bedwars.ItemMeta[v].image)
				end
				return
			end
	
			for i, v in bedwars.ItemMeta do
				if text:lower() == i:lower():sub(1, text:len()) then
					if not v.image then continue end
					createitem(i, v.image)
				end
			end
		end
	
		search:GetPropertyChangedSignal('Text'):Connect(function()
			indexSearch(search.Text)
		end)
		indexSearch('')
	
		return window
	end
	
	vape.Components.HotbarList = function(optionsettings, children, api)
		if vape.ThreadFix then
			setthreadidentity(8)
		end
		local optionapi = {
			Type = 'HotbarList',
			Hotbars = {},
			Selected = 1
		}
		local hotbarlist = Instance.new('TextButton')
		hotbarlist.Name = 'HotbarList'
		hotbarlist.Size = UDim2.fromOffset(220, 40)
		hotbarlist.BackgroundColor3 = optionsettings.Darker and (children.BackgroundColor3 == color.Dark(uipallet.Main, 0.02) and color.Dark(uipallet.Main, 0.04) or color.Dark(uipallet.Main, 0.02)) or children.BackgroundColor3
		hotbarlist.Text = ''
		hotbarlist.BorderSizePixel = 0
		hotbarlist.AutoButtonColor = false
		hotbarlist.Parent = children
		local textbkg = Instance.new('Frame')
		textbkg.Name = 'BKG'
		textbkg.Size = UDim2.new(1, -20, 0, 31)
		textbkg.Position = UDim2.fromOffset(10, 4)
		textbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		textbkg.Parent = hotbarlist
		local textbkgcorner = Instance.new('UICorner')
		textbkgcorner.CornerRadius = UDim.new(0, 4)
		textbkgcorner.Parent = textbkg
		local textbutton = Instance.new('TextButton')
		textbutton.Name = 'HotbarList'
		textbutton.Size = UDim2.new(1, -2, 1, -2)
		textbutton.Position = UDim2.fromOffset(1, 1)
		textbutton.BackgroundColor3 = uipallet.Main
		textbutton.Text = ''
		textbutton.AutoButtonColor = false
		textbutton.Parent = textbkg
		textbutton.MouseEnter:Connect(function()
			tween:Tween(textbkg, TweenInfo.new(0.2), {
				BackgroundColor3 = color.Light(uipallet.Main, 0.14)
			})
		end)
		textbutton.MouseLeave:Connect(function()
			tween:Tween(textbkg, TweenInfo.new(0.2), {
				BackgroundColor3 = color.Light(uipallet.Main, 0.034)
			})
		end)
		local textbuttoncorner = Instance.new('UICorner')
		textbuttoncorner.CornerRadius = UDim.new(0, 4)
		textbuttoncorner.Parent = textbutton
		local textbuttonicon = Instance.new('ImageLabel')
		textbuttonicon.Size = UDim2.fromOffset(12, 12)
		textbuttonicon.Position = UDim2.fromScale(0.5, 0.5)
		textbuttonicon.AnchorPoint = Vector2.new(0.5, 0.5)
		textbuttonicon.BackgroundTransparency = 1
		textbuttonicon.Image = getcustomasset('catsix/assets/new/add.png')
		textbuttonicon.ImageColor3 = Color3.fromHSV(0.46, 0.96, 0.52)
		textbuttonicon.Parent = textbutton
		local childrenlist = Instance.new('Frame')
		childrenlist.Size = UDim2.new(1, 0, 1, -40)
		childrenlist.Position = UDim2.fromOffset(0, 40)
		childrenlist.BackgroundTransparency = 1
		childrenlist.Parent = hotbarlist
		local windowlist = Instance.new('UIListLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		windowlist.Padding = UDim.new(0, 3)
		windowlist.Parent = childrenlist
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if vape.ThreadFix then
				setthreadidentity(8)
			end
			hotbarlist.Size = UDim2.fromOffset(220, math.min(43 + windowlist.AbsoluteContentSize.Y / vape.guiscale.Scale, 603))
		end)
		textbutton.MouseButton1Click:Connect(function()
			optionapi:AddHotbar()
		end)
		optionapi.Window = CreateWindow(optionapi)
	
		function optionapi:Save(savetab)
			local hotbars = {}
			for _, v in self.Hotbars do
				table.insert(hotbars, v.Hotbar)
			end
			savetab.HotbarList = {
				Selected = self.Selected,
				Hotbars = hotbars
			}
		end
	
		function optionapi:Load(savetab)
			for _, v in self.Hotbars do
				v.Object:ClearAllChildren()
				v.Object:Destroy()
				table.clear(v.Hotbar)
			end
			table.clear(self.Hotbars)
			for _, v in savetab.Hotbars do
				self:AddHotbar(v)
			end
			self.Selected = savetab.Selected or 1
		end
	
		function optionapi:AddHotbar(data)
			local hotbardata = {Hotbar = data or {}}
			table.insert(self.Hotbars, hotbardata)
			local hotbar = Instance.new('TextButton')
			hotbar.Size = UDim2.fromOffset(200, 27)
			hotbar.BackgroundColor3 = table.find(self.Hotbars, hotbardata) == self.Selected and color.Light(uipallet.Main, 0.034) or uipallet.Main
			hotbar.Text = ''
			hotbar.AutoButtonColor = false
			hotbar.Parent = childrenlist
			hotbardata.Object = hotbar
			local hotbarcorner = Instance.new('UICorner')
			hotbarcorner.CornerRadius = UDim.new(0, 4)
			hotbarcorner.Parent = hotbar
			for i = 1, 9 do
				local slot = Instance.new('ImageLabel')
				slot.Name = 'Slot'..i
				slot.Size = UDim2.fromOffset(17, 18)
				slot.Position = UDim2.fromOffset(-7 + (i * 18), 5)
				slot.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
				slot.Image = hotbardata.Hotbar[tostring(i)] and bedwars.getIcon({itemType = hotbardata.Hotbar[tostring(i)]}, true) or ''
				slot.BorderSizePixel = 0
				slot.Parent = hotbar
			end
			hotbar.MouseButton1Click:Connect(function()
				local ind = table.find(optionapi.Hotbars, hotbardata)
				if ind == optionapi.Selected then
					vape.gui.ScaledGui.ClickGui.Visible = false
					optionapi.Window.Visible = true
					for i = 1, 9 do
						optionapi.Window['Slot'..i].ImageLabel.Image = hotbardata.Hotbar[tostring(i)] and bedwars.getIcon({itemType = hotbardata.Hotbar[tostring(i)]}, true) or ''
					end
				else
					if optionapi.Hotbars[optionapi.Selected] then
						optionapi.Hotbars[optionapi.Selected].Object.BackgroundColor3 = uipallet.Main
					end
					hotbar.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
					optionapi.Selected = ind
				end
			end)
			local close = Instance.new('ImageButton')
			close.Name = 'Close'
			close.Size = UDim2.fromOffset(16, 16)
			close.Position = UDim2.new(1, -23, 0, 6)
			close.BackgroundColor3 = Color3.new(1, 1, 1)
			close.BackgroundTransparency = 1
			close.Image = getcustomasset('catsix/assets/new/closemini.png')
			close.ImageColor3 = color.Light(uipallet.Text, 0.2)
			close.ImageTransparency = 0.5
			close.AutoButtonColor = false
			close.Parent = hotbar
			local closecorner = Instance.new('UICorner')
			closecorner.CornerRadius = UDim.new(1, 0)
			closecorner.Parent = close
			close.MouseEnter:Connect(function()
				close.ImageTransparency = 0.3
				tween:Tween(close, TweenInfo.new(0.2), {
					BackgroundTransparency = 0.6
				})
			end)
			close.MouseLeave:Connect(function()
				close.ImageTransparency = 0.5
				tween:Tween(close, TweenInfo.new(0.2), {
					BackgroundTransparency = 1
				})
			end)
			close.MouseButton1Click:Connect(function()
				local ind = table.find(self.Hotbars, hotbardata)
				local obj = self.Hotbars[self.Selected]
				local obj2 = self.Hotbars[ind]
				if obj and obj2 then
					obj2.Object:ClearAllChildren()
					obj2.Object:Destroy()
					table.remove(self.Hotbars, ind)
					ind = table.find(self.Hotbars, obj)
					self.Selected = table.find(self.Hotbars, obj) or 1
				end
			end)
		end
	
		api.Options.HotbarList = optionapi
	
		return optionapi
	end
	
	local function getBlock()
		local clone = table.clone(store.inventory.inventory.items)
		table.sort(clone, function(a, b)
			return a.amount < b.amount
		end)
	
		for _, item in clone do
			local block = bedwars.ItemMeta[item.itemType].block
			if block and not block.seeThrough then
				return item
			end
		end
	end
	
	local function getCustomItem(v)
		if v == 'diamond_sword' then
			local sword = store.tools.sword
			v = sword and sword.itemType or 'wood_sword'
		elseif v == 'diamond_pickaxe' then
			local pickaxe = store.tools.stone
			v = pickaxe and pickaxe.itemType or 'wood_pickaxe'
		elseif v == 'diamond_axe' then
			local axe = store.tools.wood
			v = axe and axe.itemType or 'wood_axe'
		elseif v == 'wood_bow' then
			local bow = getBow()
			v = bow and bow.itemType or 'wood_bow'
		elseif v == 'wool_white' then
			local block = getBlock()
			v = block and block.itemType or 'wool_white'
		end
	
		return v
	end
	
	local function findItemInTable(tab, item)
		for slot, v in tab do
			if item.itemType == getCustomItem(v) then
				return tonumber(slot)
			end
		end
	end
	
	local function findInHotbar(item)
		for i, v in store.inventory.hotbar do
			if v.item and v.item.itemType == item.itemType then
				return i - 1, v.item
			end
		end
	end
	
	local function findInInventory(item)
		for _, v in store.inventory.inventory.items do
			if v.itemType == item.itemType then
				return v
			end
		end
	end
	
	local function dispatch(...)
		bedwars.Store:dispatch(...)
		vapeEvents.InventoryChanged.Event:Wait()
	end
	
	local function sortCallback()
		if Active then return end
		Active = true
		local items = (List.Hotbars[List.Selected] and List.Hotbars[List.Selected].Hotbar or {})
	
		for _, v in store.inventory.inventory.items do
			local slot = findItemInTable(items, v)
			if slot then
				local olditem = store.inventory.hotbar[slot]
				if olditem.item and olditem.item.itemType == v.itemType then continue end
				if olditem.item then
					dispatch({
						type = 'InventoryRemoveFromHotbar',
						slot = slot - 1
					})
				end
	
				local newslot = findInHotbar(v)
				if newslot then
					dispatch({
						type = 'InventoryRemoveFromHotbar',
						slot = newslot
					})
					if olditem.item then
						dispatch({
							type = 'InventoryAddToHotbar',
							item = findInInventory(olditem.item),
							slot = newslot
						})
					end
				end
	
				dispatch({
					type = 'InventoryAddToHotbar',
					item = findInInventory(v),
					slot = slot - 1
				})
			elseif Clear.Enabled then
				local newslot = findInHotbar(v)
				if newslot then
				   	dispatch({
						type = 'InventoryRemoveFromHotbar',
						slot = newslot
					})
				end
			end
		end
	
		Active = false
	end
	
	AutoHotbar = vape.Categories.Inventory:CreateModule({
		Name = 'AutoHotbar',
		Function = function(callback)
			if callback then
				task.spawn(sortCallback)
				if Mode.Value == 'On Key' then
					AutoHotbar:Toggle()
					return
				end
	
				AutoHotbar:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(sortCallback))
			end
		end,
		Tooltip = 'Automatically arranges hotbar to your liking.'
	})
	Mode = AutoHotbar:CreateDropdown({
		Name = 'Activation',
		List = {'Toggle', 'On Key'},
		Function = function()
			if AutoHotbar.Enabled then
				AutoHotbar:Toggle()
				AutoHotbar:Toggle()
			end
		end
	})
	Clear = AutoHotbar:CreateToggle({Name = 'Clear Hotbar'})
	List = AutoHotbar:CreateHotbarList({})
end)

run(function()
	local Value
	local oldclickhold, oldshowprogress
	
	local FastConsume = vape.Categories.Inventory:CreateModule({
		Name = 'FastConsume',
		Function = function(callback)
			if callback then
				oldclickhold = bedwars.ClickHold.startClick
				oldshowprogress = bedwars.ClickHold.showProgress
				bedwars.ClickHold.startClick = function(self)
					self.startedClickTime = tick()
					local handle = self:showProgress()
					local clicktime = self.startedClickTime
					bedwars.RuntimeLib.Promise.defer(function()
						task.wait(self.durationSeconds * (Value.Value / 40))
						if handle == self.handle and clicktime == self.startedClickTime and self.closeOnComplete then
							self:hideProgress()
							if self.onComplete then self.onComplete() end
							if self.onPartialComplete then self.onPartialComplete(1) end
							self.startedClickTime = -1
						end
					end)
				end
	
				bedwars.ClickHold.showProgress = function(self)
					local roact = debug.getupvalue(oldshowprogress, 1)
					local countdown = roact.mount(roact.createElement('ScreenGui', {}, { roact.createElement('Frame', {
						[roact.Ref] = self.wrapperRef,
						Size = UDim2.new(),
						Position = UDim2.fromScale(0.5, 0.55),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.8
					}, { roact.createElement('Frame', {
						[roact.Ref] = self.progressRef,
						Size = UDim2.fromScale(0, 1),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BackgroundTransparency = 0.5
					}) }) }), lplr:FindFirstChild('PlayerGui'))
	
					self.handle = countdown
					local sizetween = tweenService:Create(self.wrapperRef:getValue(), TweenInfo.new(0.1), {
						Size = UDim2.fromScale(0.11, 0.005)
					})
					local countdowntween = tweenService:Create(self.progressRef:getValue(), TweenInfo.new(self.durationSeconds * (Value.Value / 100), Enum.EasingStyle.Linear), {
						Size = UDim2.fromScale(1, 1)
					})
	
					sizetween:Play()
					countdowntween:Play()
					table.insert(self.tweens, countdowntween)
					table.insert(self.tweens, sizetween)
					
					return countdown
				end
			else
				bedwars.ClickHold.startClick = oldclickhold
				bedwars.ClickHold.showProgress = oldshowprogress
				oldclickhold = nil
				oldshowprogress = nil
			end
		end,
		Tooltip = 'Use/Consume items quicker.'
	})
	Value = FastConsume:CreateSlider({
		Name = 'Multiplier',
		Min = 0,
		Max = 100
	})
end)

run(function()
	local FastDrop
	
	FastDrop = vape.Categories.Inventory:CreateModule({
		Name = 'FastDrop',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive and (not store.inventory.opened) and (inputService:IsKeyDown(Enum.KeyCode.H) or inputService:IsKeyDown(Enum.KeyCode.Backspace)) and inputService:GetFocusedTextBox() == nil then
						task.spawn(bedwars.ItemDropController.dropItemInHand)
						task.wait()
					else
						task.wait(0.1)
					end
				until not FastDrop.Enabled
			end
		end,
		Tooltip = 'Drops items fast when you hold Q'
	})
end)

run(function()
	local AutoAdetunde
	
	AutoAdetunde = vape.Categories.Minigames:CreateModule({
		Name = 'AutoAdetunde',
		Function = function(callback)
			if callback then
				repeat
					local crystal = getItem('frost_crystal')
					if crystal then
						for i, v in bedwars.AdetundeUtil.getUpgradesFromHammer(lplr) do
							local new = getItem('frost_crystal')
							if not new then
								break
							end
	
							crystal = new
	
							local nextUpgrade = AutoAdetunde.Options['Buy ' .. i].Enabled and bedwars.AdetundeUpgradeMeta[i].tiers[v + 1] or nil
							if nextUpgrade then
								if crystal.amount >= nextUpgrade.price then
									bedwars.Handler:Get('UpgradeFrostyHammer'):Fire('CallServer', i)
									task.wait(0.1)
								end
							end
						end
					end
					task.wait(0.5)
				until not AutoAdetunde.Enabled
			end
		end,
		Tooltip = 'Automatically upgrades ur frosty hammer'
	})
	
	for i in bedwars.AdetundeUpgradeMeta do
		AutoAdetunde:CreateToggle({
			Name = 'Buy ' .. i,
			Default = true,
		})
	end
end)

run(function()
	local AutoBuilder
	local Animation
	local Blacklist
	local BedCheck
	local Limit
	
	local function getBedNear(pos)
		local bed, lastmag = nil, math.huge
		local localPosition = pos or Vector3.zero
		for _, v in collectionService:GetTagged('bed') do
			local mag = (localPosition - v.Position).Magnitude
			if mag < lastmag and v:GetAttribute('Team' .. (lplr:GetAttribute('Team') or -1) .. 'NoBreak') then
				bed = v
				lastmag = mag
			end
		end
		return bed, lastmag
	end
	
	AutoBuilder = vape.Categories.Minigames:CreateModule({
		Name = 'AutoBuilder',
		Function = function(callback)
			if callback then
				repeat
					task.wait()
				until store.matchState ~= 0 and store.equippedKit == 'builder' or not AutoBuilder.Enabled
				if not AutoBuilder.Enabled then
					return
				end
	
				local bed = getBedNear(entitylib.character.RootPart.Position)
				local blocks = collection('block', AutoBuilder, function(tab, obj)
					task.delay(0, function()
						if obj and not obj:GetAttribute('NoBreak') and obj:GetAttribute('PlacedByUserId') ~= nil then
							table.insert(tab, obj)
						end
					end)
				end)
				repeat
					if entitylib.isAlive and (not Limit.Enabled and getItem('hammer') or Limit.Enabled and store.hand.tool and store.hand.tool.Name == 'hammer') then
						bed = getBedNear(entitylib.character.RootPart.Position)
	
						for _, v in blocks do
							if not BedCheck.Enabled or (bed.Position - v.Position).Magnitude <= 30 then
								local name = v.Name
								if name:find('wool_') then
									name = 'wool'
								end
								if not table.find(Blacklist.ListEnabled, name) and not v:FindFirstChild('BuilderFortify') then
									bedwars.Handler:Get('FortifyBlock'):Fire('SendToServer', ({getPlacedBlock(v.Position)})[2])
									if Animation.Enabled then
										bedwars.GameAnimationUtil:playAnimation(lplr, bedwars.GameAnimationUtil:getAssetId(bedwars.AnimationType.BUILDER_HAMMER_HIT), {
											fadeInTime = 0.02
										})
										bedwars.SoundManager:playSound(bedwars.SoundList.FORTIFY_BLOCK,lplr.Character.HumanoidRootPart.Position)
									end
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoBuilder.Enabled
			end
		end
	})
	
	BedCheck = AutoBuilder:CreateToggle({
		Name = 'Bed Check',
		Tooltip = 'Checks if the block is near your bed'
	})
	Animation = AutoBuilder:CreateToggle({
		Name = 'Animation',
		Default = true,
		Tooltip = 'Plays builder visuals (sfx and anim)'
	})
	Limit = AutoBuilder:CreateToggle({
		Name = 'Limit to items',
		Default = true
	})
	Blacklist = AutoBuilder:CreateTextList({
		Name = 'Blacklists',
		Placeholder = 'block',
		Default = {'cannon', 'wool'}
	})
end)

run(function()
	local AutoCaitlyn
	local Mode
	local Range
	local MinHP
	local TargetPriorities
	local activeSession
	
	local function getEntity(value)
		return typeof(value) == 'Instance' and entitylib.getEntity(value) or nil
	end
	
	local function getContract(contracts, ent)
		for _, v in contracts do
			if v.target == ent.Player or v.target and v.target.Name == ent.Player.Name then
				return v
			end
		end
		return nil
	end
	
	local function getValidTargets(wallcheck)
		local targets = {}
		for _, ent in entitylib.AllPosition({
			Part = 'RootPart',
			Players = true,
			Range = Range.Value,
			Wallcheck = wallcheck
		}) do
			if not (ent.Player.Team and ent.Player.Team.Name == 'Spectators') then
				targets[ent.Player] = ent
				targets[ent.Character] = ent
			end
		end
		return targets
	end
	
	local function hasBed(session, plr)
		local suc, team = pcall(bedwars.TeamController.getPlayerTeam, bedwars.TeamController, plr)
		local teamId = suc and team and team.id or plr:GetAttribute('Team')
		if teamId == nil then
			return true
		end
	
		local cached = session.beds[teamId]
		if cached and cached[2] > tick() then
			return cached[1]
		end
	
		suc, team = pcall(bedwars.BedwarsController.getTeamBed, bedwars.BedwarsController, teamId)
		local result = not suc or team and team.Parent ~= nil
		session.beds[teamId] = {result, tick() + 1}
		return result
	end
	
	local function getScore(session, contract, targets)
		local ent = targets[contract.target]
		if not ent then
			return nil
		end
	
		local health = ent.Humanoid.Health
		local distance = (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude
		local score = 30 + ((tonumber(contract.rewardValue) or 0) * 35)
		score += (1 - math.clamp(health / math.max(ent.Humanoid.MaxHealth, 1), 0, 1)) * 35
		score += math.max(1 - (distance / Range.Value), 0) * 20
	
		if health <= MinHP.Value then
			score += 20
		end
		if (session.threats[ent.Player] or 0) > tick() then
			score += 30
		end
		if ent.Character:GetAttribute('BleedSource') == lplr.UserId then
			score += 25
		end
		if not hasBed(session, ent.Player) then
			score += 20
		end
	
		local reward = contract.rewardExplanation
		if type(reward) == 'table' then
			score += (reward.assassin and 10 or 0) + (reward.kitClass and 8 or 0) + (reward.gear and 6 or 0)
		end
		return score, ent
	end
	
	local function getPriorityContract(session, contracts)
		local bounty = false
		for _, v in contracts do
			if v.rewardValue ~= nil or v.rewardUpgrade ~= nil then
				bounty = true
				break
			end
		end
		if not bounty then
			return nil, false
		end
	
		local targets = getValidTargets(true)
		local current, currentScore
		if session.priorityId ~= nil then
			for _, v in contracts do
				if v.id == session.priorityId then
					current, currentScore = v, getScore(session, v, targets)
					break
				end
			end
		end
	
		local best, bestScore
		for _, v in contracts do
			local score = getScore(session, v, targets)
			if score and (not bestScore or score > bestScore) then
				best, bestScore = v, score
			end
		end
	
		if current and currentScore and best ~= current and bestScore < currentScore + 15 then
			best = current
		end
	
		session.priorityId = best and best.id or nil
		return best, true
	end
	
	local function getNormalContract(session, contracts)
		local hit = session.lastHit
		if hit and hit[2] > tick() then
			local ent = getValidTargets(false)[hit[1].Player]
			if ent == hit[1] then
				if Mode.Value == 'On Low' and ent.Humanoid.Health >= MinHP.Value then
					return nil
				end
				return getContract(contracts, ent)
			end
		end
	
		session.lastHit = nil
		return nil
	end
	
	local function selectContract(session, contract)
		if contract and not (session.pendingId == contract.id and session.pendingUntil > tick()) then
			bedwars.Handler:Get('BloodAssassinSelectContract'):Fire('SendToServer', {
				contractId = contract.id
			})
			session.pendingId = contract.id
			session.pendingUntil = tick() + 1
		end
	end
	
	local function updateCaitlyn(session)
		if not entitylib.isAlive or store.matchState ~= 1 or store.equippedKit ~= 'blood_assassin' then
			session.lastHit = nil
			session.pendingId = nil
			session.priorityId = nil
			return
		end
	
		local kit = bedwars.Store:getState().Kit
		if not kit or kit.activeContract then
			session.pendingId = nil
			session.priorityId = kit and kit.activeContract and kit.activeContract.id or nil
			return
		end
	
		if session.pendingId and session.pendingUntil > tick() then
			return
		end
		session.pendingId = nil
	
		local contracts = kit.availableContracts
		if not contracts or #contracts == 0 then
			return
		end
	
		local contract
		if TargetPriorities.Enabled then
			local available
			contract, available = getPriorityContract(session, contracts)
			if not available then
				contract = getNormalContract(session, contracts)
			end
		else
			session.priorityId = nil
			contract = getNormalContract(session, contracts)
		end
		selectContract(session, contract)
	end
	
	AutoCaitlyn = vape.Categories.Minigames:CreateModule({
		Name = 'AutoCaitlyn',
		Function = function(callback)
			if callback then
				local session = {
					beds = {},
					nextUpdate = 0,
					pendingUntil = 0,
					threats = {}
				}
				activeSession = session
	
				AutoCaitlyn:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if activeSession ~= session then
						return
					end
	
					local source = getEntity(damageTable.fromEntity)
					if damageTable.entityInstance == lplr.Character and source and source.Player then
						session.threats[source.Player] = tick() + 3
					elseif damageTable.fromEntity == lplr.Character or damageTable.fromEntity == lplr then
						local victim = getEntity(damageTable.entityInstance)
						if victim then
							session.lastHit = {victim, tick() + 1}
						end
					end
				end))
	
				AutoCaitlyn:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function()
					table.clear(session.beds)
				end))
	
				AutoCaitlyn:Clean(entitylib.Events.LocalAdded:Connect(function()
					session.lastHit = nil
					session.pendingId = nil
				end))
	
				AutoCaitlyn:Clean(entitylib.Events.LocalRemoved:Connect(function()
					session.lastHit = nil
					session.pendingId = nil
					session.priorityId = nil
				end))
	
				repeat
					if tick() >= session.nextUpdate then
						session.nextUpdate = tick() + 0.2
						updateCaitlyn(session)
					end
					task.wait(0.05)
				until not AutoCaitlyn.Enabled or activeSession ~= session
	
				if activeSession == session then
					activeSession = nil
				end
			else
				activeSession = nil
			end
		end,
		Tooltip = 'Automatically assigns a player\'s contract when a specific action happens'
	})
	
	Mode = AutoCaitlyn:CreateDropdown({
		Name = 'Contract mode',
		List = {'On Hit', 'On Low'},
		Tooltip = 'On Hit - Contracts them whenever u start hitting them\nOn Low - When they\'re low',
		Function = function(val)
			if MinHP then
				MinHP.Object.Visible = val == 'On Low'
			end
		end,
		Default = 'On Low'
	})
	MinHP = AutoCaitlyn:CreateSlider({
		Name = 'Minimum Health',
		Tooltip = 'How low they have to be before contracting',
		Min = 1,
		Max = 100,
		Default = 30,
		Darker = true,
		Visible = false
	})
	Range = AutoCaitlyn:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 50,
		Default = 50,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	TargetPriorities = AutoCaitlyn:CreateToggle({
		Name = 'Target Priorities',
		Function = function()
			if activeSession then
				activeSession.priorityId = nil
			end
		end
	})
end)

run(function()
	local AutoElder
	local Streamer
	local Range
	local Animation
	local Delay
	
	local Legit = getFunctionRange(bedwars.EldertreeController.createTreeOrbInteraction) or 10
	
	AutoElder = vape.Categories.Minigames:CreateModule({
		Name = 'AutoElder',
		Function = function(call)
			if call then
				AutoElder:Clean(proximityPromptService.PromptShown:Connect(function(prompt)
					if Streamer.Enabled and prompt.Name == 'treeOrb' then
						task.delay(0.1, prompt.InputHoldBegin, prompt)
					end
				end))
	
				repeat
					if not Streamer.Enabled and entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						for i, v in collectionService:GetTagged('treeOrb') do
							if tick() > (Delay[v] or 0) and (localPosition - v.Spirit.Position).Magnitude <= Range.Value then
								if Delay.Value > 0 then
									task.wait(Delay.Value)
								end
	
								if (localPosition - v.Spirit.Position).Magnitude <= Range.Value then
									if Animation.Enabled then
										bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.PUNCH)
										bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
										bedwars.SoundManager:playSound(bedwars.SoundList.CROP_HARVEST)
									end
									if bedwars.Handler:Get('ConsumeTreeOrb'):Fire('CallServer', {treeOrbSecret = v:GetAttribute('TreeOrbSecret')}) then
										v:Destroy()
									end
									Delay[v] = tick() + 1
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoElder.Enabled
			end
		end,
		Tooltip = 'Automatically collects tree orbs'
	})
	
	Streamer = AutoElder:CreateToggle({
		Name = 'Streamer mode',
		Tooltip = 'Useful for when ur screensharing',
		Function = function(call)
			pcall(function()
				Delay.Object.Visible = not call
				Range.Object.Visible = not call
				Animation.Object.Visible = not call
			end)
		end
	})
	Animation = AutoElder:CreateToggle({
		Name = 'Animation',
		Default = true,
		Tooltip = 'Plays the collect animation'
	})
	Range = AutoElder:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 20,
		Default = 12,
		Suffix = function(val)
			return val > 1 and 'studs' or 'stud'
		end
	})
	AutoElder:CreateButton({
		Name = 'Sync to legit range',
		Function = function()
			Range:SetValue(Legit)
		end
	})
	Delay = AutoElder:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 1,
		Suffix = function(val)
			return val > 1 and 'secs' or 'sec'
		end,
		Default = 0.2,
		Decimal = 100
	})
end)

run(function()
	local AutoEmber
	local Targets
	local Range
	local Delay
	local Limit
	
	AutoEmber = vape.Categories.Minigames:CreateModule({
		Name = 'AutoEmber',
		Function = function(call)
			if call then
				local clock = os.clock()
				repeat
					if entitylib.isAlive then
						local tool = getItem('infernal_saber')
						if tool and (not Limit.Enabled or store.hand.tool and store.hand.tool == tool) and entitylib.EntityPosition({
							Range = Range.Value,
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
						}) then
							if Delay.Value <= 0 or (os.clock() - clock) >= Delay.Value then
								bedwars.Handler:Get('HellBladeRelease'):Fire('SendToServer', {
									chargeTime = 1,
									weapon = tool,
									player = lplr,
								})
								clock = os.clock()
							end
						end
					end
					task.wait()
				until not AutoEmber.Enabled
			end
		end
	})
	
	Targets = AutoEmber:CreateTargets({
		Players = true,
		NPCs = false
	})
	Delay = AutoEmber:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 1,
		Default = 0.1,
		Decimal = 100
	})
	Range = AutoEmber:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 22,
		Default = 22,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	Limit = AutoEmber:CreateToggle({Name = 'Limit to item'})
	
end)

run(function()
	local AutoGingerbread
	local Range
	local Delay
	local Break
	local Jump
	local Switch
	local OwnOnly
	local SuccessfulOnly
	
	local old
	local hook
	
	local function canUseBlock(block)
		if not entitylib.isAlive or typeof(block) ~= 'Instance' or not block:IsA('BasePart') then
			return false
		end
	
		if store.equippedKit ~= 'gingerbread_man' then
			return false
		end
	
		if OwnOnly.Enabled and block:GetAttribute('PlacedByUserId') ~= lplr.UserId then
			return false
		end
	
		return (block.Position - entitylib.character.RootPart.Position).Magnitude <= Range.Value
	end
	
	AutoGingerbread = vape.Categories.Minigames:CreateModule({
		Name = 'AutoGingerbreadMan',
		Function = function(callback)
			if callback then
				local original = bedwars.LaunchPadController.attemptLaunch
				old = original
				hook = function(...)
					local controller, block = ...
					local lastLaunch = controller and controller.lastLaunch or 0
	
					if AutoGingerbread.Enabled and (not SuccessfulOnly.Enabled or (controller and controller.lastLaunch and (controller.lastLaunch ~= lastLaunch or workspace:GetServerTimeNow() - controller.lastLaunch < 0.5))) then
						if Break.Enabled and canUseBlock(block) then
							task.delay(Delay.Value, function()
								if AutoGingerbread.Enabled and block.Parent then
									bedwars.breakBlock(block, false, nil, true, nil, Switch.Enabled)
								end
							end)
						end
	
						if Jump.Enabled and entitylib.isAlive then
							lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
						end
					end
	
					return original(...)
				end
				bedwars.LaunchPadController.attemptLaunch = hook
			elseif old then
				if bedwars.LaunchPadController.attemptLaunch == hook then
					bedwars.LaunchPadController.attemptLaunch = old
				end
				old = nil
				hook = nil
			end
		end,
		Tooltip = 'Automatically handles Gingerbread Man launch pads.'
	})
	
	Break = AutoGingerbread:CreateToggle({
		Name = 'Break launch pad',
		Default = true,
		Function = function(call)
			pcall(function()
				Range.Object.Visible = call
				Delay.Object.Visible = call
				Switch.Object.Visible = call
				OwnOnly.Object.Visible = call
			end)
		end
	})
	Jump = AutoGingerbread:CreateToggle({Name = 'Jump after launch'})
	Switch = AutoGingerbread:CreateToggle({
		Name = 'Legit switch',
		Darker = true
	})
	OwnOnly = AutoGingerbread:CreateToggle({
		Name = 'Own pads only',
		Default = true,
		Darker = true
	})
	SuccessfulOnly = AutoGingerbread:CreateToggle({
		Name = 'Successful launch only',
		Default = true
	})
	Range = AutoGingerbread:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 30,
		Default = 30,
		Darker = true,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	Delay = AutoGingerbread:CreateSlider({
		Name = 'Break delay',
		Min = 0,
		Max = 1,
		Default = 0.05,
		Decimal = 100,
		Darker = true,
		Suffix = function(val)
			return val == 1 and 'sec' or 'secs'
		end
	})
	
end)

run(function()
	local AutoHannah
	local Range
	
	AutoHannah = vape.Categories.Minigames:CreateModule({
		Name = 'AutoHannah',
		Function = function(callback)
			if callback then
				local objs = collection('HannahExecuteInteraction', AutoHannah)
				repeat
					if entitylib.isAlive and store.equippedKit == 'hannah' then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in objs do
							if not AutoHannah.Enabled then
								break
							end
	
							local part = not v:IsA('Model') and v or v.PrimaryPart
							if part and (part.Position - localPosition).Magnitude <= Range.Value then
								local billboard = bedwars.Handler:Get('HannahPromptTrigger'):Fire('CallServer', {
									user = lplr,
									victimEntity = v,
								}) and v:FindFirstChild('Hannah Execution Icon')
	
								if billboard then
									billboard:Destroy()
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoHannah.Enabled
			end
		end,
		Tooltip = 'Automatically executes low health players with Hannah.'
	})
	
	AutoHannah:CreateTargets({Players = true}) -- cosmetic settings lmao
	Range = AutoHannah:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 30,
		Default = 30,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	AutoHannah:CreateDropdown({
		Name = 'Target mode', 
		List = methods,
		Default = 'Health'
	})
	AutoHannah:CreateToggle({
		Name = 'Only killaura target',
		Tooltip = 'Only executes targets that are being attacked by killaura'
	})
end)

run(function()
	local AutoHephaestus
	local lastRepair = 0
	
	AutoHephaestus = vape.Categories.Minigames:CreateModule({
		Name = 'AutoHephaestus',
		Function = function(callback)
			if callback then
				AutoHephaestus:Clean(runService.Heartbeat:Connect(function()
					if tick() >= lastRepair and store.equippedKit == 'tinker' and bedwars.TinkerKitController.mounted and bedwars.AbilityController:canUseAbility('tinker_self_repair') and (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 1 then
						lastRepair = tick() + 0.5
						bedwars.AbilityController:useAbility('tinker_self_repair')
					end
				end))
			end
		end,
		Tooltip = 'Automatically repairs your Tinker machine whenever the self repair ability is available'
	})
	
end)

run(function()
	local AutoKaliyah
	local Range
	local Delay
	local NoSlow
	
	local Legit = getFunctionRange(bedwars.DragonSlayerController.onKitLocalActivated) or 14.4
	local modifier, oldAddModifier, newAddModifier
	local noSlowUntil = 0
	
	local function hookModifier()
		if newAddModifier then return end
		modifier = bedwars.SprintController:getMovementStatusModifier()
		oldAddModifier = modifier and modifier.addModifier
		if typeof(oldAddModifier) ~= 'function' then
			modifier, oldAddModifier = nil, nil
			return
		end
		newAddModifier = function(self, tab)
			if AutoKaliyah.Enabled and NoSlow.Enabled and tick() < noSlowUntil and type(tab) == 'table' and tab.moveSpeedMultiplier == 0 then
				tab.moveSpeedMultiplier = 1
			end
			return oldAddModifier(self, tab)
		end
		modifier.addModifier = newAddModifier
		AutoKaliyah:Clean(function()
			if modifier and modifier.addModifier == newAddModifier then
				modifier.addModifier = oldAddModifier
			end
			modifier, oldAddModifier, newAddModifier = nil, nil, nil
			noSlowUntil = 0
		end)
	end
	
	local function func(v)
		if NoSlow.Enabled then
			hookModifier()
			noSlowUntil = math.max(noSlowUntil, tick() + Delay.Value + 0.1)
		end
	
		task.wait(Delay.Value)
		bedwars.DragonSlayerController:deleteEmblem(v)
		bedwars.DragonSlayerController:playPunchAnimation(Vector3.zero)
	
		bedwars.Handler:Get('RequestDragonPunch'):Fire('SendToServer', {
			target = v
		})
	end
	
	AutoKaliyah = vape.Categories.Minigames:CreateModule({
		Name = 'AutoKaliyah',
		Function = function(call)
			if call then
				local objs = collection('KaliyahPunchInteraction', AutoKaliyah)
	
				repeat
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in objs do
							if not AutoKaliyah.Enabled then
								break
							end
	
							local part = not v:IsA('Model') and v or v.PrimaryPart
							if part and (part.Position - localPosition).Magnitude <= Range.Value then
								func(v)
							end
						end
					end
					task.wait(0.1)
				until not AutoKaliyah.Enabled
			end
		end,
		Tooltip = 'Automatically uses the "punch" ability from kaliyah'
	})
	
	NoSlow = AutoKaliyah:CreateToggle({
		Name = 'No Slow',
		Tooltip = 'Prevents you from being slowed down after using the "Punch" ability',
		Default = true
	})
	Range = AutoKaliyah:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 20,
		Default = 18,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	AutoKaliyah:CreateButton({
		Name = 'Sync to legit range',
		Function = function()
			Range:SetValue(Legit)
		end
	})
	Delay = AutoKaliyah:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 1,
		Default = 0.1,
		Decimal = 100
	})
	
end)

run(function()
	local AutoLani
	local Delay
	local UseEnemy
	local Enemy
	local Player
	
	local Request = {Fire = function(self, ...) end}
	pcall(function()
		Request = bedwars.Handler:Get('PaladinAbilityRequest')
	end)
	
	AutoLani = vape.Categories.Minigames:CreateModule({
		Name = 'AutoLani',
		Function = function(callback)
			if callback then
				local oldstart = 0
	
				repeat
					local start = (lplr:GetAttribute('PaladinStartTime') or 0)
					if oldstart and oldstart ~= start then
						local player = UseEnemy.Enabled and playersService:FindFirstChild(Enemy.Value) or not UseEnemy.Enabled and playersService:FindFirstChild(Player.Value) or nil
	
						if player then
							task.delay(Delay.Value, function()
								if AutoLani.Enabled and player.Parent == playersService then
									Request:Fire('SendToServer', {target = player})
								end
							end)
						end
					end
					oldstart = start
					task.wait(0.1)
				until not AutoLani.Enabled
			end
		end,
		Tooltip = 'Automatically uses the "scepter of light" ability'
	})
	
	local friends, enemies = {'None'}, {'None'}
	local teamConnections = {}
	
	local function rebuildPlayers()
		table.clear(friends)
		table.clear(enemies)
		table.insert(friends, 'None')
		table.insert(enemies, 'None')
		for _, plr in playersService:GetPlayers() do
			if plr:GetAttribute('Team') == lplr:GetAttribute('Team') then
				table.insert(friends, plr.Name)
			elseif plr.Team and plr.Team.Name ~= 'Spectators' then
				table.insert(enemies, plr.Name)
			end
		end
		Player:Change(friends)
		Enemy:Change(enemies)
	end
	
	local function addConnection(plr)
		if teamConnections[plr] then
			teamConnections[plr]:Disconnect()
		end
		teamConnections[plr] = plr:GetAttributeChangedSignal('Team'):Connect(rebuildPlayers)
		rebuildPlayers()
	end
	
	Player = AutoLani:CreateDropdown({
		Name = 'Selected Player',
		List = {},
		Tooltip = 'Player to use the ability on'
	})
	Enemy = AutoLani:CreateDropdown({
		Name = 'Selected Enemy',
		List = {},
		Tooltip = 'Target to use the ability on',
		Visible = false
	})
	UseEnemy = AutoLani:CreateToggle({
		Name = 'Use enemy',
		Function = function(call)
			Enemy.Object.Visible = call
			Player.Object.Visible = not call
		end,
		Tooltip = 'Uses the ability on other people instead of your teammates'
	})
	for _, v in playersService:GetPlayers() do
		addConnection(v)
	end
	vape:Clean(playersService.PlayerAdded:Connect(addConnection))
	vape:Clean(playersService.PlayerRemoving:Connect(function(plr)
		if teamConnections[plr] then
			teamConnections[plr]:Disconnect()
			teamConnections[plr] = nil
		end
		rebuildPlayers()
	end))
	vape:Clean(function()
		for _, connection in teamConnections do
			connection:Disconnect()
		end
		table.clear(teamConnections)
	end)
	Delay = AutoLani:CreateSlider({
		Name = 'Delay',
		Min = 1,
		Max = 20,
		Default = 5,
		Suffix = function(val)
			return val <= 1 and 'sec' or 'secs'
		end,
		Decimal = 10,
		Tooltip = 'Delay between triggers'
	})
	
end)

run(function()
	local AutoMarina
	local Range
	
	AutoMarina = vape.Categories.Minigames:CreateModule({
		Name = 'AutoMarina',
		Function = function(call)
			if call then
				local jellies = collection('jellyfish', AutoMarina, function(tab, obj)
					task.delay(0, function()
						if obj:GetAttribute('PlacedByUserId') == lplr.UserId then
							table.insert(tab, obj)
						end
					end)
				end)
				repeat
					if entitylib.isAlive and bedwars.AbilityController:canUseAbility('electrify_jellyfish') then
						for _, v in jellies do
							if v.PrimaryPart then
								if entitylib.EntityPosition({
									Origin = v.PrimaryPart.Position,
									Range = Range.Value,
									Part = 'RootPart',
									Players = true
								}) then
									bedwars.AbilityController:useAbility('electrify_jellyfish')
									break
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoMarina.Enabled
			end
		end,
		Tooltip = 'Automatically uses "electrify" ability when enemies are near jellies.'
	})
	
	Range = AutoMarina:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 65,
		Default = 50,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end,
	})
end)

run(function()
	local AutoMartin
	local Targets
	local Range
	
	AutoMartin = vape.Categories.Minigames:CreateModule({
	    Name = 'AutoMartin',
	    Function = function(callback)
	        if callback then
	            repeat
	                local ent = entitylib.EntityPosition({
	                    Range = Range.Value,
	                    Part = 'RootPart',
	                    Wallcheck = Targets.Walls.Enabled,
	                    Players = Targets.Players.Enabled,
	                    NPCs = Targets.NPCs.Enabled,
	                    Sort = sortmethods.Distance,
	                })
	                if ent and bedwars.AbilityController:canUseAbility('cactus_fire') then
	                    bedwars.AbilityController:useAbility('cactus_fire')
	                end
	                task.wait(0.1)
	            until not AutoMartin.Enabled
	        end
	    end,
	    Tooltip = 'Automatically uses "Wild growth" ability when within range.'
	})
	
	Targets = AutoMartin:CreateTargets({
		Players = true,
		Walls = true
	})
	Range = AutoMartin:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 22,
		Default = 22,
		Suffix = function(val)
			return val <= 0 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local AutoMelody
	local Range
	local SelfHeal
	local TeammateHeal
	
	AutoMelody = vape.Categories.Minigames:CreateModule({
		Name = 'AutoMelody',
		Function = function(callback)
			if callback then
				repeat
					local mag, hp, ent = Range.Value, math.huge, nil
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in entitylib.List do
							if v.Player and (SelfHeal.Enabled or v.Player ~= lplr) and (TeammateHeal.Enabled and v.Player:GetAttribute('Team') == lplr:GetAttribute('Team') or not TeammateHeal.Enabled and SelfHeal.Enabled and v.Player == lplr) then
								local newmag = (localPosition - v.RootPart.Position).Magnitude
								if newmag <= mag and v.Health < hp and v.Health < v.MaxHealth then
									mag, hp, ent = newmag, v.Health, v
								end
							end
						end
					end
	
					if ent and getItem('guitar') then
						bedwars.Handler:Get('GuitarHeal'):Fire('SendToServer', {
							healTarget = ent.Character
						})
					end
	
					task.wait(0.1)
				until not AutoMelody.Enabled
			end
		end,
		Tooltip = 'Automatically uses the guitar to heal ur teammates/urself'
	})
	
	SelfHeal = AutoMelody:CreateToggle({
		Name = 'Self Heal',
		Default = true
	})
	TeammateHeal = AutoMelody:CreateToggle({
		Name = 'Teammate Heal',
		Default = true
	})
	Range = AutoMelody:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 30,
		Default = 30,
		Decimal = 4
	})
end)

run(function()
	local AutoMetal
	local Limit
	local StreamerMode
	local Duration
	local Range
	local Animation
	
	local Legit = getFunctionRange(bedwars.HiddenMetalController.onKitLocalActivated) or 0
	local Delay = {}
	
	AutoMetal = vape.Categories.Minigames:CreateModule({
		Name = 'AutoMetal',
		Function = function(call)
			if call then
				AutoMetal:Clean(proximityPromptService.PromptShown:Connect(function(prompt)
					if StreamerMode.Enabled then
						if prompt.Name == 'hidden-metal-prompt' and (not Limit.Enabled or store.hand.tool and store.hand.tool.Name == 'metal_detector') then
							task.wait(0.1)
							prompt:InputHoldBegin()
						end
					end
				end))
	
				repeat
					if not StreamerMode.Enabled and entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						for i, v in collectionService:GetTagged('hidden-metal') do
							if tick() > (Delay[v] or 0) and (localPosition - v.Part.Position).Magnitude <= Range.Value and (not Limit.Enabled or store.hand.tool and store.hand.tool.Name == 'metal_detector') then
								if Duration.Value > 0 then
									task.wait(Duration.Value)
								end
	
								if (localPosition - v.Part.Position).Magnitude <= Range.Value then
									if Animation.Enabled then
										bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.SHOVEL_DIG)
										bedwars.SoundManager:playSound(bedwars.SoundList.SNAP_TRAP_CONSUME_MARK)
									end
									bedwars.Handler:Get('CollectCollectableEntity'):Fire('SendToServer', {
										id = v:GetAttribute('Id')
									})
									Delay[v] = tick() + 1
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoMetal.Enabled
			end
		end,
		Tooltip = 'Automatically uses the metal kit'
	})
	
	Limit = AutoMetal:CreateToggle({Name = 'Limit to item'})
	StreamerMode = AutoMetal:CreateToggle({
		Name = 'Streamer mode',
		Function = function(call)
			pcall(function()
				Duration.Object.Visible = not call
				Range.Object.Visible = not call
				Animation.Object.Visible = not call
			end)
		end,
		Tooltip = 'Actually does the metal prompt thing for you'
	})
	Animation = AutoMetal:CreateToggle({
		Name = 'Animation',
		Default = true,
		Tooltip = 'Plays the metal collect animation'
	})
	Range = AutoMetal:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 20,
		Default = Legit,
		Suffix = function(val)
			return val > 1 and 'studs' or 'stud'
		end
	})
	AutoMetal:CreateButton({
		Name = 'Sync to legit range',
		Function = function()
			Range:SetValue(Legit)
		end
	})
	Duration = AutoMetal:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 1,
		Suffix = function(val)
			return val > 1 and 'secs' or 'sec'
		end,
		Default = 0.2,
		Decimal = 5
	})
end)

run(function()
	local AutoMiner
	local Delay
	local Animation
	local Range
	
	local Legit = getFunctionRange(bedwars.MinerController.setupMinerPrompts) or 0
	
	AutoMiner = vape.Categories.Minigames:CreateModule({
	    Name = 'AutoMiner',
	    Function = function(callback)
	        if callback then
	            local souls = collection('petrified-player', AutoMiner)
	            local cooldown = 0
	            repeat
	                if entitylib.isAlive and (tick() - cooldown) >= Delay.Value then
	                    local localPosition = entitylib.character.RootPart.Position
	                    for _, v in souls do
	                        if (localPosition - v.Position).Magnitude <= Range.Value then
	                            bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.MINER_MINE_STONE)
	                            task.delay(Delay.Value, function()
	                                if AutoMiner.Enabled and v.Parent then
	                                    bedwars.Handler:Get('DestroyPetrifiedPlayer'):Fire('SendToServer', {
	                                        petrifyId = v:GetAttribute('Id')
	                                    })
	                                end
	                            end)
	                            cooldown = tick()
	                            break
	                        end
	                    end
	                end
	                task.wait(0.1)
	            until not AutoMiner.Enabled
	        end
	    end
	})
	
	Range = AutoMiner:CreateSlider({
	    Name = 'Range',
	    Min = 1,
	    Max = 30,
	    Default = 12,
	    Suffix = function(val)
	        return val <= 1 and 'stud' or 'studs'
	    end
	})
	AutoMiner:CreateButton({
		Name = 'Sync to legit range',
		Function = function()
			Range:SetValue(Legit)
		end
	})
	Delay = AutoMiner:CreateSlider({
	    Name = 'Delay',
	    Min = 0,
	    Max = 2,
	    Default = 0.1,
	    Suffix = 'seconds',
	    Decimal = 10
	})
	Animation = AutoMiner:CreateToggle({Name = 'Animation', Default = true})
	
end)

run(function()
	local AutoNoelle
	local Notify
	local FrostySlime
	local HealSlime
	local StickySlime
	local VoidSlime
	local Limit
	
	local function getSlimes()
		local slimes = {}
		local folder = workspace:FindFirstChild('SlimeModelFolder')
		for _, v in folder:GetChildren() do
			local data = v:FindFirstChild('SlimeData')
			data = data and data.Value or nil
	
			if data and data.Tamer.Value == lplr.UserId then
				table.insert(slimes, {
					Data = data, 
					RootPart = v, 
					Name = v.Name:gsub(`_{lplr.Name}`, ''):gsub('Slime', ' Slime')
				})
			end
		end
		return slimes
	end
	
	local function getPlayer(name)
		for _, v in playersService:GetPlayers() do
			if (`{v.DisplayName} ({v.Name})`) == name then
				return v
			end
		end
		return
	end
	
	AutoNoelle = vape.Categories.Minigames:CreateModule({
		Name = 'AutoNoelle',
		Function = function(call)
			if call then
				repeat
					if entitylib.isAlive and (not Limit.Enabled or store.hand.tool and store.hand.tool.Name == 'slime_tamer_flute') then
						local slimes = getSlimes()
	
						for _, v in slimes do
							local dropdown = AutoNoelle.Options[`{v.Name} Target`]
							if dropdown then
								local player = getPlayer(dropdown.Value)
								if player and v.Data.Following.Value ~= player.UserId then
									bedwars.Handler:Get('RequestMoveSlime'):Fire('CallServerAsync', {
										slimeId = v.Data:GetAttribute('Id'),
										targetPlayerUserId = player.UserId,
									}):andThen(function(suc)
										if suc then
											v.Data.Following.Value = player.UserId
											if Notify.Enabled then
												notif('AutoNoelle', `Directed {v.Name} to {player.DisplayName} ({player.Name})`, 5, 'info')
											end
										end
									end)
								end
							end
						end
					end
					task.wait(0.5)
				until not AutoNoelle.Enabled
			end
		end,
		Tooltip = 'Automatically directs the slimes to the selected player\'s'
	})
	
	local friends = { 'None' }
	
	local function addConnection(plr)
		if plr:GetAttribute('Team') == lplr:GetAttribute('Team') then
			table.insert(friends, `{plr.DisplayName} ({plr.Name})`)
			FrostySlime:Change(friends)
			HealSlime:Change(friends)
			StickySlime:Change(friends)
			VoidSlime:Change(friends)
		end
	
		vape:Clean(plr:GetAttributeChangedSignal('Team'):Connect(function()
			if plr:GetAttribute('Team') == lplr:GetAttribute('Team') then
				table.insert(friends, `{plr.DisplayName} ({plr.Name})`)
				FrostySlime:Change(friends)
				HealSlime:Change(friends)
				StickySlime:Change(friends)
				VoidSlime:Change(friends)
			end
		end))
	end
	
	Notify = AutoNoelle:CreateToggle({ Name = 'Notify on direct' })
	Limit = AutoNoelle:CreateToggle({ Name = 'Limit to item' })
	FrostySlime = AutoNoelle:CreateDropdown({
		Name = 'Frosty Slime Target',
		List = {},
		Tooltip = 'Player to direct frost slimes to',
	})
	HealSlime = AutoNoelle:CreateDropdown({
		Name = 'Heal Slime Target',
		List = {},
		Tooltip = 'Player to direct heal slimes to',
	})
	StickySlime = AutoNoelle:CreateDropdown({
		Name = 'Sticky Slime Target',
		List = {},
		Tooltip = 'Player to direct sticky slimes to',
	})
	VoidSlime = AutoNoelle:CreateDropdown({
		Name = 'Void Slime Target',
		List = {},
		Tooltip = 'Player to direct void slimes to',
	})
	
	for _, v in playersService:GetPlayers() do
		addConnection(v)
	end
	vape:Clean(playersService.PlayerAdded:Connect(addConnection))
end)

run(function()
	local AutoNyx
	local Targets
	
	AutoNyx = vape.Categories.Minigames:CreateModule({
		Name = 'AutoNyx',
		Function = function(call)
			if call then
				AutoNyx:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if damageTable.damageType == 0 and damageTable.fromEntity and damageTable.fromEntity.Name == lplr.Name and entitylib.EntityPosition({
						Range = 14.4,
						Part = 'RootPart',
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
					}) and bedwars.AbilityController:canUseAbility('midnight') then
						bedwars.AbilityController:useAbility('midnight')
					end
				end))
			end
		end,
		Tooltip = 'Automatically uses the "midnight" ability when meleeing a target'
	})
	
	Targets = AutoNyx:CreateTargets({
		Players = true,
		NPCs = false
	})
end)

run(function()
	local AutoPyro
	
	local list = {'Range', 'Heat', 'Power'}
	
	AutoPyro = vape.Categories.Minigames:CreateModule({
		Name = 'AutoPyro',
		Function = function(callback)
			if callback then
				repeat
					local flamethrower = getItem('flamethrower')
					if flamethrower then
						for _, v in list do
							if not AutoPyro.Options['Buy ' .. v].Enabled then
								table.remove(list, table.find(list, v))
							end
						end
	
						for _, v in list do
							v = v:lower()
							local value = flamethrower.tool:GetAttribute(v) or -1
							if value < 3 then
								local nextUpgrade = bedwars.PyroUpgradeMeta[v].tiers[value + 2]
								if nextUpgrade then
									local currency = getItem(nextUpgrade.currency)
									if currency and currency.amount >= nextUpgrade.price then
										bedwars.Handler:Get('UpgradeFlamethrower'):Fire('CallServer', v)
										task.wait(0.1)
									end
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoPyro.Enabled
			end
		end,
		Tooltip = 'Automatically upgrades flamethrower'
	})
	
	for _, i in list do
		AutoPyro:CreateToggle({
			Name = 'Buy ' .. i,
			Default = true
		})
	end
end)

run(function()
	local AutoRamil
	local Range
	local Sorts
	local Targets
	local UseTornando
	local TonradoRange
	
	AutoRamil = vape.Categories.Minigames:CreateModule({
		Name = 'AutoRamil',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive and store.equippedKit == 'airbender' then
						local localPosition = entitylib.character.RootPart.Position
						local ent = entitylib.EntityPosition({
							Origin = localPosition,
							Range = (UseTornando.Enabled and TonradoRange.Value > Range.Value and TonradoRange.Value or Range.Value),
							Wallcheck = Targets.Walls.Enabled,
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Sort = sortmethods[Sorts.Value],
						})
	
						if ent then
							if (localPosition - ent.RootPart.Position).Magnitude <= Range.Value and bedwars.AbilityController:canUseAbility('airbender_tornado') then
								bedwars.AbilityController:useAbility('airbender_tornado')
							end
	
							if UseTornando.Enabled and (localPosition - ent.RootPart.Position).Magnitude <= TonradoRange.Value and bedwars.AbilityController:canUseAbility('airbender_moving_tornado') then
								bedwars.AbilityController:useAbility('airbender_moving_tornado')
							end
						end
					end
					task.wait()
				until not AutoRamil.Enabled
			end
		end,
		Tooltip = 'Automatically use ramil abilities on certain conditions.'
	})
	
	Targets = AutoRamil:CreateTargets({
		Players = true,
		NPCs = false
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	Sorts = AutoRamil:CreateDropdown({
		Name = 'Target Mode',
		List = methods,
		Default = 'Distance'
	})
	Range = AutoRamil:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 25,
		Default = 25,
		Suffix = function(val)
			return val >= 1 and 'studs' or 'stud'
		end
	})
	UseTornando = AutoRamil:CreateToggle({
		Name = 'Use Moving Tornado',
		Function = function(call)
			pcall(function()
				TonradoRange.Object.Visible = call
			end)
		end
	})
	TonradoRange = AutoRamil:CreateSlider({
		Name = 'Tornado Range',
		Min = 1,
		Max = 35,
		Default = 25,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val >= 1 and 'studs' or 'stud'
		end
	})
end)

run(function()
	local AutoSheep
	local Delay
	local Range
	
	local tameSheep = {SendToServer = function(self, ...) end}
	pcall(function()
		tameSheep = bedwars.Client:GetNamespace('SheepHerder'):Get('TameSheep')
	end)
	
	AutoSheep = vape.Categories.Minigames:CreateModule({
		Name = 'AutoSheepHerder',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						local model = workspace:FindFirstChild('SheepModel')
	
						for _, v in model:GetChildren() do
							if v.PrimaryPart and (localPosition - v.PrimaryPart.Position).Magnitude <= Range.Value then
								if Delay.Value > 0 then
									task.wait(Delay.Value)
								end
								tameSheep:SendToServer(v.SheepData.Value)
							end
						end
					end
					task.wait(0.1)
				until not AutoSheep.Enabled
			end
		end,
		Tooltip = 'Automatically tames sheep within range.'
	})
	
	Range = AutoSheep:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 20,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end,
		Default = 20
	})
	Delay = AutoSheep:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 1,
		Default = 0.1,
		Decimal = 100
	})
end)

run(function()
	local AutoStar
	local Streamer
	local Range
	local Animation
	local Delay
	
	AutoStar = vape.Categories.Minigames:CreateModule({
		Name = 'AutoStarCollector',
		Function = function(callback)
			if callback then
				AutoStar:Clean(proximityPromptService.PromptShown:Connect(function(prompt)
					if Streamer.Enabled then
						if prompt.Name == 'stars_ProximityPrompt' then
							task.wait(0.1)
							prompt:InputHoldBegin()
						end
					end
				end))
	
				repeat
					if not Streamer.Enabled and entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						for i, v in collectionService:GetTagged('stars') do
							if tick() > (Delay[v] or 0) and v.PrimaryPart and (localPosition - v.PrimaryPart.Position).Magnitude <= Range.Value then
								if Delay.Value > 0 then
									task.wait(Delay.Value)
								end
	
								if (localPosition - v.PrimaryPart.Position).Magnitude <= Range.Value then
									if Animation.Enabled then
										bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.PUNCH)
										bedwars.ViewmodelController:playAnimation(bedwars.AnimationType.FP_USE_ITEM)
									end
									bedwars.StarCollectorController:collectEntity(lplr, v, v.Name)
									Delay[v] = tick() + 1
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoStar.Enabled
			end
		end,
		Tooltip = 'Automatically collects stars'
	})
	
	Streamer = AutoStar:CreateToggle({
		Name = 'Streamer mode',
		Function = function(call)
			pcall(function()
				Delay.Object.Visible = not call
				Range.Object.Visible = not call
				Animation.Object.Visible = not call
			end)
		end,
		Tooltip = 'Useful for when ur screensharing'
	})
	Animation = AutoStar:CreateToggle({
		Name = 'Animation',
		Default = true,
		Tooltip = 'Plays the collect animation'
	})
	Range = AutoStar:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 20,
		Default = 12,
		Suffix = function(val)
			return val > 1 and 'studs' or 'stud'
		end
	})
	Delay = AutoStar:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 1,
		Suffix = function(val)
			return val > 1 and 'secs' or 'sec'
		end,
		Default = 0.2,
		Decimal = 100
	})
end)

run(function()
	local AutoTaliyah
	local Emerald
	local Diamond
	local Iron
	local Amount
	
	local function getShopNPC()
		local shop, items, upgrades, newid = nil, false, false, nil
		if entitylib.isAlive then
			local localPosition = entitylib.character.RootPart.Position
			for _, v in store.shop do
				if (v.RootPart.Position - localPosition).Magnitude <= 20 then
					shop = v.Upgrades or v.Shop or nil
					upgrades = upgrades or v.Upgrades
					items = items or v.Shop
					newid = v.Shop and v.Id or newid
				end
			end
		end
		return shop, items, upgrades, newid
	end
	
	AutoTaliyah = vape.Categories.Minigames:CreateModule({
		Name = 'AutoTaliyah',
		Tooltip = 'Automatically buy chickens when it sells for emerald',
		Function = function(callback)
			if callback then
				local item = bedwars.Shop.getShopItem('chicken_shop_item', lplr)
				repeat
					local shopNpc, items, __, id = getShopNPC()
					if shopNpc and items then
						local chickenData = bedwars.TaliyahUtil:getPrice()
						if (chickenData.currency == 'emerald' and Emerald.Enabled or chickenData.currency == 'iron' and Iron.Enabled or chickenData.currency == 'diamond' and Diamond.Enabled) and chickenData.price >= Amount.Value then
							bedwars.Handler:Get('BedwarsPurchaseItem'):Fire('CallServerAsync', {
								shopItem = item,
								shopId = id
							}):andThen(function(suc)
								if suc then
									bedwars.SoundManager:playSound(bedwars.SoundList.BEDWARS_PURCHASE_ITEM)
									bedwars.Store:dispatch({
										type = 'BedwarsAddItemPurchased',
										itemType = item.itemType
									})
									bedwars.BedwarsShopController.alreadyPurchasedMap[item.itemType] = true
								end
							end)
						end
					end
					task.wait(0.1)
				until not AutoTaliyah.Enabled
			end
		end,
	})
	
	Iron = AutoTaliyah:CreateToggle({
		Name = 'Iron',
		Default = true,
		Tooltip = 'Sells ur chicken when the currency is iron'
	})
	Emerald = AutoTaliyah:CreateToggle({
		Name = 'Emerald',
		Default = true,
		Tooltip = 'Sells ur chicken when the currency is emerald'
	})
	Diamond = AutoTaliyah:CreateToggle({
		Name = 'Diamond',
		Default = true,
		Tooltip = 'Sells ur chicken when the currency is diamond'
	})
	Amount = AutoTaliyah:CreateSlider({
		Name = 'Amount',
		Default = 2,
		Min = 1,
		Max = 1000,
		Tooltip = 'Only sells if the currency is selling for the selected amount'
	})
end)

run(function()
	local AutoTriton
	local Legit
	local Back
	local BackDelay
	local Limit
	
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	rayCheck.FilterType = Enum.RaycastFilterType.Include
	local projectileRemote = {InvokeServer = function(self, ...) end}
	task.spawn(function()
		projectileRemote = bedwars.Handler:Get('ProjectileFire').Remote.instance
	end)
	
	local function firePearl(pos, spot, item)
		local hotbar, old = getHotbar(item.tool), store.hand
	
		switchItem(item.tool)
		if Legit.Enabled and hotbar then
			hotbarSwitch(hotbar)
		end
	
		local meta = bedwars.ProjectileMeta.harpoon_projectile
		local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)
		local landed = false
	
		if calc then
			local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
			local projectile = bedwars.ProjectileController:createLocalProjectile(meta, 'harpoon_projectile', 'harpoon_projectile', pos, nil, dir, {drawDurationSeconds = 1})
			local res = projectileRemote:InvokeServer(
				item.tool,
				'harpoon_projectile',
				'harpoon_projectile',
				pos,
				pos,
				dir,
				httpService:GenerateGUID(true),
				{ 
	                drawDurationSeconds = 1, 
	                shotId = httpService:GenerateGUID(false) 
	            },
				workspace:GetServerTimeNow() - 0.045
			)
			task.spawn(function()
				local timeout = tick() + 10
				repeat
					task.wait()
				until not AutoTriton.Enabled or not projectile or not projectile.Parent or tick() >= timeout
				landed = true
			end)
			if res then
				pcall(function()
					res.Parent = replicatedStorage
				end)
			end
		else
			landed = true
		end
	
	    repeat
	        task.wait() 
	    until landed or not AutoTriton.Enabled
		if Back.Enabled and old and old.tool then
			task.wait(BackDelay:GetRandomValue())
			switchItem(old.tool)
			if Legit.Enabled and getHotbar(old.tool) then
				hotbarSwitch(getHotbar(old.tool))
			end
		end
	end
	
	local function findNearGround(origin)
		for _, v in {Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0), Vector3.new(0, 0, -1)} do
			for i = 1, 24 do
				local ray = workspace:Raycast((origin.Position + (Vector3.yAxis * 3)) + (v * i), Vector3.new(0, -60, 0), rayCheck)
				if ray then
					return ray.Position
				end
			end
		end
		return nil
	end
	
	AutoTriton = vape.Categories.Minigames:CreateModule({
		Name = 'AutoTriton',
		Function = function(callback)
			if callback then
				local check, lasty
				repeat
					if entitylib.isAlive and (not Limit.Enabled or store.hand.tool and store.hand.tool.Name == 'harpoon') then
						local root = entitylib.character.RootPart
						local pearl = getItem('harpoon')
						rayCheck.FilterDescendantsInstances = {store.map}
						rayCheck.CollisionGroup = root.CollisionGroup
	
						if entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
							lasty = root.CFrame
						end
	
						if pearl and root.Velocity.Y < -60 and not workspace:Raycast(root.Position, Vector3.new(0, -200, 0), rayCheck) then
							if not check then
								check = true
								local ground = findNearGround(root.CFrame + Vector3.new(0, 40, 0)) or findNearGround(lasty and lasty + Vector3.new(0, 5, 0) or root.CFrame)
								if ground then
									firePearl(root.Position, ground, pearl)
								end
							end
						else
							check = false
						end
					end
					task.wait(0.1)
				until not AutoTriton.Enabled
			end
		end,
		Tooltip = 'Automatically throws triton trident onto nearby ground after\nfalling a certain distance.'
	})
	
	Legit = AutoTriton:CreateToggle({
		Name = 'Legit Switch',
		Tooltip = 'Visualizes the switching clientside',
		Default = true
	})
	Back = AutoTriton:CreateToggle({
		Name = 'Switch back',
		Default = true,
		Function = function(callback)
			if BackDelay then
				BackDelay.Object.Visible = callback
			end
		end,
		Tooltip = 'Switches back to the last slot before pearl'
	})
	BackDelay = AutoTriton:CreateTwoSlider({
		Name = 'Switch Back Delay',
		Min = 0,
		Max = 2,
		DefaultMin = 0.1,
		DefaultMax = 0.2,
		Darker = true
	})
	Limit = AutoTriton:CreateToggle({
		Name = 'Limit to item',
		Tooltip = 'Only throws pearl when holding a pearl'
	})
	
end)

run(function()
	local AutoUma
	local Range
	local Limit
	local Animation
	local AutoSummon
	local HealSpirit
	local AttackSpirit
	local TargetItemDrops
	local Diamond
	local Emerald
	
	local function getAttackData()
		if Limit.Enabled then
			local tool = (store.hand.tool and store.hand.tool.Name == 'spirit_staff') and store.hand.tool or nil
			return tool, tool and getHotbar(tool) or nil
		end
		for i, v in store.inventory.inventory.items do
			if v.itemType == 'spirit_staff' then
				switchItem(v, 0)
				return v, i
			end
		end
		return
	end
	
	local function getDrops(localPosition, ItemDrops)
		local drop, lastmag = nil, Range.Value + 1
		for i, v in ItemDrops do
			if v.Name == 'emerald' and Emerald.Enabled or v.Name == 'diamond' and Diamond.Enabled then
				local magnitude = (localPosition - v.Position).Magnitude
				if magnitude <= lastmag and not entitylib.Wallcheck(localPosition, v.Position, {gameCamera, lplr.Character, v}) then
					drop, lastmag = v, magnitude
				end
			end
		end
		return drop
	end
	
	AutoUma = vape.Categories.Minigames:CreateModule({
		Name = 'AutoUma',
		Function = function(call)
			if call then
				local items = collection('ItemDrop', AutoUma)
				repeat
					local staff = getAttackData()
					if staff then
						if TargetItemDrops.Enabled then
							local attackSpirits = (lplr:GetAttribute('ReadySummonedAttackSpirits') or 0)
							local healSpirits = (lplr:GetAttribute('ReadySummonedHealSpirits') or 0)
	
							if AutoSummon.Enabled then
								if AttackSpirit.Enabled and attackSpirits < 1 and getItem('summon_stone') then
									bedwars.AbilityController:useAbility('summon_attack_spirit')
								end
	
								if HealSpirit.Enabled and healSpirits < 1 and getItem('summon_stone') then
									bedwars.AbilityController:useAbility('summon_heal_spirit')
								end
							end
	
							if (healSpirits + attackSpirits) > 0 then
								local localPosition = entitylib.character.RootPart.Position
								local drop = getDrops(localPosition, items)
	
								if drop then
									local shootpos = localPosition + Vector3.new(0, 2, 0)
									local dir = CFrame.lookAt(localPosition, drop.Position + Vector3.new(0, (localPosition - drop.Position).Magnitude / 5, 0)).LookVector * 100
	
									bedwars.Handler:Get('ProjectileFire').Remote.instance:InvokeServer(
										staff,
										nil,
										attackSpirits > 0 and 'attack_spirit' or 'heal_spirit',
										shootpos,
										localPosition,
										dir,
										httpService:GenerateGUID(),
										{
											drawDurationSeconds = 1,
											shotId = httpService:GenerateGUID(false),
										},
										workspace:GetServerTimeNow() - 0.045
									)
	
									if Animation.Enabled then
										bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.WIZARD_BALL_CAST)
										bedwars.SoundManager:playSound(bedwars.SoundList.SPIRIT_SUMMONER_CHANGE_AFFINITY, {})
									end
	
									task.wait(1.5)
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoUma.Enabled
			end
		end,
		Tooltip = 'Automatically throw spirits at item drops and opponents.'
	})
	
	Range = AutoUma:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 80,
		Default = 50,
		Decimal = 5,
		Suffix = function(val)
			return val >= 2 and 'studs' or 'stud'
		end
	})
	Animation = AutoUma:CreateToggle({
		Name = 'Animation',
		Default = true
	})
	Limit = AutoUma:CreateToggle({
		Name = 'Limit to item',
		Default = true
	})
	AutoSummon = AutoUma:CreateToggle({
		Name = 'Auto Summon',
		Function = function(call)
			pcall(function()
				AttackSpirit.Object.Visible = call
				HealSpirit.Object.Visible = call
			end)
		end,
		Tooltip = 'Automattically summons spirit for you'
	})
	HealSpirit = AutoUma:CreateToggle({
		Name = 'Use heal spirit',
		Default = true,
		Visible = false,
		Darker = true
	})
	AttackSpirit = AutoUma:CreateToggle({
		Name = 'Use attack spirit',
		Default = true,
		Visible = false,
		Darker = true
	})
	TargetItemDrops = AutoUma:CreateToggle({
		Name = 'Target item drops',
		Default = true,
		Function = function(call)
			pcall(function()
				Emerald.Object.Visible = call
				Diamond.Object.Visible = call
			end)
		end
	})
	Emerald = AutoUma:CreateToggle({
		Name = 'Emerald',
		Darker = true,
		Default = true
	})
	Diamond = AutoUma:CreateToggle({
		Name = 'Diamond',
		Darker = true,
		Default = true
	})
end)

run(function()
	local AutoWhisper
	local Heal
	local Threshold
	local Fly
	local Level
	
	AutoWhisper = vape.Categories.Minigames:CreateModule({
		Name = 'AutoWhisper',
		Function = function(callback)
			if callback then
				local lowestpoint = math.huge
				repeat
					task.wait()
				until store.matchState ~= 0 or not AutoWhisper.Enabled
				if not AutoWhisper.Enabled then
					return
				end
	
				for _, v in store.blocks do
					local point = (v.Position.Y - (v.Size.Y / 2)) - 50
					if point < lowestpoint then
						lowestpoint = point
					end
				end
	
				repeat
					local liftReady = Fly.Enabled and (workspace:GetServerTimeNow() - (lplr:GetAttribute('OwlLiftReadyTime') or 0)) > 0
					local healReady = Heal.Enabled and (workspace:GetServerTimeNow() - (lplr:GetAttribute('OwlHealReadyTime') or 0)) > 0
	
					if liftReady or healReady then
						for _, v in collectionService:GetTagged('Owl') do
							if v:GetAttribute('Owner') == lplr.UserId then
								local plr = playersService:GetPlayerByUserId(v:GetAttribute('Target'))
								local char = plr and plr.Character
								local root = char and char:FindFirstChild('HumanoidRootPart')
								if char and root then
									if liftReady and root.Velocity.Y < -10 then
										if root.Position.Y < lowestpoint then
											bedwars.AbilityController:useAbility('OWL_LIFT')
										end
									end
									local health = char:GetAttribute('Health')
									local maxHealth = char:GetAttribute('MaxHealth')
									if healReady and (Threshold.Value >= 100 or type(health) == 'number' and type(maxHealth) == 'number' and maxHealth > 0 and (health / maxHealth) <= (Threshold.Value / 100)) then
										bedwars.AbilityController:useAbility('OWL_HEAL')
									end
								end
								break
							end
						end
					end
					task.wait(0.1)
				until not AutoWhisper.Enabled
			end
		end,
		Tooltip = 'Automatically uses whisper abilities'
	})
	
	Heal = AutoWhisper:CreateToggle({
		Name = 'Heal',
		Default = true,
		Function = function(call)
			if Threshold then
				Threshold.Object.Visible = call
			end
		end
	})
	Threshold = AutoWhisper:CreateSlider({
		Name = 'Health',
		Min = 1,
		Max = 100,
		Default = 99,
		Suffix = '%',
		Darker = true
	})
	Fly = AutoWhisper:CreateToggle({
		Name = 'Fly',
		Default = true,
		Function = function(call)
			if Level then
				Level.Object.Visible = call
			end
		end
	})
	Level = AutoWhisper:CreateSlider({
		Name = 'Level',
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = function(val)
			return val <= 1 and 'stud' or 'studs'
		end
	})
	
end)

run(function()
	local BedPlates
	local Background
	local Color
	local LayerCounter
	local LayerColor
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local function getBlockLayerHealth(block)
		local meta = bedwars.ItemMeta[block]
		return meta and meta.block and meta.block.health or 0
	end
	
	local function getLayerColor()
		return LayerColor and Color3.fromHSV(LayerColor.Hue, LayerColor.Sat, LayerColor.Value) or Color3.new(1, 1, 1)
	end
	
	local function scanSide(self, start, tab)
		for _, side in sides do
			local layers = {}
			for i = 1, 15 do
				local block = getPlacedBlock(start + (side * i))
				if not block or block == self or block.Name == 'bed' then
					break
				end
				if not block:GetAttribute('NoBreak') then
					layers[block.Name] = (layers[block.Name] or 0) + 1
				end
			end
	
			for block, amount in layers do
				tab[block] = math.max(tab[block] or 0, amount)
			end
		end
	end
	
	local function refreshAdornee(v)
		for _, obj in v.Frame:GetChildren() do
			if obj:IsA('ImageLabel') and obj.Name ~= 'Blur' then
				obj:Destroy()
			end
		end
	
		local start = v.Adornee.Position
		local layers = {}
		local alreadygot = {}
		scanSide(v.Adornee, start, layers)
		scanSide(v.Adornee, start + Vector3.new(0, 0, 3), layers)
		for block, amount in layers do
			table.insert(alreadygot, {block, amount})
		end
		table.sort(alreadygot, function(a, b)
			local healthA, healthB = getBlockLayerHealth(a[1]), getBlockLayerHealth(b[1])
			return healthA == healthB and a[1] < b[1] or healthA > healthB
		end)
		v.Enabled = #alreadygot > 0
	
		for _, blockData in alreadygot do
			local block, amount = blockData[1], blockData[2]
			local blockimage = Instance.new('ImageLabel')
			blockimage.Size = UDim2.fromOffset(32, 32)
			blockimage.BackgroundTransparency = 1
			blockimage.Image = bedwars.getIcon({itemType = block}, true)
			blockimage.Parent = v.Frame
			if amount > 1 and (not LayerCounter or LayerCounter.Enabled) then
				local amounttext = Instance.new('TextLabel')
				amounttext.Name = 'Amount'
				amounttext.Size = UDim2.fromScale(1, 1)
				amounttext.BackgroundTransparency = 1
				amounttext.Text = tostring(amount)
				amounttext.TextColor3 = getLayerColor()
				amounttext.TextSize = 16
				amounttext.TextStrokeTransparency = 0.3
				amounttext.Font = Enum.Font.Arial
				amounttext.Parent = blockimage
			end
		end
	end
	
	local function refreshAll()
		for _, v in Reference do
			refreshAdornee(v)
		end
	end
	
	local function updateLayerTextColor()
		local textColor = getLayerColor()
		for _, v in Reference do
			for _, obj in v.Frame:GetDescendants() do
				if obj:IsA('TextLabel') and obj.Name == 'Amount' then
					obj.TextColor3 = textColor
				end
			end
		end
	end
	
	local function Added(v)
		local billboard = Instance.new('BillboardGui')
		billboard.Parent = Folder
		billboard.Name = 'bed'
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		billboard.Size = UDim2.fromOffset(36, 36)
		billboard.AlwaysOnTop = true
		billboard.ClipsDescendants = false
		billboard.Adornee = v
		local blur = addBlur(billboard)
		blur.Visible = Background.Enabled
		local frame = Instance.new('Frame')
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		frame.BackgroundTransparency = 1 - (Background.Enabled and Color.Opacity or 0)
		frame.Parent = billboard
		local layout = Instance.new('UIListLayout')
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			billboard.Size = UDim2.fromOffset(math.max(layout.AbsoluteContentSize.X + 4, 36), 36)
		end)
		layout.Parent = frame
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = frame
		Reference[v] = billboard
		refreshAdornee(billboard)
	end
	
	local function refreshNear(data)
		data = data.blockRef.blockPosition * 3
		for i, v in Reference do
			if (data - i.Position).Magnitude <= 30 then
				refreshAdornee(v)
			end
		end
	end
	
	BedPlates = vape.Categories.Minigames:CreateModule({
		Name = 'BedPlates',
		Function = function(callback)
			if callback then
				for _, v in collectionService:GetTagged('bed') do
					task.spawn(Added, v)
				end
				BedPlates:Clean(vapeEvents.PlaceBlockEvent.Event:Connect(refreshNear))
				BedPlates:Clean(vapeEvents.BreakBlockEvent.Event:Connect(refreshNear))
				BedPlates:Clean(collectionService:GetInstanceAddedSignal('bed'):Connect(Added))
				BedPlates:Clean(collectionService:GetInstanceRemovedSignal('bed'):Connect(function(v)
					if Reference[v] then
						Reference[v]:Destroy()
						Reference[v]:ClearAllChildren()
						Reference[v] = nil
					end
				end))
			else
				table.clear(Reference)
				Folder:ClearAllChildren()
			end
		end,
		Tooltip = 'Displays blocks over the bed'
	})
	Background = BedPlates:CreateToggle({
		Name = 'Background',
		Function = function(callback)
			if Color and Color.Object then
				Color.Object.Visible = callback
			end
			for _, v in Reference do
				v.Frame.BackgroundTransparency = 1 - (callback and Color.Opacity or 0)
				v.Blur.Visible = callback
			end
		end,
		Default = true
	})
	Color = BedPlates:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in Reference do
				v.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.Frame.BackgroundTransparency = 1 - opacity
			end
		end,
		Darker = true
	})
	LayerCounter = BedPlates:CreateToggle({
		Name = 'Layer Counter',
		Function = function(callback)
			if LayerColor and LayerColor.Object then
				LayerColor.Object.Visible = callback
			end
			refreshAll()
		end,
		Default = true
	})
	LayerColor = BedPlates:CreateColorSlider({
		Name = 'Counter Text Color',
		Function = function()
			updateLayerTextColor()
		end,
		DefaultSat = 0,
		DefaultValue = 1
	})
end)

run(function()
	local Breaker
	local Mode
	local Range
	local BreakSpeed
	local UpdateRate
	local Custom
	local Bed
	local Tesla
	local Hive
	local LuckyBlock
	local IronOre
	local Effect
	local CustomHealth = {}
	local Animation
	local SelfBreak
	local InstantBreak
	local LimitItem
	local Wallcheck
	local AutoTool
	local customlist, parts = {}, {}
	
	local function customHealthbar(self, blockRef, health, maxHealth, changeHealth, block)
	    xpcall(function()
	        if block:GetAttribute('NoHealthbar') then return end
	        if not self.healthbarPart or not self.healthbarBlockRef or self.healthbarBlockRef.blockPosition ~= blockRef.blockPosition then
	            if self.healthbarPart then
	                bedwars.QueryUtil:setQueryIgnored(self.healthbarPart, true)
	            end
	            self.maid:DoCleaning()
	            self.healthbarBlockRef = blockRef
	            local create = bedwars.Roact.createElement
	            local percent = math.clamp(health / maxHealth, 0, 1)
	            local cleanCheck = true
	            local part = Instance.new('Part')
	            part.Size = Vector3.one
	            part.CFrame = CFrame.new(bedwars.BlockController:getWorldPosition(blockRef.blockPosition))
	            part.Transparency = 1
	            part.Anchored = true
	            part.CanCollide = false
	            part.Parent = workspace
	            bedwars.QueryUtil:setQueryIgnored(part, true)
	            self.healthbarPart = part
	
	            local mounted = bedwars.Roact.mount(create('BillboardGui', {
	                Size = UDim2.fromOffset(249, 102),
	                StudsOffset = Vector3.new(0, 2.5, 0),
	                Adornee = part,
	                MaxDistance = 40,
	                AlwaysOnTop = true
	            }, {
	                create('Frame', {
	                    Size = UDim2.fromOffset(160, 50),
	                    Position = UDim2.fromOffset(44, 32),
	                    BackgroundColor3 = Color3.new(),
	                    BackgroundTransparency = 0.5
	                }, {
	                    create('UICorner', {CornerRadius = UDim.new(0, 5)}),
	                    create('ImageLabel', {
	                        Size = UDim2.new(1, 89, 1, 52),
	                        Position = UDim2.fromOffset(-48, -31),
	                        BackgroundTransparency = 1,
	                        Image = getcustomasset('catsix/assets/new/blur.png'),
	                        ScaleType = Enum.ScaleType.Slice,
	                        SliceCenter = Rect.new(52, 31, 261, 502)
	                    }),
	                    create('TextLabel', {
	                        Size = UDim2.fromOffset(145, 14),
	                        Position = UDim2.fromOffset(13, 12),
	                        BackgroundTransparency = 1,
	                        Text = bedwars.ItemMeta[block.Name].displayName or block.Name,
	                        TextXAlignment = Enum.TextXAlignment.Left,
	                        TextYAlignment = Enum.TextYAlignment.Top,
	                        TextColor3 = Color3.new(),
	                        TextScaled = true,
	                        Font = Enum.Font.Arial
	                    }),
	                    create('TextLabel', {
	                        Size = UDim2.fromOffset(145, 14),
	                        Position = UDim2.fromOffset(12, 11),
	                        BackgroundTransparency = 1,
	                        Text = bedwars.ItemMeta[block.Name].displayName or block.Name,
	                        TextXAlignment = Enum.TextXAlignment.Left,
	                        TextYAlignment = Enum.TextYAlignment.Top,
	                        TextColor3 = color.Dark(uipallet.Text, 0.16),
	                        TextScaled = true,
	                        Font = Enum.Font.Arial
	                    }),
	                    create('Frame', {
	                        Size = UDim2.fromOffset(138, 4),
	                        Position = UDim2.fromOffset(12, 32),
	                        BackgroundColor3 = uipallet.Main
	                    }, {
	                        create('UICorner', {CornerRadius = UDim.new(1, 0)}),
	                        create('Frame', {
	                            [bedwars.Roact.Ref] = self.blockHealthbar.healthbarProgressRef,
	                            Size = UDim2.fromScale(percent, 1),
	                            BackgroundColor3 = Color3.fromHSV(math.clamp(percent / 2.5, 0, 1), 0.89, 0.75)
	                        }, {create('UICorner', {CornerRadius = UDim.new(1, 0)})})
	                    })
	                })
	            }), part)
	
	            self.maid:GiveTask(function()
	                cleanCheck = false
	                self.healthbarBlockRef = nil
	                bedwars.Roact.unmount(mounted)
	                if self.healthbarPart then
	                    self.healthbarPart:Destroy()
	                end
	                self.healthbarPart = nil
	            end)
	
	            bedwars.RuntimeLib.Promise.delay(5):andThen(function()
	                if cleanCheck then
	                    self.maid:DoCleaning()
	                end
	            end)
	        end
	
	        local newpercent = math.clamp((health - changeHealth) / maxHealth, 0, 1)
	        tweenService:Create(self.blockHealthbar.healthbarProgressRef:getValue(), TweenInfo.new(0.3), {
	            Size = UDim2.fromScale(newpercent, 1), BackgroundColor3 = Color3.fromHSV(math.clamp(newpercent / 2.5, 0, 1), 0.89, 0.75)
	        }):Play()
	    end, function(...)
	        if shared.VapeDeveloper then
	            warn(...)
	        end
	    end)
	end
	
	local hit = 0
	
	local function attemptBreak(tab, localPosition)
		if not tab then return end
		for _, v in tab do
			if (v.Position - localPosition).Magnitude < Range.Value and bedwars.BlockController:isBlockBreakable({blockPosition = v.Position / 3}, lplr) then
				if not SelfBreak.Enabled and v:GetAttribute('PlacedByUserId') == lplr.UserId then continue end
				if (v:GetAttribute('BedShieldEndTime') or 0) > workspace:GetServerTimeNow() then continue end
				if LimitItem.Enabled and not (store.hand.tool and bedwars.ItemMeta[store.hand.tool.Name].breakBlock) then continue end
	
				hit += 1
				local target, path, endpos = bedwars.breakBlock(v, Effect.Enabled, Animation.Enabled, CustomHealth.Enabled and customHealthbar or nil, AutoTool.Enabled, Wallcheck.Enabled, breakmethods[Mode.Value])
				if path then
					local currentnode = target
					for _, part in parts do
						part.Position = currentnode or Vector3.zero
						if currentnode then
							part.BoxHandleAdornment.Color3 = currentnode == endpos and Color3.new(1, 0.2, 0.2) or currentnode == target and Color3.new(0.2, 0.2, 1) or Color3.new(0.2, 1, 0.2)
						end
						currentnode = path[currentnode]
					end
				end
	
				task.wait(InstantBreak.Enabled and (store.damageBlockFail > tick() and 4.5 or 0) or BreakSpeed.Value)
	
				return true
			end
		end
	
		return false
	end
	
	Breaker = vape.Categories.Minigames:CreateModule({
		Name = 'Breaker',
		Function = function(callback)
			if callback then
				for _ = 1, 30 do
					local part = Instance.new('Part')
					part.Anchored = true
					part.CanQuery = false
					part.CanCollide = false
					part.Transparency = 1
					part.Parent = gameCamera
					local highlight = Instance.new('BoxHandleAdornment')
					highlight.Size = Vector3.one
					highlight.AlwaysOnTop = true
					highlight.ZIndex = 1
					highlight.Transparency = 0.5
					highlight.Adornee = part
					highlight.Parent = part
					table.insert(parts, part)
				end
	
				local beds = collection('bed', Breaker)
				local teslas = collection('tesla-trap', Breaker, function(tab, obj)
	                task.delay(0.1, function()
	                    if not Breaker.Enabled or not obj.Parent then return end
	                    local player = playersService:GetPlayerByUserId(obj:GetAttribute('PlacedByUserId'))
	                    if player and player:GetAttribute('Team') ~= lplr:GetAttribute('Team') then
	                        table.insert(tab, obj)
	                    end
	                end)
	            end)
				local hives = collection('beehive', Breaker, function(tab, obj)
	                task.delay(0.1, function()
	                    if not Breaker.Enabled or not obj.Parent then return end
	                    local player = playersService:GetPlayerByUserId(obj:GetAttribute('PlacedByUserId'))
	                    if player and player:GetAttribute('Team') ~= lplr:GetAttribute('Team') then
	                        table.insert(tab, obj)
	                    end
	                end)
	            end)
				local luckyblock = collection('LuckyBlock', Breaker)
				local ironores = collection('iron_ore_mesh_block', Breaker)
				customlist = collection('block', Breaker, function(tab, obj)
					if table.find(Custom.ListEnabled, obj.Name) then
						table.insert(tab, obj)
					end
				end)
	
				repeat
					task.wait(1 / UpdateRate.Value)
					if not Breaker.Enabled then break end
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
	
						if attemptBreak(Bed.Enabled and beds, localPosition) then continue end
						if attemptBreak(Hive.Enabled and hives, localPosition) then continue end
						if attemptBreak(Tesla.Enabled and teslas, localPosition) then continue end
						if attemptBreak(customlist, localPosition) then continue end
						if attemptBreak(LuckyBlock.Enabled and luckyblock, localPosition) then continue end
						if attemptBreak(IronOre.Enabled and ironores, localPosition) then continue end
	
						for _, v in parts do
							v.Position = Vector3.zero
						end
					end
				until not Breaker.Enabled
			else
				for _, v in parts do
					v:ClearAllChildren()
					v:Destroy()
				end
				table.clear(parts)
			end
		end,
		Tooltip = 'Break blocks around you automatically'
	})
	Mode = Breaker:CreateDropdown({
		Name = 'Break mode',
		List = {'Health', 'Distance'},
		Default = 'Health'
	})
	Range = Breaker:CreateSlider({
		Name = 'Break range',
		Min = 1,
		Max = 30,
		Default = 30,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	BreakSpeed = Breaker:CreateSlider({
		Name = 'Break speed',
		Min = 0,
		Max = 0.3,
		Default = 0.25,
		Decimal = 100,
		Suffix = 'seconds'
	})
	UpdateRate = Breaker:CreateSlider({
		Name = 'Update rate',
		Min = 1,
		Max = 120,
		Default = 60,
		Suffix = 'hz'
	})
	Custom = Breaker:CreateTextList({
		Name = 'Custom',
		Function = function()
			if not customlist then return end
			table.clear(customlist)
			for _, obj in store.blocks do
				if table.find(Custom.ListEnabled, obj.Name) then
					table.insert(customlist, obj)
				end
			end
		end
	})
	Bed = Breaker:CreateToggle({
		Name = 'Break Bed',
		Default = true
	})
	Tesla = Breaker:CreateToggle({
	    Name = 'Break Tesla',
	    Default = true
	})
	Hive = Breaker:CreateToggle({
	    Name = 'Break Hive',
	    Default = true
	})
	LuckyBlock = Breaker:CreateToggle({
		Name = 'Break Lucky Block',
		Default = true
	})
	IronOre = Breaker:CreateToggle({
		Name = 'Break Iron Ore',
		Default = true
	})
	Effect = Breaker:CreateToggle({
		Name = 'Show Healthbar & Effects',
		Function = function(callback)
			if CustomHealth.Object then
				CustomHealth.Object.Visible = callback
			end
		end,
		Default = true
	})
	CustomHealth = Breaker:CreateToggle({
		Name = 'Custom Healthbar',
		Default = true,
		Darker = true
	})
	Animation = Breaker:CreateToggle({Name = 'Animation'})
	SelfBreak = Breaker:CreateToggle({Name = 'Self Break'})
	InstantBreak = Breaker:CreateToggle({Name = 'Instant Break'})
	Wallcheck = Breaker:CreateToggle({
		Name = 'Legit mode',
		Default = true,
		Tooltip = 'Checks for blocks inside the bed instead of directly targetting bed'
	})
	AutoTool = Breaker:CreateToggle({
		Name = 'Auto Tool',
		Tooltip = 'Visualises tool switching on ur client'
	})
	LimitItem = Breaker:CreateToggle({
		Name = 'Limit to items',
		Tooltip = 'Only breaks when tools are held'
	})
end)

run(function()
	local FishermanSpy
	local Teammates
	
	FishermanSpy = vape.Categories.Minigames:CreateModule({
		Name = 'FishermanSpy',
		Function = function(call)
			if call then
				FishermanSpy:Clean(bedwars.Handler:Get('FishCaught').Remote:Connect(function(data)
					if data.dropData and data.dropData.drops and data.catchingPlayer then
						local text = {}
						for _, v in data.dropData.drops do
							local itemDisplay = bedwars.ItemMeta[v.itemType] and bedwars.ItemMeta[v.itemType].displayName or v.itemType
							table.insert(text, `{v.amount} {itemDisplay:lower()}{v.amount >= 2 and 's' or ''}`)
						end
	
						if #text > 0 and (not Teammates.Enabled or lplr.Team ~= data.catchingPlayer.Team) then
							notif('FishermanSpy', `{data.catchingPlayer.Name} caught {table.concat(text, ', ')}`, 20, 'info')
						end
					end
				end))
			end
		end
	})
	
	Teammates = FishermanSpy:CreateToggle({
		Name = 'Ignore teammate',
		Default = true
	})
end)

run(function()
	local AutoPickpocket
	local Targets
	local Range
	
	local Legit = getFunctionRange(bedwars.MimicController.onKitLocalActivated) or 25
	local mimicPickPocket = bedwars.Handler:Get('MimicBlockPickPocketPlayer')
	
	AutoPickpocket = vape.Categories.Minigames:CreateModule({
	    Name = 'AutoPickpocket',
	    Function = function(callback)
	        if callback then
	            local list = {bedwars.SoundList.MIMIC_PICKPOCKET_1, bedwars.SoundList.MIMIC_PICKPOCKET_2, bedwars.SoundList.MIMIC_PICKPOCKET_3}
	            repeat
	                if entitylib.isAlive then
	                    local localPosition = entitylib.character.RootPart.Position
	                    local plrs = entitylib.AllPosition({
	                        Range = Range.Value,
	                        Origin = localPosition,
	                        Wallcheck = Targets.Walls.Enabled or nil,
	                        Part = 'RootPart',
	                        Players = true,
	                        Sort = sortmethods.Distance
	                    })
	                    for _, v in plrs do
	                        if mimicPickPocket:Fire('CallServer', v.Player) then
	                            bedwars.SoundManager:playSound(list[Random.new(os.clock())(1, 3)], {
	                                playbackSpeedMultiplier = 1.27,
	                                position = localPosition
	                            })
	                        end
	                    end
	                end
	                task.wait(0.1)
	            until not AutoPickpocket.Enabled
	        end
	    end,
	    Tooltip = 'Automatically pickpockets with milo kit.'
	})
	
	Targets = AutoPickpocket:CreateTargets({Players = true, Walls = true})
	Range = AutoPickpocket:CreateSlider({
	    Name = 'Range',
	    Min = 1,
	    Max = 30,
	    Default = Legit,
	    Suffix = function(val)
	        return val <= 1 and 'stud' or 'studs'
	    end
	})
	AutoPickpocket:CreateButton({
		Name = 'Sync to legit range',
		Function = function()
			Range:SetValue(Legit)
		end
	})
end)

run(function()
	local BedBreakEffect
	local Mode
	local List
	local NameToId = {}
	
	BedBreakEffect = vape.Legit:CreateModule({
		Name = 'Bed Break Effect',
		Function = function(callback)
			if callback then
	            BedBreakEffect:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function(data)
	                firesignal(bedwars.Handler:Get('BedBreakEffectTriggered').Remote.instance.OnClientEvent, {
	                    player = data.player,
	                    position = data.bedBlockPosition * 3,
	                    effectType = NameToId[List.Value],
	                    teamId = data.brokenBedTeam.id,
	                    centerBedPosition = data.bedBlockPosition * 3
	                })
	            end))
	        end
		end,
		Tooltip = 'Custom bed break effects'
	})
	local BreakEffectName = {}
	for i, v in bedwars.BedBreakEffectMeta do
		table.insert(BreakEffectName, v.name)
		NameToId[v.name] = i
	end
	table.sort(BreakEffectName)
	List = BedBreakEffect:CreateDropdown({
		Name = 'Effect',
		List = BreakEffectName
	})
end)

run(function()
	vape.Legit:CreateModule({
		Name = 'Clean Kit',
		Function = function(callback)
			if callback then
				bedwars.WindWalkerController.spawnOrb = function() end
				local zephyreffect = lplr.PlayerGui:FindFirstChild('WindWalkerEffect', true)
				if zephyreffect then 
					zephyreffect.Visible = false 
				end
			end
		end,
		Tooltip = 'Removes zephyr status indicator'
	})
end)

run(function()
	local old
	local Image
	
	local Crosshair = vape.Legit:CreateModule({
		Name = 'Crosshair',
		Function = function(callback)
			if callback then
				old = debug.getconstant(bedwars.ViewmodelController.showCrosshair, 25)
				debug.setconstant(bedwars.ViewmodelController.showCrosshair, 25, Image.Value)
				debug.setconstant(bedwars.ViewmodelController.showCrosshair, 37, Image.Value)
			else
				debug.setconstant(bedwars.ViewmodelController.showCrosshair, 25, old)
				debug.setconstant(bedwars.ViewmodelController.showCrosshair, 37, old)
				old = nil
			end
	
			if bedwars.ViewmodelController.crosshair then
				bedwars.ViewmodelController:hideCrosshair()
				bedwars.ViewmodelController:showCrosshair()
			end
		end,
		Tooltip = 'Custom first person crosshair depending on the image choosen.'
	})
	Image = Crosshair:CreateTextBox({
		Name = 'Image',
		Placeholder = 'image id (roblox)',
		Function = function(enter)
			if enter and Crosshair.Enabled then
				Crosshair:Toggle()
				Crosshair:Toggle()
			end
		end
	})
end)

run(function()
	local DamageIndicator
	local FontOption
	local Color
	local Size
	local Anchor
	local Stroke
	local suc, tab = pcall(function()
		return debug.getupvalue(bedwars.DamageIndicator, 2)
	end)
	tab = suc and tab or {}
	local oldvalues, oldfont = {}
	
	DamageIndicator = vape.Legit:CreateModule({
		Name = 'Damage Indicator',
		Function = function(callback)
			if callback then
				oldvalues = table.clone(tab)
				oldfont = debug.getconstant(bedwars.DamageIndicator, 87)
				debug.setconstant(bedwars.DamageIndicator, 86, Enum.Font[FontOption.Value])
				debug.setconstant(bedwars.DamageIndicator, 119, Stroke.Enabled and 'Thickness' or 'Enabled')
				tab.strokeThickness = Stroke.Enabled and 1 or false
				tab.textSize = Size.Value
				tab.blowUpSize = Size.Value
				tab.blowUpDuration = 0
				tab.baseColor = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
				tab.blowUpCompleteDuration = 0
				tab.anchoredDuration = Anchor.Value
			else
				for i, v in oldvalues do
					tab[i] = v
				end
				debug.setconstant(bedwars.DamageIndicator, 87, oldfont)
				debug.setconstant(bedwars.DamageIndicator, 119, 'Thickness')
			end
		end,
		Tooltip = 'Customize the damage indicator'
	})
	local fontitems = {'GothamBlack'}
	for _, v in Enum.Font:GetEnumItems() do
		if v.Name ~= 'GothamBlack' then
			table.insert(fontitems, v.Name)
		end
	end
	FontOption = DamageIndicator:CreateDropdown({
		Name = 'Font',
		List = fontitems,
		Function = function(val)
			if DamageIndicator.Enabled then
				debug.setconstant(bedwars.DamageIndicator, 86, Enum.Font[val])
			end
		end
	})
	Color = DamageIndicator:CreateColorSlider({
		Name = 'Color',
		DefaultHue = 0,
		Function = function(hue, sat, val)
			if DamageIndicator.Enabled then
				tab.baseColor = Color3.fromHSV(hue, sat, val)
			end
		end
	})
	Size = DamageIndicator:CreateSlider({
		Name = 'Size',
		Min = 1,
		Max = 32,
		Default = 32,
		Function = function(val)
			if DamageIndicator.Enabled then
				tab.textSize = val
				tab.blowUpSize = val
			end
		end
	})
	Anchor = DamageIndicator:CreateSlider({
		Name = 'Anchor',
		Min = 0,
		Max = 1,
		Decimal = 10,
		Function = function(val)
			if DamageIndicator.Enabled then
				tab.anchoredDuration = val
			end
		end
	})
	Stroke = DamageIndicator:CreateToggle({
		Name = 'Stroke',
		Function = function(callback)
			if DamageIndicator.Enabled then
				debug.setconstant(bedwars.DamageIndicator, 119, callback and 'Thickness' or 'Enabled')
				tab.strokeThickness = callback and 1 or false
			end
		end
	})
end)

run(function()
	local FOV
	local Value
	local old, old2
	
	FOV = vape.Legit:CreateModule({
		Name = 'FOV',
		Function = function(callback)
			if callback then
				old = bedwars.FovController.setFOV
				old2 = bedwars.FovController.getFOV
				bedwars.FovController.setFOV = function(self) 
					return old(self, Value.Value) 
				end
				bedwars.FovController.getFOV = function() 
					return Value.Value 
				end
			else
				bedwars.FovController.setFOV = old
				bedwars.FovController.getFOV = old2
			end
			
			bedwars.FovController:setFOV(bedwars.Store:getState().Settings.fov)
		end,
		Tooltip = 'Adjusts camera vision'
	})
	Value = FOV:CreateSlider({
		Name = 'FOV',
		Min = 30,
		Max = 120
	})
end)

run(function()
	local FPSBoost
	local Kill
	local Visualizer
	local effects, util = {}, {}
	
	FPSBoost = vape.Legit:CreateModule({
		Name = 'FPS Boost',
		Function = function(callback)
			if callback then
				if Kill.Enabled then
					for i, v in bedwars.KillEffectController.killEffects do
						if not i:find('Custom') then
							effects[i] = v
							bedwars.KillEffectController.killEffects[i] = {
								new = function() 
									return {
										onKill = function() end, 
										isPlayDefaultKillEffect = function() 
											return true 
										end
									} 
								end
							}
						end
					end
				end
	
				if Visualizer.Enabled then
					for i, v in bedwars.VisualizerUtils do
						util[i] = v
						bedwars.VisualizerUtils[i] = function() end
					end
				end
	
				repeat task.wait() until store.matchState ~= 0
				if not bedwars.AppController then return end
				bedwars.NametagController.addGameNametag = function() end
				for _, v in bedwars.AppController:getOpenApps() do
					if tostring(v):find('Nametag') then
						bedwars.AppController:closeApp(tostring(v))
					end
				end
			else
				for i, v in effects do 
					bedwars.KillEffectController.killEffects[i] = v 
				end
				for i, v in util do 
					bedwars.VisualizerUtils[i] = v 
				end
				table.clear(effects)
				table.clear(util)
			end
		end,
		Tooltip = 'Improves the framerate by turning off certain effects'
	})
	Kill = FPSBoost:CreateToggle({
		Name = 'Kill Effects',
		Function = function()
			if FPSBoost.Enabled then
				FPSBoost:Toggle()
				FPSBoost:Toggle()
			end
		end,
		Default = true
	})
	Visualizer = FPSBoost:CreateToggle({
		Name = 'Visualizer',
		Function = function()
			if FPSBoost.Enabled then
				FPSBoost:Toggle()
				FPSBoost:Toggle()
			end
		end,
		Default = true
	})
end)

run(function()
	local HitColor
	local Color
	local done = {}
	
	HitColor = vape.Legit:CreateModule({
		Name = 'Hit Color',
		Function = function(callback)
			if callback then 
				repeat
					for i, v in entitylib.List do 
						local highlight = v.Character and v.Character:FindFirstChild('_DamageHighlight_')
						if highlight then 
							if not table.find(done, highlight) then 
								table.insert(done, highlight) 
							end
							highlight.FillColor = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
							highlight.FillTransparency = Color.Opacity
						end
					end
					task.wait(0.1)
				until not HitColor.Enabled
			else
				for i, v in done do 
					v.FillColor = Color3.new(1, 0, 0)
					v.FillTransparency = 0.4
				end
				table.clear(done)
			end
		end,
		Tooltip = 'Customize the hit highlight options'
	})
	Color = HitColor:CreateColorSlider({
		Name = 'Color',
		DefaultOpacity = 0.4
	})
end)

run(function()
	vape.Legit:CreateModule({
		Name = 'HitFix',
		Function = function(callback)
			debug.setconstant(bedwars.SwordController.swingSwordAtMouse, 23, callback and 'raycast' or 'Raycast')
			debug.setupvalue(bedwars.SwordController.swingSwordAtMouse, 4, callback and bedwars.QueryUtil or workspace)
		end,
		Tooltip = 'Changes the raycast function to the correct one'
	})
end)

run(function()
	local Interface
	local HotbarOpenInventory = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-open-inventory']).HotbarOpenInventory
	local HotbarHealthbar = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar['hotbar-healthbar']).HotbarHealthbar
	local HotbarApp = getRoactRender(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-app']).HotbarApp.render)
	local old, new = {}, {}
	
	vape:Clean(function()
		for _, v in new do
			table.clear(v)
		end
		for _, v in old do
			table.clear(v)
		end
		table.clear(new)
		table.clear(old)
	end)
	
	local function modifyconstant(func, ind, val)
		if not func then return end
		if not old[func] then old[func] = {} end
		if not new[func] then new[func] = {} end
		if not old[func][ind] then
			old[func][ind] = debug.getconstant(func, ind)
		end
		if typeof(old[func][ind]) ~= typeof(val) then return end
		new[func][ind] = val
	
		if Interface.Enabled then
			if val then
				debug.setconstant(func, ind, val)
			else
				debug.setconstant(func, ind, old[func][ind])
				old[func][ind] = nil
			end
		end
	end
	
	Interface = vape.Legit:CreateModule({
		Name = 'Interface',
		Function = function(callback)
			for i, v in (callback and new or old) do
				for i2, v2 in v do
					debug.setconstant(i, i2, v2)
				end
			end
		end,
		Tooltip = 'Customize bedwars UI'
	})
	local fontitems = {'LuckiestGuy'}
	for _, v in Enum.Font:GetEnumItems() do
		if v.Name ~= 'LuckiestGuy' then
			table.insert(fontitems, v.Name)
		end
	end
	Interface:CreateDropdown({
		Name = 'Health Font',
		List = fontitems,
		Function = function(val)
			modifyconstant(HotbarHealthbar.render, 77, val)
		end
	})
	Interface:CreateColorSlider({
		Name = 'Health Color',
		Function = function(hue, sat, val)
			modifyconstant(HotbarHealthbar.render, 16, tonumber(Color3.fromHSV(hue, sat, val):ToHex(), 16))
			if Interface.Enabled then
				local hotbar = lplr.PlayerGui:FindFirstChild('hotbar')
				hotbar = hotbar and hotbar:FindFirstChild('HealthbarProgressWrapper', true)
				if hotbar then
					hotbar['1'].BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				end
			end
		end
	})
	Interface:CreateColorSlider({
		Name = 'Hotbar Color',
		DefaultOpacity = 0.8,
		Function = function(hue, sat, val, opacity)
			local func = oldinvrender or HotbarOpenInventory.render
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 51, tonumber(Color3.fromHSV(hue, sat, val):ToHex(), 16))
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 58, tonumber(Color3.fromHSV(hue, sat, math.clamp(val > 0.5 and val - 0.2 or val + 0.2, 0, 1)):ToHex(), 16))
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 54, 1 - opacity)
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 55, math.clamp(1.2 - opacity, 0, 1))
			modifyconstant(func, 31, tonumber(Color3.fromHSV(hue, sat, val):ToHex(), 16))
			modifyconstant(func, 32, math.clamp(1.2 - opacity, 0, 1))
			modifyconstant(func, 34, tonumber(Color3.fromHSV(hue, sat, math.clamp(val > 0.5 and val - 0.2 or val + 0.2, 0, 1)):ToHex(), 16))
		end
	})
end)

run(function()
	local KillEffect
	local Mode
	local List
	local NameToId = {}
	
	local killeffects = {
		Gravity = function(_, _, char, _)
			char:BreakJoints()
			local highlight = char:FindFirstChildWhichIsA('Highlight')
			local nametag = char:FindFirstChild('Nametag', true)
			if highlight then
				highlight:Destroy()
			end
			if nametag then
				nametag:Destroy()
			end
	
			task.spawn(function()
				local partvelo = {}
				for _, v in char:GetDescendants() do
					if v:IsA('BasePart') then
						partvelo[v.Name] = v.Velocity
					end
				end
				char.Archivable = true
				local clone = char:Clone()
				clone.Humanoid.Health = 100
				clone.Parent = workspace
				game:GetService('Debris'):AddItem(clone, 30)
				char:Destroy()
				task.wait(0.01)
				clone.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				clone:BreakJoints()
				task.wait(0.01)
				for _, v in clone:GetDescendants() do
					if v:IsA('BasePart') then
						local bodyforce = Instance.new('BodyForce')
						bodyforce.Force = Vector3.new(0, (workspace.Gravity - 10) * v:GetMass(), 0)
						bodyforce.Parent = v
						v.CanCollide = true
						v.Velocity = partvelo[v.Name] or Vector3.zero
					end
				end
			end)
		end,
		Lightning = function(_, _, char, _)
			char:BreakJoints()
			local highlight = char:FindFirstChildWhichIsA('Highlight')
			if highlight then
				highlight:Destroy()
			end
			local startpos = 1125
			local startcf = char.PrimaryPart.CFrame.p - Vector3.new(0, 8, 0)
			local newpos = Vector3.new((math.random(1, 10) - 5) * 2, startpos, (math.random(1, 10) - 5) * 2)
	
			for i = startpos - 75, 0, -75 do
				local newpos2 = Vector3.new((math.random(1, 10) - 5) * 2, i, (math.random(1, 10) - 5) * 2)
				if i == 0 then
					newpos2 = Vector3.zero
				end
				local part = Instance.new('Part')
				part.Size = Vector3.new(1.5, 1.5, 77)
				part.Material = Enum.Material.SmoothPlastic
				part.Anchored = true
				part.Material = Enum.Material.Neon
				part.CanCollide = false
				part.CFrame = CFrame.new(startcf + newpos + ((newpos2 - newpos) * 0.5), startcf + newpos2)
				part.Parent = workspace
				local part2 = part:Clone()
				part2.Size = Vector3.new(3, 3, 78)
				part2.Color = Color3.new(0.7, 0.7, 0.7)
				part2.Transparency = 0.7
				part2.Material = Enum.Material.SmoothPlastic
				part2.Parent = workspace
				game:GetService('Debris'):AddItem(part, 0.5)
				game:GetService('Debris'):AddItem(part2, 0.5)
				bedwars.QueryUtil:setQueryIgnored(part, true)
				bedwars.QueryUtil:setQueryIgnored(part2, true)
				if i == 0 then
					local soundpart = Instance.new('Part')
					soundpart.Transparency = 1
					soundpart.Anchored = true
					soundpart.Size = Vector3.zero
					soundpart.Position = startcf
					soundpart.Parent = workspace
					bedwars.QueryUtil:setQueryIgnored(soundpart, true)
					local sound = Instance.new('Sound')
					sound.SoundId = 'rbxassetid://6993372814'
					sound.Volume = 2
					sound.Pitch = 0.5 + (math.random(1, 3) / 10)
					sound.Parent = soundpart
					sound:Play()
					sound.Ended:Connect(function()
						soundpart:Destroy()
					end)
				end
				newpos = newpos2
			end
		end,
		Delete = function(_, _, char, _)
			char:Destroy()
		end
	}
	
	KillEffect = vape.Legit:CreateModule({
		Name = 'Kill Effect',
		Function = function(callback)
			if callback then
				for i, v in killeffects do
					bedwars.KillEffectController.killEffects['Custom'..i] = {
						new = function()
							return {
								onKill = v,
								isPlayDefaultKillEffect = function()
									return false
								end
							}
						end
					}
				end
				KillEffect:Clean(lplr:GetAttributeChangedSignal('KillEffectType'):Connect(function()
					lplr:SetAttribute('KillEffectType', Mode.Value == 'Bedwars' and NameToId[List.Value] or 'Custom'..Mode.Value)
				end))
				lplr:SetAttribute('KillEffectType', Mode.Value == 'Bedwars' and NameToId[List.Value] or 'Custom'..Mode.Value)
			else
				for i in killeffects do
					bedwars.KillEffectController.killEffects['Custom'..i] = nil
				end
				lplr:SetAttribute('KillEffectType', 'default')
			end
		end,
		Tooltip = 'Custom final kill effects'
	})
	local modes = {'Bedwars'}
	for i in killeffects do
		table.insert(modes, i)
	end
	Mode = KillEffect:CreateDropdown({
		Name = 'Mode',
		List = modes,
		Function = function(val)
			List.Object.Visible = val == 'Bedwars'
			if KillEffect.Enabled then
				lplr:SetAttribute('KillEffectType', val == 'Bedwars' and NameToId[List.Value] or 'Custom'..val)
			end
		end
	})
	local KillEffectName = {}
	for i, v in bedwars.KillEffectMeta do
		table.insert(KillEffectName, v.name)
		NameToId[v.name] = i
	end
	table.sort(KillEffectName)
	List = KillEffect:CreateDropdown({
		Name = 'Bedwars',
		List = KillEffectName,
		Function = function(val)
			if KillEffect.Enabled then
				lplr:SetAttribute('KillEffectType', NameToId[val])
			end
		end,
		Darker = true
	})
end)

run(function()
	local Ping
	local label

	Ping = vape.Legit:CreateModule({
		Name = 'Ping',
		Function = function(callback)
			if callback then
				repeat
					label.Text = math.floor((store.ping.total or 0) * 1000)..' ms'
					task.wait(1)
				until not Ping.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41),
		Tooltip = 'Shows the current connection speed to the game server'
	})
	Ping:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	Ping:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.new(0, 100, 0, 41)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = '0 ms'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = Ping.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
task.spawn(function()
	local incoming
	repeat
		if not incoming then
			incoming = os.clock()
			task.spawn(function()
				bedwars.Handler:Get('TridentUnanchor'):Fire('CallServer')
				store.ping.total = os.clock() - incoming
				incoming = nil
			end)
		end
		store.ping.incoming = os.clock() - incoming
		task.wait(1)
	until vape.Loaded == nil
end)

run(function()
	local ReachDisplay
	local label
	
	ReachDisplay = vape.Legit:CreateModule({
		Name = 'Reach Display',
		Function = function(callback)
			if callback then
				repeat
					label.Text = (store.attackReachUpdate > tick() and store.attackReach or '0.00')..' studs'
					task.wait(0.4)
				until not ReachDisplay.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41)
	})
	ReachDisplay:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	ReachDisplay:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = '0.00 studs'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = ReachDisplay.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)

run(function()
	local SongBeats
	local List
	local FOV
	local FOVValue = {}
	local Volume
	local alreadypicked = {}
	local beattick = tick()
	local oldfov, songobj, songbpm, songtween
	
	local function choosesong()
		local list = List.ListEnabled
		if #alreadypicked >= #list then 
			table.clear(alreadypicked) 
		end
	
		if #list <= 0 then
			notif('SongBeats', 'no songs', 10)
			SongBeats:Toggle()
			return
		end
	
		local chosensong = list[math.random(1, #list)]
		if #list > 1 and table.find(alreadypicked, chosensong) then
			repeat 
				task.wait() 
				chosensong = list[math.random(1, #list)] 
			until not table.find(alreadypicked, chosensong) or not SongBeats.Enabled
		end
		if not SongBeats.Enabled then return end
	
		local split = chosensong:split('/')
		if not isfile(split[1]) then
			notif('SongBeats', 'Missing song ('..split[1]..')', 10)
			SongBeats:Toggle()
			return
		end
	
		songobj.SoundId = assetfunction(split[1])
		repeat task.wait() until songobj.IsLoaded or not SongBeats.Enabled
		if SongBeats.Enabled then
			beattick = tick() + (tonumber(split[3]) or 0)
			songbpm = 60 / (tonumber(split[2]) or 50)
			songobj:Play()
		end
	end
	
	SongBeats = vape.Legit:CreateModule({
		Name = 'Song Beats',
		Function = function(callback)
			if callback then
				songobj = Instance.new('Sound')
				songobj.Volume = Volume.Value / 100
				songobj.Parent = workspace
				repeat
					if not songobj.Playing then choosesong() end
					if beattick < tick() and SongBeats.Enabled and FOV.Enabled then
						beattick = tick() + songbpm
						oldfov = math.min(bedwars.FovController:getFOV() * (bedwars.SprintController.sprinting and 1.1 or 1), 120)
						gameCamera.FieldOfView = oldfov - FOVValue.Value
						songtween = tweenService:Create(gameCamera, TweenInfo.new(math.min(songbpm, 0.2), Enum.EasingStyle.Linear), {FieldOfView = oldfov})
						songtween:Play()
					end
					task.wait()
				until not SongBeats.Enabled
			else
				if songobj then
					songobj:Destroy()
				end
				if songtween then
					songtween:Cancel()
				end
				if oldfov then
					gameCamera.FieldOfView = oldfov
				end
				table.clear(alreadypicked)
			end
		end,
		Tooltip = 'Built in mp3 player'
	})
	List = SongBeats:CreateTextList({
		Name = 'Songs',
		Placeholder = 'filepath/bpm/start'
	})
	FOV = SongBeats:CreateToggle({
		Name = 'Beat FOV',
		Function = function(callback)
			if FOVValue.Object then
				FOVValue.Object.Visible = callback
			end
			if SongBeats.Enabled then
				SongBeats:Toggle()
				SongBeats:Toggle()
			end
		end,
		Default = true
	})
	FOVValue = SongBeats:CreateSlider({
		Name = 'Adjustment',
		Min = 1,
		Max = 30,
		Default = 5,
		Darker = true
	})
	Volume = SongBeats:CreateSlider({
		Name = 'Volume',
		Function = function(val)
			if songobj then 
				songobj.Volume = val / 100 
			end
		end,
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
end)

run(function()
	local SoundChanger
	local List
	local soundlist = {}
	local old
	
	SoundChanger = vape.Legit:CreateModule({
		Name = 'SoundChanger',
		Function = function(callback)
			if callback then
				old = bedwars.SoundManager.playSound
				bedwars.SoundManager.playSound = function(self, id, ...)
					if soundlist[id] then
						id = soundlist[id]
					end
	
					return old(self, id, ...)
				end
			else
				bedwars.SoundManager.playSound = old
				old = nil
			end
		end,
		Tooltip = 'Change ingame sounds to custom ones.'
	})
	List = SoundChanger:CreateTextList({
		Name = 'Sounds',
		Placeholder = '(DAMAGE_1/ben.mp3)',
		Function = function()
			table.clear(soundlist)
			for _, entry in List.ListEnabled do
				local split = entry:split('/')
				local id = bedwars.SoundList[split[1]]
				if id and #split > 1 then
					soundlist[id] = split[2]:find('rbxasset') and split[2] or isfile(split[2]) and assetfunction(split[2]) or ''
				end
			end
		end
	})
end)

run(function()
	local UICleanup
	local OpenInv
	local KillFeed
	local OldTabList
	local HotbarApp = getRoactRender(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-app']).HotbarApp.render)
	local HotbarOpenInventory = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-open-inventory']).HotbarOpenInventory
	local old, new = {}, {}
	local oldkillfeed
	
	vape:Clean(function()
		for _, v in new do
			table.clear(v)
		end
		for _, v in old do
			table.clear(v)
		end
		table.clear(new)
		table.clear(old)
	end)
	
	local function modifyconstant(func, ind, val)
		if not old[func] then old[func] = {} end
		if not new[func] then new[func] = {} end
		if not old[func][ind] then
			local typing = type(old[func][ind])
			if typing == 'function' or typing == 'userdata' then return end
			old[func][ind] = debug.getconstant(func, ind)
		end
		if typeof(old[func][ind]) ~= typeof(val) and val ~= nil then return end
	
		new[func][ind] = val
		if UICleanup.Enabled then
			if val then
				debug.setconstant(func, ind, val)
			else
				debug.setconstant(func, ind, old[func][ind])
				old[func][ind] = nil
			end
		end
	end
	
	UICleanup = vape.Legit:CreateModule({
		Name = 'UI Cleanup',
		Function = function(callback)
			for i, v in (callback and new or old) do
				for i2, v2 in v do
					debug.setconstant(i, i2, v2)
				end
			end
			if callback then
				if OpenInv.Enabled then
					oldinvrender = HotbarOpenInventory.render
					HotbarOpenInventory.render = function()
						return bedwars.Roact.createElement('TextButton', {Visible = false}, {})
					end
				end
	
				if KillFeed.Enabled then
					oldkillfeed = bedwars.KillFeedController.addToKillFeed
					bedwars.KillFeedController.addToKillFeed = function() end
				end
	
				if OldTabList.Enabled then
					starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
				end
			else
				if oldinvrender then
					HotbarOpenInventory.render = oldinvrender
					oldinvrender = nil
				end
	
				if KillFeed.Enabled then
					bedwars.KillFeedController.addToKillFeed = oldkillfeed
					oldkillfeed = nil
				end
	
				if OldTabList.Enabled then
					starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
				end
			end
		end,
		Tooltip = 'Cleans up the UI for kits & main'
	})
	UICleanup:CreateToggle({
		Name = 'Resize Health',
		Function = function(callback)
			modifyconstant(HotbarApp, 60, callback and 1 or nil)
			modifyconstant(debug.getupvalue(HotbarApp, 15).render, 30, callback and 1 or nil)
			modifyconstant(debug.getupvalue(HotbarApp, 23).tweenPosition, 16, callback and 0 or nil)
		end,
		Default = true
	})
	UICleanup:CreateToggle({
		Name = 'No Hotbar Numbers',
		Function = function(callback)
			local func = oldinvrender or HotbarOpenInventory.render
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 90, callback and 0 or nil)
			modifyconstant(func, 71, callback and 0 or nil)
		end,
		Default = true
	})
	OpenInv = UICleanup:CreateToggle({
		Name = 'No Inventory Button',
		Function = function(callback)
			modifyconstant(HotbarApp, 78, callback and 0 or nil)
			if UICleanup.Enabled then
				if callback then
					oldinvrender = HotbarOpenInventory.render
					HotbarOpenInventory.render = function()
						return bedwars.Roact.createElement('TextButton', {Visible = false}, {})
					end
				else
					HotbarOpenInventory.render = oldinvrender
					oldinvrender = nil
				end
			end
		end,
		Default = true
	})
	KillFeed = UICleanup:CreateToggle({
		Name = 'No Kill Feed',
		Function = function(callback)
			if UICleanup.Enabled then
				if callback then
					oldkillfeed = bedwars.KillFeedController.addToKillFeed
					bedwars.KillFeedController.addToKillFeed = function() end
				else
					bedwars.KillFeedController.addToKillFeed = oldkillfeed
					oldkillfeed = nil
				end
			end
		end,
		Default = true
	})
	OldTabList = UICleanup:CreateToggle({
		Name = 'Old Player List',
		Function = function(callback)
			if UICleanup.Enabled then
				starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, callback)
			end
		end,
		Default = true
	})
	UICleanup:CreateToggle({
		Name = 'Fix Queue Card',
		Function = function(callback)
			modifyconstant(bedwars.QueueCard.render, 15, callback and 0.1 or nil)
		end,
		Default = true
	})
end)

run(function()
	local Viewmodel
	local Depth
	local Horizontal
	local Vertical
	local NoBob
	local Visuals
	local FillColor
	local OutlineColor
	local Rots = {}
	local Highlights = {}
	local old, oldc1
	
	local function highlightAccessory(accessory)
		local handle = accessory:FindFirstChild('Handle')
		if handle then
			local highlight = Instance.new('Highlight')
			highlight.Name = 'ViewmodelVisuals'
			highlight.FillColor = Color3.fromHSV(FillColor.Hue, FillColor.Sat, FillColor.Value)
			highlight.FillTransparency = FillColor.Opacity
			highlight.OutlineColor = Color3.fromHSV(OutlineColor.Hue, OutlineColor.Sat, OutlineColor.Value)
			highlight.OutlineTransparency = OutlineColor.Opacity
			highlight.Parent = handle
			Viewmodel:Clean(highlight)
			table.insert(Highlights, highlight)
		end
	end
	
	local function startVisuals()
		local viewmodel
		repeat
			viewmodel = gameCamera:FindFirstChild('Viewmodel')
			if viewmodel or not Viewmodel.Enabled then break end
			task.wait(0.1)
		until false
		if not viewmodel or not Viewmodel.Enabled then return end
	
		for _, v in viewmodel:GetChildren() do
			if v:IsA('Accessory') then
				highlightAccessory(v)
			end
		end
	
		Viewmodel:Clean(viewmodel.ChildAdded:Connect(function(v)
			for i = #Highlights, 1, -1 do
				if not Highlights[i].Parent then
					table.remove(Highlights, i)
				end
			end
			if v:IsA('Accessory') then
				highlightAccessory(v)
			end
		end))
		Viewmodel:Clean(gameCamera.ChildAdded:Connect(function(v)
			if v.Name == 'Viewmodel' then
				Viewmodel:Toggle()
				Viewmodel:Toggle()
			end
		end))
	end
	
	Viewmodel = vape.Legit:CreateModule({
		Name = 'Viewmodel',
		Function = function(callback)
			local viewmodel = gameCamera:FindFirstChild('Viewmodel')
			if callback then
				old = bedwars.ViewmodelController.playAnimation
				oldc1 = viewmodel and viewmodel.RightHand.RightWrist.C1 or CFrame.identity
				if NoBob.Enabled then
					bedwars.ViewmodelController.playAnimation = function(self, animtype, ...)
						if bedwars.AnimationType and animtype == bedwars.AnimationType.FP_WALK then return end
						return old(self, animtype, ...)
					end
				end
	
				bedwars.InventoryViewmodelController:handleStore(bedwars.Store:getState())
				if viewmodel then
					gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(Rots[1].Value), math.rad(Rots[2].Value), math.rad(Rots[3].Value))
				end
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', -Depth.Value)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', Horizontal.Value)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', Vertical.Value)
	
				if Visuals.Enabled then
					startVisuals()
				end
			else
				bedwars.ViewmodelController.playAnimation = old
				if viewmodel then
					viewmodel.RightHand.RightWrist.C1 = oldc1
				end
	
				bedwars.InventoryViewmodelController:handleStore(bedwars.Store:getState())
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', 0)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', 0)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', 0)
				table.clear(Highlights)
				old = nil
			end
		end,
		Tooltip = 'Changes the viewmodel animations and visuals'
	})
	Depth = Viewmodel:CreateSlider({
		Name = 'Depth',
		Min = 0,
		Max = 2,
		Default = 0.8,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', -val)
			end
		end
	})
	Horizontal = Viewmodel:CreateSlider({
		Name = 'Horizontal',
		Min = 0,
		Max = 2,
		Default = 0.8,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', val)
			end
		end
	})
	Vertical = Viewmodel:CreateSlider({
		Name = 'Vertical',
		Min = -0.2,
		Max = 2,
		Default = -0.2,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', val)
			end
		end
	})
	for _, name in {'Rotation X', 'Rotation Y', 'Rotation Z'} do
		table.insert(Rots, Viewmodel:CreateSlider({
			Name = name,
			Min = 0,
			Max = 360,
			Function = function(val)
				if Viewmodel.Enabled then
					gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(Rots[1].Value), math.rad(Rots[2].Value), math.rad(Rots[3].Value))
				end
			end
		}))
	end
	NoBob = Viewmodel:CreateToggle({
		Name = 'No Bobbing',
		Default = true,
		Function = function()
			if Viewmodel.Enabled then
				Viewmodel:Toggle()
				Viewmodel:Toggle()
			end
		end
	})
	Visuals = Viewmodel:CreateToggle({
		Name = 'Visuals',
		Tooltip = 'Highlights the item held in your viewmodel',
		Function = function(callback)
			FillColor.Object.Visible = callback
			OutlineColor.Object.Visible = callback
			if Viewmodel.Enabled then
				Viewmodel:Toggle()
				Viewmodel:Toggle()
			end
		end
	})
	FillColor = Viewmodel:CreateColorSlider({
		Name = 'Fill Color',
		DefaultSat = 0,
		DefaultOpacity = 0.5,
		Darker = true,
		Visible = false,
		Function = function(hue, sat, val, opacity)
			for _, v in Highlights do
				v.FillColor = Color3.fromHSV(hue, sat, val)
				v.FillTransparency = opacity
			end
		end
	})
	OutlineColor = Viewmodel:CreateColorSlider({
		Name = 'Outline Color',
		DefaultValue = 0,
		DefaultOpacity = 0,
		Darker = true,
		Visible = false,
		Function = function(hue, sat, val, opacity)
			for _, v in Highlights do
				v.OutlineColor = Color3.fromHSV(hue, sat, val)
				v.OutlineTransparency = opacity
			end
		end
	})
end)

run(function()
	local WinEffect
	local List
	local NameToId = {}
	
	WinEffect = vape.Legit:CreateModule({
		Name = 'WinEffect',
		Function = function(callback)
			if callback then
				WinEffect:Clean(vapeEvents.MatchEndEvent.Event:Connect(function()
					for i, v in getconnections(bedwars.Handler:Get('WinEffectTriggered').Remote.instance.OnClientEvent) do
						if v.Function then
							v.Function({
								winEffectType = NameToId[List.Value],
								winningPlayer = lplr
							})
						end
					end
				end))
			end
		end,
		Tooltip = 'Allows you to select any clientside win effect'
	})
	local WinEffectName = {}
	for i, v in bedwars.WinEffectMeta do
		table.insert(WinEffectName, v.name)
		NameToId[v.name] = i
	end
	table.sort(WinEffectName)
	List = WinEffect:CreateDropdown({
		Name = 'Effects',
		List = WinEffectName
	})
end)