-- roblox: valecod1234 | discord: hamsterz8

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_V45")
local Events = ReplicatedStorage:WaitForChild("Events")

local AddClick = Events:WaitForChild("AddClick")
local BuySkinEvent = Events:WaitForChild("BuySkin")
local EquipSkinEvent = Events:WaitForChild("EquipSkinEvent")
local GetSkinData = Events:WaitForChild("GetSkinData")
-- these remotes are the bridge between the ui/client and this server script.
-- the server keeps the important values here so the client cannot directly change saved progress.
local BuyUpgradeEvent = Events:WaitForChild("BuyUpgrade")
local GetUpgradeData = Events:WaitForChild("GetUpgradeData")
local AutoClick = Events:WaitForChild("AutoClick")
local AddBaguette = Events:WaitForChild("AddBaguette")
local RebirthEvent = Events:WaitForChild("RebirthEvent")
local SkinEvent = Events:WaitForChild("GiveSkin")
local OfflineEarningsEvent = Events:WaitForChild("OfflineEarnings")
local SecretAddSkin = Events:WaitForChild("SecretAddSkin")

-- these tables hold data that is easier to keep grouped than individual player attributes.
-- attributes handle simple values, while these tables keep skins and upgrade records together.
local playerSkins = {}
local currentSkins = {}
local playerUpgrades = {}
local dataLoaded = {}
local pendingOfflineEarnings = {}
local saving = {}

-- the default skin is used whenever a new player has no saved selection.
local DEFAULT_SKIN = "Default"

-- only these user ids can use the admin reset command.
local ADMINS = {
	[2768492361] = true,
}

