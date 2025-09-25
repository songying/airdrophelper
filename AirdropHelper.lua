-- AirdropHelper Main File
-- 主外掛文件

local addonName, addon = ...

-- 創建主框架
local frame = CreateFrame("Frame", "AirdropHelperFrame")
addon.frame = frame

-- 事件處理函數
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            addon:OnAddonLoaded()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        addon:OnPlayerEnteringWorld()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        addon:OnZoneChanged()
    elseif event == "CHAT_MSG_MONSTER_SAY" then
        local message, sender = ...
        addon:OnNPCSpeak(message, sender)
    elseif event == "VIGNETTE_MINIMAP_UPDATED" then
        local vignetteGUID = ...
        addon:OnVignetteUpdated(vignetteGUID)
    elseif event == "PLAYER_FLAGS_CHANGED" then
        addon:OnPlayerFlagsChanged()
    end
end

-- 註冊事件
frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("ADDON_LOADED")

-- 外掛初始化
function addon:OnAddonLoaded()
    -- 初始化設定
    self.Config:Init()
    
    -- 初始化戰爭模式狀態
    self.warModeEnabled = false
    
    -- 檢查外掛是否啟用
    if not self.Config:IsEnabled() then
        self.Utils:Info(addon.L.ADDON_DISABLED)
        return
    end
    
    -- 初始化各個模組
    self:InitializeModules()
    
    -- 註冊其他事件
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
    frame:RegisterEvent("PLAYER_FLAGS_CHANGED") -- 監聽戰爭模式變化
    -- 重新啟用地圖標記事件，監控"戰爭補給箱"
    frame:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
    
    -- 初始化同步系統
    if self.Config:IsSyncEnabled() then
        self.SyncManager:Initialize()
    end
    
    self.Utils:Info(addon.L("ADDON_LOADED", self.VERSION))
    
    -- 輸出本地化資訊
    self.Utils:Debug("Localization loaded for locale:", GetLocale())
    
    -- 檢查相依性
    local missingDeps = self.Utils:CheckDependencies()
    if #missingDeps > 0 then
        self.Utils:Warning("缺少相依性: " .. table.concat(missingDeps, ", "))
    end
end

-- 初始化模組
function addon:InitializeModules()
    -- 初始化NPC監控器
    if self.NPCMonitor then
        self.NPCMonitor:Initialize()
    end
    
    -- 初始化通知系統
    if self.NotificationSystem then
        self.NotificationSystem:Initialize()
    end
    
    -- 初始化計時器UI
    if self.TimerUI then
        self.TimerUI:Initialize()
    end
    
    -- 初始化空投檢測器
    if self.AirdropDetector then
        self.AirdropDetector:Initialize()
    end
end

-- 玩家進入世界
function addon:OnPlayerEnteringWorld()
    self.Utils:Debug("玩家進入世界")
    
    -- 檢查戰爭模式狀態
    self:CheckWarModeStatus()
    
    -- 不重置計時器！保持其他地圖的計時器繼續運行
    -- 只更新目前區域資訊
    self.currentZone = self.Utils:GetCurrentZoneName()
    self.Utils:Debug("目前地圖:", self.currentZone)
end

-- 區域變化
function addon:OnZoneChanged()
    local newZone = self.Utils:GetCurrentZoneName()
    local oldZone = self.currentZone
    
    self.currentZone = newZone
    self.Utils:Debug("區域變化:", oldZone, "->", newZone)
    
    -- 計時器UI不需要處理區域變化，讓所有地圖的計時器繼續運行
    -- 只通知需要清理狀態的模組
    if self.NPCMonitor then
        self.NPCMonitor:OnZoneChanged(newZone, oldZone)
    end
    
    if self.AirdropDetector then
        self.AirdropDetector:OnZoneChanged(newZone, oldZone)
    end
    
    -- 顯示目前地圖上的計時器狀態（除錯資訊）
    if self.TimerUI and addon.DEBUG then
        local currentZoneTimers = 0
        local totalTimers = #self.TimerUI.timers
        for _, timer in ipairs(self.TimerUI.timers) do
            if timer.zoneName == newZone and not timer.expired then
                currentZoneTimers = currentZoneTimers + 1
            end
        end
        self.Utils:Debug(string.format("地圖 [%s] 計時器: %d個, 總計時器: %d個", newZone, currentZoneTimers, totalTimers))
    end
