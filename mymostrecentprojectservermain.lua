-- roblox: valecod1234 | discord: hamsterz8


local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_V45")

local AddClick = ReplicatedStorage.Events:WaitForChild("AddClick")
local BuySkinEvent = ReplicatedStorage.Events:WaitForChild("BuySkin")
local EquipSkinEvent = ReplicatedStorage.Events:WaitForChild("EquipSkinEvent")
local GetSkinData = ReplicatedStorage.Events:WaitForChild("GetSkinData")
-- these remotes are the bridge between the ui/client and this server script. the server keeps the important values here so the client cannot directly change saved progress.
local BuyUpgradeEvent = ReplicatedStorage.Events:WaitForChild("BuyUpgrade")
local GetUpgradeData = ReplicatedStorage.Events:WaitForChild("GetUpgradeData")
local AutoClick = ReplicatedStorage.Events:WaitForChild("AutoClick")
local AddBaguette = ReplicatedStorage.Events:WaitForChild("AddBaguette")
local RebirthEvent = ReplicatedStorage.Events:WaitForChild("RebirthEvent")
local SkinEvent = game.ReplicatedStorage.Events:WaitForChild("GiveSkin")
local OfflineEarningsEvent = ReplicatedStorage.Events:WaitForChild("OfflineEarnings")
local SecretAddSkin = game.ReplicatedStorage.Events:WaitForChild("SecretAddSkin")


-- these tables hold data that is easier to keep grouped than individual player attributes. attributes handle simple values, while these tables keep skins and upgrade records together.
local playerSkins = {}
local currentSkins = {}
local playerUpgrades = {}

local dataLoaded = {}
local pendingOfflineEarnings = {}
local saving = {}
-- the default skin is used whenever a new player has no saved selection, which also gives the rest of the script a safe fallback.
local DEFAULT_SKIN = "Default"

-- load data first so every later remote event can work with server-side state that has already been restored.
-- if no record exists, the player receives a complete starting table instead of making each system handle missing values separately.
local function loadData(player)

	-- datastore calls can fail because of temporary service issues, so the result is checked before any loaded values are used.
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	if not success then
		warn("FAILED TO LOAD DATA FOR " .. player.Name)
		player:Kick("Your data could not be loaded. Please rejoin.")
		return
	end

	-- a nil result means this is the first time the datastore has seen the player, so all progression starts from known values.

	if data == nil then

		data = {
			Rebirths = 0,
			RebirthBoost = 1,
			RebirthPrice = 500000, 
			Baguettes = -1,
			Clicks = 0,
			PlayerClick = 1,
			AutoClicks = 0,
			AutoTetoSpeed = 1,
			AutoClicksPower = 1,
			Skins = {},
			CurrentSkin = DEFAULT_SKIN,
			Upgrades = {},
			OfflineTeto = false,
			LastLogout = 0,
			PendingOfflineEarnings = 0, 
		}

	end

	-- FIELDS EXIST
	--verify that the values exists
	data.OfflineTeto = data.OfflineTeto or false
	data.LastLogout = data.LastLogout or 0
	data.Baguettes = data.Baguettes or -1
	data.RebirthPrice = data.RebirthPrice or 500000
	data.RebirthBoost = data.RebirthBoost or 1
	data.Rebirths = data.Rebirths or 0
	data.AutoTetoSpeed = data.AutoTetoSpeed or 1
	data.AutoClicks = data.AutoClicks or 0
	data.AutoClicksPower = data.AutoClicksPower or 1
	data.Clicks = data.Clicks or 0
	data.PlayerClick = data.PlayerClick or 1
	data.Skins = data.Skins or {}
	data.CurrentSkin = data.CurrentSkin or DEFAULT_SKIN
	data.PendingOfflineEarnings = data.PendingOfflineEarnings or 0
	data.Upgrades = data.Upgrades or {}
	
	for _, upgradeData in ipairs(data.Upgrades) do

		upgradeData.Level =
			math.round(upgradeData.Level or 1)

		upgradeData.Price =
			math.round(upgradeData.Price or 0)

	end

	-- LOAD PLAYER VALUES
	--load the values
	player:SetAttribute("AutoTetoSpeed", data.AutoTetoSpeed)
	player:SetAttribute("RebirthBoost", data.RebirthBoost)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("RebirthPrice", data.RebirthPrice)
	player:SetAttribute("Baguettes", data.Baguettes)
	player:SetAttribute("Clicks", data.Clicks)
	player:SetAttribute("PlayerClick", data.PlayerClick)
	player:SetAttribute("AutoClicks", data.AutoClicks)
	player:SetAttribute("AutoClicksPower", data.AutoClicksPower)
	player:SetAttribute("OfflineTeto", data.OfflineTeto)
	player:SetAttribute("LastLogout", data.LastLogout)
	player:SetAttribute("Multiplier", 1)
	player:SetAttribute("CurrentSkin", data.CurrentSkin or DEFAULT_SKIN)
	playerSkins[player] = data.Skins
	currentSkins[player] = data.CurrentSkin
	playerUpgrades[player] = data.Upgrades
	data.PendingOfflineEarnings = data.PendingOfflineEarnings
	dataLoaded[player] = true
	
	-- OFFLINE EARNINGS LOADING
	--calculate the offline earnings once the data is definied
	local lastLogout = data.LastLogout or 0
	local offlineTeto = data.OfflineTeto or false
	local previousPending = data.PendingOfflineEarnings or 0
	local newOfflineEarnings = 0
	local offlineTime = 0
	if offlineTeto and lastLogout > 0 then
		offlineTime = os.time() - lastLogout
		local minimumOfflineTime = 10 * 60
		if offlineTime >= minimumOfflineTime then
			local autoClicks = data.AutoClicks or 0
			local autoPower = data.AutoClicksPower or 1
			local autoSpeed = data.AutoTetoSpeed or 1
			local rebirthBoost = data.RebirthBoost or 1
			local earningsPerSecond =
				(autoClicks * autoPower * rebirthBoost)
				/ autoSpeed
			newOfflineEarnings =
				math.floor(earningsPerSecond * offlineTime)
		end
	end
	local totalPending =
		previousPending + newOfflineEarnings
	if totalPending > 0 then
		pendingOfflineEarnings[player] = {
			Amount = totalPending,
			Time = offlineTime
		}
		OfflineEarningsEvent:FireClient(
			player,
			totalPending,
			offlineTime
		)
		print(
			"OFFLINE TETO WAITING:",
			player.Name,
			"Previous:", previousPending,
			"New:", newOfflineEarnings,
			"Total:", totalPending
		)
	else
		pendingOfflineEarnings[player] = nil
	end
	print(
		"LOADED:",
		player.Name,
		"Rebirths:", data.Rebirths,
		"RebirthBoost:", data.RebirthBoost,
		"RebirthPrice:", data.RebirthPrice,
		"AutoTetoSpeed:", data.AutoTetoSpeed,
		"Baguettes:", data.Baguettes,
		"Clicks:", data.Clicks,
		"AutoClicksPower:", data.AutoClicksPower,
		"AutoClicks:", data.AutoClicks,
		"PlayerClick:", data.PlayerClick,
		"CurrentSkin:", data.CurrentSkin,
		"LastLog", data.LastLogout,
		"OfflineTeto:", data.OfflineTeto,
		"pendingOfflineEarnings", data.PendingOfflineEarnings
		
		
		
	)

	for _, upgrade in ipairs(data.Upgrades) do

		print(
			"  Upgrade:",
			upgrade.Name,
			"Level:", upgrade.Level,
			"Price:", upgrade.Price
		)
	end
