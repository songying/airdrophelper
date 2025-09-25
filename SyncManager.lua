-- AirdropHelper Sync Manager
-- 玩家間資訊同步模組

local addonName, addon = ...

addon.SyncManager = {}

local SyncManager = addon.SyncManager

-- 初始化
function SyncManager:Initialize()
    self.isEnabled = addon.Config:IsSyncEnabled()
    self.syncData = {}
    self.lastSyncTime = {}
    self.syncCooldown = 3 -- 3秒同步冷却时间
    
    -- 註冊通信前綴
    C_ChatInfo.RegisterAddonMessagePrefix(addon.SYNC_CONFIG.PREFIX)
    
    -- 註冊事件
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function(self, event, ...)
        SyncManager:OnAddonMessage(...)
    end)
    
    self.frame = frame
    
    addon.Utils:Debug(addon.L.SYNC_MANAGER_INITIALIZED)
end

-- 处理插件消息
function SyncManager:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= addon.SYNC_CONFIG.PREFIX then
        return
    end

    if sender == UnitName("player") then
        return -- 忽略自己的消息
    end

    -- 已禁用接收同步信息，防止跨伺服器干擾
    addon.Utils:Debug("已禁用接收同步信息，防止跨伺服器干擾:", sender, channel)
    return

    --[[
    -- 以下代码被禁用 - 不再接收其他插件的同步数据
    -- 验证发送者是否在同一队伍/团队中
    if not self:IsValidSender(sender, channel) then
        addon.Utils:Debug(addon.L("SYNC_IGNORE_MESSAGE", sender, channel))
        return
    end

    addon.Utils:Debug(addon.L("SYNC_RECEIVE_MESSAGE", sender, channel, string.sub(message, 1, 50)))

    local success, data = self:DecodeMessage(message)
    if not success then
        addon.Utils:Debug(addon.L("SYNC_DECODE_FAILED", message))
        return
    end

    self:ProcessSyncMessage(data, sender, channel)
    --]]
end

-- 验证发送者是否是有效的队伍/团队成员
function SyncManager:IsValidSender(sender, channel)
    -- 根据频道类型验证
    if channel == "RAID" then
        -- 验证是否在同一团队中
        if UnitInRaid("player") then
            for i = 1, GetNumGroupMembers() do
                local name = GetRaidRosterInfo(i)
                if name and name == sender then
                    return true
                end
            end
        end
        return false
    elseif channel == "PARTY" then
        -- 验证是否在同一小队中
        if UnitInParty("player") and not UnitInRaid("player") then
            for i = 1, GetNumSubgroupMembers() do
                local unit = "party" .. i
                local name = UnitName(unit)
                if name and name == sender then
                    return true
                end
            end
        end
        return false
    else
        -- 其他频道一律拒绝
        return false
    end
end

-- 分享空投信息
function SyncManager:ShareAirdrop(airdropData)
    if not self.isEnabled then
        addon.Utils:Debug(addon.L.SYNC_DISABLED)
        return
    end
    
    -- 检查是否在队伍/团队中，单人时不同步
    if not UnitInParty("player") and not UnitInRaid("player") then
        addon.Utils:Debug(addon.L.SYNC_NOT_IN_GROUP)
        return
    end
    
    -- 检查冷却时间
    local currentTime = GetTime()
    local dataKey = string.format("%s_%s", airdropData.zoneName, airdropData.triggerType)
    local lastSync = self.lastSyncTime[dataKey] or 0
    
    if currentTime - lastSync < self.syncCooldown then
        addon.Utils:Debug(addon.L("SYNC_COOLDOWN", dataKey))
        return
    end
    
    self.lastSyncTime[dataKey] = currentTime
    
    -- 准备同步数据
    local syncMessage = {
        type = "AIRDROP",
        version = addon.SYNC_CONFIG.VERSION,
        timestamp = GetServerTime(),
        sender = UnitName("player"),
        data = {
            zoneName = airdropData.zoneName,
            timeString = airdropData.timeString,
            triggerType = airdropData.triggerType,
            duration = airdropData.duration,
            position = airdropData.position or {addon.Utils:GetPlayerPosition()}
        }
    }
    
    local encodedMessage = self:EncodeMessage(syncMessage)
    if not encodedMessage then
        addon.Utils:Warning(addon.L.SYNC_ENCODE_FAILED)
        return
    end
    
    -- 发送到不同频道
    self:SendToChannels(encodedMessage)
    
    addon.Utils:Debug(addon.L("SYNC_PROCESSING_AIRDROP", airdropData.zoneName, airdropData.triggerType))
end

