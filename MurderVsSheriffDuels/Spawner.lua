if _G.dfhsjeesjidcvfej then
    print("already executed")
    return
end
_G.dfhsjeesjidcvfej = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playercollectionservice = require(ReplicatedStorage.Collection.PlayerCollectionService)
local itemdatabase = require(ReplicatedStorage.Collection.ItemDatabase)
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local TextFormat = require(ReplicatedStorage.Modules.Util.TextFormat)

local itemNames = {}
local itemMetadata = {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScannerGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 150)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(35, 35, 35)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -24, 0, 50)
TitleLabel.Position = UDim2.new(0, 12, 0, 8)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Please hang on, we are scanning MVSD's database!"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextWrapped = true
TitleLabel.Parent = MainFrame

local GunsLabel = Instance.new("TextLabel")
GunsLabel.Size = UDim2.new(1, -24, 0, 35)
GunsLabel.Position = UDim2.new(0, 12, 0, 68)
GunsLabel.BackgroundTransparency = 1
GunsLabel.Text = "GUNS: 0 / 200"
GunsLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
GunsLabel.TextSize = 14
GunsLabel.Font = Enum.Font.GothamMedium
GunsLabel.Parent = MainFrame

local KnivesLabel = Instance.new("TextLabel")
KnivesLabel.Size = UDim2.new(1, -24, 0, 35)
KnivesLabel.Position = UDim2.new(0, 12, 0, 105)
KnivesLabel.BackgroundTransparency = 1
KnivesLabel.Text = "KNIVES: 0 / 200"
KnivesLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
KnivesLabel.TextSize = 14
KnivesLabel.Font = Enum.Font.GothamMedium
KnivesLabel.Parent = MainFrame

local function scanDatabase(prefix, maxCount, label, labelPrefix)
    for i = 1, maxCount do
        label.Text = labelPrefix .. i .. " / " .. maxCount
        local currentId = prefix .. i
        local success, info = pcall(function() return itemdatabase.getEntry(currentId) end)
        if success and info and info.DisplayName then
            local displayName = info.DisplayName
            table.insert(itemNames, displayName)
            itemMetadata[displayName] = {
                -- more feild, but not needed for spawning
                Name = info.DisplayName or "Unknown",
                Rarity = info.Rarity or "Common",
                Type = info.Type or "Gun",
                Id = currentId
            }
        end
        task.wait(0.01)
    end
end

if #itemNames == 0 then
    itemNames = { "Default Item" }
    itemMetadata["Default Item"] = { Name = "Default Item", Rarity = "Common", Type = "Gun", Id = "G22" }
end
table.sort(itemNames)

scanDatabase("G", 200, GunsLabel, "GUNS: ")
scanDatabase("K", 200, KnivesLabel, "KNIVES: ")
ScreenGui:Destroy()

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Vexal Scripts | Spawner Script",
    SubTitle = "Murder vs Sheriff Duels",
    TabWidth = 120,
    Size = UDim2.fromOffset(500, 300),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})
local Main = Window:AddTab({ Title = "Main", Icon = "home" })
local Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
local Options = Fluent.Options
Main:AddParagraph({
    Title = "Information",
    Content = "May lag for few seconds when executing, fetching game's database."
})

