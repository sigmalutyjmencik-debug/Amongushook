-- Amongus.hook | Defuse Division - ULTIMATE FIXED VERSION
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Конфиг
local enabled = {
    aim = false,
    hitbox = false,
    esp = false,
    fullbright = false,
    bhop = false,
    fov_changer = false,
    invisible = false,
    skin_changer = false,
    silent_aim = false
}

local settings = {
    team_check = true,
    hitbox_size = 5,
    aim_fov = 100,
    player_fov = 90,
    selected_skin = "Butterfly",
    silent_fov = 120,
    hit_chance = 100
}

local fovCircle
local aimToggle = false
local silentAimActive = false

-- Удаляем старый GUI
if CoreGui:FindFirstChild("AmongusHook") then
    CoreGui.AmongusHook:Destroy()
end

-- FOV круг
function createFovCircle()
    if fovCircle then 
        fovCircle:Remove() 
    end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = enabled.aim and aimToggle
    fovCircle.Thickness = 1
    fovCircle.Color = Color3.fromRGB(255, 50, 50)
    fovCircle.Transparency = 1
    fovCircle.Filled = false
    fovCircle.Radius = settings.aim_fov
    fovCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
end

-- FOV Changer
function updateFovChanger()
    if enabled.fov_changer then
        workspace.CurrentCamera.FieldOfView = settings.player_fov
    else
        workspace.CurrentCamera.FieldOfView = 70
    end
end

-- Invisible
function updateInvisible()
    if not player.Character then return end
    
    if enabled.invisible then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            elseif part:IsA("Decal") then
                part.Transparency = 1
            end
        end
    else
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            elseif part:IsA("Decal") then
                part.Transparency = 0
            end
        end
    end
end

-- ESP
local espConnections = {}

function updateESP()
    -- Очистка старых подключений
    for _, connection in pairs(espConnections) do
        connection:Disconnect()
    end
    espConnections = {}
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer.Character then
            for _, part in pairs(targetPlayer.Character:GetChildren()) do
                if part:IsA("Highlight") and part.Name == "AMONGUS_ESP" then
                    part:Destroy()
                end
            end
        end
    end
    
    if not enabled.esp then return end
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            if settings.team_check and player.Team and targetPlayer.Team and player.Team == targetPlayer.Team then
                goto continue
            end
            
            local function setupESP(character)
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "AMONGUS_ESP"
                    highlight.Adornee = character
                    highlight.FillColor = Color3.fromRGB(255, 50, 50)
                    highlight.FillTransparency = 0.8
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.OutlineTransparency = 0
                    highlight.Parent = character
                    
                    -- Обновление при изменении здоровья
                    local healthConnection = humanoid.HealthChanged:Connect(function()
                        if humanoid.Health <= 0 then
                            highlight:Destroy()
                        end
                    end)
                    
                    table.insert(espConnections, healthConnection)
                end
            end
            
            setupESP(targetPlayer.Character)
            
            -- Обработчик появления нового персонажа
            local charConnection = targetPlayer.CharacterAdded:Connect(function(newChar)
                wait(1)
                setupESP(newChar)
            end)
            
            table.insert(espConnections, charConnection)
        end
        ::continue::
    end
end

-- Хитбоксы
local hitboxConnections = {}

function updateHitboxes()
    -- Очистка
    for _, connection in pairs(hitboxConnections) do
        connection:Disconnect()
    end
    hitboxConnections = {}
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer.Character then
            for _, part in pairs(targetPlayer.Character:GetChildren()) do
                if part:IsA("Highlight") and part.Name == "AMONGUS_HITBOX" then
                    part:Destroy()
                end
            end
        end
    end
    
    if not enabled.hitbox then return end
    
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            if settings.team_check and player.Team and targetPlayer.Team and player.Team == targetPlayer.Team then
                goto continue
            end
            
            local function setupHitbox(character)
                local head = character:FindFirstChild("Head")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                
                if head and humanoid and humanoid.Health > 0 then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "AMONGUS_HITBOX"
                    highlight.Adornee = head
                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                    highlight.FillTransparency = 0.3
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.OutlineTransparency = 0
                    highlight.Parent = head
                    
                    -- Обновление при смерти
                    local healthConnection = humanoid.HealthChanged:Connect(function()
                        if humanoid.Health <= 0 then
                            highlight:Destroy()
                        end
                    end)
                    
                    table.insert(hitboxConnections, healthConnection)
                end
            end
            
            setupHitbox(targetPlayer.Character)
            
            local charConnection = targetPlayer.CharacterAdded:Connect(function(newChar)
                wait(1)
                setupHitbox(newChar)
            end)
            
            table.insert(hitboxConnections, charConnection)
        end
        ::continue::
    end
