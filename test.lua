-- Roblox 高级通知系统
-- 功能：创建可自定义的通知UI，支持多种样式、动画效果、拖放和声音效果

local Notify = {}

-- 服务引用
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

-- 通知配置
local config = {
    notificationLifetime = 3, -- 通知显示时间（秒）
    fadeInTime = 0.3, -- 淡入时间
    fadeOutTime = 0.3, -- 淡出时间
    offsetBetweenNotifs = 60, -- 通知之间的垂直间距
    maxVisibleNotifs = 5, -- 最大可见通知数
    defaultPosition = UDim2.new(1, -260, 0, 20), -- 默认位置（右上角）
    animationStyle = "slide", -- 动画样式: slide, fade, bounce, zoom, elastic
    defaultTheme = "default", -- 默认主题
    enableSounds = true, -- 是否启用声音
    enableDrag = true, -- 是否启用拖放
    autoHideContainer = false, -- 没有通知时自动隐藏容器
    containerVisible = true, -- 容器可见状态
    pauseOnHover = true, -- 悬停时暂停计时
    showProgressBar = true, -- 显示进度条
    showCloseButton = true -- 显示关闭按钮
}

-- 通知主题
local themes = {
    default = {
        backgroundColor = Color3.fromRGB(30, 30, 30),
        borderColor = Color3.fromRGB(60, 60, 60),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(200, 200, 200),
        iconColor = Color3.fromRGB(70, 130, 180),
        cornerRadius = 4,
        soundName = "default"
    },
    success = {
        backgroundColor = Color3.fromRGB(20, 60, 20),
        borderColor = Color3.fromRGB(40, 120, 40),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(180, 255, 180),
        iconColor = Color3.fromRGB(0, 255, 0),
        cornerRadius = 4,
        soundName = "success"
    },
    error = {
        backgroundColor = Color3.fromRGB(60, 20, 20),
        borderColor = Color3.fromRGB(120, 40, 40),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(255, 180, 180),
        iconColor = Color3.fromRGB(255, 0, 0),
        cornerRadius = 4,
        soundName = "error"
    },
    warning = {
        backgroundColor = Color3.fromRGB(60, 50, 20),
        borderColor = Color3.fromRGB(120, 100, 40),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(255, 240, 180),
        iconColor = Color3.fromRGB(255, 200, 0),
        cornerRadius = 4,
        soundName = "warning"
    },
    info = {
        backgroundColor = Color3.fromRGB(20, 40, 60),
        borderColor = Color3.fromRGB(40, 80, 120),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(180, 220, 255),
        iconColor = Color3.fromRGB(0, 150, 255),
        cornerRadius = 4,
        soundName = "info"
    },
    -- 新增主题
    primary = {
        backgroundColor = Color3.fromRGB(25, 118, 210),
        borderColor = Color3.fromRGB(33, 150, 243),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(224, 242, 254),
        iconColor = Color3.fromRGB(193, 230, 255),
        cornerRadius = 8,
        soundName = "info"
    },
    dark = {
        backgroundColor = Color3.fromRGB(40, 40, 40),
        borderColor = Color3.fromRGB(80, 80, 80),
        titleColor = Color3.fromRGB(255, 255, 255),
        messageColor = Color3.fromRGB(180, 180, 180),
        iconColor = Color3.fromRGB(100, 100, 100),
        cornerRadius = 6,
        soundName = "default"
    },
    light = {
        backgroundColor = Color3.fromRGB(245, 245, 245),
        borderColor = Color3.fromRGB(200, 200, 200),
        titleColor = Color3.fromRGB(50, 50, 50),
        messageColor = Color3.fromRGB(100, 100, 100),
        iconColor = Color3.fromRGB(200, 200, 200),
        cornerRadius = 6,
        soundName = "default"
    }
}

-- 通知队列和UI引用
local notificationQueue = {}
local activeNotifications = {}
local uiContainer = nil
local dragInfo = nil -- 用于拖放功能

-- 声音效果管理
local notificationSounds = {}
local soundParent = nil

