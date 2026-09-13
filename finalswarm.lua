-- Final Swarm Utility Script (Clean Core V3)
-- Integrated Precision Auto Grade Minigame Bot
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
   Name = "Final Swarm | Master Engine",
   LoadingTitle = "Khởi tạo hệ thống cốt lõi...",
   LoadingSubtitle = "by MrDon",
   ConfigurationSaving = { Enabled = false }
})

local MoveTab = Window:CreateTab("Movement (Di Chuyển)", 4483362458)
local GradeTab = Window:CreateTab("Auto Grade Minigame", 4483362458)

-- ==========================================
-- GLOBAL VARIABLES
-- ==========================================
local WalkSpeedVal = 16
local Flying = false
local FlySpeed = 50

local AutoPatrol = false
local PatrolRadius = 30
local PatrolOrigin = Vector3.new(0,0,0)
local PatrolAngle = 0

-- Minigame Variables
local AutoGrade = false
local GradeTolerance = 12 -- Độ lệch góc cho phép (Độ)
local ClickCooldown = false
local LastNeedleRotation = 0

-- ==========================================
-- MOVEMENT UI ELEMENTS
-- ==========================================
MoveTab:CreateSlider({
   Name = "Tốc độ chạy (CFrame Bypass)", 
   Range = {16, 200}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Flag = "SpeedSlider",
   Callback = function(Value) WalkSpeedVal = Value end,
})

MoveTab:CreateToggle({
   Name = "Bật Fly (Lơ lửng & Lướt)", CurrentValue = false, Flag = "FlyToggle",
   Callback = function(Value) 
      Flying = Value 
      if not Flying and AutoPatrol then Window.Flags["PatrolToggle"]:Set(false) end
   end,
})

MoveTab:CreateSlider({ 
   Name = "Tốc độ Bay (Fly Speed)", Range = {10, 200}, Increment = 5, Suffix = "Speed", CurrentValue = 50, Flag = "FlySpeedSlider", 
   Callback = function(Value) FlySpeed = Value end 
})

MoveTab:CreateDivider()

