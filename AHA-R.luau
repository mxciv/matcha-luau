
local CONF_TOP_SPACING      = 3
local CONF_BOTTOM_SPACING   = 10
local CONF_SCANNER_INTERVAL = 1 -- seconds

local Workspace             = game:GetService("Workspace")
local RunService            = game:GetService("RunService")

local espData               = {}
local medicineData          = {}

local BasePartTypes         = {
	["Part"]                = "BasePart",
	["MeshPart"]            = "BasePart",
	["UnionOperation"]      = "BasePart",
	["Model"]               = "Model",
}

local cornerOffsets         = {
	Vector3.new(-1, -1, -1), Vector3.new( 1, -1, -1),
	Vector3.new( 1, -1,  1), Vector3.new(-1, -1,  1),
	Vector3.new(-1,  1, -1), Vector3.new( 1,  1, -1),
	Vector3.new( 1,  1,  1), Vector3.new(-1,  1,  1),
}

local function getPatientMedicine(room)
    if not room or room == "" then print("Or here?") return "" end
    if not medicineData[room] then print("Here?") return "" end

    local ret = {}
    local instance = medicineData[room]

    for _, med in pairs(instance:GetChildren()) do
        if med.Name == "UIGridLayout" then continue end
        table.insert(ret, med.Name)
		print("Found:", med.Name)
    end

    return table.concat(ret, " | ")
end

local function addESP(part)
    if not part then return end

    -- Get Patient Data
    local parent = part.Parent
    if BasePartTypes[parent.ClassName] ~= "Model" then return end

    local isAnomaly = parent:GetAttribute("IsAnomaly") or parent:GetAttribute("Skinwalker") or false
    local isVisitor = parent:GetAttribute("IsVisitor") or false
    local isPatient = parent:GetAttribute("IsPatient") or false
    local isTreated = parent:GetAttribute("Treated") or false
    local roomInfo  = parent:GetAttribute("DesignatedRoom") or ""
    
    -- Build patient data based on attributes
    local name      = parent.Name
    local info      = ""
    local medicine  = getPatientMedicine(roomInfo)
    local color     = Color3.fromHex("#FFFFFF")

    -- Ratthew name replacer
    if name and name == "???" then name = "Ratthew" end

    -- Info builder
    if isVisitor then 
        info        = "Visitor"
        color       = Color3.fromHex("#00FF00")
    elseif isPatient then 
        info        = "Patient"
        color       = Color3.fromHex("#7abdff")
    elseif isAnomaly then
        info        = "Anomaly" 
        color       = Color3.fromHex("#FF0000")
    end

    -- Update existing data here if available
    if espData[part.Address] then
        local data      = espData[part.Address]
        data.Name.Text  = name
        data.Type.Text  = info
        data.Type.Color = color
        data.Info.Text  = medicine
        return
    end

    -- Build drawing ESP
    local espName = Drawing.new("Text")
    espName.Visible = true
    espName.Transparency = 1
    espName.ZIndex = 20
    espName.Color = Color3.fromHex("#FFFFFF")
    espName.Position = Vector2.new(399, 182)
    espName.Text = name
    espName.Size = 20
    espName.Center = true
    espName.Outline = true
    espName.Font = Drawing.Fonts.Monospace

    local espType = Drawing.new("Text")
    espType.Visible = true
    espType.Transparency = 1
    espType.ZIndex = 20
    espType.Color = color
    espType.Position = Vector2.new(399, 210.5)
    espType.Text = info
    espType.Size = 18
    espType.Center = true
    espType.Outline = true
    espType.Font = Drawing.Fonts.Monospace

    local espInfo = Drawing.new("Text")
    espInfo.Visible = true
    espInfo.Transparency = 1
    espInfo.ZIndex = 30
    espInfo.Color = Color3.fromHex("#00FF00")
    espInfo.Position = Vector2.new(399, 381)
    espInfo.Text = medicine
    espInfo.Size = 20
    espInfo.Center = true
    espInfo.Outline = true
    espInfo.Font = Drawing.Fonts.Monospace

    local espBox = Drawing.new("Square")
    espBox.Visible = true
    espBox.Transparency = 1
    espBox.ZIndex = 40
    espBox.Color = Color3.fromHex("#FFFFFF")
    espBox.Position = Vector2.new(350, 250)
    espBox.Size = Vector2.new(100, 100)
    espBox.Filled = false

    espData[part.Address] = {
        Instance = part,
        Name = espName,
        Type = espType,
        Info = espInfo,
        Box = espBox,
    }