-- default values are kept here so new players and resets use the same values.
local function getDefaultData()
	return {
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

-- returns the multiplier for the player's currently equipped skin.
local function getSkinMultiplier(player)
	local skinName = player:GetAttribute("CurrentSkin") or DEFAULT_SKIN
	local folder = ReplicatedStorage:FindFirstChild("Skins")
	local skin = folder and folder:FindFirstChild(skinName)
	local multiplier = skin and skin:FindFirstChild("Multiplier")
	return multiplier and multiplier.Value or 1
end

-- combines rebirth, player and skin multipliers into the final click multiplier.
local function getClickMultiplier(player)
	return (player:GetAttribute("RebirthBoost") or 1)
		* (player:GetAttribute("Multiplier") or 1)
		* getSkinMultiplier(player)
end

-- load data first so every later remote event can work with server-side state that has already been restored.
local function loadData(player)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	-- datastore calls can fail because of temporary service issues, so the result is checked before any loaded values are used.
	if not success then
		warn("FAILED TO LOAD DATA FOR " .. player.Name)
		player:Kick("Your data could not be loaded. Please rejoin.")
		return
	end

	-- a nil result means this is the first time the datastore has seen the player.
	data = data or getDefaultData()

	-- FIELDS EXIST
	-- verify that the values exist.
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
		upgradeData.Level = math.round(upgradeData.Level or 1)
		upgradeData.Price = math.round(upgradeData.Price or 0)
		upgradeData.MaxLevel = math.round(upgradeData.MaxLevel or 1)
	end

	-- LOAD PLAYER VALUES
	-- load the values into server-owned player attributes.
	local attributes = {
		AutoTetoSpeed = data.AutoTetoSpeed,
		RebirthBoost = data.RebirthBoost,
		Rebirths = data.Rebirths,
		RebirthPrice = data.RebirthPrice,
		Baguettes = data.Baguettes,
		Clicks = data.Clicks,
		PlayerClick = data.PlayerClick,
		AutoClicks = data.AutoClicks,
		AutoClicksPower = data.AutoClicksPower,
		OfflineTeto = data.OfflineTeto,
		LastLogout = data.LastLogout,
		Multiplier = 1,
		CurrentSkin = data.CurrentSkin,
	}

	for name, value in pairs(attributes) do
		player:SetAttribute(name, value)
	end

	playerSkins[player] = data.Skins
	currentSkins[player] = data.CurrentSkin
	playerUpgrades[player] = data.Upgrades
	dataLoaded[player] = true

	-- OFFLINE EARNINGS LOADING
	-- calculate the offline earnings once the data is defined.
	local lastLogout = data.LastLogout
	local offlineTime = 0
	local newOfflineEarnings = 0

	if data.OfflineTeto and lastLogout > 0 then
		offlineTime = math.max(0, os.time() - lastLogout)

		local minimumOfflineTime = 10 * 60

		if offlineTime >= minimumOfflineTime then
			local earningsPerSecond =
				(data.AutoClicks * data.AutoClicksPower * data.RebirthBoost)
				/ math.max(data.AutoTetoSpeed, 0.05)

			newOfflineEarnings =
				math.floor(earningsPerSecond * offlineTime)
		end
	end

	local previousPending = data.PendingOfflineEarnings

	-- supports old saves where PendingOfflineEarnings was stored as a table.
	if typeof(previousPending) == "table" then
		previousPending = previousPending.Amount or 0
	end

	previousPending = tonumber(previousPending) or 0

	local totalPending = previousPending + newOfflineEarnings

	if totalPending > 0 then
		pendingOfflineEarnings[player] = {
			Amount = totalPending,
			Time = offlineTime,
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
		"LastLog:", data.LastLogout,
		"OfflineTeto:", data.OfflineTeto,
		"PendingOfflineEarnings:", previousPending
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

-- saving converts the current server state back into one datastore table.
-- the saving flag prevents two save requests for the same player from running at the same time.
local function saveData(player)
	if saving[player] or not dataLoaded[player] then
		return
	end

	saving[player] = true

	local pending = pendingOfflineEarnings[player]
	local pendingAmount = pending and pending.Amount or 0

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
		PendingOfflineEarnings = pendingAmount,
		CurrentSkin = player:GetAttribute("CurrentSkin") or DEFAULT_SKIN,
		LastLogout = os.time(),
		Skins = playerSkins[player] or {},
		Upgrades = playerUpgrades[player] or {},
	}

	local success, err = pcall(function()
		-- UpdateAsync writes the complete current snapshot through Roblox's datastore API.
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
			"RebirthPrice:", data.RebirthPrice,
			"Baguettes:", data.Baguettes,
			"AutoClicksPower:", data.AutoClicksPower,
			"AutoClicks:", data.AutoClicks,
			"Clicks:", data.Clicks,
			"PlayerClick:", data.PlayerClick,
			"CurrentSkin:", data.CurrentSkin,
			"LastLog:", data.LastLogout,
			"OfflineTeto:", data.OfflineTeto,
			"PendingOfflineEarnings:", data.PendingOfflineEarnings
		)
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
-- load player data as soon as he joins.
Players.PlayerAdded:Connect(function(player)
	loadData(player)

	-- check if the player chats "!reset" and if he's an admin.
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

			if targetPlayer == player
				and string.lower(username) ~= string.lower(player.Name) then
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

			local success = pcall(function()
				TeleportService:Teleport(
					game.PlaceId,
					targetPlayer
				)
			end)

			if not success and targetPlayer.Parent then
				targetPlayer:Kick(
					"Your data was reset, but the server transfer failed. Please rejoin."
				)
			end
		end
	end)
end)

-- PLAYER LEAVE
-- save the player data before clearing the temporary server tables.
Players.PlayerRemoving:Connect(function(player)
	if dataLoaded[player] then
		saveData(player)
	end

	playerSkins[player] = nil
	currentSkins[player] = nil
	playerUpgrades[player] = nil
	pendingOfflineEarnings[player] = nil
	dataLoaded[player] = nil
	saving[player] = nil
end)

-- SERVER SHUTDOWN
-- in case of shutdown save the data.
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		if dataLoaded[player] then
			saveData(player)
		end
	end
end)

-- ADD CLICK
-- add click on each AddClick event which is connected to an ImageButton.
AddClick.OnServerEvent:Connect(function(player)
	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local playerClick = player:GetAttribute("PlayerClick") or 1
	local amount = playerClick * getClickMultiplier(player)

	player:SetAttribute("Clicks", clicks + amount)
end)

-- AUTO CLICK
-- once autoclick is unlocked this makes the ImageButton generate clicks.
AutoClick.OnServerEvent:Connect(function(player)
	if not dataLoaded[player] then
		return
	end

	local autoClicks = player:GetAttribute("AutoClicks") or 0

	if autoClicks <= 0 then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local amount = autoClicks * getClickMultiplier(player)

	player:SetAttribute("Clicks", clicks + amount)
end)