end

-- 玩家標誌變化（包括戰爭模式）
function addon:OnPlayerFlagsChanged()
    self:CheckWarModeStatus()
end

-- 檢查戰爭模式狀態
function addon:CheckWarModeStatus()
    local isWarModeEnabled = self.Utils:IsWarModeEnabled()
    
    if isWarModeEnabled ~= self.warModeEnabled then
        self.warModeEnabled = isWarModeEnabled
        
        if isWarModeEnabled then
            self.Utils:Info(addon.L.ADDON_ACTIVATED)
            if self.TimerUI then
                self.TimerUI:Show()
            end
        else
            self.Utils:Info(addon.L.ADDON_DEACTIVATED)
            if self.TimerUI then
                self.TimerUI:Hide()
                -- 不清理計時器！只是隱藏介面，讓計時器在後台繼續運行
                -- 當重新開啟戰爭模式時，之前的計時器依然有效
            end
        end
    end
end

-- 檢查外掛是否應該工作
function addon:IsActive()
    return self.Config:IsEnabled() and self.warModeEnabled
end

-- NPC說話事件
function addon:OnNPCSpeak(message, sender)
    if not self:IsActive() then
        return
    end
    
    self.Utils:Debug("NPC說話:", sender, "->", message)
    
    -- 傳遞給NPC監控器處理
    if self.NPCMonitor then
        self.NPCMonitor:ProcessNPCMessage(message, sender)
    end
end

-- 地圖標記更新事件
function addon:OnVignetteUpdated(vignetteGUID)
    if not self:IsActive() then
        return
    end
    
    self.Utils:Debug("地圖標記更新:", vignetteGUID)
    
    -- 傳遞給空投檢測器處理
    if self.AirdropDetector then
        self.AirdropDetector:ProcessVignette(vignetteGUID)
    end
end

-- 觸發空投事件
function addon:TriggerAirdrop(triggerType, data)
    if not self:IsActive() then
        return
    end
    
    local zoneName = data.zoneName or self.Utils:GetCurrentZoneName()
    local timeString = data.timeString or self.Utils:GetTimeString()
    local duration = data.duration or (triggerType == "NPC" and self.TIMER_CONFIG.NPC_TRIGGER_DURATION or self.TIMER_CONFIG.VISUAL_TRIGGER_DURATION)
    
    self.Utils:Debug("觸發空投:", triggerType, zoneName, timeString)
    
    -- 發送通知
    if self.NotificationSystem and self.Config:IsNotificationEnabled() then
        local message = string.format("%s %s %s", self.L.AIRDROP_DETECTED, zoneName, timeString)
        self.NotificationSystem:SendNotification(message)
    end
    
    -- 添加計時器
    if self.TimerUI then
        self.TimerUI:AddTimer({
            id = self.Utils:GenerateID(),
            zoneName = zoneName,
            startTime = GetTime(),
            duration = duration,
            triggerType = triggerType,
            triggerTime = date("%H:%M"), -- 添加觸發時間字段
            expired = false
        })
    end
    
    -- 同步給其他玩家
    if self.SyncManager and self.Config:IsSyncEnabled() then
        self.SyncManager:ShareAirdrop({
            zoneName = zoneName,
            timeString = timeString,
            triggerType = triggerType,
            duration = duration,
            triggerTime = date("%H:%M"), -- 添加觸發時間到同步資料
            position = {self.Utils:GetPlayerPosition()}
        })
    end
    
    -- 播放聲音提醒
    self.Utils:PlaySound()
end

-- 斜線命令處理
SLASH_AIRDROPHELPER1 = "/airdrophelper"
SLASH_AIRDROPHELPER2 = "/adh"

