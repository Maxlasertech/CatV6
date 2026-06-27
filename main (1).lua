--[[
    --------------------------------------------------------------
    -------------------------------------------------------------
    https://www.roblox.com/games/71480482338212/bedfight
    -------------------------------------------------------------
    -------------------------------------------------------------
--]]


repeat task.wait() until game:IsLoaded()

local hidden = get_hidden_gui or gethui
local _sti = setthreadidentity or (getfenv and getfenv().setthreadidentity) or nil

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Lighting = cloneref(game:GetService("Lighting"))
local Teams = cloneref(game:GetService("Teams"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local _GTS = cloneref(game:GetService("TextService"))
local _twCache = {}
local _ws = { string.char(70,105,114,101,83,101,114,118,101,114) }
local function measureTextW(txt, sz, font)
    local key = txt .. "\0" .. sz
    local cached = _twCache[key]
    if cached then return cached end
    local ok, v = pcall(function() return _GTS:GetTextSize(txt, sz, font, Vector2.new(9999, 9999)) end)
    local w = ok and v.X or #txt * sz * 0.55
    _twCache[key] = w
    return w
end

local lplr = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local UI, ops = phantom.UI, phantom.ops
local GuiLibrary, funcs = UI, ops
local Runtime = funcs.runtime
local RunLoops = Runtime.RunLoops
local runcode = Runtime.run
local createNotification = GuiLibrary.toast

local LongFly = {}
local projFireAt = nil
local PlayerUtility = phantom.module:Load("utility") or loadstring(readfile("Phantom/lib/Utility.lua"))()
local Prediction = phantom.module:Load("prediction") or loadstring(readfile("Phantom/lib/Prediction.lua"))()
local DrawLibrary = phantom.module:Load("fly") or loadstring(readfile("Phantom/lib/fly.lua"))()

local data = {
    hooked = {},
    matchState = 0,
    Attacking = false,
    attackingEntity = nil,
    gamemode = {
        value = nil,
        current = nil,
        connection = nil
    }
}

for _, v in ipairs({"Antideath", "Gravity", "ESP", "AntiFall", "TriggerBot", "AimAssist", "BreadCrumbs", "Speed", "Fly", "AntiAFK", "AntiFall", "Antideath", "AutoClicker", "ServerHop", "NoClip"}) do
    UI.kit:deregister(v .. "Module")
end

local bedfight = {
    remotes = {
        EquipTool = ReplicatedStorage.Remotes.ItemsRemotes.EquipTool,
        SwordHit = ReplicatedStorage.Remotes.ItemsRemotes.SwordHit,
        ShootProjectile = ReplicatedStorage.Remotes.ItemsRemotes.ShootProjectile,
        PutItemInChest = ReplicatedStorage.Remotes.PutItemInChest,
        TakeItemFromChest = ReplicatedStorage.Remotes.TakeItemFromChest
    },
    modules = {
        ItemsData = require(ReplicatedStorage.Modules.DataModules.ItemsData),
        InventoryHandler = require(ReplicatedStorage.Modules.InventoryHandler),
        EmotesData = require(ReplicatedStorage.Modules.DataModules.EmotesData),
        Signals = require(ReplicatedStorage.Modules.Signals),
        SwordController = require(ReplicatedStorage.ToolHandlers.Sword),
        Ranged = require(ReplicatedStorage.ToolHandlers.Ranged),
        CapesData = require(ReplicatedStorage.Modules.DataModules.CapesData),
        ImageAnimationController = require(ReplicatedStorage.Modules.ImageAnimationController),
        RangedData = require(ReplicatedStorage.Modules.DataModules.RangedData),
        ProjectilesData = require(ReplicatedStorage.Modules.DataModules.ProjectilesData),
        ProjectilesController = require(ReplicatedStorage.Modules.ProjectilesController),
        PlayerConfig = require(ReplicatedStorage.Modules.PlayerConfigurations),
        BlocksData = require(ReplicatedStorage.Modules.DataModules.BlocksData),
        JetpackState = require(ReplicatedStorage.Modules.JetpackState),
        SwordsData = require(ReplicatedStorage.Modules.DataModules.SwordsData),
        VelocityUtils = require(ReplicatedStorage.Modules.VelocityUtils),
        spawnFakeProjectile = nil,
    }
}
_ws[3], _ws[4] = bedfight.remotes.SwordHit, bedfight.modules.SwordsData

do -- update checker
    local HS = game:GetService("HttpService")
    local CFG = "Phantom/storage/config/gameVersion.json"
    if not isfolder("Phantom/storage/config") then makefolder("Phantom/storage/config") end
    if not isfile(CFG) then writefile(CFG, "{}") end
    task.spawn(function()
        task.wait(3)
        local mode = "Unknown"
        pcall(function()
            local gi = ReplicatedStorage:WaitForChild("GameInfo", 5)
            if gi then
                local gm = gi:WaitForChild("GameMode", 5)
                if gm and gm.Value ~= "" then mode = gm.Value end
            end
        end)
        local pv = game.PlaceVersion
        local fp = ""
        for _, s in ipairs({ ReplicatedStorage:FindFirstChild("Modules", true), ReplicatedStorage:WaitForChild("Remotes", 3), bedfight.modules.SwordController }) do
            if s then pcall(function() local ok, r = pcall(getscripthash, s); if ok then fp ..= r end end) end
        end
        fp = fp ~= "" and fp or nil
        local ok, t = pcall(function() return HS:JSONDecode(readfile(CFG)) end)
        local allModes = (ok and type(t) == "table") and t or {}
        if allModes.placeVersion then allModes = {} end
        local saved = allModes[mode]
        local entry = { placeVersion = pv, scriptHash = fp, savedAt = os.time() }
        if not saved then
            allModes[mode] = entry
            pcall(function() writefile(CFG, HS:JSONEncode(allModes)) end)
            return
        end
        if saved.placeVersion ~= pv or (fp and saved.scriptHash ~= fp) then
            local reason = saved.placeVersion ~= pv and ("v"..tostring(saved.placeVersion).." -> v"..pv) or "Script hashes changed (v"..pv..")"
            allModes[mode] = entry
            pcall(function() writefile(CFG, HS:JSONEncode(allModes)) end)
            createNotification("Update Checker", "["..mode.."] Game updated! "..reason, 8)
        else
            createNotification("Update Checker", "["..mode.."] v"..pv, 4)
        end
    end)
end

local rangedData = bedfight.modules.RangedData
local projData = bedfight.modules.ProjectilesData

local function getItemName(item)
    if not item then return nil end
    if type(item) == "string" then return item end
    if typeof(item) == "Instance" then
        local itemName = item.Name
        if itemName ~= "" then
            return itemName
        end
        return item:GetAttribute("itemType") or item:GetAttribute("ItemType")
    end
    if type(item) == "table" then
        return item.itemType or item.ItemType or item.name or item.Name or getItemName(item.item) or getItemName(item.tool)
    end
    return nil
end

local function namesMatch(lhs, rhs)
    return lhs and rhs and string.lower(lhs) == string.lower(rhs)
end

local function findTrackedItem(name, plr)
    plr = plr or lplr
    local hook = data.hooked[plr]
    if not hook or not name then return nil end

    local needle = string.lower(tostring(name))
    local partial
    for _, v in ipairs(hook.items) do
        local itemName = getItemName(v.item)
        if itemName then
            local lowered = string.lower(itemName)
            if lowered == needle then
                return v
            end
            if not partial and lowered:find(needle, 1, true) then
                partial = v
            end
        end
    end

    return partial
end

local function findFirstByName(parent, name)
    if not parent or not name then return nil end

    local direct = parent:FindFirstChild(name)
    if direct then
        return direct
    end

    for _, child in ipairs(parent:GetChildren()) do
        if namesMatch(getItemName(child), name) then
            return child
        end
    end
end

local function findToolInstance(name, plr)
    plr = plr or lplr
    local itemName = getItemName(name)
    if not itemName then return nil end

    local char = plr.Character
    local backpack = plr:FindFirstChild("Backpack")
    local tracked = findTrackedItem(itemName, plr)
    return findFirstByName(char, itemName) or findFirstByName(backpack, itemName) or (tracked and tracked.item)
end

local function getEntityCharacter(entry)
    if not entry then return nil end

    if typeof(entry) == "Instance" then
        if entry:IsA("Player") then
            return entry.Character
        end
        if entry:IsA("Model") then
            return entry
        end
    end

    if type(entry) ~= "table" then
        return nil
    end

    local direct = entry.character or entry.Character or entry.player
    if direct and direct ~= entry then
        local resolved = getEntityCharacter(direct)
        if resolved then
            return resolved
        end
    end

    local nested = entry.entity or entry.Entity
    if nested and nested ~= entry then
        return getEntityCharacter(nested)
    end

    return nil
end

local function findCharacterHitbox(character)
    if not character then return nil end

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local ok, hasTag = pcall(function()
                return descendant:HasTag("Hitbox")
            end)
            if ok and hasTag then
                return descendant
            end
        end
    end

    return character:FindFirstChild("Hitbox") or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart or character:FindFirstChildWhichIsA("BasePart")
end

local getEntityHitbox
getEntityHitbox = function(entry, character)
    if type(entry) == "table" then
        local hitbox = entry.hitbox or entry.Hitbox or entry.rootPart or entry.RootPart
        if typeof(hitbox) == "Instance" and hitbox:IsA("BasePart") then
            return hitbox
        end

        local nested = entry.entity or entry.Entity
        if nested and nested ~= entry then
            local nestedHitbox = getEntityHitbox(nested, character)
            if nestedHitbox then
                return nestedHitbox
            end
        end
    end

    character = character or getEntityCharacter(entry)
    return findCharacterHitbox(character)
end

local function buildSwordHitData(entry)
    local character = getEntityCharacter(entry)
    if not character then return nil end

    return character
end

local function isValidSwordHitCall(hitArg, swordArg, extraArg)
    if extraArg ~= nil then
        return false
    end

    local directSwordName = getItemName(hitArg)
    if directSwordName and bedfight.modules.SwordsData[directSwordName] then
        return typeof(swordArg) == "Instance"
    end

    local swordName = getItemName(swordArg)
    if not swordName or not bedfight.modules.SwordsData[swordName] then
        return false
    end

    local character = getEntityCharacter(hitArg)
    local hitbox = getEntityHitbox(hitArg, character)
    return typeof(character) == "Instance" and character:IsA("Model") and typeof(hitbox) == "Instance" and hitbox:IsA("BasePart")
end

local function sendRemote(remote, ...)
    if not remote then return nil end
    local args = table.pack(...)

    for _, methodName in ipairs({ "SendToServer", "sendToServer", "sendtoserver", "FireServer", "fireServer" }) do
        local ok, method = pcall(function()
            return remote[methodName]
        end)
        if ok and type(method) == "function" then
            return method(remote, table.unpack(args, 1, args.n))
        end
    end

    local ok, result = pcall(function()
        return remote:FireServer(table.unpack(args, 1, args.n))
    end)
    if ok then
        return result
    end

    ok, result = pcall(function()
        return remote:SendToServer(table.unpack(args, 1, args.n))
    end)
    if ok then
        return result
    end
end

do
    local _PC = bedfight.modules.ProjectilesController
    local _PD = bedfight.modules.ProjectilesData
    bedfight.modules.spawnFakeProjectile = function(origin, aimDir, launchVel, pName)
        if not _PC or not _PD then return end
        local pData = _PD[pName]
        local container = workspace:FindFirstChild("ProjectilesContainer")
        if not pData or not container then return end
        local ok, proj, token = pcall(function()
            local proj = _PC.new(nil, launchVel, pData)
            proj:AddProjectile(pData.Projectile or pName)
            proj.ProjectileRoot.CFrame = CFrame.lookAlong(origin, aimDir)
            proj.UpdatedVelocity = launchVel
            proj.Projectile.Parent = container
            local token = proj:Play()
            return proj, token
        end)
        if ok then
            return proj, token
        end
    end
end

local wsScriptChildren = {}
do
    local snapshot = {}
    for _, c in ipairs(workspace:GetChildren()) do snapshot[c] = true end
    workspace.ChildAdded:Connect(function(c)
        if not snapshot[c] then table.insert(wsScriptChildren, c) end
    end)
    workspace.ChildRemoved:Connect(function(c)
        for i = #wsScriptChildren, 1, -1 do
            if wsScriptChildren[i] == c then table.remove(wsScriptChildren, i); break end
        end
    end)
    _ws[2] = hookmetamethod(game, "__namecall", function(s, ...)
        if not checkcaller() and s == _ws[3] and getnamecallmethod() == _ws[1] then
            if not _ws[4][(select(1,...))] or typeof(select(2,...)) ~= "Instance" or select(3,...) ~= nil then return end
        end
        return _ws[2](s, ...)
    end)
end

local RANGED_NAMES = {}
if rangedData then
    for name in pairs(rangedData) do table.insert(RANGED_NAMES, name) end
end

local getRanged
local getBestProjectile

local Fly = {}
local Speed = {}
local infFlyVel = false

local bodyVel
local createBodyVel = function()
    if PlayerUtility.lplrIsAlive and ((bodyVel and not bodyVel.Parent.Parent) or not bodyVel) then
        bodyVel = Instance.new("BodyVelocity", lplr.Character.HumanoidRootPart)
        bodyVel.P = math.huge
        bodyVel.MaxForce = Vector3.one * bodyVel.P
        bodyVel.Velocity = Vector3.zero

        funcs:onExit("bodyVelHook", function()
            if bodyVel then
                bodyVel:Destroy()
            end
        end)
    end
end

local speedBoost = 0
local speedTimer = tick()

local SpeedMultiplier = function()
    return tick() <= speedTimer and speedBoost or 0
end

local function getHookId(plr)
    return "inv_" .. tostring((plr and plr.UserId) or "local")
end

funcs:onExit("_wsx", function() if _ws[2] then hookmetamethod(game, "__namecall", _ws[2]) end end)

local function cleanupHookinv(plr)
    local hook = data.hooked[plr]
    if not hook then return end

    for _, conn in ipairs(hook.conns) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end

    data.hooked[plr] = nil
end

Players.PlayerRemoving:Connect(function(plr)
    funcs:offExit(getHookId(plr))
    cleanupHookinv(plr)
end)

local hookinv = function(plr)
    plr = plr or lplr
    local inv = plr:FindFirstChild("Inventory") or plr:WaitForChild("Inventory", 5)
    if not inv then
        return
    end

    funcs:offExit(getHookId(plr))
    cleanupHookinv(plr)

    data.hooked[plr] = {
        inv = inv,
        items = {},
        conns = {}
    }

    local function addConn(conn)
        table.insert(data.hooked[plr].conns, conn)
        return conn
    end

    local function untrackItem(itemInstance)
        if not itemInstance then return end

        for idx, v in ipairs(data.hooked[plr].items) do
            if v.item == itemInstance then
                table.remove(data.hooked[plr].items, idx)
                break
            end
        end
    end

    local function trackItem(itemInstance, inventoryType, itemClass)
        if not itemInstance then return end

        for _, v in ipairs(data.hooked[plr].items) do
            if v.item == itemInstance then
                v.inventory = inventoryType or v.inventory
                v.class = itemClass or v.class
                return
            end
        end

        table.insert(data.hooked[plr].items, {
            item = itemInstance,
            inventory = inventoryType,
            class = itemClass
        })
    end

    if plr == lplr then
        for i, v in pairs(bedfight.modules.InventoryHandler.Inventories) do
            for _, slot in ipairs(v.Items) do
                local slotClass = slot:GetAttribute("Class")

                if i == "Armor" then
                    if slot.Name ~= "" then
                        trackItem(slot, i, slotClass)
                    end
                else
                    local itemInstance = inv:FindFirstChild(slot.Name)
                    trackItem(itemInstance, i, slotClass)
                end

                addConn(slot:GetPropertyChangedSignal("Name"):Connect(function()
                    local newName = slot.Name
                    if i == "Armor" then
                        if newName == "" then
                            untrackItem(slot)
                        else
                            trackItem(slot, i, slot:GetAttribute("Class"))
                        end
                    else
                        local newItem = inv:FindFirstChild(newName)
                        trackItem(newItem, i, slot:GetAttribute("Class"))
                    end
                end))

                addConn(slot:GetAttributeChangedSignal("Class"):Connect(function()
                    if i == "Armor" and slot.Name ~= "" then
                        trackItem(slot, i, slot:GetAttribute("Class"))
                    end
                end))
            end
        end
    else
        for _, item in ipairs(inv:GetChildren()) do
            trackItem(item, "Inventory", item:GetAttribute("Class"))
        end
    end

    addConn(inv.ChildAdded:Connect(function(item)
        local inventoryType = "Inventory"

        if plr == lplr then
            inventoryType = "Unknown"
            for i, v in pairs(bedfight.modules.InventoryHandler.Inventories) do
                if bedfight.modules.InventoryHandler.GetSlotByName(item.Name, i) then
                    inventoryType = i
                    v.SlotsAmount = v.SlotsAmount + 1
                end
            end
        end

        trackItem(item, inventoryType, item:GetAttribute("Class"))
    end))

    addConn(inv.ChildRemoved:Connect(function(item)
        untrackItem(item)

        if plr == lplr then
            for i, v in pairs(bedfight.modules.InventoryHandler.Inventories) do
                local slot = bedfight.modules.InventoryHandler.GetSlotByName(item.Name, i)
                if slot then
                    v.SlotsAmount = math.max(v.SlotsAmount - 1, 0)
                end
            end
        end
    end))

    funcs:onExit(getHookId(plr), function()
        cleanupHookinv(plr)
    end)
end

local hookAnims = function()
    local swingAnimation = Instance.new("Animation")
    swingAnimation.AnimationId = "rbxassetid://123800159244236"

    local swingFPAnimation = Instance.new("Animation")
    swingFPAnimation.AnimationId = "rbxassetid://80138703077151"

    data.swingAnims = data.swingAnims or {
        third = nil,
        first = nil
    }

    local alive = true

    local function load()
        if not alive then return end
        if not lplr.Character then return end
        if not data.swingAnims then
            data.swingAnims = {
                third = nil,
                first = nil
            }
        end

        local humanoid = lplr.Character:FindFirstChild("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

        if animator then
            data.swingAnims.third = animator:LoadAnimation(swingAnimation)
        end

        local cam = workspace.CurrentCamera
        local vm = cam and cam:FindFirstChild("ViewModel")
        local vmAnimator = vm and vm:FindFirstChild("AnimationController") and vm.AnimationController:FindFirstChildOfClass("Animator")

        if vmAnimator then
            data.swingAnims.first = vmAnimator:LoadAnimation(swingFPAnimation)
        end
    end

    task.spawn(function()
        task.wait(0.2)
        if alive then
            load()
        end
    end)

    local charConn = lplr.CharacterAdded:Connect(function()
        if not alive then return end
        data.swingAnims = data.swingAnims or {
            third = nil,
            first = nil
        }
        data.swingAnims.third = nil
        data.swingAnims.first = nil
        task.wait(0.2)
        if alive then
            load()
        end
    end)

    funcs:onExit("anims", function()
        alive = false
        if charConn then
            charConn:Disconnect()
        end
        data.swingAnims = nil
    end)
end

local hookmode = function()
    local gameMode = game:GetService("ReplicatedStorage"):WaitForChild("GameInfo"):WaitForChild("GameMode")
    
    data.gamemode.current = gameMode.Value

    local conn = gameMode:GetPropertyChangedSignal("Value"):Connect(function()
        data.gamemode.current = gameMode.Value
    end)

    data.gamemode.connection = conn

    funcs:onExit("gamemode", function()
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end)
end

local getitem = function(name, plr)
    local entry = findTrackedItem(name, plr)
    if entry then
        return entry.item, entry.inventory
    end
    return nil
end

getRanged = function()
    local hook = data.hooked[lplr]
    if hook then
        for _, v in ipairs(hook.items) do
            local itemName = getItemName(v.item)
            if itemName and rangedData[itemName] then
                return itemName
            end
        end
    end

    for _, name in ipairs(RANGED_NAMES) do
        local item = getitem(name)
        local itemName = getItemName(item)
        if itemName then return itemName end
    end
end

getBestProjectile = function(weaponName)
    local wData = rangedData[weaponName]
    if not wData then return nil, nil end
    local ungrouped = bedfight.modules.InventoryHandler.Ungrouped
    local names = wData.ProjectileOrder or (wData.Projectile and {wData.Projectile}) or {}
    for _, pName in ipairs(names) do
        local pd = projData[pName]
        if pd then
            local modelName = pd.Projectile or pName
            if ungrouped and ungrouped[modelName] then
                return pName, pd
            end
        end
    end
    return nil, nil
end

local function getTeams()
    local teams = {}
    for _, team in ipairs(Teams:GetChildren()) do
        if team:IsA("Team") then
            table.insert(teams, team.Name)
        end
    end
    return teams
end

local function getClientEquipped()
    local char = lplr.Character
    if not char then return nil end
    local hook = data.hooked[lplr]
    if not hook then return nil end
    for _, child in ipairs(char:GetChildren()) do
        local childName = getItemName(child)
        if childName and childName ~= "" then
            for _, v in ipairs(hook.items) do
                local itemName = getItemName(v.item)
                if itemName and v.inventory ~= "Armor" and itemName ~= "" and namesMatch(childName, itemName) then
                    return itemName, v.inventory
                end
            end
        end
    end
    return nil
end

local getsword
local switchitem
local revertitem
local matchState

do
    hookinv(lplr)
    hookAnims()
    hookmode()

    local switchedTo
    local previousEquipped

    getsword = function()
        local hook = data.hooked[lplr]
        if hook then
            for _, v in ipairs(hook.items) do
                local itemName = getItemName(v.item)
                if itemName and bedfight.modules.SwordsData[itemName] then
                    return itemName
                end
            end
        end

        local item = getitem("Sword")
        return getItemName(item)
    end

    switchitem = function(name, plr)
        plr = plr or lplr
        local hook = data.hooked[plr]
        if not hook then
            return
        end

        local target = findTrackedItem(name, plr)
        local targetName = target and getItemName(target.item)

        if not target or not targetName then
            return
        end

        if switchedTo == targetName then
            return
        end

        if not previousEquipped then
            local n, t = getClientEquipped()
            if n then
                previousEquipped = {name = n, inventory = t}
            end
        end

        switchedTo = targetName
        sendRemote(bedfight.remotes.EquipTool, targetName)
    end

    revertitem = function(plr)
        if not switchedTo then return end
        if previousEquipped then
            sendRemote(bedfight.remotes.EquipTool, previousEquipped.name)
            previousEquipped = nil
        end
        switchedTo = nil
    end

    matchState = function()
        local Signals = bedfight.modules.Signals
        local statusObj = ReplicatedStorage.GameInfo.Status

        local getTimerSeconds = function()
            local ok, result = pcall(function()
                return lplr.PlayerGui.TopbarButtonsGui.ButtonsList.GameTimer.TextLabel.Text
            end)
            if not ok or not result then return math.huge end
            local m, s = result:match("(%d+):(%d+)")
            return (m and s) and (tonumber(m) * 60 + tonumber(s)) or math.huge
        end

        local isInActiveGame = function()
            if not lplr:GetAttribute("CanJoinGame") then return false end
            local pg = lplr.PlayerGui
            local ok1, f1 = pcall(function() return pg.StartGui.Enabled end)
            if ok1 and f1 then return true end
            local ok2, f2 = pcall(function() return pg.PlayAgainGui.MainFrame.Visible end)
            return ok2 and f2 ~= nil
        end

        local evaluate = function()
            local isRanked = data.gamemode.current == "Ranked 1v1" or data.gamemode.current == "Ranked 4v4"
            if isRanked then
                if statusObj.Value == "Starting" then data.matchState = 1
                elseif statusObj.Value == "Started" then data.matchState = 2 end
                return
            end

            local statusText = ""
            pcall(function() statusText = lplr.PlayerGui.GameStatusGui.StatusLabel.Text:lower() end)
            local secs = getTimerSeconds()

            if statusText:find("more team") then
                data.matchState = 0
            elseif lplr:GetAttribute("PVP") == true and not (lplr.Team and lplr.Team.Name == "Spectators") then
                data.matchState = 2
            elseif not (lplr.Team and lplr.Team.Name == "Spectators") and (statusText:find("status:") or statusText:find("started:")) then
                data.matchState = 2
            elseif statusText:find("voting:") or statusText:find("intermission:") then
                data.matchState = 1
            elseif isInActiveGame() and secs < 180 and statusText:find("status:") then
                local activeOk, activeFrame = pcall(function() return lplr.PlayerGui.StartGui.MainFrame.OptionsFrame end)
                if activeOk and activeFrame then data.matchState = 1 end
            elseif statusObj.Value == "Waiting" then
                data.matchState = 1
            else
                data.matchState = 0
            end
        end

        local gameConn = Signals.Game:Connect(function() data.matchState = 2 end)
        local resultConn = Signals.GameResult:Connect(function() data.matchState = 0 end)
        local setMapConn = Signals.SetMap:Connect(function() data.matchState = 1 end)
        local endGameConn = Signals.EndGame:Connect(function() data.matchState = 0 end)
        RunLoops:BindToHeartbeat("matchState", evaluate, 0.7)

        funcs:onExit("matchStateLoop", function()
            RunLoops:UnbindFromHeartbeat("matchState")
            gameConn:Disconnect()
            resultConn:Disconnect()
            setMapConn:Disconnect()
            endGameConn:Disconnect()
        end)
    end
    matchState()
end

local touching = false
do
    touchConnStart = UserInputService.TouchStarted:Connect(function()
        touching = true
    end)

    touchConnEnd = UserInputService.TouchEnded:Connect(function()
        touching = false
    end)
    
    funcs:onExit("bodyVelHook", function()
        if touchConnStart then
            touchConnStart:Disconnect()
            touchConnStart = nil
        end
        if touchConnEnd then
            touchConnEnd:Disconnect()
            touchConnEnd = nil
        end
        touching = false
    end)
end

local Distance = {Value = 21}
runcode(function()
    local Killaura = {}
    local FacePlayer = {}
    local TeamCheck = {}

    local swordtype = nil
    local currentTarget = nil
    local currentController = nil
    local shieldActive = false
    local shieldConn = nil

    local SwordController = bedfight.modules.SwordController
    local origGetHitWithBox = nil
    local origSwordNew = nil
    local capturedControllers = {}

    local function getPing()
        local ok, value = pcall(function()
            return lplr:GetNetworkPing()
        end)
        return ok and value or 0
    end

    local function stopController()
        if currentController then
            currentController:Stop(true)
            currentController = nil
        end
    end

    -- changing this WILL BREAK aura okay? 
    local hookcont = function(swordName)
        local char = lplr.Character
        if not char then return nil end
        local toolInstance = findToolInstance(swordName)
        if not toolInstance then return nil end

        if currentController and currentController.Name == swordName and currentController.Tool == toolInstance then
            return currentController
        end

        stopController()

        local captured = capturedControllers[toolInstance]
        if not captured then
            local toolName = getItemName(toolInstance) or swordName
            local byName = capturedControllers[toolName]
            if byName and namesMatch(getItemName(byName.Tool), toolName) then
                captured = byName
            end
        end
        if captured then
            currentController = captured
        else
            currentController = SwordController.new(toolInstance, char)
            currentController:Run()
        end

        if not origGetHitWithBox then
            origGetHitWithBox = SwordController.GetHitWithBox
        end

        return currentController
    end

    Killaura = GuiLibrary.Registry.combatPanel.API.CreateOptionsButton({
        Name = "Killaura",
        Beta = true,
        Function = function(callback)
            if callback then
                shieldConn = bedfight.modules.Signals.Shield:Connect(function()
                    shieldActive = true
                    task.delay(0.35, function() shieldActive = false end)
                end)

                origSwordNew = SwordController.new
                SwordController.new = function(tool, char, ...)
                    local ctrl = origSwordNew(tool, char, ...)
                    if tool then
                        capturedControllers[tool] = ctrl
                        local toolName = getItemName(tool)
                        if toolName then
                            capturedControllers[toolName] = ctrl
                        end
                    end
                    return ctrl
                end

                RunLoops:BindToHeartbeat("Killaura", function()
                    if shieldActive then return end

                    local isSpectator = not lplr.Team or lplr.Team.Name == "Spectators"
                    local nearest = PlayerUtility.GetNearestEntities(Distance.Value, TeamCheck.Enabled and not isSpectator, false)
                    if not nearest or #nearest == 0 then
                        data.Attacking, data.attackingEntity, currentTarget = false, nil, nil
                        if currentController then currentController:Stop(true); currentController = nil end
                        revertitem()
                        return
                    end

                    local targetEntry = nearest[1]
                    local target = getEntityCharacter(targetEntry)
                    if not target then revertitem() return end
                    if target:GetAttribute("Forcefield") then return end

                    local humanoid = target:FindFirstChildOfClass("Humanoid")
                    local root = target:FindFirstChild("HumanoidRootPart")
                    if not humanoid or not root or humanoid.Health <= 0 then revertitem() return end

                    swordtype = getsword()
                    if not swordtype then revertitem() return end
                    if ItemOnly.Enabled and getClientEquipped() ~= swordtype then return end
                    local swordData = bedfight.modules.SwordsData[swordtype]
                    if not swordData then return end
                    local ping = getPing()

                    local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                    local myHum = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid")
                    if not myRoot or not myHum then revertitem() return end

                    if FacePlayer.Enabled and not LongFly.Enabled then
                        local aimPos = root.Position + Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z) * ping
                        myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(aimPos.X, myRoot.Position.Y, aimPos.Z))
                    end

                    if data.projLastFire and (tick() - data.projLastFire) < 0.05 then return end

                    data.Attacking = true
                    data.attackingEntity = target


                    if SwingOnly.Enabled and not (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or touching) then
                        return
                    end

                    currentTarget = targetEntry

                    switchitem(swordtype)
                    task.wait(0.03)
                    local ctrl = hookcont(swordtype)
                    if not ctrl then return end
                    ctrl.CanAttack = true
                    SwordController.GetHitWithBox = function()
                        return buildSwordHitData(currentTarget)
                    end
                    ctrl:Activate()
                    SwordController.GetHitWithBox = origGetHitWithBox
                    --if projFireAt then task.spawn(projFireAt, root, target) end
                end)
            else
                if shieldConn then shieldConn:Disconnect(); shieldConn = nil end
                funcs:offExit("KA_CharConn")
                shieldActive = false
                currentTarget = nil
                data.Attacking = false
                data.attackingEntity = nil
                stopController()
                if origGetHitWithBox then
                    SwordController.GetHitWithBox = origGetHitWithBox
                    origGetHitWithBox = nil
                end
                if origSwordNew then
                    SwordController.new = origSwordNew
                    origSwordNew = nil
                end
                capturedControllers = {}
                currentTarget = nil
                revertitem()
                RunLoops:UnbindFromHeartbeat("Killaura")
            end
        end
    })
    Distance = Killaura.CreateSlider({
        Name = "Distance",
        Min = 0,
        Max = 21,
        Default = 17,
        Round = 1,
        Function = function() end
    })
    TeamCheck = Killaura.CreateToggle({
        Name = "Team Check",
        Default = true,
        Function = function() end
    })
    FacePlayer = Killaura.CreateToggle({
        Name = "FacePlayer",
        Function = function() end
    })
    SwingOnly = Killaura.CreateToggle({
        Name = "Swing Only",
        Tooltip = "Only attacks while clicking",
        Function = function() end
    })
    ItemOnly = Killaura.CreateToggle({
        Name = "Item Only",
        Tooltip = "Only attacks when sword is held",
        Function = function() end
    })
end)

runcode(function()
    local AimAssist = {}
    local AimFOV = {}
    local AimSmoothing = {}
    local aimTeamCheck = {}

    AimAssist = GuiLibrary.Registry.combatPanel.API.CreateOptionsButton({
        Name = "Aim Assist",
        Function = function(callback)
            if callback then
                RunLoops:BindToHeartbeat("AimAssist", function()
                    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
                    local isSpectator = not lplr.Team or lplr.Team.Name == "Spectators"
                    local nearest = PlayerUtility.GetNearestEntities(AimFOV.Value, aimTeamCheck.Enabled and not isSpectator, false)
                    if not nearest or #nearest == 0 then return end
                    local target = getEntityCharacter(nearest[1])
                    if not target then return end
                    local head = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
                    if not head then return end
                    local cam = workspace.CurrentCamera
                    local camPos = cam.CFrame.Position
                    local lookDir = (head.Position - camPos).Unit
                    cam.CFrame = cam.CFrame:Lerp(CFrame.new(camPos, camPos + lookDir), AimSmoothing.Value)
                end)
            else
                RunLoops:UnbindFromHeartbeat("AimAssist")
            end
        end
    })
    AimFOV = AimAssist.CreateSlider({
        Name = "Range",
        Min = 5,
        Max = 100,
        Default = 30,
        Round = 1,
    })
    AimSmoothing = AimAssist.CreateSlider({
        Name = "Smoothness",
        Min = 0.05,
        Max = 1,
        Default = 0.15,
    })
    aimTeamCheck = AimAssist.CreateToggle({
        Name = "Team Check",
        Default = true,
        Function = function() end,
    })
end)

local SpeedSlider = {}
runcode(function()
    local AutoJump = {}
    local Direction = {}
    local Mode = {}
    local HSHighSpeed = {Value = 32}
    local HSLowSpeed = {Value = 16}
    local HSHighDur = {Value = 0.5}
    local HSLowDur = {Value = 0.5}
    local hsPhase = "boost"
    local hsTimer = 0

    Speed = GuiLibrary.Registry.blatantPanel.API.CreateOptionsButton({
        Name = "Speed",
        ExtraText = "CFrame",
        Function = function(callback)
            if callback then
                hsPhase = "boost"
                hsTimer = 0

                RunLoops:BindToHeartbeat("Speed", function(dt)
                    local char = lplr.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if PlayerUtility.lplrIsAlive and hum and root and hum.MoveDirection.Magnitude > 0 then
                        local moveDirection = hum.MoveDirection

                        local newCFrame
                        if Direction.Enabled and moveDirection ~= Vector3.zero and not data.Attacking then
                            newCFrame = CFrame.new(root.Position, root.Position + Vector3.new(moveDirection.X, 0, moveDirection.Z))
                        else
                            newCFrame = root.CFrame
                        end

                        if Mode.Value == "Velocity" then
                            root.AssemblyLinearVelocity =(moveDirection * SpeedSlider.Value) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)

                        elseif Mode.Value == "HeatSeeker" then
                            hsTimer = hsTimer + dt
                            local phaseDur = hsPhase == "boost" and HSHighDur.Value or HSLowDur.Value
                            if hsTimer >= phaseDur then
                                hsTimer = 0
                                hsPhase = hsPhase == "boost" and "normal" or "boost"
                            end
                            local spd = hsPhase == "boost" and HSHighSpeed.Value or HSLowSpeed.Value
                            root.AssemblyLinearVelocity = (moveDirection * spd) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                        end

                        if not Fly.Enabled and AutoJump.Enabled and data.Attacking and hum.FloorMaterial ~= Enum.Material.Air then
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end
                end)

            else
                lplr.Character.Humanoid.AutoRotate = true

                if bodyVel then
                    bodyVel:Destroy()
                    bodyVel = nil
                end

                RunLoops:UnbindFromHeartbeat("Speed")
            end
        end
    })
    SpeedSlider = Speed.CreateSlider({
        Name = "Value",
        Min = 0,
        Max = 32,
        Default = 32,
        Round = 1,
    })
    Mode = Speed.CreateDropdown({
        Name = "Mode",
        List = {"Velocity", "HeatSeeker"},
        Default = "Velocity",
    })
    local HSBoostSpeedSlider = Speed.CreateSlider({
        Name = "BoostSpeed",
        Min = 0,
        Max = 200,
        Default = 60,
        Round = 1,
        Function = function(callback) HSHighSpeed.Value = callback end,
    })
    local HSBaseSpeedSlider = Speed.CreateSlider({
        Name = "BaseSpeed",
        Min = 0,
        Max = 100,
        Default = 32,
        Round = 1,
        Function = function(callback) HSLowSpeed.Value = callback end,
    })
    local HSBoostDurSlider = Speed.CreateSlider({
        Name = "BoostDur",
        Min = 0.1,
        Max = 5,
        Default = 0.1,
        Round = 1,
        Function = function(callback) HSHighDur.Value = callback end,
    })
    local HSBaseDurSlider = Speed.CreateSlider({
        Name = "BaseDur",
        Min = 0.1,
        Max = 5,
        Default = 1.2,
        Round = 1,
        Function = function(callback) HSLowDur.Value = callback end,
    })
    Mode:ShowWhen("HeatSeeker", HSBoostSpeedSlider)
    Mode:ShowWhen("HeatSeeker", HSBaseSpeedSlider)
    Mode:ShowWhen("HeatSeeker", HSBoostDurSlider)
    Mode:ShowWhen("HeatSeeker", HSBaseDurSlider)
    AutoJump = Speed.CreateToggle({
        Name = "AutoJump",
        Default = true,
    })
    Direction = Speed.CreateToggle({
        Name = "Direction",
        Default = true,
        Function = function(callback)
            repeat task.wait() until Speed.Enabled
            lplr.Character.Humanoid.AutoRotate = Speed.Enabled and not callback or true
        end,
    })
end)

