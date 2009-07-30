local DATABROKER_ADDON = "CurrencyTracker"

-- Some custom buttons at the bottom
local buttonEnter = function(self)
	if(not self.Tip) then return end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(self.Tip)
	GameTooltip:Show()
end
local buttonLeave = function() GameTooltip:Hide() end

local function createSmallButton(name, parent, ...)
	local button = CreateFrame("Button", nil, parent)
	button:SetPoint(...)
	button:SetNormalFontObject(GameFontHighlight)
	button:SetText(name)
	button:SetPoint"CENTER"
	button:SetWidth(20)
	button:SetHeight(20)
	button:SetScript("OnEnter", buttonEnter)
	button:SetScript("OnLeave", buttonLeave)
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	button:SetBackdropColor(0, 0, 0, 1)
	button:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)
	return button
end

-- Update the size of a bag group by getting the
-- height of all contained bags and
-- position them
local function UpdateDimensions(self, anchor)
	local height = 0
	local spacing = 8
	local prev
	for i, frame in pairs(self.Frames) do
		if(i > 1) then height = height + spacing end
		if(anchor) then
			frame:ClearAllPoints()
			if(prev) then
				frame:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -spacing)
			else
				frame:SetPoint("TOPLEFT")
			end
			prev = frame
		end
		height = height + frame:GetHeight() * frame:GetScale() + spacing
	end
	self:SetHeight(height)
	if(self.Parent.Active == self) then
		self.Parent:UpdateDimensions()
	end
end

-- Adds a sub bag to the group
local function AddFrame(self, frame, pos)
	if(pos) then
		tinsert(self.Frames, pos, frame)
	else
		tinsert(self.Frames, frame)
	end
	frame.MainFrame = self.Parent
	frame:SetParent(self)
	frame:SetWidth(self.Parent:GetWidth())
	frame.Parent = self
	self:UpdateDimensions(true)
end

-- The animations system
local f = CreateFrame"Frame"
local function OnShow(self)
	self:SetAlpha(0)
	self.Fade.min = 0
	self.Fade.max = 1
	self.Fade:Play()
	f.Show(self)
end
local function OnHide(self)
	self:SetAlpha(1)
	self.Fade.min = 1
	self.Fade.max = 0
	self.Fade:Play()
end

local function OnUpdate(self)
	self.Parent:SetAlpha(self.min + (self.max - self.min) * self:GetProgress())
end
local function OnFinished(self)
	if(self.max == 0) then f.Hide(self.Parent) end
end


-- PARENT MAINFRAME
local function TabOnClick(self)
	local parent = self.Parent
	local group = self.Group

	if(parent.Active) then
		if(parent.Active.OnDisable) then parent.Active:OnDisable() end
		parent.Active:Hide()
		parent.Active.Tab:SetAlpha(0.5)
	end
	if(group.OnEnable) then group:OnEnable() end
	group:Show()
	self:SetAlpha(1)
	parent.Active = group
	parent:UpdateDimensions()
end

