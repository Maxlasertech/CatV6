if getgenv().texturepack then getgenv().texturepack:Disconnect() end

-- BrickColor name → flat PvP color
-- White/near-white map parts are pushed to a clean neutral so SmoothPlastic
-- doesn't blind you. Team block colors are maximally saturated.
local PALETTE = {
    -- Team wool / placed blocks
    ['Bright red']           = Color3.fromRGB(255,  38,  38),
    ['Bright blue']          = Color3.fromRGB( 28,  95, 255),
    ['Lime green']           = Color3.fromRGB( 35, 210,  50),
    ['Bright yellow']        = Color3.fromRGB(255, 208,   0),
    ['Hot pink']             = Color3.fromRGB(255,  48, 168),
    ['Cyan']                 = Color3.fromRGB(  0, 188, 210),
    ['Bright orange']        = Color3.fromRGB(255, 122,  12),
    ['Dark orange']          = Color3.fromRGB(230, 100,   5),
    ['Medium orange']        = Color3.fromRGB(252, 136,  18),
    ['Bright violet']        = Color3.fromRGB(128,  38, 205),
    ['Lavender']             = Color3.fromRGB(155,  92, 215),
    ['Sand blue']            = Color3.fromRGB( 68, 112, 170),
    ['Pastel blue']          = Color3.fromRGB( 80, 132, 202),
    ['Medium blue']          = Color3.fromRGB( 55,  82, 192),
    ['Light blue']           = Color3.fromRGB( 65, 144, 218),
    -- White / near-white → neutral cool gray so SmoothPlastic doesn't bleach
    ['White']                = Color3.fromRGB(208, 212, 220),
    ['Institutional white']  = Color3.fromRGB(200, 204, 212),
    ['Ghost grey']           = Color3.fromRGB(165, 185, 205),
    ['Light stone grey']     = Color3.fromRGB(172, 178, 188),
    -- Map stone / ground (clean grays)
    ['Medium stone grey']    = Color3.fromRGB(112, 118, 128),
    ['Dark stone grey']      = Color3.fromRGB( 60,  63,  70),
    ['Smoky grey']           = Color3.fromRGB( 90,  94, 102),
    ['Mid gray']             = Color3.fromRGB(145, 150, 158),
    ['Pearl']                = Color3.fromRGB(185, 190, 198),
    -- End stone / sand
    ['Sand yellow']          = Color3.fromRGB(205, 182, 105),
    ['Brick yellow']         = Color3.fromRGB(210, 188, 115),
    ['Pale yellow']          = Color3.fromRGB(215, 193, 122),
    -- Wood
    ['Reddish brown']        = Color3.fromRGB(145,  76,  30),
    ['Nougat']               = Color3.fromRGB(165, 108,  44),
    -- Obsidian
    ['Really black']         = Color3.fromRGB( 18,  14,  25),
    ['Black']                = Color3.fromRGB( 24,  19,  32),
    -- Resource / precious blocks
    ['Gold']                 = Color3.fromRGB(255, 180,  10),
    ['Bright green']         = Color3.fromRGB(  0, 185,  78),
    ['Dark green']           = Color3.fromRGB( 18, 112,  36),
    ['Sand green']           = Color3.fromRGB( 76, 156, 105),
    ['Electric blue']        = Color3.fromRGB( 55, 198, 218),
    ['Teal']                 = Color3.fromRGB( 15, 168, 158),
}

local SKIP_NAMES = {
    HumanoidRootPart = true, Head = true, Torso = true,
    UpperTorso = true, LowerTorso = true,
    ['Left Arm'] = true,  ['Right Arm'] = true,
    ['Left Leg'] = true,  ['Right Leg'] = true,
    LeftUpperArm = true,  RightUpperArm = true,
    LeftLowerArm = true,  RightLowerArm = true,
    LeftHand = true,      RightHand = true,
    LeftUpperLeg = true,  RightUpperLeg = true,
    LeftLowerLeg = true,  RightLowerLeg = true,
    LeftFoot = true,      RightFoot = true,
}

local function boostColor(c)
    local h, s, v = Color3.toHSV(c)
    -- Boost saturation only — never touch brightness so light parts don't bleach
    s = math.min(1, s * 1.45)
    -- Pull very bright near-white colors down to a readable light gray
    if s < 0.08 and v > 0.85 then
        v = 0.78
    end
    return Color3.fromHSV(h, s, v)
end

local function apply(part)
    if not (part:IsA('BasePart') or part:IsA('UnionOperation')) then return end
    if SKIP_NAMES[part.Name] then return end
    pcall(function()
        part.Material      = Enum.Material.SmoothPlastic
        part.TopSurface    = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Color = PALETTE[part.BrickColor.Name] or boostColor(part.Color)
        for _, child in part:GetChildren() do
            if child:IsA('Texture') or child:IsA('Decal') then
                child:Destroy()
            end
        end
    end)
end

for _, v in workspace:GetDescendants() do
    task.defer(apply, v)
end

getgenv().texturepack = workspace.DescendantAdded:Connect(function(v)
    task.defer(apply, v)
end)