local height = lplr.Character.HumanoidRootPart.Size.Y * 1.5
runcode(function()
	local ScreenGui = DrawLibrary.CreateBar(game.CoreGui)

	local FlyValue = {}
	local FlyVerticalValue = {}
	local ProgressBar = {}
	local extendedFly = {}
	local ExtendMode = {}
	local AscendTimer = {}
	local bypass = {}

	local TweenFrame = ScreenGui.Bar
	local SecondLeft = ScreenGui.SecondLeft

	local extPhase = "none"
	local extTimer = 0
	local lastExtendTime = 0
	local EXT_ASCEND_TIME = 0.9
	local MIN_SAFE_ASCEND = 10

	Fly = GuiLibrary.Registry.blatantPanel.API.CreateOptionsButton({
		Name = "Fly",
		Function = function(callback)

			local lastTick = os.clock()
			local airTimer = 0
			local i = 0
			local verticalVelocity = 0

			local descendState = false
			local ascendState = false
			local targetY = 0
			local originalY = 0

			local char = lplr.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")

			local groundParams = RaycastParams.new()
			groundParams.FilterType = Enum.RaycastFilterType.Blacklist
			groundParams.FilterDescendantsInstances = { char }
			groundParams.IgnoreWater = true

			local isOverVoid = false
			local voidCheckTimer = 0
			local voidGrace = 0
			local VOID_GRACE_TIME = 0.4
			local MAX_AIR_TIME = 0.9

			local ascendStartY = 0

			extPhase = "none"
			extTimer = 0

			if callback then
				TweenFrame.Size = UDim2.new(0, 0, 1, 0)
				TweenFrame.Position = UDim2.new(0, 0, 0, 0)
				ScreenGui.ScreenGui.Enabled = true

				if extendedFly.Enabled and not bypass.Enabled and ExtendMode.Value == "AscendDescend" then
					extPhase = "ascending"
					extTimer = 0
					ascendStartY = root and root.Position.Y or 0
				end

				RunLoops:BindToHeartbeat("Fly", function(dt)

					local currentTick = os.clock()
					local deltaTime = math.min(currentTick - lastTick, 0.1)
					lastTick = currentTick

					if not root or not root.Parent then
						char = lplr.Character
						root = char and char:FindFirstChild("HumanoidRootPart")
						humanoid = char and char:FindFirstChildOfClass("Humanoid")
						if char then groundParams.FilterDescendantsInstances = { char } end
						return
					end

                    voidCheckTimer = voidCheckTimer + deltaTime
					if voidCheckTimer >= 0.1 then
						voidCheckTimer = 0
						local voidRay = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), groundParams)
						if voidRay then
							isOverVoid = false
							voidGrace = VOID_GRACE_TIME
						else
                            voidGrace = voidGrace - deltaTime
							if voidGrace <= 0 then isOverVoid = true end
						end
					end

					local moveDirection = (humanoid and humanoid.MoveDirection) or Vector3.zero
					local dir = moveDirection.Magnitude > 0.1 and moveDirection.Unit or root.CFrame.LookVector
                    i = i + deltaTime

                    root.CFrame = root.CFrame + moveDirection * (FlyValue.Value + SpeedMultiplier()) / (1 / dt)

					createBodyVel()
					bodyVel.MaxForce = Vector3.one * bodyVel.P

					local ray = workspace:Raycast(root.Position, Vector3.new(0, -math.clamp(1000 + math.abs(root.AssemblyLinearVelocity.Y) * 8, 1000, 2500), 0), groundParams)
					local onGround = ray and ray.Distance <= height + 0.3

					if onGround then
						if extPhase == "descending" then
							extPhase = "none"
							extTimer = 0
							bodyVel.MaxForce = Vector3.zero
							if Fly.Enabled then Fly.Toggle() end
							return
						end
						airTimer = 0
						isOverVoid = false
					end

					if bypass.Enabled then airTimer = math.huge end

					if ProgressBar.Enabled then
						ScreenGui.ScreenGui.Enabled = true
						TweenFrame.Visible = true
					else
						ScreenGui.ScreenGui.Enabled = false
						TweenFrame.Visible = false
					end

					if extendedFly.Enabled and not bypass.Enabled and ExtendMode.Value == "AscendDescend" then

						if extPhase == "ascending" then
							local gainedHeight = root.Position.Y - ascendStartY
							if isOverVoid and gainedHeight < MIN_SAFE_ASCEND then
								extPhase = "descending"
								extTimer = 0
								airTimer = 0
							elseif extTimer >= (AscendTimer.Value or 0.9) then
								extPhase = "descending"
								extTimer = 0
								airTimer = 0
							else
                                extTimer = extTimer + deltaTime
								bodyVel.Velocity = Vector3.new(0, FlyVerticalValue.Value, 0)
							end

						elseif extPhase == "descending" then
                            if not bypass.Enabled then airTimer = airTimer + deltaTime end
							bodyVel.Velocity = Vector3.new(0, -5, 0)

						else
                            if not bypass.Enabled then airTimer = airTimer + deltaTime end
							if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
								verticalVelocity = FlyVerticalValue.Value
							elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
								verticalVelocity = -FlyVerticalValue.Value
							else
								verticalVelocity = math.sin(i * math.pi) * 0.01
							end
							bodyVel.Velocity = Vector3.new(0, verticalVelocity, 0)
						end
					elseif extendedFly.Enabled and not bypass.Enabled and ExtendMode.Value == "TweenDown" then
						if extPhase ~= "none" then extPhase = "none"; extTimer = 0 end
                        if not bypass.Enabled then airTimer = airTimer + deltaTime end

						local remainingTime = math.max(MAX_AIR_TIME - airTimer, 0)
						remainingTime = math.round(remainingTime * 10) / 10

						if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
							verticalVelocity = FlyVerticalValue.Value
						elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
							verticalVelocity = -FlyVerticalValue.Value
						else
							verticalVelocity = math.sin(i * math.pi) * 0.01
						end

						if descendState then
							local check = workspace:Raycast(root.Position, Vector3.new(0, -100, 0), groundParams)
							if not check then
								descendState = false
							else
								bodyVel.Velocity = Vector3.new(0, -math.clamp((root.Position.Y - targetY) * 3, 75, 200), 0)
								if humanoid.FloorMaterial ~= Enum.Material.Air then
									airTimer = 0
									descendState = false
									ascendState = true
								end
							end
						elseif ascendState then
							bodyVel.Velocity = Vector3.new(0, math.clamp((originalY - root.Position.Y) * 2, 15, 60), 0)
							if originalY - root.Position.Y <= 0.3 then
								ascendState = false
								airTimer = 0
							end
						else
							bodyVel.Velocity = Vector3.new(0, verticalVelocity, 0)
						end

						if not descendState and not ascendState and not isOverVoid then
							local vel = root.AssemblyLinearVelocity
							local horizontalSpeed = math.max(Vector3.new(vel.X, 0, vel.Z).Magnitude, FlyValue.Value + SpeedMultiplier())
							local scanStep = math.clamp(horizontalSpeed * 0.25, 4, 10)
							local maxScan = math.clamp(horizontalSpeed * 10, 60, 150)
							local closestBlock, closestDist = nil, math.huge

							for dist = 2, maxScan, scanStep do
								local origin = root.Position + dir * dist + Vector3.new(0, 6, 0)
								local forwardRay = workspace:Raycast(origin, Vector3.new(0, -60, 0), groundParams)
								if forwardRay then
									local hDist = (Vector3.new(forwardRay.Position.X, 0, forwardRay.Position.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
									if math.abs(forwardRay.Position.Y - root.Position.Y) < 50 and hDist < closestDist then
										closestDist = hDist
										closestBlock = forwardRay.Position
									end
								end
							end

							if closestBlock then
								local horizontalDist = (Vector3.new(closestBlock.X, 0, closestBlock.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
								if horizontalDist <= 35 then
									local safetyRay = workspace:Raycast(Vector3.new(closestBlock.X, closestBlock.Y + 5, closestBlock.Z), Vector3.new(0, -100, 0), groundParams)
									if safetyRay then
										local landingY = closestBlock.Y + height
										local dropHeight = root.Position.Y - landingY
										local descentSpeed = math.clamp(dropHeight * 3, 75, 200)
										local timeToDescend = dropHeight / descentSpeed
										local timeToReach = closestDist / math.max(horizontalSpeed, FlyValue.Value)
										if remainingTime <= timeToReach + timeToDescend and airTimer > 0.25 then
											if landingY < root.Position.Y then
												local landingCheck = workspace:Raycast(Vector3.new(closestBlock.X, closestBlock.Y + 5, closestBlock.Z), Vector3.new(0, -500, 0), groundParams)
												if landingCheck and (os.clock() - lastExtendTime) > 0.7 then
													lastExtendTime = os.clock()
													airTimer = 0
													originalY = root.Position.Y
													targetY = landingY
													descendState = true
													createNotification("Fly", "Extended time by " .. remainingTime .. "s", 4)
												end
											end
										end
									end
								end
							end
						end
					else
						if extPhase ~= "none" then extPhase = "none"; extTimer = 0 end
                        if not bypass.Enabled then airTimer = airTimer + deltaTime end

						if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
							verticalVelocity = FlyVerticalValue.Value
						elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
							verticalVelocity = -FlyVerticalValue.Value
						else
							verticalVelocity = math.sin(i * math.pi) * 0.01
						end
						bodyVel.Velocity = Vector3.new(0, verticalVelocity, 0)
					end

					local remainingTime = bypass.Enabled and math.huge or math.max(MAX_AIR_TIME - airTimer, 0)
					remainingTime = math.round(remainingTime * 10) / 10
					SecondLeft.Text = remainingTime .. "s"

					if ScreenGui.ScreenGui.Enabled then
						local barFill = extPhase == "ascending" and 1 or (bypass.Enabled and 1 or math.max(1 - (airTimer / MAX_AIR_TIME), 0))
						TweenFrame:TweenSize(UDim2.new(barFill, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.1, true)
					end

					if airTimer >= MAX_AIR_TIME and extPhase == "none" and not bypass.Enabled then
						bodyVel.MaxForce = Vector3.zero
						if Fly.Enabled then Fly.Toggle() end
					end
				end)
			else
				if bodyVel then bodyVel.MaxForce = Vector3.zero end
				extPhase = "none"
				extTimer = 0
				descendState = false
				ascendState = false
				MAX_AIR_TIME = 0.9
				TweenFrame:TweenSize(UDim2.new(0, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.1, true)
				ScreenGui.ScreenGui.Enabled = false
				RunLoops:UnbindFromHeartbeat("Fly")
			end
		end
	})
	FlyValue = Fly.CreateSlider({
		Name = "value",
		Min = 0,
		Max = 32,
		Default = 32,
		Round = 1
	})
	FlyVerticalValue = Fly.CreateSlider({
		Name = "vertical value",
		Min = 0,
		Max = 100,
		Default = 49,
		Round = 1
	})
	ProgressBar = Fly.CreateToggle({
		Name = "ProgressBar",
		Default = true
	})
	extendedFly = Fly.CreateToggle({
		Name = "ExtendedFly",
		Default = true
	})
	ExtendMode = Fly.CreateDropdown({
		Name = "Extend Mode",
		List = {"AscendDescend", "TweenDown"},
		Default = "AscendDescend",
	})
	extendedFly:AddDependent(ExtendMode)
	AscendTimer = Fly.CreateSlider({
		Name = "ascend time",
		Min = 0.1,
		Max = 0.9,
		Default = 0.4,
		Round = 1,
	})
	ExtendMode:ShowWhen("AscendDescend", AscendTimer)
	extendedFly:AddDependent(AscendTimer)
	bypass = Fly.CreateToggle({
		Name = "bypassTimer",
		Default = false
	})
end)

runcode(function()
    local LongFlyValue, LongFlyDuration, LongFlySlopeAngle = {}, {}, {}
    local smartFly = {}
    local overheadCheck = false
    local phase, noBlockTimer = "0", 0
    local lastActivated, cooldown = 0, 0
    local speedWasEnabled = false
    local GRACE_PERIOD = 0.03

    local flyAttachment = nil
    local flyForce = nil

    local function createFlyForce(root)
        if flyForce then flyForce:Destroy(); flyForce = nil end
        if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end

        flyAttachment = Instance.new("Attachment")
        flyAttachment.Position = Vector3.zero
        flyAttachment.Parent = root

        flyForce = Instance.new("VectorForce")
        flyForce.Attachment0 = flyAttachment
        flyForce.Force = Vector3.zero
        flyForce.RelativeTo = Enum.ActuatorRelativeTo.World
        flyForce.ApplyAtCenterOfMass = true
        flyForce.Parent = root
    end

    local function destroyFlyForce()
        if flyForce then flyForce:Destroy(); flyForce = nil end
        if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end
    end

    local function applyFlyForce(root, targetVelocity, dt)
        if not flyForce or not root then return end

        local mass = root.AssemblyMass
        local currentVel = root.AssemblyLinearVelocity
        local error = targetVelocity - currentVel

        local correctionForce = (error * mass) / math.max(dt, 0.001)

        local gravityCompensation = Vector3.new(0, workspace.Gravity * mass, 0)

        flyForce.Force = correctionForce + gravityCompensation
    end

    local function stopLongFly(root, reason)
        destroyFlyForce()
        if root then root.AssemblyLinearVelocity = Vector3.zero end
        phase, noBlockTimer = "0", 0
        RunLoops:UnbindFromHeartbeat("LongFly")
        if LongFly.Enabled then LongFly.Toggle() end
        createNotification("LongFly", reason, 2)
        if speedWasEnabled and not Speed.Enabled then
            Speed.Toggle()
        end
        speedWasEnabled = false
    end

    LongFly = GuiLibrary.Registry.blatantPanel.API.CreateOptionsButton({
        Name = "LongFly",
        New = true,
        Function = function(callback)
            if callback then
                if os.clock() - lastActivated < cooldown then
                    createNotification("LongFly", "On cooldown", 2)
                    if LongFly.Enabled then LongFly.Toggle() end
                    return
                end
                lastActivated = os.clock()

                if Fly and Fly.Enabled then
                    createNotification("LongFly", "Disable Fly first", 3)
                    if LongFly.Enabled then LongFly.Toggle() end
                    return
                end

                local char = lplr.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                if not root or not humanoid then
                    if LongFly.Enabled then LongFly.Toggle() end
                    return
                end

                speedWasEnabled = Speed and Speed.Enabled or false
                if speedWasEnabled then Speed.Toggle() end

                root.Anchored = true
                root.AssemblyLinearVelocity = Vector3.zero
                task.wait(0.7)
                root.Anchored = false

                local camLook = workspace.CurrentCamera.CFrame.LookVector
                local lockedDir = Vector3.new(camLook.X, 0, camLook.Z)
                local horizontalMag = lockedDir.Magnitude
                local lockedDirUnit = horizontalMag > 0.01 and lockedDir.Unit or Vector3.zero
                local slopeRad = horizontalMag > 0.01 and math.rad(LongFlySlopeAngle.Value) or 0

                local flyDir = Vector3.new(lockedDirUnit.X * math.cos(slopeRad),math.sin(slopeRad) * (horizontalMag > 0.01 and 1 or 0),lockedDirUnit.Z * math.cos(slopeRad))

                local startTime = os.clock()
                local lastTick = os.clock()
                local startPos = root.Position
                local timeUnderBlock, totalTime = 0, 0
                local wasUnderBlock, smartStopArmed = false, false

                phase = overheadCheck.Enabled and "1" or "0"
                noBlockTimer = 0

                createFlyForce(root)
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

                local longFlyRayParams = RaycastParams.new()
                longFlyRayParams.FilterType = Enum.RaycastFilterType.Exclude

                RunLoops:BindToHeartbeat("LongFly", function()
                    local now = os.clock()
                    local dt = math.min(now - lastTick, 0.016)
                    lastTick = now

                    root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                    humanoid = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid")
                    if not root then return end

                    if flyAttachment and flyAttachment.Parent ~= root then
                        createFlyForce(root)
                    end

                    totalTime = totalTime + dt

                    longFlyRayParams.FilterDescendantsInstances = { lplr.Character }

                    local currentlyUnderBlock = workspace:Raycast(root.Position, Vector3.new(0, -100, 0), longFlyRayParams) ~= nil

                    if currentlyUnderBlock then
                        timeUnderBlock = timeUnderBlock + dt
                        wasUnderBlock = true
                    end

                    if smartFly.Enabled and wasUnderBlock and currentlyUnderBlock then
                        local blockCoverage = timeUnderBlock / math.max(totalTime, 0.001)
                        local flightProgress = (now - startTime) / LongFlyDuration.Value

                        if blockCoverage >= 0.10 and flightProgress >= 0.4 and not smartStopArmed then
                            smartStopArmed = true
                        end

                        if smartStopArmed then
                            local flatDir = Vector3.new(flyDir.X, 0, flyDir.Z).Unit
                            local missingCount = 0

                            for i = 1, 5 do
                                local checkPos = root.Position + flatDir * (20 + i * 12)
                                local probeOrigin = Vector3.new(checkPos.X, root.Position.Y + 5, checkPos.Z)
                                if not workspace:Raycast(probeOrigin, Vector3.new(0, -150, 0), longFlyRayParams) then
                                    missingCount = missingCount + 1
                                end
                            end

                            if missingCount >= 4 then
                                local dist = (Vector3.new(root.Position.X, 0, root.Position.Z)- Vector3.new(startPos.X, 0, startPos.Z)).Magnitude
                                cooldown = math.clamp((dist / 50) ^ 2.6, 1, 4)
                                stopLongFly(root, "SmartFly: void ahead")
                                return
                            end
                        end
                    end

                    if now - startTime >= LongFlyDuration.Value then
                        local dist = (Vector3.new(root.Position.X, 0, root.Position.Z)- Vector3.new(startPos.X, 0, startPos.Z)).Magnitude
                        cooldown = math.clamp((dist / 50) ^ 2.5, 1, 3)
                        stopLongFly(root, "Ended")
                        return
                    end

                    if overheadCheck.Enabled then
                        if phase == "1" then
                            if currentlyUnderBlock then
                                phase, noBlockTimer = "3", 0
                            end

                        elseif phase == "3" then
                            if currentlyUnderBlock then
                                noBlockTimer = 0
                            else
                                noBlockTimer = noBlockTimer + dt
                                if noBlockTimer >= GRACE_PERIOD then
                                    phase, noBlockTimer = "2", 0
                                end
                            end

                        elseif phase == "2" then
                            if currentlyUnderBlock then
                                local dist = (Vector3.new(root.Position.X, 0, root.Position.Z)- Vector3.new(startPos.X, 0, startPos.Z)).Magnitude
                                cooldown = math.clamp((dist / 50) ^ 2.5, 1, 3)
                                stopLongFly(root, "Entered block coverage")
                                return
                            end
                        end
                    end

                    if humanoid then
                        local s = humanoid:GetState()
                        if s == Enum.HumanoidStateType.Running
                            or s == Enum.HumanoidStateType.RunningNoPhysics
                            or s == Enum.HumanoidStateType.Landed
                        then
                            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end

                    local speed = LongFlyValue.Value + SpeedMultiplier()
                    local targetVelocity = flyDir * speed

                    root.CFrame = root.CFrame + flyDir * speed * dt

                    applyFlyForce(root, targetVelocity, dt)
                end)

            else
                local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                stopLongFly(root, "Disabled")
            end
        end
    })
    LongFlyValue = LongFly.CreateSlider({
        Name = "speed",
        Min = 0,
        Max = 300,
        Default = 300,
        Round = 1
    })
    LongFlyDuration = LongFly.CreateSlider({
        Name = "duration",
        Min = 0.1,
        Max = 2,
        Default = 0.23,
        Round = 1
    })
    LongFlySlopeAngle = LongFly.CreateSlider({
        Name = "slope angle",
        Min = 0,
        Max = 10,
        Default = 5,
        Round = 1
    })
    overheadCheck = LongFly.CreateToggle({
        Name = "Stop Under Block",
        Default = false,
        Function = function()
            phase, noBlockTimer = "0", 0
        end
    })
    smartFly = LongFly.CreateToggle({
        Name = "SmartFly",
        Default = false,
        Function = function() end
    })
end)

runcode(function()
    local old
    local playerHook
    local hookedConnection

    local blacklistedStates = {
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Physics,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.PlatformStanding
    }

    local disableStates = function(hum)
        for _, v in next, blacklistedStates do
            hum:SetStateEnabled(v, false)
        end
    end

    local Strength = {}
    local Velocity = {}
    Velocity = GuiLibrary.Registry.combatPanel.API.CreateOptionsButton({
        Name = "Velocity",
        Function = function(callback)
            if callback then
                local connection = getconnections(ReplicatedStorage.Remotes.Knockback.OnClientEvent)[1]
                if not connection or not connection.Function then return end

                old = old or connection.Function

                hookfunction(connection.Function, function(...)
                    return nil
                end)

                hookedConnection = connection

                if lplr.Character and lplr.Character:FindFirstChild("Humanoid") then
                    disableStates(lplr.Character.Humanoid)
                end

                playerHook = lplr.CharacterAdded:Connect(function(chr)
                    disableStates(chr:WaitForChild("Humanoid"))
                end)

            else
                if hookedConnection and old then
                    hookfunction(hookedConnection.Function, old)
                end

                old = nil
                hookedConnection = nil

                if playerHook then
                    playerHook:Disconnect()
                    playerHook = nil
                end
            end
        end
    })

    Strength = Velocity.CreateSlider({
        Name = "Strength",
        Min = 0,
        Max = 100,
        Default = 0
    })
end)

runcode(function()
    local range = {Value = 120}
    local teamCheck = {Enabled = false}
    local targetPart = {Value = "HumanoidRootPart"}
    local mode = {Value = "Distance"}
    local fov = {Value = 120}
    -- local hookedRangedData = require(ReplicatedStorage.Modules.DataModules.RangedData)

    local Projectile = {}
    local rangedModule = bedfight.modules.Ranged
    local oldUpdateBeam = nil
    local targetTrackers = {}
    local wallCheck = {Enabled = true}
    local aimbotWallParams = RaycastParams.new()
    aimbotWallParams.FilterType = Enum.RaycastFilterType.Exclude

    local hooktrajectory = function(self, root, projData)
        local tData = self and self.TrajectoryData
        if not (PlayerUtility.lplrIsAlive and tData and root and projData) then return nil,nil,nil end

        local targetChar
        if mode.Value == "Mouse" then
            local ent = PlayerUtility.GetEntityNearMouse(fov.Value, teamCheck.Enabled)
            targetChar = getEntityCharacter(ent)
        else
            local nearest = PlayerUtility.GetNearestEntities(range.Value, teamCheck.Enabled, false)
            targetChar = nearest and nearest[1] and getEntityCharacter(nearest[1])
        end
        if not targetChar then return nil,nil,nil end

        local aimPart = targetChar:FindFirstChild(targetPart.Value) or targetChar:FindFirstChild("HumanoidRootPart")
        if not (aimPart and aimPart:IsA("BasePart")) then return nil,nil,nil end

        local weaponName = getRanged()
        local wData = weaponName and bedfight.modules.RangedData[weaponName]
        local offset = (wData and wData.Offset) or (self.Data and self.Data.Offset) or Vector3.new(1.5,1,0)
        local cam = workspace.CurrentCamera
        local origin = root.Position + cam.CFrame:VectorToWorldSpace(offset)

        local lchar = lplr.Character
        local rightArm = lchar and (lchar:FindFirstChild("RightHand") or lchar:FindFirstChild("Right Arm"))
        local leftArm = lchar and (lchar:FindFirstChild("LeftHand")  or lchar:FindFirstChild("Left Arm"))
        if rightArm and rightArm:IsA("BasePart") and leftArm and leftArm:IsA("BasePart") then
            local armOrigin = (rightArm.Position + leftArm.Position) * 0.5
            origin = origin:Lerp(armOrigin + cam.CFrame:VectorToWorldSpace(offset * 0.35), 0.5)
        elseif rightArm and rightArm:IsA("BasePart") then
            origin = origin:Lerp(rightArm.Position + cam.CFrame:VectorToWorldSpace(offset * 0.35), 0.5)
        end

        local netPing = 0
        pcall(function() netPing = math.clamp(lplr:GetNetworkPing(), 0, 0.12) end)

        local speed = projData.Speed and projData.Speed.Max or 100
        local minSpeed = projData.Speed and projData.Speed.Min or speed
        local liveSpeed = tData.Velocity and tData.Velocity.Magnitude or 0
        if liveSpeed > 1 then speed = math.clamp(liveSpeed, minSpeed, speed) end
        if wData and wData.ChargeTime and wData.ChargeTime > 0 and liveSpeed <= 1 then speed = speed * 0.96 end

        local gravity = projData.Gravity and math.abs(projData.Gravity.Y) or 70

        if not targetTrackers[targetChar] then
            targetTrackers[targetChar] = Prediction.NewTracker(10)
        end
        local tracker = targetTrackers[targetChar]
        Prediction.PushSample(tracker, aimPart.Position, aimPart.AssemblyLinearVelocity, tick())

        local exclusions = {lplr.Character, targetChar, table.unpack(wsScriptChildren)}
        aimbotWallParams.FilterDescendantsInstances = exclusions

        local aimPoint, flightTime = Prediction.SolveTrajectory(
            origin, speed, gravity,
            aimPart.Position, aimPart.AssemblyLinearVelocity,
            workspace.Gravity, 5, nil, nil,
            {
                tracker = tracker,
                latency = netPing,
                shooterVelocity = root.AssemblyLinearVelocity,
                geometryParams = aimbotWallParams,
            }
        )
        if not aimPoint then return nil,nil,nil end

        if wallCheck.Enabled then
            local wallHit = workspace:Raycast(origin, aimPart.Position - origin, aimbotWallParams)
            if wallHit then return nil,nil,nil end
        end

        local launchVel = aimPoint - origin
        local solvedDir = launchVel.Unit
        local solvedIntercept = aimPart.Position + aimPart.AssemblyLinearVelocity * (flightTime or 0.5)

        tData.Velocity = launchVel
        tData.Direction = solvedDir
        tData.AimDirection = solvedDir
        tData.TargetPosition = solvedIntercept
        tData.HitPosition = solvedIntercept
        return launchVel, solvedDir, solvedIntercept
    end

    Projectile = GuiLibrary.Registry.combatPanel.API.CreateOptionsButton({
        Name = "ProjectileAimbot",
        Function = function(callback)
            if callback then
                oldUpdateBeam = rangedModule.UpdateBeam

                rangedModule.UpdateBeam = function(self, root, projData)
                    local solvedVelocity, solvedDirection, solvedIntercept = hooktrajectory(self, root, projData)
                    local trajectoryData = self.TrajectoryData
                    local originalCurveBeam = nil

                    if solvedVelocity and trajectoryData and trajectoryData.CurveBeam then
                        originalCurveBeam = trajectoryData.CurveBeam
                        trajectoryData.CurveBeam = function(td, ...)
                            td.Velocity = solvedVelocity
                            td.Direction = solvedDirection or solvedVelocity.Unit
                            td.AimDirection = td.Direction
                            td.TargetPosition = solvedIntercept
                            td.HitPosition = solvedIntercept
                            return originalCurveBeam(td, ...)
                        end
                    end

                    local result = oldUpdateBeam(self, root, projData)

                    if originalCurveBeam and trajectoryData then
                        trajectoryData.CurveBeam = originalCurveBeam
                    end

                    if solvedVelocity and self.TrajectoryData then
                        self.TrajectoryData.Velocity = solvedVelocity
                        self.TrajectoryData.Direction = solvedDirection or solvedVelocity.Unit
                        self.TrajectoryData.AimDirection = self.TrajectoryData.Direction
                        self.TrajectoryData.TargetPosition = solvedIntercept
                        self.TrajectoryData.HitPosition = solvedIntercept
                    end

                    return result
                end
            else
                rangedModule.UpdateBeam = oldUpdateBeam or rangedModule.UpdateBeam
                targetTrackers = {}
            end
        end
    })
    range = Projectile.CreateSlider({
        Name = "Range",
        Min = 10,
        Max = 150,
        Default = 120,
        Round = 1,
    })
    fov = Projectile.CreateSlider({
        Name = "Mouse FOV",
        Min = 10,
        Max = 300,
        Default = 120,
        Round = 1,
    })
    teamCheck = Projectile.CreateToggle({
        Name = "TeamCheck",
        Default = false,
        Function = function() end
    })
    wallCheck = Projectile.CreateToggle({
        Name = "Wall Check",
        Default = true,
        Function = function() end
    })
    targetPart = Projectile.CreateDropdown({
        Name = "TargetPart",
        List = {"HumanoidRootPart", "Head"},
        Default = "HumanoidRootPart",
        Function = function() end
    })
    mode = Projectile.CreateDropdown({
        Name = "Mode",
        List = {"Distance", "Mouse"},
        Default = "Distance",
        Function = function() end
    })
    mode:ShowWhen("Distance", range)
    mode:ShowWhen("Mouse", fov)
end)

runcode(function()
    local wallParams = RaycastParams.new()
    wallParams.FilterType = Enum.RaycastFilterType.Exclude

    local projLastFire = 0
    local projFakeLast = 0
    local projSwitching = false
    local projPendingShot = false
    local targetTrackers = {}
    local ProjRange = {Value = 100}
    local ProjWall = {Enabled = true}

    projFireAt = function(targetRoot, targetChar, tracker)
        if projPendingShot then return end

        local weaponName = getRanged()
        if not weaponName then return end

        local wData = rangedData[weaponName]
        if not wData then return end

        local pName, pData = getBestProjectile(weaponName)
        if not pName or not pData then return end

        local now = tick()
        local cooldown = wData.Cooldown or 0.8
        if (now - projLastFire) < cooldown then return end

        local myChar = lplr.Character
        local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        if not targetRoot or not targetHum or targetHum.Health <= 0 then return end

        local offset = wData.Offset or Vector3.new(1.5, 1, 0)
        local origin = hrp.Position + Camera.CFrame:VectorToWorldSpace(offset)

        local projSpeed = pData.Speed and pData.Speed.Max or 100
        local gravY = pData.Gravity and math.abs(pData.Gravity.Y) or 70
        local shooterVel = hrp.AssemblyLinearVelocity
        local latency = 0
        pcall(function()
            latency = math.clamp(lplr:GetNetworkPing(), 0, 0.15)
        end)

        local exclusions = {myChar, targetChar, table.unpack(wsScriptChildren)}
        wallParams.FilterDescendantsInstances = exclusions

        local aimPoint, flightTime = Prediction.SolveTrajectory(
            origin, projSpeed, gravY,
            targetRoot.Position, targetRoot.AssemblyLinearVelocity,
            workspace.Gravity, 5, nil, nil,
            {
                tracker = tracker,
                latency = latency,
                shooterVelocity = shooterVel,
                geometryParams = wallParams,
            }
        )
        if not aimPoint then return end

        local launchVel = aimPoint - origin
        if launchVel.Magnitude <= 0.001 then return end

        local aimDir = launchVel.Unit
        local camCF = CFrame.lookAt(Camera.CFrame.Position, aimPoint)

        if ProjWall.Enabled then
            local wallHit = workspace:Raycast(origin, launchVel, wallParams)
            if wallHit and not wallHit.Instance:IsDescendantOf(targetChar) then
                return
            end
        end

        projPendingShot = true
        projLastFire = now
        data.projLastFire = now

        switchitem(weaponName)

        task.wait()
        local equipped = getClientEquipped()
        if equipped ~= weaponName then
            projPendingShot = false
            return
        end

        local _, shotToken = bedfight.modules.spawnFakeProjectile(origin, aimDir, launchVel, pName)
        sendRemote(bedfight.remotes.ShootProjectile, shotToken or 0, weaponName, aimDir, launchVel, camCF)

        if not shotToken then
            task.delay(0.06, function()
                if tick() - projFakeLast > 0.08 then
                    projFakeLast = tick()
                    task.spawn(bedfight.modules.spawnFakeProjectile, origin, aimDir, launchVel, pName)
                end
            end)
        end

        task.defer(function()
            projPendingShot = false
            local sw = getsword()
            if sw then
                switchitem(sw)
            else
                revertitem()
            end
        end)
    end

    local Projectile = GuiLibrary.Registry.combatPanel.API.CreateOptionsButton({
        Name = "ProjectileAura",
        Function = function(callback)
            if callback then
                RunLoops:BindToHeartbeat("Projectile", function()
                    if not PlayerUtility.lplrIsAlive then return end
                    if projPendingShot then return end
                    local nearest = PlayerUtility.GetNearestEntities(ProjRange.Value, true, false)
                    if not nearest or #nearest == 0 then return end
                    local targetChar = getEntityCharacter(nearest[1])
                    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
                    if not targetRoot or not targetHum or targetHum.Health <= 0 then return end
                    if not targetTrackers[targetChar] then
                        targetTrackers[targetChar] = Prediction.NewTracker(10)
                    end
                    Prediction.PushSample(
                        targetTrackers[targetChar],
                        targetRoot.Position,
                        targetRoot.AssemblyLinearVelocity,
                        tick()
                    )
                    projFireAt(targetRoot, targetChar, targetTrackers[targetChar])
                end)
            else
                RunLoops:UnbindFromHeartbeat("Projectile")
                targetTrackers = {}
                task.defer(function()
                    local sw = getsword()
                    if sw then switchitem(sw) else revertitem() end
                end)
            end
        end
    })
    ProjRange = Projectile.CreateSlider({
        Name = "range",
        Min = 10,
        Max = 150,
        Default = 100,
        Round = 1,
        Function = function() end,
    })
    ProjWall = Projectile.CreateToggle({
        Name = "Wall Check",
        Default = true,
        Function = function() end,
    })
end)

runcode(function()
    local origReach = {}
    local ReachVal = {Value = 20}
    for name, data in pairs(bedfight.modules.SwordsData) do
        if type(data) == "table" and data.Range then
            origReach[name] = { Range = data.Range, HitboxSize = data.HitboxSize }
        end
    end
    Reach = GuiLibrary.Registry.combatPanel.API.CreateOptionsButton({
        Name = "Reach",
        Function = function(callback)
            for name, orig in pairs(origReach) do
                local d = bedfight.modules.SwordsData[name]
                if d then
                    d.Range = callback and ReachVal.Value or orig.Range
                    d.HitboxSize = callback and Vector3.new(ReachVal.Value, ReachVal.Value, ReachVal.Value * 2) or orig.HitboxSize
                end
            end
        end
    })
    Reach.CreateSlider({
        Name = "Range",
        Min = 5, 
        Max = 25, 
        Default = 25,
        Round = 1,
        Function = function(callback)
            ReachVal.Value = callback
            if Reach.Enabled then
                for name, d in pairs(bedfight.modules.SwordsData) do
                    if type(d) == "table" and d.Range then
                        d.Range = callback
                        d.HitboxSize = Vector3.new(callback, callback, callback * 2)
                    end
                end
            end
        end
    })
end)

runcode(function()
    local KeepInv = {}
    local SaveInLobby = {}

    local chestState = {saved = {}, savedSlots = {}, saving = false, rConn = nil, hConn = nil, invConn = nil, saveCooldown = false, restoreCooldown = false, dmgWindow = {}, lastHp = 0, lowestY = math.huge, lobbySaved = false,}

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide and v.Transparency < 1 then
            local y = v.Position.Y - v.Size.Y / 2
            if y < chestState.lowestY then chestState.lowestY = y end
        end
    end
    local lowestY = chestState.lowestY

    local chestfuncs = {}

    chestfuncs.Loop = function(loop, cycle, index, teams)
        if not PlayerUtility.IsAlive(lplr) then return end
        local team = lplr.Team and lplr.Team.Name
        if not team or team == "Spectators" or not teams or #teams == 0 then
            return getTeams(), 1, 1
        end
        local t = teams[index]
        local teamName = typeof(t) == "Instance" and t.Name or t
        local chest = ReplicatedStorage.TeamChestsStorage:FindFirstChild(teamName)
        if chest and teamName ~= "Spectators" then
            local slot = chest:FindFirstChild(tostring(cycle))
            local name = slot and slot:GetAttribute("Name")
            if name and name ~= "" then
                sendRemote(bedfight.remotes.TakeItemFromChest, teamName, cycle, tostring(cycle))
            end
        end
        index = index + 1
        if index > #teams then return getTeams(), 1, cycle % 3 + 1 end
        return teams, index, cycle
    end

    chestfuncs.Save = function(team)
        if chestState.saving or chestState.saveCooldown then return end
        chestState.saving = true
        chestState.saved = {}
        chestState.savedSlots = {}
        local teamName = typeof(team) == "Instance" and team.Name or team
        for _, invy in pairs(bedfight.modules.InventoryHandler.Inventories) do
            for i, slot in pairs(invy.Items) do
                if slot.Name ~= "" then
                    local itemData = bedfight.modules.ItemsData[slot.Name]
                    if itemData and itemData.CanStoreInChest then
                        if not chestState.savedSlots[i] then
                            chestState.savedSlots[i] = true
                            local chestSlot = 99 + i
                            chestState.saved[slot.Name .. "_" .. i .. "_" .. chestSlot] = {team = team, slot = chestSlot}
                            sendRemote(bedfight.remotes.PutItemInChest, slot.Name, teamName, chestSlot)
                        end
                    end
                end
            end
        end
        chestState.saving = false
        chestState.saveCooldown = true
        task.delay(5, function() chestState.saveCooldown = false end)
    end

    chestfuncs.SaveItem = function(team, item)
        if not item or item.Name == "" then return end
        local itemData = bedfight.modules.ItemsData[item.Name]
        if not itemData or not itemData.CanStoreInChest then return end
        local teamName = typeof(team) == "Instance" and team.Name or team
        for _, invy in pairs(bedfight.modules.InventoryHandler.Inventories) do
            for i, slot in pairs(invy.Items) do
                if slot.Name == item.Name and not (chestState.savedSlots and chestState.savedSlots[i]) then
                    local chestSlot = 99 + i
                    chestState.savedSlots = chestState.savedSlots or {}
                    chestState.savedSlots[i] = true
                    chestState.saved[item.Name .. "_" .. i .. "_" .. chestSlot] = {team = team, slot = chestSlot}
                    sendRemote(bedfight.remotes.PutItemInChest, item.Name, teamName, chestSlot)
                    return
                end
            end
        end
    end

    chestfuncs.Restore = function(loop)
        if not next(chestState.saved) then return end
        local restoreList = {}
        for _, dataSlot in pairs(chestState.saved) do table.insert(restoreList, dataSlot) end
        chestState.saved = {}
        chestState.savedSlots = {}
        chestState.dmgWindow = {}
        task.spawn(function()
            for _, info in ipairs(restoreList) do
                task.wait(0.25)
                local teamName = typeof(info.team) == "Instance" and info.team.Name or info.team
                sendRemote(bedfight.remotes.TakeItemFromChest, teamName, info.slot, tostring(info.slot))
            end
            if loop then RunLoops:BindToHeartbeat("ChestManagerLoop", loop) end
        end)
    end

    chestfuncs.Cleanup = function()
        RunLoops:UnbindFromHeartbeat("ChestManagerVoid")
        if chestState.hConn then chestState.hConn:Disconnect(); chestState.hConn = nil end
        if chestState.invConn then chestState.invConn:Disconnect(); chestState.invConn = nil end
        chestState.dmgWindow = {}
        chestState.saveCooldown = false
        chestState.restoreCooldown = false
        chestState.lobbySaved = false
        chestState.saving = false
    end

    chestfuncs.Hook = function(loop)
        chestfuncs.Cleanup()
        local char = lplr.Character
        if not char then return end
        local hum = char:WaitForChild("Humanoid")
        local hrp = char:WaitForChild("HumanoidRootPart")
        local inv = lplr:WaitForChild("Inventory")
        chestState.lastHp = hum.Health

        RunLoops:BindToHeartbeat("ChestManagerVoid", function()
            if not KeepInv.Enabled or chestState.saving or chestState.saveCooldown then return end
            if not (hrp and hrp.Parent) then return end
            local team = lplr.Team and lplr.Team.Name
            if not team or team == "Spectators" then return end
            if hrp.Position.Y <= lowestY - 15 then
                chestfuncs.Save(team)
            elseif SaveInLobby.Enabled and not chestState.lobbySaved and data.matchState == 0 then
                chestState.lobbySaved = true
                chestfuncs.Save(team)
            end
        end)

        chestState.hConn = hum.HealthChanged:Connect(function(h)
            if not KeepInv.Enabled then return end
            local team = lplr.Team and lplr.Team.Name
            if not team or team == "Spectators" then return end
            local delta = chestState.lastHp - h
            local maxHp = hum.MaxHealth
            chestState.lastHp = h

            if h <= 0 and not chestState.saving then
                chestfuncs.Save(team)
                return
            end

            if delta > 0 then
                local now = tick()
                table.insert(chestState.dmgWindow, {t = now, dmg = delta})
                for i = #chestState.dmgWindow, 1, -1 do
                    if now - chestState.dmgWindow[i].t > 1.2 then table.remove(chestState.dmgWindow, i) end
                end
                local total = 0
                for _, e in ipairs(chestState.dmgWindow) do total = total + e.dmg end
                local hpRatio = h / maxHp
                if total >= h*0.85 or delta >= maxHp*0.45 or (hpRatio <= 0.20 and total >= maxHp*0.06) or (hpRatio <= 0.35 and total >= h*0.60) then
                    chestfuncs.Save(team)
                end
            elseif delta < 0 and not chestState.restoreCooldown and next(chestState.saved) then
                if h / maxHp >= 0.50 then
                    chestState.restoreCooldown = true
                    chestfuncs.Restore(loop)
                    task.delay(2.5, function() chestState.restoreCooldown = false end)
                end
            end
        end)

        chestState.invConn = inv.ChildAdded:Connect(function(item)
            if not KeepInv.Enabled or chestState.saveCooldown then return end
            local team = lplr.Team and lplr.Team.Name
            if not team or team == "Spectators" then return end
            local now = tick()
            local windowActive = false
            for _, e in ipairs(chestState.dmgWindow) do
                if now - e.t <= 1.2 then windowActive = true; break end
            end
            local hpRatio = hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) or 0
            local inDanger = windowActive or hpRatio <= 0.35

            if not inDanger then return end
            task.delay(0.1, function()
                if not KeepInv.Enabled then return end
                chestfuncs.SaveItem(team, item)
            end)
        end)
    end

    local CM = GuiLibrary.Registry.inventoryPanel.API.CreateOptionsButton({
        Name = "ChestManager",
        New = true,
        Function = function(callback)
            if data.gamemode.current ~= "Ranked 1v1" and data.gamemode.current ~= "Ranked 4v4" then
                local loopState = {cycle = 1, index = 1, teams = {}}
                local function loop()
                    loopState.teams, loopState.index, loopState.cycle = chestfuncs.Loop(loop, loopState.cycle, loopState.index, loopState.teams)
                end
                if callback then
                    loopState.teams = getTeams()
                    if chestState.rConn then chestState.rConn:Disconnect() end
                    chestState.rConn = lplr.CharacterAdded:Connect(function(char)
                        local hum = char:WaitForChild("Humanoid", 5)
                        if not hum then return end
                        chestfuncs.Restore(loop)
                        chestfuncs.Hook(loop)
                    end)
                    chestfuncs.Hook(loop)
                    RunLoops:BindToHeartbeat("ChestManagerLoop", loop)
                else
                    RunLoops:UnbindFromHeartbeat("ChestManagerLoop")
                    chestfuncs.Cleanup()
                    chestState.saved = {}
                    chestState.savedSlots = {}
                    if chestState.rConn then chestState.rConn:Disconnect(); chestState.rConn = nil end
                end
            end
        end
    })
    KeepInv = CM.CreateToggle({
        Name = "KeepInv",
        Function = function() end
    })
    SaveInLobby = CM.CreateToggle({
        Name = "SaveInLobby",
        Function = function() end
    })
end)

runcode(function()
    local Cape = {}
    local Capedrop = {}
    local CapesFolder = ReplicatedStorage:WaitForChild("Capes")
    local currentCape = nil
    local connection = nil

    local function equipCape(capeName)
        local char = lplr.Character
        if not char then return end

        local capeValue = lplr:FindFirstChild("Cape")
        if capeValue then
            capeValue.Value = capeName
        end
        currentCape = capeName
    end

    local capeList = {}
    for _, cape in pairs(CapesFolder:GetChildren()) do
        table.insert(capeList, cape.Name)
    end

    Cape = GuiLibrary.Registry.renderPanel.API.CreateOptionsButton({
        Name = "Cape",
        Function = function(callback)
            if callback then
                equipCape(currentCape or capeList[1])
                connection = lplr.CharacterAdded:Connect(function()
                    if currentCape then
                        equipCape(currentCape)
                    end
                end)
            else
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
                if lplr.Character then
                    local capeValue = lplr:FindFirstChild("Cape")
                    if capeValue then
                        capeValue.Value = ""
                    end
                end
                currentCape = nil
            end
        end
    })

    Capedrop = Cape.CreateDropdown({
        Name = "Cape",
        List = capeList,
        Default = capeList[1] or "",
        Function = function(callback)
            if not Cape.Enabled then return end
            equipCape(callback)
        end
    })
end)

runcode(function()
    local Tracers = {}
    local TracerThickness = {}
    local Lines = {}
    local TracerGui

    local TracerColor = {}
    local TracerDistLabel = {}

    Tracers = GuiLibrary.Registry.renderPanel.API.CreateOptionsButton({
        Name = "Tracers",
        Function = function(callback)
            if callback then
                if not TracerGui then
                    TracerGui = Instance.new("ScreenGui")
                    TracerGui.Name = "Tracers"
                    TracerGui.ResetOnSpawn = false
                    TracerGui.Parent = hidden and hidden() or game.CoreGui
                end
                RunLoops:BindToHeartbeat("Tracers", function()
                    if _sti then _sti(8) end
                    local i = 1
                    local LineOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")

                    for _, v in pairs(Players:GetPlayers()) do
                        if v ~= lplr and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                            local hrp = v.Character.HumanoidRootPart
                            local pos, onScreen = Camera:WorldToScreenPoint(hrp.Position)

                            if onScreen then
                                local line = Lines[i] or Instance.new("Frame")
                                Lines[i] = line

                                line.Name = "Line"
                                line.AnchorPoint = Vector2.new(0.5, 0.5)
                                line.BorderSizePixel = 0
                                line.Parent = TracerGui

                                local screenPos = Vector2.new(pos.X, pos.Y)
                                local mid = (LineOrigin + screenPos) / 2
                                local len = (LineOrigin - screenPos).Magnitude

                                line.Position = UDim2.new(0, mid.X, 0, mid.Y)
                                line.Size = UDim2.new(0, len, 0, TracerThickness.Value)
                                line.Rotation = math.deg(math.atan2(
                                    screenPos.Y - LineOrigin.Y,
                                    screenPos.X - LineOrigin.X
                                ))

                                local color
                                if TracerColor.Enabled and v.Team then
                                    color = v.Team.TeamColor.Color
                                else
                                    color = GuiLibrary.kit:activeColor()
                                end
                                line.BackgroundColor3 = color
                                line.BorderColor3 = color
                                line.Visible = true

                                if TracerDistLabel.Enabled and myRoot then
                                    local dist = math.floor((myRoot.Position - hrp.Position).Magnitude)
                                    local lbl = line:FindFirstChildOfClass("TextLabel")
                                    if not lbl then
                                        lbl = Instance.new("TextLabel")
                                        lbl.BackgroundTransparency = 1
                                        lbl.TextColor3 = Color3.new(1, 1, 1)
                                        lbl.TextStrokeTransparency = 0.5
                                        lbl.Font = Enum.Font.GothamSemibold
                                        lbl.TextSize = 11
                                        lbl.Size = UDim2.new(0, 40, 0, 14)
                                        lbl.AnchorPoint = Vector2.new(0.5, 0.5)
                                        lbl.Position = UDim2.new(0.5, 0, 0.5, -8)
                                        lbl.Parent = line
                                    end
                                    lbl.Text = dist .. "m"
                                    lbl.Visible = true
                                else
                                    local lbl = line:FindFirstChildOfClass("TextLabel")
                                    if lbl then lbl.Visible = false end
                                end

                                i = i + 1
                            end
                        end
                    end

                    for j = i, #Lines do
                        if Lines[j] then
                            Lines[j].Visible = false
                        end
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("Tracers")

                if TracerGui then
                    TracerGui:Destroy()
                    TracerGui = nil
                end

                Lines = {}
            end
        end
    })
    TracerThickness = Tracers.CreateSlider({
        Name = "Thickness",
        Min = 1,
        Max = 10,
        Default = 1
    })
    TracerColor = Tracers.CreateToggle({
        Name = "Team Color",
        Default = false,
        Function = function() end
    })
    TracerDistLabel = Tracers.CreateToggle({
        Name = "Distance Label",
        Default = false,
        Function = function() end
    })
end)

runcode(function()
    local NameTags = {}
    local TeamColor = {}
    local ShowDistance = {}
    local TagSize = {}
    local TextSize = {}
    local BoldText = {}
    local FontWeight = {}
    local IconBackground = {}
    local RoundedCorners = {}
    local SeparateBackground = {}
    local ShowDisplayName = {}
    local ShowArmorIcons = {}
    local ShowSwordIcons = {}
    local ShowBrackets = {}
    local ShowHealth = {}
    local TagBg = {}
    local TagBgCorner = {}
    local FontChoice = {}
    local IconSpacing = {}

    local tags = {}
    local pending = {}
    local cleanupConns = {}
    local fallback = "rbxassetid://130674868309232"
    local swords = bedfight.modules.SwordsData or {}
    local NameTagGui

    local iconMap = {}
    local kinds = {armor = {}, sword = {}}
    local armorTypes = {}

    local function norm(value)
        return string.gsub(string.lower(tostring(value or "")), "[^%w]", "")
    end

    local function removeTags(str)
        return (str:gsub("<[^<>]->", ""))
    end

    local FONT_FAMILIES = {
        ["Arial"]       = "rbxasset://fonts/families/Arial.json",
        ["Gotham"]      = "rbxasset://fonts/families/GothamSSm.json",
        ["Montserrat"]  = "rbxasset://fonts/families/Montserrat.json",
        ["Nunito"]      = "rbxasset://fonts/families/Nunito.json",
        ["Ubuntu"]      = "rbxasset://fonts/families/Ubuntu.json",
        ["Roboto"]      = "rbxasset://fonts/families/Roboto.json",
        ["Source Sans"] = "rbxasset://fonts/families/SourceSansPro.json",
        ["Arimo"]       = "rbxasset://fonts/families/Arimo.json",
    }
    local FONT_WEIGHT_MAP = {
        Semibold = Enum.FontWeight.SemiBold,
        Bold = Enum.FontWeight.Bold,
        Black = Enum.FontWeight.Heavy,
    }
    local FONT_REGULAR = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular)
    local FONT_SEMIBOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
    local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    local FONT_BLACK = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)

    local function getNameTagGui()
        if NameTagGui and NameTagGui.Parent then
            return NameTagGui
        end

        NameTagGui = Instance.new("ScreenGui")
        NameTagGui.Name = "PhantomNameTags"
        NameTagGui.ResetOnSpawn = false
        NameTagGui.IgnoreGuiInset = true
        NameTagGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        NameTagGui.Parent = hidden and hidden() or game.CoreGui
        return NameTagGui
    end

    for itemName, itemData in pairs(bedfight.modules.ItemsData) do
        if itemData and itemData.Image then
            iconMap[string.lower(itemName)] = itemData.Image
        end
        if itemData and itemData.Armor ~= nil then
            local key = norm(itemName)
            if key ~= "" then
                kinds.armor[key] = itemName
            end
        end
    end

    for swordName in pairs(swords) do
        local key = norm(swordName)
        if key ~= "" then
            kinds.sword[key] = swordName
        end
    end

    local armorInv = bedfight.modules.InventoryHandler.Inventories and bedfight.modules.InventoryHandler.Inventories.Armor
    if armorInv then
        for _, slot in ipairs(armorInv.Items) do
            local key = norm(slot:GetAttribute("Class"))
            if key ~= "" then
                armorTypes[key] = true
            end
        end
    end

    local function getKind(itemName, invType, itemData, className)
        local invKey = norm(invType)
        local key = norm(itemName)
        local classKey = norm(className)
        local nameText = string.lower(tostring(itemName or ""))
        local invText = string.lower(tostring(invType or ""))
        local classText = string.lower(tostring(className or ""))
        local meta = itemData and string.lower(
            tostring(itemData.ItemType or itemData.itemType or "") .. " " ..
            tostring(itemData.Class or "") .. " " ..
            tostring(itemData.Category or "") .. " " ..
            tostring(itemData.Type or "") .. " " ..
            tostring(itemData.DisplayName or "")
        ) or ""

        if classText ~= "" then
            meta = meta .. " " .. classText
        end

        if classKey ~= "" and kinds.armor[classKey] then
            return "armor", kinds.armor[classKey]
        end

        local looksArmor =
            invKey == "armor"
            or armorTypes[invKey]
            or armorTypes[classKey]
            or (itemData and itemData.Armor ~= nil)
            or string.find(invText, "armor", 1, true)
            or string.find(classText, "armor", 1, true)
            or string.find(nameText, "armor", 1, true)
            or string.find(nameText, "helmet", 1, true)
            or string.find(nameText, "chestplate", 1, true)
            or string.find(nameText, "leggings", 1, true)
            or string.find(nameText, "boots", 1, true)
            or string.find(nameText, "pants", 1, true)
            or string.find(meta, "armor", 1, true)
            or string.find(meta, "helmet", 1, true)
            or string.find(meta, "chestplate", 1, true)
            or string.find(meta, "leggings", 1, true)
            or string.find(meta, "boots", 1, true)
            or string.find(meta, "pants", 1, true)

        if looksArmor then
            if key ~= "" then
                if kinds.armor[key] then
                    return "armor", kinds.armor[key]
                end
                if classKey ~= "" and kinds.armor[classKey] then
                    return "armor", kinds.armor[classKey]
                end
                for matchKey, realName in pairs(kinds.armor) do
                    if string.find(matchKey, key, 1, true) or string.find(key, matchKey, 1, true) then
                        return "armor", realName
                    end
                    if classKey ~= "" and (string.find(matchKey, classKey, 1, true) or string.find(classKey, matchKey, 1, true)) then
                        return "armor", realName
                    end
                end
            end
            return "armor", itemName
        end

        if swords[itemName]
            or string.find(invText, "sword", 1, true)
            or string.find(classText, "sword", 1, true)
            or string.find(nameText, "sword", 1, true)
            or string.find(meta, "sword", 1, true)
        then
            return "sword", itemName
        end

        if key == "" then
            return nil, nil
        end

        for matchKey, realName in pairs(kinds.sword) do
            if string.find(matchKey, key, 1, true) or string.find(key, matchKey, 1, true) then
                return "sword", realName
            end
        end

        return nil, nil
    end

    local function disconnectCleanup()
        for _, conn in ipairs(cleanupConns) do
            if conn and conn.Disconnect then
                conn:Disconnect()
            end
        end
        table.clear(cleanupConns)
    end

    local function clearTag(plr)
        local tag = tags[plr]
        if not tag then return end
        if tag.board then
            tag.board:Destroy()
        end
        tags[plr] = nil
        pending[plr] = nil
    end

    local function clearAllTags()
        for plr in pairs(tags) do
            clearTag(plr)
        end
    end

    local function updateSubVis()
        local showIcons = (ShowArmorIcons and ShowArmorIcons.Enabled) or (ShowSwordIcons and ShowSwordIcons.Enabled)
        local showIconBg = showIcons and (IconBackground and IconBackground.Enabled)
        local showSepBg = showIconBg and (SeparateBackground and SeparateBackground.Enabled)
        if IconBackground     and IconBackground.Instance     then IconBackground.Instance.Visible = showIcons  end
        if RoundedCorners     and RoundedCorners.Instance     then RoundedCorners.Instance.Visible = showIconBg end
        if SeparateBackground and SeparateBackground.Instance then SeparateBackground.Instance.Visible = showIconBg end
        if TagSize            and TagSize.Instance            then TagSize.Instance.Visible = showIcons  end
        if IconSpacing        and IconSpacing.Instance        then IconSpacing.Instance.Visible = showSepBg  end
    end


    local function applyTextLayout(entry, baseTagH, hasIcons)
        local bounds = entry.label.TextBounds
        local bx = math.max(1, bounds.X)
        local by = math.max(1, bounds.Y)
        local iconBandH = hasIcons and math.max(16, math.floor(baseTagH * 0.42)) or 0
        local width = bx + 10
        local totalH = by + iconBandH + 6

        local boardChanged = entry.cBoardW ~= width or entry.cBoardH ~= totalH
        if boardChanged then
            entry.board.Size = UDim2.new(0, width, 0, totalH)
            entry.bg.Size = UDim2.new(1, 0, 1, 0)
            entry.cBoardW = width
            entry.cBoardH = totalH
        end

        local iconChanged = entry.cIconBandH ~= iconBandH
        if boardChanged or iconChanged then
            local lblW = bx + 6
            local lblH = by + 4
            if hasIcons then
                entry.icons.Visible = true
                entry.icons.Size = UDim2.new(1, 0, 0, iconBandH)
                entry.icons.Position = UDim2.new(0, 0, 0, 0)
                entry.label.AnchorPoint = Vector2.new(0.5, 0)
                entry.label.Position = UDim2.new(0.5, 0, 0, iconBandH + 1)
                entry.label.Size = UDim2.new(0, lblW, 0, lblH)
            else
                entry.icons.Visible = false
                entry.label.AnchorPoint = Vector2.new(0.5, 0)
                entry.label.Position = UDim2.new(0.5, 0, 0, 1)
                entry.label.Size = UDim2.new(0, lblW, 0, lblH)
            end
            entry.cIconBandH = iconBandH
        end
    end

    NameTags = GuiLibrary.Registry.renderPanel.API.CreateOptionsButton({
        Name = "NameTags",
        Function = function(callback)
            if callback then
                getNameTagGui()

                local function getTargetFont(bold, weight)
                    local family = FONT_FAMILIES[FontChoice and FontChoice.Value or "Gotham"]
                        or "rbxasset://fonts/families/GothamSSm.json"
                    local w = bold and (FONT_WEIGHT_MAP[weight] or Enum.FontWeight.SemiBold) or Enum.FontWeight.Regular
                    return Font.new(family, w)
                end

                local function _getArmorSlot(itemName, itemData, className)
                    local t = string.lower(
                        tostring(itemName or "") .. " " ..
                        tostring(className or "") .. " " ..
                        tostring(itemData and itemData.Class or "") .. " " ..
                        tostring(itemData and itemData.Category or "") .. " " ..
                        tostring(itemData and itemData.Type or "") .. " " ..
                        tostring(itemData and itemData.DisplayName or "")
                    )
                    if string.find(t, "helmet", 1, true) or string.find(t, "head", 1, true) then return "helmet" end
                    if string.find(t, "chestplate", 1, true) or string.find(t, "chest", 1, true) or string.find(t, "body", 1, true) then return "chestplate" end
                    if string.find(t, "leggings", 1, true) or string.find(t, "pants", 1, true) or string.find(t, "legs", 1, true) then return "leggings" end
                    if string.find(t, "boots", 1, true) or string.find(t, "shoes", 1, true) or string.find(t, "feet", 1, true) then return "boots" end
                end

                local function _getPriority(invType, className)
                    local invText = string.lower(tostring(invType or ""))
                    local classKey = norm(className)
                    if invText == "armor" then return 5 end
                    if armorTypes[classKey] then return 4 end
                    if invText == "characterworn" then return 3 end
                    if invText == "equipped" then return 2 end
                    return 1
                end

                local function _addItem(itemName, invType, className, armorItems, swordRef)
                    if not itemName or itemName == "" then return end

                    local classItem = tostring(className or "")
                    local itemData = bedfight.modules.ItemsData[itemName] or bedfight.modules.ItemsData[classItem]
                    local kind, realName = getKind(itemName, invType, itemData, className)
                    if not kind then return end
                    if (kind == "sword" and not ShowSwordIcons.Enabled) or (kind == "armor" and not ShowArmorIcons.Enabled) then return end

                    local name = realName or itemName
                    if kind == "armor" and not realName and classItem ~= "" and bedfight.modules.ItemsData[classItem] then
                        name = classItem
                    end

                    local idata = bedfight.modules.ItemsData[name] or bedfight.modules.ItemsData[classItem] or itemData
                    local image = fallback

                    if idata and idata.Image then
                        image = idata.Image
                    else
                        for _, searchName in ipairs({name, classItem}) do
                            if searchName ~= "" then
                                local lower = string.lower(searchName)
                                if iconMap[lower] then
                                    image = iconMap[lower]
                                    break
                                end
                                local key = norm(searchName)
                                for iconName, icon in pairs(iconMap) do
                                    local iconKey = norm(iconName)
                                    if iconKey == key or string.find(iconKey, key, 1, true) or string.find(key, iconKey, 1, true) then
                                        image = icon
                                        break
                                    end
                                end
                                if image ~= fallback then break end
                            end
                        end
                    end

                    local priority = _getPriority(invType, className)

                    if kind == "sword" then
                        if not swordRef[1] or priority > swordRef[1].priority then
                            swordRef[1] = {name = name, image = image, priority = priority}
                        end
                        return
                    end

                    local slot = _getArmorSlot(name, idata, className) or _getArmorSlot(itemName, itemData, className)
                    local key = slot or name
                    local current = armorItems[key]
                    if not current or priority > current.priority then
                        armorItems[key] = {slot = slot, name = name, image = image, priority = priority}
                    end
                end

                disconnectCleanup()

                table.insert(cleanupConns, Players.PlayerRemoving:Connect(function(plr)
                    clearTag(plr)
                end))

                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= lplr then
                        table.insert(cleanupConns, plr.CharacterRemoving:Connect(function()
                            clearTag(plr)
                        end))
                        table.insert(cleanupConns, plr.CharacterAdded:Connect(function()
                            clearTag(plr)
                        end))
                    end
                end

                local infoTick = 0

                RunLoops:BindToHeartbeat("NameTags", function(dt)
                    if _sti then _sti(8) end
                    infoTick = infoTick + dt

                    local vp = Camera.ViewportSize
                    local viewScale = math.clamp((vp.Y / 1080), 0.82, 1.4)
                    local tagSizeV = (TagSize and TagSize.Value) or 160
                    local baseTagW = math.floor(tagSizeV * viewScale)
                    local baseTagH = math.floor(tagSizeV * 0.40 * viewScale)
                    local textSz = math.max(7, math.floor(((TextSize and TextSize.Value) or 10) * viewScale))
                    local targetFont = getTargetFont(BoldText and BoldText.Enabled, FontWeight and FontWeight.Value)
                    local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                    local doInfoUpdate = infoTick >= 0.15

                    if doInfoUpdate then
                        infoTick = 0
                    end

                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= lplr then
                            local char = plr.Character
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            local root = char and char:FindFirstChild("HumanoidRootPart")

                            if not char or not hum or not root or hum.Health <= 0 or not root:IsDescendantOf(workspace) then
                                clearTag(plr)
                                continue
                            end

                            local entry = tags[plr]
                            if not entry then
                                local board = Instance.new("Frame")
                                board.Name = "NameTag"
                                board.AnchorPoint = Vector2.new(0.5, 1)
                                board.BackgroundTransparency = 1
                                board.BorderSizePixel = 0
                                board.Visible = false
                                board.Size = UDim2.new(0, baseTagW, 0, baseTagH)
                                board.Parent = getNameTagGui()

                                local bg = Instance.new("Frame")
                                bg.Name = "BG"
                                bg.BackgroundColor3 = Color3.new(0, 0, 0)
                                bg.BackgroundTransparency = 1
                                bg.Size = UDim2.new(1, 0, 1, 0)
                                bg.BorderSizePixel = 0
                                bg.Parent = board

                                local label = Instance.new("TextLabel")
                                label.Name = "Label"
                                label.AnchorPoint = Vector2.new(0.5, 0)
                                label.BackgroundColor3 = Color3.new(0, 0, 0)
                                label.BackgroundTransparency = 1
                                label.TextWrapped = false
                                label.TextXAlignment = Enum.TextXAlignment.Center
                                label.TextYAlignment = Enum.TextYAlignment.Center
                                label.Font = Enum.Font.GothamSemibold
                                label.TextScaled = false
                                label.TextStrokeTransparency = 0.3
                                label.TextStrokeColor3 = Color3.new(0, 0, 0)
                                label.TextColor3 = Color3.new(1, 1, 1)
                                label.RichText = true
                                label.Parent = bg
                                local labelCorner = Instance.new("UICorner")
                                labelCorner.CornerRadius = UDim.new(0, 5)
                                labelCorner.Parent = label

                                local iconFrame = Instance.new("Frame")
                                iconFrame.Name = "ArmorIcons"
                                iconFrame.BackgroundTransparency = 1
                                iconFrame.Parent = bg

                                entry = {
                                    board = board,
                                    bg = bg,
                                    labelCorner = labelCorner,
                                    label = label,
                                    icons = iconFrame,
                                    sig = "",
                                    cText = nil,
                                    cFont = nil,
                                    cFontW = nil,
                                    cTextSz = nil,
                                    cColor = nil,
                                    cBoardW = nil,
                                    cBoardH = nil,
                                    cIconBandH = nil,
                                }
                                tags[plr] = entry
                            end

                            if doInfoUpdate then
                                local hook = data.hooked[plr]
                                if not hook then
                                    if not pending[plr] then
                                        pending[plr] = true
                                        task.spawn(function()
                                            hookinv(plr)
                                            pending[plr] = nil
                                        end)
                                    end
                                else
                                    pending[plr] = nil
                                end

                                local armorItems = {}
                                local swordRef = {}

                                if hook and hook.items then
                                    for _, itemEntry in ipairs(hook.items) do
                                        local itemObj = itemEntry.item
                                        _addItem(itemObj and itemObj.Name, itemEntry.inventory or itemEntry.class, itemEntry.class, armorItems, swordRef)
                                    end
                                end

                                local baseName
                                if _G.phantomNameSpoofActive then
                                    baseName = _G.phantomSpoofName or "wynnech"
                                elseif ShowDisplayName.Enabled then
                                    baseName = plr.DisplayName ~= "" and plr.DisplayName or plr.Name
                                else
                                    baseName = plr.Name
                                end

                                local text = string.upper(baseName)

                                if ShowDistance.Enabled and myRoot then
                                    local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                                    if ShowBrackets.Enabled then
                                        text = '<font color="rgb(85,255,85)">[</font>'
                                            .. '<font color="rgb(255,255,255)">' .. dist .. '</font>'
                                            .. '<font color="rgb(85,255,85)">]</font> ' .. text
                                    else
                                        text = '<font color="rgb(85,255,85)">' .. dist .. '</font> ' .. text
                                    end
                                end

                                if ShowHealth.Enabled then
                                    local hp = math.floor(hum.Health)
                                    local maxhp = math.max(hum.MaxHealth, 1)
                                    local hc = Color3.fromHSV(math.clamp(hp / maxhp, 0, 1) / 2.5, 0.89, 0.75)
                                    local hStr = 'rgb(' .. math.floor(hc.R*255) .. ',' .. math.floor(hc.G*255) .. ',' .. math.floor(hc.B*255) .. ')'
                                    if ShowBrackets.Enabled then
                                        text = text .. ' <font color="' .. hStr .. '">[' .. hp .. ']</font>'
                                    else
                                        text = text .. ' <font color="' .. hStr .. '">' .. hp .. '</font>'
                                    end
                                end

                                local color = (TeamColor.Enabled and plr.Team and plr.Team.TeamColor.Color) or Color3.new(1, 1, 1)

                                local items = {}
                                for _, slotName in ipairs({"helmet", "chestplate", "leggings", "boots"}) do
                                    local info = armorItems[slotName]
                                    if info then
                                        table.insert(items, {name = info.name, image = info.image})
                                    end
                                end
                                if swordRef[1] then
                                    table.insert(items, {name = swordRef[1].name, image = swordRef[1].image})
                                end

                                local hasIcons = #items > 0

                                if entry.cText ~= text then
                                    entry.cText = text
                                    entry.label.Text = text
                                end
                                if entry.cFont ~= targetFont.Family or entry.cFontW ~= targetFont.Weight then
                                    entry.cFont = targetFont.Family
                                    entry.cFontW = targetFont.Weight
                                    entry.label.FontFace = targetFont
                                end
                                if entry.cTextSz ~= textSz then
                                    entry.cTextSz = textSz
                                    entry.label.TextSize = textSz
                                end
                                if entry.cColor ~= color then
                                    entry.cColor = color
                                    entry.label.TextColor3 = color
                                end

                                local bgEnabled = IconBackground.Enabled
                                local sepEnabled = SeparateBackground.Enabled
                                local rndEnabled = RoundedCorners.Enabled
                                local iconGap = sepEnabled and math.floor((IconSpacing and IconSpacing.Value) or 3) or 2

                                local parts = {}
                                for _, info in ipairs(items) do
                                    table.insert(parts, info.name)
                                end

                                local iconSig = table.concat(parts, "|")
                                    .. "|bg=" .. tostring(bgEnabled)
                                    .. "|sep=" .. tostring(sepEnabled)
                                    .. "|rnd=" .. tostring(rndEnabled)
                                    .. "|gap=" .. tostring(iconGap)
                                    .. "|h=" .. tostring(baseTagH)

                                if entry.sig ~= iconSig then
                                    entry.sig = iconSig

                                    for _, iconChild in ipairs(entry.icons:GetChildren()) do
                                        iconChild:Destroy()
                                    end

                                    if hasIcons then
                                        local iconBandH = math.max(16, math.floor(baseTagH * 0.42))
                                        local iconPx = math.max(12, math.floor(iconBandH * 0.78))
                                        local totalIconW = #items * iconPx + math.max(0, #items - 1) * iconGap

                                        local iconRow = Instance.new("Frame")
                                        iconRow.Name = "IconRow"
                                        iconRow.AnchorPoint = Vector2.new(0.5, 0.5)
                                        iconRow.Position = UDim2.new(0.5, 0, 0.5, 0)
                                        iconRow.Size = UDim2.new(0, totalIconW, 0, iconPx)
                                        iconRow.AutomaticSize = Enum.AutomaticSize.X
                                        iconRow.BackgroundTransparency = 1
                                        iconRow.BorderSizePixel = 0
                                        iconRow.Parent = entry.icons

                                        local layout = Instance.new("UIListLayout")
                                        layout.FillDirection = Enum.FillDirection.Horizontal
                                        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                                        layout.VerticalAlignment = Enum.VerticalAlignment.Center
                                        layout.Padding = UDim.new(0, iconGap)
                                        layout.SortOrder = Enum.SortOrder.LayoutOrder
                                        layout.Parent = iconRow

                                        if bgEnabled and not sepEnabled then
                                            local holder = Instance.new("Frame")
                                            holder.Name = "SharedIconBG"
                                            holder.AnchorPoint = Vector2.new(0.5, 0.5)
                                            holder.Position = UDim2.new(0.5, 0, 0.5, 0)
                                            holder.Size = UDim2.new(0, totalIconW + 8, 0, iconPx + 4)
                                            holder.BackgroundColor3 = Color3.new(0, 0, 0)
                                            holder.BackgroundTransparency = 0.35
                                            holder.BorderSizePixel = 0
                                            holder.ZIndex = iconRow.ZIndex - 1
                                            holder.Parent = entry.icons
                                            if rndEnabled then
                                                Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 4)
                                            end
                                        end

                                        for i, info in ipairs(items) do
                                            if bgEnabled and sepEnabled then
                                                local cell = Instance.new("Frame")
                                                cell.Name = "Cell_" .. i
                                                cell.LayoutOrder = i
                                                cell.Size = UDim2.new(0, iconPx + 4, 0, iconPx + 4)
                                                cell.BackgroundColor3 = Color3.new(0, 0, 0)
                                                cell.BackgroundTransparency = 0.35
                                                cell.BorderSizePixel = 0
                                                cell.Parent = iconRow
                                                if rndEnabled then
                                                    Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 4)
                                                end
                                                local icon = Instance.new("ImageLabel")
                                                icon.Name = "Icon"
                                                icon.AnchorPoint = Vector2.new(0.5, 0.5)
                                                icon.Position = UDim2.new(0.5, 0, 0.5, 0)
                                                icon.Size = UDim2.new(0, iconPx, 0, iconPx)
                                                icon.BackgroundTransparency = 1
                                                icon.BorderSizePixel = 0
                                                icon.Image = info.image or fallback
                                                icon.Parent = cell
                                            else
                                                local icon = Instance.new("ImageLabel")
                                                icon.Name = "Icon_" .. i
                                                icon.LayoutOrder = i
                                                icon.Size = UDim2.new(0, iconPx, 0, iconPx)
                                                icon.BackgroundTransparency = 1
                                                icon.BorderSizePixel = 0
                                                icon.Image = info.image or fallback
                                                icon.Parent = iconRow
                                            end
                                        end
                                    end
                                end

                                applyTextLayout(entry, baseTagH, hasIcons)
                            end

                            local tagBgOn = TagBg and TagBg.Enabled
                            entry.label.BackgroundTransparency = tagBgOn and 0.35 or 1
                            if entry.labelCorner then
                                entry.labelCorner.CornerRadius = UDim.new(0, (TagBgCorner and TagBgCorner.Value == "Square") and 0 or 5)
                            end

                            local tagPos, onScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, hum.HipHeight + 1, 0))
                            entry.board.Visible = onScreen and tagPos.Z > 0
                            if entry.board.Visible then
                                entry.board.Position = UDim2.fromOffset(tagPos.X, tagPos.Y)
                            end
                        end
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("NameTags")
                disconnectCleanup()
                clearAllTags()
                if NameTagGui then
                    NameTagGui:Destroy()
                    NameTagGui = nil
                end
            end
        end
    })

    TeamColor = NameTags.CreateToggle({
        Name = "Team Color",
        Default = true,
        Function = function()end,
    })
    ShowDisplayName = NameTags.CreateToggle({
        Name = "Display Name",
        Default = true,
        Function = function()end,
    })
    ShowDistance = NameTags.CreateToggle({
        Name = "Distance",
        Default = true,
        Function = function()end,
    })
    ShowHealth = NameTags.CreateToggle({
        Name = "Health",
        Default = true,
        Function = function()end,
    })
    ShowBrackets = NameTags.CreateToggle({
        Name = "Brackets",
        Default = true,
        Function = function()end,
    })
    ShowArmorIcons = NameTags.CreateToggle({
        Name = "Armor Icons",
        Default = true,
        Function = function() updateSubVis() end,
    })
    ShowSwordIcons = NameTags.CreateToggle({
        Name = "Sword Icon",
        Default = true,
        Function = function() updateSubVis() end,
    })
    IconBackground = NameTags.CreateToggle({
        Name = "Icon Background",
        Default = true,
        Function = function() updateSubVis() end,
    })
    RoundedCorners = NameTags.CreateToggle({
        Name = "Icon Rounded",
        Default = true,
        Function = function() end,
    })
    SeparateBackground = NameTags.CreateToggle({
        Name = "Separate BG",
        Default = true,
        Function = function() updateSubVis() end,
    })
    IconSpacing = NameTags.CreateSlider({
        Name = "Icon Spacing",
        Min = 1,
        Max = 12,
        Default = 3,
        Round = 1,
        Function = function()end,
    })
    TagSize = NameTags.CreateSlider({
        Name = "Icon Size",
        Min = 110,
        Max = 220,
        Default = 160,
        Round = 1,
        Function = function()end,
    })
    TagBg = NameTags.CreateToggle({
        Name = "Background",
        Default = true,
        Function = function()end,
    })
    TagBgCorner = NameTags.CreateDropdown({
        Name = "Corner Style",
        List = {"Rounded", "Square"},
        Default = "Rounded",
        Function = function()end,
    })
    TagBgCorner:ShowWhen(TagBg)
    TagBg:AddDependent(TagBgCorner)
    FontChoice = NameTags.CreateDropdown({
        Name = "Font",
        List = {"Arial","Montserrat","Nunito","Ubuntu","Roboto","Source Sans","Arimo","Gotham"},
        Default = "Arial",
        Function = function() end
    })
    BoldText = NameTags.CreateToggle({
        Name = "Bold",
        Default = true,
        Function = function()end,
    })
    FontWeight = NameTags.CreateDropdown({
        Name = "Bold Weight",
        List = {"Semibold", "Bold", "Black"},
        Default = "Semibold",
        Function = function()end,
    })
    FontWeight:ShowWhen(BoldText)
    BoldText:AddDependent(FontWeight)
    TextSize = NameTags.CreateSlider({
        Name = "Text Size",
        Min = 7,
        Max = 20,
        Default = 13,
        Round = 1,
        Function = function()end,
    })

    updateSubVis()
