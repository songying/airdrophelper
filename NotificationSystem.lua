-- AirdropHelper Notification System
-- 通知系统模块

local addonName, addon = ...

addon.NotificationSystem = {}

local NotificationSystem = addon.NotificationSystem

-- 初始化
function NotificationSystem:Initialize()
    self.isEnabled = true
    self.lastNotificationTime = 0
    self.notificationCooldown = 2 -- 2秒冷却时间，防止刷屏
    
    addon.Utils:Debug(addon.L.NOTIFICATION_INITIALIZED)
end

-- 发送通知
function NotificationSystem:SendNotification(message, priority)
    if not self.isEnabled or not addon.Config:IsNotificationEnabled() then
        return false
    end
    
    -- 检查冷却时间
    local currentTime = GetTime()
    if currentTime - self.lastNotificationTime < self.notificationCooldown then
        addon.Utils:Debug(addon.L("NOTIFICATION_COOLDOWN", message))
        return false
    end
    
    self.lastNotificationTime = currentTime
    
    -- 确定发送方式
    local sentSuccessfully = false
    
    if priority then
        -- 使用指定优先级
        sentSuccessfully = self:SendByPriority(message, priority)
    else
        -- 自动选择最佳发送方式
        sentSuccessfully = self:SendByBestMethod(message)
    end
    
    if sentSuccessfully then
        addon.Utils:Debug(addon.L("NOTIFICATION_SENT", message))
    else
        addon.Utils:Warning(addon.L("NOTIFICATION_FAILED", message))
    end
    
    return sentSuccessfully
end

-- 自动选择最佳发送方式
function NotificationSystem:SendByBestMethod(message)
    -- 优先级顺序：团队警报 > 团队频道 > 小队频道 > 普通说话
    -- 无论什么情况都要发送消息，确保玩家能看到通知
    
    -- 1. 尝试团队警报
    if addon.Config:Get("notifications.useRaidWarning") and self:TryRaidWarning(message) then
        return true
    end
    
    -- 2. 尝试团队频道
    if self:TryRaidChat(message) then
        return true
    end
    
    -- 3. 尝试小队频道
    if self:TryPartyChat(message) then
        return true
    end
    
    -- 4. 普通说话 (单人时也要发送，确保玩家看到通知)
    return self:TrySayChat(message)
end

-- 按指定优先级发送
function NotificationSystem:SendByPriority(message, priority)
    if priority == addon.NOTIFICATION_PRIORITY.RAID_WARNING then
        return self:TryRaidWarning(message)
    elseif priority == addon.NOTIFICATION_PRIORITY.RAID then
        return self:TryRaidChat(message)
    elseif priority == addon.NOTIFICATION_PRIORITY.PARTY then
        return self:TryPartyChat(message)
    elseif priority == addon.NOTIFICATION_PRIORITY.SAY then
        return self:TrySayChat(message)
    else
        return self:SendByBestMethod(message)
    end
end

-- 尝试发送团队警报
function NotificationSystem:TryRaidWarning(message)
    if not UnitInRaid("player") then
        addon.Utils:Debug(addon.L.NOTIFICATION_NOT_IN_RAID)
        return false
    end
    
    if not addon.Utils:CanSendRaidWarning() then
        addon.Utils:Debug(addon.L.WARNING_NO_PERMISSION)
        return false
    end
    
    return addon.Utils:SendChatMessage(message, "RAID_WARNING")
end

-- 尝试发送团队频道消息
function NotificationSystem:TryRaidChat(message)
    if not UnitInRaid("player") then
        addon.Utils:Debug(addon.L.NOTIFICATION_NOT_IN_RAID)
        return false
    end
    
    return addon.Utils:SendChatMessage(message, "RAID")
end

-- 尝试发送小队频道消息
function NotificationSystem:TryPartyChat(message)
    if not UnitInParty("player") then
        addon.Utils:Debug(addon.L.NOTIFICATION_NOT_IN_PARTY)
        return false
    end
    
    return addon.Utils:SendChatMessage(message, "PARTY")
end

-- 尝试发送普通说话
function NotificationSystem:TrySayChat(message)
    return addon.Utils:SendChatMessage(message, "SAY")
end

-- 发送本地通知 (只有自己能看到)
function NotificationSystem:SendLocalNotification(message, color)
    local coloredMessage = message
    if color then
        coloredMessage = addon.Utils:ColorText(message, color[1], color[2], color[3])
    end
    
    print(coloredMessage)
    addon.Utils:Debug(addon.L("NOTIFICATION_LOCAL", message))
end

