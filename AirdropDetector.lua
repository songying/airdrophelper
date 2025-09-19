-- AirdropHelper Airdrop Detector
-- 空投箱子视觉检测模块

local addonName, addon = ...

addon.AirdropDetector = {}

local AirdropDetector = addon.AirdropDetector

-- 初始化
function AirdropDetector:Initialize()
    -- 重新启用空投检测器，监控"戰爭補給箱"
    self.isEnabled = true -- 重新启用
    self.detectedAirdrops = {}
    self.lastDetectionTime = {}
    self.detectionCooldown = 10 -- 10秒冷却时间
    
    -- 如果HandyNotes可用，使用其检测逻辑 (兼容新旧API)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        self.useHandyNotes = C_AddOns.IsAddOnLoaded("HandyNotes")
    elseif IsAddOnLoaded then
        self.useHandyNotes = IsAddOnLoaded("HandyNotes")
    else
        self.useHandyNotes = false
    end
    
    addon.Utils:Debug(addon.L.DETECTOR_INITIALIZED, self.useHandyNotes and "HandyNotes支持" or "")
end

-- 处理地图标记更新
function AirdropDetector:ProcessVignette(vignetteGUID)
    if not self.isEnabled then
        return
    end
    
    local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
    if not vignetteInfo then
        return
    end
    
    addon.Utils:Debug("检测到地图标记:", vignetteInfo.name, vignetteInfo.vignetteID)
    
    -- 检查是否是空投相关的标记
    if self:IsAirdropVignette(vignetteInfo) then
        self:ProcessAirdropDetection(vignetteInfo, vignetteGUID)
    end
end

-- 判断是否是空投标记
function AirdropDetector:IsAirdropVignette(vignetteInfo)
    if not vignetteInfo then
        return false
    end
    
    -- 首先检查是否是指定的战争补给箱
    local name = vignetteInfo.name or ""
    
    -- 检查是否匹配"戰爭補給箱"和其变体
    if addon.AIRDROP_OBJECTS.BOX_NAMES[name] then
        addon.Utils:Debug("检测到目标箱子:", name)
        return true
    end
    
    -- 检查已知的空投标记ID
    local knownAirdropVignettes = {
        -- 这里需要根据实际游戏数据填入空投相关的vignetteID
        -- 示例：
        -- [5570] = "战争资源空投",
        -- [5571] = "装备空投",
    }
    
    if knownAirdropVignettes[vignetteInfo.vignetteID] then
        return true
    end
    
    -- 检查名称关键词 (作为备用方案)
    local airdropKeywords = {
        "空投", "airdrop", "supply", "资源", "补给", "箱子", "crate"
    }
    
    local lowerName = name:lower()
    
    for _, keyword in ipairs(airdropKeywords) do
        if string.find(lowerName, keyword:lower(), 1, true) then
            return true
        end
    end
    
    return false
end

-- 处理空投检测
function AirdropDetector:ProcessAirdropDetection(vignetteInfo, vignetteGUID)
    local currentTime = GetTime()
    local zoneName = addon.Utils:GetCurrentZoneName()
    
    -- 生成检测ID
    local detectionId = string.format("%s_%s_%d", 
        zoneName, 
        vignetteInfo.vignetteID or "unknown", 
        vignetteInfo.atlasName and string.gsub(vignetteInfo.atlasName, "[^%w]", "") or "atlas")
    
    -- 检查冷却时间
    local lastDetection = self.lastDetectionTime[detectionId] or 0
    if currentTime - lastDetection < self.detectionCooldown then
        addon.Utils:Debug("空投检测冷却中:", detectionId)
        return
    end
    
    self.lastDetectionTime[detectionId] = currentTime
    
    -- 检查是否已有该区域的NPC触发且剩余时间大于5分钟
    if self:HasConflictingNPCTimer(zoneName) then
        addon.Utils:Debug("检测到该区域已有NPC计时器且剩余时间>5分钟，忽略箱子检测")
        return
    end
    
    addon.Utils:Debug("检测到空投:", vignetteInfo.name, "区域:", zoneName)
    
    -- 触发空投事件
    addon:TriggerAirdrop("VISUAL", {
        vignetteInfo = vignetteInfo,
        vignetteGUID = vignetteGUID,
        detectionId = detectionId,
        zoneName = zoneName,
        timeString = addon.Utils:GetTimeString(),
        duration = addon.TIMER_CONFIG.VISUAL_TRIGGER_DURATION
    })
    
    -- 记录检测到的空投
    self.detectedAirdrops[detectionId] = {
        vignetteInfo = vignetteInfo,
        vignetteGUID = vignetteGUID,
        zoneName = zoneName,
        detectionTime = currentTime
    }
