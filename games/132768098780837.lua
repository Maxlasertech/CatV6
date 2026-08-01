local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local collectionService = cloneref(game:GetService('CollectionService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local runService = cloneref(game:GetService('RunService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo

local bw = {}
local blocks = {}
local BlockTimes = {}
local AnticheatBypass
local bypassRoot
local isAttacking

local function applySpeed(speed, dt)
	local root = entitylib.character.RootPart
	local dest = (entitylib.character.Humanoid.MoveDirection * math.max((speed + (entitylib.character.Humanoid.WalkSpeed - 16)) - entitylib.character.Humanoid.WalkSpeed, 0) * dt)
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
	rayCheck.CollisionGroup = root.CollisionGroup

	local ray = workspace:Raycast(root.Position, dest, rayCheck)
	if ray then
		dest = ((ray.Position + ray.Normal) - root.Position)
	end
	root.CFrame += dest
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

local function getInventory()
	local inv = {}
	local backpack = lplr:FindFirstChildWhichIsA('Backpack')
	if backpack then
		inv = backpack:GetChildren()
	end

	local equipped = lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool')
	if equipped then
		table.insert(inv, equipped)
	end

	return inv
end

local function getTool()
	return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool')
end

run(function()
	local oldstart = entitylib.start
	local function customEntity(ent)
		entitylib.addEntity(ent, nil, function(self)
			return (lplr.Team and lplr.Team.Name or '') ~= self.Character:GetAttribute('TeamId')
		end)
	end

	entitylib.start = function()
		oldstart()
		if entitylib.Running then
			for _, ent in collectionService:GetTagged('Attackable') do
				customEntity(ent)
			end
			table.insert(entitylib.Connections, collectionService:GetInstanceAddedSignal('Attackable'):Connect(customEntity))
			table.insert(entitylib.Connections, collectionService:GetInstanceRemovedSignal('Attackable'):Connect(function(ent)
				entitylib.removeEntity(ent)
			end))
		end
	end
end)
entitylib.start()

run(function()
	bw = {
		RemoteIndex = require(replicatedStorage.Modules.RemotesIndex),
		BlockBreakConstants = require(replicatedStorage.Modules.Configs.BlockBreakConfig),
		ShopConfig = require(replicatedStorage.Modules.Configs.ShopConfig),
		Inventory = debug.getupvalue(require(replicatedStorage.Modules.ShopUIClient).Start, 8)
	}

	blocks = collection('BedWarsX_PlacedBlock', vape, function(tab, block)
		tab[block.Position // 3] = block
	end, function(tab, block)
		tab[block.Position // 3] = nil
	end)

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	task.delay(1, function()
		if workspace:GetAttribute('ServerType') ~= 'Lobby' then
			games:Increment()
		end
	end)

	vape:Clean(lplr:GetAttributeChangedSignal('RoundKills'):Connect(function()
		if lplr:GetAttribute('RoundKills') > 0 then
			kills:Increment()
		end
	end))

	vape:Clean(bw.RemoteIndex.Round_Event.OnClientEvent:Connect(function(data)
		if type(data) == 'table' and data.id == 'final_kill' then
			if lplr.Team and lplr.Team.Name == data.teamId then
				wins:Increment()
			end
		end
	end))

	vape:Clean(bw.RemoteIndex.Bed_Destroyed.OnClientEvent:Connect(function(data)
		if type(data) == 'table' and data.breakerId == lplr.UserId then
			beds:Increment()
		end
	end))

	vape:Clean(entitylib.Events.EntityAdded:Connect(function(entity)
		BlockTimes[entity.Character] = 0

		local animator = entity.Humanoid:FindFirstChild('Animator')
		if animator then
			table.insert(entity.Connections, animator.AnimationPlayed:Connect(function(track)
				if track.Animation.AnimationId == 'rbxassetid://99664081334494' or track.Animation.AnimationId == 'rbxassetid://75062274621204' then
					BlockTimes[entity.Character] = os.clock()
				end
			end))
		end
	end))

	vape:Clean(entitylib.Events.EntityRemoving:Connect(function(entity)
		BlockTimes[entity.Character] = nil
	end))
end)

for _, v in {'AimAssist', 'Reach', 'SilentAim', 'TriggerBot', 'Jesus', 'AutoRejoin', 'Disabler', 'FastProxPrompt', 'SafeWalk', 'MurderMystery'} do
	vape:Remove(v)
end

run(function()
	local overParams = RaycastParams.new()
	overParams.RespectCanCollide = true
	
	local function clampVec(vec, max)
		if vec.Magnitude > max then
			return vec.Unit == vec.Unit and vec.Unit * max or Vector3.zero
		end
	
		return vec
	end
	
	AnticheatBypass = vape.Categories.Blatant:CreateModule({
		Name = 'AnticheatBypass',
		Function = function(callback)
			if callback then
				bypassRoot = Instance.new('Part')
				bypassRoot.CanCollide = false
				bypassRoot.CanQuery = false
				bypassRoot.Size = Vector3.new(2, 2, 1)
				bypassRoot.Material = Enum.Material.SmoothPlastic
				bypassRoot.Transparency = 1
				bypassRoot.Parent = workspace.CurrentCamera
				AnticheatBypass:Clean(bypassRoot)
	
				local oldcf, oldvelo
				local bindKey = game:GetService('HttpService'):GenerateGUID(true)
				runService:BindToRenderStep(bindKey, 0, function()
					if entitylib.isAlive and oldcf then
						entitylib.character.RootPart.CFrame = oldcf
					end
				end)
	
				AnticheatBypass:Clean(function()
					runService:UnbindFromRenderStep(bindKey)
				end)
	
				for _, connection in {entitylib.Events.LocalAdded, replicatedStorage.GameEvents.BedWarsRemotes.AntiCheat_Strike.OnClientEvent} do
					AnticheatBypass:Clean(connection:Connect(function()
						oldcf = nil
					end))
				end
	
				local tpTimer = 0
				local fallTimer = 0
				AnticheatBypass:Clean(runService.Heartbeat:Connect(function(dt)
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						if not oldcf then
							bypassRoot.CFrame = root.CFrame
						end
						oldcf = root.CFrame
	
						local diff = (oldcf.Position - bypassRoot.Position) * Vector3.new(1, 0, 1)
						local united = diff.Unit
						united = united == united and diff.Magnitude > 0.1 and united * entitylib.character.Humanoid.WalkSpeed or Vector3.zero
						bypassRoot.AssemblyLinearVelocity = Vector3.new(united.X, 0, united.Z)
						bypassRoot.CFrame = CFrame.lookAlong(Vector3.new(bypassRoot.Position.X, root.Position.Y, bypassRoot.Position.Z), root.CFrame.LookVector)
						if diff.Magnitude > 6 and (os.clock() - tpTimer) > 0.75 then
							bypassRoot.CFrame += clampVec(diff, entitylib.character.Humanoid.WalkSpeed)
							tpTimer = os.clock()
						end
	
						overParams.CollisionGroup = root.CollisionGroup
						overParams.FilterDescendantsInstances = {lplr.Character, gameCamera}
						local flyCheck = workspace:Raycast(bypassRoot.Position, Vector3.new(0, -8, 0), overParams)
						if not flyCheck then
							if fallTimer == 0 then
								fallTimer = os.clock()
							end
							bypassRoot.CFrame -= Vector3.new(0, ((os.clock() - fallTimer) % 1) * 10, 0)
						else
							fallTimer = 0
						end
	
						root.CFrame = bypassRoot.CFrame
						if root.AssemblyLinearVelocity.Magnitude < 0.1 then
							root.AssemblyLinearVelocity += Vector3.new(0, -0.1, 0)
						end
					else
						bypassRoot.CFrame = CFrame.new()
						bypassRoot.AssemblyLinearVelocity = Vector3.zero
					end
				end))
			else
				bypassRoot = nil
			end
		end,
		Tooltip = 'Using various methods to bypass the Anticheat.'
	})
end)

local Fly
run(function()
	local Value
	local Keys
	local Platform = Instance.new('Part')
	Platform.CanQuery = false
	Platform.Anchored = true
	Platform.Size = Vector3.new(4, 1, 4)
	Platform.Transparency = 1
	Platform.Parent = nil

	Fly = vape.Categories.Blatant:CreateModule({
		Name = 'Fly',
		Function = function(callback)
			if Platform then
				Platform.Parent = callback and gameCamera or nil
			end

			if callback then
				if not AnticheatBypass.Enabled then
					AnticheatBypass:Toggle()
				end

				Fly:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive then
						applySpeed(Value.Value, dt)
						Platform.CFrame = down ~= 0 and CFrame.identity or entitylib.character.RootPart.CFrame + Vector3.new(0, -(entitylib.character.HipHeight + 0.5), 0)
					end
				end))

				up, down = 0, 0
				for _, v in {'InputBegan', 'InputEnded'} do
					Fly:Clean(inputService[v]:Connect(function(input)
						if not inputService:GetFocusedTextBox() then
							local divided = Keys.Value:split('/')
							if input.KeyCode == Enum.KeyCode[divided[1]] then
								up = v == 'InputBegan' and 1 or 0
							elseif input.KeyCode == Enum.KeyCode[divided[2]] then
								down = v == 'InputBegan' and -1 or 0
							end
						end
					end))
				end

				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						Fly:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
							up = jumpButton.ImageRectOffset.X == 146 and 1 or 0
						end))
					end)
				end
			end
		end,
		ExtraText = function()
			return 'BlockWars'
		end,
		Tooltip = 'Makes you go zoom.'
	})
	Keys = Fly:CreateDropdown({
		Name = 'Keys',
		List = {'Space/LeftControl', 'Space/LeftShift', 'E/Q', 'Space/Q', 'ButtonA/ButtonL2'},
		Tooltip = 'The key combination for going up & down'
	})
	Value = Fly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 38,
		Default = 38,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local Killaura
	local Targets
	local SwingRange
	local AttackRange
	local AngleSlider
	local Max
	local Mouse
	local BoxSwingColor
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local Face
	local Particles, Boxes, AttackDelay = {}, {}, {}
	
	local function getSword()
		local inv = getInventory()
		for _, tool in inv do
			if tool:GetAttribute('WeaponType') then
				return tool
			end
		end
	end
	
	local function getAttackData()
		if Mouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end
	
		local tool = getSword()
		return tool or nil, tool
	end
	
	Killaura = vape.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				repeat
					isAttacking = false
					local tool = getAttackData()
					local attacked = {}
	
					if tool then
						local plrs = entitylib.AllPosition({
							Range = AttackRange.Value,
							Wallcheck = Targets.Walls.Enabled or nil,
							Origin = bypassRoot and bypassRoot.Position or nil,
							Part = 'RootPart',
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Limit = Max.Value
						})
	
						if #plrs > 0 then
							isAttacking = true
							local selfpos = entitylib.character.RootPart.Position
							local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
	
							if tool.Parent ~= lplr.Character then
								entitylib.character.Humanoid:EquipTool(tool)
							end
	
							for _, v in plrs do
								local delta = (v.RootPart.Position - selfpos)
								local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
								if angle > (math.rad(AngleSlider.Value) / 2) then continue end
	
								table.insert(attacked, {
									Entity = v,
									Check = delta.Magnitude > AttackRange.Value and BoxSwingColor or BoxAttackColor
								})
								targetinfo.Targets[v] = tick() + 1
	
								if (os.clock() - (BlockTimes[v.Character] or 0)) < 0.3 then
									continue
								end
	
								if (os.clock() - (AttackDelay[v.Character] or 0) < 0.03) then
									continue
								end
	
								replicatedStorage.GameEvents.CombatRemotes.Combat_FeintSwing:FireServer()
								replicatedStorage.GameEvents.CombatRemotes.Combat_RequestAttack:FireServer(tool:GetAttribute('WeaponType'), v.Character)
								AttackDelay[v.Character] = os.clock()
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
	
					if Face.Enabled and attacked[1] then
						local vec = attacked[1].Entity.RootPart.Position * Vector3.new(1, 0, 1)
						entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position, Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.01, vec.Z))
					end
	
					task.wait(0.016)
				until not Killaura.Enabled
			else
				isAttacking = false
	
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
	Targets = Killaura:CreateTargets({
		Players = true,
		NPCs = true
	})
	AttackRange = Killaura:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = 13,
		Default = 13,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AngleSlider = Killaura:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 90
	})
	Max = Killaura:CreateSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 10,
		Default = 10
	})
	Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
	Killaura:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxSwingColor.Object.Visible = callback
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
end)

