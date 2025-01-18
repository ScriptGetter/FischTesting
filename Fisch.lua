-- References to the UI components
local screenGui = script.Parent
local textLabel = screenGui:WaitForChild("TextLabel")

-- Initial Text
textLabel.Text = "Press RightShift"

-- Function to handle RightShift key press
local function onKeyPress(input, gameProcessed)
    if gameProcessed then return end -- Ignore if the input is already processed by the game

    if input.KeyCode == Enum.KeyCode.RightShift then
        -- Toggle the message
        if textLabel.Text == "Press RightShift" then
            textLabel.Text = "RightShift Pressed!"
        else
            textLabel.Text = "Press RightShift"
        end
    end
end

-- Connect the function to listen for the key press
game:GetService("UserInputService").InputBegan:Connect(onKeyPress)

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

local Window = OrionLib:MakeWindow({Name = "Approved Hub | Version 3.208", HidePremium = false, IntroText = "Fisch", SaveConfig = true, ConfigFolder = "OrionTest"})

local Tab = Window:MakeTab({
	Name = "📃UPDATE LOG📃",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local Section = Tab:AddSection({
	Name = "LATEST UPDATE 1/8/25"
})

Tab:AddButton({
	Name = "ADDED GRAND REEF",
	Callback = function()
      		print("button pressed")
  	end    
})

Tab:AddButton({
	Name = "HEAVENS ROD QUEST FIX",
	Callback = function()
      		print("button pressed")
  	end    
})

Tab:AddButton({
	Name = "This is a test.",
	Callback = function()
      		print("button pressed")
  	end    
})

local Tab = Window:MakeTab({
	Name = "Main",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

-- Configuration variables
local config = {
    fpsCap = 9999,
    disableChat = false,            -- Set to true to hide the chat
    enableBigButton = false,        -- Set to true to enlarge the button in the shake UI
    bigButtonScaleFactor = 2,      -- Scale factor for big button size
    shakeSpeed = 0.05,             -- Lower value means faster shake (e.g., 0.05 for fast, 0.1 for normal)
    FreezeWhileFishing = true      -- Set to true to freeze your character while fishing
}

-- Services
local players = game:GetService("Players")
local vim = game:GetService("VirtualInputManager")
local run_service = game:GetService("RunService")
local replicated_storage = game:GetService("ReplicatedStorage")
local localplayer = players.LocalPlayer
local playergui = localplayer.PlayerGui
local StarterGui = game:GetService("StarterGui")

-- Set FPS cap
setfpscap(config.fpsCap)

-- Disable chat if the option is enabled in config
if config.disableChat then
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
end

-- Utility functions
local utility = {blacklisted_attachments = {"bob", "bodyweld"}}
do
    function utility.simulate_click(x, y, mb)
        vim:SendMouseButtonEvent(x, y, (mb - 1), true, game, 1)
        vim:SendMouseButtonEvent(x, y, (mb - 1), false, game, 1)
    end

    function utility.move_fix(bobber)
        for _, value in ipairs(bobber:GetDescendants()) do
            if value:IsA("Attachment") and table.find(utility.blacklisted_attachments, value.Name) then
                value:Destroy()
            end
        end
    end
end

-- Fishing system
local farm = {running = false}
function farm.find_rod()
    local character = localplayer.Character
    if not character then return nil end

    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:find("rod") or tool.Name:find("Rod")) then
            return tool
        end
    end
    return nil
end

function farm.freeze_character(freeze)
    local character = localplayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = freeze and 0 or 16  -- Default WalkSpeed
            humanoid.JumpPower = freeze and 0 or 50  -- Default JumpPower
        end
    end
end

function farm.cast()
    local rod = farm.find_rod()
    if not rod then return end

    local args = { [1] = 100, [2] = 1 }
    rod.events.cast:FireServer(unpack(args))
end

function farm.shake()
    local shake_ui = playergui:FindFirstChild("shakeui")
    if shake_ui then
        local safezone = shake_ui:FindFirstChild("safezone")
        local button = safezone and safezone:FindFirstChild("button")

        if button and button.Visible then
            if config.enableBigButton then
                button.Size = UDim2.new(config.bigButtonScaleFactor, 0, config.bigButtonScaleFactor, 0)
            else
                button.Size = UDim2.new(1, 0, 1, 0)  -- Reset to default size
            end

            utility.simulate_click(
                button.AbsolutePosition.X + button.AbsoluteSize.X / 2,
                button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2,
                1
            )
        end
    end
end

function farm.reel()
    local reel_ui = playergui:FindFirstChild("reel")
    if not reel_ui then return end

    local reel_bar = reel_ui:FindFirstChild("bar")
    if not reel_bar then return end

    local reel_client = reel_bar:FindFirstChild("reel")
    if not reel_client then return end

    if reel_client.Disabled then
        reel_client.Disabled = false
    end

    local update_colors = getsenv(reel_client).UpdateColors
    if update_colors then
        setupvalue(update_colors, 1, 100)
        replicated_storage.events.reelfinished:FireServer(getupvalue(update_colors, 1), true)
    end
end

-- Main loop
function farm.start()
    farm.running = true
    while farm.running do
        task.wait(config.shakeSpeed)
        local rod = farm.find_rod()
        if rod then
            if config.FreezeWhileFishing then
                farm.freeze_character(true)
            end
            farm.cast()
            farm.shake()
            farm.reel()
        else
            farm.freeze_character(false)
        end
    end
end

function farm.stop()
    farm.running = false
    farm.freeze_character(false) -- Unfreeze character when stopping
end

-- Toggle UI Button
Tab:AddToggle({
    Name = "Auto Fish",
    Default = false,
    Callback = function(Value)
        if Value then
            -- Start fishing system
            farm.start()
        else
            -- Stop fishing system
            farm.stop()
        end
        print("Fishing system is now " .. (Value and "ON" or "OFF"))
    end
})


-- Get all players in the game (excluding the local player)
local players = {}
for _, player in ipairs(game.Players:GetPlayers()) do
    if player.Name ~= game.Players.LocalPlayer.Name then
        table.insert(players, player.Name)
    end
end

-- Add the dropdown to select a player
local selectedPlayerName = players[1] or "1"  -- Default selection
Tab:AddDropdown({
    Name = "Select Player to Teleport To",
    Default = selectedPlayerName, -- Set the first player by default, or "1" if no players found
    Options = players,
    Callback = function(value)
        -- Store the selected player
        selectedPlayerName = value
        print("Selected Player:", selectedPlayerName)
    end
})

-- Add the button that will teleport the player to the selected player
Tab:AddButton({
    Name = "Teleport to Selected Player",
    Callback = function()
        local player = game.Players.LocalPlayer
        local targetPlayer = game.Players:FindFirstChild(selectedPlayerName)

        -- Ensure the target player is valid and has a character with HumanoidRootPart
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = targetPlayer.Character.HumanoidRootPart.CFrame
            local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            
            -- If the local player has a HumanoidRootPart, teleport them
            if rootPart then
                -- Teleport the player to the selected player's position
                rootPart.CFrame = targetPosition
                print("Teleported to:", selectedPlayerName)
            else
                print("HumanoidRootPart not found in your character.")
            end
        else
            print("Target player not found or their character is not loaded.")
        end
    end    
})


local Tab = Window:MakeTab({
	Name = "Event",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

Tab:AddButton({
    Name = "Grand Reef",
    Callback = function()
        local teleportCoordinates = Vector3.new(-3530, 130, 550)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

local Tab = Window:MakeTab({
	Name = "Islands",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

Tab:AddButton({
    Name = "Moosewood",
    Callback = function()
        local teleportCoordinates = Vector3.new(400, 135, 250)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Mangrove Swamp",
    Callback = function()
        local teleportCoordinates = Vector3.new(2420, 135, -750)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Roslit Bay",
    Callback = function()
        local teleportCoordinates = Vector3.new(-1600, 130, 500)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Snowcap Island",
    Callback = function()
        local teleportCoordinates = Vector3.new(2625, 135, 2370)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Statue of Sovereignty",
    Callback = function()
        local teleportCoordinates = Vector3.new(35, 135, -1010)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Sunstone Island",
    Callback = function()
        local teleportCoordinates = Vector3.new(-870, 135, -1100)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Terrapin Island",
    Callback = function()
        local teleportCoordinates = Vector3.new(-95, 130, 1875)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Harvesters Spike",
    Callback = function()
        local teleportCoordinates = Vector3.new(-1260, 135, 1550)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "The Arch",
    Callback = function()
        local teleportCoordinates = Vector3.new(1100, 130, -1250)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Birch Cay",
    Callback = function()
        local teleportCoordinates = Vector3.new(1650, 130, -2350)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Haddock Rock",
    Callback = function()
        local teleportCoordinates = Vector3.new(-500, 125, -505)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Earmark Island",
    Callback = function()
        local teleportCoordinates = Vector3.new(1200, 130, 530)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Desolate Deep",
    Callback = function()
        local teleportCoordinates = Vector3.new(-800, 130, -3100)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Forsaken Shore",
    Callback = function()
        local teleportCoordinates = Vector3.new(-2750, 130, 1450)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Archeological Site",
    Callback = function()
        local teleportCoordinates = Vector3.new(4050, 130, 50)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Ancient Isle",
    Callback = function()
        local teleportCoordinates = Vector3.new(6000, 200, 300)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Northern Expedition",
    Callback = function()
        local teleportCoordinates = Vector3.new(-1750, 130, 3750)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

local Tab = Window:MakeTab({
	Name = "📜 Quest",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local Section = Tab:AddSection({
	Name = "This is a Heaven's Rod Quest (FIXING)"
})

Tab:AddButton({
    Name = "Blue Energy Crystal",
    Callback = function()
        local teleportCoordinates = Vector3.new(20125, 210, 5450)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Blue Energy Crystal:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Yellow Energy Crystal",
    Callback = function()
        local teleportCoordinates = Vector3.new(19500, 335, 5555)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Yellow Energy Crystal:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Green Energy Crystal",
    Callback = function()
        local teleportCoordinates = Vector3.new(19875, 450, 5555)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Green Energy Crystal:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Red Energy Crystal",
    Callback = function()
        local teleportCoordinates = Vector3.new(19920, 1135, 5355)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Red Energy Crystal:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Button #1 (Moosewood)",
    Callback = function()
        local teleportCoordinates = Vector3.new(400, 135, 265)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Button #1 (Moosewood):", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Button #2 (Ancient Isles)",
    Callback = function()
        local teleportCoordinates = Vector3.new(5505, 145, -315)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Button #2 (Ancient Isles):", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Button #3 (Snowcap Island)",
    Callback = function()
        local teleportCoordinates = Vector3.new(2930, 280, 2595)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Button #3 (Snowcap Island):", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Button #4 (Roslit Bay)",
    Callback = function()
        local teleportCoordinates = Vector3.new(-1715, 150, 735)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Button #4 (Roslit Bay):", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Button #5 (Forsaken Shores)",
    Callback = function()
        local teleportCoordinates = Vector3.new(-2565, 180, 1355)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Button #5 (Forsaken Shores):", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Avalanche Totem (Yellow Energy Crystal)",
    Callback = function()
        local teleportCoordinates = Vector3.new(19710, 470, 6060)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Avalanche Totem:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab = Window:MakeTab({
	Name = "Totems",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

Tab:AddButton({
    Name = "Sundial Totem - Cost 2,000",
    Callback = function()
        local teleportCoordinates = Vector3.new(-1215, 195, -1040)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Avalanche Totem:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Aurora Totem - Cost 500,000",
    Callback = function()
        local teleportCoordinates = Vector3.new(-1808, -135, -3285)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Avalanche Totem:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Tempest Totem - Cost 2,000",
    Callback = function()
        local teleportCoordinates = Vector3.new(35, 132, 1944)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Avalanche Totem:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Windset Totem - Cost 2,000",
    Callback = function()
        local teleportCoordinates = Vector3.new(2845, 180, 2700)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Avalanche Totem:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Smokescreen Totem - Cost 2,000",
    Callback = function()
        local teleportCoordinates = Vector3.new(2790, 140, -626)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Avalanche Totem:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Meteorite Totem - Cost 75,000",
    Callback = function()
        local teleportCoordinates = Vector3.new(1945, 275, 230)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Avalanche Totem:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Eclipse Totem - Cost 250,000",
    Callback = function()
        local teleportCoordinates = Vector3.new(5940, 265, 900)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Avalanche Totem:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

local Section = Tab:AddSection({
	Name = "Relics/Enchant"
})

Tab:AddButton({
    Name = "Go To Merlin (Buy Relic)",
    Callback = function()
        local teleportCoordinates = Vector3.new(-942, 223, -988)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Avalanche Totem:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})

Tab:AddButton({
    Name = "Enchant Area",
    Callback = function()
        local teleportCoordinates = Vector3.new(30, 144, -1025)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(teleportCoordinates)
            print("Teleported to Avalanche Totem:", teleportCoordinates)
        else
            print("HumanoidRootPart not found, teleport failed.")
        end
    end    
})
