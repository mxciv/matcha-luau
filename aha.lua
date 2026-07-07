loadstring(game:HttpGet("https://raw.githubusercontent.com/mxciv/matcha-luau/refs/heads/main/lib/esp.lua"))()
local ESPService = _G.ESPService
if not ESPService then return end

local Workspace = game:GetService("Workspace")

task.spawn(function()
    while true do
        for _, kid in pairs(Workspace.NPCs:GetChildren()) do
            local rootPart = kid:FindFirstChild("RootPart")

            if rootPart then
                local anomaly = kid:GetAttribute("Anomaly") or kid:GetAttribute("Skinwalker")
					
				if string.match(kid.Name, "Monster") then
					ESPService:Create(rootPart, kid.Name, Color3.fromRGB(255, 0, 0))
				else
                	ESPService:Create(rootPart, string.format("%s", kid.Name), anomaly and Color3.fromRGB(255, 0, 0) or Color3.new(1,1,1))
				end
			end
        end
        task.wait(0.5)
    end
end)