end)

local PHANTOM_COLORS = {
    Theme = function() return GuiLibrary.kit:activeColor() end,
    Red = function() return Color3.fromRGB(255,60,60) end,
    Orange = function() return Color3.fromRGB(255,140,0) end,
    Yellow = function() return Color3.fromRGB(255,220,0) end,
    Green = function() return Color3.fromRGB(60,200,80) end,
    Cyan = function() return Color3.fromRGB(0,200,220) end,
    Blue = function() return Color3.fromRGB(50,100,255) end,
    Purple = function() return Color3.fromRGB(160,50,220) end,
    White = function() return Color3.fromRGB(255,255,255) end,
    Pink = function() return Color3.fromRGB(255,100,180) end,
    TeamColor = function() return lplr.Team and lplr.Team.TeamColor.Color or Color3.fromRGB(255,255,255) end,
    Auto = function() return lplr.Team and lplr.Team.TeamColor.Color or Color3.fromRGB(255,255,255) end,
}
local PHANTOM_COL_LIST = {"Auto","Theme","Red","Orange","Yellow","Green","Cyan","Blue","Purple","White","Pink","Team Color"}
local function pcol(dd)
    local k = dd and dd.Value or "Theme"
    local key = k == "Team Color" and "TeamColor" or (k == "Auto" and "Auto" or k)
    return (PHANTOM_COLORS[key] or PHANTOM_COLORS.Theme)()
