local mainapi = {
	Categories = {},
	GUIColor = {
		Hue = 0.46,
		Sat = 0.96,
		Value = 0.52
	},
	HeldKeybinds = {},
	Keybind = {'RightShift'},
	Loaded = false,
	Legit = {Modules = {}},
	Libraries = {},
	Modules = {},
	MultiKeybind = {},
	Place = game.PlaceId,
	Profile = 'default',
	Profiles = {},
	RainbowSpeed = {Value = 1},
	RainbowUpdateSpeed = {Value = 60},
	RainbowTable = {},
	Scale = {Value = 1},
	ThreadFix = setthreadidentity and true or false,
	ToggleNotifications = {},
	Version = '4.18',
	Windows = {}
}

local cloneref = cloneref or function(obj)
	return obj
end
local tweenService = cloneref(game:GetService('TweenService'))
local inputService = cloneref(game:GetService('UserInputService'))
local textService = cloneref(game:GetService('TextService'))
local guiService = cloneref(game:GetService('GuiService'))
local runService = cloneref(game:GetService('RunService'))
local httpService = cloneref(game:GetService('HttpService'))

local fontsize = Instance.new('GetTextBoundsParams')
fontsize.Width = math.huge
local notifications
local assetfunction = getcustomasset
local getcustomasset
local clickgui
local scaledgui
local mainframe
local mainscale
local sidebar
local categoryholder
local categoryhighlight
local lastSelected
local guiTween
local scale
local gui

local color = {}
local tween = {
	tweens = {},
	tweenstwo = {}
}
local uipallet = {
	Main = Color3.fromRGB(70, 119, 255),
	Text = Color3.new(1, 1, 1),
	Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear),
}

local getcustomassets = {
	['catsix/assets/liquidbounce/blatant.png'] = 'rbxasset://liquidbounce/blatant.png',
	['catsix/assets/liquidbounce/combat.png'] = 'rbxasset://liquidbounce/combat.png',
	['catsix/assets/liquidbounce/expand.png'] = 'rbxasset://liquidbounce/expand.png',
	['catsix/assets/liquidbounce/inventory.png'] = 'rbxasset://liquidbounce/inventory.png',
	['catsix/assets/liquidbounce/logo.png'] = 'rbxasset://liquidbounce/logo.png',
	['catsix/assets/liquidbounce/minigames.png'] = 'rbxasset://liquidbounce/minigames.png',
	['catsix/assets/liquidbounce/render.png'] = 'rbxasset://liquidbounce/render.png',
	['catsix/assets/liquidbounce/textgui.png'] = 'rbxasset://liquidbounce/textgui.png',
	['catsix/assets/liquidbounce/utility.png'] = 'rbxasset://liquidbounce/utility.png',
	['catsix/assets/liquidbounce/world.png'] = 'rbxasset://liquidbounce/world.png',
	['catsix/assets/new/blur.png'] = 'rbxassetid://14898786664'
}

local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end

local getfontsize = function(text, size, font)
	fontsize.Text = text
	fontsize.Size = size
	if typeof(font) == 'Font' then
		fontsize.Font = font
	end
	return textService:GetTextBoundsAsync(fontsize)
