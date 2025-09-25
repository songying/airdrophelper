-- AirdropHelper Timer UI
-- 倒計時UI介面模組

local addonName, addon = ...

addon.TimerUI = {}

local TimerUI = addon.TimerUI

-- 初始化
function TimerUI:Initialize()
    self.timers = {}
    self.frame = nil
    self.progressBars = {}
    self.isVisible = true
    self.isLocked = addon.Config:Get("ui.locked") or false

    self:CreateMainFrame()
    self:UpdatePosition()

    -- 載入儲存的計時器資料
    self:LoadTimersFromDatabase()

    self:StartUpdateTimer()

    addon.Utils:Debug(addon.L.TIMER_UI_INITIALIZED)
end

-- 创建主框架
function TimerUI:CreateMainFrame()
    if self.frame then
        return
    end
    
    -- 创建主框架
    local frame = CreateFrame("Frame", "AirdropHelperTimerFrame", UIParent)
    frame:SetSize(addon.UI_CONFIG.FRAME_WIDTH, 100) -- 初始高度
    frame:SetPoint("CENTER", 0, 0)
    
    -- 设置背景
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.7)
    frame.background = bg
    
    -- 创建标题栏
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", frame, "TOP", 0, -5)
    title:SetText(addon.L.TIMER_TITLE)
    title:SetTextColor(1, 1, 1, 1)
    frame.title = title
    
    -- 设置可拖拽
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    frame:SetScript("OnDragStart", function(self)
        if not TimerUI.isLocked then
            self:StartMoving()
        end
    end)
    
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        TimerUI:SavePosition()
    end)
    
    -- 右键菜单
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            TimerUI:ShowContextMenu()
        end
    end)
    
    self.frame = frame
    
    -- 创建进度条容器
    self:CreateProgressBarContainer()
    
    -- 创建广播按钮和下拉框
    self:CreateBroadcastControls()
end

-- 创建进度条容器
function TimerUI:CreateProgressBarContainer()
    if not self.frame then
        return
    end
    
    local container = CreateFrame("Frame", nil, self.frame)
    container:SetPoint("TOPLEFT", self.frame, "TOPLEFT", addon.UI_CONFIG.FRAME_PADDING, -30)
    container:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -addon.UI_CONFIG.FRAME_PADDING, -30)
    container:SetHeight(1) -- 动态调整
    
    self.progressBarContainer = container
end

-- 创建广播控件
function TimerUI:CreateBroadcastControls()
    if not self.frame then
        return
    end
    
    -- 创建广播按钮，使用游戏内置按钮样式
    local broadcastButton = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    broadcastButton:SetSize(50, 22)
    broadcastButton:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -5, -5)
    broadcastButton:SetText("Send")
    
    -- 调整字体大小
    local font = broadcastButton:GetFontString()
    if font then
        font:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    
    -- 广播按钮点击事件
    broadcastButton:SetScript("OnClick", function()
        self:ToggleBroadcastDropdown()
    end)
    
    -- 广播按钮悬停效果
    broadcastButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(broadcastButton, "ANCHOR_TOP")
        GameTooltip:SetText(addon.L.BROADCAST_TOOLTIP)
        GameTooltip:Show()
    end)
    
    broadcastButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    self.broadcastButton = broadcastButton
    
    -- 创建 Add 按钮（在右侧 Send 按钮之前）
    local addButton = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    addButton:SetSize(50, 22)
    addButton:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -60, -5) -- 在Send按钮左侧
    addButton:SetText("Add")
    
    -- 调整字体大小
    local addFont = addButton:GetFontString()
    if addFont then
        addFont:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    
    -- Add 按钮点击事件
    addButton:SetScript("OnClick", function()
        self:ShowManualTimerDialog()
    end)
    
    -- Add 按钮悬停效果
    addButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(addButton, "ANCHOR_TOP")
        GameTooltip:SetText("手動添加計時器")
        GameTooltip:Show()
    end)
    
    addButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    self.addButton = addButton
    
    -- 创建自动播报开关（在原来Add按钮位置）
    self:CreateAutoBroadcastSwitch()
    
    -- 创建下拉框
    self:CreateBroadcastDropdown()
end