end

-- saving converts the current server state back into one datastore table. the saving flag prevents two save requests for the same player from running at the same time.
local function saveData(player)

	if saving[player] then
		return
	end

	-- mark the player before building the save table so another event cannot start a second save at the same time.
	saving[player] = true

	local data = {
		
		AutoTetoSpeed = player:GetAttribute("AutoTetoSpeed") or 1,
		RebirthBoost = player:GetAttribute("RebirthBoost") or 1,
		Rebirths = player:GetAttribute("Rebirths") or 0,
		RebirthPrice = player:GetAttribute("RebirthPrice") or 500000,
		Clicks = player:GetAttribute("Clicks") or 0,
		PlayerClick = player:GetAttribute("PlayerClick") or 1,
		AutoClicks = player:GetAttribute("AutoClicks") or 0,
		Baguettes = player:GetAttribute("Baguettes") or -1,
		AutoClicksPower = player:GetAttribute("AutoClicksPower") or 1,
		OfflineTeto = player:GetAttribute("OfflineTeto") or false,
		PendingOfflineEarnings = pendingOfflineEarnings[player] or nil,
		CurrentSkin = player:GetAttribute("CurrentSkin") or DEFAULT_SKIN,
		LastLogout = os.time(),
		
		Skins = playerSkins[player] or {},
		Upgrades = playerUpgrades[player] or {}

	}
	local success, err = pcall(function()

			-- updateasync writes the complete current snapshot through roblox's datastore api, keeping the save operation inside the protected call.
		PlayerDataStore:UpdateAsync(player.UserId, function()
			return data
		end)
	end)
	if success then
		print(
			"SAVED:",
			player.Name,
			"Rebirths:", data.Rebirths,
			"RebirthBoost:", data.RebirthBoost,
			"AutoTetoSpeed:", data.AutoTetoSpeed,
			"RebirthPrice:", data.RebirthPrice,
			"Baguettes:", data.Baguettes,
			"AutoClicksPower:", data.AutoClicksPower,
			"AutoClicks:", data.AutoClicks,
			"Clicks:", data.Clicks,
			"PlayerClick:", data.PlayerClick,
			"CurrentSkin:", data.CurrentSkin,
			"LastLog", data.LastLogout,
			"OfflineTeto:", data.OfflineTeto,
			"pendingOfflineEarnings", data.PendingOfflineEarnings
		)
		for _, upgrade in ipairs(data.Upgrades) do

			print(
				"  Upgrade:",
				upgrade.Name,
				"Level:", upgrade.Level,
				"Price:", upgrade.Price
			)
		end
	else

		warn(
			"FAILED TO SAVE "
				.. player.Name
				.. ": "
				.. tostring(err)
		)

	end
	saving[player] = nil
end

-- loading on playeradded makes the server finish restoring progression before gameplay requests are accepted by the data-loaded checks below.
Players.PlayerAdded:Connect(function(player)

	loadData(player)

end)

-- playerremoving is the normal exit path, so the current attributes and server tables are written before their in-memory entries are cleared.
Players.PlayerRemoving:Connect(function(player)

	if dataLoaded[player] then
		saveData(player)
	end
	playerSkins[player] = nil
	currentSkins[player] = nil
	playerUpgrades[player] = nil
	dataLoaded[player] = nil

end)

-- bindtoclose gives active players one last save attempt when roblox is shutting the server down, covering a case where playerremoving may not be enough.
game:BindToClose(function()

	for _, player in Players:GetPlayers() do

		if dataLoaded[player] then
			saveData(player)
		end
	end
end)

-- the client only requests a click; the server calculates the reward from server-owned attributes and the equipped skin so the client is not trusted with the final amount.
AddClick.OnServerEvent:Connect(function(player)

	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local playerClick = player:GetAttribute("PlayerClick") or 1
	local rebirthboost = player:GetAttribute("RebirthBoost") or 1
	local playerskin = player:GetAttribute("CurrentSkin") or "Default"
	-- the skin multiplier comes from the server-side replicated configuration, while the player multiplier comes from the current session attributes.
	local skinmultiplier = ReplicatedStorage:FindFirstChild("Skins"):FindFirstChild(playerskin).Multiplier.Value
	local multiplier = player:GetAttribute("Multiplier") or 1
	local togive = playerClick * rebirthboost * multiplier * skinmultiplier
	player:SetAttribute(
		"Clicks",
		clicks + togive
	)
end)
-- autoclick uses the same reward calculation as normal clicks, but the amount is based on the saved auto-click count. keeping the calculation on the server keeps the progression authoritative.
AutoClick.OnServerEvent:Connect(function(player)

	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local autoClicks = player:GetAttribute("AutoClicks") or 0
	local rebirthboost = player:GetAttribute("RebirthBoost") or 1
	local multiplier = player:GetAttribute("Multiplier") or 1
	local playerskin = player:GetAttribute("CurrentSkin") or "Default"
	local skinmultiplier = ReplicatedStorage:FindFirstChild("Skins"):FindFirstChild(playerskin).Multiplier.Value
	local multiplier = player:GetAttribute("Multiplier") or 1

	if autoClicks <= 0 then
		return
	end
	local togive = autoClicks * rebirthboost * multiplier * skinmultiplier
	player:SetAttribute(
		"Clicks",
		clicks + togive
	)
end)
-- baguettes are gated by the saved unlock value. the server checks that the feature is unlocked before changing the player's count.
AddBaguette.OnServerEvent:Connect(function(player)
	
	if not dataLoaded[player] then
		return
	end

	local baguettes = player:GetAttribute("Baguettes")

	if baguettes == nil or baguettes < 0 then
		return
	end

	player:SetAttribute("Baguettes", baguettes + 1)

end)

