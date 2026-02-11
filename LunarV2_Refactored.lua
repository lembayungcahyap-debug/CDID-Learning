--[[
    LunarV2 - Car Driving Indonesia Script
    Version: 1.0.0
    Refactored for better maintainability and performance
]]

-- ============================================================================
-- MODULE: Core Configuration
-- ============================================================================
local Config = {
    Version = "1.0.0",
    BaseFolder = "LunarV2",
    SubFolder = "settings",
    FileName = "LunarConfig",
    SaveCooldown = 1,
    MaxRetries = 3,
    
    GameNames = {
        MainGame = "(UPDATE) Car Driving Indonesia",
        EventGame = "Jawa Barat",
        CentralJava = "Jawa Tengah",
        EventCNY = "An Adventure in the Hidden Temple Event (CNY 2025)"
    },
    
    DefaultSettings = {
        OnFarming = false,
        OnFirstTime = true,
        PrivateCode = nil,
        PrivateServer = nil,
        MaclibVisibility = false,
        WaveText = false,
        BlipText = false,
        SpoofedName = nil,
        SubtitleName = nil,
        InfiniteJump = false,
        SelectedJob = nil,
        StopFarm = false,
        TruckMethod = nil,
        UIVisibility = false,
        CountdownNotif = false,
        DelayBeforeRejoin = 0.5,
        SpoofToggle = false
    }
}

-- ============================================================================
-- MODULE: Services Cache
-- ============================================================================
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    HttpService = game:GetService("HttpService"),
    MarketplaceService = game:GetService("MarketplaceService"),
    TeleportService = game:GetService("TeleportService"),
    VirtualInputManager = game:GetService("VirtualInputManager")
}

local LocalPlayer = Services.Players.LocalPlayer

-- ============================================================================
-- MODULE: Settings Manager
-- ============================================================================
local SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager.new()
    local self = setmetatable({}, SettingsManager)
    self.LastSave = 0
    self.IsSaving = false
    self.SaveQueue = {}
    self.FilePath = table.concat({Config.BaseFolder, Config.SubFolder, Config.FileName}, "\\")
    
    self:Initialize()
    return self
end

function SettingsManager:Initialize()
    -- Create folders
    if not isfolder(Config.BaseFolder) then
        makefolder(Config.BaseFolder)
    end
    
    local subPath = Config.BaseFolder .. "\\" .. Config.SubFolder
    if not isfolder(subPath) then
        makefolder(subPath)
    end
    
    -- Initialize settings
    getgenv().Settings = Config.DefaultSettings
    getgenv().Temporary = {
        onFindingSnake = false,
        onFindingAngpao = false,
        onStory = false
    }
    
    -- Load existing settings
    if not self:Load() then
        self:Save(true)
    end
end

function SettingsManager:Save(force)
    if not writefile then return false end
    
    if self.IsSaving and not force then
        table.insert(self.SaveQueue, true)
        return false
    end
    
    local currentTime = os.time()
    if not force and currentTime - self.LastSave < Config.SaveCooldown then
        table.insert(self.SaveQueue, true)
        return false
    end
    
    self.IsSaving = true
    
    local success = pcall(function()
        local data = {
            version = Config.Version,
            settings = getgenv().Settings,
            timestamp = currentTime
        }
        writefile(self.FilePath, Services.HttpService:JSONEncode(data))
        self.LastSave = currentTime
    end)
    
    self.IsSaving = false
    
    -- Process queue
    if #self.SaveQueue > 0 then
        table.remove(self.SaveQueue, 1)
        task.spawn(function()
            task.wait(Config.SaveCooldown)
            self:Save()
        end)
    end
    
    return success
end

function SettingsManager:Load()
    if not (readfile and isfile) then return false end
    
    local retries = 0
    local success, result
    
    repeat
        success, result = pcall(function()
            if isfile(self.FilePath) then
                local data = readfile(self.FilePath)
                local decoded = Services.HttpService:JSONDecode(data)
                
                if type(decoded) == "table" and decoded.settings then
                    if decoded.version ~= Config.Version then
                        self:MigrateSettings(decoded.settings)
                    else
                        getgenv().Settings = decoded.settings
                    end
                    return true
                end
            end
            return false
        end)
        
        retries = retries + 1
        if not success and retries < Config.MaxRetries then
            task.wait(1)
        end
    until success or retries >= Config.MaxRetries
    
    return success and result
