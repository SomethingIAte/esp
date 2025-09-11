-- ESP Module for xsx UI Library
local ESP = {
    Enabled = false,
    Players = {},
    Settings = {
        ShowName = true,
        ShowHealth = true,
        ShowWeapon = true,
        ShowBox = true,
        TeamColor = true,
        MaxDistance = 1000,
        TextSize = 14,
        HealthBarSize = Vector2.new(50, 4),
        BoxColor = Color3.fromRGB(255, 255, 255)
    }
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- Local player reference
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Create a container in CoreGui for ESP elements
local ESPContainer = Instance.new("ScreenGui")
ESPContainer.Name = "ESP_Container"
ESPContainer.ResetOnSpawn = false
ESPContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ESPContainer.Parent = CoreGui

-- Function to get equipped weapon
function ESP:GetEquippedWeapon(character)
    -- Look for tools in the character
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            return child.Name
        end
    end
    
    -- Check for weapons in the backpack if accessible
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
                    return tool.Name
                end
            end
        end
    end
    
    return "None"
end

-- Function to get player color
function ESP:GetPlayerColor(player)
    if self.Settings.TeamColor and player.Team then
        return player.Team.TeamColor.Color
    else
        return Color3.fromRGB(255, 255, 255)
    end
end

-- Function to remove ESP
function ESP:RemoveESP(esp)
    if esp.Container then esp.Container:Destroy() end
    if esp.RenderConnection then esp.RenderConnection:Disconnect() end
    
    esp.Container = nil
    esp.Label = nil
    esp.HealthBar = nil
    esp.HealthBarBackground = nil
    esp.WeaponLabel = nil
    esp.Box = nil
    esp.RenderConnection = nil
end

-- Function to create ESP for a player
function ESP:Create(player)
    if self.Players[player] then return end
    
    local esp = {
        Player = player,
        Container = nil,
        Label = nil,
        HealthBar = nil,
        HealthBarBackground = nil,
        WeaponLabel = nil,
        Box = nil,
        RenderConnection = nil,
        Visible = false
    }
    
    self.Players[player] = esp
    
    if player.Character then
        self:CharacterAdded(player, player.Character)
    end
    
    player.CharacterAdded:Connect(function(character)
        self:CharacterAdded(player, character)
    end)
    
    player.CharacterRemoving:Connect(function()
        self:RemoveESP(esp)
    end)
end

-- Function to handle when a character is added
function ESP:CharacterAdded(player, character)
    local esp = self.Players[player]
    if not esp then return end
    
    self:RemoveESP(esp)
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    
    if not humanoidRootPart or not humanoid then return end
    
    -- Create a container frame for this player's ESP
    local container = Instance.new("Frame")
    container.Name = player.Name .. "_ESP"
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Size = UDim2.new(0, 200, 0, 70)
    container.Position = UDim2.new(0, 0, 0, 0)
    container.Visible = false
    container.Parent = ESPContainer
    
    -- Box around player (only created if ShowBox is enabled)
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderColor3 = self.Settings.BoxColor
    box.BorderSizePixel = 2
    box.Size = UDim2.new(0, 100, 0, 200)
    box.Position = UDim2.new(0, 0, 0, 0)
    box.Visible = self.Enabled and self.Settings.ShowBox
    box.Parent = container
    
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextColor3 = self:GetPlayerColor(player)
    nameLabel.TextSize = self.Settings.TextSize
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Visible = self.Enabled and self.Settings.ShowName
    nameLabel.Parent = container
    
    -- Health bar background
    local healthBarBg = Instance.new("Frame")
    healthBarBg.Name = "HealthBarBackground"
    healthBarBg.Size = UDim2.new(0, self.Settings.HealthBarSize.X, 0, self.Settings.HealthBarSize.Y)
    healthBarBg.Position = UDim2.new(0.5, -self.Settings.HealthBarSize.X/2, 0, 25)
    healthBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    healthBarBg.BorderSizePixel = 0
    healthBarBg.Visible = self.Enabled and self.Settings.ShowHealth
    healthBarBg.Parent = container
    
    -- Health bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Visible = self.Enabled and self.Settings.ShowHealth
    healthBar.Parent = healthBarBg
    
    -- Weapon label
    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Name = "Weapon"
    weaponLabel.Size = UDim2.new(1, 0, 0, 16)
    weaponLabel.Position = UDim2.new(0, 0, 0, 35)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.TextStrokeTransparency = 0.5
    weaponLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    weaponLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    weaponLabel.TextSize = self.Settings.TextSize - 2
    weaponLabel.Font = Enum.Font.Gotham
    weaponLabel.Visible = self.Enabled and self.Settings.ShowWeapon
    weaponLabel.Parent = container
    
    esp.Container = container
    esp.Box = box
    esp.Label = nameLabel
    esp.HealthBar = healthBar
    esp.HealthBarBackground = healthBarBg
    esp.WeaponLabel = weaponLabel
    esp.Humanoid = humanoid
    esp.HumanoidRootPart = humanoidRootPart
    esp.Character = character
    
    -- Update function
    esp.RenderConnection = RunService.RenderStepped:Connect(function()
        if not self.Enabled or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
            container.Visible = false
            esp.Visible = false
            return
        end
        
        local localPlayer = Players.LocalPlayer
        local localCharacter = localPlayer.Character
        local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        
        if not localRoot then 
            container.Visible = false
            esp.Visible = false
            return 
        end
        
        -- Calculate screen position
        local rootPos = humanoidRootPart.Position
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos + Vector3.new(0, 3.5, 0))
        
        if onScreen then
            container.Visible = self.Enabled
            esp.Visible = self.Enabled
            container.Position = UDim2.new(0, screenPos.X - 100, 0, screenPos.Y - 35)
            
            -- Update box position and size
            if self.Settings.ShowBox then
                local headPos, headOnScreen = Camera:WorldToViewportPoint(character.Head.Position)
                local feetPos, feetOnScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 3, 0))
                
                if headOnScreen and feetOnScreen then
                    local height = math.abs(headPos.Y - feetPos.Y)
                    local width = height / 2
                    box.Size = UDim2.new(0, width, 0, height)
                    box.Position = UDim2.new(0, screenPos.X - width/2, 0, feetPos.Y)
                    box.Visible = self.Enabled and self.Settings.ShowBox
                else
                    box.Visible = false
                end
            end
            
            -- Set player name
            if self.Settings.ShowName then
                nameLabel.Text = player.Name
                nameLabel.TextColor3 = self:GetPlayerColor(player)
                nameLabel.Visible = self.Enabled and self.Settings.ShowName
            else
                nameLabel.Visible = false
            end
            
            -- Update health bar
            if self.Settings.ShowHealth then
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                
                -- Change health bar color based on health
                if healthPercent > 0.7 then
                    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
                elseif healthPercent > 0.3 then
                    healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Yellow
                else
                    healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
                end
                
                healthBarBg.Visible = self.Enabled and self.Settings.ShowHealth
                healthBar.Visible = self.Enabled and self.Settings.ShowHealth
            else
                healthBarBg.Visible = false
                healthBar.Visible = false
            end
            
            -- Update weapon display
            if self.Settings.ShowWeapon then
                local weapon = self:GetEquippedWeapon(character)
                weaponLabel.Text = weapon or "None"
                weaponLabel.Visible = self.Enabled and self.Settings.ShowWeapon
            else
                weaponLabel.Visible = false
            end
        else
            container.Visible = false
            esp.Visible = false
        end
    end)