-- 创建广播下拉框
function TimerUI:CreateBroadcastDropdown()
    if not self.frame then
        return
    end
    
    -- 创建下拉框架，设置高图层确保在进度条之上
    local dropdown = CreateFrame("Frame", nil, UIParent) -- 使用UIParent作为父级
    dropdown:SetSize(150, 200) -- 稍微增加宽度以容纳频道信息
    dropdown:SetPoint("TOPRIGHT", self.broadcastButton, "BOTTOMRIGHT", 0, -2)
    dropdown:SetFrameStrata("DIALOG") -- 设置高图层
    dropdown:SetFrameLevel(1000) -- 设置高图层级别
    dropdown:Hide()
    
    -- 下拉框背景
    local dropdownBg = dropdown:CreateTexture(nil, "BACKGROUND")
    dropdownBg:SetAllPoints()
    dropdownBg:SetColorTexture(0, 0, 0, 0.9)
    dropdown.background = dropdownBg
    
    -- 下拉框边框
    local border = dropdown:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(0.5, 0.5, 0.5, 1)
    border:SetPoint("TOPLEFT", dropdown, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", 1, -1)
    
    self.broadcastDropdown = dropdown
    self.broadcastOptions = {}
    
    -- 更新下拉选项
    self:UpdateBroadcastOptions()
end

-- 创建自动播报开关（按钮样式）
function TimerUI:CreateAutoBroadcastSwitch()
    if not self.frame then
        return
    end
    
    -- 获取默认状态（默认开启）
    local isEnabled = addon.Config:Get("autoBroadcast.enabled")
    if isEnabled == nil then
        isEnabled = true
        addon.Config:Set("autoBroadcast.enabled", true)
    end
    
    -- 创建按钮样式的开关，使用游戏内置按钮样式
    local switchButton = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
    switchButton:SetSize(80, 22) -- 稍微宽一些以容纳文字
    switchButton:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, -5)
    
    -- 调整字体大小
    local font = switchButton:GetFontString()
    if font then
        font:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    
    -- 更新按钮文字和外观
    local function updateButtonAppearance()
        if isEnabled then
            switchButton:SetText("ON")
        else
            switchButton:SetText("OFF")
        end
    end
    
    -- 初始化外观
    updateButtonAppearance()
    
    -- 点击事件
    switchButton:SetScript("OnClick", function()
        isEnabled = not isEnabled
        addon.Config:Set("autoBroadcast.enabled", isEnabled)
        updateButtonAppearance()
        
        local status = isEnabled and "開啓" or "關閉"
        addon.Utils:Info("自動播報已" .. status)
    end)
    
    -- 悬停提示
    switchButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(switchButton, "ANCHOR_TOP")
        local tooltip = isEnabled and "點擊關閉自動播報" or "點擊開啓自動播報"
        GameTooltip:SetText(tooltip)
        GameTooltip:AddLine("開啓時：出發計時器自動發送到團隊/小隊/説話頻道", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    
    switchButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    self.autoBroadcastSwitch = switchButton
end

-- 自动播报功能
function TimerUI:AutoBroadcastTimer(timerData)
    -- 检查是否启用自动播报
    if not addon.Config:Get("autoBroadcast.enabled") then
        return
    end
    
    -- 构建播报消息
    local remaining = timerData.duration
    local timeText = self:FormatBroadcastTime(remaining)
    local triggerTime = timerData.triggerTime or ""
    local message = string.format("[%s]%s(next:%s)", triggerTime, timerData.zoneName, timeText)
    
    -- 按优先级尝试发送：团队警报 > 团队 > 小队 > 说话
    local channels = {
        {type = "RAID_WARNING", name = "团队警报", condition = function() return UnitInRaid("player") and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) end},
        {type = "RAID", name = "团队", condition = function() return UnitInRaid("player") end},
        {type = "PARTY", name = "小队", condition = function() return UnitInParty("player") and not UnitInRaid("player") end},
        {type = "SAY", name = "说话", condition = function() return true end}
    }
    
    for _, channel in ipairs(channels) do
        if channel.condition() then
            local success = addon.Utils:SendChatMessage(message, channel.type)
            if success then
                addon.Utils:Debug("自动播报成功发送到: " .. channel.name)
                return true
            end
        end
    end
    
    addon.Utils:Debug("自动播报失败")
    return false
end

