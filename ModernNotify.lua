local ModernNotify = {}

-- 服务引用
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- 配置项
ModernNotify.Config = {
    NotificationLifetime = 5,
    AnimationDuration = 0.3,
    ContainerPadding = 12,
    NotificationSpacing = 8,
    DefaultPosition = "TopRight", -- TopLeft, TopRight, BottomLeft, BottomRight, TopCenter, BottomCenter
    MaxVisibleNotifications = 5,
    AutoHideContainer = true,
    AllowDismissOnClick = true,
    AllowPauseOnHover = true
}

-- 预定义主题
ModernNotify.Themes = {
    Default = {
        BackgroundColor = Color3.fromRGB(30, 30, 30),
        TextColor = Color3.fromRGB(255, 255, 255),
        BorderColor = Color3.fromRGB(50, 50, 50),
        IconColor = Color3.fromRGB(255, 255, 255)
    },
    Success = {
        BackgroundColor = Color3.fromRGB(46, 204, 113),
        TextColor = Color3.fromRGB(255, 255, 255),
        BorderColor = Color3.fromRGB(39, 174, 96),
        IconColor = Color3.fromRGB(255, 255, 255)
    },
    Error = {
        BackgroundColor = Color3.fromRGB(231, 76, 60),
        TextColor = Color3.fromRGB(255, 255, 255),
        BorderColor = Color3.fromRGB(203, 67, 53),
        IconColor = Color3.fromRGB(255, 255, 255)
    },
    Warning = {
        BackgroundColor = Color3.fromRGB(241, 196, 15),
        TextColor = Color3.fromRGB(0, 0, 0),
        BorderColor = Color3.fromRGB(243, 156, 18),
        IconColor = Color3.fromRGB(0, 0, 0)
    },
    Info = {
        BackgroundColor = Color3.fromRGB(52, 152, 219),
        TextColor = Color3.fromRGB(255, 255, 255),
        BorderColor = Color3.fromRGB(41, 128, 185),
        IconColor = Color3.fromRGB(255, 255, 255)
    },
    Gradient = {
        UseGradient = true,
        GradientColors = {Color3.fromRGB(131, 56, 236), Color3.fromRGB(58, 12, 163)},
        TextColor = Color3.fromRGB(255, 255, 255),
        BorderColor = Color3.fromRGB(101, 31, 255),
        IconColor = Color3.fromRGB(255, 255, 255)
    },
    Primary = {
        BackgroundColor = Color3.fromRGB(52, 73, 94),
        TextColor = Color3.fromRGB(255, 255, 255),
        BorderColor = Color3.fromRGB(44, 62, 80),
        IconColor = Color3.fromRGB(255, 255, 255)
    },
    Dark = {
        BackgroundColor = Color3.fromRGB(17, 17, 17),
        TextColor = Color3.fromRGB(230, 230, 230),
        BorderColor = Color3.fromRGB(40, 40, 40),
        IconColor = Color3.fromRGB(230, 230, 230)
    },
    Light = {
        BackgroundColor = Color3.fromRGB(245, 245, 245),
        TextColor = Color3.fromRGB(50, 50, 50),
        BorderColor = Color3.fromRGB(220, 220, 220),
        IconColor = Color3.fromRGB(50, 50, 50)
    },
    Pastel = {
        BackgroundColor = Color3.fromRGB(229, 239, 255),
        TextColor = Color3.fromRGB(40, 60, 80),
        BorderColor = Color3.fromRGB(187, 216, 255),
        IconColor = Color3.fromRGB(40, 60, 80)
    },
    Rainbow = {
        UseGradient = true,
        GradientColors = {Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 127, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255), Color3.fromRGB(75, 0, 130), Color3.fromRGB(148, 0, 211)},
        TextColor = Color3.fromRGB(255, 255, 255),
        BorderColor = Color3.fromRGB(200, 200, 200),
        IconColor = Color3.fromRGB(255, 255, 255)
    }
}

-- 存储通知相关数据
ModernNotify._notifications = {}
ModernNotify._activeNotifications = {}
ModernNotify._container = nil
ModernNotify._notificationQueue = {}
ModernNotify._isContainerVisible = true

