local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catsix/profiles/commit.txt')..'/'..select(1, path:gsub('catsix/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
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
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local replicatedFirst = cloneref(game:GetService('ReplicatedFirst'))
local collectionService = cloneref(game:GetService('CollectionService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local runService = cloneref(game:GetService('RunService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local whitelist = vape.Libraries.whitelist
local drawingactor = loadstring(downloadFile('catsix/libraries/drawing.lua'), 'drawing')(...)
local redline = {Teams = {}}
local starttime = os.clock()
local TargetStrafeVector
local latestHash = 'c401462bc7f7f49e53b4a8da2de5b57bc2d7e14df1b773e5ccd1bcddb28db9c843b8902d2c93738a2f042e533d3d4971'
local redline_boxes = {
	{
		boxtype = 'redliner_melee',
		data = {
			size = Vector3.new(17.75, 14, 22),
			offset = CFrame.new(0, 0, -11)
		}
	},
	{
		boxtype = 'redliner_charged_melee',
		data = {
			size = Vector3.new(39, 14, 35),
			offset = CFrame.new(0, -0.5, -9)
		}
	}
}

local function addVelocity(velo)
	if redline[redline.MoveController] and typeof(redline[redline.MoveController][redline.LaunchpadFunction]) == 'function' then
		local pad = Instance.new('Model')
		local origin = Instance.new('Part')
		origin.Name = 'Origin'
		origin.CFrame = CFrame.new(100, 100, 100)
		origin.Parent = pad
		local goal = Instance.new('Part')
		goal.Name = 'LaunchGoal'
		goal.CFrame = CFrame.new(100, 100, 100) + (velo.Unit == velo.Unit and velo.Unit or Vector3.zero)
		goal.Parent = pad
		redline[redline.MoveController][redline.LaunchpadFunction](redline[redline.MoveController], pad, {
			base_strength = velo.Magnitude,
			max_strength = velo.Magnitude
		})

		pad:Destroy()
		pad:ClearAllChildren()
	end
end

local function castHitbox(data, origin)
	local hit_hurtboxes = {}
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.RespectCanCollide = false
	params.FilterDescendantsInstances = collectionService:GetTagged('Hurtbox')

	for _, v in params.FilterDescendantsInstances do
		v.Transparency = 0
	end

	for _, hit in workspace:GetPartBoundsInBox(origin * data.offset, data.size, params) do
		if hit:FindFirstAncestorWhichIsA('Model') ~= lplr.Character then
			table.insert(hit_hurtboxes, hit)
		end
	end

	return hit_hurtboxes
end

local function searchForPacket(func, unreliable)
	for _, v in debug.getconstants(func) do
		if rawget(unreliable and redline.Packets.unreliablePackets or redline.Packets, v) then
			return v
		end
	end
end

local function getIndicators()
	return redline[redline.IndicatorController] and redline[redline.IndicatorController][redline.IndicatorTable] or {}
end

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

local function notif(...)
	return vape:CreateNotification(...)
end

local function warningRoutine(hash)
	local path = 'catsix/profiles/agreementhash.txt'
	if (isfile(path) and readfile(path) or '') ~= hash then
		local box = Instance.new('TextLabel')
		box.Size = UDim2.fromScale(1, 1)
		box.BackgroundColor3 = Color3.new()
		box.BackgroundTransparency = 0.5
		box.Text = '⚠️WARNING⚠️\nThe game\'s update hash is not the same as the current script hash, this ⚠️MAY⚠️ mean the game developer has added detections.\nBy clicking OK, you agree to all risks of using this product.\n\n- 7GrandDad'
		box.TextColor3 = Color3.new(1, 1, 1)
		box.TextScaled = true
		box.Font = Enum.Font.Arial
		box.Parent = vape.gui
		local button = Instance.new('TextButton')
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Size = UDim2.fromScale(0.2, 0.05)
		button.Position = UDim2.fromScale(0.5, 0.95)
		button.BackgroundColor3 = Color3.new()
		button.Text = 'OK'
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.Font = Enum.Font.Arial
		button.Parent = box

		button.MouseButton1Click:Connect(function()
			writefile(path, hash)
			box:Destroy()
		end)

		box.Destroying:Wait()
	end
end

if not select(1, ...) then
	if run_on_actor then
		local oldreload = shared.vapereload
		vape.Load = function()
			task.delay(0.1, function()
				vape:Uninject()
			end)
		end

		task.spawn(function()
			repeat task.wait() until not shared.vape
			local executionString = "loadfile('catsix/main.lua')("..drawingactor..")"
			for i, v in shared do
				if type(v) == 'string' then
					executionString = string.format("shared.%s = '%s'", i, v)..'\n'..executionString
				elseif type(v) == 'boolean' then
					executionString = string.format("shared.%s = %s", i, tostring(v))..'\n'..executionString
				end
			end
			if oldreload then
				executionString = 'shared.vapereload = true\n'..executionString
			end

			if getactorthreads and run_on_thread then
				for _, v in getactorthreads() do
					run_on_thread(v, executionString)
					return
				end
			elseif getactorstates then
				for _, v in getactorstates() do
					if type(v) ~= 'thread' then
						v:Execute(executionString)
						return
					end
				end
			end

			for _, v in (getdeletedactors or getactors)() do
				run_on_actor(v, executionString)
				return
			end

			lplr:Kick('Failed to find actor, Executor: '..identifyexecutor())
		end)
	else
		vape.Load = function()
			notif('Vape', 'Missing actor functions.', 10, 'alert')
		end
	end

	return
end

run(function()
	local function waitForChildOfType(obj, name, timeout, prop)
		local checktick = tick() + timeout
		local returned
		repeat
			returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
			if returned or checktick < tick() then break end
			task.wait()
		until false
		return returned
	end

	entitylib.addEntity = function(char, plr, teamfunc, spawntime)
		if not char then return end
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum = waitForChildOfType(char, 'Humanoid', 10)
			local humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
			local head = char:WaitForChild('Head', 10) or humrootpart
			local hitbox = char:FindFirstChild('Head_Hurtbox', true)

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = hum.Health,
					Head = head,
					Hitbox = hitbox or humrootpart,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
					MaxHealth = hum.MaxHealth,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					SpawnTime = spawntime or 0,
					TeamCheck = teamfunc
				}

				if plr == lplr then
					entitylib.character = entity
					entitylib.isAlive = true
					entitylib.Events.LocalAdded:Fire(entity)
				else
					entity.Targetable = entitylib.targetCheck(entity)

					for _, v in entitylib.getUpdateConnections(entity) do
						table.insert(entity.Connections, v:Connect(function()
							entitylib.Events.EntityUpdated:Fire(entity)
						end))
					end

					table.insert(entitylib.List, entity)
					entitylib.Events.EntityAdded:Fire(entity)
				end
			end

			entitylib.EntityThreads[char] = nil
		end)
	end

	if game.PlaceId == 126691165749976 then
		entitylib.targetCheck = function(entity)
			if entity.NPC then return true end
			if isFriend(entity.Player) then return false end
			if not select(2, whitelist:get(entity.Player)) then return false end
			if vape.Categories.Main.Options['Teams by server'].Enabled then
				if not redline.Teams[tostring(lplr.UserId)] then return true end
				return redline.Teams[tostring(entity.Player.UserId)] ~= redline.Teams[tostring(lplr.UserId)]
			end

			return true
		end

		local function updatePlayer(plr)
			plr = playersService:GetPlayerByUserId(tonumber(plr.Name))

			if plr and entitylib.Running then
				if plr == lplr then
					local cloned = table.clone(entitylib.List)
					for _, entity in cloned do
						if entity.Targetable ~= entitylib.targetCheck(entity) then
							entitylib.refreshEntity(entity.Character, entity.Player)
						end
					end
					table.clear(cloned)
				else
					local entity = entitylib.getEntity(plr)
					if entity and entity.Targetable ~= entitylib.targetCheck(entity) then
						entitylib.refreshEntity(entity.Character, plr)
					end
				end
			end
		end

		local function processPlayer(plr)
			if tonumber(plr.Name) then
				redline.Teams[plr.Name] = plr:GetAttribute('team_id')
				task.spawn(updatePlayer, plr)

				vape:Clean(plr:GetAttributeChangedSignal('team_id'):Connect(function()
					redline.Teams[plr.Name] = plr:GetAttribute('team_id')
					task.spawn(updatePlayer, plr)
				end))
			end
		end

		local function processMatch(match)
			if match and match.Name == 'Match' then
				vape:Clean(match.DescendantAdded:Connect(processPlayer))
				for _, v in match:GetDescendants() do
					processPlayer(v)
				end
			end
		end

		vape:Clean(replicatedStorage.ReadOnly.ChildAdded:Connect(processMatch))
		task.spawn(processMatch, replicatedStorage.ReadOnly:FindFirstChild('Match'))
	end
end)
entitylib.start()

