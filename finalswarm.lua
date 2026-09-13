-- Final Swarm Utility Script (Clean Core V7 - PC Spacebar Trigger)
-- Tối ưu hóa cho PC/Laptop: Tốc độ quét Max FPS, sử dụng phím Space để Grade
-- Author: MrDon

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Lỗi tải Rayfield UI")
    return 
end

local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local Window = Rayfield:CreateWindow({
   Name = "Final Swarm | Master PC V7",
   LoadingTitle = "Khởi tạo hệ thống PC...",
   LoadingSubtitle = "by MrDon",
   ConfigurationSaving = { Enabled = false }
})

local MoveTab = Window:CreateTab("Movement (Di Chuyển)", 4483362458)
local GradeTab = Window:CreateTab("Auto Grade (Spacebar)", 4483362458)

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
local GradeTolerance = 12 -- Để mức 12 cho PC dễ bắt dính
local ClickCooldown = false

local CachedNeedle = nil
local CachedTarget = nil
local IsNeedleMoving = false

-- ==========================================
-- MOVEMENT MODULE
-- ==========================================
MoveTab:CreateSlider({
   Name = "Tốc độ chạy (CFrame Bypass)", Range = {16, 200}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Flag = "SpeedSlider",
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
-- PC SPACEBAR AUTO GRADE MODULE
-- ==========================================
GradeTab:CreateToggle({
   Name = "Bật Auto Grade (Gõ Space)",
   CurrentValue = false,
   Flag = "AutoGradeFlag",
   Callback = function(Value)
      AutoGrade = Value
      
      if AutoGrade then
         local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
         local lastRotMap = {}
         
         -- 1. QUÉT TÌM GIAO DIỆN (Quét nhanh hơn trên PC: 0.2s/lần)
         task.spawn(function()
            while AutoGrade do
               pcall(function()
                  local foundNeedle = nil
                  local foundTarget = nil
                  
                  for _, gui in pairs(playerGui:GetDescendants()) do
                     if gui:IsA("GuiObject") and gui.Visible and gui.Parent then
                        local r = gui.Rotation
                        local lastR = lastRotMap[gui] or r
                        local diffRot = math.abs(r - lastR)
                        
                        if diffRot > 0.5 and diffRot < 120 then
                           foundNeedle = gui
                           IsNeedleMoving = true
                        end
                        lastRotMap[gui] = r
                     end
                  end
                  
                  if foundNeedle and foundNeedle.Parent then
                     local minigameFrame = foundNeedle.Parent
                     for _, child in pairs(minigameFrame:GetChildren()) do
                        if child ~= foundNeedle and child:IsA("GuiObject") and child.Visible then
                           local isGreen = false
                           if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                              local c = child.ImageColor3
                              if c.G > 0.5 and c.R < 0.5 then isGreen = true end
                           elseif child:IsA("Frame") then
                              local c = child.BackgroundColor3
                              if c.G > 0.5 and c.R < 0.5 then isGreen = true end
                           end
                           
                           if isGreen then foundTarget = child; break end
                        end
                     end
                  end
                  
                  CachedNeedle = foundNeedle
                  CachedTarget = foundTarget
               end)
               task.wait(0.2) -- PC gánh tốt, quét liên tục 0.2s
            end
         end)

         -- 2. LUỒNG BẤM TỰ ĐỘNG BẰNG PHÍM SPACE
         task.spawn(function()
            while AutoGrade do
               RunService.RenderStepped:Wait() -- Chạy theo FPS của Laptop (cực chuẩn)
               pcall(function()
                  if CachedNeedle and CachedTarget and CachedNeedle.Visible and CachedTarget.Visible and IsNeedleMoving then
                     local needleRot = CachedNeedle.Rotation
                     local targetRot = CachedTarget.Rotation
                     
                     local diff = math.abs(needleRot - targetRot)
                     if diff > 180 then diff = 360 - diff end
                     
                     -- Điều kiện bấm
                     if diff <= GradeTolerance and not ClickCooldown then
                        ClickCooldown = true
                        
                        -- GIẢ LẬP NHẤN PHÍM SPACE (Khoan thủng mọi Anti-Click)
                        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.01)
                        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        
                        -- Đợi 0.3s cho UI reset vạch xanh
                        task.delay(0.3, function() ClickCooldown = false end)
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
   Range = {3, 25}, Increment = 1, Suffix = "Độ", CurrentValue = 12, Flag = "GradeToleranceSlider",
   Callback = function(Value) GradeTolerance = Value end,
})

GradeTab:CreateParagraph({
   Title = "⚡ Nâng cấp PC",
   Content = "Bot hiện tại sử dụng giả lập phím cách (Spacebar). Khi vạch vàng chạm vạch xanh, bot sẽ tự gõ Space siêu tốc."
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

Rayfield:Notify({ Title = "PC Engine V7 Ready", Content = "Đã chuyển sang giả lập Spacebar. Tối đa hóa tốc độ xử lý.", Duration = 4, Image = 4483362458 })