local ItemDropdown = Main:AddDropdown("ItemDropdown", {
    Title = "Item to Spawn",
    Values = itemNames,
    Multi = false,
    Default = itemNames[1],
})
local lastSpawn = 0
local cooldownTime = 10
local SpawnButton = Main:AddButton({
    Title = "Spawn Item",
    Description = "Adds the selected item to your local inventory",
    Callback = function()
        local timePassed = os.time() - lastSpawn
        if timePassed < cooldownTime then
            Fluent:Notify({
                Title = "Cooldown",
                Content = "You have " ..
                    tostring(cooldownTime - timePassed) .. " seconds left before spawning another item!",
                Duration = 3
            })
            return
        end
        lastSpawn = os.time()
        local currentSelection = ItemDropdown.Value
        local meta = itemMetadata[currentSelection]
        if meta then
            local globalCollection = playercollectionservice.GetCollection()
            if type(globalCollection) == "table" then
                local localInventoryCopy = {}
                table.insert(localInventoryCopy,
                    { Name = meta.Name, Rarity = meta.Rarity, Type = meta.Type, Id = meta.Id, SpawnedVexal = true })
                for idx, existingItem in ipairs(globalCollection) do
                    table.insert(localInventoryCopy,
                        {
                            Name = existingItem.Name,
                            Rarity = existingItem.Rarity,
                            Type = existingItem.Type,
                            Id =
                                existingItem.Id,
                            SpawnedVexal = existingItem.SpawnedVexal
                        })
                end
                table.clear(globalCollection)
                for _, restoredItem in ipairs(localInventoryCopy) do
                    table.insert(globalCollection, restoredItem)
                end
                local rarityValues = {
                    Common = 10,
                    Uncommon = 50,
                    Rare = 250,
                    UltraRare = 1500,
                    Legendary = 20000,
                    Collectible = 150000,
                }
                local oldCollectionRating = Players.LocalPlayer:GetAttribute('CollectionRating') or 0
                local rarityValue = rarityValues[meta.Rarity] or 0
                local newCollectionRating = oldCollectionRating + rarityValue
                Players.LocalPlayer:SetAttribute('CollectionRating', newCollectionRating)
                local ratingTextLabel = PlayerGui:FindFirstChild('Collection') and
                PlayerGui.Collection:FindFirstChild('Frame') and PlayerGui.Collection.Frame:FindFirstChild('BodyFrame') and
                PlayerGui.Collection.Frame.BodyFrame:FindFirstChild('EntryFrame') and
                PlayerGui.Collection.Frame.BodyFrame.EntryFrame:FindFirstChild('Frame') and
                PlayerGui.Collection.Frame.BodyFrame.EntryFrame.Frame:FindFirstChild('RatingTextLabel')
                if ratingTextLabel then
                    ratingTextLabel.Text = TextFormat.withCommas(newCollectionRating)
                end
                local function updateAllRatingLabels(parent)
                    for _, descendant in pairs(parent:GetDescendants()) do
                        if descendant:IsA('TextLabel') or descendant:IsA('TextButton') then
                            if descendant.Text == TextFormat.withCommas(oldCollectionRating) then
                                descendant.Text = TextFormat.withCommas(newCollectionRating)
                            end
                        end
                    end
                end
                updateAllRatingLabels(PlayerGui)
                if workspace:FindFirstChild('GUI') then
                    updateAllRatingLabels(workspace.GUI)
                end
                task.wait(0.5)
                updateAllRatingLabels(PlayerGui)
                if workspace:FindFirstChild('GUI') then
                    updateAllRatingLabels(workspace.GUI)
                end
            end
        end
        Fluent:Notify({
            Title = "Success",
            Content = "Spawned " ..
                tostring(currentSelection) .. " (" .. (meta and meta.Id or "N/A") .. ")",
            Duration = 3
        })
    end
})
task.spawn(function()
    if CoreGui:FindFirstChild("VexalToggle") then CoreGui.VexalToggle:Destroy() end
    local ToggleButton = Instance.new("ScreenGui")
    local Button = Instance.new("ImageButton")
    local UICorner = Instance.new("UICorner")
    local UIStroke = Instance.new("UIStroke")
    local Gradient = Instance.new("UIGradient")

    ToggleButton.Name, ToggleButton.Parent, ToggleButton.ZIndexBehavior = "VexalToggle", CoreGui,
        Enum.ZIndexBehavior.Sibling
    Button.Name, Button.Parent, Button.BackgroundColor3, Button.Position, Button.Size, Button.Image, Button.Active, Button.Draggable =
        "ToggleButton", ToggleButton, Color3.fromRGB(30, 30, 30), UDim2.new(0, 15, 0.5, 0), UDim2.new(0, 50, 0, 50),
        "", true, true
    Gradient.Transparency, Gradient.Rotation, Gradient.Parent =
        NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.85, 0),
            NumberSequenceKeypoint
                .new(1, 1) }), 45, Button
    UIStroke.Color, UIStroke.Thickness, UIStroke.Transparency, UIStroke.Parent = Color3.fromRGB(0, 0, 0), 1.5, 0.5,
        Button
    UICorner.CornerRadius, UICorner.Parent = UDim.new(0, 12), Button

    Button.MouseButton1Click:Connect(function()
        task.spawn(function()
            TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Size = UDim2.new(0, 42, 0, 42) }):Play()
            task.wait(0.1)
            TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Size = UDim2.new(0, 50, 0, 50) }):Play()
        end)
        if Window then Window:Minimize() end
    end)
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("VexalMvsd")
SaveManager:SetFolder("VexalMvsd/configs")
InterfaceManager:BuildInterfaceSection(Settings)
SaveManager:BuildConfigSection(Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
Fluent:Notify({
    Title = "Vexal Scripts",
    Content = "Script loaded successfully, Enjoy!",
    Duration = 15
})