run(function()
	local root

	for i = 1, 3 do
		local doBreak
		for _, v in getloadedmodules() do
			if v:GetFullName() == 'Start.Client.ClientRoot' then
				doBreak = true
				break
			end
		end

		if doBreak then
			break
		end

		task.wait(0.5)
	end

	for _, v in getloadedmodules() do
		if v:GetFullName() == 'Start.Client.ClientRoot' then
			if getscripthash(v) ~= latestHash then
				warningRoutine(getscripthash(v))

				if vape.Loaded == nil then
					return
				end
			end

			root = require(v)
			if not rawget(root, 'loaded') then
				repeat
					task.wait()
				until rawget(root, 'loaded') or vape.Loaded == nil
			end

			if vape.Loaded == nil then
				return
			end
		end
	end

	if not root then
		lplr:Kick('Failed to find root class, please contact 7GrandDad on discord.')
		return
	end

	local classList = rawget(root, 'Classes') or {}
	redline = setmetatable({
		CEnum = require(replicatedStorage.Assets.ModuleScripts.CEnum),
		Packets = require(replicatedStorage.Assets.ModuleScripts.Packets),
		Packet = debug.getupvalue(getrawmetatable(require(replicatedStorage.Assets.ModuleScripts.Packets.Packet)).__call, 3),
		Util = require(replicatedStorage.Assets.SharedClasses.Util),
		Teams = redline.Teams
	}, {
		__index = function(self, ind)
			return rawget(classList, ind)
		end
	})

	local dumplist = {
		Constants = {
			ShootFunction = function(constants, func, inst)
				for _, const in constants do
					if const == 'ViewportPointToRay' and debug.info(func, 'n'):sub(1, 1) == '_' then
						redline.ShootFunction = require(inst)[debug.info(func, 'n')]
						break
					end
				end
			end,
			ActionController = function(constants, func, inst)
				for _, const in constants do
					if const == 'getAction FAILED FOR : ' and debug.info(func, 'n'):sub(1, 1) == '_' then
						redline.ActionController = inst.Name
						redline.ActionFunction = require(inst)[debug.info(func, 'n')]
						break
					end
				end
			end,
			IndicatorController = function(constants, func, inst)
				for _, const in constants do
					if const == 'INVALID crosshair_name : ' then
						redline.IndicatorController = inst.Name
						break
					end
				end
			end,
			ActionEventPacket = function(constants, func, inst)
				local found
				for _, const in constants do
					if const == 'OnClientEvent' then
						found = true
					elseif const == 'onKill' and found then
						redline.ActionEventPacket = searchForPacket(func, true)
						if redline.ActionEventPacket then
							redline.ActionEventPacket = redline.Packets.unreliablePackets[redline.ActionEventPacket]
						end

						break
					end
				end
			end,
			LaunchpadFunction = function(constants, func, inst)
				local found
				for _, const in constants do
					if const == -0.007 then
						found = true
					elseif const == 'augment' and found then
						local dumpList = {}
						for _, const in constants do
							if tostring(const):sub(1, 2) == '_x' then
								table.insert(dumpList, const)
							end
						end

						redline.LaunchpadFunction = dumpList[9]
						break
					end
				end
			end
		},
		Protos = {
			AttackPacket = function(protos, func, inst)
				for _, proto in protos do
					if debug.info(proto, 'n') == 'redlinerMelee' then
						redline.AttackPacket = searchForPacket(proto)
						if redline.AttackPacket then
							redline.AttackPacket = redline.Packets[redline.AttackPacket].Name
						end

						break
					end
				end
			end,
			IndicatorTable = function(protos, func, inst)
				for _, proto in protos do
					if debug.info(proto, 'n') == 'removeShotIndicator' then
						for _, const in debug.getconstants(proto) do
							if tostring(const):sub(1, 1) == '_' then
								redline.IndicatorTable = const
								break
							end
						end

						break
					end
				end
			end,
			DashVariables = function(protos, func, inst)
				for _, proto in protos do
					local doBreak = false
					local found = false
					for _, const in debug.getconstants(proto) do
						if const == 'onDeath' then
							found = true
						elseif const == 'Fire' and found then
							doBreak = true
						end
					end

					if doBreak then
						local dumpList = {}
						for _, const in debug.getconstants(proto) do
							if tostring(const):sub(1, 2) == '_x' then
								table.insert(dumpList, const)
							end
						end

						redline.MoveController = dumpList[3]
						redline.DashRecoverVariable = dumpList[4]
						redline.DashVariable = dumpList[5]
						break
					end
				end
			end
		}
	}

	for _, v in getscripts() do
		if v:GetFullName():sub(1, 5) == 'Start' and v:IsA('ModuleScript') then
			local closure = getscriptclosure(v)
			local protos = debug.getprotos(closure)

			if protos[1] then
				if debug.info(protos[1], 'l') == 3 and #debug.info(protos[1], 'n') <= 2 then
					continue
				end
			end

			for _, func in debug.getprotos(closure) do
				for name, callback in dumplist.Constants do
					if not redline[name] then
						callback(debug.getconstants(func), func, v)
					end
				end

				for name, callback in dumplist.Protos do
					if not redline[name] then
						callback(debug.getprotos(func), func, v)
					end
				end
			end
		end
	end

	local kills = sessioninfo:AddItem('Kills')
	local deaths = sessioninfo:AddItem('Deaths')
	local games = sessioninfo:AddItem('Games')
	local wins = sessioninfo:AddItem('Wins')

	if game.PlaceId == 126691165749976 then
		task.delay(1, function()
			games:Increment()
		end)
	end

	if redline.ActionEventPacket then
		vape:Clean(redline.ActionEventPacket.OnClientEvent:Connect(function(data)
			if type(data) == 'table' then
				task.spawn(function()
					local attacker = data.agent and (playersService:GetPlayerFromCharacter(data.agent) or playersService:FindFirstChild(data.agent.Name))
					local victim = data.victim and (playersService:GetPlayerFromCharacter(data.victim) or playersService:FindFirstChild(data.victim.Name))

					if data.action == 'killed' then
						if attacker == lplr then
							vapeEvents.PlayerKill:Fire()
							kills:Increment()
						elseif victim == lplr then
							deaths:Increment()
						end
					elseif data.action == 'hit' and attacker == lplr then
						vapeEvents.Hit:Fire()
					end
				end)
			end
		end))
	end

	vape:Clean(vapeEvents.MatchEnded.Event:Connect(function(won)
		if won then
			wins:Increment()
		end
	end))

	vape:Clean(lplr.PlayerGui.ChildAdded:Connect(function(obj)
		if obj.Name == 'MatchResultsScreen' then
			local results = obj
			obj = obj:FindFirstChild('Subtext', true)
			obj = obj and obj:FindFirstChildWhichIsA('TextLabel')

			if obj then
				obj:GetPropertyChangedSignal('Text'):Wait()
				vapeEvents.MatchEnded:Fire(obj.Text:find('WON') and true or false, results)
			end
		end
	end))
end)

