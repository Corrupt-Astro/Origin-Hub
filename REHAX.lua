-- Global Shared Services and Player Setup
shared = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    ProximityPromptService = game:GetService("ProximityPromptService"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Character = nil
}
local VirtualInputManager = game:GetService("VirtualInputManager")
LocalPlayer = shared.Players.LocalPlayer;
Mouse = LocalPlayer:GetMouse()

if LocalPlayer.Character then shared.Character = LocalPlayer.Character end;

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    shared.Character = LocalPlayer.Character
end)

-- Universal Library Loading (Loaded once for all games)
local BASE_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(BASE_URL .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(BASE_URL .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(BASE_URL .. "addons/SaveManager.lua"))()
local ESPLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheHunterSolo1/Scripts/main/ESPLibrary"))()

-- Universal ESP Helper Function
function Addesp(Object, Text, Color)
    ESPLibrary:AddESP(Object, Text, Color)
end

--------------------------------------------------------------------------------
--- UNIVERSAL UI AND MANAGER SETUP FUNCTIONS
--------------------------------------------------------------------------------

-- Function to set up the common 'UI Settings' tab content
local function SetupUISettingsGroup(Tabs, Library, Connections, UnloadSpeed, SetUnloadedFlag)
    local UISettingsGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
    
    -- UI Toggles
    UISettingsGroup:AddToggle("KeybindMenuOpen", {
        Default = Library.KeybindFrame.Visible, 
        Text = "Open Keybind Menu", 
        Callback = function(IsOpen) 
            Library.KeybindFrame.Visible = IsOpen 
        end
    })
    
    UISettingsGroup:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor", 
        Default = true, 
        Callback = function(isEnabled) 
            Library.ShowCustomCursor = isEnabled 
        end
    })
    
    UISettingsGroup:AddDropdown("NotificationSide", {
        Values = {"Left", "Right"}, 
        Default = "Right", 
        Text = "Notification Side", 
        Callback = function(Side) 
            Library:SetNotifySide(Side)
        end
    })
    
    UISettingsGroup:AddDropdown("DPIDropdown", {
        Values = {"50%", "75%", "100%", "125%", "150%", "175%", "200%"}, 
        Default = "100%", 
        Text = "DPI Scale", 
        Callback = function(ScaleText) 
            ScaleText = ScaleText:gsub("%%", "")
            local ScaleValue = tonumber(ScaleText)
            Library:SetDPIScale(ScaleValue)
        end
    })
    
    UISettingsGroup:AddDivider()
    
    -- Keybind
    UISettingsGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
        Default = "RightShift", 
        NoUI = true, 
        Text = "Menu keybind"
    })

    -- Unload Button (Custom speed reset logic)
    UISettingsGroup:AddButton("Unload", function()
        if SetUnloadedFlag then
            Library.Unloaded = true; -- Used by Anticheat Bypass in some games
        end
        
        -- Reset speed if defined
        if UnloadSpeed and shared.Character and shared.Character.Humanoid then
            shared.Character.Humanoid.WalkSpeed = shared.Character:GetAttribute("Speed") or UnloadSpeed
        end

        Library:Unload()
        ESPLibrary:Unload()
        for Index, Connection in pairs(Connections) do 
            Connection:Disconnect()
        end 
    end)
    
    UISettingsGroup:AddButton("Join Discord", function()
        toclipboard("https://discord.gg/CBDfkeXsZs")
    end)
end

-- Function to set up the Theme/Save Managers
local function SetupManagers(Library, ThemeManager, SaveManager, Tabs, GameFolder)
    Library.ToggleKeybind = Library.Options.MenuKeybind;
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({"MenuKeybind"})
    ThemeManager:SetFolder("OriginHub")
    SaveManager:SetFolder("OriginHub/" .. GameFolder) -- GameFolder is "99Nights", "EatWorld", etc.
    SaveManager:BuildConfigSection(Tabs["UI Settings"])
    ThemeManager:ApplyToTab(Tabs["UI Settings"])
    SaveManager:LoadAutoloadConfig()