end

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 42, 1, 42)
	blur.Position = UDim2.fromOffset(-24, -15)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('catsix/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(44, 38, 804, 595)
	blur.Parent = parent

	return blur
end

local function addCorner(parent, radius)
	local corner = Instance.new('UICorner')
	corner.CornerRadius = radius or UDim.new(0, 5)
	corner.Parent = parent

	return corner
end

local function addMaid(object)
	object.Connections = {}
	function object:Clean(callback)
		if typeof(callback) == 'Instance' then
			table.insert(self.Connections, {
				Disconnect = function()
					callback:ClearAllChildren()
					callback:Destroy()
				end
			})
		elseif type(callback) == 'function' then
			table.insert(self.Connections, {
				Disconnect = callback
			})
		else
			table.insert(self.Connections, callback)
		end
	end
end

local function checkKeybinds(compare, target, key)
	if table.find(target, key) then
		for _, v in target do
			if not table.find(compare, v) then
				return false
			end
		end
		return true
	end

	return false
end

local function createDownloader(text)
	if mainapi.Loaded ~= true then
		local downloader = mainapi.Downloader
		if not downloader then
			downloader = Instance.new('TextLabel')
			downloader.Size = UDim2.new(1, 0, 0, 40)
			downloader.BackgroundTransparency = 1
			downloader.TextStrokeTransparency = 0
			downloader.TextSize = 20
			downloader.TextColor3 = Color3.new(1, 1, 1)
			downloader.FontFace = Font.fromEnum(Enum.Font.Arial)
			downloader.Parent = mainapi.gui
			mainapi.Downloader = downloader
		end
		downloader.Text = 'Downloading '..text
	end
end

local function createTween(time, dir)
	return TweenInfo.new(time, Enum.EasingStyle.Cubic, Enum.EasingDirection[dir or 'InOut'])
end

local function downloadFile(path, func)
	if not isfile(path) then
		createDownloader(path)
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

getcustomasset = not inputService.TouchEnabled and assetfunction and function(path)
	return downloadFile(path, assetfunction)
end or function(path)
	return getcustomassets[path] or ''
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do ind += 1 end
	return ind
end

local function loopClean(tab)
	for i, v in tab do
		if type(v) == 'table' then
			loopClean(v)
		end
		tab[i] = nil
	end
end

local function loadJson(path)
	local suc, res = pcall(function()
		return httpService:JSONDecode(readfile(path))
	end)
	return suc and type(res) == 'table' and res or nil
end

local function makeDraggable(obj, window)
	obj.InputBegan:Connect(function(inputObj)
		if window and not window.Visible or mainapi.Dragging then return end
		if
			(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
			and (inputObj.Position.Y - obj.AbsolutePosition.Y < 40 or window)
		then
			mainapi.Dragging = true
			local dragPosition = Vector2.new(obj.AbsolutePosition.X - inputObj.Position.X, obj.AbsolutePosition.Y - inputObj.Position.Y + guiService:GetGuiInset().Y) / scale.Scale
			local changed = inputService.InputChanged:Connect(function(input)
				if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
					local position = input.Position
					if inputService:IsKeyDown(Enum.KeyCode.LeftShift) then
						dragPosition = (dragPosition // 3) * 3
						position = (position // 3) * 3
					end
					obj.Position = UDim2.fromOffset((position.X / scale.Scale) + dragPosition.X, (position.Y / scale.Scale) + dragPosition.Y)
				end
			end)

			local ended
			ended = inputObj.Changed:Connect(function()
				if inputObj.UserInputState == Enum.UserInputState.End then
					mainapi.Dragging = nil
					if changed then
						changed:Disconnect()
					end
					if ended then
						ended:Disconnect()
					end
				end
			end)
		end
	end)
end

local function randomString()
	local array = {}
	for i = 1, math.random(10, 100) do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

local function writeFont()
	if not assetfunction then return 'rbxasset://fonts/inter.json' end
	--[[writefile('catsix/assets/liquidbounce/lbfont.json', httpService:JSONEncode({
		name = 'Inter',
		faces = {
			{style = 'normal', assetId = getcustomasset('catsix/assets/liquidbounce/Inter-Light.ttf'), name = 'Light', weight = 300},
			{style = 'normal', assetId = getcustomasset('catsix/assets/liquidbounce/Inter-Regular.ttf'), name = 'Regular', weight = 400},
			{style = 'normal', assetId = getcustomasset('catsix/assets/liquidbounce/Inter-Medium.ttf'), name = 'Medium', weight = 500}
		}
	}))]]
	return getcustomasset('catsix/assets/liquidbounce/lbfont.json')
end

if inputService.TouchEnabled then
	writefile('catsix/profiles/gui.txt', 'new')
	return
end

do
	local lbfont = writeFont()
	uipallet.Font = Font.new(lbfont, Enum.FontWeight.Regular)
	uipallet.FontSemiBold = Font.new(lbfont, Enum.FontWeight.Medium)
	uipallet.FontLight = Font.new(lbfont, Enum.FontWeight.Light)

	local res = isfile('catsix/profiles/color.txt') and loadJson('catsix/profiles/color.txt')
	if res then
		uipallet.Main = res.Main and Color3.fromRGB(unpack(res.Main)) or uipallet.Main
		uipallet.Text = res.Text and Color3.fromRGB(unpack(res.Text)) or uipallet.Text
		uipallet.Font = res.Font and Font.new(
			res.Font:find('rbxasset') and res.Font or string.format('rbxasset://fonts/families/%s.json', res.Font)
		) or uipallet.Font
		uipallet.FontSemiBold = Font.new(uipallet.Font.Family, Enum.FontWeight.SemiBold)
		uipallet.FontLight = Font.new(uipallet.Font.Family, Enum.FontWeight.Light)
	end

	fontsize.Font = uipallet.Font
end

do
	function color.Dark(col, num)
		local h, s, v = col:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
	end

	function color.Light(col, num)
		local h, s, v = col:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
	end

	function color.Saturate(col, num)
		local h, s, v = col:ToHSV()
		return Color3.fromHSV(h, math.clamp(s - (s * num), 0, 1), math.clamp(v - 0.3, 0, 1))
	end

	function mainapi:Color(h)
		local s = 0.75 + (0.15 * math.min(h / 0.03, 1))
		if h > 0.57 then
			s = 0.9 - (0.4 * math.min((h - 0.57) / 0.09, 1))
		end
		if h > 0.66 then
			s = 0.5 + (0.4 * math.min((h - 0.66) / 0.16, 1))
		end
		if h > 0.87 then
			s = 0.9 - (0.15 * math.min((h - 0.87) / 0.13, 1))
		end
		return h, s, 1
	end

	function mainapi:TextColor(h, s, v)
		if v >= 0.7 and (s < 0.6 or h > 0.04 and h < 0.56) then
			return Color3.new(0.19, 0.19, 0.19)
		end
		return Color3.new(1, 1, 1)
	end
end

do
	function tween:Tween(obj, tweeninfo, goal, tab)
		tab = tab or self.tweens
		if tab[obj] then
			tab[obj]:Cancel()
			tab[obj] = nil
		end

		if obj.Parent and obj.Visible then
			tab[obj] = tweenService:Create(obj, tweeninfo, goal)
			tab[obj].Completed:Once(function()
				if tab then
					tab[obj]:Destroy()
					tab[obj] = nil
					tab = nil
				end
			end)
			tab[obj]:Play()
		else
			for i, v in goal do
				obj[i] = v
			end
		end
	end

	function tween:Cancel(obj)
		if self.tweens[obj] then
			self.tweens[obj]:Cancel()
			self.tweens[obj] = nil
		end
	end
end

mainapi.Libraries = {
	color = color,
	getcustomasset = getcustomasset,
	getfontsize = getfontsize,
	tween = tween,
	uipallet = uipallet,
}

local components
components = {
	Bind = function(optionsettings, children, api)
		local bind = Instance.new('TextButton')
		bind.Name = 'Bind'
		bind.Size = UDim2.new(1, 0, 0, 41)
		bind.BackgroundTransparency = 1
		bind.Text = ''
		bind.Parent = children
		--addTooltip(button, optionsettings.Tooltip)
		local accentbar = Instance.new('Frame')
		accentbar.Size = UDim2.new(0, 4, 1, 0)
		accentbar.BackgroundColor3 = uipallet.Main
		accentbar.BorderSizePixel = 0
		accentbar.Parent = bind
		local bkg = Instance.new('Frame')
		bkg.Size = UDim2.new(1, -22, 1, -14)
		bkg.Position = UDim2.fromOffset(11, 7)
		bkg.BackgroundColor3 = uipallet.Main
		bkg.Parent = bind
		addCorner(bkg, UDim.new(0, 4))
		local bkg2 = bkg:Clone()
		bkg2.Size = UDim2.new(1, -4, 1, -4)
		bkg2.Position = UDim2.fromOffset(2, 2)
		bkg2.BackgroundColor3 = Color3.new()
		bkg2.Parent = bkg
		local label = Instance.new('TextLabel')
		label.Size = UDim2.new(1, -4, 1, -4)
		label.Position = UDim2.fromOffset(2, 2)
		label.BackgroundTransparency = 1
		label.Text = 'Bind: None'
		label.TextColor3 = uipallet.Text
		label.TextSize = 14
		label.FontFace = uipallet.FontSemiBold
		label.Parent = bkg2
		
		api.Bind = {}
		function api:SetBind(tab, mouse)
			if tab.Mobile then
				return
			end
		
			self.Bind = table.clone(tab)
			label.Text = 'Bind: '..(#tab <= 0 and 'None' or table.concat(tab, ' + '))
		end
		
		bind.MouseButton1Click:Connect(function()
			label.Text = 'Press any key'
			mainapi.Binding = api
		end)
	end,
	Button = function(optionsettings, children, api)
		local button = Instance.new('TextButton')
		button.Name = optionsettings.Name..'Button'
		button.Size = UDim2.new(1, 0, 0, 41)
		button.BackgroundTransparency = 1
		button.Visible = optionsettings.Visible == nil or optionsettings.Visible
		button.Text = ''
		button.Parent = children
		--addTooltip(button, optionsettings.Tooltip)
		local accentbar = Instance.new('Frame')
		accentbar.Size = UDim2.new(0, 4, 1, 0)
		accentbar.BackgroundColor3 = uipallet.Main
		accentbar.BorderSizePixel = 0
		accentbar.Parent = button
		local bkg = Instance.new('Frame')
		bkg.Size = UDim2.new(1, -22, 1, -14)
		bkg.Position = UDim2.fromOffset(11, 7)
		bkg.BackgroundColor3 = uipallet.Main
		bkg.Parent = button
		addCorner(bkg, UDim.new(0, 4))
		local label = Instance.new('TextLabel')
		label.Size = UDim2.new(1, -4, 1, -4)
		label.Position = UDim2.fromOffset(2, 2)
		label.BackgroundTransparency = 1
		label.Text = optionsettings.Name
		label.TextColor3 = uipallet.Text
		label.TextSize = 14
		label.FontFace = uipallet.FontSemiBold
		label.Parent = bkg
		optionsettings.Function = optionsettings.Function or function() end
		
		button.MouseButton1Click:Connect(optionsettings.Function)
	end,
	ColorSlider = function(optionsettings, children, api)
		local optionapi = {
			Type = 'ColorSlider',
			Hue = optionsettings.DefaultHue or 0.44,
			Sat = optionsettings.DefaultSat or 1,
			Value = optionsettings.DefaultValue or 1,
			Opacity = optionsettings.DefaultOpacity or 1,
			Rainbow = false,
			Index = 0
		}
		
		local function createSlider(name, gradientColor)
			local slider = Instance.new('TextButton')
			slider.Name = optionsettings.Name..'Slider'..name
			slider.Size = UDim2.new(1, 0, 0, 50)
			slider.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
			slider.BorderSizePixel = 0
			slider.AutoButtonColor = false
			slider.Visible = false
			slider.Text = ''
			slider.Parent = children
			local title = Instance.new('TextLabel')
			title.Name = 'Title'
			title.Size = UDim2.fromOffset(60, 30)
			title.Position = UDim2.fromOffset(10, 2)
			title.BackgroundTransparency = 1
			title.Text = name
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextColor3 = color.Dark(uipallet.Text, 0.16)
			title.TextSize = 11
			title.FontFace = uipallet.Font
			title.Parent = slider
			local bkg = Instance.new('Frame')
			bkg.Name = 'Slider'
			bkg.Size = UDim2.new(1, -20, 0, 2)
			bkg.Position = UDim2.fromOffset(10, 37)
			bkg.BackgroundColor3 = Color3.new(1, 1, 1)
			bkg.BorderSizePixel = 0
			bkg.Parent = slider
			local gradient = Instance.new('UIGradient')
			gradient.Color = gradientColor
			gradient.Parent = bkg
			local fill = bkg:Clone()
			fill.Name = 'Fill'
			fill.Size = UDim2.fromScale(math.clamp(name == 'Saturation' and optionapi.Sat or name == 'Vibrance' and optionapi.Value or optionapi.Opacity, 0.04, 0.96), 1)
			fill.Position = UDim2.new()
			fill.BackgroundTransparency = 1
			fill.Parent = bkg
			local knobholder = Instance.new('Frame')
			knobholder.Name = 'Knob'
			knobholder.Size = UDim2.fromOffset(24, 4)
			knobholder.Position = UDim2.fromScale(1, 0.5)
			knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
			knobholder.BackgroundColor3 = slider.BackgroundColor3
			knobholder.BorderSizePixel = 0
			knobholder.Parent = fill
			local knob = Instance.new('Frame')
			knob.Name = 'Knob'
			knob.Size = UDim2.fromOffset(14, 14)
			knob.Position = UDim2.fromScale(0.5, 0.5)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.BackgroundColor3 = uipallet.Text
			knob.Parent = knobholder
			addCorner(knob, UDim.new(1, 0))
		
			slider.InputBegan:Connect(function(inputObj)
				if
					(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
					and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
				then
					local changed = inputService.InputChanged:Connect(function(input)
						if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
							optionapi:SetValue(nil, name == 'Saturation' and math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1) or nil, name == 'Vibrance' and math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1) or nil, name == 'Opacity' and math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1) or nil)
						end
					end)
		
					local ended
					ended = inputObj.Changed:Connect(function()
						if inputObj.UserInputState == Enum.UserInputState.End then
							if changed then changed:Disconnect() end
							if ended then ended:Disconnect() end
						end
					end)
				end
			end)
			slider.MouseEnter:Connect(function()
				tween:Tween(knob, uipallet.Tween, {
					Size = UDim2.fromOffset(16, 16)
				})
			end)
			slider.MouseLeave:Connect(function()
				tween:Tween(knob, uipallet.Tween, {
					Size = UDim2.fromOffset(14, 14)
				})
			end)
		
			return slider
		end
		
		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.new(1, 0, 0, 50)
		slider.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		slider.BorderSizePixel = 0
		slider.AutoButtonColor = false
		slider.Visible = optionsettings.Visible == nil or optionsettings.Visible
		slider.Text = ''
		slider.Parent = children
		--addTooltip(slider, optionsettings.Tooltip)
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.fromOffset(60, 30)
		title.Position = UDim2.fromOffset(10, 2)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.16)
		title.TextSize = 11
		title.FontFace = uipallet.Font
		title.Parent = slider
		local valuebox = Instance.new('TextBox')
		valuebox.Name = 'Box'
		valuebox.Size = UDim2.fromOffset(60, 15)
		valuebox.Position = UDim2.new(1, -69, 0, 9)
		valuebox.BackgroundTransparency = 1
		valuebox.Visible = false
		valuebox.Text = ''
		valuebox.TextXAlignment = Enum.TextXAlignment.Right
		valuebox.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebox.TextSize = 11
		valuebox.FontFace = uipallet.Font
		valuebox.ClearTextOnFocus = true
		valuebox.Parent = slider
		local bkg = Instance.new('Frame')
		bkg.Name = 'Slider'
		bkg.Size = UDim2.new(1, -20, 0, 2)
		bkg.Position = UDim2.fromOffset(10, 39)
		bkg.BackgroundColor3 = Color3.new(1, 1, 1)
		bkg.BorderSizePixel = 0
		bkg.Parent = slider
		local rainbowTable = {}
		for i = 0, 1, 0.1 do
			table.insert(rainbowTable, ColorSequenceKeypoint.new(i, Color3.fromHSV(i, 1, 1)))
		end
		local gradient = Instance.new('UIGradient')
		gradient.Color = ColorSequence.new(rainbowTable)
		gradient.Parent = bkg
		local fill = bkg:Clone()
		fill.Name = 'Fill'
		fill.Size = UDim2.fromScale(math.clamp(optionapi.Hue, 0.04, 0.96), 1)
		fill.Position = UDim2.new()
		fill.BackgroundTransparency = 1
		fill.Parent = bkg
		local preview = Instance.new('ImageButton')
		preview.Name = 'Preview'
		preview.Size = UDim2.fromOffset(12, 12)
		preview.Position = UDim2.new(1, -22, 0, 10)
		preview.BackgroundTransparency = 1
		preview.Image = getcustomasset('catsix/assets/new/colorpreview.png')
		preview.ImageColor3 = Color3.fromHSV(optionapi.Hue, optionapi.Sat, optionapi.Value)
		preview.ImageTransparency = 1 - optionapi.Opacity
		preview.Parent = slider
		local expandbutton = Instance.new('TextButton')
		expandbutton.Name = 'Expand'
		expandbutton.Size = UDim2.fromOffset(17, 13)
		expandbutton.Position = UDim2.new(0, getfontsize(title.Text, title.TextSize, title.Font, Vector2.new(1000, 1000)).X + 11, 0, 7)
		expandbutton.BackgroundTransparency = 1
		expandbutton.Text = ''
		expandbutton.Parent = slider
		local expand = Instance.new('ImageLabel')
		expand.Name = 'Expand'
		expand.Size = UDim2.fromOffset(9, 5)
		expand.Position = UDim2.fromOffset(4, 4)
		expand.BackgroundTransparency = 1
		expand.Image = getcustomasset('catsix/assets/new/expandicon.png')
		expand.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		expand.Parent = expandbutton
		local rainbow = Instance.new('TextButton')
		rainbow.Name = 'Rainbow'
		rainbow.Size = UDim2.fromOffset(12, 12)
		rainbow.Position = UDim2.new(1, -42, 0, 10)
		rainbow.BackgroundTransparency = 1
		rainbow.Text = ''
		rainbow.Parent = slider
		local rainbow1 = Instance.new('ImageLabel')
		rainbow1.Size = UDim2.fromOffset(12, 12)
		rainbow1.BackgroundTransparency = 1
		rainbow1.Image = getcustomasset('catsix/assets/new/rainbow_1.png')
		rainbow1.ImageColor3 = color.Light(uipallet.Main, 0.37)
		rainbow1.Parent = rainbow
		local rainbow2 = rainbow1:Clone()
		rainbow2.Image = getcustomasset('catsix/assets/new/rainbow_2.png')
		rainbow2.Parent = rainbow
		local rainbow3 = rainbow1:Clone()
		rainbow3.Image = getcustomasset('catsix/assets/new/rainbow_3.png')
		rainbow3.Parent = rainbow
		local rainbow4 = rainbow1:Clone()
		rainbow4.Image = getcustomasset('catsix/assets/new/rainbow_4.png')
		rainbow4.Parent = rainbow
		local knobholder = Instance.new('Frame')
		knobholder.Name = 'Knob'
		knobholder.Size = UDim2.fromOffset(24, 4)
		knobholder.Position = UDim2.fromScale(1, 0.5)
		knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
		knobholder.BackgroundColor3 = slider.BackgroundColor3
		knobholder.BorderSizePixel = 0
		knobholder.Parent = fill
		local knob = Instance.new('Frame')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(14, 14)
		knob.Position = UDim2.fromScale(0.5, 0.5)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundColor3 = uipallet.Text
		knob.Parent = knobholder
		addCorner(knob, UDim.new(1, 0))
		optionsettings.Function = optionsettings.Function or function() end
		local satSlider = createSlider('Saturation', ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, optionapi.Value)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, 1, optionapi.Value))
		}))
		local vibSlider = createSlider('Vibrance', ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, optionapi.Sat, 1))
		}))
		local opSlider = createSlider('Opacity', ColorSequence.new({
			ColorSequenceKeypoint.new(0, color.Dark(uipallet.Main, 0.02)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, optionapi.Sat, optionapi.Value))
		}))
		
		function optionapi:Save(tab)
			tab[optionsettings.Name] = {
				Hue = self.Hue,
				Sat = self.Sat,
				Value = self.Value,
				Opacity = self.Opacity,
				Rainbow = self.Rainbow
			}
		end
		
		function optionapi:Load(tab)
			if tab.Rainbow ~= self.Rainbow then
				self:Toggle()
			end
			if self.Hue ~= tab.Hue or self.Sat ~= tab.Sat or self.Value ~= tab.Value or self.Opacity ~= tab.Opacity then
				self:SetValue(tab.Hue, tab.Sat, tab.Value, tab.Opacity)
			end
		end
		
		function optionapi:SetValue(h, s, v, o)
			self.Hue = h or self.Hue
			self.Sat = s or self.Sat
			self.Value = v or self.Value
			self.Opacity = o or self.Opacity
			preview.ImageColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
			preview.ImageTransparency = 1 - self.Opacity
			satSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, self.Value)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, 1, self.Value))
			})
			vibSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, 1))
			})
			opSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, color.Dark(uipallet.Main, 0.02)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, self.Value))
			})
		
			if self.Rainbow then
				fill.Size = UDim2.fromScale(math.clamp(self.Hue, 0.04, 0.96), 1)
			else
				tween:Tween(fill, uipallet.Tween, {
					Size = UDim2.fromScale(math.clamp(self.Hue, 0.04, 0.96), 1)
				})
			end
		
			if s then
				tween:Tween(satSlider.Slider.Fill, uipallet.Tween, {
					Size = UDim2.fromScale(math.clamp(self.Sat, 0.04, 0.96), 1)
				})
			end
			if v then
				tween:Tween(vibSlider.Slider.Fill, uipallet.Tween, {
					Size = UDim2.fromScale(math.clamp(self.Value, 0.04, 0.96), 1)
				})
			end
			if o then
				tween:Tween(opSlider.Slider.Fill, uipallet.Tween, {
					Size = UDim2.fromScale(math.clamp(self.Opacity, 0.04, 0.96), 1)
				})
			end
		
			optionsettings.Function(self.Hue, self.Sat, self.Value, self.Opacity)
		end
		
		function optionapi:Toggle()
			self.Rainbow = not self.Rainbow
			if self.Rainbow then
				table.insert(mainapi.RainbowTable, self)
				rainbow1.ImageColor3 = Color3.fromRGB(5, 127, 100)
				task.delay(0.1, function()
					if not self.Rainbow then return end
					rainbow2.ImageColor3 = Color3.fromRGB(228, 125, 43)
					task.delay(0.1, function()
						if not self.Rainbow then return end
						rainbow3.ImageColor3 = Color3.fromRGB(225, 46, 52)
					end)
				end)
			else
				local ind = table.find(mainapi.RainbowTable, self)
				if ind then
					table.remove(mainapi.RainbowTable, ind)
				end
				rainbow3.ImageColor3 = color.Light(uipallet.Main, 0.37)
				task.delay(0.1, function()
					if self.Rainbow then return end
					rainbow2.ImageColor3 = color.Light(uipallet.Main, 0.37)
					task.delay(0.1, function()
						if self.Rainbow then return end
						rainbow1.ImageColor3 = color.Light(uipallet.Main, 0.37)
					end)
				end)
			end
		end
		
		local doubleClick = tick()
		preview.MouseButton1Click:Connect(function()
			preview.Visible = false
			valuebox.Visible = true
			valuebox:CaptureFocus()
			local text = Color3.fromHSV(optionapi.Hue, optionapi.Sat, optionapi.Value)
			valuebox.Text = math.round(text.R * 255)..', '..math.round(text.G * 255)..', '..math.round(text.B * 255)
		end)
		slider.InputBegan:Connect(function(inputObj)
			if
				(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
				and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
			then
				if doubleClick > tick() then
					optionapi:Toggle()
				end
				doubleClick = tick() + 0.3
				local changed = inputService.InputChanged:Connect(function(input)
					if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
						optionapi:SetValue(math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1))
					end
				end)
		
				local ended
				ended = inputObj.Changed:Connect(function()
					if inputObj.UserInputState == Enum.UserInputState.End then
						if changed then
							changed:Disconnect()
						end
						if ended then
							ended:Disconnect()
						end
					end
				end)
			end
		end)
		slider.MouseEnter:Connect(function()
			tween:Tween(knob, uipallet.Tween, {
				Size = UDim2.fromOffset(16, 16)
			})
		end)
		slider.MouseLeave:Connect(function()
			tween:Tween(knob, uipallet.Tween, {
				Size = UDim2.fromOffset(14, 14)
			})
		end)
		slider:GetPropertyChangedSignal('Visible'):Connect(function()
			satSlider.Visible = expand.Rotation == 180 and slider.Visible
			vibSlider.Visible = satSlider.Visible
			opSlider.Visible = satSlider.Visible
		end)
		expandbutton.MouseEnter:Connect(function()
			expand.ImageColor3 = color.Dark(uipallet.Text, 0.16)
		end)
		expandbutton.MouseLeave:Connect(function()
			expand.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		end)
		expandbutton.MouseButton1Click:Connect(function()
			satSlider.Visible = not satSlider.Visible
			vibSlider.Visible = satSlider.Visible
			opSlider.Visible = satSlider.Visible
			expand.Rotation = satSlider.Visible and 180 or 0
		end)
		rainbow.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)
		valuebox.FocusLost:Connect(function(enter)
			preview.Visible = true
			valuebox.Visible = false
			if enter then
				local commas = valuebox.Text:split(',')
				local suc, res = pcall(function()
					return tonumber(commas[1]) and Color3.fromRGB(tonumber(commas[1]), tonumber(commas[2]), tonumber(commas[3])) or Color3.fromHex(valuebox.Text)
				end)
				if suc then
					if optionapi.Rainbow then
						optionapi:Toggle()
					end
					optionapi:SetValue(res:ToHSV())
				end
			end
		end)
		
		optionapi.Object = slider
		api.Options[optionsettings.Name] = optionapi
		
		return optionapi
	end,
	Dropdown = function(optionsettings, children, api)
		local optionapi = {
			Type = 'Dropdown',
			Value = optionsettings.List[1] or 'None',
			Index = 0
		}
		
		local dropdown = Instance.new('TextButton')
		dropdown.Name = optionsettings.Name..'Dropdown'
		dropdown.Size = UDim2.new(1, 0, 0, 41)
		dropdown.BackgroundTransparency = 1
		dropdown.Visible = optionsettings.Visible == nil or optionsettings.Visible
		dropdown.Text = ''
		dropdown.Parent = children
		--addTooltip(dropdown, optionsettings.Tooltip or optionsettings.Name)
		local accentbar = Instance.new('Frame')
		accentbar.Size = UDim2.new(0, 4, 1, 0)
		accentbar.BackgroundColor3 = uipallet.Main
		accentbar.BorderSizePixel = 0
		accentbar.Parent = dropdown
		local button = Instance.new('TextButton')
		button.Name = 'Dropdown'
		button.Size = UDim2.new(1, -22, 1, -14)
		button.Position = UDim2.fromOffset(11, 7)
		button.BackgroundColor3 = uipallet.Main
		button.AutoButtonColor = false
		button.Text = ''
		button.Parent = dropdown
		addCorner(button, UDim.new(0, 4))
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -10, 0, 27)
		title.Position = UDim2.fromOffset(10, 0)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name..' · '..optionapi.Value
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 14
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.FontFace = uipallet.FontSemiBold
		title.Parent = button
		local dropdownexpand = Instance.new('ImageButton')
		dropdownexpand.Size = UDim2.fromOffset(6, 10)
		dropdownexpand.Position = UDim2.new(1, -15, 0, 14)
		dropdownexpand.AnchorPoint = Vector2.new(0.5, 0.5)
		dropdownexpand.BackgroundTransparency = 1
		dropdownexpand.Image = getcustomasset('catsix/assets/liquidbounce/expand.png')
		dropdownexpand.Parent = button
		optionsettings.Function = optionsettings.Function or function() end
		local dropdownchildren
		
		function optionapi:Save(tab)
			tab[optionsettings.Name] = {Value = self.Value}
		end
		
		function optionapi:Load(tab)
			if self.Value ~= tab.Value then
				self:SetValue(tab.Value)
			end
		end
		
		function optionapi:Change(list)
			optionsettings.List = list or {}
			if not table.find(optionsettings.List, self.Value) then
				self:SetValue(self.Value)
			end
		end
		
		function optionapi:SetValue(val, mouse)
			self.Value = table.find(optionsettings.List, val) and val or optionsettings.List[1] or 'None'
			title.Text = optionsettings.Name..' · '..self.Value
			if dropdownchildren then
				dropdownchildren:Destroy()
				dropdownchildren = nil
				dropdown.Size = UDim2.new(1, 0, 0, 41)
			end
			optionsettings.Function(self.Value, mouse)
		end
		
		button.MouseButton1Click:Connect(function()
			if not dropdownchildren then
				dropdown.Size = UDim2.new(1, 0, 0, 45 + #optionsettings.List * 30)
				dropdownchildren = Instance.new('Frame')
				dropdownchildren.Name = 'Children'
				dropdownchildren.Size = UDim2.new(1, -2, 0, 3 + #optionsettings.List * 30)
				dropdownchildren.Position = UDim2.fromOffset(1, 27)
				dropdownchildren.BackgroundColor3 = Color3.new()
				dropdownchildren.BorderSizePixel = 0
				dropdownchildren.Parent = button
				addCorner(dropdownchildren, UDim.new(0, 5))
				local ind = 0
				for _, v in optionsettings.List do
					local dropdownoption = Instance.new('TextButton')
					dropdownoption.Name = v..'Option'
					dropdownoption.Size = UDim2.new(1, 0, 0, 30)
					dropdownoption.Position = UDim2.fromOffset(0, ind * 30)
					dropdownoption.BackgroundColor3 = Color3.new()
					dropdownoption.BorderSizePixel = 0
					dropdownoption.AutoButtonColor = false
					dropdownoption.Text = v
					dropdownoption.TextColor3 = v == optionapi.Value and uipallet.Main or color.Dark(uipallet.Text, 0.2)
					dropdownoption.TextSize = 14
					dropdownoption.TextTruncate = Enum.TextTruncate.AtEnd
					dropdownoption.FontFace = uipallet.FontSemiBold
					dropdownoption.Parent = dropdownchildren
					dropdownoption.MouseButton1Click:Connect(function()
						optionapi:SetValue(v, true)
						tween:Tween(dropdownexpand, createTween(0.4), {
							Rotation = 0
						}, tween.tweenstwo)
					end)
					ind += 1
				end
			else
				optionapi:SetValue(optionapi.Value, true)
			end
		
			tween:Tween(dropdownexpand, createTween(0.4), {
				Rotation = dropdownchildren and 90 or 0
			}, tween.tweenstwo)
		end)
		
		optionapi.Object = dropdown
		api.Options[optionsettings.Name] = optionapi
		
		return optionapi
	end,
	Font = function(optionsettings, children, api)
		local fonts = {
			optionsettings.Blacklist,
			'Custom'
		}
		for _, v in Enum.Font:GetEnumItems() do
			if not table.find(fonts, v.Name) then
				table.insert(fonts, v.Name)
			end
		end
		
		local optionapi = {Value = Font.fromEnum(Enum.Font[fonts[1]])}
		local fontdropdown
		local fontbox
		optionsettings.Function = optionsettings.Function or function() end
		
		fontdropdown = components.Dropdown({
			Name = optionsettings.Name,
			List = fonts,
			Function = function(val)
				fontbox.Object.Visible = val == 'Custom' and fontdropdown.Object.Visible
				if val ~= 'Custom' then
					optionapi.Value = Font.fromEnum(Enum.Font[val])
					optionsettings.Function(optionapi.Value)
				else
					pcall(function()
						optionapi.Value = Font.fromId(tonumber(fontbox.Value))
					end)
					optionsettings.Function(optionapi.Value)
				end
			end,
			Darker = optionsettings.Darker,
			Visible = optionsettings.Visible
		}, children, api)
		optionapi.Object = fontdropdown.Object
		fontbox = components.TextBox({
			Name = optionsettings.Name..' Asset',
			Placeholder = 'font (rbxasset)',
			Function = function()
				if fontdropdown.Value == 'Custom' then
					pcall(function()
						optionapi.Value = Font.fromId(tonumber(fontbox.Value))
					end)
					optionsettings.Function(optionapi.Value)
				end
			end,
			Visible = false,
			Darker = true
		}, children, api)
		
		fontdropdown.Object:GetPropertyChangedSignal('Visible'):Connect(function()
			fontbox.Object.Visible = fontdropdown.Object.Visible and fontdropdown.Value == 'Custom'
		end)
		
		return optionapi
	end,
	Slider = function(optionsettings, children, api)
		local optionapi = {
			Type = 'Slider',
			Value = optionsettings.Default or optionsettings.Min,
			Max = optionsettings.Max,
			Index = getTableSize(api.Options)
		}
		
		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.new(1, 0, 0, 46)
		slider.BackgroundTransparency = 1
		slider.Visible = optionsettings.Visible == nil or optionsettings.Visible
		slider.Text = ''
		slider.Parent = children
		--addTooltip(slider, optionsettings.Tooltip)
		local accentbar = Instance.new('Frame')
		accentbar.Size = UDim2.new(0, 4, 1, 0)
		accentbar.BackgroundColor3 = uipallet.Main
		accentbar.BorderSizePixel = 0
		accentbar.Parent = slider
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.fromOffset(60, 15)
		title.Position = UDim2.fromOffset(10, 7)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 14
		title.FontFace = uipallet.FontSemiBold
		title.Parent = slider
		local valuebutton = Instance.new('TextButton')
		valuebutton.Name = 'Value'
		valuebutton.Size = UDim2.fromOffset(60, 15)
		valuebutton.Position = UDim2.new(1, -69, 0, 7)
		valuebutton.BackgroundTransparency = 1
		valuebutton.Text = optionapi.Value..(optionsettings.Suffix and ' '..(type(optionsettings.Suffix) == 'function' and optionsettings.Suffix(optionapi.Value) or optionsettings.Suffix) or '')
		valuebutton.TextXAlignment = Enum.TextXAlignment.Right
		valuebutton.TextColor3 = uipallet.Text
		valuebutton.TextSize = 14
		valuebutton.FontFace = uipallet.FontSemiBold
		valuebutton.Parent = slider
		local valuebox = Instance.new('TextBox')
		valuebox.Name = 'Box'
		valuebox.Size = valuebutton.Size
		valuebox.Position = valuebutton.Position
		valuebox.BackgroundTransparency = 1
		valuebox.Visible = false
		valuebox.Text = optionapi.Value
		valuebox.TextXAlignment = Enum.TextXAlignment.Right
		valuebox.TextColor3 = uipallet.Text
		valuebox.TextSize = 14
		valuebox.FontFace = uipallet.FontSemiBold
		valuebox.ClearTextOnFocus = false
		valuebox.Parent = slider
		local bkg = Instance.new('Frame')
		bkg.Name = 'Slider'
		bkg.Size = UDim2.new(1, -22, 0, 2)
		bkg.Position = UDim2.fromOffset(11, 32)
		bkg.BackgroundColor3 = color.Dark(uipallet.Text, 0.8)
		bkg.BorderSizePixel = 0
		bkg.Parent = slider
		local fill = bkg:Clone()
		fill.Name = 'Fill'
		fill.Size = UDim2.fromScale(math.clamp((optionapi.Value - optionsettings.Min) / optionsettings.Max, 0.03, 0.97), 1)
		fill.Position = UDim2.new()
		fill.BackgroundColor3 = uipallet.Main
		fill.BorderSizePixel = 0
		fill.Parent = bkg
		local knobholder = Instance.new('Frame')
		knobholder.Name = 'Knob'
		knobholder.Size = UDim2.fromOffset(24, 4)
		knobholder.Position = UDim2.fromScale(1, 0.5)
		knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
		knobholder.BackgroundTransparency = 1
		knobholder.Parent = fill
		local knob = Instance.new('Frame')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(14, 14)
		knob.Position = UDim2.fromScale(0.5, 0.5)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundColor3 = uipallet.Main
		knob.Parent = knobholder
		addCorner(knob, UDim.new(1, 0))
		optionsettings.Function = optionsettings.Function or function() end
		optionsettings.Decimal = optionsettings.Decimal or 1
		
		function optionapi:Save(tab)
			tab[optionsettings.Name] = {
				Value = self.Value,
				Max = self.Max
			}
		end
		
		function optionapi:Load(tab)
			local newval = tab.Value == tab.Max and tab.Max ~= self.Max and self.Max or tab.Value
			if self.Value ~= newval then
				self:SetValue(newval, nil, true)
			end
		end
		
		function optionapi:SetValue(value, pos, final)
			if tonumber(value) == math.huge or value ~= value then return end
			local check = self.Value ~= value
			self.Value = value
			tween:Tween(fill, uipallet.Tween, {
				Size = UDim2.fromScale(math.clamp(pos or math.clamp(value / optionsettings.Max, 0, 1), 0.03, 0.97), 1)
			})
			valuebutton.Text = self.Value..(optionsettings.Suffix and ' '..(type(optionsettings.Suffix) == 'function' and optionsettings.Suffix(self.Value) or optionsettings.Suffix) or '')
			if check or final then
				optionsettings.Function(value, final)
			end
		end
		
		slider.InputBegan:Connect(function(inputObj)
			if
				(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
				and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
			then
				local newPosition = math.clamp((inputObj.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1)
				optionapi:SetValue(math.floor((optionsettings.Min + (optionsettings.Max - optionsettings.Min) * newPosition) * optionsettings.Decimal) / optionsettings.Decimal, newPosition)
				local lastValue = optionapi.Value
				local lastPosition = newPosition
		
				local changed = inputService.InputChanged:Connect(function(input)
					if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
						local newPosition = math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1)
						optionapi:SetValue(math.floor((optionsettings.Min + (optionsettings.Max - optionsettings.Min) * newPosition) * optionsettings.Decimal) / optionsettings.Decimal, newPosition)
						lastValue = optionapi.Value
						lastPosition = newPosition
					end
				end)
		
				local ended
				ended = inputObj.Changed:Connect(function()
					if inputObj.UserInputState == Enum.UserInputState.End then
						if changed then
							changed:Disconnect()
						end
						if ended then
							ended:Disconnect()
						end
						optionapi:SetValue(lastValue, lastPosition, true)
					end
				end)
		
			end
		end)
		valuebutton.MouseButton1Click:Connect(function()
			valuebutton.Visible = false
			valuebox.Visible = true
			valuebox.Text = optionapi.Value
			valuebox:CaptureFocus()
		end)
		valuebox.FocusLost:Connect(function(enter)
			valuebutton.Visible = true
			valuebox.Visible = false
			if enter and tonumber(valuebox.Text) then
				optionapi:SetValue(tonumber(valuebox.Text), nil, true)
			end
		end)
		
		optionapi.Object = slider
		api.Options[optionsettings.Name] = optionapi
		
		return optionapi
	end,
	Targets = function(optionsettings, children, api)
		local optionapi = {
			Type = 'Targets',
			Index = getTableSize(api.Options)
		}
		
		local textlist = Instance.new('TextButton')
		textlist.Name = 'Targets'
		textlist.Size = UDim2.new(1, 0, 0, 50)
		textlist.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		textlist.BorderSizePixel = 0
		textlist.AutoButtonColor = false
		textlist.Visible = optionsettings.Visible == nil or optionsettings.Visible
		textlist.Text = ''
		textlist.Parent = children
		--addTooltip(textlist, optionsettings.Tooltip)
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -20, 1, -9)
		bkg.Position = UDim2.fromOffset(10, 4)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.Parent = textlist
		addCorner(bkg, UDim.new(0, 4))
		local button = Instance.new('TextButton')
		button.Name = 'TextList'
		button.Size = UDim2.new(1, -2, 1, -2)
		button.Position = UDim2.fromOffset(1, 1)
		button.BackgroundColor3 = uipallet.Main
		button.AutoButtonColor = false
		button.Text = ''
		button.Parent = bkg
		local buttontitle = Instance.new('TextLabel')
		buttontitle.Name = 'Title'
		buttontitle.Size = UDim2.new(1, -5, 0, 15)
		buttontitle.Position = UDim2.fromOffset(5, 6)
		buttontitle.BackgroundTransparency = 1
		buttontitle.Text = 'Target:'
		buttontitle.TextXAlignment = Enum.TextXAlignment.Left
		buttontitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
		buttontitle.TextSize = 15
		buttontitle.TextTruncate = Enum.TextTruncate.AtEnd
		buttontitle.FontFace = uipallet.Font
		buttontitle.Parent = button
		local items = buttontitle:Clone()
		items.Name = 'Items'
		items.Position = UDim2.fromOffset(5, 21)
		items.Text = 'Ignore none'
		items.TextColor3 = color.Dark(uipallet.Text, 0.16)
		items.TextSize = 11
		items.Parent = button
		addCorner(button, UDim.new(0, 4))
		local tool = Instance.new('Frame')
		tool.Size = UDim2.fromOffset(65, 12)
		tool.Position = UDim2.fromOffset(52, 8)
		tool.BackgroundTransparency = 1
		tool.Parent = button
		local toollist = Instance.new('UIListLayout')
		toollist.FillDirection = Enum.FillDirection.Horizontal
		toollist.Padding = UDim.new(0, 6)
		toollist.Parent = tool
		local window = Instance.new('TextButton')
		window.Name = 'TargetsTextWindow'
		window.Size = UDim2.fromOffset(220, 145)
		window.BackgroundColor3 = uipallet.Main
		window.BorderSizePixel = 0
		window.AutoButtonColor = false
		window.Visible = false
		window.Text = ''
		window.Parent = clickgui
		optionapi.Window = window
		addBlur(window)
		addCorner(window)
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = UDim2.fromOffset(18, 12)
		icon.Position = UDim2.fromOffset(10, 15)
		icon.BackgroundTransparency = 1
		icon.Image = getcustomasset('catsix/assets/new/targetstab.png')
		icon.Parent = window
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -36, 0, 20)
		title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 11)
		title.BackgroundTransparency = 1
		title.Text = 'Target settings'
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = window
		--local close = addCloseButton(window)
		optionsettings.Function = optionsettings.Function or function() end
		
		function optionapi:Save(tab)
			tab.Targets = {
				Players = self.Players.Enabled,
				NPCs = self.NPCs.Enabled,
				Invisible = self.Invisible.Enabled,
				Walls = self.Walls.Enabled
			}
		end
		
		function optionapi:Load(tab)
			if self.Players.Enabled ~= tab.Players then
				self.Players:Toggle()
			end
			if self.NPCs.Enabled ~= tab.NPCs then
				self.NPCs:Toggle()
			end
			if self.Invisible.Enabled ~= tab.Invisible then
				self.Invisible:Toggle()
			end
			if self.Walls.Enabled ~= tab.Walls then
				self.Walls:Toggle()
			end
		end
		
		function optionapi:Color(hue, sat, val, rainbowcheck)
			bkg.BackgroundColor3 = rainbowcheck and Color3.fromHSV(mainapi:Color((hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
			if self.Players.Enabled then
				tween:Cancel(self.Players.Object.Frame)
				self.Players.Object.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			end
			if self.NPCs.Enabled then
				tween:Cancel(self.NPCs.Object.Frame)
				self.NPCs.Object.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			end
			if self.Invisible.Enabled then
				tween:Cancel(self.Invisible.Object.Knob)
				self.Invisible.Object.Knob.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			end
			if self.Walls.Enabled then
				tween:Cancel(self.Walls.Object.Knob)
				self.Walls.Object.Knob.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			end
		end
		
		optionapi.Players = components.TargetsButton({
			Position = UDim2.fromOffset(11, 45),
			Icon = getcustomasset('catsix/assets/new/targetplayers1.png'),
			IconSize = UDim2.fromOffset(15, 16),
			IconParent = tool,
			ToolIcon = getcustomasset('catsix/assets/new/targetplayers2.png'),
			ToolSize = UDim2.fromOffset(11, 12),
			Tooltip = 'Players',
			Function = optionsettings.Function
		}, window, tool)
		optionapi.NPCs = components.TargetsButton({
			Position = UDim2.fromOffset(112, 45),
			Icon = getcustomasset('catsix/assets/new/targetnpc1.png'),
			IconSize = UDim2.fromOffset(12, 16),
			IconParent = tool,
			ToolIcon = getcustomasset('catsix/assets/new/targetnpc2.png'),
			ToolSize = UDim2.fromOffset(9, 12),
			Tooltip = 'NPCs',
			Function = optionsettings.Function
		}, window, tool)
		optionapi.Invisible = components.Toggle({
			Name = 'Ignore invisible',
			Function = function()
				local text = 'none'
				if optionapi.Invisible.Enabled then
					text = 'invisible'
				end
				if optionapi.Walls.Enabled then
					text = text == 'none' and 'behind walls' or text..', behind walls'
				end
				items.Text = 'Ignore '..text
				optionsettings.Function()
			end
		}, window, {Options = {}})
		optionapi.Invisible.Object.Position = UDim2.fromOffset(0, 81)
		optionapi.Walls = components.Toggle({
			Name = 'Ignore behind walls',
			Function = function()
				local text = 'none'
				if optionapi.Invisible.Enabled then
					text = 'invisible'
				end
				if optionapi.Walls.Enabled then
					text = text == 'none' and 'behind walls' or text..', behind walls'
				end
				items.Text = 'Ignore '..text
				optionsettings.Function()
			end
		}, window, {Options = {}})
		optionapi.Walls.Object.Position = UDim2.fromOffset(0, 111)
		if optionsettings.Players then
			optionapi.Players:Toggle()
		end
		if optionsettings.NPCs then
			optionapi.NPCs:Toggle()
		end
		if optionsettings.Invisible then
			optionapi.Invisible:Toggle()
		end
		if optionsettings.Walls then
			optionapi.Walls:Toggle()
		end
		
		--close.MouseButton1Click:Connect(function()
		--	window.Visible = false
		--end)
		button.MouseButton1Click:Connect(function()
			window.Visible = not window.Visible
			tween:Cancel(bkg)
			bkg.BackgroundColor3 = window.Visible and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Light(uipallet.Main, 0.37)
		end)
		textlist.MouseEnter:Connect(function()
			if not optionapi.Window.Visible then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.37)
				})
			end
		end)
		textlist.MouseLeave:Connect(function()
			if not optionapi.Window.Visible then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.034)
				})
			end
		end)
		textlist:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			local actualPosition = (textlist.AbsolutePosition + Vector2.new(0, 60)) / scale.Scale
			window.Position = UDim2.fromOffset(actualPosition.X + 220, actualPosition.Y)
		end)
		
		optionapi.Object = textlist
		api.Options.Targets = optionapi
		
		return optionapi
	end,
	TargetsButton = function(optionsettings, children, api)
		local optionapi = {Enabled = false}
		
		local targetbutton = Instance.new('TextButton')
		targetbutton.Size = UDim2.fromOffset(98, 31)
		targetbutton.Position = optionsettings.Position
		targetbutton.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
		targetbutton.AutoButtonColor = false
		targetbutton.Visible = optionsettings.Visible == nil or optionsettings.Visible
		targetbutton.Text = ''
		targetbutton.Parent = children
		addCorner(targetbutton)
		--addTooltip(targetbutton, optionsettings.Tooltip)
		local bkg = Instance.new('Frame')
		bkg.Size = UDim2.new(1, -2, 1, -2)
		bkg.Position = UDim2.fromOffset(1, 1)
		bkg.BackgroundColor3 = uipallet.Main
		bkg.Parent = targetbutton
		addCorner(bkg)
		local icon = Instance.new('ImageLabel')
		icon.Size = optionsettings.IconSize
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = optionsettings.Icon
		icon.ImageColor3 = color.Light(uipallet.Main, 0.37)
		icon.Parent = bkg
		optionsettings.Function = optionsettings.Function or function() end
		local tooltipicon
		
		function optionapi:Toggle()
			self.Enabled = not self.Enabled
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = self.Enabled and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or uipallet.Main
			})
			tween:Tween(icon, uipallet.Tween, {
				ImageColor3 = self.Enabled and Color3.new(1, 1, 1) or color.Light(uipallet.Main, 0.37)
			})
			if tooltipicon then
				tooltipicon:Destroy()
			end
			if self.Enabled then
				tooltipicon = Instance.new('ImageLabel')
				tooltipicon.Size = optionsettings.ToolSize
				tooltipicon.BackgroundTransparency = 1
				tooltipicon.Image = optionsettings.ToolIcon
				tooltipicon.ImageColor3 = uipallet.Text
				tooltipicon.Parent = optionsettings.IconParent
			end
			optionsettings.Function(self.Enabled)
		end
		
		targetbutton.MouseEnter:Connect(function()
			if not optionapi.Enabled then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value - 0.25)
				})
				tween:Tween(icon, uipallet.Tween, {
					ImageColor3 = Color3.new(1, 1, 1)
				})
			end
		end)
		targetbutton.MouseLeave:Connect(function()
			if not optionapi.Enabled then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = uipallet.Main
				})
				tween:Tween(icon, uipallet.Tween, {
					ImageColor3 = color.Light(uipallet.Main, 0.37)
				})
			end
		end)
		targetbutton.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)
		
		optionapi.Object = targetbutton
		
		return optionapi
	end,
	TextBox = function(optionsettings, children, api)
		local optionapi = {
			Type = 'TextBox',
			Value = optionsettings.Default or '',
			Index = 0
		}
		
		local textbox = Instance.new('TextButton')
		textbox.Name = optionsettings.Name..'TextBox'
		textbox.Size = UDim2.new(1, 0, 0, 60)
		textbox.BackgroundTransparency = 1
		textbox.Visible = optionsettings.Visible == nil or optionsettings.Visible
		textbox.Text = ''
		textbox.Parent = children
		--addTooltip(textbox, optionsettings.Tooltip)
		local accentbar = Instance.new('Frame')
		accentbar.Size = UDim2.new(0, 4, 1, 0)
		accentbar.BackgroundColor3 = uipallet.Main
		accentbar.BorderSizePixel = 0
		accentbar.Parent = textbox
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.fromOffset(60, 15)
		title.Position = UDim2.fromOffset(10, 7)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 14
		title.FontFace = uipallet.FontSemiBold
		title.Parent = textbox
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -22, 0, 26)
		bkg.Position = UDim2.fromOffset(11, 28)
		bkg.BackgroundColor3 = uipallet.Main
		bkg.Parent = textbox
		addCorner(bkg, UDim.new(0, 4))
		local bkg2 = bkg:Clone()
		bkg2.Size = UDim2.new(1, 0, 1, -1)
		bkg2.Position = UDim2.fromOffset(0, -1)
		bkg2.BackgroundColor3 = Color3.new()
		bkg2.Parent = bkg
		local box = Instance.new('TextBox')
		box.Size = UDim2.new(1, -16, 1, -2)
		box.Position = UDim2.fromOffset(8, 0)
		box.BackgroundTransparency = 1
		box.Text = optionsettings.Default or ''
		box.PlaceholderText = optionsettings.Placeholder or 'Click to set'
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextColor3 = uipallet.Text
		box.PlaceholderColor3 = color.Dark(uipallet.Text, 0.31)
		box.TextSize = 14
		box.FontFace = uipallet.FontSemiBold
		box.ClearTextOnFocus = false
		box.ClipsDescendants = true
		box.Parent = bkg
		optionsettings.Function = optionsettings.Function or function() end
		
		function optionapi:Save(tab)
			tab[optionsettings.Name] = {Value = self.Value}
		end
		
		function optionapi:Load(tab)
			if self.Value ~= tab.Value then
				self:SetValue(tab.Value)
			end
		end
		
		function optionapi:SetValue(val, enter)
			self.Value = val
			box.Text = val
			optionsettings.Function(enter)
		end
		
		textbox.MouseButton1Click:Connect(function()
			box:CaptureFocus()
		end)
		box.FocusLost:Connect(function(enter)
			optionapi:SetValue(box.Text, enter)
		end)
		box:GetPropertyChangedSignal('Text'):Connect(function()
			optionapi:SetValue(box.Text)
		end)
		
		optionapi.Object = textbox
		api.Options[optionsettings.Name] = optionapi
		
		return optionapi
	end,
	TextList = function(optionsettings, children, api)
		local optionapi = {
			Type = 'TextList',
			List = optionsettings.Default or {},
			ListEnabled = optionsettings.Default or {},
			Objects = {},
			Window = {Visible = false},
			Index = getTableSize(api.Options)
		}
		optionsettings.Color = optionsettings.Color or Color3.fromRGB(5, 134, 105)
		
		local textlist = Instance.new('TextButton')
		textlist.Name = optionsettings.Name..'TextList'
		textlist.Size = UDim2.new(1, 0, 0, 50)
		textlist.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		textlist.BorderSizePixel = 0
		textlist.AutoButtonColor = false
		textlist.Visible = optionsettings.Visible == nil or optionsettings.Visible
		textlist.Text = ''
		textlist.Parent = children
		--addTooltip(textlist, optionsettings.Tooltip)
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -20, 1, -9)
		bkg.Position = UDim2.fromOffset(10, 4)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.Parent = textlist
		addCorner(bkg, UDim.new(0, 4))
		local button = Instance.new('TextButton')
		button.Name = 'TextList'
		button.Size = UDim2.new(1, -2, 1, -2)
		button.Position = UDim2.fromOffset(1, 1)
		button.BackgroundColor3 = uipallet.Main
		button.AutoButtonColor = false
		button.Text = ''
		button.Parent = bkg
		local buttonicon = Instance.new('ImageLabel')
		buttonicon.Name = 'Icon'
		buttonicon.Size = UDim2.fromOffset(14, 12)
		buttonicon.Position = UDim2.fromOffset(10, 14)
		buttonicon.BackgroundTransparency = 1
		buttonicon.Image = optionsettings.Icon or getcustomasset('catsix/assets/new/allowedicon.png')
		buttonicon.Parent = button
		local buttontitle = Instance.new('TextLabel')
		buttontitle.Name = 'Title'
		buttontitle.Size = UDim2.new(1, -35, 0, 15)
		buttontitle.Position = UDim2.fromOffset(35, 6)
		buttontitle.BackgroundTransparency = 1
		buttontitle.Text = optionsettings.Name
		buttontitle.TextXAlignment = Enum.TextXAlignment.Left
		buttontitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
		buttontitle.TextSize = 15
		buttontitle.TextTruncate = Enum.TextTruncate.AtEnd
		buttontitle.FontFace = uipallet.Font
		buttontitle.Parent = button
		local amount = buttontitle:Clone()
		amount.Name = 'Amount'
		amount.Size = UDim2.new(1, -13, 0, 15)
		amount.Position = UDim2.fromOffset(0, 6)
		amount.Text = '0'
		amount.TextXAlignment = Enum.TextXAlignment.Right
		amount.Parent = button
		local items = buttontitle:Clone()
		items.Name = 'Items'
		items.Position = UDim2.fromOffset(35, 21)
		items.Text = 'None'
		items.TextColor3 = color.Dark(uipallet.Text, 0.43)
		items.TextSize = 11
		items.Parent = button
		addCorner(button, UDim.new(0, 4))
		local window = Instance.new('TextButton')
		window.Name = optionsettings.Name..'TextWindow'
		window.Size = UDim2.fromOffset(220, 85)
		window.BackgroundColor3 = uipallet.Main
		window.BorderSizePixel = 0
		window.AutoButtonColor = false
		window.Visible = false
		window.Text = ''
		window.Parent = api.Legit and mainapi.Legit.Window or clickgui
		optionapi.Window = window
		addBlur(window)
		addCorner(window)
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = optionsettings.TabSize or UDim2.fromOffset(19, 16)
		icon.Position = UDim2.fromOffset(10, 13)
		icon.BackgroundTransparency = 1
		icon.Image = optionsettings.Tab or getcustomasset('catsix/assets/new/allowedtab.png')
		icon.Parent = window
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -36, 0, 20)
		title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 11)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = window
		--local close = addCloseButton(window)
		local addbkg = Instance.new('Frame')
		addbkg.Name = 'Add'
		addbkg.Size = UDim2.fromOffset(200, 31)
		addbkg.Position = UDim2.fromOffset(10, 45)
		addbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		addbkg.Parent = window
		addCorner(addbkg)
		local addbox = addbkg:Clone()
		addbox.Size = UDim2.new(1, -2, 1, -2)
		addbox.Position = UDim2.fromOffset(1, 1)
		addbox.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		addbox.Parent = addbkg
		local addvalue = Instance.new('TextBox')
		addvalue.Size = UDim2.new(1, -35, 1, 0)
		addvalue.Position = UDim2.fromOffset(10, 0)
		addvalue.BackgroundTransparency = 1
		addvalue.Text = ''
		addvalue.PlaceholderText = optionsettings.Placeholder or 'Add entry...'
		addvalue.TextXAlignment = Enum.TextXAlignment.Left
		addvalue.TextColor3 = Color3.new(1, 1, 1)
		addvalue.TextSize = 15
		addvalue.FontFace = uipallet.Font
		addvalue.ClearTextOnFocus = false
		addvalue.Parent = addbkg
		local addbutton = Instance.new('ImageButton')
		addbutton.Name = 'AddButton'
		addbutton.Size = UDim2.fromOffset(16, 16)
		addbutton.Position = UDim2.new(1, -26, 0, 8)
		addbutton.BackgroundTransparency = 1
		addbutton.Image = getcustomasset('catsix/assets/new/add.png')
		addbutton.ImageColor3 = optionsettings.Color
		addbutton.ImageTransparency = 0.3
		addbutton.Parent = addbkg
		optionsettings.Function = optionsettings.Function or function() end
		
		function optionapi:Save(tab)
			tab[optionsettings.Name] = {
				List = self.List,
				ListEnabled = self.ListEnabled
			}
		end
		
		function optionapi:Load(tab)
			self.List = tab.List or {}
			self.ListEnabled = tab.ListEnabled or {}
			self:ChangeValue()
		end
		
		function optionapi:Color(hue, sat, val, rainbowcheck)
			if window.Visible then
				bkg.BackgroundColor3 = rainbowcheck and Color3.fromHSV(mainapi:Color((hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
			end
		end
		
		function optionapi:ChangeValue(val)
			if val then
				local ind = table.find(self.List, val)
				if ind then
					table.remove(self.List, ind)
					ind = table.find(self.ListEnabled, val)
					if ind then
						table.remove(self.ListEnabled, ind)
					end
				else
					table.insert(self.List, val)
					table.insert(self.ListEnabled, val)
				end
			end
		
			optionsettings.Function(self.List)
			for _, v in self.Objects do
				v:Destroy()
			end
			table.clear(self.Objects)
			window.Size = UDim2.fromOffset(220, 85 + (#self.List * 35))
			amount.Text = #self.List
		
			local enabledtext = 'None'
			for i, v in self.ListEnabled do
				if i == 1 then enabledtext = '' end
				enabledtext = enabledtext..(i == 1 and v or ', '..v)
			end
			items.Text = enabledtext
		
			for i, v in self.List do
				local enabled = table.find(self.ListEnabled, v)
				local object = Instance.new('TextButton')
				object.Name = v
				object.Size = UDim2.fromOffset(200, 32)
				object.Position = UDim2.fromOffset(10, 47 + (i * 35))
				object.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				object.AutoButtonColor = false
				object.Text = ''
				object.Parent = window
				addCorner(object)
				local objectbkg = Instance.new('Frame')
				objectbkg.Name = 'BKG'
				objectbkg.Size = UDim2.new(1, -2, 1, -2)
				objectbkg.Position = UDim2.fromOffset(1, 1)
				objectbkg.BackgroundColor3 = uipallet.Main
				objectbkg.Visible = false
				objectbkg.Parent = object
				addCorner(objectbkg)
				local objectdot = Instance.new('Frame')
				objectdot.Name = 'Dot'
				objectdot.Size = UDim2.fromOffset(10, 11)
				objectdot.Position = UDim2.fromOffset(10, 12)
				objectdot.BackgroundColor3 = enabled and optionsettings.Color or color.Light(uipallet.Main, 0.37)
				objectdot.Parent = object
				addCorner(objectdot, UDim.new(1, 0))
				local objectdotin = objectdot:Clone()
				objectdotin.Size = UDim2.fromOffset(8, 9)
				objectdotin.Position = UDim2.fromOffset(1, 1)
				objectdotin.BackgroundColor3 = enabled and optionsettings.Color or color.Light(uipallet.Main, 0.02)
				objectdotin.Parent = objectdot
				local objecttitle = Instance.new('TextLabel')
				objecttitle.Name = 'Title'
				objecttitle.Size = UDim2.new(1, -30, 1, 0)
				objecttitle.Position = UDim2.fromOffset(30, 0)
				objecttitle.BackgroundTransparency = 1
				objecttitle.Text = v
				objecttitle.TextXAlignment = Enum.TextXAlignment.Left
				objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
				objecttitle.TextSize = 15
				objecttitle.FontFace = uipallet.Font
				objecttitle.Parent = object
				local close = Instance.new('ImageButton')
				close.Name = 'Close'
				close.Size = UDim2.fromOffset(16, 16)
				close.Position = UDim2.new(1, -26, 0, 8)
				close.BackgroundColor3 = Color3.new(1, 1, 1)
				close.BackgroundTransparency = 1
				close.AutoButtonColor = false
				close.Image = getcustomasset('catsix/assets/new/closemini.png')
				close.ImageColor3 = color.Light(uipallet.Text, 0.2)
				close.ImageTransparency = 0.5
				close.Parent = object
				addCorner(close, UDim.new(1, 0))
		
				close.MouseEnter:Connect(function()
					close.ImageTransparency = 0.3
					tween:Tween(close, uipallet.Tween, {
						BackgroundTransparency = 0.6
					})
				end)
				close.MouseLeave:Connect(function()
					close.ImageTransparency = 0.5
					tween:Tween(close, uipallet.Tween, {
						BackgroundTransparency = 1
					})
				end)
				close.MouseButton1Click:Connect(function()
					self:ChangeValue(v)
				end)
				object.MouseEnter:Connect(function()
					objectbkg.Visible = true
				end)
				object.MouseLeave:Connect(function()
					objectbkg.Visible = false
				end)
				object.MouseButton1Click:Connect(function()
					local ind = table.find(self.ListEnabled, v)
					if ind then
						table.remove(self.ListEnabled, ind)
						objectdot.BackgroundColor3 = color.Light(uipallet.Main, 0.37)
						objectdotin.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
					else
						table.insert(self.ListEnabled, v)
						objectdot.BackgroundColor3 = optionsettings.Color
						objectdotin.BackgroundColor3 = optionsettings.Color
					end
		
					local enabledtext = 'None'
					for i, v in self.ListEnabled do
						if i == 1 then enabledtext = '' end
						enabledtext = enabledtext..(i == 1 and v or ', '..v)
					end
		
					items.Text = enabledtext
					optionsettings.Function()
				end)
		
				table.insert(self.Objects, object)
			end
		end
		
		addbutton.MouseEnter:Connect(function()
			addbutton.ImageTransparency = 0
		end)
		addbutton.MouseLeave:Connect(function()
			addbutton.ImageTransparency = 0.3
		end)
		addbutton.MouseButton1Click:Connect(function()
			if not table.find(optionapi.List, addvalue.Text) then
				optionapi:ChangeValue(addvalue.Text)
				addvalue.Text = ''
			end
		end)
		addvalue.FocusLost:Connect(function(enter)
			if enter and not table.find(optionapi.List, addvalue.Text) then
				optionapi:ChangeValue(addvalue.Text)
				addvalue.Text = ''
			end
		end)
		addvalue.MouseEnter:Connect(function()
			tween:Tween(addbkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.14)
			})
		end)
		addvalue.MouseLeave:Connect(function()
			tween:Tween(addbkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			})
		end)
		--close.MouseButton1Click:Connect(function()
		--	window.Visible = false
		--end)
		button.MouseButton1Click:Connect(function()
			window.Visible = not window.Visible
			tween:Cancel(bkg)
			bkg.BackgroundColor3 = window.Visible and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Light(uipallet.Main, 0.37)
		end)
		textlist.MouseEnter:Connect(function()
			if not optionapi.Window.Visible then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.37)
				})
			end
		end)
		textlist.MouseLeave:Connect(function()
			if not optionapi.Window.Visible then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.034)
				})
			end
		end)
		textlist:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			local actualPosition = (textlist.AbsolutePosition - (api.Legit and mainapi.Legit.Window.AbsolutePosition or -guiService:GetGuiInset())) / scale.Scale
			window.Position = UDim2.fromOffset(actualPosition.X + 220, actualPosition.Y)
		end)
		
		if optionsettings.Default then
			optionapi:ChangeValue()
		end
		optionapi.Object = textlist
		api.Options[optionsettings.Name] = optionapi
		
		return optionapi
	end,
	Toggle = function(optionsettings, children, api)
		local optionapi = {
			Type = 'Toggle',
			Enabled = false,
			Index = getTableSize(api.Options)
		}
		
		local toggle = Instance.new('TextButton')
		toggle.Name = optionsettings.Name..'Toggle'
		toggle.Size = UDim2.new(1, 0, 0, 28)
		toggle.BackgroundTransparency = 1
		toggle.Visible = optionsettings.Visible == nil or optionsettings.Visible
		toggle.Text = ''
		toggle.Parent = children
		--addTooltip(toggle, optionsettings.Tooltip)
		local accentbar = Instance.new('Frame')
		accentbar.Size = UDim2.new(0, 4, 1, 0)
		accentbar.BackgroundColor3 = uipallet.Main
		accentbar.BorderSizePixel = 0
		accentbar.Parent = toggle
		local title = Instance.new('TextLabel')
		title.Size = UDim2.new(1, -40, 1, -2)
		title.Position = UDim2.fromOffset(40, 0)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 14
		title.FontFace = uipallet.FontSemiBold
		title.Parent = toggle
		local knobholder = Instance.new('Frame')
		knobholder.Name = 'Knob'
		knobholder.Size = UDim2.fromOffset(22, 8)
		knobholder.Position = UDim2.fromOffset(11, 10)
		knobholder.BackgroundColor3 = color.Dark(uipallet.Text, 0.2)
		knobholder.Parent = toggle
		addCorner(knobholder, UDim.new(1, 0))
		local knob = knobholder:Clone()
		knob.Size = UDim2.fromOffset(12, 12)
		knob.Position = UDim2.fromOffset(0, -2)
		knob.BackgroundColor3 = uipallet.Text
		knob.Parent = knobholder
		optionsettings.Function = optionsettings.Function or function() end
		
		function optionapi:Save(tab)
			tab[optionsettings.Name] = {Enabled = self.Enabled}
		end
		
		function optionapi:Load(tab)
			if self.Enabled ~= tab.Enabled then
				self:Toggle()
			end
		end
		
		function optionapi:Toggle()
			self.Enabled = not self.Enabled
			tween:Tween(knob, createTween(0.4), {
				BackgroundColor3 = self.Enabled and uipallet.Main or uipallet.Text,
				Position = UDim2.fromOffset(self.Enabled and 10 or 0, -2)
			})
			tween:Tween(knobholder, createTween(0.4), {
				BackgroundColor3 = self.Enabled and color.Saturate(uipallet.Main, 0.6) or color.Dark(uipallet.Text, 0.55)
			})
		
			optionsettings.Function(self.Enabled)
		end
		
		toggle.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)
		
		if optionsettings.Default then
			optionapi:Toggle()
		end
		optionapi.Object = toggle
		api.Options[optionsettings.Name] = optionapi
		
		return optionapi
	end,
	TwoSlider = function(optionsettings, children, api)
		local optionapi = {
			Type = 'TwoSlider',
			ValueMin = optionsettings.DefaultMin or optionsettings.Min,
			ValueMax = optionsettings.DefaultMax or 10,
			Max = optionsettings.Max,
			Index = getTableSize(api.Options)
		}
		
		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.new(1, 0, 0, 46)
		slider.BackgroundTransparency = 1
		slider.Visible = optionsettings.Visible == nil or optionsettings.Visible
		slider.Text = ''
		slider.Parent = children
		--addTooltip(slider, optionsettings.Tooltip)
		local accentbar = Instance.new('Frame')
		accentbar.Size = UDim2.new(0, 4, 1, 0)
		accentbar.BackgroundColor3 = uipallet.Main
		accentbar.BorderSizePixel = 0
		accentbar.Parent = slider
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.fromOffset(60, 15)
		title.Position = UDim2.fromOffset(10, 7)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 14
		title.FontFace = uipallet.FontSemiBold
		title.Parent = slider
		local valuebutton = Instance.new('TextButton')
		valuebutton.Name = 'Value'
		valuebutton.Size = UDim2.fromOffset(60, 15)
		valuebutton.Position = UDim2.new(1, -69, 0, 7)
		valuebutton.BackgroundTransparency = 1
		valuebutton.Text = optionapi.ValueMax
		valuebutton.TextXAlignment = Enum.TextXAlignment.Right
		valuebutton.TextColor3 = uipallet.Text
		valuebutton.TextSize = 14
		valuebutton.FontFace = uipallet.FontSemiBold
		valuebutton.Parent = slider
		local valuebutton2 = valuebutton:Clone()
		valuebutton2.Position = UDim2.new(1, -125, 0, 7)
		valuebutton2.Text = optionapi.ValueMin
		valuebutton2.Parent = slider
		local valuebox = Instance.new('TextBox')
		valuebox.Name = 'Box'
		valuebox.Size = valuebutton.Size
		valuebox.Position = valuebutton.Position
		valuebox.BackgroundTransparency = 1
		valuebox.Visible = false
		valuebox.Text = optionapi.ValueMin
		valuebox.TextXAlignment = Enum.TextXAlignment.Right
		valuebox.TextColor3 = uipallet.Text
		valuebox.TextSize = 14
		valuebox.FontFace = uipallet.FontSemiBold
		valuebox.ClearTextOnFocus = false
		valuebox.Parent = slider
		local valuebox2 = valuebox:Clone()
		valuebox2.Position = valuebutton2.Position
		valuebox2.Parent = slider
		local bkg = Instance.new('Frame')
		bkg.Name = 'Slider'
		bkg.Size = UDim2.new(1, -22, 0, 2)
		bkg.Position = UDim2.fromOffset(11, 32)
		bkg.BackgroundColor3 = color.Dark(uipallet.Text, 0.8)
		bkg.BorderSizePixel = 0
		bkg.Parent = slider
		local fill = bkg:Clone()
		fill.Name = 'Fill'
		fill.Position = UDim2.fromScale(math.clamp(optionapi.ValueMin / optionsettings.Max, 0.04, 0.96), 0)
		fill.Size = UDim2.fromScale(math.clamp(math.clamp(optionapi.ValueMax / optionsettings.Max, 0, 1), 0.04, 0.96) - fill.Position.X.Scale, 1)
		fill.BackgroundColor3 = uipallet.Main
		fill.Parent = bkg
		local knobholder = Instance.new('Frame')
		knobholder.Name = 'Knob'
		knobholder.Size = UDim2.fromOffset(24, 4)
		knobholder.Position = UDim2.fromScale(0, 0.5)
		knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
		knobholder.BackgroundTransparency = 1
		knobholder.Parent = fill
		local knob = Instance.new('Frame')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(14, 14)
		knob.Position = UDim2.fromScale(0.5, 0.5)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundColor3 = uipallet.Main
		knob.Parent = knobholder
		addCorner(knob, UDim.new(1, 0))
		local knobholdermax = knobholder:Clone()
		knobholdermax.Name = 'KnobMax'
		knobholdermax.Position = UDim2.fromScale(1, 0.5)
		knobholdermax.Parent = fill
		knobholdermax.Knob.Rotation = 180
		optionsettings.Function = optionsettings.Function or function() end
		optionsettings.Decimal = optionsettings.Decimal or 1
		local random = Random.new()
		
		function optionapi:Save(tab)
			tab[optionsettings.Name] = {ValueMin = self.ValueMin, ValueMax = self.ValueMax}
		end
		
		function optionapi:Load(tab)
			if self.ValueMin ~= tab.ValueMin then
				self:SetValue(false, tab.ValueMin)
			end
			if self.ValueMax ~= tab.ValueMax then
				self:SetValue(true, tab.ValueMax)
			end
		end
		
		function optionapi:Color(hue, sat, val, rainbowcheck)
			fill.BackgroundColor3 = rainbowcheck and Color3.fromHSV(mainapi:Color((hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
			knob.ImageColor3 = fill.BackgroundColor3
			knobholdermax.Knob.ImageColor3 = fill.BackgroundColor3
		end
		
		function optionapi:GetRandomValue()
			return random:NextNumber(optionapi.ValueMin, optionapi.ValueMax)
		end
		
		function optionapi:SetValue(max, value)
			if tonumber(value) == math.huge or value ~= value then return end
			self[max and 'ValueMax' or 'ValueMin'] = value
			valuebutton.Text = self.ValueMax
			valuebutton2.Text = self.ValueMin
			local size = math.clamp(math.clamp(self.ValueMin / optionsettings.Max, 0, 1), 0.03, 0.97)
			tween:Tween(fill, TweenInfo.new(0.1), {
				Position = UDim2.fromScale(size, 0),
				Size = UDim2.fromScale(math.clamp(math.clamp(math.clamp(self.ValueMax / optionsettings.Max, 0.04, 0.96), 0.03, 0.97) - size, 0, 1), 1)
			})
		end
		
		slider.InputBegan:Connect(function(inputObj)
			if
				(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
				and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
			then
				local maxCheck = (inputObj.Position.X - knobholdermax.AbsolutePosition.X) > -10
				local newPosition = math.clamp((inputObj.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1)
				optionapi:SetValue(maxCheck, math.floor((optionsettings.Min + (optionsettings.Max - optionsettings.Min) * newPosition) * optionsettings.Decimal) / optionsettings.Decimal, newPosition)
		
				local changed = inputService.InputChanged:Connect(function(input)
					if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
						local newPosition = math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1)
						optionapi:SetValue(maxCheck, math.floor((optionsettings.Min + (optionsettings.Max - optionsettings.Min) * newPosition) * optionsettings.Decimal) / optionsettings.Decimal, newPosition)
					end
				end)
		
				local ended
				ended = inputObj.Changed:Connect(function()
					if inputObj.UserInputState == Enum.UserInputState.End then
						if changed then
							changed:Disconnect()
						end
						if ended then
							ended:Disconnect()
						end
					end
				end)
			end
		end)
		valuebutton.MouseButton1Click:Connect(function()
			valuebutton.Visible = false
			valuebox.Visible = true
			valuebox.Text = optionapi.ValueMax
			valuebox:CaptureFocus()
		end)
		valuebutton2.MouseButton1Click:Connect(function()
			valuebutton2.Visible = false
			valuebox2.Visible = true
			valuebox2.Text = optionapi.ValueMin
			valuebox2:CaptureFocus()
		end)
		valuebox.FocusLost:Connect(function(enter)
			valuebutton.Visible = true
			valuebox.Visible = false
			if enter and tonumber(valuebox.Text) then
				optionapi:SetValue(true, tonumber(valuebox.Text))
			end
		end)
		valuebox2.FocusLost:Connect(function(enter)
			valuebutton2.Visible = true
			valuebox2.Visible = false
			if enter and tonumber(valuebox2.Text) then
				optionapi:SetValue(false, tonumber(valuebox2.Text))
			end
		end)
		
		optionapi.Object = slider
		api.Options[optionsettings.Name] = optionapi
		
		return optionapi
	end,
	Divider = function(children, text)

	end
}

mainapi.Components = setmetatable(components, {
	__newindex = function(self, ind, func)
		for _, v in mainapi.Modules do
			rawset(v, 'Create'..ind, function(_, settings)
				return func(settings, v.Children, v)
			end)
		end

		if mainapi.Legit then
			for _, v in mainapi.Legit.Modules do
				rawset(v, 'Create'..ind, function(_, settings)
					return func(settings, v.Children, v)
				end)
			end
		end

		rawset(self, ind, func)
	end
})

task.spawn(function()
	repeat
		local hue = tick() * (0.2 * mainapi.RainbowSpeed.Value) % 1
		for _, v in mainapi.RainbowTable do
			if v.Type == 'GUISlider' then
				v:SetValue(mainapi:Color(hue))
			else
				v:SetValue(hue)
			end
		end
		task.wait(1 / mainapi.RainbowUpdateSpeed.Value)
	until mainapi.Loaded == nil
end)

function mainapi:BlurCheck()
	if self.ThreadFix then
		setthreadidentity(8)
		runService:SetRobloxGuiFocused((clickgui.Visible or guiService:GetErrorType() ~= Enum.ConnectionError.OK) and self.Blur.Enabled)
	end
end

addMaid(mainapi)

function mainapi:CreateCategory(categorysettings)
	local categoryapi = {
		Type = 'Category',
		Expanded = false
	}

	local window = Instance.new('CanvasGroup')
	window.Name = categorysettings.Name..'Category'
	window.Size = UDim2.fromOffset(250, 39)
	window.Position = UDim2.fromOffset(236, 60)
	window.BackgroundTransparency = 1
	window.Parent = clickgui
	local titlebar = Instance.new('Frame')
	titlebar.Size = UDim2.fromOffset(250, 39)
	titlebar.BackgroundColor3 = Color3.new()
	titlebar.BackgroundTransparency = 0.1
	titlebar.BorderSizePixel = 0
	titlebar.Parent = window
	local title = Instance.new('TextLabel')
	title.Size = UDim2.new(1, -44, 1, -2)
	title.Position = UDim2.fromOffset(44, 0)
	title.BackgroundTransparency = 1
	title.Text = categorysettings.Name
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 16
	title.FontFace = uipallet.FontSemiBold
	title.Parent = titlebar
	local icon = Instance.new('ImageLabel')
	icon.Size = categorysettings.Size or UDim2.fromOffset(15, 15)
	icon.Position = UDim2.fromOffset(24, 18)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = categorysettings.Icon
	icon.Parent = titlebar
	local expandbar1 = Instance.new('Frame')
	expandbar1.Size = UDim2.fromOffset(2, 12)
	expandbar1.Position = UDim2.new(1, -21, 0.5, 0)
	expandbar1.AnchorPoint = Vector2.new(0.5, 0.5)
	expandbar1.BackgroundColor3 = uipallet.Text
	expandbar1.BorderSizePixel = 0
	expandbar1.Parent = title
	local expandbar2 = expandbar1:Clone()
	expandbar2.Rotation = 90
	expandbar2.Parent = title
	local divider = Instance.new('Frame')
	divider.Size = UDim2.fromOffset(250, 2)
	divider.Position = UDim2.fromOffset(0, 37)
	divider.BackgroundColor3 = uipallet.Main
	divider.BorderSizePixel = 0
	divider.Parent = titlebar
	addCorner(window)
	makeDraggable(window)
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -39)
	children.Position = UDim2.fromOffset(0, 39)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.Visible = true
	children.ScrollBarThickness = 0
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children

	function categoryapi:CreateModule(modulesettings)
		mainapi:Remove(modulesettings.Name)
		local moduleapi = {
			Enabled = false,
			Options = {},
			Bind = {},
			Index = getTableSize(mainapi.Modules),
			ExtraText = modulesettings.ExtraText,
			Name = modulesettings.Name,
			Category = categorysettings.Name
		}

		local hovered = false
		local modulebutton = Instance.new('TextButton')
		modulebutton.Name = modulesettings.Name
		modulebutton.Size = UDim2.fromOffset(250, 35)
		modulebutton.BackgroundColor3 = Color3.new()
		modulebutton.BackgroundTransparency = 0.25
		modulebutton.BorderSizePixel = 0
		modulebutton.AutoButtonColor = false
		modulebutton.Text = modulesettings.Name
		modulebutton.TextColor3 = color.Dark(uipallet.Text, 0.2)
		modulebutton.TextSize = 14
		modulebutton.FontFace = uipallet.FontSemiBold
		modulebutton.Parent = children
		local expandicon = Instance.new('ImageButton')
		expandicon.Size = UDim2.fromOffset(6, 10)
		expandicon.Position = UDim2.new(1, -20, 0.5, 0)
		expandicon.AnchorPoint = Vector2.new(0.5, 0.5)
		expandicon.BackgroundTransparency = 1
		expandicon.Image = getcustomasset('catsix/assets/liquidbounce/expand.png')
		expandicon.ImageTransparency = 0.5
		expandicon.Parent = modulebutton
		local modulechildren = Instance.new('Frame')
		modulechildren.Name = modulesettings.Name..'Children'
		modulechildren.Size = UDim2.new(1, 0, 0, 0)
		modulechildren.BackgroundColor3 = Color3.new()
		modulechildren.BackgroundTransparency = 0.1
		modulechildren.BorderSizePixel = 0
		modulechildren.Visible = false
		modulechildren.Parent = children
		moduleapi.Children = modulechildren
		local windowlist = Instance.new('UIListLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		windowlist.Parent = modulechildren
		modulesettings.Function = modulesettings.Function or function() end
		addMaid(moduleapi)

		function moduleapi:Toggle(multiple)
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			self.Enabled = not self.Enabled
			tween:Tween(modulebutton, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {
				TextColor3 = self.Enabled and uipallet.Main or (hovered and uipallet.Text or color.Dark(uipallet.Text, 0.2))
			}, tween.tweenstwo)
			if not self.Enabled then
				for _, v in self.Connections do
					v:Disconnect()
				end
				table.clear(self.Connections)
			end
			if not multiple then
				mainapi:UpdateTextGUI()
			end
			task.spawn(modulesettings.Function, self.Enabled)
		end

		for i, v in components do
			moduleapi['Create'..i] = function(_, optionsettings)
				return v(optionsettings, modulechildren, moduleapi)
			end
		end

		moduleapi:CreateBind()
		modulebutton.MouseEnter:Connect(function()
			hovered = true
			tween:Tween(modulebutton, createTween(0.2), {
				BackgroundTransparency = 0.15
			})

			if not moduleapi.Enabled then
				tween:Tween(modulebutton, createTween(0.2), {
					TextColor3 = uipallet.Text
				}, tween.tweenstwo)
			end
		end)
		modulebutton.MouseLeave:Connect(function()
			hovered = false
			tween:Tween(modulebutton, createTween(0.2), {
				BackgroundTransparency = 0.25
			})

			if not moduleapi.Enabled then
				tween:Tween(modulebutton, createTween(0.2), {
					TextColor3 = color.Dark(uipallet.Text, 0.2)
				}, tween.tweenstwo)
			end
		end)
		modulebutton.MouseButton1Click:Connect(function()
			moduleapi:Toggle()
		end)
		modulebutton.MouseButton2Click:Connect(function()
			modulechildren.Visible = not modulechildren.Visible
			tween:Tween(expandicon, createTween(0.2), {
				ImageTransparency = modulechildren.Visible and 0 or 0.5
			})
			tween:Tween(expandicon, createTween(0.4), {
				Rotation = modulechildren.Visible and 90 or 0
			}, tween.tweenstwo)
		end)
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			modulechildren.Size = UDim2.new(1, 0, 0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		end)

		moduleapi.Object = modulebutton
		mainapi.Modules[modulesettings.Name] = moduleapi

		local sorting = {}
		for _, v in mainapi.Modules do
			sorting[v.Category] = sorting[v.Category] or {}
			table.insert(sorting[v.Category], v.Name)
		end

		for _, sort in sorting do
			table.sort(sort)
			for i, v in sort do
				mainapi.Modules[v].Index = i
				mainapi.Modules[v].Object.LayoutOrder = i
				mainapi.Modules[v].Children.LayoutOrder = i
			end
		end

		return moduleapi
	end

	function categoryapi:Expand()
		self.Expanded = not self.Expanded
		tween:Tween(expandbar1, createTween(0.4, 'Out'), {
			Rotation = self.Expanded and 90 or 0
		})
		tween:Tween(expandbar2, createTween(0.4, 'Out'), {
			Rotation = self.Expanded and 270 or 90
		})
		tween:Tween(window, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(250, self.Expanded and math.min(39 + windowlist.AbsoluteContentSize.Y / scale.Scale, 583) or 39)
		})
	end

	window.InputBegan:Connect(function(inputObj)
		if inputObj.Position.Y < window.AbsolutePosition.Y + 39 and inputObj.UserInputType == Enum.UserInputType.MouseButton2 then
			categoryapi:Expand()
		end
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		if categoryapi.Expanded then
			tween:Tween(window, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(250, math.min(39 + windowlist.AbsoluteContentSize.Y / scale.Scale, 583))
			})
		end
	end)

	categoryapi.Object = window
	self.Categories[categorysettings.Name] = categoryapi

	return categoryapi
end

function mainapi:CreateNotification(title, text, duration, type)

end

function mainapi:Load(skipgui, profile)

end

function mainapi:LoadOptions(object, savedoptions)

end

function mainapi:Remove(obj)
	local tab = (self.Modules[obj] and self.Modules or self.Legit.Modules[obj] and self.Legit.Modules or self.Categories)
	if tab and tab[obj] then
		local newobj = tab[obj]
		if self.ThreadFix then
			setthreadidentity(8)
		end

		for _, v in {'Object', 'Children', 'Toggle', 'Button'} do
			local childobj = typeof(newobj[v]) == 'table' and newobj[v].Object or newobj[v]
			if typeof(childobj) == 'Instance' then
				childobj:Destroy()
				childobj:ClearAllChildren()
			end
		end

		loopClean(newobj)
		tab[obj] = nil
	end
end

function mainapi:Save(newprofile)

end

function mainapi:SaveOptions(object, savedoptions)

end

function mainapi:Uninject()

end

function mainapi:UpdateGUI()

end

function mainapi:UpdateTextGUI()

end

gui = Instance.new('ScreenGui')
gui.Name = randomString()
gui.DisplayOrder = 9999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.OnTopOfCoreBlur = true
if mainapi.ThreadFix then
	gui.Parent = cloneref(game:GetService('CoreGui'))--(gethui and gethui()) or cloneref(game:GetService('CoreGui'))
else
	gui.Parent = cloneref(game:GetService('Players')).LocalPlayer.PlayerGui
	gui.ResetOnSpawn = false
end
mainapi.gui = gui
scaledgui = Instance.new('Frame')
scaledgui.Name = 'ScaledGui'
scaledgui.Size = UDim2.fromScale(1, 1)
scaledgui.BackgroundTransparency = 1
scaledgui.Parent = gui
clickgui = Instance.new('Frame')
clickgui.Name = 'ClickGui'
clickgui.Size = UDim2.fromScale(1, 1)
clickgui.BackgroundTransparency = 0.4
clickgui.BackgroundColor3 = Color3.new()
clickgui.BorderSizePixel = 0
clickgui.Visible = false
clickgui.Parent = scaledgui
local modal = Instance.new('TextButton')
modal.BackgroundTransparency = 1
modal.Modal = true
modal.Text = ''
modal.Parent = clickgui
local cursor = Instance.new('ImageLabel')
cursor.Size = UDim2.fromOffset(64, 64)
cursor.BackgroundTransparency = 1
cursor.Visible = false
cursor.Image = 'rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png'
cursor.Parent = gui
notifications = Instance.new('Folder')
notifications.Name = 'Notifications'
notifications.Parent = scaledgui
scale = Instance.new('UIScale')
scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 1)
scale.Parent = scaledgui
mainapi.guiscale = scale
scaledgui.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)