-- 初始化声音系统
local function initSoundSystem()
    if soundParent then return end
    
    -- 创建声音父对象
    soundParent = Instance.new("SoundGroup")
    soundParent.Name = "NotificationSounds"
    soundParent.Volume = 0.5
    soundParent.Parent = SoundService
    
    -- 创建基础声音
    local soundsToCreate = {
        default = {Pitch = 1.0, Volume = 0.3},
        success = {Pitch = 1.2, Volume = 0.3},
        error = {Pitch = 0.8, Volume = 0.4},
        warning = {Pitch = 1.0, Volume = 0.35},
        info = {Pitch = 1.1, Volume = 0.25}
    }
    
    for name, properties in pairs(soundsToCreate) do
        local sound = Instance.new("Sound")
        sound.Name = name
        sound.SoundId = "rbxassetid://5637153838" -- 通用通知音效
        sound.Volume = properties.Volume
        sound.Pitch = properties.Pitch
        sound.SoundGroup = soundParent
        sound.Parent = soundParent
        notificationSounds[name] = sound
    end
end

-- 播放通知声音
local function playNotificationSound(soundName)
    if not config.enableSounds then return end
    
    -- 确保声音系统已初始化
    initSoundSystem()
    
    -- 播放声音
    local sound = notificationSounds[soundName] or notificationSounds.default
    if sound then
        sound:Play()
    end
end

-- 初始化UI容器
local function initUIContainer()
    if uiContainer then return uiContainer end
    
    -- 创建ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NotificationSystem"
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    ScreenGui.DisplayOrder = 9999 -- 确保通知在最上层
    ScreenGui.IgnoreGuiInset = true -- 忽略安全区域
    
    -- 创建容器Frame
    local Container = Instance.new("Frame")
    Container.Name = "NotificationContainer"
    Container.Size = UDim2.new(0, 250, 0, 300)
    Container.Position = config.defaultPosition
    Container.BackgroundTransparency = 1
    Container.ClipsDescendants = false
    Container.Parent = ScreenGui
    Container.Visible = config.containerVisible
    
    -- 添加拖放支持
    if config.enableDrag then
        Container.Active = true
        Container.Selectable = true
        
        -- 开始拖动
        Container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragInfo = {
                    startPosition = input.Position,
                    startContainerPosition = Container.Position,
                    isDragging = true
                }
                
                -- 临时高亮容器背景
                local originalTransparency = Container.BackgroundTransparency
                Container.BackgroundTransparency = 0.1
                Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                
                -- 拖动结束后恢复
                local connection
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragInfo.isDragging = false
                        Container.BackgroundTransparency = originalTransparency
                        connection:Disconnect()
                    end
                end)
            end
        end)
        
        -- 拖动中
        UserInputService.InputChanged:Connect(function(input)
            if dragInfo and dragInfo.isDragging and (
                input.UserInputType == Enum.UserInputType.MouseMovement or 
                input.UserInputType == Enum.UserInputType.Touch
            ) then
                local delta = input.Position - dragInfo.startPosition
                local newPosition = UDim2.new(
                    dragInfo.startContainerPosition.X.Scale,
                    dragInfo.startContainerPosition.X.Offset + delta.X,
                    dragInfo.startContainerPosition.Y.Scale,
                    dragInfo.startContainerPosition.Y.Offset + delta.Y
                )
                
                -- 限制在屏幕内
                local viewportSize = workspace.CurrentCamera.ViewportSize
                newPosition = UDim2.new(
                    math.clamp(newPosition.X.Scale, 0, 1),
                    math.clamp(newPosition.X.Offset, 0, viewportSize.X - Container.AbsoluteSize.X),
                    math.clamp(newPosition.Y.Scale, 0, 1),
                    math.clamp(newPosition.Y.Offset, 0, viewportSize.Y - Container.AbsoluteSize.Y)
                )
                
                Container.Position = newPosition
            end
        end)
        
        -- 拖动结束
        UserInputService.InputEnded:Connect(function(input)
            if dragInfo and dragInfo.isDragging and (
                input.UserInputType == Enum.UserInputType.MouseButton1 or 
                input.UserInputType == Enum.UserInputType.Touch
            ) then
                dragInfo.isDragging = false
            end
        end)
    end
    
    uiContainer = Container
    return Container