local SendHook = {Hooks = {}}
do
	local oldsend

	local function Hook(...)
		local args = table.pack(...)
		for _, v in SendHook.Hooks do
			if v[2](args) then
				return
			end
		end

		return oldsend(unpack(args, 1, args.n))
	end

	function SendHook:DoHook()
		if not oldsend and next(self.Hooks) then
			oldsend = hookfunction(redline.Packet.Fire, function(...)
				return Hook(...)
			end)
		end
	end

	function SendHook:Add(key, val, priority)
		table.insert(self.Hooks, {key, val, priority or 0})
		table.sort(self.Hooks, function(a, b)
			return a[3] < b[3]
		end)

		if not oldsend then
			if (os.clock() - starttime) < 2 then
				task.defer(function()
					task.delay(2, function()
						self:DoHook()
					end)
				end)
			else
				self:DoHook()
			end
		end
	end

	function SendHook:Remove(key)
		for i, v in self.Hooks do
			if v[1] == key then
				table.remove(self.Hooks, i)
				break
			end
		end

		if oldsend and not next(self.Hooks) then
			if restorefunction then
				restorefunction(redline.Packet.Fire)
			else
				hookfunction(redline.Packet.Fire, oldsend)
			end

			oldsend = nil
		end
	end
end

for _, v in {'Reach', 'TriggerBot', 'AntiFall', 'Desync', 'HitBoxes', 'Invisible', 'Jesus', 'MouseTP', 'Spider', 'SpinBot', 'Swim', 'TargetStrafe', 'AntiRagdoll', 'Disabler', 'StateSpoofer', 'Parkour', 'SafeWalk', 'MurderMystery'} do
	vape:Remove(v)
