# API 兼容性修复文档

## 魔兽世界 11.2 版本 API 变更处理

本文档记录了为使 AirdropHelper 插件兼容魔兽世界 11.2 版本而进行的 API 修复。

## 修复的API问题

### 1. IsAddOnLoaded 函数变更
**问题**: `IsAddOnLoaded` 函数在 11.2 中已被移到 `C_AddOns.IsAddOnLoaded`

**影响文件**:
- `Core/Utils.lua`
- `AirdropDetector.lua`

**修复方案**:
```lua
-- 旧版本 (11.1及以前)
local isLoaded = IsAddOnLoaded("HandyNotes")

-- 新版本兼容写法
local isLoaded = false
if C_AddOns and C_AddOns.IsAddOnLoaded then
    isLoaded = C_AddOns.IsAddOnLoaded("HandyNotes")
elseif IsAddOnLoaded then
    isLoaded = IsAddOnLoaded("HandyNotes")
else
    isLoaded = false
end
```

### 2. GetObjectName 函数移除
**问题**: `GetObjectName` 函数在 11.2 中已被移除或变更

**影响文件**:
- `AirdropDetector.lua`

**修复方案**:
```lua
-- 旧版本代码 (已注释)
-- local objectName = GetObjectName("target" .. i)

-- 新版本替代方案
-- 使用 C_VignetteInfo API 或其他地图标记 API 来检测空投箱子
-- 当前实现专注于 vignette 检测而非直接对象扫描
```

### 3. EasyMenu 和 UIDropDownMenuTemplate 变更
**问题**: 下拉菜单相关 API 在 11.2 中可能不稳定

**影响文件**:
- `TimerUI.lua`

**修复方案**:
```lua
-- 旧版本复杂菜单
-- EasyMenu(menu, CreateFrame("Frame", "MenuName", UIParent, "UIDropDownMenuTemplate"), ...)

-- 新版本简化实现
function TimerUI:ShowContextMenu()
    -- 使用聊天输出代替复杂的下拉菜单
    print("|cFF00FF00空投计时器菜单:|r")
    print("1. " .. (self.isLocked and "解锁位置" or "锁定位置"))
    -- 直接执行常用操作
    self:SetLocked(not self.isLocked)
end
```

### 4. ChatTypeInfo 兼容性
**问题**: `ChatTypeInfo` 表结构可能在某些情况下不可用

**影响文件**:
- `NotificationSystem.lua`

**修复方案**:
```lua
-- 兼容性检查
local chatTypeInfo = ChatTypeInfo and ChatTypeInfo["RAID_WARNING"]
if chatTypeInfo then
    RaidNotice_AddMessage(RaidWarningFrame, message, chatTypeInfo)
else
    -- 手动创建颜色信息
    RaidNotice_AddMessage(RaidWarningFrame, message, {r=1, g=0.3, b=0.1})
end
```

## 测试建议

### 基本功能测试
1. 启动插件：`/adh` 查看命令帮助
2. 测试触发：`/adh test` 触发测试空投
3. 界面操作：右键点击计时器窗口测试菜单
4. 调试模式：`/adh debug` 开启调试输出

### API 兼容性测试
1. 检查依赖检测：观察启动时的 HandyNotes 检测结果
2. 测试通知系统：加入队伍/团队测试不同通知方式
3. 验证 UI 功能：拖拽、锁定/解锁界面
4. 监控错误：开启 Lua 错误显示，观察是否有 API 调用错误

## 版本兼容性

### 支持的版本
- **主要支持**: 魔兽世界 11.2.x (The War Within)
- **兼容性**: 11.1.x (向后兼容)

### 不支持的版本
- 11.0.x 及更早版本可能需要额外的兼容性处理

## 未来API变更应对

### 1. 监控 API 变更
- 关注暴雪官方 API 文档更新
- 在 PTR 服务器测试新版本
- 社区反馈收集

### 2. 防御性编程
- 使用 `pcall` 包装可能失败的 API 调用
- 提供多重备用方案
- 详细的错误日志记录

### 3. 渐进式升级
- 保持向后兼容性
- 逐步迁移到新 API
- 清晰的版本文档记录

## 常见问题解决

### Q: 插件加载失败，提示 API 错误
A: 
1. 确认魔兽世界客户端版本为 11.2+
2. 检查是否有其他插件冲突
3. 尝试 `/reload` 重新加载 UI
4. 开启调试模式查看详细错误信息

### Q: 某些功能不工作
A:
1. 检查相关 API 是否可用
2. 查看错误日志中的具体报错
3. 考虑使用替代功能
4. 报告问题以便更新

### Q: 如何检查API兼容性
A:
```lua
-- 检查API可用性的通用方法
local function checkAPI(apiName, apiFunction)
    if apiFunction then
        print(apiName .. ": 可用")
        return true
    else
        print(apiName .. ": 不可用")
        return false
    end
end

-- 使用示例
checkAPI("C_AddOns.IsAddOnLoaded", C_AddOns and C_AddOns.IsAddOnLoaded)
checkAPI("IsAddOnLoaded", IsAddOnLoaded)
```

---

**最后更新**: 2025-09-19  
**适用版本**: AirdropHelper v1.0.0+  
**魔兽世界版本**: 11.2.x