-- AirdropHelper Main File
-- 主插件文件

local addonName, addon = ...

-- 创建主框架
local frame = CreateFrame("Frame", "AirdropHelperFrame")
addon.frame = frame

-- 事件处理函数
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

-- 注册事件
frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("ADDON_LOADED")

-- 插件初始化
function addon:OnAddonLoaded()
    -- 初始化配置
    self.Config:Init()
    
    -- 初始化战争模式状态
    self.warModeEnabled = false
    
    -- 检查插件是否启用
    if not self.Config:IsEnabled() then
        self.Utils:Info(addon.L.ADDON_DISABLED)
        return
    end
    
    -- 初始化各个模块
    self:InitializeModules()
    
    -- 注册其他事件
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
    frame:RegisterEvent("PLAYER_FLAGS_CHANGED") -- 监听战争模式变化
    -- 重新启用地图标记事件，监控"戰爭補給箱"
    frame:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
    
    -- 初始化同步系统
    if self.Config:IsSyncEnabled() then
        self.SyncManager:Initialize()
    end
    
    self.Utils:Info(addon.L("ADDON_LOADED", self.VERSION))
    
    -- 输出本地化信息
    self.Utils:Debug("Localization loaded for locale:", GetLocale())
    
    -- 检查依赖
    local missingDeps = self.Utils:CheckDependencies()
    if #missingDeps > 0 then
        self.Utils:Warning("缺少依赖: " .. table.concat(missingDeps, ", "))
    end
end

-- 初始化模块
function addon:InitializeModules()
    -- 初始化NPC监控器
    if self.NPCMonitor then
        self.NPCMonitor:Initialize()
    end
    
    -- 初始化通知系统
    if self.NotificationSystem then
        self.NotificationSystem:Initialize()
    end
    
    -- 初始化计时器UI
    if self.TimerUI then
        self.TimerUI:Initialize()
    end
    
    -- 初始化空投检测器
    if self.AirdropDetector then
        self.AirdropDetector:Initialize()
    end
end

-- 玩家进入世界
function addon:OnPlayerEnteringWorld()
    self.Utils:Debug("玩家进入世界")
    
    -- 检查战争模式状态
    self:CheckWarModeStatus()
    
    -- 不重置计时器！保持其他地图的计时器继续运行
    -- 只更新当前区域信息
    self.currentZone = self.Utils:GetCurrentZoneName()
    self.Utils:Debug("当前地图:", self.currentZone)
end

-- 区域变化
function addon:OnZoneChanged()
    local newZone = self.Utils:GetCurrentZoneName()
    local oldZone = self.currentZone
    
    self.currentZone = newZone
    self.Utils:Debug("区域变化:", oldZone, "->", newZone)
    
    -- 计时器UI不需要处理区域变化，让所有地图的计时器继续运行
    -- 只通知需要清理状态的模块
    if self.NPCMonitor then
        self.NPCMonitor:OnZoneChanged(newZone, oldZone)
    end
    
    if self.AirdropDetector then
        self.AirdropDetector:OnZoneChanged(newZone, oldZone)
    end
    
    -- 显示当前地图上的计时器状态（调试信息）
    if self.TimerUI and addon.DEBUG then
        local currentZoneTimers = 0
        local totalTimers = #self.TimerUI.timers
        for _, timer in ipairs(self.TimerUI.timers) do
            if timer.zoneName == newZone and not timer.expired then
                currentZoneTimers = currentZoneTimers + 1
            end
        end
        self.Utils:Debug(string.format("地图 [%s] 计时器: %d个, 总计时器: %d个", newZone, currentZoneTimers, totalTimers))
    end
end

-- 玩家标志变化（包括战争模式）
function addon:OnPlayerFlagsChanged()
    self:CheckWarModeStatus()
end

-- 检查战争模式状态
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
                -- 不清理计时器！只是隐藏界面，让计时器在后台继续运行
                -- 当重新开启战争模式时，之前的计时器依然有效
            end
        end
    end
end

-- 检查插件是否应该工作
function addon:IsActive()
    return self.Config:IsEnabled() and self.warModeEnabled
end

