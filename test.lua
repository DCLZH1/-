-- Roblox 高级通知系统
-- 功能：创建可自定义的通知UI，支持多种样式、动画效果和队列管理

local Notify = {}

-- 通知配置
local config = {
    notificationLifetime = 3, -- 通知显示时间（秒）
    fadeInTime = 0.3, -- 淡入时间
    fadeOutTime = 0.3, -- 淡出时间
    offsetBetweenNotifs = 60, -- 通知之间的垂直间距
    maxVisibleNotifs = 5, -- 最大可见通知数
    defaultPosition = UDim2.new(1, -260, 0, 20), -- 默认位置（右上角）
    animationStyle = "slide", -- 动画样式: slide, fade, bounce
    defaultTheme = "default" -- 默认主题
}

-- 通知主题
local themes = {
    default = {
        backgroundColor = Color3.fromRGB(30, 30, 30),
        borderColor = Color3.fromRGB(60, 60, 60),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(200, 200, 200),
        iconColor = Color3.fromRGB(70, 130, 180),
        cornerRadius = 4
    },
    success = {
        backgroundColor = Color3.fromRGB(20, 60, 20),
        borderColor = Color3.fromRGB(40, 120, 40),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(180, 255, 180),
        iconColor = Color3.fromRGB(0, 255, 0),
        cornerRadius = 4
    },
    error = {
        backgroundColor = Color3.fromRGB(60, 20, 20),
        borderColor = Color3.fromRGB(120, 40, 40),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(255, 180, 180),
        iconColor = Color3.fromRGB(255, 0, 0),
        cornerRadius = 4
    },
    warning = {
        backgroundColor = Color3.fromRGB(60, 50, 20),
        borderColor = Color3.fromRGB(120, 100, 40),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(255, 240, 180),
        iconColor = Color3.fromRGB(255, 200, 0),
        cornerRadius = 4
    },
    info = {
        backgroundColor = Color3.fromRGB(20, 40, 60),
        borderColor = Color3.fromRGB(40, 80, 120),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(180, 220, 255),
        iconColor = Color3.fromRGB(0, 150, 255),
        cornerRadius = 4
    }
}

-- 通知队列和UI引用
local notificationQueue = {}
local activeNotifications = {}
local uiContainer = nil

-- 初始化UI容器
local function initUIContainer()
    if uiContainer then return uiContainer end
    
    -- 创建ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NotificationSystem"
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    ScreenGui.DisplayOrder = 9999 -- 确保通知在最上层
    
    -- 创建容器Frame
    local Container = Instance.new("Frame")
    Container.Name = "NotificationContainer"
    Container.Size = UDim2.new(0, 250, 0, 300)
    Container.Position = config.defaultPosition
    Container.BackgroundTransparency = 1
    Container.ClipsDescendants = false
    Container.Parent = ScreenGui
    
    uiContainer = Container
    return Container
end

-- 创建通知图标
local function createNotificationIcon(theme)
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 36, 0, 36)
    iconFrame.BackgroundColor3 = theme.iconColor
    iconFrame.BorderSizePixel = 0
    iconFrame.Shape = Enum.Shape.RoundCorner
    iconFrame.CornerRadius = UDim.new(0, 6)
    
    return iconFrame
end

-- 创建单个通知
function Notify:CreateNotification(options)
    -- 确保UI容器已初始化
    local container = initUIContainer()
    
    -- 默认选项
    local title = options.title or "通知"
    local message = options.message or "这是一条通知消息"
    local lifetime = options.lifetime or config.notificationLifetime
    local themeName = options.theme or config.defaultTheme
    local theme = themes[themeName] or themes.default
    local icon = options.icon or nil
    local clickCallback = options.onClick or nil
    local priority = options.priority or 0
    
    -- 创建通知对象
    local notificationObj = {
        title = title,
        message = message,
        lifetime = lifetime,
        theme = theme,
        themeName = themeName,
        icon = icon,
        clickCallback = clickCallback,
        priority = priority,
        frame = nil
    }
    
    -- 添加到队列
    table.insert(notificationQueue, notificationObj)
    
    -- 立即处理队列
    processNotificationQueue()
    
    return notificationObj
end