end

runcode(function()
    local espRef = {}
    local espHLs = {}
    local espHurt = {}
    local espAimLines = {}
    local espCAConns = {}

    local ESPMode, ESPOutC, ESPFillC, ESPOutOp, ESPFillOp
    local ESPThick, ESPHurt, ESPHurtC, ESPHealth, ESPName
    local ESPDist, ESPWalls, ESPLQMode, ESPAimBox, ESPSelf, ESPTeam

    local function w2v(pos)
        local p, vis = Camera:WorldToViewportPoint(pos)
        return Vector2.new(p.X, p.Y), vis, p.Z
    end

    local function getHH(char)
        local h = char:FindFirstChildOfClass("Humanoid")
        return h and (h.HipHeight + 1) or 2.8
    end

    local function bounds2D(hrp, hh)
        local pos = hrp.Position
        local lv = Camera.CFrame.LookVector
        local rS, rVis, rZ = w2v(pos)
        if not rVis or rZ <= 0 then return nil end
        local tS = w2v((CFrame.lookAlong(pos,lv)*CFrame.new( 2,  hh,    0)).Position)
        local bS = w2v((CFrame.lookAlong(pos,lv)*CFrame.new(-2, -hh-1,  0)).Position)
        local sw = math.abs(tS.X - bS.X)
        local sh = math.abs(tS.Y - bS.Y)
        local top = math.min(tS.Y, bS.Y)
        local left= rS.X - sw/2
        return left, top, sw, sh
    end

    local function pts3D(hrp, hh)
        local p = hrp.Position
        return {
            w2v(p+Vector3.new( 1.5, hh, 1.5)),  w2v(p+Vector3.new( 1.5,-hh, 1.5)),
            w2v(p+Vector3.new(-1.5, hh, 1.5)),  w2v(p+Vector3.new(-1.5,-hh, 1.5)),
            w2v(p+Vector3.new( 1.5, hh,-1.5)),  w2v(p+Vector3.new( 1.5,-hh,-1.5)),
            w2v(p+Vector3.new(-1.5, hh,-1.5)),  w2v(p+Vector3.new(-1.5,-hh,-1.5)),
        }
    end

    local function mkLine(c, thick)
        local d = Drawing.new("Line")
        d.Thickness = thick or 1
        d.Color = c
        d.Visible = false
        d.ZIndex = 2
        return d
    end
    local function mkSquare(c, thick, filled)
        local d = Drawing.new("Square")
        d.Thickness = thick or 1
        d.Color = c
        d.Filled = filled or false
        d.Visible = false
        d.ZIndex = 2
        return d
    end
    local function mkText(c, sz)
        local d = Drawing.new("Text")
        d.Color = c
        d.Size = sz or 14
        d.Visible = false
        d.Center = true
        d.Outline = true
        d.OutlineColor = Color3.new(0,0,0)
        d.ZIndex = 3
        d.Font = Drawing.Fonts.UI
        return d
    end

    local function newEntry(mode, c, thick)
        local e = {mode=mode, objs={}}
        if mode == "Highlight" then
        elseif mode == "2D Box" then
            e.box = mkSquare(c, thick)
            e.boxBd = mkSquare(Color3.new(0,0,0), thick+1)
        elseif mode == "Corner Box" then
            for i=1,8 do e.objs[i] = mkLine(c, thick) end
        elseif mode == "3D Box" then
            for i=1,12 do e.objs[i] = mkLine(c, thick) end
        end
        e.hpBG = mkLine(Color3.fromRGB(25,25,25), 4)
        e.hp = mkLine(Color3.fromRGB(85,255,85), 2)
        e.name = mkText(c, 14)
        e.dist = mkText(c, 12)
        return e
    end

    local function destroyEntry(e)
        if not e then return end
        if e.box   then pcall(function() e.box:Remove()   end) end
        if e.boxBd then pcall(function() e.boxBd:Remove() end) end
        for _, d in ipairs(e.objs) do pcall(function() d:Remove() end) end
        for _, k in ipairs({"hpBG","hp","name","dist"}) do
            if e[k] then pcall(function() e[k]:Remove() end) end
        end
    end

    local function hideEntry(e)
        if not e then return end
        if e.box   then e.box.Visible = false end
        if e.boxBd then e.boxBd.Visible = false end
        for _, d in ipairs(e.objs) do d.Visible = false end
        e.hpBG.Visible = false
        e.hp.Visible = false
        e.name.Visible = false
        e.dist.Visible = false
    end

    local function destroyHL(char)
        local h = espHLs[char]; if h and h.Parent then h:Destroy() end; espHLs[char]=nil
    end
    local function removeChar(char)
        destroyEntry(espRef[char])
        espRef[char]=nil
        destroyHL(char)
    end

    local function draw2D(e, left, top, sw, sh, c, thick)
        if not e.box then return end
        e.boxBd.Color = Color3.new(0,0,0)
        e.boxBd.Thickness = thick+1
        e.boxBd.Position = Vector2.new(left-1, top-1)
        e.boxBd.Size = Vector2.new(sw+2, sh+2)
        e.boxBd.Visible = true
        e.box.Color = c
        e.box.Thickness = thick
        e.box.Position = Vector2.new(left, top)
        e.box.Size = Vector2.new(sw, sh)
        e.box.Visible = true
    end

    local function drawCorner(objs, left, top, sw, sh, c, thick)
        local cw, ch = sw*0.25, sh*0.25
        local r, b = left+sw, top+sh
        local segs = {
            {Vector2.new(left,    top),    Vector2.new(left+cw, top)},
            {Vector2.new(left,    top),    Vector2.new(left,    top+ch)},
            {Vector2.new(r-cw,   top),    Vector2.new(r,       top)},
            {Vector2.new(r,       top),    Vector2.new(r,       top+ch)},
            {Vector2.new(left,    b-ch),   Vector2.new(left,    b)},
            {Vector2.new(left,    b),      Vector2.new(left+cw, b)},
            {Vector2.new(r,       b-ch),   Vector2.new(r,       b)},
            {Vector2.new(r-cw,   b),      Vector2.new(r,       b)},
        }
        for i,s in ipairs(segs) do
            objs[i].Color=c
            objs[i].Thickness=thick
            objs[i].From=s[1]
            objs[i].To=s[2]
            objs[i].Visible=true
        end
    end

    local function draw3D(objs, pts, c, thick)
        local edges={{1,2},{3,4},{5,6},{7,8},{1,3},{1,5},{5,7},{7,3},{2,4},{2,6},{6,8},{8,4}}
        for i,e in ipairs(edges) do
            objs[i].Color=c
            objs[i].Thickness=thick
            objs[i].From=pts[e[1]]
            objs[i].To=pts[e[2]]
            objs[i].Visible=true
        end
    end

    local function updateOverlays(e, char, v, c, left, top, sw, sh, showHB, showN, showD)
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hp = hum and hum.Health    or 0
        local maxhp = hum and hum.MaxHealth or 100
        local ratio = math.clamp(hp/math.max(maxhp,1), 0, 1)
        local bx = left - 6

        e.hpBG.Visible = showHB
        e.hp.Visible = showHB and hp > 0
        if showHB then
            e.hpBG.From = Vector2.new(bx, top)
            e.hpBG.To = Vector2.new(bx, top+sh)
            e.hp.Color = Color3.fromHSV(ratio/3, 0.9, 0.85)
            e.hp.From = Vector2.new(bx, top + sh*(1-ratio))
            e.hp.To = Vector2.new(bx, top+sh)
        end

        local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        e.name.Visible = showN
        if showN then
            local nameStr = v.DisplayName ~= "" and v.DisplayName or v.Name
            e.name.Text = nameStr
            e.name.Color = c
            e.name.Position = Vector2.new(left+sw/2, top-16)
        end

        e.dist.Visible = showD
        if showD and myRoot and hrp then
            local d = math.floor((myRoot.Position-hrp.Position).Magnitude)
            e.dist.Text = d.."m"
            e.dist.Color = c
            e.dist.Position = Vector2.new(left+sw/2, top+sh+3)
        end
    end

    local ESP = GuiLibrary.Registry.renderPanel.API.CreateOptionsButton({
        Name = "ESP",
        Function = function(callback)
            if callback then
                local function hookHurt(p)
                    local char = p.Character; if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
                    local prevHp = hum.Health
                    local conn = hum.HealthChanged:Connect(function(hp)
                        if hp < prevHp then espHurt[char] = tick() end
                        prevHp = hp
                    end)
                    funcs:onExit("ESPHT_"..p.UserId, conn)
                end
                local function hookPlayer(p)
                    hookHurt(p)
                    if espCAConns[p] then espCAConns[p]:Disconnect() end
                    espCAConns[p] = p.CharacterAdded:Connect(function()
                        task.wait(0.15)
                        hookHurt(p)
                    end)
                end
                local espPlayers = {}
                for _, p in ipairs(Players:GetPlayers()) do espPlayers[p] = true; hookPlayer(p) end
                local paConn = Players.PlayerAdded:Connect(function(p) espPlayers[p] = true; hookPlayer(p) end)
                local prConn = Players.PlayerRemoving:Connect(function(p) espPlayers[p] = nil end)
                funcs:onExit("ESP_PA", paConn)
                funcs:onExit("ESP_PR", prConn)

                local lqN = 0
                RunLoops:BindToHeartbeat("ESP", function()
                    if _sti then _sti(8) end
                    lqN += 1
                    if ESPLQMode and ESPLQMode.Enabled and lqN%3~=0 then return end

                    local mode = ESPMode   and ESPMode.Value   or "Highlight"
                    local doHL = mode == "Highlight"
                    local outA = ESPOutOp  and ESPOutOp.Value  or 0
                    local fillA = ESPFillOp and ESPFillOp.Value or 0.5
                    local thick = ESPThick  and ESPThick.Value  or 1
                    local useT = ESPTeam   and ESPTeam.Enabled
                    local showHB = ESPHealth and ESPHealth.Enabled
                    local showN = ESPName   and ESPName.Enabled
                    local showD = ESPDist   and ESPDist.Enabled
                    local walls = ESPWalls  and ESPWalls.Enabled
                    local hurtOn = ESPHurt   and ESPHurt.Enabled

                    local seen = {}
                    local bestDot, bestChar = -1, nil

                    for v in pairs(espPlayers) do
                        local isSelf = v == lplr
                        if isSelf and not (ESPSelf and ESPSelf.Enabled) then continue end
                        local char = v.Character; if not char then continue end
                        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health <= 0 then removeChar(char); continue end
                        seen[char] = true

                        local hurt = hurtOn and espHurt[char] and (tick()-espHurt[char] < 0.4)
                        local oc
                        if hurt        then oc = pcol(ESPHurtC)
                        elseif useT and v.Team then oc = v.Team.TeamColor.Color
                        else oc = pcol(ESPOutC) end

                        if doHL then
                            if espRef[char] and espRef[char].mode ~= "Highlight" then
                                destroyEntry(espRef[char])
                                espRef[char]=nil
                            end
                            local h = espHLs[char]
                            if not h then
                                h = Instance.new("Highlight")
                                h.Name="PhantomESP"
                                h.Adornee=char
                                h.DepthMode = walls and Enum.HighlightDepthMode.AlwaysOnTop
                                             or Enum.HighlightDepthMode.Occluded
                                h.Parent=char
                                espHLs[char]=h
                            end
                            h.OutlineColor=oc
                            h.OutlineTransparency=outA
                            h.FillColor=pcol(ESPFillC)
                            h.FillTransparency=fillA
                            local hh = getHH(char)
                            local left, top, sw, sh = bounds2D(hrp, hh)
                            local entry = espRef[char]
                            if not entry then
                                entry = newEntry("Highlight", oc, thick)
                                espRef[char] = entry
                            end
                            if left then
                                updateOverlays(entry, char, v, oc, left, top, sw, sh, showHB, showN, showD)
                            else
                                hideEntry(entry)
                            end
                        else
                            destroyHL(char)
                            local hh = getHH(char)
                            local left, top, sw, sh = bounds2D(hrp, hh)
                            local entry = espRef[char]

                            if not left then
                                if entry then hideEntry(entry) end; continue
                            end

                            if not entry or entry.mode ~= mode then
                                if entry then destroyEntry(entry) end
                                entry = newEntry(mode, oc, thick)
                                espRef[char] = entry
                            end

                            if mode == "2D Box" then
                                draw2D(entry, left, top, sw, sh, oc, thick)
                            elseif mode == "Corner Box" then
                                drawCorner(entry.objs, left, top, sw, sh, oc, thick)
                            elseif mode == "3D Box" then
                                draw3D(entry.objs, pts3D(hrp,hh), oc, thick)
                            end
                            updateOverlays(entry, char, v, oc, left, top, sw, sh, showHB, showN, showD)
                        end

                        if not isSelf and ESPAimBox and ESPAimBox.Enabled then
                            local dv = Camera.CFrame:vectorToObjectSpace(
                                (hrp.Position-Camera.CFrame.Position).Unit)
                            local dot = dv.Z < 0 and -dv.Z or 0
                            if dot > bestDot then bestDot=dot; bestChar=char end
                        end
                    end

                    for char in pairs(espRef) do if not seen[char] then removeChar(char) end end
                    for char in pairs(espHLs)  do if not seen[char] then destroyHL(char)  end end

                    if ESPAimBox and ESPAimBox.Enabled and bestChar then
                        local hrp = bestChar:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local hh = getHH(bestChar)
                            local left, top, sw, sh = bounds2D(hrp, hh)
                            if left then
                                if #espAimLines == 0 then
                                    for i=1,8 do espAimLines[i]=mkLine(Color3.fromRGB(255,60,60),2) end
                                end
                                drawCorner(espAimLines, left, top, sw, sh, Color3.fromRGB(255,60,60), 2)
                            end
                        end
                    else
                        for _, d in ipairs(espAimLines) do d.Visible=false end
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("ESP")
                for char in pairs(espRef) do removeChar(char) end
                for char in pairs(espHLs) do destroyHL(char)  end
                for _, d in ipairs(espAimLines) do pcall(function() d:Remove() end) end
                espAimLines = {}
                for p in pairs(espCAConns) do funcs:offExit("ESPHT_"..p.UserId) end
                for _, c in pairs(espCAConns) do pcall(function() c:Disconnect() end) end
                espCAConns = {}
                funcs:offExit("ESP_PA")
                funcs:offExit("ESP_PR")
                espHurt = {}
            end
        end
    })
    ESPMode = ESP.CreateDropdown({
        Name = "Mode",
        List = {"Highlight", "2D Box", "Corner Box", "3D Box"},
        Default = "Highlight",
        Function = function()end,
    })
    ESPOutC = ESP.CreateDropdown({
        Name = "Outline Color",
        List = PHANTOM_COL_LIST,
        Default = "Theme",
        Function = function()end,
    })
    ESPFillC = ESP.CreateDropdown({
        Name = "Fill Color",
        List = PHANTOM_COL_LIST,
        Default = "Theme",
        Function = function()end,
    })
    ESPOutOp = ESP.CreateSlider({
        Name = "Outline Opacity",
        Min = 0,
        Max = 1,
        Default = 0,
    })
    ESPFillOp = ESP.CreateSlider({
        Name = "Fill Opacity",
        Min = 0,
        Max = 1,
        Default = 0.5,
    })
    ESPThick = ESP.CreateSlider({
        Name = "Line Thickness",
        Min = 1,
        Max = 4,
        Default = 1,
        Round = 1,
    })
    ESPHurt = ESP.CreateToggle({
        Name = "Hurt Indicator",
        Default = true,
        Function = function()end,
    })
    ESPHurtC = ESP.CreateDropdown({
        Name = "Hurt Color",
        List = {"Red", "Orange", "Yellow", "White", "Pink", "Cyan"},
        Default = "Red",
        Function = function()end,
    })
    ESPHealth = ESP.CreateToggle({
        Name = "Health Bar",
        Default = true,
        Function = function()end,
    })
    ESPName = ESP.CreateToggle({
        Name = "Name Label",
        Default = true,
        Function = function()end,
    })
    ESPDist = ESP.CreateToggle({
        Name = "Distance",
        Default = false,
        Function = function()end,
    })
    ESPWalls = ESP.CreateToggle({
        Name = "Through Walls",
        Default = true,
        Function = function()end,
    })
    ESPLQMode = ESP.CreateToggle({
        Name = "LQ Mode",
        Default = false,
        Function = function()end,
    })
    ESPAimBox = ESP.CreateToggle({
        Name = "AimAssist Box",
        Default = false,
        Function = function()end,
    })
    ESPSelf = ESP.CreateToggle({
        Name = "Self Render",
        Default = false,
        Function = function()end,
    })
    ESPTeam = ESP.CreateToggle({
        Name = "Team Color",
        Default = false,
        Function = function()end,
    })
    ESPMode:ShowWhen("2D Box",     ESPThick)
    ESPMode:ShowWhen("Corner Box", ESPThick)
    ESPMode:ShowWhen("3D Box",     ESPThick)
    ESPMode:ShowWhen("Highlight",  ESPFillC)
    ESPMode:ShowWhen("2D Box",     ESPFillC)
    ESPMode:ShowWhen("Highlight",  ESPFillOp)
    ESPMode:ShowWhen("2D Box",     ESPFillOp)
    ESPMode:ShowWhen("Highlight",  ESPHealth)
    ESPMode:ShowWhen("2D Box",     ESPHealth)
    ESPMode:ShowWhen("Corner Box", ESPHealth)
    ESPMode:ShowWhen("3D Box",     ESPHealth)
    ESPMode:ShowWhen("Highlight",  ESPName)
    ESPMode:ShowWhen("2D Box",     ESPName)
    ESPMode:ShowWhen("Corner Box", ESPName)
    ESPMode:ShowWhen("3D Box",     ESPName)
    ESPMode:ShowWhen("Highlight",  ESPDist)
    ESPMode:ShowWhen("2D Box",     ESPDist)
    ESPMode:ShowWhen("Corner Box", ESPDist)
    ESPMode:ShowWhen("3D Box",     ESPDist)
    ESPHurtC:ShowWhen(ESPHurt)
    ESPHurt:AddDependent(ESPHurtC)
end)


runcode(function()
    local fpConn = nil
    local FirstPerson = {}
    local resetChar = function()
        local char = lplr.Character
        if not char then return end
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.LocalTransparencyModifier = 0
            end
        end
    end

    FirstPerson = GuiLibrary.Registry.renderPanel.API.CreateOptionsButton({
        Name = "FirstPerson",
        Function = function(callback)
            if callback then
                bedfight.modules.PlayerConfig.InFirstPerson.Value = true
                RunService:BindToRenderStep("ForceFP", Enum.RenderPriority.Last.Value + 200, resetCharTransparency)
                fpConn = bedfight.modules.PlayerConfig.InFirstPerson.Changed:Connect(function(val)
                    if not val then
                        task.defer(function()
                            bedfight.modules.PlayerConfig.InFirstPerson.Value = true
                        end)
                    end
                end)
            else
                RunService:UnbindFromRenderStep("ForceFP")
                if fpConn then fpConn:Disconnect(); fpConn = nil end
                bedfight.modules.PlayerConfig.InFirstPerson.Value = false
                resetChar()
            end
        end
    })
end)

runcode(function()
    local ThemeDropdown = {}
    local GameThemes = {}
    local LIGHT_TAG = "NightTheme_Light"
    local LIGHT_HOLDER_FOLDER = "NightTheme_LightHolders"
    local nightConnections = {}
    local timeCycleConn = nil
    local audioState = {folder=nil,rainInside=nil,rainOutside=nil,thunderLoop=nil,thunderToken=0,roofHeartbeat=nil,flashToken=0,flashGui=nil,flashFrame=nil}

    local cleanupSnow = function()
        local e = workspace:FindFirstChild("Snowfall_Client"); if e then e:Destroy() end
    end
    local cleanupNight = function()
        if timeCycleConn then timeCycleConn:Disconnect(); timeCycleConn = nil end
        for _, c in ipairs(nightConnections) do c:Disconnect() end
        nightConnections = {}
        local hf = workspace:FindFirstChild(LIGHT_HOLDER_FOLDER); if hf then hf:Destroy() end
        for _, d in ipairs(workspace:GetDescendants()) do
            local l1 = d:FindFirstChild(LIGHT_TAG.."_Spot"); if l1 then l1:Destroy() end
            local l2 = d:FindFirstChild(LIGHT_TAG.."_Point"); if l2 then l2:Destroy() end
        end
    end
    local cleanupAudio = function()
        audioState.thunderToken += 1
        audioState.flashToken += 1
        if audioState.roofHeartbeat then audioState.roofHeartbeat:Disconnect(); audioState.roofHeartbeat = nil end
        if audioState.flashGui then audioState.flashGui:Destroy() end
        if audioState.folder then audioState.folder:Destroy() end
        audioState.folder=nil
        audioState.rainInside=nil
        audioState.rainOutside=nil
        audioState.thunderLoop=nil
        audioState.flashGui=nil
        audioState.flashFrame=nil
    end
    local cleanupAll = function() cleanupSnow(); cleanupNight(); cleanupAudio() end

    local applyLighting = function(code) loadstring(code)() end

    local tweenVolume = function(sound, target, step)
        if not sound then return end
        sound.Volume = sound.Volume + (target - sound.Volume) * math.clamp(step, 0, 1)
        if math.abs(sound.Volume - target) < 0.003 then sound.Volume = target end
    end

    local ROOF_OFFSETS = {Vector3.new(0,0,0),Vector3.new(7,0,0),Vector3.new(-7,0,0),Vector3.new(0,0,7),Vector3.new(0,0,-9),Vector3.new(9,0,9),Vector3.new(-9,0,9),Vector3.new(9,0,-9),Vector3.new(-9,0,-9)}
    local getRoofAudioBlend = function(hrp, rayParams)
        if not hrp then return 0, false end
        local offsets = ROOF_OFFSETS
        local coveredWeight, totalWeight, centerCovered = 0, 0, false
        for idx, offset in ipairs(offsets) do
            local result = workspace:Raycast(hrp.Position + offset, Vector3.new(0,80,0), rayParams)
            local weight = idx == 1 and 2.35 or 1
            totalWeight += weight
            if result then
                local strength = 0.45 + (1 - math.clamp((result.Position.Y - hrp.Position.Y - 6) / 22, 0, 1)) * 0.55
                coveredWeight += weight * strength
                if idx == 1 then centerCovered = true end
            end
        end
        local blend = totalWeight > 0 and math.clamp(coveredWeight / totalWeight, 0, 1) or 0
        if blend > 0 and blend < 1 then blend = math.clamp(blend * 0.82 + 0.09, 0, 1) end
        return blend, centerCovered
    end

    local ensureLightningFlash = function()
        if audioState.flashGui and audioState.flashFrame and audioState.flashGui.Parent then return audioState.flashFrame end
        local pgui = lplr:FindFirstChildOfClass("PlayerGui"); if not pgui then return nil end
        local gui = Instance.new("ScreenGui")
        gui.Name="WeatherLightningFlash"
        gui.IgnoreGuiInset=true
        gui.ResetOnSpawn=false
        gui.DisplayOrder=999999
        gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        gui.Parent=pgui
        local frame = Instance.new("Frame")
        frame.Name="Flash"
        frame.BackgroundColor3=Color3.new(1,1,1)
        frame.BorderSizePixel=0
        frame.Size=UDim2.fromScale(1,1)
        frame.Position=UDim2.fromScale(0,0)
        frame.BackgroundTransparency=1
        frame.Parent=gui
        audioState.flashGui=gui
        audioState.flashFrame=frame
        return frame
    end

    local playLightningFlash = function(power)
        local frame = ensureLightningFlash()
        audioState.flashToken += 1
        local token = audioState.flashToken
        power = math.clamp(power or 0.5, 0.08, 1)
        local char = lplr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local lightPart, worldLight
        if hrp then
            lightPart = Instance.new("Part")
            lightPart.Name="LightningFlashHolder"
            lightPart.Anchored=true
            lightPart.CanCollide=false
            lightPart.CanQuery=false
            lightPart.CanTouch=false
            lightPart.Transparency=1
            lightPart.Size=Vector3.new(1,1,1)
            lightPart.CFrame=hrp.CFrame
            lightPart.Parent=workspace
            worldLight = Instance.new("PointLight")
            worldLight.Name="LightningFlashLight"
            worldLight.Color=Color3.fromRGB(220,235,255)
            worldLight.Brightness=0
            worldLight.Range=0
            worldLight.Shadows=true
            worldLight.Parent=lightPart
        end
        task.spawn(function()
            local steps = {{1-(power*0.34),1.7*power,40+(26*power),0.025},{1-(power*0.16),0.8*power,30+(18*power),0.035},{1-(power*0.48),2.5*power,52+(34*power),0.030},{1-(power*0.10),0.55*power,24+(14*power),0.060},{1,0,0,0.080}}
            for _, s in ipairs(steps) do
                if audioState.flashToken ~= token then break end
                local chr = lplr.Character
                local h = chr and chr:FindFirstChild("HumanoidRootPart")
                if lightPart and lightPart.Parent and h then lightPart.CFrame = h.CFrame end
                if frame and frame.Parent then frame.BackgroundTransparency = s[1] end
                if worldLight and worldLight.Parent then worldLight.Brightness=s[2]; worldLight.Range=s[3] end
                task.wait(s[4])
            end
            if frame and frame.Parent and audioState.flashToken == token then frame.BackgroundTransparency = 1 end
            if lightPart then lightPart:Destroy() end
        end)
    end

    local ensureGameAudio = function()
        cleanupAudio()
        local gameAudio = Instance.new("Folder")
        gameAudio.Name="GameAudio"
        gameAudio.Parent=workspace
        local thunderSounds = Instance.new("Folder")
        thunderSounds.Name="ThunderSounds"
        thunderSounds.Parent=gameAudio
        local closeFolder = Instance.new("Folder")
        closeFolder.Name="Close"
        closeFolder.Parent=thunderSounds
        local farFolder = Instance.new("Folder")
        farFolder.Name="Far"
        farFolder.Parent=thunderSounds
        local brewingFolder = Instance.new("Folder")
        brewingFolder.Name="Brewing"
        brewingFolder.Parent=thunderSounds
        local rainFolder = Instance.new("Folder")
        rainFolder.Name="Rain"
        rainFolder.Parent=gameAudio
        local makeSound = function(p,n,id,vol,looped,spd) local s=Instance.new("Sound"); s.Name=n; s.SoundId=id; s.Volume=vol; s.Looped=looped or false; s.RollOffMode=Enum.RollOffMode.Inverse; s.RollOffMinDistance=35; s.RollOffMaxDistance=100000; s.EmitterSize=80; s.PlaybackSpeed=spd or 1; s.Parent=p; return s end
        local makeMuffler = function(s) local eq=Instance.new("EqualizerSoundEffect"); eq.Name="AudioMuffler"; eq.Enabled=true; eq.HighGain=0; eq.MidGain=0; eq.LowGain=0; eq.Parent=s; return eq end
        local makeLayer = function(p,n,id,vol,spd) local s=makeSound(p,n,id,0,true,spd); s:SetAttribute("OriginalVolume",vol); return s end
        local t1=makeSound(closeFolder,"Thunder1","rbxassetid://131300621",1.15,false,1)
        makeMuffler(t1)
        local t2=makeSound(closeFolder,"Thunder2","rbxassetid://5246104843",1.1,false,1)
        makeMuffler(t2)
        local t3=makeSound(closeFolder,"Thunder3","rbxassetid://6734470366",1.2,false,0.8)
        makeMuffler(t3)
        local r1=makeSound(farFolder,"Rumble1","rbxassetid://7742650861",0.9,false,1)
        makeMuffler(r1)
        local r2=makeSound(farFolder,"Rumble2","rbxassetid://4961240438",0.82,false,1)
        makeMuffler(r2)
        local r3=makeSound(farFolder,"Rumble3","rbxassetid://9120016241",0.82,false,1)
        makeMuffler(r3)
        local b1=makeSound(brewingFolder,"Rumble1","rbxassetid://4961240438",0.55,false,0.7)
        makeMuffler(b1)
        local b2=makeSound(brewingFolder,"Rumble2","rbxassetid://83308742405412",0.9,false,1)
        makeMuffler(b2)
        local hri=makeLayer(rainFolder,"HeavyRainInside","rbxassetid://97388832021513",0.42,1)
        local hro=makeLayer(rainFolder,"HeavyRainOutside","rbxassetid://9120551859",0.16,1)
        local lri=makeLayer(rainFolder,"LightRainInside","c",0.24,1.05)
        local lro=makeLayer(rainFolder,"LightRainOutside","rbxassetid://9120551859",0.10,1.08)
        local bw=makeLayer(rainFolder,"BlizzardWind","rbxassetid://4175285709",0.22,0.72)
        audioState.folder=gameAudio
        audioState.soundSets={
            LightRain={inside=lri,outside=lro,insideTarget=0.24,outsideTarget=0.10,thunderChance=0.62,minDelay=10,maxDelay=20},
            HeavyRain={inside=hri,outside=hro,insideTarget=0.42,outsideTarget=0.16,thunderChance=0.82,minDelay=6,maxDelay=14},
            Blizzard={inside=nil,outside=bw,insideTarget=0,outsideTarget=0.22,thunderChance=0,minDelay=999,maxDelay=999},
        }
        return gameAudio
    end

    local setMuffled = function(sound, muffled)
        if not sound then return end
        local eq = sound:FindFirstChild("AudioMuffler"); if not eq then return end
        if muffled then eq.LowGain=-2; eq.MidGain=-6; eq.HighGain=-18
        else eq.LowGain=0; eq.MidGain=0; eq.HighGain=0 end
    end

    local startWeatherAudio = function(mode)
        ensureGameAudio()
        local cfg = audioState.soundSets and audioState.soundSets[mode]; if not cfg then return end
        audioState.rainInside=cfg.inside
        audioState.rainOutside=cfg.outside
        for _, s in ipairs({cfg.inside, cfg.outside}) do
            if s then s.Volume=0; s.TimePosition=0; if s.IsPlaying then s:Stop() end; s:Play() end
        end
        local rayParams = RaycastParams.new()
        rayParams.FilterType=Enum.RaycastFilterType.Exclude
        audioState.roofHeartbeat = RunService.Heartbeat:Connect(function(dt)
            local char=lplr.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                if cfg.inside then tweenVolume(cfg.inside,0,0.12) end
                if cfg.outside then tweenVolume(cfg.outside,0,0.12) end; return
            end
            rayParams.FilterDescendantsInstances={char,audioState.folder}
            local blend, centerCovered = getRoofAudioBlend(hrp, rayParams)
            local outsideBlend = 1 - blend
            local insideTarget = cfg.insideTarget * (centerCovered and math.max(blend,0.7) or blend)
            local outsideTarget = centerCovered and cfg.outsideTarget*(0.08+outsideBlend*0.55) or cfg.outsideTarget*math.clamp(0.42+outsideBlend*0.58,0,1)
            local step = math.clamp((dt or 0.016)*5.6,0.05,0.16)
            if cfg.inside then tweenVolume(cfg.inside,insideTarget,step) end
            if cfg.outside then tweenVolume(cfg.outside,outsideTarget,step) end
        end)
        if cfg.thunderChance > 0 then
            local token = audioState.thunderToken + 1
            audioState.thunderToken = token
            task.spawn(function()
                while audioState.thunderToken == token do
                    task.wait(math.random(cfg.minDelay*100, cfg.maxDelay*100)/100)
                    if audioState.thunderToken ~= token then break end
                    if math.random() > cfg.thunderChance then continue end
                    local tSounds=audioState.folder and audioState.folder:FindFirstChild("ThunderSounds")
                    local cf=tSounds and tSounds:FindFirstChild("Close")
                    local ff=tSounds and tSounds:FindFirstChild("Far")
                    local bf=tSounds and tSounds:FindFirstChild("Brewing")
                    local char=lplr.Character
                    local hrp=char and char:FindFirstChild("HumanoidRootPart")
                    local insideBlend,underRoof=0,false
                    if hrp then local tr=RaycastParams.new(); tr.FilterType=Enum.RaycastFilterType.Exclude; tr.FilterDescendantsInstances={char,audioState.folder}; insideBlend,underRoof=getRoofAudioBlend(hrp,tr) end
                    local forcedClose=false
                    if bf and math.random()<0.55 then
                        local brewing=bf:GetChildren()
                        if #brewing>0 then
                            local brew=brewing[math.random(1,#brewing)]
                            setMuffled(brew,underRoof or insideBlend>0.45)
                            brew.TimePosition=0
                            brew:Play()
                            if math.random()<0.35 then task.wait(math.random(20,55)/100); if audioState.thunderToken~=token then break end; playLightningFlash(0.14) end
                            task.wait(math.random(140,320)/100); if audioState.thunderToken~=token then break end; forcedClose=true
                        end
                    else task.wait(math.random(10,45)/100); if audioState.thunderToken~=token then break end end
                    local useClose=forcedClose or (math.random()<(mode=="HeavyRain" and 0.45 or 0.20))
                    local src=useClose and cf or ff
                    if src then
                        local list=src:GetChildren()
                        if #list>0 then
                            local snd=list[math.random(1,#list)]
                            setMuffled(snd,underRoof or insideBlend>0.45)
                            snd.TimePosition=0
                            playLightningFlash(useClose and math.random(75,100)/100 or math.random(28,50)/100)
                            snd:Play()
                        end
                    end
                end
            end)
        end
    end

    local isCharacterPart = function(part) local m=part:FindFirstAncestorOfClass("Model"); return m and m:FindFirstChildOfClass("Humanoid") end
    local getLightHolderFolder = function() local f=workspace:FindFirstChild(LIGHT_HOLDER_FOLDER); if not f then f=Instance.new("Folder"); f.Name=LIGHT_HOLDER_FOLDER; f.Parent=workspace end; return f end
    local addSpotLight = function(part)
        if not part:IsA("BasePart") or not isCharacterPart(part) then return end
        local hf=getLightHolderFolder(); local hn=LIGHT_TAG.."_Holder_"..tostring(part:GetDebugId()); if hf:FindFirstChild(hn) then return end
        local holder=Instance.new("Part")
        holder.Name=hn
        holder.Anchored=true
        holder.CanCollide=false
        holder.CanQuery=false
        holder.CanTouch=false
        holder.Transparency=1
        holder.Size=Vector3.new(0.2,0.2,0.2)
        holder.CFrame=part.CFrame
        holder.Parent=hf
        local sl=Instance.new("SpotLight")
        sl.Name=LIGHT_TAG.."_Spot"
        sl.Brightness=0.1
        sl.Range=35
        sl.Angle=55
        sl.Color=Color3.fromRGB(255,180,89)
        sl.Shadows=true
        sl.Face=Enum.NormalId.Front
        sl.Parent=holder
        table.insert(nightConnections, RunService.Heartbeat:Connect(function() if not holder.Parent then return end; if not part.Parent then holder:Destroy(); return end; holder.CFrame=part.CFrame end))
    end
    local addPointLight = function(part)
        if not part:IsA("BasePart") or part:FindFirstChild(LIGHT_TAG.."_Point") or isCharacterPart(part) or part.Size.Magnitude<6 then return end
        local pl=Instance.new("PointLight")
        pl.Name=LIGHT_TAG.."_Point"
        pl.Brightness=0.2
        pl.Range=12
        pl.Color=Color3.fromRGB(254,243,187)
        pl.Parent=part
    end
    local lightFolders = function()
        for _,child in ipairs(workspace:GetChildren()) do if child:IsA("Folder") then for _,d in ipairs(child:GetDescendants()) do addSpotLight(d); addPointLight(d) end end end
        for _,p in ipairs(Players:GetPlayers()) do local char=p.Character; if char then for _,part in ipairs(char:GetDescendants()) do addSpotLight(part) end end end
    end

    local buildRainScene = function(lplr, cam, folder, rainRate, dropletRate, mistRate, mistTransMin, mistTransMax)
        local conns = {}
        local makeWeatherPart = function(name, size, offset)
            local p=Instance.new("Part",folder)
            p.Name=name
            p.Anchored=true
            p.CanCollide=false
            p.Transparency=1
            p.Color=Color3.fromRGB(255,0,0)
            p.Size=size
            p.CFrame=CFrame.new(0,0,0)
            local rain=Instance.new("ParticleEmitter",p)
            rain.Name="Rain"
            rain.Texture="rbxassetid://1822883048"
            rain.Rate=rainRate
            rain.Lifetime=NumberRange.new(3,3)
            rain.Speed=NumberRange.new(100,100)
            rain.Drag=0
            rain.Rotation=NumberRange.new(0,0)
            rain.RotSpeed=NumberRange.new(0,0)
            rain.VelocitySpread=2
            rain.SpreadAngle=Vector2.new(2,2)
            rain.LightInfluence=0.38
            rain.LightEmission=0.5
            rain.ZOffset=0
            rain.Acceleration=Vector3.new(0,0,0)
            rain.EmissionDirection=Enum.NormalId.Bottom
            rain.Orientation=Enum.ParticleOrientation.FacingCameraWorldUp
            rain.Shape=Enum.ParticleEmitterShape.Box
            rain.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
            rain.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
            rain.Enabled=true
            rain.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0.760784,0.823529,1)),ColorSequenceKeypoint.new(1,Color3.new(0.760784,0.823529,1))})
            rain.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,11),NumberSequenceKeypoint.new(1,11)})
            rain.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(0.367,0.894),NumberSequenceKeypoint.new(0.395,1),NumberSequenceKeypoint.new(1,1)})
            table.insert(conns, RunService.Heartbeat:Connect(function() p.CFrame=cam.CFrame*CFrame.new(offset) end))
            p.AncestryChanged:Connect(function() if not p.Parent then for _,c in ipairs(conns) do c:Disconnect() end end end)
            return p, rain
        end
        local droplets=Instance.new("Part",folder)
        droplets.Name="Droplets"
        droplets.Anchored=true
        droplets.CanCollide=false
        droplets.Transparency=1
        droplets.Size=Vector3.new(50,1,50)
        droplets.CFrame=CFrame.new(0,0,0)
        local de=Instance.new("ParticleEmitter",droplets)
        de.Name="Emitter"
        de.Texture="rbxassetid://241576804"
        de.Rate=dropletRate
        de.Lifetime=NumberRange.new(0.5,0.5)
        de.Speed=NumberRange.new(3,3)
        de.Drag=0
        de.Rotation=NumberRange.new(-20,-20)
        de.RotSpeed=NumberRange.new(0,0)
        de.VelocitySpread=0
        de.SpreadAngle=Vector2.new(0,0)
        de.LightInfluence=0
        de.LightEmission=0.5
        de.ZOffset=0
        de.Acceleration=Vector3.new(0,-30,0)
        de.EmissionDirection=Enum.NormalId.Top
        de.Orientation=Enum.ParticleOrientation.FacingCamera
        de.Shape=Enum.ParticleEmitterShape.Box
        de.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
        de.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
        de.Enabled=false
        de.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))})
        de.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1.0625)})
        de.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.1,0),NumberSequenceKeypoint.new(0.55,0.75),NumberSequenceKeypoint.new(1,1)})
        local mistPart=Instance.new("Part",folder)
        mistPart.Name="MistPart"
        mistPart.Anchored=true
        mistPart.CanCollide=false
        mistPart.Transparency=1
        mistPart.Size=Vector3.new(100,1,100)
        mistPart.CFrame=CFrame.new(0,0,0)
        local mist=Instance.new("ParticleEmitter",mistPart)
        mist.Name="Mist"
        mist.Texture="rbxassetid://135522315481814"
        mist.Rate=mistRate
        mist.Lifetime=NumberRange.new(6,10)
        mist.Speed=NumberRange.new(1,4)
        mist.Drag=0.8
        mist.Rotation=NumberRange.new(0,360)
        mist.RotSpeed=NumberRange.new(-10,10)
        mist.VelocitySpread=360
        mist.SpreadAngle=Vector2.new(20,20)
        mist.LightInfluence=1
        mist.LightEmission=0
        mist.ZOffset=0
        mist.Acceleration=Vector3.new(-0.1,0,0)
        mist.EmissionDirection=Enum.NormalId.Top
        mist.Orientation=Enum.ParticleOrientation.FacingCamera
        mist.Shape=Enum.ParticleEmitterShape.Box
        mist.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
        mist.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
        mist.Enabled=true
        mist.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0.78,0.81,0.85)),ColorSequenceKeypoint.new(1,Color3.new(0.78,0.81,0.85))})
        mist.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,4),NumberSequenceKeypoint.new(0.4,8),NumberSequenceKeypoint.new(1,3)})
        mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.1,mistTransMin),NumberSequenceKeypoint.new(0.9,mistTransMax),NumberSequenceKeypoint.new(1,1)})
        local _,r1=makeWeatherPart("PrimaryWeatherPart",Vector3.new(100,1,100),Vector3.new(0,37,0))
        local _,r2=makeWeatherPart("WeatherPart",Vector3.new(100,1,100),Vector3.new(0,-10,0))
        local _,r3=makeWeatherPart("WeatherPart",Vector3.new(100,1,100),Vector3.new(30,5,-30))
        local _,r4=makeWeatherPart("WeatherPart",Vector3.new(100,1,100),Vector3.new(-30,5,30))
        local rainEmitters={r1,r2,r3,r4}
        local edgeFolder=Instance.new("Folder",folder)
        edgeFolder.Name="EdgeRain"
        local edgeOffsets={Vector3.new(8,0,0),Vector3.new(-8,0,0),Vector3.new(0,0,8),Vector3.new(0,0,-8),Vector3.new(6,0,6),Vector3.new(-6,0,6),Vector3.new(6,0,-6),Vector3.new(-6,0,-6)}
        local edgeEmitters={}
        for _,offset in ipairs(edgeOffsets) do
            local ep=Instance.new("Part",edgeFolder)
            ep.Name="EdgePart"
            ep.Anchored=true
            ep.CanCollide=false
            ep.Transparency=1
            ep.Size=Vector3.new(6,1,6)
            ep.CFrame=CFrame.new(0,0,0)
            local ee=Instance.new("ParticleEmitter",ep)
            ee.Name="EdgeRain"
            ee.Texture="rbxassetid://1822883048"
            ee.Rate=rainRate*0.35
            ee.Lifetime=NumberRange.new(2,3)
            ee.Speed=NumberRange.new(80,100)
            ee.Drag=0
            ee.Rotation=NumberRange.new(0,0)
            ee.RotSpeed=NumberRange.new(0,0)
            ee.VelocitySpread=3
            ee.SpreadAngle=Vector2.new(3,3)
            ee.LightInfluence=0.38
            ee.LightEmission=0.5
            ee.ZOffset=0
            ee.Acceleration=Vector3.new(0,0,0)
            ee.EmissionDirection=Enum.NormalId.Bottom
            ee.Orientation=Enum.ParticleOrientation.FacingCameraWorldUp
            ee.Shape=Enum.ParticleEmitterShape.Box
            ee.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
            ee.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
            ee.Enabled=false
            ee.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(0.760784,0.823529,1)),ColorSequenceKeypoint.new(1,Color3.new(0.760784,0.823529,1))})
            ee.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,8),NumberSequenceKeypoint.new(1,8)})
            ee.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(0.367,0.894),NumberSequenceKeypoint.new(0.395,1),NumberSequenceKeypoint.new(1,1)})
            table.insert(edgeEmitters,{part=ep,emitter=ee,offset=offset})
        end
        local rayParams=RaycastParams.new()
        rayParams.FilterType=Enum.RaycastFilterType.Exclude
        table.insert(conns, RunService.Heartbeat:Connect(function()
            local char=lplr.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then de.Enabled=false; mist.Enabled=false; for _,e in ipairs(rainEmitters) do e.Enabled=true end; for _,d in ipairs(edgeEmitters) do d.emitter.Enabled=false end; return end
            rayParams.FilterDescendantsInstances={char,folder,audioState.folder}
            local roofResult=workspace:Raycast(hrp.Position,Vector3.new(0,80,0),rayParams)
            local underRoof=roofResult~=nil
            for _,e in ipairs(rainEmitters) do e.Enabled=not underRoof end
            de.Enabled=false
            mist.Enabled=false
            if underRoof then
                for _,d in ipairs(edgeEmitters) do
                    local ewp=hrp.Position+d.offset
                    d.emitter.Enabled=(workspace:Raycast(ewp,Vector3.new(0,80,0),rayParams)==nil)
                    d.part.CFrame=CFrame.new(ewp.X,hrp.Position.Y+18,ewp.Z)
                end
            else
                for _,d in ipairs(edgeEmitters) do d.emitter.Enabled=false end
                local floorResult=workspace:Raycast(hrp.Position+Vector3.new(0,5,0),Vector3.new(0,-60,0),rayParams)
                if floorResult and floorResult.Normal.Y>0.7 and floorResult.Position.Y<=hrp.Position.Y then
                    droplets.CFrame=CFrame.new(hrp.Position.X,floorResult.Position.Y,hrp.Position.Z)
                    mistPart.CFrame=CFrame.new(hrp.Position.X,floorResult.Position.Y+1,hrp.Position.Z)
                    de.Enabled=true
                    mist.Enabled=true
                end
            end
        end))
    end

    local makeSnowPart = function(name, rate, lifetime, speed, sizeKF, transKF, accel, folder, trackCam)
        local part=Instance.new("Part",folder)
        part.Name=name
        part.Anchored=true
        part.CanCollide=false
        part.Transparency=1
        local e=Instance.new("ParticleEmitter",part)
        e.Name="Particle"
        e.Texture="rbxassetid://127302768524882"
        e.Rate=rate
        e.Lifetime=lifetime
        e.Speed=speed
        e.Drag=0
        e.VelocitySpread=trackCam and 5 or 18
        e.SpreadAngle=trackCam and Vector2.new(5,5) or Vector2.new(12,12)
        e.LightInfluence=1
        e.LightEmission=0
        e.ZOffset=0
        e.Acceleration=accel
        e.EmissionDirection=Enum.NormalId.Front
        e.Orientation=Enum.ParticleOrientation.FacingCamera
        e.Shape=Enum.ParticleEmitterShape.Box
        e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
        e.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
        e.Enabled=true
        e.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))})
        e.Size=NumberSequence.new(sizeKF)
        e.Transparency=NumberSequence.new(transKF)
        if trackCam then
            part.Size=Vector3.new(100,80,1)
            local conn=RunService.Heartbeat:Connect(function() local hrp=lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart"); if hrp then part.CFrame=CFrame.new(hrp.Position+Vector3.new(0,0,50)) end end)
            part.AncestryChanged:Connect(function() if not part.Parent then conn:Disconnect() end end)
        else
            part.Size=Vector3.new(90,55,1)
            local OFFSET_Z,OFFSET_Y,zSign=10,5,1
            local conn=RunService.Heartbeat:Connect(function()
                local hrp=lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                local flatLook=Vector3.new(hrp.CFrame.LookVector.X,0,hrp.CFrame.LookVector.Z).Unit
                local toPart=Vector3.new(part.Position.X-hrp.Position.X,0,part.Position.Z-hrp.Position.Z)
                if toPart.Magnitude>0.01 and flatLook:Dot(toPart/toPart.Magnitude)<-0.85 then zSign=-zSign end
                part.CFrame=CFrame.lookAt(hrp.Position+Vector3.new(0,OFFSET_Y,OFFSET_Z*zSign),hrp.Position)
            end)
            part.AncestryChanged:Connect(function() if not part.Parent then conn:Disconnect() end end)
        end
        return part, e
    end

    local setupNightLights = function()
        lightFolders()
        table.insert(nightConnections,workspace.DescendantAdded:Connect(function(d) task.defer(function() addSpotLight(d); addPointLight(d) end) end))
        local watchChar = function(p) table.insert(nightConnections,p.CharacterAdded:Connect(function(char) task.defer(function() for _,part in ipairs(char:GetDescendants()) do addSpotLight(part) end end) end)) end
        for _,p in ipairs(Players:GetPlayers()) do watchChar(p) end
        table.insert(nightConnections,Players.PlayerAdded:Connect(watchChar))
        local last=0; table.insert(nightConnections,RunService.Heartbeat:Connect(function() if tick()-last<5 then return end; last=tick(); lightFolders() end))
    end

    local themes = {
        Default = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0.576471,0.67451,0.784314);L.Brightness=3;L.ColorShift_Bottom=Color3.new(0.294118,0.235294,0.192157);L.ColorShift_Top=Color3.new(0,0,0);L.OutdoorAmbient=Color3.new(0.576471,0.67451,0.784314);L.FogColor=Color3.new(0.752941,0.752941,0.752941);L.FogEnd=100000;L.FogStart=0;L.GlobalShadows=true;L.GeographicLatitude=45;L.ExposureCompensation=0;L.EnvironmentDiffuseScale=1;L.EnvironmentSpecularScale=1;L.ClockTime=14.5;L.TimeOfDay='14:30:00';L.ShadowSoftness=0.1;L.Technology=Enum.Technology.ShadowMap;local blo=Instance.new('BloomEffect',L);blo.Name='Bloom';blo.Enabled=true;blo.Intensity=1;blo.Size=10;blo.Threshold=2;local col=Instance.new('ColorCorrectionEffect',L);col.Name='DeathBarrierEffect';col.Enabled=false;col.Brightness=0;col.Contrast=0;col.Saturation=0;col.TintColor=Color3.new(0.858824,0.627451,1);local col2=Instance.new('ColorCorrectionEffect',L);col2.Name='ColorCorrection';col2.Enabled=true;col2.Brightness=0;col2.Contrast=0.05;col2.Saturation=0.05;col2.TintColor=Color3.new(1,1,1);local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=true;sky.SunAngularSize=21;sky.MoonAngularSize=11;sky.SkyboxBk='rbxassetid://93968881652239';sky.SkyboxDn='rbxassetid://102254730940508';sky.SkyboxFt='rbxassetid://93968881652239';sky.SkyboxLf='rbxassetid://93968881652239';sky.SkyboxRt='rbxassetid://93968881652239';sky.SkyboxUp='rbxassetid://112261788034018';sky.StarCount=3000;sky.SunTextureId='';sky.MoonTextureId='';local col3=Instance.new('ColorCorrectionEffect',L);col3.Name='SmokeColorCorrection';col3.Enabled=false;col3.Brightness=0;col3.Contrast=0;col3.Saturation=-0.5;col3.TintColor=Color3.new(0.588235,0.588235,0.588235)]])
        end,
        Morning = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0,0,0);L.Brightness=3;L.ColorShift_Bottom=Color3.new(1,1,1);L.ColorShift_Top=Color3.new(0.972549,0.537255,0.152941);L.OutdoorAmbient=Color3.new(0,0,0);L.FogColor=Color3.new(0.752941,0.752941,0.752941);L.FogEnd=100000;L.FogStart=0;L.GlobalShadows=true;L.GeographicLatitude=40;L.ExposureCompensation=0.7;L.EnvironmentDiffuseScale=1;L.EnvironmentSpecularScale=1;L.ClockTime=7;L.TimeOfDay='07:00:00';L.ShadowSoftness=0.03;L.Technology=Enum.Technology.Future;local sky=Instance.new('Sky',L);sky.Name='60';sky.CelestialBodiesShown=true;sky.SunAngularSize=5;sky.MoonAngularSize=1.5;sky.SkyboxBk='rbxassetid://6973550206';sky.SkyboxDn='rbxassetid://6973550815';sky.SkyboxFt='rbxassetid://6973549125';sky.SkyboxLf='rbxassetid://6973549670';sky.SkyboxRt='rbxassetid://9089057892';sky.SkyboxUp='rbxassetid://6973551204';sky.StarCount=5000;sky.SunTextureId='rbxassetid://1084351190';sky.MoonTextureId='rbxassetid://1075087760';local atm=Instance.new('Atmosphere',L);atm.Name='Atmosphere';atm.Density=0.325;atm.Offset=1;atm.Color=Color3.new(0,0,0);atm.Decay=Color3.new(0,0,0);atm.Glare=0;atm.Haze=0.05;local blo=Instance.new('BloomEffect',L);blo.Name='Bloom';blo.Enabled=true;blo.Intensity=1;blo.Size=56;blo.Threshold=2.9;local blu=Instance.new('BlurEffect',L);blu.Name='Blur';blu.Enabled=false;blu.Size=3;local col=Instance.new('ColorCorrectionEffect',L);col.Name='ColorCorrection';col.Enabled=true;col.Brightness=0;col.Contrast=0.1;col.Saturation=0.2;col.TintColor=Color3.new(1,1,1);local sun=Instance.new('SunRaysEffect',L);sun.Name='SunRays';sun.Enabled=true;sun.Intensity=0.004;sun.Spread=0.04]])
        end,
        Sunset = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0,0,0);L.Brightness=1.5;L.ColorShift_Bottom=Color3.new(0,0,0);L.ColorShift_Top=Color3.new(0.666667,0.533333,0.321569);L.OutdoorAmbient=Color3.new(0,0,0);L.FogColor=Color3.new(0.752941,0.752941,0.752941);L.FogEnd=100000;L.FogStart=0;L.GlobalShadows=true;L.GeographicLatitude=40;L.ExposureCompensation=0.5;L.EnvironmentDiffuseScale=1;L.EnvironmentSpecularScale=1;L.ClockTime=17.6;L.TimeOfDay='17:36:00';L.ShadowSoftness=0.03;L.Technology=Enum.Technology.Future;local sky=Instance.new('Sky',L);sky.Name='60';sky.CelestialBodiesShown=true;sky.SunAngularSize=5;sky.MoonAngularSize=1.5;sky.SkyboxBk='rbxassetid://6973550206';sky.SkyboxDn='rbxassetid://6973550815';sky.SkyboxFt='rbxassetid://6973549125';sky.SkyboxLf='rbxassetid://6973549670';sky.SkyboxRt='rbxassetid://9089057892';sky.SkyboxUp='rbxassetid://6973551204';sky.StarCount=5000;sky.SunTextureId='rbxassetid://1084351190';sky.MoonTextureId='rbxassetid://1075087760';local atm=Instance.new('Atmosphere',L);atm.Name='Atmosphere';atm.Density=0.35;atm.Offset=1;atm.Color=Color3.new(0.490196,0.247059,0.45098);atm.Decay=Color3.new(0.411765,0.643137,0.705882);atm.Glare=0;atm.Haze=0.05;local blo=Instance.new('BloomEffect',L);blo.Name='Bloom';blo.Enabled=true;blo.Intensity=1;blo.Size=56;blo.Threshold=2.9;local blu=Instance.new('BlurEffect',L);blu.Name='Blur';blu.Enabled=false;blu.Size=3;local col=Instance.new('ColorCorrectionEffect',L);col.Name='ColorCorrection';col.Enabled=true;col.Brightness=0;col.Contrast=0.05;col.Saturation=0.1;col.TintColor=Color3.new(1,0.921569,0.796078);local sun=Instance.new('SunRaysEffect',L);sun.Name='SunRays';sun.Enabled=true;sun.Intensity=0.004;sun.Spread=0.04]])
        end,
        Blizzard = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0,0,0);L.Brightness=1;L.ColorShift_Bottom=Color3.new(0,0,0);L.ColorShift_Top=Color3.new(0,0,0);L.OutdoorAmbient=Color3.new(0.576471,0.6,0.760784);L.FogColor=Color3.new(0.576471,0.6,0.760784);L.FogEnd=300;L.FogStart=15;L.GlobalShadows=true;L.GeographicLatitude=23.5;L.ExposureCompensation=0;L.EnvironmentDiffuseScale=0.4;L.EnvironmentSpecularScale=0.6;L.ClockTime=12;L.TimeOfDay='12:00:00';L.ShadowSoftness=0.07;L.Technology=Enum.Technology.Future;local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=false;sky.SkyboxBk='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxDn='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxFt='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxLf='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxRt='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxUp='http://www.roblox.com/asset/?id=4514139911';sky.StarCount=3000;local atm=Instance.new('Atmosphere',L);atm.Name='Blizzard_Atmosphere';atm.Density=0.531;atm.Offset=0.281;atm.Color=Color3.new(0.686275,0.733333,0.780392);atm.Decay=Color3.new(0.619608,0.666667,0.784314);atm.Glare=2.69;atm.Haze=10]])
            local folder=Instance.new("Folder",workspace)
            folder.Name="Snowfall_Client"
            makeSnowPart("Blizzard",5000,NumberRange.new(6,8),NumberRange.new(20,50),
                {NumberSequenceKeypoint.new(0,1.875),NumberSequenceKeypoint.new(0.374999,1.25),NumberSequenceKeypoint.new(1,0)},
                {NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.501247,0.4375),NumberSequenceKeypoint.new(1,0)},
                Vector3.new(0,-0.4,0),folder,true)
            startWeatherAudio("Blizzard")
        end,
        LightSnow = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0.15,0.15,0.15);L.Brightness=1.7;L.ColorShift_Bottom=Color3.new(0,0,0);L.ColorShift_Top=Color3.new(0,0,0);L.OutdoorAmbient=Color3.new(0.68,0.72,0.78);L.FogColor=Color3.new(0.76,0.8,0.86);L.FogEnd=850;L.FogStart=35;L.GlobalShadows=true;L.GeographicLatitude=23.5;L.ExposureCompensation=0;L.EnvironmentDiffuseScale=0.5;L.EnvironmentSpecularScale=0.65;L.ClockTime=12.3;L.TimeOfDay='12:18:00';L.ShadowSoftness=0.05;L.Technology=Enum.Technology.Future;local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=false;sky.SkyboxBk='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxDn='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxFt='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxLf='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxRt='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxUp='http://www.roblox.com/asset/?id=4514139911';sky.StarCount=3000;local atm=Instance.new('Atmosphere',L);atm.Name='LightSnow_Atmosphere';atm.Density=0.4;atm.Offset=0.12;atm.Color=Color3.new(0.8,0.84,0.89);atm.Decay=Color3.new(0.7,0.74,0.81);atm.Glare=0.7;atm.Haze=2.4;local col=Instance.new('ColorCorrectionEffect',L);col.Name='ColorCorrection';col.Enabled=true;col.Brightness=-0.01;col.Contrast=0.04;col.Saturation=-0.1;col.TintColor=Color3.new(0.96,0.98,1)]])
            local folder=Instance.new("Folder",workspace)
            folder.Name="Snowfall_Client"
            makeSnowPart("LightSnow",450,NumberRange.new(7,10),NumberRange.new(6,14),
                {NumberSequenceKeypoint.new(0,0.45),NumberSequenceKeypoint.new(0.7,0.32),NumberSequenceKeypoint.new(1,0.18)},
                {NumberSequenceKeypoint.new(0,0.35),NumberSequenceKeypoint.new(0.8,0.5),NumberSequenceKeypoint.new(1,1)},
                Vector3.new(0,-1.2,0),folder,false)
        end,
        ChillMorning = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0,0,0);L.Brightness=2.2;L.ColorShift_Bottom=Color3.new(0.9,0.95,1);L.ColorShift_Top=Color3.new(0.972549,0.537255,0.152941);L.OutdoorAmbient=Color3.new(0.62,0.66,0.74);L.FogColor=Color3.new(0.82,0.87,0.93);L.FogEnd=680;L.FogStart=30;L.GlobalShadows=true;L.GeographicLatitude=40;L.ExposureCompensation=0.55;L.EnvironmentDiffuseScale=0.6;L.EnvironmentSpecularScale=0.75;L.ClockTime=7.2;L.TimeOfDay='07:12:00';L.ShadowSoftness=0.04;L.Technology=Enum.Technology.Future;local sky=Instance.new('Sky',L);sky.Name='ChillMorningSky';sky.CelestialBodiesShown=true;sky.SunAngularSize=5;sky.MoonAngularSize=1.5;sky.SkyboxBk='rbxassetid://6973550206';sky.SkyboxDn='rbxassetid://6973550815';sky.SkyboxFt='rbxassetid://6973549125';sky.SkyboxLf='rbxassetid://6973549670';sky.SkyboxRt='rbxassetid://9089057892';sky.SkyboxUp='rbxassetid://6973551204';sky.StarCount=2000;sky.SunTextureId='rbxassetid://1084351190';sky.MoonTextureId='rbxassetid://1075087760';local atm=Instance.new('Atmosphere',L);atm.Name='ChillMorning_Atmosphere';atm.Density=0.38;atm.Offset=0.18;atm.Color=Color3.new(0.78,0.82,0.88);atm.Decay=Color3.new(0.68,0.72,0.80);atm.Glare=0.9;atm.Haze=2.0;local blo=Instance.new('BloomEffect',L);blo.Name='Bloom';blo.Enabled=true;blo.Intensity=0.85;blo.Size=48;blo.Threshold=2.7;local col=Instance.new('ColorCorrectionEffect',L);col.Name='ColorCorrection';col.Enabled=true;col.Brightness=0.02;col.Contrast=0.08;col.Saturation=0.05;col.TintColor=Color3.new(0.96,0.98,1);local sun=Instance.new('SunRaysEffect',L);sun.Name='SunRays';sun.Enabled=true;sun.Intensity=0.003;sun.Spread=0.035]])
            local folder=Instance.new("Folder",workspace)
            folder.Name="Snowfall_Client"
            makeSnowPart("ChillMorning",320,NumberRange.new(8,12),NumberRange.new(4,10),
                {NumberSequenceKeypoint.new(0,0.40),NumberSequenceKeypoint.new(0.7,0.28),NumberSequenceKeypoint.new(1,0.14)},
                {NumberSequenceKeypoint.new(0,0.28),NumberSequenceKeypoint.new(0.8,0.48),NumberSequenceKeypoint.new(1,1)},
                Vector3.new(0,-0.9,0),folder,false)
        end,
        LightRain = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0,0,0);L.Brightness=1.4;L.ColorShift_Bottom=Color3.new(0,0,0);L.ColorShift_Top=Color3.new(0.6,0.6,0.6);L.OutdoorAmbient=Color3.new(0.3,0.32,0.36);L.FogColor=Color3.new(0.72,0.74,0.78);L.FogEnd=800;L.FogStart=40;L.GlobalShadows=true;L.GeographicLatitude=40;L.ExposureCompensation=0;L.EnvironmentDiffuseScale=0.8;L.EnvironmentSpecularScale=0.6;L.ClockTime=13;L.TimeOfDay='15:00:00';L.ShadowSoftness=0.05;L.Technology=Enum.Technology.Future;local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=false;sky.SkyboxBk='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxDn='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxFt='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxLf='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxRt='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxUp='http://www.roblox.com/asset/?id=4514139911';sky.StarCount=0;local atm=Instance.new('Atmosphere',L);atm.Name='LightRain_Atmosphere';atm.Density=0.38;atm.Offset=0.08;atm.Color=Color3.new(0.74,0.76,0.80);atm.Decay=Color3.new(0.60,0.62,0.66);atm.Glare=0.3;atm.Haze=1.8;local col=Instance.new('ColorCorrectionEffect',L);col.Name='ColorCorrection';col.Enabled=true;col.Brightness=-0.02;col.Contrast=0.03;col.Saturation=-0.15;col.TintColor=Color3.new(0.94,0.96,1)]])
            local folder=Instance.new("Folder",workspace)
            folder.Name="Snowfall_Client"
            buildRainScene(lplr,workspace.CurrentCamera,folder,28,38,6,0.94,0.97)
            startWeatherAudio("LightRain")
        end,
        HeavyRain = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0.168627,0.168627,0.168627);L.Brightness=1;L.ColorShift_Bottom=Color3.new(0,0,0);L.ColorShift_Top=Color3.new(0,0,0);L.OutdoorAmbient=Color3.new(0.168627,0.168627,0.168627);L.FogColor=Color3.new(0.752941,0.752941,0.752941);L.FogEnd=100000;L.FogStart=0;L.GlobalShadows=true;L.GeographicLatitude=0;L.ExposureCompensation=0;L.EnvironmentDiffuseScale=1;L.EnvironmentSpecularScale=1;L.ClockTime=0;L.TimeOfDay='2:00:00';L.ShadowSoftness=0.2;L.Technology=Enum.Technology.ShadowMap;local atm=Instance.new('Atmosphere',L);atm.Name='Atmosphere';atm.Density=0.6;atm.Offset=0;atm.Color=Color3.new(0.780392,0.780392,0.780392);atm.Decay=Color3.new(0.415686,0.439216,0.490196);atm.Glare=0;atm.Haze=0;local col=Instance.new('ColorCorrectionEffect',L);col.Name='ColorCorrection';col.Enabled=true;col.Brightness=0;col.Contrast=0;col.Saturation=0.5;col.TintColor=Color3.new(1,1,1);local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=true;sky.SunAngularSize=11;sky.MoonAngularSize=11;sky.SkyboxBk='rbxassetid://6444884337';sky.SkyboxDn='rbxassetid://6444884785';sky.SkyboxFt='rbxassetid://6444884337';sky.SkyboxLf='rbxassetid://6444884337';sky.SkyboxRt='rbxassetid://6444884337';sky.SkyboxUp='rbxassetid://6412503613';sky.StarCount=3000;sky.SunTextureId='rbxassetid://6196665106';sky.MoonTextureId='rbxassetid://5076043799';local dep=Instance.new('DepthOfFieldEffect',L);dep.Name='DepthOfField';dep.Enabled=true;dep.FarIntensity=0.75;dep.FocusDistance=0.05;dep.InFocusRadius=75;dep.NearIntensity=0]])
            local folder=Instance.new("Folder",workspace)
            folder.Name="Snowfall_Client"
            buildRainScene(lplr,workspace.CurrentCamera,folder,82,50,18,0.88,0.93)
            startWeatherAudio("HeavyRain")
            lightFolders()
        end,
        BloodMoon = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0.0784314,0.0784314,0.0784314);L.Brightness=0.5;L.ColorShift_Bottom=Color3.new(0,0,0);L.ColorShift_Top=Color3.new(0,0,0);L.OutdoorAmbient=Color3.new(0.423529,0.160784,0.164706);L.FogColor=Color3.new(0,0,0);L.FogEnd=300;L.FogStart=15;L.GlobalShadows=true;L.GeographicLatitude=23.5;L.ExposureCompensation=0;L.EnvironmentDiffuseScale=0.4;L.EnvironmentSpecularScale=0.6;L.ClockTime=0;L.TimeOfDay='00:00:00';L.ShadowSoftness=0.07;L.Technology=Enum.Technology.Future;local blu=Instance.new('BlurEffect',L);blu.Name='Blur';blu.Enabled=true;blu.Size=1;local blo=Instance.new('BloomEffect',L);blo.Name='DefaultBloom';blo.Enabled=true;blo.Intensity=0.2;blo.Size=100;blo.Threshold=0.8;local col2=Instance.new('ColorCorrectionEffect',L);col2.Name='Saturation';col2.Enabled=true;col2.Brightness=0;col2.Contrast=0;col2.Saturation=0.4;col2.TintColor=Color3.new(1,1,1);local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=false;sky.SkyboxBk='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxDn='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxFt='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxLf='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxRt='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxUp='http://www.roblox.com/asset/?id=4514139911';sky.StarCount=3000;local atm=Instance.new('Atmosphere',L);atm.Name='BloodNight_Atmosphere';atm.Density=0.58;atm.Offset=0;atm.Color=Color3.new(0.254902,0.14902,0.152941);atm.Decay=Color3.new(0.27451,0.0431373,0.0509804);atm.Glare=0;atm.Haze=4.47]])
        end,
        Nighttime = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0.168627,0.168627,0.168627);L.Brightness=1;L.ColorShift_Bottom=Color3.new(0,0,0);L.ColorShift_Top=Color3.new(0,0,0);L.OutdoorAmbient=Color3.new(0.168627,0.168627,0.168627);L.FogColor=Color3.new(0.752941,0.752941,0.752941);L.FogEnd=100000;L.FogStart=0;L.GlobalShadows=true;L.GeographicLatitude=0;L.ExposureCompensation=0;L.EnvironmentDiffuseScale=1;L.EnvironmentSpecularScale=1;L.ClockTime=0;L.TimeOfDay='00:00:00';L.ShadowSoftness=0.2;L.Technology=Enum.Technology.Future;local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=true;sky.SunAngularSize=11;sky.MoonAngularSize=11;sky.SkyboxBk='rbxassetid://6444884337';sky.SkyboxDn='rbxassetid://6444884785';sky.SkyboxFt='rbxassetid://6444884337';sky.SkyboxLf='rbxassetid://6444884337';sky.SkyboxRt='rbxassetid://6444884337';sky.SkyboxUp='rbxassetid://6412503613';sky.StarCount=3000;sky.SunTextureId='rbxassetid://6196665106';sky.MoonTextureId='rbxassetid://5076043799';local dep=Instance.new('DepthOfFieldEffect',L);dep.Name='DepthOfField';dep.Enabled=false;dep.FarIntensity=0;dep.FocusDistance=0.05;dep.InFocusRadius=30;dep.NearIntensity=0;local col=Instance.new('ColorCorrectionEffect',L);col.Name='ColorCorrection';col.Enabled=true;col.Brightness=0;col.Contrast=0;col.Saturation=0;col.TintColor=Color3.new(1,1,1);local atm=Instance.new('Atmosphere',L);atm.Name='Atmosphere';atm.Density=0.6;atm.Offset=0;atm.Color=Color3.new(0.780392,0.780392,0.780392);atm.Decay=Color3.new(0.415686,0.439216,0.490196);atm.Glare=0;atm.Haze=0]])
            setupNightLights()
            local gameAudio=Instance.new("Folder")
            gameAudio.Name="GameAudio"
            gameAudio.Parent=workspace
            audioState.folder=gameAudio
            local bgSound=Instance.new("Sound")
            bgSound.Name="OutsideNightAmbient"
            bgSound.SoundId="rbxassetid://9112764891"
            bgSound.Looped=true
            bgSound.Volume=0.1
            bgSound.RollOffMode=Enum.RollOffMode.Inverse
            bgSound.RollOffMinDistance=35
            bgSound.RollOffMaxDistance=100000
            bgSound.EmitterSize=80
            bgSound.Parent=gameAudio
            bgSound:Play()
        end,
        Foggy = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0,0,0);L.Brightness=1;L.ColorShift_Bottom=Color3.new(0,0,0);L.ColorShift_Top=Color3.new(0,0,0);L.OutdoorAmbient=Color3.new(0.431373,0.431373,0.431373);L.FogColor=Color3.new(0.521569,0.521569,0.521569);L.FogEnd=300;L.FogStart=15;L.GlobalShadows=true;L.GeographicLatitude=23.5;L.ExposureCompensation=0;L.EnvironmentDiffuseScale=0.4;L.EnvironmentSpecularScale=0.6;L.ClockTime=12;L.TimeOfDay='12:00:00';L.ShadowSoftness=0.07;L.Technology=Enum.Technology.Future;local blu=Instance.new('BlurEffect',L);blu.Name='Blur';blu.Enabled=true;blu.Size=1;local blo=Instance.new('BloomEffect',L);blo.Name='DefaultBloom';blo.Enabled=true;blo.Intensity=0.2;blo.Size=100;blo.Threshold=0.8;local col2=Instance.new('ColorCorrectionEffect',L);col2.Name='Saturation';col2.Enabled=true;col2.Brightness=0;col2.Contrast=0;col2.Saturation=0.4;col2.TintColor=Color3.new(1,1,1);local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=false;sky.SkyboxBk='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxDn='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxFt='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxLf='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxRt='http://www.roblox.com/asset/?id=4514139911';sky.SkyboxUp='http://www.roblox.com/asset/?id=4514139911';sky.StarCount=3000;local atm=Instance.new('Atmosphere',L);atm.Name='FoggyDay_Atmosphere';atm.Density=0.675;atm.Offset=0;atm.Color=Color3.new(0.780392,0.780392,0.780392);atm.Decay=Color3.new(0.454902,0.454902,0.454902);atm.Glare=4.95;atm.Haze=2.62]])
        end,
        WasteLand = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0,0,0);L.Brightness=3.5;L.ColorShift_Bottom=Color3.new(0,0,0);L.ColorShift_Top=Color3.new(1,0.752941,0.572549);L.OutdoorAmbient=Color3.new(0.254902,0.282353,0.207843);L.FogColor=Color3.new(0.752941,0.752941,0.752941);L.FogEnd=100000;L.FogStart=0;L.GlobalShadows=true;L.GeographicLatitude=53;L.ExposureCompensation=0;L.EnvironmentDiffuseScale=0.222;L.EnvironmentSpecularScale=1;L.ClockTime=7.8;L.TimeOfDay='07:48:00';L.ShadowSoftness=0.15;L.Technology=Enum.Technology.Voxel;local blo=Instance.new('BloomEffect',L);blo.Name='Bloom';blo.Enabled=true;blo.Intensity=0.15;blo.Size=20;blo.Threshold=2;local blu=Instance.new('BlurEffect',L);blu.Name='Blur';blu.Enabled=true;blu.Size=1;local col=Instance.new('ColorCorrectionEffect',L);col.Name='ColorCorrection';col.Enabled=true;col.Brightness=0.1;col.Contrast=0.2;col.Saturation=0;col.TintColor=Color3.new(0.803922,0.890196,1);local sun=Instance.new('SunRaysEffect',L);sun.Name='SunRays';sun.Enabled=true;sun.Intensity=-0.01;sun.Spread=1;local sky=Instance.new('Sky',L);sky.Name='Clouded Sky';sky.CelestialBodiesShown=true;sky.SunAngularSize=11;sky.MoonAngularSize=11;sky.SkyboxBk='http://www.roblox.com/asset/?id=252760981';sky.SkyboxDn='http://www.roblox.com/asset/?id=252763035';sky.SkyboxFt='http://www.roblox.com/asset/?id=252761439';sky.SkyboxLf='http://www.roblox.com/asset/?id=252760980';sky.SkyboxRt='http://www.roblox.com/asset/?id=252760986';sky.SkyboxUp='http://www.roblox.com/asset/?id=252762652';sky.StarCount=3000;sky.SunTextureId='rbxassetid://1345009717';sky.MoonTextureId='rbxasset://sky/moon.jpg';local atm=Instance.new('Atmosphere',L);atm.Name='Atmosphere';atm.Density=0.125;atm.Offset=0;atm.Color=Color3.new(0.45098,0.623529,0.65098);atm.Decay=Color3.new(0.160784,0.239216,0.247059);atm.Glare=0.5;atm.Haze=2.1]])
        end,
        Haze = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0.211765,0.219608,0.231373);L.Brightness=2.1;L.ColorShift_Bottom=Color3.new(0.713726,0.713726,0.713726);L.ColorShift_Top=Color3.new(0.956863,0.952941,0.886275);L.OutdoorAmbient=Color3.new(0.490196,0.482353,0.458824);L.FogColor=Color3.new(0.752941,0.752941,0.752941);L.FogEnd=100000;L.FogStart=0;L.GlobalShadows=true;L.GeographicLatitude=55;L.ExposureCompensation=0.6;L.EnvironmentDiffuseScale=0.5;L.EnvironmentSpecularScale=0.75;L.ClockTime=7.6;L.TimeOfDay='07:36:00';L.ShadowSoftness=0.1;L.Technology=Enum.Technology.Future;local atm=Instance.new('Atmosphere',L);atm.Name='Atmosphere';atm.Density=0.3;atm.Offset=0;atm.Color=Color3.new(1,0.964706,0.827451);atm.Decay=Color3.new(0.654902,0.627451,0.576471);atm.Glare=0.25;atm.Haze=0.15;local blo=Instance.new('BloomEffect',L);blo.Name='Bloom';blo.Enabled=true;blo.Intensity=0.05;blo.Size=38;blo.Threshold=2;local col=Instance.new('ColorCorrectionEffect',L);col.Name='Default';col.Enabled=true;col.Brightness=-0.06;col.Contrast=0.33;col.Saturation=0.1;col.TintColor=Color3.new(1,0.941176,0.878431);local dep=Instance.new('DepthOfFieldEffect',L);dep.Name='DepthOfField';dep.Enabled=true;dep.FarIntensity=0.1;dep.FocusDistance=100;dep.InFocusRadius=50;dep.NearIntensity=0;local sun=Instance.new('SunRaysEffect',L);sun.Name='Rays';sun.Enabled=true;sun.Intensity=0.022;sun.Spread=0.4;local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=true;sky.SunAngularSize=11;sky.MoonAngularSize=11;sky.SkyboxBk='http://www.roblox.com/asset/?id=252760981';sky.SkyboxDn='http://www.roblox.com/asset/?id=252763035';sky.SkyboxFt='http://www.roblox.com/asset/?id=252761439';sky.SkyboxLf='http://www.roblox.com/asset/?id=252760980';sky.SkyboxRt='http://www.roblox.com/asset/?id=252760986';sky.SkyboxUp='http://www.roblox.com/asset/?id=252762652';sky.StarCount=3000;sky.SunTextureId='rbxassetid://1345009717';sky.MoonTextureId='rbxasset://sky/moon.jpg']])
        end,
        CherryBlossom = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0.627451,0.580392,0.631373);L.Brightness=8;L.ColorShift_Bottom=Color3.new(0.713726,0.713726,0.713726);L.ColorShift_Top=Color3.new(0.956863,0.952941,0.886275);L.OutdoorAmbient=Color3.new(0.552941,0.529412,0.576471);L.FogColor=Color3.new(0.752941,0.752941,0.752941);L.FogEnd=100000;L.FogStart=0;L.GlobalShadows=true;L.GeographicLatitude=25;L.ExposureCompensation=0.1;L.EnvironmentDiffuseScale=0;L.EnvironmentSpecularScale=0.75;L.ClockTime=16.7;L.TimeOfDay='16:42:00';L.ShadowSoftness=0.1;L.Technology=Enum.Technology.Future;local atm=Instance.new('Atmosphere',L);atm.Name='Atmosphere';atm.Density=0.33;atm.Offset=0;atm.Color=Color3.new(0.580392,0.462745,0.552941);atm.Decay=Color3.new(0.866667,0.768627,0.909804);atm.Glare=0.2;atm.Haze=0;local blo=Instance.new('BloomEffect',L);blo.Name='Bloom';blo.Enabled=true;blo.Intensity=0.05;blo.Size=38;blo.Threshold=2;local col=Instance.new('ColorCorrectionEffect',L);col.Name='Default';col.Enabled=true;col.Brightness=-0.04;col.Contrast=0.3;col.Saturation=0.1;col.TintColor=Color3.new(1,0.937255,1);local dep=Instance.new('DepthOfFieldEffect',L);dep.Name='DepthOfField';dep.Enabled=true;dep.FarIntensity=0.1;dep.FocusDistance=100;dep.InFocusRadius=50;dep.NearIntensity=0;local sun=Instance.new('SunRaysEffect',L);sun.Name='Rays';sun.Enabled=true;sun.Intensity=0.022;sun.Spread=0.4;local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=true;sky.SunAngularSize=21;sky.MoonAngularSize=11;sky.SkyboxBk='rbxassetid://11555017034';sky.SkyboxDn='rbxassetid://11555013415';sky.SkyboxFt='rbxassetid://11555010145';sky.SkyboxLf='rbxassetid://11555006545';sky.SkyboxRt='rbxassetid://11555000712';sky.SkyboxUp='rbxassetid://11554996247';sky.StarCount=3000]])
        end,
        GoldenHour = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0.133333,0.137255,0.145098);L.Brightness=2.2;L.ColorShift_Bottom=Color3.new(0.713726,0.713726,0.713726);L.ColorShift_Top=Color3.new(0.956863,0.952941,0.886275);L.OutdoorAmbient=Color3.new(0.4,0.34902,0.321569);L.FogColor=Color3.new(0.752941,0.752941,0.752941);L.FogEnd=100000;L.FogStart=0;L.GlobalShadows=true;L.GeographicLatitude=55;L.ExposureCompensation=0.6;L.EnvironmentDiffuseScale=0.5;L.EnvironmentSpecularScale=0.75;L.ClockTime=16.65;L.TimeOfDay='16:39:00';L.ShadowSoftness=0.1;L.Technology=Enum.Technology.Future;local atm=Instance.new('Atmosphere',L);atm.Name='Atmosphere';atm.Density=0.33;atm.Offset=0;atm.Color=Color3.new(0.7843,0.6667,0.4235);atm.Decay=Color3.new(0.3608,0.2353,0.0549);atm.Glare=0;atm.Haze=0;local blo=Instance.new('BloomEffect',L);blo.Name='Bloom';blo.Enabled=true;blo.Intensity=0.05;blo.Size=38;blo.Threshold=2;local col=Instance.new('ColorCorrectionEffect',L);col.Name='Default';col.Enabled=true;col.Brightness=-0.04;col.Contrast=0.4;col.Saturation=0.1;col.TintColor=Color3.new(1,0.941176,0.878431);local dep=Instance.new('DepthOfFieldEffect',L);dep.Name='DepthOfField';dep.Enabled=true;dep.FarIntensity=0.1;dep.FocusDistance=100;dep.InFocusRadius=50;dep.NearIntensity=0;local sun=Instance.new('SunRaysEffect',L);sun.Name='Rays';sun.Enabled=true;sun.Intensity=0.022;sun.Spread=0.4;local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=false;sky.SunAngularSize=21;sky.MoonAngularSize=11;sky.SkyboxBk='rbxassetid://600830446';sky.SkyboxDn='rbxassetid://600831635';sky.SkyboxFt='rbxassetid://600832720';sky.SkyboxLf='rbxassetid://600886090';sky.SkyboxRt='rbxassetid://600833862';sky.SkyboxUp='rbxassetid://600835177';sky.StarCount=3000]])
        end,
        Void = function()
            cleanupAll()
            applyLighting([[local L=game:GetService('Lighting');L:ClearAllChildren();task.wait(0.3);L.Ambient=Color3.new(0.784314,0.784314,0.784314);L.Brightness=1;L.ColorShift_Bottom=Color3.new(0,0,0);L.ColorShift_Top=Color3.new(0,0,0);L.OutdoorAmbient=Color3.new(0.588235,0.588235,0.588235);L.FogColor=Color3.new(0.431373,0.258824,0.666667);L.FogEnd=2000;L.FogStart=0;L.GlobalShadows=true;L.GeographicLatitude=41.7333;L.ExposureCompensation=0;L.EnvironmentDiffuseScale=0;L.EnvironmentSpecularScale=0;L.ClockTime=14;L.TimeOfDay='14:00:00';L.ShadowSoftness=0.5;L.Technology=Enum.Technology.ShadowMap;local sun=Instance.new('SunRaysEffect',L);sun.Name='SunRays';sun.Enabled=true;sun.Intensity=0;sun.Spread=1;local col=Instance.new('ColorCorrectionEffect',L);col.Name='ColorCorrection';col.Enabled=true;col.Brightness=0;col.Contrast=0.35;col.Saturation=0;col.TintColor=Color3.new(1,1,1);local blo=Instance.new('BloomEffect',L);blo.Name='Bloom';blo.Enabled=true;blo.Intensity=1;blo.Size=13;blo.Threshold=2;local sky=Instance.new('Sky',L);sky.Name='Sky';sky.CelestialBodiesShown=false;sky.SunAngularSize=21;sky.MoonAngularSize=11;sky.SkyboxBk='http://www.roblox.com/asset/?id=296908715';sky.SkyboxDn='http://www.roblox.com/asset/?id=296908724';sky.SkyboxFt='http://www.roblox.com/asset/?id=296908740';sky.SkyboxLf='http://www.roblox.com/asset/?id=296908755';sky.SkyboxRt='http://www.roblox.com/asset/?id=296908764';sky.SkyboxUp='http://www.roblox.com/asset/?id=296908769';sky.StarCount=0]])
        end,
        TimeCycle = function()
            cleanupAll()
            local L=game:GetService("Lighting")
            L:ClearAllChildren()
            L.Technology=Enum.Technology.Future
            L.GlobalShadows=true
            L.GeographicLatitude=40
            L.ShadowSoftness=0.25
            L.FogEnd=100000
            L.FogStart=0
            L.EnvironmentDiffuseScale=1
            L.EnvironmentSpecularScale=1
            local sky=Instance.new("Sky",L)
            sky.Name="60"
            sky.CelestialBodiesShown=true
            sky.SunAngularSize=5
            sky.MoonAngularSize=1.5
            sky.SkyboxBk="rbxassetid://6973550206"
            sky.SkyboxDn="rbxassetid://6973550815"
            sky.SkyboxFt="rbxassetid://6973549125"
            sky.SkyboxLf="rbxassetid://6973549670"
            sky.SkyboxRt="rbxassetid://9089057892"
            sky.SkyboxUp="rbxassetid://6973551204"
            sky.StarCount=5000
            sky.SunTextureId="rbxassetid://1084351190"
            sky.MoonTextureId="rbxassetid://1075087760"
            local atm=Instance.new("Atmosphere",L)
            local bloom=Instance.new("BloomEffect",L)
            bloom.Name="Bloom"
            bloom.Enabled=true
            local cc=Instance.new("ColorCorrectionEffect",L)
            cc.Name="ColorCorrection"
            cc.Enabled=true
            local sun=Instance.new("SunRaysEffect",L)
            sun.Name="SunRays"
            sun.Enabled=true
            sun.Intensity=0.004
            sun.Spread=0.04
            local KF={
                {clock=7,   brightness=3,   exposure=0.7, shadowSoftness=0.25, csTop=Color3.new(0.972549,0.537255,0.152941), csBot=Color3.new(1,1,1),               ambient=Color3.new(0,0,0),             outdoorAmbient=Color3.new(0,0,0),             atmDensity=0.325,atmOffset=1,   atmColor=Color3.new(0,0,0),             atmDecay=Color3.new(0,0,0),             atmGlare=0,atmHaze=0.05, bloomI=1,bloomS=56,bloomT=2.9,ccContrast=0.1, ccSat=0.2, ccTint=Color3.new(1,1,1)},
                {clock=14,  brightness=3,   exposure=0.4, shadowSoftness=0.15, csTop=Color3.new(1,0.941176,0.803922),         csBot=Color3.new(1,1,1),               ambient=Color3.new(0,0,0),             outdoorAmbient=Color3.new(0,0,0),             atmDensity=0.3,  atmOffset=0.9,  atmColor=Color3.new(0.101961,0.109804,0.152941),atmDecay=Color3.new(0.101961,0.109804,0.152941),atmGlare=0,atmHaze=0,    bloomI=1,bloomS=56,bloomT=2.9,ccContrast=0.05,ccSat=0.1, ccTint=Color3.new(1,1,1)},
                {clock=17.6,brightness=1.5, exposure=0.5, shadowSoftness=0.25, csTop=Color3.new(0.666667,0.533333,0.321569),  csBot=Color3.new(0,0,0),               ambient=Color3.new(0,0,0),             outdoorAmbient=Color3.new(0,0,0),             atmDensity=0.35, atmOffset=1,    atmColor=Color3.new(0.490196,0.247059,0.45098), atmDecay=Color3.new(0.411765,0.643137,0.705882),atmGlare=0,atmHaze=0.05, bloomI=1,bloomS=56,bloomT=2.9,ccContrast=0.05,ccSat=0.1, ccTint=Color3.new(1,0.921569,0.796078)},
                {clock=27,  brightness=1,   exposure=2.1, shadowSoftness=0.35, csTop=Color3.new(1,1,1),                        csBot=Color3.new(0,0,0),               ambient=Color3.new(0.098,0.098,0.098),outdoorAmbient=Color3.new(0.098,0.098,0.098),atmDensity=0.35, atmOffset=0.93, atmColor=Color3.new(0.133333,0.0901961,0.152941),atmDecay=Color3.new(0.133333,0.0901961,0.152941),atmGlare=0,atmHaze=0.05, bloomI=1,bloomS=56,bloomT=2.9,ccContrast=0.05,ccSat=-0.1,ccTint=Color3.new(1,1,1)},
            }
            local SEG_W={7/24,3.6/24,9.4/24,4/24}; local SEG_S={0}; for i=1,3 do SEG_S[i+1]=SEG_S[i]+SEG_W[i] end
            local CYCLE_DURATION=300
            local cycleStart=tick()
            timeCycleConn=RunService.Heartbeat:Connect(function()
                local t=(tick()-cycleStart)%CYCLE_DURATION/CYCLE_DURATION
                local seg=4; for i=3,1,-1 do if t<SEG_S[i+1] then seg=i end end
                local a=KF[seg]
                local b=KF[seg%4+1]
                local st=math.clamp((t-SEG_S[seg])/SEG_W[seg],0,1)
                local lerp = function(x,y) return x+(y-x)*st end
                local clockB=(seg==4) and (KF[1].clock+24) or b.clock
                L.ClockTime=(a.clock+(clockB-a.clock)*st)%24
                L.Brightness=lerp(a.brightness,b.brightness)
                L.ExposureCompensation=lerp(a.exposure,b.exposure)
                L.ColorShift_Top=a.csTop:Lerp(b.csTop,st)
                L.ColorShift_Bottom=a.csBot:Lerp(b.csBot,st)
                L.Ambient=a.ambient:Lerp(b.ambient,st)
                L.OutdoorAmbient=a.outdoorAmbient:Lerp(b.outdoorAmbient,st)
                atm.Density=lerp(a.atmDensity,b.atmDensity)
                atm.Offset=lerp(a.atmOffset,b.atmOffset)
                atm.Color=a.atmColor:Lerp(b.atmColor,st)
                atm.Decay=a.atmDecay:Lerp(b.atmDecay,st)
                atm.Glare=lerp(a.atmGlare,b.atmGlare)
                atm.Haze=lerp(a.atmHaze,b.atmHaze)
                bloom.Intensity=lerp(a.bloomI,b.bloomI)
                bloom.Size=lerp(a.bloomS,b.bloomS)
                bloom.Threshold=lerp(a.bloomT,b.bloomT)
                cc.Contrast=lerp(a.ccContrast,b.ccContrast)
                cc.Saturation=lerp(a.ccSat,b.ccSat)
                cc.TintColor=a.ccTint:Lerp(b.ccTint,st)
                L.ShadowSoftness=lerp(a.shadowSoftness,b.shadowSoftness)
            end)
        end,
    }

    GameThemes = GuiLibrary.Registry.miscPanel.API.CreateOptionsButton({
        Name = "GameThemes",
        Function = function(callback)
            if callback then themes[ThemeDropdown.Value]()
            else cleanupAll(); themes.Default() end
        end
    })
    ThemeDropdown = GameThemes.CreateDropdown({
        Name = "theme",
        List = {"Default","Morning","Sunset","LightSnow","ChillMorning","Blizzard","LightRain","HeavyRain","BloodMoon","Nighttime","Foggy","WasteLand","TimeCycle","GoldenHour","CherryBlossom","Haze","Void"},
        Default = "Default",
        Function = function(callback)
            if GameThemes.Enabled and themes[callback] then themes[callback]() end
        end
    })