end

-- 创建通知图标
local function createNotificationIcon(theme)
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 36, 0, 36)
    iconFrame.BackgroundColor3 = theme.iconColor
    iconFrame.BorderSizePixel = 0
    
    -- 使用UICorner代替Shape属性实现圆角
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = iconFrame
    
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
    local showSound = options.showSound ~= nil and options.showSound or true
    local animationStyle = options.animationStyle or config.animationStyle
    local showProgressBar = options.showProgressBar ~= nil and options.showProgressBar or config.showProgressBar
    local showCloseButton = options.showCloseButton ~= nil and options.showCloseButton or config.showCloseButton
    local pauseOnHover = options.pauseOnHover ~= nil and options.pauseOnHover or config.pauseOnHover
    
    -- 创建通知对象
    local notificationObj = {
        title = title,
        message = message,
        lifetime = lifetime,
        remainingLifetime = lifetime,
        theme = theme,
        themeName = themeName,
        icon = icon,
        clickCallback = clickCallback,
        priority = priority,
        frame = nil,
        animationStyle = animationStyle,
        showSound = showSound,
        showProgressBar = showProgressBar,
        showCloseButton = showCloseButton,
        pauseOnHover = pauseOnHover,
        isPaused = false,
        lifetimeTimer = nil,
        progressBar = nil
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
        -- 自动隐藏容器
        if config.autoHideContainer and uiContainer then
            uiContainer.Visible = false
            config.containerVisible = false
        end
        return
    end
    
    -- 显示容器
    if uiContainer and not uiContainer.Visible then
        uiContainer.Visible = true
        config.containerVisible = true
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
    
    -- 播放通知声音
    if nextNotification.showSound then
        playNotificationSound(nextNotification.theme.soundName)
    end
    
    -- 启动动画
    animateNotificationIn(notificationFrame, nextNotification.themeName, nextNotification.animationStyle)
    
    -- 设置生命周期计时器
    startNotificationLifetimeTimer(nextNotification)
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
        -- 默认图标（根据主题显示不同图标）
        local iconText = "!"
        if notification.themeName == "success" then
            iconText = "✓"
        elseif notification.themeName == "error" then
            iconText = "✕"
        elseif notification.themeName == "warning" then
            iconText = "⚠"
        elseif notification.themeName == "info" then
            iconText = "ℹ"
        end
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 1, 0)
        iconLabel.Text = iconText
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
    titleLabel.Size = UDim2.new(1, notification.showCloseButton and -80 or -60, 0, 20)
    titleLabel.Position = UDim2.new(0, 52, 0, 8)
    titleLabel.Text = notification.title
    titleLabel.TextColor3 = theme.titleColor
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = mainFrame
    
    -- 创建关闭按钮
    if notification.showCloseButton then
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Size = UDim2.new(0, 16, 0, 16)
        closeButton.Position = UDim2.new(1, -24, 0, 12)
        closeButton.Text = "✕"
        closeButton.TextColor3 = theme.titleColor
        closeButton.TextSize = 14
        closeButton.BackgroundTransparency = 1
        closeButton.Font = Enum.Font.SourceSansBold
        closeButton.Parent = mainFrame
        
        -- 关闭按钮悬停效果
        closeButton.MouseEnter:Connect(function()
            closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        
        closeButton.MouseLeave:Connect(function()
            closeButton.TextColor3 = theme.titleColor
        end)
        
        -- 关闭按钮点击事件
        closeButton.MouseButton1Click:Connect(function()
            -- 立即销毁通知
            if notification.frame and notification.frame.Parent then
                animateNotificationOut(notification.frame, notification.animationStyle, function()
                    -- 从活跃列表中移除
                    for i, notif in ipairs(activeNotifications) do
                        if notif.frame == notification.frame then
                            table.remove(activeNotifications, i)
                            break
                        end
                    end
                    
                    -- 销毁通知
                    if notification.frame and notification.frame.Parent then
                        notification.frame:Destroy()
                    end
                    
                    -- 重新定位剩余通知
                    repositionActiveNotifications()
                    
                    -- 处理下一个队列中的通知
                    processNotificationQueue()
                end)
            end
        end)
    end
    
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
    
    -- 进度条
    local totalHeight = math.max(52, messageHeight + 38)
    if notification.showProgressBar then
        -- 添加进度条空间
        totalHeight = totalHeight + 3
        
        local progressBarBg = Instance.new("Frame")
        progressBarBg.Name = "ProgressBarBackground"
        progressBarBg.Size = UDim2.new(1, 0, 0, 3)
        progressBarBg.Position = UDim2.new(0, 0, 1, -3)
        progressBarBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        progressBarBg.BackgroundTransparency = 0.5
        progressBarBg.BorderSizePixel = 0
        progressBarBg.Parent = mainFrame
        
        local progressBar = Instance.new("Frame")
        progressBar.Name = "ProgressBar"
        progressBar.Size = UDim2.new(1, 0, 1, 0)
        progressBar.BackgroundColor3 = theme.iconColor
        progressBar.BorderSizePixel = 0
        progressBar.Parent = progressBarBg
        
        -- 保存进度条引用
        notification.progressBar = progressBar
    end
    
    -- 调整主框架大小
    mainFrame.Size = UDim2.new(0, 250, 0, totalHeight)
    
    -- 添加到容器
    mainFrame.Parent = uiContainer
    
    -- 保存对框架的引用
    notification.frame = mainFrame
    
    -- 悬停暂停功能
    if notification.pauseOnHover then
        mainFrame.Active = true
        mainFrame.Selectable = true
        
        mainFrame.MouseEnter:Connect(function()
            if not notification.isPaused then
                notification.isPaused = true
                -- 停止当前计时器
                if notification.lifetimeTimer then
                    task.cancel(notification.lifetimeTimer)
                end
            end
            
            -- 悬停背景色变化
            mainFrame.BackgroundColor3 = theme.backgroundColor:Lerp(Color3.fromRGB(255, 255, 255), 0.1)
        end)
        
        mainFrame.MouseLeave:Connect(function()
            if notification.isPaused then
                notification.isPaused = false
                -- 重新启动计时器
                if notification.remainingLifetime > 0 then
                    startNotificationLifetimeTimer(notification)
                end
            end
            
            -- 恢复背景色
            mainFrame.BackgroundColor3 = theme.backgroundColor
        end)
    end
    
    -- 如果有点击回调，添加点击事件
    if notification.clickCallback then
        mainFrame.Active = true
        mainFrame.Selectable = true
        
        mainFrame.MouseButton1Click:Connect(function()
            notification.clickCallback(notification)
        end)
    end
    
    return mainFrame
end

-- 启动通知生命周期计时器
function startNotificationLifetimeTimer(notification)
    -- 如果已经有计时器运行，先取消
    if notification.lifetimeTimer then
        task.cancel(notification.lifetimeTimer)
    end
    
    -- 更新进度条
    if notification.progressBar then
        local progressTween = TweenService:Create(
            notification.progressBar,
            TweenInfo.new(notification.remainingLifetime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 0, 1, 0)}
        )
        progressTween:Play()
    end
    
    -- 设置生命周期计时器
    notification.lifetimeTimer = task.delay(notification.remainingLifetime, function()
        -- 淡出动画
        animateNotificationOut(notification.frame, notification.animationStyle, function()
            -- 从活跃列表中移除
            for i, notif in ipairs(activeNotifications) do
                if notif.frame == notification.frame then
                    table.remove(activeNotifications, i)
                    break
                end
            end
            
            -- 销毁通知
            if notification.frame and notification.frame.Parent then
                notification.frame:Destroy()
            end
            
            -- 重新定位剩余通知
            repositionActiveNotifications()
            
            -- 处理下一个队列中的通知
            processNotificationQueue()
        end)
    end)
