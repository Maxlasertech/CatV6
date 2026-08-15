local downloader = Instance.new('TextLabel')
downloader.Size = UDim2.new(1, 0, 0, 40)
downloader.BackgroundTransparency = 1
downloader.TextStrokeTransparency = 0
downloader.TextSize = 20
downloader.TextColor3 = Color3.new(1, 1, 1)
downloader.Font = Enum.Font.Arial
downloader.Text = 'Reinstalling script..'
downloader.Parent = Instance.new('ScreenGui', gethui and gethui() or cloneref(game:GetService('CoreGui')))
task.delay(0.1, downloader.Destroy, downloader)

delfolder('catsix')
loadstring(game:HttpGet('https://raw.githubusercontent.com/MaxlaserTech/CatV6/main/init.lua'), 'init.lua')(...)