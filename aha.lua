
-- Configuration
local Config = {
    PATIENT_ATTACH_PART = "RootPart", -- or "Head"
    PATIENT_DEFAULT_COLOR = Color3.fromHex("#FFFFFF"),
    IGNORE_PATIENTS = {"Doctor"}
}

-- Services
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local playerCharacter = LocalPlayer.Character

-- Variables
local hospitalRooms = {}
local patientActiveESP = {}
local medicineCache = {}

-- Utilities
local function checkIgnoredPatient(name)
    for _, ignoreName in pairs(Config.IGNORE_PATIENTS) do
        if string.match(name, ignoreName) then
            return true
        end
    end
    return false
end

local function getDistanceFromPlayer(position, studs_per_unit)
	if not position then return 0 end
    if not playerCharacter then return 0 end

    local hrp = playerCharacter:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end

    return (hrp.Position - position).Magnitude / studs_per_unit
end

local function getPatientColor(patient)
    if not patient then 
        warn("Patient instance is not valid!") 
        return Config.PATIENT_DEFAULT_COLOR 
    end

    if patient:GetAttribute("Skinwalker") or patient:GetAttribute("IsAnomaly") then
        return Color3.fromHex("#FF0000")
    end
    if string.match(patient.Name, "onster") then
        return Color3.fromHex("#FFFF00")
    end
    if patient:GetAttribute("IsVisitor") then
        return Color3.fromHex("#00FF00")
    end
    if patient:GetAttribute("IsPatient") then
        return Color3.fromHex("#55AAFF")
    end
    
    return Config.PATIENT_DEFAULT_COLOR
end

-- ESP Renderer
local function processPatientESP(part, color, room)
    if not part then return warn("Invalid part instance!") end

    local espDist = Drawing.new("Text")
    espDist.Visible = true
    espDist.Transparency = 1
    espDist.ZIndex = 20
    espDist.Color = Color3.fromHex("#FFFFFF")
    espDist.Position = Vector2.new(0, 0)
    espDist.Text = "[24 m]"
    espDist.Size = 18
    espDist.Center = true
    espDist.Outline = true
    espDist.Font = Drawing.Fonts.Monospace

    local espName = Drawing.new("Text")
    espName.Visible = true
    espName.Transparency = 1
    espName.ZIndex = 10
    espName.Color = color
    espName.Position = Vector2.new(0, 25)
    espName.Text = part.Parent.Name
    espName.Size = 20
    espName.Center = true
    espName.Outline = true
    espName.Font = Drawing.Fonts.Monospace

    local espMeds = Drawing.new("Text")
    espMeds.Visible = false
    espMeds.Transparency = 1
    espMeds.ZIndex = 10
    espMeds.Color = Color3.fromHex("#bbdb1a")
    espMeds.Position = Vector2.new(0, 50)
    espMeds.Text = ""
    espMeds.Size = 20
    espMeds.Center = true
    espMeds.Outline = true
    espMeds.Font = Drawing.Fonts.Monospace

    patientActiveESP[part.Address] = {
        Instance = part,
        EspDist = espDist,
        EspName = espName,
        EspMeds = espMeds,
        RoomName = room,
    }
end

local function deletePatientESP(address)
    local data = patientActiveESP[address]

    if data then
        if data.EspDist then data.EspDist:Remove() end
        if data.EspName then data.EspName:Remove() end
        if data.EspMeds then data.EspMeds:Remove() end
        patientActiveESP[address] = nil
    end
end

local function updatePatientESP()
    for address, data in pairs(patientActiveESP) do
        local part = data.Instance

        if not part then
            deletePatientESP(address)
            continue
        end

        if not part:IsDescendantOf(Workspace) then
            deletePatientESP(address)
            continue
        end

        local partPosition = part.Position

        if not partPosition then
            deletePatientESP(address)
            continue
        end

        local screnPosition, onScreen = WorldToScreen(partPosition)

        if not onScreen then
            data.EspDist.Visible = false
            data.EspName.Visible = false
            data.EspMeds.Visible = false
            continue
        end
        
        -- Update drawings
        local distance = getDistanceFromPlayer(part.Position, 3)

        data.EspDist.Text = string.format("[%d m]", distance)
        data.EspDist.Position = screnPosition + Vector2.new(0, -10)
        data.EspDist.Visible = true

        data.EspName.Position = screnPosition + Vector2.new(0, 10)
        data.EspName.Visible = true

        data.EspMeds.Position = screnPosition + Vector2.new(0, 35)
        data.EspMeds.Visible = (data.EspMeds.Text ~= "")
    end
end

-- Main Process
local function updateMedicineInfo()
    for roomName, rooms in pairs(hospitalRooms) do
        local medicines = rooms:FindFirstChild("Minigame") 
                and rooms.Minigame:FindFirstChild("TV") 
                and rooms.Minigame.TV:FindFirstChild("Screen") 
                and rooms.Minigame.TV.Screen:FindFirstChild("UI") 
                and rooms.Minigame.TV.Screen.UI:FindFirstChild("Report")
                and rooms.Minigame.TV.Screen.UI.Report:FindFirstChild("inv")

        if medicines then
            local names = {}
            for _, med in pairs(medicines:GetChildren()) do
                if med.Name == "UIGridLayout" then continue end
                table.insert(names, med.Name)
            end

            medicineCache[roomName] = table.concat(names, " | ")
        else
            medicineCache[roomName] = ""
        end
    end

    for _, data in pairs(patientActiveESP) do
        if not data.Instance.Parent:GetAttribute("Treated") or not data.Instance.Parent:GetAttribute("IsVisitor") then

            if data.RoomName then
                data.EspMeds.Text = medicineCache[data.RoomName]
            end
        end
    end
end

local function processPatient(patient)
    local part = patient:FindFirstChild(Config.PATIENT_ATTACH_PART)
    if not part then return end
    
    local data = patientActiveESP[part.Address]
    local room = patient:GetAttribute("DesignatedRoom")
    local color = getPatientColor(patient)

    -- Sync data if active
    if data then 
        data.EspName.Text = patient.Name
        data.EspName.Color = color
        data.RoomName = room
        return 
    end

    -- Stalker detector
    if string.match(patient.Name, "TallMonster") then
        notify("Stalker is spawned, avoid eye contact!", 8)
    end

    processPatientESP(part, getPatientColor(patient), room)
end

local function initializeScanner(location, wait_time)
    if not location then return error("Invalid location instance!") end

    -- run service for updatePatientESP
    RunService.RenderStepped:Connect(updatePatientESP)

    -- spawn new task for our npc scanner
    task.spawn(function()
        while true do
            for _, kid in pairs(location:GetChildren()) do
                if not checkIgnoredPatient(kid.Name) then
                    processPatient(kid)
                end
            end
            
            -- Handle EyeMass
            local EyeMass = Workspace.Rooms:FindFirstChild("EyeMass")

            if EyeMass then
                local part = EyeMass:FindFirstChild("Main")
                if part and not patientActiveESP[part.Address] then
                    processPatientESP(part, Color3.fromHex("#FF0000"), nil)
                end
            end

            updateMedicineInfo()
            task.wait(wait_time)
        end
    end)
end

-- scan for room instances
for _, room in pairs(Workspace.Rooms:GetDescendants()) do
    if room:IsA("Folder") and string.match(room.Name, "^Room%d$") then
        hospitalRooms[room.Name] = room
    end
end

-- Initializer
initializeScanner(Workspace.NPCs, 1)
