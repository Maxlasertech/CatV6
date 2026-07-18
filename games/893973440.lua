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
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local mapobj
local lstats

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

run(function()
	lstats = lplr:FindFirstChild('TempPlayerStatsModule')
	if not lstats then
		repeat
			lstats = lplr:FindFirstChild('TempPlayerStatsModule')
			task.wait()
		until lstats or vape.Loaded == nil

		if vape.Loaded == nil then
			return
		end
	end

	local mapval = replicatedStorage.CurrentMap
	local function updateMap()
		if mapval.Value then
			mapobj = mapval.Value
			vapeEvents.MapAdded:Fire(mapobj)
		elseif mapobj then
			vapeEvents.MapRemoved:Fire(mapobj)
			mapobj = nil
		end
	end

	vape:Clean(mapval:GetPropertyChangedSignal('Value'):Connect(updateMap))
	if mapval.Value then
		updateMap()
	end
end)

run(function()
	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum = waitForChildOfType(char, 'Humanoid', 10)
			local humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
			local head = char:WaitForChild('Head', 10) or humrootpart
			local plrstats = plr:WaitForChild('TempPlayerStatsModule', 10) or {IsBeast = {GetPropertyChangedSignal = function() return {Connect = function() end} end}}

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = hum.Health,
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					IsBeast = plrstats.IsBeast.Value,
					HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
					MaxHealth = hum.MaxHealth,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc
				}

				if plr == lplr then
					entitylib.character = entity
					entitylib.isAlive = true
					entitylib.Events.LocalAdded:Fire(entity)
				else
					entity.Targetable = entitylib.targetCheck(entity)

					table.insert(entity.Connections, plrstats.IsBeast:GetPropertyChangedSignal('Value'):Connect(function()
						entitylib.refreshEntity(entity.Character, entity.Player)
					end))

					for _, v in entitylib.getUpdateConnections(entity) do
						table.insert(entity.Connections, v:Connect(function()
							entity.Health = hum.Health
							entity.MaxHealth = hum.MaxHealth
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

	entitylib.getEntityColor = function(ent)
		if not (ent.Player and vape.Categories.Main.Options['Use team color'].Enabled) then return end
		if isFriend(ent.Player, true) then
			return Color3.fromHSV(vape.Categories.Friends.Options['Friends color'].Hue, vape.Categories.Friends.Options['Friends color'].Sat, vape.Categories.Friends.Options['Friends color'].Value)
		end
		return ent.IsBeast and Color3.new(1, 0.2, 0.2) or Color3.new(0.3, 1, 0.3)
	end

	entitylib.start()
end)

for _, v in {'Aim Assist', 'Reach', 'Silent Aim', 'Trigger Bot', 'Anti Fall', 'Invisible', 'Jesus', 'Killaura', 'Disabler', 'Murder Mystery'} do
	vape:Remove(v)
end

--[[
    Blatant
]]

run(function()
    run(function()
    	local Killaura
    	local Targets
    	local CPS
    	local SwingRange
    	local FaceTarget
    	local AttackRange
    	local AngleSlider
    	local Max
    	local Mouse
    	local Swing
    	local BoxSwingColor
    	local BoxAttackColor
    	local ParticleTexture
    	local ParticleColor1
    	local ParticleColor2
    	local ParticleSize
        local LegitAura
    	local Rope
    	local Particles, Boxes, AttackDelay, SwingDelay, ClickDelay = {}, {}, tick(), tick(), tick()
        
    	local function getAttackData()
    		if Mouse.Enabled then
    			if not inputService:IsMouseButtonPressed(0) then return false end
    		end
    		if LegitAura.Enabled then 
    			if ClickDelay < tick() then return false end
    		end
    		
    		return entitylib.isAlive and lplr.Character:FindFirstChild('Hammer') or nil
    	end
    
        Killaura = vape.Categories.Blatant:CreateModule({
            Name = 'Killaura',
            Function = function(callback)
                if callback then
                    local attacked = {}
                    repeat
                        local tool, plrs = getAttackData(), entitylib.AllPosition({
                            Range = SwingRange.Value,
                            Wallcheck = Targets.Walls.Enabled,
                            Part = 'RootPart',
                            Players = Targets.Players.Enabled,
                            NPCs = Targets.NPCs.Enabled,
                            Limit = Max.Value
                        })
    
                        if tool and #plrs > 0 then
                            local selfpos = entitylib.character.RootPart.Position
                            local localfacing = gameCamera.CFrame.LookVector * Vector3.new(1, 0, 1)
    
                            for _, v in plrs do
                                local delta = (v.RootPart.Position - selfpos)
                                local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
                                if angle > (math.rad(AngleSlider.Value) / 2) then continue end
                                targetinfo.Targets[v] = tick() + 1
                                
                                if not Swing.Enabled and SwingDelay < tick() and not v.Player.TempPlayerStatsModule.Ragdoll.Value and tool then
                                    SwingDelay = tick() + 0.7
                                    entitylib.character.Humanoid.Animator:LoadAnimation(tool.AnimSwing):Play()
                                end
    
                                if delta.Magnitude > AttackRange.Value then continue end
                                if AttackDelay < tick() then
                                    AttackDelay = tick() + (0.1 / CPS.GetRandomValue())
                                    if not v.Player.TempPlayerStatsModule.Ragdoll.Value then tool.HammerEvent:FireServer('HammerHit', v.Head) end
                                    if Rope.Enabled then tool.HammerEvent:FireServer('HammerTieUp', v.Head, lplr.Character.HumanoidRootPart.Position) end
                                    if FaceTarget.Enabled then
                                        lplr.Character:SetPrimaryPartCFrame(CFrame.new(lplr.Character.PrimaryPart.Position, Vector3.new(v.HumanoidRootPart.Position.X, lplr.Character.PrimaryPart.Position.Y, v.HumanoidRootPart.Position.Z)))
                                    end
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
                        task.wait()
                    until not Killaura.Enabled
                else
    				for _, v in Boxes do
    					v.Adornee = nil
    				end
    				for _, v in Particles do
    					v.Parent = nil
    				end
                end
            end,
            Tooltip = 'Attack players around you\nwithout aiming at them.',
        })
    	Targets = Killaura:CreateTargets({Players = true})
    	CPS = Killaura:CreateTwoSlider({
    		Name = 'Attacks per Second',
    		Min = 1,
    		Max = 20,
    		DefaultMin = 12,
    		DefaultMax = 12
    	})
    	SwingRange = Killaura:CreateSlider({
    		Name = 'Swing range',
    		Min = 1,
    		Max = 16,
    		Default = 16,
    		Suffix = function(val)
    			return val == 1 and 'stud' or 'studs'
    		end
    	})
    	AttackRange = Killaura:CreateSlider({
    		Name = 'Attack range',
    		Min = 1,
    		Max = 16,
    		Default = 16,
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
    	Max = Killaura:CreateSlider({
    		Name = 'Max targets',
    		Min = 1,
    		Max = 10,
    		Default = 10
    	})
    	Rope = Killaura:CreateToggle({Name = 'Auto rope', Default = true})
    	Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
    	Swing = Killaura:CreateToggle({Name = 'No Swing'})
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
    	FaceTarget = Killaura:CreateToggle({Name = 'Face Target'})
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
    		Default = 0.14,
    		Decimal = 100,
    		Function = function(val)
    			for _, v in Particles do
    				v.ParticleEmitter.Size = NumberSequence.new(val)
    			end
    		end,
    		Darker = true,
    		Visible = false
    	})
    	LegitAura = Killaura:CreateToggle({
    		Name = 'Click only',
    		Function = function()
    			if Killaura.Enabled then 
    				Killaura:Toggle()
    				Killaura:Toggle()
    			end
    		end,
    		Tooltip = 'Only attacks while clicking manually'
    	})
    end)
end)

run(function()
    local NoSlowdown
    local old
    
    NoSlowdown = vape.Categories.Blatant:CreateModule({
        Name = 'No Slow',
        Function = function(callback)
            if callback then
                repeat
                    for _, v in getconnections(inputService.JumpRequest) do
                        if v.Function and debug.info(v.Function, 's'):find('PowersLocalScript') then
                            old = v
                            v:Disable()
                        end
                    end
    
                    task.wait(0.1)
                until not NoSlowdown.Enabled
            else
                if old then
                    old:Enable()
                    old = nil
                end
            end
        end,
        Tooltip = 'Prevent slowing down when jumping as the beast'
    })
end)

run(function()
    local PhaseHammer
    local old
    
    local function getEnv(mod)
        local renv = getsenv(mod)
        if not (renv and renv.OnClick) then
            repeat
                renv = getsenv(mod)
                task.wait()
            until renv and renv.OnClick or not PhaseHammer.Enabled
        end
    
        return PhaseHammer.Enabled and renv
    end
    
    local function addHammer(hammer)
        if hammer and hammer.Name == 'Hammer' then
            local mod = hammer:WaitForChild('LocalClubScript', 3)
            if mod and PhaseHammer.Enabled then
                local env = getEnv(mod)
                if not env then return end
    
                old = env.OnClick
                debug.setconstant(debug.getproto(old, 1), 7, 0)
            end
        end
    end
    
    local function addEntity(ent)
        PhaseHammer:Clean(ent.Character.ChildAdded:Connect(addHammer))
        addHammer(ent.Character:FindFirstChild('Hammer'))
    end
    
    PhaseHammer = vape.Categories.Blatant:CreateModule({
        Name = 'Phase Hammer',
        Function = function(callback)
            if callback then
                PhaseHammer:Clean(entitylib.Events.LocalAdded:Connect(addEntity))
                if entitylib.isAlive then
                    task.spawn(addEntity, entitylib.character)
                end
            else
                if old then
                    debug.setconstant(debug.getproto(old, 1), 7, 0.95)
                    old = nil
                end
            end
        end,
        Tooltip = 'Allow your hammer to clip through walls'
    })
end)

run(function()
    local RopeDisabler
    local Self
    
    RopeDisabler = vape.Categories.Utility:CreateModule({
        Name = 'Restrain Beast',
        Function = function(callback)
            if callback then
                repeat
                    if not Self.Enabled or lplr.TempPlayerStatsModule.Ragdoll.Value then
                        for _, v in entitylib.List do
                            local hammer = v.IsBeast and v.Character:FindFirstChild('Hammer')
                            if hammer then
                                hammer.HammerEvent:FireServer('HammerClick', true)
                                break
                            end
                        end
                    end
                    task.wait(0.1)
                until not RopeDisabler.Enabled
            end
        end,
        Tooltip = 'Force the beast to be unable to hook onto survivors'
    })
    Self = RopeDisabler:CreateToggle({
        Name = 'Only you', 
        Tooltip = 'Disable ropes for you only.', 
    })
end)

run(function()
    local SlowBeast
    
    SlowBeast = vape.Categories.Blatant:CreateModule({
        Name = 'Slow Beast',
        Function = function(callback)
            if callback then
                repeat
                    for _, v in entitylib.List do
                        local rem = v.IsBeast and v.Character:FindFirstChild('PowersEvent', true)
                        if rem and rem:IsA('RemoteEvent') then
                            rem:FireServer('Jumped')
                        end
                    end
    
                    task.wait(0.1)
                until not SlowBeast.Enabled
            end
        end,
        Tooltip = 'Force the beast to be slowed'
    })
end)

run(function()
    local SpamBeast
    
    SpamBeast = vape.Categories.Blatant:CreateModule({
        Name = 'Spam Beast',
        Function = function(callback)
            if callback then
                repeat
                    for _, v in entitylib.List do
                        local rem = v.IsBeast and v.Character:FindFirstChild('PowersEvent', true)
                        if rem and rem:IsA('RemoteEvent') then
                            rem:FireServer('Input')
                        end
                    end
    
                    task.wait(0.1)
                until not SpamBeast.Enabled
            end
        end,
        Tooltip = 'Force the beast to use abilities'
    })
end)

--[[
    Render
]]

run(function()
    local ComputerESP
    local FillColor
    local OutlineColor
    local FillTransparency
    local OutlineTransparency
    local Reference = {}
    local Folder = Instance.new('Folder')
    Folder.Parent = vape.gui
    
    local function Added(computer)
        local screen = computer:FindFirstChild('Screen')
        local cham = Instance.new('Highlight')
        cham.Adornee = computer
        cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        cham.FillColor = Color3.fromHSV(FillColor.Hue, FillColor.Sat, FillColor.Value)
        cham.OutlineColor = Color3.fromHSV(OutlineColor.Hue, OutlineColor.Sat, OutlineColor.Value)
        cham.FillTransparency = FillTransparency.Value
        cham.OutlineTransparency = OutlineTransparency.Value
        cham.Parent = Folder
        cham.Enabled = screen.Color ~= Color3.fromRGB(40, 127, 71)
    
        ComputerESP:Clean(screen:GetPropertyChangedSignal('Color'):Connect(function()
            cham.Enabled = screen.Color ~= Color3.fromRGB(40, 127, 71)
        end))
    
        Reference[computer] = cham
    end
    
    local function Removed(computer)
        if Reference[computer] then
            if vape.ThreadFix then
                setthreadidentity(8)
            end
    
            Reference[computer]:Destroy()
            Reference[computer] = nil
        end
    end
    
    local function MapAdded(map)
        local status = replicatedStorage.GameStatus
        if status.Value:find('LOADING') or status.Value:find('START') then
            repeat
                task.wait()
            until not (status.Value:find('LOADING') or status.Value:find('START')) or not ComputerESP.Enabled
    
            if not ComputerESP.Enabled then
                return
            end
        end
    
        for _, v in map:GetChildren() do
            if v.Name == 'ComputerTable' then
                task.spawn(Added, v)
            end
        end
    end
    
    ComputerESP = vape.Categories.Render:CreateModule({
        Name = 'Computer ESP',
        Function = function(callback)
            if callback then
                ComputerESP:Clean(vapeEvents.MapAdded.Event:Connect(MapAdded))
                ComputerESP:Clean(vapeEvents.MapRemoved.Event:Connect(function()
                    for _, v in Reference do
                        Removed(v)
                    end
                end))
    
                if mapobj then
                    task.spawn(MapAdded, mapobj)
                end
            else
                for _, v in Reference do
                    v:Destroy()
                end
                table.clear(Reference)
            end
        end,
        Tooltip = 'Show nearby uncompleted computers.'
    })
    FillColor = ComputerESP:CreateColorSlider({
        Name = 'Color',
        Function = function(hue, sat, val)
            for _, v in Reference do
                v.FillColor = Color3.fromHSV(hue, sat, val)
            end
        end
    })
    OutlineColor = ComputerESP:CreateColorSlider({
        Name = 'Outline Color',
        DefaultSat = 0,
        Function = function(hue, sat, val)
            for _, v in Reference do
                v.OutlineColor = Color3.fromHSV(hue, sat, val)
            end
        end
    })
    FillTransparency = ComputerESP:CreateSlider({
        Name = 'Transparency',
        Min = 0,
        Max = 1,
        Default = 0.5,
        Function = function(val)
            for _, v in Reference do
                v.FillTransparency = val
            end
        end,
        Decimal = 10
    })
    OutlineTransparency = ComputerESP:CreateSlider({
        Name = 'Outline Transparency',
        Min = 0,
        Max = 1,
        Default = 0.5,
        Function = function(val)
            for _, v in Reference do
                v.OutlineTransparency = val
            end
        end,
        Decimal = 10
    })
end)

--[[
    Utility
]]

run(function()
    local AutoComputer
    local Mode
    
    AutoComputer = vape.Categories.Utility:CreateModule({
        Name = 'Auto Computer',
        Function = function(callback)
            if callback then
                repeat
                    if Mode.Value == 'Blatant' then
                        replicatedStorage.RemoteEvent:FireServer('SetPlayerMinigameResult', true)
                    else
                        if lplr.TempPlayerStatsModule.TimingPinPosition.Value == lplr.TempPlayerStatsModule.TimingGoalPosition.Value then
                            replicatedStorage.RemoteEvent:FireServer('Input', 'Action', true)
                            replicatedStorage.RemoteEvent:FireServer('SetPlayerMinigameResult', true)
                        end
                    end
                    task.wait()
                until not AutoComputer.Enabled
            end
        end,
        Tooltip = 'Automatically complete the computer skill check.'
    })
    
    Mode = AutoComputer:CreateDropdown({
        Name = 'Mode',
        List = {'Blatant', 'Legit'}
    })
end)

--[[
    Legit
]]

run(function()
    run(function()
    	local Viewmodel
    	local clone, old
    
        local function Check(obj)
            if obj.Name == 'Hammer' then 
                old = obj
                clone = old:WaitForChild('Handle'):Clone()
                clone.CanCollide = false
                clone.Massless = true
                clone.Anchored = true
                clone.Parent = gameCamera
                clone:ClearAllChildren()
                clone.LocalTransparencyModifier = 0
                old.Handle.LocalTransparencyModifier = 1
            end
        end
    	
    	local function Added(char)
            local hammer = char:FindFirstChild('Hammer')
            if hammer then
                Check(hammer)
            end
    
    		Viewmodel:Clean(char.ChildAdded:Connect(Check))
    		Viewmodel:Clean(char.ChildRemoved:Connect(function(obj)
    			if obj == old then 
    				clone:Destroy()
    				clone = nil
    				old = nil
    			end
    		end))
    	end
    	
    	Viewmodel = vape.Categories.Legit:CreateModule({
    		Name = 'Viewmodel',
    		Function = function(callback)
    			if callback then 
    				local motor = Instance.new('Motor6D')
    				Viewmodel:Clean(motor)
    				Viewmodel:Clean(runService.RenderStepped:Connect(function()
    					if clone then 
    						local dcf = ((CFrame.new(2.06, -2.44, -2.24) * CFrame.new(0.6, -0.2, -0.6)) * CFrame.Angles(math.rad(99), math.rad(2), math.rad(-4))) * motor.C0
    						local offsetcf = (CFrame.new(0, -0.15, -1.56) * CFrame.Angles(math.rad(-90), math.rad(-90), 0))
    						clone.CFrame = ((gameCamera.CFrame * dcf) * offsetcf)
    					end
    				end))
    				Viewmodel:Clean(entitylib.Events.LocalAdded:Connect(Added))
    				if entitylib.isAlive then 
    					Added(entitylib.character) 
    				end
    			else
    				if clone then 
    					clone:Destroy() 
                        clone = nil
    				end
    			end
    		end,
    		Tooltip = 'Replaces the default viewmodel'
    	})
    end)
end)