end

run(function()
	local Reach
	
	Reach = vape.Categories.Combat:CreateModule({
		Name = 'Reach',
		Function = function(callback)
			if callback then
				SendHook:Add('Reach', function(args)
					local self = args[1]
					if self and rawget(self, 'Name') == redline.AttackPacket then
						if typeof(args[4]) == 'string' then
							for _, box in redline_boxes do
								if #castHitbox(box.data, CFrame.lookAlong(entitylib.character.RootPart.Position + Vector3.new(0, 2, 0), args[5])) > 0 then
									args[4] = box.boxtype
									break
								end
							end
						end
					end
				end, 2)
			else
				SendHook:Remove('Reach')
			end
		end,
		Tooltip = 'Extends attack reach by picking the best hitbox type. (RISKY)'
	})
end)

run(function()
	local SilentAim
	local Target
	local Range
	local HitChance
	local CircleColor
	local CircleTransparency
	local CircleFilled
	local CircleObject
	local old
	
	local function Hook(...)
		if debug.info(4, 's'):find('Gun') then
			local ent = entitylib.EntityMouse({
				Range = Range.Value,
				Part = 'RootPart',
				Players = Target.Players.Enabled,
				NPCs = Target.NPCs.Enabled
			})
	
			if ent then
				targetinfo.Targets[ent] = tick() + 1
				return CFrame.lookAt(gameCamera.CFrame.Position, ent.Head.Position).LookVector
			end
		end
	
		return old(...)
	end
	
	SilentAim = vape.Categories.Combat:CreateModule({
		Name = 'SilentAim',
		Function = function(callback)
			if callback then
				old = hookfunction(redline.ShootFunction, function(...)
					return Hook(...)
				end)
	
				repeat
					if CircleObject then
						CircleObject.Position = inputService:GetMouseLocation()
					end
	
					task.wait()
				until not SilentAim.Enabled
			else
				if old then
					if restorefunction then
						restorefunction(redline.ShootFunction)
					else
						hookfunction(redline.ShootFunction, old)
					end
					old = nil
				end
			end
		end,
		ExtraText = function()
			return 'Redliner'
		end,
		Tooltip = 'Silently adjusts your aim towards the enemy'
	})
	Target = SilentAim:CreateTargets({Players = true})
	Range = SilentAim:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 1000,
		Default = 150,
		Function = function(val)
			if CircleObject then
				CircleObject.Radius = val
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	HitChance = SilentAim:CreateSlider({
		Name = 'Hit Chance',
		Min = 0,
		Max = 100,
		Default = 85,
		Suffix = '%'
	})
	SilentAim:CreateToggle({
		Name = 'Range Circle',
		Function = function(callback)
			if callback then
				CircleObject = Drawing.new('Circle')
				CircleObject.Filled = CircleFilled.Enabled
				CircleObject.Color = Color3.fromHSV(CircleColor.Hue, CircleColor.Sat, CircleColor.Value)
				CircleObject.Position = vape.gui.AbsoluteSize / 2
				CircleObject.Radius = Range.Value
				CircleObject.NumSides = 100
				CircleObject.Transparency = 1 - CircleTransparency.Value
				CircleObject.Visible = SilentAim.Enabled
			else
				pcall(function()
					CircleObject.Visible = false
					CircleObject:Remove()
				end)
			end
			CircleColor.Object.Visible = callback
			CircleTransparency.Object.Visible = callback
			CircleFilled.Object.Visible = callback
		end
	})
	CircleColor = SilentAim:CreateColorSlider({
		Name = 'Circle Color',
		Function = function(hue, sat, val)
			if CircleObject then
				CircleObject.Color = Color3.fromHSV(hue, sat, val)
			end
		end,
		Darker = true,
		Visible = false
	})
	CircleTransparency = SilentAim:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Decimal = 10,
		Default = 0.5,
		Function = function(val)
			if CircleObject then
				CircleObject.Transparency = 1 - val
			end
		end,
		Darker = true,
		Visible = false
	})
	CircleFilled = SilentAim:CreateToggle({
		Name = 'Circle Filled',
		Function = function(callback)
			if CircleObject then
				CircleObject.Filled = callback
			end
		end,
		Darker = true,
		Visible = false
	})