end

-- 重新定位活跃通知
function repositionActiveNotifications()
    for i, notification in ipairs(activeNotifications) do
        if notification.frame and notification.frame.Parent then
            -- 计算位置
            local yOffset = (i - 1) * (notification.frame.AbsoluteSize.Y + config.offsetBetweenNotifs)
            
            -- 移动通知
            local moveTween = TweenService:Create(
                notification.frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(0, 0, 0, yOffset)}
            )
            moveTween:Play()
        end
    end
    
    -- 自动隐藏容器
    if #activeNotifications == 0 and config.autoHideContainer and uiContainer then
        uiContainer.Visible = false
        config.containerVisible = false
    end
end

-- 进入动画
function animateNotificationIn(notificationFrame, themeName, animationStyle)
    animationStyle = animationStyle or config.animationStyle
    notificationFrame.Visible = true
    
    if animationStyle == "slide" then
        -- 初始位置在屏幕外
        notificationFrame.Position = UDim2.new(1, 10, 0, notificationFrame.Position.Y.Offset)
        
        -- 滑动动画
        TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 0, 0, notificationFrame.Position.Y.Offset)}
        ):Play()
        
    elseif animationStyle == "fade" then
        -- 淡入动画
        notificationFrame.Transparency = 1
        TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 0}
        ):Play()
        
    elseif animationStyle == "bounce" then
        -- 初始大小很小
        notificationFrame.Size = UDim2.new(0, 0, 0, notificationFrame.AbsoluteSize.Y)
        notificationFrame.Position = UDim2.new(0.5, -notificationFrame.AbsoluteSize.X/2, 0, notificationFrame.Position.Y.Offset)
        
        -- 弹跳动画
        TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 250, 0, notificationFrame.AbsoluteSize.Y),
             Position = UDim2.new(0, 0, 0, notificationFrame.Position.Y.Offset)}
        ):Play()
        
    elseif animationStyle == "zoom" then
        -- 缩放动画
        notificationFrame.Size = UDim2.new(0, 0, 0, 0)
        notificationFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        notificationFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        
        TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 250, 0, notificationFrame.AbsoluteSize.Y),
             Position = UDim2.new(0, 0, 0, notificationFrame.Position.Y.Offset),
             AnchorPoint = Vector2.new(0, 0)}
        ):Play()
        
    elseif animationStyle == "elastic" then
        -- 弹性动画
        notificationFrame.Size = UDim2.new(0, 250, 0, notificationFrame.AbsoluteSize.Y)
        notificationFrame.Position = UDim2.new(1, 10, 0, notificationFrame.Position.Y.Offset)
        
        TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime * 1.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 0, 0, notificationFrame.Position.Y.Offset)}
        ):Play()
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
function animateNotificationOut(notificationFrame, animationStyle, onComplete)
    animationStyle = animationStyle or config.animationStyle
    
    if animationStyle == "slide" then
        -- 滑动出屏幕
        local slideTween = TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, 0, notificationFrame.Position.Y.Offset)}
        )
        
        slideTween.Completed:Connect(onComplete)
        slideTween:Play()
        
    elseif animationStyle == "fade" then
        -- 淡出
        local fadeTween = TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Transparency = 1}
        )
        
        fadeTween.Completed:Connect(onComplete)
        fadeTween:Play()
        
    elseif animationStyle == "bounce" then
        -- 缩小
        local shrinkTween = TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, notificationFrame.AbsoluteSize.Y),
             Position = UDim2.new(0.5, -notificationFrame.AbsoluteSize.X/2, 0, notificationFrame.Position.Y.Offset)}
        )
        
        shrinkTween.Completed:Connect(onComplete)
        shrinkTween:Play()
        
    elseif animationStyle == "zoom" then
        -- 缩放动画
        notificationFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        
        local zoomTween = TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0),
             Position = UDim2.new(0.5, 0, 0.5, 0)}
        )
        
        zoomTween.Completed:Connect(onComplete)
        zoomTween:Play()
        
    elseif animationStyle == "elastic" then
        -- 弹性动画
        local elasticTween = TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime * 1.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, 0, notificationFrame.Position.Y.Offset)}
        )
        
        elasticTween.Completed:Connect(onComplete)
        elasticTween:Play()
    end
