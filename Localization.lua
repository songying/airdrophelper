-- AirdropHelper Localization
-- 国际化本地化文件

local addonName, addon = ...

-- 获取客户端语言
local locale = GetLocale()

-- 本地化字符串表
local L = {}

-- 默认语言（英文）
local defaultStrings = {
    -- 基本信息
    ["ADDON_NAME"] = "AirdropHelper",
    ["ADDON_LOADED"] = "AirdropHelper v%s loaded",
    ["ADDON_DISABLED"] = "Plugin disabled",
    ["ADDON_ACTIVATED"] = "War Mode enabled, Airdrop Helper activated",
    ["ADDON_DEACTIVATED"] = "War Mode disabled, Airdrop Helper hidden",
    
    -- 空投相关
    ["AIRDROP_DETECTED"] = "Airdrop",
    ["AIRDROP_TIMER_EXPIRED"] = "Airdrop timer expired: %s",
    ["AIRDROP_TEST_TRIGGERED"] = "Test airdrop triggered",
    ["AIRDROP_PLUGIN_INACTIVE"] = "Plugin inactive - War Mode required",
    
    -- 计时器相关
    ["TIMER_TITLE"] = "Airdrop Timers",
    ["TIMER_MAX_REACHED"] = "Maximum timer limit reached (%d timers)",
    ["TIMER_UPDATED"] = "Updated timer for [%s], type: %s",
    ["TIMER_ADDED"] = "Added timer for [%s], type: %s",
    ["TIMER_REMOVED"] = "Removed timer: %s",
    ["TIMER_NOT_FOUND"] = "Timer not found: %s",
    
    -- 状态信息
    ["STATUS_WAR_MODE"] = "War Mode: %s",
    ["STATUS_PLUGIN"] = "Plugin Status: %s",
    ["STATUS_TOTAL_TIMERS"] = "Total Timers: %d",
    ["STATUS_ZONE_TIMERS"] = "  %s: %d timer(s) %s",
    ["STATUS_CURRENT_MAP"] = "(current map)",
    ["STATUS_NO_TIMERS"] = "No active timers",
    ["STATUS_ENABLED"] = "Enabled",
    ["STATUS_DISABLED"] = "Disabled",
    ["STATUS_ACTIVE"] = "Active",
    ["STATUS_INACTIVE"] = "Inactive",
    ["STATUS_ON"] = "On",
    ["STATUS_OFF"] = "Off",
    
    -- 命令帮助
    ["HELP_TITLE"] = "AirdropHelper Commands:",
    ["HELP_SHOW"] = "  /adh show - Show timer window",
    ["HELP_HIDE"] = "  /adh hide - Hide timer window", 
    ["HELP_LOCK"] = "  /adh lock - Lock window position",
    ["HELP_UNLOCK"] = "  /adh unlock - Unlock window position",
    ["HELP_RESET"] = "  /adh reset - Reset all settings",
    ["HELP_DEBUG"] = "  /adh debug - Toggle debug mode",
    ["HELP_TEST"] = "  /adh test - Test airdrop trigger (requires War Mode)",
    ["HELP_DETECTOR"] = "  /adh detector [on/off] - Enable/disable airdrop detector",
    ["HELP_STATUS"] = "  /adh status - View plugin status",
    ["HELP_WARNING"] = "Note: Plugin only works when War Mode is enabled",
    
    -- 界面相关
    ["UI_LOCKED"] = "Interface locked",
    ["UI_UNLOCKED"] = "Interface unlocked",
    ["UI_MENU_TITLE"] = "Airdrop Timer",
    ["UI_MENU_LOCK"] = "Lock Position",
    ["UI_MENU_UNLOCK"] = "Unlock Position", 
    ["UI_MENU_RESET"] = "Reset Timers",
    ["UI_MENU_CLOSE"] = "Close",
    
    -- 同步相关
    ["SYNC_DISABLED"] = "Sync disabled, skipping share",
    ["SYNC_NOT_IN_GROUP"] = "Not in party/raid, skipping sync share",
    ["SYNC_IGNORE_NON_MEMBER"] = "Ignoring message from non-party/raid member: %s %s",
    ["SYNC_PROCESSING"] = "Processing party member airdrop sync: %s -> %s",
    ["SYNC_DIFFERENT_ZONE"] = "Not in same zone, ignoring sync: %s vs %s",
    ["SYNC_SIMILAR_TIMER"] = "Similar timer exists, ignoring sync",
    ["SYNC_MESSAGE"] = "Sync: %s %s (from %s)",
    
    -- 检测器相关
    ["DETECTOR_INITIALIZED"] = "Airdrop detector initialized",
    ["DETECTOR_ENABLED"] = "Airdrop detector enabled",
    ["DETECTOR_DISABLED"] = "Airdrop detector disabled", 
    ["DETECTOR_STATUS"] = "Airdrop detector status: %s",
    ["DETECTOR_BOX_FOUND"] = "Detected target box: %s",
    ["DETECTOR_NPC_CONFLICT"] = "Detected NPC timer with %s remaining, ignoring box detection",
    ["DETECTOR_BOX_TRIGGERED"] = "Box detection triggered: %s in %s",
    
    -- 调试相关
    ["DEBUG_MODE"] = "Debug mode: %s",
    ["DEBUG_NPC_SPEAK"] = "NPC speaking: %s -> %s",
    ["DEBUG_ZONE_CHANGED"] = "Zone changed: %s -> %s",
    ["DEBUG_CURRENT_MAP"] = "Current map: %s",
    ["DEBUG_ZONE_TIMERS"] = "Map [%s] timers: %d, total timers: %d",
    
    -- 错误信息
    ["ERROR_UNKNOWN_COMMAND"] = "Unknown command: %s",
    ["ERROR_NOTIFICATION_FAILED"] = "Notification failed: %s",
    ["WARNING_NO_PERMISSION"] = "No raid warning permission",
    ["WARNING_MISSING_DEPS"] = "Missing dependencies: %s",
    
    -- 通知系统
    ["NOTIFICATION_INITIALIZED"] = "Notification system initialized",
    ["NOTIFICATION_COOLDOWN"] = "Notification cooling down, ignoring message: %s",
    ["NOTIFICATION_SENT"] = "Notification sent: %s",
    ["NOTIFICATION_FAILED"] = "Notification failed: %s",
    ["NOTIFICATION_TEST_SENT"] = "Test notification sent",
    ["NOTIFICATION_TEST_FAILED"] = "Test notification failed",
    
    -- NPC 监控
    ["NPC_MONITOR_INITIALIZED"] = "NPC monitor initialized",
    ["NPC_NOT_MONITORED"] = "NPC not in monitor list: %s",
    ["NPC_NO_KEYWORDS"] = "Message contains no keywords: %s",
    ["NPC_COOLDOWN"] = "Trigger cooling down, ignoring: %s %s",
    ["NPC_TRIGGERED"] = "NPC triggered airdrop: %s keyword: %s",
    ["NPC_ZONE_CHANGED"] = "NPC monitor: Zone changed, clearing cooldowns",
    
    -- NPC 监控额外功能
    ["NPC_ADD_KEYWORDS"] = "Added NPC keywords: %s -> %s",
    ["NPC_REMOVE_KEYWORDS"] = "Removed NPC keywords: %s",
    ["NPC_SET_COOLDOWN"] = "Set trigger cooldown: %d seconds",
    ["NPC_CLEAR_COOLDOWNS"] = "Manually cleared NPC trigger cooldowns",
    
    -- 通知系统额外功能
    ["NOTIFICATION_NOT_IN_RAID"] = "Not in raid, cannot send raid warning",
    ["NOTIFICATION_NOT_IN_PARTY"] = "Not in party, cannot send party message",
    ["NOTIFICATION_SET_COOLDOWN"] = "Set notification cooldown: %d seconds",
    ["NOTIFICATION_LOCAL"] = "Local notification: %s",
    ["NOTIFICATION_SCREEN_ALERT"] = "Screen alert: %s",
    ["NOTIFICATION_STATUS"] = "Notification system status: %s",
    ["NOTIFICATION_AVAILABLE_METHODS"] = "Available methods",
    ["NOTIFICATION_RAID_WARNING"] = "Raid Warning",
    ["NOTIFICATION_RAID_CHANNEL"] = "Raid Channel", 
    ["NOTIFICATION_PARTY_CHANNEL"] = "Party Channel",
    ["NOTIFICATION_SAY_CHANNEL"] = "Say Channel",
    ["NOTIFICATION_TRIGGER_TYPE_NPC"] = "(NPC)",
    ["NOTIFICATION_TRIGGER_TYPE_VISUAL"] = "(Visual)",
    
    -- 计时器UI额外功能
    ["TIMER_UI_INITIALIZED"] = "Timer UI initialized",
    ["TIMER_UI_EXPIRED"] = "Timer expired: %s",
    ["TIMER_UI_RESET"] = "Timer UI reset",
    ["TIMER_UI_CONTEXT_MENU"] = "Airdrop Timer Menu:",
    ["TIMER_UI_MENU_LOCK_UNLOCK"] = "%d. %s - Use /adh %s",
    ["TIMER_UI_MENU_RESET"] = "2. Reset Timers - Use /adh reset",
    ["TIMER_UI_MENU_HIDE"] = "3. Hide Interface - Use /adh hide",
    
    -- 同步管理器额外功能
    ["SYNC_MANAGER_INITIALIZED"] = "Sync manager initialized",
    ["SYNC_IGNORE_MESSAGE"] = "Ignoring message from non-party/raid member: %s %s",
    ["SYNC_RECEIVE_MESSAGE"] = "Received sync message: %s %s %s",
    ["SYNC_DECODE_FAILED"] = "Failed to decode message: %s",
    ["SYNC_PROCESSING_AIRDROP"] = "Processing party member airdrop sync: %s -> %s",
    ["SYNC_DIFFERENT_ZONE"] = "Not in same zone, ignoring sync: %s vs %s",
    ["SYNC_SIMILAR_TIMER"] = "Similar timer exists, ignoring sync",
    ["SYNC_PROCESSED"] = "Processed sync airdrop: %s from: %s",
    ["SYNC_NO_CHANNELS"] = "No available sync channels",
    ["SYNC_MESSAGE_SENT"] = "Sync message sent to: %s",
    ["SYNC_MESSAGE_FAILED"] = "Failed to send sync message to: %s",
    ["SYNC_ENCODE_FAILED"] = "Failed to encode sync message",
    ["SYNC_VERSION_INCOMPATIBLE"] = "Version incompatible, ignoring message: %s",
    ["SYNC_MESSAGE_TOO_OLD"] = "Message too old, ignoring: %d",
    ["SYNC_DUPLICATE_MESSAGE"] = "Duplicate sync message, ignoring: %s",
    ["SYNC_CLEANUP_DATA"] = "Cleaned up %d expired sync data",
    ["SYNC_STATUS"] = "Sync manager status: %s",
    ["SYNC_TEST_SENT"] = "Test sync message sent",
    ["SYNC_NOT_ENABLED"] = "Sync functionality not enabled",
    ["SYNC_COOLDOWN"] = "Sync cooling down, skipping share: %s",
    
    -- 广播功能
    ["BROADCAST_BUTTON"] = "Broadcast",
    ["BROADCAST_TOOLTIP"] = "Broadcast current timers to selected channel",
    ["BROADCAST_RAID"] = "Raid",
    ["BROADCAST_PARTY"] = "Party", 
    ["BROADCAST_GUILD"] = "Guild",
    ["BROADCAST_SAY"] = "Say",
    ["BROADCAST_CHANNEL"] = "Channel %d",
    ["BROADCAST_COMMUNITY"] = "Community: %s",
    ["BROADCAST_NO_TIMERS"] = "No active timers to broadcast",
    ["BROADCAST_SUCCESS"] = "Timers broadcasted to %s",
    ["BROADCAST_FAILED"] = "Failed to broadcast to %s",
    ["BROADCAST_MESSAGE_FORMAT"] = "Airdrop Timers: %s",
    ["BROADCAST_TIMER_FORMAT"] = "%s (%s remaining)",
    
    -- 其他
    ["UNKNOWN_ZONE"] = "Unknown Zone",
    ["DEPENDENCIES_CHECK"] = "HandyNotes (optional)"
}