end)

runcode(function()
    local pg = lplr:FindFirstChild("PlayerGui")

    local HIDE_GUIS = {
        "KitPopupsGui",
        "AnnouncementGui",
        "DamageScreenEffectGui",
        "NotificationGui",
        "AchievementGui",
        "OfflineRewardsGui",
        "GiftedKitGui",
        "PurchaseEffectGui",
        "PurchasingEffectGui2",
        "GroupVerificationGui",
        "ShiftlockDisplayGui",
        "DamageIndicatorGui",
    }

    local ALWAYS_HIDE_GUIS = {
        "UpdateLogGui",
    }

    local HIDE_TOPBAR = { "UpdateLog", "Codes" }

    local origEnabled = {}
    local origTopbar = {}
    local origHealthBGT = nil
    local origStatusBGT = nil
    local origStroke = nil
    local cleanLoop = nil
    local snapshotDone = false

    local snapshot = function()
        if snapshotDone then return end
        snapshotDone = true
        for _, name in ipairs(HIDE_GUIS) do
            local gui = pg:FindFirstChild(name)
            if gui then origEnabled[name] = gui.Enabled end
        end

        local topbar = pg:FindFirstChild("TopbarButtonsGui")
        if topbar then
            local bl = topbar:FindFirstChild("ButtonsList")
            if bl then
                for _, btnName in ipairs(HIDE_TOPBAR) do
                    local btn = bl:FindFirstChild(btnName)
                    if btn then origTopbar[btnName] = btn.Visible end
                end
            end
        end

        local healthGui = pg:FindFirstChild("HealthGui")
        if healthGui then
            local frame = healthGui:FindFirstChild("HealthFrame")
            if frame then
                local stroke = frame:FindFirstChild("UIStroke")
                if stroke then origStroke = stroke.Thickness end
                origHealthBGT = frame.BackgroundTransparency
            end
        end

        local statusGui = pg:FindFirstChild("GameStatusGui")
        if statusGui then
            local lbl = statusGui:FindFirstChild("StatusLabel")
            if lbl then origStatusBGT = lbl.BackgroundTransparency end
        end
    end

    local enforce = function()
        for _, name in ipairs(HIDE_GUIS) do
            local gui = pg:FindFirstChild(name)
            if gui and gui.Enabled then gui.Enabled = false end
        end
        for _, name in ipairs(ALWAYS_HIDE_GUIS) do
            local gui = pg:FindFirstChild(name)
            if gui and gui.Enabled then gui.Enabled = false end
        end

        local topbar = pg:FindFirstChild("TopbarButtonsGui")
        if topbar then
            local bl = topbar:FindFirstChild("ButtonsList")
            if bl then
                for _, btnName in ipairs(HIDE_TOPBAR) do
                    local btn = bl:FindFirstChild(btnName)
                    if btn and btn.Visible then btn.Visible = false end
                end
            end
        end

        local healthGui = pg:FindFirstChild("HealthGui")
        if healthGui then
            local frame = healthGui:FindFirstChild("HealthFrame")
            if frame then
                local stroke = frame:FindFirstChild("UIStroke")
                if stroke and stroke.Thickness ~= 0 then stroke.Thickness = 0 end
                if frame.BackgroundTransparency ~= 0.55 then frame.BackgroundTransparency = 0.55 end
            end
        end

        local statusGui = pg:FindFirstChild("GameStatusGui")
        if statusGui then
            local lbl = statusGui:FindFirstChild("StatusLabel")
            if lbl and lbl.BackgroundTransparency ~= 0.2 then lbl.BackgroundTransparency = 0.2 end
        end

        pcall(function()
            local bc = game:GetService("CoreGui"):FindFirstChild("ExperienceChat"):FindFirstChild("bubbleChat")
            if bc and bc.Enabled then bc.Enabled = false end
        end)
    end

    GuiLibrary.Registry.miscPanel.API.CreateOptionsButton({
        Name = "UICleanup",
        Function = function(callback)
            if callback then
                snapshot()
                enforce()
                cleanLoop = RunService.Heartbeat:Connect(enforce)
            else
                if cleanLoop then cleanLoop:Disconnect(); cleanLoop = nil end
                for name, was in pairs(origEnabled) do
                    local gui = pg:FindFirstChild(name)
                    if gui then gui.Enabled = was end
                end
                for _, name in ipairs(ALWAYS_HIDE_GUIS) do
                    local gui = pg:FindFirstChild(name)
                    if gui then gui.Enabled = false end
                end
                origEnabled = {}
                local topbar = pg:FindFirstChild("TopbarButtonsGui")
                if topbar then
                    local bl = topbar:FindFirstChild("ButtonsList")
                    if bl then
                        for btnName, was in pairs(origTopbar) do
                            local btn = bl:FindFirstChild(btnName)
                            if btn then btn.Visible = was end
                        end
                    end
                end
                origTopbar = {}
                local healthGui = pg:FindFirstChild("HealthGui")
                if healthGui then
                    local frame = healthGui:FindFirstChild("HealthFrame")
                    if frame then
                        local stroke = frame:FindFirstChild("UIStroke")
                        if stroke and origStroke ~= nil then stroke.Thickness = origStroke end
                        if origHealthBGT ~= nil then frame.BackgroundTransparency = origHealthBGT end
                    end
                end
                local statusGui = pg:FindFirstChild("GameStatusGui")
                if statusGui then
                    local lbl = statusGui:FindFirstChild("StatusLabel")
                    if lbl and origStatusBGT ~= nil then lbl.BackgroundTransparency = origStatusBGT end
                end
                pcall(function()
                    local bc = game:GetService("CoreGui"):FindFirstChild("ExperienceChat"):FindFirstChild("bubbleChat")
                    if bc then bc.Enabled = true end
                end)
                snapshotDone = false
            end
        end
    })
end)