mainapi:Clean(gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
	if mainapi.Scale.Enabled then
		scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 1)
	end
end))

mainapi:Clean(scale:GetPropertyChangedSignal('Scale'):Connect(function()
	scaledgui.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
	for _, v in scaledgui:GetDescendants() do
		if v:IsA('GuiObject') and v.Visible then
			v.Visible = false
			v.Visible = true
		end
	end
end))

mainapi:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
	mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value, true)
	if clickgui.Visible and inputService.MouseEnabled then
		repeat
			local visibleCheck = clickgui.Visible
			for _, v in mainapi.Windows do
				visibleCheck = visibleCheck or v.Visible
			end
			if not visibleCheck then break end

			cursor.Visible = not inputService.MouseIconEnabled
			if cursor.Visible then
				local mouseLocation = inputService:GetMouseLocation()
				cursor.Position = UDim2.fromOffset(mouseLocation.X - 31, mouseLocation.Y - 32)
			end

			task.wait()
		until mainapi.Loaded == nil
		cursor.Visible = false
	end
end))

mainapi:CreateCategory({
	Name = 'Combat',
	Icon = getcustomasset('catsix/assets/liquidbounce/combat.png'),
	Size = UDim2.fromOffset(16, 15)
})
mainapi:CreateCategory({
	Name = 'Blatant',
	Icon = getcustomasset('catsix/assets/liquidbounce/blatant.png'),
	Size = UDim2.fromOffset(15, 15)
})
mainapi:CreateCategory({
	Name = 'Render',
	Icon = getcustomasset('catsix/assets/liquidbounce/render.png'),
	Size = UDim2.fromOffset(15, 9)
})
mainapi:CreateCategory({
	Name = 'Utility',
	Icon = getcustomasset('catsix/assets/liquidbounce/utility.png'),
	Size = UDim2.fromOffset(15, 15)
})
mainapi:CreateCategory({
	Name = 'World',
	Icon = getcustomasset('catsix/assets/liquidbounce/world.png'),
	Size = UDim2.fromOffset(15, 15)
})
mainapi:CreateCategory({
	Name = 'Inventory',
	Icon = getcustomasset('catsix/assets/liquidbounce/inventory.png'),
	Size = UDim2.fromOffset(14, 15)
})
mainapi:CreateCategory({
	Name = 'Minigames',
	Icon = getcustomasset('catsix/assets/liquidbounce/minigames.png'),
	Size = UDim2.fromOffset(15, 15)
})

