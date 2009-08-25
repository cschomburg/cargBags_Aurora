local PostUpdateButton = function(self, button, item)
	if(item.texture and item.count == 1 and item.bindOn == "equip") then
		button.Count:SetText("|cff00ff00BoE|r")
		button.Count:Show()
	end
	button.Icon:SetTexCoord(0.03, 0.98, 0.03, 0.98)
end

local UpdateDimensions = function(self, height)
	self:SetHeight(height + (self.Caption and 15 or 0))
	self.Parent:UpdateDimensions()
end

-- Function is called after a button was added to an object
-- Please note that the buttons are in most cases recycled and not new created
local PostCreateButton = function(self, button)
	button.NormalTexture:SetAlpha(0.5)
end

-- Style of the bag and its contents
cargBags:RegisterStyle("Aurora", function(self, text)
	self:EnableMouse(true)

	self.UpdateDimensions = UpdateDimensions
	self.PostUpdateButton = PostUpdateButton
	self.PostCreateButton = PostCreateButton

	self:SetWidth(1)
	self:SetHeight(1)

	-- The caption text
	if(text) then
		local caption = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		caption:SetText(text)
		caption:SetPoint("TOPLEFT")
		self.Caption = caption
		self.yOffset = -15
	end
end)

-- Localization
local L = {}
L.Weapon, L.Armor, L.Container, L.Consumable, L.Glyph, L.TradeGood,
L.Projectile, L.Quiver, L.Recipe, L.Gem, L.Misc, L.Quest = GetAuctionItemClasses()
L.SoulShard = GetItemInfo(6265)

-- Filter functions
--   As you can see, these functions get the same item-table seen at the top in UpdateButton(self, button, item)
--   Just check the properties you want to have and return true/false if the item belongs in this bag object
local INVERTED = -1 -- with inverted filters (using -1), everything goes into this bag when the filter returns false

local onlyBags = function(item) return item.bagID >= 0 and item.bagID <= 4 end
local onlyKeyring = function(item) return item.bagID == -2 end
local onlyBank = function(item) return item.bagID == -1 or item.bagID >= 5 and item.bagID <= 11 end
local onlyJunk = function(item) return item.rarity == 0 end
local onlyConsumables = function(item) return item.type == L.Consumable end
local onlyAmmo = function(item) return item.type == L.Projectile or (L.SoulShard and item.name == L.SoulShard) end
local onlyTradeGoods = function(item) return item.type == L.TradeGood end
local onlyRecipes = function(item) return item.type == L.Recipe end
local hideEmpty = function(item) return item.texture ~= nil end

local disable = function() return false end

-- Now we add the containers
--  cargBags:Spawn( name , parentFrame ) spawns the container with that name
--  object:SetFilter ( filterFunc, enabled ) adds a filter or disables one

-- Spawn the main aurora frame
local mainFrame = Aurora_Create_Frame("inventory", 8)
mainFrame:SetPoint("RIGHT", 0, -5)
-- Add the tab groups to it
local mainBag = mainFrame:CreateGroup("Main")
local tradeBag = mainFrame:CreateGroup("Trade")
local otherBag = mainFrame:CreateGroup("Other")
local aioBag = mainFrame:CreateGroup("All")

-- And the same with the bank frame
local bankFrame = Aurora_Create_Frame("bank", 12)
bankFrame:SetPoint("LEFT", 0, 5)
local bankBag = bankFrame:CreateGroup("Bank")

-- All in one
local aio = cargBags:Spawn("cBags_AIO")
	aio:SetFilter(onlyBags, true)
	aio:SetFilter(disable, true)
	aioBag:AddFrame(aio)

aioBag.OnEnable = function() aio:SetFilter(disable, false) end
aioBag.OnDisable = function() aio:SetFilter(disable, true) end

-- Tradegoods
local trade = cargBags:Spawn("cBags_Trade", "Tradegoods")
	trade:SetFilter(onlyTradeGoods, true)
	trade:SetFilter(onlyBags, true)
	tradeBag:AddFrame(trade)

-- Recipes
local recipe = cargBags:Spawn("cBags_Recipe", "Recipes")
	recipe:SetFilter(onlyRecipes, true)
	recipe:SetFilter(onlyBags, true)
	tradeBag:AddFrame(recipe)

-- Ammo
local ammo = cargBags:Spawn("cBags_Ammo", "Ammo")
	ammo:SetFilter(onlyAmmo, true)
	ammo:SetFilter(onlyBags, true)
	otherBag:AddFrame(ammo)

-- Keyring
local key = cargBags:Spawn("cBags_Key", "Keys")
	key:SetFilter(onlyKeyring, true)
	key:SetFilter(hideEmpty, true)
	otherBag:AddFrame(key)

-- Junk
local junk = cargBags:Spawn("cBags_Junk", "Junk")
	junk:SetFilter(onlyJunk, true)
	junk:SetFilter(onlyBags, true)
	otherBag:AddFrame(junk)

-- Consumables
local cons = cargBags:Spawn("cBags_Consumables", "Consumables")
	cons:SetFilter(onlyBags, true)
	cons:SetFilter(onlyConsumables, true)
	mainBag:AddFrame(cons)

local main 	= cargBags:Spawn("cBags_Main", "Main")
	main:SetFilter(onlyBags, true)
	main:SetFilter(hideEmpty, true)
	mainBag:AddFrame(main)

-- Bank frame and bank bags
local bank = cargBags:Spawn("cBags_Bank")
	bank:SetFilter(onlyBank, true)
	bankBag:AddFrame(bank)

-- Opening / Closing Functions
function OpenCargBags()
	mainFrame:Show()
end

function CloseCargBags()
	mainFrame:Hide()
	bankFrame:Hide()
end

function ToggleCargBags(forceopen)
	if(mainFrame:IsShown() and not forceopen) then CloseCargBags() else OpenCargBags() end
end

-- To toggle containers when entering / leaving a bank
local bankToggle = CreateFrame"Frame"
bankToggle:RegisterEvent"BANKFRAME_OPENED"
bankToggle:RegisterEvent"BANKFRAME_CLOSED"
bankToggle:SetScript("OnEvent", function(self, event)
	if(event == "BANKFRAME_OPENED") then
		bankFrame:Show()
	else
		bankFrame:Hide()
	end
end)

-- Close real bank frame when our bank frame is hidden
bank:SetScript("OnHide", CloseBankFrame)

-- Hide the original bank frame
BankFrame:UnregisterAllEvents()

-- Blizzard Replacement Functions
ToggleBackpack = ToggleCargBags
ToggleBag = function() ToggleCargBags() end
OpenAllBags = ToggleBag
CloseAllBags = CloseCargBags
OpenBackpack = OpenCargBags
CloseBackpack = CloseCargBags

-- Set cargBags_Anywhere as default handler when used
if(cargBags.Handler["Anywhere"]) then
	cargBags:SetActiveHandler("Anywhere")
end