-- 中文简体
local zhCN = {
    -- 基本信息
    ["ADDON_NAME"] = "空投助手",
    ["ADDON_LOADED"] = "空投助手 v%s 已加载",
    ["ADDON_DISABLED"] = "插件已禁用",
    ["ADDON_ACTIVATED"] = "战争模式已开启，空投助手激活",
    ["ADDON_DEACTIVATED"] = "战争模式已关闭，空投助手隐藏",
    
    -- 空投相关
    ["AIRDROP_DETECTED"] = "空投箱子",
    ["AIRDROP_TIMER_EXPIRED"] = "空投计时器过期: %s",
    ["AIRDROP_TEST_TRIGGERED"] = "测试空投已触发",
    ["AIRDROP_PLUGIN_INACTIVE"] = "插件未激活 - 需要开启战争模式",
    
    -- 计时器相关
    ["TIMER_TITLE"] = "空投计时器",
    ["TIMER_MAX_REACHED"] = "已达到最大计时器数量限制 (%d个)",
    ["TIMER_UPDATED"] = "更新地图 [%s] 的计时器，类型: %s",
    ["TIMER_ADDED"] = "添加新地图 [%s] 的计时器，类型: %s",
    ["TIMER_REMOVED"] = "已移除计时器: %s",
    ["TIMER_NOT_FOUND"] = "未找到要删除的计时器: %s",
    
    -- 状态信息
    ["STATUS_WAR_MODE"] = "战争模式: %s",
    ["STATUS_PLUGIN"] = "插件状态: %s",
    ["STATUS_TOTAL_TIMERS"] = "当前计时器总数: %d个",
    ["STATUS_ZONE_TIMERS"] = "  %s: %d个计时器 %s",
    ["STATUS_CURRENT_MAP"] = "(当前地图)",
    ["STATUS_NO_TIMERS"] = "当前没有活跃的计时器",
    ["STATUS_ENABLED"] = "启用",
    ["STATUS_DISABLED"] = "禁用",
    ["STATUS_ACTIVE"] = "激活",
    ["STATUS_INACTIVE"] = "未激活",
    ["STATUS_ON"] = "开启",
    ["STATUS_OFF"] = "关闭",
    
    -- 命令帮助
    ["HELP_TITLE"] = "AirdropHelper 命令:",
    ["HELP_SHOW"] = "  /adh show - 显示计时器窗口",
    ["HELP_HIDE"] = "  /adh hide - 隐藏计时器窗口",
    ["HELP_LOCK"] = "  /adh lock - 锁定窗口位置",
    ["HELP_UNLOCK"] = "  /adh unlock - 解锁窗口位置",
    ["HELP_RESET"] = "  /adh reset - 重置所有设置",
    ["HELP_DEBUG"] = "  /adh debug - 切换调试模式",
    ["HELP_TEST"] = "  /adh test - 测试空投触发（需要战争模式）",
    ["HELP_DETECTOR"] = "  /adh detector [on/off] - 启用/禁用空投检测器",
    ["HELP_STATUS"] = "  /adh status - 查看插件状态",
    ["HELP_WARNING"] = "注意: 插件仅在战争模式开启时工作",
    
    -- 界面相关
    ["UI_LOCKED"] = "界面已锁定",
    ["UI_UNLOCKED"] = "界面已解锁",
    ["UI_MENU_TITLE"] = "空投计时器",
    ["UI_MENU_LOCK"] = "锁定位置",
    ["UI_MENU_UNLOCK"] = "解锁位置",
    ["UI_MENU_RESET"] = "重置计时器",
    ["UI_MENU_CLOSE"] = "关闭",
    
    -- 同步相关
    ["SYNC_DISABLED"] = "同步已禁用，跳过分享",
    ["SYNC_NOT_IN_GROUP"] = "不在队伍/团队中，跳过同步分享",
    ["SYNC_IGNORE_NON_MEMBER"] = "忽略非队伍/团队成员的消息: %s %s",
    ["SYNC_PROCESSING"] = "处理队伍成员空投同步: %s -> %s",
    ["SYNC_DIFFERENT_ZONE"] = "不在相同区域，忽略同步: %s vs %s",
    ["SYNC_SIMILAR_TIMER"] = "已有相似计时器，忽略同步",
    ["SYNC_MESSAGE"] = "同步: %s %s (来自 %s)",
    
    -- 检测器相关
    ["DETECTOR_INITIALIZED"] = "空投检测器已初始化",
    ["DETECTOR_ENABLED"] = "空投检测器已启用", 
    ["DETECTOR_DISABLED"] = "空投检测器已禁用",
    ["DETECTOR_STATUS"] = "空投检测器状态: %s",
    ["DETECTOR_BOX_FOUND"] = "检测到目标箱子: %s",
    ["DETECTOR_NPC_CONFLICT"] = "检测到NPC计时器剩余%s，忽略箱子检测",
    ["DETECTOR_BOX_TRIGGERED"] = "箱子检测触发: %s 在 %s",
    
    -- 调试相关
    ["DEBUG_MODE"] = "调试模式: %s",
    ["DEBUG_NPC_SPEAK"] = "NPC说话: %s -> %s",
    ["DEBUG_ZONE_CHANGED"] = "区域变化: %s -> %s",
    ["DEBUG_CURRENT_MAP"] = "当前地图: %s",
    ["DEBUG_ZONE_TIMERS"] = "地图 [%s] 计时器: %d个, 总计时器: %d个",
    
    -- 错误信息
    ["ERROR_UNKNOWN_COMMAND"] = "未知命令: %s",
    ["ERROR_NOTIFICATION_FAILED"] = "通知发送失败: %s",
    ["WARNING_NO_PERMISSION"] = "没有团队警报权限",
    ["WARNING_MISSING_DEPS"] = "缺少依赖: %s",
    
    -- 通知系统
    ["NOTIFICATION_INITIALIZED"] = "通知系统已初始化",
    ["NOTIFICATION_COOLDOWN"] = "通知冷却中，忽略消息: %s",
    ["NOTIFICATION_SENT"] = "通知已发送: %s",
    ["NOTIFICATION_FAILED"] = "通知发送失败: %s",
    ["NOTIFICATION_TEST_SENT"] = "测试通知已发送",
    ["NOTIFICATION_TEST_FAILED"] = "测试通知发送失败",
    
    -- NPC 监控
    ["NPC_MONITOR_INITIALIZED"] = "NPC监控器已初始化",
    ["NPC_NOT_MONITORED"] = "NPC不在监控列表中: %s",
    ["NPC_NO_KEYWORDS"] = "消息不包含关键词: %s",
    ["NPC_COOLDOWN"] = "触发冷却中，忽略: %s %s",
    ["NPC_TRIGGERED"] = "NPC触发空投: %s 关键词: %s",
    ["NPC_ZONE_CHANGED"] = "NPC监控器: 区域变化，清理冷却记录",
    
    -- NPC 监控额外功能
    ["NPC_ADD_KEYWORDS"] = "添加NPC关键词: %s -> %s",
    ["NPC_REMOVE_KEYWORDS"] = "移除NPC关键词: %s",
    ["NPC_SET_COOLDOWN"] = "设置触发冷却时间: %d秒",
    ["NPC_CLEAR_COOLDOWNS"] = "手动清理NPC触发冷却记录",
    
    -- 通知系统额外功能
    ["NOTIFICATION_NOT_IN_RAID"] = "不在团队中，无法发送团队警报",
    ["NOTIFICATION_NOT_IN_PARTY"] = "不在小队中，无法发送小队消息",
    ["NOTIFICATION_SET_COOLDOWN"] = "设置通知冷却时间: %d秒",
    ["NOTIFICATION_LOCAL"] = "本地通知: %s",
    ["NOTIFICATION_SCREEN_ALERT"] = "屏幕提醒: %s",
    ["NOTIFICATION_STATUS"] = "通知系统状态: %s",
    ["NOTIFICATION_AVAILABLE_METHODS"] = "可用方式",
    ["NOTIFICATION_RAID_WARNING"] = "团队警报",
    ["NOTIFICATION_RAID_CHANNEL"] = "团队频道",
    ["NOTIFICATION_PARTY_CHANNEL"] = "小队频道",
    ["NOTIFICATION_SAY_CHANNEL"] = "普通说话",
    ["NOTIFICATION_TRIGGER_TYPE_NPC"] = "(NPC)",
    ["NOTIFICATION_TRIGGER_TYPE_VISUAL"] = "(视觉)",
    
    -- 计时器UI额外功能
    ["TIMER_UI_INITIALIZED"] = "计时器UI已初始化",
    ["TIMER_UI_EXPIRED"] = "计时器过期: %s",
    ["TIMER_UI_RESET"] = "计时器UI已重置",
    ["TIMER_UI_CONTEXT_MENU"] = "空投计时器菜单:",
    ["TIMER_UI_MENU_LOCK_UNLOCK"] = "%d. %s - 使用 /adh %s",
    ["TIMER_UI_MENU_RESET"] = "2. 重置计时器 - 使用 /adh reset",
    ["TIMER_UI_MENU_HIDE"] = "3. 隐藏界面 - 使用 /adh hide",
    
    -- 同步管理器额外功能
    ["SYNC_MANAGER_INITIALIZED"] = "同步管理器已初始化",
    ["SYNC_IGNORE_MESSAGE"] = "忽略非队伍/团队成员的消息: %s %s",
    ["SYNC_RECEIVE_MESSAGE"] = "收到同步消息: %s %s %s",
    ["SYNC_DECODE_FAILED"] = "解码消息失败: %s",
    ["SYNC_PROCESSING_AIRDROP"] = "处理队伍成员空投同步: %s -> %s",
    ["SYNC_DIFFERENT_ZONE"] = "不在相同区域，忽略同步: %s vs %s",
    ["SYNC_SIMILAR_TIMER"] = "已有相似计时器，忽略同步",
    ["SYNC_PROCESSED"] = "处理同步空投: %s 来自: %s",
    ["SYNC_NO_CHANNELS"] = "没有可用的同步频道",
    ["SYNC_MESSAGE_SENT"] = "同步消息已发送到: %s",
    ["SYNC_MESSAGE_FAILED"] = "发送同步消息失败: %s",
    ["SYNC_ENCODE_FAILED"] = "编码同步消息失败",
    ["SYNC_VERSION_INCOMPATIBLE"] = "版本不兼容，忽略消息: %s",
    ["SYNC_MESSAGE_TOO_OLD"] = "消息过旧，忽略: %d",
    ["SYNC_DUPLICATE_MESSAGE"] = "重复的同步消息，忽略: %s",
    ["SYNC_CLEANUP_DATA"] = "清理 %d 个过期的同步数据",
    ["SYNC_STATUS"] = "同步管理器状态: %s",
    ["SYNC_TEST_SENT"] = "测试同步消息已发送",
    ["SYNC_NOT_ENABLED"] = "同步功能未启用",
    ["SYNC_COOLDOWN"] = "同步冷却中，跳过分享: %s",
    
    -- 广播功能
    ["BROADCAST_BUTTON"] = "广播",
    ["BROADCAST_TOOLTIP"] = "将当前计时器广播到选择的频道",
    ["BROADCAST_RAID"] = "团队",
    ["BROADCAST_PARTY"] = "小队",
    ["BROADCAST_GUILD"] = "公会",
    ["BROADCAST_SAY"] = "说话",
    ["BROADCAST_CHANNEL"] = "频道 %d",
    ["BROADCAST_COMMUNITY"] = "社群: %s",
    ["BROADCAST_NO_TIMERS"] = "没有活跃的计时器可广播",
    ["BROADCAST_SUCCESS"] = "计时器已广播到 %s",
    ["BROADCAST_FAILED"] = "广播到 %s 失败",
    ["BROADCAST_MESSAGE_FORMAT"] = "空投计时器: %s",
    ["BROADCAST_TIMER_FORMAT"] = "%s (剩余 %s)",
    
    -- 其他
    ["UNKNOWN_ZONE"] = "未知区域",
    ["DEPENDENCIES_CHECK"] = "HandyNotes (可选)"
}