function SlashCmdList.AIRDROPHELPER(msg)
    local command, args = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()
    
    if command == "" or command == "help" then
        print("|cFF00FF00" .. addon.L.HELP_TITLE .. "|r")
        print(addon.L.HELP_SHOW)
        print(addon.L.HELP_HIDE)
        print(addon.L.HELP_LOCK)
        print(addon.L.HELP_UNLOCK)
        print(addon.L.HELP_RESET)
        print(addon.L.HELP_DEBUG)
        print(addon.L.HELP_TEST)
        print(addon.L.HELP_DETECTOR)
        print(addon.L.HELP_STATUS)
        print("|cFFFFFF00" .. addon.L.HELP_WARNING .. "|r")
    elseif command == "show" then
        if addon.TimerUI then
            addon.TimerUI:Show()
        end
    elseif command == "hide" then
        if addon.TimerUI then
            addon.TimerUI:Hide()
        end
    elseif command == "lock" then
        addon.Config:Set("ui.locked", true)
        if addon.TimerUI then
            addon.TimerUI:SetLocked(true)
        end
        addon.Utils:Info("視窗已鎖定")
    elseif command == "unlock" then
        addon.Config:Set("ui.locked", false)
        if addon.TimerUI then
            addon.TimerUI:SetLocked(false)
        end
        addon.Utils:Info("視窗已解鎖")
    elseif command == "reset" then
        addon.Config:Reset()
        ReloadUI()
    elseif command == "debug" then
        local newDebugState = not addon.Config:Get("debugMode")
        addon.Config:Set("debugMode", newDebugState)
        addon.Utils:Info("除錯模式:", newDebugState and "開啟" or "關閉")
    elseif command == "test" then
        if addon:IsActive() then
            addon:TriggerAirdrop("TEST", {
                zoneName = "測試區域",
                timeString = addon.Utils:GetTimeString(),
                duration = 60 -- 1分鐘測試
            })
            addon.Utils:Info("測試空投已觸發")
        else
            addon.Utils:Warning("外掛未啟動 - 需要開啟戰爭模式")
        end
    elseif command == "detector" then
        if args == "on" then
            if addon.AirdropDetector then
                addon.AirdropDetector:SetEnabled(true)
                frame:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
                addon.Utils:Info(addon.L.DETECTOR_ENABLED)
            end
        elseif args == "off" then
            if addon.AirdropDetector then
                addon.AirdropDetector:SetEnabled(false)
                frame:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
                addon.Utils:Info(addon.L.DETECTOR_DISABLED)
            end
        else
            local status = addon.AirdropDetector and addon.AirdropDetector:IsEnabled() and addon.L.STATUS_ENABLED or addon.L.STATUS_DISABLED
            addon.Utils:Info(addon.L("DETECTOR_STATUS", status))
        end
    elseif command == "status" then
        local warModeStatus = addon.warModeEnabled and "開啟" or "關閉"
        local activeStatus = addon:IsActive() and "啟動" or "未啟動"
        addon.Utils:Info("戰爭模式: " .. warModeStatus)
        addon.Utils:Info("外掛狀態: " .. activeStatus)
        
        if addon.TimerUI and #addon.TimerUI.timers > 0 then
            addon.Utils:Info("目前計時器總數: " .. #addon.TimerUI.timers .. "個")
            
            -- 按地圖分組顯示計時器
            local zoneTimers = {}
            for _, timer in ipairs(addon.TimerUI.timers) do
                if not zoneTimers[timer.zoneName] then
                    zoneTimers[timer.zoneName] = 0
                end
                if not timer.expired then
                    zoneTimers[timer.zoneName] = zoneTimers[timer.zoneName] + 1
                end
            end
            
            for zoneName, count in pairs(zoneTimers) do
                if count > 0 then
                    local status = zoneName == addon.currentZone and "(目前地圖)" or ""
                    addon.Utils:Info("  " .. zoneName .. ": " .. count .. "個計時器 " .. status)
                end
            end
        else
            addon.Utils:Info("目前沒有活躍的計時器")
        end
    else
        addon.Utils:Error("未知命令:", command)
    end
end