-- Final Swarm Utility Script (Concentric Rhythm Bot V13)
-- Tối ưu hóa: Bỏ quét màu, đối chiếu tọa độ tâm xoay chuẩn xác
-- Author: MrDon

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    game.StarterGui:SetCore("SendNotification", { Title = "Lỗi Mạng", Text = "Vui lòng bật VPN (1.1.1.1) rồi chạy lại.", Duration = 10 })
    return 
end

local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Cam = workspace.CurrentCamera

local Window = Rayfield:CreateWindow({
   Name = "Final Swarm Hub | MrDon",
   LoadingTitle = "System Initializing...",
   LoadingSubtitle = "by MrDon",
   ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Main Features", 4483362458)
local CardTab = Window:CreateTab("Card Settings", 4483362458)
local MinigameTab = Window:CreateTab("Rhythm Minigame", 4483362458)

-- ==========================================
-- GLOBAL VARIABLES
-- ==========================================
local AutoAttack = false
local ESPEnabled = false
local WalkSpeedVal = 16

local Flying = false
local FlySpeed = 50
local FlyHeight = 0 
local AutoPatrol = false
local PatrolRadius = 50
local PatrolOrigin = Vector3.new(0,0,0)
local PatrolAngle = 0

local AutoSelectCard = false
local CardPriorities = {"damage", "health", "attack"}

-- Minigame Variables
local AutoMinigame = false
local MinigameTolerance = 10
local ClickCooldown = false
local lastRots = {}

local function parseWords(str)
   local parsed = {}
   for word in string.gmatch(str, '([^,]+)') do
      local trimmed = word:match("^%s*(.-)%s*$")
      if trimmed and trimmed ~= "" then table.insert(parsed, string.lower(trimmed)) end
   end
   return parsed
end

-- ==========================================
-- RHYTHM TIMING BOT (CONCENTRIC MATCHING)
-- ==========================================
MinigameTab:CreateToggle({
   Name = "Bật Auto Minigame (Click tới khi hết tim)",
   CurrentValue = false,
   Flag = "MinigameFlag",
   Callback = function(Value)
      AutoMinigame = Value
      
      if AutoMinigame then
         local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
         
         local function simulateCenterClick()
            if ClickCooldown then return end
            ClickCooldown = true
            
            -- Chạm tàng hình vào giữa màn hình
            local centerX = Cam.ViewportSize.X / 2
            local centerY = Cam.ViewportSize.Y / 2
            
            VIM:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
            task.wait(0.02)
            VIM:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
            
            -- Đóng băng nhấp chuột 0.3s để tránh spam trừ máu oan
            task.delay(0.3, function() ClickCooldown = false end)
         end

         task.spawn(function()
            while AutoMinigame do
               task.wait() -- Chạy mỗi frame
               pcall(function()
                  local activeNeedle = nil
                  
                  -- 1. Tìm "Kim" (Vật thể đang xoay liên tục)
                  for _, gui in pairs(playerGui:GetDescendants()) do
                     if gui:IsA("GuiObject") and gui.Visible then
                        local rot = gui.Rotation
                        local lastRot = lastRots[gui] or rot
                        local deltaRot = math.abs(rot - lastRot)
                        
                        -- Nếu góc xoay thay đổi > 0.1 độ mỗi frame -> Nó là cây kim
                        if deltaRot > 0.1 and deltaRot < 45 then
                           activeNeedle = gui
                        end
                        lastRots[gui] = rot
                     end
                  end
                  
                  -- 2. Tìm "Vùng đích" có cùng Tọa độ Tâm với Kim
                  if activeNeedle then
                     local activeTarget = nil
                     
                     for _, gui in pairs(playerGui:GetDescendants()) do
                        if gui:IsA("GuiObject") and gui.Visible and gui ~= activeNeedle then
                           -- Đối chiếu tọa độ tâm: Chênh lệch không quá 2 pixels
                           local dist = (gui.AbsolutePosition - activeNeedle.AbsolutePosition).Magnitude
                           if dist < 2 then
                              local rotDelta = math.abs(gui.Rotation - (lastRots[gui] or gui.Rotation))
                              
                              -- Vùng đích thường đứng im (không xoay liên tục như kim)
                              if rotDelta < 0.1 then
                                 -- Ưu tiên vật thể có Rotation khác 0 (Góc lệch chuẩn của vùng đích)
                                 if gui.Rotation ~= 0 or not activeTarget then
                                    activeTarget = gui
                                 end
                              end
                           end
                        end
                     end
                     
                     -- 3. Tính toán va chạm góc
                     if activeTarget then
                        local diff = math.abs(activeNeedle.Rotation - activeTarget.Rotation)
                        if diff > 180 then diff = 360 - diff end
                        
                        -- Nếu kim đi vào vùng sai số -> CLICK
                        if diff <= MinigameTolerance then
                           simulateCenterClick()
                        end
                     end
                  end
               end)
            end
         end)
      end
   end,
})

MinigameTab:CreateSlider({
   Name = "Sai số bấm sớm/muộn (Tolerance)", 
   Range = {2, 30}, Increment = 1, Suffix = "Độ", CurrentValue = 10, Flag = "ToleranceSlider",
   Callback = function(Value) MinigameTolerance = Value end,
})
-- Lời khuyên: Nếu bot bấm trượt ra ngoài vùng xanh, hãy giảm số này xuống (vd: 5). Nếu nó bấm muộn, tăng lên (vd: 15).

-- ==========================================
-- CARD SELECTOR SYSTEM
-- ==========================================
CardTab:CreateInput({
   Name = "Priority Cards (Ngăn cách dấu phẩy)", PlaceholderText = "Ví dụ: Damage, Health", RemoveTextAfterFocusLost = false,
   Callback = function(Text) CardPriorities = parseWords(Text) end,
})

CardTab:CreateToggle({
   Name = "Auto Select Priority Cards", CurrentValue = false, Flag = "AutoCardFlag",
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
                           if subChild:IsA("TextLabel") or subChild:IsA("TextButton") then textToMatch = textToMatch .. " " .. subChild.Text end
                        end
                        textToMatch = string.lower(textToMatch)
                        for _, priority in ipairs(CardPriorities) do
                           if string.find(textToMatch, priority) then
                              if getconnections then
                                 for _, connection in pairs(getconnections(child.MouseButton1Click)) do connection:Fire() end
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
-- COMBAT, ESP & CORE FEATURES
-- ==========================================
MainTab:CreateToggle({
   Name = "Auto Attack / Auto Hit", CurrentValue = false, Flag = "AutoAttackFlag",
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

MainTab:CreateToggle({
   Name = "Mob ESP (Highlights)", CurrentValue = false, Flag = "ESPFlag",
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
                        hl.Name, hl.FillColor, hl.OutlineColor = "Highlight", Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 255)
                        hl.Parent = v
                     end
                  end
               end
            end)
         end
         if not ESPEnabled then
            for _, v in pairs(workspace:GetChildren()) do if v:FindFirstChild("Highlight") then v.Highlight:Destroy() end end
         end
      end)
   end,
})

-- ==========================================
-- MASTER MOVEMENT ENGINE (CFrame Override)
-- ==========================================
MainTab:CreateSlider({ Name = "Tốc độ chạy (WalkSpeed CFrame)", Range = {16, 200}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Flag = "SpeedSlider", Callback = function(Value) WalkSpeedVal = Value end })
MainTab:CreateToggle({ Name = "Enable Fly (An Toàn Cho Joystick)", CurrentValue = false, Flag = "FlyToggle", Callback = function(Value) Flying = Value end })
MainTab:CreateSlider({ Name = "Tốc độ Bay (Fly Speed)", Range = {10, 200}, Increment = 5, Suffix = "Speed", CurrentValue = 50, Flag = "FlySpeedSlider", Callback = function(Value) FlySpeed = Value end })
MainTab:CreateSlider({ Name = "Tốc độ Nâng/Hạ (Cao độ)", Range = {-50, 50}, Increment = 5, Suffix = "Studs/s", CurrentValue = 0, Flag = "FlyHeightSlider", Callback = function(Value) FlyHeight = Value end })
MainTab:CreateToggle({
   Name = "Auto Patrol (Bay vòng quanh tâm)", CurrentValue = false, Flag = "PatrolToggle",
   Callback = function(Value)
      AutoPatrol = Value
      if AutoPatrol then
         pcall(function()
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
               PatrolOrigin = char.HumanoidRootPart.Position
               PatrolAngle = 0
            end
         end)
      end
   end,
})
MainTab:CreateSlider({ Name = "Patrol Radius (Bán kính)", Range = {10, 500}, Increment = 10, Suffix = "Studs", CurrentValue = 50, Flag = "PatrolRadiusSlider", Callback = function(Value) PatrolRadius = Value end })

RunService.RenderStepped:Connect(function(deltaTime)
   pcall(function()
      local player = game.Players.LocalPlayer
      local char = player.Character
      if not char then return end
      
      local root = char:FindFirstChild("HumanoidRootPart")
      local hum = char:FindFirstChild("Humanoid")
      if not root or not hum then return end

      if Flying then
         root.Velocity = Vector3.new(0, 0, 0)
         if AutoPatrol then
            local angularSpeed = FlySpeed / PatrolRadius
            PatrolAngle = PatrolAngle + (angularSpeed * deltaTime)
            local targetX = PatrolOrigin.X + PatrolRadius * math.cos(PatrolAngle)
            local targetZ = PatrolOrigin.Z + PatrolRadius * math.sin(PatrolAngle)
            local targetPos = Vector3.new(targetX, root.Position.Y, targetZ)
            local nextAngle = PatrolAngle + 0.1
            local lookX = PatrolOrigin.X + PatrolRadius * math.cos(nextAngle)
            local lookZ = PatrolOrigin.Z + PatrolRadius * math.sin(nextAngle)
            local lookPos = Vector3.new(lookX, root.Position.Y, lookZ)
            root.CFrame = CFrame.new(targetPos, lookPos) + Vector3.new(0, FlyHeight * deltaTime, 0)
         else
            local moveDir = hum.MoveDirection
            local currentCFrame = root.CFrame
            if moveDir.Magnitude > 0 then currentCFrame = currentCFrame + (moveDir * FlySpeed * deltaTime) end
            currentCFrame = currentCFrame + Vector3.new(0, FlyHeight * deltaTime, 0)
            root.CFrame = currentCFrame
         end
      else
         if WalkSpeedVal > 16 then
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
               local bonusSpeed = WalkSpeedVal - 16
               root.CFrame = root.CFrame + (moveDir * bonusSpeed * deltaTime)
            end
         end
      end
   end)
end)

Rayfield:Notify({ Title = "Rhythm Engine V13", Content = "Đã thay đổi thuật toán toán học không gian. Không spam nữa.", Duration = 4, Image = 4483362458 })