-- 初始化UI容器
function ModernNotify:_InitializeContainer()
    if self._container then return self._container end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ModernNotifyScreen"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.Parent = CoreGui
    
    self._container = Instance.new("Frame")
    self._container.Name = "NotificationContainer"
    self._container.BackgroundTransparency = 1
    self._container.ClipsDescendants = false
    self._container.Position = self:_GetContainerPosition()
    self._container.Size = UDim2.new(0, 300, 0, 0)
    self._container.AutomaticSize = Enum.AutomaticSize.Y
    self._container.Parent = screenGui
    
    -- 添加拖放功能
    self:_SetupDragging()
    
    return self._container
end

-- 获取容器位置
function ModernNotify:_GetContainerPosition()
    local position = self.Config.DefaultPosition
    local padding = self.Config.ContainerPadding
    
    if position == "TopLeft" then
        return UDim2.new(0, padding, 0, padding)
    elseif position == "TopRight" then
        return UDim2.new(1, -padding - 300, 0, padding)
    elseif position == "BottomLeft" then
        return UDim2.new(0, padding, 1, -padding)
    elseif position == "BottomRight" then
        return UDim2.new(1, -padding - 300, 1, -padding)
    elseif position == "TopCenter" then
        return UDim2.new(0.5, -150, 0, padding)
    elseif position == "BottomCenter" then
        return UDim2.new(0.5, -150, 1, -padding)
    end
    
    return UDim2.new(1, -padding - 300, 0, padding) -- 默认右上角
end

-- 设置拖放功能
function ModernNotify:_SetupDragging()
    local container = self._container
    local isDragging = false
    local dragStartPos = Vector2.new()
    
    local function updateContainerPosition(input)
        local delta = input.Position - dragStartPos
        local newPos = container.Position + UDim2.new(0, delta.X, 0, delta.Y)
        container.Position = newPos
        dragStartPos = input.Position
    end
    
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartPos = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateContainerPosition(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            isDragging = false
        end
    end)
end