end

--------------------------------------------------------------------------------
--- GAME-SPECIFIC LOGIC BLOCKS
--------------------------------------------------------------------------------

-- Game: 99 Nights
if game.PlaceId == 126509999114328 then 
    local Options = Library.Options;
    local Toggles = Library.Toggles;
    local Connections = {}
    
    local Window = Library:CreateWindow({Title=" 倹 Origin Hub",Footer="version: 1",NotifySide="Right",ShowCustomCursor=true})
    local Tabs = {Main=Window:AddTab("Main","user"),["UI Settings"]=Window:AddTab("UI Settings","settings")}
    
    local ESPGroup = Tabs.Main:AddRightGroupbox('ESP')
    local SelfGroup = Tabs.Main:AddLeftGroupbox('Self')
    
    -- Self
    SelfGroup:AddToggle('MaxSpeed',{Text="Always Sprint (Infinite)",Default=false})
    
    Toggles.MaxSpeed:OnChanged(function(isEnabled)
        if isEnabled then 
            shared.Character:SetAttribute("Speed",shared.Character.Humanoid.WalkSpeed)
        else 
            shared.Character.Humanoid.WalkSpeed = shared.Character:GetAttribute("Speed") or 19 
        end 
    end)
    
    -- ESP
    ESPGroup:AddToggle('CarrotESP',{Text="Items ESP",Default=false,Callback=function(isEnabled)
        if isEnabled then 
            for Index,ItemModel in pairs(workspace.Items:GetChildren())do 
                if ItemModel:IsA("Model")then 
                    Addesp(ItemModel,ItemModel.Name,Color3.new(0,1,0))
                end 
            end 
        else 
            for Index,ItemModel in pairs(workspace.Items:GetChildren())do 
                if ItemModel:IsA("Model")then 
                    ESPLibrary:RemoveESP(ItemModel)
                end 
            end 
        end 
    end})
    
    ESPGroup:AddToggle('EnemysESP',{Text="Enemy's ESP",Default=false,Callback=function(isEnabled)
        if isEnabled then 
            for Index,CharacterModel in pairs(workspace.Characters:GetChildren())do 
                if CharacterModel:IsA("Model")then 
                    Addesp(CharacterModel,CharacterModel.Name,Color3.new(1,0,0))
                end 
            end 
        else 
            for Index,CharacterModel in pairs(workspace.Characters:GetChildren())do 
                if CharacterModel:IsA("Model")then 
                    ESPLibrary:RemoveESP(CharacterModel)
                end 
            end 
        end 
    end})
    
    -- Connections
    table.insert(Connections,shared.RunService.RenderStepped:Connect(function()
        if Toggles.MaxSpeed.Value then 
            shared.Character.Humanoid.WalkSpeed = 27 
        end 
    end))
    
    table.insert(Connections,workspace.Items.ChildAdded:Connect(function(ItemModel)
        if ItemModel:IsA("Model") and Toggles.CarrotESP.Value then 
            Addesp(ItemModel,ItemModel.Name,Color3.new(0,1,0))
        end 
    end))
    
    table.insert(Connections,workspace.Characters.ChildAdded:Connect(function(CharacterModel)
        if CharacterModel:IsA("Model") and Toggles.EnemysESP.Value then 
            Addesp(CharacterModel,CharacterModel.Name,Color3.new(1,0,0))
        end 
    end))

    -- Universal Setup Calls
    SetupUISettingsGroup(Tabs, Library, Connections, 19, false) -- UnloadSpeed 19, no SetUnloadedFlag
    SetupManagers(Library, ThemeManager, SaveManager, Tabs, "99Nights")
end;

