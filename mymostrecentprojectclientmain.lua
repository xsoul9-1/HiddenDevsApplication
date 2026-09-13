local switchframe = script.Parent:FindFirstChild("Switch", true)
local mainframe = script.Parent:FindFirstChild("MainFrame", true)
local Shop = switchframe.Shop
local Upgrades = switchframe.Upgrades
local box = script.Parent:FindFirstChild("Box", true)
local music = script.Parent:FindFirstChild("Music", true)
local cd = music.CD
local clicker = script.Parent:FindFirstChild("Clicker", true)
local Clicks = clicker.Clicks
local Teto = clicker.Teto
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AddClick = ReplicatedStorage.Events:WaitForChild("AddClick")
local player = game.Players.LocalPlayer
local AddLavel = clicker:WaitForChild("AddLabel")
local GetSkinData = ReplicatedStorage.Events:WaitForChild("GetSkinData")
local EquipSkinEvent = ReplicatedStorage.Events:WaitForChild("EquipSkinEvent")
local clicksound = game.SoundService:FindFirstChild("Click")
local scrollingupgrades = box:FindFirstChild("ScrollingFrame", true)
local BuyUpgradeEvent = ReplicatedStorage.Events:WaitForChild("BuyUpgrade")
local GetUpgradeData = ReplicatedStorage.Events:WaitForChild("GetUpgradeData")
local sound = game.SoundService:FindFirstChild("Click")
local AutoClick = ReplicatedStorage.Events:WaitForChild("AutoClick")
local rebirthevent = ReplicatedStorage.Events:WaitForChild("RebirthEvent")
local OfflineEarningsEvent = ReplicatedStorage.Events:WaitForChild("OfflineEarnings")

local function formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if hours > 0 then
		return hours .. "h " .. minutes .. "m"
	else
		return minutes .. "m"
	end
end

--clicksound
for i, b in pairs(mainframe:GetDescendants())do
	if b:IsA("TextButton") or b:IsA("ImageButton") then
		b.Activated:Connect(function()
			if b.Name == "Buy" or b.Name == "Teto" then
			else
				clicksound:Play()
			end
		end)
	end
end

--upgradesactivation
Upgrades.Activated:Connect(function()
	local Frame = box:FindFirstChild(Upgrades.Name)
	if Frame then
		if Frame.Visible == false then
			for i, b in pairs((box):GetChildren())do
				if b:IsA("Frame")  and b.Name ~= Upgrades.Name and b.name ~= "Switch"  then					
					b.Visible = false						
				end
				Frame.Visible = true
			end
		end
	end	
end)
--shopactivation
Shop.Activated:Connect(function()
	local Frame = box:FindFirstChild(Shop.Name)
	local notification = Shop.Notification
	if Frame then
		if Frame.Visible == false then
			for i, b in pairs((box):GetChildren())do
				if b:IsA("Frame")  and b.Name ~= Shop.Name and b.name ~= "Switch"  then					
					b.Visible = false						
				end
				Frame.Visible = true
				notification.Visible = false
			end
		end
	end	
end)

cd.Activated:Connect(function()
	local frame = music.Settings
	if frame.Visible == false then
		frame.Visible = true
	elseif frame.Visible == true then
		frame.Visible = false
	end
end)

local TweenService = game:GetService("TweenService")

local Teto = clicker.Teto

local normalSize = Teto.Size
local hoverSize = UDim2.new(
	normalSize.X.Scale * 1.1,
	normalSize.X.Offset * 1.1,
	normalSize.Y.Scale * 1.1,
	normalSize.Y.Offset * 1.1
)

local clickSize = UDim2.new(
	normalSize.X.Scale * 1,
	normalSize.X.Offset * 1,
	normalSize.Y.Scale * 1,
	normalSize.Y.Offset * 1
)


