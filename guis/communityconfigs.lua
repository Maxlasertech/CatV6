local env = ... or {}
local uipallet = env.uipallet
local color = env.color
local tween = env.tween
local mainapi = env.mainapi
local httpService = env.httpService
local inputService = env.inputService
local guiService = env.guiService
local runService = env.runService
local getConfigPath = env.getConfigPath
local loadJson = env.loadJson
local refreshConfigProfiles = env.refreshConfigProfiles
local communityConfigs = env.communityConfigs
local installBundledConfig = env.installBundledConfig
local applySavedConfig = env.applySavedConfig
local removeSavedConfig = env.removeSavedConfig
local clickgui = env.clickgui
local scale = env.scale
local gui = env.gui
local scaledgui = env.scaledgui
local tooltip = env.tooltip

--[[
	Config Manager — Rewrite
	Drop-in replacement for createConfigManager(categoryapi).

	Key design decisions:
	  • Three columns: Saved | Community | Preview
	  • Configs apply immediately on click — no separate "download then apply" step
	  • Community configs are fetched fresh each time they are selected and applied
	  • Saved configs are toggled on/off: clicking an active saved config deactivates
	    all its modules; clicking an inactive one activates them
	  • Import via paste box at the bottom — press Enter to apply instantly
	  • Compact rows (~48px), tight spacing, no wasted chrome
	  • Accent colour follows mainapi.GUIColor throughout
]]

