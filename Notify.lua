local Notify = {}

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local config = {
    notificationLifetime = 3,
    fadeInTime = 0.3,
    fadeOutTime = 0.3,
    offsetBetweenNotifs = 60,
    maxVisibleNotifs = 5,
    defaultPosition = UDim2.new(1, -260, 0, 20),
    animationStyle = "slide",
    defaultTheme = "default",
    enableSounds = true,
    enableDrag = true,
    autoHideContainer = false,
    containerVisible = true,
    pauseOnHover = true,
    showProgressBar = true,
    showCloseButton = true
}

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

local notificationQueue = {}
local activeNotifications = {}
local uiContainer = nil
local dragInfo = nil

local notificationSounds = {}
local soundParent = nil

local function initSoundSystem()
    if soundParent then return end
    
    soundParent = Instance.new("SoundGroup")
    soundParent.Name = "NotificationSounds"
    soundParent.Volume = 0.5
    soundParent.Parent = SoundService
    
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
        sound.SoundId = "rbxassetid://5637153838"
        sound.Volume = properties.Volume
        sound.Pitch = properties.Pitch
        sound.SoundGroup = soundParent
        sound.Parent = soundParent
        notificationSounds[name] = sound
    end
end

local function playNotificationSound(soundName)
    if not config.enableSounds then return end
    
    initSoundSystem()
    
    local sound = notificationSounds[soundName] or notificationSounds.default
    if sound then
        sound:Play()
    end
end

local function initUIContainer()
    if uiContainer then return uiContainer end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NotificationSystem"
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    ScreenGui.DisplayOrder = 9999
    ScreenGui.IgnoreGuiInset = true
    
    local Container = Instance.new("Frame")
    Container.Name = "NotificationContainer"
    Container.Size = UDim2.new(0, 250, 0, 300)
    Container.Position = config.defaultPosition
    Container.BackgroundTransparency = 1
    Container.ClipsDescendants = false
    Container.Parent = ScreenGui
    Container.Visible = config.containerVisible
    
    if config.enableDrag then
        Container.Active = true
        Container.Selectable = true
        
        Container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragInfo = {
                    startPosition = input.Position,
                    startContainerPosition = Container.Position,
                    isDragging = true
                }
                
                local originalTransparency = Container.BackgroundTransparency
                Container.BackgroundTransparency = 0.1
                Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                
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

local function createNotificationIcon(theme)
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 36, 0, 36)
    iconFrame.BackgroundColor3 = theme.iconColor
    iconFrame.BorderSizePixel = 0
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 6)
    uiCorner.Parent = iconFrame
    
    return iconFrame
end

function Notify:CreateNotification(options)
    local container = initUIContainer()
    
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
    
    table.insert(notificationQueue, notificationObj)
    
    processNotificationQueue()
    
    return notificationObj
end

function processNotificationQueue()
    if #activeNotifications >= config.maxVisibleNotifs then
        return
    end
    
    if #notificationQueue == 0 then
        if config.autoHideContainer and uiContainer then
            uiContainer.Visible = false
            config.containerVisible = false
        end
        return
    end
    
    if uiContainer and not uiContainer.Visible then
        uiContainer.Visible = true
        config.containerVisible = true
    end
    
    table.sort(notificationQueue, function(a, b)
        return a.priority > b.priority
    end)
    
    local nextNotification = table.remove(notificationQueue, 1)
    
    local notificationFrame = createNotificationUI(nextNotification)
    
    table.insert(activeNotifications, 1, nextNotification)
    
    repositionActiveNotifications()
    
    if nextNotification.showSound then
        playNotificationSound(nextNotification.theme.soundName)
    end
    
    animateNotificationIn(notificationFrame, nextNotification.themeName, nextNotification.animationStyle)
    
    startNotificationLifetimeTimer(nextNotification)
end