end

-- 快捷通知函数
function Notify:Success(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "success"
    options.icon = options.icon or nil
    return self:CreateNotification(options)
end

function Notify:Error(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "error"
    options.icon = options.icon or nil
    return self:CreateNotification(options)
end

function Notify:Warning(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "warning"
    options.icon = options.icon or nil
    return self:CreateNotification(options)
end

function Notify:Info(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "info"
    options.icon = options.icon or nil
    return self:CreateNotification(options)
end

function Notify:Primary(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "primary"
    options.icon = options.icon or nil
    return self:CreateNotification(options)
end

function Notify:Dark(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "dark"
    options.icon = options.icon or nil
    return self:CreateNotification(options)
end

function Notify:Light(title, message, options)
    options = options or {}
    options.title = title
    options.message = message
    options.theme = "light"
    options.icon = options.icon or nil
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

-- 暂停所有通知计时
function Notify:PauseAll()
    for _, notification in ipairs(activeNotifications) do
        if not notification.isPaused then
            notification.isPaused = true
            -- 停止计时器
            if notification.lifetimeTimer then
                task.cancel(notification.lifetimeTimer)
            end
            
            -- 暂停进度条动画
            if notification.progressBar then
                for _, tween in pairs(game:GetService("TweenService"):GetTweensAsync(notification.progressBar)) do
                    tween:Pause()
                end
            end
        end
    end
end

-- 恢复所有通知计时
function Notify:ResumeAll()
    for _, notification in ipairs(activeNotifications) do
        if notification.isPaused then
            notification.isPaused = false
            -- 重新启动计时器
            startNotificationLifetimeTimer(notification)
        end
    end
end

-- 显示通知容器
function Notify:ShowContainer()
    if uiContainer then
        uiContainer.Visible = true
        config.containerVisible = true
    end
end

-- 隐藏通知容器
function Notify:HideContainer()
    if uiContainer then
        uiContainer.Visible = false
        config.containerVisible = false
    end
end

-- 设置通知容器位置
function Notify:SetContainerPosition(position)
    if uiContainer then
        uiContainer.Position = position
    end
end

-- 清除所有通知
function Notify:ClearAll()
    -- 清除队列
    notificationQueue = {}
    
    -- 移除所有活跃通知
    for _, notification in ipairs(activeNotifications) do
        -- 取消计时器
        if notification.lifetimeTimer then
            task.cancel(notification.lifetimeTimer)
        end
        
        -- 销毁通知
        if notification.frame and notification.frame.Parent then
            notification.frame:Destroy()
        end
    end
    
    activeNotifications = {}
    
    -- 自动隐藏容器
    if config.autoHideContainer and uiContainer then
        uiContainer.Visible = false
        config.containerVisible = false
    end
end

-- 示例用法：
-- 基本通知
-- Notify:Success("操作成功", "您的任务已完成！")
-- Notify:Error("错误", "无法完成操作，请重试")
-- Notify:Warning("警告", "即将达到限制")
-- Notify:Info("信息", "新功能已上线")
-- Notify:Primary("主要通知", "这是一条重要通知")
-- Notify:Dark("深色主题", "使用深色主题的通知")
-- Notify:Light("浅色主题", "使用浅色主题的通知")

-- 高级自定义通知
-- Notify:CreateNotification({
--     title = "自定义通知",
--     message = "这是一个带有自定义选项的通知",
--     lifetime = 8, -- 显示8秒
--     theme = "success",
--     priority = 1,
--     showProgressBar = true, -- 显示进度条
--     showCloseButton = true, -- 显示关闭按钮
--     pauseOnHover = true, -- 悬停时暂停计时
--     showSound = true, -- 播放通知声音
--     animationStyle = "elastic", -- 使用弹性动画
--     onClick = function(notification)
--         print("通知被点击")
--         -- 可以在这里执行自定义操作
--     end
-- })

-- 控制通知容器
-- Notify:SetContainerPosition(UDim2.new(1, -270, 0, 20)) -- 设置在右上角
-- Notify:ShowContainer() -- 显示容器
-- Notify:HideContainer() -- 隐藏容器

-- 批量控制通知
-- Notify:PauseAll() -- 暂停所有通知计时
-- Notify:ResumeAll() -- 恢复所有通知计时
-- Notify:ClearAll() -- 清除所有通知

-- 导出通知系统
_G.Notify = Notify
return Notify
