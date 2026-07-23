if getgenv().fjevgbrivgtuthui then
    warn("you have already executed trade helper")
    return
end
getgenv().fjevgbrivgtuthui = true
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local success232, result232 = pcall(function()
    return require(game:GetService("ReplicatedStorage"):WaitForChild("Collection"):WaitForChild("ItemDatabase"))
end)
if (not (success232 and result232)) or not fireproximityprompt then
    game:GetService("Players").LocalPlayer:Kick("unsupported executor, please try using delta or real executor")
    return
end
local success56, placeEnum = pcall(function()
    return require(game:GetService("ReplicatedStorage").Places.PlaceEnum)
end)
local success2, placeService = pcall(function()
    return require(game:GetService("ReplicatedStorage").Places.PlaceService)
end)
if not success56 or not success2 then
    game:GetService("Players").LocalPlayer:Kick("failed to load place modules")
    return
end
if not placeService.IsThisPlace(placeEnum.Trading) then
    game:GetService("Players").LocalPlayer:Kick("invalid place, please be in the trading hub!")
    return
end

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDatabase = require(ReplicatedStorage.Collection.ItemDatabase)
local PlayerCollection = require(ReplicatedStorage.Collection.PlayerCollectionService)
local myItems = PlayerCollection.GetCollection() or {}
local rawData = game:HttpGet("https://vexal.fun/files/d/valueList.json")
local valueData = HttpService:JSONDecode(rawData)

local function scanInventory()
    local colorKeywords = { "Purple", "Blue", "Yellow", "Gold", "Red", "Green", "Pink", "Orange", "Black", "White",
        "Cyan",
        "Magenta" }
    local idMap = {
        ["SG"] = "Sniper",
        ["G"]  = "Gun",
        ["K"]  = "Knife",
        ["LC"] = "Case",
        ["CD"] = "Banner",
        ["C"]  = "Case"
    }
    local function getCleanName(color, name, idName)
        local raw = color .. " " .. name .. " " .. idName
        local words = {}
        local result = {}
        for word in raw:gmatch("%S+") do
            local upper = string.upper(word)
            if not words[upper] then
                table.insert(result, word)
                words[upper] = true
            end
        end
        return table.concat(result, " ")
    end
    local function fetchValue(color, name, idName)
        if not valueData then return "Not Found", getCleanName(color, name, idName) end
        local typeFallback = (idName == "Gun" and "Revolver") or (idName == "Knife" and "Axe") or ""
        local checks = {
            { color, name,         idName },
            { name,  idName,       color },
            { color, name,         typeFallback },
            { name,  typeFallback, color }
        }
        for _, set in ipairs(checks) do
            local query = getCleanName(set[1], set[2], set[3])
            if query ~= "" then
                local upperQuery = string.upper(query)
                for _, data in ipairs(valueData) do
                    local apiName = string.upper(data.pets or "")
                    local match = true
                    for word in upperQuery:gmatch("%S+") do
                        if not apiName:find(word, 1, true) then
                            match = false
                            break
                        end
                    end
                    if match then return data.value or "N/A", query end
                end
            end
        end
        return "Not Found", getCleanName(color, name, idName)
    end
    local results = {}
    local calculatedInventory = {}
    for i = 1, #myItems do
        local item = myItems[i]
        local info = ItemDatabase.getEntry(item.Id)
        if info then
            local baseName = info.DisplayName or ""
            local uiName = info.DisplayNameOverride or info.DisplayName or ""
            local foundColor = ""
            for _, color in ipairs(colorKeywords) do
                if string.find(string.lower(baseName), string.lower(color), 1, true) then
                    foundColor = color
                    break
                end
            end
            local prefix = string.match(tostring(item.Id), "^%a+")
            local idName = idMap[prefix] or ""
            local itemValue, finalName = fetchValue(foundColor, uiName, idName)
            local last = results[#results]
            if last and last.name == finalName and last.value == itemValue then
                last.stop = i
            else
                table.insert(results, { start = i, stop = i, name = finalName, value = itemValue })
            end

            table.insert(calculatedInventory, { Index = i, Name = finalName, Value = itemValue })
        end
    end
    return results, calculatedInventory
end
local grouped, fullList = scanInventory()

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "Murder vs Sheriff Duels - Trade Helper",
    Icon = "rbxassetid://139687752061139",
    Author = "by Vexal Scripts",
    Folder = "MVSDTRADEHELPERVEXALSCRIPTS",
    Size = UDim2.fromOffset(650, 430),
    MinSize = Vector2.new(450, 250),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Sky",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
        end,
    },
})
Window:EditOpenButton({
    Title = "Vexal",
    Icon = "rbxassetid://139687752061139",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("0A1128"), -- dark blue
        Color3.fromHex("4B0082")  -- deep purple
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})
Window:Tag({
    Title = "NEW UPDATE",
    Icon = "shield-check",
    Color = Color3.fromHex("#30aaff"),
    Radius = 5,
})
local Welcome = Window:Tab({
    Title = "Welcome",
    Icon = "shield-user",
    Locked = false,
})
Welcome:Paragraph({
    Title = "Welcome to Vexal Scripts!!",
    Desc =
    "We hope you find this script useful, if you find any issues please report them below to my discord by making a ticket, thank you for using us!",
    Color = "Blue",
    Image = "rbxassetid://139687752061139",
    ImageSize = 60,
    Locked = false,
    Buttons = {
        {
            Icon = "link",
            Title = "Copy our Discord Link",
            Callback = function() setclipboard("https://dsc.gg/vexalscripts") end,
        }
    }
})
local ControlsTab = Window:Tab({
    Title = "My Inventory Controls",
    Icon = "settings",
})
local DatabaseTab = Window:Tab({
    Title = "123 Demands",
    Icon = "circle-check-big",
})