-- ADD BAGUETTE
-- add a baguette when the player catches them.
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
-- buying a skin from the shop.
BuySkinEvent.OnServerEvent:Connect(function(player, clientPrice, skinName)
	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local skins = playerSkins[player]

	if not skins then
		return
	end

	local folder = ReplicatedStorage:FindFirstChild("Skins")
	local skin = folder and folder:FindFirstChild(skinName)

	if not skin or table.find(skins, skinName) then
		return
	end

	local priceValue = skin:FindFirstChild("Price")

	if not priceValue then
		warn("No Price found for skin:", skinName)
		return
	end

	local price = priceValue.Value

	if clientPrice ~= price then
		warn(player.Name .. " sent an invalid price for " .. skinName)
		return
	end

	if clicks < price then
		return
	end

	player:SetAttribute("Clicks", clicks - price)
	table.insert(skins, skinName)

	currentSkins[player] = skinName
	player:SetAttribute("CurrentSkin", skinName)
	BuySkinEvent:FireClient(player, skinName)
end)

-- RANDOM/REBIRTH SKIN
-- receiving a skin from the rebirth or random skin blind box.
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

	local priceValue = skin:FindFirstChild("Price")

	if not priceValue then
		warn("No Price found for skin:", skinName)
		return
	end

	local price = priceValue.Value

	if clientPrice ~= price then
		warn(player.Name .. " sent an invalid price for " .. skinName)
		return
	end

	if clicks < price then
		return
	end

	player:SetAttribute("Clicks", clicks - price)

	if not table.find(skins, skinName) then
		table.insert(skins, skinName)
	end

	currentSkins[player] = skinName
	player:SetAttribute("CurrentSkin", skinName)
	BuySkinEvent:FireClient(player, skinName)
end)

-- SECRET ADD SKIN
-- add the skin to the data before the player claims it so he will have it anyways if he leaves.
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

	-- save immediately so a disconnect during the claim animation cannot lose the reward.
	task.spawn(function()
		saveData(player)
	end)
end)

-- EQUIP SKIN
-- event to equip the skins.
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

	-- only skins already owned by the player can be equipped.
	if not table.find(skins, skinName) then
		return
	end

	currentSkins[player] = skinName
	player:SetAttribute("CurrentSkin", skinName)

	print(player.Name .. " equipped " .. skinName)
end)

-- GET SKIN DATA
-- get the player's skin data.
GetSkinData.OnServerInvoke = function(player)
	while not dataLoaded[player] and player.Parent do
		task.wait()
	end

	return playerSkins[player] or {}, currentSkins[player] or DEFAULT_SKIN
end

-- GET UPGRADE DATA
-- get the player's upgrades.
GetUpgradeData.OnServerInvoke = function(player)
	while not dataLoaded[player] and player.Parent do
		task.wait()
	end

	return playerUpgrades[player] or {}
end

-- APPLY UPGRADE
-- this function changes the actual gameplay value after the server validates the purchase.
local function applyUpgrade(player, upgradeName)
	if upgradeName == "+1 Teto" then
		player:SetAttribute(
			"PlayerClick",
			(player:GetAttribute("PlayerClick") or 1) + 1
		)

	elseif upgradeName == "+10 Teto" then
		player:SetAttribute(
			"PlayerClick",
			(player:GetAttribute("PlayerClick") or 1) + 10
		)

	elseif upgradeName == "Auto Teto" then
		player:SetAttribute(
			"AutoClicks",
			(player:GetAttribute("AutoClicks") or 0) + 1
		)

	elseif upgradeName == "+10 Auto Teto" then
		player:SetAttribute(
			"AutoClicks",
			(player:GetAttribute("AutoClicks") or 0) + 10
		)

	elseif upgradeName == "Auto Teto Power" then
		player:SetAttribute(
			"AutoClicksPower",
			(player:GetAttribute("AutoClicksPower") or 1) + 1
		)

	elseif upgradeName == "Auto Teto Speed" then
		local speed = player:GetAttribute("AutoTetoSpeed") or 1
		player:SetAttribute(
			"AutoTetoSpeed",
			math.max(0.05, speed - 0.05)
		)

	elseif upgradeName == "Unlock Baguettes" then
		local baguettes = player:GetAttribute("Baguettes")

		if baguettes == nil or baguettes < 0 then
			baguettes = 0
		end

		player:SetAttribute("Baguettes", baguettes + 1)

	elseif upgradeName == "Unlock Offline Teto" then
		player:SetAttribute("OfflineTeto", true)
	end
end

-- BUY UPGRADE
-- event to buy and save upgrades connected to buttons.
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

	-- search the player's existing records first so a purchase increases the saved upgrade instead of creating duplicates.
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
			Price = math.round(clientPrice),
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

	applyUpgrade(player, upgradeName)

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

