-- AirdropHelper Utilities
-- 工具函数文件

local addonName, addon = ...

addon.Utils = {}

-- 获取当前时间字符串 (HH:MM格式)
function addon.Utils:GetTimeString()
    local hour, minute = GetGameTime()
    return string.format("%02d:%02d", hour, minute)
end

-- 获取当前地图名称
function addon.Utils:GetCurrentZoneName()
    return GetZoneText() or GetRealZoneText() or "未知区域"
end

-- 检查字符串是否包含关键词
function addon.Utils:ContainsKeyword(text, keywords)
    if not text or not keywords then
        return false
    end
    
    for _, keyword in ipairs(keywords) do
        if string.find(text, keyword, 1, true) then
            return true, keyword
        end
    end
    
    return false
end

-- 格式化时间显示 (MMmSSs格式，与广播格式保持一致)
function addon.Utils:FormatTime(seconds)
    if seconds < 0 then
        local absSeconds = math.abs(seconds)
        local minutes = math.floor(absSeconds / 60)
        local secs = absSeconds % 60
        return string.format("-%dm%02ds", minutes, secs)
    else
        local minutes = math.floor(seconds / 60)
        local secs = seconds % 60
        return string.format("%dm%02ds", minutes, secs)
    end
end

-- 获取玩家当前状态 (团队/小队/单人)
function addon.Utils:GetPlayerStatus()
    if UnitInRaid("player") then
        return "RAID"
    elseif UnitInParty("player") then
        return "PARTY"
    else
        return "SOLO"
    end
end

-- 检查是否开启战争模式
function addon.Utils:IsWarModeEnabled()
    -- 使用C_PvP.IsWarModeDesired()检查战争模式状态
    if C_PvP and C_PvP.IsWarModeDesired then
        return C_PvP.IsWarModeDesired()
    end
    -- 备用检查方法
    return GetZonePVPInfo() == "combat"
end

-- 检查是否有团队警报权限
function addon.Utils:CanSendRaidWarning()
    return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

-- 安全发送聊天消息
function addon.Utils:SendChatMessage(message, chatType, channel)
    if not message or message == "" then
        return false
    end
    
    -- 防止消息过长
    if string.len(message) > 255 then
        message = string.sub(message, 1, 252) .. "..."
    end
    
    local success = pcall(SendChatMessage, message, chatType, nil, channel)
    return success
end

-- 调试输出
function addon.Utils:Debug(...)
    if addon.DEBUG or addon.Config:Get("debugMode") then
        print("AirdropHelper Debug:", ...)
    end
end

-- 错误处理
function addon.Utils:Error(...)
    print("|cFFFF0000AirdropHelper Error:|r", ...)
end

-- 信息输出
function addon.Utils:Info(...)
    print("|cFF00FF00AirdropHelper:|r", ...)
end

-- 警告输出
function addon.Utils:Warning(...)
    print("|cFFFFFF00AirdropHelper Warning:|r", ...)
end

-- 检查插件依赖
function addon.Utils:CheckDependencies()
    local missingDeps = {}
    
    -- 检查可选依赖 (兼容新旧API)
    local isHandyNotesLoaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        isHandyNotesLoaded = C_AddOns.IsAddOnLoaded("HandyNotes")
    elseif IsAddOnLoaded then
        isHandyNotesLoaded = IsAddOnLoaded("HandyNotes")
    end
    
    if not isHandyNotesLoaded then
        table.insert(missingDeps, "HandyNotes (可选)")
    end
    
    return missingDeps
end

-- 播放声音
function addon.Utils:PlaySound(soundFile)
    if addon.Config:Get("notifications.useSound") then
        local customSound = addon.Config:Get("notifications.soundFile")
        if customSound and customSound ~= "" then
            PlaySoundFile(customSound)
        else
            PlaySound(SOUNDKIT.RAID_WARNING)
        end
    end
end

-- 生成唯一ID
function addon.Utils:GenerateID()
    return string.format("%s_%d_%d", 
        UnitName("player") or "Unknown", 
        GetServerTime(), 
        math.random(1000, 9999))
end

-- 计算两个位置之间的距离
function addon.Utils:CalculateDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- 获取玩家坐标
function addon.Utils:GetPlayerPosition()
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local position = C_Map.GetPlayerMapPosition(mapID, "player")
        if position then
            return position.x, position.y, mapID
        end
    end
    return nil, nil, nil
end

-- 颜色代码转换
function addon.Utils:ColorText(text, r, g, b)
    if type(r) == "table" then
        return string.format("|cFF%02x%02x%02x%s|r", 
            r[1] * 255, r[2] * 255, r[3] * 255, text)
    else
        return string.format("|cFF%02x%02x%02x%s|r", 
            (r or 1) * 255, (g or 1) * 255, (b or 1) * 255, text)
    end
end