if _G.VexalScriptsExecuted then
    print("you've already executed this!")
    return
end
_G.VexalScriptsExecuted = true

local VexalLogo = "rbxassetid://139687752061139"
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
    Icon = "user-lock",
    Author = "by Vexal Scripts - deyvis",
    Folder = "ConfigsVexalScripts",
    Size = UDim2.fromOffset(530, 410),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey = Enum.KeyCode.LeftControl,
    Transparent = false,
    Theme = "Dark", -- autoset
    Resizable = true,
    SideBarWidth = 175,
    BackgroundImageTransparency = 1,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    User = {
        Enabled = true,
        Anonymous = true,
        Callback = function()
            --print("clicked")
        end,
    },
})
Window:EditOpenButton({
    Title = "Open Vexal Scripts",
    Icon = "user-lock",
    CornerRadius = UDim.new(0, 8),
    StrokeThickness = 0.5,
    Color = ColorSequence.new(
        Color3.fromHex("#7c5cff"),
        Color3.fromHex("#e2f0fd")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})
Window:CreateTopbarButton("Discord", "message-circle-question-mark",
    function() setclipboard("https://dsc.gg/vexalscr1pts") end, 990)
Window:Tag({
    Title = "V3",
    Icon = "flame",
    Color = Color3.fromHex("#7c5cff"),
    Radius = 3,
})

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Collection = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer

getgenv().match = false -- whether player is in match or not
local canShoot = true
local matchEnemies = {}

task.spawn(function() -- match status tracking
    while true do
        if Player then
            if Player:GetAttribute("Match") then
                getgenv().match = true
            else
                getgenv().match = false
            end
        end
        task.wait(0.1)
    end
end)
task.spawn(function() -- match players tracking
    while task.wait(0.1) do
        local currentMatch = Player:GetAttribute("Match")
        local tempTable = {}
        if currentMatch then
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= Player and v:GetAttribute("Match") == currentMatch then
                    local char = v.Character
                    if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                        table.insert(tempTable, v)
                    end
                end
            end
        end
        matchEnemies = tempTable
    end
end)
task.spawn(function() -- gun cooldown tracking
    local lastGunTracked = nil
    local soundConnection = nil
    while task.wait(0.1) do
        local character = Player.Character
        local gun = nil
        local locations = { Player:FindFirstChild("Backpack") }
        if character then table.insert(locations, character) end
        for _, container in ipairs(locations) do
            if container then
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") and tool:FindFirstChild("Fire") and tool:FindFirstChild("Reload") then
                        gun = tool
                        break
                    end
                end
            end
            if gun then break end
        end
        if gun then
            if gun ~= lastGunTracked then
                lastGunTracked = gun
                if soundConnection then soundConnection:Disconnect() end
                local fireSound = gun:FindFirstChild("Fire")
                if fireSound and fireSound:IsA("Sound") then
                    soundConnection = fireSound.Played:Connect(function()
                        lastFiredTime = tick()
                    end)
                end
            end
        else
            lastGunTracked = nil
            if soundConnection then
                soundConnection:Disconnect()
                soundConnection = nil
            end
        end
    end
end)

local function getGun() -- returns your gun tool
    local character = Player.Character
    local locations = { Player:FindFirstChild("Backpack") }
    if character then table.insert(locations, character) end
    for _, container in ipairs(locations) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("Fire") and tool:FindFirstChild("Reload") then
                    return tool
                end
            end
        end
    end
    return nil
end
local function equipGun()
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")
    if not character or not backpack then
        return false
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    if getgenv().match then
        local gun = getGun()
        if gun then
            humanoid:EquipTool(gun)
            return true
        end
    end
    return false
end
local function equipKnife()
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")
    if not character or not backpack then
        return false
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    if getgenv().match then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("EquipAnimation") == "Knife_Equip" then
                humanoid:EquipTool(tool)
                return true
            end
        end
    end
    return false
end
local BulletRendererColor = Color3.fromRGB(255, 255, 255)
local function BulletRenderer(origin, targetPos)
    local function CreatePseudoPart(cf)
        local p = Instance.new("Part")
        p.Size = Vector3.new(0.1, 0.1, 0.1)
        p.Transparency = 1
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.Anchored = true
        p.CFrame = cf
        p.Parent = workspace
        return p
    end
    local startPart = CreatePseudoPart(CFrame.lookAt(origin, targetPos) * CFrame.new(0, 0, -1))
    local endPart = CreatePseudoPart(CFrame.new(targetPos))
    local beam = Instance.new("Beam")
    beam.Texture = ""
    beam.TextureLength = 1
    beam.TextureMode = Enum.TextureMode.Stretch
    beam.TextureSpeed = 0
    beam.Color = ColorSequence.new(BulletRendererColor)
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Brightness = 5
    beam.Width0 = 0
    beam.Width1 = 0
    local att0 = Instance.new("Attachment", startPart)
    local att1 = Instance.new("Attachment", endPart)
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Parent = startPart
    local fadeIn = TweenService:Create(beam, TweenInfo.new(0.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
        Width0 = 0.3,
        Width1 = 0.6
    })
    local fadeOut = TweenService:Create(beam, TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        Width0 = 0,
        Width1 = 0
    })
    fadeIn:Play()
    fadeIn.Completed:Connect(function()
        fadeOut:Play()
    end)
    Debris:AddItem(startPart, 0.3)
    Debris:AddItem(endPart, 0.3)
end
local function CharacterRayOrigin(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    return (hrp.CFrame * CFrame.new(0, 0, hrp.Size.Z / 2)).Position
end
local function ShootGun(target) -- target: player instance
    local myChar = Player.Character
    if not myChar then return end
    local origin = CharacterRayOrigin(myChar)
    if not origin then return end
    local hitPart = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
    local tool = getGun()
    if not tool then return end
    if hitPart then
        canShoot = false
        local targetPos = hitPart.Position
        local muzzle = tool:FindFirstChild("Muzzle", true)
        local startPos = muzzle and muzzle.WorldPosition or origin
        BulletRenderer(startPos, targetPos)
        ReplicatedStorage.Remotes.ShootGun:FireServer(origin, targetPos, hitPart, targetPos)
        local sound = tool and tool:FindFirstChild("Fire")
        if sound and sound:IsA("Sound") then
            sound:Play()
        end
        task.delay(2.5, function()
            canShoot = true
        end)
    end
end
local lastNotify = 0
local function NotSupportedFeature()
    local currentTime = tick()
    if currentTime - lastNotify >= 5 then
        lastNotify = currentTime

        WindUI:Notify({
            Title = "Uh Oh! Executor not supported!",
            Content =
            "Sorry! Your executor isn't supported to run this feature, we have made sure of that by running simple checks once you loaded this script!",
            Duration = 3,
            Icon = VexalLogo,
        })

        WindUI:Notify({
            Title = "Notice!",
            Content = "If your on PC/Laptop, try using Velocity (its free!), on Android/Ios please try using Delta!",
            Duration = 3,
            Icon = VexalLogo,
        })
    end
end
local function FeatureActivated(boolean)
    if boolean then
        WindUI:Notify({
            Title = "Activated Feature!!",
            Content =
            "Enjoying Vexal Scripts? Join our discord server located in the Welcome tab for even better stuff!",
            Duration = 3,
            Icon = VexalLogo,
        })
    else
        WindUI:Notify({
            Title = "Disabled Feature!!",
            Content =
            "Enjoying Vexal Scripts? Join our discord server located in the Welcome tab for even better stuff!",
            Duration = 3,
            Icon = VexalLogo,
        })
    end
end

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house",
    Locked = false,
})
local FeaturesSection = MainTab:Section({ 
    Title = "Features",
    Opened = true
})