end

local function removeESP(address)
    if not address then return end
    if not espData[address] then return end
    
    local data = espData[address]

    data.Box:Remove()
    espData[address] = nil
end

local function getScreenBoundingBox(part)
    if not part then return nil end

    local pos = part.Position
    local size = part.Size
    local half = size * 0.5
    local visible = false

    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    
    for i = 1, 8 do
        local corner = cornerOffsets[i]
        local worldPos = Vector3.new(
            pos.X + corner.X * half.X,
            pos.Y + corner.Y * half.Y,
            pos.Z + corner.Z * half.Z
        )

        local screenPos, onScreen = WorldToScreen(worldPos)
		if onScreen then
            visible = true
            minX = math.min(minX, screenPos.X)
            minY = math.min(minY, screenPos.Y)
            maxX = math.max(maxX, screenPos.X)
            maxY = math.max(maxY, screenPos.Y)
        end
    end
    
    if not visible then return nil end
    return minX, minY, maxX, maxY
end

RunService.RenderStepped:Connect(function()
    for address, data in pairs(espData) do
        local dataPart = data.Instance

        if not dataPart then
            removeESP(address)
            continue
        end

        local partPos = dataPart.Position

        local screenPos, onScreen = WorldToScreen(partPos)
        local minX, minY, maxX, maxY = getScreenBoundingBox(dataPart)

        data.Name.Visible = onScreen
        data.Type.Visible = onScreen
        data.Info.Visible = onScreen

        if minX == nil then 
            data.Box.Visible = false
			continue 
		end

        if onScreen then
            local topCenterX = (minX + maxX) / 2

            local nameBounds = data.Name.TextBounds
            local typeBounds = data.Type.TextBounds

            data.Name.Position = Vector2.new(topCenterX, minY - nameBounds.Y - typeBounds.Y - CONF_TOP_SPACING)
            data.Type.Position = Vector2.new(topCenterX, minY - typeBounds.Y)
            data.Info.Position = Vector2.new(topCenterX, maxY + CONF_BOTTOM_SPACING)

            data.Box.Position = Vector2.new(minX, minY)
            data.Box.Size = Vector2.new(maxX - minX, maxY - minY)
            data.Box.Visible = true
        end

    end
end)

-- Initializers
local Rooms = Workspace:FindFirstChild("Rooms")
if not Rooms then return notify("Failed to initialize script (Error: Cannot found Rooms path)", "Sol's AHA", 5) end

-- Room medicine detections
for _, room in ipairs(Rooms.Medical:GetChildren()) do
    print("Found", room.Name)
    for _, instance in ipairs(room:GetDescendants()) do
        if instance.Name == "inv" and instance.ClassName == "Frame" then
            medicineData[room.Name] = instance
            print("Found instance!")
			print(room.Name, instance.Name)
        end
    end
end

for _, room in ipairs(Rooms.Emergency:GetChildren()) do
    print("Found", room.Name)
    for _, instance in ipairs(room:GetDescendants()) do
        if instance.Name == "inv" and instance.ClassName == "Frame" then
            medicineData[room.Name] = instance
            print("Found instance!")
			print(room.Name, instance.Name)
        end
    end
end

-- Scanners
local NPCs = Workspace:FindFirstChild("NPCs")
if not NPCs then return notify("Failed to initialize script (Error: Cannot found NPC path)", "Sol's AHA", 5) end

task.spawn(function()
    while true do
        for _, instance in ipairs(NPCs:GetChildren()) do
            local hrp = instance:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end -- skip
            addESP(hrp)
        end

        task.wait(CONF_SCANNER_INTERVAL)
    end
end)
