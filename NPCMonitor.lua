-- AirdropHelper NPC Monitor
-- NPC对话监控模块

local addonName, addon = ...

addon.NPCMonitor = {}

local NPCMonitor = addon.NPCMonitor

-- 初始化
function NPCMonitor:Initialize()
    self.isEnabled = true
    self.lastTriggerTime = {}
    self.triggerCooldown = 5 -- 5秒冷却时间，防止重复触发
    
    addon.Utils:Debug(addon.L.NPC_MONITOR_INITIALIZED)
end

-- 处理NPC消息
function NPCMonitor:ProcessNPCMessage(message, sender)
    if not self.isEnabled then
        return
    end
    
    -- 获取NPC关键词配置
    local npcKeywords = addon.Config:GetNPCKeywords()
    
    -- 检查发送者是否在监控列表中
    if not npcKeywords[sender] then
        addon.Utils:Debug(addon.L("NPC_NOT_MONITORED", sender))
        return
    end
    
    -- 检查消息是否包含关键词
    local containsKeyword, matchedKeyword = addon.Utils:ContainsKeyword(message, npcKeywords[sender])
    
    if not containsKeyword then
        addon.Utils:Debug(addon.L("NPC_NO_KEYWORDS", message))
        return
    end
    
    -- 检查冷却时间
    local currentTime = GetTime()
    local lastTrigger = self.lastTriggerTime[sender] or 0
    
    if currentTime - lastTrigger < self.triggerCooldown then
        addon.Utils:Debug(addon.L("NPC_COOLDOWN", sender, matchedKeyword))
        return
    end
    
    -- 记录触发时间
    self.lastTriggerTime[sender] = currentTime
    
    addon.Utils:Debug(addon.L("NPC_TRIGGERED", sender, matchedKeyword))
    
    -- 触发空投事件
    addon:TriggerAirdrop("NPC", {
        npcName = sender,
        keyword = matchedKeyword,
        message = message,
        zoneName = addon.Utils:GetCurrentZoneName(),
        timeString = addon.Utils:GetTimeString(),
        duration = addon.TIMER_CONFIG.NPC_TRIGGER_DURATION
    })
end

-- 区域变化处理
function NPCMonitor:OnZoneChanged(newZone, oldZone)
    -- 清理旧区域的冷却记录
    self.lastTriggerTime = {}
    addon.Utils:Debug(addon.L.NPC_ZONE_CHANGED)
end

-- 启用/禁用监控
function NPCMonitor:SetEnabled(enabled)
    self.isEnabled = enabled
    addon.Utils:Debug("NPC监控器状态:", enabled and addon.L.STATUS_ENABLED or addon.L.STATUS_DISABLED)
end

-- 获取当前状态
function NPCMonitor:IsEnabled()
    return self.isEnabled
end

-- 添加新的NPC关键词
function NPCMonitor:AddNPCKeywords(npcName, keywords)
    local currentKeywords = addon.Config:GetNPCKeywords()
    currentKeywords[npcName] = keywords
    addon.Config:Set("npcKeywords", currentKeywords)
    addon.Utils:Debug(addon.L("NPC_ADD_KEYWORDS", npcName, table.concat(keywords, ", ")))
end

-- 移除NPC关键词
function NPCMonitor:RemoveNPCKeywords(npcName)
    local currentKeywords = addon.Config:GetNPCKeywords()
    currentKeywords[npcName] = nil
    addon.Config:Set("npcKeywords", currentKeywords)
    addon.Utils:Debug(addon.L("NPC_REMOVE_KEYWORDS", npcName))
end

-- 获取所有监控的NPC列表
function NPCMonitor:GetMonitoredNPCs()
    local npcKeywords = addon.Config:GetNPCKeywords()
    local npcList = {}
    
    for npcName, keywords in pairs(npcKeywords) do
        table.insert(npcList, {
            name = npcName,
            keywords = keywords,
            keywordCount = #keywords
        })
    end
    
    return npcList
end

-- 设置触发冷却时间
function NPCMonitor:SetTriggerCooldown(cooldown)
    self.triggerCooldown = math.max(1, cooldown or 5)
    addon.Utils:Debug(addon.L("NPC_SET_COOLDOWN", self.triggerCooldown))
end

-- 手动清理冷却记录
function NPCMonitor:ClearCooldowns()
    self.lastTriggerTime = {}
    addon.Utils:Debug(addon.L.NPC_CLEAR_COOLDOWNS)
end

-- 检查NPC是否在冷却中
function NPCMonitor:IsNPCOnCooldown(npcName)
    local lastTrigger = self.lastTriggerTime[npcName] or 0
    local currentTime = GetTime()
    local remainingCooldown = self.triggerCooldown - (currentTime - lastTrigger)
    
    if remainingCooldown > 0 then
        return true, remainingCooldown
    end
    
    return false, 0
end

-- 获取统计信息
function NPCMonitor:GetStats()
    local stats = {
        enabled = self.isEnabled,
        monitoredNPCs = 0,
        totalKeywords = 0,
        triggersToday = 0,
        lastTriggerTime = 0
    }
    
    local npcKeywords = addon.Config:GetNPCKeywords()
    for npcName, keywords in pairs(npcKeywords) do
        stats.monitoredNPCs = stats.monitoredNPCs + 1
        stats.totalKeywords = stats.totalKeywords + #keywords
    end
    
    for npcName, triggerTime in pairs(self.lastTriggerTime) do
        if triggerTime > stats.lastTriggerTime then
            stats.lastTriggerTime = triggerTime
        end
    end
    
    return stats
end