-- skin purchases read the price from the replicated skin object instead of trusting the price as the source of truth. the client value is only compared against that server value.
BuySkinEvent.OnServerEvent:Connect(function(player, clientPrice, skinName)

	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local skins = playerSkins[player]

	if not skins then
		return
	end

	local skin = ReplicatedStorage.Skins:FindFirstChild(skinName)

	if not skin then
		return
	end

	if table.find(skins, skinName) then
		return
	end

	local priceValue = skin:FindFirstChild("Price")

	if not priceValue then
		warn("No Price found for skin:", skinName)
		return
	end

	local price = priceValue.Value

	if clientPrice ~= price then
		warn(
			player.Name
				.. " sent an invalid price for "
				.. skinName
		)
		return
	end

	if clicks < price then
		return
	end

	player:SetAttribute(
		"Clicks",
		clicks - price
	)

	table.insert(skins, skinName)

	currentSkins[player] = skinName
	player:SetAttribute("CurrentSkin", skinName)

	BuySkinEvent:FireClient(
		player,
		skinName
	)
end)
-- this event handles skins from the random-skin flow. ownership is checked before inserting the skin, while the selected skin is still updated after the purchase succeeds.
SkinEvent.OnServerEvent:Connect(function(player, clientPrice, skinName)

	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local skins = playerSkins[player]

	if not skins then
		return
	end
	local skin = ReplicatedStorage.RandomSkins:FindFirstChild(skinName)

	if not skin then
		warn("Skin not found:", skinName)
		return
	end
	local alreadyOwned = table.find(skins, skinName) ~= nil

	local priceValue = skin:FindFirstChild("Price")

	if not priceValue then
		warn("No Price found for skin:", skinName)
		return
	end
	local price = priceValue.Value
	if clientPrice ~= price then
		warn(
			player.Name
				.. " sent an invalid price for "
				.. skinName
		)
		return
	end
	if clicks < price then
		return
	end
	player:SetAttribute(
		"Clicks",
		clicks - price
	)
	if not alreadyOwned then
		table.insert(skins, skinName)
	end

	currentSkins[player] = skinName
	player:SetAttribute("CurrentSkin", skinName)
	BuySkinEvent:FireClient(
		player,
		skinName
	)
end)
-- this server-side insert happens before the client finishes its claim animation, so a disconnect during the claim sequence does not leave the reward only on the client.
SecretAddSkin.OnServerEvent:Connect(function(player, skinName)
	if not dataLoaded[player] then
		return
	end

	local skins = playerSkins[player]

	if not skins then
		return
	end

	local skin = ReplicatedStorage.RandomSkins:FindFirstChild(skinName)

	if not skin then
		warn("Skin not found:", skinName)
		return
	end

	if table.find(skins, skinName) then
		return
	end

	table.insert(skins, skinName)
end)


-- equipping changes only the active skin reference. the owned-skin table is kept separately so changing the equipped skin does not remove other collected skins.
EquipSkinEvent.OnServerEvent:Connect(function(player, skinName)

	if not dataLoaded[player] then
		return
	end

	local skins = playerSkins[player]

	if not skins then
		return
	end

	if not ReplicatedStorage.Skins:FindFirstChild(skinName) then
		return
	end

	if not table.find(skins, skinName) then
		table.insert(skins, skinName)
	end

	currentSkins[player] = skinName
	player:SetAttribute("CurrentSkin", skinName)

	print(
		player.Name
			.. " equipped "
			.. skinName
	)
end)


-- the client needs a server-approved snapshot of its skin inventory and current selection. waiting for data-loaded prevents an early remote call from receiving an incomplete table.
GetSkinData.OnServerInvoke = function(player)

	while not dataLoaded[player] do
		task.wait()
	end

	return
		playerSkins[player] or {},
		currentSkins[player] or DEFAULT_SKIN
end

-- upgrades are returned from the same server table used by the purchase handler, keeping the ui synchronized with the progression that will actually be saved.
GetUpgradeData.OnServerInvoke = function(player)

	while not dataLoaded[player] do
		task.wait()
	end
	return playerUpgrades[player] or {}
end