-- 创建通知
function ModernNotify:CreateNotification(options)
    options = options or {}
    
    local notification = {
        title = options.title or "Notification",
        message = options.message or "",
        theme = options.theme or "Default",
        lifetime = options.lifetime or self.Config.NotificationLifetime,
        icon = options.icon,
        onClick = options.onClick,
        onClose = options.onClose,
        showProgress = options.showProgress or false,
        showCloseButton = options.showCloseButton or true,
        pauseOnHover = options.pauseOnHover or self.Config.AllowPauseOnHover,
        canDismiss = options.canDismiss or self.Config.AllowDismissOnClick,
        priority = options.priority or "normal", -- high, normal, low
        id = tostring(#self._notifications + 1)
    }
    
    table.insert(self._notifications, notification)
    table.insert(self._notificationQueue, notification)
    
    -- 立即处理队列，如果有空间
    self:_ProcessNotificationQueue()
    
    return notification.id
end

-- 处理通知队列
function ModernNotify:_ProcessNotificationQueue()
    while #self._activeNotifications < self.Config.MaxVisibleNotifications and #self._notificationQueue > 0 do
        local notification = table.remove(self._notificationQueue, 1)
        self:_DisplayNotification(notification)
    end
end

-- 显示通知
function ModernNotify:_DisplayNotification(notification)
    if not self._container then self:_InitializeContainer() end
    
    -- 创建通知UI
    local notificationFrame = self:_CreateNotificationUI(notification)
    table.insert(self._activeNotifications, notificationFrame)
    
    -- 重新定位所有通知
    self:_RepositionNotifications()
    
    -- 设置生命周期计时器
    self:_StartNotificationLifetime(notificationFrame, notification)
    
    -- 执行进入动画
    self:_AnimateNotificationIn(notificationFrame)
    
    return notificationFrame
end

-- 创建通知UI
function ModernNotify:_CreateNotificationUI(notification)
    local frame = Instance.new("Frame")
    frame.Name = "Notification"
    frame.BackgroundTransparency = 0
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.ClipsDescendants = true
    frame.Active = true
    
    -- 应用主题
    self:_ApplyTheme(frame, notification.theme)
    
    -- 创建内容容器
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.BackgroundTransparency = 1
    contentContainer.Size = UDim2.new(1, 0, 1, 0)
    contentContainer.Parent = frame
    
    -- 创建图标
    local iconContainer = Instance.new("Frame")
    iconContainer.Name = "IconContainer"
    iconContainer.BackgroundTransparency = 1
    iconContainer.Size = UDim2.new(0, 40, 0, 40)
    iconContainer.Position = UDim2.new(0, 12, 0, 12)
    iconContainer.Parent = contentContainer
    
    local icon = self:_CreateNotificationIcon(notification)
    icon.Parent = iconContainer
    
    -- 创建文本容器
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.BackgroundTransparency = 1
    textContainer.Size = UDim2.new(1, -100, 0, 0)
    textContainer.Position = UDim2.new(0, 60, 0, 12)
    textContainer.AutomaticSize = Enum.AutomaticSize.Y
    textContainer.Parent = contentContainer
    
    -- 创建标题
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 0)
    title.AutomaticSize = Enum.AutomaticSize.Y
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.TextColor3 = self.Themes[notification.theme].TextColor
    title.Text = notification.title
    title.TextWrapped = true
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = textContainer
    
    -- 创建消息
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.BackgroundTransparency = 1
    message.Size = UDim2.new(1, 0, 0, 0)
    message.AutomaticSize = Enum.AutomaticSize.Y
    message.Font = Enum.Font.SourceSans
    message.TextSize = 14
    message.TextColor3 = self.Themes[notification.theme].TextColor
    message.Text = notification.message
    message.TextWrapped = true
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.Position = UDim2.new(0, 0, 0, title.TextBounds.Y + 4)
    message.Parent = textContainer
    
    -- 调整内容容器大小
    local padding = 16
    local maxWidth = frame.AbsoluteSize.X - padding * 2
    contentContainer.Size = UDim2.new(1, 0, 0, math.max(60, textContainer.AbsoluteSize.Y + padding * 2))
    
    -- 添加关闭按钮
    if notification.showCloseButton then
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.BackgroundTransparency = 1
        closeButton.Size = UDim2.new(0, 30, 0, 30)
        closeButton.Position = UDim2.new(1, -40, 0, 5)
        closeButton.Font = Enum.Font.SourceSansBold
        closeButton.TextSize = 16
        closeButton.TextColor3 = self.Themes[notification.theme].TextColor
        closeButton.Text = "×"
        closeButton.Parent = contentContainer
        
        closeButton.MouseButton1Click:Connect(function()
            self:_CloseNotification(frame, notification)
        end)
    end
    
    -- 添加进度条
    if notification.showProgress then
        local progressBarContainer = Instance.new("Frame")
        progressBarContainer.Name = "ProgressBarContainer"
        progressBarContainer.BackgroundTransparency = 1
        progressBarContainer.Size = UDim2.new(1, 0, 0, 4)
        progressBarContainer.Position = UDim2.new(0, 0, 1, -4)
        progressBarContainer.Parent = frame
        
        local progressBar = Instance.new("Frame")
        progressBar.Name = "ProgressBar"
        progressBar.BackgroundTransparency = 0
        progressBar.Size = UDim2.new(1, 0, 1, 0)
        progressBar.BackgroundColor3 = self.Themes[notification.theme].TextColor
        progressBar.BackgroundTransparency = 0.3
        progressBar.Parent = progressBarContainer
        
        frame.ProgressBar = progressBar
    end
    
    -- 设置点击事件
    if notification.canDismiss or notification.onClick then
        frame.MouseButton1Click:Connect(function()
            if notification.onClick then
                notification.onClick()
            end
            if notification.canDismiss then
                self:_CloseNotification(frame, notification)
            end
        end)
    end
    
    -- 设置悬停暂停
    if notification.pauseOnHover then
        frame.MouseEnter:Connect(function()
            if frame.lifetimeTimer then
                frame.lifetimeTimer:Pause()
            end
        end)
        
        frame.MouseLeave:Connect(function()
            if frame.lifetimeTimer then
                frame.lifetimeTimer:Resume()
            end
        end)
    end
    
    -- 保存通知数据
    frame.notification = notification
    
    return frame
end