-- REBIRTH
-- once the player can rebirth and presses the rebirth button, clear his data except for permanent upgrades, baguettes and skins.
RebirthEvent.OnServerEvent:Connect(function(player)
	if not dataLoaded[player] then
		return
	end

	local clicks = player:GetAttribute("Clicks") or 0
	local rebirthPrice = player:GetAttribute("RebirthPrice") or 500000

	if clicks < rebirthPrice then
		return
	end

	local oldClicks = clicks
	local clickReward = math.round(oldClicks * 0.2)
	local newRebirthPrice = math.floor(rebirthPrice * 1.3)

	-- reset temporary progression.
	player:SetAttribute("Clicks", clickReward)
	player:SetAttribute("PlayerClick", 1)
	player:SetAttribute("AutoClicks", 0)
	player:SetAttribute("AutoClicksPower", 1)
	player:SetAttribute("AutoTetoSpeed", 1)
	player:SetAttribute(
		"Rebirths",
		(player:GetAttribute("Rebirths") or 0) + 1
	)
	player:SetAttribute(
		"RebirthBoost",
		(player:GetAttribute("RebirthBoost") or 1) * 1.5
	)
	player:SetAttribute("RebirthPrice", newRebirthPrice)

	-- these names are the small set of upgrades that survive rebirth.
	local permanentUpgrades = {
		["Unlock Baguettes"] = true,
		["Unlock Offline Teto"] = true,
	}

	local preservedUpgrades = {}

	for _, upgradeData in ipairs(playerUpgrades[player] or {}) do
		if permanentUpgrades[upgradeData.Name]
			and upgradeData.Level >= 1 then

			table.insert(preservedUpgrades, {
				Name = upgradeData.Name,
				Level = upgradeData.Level,
				MaxLevel = upgradeData.MaxLevel,
				Price = upgradeData.Price,
			})
		end
	end

	playerUpgrades[player] = preservedUpgrades

	-- skins are intentionally untouched so every collected skin survives rebirth.
	saveData(player)

	RebirthEvent:FireClient(player, {
		RebirthPrice = newRebirthPrice,
		ResetUpgrades = true,
	})

	print(
		"REBIRTH:",
		player.Name,
		"| Old Clicks:", oldClicks,
		"| Reward:", clickReward,
		"| New Price:", newRebirthPrice,
		"| Rebirths:", player:GetAttribute("Rebirths"),
		"| Boost:", player:GetAttribute("RebirthBoost")
	)

	-- rebirth results.
	for _, upgradeData in ipairs(preservedUpgrades) do
		print(
			"KEPT UPGRADE:",
			upgradeData.Name,
			"Level:", upgradeData.Level
		)
	end
end)

-- RESET PLAYER DATA
-- this admin-only reset clears the datastore and immediately restores default runtime values.
function resetPlayerData(targetPlayer)
	if not targetPlayer then
		return false
	end

	local success, err = pcall(function()
		PlayerDataStore:RemoveAsync(targetPlayer.UserId)
	end)

	if not success then
		warn(
			"FAILED TO RESET DATA FOR "
				.. targetPlayer.Name
				.. ": "
				.. tostring(err)
		)
		return false
	end

	-- restore all default runtime values.
	local defaults = getDefaultData()

	for name, value in pairs(defaults) do
		if name ~= "Skins" and name ~= "Upgrades"
			and name ~= "PendingOfflineEarnings" then
			targetPlayer:SetAttribute(name, value)
		end
	end

	targetPlayer:SetAttribute("Multiplier", 1)

	playerSkins[targetPlayer] = {}
	currentSkins[targetPlayer] = DEFAULT_SKIN
	playerUpgrades[targetPlayer] = {}
	pendingOfflineEarnings[targetPlayer] = nil

	print("RESET DATA:", targetPlayer.Name)
	return true
end

-- TELEPORT FAILURE
-- if the teleport cannot be started, the player is kicked so they can rejoin and load the reset state.
TeleportService.TeleportInitFailed:Connect(function(player)
	if player.Parent then
		player:Kick(
			"Your data was reset, but the server transfer failed. Please rejoin."
		)
	end
end)

-- OFFLINE EARNINGS
-- this event is responsible for claiming the pending amount.
-- separating calculation from claiming prevents the same offline reward from being added twice.
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