function createNotificationUI(notification)
    local theme = notification.theme
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Notification"
    mainFrame.Size = UDim2.new(0, 250, 0, 0)
    mainFrame.BackgroundColor3 = theme.backgroundColor
    mainFrame.BorderColor3 = theme.borderColor
    mainFrame.BorderSizePixel = 1
    mainFrame.ClipsDescendants = true
    mainFrame.Visible = false
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, theme.cornerRadius)
    uiCorner.Parent = mainFrame
    
    local iconFrame = createNotificationIcon(theme)
    iconFrame.Position = UDim2.new(0, 8, 0, 8)
    iconFrame.Parent = mainFrame
    
    if notification.icon then
        notification.icon.Size = UDim2.new(1, -4, 1, -4)
        notification.icon.Position = UDim2.new(0, 2, 0, 2)
        notification.icon.Parent = iconFrame
    else
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
        
        closeButton.MouseEnter:Connect(function()
            closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
        
        closeButton.MouseLeave:Connect(function()
            closeButton.TextColor3 = theme.titleColor
        end)
        
        closeButton.MouseButton1Click:Connect(function()
            if notification.frame and notification.frame.Parent then
                animateNotificationOut(notification.frame, notification.animationStyle, function()
                    for i, notif in ipairs(activeNotifications) do
                        if notif.frame == notification.frame then
                            table.remove(activeNotifications, i)
                            break
                        end
                    end
                    
                    if notification.frame and notification.frame.Parent then
                        notification.frame:Destroy()
                    end
                    
                    repositionActiveNotifications()
                    
                    processNotificationQueue()
                end)
            end
        end)
    end
    
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
    
    local textBounds = messageLabel.TextBounds
    local messageHeight = math.max(20, textBounds.Y)
    messageLabel.Size = UDim2.new(1, -52, 0, messageHeight)
    
    local totalHeight = math.max(52, messageHeight + 38)
    if notification.showProgressBar then
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
        
        notification.progressBar = progressBar
    end
    
    mainFrame.Size = UDim2.new(0, 250, 0, totalHeight)
    
    mainFrame.Parent = uiContainer
    
    notification.frame = mainFrame
    
    if notification.pauseOnHover then
        mainFrame.Active = true
        
        mainFrame.MouseEnter:Connect(function()
            if not notification.isPaused then
                notification.isPaused = true
                if notification.lifetimeTimer then
                    task.cancel(notification.lifetimeTimer)
                end
            end
            
            mainFrame.BackgroundColor3 = theme.backgroundColor:Lerp(Color3.fromRGB(255, 255, 255), 0.1)
        end)
        
        mainFrame.MouseLeave:Connect(function()
            if notification.isPaused then
                notification.isPaused = false
                if notification.remainingLifetime > 0 then
                    startNotificationLifetimeTimer(notification)
                end
            end
            
            mainFrame.BackgroundColor3 = theme.backgroundColor
        end)
    end
    
    if notification.clickCallback then
        mainFrame.Active = true
        
        mainFrame.MouseButton1Click:Connect(function()
            notification.clickCallback(notification)
        end)
    end
    
    return mainFrame
end

function startNotificationLifetimeTimer(notification)
    if notification.lifetimeTimer then
        task.cancel(notification.lifetimeTimer)
    end
    
    if notification.progressBar then
        local progressTween = TweenService:Create(
            notification.progressBar,
            TweenInfo.new(notification.remainingLifetime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 0, 1, 0)}
        )
        progressTween:Play()
    end
    
    notification.lifetimeTimer = task.delay(notification.remainingLifetime, function()
        animateNotificationOut(notification.frame, notification.animationStyle, function()
            for i, notif in ipairs(activeNotifications) do
                if notif.frame == notification.frame then
                    table.remove(activeNotifications, i)
                    break
                end
            end
            
            if notification.frame and notification.frame.Parent then
                notification.frame:Destroy()
            end
            
            repositionActiveNotifications()
            
            processNotificationQueue()
        end)
    end)
end

function repositionActiveNotifications()
    for i, notification in ipairs(activeNotifications) do
        if notification.frame and notification.frame.Parent then
            local yOffset = (i - 1) * (notification.frame.AbsoluteSize.Y + config.offsetBetweenNotifs)
            
            local moveTween = TweenService:Create(
                notification.frame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(0, 0, 0, yOffset)}
            )
            moveTween:Play()
        end
    end
    
    if #activeNotifications == 0 and config.autoHideContainer and uiContainer then
        uiContainer.Visible = false
        config.containerVisible = false
    end
end