end

function SettingsManager:MigrateSettings(oldSettings)
    for key, value in pairs(oldSettings) do
        if getgenv().Settings[key] ~= nil then
            getgenv().Settings[key] = value
        end
    end
    getgenv().Settings.Version = Config.Version
end

-- ============================================================================
-- MODULE: Game Utilities
-- ============================================================================
local GameUtils = {}

function GameUtils.GetCurrentGameName()
    local success, gameInfo = pcall(function()
        return Services.MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    return success and gameInfo.Name or nil
end

function GameUtils.WaitForChild(parent, childName, timeout)
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    local elapsed = 0
    timeout = timeout or 10
    
    repeat
        child = parent:FindFirstChild(childName)
        task.wait(0.1)
        elapsed = elapsed + 0.1
    until child or elapsed >= timeout
    
    return child
end

function GameUtils.SafeTeleport(vehicle, targetCFrame)
    local align = Instance.new("AlignPosition")
    local att0 = Instance.new("Attachment")
    local att1 = Instance.new("Attachment")
    
    align.Mode = Enum.PositionAlignmentMode.OneAttachment
    align.Responsiveness = 200
    align.MaxForce = 1000000
    align.Parent = game:GetService("Terrain")
    
    pcall(function()
        att0.Parent = vehicle.PrimaryPart
        att1.Parent = game:GetService("Terrain")
        att1.WorldCFrame = targetCFrame
        
        align.Attachment0 = att0
        align.Attachment1 = att1
        
        task.wait(0.3)
        Services.RunService:Set3dRenderingEnabled(false)
        
        vehicle:PivotTo(targetCFrame)
        
        task.delay(1, function()
            align:Destroy()
            att0:Destroy()
            att1:Destroy()
        end)
    end)
end

function GameUtils.FireProximityPrompt(prompt, count)
    count = count or 1
    for i = 1, count do
        fireproximityprompt(prompt)
    end
end

-- ============================================================================
-- MODULE: Anti-AFK System
-- ============================================================================
local AntiAFK = {}

function AntiAFK.Initialize()
    local keys = {"W", "A", "S", "D"}
    
    local connection = LocalPlayer.Idled:Connect(function()
        pcall(function()
            local randomKey = keys[math.random(1, #keys)]
            Services.VirtualInputManager:SendKeyEvent(true, randomKey, false, game)
            task.wait(math.random(0.1, 0.3))
            Services.VirtualInputManager:SendKeyEvent(false, randomKey, false, game)
            
            local randomX = math.random(-50, 50)
            local randomY = math.random(-50, 50)
            Services.VirtualInputManager:SendMouseMoveEvent(randomX, randomY, game)
        end)
    end)
    
    LocalPlayer.CharacterRemoving:Connect(function()
        if connection then
            connection:Disconnect()
        end
    end)
    
    return connection
end

-- ============================================================================
-- MODULE: Job Farming System
-- ============================================================================
local JobFarming = {}

function JobFarming.SolveOfficeQuest()
    local quest = LocalPlayer.PlayerGui.Job.Components.Container.Office.Frame.Question.Text
    local splitQuest = string.split(quest, " ")
    local num1 = tonumber(splitQuest[1])
    local operator = splitQuest[2]
    local num2 = tonumber(splitQuest[3])
    
    local result
    if operator == "+" then
        result = tostring(num1 + num2)
    elseif operator == "-" then
        result = tostring(num1 - num2)
    end
    
    return result
end

function JobFarming.StartOfficeJob()
    Services.ReplicatedStorage.NetworkContainer.RemoteEvents.Job:FireServer("Office")
    
    pcall(function()
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-38581, 1039, -62763)
    end)
    
    task.wait(1)
    GameUtils.FireProximityPrompt(workspace.Etc.Job.Office.Starter.Prompt, 8)
    
    while not getgenv().Settings.StopFarm do
        for i = 1, 5 do
            if getgenv().Settings.StopFarm then break end
            
            local solution = JobFarming.SolveOfficeQuest()
            local textBox = LocalPlayer.PlayerGui.Job.Components.Container.Office.Frame.TextBox
            local submitButton = LocalPlayer.PlayerGui.Job.Components.Container.Office.Frame.SubmitButton
            
            textBox.Text = solution
            
            repeat task.wait(0.1) until textBox.Text == solution
            
            if submitButton.Visible then
                game:GetService('GuiService').SelectedObject = submitButton
                Services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait(0.1)
                Services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                task.wait(0.2)
                game:GetService('GuiService').SelectedObject = nil
            end
        end
        task.wait(0.5)
    end
end

function JobFarming.StartBaristaJob()
    Services.ReplicatedStorage.NetworkContainer.RemoteEvents.Job:FireServer("JanjiJiwa")
    
    task.spawn(function()
        while not getgenv().Settings.StopFarm do
            pcall(function()
                GameUtils.FireProximityPrompt(workspace.Etc.Job.JanjiJiwa.Starter.Prompt, 2)
                
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-13716.3544921875, 1052.8948974609375, -17997.69921875)
                
                local hasCoffee = LocalPlayer.Backpack:FindFirstChild("Coffee")
                if hasCoffee then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-13723.75390625, 1052.8948974609375, -17994.228515625)
                    Services.ReplicatedStorage.NetworkContainer.RemoteEvents.JanjiJiwa:FireServer("Delivery")
                end
                
                task.wait(15)
            end)
        end
    end)