-- upgrades are stored as records so each one can keep its own level, price, and maximum level. after the purchase changes the record, the updated state is saved and sent back to the client.
BuyUpgradeEvent.OnServerEvent:Connect(function(
	player,
	upgradeName,
	clientPrice,
	clientMaxLevel
)

	if not dataLoaded[player] then
		return
	end

	local upgrades = playerUpgrades[player]

	if not upgrades then
		return
	end

	-- search the player's existing records first so a purchase increases the saved upgrade instead of creating duplicate records.
	local savedUpgrade

	for _, upgradeData in ipairs(upgrades) do
		if upgradeData.Name == upgradeName then
			savedUpgrade = upgradeData
			break
		end
	end

	if not savedUpgrade then
		if typeof(clientPrice) ~= "number"
			or typeof(clientMaxLevel) ~= "number" then
			return
		end

		savedUpgrade = {
			Name = upgradeName,
			Level = 0,
			MaxLevel = math.round(clientMaxLevel),
			Price = math.round(clientPrice)
		}

		table.insert(upgrades, savedUpgrade)
	end

	if savedUpgrade.Level >= savedUpgrade.MaxLevel then
		return
	end

	local price = savedUpgrade.Price
	local clicks = player:GetAttribute("Clicks") or 0

	if clicks < price then
		return
	end

	player:SetAttribute("Clicks", clicks - price)

	savedUpgrade.Level += 1
	savedUpgrade.Price = math.round(price * 1.3)

	if upgradeName == "+1 Teto" then

		local playerClick = player:GetAttribute("PlayerClick") or 1

		player:SetAttribute(
			"PlayerClick",
			playerClick + 1
		)
	elseif upgradeName == "+10 Teto" then

		local playerClick = player:GetAttribute("PlayerClick") or 1

		player:SetAttribute(
			"PlayerClick",
			playerClick + 10
		)

	elseif upgradeName == "Auto Teto" then
		local autoClicks = player:GetAttribute("AutoClicks") or 0
		player:SetAttribute(
			"AutoClicks",
			autoClicks + 1
		)
	elseif upgradeName == "+10 Auto Teto" then
		local autoClicks = player:GetAttribute("AutoClicks") or 0
		player:SetAttribute(
			"AutoClicks",
			autoClicks + 10
		)
	elseif upgradeName == "Auto Teto Power" then
		local autoClicksPower =
			player:GetAttribute("AutoClicksPower") or 1
		player:SetAttribute(
			"AutoClicksPower",
			autoClicksPower + 1
		)
	elseif upgradeName == "Auto Teto Speed" then
		local AutoTetoSpeed =
			player:GetAttribute("AutoTetoSpeed") or 1
		player:SetAttribute(
			"AutoTetoSpeed",
			AutoTetoSpeed - 0.05
		)
	elseif upgradeName == "Unlock Baguettes" then
		local Baguettes = player:GetAttribute("Baguettes") or 1
		player:SetAttribute(
			"Baguettes",
			Baguettes + 1
		)
	elseif upgradeName == "Unlock Offline Teto" then
		player:SetAttribute(
			"OfflineTeto",
			true
		)
	end
	task.spawn(function()
		saveData(player)
	end)

	BuyUpgradeEvent:FireClient(
		player,
		upgradeName,
		savedUpgrade.Price,
		savedUpgrade.Level
	)

	print(
		"BOUGHT UPGRADE:",
		player.Name,
		upgradeName,
		"Level:", savedUpgrade.Level,
		"MaxLevel:", savedUpgrade.MaxLevel,
		"Price:", savedUpgrade.Price
	)
end)
-- rebirth resets temporary progression while rebuilding a smaller upgrade table containing only permanent upgrades. the player's skins are intentionally kept outside this reset.
RebirthEvent.OnServerEvent:Connect(function(player)
	if not dataLoaded[player] then
		return
	end
	local upgradesGui =
		player.PlayerGui.Main:FindFirstChild("Upgrades", true)

	local scrollingFrame =
		upgradesGui
		and upgradesGui:FindFirstChild("ScrollingFrame")

	local clicks =
		player:GetAttribute("Clicks") or 0

	local rebirthPrice =
		player:GetAttribute("RebirthPrice") or 500000
	if clicks < rebirthPrice then
		return
	end

	local oldClicks = clicks

	local clickReward =
		math.round(oldClicks * 0.2)

	local newRebirthPrice =
		math.floor(rebirthPrice * 1.3)

	player:SetAttribute("Clicks",clickReward)
	player:SetAttribute("PlayerClick",1)
	player:SetAttribute("AutoClicks",0)
	player:SetAttribute("AutoClicksPower",1)
	player:SetAttribute("AutoTetoSpeed",1)
	player:SetAttribute("Rebirths",(player:GetAttribute("Rebirths") or 0) + 1)
	player:SetAttribute("RebirthBoost",(player:GetAttribute("RebirthBoost") or 1) * 1.5)
	player:SetAttribute("RebirthPrice",newRebirthPrice)
	-- these names are the small set of upgrades that survive rebirth. using a lookup table makes the preservation check simple and avoids repeated comparisons.
	local permanentUpgrades = {
		["Unlock Baguettes"] = true,
		["Unlock Offline Teto"] = true
	}

	local preservedUpgrades = {}
	for _, upgradeData in ipairs(playerUpgrades[player] or {}) do

		if permanentUpgrades[upgradeData.Name]
			and upgradeData.Level >= 1 then

			table.insert(
				preservedUpgrades,
				{
					Name = upgradeData.Name,
					Level = upgradeData.Level,
					MaxLevel = upgradeData.MaxLevel,
					Price = upgradeData.Price
				}
			)

		end
	end
	if scrollingFrame then

		for _, upgradeFrame in ipairs(scrollingFrame:GetChildren()) do

			local lvlValue =
				upgradeFrame:FindFirstChild("LvL")

			local priceValue =
				upgradeFrame:FindFirstChild("Price")

			local basePrice =
				upgradeFrame:FindFirstChild("BasePrice")

			if lvlValue then
				lvlValue.Value = 0
			end

			if priceValue and basePrice then
				priceValue.Value = basePrice.Value
			end
		end
		for _, upgradeData in ipairs(preservedUpgrades) do

			local upgrade =
				scrollingFrame:FindFirstChild(
					upgradeData.Name,
					true
				)

			if upgrade then

				local lvlValue =
					upgrade:FindFirstChild("LvL")

				local priceValue =
					upgrade:FindFirstChild("Price")

				if lvlValue then
					lvlValue.Value =
						upgradeData.Level
				end

				if priceValue then
					priceValue.Value =
						upgradeData.Price
				end
			end
		end
	end

	playerUpgrades[player] = preservedUpgrades
	saveData(player)

	RebirthEvent:FireClient(player, {
		RebirthPrice = newRebirthPrice,
		ResetUpgrades = true
	})

	print(
		"REBIRTH:",
		player.Name,
		"| Old Clicks:",
		oldClicks,
		"| Reward:",
		clickReward,
		"| New Price:",
		newRebirthPrice,
		"| Rebirths:",
		player:GetAttribute("Rebirths"),
		"| Boost:",
		player:GetAttribute("RebirthBoost")
	)
-- printing the preserved upgrades makes it easier to verify that the reset removed temporary upgrades without losing the permanent ones.
	for _, upgradeData in
		ipairs(preservedUpgrades) do

		print(
			"KEPT UPGRADE:",
			upgradeData.Name,
			"Level:",
			upgradeData.Level
		)
	end
end)

-- this admin-only reset is kept separate from normal progression so testing can clear a player's datastore record and immediately restore the default runtime values.
local ADMINS = {
	[2768492361] = true, 
}

local function resetPlayerData(targetPlayer)
	if not targetPlayer then
		return false
	end

	local success, err = pcall(function()
		PlayerDataStore:RemoveAsync(targetPlayer.UserId)
	end)

	if not success then
		warn("FAILED TO RESET DATA FOR " .. targetPlayer.Name .. ": " .. tostring(err))
		return false
	end

	targetPlayer:SetAttribute("AutoTetoSpeed", 1)
	targetPlayer:SetAttribute("RebirthBoost", 1)
	targetPlayer:SetAttribute("Rebirths", 0)
	targetPlayer:SetAttribute("RebirthPrice", 500000)
	targetPlayer:SetAttribute("Baguettes", -1)
	targetPlayer:SetAttribute("Clicks", 0)
	targetPlayer:SetAttribute("PlayerClick", 1)
	targetPlayer:SetAttribute("AutoClicks", 0)
	targetPlayer:SetAttribute("AutoClicksPower", 1)
	targetPlayer:SetAttribute("CurrentSkin", DEFAULT_SKIN)
	playerSkins[targetPlayer] = {}
	currentSkins[targetPlayer] = DEFAULT_SKIN
	playerUpgrades[targetPlayer] = {}

	print("RESET DATA:", targetPlayer.Name)

	return true
end


-- the reset flow teleports the affected player into a fresh server. this listener handles a failed teleport so the player is not left assuming the reset completed cleanly.
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
	if player.Parent then
		player:Kick("Your data was reset, but the server transfer failed. Please rejoin.")
	end
