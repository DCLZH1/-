load Notify Gui
```lua
local Notify = loadstring(game:HttpGet("https://raw.githubusercontent.com/DCLZH1/-/refs/heads/main/Notify.lua"))()
```
you can use these
```lua
Notify:Success("操作成功", "您的任务已完成！")
Notify:Error("错误", "无法完成操作，请重试")
Notify:Warning("警告", "")
Notify:Info("信息", "新功能已上线")
Notify:Primary("主要通知", "这是一条重要通知")
Notify:Dark("深色主题", "使用深色主题的通知")
Notify:Light("浅色主题", "使用浅色主题的通知")
```
```lua
Notify:CreateNotification({
     title = "自定义通知",
     message = "这是一个带有自定义选项的通知",
     lifetime = 8, -- 显示8秒
     theme = "success",
     priority = 1,
     showProgressBar = true, -- 显示进度条
     showCloseButton = true, -- 显示关闭按钮
     pauseOnHover = true, -- 悬停时暂停计时
     showSound = true, -- 播放通知声音
     animationStyle = "elastic", -- 使用弹性动画
     onClick = function(notification)
         print("通知被点击")
         -- 可以在这里执行自定义操作
     end 
})
```
all these are easy and then
this notify made by Gemini 3 pro