local ResultsTab = Window:Tab({
    Title = "Results",
    Icon = "list",
})
local LogParagraph = ResultsTab:Paragraph({
    Title = "Inventory Log",
    Desc = "waiting for you to click some buttons!",
    Color = "Blue",
})
WindUI:Notify({
    Title = "Welcome to Vexal Scripts MVSD",
    Duration = 15,
    Icon = "rbxassetid://139687752061139",
})
local searchQuery = ""
local dbSearchQuery = ""

local function updateUI(groupedResults)
    local fullText = ""
    local totalGroups = #groupedResults
    for _, entry in ipairs(groupedResults) do
        local range = (entry.start == entry.stop) and tostring(entry.start) or (entry.start .. "-" .. entry.stop)
        fullText = fullText .. string.format("[%s] %s | Value: %s\n", range, entry.name, entry.value)
    end
    LogParagraph:SetTitle("Success")
    LogParagraph:SetDesc(fullText)
end

ControlsTab:Input({
    Title = "Search Inventory",
    Desc = "Search an item from your inventory",
    Value = "",
    Type = "Input",
    Placeholder = "e.g. Reef",
    Locked = false,
    Callback = function(input)
        searchQuery = input
    end
})
ControlsTab:Button({
    Title = "Find Item",
    Desc = "Search an items value from your inventory",
    Locked = false,
    Callback = function()
        if searchQuery == "" then return end
        local results = ""
        local count = 0
        local upperQuery = string.upper(searchQuery)
        for _, item in ipairs(fullList) do
            if string.find(string.upper(item.Name), upperQuery, 1, true) then
                results = results .. string.format("[%d] %s | Value: %s\n", item.Index, item.Name, item.Value)
                count = count + 1
            end
        end
        LogParagraph:SetTitle("Search: " .. searchQuery .. " (" .. count .. " Found)")
        LogParagraph:SetDesc(results ~= "" and results or "No matches found.")
        ResultsTab:Select()
    end
})
ControlsTab:Button({
    Title = "Load Calculated Inventory",
    Desc = "Show all values of your inventory",
    Locked = false,
    Callback = function()
        local totalValue = 0
        local results = ""
        for _, v in ipairs(fullList) do
            local numValue = tonumber(v.Value) or 0
            totalValue = totalValue + numValue
            results = results .. string.format("[%d] %s | %s\n", v.Index, v.Name, v.Value)
        end
        local formattedTotal
        if totalValue >= 1000000 then
            formattedTotal = string.format("%.2fM", totalValue / 1000000)
        elseif totalValue >= 1000 then
            formattedTotal = string.format("%.2fK", totalValue / 1000)
        else
            formattedTotal = tostring(totalValue)
        end
        results = "Total Inventory Value: " .. formattedTotal .. "\n\n" .. results
        LogParagraph:SetTitle("Calculated Inventory (" .. #fullList .. " Items)")
        LogParagraph:SetDesc(results)
        ResultsTab:Select()
    end
})
ControlsTab:Button({
    Title = "Load Grouped View",
    Desc = "Show condensed values of your inventory",
    Locked = false,
    Callback = function()
        updateUI(grouped)
        ResultsTab:Select()
    end
})
DatabaseTab:Input({
    Title = "Detailed Searching",
    Desc = "Search any item using 123demands!",
    Value = "",
    Type = "Input",
    Placeholder = "e.g. Shimmer",
    Locked = false,
    Callback = function(input)
        dbSearchQuery = input
    end
})
DatabaseTab:Button({
    Title = "Search 123Demands",
    Desc = "Search global values, demand, and rarity",
    Locked = false,
    Callback = function()
        if dbSearchQuery == "" then return end
        local results = ""
        local count = 0
        local upperQuery = string.upper(dbSearchQuery)
        if valueData then
            for _, data in ipairs(valueData) do
                local itemName = data.pets or "Unknown"
                if string.find(string.upper(itemName), upperQuery, 1, true) then
                    local val = data.value or "N/A"
                    local dem = data.demand or "N/A"
                    local rar = data.rarity or "N/A"

                    results = results ..
                        string.format("%s\nValue: %s | Demand: %s\nRarity: %s\n\n", itemName, val, dem, rar)
                    count = count + 1
                end
                if count >= 20 then
                    results = results .. "...and more. Try a specific search!"
                    break
                end
            end
        end
        LogParagraph:SetTitle("Database Results: " .. dbSearchQuery)
        LogParagraph:SetDesc(count > 0 and results or "No items found from 123demands")
        ResultsTab:Select()
    end
})

Welcome:Select()
