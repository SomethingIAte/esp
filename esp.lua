-- ESP Module for xsx UI Library
local ESP = {
    Enabled = false,
    Players = {},
    Settings = {
        ShowName = true,
        ShowHealth = true,
        ShowWeapon = true,
        TeamColor = true,
        MaxDistance = 1000,
        TextSize = 14,
        HealthBarSize = Vector2.new(50, 4)
    }
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local player reference
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Function to create ESP for a player
function ESP:Create(player)
    if self.Players[player] then return end
    
    local esp = {
        Player = player,
        Label = nil,
        HealthBar = nil,
        HealthBarBackground = nil,
        WeaponLabel = nil,
        RenderConnection = nil
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
    
    -- Create main billboard for name and health
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPLabel"
    billboard.Adornee = humanoidRootPart
    billboard.Size = UDim2.new(0, 200, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = self.Settings.MaxDistance
    billboard.Parent = humanoidRootPart
    
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
    nameLabel.Parent = billboard
    
    -- Health bar background
    local healthBarBg = Instance.new("Frame")
    healthBarBg.Name = "HealthBarBackground"
    healthBarBg.Size = UDim2.new(0, self.Settings.HealthBarSize.X, 0, self.Settings.HealthBarSize.Y)
    healthBarBg.Position = UDim2.new(0.5, -self.Settings.HealthBarSize.X/2, 0, 25)
    healthBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    healthBarBg.BorderSizePixel = 0
    healthBarBg.Parent = billboard
    
    -- Health bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
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
    weaponLabel.Parent = billboard
    
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
            billboard.Enabled = false
            return
        end
        
        local localPlayer = Players.LocalPlayer
        local localCharacter = localPlayer.Character
        local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        
        if not localRoot then return end
        
        -- Update label
        billboard.Enabled = self.Enabled
        
        -- Set player name
        if self.Settings.ShowName then
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = self:GetPlayerColor(player)
            nameLabel.Visible = true
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
            
            healthBarBg.Visible = true
            healthBar.Visible = true
        else
            healthBarBg.Visible = false
            healthBar.Visible = false
        end
        
        -- Update weapon display
        if self.Settings.ShowWeapon then
            local weapon = self:GetEquippedWeapon(character)
            weaponLabel.Text = weapon or "None"
            weaponLabel.Visible = true
        else
            weaponLabel.Visible = false
        end
    end)
end

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

-- Function to remove ESP
function ESP:RemoveESP(esp)
    if esp.Label then esp.Label.Parent:Destroy() end
    if esp.RenderConnection then esp.RenderConnection:Disconnect() end
    
    esp.Label = nil
    esp.HealthBar = nil
    esp.HealthBarBackground = nil
    esp.WeaponLabel = nil
    esp.RenderConnection = nil
end

-- Function to get player color
function ESP:GetPlayerColor(player)
    if self.Settings.TeamColor and player.Team then
        return player.Team.TeamColor.Color
    else
        return Color3.fromRGB(255, 255, 255)
    end
end

-- Function to toggle ESP
function ESP:Toggle(state)
    self.Enabled = state
    for player, esp in pairs(self.Players) do
        if esp.Label then
            esp.Label.Parent.Enabled = state
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
