local license = ...
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
	Libraries = {},
	Modules = {},
	Place = game.PlaceId,
	Profile = 'default',
	Profiles = {},
	RainbowSpeed = {Value = 1},
	RainbowUpdateSpeed = {Value = 60},
	RainbowTable = {},
	SaveCache = {},
	Scale = {Value = 1},
	ThreadFix = setthreadidentity and true or false,
	ToggleNotifications = {},
	Version = '6',
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
local toolblur
local tooltip
local scale
local gui

local color = {}
local tween = {
	tweens = {},
	tweenstwo = {}
}
local uipallet = {
	Main = Color3.fromRGB(26, 25, 26),
	Text = Color3.fromRGB(200, 200, 200),
	Font = Font.fromEnum(Enum.Font.Arial),
	FontSemiBold = Font.fromEnum(Enum.Font.Arial, Enum.FontWeight.SemiBold),
	Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}

local getcustomassets = {
	['catsix/assets/new/add.png'] = 'rbxassetid://14368300605',
	['catsix/assets/new/alert.png'] = 'rbxassetid://14368301329',
	['catsix/assets/new/allowedicon.png'] = 'rbxassetid://14368302000',
	['catsix/assets/new/allowedtab.png'] = 'rbxassetid://14368302875',
	['catsix/assets/new/arrowmodule.png'] = 'rbxassetid://14473354880',
	['catsix/assets/new/back.png'] = 'rbxassetid://14368303894',
	['catsix/assets/new/bind.png'] = 'rbxassetid://14368304734',
	['catsix/assets/new/bindbkg.png'] = 'rbxassetid://14368305655',
	['catsix/assets/new/blatanticon.png'] = 'rbxassetid://14368306745',
	['catsix/assets/new/blockedicon.png'] = 'rbxassetid://14385669108',
	['catsix/assets/new/blockedtab.png'] = 'rbxassetid://14385672881',
	['catsix/assets/new/blur.png'] = 'rbxassetid://14898786664',
	['catsix/assets/new/blurnotif.png'] = 'rbxassetid://16738720137',
	['catsix/assets/new/close.png'] = 'rbxassetid://14368309446',
	['catsix/assets/new/closemini.png'] = 'rbxassetid://14368310467',
	['catsix/assets/new/colorpreview.png'] = 'rbxassetid://14368311578',
	['catsix/assets/new/combaticon.png'] = 'rbxassetid://14368312652',
	['catsix/assets/new/customsettings.png'] = 'rbxassetid://14403726449',
	['catsix/assets/new/discord.png'] = '',
	['catsix/assets/new/dots.png'] = 'rbxassetid://14368314459',
	['catsix/assets/new/edit.png'] = 'rbxassetid://14368315443',
	['catsix/assets/new/expandicon.png'] = 'rbxassetid://14368353032',
	['catsix/assets/new/expandright.png'] = 'rbxassetid://14368316544',
	['catsix/assets/new/expandup.png'] = 'rbxassetid://14368317595',
	['catsix/assets/new/friendstab.png'] = 'rbxassetid://14397462778',
	['catsix/assets/new/guisettings.png'] = 'rbxassetid://14368318994',
	['catsix/assets/new/guislider.png'] = 'rbxassetid://14368320020',
	['catsix/assets/new/guisliderrain.png'] = 'rbxassetid://14368321228',
	['catsix/assets/new/guiv4.png'] = 'rbxassetid://14368322199',
	['catsix/assets/new/guivape.png'] = 'rbxassetid://14657521312',
	['catsix/assets/new/info.png'] = 'rbxassetid://14368324807',
	['catsix/assets/new/inventoryicon.png'] = 'rbxassetid://14928011633',
	['catsix/assets/new/legit.png'] = 'rbxassetid://14425650534',
	['catsix/assets/new/legittab.png'] = 'rbxassetid://14426740825',
	['catsix/assets/new/miniicon.png'] = 'rbxassetid://14368326029',
	['catsix/assets/new/notification.png'] = 'rbxassetid://16738721069',
	['catsix/assets/new/overlaysicon.png'] = 'rbxassetid://14368339581',
	['catsix/assets/new/overlaystab.png'] = 'rbxassetid://14397380433',
	['catsix/assets/new/pin.png'] = 'rbxassetid://14368342301',
	['catsix/assets/new/profilesicon.png'] = 'rbxassetid://14397465323',
	['catsix/assets/new/radaricon.png'] = 'rbxassetid://14368343291',
	['catsix/assets/new/rainbow_1.png'] = 'rbxassetid://14368344374',
	['catsix/assets/new/rainbow_2.png'] = 'rbxassetid://14368345149',
	['catsix/assets/new/rainbow_3.png'] = 'rbxassetid://14368345840',
	['catsix/assets/new/rainbow_4.png'] = 'rbxassetid://14368346696',
	['catsix/assets/new/range.png'] = 'rbxassetid://14368347435',
	['catsix/assets/new/rangearrow.png'] = 'rbxassetid://14368348640',
	['catsix/assets/new/rendericon.png'] = 'rbxassetid://14368350193',
	['catsix/assets/new/rendertab.png'] = 'rbxassetid://14397373458',
	['catsix/assets/new/search.png'] = 'rbxassetid://14425646684',
	['catsix/assets/new/targetinfoicon.png'] = 'rbxassetid://14368354234',
	['catsix/assets/new/targetnpc1.png'] = 'rbxassetid://14497400332',
	['catsix/assets/new/targetnpc2.png'] = 'rbxassetid://14497402744',
	['catsix/assets/new/targetplayers1.png'] = 'rbxassetid://14497396015',
	['catsix/assets/new/targetplayers2.png'] = 'rbxassetid://14497397862',
	['catsix/assets/new/targetstab.png'] = 'rbxassetid://14497393895',
	['catsix/assets/new/textguiicon.png'] = 'rbxassetid://14368355456',
	['catsix/assets/new/textv4.png'] = 'rbxassetid://14368357095',
	['catsix/assets/new/textvape.png'] = 'rbxassetid://14368358200',
	['catsix/assets/new/utilityicon.png'] = 'rbxassetid://14368359107',
	['catsix/assets/new/vape.png'] = 'rbxassetid://14373395239',
	['catsix/assets/new/warning.png'] = 'rbxassetid://14368361552',
	['catsix/assets/new/worldicon.png'] = 'rbxassetid://14368362492'
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

local function addBlur(parent, notif)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('catsix/assets/new/'..(notif and 'blurnotif' or 'blur')..'.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent

	return blur
end

local function addCorner(parent, radius)
	local corner = Instance.new('UICorner')
	corner.CornerRadius = radius or UDim.new(0, 5)
	corner.Parent = parent

	return corner
end

local function addCloseButton(parent, offset)
	local close = Instance.new('ImageButton')
	close.Name = 'Close'
	close.Size = UDim2.fromOffset(24, 24)
	close.Position = UDim2.new(1, -35, 0, offset or 9)
	close.BackgroundColor3 = Color3.new(1, 1, 1)
	close.BackgroundTransparency = 1
	close.AutoButtonColor = false
	close.Image = getcustomasset('catsix/assets/new/close.png')
	close.ImageColor3 = color.Light(uipallet.Text, 0.2)
	close.ImageTransparency = 0.5
	close.Parent = parent
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

	return close
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

local function addTooltip(gui, text)
	if not text then return end

	local function tooltipMoved(x, y)
		local right = x + 16 + tooltip.Size.X.Offset > (scale.Scale * 1920)
		tooltip.Position = UDim2.fromOffset(
			(right and x - (tooltip.Size.X.Offset * scale.Scale) - 16 or x + 16) / scale.Scale,
			((y + 11) - (tooltip.Size.Y.Offset / 2)) / scale.Scale
		)
		tooltip.Visible = toolblur.Visible
	end

	gui.MouseEnter:Connect(function(x, y)
		local tooltipSize = getfontsize(text, tooltip.TextSize, uipallet.Font)
		tooltip.Size = UDim2.fromOffset(tooltipSize.X + 10, tooltipSize.Y + 10)
		tooltip.Text = text
		tooltipMoved(x, y)
	end)
	gui.MouseMoved:Connect(tooltipMoved)
	gui.MouseLeave:Connect(function()
		tooltip.Visible = false
	end)
end

local function checkKeybinds(compare, target, key)
	if type(target) == 'table' then
		if table.find(target, key) then
			for i, v in target do
				if not table.find(compare, v) then
					return false
				end
			end
			return true
		end
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
			downloader.FontFace = uipallet.Font
			downloader.Parent = mainapi.gui
			mainapi.Downloader = downloader
		end
		downloader.Text = 'Downloading '..text
	end
end

local function createMobileButton(buttonapi, position)
	local heldbutton = false
	local button = Instance.new('TextButton')
	button.Size = UDim2.fromOffset(40, 40)
	button.Position = UDim2.fromOffset(position.X, position.Y)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = buttonapi.Enabled and Color3.new(0, 0.7, 0) or Color3.new()
	button.BackgroundTransparency = 0.5
	button.Text = buttonapi.Name
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.Gotham
	button.Parent = mainapi.gui
	local buttonconstraint = Instance.new('UITextSizeConstraint')
	buttonconstraint.MaxTextSize = 16
	buttonconstraint.Parent = button
	addCorner(button, UDim.new(1, 0))

	button.MouseButton1Down:Connect(function()
		heldbutton = true
		local holdtime, holdpos = tick(), inputService:GetMouseLocation()
		repeat
			heldbutton = (inputService:GetMouseLocation() - holdpos).Magnitude < 6
			task.wait()
		until (tick() - holdtime) > 1 or not heldbutton
		if heldbutton then
			buttonapi.Bind = {}
			button:Destroy()
		end
	end)
	button.MouseButton1Up:Connect(function()
		heldbutton = false
	end)
	button.MouseButton1Click:Connect(function()
		buttonapi:Toggle()
		button.BackgroundColor3 = buttonapi.Enabled and Color3.new(0, 0.7, 0) or Color3.new()
	end)

	buttonapi.Bind = {Button = button}
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

local function loadFeatures()
	local suc, res = pcall(downloadFile, 'catsix/features.json')
	if not suc or type(res) ~= 'string' then return nil end

	local decoded, payload = pcall(function()
		return httpService:JSONDecode(res)
	end)
	return decoded and type(payload) == 'table' and payload or nil
end

local featureTags
local function getFeatureTag(name)
	if not featureTags then
		featureTags = {}
		local features = loadFeatures()
		for tag, key in {updated = 'updated', new = 'added'} do
			local list = features and features[key]
			if type(list) == 'table' then
				for _, module in list do
					if type(module) == 'string' then
						featureTags[module] = tag
					end
				end
			end
		end
	end
	return featureTags[name]
end

local function makeDraggable(gui, window)
	gui.InputBegan:Connect(function(inputObj)
		if window and not window.Visible then return end
		if
			(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
			and (inputObj.Position.Y - gui.AbsolutePosition.Y < 40 or window)
		then
			local dragPosition = Vector2.new(
				gui.AbsolutePosition.X - inputObj.Position.X,
				gui.AbsolutePosition.Y - inputObj.Position.Y + guiService:GetGuiInset().Y
			) / scale.Scale

			local changed = inputService.InputChanged:Connect(function(input)
				if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
					local position = input.Position
					if inputService:IsKeyDown(Enum.KeyCode.LeftShift) then
						dragPosition = (dragPosition // 3) * 3
						position = (position // 3) * 3
					end
					gui.Position = UDim2.fromOffset((position.X / scale.Scale) + dragPosition.X, (position.Y / scale.Scale) + dragPosition.Y)
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
end

local function randomString()
	local array = {}
	for i = 1, math.random(10, 100) do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return str:gsub('<[^<>]->', '')
end

do
	local res = isfile('catsix/profiles/color.txt') and loadJson('catsix/profiles/color.txt')
	if res then
		uipallet.Main = res.Main and Color3.fromRGB(unpack(res.Main)) or uipallet.Main
		uipallet.Text = res.Text and Color3.fromRGB(unpack(res.Text)) or uipallet.Text
		uipallet.Font = res.Font and Font.new(
			res.Font:find('rbxasset') and res.Font
			or string.format('rbxasset://fonts/families/%s.json', res.Font)
		) or uipallet.Font
		uipallet.FontSemiBold = Font.new(uipallet.Font.Family, Enum.FontWeight.SemiBold)
	end
	fontsize.Font = uipallet.Font
end

do
	function color.Dark(col, num)
		local h, s, v = col:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(select(3, uipallet.Main:ToHSV()) > 0.5 and v + num or v - num, 0, 1))
	end

	function color.Light(col, num)
		local h, s, v = col:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(select(3, uipallet.Main:ToHSV()) > 0.5 and v - num or v + num, 0, 1))
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
	addBlur = addBlur,
	addCloseButton = addCloseButton,
	addCorner = addCorner,
	color = color,
	getcustomasset = getcustomasset,
	getfontsize = getfontsize,
	makeDraggable = makeDraggable,
	tween = tween,
	uipallet = uipallet,
}

local components
components = {
	Button = function(optionsettings, children, api)
		local button = Instance.new('TextButton')
		button.Name = optionsettings.Name..'Button'
		button.Size = UDim2.new(1, 0, 0, 31)
		button.LayoutOrder = optionsettings.LayoutOrder or 0
		button.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Visible = optionsettings.Visible == nil or optionsettings.Visible
		button.Text = ''
		button.BackgroundTransparency = 1
		button.Parent = children
		addTooltip(button, optionsettings.Tooltip)
		local bkg = Instance.new('Frame')
		bkg.Size = UDim2.fromOffset(200, 27)
		bkg.Position = UDim2.fromOffset(10, 2)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
		bkg.Parent = button
		addCorner(bkg)
		local label = Instance.new('TextLabel')
		label.Size = UDim2.new(1, -4, 1, -4)
		label.Position = UDim2.fromOffset(2, 2)
		label.BackgroundColor3 = uipallet.Main
		label.Text = optionsettings.Name
		label.TextColor3 = color.Dark(uipallet.Text, 0.16)
		label.TextSize = 14
		label.FontFace = uipallet.Font
		label.Parent = bkg
		addCorner(label, UDim.new(0, 4))
		optionsettings.Function = optionsettings.Function or function() end
		
		button.MouseEnter:Connect(function()
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.0875)
			})
		end)
		button.MouseLeave:Connect(function()
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.05)
			})
		end)
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
		addTooltip(slider, optionsettings.Tooltip)
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
		expandbutton.Position = UDim2.new(0, textService:GetTextSize(title.Text, title.TextSize, title.Font, Vector2.new(1000, 1000)).X + 11, 0, 7)
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
			Default = optionsettings.Default or optionsettings.List[1] or 'None',
			List = optionsettings.List,
			Index = 0
		}
		
		local dropdown = Instance.new('TextButton')
		dropdown.Name = optionsettings.Name..'Dropdown'
		dropdown.Size = UDim2.new(1, 0, 0, 40)
		dropdown.LayoutOrder = optionsettings.LayoutOrder or 0
		dropdown.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		dropdown.BorderSizePixel = 0
		dropdown.AutoButtonColor = false
		dropdown.Visible = optionsettings.Visible == nil or optionsettings.Visible
		dropdown.Text = ''
		dropdown.Parent = children
		addTooltip(dropdown, optionsettings.Tooltip or optionsettings.Name)
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -20, 1, -9)
		bkg.Position = UDim2.fromOffset(10, 4)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.Parent = dropdown
		addCorner(bkg, UDim.new(0, 6))
		local button = Instance.new('TextButton')
		button.Name = 'Dropdown'
		button.Size = UDim2.new(1, -2, 1, -2)
		button.Position = UDim2.fromOffset(1, 1)
		button.BackgroundColor3 = uipallet.Main
		button.AutoButtonColor = false
		button.Text = ''
		button.Parent = bkg
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, 0, 0, 29)
		title.BackgroundTransparency = 1
		title.Text = '         '..optionsettings.Name..' - '..optionapi.Value
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.16)
		title.TextSize = 13
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.FontFace = uipallet.Font
		title.Parent = button
		addCorner(button, UDim.new(0, 6))
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(4, 8)
		arrow.Position = UDim2.new(1, -17, 0, 11)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('catsix/assets/new/expandright.png')
		arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
		arrow.Rotation = 90
		arrow.Parent = button
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
			self.List = optionsettings.List
			if not table.find(optionsettings.List, self.Value) then
				self:SetValue(self.Value)
			end
		end
		
		function optionapi:SetValue(val, mouse)
			self.Value = table.find(optionsettings.List, val) and val or optionsettings.List[1] or 'None'
			title.Text = '         '..optionsettings.Name..' - '..self.Value
			if dropdownchildren then
				arrow.Rotation = 90
				dropdownchildren:Destroy()
				dropdownchildren = nil
				dropdown.Size = UDim2.new(1, 0, 0, 40)
			end
			optionsettings.Function(self.Value, mouse)
		end
		
		button.MouseButton1Click:Connect(function()
			if not dropdownchildren then
				arrow.Rotation = 270
				dropdown.Size = UDim2.new(1, 0, 0, 40 + (#optionsettings.List - 1) * 26)
				dropdownchildren = Instance.new('Frame')
				dropdownchildren.Name = 'Children'
				dropdownchildren.Size = UDim2.new(1, 0, 0, (#optionsettings.List - 1) * 26)
				dropdownchildren.Position = UDim2.fromOffset(0, 27)
				dropdownchildren.BackgroundTransparency = 1
				dropdownchildren.Parent = button
				local ind = 0
				for _, v in optionsettings.List do
					if v == optionapi.Value then continue end
					local dropdownoption = Instance.new('TextButton')
					dropdownoption.Name = v..'Option'
					dropdownoption.Size = UDim2.new(1, 0, 0, 26)
					dropdownoption.Position = UDim2.fromOffset(0, ind * 26)
					dropdownoption.BackgroundColor3 = uipallet.Main
					dropdownoption.BorderSizePixel = 0
					dropdownoption.AutoButtonColor = false
					dropdownoption.Text = '         '..v
					dropdownoption.TextXAlignment = Enum.TextXAlignment.Left
					dropdownoption.TextColor3 = color.Dark(uipallet.Text, 0.16)
					dropdownoption.TextSize = 13
					dropdownoption.TextTruncate = Enum.TextTruncate.AtEnd
					dropdownoption.FontFace = uipallet.Font
					dropdownoption.Parent = dropdownchildren
					dropdownoption.MouseEnter:Connect(function()
						tween:Tween(dropdownoption, uipallet.Tween, {
							BackgroundColor3 = color.Light(uipallet.Main, 0.02)
						})
					end)
					dropdownoption.MouseLeave:Connect(function()
						tween:Tween(dropdownoption, uipallet.Tween, {
							BackgroundColor3 = uipallet.Main
						})
					end)
					dropdownoption.MouseButton1Click:Connect(function()
						optionapi:SetValue(v, true)
					end)
					ind += 1
				end
			else
				optionapi:SetValue(optionapi.Value, true)
			end
		end)
		dropdown.MouseEnter:Connect(function()
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.0875)
			})
		end)
		dropdown.MouseLeave:Connect(function()
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.034)
			})
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
			if fontbox.Object then
				fontbox.Object.Visible = fontdropdown.Object.Visible and fontdropdown.Value == 'Custom'
			end
		end)
		
		return optionapi
	end,
	Slider = function(optionsettings, children, api)
		local optionapi = {
			Type = 'Slider',
			Value = optionsettings.Default or optionsettings.Min,
			Default = optionsettings.Default or optionsettings.Min,
			Min = optionsettings.Min,
			Max = optionsettings.Max,
			Decimal = optionsettings.Decimal or 1,
			Suffix = optionsettings.Suffix,
			Index = getTableSize(api.Options)
		}
		
		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.new(1, 0, 0, 50)
		slider.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		slider.BorderSizePixel = 0
		slider.AutoButtonColor = false
		slider.Visible = optionsettings.Visible == nil or optionsettings.Visible
		slider.Text = ''
		slider.Parent = children
		addTooltip(slider, optionsettings.Tooltip)
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
		local valuebutton = Instance.new('TextButton')
		valuebutton.Name = 'Value'
		valuebutton.Size = UDim2.fromOffset(60, 15)
		valuebutton.Position = UDim2.new(1, -69, 0, 9)
		valuebutton.BackgroundTransparency = 1
		valuebutton.Text = optionapi.Value..(optionsettings.Suffix and ' '..(type(optionsettings.Suffix) == 'function' and optionsettings.Suffix(optionapi.Value) or optionsettings.Suffix) or '')
		valuebutton.TextXAlignment = Enum.TextXAlignment.Right
		valuebutton.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebutton.TextSize = 11
		valuebutton.FontFace = uipallet.Font
		valuebutton.Parent = slider
		local valuebox = Instance.new('TextBox')
		valuebox.Name = 'Box'
		valuebox.Size = valuebutton.Size
		valuebox.Position = valuebutton.Position
		valuebox.BackgroundTransparency = 1
		valuebox.Visible = false
		valuebox.Text = optionapi.Value
		valuebox.TextXAlignment = Enum.TextXAlignment.Right
		valuebox.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebox.TextSize = 11
		valuebox.FontFace = uipallet.Font
		valuebox.ClearTextOnFocus = false
		valuebox.Parent = slider
		local bkg = Instance.new('Frame')
		bkg.Name = 'Slider'
		bkg.Size = UDim2.new(1, -20, 0, 2)
		bkg.Position = UDim2.fromOffset(10, 37)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.BorderSizePixel = 0
		bkg.Parent = slider
		local fill = bkg:Clone()
		fill.Name = 'Fill'
		fill.Size = UDim2.fromScale(math.clamp((optionapi.Value - optionsettings.Min) / optionsettings.Max, 0.04, 0.96), 1)
		fill.Position = UDim2.new()
		fill.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
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
		knob.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
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
		
		function optionapi:Color(hue, sat, val, rainbowcheck)
			fill.BackgroundColor3 = rainbowcheck and Color3.fromHSV(mainapi:Color((hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
			knob.BackgroundColor3 = fill.BackgroundColor3
		end
		
		function optionapi:SetValue(value, pos, final)
			if tonumber(value) == math.huge or value ~= value then return end
			local check = self.Value ~= value
			self.Value = value
			tween:Tween(fill, uipallet.Tween, {
				Size = UDim2.fromScale(math.clamp(pos or math.clamp(value / optionsettings.Max, 0, 1), 0.04, 0.96), 1)
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
			Default = {
				Players = optionsettings.Players and true or false,
				NPCs = optionsettings.NPCs and true or false,
				Invisible = optionsettings.Invisible and true or false,
				Walls = optionsettings.Walls and true or false
			},
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
		addTooltip(textlist, optionsettings.Tooltip)
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
		local close = addCloseButton(window)
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
		
		close.MouseButton1Click:Connect(function()
			window.Visible = false
		end)
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
		addTooltip(targetbutton, optionsettings.Tooltip)
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
		textbox.Size = UDim2.new(1, 0, 0, 58)
		textbox.LayoutOrder = optionsettings.LayoutOrder or 0
		textbox.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		textbox.BorderSizePixel = 0
		textbox.AutoButtonColor = false
		textbox.Visible = optionsettings.Visible == nil or optionsettings.Visible
		textbox.Text = ''
		textbox.Parent = children
		addTooltip(textbox, optionsettings.Tooltip)
		local title = Instance.new('TextLabel')
		title.Size = UDim2.new(1, -10, 0, 20)
		title.Position = UDim2.fromOffset(10, 3)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 12
		title.FontFace = uipallet.Font
		title.Parent = textbox
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -20, 0, 29)
		bkg.Position = UDim2.fromOffset(10, 23)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		bkg.Parent = textbox
		addCorner(bkg, UDim.new(0, 4))
		local box = Instance.new('TextBox')
		box.Size = UDim2.new(1, -8, 1, 0)
		box.Position = UDim2.fromOffset(8, 0)
		box.BackgroundTransparency = 1
		box.Text = optionsettings.Default or ''
		box.PlaceholderText = optionsettings.Placeholder or 'Click to set'
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextColor3 = color.Dark(uipallet.Text, 0.16)
		box.PlaceholderColor3 = color.Dark(uipallet.Text, 0.31)
		box.TextSize = 12
		box.FontFace = uipallet.Font
		box.ClearTextOnFocus = false
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
			Default = table.clone(optionsettings.Default or {}),
			Icon = optionsettings.Icon,
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
		addTooltip(textlist, optionsettings.Tooltip)
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
		local close = addCloseButton(window)
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
		close.MouseButton1Click:Connect(function()
			window.Visible = false
		end)
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
			Default = optionsettings.Default and true or false,
			Index = getTableSize(api.Options)
		}
		
		local hovered = false
		local toggle = Instance.new('TextButton')
		toggle.Name = optionsettings.Name..'Toggle'
		toggle.Size = UDim2.new(1, 0, 0, 30)
		toggle.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		toggle.BorderSizePixel = 0
		toggle.AutoButtonColor = false
		toggle.Visible = optionsettings.Visible == nil or optionsettings.Visible
		toggle.Text = '          '..optionsettings.Name
		toggle.TextXAlignment = Enum.TextXAlignment.Left
		toggle.TextColor3 = color.Dark(uipallet.Text, 0.16)
		toggle.TextSize = 14
		toggle.FontFace = uipallet.Font
		toggle.Parent = children
		addTooltip(toggle, optionsettings.Tooltip)
		local knobholder = Instance.new('Frame')
		knobholder.Name = 'Knob'
		knobholder.Size = UDim2.fromOffset(22, 12)
		knobholder.Position = UDim2.new(1, -30, 0, 9)
		knobholder.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
		knobholder.Parent = toggle
		addCorner(knobholder, UDim.new(1, 0))
		local knob = knobholder:Clone()
		knob.Size = UDim2.fromOffset(8, 8)
		knob.Position = UDim2.fromOffset(2, 2)
		knob.BackgroundColor3 = uipallet.Main
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
		
		function optionapi:Color(hue, sat, val, rainbowcheck)
			if self.Enabled then
				tween:Cancel(knobholder)
				knobholder.BackgroundColor3 = rainbowcheck and Color3.fromHSV(mainapi:Color((hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
			end
		end
		
		function optionapi:Toggle()
			self.Enabled = not self.Enabled
			local rainbowcheck = mainapi.GUIColor.Rainbow and mainapi.RainbowMode.Value ~= 'Retro'
			tween:Tween(knobholder, uipallet.Tween, {
				BackgroundColor3 = self.Enabled and (rainbowcheck and Color3.fromHSV(mainapi:Color((mainapi.GUIColor.Hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)) or (hovered and color.Light(uipallet.Main, 0.37) or color.Light(uipallet.Main, 0.14))
			})
			tween:Tween(knob, uipallet.Tween, {
				Position = UDim2.fromOffset(self.Enabled and 12 or 2, 2)
			})
			optionsettings.Function(self.Enabled)
		end
		
		toggle.MouseEnter:Connect(function()
			hovered = true
			if not optionapi.Enabled then
				tween:Tween(knobholder, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.37)
				})
			end
		end)
		toggle.MouseLeave:Connect(function()
			hovered = false
			if not optionapi.Enabled then
				tween:Tween(knobholder, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.14)
				})
			end
		end)
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
			DefaultMin = optionsettings.DefaultMin or optionsettings.Min,
			DefaultMax = optionsettings.DefaultMax or 10,
			Min = optionsettings.Min,
			Max = optionsettings.Max,
			Decimal = optionsettings.Decimal or 1,
			Index = getTableSize(api.Options)
		}
		
		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.new(1, 0, 0, 50)
		slider.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		slider.BorderSizePixel = 0
		slider.AutoButtonColor = false
		slider.Visible = optionsettings.Visible == nil or optionsettings.Visible
		slider.Text = ''
		slider.Parent = children
		addTooltip(slider, optionsettings.Tooltip)
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
		local valuebutton = Instance.new('TextButton')
		valuebutton.Name = 'Value'
		valuebutton.Size = UDim2.fromOffset(60, 15)
		valuebutton.Position = UDim2.new(1, -69, 0, 9)
		valuebutton.BackgroundTransparency = 1
		valuebutton.Text = optionapi.ValueMax
		valuebutton.TextXAlignment = Enum.TextXAlignment.Right
		valuebutton.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebutton.TextSize = 11
		valuebutton.FontFace = uipallet.Font
		valuebutton.Parent = slider
		local valuebutton2 = valuebutton:Clone()
		valuebutton2.Position = UDim2.new(1, -125, 0, 9)
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
		valuebox.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebox.TextSize = 11
		valuebox.FontFace = uipallet.Font
		valuebox.ClearTextOnFocus = false
		valuebox.Parent = slider
		local valuebox2 = valuebox:Clone()
		valuebox2.Position = valuebutton2.Position
		valuebox2.Parent = slider
		local bkg = Instance.new('Frame')
		bkg.Name = 'Slider'
		bkg.Size = UDim2.new(1, -20, 0, 2)
		bkg.Position = UDim2.fromOffset(10, 37)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.BorderSizePixel = 0
		bkg.Parent = slider
		local fill = bkg:Clone()
		fill.Name = 'Fill'
		fill.Position = UDim2.fromScale(math.clamp(optionapi.ValueMin / optionsettings.Max, 0.04, 0.96), 0)
		fill.Size = UDim2.fromScale(math.clamp(math.clamp(optionapi.ValueMax / optionsettings.Max, 0, 1), 0.04, 0.96) - fill.Position.X.Scale, 1)
		fill.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		fill.Parent = bkg
		local knobholder = Instance.new('Frame')
		knobholder.Name = 'Knob'
		knobholder.Size = UDim2.fromOffset(16, 4)
		knobholder.Position = UDim2.fromScale(0, 0.5)
		knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
		knobholder.BackgroundColor3 = slider.BackgroundColor3
		knobholder.BorderSizePixel = 0
		knobholder.Parent = fill
		local knob = Instance.new('ImageLabel')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(9, 16)
		knob.Position = UDim2.fromScale(0.5, 0.5)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundTransparency = 1
		knob.Image = getcustomasset('catsix/assets/new/range.png')
		knob.ImageColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		knob.Parent = knobholder
		local knobholdermax = knobholder:Clone()
		knobholdermax.Name = 'KnobMax'
		knobholdermax.Position = UDim2.fromScale(1, 0.5)
		knobholdermax.Parent = fill
		knobholdermax.Knob.Rotation = 180
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(12, 6)
		arrow.Position = UDim2.new(1, -56, 0, 10)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('catsix/assets/new/rangearrow.png')
		arrow.ImageColor3 = color.Light(uipallet.Main, 0.14)
		arrow.Parent = slider
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
			local size = math.clamp(math.clamp(self.ValueMin / optionsettings.Max, 0, 1), 0.04, 0.96)
			tween:Tween(fill, TweenInfo.new(0.1), {
				Position = UDim2.fromScale(size, 0),
				Size = UDim2.fromScale(math.clamp(math.clamp(math.clamp(self.ValueMax / optionsettings.Max, 0.04, 0.96), 0.04, 0.96) - size, 0, 1), 1)
			})
		end
		
		knobholder.MouseEnter:Connect(function()
			tween:Tween(knob, uipallet.Tween, {
				Size = UDim2.fromOffset(11, 18)
			})
		end)
		knobholder.MouseLeave:Connect(function()
			tween:Tween(knob, uipallet.Tween, {
				Size = UDim2.fromOffset(9, 16)
			})
		end)
		knobholdermax.MouseEnter:Connect(function()
			tween:Tween(knobholdermax.Knob, uipallet.Tween, {
				Size = UDim2.fromOffset(11, 18)
			})
		end)
		knobholdermax.MouseLeave:Connect(function()
			tween:Tween(knobholdermax.Knob, uipallet.Tween, {
				Size = UDim2.fromOffset(9, 16)
			})
		end)
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
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		divider.BorderSizePixel = 0
		divider.Parent = children
		if text then
			local label = Instance.new('TextLabel')
			label.Name = 'DividerLabel'
			label.Size = UDim2.fromOffset(218, 27)
			label.BackgroundTransparency = 1
			label.Text = '          '..text:upper()
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextColor3 = color.Dark(uipallet.Text, 0.43)
			label.TextSize = 9
			label.FontFace = uipallet.Font
			label.Parent = children
			divider.Position = UDim2.fromOffset(0, 26)
			divider.Parent = label
		end
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
	if self.ThreadFix and not inputService.TouchEnabled then
		setthreadidentity(8)
		runService:SetRobloxGuiFocused((clickgui.Visible or guiService:GetErrorType() ~= Enum.ConnectionError.OK) and self.Blur.Enabled)
	end
end

addMaid(mainapi)

function mainapi:CreateGUI()
	local categoryapi = {
		Type = 'MainWindow',
		Buttons = {},
		Options = {}
	}

	local window = Instance.new('TextButton')
	window.Name = 'GUICategory'
	window.Position = UDim2.fromOffset(6, 60)
	window.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	window.AutoButtonColor = false
	window.Text = ''
	window.Parent = clickgui
	addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local logo = Instance.new('ImageLabel')
	logo.Name = 'VapeLogo'
	logo.Size = UDim2.fromOffset(62, 18)
	logo.Position = UDim2.fromOffset(11, 10)
	logo.BackgroundTransparency = 1
	logo.Image = getcustomasset('catsix/assets/new/guivape.png')
	logo.ImageColor3 = select(3, uipallet.Main:ToHSV()) > 0.5 and uipallet.Text or Color3.new(1, 1, 1)
	logo.Parent = window
	local logov4 = Instance.new('ImageLabel')
	logov4.Name = 'V4Logo'
	logov4.Size = UDim2.fromOffset(28, 16)
	logov4.Position = UDim2.new(1, 1, 0, 1)
	logov4.BackgroundTransparency = 1
	logov4.Image = getcustomasset('catsix/assets/new/guiv4.png')
	logov4.Parent = logo
	local children = Instance.new('Frame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -33)
	children.Position = UDim2.fromOffset(0, 37)
	children.BackgroundTransparency = 1
	children.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children
	local settingsbutton = Instance.new('TextButton')
	settingsbutton.Name = 'Settings'
	settingsbutton.Size = UDim2.fromOffset(40, 40)
	settingsbutton.Position = UDim2.new(1, -40, 0, 0)
	settingsbutton.BackgroundTransparency = 1
	settingsbutton.Text = ''
	settingsbutton.Parent = window
	addTooltip(settingsbutton, 'Open settings')
	local settingsicon = Instance.new('ImageLabel')
	settingsicon.Size = UDim2.fromOffset(14, 14)
	settingsicon.Position = UDim2.fromOffset(15, 12)
	settingsicon.BackgroundTransparency = 1
	settingsicon.Image = getcustomasset('catsix/assets/new/guisettings.png')
	settingsicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
	settingsicon.Parent = settingsbutton
	local discordbutton = Instance.new('ImageButton')
	discordbutton.Size = UDim2.fromOffset(16, 16)
	discordbutton.Position = UDim2.new(1, -56, 0, 11)
	discordbutton.BackgroundTransparency = 1
	discordbutton.Image = getcustomasset('catsix/assets/new/discord.png')
	discordbutton.Parent = window
	addTooltip(discordbutton, 'Join discord')
	local settingspane = Instance.new('TextButton')
	settingspane.Size = UDim2.fromScale(1, 1)
	settingspane.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	settingspane.AutoButtonColor = false
	settingspane.Visible = false
	settingspane.Text = ''
	settingspane.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -36, 0, 20)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 11)
	title.BackgroundTransparency = 1
	title.Text = 'Settings'
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = settingspane
	local close = addCloseButton(settingspane)
	local back = Instance.new('ImageButton')
	back.Name = 'Back'
	back.Size = UDim2.fromOffset(16, 16)
	back.Position = UDim2.fromOffset(11, 13)
	back.BackgroundTransparency = 1
	back.Image = getcustomasset('catsix/assets/new/back.png')
	back.ImageColor3 = color.Light(uipallet.Main, 0.37)
	back.Parent = settingspane
	local settingsversion = Instance.new('TextLabel')
	settingsversion.Name = 'Version'
	settingsversion.Size = UDim2.new(1, 0, 0, 16)
	settingsversion.Position = UDim2.new(0, 0, 1, -16)
	settingsversion.BackgroundTransparency = 1
	settingsversion.Text = 'Vape '..mainapi.Version..' '..(
		isfile('catsix/profiles/commit.txt') and readfile('catsix/profiles/commit.txt'):sub(1, 6) or ''
	)..' '
	settingsversion.TextColor3 = color.Dark(uipallet.Text, 0.43)
	settingsversion.TextXAlignment = Enum.TextXAlignment.Right
	settingsversion.TextSize = 10
	settingsversion.FontFace = uipallet.Font
	settingsversion.Parent = settingspane
	addCorner(settingspane)
	local settingschildren = Instance.new('Frame')
	settingschildren.Name = 'Children'
	settingschildren.Size = UDim2.new(1, 0, 1, -57)
	settingschildren.Position = UDim2.fromOffset(0, 41)
	settingschildren.BackgroundColor3 = uipallet.Main
	settingschildren.BorderSizePixel = 0
	settingschildren.Parent = settingspane
	local settingswindowlist = Instance.new('UIListLayout')
	settingswindowlist.SortOrder = Enum.SortOrder.LayoutOrder
	settingswindowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	settingswindowlist.Parent = settingschildren
	categoryapi.Object = window

	function categoryapi:CreateBind()
		local optionapi = {Bind = {'RightShift'}}

		local button = Instance.new('TextButton')
		button.Size = UDim2.fromOffset(220, 40)
		button.BackgroundColor3 = uipallet.Main
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = '          Rebind GUI'
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextColor3 = color.Dark(uipallet.Text, 0.16)
		button.TextSize = 14
		button.FontFace = uipallet.Font
		button.Parent = settingschildren
		addTooltip(button, 'Change the bind of the GUI')
		local bind = Instance.new('TextButton')
		bind.Name = 'Bind'
		bind.Size = UDim2.fromOffset(20, 21)
		bind.Position = UDim2.new(1, -10, 0, 9)
		bind.AnchorPoint = Vector2.new(1, 0)
		bind.BackgroundColor3 = Color3.new(1, 1, 1)
		bind.BackgroundTransparency = 0.92
		bind.BorderSizePixel = 0
		bind.AutoButtonColor = false
		bind.Text = ''
		bind.Parent = button
		addTooltip(bind, 'Click to bind')
		addCorner(bind, UDim.new(0, 4))
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = UDim2.fromOffset(12, 12)
		icon.Position = UDim2.new(0.5, -6, 0, 5)
		icon.BackgroundTransparency = 1
		icon.Image = getcustomasset('catsix/assets/new/bind.png')
		icon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		icon.Parent = bind
		local label = Instance.new('TextLabel')
		label.Name = 'Text'
		label.Size = UDim2.fromScale(1, 1)
		label.Position = UDim2.fromOffset(0, 1)
		label.BackgroundTransparency = 1
		label.Visible = false
		label.Text = ''
		label.TextColor3 = color.Dark(uipallet.Text, 0.43)
		label.TextSize = 12
		label.FontFace = uipallet.Font
		label.Parent = bind

		function optionapi:SetBind(tab)
			mainapi.Keybind = #tab <= 0 and mainapi.Keybind or table.clone(tab)
			self.Bind = mainapi.Keybind
			if mainapi.VapeButton then
				mainapi.VapeButton:Destroy()
				mainapi.VapeButton = nil
			end

			bind.Visible = true
			label.Visible = true
			icon.Visible = false
			label.Text = table.concat(mainapi.Keybind, ' + '):upper()
			bind.Size = UDim2.fromOffset(math.max(getfontsize(label.Text, label.TextSize, label.Font).X + 10, 20), 21)
		end

		bind.MouseEnter:Connect(function()
			label.Visible = false
			icon.Visible = not label.Visible
			icon.Image = getcustomasset('catsix/assets/new/edit.png')
			icon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
		end)
		bind.MouseLeave:Connect(function()
			label.Visible = true
			icon.Visible = not label.Visible
			icon.Image = getcustomasset('catsix/assets/new/bind.png')
			icon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		end)
		bind.MouseButton1Click:Connect(function()
			mainapi.Binding = optionapi
		end)

		categoryapi.Options.Bind = optionapi

		return optionapi
	end

	function categoryapi:CreateButton(categorysettings)
		local optionapi = {
			Enabled = false,
			Index = getTableSize(categoryapi.Buttons)
		}

		local button = Instance.new('TextButton')
		button.Name = categorysettings.Name
		button.Size = UDim2.fromOffset(220, 40)
		button.BackgroundColor3 = uipallet.Main
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = (categorysettings.Icon and '                                 ' or '             ')..categorysettings.Name
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextColor3 = color.Dark(uipallet.Text, 0.16)
		button.TextSize = 14
		button.FontFace = uipallet.Font
		button.Parent = children
		local icon
		if categorysettings.Icon then
			icon = Instance.new('ImageLabel')
			icon.Name = 'Icon'
			icon.Size = categorysettings.Size
			icon.Position = UDim2.fromOffset(13, 13)
			icon.BackgroundTransparency = 1
			icon.Image = categorysettings.Icon
			icon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
			icon.Parent = button
		end
		if categorysettings.Name == 'Profiles' then
			local label = Instance.new('TextLabel')
			label.Name = 'ProfileLabel'
			label.Size = UDim2.fromOffset(53, 24)
			label.Position = UDim2.new(1, -36, 0, 8)
			label.AnchorPoint = Vector2.new(1, 0)
			label.BackgroundColor3 = color.Light(uipallet.Main, 0.04)
			label.Text = 'default'
			label.TextColor3 = color.Dark(uipallet.Text, 0.29)
			label.TextSize = 12
			label.FontFace = uipallet.Font
			label.Parent = button
			addCorner(label)
			mainapi.ProfileLabel = label
		end
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(4, 8)
		arrow.Position = UDim2.new(1, -20, 0, 16)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('catsix/assets/new/expandright.png')
		arrow.ImageColor3 = color.Light(uipallet.Main, 0.37)
		arrow.Parent = button
		optionapi.Name = categorysettings.Name
		optionapi.Icon = icon
		optionapi.Object = button

		function optionapi:Toggle()
			self.Enabled = not self.Enabled
			tween:Tween(arrow, uipallet.Tween, {
				Position = UDim2.new(1, self.Enabled and -14 or -20, 0, 16)
			})
			button.TextColor3 = self.Enabled and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or uipallet.Text
			if icon then
				icon.ImageColor3 = button.TextColor3
			end
			button.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			categorysettings.Window.Visible = self.Enabled
		end

		button.MouseEnter:Connect(function()
			if not optionapi.Enabled then
				button.TextColor3 = uipallet.Text
				if buttonicon then buttonicon.ImageColor3 = uipallet.Text end
				button.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			end
		end)
		button.MouseLeave:Connect(function()
			if not optionapi.Enabled then
				button.TextColor3 = color.Dark(uipallet.Text, 0.16)
				if buttonicon then buttonicon.ImageColor3 = color.Dark(uipallet.Text, 0.16) end
				button.BackgroundColor3 = uipallet.Main
			end
		end)
		button.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)

		categoryapi.Buttons[categorysettings.Name] = optionapi

		return optionapi
	end

	function categoryapi:CreateDivider(text)
		return components.Divider(children, text)
	end

	function categoryapi:CreateOverlayBar()
		local optionapi = {Toggles = {}}

		local bar = Instance.new('Frame')
		bar.Name = 'Overlays'
		bar.Size = UDim2.fromOffset(220, 36)
		bar.BackgroundColor3 = uipallet.Main
		bar.BorderSizePixel = 0
		bar.Parent = children
		components.Divider(bar)
		local button = Instance.new('ImageButton')
		button.Size = UDim2.fromOffset(24, 24)
		button.Position = UDim2.new(1, -29, 0, 7)
		button.BackgroundTransparency = 1
		button.AutoButtonColor = false
		button.Image = getcustomasset('catsix/assets/new/overlaysicon.png')
		button.ImageColor3 = color.Light(uipallet.Main, 0.37)
		button.Parent = bar
		addCorner(button, UDim.new(1, 0))
		addTooltip(button, 'Open overlays menu')
		local shadow = Instance.new('TextButton')
		shadow.Name = 'Shadow'
		shadow.Size = UDim2.new(1, 0, 1, -5)
		shadow.BackgroundColor3 = Color3.new()
		shadow.BackgroundTransparency = 1
		shadow.AutoButtonColor = false
		shadow.ClipsDescendants = true
		shadow.Visible = false
		shadow.Text = ''
		shadow.Parent = window
		addCorner(shadow)
		local window = Instance.new('Frame')
		window.Size = UDim2.fromOffset(220, 42)
		window.Position = UDim2.fromScale(0, 1)
		window.BackgroundColor3 = uipallet.Main
		window.Parent = shadow
		addCorner(window)
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = UDim2.fromOffset(14, 12)
		icon.Position = UDim2.fromOffset(10, 13)
		icon.BackgroundTransparency = 1
		icon.Image = getcustomasset('catsix/assets/new/overlaystab.png')
		icon.ImageColor3 = uipallet.Text
		icon.Parent = window
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -36, 0, 38)
		title.Position = UDim2.fromOffset(36, 0)
		title.BackgroundTransparency = 1
		title.Text = 'Overlays'
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 15
		title.FontFace = uipallet.Font
		title.Parent = window
		local close = addCloseButton(window, 7)
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.fromOffset(0, 37)
		divider.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		divider.BorderSizePixel = 0
		divider.Parent = window
		local childrentoggle = Instance.new('Frame')
		childrentoggle.Position = UDim2.fromOffset(0, 38)
		childrentoggle.BackgroundTransparency = 1
		childrentoggle.Parent = window
		local windowlist = Instance.new('UIListLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		windowlist.Parent = childrentoggle

		function optionapi:CreateToggle(togglesettings)
			local toggleapi = {
				Enabled = false,
				Index = getTableSize(optionapi.Toggles)
			}

			local hovered = false
			local toggle = Instance.new('TextButton')
			toggle.Name = togglesettings.Name..'Toggle'
			toggle.Size = UDim2.new(1, 0, 0, 40)
			toggle.BackgroundTransparency = 1
			toggle.AutoButtonColor = false
			toggle.Text = string.rep(' ', 33 * scale.Scale)..togglesettings.Name
			toggle.TextXAlignment = Enum.TextXAlignment.Left
			toggle.TextColor3 = color.Dark(uipallet.Text, 0.16)
			toggle.TextSize = 14
			toggle.FontFace = uipallet.Font
			toggle.Parent = childrentoggle
			local icon = Instance.new('ImageLabel')
			icon.Name = 'Icon'
			icon.Size = togglesettings.Size
			icon.Position = togglesettings.Position
			icon.BackgroundTransparency = 1
			icon.Image = togglesettings.Icon
			icon.ImageColor3 = uipallet.Text
			icon.Parent = toggle
			local knob = Instance.new('Frame')
			knob.Name = 'Knob'
			knob.Size = UDim2.fromOffset(22, 12)
			knob.Position = UDim2.new(1, -30, 0, 14)
			knob.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
			knob.Parent = toggle
			addCorner(knob, UDim.new(1, 0))
			local knobmain = knob:Clone()
			knobmain.Size = UDim2.fromOffset(8, 8)
			knobmain.Position = UDim2.fromOffset(2, 2)
			knobmain.BackgroundColor3 = uipallet.Main
			knobmain.Parent = knob
			toggleapi.Object = toggle

			function toggleapi:Toggle()
				self.Enabled = not self.Enabled
				tween:Tween(knob, uipallet.Tween, {
					BackgroundColor3 = self.Enabled and Color3.fromHSV(
						mainapi.GUIColor.Hue,
						mainapi.GUIColor.Sat,
						mainapi.GUIColor.Value
					) or (hovered and color.Light(uipallet.Main, 0.37) or color.Light(uipallet.Main, 0.14))
				})
				tween:Tween(knobmain, uipallet.Tween, {
					Position = UDim2.fromOffset(self.Enabled and 12 or 2, 2)
				})
				togglesettings.Function(self.Enabled)
			end

			scale:GetPropertyChangedSignal('Scale'):Connect(function()
				toggle.Text = string.rep(' ', 33 * scale.Scale)..togglesettings.Name
			end)
			toggle.MouseEnter:Connect(function()
				hovered = true
				if not toggleapi.Enabled then
					tween:Tween(knob, uipallet.Tween, {
						BackgroundColor3 = color.Light(uipallet.Main, 0.37)
					})
				end
			end)
			toggle.MouseLeave:Connect(function()
				hovered = false
				if not toggleapi.Enabled then
					tween:Tween(knob, uipallet.Tween, {
						BackgroundColor3 = color.Light(uipallet.Main, 0.14)
					})
				end
			end)
			toggle.MouseButton1Click:Connect(function()
				toggleapi:Toggle()
			end)

			table.insert(optionapi.Toggles, toggleapi)

			return toggleapi
		end

		button.MouseEnter:Connect(function()
			button.ImageColor3 = uipallet.Text
			tween:Tween(button, uipallet.Tween, {
				BackgroundTransparency = 0.9
			})
		end)
		button.MouseLeave:Connect(function()
			button.ImageColor3 = color.Light(uipallet.Main, 0.37)
			tween:Tween(button, uipallet.Tween, {
				BackgroundTransparency = 1
			})
		end)
		button.MouseButton1Click:Connect(function()
			shadow.Visible = true
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 0.5
			})
			tween:Tween(window, uipallet.Tween, {
				Position = UDim2.new(0, 0, 1, -(window.Size.Y.Offset))
			})
		end)
		close.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(window, uipallet.Tween, {
				Position = UDim2.fromScale(0, 1)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		shadow.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(window, uipallet.Tween, {
				Position = UDim2.fromScale(0, 1)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			window.Size = UDim2.fromOffset(220, math.min(37 + windowlist.AbsoluteContentSize.Y / scale.Scale, 605))
			childrentoggle.Size = UDim2.fromOffset(220, window.Size.Y.Offset - 5)
		end)

		mainapi.Overlays = optionapi

		return optionapi
	end

	function categoryapi:CreateSettingsDivider()
		components.Divider(settingschildren)
	end

	function categoryapi:CreateSettingsPane(categorysettings)
		local optionapi = {}

		local button = Instance.new('TextButton')
		button.Name = categorysettings.Name
		button.Size = UDim2.fromOffset(220, 40)
		button.BackgroundColor3 = uipallet.Main
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = '          '..categorysettings.Name
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextColor3 = color.Dark(uipallet.Text, 0.16)
		button.TextSize = 14
		button.FontFace = uipallet.Font
		button.Parent = settingschildren
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(4, 8)
		arrow.Position = UDim2.new(1, -20, 0, 16)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('catsix/assets/new/expandright.png')
		arrow.ImageColor3 = color.Light(uipallet.Main, 0.37)
		arrow.Parent = button
		local settingspane = Instance.new('TextButton')
		settingspane.Size = UDim2.fromScale(1, 1)
		settingspane.BackgroundColor3 = uipallet.Main
		settingspane.AutoButtonColor = false
		settingspane.Visible = false
		settingspane.Text = ''
		settingspane.Parent = window
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -36, 0, 20)
		title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 11)
		title.BackgroundTransparency = 1
		title.Text = categorysettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = settingspane
		local close = addCloseButton(settingspane)
		local back = Instance.new('ImageButton')
		back.Name = 'Back'
		back.Size = UDim2.fromOffset(16, 16)
		back.Position = UDim2.fromOffset(11, 13)
		back.BackgroundTransparency = 1
		back.Image = getcustomasset('catsix/assets/new/back.png')
		back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		back.Parent = settingspane
		addCorner(settingspane)
		local settingschildren = Instance.new('Frame')
		settingschildren.Name = 'Children'
		settingschildren.Size = UDim2.new(1, 0, 1, -57)
		settingschildren.Position = UDim2.fromOffset(0, 41)
		settingschildren.BackgroundColor3 = uipallet.Main
		settingschildren.BorderSizePixel = 0
		settingschildren.Parent = settingspane
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.BackgroundColor3 = Color3.new(1, 1, 1)
		divider.BackgroundTransparency = 0.928
		divider.BorderSizePixel = 0
		divider.Parent = settingschildren
		local settingswindowlist = Instance.new('UIListLayout')
		settingswindowlist.SortOrder = Enum.SortOrder.LayoutOrder
		settingswindowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		settingswindowlist.Parent = settingschildren

		for i, v in components do
			optionapi['Create'..i] = function(_, settings)
				return v(settings, settingschildren, categoryapi)
			end
		end

		back.MouseEnter:Connect(function()
			back.ImageColor3 = uipallet.Text
		end)
		back.MouseLeave:Connect(function()
			back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end)
		back.MouseButton1Click:Connect(function()
			settingspane.Visible = false
		end)
		button.MouseEnter:Connect(function()
			button.TextColor3 = uipallet.Text
			button.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		end)
		button.MouseLeave:Connect(function()
			button.TextColor3 = color.Dark(uipallet.Text, 0.16)
			button.BackgroundColor3 = uipallet.Main
		end)
		button.MouseButton1Click:Connect(function()
			settingspane.Visible = true
		end)
		close.MouseButton1Click:Connect(function()
			settingspane.Visible = false
		end)
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			window.Size = UDim2.fromOffset(220, 45 + windowlist.AbsoluteContentSize.Y / scale.Scale)
			for _, v in categoryapi.Buttons do
				if v.Icon then
					v.Object.Text = string.rep(' ', 33 * scale.Scale)..v.Name
				end
			end
		end)

		return optionapi
	end

	function categoryapi:CreateGUISlider(optionsettings)
		local optionapi = {
			Type = 'GUISlider',
			Notch = 4,
			Hue = 0.46,
			Sat = 0.96,
			Value = 0.52,
			Rainbow = false,
			CustomColor = false
		}
		local slidercolors = {
			Color3.fromRGB(250, 50, 56),
			Color3.fromRGB(242, 99, 33),
			Color3.fromRGB(252, 179, 22),
			Color3.fromRGB(5, 133, 104),
			Color3.fromRGB(47, 122, 229),
			Color3.fromRGB(126, 84, 217),
			Color3.fromRGB(232, 96, 152)
		}
		local slidercolorpos = {
			4,
			33,
			62,
			90,
			119,
			148,
			177
		}

		local function createSlider(name, gradientColor)
			local slider = Instance.new('TextButton')
			slider.Name = optionsettings.Name..'Slider'..name
			slider.Size = UDim2.fromOffset(220, 50)
			slider.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
			slider.BorderSizePixel = 0
			slider.AutoButtonColor = false
			slider.Visible = false
			slider.Text = ''
			slider.Parent = settingschildren
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
			local holder = Instance.new('Frame')
			holder.Name = 'Slider'
			holder.Size = UDim2.fromOffset(200, 2)
			holder.Position = UDim2.fromOffset(10, 37)
			holder.BackgroundColor3 = Color3.new(1, 1, 1)
			holder.BorderSizePixel = 0
			holder.Parent = slider
			local uigradient = Instance.new('UIGradient')
			uigradient.Color = gradientColor
			uigradient.Parent = holder
			local fill = holder:Clone()
			fill.Name = 'Fill'
			fill.Size = UDim2.fromScale(math.clamp(1, 0.04, 0.96), 1)
			fill.Position = UDim2.new()
			fill.BackgroundTransparency = 1
			fill.Parent = holder
			local knobframe = Instance.new('Frame')
			knobframe.Name = 'Knob'
			knobframe.Size = UDim2.fromOffset(24, 4)
			knobframe.Position = UDim2.fromScale(1, 0.5)
			knobframe.AnchorPoint = Vector2.new(0.5, 0.5)
			knobframe.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
			knobframe.BorderSizePixel = 0
			knobframe.Parent = fill
			local knob = Instance.new('Frame')
			knob.Name = 'Knob'
			knob.Size = UDim2.fromOffset(14, 14)
			knob.Position = UDim2.fromScale(0.5, 0.5)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.BackgroundColor3 = uipallet.Text
			knob.Parent = knobframe
			addCorner(knob, UDim.new(1, 0))
			if name == 'Custom color' then
				local reset = Instance.new('TextButton')
				reset.Size = UDim2.fromOffset(45, 20)
				reset.Position = UDim2.new(1, -52, 0, 5)
				reset.BackgroundTransparency = 1
				reset.Text = 'RESET'
				reset.TextColor3 = color.Dark(uipallet.Text, 0.16)
				reset.TextSize = 11
				reset.FontFace = uipallet.Font
				reset.Parent = slider
				reset.MouseButton1Click:Connect(function()
					optionapi:SetValue(nil, nil, nil, 4)
				end)
			end

			slider.InputBegan:Connect(function(inputObj)
				if
					(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
					and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
				then
					local changed = inputService.InputChanged:Connect(function(input)
						if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
							local value = math.clamp((input.Position.X - holder.AbsolutePosition.X) / holder.AbsoluteSize.X, 0, 1)
							optionapi:SetValue(
								name == 'Custom color' and value or nil,
								name == 'Saturation' and value or nil,
								name == 'Vibrance' and value or nil,
								name == 'Opacity' and value or nil
							)
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

			return slider
		end

		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.fromOffset(220, 50)
		slider.BackgroundTransparency = 1
		slider.AutoButtonColor = false
		slider.Text = ''
		slider.Parent = settingschildren
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
		local holder = Instance.new('Frame')
		holder.Name = 'Slider'
		holder.Size = UDim2.fromOffset(200, 2)
		holder.Position = UDim2.fromOffset(10, 37)
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Parent = slider
		local colornum = 0
		for i, color in slidercolors do
			local colorframe = Instance.new('Frame')
			colorframe.Size = UDim2.fromOffset(27 + (((i + 1) % 2) == 0 and 1 or 0), 2)
			colorframe.Position = UDim2.fromOffset(colornum, 0)
			colorframe.BackgroundColor3 = color
			colorframe.BorderSizePixel = 0
			colorframe.Parent = holder
			colornum += (colorframe.Size.X.Offset + 1)
		end
		local preview = Instance.new('ImageButton')
		preview.Name = 'Preview'
		preview.Size = UDim2.fromOffset(12, 12)
		preview.Position = UDim2.new(1, -22, 0, 10)
		preview.BackgroundTransparency = 1
		preview.Image = getcustomasset('catsix/assets/new/colorpreview.png')
		preview.ImageColor3 = Color3.fromHSV(optionapi.Hue, 1, 1)
		preview.Parent = slider
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
		local expandbutton = Instance.new('TextButton')
		expandbutton.Name = 'Expand'
		expandbutton.Size = UDim2.fromOffset(17, 13)
		expandbutton.Position = UDim2.new(0, getfontsize(title.Text, title.TextSize, title.Font).X + 11, 0, 7)
		expandbutton.BackgroundTransparency = 1
		expandbutton.Text = ''
		expandbutton.Parent = slider
		local expandicon = Instance.new('ImageLabel')
		expandicon.Name = 'Expand'
		expandicon.Size = UDim2.fromOffset(9, 5)
		expandicon.Position = UDim2.fromOffset(4, 4)
		expandicon.BackgroundTransparency = 1
		expandicon.Image = getcustomasset('catsix/assets/new/expandicon.png')
		expandicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		expandicon.Parent = expandbutton
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
		local knob = Instance.new('ImageLabel')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(26, 12)
		knob.Position = UDim2.fromOffset(slidercolorpos[4] - 3, -5)
		knob.BackgroundTransparency = 1
		knob.Image = getcustomasset('catsix/assets/new/guislider.png')
		knob.ImageColor3 = slidercolors[4]
		knob.Parent = holder
		optionsettings.Function = optionsettings.Function or function() end
		local rainbowTable = {}
		for i = 0, 1, 0.1 do
			table.insert(rainbowTable, ColorSequenceKeypoint.new(i, Color3.fromHSV(i, 1, 1)))
		end
		local colorSlider = createSlider('Custom color', ColorSequence.new(rainbowTable))
		local satSlider = createSlider('Saturation', ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, optionapi.Value)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, 1, optionapi.Value))
		}))
		local vibSlider = createSlider('Vibrance', ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, optionapi.Sat, 1))
		}))
		local normalknob = getcustomasset('catsix/assets/new/guislider.png')
		local rainbowknob = getcustomasset('catsix/assets/new/guisliderrain.png')
		local rainbowthread

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {
				Hue = self.Hue,
				Sat = self.Sat,
				Value = self.Value,
				Notch = self.Notch,
				CustomColor = self.CustomColor,
				Rainbow = self.Rainbow
			}
		end

		function optionapi:Load(tab)
			if tab.Rainbow then
				self:Toggle()
			end
			if self.Rainbow or tab.CustomColor then
				self:SetValue(tab.Hue, tab.Sat, tab.Value)
			else
				self:SetValue(nil, nil, nil, tab.Notch)
			end
		end

		function optionapi:SetValue(h, s, v, n)
			if n then
				if self.Rainbow then
					self:Toggle()
				end
				self.CustomColor = false
				h, s, v = slidercolors[n]:ToHSV()
			else
				self.CustomColor = true
			end

			self.Hue = h or self.Hue
			self.Sat = s or self.Sat
			self.Value = v or self.Value
			self.Notch = n
			preview.ImageColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
			satSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, self.Value)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, 1, self.Value))
			})
			vibSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, 1))
			})

			if self.Rainbow or self.CustomColor then
				knob.Image = rainbowknob
				knob.ImageColor3 = Color3.new(1, 1, 1)
				tween:Tween(knob, uipallet.Tween, {
					Position = UDim2.fromOffset(slidercolorpos[4] - 3, -5)
				})
			else
				knob.Image = normalknob
				knob.ImageColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
				tween:Tween(knob, uipallet.Tween, {
					Position = UDim2.fromOffset(slidercolorpos[n or 4] - 3, -5)
				})
			end

			if self.Rainbow then
				if h then
					colorSlider.Slider.Fill.Size = UDim2.fromScale(math.clamp(self.Hue, 0.04, 0.96), 1)
				end
				if s then
					satSlider.Slider.Fill.Size = UDim2.fromScale(math.clamp(self.Sat, 0.04, 0.96), 1)
				end
				if v then
					vibSlider.Slider.Fill.Size = UDim2.fromScale(math.clamp(self.Value, 0.04, 0.96), 1)
				end
			else
				if h then
					tween:Tween(colorSlider.Slider.Fill, uipallet.Tween, {
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
			end
			optionsettings.Function(self.Hue, self.Sat, self.Value)
		end

		function optionapi:Toggle()
			self.Rainbow = not self.Rainbow
			if rainbowthread then
				task.cancel(rainbowthread)
			end

			if self.Rainbow then
				knob.Image = rainbowknob
				table.insert(mainapi.RainbowTable, self)

				rainbow1.ImageColor3 = Color3.fromRGB(5, 127, 100)
				rainbowthread = task.delay(0.1, function()
					rainbow2.ImageColor3 = Color3.fromRGB(228, 125, 43)
					rainbowthread = task.delay(0.1, function()
						rainbow3.ImageColor3 = Color3.fromRGB(225, 46, 52)
						rainbowthread = nil
					end)
				end)
			else
				self:SetValue(nil, nil, nil, 4)
				knob.Image = normalknob
				local ind = table.find(mainapi.RainbowTable, self)
				if ind then
					table.remove(mainapi.RainbowTable, ind)
				end

				rainbow3.ImageColor3 = color.Light(uipallet.Main, 0.37)
				rainbowthread = task.delay(0.1, function()
					rainbow2.ImageColor3 = color.Light(uipallet.Main, 0.37)
					rainbowthread = task.delay(0.1, function()
						rainbow1.ImageColor3 = color.Light(uipallet.Main, 0.37)
					end)
				end)
			end
		end

		expandbutton.MouseEnter:Connect(function()
			expandicon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
		end)
		expandbutton.MouseLeave:Connect(function()
			expandicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		end)
		expandbutton.MouseButton1Click:Connect(function()
			colorSlider.Visible = not colorSlider.Visible
			satSlider.Visible = colorSlider.Visible
			vibSlider.Visible = satSlider.Visible
			expandicon.Rotation = satSlider.Visible and 180 or 0
		end)
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
				local changed = inputService.InputChanged:Connect(function(input)
					if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
						optionapi:SetValue(nil, nil, nil, math.clamp(math.round((input.Position.X - holder.AbsolutePosition.X) / scale.Scale / 27), 1, 7))
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
				optionapi:SetValue(nil, nil, nil, math.clamp(math.round((inputObj.Position.X - holder.AbsolutePosition.X) / scale.Scale / 27), 1, 7))
			end
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
					return tonumber(commas[1]) and Color3.fromRGB(
						tonumber(commas[1]),
						tonumber(commas[2]),
						tonumber(commas[3])
					) or Color3.fromHex(valuebox.Text)
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
		categoryapi.Options[optionsettings.Name] = optionapi

		return optionapi
	end

	back.MouseEnter:Connect(function()
		back.ImageColor3 = uipallet.Text
	end)
	back.MouseLeave:Connect(function()
		back.ImageColor3 = color.Light(uipallet.Main, 0.37)
	end)
	back.MouseButton1Click:Connect(function()
		settingspane.Visible = false
	end)
	close.MouseButton1Click:Connect(function()
		settingspane.Visible = false
	end)
	discordbutton.MouseButton1Click:Connect(function()
		task.spawn(function()
			local body = httpService:JSONEncode({
				nonce = httpService:GenerateGUID(false),
				args = {
					invite = {code = 'VZEQJxMSnG'},
					code = 'VZEQJxMSnG'
				},
				cmd = 'INVITE_BROWSER'
			})

			for i = 1, 14 do
				task.spawn(function()
					request({
						Method = 'POST',
						Url = 'http://127.0.0.1:64'..(53 + i)..'/rpc?v=1',
						Headers = {
							['Content-Type'] = 'application/json',
							Origin = 'https://discord.com'
						},
						Body = body
					})
				end)
			end
		end)

		task.spawn(function()
			tooltip.Text = 'Copied!'
			setclipboard('https://discord.gg/VZEQJxMSnG')
		end)
	end)
	settingsbutton.MouseEnter:Connect(function()
		settingsicon.ImageColor3 = uipallet.Text
	end)
	settingsbutton.MouseLeave:Connect(function()
		settingsicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
	end)
	settingsbutton.MouseButton1Click:Connect(function()
		settingspane.Visible = true
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		window.Size = UDim2.fromOffset(220, 42 + windowlist.AbsoluteContentSize.Y / scale.Scale)
		for _, v in categoryapi.Buttons do
			if v.Icon then
				v.Object.Text = string.rep(' ', 36 * scale.Scale)..v.Name
			end
		end
	end)

	self.Categories.Main = categoryapi

	return categoryapi
end

function mainapi:CreateCategory(categorysettings)
	local categoryapi = {
		Type = 'Category',
		Expanded = false
	}

	local window = Instance.new('TextButton')
	window.Name = categorysettings.Name..'Category'
	window.Size = UDim2.fromOffset(220, 41)
	window.Position = UDim2.fromOffset(236, 60)
	window.BackgroundColor3 = uipallet.Main
	window.AutoButtonColor = false
	window.Visible = false
	window.Text = ''
	window.Parent = clickgui
	addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = categorysettings.Size
	icon.Position = UDim2.fromOffset(12, (icon.Size.X.Offset > 20 and 14 or 13))
	icon.BackgroundTransparency = 1
	icon.Image = categorysettings.Icon
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -(categorysettings.Size.X.Offset > 18 and 40 or 33), 0, 41)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 0)
	title.BackgroundTransparency = 1
	title.Text = categorysettings.Name
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = window
	local arrowbutton = Instance.new('TextButton')
	arrowbutton.Name = 'Arrow'
	arrowbutton.Size = UDim2.fromOffset(40, 40)
	arrowbutton.Position = UDim2.new(1, -40, 0, 0)
	arrowbutton.BackgroundTransparency = 1
	arrowbutton.Text = ''
	arrowbutton.Parent = window
	local arrow = Instance.new('ImageLabel')
	arrow.Name = 'Arrow'
	arrow.Size = UDim2.fromOffset(9, 4)
	arrow.Position = UDim2.fromOffset(20, 18)
	arrow.BackgroundTransparency = 1
	arrow.Image = getcustomasset('catsix/assets/new/expandup.png')
	arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	arrow.Rotation = 180
	arrow.Parent = arrowbutton
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -41)
	children.Position = UDim2.fromOffset(0, 37)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.Visible = false
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 37)
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.928
	divider.BorderSizePixel = 0
	divider.Visible = false
	divider.Parent = window
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
			Tags = {},
			Index = getTableSize(mainapi.Modules),
			ExtraText = modulesettings.ExtraText,
			Name = modulesettings.Name,
			Category = categorysettings.Name
		}

		local hovered = false
		local modulebutton = Instance.new('TextButton')
		modulebutton.Name = modulesettings.Name
		modulebutton.Size = UDim2.fromOffset(220, 40)
		modulebutton.BackgroundColor3 = uipallet.Main
		modulebutton.BorderSizePixel = 0
		modulebutton.AutoButtonColor = false
		modulebutton.Text = '            '..modulesettings.Name
		modulebutton.TextXAlignment = Enum.TextXAlignment.Left
		modulebutton.TextColor3 = color.Dark(uipallet.Text, 0.16)
		modulebutton.TextSize = 14
		modulebutton.FontFace = uipallet.Font
		if not pcall(function()
			modulebutton.Parent = children
		end) and mainapi.ThreadFix then
			setthreadidentity(8)
			modulebutton.Parent = children
		end
		local indicatorholder = Instance.new('Frame')
		indicatorholder.Parent = modulebutton
		indicatorholder.Size = UDim2.fromOffset(0, 21)
		indicatorholder.AnchorPoint = Vector2.new(0, 0.5)
		indicatorholder.Name = 'Indicators'
		indicatorholder.BackgroundTransparency = 1
		indicatorholder.Position = UDim2.fromScale(0.85, 0.5)
		local layout = Instance.new('UIListLayout')
		layout.Parent = indicatorholder
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 5)
		modulesettings.Tags = modulesettings.Tags or {}
		local featureTag = getFeatureTag(modulesettings.Name)
		if featureTag and not table.find(modulesettings.Tags, featureTag) then
			table.insert(modulesettings.Tags, featureTag)
		end
		task.spawn(function()
			for i, tag in modulesettings.Tags do
				tag = tag:upper()
				modulesettings.Tags[i] = tag:lower()
				local size = getfontsize(removeTags(tag), 12, uipallet.Font, Vector2.new(100000, 100000))
				local indicator = Instance.new('TextLabel')
				indicator.LayoutOrder = i - 1
				indicator.Size = UDim2.new(0, size.X + 4, 0, 21)
				indicator.BackgroundColor3 = Color3.new(1, 1, 1)
				indicator.TextSize = 14
				indicator.TextTransparency = 1
				indicator.Text = tag
				indicator.Name = tag
				indicator.Position = UDim2.new()
				indicator.TextColor3 = Color3.new(0, 0, 0)
				indicator.FontFace = uipallet.Font
				indicator.Parent = indicatorholder
				addCorner(indicator, UDim.new(0, 5))
				local text = indicator:Clone()
				text.Position = UDim2.new()
				text.Size = UDim2.fromScale(1, 1)
				text.BackgroundTransparency = 1
				text.Name = 'Text'
				text.AnchorPoint = Vector2.new()
				text.TextSize = 12
				text.TextTransparency = 0
				text.Parent = indicator
				table.insert(moduleapi.Tags, indicator)
				indicator.Visible = tag ~= 'MATCHED'
			end
		end)
		local gradient = Instance.new('UIGradient')
		gradient.Rotation = 90
		gradient.Enabled = false
		gradient.Parent = modulebutton
		local modulechildren = Instance.new('Frame')
		local bind = Instance.new('TextButton')
		addTooltip(modulebutton, modulesettings.Tooltip)
		addTooltip(bind, 'Click to bind')
		bind.Name = 'Bind'
		bind.Size = UDim2.fromOffset(20, 21)
		bind.Position = UDim2.new(1, -36, 0, 9)
		bind.AnchorPoint = Vector2.new(1, 0)
		bind.BackgroundColor3 = Color3.new(1, 1, 1)
		bind.BackgroundTransparency = 0.92
		bind.BorderSizePixel = 0
		bind.AutoButtonColor = false
		bind.Visible = false
		bind.Text = ''
		addCorner(bind, UDim.new(0, 4))
		local bindicon = Instance.new('ImageLabel')
		bindicon.Name = 'Icon'
		bindicon.Size = UDim2.fromOffset(12, 12)
		bindicon.Position = UDim2.new(0.5, -6, 0, 5)
		bindicon.BackgroundTransparency = 1
		bindicon.Image = getcustomasset('catsix/assets/new/bind.png')
		bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		bindicon.Parent = bind
		local bindtext = Instance.new('TextLabel')
		bindtext.Size = UDim2.fromScale(1, 1)
		bindtext.Position = UDim2.fromOffset(0, 1)
		bindtext.BackgroundTransparency = 1
		bindtext.Visible = false
		bindtext.Text = ''
		bindtext.TextColor3 = color.Dark(uipallet.Text, 0.43)
		bindtext.TextSize = 12
		bindtext.FontFace = uipallet.Font
		bindtext.Parent = bind
		local bindcover = Instance.new('ImageLabel')
		bindcover.Name = 'Cover'
		bindcover.Size = UDim2.fromOffset(154, 40)
		bindcover.BackgroundTransparency = 1
		bindcover.Visible = false
		bindcover.Image = getcustomasset('catsix/assets/new/bindbkg.png')
		bindcover.ScaleType = Enum.ScaleType.Slice
		bindcover.SliceCenter = Rect.new(0, 0, 141, 40)
		bindcover.Parent = modulebutton
		local bindcovertext = Instance.new('TextLabel')
		bindcovertext.Name = 'Text'
		bindcovertext.Size = UDim2.new(1, -10, 1, -3)
		bindcovertext.BackgroundTransparency = 1
		bindcovertext.Text = 'PRESS A KEY TO BIND'
		bindcovertext.TextColor3 = uipallet.Text
		bindcovertext.TextSize = 11
		bindcovertext.FontFace = uipallet.Font
		bindcovertext.Parent = bindcover
		bind.Parent = modulebutton
		local dotsbutton = Instance.new('TextButton')
		dotsbutton.Name = 'Dots'
		dotsbutton.Size = UDim2.fromOffset(25, 40)
		dotsbutton.Position = UDim2.new(1, -25, 0, 0)
		dotsbutton.BackgroundTransparency = 1
		dotsbutton.Text = ''
		dotsbutton.Parent = modulebutton
		local dots = Instance.new('ImageLabel')
		dots.Name = 'Dots'
		dots.Size = UDim2.fromOffset(3, 16)
		dots.Position = UDim2.fromOffset(4, 12)
		dots.BackgroundTransparency = 1
		dots.Image = getcustomasset('catsix/assets/new/dots.png')
		dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		dots.Parent = dotsbutton
		modulechildren.Name = modulesettings.Name..'Children'
		modulechildren.Size = UDim2.new(1, 0, 0, 0)
		modulechildren.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		modulechildren.BorderSizePixel = 0
		modulechildren.Visible = false
		modulechildren.Parent = children
		moduleapi.Children = modulechildren
		local windowlist = Instance.new('UIListLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		windowlist.Parent = modulechildren
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.new(0, 0, 1, -1)
		divider.BackgroundColor3 = Color3.new(0.19, 0.19, 0.19)
		divider.BackgroundTransparency = 0.52
		divider.BorderSizePixel = 0
		divider.Visible = false
		divider.Parent = modulebutton
		modulesettings.Function = modulesettings.Function or function() end
		addMaid(moduleapi)

		function moduleapi:SetBind(tab, mouse)
			if tab.Mobile then
				createMobileButton(moduleapi, Vector2.new(tab.X, tab.Y))
				return
			end

			self.Bind = table.clone(tab)
			if mouse then
				bindcovertext.Text = #tab <= 0 and 'BIND REMOVED' or 'BOUND TO'
				bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
				task.delay(1, function()
					bindcover.Visible = false
				end)
			end

			if #tab <= 0 then
				bindtext.Visible = false
				bindicon.Visible = true
				bind.Size = UDim2.fromOffset(20, 21)
			else
				bind.Visible = true
				bindtext.Visible = true
				bindicon.Visible = false
				bindtext.Text = table.concat(tab, ' + '):upper()
				bind.Size = UDim2.fromOffset(math.max(getfontsize(bindtext.Text, bindtext.TextSize, bindtext.Font).X + 10, 20), 21)
			end
		end

		function moduleapi:Toggle(multiple)
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			self.Enabled = not self.Enabled
			divider.Visible = self.Enabled
			gradient.Enabled = self.Enabled
			modulebutton.TextColor3 = (hovered or modulechildren.Visible) and uipallet.Text or color.Dark(uipallet.Text, 0.16)
			modulebutton.BackgroundColor3 = (hovered or modulechildren.Visible) and color.Light(uipallet.Main, 0.02) or uipallet.Main
			dots.ImageColor3 = self.Enabled and Color3.fromRGB(50, 50, 50) or color.Light(uipallet.Main, 0.37)
			bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
			bindtext.TextColor3 = color.Dark(uipallet.Text, 0.43)
			if not self.Enabled then
				for _, v in self.Connections do
					v:Disconnect()
				end
				table.clear(self.Connections)
			end
			if not multiple then
				mainapi:UpdateTextGUI()
			end
			mainapi:QueueSave()
			task.spawn(modulesettings.Function, self.Enabled)
		end

		for i, v in components do
			moduleapi['Create'..i] = function(_, optionsettings)
				return v(optionsettings, modulechildren, moduleapi)
			end
		end

		bind.MouseEnter:Connect(function()
			bindtext.Visible = false
			bindicon.Visible = not bindtext.Visible
			bindicon.Image = getcustomasset('catsix/assets/new/edit.png')
			if not moduleapi.Enabled then bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.16) end
		end)
		bind.MouseLeave:Connect(function()
			bindtext.Visible = #moduleapi.Bind > 0
			bindicon.Visible = not bindtext.Visible
			bindicon.Image = getcustomasset('catsix/assets/new/bind.png')
			if not moduleapi.Enabled then
				bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
			end
		end)
		bind.MouseButton1Click:Connect(function()
			bindcovertext.Text = 'PRESS A KEY TO BIND'
			bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
			bindcover.Visible = true
			mainapi.Binding = moduleapi
		end)
		dotsbutton.MouseEnter:Connect(function()
			if not moduleapi.Enabled then
				dots.ImageColor3 = uipallet.Text
			end
		end)
		dotsbutton.MouseLeave:Connect(function()
			if not moduleapi.Enabled then
				dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
			end
		end)
		dotsbutton.MouseButton1Click:Connect(function()
			modulechildren.Visible = not modulechildren.Visible
		end)
		dotsbutton.MouseButton2Click:Connect(function()
			modulechildren.Visible = not modulechildren.Visible
		end)
		modulebutton.MouseEnter:Connect(function()
			hovered = true
			if not moduleapi.Enabled and not modulechildren.Visible then
				modulebutton.TextColor3 = uipallet.Text
				modulebutton.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			end
			bind.Visible = #moduleapi.Bind > 0 or hovered or modulechildren.Visible
		end)
		modulebutton.MouseLeave:Connect(function()
			hovered = false
			if not moduleapi.Enabled and not modulechildren.Visible then
				modulebutton.TextColor3 = color.Dark(uipallet.Text, 0.16)
				modulebutton.BackgroundColor3 = uipallet.Main
			end
			bind.Visible = #moduleapi.Bind > 0 or hovered or modulechildren.Visible
		end)
		modulebutton.MouseButton1Click:Connect(function()
			moduleapi:Toggle()
		end)
		modulebutton.MouseButton2Click:Connect(function()
			modulechildren.Visible = not modulechildren.Visible
		end)
		if inputService.TouchEnabled then
			local heldbutton = false
			modulebutton.MouseButton1Down:Connect(function()
				heldbutton = true
				local holdtime, holdpos = tick(), inputService:GetMouseLocation()
				repeat
					heldbutton = (inputService:GetMouseLocation() - holdpos).Magnitude < 3
					task.wait()
				until (tick() - holdtime) > 1 or not heldbutton or not clickgui.Visible
				if heldbutton and clickgui.Visible then
					if mainapi.ThreadFix then
						setthreadidentity(8)
					end
					clickgui.Visible = false
					tooltip.Visible = false
					mainapi:BlurCheck()
					for _, mobileButton in mainapi.Modules do
						if mobileButton.Bind.Button then
							mobileButton.Bind.Button.Visible = true
						end
					end

					local touchconnection
					touchconnection = inputService.InputBegan:Connect(function(inputType)
						if inputType.UserInputType == Enum.UserInputType.Touch then
							if mainapi.ThreadFix then
								setthreadidentity(8)
							end
							createMobileButton(moduleapi, inputType.Position + Vector3.new(0, guiService:GetGuiInset().Y, 0))
							clickgui.Visible = true
							mainapi:BlurCheck()
							for _, mobileButton in mainapi.Modules do
								if mobileButton.Bind.Button then
									mobileButton.Bind.Button.Visible = false
								end
							end
							touchconnection:Disconnect()
						end
					end)
				end
			end)
			modulebutton.MouseButton1Up:Connect(function()
				heldbutton = false
			end)
		end
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
		children.Visible = self.Expanded
		arrow.Rotation = self.Expanded and 0 or 180
		window.Size = UDim2.fromOffset(220, self.Expanded and math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601) or 41)
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end

	arrowbutton.MouseButton1Click:Connect(function()
		categoryapi:Expand()
	end)
	arrowbutton.MouseButton2Click:Connect(function()
		categoryapi:Expand()
	end)
	arrowbutton.MouseEnter:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(220, 220, 220)
	end)
	arrowbutton.MouseLeave:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	end)
	children:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end)
	window.InputBegan:Connect(function(inputObj)
		if inputObj.Position.Y < window.AbsolutePosition.Y + 41 and inputObj.UserInputType == Enum.UserInputType.MouseButton2 then
			categoryapi:Expand()
		end
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		if categoryapi.Expanded then
			window.Size = UDim2.fromOffset(220, math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601))
		end
	end)

	categoryapi.Button = self.Categories.Main:CreateButton({
		Name = categorysettings.Name,
		Icon = categorysettings.Icon,
		Size = categorysettings.Size,
		Window = window
	})

	categoryapi.Object = window
	self.Categories[categorysettings.Name] = categoryapi

	return categoryapi
end

function mainapi:CreateOverlay(categorysettings)
	local window
	local categoryapi
	categoryapi = {
		Type = 'Overlay',
		Expanded = false,
		Button = self.Overlays:CreateToggle({
			Name = categorysettings.Name,
			Function = function(callback)
				window.Visible = callback and (clickgui.Visible or categoryapi.Pinned)
				if not callback then
					for _, v in categoryapi.Connections do
						v:Disconnect()
					end
					table.clear(categoryapi.Connections)
				end

				if categorysettings.Function then
					task.spawn(categorysettings.Function, callback)
				end
			end,
			Icon = categorysettings.Icon,
			Size = categorysettings.Size,
			Position = categorysettings.Position
		}),
		Pinned = false,
		Options = {}
	}

	window = Instance.new('TextButton')
	window.Name = categorysettings.Name..'Overlay'
	window.Size = UDim2.fromOffset(categorysettings.CategorySize or 220, 41)
	window.Position = UDim2.fromOffset(240, 46)
	window.BackgroundColor3 = uipallet.Main
	window.AutoButtonColor = false
	window.Visible = false
	window.Text = ''
	window.Parent = scaledgui
	local blur = addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = categorysettings.Size
	icon.Position = UDim2.fromOffset(12, (icon.Size.X.Offset > 14 and 14 or 13))
	icon.BackgroundTransparency = 1
	icon.Image = categorysettings.Icon
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -32, 0, 41)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 0)
	title.BackgroundTransparency = 1
	title.Text = categorysettings.Name
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = window
	local pin = Instance.new('ImageButton')
	pin.Name = 'Pin'
	pin.Size = UDim2.fromOffset(16, 16)
	pin.Position = UDim2.new(1, -47, 0, 12)
	pin.BackgroundTransparency = 1
	pin.AutoButtonColor = false
	pin.Image = getcustomasset('catsix/assets/new/pin.png')
	pin.ImageColor3 = color.Dark(uipallet.Text, 0.43)
	pin.Parent = window
	local dotsbutton = Instance.new('TextButton')
	dotsbutton.Name = 'Dots'
	dotsbutton.Size = UDim2.fromOffset(17, 40)
	dotsbutton.Position = UDim2.new(1, -17, 0, 0)
	dotsbutton.BackgroundTransparency = 1
	dotsbutton.Text = ''
	dotsbutton.Parent = window
	local dots = Instance.new('ImageLabel')
	dots.Name = 'Dots'
	dots.Size = UDim2.fromOffset(3, 16)
	dots.Position = UDim2.fromOffset(4, 12)
	dots.BackgroundTransparency = 1
	dots.Image = getcustomasset('catsix/assets/new/dots.png')
	dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
	dots.Parent = dotsbutton
	local customchildren = Instance.new('Frame')
	customchildren.Name = 'CustomChildren'
	customchildren.Size = UDim2.new(1, 0, 0, 200)
	customchildren.Position = UDim2.fromScale(0, 1)
	customchildren.BackgroundTransparency = 1
	customchildren.Parent = window
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -41)
	children.Position = UDim2.fromOffset(0, 37)
	children.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	children.BorderSizePixel = 0
	children.Visible = false
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children
	addMaid(categoryapi)

	function categoryapi:Expand(check)
		if check and not blur.Visible then return end
		self.Expanded = not self.Expanded
		children.Visible = self.Expanded
		dots.ImageColor3 = self.Expanded and uipallet.Text or color.Light(uipallet.Main, 0.37)
		if self.Expanded then
			window.Size = UDim2.fromOffset(window.Size.X.Offset, math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601))
		else
			window.Size = UDim2.fromOffset(window.Size.X.Offset, 41)
		end
	end

	function categoryapi:Pin()
		self.Pinned = not self.Pinned
		pin.ImageColor3 = self.Pinned and uipallet.Text or color.Dark(uipallet.Text, 0.43)
	end

	function categoryapi:Update()
		window.Visible = self.Button.Enabled and (clickgui.Visible or self.Pinned)
		if self.Expanded then
			self:Expand()
		end
		if clickgui.Visible then
			window.Size = UDim2.fromOffset(window.Size.X.Offset, 41)
			window.BackgroundTransparency = 0
			blur.Visible = true
			icon.Visible = true
			title.Visible = true
			pin.Visible = true
			dotsbutton.Visible = true
		else
			window.Size = UDim2.fromOffset(window.Size.X.Offset, 0)
			window.BackgroundTransparency = 1
			blur.Visible = false
			icon.Visible = false
			title.Visible = false
			pin.Visible = false
			dotsbutton.Visible = false
		end
	end

	for i, v in components do
		categoryapi['Create'..i] = function(self, optionsettings)
			return v(optionsettings, children, categoryapi)
		end
	end

	dotsbutton.MouseEnter:Connect(function()
		if not children.Visible then
			dots.ImageColor3 = uipallet.Text
		end
	end)
	dotsbutton.MouseLeave:Connect(function()
		if not children.Visible then
			dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end
	end)
	dotsbutton.MouseButton1Click:Connect(function()
		categoryapi:Expand(true)
	end)
	dotsbutton.MouseButton2Click:Connect(function()
		categoryapi:Expand(true)
	end)
	pin.MouseButton1Click:Connect(function()
		categoryapi:Pin()
	end)
	window.MouseButton2Click:Connect(function()
		categoryapi:Expand(true)
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		if categoryapi.Expanded then
			window.Size = UDim2.fromOffset(window.Size.X.Offset, math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601))
		end
	end)
	self:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
		categoryapi:Update()
	end))

	categoryapi:Update()
	categoryapi.Object = window
	categoryapi.Children = customchildren
	self.Categories[categorysettings.Name] = categoryapi

	return categoryapi
end

function mainapi:CreateCategoryList(categorysettings)
	local categoryapi = {
		Type = 'CategoryList',
		Expanded = false,
		List = {},
		ListEnabled = {},
		Objects = {},
		Options = {}
	}
	categorysettings.Color = categorysettings.Color or Color3.fromRGB(5, 134, 105)

	local window = Instance.new('TextButton')
	window.Name = categorysettings.Name..'CategoryList'
	window.Size = UDim2.fromOffset(220, 45)
	window.Position = UDim2.fromOffset(240, 46)
	window.BackgroundColor3 = uipallet.Main
	window.AutoButtonColor = false
	window.Visible = false
	window.Text = ''
	window.Parent = clickgui
	addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = categorysettings.Size
	icon.Position = categorysettings.Position or UDim2.fromOffset(12, (categorysettings.Size.X.Offset > 20 and 13 or 12))
	icon.BackgroundTransparency = 1
	icon.Image = categorysettings.Icon
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -(categorysettings.Size.X.Offset > 20 and 44 or 36), 0, 20)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 12)
	title.BackgroundTransparency = 1
	title.Text = categorysettings.Name
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = window
	local arrowbutton = Instance.new('TextButton')
	arrowbutton.Name = 'Arrow'
	arrowbutton.Size = UDim2.fromOffset(40, 40)
	arrowbutton.Position = UDim2.new(1, -40, 0, 0)
	arrowbutton.BackgroundTransparency = 1
	arrowbutton.Text = ''
	arrowbutton.Parent = window
	local arrow = Instance.new('ImageLabel')
	arrow.Name = 'Arrow'
	arrow.Size = UDim2.fromOffset(9, 4)
	arrow.Position = UDim2.fromOffset(20, 19)
	arrow.BackgroundTransparency = 1
	arrow.Image = getcustomasset('catsix/assets/new/expandup.png')
	arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	arrow.Rotation = 180
	arrow.Parent = arrowbutton
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -45)
	children.Position = UDim2.fromOffset(0, 45)
	children.BackgroundColor3 = uipallet.Main
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.Visible = false
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local childrentwo = Instance.new('Frame')
	childrentwo.BackgroundTransparency = 1
	childrentwo.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	childrentwo.Visible = false
	childrentwo.Parent = children
	local settings = Instance.new('ImageButton')
	settings.Name = 'Settings'
	settings.Size = UDim2.fromOffset(16, 16)
	settings.Position = UDim2.new(1, -52, 0, 13)
	settings.BackgroundTransparency = 1
	settings.AutoButtonColor = false
	settings.Image = getcustomasset('catsix/assets/new/customsettings.png')
	settings.ImageColor3 = color.Dark(uipallet.Text, 0.43)
	settings.Parent = window
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 41)
	divider.BorderSizePixel = 0
	divider.Visible = false
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.928
	divider.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Padding = UDim.new(0, 3)
	windowlist.Parent = children
	local windowlisttwo = Instance.new('UIListLayout')
	windowlisttwo.SortOrder = Enum.SortOrder.LayoutOrder
	windowlisttwo.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlisttwo.Parent = childrentwo
	local addbkg = Instance.new('Frame')
	addbkg.Name = 'Add'
	addbkg.Size = UDim2.fromOffset(200, 31)
	addbkg.Position = UDim2.fromOffset(10, 45)
	addbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
	addbkg.Parent = children
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
	addvalue.PlaceholderText = categorysettings.Placeholder or 'Add entry...'
	addvalue.TextXAlignment = Enum.TextXAlignment.Left
	addvalue.TextColor3 = Color3.new(1, 1, 1)
	addvalue.TextSize = 15
	addvalue.FontFace = uipallet.Font
	addvalue.ClearTextOnFocus = false
	addvalue.Parent = addbkg
	local addbutton = Instance.new('ImageButton')
	addbutton.Name = 'AddButton'
	addbutton.Size = UDim2.fromOffset(16, 16)
	addbutton.Position = UDim2.new(1, -26, 0, 10)
	addbutton.BackgroundTransparency = 1
	addbutton.Image = getcustomasset('catsix/assets/new/add.png')
	addbutton.ImageColor3 = categorysettings.Color
	addbutton.ImageTransparency = 0.3
	addbutton.Parent = addbkg
	if categorysettings.Profiles then
		local addrow = Instance.new('Frame')
		addrow.Name = 'AddRow'
		addrow.Size = UDim2.new(1, -20, 0, 36)
		addrow.BackgroundTransparency = 1
		addrow.LayoutOrder = addbkg.LayoutOrder
		addrow.Parent = children
		local addrowlayout = Instance.new('UIListLayout')
		addrowlayout.FillDirection = Enum.FillDirection.Horizontal
		addrowlayout.SortOrder = Enum.SortOrder.LayoutOrder
		addrowlayout.Padding = UDim.new(0, 8)
		addrowlayout.Parent = addrow

		addbkg.Size = UDim2.fromOffset(200, 31)
		addbkg.Position = UDim2.fromOffset(0, 0)
		addbkg.LayoutOrder = addrow.LayoutOrder + 1
		addbkg.Visible = false
		addvalue.Size = UDim2.new(1, -35, 1, 0)
		addvalue.TextSize = 15

		local createbkg = Instance.new('TextButton')
		createbkg.Name = 'CreateNew'
		createbkg.Size = UDim2.new(0.53, -4, 1, 0)
		createbkg.LayoutOrder = 1
		createbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		createbkg.AutoButtonColor = false
		createbkg.Text = ''
		createbkg.Parent = addrow
		addCorner(createbkg)
		local createinner = Instance.new('Frame')
		createinner.Size = UDim2.new(1, -2, 1, -2)
		createinner.Position = UDim2.fromOffset(1, 1)
		createinner.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		createinner.Parent = createbkg
		addCorner(createinner)
		local function addRowButtonContent(parent, asset, text, iconsize)
			local width = getfontsize(text, 11, uipallet.FontSemiBold).X
			local holder = Instance.new('Frame')
			holder.Name = 'Content'
			holder.Size = UDim2.new(0, iconsize + 7 + width, 1, 0)
			holder.Position = UDim2.fromScale(0.5, 0.5)
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.BackgroundTransparency = 1
			holder.ZIndex = 2
			holder.Parent = parent
			local icon = Instance.new('ImageLabel')
			icon.Name = 'Icon'
			icon.Size = UDim2.fromOffset(iconsize, iconsize)
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.new(0, 0, 0.5, 0)
			icon.BackgroundTransparency = 1
			icon.Image = getcustomasset(asset)
			icon.ImageColor3 = categorysettings.Color
			icon.ZIndex = 2
			icon.Parent = holder
			local label = Instance.new('TextLabel')
			label.Size = UDim2.new(0, width, 1, 0)
			label.Position = UDim2.fromOffset(iconsize + 7, 0)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextSize = 11
			label.FontFace = uipallet.FontSemiBold
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.ZIndex = 2
			label.Parent = holder
		end

		addRowButtonContent(createbkg, 'catsix/assets/new/add.png', 'CREATE NEW', 16)

		local newprofile = Instance.new('Frame')
		newprofile.Name = 'NewProfile'
		newprofile.Size = UDim2.new(1, 0, 1, 0)
		newprofile.BackgroundColor3 = uipallet.Main
		newprofile.BorderSizePixel = 0
		newprofile.Visible = false
		newprofile.ZIndex = 3
		newprofile.Parent = window

		local back = Instance.new('TextButton')
		back.Name = 'Back'
		back.Size = UDim2.fromOffset(15, 15)
		back.Position = UDim2.fromOffset(14, 15)
		back.BackgroundColor3 = color.Light(uipallet.Main, 0.06)
		back.AutoButtonColor = true
		back.Text = ''
		back.ZIndex = 4
		back.Parent = newprofile
		addCorner(back, UDim.new(1, 0))
		local backicon = Instance.new('ImageLabel')
		backicon.Size = UDim2.fromScale(1, 1)
		backicon.AnchorPoint = Vector2.new(0.5, 0.5)
		backicon.Position = UDim2.fromScale(0.5, 0.5)
		backicon.BackgroundTransparency = 1
		backicon.Image = getcustomasset('catsix/assets/new/back.png')
		backicon.ImageColor3 = uipallet.Text
		backicon.ZIndex = 5
		backicon.Parent = back

		local newtitle = Instance.new('TextLabel')
		newtitle.Size = UDim2.fromOffset(150, 20)
		newtitle.Position = UDim2.fromOffset(36, 12)
		newtitle.BackgroundTransparency = 1
		newtitle.Text = 'New Profile'
		newtitle.TextColor3 = uipallet.Text
		newtitle.TextSize = 13
		newtitle.FontFace = uipallet.Font
		newtitle.TextXAlignment = Enum.TextXAlignment.Left
		newtitle.ZIndex = 4
		newtitle.Parent = newprofile

		local newarrowbutton = Instance.new('TextButton')
		newarrowbutton.Name = 'Arrow'
		newarrowbutton.Size = UDim2.fromOffset(40, 40)
		newarrowbutton.Position = UDim2.new(1, -40, 0, 0)
		newarrowbutton.BackgroundTransparency = 1
		newarrowbutton.Text = ''
		newarrowbutton.ZIndex = 4
		newarrowbutton.Parent = newprofile
		local newarrow = Instance.new('ImageLabel')
		newarrow.Name = 'Arrow'
		newarrow.Size = UDim2.fromOffset(9, 4)
		newarrow.Position = UDim2.fromOffset(20, 19)
		newarrow.BackgroundTransparency = 1
		newarrow.Image = getcustomasset('catsix/assets/new/expandup.png')
		newarrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
		newarrow.ZIndex = 5
		newarrow.Parent = newarrowbutton
		newarrowbutton.MouseButton1Click:Connect(function()
			categoryapi:Expand()
			newarrow.Rotation = arrow.Rotation
		end)

		local namebkg = addbkg:Clone()
		namebkg.Name = 'NameBox'
		namebkg.Size = UDim2.new(1, -20, 0, 36)
		namebkg.Position = UDim2.fromOffset(10, 42)
		namebkg.Visible = true
		namebkg.ZIndex = 4
		for _, d in namebkg:GetDescendants() do
			if d:IsA('GuiObject') then d.ZIndex = 5 end
		end
		namebkg.Parent = newprofile
		local namebox = namebkg:FindFirstChildWhichIsA('TextBox')
		local nameadd = namebkg:FindFirstChild('AddButton')

		local countlabel = Instance.new('TextLabel')
		countlabel.Name = 'Count'
		countlabel.Size = UDim2.fromOffset(150, 16)
		countlabel.Position = UDim2.fromOffset(10, 94)
		countlabel.BackgroundTransparency = 1
		countlabel.RichText = true
		countlabel.Text = ''
		countlabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		countlabel.TextSize = 11
		countlabel.FontFace = uipallet.FontSemiBold
		countlabel.TextXAlignment = Enum.TextXAlignment.Left
		countlabel.ZIndex = 4
		countlabel.Parent = newprofile

		local editall = Instance.new('TextButton')
		editall.Name = 'EditAll'
		editall.Size = UDim2.fromOffset(50, 16)
		editall.Position = UDim2.new(1, -60, 0, 94)
		editall.BackgroundTransparency = 1
		editall.AutoButtonColor = false
		editall.Text = 'edit all'
		editall.TextColor3 = Color3.fromRGB(171, 171, 171)
		editall.TextSize = 11
		editall.FontFace = uipallet.Font
		editall.TextXAlignment = Enum.TextXAlignment.Right
		editall.ZIndex = 4
		editall.Parent = newprofile

		local modulelist = Instance.new('ScrollingFrame')
		modulelist.Name = 'Modules'
		modulelist.Size = UDim2.new(1, -16, 1, -123)
		modulelist.Position = UDim2.fromOffset(8, 114)
		modulelist.BackgroundTransparency = 1
		modulelist.BorderSizePixel = 0
		modulelist.ScrollBarThickness = 0
		modulelist.ScrollBarImageTransparency = 1
		modulelist.CanvasSize = UDim2.new()
		modulelist.ZIndex = 4
		modulelist.Parent = newprofile
		local modulelayout = Instance.new('UIListLayout')
		modulelayout.SortOrder = Enum.SortOrder.LayoutOrder
		modulelayout.Padding = UDim.new(0, 5)
		modulelayout.Parent = modulelist
		local modulepadding = Instance.new('UIPadding')
		modulepadding.PaddingTop = UDim.new(0, 2)
		modulepadding.PaddingLeft = UDim.new(0, 2)
		modulepadding.Parent = modulelist

		local openEditor

		local function accentColor()
			return Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		end

		local function accentTextColor()
			return mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		end

		local function listModules(query, affectedonly)
			local list = {}
			for name, mod in pairs(mainapi.Modules) do
				local rank = mod.Bind[1] and 1 or (mod.Enabled and 2 or 3)
				if (rank < 3 or not affectedonly) and (query == '' or tostring(name):lower():find(query, 1, true)) then
					table.insert(list, {Name = tostring(name), Module = mod, Rank = rank})
				end
			end
			table.sort(list, function(a, b)
				if a.Rank ~= b.Rank then
					return a.Rank < b.Rank
				end
				return a.Name < b.Name
			end)
			return list
		end

		local function addModuleChip(row, mod, offset)
			local bind = mod.Bind[1] and tostring(mod.Bind[1]):upper() or ''
			if not mod.Enabled and bind == '' then return end

			local chip = Instance.new('Frame')
			chip.Name = 'Chip'
			chip.Size = UDim2.fromOffset(mod.Enabled and 24 or math.max(getfontsize(bind, 11, uipallet.Font).X + 12, 20), 18)
			chip.AnchorPoint = Vector2.new(1, 0.5)
			chip.Position = UDim2.new(1, -offset, 0.5, 0)
			chip.BackgroundColor3 = mod.Enabled and accentColor() or color.Light(uipallet.Main, 0.08)
			chip.BorderSizePixel = 0
			chip.ZIndex = 5
			chip.Parent = row
			addCorner(chip, UDim.new(0, 4))
			local chiptext = Instance.new('TextLabel')
			chiptext.Name = 'Text'
			chiptext.Size = UDim2.fromScale(1, 1)
			chiptext.BackgroundTransparency = 1
			chiptext.Text = mod.Enabled and 'ON' or bind
			chiptext.TextColor3 = mod.Enabled and accentTextColor() or Color3.fromRGB(171, 171, 171)
			chiptext.TextSize = 11
			chiptext.FontFace = uipallet.Font
			chiptext.ZIndex = 6
			chiptext.Parent = chip

			return chip
		end

		local function refreshModules()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			
			for _, old in modulelist:GetChildren() do
				if old:IsA('TextButton') then
					old:Destroy()
				end
			end

			local list = listModules('', false)
			countlabel.Text = `<font color="rgb(255,255,255)">{#listModules('', true)}</font> AFFECTED MODULES`

			for i, entry in list do
				local row = Instance.new('TextButton')
				row.Name = entry.Name
				row.Size = UDim2.new(1, -4, 0, 34)
				row.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
				row.BorderSizePixel = 0
				row.AutoButtonColor = false
				row.Text = ''
				row.LayoutOrder = i
				row.ZIndex = 4
				row.Parent = modulelist
				addCorner(row)
				local rowstroke = Instance.new('UIStroke')
				rowstroke.Color = color.Light(uipallet.Main, 0.09)
				rowstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				rowstroke.Parent = row
				local label = Instance.new('TextLabel')
				label.Name = 'Label'
				label.Size = UDim2.new(1, -50, 1, 0)
				label.Position = UDim2.fromOffset(10, 0)
				label.BackgroundTransparency = 1
				label.Text = entry.Name
				label.TextColor3 = color.Dark(uipallet.Text, 0.16)
				label.TextSize = 13
				label.FontFace = uipallet.Font
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextTruncate = Enum.TextTruncate.AtEnd
				label.ZIndex = 5
				label.Parent = row
				addModuleChip(row, entry.Module, 8)

				row.MouseEnter:Connect(function()
					tween:Tween(row, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.075)})
				end)
				row.MouseLeave:Connect(function()
					tween:Tween(row, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.034)})
				end)
				row.MouseButton1Click:Connect(function()
					openEditor(entry.Name)
				end)
			end

			modulelist.CanvasSize = UDim2.fromOffset(0, (#list * 39) + 4)
		end

		local editor = Instance.new('Frame')
		editor.Name = 'ModuleEditor'
		editor.Size = UDim2.fromOffset(674, 387)
		editor.Position = UDim2.new(0.5, -337, 0.5, -193)
		editor.BackgroundColor3 = uipallet.Main
		editor.Visible = false
		editor.Parent = scaledgui
		addBlur(editor)
		addCorner(editor)
		makeDraggable(editor)
		table.insert(mainapi.Windows, editor)

		local editorside = Instance.new('Frame')
		editorside.Name = 'Sidebar'
		editorside.Size = UDim2.fromOffset(244, 387)
		editorside.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		editorside.BorderSizePixel = 0
		editorside.Parent = editor
		addCorner(editorside)
		local sideedge = Instance.new('Frame')
		sideedge.Name = 'Edge'
		sideedge.Size = UDim2.fromOffset(6, 387)
		sideedge.Position = UDim2.fromOffset(238, 0)
		sideedge.BackgroundColor3 = editorside.BackgroundColor3
		sideedge.BorderSizePixel = 0
		sideedge.Parent = editorside

		local editortitle = Instance.new('TextLabel')
		editortitle.Name = 'Title'
		editortitle.Size = UDim2.fromOffset(200, 28)
		editortitle.Position = UDim2.fromOffset(26, 21)
		editortitle.BackgroundTransparency = 1
		editortitle.Text = ''
		editortitle.TextColor3 = Color3.new(1, 1, 1)
		editortitle.TextSize = 19
		editortitle.FontFace = uipallet.FontSemiBold
		editortitle.TextXAlignment = Enum.TextXAlignment.Left
		editortitle.TextTruncate = Enum.TextTruncate.AtEnd
		editortitle.Parent = editorside

		local searchbkg = Instance.new('Frame')
		searchbkg.Name = 'Search'
		searchbkg.Size = UDim2.fromOffset(173, 30)
		searchbkg.Position = UDim2.fromOffset(26, 59)
		searchbkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.015)
		searchbkg.BorderSizePixel = 0
		searchbkg.Parent = editorside
		addCorner(searchbkg)
		local searchstroke = Instance.new('UIStroke')
		searchstroke.Color = color.Light(uipallet.Main, 0.06)
		searchstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		searchstroke.Parent = searchbkg
		local searchicon = Instance.new('ImageLabel')
		searchicon.Name = 'Icon'
		searchicon.Size = UDim2.fromOffset(12, 12)
		searchicon.Position = UDim2.fromOffset(12, 9)
		searchicon.BackgroundTransparency = 1
		searchicon.Image = getcustomasset('catsix/assets/new/search.png')
		searchicon.ImageColor3 = Color3.fromRGB(122, 122, 122)
		searchicon.Parent = searchbkg
		local searchbox = Instance.new('TextBox')
		searchbox.Size = UDim2.new(1, -44, 1, 0)
		searchbox.Position = UDim2.fromOffset(33, 0)
		searchbox.BackgroundTransparency = 1
		searchbox.Text = ''
		searchbox.PlaceholderText = 'Search modules...'
		searchbox.PlaceholderColor3 = Color3.fromRGB(122, 122, 122)
		searchbox.TextColor3 = uipallet.Text
		searchbox.TextSize = 13
		searchbox.FontFace = uipallet.Font
		searchbox.TextXAlignment = Enum.TextXAlignment.Left
		searchbox.ClearTextOnFocus = false
		searchbox.Parent = searchbkg

		local filterbtn = Instance.new('TextButton')
		filterbtn.Name = 'Filter'
		filterbtn.Size = UDim2.fromOffset(27, 30)
		filterbtn.Position = UDim2.fromOffset(206, 59)
		filterbtn.BackgroundColor3 = searchbkg.BackgroundColor3
		filterbtn.AutoButtonColor = false
		filterbtn.Text = ''
		filterbtn.Parent = editorside
		addCorner(filterbtn)
		local filterstroke = searchstroke:Clone()
		filterstroke.Parent = filterbtn
		local filtericon = Instance.new('Frame')
		filtericon.Name = 'Icon'
		filtericon.Size = UDim2.fromOffset(12, 10)
		filtericon.AnchorPoint = Vector2.new(0.5, 0.5)
		filtericon.Position = UDim2.fromScale(0.5, 0.5)
		filtericon.BackgroundTransparency = 1
		filtericon.Parent = filterbtn
		local filterbars = {}
		for i, width in {12, 8, 4} do
			local bar = Instance.new('Frame')
			bar.Name = `Bar{i}`
			bar.Size = UDim2.fromOffset(width, 2)
			bar.AnchorPoint = Vector2.new(0.5, 0)
			bar.Position = UDim2.new(0.5, 0, 0, (i - 1) * 4)
			bar.BackgroundColor3 = Color3.fromRGB(171, 171, 171)
			bar.BorderSizePixel = 0
			bar.Parent = filtericon
			addCorner(bar, UDim.new(1, 0))
			table.insert(filterbars, bar)
		end

		local editorcount = Instance.new('TextLabel')
		editorcount.Name = 'Count'
		editorcount.Size = UDim2.fromOffset(160, 16)
		editorcount.Position = UDim2.fromOffset(26, 108)
		editorcount.BackgroundTransparency = 1
		editorcount.RichText = true
		editorcount.Text = ''
		editorcount.TextColor3 = Color3.fromRGB(134, 134, 134)
		editorcount.TextSize = 11
		editorcount.FontFace = uipallet.FontSemiBold
		editorcount.TextXAlignment = Enum.TextXAlignment.Left
		editorcount.Parent = editorside

		local resetall = Instance.new('TextButton')
		resetall.Name = 'ResetAll'
		resetall.Size = UDim2.fromOffset(70, 16)
		resetall.Position = UDim2.fromOffset(163, 108)
		resetall.BackgroundTransparency = 1
		resetall.AutoButtonColor = false
		resetall.Text = 'Reset all'
		resetall.TextColor3 = Color3.fromRGB(171, 171, 171)
		resetall.TextSize = 11
		resetall.FontFace = uipallet.Font
		resetall.TextXAlignment = Enum.TextXAlignment.Right
		resetall.Parent = editorside

		local editorlist = Instance.new('ScrollingFrame')
		editorlist.Name = 'Modules'
		editorlist.Size = UDim2.fromOffset(211, 248)
		editorlist.Position = UDim2.fromOffset(24, 129)
		editorlist.BackgroundTransparency = 1
		editorlist.BorderSizePixel = 0
		editorlist.ScrollBarThickness = 0
		editorlist.ScrollBarImageTransparency = 1
		editorlist.CanvasSize = UDim2.new()
		editorlist.Parent = editorside
		local editorlayout = Instance.new('UIListLayout')
		editorlayout.SortOrder = Enum.SortOrder.LayoutOrder
		editorlayout.Padding = UDim.new(0, 2)
		editorlayout.Parent = editorlist
		local editorpadding = Instance.new('UIPadding')
		editorpadding.PaddingTop = UDim.new(0, 2)
		editorpadding.PaddingLeft = UDim.new(0, 2)
		editorpadding.Parent = editorlist

		local moduletitle = Instance.new('TextLabel')
		moduletitle.Name = 'ModuleTitle'
		moduletitle.Size = UDim2.fromOffset(260, 26)
		moduletitle.Position = UDim2.fromOffset(260, 28)
		moduletitle.BackgroundTransparency = 1
		moduletitle.Text = ''
		moduletitle.TextColor3 = Color3.new(1, 1, 1)
		moduletitle.TextSize = 17
		moduletitle.FontFace = uipallet.FontSemiBold
		moduletitle.TextXAlignment = Enum.TextXAlignment.Left
		moduletitle.TextTruncate = Enum.TextTruncate.AtEnd
		moduletitle.Parent = editor

		local function addChip(parent, name, width)
			local chip = Instance.new('Frame')
			chip.Name = name
			chip.Size = UDim2.fromOffset(width, 17)
			chip.BackgroundColor3 = color.Light(uipallet.Main, 0.09)
			chip.BorderSizePixel = 0
			chip.Visible = false
			chip.Parent = parent
			addCorner(chip, UDim.new(0, 4))
			local text = Instance.new('TextLabel')
			text.Name = 'Text'
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.Text = ''
			text.TextColor3 = Color3.fromRGB(171, 171, 171)
			text.TextSize = 10
			text.FontFace = uipallet.FontSemiBold
			text.ZIndex = 2
			text.Parent = chip
			return chip, text
		end

		local function chipWidth(text)
			return math.max(getfontsize(text, 10, uipallet.FontSemiBold).X + 14, 22)
		end

		local statechip, statetext = addChip(editor, 'State', 28)
		local bindchip, bindtext = addChip(editor, 'Bind', 22)

		local resetmodule = Instance.new('TextButton')
		resetmodule.Name = 'ResetModule'
		resetmodule.Size = UDim2.fromOffset(112, 20)
		resetmodule.Position = UDim2.fromOffset(538, 31)
		resetmodule.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		resetmodule.AutoButtonColor = false
		resetmodule.Text = 'RESET THIS MODULE'
		resetmodule.TextColor3 = Color3.fromRGB(171, 171, 171)
		resetmodule.TextSize = 10
		resetmodule.FontFace = uipallet.FontSemiBold
		resetmodule.Visible = false
		resetmodule.Parent = editor
		addCorner(resetmodule, UDim.new(0, 4))

		local settingscaption = Instance.new('TextLabel')
		settingscaption.Name = 'Caption'
		settingscaption.Size = UDim2.fromOffset(200, 14)
		settingscaption.Position = UDim2.fromOffset(260, 61)
		settingscaption.BackgroundTransparency = 1
		settingscaption.Text = 'SETTINGS'
		settingscaption.TextColor3 = Color3.fromRGB(122, 122, 122)
		settingscaption.TextSize = 10
		settingscaption.FontFace = uipallet.FontSemiBold
		settingscaption.TextXAlignment = Enum.TextXAlignment.Left
		settingscaption.Visible = false
		settingscaption.Parent = editor

		local settingslist = Instance.new('ScrollingFrame')
		settingslist.Name = 'Settings'
		settingslist.Size = UDim2.fromOffset(390, 293)
		settingslist.Position = UDim2.fromOffset(260, 82)
		settingslist.BackgroundTransparency = 1
		settingslist.BorderSizePixel = 0
		settingslist.ScrollBarThickness = 0
		settingslist.ScrollBarImageTransparency = 1
		settingslist.CanvasSize = UDim2.new()
		settingslist.Parent = editor
		local settingslayout = Instance.new('UIListLayout')
		settingslayout.SortOrder = Enum.SortOrder.LayoutOrder
		settingslayout.Parent = settingslist

		local editorclose = addCloseButton(editor, 8)

		local targetsscrim = Instance.new('TextButton')
		targetsscrim.Name = 'TargetsScrim'
		targetsscrim.Size = UDim2.fromScale(1, 1)
		targetsscrim.BackgroundColor3 = Color3.new()
		targetsscrim.BackgroundTransparency = 0.45
		targetsscrim.AutoButtonColor = false
		targetsscrim.Text = ''
		targetsscrim.Visible = false
		targetsscrim.ZIndex = 8
		targetsscrim.Parent = editor
		addCorner(targetsscrim)

		local targetspanel = Instance.new('Frame')
		targetspanel.Name = 'TargetsPanel'
		targetspanel.Size = UDim2.fromOffset(220, 113)
		targetspanel.BackgroundColor3 = color.Light(uipallet.Main, 0.07)
		targetspanel.BorderSizePixel = 0
		targetspanel.Visible = false
		targetspanel.ZIndex = 9
		targetspanel.Parent = editor
		addCorner(targetspanel, UDim.new(0, 6))

		local function addResetButton(row, y, callback)
			local reset = Instance.new('TextButton')
			reset.Name = 'Reset'
			reset.Size = UDim2.fromOffset(18, 18)
			reset.Position = UDim2.fromOffset(368, y)
			reset.BackgroundTransparency = 1
			reset.AutoButtonColor = false
			reset.Text = ''
			reset.Parent = row
			local ring = Instance.new('Frame')
			ring.Name = 'Ring'
			ring.Size = UDim2.fromOffset(12, 12)
			ring.AnchorPoint = Vector2.new(0.5, 0.5)
			ring.Position = UDim2.fromScale(0.5, 0.5)
			ring.BackgroundTransparency = 1
			ring.Parent = reset
			addCorner(ring, UDim.new(1, 0))
			local ringstroke = Instance.new('UIStroke')
			ringstroke.Color = Color3.fromRGB(128, 128, 128)
			ringstroke.Thickness = 1.3
			ringstroke.Parent = ring
			local gap = Instance.new('Frame')
			gap.Name = 'Gap'
			gap.Size = UDim2.fromOffset(6, 5)
			gap.Position = UDim2.fromOffset(6, -2)
			gap.BackgroundColor3 = uipallet.Main
			gap.BorderSizePixel = 0
			gap.Parent = ring
			local head = Instance.new('ImageLabel')
			head.Name = 'Head'
			head.Size = UDim2.fromOffset(5, 6)
			head.Position = UDim2.fromOffset(7, -1)
			head.BackgroundTransparency = 1
			head.Image = getcustomasset('catsix/assets/new/range.png')
			head.ImageColor3 = ringstroke.Color
			head.Rotation = 180
			head.Parent = ring

			reset.MouseEnter:Connect(function()
				ringstroke.Color = Color3.new(1, 1, 1)
				head.ImageColor3 = ringstroke.Color
			end)
			reset.MouseLeave:Connect(function()
				ringstroke.Color = Color3.fromRGB(128, 128, 128)
				head.ImageColor3 = ringstroke.Color
			end)
			reset.MouseButton1Click:Connect(callback)

			return reset
		end

		local function addRowLabel(row, text, size, y, height)
			local label = Instance.new('TextLabel')
			label.Name = 'Label'
			label.Size = UDim2.fromOffset(240, height)
			label.Position = UDim2.fromOffset(0, y)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = color.Dark(uipallet.Text, 0.16)
			label.TextSize = size
			label.FontFace = uipallet.Font
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.Parent = row
			return label
		end

		local function addValueLabel(row, text, y)
			local label = Instance.new('TextLabel')
			label.Name = 'Value'
			label.Size = UDim2.fromOffset(160, 22)
			label.Position = UDim2.fromOffset(197, y)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = color.Dark(uipallet.Text, 0.16)
			label.TextSize = 12
			label.FontFace = uipallet.Font
			label.TextXAlignment = Enum.TextXAlignment.Right
			label.Parent = row
			return label
		end

		local function addTogglePill(parent, x, y, enabled)
			local pill = Instance.new('TextButton')
			pill.Name = 'Toggle'
			pill.Size = UDim2.fromOffset(25, 13)
			pill.Position = UDim2.fromOffset(x, y)
			pill.BackgroundColor3 = enabled and accentColor() or color.Light(uipallet.Main, 0.14)
			pill.AutoButtonColor = false
			pill.Text = ''
			pill.Parent = parent
			addCorner(pill, UDim.new(1, 0))
			local knob = Instance.new('Frame')
			knob.Name = 'Knob'
			knob.Size = UDim2.fromOffset(9, 9)
			knob.Position = UDim2.fromOffset(enabled and 14 or 2, 2)
			knob.BackgroundColor3 = enabled and accentTextColor() or Color3.new(1, 1, 1)
			knob.BorderSizePixel = 0
			knob.Parent = pill
			addCorner(knob, UDim.new(1, 0))
			return pill, knob
		end

		local function trackRatio(ratio)
			return math.clamp(ratio, 0.04, 0.96)
		end

		local function addSliderTrack(row, y)
			local track = Instance.new('Frame')
			track.Name = 'Track'
			track.Size = UDim2.fromOffset(357, 3)
			track.Position = UDim2.fromOffset(0, y)
			track.BackgroundColor3 = color.Light(uipallet.Main, 0.09)
			track.BorderSizePixel = 0
			track.Parent = row
			addCorner(track, UDim.new(1, 0))
			local fill = Instance.new('Frame')
			fill.Name = 'Fill'
			fill.BackgroundColor3 = accentColor()
			fill.BorderSizePixel = 0
			fill.Parent = track
			addCorner(fill, UDim.new(1, 0))
			return track, fill
		end

		local function addDragInput(row, track, callback)
			row.InputBegan:Connect(function(inputObj)
				if
					(inputObj.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObj.UserInputType ~= Enum.UserInputType.Touch)
					or (inputObj.Position.Y - row.AbsolutePosition.Y) < (26 * scale.Scale)
				then
					return
				end

				callback(math.clamp((inputObj.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1), true)
				local changed = inputService.InputChanged:Connect(function(input)
					if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
						callback(math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1), false)
					end
				end)

				local ended
				ended = inputObj.Changed:Connect(function()
					if inputObj.UserInputState == Enum.UserInputState.End then
						changed:Disconnect()
						ended:Disconnect()
						callback(nil, false, true)
					end
				end)
			end)
		end

		local function getOptions(mod)
			local order = mod.Children and mod.Children:GetChildren() or {}
			local list = {}
			for name, opt in pairs(mod.Options) do
				table.insert(list, {
					Name = tostring(name),
					Option = opt,
					Order = table.find(order, opt.Object) or 1000
				})
			end
			table.sort(list, function(a, b)
				return a.Order < b.Order
			end)
			return list
		end

		local function sameList(list, other)
			if #list ~= #other then return false end
			for _, v in list do
				if not table.find(other, v) then return false end
			end
			return true
		end

		local function isDefault(opt)
			if opt.Type == 'Toggle' then
				return opt.Enabled == opt.Default
			elseif opt.Type == 'Slider' then
				return opt.Value == opt.Default
			elseif opt.Type == 'TwoSlider' then
				return opt.ValueMin == opt.DefaultMin and opt.ValueMax == opt.DefaultMax
			elseif opt.Type == 'Dropdown' or opt.Type == 'TextBox' then
				return opt.Value == opt.Default
			elseif opt.Type == 'TextList' then
				return sameList(opt.List, opt.Default) and sameList(opt.ListEnabled, opt.Default)
			elseif opt.Type == 'Targets' then
				return opt.Players.Enabled == opt.Default.Players
					and opt.NPCs.Enabled == opt.Default.NPCs
					and opt.Invisible.Enabled == opt.Default.Invisible
					and opt.Walls.Enabled == opt.Default.Walls
			end
			return true
		end

		local function resetOption(opt)
			if opt.Type == 'Toggle' then
				if opt.Enabled ~= opt.Default then
					opt:Toggle()
				end
			elseif opt.Type == 'Slider' then
				opt:SetValue(opt.Default, nil, true)
			elseif opt.Type == 'TwoSlider' then
				opt:SetValue(false, opt.DefaultMin)
				opt:SetValue(true, opt.DefaultMax)
			elseif opt.Type == 'Dropdown' then
				opt:SetValue(opt.Default, true)
			elseif opt.Type == 'TextBox' then
				opt:SetValue(opt.Default or '')
			elseif opt.Type == 'TextList' then
				opt:Load({List = table.clone(opt.Default), ListEnabled = table.clone(opt.Default)})
			elseif opt.Type == 'Targets' then
				opt:Load(opt.Default)
			end
			mainapi:QueueSave()
		end

		local selectedmodule
		local selectedname
		local expandedoption
		local refreshEditor
		local refreshSettings

		local function addToggleRow(entry, order, listicon)
			local opt = entry.Option
			local row = Instance.new('Frame')
			row.Name = entry.Name
			row.Size = UDim2.new(1, 0, 0, 30)
			row.BackgroundTransparency = 1
			row.LayoutOrder = order
			row.Parent = settingslist
			addRowLabel(row, entry.Name, 13, 0, 30)

			if listicon then
				local icon = Instance.new('ImageLabel')
				icon.Name = 'ListIcon'
				icon.Size = UDim2.fromOffset(14, 12)
				icon.Position = UDim2.fromOffset(315, 9)
				icon.BackgroundTransparency = 1
				icon.Image = listicon
				icon.Parent = row
			end

			local pill, knob = addTogglePill(row, 332, 9, opt.Enabled)
			if not isDefault(opt) then
				addResetButton(row, 6, function()
					resetOption(opt)
					refreshSettings()
				end)
			end

			pill.MouseButton1Click:Connect(function()
				opt:Toggle()
				mainapi:QueueSave()
				tween:Tween(pill, uipallet.Tween, {BackgroundColor3 = opt.Enabled and accentColor() or color.Light(uipallet.Main, 0.14)})
				tween:Tween(knob, uipallet.Tween, {
					Position = UDim2.fromOffset(opt.Enabled and 14 or 2, 2),
					BackgroundColor3 = opt.Enabled and accentTextColor() or Color3.new(1, 1, 1)
				})
				refreshSettings()
			end)
		end

		local function addSliderRow(entry, order)
			local opt = entry.Option
			local row = Instance.new('TextButton')
			row.Name = entry.Name
			row.Size = UDim2.new(1, 0, 0, 50)
			row.BackgroundTransparency = 1
			row.AutoButtonColor = false
			row.Text = ''
			row.LayoutOrder = order
			row.Parent = settingslist
			addRowLabel(row, entry.Name, 12, 4, 22)

			local function formatValue()
				local suffix = type(opt.Suffix) == 'function' and opt.Suffix(opt.Value) or opt.Suffix
				return suffix and `{opt.Value} {suffix}` or tostring(opt.Value)
			end

			local value = addValueLabel(row, formatValue(), 4)
			local range = math.max(opt.Max - opt.Min, 1e-6)
			local track, fill = addSliderTrack(row, 36)
			fill.Size = UDim2.fromScale(trackRatio((opt.Value - opt.Min) / range), 1)
			local knob = Instance.new('Frame')
			knob.Name = 'Knob'
			knob.Size = UDim2.fromOffset(13, 13)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.Position = UDim2.fromScale(1, 0.5)
			knob.BackgroundColor3 = accentColor()
			knob.BorderSizePixel = 0
			knob.ZIndex = 2
			knob.Parent = fill
			addCorner(knob, UDim.new(1, 0))

			local hadreset = not isDefault(opt)
			if hadreset then
				addResetButton(row, 12, function()
					resetOption(opt)
					refreshSettings()
				end)
			end

			row.MouseEnter:Connect(function()
				tween:Tween(knob, uipallet.Tween, {Size = UDim2.fromOffset(15, 15)})
			end)
			row.MouseLeave:Connect(function()
				tween:Tween(knob, uipallet.Tween, {Size = UDim2.fromOffset(13, 13)})
			end)

			addDragInput(row, track, function(pos, _, final)
				if final then
					opt:SetValue(opt.Value, nil, true)
					mainapi:QueueSave()
					if hadreset == isDefault(opt) then
						refreshSettings()
					end
					return
				end
				opt:SetValue(math.floor((opt.Min + range * pos) * opt.Decimal) / opt.Decimal, pos)
				value.Text = formatValue()
				tween:Tween(fill, uipallet.Tween, {Size = UDim2.fromScale(trackRatio(pos), 1)})
			end)
		end

		local function addTwoSliderRow(entry, order)
			local opt = entry.Option
			local row = Instance.new('TextButton')
			row.Name = entry.Name
			row.Size = UDim2.new(1, 0, 0, 50)
			row.BackgroundTransparency = 1
			row.AutoButtonColor = false
			row.Text = ''
			row.LayoutOrder = order
			row.Parent = settingslist
			addRowLabel(row, entry.Name, 12, 4, 22)

			local maxwidth = getfontsize(tostring(opt.ValueMax), 12, uipallet.Font).X
			local maxvalue = addValueLabel(row, opt.ValueMax, 4)
			local arrow = Instance.new('ImageLabel')
			arrow.Name = 'Arrow'
			arrow.Size = UDim2.fromOffset(12, 6)
			arrow.Position = UDim2.fromOffset(339 - maxwidth, 12)
			arrow.BackgroundTransparency = 1
			arrow.Image = getcustomasset('catsix/assets/new/rangearrow.png')
			arrow.ImageColor3 = color.Light(uipallet.Main, 0.2)
			arrow.Parent = row
			local minvalue = addValueLabel(row, opt.ValueMin, 4)
			minvalue.Position = UDim2.fromOffset(161 - maxwidth, 4)

			local range = math.max(opt.Max - opt.Min, 1e-6)
			local minratio = trackRatio((opt.ValueMin - opt.Min) / range)
			local maxratio = trackRatio((opt.ValueMax - opt.Min) / range)
			local track, fill = addSliderTrack(row, 36)
			fill.Position = UDim2.fromScale(minratio, 0)
			fill.Size = UDim2.fromScale(math.max(maxratio - minratio, 0), 1)

			local function addKnob(name, edge, flipped)
				local knob = Instance.new('ImageLabel')
				knob.Name = name
				knob.Size = UDim2.fromOffset(9, 16)
				knob.AnchorPoint = Vector2.new(0.5, 0.5)
				knob.Position = UDim2.fromScale(edge, 0.5)
				knob.BackgroundTransparency = 1
				knob.Image = getcustomasset('catsix/assets/new/range.png')
				knob.ImageColor3 = accentColor()
				knob.Rotation = flipped and 180 or 0
				knob.ZIndex = 2
				knob.Parent = fill

				knob.MouseEnter:Connect(function()
					tween:Tween(knob, uipallet.Tween, {Size = UDim2.fromOffset(11, 18)})
				end)
				knob.MouseLeave:Connect(function()
					tween:Tween(knob, uipallet.Tween, {Size = UDim2.fromOffset(9, 16)})
				end)

				return knob
			end

			addKnob('KnobMin', 0, false)
			addKnob('KnobMax', 1, true)

			local hadreset = not isDefault(opt)
			if hadreset then
				addResetButton(row, 12, function()
					resetOption(opt)
					refreshSettings()
				end)
			end

			local editingmax = false
			addDragInput(row, track, function(pos, began, final)
				if final then
					mainapi:QueueSave()
					if hadreset == isDefault(opt) then
						refreshSettings()
					end
					return
				end
				if began then
					editingmax = math.abs(pos - maxratio) <= math.abs(pos - minratio)
				end
				opt:SetValue(editingmax, math.floor((opt.Min + range * pos) * opt.Decimal) / opt.Decimal)
				minratio = trackRatio((opt.ValueMin - opt.Min) / range)
				maxratio = trackRatio((opt.ValueMax - opt.Min) / range)
				minvalue.Text = opt.ValueMin
				maxvalue.Text = opt.ValueMax
				tween:Tween(fill, uipallet.Tween, {
					Position = UDim2.fromScale(minratio, 0),
					Size = UDim2.fromScale(math.max(maxratio - minratio, 0), 1)
				})
			end)
		end

		local function addDropdownRow(entry, order, expanded)
			local opt = entry.Option
			local options = opt.List or {}
			local row = Instance.new('Frame')
			row.Name = entry.Name
			row.Size = UDim2.new(1, 0, 0, expanded and 40 + (#options * 26) or 40)
			row.BackgroundTransparency = 1
			row.LayoutOrder = order
			row.Parent = settingslist

			local bkg = Instance.new('Frame')
			bkg.Name = 'BKG'
			bkg.Size = UDim2.new(0, 357, 1, -9)
			bkg.Position = UDim2.fromOffset(0, 4)
			bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
			bkg.BorderSizePixel = 0
			bkg.Parent = row
			addCorner(bkg, UDim.new(0, 6))
			local button = Instance.new('TextButton')
			button.Name = 'Dropdown'
			button.Size = UDim2.new(1, -2, 1, -2)
			button.Position = UDim2.fromOffset(1, 1)
			button.BackgroundColor3 = uipallet.Main
			button.AutoButtonColor = false
			button.Text = ''
			button.Parent = bkg
			addCorner(button, UDim.new(0, 6))
			local title = Instance.new('TextLabel')
			title.Name = 'Title'
			title.Size = UDim2.new(1, -44, 0, 29)
			title.Position = UDim2.fromOffset(14, 0)
			title.BackgroundTransparency = 1
			title.Text = `{entry.Name} - {opt.Value}`
			title.TextColor3 = color.Dark(uipallet.Text, 0.16)
			title.TextSize = 13
			title.FontFace = uipallet.Font
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextTruncate = Enum.TextTruncate.AtEnd
			title.Parent = button
			local arrow = Instance.new('ImageLabel')
			arrow.Name = 'Arrow'
			arrow.Size = UDim2.fromOffset(4, 8)
			arrow.Position = UDim2.new(1, -17, 0, 11)
			arrow.BackgroundTransparency = 1
			arrow.Image = getcustomasset('catsix/assets/new/expandright.png')
			arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
			arrow.Rotation = expanded and 270 or 90
			arrow.Parent = button

			row.MouseEnter:Connect(function()
				tween:Tween(bkg, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.0875)})
			end)
			row.MouseLeave:Connect(function()
				tween:Tween(bkg, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.034)})
			end)

			if not isDefault(opt) then
				addResetButton(row, 11, function()
					resetOption(opt)
					refreshSettings()
				end)
			end

			button.MouseButton1Click:Connect(function()
				expandedoption = not expanded and entry.Name or nil
				refreshSettings()
			end)

			if not expanded then return end

			for i, v in options do
				local choice = Instance.new('TextButton')
				choice.Name = v
				choice.Size = UDim2.new(1, 0, 0, 26)
				choice.Position = UDim2.fromOffset(0, 29 + ((i - 1) * 26))
				choice.BackgroundColor3 = uipallet.Main
				choice.BorderSizePixel = 0
				choice.AutoButtonColor = false
				choice.Text = ''
				choice.Parent = button
				local choicetext = Instance.new('TextLabel')
				choicetext.Name = 'Text'
				choicetext.Size = UDim2.new(1, -28, 1, 0)
				choicetext.Position = UDim2.fromOffset(14, 0)
				choicetext.BackgroundTransparency = 1
				choicetext.Text = v
				choicetext.TextColor3 = v == opt.Value and Color3.new(1, 1, 1) or color.Dark(uipallet.Text, 0.16)
				choicetext.TextSize = 13
				choicetext.FontFace = uipallet.Font
				choicetext.TextXAlignment = Enum.TextXAlignment.Left
				choicetext.TextTruncate = Enum.TextTruncate.AtEnd
				choicetext.Parent = choice

				choice.MouseEnter:Connect(function()
					tween:Tween(choice, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.04)})
				end)
				choice.MouseLeave:Connect(function()
					tween:Tween(choice, uipallet.Tween, {BackgroundColor3 = uipallet.Main})
				end)
				choice.MouseButton1Click:Connect(function()
					opt:SetValue(v, true)
					mainapi:QueueSave()
					expandedoption = nil
					refreshSettings()
				end)
			end
		end

		local function showTargets(opt, rowy)
			for _, old in targetspanel:GetChildren() do
				if not old:IsA('UICorner') then
					old:Destroy()
				end
			end

			local function addTargetTab(name, toggle, asset, size, x)
				local tab = Instance.new('TextButton')
				tab.Name = name
				tab.Size = UDim2.fromOffset(61, 28)
				tab.Position = UDim2.fromOffset(x, 12)
				tab.BackgroundColor3 = toggle.Enabled and accentColor() or color.Light(uipallet.Main, 0.12)
				tab.AutoButtonColor = false
				tab.Text = ''
				tab.ZIndex = 10
				tab.Parent = targetspanel
				addCorner(tab, UDim.new(0, 5))
				local icon = Instance.new('ImageLabel')
				icon.Name = 'Icon'
				icon.Size = size
				icon.AnchorPoint = Vector2.new(0.5, 0.5)
				icon.Position = UDim2.fromScale(0.5, 0.5)
				icon.BackgroundTransparency = 1
				icon.Image = getcustomasset(asset)
				icon.ImageColor3 = toggle.Enabled and accentTextColor() or Color3.fromRGB(171, 171, 171)
				icon.ZIndex = 11
				icon.Parent = tab

				tab.MouseButton1Click:Connect(function()
					toggle:Toggle()
					mainapi:QueueSave()
					refreshSettings()
				end)
			end

			addTargetTab('Players', opt.Players, 'catsix/assets/new/targetplayers1.png', UDim2.fromOffset(15, 16), 12)
			addTargetTab('NPCs', opt.NPCs, 'catsix/assets/new/targetnpc1.png', UDim2.fromOffset(12, 16), 79)

			local function addTargetToggle(name, toggle, y)
				local label = Instance.new('TextLabel')
				label.Name = name
				label.Size = UDim2.new(1, -70, 0, 22)
				label.Position = UDim2.fromOffset(14, y)
				label.BackgroundTransparency = 1
				label.Text = name
				label.TextColor3 = color.Dark(uipallet.Text, 0.16)
				label.TextSize = 13
				label.FontFace = uipallet.Font
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.ZIndex = 10
				label.Parent = targetspanel

				local pill, knob = addTogglePill(targetspanel, 181, y + 4, toggle.Enabled)
				pill.ZIndex = 10
				knob.ZIndex = 11
				pill.MouseButton1Click:Connect(function()
					toggle:Toggle()
					mainapi:QueueSave()
					refreshSettings()
				end)
			end

			addTargetToggle('Ignore invisible', opt.Invisible, 52)
			addTargetToggle('Ignore behind walls', opt.Walls, 84)

			targetspanel.Position = UDim2.fromOffset(332, 134 + rowy - settingslist.CanvasPosition.Y)
			targetspanel.Visible = true
			targetsscrim.Visible = true
		end

		local function addTargetsRow(entry, order, rowy, expanded)
			local opt = entry.Option
			local row = Instance.new('Frame')
			row.Name = entry.Name
			row.Size = UDim2.new(1, 0, 0, 50)
			row.BackgroundTransparency = 1
			row.LayoutOrder = order
			row.Parent = settingslist

			local bkg = Instance.new('Frame')
			bkg.Name = 'BKG'
			bkg.Size = UDim2.fromOffset(357, 32)
			bkg.Position = UDim2.fromOffset(0, 9)
			bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.06)
			bkg.BorderSizePixel = 0
			bkg.Parent = row
			addCorner(bkg, UDim.new(0, 6))
			local inner = Instance.new('Frame')
			inner.Name = 'Inner'
			inner.Size = UDim2.new(1, -2, 1, -2)
			inner.Position = UDim2.fromOffset(1, 1)
			inner.BackgroundColor3 = uipallet.Main
			inner.BorderSizePixel = 0
			inner.Parent = bkg
			addCorner(inner, UDim.new(0, 6))

			local tag = Instance.new('Frame')
			tag.Name = 'Tag'
			tag.Size = UDim2.fromOffset(81, 30)
			tag.BackgroundColor3 = color.Light(uipallet.Main, 0.055)
			tag.BorderSizePixel = 0
			tag.Parent = inner
			addCorner(tag, UDim.new(0, 6))
			local tagicon = Instance.new('ImageLabel')
			tagicon.Name = 'Icon'
			tagicon.Size = UDim2.fromOffset(15, 12)
			tagicon.Position = UDim2.fromOffset(14, 9)
			tagicon.BackgroundTransparency = 1
			tagicon.Image = getcustomasset('catsix/assets/new/targetstab.png')
			tagicon.ImageColor3 = Color3.fromRGB(171, 171, 171)
			tagicon.Parent = tag
			local tagtext = Instance.new('TextLabel')
			tagtext.Name = 'Text'
			tagtext.Size = UDim2.new(1, -36, 1, 0)
			tagtext.Position = UDim2.fromOffset(36, 0)
			tagtext.BackgroundTransparency = 1
			tagtext.Text = entry.Name
			tagtext.TextColor3 = color.Dark(uipallet.Text, 0.16)
			tagtext.TextSize = 13
			tagtext.FontFace = uipallet.Font
			tagtext.TextXAlignment = Enum.TextXAlignment.Left
			tagtext.Parent = tag

			local targets = {}
			if opt.Players.Enabled then table.insert(targets, 'Players') end
			if opt.NPCs.Enabled then table.insert(targets, 'NPCs') end
			local valuetext = Instance.new('TextLabel')
			valuetext.Name = 'Value'
			valuetext.Size = UDim2.new(1, -150, 1, 0)
			valuetext.Position = UDim2.fromOffset(95, 0)
			valuetext.BackgroundTransparency = 1
			valuetext.Text = #targets > 0 and table.concat(targets, ', ') or 'None'
			valuetext.TextColor3 = color.Dark(uipallet.Text, 0.16)
			valuetext.TextSize = 13
			valuetext.FontFace = uipallet.Font
			valuetext.TextXAlignment = Enum.TextXAlignment.Left
			valuetext.TextTruncate = Enum.TextTruncate.AtEnd
			valuetext.Parent = inner

			local edit = Instance.new('TextButton')
			edit.Name = 'Edit'
			edit.Size = UDim2.fromOffset(40, 32)
			edit.Position = UDim2.new(1, -50, 0, 0)
			edit.BackgroundTransparency = 1
			edit.AutoButtonColor = false
			edit.Text = 'edit'
			edit.TextColor3 = Color3.fromRGB(171, 171, 171)
			edit.TextSize = 12
			edit.FontFace = uipallet.Font
			edit.TextXAlignment = Enum.TextXAlignment.Right
			edit.Parent = inner

			if not isDefault(opt) then
				addResetButton(row, 16, function()
					resetOption(opt)
					refreshSettings()
				end)
			end

			edit.MouseButton1Click:Connect(function()
				expandedoption = not expanded and entry.Name or nil
				refreshSettings()
			end)

			if expanded then
				showTargets(opt, rowy)
			end
		end

		local function addTextListRow(entry, order)
			local opt = entry.Option
			local row = Instance.new('Frame')
			row.Name = entry.Name
			row.Size = UDim2.new(1, 0, 0, 48)
			row.BackgroundTransparency = 1
			row.LayoutOrder = order
			row.Parent = settingslist

			local card = Instance.new('Frame')
			card.Name = 'Card'
			card.Size = UDim2.fromOffset(331, 40)
			card.Position = UDim2.fromOffset(26, 2)
			card.BackgroundColor3 = color.Light(uipallet.Main, 0.045)
			card.BorderSizePixel = 0
			card.Parent = row
			addCorner(card, UDim.new(0, 6))
			local icon = Instance.new('ImageLabel')
			icon.Name = 'Icon'
			icon.Size = UDim2.fromOffset(14, 12)
			icon.Position = UDim2.fromOffset(14, 14)
			icon.BackgroundTransparency = 1
			icon.Image = opt.Icon or getcustomasset('catsix/assets/new/allowedicon.png')
			icon.Parent = card
			local title = Instance.new('TextLabel')
			title.Name = 'Title'
			title.Size = UDim2.new(1, -80, 0, 16)
			title.Position = UDim2.fromOffset(38, 6)
			title.BackgroundTransparency = 1
			title.Text = entry.Name
			title.TextColor3 = color.Dark(uipallet.Text, 0.16)
			title.TextSize = 13
			title.FontFace = uipallet.Font
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextTruncate = Enum.TextTruncate.AtEnd
			title.Parent = card
			local items = Instance.new('TextLabel')
			items.Name = 'Items'
			items.Size = UDim2.new(1, -80, 0, 14)
			items.Position = UDim2.fromOffset(38, 21)
			items.BackgroundTransparency = 1
			items.Text = #opt.ListEnabled > 0 and table.concat(opt.ListEnabled, ', ') or 'None'
			items.TextColor3 = color.Dark(uipallet.Text, 0.43)
			items.TextSize = 11
			items.FontFace = uipallet.Font
			items.TextXAlignment = Enum.TextXAlignment.Left
			items.TextTruncate = Enum.TextTruncate.AtEnd
			items.Parent = card
			local amount = Instance.new('TextLabel')
			amount.Name = 'Amount'
			amount.Size = UDim2.new(1, -20, 1, 0)
			amount.BackgroundTransparency = 1
			amount.Text = #opt.List
			amount.TextColor3 = color.Dark(uipallet.Text, 0.16)
			amount.TextSize = 13
			amount.FontFace = uipallet.Font
			amount.TextXAlignment = Enum.TextXAlignment.Right
			amount.Parent = card

			if not isDefault(opt) then
				addResetButton(row, 13, function()
					resetOption(opt)
					refreshSettings()
				end)
			end
		end

		local function addColorRow(entry, order)
			local opt = entry.Option
			local row = Instance.new('Frame')
			row.Name = entry.Name
			row.Size = UDim2.new(1, 0, 0, 30)
			row.BackgroundTransparency = 1
			row.LayoutOrder = order
			row.Parent = settingslist
			addRowLabel(row, entry.Name, 13, 0, 30)

			local swatch = Instance.new('Frame')
			swatch.Name = 'Color'
			swatch.Size = UDim2.fromOffset(26, 14)
			swatch.Position = UDim2.fromOffset(332, 9)
			swatch.BackgroundColor3 = Color3.fromHSV(opt.Hue, opt.Sat, opt.Value)
			swatch.BorderSizePixel = 0
			swatch.Parent = row
			addCorner(swatch, UDim.new(0, 4))
		end

		local function addValueRow(entry, order, text)
			local row = Instance.new('Frame')
			row.Name = entry.Name
			row.Size = UDim2.new(1, 0, 0, 30)
			row.BackgroundTransparency = 1
			row.LayoutOrder = order
			row.Parent = settingslist
			addRowLabel(row, entry.Name, 13, 0, 30)
			local value = addValueLabel(row, text, 4)
			value.TextColor3 = color.Dark(uipallet.Text, 0.43)
		end

		function refreshSettings()
			for _, old in settingslist:GetChildren() do
				if not old:IsA('UIListLayout') then
					old:Destroy()
				end
			end
			targetsscrim.Visible = false
			targetspanel.Visible = false

			local mod = selectedmodule
			settingscaption.Visible = mod ~= nil
			resetmodule.Visible = mod ~= nil
			moduletitle.Text = mod and selectedname or ''
			statechip.Visible = mod ~= nil
			bindchip.Visible = mod ~= nil and mod.Bind[1] ~= nil

			if not mod then
				settingslist.CanvasSize = UDim2.new()
				return
			end

			local namewidth = getfontsize(selectedname, 17, uipallet.FontSemiBold).X
			statetext.Text = mod.Enabled and 'ON' or 'OFF'
			statechip.Size = UDim2.fromOffset(chipWidth(statetext.Text), 18)
			statechip.Position = UDim2.fromOffset(272 + namewidth, 32)
			statechip.BackgroundColor3 = mod.Enabled and accentColor() or color.Light(uipallet.Main, 0.09)
			statetext.TextColor3 = mod.Enabled and accentTextColor() or Color3.fromRGB(171, 171, 171)

			bindtext.Text = mod.Bind[1] and tostring(mod.Bind[1]):upper() or ''
			bindchip.Size = UDim2.fromOffset(chipWidth(bindtext.Text), 18)
			bindchip.Position = UDim2.fromOffset(278 + namewidth + statechip.Size.X.Offset, 32)

			local options = getOptions(mod)
			local y = 0
			for i, entry in options do
				local following = options[i + 1]
				local opt = entry.Option
				if opt.Type == 'Toggle' then
					local sublist = following and following.Option.Type == 'TextList'
					addToggleRow(entry, i, sublist and (following.Option.Icon or getcustomasset('catsix/assets/new/allowedicon.png')) or nil)
					y += 30
				elseif opt.Type == 'Slider' then
					addSliderRow(entry, i)
					y += 50
				elseif opt.Type == 'TwoSlider' then
					addTwoSliderRow(entry, i)
					y += 50
				elseif opt.Type == 'Dropdown' then
					local expanded = expandedoption == entry.Name
					addDropdownRow(entry, i, expanded)
					y += expanded and 40 + (#(opt.List or {}) * 26) or 40
				elseif opt.Type == 'Targets' then
					addTargetsRow(entry, i, y, expandedoption == entry.Name)
					y += 50
				elseif opt.Type == 'TextList' then
					addTextListRow(entry, i)
					y += 48
				elseif opt.Type == 'ColorSlider' then
					addColorRow(entry, i)
					y += 30
				elseif opt.Type == 'TextBox' then
					addValueRow(entry, i, tostring(opt.Value))
					y += 30
				end
			end

			settingslist.CanvasSize = UDim2.fromOffset(0, y)
		end

		local function addEditorRow(entry, order, selected)
			local row = Instance.new('TextButton')
			row.Name = entry.Name
			row.Size = UDim2.new(1, -4, 0, 34)
			row.BackgroundColor3 = color.Light(uipallet.Main, 0.06)
			row.BackgroundTransparency = selected and 0 or 1
			row.AutoButtonColor = false
			row.Text = ''
			row.LayoutOrder = order
			row.Parent = editorlist
			addCorner(row)
			local stroke = Instance.new('UIStroke')
			stroke.Color = color.Light(uipallet.Main, 0.13)
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Enabled = selected
			stroke.Parent = row
			local label = Instance.new('TextLabel')
			label.Name = 'Label'
			label.Size = UDim2.new(1, -58, 1, 0)
			label.Position = UDim2.fromOffset(10, 0)
			label.BackgroundTransparency = 1
			label.Text = entry.Name
			label.TextColor3 = selected and Color3.new(1, 1, 1) or Color3.fromRGB(171, 171, 171)
			label.TextSize = 13
			label.FontFace = uipallet.Font
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.Parent = row
			local chevron = Instance.new('ImageLabel')
			chevron.Name = 'Chevron'
			chevron.Size = UDim2.fromOffset(5, 9)
			chevron.AnchorPoint = Vector2.new(1, 0.5)
			chevron.Position = UDim2.new(1, -12, 0.5, 0)
			chevron.BackgroundTransparency = 1
			chevron.Image = getcustomasset('catsix/assets/new/expandright.png')
			chevron.ImageColor3 = Color3.fromRGB(122, 122, 122)
			chevron.Parent = row

			local bindname = entry.Module.Bind[1] and tostring(entry.Module.Bind[1]):upper() or ''
			if entry.Module.Enabled or bindname ~= '' then
				local chip, chiptext = addChip(row, 'Chip', 22)
				chiptext.Text = entry.Module.Enabled and 'ON' or bindname
				chip.Size = UDim2.fromOffset(chipWidth(chiptext.Text), 18)
				chip.AnchorPoint = Vector2.new(1, 0.5)
				chip.Position = UDim2.new(1, -28, 0.5, 0)
				chip.Visible = true
				if entry.Module.Enabled then
					chip.BackgroundColor3 = accentColor()
					chiptext.TextColor3 = accentTextColor()
				end
			end

			row.MouseEnter:Connect(function()
				if not selected then
					tween:Tween(row, uipallet.Tween, {BackgroundTransparency = 0.55})
				end
			end)
			row.MouseLeave:Connect(function()
				if not selected then
					tween:Tween(row, uipallet.Tween, {BackgroundTransparency = 1})
				end
			end)
			row.MouseButton1Click:Connect(function()
				selectedname = entry.Name
				selectedmodule = entry.Module
				expandedoption = nil
				refreshEditor()
			end)
		end

		local affectedonly = false

		local function getModules()
			return listModules(searchbox.Text:lower(), affectedonly)
		end

		function refreshEditor()
			for _, old in editorlist:GetChildren() do
				if old:IsA('TextButton') then
					old:Destroy()
				end
			end

			local active = getModules()
			editorcount.Text = `<font color="rgb(255,255,255)">{#listModules('', true)}</font> AFFECTED MODULES`

			if selectedname and not mainapi.Modules[selectedname] then
				selectedname = nil
				selectedmodule = nil
			end

			for i, entry in active do
				addEditorRow(entry, i, entry.Name == selectedname)
			end

			editorlist.CanvasSize = UDim2.fromOffset(0, (#active * 36) + 4)
			refreshSettings()
		end

		function openEditor(target)
			editortitle.Text = mainapi.Profile or 'Profile'
			searchbox.Text = ''
			expandedoption = nil

			local active = getModules()
			selectedname = typeof(target) == 'string' and target or (active[1] and active[1].Name)
			selectedmodule = selectedname and mainapi.Modules[selectedname]

			refreshEditor()
			editor.Position = UDim2.new(0.5, -337, 0.5, -193)
			editor.Visible = true
		end

		searchbox:GetPropertyChangedSignal('Text'):Connect(refreshEditor)

		targetsscrim.MouseButton1Click:Connect(function()
			expandedoption = nil
			refreshSettings()
		end)

		filterbtn.MouseButton1Click:Connect(function()
			affectedonly = not affectedonly
			for _, bar in filterbars do
				bar.BackgroundColor3 = affectedonly and accentColor() or Color3.fromRGB(171, 171, 171)
			end
			refreshEditor()
		end)

		resetmodule.MouseEnter:Connect(function()
			tween:Tween(resetmodule, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.075)})
		end)
		resetmodule.MouseLeave:Connect(function()
			tween:Tween(resetmodule, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.034)})
		end)
		resetmodule.MouseButton1Click:Connect(function()
			if selectedmodule then
				for _, entry in getOptions(selectedmodule) do
					resetOption(entry.Option)
				end
				expandedoption = nil
				refreshSettings()
			end
		end)

		resetall.MouseEnter:Connect(function()
			resetall.TextColor3 = Color3.new(1, 1, 1)
		end)
		resetall.MouseLeave:Connect(function()
			resetall.TextColor3 = Color3.fromRGB(171, 171, 171)
		end)
		resetall.MouseButton1Click:Connect(function()
			for _, entry in listModules('', true) do
				for _, option in getOptions(entry.Module) do
					resetOption(option.Option)
				end
			end
			expandedoption = nil
			refreshEditor()
		end)

		editall.MouseButton1Click:Connect(function()
			openEditor()
		end)
		editorclose.MouseButton1Click:Connect(function()
			editor.Visible = false
		end)

		createbkg.MouseButton1Click:Connect(function()
			refreshModules()
			namebox.Text = ''
			newprofile.Visible = true
			namebox:CaptureFocus()
		end)

		back.MouseButton1Click:Connect(function()
			newprofile.Visible = false
		end)

		nameadd.MouseButton1Click:Connect(function()
			if namebox.Text == '' then return end
			categoryapi:ChangeValue(namebox.Text)
			namebox.Text = ''
			newprofile.Visible = false
		end)

		local publicbkg = Instance.new('TextButton')
		publicbkg.Name = 'Public'
		publicbkg.Size = UDim2.new(0.47, -4, 1, 0)
		publicbkg.LayoutOrder = 2
		publicbkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		publicbkg.AutoButtonColor = true
		publicbkg.Text = ''
		publicbkg.Parent = addrow
		addCorner(publicbkg)
		local publicstroke = Instance.new('UIStroke')
		publicstroke.Color = color.Light(uipallet.Main, 0.02)
		publicstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		publicstroke.Parent = publicbkg
		addRowButtonContent(publicbkg, 'catsix/assets/new/profileworld.png', 'PUBLIC', 14)

		publicbkg.MouseButton1Click:Connect(function()
			local public = mainapi.PublicProfiles
			if not public then return end
			public.Window.Position = UDim2.new(0.5, -350, 0.5, -194)
			public.Window.Visible = true
		end)

	end

	local cursedpadding = Instance.new('Frame')
	cursedpadding.Size = UDim2.fromOffset()
	cursedpadding.BackgroundTransparency = 1
	cursedpadding.Parent = children
	categorysettings.Function = categorysettings.Function or function() end

	function categoryapi:ChangeValue(val)
		if val then
			if categorysettings.Profiles then
				local ind = self:GetValue(val)
				if ind then
					if val ~= 'default' then
						table.remove(mainapi.Profiles, ind)
						if isfile('catsix/profiles/'..val..mainapi.Place..'.txt') and delfile then
							delfile('catsix/profiles/'..val..mainapi.Place..'.txt')
						end
					end
				else
					table.insert(mainapi.Profiles, {Name = val, Bind = {}})
				end
			else
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
		end

		categorysettings.Function()
		for _, v in self.Objects do
			v:Destroy()
		end
		table.clear(self.Objects)
		self.Selected = nil

		for i, v in (categorysettings.Profiles and mainapi.Profiles or self.List) do
			if categorysettings.Profiles then
				local object = Instance.new('TextButton')
				object.Name = v.Name
				object.Size = UDim2.fromOffset(200, 33)
				object.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				object.AutoButtonColor = false
				object.Text = ''
				object.Parent = children
				addCorner(object)
				local objectstroke = Instance.new('UIStroke')
				objectstroke.Color = color.Light(uipallet.Main, 0.1)
				objectstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				objectstroke.Enabled = false
				objectstroke.Parent = object
				local objecttitle = Instance.new('TextLabel')
				objecttitle.Name = 'Title'
				objecttitle.Size = UDim2.new(1, -10, 1, 0)
				objecttitle.Position = UDim2.fromOffset(10, 0)
				objecttitle.BackgroundTransparency = 1
				objecttitle.Text = v.Name
				objecttitle.TextXAlignment = Enum.TextXAlignment.Left
				objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.4)
				objecttitle.TextSize = 15
				objecttitle.FontFace = uipallet.Font
				objecttitle.Parent = object
				local dotsbutton = Instance.new('TextButton')
				dotsbutton.Name = 'Dots'
				dotsbutton.Size = UDim2.fromOffset(25, 33)
				dotsbutton.Position = UDim2.new(1, -25, 0, 0)
				dotsbutton.BackgroundTransparency = 1
				dotsbutton.Text = ''
				dotsbutton.Parent = object
				local dots = Instance.new('ImageLabel')
				dots.Name = 'Dots'
				dots.Size = UDim2.fromOffset(3, 16)
				dots.Position = UDim2.fromOffset(10, 9)
				dots.BackgroundTransparency = 1
				dots.Image = getcustomasset('catsix/assets/new/dots.png')
				dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
				dots.Parent = dotsbutton
				local bind = Instance.new('TextButton')
				addTooltip(bind, 'Click to bind')
				bind.Name = 'Bind'
				bind.Size = UDim2.fromOffset(20, 21)
				bind.Position = UDim2.new(1, -30, 0, 6)
				bind.AnchorPoint = Vector2.new(1, 0)
				bind.BackgroundColor3 = Color3.new(1, 1, 1)
				bind.BackgroundTransparency = 0.92
				bind.BorderSizePixel = 0
				bind.AutoButtonColor = false
				bind.Visible = false
				bind.Text = ''
				addCorner(bind, UDim.new(0, 4))
				local bindicon = Instance.new('ImageLabel')
				bindicon.Name = 'Icon'
				bindicon.Size = UDim2.fromOffset(12, 12)
				bindicon.Position = UDim2.new(0.5, -6, 0, 5)
				bindicon.BackgroundTransparency = 1
				bindicon.Image = getcustomasset('catsix/assets/new/bind.png')
				bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
				bindicon.Parent = bind
				local bindtext = Instance.new('TextLabel')
				bindtext.Size = UDim2.fromScale(1, 1)
				bindtext.Position = UDim2.fromOffset(0, 1)
				bindtext.BackgroundTransparency = 1
				bindtext.Visible = false
				bindtext.Text = ''
				bindtext.TextColor3 = color.Dark(uipallet.Text, 0.43)
				bindtext.TextSize = 12
				bindtext.FontFace = uipallet.Font
				bindtext.Parent = bind
				bind.MouseEnter:Connect(function()
					bindtext.Visible = false
					bindicon.Visible = not bindtext.Visible
					bindicon.Image = getcustomasset('catsix/assets/new/edit.png')
					if v.Name ~= mainapi.Profile then
						bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
					end
				end)
				bind.MouseLeave:Connect(function()
					bindtext.Visible = #v.Bind > 0
					bindicon.Visible = not bindtext.Visible
					bindicon.Image = getcustomasset('catsix/assets/new/bind.png')
					if v.Name ~= mainapi.Profile then
						bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
					end
				end)
				local bindcover = Instance.new('ImageLabel')
				bindcover.Name = 'Cover'
				bindcover.Size = UDim2.fromOffset(154, 33)
				bindcover.BackgroundTransparency = 1
				bindcover.Visible = false
				bindcover.Image = getcustomasset('catsix/assets/new/bindbkg.png')
				bindcover.ScaleType = Enum.ScaleType.Slice
				bindcover.SliceCenter = Rect.new(0, 0, 141, 40)
				bindcover.Parent = object
				local bindcovertext = Instance.new('TextLabel')
				bindcovertext.Name = 'Text'
				bindcovertext.Size = UDim2.new(1, -10, 1, -3)
				bindcovertext.BackgroundTransparency = 1
				bindcovertext.Text = 'PRESS A KEY TO BIND'
				bindcovertext.TextColor3 = uipallet.Text
				bindcovertext.TextSize = 11
				bindcovertext.FontFace = uipallet.Font
				bindcovertext.Parent = bindcover
				bind.Parent = object
				dotsbutton.MouseEnter:Connect(function()
					if v.Name ~= mainapi.Profile then
						dots.ImageColor3 = uipallet.Text
					end
				end)
				dotsbutton.MouseLeave:Connect(function()
					if v.Name ~= mainapi.Profile then
						dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
					end
				end)
				dotsbutton.MouseButton1Click:Connect(function()
					if v.Name ~= mainapi.Profile then
						categoryapi:ChangeValue(v.Name)
					end
				end)
				object.MouseButton1Click:Connect(function()
					mainapi:Save(v.Name)
					mainapi:Load(true)
				end)
				object.MouseEnter:Connect(function()
					bind.Visible = true
					if v.Name ~= mainapi.Profile then
						objectstroke.Enabled = true
						objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
					end
				end)
				object.MouseLeave:Connect(function()
					bind.Visible = #v.Bind > 0
					if v.Name ~= mainapi.Profile then
						objectstroke.Enabled = false
						objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.4)
					end
				end)

				local function bindFunction(self, tab, mouse)
					v.Bind = table.clone(tab)
					if mouse then
						bindcovertext.Text = #tab <= 0 and 'BIND REMOVED' or 'BOUND TO '..table.concat(tab, ' + '):upper()
						bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
						task.delay(1, function()
							bindcover.Visible = false
						end)
					end

					if #tab <= 0 then
						bindtext.Visible = false
						bindicon.Visible = true
						bind.Size = UDim2.fromOffset(20, 21)
					else
						bind.Visible = true
						bindtext.Visible = true
						bindicon.Visible = false
						bindtext.Text = table.concat(tab, ' + '):upper()
						bind.Size = UDim2.fromOffset(math.max(getfontsize(bindtext.Text, bindtext.TextSize, bindtext.Font).X + 10, 20), 21)
					end
				end

				bindFunction({}, v.Bind)
				bind.MouseButton1Click:Connect(function()
					bindcovertext.Text = 'PRESS A KEY TO BIND'
					bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
					bindcover.Visible = true
					mainapi.Binding = {SetBind = bindFunction, Bind = v.Bind}
				end)
				if v.Name == mainapi.Profile then
					self.Selected = object
				end
				table.insert(self.Objects, object)
			else
				local enabled = table.find(self.ListEnabled, v)
				local object = Instance.new('TextButton')
				object.Name = v
				object.Size = UDim2.fromOffset(200, 32)
				object.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				object.AutoButtonColor = false
				object.Text = ''
				object.Parent = children
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
				objectdot.BackgroundColor3 = enabled and categorysettings.Color or color.Light(uipallet.Main, 0.37)
				objectdot.Parent = object
				addCorner(objectdot, UDim.new(1, 0))
				local objectdotin = objectdot:Clone()
				objectdotin.Size = UDim2.fromOffset(8, 9)
				objectdotin.Position = UDim2.fromOffset(1, 1)
				objectdotin.BackgroundColor3 = enabled and categorysettings.Color or color.Light(uipallet.Main, 0.02)
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
				if mainapi.ThreadFix then
					setthreadidentity(8)
				end
				local close = Instance.new('ImageButton')
				close.Name = 'Close'
				close.Size = UDim2.fromOffset(16, 16)
				close.Position = UDim2.new(1, -23, 0, 8)
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
					categoryapi:ChangeValue(v)
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
						objectdot.BackgroundColor3 = categorysettings.Color
						objectdotin.BackgroundColor3 = categorysettings.Color
					end
					categorysettings.Function()
				end)
				table.insert(self.Objects, object)
			end
		end
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end

	function categoryapi:Expand()
		self.Expanded = not self.Expanded
		children.Visible = self.Expanded
		arrow.Rotation = self.Expanded and 0 or 180
		window.Size = UDim2.fromOffset(220, self.Expanded and math.min(51 + windowlist.AbsoluteContentSize.Y / scale.Scale, 611) or 45)
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end

	function categoryapi:GetValue(name)
		for i, v in mainapi.Profiles do
			if v.Name == name then
				return i
			end
		end
	end

	for i, v in components do
		categoryapi['Create'..i] = function(self, optionsettings)
			return v(optionsettings, children, categoryapi)
		end
	end

	addbutton.MouseEnter:Connect(function()
		addbutton.ImageTransparency = 0
	end)
	addbutton.MouseLeave:Connect(function()
		addbutton.ImageTransparency = 0.3
	end)
	addbutton.MouseButton1Click:Connect(function()
		if not table.find(categoryapi.List, addvalue.Text) then
			categoryapi:ChangeValue(addvalue.Text)
			addvalue.Text = ''
		end
	end)
	arrowbutton.MouseEnter:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(220, 220, 220)
	end)
	arrowbutton.MouseLeave:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	end)
	arrowbutton.MouseButton1Click:Connect(function()
		categoryapi:Expand()
	end)
	arrowbutton.MouseButton2Click:Connect(function()
		categoryapi:Expand()
	end)
	addvalue.FocusLost:Connect(function(enter)
		if enter and not table.find(categoryapi.List, addvalue.Text) then
			categoryapi:ChangeValue(addvalue.Text)
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
	children:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end)
	settings.MouseEnter:Connect(function()
		settings.ImageColor3 = uipallet.Text
	end)
	settings.MouseLeave:Connect(function()
		settings.ImageColor3 = color.Light(uipallet.Main, 0.37)
	end)
	settings.MouseButton1Click:Connect(function()
		childrentwo.Visible = not childrentwo.Visible
	end)
	window.InputBegan:Connect(function(inputObj)
		if inputObj.Position.Y < window.AbsolutePosition.Y + 41 and inputObj.UserInputType == Enum.UserInputType.MouseButton2 then
			categoryapi:Expand()
		end
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		if categoryapi.Expanded then
			window.Size = UDim2.fromOffset(220, math.min(51 + windowlist.AbsoluteContentSize.Y / scale.Scale, 611))
		end
	end)
	windowlisttwo:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		childrentwo.Size = UDim2.fromOffset(220, windowlisttwo.AbsoluteContentSize.Y)
	end)

	categoryapi.Button = self.Categories.Main:CreateButton({
		Name = categorysettings.Name,
		Icon = categorysettings.CategoryIcon,
		Size = categorysettings.CategorySize,
		Window = window
	})

	categoryapi.Object = window
	self.Categories[categorysettings.Name] = categoryapi

	return categoryapi
end

function mainapi:CreateSearch()
	local xoffset = inputService.TouchEnabled and 0.35 or 0.5
	local searchbkg = Instance.new('Frame')
	searchbkg.Name = 'Search'
	searchbkg.Size = UDim2.fromOffset(220, 37)
	searchbkg.Position = UDim2.new(xoffset, 0, 0, 13)
	searchbkg.AnchorPoint = Vector2.new(xoffset, 0)
	searchbkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	searchbkg.Parent = clickgui
	local searchicon = Instance.new('ImageLabel')
	searchicon.Name = 'Icon'
	searchicon.Size = UDim2.fromOffset(14, 14)
	searchicon.Position = UDim2.new(1, -23, 0, 11)
	searchicon.BackgroundTransparency = 1
	searchicon.Image = getcustomasset('catsix/assets/new/search.png')
	searchicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
	searchicon.Parent = searchbkg
	local legiticon = Instance.new('ImageButton')
	legiticon.Name = 'Legit'
	legiticon.Size = UDim2.fromOffset(29, 16)
	legiticon.Position = UDim2.fromOffset(8, 11)
	legiticon.BackgroundTransparency = 1
	legiticon.Image = getcustomasset('catsix/assets/new/legit.png')
	legiticon.Parent = searchbkg
	local legitdivider = Instance.new('Frame')
	legitdivider.Name = 'LegitDivider'
	legitdivider.Size = UDim2.fromOffset(2, 12)
	legitdivider.Position = UDim2.fromOffset(43, 13)
	legitdivider.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
	legitdivider.BorderSizePixel = 0
	legitdivider.Parent = searchbkg
	addBlur(searchbkg)
	addCorner(searchbkg)
	local search = Instance.new('TextBox')
	search.Size = UDim2.new(1, -50, 0, 37)
	search.Position = UDim2.fromOffset(50, 0)
	search.BackgroundTransparency = 1
	search.Text = ''
	search.PlaceholderText = ''
	search.TextXAlignment = Enum.TextXAlignment.Left
	search.TextColor3 = uipallet.Text
	search.TextSize = 12
	search.FontFace = uipallet.Font
	search.ClearTextOnFocus = false
	search.Parent = searchbkg
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -37)
	children.Position = UDim2.fromOffset(0, 34)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = searchbkg
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 33)
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.928
	divider.BorderSizePixel = 0
	divider.Visible = false
	divider.Parent = searchbkg
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children

	children:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end)
	legiticon.MouseButton1Click:Connect(function()
		clickgui.Visible = false
		self.Legit.Window.Visible = true
		self.Legit.Window.Position = UDim2.new(0.5, -350, 0.5, -194)
	end)
	search:GetPropertyChangedSignal('Text'):Connect(function()
		for _, v in children:GetChildren() do
			if v:IsA('TextButton') then
				v:Destroy()
			end
		end
		if search.Text == '' then return end

		for i, v in self.Modules do
			if i:lower():find(search.Text:lower()) then
				local button = v.Object:Clone()
				button.Bind:Destroy()
				button.MouseButton1Click:Connect(function()
					v:Toggle()
				end)

				button.MouseButton2Click:Connect(function()
					v.Object.Parent.Parent.Visible = true
					local frame = v.Object.Parent
					local highlight = Instance.new('Frame')
					highlight.Size = UDim2.fromScale(1, 1)
					highlight.BackgroundColor3 = Color3.new(1, 1, 1)
					highlight.BackgroundTransparency = 0.6
					highlight.BorderSizePixel = 0
					highlight.Parent = v.Object
					tween:Tween(highlight, TweenInfo.new(0.5), {
						BackgroundTransparency = 1
					})
					task.delay(0.5, highlight.Destroy, highlight)

					frame.CanvasPosition = Vector2.new(0, (v.Object.LayoutOrder * 40) - (math.min(frame.CanvasSize.Y.Offset, 600) / 2))
				end)

				button.Parent = children
				task.spawn(function()
					repeat
						for _, v2 in {'Text', 'TextColor3', 'BackgroundColor3'} do
							button[v2] = v.Object[v2]
						end
						button.UIGradient.Color = v.Object.UIGradient.Color
						button.UIGradient.Enabled = v.Object.UIGradient.Enabled
						button.Dots.Dots.ImageColor3 = v.Object.Dots.Dots.ImageColor3
						task.wait()
					until not button.Parent
				end)
			end
		end
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		searchbkg.Size = UDim2.fromOffset(220, math.min(37 + windowlist.AbsoluteContentSize.Y / scale.Scale, 437))
	end)

	self.Legit.Icon = legiticon
end

function mainapi:CreateLegit()
	local legitapi = {Modules = {}}

	local window = Instance.new('Frame')
	window.Name = 'LegitGUI'
	window.Size = UDim2.fromOffset(700, 389)
	window.Position = UDim2.new(0.5, -350, 0.5, -194)
	window.BackgroundColor3 = uipallet.Main
	window.Visible = false
	window.Parent = scaledgui
	addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local modal = Instance.new('TextButton')
	modal.BackgroundTransparency = 1
	modal.Text = ''
	modal.Modal = true
	modal.Parent = window
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = UDim2.fromOffset(16, 16)
	icon.Position = UDim2.fromOffset(18, 13)
	icon.BackgroundTransparency = 1
	icon.Image = getcustomasset('catsix/assets/new/legittab.png')
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local close = addCloseButton(window)
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.fromOffset(684, 340)
	children.Position = UDim2.fromOffset(14, 41)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local windowlist = Instance.new('UIGridLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.FillDirectionMaxCells = 4
	windowlist.CellSize = UDim2.fromOffset(163, 114)
	windowlist.CellPadding = UDim2.fromOffset(6, 5)
	windowlist.Parent = children
	legitapi.Window = window
	table.insert(mainapi.Windows, window)

	function legitapi:CreateModule(modulesettings)
		mainapi:Remove(modulesettings.Name)
		local moduleapi = {
			Enabled = false,
			Options = {},
			Name = modulesettings.Name,
			Legit = true
		}

		local module = Instance.new('TextButton')
		module.Name = modulesettings.Name
		module.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		module.Text = ''
		module.AutoButtonColor = false
		module.Parent = children
		addTooltip(module, modulesettings.Tooltip)
		addCorner(module)
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -16, 0, 20)
		title.Position = UDim2.fromOffset(16, 81)
		title.BackgroundTransparency = 1
		title.Text = modulesettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.31)
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = module
		local knob = Instance.new('Frame')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(22, 12)
		knob.Position = UDim2.new(1, -57, 0, 14)
		knob.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
		knob.Parent = module
		addCorner(knob, UDim.new(1, 0))
		local knobmain = knob:Clone()
		knobmain.Size = UDim2.fromOffset(8, 8)
		knobmain.Position = UDim2.fromOffset(2, 2)
		knobmain.BackgroundColor3 = uipallet.Main
		knobmain.Parent = knob
		local dotsbutton = Instance.new('TextButton')
		dotsbutton.Name = 'Dots'
		dotsbutton.Size = UDim2.fromOffset(14, 24)
		dotsbutton.Position = UDim2.new(1, -27, 0, 8)
		dotsbutton.BackgroundTransparency = 1
		dotsbutton.Text = ''
		dotsbutton.Parent = module
		local dots = Instance.new('ImageLabel')
		dots.Name = 'Dots'
		dots.Size = UDim2.fromOffset(2, 12)
		dots.Position = UDim2.fromOffset(6, 6)
		dots.BackgroundTransparency = 1
		dots.Image = getcustomasset('catsix/assets/new/dots.png')
		dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		dots.Parent = dotsbutton
		local shadow = Instance.new('TextButton')
		shadow.Name = 'Shadow'
		shadow.Size = UDim2.new(1, 0, 1, -5)
		shadow.BackgroundColor3 = Color3.new()
		shadow.BackgroundTransparency = 1
		shadow.AutoButtonColor = false
		shadow.ClipsDescendants = true
		shadow.Visible = false
		shadow.Text = ''
		shadow.Parent = window
		addCorner(shadow)
		local settingspane = Instance.new('TextButton')
		settingspane.Size = UDim2.new(0, 220, 1, 0)
		settingspane.Position = UDim2.fromScale(1, 0)
		settingspane.BackgroundColor3 = uipallet.Main
		settingspane.AutoButtonColor = false
		settingspane.Text = ''
		settingspane.Parent = shadow
		local settingstitle = Instance.new('TextLabel')
		settingstitle.Name = 'Title'
		settingstitle.Size = UDim2.new(1, -36, 0, 20)
		settingstitle.Position = UDim2.fromOffset(36, 12)
		settingstitle.BackgroundTransparency = 1
		settingstitle.Text = modulesettings.Name
		settingstitle.TextXAlignment = Enum.TextXAlignment.Left
		settingstitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
		settingstitle.TextSize = 13
		settingstitle.FontFace = uipallet.Font
		settingstitle.Parent = settingspane
		local back = Instance.new('ImageButton')
		back.Name = 'Back'
		back.Size = UDim2.fromOffset(16, 16)
		back.Position = UDim2.fromOffset(11, 13)
		back.BackgroundTransparency = 1
		back.Image = getcustomasset('catsix/assets/new/back.png')
		back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		back.Parent = settingspane
		addCorner(settingspane)
		local settingschildren = Instance.new('ScrollingFrame')
		settingschildren.Name = 'Children'
		settingschildren.Size = UDim2.new(1, 0, 1, -45)
		settingschildren.Position = UDim2.fromOffset(0, 41)
		settingschildren.BackgroundColor3 = uipallet.Main
		settingschildren.BorderSizePixel = 0
		settingschildren.ScrollBarThickness = 2
		settingschildren.ScrollBarImageTransparency = 0.75
		settingschildren.CanvasSize = UDim2.new()
		settingschildren.Parent = settingspane
		local settingswindowlist = Instance.new('UIListLayout')
		settingswindowlist.SortOrder = Enum.SortOrder.LayoutOrder
		settingswindowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		settingswindowlist.Parent = settingschildren
		if modulesettings.Size then
			local modulechildren = Instance.new('Frame')
			modulechildren.Size = modulesettings.Size
			modulechildren.BackgroundTransparency = 1
			modulechildren.Visible = false
			modulechildren.Parent = scaledgui
			makeDraggable(modulechildren, window)
			local objectstroke = Instance.new('UIStroke')
			objectstroke.Color = Color3.fromRGB(5, 134, 105)
			objectstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			objectstroke.Thickness = 0
			objectstroke.Parent = modulechildren
			moduleapi.Children = modulechildren
		end
		modulesettings.Function = modulesettings.Function or function() end
		addMaid(moduleapi)

		function moduleapi:Toggle()
			moduleapi.Enabled = not moduleapi.Enabled
			if moduleapi.Children then
				moduleapi.Children.Visible = moduleapi.Enabled
			end
			title.TextColor3 = moduleapi.Enabled and color.Light(uipallet.Text, 0.2) or color.Dark(uipallet.Text, 0.31)
			module.BackgroundColor3 = moduleapi.Enabled and color.Light(uipallet.Main, 0.05) or module.BackgroundColor3
			tween:Tween(knob, uipallet.Tween, {
				BackgroundColor3 = moduleapi.Enabled and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Light(uipallet.Main, 0.14)
			})
			tween:Tween(knobmain, uipallet.Tween, {
				Position = UDim2.fromOffset(moduleapi.Enabled and 12 or 2, 2)
			})
			if not moduleapi.Enabled then
				for _, v in moduleapi.Connections do
					v:Disconnect()
				end
				table.clear(moduleapi.Connections)
			end
			mainapi:QueueSave()
			task.spawn(modulesettings.Function, moduleapi.Enabled)
		end

		back.MouseEnter:Connect(function()
			back.ImageColor3 = uipallet.Text
		end)
		back.MouseLeave:Connect(function()
			back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end)
		back.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.fromScale(1, 0)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		dotsbutton.MouseButton1Click:Connect(function()
			shadow.Visible = true
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 0.5
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.new(1, -220, 0, 0)
			})
		end)
		dotsbutton.MouseEnter:Connect(function()
			dots.ImageColor3 = uipallet.Text
		end)
		dotsbutton.MouseLeave:Connect(function()
			dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end)
		module.MouseEnter:Connect(function()
			if not moduleapi.Enabled then
				module.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
			end
		end)
		module.MouseLeave:Connect(function()
			if not moduleapi.Enabled then
				module.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			end
		end)
		module.MouseButton1Click:Connect(function()
			moduleapi:Toggle()
		end)
		module.MouseButton2Click:Connect(function()
			shadow.Visible = true
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 0.5
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.new(1, -220, 0, 0)
			})
		end)
		shadow.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.fromScale(1, 0)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		settingswindowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			settingschildren.CanvasSize = UDim2.fromOffset(0, settingswindowlist.AbsoluteContentSize.Y / scale.Scale)
		end)

		for i, v in components do
			moduleapi['Create'..i] = function(_, optionsettings)
				return v(optionsettings, settingschildren, moduleapi)
			end
		end

		moduleapi.Object = module
		legitapi.Modules[modulesettings.Name] = moduleapi

		local sorting = {}
		for _, v in legitapi.Modules do
			table.insert(sorting, v.Name)
		end
		table.sort(sorting)

		for i, v in sorting do
			legitapi.Modules[v].Object.LayoutOrder = i
		end

		return moduleapi
	end

	local function visibleCheck()
		for _, v in legitapi.Modules do
			if v.Children then
				local visible = clickgui.Visible
				for _, v2 in self.Windows do
					visible = visible or v2.Visible
				end
				v.Children.Visible = (not visible or window.Visible) and v.Enabled
			end
		end
	end

	close.MouseButton1Click:Connect(function()
		window.Visible = false
		clickgui.Visible = true
	end)
	self:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(visibleCheck))
	window:GetPropertyChangedSignal('Visible'):Connect(function()
		self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
		visibleCheck()
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
	end)

	self.Legit = legitapi

	return legitapi
end


local function escapeRich(text)
	return (text:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
end

local markerColors = {
	['+'] = '#57a64a',
	['-'] = '#e06c75',
	['*'] = '#5c9fd6',
	['!'] = '#e5c07b'
}

local function formatNotes(text)
	local lines = {}
	for _, line in string.split(text, '\n') do
		local clean = line:gsub('\27%[[%d;]*m', '')
		local escaped = escapeRich(clean):gsub('%[PAID%]', '<font color="#c678dd">[PAID]</font>')
		local color = markerColors[clean:match('^%[(.)%] ') or '']
		if color then
			table.insert(lines, `<font color="{color}">{escaped}</font>`)
		elseif clean:match('^%[.+%]$') then
			table.insert(lines, `<font color="#dcddde">{escaped}</font>`)
		else
			table.insert(lines, escaped)
		end
	end
	return table.concat(lines, '\n')
end

local presetPromptFile = 'catsix/profiles/presetprompt.txt'

local function getCommit()
	return isfile('catsix/profiles/commit.txt') and readfile('catsix/profiles/commit.txt') or nil
end

local function dismissedPresets()
	local commit = getCommit()
	return commit ~= nil and isfile(presetPromptFile) and readfile(presetPromptFile) == commit
end

local function shouldOfferPresets()
	if shared.VapePresetInstall or shared.updated then return true end

	local suc, files = pcall(listfiles, 'catsix/profiles')
	return suc and #files < 4
end

local function installPresets()
	local install = shared.VapePresetInstall
	if install then
		shared.VapePresetInstall = nil
		return install()
	end

	local suc, req = pcall(request, {
		Url = 'https://api.github.com/repos/MaxlaserTech/CatV6/contents/profiles',
		Method = 'GET'
	})
	if not suc or not req or req.StatusCode ~= 200 then return false end

	local decoded, body = pcall(function()
		return httpService:JSONDecode(req.Body)
	end)
	if not decoded or type(body) ~= 'table' then return false end

	local commit = getCommit() or 'main'
	local installed = false
	for _, v in body do
		if v.type == 'file' then
			local path = ({v.path:gsub(' ', '%%20')})[1]
			local got, res = pcall(function()
				return game:HttpGet(`https://raw.githubusercontent.com/MaxlaserTech/CatV6/{commit}/{path}`, true)
			end)
			if got and type(res) == 'string' and res ~= '' and res ~= '404: Not Found' then
				writefile(`catsix/{path}`, res)
				installed = true
			end
		end
	end
	return installed
end

function mainapi:PromptPresets()
	if self.PromptedPresets or dismissedPresets() then return end
	self.PromptedPresets = true

	self:CreatePrompt({
		Title = 'Preset configs',
		Text = 'Would you like to install a premade config, this will override ur default config.',
		Confirm = 'Install',
		Cancel = 'No thanks',
		Dismiss = 'Dont show until next update',
		Function = function(result)
			if result == 'dismiss' then
				pcall(writefile, presetPromptFile, getCommit() or 'main')
				self:CreateNotification('Vape', 'Preset configs wont be offered again until the next update.', 8)
				return
			end
			if not result then return end
			task.spawn(function()
				local loaded = self.Loaded
				self.Loaded = false

				if not installPresets() then
					self.Loaded = loaded
					self:CreateNotification('Vape', 'Failed to download preset configs.', 8, 'alert')
					return
				end

				table.clear(self.SaveCache)
				self:Load(true)
				self:CreateNotification('Vape', `Loaded the preset config for {self.Profile}`, 8)
			end)
		end
	})
end

local function parseTimestamp(value)
	if type(value) == 'number' then return value end
	if type(value) ~= 'string' then return 0 end

	local year, month, day, hour, min, sec = value:match('(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)')
	if not year then return tonumber(value) or 0 end

	return os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = tonumber(sec)
	})
end

local function parseFilename(entry)
	local id, name = tostring(entry.filename or ''):match('^%((%d+)%)%-%((.+)%)%.json$')
	local fallbackName = entry.config_name
	local fallbackAuthor = entry.discord_username

	return name or (fallbackName ~= 'unknown' and fallbackName) or 'Unnamed',
		(fallbackAuthor ~= 'unknown' and fallbackAuthor) or id or 'unknown'
end

local avatarCache = {}
local avatarPlaceholder = 'rbxasset://textures/ui/GuiImagePlaceholder.png'

local function applyAvatar(image, url)
	image.Image = avatarPlaceholder
	if type(url) ~= 'string' or not url:find('^https?://') then return end

	if avatarCache[url] then
		image.Image = avatarCache[url]
		return
	end

	task.spawn(function()
		if not isfolder('catsix/assets/pfp') then
			makefolder('catsix/assets/pfp')
		end

		local path = 'catsix/assets/pfp/'..url:gsub('%W', ''):sub(-48)..'.png'
		if not isfile(path) then
			local suc, res = pcall(request, {Url = url, Method = 'GET'})
			if not suc or not res or not res.Body or res.Body == '' then return end
			writefile(path, res.Body)
		end

		local ok, asset = pcall(getcustomasset, path)
		if not ok or not asset then return end

		avatarCache[url] = asset
		if image.Parent then
			image.Image = asset
		end
	end)
end

local function relativeDays(uploaded)
	local days = math.floor((os.time() - (tonumber(uploaded) or os.time())) / 86400)
	if days <= 0 then return 'Today' end
	return days..(days == 1 and ' day ago' or ' days ago')
end

function mainapi:CreatePublicProfiles()
	local publicapi = {Configs = {}, Cards = {}, Owned = {}, Accents = {}, Sort = 'newest', Search = ''}

	local function accentColor()
		local guicolor = mainapi.GUIColor
		if not guicolor then return Color3.fromRGB(5, 133, 102) end
		return Color3.fromHSV(guicolor.Hue, guicolor.Sat, guicolor.Value)
	end

	local function accentTextColor()
		local guicolor = mainapi.GUIColor
		if not guicolor then return Color3.new(1, 1, 1) end
		return mainapi:TextColor(guicolor.Hue, guicolor.Sat, guicolor.Value)
	end

	local sorts = {
		newest = function(a, b)
			return a.Uploaded > b.Uploaded
		end,
		oldest = function(a, b)
			return a.Uploaded < b.Uploaded
		end,
		name = function(a, b)
			return a.Name:lower() < b.Name:lower()
		end
	}

	local window = Instance.new('Frame')
	window.Name = 'PublicProfilesGUI'
	window.Size = UDim2.fromOffset(700, 389)
	window.Position = UDim2.new(0.5, -350, 0.5, -194)
	window.BackgroundColor3 = uipallet.Main
	window.Visible = false
	window.Parent = scaledgui
	addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local modal = Instance.new('TextButton')
	modal.BackgroundTransparency = 1
	modal.Text = ''
	modal.Modal = true
	modal.Parent = window
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = UDim2.fromOffset(16, 10)
	icon.Position = UDim2.fromOffset(10, 13)
	icon.BackgroundTransparency = 1
	icon.Image = getcustomasset('catsix/assets/new/profilesicon.png')
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, 20, 0, 20)
	title.Position = UDim2.fromOffset(25, 0)
	title.BackgroundTransparency = 1
	title.Text = 'Public Profiles'
	title.TextColor3 = Color3.fromRGB(200, 200, 200)
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Top
	title.Parent = icon
	local close = addCloseButton(window)
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 0.102827765, 0)
	divider.BorderSizePixel = 0
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.95
	divider.Parent = window

	local publish = Instance.new('TextButton')
	publish.Name = 'Publish'
	publish.Size = UDim2.fromOffset(167, 30)
	publish.Position = UDim2.new(0.0142857144, 0, 0.136246786, 0)
	publish.BackgroundColor3 = accentColor()
	publish.AutoButtonColor = false
	publish.Text = ('create new'):upper()
	publish.TextColor3 = accentTextColor()
	publish.TextSize = 12
	publish.FontFace = uipallet.Font
	publish.Parent = window
	addCorner(publish)
	table.insert(publicapi.Accents, publish)

	local searchbkg = Instance.new('Frame')
	searchbkg.Name = 'Search'
	searchbkg.Size = UDim2.fromOffset(485, 35)
	searchbkg.Position = UDim2.new(0.282000005, 0, 0.153999999, 0)
	searchbkg.BackgroundColor3 = uipallet.Main
	searchbkg.BorderSizePixel = 0
	searchbkg.Parent = window
	addCorner(searchbkg)
	local searchstroke = Instance.new('UIStroke')
	searchstroke.Color = Color3.fromRGB(42, 41, 42)
	searchstroke.Parent = searchbkg
	local searchicon = Instance.new('ImageLabel')
	searchicon.Size = UDim2.fromOffset(13, 13)
	searchicon.Position = UDim2.new(0.0189999994, 0, 0.300000012, 0)
	searchicon.BackgroundTransparency = 1
	searchicon.BorderSizePixel = 0
	searchicon.Image = getcustomasset('catsix/assets/new/search.png')
	searchicon.ImageTransparency = 0.7
	searchicon.Parent = searchbkg
	local searchbox = Instance.new('TextBox')
	searchbox.Size = UDim2.new(0.509247422, 200, 0.899999976, 0)
	searchbox.Position = UDim2.new(0.0787525922, 0, 0, 2)
	searchbox.BackgroundTransparency = 1
	searchbox.BorderSizePixel = 0
	searchbox.Text = ''
	searchbox.PlaceholderText = 'Search Profile / Username'
	searchbox.PlaceholderColor3 = Color3.fromRGB(94, 94, 94)
	searchbox.TextXAlignment = Enum.TextXAlignment.Left
	searchbox.TextColor3 = Color3.fromRGB(171, 171, 171)
	searchbox.TextSize = 12
	searchbox.FontFace = uipallet.Font
	searchbox.ClearTextOnFocus = false
	searchbox.Parent = searchbkg

	local sortframe = Instance.new('Frame')
	sortframe.Name = 'Sorts'
	sortframe.Size = UDim2.fromOffset(500, 28)
	sortframe.Position = UDim2.new(0.282000005, 0, 0.270000011, 0)
	sortframe.BackgroundTransparency = 1
	sortframe.BorderSizePixel = 0
	sortframe.Parent = window
	local sortlayout = Instance.new('UIListLayout')
	sortlayout.FillDirection = Enum.FillDirection.Horizontal
	sortlayout.SortOrder = Enum.SortOrder.LayoutOrder
	sortlayout.Padding = UDim.new(0, 5)
	sortlayout.Parent = sortframe

	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.fromOffset(500, 236)
	children.Position = UDim2.new(0.282000035, 0, 0, 153)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local gridlayout = Instance.new('UIGridLayout')
	gridlayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridlayout.FillDirectionMaxCells = 4
	gridlayout.CellSize = UDim2.fromOffset(157, 140)
	gridlayout.CellPadding = UDim2.fromOffset(9, 5)
	gridlayout.Parent = children

	local owned = Instance.new('ScrollingFrame')
	owned.Name = 'Owned'
	owned.Size = UDim2.fromOffset(167, 288)
	owned.Position = UDim2.new(0.0142857144, 0, 0, 91)
	owned.BackgroundTransparency = 1
	owned.BorderSizePixel = 0
	owned.ScrollBarThickness = 0
	owned.CanvasSize = UDim2.new()
	owned.Parent = window
	local ownedlayout = Instance.new('UIListLayout')
	ownedlayout.SortOrder = Enum.SortOrder.LayoutOrder
	ownedlayout.Padding = UDim.new(0, 2)
	ownedlayout.Parent = owned

	local ownedempty = Instance.new('TextLabel')
	ownedempty.Name = 'OwnedEmpty'
	ownedempty.Size = UDim2.fromOffset(167, 20)
	ownedempty.Position = UDim2.new(0.0142857144, 0, 0, 95)
	ownedempty.BackgroundTransparency = 1
	ownedempty.Text = 'Nothing published yet'
	ownedempty.TextColor3 = Color3.fromRGB(94, 94, 94)
	ownedempty.TextSize = 12
	ownedempty.FontFace = uipallet.Font
	ownedempty.TextXAlignment = Enum.TextXAlignment.Left
	ownedempty.Visible = false
	ownedempty.Parent = window

	local empty = Instance.new('TextLabel')
	empty.Name = 'Empty'
	empty.Size = UDim2.fromOffset(500, 20)
	empty.Position = UDim2.new(0.282000035, 0, 0, 230)
	empty.BackgroundTransparency = 1
	empty.Text = 'No profiles found'
	empty.TextColor3 = Color3.fromRGB(171, 171, 171)
	empty.TextSize = 12
	empty.FontFace = uipallet.Font
	empty.Visible = false
	empty.Parent = window

	publicapi.Window = window
	table.insert(mainapi.Windows, window)

	local overlay = Instance.new('TextButton')
	overlay.Name = 'Overlay'
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new()
	overlay.BackgroundTransparency = 0.45
	overlay.AutoButtonColor = false
	overlay.Text = ''
	overlay.ZIndex = 4
	overlay.Visible = false
	overlay.Parent = window
	addCorner(overlay)

	local function makePanel(name, height, width)
		local panel = Instance.new('Frame')
		panel.Name = name
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.fromScale(0.5, 0.5)
		panel.Size = UDim2.fromOffset(width or 440, height)
		panel.BackgroundColor3 = Color3.fromRGB(33, 32, 33)
		panel.ZIndex = 5
		panel.Visible = false
		panel.Parent = window
		addBlur(panel).ZIndex = 4
		addCorner(panel)
		local stroke = Instance.new('UIStroke')
		stroke.Color = Color3.fromRGB(42, 40, 42)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = panel
		return panel
	end

	local function makeAction(parent, text, accent, y, width, x)
		local button = Instance.new('TextButton')
		button.Size = UDim2.fromOffset(width, 30)
		button.Position = UDim2.fromOffset(x, y)
		button.BackgroundColor3 = color.Light(uipallet.Main, 0.034)--accent and accentColor() or color.Dark(uipallet.Main, 0.02)
		button.AutoButtonColor = false
		button.Text = text
		button.TextColor3 = accent and accentTextColor() or Color3.new(1, 1, 1)
		button.TextSize = 12
		button.FontFace = uipallet.Font
		button.ZIndex = 6
		button.Parent = parent
		addCorner(button)
		if accent then
			table.insert(publicapi.Accents, button)
		end
		return button
	end

	local details = makePanel('Details', 330, 646)
	details.BackgroundColor3 = uipallet.Main
	local sidebar = Instance.new('Frame')
	sidebar.Name = 'Sidebar'
	sidebar.Size = UDim2.fromOffset(215, 330)
	sidebar.BackgroundColor3 = uipallet.Main -- skibidi yes
	sidebar.BorderSizePixel = 0
	sidebar.ZIndex = 6
	sidebar.Parent = details
	addCorner(sidebar)

	local detailname = Instance.new('TextLabel')
	detailname.Size = UDim2.fromOffset(183, 24)
	detailname.Position = UDim2.fromOffset(16, 16)
	detailname.BackgroundTransparency = 1
	detailname.Text = ''
	detailname.TextColor3 = Color3.new(1, 1, 1)
	detailname.TextSize = 18
	detailname.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	detailname.TextXAlignment = Enum.TextXAlignment.Left
	detailname.TextTruncate = Enum.TextTruncate.AtEnd
	detailname.ZIndex = 7
	detailname.Parent = sidebar

	local avatar = Instance.new('ImageLabel')
	avatar.Size = UDim2.fromOffset(20, 20)
	avatar.Position = UDim2.fromOffset(16, 48)
	avatar.BackgroundColor3 = color.Light(uipallet.Main, 0.06)
	avatar.Image = avatarPlaceholder
	avatar.ZIndex = 7
	avatar.Parent = sidebar
	addCorner(avatar, UDim.new(1, 0))

	local detailauthor = Instance.new('TextLabel')
	detailauthor.Size = UDim2.fromOffset(151, 20)
	detailauthor.Position = UDim2.fromOffset(44, 48)
	detailauthor.BackgroundTransparency = 1
	detailauthor.Text = ''
	detailauthor.TextColor3 = Color3.fromRGB(171, 171, 171)
	detailauthor.TextSize = 12
	detailauthor.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	detailauthor.TextXAlignment = Enum.TextXAlignment.Left
	detailauthor.TextTruncate = Enum.TextTruncate.AtEnd
	detailauthor.ZIndex = 7
	detailauthor.Parent = sidebar

	local function clearList(frame)
		for _, old in frame:GetChildren() do
			if not old:IsA('UIListLayout') and not old:IsA('UIPadding') then
				old:Destroy()
			end
		end
	end

	local function addRow(parent, text, y, selected, onClick, order)
		local row = onClick and Instance.new('TextButton') or Instance.new('Frame')
		row.LayoutOrder = order or 0
		if onClick then
			row.AutoButtonColor = false
			row.Text = ''
			row.MouseButton1Click:Connect(function()
				onClick(row)
			end)
		end
		row.Size = UDim2.fromOffset(215, 34)
		row.Position = UDim2.fromOffset(0, y)
		row.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
		row.BackgroundTransparency = selected and 0 or 1
		row.BorderSizePixel = 0
		row.ZIndex = 7
		row.Parent = parent
		local rowtext = Instance.new('TextLabel')
		rowtext.Size = UDim2.fromOffset(170, 34)
		rowtext.Position = UDim2.fromOffset(16, 0)
		rowtext.BackgroundTransparency = 1
		rowtext.Text = text
		rowtext.TextColor3 = selected and Color3.new(1, 1, 1) or Color3.fromRGB(171, 171, 171)
		rowtext.TextSize = 13
		rowtext.FontFace = uipallet.Font
		rowtext.TextXAlignment = Enum.TextXAlignment.Left
		rowtext.TextTruncate = Enum.TextTruncate.AtEnd
		rowtext.ZIndex = 8
		rowtext.Parent = row
		local chevron = Instance.new('TextLabel')
		chevron.Size = UDim2.fromOffset(20, 34)
		chevron.Position = UDim2.fromOffset(189, 0)
		chevron.BackgroundTransparency = 1
		chevron.Text = '>'
		chevron.TextColor3 = Color3.fromRGB(120, 120, 120)
		chevron.TextSize = 13
		chevron.FontFace = uipallet.Font
		chevron.ZIndex = 8
		chevron.Parent = row
		return row
	end

	local function fillModules(list, count, source, onClick)
		clearList(list)

		local active, rows = {}, {}
		local decoded = source and select(2, pcall(httpService.JSONDecode, httpService, source))
		for module, data in (type(decoded) == 'table' and decoded.Modules or {}) do
			if type(data) == 'table' and data.Enabled then
				table.insert(active, tostring(module))
			end
		end
		table.sort(active)

		count.Text = `<font color="rgb(255,255,255)">{#active}</font> AFFECTED MODULES`
		for i, module in active do
			rows[module] = addRow(list, module, 0, false, onClick and function()
				onClick(module)
			end or nil, i)
		end
		list.CanvasSize = UDim2.fromOffset(0, #active * 34)

		return decoded, rows
	end

	local detailsrow

	local modulecount = Instance.new('TextLabel')
	modulecount.Size = UDim2.fromOffset(183, 16)
	modulecount.Position = UDim2.fromOffset(16, 126)
	modulecount.BackgroundTransparency = 1
	modulecount.RichText = true
	modulecount.Text = ''
	modulecount.TextColor3 = Color3.fromRGB(171, 171, 171)
	modulecount.TextSize = 11
	modulecount.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	modulecount.TextXAlignment = Enum.TextXAlignment.Left
	modulecount.ZIndex = 7
	modulecount.Parent = sidebar

	local modulelist = Instance.new('ScrollingFrame')
	modulelist.Name = 'Modules'
	modulelist.Size = UDim2.fromOffset(215, 178)
	modulelist.Position = UDim2.fromOffset(0, 148)
	modulelist.BackgroundTransparency = 1
	modulelist.BorderSizePixel = 0
	modulelist.ScrollBarThickness = 0
	modulelist.CanvasSize = UDim2.new()
	modulelist.ZIndex = 7
	modulelist.Parent = sidebar
	local modulelayout = Instance.new('UIListLayout')
	modulelayout.SortOrder = Enum.SortOrder.LayoutOrder
	modulelayout.Padding = UDim.new(0, 0)
	modulelayout.Parent = modulelist

	local detailtitle = Instance.new('TextLabel')
	detailtitle.Size = UDim2.fromOffset(200, 20)
	detailtitle.Position = UDim2.fromOffset(231, 22)
	detailtitle.BackgroundTransparency = 1
	detailtitle.Text = 'Details'
	detailtitle.TextColor3 = Color3.new(1, 1, 1)
	detailtitle.TextSize = 15
	detailtitle.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	detailtitle.TextXAlignment = Enum.TextXAlignment.Left
	detailtitle.ZIndex = 6
	detailtitle.Parent = details

	local created = Instance.new('TextLabel')
	created.Size = UDim2.fromOffset(300, 18)
	created.Position = UDim2.fromOffset(231, 62)
	created.BackgroundTransparency = 1
	created.Text = ''
	created.TextColor3 = Color3.fromRGB(140, 140, 140)
	created.TextSize = 13
	created.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	created.TextXAlignment = Enum.TextXAlignment.Left
	created.ZIndex = 6
	created.Parent = details

	local function addStat(x, width, label)
		local box = Instance.new('Frame')
		box.Size = UDim2.fromOffset(width, 64)
		box.Position = UDim2.fromOffset(x, 96)
		box.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		box.BorderSizePixel = 0
		box.ZIndex = 6
		box.Parent = details
		addCorner(box)
		local value = Instance.new('TextLabel')
		value.Size = UDim2.new(1, 0, 0, 24)
		value.Position = UDim2.fromOffset(0, 12)
		value.BackgroundTransparency = 1
		value.Text = ''
		value.TextColor3 = Color3.new(1, 1, 1)
		value.TextSize = 17
		value.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		value.ZIndex = 7
		value.Parent = box
		local caption = Instance.new('TextLabel')
		caption.Size = UDim2.new(1, 0, 0, 16)
		caption.Position = UDim2.fromOffset(0, 38)
		caption.BackgroundTransparency = 1
		caption.Text = label
		caption.TextColor3 = Color3.fromRGB(140, 140, 140)
		caption.TextSize = 11
		caption.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		caption.ZIndex = 7
		caption.Parent = box

		return box, value
	end

	local likesbox, likesvalue = addStat(231, 189, 'Positive reviews')
	local updatedbox, updatedvalue = addStat(432, 189, 'Last updated')

	local detaildesc = Instance.new('TextLabel')
	detaildesc.Size = UDim2.fromOffset(390, 80)
	detaildesc.Position = UDim2.fromOffset(231, 174)
	detaildesc.BackgroundTransparency = 1
	detaildesc.Text = ''
	detaildesc.TextColor3 = Color3.fromRGB(171, 171, 171)
	detaildesc.TextSize = 14
	detaildesc.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	detaildesc.TextXAlignment = Enum.TextXAlignment.Left
	detaildesc.TextYAlignment = Enum.TextYAlignment.Top
	detaildesc.TextWrapped = true
	detaildesc.ZIndex = 6
	detaildesc.Parent = details

	local moduletitle = Instance.new('TextLabel')
	moduletitle.Size = UDim2.fromOffset(390, 26)
	moduletitle.Position = UDim2.fromOffset(231, 20)
	moduletitle.BackgroundTransparency = 1
	moduletitle.Text = ''
	moduletitle.TextColor3 = Color3.new(1, 1, 1)
	moduletitle.TextSize = 18
	moduletitle.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	moduletitle.TextXAlignment = Enum.TextXAlignment.Left
	moduletitle.Visible = false
	moduletitle.ZIndex = 6
	moduletitle.Parent = details

	local optionlist = Instance.new('ScrollingFrame')
	optionlist.Name = 'Options'
	optionlist.Size = UDim2.fromOffset(400, 208)
	optionlist.Position = UDim2.fromOffset(231, 52)
	optionlist.BackgroundTransparency = 1
	optionlist.BorderSizePixel = 0
	optionlist.ScrollBarThickness = 0
	optionlist.CanvasSize = UDim2.new()
	optionlist.Visible = false
	optionlist.ZIndex = 6
	optionlist.Parent = details
	local optionlayout = Instance.new('UIListLayout')
	optionlayout.SortOrder = Enum.SortOrder.LayoutOrder
	optionlayout.Padding = UDim.new(0, 0)
	optionlayout.Parent = optionlist

	local detailview = {detailtitle, created, likesbox, updatedbox, detaildesc}
	local selectModule
	local uploadsource

	local function showDetails(showModule)
		for _, part in detailview do
			part.Visible = not showModule
		end
		moduletitle.Visible = showModule
		optionlist.Visible = showModule
	end

	local function formatOption(value)
		if type(value) ~= 'table' then return tostring(value) end
		if value.List then return `{#value.List} items` end
		if value.Value ~= nil then
			if type(value.Value) == 'number' then
				return tostring(math.floor(value.Value * 10 + 0.5) / 10)
			end
			return tostring(value.Value)
		end
		if value.Min and value.Max then
			return `{math.floor(value.Min * 10 + 0.5) / 10} - {math.floor(value.Max * 10 + 0.5) / 10}`
		end
		if value.Enabled ~= nil then return value.Enabled and 'ON' or 'OFF' end

		local on = 0
		for _, v in pairs(value) do
			if v == true then on += 1 end
		end
		return on > 0 and `{on} on` or '-'
	end

	local function addOptionRow(parent, name, value, index)
		local row = Instance.new('Frame')
		row.Size = UDim2.fromOffset(400, 30)
		row.BackgroundTransparency = 1
		row.LayoutOrder = index
		row.ZIndex = 7
		row.Parent = parent
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromOffset(270, 30)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.fromRGB(171, 171, 171)
		label.TextSize = 13
		label.FontFace = uipallet.Font
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.ZIndex = 8
		label.Parent = row
		local text = formatOption(value)
		local pill = Instance.new('Frame')
		pill.Size = UDim2.fromOffset(math.max(#text * 7 + 16, 34), 20)
		pill.Position = UDim2.new(1, -math.max(#text * 7 + 16, 34), 0, 5)
		pill.BackgroundColor3 = color.Light(uipallet.Main, 0.06)
		pill.BorderSizePixel = 0
		pill.ZIndex = 8
		pill.Parent = row
		addCorner(pill, UDim.new(0, 4))
		local pilltext = Instance.new('TextLabel')
		pilltext.Size = UDim2.fromScale(1, 1)
		pilltext.BackgroundTransparency = 1
		pilltext.Text = text
		pilltext.TextColor3 = Color3.fromRGB(200, 200, 200)
		pilltext.TextSize = 11
		pilltext.FontFace = uipallet.Font
		pilltext.ZIndex = 9
		pilltext.Parent = pill
	end

	detailsrow = addRow(sidebar, 'Details', 80, true, function()
		if selectModule then
			selectModule(nil)
		end
	end)

	local download = makeAction(details, 'Download', true, 276, 245, 385)

	local function addThumb(parent, flipped)
		local thumb = Instance.new('Frame')
		thumb.Name = 'Thumb'
		thumb.AnchorPoint = Vector2.new(0.5, 0.5)
		thumb.Size = UDim2.fromOffset(14, 14)
		thumb.Position = UDim2.fromScale(0.5, 0.5)
		thumb.BackgroundTransparency = 1
		thumb.Rotation = flipped and 180 or 0
		thumb.ZIndex = 8
		thumb.Parent = parent

		for _, shape in {{4, 7, 0, 7, 1}, {9, 8, 5, 6, 2}, {5, 7, 5, 0, 2}} do
			local part = Instance.new('Frame')
			part.Size = UDim2.fromOffset(shape[1], shape[2])
			part.Position = UDim2.fromOffset(shape[3], shape[4])
			part.BackgroundColor3 = Color3.fromRGB(171, 171, 171)
			part.BorderSizePixel = 0
			part.ZIndex = 8
			part.Parent = thumb
			addCorner(part, UDim.new(0, shape[5]))
		end

		return thumb
	end

	local voteframe = Instance.new('Frame')
	voteframe.Name = 'Votes'
	voteframe.Size = UDim2.fromOffset(92, 30)
	voteframe.Position = UDim2.fromOffset(231, 276)
	voteframe.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
	voteframe.BorderSizePixel = 0
	voteframe.ClipsDescendants = true
	voteframe.ZIndex = 6
	voteframe.Parent = details
	addCorner(voteframe)

	local votedivider = Instance.new('Frame')
	votedivider.Name = 'Divider'
	votedivider.Size = UDim2.fromOffset(1, 18)
	votedivider.Position = UDim2.fromOffset(45, 6)
	votedivider.BackgroundColor3 = Color3.new(1, 1, 1)
	votedivider.BackgroundTransparency = 0.9
	votedivider.BorderSizePixel = 0
	votedivider.ZIndex = 8
	votedivider.Parent = voteframe

	local function addVote(name, x, width, flipped)
		local button = Instance.new('TextButton')
		button.Name = name
		button.Size = UDim2.fromOffset(width, 30)
		button.Position = UDim2.fromOffset(x, 0)
		button.BackgroundColor3 = color.Light(uipallet.Main, 0.0875)
		button.BackgroundTransparency = 1
		button.AutoButtonColor = false
		button.Text = ''
		button.ZIndex = 7
		button.Parent = voteframe

		button.MouseEnter:Connect(function()
			tween:Tween(button, uipallet.Tween, {BackgroundTransparency = 0})
		end)
		button.MouseLeave:Connect(function()
			tween:Tween(button, uipallet.Tween, {BackgroundTransparency = 1})
		end)

		return button, addThumb(button, flipped)
	end

	local like, likethumb = addVote('Like', 0, 45, false)
	local dislike, dislikethumb = addVote('Dislike', 46, 46, true)

	local detailclose = addCloseButton(details, 12)
	detailclose.ZIndex = 6

	local uploader = makePanel('Uploader', 330, 646)
	uploader.BackgroundColor3 = uipallet.Main
	local uploadside = Instance.new('Frame')
	uploadside.Name = 'Sidebar'
	uploadside.Size = UDim2.fromOffset(215, 330)
	uploadside.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
	uploadside.BorderSizePixel = 0
	uploadside.ZIndex = 6
	uploadside.Parent = uploader
	addCorner(uploadside)

	local uploadtitle = Instance.new('TextLabel')
	uploadtitle.Size = UDim2.fromOffset(183, 24)
	uploadtitle.Position = UDim2.fromOffset(16, 16)
	uploadtitle.BackgroundTransparency = 1
	uploadtitle.Text = 'New Profile'
	uploadtitle.TextColor3 = Color3.new(1, 1, 1)
	uploadtitle.TextSize = 18
	uploadtitle.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	uploadtitle.TextXAlignment = Enum.TextXAlignment.Left
	uploadtitle.ZIndex = 7
	uploadtitle.Parent = uploadside

	local derived = Instance.new('TextLabel')
	derived.Size = UDim2.fromOffset(183, 16)
	derived.Position = UDim2.fromOffset(16, 46)
	derived.BackgroundTransparency = 1
	derived.RichText = true
	derived.Text = ''
	derived.TextColor3 = Color3.fromRGB(140, 140, 140)
	derived.TextSize = 11
	derived.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	derived.TextXAlignment = Enum.TextXAlignment.Left
	derived.TextTruncate = Enum.TextTruncate.AtEnd
	derived.ZIndex = 7
	derived.Parent = uploadside

	addRow(uploadside, 'Details', 80, true)

	local uploadcount = modulecount:Clone()
	uploadcount.Parent = uploadside
	local uploadmodules = Instance.new('ScrollingFrame')
	uploadmodules.Name = 'Modules'
	uploadmodules.Size = UDim2.fromOffset(215, 178)
	uploadmodules.Position = UDim2.fromOffset(0, 148)
	uploadmodules.BackgroundTransparency = 1
	uploadmodules.BorderSizePixel = 0
	uploadmodules.ScrollBarThickness = 0
	uploadmodules.CanvasSize = UDim2.new()
	uploadmodules.ZIndex = 7
	uploadmodules.Parent = uploadside
	local uploadlayout = Instance.new('UIListLayout')
	uploadlayout.SortOrder = Enum.SortOrder.LayoutOrder
	uploadlayout.Padding = UDim.new(0, 0)
	uploadlayout.Parent = uploadmodules

	local function addCaption(parent, text, y)
		local caption = Instance.new('TextLabel')
		caption.Size = UDim2.fromOffset(300, 14)
		caption.Position = UDim2.fromOffset(231, y)
		caption.BackgroundTransparency = 1
		caption.Text = text
		caption.TextColor3 = Color3.fromRGB(140, 140, 140)
		caption.TextSize = 11
		caption.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		caption.TextXAlignment = Enum.TextXAlignment.Left
		caption.ZIndex = 6
		caption.Parent = parent
		return caption
	end

	local function addInput(parent, placeholder, y)
		local box = Instance.new('TextBox')
		box.Size = UDim2.fromOffset(390, 26)
		box.Position = UDim2.fromOffset(231, y)
		box.BackgroundTransparency = 1
		box.Text = ''
		box.PlaceholderText = placeholder
		box.PlaceholderColor3 = Color3.fromRGB(94, 94, 94)
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextColor3 = uipallet.Text
		box.TextSize = 14
		box.FontFace = uipallet.Font
		box.ClearTextOnFocus = false
		box.ZIndex = 6
		box.Parent = parent
		local line = Instance.new('Frame')
		line.Size = UDim2.fromOffset(390, 1)
		line.Position = UDim2.fromOffset(231, y + 30)
		line.BackgroundColor3 = Color3.new(1, 1, 1)
		line.BackgroundTransparency = 0.93
		line.BorderSizePixel = 0
		line.ZIndex = 6
		line.Parent = parent
		return box
	end

	addCaption(uploader, 'NAME', 24)
	local namebox = addInput(uploader, 'Enter profile name...', 42)
	addCaption(uploader, 'DESCRIPTION', 90)
	local descbox = addInput(uploader, 'Add Description (optional)', 108)
	addCaption(uploader, 'PREFERENCES', 156)

	local anonlabel = Instance.new('TextLabel')
	anonlabel.Size = UDim2.fromOffset(300, 20)
	anonlabel.Position = UDim2.fromOffset(231, 180)
	anonlabel.BackgroundTransparency = 1
	anonlabel.Text = 'Upload anonymously'
	anonlabel.TextColor3 = uipallet.Text
	anonlabel.TextSize = 13
	anonlabel.FontFace = uipallet.Font
	anonlabel.TextXAlignment = Enum.TextXAlignment.Left
	anonlabel.ZIndex = 6
	anonlabel.Parent = uploader

	local function addToggle(parent, y)
		local toggleapi = {Enabled = false}

		local button = Instance.new('TextButton')
		button.Size = UDim2.fromOffset(34, 18)
		button.Position = UDim2.fromOffset(587, y)
		button.BackgroundColor3 = color.Light(uipallet.Main, 0.06)
		button.AutoButtonColor = false
		button.Text = ''
		button.ZIndex = 6
		button.Parent = parent
		addCorner(button, UDim.new(1, 0))
		local knob = Instance.new('Frame')
		knob.Size = UDim2.fromOffset(14, 14)
		knob.Position = UDim2.fromOffset(2, 2)
		knob.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
		knob.BorderSizePixel = 0
		knob.ZIndex = 7
		knob.Parent = button
		addCorner(knob, UDim.new(1, 0))

		function toggleapi:Set(state)
			self.Enabled = state
			tween:Tween(knob, uipallet.Tween, {
				Position = UDim2.fromOffset(state and 18 or 2, 2),
				BackgroundColor3 = state and accentColor() or Color3.fromRGB(140, 140, 140)
			})
		end

		button.MouseButton1Click:Connect(function()
			toggleapi:Set(not toggleapi.Enabled)
		end)

		return toggleapi
	end

	local anontoggle = addToggle(uploader, 181)

	local confirm = makeAction(uploader, 'PUBLISH', true, 276, 120, 501)
	local cancel = makeAction(uploader, 'CANCEL', false, 276, 100, 391)
	cancel.BackgroundTransparency = 1
	cancel.TextSize = 12
	local uploadclose = addCloseButton(uploader, 12)
	uploadclose.ZIndex = 6

	local editor = makePanel('Editor', 330, 646)
	editor.BackgroundColor3 = uipallet.Main
	local editorside = Instance.new('Frame')
	editorside.Name = 'Sidebar'
	editorside.Size = UDim2.fromOffset(215, 330)
	editorside.BackgroundColor3 = uipallet.Main
	editorside.BorderSizePixel = 0
	editorside.ZIndex = 6
	editorside.Parent = editor
	addCorner(editorside)

	local editortitle = uploadtitle:Clone()
	editortitle.Text = ''
	editortitle.Parent = editorside

	local editorderived = Instance.new('TextButton')
	editorderived.Name = 'Derived'
	editorderived.Size = UDim2.fromOffset(183, 16)
	editorderived.Position = UDim2.fromOffset(16, 46)
	editorderived.BackgroundTransparency = 1
	editorderived.AutoButtonColor = false
	editorderived.RichText = true
	editorderived.Text = ''
	editorderived.TextColor3 = Color3.fromRGB(140, 140, 140)
	editorderived.TextSize = 11
	editorderived.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	editorderived.TextXAlignment = Enum.TextXAlignment.Left
	editorderived.TextTruncate = Enum.TextTruncate.AtEnd
	editorderived.ZIndex = 7
	editorderived.Parent = editorside

	local selectEditorModule
	local editordetailsrow = addRow(editorside, 'Details', 80, true, function()
		selectEditorModule(nil)
	end)

	local editorcount = modulecount:Clone()
	editorcount.Parent = editorside
	local editormodules = Instance.new('ScrollingFrame')
	editormodules.Name = 'Modules'
	editormodules.Size = UDim2.fromOffset(215, 178)
	editormodules.Position = UDim2.fromOffset(0, 148)
	editormodules.BackgroundTransparency = 1
	editormodules.BorderSizePixel = 0
	editormodules.ScrollBarThickness = 0
	editormodules.CanvasSize = UDim2.new()
	editormodules.ZIndex = 7
	editormodules.Parent = editorside
	local editormoduleslayout = Instance.new('UIListLayout')
	editormoduleslayout.SortOrder = Enum.SortOrder.LayoutOrder
	editormoduleslayout.Padding = UDim.new(0, 0)
	editormoduleslayout.Parent = editormodules

	local editorsettings = Instance.new('Frame')
	editorsettings.Name = 'Settings'
	editorsettings.Size = UDim2.fromScale(1, 1)
	editorsettings.BackgroundTransparency = 1
	editorsettings.ZIndex = 6
	editorsettings.Parent = editor

	addCaption(editorsettings, 'DESCRIPTION', 24)
	local editordesc = addInput(editorsettings, 'Add Description (optional)', 42)
	addCaption(editorsettings, 'PREFERENCES', 90)

	local editoranonlabel = anonlabel:Clone()
	editoranonlabel.Position = UDim2.fromOffset(231, 114)
	editoranonlabel.Parent = editorsettings
	local editoranon = addToggle(editorsettings, 115)

	addCaption(editorsettings, 'STATS', 162)

	local editorstats = Instance.new('TextLabel')
	editorstats.Size = UDim2.fromOffset(390, 20)
	editorstats.Position = UDim2.fromOffset(231, 180)
	editorstats.BackgroundTransparency = 1
	editorstats.Text = ''
	editorstats.TextColor3 = uipallet.Text
	editorstats.TextSize = 13
	editorstats.FontFace = uipallet.Font
	editorstats.TextXAlignment = Enum.TextXAlignment.Left
	editorstats.ZIndex = 6
	editorstats.Parent = editorsettings

	local editormoduletitle = moduletitle:Clone()
	editormoduletitle.Parent = editor

	local editoroptions = Instance.new('ScrollingFrame')
	editoroptions.Name = 'Options'
	editoroptions.Size = UDim2.fromOffset(400, 208)
	editoroptions.Position = UDim2.fromOffset(231, 52)
	editoroptions.BackgroundTransparency = 1
	editoroptions.BorderSizePixel = 0
	editoroptions.ScrollBarThickness = 0
	editoroptions.CanvasSize = UDim2.new()
	editoroptions.Visible = false
	editoroptions.ZIndex = 6
	editoroptions.Parent = editor
	local editoroptionslayout = Instance.new('UIListLayout')
	editoroptionslayout.SortOrder = Enum.SortOrder.LayoutOrder
	editoroptionslayout.Padding = UDim.new(0, 0)
	editoroptionslayout.Parent = editoroptions

	local update = makeAction(editor, 'UPDATE', true, 276, 120, 501)
	local editorcancel = makeAction(editor, 'CANCEL', false, 276, 100, 391)
	editorcancel.BackgroundTransparency = 1
	editorcancel.TextSize = 12
	local editorremove = makeAction(editor, 'REMOVE', false, 276, 100, 231)
	editorremove.BackgroundTransparency = 1
	editorremove.TextColor3 = Color3.fromRGB(220, 90, 90)
	editorremove.TextSize = 12
	editorremove.TextXAlignment = Enum.TextXAlignment.Left
	local editorclose = addCloseButton(editor, 12)
	editorclose.ZIndex = 6

	local sourcemenu, sourcecatcher, sourceaction

	local function setSourceMenu(state)
		if not sourcemenu then return end
		sourcemenu.Visible = state
		sourcecatcher.Visible = state
	end

	local function showPanel(panel)
		overlay.Visible = panel ~= nil
		details.Visible = panel == details
		uploader.Visible = panel == uploader
		editor.Visible = panel == editor
		setSourceMenu(false)
	end

	local editing
	local editorsource
	local openEditor
	local selected
	local dislikes = {}
	local voting = false

	local function paintThumb(thumb, tint)
		for _, part in thumb:GetChildren() do
			if part:IsA('Frame') then
				tween:Tween(part, uipallet.Tween, {BackgroundColor3 = tint})
			end
		end
	end

	local function renderVotes(entry)
		likesvalue.Text = tostring(entry.likes or 0)
		paintThumb(likethumb, entry.liked and accentColor() or Color3.fromRGB(171, 171, 171))
		paintThumb(dislikethumb, dislikes[entry.filename] and Color3.fromRGB(220, 90, 90) or Color3.fromRGB(171, 171, 171))
	end

	local function sendLike(entry, wanted)
		local liked, likes = entry.liked, entry.likes or 0
		entry.liked = wanted
		entry.likes = math.max(likes + (wanted and 1 or -1), 0)
		voting = true
		renderVotes(entry)

		task.spawn(function()
			local res = request({
				Url = 'https://api.catvape.dev/configs/like',
				Method = 'POST',
				Headers = {
					['Content-Type'] = 'application/json'
				},
				Body = httpService:JSONEncode({
					key = license.Key or '_key',
					filename = entry.filename,
					like = wanted
				})
			})
			voting = false

			if res and res.Body then
				local body = httpService:JSONDecode(httpService:JSONDecode(res.Body).response)
				entry.liked = body.liked == true
				entry.likes = math.max(likes + ((entry.liked and 1 or 0) - (liked and 1 or 0)), 0)
			else
				entry.liked, entry.likes = liked, likes
				mainapi:CreateNotification('Cat', `Failed to {wanted and 'like' or 'unlike'} "{entry.Name}"`, 8, 'warning')
			end

			if selected == entry then
				renderVotes(entry)
			end
		end)
	end

	like.MouseButton1Click:Connect(function()
		if voting or not selected or not selected.filename then return end
		local entry = selected
		dislikes[entry.filename] = nil
		sendLike(entry, not entry.liked)
	end)

	dislike.MouseButton1Click:Connect(function()
		if voting or not selected or not selected.filename then return end
		local entry = selected
		local disliked = not dislikes[entry.filename]
		dislikes[entry.filename] = disliked or nil

		if disliked and entry.liked then
			sendLike(entry, false)
			return
		end
		renderVotes(entry)
	end)

	local function addCard(entry)
		local name = entry.Name
		local author = entry.Author

		local card = Instance.new('TextButton')
		card.Name = name
		card.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		card.AutoButtonColor = false
		card.Text = ''
		card.Parent = children
		addCorner(card)
		local stroke = Instance.new('UIStroke')
		stroke.Transparency = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = color.Light(uipallet.Main, 0.034)
		stroke.Thickness = 2
		stroke.Parent = card
		local label = Instance.new('TextLabel')
		label.Size = UDim2.new(0.753427446, -16, 0.423529416, 20)
		label.Position = UDim2.fromOffset(16, 20)
		label.BackgroundTransparency = 1
		label.RichText = true
		label.Text = `{name}\n\n\n<font tr="0.7">@{author}</font>`
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextTransparency = 0.3
		label.TextSize = 13
		label.FontFace = uipallet.Font
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.Parent = card
		local badge = Instance.new('Frame')
		badge.Size = UDim2.fromOffset(72, 22)
		badge.Position = UDim2.fromOffset(16, 104)
		badge.BackgroundColor3 = color.Light(uipallet.Main, 0.06)
		badge.Parent = card
		addCorner(badge, UDim.new(1, 0))
		local badgetext = Instance.new('TextLabel')
		badgetext.Size = UDim2.fromScale(1, 1)
		badgetext.BackgroundTransparency = 1
		badgetext.Text = relativeDays(entry.Uploaded)
		badgetext.TextColor3 = Color3.fromRGB(171, 171, 171)
		badgetext.TextSize = 11
		badgetext.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		badgetext.Parent = badge

		card.MouseEnter:Connect(function()
			tween:Tween(card, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.0875)})
			tweenService:Create(stroke, uipallet.Tween, {Transparency = 0}):Play()
		end)
		card.MouseLeave:Connect(function()
			tween:Tween(card, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.034)})
			tweenService:Create(stroke, uipallet.Tween, {Transparency = 1}):Play()
		end)
		card.MouseButton1Click:Connect(function()
			selected = entry
			detailname.Text = name
			detailauthor.Text = `By {author}`
			applyAvatar(avatar, entry.discord_pfp)
			created.Text = `Created: {entry.Uploaded and os.date('%b %d, %Y', entry.Uploaded) or 'unknown'}`
			updatedvalue.Text = relativeDays(entry.Uploaded)
			renderVotes(entry)
			detaildesc.Text = (entry.description and entry.description ~= '' and entry.description ~= 'unknown') and entry.description or 'No description provided'

			clearList(modulelist)

			local active = {}
			local decoded = entry.config and select(2, pcall(httpService.JSONDecode, httpService, entry.config))
			for module, data in (type(decoded) == 'table' and decoded.Modules or {}) do
				if type(data) == 'table' and data.Enabled then
					table.insert(active, tostring(module))
				end
			end
			table.sort(active)

			modulecount.Text = `<font color="rgb(255,255,255)">{#active}</font> AFFECTED MODULES`

			local rows = {}
			local function selectRow(chosen)
				for module, row in rows do
					local on = module == chosen
					row.BackgroundTransparency = on and 0 or 1
					row.TextLabel.TextColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(171, 171, 171)
				end
				detailsrow.BackgroundTransparency = chosen and 1 or 0
				detailsrow.TextLabel.TextColor3 = chosen and Color3.fromRGB(171, 171, 171) or Color3.new(1, 1, 1)

				if not chosen then
					showDetails(false)
					return
				end

				moduletitle.Text = chosen
				clearList(optionlist)

				local options = decoded.Modules[chosen].Options or {}
				local names = {}
				for option in pairs(options) do
					table.insert(names, tostring(option))
				end
				table.sort(names)
				for i, option in names do
					addOptionRow(optionlist, option, options[option], i)
				end
				optionlist.CanvasSize = UDim2.fromOffset(0, #names * 30)
				showDetails(true)
			end

			selectModule = selectRow
			for i, module in active do
				rows[module] = addRow(modulelist, module, 0, false, function()
					selectRow(module)
				end, i)
			end
			modulelist.CanvasSize = UDim2.fromOffset(0, #active * 34)
			selectRow(nil)

			showPanel(details)
		end)

		table.insert(publicapi.Cards, card)
	end

	local function clearCards()
		for _, card in publicapi.Cards do
			card:Destroy()
		end
		table.clear(publicapi.Cards)
	end

	local function showSkeletons()
		clearCards()
		empty.Visible = false

		for _ = 1, 6 do
			local card = Instance.new('Frame')
			card.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
			card.Parent = children
			addCorner(card)

			for _, shape in {{118, 16, 20}, {58, 12, 44}, {72, 22, 104}} do
				local bar = Instance.new('Frame')
				bar.Size = UDim2.fromOffset(shape[1], shape[2])
				bar.Position = UDim2.fromOffset(16, shape[3])
				bar.BackgroundColor3 = color.Light(uipallet.Main, 0.08)
				bar.BorderSizePixel = 0
				bar.Parent = card
				addCorner(bar, UDim.new(0, 4))
			end

			table.insert(publicapi.Cards, card)
		end
	end

	local function addOwned(entry, order)
		local row = Instance.new('TextButton')
		row.Name = entry.Name
		row.Size = UDim2.fromOffset(167, 32)
		row.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		row.BorderSizePixel = 0
		row.AutoButtonColor = false
		row.Text = ''
		row.LayoutOrder = order
		row.Parent = owned
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromOffset(143, 32)
		label.Position = UDim2.fromOffset(12, 0)
		label.BackgroundTransparency = 1
		label.Text = entry.Name
		label.TextColor3 = Color3.fromRGB(171, 171, 171)
		label.TextSize = 13
		label.FontFace = uipallet.Font
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Parent = row

		row.MouseEnter:Connect(function()
			tween:Tween(row, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.0875)})
			label.TextColor3 = Color3.new(1, 1, 1)
		end)
		row.MouseLeave:Connect(function()
			tween:Tween(row, uipallet.Tween, {BackgroundColor3 = color.Light(uipallet.Main, 0.034)})
			label.TextColor3 = Color3.fromRGB(171, 171, 171)
		end)
		row.MouseButton1Click:Connect(function()
			openEditor(entry)
		end)

		table.insert(publicapi.Owned, row)
	end

	local function renderOwned()
		for _, row in publicapi.Owned do
			row:Destroy()
		end
		table.clear(publicapi.Owned)

		local count = 0
		for _, entry in publicapi.Configs do
			if entry.mine then
				count += 1
				addOwned(entry, count)
			end
		end

		ownedempty.Visible = count == 0
		owned.CanvasSize = UDim2.fromOffset(0, count * 34)
	end

	local function render()
		clearCards()

		local filtered = {}
		local query = publicapi.Search:lower()
		for _, entry in publicapi.Configs do
			local name = entry.Name:lower()
			local author = entry.Author:lower()
			if query == '' or name:find(query, 1, true) or author:find(query, 1, true) then
				table.insert(filtered, entry)
			end
		end

		table.sort(filtered, sorts[publicapi.Sort])
		for _, entry in filtered do
			addCard(entry)
		end
		empty.Visible = #filtered == 0
	end

	local function refresh()
		showSkeletons()

		local res = request({
			Url = 'https://api.catvape.dev/configs/get',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json'
			},
			Body = httpService:JSONEncode({key = license.Key or '_key'})
		})
		local payload = res and res.Body and httpService:JSONDecode(httpService:JSONDecode(res.Body).response)
		local configs = payload and payload.configs
		table.clear(publicapi.Configs)
		publicapi.Viewer = payload and payload.viewer

		if configs then
			for _, v in configs do
				if v.config_name then
					v.Uploaded = parseTimestamp(v.uploaded_at)
					v.Name, v.Author = parseFilename(v)
					v.likes = tonumber(v.likes) or 0
					v.liked = v.liked == true
					v.mine = v.mine == true
					table.insert(publicapi.Configs, v)
				end
			end
		end
		renderOwned()
		render()
	end

	publicapi.Refresh = refresh

	local function addSort(name, label)
		local button = Instance.new('TextButton')
		button.Name = name
		button.Size = UDim2.new(0, 70, 1, 0)
		button.BackgroundColor3 = accentColor()
		button.BackgroundTransparency = publicapi.Sort == name and 0 or 1
		button.AutoButtonColor = false
		button.Text = (label or name):upper()
		button.TextColor3 = publicapi.Sort == name and accentTextColor() or Color3.new(1, 1, 1)
		button.TextTransparency = publicapi.Sort == name and 0 or 0.85
		button.TextSize = 10
		button.FontFace = Font.fromEnum(Enum.Font.ArialBold)
		button.Parent = sortframe
		addCorner(button, UDim.new(1, 0))
		table.insert(publicapi.Accents, button)

		button.MouseButton1Click:Connect(function()
			publicapi.Sort = name
			for _, other in sortframe:GetChildren() do
				if other:IsA('TextButton') then
					local on = other.Name == name
					other.BackgroundTransparency = on and 0 or 1
					other.TextColor3 = on and accentTextColor() or Color3.new(1, 1, 1)
					other.TextTransparency = on and 0 or 0.85
				end
			end
			render()
		end)
	end

	addSort('newest', 'Newest')
	addSort('oldest', 'Oldest')
	addSort('name', 'A - Z')

	searchbox:GetPropertyChangedSignal('Text'):Connect(function()
		publicapi.Search = searchbox.Text
		render()
	end)

	download.MouseButton1Click:Connect(function()
		if not selected then return end
		local entry = selected
		local content = entry.config or (entry.metadata and entry.metadata.content)
		if not content then
			mainapi:CreateNotification('Cat', `Could not fetch "{entry.Name}"`, 8, 'warning')
			return
		end

		local profile = `{entry.Name} (@{entry.Author})`
		table.insert(mainapi.Profiles, {Name = profile, Bind = {}})
		mainapi:Save(profile)
		writefile('catsix/profiles/'..profile..mainapi.Place..'.txt', content)
		mainapi:Load(true, profile)
		showPanel(nil)
		mainapi:CreateNotification('Cat', `Downloaded "{entry.Name}" by {entry.Author}`, 8, 'info')
	end)

	for _, v in {detailclose, uploadclose, cancel, overlay} do
		v.MouseButton1Click:Connect(showPanel)
	end

	sourcecatcher = Instance.new('TextButton')
	sourcecatcher.Name = 'CreateFromCatcher'
	sourcecatcher.Size = UDim2.fromScale(1, 1)
	sourcecatcher.BackgroundTransparency = 1
	sourcecatcher.AutoButtonColor = false
	sourcecatcher.Text = ''
	sourcecatcher.Visible = false
	sourcecatcher.ZIndex = 8
	sourcecatcher.Parent = window
	sourcecatcher.MouseButton1Click:Connect(function()
		local mouse = inputService:GetMouseLocation() - game:GetService('GuiService'):GetGuiInset()
		local origin, size = sourcemenu.AbsolutePosition, sourcemenu.AbsoluteSize
		if mouse.X >= origin.X and mouse.X <= origin.X + size.X and mouse.Y >= origin.Y and mouse.Y <= origin.Y + size.Y then
			return
		end
		setSourceMenu(false)
	end)

	sourcemenu = Instance.new('Frame')
	sourcemenu.Active = true
	sourcemenu.Name = 'CreateFrom'
	sourcemenu.Size = UDim2.fromOffset(216, 60)
	sourcemenu.Position = UDim2.fromOffset(96, 60)
	sourcemenu.BackgroundColor3 = accentColor()
	sourcemenu.BorderSizePixel = 0
	sourcemenu.Visible = false
	sourcemenu.ZIndex = 9
	sourcemenu.Parent = window
	addCorner(sourcemenu)
	table.insert(publicapi.Accents, sourcemenu)

	local sourcetitle = Instance.new('TextLabel')
	sourcetitle.Size = UDim2.new(1, 0, 0, 20)
	sourcetitle.Position = UDim2.fromOffset(0, 14)
	sourcetitle.BackgroundTransparency = 1
	sourcetitle.Text = 'Create from...'
	sourcetitle.TextColor3 = accentTextColor()
	sourcetitle.TextSize = 14
	sourcetitle.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	sourcetitle.ZIndex = 10
	sourcetitle.Parent = sourcemenu

	local sourcelist = Instance.new('ScrollingFrame')
	sourcelist.Size = UDim2.fromOffset(216, 20)
	sourcelist.Position = UDim2.fromOffset(0, 40)
	sourcelist.BackgroundTransparency = 1
	sourcelist.BorderSizePixel = 0
	sourcelist.ScrollBarThickness = 0
	sourcelist.CanvasSize = UDim2.new()
	sourcelist.ZIndex = 10
	sourcelist.Parent = sourcemenu
	local sourcelayout = Instance.new('UIListLayout')
	sourcelayout.SortOrder = Enum.SortOrder.LayoutOrder
	sourcelayout.Padding = UDim.new(0, 0)
	sourcelayout.Parent = sourcelist

	local function profileSource(profile)
		if not profile then
			mainapi:Save(mainapi.Profile)
		end

		local path = 'catsix/profiles/'..(profile or mainapi.Profile)..mainapi.Place..'.txt'
		return isfile(path) and readfile(path) or nil
	end

	local function openUploader(profile)
		setSourceMenu(false)
		namebox.Text = ''
		descbox.Text = ''
		anontoggle:Set(false)
		derived.Text = `DERIVED FROM <font color="rgb(255,255,255)">{profile or 'Current settings'}</font>`

		uploadsource = profileSource(profile)
		fillModules(uploadmodules, uploadcount, uploadsource)
		showPanel(uploader)
	end

	local editorrows, editordecoded = {}, nil

	function selectEditorModule(chosen)
		for module, row in editorrows do
			local on = module == chosen
			row.BackgroundTransparency = on and 0 or 1
			row.TextLabel.TextColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(171, 171, 171)
		end
		editordetailsrow.BackgroundTransparency = chosen and 1 or 0
		editordetailsrow.TextLabel.TextColor3 = chosen and Color3.fromRGB(171, 171, 171) or Color3.new(1, 1, 1)

		editorsettings.Visible = not chosen
		editormoduletitle.Visible = chosen ~= nil
		editoroptions.Visible = chosen ~= nil

		if not chosen then return end

		editormoduletitle.Text = chosen
		clearList(editoroptions)

		local options = editordecoded.Modules[chosen].Options or {}
		local names = {}
		for option in pairs(options) do
			table.insert(names, tostring(option))
		end
		table.sort(names)
		for i, option in names do
			addOptionRow(editoroptions, option, options[option], i)
		end
		editoroptions.CanvasSize = UDim2.fromOffset(0, #names * 30)
	end

	local function setEditorModules(source)
		editordecoded, editorrows = fillModules(editormodules, editorcount, source, selectEditorModule)
		selectEditorModule(nil)
	end

	local function setEditorSource(profile)
		setSourceMenu(false)
		editorsource = profileSource(profile)
		editorderived.Text = `DERIVED FROM <font color="rgb(255,255,255)">{profile or 'Current settings'}</font>`
		setEditorModules(editorsource)
	end

	function openEditor(entry)
		editing = entry
		editorsource = nil
		editortitle.Text = entry.Name
		editordesc.Text = (entry.description ~= 'unknown' and entry.description) or ''
		editorderived.Text = 'DERIVED FROM <font color="rgb(255,255,255)">Published copy</font>'
		editorstats.Text = `{entry.likes or 0} positive reviews    {entry.downloads or 0} downloads`
		editoranon:Set(entry.discord_username == 'unknown')

		setEditorModules(entry.config)
		showPanel(editor)
	end

	local function addSource(text, profile, order)
		local row = Instance.new('TextButton')
		row.Size = UDim2.fromOffset(216, 30)
		row.BackgroundColor3 = accentColor()
		row.BorderSizePixel = 0
		row.AutoButtonColor = true
		row.Text = ''
		row.LayoutOrder = order
		row.ZIndex = 10
		row.Parent = sourcelist
		local plus = Instance.new('TextLabel')
		plus.Size = UDim2.fromOffset(20, 30)
		plus.Position = UDim2.fromOffset(16, 0)
		plus.BackgroundTransparency = 1
		plus.Text = '+'
		plus.TextColor3 = accentTextColor()
		plus.TextSize = 16
		plus.FontFace = uipallet.Font
		plus.ZIndex = 11
		plus.Parent = row
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromOffset(160, 30)
		label.Position = UDim2.fromOffset(40, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = accentTextColor()
		label.TextSize = 13
		label.FontFace = uipallet.Font
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.ZIndex = 11
		label.Parent = row
		row.MouseButton1Click:Connect(function()
			sourceaction(profile)
		end)
		return row
	end

	local function showSourceMenu(action, title, x, y)
		sourceaction = action

		for _, old in sourcelist:GetChildren() do
			if old:IsA('TextButton') or old:IsA('TextLabel') then
				old:Destroy()
			end
		end

		sourcetitle.Text = title
		sourcetitle.TextColor3 = accentTextColor()
		addSource('Current settings', nil, 1)

		local caption = Instance.new('TextLabel')
		caption.Size = UDim2.fromOffset(216, 24)
		caption.BackgroundTransparency = 1
		caption.Text = '      PRIVATE PROFILES'
		caption.TextColor3 = accentTextColor()
		caption.TextTransparency = 0.35
		caption.TextSize = 11
		caption.FontFace = Font.new('rbxasset://fonts/families/Arial.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		caption.TextXAlignment = Enum.TextXAlignment.Left
		caption.LayoutOrder = 2
		caption.ZIndex = 11
		caption.Parent = sourcelist

		local count = 0
		for _, profile in mainapi.Profiles do
			count += 1
			addSource(profile.Name, profile.Name, 2 + count)
		end

		local height = 30 + 24 + count * 30
		sourcelist.Size = UDim2.fromOffset(216, math.min(height, 210))
		sourcelist.CanvasSize = UDim2.fromOffset(0, height)
		sourcemenu.Size = UDim2.fromOffset(216, 40 + math.min(height, 210) + 10)
		sourcemenu.Position = UDim2.fromOffset(x, y)
		setSourceMenu(true)
	end

	publish.MouseButton1Click:Connect(function()
		showSourceMenu(openUploader, 'Create from...', 96, 60)
	end)

	editorderived.MouseButton1Click:Connect(function()
		showSourceMenu(setEditorSource, 'Update from...', 43, 96)
	end)

	confirm.MouseButton1Click:Connect(function()
		if namebox.Text == '' then
			mainapi:CreateNotification('Cat', 'No profile name provided', 5, 'warning')
			return
		end

		if not uploadsource then
			mainapi:CreateNotification('Cat', 'That profile has no saved settings yet', 8, 'warning')
			return
		end

		showPanel(nil)
		mainapi:CreateNotification('Cat', 'Publishing profile', 5, 'info')

		local res = request({
			Url = 'https://api.catvape.dev/configs/set',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json'
			},
			Body = httpService:JSONEncode({
				key = license.Key or '_key',
				config_name = namebox.Text,
				config = uploadsource,
				description = descbox.Text,
				anonymous = anontoggle.Enabled
			})
		})

		if res and res.Body then
			mainapi:CreateNotification('Cat', `Published "{namebox.Text}"`, 10, 'info')
			refresh()
		else
			mainapi:CreateNotification('Cat', 'Failed to publish profile', 10, 'warning')
		end
	end)

	update.MouseButton1Click:Connect(function()
		if not editing then return end
		local entry = editing
		local content = editorsource or entry.config

		if not content then
			mainapi:CreateNotification('Cat', `Could not read the settings for "{entry.Name}"`, 8, 'warning')
			return
		end

		showPanel(nil)
		mainapi:CreateNotification('Cat', `Updating "{entry.Name}"`, 5, 'info')

		local res = request({
			Url = 'https://api.catvape.dev/configs/set',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json'
			},
			Body = httpService:JSONEncode({
				key = license.Key or '_key',
				config_name = entry.config_name,
				config = content,
				description = editordesc.Text,
				anonymous = editoranon.Enabled
			})
		})

		if res and res.Body then
			mainapi:CreateNotification('Cat', `Updated "{entry.Name}"`, 10, 'info')
			refresh()
		else
			mainapi:CreateNotification('Cat', `Failed to update "{entry.Name}"`, 10, 'warning')
		end
	end)

	editorremove.MouseButton1Click:Connect(function()
		if not editing then return end
		local entry = editing

		showPanel(nil)
		local res = request({
			Url = 'https://api.catvape.dev/configs/delete',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json'
			},
			Body = httpService:JSONEncode({
				key = license.Key or '_key',
				config_name = entry.config_name
			})
		})
		local body = res and res.Body and httpService:JSONDecode(httpService:JSONDecode(res.Body).response)

		if body and body.success then
			mainapi:CreateNotification('Cat', `Removed "{entry.Name}"`, 8, 'info')
			refresh()
		else
			mainapi:CreateNotification('Cat', `Failed to remove "{entry.Name}"`, 8, 'warning')
		end
	end)

	editorcancel.MouseButton1Click:Connect(function()
		showPanel(nil)
	end)
	editorclose.MouseButton1Click:Connect(function()
		showPanel(nil)
	end)

	close.MouseButton1Click:Connect(function()
		window.Visible = false
		clickgui.Visible = true
	end)

	local loading = false
	window:GetPropertyChangedSignal('Visible'):Connect(function()
		self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
		if window.Visible and not loading then
			loading = true
			task.spawn(function()
				refresh()
				loading = false
			end)
		end
	end)
	gridlayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, gridlayout.AbsoluteContentSize.Y / scale.Scale)
	end)

	showPanel(nil)
	self.PublicProfiles = publicapi

	return publicapi
end

function mainapi:CreateChangelogs()
	local changelogapi = {}

	local window = Instance.new('Frame')
	window.Name = 'ChangelogsGUI'
	window.Size = UDim2.fromOffset(700, 389)
	window.Position = UDim2.new(0.5, -350, 0.5, -194)
	window.BackgroundColor3 = uipallet.Main
	window.Visible = false
	window.Parent = scaledgui
	addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local modal = Instance.new('TextButton')
	modal.BackgroundTransparency = 1
	modal.Text = ''
	modal.Modal = true
	modal.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -47, 0, 20)
	title.Position = UDim2.fromOffset(12, 10)
	title.BackgroundTransparency = 1
	title.Text = 'Changelogs'
	title.TextColor3 = Color3.fromRGB(200, 200, 200)
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Top
	title.Parent = window
	local status = Instance.new('TextLabel')
	status.Name = 'Status'
	status.Size = UDim2.fromOffset(250, 16)
	status.Position = UDim2.new(1, -295, 0, 13)
	status.BackgroundTransparency = 1
	status.Text = ''
	status.TextColor3 = color.Dark(uipallet.Text, 0.43)
	status.TextSize = 11
	status.FontFace = uipallet.Font
	status.TextXAlignment = Enum.TextXAlignment.Right
	status.Parent = window
	local close = addCloseButton(window)
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 0.102827765, 0)
	divider.BorderSizePixel = 0
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.95
	divider.Parent = window

	local notes = Instance.new('Frame')
	notes.Name = 'Notes'
	notes.Size = UDim2.fromOffset(680, 325)
	notes.Position = UDim2.fromOffset(10, 52)
	notes.BackgroundColor3 = color.Dark(uipallet.Main, 0.025)
	notes.BorderSizePixel = 0
	notes.Parent = window
	addCorner(notes)
	local notesstroke = Instance.new('UIStroke')
	notesstroke.Color = Color3.fromRGB(42, 41, 42)
	notesstroke.Parent = notes
	local noteslist = Instance.new('ScrollingFrame')
	noteslist.Name = 'Children'
	noteslist.Size = UDim2.fromOffset(680, 303)
	noteslist.Position = UDim2.fromOffset(0, 11)
	noteslist.BackgroundTransparency = 1
	noteslist.BorderSizePixel = 0
	noteslist.ScrollBarThickness = 2
	noteslist.ScrollBarImageTransparency = 0.75
	noteslist.CanvasSize = UDim2.new()
	noteslist.Parent = notes
	local notespadding = Instance.new('UIPadding')
	notespadding.PaddingLeft = UDim.new(0, 14)
	notespadding.Parent = noteslist
	local body = Instance.new('TextLabel')
	body.Name = 'Body'
	body.Size = UDim2.fromOffset(652, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.BackgroundTransparency = 1
	body.RichText = true
	body.Text = ''
	body.TextColor3 = Color3.fromRGB(150, 150, 150)
	body.TextSize = 12
	body.LineHeight = 1.25
	body.FontFace = Font.fromEnum(Enum.Font.Roboto)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.Parent = noteslist

	local empty = Instance.new('TextLabel')
	empty.Name = 'Empty'
	empty.Size = UDim2.fromOffset(680, 20)
	empty.Position = UDim2.fromOffset(10, 205)
	empty.BackgroundTransparency = 1
	empty.Text = 'No changelogs found'
	empty.TextColor3 = Color3.fromRGB(171, 171, 171)
	empty.TextSize = 12
	empty.FontFace = uipallet.Font
	empty.Visible = false
	empty.Parent = window

	changelogapi.Window = window

	local graphemes = 0

	local function render()
		local features = loadFeatures()
		local added = features and type(features.added) == 'table' and features.added or {}
		local updated = features and type(features.updated) == 'table' and features.updated or {}
		local text = features and type(features.text) == 'string' and features.text or ''
		local commit = isfile('catsix/profiles/commit.txt') and readfile('catsix/profiles/commit.txt'):sub(1, 7) or ''

		graphemes = utf8.len(text) or #text
		body.Text = text ~= '' and formatNotes(text) or ''
		status.Text = `{#added} added, {#updated} updated`..(commit ~= '' and '  ·  '..commit or '')
		notes.Visible = text ~= ''
		empty.Visible = text == ''
	end

	local function revealBody()
		local duration = math.clamp(graphemes / 1500, 0.1, 3)
		warn(duration)
		tween:Cancel(body)
		body.MaxVisibleGraphemes = 0
		tween:Tween(body, TweenInfo.new(duration, Enum.EasingStyle.Linear), {MaxVisibleGraphemes = graphemes})
		task.delay(duration, function()
			body.MaxVisibleGraphemes = -1
		end)
	end

	changelogapi.Refresh = render

	close.MouseButton1Click:Connect(function()
		window.Visible = false
		self:PromptPresets()
	end)
	body:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		noteslist.CanvasSize = UDim2.fromOffset(0, body.AbsoluteSize.Y / scale.Scale)
	end)

	local loaded, revealed = false, false

	function changelogapi:Open()
		if not loaded then
			loaded = true
			render()
		end

		window.Position = UDim2.new(0.5, -350, 0.5, -194)
		window.Visible = true
		noteslist.CanvasPosition = Vector2.zero

		if not revealed and notes.Visible then
			revealed = true
			revealBody()
		end
	end

	if shared.updated then
		local function showUpdate()
			task.wait(0.5)
			loaded = true
			render()
			if empty.Visible then return end

			changelogapi:Open()
			self:CreateNotification('Cat', `Script updated from {shared.updated:sub(1, 7)}, here is what changed`, 10, 'info')
		end

		local pending
		pending = clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
			if not clickgui.Visible then return end
			pending:Disconnect()
			task.spawn(showUpdate)
		end)
		mainapi:Clean(pending)

		if clickgui.Visible then
			pending:Disconnect()
			task.spawn(showUpdate)
		end
	end

	self.Changelogs = changelogapi

	return changelogapi
end

function mainapi:CreateNotification(title, text, duration, type)
	if not self.Notifications.Enabled then return end
	task.delay(0, function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		local i = #notifications:GetChildren() + 1
		local notification = Instance.new('ImageLabel')
		notification.Name = 'Notification'
		notification.Size = UDim2.fromOffset(math.max(getfontsize(removeTags(text), 14, uipallet.Font).X + 80, 266), 75)
		notification.Position = UDim2.new(1, 0, 1, -(29 + (78 * i)))
		notification.ZIndex = 5
		notification.BackgroundTransparency = 1
		notification.Image = getcustomasset('catsix/assets/new/notification.png')
		notification.ScaleType = Enum.ScaleType.Slice
		notification.SliceCenter = Rect.new(7, 7, 9, 9)
		notification.Parent = notifications
		addBlur(notification, true)
		local iconshadow = Instance.new('ImageLabel')
		iconshadow.Name = 'Icon'
		iconshadow.Size = UDim2.fromOffset(60, 60)
		iconshadow.Position = UDim2.fromOffset(-5, -8)
		iconshadow.ZIndex = 5
		iconshadow.BackgroundTransparency = 1
		iconshadow.Image = getcustomasset('catsix/assets/new/'..(type or 'info')..'.png')
		iconshadow.ImageColor3 = Color3.new()
		iconshadow.ImageTransparency = 0.5
		iconshadow.Parent = notification
		local icon = iconshadow:Clone()
		icon.Position = UDim2.fromOffset(-1, -1)
		icon.ImageColor3 = Color3.new(1, 1, 1)
		icon.ImageTransparency = 0
		icon.Parent = iconshadow
		local titlelabel = Instance.new('TextLabel')
		titlelabel.Name = 'Title'
		titlelabel.Size = UDim2.new(1, -56, 0, 20)
		titlelabel.Position = UDim2.fromOffset(46, 16)
		titlelabel.ZIndex = 5
		titlelabel.BackgroundTransparency = 1
		titlelabel.Text = "<stroke color='#FFFFFF' joins='round' thickness='0.3' transparency='0.5'>"..title..'</stroke>'
		titlelabel.TextXAlignment = Enum.TextXAlignment.Left
		titlelabel.TextYAlignment = Enum.TextYAlignment.Top
		titlelabel.TextColor3 = Color3.fromRGB(209, 209, 209)
		titlelabel.TextSize = 14
		titlelabel.RichText = true
		titlelabel.FontFace = uipallet.FontSemiBold
		titlelabel.Parent = notification
		local textshadow = titlelabel:Clone()
		textshadow.Name = 'Text'
		textshadow.Position = UDim2.fromOffset(47, 44)
		textshadow.Text = removeTags(text)
		textshadow.TextColor3 = Color3.new()
		textshadow.TextTransparency = 0.5
		textshadow.RichText = false
		textshadow.FontFace = uipallet.Font
		textshadow.Parent = notification
		local textlabel = textshadow:Clone()
		textlabel.Position = UDim2.fromOffset(-1, -1)
		textlabel.Text = text
		textlabel.TextColor3 = Color3.fromRGB(170, 170, 170)
		textlabel.TextTransparency = 0
		textlabel.RichText = true
		textlabel.Parent = textshadow
		local progress = Instance.new('Frame')
		progress.Name = 'Progress'
		progress.Size = UDim2.new(1, -13, 0, 2)
		progress.Position = UDim2.new(0, 3, 1, -4)
		progress.ZIndex = 5
		progress.BackgroundColor3 =
			type == 'alert' and Color3.fromRGB(250, 50, 56)
			or type == 'warning' and Color3.fromRGB(236, 129, 43)
			or Color3.fromRGB(220, 220, 220)
		progress.BorderSizePixel = 0
		progress.Parent = notification
		if tween.Tween then
			tween:Tween(notification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
				AnchorPoint = Vector2.new(1, 0)
			}, tween.tweenstwo)
			tween:Tween(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
				Size = UDim2.fromOffset(0, 2)
			})
		end
		task.delay(duration, function()
			if tween.Tween then
				tween:Tween(notification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
					AnchorPoint = Vector2.new(0, 0)
				}, tween.tweenstwo)
			end
			task.wait(0.2)
			notification:ClearAllChildren()
			notification:Destroy()
		end)
	end)
end

function mainapi:CreatePrompt(promptsettings)
	local answered = false
	local shadow = Instance.new('TextButton')
	shadow.Name = 'PromptShadow'
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.ZIndex = 10
	shadow.BackgroundColor3 = Color3.new()
	shadow.BackgroundTransparency = 0.6
	shadow.AutoButtonColor = false
	shadow.Modal = true
	shadow.Text = ''
	shadow.Parent = clickgui
	local window = Instance.new('Frame')
	window.Name = 'Prompt'
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Size = UDim2.fromOffset(360, promptsettings.Dismiss and 218 or 178)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.ZIndex = 11
	window.BackgroundColor3 = uipallet.Main
	window.Parent = shadow
	addCorner(window)
	addBlur(window)
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = UDim2.fromOffset(16, 16)
	icon.Position = UDim2.fromOffset(20, 20)
	icon.ZIndex = 12
	icon.BackgroundTransparency = 1
	icon.Image = getcustomasset('catsix/assets/new/'..(promptsettings.Icon or 'vape')..'.png')
	icon.ImageColor3 = promptsettings.Icon and uipallet.Text or Color3.new(1, 1, 1)
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -60, 0, 16)
	title.Position = UDim2.fromOffset(44, 20)
	title.ZIndex = 12
	title.BackgroundTransparency = 1
	title.Text = promptsettings.Title or 'Vape'
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 14
	title.FontFace = uipallet.FontSemiBold
	title.Parent = window
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, -40, 0, 1)
	divider.Position = UDim2.fromOffset(20, 48)
	divider.ZIndex = 12
	divider.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
	divider.BorderSizePixel = 0
	divider.Parent = window
	local text = Instance.new('TextLabel')
	text.Name = 'Text'
	text.Size = UDim2.new(1, -40, 0, 62)
	text.Position = UDim2.fromOffset(20, 62)
	text.ZIndex = 12
	text.BackgroundTransparency = 1
	text.Text = promptsettings.Text or ''
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextColor3 = color.Dark(uipallet.Text, 0.31)
	text.TextSize = 13
	text.TextWrapped = true
	text.RichText = true
	text.FontFace = uipallet.Font
	text.Parent = window

	local function answer(result)
		if answered then return end
		answered = true
		shadow:ClearAllChildren()
		shadow:Destroy()
		if promptsettings.Function then
			promptsettings.Function(result)
		end
	end

	local function createButton(name, label, offset, width, bottom, accent)
		local button = Instance.new('TextButton')
		button.Name = name
		button.Size = UDim2.fromOffset(width, 32)
		button.Position = UDim2.new(0, offset, 1, -bottom)
		button.ZIndex = 12
		button.BackgroundColor3 = accent
			and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
			or color.Light(uipallet.Main, 0.02)
		button.AutoButtonColor = false
		button.Text = label
		button.TextColor3 = accent
			and mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
			or color.Dark(uipallet.Text, 0.16)
		button.TextSize = 13
		button.FontFace = uipallet.FontSemiBold
		button.Parent = window
		addCorner(button, UDim.new(0, 6))
		button.MouseEnter:Connect(function()
			tween:Tween(button, uipallet.Tween, {
				BackgroundColor3 = accent
					and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, math.clamp(mainapi.GUIColor.Value + 0.1, 0, 1))
					or color.Light(uipallet.Main, 0.14)
			})
		end)
		button.MouseLeave:Connect(function()
			tween:Tween(button, uipallet.Tween, {
				BackgroundColor3 = accent
					and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
					or color.Light(uipallet.Main, 0.02)
			})
		end)
		return button
	end

	local row = promptsettings.Dismiss and 88 or 48
	createButton('Cancel', promptsettings.Cancel or 'No', 20, 158, row, false).MouseButton1Click:Connect(function()
		answer(false)
	end)
	createButton('Confirm', promptsettings.Confirm or 'Yes', 182, 158, row, true).MouseButton1Click:Connect(function()
		answer(true)
	end)
	if promptsettings.Dismiss then
		createButton('Dismiss', promptsettings.Dismiss, 20, 320, 48, false).MouseButton1Click:Connect(function()
			answer('dismiss')
		end)
	end
	return answer
end

function mainapi:Load(skipgui, profile)
	if not skipgui then
		self.GUIColor:SetValue(nil, nil, nil, 4)
	end
	local guidata = {}
	local savecheck = true
	local savenew

	if isfile('catsix/profiles/'..game.GameId..'.gui.txt') then
		guidata = loadJson('catsix/profiles/'..game.GameId..'.gui.txt')
		if not guidata then
			guidata = {Categories = {}}
			self:CreateNotification('Vape', 'Failed to load GUI settings.', 10, 'alert')
			savecheck = false
		end

		if not skipgui then
			self.Keybind = guidata.Keybind
			for i, v in guidata.Categories do
				local object = self.Categories[i]
				if not object then continue end
				if object.Options and v.Options then
					self:LoadOptions(object, v.Options)
					if shared.vapesmooth then
						task.wait()
					end
				end
				if v.Enabled then
					object.Button:Toggle()
				end
				if v.Pinned then
					object:Pin()
				end
				if v.Expanded and object.Expand then
					object:Expand()
				end
				if v.List and (#object.List > 0 or #v.List > 0) then
					object.List = v.List or {}
					object.ListEnabled = v.ListEnabled or {}
					object:ChangeValue()
				end
				if v.Position then
					object.Object.Position = UDim2.fromOffset(v.Position.X, v.Position.Y)
				end
			end
		end
	end

	self.Profile = profile or guidata.Profile or 'default'
	self.Profiles = guidata.Profiles or {{
		Name = 'default', Bind = {}
	}}
	self.Categories.Profiles:ChangeValue()
	if self.ProfileLabel then
		self.ProfileLabel.Text = #self.Profile > 10 and self.Profile:sub(1, 10)..'...' or self.Profile
		self.ProfileLabel.Size = UDim2.fromOffset(getfontsize(self.ProfileLabel.Text, self.ProfileLabel.TextSize, self.ProfileLabel.Font).X + 16, 24)
	end

	if isfile('catsix/profiles/'..self.Profile..self.Place..'.txt') then
		local savedata = loadJson('catsix/profiles/'..self.Profile..self.Place..'.txt')
		if not savedata then
			savedata = {Categories = {}, Modules = {}, Legit = {}}
			self:CreateNotification('Vape', 'Failed to load '..self.Profile..' profile.', 10, 'alert')
			savecheck = false
		end

		for i, v in savedata.Categories do
			local object = self.Categories[i]
			if not object then continue end
			if object.Options and v.Options then
				self:LoadOptions(object, v.Options)
				if shared.vapesmooth then
					task.wait()
				end
			end
			if v.Pinned ~= object.Pinned then
				object:Pin()
			end
			if v.Expanded ~= nil and v.Expanded ~= object.Expanded then
				object:Expand()
			end
			if object.Button and (v.Enabled or false) ~= object.Button.Enabled then
				object.Button:Toggle()
			end
			if v.List and (#object.List > 0 or #v.List > 0) then
				object.List = v.List or {}
				object.ListEnabled = v.ListEnabled or {}
				object:ChangeValue()
			end
			object.Object.Position = UDim2.fromOffset(v.Position.X, v.Position.Y)
		end

		local modulelookup, legitlookup = {}, {}
		for i, v in self.Modules do
			modulelookup[i:gsub(' ', '')] = v
		end
		for i, v in self.Legit.Modules do
			legitlookup[i:gsub(' ', '')] = v
		end

		for i, v in savedata.Modules do
			i = i:gsub(' ', '')
			local object = modulelookup[i]
			if not object then continue end
			if object.Options and v.Options then
				self:LoadOptions(object, v.Options)
				if shared.vapesmooth then
					task.wait()
				end
			end
			if v.Enabled ~= object.Enabled then
				if skipgui then
					if self.ToggleNotifications.Enabled then 
						mainapi:CreateNotification(i, (not v.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>"), 0.75)
					end
				end
				object:Toggle(true)
				if shared.vapesmooth then
					task.wait()
				end
			end
			object:SetBind(v.Bind)
			object.Object.Bind.Visible = #v.Bind > 0
		end

		for i, v in savedata.Legit do
			i = i:gsub(' ', '')
			local object = legitlookup[i]
			if not object then continue end
			if object.Options and v.Options then
				self:LoadOptions(object, v.Options)
				if shared.vapesmooth then
					task.wait()
				end
			end
			if object.Enabled ~= v.Enabled then
				object:Toggle()
				if shared.vapesmooth then
					task.wait()
				end
			end
			if v.Position and object.Children then
				object.Children.Position = UDim2.fromOffset(v.Position.X, v.Position.Y)
			end
		end

		self:UpdateTextGUI(true)
	else
		savenew = true
	end

	if self.Downloader then
		self.Downloader:Destroy()
		self.Downloader = nil
	end
	self.Loaded = savecheck
	self.Categories.Main.Options.Bind:SetBind(self.Keybind)

	if savenew then
		self:Save()
	end

	if not inputService.KeyboardEnabled or shared.VapeDeveloper then
		local hide = isfile('catsix/profiles/hide.txt') and readfile('catsix/profiles/hide.txt') or nil
		if hide ~= nil then
			hide = hide == 'true' and true or false
		end
		local button = Instance.new('TextButton')
		button.LayoutOrder = -1
		button.Size = UDim2.fromOffset(32, 32)
		button.Position = UDim2.new(1, -90, 0, 4)
		button.BackgroundColor3 = Color3.new()
		button.BackgroundTransparency = hide and 1 or 0.35
		button.Text = ''
		local topbar = cloneref(game:GetService('Players')).LocalPlayer.PlayerGui:WaitForChild("TopBarAppGui", 15)
		if topbar then
			topbar = topbar:WaitForChild("TopBarApp", 5)
		end
		button.Parent = game.GameId == 2619619496 and topbar or gui
		local image = Instance.new('ImageLabel')
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Size = UDim2.fromOffset(22, 22)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.BackgroundTransparency = 1
		image.Image = getcustomasset('catsix/assets/new/vape.png')
		image.ImageTransparency = hide and 1 or 0
		image.Parent = button
		local buttoncorner = Instance.new('UICorner')
		buttoncorner.Parent = button
		self.VapeButton = button
		mainapi:Clean(button)
		button.MouseButton1Click:Connect(function()
			if self.ThreadFix then
				setthreadidentity(8)
			end
			for _, v in self.Windows do
				v.Visible = false
			end
			for _, mobileButton in self.Modules do
				if mobileButton.Bind.Button then
					mobileButton.Bind.Button.Visible = clickgui.Visible
				end
			end
			clickgui.Visible = not clickgui.Visible
			tooltip.Visible = false
			self:BlurCheck()
		end)
	end
end

function mainapi:LoadOptions(object, savedoptions)
	for i, v in savedoptions do
		local option = object.Options[i]
		if not option then continue end
		if mainapi.ThreadFix then
			setthreadidentity(8)
		end
		if not pcall(function()
			option:Load(v)
		end) then
			mainapi:CreateNotification('Cat', `Failed to load config for {i}`, 5, 'warning')
		end
	end
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
	if not self.Loaded then return end
	local guidata = {
		Categories = {},
		Profile = newprofile or self.Profile,
		Profiles = self.Profiles,
		Keybind = self.Keybind
	}
	local savedata = {
		Modules = {},
		Categories = {},
		Legit = {}
	}

	for i, v in self.Categories do
		(v.Type ~= 'Category' and i ~= 'Main' and savedata or guidata).Categories[i] = {
			Enabled = i ~= 'Main' and v.Button.Enabled or nil,
			Expanded = v.Type ~= 'Overlay' and v.Expanded or nil,
			Pinned = v.Pinned,
			Position = {X = v.Object.Position.X.Offset, Y = v.Object.Position.Y.Offset},
			Options = mainapi:SaveOptions(v, v.Options),
			List = v.List,
			ListEnabled = v.ListEnabled
		}
	end

	for i, v in self.Modules do
		savedata.Modules[i:gsub(' ', '')] = {
			Enabled = v.Enabled,
			Bind = v.Bind.Button and {Mobile = true, X = v.Bind.Button.Position.X.Offset, Y = v.Bind.Button.Position.Y.Offset} or v.Bind,
			Options = mainapi:SaveOptions(v, true)
		}
	end

	for i, v in self.Legit.Modules do
		savedata.Legit[i:gsub(' ', '')] = {
			Enabled = v.Enabled,
			Position = v.Children and {X = v.Children.Position.X.Offset, Y = v.Children.Position.Y.Offset} or nil,
			Options = mainapi:SaveOptions(v, v.Options)
		}
	end

	local function writeSave(path, data)
		if self.SaveCache[path] ~= data then
			self.SaveCache[path] = data
			writefile(path, data)
		end
	end

	writeSave('catsix/profiles/'..game.GameId..'.gui.txt', httpService:JSONEncode(guidata))
	writeSave('catsix/profiles/'..self.Profile..self.Place..'.txt', httpService:JSONEncode(savedata))
end

function mainapi:QueueSave()
	if self.SaveQueued or not self.Loaded then return end
	self.SaveQueued = true
	task.delay(2, function()
		self.SaveQueued = nil
		if self.Loaded then
			self:Save()
		end
	end)
end

function mainapi:SaveOptions(object, savedoptions)
	if not savedoptions then return end
	savedoptions = {}
	for _, v in object.Options do
		if not v.Save then continue end
		v:Save(savedoptions)
	end
	return savedoptions
end

function mainapi:Uninject()
	mainapi:Save()
	mainapi.Loaded = nil
	for _, v in self.Modules do
		if v.Enabled then
			v:Toggle()
		end
	end
	for _, v in self.Legit.Modules do
		if v.Enabled then
			v:Toggle()
		end
	end
	for _, v in self.Categories do
		if v.Type == 'Overlay' and v.Button.Enabled then
			v.Button:Toggle()
		end
	end
	for _, v in mainapi.Connections do
		pcall(function()
			v:Disconnect()
		end)
	end
	if mainapi.ThreadFix then
		setthreadidentity(8)
		clickgui.Visible = false
		mainapi:BlurCheck()
	end
	mainapi.gui:ClearAllChildren()
	mainapi.gui:Destroy()
	table.clear(mainapi.Connections)
	table.clear(mainapi.Libraries)
	loopClean(mainapi)
	shared.vape = nil
	shared.vapereload = nil
	shared.VapeIndependent = nil
end

gui = Instance.new('ScreenGui')
gui.Name = randomString()
gui.DisplayOrder = 9999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.IgnoreGuiInset = true
gui.OnTopOfCoreBlur = true
if false then--mainapi.ThreadFix
	gui.Parent = cloneref(game:GetService('CoreGui'))
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
clickgui.BackgroundTransparency = 1
clickgui.Visible = false
clickgui.Parent = scaledgui
local scarcitybanner = Instance.new('TextLabel')
scarcitybanner.Size = UDim2.fromScale(1, 0.02)
scarcitybanner.Position = UDim2.fromScale(0, 0.97)
scarcitybanner.BackgroundTransparency = 1
scarcitybanner.Text = 'The discord link has been fixed, click the discord icon to join.'
scarcitybanner.TextScaled = true
scarcitybanner.TextColor3 = Color3.new(1, 1, 1)
scarcitybanner.TextStrokeTransparency = 0.5
scarcitybanner.FontFace = uipallet.Font
scarcitybanner.Parent = clickgui
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
tooltip = Instance.new('TextLabel')
tooltip.Name = 'Tooltip'
tooltip.Position = UDim2.fromScale(-1, -1)
tooltip.ZIndex = 5
tooltip.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
tooltip.Visible = false
tooltip.Text = ''
tooltip.TextColor3 = color.Dark(uipallet.Text, 0.16)
tooltip.TextSize = 12
tooltip.FontFace = uipallet.Font
tooltip.Parent = scaledgui
toolblur = addBlur(tooltip)
addCorner(tooltip)
local toolstrokebkg = Instance.new('Frame')
toolstrokebkg.Size = UDim2.new(1, -2, 1, -2)
toolstrokebkg.Position = UDim2.fromOffset(1, 1)
toolstrokebkg.ZIndex = 6
toolstrokebkg.BackgroundTransparency = 1
toolstrokebkg.Parent = tooltip
local toolstroke = Instance.new('UIStroke')
toolstroke.Color = color.Light(uipallet.Main, 0.02)
toolstroke.Parent = toolstrokebkg
addCorner(toolstrokebkg, UDim.new(0, 4))
scale = Instance.new('UIScale')
scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 0.6)
scale.Parent = scaledgui
mainapi.guiscale = scale
scaledgui.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
mainapi.Libraries.clickgui = clickgui
mainapi.Libraries.scaledgui = scaledgui
mainapi.Libraries.scale = scale

mainapi:Clean(gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
	if mainapi.Scale.Enabled then
		scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 0.6)
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
	if not clickgui.Visible then
		mainapi:QueueSave()
	end
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

mainapi:CreateGUI()
mainapi.Categories.Main:CreateDivider()
mainapi:CreateCategory({
	Name = 'Combat',
	Icon = getcustomasset('catsix/assets/new/combaticon.png'),
	Size = UDim2.fromOffset(13, 14)
})
mainapi:CreateCategory({
	Name = 'Blatant',
	Icon = getcustomasset('catsix/assets/new/blatanticon.png'),
	Size = UDim2.fromOffset(14, 14)
})
mainapi:CreateCategory({
	Name = 'Render',
	Icon = getcustomasset('catsix/assets/new/rendericon.png'),
	Size = UDim2.fromOffset(15, 14)
})
mainapi:CreateCategory({
	Name = 'Utility',
	Icon = getcustomasset('catsix/assets/new/utilityicon.png'),
	Size = UDim2.fromOffset(15, 14)
})
mainapi:CreateCategory({
	Name = 'World',
	Icon = getcustomasset('catsix/assets/new/worldicon.png'),
	Size = UDim2.fromOffset(14, 14)
})
mainapi:CreateCategory({
	Name = 'Inventory',
	Icon = getcustomasset('catsix/assets/new/inventoryicon.png'),
	Size = UDim2.fromOffset(15, 14)
})
mainapi:CreateCategory({
	Name = 'Minigames',
	Icon = getcustomasset('catsix/assets/new/miniicon.png'),
	Size = UDim2.fromOffset(19, 12)
})
mainapi.Categories.Main:CreateDivider('misc')

--[[
	Friends
]]
local friends
local friendscolor = {
	Hue = 1,
	Sat = 1,
	Value = 1
}
local friendssettings = {
	Name = 'Friends',
	Icon = getcustomasset('catsix/assets/new/friendstab.png'),
	Size = UDim2.fromOffset(17, 16),
	Placeholder = 'Roblox username',
	Color = Color3.fromRGB(5, 134, 105),
	Function = function()
		friends.Update:Fire()
		friends.ColorUpdate:Fire(friendscolor.Hue, friendscolor.Sat, friendscolor.Value)
	end
}
friends = mainapi:CreateCategoryList(friendssettings)
friends.Update = Instance.new('BindableEvent')
friends.ColorUpdate = Instance.new('BindableEvent')
friends:CreateToggle({
	Name = 'Recolor visuals',
	Darker = true,
	Default = true,
	Function = function()
		friends.Update:Fire()
		friends.ColorUpdate:Fire(friendscolor.Hue, friendscolor.Sat, friendscolor.Value)
	end
})
friendscolor = friends:CreateColorSlider({
	Name = 'Friends color',
	Darker = true,
	Function = function(hue, sat, val)
		for _, v in friends.Object.Children:GetChildren() do
			local dot = v:FindFirstChild('Dot')
			if dot and dot.BackgroundColor3 ~= color.Light(uipallet.Main, 0.37) then
				dot.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				dot.Dot.BackgroundColor3 = dot.BackgroundColor3
			end
		end
		friendssettings.Color = Color3.fromHSV(hue, sat, val)
		friends.ColorUpdate:Fire(hue, sat, val)
	end
})
friends:CreateToggle({
	Name = 'Use friends',
	Darker = true,
	Default = true,
	Function = function()
		friends.Update:Fire()
		friends.ColorUpdate:Fire(friendscolor.Hue, friendscolor.Sat, friendscolor.Value)
	end
})
mainapi:Clean(friends.Update)
mainapi:Clean(friends.ColorUpdate)

--[[
	Profiles
]]
local Profiles = mainapi:CreateCategoryList({
	Name = 'Profiles',
	Icon = getcustomasset('catsix/assets/new/profilesicon.png'),
	Size = UDim2.fromOffset(17, 10),
	Position = UDim2.fromOffset(12, 16),
	Placeholder = 'Type name',
	Profiles = true
})
Profiles:CreateButton({
	Name = 'Sync to "default" profile',
	LayoutOrder = 6,
	Function = function()
		local profile = mainapi.Profile
		mainapi:Save()

		local current = 'catsix/profiles/'..profile..mainapi.Place..'.txt'
		local target = 'catsix/profiles/default'..mainapi.Place..'.txt'
		if profile ~= 'default' and isfile(current) then
			local data = readfile(current)
			mainapi.SaveCache[target] = data
			writefile(target, data)
		end

		mainapi:Load(true, 'default')
		mainapi:CreateNotification('Cat', `Synced "{profile}" to the default profile`, 5, 'info')
	end
})
Profiles:CreateButton({
	Name = 'Reset current profile',
	LayoutOrder = 7,
	Function = function()
		mainapi.Save = function() end
		if isfile('catsix/profiles/'..mainapi.Profile..mainapi.Place..'.txt') and delfile then
			delfile('catsix/profiles/'..mainapi.Profile..mainapi.Place..'.txt')
		end
		shared.vapereload = true
		if shared.VapeDeveloper then
			loadstring(readfile('catsix/init.lua'), 'init')(license)
		else
			loadstring(game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catsix/profiles/commit.txt')..'/init.lua', true))(license)
		end
	end,
	Tooltip = 'This will set your profile to the default settings of Cat Vape'
})	

--[[
	Targets
]]
local targets
targets = mainapi:CreateCategoryList({
	Name = 'Targets',
	Icon = getcustomasset('catsix/assets/new/friendstab.png'),
	Size = UDim2.fromOffset(17, 16),
	Placeholder = 'Roblox username',
	Function = function()
		targets.Update:Fire()
	end
})
targets.Update = Instance.new('BindableEvent')
mainapi:Clean(targets.Update)

mainapi:CreateLegit()
mainapi:CreateChangelogs()
mainapi:CreatePublicProfiles()
mainapi:CreateSearch()
mainapi.Categories.Main:CreateOverlayBar()
mainapi.Categories.Main:CreateSettingsDivider()

--[[
	General Settings
]]

local general = mainapi.Categories.Main:CreateSettingsPane({Name = 'General'})
general:CreateButton({
	Name = 'View changelogs',
	Function = function()
		if mainapi.Changelogs then
			mainapi.Changelogs:Open()
		end
	end,
	Tooltip = 'Shows what changed in the latest update'
})
mainapi.MultiKeybind = general:CreateToggle({
	Name = 'Enable Multi-Keybinding',
	Tooltip = 'Allows multiple keys to be bound to a module (eg. G + H)'
})
general:CreateButton({
	Name = 'Self destruct',
	Function = function()
		mainapi:Uninject()
	end,
	Tooltip = 'Removes vape from the current game'
})
general:CreateButton({
	Name = 'Reinject',
	Function = function()
		shared.vapereload = true
		if shared.VapeDeveloper then
			loadstring(readfile('catsix/init.lua'), 'init')()
		else
			loadstring(game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catsix/profiles/commit.txt')..'/init.lua', true))()
		end
	end,
	Tooltip = 'Reloads vape for debugging purposes'
})

--[[
	Module Settings
]]

local modules = mainapi.Categories.Main:CreateSettingsPane({Name = 'Modules'})
modules:CreateToggle({
	Name = 'Teams by server',
	Tooltip = 'Ignore players on your team designated by the server',
	Default = true,
	Function = function()
		if mainapi.Libraries.entity and mainapi.Libraries.entity.Running then
			mainapi.Libraries.entity.refresh()
		end
	end
})
modules:CreateToggle({
	Name = 'Use team color',
	Tooltip = 'Uses the TeamColor property on players for render modules',
	Default = true,
	Function = function()
		if mainapi.Libraries.entity and mainapi.Libraries.entity.Running then
			mainapi.Libraries.entity.refresh()
		end
	end
})

--[[
	GUI Settings
]]

local guipane = mainapi.Categories.Main:CreateSettingsPane({Name = 'GUI'})
mainapi.Blur = guipane:CreateToggle({
	Name = 'Blur background',
	Function = function()
		mainapi:BlurCheck()
	end,
	Default = true,
	Tooltip = 'Blur the background of the GUI'
})
guipane:CreateToggle({
	Name = 'GUI bind indicator',
	Default = true,
	Tooltip = "Displays a message indicating your GUI upon injecting.\nI.E. 'Press RSHIFT to open GUI'"
})
guipane:CreateToggle({
	Name = 'Show tooltips',
	Function = function(enabled)
		tooltip.Visible = false
		toolblur.Visible = enabled
	end,
	Default = true,
	Tooltip = 'Toggles visibility of these'
})
if not inputService.KeyboardEnabled or shared.VapeDeveloper then
	guipane:CreateToggle({
		Name = 'Hide Vape Button',
		Default = isfile('catsix/profiles/hide.txt') and readfile('catsix/profiles/hide.txt') == 'true' or false,
		Function = function(enabled)
			local button = mainapi.VapeButton
			if button then
				button.BackgroundTransparency = enabled and 1 or 0.35
				button.ImageLabel.ImageTransparency = enabled and 1 or 0
			end
			writefile('catsix/profiles/hide.txt', tostring(enabled))
		end,
		Tooltip = 'Hides the button that opens the GUI'
	})
end
guipane:CreateToggle({
	Name = 'Show legit mode',
	Function = function(enabled)
		clickgui.Search.Legit.Visible = enabled
		clickgui.Search.LegitDivider.Visible = enabled
		clickgui.Search.TextBox.Size = UDim2.new(1, enabled and -50 or -10, 0, 37)
		clickgui.Search.TextBox.Position = UDim2.fromOffset(enabled and 50 or 10, 0)
	end,
	Default = true,
	Tooltip = 'Shows the button to change to Legit Mode'
})
local scaleslider = {Object = {}, Value = 1}
mainapi.Scale = guipane:CreateToggle({
	Name = 'Auto rescale',
	Default = true,
	Function = function(callback)
		scaleslider.Object.Visible = not callback
		if callback then
			scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 0.45)
		else
			scale.Scale = scaleslider.Value
		end
	end,
	Tooltip = 'Automatically rescales the gui using the screens resolution'
})
scaleslider = guipane:CreateSlider({
	Name = 'Scale',
	Min = 0.1,
	Max = 2,
	Decimal = 10,
	Function = function(val, final)
		if final and not mainapi.Scale.Enabled then
			scale.Scale = val
		end
	end,
	Default = 1,
	Darker = true,
	Visible = false
})
guipane:CreateDropdown({
	Name = 'GUI Theme',
	List = inputService.TouchEnabled and {'new', 'old'} or {'new', 'old', 'rise'},
	Function = function(val, mouse)
		if mouse then
			writefile('catsix/profiles/gui.txt', val)
			shared.vapereload = true
			if shared.VapeDeveloper then
				loadstring(readfile('catsix/init.lua'), 'loader')()
			else
				loadstring(game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/'..readfile('catsix/profiles/commit.txt')..'/init.lua', true))()
			end
		end
	end,
	Tooltip = 'new - The newest vape theme to since v4.05\nold - The vape theme pre v4.05\nrise - Rise 6.0'
})
mainapi.RainbowMode = guipane:CreateDropdown({
	Name = 'Rainbow Mode',
	List = {'Normal', 'Gradient', 'Retro'},
	Tooltip = 'Normal - Smooth color fade\nGradient - Gradient color fade\nRetro - Static color'
})
mainapi.RainbowSpeed = guipane:CreateSlider({
	Name = 'Rainbow speed',
	Min = 0.1,
	Max = 10,
	Decimal = 10,
	Default = 1,
	Tooltip = 'Adjusts the speed of rainbow values'
})
mainapi.RainbowUpdateSpeed = guipane:CreateSlider({
	Name = 'Rainbow update rate',
	Min = 1,
	Max = 144,
	Default = 60,
	Tooltip = 'Adjusts the update rate of rainbow values',
	Suffix = 'hz'
})
guipane:CreateButton({
	Name = 'Reset GUI positions',
	Function = function()
		for _, v in mainapi.Categories do
			v.Object.Position = UDim2.fromOffset(6, 42)
		end
	end,
	Tooltip = 'This will reset your GUI back to default'
})
guipane:CreateButton({
	Name = 'Sort GUI',
	Function = function()
		local priority = {
			GUICategory = 1,
			CombatCategory = 2,
			BlatantCategory = 3,
			RenderCategory = 4,
			UtilityCategory = 5,
			WorldCategory = 6,
			InventoryCategory = 7,
			MinigamesCategory = 8,
			FriendsCategory = 9,
			ProfilesCategory = 10
		}
		local categories = {}
		for _, v in mainapi.Categories do
			if v.Type ~= 'Overlay' then
				table.insert(categories, v)
			end
		end
		table.sort(categories, function(a, b)
			return (priority[a.Object.Name] or 99) < (priority[b.Object.Name] or 99)
		end)

		local ind = 0
		for _, v in categories do
			if v.Object.Visible then
				v.Object.Position = UDim2.fromOffset(6 + (ind % 8 * 230), 60 + (ind > 7 and 360 or 0))
				ind += 1
			end
		end
	end,
	Tooltip = 'Sorts GUI'
})

--[[
	Notification Settings
]]

local notifpane = mainapi.Categories.Main:CreateSettingsPane({Name = 'Notifications'})
mainapi.Notifications = notifpane:CreateToggle({
	Name = 'Notifications',
	Function = function(enabled)
		if mainapi.ToggleNotifications.Object then
			mainapi.ToggleNotifications.Object.Visible = enabled
		end
	end,
	Tooltip = 'Shows notifications',
	Default = true
})
mainapi.ToggleNotifications = notifpane:CreateToggle({
	Name = 'Toggle alert',
	Tooltip = 'Notifies you if a module is enabled/disabled.',
	Default = true,
	Darker = true
})

mainapi.GUIColor = mainapi.Categories.Main:CreateGUISlider({
	Name = 'GUI Theme',
	Function = function(h, s, v)
		mainapi:UpdateGUI(h, s, v, true)
	end
})
mainapi.Categories.Main:CreateBind()

--[[
	Text GUI
]]

local textgui = mainapi:CreateOverlay({
	Name = 'Text GUI',
	Icon = getcustomasset('catsix/assets/new/textguiicon.png'),
	Size = UDim2.fromOffset(16, 12),
	Position = UDim2.fromOffset(12, 14),
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguisort = textgui:CreateDropdown({
	Name = 'Sort',
	List = {'Alphabetical', 'Length'},
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguifont = textgui:CreateFont({
	Name = 'Font',
	Blacklist = 'Arial',
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguicolor
local textguicolordrop = textgui:CreateDropdown({
	Name = 'Color Mode',
	List = {'Match GUI color', 'Custom color'},
	Function = function(val)
		textguicolor.Object.Visible = val == 'Custom color'
		mainapi:UpdateTextGUI()
	end
})
textguicolor = textgui:CreateColorSlider({
	Name = 'Text GUI color',
	Function = function()
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end,
	Darker = true,
	Visible = false
})
local VapeTextScale = Instance.new('UIScale')
VapeTextScale.Parent = textgui.Children
local textguiscale = textgui:CreateSlider({
	Name = 'Scale',
	Min = 0,
	Max = 2,
	Decimal = 10,
	Default = 1,
	Function = function(val)
		VapeTextScale.Scale = val
		mainapi:UpdateTextGUI()
	end
})
local textguishadow = textgui:CreateToggle({
	Name = 'Shadow',
	Tooltip = 'Renders shadowed text.',
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguigradientv4
local textguigradient = textgui:CreateToggle({
	Name = 'Gradient',
	Tooltip = 'Renders a gradient',
	Function = function(callback)
		textguigradientv4.Object.Visible = callback
		mainapi:UpdateTextGUI()
	end
})
textguigradientv4 = textgui:CreateToggle({
	Name = 'V4 Gradient',
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Darker = true,
	Visible = false
})
local textguianimations = textgui:CreateToggle({
	Name = 'Animations',
	Tooltip = 'Use animations on text gui',
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguiwatermark = textgui:CreateToggle({
	Name = 'Watermark',
	Tooltip = 'Renders a vape watermark',
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguibackgroundtransparency = {
	Value = 0.5,
	Object = {Visible = {}}
}
local textguibackgroundtint = {Enabled = false}
local textguibackground = textgui:CreateToggle({
	Name = 'Render background',
	Function = function(callback)
		textguibackgroundtransparency.Object.Visible = callback
		textguibackgroundtint.Object.Visible = callback
		mainapi:UpdateTextGUI()
	end
})
textguibackgroundtransparency = textgui:CreateSlider({
	Name = 'Transparency',
	Min = 0,
	Max = 1,
	Default = 0.5,
	Decimal = 10,
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Darker = true,
	Visible = false
})
textguibackgroundtint = textgui:CreateToggle({
	Name = 'Tint',
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Darker = true,
	Visible = false
})
local textguimoduleslist
local textguimodules = textgui:CreateToggle({
	Name = 'Hide modules',
	Tooltip = 'Allows you to blacklist certain modules from being shown.',
	Function = function(enabled)
		textguimoduleslist.Object.Visible = enabled
		mainapi:UpdateTextGUI()
	end
})
textguimoduleslist = textgui:CreateTextList({
	Name = 'Blacklist',
	Tooltip = 'Name of module to hide.',
	Icon = getcustomasset('catsix/assets/new/blockedicon.png'),
	Tab = getcustomasset('catsix/assets/new/blockedtab.png'),
	TabSize = UDim2.fromOffset(21, 16),
	Color = Color3.fromRGB(250, 50, 56),
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Visible = false,
	Darker = true
})
local textguirender = textgui:CreateToggle({
	Name = 'Hide render',
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguibox
local textguifontcustom
local textguicolorcustomtoggle
local textguicolorcustom
local textguitext = textgui:CreateToggle({
	Name = 'Add custom text',
	Function = function(enabled)
		textguibox.Object.Visible = enabled
		textguifontcustom.Object.Visible = enabled
		textguicolorcustomtoggle.Object.Visible = enabled
		textguicolorcustom.Object.Visible = textguicolorcustomtoggle.Enabled and enabled
		mainapi:UpdateTextGUI()
	end
})
textguibox = textgui:CreateTextBox({
	Name = 'Custom text',
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Darker = true,
	Visible = false
})
textguifontcustom = textgui:CreateFont({
	Name = 'Custom Font',
	Blacklist = 'Arial',
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Darker = true,
	Visible = false
})
textguicolorcustomtoggle = textgui:CreateToggle({
	Name = 'Set custom text color',
	Function = function(enabled)
		textguicolorcustom.Object.Visible = enabled
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end,
	Darker = true,
	Visible = false
})
textguicolorcustom = textgui:CreateColorSlider({
	Name = 'Color of custom text',
	Function = function()
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end,
	Darker = true,
	Visible = false
})

--[[
	Text GUI Objects
]]

local VapeLabels = {}
local VapeLogo = Instance.new('ImageLabel')
VapeLogo.Name = 'Logo'
VapeLogo.Size = UDim2.fromOffset(80, 21)
VapeLogo.Position = UDim2.new(1, -142, 0, 3)
VapeLogo.BackgroundTransparency = 1
VapeLogo.BorderSizePixel = 0
VapeLogo.Visible = false
VapeLogo.BackgroundColor3 = Color3.new()
VapeLogo.Image = getcustomasset('catsix/assets/new/textvape.png')
VapeLogo.Parent = textgui.Children

local lastside = textgui.Children.AbsolutePosition.X > (gui.AbsoluteSize.X / 2)
mainapi:Clean(textgui.Children:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
	if mainapi.ThreadFix then
		setthreadidentity(8)
	end
	local newside = textgui.Children.AbsolutePosition.X > (gui.AbsoluteSize.X / 2)
	if lastside ~= newside then
		lastside = newside
		mainapi:UpdateTextGUI()
	end
end))

local VapeLogoV4 = Instance.new('ImageLabel')
VapeLogoV4.Name = 'Logo2'
VapeLogoV4.Size = UDim2.fromOffset(33, 18)
VapeLogoV4.Position = UDim2.new(1, 1, 0, 1)
VapeLogoV4.BackgroundColor3 = Color3.new()
VapeLogoV4.BackgroundTransparency = 1
VapeLogoV4.BorderSizePixel = 0
VapeLogoV4.Image = getcustomasset('catsix/assets/new/textv4.png')
VapeLogoV4.Parent = VapeLogo
local VapeLogoShadow = VapeLogo:Clone()
VapeLogoShadow.Position = UDim2.fromOffset(1, 1)
VapeLogoShadow.ZIndex = 0
VapeLogoShadow.Visible = true
VapeLogoShadow.ImageColor3 = Color3.new()
VapeLogoShadow.ImageTransparency = 0.65
VapeLogoShadow.Parent = VapeLogo
VapeLogoShadow.Logo2.ZIndex = 0
VapeLogoShadow.Logo2.ImageColor3 = Color3.new()
VapeLogoShadow.Logo2.ImageTransparency = 0.65
local VapeLogoGradient = Instance.new('UIGradient')
VapeLogoGradient.Rotation = 90
VapeLogoGradient.Parent = VapeLogo
local VapeLogoGradient2 = Instance.new('UIGradient')
VapeLogoGradient2.Rotation = 90
VapeLogoGradient2.Parent = VapeLogoV4
local VapeLabelCustom = Instance.new('TextLabel')
VapeLabelCustom.Position = UDim2.fromOffset(5, 2)
VapeLabelCustom.BackgroundTransparency = 1
VapeLabelCustom.BorderSizePixel = 0
VapeLabelCustom.Visible = false
VapeLabelCustom.Text = ''
VapeLabelCustom.TextSize = 25
VapeLabelCustom.FontFace = textguifontcustom.Value
VapeLabelCustom.RichText = true
local VapeLabelCustomShadow = VapeLabelCustom:Clone()
VapeLabelCustom:GetPropertyChangedSignal('Position'):Connect(function()
	VapeLabelCustomShadow.Position = UDim2.new(
		VapeLabelCustom.Position.X.Scale,
		VapeLabelCustom.Position.X.Offset + 1,
		0,
		VapeLabelCustom.Position.Y.Offset + 1
	)
end)
VapeLabelCustom:GetPropertyChangedSignal('FontFace'):Connect(function()
	VapeLabelCustomShadow.FontFace = VapeLabelCustom.FontFace
end)
VapeLabelCustom:GetPropertyChangedSignal('Text'):Connect(function()
	VapeLabelCustomShadow.Text = removeTags(VapeLabelCustom.Text)
end)
VapeLabelCustom:GetPropertyChangedSignal('Size'):Connect(function()
	VapeLabelCustomShadow.Size = VapeLabelCustom.Size
end)
VapeLabelCustomShadow.TextColor3 = Color3.new()
VapeLabelCustomShadow.TextTransparency = 0.65
VapeLabelCustomShadow.Parent = textgui.Children
VapeLabelCustom.Parent = textgui.Children
local VapeLabelHolder = Instance.new('Frame')
VapeLabelHolder.Name = 'Holder'
VapeLabelHolder.Size = UDim2.fromScale(1, 1)
VapeLabelHolder.Position = UDim2.fromOffset(5, 37)
VapeLabelHolder.BackgroundTransparency = 1
VapeLabelHolder.Parent = textgui.Children
local VapeLabelSorter = Instance.new('UIListLayout')
VapeLabelSorter.HorizontalAlignment = Enum.HorizontalAlignment.Right
VapeLabelSorter.VerticalAlignment = Enum.VerticalAlignment.Top
VapeLabelSorter.SortOrder = Enum.SortOrder.LayoutOrder
VapeLabelSorter.Parent = VapeLabelHolder

--[[
	Target Info
]]

local targetinfo
local targetinfoobj
local targetinfobcolor
local targetinfobkg
local targetinfofollow
targetinfoobj = mainapi:CreateOverlay({
	Name = 'Target Info',
	Icon = getcustomasset('catsix/assets/new/targetinfoicon.png'),
	Size = UDim2.fromOffset(14, 14),
	Position = UDim2.fromOffset(12, 14),
	CategorySize = 240,
	Function = function(callback)
		if callback then
			task.spawn(function()
				repeat
					local target = targetinfo:UpdateInfo()
					if targetinfofollow and targetinfofollow.Enabled and target then
						local vec, screen = workspace.CurrentCamera:WorldToViewportPoint(target.Position)
						if screen then
							targetinfobkg.Parent.Parent.Parent.Position = UDim2.fromOffset(vec.X, vec.Y)
						end
					end
					task.wait(0)
				until not targetinfoobj.Button or not targetinfoobj.Button.Enabled
			end)
		end
	end
})

--[[
	New
]]

local handler = Instance.new('Frame')
handler.Size = UDim2.fromOffset(240, 89)
handler.BackgroundColor3 = color.Dark(uipallet.Main, 0.1)
handler.BackgroundTransparency = 1
handler.Parent = targetinfoobj.Children

targetinfobkg = Instance.new('Frame')
targetinfobkg.Size = UDim2.fromOffset(240, 89)
targetinfobkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.1)
targetinfobkg.BackgroundTransparency = 0.5
targetinfobkg.Parent = handler

local targetinfoblurobj = addBlur(targetinfobkg)
targetinfoblurobj.Visible = true
addCorner(targetinfobkg)
local targetinfoshot = Instance.new('ImageLabel')
targetinfoshot.Size = UDim2.fromOffset(26, 27)
targetinfoshot.Position = UDim2.fromOffset(19, 17)
targetinfoshot.BackgroundColor3 = uipallet.Main
targetinfoshot.Image = 'rbxthumb://type=AvatarHeadShot&id=1&w=420&h=420'
targetinfoshot.Parent = targetinfobkg
local targetinfoshotflash = Instance.new('Frame')
targetinfoshotflash.Size = UDim2.fromScale(1, 1)
targetinfoshotflash.BackgroundTransparency = 1
targetinfoshotflash.BackgroundColor3 = Color3.new(1, 0, 0)
targetinfoshotflash.Parent = targetinfoshot
addCorner(targetinfoshotflash)
local targetinfoshotblur = addBlur(targetinfoshot)
targetinfoshotblur.Visible = true
addCorner(targetinfoshot)
local targetinfoname = Instance.new('TextLabel')
targetinfoname.Size = UDim2.fromOffset(145, 20)
targetinfoname.Position = UDim2.fromOffset(54, 20)
targetinfoname.BackgroundTransparency = 1
targetinfoname.Text = 'Target name'
targetinfoname.TextXAlignment = Enum.TextXAlignment.Left
targetinfoname.TextYAlignment = Enum.TextYAlignment.Top
targetinfoname.TextScaled = true
targetinfoname.TextColor3 = color.Light(uipallet.Text, 0.4)
targetinfoname.TextStrokeTransparency = 1
targetinfoname.FontFace = uipallet.Font
local targetinfoshadow = targetinfoname:Clone()
targetinfoshadow.Position = UDim2.fromOffset(55, 21)
targetinfoshadow.TextColor3 = Color3.new()
targetinfoshadow.TextTransparency = 0.65
targetinfoshadow.Visible = false
targetinfoshadow.Parent = targetinfobkg
targetinfoname:GetPropertyChangedSignal('Size'):Connect(function()
	targetinfoshadow.Size = targetinfoname.Size
end)
targetinfoname:GetPropertyChangedSignal('Text'):Connect(function()
	targetinfoshadow.Text = targetinfoname.Text
end)
targetinfoname:GetPropertyChangedSignal('FontFace'):Connect(function()
	targetinfoshadow.FontFace = targetinfoname.FontFace
end)
targetinfoname.Parent = targetinfobkg
local targetinfohealthbkg = Instance.new('Frame')
targetinfohealthbkg.Name = 'HealthBKG'
targetinfohealthbkg.Size = UDim2.fromOffset(200, 9)
targetinfohealthbkg.Position = UDim2.fromOffset(20, 56)
targetinfohealthbkg.BackgroundColor3 = uipallet.Main
targetinfohealthbkg.BorderSizePixel = 0
targetinfohealthbkg.Parent = targetinfobkg
addCorner(targetinfohealthbkg, UDim.new(1, 0))
local targetinfohealth = targetinfohealthbkg:Clone()
targetinfohealth.Size = UDim2.fromScale(0.8, 1)
targetinfohealth.Position = UDim2.new()
targetinfohealth.BackgroundColor3 = Color3.fromHSV(1 / 2.5, 0.89, 0.75)
targetinfohealth.Parent = targetinfohealthbkg
targetinfohealth:GetPropertyChangedSignal('Size'):Connect(function()
	targetinfohealth.Visible = targetinfohealth.Size.X.Scale > 0.01
end)
local targetinfohealthextra = targetinfohealth:Clone()
targetinfohealthextra.Size = UDim2.new()
targetinfohealthextra.Position = UDim2.fromScale(1, 0)
targetinfohealthextra.AnchorPoint = Vector2.new(1, 0)
targetinfohealthextra.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
targetinfohealthextra.Visible = false
targetinfohealthextra.Parent = targetinfohealthbkg
targetinfohealthextra:GetPropertyChangedSignal('Size'):Connect(function()
	targetinfohealthextra.Visible = targetinfohealthextra.Size.X.Scale > 0.01
end)
local targetinfohealthblur = addBlur(targetinfohealthbkg)
targetinfohealthblur.SliceCenter = Rect.new(52, 31, 261, 510)
targetinfohealthblur.ImageColor3 = Color3.new()
targetinfohealthblur.Visible = true
local targetinfob = Instance.new('UIStroke')
targetinfob.Enabled = false
targetinfob.Color = Color3.fromHSV(0.44, 1, 1)
targetinfob.Parent = targetinfobkg

--[[
	Old
]]

local TargetInfoMainFrame = Instance.new('Frame')
TargetInfoMainFrame.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
TargetInfoMainFrame.BorderSizePixel = 0
TargetInfoMainFrame.BackgroundTransparency = 1
TargetInfoMainFrame.Size = UDim2.new(0, 220, 0, 72)
TargetInfoMainFrame.Position = UDim2.new(0, 0, 0, 5)
TargetInfoMainFrame.Parent = targetinfoobj.Children
TargetInfoMainFrame.Visible = false

local TargetInfoFrameShadow = Instance.new('ImageLabel')
TargetInfoFrameShadow.BackgroundTransparency = 1
TargetInfoFrameShadow.Position = UDim2.fromScale(-0.041, -0.125)
TargetInfoFrameShadow.Size = UDim2.fromOffset(237, 97)
TargetInfoFrameShadow.ZIndex = -1
TargetInfoFrameShadow.Image = 'rbxassetid://123343128195297'
TargetInfoFrameShadow.Parent = TargetInfoMainFrame

local TargetInfoMainInfo = Instance.new('Frame')
TargetInfoMainInfo.BackgroundColor3 = Color3.fromRGB(31, 30, 31)
TargetInfoMainInfo.Size = UDim2.new(0, 220, 0, 80)
TargetInfoMainInfo.BackgroundTransparency = 0.5
TargetInfoMainInfo.Position = UDim2.new(0, 0, 0, 0)
TargetInfoMainInfo.Name = 'MainInfo'
TargetInfoMainInfo.Parent = TargetInfoMainFrame
local TargetInfoName = Instance.new('TextLabel')
TargetInfoName.Font = Enum.Font.Arial
TargetInfoName.TextColor3 = Color3.fromRGB(182, 182, 182)
TargetInfoName.Position = UDim2.new(0, 70, 0, 13)
TargetInfoName.TextStrokeTransparency = 1
TargetInfoName.BackgroundTransparency = 1
TargetInfoName.TextSize = 14
TargetInfoName.Size = UDim2.new(0, 80, 0, 20)
TargetInfoName.Text = 'None'
TargetInfoName.ZIndex = 2
TargetInfoName.TextXAlignment = Enum.TextXAlignment.Left
TargetInfoName.TextYAlignment = Enum.TextYAlignment.Top
TargetInfoName.Parent = TargetInfoMainInfo
local TargetInfoNameShadow = TargetInfoName:Clone()
TargetInfoNameShadow.Size = UDim2.new(1, 0, 1, 0)
TargetInfoNameShadow.TextTransparency = 0.5
TargetInfoNameShadow.TextColor3 = Color3.new()
TargetInfoNameShadow.ZIndex = 1
TargetInfoNameShadow.Position = UDim2.new(0, 1, 0, 1)
TargetInfoName:GetPropertyChangedSignal('Text'):Connect(function()
	TargetInfoNameShadow.Text = TargetInfoName.Text
end)
TargetInfoNameShadow.Parent = TargetInfoName
local TargetInfoHealthBackground = Instance.new('Frame')
TargetInfoHealthBackground.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
TargetInfoHealthBackground.Size = UDim2.new(0, 140, 0, 4)
TargetInfoHealthBackground.Position = UDim2.new(0, 71, 0, 35)
TargetInfoHealthBackground.Parent = TargetInfoMainInfo
local TargetInfoHealthBackgroundShadow = Instance.new('ImageLabel')
TargetInfoHealthBackgroundShadow.AnchorPoint = Vector2.new(0.5, 0.5)
TargetInfoHealthBackgroundShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
TargetInfoHealthBackgroundShadow.Image = 'rbxassetid://13350795660'
TargetInfoHealthBackgroundShadow.BackgroundTransparency = 1
TargetInfoHealthBackgroundShadow.ImageTransparency = 0.6
TargetInfoHealthBackgroundShadow.ZIndex = -1
TargetInfoHealthBackgroundShadow.Size = UDim2.new(1, 6, 1, 6)
TargetInfoHealthBackgroundShadow.ImageColor3 = Color3.new()
TargetInfoHealthBackgroundShadow.ScaleType = Enum.ScaleType.Slice
TargetInfoHealthBackgroundShadow.SliceCenter = Rect.new(10, 10, 118, 118)
TargetInfoHealthBackgroundShadow.Parent = TargetInfoHealthBackground
local TargetInfoHealth = Instance.new('Frame')
TargetInfoHealth.BackgroundColor3 = Color3.fromRGB(115, 255, 110)
TargetInfoHealth.Size = UDim2.new(1, 0, 1, 0)
TargetInfoHealth.ZIndex = 3
TargetInfoHealth.BorderSizePixel = 0
TargetInfoHealth.Parent = TargetInfoHealthBackground
local TargetInfoHealthExtra = Instance.new('Frame')
TargetInfoHealthExtra.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
TargetInfoHealthExtra.Size = UDim2.new(0, 0, 1, 0)
TargetInfoHealthExtra.ZIndex = 4
TargetInfoHealthExtra.BorderSizePixel = 0
TargetInfoHealthExtra.AnchorPoint = Vector2.new(1, 0)
TargetInfoHealthExtra.Position = UDim2.new(1, 0, 0, 0)
TargetInfoHealthExtra.Parent = TargetInfoHealth
local TargetInfoImage = Instance.new('ImageLabel')
TargetInfoImage.Size = UDim2.new(0, 50, 0, 50)
TargetInfoImage.BackgroundTransparency = 0
TargetInfoImage.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
TargetInfoImage.Image = 'rbxthumb://type=AvatarHeadShot&id=1&w=420&h=420'
TargetInfoImage.Position = UDim2.new(0, 10, 0, 16)

local targetinfoshotflashold = Instance.new('Frame')
targetinfoshotflashold.Size = UDim2.fromScale(1, 1)
targetinfoshotflashold.BackgroundTransparency = 1
targetinfoshotflashold.BackgroundColor3 = Color3.new(1, 0, 0)
targetinfoshotflashold.Parent = TargetInfoImage
addCorner(targetinfoshotflashold)

TargetInfoImage.Parent = TargetInfoMainInfo
local TargetInfoMainInfoCorner = Instance.new('UICorner')
TargetInfoMainInfoCorner.CornerRadius = UDim.new(0, 6)
TargetInfoMainInfoCorner.Parent = TargetInfoMainInfo
local TargetInfoHealthBackgroundCorner = Instance.new('UICorner')
TargetInfoHealthBackgroundCorner.CornerRadius = UDim.new(0, 2048)
TargetInfoHealthBackgroundCorner.Parent = TargetInfoHealthBackground
local TargetInfoHealthCorner = Instance.new('UICorner')
TargetInfoHealthCorner.CornerRadius = UDim.new(0, 2048)
TargetInfoHealthCorner.Parent = TargetInfoHealth
local TargetInfoHealthCorner2 = Instance.new('UICorner')
TargetInfoHealthCorner2.CornerRadius = UDim.new(0, 2048)
TargetInfoHealthCorner2.Parent = TargetInfoHealthExtra
local TargetInfoHealthExtraCorner = Instance.new('UICorner')
TargetInfoHealthExtraCorner.CornerRadius = UDim.new(0, 8)
TargetInfoHealthExtraCorner.Parent = TargetInfoImage

local TargetInfoHud = isfile('catsix/profiles/hud.txt') and readfile('catsix/profiles/hud.txt') or 'new'
targetinfoobj:CreateDropdown({
	Name = 'Gui Mode',
	List = {'old', 'new'},
	Default = 'new',
	Function = function(val)
		TargetInfoHud = val
		writefile('catsix/profiles/hud.txt', val)
		TargetInfoMainFrame.Visible = val == 'old'
		handler.Visible = val == 'new'
	end
})
TargetInfoMainFrame.Visible = TargetInfoHud == 'old'
handler.Visible = TargetInfoHud == 'new'
targetinfoobj:CreateFont({
	Name = 'Font',
	Blacklist = 'Arial',
	Function = function(val)
		targetinfoname.FontFace = val
		TargetInfoName.FontFace = val
		TargetInfoNameShadow.FontFace = val
	end
})
local targetinfobackgroundtransparency = {
	Value = 0.5,
	Object = {Visible = {}}
}
local targetinfodisplay = targetinfoobj:CreateToggle({
	Name = 'Use Displayname',
	Default = true
})
targetinfoobj:CreateToggle({
	Name = 'Render Background',
	Function = function(callback)
		targetinfobkg.BackgroundTransparency = callback and targetinfobackgroundtransparency.Value or 1
		TargetInfoMainInfo.BackgroundTransparency = targetinfobkg.BackgroundTransparency
		targetinfoshadow.Visible = not callback
		targetinfoblurobj.Visible = callback
		targetinfobackgroundtransparency.Object.Visible = callback
	end,
	Default = true
})
targetinfofollow = targetinfoobj:CreateToggle({
	Name = 'Follow Player',
	Function = function(callback) end,
	Default = true
})
targetinfobackgroundtransparency = targetinfoobj:CreateSlider({
	Name = 'Transparency',
	Min = 0,
	Max = 1,
	Default = 0.5,
	Decimal = 10,
	Function = function(val)
		targetinfobkg.BackgroundTransparency = val
	end,
	Darker = true
})
local targetinfocolor
local targetinfocolortoggle = targetinfoobj:CreateToggle({
	Name = 'Custom Color',
	Function = function(callback)
		targetinfocolor.Object.Visible = callback
		if callback then
			targetinfobkg.BackgroundColor3 = Color3.fromHSV(targetinfocolor.Hue, targetinfocolor.Sat, targetinfocolor.Value)
			targetinfoshot.BackgroundColor3 = Color3.fromHSV(targetinfocolor.Hue, targetinfocolor.Sat, math.max(targetinfocolor.Value - 0.1, 0.075))
			targetinfohealthbkg.BackgroundColor3 = targetinfoshot.BackgroundColor3
		else
			targetinfobkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.1)
			targetinfoshot.BackgroundColor3 = uipallet.Main
			targetinfohealthbkg.BackgroundColor3 = uipallet.Main
		end
	end
})
targetinfocolor = targetinfoobj:CreateColorSlider({
	Name = 'Color',
	Function = function(hue, sat, val)
		if targetinfocolortoggle.Enabled then
			targetinfobkg.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			targetinfoshot.BackgroundColor3 = Color3.fromHSV(hue, sat, math.max(val - 0.1, 0))
			targetinfohealthbkg.BackgroundColor3 = targetinfoshot.BackgroundColor3
		end
	end,
	Darker = true,
	Visible = false
})
targetinfoobj:CreateToggle({
	Name = 'Border',
	Function = function(callback)
		targetinfob.Enabled = callback
		targetinfobcolor.Object.Visible = callback
	end
})
targetinfobcolor = targetinfoobj:CreateColorSlider({
	Name = 'Border Color',
	Function = function(hue, sat, val, opacity)
		targetinfob.Color = Color3.fromHSV(hue, sat, val)
		targetinfob.Transparency = 1 - opacity
	end,
	Darker = true,
	Visible = false
})

local lasthealth = 0
local lastmaxhealth = 0
targetinfo = {
	Targets = {},
	Object = targetinfobkg,
	oldparent = TargetInfoMainFrame,
	UpdateInfo = function(self)
		local entitylib = mainapi.Libraries
		if not entitylib then return end

		for i, v in self.Targets do
			if v < tick() then
				self.Targets[i] = nil
			end
		end

		local v, highest = nil, tick()
		for i, check in self.Targets do
			if check > highest then
				v = i
				highest = check
			end
		end

		targetinfobkg.Visible = v ~= nil or mainapi.gui.ScaledGui.ClickGui.Visible
		TargetInfoMainInfo.Visible = targetinfobkg.Visible
		TargetInfoFrameShadow.Visible = targetinfobkg.Visible
		if v then
			targetinfoname.Text = v.Player and (targetinfodisplay.Enabled and v.Player.DisplayName or v.Player.Name) or v.Character and v.Character.Name or targetinfoname.Text
			TargetInfoName.Text = targetinfoname.Text
			TargetInfoNameShadow.Text = targetinfoname.Text
			targetinfoshot.Image = 'rbxthumb://type=AvatarHeadShot&id='..(v.Player and v.Player.UserId or 1)..'&w=420&h=420'
			TargetInfoImage.Image = targetinfoshot.Image

			if not v.Character then
				v.Health = v.Health or 0
				v.MaxHealth = v.MaxHealth or 100
			end

			if v.Health ~= lasthealth or v.MaxHealth ~= lastmaxhealth then
				task.spawn(function()
					local percent = math.max(v.Health / v.MaxHealth, 0)
					tween:Tween(targetinfohealth, TweenInfo.new(0.3), {
						Size = UDim2.fromScale(math.min(percent, 1), 1), BackgroundColor3 = Color3.fromHSV(math.clamp(percent / 2.5, 0, 1), 0.89, 0.75)
					})
					tween:Tween(targetinfohealthextra, TweenInfo.new(0.3), {
						Size = UDim2.fromScale(math.clamp(percent - 1, 0, 0.8), 1)
					})
					tween:Tween(TargetInfoHealth, TweenInfo.new(0.3), {
						Size = UDim2.fromScale(math.min(percent, 1), 1), BackgroundColor3 = Color3.fromHSV(math.clamp(percent / 2.5, 0, 1), 0.89, 0.75)
					})
					tween:Tween(TargetInfoHealthExtra, TweenInfo.new(0.3), {
						Size = UDim2.fromScale(math.clamp(percent - 1, 0, 0.8), 1)
					})
					if lasthealth > v.Health and self.LastTarget == v then
						tween:Cancel(targetinfoshotflash)
						tween:Cancel(targetinfoshotflashold)
						targetinfoshotflash.BackgroundTransparency = 0.3
						targetinfoshotflashold.BackgroundTransparency = 0.3
						tween:Tween(targetinfoshotflash, TweenInfo.new(0.5), {
							BackgroundTransparency = 1
						})
						tween:Tween(targetinfoshotflashold, TweenInfo.new(0.5), {
							BackgroundTransparency = 1
						})
					end
					lasthealth = v.Health
					lastmaxhealth = v.MaxHealth
				end)
			end

			if not v.Character then table.clear(v) end
			self.LastTarget = v
		end
		return v and v.Head
	end
}
mainapi.Libraries.targetinfo = targetinfo

function mainapi:UpdateTextGUI(afterload)
	if not afterload and not mainapi.Loaded then return end
	if textgui.Button.Enabled then
		local right = textgui.Children.AbsolutePosition.X > (gui.AbsoluteSize.X / 2)
		VapeLogo.Visible = textguiwatermark.Enabled
		VapeLogo.Position = right and UDim2.new(1 / VapeTextScale.Scale, -113, 0, 6) or UDim2.fromOffset(0, 6)
		VapeLogoShadow.Visible = textguishadow.Enabled
		VapeLabelCustom.Text = textguibox.Value
		VapeLabelCustom.FontFace = textguifontcustom.Value
		VapeLabelCustom.Visible = VapeLabelCustom.Text ~= '' and textguitext.Enabled
		VapeLabelCustomShadow.Visible = VapeLabelCustom.Visible and textguishadow.Enabled
		VapeLabelSorter.HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
		VapeLabelHolder.Size = UDim2.fromScale(1 / VapeTextScale.Scale, 1)
		VapeLabelHolder.Position = UDim2.fromOffset(right and 3 or 0, 11 + (VapeLogo.Visible and VapeLogo.Size.Y.Offset or 0) + (VapeLabelCustom.Visible and 28 or 0) + (textguibackground.Enabled and 3 or 0))
		if VapeLabelCustom.Visible then
			local size = getfontsize(removeTags(VapeLabelCustom.Text), VapeLabelCustom.TextSize, VapeLabelCustom.FontFace)
			VapeLabelCustom.Size = UDim2.fromOffset(size.X, size.Y)
			VapeLabelCustom.Position = UDim2.new(right and 1 / VapeTextScale.Scale or 0, right and -size.X or 0, 0, (VapeLogo.Visible and 32 or 8))
		end

		local found = {}
		for _, v in VapeLabels do
			if v.Enabled then
				table.insert(found, v.Object.Name)
			end
			v.Object:Destroy()
		end
		table.clear(VapeLabels)

		local info = TweenInfo.new(0.3, Enum.EasingStyle.Exponential)
		for i, v in mainapi.Modules do
			if textguimodules.Enabled and table.find(textguimoduleslist.ListEnabled, i) then continue end
			if textguirender.Enabled and v.Category == 'Render' then continue end
			if v.Enabled or table.find(found, i) then
				local holder = Instance.new('Frame')
				holder.Name = i
				holder.Size = UDim2.fromOffset()
				holder.BackgroundTransparency = 1
				holder.ClipsDescendants = true
				holder.Parent = VapeLabelHolder
				local holderbackground
				local holdercolorline
				if textguibackground.Enabled then
					holderbackground = Instance.new('Frame')
					holderbackground.Size = UDim2.new(1, 3, 1, 0)
					holderbackground.BackgroundColor3 = color.Dark(uipallet.Main, 0.15)
					holderbackground.BackgroundTransparency = textguibackgroundtransparency.Value
					holderbackground.BorderSizePixel = 0
					holderbackground.Parent = holder
					local holderline = Instance.new('Frame')
					holderline.Size = UDim2.new(1, 0, 0, 1)
					holderline.Position = UDim2.new(0, 0, 1, -1)
					holderline.BackgroundColor3 = Color3.new()
					holderline.BackgroundTransparency = 0.928 + (0.072 * math.clamp((textguibackgroundtransparency.Value - 0.5) / 0.5, 0, 1))
					holderline.BorderSizePixel = 0
					holderline.Parent = holderbackground
					local holderline2 = holderline:Clone()
					holderline2.Name = 'Line'
					holderline2.Position = UDim2.new()
					holderline2.Parent = holderbackground
					holdercolorline = Instance.new('Frame')
					holdercolorline.Size = UDim2.new(0, 2, 1, 0)
					holdercolorline.Position = right and UDim2.new(1, -5, 0, 0) or UDim2.new()
					holdercolorline.BorderSizePixel = 0
					holdercolorline.Parent = holderbackground
				end
				local holdertext = Instance.new('TextLabel')
				holdertext.Position = UDim2.fromOffset(right and 3 or 6, 2)
				holdertext.BackgroundTransparency = 1
				holdertext.BorderSizePixel = 0
				holdertext.Text = i..(v.ExtraText and " <font color='#A8A8A8'>"..v.ExtraText()..'</font>' or '')
				holdertext.TextSize = 15
				holdertext.FontFace = textguifont.Value
				holdertext.RichText = true
				local size = getfontsize(removeTags(holdertext.Text), holdertext.TextSize, holdertext.FontFace)
				holdertext.Size = UDim2.fromOffset(size.X, size.Y)
				if textguishadow.Enabled then
					local holderdrop = holdertext:Clone()
					holderdrop.Position = UDim2.fromOffset(holdertext.Position.X.Offset + 1, holdertext.Position.Y.Offset + 1)
					holderdrop.Text = removeTags(holdertext.Text)
					holderdrop.TextColor3 = Color3.new()
					holderdrop.Parent = holder
				end
				holdertext.Parent = holder
				local holdersize = UDim2.fromOffset(size.X + 10, size.Y + (textguibackground.Enabled and 5 or 3))
				if textguianimations.Enabled then
					if not table.find(found, i) then
						tween:Tween(holder, info, {
							Size = holdersize
						})
					else
						holder.Size = holdersize
						if not v.Enabled then
							tween:Tween(holder, info, {
								Size = UDim2.fromOffset()
							})
						end
					end
				else
					holder.Size = v.Enabled and holdersize or UDim2.fromOffset()
				end
				table.insert(VapeLabels, {
					Object = holder,
					Text = holdertext,
					Background = holderbackground,
					Color = holdercolorline,
					Enabled = v.Enabled
				})
			end
		end

		if textguisort.Value == 'Alphabetical' then
			table.sort(VapeLabels, function(a, b)
				return a.Text.Text < b.Text.Text
			end)
		else
			table.sort(VapeLabels, function(a, b)
				return a.Text.Size.X.Offset > b.Text.Size.X.Offset
			end)
		end

		for i, v in VapeLabels do
			if v.Color then
				v.Color.Parent.Line.Visible = i ~= 1
			end
			v.Object.LayoutOrder = i
		end
	end

	mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value, true)
end

function mainapi:UpdateGUI(hue, sat, val, default)
	if mainapi.Loaded == nil then return end
	if not default and mainapi.GUIColor.Rainbow then return end
	if textgui.Button.Enabled then
		VapeLogoGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
			ColorSequenceKeypoint.new(1, textguigradient.Enabled and Color3.fromHSV(mainapi:Color((hue - 0.075) % 1)) or Color3.fromHSV(hue, sat, val))
		})
		VapeLogoGradient2.Color = textguigradient.Enabled and textguigradientv4.Enabled and VapeLogoGradient.Color or ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
		})
		VapeLabelCustom.TextColor3 = textguicolorcustomtoggle.Enabled and Color3.fromHSV(textguicolorcustom.Hue, textguicolorcustom.Sat, textguicolorcustom.Value) or VapeLogoGradient.Color.Keypoints[2].Value

		local customcolor = textguicolordrop.Value == 'Custom color' and Color3.fromHSV(textguicolor.Hue, textguicolor.Sat, textguicolor.Value) or nil
		for i, v in VapeLabels do
			v.Text.TextColor3 = customcolor or (mainapi.GUIColor.Rainbow and Color3.fromHSV(mainapi:Color((hue - ((textguigradient and i + 2 or i) * 0.025)) % 1)) or VapeLogoGradient.Color.Keypoints[2].Value)
			if v.Color then
				v.Color.BackgroundColor3 = v.Text.TextColor3
			end
			if textguibackgroundtint.Enabled and v.Background then
				v.Background.BackgroundColor3 = color.Dark(v.Text.TextColor3, 0.75)
			end
		end
	end

	if mainapi.PublicProfiles then
		for _, accent in mainapi.PublicProfiles.Accents do
			accent.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			if accent:IsA('TextButton') and accent.BackgroundTransparency == 0 then
				accent.TextColor3 = mainapi:TextColor(hue, sat, val)
			end
		end
	end

	if not clickgui.Visible and not mainapi.Legit.Window.Visible and not (mainapi.PublicProfiles and mainapi.PublicProfiles.Window.Visible) then return end
	local rainbow = mainapi.GUIColor.Rainbow and mainapi.RainbowMode.Value ~= 'Retro'

	for i, v in mainapi.Categories do
		if i == 'Main' then
			v.Object.VapeLogo.V4Logo.ImageColor3 = Color3.fromHSV(hue, sat, val)
			for _, button in v.Buttons do
				if button.Enabled then
					button.Object.TextColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1)) or Color3.fromHSV(hue, sat, val)
					if button.Icon then
						button.Icon.ImageColor3 = button.Object.TextColor3
					end
				end
			end
		end

		if v.Options then
			for _, option in v.Options do
				if option.Color then
					option:Color(hue, sat, val, rainbow)
				end
			end
		end

		if v.Type == 'CategoryList' then
			local accent = rainbow and Color3.fromHSV(mainapi:Color(hue % 1)) or Color3.fromHSV(hue, sat, val)
			for _, addbutton in v.Object:GetDescendants() do
				if addbutton.Name == 'AddButton' and addbutton:IsA('ImageButton') then
					addbutton.ImageColor3 = accent
				end
			end
			local addrow = v.Object.Children:FindFirstChild('AddRow')
			if addrow then
				for _, button in addrow:GetChildren() do
					local buttonicon = button:FindFirstChild('Icon', true)
					if buttonicon then
						buttonicon.ImageColor3 = accent
					end
				end
			end
			if v.Selected then
				v.Selected.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color(hue % 1)) or Color3.fromHSV(hue, sat, val)
				v.Selected.Title.TextColor3 = mainapi.GUIColor.Rainbow and Color3.new(0.19, 0.19, 0.19) or mainapi:TextColor(hue, sat, val)
				v.Selected.Dots.Dots.ImageColor3 = v.Selected.Title.TextColor3
				v.Selected.Bind.Icon.ImageColor3 = v.Selected.Title.TextColor3
				v.Selected.Bind.TextLabel.TextColor3 = v.Selected.Title.TextColor3
			end
		end
	end

	for _, button in mainapi.Modules do
		if button.Enabled then
			button.Object.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1)) or Color3.fromHSV(hue, sat, val)
			button.Object.TextColor3 = mainapi.GUIColor.Rainbow and Color3.new(0.19, 0.19, 0.19) or mainapi:TextColor(hue, sat, val)
			button.Object.UIGradient.Enabled = rainbow and mainapi.RainbowMode.Value == 'Gradient'
			if button.Object.UIGradient.Enabled then
				button.Object.BackgroundColor3 = Color3.new(1, 1, 1)
				button.Object.UIGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1))),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(mainapi:Color((hue - ((button.Index + 1) * 0.025)) % 1)))
				})
			end
			button.Object.Bind.Icon.ImageColor3 = button.Object.TextColor3
			button.Object.Bind.TextLabel.TextColor3 = button.Object.TextColor3
			button.Object.Dots.Dots.ImageColor3 = button.Object.TextColor3
		end

		for _, option in button.Options do
			if option.Color then
				option:Color(hue, sat, val, rainbow)
			end
		end

		for _, v in button.Tags do
			v.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1)) or button.Enabled and Color3.new(1, 1, 1) or Color3.fromHSV(hue, sat, val)
			v.BackgroundTransparency = (rainbow or not button.Enabled) and 0 or 0.85
			v:FindFirstChild('Text').TextColor3 = mainapi.GUIColor.Rainbow and Color3.new(0.19, 0.19, 0.19) or mainapi:TextColor(hue, sat, val)
		end
	end

	for i, v in mainapi.Overlays.Toggles do
		if v.Enabled then
			tween:Cancel(v.Object.Knob)
			v.Object.Knob.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (i * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
		end
	end

	if mainapi.Legit.Icon then
		mainapi.Legit.Icon.ImageColor3 = Color3.fromHSV(hue, sat, val)
	end

	if mainapi.Legit.Window.Visible then
		for _, v in mainapi.Legit.Modules do
			if v.Enabled then
				tween:Cancel(v.Object.Knob)
				v.Object.Knob.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			end

			for _, option in v.Options do
				if option.Color then
					option:Color(hue, sat, val, rainbow)
				end
			end
		end
	end
end

mainapi:Clean(notifications.ChildRemoved:Connect(function()
	for i, v in notifications:GetChildren() do
		if tween.Tween then
			tween:Tween(v, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
				Position = UDim2.new(1, 0, 1, -(29 + (78 * i)))
			})
		end
	end
end))

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
			tooltip.Visible = false
			mainapi:BlurCheck()
		end

		local toggled = false
		for i, v in mainapi.Modules do
			if checkKeybinds(mainapi.HeldKeybinds, v.Bind, inputObj.KeyCode.Name) then
				toggled = true
				if mainapi.ToggleNotifications.Enabled then
					mainapi:CreateNotification(i, (not v.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>"), 0.75)
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

	if mainapi.ThreadFix then
		setthreadidentity(8)
	end
	if clickgui.Visible then
		mainapi:QueueSave()
	end
end))

if not shared.updated then
	local prompted = false
	mainapi:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
		if prompted or not clickgui.Visible then return end
		prompted = true
		mainapi:PromptPresets()
	end))
end

return mainapi