-- 处理通知队列
function processNotificationQueue()
    -- 如果已经有最大数量的通知显示，则不处理
    if #activeNotifications >= config.maxVisibleNotifs then
        return
    end
    
    -- 如果队列为空，结束
    if #notificationQueue == 0 then
        return
    end
    
    -- 按优先级排序队列（优先级越高，越先显示）
    table.sort(notificationQueue, function(a, b)
        return a.priority > b.priority
    end)
    
    -- 获取下一个通知
    local nextNotification = table.remove(notificationQueue, 1)
    
    -- 创建通知UI
    local notificationFrame = createNotificationUI(nextNotification)
    
    -- 更新活跃通知列表
    table.insert(activeNotifications, 1, nextNotification)
    
    -- 重新定位所有通知
    repositionActiveNotifications()
    
    -- 启动动画
    animateNotificationIn(notificationFrame, nextNotification.themeName)
    
    -- 设置生命周期
    task.delay(nextNotification.lifetime, function()
        -- 淡出动画
        animateNotificationOut(notificationFrame, function()
            -- 从活跃列表中移除
            for i, notif in ipairs(activeNotifications) do
                if notif.frame == notificationFrame then
                    table.remove(activeNotifications, i)
                    break
                end
            end
            
            -- 销毁通知
            if notificationFrame and notificationFrame.Parent then
                notificationFrame:Destroy()
            end
            
            -- 重新定位剩余通知
            repositionActiveNotifications()
            
            -- 处理下一个队列中的通知
            processNotificationQueue()
        end)
    end)
end

-- 创建通知UI框架
function createNotificationUI(notification)
    local theme = notification.theme
    
    -- 创建主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Notification"
    mainFrame.Size = UDim2.new(0, 250, 0, 0) -- 初始高度为0，将根据内容调整
    mainFrame.BackgroundColor3 = theme.backgroundColor
    mainFrame.BorderColor3 = theme.borderColor
    mainFrame.BorderSizePixel = 1
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = false
    
    -- 添加圆角
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, theme.cornerRadius)
    uiCorner.Parent = mainFrame
    
    -- 创建图标
    local iconFrame = createNotificationIcon(theme)
    iconFrame.Position = UDim2.new(0, 8, 0, 8)
    iconFrame.Parent = mainFrame
    
    -- 如果提供了自定义图标，使用它
    if notification.icon then
        notification.icon.Size = UDim2.new(1, -4, 1, -4)
        notification.icon.Position = UDim2.new(0, 2, 0, 2)
        notification.icon.Parent = iconFrame
    else
        -- 默认图标
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 1, 0)
        iconLabel.Text = "!"
        iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        iconLabel.TextSize = 20
        iconLabel.TextScaled = true
        iconLabel.BackgroundTransparency = 1
        iconLabel.Font = Enum.Font.SourceSansBold
        iconLabel.Parent = iconFrame
    end
    
    -- 创建标题
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -60, 0, 20)
    titleLabel.Position = UDim2.new(0, 52, 0, 8)
    titleLabel.Text = notification.title
    titleLabel.TextColor3 = theme.titleColor
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = mainFrame
    
    -- 创建消息
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -52, 0, 40)
    messageLabel.Position = UDim2.new(0, 52, 0, 30)
    messageLabel.Text = notification.message
    messageLabel.TextColor3 = theme.messageColor
    messageLabel.TextSize = 12
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.Parent = mainFrame
    
    -- 调整消息标签大小以适应文本
    local textBounds = messageLabel.TextBounds
    local messageHeight = math.max(20, textBounds.Y)
    messageLabel.Size = UDim2.new(1, -52, 0, messageHeight)
    
    -- 调整主框架大小
    mainFrame.Size = UDim2.new(0, 250, 0, math.max(52, messageHeight + 38))
    
    -- 添加到容器
    mainFrame.Parent = uiContainer
    
    -- 保存对框架的引用
    notification.frame = mainFrame
    
    -- 如果有点击回调，添加点击事件
    if notification.clickCallback then
        mainFrame.Active = true
        mainFrame.Selectable = true
        
        local function onMouseEnter()
            mainFrame.BackgroundColor3 = theme.backgroundColor:Lerp(Color3.fromRGB(255, 255, 255), 0.1)
        end
        
        local function onMouseLeave()
            mainFrame.BackgroundColor3 = theme.backgroundColor
        end
        
        local function onClick()
            notification.clickCallback(notification)
        end
        
        mainFrame.MouseEnter:Connect(onMouseEnter)
        mainFrame.MouseLeave:Connect(onMouseLeave)
        mainFrame.MouseButton1Click:Connect(onClick)
    end
    
    return mainFrame
end

-- 重新定位活跃通知
function repositionActiveNotifications()
    for i, notification in ipairs(activeNotifications) do
        if notification.frame and notification.frame.Parent then
            -- 计算位置
            local yOffset = (i - 1) * (notification.frame.AbsoluteSize.Y + config.offsetBetweenNotifs)
            
            -- 移动通知
            local moveTween = game:GetService("TweenService"):Create(
                notification.frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(0, 0, 0, yOffset)}
            )
            moveTween:Play()
        end
    end
end