runcode(function()
    local BlockRange = {}
    local BlockRangeSlider = {}
    local rangeVal = {Value = 50}
    local infRange = false
    local origRange = bedfight.modules.BlocksData.Default.Range
    BlockRange = GuiLibrary.Registry.utillityPanel.API.CreateOptionsButton({
        Name = "BlockRange",
        Function = function(callback)
            bedfight.modules.BlocksData.Default.Range = callback and (infRange and math.huge or rangeVal.Value) or origRange
        end
    })
    BlockRangeSlider = BlockRange.CreateSlider({
        Name = "Range",
        Min = 18, 
        Max = 200, 
        Default = 50, 
        Round = 1,
        Function = function(callback)
            rangeVal.Value = callback
            if BlockRange.Enabled and not infRange then bedfight.modules.BlocksData.Default.Range = callback end
        end
    })
    BlockRange.CreateToggle({
        Name = "Inf Range",
        Function = function(callback)
            infRange = callback
            if BlockRange.Enabled then
                bedfight.modules.BlocksData.Default.Range = callback and math.huge or rangeVal.Value
            end
        end
    })
end)

runcode(function()
    local MiningData = require(game:GetService("ReplicatedStorage").Modules.DataModules.MiningData)
    local origMining = {}
    local FastBreak = {}
    local FastBreakCooldown = {}
    for name, d in pairs(MiningData) do
        if type(d) == "table" and d.Cooldown ~= nil then
            origMining[name] = d.Cooldown
        end
    end
    FastBreak = GuiLibrary.Registry.utillityPanel.API.CreateOptionsButton({
        Name = "FastBreak",
        Function = function(callback)
            local cd = FastBreakCooldown and FastBreakCooldown.Value or 0.1
            for name, orig in pairs(origMining) do
                local d = MiningData[name]
                if d then d.Cooldown = callback and cd or orig end
            end
        end
    })
    FastBreakCooldown = FastBreak.CreateSlider({
        Name = "Cooldown",
        Min = 0,
        Max = 0.5,
        Default = 0.1,
        Function = function(callback)
            if FastBreak.Enabled then
                for name, _ in pairs(origMining) do
                    local d = MiningData[name]
                    if d then d.Cooldown = callback end
                end
            end
        end,
    })
end)

runcode(function()
    local Jetpack = {}
    Jetpack = GuiLibrary.Registry.utillityPanel.API.CreateOptionsButton({
        Name = "InfJetpack",
        Function = function(callback)
            if callback then
                RunLoops:BindToHeartbeat("InfJetpackLoop", function()
                    bedfight.modules.JetpackState.Fuel = 1
                end)
            else
                RunLoops:UnbindFromHeartbeat("InfJetpackLoop")
            end
        end
    })
end)

runcode(function()
    local PlayEmote = {}
    local AnimSpoof = {}
    local UISpoof = {}
    local wheel = lplr:WaitForChild("EmoteWheel")
    local _Original = {}
    local Emotes, SelectedEmote, LoopEnabled = {}, nil, false
    local popupConn = nil
    local oldPopupFunc = nil
    local popupConnection = nil

    for _, slot in ipairs(wheel:GetChildren()) do
        if slot:IsA("StringValue") then
            table.insert(Emotes, {Name = slot.Name, Value = slot.Value})
        end
    end

    for _, emote in pairs(bedfight.modules.EmotesData) do
        if type(emote) == "table" and emote.FrameConfigs then
            for _, frame in pairs(emote.FrameConfigs) do
                for _, config in ipairs(frame) do
                    if config.Id then
                        table.insert(_Original, {config = config, id = config.Id})
                    end
                end
            end
        end
    end

    PlayEmote = GuiLibrary.Registry.miscPanel.API.CreateOptionsButton({
        Name = "PlayEmote",
        Function = function(callback)
            if callback then
                if AnimSpoof.Enabled then
                    for _, entry in ipairs(_Original) do entry.config.Id = "rbxassetid://0" end
                end
                for _, v in ipairs(Emotes) do
                    if v.Value == SelectedEmote then bedfight.modules.Signals.PlayEmote:Fire(v.Name) break end
                end
                if LoopEnabled then
                    RunLoops:BindToHeartbeat("PlayEmoteLoop", function()
                        for _, v in ipairs(Emotes) do
                            if v.Value == SelectedEmote then bedfight.modules.Signals.PlayEmote:Fire(v.Name) break end
                        end
                    end, 0.1)
                end
            else
                RunLoops:UnbindFromHeartbeat("PlayEmoteLoop")
                if not AnimSpoof.Enabled then
                    for _, entry in ipairs(_Original) do entry.config.Id = entry.id end
                end
            end
        end
    })

    PlayEmote.CreateDropdown({
        Name = "Emote",
        List = (function() local t = {} for _, v in ipairs(Emotes) do table.insert(t, v.Value) end return t end)(),
        Default = Emotes[1] and Emotes[1].Value or "",
        Function = function(callback)
            SelectedEmote = callback
            if PlayEmote.Enabled then
                for _, v in ipairs(Emotes) do
                    if v.Value == callback then bedfight.modules.Signals.PlayEmote:Fire(v.Name) break end
                end
            end
        end
    })

    PlayEmote.CreateToggle({
        Name = "Loop Emote",
        Default = false,
        Function = function(callback)
            LoopEnabled = callback
            if callback and PlayEmote.Enabled then
                RunLoops:BindToHeartbeat("PlayEmoteLoop", function()
                    for _, v in ipairs(Emotes) do
                        if v.Value == SelectedEmote then bedfight.modules.Signals.PlayEmote:Fire(v.Name) break end
                    end
                end, 0.1)
            else
                RunLoops:UnbindFromHeartbeat("PlayEmoteLoop")
            end
        end
    })

    UISpoof = PlayEmote.CreateToggle({
        Name = "UI Spoof",
        Default = false,
        Function = function(callback)
            if callback then
                for _, plr in ipairs(Players:GetPlayers()) do
                    local char = plr.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, child in ipairs(hrp:GetChildren()) do
                            if child:IsA("BillboardGui") then child:Destroy() end
                        end
                    end
                end
                popupConn = workspace.DescendantAdded:Connect(function(desc)
                    if not UISpoof.Enabled then return end
                    if desc:IsA("BillboardGui") then
                        local parent = desc.Parent
                        if parent and parent.Name == "HumanoidRootPart" then
                            desc:Destroy()
                        end
                    end
                end)
            else
                if popupConn then popupConn:Disconnect(); popupConn = nil end
            end
        end
    })
    AnimSpoof = PlayEmote.CreateToggle({
        Name = "Sound Spoof",
        Default = true,
        Function = function(callback)
            if callback then
                for _, entry in ipairs(_Original) do entry.config.Id = "rbxassetid://0" end
            else
                for _, entry in ipairs(_Original) do entry.config.Id = entry.id end
            end
        end
    })

    SelectedEmote = Emotes[1] and Emotes[1].Value or nil
end)