end

function JobFarming.Start(jobType)
    if jobType == "Office Worker" then
        JobFarming.StartOfficeJob()
    elseif jobType == "Barista" then
        JobFarming.StartBaristaJob()
    end
end

-- ============================================================================
-- MODULE: Truck Farming System
-- ============================================================================
local TruckFarming = {}

function TruckFarming.GetVehicle()
    local vehicles = workspace:FindFirstChild("Vehicles")
    if not vehicles then return nil end
    return vehicles:FindFirstChild(LocalPlayer.Name .. "sCar")
end

function TruckFarming.SpawnVehicle()
    local spawnPos = CFrame.new(-21782.94140625, 1042.0301513671875, -26786.958984375)
    Services.TweenService:Create(
        LocalPlayer.Character.HumanoidRootPart,
        TweenInfo.new(2, Enum.EasingStyle.Quad),
        {CFrame = spawnPos}
    ):Play()
    
    task.wait(2)
    Services.VirtualInputManager:SendKeyEvent(true, "F", false, game)
    task.wait(0.3)
    Services.VirtualInputManager:SendKeyEvent(false, "F", false, game)
    task.wait(5)
    
    local vehicle
    repeat
        vehicle = TruckFarming.GetVehicle()
        if not vehicle then
            Services.VirtualInputManager:SendKeyEvent(true, "F", false, game)
            Services.VirtualInputManager:SendKeyEvent(false, "F", false, game)
            task.wait(0.8)
        end
    until vehicle
    
    return vehicle
end

function TruckFarming.Start(statusCallback)
    while getgenv().Settings.OnFarming do
        pcall(function()
            statusCallback("Checking requirements...")
            task.wait(0.8)
            
            -- Take truck job
            Services.ReplicatedStorage.NetworkContainer.RemoteEvents.Job:FireServer("Truck")
            statusCallback("Taking trucker job...")
            
            -- Wait for waypoint
            local waypoint
            repeat
                waypoint = workspace.Etc.Waypoint:FindFirstChild("Waypoint")
                if not waypoint then
                    Services.ReplicatedStorage.NetworkContainer.RemoteEvents.Job:FireServer("Truck")
                    task.wait(0.4)
                end
            until waypoint
            
            -- Navigate to destination
            statusCallback("Navigating to PT. Shad Cirebon...")
            Services.TweenService:Create(
                LocalPlayer.Character.HumanoidRootPart,
                TweenInfo.new(1, Enum.EasingStyle.Linear),
                {CFrame = CFrame.new(-21799.8, 1042.65, -26797.7)}
            ):Play()
            task.wait(0.2)
            
            -- Wait for correct destination
            repeat
                LocalPlayer.Character.HumanoidRootPart.Anchored = true
                local waypointLabel = waypoint:FindFirstChild("BillboardGui"):FindFirstChild("TextLabel")
                
                if waypointLabel.Text ~= "Rojod Semarang" then
                    Services.ReplicatedStorage.NetworkContainer.RemoteEvents.Job:FireServer("Truck")
                    GameUtils.FireProximityPrompt(workspace.Etc.Job.Truck.Starter.Prompt)
                end
                
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
                task.wait(0.8)
            until waypointLabel.Text == "Rojod Semarang"
            
            -- Spawn and enter vehicle
            statusCallback("Spawning truck...")
            local vehicle = TruckFarming.SpawnVehicle()
            
            if vehicle and vehicle:FindFirstChild("DriveSeat") then
                vehicle.DriveSeat:Sit(LocalPlayer.Character.Humanoid)
                task.wait(1.2)
                
                -- Countdown
                for i = 40, 0, -1 do
                    if not getgenv().Settings.OnFarming then
                        statusCallback("Farming stopped")
                        return
                    end
                    
                    statusCallback(string.format("Teleporting in %d seconds", i))
                    task.wait(1)
                end
                
                -- Teleport
                Services.RunService:Set3dRenderingEnabled(false)
                task.wait(0.3)
                GameUtils.SafeTeleport(vehicle, CFrame.new(-50889.6602, 1017.86719, -86514.7969, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268))
                task.wait(0.4)
                
                Services.ReplicatedStorage.NetworkContainer.RemoteEvents.Job:FireServer("Truck")
                task.wait(getgenv().Settings.DelayBeforeRejoin or 0.5)
                
                Services.TeleportService:Teleport(6911148748, LocalPlayer)
                task.wait(100)
            end
        end)
        task.wait(1)
    end
