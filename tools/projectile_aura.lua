local replicated = game:GetService('ReplicatedStorage')
local players = game:GetService('Players')
local lplr = players.LocalPlayer
local http = game:GetService('HttpService')

local remote = replicated.rbxts_include.node_modules['@rbxts'].net.out._NetManaged.ProjectileFire

local RANGE = 100
local DELAY = 0.35

local function getNearest()
    local root = lplr.Character and lplr.Character.PrimaryPart
    if not root then return end

    local closest, closestDist = nil, RANGE
    for _, plr in players:GetPlayers() do
        if plr ~= lplr and plr.Team ~= lplr.Team and plr.Character then
            local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
            local hum = plr.Character:FindFirstChild('Humanoid')
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - root.Position).Magnitude
                if d < closestDist then
                    closest = hrp
                    closestDist = d
                end
            end
        end
    end
    return closest
end

repeat
    task.wait(DELAY)
    local root = lplr.Character and lplr.Character.PrimaryPart
    if not root then continue end

    local weapon = replicated.Inventories:FindFirstChild(lplr.Name)
    weapon = weapon and weapon:FindFirstChild('wood_crossbow')
    if not weapon then continue end

    local target = getNearest()
    if not target then continue end

    local dir = (target.Position - root.Position).Unit

    remote:InvokeServer(
        weapon,
        'volley_arrow',
        'arrow',
        root.CFrame,
        root.CFrame,
        dir * 9e9,
        http:GenerateGUID(false),
        {
            shotId = http:GenerateGUID(false),
            drawDurationSec = 9e9
        },
        workspace:GetServerTimeNow()
    )
until false