end

-- Function to toggle ESP
function ESP:Toggle(state)
    self.Enabled = state
    
    -- Update visibility of all ESP elements based on toggle state
    for player, esp in pairs(self.Players) do
        if esp.Container then
            esp.Container.Visible = state and esp.Visible
            
            -- Update individual component visibility
            if esp.Label then
                esp.Label.Visible = state and self.Settings.ShowName and esp.Visible
            end
            if esp.HealthBarBackground then
                esp.HealthBarBackground.Visible = state and self.Settings.ShowHealth and esp.Visible
            end
            if esp.HealthBar then
                esp.HealthBar.Visible = state and self.Settings.ShowHealth and esp.Visible
            end
            if esp.WeaponLabel then
                esp.WeaponLabel.Visible = state and self.Settings.ShowWeapon and esp.Visible
            end
            if esp.Box then
                esp.Box.Visible = state and self.Settings.ShowBox and esp.Visible
            end
        end
    end
end

-- Function to update individual settings
function ESP:UpdateSetting(setting, value)
    if self.Settings[setting] ~= nil then
        self.Settings[setting] = value
        
        -- Only update visibility if ESP is enabled
        if self.Enabled then
            for player, esp in pairs(self.Players) do
                if setting == "ShowName" and esp.Label then
                    esp.Label.Visible = value and esp.Visible
                elseif setting == "ShowHealth" and esp.HealthBarBackground then
                    esp.HealthBarBackground.Visible = value and esp.Visible
                    esp.HealthBar.Visible = value and esp.Visible
                elseif setting == "ShowWeapon" and esp.WeaponLabel then
                    esp.WeaponLabel.Visible = value and esp.Visible
                elseif setting == "ShowBox" and esp.Box then
                    esp.Box.Visible = value and esp.Visible
                elseif setting == "BoxColor" and esp.Box then
                    esp.Box.BorderColor3 = value
                elseif setting == "TeamColor" and esp.Label then
                    esp.Label.TextColor3 = self:GetPlayerColor(player)
                end
            end
        end
    end
end

-- Function to initialize ESP
function ESP:Initialize()
    -- Create ESP for all players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            self:Create(player)
        end
    end
    
    -- Listen for new players
    Players.PlayerAdded:Connect(function(player)
        if player ~= Players.LocalPlayer then
            self:Create(player)
        end
    end)
    
    -- Listen for players leaving
    Players.PlayerRemoving:Connect(function(player)
        local esp = self.Players[player]
        if esp then
            self:RemoveESP(esp)
            self.Players[player] = nil
        end
    end)
end

-- Initialize the ESP
ESP:Initialize()

-- Return the ESP module
return ESP