-- 中文繁体
local zhTW = {
    -- 基本信息
    ["ADDON_NAME"] = "空投助手",
    ["ADDON_LOADED"] = "空投助手 v%s 已載入",
    ["ADDON_DISABLED"] = "插件已禁用",
    ["ADDON_ACTIVATED"] = "戰爭模式已開啟，空投助手啟動",
    ["ADDON_DEACTIVATED"] = "戰爭模式已關閉，空投助手隱藏",
    
    -- 空投相关
    ["AIRDROP_DETECTED"] = "空投箱子",
    ["AIRDROP_TIMER_EXPIRED"] = "空投計時器過期: %s",
    ["AIRDROP_TEST_TRIGGERED"] = "測試空投已觸發",
    ["AIRDROP_PLUGIN_INACTIVE"] = "插件未啟動 - 需要開啟戰爭模式",
    
    -- 计时器相关
    ["TIMER_TITLE"] = "空投計時器",
    ["TIMER_MAX_REACHED"] = "已達到最大計時器數量限制 (%d個)",
    ["TIMER_UPDATED"] = "更新地圖 [%s] 的計時器，類型: %s",
    ["TIMER_ADDED"] = "添加新地圖 [%s] 的計時器，類型: %s",
    ["TIMER_REMOVED"] = "已移除計時器: %s",
    ["TIMER_NOT_FOUND"] = "未找到要刪除的計時器: %s",
    
    -- 状态信息
    ["STATUS_WAR_MODE"] = "戰爭模式: %s",
    ["STATUS_PLUGIN"] = "插件狀態: %s",
    ["STATUS_TOTAL_TIMERS"] = "目前計時器總數: %d個",
    ["STATUS_ZONE_TIMERS"] = "  %s: %d個計時器 %s",
    ["STATUS_CURRENT_MAP"] = "(目前地圖)",
    ["STATUS_NO_TIMERS"] = "目前沒有活躍的計時器",
    ["STATUS_ENABLED"] = "啟用",
    ["STATUS_DISABLED"] = "禁用",
    ["STATUS_ACTIVE"] = "啟動",
    ["STATUS_INACTIVE"] = "未啟動",
    ["STATUS_ON"] = "開啟",
    ["STATUS_OFF"] = "關閉",
    
    -- 其他重要字符串...
    ["HELP_TITLE"] = "AirdropHelper 命令:",
    ["HELP_WARNING"] = "注意: 插件僅在戰爭模式開啟時工作",
    ["TIMER_TITLE"] = "空投計時器",
    ["UNKNOWN_ZONE"] = "未知區域"
}

-- 语言选择函数
local function GetLocalizedStrings()
    if locale == "zhCN" then
        return zhCN
    elseif locale == "zhTW" then
        return zhTW
    else
        return defaultStrings
    end
end

-- 设置本地化字符串
local localizedStrings = GetLocalizedStrings()

-- 创建本地化函数
local function GetLocalizedString(key, ...)
    local text = localizedStrings[key] or defaultStrings[key] or key
    if ... then
        return string.format(text, ...)
    end
    return text
end

-- 导出本地化系统
addon.L = setmetatable({}, {
    __index = function(t, k)
        return GetLocalizedString(k)
    end,
    __call = function(t, k, ...)
        return GetLocalizedString(k, ...)
    end
})

-- 调试信息 (延迟到初始化完成后)
-- addon.Utils:Debug("Localization loaded for locale:", locale)