end

-- ============================================================================
-- MODULE: Event System (CNY 2025)
-- ============================================================================
local EventSystem = {}

function EventSystem.CollectSnakes()
    local snakes = {}
    for _, snake in ipairs(workspace.Event.Client.Snake:GetChildren()) do
        table.insert(snakes, snake)
    end
    
    if #snakes == 0 then return end
    
    table.sort(snakes, function(a, b)
        return tonumber(a.Name) < tonumber(b.Name)
    end)
    
    for _, snake in ipairs(snakes) do
        if not getgenv().Temporary.onFindingSnake then break end
        
        local position = snake.Position
        if position and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
            
            Services.VirtualInputManager:SendKeyEvent(true, "E", false, game)
            task.wait(4)
            Services.VirtualInputManager:SendKeyEvent(false, "E", false, game)
            task.wait(2)
        end
    end
    
    getgenv().Temporary.onFindingSnake = false
end

function EventSystem.CollectAngpao()
    local angpaos = {}
    for _, angpao in ipairs(workspace.Event.Client.Angpao:GetChildren()) do
        table.insert(angpaos, angpao)
    end
    
    if #angpaos == 0 then return end
    
    table.sort(angpaos, function(a, b)
        return tonumber(a.Name) < tonumber(b.Name)
    end)
    
    for _, angpao in ipairs(angpaos) do
        if not getgenv().Temporary.onFindingAngpao then break end
        
        local position = angpao.Position
        if position and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
            task.wait(2)
            
            local prompt = angpao.ProximityPrompt
            if prompt then
                fireproximityprompt(prompt)
            end
            task.wait(2)
        end
    end
    
    getgenv().Temporary.onFindingAngpao = false
end

function EventSystem.ClaimAllQuests()
    for i = 5, 1, -1 do
        Services.ReplicatedStorage.NetworkContainer.RemoteEvents.ClaimEventQuest:FireServer("Quest" .. i)
        task.wait(1)
    end
end

-- ============================================================================
-- MODULE: UI Manager
-- ============================================================================
local UIManager = {}