-- NPC说话事件
function addon:OnNPCSpeak(message, sender)
    if not self:IsActive() then
        return
    end
    
    self.Utils:Debug("NPC说话:", sender, "->", message)
    
    -- 传递给NPC监控器处理
    if self.NPCMonitor then
        self.NPCMonitor:ProcessNPCMessage(message, sender)
    end
end

-- 地图标记更新事件
function addon:OnVignetteUpdated(vignetteGUID)
    if not self:IsActive() then
        return
    end
    
    self.Utils:Debug("地图标记更新:", vignetteGUID)
    
    -- 传递给空投检测器处理
    if self.AirdropDetector then
        self.AirdropDetector:ProcessVignette(vignetteGUID)
    end
end

-- 触发空投事件
function addon:TriggerAirdrop(triggerType, data)
    if not self:IsActive() then
        return
    end
    
    local zoneName = data.zoneName or self.Utils:GetCurrentZoneName()
    local timeString = data.timeString or self.Utils:GetTimeString()
    local duration = data.duration or (triggerType == "NPC" and self.TIMER_CONFIG.NPC_TRIGGER_DURATION or self.TIMER_CONFIG.VISUAL_TRIGGER_DURATION)
    
    self.Utils:Debug("触发空投:", triggerType, zoneName, timeString)
    
    -- 发送通知
    if self.NotificationSystem and self.Config:IsNotificationEnabled() then
        local message = string.format("%s %s %s", self.L.AIRDROP_DETECTED, zoneName, timeString)
        self.NotificationSystem:SendNotification(message)
    end
    
    -- 添加计时器
    if self.TimerUI then
        self.TimerUI:AddTimer({
            id = self.Utils:GenerateID(),
            zoneName = zoneName,
            startTime = GetTime(),
            duration = duration,
            triggerType = triggerType,
            triggerTime = date("%H:%M"), -- 添加触发时间字段
            expired = false
        })
    end
    
    -- 同步给其他玩家
    if self.SyncManager and self.Config:IsSyncEnabled() then
        self.SyncManager:ShareAirdrop({
            zoneName = zoneName,
            timeString = timeString,
            triggerType = triggerType,
            duration = duration,
            triggerTime = date("%H:%M"), -- 添加触发时间到同步数据
            position = {self.Utils:GetPlayerPosition()}
        })
    end
    
    -- 播放声音提醒
    self.Utils:PlaySound()
end

-- 斜杠命令处理
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
        addon.Utils:Info("窗口已锁定")
    elseif command == "unlock" then
        addon.Config:Set("ui.locked", false)
        if addon.TimerUI then
            addon.TimerUI:SetLocked(false)
        end
        addon.Utils:Info("窗口已解锁")
    elseif command == "reset" then
        addon.Config:Reset()
        ReloadUI()
    elseif command == "debug" then
        local newDebugState = not addon.Config:Get("debugMode")
        addon.Config:Set("debugMode", newDebugState)
        addon.Utils:Info("调试模式:", newDebugState and "开启" or "关闭")
    elseif command == "test" then
        if addon:IsActive() then
            addon:TriggerAirdrop("TEST", {
                zoneName = "测试区域",
                timeString = addon.Utils:GetTimeString(),
                duration = 60 -- 1分钟测试
            })
            addon.Utils:Info("测试空投已触发")
        else
            addon.Utils:Warning("插件未激活 - 需要开启战争模式")
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
        local warModeStatus = addon.warModeEnabled and "开启" or "关闭"
        local activeStatus = addon:IsActive() and "激活" or "未激活"
        addon.Utils:Info("战争模式: " .. warModeStatus)
        addon.Utils:Info("插件状态: " .. activeStatus)
        
        if addon.TimerUI and #addon.TimerUI.timers > 0 then
            addon.Utils:Info("当前计时器总数: " .. #addon.TimerUI.timers .. "个")
            
            -- 按地图分组显示计时器
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
                    local status = zoneName == addon.currentZone and "(当前地图)" or ""
                    addon.Utils:Info("  " .. zoneName .. ": " .. count .. "个计时器 " .. status)
                end
            end
        else
            addon.Utils:Info("当前没有活跃的计时器")
        end
    else
        addon.Utils:Error("未知命令:", command)
    end
end