end)
-- if the teleport cannot be started, the player is kicked with the same explanation so they can rejoin and load the reset state.


-- only user ids in the admin table can trigger the reset command. the target is resolved on the server before the datastore is changed.
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if not ADMINS[player.UserId] then
			return
		end

		local args = string.split(message, " ")
		if string.lower(args[1]) ~= "!reset" then
			return
		end
		local username = args[2]
		local targetPlayer = player
		if username then
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if string.lower(otherPlayer.Name) == string.lower(username) then
					targetPlayer = otherPlayer
					break
				end
			end
			if targetPlayer == player and string.lower(username) ~= string.lower(player.Name) then
				warn("Player not found: " .. username)
				return
			end
		end
		if resetPlayerData(targetPlayer) then
			print(
				player.Name
					.. " reset the data of "
					.. targetPlayer.Name
			)
			local success, err = pcall(function()
				TeleportService:Teleport(
					game.PlaceId,
					targetPlayer
				)
			end)
			if not success then
				if targetPlayer.Parent then
					targetPlayer:Kick(
						"Your data was reset, but the server transfer failed. Please rejoin."
					)
				end
			end
		end
	end)
end)


-- the loading section calculates what is owed, while this event is responsible for claiming that pending amount. separating calculation from claiming prevents the same offline reward from being added twice.
OfflineEarningsEvent.OnServerEvent:Connect(function(player)

	if not dataLoaded[player] then
		return
	end

	local pending = pendingOfflineEarnings[player]

	if not pending then
		return
	end

	local amount = pending.Amount
	if typeof(amount) ~= "number" or amount <= 0 then
		pendingOfflineEarnings[player] = nil
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	player:SetAttribute(
		"Clicks",
		clicks + amount
	)

	pendingOfflineEarnings[player] = nil

	print(
		"OFFLINE TETO CLAIMED:",
		player.Name,
		"Earnings:", amount
	)
	task.spawn(function()
		saveData(player)
	end)

end)-- LOAD DATA
--loading of the data, if new player then  set everything to a base value
local function loadData(player)

	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	if not success then
		warn("FAILED TO LOAD DATA FOR " .. player.Name)
		player:Kick("Your data could not be loaded. Please rejoin.")
		return
	end

	-- NEW PLAYER

	if data == nil then

		data = {
			Rebirths = 0,
			RebirthBoost = 1,
			RebirthPrice = 500000, 
			Baguettes = -1,
			Clicks = 0,
			PlayerClick = 1,
			AutoClicks = 0,
			AutoTetoSpeed = 1,
			AutoClicksPower = 1,
			Skins = {},
			CurrentSkin = DEFAULT_SKIN,
			Upgrades = {},
			OfflineTeto = false,
			LastLogout = 0,
			PendingOfflineEarnings = 0, 
		}

	end

	-- FIELDS EXIST
	--verify that the values exists
	data.OfflineTeto = data.OfflineTeto or false
	data.LastLogout = data.LastLogout or 0
	data.Baguettes = data.Baguettes or -1
	data.RebirthPrice = data.RebirthPrice or 500000
	data.RebirthBoost = data.RebirthBoost or 1
	data.Rebirths = data.Rebirths or 0
	data.AutoTetoSpeed = data.AutoTetoSpeed or 1
	data.AutoClicks = data.AutoClicks or 0
	data.AutoClicksPower = data.AutoClicksPower or 1
	data.Clicks = data.Clicks or 0
	data.PlayerClick = data.PlayerClick or 1
	data.Skins = data.Skins or {}
	data.CurrentSkin = data.CurrentSkin or DEFAULT_SKIN
	data.PendingOfflineEarnings = data.PendingOfflineEarnings or 0
	data.Upgrades = data.Upgrades or {}
	
	for _, upgradeData in ipairs(data.Upgrades) do

		upgradeData.Level =
			math.round(upgradeData.Level or 1)

		upgradeData.Price =
			math.round(upgradeData.Price or 0)

	end

	-- LOAD PLAYER VALUES
	--load the values
	player:SetAttribute("AutoTetoSpeed", data.AutoTetoSpeed)
	player:SetAttribute("RebirthBoost", data.RebirthBoost)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("RebirthPrice", data.RebirthPrice)
	player:SetAttribute("Baguettes", data.Baguettes)
	player:SetAttribute("Clicks", data.Clicks)
	player:SetAttribute("PlayerClick", data.PlayerClick)
	player:SetAttribute("AutoClicks", data.AutoClicks)
	player:SetAttribute("AutoClicksPower", data.AutoClicksPower)
	player:SetAttribute("OfflineTeto", data.OfflineTeto)
	player:SetAttribute("LastLogout", data.LastLogout)
	player:SetAttribute("Multiplier", 1)
	player:SetAttribute("CurrentSkin", data.CurrentSkin or DEFAULT_SKIN)
	playerSkins[player] = data.Skins
	currentSkins[player] = data.CurrentSkin
	playerUpgrades[player] = data.Upgrades
	data.PendingOfflineEarnings = data.PendingOfflineEarnings
	dataLoaded[player] = true
	
	-- OFFLINE EARNINGS LOADING
	--calculate the offline earnings once the data is definied
	local lastLogout = data.LastLogout or 0
	local offlineTeto = data.OfflineTeto or false
	local previousPending = data.PendingOfflineEarnings or 0
	local newOfflineEarnings = 0
	local offlineTime = 0
	if offlineTeto and lastLogout > 0 then
		offlineTime = os.time() - lastLogout
		local minimumOfflineTime = 10 * 60
		if offlineTime >= minimumOfflineTime then
			local autoClicks = data.AutoClicks or 0
			local autoPower = data.AutoClicksPower or 1
			local autoSpeed = data.AutoTetoSpeed or 1
			local rebirthBoost = data.RebirthBoost or 1
			local earningsPerSecond =
				(autoClicks * autoPower * rebirthBoost)
				/ autoSpeed
			newOfflineEarnings =
				math.floor(earningsPerSecond * offlineTime)
		end
	end
	local totalPending =
		previousPending + newOfflineEarnings
	if totalPending > 0 then
		pendingOfflineEarnings[player] = {
			Amount = totalPending,
			Time = offlineTime
		}
		OfflineEarningsEvent:FireClient(
			player,
			totalPending,
			offlineTime
		)
		print(
			"OFFLINE TETO WAITING:",
			player.Name,
			"Previous:", previousPending,
			"New:", newOfflineEarnings,
			"Total:", totalPending
		)
	else
		pendingOfflineEarnings[player] = nil
	end
	print(
		"LOADED:",
		player.Name,
		"Rebirths:", data.Rebirths,
		"RebirthBoost:", data.RebirthBoost,
		"RebirthPrice:", data.RebirthPrice,
		"AutoTetoSpeed:", data.AutoTetoSpeed,
		"Baguettes:", data.Baguettes,
		"Clicks:", data.Clicks,
		"AutoClicksPower:", data.AutoClicksPower,
		"AutoClicks:", data.AutoClicks,
		"PlayerClick:", data.PlayerClick,
		"CurrentSkin:", data.CurrentSkin,
		"LastLog", data.LastLogout,
		"OfflineTeto:", data.OfflineTeto,
		"pendingOfflineEarnings", data.PendingOfflineEarnings
		
		
		
	)

	for _, upgrade in ipairs(data.Upgrades) do

		print(
			"  Upgrade:",
			upgrade.Name,
			"Level:", upgrade.Level,
			"Price:", upgrade.Price
		)
	end