-- 进入动画
function animateNotificationIn(notificationFrame, themeName)
    notificationFrame.Visible = true
    
    if config.animationStyle == "slide" then
        -- 初始位置在屏幕外
        notificationFrame.Position = UDim2.new(1, 10, 0, notificationFrame.Position.Y.Offset)
        
        -- 滑动动画
        game:GetService("TweenService"):Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 0, 0, notificationFrame.Position.Y.Offset)}
        ):Play()
        
    elseif config.animationStyle == "fade" then
        -- 淡入动画
        notificationFrame.Transparency = 1
        game:GetService("TweenService"):Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 0}
        ):Play()
        
    elseif config.animationStyle == "bounce" then
        -- 初始大小很小
        notificationFrame.Size = UDim2.new(0, 0, 0, notificationFrame.AbsoluteSize.Y)
        notificationFrame.Position = UDim2.new(1, -notificationFrame.AbsoluteSize.X/2, 0, notificationFrame.Position.Y.Offset)
        
        -- 弹跳动画
        local bounceTween = game:GetService("TweenService"):Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 250, 0, notificationFrame.AbsoluteSize.Y),
             Position = UDim2.new(0, 0, 0, notificationFrame.Position.Y.Offset)}
        )
        bounceTween:Play()
    end
    
    -- 添加主题特定的额外效果
    if themeName == "success" or themeName == "error" or themeName == "warning" or themeName == "info" then
        -- 创建短暂的发光效果
        local glowEffect = Instance.new("Frame")
        glowEffect.Size = UDim2.new(1, 10, 1, 10)
        glowEffect.Position = UDim2.new(0, -5, 0, -5)
        glowEffect.BackgroundColor3 = themes[themeName].iconColor
        glowEffect.BackgroundTransparency = 0.7
        glowEffect.ZIndex = notificationFrame.ZIndex - 1
        glowEffect.Parent = notificationFrame.Parent
        
        -- 应用圆角
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = glowEffect
        
        -- 淡出效果
        game:GetService("TweenService"):Create(
            glowEffect,
            TweenInfo.new(config.fadeInTime * 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1, Size = UDim2.new(1, 20, 1, 20), Position = UDim2.new(0, -10, 0, -10)}
        ):Play()
        
        -- 完成后移除
        task.delay(config.fadeInTime * 2, function()
            if glowEffect and glowEffect.Parent then
                glowEffect:Destroy()
            end
        end)
    end
end

-- 退出动画
function animateNotificationOut(notificationFrame, onComplete)
    if config.animationStyle == "slide" then
        -- 滑动出屏幕
        local slideTween = game:GetService("TweenService"):Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, 0, notificationFrame.Position.Y.Offset)}
        )
        
        slideTween.Completed:Connect(onComplete)
        slideTween:Play()
        
    elseif config.animationStyle == "fade" then
        -- 淡出
        local fadeTween = game:GetService("TweenService"):Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Transparency = 1}
        )
        
        fadeTween.Completed:Connect(onComplete)
        fadeTween:Play()
        
    elseif config.animationStyle == "bounce" then
        -- 缩小
        local shrinkTween = game:GetService("TweenService"):Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, notificationFrame.AbsoluteSize.Y),
             Position = UDim2.new(1, -notificationFrame.AbsoluteSize.X/2, 0, notificationFrame.Position.Y.Offset)}
        )
        
        shrinkTween.Completed:Connect(onComplete)
        shrinkTween:Play()
    end
end

-- 快捷通知函数
function Notify:Success(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "success"
    return self:CreateNotification(options)
end

function Notify:Error(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "error"
    return self:CreateNotification(options)
end

function Notify:Warning(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "warning"
    return self:CreateNotification(options)
end

function Notify:Info(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "info"
    return self:CreateNotification(options)
end

-- 配置函数
function Notify:SetConfig(newConfig)
    for key, value in pairs(newConfig) do
        if config[key] ~= nil then
            config[key] = value
        end
    end
end

-- 添加自定义主题
function Notify:AddTheme(themeName, themeConfig)
    themes[themeName] = themeConfig
end

-- 清除所有通知
function Notify:ClearAll()
    -- 清除队列
    notificationQueue = {}
    
    -- 移除所有活跃通知
    for _, notification in ipairs(activeNotifications) do
        if notification.frame and notification.frame.Parent then
            notification.frame:Destroy()
        end
    end
    
    activeNotifications = {}
end

-- 示例用法：
-- Notify:Success("操作成功", "您的任务已完成！")
-- Notify:Error("错误", "无法完成操作，请重试")
-- Notify:Warning("警告", "即将达到限制")
-- Notify:Info("信息", "新功能已上线")

-- 高级用法：
-- Notify:CreateNotification({
--     title = "自定义通知",
--     message = "这是一个带有自定义图标和回调的通知",
--     lifetime = 5,
--     theme = "custom",
--     priority = 1,
--     onClick = function(notification)
--         print("通知被点击")
--     end
-- })

-- 导出通知系统
_G.Notify = Notify

print("[高级通知系统] 已加载")
 
return Notify