-- Creates a bag group with tabs
local function createGroup(self, name)
	self.Groups = self.Groups or {}
	local groups = self.Groups

	local group = CreateFrame("Frame", nil, self)
	group.UpdateDimensions = UpdateDimensions
	group.AddFrame = AddFrame
	group.RemoveFrame = RemoveFrame
	group:Hide()
	group:SetPoint("TOPLEFT", 0, -(self.Top or 0))
	group:SetPoint("TOPRIGHT", 0, -(self.Top or 0))
	group.Frames = {}
	group.Parent = self

	groups[#groups+1] = group

	local tab = CreateFrame("Button", nil, self)
	tab.Group = group
	tab.Parent = self
	tab:SetBackdrop{
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	}
	tab:SetBackdropColor(0, 0, 0, 0.8)
	tab:SetBackdropBorderColor(0, 0, 0, 0.5)
	tab:SetNormalFontObject(GameFontHighlightSmall)
	tab:SetText(name)
	tab:SetHeight(24)
	tab:SetWidth(70)
	tab:SetAlpha(0.5)
	tab:SetScript("OnClick", TabOnClick)
	if(self.PrevTab) then
		tab:SetPoint("LEFT", self.PrevTab, "RIGHT", 5, 0)
	else
		tab:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 20, 0)
	end
	self.PrevTab = tab
	group.Tab = tab

	if(#groups == 1) then TabOnClick(tab) end

	return group
end

-- Update the mainframe's dimensions based on the size
-- of the active bag group
local function ParentUpdateDimensions(self)
	self:SetHeight((self.Top or 0) + (self.Bottom or 0) + self.Active:GetHeight())
end

local num = 1
-- Create a mainframe and its plugins
function Aurora_Create_Frame(frameType, columns)
	local name = "Aurora"..num
	num = num + 1

	local self = CreateFrame("Button", name, UIParent)
	self.SpawnPlugin = cargBags.SpawnPlugin
	self.CreateGroup = createGroup
	self.UpdateDimensions = ParentUpdateDimensions

	self:Hide()

	local anim = self:CreateAnimationGroup()
	local fade = anim:CreateAnimation("Animation")
	fade:SetDuration(.125)
	fade:SetSmoothing("IN_OUT")
	fade.Parent = self
	fade:SetScript("OnUpdate", OnUpdate)
	fade:SetScript("OnFinished", OnFinished)
	self.Show = OnShow
	self.Hide = OnHide
	self.Fade = fade
	self.Name = name

	self.Top = 33
	self.Bottom = 25

	self:SetMovable(true)
	self:RegisterForClicks("LeftButton", "RightButton")
	self:SetScript("OnMouseDown", function() 
		if(IsAltKeyDown()) then 
			self:ClearAllPoints() 
			self:StartMoving() 
		end
	end)
	self:SetScript("OnMouseUp",  self.StopMovingOrSizing)
	self:SetFrameStrata("HIGH")

	self.Columns = columns
	self:SetWidth(columns*38+20)

	-- close button
	local close = CreateFrame("Button", nil, self, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 5, 8)
	close:SetScript("OnClick", function(self) self:GetParent():Hide() end)
	close:GetNormalTexture():SetDesaturated(1)

	-- And the frame background!
	local background = CreateFrame("Frame", nil, self)
	background:SetBackdrop{
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	}
	background:SetFrameStrata("HIGH")
	background:SetFrameLevel(1)
	background:SetBackdropColor(0, 0, 0, 0.8)
	background:SetBackdropBorderColor(0, 0, 0, 0.5)

	background:SetPoint("TOPLEFT", -6, 6)
	background:SetPoint("BOTTOMRIGHT", 6, -6)

	-- The frame for money display
	local money = self:SpawnPlugin("Money")
	if(money) then
		money:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 5)
	end

	-- The font string for bag space display
	-- You can see, it works with tags, - [free], [max], [used] are currently supported
	local bagType
	if(frameType == "inventory") then
		bagType = "backpack+bags"	-- We want to add all bags and the backpack to our space display
	else
		bagType = "bankframe+bank"	-- the bank gets bank bags, of course
	end
	local space = self:SpawnPlugin("Space", "[free]", bagType)
	if(space) then
		space:SetPoint("TOPLEFT", 5, -5)
		space:SetJustifyH"LEFT"
		space:SetFont("Fonts\\FRIZQT__.TTF", 20)

		local text = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetPoint("TOPLEFT", space, "TOPRIGHT", 2, 0)
		text:SetText("free")
	end


	-- This is the space status bar
	-- First we create a frame and then spawn a plugin from it, so
	-- it connects with the space update function
	local spaceBackground = CreateFrame("StatusBar", nil, self)
	if(spaceBackground) then
		spaceBackground:SetAlpha(0.6)
		spaceBackground:SetPoint("TOPLEFT", space, "TOPRIGHT", 40, 8)
		spaceBackground:SetWidth(80)
		spaceBackground:SetHeight(80*0.35)
		spaceBackground:SetStatusBarTexture("Interface\\AddOns\\cargBags_Aurora\\progressbar")
		spaceBackground:SetBackdrop{
			bgFile = "Interface\\AddOns\\cargBags_Aurora\\progressbar",
		}
		spaceBackground:SetBackdropColor(1, 1, 1, .2)

		-- Connecting with the space plugin,
		-- updating is done via UpdateText() callback
		self:SpawnPlugin("Space", spaceBackground, bagType)
		spaceBackground.UpdateText = function(self, free, max)
			self:SetMinMaxValues(0, max)
			self:SetValue(max-free, max)
		end
	end

	-- A nice bag bar for changing/toggling bags
	local bagType
	if(frameType == "inventory") then
		bagType = "bags"	-- We want to add all bags to our bag button bar
	else
		bagType = "bank"	-- the bank gets bank bags, of course
	end
	local bagButtons = self:SpawnPlugin("BagBar", bagType)
	if(bagButtons) then
		bagButtons:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 24)
		bagButtons:Hide()
	end

	-- We don't need the bag bar every time, so let's create a toggle button for them to show
	local bagToggle = createSmallButton("B", self, "BOTTOMLEFT")
	bagToggle.Object = self
	bagToggle:SetScript("OnClick", function()
		ToggleFrame(self.BagBar)
		self.Bottom = 25 + (self.BagBar:IsShown() and 40 or 0)
		self:UpdateDimensions()	-- The bag buttons take space, so let's update the height of the frame
	end)
	bagToggle.Tip = "Toggle bag bar"

	if(frameType == "inventory") then
		-- The button for viewing other characters' bags
		local anywhere = self:SpawnPlugin("Anywhere")
		local bankToggle
		if(anywhere) then
			anywhere:SetPoint("TOPRIGHT", -19, 4)
			anywhere:GetNormalTexture():SetDesaturated(1)

			-- If Anywhere exists, we place a button for toggling the bank
			bankToggle = createSmallButton("B", self, "BOTTOMLEFT", 25, 0)
			bankToggle:SetScript("OnClick", function(self) ToggleFrame(Aurora2) end)
			bankToggle.Tip = "Toggle bank frame"
		end

		-- Display a databroker object on the main inventory frame
		local databroker = DATABROKER_ADDON and self:SpawnPlugin("DataBroker", DATABROKER_ADDON, {
			noIcon = true,
			fontObject = "NumberFontNormal",
		})
		if(databroker) then
			databroker:SetPoint("LEFT", bankToggle or bagToggle, "RIGHT", 10, 0)
		end
	else
		local purchase = self:SpawnPlugin("Purchase")
		if(purchase) then
			purchase:SetText(BANKSLOTPURCHASE)
			purchase:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 20)
			if(self.BagBar) then purchase:SetParent(self.BagBar) end

			purchase.Cost = self:SpawnPlugin("Money", "static")
			purchase.Cost:SetParent(purchase)
			purchase.Cost:SetPoint("BOTTOMRIGHT", purchase, "TOPRIGHT", 0, 2)
		end
	end

	return self
end