end

-- SAVE DATA
--save the player data when leaving
local function saveData(player)

	if saving[player] then
		return
	end

	saving[player] = true

	local data = {
		
		AutoTetoSpeed = player:GetAttribute("AutoTetoSpeed") or 1,
		RebirthBoost = player:GetAttribute("RebirthBoost") or 1,
		Rebirths = player:GetAttribute("Rebirths") or 0,
		RebirthPrice = player:GetAttribute("RebirthPrice") or 500000,
		Clicks = player:GetAttribute("Clicks") or 0,
		PlayerClick = player:GetAttribute("PlayerClick") or 1,
		AutoClicks = player:GetAttribute("AutoClicks") or 0,
		Baguettes = player:GetAttribute("Baguettes") or -1,
		AutoClicksPower = player:GetAttribute("AutoClicksPower") or 1,
		OfflineTeto = player:GetAttribute("OfflineTeto") or false,
		PendingOfflineEarnings = pendingOfflineEarnings[player] or nil,
		CurrentSkin = player:GetAttribute("CurrentSkin") or DEFAULT_SKIN,
		LastLogout = os.time(),
		
		Skins = playerSkins[player] or {},
		Upgrades = playerUpgrades[player] or {}

	}
	local success, err = pcall(function()

		PlayerDataStore:UpdateAsync(player.UserId, function()
			return data
		end)
	end)
	if success then
		print(
			"SAVED:",
			player.Name,
			"Rebirths:", data.Rebirths,
			"RebirthBoost:", data.RebirthBoost,
			"AutoTetoSpeed:", data.AutoTetoSpeed,
			"RebirthPrice:", data.RebirthPrice,
			"Baguettes:", data.Baguettes,
			"AutoClicksPower:", data.AutoClicksPower,
			"AutoClicks:", data.AutoClicks,
			"Clicks:", data.Clicks,
			"PlayerClick:", data.PlayerClick,
			"CurrentSkin:", data.CurrentSkin,
			"LastLog", data.LastLogout,
			"OfflineTeto:", data.OfflineTeto,
			"pendingOfflineEarnings", data.PendingOfflineEarnings
		)
		for _, upgrade in ipairs(data.Upgrades) do

			print(
				"  Upgrade:",
				upgrade.Name,
				"Level:", upgrade.Level,
				"Price:", upgrade.Price
			)
		end
	else

		warn(
			"FAILED TO SAVE "
				.. player.Name
				.. ": "
				.. tostring(err)
		)

	end
	saving[player] = nil
end

-- PLAYER JOIN
--load player data as soon as he join
Players.PlayerAdded:Connect(function(player)

	loadData(player)

end)

-- PLAYER LEAVE
--save the player data
Players.PlayerRemoving:Connect(function(player)

	if dataLoaded[player] then
		saveData(player)
	end
	playerSkins[player] = nil
	currentSkins[player] = nil
	playerUpgrades[player] = nil
	dataLoaded[player] = nil

end)

-- SERVER SHUTDOWN
-- in case of shutdown save the data
game:BindToClose(function()

	for _, player in Players:GetPlayers() do

		if dataLoaded[player] then
			saveData(player)
		end
	end
end)

-- ADD CLICK
--add click each AddClick event which is connected to an ImageButton
AddClick.OnServerEvent:Connect(function(player)

	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local playerClick = player:GetAttribute("PlayerClick") or 1
	local rebirthboost = player:GetAttribute("RebirthBoost") or 1
	local playerskin = player:GetAttribute("CurrentSkin") or "Default"
	local skinmultiplier = ReplicatedStorage:FindFirstChild("Skins"):FindFirstChild(playerskin).Multiplier.Value
	local multiplier = player:GetAttribute("Multiplier") or 1
	local togive = playerClick * rebirthboost * multiplier * skinmultiplier
	player:SetAttribute(
		"Clicks",
		clicks + togive
	)
end)
--once autoclick is unlocked this makes the imagebutton generate clicks every seconds
AutoClick.OnServerEvent:Connect(function(player)

	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local autoClicks = player:GetAttribute("AutoClicks") or 0
	local rebirthboost = player:GetAttribute("RebirthBoost") or 1
	local multiplier = player:GetAttribute("Multiplier") or 1
	local playerskin = player:GetAttribute("CurrentSkin") or "Default"
	local skinmultiplier = ReplicatedStorage:FindFirstChild("Skins"):FindFirstChild(playerskin).Multiplier.Value
	local multiplier = player:GetAttribute("Multiplier") or 1

	if autoClicks <= 0 then
		return
	end
	local togive = autoClicks * rebirthboost * multiplier * skinmultiplier
	player:SetAttribute(
		"Clicks",
		clicks + togive
	)
end)
--add a baguette when the player chatch them
AddBaguette.OnServerEvent:Connect(function(player)
	
	if not dataLoaded[player] then
		return
	end

	local baguettes = player:GetAttribute("Baguettes")

	if baguettes == nil or baguettes < 0 then
		return
	end

	player:SetAttribute("Baguettes", baguettes + 1)

end)