-- Game: Eat World
if game.PlaceId == 16480898254 then 
    local Options = Library.Options;
    local Toggles = Library.Toggles;
    local Connections = {}
    
    local Window = Library:CreateWindow({Title=" 倹 Origin Hub",Footer="version: 1",NotifySide="Right",ShowCustomCursor=true})
    local Tabs = {Main=Window:AddTab("Main","user"),["UI Settings"]=Window:AddTab("UI Settings","settings")}
    
    local AutomationGroup = Tabs.Main:AddRightGroupbox('Automation')
    
    -- Automation
    AutomationGroup:AddToggle('AutoGrab',{Text="Automation Grab",Default=false})
    AutomationGroup:AddToggle('AutoEat',{Text="Automation Eat",Default=false})
    AutomationGroup:AddToggle('AutoSell',{Text="Automation Sell (When Full)",Default=false})
    
    -- Connections
    table.insert(Connections,shared.RunService.Heartbeat:Connect(function()
        if shared.Character and shared.Character:FindFirstChild("HumanoidRootPart")then 
            if Toggles.AutoGrab.Value then 
                local GrabArguments = {false,false,false}
                game:GetService("Players").LocalPlayer.Character:WaitForChild("Events"):WaitForChild("Grab"):FireServer(unpack(GrabArguments))
                shared.Character.HumanoidRootPart.Anchored = false 
            end;
            
            if Toggles.AutoEat.Value then 
                game:GetService("Players").LocalPlayer.Character:WaitForChild("Events"):WaitForChild("Eat"):FireServer()
            end;
            
            if Toggles.AutoSell.Value and game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.Sell.WarningText.Visible==true then 
                game:GetService("Players").LocalPlayer.Character:WaitForChild("Events"):WaitForChild("Sell"):FireServer()
            end 
        end 
    end))
    
    -- Universal Setup Calls
    SetupUISettingsGroup(Tabs, Library, Connections, nil, false) -- No explicit speed reset needed
    SetupManagers(Library, ThemeManager, SaveManager, Tabs, "EatWorld")
end;

-- Game: Tower Hell (or a similar place ID)
if game.PlaceId == 1962086868 or game.PlaceId == 3582763398 then 
    local Options = Library.Options;
    local Toggles = Library.Toggles;
    local Connections = {}
    
    local Window = Library:CreateWindow({Title=" 倹 Origin Hub",Footer="version: 1",NotifySide="Right",ShowCustomCursor=true})
    local Tabs = {Main=Window:AddTab("Main","user"),["UI Settings"]=Window:AddTab("UI Settings","settings")}
    
    local BypassGroup = Tabs.Main:AddRightGroupbox('Bypass')
    local SelfGroup = Tabs.Main:AddLeftGroupbox('Self')
    
    -- Self
    SelfGroup:AddButton("Get All Tools",function()
        for Index,ToolModel in pairs(game:GetService("ReplicatedStorage").Assets.Gear:GetChildren())do 
            if ToolModel:IsA("Tool")then 
                ToolModel:Clone().Parent=LocalPlayer.Backpack 
            end 
        end 
    end)
    
    SelfGroup:AddToggle('Godmode',{Text="God Mode",Default=false})
    
    -- Bypass
    BypassGroup:AddToggle('AnticheatBypass',{Text="Anticheat Bypass",Default=false,Disabled=not hookfunction,DisabledTooltip="This Feature is not supported by the Executor"})
    
    -- Connections
    table.insert(Connections,LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if Toggles.Godmode.Value then 
            if LocalPlayer.Character.Humanoid.Health < LocalPlayer.Character.Humanoid.MaxHealth then 
                LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth 
            end 
        end 
    end))
    
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        table.insert(Connections,LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if Toggles.Godmode.Value then 
                if LocalPlayer.Character.Humanoid.Health < LocalPlayer.Character.Humanoid.MaxHealth then 
                    LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth 
                end 
            end 
        end))
    end)
    
    for Index,Function in getgc(true)do 
        if typeof(Function)=="function"then 
            local DebugInfo=debug.getinfo(Function)
            if DebugInfo.name=="kick"then 
                hookfunction(Function,function(...)
                    if Toggles.AnticheatBypass.Value and Library.Unloaded == false then 
                        return nil 
                    end 
                end)
            end 
        end 
    end;
    
    -- Universal Setup Calls
    SetupUISettingsGroup(Tabs, Library, Connections, 19, true) -- UnloadSpeed 19, SetUnloadedFlag true for hook check
    SetupManagers(Library, ThemeManager, SaveManager, Tabs, "TowerHell")