local autounanchor = false
FeaturesSection:Toggle({ -- Auto UnAnchor Character
    Title = "Auto UnAnchor Character",
    Desc = "Bypasses the 10s and 5s wait before a match starts and lets you move around",
    Default = false,
    Callback = function(Value)
        autounanchor = Value
        local function monitorCharacter(character)
            local rootPart = character:WaitForChild("HumanoidRootPart", 5)
            local humanoid = character:WaitForChild("Humanoid", 5)
            if not rootPart or not humanoid then return end
            local connection
            connection = RunService.Heartbeat:Connect(function()
                if not character.Parent or humanoid.Health <= 0 then
                    connection:Disconnect()
                    return
                end
                if rootPart.Anchored and autounanchor then
                    rootPart.Anchored = false
                end
            end)
        end
        if Player.Character then
            task.spawn(monitorCharacter, Player.Character)
        end
        Player.CharacterAdded:Connect(monitorCharacter)
    end
})
getgenv().original_cooldowns = {}
FeaturesSection:Toggle({ -- remove gun cooldown
    Title = "Remove gun cooldown",
    Desc = "You may need to re-equip your weapon for changes to apply",
    Icon = "check",
    Default = false,
    Flag = "RemoveGunCooldownToggle",
    Callback = function(Value)
        getgenv().remove_gun_cooldown = Value
        if getgenv().remove_gun_cooldown then
            FeatureActivated(true)
        else
            FeatureActivated(false)
        end
        if Value then
            getgenv().original_cooldowns = {}
            task.spawn(function()
                while getgenv().remove_gun_cooldown do
                    task.wait(0.1)
                    local tools = {}
                    for _, container in ipairs({ Player:FindFirstChild("Backpack"), Player.Character }) do
                        if container then
                            for _, tool in ipairs(container:GetChildren()) do
                                if tool:IsA("Tool") and tool:FindFirstChild("Fire") then
                                    table.insert(tools, tool)
                                end
                            end
                        end
                    end
                    for _, tool in ipairs(tools) do
                        if getgenv().original_cooldowns[tool] == nil then
                            getgenv().original_cooldowns[tool] = tool:GetAttribute("Cooldown")
                        end
                        if tool:GetAttribute("Cooldown") ~= 0 then
                            tool:SetAttribute("Cooldown", 0)
                        end
                    end
                end
            end)
        else
            for tool, cooldown in pairs(getgenv().original_cooldowns) do
                if tool and tool.Parent then
                    tool:SetAttribute("Cooldown", cooldown)
                end
            end
            getgenv().original_cooldowns = {}
        end
    end,
})
FeaturesSection:Space()
getgenv().autoshoot_enabled = false
getgenv().max_distance = 300
getgenv().autoshoot_cooldown = 2
local autoshoot_thread = nil
FeaturesSection:Toggle({ -- Autoshoot
    Title = "Autoshoot",
    Desc = "Automatically shoot players for you",
    Default = false,
    Callback = function(Value)
        getgenv().autoshoot_enabled = Value
        FeatureActivated(Value)
        if autoshoot_thread then
            task.cancel(autoshoot_thread)
            autoshoot_thread = nil
        end
        if getgenv().autoshoot_enabled then
            local function has_clear_los(fromPos, toPos, myCharacter, targetCharacter)
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = { myCharacter, targetCharacter }
                params.FilterType = Enum.RaycastFilterType.Exclude
                local result = workspace:Raycast(fromPos, (toPos - fromPos), params)
                if result then
                    if not result.Instance:IsDescendantOf(targetCharacter) then
                        return false
                    end
                end
                return true
            end
            autoshoot_thread = task.spawn(function()
                while getgenv().autoshoot_enabled do
                    local myChar = Player.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local myHum = myChar and myChar:FindFirstChild("Humanoid")
                    if getgenv().match and myRoot and myHum and myHum.Health > 0 then
                        local closestTarget = nil
                        local closestDistance = getgenv().max_distance or 1000
                        for _, enemy in ipairs(matchEnemies) do
                            local char = enemy.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChild("Humanoid")
                            if enemy ~= Player and hum and hum.Health > 0 and hrp then
                                local dist = (hrp.Position - myRoot.Position).Magnitude
                                if dist < closestDistance then
                                    local onDifferentTeam = (not enemy.Team or enemy.Team ~= Player.Team)
                                    local isVisibleInFov = (Camera.CFrame.LookVector:Dot((hrp.Position - Camera.CFrame.Position).Unit) >= 0.9)
                                    if onDifferentTeam and isVisibleInFov then
                                        closestDistance = dist
                                        closestTarget = enemy
                                    end
                                end
                            end
                        end
                        if closestTarget and canShoot then
                            local targetChar = closestTarget.Character
                            local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                            if targetHrp and has_clear_los(myRoot.Position, targetHrp.Position, myChar, targetChar) then
                                ShootGun(closestTarget)
                            end
                        end
                    end
                    task.wait(0.03)
                end
            end)
        end
    end
})
FeaturesSection:Slider({ -- Autoshoot Max Distance
    Title = "Max Distance",
    Step = 1,
    Value = {
        Min = 0,
        Max = 1000,
        Default = 300,
    },
    Callback = function(value)
        getgenv().max_distance = value
    end
})
FeaturesSection:Slider({ -- Cooldown
    Title = "Cooldown",
    Step = 0.5,
    Value = {
        Min = 0.5,
        Max = 10,
        Default = 2,
    },
    Callback = function(value)
        getgenv().autoshoot_cooldown = value
    end
})
FeaturesSection:Space()

getgenv().auto_throw_enabled = false
getgenv().max_distance = 300
getgenv().throw_cooldown = 2
local autoThrowThread = nil
local lastThrowTime = 0
local function throwKnife(targetChar)
    local tool = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool or not tool:FindFirstChild("RightHandle") then return end
    local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return end
    local origin = CharacterRayOrigin(game.Players.LocalPlayer.Character)
    local direction = (targetHrp.Position - origin).Unit
    ReplicatedStorage.Remotes.ThrowStart:FireServer(origin, direction)
    require(ReplicatedStorage.Modules.KnifeProjectileController)({
        Speed = tool:GetAttribute("ThrowSpeed"),
        KnifeProjectile = tool.RightHandle:Clone(),
        Direction = direction,
        Origin = origin
    }, function(raycastResult)
        ReplicatedStorage.Remotes.ThrowHit:FireServer(raycastResult and raycastResult.Instance,
            raycastResult and raycastResult.Position)
    end)
    lastThrowTime = tick()