local function createConfigManager(categoryapi)

	-- ─────────────────────────────────────────────────────────────────────────
	-- Helpers re-used from the outer scope (already defined in main.lua):
	--   uipallet, color, tween, addCorner, addBlur, getfontsize
	--   mainapi, httpService, inputService, guiService, runService
	--   getConfigPath, loadJson, refreshConfigProfiles
	--   communityConfigs, installBundledConfig, applySavedConfig
	--   removeSavedConfig, clickgui, scale, gui, scaledgui
	-- ─────────────────────────────────────────────────────────────────────────

	-- ── Palette ───────────────────────────────────────────────────────────────
	local BG    = Color3.fromRGB(10,  11,  18)
	local SURF  = Color3.fromRGB(14,  16,  26)
	local CARD  = Color3.fromRGB(18,  21,  34)
	local RAISED= Color3.fromRGB(22,  26,  40)
	local EDGE  = Color3.fromRGB(40,  46,  70)
	local MUTED = Color3.fromRGB(110, 118, 148)
	local WHITE = Color3.new(1, 1, 1)

	local function accent(v, s)
		return Color3.fromHSV(
			mainapi.GUIColor.Hue,
			math.clamp(mainapi.GUIColor.Sat * (s or 0.72), 0, 1),
			math.clamp(mainapi.GUIColor.Value * (v or 0.82), 0, 1)
		)
	end
	local function accentBg(a)  -- very dark tint
		return Color3.fromHSV(mainapi.GUIColor.Hue, math.clamp(mainapi.GUIColor.Sat * 0.45, 0, 0.65), a or 0.16)
	end
	local function accentText()
		return Color3.fromHSV(mainapi.GUIColor.Hue, math.clamp(mainapi.GUIColor.Sat, 0, 0.80), 1)
	end

	-- tracked accent-linked objects {obj, prop, fn}
	local accentLinks = {}
	local function linkAccent(obj, prop, fn)
		table.insert(accentLinks, {obj = obj, prop = prop, fn = fn})
		obj[prop] = fn()
	end
	local function refreshAccents()
		for i = #accentLinks, 1, -1 do
			local l = accentLinks[i]
			if not l.obj or not l.obj.Parent then
				table.remove(accentLinks, i)
			else
				l.obj[l.prop] = l.fn()
			end
		end
	end

	-- ── Utility ───────────────────────────────────────────────────────────────
	local function trim(s)
		return type(s) == "string" and s:match("^%s*(.-)%s*$") or ""
	end

	local function corner(obj, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = r or UDim.new(0, 7)
		c.Parent = obj
		return c
	end

	local function stroke(obj, col, t)
		local s = Instance.new("UIStroke")
		s.Color = col or EDGE
		s.Transparency = t or 0.18
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = obj
		return s
	end

	local function label(props)
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.FontFace = props.semi and uipallet.FontSemiBold or uipallet.Font
		lbl.TextSize  = props.size  or 12
		lbl.TextColor3 = props.col or WHITE
		lbl.Text = props.text or ""
		lbl.Size = props.sz or UDim2.fromScale(1, 1)
		lbl.Position = props.pos or UDim2.new()
		if props.parent then lbl.Parent = props.parent end
		if props.wrap  then lbl.TextWrapped = true end
		if props.trunc then lbl.TextTruncate = Enum.TextTruncate.AtEnd end
		return lbl
	end

	local function pad(obj, l, r, t, b)
		local p = Instance.new("UIPadding")
		p.PaddingLeft   = UDim.new(0, l or 0)
		p.PaddingRight  = UDim.new(0, r or 0)
		p.PaddingTop    = UDim.new(0, t or 0)
		p.PaddingBottom = UDim.new(0, b or 0)
		p.Parent = obj
	end

	local function scrollFrame(parent, x, y, w, h)
		local sf = Instance.new("ScrollingFrame")
		sf.Position = UDim2.fromOffset(x, y)
		sf.Size     = UDim2.new(w or 1, -20, h or 1, -(y + 8))
		sf.BackgroundTransparency = 1
		sf.BorderSizePixel = 0
		sf.ScrollBarThickness = 3
		sf.ScrollBarImageTransparency = 0.12
		sf.CanvasSize = UDim2.new()
		sf.Parent = parent
		linkAccent(sf, "ScrollBarImageColor3", accentText)

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 5)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = sf

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			sf.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12)
		end)

		return sf, layout
	end

	local function divLine(parent, y)
		local d = Instance.new("Frame")
		d.Size = UDim2.new(1, 0, 0, 1)
		d.Position = UDim2.fromOffset(0, y or 0)
		d.BackgroundColor3 = EDGE
		d.BackgroundTransparency = 0.30
		d.BorderSizePixel = 0
		d.Parent = parent
		return d
	end

	-- Tiny badge pill
	local function pill(parent, text, col, tcol, x, y)
		local p = Instance.new("TextLabel")
		local tw = math.max(32, #text * 6 + 14)
		p.Size = UDim2.fromOffset(tw, 17)
		p.Position = UDim2.fromOffset(x or 0, y or 0)
		p.BackgroundColor3 = col
		p.Text = text
		p.TextSize = 9
		p.TextColor3 = tcol
		p.FontFace = uipallet.FontSemiBold
		p.Parent = parent
		corner(p, UDim.new(0, 5))
		return p
	end

	-- ── Config data ───────────────────────────────────────────────────────────
	local CONFIG_META = {
		cc            = { label = "CC",           desc = "Core legitimate config for everyday PvP.",                tags = {"Verified", "Safe"} },
		legit         = { label = "Legit+",        desc = "Smooth legit setup with soft movement.",                   tags = {"Verified", "Low-Flag"} },
		["bedwars sweat"] = { label = "BW Sweat", desc = "Tuned for BedWars wins — clean and reliable.",            tags = {"Featured", "Safe"} },
		["sky pvp"]   = { label = "Sky PvP",       desc = "Aerial fight awareness and clean combat.",                tags = {"New", "Safe"} },
		["utility stack"] = { label = "Util Stack",desc = "Quality-of-life modules stacked for every match.",       tags = {"Verified", "QOL"} },
		rage          = { label = "Rage",           desc = "Max pressure, fast eliminations. Use in casual lobbies.", tags = {"Verified", "High-Risk"} },
	}

	-- ── Apply a config: parse JSON → toggle modules ────────────────────────────
	--   configData = raw JSON string OR decoded table
	local function applyConfigData(configData)
		local decoded
		if type(configData) == "string" then
			local ok, res = pcall(function() return httpService:JSONDecode(configData) end)
			if not ok or type(res) ~= "table" then return false, "Invalid JSON" end
			decoded = res
		elseif type(configData) == "table" then
			decoded = configData
		else
			return false, "No data"
		end

		-- Support both raw {Modules={...}} and wrapped {config="...", ...}
		if type(decoded.config) == "string" then
			local ok, inner = pcall(function() return httpService:JSONDecode(decoded.config) end)
			if ok and type(inner) == "table" then decoded = inner end
		end

		local modulesData = decoded.Modules
		if type(modulesData) ~= "table" then return false, "No module data" end

		-- First pass: disable all currently enabled modules
		for _, mod in mainapi.Modules do
			if mod.Enabled then mod:Toggle(true) end
		end

		-- Second pass: enable modules listed as Enabled in config
		local toggled = 0
		for name, data in modulesData do
			local mod = mainapi.Modules[name]
			if mod and type(data) == "table" then
				-- Options first
				if data.Options then
					mainapi:LoadOptions(mod, data.Options)
				end
				-- Keybinds
				if data.Bind then
					mod:SetBind(data.Bind)
				end
				-- Toggle state
				if data.Enabled and not mod.Enabled then
					mod:Toggle(true)
					toggled += 1
				end
			end
		end

		mainapi:UpdateTextGUI(true)
		return true, toggled
	end

	-- Read a community config file (bundled), return decoded table
	local function readBundledConfig(name)
		local path = "aethercorev2/configs/"..name..".json"
		if not isfile(path) then return nil end
		local raw = loadJson(path)
		if not raw then return nil end
		-- unwrap
		if type(raw.config) == "string" then
			local ok, inner = pcall(function() return httpService:JSONDecode(raw.config) end)
			if ok and type(inner) == "table" then return inner end
		end
		return raw
	end

	-- Download a bundled config from the repo then apply it
	local function downloadAndApply(name, callback)
		task.spawn(function()
			local path = "aethercorev2/configs/"..name..".json"
			local suc, err = pcall(function()
				local res = game:HttpGet(
					"https://raw.githubusercontent.com/plutoxqqq/AetherCoreV2/"
					..readfile("aethercorev2/profiles/commit.txt")
					.."/configs/"..name..".json", true
				)
				if res == "404: Not Found" then error("404") end
				writefile(path, res)
			end)
			if suc then
				local data = readBundledConfig(name)
				if data then
					local ok, count = applyConfigData(data)
					if callback then callback(ok, count) end
				else
					if callback then callback(false, "Parse failed") end
				end
			else
				-- fallback: try to apply from disk if already exists
				local data = readBundledConfig(name)
				if data then
					local ok, count = applyConfigData(data)
					if callback then callback(ok, count) end
				else
					if callback then callback(false, err) end
				end
			end
		end)
	end

	-- ── Root blocker + frame ──────────────────────────────────────────────────
	local blocker = Instance.new("TextButton")
	blocker.Name = "ConfigManagerBlocker"
	blocker.Size = UDim2.fromScale(1, 1)
	blocker.BackgroundTransparency = 1
	blocker.Text = ""
	blocker.AutoButtonColor = false
	blocker.ZIndex = 49
	blocker.Visible = false
	blocker.Parent = clickgui

	local manager = Instance.new("Frame")
	manager.Name = "ConfigManager"
	manager.Size = UDim2.new(1, -28, 1, -28)
	manager.Position = UDim2.fromOffset(14, 14)
	manager.BackgroundColor3 = BG
	manager.ZIndex = 50
	manager.Visible = false
	manager.ClipsDescendants = true
	manager.Parent = clickgui
	corner(manager, UDim.new(0, 10))

	-- ensure all descendants sit above z=50
	manager.DescendantAdded:Connect(function(d)
		if d:IsA("GuiObject") then d.ZIndex = math.max(d.ZIndex, 51) end
	end)

	-- subtle accent border
	local mgStroke = stroke(manager, EDGE, 0.10)
	linkAccent(mgStroke, "Color", function() return accent(1, 0.85) end)

	-- dark gradient wash
	local mgGrad = Instance.new("UIGradient")
	mgGrad.Rotation = 30
	mgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(11, 13, 22)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB( 9, 10, 17)),
	})
	mgGrad.Parent = manager

	-- ── Header (56px) ────────────────────────────────────────────────────────
	local HDR = 56
	local hdr = Instance.new("Frame")
	hdr.Size = UDim2.new(1, 0, 0, HDR)
	hdr.BackgroundColor3 = SURF
	hdr.BorderSizePixel = 0
	hdr.Parent = manager

	divLine(hdr, HDR - 1)

	-- top accent line
	local accentLine = Instance.new("Frame")
	accentLine.Size = UDim2.new(1, 0, 0, 2)
	accentLine.BackgroundTransparency = 0.06
	accentLine.BorderSizePixel = 0
	accentLine.Parent = hdr
	linkAccent(accentLine, "BackgroundColor3", function() return accent(0.95, 0.65) end)

	-- icon box
	local iconBox = Instance.new("Frame")
	iconBox.Size = UDim2.fromOffset(32, 32)
	iconBox.Position = UDim2.fromOffset(16, 12)
	iconBox.BorderSizePixel = 0
	iconBox.Parent = hdr
	corner(iconBox, UDim.new(0, 7))
	linkAccent(iconBox, "BackgroundColor3", function() return accentBg(0.24) end)

	local iconLbl = label({text = "⊞", size = 16, pos = UDim2.new(), sz = UDim2.fromScale(1,1), parent = iconBox})
	iconLbl.TextXAlignment = Enum.TextXAlignment.Center
	iconLbl.TextYAlignment = Enum.TextYAlignment.Center
	linkAccent(iconLbl, "TextColor3", accentText)

	local titleLbl = label({text = "Configs", size = 18, semi = true, col = WHITE,
		pos = UDim2.fromOffset(58, 8), sz = UDim2.fromOffset(260, 22), parent = hdr})
	local subLbl = label({text = "Select a community config to apply instantly, or manage your saved profiles.",
		size = 10, col = MUTED, pos = UDim2.fromOffset(59, 31), sz = UDim2.new(0.6, 0, 0, 14), parent = hdr})

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -42, 0, 14)
	closeBtn.BackgroundColor3 = RAISED
	closeBtn.AutoButtonColor = false
	closeBtn.Text = "×"
	closeBtn.TextSize = 20
	closeBtn.TextColor3 = MUTED
	closeBtn.FontFace = uipallet.Font
	closeBtn.Parent = hdr
	corner(closeBtn, UDim.new(0, 7))
	closeBtn.MouseEnter:Connect(function()
		tween:Tween(closeBtn, uipallet.Tween, {BackgroundColor3 = Color3.fromRGB(55, 20, 30), TextColor3 = WHITE})
	end)
	closeBtn.MouseLeave:Connect(function()
		tween:Tween(closeBtn, uipallet.Tween, {BackgroundColor3 = RAISED, TextColor3 = MUTED})
	end)

	-- ── Three-column layout ──────────────────────────────────────────────────
	--   A: Saved  30%   B: Community  26%   C: Preview 44%
	local CONTENT_Y = HDR + 10
	local BOT_H = 52
	local COL_PAD = 10  -- gap between columns and edges

	local function makeCol(xScale, xOff, wScale, wOff)
		local f = Instance.new("Frame")
		f.Position = UDim2.new(xScale, xOff, 0, CONTENT_Y)
		f.Size = UDim2.new(wScale, wOff, 1, -(CONTENT_Y + BOT_H + 10))
		f.BackgroundColor3 = SURF
		f.ClipsDescendants = false
		f.Parent = manager
		corner(f, UDim.new(0, 8))
		stroke(f, EDGE, 0.25)

		-- subtle top accent strip
		local top = Instance.new("Frame")
		top.Size = UDim2.new(1, 0, 0, 2)
		top.BackgroundTransparency = 0.15
		top.BorderSizePixel = 0
		top.Parent = f
		linkAccent(top, "BackgroundColor3", function() return accent(0.82, 0.55) end)
		corner(top, UDim.new(0, 8))

		return f
	end

	local colA = makeCol(0,           COL_PAD,       0.30, -COL_PAD - 4)
	local colB = makeCol(0.30,        COL_PAD + 2,   0.26, -COL_PAD - 4)
	local colC = makeCol(0.56,        COL_PAD + 4,   0.44, -COL_PAD - 14)

	-- Column headers
	local function colHeader(col, icon, title)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, 40)
		f.BackgroundTransparency = 1
		f.Parent = col

		local ico = label({text = icon, size = 13, col = MUTED,
			pos = UDim2.fromOffset(12, 0), sz = UDim2.fromOffset(20, 40), parent = f})
		ico.TextXAlignment = Enum.TextXAlignment.Center
		ico.TextYAlignment = Enum.TextYAlignment.Center

		local t = label({text = title, size = 12, semi = true, col = WHITE,
			pos = UDim2.fromOffset(34, 0), sz = UDim2.new(1, -90, 1, 0), parent = f})
		t.TextYAlignment = Enum.TextYAlignment.Center

		divLine(f, 39)
		return f
	end

	colHeader(colA, "⊟", "Saved Configs")
	colHeader(colB, "◈", "Community")
	colHeader(colC, "▤", "Preview")

	-- Scroll lists
	local savedList, savedLayout = scrollFrame(colA, 10, 48, 1, 0)
	savedList.Size = UDim2.new(1, -20, 1, -(48 + 52))  -- leave room for search

	local communityList, communityLayout = scrollFrame(colB, 10, 48, 1, 0)
	communityList.Size = UDim2.new(1, -20, 1, -(48 + 52))

	local previewList, previewLayout = scrollFrame(colC, 10, 48, 1, 0)
	previewList.Size = UDim2.new(1, -20, 1, -(48 + 10))

	-- ── Search box (saved panel) ──────────────────────────────────────────────
	local searchBg = Instance.new("Frame")
	searchBg.Size = UDim2.new(1, -20, 0, 32)
	searchBg.Position = UDim2.new(0, 10, 1, -42)
	searchBg.BackgroundColor3 = CARD
	searchBg.BorderSizePixel = 0
	searchBg.Parent = colA
	corner(searchBg)
	stroke(searchBg, EDGE, 0.20)

	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -12, 1, 0)
	searchBox.Position = UDim2.fromOffset(10, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.PlaceholderText = "⌕  Search saved..."
	searchBox.Text = ""
	searchBox.TextColor3 = WHITE
	searchBox.PlaceholderColor3 = MUTED
	searchBox.TextSize = 11
	searchBox.FontFace = uipallet.Font
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchBg

	-- ── Community apply btn ───────────────────────────────────────────────────
	local function makeActionBtn(parent, text, style, callback)
		-- style: "primary" | "danger" | "neutral"
		local isPrimary = style == "primary"
		local isDanger  = style == "danger"

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -20, 0, 32)
		btn.Position = UDim2.new(0, 10, 1, -42)
		btn.AutoButtonColor = false
		btn.Text = text
		btn.TextSize = 12
		btn.FontFace = isPrimary and uipallet.FontSemiBold or uipallet.Font
		btn.Parent = parent
		corner(btn)

		local function setBg(hover)
			if isPrimary then
				btn.BackgroundColor3 = hover and accent(1.0, 0.80) or accent(0.78, 0.68)
				btn.TextColor3 = mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
			elseif isDanger then
				btn.BackgroundColor3 = hover and Color3.fromRGB(60, 15, 24) or Color3.fromRGB(36, 10, 18)
				btn.TextColor3 = Color3.fromRGB(248, 80, 96)
			else
				btn.BackgroundColor3 = hover and RAISED or CARD
				btn.TextColor3 = MUTED
			end
		end
		setBg(false)

		if isPrimary then
			linkAccent(btn, "BackgroundColor3", function() return accent(0.78, 0.68) end)
		end

		btn.MouseEnter:Connect(function()  setBg(true)  end)
		btn.MouseLeave:Connect(function()  setBg(false) end)
		if callback then btn.MouseButton1Click:Connect(callback) end
		return btn
	end

	-- ── Row factory ───────────────────────────────────────────────────────────
	local function makeRow(parent, opts)
		-- opts: name, meta, selected, onSelect, isCommunity, isInstalled
		local ROW_H = 52
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -2, 0, ROW_H)
		row.BackgroundColor3 = opts.selected and accentBg(0.22) or CARD
		row.AutoButtonColor = false
		row.Text = ""
		row.Parent = parent
		corner(row, UDim.new(0, 7))

		local rowStroke = stroke(row, opts.selected and accentText() or EDGE, opts.selected and 0.06 or 0.28)
		if opts.selected then
			linkAccent(rowStroke, "Color", accentText)
			linkAccent(row, "BackgroundColor3", function() return accentBg(0.22) end)
		end

		-- Avatar swatch
		local av = Instance.new("Frame")
		av.Size = UDim2.fromOffset(34, 34)
		av.Position = UDim2.fromOffset(9, 9)
		av.BackgroundColor3 = opts.selected and accent(0.82, 0.76) or RAISED
		av.BorderSizePixel = 0
		av.Parent = row
		corner(av, UDim.new(0, 7))
		if opts.selected then linkAccent(av, "BackgroundColor3", function() return accent(0.82, 0.76) end) end

		local avLbl = label({
			text = opts.meta and opts.meta.label and opts.meta.label:upper():sub(1,2) or opts.name:upper():sub(1,2),
			size = 11, semi = true,
			col = opts.selected and mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or MUTED,
			parent = av
		})
		avLbl.TextXAlignment = Enum.TextXAlignment.Center
		avLbl.TextYAlignment = Enum.TextYAlignment.Center

		-- Name
		local nameLbl = label({
			text = opts.meta and opts.meta.label or opts.name,
			size = 13, semi = true,
			col = opts.selected and WHITE or Color3.fromRGB(190, 196, 220),
			pos = UDim2.fromOffset(52, 7),
			sz  = UDim2.new(1, -120, 0, 19),
			trunc = true, parent = row
		})

		-- Sub-line
		label({
			text = opts.isCommunity and "AetherCore Team" or (opts.name == "default" and "Default" or "Local"),
			size = 10, col = MUTED,
			pos = UDim2.fromOffset(52, 28), sz = UDim2.new(1, -110, 0, 14),
			parent = row
		})

		-- Status badge (top-right)
		if opts.selected then
			pill(row, "ACTIVE", accentBg(0.22), accentText(), 0, 8).Position = UDim2.new(1, -68, 0, 8)
			linkAccent(row:FindFirstChildOfClass("TextLabel"), "BackgroundColor3", function() return accentBg(0.22) end)
		elseif opts.isCommunity then
			local installed = opts.isInstalled
			pill(row, installed and "ON DISK" or "CLOUD",
				installed and Color3.fromRGB(14, 38, 24) or Color3.fromRGB(20, 22, 38),
				installed and Color3.fromRGB(60, 200, 100) or MUTED,
				0, 8).Position = UDim2.new(1, -70, 0, 8)
		end

		row.MouseEnter:Connect(function()
			if not opts.selected then
				tween:Tween(row, uipallet.Tween, {BackgroundColor3 = RAISED})
			end
		end)
		row.MouseLeave:Connect(function()
			if not opts.selected then
				tween:Tween(row, uipallet.Tween, {BackgroundColor3 = CARD})
			end
		end)
		if opts.onSelect then row.MouseButton1Click:Connect(opts.onSelect) end
		return row
	end

	-- ── Preview pane helpers ──────────────────────────────────────────────────
	local function previewSection(text)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, 24)
		f.BackgroundTransparency = 1
		f.Parent = previewList
		label({text = text:upper(), size = 9, semi = true, col = MUTED, parent = f,
			pos = UDim2.fromOffset(2, 0), sz = UDim2.new(1, -4, 1, 0)})
	end

	local function previewRow(left, right, active)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, 20)
		f.BackgroundTransparency = 1
		f.Parent = previewList

		local b = label({text = "•", size = 12, semi = true,
			col = active and accentText() or MUTED,
			pos = UDim2.fromOffset(0, 0), sz = UDim2.fromOffset(14, 20), parent = f})
		b.TextYAlignment = Enum.TextYAlignment.Center
		if active then linkAccent(b, "TextColor3", accentText) end

		label({text = left, size = 11, col = active and WHITE or MUTED,
			pos = UDim2.fromOffset(16, 0), sz = UDim2.new(1, -80, 1, 0),
			trunc = true, parent = f})

		local r = label({text = right or "", size = 10,
			col = active and accentText() or MUTED,
			pos = UDim2.new(1, -70, 0, 0), sz = UDim2.fromOffset(68, 20), parent = f})
		r.TextXAlignment = Enum.TextXAlignment.Right
		if active then linkAccent(r, "TextColor3", accentText) end
	end

	local function previewNote(text)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, 28)
		f.BackgroundTransparency = 1
		f.Parent = previewList
		label({text = text, size = 10, col = MUTED, wrap = true,
			pos = UDim2.fromOffset(2, 0), sz = UDim2.new(1, -4, 1, 0), parent = f})
	end

	-- ── State ─────────────────────────────────────────────────────────────────
	local selectedSaved     = mainapi.Profile or "default"
	local selectedCommunity = communityConfigs[1] or "cc"
	local previewMode       = "community"   -- "saved" | "community"
	local statusMsg         = ""

	-- ── Refresh preview ───────────────────────────────────────────────────────
	local function clearChildren(frame)
		for _, c in frame:GetChildren() do
			if c:IsA("GuiObject") then c:Destroy() end
		end
	end

	local function refreshPreview()
		clearChildren(previewList)

		local name    = previewMode == "saved" and selectedSaved or selectedCommunity
		local bundled = previewMode == "community"
		local meta    = bundled and CONFIG_META[name] or nil

		-- Header card
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 78)
		card.BackgroundColor3 = CARD
		card.BorderSizePixel = 0
		card.Parent = previewList
		corner(card)

		local avCard = Instance.new("Frame")
		avCard.Size = UDim2.fromOffset(42, 42)
		avCard.Position = UDim2.fromOffset(10, 10)
		avCard.BorderSizePixel = 0
		avCard.Parent = card
		corner(avCard, UDim.new(0, 8))
		linkAccent(avCard, "BackgroundColor3", function() return accent(0.82, 0.76) end)

		local initials = meta and (meta.label or name):upper():sub(1,2) or name:upper():sub(1,2)
		local avLbl2 = label({text = initials, size = 14, semi = true, parent = avCard})
		avLbl2.TextXAlignment = Enum.TextXAlignment.Center
		avLbl2.TextYAlignment = Enum.TextYAlignment.Center
		avLbl2.TextColor3 = WHITE

		label({text = meta and meta.label or name, size = 15, semi = true, col = WHITE,
			pos = UDim2.fromOffset(62, 8), sz = UDim2.new(1, -74, 0, 22), parent = card})
		label({text = bundled and "AetherCore Team" or "local config",
			size = 10, col = MUTED, pos = UDim2.fromOffset(62, 30), sz = UDim2.new(1, -74, 0, 14), parent = card})
		label({text = meta and meta.desc or (bundled and "Community configuration." or "Your saved local configuration."),
			size = 10, col = MUTED, wrap = true,
			pos = UDim2.fromOffset(10, 56), sz = UDim2.new(1, -20, 0, 18), parent = card})

		-- Tags
		if meta and meta.tags then
			local tx = 10
			for _, t in meta.tags do
				local tp = pill(card, t, accentBg(0.18), accentText(), tx, 2)
				tp.Position = UDim2.fromOffset(tx, 2)
				linkAccent(tp, "BackgroundColor3", function() return accentBg(0.18) end)
				linkAccent(tp, "TextColor3", accentText)
				tx = tx + tp.Size.X.Offset + 5
			end
		end

		-- Status message
		if statusMsg ~= "" then
			local msgF = Instance.new("Frame")
			msgF.Size = UDim2.new(1, 0, 0, 24)
			msgF.BackgroundColor3 = accentBg(0.18)
			msgF.BorderSizePixel = 0
			msgF.Parent = previewList
			corner(msgF)
			label({text = statusMsg, size = 11, col = accentText(),
				pos = UDim2.fromOffset(10, 0), sz = UDim2.new(1, -14, 1, 0), parent = msgF})
		end

		-- Module summary from current mainapi state
		local enabled, total = {}, 0
		for n, mod in mainapi.Modules do
			total += 1
			if mod.Enabled then table.insert(enabled, n) end
		end

		-- Stat row
		local statF = Instance.new("Frame")
		statF.Size = UDim2.new(1, 0, 0, 40)
		statF.BackgroundColor3 = CARD
		statF.BorderSizePixel = 0
		statF.Parent = previewList
		corner(statF)

		local stats = {
			{"Total", tostring(total)},
			{"Enabled", tostring(#enabled)},
			{"Profile", selectedSaved}
		}
		for i, s in stats do
			local seg = Instance.new("Frame")
			seg.Size = UDim2.new(1/#stats, 0, 1, 0)
			seg.Position = UDim2.fromScale((i-1)/#stats, 0)
			seg.BackgroundTransparency = 1
			seg.Parent = statF
			if i > 1 then
				local sep = Instance.new("Frame")
				sep.Size = UDim2.fromOffset(1, 22)
				sep.Position = UDim2.new(0, 0, 0.5, -11)
				sep.BackgroundColor3 = EDGE
				sep.BackgroundTransparency = 0.30
				sep.BorderSizePixel = 0
				sep.Parent = seg
			end
			local vl = label({text = s[2], size = 14, semi = true, parent = seg,
				pos = UDim2.fromOffset(0, 5), sz = UDim2.new(1, 0, 0, 18)})
			vl.TextXAlignment = Enum.TextXAlignment.Center
			linkAccent(vl, "TextColor3", accentText)
			local sl = label({text = s[1], size = 9, col = MUTED, parent = seg,
				pos = UDim2.fromOffset(0, 24), sz = UDim2.new(1, 0, 0, 12)})
			sl.TextXAlignment = Enum.TextXAlignment.Center
		end

		-- Active modules list
		previewSection("Active Modules")
		local shown = 0
		table.sort(enabled)
		for _, n in enabled do
			if shown >= 12 then break end
			shown += 1
			previewRow(n, "ON", true)
		end
		if shown == 0 then
			previewNote("No modules enabled.")
		end
		if #enabled > shown then
			previewNote("+"..tostring(#enabled - shown).." more enabled.")
		end
	end

	-- ── Main refresh ──────────────────────────────────────────────────────────
	local function refreshManager()
		refreshConfigProfiles()
		refreshAccents()

		clearChildren(savedList)
		clearChildren(communityList)

		local filter = searchBox.Text:lower()

		for _, p in mainapi.Profiles do
			if filter == "" or p.Name:lower():find(filter, 1, true) then
				makeRow(savedList, {
					name = p.Name,
					selected = p.Name == mainapi.Profile,
					isCommunity = false,
					onSelect = function()
						selectedSaved = p.Name
						previewMode = "saved"
						-- Apply the saved config immediately
						mainapi:Save()
						mainapi:Load(true, p.Name)
						mainapi:Save()
						statusMsg = "Applied: "..p.Name
						refreshManager()
					end
				})
			end
		end

		for _, name in communityConfigs do
			local installed = isfile("aethercorev2/configs/"..name..".json")
			makeRow(communityList, {
				name = name,
				meta = CONFIG_META[name],
				selected = name == selectedCommunity and previewMode == "community",
				isCommunity = true,
				isInstalled = installed,
				onSelect = function()
					selectedCommunity = name
					previewMode = "community"
					refreshManager()
				end
			})
		end

		refreshPreview()
	end

	-- ── Action button row (community panel) ───────────────────────────────────
	local applyBtn = makeActionBtn(colB, "▶  Apply Config", "primary", function()
		statusMsg = "Applying "..selectedCommunity.."..."
		refreshPreview()

		local installed = isfile("aethercorev2/configs/"..selectedCommunity..".json")
		if installed then
			-- Already on disk — apply directly
			local data = readBundledConfig(selectedCommunity)
			if data then
				local ok, count = applyConfigData(data)
				statusMsg = ok and ("✓ Applied — "..tostring(count).." modules on") or "Failed: "..tostring(count)
				-- Save as a named profile
				selectedSaved = selectedCommunity
				mainapi.Profile = selectedCommunity
				if not mainapi.Profiles then mainapi.Profiles = {} end
				local found = false
				for _, p in mainapi.Profiles do
					if p.Name == selectedCommunity then found = true break end
				end
				if not found then
					table.insert(mainapi.Profiles, {Name = selectedCommunity, Bind = {}})
				end
				mainapi:Save(selectedCommunity)
				refreshManager()
			else
				statusMsg = "Failed to read config."
				refreshPreview()
			end
		else
			-- Download first, then apply
			downloadAndApply(selectedCommunity, function(ok, result)
				statusMsg = ok and ("✓ Applied — "..tostring(result).." modules on") or "Download failed."
				selectedSaved = selectedCommunity
				mainapi.Profile = selectedCommunity
				local found = false
				for _, p in mainapi.Profiles do
					if p.Name == selectedCommunity then found = true break end
				end
				if not found then
					table.insert(mainapi.Profiles, {Name = selectedCommunity, Bind = {}})
				end
				pcall(function() mainapi:Save(selectedCommunity) end)
				refreshManager()
			end)
		end
	end)
	applyBtn.Position = UDim2.new(0, 10, 1, -42)

	-- ── Saved panel actions ───────────────────────────────────────────────────
	-- New profile button
	local newBtn = makeActionBtn(colA, "+ New Config", "neutral", function()
		local newName = "config"..tostring(#mainapi.Profiles + 1)
		table.insert(mainapi.Profiles, {Name = newName, Bind = {}})
		mainapi:Save(newName)
		selectedSaved = newName
		previewMode = "saved"
		refreshManager()
	end)
	newBtn.Position = UDim2.new(0, 10, 1, -42)
	newBtn.Size = UDim2.new(0.48, -14, 0, 32)

	local deleteBtn = makeActionBtn(colA, "⌫ Delete", "danger", function()
		local target = selectedSaved
		if target == "default" then
			statusMsg = "Cannot delete default."
			refreshPreview()
			return
		end
		-- remove
		for i = #mainapi.Profiles, 1, -1 do
			if mainapi.Profiles[i].Name == target then
				table.remove(mainapi.Profiles, i)
			end
		end
		if isfile(getConfigPath(target)) and delfile then
			delfile(getConfigPath(target))
		end
		mainapi.Profile = "default"
		selectedSaved = "default"
		mainapi:Save("default")
		statusMsg = "Deleted: "..target
		refreshManager()
	end)
	deleteBtn.Position = UDim2.new(0.52, -4, 1, -42)
	deleteBtn.Size = UDim2.new(0.48, -6, 0, 32)
	deleteBtn.TextSize = 11

	-- ── Bottom bar — Import ───────────────────────────────────────────────────
	local botBar = Instance.new("Frame")
	botBar.Size = UDim2.new(1, 0, 0, BOT_H)
	botBar.Position = UDim2.new(0, 0, 1, -BOT_H)
	botBar.BackgroundColor3 = SURF
	botBar.BorderSizePixel = 0
	botBar.Parent = manager
	divLine(botBar, 0)

	local importBg = Instance.new("Frame")
	importBg.Size = UDim2.new(0.72, -20, 0, 34)
	importBg.Position = UDim2.fromOffset(COL_PAD, 9)
	importBg.BackgroundColor3 = CARD
	importBg.BorderSizePixel = 0
	importBg.Parent = botBar
	corner(importBg)
	stroke(importBg, EDGE, 0.22)

	local importBox = Instance.new("TextBox")
	importBox.Size = UDim2.new(1, -16, 1, 0)
	importBox.Position = UDim2.fromOffset(10, 0)
	importBox.BackgroundTransparency = 1
	importBox.PlaceholderText = "⌨  Paste exported JSON config here and press Enter to import..."
	importBox.Text = ""
	importBox.TextColor3 = WHITE
	importBox.PlaceholderColor3 = MUTED
	importBox.TextSize = 11
	importBox.FontFace = uipallet.Font
	importBox.ClearTextOnFocus = false
	importBox.Parent = importBg

	local exportBtn = makeActionBtn(botBar, "↑ Export", "neutral", function()
		local tab = {}
		if isfile(getConfigPath(mainapi.Profile)) then
			tab.config = readfile(getConfigPath(mainapi.Profile))
		end
		if isfile("aethercorev2/profiles/"..game.GameId..".gui.txt") then
			tab.gui = readfile("aethercorev2/profiles/"..game.GameId..".gui.txt")
		end
		tab.game = tostring(game.PlaceId)
		setclipboard(httpService:JSONEncode(tab))
		statusMsg = "Copied to clipboard!"
		refreshPreview()
	end)
	exportBtn.Position = UDim2.new(0.72, COL_PAD, 0, 9)
	exportBtn.Size = UDim2.new(0.14, -8, 0, 34)

	local importActionBtn = makeActionBtn(botBar, "↥ Import", "primary", function()
		local text = trim(importBox.Text)
		if text == "" then return end
		local ok, result = pcall(function() return httpService:JSONDecode(text) end)
		if ok and type(result) == "table" then
			local name = "imported"..tostring(#mainapi.Profiles + 1)
			-- If it's a full export {config, gui}, extract config
			local configData = result
			if result.config then
				pcall(function()
					writefile(getConfigPath(name), result.config)
				end)
				if result.gui then
					pcall(function()
						writefile("aethercorev2/profiles/"..game.GameId..".gui.txt", result.gui)
					end)
				end
				-- decode config for immediate apply
				local ok2, inner = pcall(function() return httpService:JSONDecode(result.config) end)
				if ok2 then configData = inner end
			end
			local applied, count = applyConfigData(configData)
			table.insert(mainapi.Profiles, {Name = name, Bind = {}})
			pcall(function() mainapi:Save(name) end)
			selectedSaved = name
			mainapi.Profile = name
			importBox.Text = ""
			statusMsg = applied and ("✓ Imported — "..tostring(count).." modules on") or "Imported (no modules)."
			refreshManager()
		else
			statusMsg = "Invalid JSON."
			refreshPreview()
		end
	end)
	importActionBtn.Position = UDim2.new(0.86, COL_PAD, 0, 9)
	importActionBtn.Size = UDim2.new(0.14, -COL_PAD - 10, 0, 34)

	importBox.FocusLost:Connect(function(enter)
		if enter then importActionBtn.MouseButton1Click:Fire() end
	end)

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		clearChildren(savedList)
		refreshManager()
	end)

	-- ── Open / close wiring ───────────────────────────────────────────────────
	local function doClose()
		manager.Visible = false
		blocker.Visible = false
		categoryapi.Expanded = false
		categoryapi.Object.Visible = false
		if categoryapi.Button and categoryapi.Button.Enabled then
			-- manually untoggle without triggering re-open
			categoryapi.Button.Enabled = false
			categoryapi.Button.Object.TextColor3 = color.Dark(uipallet.Text, 0.16)
		end
	end

	closeBtn.MouseButton1Click:Connect(doClose)

	function categoryapi:Expand()
		local nowVisible = not manager.Visible
		manager.Visible = nowVisible
		blocker.Visible = nowVisible
		categoryapi.Expanded = nowVisible
		categoryapi.Object.Visible = false
		tooltip.Visible = false
		if categoryapi.Button then
			categoryapi.Button.Enabled = nowVisible
		end
		if nowVisible then
			selectedSaved = mainapi.Profile or selectedSaved
			statusMsg = ""
			refreshManager()
		end
	end

	if categoryapi.Button then
		local origToggle = categoryapi.Button.Toggle
		function categoryapi.Button:Toggle()
			origToggle(self)
			categoryapi.Object.Visible = false
			if not mainapi.Loaded then
				if self.Enabled then origToggle(self) end
				manager.Visible = false
				blocker.Visible = false
				categoryapi.Expanded = false
				return
			end
			manager.Visible = self.Enabled
			blocker.Visible = self.Enabled
			categoryapi.Expanded = self.Enabled
			tooltip.Visible = false
			if self.Enabled then
				selectedSaved = mainapi.Profile or selectedSaved
				statusMsg = ""
				refreshManager()
			end
		end
	end

	categoryapi.ConfigManager = manager
end

return createConfigManager