end;

-- Game: Slap Battles (or a similar place ID)
if game.PlaceId == 124596094333302 or game.PlaceId == 6403373529 then 
    local Options = Library.Options;
    local Toggles = Library.Toggles;
    local Connections = {}
    
    local Window = Library:CreateWindow({Title=" 倹 Origin Hub",Footer="version: 1",NotifySide="Right",ShowCustomCursor=true})
    local Tabs = {Main=Window:AddTab("Main","user"),["UI Settings"]=Window:AddTab("UI Settings","settings")}
    
    local AuraGroup = Tabs.Main:AddLeftGroupbox('Aura')
    local AntiGroup = Tabs.Main:AddRightGroupbox('Anti')
    
    -- Anti
    AntiGroup:AddToggle('AntiRagdoll',{Text="Anti Ragdoll",Default=false})
    
    -- Aura
    AuraGroup:AddToggle('SlapAura',{Text="Slap Aura",Default=false})
    AuraGroup:AddSlider("SlapAuraReach",{Text="Slap Aura Reach",Default=12,Min=10,Max=20,Rounding=1,Compact=true,Callback=function(Value)end})
    
    local function GetNearestEnemy()
        local ClosestDistance = Options.SlapAuraReach.Value;
        local NearestCharacter = nil;
        for Index,Player in ipairs(shared.Players:GetPlayers())do 
            if Player~=LocalPlayer and Player.Character then 
                local Distance=(LocalPlayer.Character.HumanoidRootPart.Position-Player.Character.HumanoidRootPart.Position).Magnitude;
                if Distance < ClosestDistance then 
                    ClosestDistance = Distance;
                    NearestCharacter = Player.Character 
                end 
            end 
        end;
        return NearestCharacter 
    end;
    
    local CooldownTimer = 0;
    
    -- Connections
    table.insert(Connections,shared.RunService.Heartbeat:Connect(function(DeltaTime)
        CooldownTimer = CooldownTimer + DeltaTime;
        if CooldownTimer >= 0.6 then 
            CooldownTimer = 0;
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")and LocalPlayer.Character.Humanoid.Health > 0 then 
                if Toggles.SlapAura.Value then 
                    local Target = GetNearestEnemy()
                    if Target then 
                        local HitArguments = {Target:FindFirstChildWhichIsA("BasePart")}
                        for Index,RemoteEvent in pairs(shared.ReplicatedStorage:GetChildren())do 
                            if RemoteEvent:IsA("RemoteEvent")then 
                                if string.match(RemoteEvent.Name,"Hit")or string.match(RemoteEvent.Name,"hit")then 
                                    RemoteEvent:FireServer(unpack(HitArguments))
                                end 
                            end 
                        end 
                    end 
                end 
            end 
        end 
    end))
    
    table.insert(Connections,shared.RunService.Heartbeat:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")and LocalPlayer.Character.Humanoid.Health > 0 then 
            if Toggles.AntiRagdoll.Value then 
                LocalPlayer.Character.HumanoidRootPart.Anchored = LocalPlayer.Character:FindFirstChild("Ragdolled").Value 
            end 
        end 
    end))
    
    -- Universal Setup Calls
    SetupUISettingsGroup(Tabs, Library, Connections, 19, true) -- UnloadSpeed 19, SetUnloadedFlag true for general cleanup
    SetupManagers(Library, ThemeManager, SaveManager, Tabs, "SlapBattles")
