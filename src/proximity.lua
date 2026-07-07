loadstring(game:HttpGet("https://raw.githubusercontent.com/mxciv/matcha-luau/refs/heads/main/lib/theo.lua"))()
local OffsetService = _G.OffsetService

local offset = OffsetService:GetTheoOffset()
if not offset then return end

local proximityDuration = offset.ProximityPrompt and offset.ProximityPrompt.HoldDuration
if not proximityDuration then return end

local patchedPrompts = setmetatable({}, {__mode = "k"})

notify("Instant Proximity Prompt is ready!", 5)

local function patchProximityPrompt(prompt)
    if not prompt or prompt.ClassName ~= "ProximityPrompt" then return end
    if patchedPrompts[prompt] then return end

    local addr = prompt.Address + proximityDuration
    memory_write("float", addr, 0.0)
    patchedPrompts[prompt] = true
end

task.spawn(function()
    while true do
        for _, v in ipairs(game.Workspace:GetDescendants()) do
            local pp = v:FindFirstChildWhichIsA("ProximityPrompt")
            if pp then
                patchProximityPrompt(pp)
            end
        end
        wait(1)
    end
end)