-- 更新广播选项
function TimerUI:UpdateBroadcastOptions()
    if not self.broadcastDropdown then
        return
    end
    
    -- 清理旧选项
    for _, option in ipairs(self.broadcastOptions) do
        option:Hide()
        option:SetParent(nil)
    end
    self.broadcastOptions = {}
    
    local yOffset = -5
    local optionHeight = 20
    
    -- 获取可用频道
    local channels = self:GetAvailableBroadcastChannels()
    
    for i, channelInfo in ipairs(channels) do
        local option = CreateFrame("Button", nil, self.broadcastDropdown)
        option:SetSize(140, optionHeight) -- 调整宽度以适应新的下拉框尺寸
        option:SetPoint("TOP", self.broadcastDropdown, "TOP", 0, yOffset)
        
        -- 选项背景
        local optionBg = option:CreateTexture(nil, "BACKGROUND")
        optionBg:SetAllPoints()
        optionBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
        option.background = optionBg
        
        -- 选项文本
        local optionText = option:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        optionText:SetPoint("LEFT", option, "LEFT", 5, 0)
        optionText:SetText(channelInfo.name)
        optionText:SetTextColor(1, 1, 1, 1)
        option.text = optionText
        
        -- 选项点击事件
        option:SetScript("OnClick", function()
            self:BroadcastToChannel(channelInfo)
            self:HideBroadcastDropdown()
        end)
        
        -- 选项悬停效果
        option:SetScript("OnEnter", function()
            optionBg:SetColorTexture(0.3, 0.3, 0.6, 0.8)
        end)
        
        option:SetScript("OnLeave", function()
            optionBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
        end)
        
        table.insert(self.broadcastOptions, option)
        yOffset = yOffset - optionHeight - 2
    end
    
    -- 调整下拉框高度
    local totalHeight = math.max(50, #channels * (optionHeight + 2) + 10)
    self.broadcastDropdown:SetHeight(totalHeight)
end

-- 获取可用的广播频道（按优先级排序：公会>团队>小队>说>频道1-6）
function TimerUI:GetAvailableBroadcastChannels()
    local channels = {}
    
    -- 1. 公会（最高优先级）
    if IsInGuild() then
        table.insert(channels, {
            type = "GUILD",
            name = addon.L.BROADCAST_GUILD,
            target = nil,
            priority = 1
        })
    end
    
    -- 2. 团队
    if UnitInRaid("player") then
        table.insert(channels, {
            type = "RAID",
            name = addon.L.BROADCAST_RAID,
            target = nil,
            priority = 2
        })
    end
    
    -- 3. 小队
    if UnitInParty("player") and not UnitInRaid("player") then
        table.insert(channels, {
            type = "PARTY", 
            name = addon.L.BROADCAST_PARTY,
            target = nil,
            priority = 3
        })
    end
    
    -- 4. 说话
    table.insert(channels, {
        type = "SAY",
        name = addon.L.BROADCAST_SAY,
        target = nil,
        priority = 4
    })
    
    -- 5. 获取频道1-6
    for i = 1, 6 do
        local channelName = GetChannelName(i)
        if channelName and channelName ~= "" then
            table.insert(channels, {
                type = "CHANNEL",
                name = addon.L("BROADCAST_CHANNEL", i) .. " (" .. channelName .. ")",
                target = i,
                channelName = channelName,
                priority = 5
            })
        end
    end
    
    -- 按优先级排序（priority越小越靠前）
    table.sort(channels, function(a, b) return a.priority < b.priority end)
    
    return channels
end

-- 切换下拉框显示状态
function TimerUI:ToggleBroadcastDropdown()
    if not self.broadcastDropdown then
        return
    end
    
    if self.broadcastDropdown:IsVisible() then
        self:HideBroadcastDropdown()
    else
        self:ShowBroadcastDropdown()
    end
end

-- 显示下拉框
function TimerUI:ShowBroadcastDropdown()
    if not self.broadcastDropdown then
        return
    end
    
    self:UpdateBroadcastOptions()
    self.broadcastDropdown:Show()
    
    -- 创建一个不可见的全屏框架来捕获点击事件
    if not self.broadcastClickCatcher then
        self.broadcastClickCatcher = CreateFrame("Frame", nil, UIParent)
        self.broadcastClickCatcher:SetAllPoints(UIParent)
        self.broadcastClickCatcher:SetFrameLevel(self.broadcastDropdown:GetFrameLevel() - 1)
        self.broadcastClickCatcher:EnableMouse(true)
        self.broadcastClickCatcher:SetScript("OnMouseDown", function()
            TimerUI:HideBroadcastDropdown()
        end)
    end
    
    self.broadcastClickCatcher:Show()
end

-- 隐藏下拉框
function TimerUI:HideBroadcastDropdown()
    if self.broadcastDropdown then
        self.broadcastDropdown:Hide()
    end
    
    if self.broadcastClickCatcher then
        self.broadcastClickCatcher:Hide()
    end
end

-- 广播到指定频道
function TimerUI:BroadcastToChannel(channelInfo)
    -- 检查是否有任何计时器（包括已过期的负数计时器）
    if #self.timers == 0 then
        addon.Utils:Warning("没有可用的计时器进行广播")
        return
    end

    -- 确保计时器按显示顺序排序（剩余时间从少到多）
    self:SortTimersByRemainingTime()

    -- 构建广播消息（按界面显示顺序，每个地图单独发送一条消息）
    local timerMessages = {}
    for _, timer in ipairs(self.timers) do
        local remaining = timer.duration - (GetTime() - timer.startTime)
        local timeText = self:FormatBroadcastTime(remaining)
        -- 新格式：[16:20]多恩岛(next:12m30s)
        local triggerTime = timer.triggerTime or ""
        local lineText = string.format("[%s]%s(next:%s)", triggerTime, timer.zoneName, timeText)
        addon.Utils:Debug("构建广播消息: " .. lineText .. " (剩余时间: " .. remaining .. "秒)")
        table.insert(timerMessages, lineText)
    end

    addon.Utils:Debug("按顺序广播计时器数量: " .. #timerMessages)
    
    -- 分多条消息发送（解决换行问题）
    local successCount = 0
    local totalMessages = #timerMessages
    
    for i, message in ipairs(timerMessages) do
        local success = false
        
        if channelInfo.type == "CHANNEL" then
            success = addon.Utils:SendChatMessage(message, channelInfo.type, channelInfo.target)
        else
            success = addon.Utils:SendChatMessage(message, channelInfo.type)
        end
        
        if success then
            successCount = successCount + 1
        end
        
        -- 消息间小延迟，防止发送过快
        if i < totalMessages then
            C_Timer.After(0.1, function() end) -- 100ms延迟
        end
    end
    
    if successCount == totalMessages then
        addon.Utils:Info(string.format("成功广播%d条消息到: %s", successCount, channelInfo.name))
    elseif successCount > 0 then
        addon.Utils:Warning(string.format("部分成功: %d/%d 条消息广播到: %s", successCount, totalMessages, channelInfo.name))
    else
        addon.Utils:Warning("广播失败到: " .. channelInfo.name)
    end
end

-- 格式化广播时间为12mins:12sec格式
function TimerUI:FormatBroadcastTime(seconds)
    local totalSeconds = math.abs(math.floor(seconds))
    local mins = math.floor(totalSeconds / 60)
    local secs = totalSeconds % 60
    
    local prefix = seconds < 0 and "-" or ""
    return string.format("%s%dmins:%02dsec", prefix, mins, secs)
end

-- 添加计时器
function TimerUI:AddTimer(timerData)
    -- 以地图名称为唯一标识，检查是否已有该地图的计时器（包括已过期的）
    local existingTimerIndex = nil
    for i, timer in ipairs(self.timers) do
        if timer.zoneName == timerData.zoneName then
            existingTimerIndex = i
            break
        end
    end
    
    if existingTimerIndex then
        -- 更新现有地图的计时器（同一地图只保留一个进度条）
        local oldTimer = self.timers[existingTimerIndex]
        local oldBar = self.progressBars[oldTimer.id]
        
        -- 移除旧的进度条UI
        if oldBar then
            oldBar:Hide()
            oldBar:SetParent(nil)
            self.progressBars[oldTimer.id] = nil
        end
        
        -- 更新计时器数据并添加触发时间（仅在不存在时设置）
        if not timerData.triggerTime then
            timerData.triggerTime = date("%H:%M") -- 只有在没有triggerTime时才设置
        end
        timerData.startTime = GetTime()
        timerData.expired = false
        timerData.id = "timer_" .. GetTime() .. "_" .. math.random(1000, 9999)
        
        self.timers[existingTimerIndex] = timerData
        
        -- 创建新的进度条
        self:CreateProgressBar(timerData)
        
        -- 按剩余时间排序并重新排列进度条
        self:SortTimersByRemainingTime()
        self:RearrangeProgressBars()
        self:UpdateFrameSize()
        
        -- 自动播报（仅对非手动计时器）
        if timerData.triggerType ~= "MANUAL" then
            self:AutoBroadcastTimer(timerData)
        end

        -- 保存计时器数据
        self:SaveTimersToDatabase()

        addon.Utils:Debug(addon.L("TIMER_UPDATED", timerData.zoneName, timerData.triggerType))
        return true
    else
        -- 不同地图，添加新计时器
        -- 检查最大计时器数量
        if #self.timers >= addon.TIMER_CONFIG.MAX_TIMERS then
            addon.Utils:Warning(addon.L("TIMER_MAX_REACHED", addon.TIMER_CONFIG.MAX_TIMERS))
            return false
        end
        
        -- 设置计时器数据并添加触发时间（仅在不存在时设置）
        if not timerData.triggerTime then
            timerData.triggerTime = date("%H:%M") -- 只有在没有triggerTime时才设置
        end
        timerData.startTime = GetTime()
        timerData.expired = false
        timerData.id = "timer_" .. GetTime() .. "_" .. math.random(1000, 9999)
        
        -- 添加新地图的计时器
        table.insert(self.timers, timerData)
        self:CreateProgressBar(timerData)
        
        -- 按剩余时间排序
        self:SortTimersByRemainingTime()
        self:RearrangeProgressBars()
        self:UpdateFrameSize()
        
        -- 自动播报（仅对非手动计时器）
        if timerData.triggerType ~= "MANUAL" then
            self:AutoBroadcastTimer(timerData)
        end

        -- 保存计时器数据
        self:SaveTimersToDatabase()

        addon.Utils:Debug(addon.L("TIMER_ADDED", timerData.zoneName, timerData.triggerType))
        return true
    end
end

-- 移除指定的计时器
function TimerUI:RemoveTimer(timerId)
    local timerIndex = nil
    
    -- 查找计时器索引
    for i, timer in ipairs(self.timers) do
        if timer.id == timerId then
            timerIndex = i
            break
        end
    end
    
    if not timerIndex then
        addon.Utils:Debug(addon.L("TIMER_NOT_FOUND", timerId))
        return false
    end
    
    local timer = self.timers[timerIndex]
    local bar = self.progressBars[timerId]
    
    -- 移除进度条UI
    if bar then
        bar:Hide()
        bar:SetParent(nil)
        self.progressBars[timerId] = nil
    end
    
    -- 从计时器列表中移除
    table.remove(self.timers, timerIndex)
    
    -- 重新排列剩余的进度条
    self:RearrangeProgressBars()
    self:UpdateFrameSize()

    -- 保存计时器数据
    self:SaveTimersToDatabase()

    addon.Utils:Debug(addon.L("TIMER_REMOVED", timer.zoneName))
    return true
end

-- 创建进度条
function TimerUI:CreateProgressBar(timerData)
    if not self.progressBarContainer then
        return
    end
    
    -- 查找当前计时器在列表中的位置
    local index = 1
    for i, timer in ipairs(self.timers) do
        if timer.id == timerData.id then
            index = i
            break
        end
    end
    
    local yOffset = -(index - 1) * (addon.UI_CONFIG.PROGRESS_BAR_HEIGHT + addon.UI_CONFIG.PROGRESS_BAR_SPACING)
    
    -- 创建进度条框架
    local bar = CreateFrame("StatusBar", nil, self.progressBarContainer)
    bar:SetSize(addon.UI_CONFIG.FRAME_WIDTH - addon.UI_CONFIG.FRAME_PADDING * 2, addon.UI_CONFIG.PROGRESS_BAR_HEIGHT)
    bar:SetPoint("TOPLEFT", 0, yOffset)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    -- 根据18分12秒(1092秒)作为基准设置进度条范围
    local baselineDuration = 1092 -- 18分12秒
    local maxDisplayDuration = math.max(timerData.duration, baselineDuration)
    
    bar:SetMinMaxValues(0, maxDisplayDuration)
    bar:SetValue(timerData.duration) -- 设置为实际剩余时间
    
    -- 进度条背景
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    bar.background = bg
    
    -- 触发时间显示（黄色文本）
    local triggerTime = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    triggerTime:SetPoint("LEFT", bar, "LEFT", 5, 0)
    triggerTime:SetTextColor(1, 1, 0, 1) -- 黄色
    triggerTime:SetText(timerData.triggerTime or "")
    bar.triggerTime = triggerTime
    
    -- 进度条文本（调整位置避免与触发旴间重叠）
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", bar, "CENTER", 15, 0) -- 向右偏移一些
    text:SetTextColor(1, 1, 1, 1)
    bar.text = text
    
    -- 创建关闭按钮
    local closeButton = CreateFrame("Button", nil, bar)
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
    
    -- 关闭按钮背景
    local closeBg = closeButton:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.8, 0.2, 0.2, 0.8)
    closeButton.background = closeBg
    
    -- 关闭按钮文本
    local closeText = closeButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    closeText:SetPoint("CENTER")
    closeText:SetText("×")
    closeText:SetTextColor(1, 1, 1, 1)
    closeButton.text = closeText
    
    -- 关闭按钮点击事件
    closeButton:SetScript("OnClick", function()
        TimerUI:RemoveTimer(timerData.id)
    end)
    
    -- 关闭按钮悬停效果
    closeButton:SetScript("OnEnter", function()
        closeBg:SetColorTexture(1, 0.3, 0.3, 1)
        closeText:SetTextColor(1, 1, 1, 1)
    end)
    
    closeButton:SetScript("OnLeave", function()
        closeBg:SetColorTexture(0.8, 0.2, 0.2, 0.8)
        closeText:SetTextColor(1, 1, 1, 1)
    end)
    
    bar.closeButton = closeButton
    
    -- 设置初始颜色
    bar:SetStatusBarColor(unpack(addon.COLORS.GREEN))
    
    -- 存储关联数据
    bar.timerData = timerData
    bar.index = index
    
    self.progressBars[timerData.id] = bar
end

-- 更新计时器
function TimerUI:UpdateTimers()
    local currentTime = GetTime()
    local hasExpiredTimers = false
    
    for i, timer in ipairs(self.timers) do
        local elapsed = currentTime - timer.startTime
        local remaining = timer.duration - elapsed
        
        local bar = self.progressBars[timer.id]
        if bar then
            -- 更新进度条值
            bar:SetValue(math.max(0, remaining))
            
            -- 更新文本
            local timeText = addon.Utils:FormatTime(math.ceil(remaining))
            bar.text:SetText(string.format("%s：%s", timer.zoneName, timeText))
            
            -- 更新颜色
            self:UpdateProgressBarColor(bar, remaining, timer.duration)
            
            -- 检查是否过期
            if remaining <= 0 and not timer.expired then
                timer.expired = true
                self:OnTimerExpired(timer)
                hasExpiredTimers = true
            end
        end
    end
    
    -- 清理过期的计时器
    if hasExpiredTimers then
        self:CleanupExpiredTimers()
    end
    
    -- 按剩余时间重新排序
    self:SortTimersByRemainingTime()
    self:RearrangeProgressBars()
end

-- 更新进度条颜色
function TimerUI:UpdateProgressBarColor(bar, remaining, duration)
    local color
    
    if remaining <= 0 then
        -- 过期后闪烁红色
        local flashTime = GetTime() % 1
        if flashTime < 0.5 then
            color = addon.COLORS.RED
        else
            color = {0.5, 0, 0, 1} -- 暗红色
        end
    elseif remaining <= addon.TIMER_CONFIG.CRITICAL_TIME then
        color = addon.COLORS.RED
    elseif remaining <= addon.TIMER_CONFIG.WARNING_TIME then
        color = addon.COLORS.YELLOW
    else
        color = addon.COLORS.GREEN
    end
    
    bar:SetStatusBarColor(unpack(color))
end

-- 计时器过期处理
function TimerUI:OnTimerExpired(timer)
    addon.Utils:Debug(addon.L("TIMER_UI_EXPIRED", timer.zoneName))
    
    -- 播放提醒声音
    addon.Utils:PlaySound()
    
    -- 发送本地通知
    if addon.NotificationSystem then
        local message = addon.L("AIRDROP_TIMER_EXPIRED", timer.zoneName)
        addon.NotificationSystem:SendLocalNotification(message, addon.COLORS.RED)
    end
end

-- 清理过期计时器
function TimerUI:CleanupExpiredTimers()
    -- 自动删除过期超过1小时(-60分钟)的计时器
    local currentTime = GetTime()
    local toRemove = {}

    for i, timer in ipairs(self.timers) do
        local remaining = timer.duration - (currentTime - timer.startTime)
        -- 清理过期超过1小时的计时器
        if remaining <= -3600 then -- -60分钟 = -3600秒
            table.insert(toRemove, 1, i) -- 逆序插入，从后往前删除
            addon.Utils:Debug("清理过期计时器: " .. timer.zoneName .. " (过期时间: " .. math.floor(-remaining/60) .. "分钟)")
        end
    end
    
    for _, index in ipairs(toRemove) do
        local timer = self.timers[index]
        local bar = self.progressBars[timer.id]
        
        if bar then
            bar:Hide()
            bar:SetParent(nil)
            self.progressBars[timer.id] = nil
        end
        
        table.remove(self.timers, index)
    end
    
    if #toRemove > 0 then
        self:RearrangeProgressBars()
        self:UpdateFrameSize()
        -- 保存更新后的计时器数据
        self:SaveTimersToDatabase()
        addon.Utils:Info("自动清理了 " .. #toRemove .. " 个过期超过1小时的计时器")
    end
end

-- 按剩余时间排序（时间最少的排在最前）
function TimerUI:SortTimersByRemainingTime()
    if not self.timers or #self.timers <= 1 then
        return
    end
    
    local currentTime = GetTime()
    
    table.sort(self.timers, function(a, b)
        local aRemaining = (a.startTime + a.duration) - currentTime
        local bRemaining = (b.startTime + b.duration) - currentTime
        return aRemaining < bRemaining -- 小的在前
    end)
end

-- 重新排列进度条
function TimerUI:RearrangeProgressBars()
    local validBars = {}
    
    -- 收集有效的进度条
    for i, timer in ipairs(self.timers) do
        local bar = self.progressBars[timer.id]
        if bar then
            table.insert(validBars, bar)
        end
    end
    
    -- 重新设置位置
    for i, bar in ipairs(validBars) do
        local yOffset = -(i - 1) * (addon.UI_CONFIG.PROGRESS_BAR_HEIGHT + addon.UI_CONFIG.PROGRESS_BAR_SPACING)
        bar:SetPoint("TOPLEFT", self.progressBarContainer, "TOPLEFT", 0, yOffset)
        bar.index = i
    end
end

-- 更新框架大小
function TimerUI:UpdateFrameSize()
    if not self.frame then
        return
    end
    
    local numTimers = #self.timers
    local height = 40 + numTimers * (addon.UI_CONFIG.PROGRESS_BAR_HEIGHT + addon.UI_CONFIG.PROGRESS_BAR_SPACING) + addon.UI_CONFIG.FRAME_PADDING
    
    if numTimers == 0 then
        height = 60 -- 最小高度
    end
    
    self.frame:SetHeight(height)
    
    if self.progressBarContainer then
        self.progressBarContainer:SetHeight(math.max(1, numTimers * (addon.UI_CONFIG.PROGRESS_BAR_HEIGHT + addon.UI_CONFIG.PROGRESS_BAR_SPACING)))
    end
end

-- 开始更新计时器
function TimerUI:StartUpdateTimer()
    if self.updateTimer then
        self.updateTimer:Cancel()
    end
    
    self.updateTimer = C_Timer.NewTicker(0.1, function()
        self:UpdateTimers()
    end)
end

-- 显示/隐藏界面
function TimerUI:Show()
    if self.frame then
        self.frame:Show()
        self.isVisible = true
    end
end

function TimerUI:Hide()
    if self.frame then
        self.frame:Hide()
        self.isVisible = false
    end
end

function TimerUI:IsVisible()
    return self.isVisible and self.frame and self.frame:IsVisible()
end

-- 锁定/解锁界面
function TimerUI:SetLocked(locked)
    self.isLocked = locked
    
    if self.frame then
        if locked then
            self.frame:SetMovable(false)
        else
            self.frame:SetMovable(true)
        end
    end
end

-- 重置所有计时器
function TimerUI:Reset()
    for _, bar in pairs(self.progressBars) do
        if bar then
            bar:Hide()
            bar:SetParent(nil)
        end
    end
    
    self.timers = {}
    self.progressBars = {}
    self:UpdateFrameSize()
    
    addon.Utils:Debug(addon.L.TIMER_UI_RESET)
end

-- 保存位置
function TimerUI:SavePosition()
    if not self.frame then
        return
    end
    
    local point, _, relativePoint, x, y = self.frame:GetPoint()
    addon.Config:Set("ui.position", {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y
    })
end

-- 更新位置
function TimerUI:UpdatePosition()
    if not self.frame then
        return
    end
    
    local position = addon.Config:Get("ui.position")
    if position then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(position.point or "CENTER", UIParent, position.relativePoint or "CENTER", position.x or 0, position.y or 0)
    end
end

-- 显示右键菜单
function TimerUI:ShowContextMenu()
    -- 简化的右键菜单实现，兼容11.2版本
    print("|cFF00FF00" .. addon.L.TIMER_UI_CONTEXT_MENU .. "|r")
    print(addon.L("TIMER_UI_MENU_LOCK_UNLOCK", 1, (self.isLocked and addon.L.UI_MENU_UNLOCK or addon.L.UI_MENU_LOCK), (self.isLocked and "unlock" or "lock")))
    print(addon.L.TIMER_UI_MENU_RESET)
    print(addon.L.TIMER_UI_MENU_HIDE)
    
    -- 也可以直接执行切换锁定操作
    self:SetLocked(not self.isLocked)
    addon.Config:Set("ui.locked", self.isLocked)
    addon.Utils:Info(self.isLocked and addon.L.UI_LOCKED or addon.L.UI_UNLOCKED)
end

-- 显示手动计时器对话框
function TimerUI:ShowManualTimerDialog()
    if self.manualTimerDialog then
        self.manualTimerDialog:Show()
        return
    end
    
    -- 创建对话框
    local dialog = CreateFrame("Frame", nil, UIParent)
    dialog:SetSize(300, 200)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(1000)
    
    -- 对话框背景（与主框体保持一致：半透明黑色）
    local bg = dialog:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.7) -- 半透明黑色，与主框体一致
    
    -- 边框（与主框体保持一致）
    local border = dialog:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(1, 1, 1, 0.3) -- 白色边框，低透明度
    border:SetDrawLayer("BORDER", 1)
    
    -- 内部背景区域（与主背景保持一致）
    local innerBg = dialog:CreateTexture(nil, "BACKGROUND")
    innerBg:SetPoint("TOPLEFT", dialog, "TOPLEFT", 1, -1)
    innerBg:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -1, 1)
    innerBg:SetColorTexture(0, 0, 0, 0.7) -- 半透明黑色
    
    -- 标题
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", dialog, "TOP", 0, -10)
    title:SetText("手动添加计时器")
    
    -- 获取当前时间和地图
    local currentTime = date("*t")
    local currentZone = GetRealZoneText() or "多恩岛"
    
    -- 预定义地图列表
    local predefinedZones = {
        "多恩島",
        "阿兹-卡罕特",
        "鳴響深淵",
        "聖落之地",
        "海妖島",
        "幽坑城",
        "凱瑞西"
    }
    
    -- 小时输入框
    local hourLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hourLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, -50)
    hourLabel:SetText("小时:")
    
    local hourInput = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    hourInput:SetSize(50, 20)
    hourInput:SetPoint("LEFT", hourLabel, "RIGHT", 10, 0)
    hourInput:SetText(tostring(currentTime.hour))
    hourInput:SetMaxLetters(2)
    hourInput:SetAutoFocus(false)
    
    -- 分钟输入框
    local minuteLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    minuteLabel:SetPoint("LEFT", hourInput, "RIGHT", 20, 0)
    minuteLabel:SetText("分钟:")
    
    local minuteInput = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    minuteInput:SetSize(50, 20)
    minuteInput:SetPoint("LEFT", minuteLabel, "RIGHT", 10, 0)
    minuteInput:SetText(tostring(currentTime.min))
    minuteInput:SetMaxLetters(2)
    minuteInput:SetAutoFocus(false)
    
    -- 地图名称输入框
    local zoneLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoneLabel:SetPoint("TOPLEFT", hourLabel, "BOTTOMLEFT", 0, -30)
    zoneLabel:SetText("地图:")
    
    local zoneInput = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    zoneInput:SetSize(150, 20)
    zoneInput:SetPoint("LEFT", zoneLabel, "RIGHT", 10, 0)
    zoneInput:SetText(currentZone)
    zoneInput:SetMaxLetters(50)
    zoneInput:SetAutoFocus(false)
    
    -- 地图下拉按钮
    local zoneDropdownButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    zoneDropdownButton:SetSize(20, 20)
    zoneDropdownButton:SetPoint("LEFT", zoneInput, "RIGHT", 5, 0)
    zoneDropdownButton:SetText("▼")
    
    -- 创建地图下拉菜单
    self:CreateZoneDropdown(dialog, zoneInput, predefinedZones)
    
    zoneDropdownButton:SetScript("OnClick", function()
        self:ToggleZoneDropdown()
    end)
    
    -- Save 按钮
    local saveButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    saveButton:SetSize(80, 25)
    saveButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -20, 20)
    saveButton:SetText("Save")
    
    -- Cancel 按钮
    local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, 25)
    cancelButton:SetPoint("RIGHT", saveButton, "LEFT", -10, 0)
    cancelButton:SetText("Cancel")
    
    -- 输入验证和按钮状态更新
    local function validateInput()
        local hourText = hourInput:GetText()
        local minuteText = minuteInput:GetText()
        local zoneText = zoneInput:GetText()
        
        local hourValid = hourText and hourText:match("^%d+$") and tonumber(hourText) >= 0 and tonumber(hourText) <= 23
        local minuteValid = minuteText and minuteText:match("^%d+$") and tonumber(minuteText) >= 0 and tonumber(minuteText) <= 59
        local zoneValid = zoneText and zoneText:len() > 0
        
        if hourValid and minuteValid and zoneValid then
            saveButton:Enable()
            saveButton:SetAlpha(1)
        else
            saveButton:Disable()
            saveButton:SetAlpha(0.5)
        end
    end
    
    -- 绑定输入验证
    hourInput:SetScript("OnTextChanged", validateInput)
    minuteInput:SetScript("OnTextChanged", validateInput)
    zoneInput:SetScript("OnTextChanged", validateInput)
    
    -- 初始验证
    validateInput()
    
    -- 按钮事件
    saveButton:SetScript("OnClick", function()
        local hour = tonumber(hourInput:GetText())
        local minute = tonumber(minuteInput:GetText())
        local zoneName = zoneInput:GetText()
        
        self:CreateManualTimer(hour, minute, zoneName)
        dialog:Hide()
    end)
    
    cancelButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    -- ESC 键关闭
    dialog:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            dialog:Hide()
        end
    end)
    dialog:EnableKeyboard(true)
    
    self.manualTimerDialog = dialog
    dialog:Show()