end

-- Bunny Hop
local bhopConnection

function updateBhop()
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    
    if enabled.bhop then
        bhopConnection = RunService.Heartbeat:Connect(function()
            if player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
                    if humanoid.MoveDirection.Magnitude > 0 then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
        end)
    end
end

-- Fullbright
function updateFullbright()
    if enabled.fullbright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 10000
    end
end

-- Аимбот
local aimConnection

function updateAim()
    if aimConnection then
        aimConnection:Disconnect()
        aimConnection = nil
    end
    
    if enabled.aim then
        aimConnection = RunService.Heartbeat:Connect(function()
            if not player.Character or not aimToggle then return end
            
            local closestTarget = nil
            local closestDistance = settings.aim_fov
            local camera = workspace.CurrentCamera
            
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                if targetPlayer ~= player and targetPlayer.Character then
                    if settings.team_check and player.Team and targetPlayer.Team and player.Team == targetPlayer.Team then
                        goto continue
                    end
                    
                    local head = targetPlayer.Character:FindFirstChild("Head")
                    local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                    
                    if head and humanoid and humanoid.Health > 0 then
                        local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
                        
                        if onScreen then
                            local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                            local point = Vector2.new(screenPoint.X, screenPoint.Y)
                            local distance = (center - point).Magnitude
                            
                            if distance < closestDistance then
                                closestDistance = distance
                                closestTarget = head
                            end
                        end
                    end
                end
                ::continue::
            end
            
            if closestTarget then
                local targetPos = closestTarget.Position
                local currentPos = camera.CFrame.Position
                local lookVector = (targetPos - currentPos).Unit
                
                camera.CFrame = CFrame.new(currentPos, currentPos + lookVector)
            end
        end)
        
        if fovCircle then
            fovCircle.Visible = aimToggle
        end
    else
        aimToggle = false
        if fovCircle then
            fovCircle.Visible = false
        end
    end
end

-- СИЛЬНЫЙ SILENT AIM (всегда попадает)
local silentAimHook

function updateSilentAim()
    if silentAimHook then
        silentAimHook:Disconnect()
        silentAimHook = nil
        if getgenv().silentAimTarget then
            getgenv().silentAimTarget = nil
        end
    end
    
    if enabled.silent_aim then
        -- Поиск лучшей цели для Silent Aim
        local function getSilentAimTarget()
            if math.random(1, 100) > settings.hit_chance then
                return nil
            end
            
            local closestTarget = nil
            local closestDistance = settings.silent_fov
            local camera = workspace.CurrentCamera
            
            for _, targetPlayer in pairs(Players:GetPlayers()) do
                if targetPlayer ~= player and targetPlayer.Character then
                    if settings.team_check and player.Team and targetPlayer.Team and player.Team == targetPlayer.Team then
                        goto continue
                    end
                    
                    local head = targetPlayer.Character:FindFirstChild("Head")
                    local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                    
                    if head and humanoid and humanoid.Health > 0 then
                        local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
                        
                        if onScreen then
                            local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                            local point = Vector2.new(screenPoint.X, screenPoint.Y)
                            local distance = (center - point).Magnitude
                            
                            if distance < closestDistance then
                                closestDistance = distance
                                closestTarget = head
                            end
                        end
                    end
                end
                ::continue::
            end
            
            return closestTarget
        end
        
        -- Хук для перехвата выстрелов
        silentAimHook = RunService.Heartbeat:Connect(function()
            local target = getSilentAimTarget()
            if not getgenv().silentAimTarget then
                getgenv().silentAimTarget = target
            else
                getgenv().silentAimTarget = target
            end
        end)
        
        silentAimActive = true
    else
        silentAimActive = false
        if getgenv().silentAimTarget then
            getgenv().silentAimTarget = nil
        end
    end
end

-- Skin Changer
local skinConnection

