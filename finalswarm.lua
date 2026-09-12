-- Final Swarm Utility Script (FINAL V6 - All Integrated)
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
local FlySpeed, FlyHeight = 50, 10
local BodyVelocity, BodyGyro = nil, nil

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
-- AUTO REROLL & RHYTHM MINIGAME (INTEGRATED)
-- ==========================================
RerollTab:CreateInput({
   Name = "Dừng lại khi ra chỉ số (Ngăn cách bằng dấu phẩy)",
   PlaceholderText = "Ví dụ: Cấp độ S, Mythic",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text) StopAtStats = parseWords(Text) end,
})

RerollTab:CreateToggle({
   Name = "Bật Auto Minigame + Quét Chỉ Số",
   CurrentValue = false,
   Flag = "MasterRerollFlag",
   Callback = function(Value)
      AutoReroll = Value
      
      if AutoReroll then
         -- Luồng 1: Quét kiểm tra chỉ số (Chạy mỗi 0.5s)
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
                     AutoReroll = false -- Tắt toàn bộ hệ thống Minigame
                     Rayfield:Notify({
                        Title = "Hệ Thống Đã Dừng!", 
                        Content = "Phát hiện chỉ số mục tiêu. Đã ngừng click.", 
                        Duration = 10
                     })
                  end
               end)
            end
         end)
         
         -- Luồng
