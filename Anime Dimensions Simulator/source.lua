--// Checks \\--
local BlackList_IDs = {6938803436, 7338881230, 6990131029, 6990133340} -- Lobby, Raid Lobby, AFK Lobby, Character Testing
if table.find(BlackList_IDs, game.PlaceId) then return end
if not game:IsLoaded() then game.Loaded:Wait() end

if not workspace:WaitForChild("Folders", 180) then return end
if not game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents", 180) then return end
if not game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunctions", 180) then return end

--// Services \\--
local HttpService             =  game:GetService("HttpService")
local TweenService            =  game:GetService("TweenService")
local ReplicatedStorage       =  game:GetService("ReplicatedStorage")
local UserInputService        =  game:GetService("UserInputService")

local Platform                =  UserInputService:GetPlatform()
local Players                 =  game:GetService("Players")
local LocalPlayer             =  Players.LocalPlayer
local PlayerGui               =  LocalPlayer:WaitForChild("PlayerGui")
local Camera                  =  workspace.CurrentCamera

local Request = (syn and syn.request) or request or (https and https.request) or http_request or function(...)
    debug_SendOutput("Function: 'request' is invaild \n")
    local Response =  {
        ["Success"] = false
   }
    return Response
end

local Queue_on_teleport = (syn and syn.queue_on_teleport) or queue_on_teleport or queueonteleport or function(...)
    debug_SendOutput("Function: 'queue_on_teleport' is nil")
end

--// Folders \\--
local Monsters                =  workspace["Folders"]:WaitForChild("Monsters")

--// Remotes \\--
local MainRemoteEvent         =  ReplicatedStorage["RemoteEvents"]:WaitForChild("MainRemoteEvent")
local MainRemoteFunction      =  ReplicatedStorage["RemoteFunctions"]:WaitForChild("MainRemoteFunction")

--// Settings \\--
getgenv().CurrentTween = nil

getgenv().Settings = (type(getgenv().Settings) == "table" and Settings) or {
    AutoLoad        =   true,
    AutoFarm        =   false,
    AutoRetry       =   false,
    Webhook         =   {Enabled = false, Url = "https://discord.com/api/webhooks/example/tokens"},
    DebugMode       =   false,
}

getgenv().OtherSettings = (getgenv().OtherSettings and OtherSettings) or {
    PostedResult    =   false,
    Executed        =   false,
    IsHooked        =   false,
    RunAutoLoad     =   false,
}

getgenv().ResultTable = (type(getgenv().ResultTable) == "table" and ResultTable) or {
    ["timeTaken"]       = nil,
    ["damageDealt"]     = nil,
    ["rank"]            = nil,
    ["reward"]          = nil,
}

if (OtherSettings.Executed) then return else OtherSettings.Executed = true end

--// Webhook Functions \\--
local function matchUrl(input)
    if type(input) ~= "string" then return end

    if (string.find(input, "https://discord.com/api/webhooks/") and input ~= "https://discord.com/api/webhooks/example/tokens") then
        local Response = Request({Url = Settings.Webhook.Url, Method = "GET"})

        if (Response["Success"]) then
            return true
        end
    end

    return false
end