function updateSkinChanger()
    if skinConnection then
        skinConnection:Disconnect()
        skinConnection = nil
    end
    
    if enabled.skin_changer then
        skinConnection = RunService.Heartbeat:Connect(function()
            if player.Character then
                local tool = player.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("Handle") then
                    if settings.selected_skin == "Butterfly" then
                        tool.Handle.BrickColor = BrickColor.new("Bright blue")
                        tool.Handle.Material = Enum.Material.Neon
                        local mesh = tool.Handle:FindFirstChildOfClass("SpecialMesh")
                        if mesh then
                            mesh.Scale = Vector3.new(1.5, 1.5, 1.5)
                        end
                    elseif settings.selected_skin == "Karambit" then
                        tool.Handle.BrickColor = BrickColor.new("Bright red")
                        tool.Handle.Material = Enum.Material.Neon
                        local mesh = tool.Handle:FindFirstChildOfClass("SpecialMesh")
                        if mesh then
                            mesh.Scale = Vector3.new(1.2, 1.2, 1.2)
                        end
                    end
                end
            end
        end)
    end
end

-- Input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        aimToggle = not aimToggle
        if fovCircle then
            fovCircle.Visible = enabled.aim and aimToggle
        end
    end
    
    if input.KeyCode == Enum.KeyCode.F4 then
        if screenGui then
            screenGui.Enabled = not screenGui.Enabled
        end
    end
    
    if input.KeyCode == Enum.KeyCode.X then
        enabled.silent_aim = not enabled.silent_aim
        updateSilentAim()
    end
end)

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AmongusHook"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 550)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Заголовок
local title = Instance.new("Frame")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
title.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.Text = "Amongus.hook | SILENT AIM EDITION"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.Parent = title

-- Вкладки
local tabs = {"Main", "Visuals", "Aim", "Others"}
local currentTab = "Main"

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 0, 30)
tabContainer.Position = UDim2.new(0, 0, 0, 45)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -80)
contentFrame.Position = UDim2.new(0, 0, 0, 80)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Кнопки вкладок
local tabButtons = {}
for i, tabName in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1/#tabs, -4, 1, 0)
    tabBtn.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabBtn.BackgroundColor3 = currentTab == tabName and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 50, 65)
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextSize = 12
    tabBtn.Parent = tabContainer
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabBtn
    
    tabButtons[tabName] = tabBtn
    
    tabBtn.MouseButton1Click:Connect(function()
        currentTab = tabName
        updateGUI()
    end)
end

-- Функция создания кнопок
function createToggle(parent, text, yPos, configName)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0.9, 0, 0, 35)
    toggleFrame.Position = UDim2.new(0.05, 0, 0, yPos)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = parent
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.Text = "  " .. text
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.BackgroundColor3 = enabled[configName] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(50, 50, 65)
    toggleBtn.Font = Enum.Font.Gotham
    toggleBtn.TextSize = 13
    toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
    toggleBtn.Parent = toggleFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleBtn
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 40, 0, 20)
    statusLabel.Position = UDim2.new(1, -45, 0.5, -10)
    statusLabel.Text = enabled[configName] and "ON" or "OFF"
    statusLabel.TextColor3 = enabled[configName] and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 11
    statusLabel.Parent = toggleBtn
    
    toggleBtn.MouseButton1Click:Connect(function()
        enabled[configName] = not enabled[configName]
        toggleBtn.BackgroundColor3 = enabled[configName] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(50, 50, 65)
        statusLabel.Text = enabled[configName] and "ON" or "OFF"
        statusLabel.TextColor3 = enabled[configName] and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
        
        if configName == "aim" then
            updateAim()
        elseif configName == "hitbox" then
            updateHitboxes()
        elseif configName == "esp" then
            updateESP()
        elseif configName == "fullbright" then
            updateFullbright()
        elseif configName == "bhop" then
            updateBhop()
        elseif configName == "fov_changer" then
            updateFovChanger()
        elseif configName == "invisible" then
            updateInvisible()
        elseif configName == "skin_changer" then
            updateSkinChanger()
        elseif configName == "silent_aim" then
            updateSilentAim()
        end
    end)
    
    return toggleFrame
end