end)

run(function()
	local AntiParry
	local anims = {
		[replicatedStorage.Assets.Animations:FindFirstChild('3P_Parry', true).AnimationId] = true
	}
	
	AntiParry = vape.Categories.Blatant:CreateModule({
		Name = 'AntiParry',
		Function = function(callback)
			if callback then
				SendHook:Add('AntiParry', function(args)
					local self = args[1]
					if self and rawget(self, 'Name') == redline.AttackPacket and typeof(args[5]) == 'Vector3' then
						local origin = CFrame.lookAlong(entitylib.character.RootPart.Position + Vector3.new(0, 2, 0), args[5])
						for _, box in redline_boxes do
							if box.boxtype == args[4] then
								local results = castHitbox(box.data, origin)
								for _, hit in results do
									local char = hit:FindFirstAncestorWhichIsA('Model')
									local animator = char and char:FindFirstChild('Animator', true)
	
									if animator and animator:IsA('Animator') then
										for _, track in animator:GetPlayingAnimationTracks() do
											if track.IsPlaying and anims[track.Animation.AnimationId] then
												task.spawn(function()
													notif('AntiParry', 'Parry found, blocking hit.', 1)
												end)
	
												return true
											end
										end
									end
								end
	
								break
							end
						end
					end
				end, 3)
			else
				SendHook:Remove('AntiParry')
			end
		end,
		Tooltip = 'Ignores all targets with the parrying animation'
	})
end)