-- 处理同步消息
function SyncManager:ProcessSyncMessage(data, sender, channel)
    if not data or data.type ~= "AIRDROP" then
        return
    end
    
    -- 检查版本兼容性
    if data.version ~= addon.SYNC_CONFIG.VERSION then
        addon.Utils:Debug(addon.L("SYNC_VERSION_INCOMPATIBLE", data.version))
        return
    end
    
    -- 检查时间戳，忽略过旧的消息
    local messageAge = GetServerTime() - (data.timestamp or 0)
    if messageAge > 300 then -- 5分钟前的消息
        addon.Utils:Debug(addon.L("SYNC_MESSAGE_TOO_OLD", messageAge))
        return
    end
    
    local airdropData = data.data
    if not airdropData or not airdropData.zoneName then
        return
    end
    
    -- 检查是否已处理过相同的空投
    local syncKey = string.format("%s_%s_%d_%s", 
        airdropData.zoneName, 
        airdropData.triggerType, 
        data.timestamp, 
        sender)
    
    if self.syncData[syncKey] then
        addon.Utils:Debug(addon.L("SYNC_DUPLICATE_MESSAGE", syncKey))
        return
    end
    
    self.syncData[syncKey] = {
        data = airdropData,
        sender = sender,
        receiveTime = GetTime(),
        processed = false
    }
    
    -- 处理接收到的空投信息
    self:HandleReceivedAirdrop(airdropData, sender)
    
    self.syncData[syncKey].processed = true
    
    addon.Utils:Debug(addon.L("SYNC_PROCESSED", airdropData.zoneName, sender))
end

-- 处理接收到的空投信息
function SyncManager:HandleReceivedAirdrop(airdropData, sender)
    addon.Utils:Debug(addon.L("SYNC_PROCESSING_AIRDROP", sender, airdropData.zoneName))
    
    -- 检查是否在同一区域
    local currentZone = addon.Utils:GetCurrentZoneName()
    if airdropData.zoneName ~= currentZone then
        addon.Utils:Debug(addon.L("SYNC_DIFFERENT_ZONE", airdropData.zoneName, currentZone))
        return
    end
    
    -- 检查是否已有相同的计时器
    if self:HasSimilarTimer(airdropData) then
        addon.Utils:Debug(addon.L.SYNC_SIMILAR_TIMER)
        return
    end
    
    -- 创建同步的计时器
    if addon.TimerUI then
        local timerData = {
            id = addon.Utils:GenerateID(),
            zoneName = airdropData.zoneName,
            startTime = GetTime() - (airdropData.elapsedTime or 0),
            duration = airdropData.duration,
            triggerType = airdropData.triggerType .. "_SYNC",
            triggerTime = airdropData.triggerTime or date("%H:%M"), -- 使用同步数据中的触发时间或当前时间
            expired = false,
            fromSync = true,
            sender = sender
        }
        
        addon.TimerUI:AddTimer(timerData)
    end
    
    -- 发送本地通知
    if addon.NotificationSystem then
        local message = addon.L("SYNC_MESSAGE", addon.L.AIRDROP_DETECTED, airdropData.zoneName, sender)
        addon.NotificationSystem:SendLocalNotification(message, addon.COLORS.YELLOW)
    end
end

-- 检查是否有相似的计时器
function SyncManager:HasSimilarTimer(airdropData)
    if not addon.TimerUI or not addon.TimerUI.timers then
        return false
    end
    
    local currentTime = GetTime()
    local timeThreshold = 60 -- 1分钟内的相似计时器
    
    for _, timer in ipairs(addon.TimerUI.timers) do
        if timer.zoneName == airdropData.zoneName and
           not timer.expired and
           math.abs((currentTime - timer.startTime) - (airdropData.elapsedTime or 0)) < timeThreshold then
            return true
        end
    end
    
    return false
end

-- 发送到各个频道
function SyncManager:SendToChannels(message)
    local channels = self:GetAvailableChannels()
    local sent = false
    
    for _, channelInfo in ipairs(channels) do
        if self:SendToChannel(message, channelInfo.type, channelInfo.target) then
            sent = true
            break -- 只发送到第一个可用频道，避免重复
        end
    end
    
    if not sent then
        addon.Utils:Debug(addon.L.SYNC_NO_CHANNELS)
    end
    
    return sent
end

-- 获取可用的同步频道
function SyncManager:GetAvailableChannels()
    local channels = {}
    
    -- 只在队伍/团队间同步，不与公会同步
    -- 团队频道优先
    if addon.Config:Get("sync.shareWithRaid") and UnitInRaid("player") then
        table.insert(channels, {type = "RAID", target = nil, priority = 1})
    end
    
    -- 小队频道（只有在不在团队中时才使用）
    if addon.Config:Get("sync.shareWithParty") and UnitInParty("player") and not UnitInRaid("player") then
        table.insert(channels, {type = "PARTY", target = nil, priority = 2})
    end
    
    -- 移除公会频道同步，注释掉
    -- if addon.Config:Get("sync.shareWithGuild") and IsInGuild() then
    --     table.insert(channels, {type = "GUILD", target = nil, priority = 3})
    -- end
    
    -- 按优先级排序
    table.sort(channels, function(a, b) return a.priority < b.priority end)
    
    return channels
end