-- 创建通知图标
function ModernNotify:_CreateNotificationIcon(notification)
    local icon
    
    if notification.icon then
        -- 使用自定义图标
        if typeof(notification.icon) == "string" then
            -- 文本图标
            local textIcon = Instance.new("TextLabel")
            textIcon.BackgroundTransparency = 1
            textIcon.Size = UDim2.new(1, 0, 1, 0)
            textIcon.Font = Enum.Font.SourceSansBold
            textIcon.TextSize = 24
            textIcon.TextColor3 = self.Themes[notification.theme].IconColor
            textIcon.Text = notification.icon
            icon = textIcon
        else
            -- 图像图标
            icon = notification.icon:Clone()
            icon.Size = UDim2.new(1, 0, 1, 0)
        end
    else
        -- 使用默认图标
        local textIcon = Instance.new("TextLabel")
        textIcon.BackgroundTransparency = 1
        textIcon.Size = UDim2.new(1, 0, 1, 0)
        textIcon.Font = Enum.Font.SourceSansBold
        textIcon.TextSize = 24
        textIcon.TextColor3 = self.Themes[notification.theme].IconColor
        
        -- 根据主题设置图标
        if notification.theme == "Success" then
            textIcon.Text = "✓"
        elseif notification.theme == "Error" then
            textIcon.Text = "✕"
        elseif notification.theme == "Warning" then
            textIcon.Text = "⚠"
        elseif notification.theme == "Info" then
            textIcon.Text = "ℹ"
        else
            textIcon.Text = "📢"
        end
        
        icon = textIcon
    end
    
    return icon
end

-- 应用主题
function ModernNotify:_ApplyTheme(frame, themeName)
    local theme = self.Themes[themeName] or self.Themes.Default
    
    if theme.UseGradient then
        -- 创建渐变背景
        local gradient = Instance.new("Frame")
        gradient.Name = "GradientBackground"
        gradient.BackgroundTransparency = 0
        gradient.Size = UDim2.new(1, 0, 1, 0)
        gradient.BorderSizePixel = 0
        gradient.Parent = frame
        
        local uiGradient = Instance.new("UIGradient")
        uiGradient.Color = ColorSequence.new(theme.GradientColors)
        uiGradient.Parent = gradient
        
        -- 设置边框
        frame.BackgroundColor3 = theme.BorderColor
        frame.BackgroundTransparency = 0
        frame.BorderSizePixel = 0
        frame.BackgroundTransparency = 1
    else
        -- 纯色背景
        frame.BackgroundColor3 = theme.BackgroundColor
        frame.BackgroundTransparency = 0
        frame.BorderColor3 = theme.BorderColor
        frame.BorderSizePixel = 2
    end
end