MoveTab:CreateToggle({
   Name = "Auto Patrol (Bay vòng tròn quanh tâm)", CurrentValue = false, Flag = "PatrolToggle",
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

MoveTab:CreateSlider({ 
   Name = "Bán kính vòng tròn (Radius)", Range = {10, 300}, Increment = 5, Suffix = "Studs", CurrentValue = 30, Flag = "PatrolRadiusSlider", 
   Callback = function(Value) PatrolRadius = Value end 
})

-- ==========================================
-- AUTO GRADE MINIGAME MODULE
-- ==========================================
GradeTab:CreateToggle({
   Name = "Bật Auto Grade (Tự động bấm Perfect)",
   CurrentValue = false,
   Flag = "AutoGradeFlag",
   Callback = function(Value)
      AutoGrade = Value
      
      if AutoGrade then
         local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
         
         -- Lệnh chạm thật vào tâm màn hình
         local function triggerTap()
            if ClickCooldown then return end
            ClickCooldown = true
            
            local centerX = Cam.ViewportSize.X / 2
            local centerY = Cam.ViewportSize.Y / 2
            
            VIM:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
            task.wait(0.01)
            VIM:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
            
            -- Khóa click 0.2s để thanh Xanh nhảy vị trí mới mà không bị spam trừ tim
            task.delay(0.2, function()
               ClickCooldown = false
            end)
         end

         task.spawn(function()
            while AutoGrade do
               RunService.RenderStepped:Wait() -- Quét khớp từng khung hình
               pcall(function()
                  local yellowNeedle = nil
                  local greenTarget = nil
                  
                  -- Quét toàn bộ giao diện minigame trên màn hình
                  for _, gui in pairs(playerGui:GetDescendants()) do
                     if gui:IsA("GuiObject") and gui.Visible then
                        
                        -- 1. Tìm vạch Vàng (vật thể có Rotation nhảy liên tục giữa các frame)
                        local currentRot = gui.Rotation
                        local rotDiff = math.abs(currentRot - LastNeedleRotation)
                        
                        if rotDiff > 0.2 and rotDiff < 40 then
                           yellowNeedle = gui
                        end
                        
                        -- 2. Tìm vạch Xanh (có màu đại diện Xanh Lá hoặc nằm trong cụm đĩa quay)
                        local isGreen = false
                        if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
                           local c = gui.ImageColor3
                           if c.G > 0.6 and c.R < 0.6 then isGreen = true end
                        elseif gui:IsA("Frame") then
                           local c = gui.BackgroundColor3
                           if c.G > 0.6 and c.R < 0.6 then isGreen = true end
                        end
                        
                        if isGreen then
                           greenTarget = gui
                        end
                     end
                  end
                  
                  -- Cập nhật góc quay vạch vàng cho frame sau
                  if yellowNeedle then
                     LastNeedleRotation = yellowNeedle.Rotation
                  end
                  
                  -- 3. Xử lý va chạm góc giữa Vàng và Xanh
                  if yellowNeedle and greenTarget then
                     local needleAngle = yellowNeedle.Rotation
                     local targetAngle = greenTarget.Rotation
                     
                     -- Tính khoảng cách góc ngắn nhất
                     local angleDiff = math.abs(needleAngle - targetAngle)
                     if angleDiff > 180 then angleDiff = 360 - angleDiff end
                     
                     -- Khi vạch vàng tiến vào phạm vi của thanh xanh -> BẤM
                     if angleDiff <= GradeTolerance then
                        triggerTap()
                     end
                  end
               end)
            end
         end)
      end
   end,
})

GradeTab:CreateSlider({
   Name = "Độ nhạy bấm (Tolerance)", 
   Range = {3, 30}, Increment = 1, Suffix = "Độ", CurrentValue = 12, Flag = "GradeToleranceSlider",
   Callback = function(Value) GradeTolerance = Value end,
})

GradeTab:CreateParagraph({
   Title = "💡 Mẹo Auto Grade",
   Content = "• Nếu bot bấm hơi SỚM (chưa tới vạch xanh đã bấm), hãy GIẢM thanh 'Độ nhạy' xuống (ví dụ: 6-8 độ).\n• Nếu bot bấm MUỘN (vạch vàng đi qua rồi mới bấm), hãy TĂNG thanh 'Độ nhạy' lên (ví dụ: 15-18 độ)."
})

-- ==========================================
-- CORE MOVEMENT ENGINE LOOP
-- ==========================================
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
            local nextAngle = PatrolAngle + 0.1
            local lookX = PatrolOrigin.X + PatrolRadius * math.cos(nextAngle)
            local lookZ = PatrolOrigin.Z + PatrolRadius * math.sin(nextAngle)
            
            if hum.Jump then PatrolOrigin = PatrolOrigin + Vector3.new(0, FlySpeed * deltaTime, 0) end
            root.CFrame = CFrame.new(Vector3.new(targetX, PatrolOrigin.Y, targetZ), Vector3.new(lookX, PatrolOrigin.Y, lookZ))
         else
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then root.CFrame = root.CFrame + (moveDir * FlySpeed * deltaTime) end
            if hum.Jump then root.CFrame = root.CFrame + Vector3.new(0, FlySpeed * deltaTime, 0) end
         end
      else
         if WalkSpeedVal > 16 then
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then root.CFrame = root.CFrame + (moveDir * (WalkSpeedVal - 16) * deltaTime) end
         end
      end
   end)
end)

game.Players.LocalPlayer.CharacterAdded:Connect(function()
   if Flying then Window.Flags["FlyToggle"]:Set(false) end
   if AutoPatrol then Window.Flags["PatrolToggle"]:Set(false) end
end)

Rayfield:Notify({ Title = "Auto Grade Engine Ready", Content = "Đã tối ưu hóa thuật toán nhận diện vòng tròn xoay.", Duration = 4, Image = 4483362458 })