run(function()
	local AutoParry
	
	AutoParry = vape.Categories.Blatant:CreateModule({
		Name = 'AutoParry',
		Function = function(callback)
			if callback then
				local cooldown = os.clock()
	
				repeat
					if cooldown < os.clock() then
						local doParry
						for i, v in next, getIndicators() do
							if v.indicator_type == 'surefire_bullet' then
								local localPos = gameCamera.CFrame.Position
								local targetPos = (((i:FindFirstChild('Head') and i.Head.Position or i.PrimaryPart and i.PrimaryPart.Position or i:GetPivot().Position) - localPos) * Vector3.new(1, 0, 1)).Unit
								local diff = 1 - (workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit:Dot(targetPos)
								local timediff = (v.expected_shot_time - os.clock())
	
								if math.abs(diff) <= v.parry_range and timediff < 0.2 and timediff > 0 and v.indicator_ui.Visible then
									doParry = true
								end
							elseif v.indicator_type == 'timing_only' and playersService.NumPlayers <= 2 then
								local timediff = (v.expected_shot_time - os.clock())
	
								if timediff < 0 and timediff > -0.2 and v.indicator_ui.Visible then
									doParry = true
								end
							end
						end
	
						if doParry then
							cooldown = os.clock() + 0.2
	
							task.spawn(function()
								redline.ActionFunction(redline[redline.ActionController], 'PARRY').Pressed:Fire()
							end)
						end
					end
	
					task.wait(0.05)
				until not AutoParry.Enabled
			end
		end,
		Tooltip = 'lol'
	})
end)

local Fly
local LongJump
run(function()
	local Value
	local VerticalValue
	local up, down = 0, 0

	Fly = vape.Categories.Blatant:CreateModule({
		Name = 'Fly',
		Function = function(callback)
			if callback then
				Fly:Clean(runService.PreSimulation:Connect(function(dt)
					addVelocity(Vector3.new(0, 3.5 + (up + down) * VerticalValue.Value, 0))
				end))

				up, down = 0, 0
				for _, v in {'InputBegan', 'InputEnded'} do
					Fly:Clean(inputService[v]:Connect(function(input)
						if not inputService:GetFocusedTextBox() then
							if input.KeyCode == Enum.KeyCode.Space then
								up = v == 'InputBegan' and 1 or 0
							elseif input.KeyCode == Enum.KeyCode.LeftAlt then
								down = v == 'InputBegan' and -1 or 0
							end
						end
					end))
				end
			end
		end,
		ExtraText = function()
			return 'Redliner'
		end,
		Tooltip = 'Makes you go zoom.'
	})
	--[[Value = Fly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})]]
	VerticalValue = Fly:CreateSlider({
		Name = 'Vertical Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local HighJump
	local Value
	
	HighJump = vape.Categories.Blatant:CreateModule({
		Name = 'HighJump',
		Function = function(callback)
			if callback then
				HighJump:Toggle()
				addVelocity(Vector3.new(0, Value.Value, 0))
			end
		end,
		ExtraText = function()
			return 'Redliner'
		end,
		Tooltip = 'Lets you jump higher'
	})
	Value = HighJump:CreateSlider({
		Name = 'Velocity',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local InfiniteDash
	
	InfiniteDash = vape.Categories.Blatant:CreateModule({
		Name = 'InfiniteDash',
		Function = function(callback)
			if callback then
				if redline[redline.MoveController] and type(redline[redline.MoveController][redline.DashVariable]) == 'number' and type(redline[redline.MoveController][redline.DashRecoverVariable]) == 'number' then
					InfiniteDash:Clean(runService.PreSimulation:Connect(function()
						rawset(redline[redline.MoveController], redline.DashVariable, 3)
						rawset(redline[redline.MoveController], redline.DashRecoverVariable, 3)
					end))
				end
			end
		end,
		Tooltip = 'Allows you to dash infinitely.'
	})
end)

run(function()
	local Killaura
	local Targets
	local AttackRange
	local AngleSlider
	local AutoSwing
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local Overlay = OverlapParams.new()
	Overlay.FilterType = Enum.RaycastFilterType.Include
	Overlay.RespectCanCollide = false
	local Particles, Boxes = {}, {}
	local anims = {
		[replicatedStorage.Assets.Animations:FindFirstChild('3P_Parry', true).AnimationId] = true
	}
	
	local function getTarget()
		local selfpos = entitylib.isAlive and entitylib.character.RootPart.Position or Vector3.zero
		local localfacing = gameCamera.CFrame.LookVector * Vector3.new(1, 0, 1)
		local ent = entitylib.EntityPosition({
			Range = AttackRange.Value,
			Part = 'RootPart',
			Players = Targets.Players.Enabled,
			NPCs = Targets.NPCs.Enabled
		})
	
		if ent then
			local delta = (ent.RootPart.Position - selfpos)
			local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
			if angle > (math.rad(AngleSlider.Value) / 2) then
				return
			end
	
			return ent
		end
	end
	
	local function shouldAttack(ent)
		if playersService.NumPlayers <= 2 then
			for i, v in next, getIndicators() do
				if v.indicator_type == 'surefire_bullet' or v.indicator_type == 'timing_only' then
					local timediff = (v.expected_shot_time - os.clock())
					if timediff < 0.4 then
						return false
					end
				end
			end
		end
	
		local animator = ent.Humanoid:FindFirstChildWhichIsA('Animator')
		if animator then
			for _, track in animator:GetPlayingAnimationTracks() do
				if track.IsPlaying and anims[track.Animation.AnimationId] then
					return false
				end
			end
		end
	
		local origin = CFrame.lookAt(entitylib.character.RootPart.Position + Vector3.new(0, 2, 0), ent.RootPart.Position)
		for _, box in redline_boxes do
			if #castHitbox(box.data, origin) > 0 then
				return true
			end
		end
	
		return false
	end
	
	Killaura = vape.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				SendHook:Add('Killaura', function(args)
					local self = args[1]
					if self and rawget(self, 'Name') == redline.AttackPacket and typeof(args[5]) == 'Vector3' then
						local ent = getTarget()
	
						if ent then
							local origin = CFrame.lookAt(entitylib.character.RootPart.Position + Vector3.new(0, 2, 0), ent.Hitbox.Position)
							for _, box in redline_boxes do
								if #castHitbox(box.data, origin) > 0 then
									args[5] = origin.LookVector
									break
								end
							end
						end
					end
				end, 1)
	
				repeat
					local attacked = {}
					if game.PlaceId ~= 94987506187454 then
						local ent = getTarget()
	
						if ent and shouldAttack(ent) then
							table.insert(attacked, {
								Entity = ent,
								Check = BoxAttackColor
							})
	
							targetinfo.Targets[ent] = tick() + 1
							if AutoSwing.Enabled then
								task.spawn(function()
									redline.ActionFunction(redline[redline.ActionController], 'MELEE').Pressed:Fire()
								end)
							end
						end
					end
	
					for i, v in Boxes do
						v.Adornee = attacked[i] and attacked[i].Entity.RootPart or nil
						if v.Adornee then
							v.Color3 = Color3.fromHSV(attacked[i].Check.Hue, attacked[i].Check.Sat, attacked[i].Check.Value)
							v.Transparency = 1 - attacked[i].Check.Opacity
						end
					end
	
					for i, v in Particles do
						v.Position = attacked[i] and attacked[i].Entity.RootPart.Position or Vector3.new(9e9, 9e9, 9e9)
						v.Parent = attacked[i] and gameCamera or nil
					end
	
					task.wait(0.016)
				until not Killaura.Enabled
			else
				SendHook:Remove('Killaura')
	
				for _, v in Boxes do
					v.Adornee = nil
				end
	
				for _, v in Particles do
					v.Parent = nil
				end
			end
		end,
		Tooltip = 'Attack players around you\nwithout aiming at them.'
	})
	Targets = Killaura:CreateTargets({Players = true})
	AttackRange = Killaura:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = 40,
		Default = 40,
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
	AutoSwing = Killaura:CreateToggle({
		Name = 'Auto Swing',
		Default = true
	})
	Killaura:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxAttackColor.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.new(3, 5, 3)
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
end)

run(function()
	local AutoQueue
	
	AutoQueue = vape.Categories.Utility:CreateModule({
		Name = 'AutoQueue',
		Function = function(callback)
			if callback then
				AutoQueue:Clean(vapeEvents.MatchEnded.Event:Connect(function(_, obj)
					task.defer(function()
						firesignal(obj.Main.requeuebutton.Activated)
					end)
				end))
			end
		end,
		Tooltip = 'Automatically requeue after the match ends.'
	})
end)

run(function()
	local AutoToxic
	local GG
	local Toggles, Lists, Cloned, Presets = {}, {}, {}, {}
	
	local function sendMessage(name, obj, default)
		local message = default
		if #Lists[name].ListEnabled > 0 then
			if #Cloned[name] <= 0 then
				Cloned[name] = table.clone(Lists[name].ListEnabled)
			end
	
			local entry = Random.new():NextInteger(1, #Cloned[name])
			message = Cloned[name][entry]
			table.remove(Cloned[name], entry)
		end
	
		if not message then return end
	
		message = message and message:gsub('<obj>', obj or '') or ''
		if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			if textChatService:CanUserChatAsync(lplr.UserId) then
				textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(message)
			else
				textChatService.ChatInputBarConfiguration.TargetTextChannel:SendPresetAsync(Presets[message] or Presets['So close'])
			end
		else
			replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, 'All')
		end
	end
	
	AutoToxic = vape.Categories.Utility:CreateModule({
		Name = 'AutoToxic',
		Function = function(callback)
			if callback then
				AutoToxic:Clean(vapeEvents.MatchEnded.Event:Connect(function(won)
					if GG.Enabled then
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							if textChatService:CanUserChatAsync(lplr.UserId) then
								textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync('gg')
							else
								textChatService.ChatInputBarConfiguration.TargetTextChannel:SendPresetAsync(Presets['Good game'])
							end
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer('gg', 'All')
						end
					end
	
					if won then
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
	for _, v in {'Win'} do
		Cloned[v] = {}
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
			Visible = false,
			Function = function()
				table.clear(Cloned[v])
			end
		})
	end
	
	pcall(function()
		for _, group in textChatService:GetPresetsAsync().categoryGroups do
			for _, category in group.categories do
				for _, message in category.messages do
					Presets[message.value] = message.presetId
				end
			end
		end
	end)
end)

run(function()
	local HitSound
	local Value
	local Volume
	local PitchShift
	local old, sounds = nil, {}
	
	HitSound = vape.Legit:CreateModule({
		Name = 'HitSound',
		Function = function(callback)
			if callback then
				HitSound:Clean(vapeEvents.Hit.Event:Connect(function()
					if #sounds > 0 then
						local obj = Instance.new('Sound')
						obj.SoundId = sounds[math.random(1, #sounds)]
						obj.PlayOnRemove = true
						obj.PlaybackSpeed = PitchShift.Enabled and 1 + ((0.5 - math.random()) / 10) or 1
						obj.Volume = Volume.Value
						obj.Parent = workspace
						obj:Destroy()
					end
				end))
			end
		end,
		Tooltip = 'Custom hit sound'
	})
	Value = HitSound:CreateTextList({
		Name = 'Sounds',
		Placeholder = 'sound id (roblox or file path)',
		Function = function(list)
			table.clear(sounds)
			for i, v in list or {} do
				sounds[i] = v:find('rbxasset') and v or isfile(v) and getcustomasset(v) or nil
			end
		end
	})
	Volume = HitSound:CreateSlider({
		Name = 'Volume',
		Min = 0,
		Max = 2,
		Default = 1,
		Decimal = 10
	})
	PitchShift = HitSound:CreateToggle({
		Name = 'Pitch Shift'
	})
end)

run(function()
	local KillSound
	local Value
	local Volume
	local PitchShift
	local old, sounds = nil, {}
	
	KillSound = vape.Legit:CreateModule({
		Name = 'KillSound',
		Function = function(callback)
			if callback then
				KillSound:Clean(vapeEvents.PlayerKill.Event:Connect(function()
					if #sounds > 0 then
						local obj = Instance.new('Sound')
						obj.SoundId = sounds[math.random(1, #sounds)]
						obj.PlayOnRemove = true
						obj.PlaybackSpeed = PitchShift.Enabled and 1 + ((0.5 - math.random()) / 10) or 1
						obj.Volume = Volume.Value
						obj.Parent = workspace
						obj:Destroy()
					end
				end))
			end
		end,
		Tooltip = 'Custom kill sound'
	})
	Value = KillSound:CreateTextList({
		Name = 'Sounds',
		Placeholder = 'sound id (roblox or file path)',
		Function = function(list)
			table.clear(sounds)
			for i, v in list or {} do
				sounds[i] = v:find('rbxasset') and v or isfile(v) and getcustomasset(v) or nil
			end
		end
	})
	Volume = KillSound:CreateSlider({
		Name = 'Volume',
		Min = 0,
		Max = 2,
		Default = 1,
		Decimal = 10
	})
	PitchShift = KillSound:CreateToggle({
		Name = 'Pitch Shift'
	})
end)