run(function()
	local Speed
	local Value
	local AutoJump
	local AutoJumpCustom
	local AutoJumpValue
	
	Speed = vape.Categories.Blatant:CreateModule({
		Name = 'Speed',
		Function = function(callback)
			if callback then
				if not AnticheatBypass.Enabled then
					AnticheatBypass:Toggle()
				end
	
				Speed:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive and not Fly.Enabled then
						local state = entitylib.character.Humanoid:GetState()
						if state == Enum.HumanoidStateType.Climbing then return end
						applySpeed(Value.Value, dt)
	
						if AutoJump.Enabled and entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and movevec ~= Vector3.zero then
							if AutoJumpCustom.Enabled then
								local velocity = entitylib.character.RootPart.Velocity * Vector3.new(1, 0, 1)
								entitylib.character.RootPart.Velocity = Vector3.new(velocity.X, AutoJumpValue.Value, velocity.Z)
							else
								entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
							end
						end
					end
				end))
			end
		end,
		ExtraText = function()
			return 'BlockWars'
		end,
		Tooltip = 'Increases your movement with various methods.'
	})
	Value = Speed:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 38,
		Default = 38,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AutoJump = Speed:CreateToggle({
		Name = 'AutoJump',
		Function = function(callback)
			AutoJumpCustom.Object.Visible = callback
		end
	})
	AutoJumpCustom = Speed:CreateToggle({
		Name = 'Custom Jump',
		Function = function(callback)
			AutoJumpValue.Object.Visible = callback
		end,
		Tooltip = 'Allows you to adjust the jump power',
		Darker = true,
		Visible = false
	})
	AutoJumpValue = Speed:CreateSlider({
		Name = 'Jump Power',
		Min = 1,
		Max = 50,
		Default = 30,
		Darker = true,
		Visible = false
	})