runcode(function()
    local SpoofBtn = {}
    local RanksData = require(ReplicatedStorage.Modules.DataModules.RanksData)
    local rankNames = {}
    for _, r in ipairs(RanksData.Ranks) do table.insert(rankNames, r.Name) end

    local lbHookRef = nil
    local lbRemote = ReplicatedStorage.Remotes:FindFirstChild("UpdateLeaderboardRanking")
    local nameSpoofActive = false
    local spoofName = "wynnech"
    local nsConns = {}
    local nsTagConns = {}
    local nsRankConns = {}
    local rankSpoofActive = false
    local biEntries = {}
    local boardInjectActive = false
    local spoofBtnEnabled = false
    local lbSpoofToggle = {}
    local rankSpoofToggle = {}
    local nameSpoofToggle = {}
    local boardInjectToggle = {}
    local LbRank, LbScore, RankDrop, BiRankPos, BiScore, BiRankDrop, NameTagTextBox
    local playerSet = {}
    for _, p in ipairs(Players:GetPlayers()) do playerSet[p] = true end
    Players.PlayerAdded:Connect(function(p) playerSet[p] = true end)
    Players.PlayerRemoving:Connect(function(p) playerSet[p] = nil end)

    local nsIndexHook
    nsIndexHook = hookmetamethod(game, "__index", function(self, key)
        if nameSpoofActive
            and (key == "Name" or key == "DisplayName")
            and playerSet[self]
            and not checkcaller() then
            return spoofName
        end
        return nsIndexHook(self, key)
    end)

    local nameListCache = {}
    local nameCacheDirty = true
    Players.PlayerAdded:Connect(function()   nameCacheDirty = true end)
    Players.PlayerRemoving:Connect(function() nameCacheDirty = true end)

    local getNameList = function()
        if not nameCacheDirty then return nameListCache end
        nameCacheDirty = false
        local seen, list = {}, {}
        for _, plr in ipairs(Players:GetPlayers()) do
            for _, n in ipairs({plr.Name, plr.DisplayName}) do
                if n and n ~= "" and not seen[n] then
                    seen[n] = true
                    table.insert(list, n)
                end
            end
        end
        nameListCache = list
        return list
    end

    local replaceLabel = function(label, nameList)
        local ok, t = pcall(function() return label.Text end)
        if not ok or t == "" then return end
        for _, name in ipairs(nameList) do
            if #name >= 3 and t:lower() == name:lower() then
                pcall(function() label.Text = spoofName end)
                return
            end
        end
    end

    local cachedHidden = (hidden and hidden()) or nil

    local safeClone = function(src)
        local ok, r = pcall(function() return src:Clone() end)
        return ok and r or nil
    end

    local getRankedListFrame = function()
        local board = workspace:FindFirstChild("Lobby")
        board = board and board:FindFirstChild("Ranked")
        board = board and board:FindFirstChild("Leaderboard")
        if not board then return nil end
        local lf = board:FindFirstChild("LeaderboardGui")
        lf = lf and lf:FindFirstChild("LeaderboardScrollingFrame")
        lf = lf and lf:FindFirstChild("LeaderboardListFrame")
        return lf
    end

    local injectRankedBoard = function()
        task.spawn(function()
            local lf = getRankedListFrame()
            if not lf or not boardInjectActive then return end

            local tmpl = nil
            for _ = 1, 10 do
                if not boardInjectActive then return end
                for _, c in ipairs(lf:GetChildren()) do
                    if (c:IsA("Frame") or c:IsA("ImageLabel")) and c.Name ~= "__spoofEntry" then
                        tmpl = c
                        break
                    end
                end
                if tmpl then break end
                task.wait(0.5)
            end
            if not tmpl or not boardInjectActive then return end
            local old = lf:FindFirstChild("__spoofEntry")
            if old then old:Destroy() end
            local entry = safeClone(tmpl)
            if not entry then return end
            entry.Name = "__spoofEntry"
            entry.LayoutOrder = (BiRankPos and BiRankPos.Value or 1) - 1
            local score = BiScore    and BiScore.Value    or 9999
            local iconName = BiRankDrop and BiRankDrop.Value or RanksData.GetRank(score)
            local rankData = RanksData.UnorderedRanks[iconName]
            pcall(function() entry.UsernameLabel.Text = "@" .. spoofName end)
            pcall(function() entry.DisplayNameLabel.Text = spoofName end)
            pcall(function() entry.RankPointsLabel.Text = tostring(score) end)
            pcall(function() entry.RankLabel.Text = "#" .. (BiRankPos and BiRankPos.Value or 1) end)
            pcall(function() entry.RankIcon.Image = rankData and rankData.Image or "" end)
            entry.Parent = lf
            table.insert(biEntries, entry)
        end)
    end

    local injectLobbyBoards = function()
        local lb = workspace:FindFirstChild("Lobby")
        lb = lb and lb:FindFirstChild("Leaderboards")
        if not lb then return end
        for _, typeFolder in ipairs(lb:GetChildren()) do
            for _, board in ipairs(typeFolder:GetChildren()) do
                local sf = board:FindFirstChild("Board")
                sf = sf and sf:FindFirstChild("BoardGui")
                sf = sf and sf:FindFirstChild("ScrollingFrame")
                if sf then
                    local eName = "__spoof" .. lplr.UserId
                    local old = sf:FindFirstChild(eName)
                    if old then old:Destroy() end
                    local tmpl = nil
                    for _, c in ipairs(sf:GetChildren()) do
                        if c:IsA("Frame") then tmpl = c; break end
                    end
                    if tmpl then
                        local e = safeClone(tmpl)
                        if e then
                            e.Name = eName
                            e.LayoutOrder = -9999
                            local pos = BiRankPos and BiRankPos.Value or 1
                            local score = BiScore   and BiScore.Value   or 9999
                            pcall(function() e.NameLabel.Text = spoofName end)
                            pcall(function() e.RankLabel.Text = "#" .. pos end)
                            pcall(function() e.ValueLabel.Text = tostring(score) end)
                            e.Parent = sf
                            table.insert(biEntries, e)
                        end
                    end
                end
                local botFrame = board:FindFirstChild("Bottom")
                botFrame = botFrame and botFrame:FindFirstChild("BottomGui")
                botFrame = botFrame and botFrame:FindFirstChild("Frame")
                if botFrame then
                    local pos = BiRankPos and BiRankPos.Value or 1
                    local score = BiScore   and BiScore.Value   or 9999
                    pcall(function() botFrame.TextLabel.Text = "#" .. pos .. " You:" end)
                    pcall(function() botFrame.ValueLabel.Text = tostring(score) end)
                end
            end
        end
    end

    local clearBoardEntries = function()
        for _, e in ipairs(biEntries) do pcall(function() e:Destroy() end) end
        table.clear(biEntries)
    end

    SpoofBtn = GuiLibrary.Registry.miscPanel.API.CreateOptionsButton({
        Name = "StreamerMode",
        Function = function(callback)
            spoofBtnEnabled = callback == true
            local state = spoofBtnEnabled
            if lbSpoofToggle.Enabled then
                task.spawn(lbSpoofToggle.Function, state)
            end
            if rankSpoofToggle.Enabled then
                task.spawn(rankSpoofToggle.Function, state)
            end
            if nameSpoofToggle.Enabled then
                task.spawn(nameSpoofToggle.Function, state)
            end
            if boardInjectToggle.Enabled then
                task.spawn(boardInjectToggle.Function, state)
            end
        end
    })

    lbSpoofToggle = SpoofBtn.CreateToggle({
        Name = "Leaderboard Spoof",
        Default = false,
        Function = function(callback)
            if callback then
                if lbRemote and not lbHookRef then
                    local conns = getconnections(lbRemote.OnClientEvent)
                    if conns and conns[1] and conns[1].Function then
                        lbHookRef = hookfunction(conns[1].Function, newcclosure(function(p21, p22, p23, p24)
                            return lbHookRef(p21, p22, LbRank.Value, LbScore.Value)
                        end))
                    end
                end
            else
                if lbHookRef then
                    local conns = lbRemote and getconnections(lbRemote.OnClientEvent)
                    if conns and conns[1] and conns[1].Function then
                        hookfunction(conns[1].Function, lbHookRef)
                    end
                    lbHookRef = nil
                end
            end
        end
    })
    LbRank = SpoofBtn.CreateSlider({
        Name = "LB Rank #",
        Min = 1,
        Max = 100,
        Default = 1,
        Round = 1,
    })
    LbScore = SpoofBtn.CreateSlider({
        Name = "LB Score",
        Min = 0,
        Max = 9999,
        Default = 9999,
        Round = 1,
    })
    lbSpoofToggle:AddDependent(LbRank)
    lbSpoofToggle:AddDependent(LbScore)

    local hookRankIcon = function(icon)
        if not icon then return end
        local rankData = RanksData.UnorderedRanks[RankDrop and RankDrop.Value or ""]
        if rankData then icon.Image = rankData.Image end
        local conn = icon:GetPropertyChangedSignal("Image"):Connect(function()
            if rankSpoofActive then
                local rd = RanksData.UnorderedRanks[RankDrop and RankDrop.Value or ""]
                if rd and icon.Image ~= rd.Image then icon.Image = rd.Image end
            end
        end)
        table.insert(nsRankConns, conn)
    end

    local hookAllRankIcons = function()
        local pg = lplr.PlayerGui
        local gui = pg and pg:FindFirstChild("PlayersNameTagGui")
        if not gui then return end
        local char = lplr.Character
        local head = char and char:FindFirstChild("Head")
        for _, tag in ipairs(gui:GetChildren()) do
            if tag:IsA("BillboardGui") and tag.Adornee == head then
                local bottom = tag:FindFirstChild("BottomFrame")
                hookRankIcon(bottom and bottom:FindFirstChild("RankIcon"))
            end
        end
    end

    rankSpoofToggle = SpoofBtn.CreateToggle({
        Name = "Rank Spoof",
        Default = false,
        Function = function(callback)
            rankSpoofActive = callback
            if callback then
                hookAllRankIcons()
            else
                for _, c in ipairs(nsRankConns) do pcall(function() c:Disconnect() end) end
                table.clear(nsRankConns)
                pcall(function()
                    local pg = lplr.PlayerGui
                    local gui = pg and pg:FindFirstChild("PlayersNameTagGui")
                    if not gui then return end
                    for _, tag in ipairs(gui:GetChildren()) do
                        local bottom = tag:FindFirstChild("BottomFrame")
                        local icon = bottom and bottom:FindFirstChild("RankIcon")
                        if icon then icon.Image = "" end

                    end
                end)
            end
        end
    })
    RankDrop = SpoofBtn.CreateDropdown({
        Name = "Rank",
        List = rankNames,
        Default = rankNames[#rankNames] or "Crystal III",
        Function = function(val)
            if not rankSpoofActive then return end
            local rankData = RanksData.UnorderedRanks[val]
            if not rankData then return end
            local pg = lplr.PlayerGui
            local gui = pg and pg:FindFirstChild("PlayersNameTagGui")
            if not gui then return end
            local char = lplr.Character
            local head = char and char:FindFirstChild("Head")
            for _, tag in ipairs(gui:GetChildren()) do
                if tag:IsA("BillboardGui") and tag.Adornee == head then
                    local bottom = tag:FindFirstChild("BottomFrame")
                    local icon = bottom and bottom:FindFirstChild("RankIcon")
                    if icon then icon.Image = rankData.Image end
                end
            end
        end,
    })
    rankSpoofToggle:AddDependent(RankDrop)
    local hookTagLabel = function(label)
        if not label or not label:IsA("TextLabel") then return end
        label.Text = spoofName
        local conn = label:GetPropertyChangedSignal("Text"):Connect(function()
            if nameSpoofActive and label.Text ~= spoofName then
                label.Text = spoofName
            end
        end)
        table.insert(nsTagConns, conn)
    end

    local hookAllTags = function()
        local pg = lplr.PlayerGui
        local gui = pg and pg:FindFirstChild("PlayersNameTagGui")
        if not gui then return end
        for _, tag in ipairs(gui:GetChildren()) do
            local bottom = tag:FindFirstChild("BottomFrame")
            hookTagLabel(bottom and bottom:FindFirstChild("NameLabel"))
        end
    end

    nameSpoofToggle = SpoofBtn.CreateToggle({
        Name = "Name Spoof",
        Default = false,
        Function = function(callback)
            nameSpoofActive = callback
            _G.phantomNameSpoofActive = callback
            _G.phantomSpoofName = spoofName
            if callback then
                local nl = getNameList()
                local coreGui = game:GetService("CoreGui")
                hookAllTags()
                local pg = lplr.PlayerGui
                local gui = pg and pg:FindFirstChild("PlayersNameTagGui")
                if gui then
                    nsConns[3] = gui.ChildAdded:Connect(function(tag)
                        task.defer(function()
                            if not nameSpoofActive then return end
                            local bottom = tag:FindFirstChild("BottomFrame")
                                or tag:WaitForChild("BottomFrame", 2)
                            hookTagLabel(bottom and bottom:FindFirstChild("NameLabel"))
                        end)
                    end)
                end
                if cachedHidden then
                    for _, child in ipairs(cachedHidden:GetChildren()) do
                        if child.Name == "PhantomNameTags" then
                            for _, desc in ipairs(child:GetDescendants()) do
                                if desc:IsA("TextLabel") then replaceLabel(desc, nl) end
                            end
                        end
                    end
                end
                nsConns[1] = lplr.PlayerGui.DescendantAdded:Connect(function(desc)
                    if not nameSpoofActive then return end
                    if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                        task.defer(function()
                            if not nameSpoofActive then return end
                            replaceLabel(desc, getNameList())
                        end)
                    end
                end)
                pcall(function()
                    nsConns[2] = coreGui.DescendantAdded:Connect(function(desc)
                        if not nameSpoofActive then return end
                        if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                            task.defer(function()
                                if not nameSpoofActive then return end
                                replaceLabel(desc, getNameList())
                            end)
                        end
                    end)
                end)
            else
                for _, c in ipairs(nsConns) do pcall(function() c:Disconnect() end) end
                table.clear(nsConns)
                for _, c in ipairs(nsTagConns) do pcall(function() c:Disconnect() end) end
                table.clear(nsTagConns)
                pcall(function()
                    local pg = lplr.PlayerGui
                    local gui = pg and pg:FindFirstChild("PlayersNameTagGui")
                    if not gui then return end
                    for _, tag in ipairs(gui:GetChildren()) do
                        local bottom = tag:FindFirstChild("BottomFrame")
                        local label = bottom and bottom:FindFirstChild("NameLabel")
                        if label then
                            local char = tag.Adornee and tag.Adornee.Parent
                            local plr = char and Players:GetPlayerFromCharacter(char)
                            if plr then
                                label.Text = plr.DisplayName ~= "" and plr.DisplayName or plr.Name
                            end
                        end
                    end
                end)
            end
        end
    })
    NameTagTextBox = SpoofBtn.CreateTextbox({
        Name = "Spoof Name",
        Default = "wynnech",
        Function = function(val)
            spoofName = (val and val ~= "") and val or "wynnech"
            _G.phantomSpoofName = spoofName
            if nameSpoofActive then
                local pg = lplr.PlayerGui
                local gui = pg and pg:FindFirstChild("PlayersNameTagGui")
                if gui then
                    for _, tag in ipairs(gui:GetChildren()) do
                        local bottom = tag:FindFirstChild("BottomFrame")
                        local label = bottom and bottom:FindFirstChild("NameLabel")
                        if label then label.Text = spoofName end
                    end
                end
                nameCacheDirty = true
            end
            if boardInjectActive then
                clearBoardEntries()
                injectRankedBoard()
                injectLobbyBoards()
            end
        end,
    })
    nameSpoofToggle:AddDependent(NameTagTextBox)

    boardInjectToggle = SpoofBtn.CreateToggle({
        Name = "Board Inject",
        Default = false,
        Function = function(callback)
            if callback then
                boardInjectActive = true
                clearBoardEntries()
                injectRankedBoard()
                injectLobbyBoards()
                RunLoops:BindToHeartbeat("BoardInject", function()
                    local lf = getRankedListFrame()
                    if lf and not lf:FindFirstChild("__spoofEntry") then
                        injectRankedBoard()
                    end
                end, 3)
            else
                boardInjectActive = false
                RunLoops:UnbindFromHeartbeat("BoardInject")
                clearBoardEntries()
            end
        end
    })
    BiRankPos = SpoofBtn.CreateSlider({
        Name = "Board Pos",
        Min = 1,
        Max = 100,
        Default = 1,
        Round = 1,
        Function = function()
            if not boardInjectActive then return end
            clearBoardEntries()
            injectRankedBoard()
            injectLobbyBoards()
        end,
    })
    BiScore = SpoofBtn.CreateSlider({
        Name = "Board Score",
        Min = 0,
        Max = 20000,
        Default = 9999,
        Round = 1,
        Function = function()
            if not boardInjectActive then return end
            clearBoardEntries()
            injectRankedBoard()
            injectLobbyBoards()
        end,
    })
    BiRankDrop = SpoofBtn.CreateDropdown({
        Name = "Board Rank Icon",
        List = rankNames,
        Default = "Crystal III",
        Function = function(val)
            if not boardInjectActive then return end
            local lf = getRankedListFrame()
            local entry = lf and lf:FindFirstChild("__spoofEntry")
            if entry then
                local rankData = RanksData.UnorderedRanks[val]
                pcall(function() entry.RankIcon.Image = rankData and rankData.Image or "" end)
            end
        end,
    })
    boardInjectToggle:AddDependent(BiRankPos)
    boardInjectToggle:AddDependent(BiScore)
    boardInjectToggle:AddDependent(BiRankDrop)
end)

runcode(function()
    repeat task.wait(1) until lplr.PlayerGui:FindFirstChild("TopbarButtonsGui")

    local ServerHop = {}
    local hopCount = 0
    local cfgPath = "Phantom/storage/config/serverHop.json"

    local safeJSONDecode = function(str)
        if type(str) ~= "string" or str == "" then
            return nil
        end

        local ok, result = pcall(function()
            return HttpService:JSONDecode(str)
        end)
        if ok and type(result) == "table" then
            return result
        end

        local ok2, result2 = pcall(function()
            return game:GetService("HttpService"):JSONDecode(tostring(str))
        end)
        if ok2 and type(result2) == "table" then
            return result2
        end

        local cleaned = tostring(str):gsub("^\239\187\191", ""):gsub("^%s+", ""):gsub("%s+$", "")
        local ok3, result3 = pcall(function()
            return HttpService:JSONDecode(cleaned)
        end)
        if ok3 and type(result3) == "table" then
            return result3
        end

        return nil
    end

    local readConfig = function()
        local cfg = {}
        pcall(function()
            if isfile(cfgPath) then
                cfg = safeJSONDecode(readfile(cfgPath)) or {}
            end
        end)
        return cfg
    end

    local saveConfig = function(enabled, totalHops, extraFields)
        pcall(function()
            local path = "Phantom/storage/config"
            if not isfolder(path) then
                makefolder(path)
            end
            local cfg = isfile(cfgPath) and (safeJSONDecode(readfile(cfgPath)) or {}) or {}
            cfg.serverHopEnabled = enabled
            cfg.totalHops = totalHops or hopCount or 0
            cfg.lastUpdated = os.time()
            if extraFields then
                for k, v in pairs(extraFields) do
                    cfg[k] = v
                end
            end
            writefile(cfgPath, HttpService:JSONEncode(cfg))
        end)
    end

    local serverListFolder = "Phantom/storage/configs"
    local serverListPath = serverListFolder .. "/" .. tostring(game.PlaceId)
    local _cacheIndex = 0

    local saveServerCache = function(jobId, servers)
        pcall(function()
            if not isfolder(serverListFolder) then
                makefolder(serverListFolder)
            end
            local entry = {
                jobId = jobId,
                servers = servers,
                saved = os.time(),
            }
            writefile(serverListPath, HttpService:JSONEncode(entry))
        end)
        _cacheIndex = 0
    end

    local clearServerCache = function()
        pcall(function()
            if isfile(serverListPath) then
                writefile(serverListPath, "")
            end
        end)
        _cacheIndex = 0
    end

    local getNextCachedServer = function()
        local entry
        pcall(function()
            if isfile(serverListPath) then
                entry = safeJSONDecode(readfile(serverListPath))
            end
        end)
        if not entry or not entry.servers or #entry.servers == 0 then return nil end
        _cacheIndex = _cacheIndex + 1
        if _cacheIndex > #entry.servers then _cacheIndex = 1 end
        local id = entry.servers[_cacheIndex]
        if id and id ~= game.JobId then return id end
        return nil
    end

    local lowPingEnabled = {Value = false}
    local LOW_PING_MAX = 80

    local doHop = function()
        local available = {}
        local fromCache = false

        local ok, raw = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&exclude=partiallyFull&limit=100")
        end)

        if ok and raw then
            local decoded = safeJSONDecode(raw)
            if decoded and decoded.data then
                local allIds = {}
                local servers = {}
                for _, s in ipairs(decoded.data) do
                    if s.id and type(s.playing) == "number" and type(s.maxPlayers) == "number" and s.playing < s.maxPlayers and s.playing > 0 then
                        table.insert(allIds, s.id)
                        if s.id ~= game.JobId then
                            table.insert(servers, s)
                        end
                    end
                end

                if lowPingEnabled.Value and #servers > 0 then
                    table.sort(servers, function(a, b)
                        local pa = type(a.ping) == "number" and a.ping or math.huge
                        local pb = type(b.ping) == "number" and b.ping or math.huge
                        return pa < pb
                    end)
                    for _, s in ipairs(servers) do
                        local ping = type(s.ping) == "number" and s.ping or math.huge
                        if ping <= LOW_PING_MAX then
                            table.insert(available, s.id)
                        end
                    end
                    if #available == 0 then
                        table.insert(available, servers[1].id)
                        createNotification("ServerHop", "No server under " .. LOW_PING_MAX .. "ms — using best ping.", 2)
                    end
                else
                    for _, s in ipairs(servers) do
                        table.insert(available, s.id)
                    end
                end

                if #allIds > 0 then
                    saveServerCache(game.JobId, allIds)
                end
            else
                createNotification("ServerHop", "Failed to decode server list — using cache.", 3)
            end
        else
            createNotification("ServerHop", "Failed to fetch servers — using cache.", 3)
        end

        if #available == 0 then
            local id = getNextCachedServer()
            if id then
                table.insert(available, id)
                fromCache = true
            end
        end

        if #available == 0 then
            createNotification("ServerHop", "No valid servers found, retrying.", 3)
            return false
        end

        hopCount = hopCount + 1
        saveConfig(true, hopCount)
        local label = fromCache and " (cached)" or (lowPingEnabled.Value and " (low ping)" or "")
        createNotification("ServerHop", "Hop #" .. hopCount .. label .. " | " .. #available .. " servers available", 2)
        task.wait(1)

        local targetId = fromCache and available[1] or available[math.random(1, #available)]
        local tok, terr = pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, targetId, lplr)
        end)
        if not tok then
            createNotification("ServerHop", "Teleport failed: " .. tostring(terr), 3)
            saveConfig(true, hopCount)
            return false
        end
        return true
    end

    local stopHop = function(reason)
        RunLoops:UnbindFromHeartbeat("ServerHopCheck")
        createNotification("ServerHop", "Found! " .. reason .. " | Hops: " .. hopCount, 5)
        saveConfig(false, hopCount)
        if ServerHop.Enabled then
            ServerHop.Toggle()
        end
    end

    ServerHop = GuiLibrary.Registry.miscPanel.API.CreateOptionsButton({
        Name = "ServerHop",
        New = true,
        Function = function(callback)
            if callback then
                local cfg = readConfig()
                hopCount = tonumber(cfg.totalHops) or 0
                saveConfig(true, hopCount)
                createNotification("ServerHop", "Started - scanning server. | Total hops: " .. hopCount, 3)

                local cooldown = false
                RunLoops:BindToHeartbeat("ServerHopCheck", function()
                    if cooldown then
                        return
                    end

                    if data.matchState ~= 0 then
                        stopHop("valid server")
                        return
                    end

                    cooldown = true
                    task.spawn(function()
                        task.wait(1.5)
                        if not doHop() then
                            task.wait(3)
                            cooldown = false
                        end
                    end)
                end)
            else
                saveConfig(false, hopCount)
                clearServerCache()
                createNotification("ServerHop", "Disabled | Total hops: " .. hopCount, 3)
                RunLoops:UnbindFromHeartbeat("ServerHopCheck")
            end
        end
    })

    lowPingEnabled = ServerHop.CreateToggle({
        Name = "Low Ping Servers",
        Default = false,
        Function = function(on)
            lowPingEnabled.Value = on
        end,
    })

    task.spawn(function()
        pcall(function()
            local cfg = readConfig()
            hopCount = tonumber(cfg.totalHops) or 0
            if cfg and cfg.serverHopEnabled then
                task.wait(2)
                createNotification("ServerHop", "Config restored | Total hops: " .. hopCount, 2)
            end
        end)
    end)
end)

-- runcode(function()
--     local CFspeed = 50
--     local CFloop = nil

--     local _findPos = function()
--         local char = lplr.Character
--         local params = RaycastParams.new()
--         params.FilterType = Enum.RaycastFilterType.Exclude
--         params.FilterDescendantsInstances = char and {char} or {}

--         local safeY = function(pos)
--             local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + 60, pos.Z), Vector3.new(0, -120, 0), params)
--             if hit and hit.Position.Y > -20 then return hit.Position + Vector3.new(0, 5, 0) end
--             return nil
--         end

--         local bedsContainer = workspace:FindFirstChild("BedsContainer")
--         if bedsContainer then
--             for _, bed in ipairs(bedsContainer:GetChildren()) do
--                 for _, part in ipairs(bed:GetDescendants()) do
--                     if part:IsA("BasePart") and part.Position.Y > -10 then
--                         local p = safeY(part.Position)
--                         if p then return p end
--                     end
--                 end
--             end
--         end

--         local pbContainer = workspace:FindFirstChild("PlayersBlocksContainer")
--         if pbContainer then
--             for _, team in ipairs(pbContainer:GetChildren()) do
--                 for _, part in ipairs(team:GetDescendants()) do
--                     if part:IsA("BasePart") and part.Position.Y > -10 then
--                         local p = safeY(part.Position)
--                         if p then return p end
--                     end
--                 end
--             end
--         end

--         for _, p in ipairs(Players:GetPlayers()) do
--             if p ~= lplr and p.Character then
--                 local hrp = p.Character:FindFirstChild("HumanoidRootPart")
--                 if hrp and hrp.Position.Y > -10 then return hrp.Position + Vector3.new(0, 4, 0) end
--             end
--         end

--         return nil
--     end

--     GuiLibrary.Registry.blatantPanel.API.CreateOptionsButton({
--         Name = "Creative(blocks)",
--         New = true,
--         Function = function(callback)
--             local char = lplr.Character
--             if not char then return end
--             local hum = char:FindFirstChildOfClass("Humanoid")
--             local Head = char:FindFirstChild("Head")
--             if not hum or not Head then return end
--             if callback then
--                 local pos = _findPos()
--                 if pos then
--                     local hrp = char:FindFirstChild("HumanoidRootPart")
--                     if hrp then hrp.CFrame = CFrame.new(pos) end
--                 else
--                     createNotification("CreativeMode", "No map position found — place yourself manually", 3)
--                 end
--                 hum.PlatformStand = true
--                 Head.Anchored = true
--                 if CFloop then CFloop:Disconnect() end
--                 CFloop = RunService.Heartbeat:Connect(function(dt)
--                     local moveDir = hum.MoveDirection * (CFspeed * dt)
--                     local hCF = Head.CFrame
--                     local cam = Camera.CFrame
--                     local offset = hCF:ToObjectSpace(cam).Position
--                     local flatCam = cam * CFrame.new(-offset.X, -offset.Y, -offset.Z + 1)
--                     local vel = CFrame.new(flatCam.Position, Vector3.new(hCF.Position.X, flatCam.Position.Y, hCF.Position.Z)):VectorToObjectSpace(moveDir)
--                     Head.CFrame = CFrame.new(hCF.Position) * (flatCam - flatCam.Position) * CFrame.new(vel)
--                 end)
--             else
--                 if CFloop then CFloop:Disconnect(); CFloop = nil end
--                 hum.PlatformStand = false
--                 Head.Anchored = false
--             end
--         end
--     })
-- end)

runcode(function()
    local Knockback = {}

    local KBPower = {Value = 80}
    local KBDuration = {Value = 0.15}
    local KBMode = {Value = "Backward"}

    Knockback = GuiLibrary.Registry.utillityPanel.API.CreateOptionsButton({
        Name = "Knockback",
        New = true,
        Function = function(callback)
            if not callback then return end
            local char = lplr.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local look = Camera.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            flat = flat.Magnitude > 0.001 and flat.Unit or hrp.CFrame.LookVector
            local dir
            if KBMode.Value == "Forward" then
                dir = (flat + Vector3.new(0, 0.3, 0)).Unit
            elseif KBMode.Value == "Up" then
                dir = Vector3.new(0, 1, 0)
            else
                dir = (-flat + Vector3.new(0, 0.35, 0)).Unit
            end
            bedfight.modules.VelocityUtils.Create(hrp, dir * KBPower.Value, KBDuration.Value)
            task.wait(KBDuration.Value)
            hrp.AssemblyLinearVelocity = Vector3.zero
            Knockback.Toggle()
        end
    })

    KBPower = Knockback.CreateSlider({
        Name = "Power",
        Min = 10, 
        Max = 300, 
        Default = 80,
        Function = function(callback) KBPower.Value = callback end
    })

    KBDuration = Knockback.CreateSlider({
        Name = "Duration",
        Min = 0.05, 
        Max = 1, 
        Default = 0.15,
        Function = function(callback) KBDuration.Value = callback end
    })

    KBMode = Knockback.CreateDropdown({
        Name = "Direction",
        List = {"Backward", "Forward", "Up"},
        Default = "Backward",
        Function = function(callback) KBMode.Value = callback end
    })
end)