end
local uteuirhguh = FeaturesSection:Toggle({ -- Enable auto throw knife
    Title = "Auto Throw Knife",
    Desc = "Auto throws your knife at enemies",
    Default = false,
    Callback = function(Value)
        getgenv().auto_throw_enabled = Value
        if autoThrowThread then
            task.cancel(autoThrowThread)
            autoThrowThread = nil
        end
        if Value then
            autoThrowThread = task.spawn(function()
                while getgenv().auto_throw_enabled do
                    if (tick() - lastThrowTime) >= getgenv().throw_cooldown then
                        local myChar = game.Players.LocalPlayer.Character
                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

                        if myRoot then
                            local closestTarget = nil
                            local shortestDist = getgenv().max_distance
                            for _, player in matchEnemies do
                                if player ~= game.Players.LocalPlayer and player.Character and player.Team ~= Player.Team then
                                    local enemyHrp = player.Character:FindFirstChild("HumanoidRootPart")
                                    local enemyHum = player.Character:FindFirstChild("Humanoid")

                                    if enemyHrp and enemyHum and enemyHum.Health > 0 then
                                        local dist = (enemyHrp.Position - myRoot.Position).Magnitude
                                        local params = RaycastParams.new()
                                        params.FilterDescendantsInstances = { myChar, player.Character }
                                        params.FilterType = Enum.RaycastFilterType.Exclude
                                        local result = workspace:Raycast(myRoot.Position,
                                            (enemyHrp.Position - myRoot.Position), params)

                                        if dist < shortestDist and not result then
                                            shortestDist = dist
                                            closestTarget = player.Character
                                        end
                                    end
                                end
                            end

                            if closestTarget then
                                throwKnife(closestTarget)
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})
FeaturesSection:Slider({ -- Max throw distance
    Title = "Maximum Distance",
    Value = { Min = 0, Max = 1000, Default = 300 },
    Callback = function(v) getgenv().max_distance = v end
})
FeaturesSection:Slider({ -- Throw cooldown
    Title = "Cooldown",
    Value = { Min = 0.5, Max = 10, Default = 2 },
    Callback = function(v) getgenv().throw_cooldown = v end
})
FeaturesSection:Space()

getgenv().triggerbot_enabled = false
getgenv().triggerbot_firing = false
getgenv().triggerbot_cooldown = 1
local function triggerbot_valid_enemy(enemy)
    if not enemy or enemy == Player then return false end
    local character = enemy.Character
    if not character or character.Parent ~= Workspace then return false end
    if enemy.Team and enemy.Team == Player.Team then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local my_hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not (humanoid and hrp and my_hrp) then return false end
    if humanoid.Health <= 0 then return false end
    if Collection:HasTag(character, "Invulnerable") or Collection:HasTag(character, "SpeedTrail") then return false end
    return true
end
local function triggerbot_shoot(target)
    local my_char = Player.Character
    local my_root = my_char and my_char:FindFirstChild("HumanoidRootPart")
    local target_hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not (my_root and target_hrp) then
        getgenv().triggerbot_firing = false
        return
    end
    local hit_part = target.Character:FindFirstChild("LowerTorso")
        or target.Character:FindFirstChild("UpperTorso")
        or target.Character:FindFirstChild("Head")
    if hit_part then
        ShootGun(target)
    else
        getgenv().triggerbot_firing = false
    end
end
RunService.Heartbeat:Connect(function()
    if not getgenv().triggerbot_enabled then return end
    if not getgenv().match then return end
    if getgenv().triggerbot_firing then return end -- if locked then exit
    local character = Player.Character
    if not character then return end
    if not getgenv().match then return end
    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { character }
    rayParams.IgnoreWater = true
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 2000, rayParams)
    if not result then return end
    local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
    if not hitCharacter then return end
    local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
    if not hitPlayer then return end
    if triggerbot_valid_enemy(hitPlayer) then
        getgenv().triggerbot_firing = true -- lock from shooting
        triggerbot_shoot(hitPlayer)
        -- wait cooldown then unlock
        task.delay(getgenv().triggerbot_cooldown, function()
            getgenv().triggerbot_firing = false
        end)
    end
end)
FeaturesSection:Toggle({ -- trigger bot toggle
    Title = "Triggerbot",
    Desc = "Kills player when your mouse is over them",
    Default = false,
    Callback = function(Value)
        getgenv().triggerbot_enabled = Value
        if getgenv().triggerbot_enabled then
            FeatureActivated(true)
        else
            FeatureActivated(false)
        end
    end
})
FeaturesSection:Slider({ -- triggerbot cooldown
    Title = "Cooldown",
    Step = 0.1,
    Flag = "TriggerBotCooldownSlider",
    Value = {
        Min = 0,
        Max = 3,
        Default = 1,
    },
    Callback = function(value)
        getgenv().triggerbot_cooldown = value
    end
})
FeaturesSection:Space()