end

-- 检查是否有冲突的NPC计时器（剩余时间>=5分钟）
function AirdropDetector:HasConflictingNPCTimer(zoneName)
    if not addon.TimerUI or not addon.TimerUI.timers then
        return false
    end
    
    local currentTime = GetTime()
    local conflictThreshold = addon.AIRDROP_OBJECTS.CONFLICT_THRESHOLD -- 5分钟
    
    for _, timer in ipairs(addon.TimerUI.timers) do
        if timer.zoneName == zoneName and 
           timer.triggerType == "NPC" and 
           not timer.expired then
            
            -- 计算剩余时间
            local elapsed = currentTime - timer.startTime
            local remaining = timer.duration - elapsed
            
            -- 如果剩余时间大于冲突阈值（5分钟），则认为有冲突
            if remaining >= conflictThreshold then
                addon.Utils:Debug("发现冲突的NPC计时器:", timer.zoneName, "剩余时间:", addon.Utils:FormatTime(remaining))
                return true
            end
        end
    end
    
    return false
end

-- 检查是否有近期的NPC触发（保留作为备用方法）
function AirdropDetector:HasRecentNPCTrigger(zoneName)
    if not addon.TimerUI or not addon.TimerUI.timers then
        return false
    end
    
    local currentTime = GetTime()
    local checkWindow = 120 -- 2分钟内的NPC触发
    
    for _, timer in ipairs(addon.TimerUI.timers) do
        if timer.zoneName == zoneName and 
           timer.triggerType == "NPC" and 
           not timer.expired and
           (currentTime - timer.startTime) < checkWindow then
            return true
        end
    end
    
    return false
end

-- 使用HandyNotes的检测逻辑
function AirdropDetector:UseHandyNotesDetection()
    if not self.useHandyNotes or not HandyNotes then
        return
    end
    
    -- 这里可以扩展HandyNotes的检测逻辑
    -- 需要根据HandyNotes的实际API来实现
    addon.Utils:Debug("尝试使用HandyNotes检测逻辑")
end

-- 获取玩家附近的对象
function AirdropDetector:ScanNearbyObjects()
    if not self.isEnabled then
        return
    end
    
    local objects = {}
    
    -- 扫描附近的游戏对象 (注意: GetObjectName在11.2中可能不可用，此功能仅作示例)
    -- 实际实现需要使用其他方法，如C_GameObjects或地图标记API
    -- for i = 1, 40 do
    --     local objectName = GetObjectName("target" .. i)
    --     if objectName then
    --         -- 检查是否是空投相关对象
    --         if self:IsAirdropObject(objectName) then
    --             table.insert(objects, {
    --                 name = objectName,
    --                 index = i,
    --                 scanTime = GetTime()
    --             })
    --         end
    --     end
    -- end
    
    return objects
end