function Send_Webhook(Types, data)
    if (not Settings.Webhook.Enabled) then return end
    if (not matchUrl(Settings.Webhook.Url)) then debug_SendOutput("Invaild webhook url \n") return end
    if type(Settings.Webhook.Url) ~= "string" then return end
    if type(Types) ~= "string" then return end

    if (Types == "GameEnded" and OtherSettings.PostedResult) then return end
    if (Types == "GameEnded") then
        task.wait(.5)

        local Leaderstats = LocalPlayer:WaitForChild("leaderstats")
        local BattleGui = PlayerGui:WaitForChild("BattleGui"):WaitForChild("CenterUIFrame")
        local OwnInfoFrame = PlayerGui:WaitForChild("UniversalGui"):WaitForChild("LeftUIFrame"):WaitForChild("OwnHealthBarFrame")

        local Level, Damage = tostring(Leaderstats:WaitForChild("Level").Value or "null"), tostring(Leaderstats:WaitForChild("Damage").Value or "null")
        local TimeRemaining, Combo, Defeated = (BattleGui:WaitForChild("TimerBack"):WaitForChild("Timer").Text or "00:00"), (BattleGui:WaitForChild("BestComboBack"):WaitForChild("BestComboNumber").Text or "null"), (BattleGui:WaitForChild("EnemiesDefeatedBack"):WaitForChild("EnemyDefeatedNumber").Text or "null")
        local Exp, Gems, Golds = (OwnInfoFrame:WaitForChild("Exp") and " (**XP**: "..OwnInfoFrame["Exp"].Text..")") or " (**XP**: null)", "null", "null"

        local Time = (rawget(ResultTable, "timeTaken") ~= nil and "**Time elapsed**: "..ResultTable.timeTaken.." ⏳") or "**Time remain**: "..TimeRemaining.." ⏳"
        local Rank = (rawget(ResultTable, "rank") ~= nil and "**Rank**: "..ResultTable.rank.."\n") or "**Rank**: null\n"
        local Rewards, StringRewards = (rawget(ResultTable, "reward") ~= nil and type(ResultTable) == "table" and ResultTable.reward) or nil, ""

        if (Rewards) then
            for i = 1, #Rewards do
                local Current_Reward = Rewards[i]

                if (type(Current_Reward) == "table") then
                    StringRewards = StringRewards.."{"

                    for _,v in pairs(Current_Reward) do
                        if (tostring(_) == "type" or tostring(_) == "reward") then
                            StringRewards = StringRewards..tostring(_)..": '"..tostring(v).."'"
                        else
                            StringRewards = StringRewards..tostring(_)..": "..tostring(v)
                        end

                        StringRewards = StringRewards..", "
                    end
                    StringRewards = StringRewards.."}, "
                end
            end
        end

        if (string.len(StringRewards) <= 0) then
            StringRewards = "{'Failed to grab rewards 💀'}"
        end

        for _, Label in pairs(OwnInfoFrame:GetDescendants()) do
            if Label:IsA("TextLabel") and (Label.Parent and Label.Parent.Name == "CoinBlack") then
                if (Label.Name == "Gem") then
                    Gems = Label.Text
                elseif (Label.Name == "Gold") then
                    Golds = Label.Text
                end
            end
        end

        data = {
            ["content"] = "Thank you for using this script! 💖",
            ["embeds"] = { {
                ["title"]       = "🏁 Match Results 🏁",
                ["description"] =  Rank..Time.." | **Best Combo**: "..Combo.." 🌟\n**Defeated**: "..Defeated.." 🎯 | **Damage**: "..Damage.." ⚔️",
                ["color"]       = 9055202,
                ["fields"] = {
                    { ["name"] = "🎁 Rewards 🎁", ["value"] = "```lua\n"..StringRewards.."\n```" },
                    { ["name"] = "🔎 Infomation 🔎", ["value"] = "**User**: "..LocalPlayer.DisplayName.." (@"..LocalPlayer.Name..")\n**Level**: "..Level..Exp },
                    { ["name"] = "💸 Currency 💸", ["value"] = "**Gems**: "..Gems.." 💎\n**Golds**: "..Golds.." 🪙" },
                },
                ["author"] = {
                    ["name"]      = "Anime Dimensions Simulator",
                    ["url"]       = "https://roblox.com/games/6938803436/",
                    ["icon_url"]  = "https://pbs.twimg.com/media/FtZ-2XKaIAI4MX7?format=jpg&name=small"
                },
                ["footer"] = {
                    ["text"] = "👻 Made by GhostyDuckyy"
                }
              } },
          }
    end

    local Encoded           =   HttpService:JSONEncode(data)
    local ResponseStatus    =   Request(
        {
            ["Url"]         =   Settings.Webhook.Url,
            ["Body"]        =   Encoded,
            ["Method"]      =   "POST",
            ["Headers"]     =   { ["content-type"] = "application/json" },
        }
    )

    if (ResponseStatus.Success) then
        debug_SendOutput("Succesfully posted result to webhook \n")

        if (Types == "GameEnded")  then
            OtherSettings.PostedResult = true
        end
    else
        debug_SendOutput("Failed to post result to webhook \n")
    end