-- 发送到指定频道
function SyncManager:SendToChannel(message, channelType, target)
    local success = pcall(C_ChatInfo.SendAddonMessage, addon.SYNC_CONFIG.PREFIX, message, channelType, target)
    
    if success then
        addon.Utils:Debug(addon.L("SYNC_MESSAGE_SENT", channelType))
    else
        addon.Utils:Debug(addon.L("SYNC_MESSAGE_FAILED", channelType))
    end
    
    return success
end

-- 编码消息
function SyncManager:EncodeMessage(data)
    local success, encoded = pcall(function()
        -- 简单的JSON编码（可以使用更复杂的编码方式）
        local str = ""
        str = str .. "{"
        str = str .. '"type":"' .. (data.type or "") .. '",'
        str = str .. '"version":' .. (data.version or 1) .. ','
        str = str .. '"timestamp":' .. (data.timestamp or 0) .. ','
        str = str .. '"sender":"' .. (data.sender or "") .. '",'
        str = str .. '"data":{'
        
        if data.data then
            local dataStr = ""
            if data.data.zoneName then
                dataStr = dataStr .. '"zoneName":"' .. data.data.zoneName .. '",'
            end
            if data.data.timeString then
                dataStr = dataStr .. '"timeString":"' .. data.data.timeString .. '",'
            end
            if data.data.triggerType then
                dataStr = dataStr .. '"triggerType":"' .. data.data.triggerType .. '",'
            end
            if data.data.duration then
                dataStr = dataStr .. '"duration":' .. data.data.duration .. ','
            end
            
            -- 移除最后的逗号
            if dataStr:sub(-1) == "," then
                dataStr = dataStr:sub(1, -2)
            end
            
            str = str .. dataStr
        end
        
        str = str .. "}}"
        
        return str
    end)
    
    if not success then
        addon.Utils:Warning(addon.L("SYNC_ENCODE_FAILED", encoded))
        return nil
    end
    
    return encoded
end

-- 解码消息
function SyncManager:DecodeMessage(message)
    local success, data = pcall(function()
        -- 简单的JSON解析（生产环境建议使用更健壮的解析器）
        local decoded = {}
        
        -- 提取基本字段
        decoded.type = message:match('"type":"([^"]*)"')
        decoded.version = tonumber(message:match('"version":([^,}]*)'))
        decoded.timestamp = tonumber(message:match('"timestamp":([^,}]*)'))
        decoded.sender = message:match('"sender":"([^"]*)"')
        
        -- 提取data字段
        local dataSection = message:match('"data":{([^}]*)}')
        if dataSection then
            decoded.data = {}
            decoded.data.zoneName = dataSection:match('"zoneName":"([^"]*)"')
            decoded.data.timeString = dataSection:match('"timeString":"([^"]*)"')
            decoded.data.triggerType = dataSection:match('"triggerType":"([^"]*)"')
            decoded.data.duration = tonumber(dataSection:match('"duration":([^,}]*)'))
        end
        
        return decoded
    end)
    
    return success, data
end

-- 启用/禁用同步
function SyncManager:SetEnabled(enabled)
    self.isEnabled = enabled
    addon.Config:Set("sync.enabled", enabled)
    addon.Utils:Debug(addon.L("SYNC_STATUS", enabled and addon.L.STATUS_ENABLED or addon.L.STATUS_DISABLED))
end

-- 获取当前状态
function SyncManager:IsEnabled()
    return self.isEnabled
end

-- 清理过期的同步数据
function SyncManager:CleanupExpiredSyncData()
    local currentTime = GetTime()
    local expirationTime = 600 -- 10分钟过期
    local toRemove = {}
    
    for syncKey, syncInfo in pairs(self.syncData) do
        if currentTime - syncInfo.receiveTime > expirationTime then
            table.insert(toRemove, syncKey)
        end
    end
    
    for _, syncKey in ipairs(toRemove) do
        self.syncData[syncKey] = nil
    end
    
    if #toRemove > 0 then
        addon.Utils:Debug(addon.L("SYNC_CLEANUP_DATA", #toRemove))
    end
end

-- 获取统计信息
function SyncManager:GetStats()
    local stats = {
        enabled = self.isEnabled,
        syncDataCount = 0,
        lastSyncTime = 0,
        availableChannels = self:GetAvailableChannels()
    }
    
    for _, syncInfo in pairs(self.syncData) do
        stats.syncDataCount = stats.syncDataCount + 1
        if syncInfo.receiveTime > stats.lastSyncTime then
            stats.lastSyncTime = syncInfo.receiveTime
        end
    end
    
    return stats
end

-- 测试同步功能
function SyncManager:TestSync()
    if not self.isEnabled then
        addon.Utils:Warning(addon.L.SYNC_NOT_ENABLED)
        return false
    end
    
    local testData = {
        zoneName = "测试区域",
        timeString = addon.Utils:GetTimeString(),
        triggerType = "TEST",
        duration = 60
    }
    
    self:ShareAirdrop(testData)
    addon.Utils:Info(addon.L.SYNC_TEST_SENT)
    return true
end