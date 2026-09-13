-- Final Swarm Utility Script (Clean Core V6 - Anti-Spam & Parent Validation)
-- Fix triệt để lỗi spam click do nhận diện nhầm chữ/ngọc xanh
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
   Name = "Final Swarm | Core Engine V6",
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
local GradeTolerance = 10
local ClickCooldown = false

local CachedNeedle = nil
local CachedTarget = nil
local IsNeedleMoving = false

-- ==========================================
-- MOVEMENT MODULE
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
   Name = "Auto Patrol (Bay vòng tròn)", CurrentValue = false, Flag = "PatrolToggle",
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
-- ANTI-SPAM AUTO GRADE MODULE
-- ==========================================
GradeTab:CreateToggle({
   Name = "Bật Auto Grade (Anti-Spam Click)",
   CurrentValue = false,
   Flag = "AutoGradeFlag",
   Callback = function(Value)
      AutoGrade = Value
      
      if AutoGrade then
         local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
         local lastRotMap = {}
         
         -- 1. QUÉT TÌM VẬT THỂ MINIGAME CHUẨN (Chạy ngầm 0.5s/lần)
         task.spawn(function()
            while AutoGrade do
               pcall(function()
                  local foundNeedle = nil
                  local foundTarget = nil
                  
                  -- Quét tất cả GUI
                  for _, gui in pairs(playerGui:GetDescendants()) do
                     if gui:IsA("GuiObject") and gui.Visible and gui.Parent then
                        local r = gui.Rotation
                        local lastR = lastRotMap[gui] or r
                        local diffRot = math.abs(r - lastR)
                        
                        -- Vạch vàng phải là vật thể có Rotation thay đổi liên tục
                        if diffRot > 0.5 and diffRot < 120 then
                           foundNeedle = gui
                           IsNeedleMoving = true
                        end
                        lastRotMap[gui] = r
                     end
                  end
                  
                  -- Nếu tìm thấy Vạch Vàng, tìm Vạch Xanh NẰM CÙNG KHUNG MẸ (Parent)
                  if foundNeedle and foundNeedle.Parent then
                     local minigameFrame = foundNeedle.Parent
                     for _, child in pairs(minigameFrame:GetChildren()) do
                        if child ~= foundNeedle and child:IsA("GuiObject") and child.Visible then
                           -- Kiểm tra màu xanh lá cây đại diện cho vạch đích
                           local isGreen = false
                           if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                              local c = child.ImageColor3
                              if c.G > 0.5 and c.R < 0.5 then isGreen = true end
                           elseif child:IsA("Frame") then
                              local c = child.BackgroundColor3
                              if c.G > 0.5 and c.R < 0.5 then isGreen = true end
                           end
                           
                           if isGreen then
                              foundTarget = child
                              break
                           end
                        end
                     end
                  end
                  
                  CachedNeedle = foundNeedle
                  CachedTarget = foundTarget
               end)
               task.wait(0.5)
            end
         end)

         -- 2. LUỒNG BẤM TỰ ĐỘNG (CHỈ BẤM KHI ĐỦ ĐIỀU KIỆN CHÍNH XÁC)
         task.spawn(function()
            while AutoGrade do
               RunService.RenderStepped:Wait()
               pcall(function()
                  if CachedNeedle and CachedTarget and CachedNeedle.Visible and CachedTarget.Visible and IsNeedleMoving then
                     local needleRot = CachedNeedle.Rotation
                     local targetRot = CachedTarget.Rotation
                     
                     local diff = math.abs(needleRot - targetRot)
                     if diff > 180 then diff = 360 - diff end
                     
                     -- Chỉ nhấp khi: Vạch vàng lọt vào vạch xanh AND không trong thời gian chờ (Cooldown)
                     if diff <= GradeTolerance and not ClickCooldown then
                        ClickCooldown = true
                        
                        local centerX = Cam.ViewportSize.X / 2
                        local centerY = Cam.ViewportSize.Y / 2
                        
                        VIM:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                        task.wait(0.01)
                        VIM:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
                        
                        -- Khóa bấm 0.35s để chờ minigame chuyển vạch xanh mới
                        task.delay(0.35, function() 
                           ClickCooldown = false 
                        end)
                     end
                  end
               end)
            end
         end)
      else
         CachedNeedle = nil
         CachedTarget = nil
         IsNeedleMoving = false
      end
   end,
})

GradeTab:CreateSlider({
   Name = "Độ chính xác vùng xanh (Tolerance)", 
   Range = {3, 25}, Increment = 1, Suffix = "Độ", CurrentValue = 10, Flag = "GradeToleranceSlider",
   Callback = function(Value) GradeTolerance = Value end,
})

-- ==========================================
-- CORE MOVEMENT LOOP
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

Rayfield:Notify({ Title = "V6 Anti-Spam Ready", Content = "Đã khóa khung nhận diện. Không còn hiện tượng bấm liên tục.", Duration = 4, Image = 4483362458 })