end

--// Tween \\--
local function CancelTween()
    if (typeof(CurrentTween) == "Instance" and CurrentTween:IsA("Tween")) then
        CurrentTween:Pause()
        CurrentTween:Cancel()
        CurrentTween = nil
    end
end

local function Tween(SpeedPerStuds: number, prop: table)
    if type(SpeedPerStuds) ~= "number" then return end
    if type(prop) ~= "table" then return end

    CancelTween()

    local Root = GetRoot()
    if (not Root) then
        while task.wait() do
            Root = GetRoot()
            if (Root) then break end
        end
        task.wait(.1)
    end

    local Time = (Root.CFrame.Position - prop.CFrame.Position).Magnitude / SpeedPerStuds
    CurrentTween = TweenService:Create(Root, TweenInfo.new(Time, Enum.EasingStyle.Linear), prop)
    CurrentTween.Completed:Connect(function()
        CurrentTween = nil
    end)

    CurrentTween:Play()
    return CurrentTween.Completed:Wait()
end

--// Functions \\--
function GetCharacter()
    local RespawnTimerFrame = PlayerGui:WaitForChild("UniversalGui"):WaitForChild("UniversalCenterUIFrame"):WaitForChild("RespawnTimerFrame")
    if (RespawnTimerFrame and RespawnTimerFrame.Visible) then
        return nil
    end
    return (LocalPlayer.Character ~= nil and LocalPlayer.Character) or LocalPlayer.CharacterAdded:Wait()
end

function GetRoot()
    local Character = GetCharacter()
    if (Character) then
        Character:WaitForChild("HumanoidRootPart", 9e9)
        local Root = Character:FindFirstChild("HumanoidRootPart")
        return Root
    end
    return nil
end