mainapi:Clean(inputService.InputBegan:Connect(function(inputObj)
	if not inputService:GetFocusedTextBox() and inputObj.KeyCode ~= Enum.KeyCode.Unknown then
		table.insert(mainapi.HeldKeybinds, inputObj.KeyCode.Name)
		if mainapi.Binding then return end

		if checkKeybinds(mainapi.HeldKeybinds, mainapi.Keybind, inputObj.KeyCode.Name) then
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			for _, v in mainapi.Windows do
				v.Visible = false
			end
			clickgui.Visible = not clickgui.Visible
			--tooltip.Visible = false
			mainapi:BlurCheck()
		end

		local toggled = false
		for i, v in mainapi.Modules do
			if checkKeybinds(mainapi.HeldKeybinds, v.Bind, inputObj.KeyCode.Name) then
				toggled = true
				if mainapi.ToggleNotifications.Enabled then
					mainapi:CreateNotification('Module Toggled', i.."<font color='#FFFFFF'> has been </font>"..(not v.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>").."<font color='#FFFFFF'>!</font>", 0.75)
				end
				v:Toggle(true)
			end
		end
		if toggled then
			mainapi:UpdateTextGUI()
		end

		for _, v in mainapi.Profiles do
			if checkKeybinds(mainapi.HeldKeybinds, v.Bind, inputObj.KeyCode.Name) and v.Name ~= mainapi.Profile then
				mainapi:Save(v.Name)
				mainapi:Load(true)
				break
			end
		end
	end
end))

mainapi:Clean(inputService.InputEnded:Connect(function(inputObj)
	if not inputService:GetFocusedTextBox() and inputObj.KeyCode ~= Enum.KeyCode.Unknown then
		if mainapi.Binding then
			if not mainapi.MultiKeybind.Enabled then
				mainapi.HeldKeybinds = {inputObj.KeyCode.Name}
			end
			mainapi.Binding:SetBind(checkKeybinds(mainapi.HeldKeybinds, mainapi.Binding.Bind, inputObj.KeyCode.Name) and {} or mainapi.HeldKeybinds, true)
			mainapi.Binding = nil
		end
	end

	local ind = table.find(mainapi.HeldKeybinds, inputObj.KeyCode.Name)
	if ind then
		table.remove(mainapi.HeldKeybinds, ind)
	end
end))

return mainapi