-- 动画通知进入
function ModernNotify:_AnimateNotificationIn(notificationFrame)
    notificationFrame.Parent = self._container
    
    -- 初始状态
    notificationFrame.Transparency = 1
    notificationFrame.Scale = Vector3.new(0.9, 0.9, 1)
    
    -- 创建Tween
    local tweenInfo = TweenInfo.new(
        self.Config.AnimationDuration,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )
    
    local properties = {
        Transparency = 0,
        Scale = Vector3.new(1, 1, 1)
    }
    
    -- 为需要动画的属性创建单独的Tween
    if not notificationFrame:IsA("GuiObject") then
        notificationFrame = notificationFrame:GetChildren()[1]
    end
    
    -- 设置初始透明度
    notificationFrame.BackgroundTransparency = 1
    for _, child in pairs(notificationFrame:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            child.TextTransparency = 1
        end
    end
    
    -- 创建背景透明度Tween
    local bgTween = TweenService:Create(
        notificationFrame,
        tweenInfo,
        { BackgroundTransparency = notificationFrame.BackgroundTransparency }
    )
    
    -- 启动Tween
    bgTween:Play()
    
    -- 启动文本透明度Tweens
    for _, child in pairs(notificationFrame:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            local textTween = TweenService:Create(
                child,
                tweenInfo,
                { TextTransparency = 0 }
            )
            textTween:Play()
        end
    end
end

-- 动画通知离开
function ModernNotify:_AnimateNotificationOut(notificationFrame, callback)
    local tweenInfo = TweenInfo.new(
        self.Config.AnimationDuration,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.In
    )
    
    -- 创建背景透明度Tween
    local bgTween = TweenService:Create(
        notificationFrame,
        tweenInfo,
        { BackgroundTransparency = 1 }
    )
    
    -- 启动Tween
    bgTween:Play()
    
    -- 启动文本透明度Tweens
    for _, child in pairs(notificationFrame:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            local textTween = TweenService:Create(
                child,
                tweenInfo,
                { TextTransparency = 1 }
            )
            textTween:Play()
        end
    end
    
    -- 动画完成后回调
    bgTween.Completed:Connect(function()
        if callback then
            callback()
        end
    end)
end

-- 关闭通知
function ModernNotify:_CloseNotification(notificationFrame, notification)
    -- 停止计时器
    if notificationFrame.lifetimeTimer then
        notificationFrame.lifetimeTimer:Stop()
        notificationFrame.lifetimeTimer = nil
    end
    
    -- 执行离开动画
    self:_AnimateNotificationOut(notificationFrame, function()
        -- 从活跃通知列表中移除
        for i, frame in ipairs(self._activeNotifications) do
            if frame == notificationFrame then
                table.remove(self._activeNotifications, i)
                break
            end
        end
        
        -- 移除UI
        notificationFrame:Destroy()
        
        -- 调用关闭回调
        if notification.onClose then
            notification.onClose()
        end
        
        -- 重新定位通知
        self:_RepositionNotifications()
        
        -- 处理队列中的下一个通知
        self:_ProcessNotificationQueue()
        
        -- 检查是否需要隐藏容器
        self:_CheckContainerVisibility()
    end)
end

-- 重新定位通知
function ModernNotify:_RepositionNotifications()
    local spacing = self.Config.NotificationSpacing
    local position = 0
    
    -- 根据配置的位置确定排列方向
    local isBottomPosition = self.Config.DefaultPosition:find("Bottom") ~= nil
    
    if isBottomPosition then
        -- 从下往上排列
        for i = #self._activeNotifications, 1, -1 do
            local frame = self._activeNotifications[i]
            frame.Position = UDim2.new(0, 0, 0, position)
            position = position + frame.AbsoluteSize.Y + spacing
        end
    else
        -- 从上往下排列
        for _, frame in ipairs(self._activeNotifications) do
            frame.Position = UDim2.new(0, 0, 0, position)
            position = position + frame.AbsoluteSize.Y + spacing
        end
    end
end

-- 通知生命周期计时器
function ModernNotify:_StartNotificationLifetime(notificationFrame, notification)
    local startTime = os.clock()
    local lifetime = notification.lifetime
    local progressBar = notificationFrame.ProgressBar
    local isPaused = false
    local pauseStartTime = 0
    local pausedDuration = 0
    
    -- 创建计时器类
    local Timer = {
        isRunning = true,
        Stop = function()
            self.isRunning = false
        end,
        Pause = function()
            if not isPaused then
                isPaused = true
                pauseStartTime = os.clock()
            end
        end,
        Resume = function()
            if isPaused then
                isPaused = false
                pausedDuration = pausedDuration + (os.clock() - pauseStartTime)
            end
        end
    }
    
    notificationFrame.lifetimeTimer = Timer
    
    -- 使用RunService.Heartbeat来更新计时器
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not Timer.isRunning then
            connection:Disconnect()
            return
        end
        
        if isPaused then
            return
        end
        
        local currentTime = os.clock() - pausedDuration
        local elapsed = currentTime - startTime
        
        -- 更新进度条
        if progressBar then
            local progress = 1 - (elapsed / lifetime)
            progressBar.Size = UDim2.new(math.max(0, progress), 0, 1, 0)
        end
        
        -- 检查是否到期
        if elapsed >= lifetime then
            connection:Disconnect()
            self:_CloseNotification(notificationFrame, notification)
        end
    end)
end

-- 检查并更新容器可见性
function ModernNotify:_CheckContainerVisibility()
    if not self.Config.AutoHideContainer then
        return
    end
    
    if #self._activeNotifications == 0 and self._isContainerVisible then
        self._container.Visible = false
        self._isContainerVisible = false
    elseif #self._activeNotifications > 0 and not self._isContainerVisible then
        self._container.Visible = true
        self._isContainerVisible = true
    end
end

-- 添加自定义主题
function ModernNotify:AddTheme(name, themeConfig)
    if type(name) ~= "string" or type(themeConfig) ~= "table" then
        error("Invalid parameters for AddTheme: name must be a string and themeConfig must be a table")
    end
    
    -- 验证主题配置
    if themeConfig.UseGradient then
        if not themeConfig.GradientColors or type(themeConfig.GradientColors) ~= "table" or #themeConfig.GradientColors < 2 then
            error("Gradient theme must have at least 2 GradientColors")
        end
        for _, color in ipairs(themeConfig.GradientColors) do
            if typeof(color) ~= "Color3" then
                error("GradientColors must contain Color3 values")
            end
        end
    else
        if not themeConfig.BackgroundColor or typeof(themeConfig.BackgroundColor) ~= "Color3" then
            error("Non-gradient theme must have a BackgroundColor")
        end
    end
    
    -- 确保必要的颜色属性存在
    if not themeConfig.TextColor or typeof(themeConfig.TextColor) ~= "Color3" then
        error("Theme must have a TextColor")
    end
    
    if not themeConfig.BorderColor or typeof(themeConfig.BorderColor) ~= "Color3" then
        error("Theme must have a BorderColor")
    end
    
    if not themeConfig.IconColor or typeof(themeConfig.IconColor) ~= "Color3" then
        error("Theme must have an IconColor")
    end
    
    -- 添加主题
    self.Themes[name] = themeConfig
    return true
end

-- 删除主题
function ModernNotify:RemoveTheme(name)
    if name == "Default" then
        error("Cannot remove the Default theme")
    end
    
    if self.Themes[name] then
        self.Themes[name] = nil
        return true
    end
    
    return false
end

-- 获取主题
function ModernNotify:GetTheme(name)
    return self.Themes[name] or self.Themes.Default
end

-- 获取所有主题名称
function ModernNotify:GetAllThemes()
    local themeNames = {}
    for name, _ in pairs(self.Themes) do
        table.insert(themeNames, name)
    end
    return themeNames
end

-- 暂停所有通知计时
function ModernNotify:PauseAll()
    for _, notificationFrame in ipairs(self._activeNotifications) do
        if notificationFrame.lifetimeTimer then
            notificationFrame.lifetimeTimer:Pause()
        end
    end
    return true
end

-- 恢复所有通知计时
function ModernNotify:ResumeAll()
    for _, notificationFrame in ipairs(self._activeNotifications) do
        if notificationFrame.lifetimeTimer then
            notificationFrame.lifetimeTimer:Resume()
        end
    end
    return true
end

-- 显示通知容器
function ModernNotify:ShowContainer()
    if self._container then
        self._container.Visible = true
        self._isContainerVisible = true
    end
    return true
end

-- 隐藏通知容器
function ModernNotify:HideContainer()
    if self._container then
        self._container.Visible = false
        self._isContainerVisible = false
    end
    return true
end

-- 设置容器位置
function ModernNotify:SetContainerPosition(position)
    if not self._container then
        self:_InitializeContainer()
    end
    
    local validPositions = {"TopLeft", "TopRight", "BottomLeft", "BottomRight", "TopCenter", "BottomCenter"}
    local isValid = false
    
    for _, pos in ipairs(validPositions) do
        if pos == position then
            isValid = true
            break
        end
    end
    
    if not isValid then
        error("Invalid position: " .. position .. ". Valid positions are: " .. table.concat(validPositions, ", "))
    end
    
    self.Config.DefaultPosition = position
    self._container.Position = self:_GetContainerPosition()
    
    -- 重新定位通知
    self:_RepositionNotifications()
    
    return true
end

-- 清除所有通知
function ModernNotify:ClearAll()
    -- 停止所有计时器并关闭所有活跃通知
    local activeNotificationsCopy = {unpack(self._activeNotifications)}
    for _, notificationFrame in ipairs(activeNotificationsCopy) do
        if notificationFrame.lifetimeTimer then
            notificationFrame.lifetimeTimer:Stop()
            notificationFrame.lifetimeTimer = nil
        end
        
        -- 调用onClose回调
        if notificationFrame.notification and notificationFrame.notification.onClose then
            notificationFrame.notification.onClose()
        end
        
        notificationFrame:Destroy()
    end
    
    -- 清空列表
    self._activeNotifications = {}
    self._notificationQueue = {}
    
    -- 隐藏容器
    if self.Config.AutoHideContainer and self._container then
        self._container.Visible = false
        self._isContainerVisible = false
    end
    
    return true
end

-- 获取活跃通知数量
function ModernNotify:GetActiveNotificationCount()
    return #self._activeNotifications
end

-- 获取队列中通知数量
function ModernNotify:GetQueuedNotificationCount()
    return #self._notificationQueue
end

-- 更新通知配置
function ModernNotify:SetConfig(key, value)
    if self.Config[key] ~= nil then
        self.Config[key] = value
        
        -- 如果更新了位置配置，重新定位容器
        if key == "DefaultPosition" then
            self:SetContainerPosition(value)
        end
        
        return true
    end
    
    return false
end

-- 获取通知配置
function ModernNotify:GetConfig()
    return self.Config
end

-- 快捷通知方法 - Success
function ModernNotify:Success(title, message, options)
    options = options or {}
    options.theme = "Success"
    options.title = title or "Success"
    options.message = message or ""
    return self:CreateNotification(options)
end

-- 快捷通知方法 - Error
function ModernNotify:Error(title, message, options)
    options = options or {}
    options.theme = "Error"
    options.title = title or "Error"
    options.message = message or ""
    return self:CreateNotification(options)
end

-- 快捷通知方法 - Warning
function ModernNotify:Warning(title, message, options)
    options = options or {}
    options.theme = "Warning"
    options.title = title or "Warning"
    options.message = message or ""
    return self:CreateNotification(options)
end

-- 快捷通知方法 - Info
function ModernNotify:Info(title, message, options)
    options = options or {}
    options.theme = "Info"
    options.title = title or "Information"
    options.message = message or ""
    return self:CreateNotification(options)
end

-- 快捷通知方法 - Primary
function ModernNotify:Primary(title, message, options)
    options = options or {}
    options.theme = "Primary"
    options.title = title or "Notification"
    options.message = message or ""
    return self:CreateNotification(options)
end

-- 快捷通知方法 - Dark
function ModernNotify:Dark(title, message, options)
    options = options or {}
    options.theme = "Dark"
    options.title = title or "Notification"
    options.message = message or ""
    return self:CreateNotification(options)
end

-- 快捷通知方法 - Light
function ModernNotify:Light(title, message, options)
    options = options or {}
    options.theme = "Light"
    options.title = title or "Notification"
    options.message = message or ""
    return self:CreateNotification(options)
end

-- 快捷通知方法 - Pastel
function ModernNotify:Pastel(title, message, options)
    options = options or {}
    options.theme = "Pastel"
    options.title = title or "Notification"
    options.message = message or ""
    return self:CreateNotification(options)
end

-- 快捷通知方法 - Gradient
function ModernNotify:Gradient(title, message, options)
    options = options or {}
    options.theme = "Gradient"
    options.title = title or "Notification"
    options.message = message or ""
    return self:CreateNotification(options)
end

-- 快捷通知方法 - Rainbow
function ModernNotify:Rainbow(title, message, options)
    options = options or {}
    options.theme = "Rainbow"
    options.title = title or "Notification"
    options.message = message or ""
    return self:CreateNotification(options)
end

-- 示例用法
-- ModernNotify:Success("操作成功", "您的任务已成功完成！")
-- ModernNotify:Error("操作失败", "发生错误，请重试")
-- ModernNotify:Warning("警告", "请注意，此操作不可撤销")
-- ModernNotify:Info("提示", "请查看最新消息")

-- 高级用法示例
-- ModernNotify:CreateNotification({
--     title = "自定义通知",
--     message = "这是一个带有进度条和自定义图标按钮的通知",
--     theme = "Gradient",
--     lifetime = 10,
--     icon = "🔔",
--     showProgress = true,
--     showCloseButton = true,
--     pauseOnHover = true,
--     canDismiss = true,
--     onClick = function()
--         print("通知被点击了")
--     end,
--     onClose = function()
--         print("通知被关闭了")
--     end
-- })

-- 全局导出
_G.ModernNotify = ModernNotify

return ModernNotify