function UIManager.Initialize(settingsManager)
    -- Load MacLib
    local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()
    local Window = MacLib:Window({
        Title = "LunarV2 - Car Driving Indonesia",
        Subtitle = "Refactored Edition",
        Size = UDim2.fromOffset(750, 400),
        DragStyle = 2,
        DisabledWindowControls = {},
        ShowUserInfo = true,
        Keybind = Enum.KeyCode.RightControl,
        AcrylicBlur = true,
    })
    
    -- Global Settings
    local function notifyState(name, state)
        Window:Notify({
            Title = "LunarV2",
            Description = state .. " " .. name,
            Lifetime = 5
        })
    end
    
    Window:GlobalSetting({
        Name = "UI Blur",
        Default = Window:GetAcrylicBlurState(),
        Callback = function(b)
            Window:SetAcrylicBlurState(b)
            notifyState("UI Blur", b and "Enabled" or "Disabled")
        end
    })
    
    Window:GlobalSetting({
        Name = "Notifications",
        Default = Window:GetNotificationsState(),
        Callback = function(b)
            Window:SetNotificationsState(b)
            notifyState("Notifications", b and "Enabled" or "Disabled")
        end
    })
    
    -- Create tabs
    local tabGroups = {
        Main = Window:TabGroup(),
        Secondary = Window:TabGroup()
    }
    
    local tabs = {
        Home = tabGroups.Main:Tab({ Name = "Home", Image = "rbxassetid://10734942198" }),
        Features = tabGroups.Main:Tab({ Name = "Features", Image = "rbxassetid://10723407389" }),
        Farming = tabGroups.Secondary:Tab({ Name = "Farming", Image = "rbxassetid://10747364031" }),
        Event = tabGroups.Secondary:Tab({ Name = "Event", Image = "rbxassetid://10709783577" }),
        Settings = tabGroups.Secondary:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })
    }
    
    UIManager.BuildHomePage(tabs.Home, settingsManager, Window)
    UIManager.BuildFeaturesPage(tabs.Features, settingsManager, Window)
    UIManager.BuildFarmingPage(tabs.Farming, settingsManager, Window)
    UIManager.BuildEventPage(tabs.Event, settingsManager, Window)
    UIManager.BuildSettingsPage(tabs.Settings, settingsManager, Window)
    
    MacLib:SetFolder("LunarV2")
    tabs.Settings:InsertConfigSection("Left")
    tabs.Home:Select()
    MacLib:LoadAutoLoadConfig()
    
    return Window
end