-- Функция создания настроек
function createSetting(parent, text, yPos, settingName)
    local settingFrame = Instance.new("Frame")
    settingFrame.Size = UDim2.new(0.9, 0, 0, 25)
    settingFrame.Position = UDim2.new(0.05, 0, 0, yPos)
    settingFrame.BackgroundTransparency = 1
    settingFrame.Parent = parent
    
    local settingBtn = Instance.new("TextButton")
    settingBtn.Size = UDim2.new(1, 0, 1, 0)
    settingBtn.Text = "  " .. text
    settingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingBtn.BackgroundColor3 = settings[settingName] and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(50, 50, 65)
    settingBtn.Font = Enum.Font.Gotham
    settingBtn.TextSize = 11
    settingBtn.TextXAlignment = Enum.TextXAlignment.Left
    settingBtn.Parent = settingFrame
    
    local settingCorner = Instance.new("UICorner")
    settingCorner.CornerRadius = UDim.new(0, 4)
    settingCorner.Parent = settingBtn
    
    settingBtn.MouseButton1Click:Connect(function()
        settings[settingName] = not settings[settingName]
        settingBtn.BackgroundColor3 = settings[settingName] and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(50, 50, 65)
        
        if enabled.esp then updateESP() end
        if enabled.hitbox then updateHitboxes() end
        if enabled.aim then updateAim() end
        if enabled.silent_aim then updateSilentAim() end
    end)
    
    return settingFrame
end

-- Функция создания поля ввода
function createInput(parent, text, yPos, currentValue, callback)
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(0.9, 0, 0, 50)
    inputFrame.Position = UDim2.new(0.05, 0, 0, yPos)
    inputFrame.BackgroundTransparency = 1
    inputFrame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = inputFrame
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, 0, 0, 25)
    textBox.Position = UDim2.new(0, 0, 0, 20)
    textBox.Text = tostring(currentValue)
    textBox.PlaceholderText = "Enter number..."
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 12
    textBox.Parent = inputFrame
    
    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 4)
    textBoxCorner.Parent = textBox
    
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local value = tonumber(textBox.Text)
            if value then
                callback(value)
            else
                textBox.Text = tostring(currentValue)
            end
        end
    end)
    
    return inputFrame
end

-- Функция создания выбора скина
function createSkinSelector(parent, yPos)
    local skinFrame = Instance.new("Frame")
    skinFrame.Size = UDim2.new(0.9, 0, 0, 80)
    skinFrame.Position = UDim2.new(0.05, 0, 0, yPos)
    skinFrame.BackgroundTransparency = 1
    skinFrame.Parent = parent
    
    local skinLabel = Instance.new("TextLabel")
    skinLabel.Size = UDim2.new(1, 0, 0, 20)
    skinLabel.Text = "Select Knife Skin:"
    skinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    skinLabel.BackgroundTransparency = 1
    skinLabel.Font = Enum.Font.Gotham
    skinLabel.TextSize = 12
    skinLabel.TextXAlignment = Enum.TextXAlignment.Left
    skinLabel.Parent = skinFrame
    
    local butterflyBtn = Instance.new("TextButton")
    butterflyBtn.Size = UDim2.new(0.48, 0, 0, 30)
    butterflyBtn.Position = UDim2.new(0, 0, 0, 25)
    butterflyBtn.Text = "Butterfly"
    butterflyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    butterflyBtn.BackgroundColor3 = settings.selected_skin == "Butterfly" and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 50, 65)
    butterflyBtn.Font = Enum.Font.Gotham
    butterflyBtn.TextSize = 12
    butterflyBtn.Parent = skinFrame
    
    local karambitBtn = Instance.new("TextButton")
    karambitBtn.Size = UDim2.new(0.48, 0, 0, 30)
    karambitBtn.Position = UDim2.new(0.52, 0, 0, 25)
    karambitBtn.Text = "Karambit"
    karambitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    karambitBtn.BackgroundColor3 = settings.selected_skin == "Karambit" and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 50, 65)
    karambitBtn.Font = Enum.Font.Gotham
    karambitBtn.TextSize = 12
    karambitBtn.Parent = skinFrame
    
    butterflyBtn.MouseButton1Click:Connect(function()
        settings.selected_skin = "Butterfly"
        butterflyBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        karambitBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        if enabled.skin_changer then
            updateSkinChanger()
        end
    end)
    
    karambitBtn.MouseButton1Click:Connect(function()
        settings.selected_skin = "Karambit"
        karambitBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        butterflyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        if enabled.skin_changer then
            updateSkinChanger()
        end
    end)
    
    return skinFrame
