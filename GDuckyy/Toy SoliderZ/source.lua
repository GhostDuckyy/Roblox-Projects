--// Check \\--
if (game.PlaceId ~= 12215278065) then return end
if (not game:IsLoaded()) then game.Loaded:Wait() end

if (game:GetService("CoreGui"):FindFirstChild("uwuware")) then
    game:GetService("CoreGui"):FindFirstChild("uwuware"):Destroy()
end

if ( type(getgenv().AutoFarm) == "boolean" and AutoFarm ) then
    AutoFarm = false
end

--// Services \\--
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Stats = LocalPlayer:WaitForChild("Stats")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("ClientServerRemotes")

--// Functions \\--
local function IsBattle()
    local ScreenGui = PlayerGui:WaitForChild("Battle")

    if (ScreenGui and ScreenGui.Enabled) then
        return true
    end
    return false
end

local function StartWave(stage, difficulty)
    local RemoteEvent = Remotes:WaitForChild("StartWave")
    if (stage and difficulty) then
        RemoteEvent:FireServer(tonumber(stage), tostring(difficulty))
    end
end

local function LoadSlot(slot)
    local function InCD()
        local Main = PlayerGui:WaitForChild("Buttons"):WaitForChild("Everything"):WaitForChild("Main")
        local Cooldown = Main:WaitForChild("Left"):WaitForChild("QuickLoad"):WaitForChild("Cooldown"):WaitForChild("TextLabel")

        if (Cooldown and tonumber(Cooldown.ContentText)) then
            return true
        end
        return false
    end

    local RemoteEvent = Remotes:WaitForChild("LoadBuild")

    if (slot) then
        if (InCD()) then
            repeat
                task.wait()
            until (InCD() == false)
        end
        task.wait(.5)
        RemoteEvent:FireServer(tostring(slot))
    end
end

local function GetAllSlots()
    local SaveSlots = Stats:WaitForChild("SaveSlots")
    local Slots = {}

    if (SaveSlots) then
        if (SaveSlots:FindFirstChild("Autosave") and SaveSlots.Autosave:IsA("StringValue")) then
            table.insert(Slots, SaveSlots.Autosave)
        end

        for _,v in pairs(SaveSlots:GetChildren()) do
            if (v:IsA("StringValue") and v.Name ~= "Autosave") then
                table.insert(Slots, v.Name)
            end
        end
    end

    return Slots
end

--// uwuware \\--
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/GhostDuckyy/UI-Libraries/main/uwuware/source.lua"))()
local Window = Library:CreateWindow("GDuckyy Hub")
local Flags = Library.flags

--// Source \\--
getgenv().AutoFarm = false

do -- Main
    Window:AddBox({ text = "Select Wave:", flag = "wave", value = "1" })
    Window:AddList({ text = "Select Difficulty:", flag = "difficulty", value = "Easy", values = {"Easy", "Medium", "Hard", "ToyBreaker"} })
    Window:AddList({ text = "Select Slot:", flag = "slot", value = "Slot1", values = GetAllSlots() })

    Window:AddToggle({ text = "Automatic Farm", flag = "toggle", state = false, callback = function()
        AutoFarm = Flags["toggle"]

        if (AutoFarm) then
            task.spawn(function()
                while AutoFarm do
                    if (not IsBattle()) then
                        LoadSlot(Flags["slot"])
                        task.wait(2)
                        StartWave(Flags["wave"], Flags["difficulty"])
                    end

                    task.wait(.1)
                end
            end)
        end
    end })
end

do -- Misc
    local Misc = Window:AddFolder("Misc")
    Misc:AddLabel({ text = "Credit: GhostyDuckyy#7698" })
    Misc:AddLabel({ text = "UI: Jan#5106" })
    Misc:AddButton({ text = "Abort Script", flag = "Abort", callback = function()
        if (game:GetService("CoreGui"):FindFirstChild("uwuware")) then
            game:GetService("CoreGui"):FindFirstChild("uwuware"):Destroy()
        end
        AutoFarm = false
    end })
end

Library:Init()
