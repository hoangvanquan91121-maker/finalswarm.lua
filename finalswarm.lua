-- Final Swarm Utility Script (Syntax Fixed)
-- Compatible with Delta Executor
-- Author: MrDon

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local VirtualUser = game:GetService("VirtualUser")

local Window = Rayfield:CreateWindow({
   Name = "Final Swarm Hub | MrDon",
   LoadingTitle = "System Initializing...",
   LoadingSubtitle = "by MrDon",
   ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Main Features", 4483362458)
local CardTab = Window:CreateTab("Card Settings", 4483362458)
local RerollTab = Window:CreateTab("Auto Reroll & Minigame", 4483362458)

-- ==========================================
-- GLOBAL VARIABLES
-- ==========================================
local AutoAttack = false
local WalkSpeedVal = 16
local ESPEnabled = false

local Flying = false
local FlySpeed = 50
local FlyHeight = 10
local BodyVelocity = nil
local BodyGyro = nil

local AutoSelectCard = false
local CardPriorities = {"damage", "health", "attack"}

local AutoReroll = false
local StopAtStats = {"cấp độ s", "mythic", "legendary", "godly"}

-- Helper: Split string
local function parseWords(str)
   local parsed = {}
   for word in string.gmatch(str, '([^,]+)') do
      local trimmed = word:match("^%s*(.-)%s*$")
      if trimmed and trimmed ~= "" then table.insert(parsed, string.lower(trimmed)) end
   end
   return parsed
end

-- ==========================================
-- AUTO REROLL & RHYTHM MINIGAME
-- ==========================================
RerollTab:CreateInput({
   Name = "Dừng lại khi ra chỉ số (Ngăn cách bằng dấu phẩy)",
   PlaceholderText = "Ví dụ: Cấp độ S, Mythic",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text) 
      StopAtStats = parseWords(Text) 
   end,
})

RerollTab:CreateToggle({
   Name = "Bật Auto Minigame + Quét Chỉ Số",
   CurrentValue = false,
   Flag = "MasterRerollFlag",
   Callback = function(Value)
      AutoReroll = Value
      
      if AutoReroll then
         -- Luồng 1: Quét kiểm tra chỉ số
         task.spawn(function()
            while AutoReroll do
               task.wait(0.5)
               pcall(function()
                  local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
                  if not playerGui then return end
                  
                  local shouldStop = false
                  local function checkForTargetStats(node)
                     for _, child in pairs(node:GetChildren()) do
                        if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Visible then
                           local text = string.lower(child.Text)
                           for _, target in ipairs(StopAtStats) do
                              if string.find(text, target) then
                                 shouldStop = true
                                 return
                              end
                           end
                        end
                        if child:GetChildren() and #child:GetChildren() > 0 then
                           checkForTargetStats(child)
                        end
                     end
                  end

                  checkForTargetStats(playerGui)

                  if shouldStop then
                     AutoReroll = false 
                     Rayfield:Notify({
                        Title = "Hệ Thống Đã Dừng!", 
                        Content = "Phát hiện chỉ số mục tiêu. Đã ngừng click.", 
                        Duration = 10
                     })
                  end
               end)
            end
         end)
         
         -- Luồng 2: Spam Click chơi Rhythm Minigame
         task.spawn(function()
            while AutoReroll do
               task.wait(0.05) 
               pcall(function()
                  VirtualUser:Button1Down(Vector2.new(0,0))
                  task.wait(0.01)
                  VirtualUser:Button1Up(Vector2.new(0,0))
               end)
            end
         end)
      end
   end,
})

-- ==========================================
-- CARD SELECTOR SYSTEM
-- ==========================================
CardTab:CreateInput({
   Name = "Priority Cards (Ngăn cách bằng dấu phẩy)",
   PlaceholderText = "Ví dụ: Damage, Health",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text) 
      CardPriorities = parseWords(Text) 
   end,
})

CardTab:CreateToggle({
   Name = "Auto Select Priority Cards",
   CurrentValue = false,
   Flag = "AutoCardFlag",
   Callback = function(Value)
      AutoSelectCard = Value
      task.spawn(function()
         while AutoSelectCard do
            task.wait(1.5)
            pcall(function()
               local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
               if not playerGui then return end
               local function scanForCards(guiNode)
                  for _, child in pairs(guiNode:GetChildren()) do
                     if child:IsA("GuiButton") and child.Visible then
                        local textToMatch = child.Name
                        if child:IsA("TextButton") then textToMatch = textToMatch .. " " .. child.Text end
                        for _, subChild in pairs(child:GetDescendants()) do
                           if subChild:IsA("TextLabel") or subChild:IsA("TextButton") then
                              textToMatch = textToMatch .. " " .. subChild.Text
                           end
                        end
                        textToMatch = string.lower(textToMatch)
                        for _, priority in ipairs(CardPriorities) do
                           if string.find(textToMatch, priority) then
                              if getconnections then
                                 for _, connection in pairs(getconnections(child.MouseButton1Click)) do 
                                    connection:Fire() 
                                 end
                              end
                              return true
                           end
                        end
                     end
                     if child:GetChildren() and #child:GetChildren() > 0 then
                        if scanForCards(child) then return true end
                     end
                  end
                  return false
               end
               scanForCards(playerGui)
            end)
         end
      end)
   end,
})