end;

-- Game: The Strongest Battlegrounds
if game.PlaceId == 10449761463 then 
    local Options = Library.Options;
    local Toggles = Library.Toggles;
    local Connections = {}
    
    local Window = Library:CreateWindow({Title=" 倹 Origin Hub",Footer="version: 1",NotifySide="Right",ShowCustomCursor=true})
    local Tabs = {Main=Window:AddTab("Main","user"),["UI Settings"]=Window:AddTab("UI Settings","settings")}
    
    local AntiGroup = Tabs.Main:AddRightGroupbox('Anti')
    local AutomationGroup = Tabs.Main:AddLeftGroupbox('Automation')
    
    -- Automation
    AutomationGroup:AddToggle('AutoKyoto',{Text="Auto Kyoto Combo",Default=false})
    AutomationGroup:AddDivider()
    AutomationGroup:AddToggle('AutoFarm',{Text="Auto Farm (Risk Getting Ban)",Default=false,Risky=true})
    AutomationGroup:AddSlider("AutoFarmOffset",{Text="Auto Farm Offset",Default=-5,Min=0,Max=-7,Rounding=1,Compact=true,Callback=function(Value)end})
    AutomationGroup:AddLabel('Less Value More Precise Hits Less protection',true)
    
    local OriginalCFrame;
    
    Toggles.AutoFarm:OnChanged(function(isEnabled)
        if isEnabled then 
            if OriginalCFrame ~= nil then 
                OriginalCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame 
            end 
        end;
        
        if not isEnabled then 
            LocalPlayer.Character.HumanoidRootPart.CFrame = OriginalCFrame;
            LocalPlayer.Character.Humanoid.PlatformStand = false;
            for Index,ToolObject in ipairs(LocalPlayer:GetDescendants())do 
                if ToolObject:IsA("Tool")then 
                    ToolObject.Parent = LocalPlayer.Backpack 
                end 
            end;
            
            local CommunicateArgs = {{Goal="LeftClickRelease",Mobile=game:GetService("UserInputService").TouchEnabled and true or false}}
            
            game:GetService("Players").LocalPlayer.Character:WaitForChild("Communicate"):FireServer(unpack(CommunicateArgs))
        end 
    end)
    
    local function GetNearestEnemy()
        local ClosestDistance = math.huge;
        local NearestCharacter = nil;
        for Index,Player in ipairs(shared.Players:GetPlayers())do 
            if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Humanoid")and Player.Character.Humanoid.Health > 0 then 
                if Player.Character:FindFirstChild("HumanoidRootPart")then 
                    local Distance = (LocalPlayer.Character.HumanoidRootPart.Position-Player.Character.HumanoidRootPart.Position).Magnitude;
                    if Distance < ClosestDistance then 
                        ClosestDistance = Distance;
                        NearestCharacter = Player.Character 
                    end 
                end 
            end 
        end;
        return NearestCharacter 
    end;
    
    function autofarm()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")then 
            local OffsetVector = Vector3.new(0,Options.AutoFarmOffset.Value,-3)
            local Target = GetNearestEnemy()
            if Target then 
                LocalPlayer.Character.Humanoid.PlatformStand = true;
                local TargetCFrame = Target.HumanoidRootPart.CFrame - Target.HumanoidRootPart.CFrame.LookVector * 2 + OffsetVector;
                LocalPlayer.Character.HumanoidRootPart.CFrame = TargetCFrame;
                for Index,ToolObject in ipairs(LocalPlayer.Backpack:GetChildren())do 
                    if ToolObject:IsA("Tool")then 
                        ToolObject.Parent = LocalPlayer.Character;
                        ToolObject.Parent = LocalPlayer.Backpack 
                    end 
                end;
                
                local CommunicateArgs = {{Goal="LeftClick",Mobile=game:GetService("UserInputService").TouchEnabled and true or false}}
                
                game:GetService("Players").LocalPlayer.Character:WaitForChild("Communicate"):FireServer(unpack(CommunicateArgs))
            end 
        end 
    end;
    
    if LocalPlayer.Character then 
        task.spawn(function()
            local FlowingWaterTool = LocalPlayer.Character:FindFirstChild("Flowing Water")or LocalPlayer.Backpack:FindFirstChild("Flowing Water")
            local LethalWhirlwindTool = LocalPlayer.Character:FindFirstChild("Lethal Whirlwind Stream")or LocalPlayer.Backpack:FindFirstChild("Lethal Whirlwind Stream")
            
            if not FlowingWaterTool then 
                return 
            end;
            
            FlowingWaterTool:GetPropertyChangedSignal("Parent"):Connect(function()
                if Toggles.AutoKyoto.Value then 
                    if game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.Backpack.Hotbar["1"].Base:FindFirstChild("Cooldown")then 
                        return 
                    end;
                    
                    if game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.Backpack.Hotbar["2"].Base:FindFirstChild("Cooldown")then 
                        return 
                    end;
                    
                    task.wait(2.1)
                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 20;
                    task.wait(0.2)
                    LethalWhirlwindTool.Parent = LocalPlayer.Character;
                    task.wait(0.03)
                    LethalWhirlwindTool.Parent = LocalPlayer.Backpack 
                end 
            end)
        end)
    end;
    
    table.insert(Connections,LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        task.spawn(function()
            local FlowingWaterTool = LocalPlayer.Character:FindFirstChild("Flowing Water")or LocalPlayer.Backpack:FindFirstChild("Flowing Water")
            local LethalWhirlwindTool = LocalPlayer.Character:FindFirstChild("Lethal Whirlwind Stream")or LocalPlayer.Backpack:FindFirstChild("Lethal Whirlwind Stream")
            
            if not FlowingWaterTool then 
                return 
            end;
            
            FlowingWaterTool:GetPropertyChangedSignal("Parent"):Connect(function()
                if Toggles.AutoKyoto.Value then 
                    if game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.Backpack.Hotbar["1"].Base:FindFirstChild("Cooldown")then 
                        return 
                    end;
                    
                    if game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.Backpack.Hotbar["2"].Base:FindFirstChild("Cooldown")then 
                        return 
                    end;
                    
                    task.wait(2.1)
                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 20;
                    task.wait(0.2)
                    LethalWhirlwindTool.Parent = LocalPlayer.Character;
                    task.wait(0.03)
                    LethalWhirlwindTool.Parent = LocalPlayer.Backpack 
                end 
            end)
        end)
    end))
    
    -- Anti
    AntiGroup:AddToggle('AntiStun',{Text="Anti Freeze",Default=false})
    AntiGroup:AddToggle('AntiLag',{Text="Anti Lag",Default=false})
    
    -- Connections
    table.insert(Connections,workspace:FindFirstChild("Thrown").ChildAdded:Connect(function(ThrownObject)
        task.delay(0.255,function()ThrownObject:Destroy()end)
    end))
    
    table.insert(Connections,shared.RunService.Heartbeat:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")and LocalPlayer.Character.Humanoid.Health > 0 then 
            if Toggles.AntiStun.Value then 
                if LocalPlayer.Character:FindFirstChild("Freeze")then 
                    LocalPlayer.Character:FindFirstChild("Freeze"):Destroy()
                end 
            end;
            
            if Toggles.AutoFarm.Value then 
                autofarm()
            end 
        end 
    end))
    
    -- Universal Setup Calls
    SetupUISettingsGroup(Tabs, Library, Connections, 16, true) -- UnloadSpeed 16, SetUnloadedFlag true for general cleanup
    SetupManagers(Library, ThemeManager, SaveManager, Tabs, "Tsbg")
end