function GetClosestEnemy()
   local Enemy = nil
   local Last_distance = math.huge
   local Root = GetRoot()
   local Childrens = Monsters:GetChildren()

   if (not Root) then return nil end
   if (#Childrens <= 0) then return nil end

   for i = 1, #Childrens do
        local Child = Childrens[i]

        if (Child) then
            if not Child:FindFirstChildOfClass("Humanoid") then continue end
            if not Child:FindFirstChild("HumanoidRootPart") then continue end

            if (Child:FindFirstChildOfClass("BillboardGui") and Child:WaitForChild("EnemyHealthBarGui")) then
                local Health = Child["EnemyHealthBarGui"]:WaitForChild("HealthText")
                if tonumber(Health.Text) <= 0 then
                    continue
                end
            else
                continue
            end

            if Child:FindFirstChildOfClass("Highlight") then
                Enemy = Child
                return Enemy
            end

            local distance = (Root.Position - Child.HumanoidRootPart.Position).Magnitude

            if (distance < Last_distance) then
                Enemy = Child
                Last_distance = distance
            end
        end
   end

   return Enemy
end

function useAssist(number: number)
   if type(number) ~= "number" then return end
   if number >= 3 then return end

   local Root = GetRoot()
   if (not Root) then return end

   task.spawn(function()
      MainRemoteEvent:FireServer("UseAssistSkill", {["hrpCFrame"] = Root.CFrame}, number)
   end)
end

function checkCD(number: number, assist: boolean)
   if type(number) ~= "number" then return end
   if type(assist) ~= "boolean" then assist = false end

   local SlotsHolder = PlayerGui:WaitForChild("UniversalGui"):WaitForChild("UniversalCenterUIFrame"):WaitForChild("SlotsHolder")

   if (not SlotsHolder) then debug_SendOutput("SlotsHolder is 'nil' \n") return end
   if (assist) then
        if (number >= 3) then return end
        local Slot = SlotsHolder:WaitForChild("SkillAssist"..tostring(number))
        if (Slot and Slot.Visible) then
            local SkillName = Slot:WaitForChild("SkillName")

            if (not SkillName.Visible) then
                return true
            end
        end
   else
        if (number >= 6) then return end
        local Slot = SlotsHolder:WaitForChild("Skill"..tostring(number))

        if (number == 5) then
            if (Slot and Slot.Visible) then
                local SkillName = Slot:WaitForChild("SkillName").Text

                if SkillName:lower() ~= "skill 2" and not tonumber(SkillName) then
                return true
                end
            end
        elseif (4 >= number) then
            if (Slot and Slot.Visible) then
                local SkillName = Slot:WaitForChild("SkillName").Text

                if SkillName:lower() ~= "skill "..tostring(number) and not tonumber(SkillName) then
                return true
                end
            end
        end
   end

   return false
end

function useAbility(mode)
   local Root = GetRoot()
   if (not Root) then return end

    if type(mode) == "string" and mode:lower() == "click" then
        task.spawn(function()
            MainRemoteEvent:FireServer("UseSkill", {["hrpCFrame"] = Root.CFrame, ["attackNumber"] = 1}, "BasicAttack")
        end)

        task.spawn(function()
            MainRemoteEvent:FireServer("UseSkill", {["hrpCFrame"] = Root.CFrame, ["attackNumber"] = 2}, "BasicAttack")
        end)
    elseif type(mode) == "number" and mode < 6 then
        task.spawn(function()
            MainRemoteEvent:FireServer("UseSkill", {["hrpCFrame"] = Root.CFrame}, mode)
        end)
    end
end

function IsEnded()
   local CenterUIFrame = PlayerGui:WaitForChild("UniversalGui"):WaitForChild("UniversalCenterUIFrame")
   local ResultUIs = {
        [1] = CenterUIFrame:WaitForChild("ResultUI"),
        [2] = CenterUIFrame:WaitForChild("RaidResultUI"),
    }

   for i,v in pairs(ResultUIs) do
      if (v.Visible) then
         return true
      end
   end

   return false
end

function Retry()
   task.spawn(function()
      MainRemoteEvent:FireServer("RetryDungeon")
   end)
end

function Leave()
   task.spawn(function()
      MainRemoteEvent:FireServer("LeaveDungeon")
   end)
end

function debug_SendOutput(...)
    if (not Settings.DebugMode) then return end
    local Outputs = {...}
    task.spawn(function()
        for _, v in next, (Outputs) do
            print(tostring(v))
         end
    end)
end

--// Hooks \\--
task.spawn(function()
    if (OtherSettings.IsHooked) then return end
    local onMainRemoteEventCall = nil

    for i,v in pairs(getconnections(MainRemoteEvent.OnClientEvent)) do
        if (v.Function) then
            local info = debug.getinfo(v.Function)

            if (info.name == "onMainRemoteEventCall") then
                onMainRemoteEventCall = v.Function
                break
            end
        end
    end

    if (onMainRemoteEventCall) then
        local old_function;
        old_function = hookfunction(onMainRemoteEventCall, function(FuncName, ...)
            local Args = {...}

            if (FuncName == "SetUpResultUI" or FuncName == "setupRaidUI") then
                getgenv().ResultTable = Args[1]
            end

            return old_function(FuncName, ...)
        end)

        debug_SendOutput("Hooked 'onMainRemoteEventCall' function")
        OtherSettings.IsHooked = true
    else
        debug_SendOutput("Failed to hook 'onMainRemoteEventCall' function")
    end
end)

--// Auto Load \\--
if (Settings.AutoLoad and not OtherSettings.RunAutoLoad) then
    OtherSettings.RunAutoLoad = true

    local SettingsString = [[getgenv().Settings = { AutoLoad = ]]..tostring(Settings.AutoLoad)..[[, AutoFarm = ]]..tostring(Settings.AutoFarm)..[[, AutoRetry = ]]..tostring(Settings.AutoRetry)..[[, Webhook = { Enabled = ]]..tostring(Settings.Webhook.Enabled)..[[, Url = "]]..tostring(Settings.Webhook.Url)..[[", }}]].."\n"
    local WaitString = [[task.wait(2)]].."\n"
    local Source = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/GhostDuckyy/Roblox-Projects/main/Anime%20Dimensions%20Simulator/source.lua", true))("💀")]]
    local Load = tostring(SettingsString..WaitString..Source)

    Queue_on_teleport(Load)
end

--// Rayfield | Sirius Team \\--
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
local Window = Rayfield:CreateWindow( {
    Name                  =  "GhotsyDuckyy Projects",
    LoadingTitle          =  "Anime Dimensions Simulator",
    LoadingSubtitle       =  "by Sirius Team & GhostyDuckyy",
    KeySystem             =  false,
    ConfigurationSaving   =  { Enabled = false, FolderName = "GhotsyDuckyy Projects", FileName = "Anime Dimensions Simulator", },
    Discord               =  { Enabled = false, Invite =  "Current no invite",  RememberJoins = false, },
} )

local Tabs = {
    ["Main"]   =  Window:CreateTab("Main", 4483362458),
    ["Misc"]   =  Window:CreateTab("Misc", 4483362458),
}

local Toggles = {}

--// Source \\--
Rayfield:Notify({ Image = "11745872952", Title = "Warning", Content = "Abort Script at Misc tab.\nDon't use Rayfield build-in close button!" })

Tabs["Main"]:CreateSection("Auto Farm")

Toggles["Enaled_AutoFarm"] = Tabs["Main"]:CreateToggle( {
    Name            =  "Enabled",
    Current_Value   =  false,
    Flag            =  "Enaled_AutoFarm",
    Callback = function(value)
        Settings.AutoFarm = value

        if (value) then
            task.spawn(function()
                local Enemy = GetClosestEnemy()

                while task.wait(.1) do
                    local Character, Root = GetCharacter(), GetRoot()

                    if (not Settings.AutoFarm) then
                        if (Character and Root and Character:FindFirstChildOfClass("Humanoid")) then
                            Camera.CameraSubject = Character:FindFirstChildOfClass("Humanoid")
                            Root.Anchored = false
                            break
                        end
                    end

                    if IsEnded() then
                        debug_SendOutput("Game Ended")

                        Send_Webhook("GameEnded")

                        if (Settings.AutoRetry) then
                            debug_SendOutput("Retry dungeon \n")
                            Retry()
                            continue
                        else
                            debug_SendOutput("Leave dungeon \n")
                            Leave()
                            continue
                        end
                    end

                    if (Character and Root) and not IsEnded() then
                        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

                        if (Enemy and Enemy.Parent) then
                            local EnemyRoot = Enemy:FindFirstChild("HumanoidRootPart")
                            local EnemyHumanoid = Enemy:FindFirstChildOfClass("Humanoid")

                            if (not EnemyRoot or not EnemyHumanoid) then
                                Enemy = nil
                                Camera.CameraSubject = Humanoid
                                continue
                            end

                            if (Enemy:FindFirstChildOfClass("BillboardGui") and Enemy:WaitForChild("EnemyHealthBarGui")) then
                                local Health = Enemy["EnemyHealthBarGui"]:WaitForChild("HealthText")
                                if tonumber(Health.Text) <= 0 then
                                    Enemy = nil
                                    Camera.CameraSubject = Humanoid
                                    continue
                                end
                            else
                                Enemy = nil
                                Camera.CameraSubject = Humanoid
                                continue
                            end

                            pcall(
                                task.spawn(function()
                                    Camera.CameraSubject = EnemyHumanoid

                                    if (Character and Character:WaitForChild("Head", 10) and Character["Head"]:WaitForChild("PlayerHealthBarGui", 10)) then
                                        local NameLabel = Character["Head"]["PlayerHealthBarGui"]:WaitForChild("PlayerName")
                                        NameLabel.Text = "Made by GhostyDuckyy#7698"
                                    end
                                end)
                            )

                            local EnemyCFrame = EnemyRoot:GetPivot()
                            local distance = (Root.CFrame.Position - EnemyRoot.Position).Magnitude

                            Root.Anchored = false
                            debug_SendOutput("MoveTo: "..Enemy.Name.."\n")

                            if (distance <= 20) then
                                Tween(18, {CFrame = CFrame.lookAt(EnemyCFrame.Position + Vector3.new(0, 4, 0), EnemyCFrame.Position) })
                            else
                                Tween(160, {CFrame = CFrame.lookAt(EnemyCFrame.Position + Vector3.new(0, 4, 0), EnemyCFrame.Position) })
                            end

                            Root.Anchored = true

                            if checkCD(1, true) then
                                debug_SendOutput("Use Assist: 1")
                                useAssist(1)
                            end

                            if checkCD(2, true) then
                                debug_SendOutput("Use Assist: 2")
                                useAssist(2)
                            end

                            if (not checkCD(5) and not checkCD(4) and not checkCD(3) and not checkCD(2) and not checkCD(1)) then
                                debug_SendOutput("BasicAttack")
                                useAbility("click")
                                continue
                            end

                            if checkCD(5) then
                                debug_SendOutput("Use Ability: 5")
                                useAbility(5)
                                continue
                            end

                            if checkCD(4) then
                                debug_SendOutput("Use Ability: 4")
                                useAbility(4)
                                continue
                            end

                            if checkCD(3) then
                                debug_SendOutput("Use Ability: 3")
                                useAbility(3)
                                continue
                            end

                            if checkCD(2) then
                                debug_SendOutput("Use Ability: 2")
                                useAbility(2)
                                continue
                            end

                            if checkCD(1) then
                                debug_SendOutput("Use Ability: 1")
                                useAbility(1)
                                continue
                            end
                        else
                            Root.Anchored = false
                            Root.Velocity = Vector3.new()
                            Enemy = GetClosestEnemy()
                        end
                    end
                end
            end)
        end
    end,
} )

Toggles.Enaled_AutoFarm:Set(Settings.AutoFarm)

Toggles["Enaled_AutoRetry"] = Tabs["Main"]:CreateToggle( {
    Name            =  "Auto Retry Dimension",
    Current_Value   =  false,
    Flag            =  "Enaled_AutoRetry",
    Callback = function(value)
        Settings.AutoRetry = value
    end,
} )

Toggles.Enaled_AutoRetry:Set(Settings.AutoRetry)

Tabs["Main"]:CreateSection("Webhook")

local Webhook_Status = Tabs["Main"]:CreateLabel(
    "Webhook Status: "..( (matchUrl(Settings.Webhook.Url) and "Vaild") or "Invaild" )
)

Toggles["Enaled_Webhook"] = Tabs["Main"]:CreateToggle( {
    Name            =  "Enabled Webhook",
    Current_Value   =  false,
    Flag            =  "Enaled_Webhook",
    Callback = function(value)
        Settings.Webhook.Enabled = value
    end,
} )

Toggles.Enaled_Webhook:Set(Settings.Webhook.Enabled)

Tabs["Main"]:CreateInput( {
    Name                        = "Insert Url",
    PlaceholderText             =  "https://discord.com/api/webhooks/example/tokens",
    RemoveTextAfterFocusLost    =  true,
    Callback = function(value)
        Settings.Webhook.Url    = tostring(value)

        if (matchUrl(Settings.Webhook.Url)) then
            Webhook_Status:Set("Webhook Status is Vaild")
        else
            Webhook_Status:Set("Webhook Status is Invaild")
        end
    end,
} )

Tabs["Misc"]:CreateSection("Etc")

Tabs["Misc"]:CreateButton( {
    Name = "Abort Script",
    Callback = function()
        Toggles.Enaled_AutoFarm:Set(false)
        Toggles.Enaled_AutoRetry:Set(false)
        Toggles.Enaled_Webhook:Set(false)

        OtherSettings.Executed = false

        Rayfield:Destroy()
    end
} )

Tabs["Misc"]:CreateSection("Credits")

Tabs["Misc"]:CreateParagraph( {
    Title = "Scripters",
    Content = "GhostyDuckyy#7698",
} )

Tabs["Misc"]:CreateParagraph( {
    Title = "Rayfield Interface Suite",
    Content = "Sirius Team",
} )