runcode(function()
    local itemBBs = {}
    local itemTracked = {}
    local itemConns = {}
    local ItemBtn, ItemColor, ItemRarity, ItemShowName, ItemShowDist, ItemShowId, ItemMaxDist, ItemSize, ItemBg, ItemCorner

    local ITEM_COLS = {
        emerald = Color3.fromRGB(50,220,80),
        diamond = Color3.fromRGB(60,200,220),
        gold = Color3.fromRGB(255,200,0),
        iron = Color3.new(1,1,1),
    }
    local function itemColor(name)
        if ItemRarity and not ItemRarity.Enabled then return pcol(ItemColor) end
        local n = name:lower()
        for k, c in pairs(ITEM_COLS) do if n:find(k) then return c end end
        return pcol(ItemColor)
    end
    local function makeBB(model, sz)
        local bb = Instance.new("BillboardGui")
        bb.Name = "PhantomItemESP"
        bb.AlwaysOnTop = true
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        local bg = Instance.new("Frame")
        bg.Size = UDim2.fromScale(1,1)
        bg.BorderSizePixel = 0
        bg.BackgroundColor3 = Color3.fromRGB(10,10,10)
        bg.BackgroundTransparency = 1
        local bgcr = Instance.new("UICorner", bg)
        bgcr.CornerRadius = UDim.new(0, 5)
        bg.Parent = bb
        local nameLbl = Instance.new("TextLabel")
        nameLbl.BackgroundTransparency = 1
        nameLbl.BorderSizePixel = 0
        nameLbl.Font = Enum.Font.GothamSemibold
        nameLbl.TextSize = 11
        nameLbl.TextStrokeTransparency = 0.5
        nameLbl.TextColor3 = Color3.new(1,1,1)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = bg
        local distLbl = Instance.new("TextLabel")
        distLbl.BackgroundTransparency = 1
        distLbl.BorderSizePixel = 0
        distLbl.Font = Enum.Font.GothamSemibold
        distLbl.TextSize = 11
        distLbl.TextStrokeTransparency = 0.5
        distLbl.TextColor3 = Color3.new(1,1,1)
        distLbl.TextXAlignment = Enum.TextXAlignment.Right
        distLbl.Parent = bg
        bb.Parent = model
        return bb, bg, bgcr, nameLbl, distLbl
    end

    ItemBtn = GuiLibrary.Registry.renderPanel.API.CreateOptionsButton({
        Name = "ItemESP",
        Function = function(callback)
            if callback then
                local cont = workspace:FindFirstChild("DroppedItemsContainer")
                local function trackItem(obj)
                    if obj:IsA("Model") then itemTracked[obj] = true end
                end
                if cont then
                    for _, obj in ipairs(cont:GetChildren()) do trackItem(obj) end
                    table.insert(itemConns, cont.ChildAdded:Connect(trackItem))
                    table.insert(itemConns, cont.ChildRemoved:Connect(function(obj) itemTracked[obj] = nil end))
                end

                local lqN = 0
                RunLoops:BindToHeartbeat("ItemESP", function()
                    lqN += 1; if lqN % 2 ~= 0 then return end
                    local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                    local maxD = ItemMaxDist  and ItemMaxDist.Value  or 100
                    local showN = ItemShowName and ItemShowName.Enabled
                    local showD = ItemShowDist and ItemShowDist.Enabled
                    local showId = ItemShowId   and ItemShowId.Enabled
                    local sz = ItemSize     and ItemSize.Value      or 100
                    local seen = {}

                    for model in pairs(itemTracked) do
                        if not model.Parent then itemTracked[model] = nil; continue end
                        local hitbox = model:FindFirstChild("Hitbox") or model:FindFirstChildOfClass("BasePart")
                        if not hitbox then continue end
                        local dist = myRoot and (myRoot.Position - hitbox.Position).Magnitude or 0
                        if dist > maxD then
                            local old = itemBBs[model]
                            local bb2 = type(old) == "table" and old.bb or old
                            if bb2 and bb2.Parent then bb2:Destroy() end
                            itemBBs[model] = nil
                            continue
                        end
                        seen[model] = true

                        if not itemBBs[model] then
                            local _bb, _bg, _bgcr, _nL, _dL = makeBB(model, sz)
                            itemBBs[model] = {bb=_bb, bg=_bg, bgcr=_bgcr, nameLbl=_nL, distLbl=_dL}
                        end
                        local entry = itemBBs[model]
                        local col = itemColor(model.Name)
                        local ts = math.clamp(math.floor(sz / 9), 9, 16)
                        entry.bg.BackgroundTransparency = (ItemBg and ItemBg.Enabled) and 0.35 or 1
                        entry.bgcr.CornerRadius = UDim.new(0, (ItemCorner and ItemCorner.Value == "Square") and 0 or 5)
                        entry.nameLbl.TextSize = ts
                        entry.distLbl.TextSize = ts
                        entry.nameLbl.TextColor3 = col

                        local font = Enum.Font.GothamSemibold
                        local rawName = model.Name
                        local displayName = (not showId) and rawName:match("^(.-)_%d+$") or rawName
                        local nameStr = showN and (displayName or rawName) or ""
                        local distStr = showD and ("["..math.floor(dist).."m]") or ""
                        local nameW = showN and measureTextW(nameStr, ts, font) or 0
                        local distW = showD and measureTextW(distStr, ts, font) or 0
                        local pad = 6
                        local gap = (showN and showD) and 5 or 0
                        local totalW = math.max(40, nameW + distW + gap + pad * 2)
                        local h = ts + 8
                        entry.nameLbl.Visible = showN
                        entry.nameLbl.Size = UDim2.new(0, nameW, 1, 0)
                        entry.nameLbl.Position = UDim2.new(0, pad, 0, 0)
                        entry.distLbl.Visible = showD
                        entry.distLbl.Size = UDim2.new(0, distW, 1, 0)
                        entry.distLbl.Position = UDim2.new(0, pad + nameW + gap, 0, 0)
                        entry.nameLbl.Text = nameStr
                        entry.distLbl.Text = distStr
                        entry.bb.Size = UDim2.fromOffset(totalW, h)
                    end
                    for model, entry in pairs(itemBBs) do
                        if not seen[model] or not model.Parent then
                            if entry.bb and entry.bb.Parent then entry.bb:Destroy() end
                            itemBBs[model] = nil
                        end
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("ItemESP")
                for _, c in ipairs(itemConns) do pcall(function() c:Disconnect() end) end
                itemConns = {}
                itemTracked = {}
                for _, entry in pairs(itemBBs) do
                    if entry.bb and entry.bb.Parent then entry.bb:Destroy() end
                end
                itemBBs = {}
            end
        end
    })
    ItemColor = ItemBtn.CreateDropdown({
        Name = "Color",
        List = PHANTOM_COL_LIST,
        Default = "Theme",
        Function = function()end,
    })
    ItemRarity = ItemBtn.CreateToggle({
        Name = "Rarity Color",
        Default = true,
        Function = function()end,
    })
    ItemShowName = ItemBtn.CreateToggle({
        Name = "Show Name",
        Default = true,
        Function = function()end,
    })
    ItemShowDist = ItemBtn.CreateToggle({
        Name = "Show Distance",
        Default = true,
        Function = function()end,
    })
    ItemShowId = ItemBtn.CreateToggle({
        Name = "Show ID",
        Default = false,
        Function = function()end,
    })
    ItemMaxDist = ItemBtn.CreateSlider({
        Name = "Max Distance",
        Min = 20,
        Max = 300,
        Default = 100,
        Round = 1,
    })
    ItemSize = ItemBtn.CreateSlider({
        Name = "Label Size",
        Min = 60,
        Max = 160,
        Default = 100,
        Round = 1,
    })
    ItemBg = ItemBtn.CreateToggle({
        Name = "Background",
        Default = true,
        Function = function()end,
    })
    ItemCorner = ItemBtn.CreateDropdown({
        Name = "Corner Style",
        List = {"Rounded", "Square"},
        Default = "Rounded",
        Function = function()end,
    })
end)

runcode(function()
    local origFogEnd, origFogStart, origFogColor, origBright, origAmbient, origAtmDen, origAtmHaze
    local Lighting = game:GetService("Lighting")
    local AV, AVFog, AVAtmos, AVBoost, AVFogEnd, AVFogColor

    AV = GuiLibrary.Registry.utillityPanel.API.CreateOptionsButton({
        Name = "AntiVision",
        Function = function(callback)
            if callback then
                origFogEnd = Lighting.FogEnd
                origFogStart = Lighting.FogStart
                origFogColor = Lighting.FogColor
                origBright = Lighting.Brightness
                origAmbient = Lighting.Ambient
                local atm = Lighting:FindFirstChildOfClass("Atmosphere")
                if atm then origAtmDen = atm.Density; origAtmHaze = atm.Haze end

                RunLoops:BindToHeartbeat("AntiVision", function()
                    local fogEnd = AVFogEnd and AVFogEnd.Value or 100000
                    if AVFog and AVFog.Enabled then
                        Lighting.FogEnd = fogEnd
                        Lighting.FogStart = fogEnd - 10
                        Lighting.FogColor = Color3.fromRGB(0,0,0)
                    end
                    if AVAtmos and AVAtmos.Enabled then
                        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
                        if atm then atm.Density = 0; atm.Haze = 0 end
                    end
                    if AVBoost and AVBoost.Enabled then
                        Lighting.Brightness = 5
                        Lighting.Ambient = Color3.fromRGB(150,150,150)
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("AntiVision")
                Lighting.FogEnd = origFogEnd or 100000
                Lighting.FogStart = origFogStart or 0
                if origFogColor then Lighting.FogColor = origFogColor end
                if origBright   then Lighting.Brightness = origBright  end
                if origAmbient  then Lighting.Ambient = origAmbient  end
                local atm = Lighting:FindFirstChildOfClass("Atmosphere")
                if atm then
                    if origAtmDen  ~= nil then atm.Density = origAtmDen  end
                    if origAtmHaze ~= nil then atm.Haze = origAtmHaze end
                end
            end
        end
    })
    AVFog = AV.CreateToggle({
        Name = "Remove Fog",
        Default = true,
        Function = function()end,
    })
    AVAtmos = AV.CreateToggle({
        Name = "Clear Atmosphere",
        Default = true,
        Function = function()end,
    })
    AVBoost = AV.CreateToggle({
        Name = "Boost Lighting",
        Default = false,
        Function = function()end,
    })
    AVFogEnd= AV.CreateSlider({
        Name = "Fog Range",
        Min = 1000,
        Max = 200000,
        Default = 100000,
        Round = 1,
    })
end)

runcode(function()
    local warnGui, warnFrame, warnLabel = nil, nil, nil
    local NWBtn, NWDist, NWFlash, NWFlashColor, NWShowLabel, NWShowDist, NWPulse

    NWBtn = GuiLibrary.Registry.miscPanel.API.CreateOptionsButton({
        Name = "NearbyWarn",
        Function = function(callback)
            if callback then
                local pgui = lplr:FindFirstChildOfClass("PlayerGui")
                warnGui = Instance.new("ScreenGui")
                warnGui.Name = "PhantomNearby"
                warnGui.ResetOnSpawn = false
                warnGui.IgnoreGuiInset = true
                warnGui.DisplayOrder = 999998
                warnGui.Parent = pgui or game.CoreGui

                warnFrame = Instance.new("Frame", warnGui)
                warnFrame.Size = UDim2.fromScale(1,1)
                warnFrame.BackgroundColor3 = Color3.fromRGB(255,50,50)
                warnFrame.BackgroundTransparency = 1
                warnFrame.BorderSizePixel = 0

                warnLabel = Instance.new("TextLabel", warnGui)
                warnLabel.Size = UDim2.fromOffset(250, 32)
                warnLabel.AnchorPoint = Vector2.new(0.5, 0)
                warnLabel.Position = UDim2.new(0.5,0,0,72)
                warnLabel.BackgroundColor3 = Color3.fromRGB(12,12,12)
                warnLabel.BackgroundTransparency = 0.2
                warnLabel.TextColor3 = Color3.fromRGB(255,80,80)
                warnLabel.Font = Enum.Font.GothamSemibold
                warnLabel.TextSize = 14
                warnLabel.Text = "! ENEMY NEARBY (fuck him up) !"
                warnLabel.Visible = false
                local corner = Instance.new("UICorner", warnLabel)
                corner.CornerRadius = UDim.new(0,6)
                local stroke = Instance.new("UIStroke", warnLabel)
                stroke.Color = Color3.fromRGB(180,40,40)
                stroke.Thickness = 1.5

                local flashAlpha = 0
                RunLoops:BindToHeartbeat("NearbyWarn", function(dt)
                    local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                    if not myRoot then warnFrame.BackgroundTransparency = 1; warnLabel.Visible = false; return end
                    local dist = NWDist and NWDist.Value or 15
                    local closest, closestD = nil, math.huge

                    for _, v in ipairs(Players:GetPlayers()) do
                        if v == lplr then continue end
                        if v.Team and v.Team == lplr.Team then continue end
                        if not PlayerUtility.IsAlive(v) then continue end
                        local char = v.Character; if not char then continue end
                        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
                        local d = (myRoot.Position - hrp.Position).Magnitude
                        if d < dist and d < closestD then closest = v; closestD = d end
                    end

                    if closest then
                        flashAlpha = math.min(flashAlpha + dt*6, 0.22)
                        local fc = pcol(NWFlashColor)
                        local pulse = NWPulse and NWPulse.Enabled
                            and (1 - flashAlpha * math.abs(math.sin(tick() * 8))) or 1 - flashAlpha
                        if NWFlash and NWFlash.Enabled then
                            warnFrame.BackgroundColor3 = fc
                            warnFrame.BackgroundTransparency = pulse
                        else warnFrame.BackgroundTransparency = 1 end
                        if NWShowLabel and NWShowLabel.Enabled then
                            warnLabel.Visible = true
                            if NWShowDist and NWShowDist.Enabled then
                                warnLabel.Text = "!  "..closest.DisplayName.."  "..math.floor(closestD).."m (fuck him up)  !"
                            else warnLabel.Text = "! ENEMY NEARBY (fuck him up) !" end
                        else warnLabel.Visible = false end
                    else
                        flashAlpha = math.max(flashAlpha - dt*4, 0)
                        warnFrame.BackgroundTransparency = 1
                        warnLabel.Visible = false
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("NearbyWarn")
                if warnGui then warnGui:Destroy(); warnGui = nil end
                warnFrame = nil
                warnLabel = nil
            end
        end
    })
    NWDist = NWBtn.CreateSlider({
        Name = "Warn Distance",
        Min = 5,
        Max = 60,
        Default = 15,
        Round = 1,
    })
    NWFlash = NWBtn.CreateToggle({
        Name = "Screen Flash",
        Default = true,
        Function = function()end,
    })
    NWFlashColor = NWBtn.CreateDropdown({
        Name = "Flash Color",
        List = {"Red", "Orange", "Yellow", "Cyan", "White", "Pink", "Team Color"},
        Default = "Red",
        Function = function()end,
    })
    NWPulse = NWBtn.CreateToggle({
        Name = "Pulse Effect",
        Default = true,
        Function = function()end,
    })
    NWShowLabel = NWBtn.CreateToggle({
        Name = "Show Label",
        Default = true,
        Function = function()end,
    })
    NWShowDist = NWBtn.CreateToggle({
        Name = "Show Distance",
        Default = true,
        Function = function()end,
    })
end)

runcode(function()
    local tntEntries = {}
    local tntSpawn = {}
    local tntTracked = {}
    local tntConns = {}
    local TNTBtn, TNTColor, TNTMaxDist, TNTShowName, TNTShowDist, TNTBg, TNTCorner
    local TNT_FUSE = 4.2

    local TNT_KEYS = {"tnt","bomb","fireball","explosive","smoke"}
    local function isTNT(name)
        local n = name:lower()
        for _, k in ipairs(TNT_KEYS) do if n:find(k) then return true end end
        return false
    end
    local function trackTNT(obj)
        if obj:IsA("BasePart") or obj:IsA("Model") then
            if isTNT(obj.Name) then tntTracked[obj] = true end
        end
    end
    local function tntPos(obj)
        if obj:IsA("Model") then
            local ok, cf = pcall(function() return obj:GetModelCFrame() end)
            return ok and cf.Position or nil
        end
        return obj:IsA("BasePart") and obj.Position or nil
    end

    TNTBtn = GuiLibrary.Registry.miscPanel.API.CreateOptionsButton({
        Name = "TNTDetector",
        Function = function(callback)
            if callback then
                local containers = {
                    workspace:FindFirstChild("PlayersBlocksContainer"),
                    workspace:FindFirstChild("DroppedItemsContainer"),
                }
                for _, container in ipairs(containers) do
                    if not container then continue end
                    for _, obj in ipairs(container:GetDescendants()) do trackTNT(obj) end
                    table.insert(tntConns, container.DescendantAdded:Connect(trackTNT))
                    table.insert(tntConns, container.DescendantRemoving:Connect(function(obj)
                        tntTracked[obj] = nil
                    end))
                end

                local lqN = 0
                RunLoops:BindToHeartbeat("TNTDetector", function()
                    lqN += 1; if lqN % 3 ~= 0 then return end
                    local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                    local maxD = TNTMaxDist  and TNTMaxDist.Value  or 200
                    local c = pcol(TNTColor)
                    local showN = TNTShowName and TNTShowName.Enabled
                    local showD = TNTShowDist and TNTShowDist.Enabled
                    local seen = {}
                    for obj in pairs(tntTracked) do
                        if not obj.Parent then tntTracked[obj] = nil; continue end
                        local pos = tntPos(obj); if not pos then continue end
                        if myRoot and (myRoot.Position - pos).Magnitude > maxD then continue end
                        seen[obj] = true
                        if not tntSpawn[obj] then tntSpawn[obj] = tick() end
                        if not tntEntries[obj] then
                                local h = Instance.new("Highlight")
                                h.Adornee = obj
                                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                h.FillColor = c
                                h.FillTransparency = 0.35
                                h.OutlineColor = c
                                h.OutlineTransparency = 0
                                h.Parent = workspace
                                local bb = Instance.new("BillboardGui")
                                bb.Name = "PhantomTNT"
                                bb.AlwaysOnTop = true
                                bb.StudsOffset = Vector3.new(0, 3.5, 0)
                                local bg = Instance.new("Frame")
                                bg.Size = UDim2.fromScale(1,1)
                                bg.BorderSizePixel = 0
                                bg.BackgroundColor3 = Color3.fromRGB(10,10,10)
                                bg.BackgroundTransparency = 1
                                local tcr = Instance.new("UICorner", bg)
                                tcr.CornerRadius = UDim.new(0, 5)
                                bg.Parent = bb
                                local nameLbl = Instance.new("TextLabel")
                                nameLbl.BackgroundTransparency = 1
                                nameLbl.BorderSizePixel = 0
                                nameLbl.Font = Enum.Font.GothamSemibold
                                nameLbl.TextSize = 12
                                nameLbl.TextStrokeTransparency = 0.5
                                nameLbl.TextColor3 = Color3.fromRGB(255,80,80)
                                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                                nameLbl.Parent = bg
                                local timerLbl = Instance.new("TextLabel")
                                timerLbl.BackgroundTransparency = 1
                                timerLbl.BorderSizePixel = 0
                                timerLbl.Font = Enum.Font.GothamSemibold
                                timerLbl.TextSize = 12
                                timerLbl.TextStrokeTransparency = 0.5
                                timerLbl.TextColor3 = Color3.new(1,1,1)
                                timerLbl.TextXAlignment = Enum.TextXAlignment.Left
                                timerLbl.Parent = bg
                                local distLbl = Instance.new("TextLabel")
                                distLbl.BackgroundTransparency = 1
                                distLbl.BorderSizePixel = 0
                                distLbl.Font = Enum.Font.GothamSemibold
                                distLbl.TextSize = 12
                                distLbl.TextStrokeTransparency = 0.5
                                distLbl.TextColor3 = Color3.new(1,1,1)
                                distLbl.TextXAlignment = Enum.TextXAlignment.Left
                                distLbl.Parent = bg
                                bb.Parent = obj
                                tntEntries[obj] = {h=h, bb=bb, bg=bg, tcr=tcr, nameLbl=nameLbl, timerLbl=timerLbl, distLbl=distLbl}
                            end
                            local entry = tntEntries[obj]
                            entry.h.FillColor = c
                            entry.h.OutlineColor = c
                            entry.bg.BackgroundTransparency = (TNTBg and TNTBg.Enabled) and 0.35 or 1
                            entry.tcr.CornerRadius = UDim.new(0, (TNTCorner and TNTCorner.Value == "Square") and 0 or 5)
                            do
                                local dist = myRoot and math.floor((myRoot.Position - pos).Magnitude) or 0
                                local elapsed = tick() - (tntSpawn[obj] or tick())
                                local remaining = math.max(0, TNT_FUSE - elapsed)
                                local timerC = Color3.fromHSV(math.clamp(remaining/TNT_FUSE,0,1)/3, 0.9, 1)
                                local ts = 12
                                local font = Enum.Font.GothamSemibold
                                local pad = 6
                                local gap = 4
                                local nameStr = showN and obj.Name or ""
                                local timerStr = string.format("%.1fs", remaining)
                                local distStr = showD and ("["..dist.."m]") or ""
                                local nameW = showN and measureTextW(nameStr, ts, font) or 0
                                local timerW = measureTextW(timerStr, ts, font)
                                local distW = showD and measureTextW(distStr, ts, font) or 0
                                local totalW = math.max(50, nameW + (nameW>0 and gap or 0) + timerW + (distW>0 and gap or 0) + distW + pad*2)
                                local x = pad
                                entry.nameLbl.Visible = showN
                                entry.nameLbl.Size = UDim2.new(0, nameW, 1, 0)
                                entry.nameLbl.Position = UDim2.new(0, x, 0, 0)
                                entry.nameLbl.Text = nameStr; if showN then x += nameW + gap end
                                entry.timerLbl.TextColor3 = timerC
                                entry.timerLbl.Size = UDim2.new(0, timerW, 1, 0)
                                entry.timerLbl.Position = UDim2.new(0, x, 0, 0)
                                entry.timerLbl.Text = timerStr
                                x += timerW + (distW>0 and gap or 0)
                                entry.distLbl.Visible = showD
                                entry.distLbl.Size = UDim2.new(0, distW, 1, 0)
                                entry.distLbl.Position = UDim2.new(0, x, 0, 0)
                                entry.distLbl.Text = distStr
                                entry.bb.Size = UDim2.fromOffset(totalW, ts + 8)
                            end
                    end
                    for obj, entry in pairs(tntEntries) do
                        if not seen[obj] or not obj.Parent then
                            if entry.h  and entry.h.Parent  then entry.h:Destroy()  end
                            if entry.bb and entry.bb.Parent then entry.bb:Destroy() end
                            tntEntries[obj] = nil
                            tntSpawn[obj] = nil
                        end
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("TNTDetector")
                for _, e in pairs(tntEntries) do
                    if e.h  and e.h.Parent  then e.h:Destroy()  end
                    if e.bb and e.bb.Parent then e.bb:Destroy() end
                end
                tntEntries = {}
                tntSpawn = {}
                for _, c in ipairs(tntConns) do pcall(function() c:Disconnect() end) end
                table.clear(tntConns)
                table.clear(tntTracked)
            end
        end
    })
    TNTColor = TNTBtn.CreateDropdown({
        Name = "Color",
        List = {"Red", "Orange", "Yellow", "White", "Theme", "Team Color"},
        Default = "Red",
        Function = function()end,
    })
    TNTMaxDist = TNTBtn.CreateSlider({
        Name = "Max Distance",
        Min = 20,
        Max = 400,
        Default = 200,
        Round = 1,
    })
    TNTShowName = TNTBtn.CreateToggle({
        Name = "Show Name",
        Default = true,
        Function = function()end,
    })
    TNTShowDist = TNTBtn.CreateToggle({
        Name = "Show Distance",
        Default = true,
        Function = function()end,
    })
    TNTBg = TNTBtn.CreateToggle({
        Name = "Background",
        Default = true,
        Function = function()end,
    })
    TNTCorner = TNTBtn.CreateDropdown({
        Name = "Corner Style",
        List = {"Rounded", "Square"},
        Default = "Rounded",
        Function = function()end,
    })
end)

runcode(function()
    local bedEntries = {}
    local BedBtn, BedColor, BedEnemyOnly, BedShowDist, BedShowTeam, BedFillOp, BedOutOp, BedBg, BedCorner

    local _bedsCache = nil
    local _cachedLbW, _cachedRbW
    local _bedsConns = {}
    local function buildBedsCache()
        for _, c in ipairs(_bedsConns) do pcall(function() c:Disconnect() end) end
        _bedsConns = {}
        _bedsCache = {}
        local bedsFolder = workspace:FindFirstChild("Beds")
            or workspace:FindFirstChild("BedsContainer")
            or workspace:FindFirstChild("BedFolder")
        if bedsFolder then
            for _, b in ipairs(bedsFolder:GetChildren()) do
                if b:IsA("Model") then _bedsCache[b] = true end
            end
            table.insert(_bedsConns, bedsFolder.ChildAdded:Connect(function(b)
                if b:IsA("Model") then _bedsCache[b] = true end
            end))
            table.insert(_bedsConns, bedsFolder.ChildRemoved:Connect(function(b)
                _bedsCache[b] = nil
            end))
        else
            for _, d in ipairs(workspace:GetDescendants()) do
                if (d.Name == "Bed" or d.Name:lower():find("bed")) and d:IsA("Model") then
                    _bedsCache[d] = true
                end
            end
        end
    end
    local function getBedModels()
        if not _bedsCache or next(_bedsCache) == nil then buildBedsCache() end
        local out = {}
        for b in pairs(_bedsCache) do out[#out+1] = b end
        return out
    end
    local function getMattressColor(bed)
        local m = bed:FindFirstChild("Mattress")
        if m and m:IsA("BasePart") then return m.Color end
        for _, p in ipairs(bed:GetDescendants()) do
            if p:IsA("BasePart") and p.Name:lower():find("mattress") then return p.Color end
        end
        return nil
    end
    local _bedInfoCache = {}
    local function getBedAttrTeam(bed)
        return bed:GetAttribute("Team") and tostring(bed:GetAttribute("Team")) or nil
    end
    local function findTeamByName(name)
        local nl = name:lower()
        for _, team in ipairs(Teams:GetTeams()) do
            if team.Name:lower() == nl then return team end
        end
        return nil
    end
    local function isEnemyBed(bed)
        if not lplr.Team then return true end
        local attr = getBedAttrTeam(bed)
        if attr then return attr:lower() ~= lplr.Team.Name:lower() end
        return true
    end
    local function getBedTeamInfo(bed)
        local cached = _bedInfoCache[bed]
        if cached then return cached[1], cached[2] end
        local attr = getBedAttrTeam(bed)
        local label, color
        if attr then
            local team = findTeamByName(attr)
            color = team and team.TeamColor.Color or getMattressColor(bed) or Color3.fromRGB(220,60,60)
            label = attr .. " Bed"
        else
            label = bed.Name
            color = Color3.fromRGB(220, 60, 60)
        end
        _bedInfoCache[bed] = {label, color}
        return label, color
    end

    BedBtn = GuiLibrary.Registry.renderPanel.API.CreateOptionsButton({
        Name = "BedESP",
        Function = function(callback)
            if callback then
                local bedN = 0
                RunLoops:BindToHeartbeat("BedESP", function()
                    bedN += 1; if bedN % 10 ~= 0 then return end
                    local myRoot = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                    local eOnly = BedEnemyOnly and BedEnemyOnly.Enabled
                    local showD = BedShowDist  and BedShowDist.Enabled
                    local showT = BedShowTeam  and BedShowTeam.Enabled
                    local filA = BedFillOp    and BedFillOp.Value or 0.5
                    local outA = BedOutOp     and BedOutOp.Value  or 0
                    local ec = pcol(BedColor)
                    local seen = {}

                    for _, bed in ipairs(getBedModels()) do
                        if not bed or not bed.Parent then continue end
                        local enemy = isEnemyBed(bed)
                        if eOnly and not enemy then continue end
                        seen[bed] = true
                        if not bedEntries[bed] then
                            local h = Instance.new("Highlight")
                            h.Adornee = bed
                            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            h.Parent = workspace
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "PhantomBedESP"
                            bb.AlwaysOnTop = true
                            bb.StudsOffset = Vector3.new(0, 4.5, 0)
                            local bg = Instance.new("Frame")
                            bg.Size = UDim2.fromScale(1,1)
                            bg.BorderSizePixel = 0
                            bg.BackgroundColor3 = Color3.fromRGB(10,10,10)
                            bg.BackgroundTransparency = 1
                            local bcr = Instance.new("UICorner", bg)
                            bcr.CornerRadius = UDim.new(0, 5)
                            bg.Parent = bb
                            local nameLbl = Instance.new("TextLabel")
                            nameLbl.BackgroundTransparency = 1
                            nameLbl.BorderSizePixel = 0
                            nameLbl.Font = Enum.Font.GothamSemibold
                            nameLbl.TextSize = 12
                            nameLbl.TextStrokeTransparency = 0.5
                            nameLbl.TextColor3 = Color3.new(1,1,1)
                            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                            nameLbl.Parent = bg
                            local function makeLbl(color)
                                local l = Instance.new("TextLabel")
                                l.BackgroundTransparency = 1
                                l.BorderSizePixel = 0
                                l.Font = Enum.Font.GothamSemibold
                                l.TextSize = 12
                                l.TextStrokeTransparency = 0.5
                                l.TextColor3 = color
                                l.TextXAlignment = Enum.TextXAlignment.Left
                                l.Parent = bg
                                return l
                            end
                            local green = Color3.fromRGB(85, 255, 127)
                            local lbLbl = makeLbl(green)      lbLbl.Text = "["
                            local distNumLbl = makeLbl(Color3.new(1,1,1))
                            local rbLbl = makeLbl(green)      rbLbl.Text = "]"
                            bb.Parent = bed
                            bedEntries[bed] = {h=h, bb=bb, bg=bg, bcr=bcr, nameLbl=nameLbl, lbLbl=lbLbl, distNumLbl=distNumLbl, rbLbl=rbLbl}
                        end
                        local entry = bedEntries[bed]
                        local autoMode = BedColor and BedColor.Value == "Auto"
                        local teamLabel, teamColor = getBedTeamInfo(bed)
                        local bc = autoMode and teamColor or ec
                        entry.h.FillColor = bc
                        entry.h.FillTransparency = filA
                        entry.h.OutlineColor = bc
                        entry.h.OutlineTransparency = outA
                        entry.bg.BackgroundTransparency = (BedBg and BedBg.Enabled) and 0.35 or 1
                        entry.bcr.CornerRadius = UDim.new(0, (BedCorner and BedCorner.Value == "Square") and 0 or 5)
                        entry.nameLbl.TextColor3 = bc
                        local ok, cf = pcall(function() return bed:GetModelCFrame() end)
                        local bpos = ok and cf.Position or Vector3.zero
                        local ts = 12
                        local font = Enum.Font.GothamSemibold
                        if not _cachedLbW then
                            _cachedLbW = measureTextW("[", ts, font)
                            _cachedRbW = measureTextW("]", ts, font)
                        end
                        local nameVisible = showT
                        local distVisible = showD and myRoot ~= nil
                        local nameStr = nameVisible and teamLabel or ""
                        local numStr = distVisible and (myRoot and math.floor((myRoot.Position - bpos).Magnitude).."m" or "0m") or ""
                        local nameW = nameVisible and measureTextW(nameStr, ts, font) or 0
                        local lbW = distVisible and _cachedLbW or 0
                        local numW = distVisible and measureTextW(numStr, ts, font) or 0
                        local rbW = distVisible and _cachedRbW or 0
                        local pad = 6
                        local gap = (nameVisible and distVisible) and 5 or 0
                        local totalW = math.max(40, nameW + lbW + numW + rbW + gap + pad * 2)
                        entry.nameLbl.Visible = nameVisible
                        entry.nameLbl.Size = UDim2.new(0, nameW, 1, 0)
                        entry.nameLbl.Position = UDim2.new(0, pad, 0, 0)
                        entry.nameLbl.Text = nameStr
                        local dx = pad + nameW + gap
                        entry.lbLbl.Visible = distVisible
                        entry.lbLbl.Size = UDim2.new(0, lbW, 1, 0)
                        entry.lbLbl.Position = UDim2.new(0, dx, 0, 0)
                        entry.distNumLbl.Visible = distVisible
                        entry.distNumLbl.Size = UDim2.new(0, numW, 1, 0)
                        entry.distNumLbl.Position = UDim2.new(0, dx + lbW, 0, 0)
                        entry.distNumLbl.Text = numStr
                        entry.rbLbl.Visible = distVisible
                        entry.rbLbl.Size = UDim2.new(0, rbW, 1, 0)
                        entry.rbLbl.Position = UDim2.new(0, dx + lbW + numW, 0, 0)
                        entry.bb.Size = UDim2.fromOffset(totalW, ts + 8)
                        entry.bb.Enabled = nameVisible or distVisible
                    end
                    for bed, entry in pairs(bedEntries) do
                        if not seen[bed] or not bed.Parent then
                            if entry.h  and entry.h.Parent  then entry.h:Destroy()  end
                            if entry.bb and entry.bb.Parent then entry.bb:Destroy() end
                            bedEntries[bed] = nil
                        end
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("BedESP")
                for _, entry in pairs(bedEntries) do
                    if entry.h  and entry.h.Parent  then entry.h:Destroy()  end
                    if entry.bb and entry.bb.Parent then entry.bb:Destroy() end
                end
                bedEntries = {}
                for _, c in ipairs(_bedsConns) do pcall(function() c:Disconnect() end) end
                _bedsConns = {}
                _bedsCache = nil
                _bedInfoCache = {}
            end
        end
    })
    BedColor = BedBtn.CreateDropdown({
        Name = "Enemy Color",
        List = {"Auto", "Red", "Orange", "Yellow", "White", "Theme", "Team Color"},
        Default = "Auto",
        Function = function()end,
    })
    BedFillOp = BedBtn.CreateSlider({
        Name = "Fill Opacity",
        Min = 0,
        Max = 1,
        Default = 0.5,
    })
    BedOutOp = BedBtn.CreateSlider({
        Name = "Outline Opacity",
        Min = 0,
        Max = 1,
        Default = 0,
    })
    BedEnemyOnly = BedBtn.CreateToggle({
        Name = "Enemy Only",
        Default = true,
        Function = function()end,
    })
    BedShowDist = BedBtn.CreateToggle({
        Name = "Show Distance",
        Default = true,
        Function = function()end,
    })
    BedShowTeam = BedBtn.CreateToggle({
        Name = "Show Team Name",
        Default = true,
        Function = function()end,
    })
    BedBg = BedBtn.CreateToggle({
        Name = "Background",
        Default = true,
        Function = function()end,
    })
    BedCorner = BedBtn.CreateDropdown({
        Name = "Corner Style",
        List = {"Rounded", "Square"},
        Default = "Rounded",
        Function = function()end,
    })
end)

runcode(function()
    local fcActive, fcConn = false, nil
    local FCBtn, FCSpeed, FCFOV, FCNoClip

    FCBtn = GuiLibrary.Registry.worldPanel.API.CreateOptionsButton({
        Name = "Freecam",
        Function = function(callback)
            if callback then
                fcActive = true
                local lv = Camera.CFrame.LookVector
                local pitch = math.asin(math.clamp(lv.Y, -1, 1))
                local yaw = math.atan2(-lv.X, -lv.Z)
                local camPos= Camera.CFrame.Position

                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

                fcConn = RunService.RenderStepped:Connect(function(dt)
                    if not fcActive then return end
                    if Camera.CameraType ~= Enum.CameraType.Scriptable then
                        Camera.CameraType = Enum.CameraType.Scriptable
                    end

                    local speed = FCSpeed and FCSpeed.Value or 30
                    local fast = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1
                    local move = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0,0,-1) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0,0, 1) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1,0,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new( 1,0,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then move += Vector3.new(0, 1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move += Vector3.new(0,-1,0) end

                    local md = UserInputService:GetMouseDelta()
                    yaw = yaw   - md.X * 0.003
                    pitch = math.clamp(pitch - md.Y * 0.003, -math.pi/2+0.01, math.pi/2-0.01)

                    local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
                    if move.Magnitude > 0 then
                        camPos = camPos + rot:VectorToWorldSpace(move.Unit) * speed * fast * dt
                    end
                    Camera.CFrame = CFrame.new(camPos) * rot
                    if FCFOV then Camera.FieldOfView = FCFOV.Value end
                end)
            else
                fcActive = false
                if fcConn then fcConn:Disconnect(); fcConn = nil end
                Camera.CameraType = Enum.CameraType.Custom
                UIS.MouseBehavior = Enum.MouseBehavior.Default
                Camera.FieldOfView = 70
            end
        end
    })
    FCSpeed = FCBtn.CreateSlider({
        Name = "Speed",
        Min = 5,
        Max = 200,
        Default = 30,
        Round = 1,
    })
    FCFOV = FCBtn.CreateSlider({
        Name = "FOV",
        Min = 20,
        Max = 120,
        Default = 70,
        Round = 1,
    })
end)

runcode(function()
    local XRBtn, XROpacity, XRBlocks, XRWool

    local function processXray(on)
        local transp = XROpacity and XROpacity.Value or 0.88
        local doBlocks = XRBlocks  and XRBlocks.Enabled
        local doWool = XRWool    and XRWool.Enabled
        local function process(container, enabled)
            if not container then return end
            for _, p in ipairs(container:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.LocalTransparencyModifier = (on and enabled) and transp or 0
                end
            end
        end
        process(workspace:FindFirstChild("BlocksContainer"),        doBlocks)
        process(workspace:FindFirstChild("PlayersBlocksContainer"),  doWool)
    end

    XRBtn = GuiLibrary.Registry.worldPanel.API.CreateOptionsButton({
        Name = "Xray",
        Function = function(callback)
            if callback then
                local lqN = 0
                RunLoops:BindToHeartbeat("Xray", function()
                    lqN += 1; if lqN % 4 ~= 0 then return end
                    processXray(true)
                end)
            else
                RunLoops:UnbindFromHeartbeat("Xray")
                processXray(false)
            end
        end
    })
    XROpacity = XRBtn.CreateSlider({
        Name = "Transparency",
        Min = 0.3,
        Max = 0.99,
        Default = 0.88,
    })
    XRBlocks = XRBtn.CreateToggle({
        Name = "Map Blocks",
        Default = true,
        Function = function()end,
    })
    XRWool = XRBtn.CreateToggle({
        Name = "Player Wool",
        Default = true,
        Function = function()end,
    })
end)

runcode(function()
    local AHBtn, AHSize, AHPadding, AHBg, AHCorner, AHOpacity, AHPos

    local hudGui, hudFrame = nil, nil
    local iconLabels = {}
    local lastSig = ""
    local FALLBACK = "rbxassetid://130674868309232"

    local SLOT_KEYS = {"helmet","chestplate","leggings","boots"}

    local function norm2(v)
        return string.gsub(string.lower(tostring(v or "")), "[^%w]", "")
    end

    local function getArmorSlot(name, cls)
        local t = string.lower(tostring(name or "") .. " " .. tostring(cls or ""))
        if t:find("helmet") or t:find("head")                 then return "helmet"     end
        if t:find("chestplate") or t:find("chest") or t:find("body") then return "chestplate" end
        if t:find("leggings") or t:find("pants") or t:find("legs")  then return "leggings"   end
        if t:find("boots")  or t:find("shoes") or t:find("feet")    then return "boots"       end
        return nil
    end

    local function getImage(itemName, className)
        for _, name in ipairs({itemName, className}) do
            if name and name ~= "" then
                local d = bedfight.modules.ItemsData[name]
                if d and d.Image then return d.Image end
                local lk = string.lower(name)
                for k, v in pairs(bedfight.modules.ItemsData) do
                    if string.lower(k) == lk and v.Image then return v.Image end
                end
            end
        end
        return FALLBACK
    end

    local function buildSlots()
        local slots = {}

        local hook = data.hooked[lplr]
        if hook and hook.items then
            for _, entry in ipairs(hook.items) do
                local obj = entry.item
                local iName = obj and obj.Name or ""
                local cls = entry.class or ""
                if (entry.inventory or ""):lower() == "armor"
                    or getArmorSlot(iName, cls)
                then
                    local slot = getArmorSlot(iName, cls)
                    if slot and not slots[slot] then
                        slots[slot] = {image = getImage(iName, cls)}
                    end
                end
            end
        end

        if not next(slots) then
            local armorInv = bedfight.modules.InventoryHandler.Inventories
                and bedfight.modules.InventoryHandler.Inventories.Armor
            if armorInv then
                for _, slot in ipairs(armorInv.Items) do
                    local iName = slot.Name or ""
                    local cls = slot:GetAttribute("Class") or ""
                    if iName ~= "" then
                        local slotKey = getArmorSlot(iName, cls)
                        if slotKey and not slots[slotKey] then
                            slots[slotKey] = {image = getImage(iName, cls)}
                        end
                    end
                end
            end
        end

        return slots
    end

    local function buildSig(slots)
        local parts = {}
        for _, k in ipairs(SLOT_KEYS) do
            parts[#parts+1] = k .. "=" .. (slots[k] and slots[k].image or "")
        end
        return table.concat(parts, "|")
    end

    local function rebuildIcons(slots, sz, pad, bgOn, cornerOn)
        for _, lbl in ipairs(iconLabels) do
            if lbl and lbl.Parent then lbl:Destroy() end
        end
        iconLabels = {}
        if not hudFrame then return end

        local totalH = 0
        local count = 0
        for _, k in ipairs(SLOT_KEYS) do
            if slots[k] then count += 1 end
        end
        totalH = count * sz + math.max(0, count - 1) * pad

        hudFrame.Size = UDim2.fromOffset(sz + 8, totalH + 8)
        local pos = AHPos and AHPos.Value or "Bottom Left"
        local margin = 12
        local frameH = totalH + 8
        local frameW = sz + 8
        if pos == "Bottom Left" then
            hudFrame.AnchorPoint = Vector2.new(0, 1)
            hudFrame.Position = UDim2.new(0, margin, 1, -margin)
        elseif pos == "Bottom Right" then
            hudFrame.AnchorPoint = Vector2.new(1, 1)
            hudFrame.Position = UDim2.new(1, -margin, 1, -margin)
        elseif pos == "Middle Left" then
            hudFrame.AnchorPoint = Vector2.new(0, 0.5)
            hudFrame.Position = UDim2.new(0, margin, 0.5, 0)
        elseif pos == "Middle Right" then
            hudFrame.AnchorPoint = Vector2.new(1, 0.5)
            hudFrame.Position = UDim2.new(1, -margin, 0.5, 0)
        end

        local yOff = 4
        for _, k in ipairs(SLOT_KEYS) do
            local info = slots[k]
            if info then
                local img = Instance.new("ImageLabel", hudFrame)
                img.Size = UDim2.fromOffset(sz, sz)
                img.Position = UDim2.fromOffset(4, yOff)
                img.BackgroundTransparency = 1
                img.BorderSizePixel = 0
                img.Image = info.image
                img.ScaleType = Enum.ScaleType.Fit
                iconLabels[#iconLabels+1] = img
                yOff += sz + pad
            end
        end
    end

    AHBtn = GuiLibrary.Registry.inventoryPanel.API.CreateOptionsButton({
        Name = "ArmorHUD",
        Function = function(callback)
            if callback then
                if not data.hooked[lplr] then
                    task.spawn(function() hookinv(lplr) end)
                end

                local pgui = lplr:FindFirstChildOfClass("PlayerGui")
                hudGui = Instance.new("ScreenGui")
                hudGui.Name = "PhantomArmorHUD"
                hudGui.ResetOnSpawn = false
                hudGui.IgnoreGuiInset = true
                hudGui.DisplayOrder = 999990
                hudGui.Parent = pgui or game.CoreGui

                hudFrame = Instance.new("Frame", hudGui)
                hudFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
                hudFrame.BackgroundTransparency = 0.4
                hudFrame.BorderSizePixel = 0
                hudFrame.Size = UDim2.fromOffset(48, 48)
                local hCorner = Instance.new("UICorner", hudFrame)
                hCorner.CornerRadius = UDim.new(0, 6)

                local lqN = 0
                RunLoops:BindToHeartbeat("ArmorHUD", function()
                    lqN += 1; if lqN % 6 ~= 0 then return end

                    local sz = AHSize    and math.floor(AHSize.Value)    or 40
                    local pad = AHPadding and math.floor(AHPadding.Value) or 4
                    local bgOn = AHBg      and AHBg.Enabled
                    local cStyle = AHCorner  and AHCorner.Value or "Rounded"
                    local op = AHOpacity and AHOpacity.Value or 0.4

                    hudFrame.Visible = bgOn
                    hudFrame.BackgroundTransparency = op
                    hCorner.CornerRadius = UDim.new(0, cStyle == "Square" and 0 or 6)

                    local slots = buildSlots()
                    local posV = AHPos and AHPos.Value or "Bottom Left"
                    local sig = buildSig(slots) .. "|sz=" .. sz .. "|pad=" .. pad .. "|pos=" .. posV
                    local hasAny = next(slots) ~= nil
                    hudFrame.Visible = bgOn and hasAny
                    for _, lbl2 in ipairs(iconLabels) do
                        lbl2.Visible = hasAny
                    end
                    if sig ~= lastSig then
                        lastSig = sig
                        rebuildIcons(slots, sz, pad, bgOn, cStyle)
                    end
                end)
            else
                RunLoops:UnbindFromHeartbeat("ArmorHUD")
                if hudGui then hudGui:Destroy(); hudGui = nil end
                hudFrame = nil
                iconLabels = {}
                lastSig = ""
            end
        end
    })
    AHPos = AHBtn.CreateDropdown({
        Name = "Position",
        List = {"Bottom Left", "Bottom Right", "Middle Left", "Middle Right"},
        Default = "Bottom Left",
        Function = function() end,
    })
    AHSize = AHBtn.CreateSlider({
        Name = "Icon Size",
        Min = 24,
        Max = 64,
        Default = 40,
        Round = 1,
    })
    AHPadding = AHBtn.CreateSlider({
        Name = "Icon Spacing",
        Min = 0,
        Max = 16,
        Default = 4,
        Round = 1,
    })
    AHOpacity = AHBtn.CreateSlider({
        Name = "BG Opacity",
        Min = 0,
        Max = 0.9,
        Default = 0.4,
    })
    AHBg = AHBtn.CreateToggle({
        Name = "Background",
        Default = true,
        Function = function() end,
    })
    AHCorner = AHBtn.CreateDropdown({
        Name = "Corner Style",
        List = {"Rounded", "Square"},
        Default = "Rounded",
        Function = function() end,
    })
end)
