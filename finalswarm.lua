-- Final Swarm Utility Script (Clean Core V5 - Mobile Lag-Free Edition)
-- Tối ưu hóa CPU điện thoại: Giảm tải lag 90%, chống bấm sai vị trí
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
   Name = "Final Swarm | Core Engine V5",
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
local GradeTolerance = 8 -- Độ lệch góc (Siết chặt để chống bấm ngoài vùng xanh)
local ClickCooldown = false

-- UI Cache Objects (Khóa đối tượng UI để chống lag)
local CachedNeedle = nil
local CachedTarget = nil

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
-- LAG-FREE AUTO GRADE MODULE
-- ==========================================
GradeTab:CreateToggle({
   Name = "Bật Auto Grade (Siêu mượt cho Mobile)",
   CurrentValue = false,
   Flag = "AutoGradeFlag",
   Callback = function(Value)
      AutoGrade = Value
      
      if AutoGrade then
         local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
         
         -- 1. LUỒNG TÌM KIẾM UI (Chạy ngầm 1 giây / 1 lần -> TRIỆT PHÁ LAG)
         task.spawn(function()
            local lastRotMap = {}
            while AutoGrade do
               pcall(function()
                  local foundNeedle = nil
                  local foundTarget = nil
                  
                  for _, gui in pairs(playerGui:GetDescendants()) do
                     if gui:IsA("GuiObject") and gui.Visible then
                        local r = gui.Rotation
                        local lastR = lastRotMap[gui] or r
                        
                        -- Tìm vạch vàng xoay
                        if math.abs(r - lastR) > 0.1 then
                           foundNeedle = gui
                        end
                        lastRotMap[gui] = r
                        
                        -- Tìm vạch xanh
                        if (gui:IsA("ImageLabel") or gui:IsA("ImageButton")) and gui.ImageColor3.G > 0.6 and gui.ImageColor3.R < 0.6 then
                           foundTarget = gui
                        elseif gui:IsA("Frame") and gui.BackgroundColor3.G > 0.6 and gui.BackgroundColor3.R < 0.6 then
                           foundTarget = gui
                        end
                     end
                  end
                  
                  CachedNeedle = foundNeedle
                  CachedTarget = foundTarget
               end)
               task.wait(1) -- Quét lại sau mỗi 1 giây để nhẹ máy
            end
         end)

         -- 2. LUỒNG TÍNH TOÁN BẤM THỜI GIAN THỰC (Nhẹ tuyệt đối)
         task.spawn(function()
            while AutoGrade do
               RunService.RenderStepped:Wait()
               pcall(function()
                  if CachedNeedle and CachedTarget and CachedNeedle.Visible and CachedTarget.Visible then
                     local needleRot = CachedNeedle.Rotation
                     local targetRot = CachedTarget.Rotation
                     
                     -- Tính khoảng cách góc chính xác
                     local diff = math.abs(needleRot - targetRot)
                     if diff > 180 then diff = 360 - diff end
                     
                     -- CHỈ BẤM KHI VẠCH VÀNG THỰC SỰ CHUI VÀO VẠCH XANH
                     if diff <= GradeTolerance and not ClickCooldown then
                        ClickCooldown = true
                        
                        local centerX = Cam.ViewportSize.X / 2
                        local centerY = Cam.ViewportSize.Y / 2
                        
                        VIM:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
                        task.wait(0.01)
                        VIM:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
                        
                        -- Đóng băng 0.15s cho vạch xanh nhảy vị trí mới
                        task.delay(0.15, function() ClickCooldown = false end)
                     end
                  end
               end)
            end
         end)
      else
         CachedNeedle = nil
         CachedTarget = nil
      end
   end,
})

GradeTab:CreateSlider({
   Name = "Độ chính xác vùng xanh (Tolerance)", 
   Range = {3, 20}, Increment = 1, Suffix = "Độ", CurrentValue = 8, Flag = "GradeToleranceSlider",
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

Rayfield:Notify({ Title = "V5 Optimization Ready", Content = "Đã tối ưu hóa CPU cho điện thoại yếu. Không lag, không bấm nhầm.", Duration = 4, Image = 4483362458 })