local tweenInfo = TweenInfo.new(
	0.15,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

-- TetoCursor
Teto.MouseEnter:Connect(function()
	TweenService:Create(Teto, tweenInfo, {
		Size = hoverSize
	}):Play()
end)

Teto.MouseLeave:Connect(function()
	TweenService:Create(Teto, tweenInfo, {
		Size = normalSize
	}):Play()
end)

-- Click
local function CreateClickLabel()

	local newLabel = AddLavel:Clone()
	local clicks = player:GetAttribute("PlayerClick")
	local rebirthboost = player:GetAttribute("RebirthBoost") or 1
	local multiplier = player:GetAttribute("Multiplier") or 1
	local playerskin = player:GetAttribute("CurrentSkin") or "Default"
	local skinmultiplier = ReplicatedStorage:FindFirstChild("Skins"):FindFirstChild(playerskin).Multiplier.Value
	local togive = math.round(clicks * rebirthboost * multiplier * skinmultiplier * 10) / 10
	newLabel.Text = "+" .. togive .. "🎤"
	newLabel.Visible = true
	newLabel.Parent = Teto.Parent
	newLabel.TextTransparency = 0

	local stroke = newLabel:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	local tetoCenter =
		Teto.AbsolutePosition + (Teto.AbsoluteSize / 2)

	local parent = newLabel.Parent
	local parentPosition = parent.AbsolutePosition

	local startX = tetoCenter.X - parentPosition.X
	local startY = tetoCenter.Y - parentPosition.Y

	newLabel.Position = UDim2.fromOffset(startX, startY)

	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	local referenceSize = Vector2.new(1920, 1080)

	local screenScale = math.min(
		viewportSize.X / referenceSize.X,
		viewportSize.Y / referenceSize.Y
	)
	screenScale = math.min(screenScale, 1)
	local angle = math.random() * math.pi * 2
	local distance = math.random(300, 320) * screenScale

	local offsetX = math.cos(angle) * distance
	local offsetY = math.sin(angle) * distance

	local targetPosition = UDim2.fromOffset(
		startX + offsetX,
		startY + offsetY
	)

	local moveTween = TweenService:Create(
		newLabel,
		TweenInfo.new(
			0.4,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			Position = targetPosition
		}
	)
	moveTween:Play()
	moveTween.Completed:Once(function()
		local fadeTweenInfo = TweenInfo.new(
			0.35,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
		local fadeTween = TweenService:Create(
			newLabel,
			fadeTweenInfo,
			{
				TextTransparency = 1
			}
		)
		if stroke then
			TweenService:Create(
				stroke,
				fadeTweenInfo,
				{
					Transparency = 1
				}
			):Play()
		end
		fadeTween:Play()
		fadeTween.Completed:Once(function()
			newLabel:Destroy()
		end)
	end)
end
Teto.MouseButton1Click:Connect(function()
	TweenService:Create(
		Teto,
		TweenInfo.new(
			0.05,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			Size = clickSize
		}
	):Play()
	AddClick:FireServer()

	Teto.Image = Teto:FindFirstChild("1").Image
	task.wait(0.06)
	Teto.Image = Teto:FindFirstChild("2").Image
	task.wait(0.06)
	Teto.Image = Teto:FindFirstChild("3").Image
	task.wait(0.06)
	Teto.Image = Teto:FindFirstChild("idle").Image
	TweenService:Create(
		Teto,
		tweenInfo,
		{
			Size = hoverSize
		}
	):Play()
	clicksound.TimePosition = 0
	clicksound:Play()
	CreateClickLabel()

end)

local currentClicks = player:GetAttribute("Clicks") or 0
Clicks.Text = "Tetos: " .. currentClicks

player:GetAttributeChangedSignal("Clicks"):Connect(function()
	Clicks.Text = "Tetos: " .. (player:GetAttribute("Clicks") or 0)
end)

--skins
local Wardrobe = script.Parent:FindFirstChild("WardRobeFrame", true).ScrollingFrame
local BuySkinEvent = ReplicatedStorage.Events:WaitForChild("BuySkin")
local WardRobeButton = script.Parent:FindFirstChild("WardRobe", true)

WardRobeButton.Activated:Connect(function()
	if Wardrobe.Parent.Visible == false then
		Wardrobe.Parent.Visible = true
	elseif Wardrobe.Parent.Visible == true then
		Wardrobe.Parent.Visible = false
	end
end)

for i,v in pairs(Wardrobe:GetChildren()) do
	if v:IsA("ImageButton") then
		v.MouseButton1Click:Connect(function()
			local newteto = ReplicatedStorage.Skins:FindFirstChild(v.Name)
			if newteto then
				if v:FindFirstChild("NotBought") then
					local price = v:FindFirstChild("Price").Value
					local skinName = v.Name
					BuySkinEvent:FireServer(price, skinName)
				else
					EquipSkinEvent:FireServer(v.Name)
					Teto.Image = newteto:FindFirstChild("idle").Image
					Teto:FindFirstChild("1").Image = newteto:FindFirstChild("1").Image
					Teto:FindFirstChild("2").Image = newteto:FindFirstChild("2").Image
					Teto:FindFirstChild("3").Image = newteto:FindFirstChild("3").Image
					Teto:FindFirstChild("idle").Image = newteto:FindFirstChild("idle").Image
				end
			end
		end)
	end
end

BuySkinEvent.OnClientEvent:Connect(function(skinName)
	local v = Wardrobe:FindFirstChild(skinName)
	if v then
		v:FindFirstChild("NotBought"):Destroy()
		local newteto = ReplicatedStorage.Skins:FindFirstChild(v.Name)
		EquipSkinEvent:FireServer(v.Name)
		Teto.Image = newteto:FindFirstChild("idle").Image
		Teto:FindFirstChild("1").Image = newteto:FindFirstChild("1").Image
		Teto:FindFirstChild("2").Image = newteto:FindFirstChild("2").Image
		Teto:FindFirstChild("3").Image = newteto:FindFirstChild("3").Image
		Teto:FindFirstChild("idle").Image = newteto:FindFirstChild("idle").Image	
	end
end)

local ownedSkins, currentSkin = GetSkinData:InvokeServer()
for _, skinName in ipairs(ownedSkins) do
	local button = Wardrobe:FindFirstChild(skinName)
	if button then
		local randomskinfolder = ReplicatedStorage.RandomSkins
		local notBought = button:FindFirstChild("NotBought")
		if notBought then
			notBought:Destroy()
			button.Visible = true
			button.Interactable = true
			local randomskintodelete = randomskinfolder:FindFirstChild(skinName)
			if randomskintodelete then
				randomskintodelete:Destroy()
			end
		end
	end
end
if currentSkin then
	local skin = ReplicatedStorage.Skins:FindFirstChild(currentSkin)
	if skin then
		Teto.Image = skin:FindFirstChild("idle").Image
		Teto:FindFirstChild("1").Image = skin:FindFirstChild("1").Image
		Teto:FindFirstChild("2").Image = skin:FindFirstChild("2").Image
		Teto:FindFirstChild("3").Image = skin:FindFirstChild("3").Image
		Teto:FindFirstChild("idle").Image = skin:FindFirstChild("idle").Image
	end
end
--autoclicks
local Speed = player:GetAttribute("AutoTetoSpeed") or 1
task.spawn(function()

	while true do

		local autoClicks = player:GetAttribute("AutoClicks") or 0
		local rebirthboost = player:GetAttribute("RebirthBoost") or 1
		local multiplier = player:GetAttribute("Multiplier") or 1
		local playerskin = player:GetAttribute("CurrentSkin") or "Default"
		local skinmultiplier = ReplicatedStorage:FindFirstChild("Skins"):FindFirstChild(playerskin).Multiplier.Value
		local togive = math.round(autoClicks * rebirthboost * multiplier * skinmultiplier * 10) / 10

		local autoClicksPower = player:GetAttribute("AutoClicksPower") or 1

		if autoClicks > 0 then

			for i = 1, autoClicksPower do

				AutoClick:FireServer()

				local newLabel = AddLavel:Clone()
				newLabel.Text = "+" .. togive .. "🎤"
				newLabel.Visible = true
				newLabel.Parent = Teto.Parent
				newLabel.TextTransparency = 0
				clicksound.TimePosition = 0
				clicksound:Play()
				
				local stroke =
					newLabel:FindFirstChildOfClass("UIStroke")

				if stroke then
					stroke.Transparency = 0
				end
				local tetoCenter =
					Teto.AbsolutePosition + (Teto.AbsoluteSize / 2)

				local parent = newLabel.Parent
				local parentPosition = parent.AbsolutePosition

				local startX = tetoCenter.X - parentPosition.X
				local startY = tetoCenter.Y - parentPosition.Y

				newLabel.Position = UDim2.fromOffset(startX, startY)

				local camera = workspace.CurrentCamera
				local viewportSize = camera.ViewportSize
				local referenceSize = Vector2.new(1920, 1080)

				local screenScale = math.min(
					viewportSize.X / referenceSize.X,
					viewportSize.Y / referenceSize.Y
				)
				screenScale = math.min(screenScale, 1)
				local angle = math.random() * math.pi * 2
				local distance = math.random(300, 320) * screenScale

				local offsetX = math.cos(angle) * distance
				local offsetY = math.sin(angle) * distance

				local targetPosition = UDim2.fromOffset(
					startX + offsetX,
					startY + offsetY
				)
				local moveTween =
					TweenService:Create(
						newLabel,
						TweenInfo.new(
							0.4,
							Enum.EasingStyle.Quad,
							Enum.EasingDirection.Out
						),
						{
							Position = targetPosition
						}
					)
				moveTween:Play()
				moveTween.Completed:Once(function()
					local fadeTween =
						TweenService:Create(
							newLabel,
							TweenInfo.new(
								0.35,
								Enum.EasingStyle.Quad,
								Enum.EasingDirection.Out
							),
							{
								TextTransparency = 1
							}
						)
					if stroke then
						TweenService:Create(
							stroke,
							TweenInfo.new(
								0.35,
								Enum.EasingStyle.Quad,
								Enum.EasingDirection.Out
							),
							{
								Transparency = 1
							}
						):Play()
					end
					fadeTween:Play()
					fadeTween.Completed:Once(function()
						newLabel:Destroy()
					end)
				end)
			end
		end
		task.wait(Speed)
	end
end)

--upgrades
local UpgradeRequirements = {
	
	["Auto Teto Power"] = {
		Upgrade = "Auto Teto",
		Level = 1
	},
	["Auto Teto Speed"] = {
		Upgrade = "Auto Teto",
		Level = 1
	},
	["Unlock Baguettes"] = {
		Upgrade = "Auto Teto",
		Level = 1
	},
	
	["Unlock Offline Teto"] = {
		Upgrade = "Auto Teto",
		Level = 1
	},
	["+10 Teto"] = {
		Upgrade = "Auto Teto",
		Level = 1
	},
	["+10 Auto Teto"] = {
		Upgrade = "Auto Teto",
		Level = 1
	},
}


for _, v in pairs(scrollingupgrades:GetDescendants()) do
	if v:IsA("TextButton") and v.Name == "Buy" then
		local upgrade = v.Parent
		local price = upgrade:FindFirstChild("Price")
		local lvlValue = upgrade:FindFirstChild("LvL")
		local max = upgrade:FindFirstChild("Max")
		local title = upgrade:FindFirstChild("Title")
		local priceText = upgrade:FindFirstChild("PriceText")
		if not price or not lvlValue then
			continue
		end
		local function updateButton()

			local clicks =
				player:GetAttribute("Clicks") or 0
			local requirement =
				UpgradeRequirements[upgrade.Name]
			if requirement then
				local requiredUpgrade =
					scrollingupgrades:FindFirstChild(
						requirement.Upgrade,
						true
					)
				if requiredUpgrade then
					local requiredLvL =
						requiredUpgrade:FindFirstChild("LvL")
					if requiredLvL then
						if requiredLvL.Value < requirement.Level then
							v.BackgroundColor3 =
								Color3.fromRGB(120, 120, 120)

							v.Text = "LOCKED"
							v.Active = false
							v.Parent.Image.Visible = false
							v.Parent.LOCKED.Visible = true
							v.Parent.Level.Text = "LvL: 0"
							if title then
								title.Text = "LOCKED"
							end
							if priceText then
								priceText.Text = "Price: LOCKED"
							end
							return
						end
					end
				end
			end
			if title then
				title.Text = upgrade.Name
			end

			if priceText then
				priceText.Text = "Price: ".. price.Value.." T"
				v.Active = true
				v.Parent.Image.Visible = true
				v.Parent.LOCKED.Visible = false
				v.Parent.Level.Text = "LvL: ".. lvlValue.Value
			end
			if lvlValue.Value >= max.Value then

				v.BackgroundColor3 =
					Color3.fromRGB(90, 255, 68)

				v.Text = "MAX"

				return
			end
			v.Text = "BUY"
			if clicks >= price.Value then
				v.BackgroundColor3 =
					Color3.fromRGB(90, 255, 68)
			else
				v.BackgroundColor3 =
					Color3.fromRGB(178, 113, 116)
			end
		end
		player:GetAttributeChangedSignal("Clicks"):Connect(function()
			updateButton()
		end)
		price.Changed:Connect(function()
			updateButton()
		end)
		lvlValue.Changed:Connect(function()
			updateButton()

		end)
		
		local requirement =
			UpgradeRequirements[upgrade.Name]
		if requirement then

			local requiredUpgrade =
				scrollingupgrades:FindFirstChild(
					requirement.Upgrade,
					true
				)
			if requiredUpgrade then
				local requiredLvL =
					requiredUpgrade:FindFirstChild("LvL")
				if requiredLvL then
					requiredLvL.Changed:Connect(function()
						updateButton()
					end)
				end
			end
		end
		updateButton()
		v.Activated:Connect(function()
			local clicks =
				player:GetAttribute("Clicks") or 0
			local lvl =
				lvlValue.Value
			local requirement =
				UpgradeRequirements[upgrade.Name]
			if requirement then
				local requiredUpgrade =
					scrollingupgrades:FindFirstChild(
						requirement.Upgrade,
						true
					)
				if requiredUpgrade then
					local requiredLvL =
						requiredUpgrade:FindFirstChild("LvL")
					if requiredLvL
						and requiredLvL.Value < requirement.Level then
						local sound =
							game.SoundService:FindFirstChild("Error")
						if sound then
							sound:Play()
						end
						return
					end
				end
			end
			if lvl >= max.Value then
				local sound =
					game.SoundService:FindFirstChild("Error")
				if sound then
					sound:Play()
				end
				return
			end
			if clicks < price.Value then
				local sound =
					game.SoundService:FindFirstChild("Error")
				if sound then
					sound:Play()
				end
				return
			end
			local sound =
				game.SoundService:FindFirstChild("Buy")

			if sound then
				sound:Play()
			end
			BuyUpgradeEvent:FireServer(
				upgrade.Name,
				price.Value,
				max.Value
			)
		end)
	end
end


local function updateAllUpgradeButtons()
	for _, v in ipairs(scrollingupgrades:GetDescendants()) do
		if v:IsA("TextButton") and v.Name == "Buy" then
			local upgrade = v.Parent
			local price = upgrade:FindFirstChild("Price")
			local lvlValue = upgrade:FindFirstChild("LvL")
			local max = upgrade:FindFirstChild("Max")
			local title = upgrade:FindFirstChild("Title")
			local priceText = upgrade:FindFirstChild("PriceText")

			if not price or not lvlValue or not max then
				continue
			end

			local clicks = player:GetAttribute("Clicks") or 0

			-- Requirement check
			local requirement = UpgradeRequirements[upgrade.Name]

			if requirement then
				local requiredUpgrade =
					scrollingupgrades:FindFirstChild(requirement.Upgrade, true)

				if requiredUpgrade then
					local requiredLvL =
						requiredUpgrade:FindFirstChild("LvL")

					if requiredLvL and requiredLvL.Value < requirement.Level then
						v.BackgroundColor3 =
							Color3.fromRGB(120, 120, 120)

						v.Text = "LOCKED"
						v.Active = false

						if upgrade:FindFirstChild("Image") then
							upgrade.Image.Visible = false
						end

						if upgrade:FindFirstChild("LOCKED") then
							upgrade.LOCKED.Visible = true
						end

						if upgrade:FindFirstChild("Level") then
							upgrade.Level.Text = "LvL: 0"
						end

						if title then
							title.Text = "LOCKED"
						end

						if priceText then
							priceText.Text = "Price: LOCKED"
						end

						continue
					end
				end
			end

			-- Normal UI
			if title then
				title.Text = upgrade.Name
			end

			if priceText then
				priceText.Text = "Price: " .. price.Value .. " T"
			end

			v.Active = true

			if upgrade:FindFirstChild("Image") then
				upgrade.Image.Visible = true
			end

			if upgrade:FindFirstChild("LOCKED") then
				upgrade.LOCKED.Visible = false
			end

			if upgrade:FindFirstChild("Level") then
				upgrade.Level.Text = "LvL: " .. lvlValue.Value
			end

			if lvlValue.Value >= max.Value then
				v.BackgroundColor3 =
					Color3.fromRGB(90, 255, 68)

				v.Text = "MAX"
			else
				v.Text = "BUY"

				if clicks >= price.Value then
					v.BackgroundColor3 =
						Color3.fromRGB(90, 255, 68)
				else
					v.BackgroundColor3 =
						Color3.fromRGB(178, 113, 116)
				end
			end
		end
	end
end

local RebirthEvent = game.ReplicatedStorage.Events:WaitForChild("RebirthEvent")

RebirthEvent.OnClientEvent:Connect(function(data)
	if data and data.ResetUpgrades then

		for _, upgrade in ipairs(scrollingupgrades:GetChildren()) do
			local lvlValue = upgrade:FindFirstChild("LvL")
			local price = upgrade:FindFirstChild("Price")
			local defaultPrice = upgrade:FindFirstChild("BasePrice")
			if upgrade.Name == "Unlock Baguettes" or upgrade.Name == "Unlock Offline Teto" then
				if lvlValue and lvlValue.Value == 1 then
					continue
				end
			end
			if lvlValue then
				lvlValue.Value = 0
			end
			if price and defaultPrice then
				price.Value = defaultPrice.Value
			end
		end
	end

	updateAllUpgradeButtons()
end)



BuyUpgradeEvent.OnClientEvent:Connect(function(upgradename, price, LvL)
	local upgrade = scrollingupgrades:FindFirstChild(
		upgradename,
		true
	)
	if not upgrade then
		return
	end
	local priceValue = upgrade:FindFirstChild("Price")
	local levelValue = upgrade:FindFirstChild("LvL")
	local priceText = upgrade:FindFirstChild("PriceText")
	local levelText = upgrade:FindFirstChild("Level")
	if priceValue then
		priceValue.Value = price
	end
	if levelValue then
		levelValue.Value = LvL
	end
	if priceText then
		priceText.Text = "Price: " .. price .. " T"
	end
	if levelText then
		levelText.Text = "LvL: " .. LvL
	end
end)


--load upgrade
local savedUpgrades = GetUpgradeData:InvokeServer()
for _, upgradeData in ipairs(savedUpgrades) do
	local upgrade = scrollingupgrades:FindFirstChild(
		upgradeData.Name,
		true
	)
	if upgrade then
		local LvL =
			upgrade:FindFirstChild("LvL")
		local lvltext = upgrade:FindFirstChild("Level")
		local price =
			upgrade:FindFirstChild("Price")
		local pricetext = upgrade:FindFirstChild("PriceText")
		if LvL then
			LvL.Value = upgradeData.Level
			lvltext.Text = "LvL: " .. LvL.Value
		end
		if price then
			price.Value = upgradeData.Price
			pricetext.Text = "Price: " .. price.Value.." T"
		end
		print(
			"LOADED UI:",
			upgradeData.Name,
			"LvL:", upgradeData.Level,
			"Price:", upgradeData.Price
		)
	end
end

--Baguette
local BaguetteFrame = script.Parent:FindFirstChild("Baguette", true)
local Baguettes = player:GetAttribute("Baguettes")
local AddBaguette = ReplicatedStorage.Events:WaitForChild("AddBaguette")
local BaguetteTemplate = BaguetteFrame:FindFirstChild("Baguette", true)
local BaguetteText = BaguetteFrame:FindFirstChild("BaguettesText", true)

local function updateBaguette()
	local baguettes = player:GetAttribute("Baguettes") or -1

	if baguettes == -1 then
		return
	end

	if BaguetteFrame then
		BaguetteFrame.Visible = true
		BaguetteText.Text = "🥖: " .. baguettes
	end
end

player:GetAttributeChangedSignal("Baguettes"):Connect(updateBaguette)
updateBaguette()

local function fadeBaguette(baguette, clicked)
	if not baguette or not baguette.Parent then
		return
	end
	baguette.Active = false
	local fadeInfo = TweenInfo.new(
		0.4,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	local tweens = {}
	if baguette:IsA("ImageButton") then
		table.insert(tweens, TweenService:Create(
			baguette,
			fadeInfo,
			{
				ImageTransparency = 1,
				BackgroundTransparency = 1
			}
			))
	end
	for _, object in ipairs(baguette:GetDescendants()) do
		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			table.insert(tweens, TweenService:Create(
				object,
				fadeInfo,
				{
					ImageTransparency = 1
				}
				))

		elseif object:IsA("TextLabel") or object:IsA("TextButton") then
			table.insert(tweens, TweenService:Create(
				object,
				fadeInfo,
				{
					TextTransparency = 1
				}
				))
		elseif object:IsA("UIStroke") then
			table.insert(tweens, TweenService:Create(
				object,
				fadeInfo,
				{
					Transparency = 1
				}
				))
		end
	end
	for _, tween in ipairs(tweens) do
		tween:Play()
	end
	task.delay(0.4, function()
		if baguette and baguette.Parent then
			baguette:Destroy()
		end
	end)

end

local function createBaguetteLabel(baguette)
	local addLabel = BaguetteFrame:FindFirstChild("AddLabel")
	if not addLabel then
		warn("AddLabel non trovato")
		return
	end

	local newLabel = addLabel:Clone()
	newLabel.Text = "+1🥖"
	newLabel.Visible = true
	newLabel.Parent = BaguetteFrame
	local baguetteCenter =
		baguette.AbsolutePosition + (baguette.AbsoluteSize / 2)
	local framePosition = BaguetteFrame.AbsolutePosition
	local x = baguetteCenter.X - framePosition.X
	local y = baguetteCenter.Y - framePosition.Y

	newLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	newLabel.Position = UDim2.fromOffset(x, y)
	local angle = math.random() * math.pi * 2
	local distance = math.random(60, 100)
	local offsetX = math.cos(angle) * distance
	local offsetY = math.sin(angle) * distance
	local targetPosition = UDim2.fromOffset(
		x + offsetX,
		y + offsetY
	)
	local stroke = newLabel:FindFirstChildOfClass("UIStroke")
	newLabel.TextTransparency = 0
	if stroke then
		stroke.Transparency = 0
	end
	local moveTween = TweenService:Create(
		newLabel,
		TweenInfo.new(
			0.35,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			Position = targetPosition
		}
	)
	moveTween:Play()
	moveTween.Completed:Connect(function()
		if not newLabel.Parent then
			return
		end
		local fadeInfo = TweenInfo.new(
			0.3,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)
		TweenService:Create(
			newLabel,
			fadeInfo,
			{
				TextTransparency = 1
			}
		):Play()
		if stroke then
			TweenService:Create(
				stroke,
				fadeInfo,
				{
					Transparency = 1
				}
			):Play()
		end
		task.delay(0.3, function()
			if newLabel and newLabel.Parent then
				newLabel:Destroy()
			end
		end)
	end)
end


task.spawn(function()
	while true do

		task.wait(math.random(420, 600))

		local baguettes =
			player:GetAttribute("Baguettes") or -1
		if baguettes >= 0 and BaguetteFrame.Visible then
			local baguette =
				BaguetteTemplate:Clone()
			baguette.Visible = true
			baguette.Active = true
			baguette.Parent = BaguetteFrame.Parent
			local framePosition =
				BaguetteFrame.AbsolutePosition
			local frameSize =
				BaguetteFrame.AbsoluteSize
			local parentPosition =
				baguette.Parent.AbsolutePosition
			local buttonSize =
				baguette.AbsoluteSize
			local minX =
				framePosition.X
			local maxX =
				framePosition.X
				+ frameSize.X
			- buttonSize.X
			local randomX =
				math.random(
					math.floor(minX),
					math.floor(maxX)
				)
			local startX =
				randomX - parentPosition.X
			local startY =
				framePosition.Y
			- parentPosition.Y
			- buttonSize.Y
			local endY =
				framePosition.Y
				+ frameSize.Y
			- parentPosition.Y
			baguette.Position =
				UDim2.fromOffset(
					startX,
					startY
				)
			local clicked = false
			local fallTween = TweenService:Create(
				baguette,
				TweenInfo.new(
					7,
					Enum.EasingStyle.Linear
				),
				{
					Position = UDim2.fromOffset(
						startX,
						endY
					)
				}
			)
			baguette.Activated:Connect(function()
				if clicked then
					return
				end
				clicked = true
				baguette.Active = false
				fallTween:Cancel()
				AddBaguette:FireServer()
				createBaguetteLabel(baguette)
				fadeBaguette(baguette, true)
			end)
			fallTween.Completed:Connect(function()
				if clicked then
					return
				end
				clicked = true
				fadeBaguette(baguette, false)
			end)
			fallTween:Play()
		end
	end
end)
--rebirth
local rebirthbutton = mainframe:FindFirstChild("Rebirth", true)
local rebirthframe = mainframe:FindFirstChild("RebirthFrame", true)

rebirthbutton.Activated:Connect(function()
	rebirthframe.Visible = not rebirthframe.Visible
end)
local buyButton = rebirthframe:FindFirstChild("Buy", true)
local priceText = rebirthframe:FindFirstChild("PriceText", true)
local function updateRebirthButton()
	local clicks = player:GetAttribute("Clicks") or 0
	local rebirthPrice = player:GetAttribute("RebirthPrice") or 1000
	if priceText then
		priceText.Text = "Price: " .. rebirthPrice .. " T"
	end

	if buyButton then

		buyButton.Text = "REBIRTH"
		buyButton.Active = true
		if clicks >= rebirthPrice then
			buyButton.BackgroundColor3 =
				Color3.fromRGB(90, 255, 68)
				rebirthbutton.Notification.Visible = true
		else
			buyButton.BackgroundColor3 =
				Color3.fromRGB(178, 113, 116)
			rebirthbutton.Notification.Visible = false
		end
	end
end


player:GetAttributeChangedSignal("Clicks"):Connect(
	updateRebirthButton
)
player:GetAttributeChangedSignal("RebirthPrice"):Connect(
	updateRebirthButton
)
player:GetAttributeChangedSignal("Rebirths"):Connect(
	updateRebirthButton
)


buyButton.Activated:Connect(function()
	local Upg = mainframe.Box:FindFirstChild("Upgrades").ScrollingFrame
	local clicks = player:GetAttribute("Clicks") or 0
	local rebirthPrice = player:GetAttribute("RebirthPrice") or 500000
	local baguette = Upg:FindFirstChild("Unlock Baguettes")
	if clicks < rebirthPrice then
		local sound =
			game.SoundService:FindFirstChild("Error")
		if sound then
			sound:Play()
		end
		return
	end
	local sound =
		game.SoundService:FindFirstChild("Buy")
	if sound then
		sound:Play()
	end
	rebirthevent:FireServer()

end)


updateRebirthButton()


local ReciveFrame = mainframe:FindFirstChild("ReciveFrame", true)
local claimB = ReciveFrame:FindFirstChild("Buy", true)
local SkinEvent = game.ReplicatedStorage.Events:WaitForChild("GiveSkin")
local secretevent = game.ReplicatedStorage.Events:WaitForChild("SecretAddSkin")
local randomskinfolder = game.ReplicatedStorage:WaitForChild("RandomSkins")
local image = nil
local Name = nil
local rebirths = player:GetAttribute("Rebirths") or 0

local function Recive()
	local sound = game.SoundService:FindFirstChild("Buy")
	image = ReciveFrame:FindFirstChild("Skin", true)
	Name = ReciveFrame:FindFirstChild("Name", true)
	local randomskins = randomskinfolder:GetChildren()
	local randomskin = randomskins[math.random(1, #randomskins)]
	local multipliertext = ReciveFrame.Multiplier
	multipliertext.Text = "x " .. randomskin.Multiplier.Value.."🎤"
	if randomskin then
		local imageid = randomskin.idle.Image	
		image.Image = imageid
		Name.Text = string.sub(randomskin.Name, 2)
		rebirthframe.Visible = false
		ReciveFrame.Visible = true
		secretevent:FireServer(randomskin.Name)
		print("randomskin")

	end
end

player:GetAttributeChangedSignal("Rebirths"):Connect(
	Recive
)

local function claim()
	local nameToFind = "!"..Name.Text
	local skinClient = Wardrobe:FindFirstChild(nameToFind)

	if not skinClient then
		return
	end

	skinClient.Visible = true
	skinClient.Interactable = true
	ReciveFrame.Visible = false

	local skin = ReplicatedStorage.RandomSkins:FindFirstChild(nameToFind)

	if not skin then
		warn("Skin not found:", nameToFind)
		return
	end

	local priceValue = skin:FindFirstChild("Price")

	if not priceValue then
		warn("No Price found for skin:", nameToFind)
		return
	end
	SkinEvent:FireServer(
		priceValue.Value,
		nameToFind
	)
	wait(0.1)
	skin:Destroy()
end

claimB.Activated:Connect(claim)

--OfflineEarns
local OfflineFrame = mainframe:FindFirstChild("AFKFrame", true)
local OfflineTime = OfflineFrame:FindFirstChild("Time")
local OfflineAmount = OfflineFrame:FindFirstChild("Amount")
local OfflineClaim = OfflineFrame:FindFirstChild("Buy")

OfflineEarningsEvent.OnClientEvent:Connect(function(amount, offlineTime)
	OfflineAmount.Text = "Received: ".."+" .. amount .. " 🎤"
	OfflineTime.Text = "You Were Offline For " .. formatTime(offlineTime)
	OfflineFrame.Visible = true

end)

OfflineClaim.Activated:Connect(function()
	local sound = game.SoundService:FindFirstChild("Buy")
	if sound then
		sound:Play()
	end
	OfflineEarningsEvent:FireServer()
	OfflineFrame.Visible = false

end)

--Temporaneo

local inputservice = game:GetService("UserInputService")

local function testLoop()
	TweenService:Create(
		Teto,
		TweenInfo.new(
			0.05,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			Size = clickSize
		}
	):Play()
	AddClick:FireServer()
	Teto.Image = Teto:FindFirstChild("1").Image
	task.wait(0.06)
	Teto.Image = Teto:FindFirstChild("2").Image
	task.wait(0.06)
	Teto.Image = Teto:FindFirstChild("3").Image
	task.wait(0.06)
	Teto.Image = Teto:FindFirstChild("idle").Image
	TweenService:Create(
		Teto,
		tweenInfo,
		{
			Size = clickSize
		}
	):Play()
	clicksound.TimePosition = 0
	clicksound:Play()
	CreateClickLabel()
end

inputservice.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.T then
		testLoop()
	end
end)

Teto.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		testLoop()
	end
end)