function animateNotificationIn(notificationFrame, themeName, animationStyle)
    animationStyle = animationStyle or config.animationStyle
    notificationFrame.Visible = true
    
    if animationStyle == "slide" then
        notificationFrame.Position = UDim2.new(1, 10, 0, notificationFrame.Position.Y.Offset)
        
        TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 0, 0, notificationFrame.Position.Y.Offset)}
        ):Play()
        
    elseif animationStyle == "fade" then
        notificationFrame.Transparency = 1
        TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 0}
        ):Play()
        
    elseif animationStyle == "bounce" then
        notificationFrame.Size = UDim2.new(0, 0, 0, notificationFrame.AbsoluteSize.Y)
        notificationFrame.Position = UDim2.new(0.5, -notificationFrame.AbsoluteSize.X/2, 0, notificationFrame.Position.Y.Offset)
        
        TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 250, 0, notificationFrame.AbsoluteSize.Y),
             Position = UDim2.new(0, 0, 0, notificationFrame.Position.Y.Offset)}
        ):Play()
        
    elseif animationStyle == "zoom" then
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
        notificationFrame.Size = UDim2.new(0, 250, 0, notificationFrame.AbsoluteSize.Y)
        notificationFrame.Position = UDim2.new(1, 10, 0, notificationFrame.Position.Y.Offset)
        
        TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeInTime * 1.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, 0, 0, notificationFrame.Position.Y.Offset)}
        ):Play()
    end
    
    if themeName == "success" or themeName == "error" or themeName == "warning" or themeName == "info" then
        local glowEffect = Instance.new("Frame")
        glowEffect.Size = UDim2.new(1, 10, 1, 10)
        glowEffect.Position = UDim2.new(0, -5, 0, -5)
        glowEffect.BackgroundColor3 = themes[themeName].iconColor
        glowEffect.BackgroundTransparency = 0.7
        glowEffect.ZIndex = notificationFrame.ZIndex - 1
        glowEffect.Parent = notificationFrame.Parent
        
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = glowEffect
        
        game:GetService("TweenService"):Create(
            glowEffect,
            TweenInfo.new(config.fadeInTime * 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1, Size = UDim2.new(1, 20, 1, 20), Position = UDim2.new(0, -10, 0, -10)}
        ):Play()
        
        task.delay(config.fadeInTime * 2, function()
            if glowEffect and glowEffect.Parent then
                glowEffect:Destroy()
            end
        end)
    end
end

function animateNotificationOut(notificationFrame, animationStyle, onComplete)
    animationStyle = animationStyle or config.animationStyle
    
    if animationStyle == "slide" then
        local slideTween = TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, 0, notificationFrame.Position.Y.Offset)}
        )
        
        slideTween.Completed:Connect(onComplete)
        slideTween:Play()
        
    elseif animationStyle == "fade" then
        local fadeTween = TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Transparency = 1}
        )
        
        fadeTween.Completed:Connect(onComplete)
        fadeTween:Play()
        
    elseif animationStyle == "bounce" then
        local shrinkTween = TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, notificationFrame.AbsoluteSize.Y),
             Position = UDim2.new(0.5, -notificationFrame.AbsoluteSize.X/2, 0, notificationFrame.Position.Y.Offset)}
        )
        
        shrinkTween.Completed:Connect(onComplete)
        shrinkTween:Play()
        
    elseif animationStyle == "zoom" then
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
        local elasticTween = TweenService:Create(
            notificationFrame,
            TweenInfo.new(config.fadeOutTime * 1.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.In),
            {Position = UDim2.new(1, 10, 0, notificationFrame.Position.Y.Offset)}
        )
        
        elasticTween.Completed:Connect(onComplete)
        elasticTween:Play()
    end
end

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

function Notify:SetConfig(newConfig)
    for key, value in pairs(newConfig) do
        if config[key] ~= nil then
            config[key] = value
        end
    end
end

function Notify:AddTheme(themeName, themeConfig)
    themes[themeName] = themeConfig
end

function Notify:PauseAll()
    for _, notification in ipairs(activeNotifications) do
        if not notification.isPaused then
            notification.isPaused = true
            if notification.lifetimeTimer then
                task.cancel(notification.lifetimeTimer)
            end
            
            if notification.progressBar then
                for _, tween in pairs(game:GetService("TweenService"):GetTweensAsync(notification.progressBar)) do
                    tween:Pause()
                end
            end
        end
    end
end

function Notify:ResumeAll()
    for _, notification in ipairs(activeNotifications) do
        if notification.isPaused then
            notification.isPaused = false
            startNotificationLifetimeTimer(notification)
        end
    end
end

function Notify:ShowContainer()
    if uiContainer then
        uiContainer.Visible = true
        config.containerVisible = true
    end
end

function Notify:HideContainer()
    if uiContainer then
        uiContainer.Visible = false
        config.containerVisible = false
    end
end

function Notify:SetContainerPosition(position)
    if uiContainer then
        uiContainer.Position = position
    end
end

function Notify:ClearAll()
    notificationQueue = {}
    
    for _, notification in ipairs(activeNotifications) do
        if notification.lifetimeTimer then
            task.cancel(notification.lifetimeTimer)
        end
        
        if notification.frame and notification.frame.Parent then
            notification.frame:Destroy()
        end
    end
    
    activeNotifications = {}
    
    if config.autoHideContainer and uiContainer then
        uiContainer.Visible = false
        config.containerVisible = false
    end
end

_G.Notify = Notify
return Notify