-- BUY SKIN
--buying a skin from the shop
BuySkinEvent.OnServerEvent:Connect(function(player, clientPrice, skinName)

	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local skins = playerSkins[player]

	if not skins then
		return
	end

	local skin = ReplicatedStorage.Skins:FindFirstChild(skinName)

	if not skin then
		return
	end

	if table.find(skins, skinName) then
		return
	end

	local priceValue = skin:FindFirstChild("Price")

	if not priceValue then
		warn("No Price found for skin:", skinName)
		return
	end

	local price = priceValue.Value

	if clientPrice ~= price then
		warn(
			player.Name
				.. " sent an invalid price for "
				.. skinName
		)
		return
	end

	if clicks < price then
		return
	end

	player:SetAttribute(
		"Clicks",
		clicks - price
	)

	table.insert(skins, skinName)

	currentSkins[player] = skinName
	player:SetAttribute("CurrentSkin", skinName)

	BuySkinEvent:FireClient(
		player,
		skinName
	)
end)
--receiving a skin from the rebirth or a random skin blind box
SkinEvent.OnServerEvent:Connect(function(player, clientPrice, skinName)

	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local skins = playerSkins[player]

	if not skins then
		return
	end
	local skin = ReplicatedStorage.RandomSkins:FindFirstChild(skinName)

	if not skin then
		warn("Skin not found:", skinName)
		return
	end
	local alreadyOwned = table.find(skins, skinName) ~= nil

	local priceValue = skin:FindFirstChild("Price")

	if not priceValue then
		warn("No Price found for skin:", skinName)
		return
	end
	local price = priceValue.Value
	if clientPrice ~= price then
		warn(
			player.Name
				.. " sent an invalid price for "
				.. skinName
		)
		return
	end
	if clicks < price then
		return
	end
	player:SetAttribute(
		"Clicks",
		clicks - price
	)
	if not alreadyOwned then
		table.insert(skins, skinName)
	end

	currentSkins[player] = skinName
	player:SetAttribute("CurrentSkin", skinName)
	BuySkinEvent:FireClient(
		player,
		skinName
	)
end)
-- add the skin to the data before the player claims it so he will have it anyways if leaves
SecretAddSkin.OnServerEvent:Connect(function(player, skinName)
	if not dataLoaded[player] then
		return
	end

	local skins = playerSkins[player]

	if not skins then
		return
	end

	local skin = ReplicatedStorage.RandomSkins:FindFirstChild(skinName)

	if not skin then
		warn("Skin not found:", skinName)
		return
	end

	if table.find(skins, skinName) then
		return
	end

	table.insert(skins, skinName)
end)


-- EQUIP SKIN
--event to equip the skins
EquipSkinEvent.OnServerEvent:Connect(function(player, skinName)

	if not dataLoaded[player] then
		return
	end

	local skins = playerSkins[player]

	if not skins then
		return
	end

	if not ReplicatedStorage.Skins:FindFirstChild(skinName) then
		return
	end

	if not table.find(skins, skinName) then
		table.insert(skins, skinName)
	end

	currentSkins[player] = skinName
	player:SetAttribute("CurrentSkin", skinName)

	print(
		player.Name
			.. " equipped "
			.. skinName
	)
end)


-- GET SKIN DATA

--get the player's skin data
GetSkinData.OnServerInvoke = function(player)

	while not dataLoaded[player] do
		task.wait()
	end

	return
		playerSkins[player] or {},
		currentSkins[player] or DEFAULT_SKIN
end

-- GET UPGRADE DATA
--get the playrer upgrades
GetUpgradeData.OnServerInvoke = function(player)

	while not dataLoaded[player] do
		task.wait()
	end
	return playerUpgrades[player] or {}
end


-- BUY UPGRADE
--event to buy and save upgrades(connected to buttons)
BuyUpgradeEvent.OnServerEvent:Connect(function(
	player,
	upgradeName,
	clientPrice,
	clientMaxLevel
)

	if not dataLoaded[player] then
		return
	end

	local upgrades = playerUpgrades[player]

	if not upgrades then
		return
	end

	local savedUpgrade

	for _, upgradeData in ipairs(upgrades) do
		if upgradeData.Name == upgradeName then
			savedUpgrade = upgradeData
			break
		end
	end

	if not savedUpgrade then
		if typeof(clientPrice) ~= "number"
			or typeof(clientMaxLevel) ~= "number" then
			return
		end

		savedUpgrade = {
			Name = upgradeName,
			Level = 0,
			MaxLevel = math.round(clientMaxLevel),
			Price = math.round(clientPrice)
		}

		table.insert(upgrades, savedUpgrade)
	end

	if savedUpgrade.Level >= savedUpgrade.MaxLevel then
		return
	end

	local price = savedUpgrade.Price
	local clicks = player:GetAttribute("Clicks") or 0

	if clicks < price then
		return
	end

	player:SetAttribute("Clicks", clicks - price)

	savedUpgrade.Level += 1
	savedUpgrade.Price = math.round(price * 1.3)

	if upgradeName == "+1 Teto" then

		local playerClick = player:GetAttribute("PlayerClick") or 1

		player:SetAttribute(
			"PlayerClick",
			playerClick + 1
		)
	elseif upgradeName == "+10 Teto" then

		local playerClick = player:GetAttribute("PlayerClick") or 1

		player:SetAttribute(
			"PlayerClick",
			playerClick + 10
		)

	elseif upgradeName == "Auto Teto" then
		local autoClicks = player:GetAttribute("AutoClicks") or 0
		player:SetAttribute(
			"AutoClicks",
			autoClicks + 1
		)
	elseif upgradeName == "+10 Auto Teto" then
		local autoClicks = player:GetAttribute("AutoClicks") or 0
		player:SetAttribute(
			"AutoClicks",
			autoClicks + 10
		)
	elseif upgradeName == "Auto Teto Power" then
		local autoClicksPower =
			player:GetAttribute("AutoClicksPower") or 1
		player:SetAttribute(
			"AutoClicksPower",
			autoClicksPower + 1
		)
	elseif upgradeName == "Auto Teto Speed" then
		local AutoTetoSpeed =
			player:GetAttribute("AutoTetoSpeed") or 1
		player:SetAttribute(
			"AutoTetoSpeed",
			AutoTetoSpeed - 0.05
		)
	elseif upgradeName == "Unlock Baguettes" then
		local Baguettes = player:GetAttribute("Baguettes") or 1
		player:SetAttribute(
			"Baguettes",
			Baguettes + 1
		)
	elseif upgradeName == "Unlock Offline Teto" then
		player:SetAttribute(
			"OfflineTeto",
			true
		)
	end
	task.spawn(function()
		saveData(player)
	end)

	BuyUpgradeEvent:FireClient(
		player,
		upgradeName,
		savedUpgrade.Price,
		savedUpgrade.Level
	)

	print(
		"BOUGHT UPGRADE:",
		player.Name,
		upgradeName,
		"Level:", savedUpgrade.Level,
		"MaxLevel:", savedUpgrade.MaxLevel,
		"Price:", savedUpgrade.Price
	)
end)
--once the player can rebirth and presses the rebirth button clear his data except for 2 upgrades and baguettes and skins
RebirthEvent.OnServerEvent:Connect(function(player)
	if not dataLoaded[player] then
		return
	end
	local upgradesGui =
		player.PlayerGui.Main:FindFirstChild("Upgrades", true)

	local scrollingFrame =
		upgradesGui
		and upgradesGui:FindFirstChild("ScrollingFrame")

	local clicks =
		player:GetAttribute("Clicks") or 0

	local rebirthPrice =
		player:GetAttribute("RebirthPrice") or 500000
	if clicks < rebirthPrice then
		return
	end

	local oldClicks = clicks

	local clickReward =
		math.round(oldClicks * 0.2)

	local newRebirthPrice =
		math.floor(rebirthPrice * 1.3)

	player:SetAttribute("Clicks",clickReward)
	player:SetAttribute("PlayerClick",1)
	player:SetAttribute("AutoClicks",0)
	player:SetAttribute("AutoClicksPower",1)
	player:SetAttribute("AutoTetoSpeed",1)
	player:SetAttribute("Rebirths",(player:GetAttribute("Rebirths") or 0) + 1)
	player:SetAttribute("RebirthBoost",(player:GetAttribute("RebirthBoost") or 1) * 1.5)
	player:SetAttribute("RebirthPrice",newRebirthPrice)
	local permanentUpgrades = {
		["Unlock Baguettes"] = true,
		["Unlock Offline Teto"] = true
	}

	local preservedUpgrades = {}
	for _, upgradeData in ipairs(playerUpgrades[player] or {}) do

		if permanentUpgrades[upgradeData.Name]
			and upgradeData.Level >= 1 then

			table.insert(
				preservedUpgrades,
				{
					Name = upgradeData.Name,
					Level = upgradeData.Level,
					MaxLevel = upgradeData.MaxLevel,
					Price = upgradeData.Price
				}
			)

		end
	end
	if scrollingFrame then

		for _, upgradeFrame in ipairs(scrollingFrame:GetChildren()) do

			local lvlValue =
				upgradeFrame:FindFirstChild("LvL")

			local priceValue =
				upgradeFrame:FindFirstChild("Price")

			local basePrice =
				upgradeFrame:FindFirstChild("BasePrice")

			if lvlValue then
				lvlValue.Value = 0
			end

			if priceValue and basePrice then
				priceValue.Value = basePrice.Value
			end
		end
		for _, upgradeData in ipairs(preservedUpgrades) do

			local upgrade =
				scrollingFrame:FindFirstChild(
					upgradeData.Name,
					true
				)

			if upgrade then

				local lvlValue =
					upgrade:FindFirstChild("LvL")

				local priceValue =
					upgrade:FindFirstChild("Price")

				if lvlValue then
					lvlValue.Value =
						upgradeData.Level
				end

				if priceValue then
					priceValue.Value =
						upgradeData.Price
				end
			end
		end
	end

	playerUpgrades[player] = preservedUpgrades
	saveData(player)

	RebirthEvent:FireClient(player, {
		RebirthPrice = newRebirthPrice,
		ResetUpgrades = true
	})

	print(
		"REBIRTH:",
		player.Name,
		"| Old Clicks:",
		oldClicks,
		"| Reward:",
		clickReward,
		"| New Price:",
		newRebirthPrice,
		"| Rebirths:",
		player:GetAttribute("Rebirths"),
		"| Boost:",
		player:GetAttribute("RebirthBoost")
	)
--rebirth results
	for _, upgradeData in
		ipairs(preservedUpgrades) do

		print(
			"KEPT UPGRADE:",
			upgradeData.Name,
			"Level:",
			upgradeData.Level
		)
	end
end)

