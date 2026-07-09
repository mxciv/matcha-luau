
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Character = Players.LocalPlayer.Character
local NPC = Workspace.NPCs
local Rooms = Workspace.Rooms

local activePatient = {}
local npcRooms = {}

if not NPC then
    return error("Can't find the NPC folder!")
end

if not Rooms then
    return error("Can't find the Rooms folder!")
end

local function getDistanceFromPlayer(position, studs_per_unit)
    if not position then return 0 end

    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end

    return math.floor((hrp.Position - position).Magnitude / studs_per_unit)
end

local function getMedicineInfo(roomName)
    local roomInstance = npcRooms[roomName]
    if not roomInstance then return "" end
    
    -- Peak child
    local reports = roomInstance:FindFirstChild("Minigame") 
        and roomInstance.Minigame:FindFirstChild("TV") 
        and roomInstance.Minigame.TV:FindFirstChild("Screen") 
        and roomInstance.Minigame.TV.Screen:FindFirstChild("UI") 
        and roomInstance.Minigame.TV.Screen.UI:FindFirstChild("Report") 
        and roomInstance.Minigame.TV.Screen.UI.Report:FindFirstChild("inv")
    
    if reports then
        local names = {}
        for _, med in pairs(reports:GetChildren()) do
            if med.Name == "UIGridLayout" then continue end
            table.insert(names, med.Name)
        end

        return table.concat(names, " | ")
    end

    return ""
end

local function processRoomMonster(monster)
    if not monster then return end
    
    local main = monster:FindFirstChild("Main")
    if not main then return end

    if activePatient[main.Address] then return end

    -- Render ESP
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
    espName.Color = Color3.fromHex("#FF0000")
    espName.Position = Vector2.new(0, 25)
    espName.Text = monster.Name or "Unknown"
    espName.Size = 20
    espName.Center = true
    espName.Outline = true
    espName.Font = Drawing.Fonts.Monospace

    -- Store everything in this
    activePatient[main.Address] = {
        Part = main,
        Instances = {
            Distance = espDist,
            Name = espName,
            Meds = nil
        }
    }
end

local function processPatient(patient)
    if not patient then return end

    -- Atributes data
    local isAnomaly = (patient:GetAttribute("Skinwalker") or patient:GetAttribute("IsAnomaly")) or false
    local isVisitor = patient:GetAttribute("IsVisitor") or false
    local isPatient = patient:GetAttribute("IsPatient") or false
    local isTreated = patient:GetAttribute("Treated") or false
    local patientRooms = patient:GetAttribute("DesignatedRoom") or ""

    -- Get Color
    local patientColor = Color3.fromHex("#FFFFFF")
    if      isAnomaly then patientColor = Color3.fromHex("#FF0000")
    elseif  isVisitor then patientColor = Color3.fromHex("#00FF00")
    elseif  isPatient then patientColor = Color3.fromHex("#55AAFF") end

    -- Check for hrp
    local hrp = patient:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Update active ESP data
    if activePatient[hrp.Address] then
        local data = activePatient[hrp.Address]
        data.Instances.Name.Text = patient.Name
        data.Instances.Name.Color = patientColor

        if not isVisitor then 
            data.Instances.Meds.Text = (not isTreated) and getMedicineInfo(patientRooms) or ""
        end
        return
    end

    -- Render ESP
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
    espName.Color = patientColor
    espName.Position = Vector2.new(0, 25)
    espName.Text = patient.Name or "Unknown Patient"
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

    -- Store everything in this
    activePatient[hrp.Address] = {
        Part = hrp,
        Instances = {
            Distance = espDist,
            Name = espName,
            Meds = espMeds
        }
    }
end

local function disconnectESP(address)
    local data = activePatient[address]
    if not data then return end

    data.Instances.Distance:Remove()
    data.Instances.Name:Remove()

    if data.Instances.Meds then 
        data.Instances.Meds:Remove() 
    end

    activePatient[address] = nil
end

-- Initialize rooms instance
for _, room in pairs(Rooms:GetDescendants()) do
    if string.match(room.Name, "^Room%d$") then
        npcRooms[room.Name] = room
    end
end

task.spawn(function()
    while true do
        for _, kid in pairs(NPC:GetChildren()) do
			if kid.Name == "Doctor" then continue end
            processPatient(kid)
        end

        for _, room in pairs(npcRooms) do
            local monster = room:FindFirstChild("EyeMass") or room:FindFirstChild("MonsterBed")

            if monster then
                processRoomMonster(monster)
            end
        end

        task.wait(1) -- scan every second
    end
end)

RunService.RenderStepped:Connect(function()
    for address, data in pairs(activePatient) do
        local part = data.Part

        if not part then
            disconnectESP(address)
            continue
        end

        if not part:IsDescendantOf(Workspace) then
            disconnectESP(address)
            continue
        end

        local partPosition = part.Position

        if not partPosition then
            disconnectESP(address)
            continue
        end

        local screenPosition, onScreen = WorldToScreen(partPosition)
        
        if not onScreen then
            data.Instances.Distance.Visible = false
            data.Instances.Name.Visible     = false
            if data.Instances.Meds then data.Instances.Meds.Visible = false end
            continue
        end

        local distance = getDistanceFromPlayer(partPosition, 3)

        data.Instances.Distance.Visible     = true
        data.Instances.Distance.Text        = "["..distance.." m]"
        data.Instances.Distance.Position    = Vector2.new(
            screenPosition.X,
            screenPosition.Y - 10
        )
        
        data.Instances.Name.Visible         = true
        data.Instances.Name.Position        = Vector2.new(
            screenPosition.X,
            screenPosition.Y + 10
        )
        
        if data.Instances.Meds then
            data.Instances.Meds.Visible     = true
            data.Instances.Meds.Position    = Vector2.new(
                screenPosition.X,
                screenPosition.Y + 35
            )
        end
    end
end)