end

-- 创建地图下拉菜单
function TimerUI:CreateZoneDropdown(parent, targetInput, zoneList)
    local dropdown = CreateFrame("Frame", nil, UIParent)
    dropdown:SetSize(170, math.min(200, #zoneList * 25 + 10))
    dropdown:SetPoint("TOPLEFT", targetInput, "BOTTOMLEFT", 0, -2)
    dropdown:SetFrameStrata("DIALOG")
    dropdown:SetFrameLevel(1001)
    dropdown:Hide()
    
    -- 下拉框背景（不透明，防止后面按钮文字透过来）
    local bg = dropdown:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 1.0) -- 完全不透明
    
    -- 边框
    local border = dropdown:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(1, 1, 1, 0.3)
    
    -- 创建选项
    local options = {}
    for i, zoneName in ipairs(zoneList) do
        local option = CreateFrame("Button", nil, dropdown)
        option:SetSize(160, 20)
        option:SetPoint("TOP", dropdown, "TOP", 0, -5 - (i-1) * 22)
        
        -- 选项背景
        local optionBg = option:CreateTexture(nil, "BACKGROUND")
        optionBg:SetAllPoints()
        optionBg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
        optionBg:Hide()
        
        -- 选项文本
        local optionText = option:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        optionText:SetPoint("LEFT", option, "LEFT", 5, 0)
        optionText:SetText(zoneName)
        optionText:SetTextColor(1, 1, 1, 1)
        
        -- 鼠标事件
        option:SetScript("OnEnter", function()
            optionBg:Show()
        end)
        
        option:SetScript("OnLeave", function()
            optionBg:Hide()
        end)
        
        option:SetScript("OnClick", function()
            targetInput:SetText(zoneName)
            self:HideZoneDropdown()
        end)
        
        table.insert(options, option)
    end
    
    self.zoneDropdown = dropdown
    self.zoneDropdownOptions = options
    self.zoneDropdownInput = targetInput
end

-- 切换地图下拉菜单
function TimerUI:ToggleZoneDropdown()
    if not self.zoneDropdown then
        return
    end
    
    if self.zoneDropdown:IsVisible() then
        self:HideZoneDropdown()
    else
        self:ShowZoneDropdown()
    end
end

-- 显示地图下拉菜单
function TimerUI:ShowZoneDropdown()
    if not self.zoneDropdown then
        return
    end
    
    self.zoneDropdown:Show()
    
    -- 创建点击捕获器
    if not self.zoneClickCatcher then
        self.zoneClickCatcher = CreateFrame("Frame", nil, UIParent)
        self.zoneClickCatcher:SetAllPoints(UIParent)
        self.zoneClickCatcher:SetFrameLevel(self.zoneDropdown:GetFrameLevel() - 1)
        self.zoneClickCatcher:EnableMouse(true)
        self.zoneClickCatcher:SetScript("OnMouseDown", function()
            TimerUI:HideZoneDropdown()
        end)
    end
    
    self.zoneClickCatcher:Show()
end

-- 隐藏地图下拉菜单
function TimerUI:HideZoneDropdown()
    if self.zoneDropdown then
        self.zoneDropdown:Hide()
    end
    
    if self.zoneClickCatcher then
        self.zoneClickCatcher:Hide()
    end
end

-- 创建手动计时器
function TimerUI:CreateManualTimer(hour, minute, zoneName)
    -- 获取当前时间
    local currentTime = date("*t")
    local currentSeconds = currentTime.hour * 3600 + currentTime.min * 60 + currentTime.sec
    
    -- 计算目标时间（输入的时间加上18分12秒）
    local targetTime = hour * 3600 + minute * 60 + 1092 -- 加上18分12秒
    
    -- 如果目标时间小于等于当前时间，则认为是第二天
    if targetTime <= currentSeconds then
        targetTime = targetTime + 24 * 3600 -- 第二天
    end
    
    -- 计算剩余时间（这就是倒计时的时长）
    local totalDuration = targetTime - currentSeconds
    
    -- 创建计时器数据
    local timerData = {
        zoneName = zoneName,
        duration = totalDuration,
        triggerType = "MANUAL",
        startTime = GetTime(),
        triggerTime = string.format("%02d:%02d", hour, minute),
        expired = false,
        id = "manual_" .. GetTime() .. "_" .. math.random(1000, 9999)
    }
    
    -- 添加计时器
    self:AddTimer(timerData)

    addon.Utils:Info(string.format("手动添加计时器: %s, 目标时间: %02d:%02d", zoneName, hour, minute))
end

-- 保存计时器数据到数据库
function TimerUI:SaveTimersToDatabase()
    if not self.timers then
        return
    end

    -- 初始化保存的数据结构
    if not addon.Config:Get("savedTimers") then
        addon.Config:Set("savedTimers", {})
    end

    local savedData = {}
    local currentTime = GetTime()

    for _, timer in ipairs(self.timers) do
        -- 只保存未过期超过1小时的计时器
        local remaining = timer.duration - (currentTime - timer.startTime)
        if remaining > -3600 then -- 只保存过期不超过1小时的计时器
            table.insert(savedData, {
                zoneName = timer.zoneName,
                duration = timer.duration,
                triggerType = timer.triggerType,
                triggerTime = timer.triggerTime,
                startTime = timer.startTime,
                expired = timer.expired,
                saveTime = currentTime -- 记录保存时间
            })
        end
    end

    addon.Config:Set("savedTimers", savedData)
    addon.Utils:Debug("保存了 " .. #savedData .. " 个计时器到数据库")
end

-- 从数据库加载计时器数据
function TimerUI:LoadTimersFromDatabase()
    local savedData = addon.Config:Get("savedTimers")
    if not savedData or #savedData == 0 then
        return
    end

    local loadedCount = 0
    local currentTime = GetTime()

    for _, timerData in ipairs(savedData) do
        -- 检查保存的计时器是否还有效（不超过1小时）
        local timeSinceSave = currentTime - (timerData.saveTime or 0)
        if timeSinceSave <= 3600 then -- 只加载保存时间不超过1小时的计时器
            -- 调整startTime以适应加载时的时间差
            local adjustedTimer = {
                id = addon.Utils:GenerateID(),
                zoneName = timerData.zoneName,
                duration = timerData.duration,
                triggerType = timerData.triggerType,
                triggerTime = timerData.triggerTime,
                startTime = timerData.startTime,
                expired = timerData.expired
            }

            table.insert(self.timers, adjustedTimer)
            loadedCount = loadedCount + 1
        end
    end

    if loadedCount > 0 then
        -- 排序并创建UI
        self:SortTimersByRemainingTime()
        for _, timer in ipairs(self.timers) do
            self:CreateProgressBar(timer)
        end
        self:RearrangeProgressBars()
        self:UpdateFrameSize()

        addon.Utils:Info("从数据库加载了 " .. loadedCount .. " 个计时器")
    end

    -- 清理过期的保存数据
    self:CleanupSavedTimers()
end

-- 清理过期的保存数据
function TimerUI:CleanupSavedTimers()
    local savedData = addon.Config:Get("savedTimers")
    if not savedData then
        return
    end

    local currentTime = GetTime()
    local cleanData = {}

    for _, timerData in ipairs(savedData) do
        local timeSinceSave = currentTime - (timerData.saveTime or 0)
        if timeSinceSave <= 3600 then -- 保留1小时内的数据
            table.insert(cleanData, timerData)
        end
    end

    if #cleanData < #savedData then
        addon.Config:Set("savedTimers", cleanData)
        addon.Utils:Debug("清理了 " .. (#savedData - #cleanData) .. " 个过期的保存计时器")
    end
end