-- 发送屏幕中央提醒
function NotificationSystem:SendScreenAlert(message, duration)
    if not self.isEnabled then
        return
    end
    
    duration = duration or 3
    
    -- 使用暴雪的屏幕提醒框架 (兼容11.2版本)
    if RaidNotice_AddMessage and RaidWarningFrame then
        local chatTypeInfo = ChatTypeInfo and ChatTypeInfo["RAID_WARNING"]
        if chatTypeInfo then
            RaidNotice_AddMessage(RaidWarningFrame, message, chatTypeInfo)
        else
            -- 手动创建ChatTypeInfo
            RaidNotice_AddMessage(RaidWarningFrame, message, {r=1, g=0.3, b=0.1})
        end
    else
        -- 备用方案：使用UIErrorsFrame
        if UIErrorsFrame then
            UIErrorsFrame:AddMessage(message, 1, 1, 0, 1, duration)
        else
            -- 最后备用方案：直接打印
            print("|cFFFF0000" .. message .. "|r")
        end
    end
    
    addon.Utils:Debug(addon.L("NOTIFICATION_SCREEN_ALERT", message))
end

-- 启用/禁用通知系统
function NotificationSystem:SetEnabled(enabled)
    self.isEnabled = enabled
    addon.Utils:Debug(addon.L("NOTIFICATION_STATUS", enabled and addon.L.STATUS_ENABLED or addon.L.STATUS_DISABLED))
end

-- 获取当前状态
function NotificationSystem:IsEnabled()
    return self.isEnabled
end

-- 设置冷却时间
function NotificationSystem:SetCooldown(cooldown)
    self.notificationCooldown = math.max(0, cooldown or 2)
    addon.Utils:Debug(addon.L("NOTIFICATION_SET_COOLDOWN", self.notificationCooldown))
end

-- 获取可用的发送方式
function NotificationSystem:GetAvailableMethods()
    local methods = {}
    
    -- 检查团队警报
    if UnitInRaid("player") and addon.Utils:CanSendRaidWarning() then
        table.insert(methods, {
            type = "RAID_WARNING",
            name = addon.L.NOTIFICATION_RAID_WARNING,
            priority = addon.NOTIFICATION_PRIORITY.RAID_WARNING
        })
    end
    
    -- 检查团队频道
    if UnitInRaid("player") then
        table.insert(methods, {
            type = "RAID",
            name = addon.L.NOTIFICATION_RAID_CHANNEL,
            priority = addon.NOTIFICATION_PRIORITY.RAID
        })
    end
    
    -- 检查小队频道
    if UnitInParty("player") then
        table.insert(methods, {
            type = "PARTY",
            name = addon.L.NOTIFICATION_PARTY_CHANNEL,
            priority = addon.NOTIFICATION_PRIORITY.PARTY
        })
    end
    
    -- 普通说话始终可用
    table.insert(methods, {
        type = "SAY",
        name = addon.L.NOTIFICATION_SAY_CHANNEL,
        priority = addon.NOTIFICATION_PRIORITY.SAY
    })
    
    return methods
end

-- 测试通知功能
function NotificationSystem:TestNotification()
    local testMessage = string.format("%s %s %s", 
        addon.L.NOTIFICATION_TEST_SENT,
        addon.Utils:GetCurrentZoneName(), 
        addon.Utils:GetTimeString())
    
    local success = self:SendNotification(testMessage)
    
    if success then
        addon.Utils:Info(addon.L.NOTIFICATION_TEST_SENT)
    else
        addon.Utils:Warning(addon.L.NOTIFICATION_TEST_FAILED)
    end
    
    return success
end

-- 获取统计信息
function NotificationSystem:GetStats()
    local stats = {
        enabled = self.isEnabled,
        lastNotificationTime = self.lastNotificationTime,
        cooldownRemaining = math.max(0, self.notificationCooldown - (GetTime() - self.lastNotificationTime)),
        availableMethods = self:GetAvailableMethods()
    }
    
    return stats
end

-- 格式化通知消息
function NotificationSystem:FormatAirdropMessage(zoneName, timeString, triggerType)
    local prefix = addon.L.AIRDROP_DETECTED or "空投箱子"
    local message = string.format("%s %s %s", prefix, zoneName, timeString)
    
    -- 如果需要，可以添加触发类型信息
    if addon.Config:Get("notifications.showTriggerType") then
        local typeText = triggerType == "NPC" and addon.L.NOTIFICATION_TRIGGER_TYPE_NPC or addon.L.NOTIFICATION_TRIGGER_TYPE_VISUAL
        message = message .. " " .. typeText
    end
    
    return message
end