end)

run(function()
	local AutoLeave
	
	AutoLeave = vape.Categories.Utility:CreateModule({
		Name = 'AutoLeave',
		Function = function(callback)
			if callback then
				AutoLeave:Clean(bw.RemoteIndex.Victory_Show.OnClientEvent:Connect(function()
					replicatedStorage.GameEvents.BedWarsRemotes.Return_To_Lobby:FireServer()
				end))
			end
		end,
		Tooltip = 'Automatically leave after the match ends.'
	})
end)

run(function()
	local AutoQueue
	
	AutoQueue = vape.Categories.Utility:CreateModule({
		Name = 'AutoQueue',
		Function = function(callback)
			if callback then
				if workspace:GetAttribute('ServerType') == 'Lobby' then
					task.spawn(function()
						bw.RemoteIndex.Matchmaking_Request:InvokeServer('queue')
					end)
				end
			end
		end,
		Tooltip = 'Automatically queue in the lobby.'
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
				AutoToxic:Clean(bw.RemoteIndex.Round_Event.OnClientEvent:Connect(function(data)
					if type(data) == 'table' and data.id == 'final_kill' then
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
	
						if lplr.Team and lplr.Team.Name == data.teamId then
							if Toggles.Win.Enabled then
								sendMessage('Win', nil, 'yall garbage')
							end
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
	local FastBreak
	local Value
	local old
	
	FastBreak = vape.Categories.World:CreateModule({
		Name = 'FastBreak',
		Function = function(callback)
			if callback then
				old = hookfunction(bw.BlockBreakConstants.CooldownFor, function(...)
					return old(...) * (Value.Value / 100)
				end)
			else
				if old then
					hookfunction(bw.BlockBreakConstants.CooldownFor, old)
					old = nil
				end
			end
		end,
		Tooltip = 'Allow you to swing the pickaxe faster.'
	})
	Value = FastBreak:CreateSlider({
		Name = 'Break Speed Percent',
		Min = 0,
		Max = 100,
		Default = 50,
		Suffix = '%'
	})
end)

run(function()
	local AutoBuy
	local shops = {}
	local requirements = {
		armor = {
			['Leather Armor'] = 'pickaxe_iron'
		},
		pickaxe = {
			['pickaxe_gold'] = 'Golden Armor',
			['pickaxe_diamond'] = 'Diamond Armor'
		}
	}
	
	local function buyCategory(ladder, default)
		local tierItems = {}
		for _, item in bw.ShopConfig.Items do
			if item.ladder == ladder then
				table.insert(tierItems, item)
			end
		end
	
		table.sort(tierItems, function(a, b)
			return (a.tier or -1) < (b.tier or -1)
		end)
	
		local nextTier = default and tierItems[1] or nil
		for _, item in tierItems do
			if bw.Inventory.items[item.id] then
				nextTier = tierItems[table.find(tierItems, item) + 1]
				break
			end
		end
	
		if nextTier then
			for index, item in {'Block', 'Gold', 'Diamond'} do
				if (nextTier.cost and nextTier.cost[item] or 0) > (bw.Inventory[index == 1 and 'blocks' or item:lower()] or 0) then
					return false
				end
			end
	
			if requirements[ladder] and requirements[ladder][nextTier.id] and not bw.Inventory.items[requirements[ladder][nextTier.id]] then
				return false
			end
	
			bw.RemoteIndex.Shop_Purchase:InvokeServer({itemId = nextTier.id})
			return true
		end
	
		return false
	end
	
	AutoBuy = vape.Categories.Inventory:CreateModule({
		Name = 'AutoBuy',
		Function = function(callback)
			if callback then
				shops = collection('BedWarsX_ShopNPC')
	
				repeat
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						for _, shop in shops do
							if (shop.Position - localPosition).Magnitude < 20 then
								if buyCategory('armor', true) then break end
								if buyCategory('pickaxe') then break end
								if buyCategory('sword') then break end
								break
							end
						end
					end
	
					task.wait(0.2)
				until not AutoBuy.Enabled
			end
		end,
		Tooltip = 'lol'
	})
end)

run(function()
	local Breaker
	local Range
	local BreakSpeed
	local UpdateRate
	local Custom
	local Bed
	local LuckyBlock
	local IronOre
	local Effect
	local CustomHealth = {}
	local Animation
	local SelfBreak
	local InstantBreak
	local LimitItem
	local customlist, parts = {}, {}
	
	local function getPick()
		local inv = getInventory()
		for _, tool in inv do
			if tool:GetAttribute('Tier') then
				return tool
			end
		end
	end
	
	local function attemptBreak(tab, localPosition, tool)
		if not tab then return end
		for _, v in tab do
			if (v.Position - localPosition).Magnitude < Range.Value and v:GetAttribute('BedTeamId') ~= (lplr.Team and lplr.Team.Name or '') and (v:GetAttribute('HP') or 10) > 0 then
				if tool.Parent ~= lplr.Character then
					entitylib.character.Humanoid:EquipTool(tool)
				end
	
				if v:HasTag('BedWarsX_BedSpawn') then
					local notCovered = false
					for _, normal in Enum.NormalId:GetEnumItems() do
						if normal ~= Enum.NormalId.Bottom then
							if not blocks[v.Position // 3 + Vector3.fromNormalId(normal)] then
								notCovered = true
								break
							end
						end
					end
	
					if notCovered then
						bw.RemoteIndex.Block_AttemptHit:FireServer({
							camPos = localPosition,
							hitPos = v:GetClosestPointOnSurface(localPosition),
							blockInstance = v
						})
					else
						local aboveBlock = blocks[v.Position // 3 + Vector3.new(0, 1, 0)]
	
						if aboveBlock then
							bw.RemoteIndex.Block_AttemptHit:FireServer({
								camPos = localPosition,
								hitPos = aboveBlock:GetClosestPointOnSurface(localPosition),
								blockInstance = aboveBlock
							})
						end
					end
	
					task.wait(0.15)
				else
					bw.RemoteIndex.Mine_AttemptHit:FireServer(v)
				end
	
				task.wait(0.05)
				return true
			end
		end
	
		return false
	end
	
	Breaker = vape.Categories.Minigames:CreateModule({
		Name = 'Breaker',
		Function = function(callback)
			if callback then
				local beds = collection('BedWarsX_BedSpawn', Breaker)
				local generators = collection('BedWarsX_Resource', Breaker)
	
				repeat
					task.wait(1 / UpdateRate.Value)
					if not Breaker.Enabled then break end
	
					local tool = getPick()
					if entitylib.isAlive and tool and not isAttacking then
						local localPosition = bypassRoot and bypassRoot.Position or entitylib.character.RootPart.Position
	
						if attemptBreak(beds, localPosition, tool) then continue end
						if attemptBreak(generators, localPosition, tool) then continue end
					end
				until not Breaker.Enabled
			end
		end,
		Tooltip = 'Break blocks around you automatically'
	})
	Range = Breaker:CreateSlider({
		Name = 'Break range',
		Min = 1,
		Max = 12,
		Default = 12,
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
end)

run(function()
	local FixGUIs
	
	FixGUIs = vape.Legit:CreateModule({
		Name = 'FixGUIs',
		Function = function(callback)
			if callback then
				local guis = {lplr.PlayerGui:FindFirstChild('Team_UpgradesV3', true), lplr.PlayerGui:FindFirstChild('ItemShopV3', true)}
				if #guis < 2 then
					repeat
						guis = {lplr.PlayerGui:FindFirstChild('Team_UpgradesV3', true), lplr.PlayerGui:FindFirstChild('ItemShopV3', true)}
						task.wait()
					until #guis >= 2 or not FixGUIs.Enabled
	
					if not FixGUIs.Enabled then
						return
					end
				end
	
				local vis = false
				local mouse = Instance.new('ImageLabel')
				mouse.Size = UDim2.fromOffset(20, 20)
				mouse.Visible = false
				mouse.Parent = vape.gui
				FixGUIs:Clean(mouse)
	
				for _, gui in guis do
					if gui then
						for _, v in gui:QueryDescendants('TextButton') do
							local ancestor = v:FindFirstAncestorWhichIsA('ScrollingFrame')
							if not ancestor then
								v.Modal = true
							end
						end
	
						vis = vis or gui.Visible
						FixGUIs:Clean(gui:GetPropertyChangedSignal('Visible'):Connect(function()
							vis = gui.Visible
						end))
					end
				end
	
				FixGUIs:Clean(runService.Heartbeat:Connect(function()
					local location = inputService:GetMouseLocation()
					mouse.Visible = vis
					if mouse.Visible then
						mouse.Position = UDim2.fromOffset(location.X, location.Y)
					end
				end))
			end
		end,
		Tooltip = 'Fix GUI\'s in first person.'
	})
end)

run(function()
	local HideShield
	local parts = {}
	
	local function localAdded(char)
		local shield = char.Character:WaitForChild('ShieldModel', 10)
		if shield then
			parts = shield:QueryDescendants('BasePart')
		end
	end
	
	HideShield = vape.Legit:CreateModule({
		Name = 'HideShield',
		Function = function(callback)
			if callback then
				HideShield:Clean(entitylib.Events.LocalAdded:Connect(localAdded))
				if entitylib.isAlive then
					task.spawn(localAdded, entitylib.character)
				end
	
				repeat
					for _, v in parts do
						v.Transparency = 1
					end
	
					task.wait()
				until not HideShield.Enabled
			else
				table.clear(parts)
			end
		end,
		Tooltip = 'Hide the shield entirely.'
	})
end)