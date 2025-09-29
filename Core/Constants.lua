-- AirdropHelper Constants
-- 常數定義文件

local addonName, addon = ...

-- 外掛版本資訊
addon.VERSION = "1.0.0"
addon.BUILD = "110200"

-- 事件常量
addon.EVENTS = {
    CHAT_MSG_MONSTER_SAY = "CHAT_MSG_MONSTER_SAY",
    ADDON_LOADED = "ADDON_LOADED",
    PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD",
    ZONE_CHANGED_NEW_AREA = "ZONE_CHANGED_NEW_AREA",
    VIGNETTE_MINIMAP_UPDATED = "VIGNETTE_MINIMAP_UPDATED"
}

-- NPC关键词配置
addon.NPC_KEYWORDS = {
    ["魯夫厄斯"] = { "我在這附近", "附近有一箱資源", "機不可失", "附近似乎有寶藏" },
    ["瑪莉希亞"] = { "附近有資源", "準備戰鬥" }
}

-- 倒计时配置
addon.TIMER_CONFIG = {
    NPC_TRIGGER_DURATION = 18 * 60 + 12, -- 18分12秒 (1092秒)
    VISUAL_TRIGGER_DURATION = 17 * 60, -- 17分钟 (秒)
    WARNING_TIME = 8 * 60, -- 8分钟警告 (秒)
    CRITICAL_TIME = 2 * 60, -- 2分钟紧急 (秒)
    MAX_TIMERS = 10 -- 最大计时器数量
}

-- UI配置
addon.UI_CONFIG = {
    FRAME_WIDTH = 300, -- 再增加20像素宽度以完整显示标题
    PROGRESS_BAR_HEIGHT = 20,
    PROGRESS_BAR_SPACING = 2,
    FRAME_PADDING = 10
}

-- 颜色配置
addon.COLORS = {
    GREEN = {0, 1, 0, 1}, -- 绿色
    YELLOW = {1, 1, 0, 1}, -- 黄色
    RED = {1, 0, 0, 1}, -- 红色
    WHITE = {1, 1, 1, 1} -- 白色文字
}

-- 通知优先级
addon.NOTIFICATION_PRIORITY = {
    RAID_WARNING = 1, -- 团队警报
    RAID = 2, -- 团队频道
    PARTY = 3, -- 小队频道
    SAY = 4 -- 普通说话
}

-- 同步配置
addon.SYNC_CONFIG = {
    PREFIX = "AirdropHelper",
    VERSION = 1,
    CHANNEL_TYPES = {"RAID", "PARTY"} -- 移除GUILD，只在队伍/团队间同步
}

-- 调试模式默认关闭，可通过配置打开
addon.DEBUG = false

-- 空投箱子相关配置
addon.AIRDROP_OBJECTS = {
    -- 箱子名称匹配 (支持多语言)
    BOX_NAMES = {
        ["戰爭補給箱"] = true,
        ["War Supply Crate"] = true,
        ["战争补给箱"] = true
    },
    -- 冲突检测设置
    CONFLICT_THRESHOLD = 5 * 60, -- 5分钟，如果已有NPC计时器且剩余时间大于此值，则不触发箱子检测
}

-- 本地化字符串将在 Localization.lua 中定义