function UIManager.BuildHomePage(tab, settingsManager, Window)
    local leftSection = tab:Section({ Side = "Left" })
    local rightSection = tab:Section({ Side = "Right" })
    
    leftSection:Header({ Name = "Local Player" })
    
    leftSection:Slider({
        Name = "Walkspeed",
        Default = 16,
        Minimum = 2,
        Maximum = 250,
        DisplayMethod = "Percent",
        Precision = 0,
        Callback = function(value)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = value
            end
        end
    })
    
    leftSection:Slider({
        Name = "Jump Power",
        Default = 16,
        Minimum = 2,
        Maximum = 250,
        DisplayMethod = "Percent",
        Precision = 0,
        Callback = function(value)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpHeight = value
            end
        end
    })
    
    leftSection:Toggle({
        Name = "Infinite Jump",
        Default = getgenv().Settings.InfiniteJump,
        Callback = function(value)
            getgenv().Settings.InfiniteJump = value
            settingsManager:Save()
        end
    })
    
    leftSection:Toggle({
        Name = "Click TP (CTRL + Click)",
        Default = false,
        Callback = function(value)
            if value then
                Services.UserInputService.InputBegan:Connect(function(input)
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 
                       input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = 
                                CFrame.new(LocalPlayer:GetMouse().Hit.Position + Vector3.new(0, 5, 0))
                        end
                    end
                end)
            end
        end
    })
    
    leftSection:Toggle({
        Name = "No Clip",
        Default = false,
        Callback = function(value)
            Services.RunService.Stepped:Connect(function()
                if value and LocalPlayer.Character then
                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    })
    
    rightSection:Header({ Name = "Security" })
    
    rightSection:Toggle({
        Name = "Spoof Name",
        Default = getgenv().Settings.SpoofToggle,
        Callback = function(value)
            getgenv().Settings.SpoofToggle = value
            settingsManager:Save()
        end
    })
    
    rightSection:Input({
        Name = "Custom Name",
        Placeholder = "Enter name",
        AcceptedCharacters = "All",
        Callback = function(input)
            getgenv().Settings.SpoofedName = input
            settingsManager:Save()
        end
    })
end

function UIManager.BuildFeaturesPage(tab, settingsManager, Window)
    local leftSection = tab:Section({ Side = "Left" })
    local rightSection = tab:Section({ Side = "Right" })
    
    leftSection:Header({ Name = "Side Jobs" })
    
    leftSection:Dropdown({
        Name = "Select Job",
        Multi = false,
        Required = true,
        Options = {"Office Worker", "Barista"},
        Default = getgenv().Settings.SelectedJob,
        Callback = function(value)
            getgenv().Settings.SelectedJob = value
            settingsManager:Save()
            Window:Notify({
                Title = "LunarV2",
                Description = "Selected: " .. value
            })
        end
    })
    
    leftSection:Toggle({
        Name = "Start Job Farming",
        Default = false,
        Callback = function(value)
            if value then
                if getgenv().Settings.SelectedJob then
                    getgenv().Settings.StopFarm = false
                    settingsManager:Save()
                    JobFarming.Start(getgenv().Settings.SelectedJob)
                else
                    Window:Notify({
                        Title = "LunarV2",
                        Description = "Please select a job first"
                    })
                end
            else
                getgenv().Settings.StopFarm = true
                settingsManager:Save()
            end
        end
    })
    
    rightSection:Header({ Name = "Vehicle Tools" })
    
    local vehicleNames = {}
    local limitedStock = Services.ReplicatedStorage:FindFirstChild("LimitedStock")
    if limitedStock then
        for _, child in ipairs(limitedStock:GetChildren()) do
            table.insert(vehicleNames, child.Name)
        end
    end
    
    if #vehicleNames > 0 then
        rightSection:Dropdown({
            Name = "Select Vehicle",
            Multi = false,
            Options = vehicleNames,
            Callback = function(value)
                getgenv().SelectedVehicle = value
            end
        })
        
        rightSection:Button({
            Name = "Buy Selected Vehicle",
            Callback = function()
                if getgenv().SelectedVehicle then
                    Services.ReplicatedStorage.NetworkContainer.RemoteFunctions.Dealership:InvokeServer("Buy", getgenv().SelectedVehicle)
                else
                    Window:Notify({
                        Title = "LunarV2",
                        Description = "Select a vehicle first"
                    })
                end
            end
        })
    end
end

function UIManager.BuildFarmingPage(tab, settingsManager, Window)
    local leftSection = tab:Section({ Side = "Left" })
    local rightSection = tab:Section({ Side = "Right" })
    
    leftSection:Header({ Name = "Truck Farming" })
    
    local statusParagraph = rightSection:Paragraph({
        Header = "Status",
        Body = "Idle"
    })
    
    leftSection:Input({
        Name = "Rejoin Delay (seconds)",
        Placeholder = tostring(getgenv().Settings.DelayBeforeRejoin),
        AcceptedCharacters = "All",
        Callback = function(input)
            getgenv().Settings.DelayBeforeRejoin = tonumber(input) or 0.5
            settingsManager:Save()
        end
    })
    
    leftSection:Toggle({
        Name = "Countdown Notifications",
        Default = getgenv().Settings.CountdownNotif,
        Callback = function(value)
            getgenv().Settings.CountdownNotif = value
            settingsManager:Save()
        end
    })
    
    leftSection:Toggle({
        Name = "Start Truck Farming",
        Default = getgenv().Settings.OnFarming,
        Callback = function(value)
            getgenv().Settings.OnFarming = value
            settingsManager:Save()
            
            if value then
                task.spawn(function()
                    TruckFarming.Start(function(status)
                        statusParagraph:UpdateBody(status)
                        if getgenv().Settings.CountdownNotif then
                            Window:Notify({
                                Title = "Truck Farming",
                                Description = status
                            })
                        end
                    end)
                end)
            end
        end
    })
end

function UIManager.BuildEventPage(tab, settingsManager, Window)
    local gameName = GameUtils.GetCurrentGameName()
    if gameName ~= Config.GameNames.EventGame then
        tab:Section({ Side = "Left" }):Label({
            Text = "Event features only available in " .. Config.GameNames.EventGame
        })
        return
    end
    
    local leftSection = tab:Section({ Side = "Left" })
    local rightSection = tab:Section({ Side = "Right" })
    
    leftSection:Header({ Name = "CNY 2025 Event" })
    
    leftSection:Toggle({
        Name = "Auto Collect Snakes",
        Default = false,
        Callback = function(value)
            getgenv().Temporary.onFindingSnake = value
            if value then
                task.spawn(function()
                    while getgenv().Temporary.onFindingSnake do
                        EventSystem.CollectSnakes()
                        task.wait(1)
                    end
                end)
            end
        end
    })
    
    leftSection:Toggle({
        Name = "Auto Collect Angpao",
        Default = false,
        Callback = function(value)
            getgenv().Temporary.onFindingAngpao = value
            if value then
                task.spawn(function()
                    while getgenv().Temporary.onFindingAngpao do
                        EventSystem.CollectAngpao()
                        task.wait(1)
                    end
                end)
            end
        end
    })
    
    leftSection:Button({
        Name = "Claim All Quests",
        Callback = function()
            EventSystem.ClaimAllQuests()
        end
    })
    
    leftSection:Button({
        Name = "Claim Daily Reward",
        Callback = function()
            Services.ReplicatedStorage.NetworkContainer.RemoteEvents.ClaimDailyLogin:FireServer()
        end
    })
    
    rightSection:Header({ Name = "Teleports" })
    
    rightSection:Button({
        Name = "Event Area",
        Callback = function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                Services.TweenService:Create(
                    LocalPlayer.Character.HumanoidRootPart,
                    TweenInfo.new(1, Enum.EasingStyle.Linear),
                    {CFrame = CFrame.new(workspace.Event.LunarZone.WorldPivot.Position)}
                ):Play()
            end
        end
    })
end

function UIManager.BuildSettingsPage(tab, settingsManager, Window)
    local section = tab:Section({ Side = "Right" })
    
    section:Header({ Name = "Tools" })
    
    section:Button({
        Name = "Dex Explorer",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
        end
    })
    
    section:Button({
        Name = "Simple Spy",
        Callback = function()
            loadstring(game:HttpGet("https://github.com/exxtremestuffs/SimpleSpySource/raw/master/SimpleSpy.lua"))()
        end
    })
end

-- ============================================================================
-- MAIN EXECUTION
-- ============================================================================
local function Main()
    -- Wait for game to load
    repeat task.wait() until game:IsLoaded()
    
    -- Initialize settings
    local settingsManager = SettingsManager.new()
    
    -- Check game and handle private server auto-join
    local gameName = GameUtils.GetCurrentGameName()
    if gameName == Config.GameNames.MainGame and getgenv().autoPS then
        local HubChecker = GameUtils.WaitForChild(LocalPlayer.PlayerGui, "Hub", 10)
        if HubChecker then
            local CodePath = HubChecker.Container.Window.PrivateServer.ServerLabel
            
            if CodePath.ContentText == "None" then
                local attempts = 0
                repeat
                    if attempts == 15 then
                        Services.ReplicatedStorage.NetworkContainer.RemoteEvents.PrivateServer:FireServer("Create")
                        task.wait(0.6)
                    end
                    attempts = attempts + 1
                    task.wait(0.9)
                until CodePath.ContentText ~= "None"
            end
            
            Services.ReplicatedStorage.NetworkContainer.RemoteEvents.PrivateServer:FireServer("Join", CodePath.ContentText, "JawaTengah")
        end
        return
    end
    
    -- Wait for player setup
    repeat task.wait() until LocalPlayer and LocalPlayer.Character
    
    -- Create Lives folder if needed (for CNY event)
    if gameName == Config.GameNames.EventCNY then
        if not workspace:FindFirstChild("Lives") then
            local livesFolder = Instance.new("Folder")
            livesFolder.Name = "Lives"
            livesFolder.Parent = workspace
            
            local playerModel = Instance.new("Model")
            playerModel.Name = LocalPlayer.Name
            
            local head = Instance.new("Part")
            head.Name = "Head"
            head.Parent = playerModel
            
            local hrp = Instance.new("Part")
            hrp.Name = "HumanoidRootPart"
            hrp.Parent = playerModel
            
            playerModel.Parent = livesFolder
        end
    end
    
    -- Initialize systems
    AntiAFK.Initialize()
    
    -- Initialize UI
    local Window = UIManager.Initialize(settingsManager)
    
    -- Start auto-farming if enabled
    if getgenv().Settings.OnFarming then
        task.spawn(function()
            task.wait(2)
            Window:Notify({
                Title = "LunarV2",
                Description = "Auto-farming enabled, starting..."
            })
            TruckFarming.Start(function(status)
                if getgenv().Settings.CountdownNotif then
                    Window:Notify({
                        Title = "Truck Farming",
                        Description = status
                    })
                end
            end)
        end)
    end
    
    Window:Notify({
        Title = "LunarV2",
        Description = "Successfully loaded! Version " .. Config.Version
    })
end

-- Execute
local success, err = pcall(Main)
if not success then
    warn("[LunarV2] Error:", err)
end