-- ==========================================
-- COMBAT, MOVEMENT & ESP
-- ==========================================
MainTab:CreateToggle({
   Name = "Auto Attack / Auto Hit",
   CurrentValue = false,
   Flag = "AutoAttackFlag",
   Callback = function(Value)
      AutoAttack = Value
      task.spawn(function()
         while AutoAttack do
            task.wait(0.1)
            pcall(function()
               local tool = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
               if tool then tool:Activate() end
            end)
         end
      end)
   end,
})

MainTab:CreateSlider({
   Name = "WalkSpeed Modifier", 
   Range = {16, 100}, 
   Increment = 1, 
   Suffix = "Speed", 
   CurrentValue = 16, 
   Flag = "SpeedSlider",
   Callback = function(Value) 
      WalkSpeedVal = Value 
      pcall(function() 
         game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = WalkSpeedVal 
      end) 
   end,
})

MainTab:CreateToggle({
   Name = "Mob ESP (Highlights)",
   CurrentValue = false,
   Flag = "ESPFlag",
   Callback = function(Value)
      ESPEnabled = Value
      task.spawn(function()
         while ESPEnabled do
            task.wait(1)
            pcall(function()
               for _, v in pairs(workspace:GetChildren()) do
                  if v:FindFirstChild("Humanoid") and v ~= game.Players.LocalPlayer.Character then
                     if not v:FindFirstChild("Highlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "Highlight"
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.Parent = v
                     end
                  end
               end
            end)
         end
         if not ESPEnabled then
            for _, v in pairs(workspace:GetChildren()) do 
               if v:FindFirstChild("Highlight") then 
                  v.Highlight:Destroy() 
               end 
            end
         end
      end)
   end,
})

-- ==========================================
-- FLY SYSTEM
-- ==========================================
MainTab:CreateToggle({
   Name = "Enable Fly",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      Flying = Value
      local player = game.Players.LocalPlayer
      local character = player.Character or player.CharacterAdded:Wait()
      local root = character:WaitForChild("HumanoidRootPart")
      
      if Flying then
         BodyVelocity = Instance.new("BodyVelocity")
         BodyGyro = Instance.new("BodyGyro")
         BodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
         BodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
         BodyVelocity.Parent = root
         BodyGyro.Parent = root
         
         task.spawn(function()
            while Flying do
               task.wait()
               pcall(function()
                  local camera = workspace.CurrentCamera
                  local moveDir = character.Humanoid.MoveDirection
                  BodyGyro.CFrame = camera.CFrame
                  if moveDir.Magnitude > 0 then
                     BodyVelocity.Velocity = (moveDir * FlySpeed) + Vector3.new(0, FlyHeight, 0)
                  else
                     BodyVelocity.Velocity = Vector3.new(0, FlyHeight, 0)
                  end
               end)
            end
         end)
      else
         if BodyVelocity then BodyVelocity:Destroy() end
         if BodyGyro then BodyGyro:Destroy() end
      end
   end,
})

MainTab:CreateSlider({ 
   Name = "Fly Speed", 
   Range = {10, 200}, 
   Increment = 5, 
   Suffix = "Speed", 
   CurrentValue = 50, 
   Flag = "FlySpeedSlider", 
   Callback = function(Value) 
      FlySpeed = Value 
   end 
})

MainTab:CreateSlider({ 
   Name = "Fly Altitude / Lift", 
   Range = {-50, 100}, 
   Increment = 5, 
   Suffix = "Height", 
   CurrentValue = 10, 
   Flag = "FlyHeightSlider", 
   Callback = function(Value) 
      FlyHeight = Value 
   end 
})

game.Players.LocalPlayer.CharacterAdded:Connect(function(char)
   char:WaitForChild("Humanoid").WalkSpeed = WalkSpeedVal
   Flying = false
end)

Rayfield:Notify({
   Title = "System Ready",
   Content = "Đã khắc phục lỗi cú pháp. Hệ thống trực tuyến.",
   Duration = 4,
   Image = 4483362458,
})
