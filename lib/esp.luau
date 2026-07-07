local ESPService = {}
ESPService.__index = ESPService

ESPService.Config = {
    ESP_OFFSET = 2,
    ESP_GAP = 6,
    DEFAULT_COLOR = Color3.new(1,1,1)
};

ESPService.ESPList = {}

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function ESPService:Create(object, name, color)
    if self.ESPList[object.Address] then return end
    if not name then name = object.Name end

    local espName = Drawing.new("Text")
    espName.Visible = true
    espName.Transparency = 1
    espName.ZIndex = 10
    espName.Color = color or self.Config.DEFAULT_COLOR
    espName.Position = Vector2.new(0, 0)
    espName.Text = name
    espName.Size = 20
    espName.Center = true
    espName.Outline = true
    espName.Font = Drawing.Fonts.Monospace

    local espDist = Drawing.new("Text")
    espDist.Visible = true
    espDist.Transparency = 1
    espDist.ZIndex = 20
    espDist.Color =  self.Config.DEFAULT_COLOR
    espDist.Position = Vector2.new(0, 25)
    espDist.Text = "[69 m]"
    espDist.Size = 18
    espDist.Center = true
    espDist.Outline = true
    espDist.Font = Drawing.Fonts.Monospace

    self.ESPList[object.Address] = {
        Instance = object,
        EspName = espName,
        EspDist = espDist
    }
end

function ESPService:Delete(address)
    local data = self.ESPList[address]
    if not data then return end

    if data.EspName then data.EspName:Remove() end
    if data.EspDist then data.EspDist:Remove() end

    data.Instance = nil
    data.EspName = nil
    data.EspDist = nil

    self.ESPList[address] = nil
end

function ESPService:Destroy()
    self.ESPWatcher:Disconnect()
    for address, data in pairs(self.ESPList) do
        if data.EspName then data.EspName:Remove() end
        if data.EspDist then data.EspDist:Remove() end

        data.Instance = nil
        data.EspName = nil
        data.EspDist = nil
    end

    self.activeESP = {}
    ESPService = nil
    _G.ESPService = nil
end

ESPService.ESPWatcher = RunService.RenderStepped:Connect(function()
    for address, data in pairs(self.ESPList) do
        local instance = data.Instance
        if not instance or not instance:IsDescendantOf(Workspace) then
            deleteESP(address)
            continue
        end
        
        local instancePos = instance.Position

        if not instancePos then
            deleteESP(address)
            continue
        end

        local screenPos, onScreen = WorldToScreen(instancePos)

        if not onScreen then
            data.EspName.Visible = false
            data.EspDist.Visible = false
            continue
        end

        data.EspName.Visible = true
        data.EspDist.Visible = true

        local espName = data.EspName
        espName.Position = Vector2.new(
            screenPos.X,
            screenPos.Y - espName.TextBounds.Y - self.Config.ESP_OFFSET
        )

        local espDist = data.EspDist
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart

        if not hrp then
            espDist.Text = "[??? m]"

            espDist.Position = Vector2.new(
                screenPos.X,
                espName.Position.Y + espName.TextBounds.Y + self.Config.ESP_GAP
            )
            continue
        end

        local distance = math.floor((instancePos - hrp.Position).Magnitude) / 3
        espDist.Text = string.format("[%d m]", distance)

        espDist.Position = Vector2.new(
            screenPos.X,
            espName.Position.Y + espName.TextBounds.Y + self.Config.ESP_GAP
        )
    end
end)

_G.ESPService = ESPService
return ESPService