-- 判断是否是空投对象
function AirdropDetector:IsAirdropObject(objectName)
    if not objectName then
        return false
    end
    
    -- 首先检查是否是精确匹配的戰爭補給箱
    if addon.AIRDROP_OBJECTS.BOX_NAMES[objectName] then
        return true
    end
    
    -- 备用的关键词匹配
    local airdropObjectNames = {
        "补给箱", "空投箱", "资源箱", "战争资源", "戰爭補給箱",
        "supply crate", "airdrop", "resource cache", "war supply crate"
    }
    
    local name = objectName:lower()
    
    for _, keyword in ipairs(airdropObjectNames) do
        if string.find(name, keyword:lower(), 1, true) then
            return true
        end
    end
    
    return false
end

-- 区域变化处理
function AirdropDetector:OnZoneChanged(newZone, oldZone)
    -- 清理旧区域的检测记录
    local toRemove = {}
    for detectionId, detection in pairs(self.detectedAirdrops) do
        if detection.zoneName == oldZone then
            table.insert(toRemove, detectionId)
        end
    end
    
    for _, detectionId in ipairs(toRemove) do
        self.detectedAirdrops[detectionId] = nil
    end
    
    -- 清理冷却记录
    self.lastDetectionTime = {}
    
    addon.Utils:Debug("空投检测器: 区域变化，清理记录")
end

-- 启用/禁用检测
function AirdropDetector:SetEnabled(enabled)
    self.isEnabled = enabled
    addon.Utils:Debug("空投检测器状态:", enabled and "启用" or "禁用")
end

-- 获取当前状态
function AirdropDetector:IsEnabled()
    return self.isEnabled
end

-- 设置检测冷却时间
function AirdropDetector:SetDetectionCooldown(cooldown)
    self.detectionCooldown = math.max(1, cooldown or 10)
    addon.Utils:Debug("设置检测冷却时间:", self.detectionCooldown, "秒")
end

-- 手动扫描空投
function AirdropDetector:ManualScan()
    if not self.isEnabled then
        return {}
    end
    
    addon.Utils:Debug("开始手动扫描空投")
    
    local results = {}
    
    -- 扫描地图标记
    local vignetteGUIDs = C_VignetteInfo.GetVignettes()
    for _, vignetteGUID in ipairs(vignetteGUIDs) do
        local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
        if vignetteInfo and self:IsAirdropVignette(vignetteInfo) then
            table.insert(results, {
                type = "vignette",
                data = vignetteInfo,
                guid = vignetteGUID
            })
        end
    end
    
    -- 扫描附近对象
    local nearbyObjects = self:ScanNearbyObjects()
    for _, obj in ipairs(nearbyObjects) do
        table.insert(results, {
            type = "object",
            data = obj
        })
    end
    
    addon.Utils:Debug("手动扫描完成，找到", #results, "个潜在空投")
    
    return results
end

-- 获取统计信息
function AirdropDetector:GetStats()
    local stats = {
        enabled = self.isEnabled,
        useHandyNotes = self.useHandyNotes,
        detectedCount = 0,
        activeDetections = 0,
        detectionCooldown = self.detectionCooldown
    }
    
    local currentTime = GetTime()
    
    for _, detection in pairs(self.detectedAirdrops) do
        stats.detectedCount = stats.detectedCount + 1
        
        -- 检查是否还在活跃状态（5分钟内）
        if currentTime - detection.detectionTime < 300 then
            stats.activeDetections = stats.activeDetections + 1
        end
    end
    
    return stats
end

-- 清理过期的检测记录
function AirdropDetector:CleanupExpiredDetections()
    local currentTime = GetTime()
    local expirationTime = 600 -- 10分钟过期
    local toRemove = {}
    
    for detectionId, detection in pairs(self.detectedAirdrops) do
        if currentTime - detection.detectionTime > expirationTime then
            table.insert(toRemove, detectionId)
        end
    end
    
    for _, detectionId in ipairs(toRemove) do
        self.detectedAirdrops[detectionId] = nil
    end
    
    if #toRemove > 0 then
        addon.Utils:Debug("清理", #toRemove, "个过期的检测记录")
    end
end