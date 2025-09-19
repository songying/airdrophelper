-- AirdropHelper Configuration
-- 配置管理文件

local addonName, addon = ...

-- 默认配置
local defaultConfig = {
    enabled = true,
    debugMode = false, -- 关闭调试模式,
    ui = {
        locked = false,
        position = {
            point = "CENTER",
            x = 0,
            y = 0
        },
        scale = 1.0,
        alpha = 1.0
    },
    notifications = {
        enabled = true,
        useRaidWarning = true,
        useSound = true,
        soundFile = "Interface\\AddOns\\AirdropHelper\\Sounds\\alert.ogg"
    },
    timers = {
        npcDuration = 18 * 60 + 12, -- 18分12秒
        visualDuration = 16 * 60,
        maxTimers = 10
    },
    sync = {
        enabled = true,
        shareWithGuild = false, -- 禁用公会同步
        shareWithRaid = true,
        shareWithParty = true
    },
    npcKeywords = {
        ["魯夫厄斯"] = { "我在這附近", "附近有一箱資源", "機不可失", "附近似乎有寶藏" },
        ["瑪莉希亞"] = { "附近有資源", "準備戰鬥" }
    },
    autoBroadcast = {
        enabled = true -- 默认开启自动播报
    }
}

-- 配置管理器
addon.Config = {}

function addon.Config:Init()
    -- 初始化配置数据库
    if not AirdropHelperDB then
        AirdropHelperDB = {}
    end
    
    -- 合并默认配置
    for key, value in pairs(defaultConfig) do
        if AirdropHelperDB[key] == nil then
            AirdropHelperDB[key] = self:DeepCopy(value)
        end
    end
    
    if addon.DEBUG then
        print("AirdropHelper: 配置已初始化")
    end
end

function addon.Config:Get(path)
    -- 确保数据库已初始化
    if not AirdropHelperDB then
        return nil
    end
    
    local keys = {strsplit(".", path)}
    local current = AirdropHelperDB
    
    for _, key in ipairs(keys) do
        if not current or current[key] == nil then
            return nil
        end
        current = current[key]
    end
    
    return current
end

function addon.Config:Set(path, value)
    -- 确保数据库已初始化
    if not AirdropHelperDB then
        return
    end
    
    local keys = {strsplit(".", path)}
    local current = AirdropHelperDB
    
    for i = 1, #keys - 1 do
        local key = keys[i]
        if current[key] == nil then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[keys[#keys]] = value
end

function addon.Config:DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for k, v in next, original, nil do
            copy[addon.Config:DeepCopy(k)] = addon.Config:DeepCopy(v)
        end
    else
        copy = original
    end
    return copy
end

function addon.Config:Reset()
    AirdropHelperDB = self:DeepCopy(defaultConfig)
    if addon.DEBUG then
        print("AirdropHelper: 配置已重置为默认值")
    end
end

function addon.Config:GetNPCKeywords()
    return self:Get("npcKeywords") or addon.NPC_KEYWORDS
end

function addon.Config:IsEnabled()
    return self:Get("enabled") ~= false
end

function addon.Config:IsNotificationEnabled()
    return self:Get("notifications.enabled") ~= false
end

function addon.Config:IsSyncEnabled()
    return self:Get("sync.enabled") ~= false
end