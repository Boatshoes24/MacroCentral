local MyAddon, _ = ...
local _G = _G
local LibStub = LibStub
local AceGUI = LibStub("AceGUI-3.0")
local tabText = {}
local specs = nil
local window = nil
local tabGroup = nil
local isWindowOpen = false
local macroStart = 121
local macroEnd = 138
local playerClass = nil
local testTable = {}
local macroIconTable = {}
local tinsert = table.insert
local currentSpec = nil
local specIndex = 0
local update = false
-- local iconLib = LibStub("LibIconPath")

local macroName = macroName
local macroBody = macroBody
local macroIcon = macroIcon
local macroIndex = macroIndex


local MAC = LibStub("AceAddon-3.0"):NewAddon("MacroCentral", "AceEvent-3.0", "AceConsole-3.0")

-- _G.MacroCentral = MAC

local defaults = {
	["global"] = {
		
	},
}

local anchorFrame = CreateFrame("Frame")

function MAC:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("MacroCentralDB", defaults, true)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
end

function MAC:CreateMACButton()
	anchorFrame.button = CreateFrame("Button", nil, MacroFrame, "UIPanelButtonTemplate")
	anchorFrame.button:SetPoint("TOP", MacroFrame, "BOTTOM", 0, 1)
	anchorFrame.button:SetHeight(35)
	anchorFrame.button:SetWidth(MacroFrame:GetWidth())
	anchorFrame.button:SetText("Save "..currentSpec.." Macros")
	anchorFrame.button:SetScript('OnClick', function() 
		currentSpec = select(2, GetSpecializationInfo(GetSpecialization()))
		self:RefreshSpecDB(currentSpec)
		self:Print(currentSpec.." macros saved")
	end)

 	return button
end

function MAC:RefreshSpecDB(spec)
	if playerClass ~= nil and currentSpec ~= nil then
		for i = macroStart, macroEnd do
			macroName, macroIcon, macroBody = GetMacroInfo(i)
			if macroIcon == 134400 then macroIcon = "INV_Misc_QuestionMark" end
			self.db.global[playerClass][spec][i]["name"] = nil
			self.db.global[playerClass][spec][i]["icon"] = nil
			self.db.global[playerClass][spec][i]["body"] = nil
			self.db.global[playerClass][spec][i]["slot"] = {}
			if macroName then				
				self.db.global[playerClass][spec][i]["name"] = macroName
				self.db.global[playerClass][spec][i]["icon"] = macroIcon
				self.db.global[playerClass][spec][i]["body"] = macroBody or ""
			end
		end
		self:SaveActionSlots(spec)
	end
	--self:Print(spec.." macros saved")	
end

function MAC:LoadSpecMacros(spec)
	if playerClass ~= nil and currentSpec ~= nil then
		for i = macroEnd, macroStart, -1 do
			DeleteMacro(i)
		end
		for i = macroStart, macroEnd do
			if self.db.global[playerClass][spec][i]["name"] ~= nil then
				CreateMacro(self.db.global[playerClass][spec][i]["name"], self.db.global[playerClass][spec][i]["icon"], self.db.global[playerClass][spec][i]["body"], 1)
				if self.db.global[playerClass][spec][i]["slot"] ~= nil then
					for k, v in pairs(self.db.global[playerClass][spec][i]["slot"]) do
						PickupMacro(self.db.global[playerClass][spec][i]["name"])
						PlaceAction(v)
					end
				end
			end
		end
		if IsAddOnLoaded("Blizzard_MacroUI") then
			if MacroFrame:IsShown() then
				MacroFrame_Update()
			end
		end
		self:Print(spec.." macros loaded")
		--self:SaveActionSlots(spec)
	end	
end

function MAC:InitialSetup()
	if playerClass ~= nil and currentSpec ~= nil then
		self.db.global[playerClass] = self.db.global[playerClass] or {}
		for i = 1, GetNumSpecializations() do
			currentSpec = select(2, GetSpecializationInfo(i))
			if not self.db.global[playerClass][currentSpec] then
				self.db.global[playerClass][currentSpec] = self.db.global[playerClass][currentSpec] or {}
				for j = macroStart, macroEnd do
					if not self.db.global[playerClass][currentSpec][j] then
						self.db.global[playerClass][currentSpec][j] = self.db.global[playerClass][currentSpec][j] or {}
					end
					if GetMacroInfo(j) ~= nil then
						macroName, macroIcon, macroBody = GetMacroInfo(j)
						if macroIcon == 134400 then macroIcon = "INV_Misc_QuestionMark" end
						self.db.global[playerClass][currentSpec][j]["name"] = macroName
						self.db.global[playerClass][currentSpec][j]["icon"] = macroIcon
						self.db.global[playerClass][currentSpec][j]["body"] = macroBody or ""
						self.db.global[playerClass][currentSpec][j]["slot"] = {}
					end
				end
			end
		end
		self:Print("Initial setup for "..playerClass.." complete")
	end
	currentSpec = select(2, GetSpecializationInfo(GetSpecialization()))
	self:SaveActionSlots(currentSpec)
end

function MAC:SaveActionSlots(spec)
	if playerClass ~= nil and spec ~= nil then
		for i = macroEnd, macroStart, -1 do
			self.db.global[playerClass][spec][i]["slot"] = {}
			if self.db.global[playerClass][spec][i]["name"] ~= nil then 
				for j = 1, 120 do
					barName = GetActionText(j)
					barIndex = select(2, GetActionInfo(j))
					if self.db.global[playerClass][currentSpec][i]["name"] == barName then
						tinsert(self.db.global[playerClass][spec][i]["slot"], j)
					end
				end
			end
		end
	end
end

function MAC:ADDON_LOADED(event, addon)
	if addon == "Blizzard_MacroUI" then
		self.macButton = self:CreateMACButton()	
	end
end

function MAC:UNIT_SPELLCAST_START(event, unit, castID, spellID)
	if unit == "player" and spellID == 200749 then
		currentSpec = select(2, GetSpecializationInfo(GetSpecialization()))
		self:RefreshSpecDB(currentSpec)
		self:Print(currentSpec.." macros saved")
	end
end

function MAC:UNIT_SPELLCAST_SUCCEEDED(event, unit, castID, spellID)
	if unit == "player" and spellID == 200749 then
		currentSpec = select(2, GetSpecializationInfo(GetSpecialization()))
		self:LoadSpecMacros(currentSpec)
		if anchorFrame.button then
			anchorFrame.button:SetText("Save "..currentSpec.." Macros")
		end
	end
end

function MAC:PLAYER_ENTERING_WORLD(event, login, reload)
	if login or reload then
		playerClass = select(2, UnitClass("player"))
		currentSpec = select(2, GetSpecializationInfo(GetSpecialization()))
		if not self.db.global[playerClass] then
			self:InitialSetup()
		else
			if playerClass ~= nil and currentSpec ~= nil then
				--self:RefreshSpecDB(currentSpec)
				--self:LoadSpecMacros(currentSpec)
				self:Print(currentSpec.." macros loaded")
			end
		end
	end
end

function MAC:PLAYER_LEAVING_WORLD()
	self:RefreshSpecDB(currentSpec)
end