getgenv().hitbox_expander = false
getgenv().hitbox_size = 13
getgenv().hitbox_color = Color3.fromRGB(255, 0, 0)
FeaturesSection:Toggle({ -- hitbox toggle
    Title = "Hitbox Expander",
    Desc = "Expands everyones hitbox",
    Default = false,
    Callback = function(Value)
        getgenv().hitbox_expander = Value
        if getgenv().hitbox_expander then
            FeatureActivated(true)
        else
            FeatureActivated(false)
        end
        if not getgenv().hitbox_expander then
            for _, player in matchEnemies do
                if player ~= Player then
                    local character = player.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.CanCollide = false
                        local hit_box = hrp:FindFirstChild("hit_box")
                        if hit_box then
                            hit_box:Destroy()
                        end
                    end
                end
            end
            return
        end
        task.spawn(function()
            while getgenv().hitbox_expander and task.wait(0.1) do
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= Player and player.Character then
                        local character = player.Character
                        local hrp = character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local enemy = player.Team ~= Player.Team
                            if enemy then
                                hrp.Size = Vector3.new(getgenv().hitbox_size, getgenv().hitbox_size,
                                    getgenv().hitbox_size)
                                hrp.CanCollide = true
                                local hit_box = hrp:FindFirstChild("hit_box")
                                if not hit_box then
                                    local box_handle = Instance.new("BoxHandleAdornment")
                                    box_handle.Name = "hit_box"
                                    box_handle.Adornee = hrp
                                    box_handle.AlwaysOnTop = true
                                    box_handle.ZIndex = 10
                                    box_handle.Size = hrp.Size
                                    box_handle.Color3 = getgenv().hitbox_color
                                    box_handle.Transparency = 0.8
                                    box_handle.Parent = hrp
                                else
                                    hit_box.Size = hrp.Size
                                end
                            else
                                hrp.Size = Vector3.new(2, 2, 1)
                                hrp.CanCollide = false
                                local hit_box = hrp:FindFirstChild("hit_box")
                                if hit_box then
                                    hit_box:Destroy()
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})
FeaturesSection:Slider({ -- hitbox size
    Title = "Size",
    Step = 1,
    Value = {
        Min = 5,
        Max = 100,
        Default = 13,
    },
    Callback = function(size)
        getgenv().hitbox_size = size
    end
})
FeaturesSection:Colorpicker({ -- hitbox color
    Title = "Color",
    Default = Color3.fromRGB(255, 0, 0),
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        getgenv().hitbox_color = color
    end
})

local Esp = Window:Tab({
    Title = "Esp",
    Icon = "eye",
    Locked = false,
})
getgenv().esp_team_color = Color3.fromRGB(0, 255, 0)
getgenv().esp_enemy_color = Color3.fromRGB(255, 0, 0)
getgenv().esp_charms_highlighter = false
local charms_esp = CoreGui:FindFirstChild("Highlights") or Instance.new("Folder")
charms_esp.Name = "CharmsESP"
charms_esp.Parent = CoreGui
Esp:Toggle({ -- Enable Charms Highlighte
    Title = "Esp Charms",
    Default = false,
    Callback = function(Value)
        getgenv().esp_charms_highlighter = Value
        -- remove all highlight on false
        if not getgenv().esp_charms_highlighter then
            FeatureActivated(false)
            for _, esp_players in ipairs(charms_esp:GetChildren()) do
                esp_players:Destroy()
            end
            return
        else
            FeatureActivated(true)
        end
        task.spawn(function()
            while getgenv().esp_charms_highlighter do
                task.wait(0.1)
                for _, v in matchEnemies do
                    if not getgenv().esp_charms_highlighter then break end
                    if v ~= Player then
                        local character = v.Character
                        if character then
                            local highlight = charms_esp:FindFirstChild(v.Name)
                            if not highlight then
                                highlight = Instance.new("Highlight")
                                highlight.Name = v.Name
                                highlight.FillTransparency = 0.6
                                highlight.OutlineTransparency = 0.4
                                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                highlight.Parent = charms_esp
                            end
                            local teamColor = (v.Team == Player.Team)
                                and getgenv().esp_team_color
                                or getgenv().esp_enemy_color
                            highlight.FillColor = teamColor
                            highlight.OutlineColor = teamColor
                            highlight.Adornee = character
                        end
                    end
                end
            end
        end)
    end
})
getgenv().esp_skeleton = false
local skeleton_folder = CoreGui:FindFirstChild("Skeletons") or Instance.new("Folder")
skeleton_folder.Name = "Skeletons"
skeleton_folder.Parent = CoreGui
Esp:Toggle({ -- Enable Skeletal Highlighter
    Title = "Esp Skeleton",
    Default = false,
    Callback = function(Value)
        getgenv().esp_skeleton = Value
        local function cleanup()
            for _, child in ipairs(skeleton_folder:GetChildren()) do
                child:Destroy()
            end
        end
        if not Value then
            cleanup()
            FeatureActivated(false)
            return
        else
            FeatureActivated(true)
        end
        task.spawn(function()
            local function createLine()
                local line = Instance.new("LineHandleAdornment")
                line.Thickness = 2
                line.ZIndex = 10
                line.AlwaysOnTop = true
                return line
            end
            local bones = {
                { "Head",       "UpperTorso" }, { "UpperTorso", "LowerTorso" },
                { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
                { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
                { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
                { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" }
            }
            while getgenv().esp_skeleton do
                task.wait(0.1)
                for _, v in matchEnemies do
                    local char = v.Character
                    local holder = skeleton_folder:FindFirstChild(v.Name)
                    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                        if not holder then
                            holder = Instance.new("Folder")
                            holder.Name = v.Name
                            holder.Parent = skeleton_folder
                        end
                        local color = (v.Team == Player.Team) and getgenv().esp_team_color or getgenv().esp_enemy_color
                        for i, bonePair in ipairs(bones) do
                            local p1, p2 = char:FindFirstChild(bonePair[1]), char:FindFirstChild(bonePair[2])
                            if p1 and p2 then
                                local line = holder:FindFirstChild(tostring(i)) or createLine()
                                line.Name = tostring(i)
                                line.Color3 = color
                                line.Adornee = p1
                                line.CFrame = CFrame.new(Vector3.zero, p1.CFrame:PointToObjectSpace(p2.Position))
                                line.Length = (p1.Position - p2.Position).Magnitude
                                line.Parent = holder
                            end
                        end
                    elseif holder then
                        holder:Destroy()
                    end
                end
                for _, child in ipairs(skeleton_folder:GetChildren()) do
                    if not Players:FindFirstChild(child.Name) then
                        child:Destroy()
                    end
                end
            end
            cleanup()
        end)
    end
})
getgenv().esp_tracers = false
local tracers_folder = CoreGui:FindFirstChild("Tracers") or Instance.new("Folder")
tracers_folder.Name = "Tracers"
tracers_folder.Parent = CoreGui
local RunService = game:GetService("RunService")
local tracerConnection = nil -- Variable to hold our RenderStepped loop
Esp:Toggle({ -- esp tracers
    Title = "Esp Tracers",
    Default = false,
    Callback = function(Value)
        getgenv().esp_tracers = Value

        local function cleanup()
            for _, child in ipairs(tracers_folder:GetChildren()) do
                child:Destroy()
            end
        end
        if tracerConnection then
            tracerConnection:Disconnect()
            tracerConnection = nil
        end
        if not Value then
            cleanup()
            if FeatureActivated then FeatureActivated(false) end
            return
        else
            if FeatureActivated then FeatureActivated(true) end
        end
        tracerConnection = RunService.RenderStepped:Connect(function()
            if not getgenv().esp_tracers then
                if tracerConnection then
                    tracerConnection:Disconnect()
                    tracerConnection = nil
                end
                cleanup()
                return
            end
            local myChar = Player.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot then
                for _, v in ipairs(matchEnemies) do
                    if v ~= Player and v.Parent then
                        local char = v.Character
                        local tracer = tracers_folder:FindFirstChild(v.Name)
                        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                            if not tracer then
                                tracer = Instance.new("LineHandleAdornment")
                                tracer.Name = v.Name
                                tracer.Thickness = 1.5
                                tracer.ZIndex = 10
                                tracer.AlwaysOnTop = true
                                tracer.Parent = tracers_folder
                            end

                            local targetRoot = char.HumanoidRootPart
                            local color = (v.Team == Player.Team) and getgenv().esp_team_color or
                            getgenv().esp_enemy_color
                            tracer.Color3 = color
                            tracer.Adornee = workspace.Terrain
                            tracer.CFrame = CFrame.lookAt(myRoot.Position, targetRoot.Position)
                            tracer.Length = (myRoot.Position - targetRoot.Position).Magnitude
                        elseif tracer then
                            tracer:Destroy()
                        end
                    end
                end
            else
                cleanup()
            end
            for _, child in ipairs(tracers_folder:GetChildren()) do
                if not Players:FindFirstChild(child.Name) then
                    child:Destroy()
                end
            end
        end)
    end
})
Esp:Colorpicker({ -- Team Color Highlight
    Title = "Team Color",
    Default = Color3.fromRGB(0, 255, 0),
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        getgenv().esp_team_color = color
    end
})
Esp:Colorpicker({ -- Enemy Color Highlight
    Title = "Enemy Color",
    Default = Color3.fromRGB(255, 0, 0),
    Transparency = 0,
    Locked = false,
    Callback = function(color)
        getgenv().esp_enemy_color = color
    end
})

local KillingTab = Window:Tab({
    Title = "Kill All",
    Icon = "skull",
    Locked = false,
})
local GunSection = KillingTab:Section({ 
    Title = "Gun",
    Opened = true
})
local KnifeSection = KillingTab:Section({ 
    Title = "Knife",
    Opened = true
})
getgenv().autoKillGun = false
GunSection:Button({ -- [GUN] Kill all players once
    Title = "Kill all players once",
    Locked = false,
    Callback = function()
        if getgenv().match then
            local players = game:GetService("Players")
            local player = players.LocalPlayer
            local myMatch = player:GetAttribute("Match")
            if myMatch then
                equipGun()
                WindUI:Notify({
                    Title = "Killing all players!",
                    Content =
                    "Enjoying Vexal Scripts? Join our discord server located in the Welcome tab for even better stuff!",
                    Duration = 3,
                    Icon = VexalLogo,
                })
                for _, plr in matchEnemies do
                    if plr.Team ~= player.Team and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local target = plr.Character.HumanoidRootPart
                        local origin = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if origin then
                            local ShootGun = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShootGun")
                            ShootGun:FireServer(origin.Position, target.Position, target, target.Position)
                        end
                    end
                    task.wait(0.1)
                end
            end
        end
    end
})
GunSection:Toggle({ -- [GUN] Auto kill all players
    Title = "Auto kill players",
    Value = false,
    Callback = function(state)
        getgenv().autoKillGun = state
        if state then
            FeatureActivated(true)
        else
            FeatureActivated(false)
        end
    end
})
task.spawn(function() -- [GUN] auto kill all loop
    local players = game:GetService("Players")
    local player = players.LocalPlayer
    while true do
        if getgenv().autoKillGun then
            local myMatch = player:GetAttribute("Match")
            if myMatch then
                equipGun()
                for _, plr in matchEnemies do
                    if plr.Team ~= player.Team and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local target = plr.Character.HumanoidRootPart
                        local origin = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if origin then
                            local ShootGun = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShootGun")
                            ShootGun:FireServer(origin.Position, target.Position, target, target.Position)
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)
getgenv().autoKillKnife = false
KnifeSection:Button({ -- [KNIFE] Kill all players once
    Title = "Kill all players once",
    Locked = false,
    Callback = function()
        if getgenv().match then
            local players = game:GetService("Players")
            local player = players.LocalPlayer
            local myMatch = player:GetAttribute("Match")
            if myMatch then
                equipKnife()
                WindUI:Notify({
                    Title = "Killing all players!",
                    Content =
                    "Enjoying Vexal Scripts? Join our discord server located in the Welcome tab for even better stuff!",
                    Duration = 3,
                    Icon = VexalLogo,
                })
                for _, target in ipairs(Players:GetPlayers()) do
                    if target ~= player and target.Character then
                        local humanoid = target.Character:FindFirstChild("Humanoid")
                        local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
                        if humanoid and humanoid.Health > 0 and rootPart then
                            local knifeRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ThrowHit")
                            knifeRemote:FireServer(rootPart, rootPart.Position)
                        end
                    end
                    task.wait(0.1)
                end
            end
        end
    end
})
KnifeSection:Toggle({ -- [KNIFE] Auto kill all players
    Title = "Auto kill players",
    Value = false,
    Callback = function(state)
        getgenv().autoKillKnife = state
        if state then
            FeatureActivated(true)
        else
            FeatureActivated(false)
        end
    end
})
task.spawn(function() -- [KNIFE] auto kill all loop
    local players = game:GetService("Players")
    local player = players.LocalPlayer
    while true do
        if getgenv().autoKillKnife then
            local myMatch = player:GetAttribute("Match")
            if myMatch then
                equipKnife()
                for _, target in matchEnemies do
                    if target ~= player and target.Character then
                        local humanoid = target.Character:FindFirstChild("Humanoid")
                        local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
                        if humanoid and humanoid.Health > 0 and rootPart then
                            local knifeRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ThrowHit")
                            knifeRemote:FireServer(rootPart, rootPart.Position)
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

local Ability = Window:Tab({
    Title = "Ability",
    Icon = "zap",
    Locked = false,
})
getgenv().autoShroud = false
getgenv().lowExecutorsShroud = false
getgenv().shroudRate = 1
local ConfigSuccess, Config = pcall(function()
    return require(game:GetService("ReplicatedStorage").Ability.AbilityConfig)
end)
local ActivateShroud = ReplicatedStorage.Ability:WaitForChild("ActivateShroud")
local isLocked = (not ConfigSuccess)
local originals = {
    SprintCooldown = not isLocked and Config.SprintCooldown or 15,
    DashCooldown = not isLocked and Config.DashCooldown or 6,
    ShroudCooldown = not isLocked and Config.ShroudCooldown or 7,
    SoulReapCombatDelay = not isLocked and Config.SoulReapCombatDelay or 0.35
}
if isLocked then
    uteuirhguh:Lock()
end
local function blind(targetPlayer)
    local character = Players.LocalPlayer.Character
    if targetPlayer and targetPlayer.Character and character then
        local targetPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local root = character:FindFirstChild("HumanoidRootPart")

        if targetPart and root then
            local origin
            local direction

            if getgenv().lowExecutorsShroud then
                origin = root.Position
                direction = (targetPart.Position - origin).Unit
                ActivateShroud:FireServer(origin, direction)
            else
                local s1, CharacterRayOrigin = pcall(function()
                    return require(ReplicatedStorage.Modules
                        .CharacterRayOrigin)
                end)
                local s2, ShroudProjectileController = pcall(function()
                    return require(ReplicatedStorage.Ability
                        .ShroudProjectileController)
                end)
                if s1 and s2 then
                    origin = CharacterRayOrigin(character)
                    direction = (targetPart.Position - origin).Unit
                    ActivateShroud:FireServer(origin, direction)
                    ShroudProjectileController(origin, direction)
                else
                    getgenv().lowExecutorsShroud = true
                    origin = root.Position
                    direction = (targetPart.Position - origin).Unit
                    ActivateShroud:FireServer(origin, direction)
                end
            end
        end
    end
end

Ability:Toggle({ -- Auto Shroud All
    Title = "Auto shroud players",
    Value = false,
    Callback = function(state)
        getgenv().autoShroud = state
    end
})
Ability:Toggle({ -- Low Executor Mode
    Title = "Low executor mode",
    Desc = "Supports Solara/Xeno, and this feature shrouds others except you",
    Value = false,
    Callback = function(state)
        getgenv().lowExecutorsShroud = state
    end
})
Ability:Slider({ -- Shrouds firing to enemies
    Title = "Amount of shrouds per Enemy",
    Step = 0.1,
    Value = {
        Min = 1,
        Max = 10000,
        Default = 1,
    },
    Callback = function(value)
        getgenv().shroudRate = value
    end
})
task.spawn(function() -- auto shoot shroud
    while true do
        if getgenv().autoShroud then
            local matchId = Players.LocalPlayer:GetAttribute("Match")
            for _, p in matchEnemies do
                blind(p)
            end
            task.wait(1 / getgenv().shroudRate)
        else
            task.wait(0.5)
        end
    end
end)

Ability:Toggle({ -- Remove Sprint Cooldown
    Title = "Remove sprint cooldown",
    Locked = isLocked,
    Value = false,
    Callback = function(state)
        if state then
            FeatureActivated(true)
        else
            FeatureActivated(false)
        end
        if not isLocked then
            Config.SprintCooldown = state and 0 or originals.SprintCooldown
        else
            NotSupportedFeature()
        end
    end
})
Ability:Toggle({ -- Remove Dash Cooldown
    Title = "Remove dash cooldown",
    Locked = isLocked,
    Value = false,
    Callback = function(state)
        if state then
            FeatureActivated(true)
        else
            FeatureActivated(false)
        end
        if not isLocked then
            Config.DashCooldown = state and 0 or originals.DashCooldown
        else
            NotSupportedFeature()
        end
    end
})
Ability:Toggle({ -- Remove Shroud Cooldown
    Title = "Remove shroud cooldown",
    Locked = isLocked,
    Value = false,
    Callback = function(state)
        if state then
            FeatureActivated(true)
        else
            FeatureActivated(false)
        end
        if not isLocked then
            Config.ShroudCooldown = state and 0 or originals.ShroudCooldown
        else
            NotSupportedFeature()
        end
    end
})
Ability:Toggle({ -- Remove Soul Reap Combat Delay
    Title = "Remove soul reap combat delay",
    Locked = isLocked,
    Value = false,
    Callback = function(state)
        if state then
            FeatureActivated(true)
        else
            FeatureActivated(false)
        end
        if not isLocked then
            Config.SoulReapCombatDelay = state and 0 or originals.SoulReapCombatDelay
        else
            NotSupportedFeature()
        end
    end
})

Ability:Space()
Ability:Slider({ -- Sprint Time
    Title = "Sprint time",
    Step = 0.5,
    Locked = isLocked,
    Value = {
        Min = 0.5,
        Max = 10,
        Default = not isLocked and Config.SprintTime or 0,
    },
    Callback = function(value)
        if not isLocked then
            Config.SprintTime = value
        else
            NotSupportedFeature()
        end
    end
})
Ability:Slider({ -- Sprint Boost
    Title = "Sprint boost",
    Step = 0.1,
    Locked = isLocked,
    Value = {
        Min = 0,
        Max = 5,
        Default = not isLocked and Config.SprintBoost or 0,
    },
    Callback = function(value)
        if not isLocked then
            Config.SprintBoost = value
        else
            NotSupportedFeature()
        end
    end
})
Ability:Slider({ -- Soul Reap Time
    Title = "Soul reap time",
    Step = 0.5,
    Locked = isLocked,
    Value = {
        Min = 0.5,
        Max = 10,
        Default = not isLocked and Config.SoulReapTime,
    },
    Callback = function(value)
        if not isLocked then
            Config.SoulReapTime = value
        else
            NotSupportedFeature()
        end
    end
})
Ability:Slider({ -- Soul Reap Speed Boost
    Title = "Soul reap speed boost",
    Step = 0.1,
    Locked = isLocked,
    Value = {
        Min = 0.1,
        Max = 10,
        Default = not isLocked and Config.SoulReapSpeedBoost or 0,
    },
    Callback = function(value)
        if not isLocked then
            Config.SoulReapSpeedBoost = value
        else
            NotSupportedFeature()
        end
    end
})
Ability:Slider({ -- Propeller Jump Boost
    Title = "Propeller jump boost",
    Step = 0.1,
    Locked = isLocked,
    Value = {
        Min = 0.1,
        Max = 5,
        Default = not isLocked and Config.PropellerJumpBoost or 0,
    },
    Callback = function(value)
        if not isLocked then
            Config.PropellerJumpBoost = value
        else
            NotSupportedFeature()
        end
    end
})
Ability:Slider({ -- Shroud Time
    Title = "Shroud time",
    Step = 0.5,
    Locked = isLocked,
    Value = {
        Min = 0.5,
        Max = 10,
        Default = not isLocked and Config.ShroudTime or 0,
    },
    Callback = function(value)
        if not isLocked then
            Config.ShroudTime = value
        else
            NotSupportedFeature()
        end
    end
})
Ability:Slider({ -- Shroud Projectile Speed
    Title = "Shroud projectile speed",
    Step = 2.5,
    Locked = isLocked,
    Value = {
        Min = 2.5,
        Max = 100,
        Default = not isLocked and Config.ShroudProjectileSpeed or 0,
    },
    Callback = function(value)
        if not isLocked then
            Config.ShroudProjectileSpeed = value
        else
            NotSupportedFeature()
        end
    end
})
Ability:Slider({ -- Shroud Projectile Range
    Title = "Shroud projectile range",
    Step = 5,
    Locked = isLocked,
    Value = {
        Min = 5,
        Max = 1000,
        Default = not isLocked and Config.ShroudProjectileRange or 0,
    },
    Callback = function(value)
        if not isLocked then
            Config.ShroudProjectileRange = value
        else
            NotSupportedFeature()
        end
    end
})

local Teleport = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin",
    Locked = false,
})

local lobby = workspace:WaitForChild("Lobby")
local groups = { DuelRing_1v1 = 1, DuelRing_2v2 = 2, DuelRing_3v3 = 3, DuelRing_4v4 = 4 }
local autoWalkToDuelPad = false
local currentPadModel = nil
local lastJumpTime = 0
local function walkTo(model)
    local character = Player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoid and rootPart and model and model.PrimaryPart then
        local targetPosition = model.PrimaryPart.Position
        local distance = (rootPart.Position - targetPosition).Magnitude
        if distance <= 6 then
            getgenv().noclip = false
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
            return
        end
        humanoid.WalkSpeed = 35
        humanoid:MoveTo(targetPosition)
        if os.clock() - lastJumpTime >= 2 then
            humanoid.Jump = true
            lastJumpTime = os.clock()
        end
        getgenv().noclip = true
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end
Teleport:Toggle({
    Title = "Enable auto walk to duel pads",
    Desc = "Automatically walks to an available duel pad accurately",
    Default = false,
    Flag = "AutoWalkDuelPadToggle",
    Callback = function(value)
        autoWalkToDuelPad = value
    end
})
Teleport:Space()
task.spawn(function()
    while true do
        if executionID ~= _G.executionID then break end
        if not Player:GetAttribute("Match") then
            if autoWalkToDuelPad then
                local character = Player.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if currentPadModel and rootPart then
                    local currentMaxCount = 1
                    for groupName, maxCount in pairs(groups) do
                        if lobby:FindFirstChild("DuelRingsGroup") and lobby.DuelRingsGroup:FindFirstChild(groupName) then
                            if lobby.DuelRingsGroup[groupName]:FindFirstChild(currentPadModel.Name) then
                                currentMaxCount = maxCount
                                break
                            end
                        end
                    end
                    if currentMaxCount == 1 then
                        local opponentFound = false
                        for _, otherPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
                            if otherPlayer ~= Player and otherPlayer.Character then
                                local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if otherRoot then
                                    local dist = (rootPart.Position - otherRoot.Position).Magnitude
                                    if dist <= 8 then
                                        opponentFound = true
                                        break
                                    end
                                end
                            end
                        end
                        if not opponentFound then
                            currentPadModel = nil
                        end
                    end
                end
                if currentPadModel and rootPart then
                    local stillValid = false
                    for _, groupFolder in ipairs(lobby:GetChildren()) do
                        if groupFolder.Name == "DuelRingsGroup" then
                            for groupName, maxCount in pairs(groups) do
                                local ringFolder = groupFolder:FindFirstChild(groupName)
                                if ringFolder and ringFolder:FindFirstChild(currentPadModel.Name) then
                                    local totalPlayersInGroup = 0
                                    local maxPlayersForGroup = maxCount * 2
                                    local targetedPadStillNeedsPlayer = false
                                    for _, model in ipairs(ringFolder:GetChildren()) do
                                        if model:IsA("Model") and model.Name == "DuelPad" then
                                            local count = model:GetAttribute("CharacterCount") or 0
                                            totalPlayersInGroup = totalPlayersInGroup + count
                                            if model == currentPadModel and count < maxCount then
                                                targetedPadStillNeedsPlayer = true
                                            end
                                        end
                                    end
                                    if (totalPlayersInGroup == maxPlayersForGroup - 1 and targetedPadStillNeedsPlayer) or (totalPlayersInGroup == maxPlayersForGroup) then
                                        stillValid = true
                                    end
                                    break
                                end
                            end
                        end
                        if stillValid then break end
                    end
                    if not stillValid then currentPadModel = nil end
                end
                if not currentPadModel then
                    local foundNewPad = false
                    for _, groupFolder in ipairs(lobby:GetChildren()) do
                        if groupFolder.Name == "DuelRingsGroup" then
                            for groupName, maxCount in pairs(groups) do
                                local ringFolder = groupFolder:FindFirstChild(groupName)
                                if ringFolder then
                                    local pads = {}
                                    local totalPlayersInGroup = 0
                                    local maxPlayersForGroup = maxCount * 2
                                    for _, model in ipairs(ringFolder:GetChildren()) do
                                        if model:IsA("Model") and model.Name == "DuelPad" then
                                            local count = model:GetAttribute("CharacterCount") or 0
                                            totalPlayersInGroup = totalPlayersInGroup + count
                                            table.insert(pads, { model = model, count = count })
                                        end
                                    end
                                    if totalPlayersInGroup == maxPlayersForGroup - 1 then
                                        for _, pad in ipairs(pads) do
                                            if pad.count < maxCount then
                                                local opponentReady = true
                                                if maxCount == 1 then
                                                    opponentReady = false
                                                    for _, otherPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
                                                        if otherPlayer ~= Player and otherPlayer.Character then
                                                            local otherRoot = otherPlayer.Character:FindFirstChild(
                                                                "HumanoidRootPart")
                                                            if otherRoot and pad.model.PrimaryPart then
                                                                local dist = (otherRoot.Position - pad.model.PrimaryPart.Position)
                                                                    .Magnitude
                                                                if dist <= 8 then -- Opponent is waiting at the pad
                                                                    opponentReady = true
                                                                    break
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                                if opponentReady then
                                                    walkTo(pad.model)
                                                    if rootPart and pad.model.PrimaryPart then
                                                        local distance = (rootPart.Position - pad.model.PrimaryPart.Position)
                                                            .Magnitude
                                                        if distance <= 6 then currentPadModel = pad.model end
                                                    end
                                                    foundNewPad = true
                                                    task.wait(0.5)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                if foundNewPad then break end
                            end
                        end
                        if foundNewPad then break end
                    end
                end
            else
                currentPadModel = nil
            end
        else
            currentPadModel = nil
        end
        task.wait(0.2)
    end
end)
if lobby and lobby:FindFirstChild("DuelRingsGroup") then
    for groupName, _ in pairs(groups) do
        local ringFolder = lobby.DuelRingsGroup:FindFirstChild(groupName)
        if ringFolder then
            local padIndex = 1
            for _, model in ipairs(ringFolder:GetChildren()) do
                if model:IsA("Model") and model.Name == "DuelPad" then
                    local sideName = (padIndex % 2 == 1) and "Right" or "Left"
                    local cleanTitle = "Walk to " .. groupName .. " " .. sideName

                    Teleport:Button({
                        Title = cleanTitle,
                        Locked = false,
                        Callback = function()
                            WindUI:Notify({
                                Title = "Walking to position!",
                                Content =
                                "Enjoying Vexal Scripts? Join our discord server located in the Welcome tab for even better stuff!",
                                Duration = 3,
                                Icon = VexalLogo,
                            })

                            walkTo(model)
                        end
                    })
                    padIndex = padIndex + 1
                end
            end
        end
    end
end
local fov = Window:Tab({
    Title = "FOV Shooting",
    Icon = "crosshair",
    Locked = false,
})
local fov_autoshoot_enabled = false
local fov_manualShoot_enabled = false
local fov_circle_enabled = false
local fov_radius = 100
local fov_shoot_cooldown = 1
local fov_last_shot = 0
local fov_circle = nil
local fov_gunController = nil
local fov_autoshoot_toggle = nil
local fov_manual_toggle = nil
local function createFovCircle()
    if fov_circle then
        fov_circle:Remove()
    end
    fov_circle = Drawing.new("Circle")
    fov_circle.Thickness = 2
    fov_circle.NumSides = 64
    fov_circle.Radius = fov_radius
    fov_circle.Color = Color3.fromRGB(255, 255, 255)
    fov_circle.Transparency = 1
    fov_circle.Visible = false
    fov_circle.Filled = false
end
createFovCircle()
local function update_fov_circle()
    if fov_circle and (fov_circle_enabled or fov_autoshoot_enabled or fov_manualShoot_enabled) then
        local mouse_pos = UserInputService:GetMouseLocation()
        fov_circle.Position = Vector2.new(mouse_pos.X, mouse_pos.Y)
        fov_circle.Radius = fov_radius
        fov_circle.Visible = true
    elseif fov_circle then
        fov_circle.Visible = false
    end
end
local function is_in_fov(target_position)
    local screen_pos, on_screen = Camera:WorldToViewportPoint(target_position)
    if not on_screen then
        return false
    end
    local mouse_pos = UserInputService:GetMouseLocation()
    local distance = math.sqrt((screen_pos.X - mouse_pos.X) ^ 2 + (screen_pos.Y - mouse_pos.Y) ^ 2)
    return distance <= fov_radius
end
local function has_clear_los(from_pos, to_pos, target_character)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { Player.Character, target_character }
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(from_pos, (to_pos - from_pos), params)
    if result then
        if not result.Instance:IsDescendantOf(target_character) then
            return false
        end
    end
    return true
end
local function valid_enemy(enemy)
    if not enemy or enemy == Player then
        return false
    end
    local character = enemy.Character
    if not character or character.Parent ~= Workspace then
        return false
    end
    if enemy.Team and enemy.Team == Player.Team then
        return false
    end
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local my_hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not (humanoid and hrp and my_hrp) then
        return false
    end
    if humanoid.Health <= 0 then
        return false
    end
    if Collection:HasTag(character, "Invulnerable") or Collection:HasTag(character, "SpeedTrail") then
        return false
    end
    return true
end
local function shoot_enemy(target)
    local my_char = Player.Character
    local my_root = my_char and my_char:FindFirstChild("HumanoidRootPart")
    local target_hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not (my_root and target_hrp) then
        return false
    end
    if not has_clear_los(my_root.Position, target_hrp.Position, target.Character) then
        return false
    end
    if not is_in_fov(target_hrp.Position) then
        return false
    end
    local current_time = tick()
    if current_time - fov_last_shot < fov_shoot_cooldown then
        return false
    end

    local hit_part = target.Character:FindFirstChild("LowerTorso") or
        target.Character:FindFirstChild("UpperTorso") or
        target.Character:FindFirstChild("Head")

    if hit_part then
        ShootGun(target)
        fov_last_shot = current_time
        return true
    end
    return false
end
RunService.Heartbeat:Connect(function()
    update_fov_circle()
    if not fov_autoshoot_enabled then
        return
    end
    local my_char = Player.Character
    if not my_char then
        return
    end
    for _, enemy in pairs(Players:GetPlayers()) do
        if valid_enemy(enemy) then
            if shoot_enemy(enemy) then
                break
            end
        end
    end
end)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if fov_manualShoot_enabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local current_time = tick()
        if current_time - fov_last_shot < fov_shoot_cooldown then
            return
        end
        local my_char = Player.Character
        if not my_char then
            return
        end
        for _, enemy in pairs(Players:GetPlayers()) do
            if valid_enemy(enemy) then
                if shoot_enemy(enemy) then
                    break
                end
            end
        end
    end
end)
local function start_gun_controller_loop()
    if fov_gunController then
        task.cancel(fov_gunController)
    end
    fov_gunController = task.spawn(function()
        while fov_manualShoot_enabled do
            task.wait()
            local gun_controller = Workspace:FindFirstChild(Player.Name)
            if gun_controller then
                local controller = gun_controller:FindFirstChild("GunController")
                if controller then
                    controller.Parent = nil
                end
            end
        end
    end)
end
local function stop_gun_controller_loop()
    if fov_gunController then
        task.cancel(fov_gunController)
        fov_gunController = nil
    end
end
fov:Toggle({ -- enable fov circle
    Title = "Enable FOV Circle",
    Desc = "Show FOV circle around your mouse",
    Default = false,
    Flag = "EnableFovCircle",
    Callback = function(value)
        fov_circle_enabled = value
    end
})
fov_autoshoot_toggle = fov:Toggle({ -- autoshoot fov
    Title = "Autoshoot FOV",
    Desc = "Automatically shoots enemies in your FOV circle",
    Default = false,
    Flag = "EnableAutoshootFov",
    Callback = function(value)
        fov_autoshoot_enabled = value
        if value then
            if fov_manual_toggle then
                fov_manual_toggle:Lock()
            end
        else
            if fov_manual_toggle then
                fov_manual_toggle:Unlock()
            end
        end
    end
})
fov_manual_toggle = fov:Toggle({ -- fov manual shoot
    Title = "FOV Manual Shoot",
    Desc = "Click to shoot enemies in FOV circle",
    Default = false,
    Flag = "EnableManualShootToggle",
    Callback = function(value)
        fov_manualShoot_enabled = value

        if value then
            if fov_autoshoot_toggle then
                fov_autoshoot_toggle:Lock()
            end
            start_gun_controller_loop()
        else
            if fov_autoshoot_toggle then
                fov_autoshoot_toggle:Unlock()
            end
            stop_gun_controller_loop()
        end
    end
})
fov:Slider({ -- fov circle size
    Title = "FOV Circle Size",
    Step = 5,
    Flag = "FovCircleSizeSlider",
    Value = {
        Min = 35,
        Max = 300,
        Default = 100,
    },
    Callback = function(value)
        fov_radius = value
    end
})
fov:Slider({ -- fov shoot cooldown
    Title = "FOV Autoshoot Cooldown",
    Step = 0.1,
    Flag = "FovAutoshootCooldownSlider",
    Value = {
        Min = 0,
        Max = 5,
        Default = 2,
    },
    Callback = function(value)
        fov_shoot_cooldown = value
    end
})

local Misc = Window:Tab({
    Title = "Misc",
    Icon = "folder",
    Locked = false,
})
getgenv().original_speed = 16
getgenv().speed_enabled = false
getgenv().current_speed = 16
getgenv().remove_gun_cooldown = false
Misc:Toggle({ -- auto spin
    Title = "Auto Spin",
    Desc = "Auto spins for you when not in match",
    Default = false,
    Callback = function(state)
        getgenv().autoSpin = state
        task.spawn(function()
            while getgenv().autoSpin do
                if not Player:GetAttribute("Match") then
                    local SpinnerService = require(game:GetService("ReplicatedStorage").Dailies.SpinnerService)
                    SpinnerService.Spin()
                end
                task.wait(0.1)
            end
        end)
    end,
})
Misc:Toggle({ -- noclip
    Title = "Noclip",
    Desc = "Allows you to walk through walls",
    Default = false,
    Callback = function(state)
        getgenv().noclip = state
        if state then
            FeatureActivated(true)
            local noclipLoop
            noclipLoop = game:GetService("RunService").Stepped:Connect(function()
                if not getgenv().noclip then
                    noclipLoop:Disconnect()
                    return
                end
                local char = Player.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            FeatureActivated(false)
        end
    end,
})
Misc:Toggle({ -- speed toggle
    Title = "Enable Speed Changer",
    Desc = "Changes your walk speed",
    Icon = "check",
    Default = false,
    Flag = "SpeedChangerToggle",
    Callback = function(Value)
        getgenv().speed_enabled = Value
        if Value then
            task.spawn(function()
                while getgenv().speed_enabled do
                    local character = Player.Character
                    local humanoid = character and character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.WalkSpeed ~= getgenv().current_speed then
                        humanoid.WalkSpeed = getgenv().current_speed
                    end
                    task.wait(0.1)
                end
            end)
        else
            local character = Player.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = getgenv().original_speed
            end
        end
    end
})
Misc:Slider({ -- speed slider
    Title = "Walk Speed",
    Step = 1,
    Value = {
        Min = 16,
        Max = 200,
        Default = 16,
    },
    Flag = "SpeedChangerSlider",
    Callback = function(speed)
        getgenv().current_speed = speed
        if getgenv().speed_enabled then
            local character = Player.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = speed
            end
        end
    end
})
Player.CharacterAdded:Connect(function(character)
    task.wait(0.2)
    if getgenv().speed_enabled then
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.WalkSpeed = getgenv().current_speed
    end
end)

Window:OnClose(function()
    WindUI:Notify({
        Title = "Window Closed!",
        Content = "Notification Content example!",
        Duration = 2.5,
        Icon = VexalLogo,
    })
end)
Window:OnDestroy(function()
    _G.VexalScriptsExecuted = false
end)
WindUI:AddTheme({
    Name = "vexalTheme",
    Accent = Color3.fromHex("#7c5cff"),
    Background = Color3.fromHex("#0c0c0e"),
    BackgroundTransparency = 0,
    Outline = Color3.fromHex("#1b1b22"),
    Text = Color3.fromHex("#e2f0fd"),
    Placeholder = Color3.fromHex("#525975"),
    Button = Color3.fromHex("#161620"),
    Icon = Color3.fromHex("#9cb3e6"),
    Hover = Color3.fromHex("#7c5cff"),
    WindowBackground = Color3.fromHex("#0c0c0e"),
    WindowShadow = Color3.fromHex("#000000"),
    DialogBackground = Color3.fromHex("#0c0c0e"),
    DialogBackgroundTransparency = 0,
    DialogTitle = Color3.fromHex("#e2f0fd"),
    DialogContent = Color3.fromHex("#e2f0fd"),
    DialogIcon = Color3.fromHex("#9cb3e6"),
    WindowTopbarButtonIcon = Color3.fromHex("#9cb3e6"),
    WindowTopbarTitle = Color3.fromHex("#e2f0fd"),
    WindowTopbarAuthor = Color3.fromHex("#9cb3e6"),
    WindowTopbarIcon = Color3.fromHex("#e2f0fd"),
    TabBackground = Color3.fromHex("#111116"),
    TabTitle = Color3.fromHex("#e2f0fd"),
    TabIcon = Color3.fromHex("#9cb3e6"),
    ElementBackground = Color3.fromHex("#111116"),
    ElementTitle = Color3.fromHex("#e2f0fd"),
    ElementDesc = Color3.fromHex("#9cb3e6"),
    ElementIcon = Color3.fromHex("#9cb3e6"),
    PopupBackground = Color3.fromHex("#0c0c0e"),
    PopupBackgroundTransparency = 0,
    PopupTitle = Color3.fromHex("#e2f0fd"),
    PopupContent = Color3.fromHex("#e2f0fd"),
    PopupIcon = Color3.fromHex("#9cb3e6"),
    Toggle = Color3.fromHex("#161620"),
    ToggleBar = Color3.fromHex("#7c5cff"),
    Checkbox = Color3.fromHex("#161620"),
    CheckboxIcon = Color3.fromHex("#7c5cff"),
    Slider = Color3.fromHex("#161620"),
    SliderThumb = Color3.fromHex("#7c5cff"),
})
WindUI:SetTheme("vexalTheme")