--testing command to reset my data
-- RESET DATA COMMAND
local ADMINS = {
	[2768492361] = true, 
}

local function resetPlayerData(targetPlayer)
	if not targetPlayer then
		return false
	end

	local success, err = pcall(function()
		PlayerDataStore:RemoveAsync(targetPlayer.UserId)
	end)

	if not success then
		warn("FAILED TO RESET DATA FOR " .. targetPlayer.Name .. ": " .. tostring(err))
		return false
	end

	targetPlayer:SetAttribute("AutoTetoSpeed", 1)
	targetPlayer:SetAttribute("RebirthBoost", 1)
	targetPlayer:SetAttribute("Rebirths", 0)
	targetPlayer:SetAttribute("RebirthPrice", 500000)
	targetPlayer:SetAttribute("Baguettes", -1)
	targetPlayer:SetAttribute("Clicks", 0)
	targetPlayer:SetAttribute("PlayerClick", 1)
	targetPlayer:SetAttribute("AutoClicks", 0)
	targetPlayer:SetAttribute("AutoClicksPower", 1)
	targetPlayer:SetAttribute("CurrentSkin", DEFAULT_SKIN)
	playerSkins[targetPlayer] = {}
	currentSkins[targetPlayer] = DEFAULT_SKIN
	playerUpgrades[targetPlayer] = {}

	print("RESET DATA:", targetPlayer.Name)

	return true
end


-- Detect teleport failures
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
	if player.Parent then
		player:Kick("Your data was reset, but the server transfer failed. Please rejoin.")
	end
end)
--if fail to make the player rejoin kick him


--check if the player chats "!reset" and if he's an admin
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if not ADMINS[player.UserId] then
			return
		end

		local args = string.split(message, " ")
		if string.lower(args[1]) ~= "!reset" then
			return
		end
		local username = args[2]
		local targetPlayer = player
		if username then
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if string.lower(otherPlayer.Name) == string.lower(username) then
					targetPlayer = otherPlayer
					break
				end
			end
			if targetPlayer == player and string.lower(username) ~= string.lower(player.Name) then
				warn("Player not found: " .. username)
				return
			end
		end
		if resetPlayerData(targetPlayer) then
			print(
				player.Name
					.. " reset the data of "
					.. targetPlayer.Name
			)
			local success, err = pcall(function()
				TeleportService:Teleport(
					game.PlaceId,
					targetPlayer
				)
			end)
			if not success then
				if targetPlayer.Parent then
					targetPlayer:Kick(
						"Your data was reset, but the server transfer failed. Please rejoin."
					)
				end
			end
		end
	end)
end)


--offline earnings are connected to the first section of the data loading, this is for the calculation
--OfflineEarnings
OfflineEarningsEvent.OnServerEvent:Connect(function(player)

	if not dataLoaded[player] then
		return
	end

	local pending = pendingOfflineEarnings[player]

	if not pending then
		return
	end

	local amount = pending.Amount

	if typeof(amount) ~= "number" or amount <= 0 then
		pendingOfflineEarnings[player] = nil
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0

	player:SetAttribute(
		"Clicks",
		clicks + amount
	)

	pendingOfflineEarnings[player] = nil

	print(
		"OFFLINE TETO CLAIMED:",
		player.Name,
		"Earnings:", amount
	)

	task.spawn(function()
		saveData(player)
	end)

end)
