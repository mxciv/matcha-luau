local OffsetService = {}
OffsetService.__index = OffsetService

local HttpService = game:GetService("HttpService")

function OffsetService:GetTheoOffset(v)
    -- Get latest update
    if not v then v = "version-5cf2272675e145f5" end
    local channel = game:HttpGet("https://clientsettings.roblox.com/v2/client-version/WindowsPlayer/channel/live")
    local data = HttpService:JSONDecode(channel)
    if data then v = data.clientVersionUpload end

    -- Get theo offsets from LIVE channel
    local ok, response = pcall(function() return game:HttpGet(string.format("https://offsets.imtheo.lol/%s/offsets.json", v)) end)
    if not ok or not response then return {} end

    -- Fetch the data first, and then determine if the data nil or nah
    local data = HttpService:JSONDecode(response)
    return data and data.Offsets or {}
end

_G.OffsetService = OffsetService
return OffsetService