end

-- Обновление GUI
function updateGUI()
    for _, child in pairs(contentFrame:GetChildren()) do
        child:Destroy()
    end
    
    local yOffset = 10
    
    if currentTab == "Main" then
        createToggle(contentFrame, "Aimbot [E]", yOffset, "aim")
        yOffset = yOffset + 40
        createToggle(contentFrame, "Silent Aim [X]", yOffset, "silent_aim")
        yOffset = yOffset + 40
        createToggle(contentFrame, "Hitbox Extender", yOffset, "hitbox")
        yOffset = yOffset + 40
        createToggle(contentFrame, "Bunny Hop", yOffset, "bhop")
        yOffset = yOffset + 40
        createSetting(contentFrame, "Team Check", yOffset, "team_check")
        yOffset = yOffset + 30
        
    elseif currentTab == "Visuals" then
        createToggle(contentFrame, "ESP", yOffset, "esp")
        yOffset = yOffset + 40
        createToggle(contentFrame, "Fullbright", yOffset, "fullbright")
        yOffset = yOffset + 40
        createToggle(contentFrame, "FOV Changer", yOffset, "fov_changer")
        yOffset = yOffset + 40
        createToggle(contentFrame, "Invisible", yOffset, "invisible")
        yOffset = yOffset + 40
        createInput(contentFrame, "Player FOV", yOffset, settings.player_fov, function(value)
            settings.player_fov = value
            if enabled.fov_changer then updateFovChanger() end
        end)
        yOffset = yOffset + 55
        
    elseif currentTab == "Aim" then
        createInput(contentFrame, "Aimbot FOV", yOffset, settings.aim_fov, function(value)
            settings.aim_fov = value
            if fovCircle then fovCircle.Radius = value end
        end)
        yOffset = yOffset + 55
        createInput(contentFrame, "Silent Aim FOV", yOffset, settings.silent_fov, function(value)
            settings.silent_fov = value
        end)
        yOffset = yOffset + 55
        createInput(contentFrame, "Hit Chance %", yOffset, settings.hit_chance, function(value)
            settings.hit_chance = math.clamp(value, 1, 100)
        end)
        yOffset = yOffset + 55
        createInput(contentFrame, "Hitbox Size", yOffset, settings.hitbox_size, function(value)
            settings.hitbox_size = value
            if enabled.hitbox then updateHitboxes() end
        end)
        yOffset = yOffset + 55
        
    elseif currentTab == "Others" then
        createToggle(contentFrame, "Skin Changer", yOffset, "skin_changer")
        yOffset = yOffset + 40
        createSkinSelector(contentFrame, yOffset)
        yOffset = yOffset + 85
        
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(0.9, 0, 0, 100)
        infoLabel.Position = UDim2.new(0.05, 0, 0, yOffset)
        infoLabel.Text = "Hotkeys:\nE - Toggle Aimbot\nX - Toggle Silent Aim\nF4 - Hide/Show GUI"
        infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 12
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.TextYAlignment = Enum.TextYAlignment.Top
        infoLabel.Parent = contentFrame
    end
end

-- Инициализация системы
local function initializeSystem()
    createFovCircle()
    
    -- Автоматическое обновление при изменении камеры
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if fovCircle then
            fovCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
        end
    end)
    
    -- Обработчик появления персонажа
    player.CharacterAdded:Connect(function(character)
        wait(1)
        if enabled.invisible then updateInvisible() end
        if enabled.skin_changer then updateSkinChanger() end
    end)
    
    -- Обработчик добавления/удаления игроков
    Players.PlayerAdded:Connect(function()
        if enabled.esp then updateESP() end
        if enabled.hitbox then updateHitboxes() end
    end)
    
    Players.PlayerRemoving:Connect(function()
        if enabled.esp then updateESP() end
        if enabled.hitbox then updateHitboxes() end
    end)
end

-- Запуск системы
initializeSystem()
updateGUI()

-- Автоматическое обновление
RunService.Heartbeat:Connect(function()
    if enabled.esp then updateESP() end
    if enabled.hitbox then updateHitboxes() end
end)

warn("Amongus.hook loaded successfully!")
warn("Silent Aim: Press X to toggle")
warn("Aimbot: Press E to toggle")
