-- Config.lua: Localization, settings panel, initialization, and all module logic for GPlater addon

----------------------------------------
-- Localization
----------------------------------------
L = {}

local locale = GetLocale()

-- English (enUS) - default
L["enUS"] = {
    ["SETTINGS_PANEL_TITLE"] = "GPlater %s",
    ["ADDON_VERSION"] = "2.0.4",
    ["GENERAL_TAB"] = "General",
    ["FRIENDLY_NAMEPLATES_TAB"] = "Friendly Nameplates",
    ["AURA_COLORING_TAB"] = "Aura Coloring",
    ["CAST_HANDLING_TAB"] = "Cast Handling",
    ["PLATER_NOT_LOADED"] = "Plater is not loaded. GPlater requires Plater to function.",
    ["WELCOME_MESSAGE"] = "Welcome to GPlater settings. Select a tab to configure specific modules.",
    ["MODULE_LOAD_ERROR"] = "Module %s failed to load: %s",
    ["FONT_SIZE"] = "Font Size",
    ["FRIENDLY_NAMEPLATE_WIDTH"] = "Nameplate Width",
    ["NAMEPLATE_VERTICAL_SCALE"] = "Vertical Scale",
    ["ENABLE_FRIENDLY_CLICK_THROUGH"] = "Enable Click-Through",
    ["HIDE_FRIENDLY_BUFFS"] = "Hide Friendly Buffs",
    ["SHOW_FRIENDLY_NPCS"] = "Show Friendly NPCs",
    ["SHOW_ONLY_FRIENDLY_NAMES"] = "Show Only Names",
    ["ENABLE_AURA_COLORING"] = "Enable Aura Coloring",
    ["USE_IN_PVP"] = "Use in PvP",
    ["USE_RAID_MARKS"] = "Use Raid Marks",
    ["RESET_AT_30_PERCENT"] = "Reset at 30% Duration",
    ["AURA_ID"] = "Aura ID",
    ["SPELL_NAME"] = "Spell Name",
    ["AURA_NAME"] = "Aura Name",
    ["STACKS"] = "Stacks",
    ["NAME_TEXT"] = "Name Text",
    ["NAMEPLATE"] = "Nameplate",
    ["BORDER"] = "Border",
    ["FLASH"] = "Flash",
    ["DELETE"] = "Delete",
    ["ADD_AURA"] = "Add Aura",
    ["STACKS_NOT_CHECKED"] = "Not Checked",
    ["ENABLE_CAST_HANDLING"] = "Enable Cast Handling",
    ["SPELL_ID"] = "Spell ID",
    ["SPECIAL_ATTENTION"] = "Special Attention",
    ["TOP_PRIORITY"] = "Top Priority",
    ["ADD_SPELL"] = "Add Spell",
    ["ALWAYS_SHOW_TARGET_UNIT"] = "Always Show Target Unit",
    ["ALWAYS_SHOW_MARKED_UNITS"] = "Always Show Marked Units",
    ["RESET_TO_DEFAULTS"] = "Reset to Defaults",
    ["INVALID_SPELL_ID"] = "Invalid spell ID(s) entered: %s. Please check the ID(s)."
}

-- Chinese (zhCN)
L["zhCN"] = {
    ["SETTINGS_PANEL_TITLE"] = "GPlater %s",
    ["ADDON_VERSION"] = "2.0.4",
    ["GENERAL_TAB"] = "通用设置",
    ["FRIENDLY_NAMEPLATES_TAB"] = "友好姓名板",
    ["AURA_COLORING_TAB"] = "光环着色",
    ["CAST_HANDLING_TAB"] = "施法处理",
    ["PLATER_NOT_LOADED"] = "未加载 Plater。GPlater 需要 Plater 才能运行。",
    ["WELCOME_MESSAGE"] = "欢迎使用 GPlater 设置。选择一个选项卡以配置特定模块。",
    ["MODULE_LOAD_ERROR"] = "模块 %s 加载失败：%s",
    ["FONT_SIZE"] = "字体大小",
    ["FRIENDLY_NAMEPLATE_WIDTH"] = "姓名板宽度",
    ["NAMEPLATE_VERTICAL_SCALE"] = "垂直缩放",
    ["ENABLE_FRIENDLY_CLICK_THROUGH"] = "启用点击穿透",
    ["HIDE_FRIENDLY_BUFFS"] = "隐藏友好增益",
    ["SHOW_FRIENDLY_NPCS"] = "显示友好 NPC",
    ["SHOW_ONLY_FRIENDLY_NAMES"] = "仅显示名称",
    ["ENABLE_AURA_COLORING"] = "启用光环着色",
    ["USE_IN_PVP"] = "在 PvP 中使用",
    ["USE_RAID_MARKS"] = "使用团队标记",
    ["RESET_AT_30_PERCENT"] = "在 30% 持续时间重置",
    ["AURA_ID"] = "光环 ID",
    ["SPELL_NAME"] = "法术名称",
    ["AURA_NAME"] = "光环名称",
    ["STACKS"] = "层数",
    ["NAME_TEXT"] = "名称文本",
    ["NAMEPLATE"] = "姓名板",
    ["BORDER"] = "边框",
    ["FLASH"] = "闪光",
    ["DELETE"] = "删除",
    ["ADD_AURA"] = "添加光环",
    ["STACKS_NOT_CHECKED"] = "未检查",
    ["ENABLE_CAST_HANDLING"] = "启用施法处理",
    ["SPELL_ID"] = "技能 ID",
    ["SPECIAL_ATTENTION"] = "特别关注",
    ["TOP_PRIORITY"] = "最高优先级",
    ["ADD_SPELL"] = "添加技能",
    ["ALWAYS_SHOW_TARGET_UNIT"] = "始终显示目标单位",
    ["ALWAYS_SHOW_MARKED_UNITS"] = "始终显示标记单位",
    ["RESET_TO_DEFAULTS"] = "重置为默认值",
    ["INVALID_SPELL_ID"] = "无效的技能ID：%s，请检查ID。"
}

-- If language is not defined, use English
if not L[locale] then
    L[locale] = L["enUS"]
end

-- Validate localization keys
for key, value in pairs(L["enUS"]) do
    if L[locale][key] == nil then
        L[locale][key] = value
    end
end

local GPlaterL = L[locale]

----------------------------------------
-- Initialization and Database Setup
----------------------------------------
GPlaterDB = GPlaterDB or {}
local PLAYER_CLASS = select(2, UnitClass("player")) or "UNKNOWN"

-- Consolidated initialization for all modules
local function InitializeDatabase()
    -- Friendly Nameplates defaults
    local friendlyDefaults = {
        H = 1.0, -- NamePlateVerticalScale
        Hbase = 0, -- Base height offset
        OverlapV = 0.8, -- Vertical overlap
        Size = 10, -- Font size
        Friendly = {
            Width = 100, -- Unified friendly nameplate width
            distance = 20, -- Distance/height
            FriendlyClickThrough = 0, -- 0 = disabled, 1 = enabled
            HFB = false, -- Hide friendly buffs
            ShowFriendlyNPCs = 1, -- Show friendly NPCs (1 = show, 0 = hide)
            ShowOnlyFriendNames = 0, -- Show only friendly names (1 = enabled, 0 = disabled)
        }
    }

    -- Aura Coloring defaults
    local auraDefaults = {
        UseInPvP = true,
        EnableAuraColoring = true,
        UseRaidMarks = false,
        ResetAt30Percent = false,
        ColorByMark = {
            [1] = "#ffd700", -- Star (gold)
            [2] = "#ff8c00", -- Circle (darkorange)
            [3] = "#9932cc", -- Diamond (darkorchid)
            [4] = "#228b22", -- Triangle (forestgreen)
            [5] = "#add8e6", -- Moon (lightblue)
            [6] = "#191970", -- Square (midnightblue)
            [7] = "#800000", -- Cross (maroon)
            [8] = "#f8f8ff"  -- Skull (ghostwhite)
        },
        BuffsToMatch = {
            { auras = {980, 146739, 316099}, nameTextColor = "#780095", nameplateColor = "#780095", borderColor = "#780095", flash = false, hideNameplate = false },
            { auras = {445474}, nameTextColor = "#ff2217", nameplateColor = "#ff144c", borderColor = "#44ff7c", flash = false, hideNameplate = false }
        },
        FilteredBuffsToMatch = {},
        DefaultTextColors = {}
    }

    -- Cast Handling defaults
    local castDefaults = {
        EnableCastHandling = true,
        SpellsToMonitor = {
            { spellID = 2060, specialAttention = true, topPriority = false }, -- Heal (Priest)
            { spellID = 116, specialAttention = false, topPriority = true }   -- Frostbolt (Mage)
        },
        _ConcernedNum = 0,
        topPriorityUnits = {},
        castCounter = 0,
        unitKeys = {},
        pendingFrameLevels = {},
        config = {
            showOnTargeting = true,
            showOnMark = true
        }
    }

    -- Initialize database with defaults if not set
    GPlaterDB.Friendly = GPlaterDB.Friendly or {}
    for k, v in pairs(friendlyDefaults) do
        GPlaterDB.Friendly[k] = GPlaterDB.Friendly[k] or v
    end

    GPlaterDB.AuraColoring = GPlaterDB.AuraColoring or {}
    for k, v in pairs(auraDefaults) do
        GPlaterDB.AuraColoring[k] = GPlaterDB.AuraColoring[k] or v
    end

    GPlaterDB.CastHandling = GPlaterDB.CastHandling or {}
    for k, v in pairs(castDefaults) do
        GPlaterDB.CastHandling[k] = GPlaterDB.CastHandling[k] or v
    end

    -- Initialize last selected tab
    GPlaterDB.lastSelectedTab = GPlaterDB.lastSelectedTab or "Aura Coloring"
end

----------------------------------------
-- Friendly Nameplates Module
----------------------------------------

-- Utility function to set font
local function SetFont(obj, optSize)
    if not obj or not obj:IsObjectType("FontString") then return end
    local fontName, _, fontFlags = obj:GetFont()
    obj:SetFont(fontName or "Fonts\\FRIZQT__.TTF", optSize, "OUTLINE")
    obj:SetShadowOffset(0, 0)
end

-- Function to update nameplate fonts
local function UpdateFont(s)
    local size = s or GPlaterDB.Friendly.Size or 10
    SetFont(SystemFont_LargeNamePlate, size)
    SetFont(SystemFont_LargeNamePlateFixed, size)
    SetFont(SystemFont_NamePlate, size)
    SetFont(SystemFont_NamePlateFixed, size)
    SetFont(SystemFont_NamePlateCastBar, math.max(size - 2, 1))
end

-- Function to update nameplate sizes
local function UpdateFriendlyNameplatesSize()
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "party" or instanceType == "raid") and not InCombatLockdown() then
        local width = GPlaterDB.Friendly.Friendly.Width or 100
        local clickThrough = GPlaterDB.Friendly.Friendly.FriendlyClickThrough == 1
        C_NamePlate.SetNamePlateFriendlyClickThrough(clickThrough)
        C_NamePlate.SetNamePlateFriendlySize(width, clickThrough and GPlaterDB.Friendly.Friendly.distance or (GPlaterDB.Friendly.H * 12 + GPlaterDB.Friendly.Hbase))
    end
end

-- Function to apply settings
local function UpdateFriendlyNameplates()
    local inInstance, instanceType = IsInInstance()
    if not (inInstance and (instanceType == "party" or instanceType == "raid")) then return end

    if InCombatLockdown() then
        GPlaterDB.Friendly.updateCV = true
        return
    end

    SetCVar("NamePlateVerticalScale", GPlaterDB.Friendly.H or 1.0)
    SetCVar("nameplateOverlapV", GPlaterDB.Friendly.OverlapV or 0.8)
    SetCVar("nameplateShowFriendlyNPCs", GPlaterDB.Friendly.Friendly.ShowFriendlyNPCs or 1)
    SetCVar("nameplateShowOnlyNames", GPlaterDB.Friendly.Friendly.ShowOnlyFriendNames or 0)
    SetCVar("nameplateShowFriendlyBuffs", GPlaterDB.Friendly.Friendly.HFB and 0 or 1)
    SetCVar("nameplateShowDebuffsOnFriendly", GPlaterDB.Friendly.Friendly.HFB and 0 or 1)
    UpdateFont()
    UpdateFriendlyNameplatesSize()
end

-- Create Friendly Nameplates content
local function CreateFriendlyNameplatesContent(parent)
    if not parent then return CreateFrame("Frame", nil, UIParent) end

    local contentFrame = CreateFrame("Frame", nil, parent)
    contentFrame:SetSize(740, 350)

    -- Font Size Slider
    local fontSlider = CreateFrame("Slider", nil, contentFrame, "OptionsSliderTemplate")
    fontSlider:SetPoint("TOPLEFT", 10, -20)
    fontSlider:SetWidth(360)
    fontSlider:SetMinMaxValues(6, 20)
    fontSlider:SetValueStep(1)
    fontSlider:SetObeyStepOnDrag(true)
    fontSlider.Text:SetText(GPlaterL["FONT_SIZE"])
    fontSlider.Low:SetText("6")
    fontSlider.High:SetText("20")
    fontSlider:SetValue(GPlaterDB.Friendly.Size or 10)
    fontSlider:SetScript("OnValueChanged", function(self, value)
        GPlaterDB.Friendly.Size = value
        UpdateFont(value)
    end)

    -- Width Slider
    local widthSlider = CreateFrame("Slider", nil, contentFrame, "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", 10, -80)
    widthSlider:SetWidth(360)
    widthSlider:SetMinMaxValues(50, 200)
    widthSlider:SetValueStep(1)
    widthSlider:SetObeyStepOnDrag(true)
    widthSlider.Text:SetText(GPlaterL["FRIENDLY_NAMEPLATE_WIDTH"])
    widthSlider.Low:SetText("50")
    widthSlider.High:SetText("200")
    widthSlider:SetValue(GPlaterDB.Friendly.Friendly.Width or 100)
    widthSlider:SetScript("OnValueChanged", function(self, value)
        GPlaterDB.Friendly.Friendly.Width = value
        UpdateFriendlyNameplatesSize()
    end)

    -- Vertical Scale Slider
    local verticalScaleSlider = CreateFrame("Slider", nil, contentFrame, "OptionsSliderTemplate")
    verticalScaleSlider:SetPoint("TOPLEFT", 10, -140)
    verticalScaleSlider:SetWidth(360)
    verticalScaleSlider:SetMinMaxValues(0.5, 2.0)
    verticalScaleSlider:SetValueStep(0.1)
    verticalScaleSlider:SetObeyStepOnDrag(true)
    verticalScaleSlider.Text:SetText(GPlaterL["NAMEPLATE_VERTICAL_SCALE"])
    verticalScaleSlider.Low:SetText("0.5")
    verticalScaleSlider.High:SetText("2.0")
    verticalScaleSlider:SetValue(GPlaterDB.Friendly.H or 1.0)
    verticalScaleSlider:SetScript("OnValueChanged", function(self, value)
        GPlaterDB.Friendly.H = value
        UpdateFriendlyNameplates()
    end)

    -- Click-Through Checkbox
    local clickThroughCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
    clickThroughCheck:SetPoint("TOPLEFT", 10, -200)
    clickThroughCheck:SetSize(26, 26)
    clickThroughCheck.Text:SetText(GPlaterL["ENABLE_FRIENDLY_CLICK_THROUGH"])
    clickThroughCheck:SetChecked(GPlaterDB.Friendly.Friendly.FriendlyClickThrough == 1)
    clickThroughCheck:SetScript("OnClick", function(self)
        GPlaterDB.Friendly.Friendly.FriendlyClickThrough = self:GetChecked() and 1 or 0
        if not InCombatLockdown() then
            UpdateFriendlyNameplates()
        else
            GPlaterDB.Friendly.updateCV = true
        end
    end)

    -- Hide Buffs Checkbox
    local hideBuffsCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
    hideBuffsCheck:SetPoint("TOPLEFT", 10, -230)
    hideBuffsCheck:SetSize(26, 26)
    hideBuffsCheck.Text:SetText(GPlaterL["HIDE_FRIENDLY_BUFFS"])
    hideBuffsCheck:SetChecked(GPlaterDB.Friendly.Friendly.HFB)
    hideBuffsCheck:SetScript("OnClick", function(self)
        GPlaterDB.Friendly.Friendly.HFB = self:GetChecked()
        UpdateFriendlyNameplates()
    end)

    -- Show Friendly NPCs Checkbox
    local showFriendlyNPsCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
    showFriendlyNPsCheck:SetPoint("TOPLEFT", 10, -260)
    showFriendlyNPsCheck:SetSize(26, 26)
    showFriendlyNPsCheck.Text:SetText(GPlaterL["SHOW_FRIENDLY_NPCS"])
    showFriendlyNPsCheck:SetChecked(GPlaterDB.Friendly.Friendly.ShowFriendlyNPCs == 1)
    showFriendlyNPsCheck:SetScript("OnClick", function(self)
        GPlaterDB.Friendly.Friendly.ShowFriendlyNPCs = self:GetChecked() and 1 or 0
        UpdateFriendlyNameplates()
    end)

    -- Show Only Names Checkbox
    local showOnlyFriendNamesCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
    showOnlyFriendNamesCheck:SetPoint("TOPLEFT", 10, -290)
    showOnlyFriendNamesCheck:SetSize(26, 26)
    showOnlyFriendNamesCheck.Text:SetText(GPlaterL["SHOW_ONLY_FRIENDLY_NAMES"])
    showOnlyFriendNamesCheck:SetChecked(GPlaterDB.Friendly.Friendly.ShowOnlyFriendNames == 1)
    showOnlyFriendNamesCheck:SetScript("OnClick", function(self)
        GPlaterDB.Friendly.Friendly.ShowOnlyFriendNames = self:GetChecked() and 1 or 0
        UpdateFriendlyNameplates()
    end)

    -- Reset to Defaults Button
    local resetButton = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", 10, -320)
    resetButton:SetSize(120, 22)
    resetButton:SetText(GPlaterL["RESET_TO_DEFAULTS"])
    resetButton:SetScript("OnClick", function()
        GPlaterDB.Friendly = {
            H = 1.0,
            Hbase = 0,
            OverlapV = 0.8,
            Size = 10,
            Friendly = {
                Width = 100,
                distance = 20,
                FriendlyClickThrough = 0,
                HFB = false,
                ShowFriendlyNPCs = 1,
                ShowOnlyFriendNames = 0
            }
        }
        fontSlider:SetValue(GPlaterDB.Friendly.Size)
        widthSlider:SetValue(GPlaterDB.Friendly.Friendly.Width)
        verticalScaleSlider:SetValue(GPlaterDB.Friendly.H)
        clickThroughCheck:SetChecked(GPlaterDB.Friendly.Friendly.FriendlyClickThrough == 1)
        hideBuffsCheck:SetChecked(GPlaterDB.Friendly.Friendly.HFB)
        showFriendlyNPsCheck:SetChecked(GPlaterDB.Friendly.Friendly.ShowFriendlyNPCs == 1)
        showOnlyFriendNamesCheck:SetChecked(GPlaterDB.Friendly.Friendly.ShowOnlyFriendNames == 1)
        UpdateFriendlyNameplates()
    end)

    return contentFrame
end

----------------------------------------
-- Aura Coloring Module
----------------------------------------

-- Utility: Check if unit is attackable
local function IsUnitAttackable(unit)
    if not unit then return false end
    local reaction = UnitReaction("player", unit)
    return reaction and reaction <= 4
end

-- Check if in PvP environment
local function InPvP(unitId)
    return C_PvP.IsBattleground() or C_PvP.IsArena() or (unitId and UnitIsPlayer(unitId) and UnitIsPVP(unitId))
end

-- Utility: Check auras, their stacks, and duration
local function CheckAurasAndStacks(unit, auraIDs, requiredStacks)
    local auraMatches = {}
    local allAurasFound = true
    local below30Percent = false

    for _, auraID in ipairs(auraIDs) do
        auraMatches[auraID] = { found = false, stacks = 0 }
    end

    AuraUtil.ForEachAura(unit, "HARMFUL|PLAYER", nil, function(name, _, count, _, duration, expirationTime, _, _, _, spellID)
        for _, auraID in ipairs(auraIDs) do
            local auraInfo = AuraClassMap and AuraClassMap[auraID]
            if auraInfo and auraInfo.class == PLAYER_CLASS and (auraInfo.spec == nil or auraInfo.spec == GetPlayerSpec()) and not IsSkillLearned(auraID) then
                allAurasFound = false
                return
            end
            if spellID == auraID then
                auraMatches[auraID].found = true
                auraMatches[auraID].stacks = count or 1
                if GPlaterDB.AuraColoring.ResetAt30Percent and duration and duration > 0 and expirationTime and expirationTime > 0 then
                    local remaining = expirationTime - GetTime()
                    if remaining <= duration * 0.3 then
                        below30Percent = true
                    end
                end
                break
            end
        end
    end)

    for _, auraID in ipairs(auraIDs) do
        if not auraMatches[auraID].found then
            allAurasFound = false
            break
        end
    end

    local stacksMatch = true
    if allAurasFound and requiredStacks then
        for _, auraID in ipairs(auraIDs) do
            if auraMatches[auraID].stacks ~= requiredStacks then
                stacksMatch = false
                break
            end
        end
    end

    return allAurasFound and stacksMatch, below30Percent
end

-- Reset colors and effects
local function ResetColors(unitFrame)
    if not unitFrame or not unitFrame.unit then return end

    local unit = unitFrame.unit
    local currentAlpha = unitFrame:GetAlpha() or 1 -- Preserve Plater's alpha
    local npcColor = Plater.GetNpcColor(unitFrame)
    if npcColor then
        Plater.SetNameplateColor(unitFrame, npcColor.r, npcColor.g, npcColor.b, currentAlpha)
    elseif unitFrame.ActorType == "enemyplayer" then
        Plater.FindAndSetNameplateColor(unitFrame) -- Will respect Plater's alpha
    else
        Plater.RefreshNameplateColor(unitFrame) -- Will respect Plater's alpha
    end

    Plater.SetBorderColor(unitFrame)

    if unitFrame.healthBar and unitFrame.healthBar.unitName then
        local defaultTextColor = GPlaterDB.AuraColoring.DefaultTextColors and GPlaterDB.AuraColoring.DefaultTextColors[unitFrame.ActorType] or {1, 1, 1, 1}
        unitFrame.healthBar.unitName:SetTextColor(unpack(defaultTextColor))
    end

    if unitFrame.flashAnimation then
        unitFrame.flashAnimation:Stop()
        unitFrame.flashAnimation = nil
    end

    unitFrame:Show()
end

-- Create flash animation
local function CreateFlashAnimation(unitFrame)
    if unitFrame.flashAnimation then return end
    local ag = unitFrame:CreateAnimationGroup()
    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(1)
    fadeIn:SetToAlpha(0.5)
    fadeIn:SetDuration(0.3)
    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.5)
    fadeOut:SetToAlpha(1)
    fadeOut:SetDuration(0.3)
    ag:SetLooping("REPEAT")
    unitFrame.flashAnimation = ag
    ag:Play()
end

-- Check aura matches and apply colors
local function CheckAuraMatches(unitFrame)
    if not unitFrame or not unitFrame.unit then return false end

    local unit = unitFrame.unit
    if not GPlaterDB.AuraColoring.EnableAuraColoring or (not GPlaterDB.AuraColoring.UseInPvP and InPvP(unit)) or not GPlaterDB.AuraColoring.FilteredBuffsToMatch then
        if unitFrame._gPlaterModified then
            ResetColors(unitFrame)
            unitFrame._gPlaterModified = nil
        end
        return false
    end

    local bestEntry, bestPriority = nil, -1
    for _, config in ipairs(GPlaterDB.AuraColoring.FilteredBuffsToMatch) do
        local aurasMatch, below30Percent = CheckAurasAndStacks(unit, config.auras, config.stacks)
        if aurasMatch and not (GPlaterDB.AuraColoring.ResetAt30Percent and below30Percent) then
            local priority = #config.auras * 1000 + (config.stacks or 0)
            if priority > bestPriority then
                bestEntry = config
                bestPriority = priority
            end
        end
    end

    if not bestEntry then
        if unitFrame._gPlaterModified then
            ResetColors(unitFrame)
            unitFrame._gPlaterModified = nil
        end
        return false
    end

    if bestEntry.hideNameplate then
        unitFrame:SetAlpha(0)
        unitFrame._gPlaterModified = true
        return true
    end

    local currentAlpha = unitFrame:GetAlpha() or 1
    if bestEntry.nameplateColor then
        local r, g, b = 1, 1, 1
        if bestEntry.nameplateColor:match("^#") then
            r = tonumber(bestEntry.nameplateColor:sub(2, 3), 16) / 255
            g = tonumber(bestEntry.nameplateColor:sub(4, 5), 16) / 255
            b = tonumber(bestEntry.nameplateColor:sub(6, 7), 16) / 255
        end
        Plater.SetNameplateColor(unitFrame, r, g, b, currentAlpha)
        unitFrame._gPlaterModified = true
    end
    if bestEntry.borderColor then
        local r, g, b = 1, 1, 1
        if bestEntry.borderColor:match("^#") then
            r = tonumber(bestEntry.borderColor:sub(2, 3), 16) / 255
            g = tonumber(bestEntry.borderColor:sub(4, 5), 16) / 255
            b = tonumber(bestEntry.borderColor:sub(6, 7), 16) / 255
        end
        Plater.SetBorderColor(unitFrame, r, g, b)
        unitFrame._gPlaterModified = true
    end
    if bestEntry.nameTextColor and unitFrame.healthBar and unitFrame.healthBar.unitName then
        local r, g, b = 1, 1, 1
        if bestEntry.nameTextColor:match("^#") then
            r = tonumber(bestEntry.nameTextColor:sub(2, 3), 16) / 255
            g = tonumber(bestEntry.nameTextColor:sub(4, 5), 16) / 255
            b = tonumber(bestEntry.nameTextColor:sub(6, 7), 16) / 255
        end
        unitFrame.healthBar.unitName:SetTextColor(r, g, b)
        unitFrame._gPlaterModified = true
    end

    if bestEntry.flash then
        CreateFlashAnimation(unitFrame)
        unitFrame._gPlaterModified = true
    else
        if unitFrame.flashAnimation then
            unitFrame.flashAnimation:Stop()
            unitFrame.flashAnimation = nil
            unitFrame._gPlaterModified = true
        end
    end

    return true
end

-- Update nameplate with throttling
local LastUpdateAura = {}
local THROTTLE_INTERVAL_AURA = 0.1
local isUpdatingAura = {}

local function UpdateAuraColoringNameplate(plateFrame, forceUpdate)
    if not plateFrame or not plateFrame.unitFrame or not plateFrame.namePlateUnitToken then return end

    local unitFrame = plateFrame.unitFrame
    local unit = plateFrame.namePlateUnitToken
    if isUpdatingAura[unit] then return end
    isUpdatingAura[unit] = true

    local now = GetTime()
    LastUpdateAura[unit] = LastUpdateAura[unit] or 0
    if not (forceUpdate or (now - LastUpdateAura[unit] >= THROTTLE_INTERVAL_AURA)) then
        isUpdatingAura[unit] = false
        return
    end
    LastUpdateAura[unit] = now

    if not IsUnitAttackable(unit) then
        isUpdatingAura[unit] = false
        return
    end

    if GPlaterDB.AuraColoring.UseRaidMarks then
        local markIndex = GetRaidTargetIndex(unit)
        if markIndex and GPlaterDB.AuraColoring.ColorByMark[markIndex] then
            local currentAlpha = unitFrame:GetAlpha() or 1 -- Preserve Plater's alpha
            local r, g, b = 1, 1, 1
            local hex = GPlaterDB.AuraColoring.ColorByMark[markIndex]
            if hex:match("^#") then
                r = tonumber(hex:sub(2, 3), 16) / 255
                g = tonumber(hex:sub(4, 5), 16) / 255
                b = tonumber(hex:sub(6, 7), 16) / 255
            end
            Plater.SetNameplateColor(unitFrame, r, g, b, currentAlpha)
            Plater.SetBorderColor(unitFrame)
            if unitFrame.healthBar and unitFrame.healthBar.unitName then
                unitFrame.healthBar.unitName:SetTextColor(1, 1, 1)
            end
            if unitFrame.flashAnimation then
                unitFrame.flashAnimation:Stop()
                unitFrame.flashAnimation = nil
            end
            unitFrame:Show()
            unitFrame._gPlaterModified = true
            isUpdatingAura[unit] = false
            C_Timer.After(60, function() isUpdatingAura[unit] = nil end)
            return
        end
    end

    CheckAuraMatches(unitFrame)
    isUpdatingAura[unit] = false
    C_Timer.After(60, function() isUpdatingAura[unit] = nil end)
end

-- Event handling for auras
local function OnUnitAura(event, unit)
    if unit == "player" or not unit then return end
    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
        if plateFrame and plateFrame.namePlateUnitToken and (plateFrame.namePlateUnitToken == unit or UnitGUID(plateFrame.namePlateUnitToken) == UnitGUID(unit)) then
            UpdateAuraColoringNameplate(plateFrame, false)
        end
    end
end

-- Hook Plater functions for aura coloring
local function HookPlaterFunctions()
    if Plater.RefreshNameplateColor then
        hooksecurefunc(Plater, "RefreshNameplateColor", function(unitFrame)
            if unitFrame.PlateFrame and unitFrame.PlateFrame.namePlateUnitToken and not isUpdatingAura[unitFrame.PlateFrame.namePlateUnitToken] then
                UpdateAuraColoringNameplate(unitFrame.PlateFrame, true)
            end
        end)
    end
    if Plater.UpdateColor then
        hooksecurefunc(Plater, "UpdateColor", function(unitFrame)
            if unitFrame.PlateFrame and unitFrame.PlateFrame.namePlateUnitToken and not isUpdatingAura[unitFrame.PlateFrame.namePlateUnitToken] then
                UpdateAuraColoringNameplate(unitFrame.PlateFrame, true)
            end
        end)
    end
    if Plater.SetPlateColor then
        hooksecurefunc(Plater, "SetPlateColor", function(unitFrame, r, g, b)
            if unitFrame.PlateFrame and unitFrame.PlateFrame.namePlateUnitToken and not isUpdatingAura[unitFrame.PlateFrame.namePlateUnitToken] then
                UpdateAuraColoringNameplate(unitFrame.PlateFrame, true)
            end
        end)
    end
end

-- Setup Plater hooks for aura coloring
local function SetupPlaterHooks()
    if not Plater or not Plater.db or not Plater.db.profile then return false end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
    eventFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UNIT_FACTION")
    eventFrame:RegisterEvent("UNIT_FLAGS")
    eventFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "NAME_PLATE_UNIT_ADDED" or event == "RAID_TARGET_UPDATE" then
            for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                if plateFrame and plateFrame.namePlateUnitToken then
                    UpdateAuraColoringNameplate(plateFrame, true)
                end
            end
        elseif event == "UNIT_AURA" or event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_FACTION" or event == "UNIT_FLAGS" then
            OnUnitAura(event, unit)
        elseif event == "PLAYER_TARGET_CHANGED" then
            for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                if plateFrame and plateFrame.namePlateUnitToken and UnitIsUnit(plateFrame.namePlateUnitToken, "target") then
                    UpdateAuraColoringNameplate(plateFrame, true)
                    break
                end
            end
        end
    end)

    HookPlaterFunctions()
    return true
end

-- Load default text colors from Plater
local function LoadDefaultTextColors()
    if not Plater or not Plater.db or not Plater.db.profile then return end

    local profile = Plater.db.profile
    GPlaterDB.AuraColoring.DefaultTextColors = {
        enemynpc = profile.plate_config and profile.plate_config.enemynpc and profile.plate_config.enemynpc.name_color or {1, 1, 1, 1},
        enemyplayer = profile.plate_config and profile.plate_config.enemyplayer and profile.plate_config.enemyplayer.name_color or {1, 1, 1, 1},
        neutral = profile.plate_config and profile.plate_config.neutral and profile.plate_config.neutral.name_color or {1, 1, 1, 1}
    }
end

-- Filter buffs by player class, specialization, and learned skills
local function FilterBuffsByClassAndSpec()
    GPlaterDB.AuraColoring.BuffsToMatch = GPlaterDB.AuraColoring.BuffsToMatch or {}
    local filteredBuffsToMatch = {}
    local currentSpec = GetPlayerSpec()

    for _, entry in ipairs(GPlaterDB.AuraColoring.BuffsToMatch) do
        for _, auraID in ipairs(entry.auras) do
            local auraInfo = AuraClassMap and AuraClassMap[auraID]
            if auraInfo and auraInfo.class == PLAYER_CLASS and (auraInfo.spec == nil or auraInfo.spec == currentSpec) and IsSkillLearned(auraID) then
                table.insert(filteredBuffsToMatch, entry)
                break
            end
        end
    end
    GPlaterDB.AuraColoring.FilteredBuffsToMatch = filteredBuffsToMatch
end

-- Initialize aura coloring
local function UpdateAuraColoring()
    LoadDefaultTextColors()
    FilterBuffsByClassAndSpec()
    C_Timer.After(5, function()
        if not SetupPlaterHooks() then
            C_Timer.After(5, SetupPlaterHooks)
        end
    end)
end

-- Create Aura Coloring content
local function CreateAuraColoringContent(parent)
    if not parent then
        local errorMsg = "Parent frame is nil"
        local errorFrame = CreateFrame("Frame", nil, UIParent)
        local errorText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errorText:SetPoint("CENTER")
        errorText:SetText(string.format(GPlaterL["MODULE_LOAD_ERROR"], "Aura Coloring", errorMsg))
        return errorFrame
    end

    local contentFrame = CreateFrame("Frame", nil, parent)
    contentFrame:SetSize(790, 550)

    local success, errorMsg = pcall(function()
        -- Enable Aura Coloring
        local enableAuraColoringCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
        enableAuraColoringCheck:SetPoint("TOPLEFT", 20, -40)
        enableAuraColoringCheck:SetSize(26, 26)
        enableAuraColoringCheck.text:SetText(GPlaterL["ENABLE_AURA_COLORING"])
        enableAuraColoringCheck:SetChecked(GPlaterDB.AuraColoring.EnableAuraColoring)
        enableAuraColoringCheck:SetScript("OnClick", function(self)
            GPlaterDB.AuraColoring.EnableAuraColoring = self:GetChecked()
            for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                if plateFrame and plateFrame.namePlateUnitToken then
                    UpdateAuraColoringNameplate(plateFrame, true)
                end
            end
        end)

        -- Use in PvP
        local useInPvPCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
        useInPvPCheck:SetPoint("TOPLEFT", 20, -70)
        useInPvPCheck:SetSize(26, 26)
        useInPvPCheck.text:SetText(GPlaterL["USE_IN_PVP"])
        useInPvPCheck:SetChecked(GPlaterDB.AuraColoring.UseInPvP)
        useInPvPCheck:SetScript("OnClick", function(self)
            GPlaterDB.AuraColoring.UseInPvP = self:GetChecked()
            for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                if plateFrame and plateFrame.namePlateUnitToken then
                    UpdateAuraColoringNameplate(plateFrame, true)
                end
            end
        end)

        -- Use Raid Marks
        local useRaidMarksCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
        useRaidMarksCheck:SetPoint("TOPLEFT", 20, -100)
        useRaidMarksCheck:SetSize(26, 26)
        useRaidMarksCheck.text:SetText(GPlaterL["USE_RAID_MARKS"])
        useRaidMarksCheck:SetChecked(GPlaterDB.AuraColoring.UseRaidMarks)

        -- Reset at 30% Duration
        local resetAt30PercentCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
        resetAt30PercentCheck:SetPoint("TOPLEFT", 20, -130)
        resetAt30PercentCheck:SetSize(26, 26)
        resetAt30PercentCheck.text:SetText(GPlaterL["RESET_AT_30_PERCENT"])
        resetAt30PercentCheck:SetChecked(GPlaterDB.AuraColoring.ResetAt30Percent)
        resetAt30PercentCheck:SetScript("OnClick", function(self)
            GPlaterDB.AuraColoring.ResetAt30Percent = self:GetChecked()
            for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                if plateFrame and plateFrame.namePlateUnitToken then
                    UpdateAuraColoringNameplate(plateFrame, true)
                end
            end
        end)

        -- Raid Marks Frame
        contentFrame.raidMarksFrame = CreateFrame("Frame", nil, contentFrame)
        contentFrame.raidMarksFrame:SetPoint("LEFT", useRaidMarksCheck.text, "RIGHT", 10, 0)
        contentFrame.raidMarksFrame:SetSize(500, 30)
        contentFrame.raidMarksFrame:SetShown(GPlaterDB.AuraColoring.UseRaidMarks)

        local raidIconTextures = {
            "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1", -- Star
            "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2", -- Circle
            "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3", -- Diamond
            "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4", -- Triangle
            "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5", -- Moon
            "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6", -- Square
            "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7", -- Cross
            "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"  -- Skull
        }

        for i = 1, 8 do
            local icon = contentFrame.raidMarksFrame:CreateTexture(nil, "OVERLAY")
            icon:SetTexture(raidIconTextures[i])
            icon:SetSize(18, 18)
            icon:SetPoint("LEFT", (i - 1) * 60, 0)

            local colorButton = CreateFrame("Button", nil, contentFrame.raidMarksFrame)
            colorButton:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            colorButton:SetSize(27, 27)
            colorButton:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
            local function UpdateColor(r, g, b)
                local hex = string.format("#%02x%02x%02x", r * 255, g * 255, b * 255)
                GPlaterDB.AuraColoring.ColorByMark[i] = hex
                colorButton:GetNormalTexture():SetVertexColor(r, g, b)
                for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                    if plateFrame and plateFrame.namePlateUnitToken then
                        UpdateAuraColoringNameplate(plateFrame, true)
                    end
                end
            end
            colorButton:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    local currentColor = GPlaterDB.AuraColoring.ColorByMark[i] or "#ffffff"
                    local r, g, b = 1, 1, 1
                    if currentColor:match("^#") then
                        r = tonumber(currentColor:sub(2, 3), 16) / 255
                        g = tonumber(currentColor:sub(4, 5), 16) / 255
                        b = tonumber(currentColor:sub(6, 7), 16) / 255
                    end
                    ColorPickerFrame:SetupColorPickerAndShow({
                        r = r, g = g, b = b, a = 1,
                        swatchFunc = function()
                            local r, g, b = ColorPickerFrame:GetColorRGB()
                            UpdateColor(r, g, b)
                        end,
                        cancelFunc = function()
                            colorButton:GetNormalTexture():SetVertexColor(r, g, b)
                        end
                    })
                end
            end)
            local currentColor = GPlaterDB.AuraColoring.ColorByMark[i] or "#ffffff"
            if currentColor:match("^#") then
                local r = tonumber(currentColor:sub(2, 3), 16) / 255
                local g = tonumber(currentColor:sub(4, 5), 16) / 255
                local b = tonumber(currentColor:sub(6, 7), 16) / 255
                colorButton:GetNormalTexture():SetVertexColor(r, g, b)
            end
        end

        useRaidMarksCheck:SetScript("OnClick", function(self)
            GPlaterDB.AuraColoring.UseRaidMarks = self:GetChecked()
            contentFrame.raidMarksFrame:SetShown(self:GetChecked())
            for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                if plateFrame and plateFrame.namePlateUnitToken then
                    UpdateAuraColoringNameplate(plateFrame, true)
                end
            end
        end)

        -- Aura Table
        local auraTableFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
        auraTableFrame:SetPoint("TOPLEFT", 10, -170)
        auraTableFrame:SetPoint("BOTTOMRIGHT", -10, 60)
        auraTableFrame:SetClipsChildren(true)
        local auraTableContent = CreateFrame("Frame", nil, auraTableFrame)
        auraTableContent:SetSize(790, math.max(400, (#(GPlaterDB.AuraColoring.BuffsToMatch or {}) + 1) * 24 + 30))
        auraTableFrame:SetScrollChild(auraTableContent)
        contentFrame.auraTableContent = auraTableContent

        local headers = {
            GPlaterL["AURA_ID"],
            GPlaterL["AURA_NAME"],
            GPlaterL["STACKS"],
            GPlaterL["NAME_TEXT"],
            GPlaterL["NAMEPLATE"],
            GPlaterL["BORDER"],
            GPlaterL["FLASH"],
            ""
        }
        local columnWidths = {
            110, -- AURA_ID
            165, -- AURA_NAME
            88,  -- STACKS
            55,  -- NAME_TEXT
            55,  -- NAMEPLATE
            55,  -- BORDER
            55,  -- FLASH
            66   -- DELETE
        }
        local totalWidth = 0
        for _, width in ipairs(columnWidths) do
            totalWidth = totalWidth + width
        end
        local leftOffset = (790 - totalWidth) / 2

        local function CreateTableHeaders()
            local offset = leftOffset
            for i, header in ipairs(headers) do
                local label = auraTableContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
                label:SetPoint("TOPLEFT", offset, -10)
                label:SetSize(columnWidths[i], 20)
                label:SetText(header)
                offset = offset + columnWidths[i]
            end
        end

        local function UpdateAuraTable()
            if auraTableContent.rows then
                for _, row in ipairs(auraTableContent.rows) do
                    for _, widget in ipairs(row) do
                        widget:Hide()
                        widget:ClearAllPoints()
                    end
                end
            end
            auraTableContent.rows = {}

            GPlaterDB.AuraColoring.BuffsToMatch = GPlaterDB.AuraColoring.BuffsToMatch or {}

            local classBuffs, otherBuffs = {}, {}
            for i, entry in ipairs(GPlaterDB.AuraColoring.BuffsToMatch) do
                local isClassAura = false
                for _, auraID in ipairs(entry.auras) do
                    local auraInfo = AuraClassMap and AuraClassMap[auraID]
                    if auraInfo and auraInfo.class == PLAYER_CLASS then
                        isClassAura = true
                        break
                    end
                end
                table.insert(isClassAura and classBuffs or otherBuffs, { index = i, entry = entry })
            end

            local sortedBuffs = {}
            for _, buff in ipairs(classBuffs) do table.insert(sortedBuffs, buff) end
            for _, buff in ipairs(otherBuffs) do table.insert(sortedBuffs, buff) end

            for rowIndex, buff in ipairs(sortedBuffs) do
                local i = buff.index
                local entry = buff.entry
                local row = {}
                local offset = leftOffset
                local isClassAura = false
                for _, auraID in ipairs(entry.auras) do
                    local auraInfo = AuraClassMap and AuraClassMap[auraID]
                    if auraInfo and auraInfo.class == PLAYER_CLASS then
                        isClassAura = true
                        break
                    end
                end

                -- Aura ID
                local idEdit = CreateFrame("EditBox", nil, auraTableContent, "InputBoxTemplate")
                idEdit:SetPoint("TOPLEFT", offset + 5, -30 - (rowIndex * 24))
                idEdit:SetSize(columnWidths[1] - 10, 20)
                idEdit:SetAutoFocus(false)
                idEdit:SetText(table.concat(entry.auras, ","))
                idEdit:SetTextColor(isClassAura and 1 or 0.5, isClassAura and 1 or 0.5, isClassAura and 1 or 0.5)
                idEdit:SetJustifyH("LEFT")
                idEdit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
                idEdit:SetScript("OnEditFocusLost", function(self)
                    local text = self:GetText():trim()
                    local auras = {}
                    local invalidIDs = {}
                    for id in text:gmatch("%d+") do
                        local spellID = tonumber(id)
                        if spellID and C_Spell.GetSpellName(spellID) then
                            table.insert(auras, spellID)
                        else
                            table.insert(invalidIDs, id)
                        end
                    end
                    if #invalidIDs > 0 then
                        print(string.format("|cFFFF0000GPlater: %s|r", string.format(GPlaterL["INVALID_SPELL_ID"], table.concat(invalidIDs, ", "))))
                    end
                    entry.auras = #auras > 0 and auras or entry.auras
                    local name = ""
                    for _, id in ipairs(entry.auras) do
                        local spellName = C_Spell.GetSpellName(id) or "Unknown"
                        name = name .. spellName .. ","
                    end
                    row[2]:SetText(name ~= "" and name:sub(1, -2) or "Unknown")
                    local isClassAuraCheck = false
                    for _, auraID in ipairs(entry.auras) do
                        local auraInfo = AuraClassMap and AuraClassMap[auraID]
                        if auraInfo and auraInfo.class == PLAYER_CLASS then
                            isClassAuraCheck = true
                            break
                        end
                    end
                    row[2]:SetTextColor(isClassAuraCheck and 1 or 0.5, isClassAuraCheck and 1 or 0.5, isClassAuraCheck and 1 or 0.5)
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateAuraColoringNameplate(plateFrame, true)
                        end
                    end
                end)
                idEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
                row[1] = idEdit
                offset = offset + columnWidths[1]

                -- Aura Name
                local nameText = auraTableContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                nameText:SetPoint("TOPLEFT", offset + 5, -30 - (rowIndex * 24))
                nameText:SetSize(columnWidths[2] - 10, 20)
                nameText:SetJustifyH("LEFT")
                local name = ""
                for _, id in ipairs(entry.auras) do
                    local spellName = C_Spell.GetSpellName(id) or "Unknown"
                    name = name .. spellName .. ","
                end
                nameText:SetText(name ~= "" and name:sub(1, -2) or "Unknown")
                nameText:SetTextColor(isClassAura and 1 or 0.5, isClassAura and 1 or 0.5, isClassAura and 1 or 0.5)
                row[2] = nameText
                offset = offset + columnWidths[2]

                -- Stacks
                local stacksEdit = CreateFrame("EditBox", nil, auraTableContent, "InputBoxTemplate")
                stacksEdit:SetPoint("TOPLEFT", offset + 5, -30 - (rowIndex * 24))
                stacksEdit:SetSize(columnWidths[3] - 10, 20)
                stacksEdit:SetAutoFocus(false)
                stacksEdit:SetText(entry.stacks and tostring(entry.stacks) or GPlaterL["STACKS_NOT_CHECKED"])
                stacksEdit:SetTextColor(isClassAura and 1 or 0.5, isClassAura and 1 or 0.5, isClassAura and 1 or 0.5)
                stacksEdit:SetJustifyH("CENTER")
                stacksEdit:SetScript("OnEditFocusGained", function(self)
                    if self:GetText() == GPlaterL["STACKS_NOT_CHECKED"] then self:SetText("") end
                    self:HighlightText()
                end)
                stacksEdit:SetScript("OnEditFocusLost", function(self)
                    local text = self:GetText():trim()
                    if text == "" or text == GPlaterL["STACKS_NOT_CHECKED"] then
                        entry.stacks = nil
                        self:SetText(GPlaterL["STACKS_NOT_CHECKED"])
                    else
                        local value = tonumber(text)
                        if value then
                            entry.stacks = math.floor(value)
                            self:SetText(tostring(entry.stacks))
                        else
                            self:SetText(GPlaterL["STACKS_NOT_CHECKED"])
                        end
                    end
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateAuraColoringNameplate(plateFrame, true)
                        end
                    end
                end)
                stacksEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
                row[3] = stacksEdit
                offset = offset + columnWidths[3]

                -- Name Text Color
                local nameColorButton = CreateFrame("Button", nil, auraTableContent)
                nameColorButton:SetPoint("TOPLEFT", offset + (columnWidths[4] - 27) / 2, -30 - (rowIndex * 24))
                nameColorButton:SetSize(27, 27)
                nameColorButton:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                local function UpdateNameColor(r, g, b)
                    local hex = string.format("#%02x%02x%02x", r * 255, g * 255, b * 255)
                    entry.nameTextColor = hex
                    nameColorButton:GetNormalTexture():SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                    nameColorButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                    nameColorButton:GetNormalTexture():SetVertexColor(r, g, b)
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateAuraColoringNameplate(plateFrame, true)
                        end
                    end
                end
                nameColorButton:SetScript("OnMouseUp", function(self, button)
                    if button == "LeftButton" then
                        local currentColor = entry.nameTextColor or "#ffffff"
                        local r, g, b = 1, 1, 1
                        if currentColor:match("^#") then
                            r = tonumber(currentColor:sub(2, 3), 16) / 255
                            g = tonumber(currentColor:sub(4, 5), 16) / 255
                            b = tonumber(currentColor:sub(6, 7), 16) / 255
                        end
                        ColorPickerFrame:SetupColorPickerAndShow({
                            r = r, g = g, b = b, a = 1,
                            swatchFunc = function()
                                local r, g, b = ColorPickerFrame:GetColorRGB()
                                UpdateNameColor(r, g, b)
                            end,
                            cancelFunc = function()
                                nameColorButton:GetNormalTexture():SetVertexColor(r, g, b)
                            end
                        })
                    elseif button == "RightButton" then
                        if entry.nameTextColor then
                            entry.nameTextColor = nil
                            nameColorButton:GetNormalTexture():SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
                            nameColorButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                        else
                            entry.nameTextColor = "#ffffff"
                            nameColorButton:GetNormalTexture():SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                            nameColorButton:GetNormalTexture():SetVertexColor(1, 1, 1)
                        end
                        for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                            if plateFrame and plateFrame.namePlateUnitToken then
                                UpdateAuraColoringNameplate(plateFrame, true)
                            end
                        end
                    end
                end)
                if entry.nameTextColor then
                    local r, g, b = 1, 1, 1
                    if entry.nameTextColor:match("^#") then
                        r = tonumber(entry.nameTextColor:sub(2, 3), 16) / 255
                        g = tonumber(entry.nameTextColor:sub(4, 5), 16) / 255
                        b = tonumber(entry.nameTextColor:sub(6, 7), 16) / 255
                    end
                    nameColorButton:GetNormalTexture():SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                    nameColorButton:GetNormalTexture():SetVertexColor(r, g, b)
                else
                    nameColorButton:GetNormalTexture():SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
                    nameColorButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                end
                row[4] = nameColorButton
                offset = offset + columnWidths[4]

                -- Nameplate Color
                local plateColorButton = CreateFrame("Button", nil, auraTableContent)
                plateColorButton:SetPoint("TOPLEFT", offset + (columnWidths[5] - 27) / 2, -30 - (rowIndex * 24))
                plateColorButton:SetSize(27, 27)
                plateColorButton:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                local function UpdatePlateColor(r, g, b)
                    local hex = string.format("#%02x%02x%02x", r * 255, g * 255, b * 255)
                    entry.nameplateColor = hex
                    plateColorButton:GetNormalTexture():SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                    plateColorButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                    plateColorButton:GetNormalTexture():SetVertexColor(r, g, b)
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateAuraColoringNameplate(plateFrame, true)
                        end
                    end
                end
                plateColorButton:SetScript("OnMouseUp", function(self, button)
                    if button == "LeftButton" then
                        local currentColor = entry.nameplateColor or "#ffffff"
                        local r, g, b = 1, 1, 1
                        if currentColor:match("^#") then
                            r = tonumber(currentColor:sub(2, 3), 16) / 255
                            g = tonumber(currentColor:sub(4, 5), 16) / 255
                            b = tonumber(currentColor:sub(6, 7), 16) / 255
                        end
                        ColorPickerFrame:SetupColorPickerAndShow({
                            r = r, g = g, b = b, a = 1,
                            swatchFunc = function()
                                local r, g, b = ColorPickerFrame:GetColorRGB()
                                UpdatePlateColor(r, g, b)
                            end,
                            cancelFunc = function()
                                plateColorButton:GetNormalTexture():SetVertexColor(r, g, b)
                            end
                        })
                    elseif button == "RightButton" then
                        if entry.nameplateColor then
                            entry.nameplateColor = nil
                            plateColorButton:GetNormalTexture():SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
                            plateColorButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                        else
                            entry.nameplateColor = "#ffffff"
                            plateColorButton:GetNormalTexture():SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                            plateColorButton:GetNormalTexture():SetVertexColor(1, 1, 1)
                        end
                        for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                            if plateFrame and plateFrame.namePlateUnitToken then
                                UpdateAuraColoringNameplate(plateFrame, true)
                            end
                        end
                    end
                end)
                if entry.nameplateColor then
                    local r, g, b = 1, 1, 1
                    if entry.nameplateColor:match("^#") then
                        r = tonumber(entry.nameplateColor:sub(2, 3), 16) / 255
                        g = tonumber(entry.nameplateColor:sub(4, 5), 16) / 255
                        b = tonumber(entry.nameplateColor:sub(6, 7), 16) / 255
                    end
                    plateColorButton:GetNormalTexture():SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                    plateColorButton:GetNormalTexture():SetVertexColor(r, g, b)
                else
                    plateColorButton:GetNormalTexture():SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
                    plateColorButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                end
                row[5] = plateColorButton
                offset = offset + columnWidths[5]

                -- Border Color
                local borderColorButton = CreateFrame("Button", nil, auraTableContent)
                borderColorButton:SetPoint("TOPLEFT", offset + (columnWidths[6] - 27) / 2, -30 - (rowIndex * 24))
                borderColorButton:SetSize(27, 27)
                borderColorButton:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                local function UpdateBorderColor(r, g, b)
                    local hex = string.format("#%02x%02x%02x", r * 255, g * 255, b * 255)
                    entry.borderColor = hex
                    borderColorButton:GetNormalTexture():SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                    borderColorButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                    borderColorButton:GetNormalTexture():SetVertexColor(r, g, b)
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateAuraColoringNameplate(plateFrame, true)
                        end
                    end
                end
                borderColorButton:SetScript("OnMouseUp", function(self, button)
                    if button == "LeftButton" then
                        local currentColor = entry.borderColor or "#ffffff"
                        local r, g, b = 1, 1, 1
                        if currentColor:match("^#") then
                            r = tonumber(currentColor:sub(2, 3), 16) / 255
                            g = tonumber(currentColor:sub(4, 5), 16) / 255
                            b = tonumber(currentColor:sub(6, 7), 16) / 255
                        end
                        ColorPickerFrame:SetupColorPickerAndShow({
                            r = r, g = g, b = b, a = 1,
                            swatchFunc = function()
                                local r, g, b = ColorPickerFrame:GetColorRGB()
                                UpdateBorderColor(r, g, b)
                            end,
                            cancelFunc = function()
                                borderColorButton:GetNormalTexture():SetVertexColor(r, g, b)
                            end
                        })
                    elseif button == "RightButton" then
                        if entry.borderColor then
                            entry.borderColor = nil
                            borderColorButton:GetNormalTexture():SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
                            borderColorButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                        else
                            entry.borderColor = "#ffffff"
                            borderColorButton:GetNormalTexture():SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                            borderColorButton:GetNormalTexture():SetVertexColor(1, 1, 1)
                        end
                        for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                            if plateFrame and plateFrame.namePlateUnitToken then
                                UpdateAuraColoringNameplate(plateFrame, true)
                            end
                        end
                    end
                end)
                if entry.borderColor then
                    local r, g, b = 1, 1, 1
                    if entry.borderColor:match("^#") then
                        r = tonumber(entry.borderColor:sub(2, 3), 16) / 255
                        g = tonumber(entry.borderColor:sub(4, 5), 16) / 255
                        b = tonumber(entry.borderColor:sub(6, 7), 16) / 255
                    end
                    borderColorButton:GetNormalTexture():SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
                    borderColorButton:GetNormalTexture():SetVertexColor(r, g, b)
                else
                    borderColorButton:GetNormalTexture():SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
                    borderColorButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
                end
                row[6] = borderColorButton
                offset = offset + columnWidths[6]

                -- Flash
                local flashCheck = CreateFrame("CheckButton", nil, auraTableContent, "UICheckButtonTemplate")
                flashCheck:SetPoint("TOPLEFT", offset + (columnWidths[7] - 27) / 2, -30 - (rowIndex * 24))
                flashCheck:SetSize(27, 27)
                flashCheck:SetChecked(entry.flash)
                flashCheck:SetScript("OnClick", function(self)
                    entry.flash = self:GetChecked()
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateAuraColoringNameplate(plateFrame, true)
                        end
                    end
                end)
                row[7] = flashCheck
                offset = offset + columnWidths[7]

                -- Delete
                local deleteButton = CreateFrame("Button", nil, auraTableContent, "UIPanelButtonTemplate")
                deleteButton:SetPoint("TOPLEFT", offset + (columnWidths[8] - 50) / 2, -30 - (rowIndex * 24))
                deleteButton:SetSize(columnWidths[8] - 10, 20)
                deleteButton:SetText(GPlaterL["DELETE"])
                deleteButton:SetScript("OnClick", function()
                    table.remove(GPlaterDB.AuraColoring.BuffsToMatch, i)
                    UpdateAuraTable()
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateAuraColoringNameplate(plateFrame, true)
                        end
                    end
                end)
                row[8] = deleteButton

                -- Create a backdrop frame for the row
                local rowFrame = CreateFrame("Frame", nil, auraTableContent, "BackdropTemplate")
                rowFrame:SetPoint("TOPLEFT", leftOffset, -30 - (rowIndex * 24))
                rowFrame:SetSize(totalWidth, 24)
                rowFrame:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 8,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                rowFrame:SetBackdropColor(0, 0, 0, 0.5)
                rowFrame:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)

                auraTableContent.rows[rowIndex] = row
            end

            -- Add button in the last row of Aura ID column
            local addButton = auraTableContent.addButton or CreateFrame("Button", nil, auraTableContent, "UIPanelButtonTemplate")
            auraTableContent.addButton = addButton
            addButton:SetPoint("TOPLEFT", leftOffset + 5, -30 - ((#sortedBuffs + 1) * 24))
            addButton:SetSize(90, 22)
            addButton:SetText(GPlaterL["ADD_AURA"])
            addButton:Show()
            addButton:SetScript("OnClick", function()
                table.insert(GPlaterDB.AuraColoring.BuffsToMatch, { auras = {}, flash = false, stacks = nil })
                UpdateAuraTable()
            end)

            auraTableContent:SetHeight((#GPlaterDB.AuraColoring.BuffsToMatch + 2) * 24 + 30)
        end

        contentFrame.CreateTableHeaders = CreateTableHeaders
        contentFrame.UpdateAuraTable = UpdateAuraTable
        contentFrame:CreateTableHeaders()
        contentFrame:UpdateAuraTable()
    end)

    if not success then
        contentFrame:Hide()
        local errorFrame = CreateFrame("Frame", nil, parent)
        local errorText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errorText:SetPoint("CENTER")
        errorText:SetText(string.format(GPlaterL["MODULE_LOAD_ERROR"], "Aura Coloring", errorMsg))
        return errorFrame
    end

    return contentFrame
end

----------------------------------------
-- Cast Handling Module
----------------------------------------

-- Filter spells by player class, specialization, and learned interrupts
local function FilterSpellsByClassAndSpec()
    GPlaterDB.CastHandling.SpellsToMonitor = GPlaterDB.CastHandling.SpellsToMonitor or {}
    local filteredSpells = {}
    local currentSpec = GetPlayerSpec()

    for _, entry in ipairs(GPlaterDB.CastHandling.SpellsToMonitor) do
        if not entry.specialAttention then
            table.insert(filteredSpells, entry)
        else
            for spellID, info in pairs(InterruptClassMap or {}) do
                if info.class == PLAYER_CLASS and (info.spec == nil or info.spec == currentSpec or (type(info.spec) == "table" and tContains(info.spec, currentSpec))) and IsSpellKnown(spellID) then
                    table.insert(filteredSpells, entry)
                    break
                end
            end
        end
    end
    GPlaterDB.CastHandling.FilteredSpellsToMonitor = filteredSpells
end

-- Check if an interrupt is available
local function IsInterruptAvailable()
    local interrupts = {}
    local currentSpec = GetPlayerSpec()
    for spellID, info in pairs(InterruptClassMap or {}) do
        if info.class == PLAYER_CLASS and (info.spec == nil or info.spec == currentSpec or (type(info.spec) == "table" and tContains(info.spec, currentSpec))) then
            local spellInfo = C_Spell.GetSpellInfo(spellID) -- WoW 11.1 API
            if spellInfo and spellInfo.name and IsSpellKnown(spellID) then
                local cdInfo = C_Spell.GetSpellCooldown(spellID)
                if cdInfo and cdInfo.startTime == 0 then
                    table.insert(interrupts, spellID)
                end
            end
        end
    end
    return #interrupts > 0, interrupts
end

-- Check if a spell is being cast or channeled
local function CheckSpellCast(unitFrame, spellID)
    if not unitFrame or not unitFrame.unit then return false, false end
    local unit = unitFrame.unit
    local isCasting, isInterruptible = false, true
    local name, _, _, _, _, _, castSpellID, _, notInterruptible = UnitCastingInfo(unit)
    if name and castSpellID == spellID then
        isCasting = true
        isInterruptible = not notInterruptible
    else
        name, _, _, _, _, _, castSpellID, notInterruptible = UnitChannelInfo(unit)
        if name and castSpellID == spellID then
            isCasting = true
            isInterruptible = not notInterruptible
        end
    end
    return isCasting, isInterruptible
end

-- Apply cast handling effects
local function ApplyCastHandling(plateFrame)
    if not plateFrame or not plateFrame.unitFrame or not plateFrame.unitFrame.unit or not GPlaterDB.CastHandling.EnableCastHandling or not GPlaterDB.CastHandling.FilteredSpellsToMonitor then
        return false, false, false
    end

    local unitFrame = plateFrame.unitFrame
    local unit = plateFrame.namePlateUnitToken
    local hasInterrupt, interrupts = IsInterruptAvailable()
    local isCastingMonitoredSpell, isSpecialAttention, isTopPriority, isInterruptible = false, false, false, true

    for _, config in ipairs(GPlaterDB.CastHandling.FilteredSpellsToMonitor) do
        local isCasting, interruptible = CheckSpellCast(unitFrame, config.spellID)
        if isCasting then
            isCastingMonitoredSpell = true
            isInterruptible = interruptible
            if config.specialAttention and hasInterrupt and interruptible then
                isSpecialAttention = true
            end
            if config.topPriority then
                isTopPriority = true
            end
            break
        end
    end

    local wasTopPriority = GPlaterDB.CastHandling.topPriorityUnits[unitFrame]
    if isTopPriority and not wasTopPriority then
        if not GPlaterDB.CastHandling.unitKeys[unitFrame] then
            GPlaterDB.CastHandling.unitKeys[unitFrame] = #GPlaterDB.CastHandling.unitKeys + 1
        end
        GPlaterDB.CastHandling.castCounter = GPlaterDB.CastHandling.castCounter + 1
        unitFrame._castOrder = GPlaterDB.CastHandling.castCounter
        GPlaterDB.CastHandling.topPriorityUnits[unitFrame] = unitFrame._castOrder
        unitFrame._originalLevel = unitFrame:GetFrameLevel()
        local newFrameLevel = unitFrame._originalLevel + 100 + (unitFrame._castOrder * 10) + GPlaterDB.CastHandling.unitKeys[unitFrame]
        if not InCombatLockdown() then
            plateFrame:SetFrameLevel(newFrameLevel)
        else
            GPlaterDB.CastHandling.pendingFrameLevels[unit] = newFrameLevel
        end
    elseif not isTopPriority and wasTopPriority then
        GPlaterDB.CastHandling.topPriorityUnits[unitFrame] = nil
        if unitFrame._originalLevel then
            if not InCombatLockdown() then
                plateFrame:SetFrameLevel(unitFrame._originalLevel)
            else
                GPlaterDB.CastHandling.pendingFrameLevels[unit] = unitFrame._originalLevel
            end
            unitFrame._originalLevel = nil
            unitFrame._castOrder = nil
        end
    end

    return isCastingMonitoredSpell, isSpecialAttention, isTopPriority
end

-- Apply queued frame level changes
local function ApplyPendingFrameLevels()
    if InCombatLockdown() or not GPlaterDB.CastHandling.pendingFrameLevels then return end
    for unit, level in pairs(GPlaterDB.CastHandling.pendingFrameLevels) do
        for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
            if plateFrame.namePlateUnitToken == unit then
                plateFrame:SetFrameLevel(level)
                break
            end
        end
    end
    GPlaterDB.CastHandling.pendingFrameLevels = {}
end

-- Update cast handling with throttling
local LastUpdateCast = {}
local THROTTLE_INTERVAL_CAST = 0.2 -- Aligned with Aura Coloring
local isUpdatingCast = {}

local function UpdateCastHandlingNameplate(plateFrame, forceUpdate)
    if not plateFrame or not plateFrame.unitFrame or not plateFrame.namePlateUnitToken then return end

    local unitFrame = plateFrame.unitFrame
    local unit = plateFrame.namePlateUnitToken
    if isUpdatingCast[unit] then return end
    isUpdatingCast[unit] = true

    local now = GetTime()
    LastUpdateCast[unit] = LastUpdateCast[unit] or 0
    if not (forceUpdate or (now - LastUpdateCast[unit] >= THROTTLE_INTERVAL_CAST)) then
        isUpdatingCast[unit] = false
        return
    end
    LastUpdateCast[unit] = now

    if not IsUnitAttackable(unit) then
        unitFrame:SetAlpha(1)
        isUpdatingCast[unit] = false
        return
    end

    if GPlaterDB.CastHandling.config.showOnTargeting and unitFrame.namePlateIsTarget then
        unitFrame:SetAlpha(1)
        isUpdatingCast[unit] = false
        return
    end

    if GPlaterDB.CastHandling.config.showOnMark and GetRaidTargetIndex(unit) then
        unitFrame:SetAlpha(1)
        isUpdatingCast[unit] = false
        return
    end

    local isCasting, isSpecialAttention, isTopPriority = ApplyCastHandling(plateFrame)
    local wasConcerned = unitFrame._isConcerned or false
    if isSpecialAttention and not wasConcerned then
        GPlaterDB.CastHandling._ConcernedNum = GPlaterDB.CastHandling._ConcernedNum + 1
        unitFrame._isConcerned = true
    elseif not isSpecialAttention and wasConcerned then
        GPlaterDB.CastHandling._ConcernedNum = math.max(0, GPlaterDB.CastHandling._ConcernedNum - 1)
        unitFrame._isConcerned = false
    end

    -- Stop any flash animations before setting alpha to ensure transparency
    if unitFrame.flashAnimation then
        unitFrame.flashAnimation:Stop()
        unitFrame.flashAnimation = nil
    end
    unitFrame:SetAlpha(isSpecialAttention and 1 or (GPlaterDB.CastHandling._ConcernedNum > 0 and 0 or 1))

    isUpdatingCast[unit] = false
    C_Timer.After(60, function() isUpdatingCast[unit] = nil end)
end

-- Event handling for casts
local function OnUnitSpellCast(event, unit)
    if unit == "player" or not unit then return end
    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
        if plateFrame and plateFrame.namePlateUnitToken and (plateFrame.namePlateUnitToken == unit or UnitGUID(plateFrame.namePlateUnitToken) == UnitGUID(unit)) then
            UpdateCastHandlingNameplate(plateFrame, true)
        end
    end
end

-- Setup cast handling hooks
local function SetupCastHandlingHooks()
    if not Plater or not Plater.db or not Plater.db.profile then return false end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "NAME_PLATE_UNIT_ADDED" or event == "SPELL_UPDATE_COOLDOWN" then
            for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                if plateFrame and plateFrame.namePlateUnitToken then
                    UpdateCastHandlingNameplate(plateFrame, true)
                end
            end
        elseif event == "NAME_PLATE_UNIT_REMOVED" and unit then
            if GPlaterDB.CastHandling._ConcernedNum > 0 then
                for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                    if plateFrame.namePlateUnitToken == unit and plateFrame.unitFrame._isConcerned then
                        GPlaterDB.CastHandling._ConcernedNum = math.max(0, GPlaterDB.CastHandling._ConcernedNum - 1)
                        plateFrame.unitFrame._isConcerned = false
                        for _, otherPlate in ipairs(Plater.GetAllShownPlates() or {}) do
                            if otherPlate and otherPlate.namePlateUnitToken then
                                UpdateCastHandlingNameplate(otherPlate, true)
                            end
                        end
                        break
                    end
                end
            end
            for unitFrame, _ in pairs(GPlaterDB.CastHandling.topPriorityUnits) do
                if unitFrame.PlateFrame and unitFrame.PlateFrame.namePlateUnitToken == unit then
                    GPlaterDB.CastHandling.topPriorityUnits[unitFrame] = nil
                    if unitFrame._originalLevel then
                        if not InCombatLockdown() then
                            unitFrame.PlateFrame:SetFrameLevel(unitFrame._originalLevel)
                        else
                            GPlaterDB.CastHandling.pendingFrameLevels[unit] = unitFrame._originalLevel
                        end
                        unitFrame._originalLevel = nil
                        unitFrame._castOrder = nil
                    end
                    break
                end
            end
        elseif event:match("^UNIT_SPELLCAST_") or event:match("^UNIT_SPELLCAST_CHANNEL_") then
            OnUnitSpellCast(event, unit)
        end
    end)

    if Plater.UpdatePlateFrame then
        hooksecurefunc(Plater, "UpdatePlateFrame", function(plateFrame)
            if plateFrame and plateFrame.namePlateUnitToken and not isUpdatingCast[plateFrame.namePlateUnitToken] then
                UpdateCastHandlingNameplate(plateFrame, true)
            end
        end)
    end

    return true
end

-- Initialize cast handling
local function UpdateCastHandling()
    FilterSpellsByClassAndSpec()
    C_Timer.After(5, function()
        if not SetupCastHandlingHooks() then
            C_Timer.After(5, SetupCastHandlingHooks)
        end
    end)
end

-- Create Cast Handling content
local function CreateCastHandlingContent(parent)
    if not parent then
        local errorMsg = "Parent frame is nil"
        local errorFrame = CreateFrame("Frame", nil, UIParent)
        local errorText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errorText:SetPoint("CENTER")
        errorText:SetText(string.format(GPlaterL["MODULE_LOAD_ERROR"], "Cast Handling", errorMsg))
        return errorFrame
    end

    local contentFrame = CreateFrame("Frame", nil, parent)
    contentFrame:SetSize(740, 550)

    local success, errorMsg = pcall(function()
        -- Enable Cast Handling
        local enableCastHandlingCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
        enableCastHandlingCheck:SetPoint("TOPLEFT", 20, -40)
        enableCastHandlingCheck:SetSize(26, 26)
        enableCastHandlingCheck.text:SetText(GPlaterL["ENABLE_CAST_HANDLING"])
        enableCastHandlingCheck:SetChecked(GPlaterDB.CastHandling.EnableCastHandling)
        enableCastHandlingCheck:SetScript("OnClick", function(self)
            GPlaterDB.CastHandling.EnableCastHandling = self:GetChecked()
            for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                if plateFrame and plateFrame.namePlateUnitToken then
                    UpdateCastHandlingNameplate(plateFrame, true)
                end
            end
        end)

        -- Show Target Unit
        local showTargetCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
        showTargetCheck:SetPoint("TOPLEFT", 20, -70)
        showTargetCheck:SetSize(26, 26)
        showTargetCheck.text:SetText(GPlaterL["ALWAYS_SHOW_TARGET_UNIT"])
        showTargetCheck:SetChecked(GPlaterDB.CastHandling.config.showOnTargeting)
        showTargetCheck:SetScript("OnClick", function(self)
            GPlaterDB.CastHandling.config.showOnTargeting = self:GetChecked()
            for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                if plateFrame and plateFrame.namePlateUnitToken then
                    UpdateCastHandlingNameplate(plateFrame, true)
                end
            end
        end)

        -- Show Marked Units
        local showMarkCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
        showMarkCheck:SetPoint("TOPLEFT", 20, -100)
        showMarkCheck:SetSize(26, 26)
        showMarkCheck.text:SetText(GPlaterL["ALWAYS_SHOW_MARKED_UNITS"])
        showMarkCheck:SetChecked(GPlaterDB.CastHandling.config.showOnMark)
        showMarkCheck:SetScript("OnClick", function(self)
            GPlaterDB.CastHandling.config.showOnMark = self:GetChecked()
            for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                if plateFrame and plateFrame.namePlateUnitToken then
                    UpdateCastHandlingNameplate(plateFrame, true)
                end
            end
        end)

        -- Spell Table
        local spellTableFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
        spellTableFrame:SetPoint("TOPLEFT", 10, -170)
        spellTableFrame:SetPoint("BOTTOMRIGHT", -10, 60)
        spellTableFrame:SetClipsChildren(true)
        local spellTableContent = CreateFrame("Frame", nil, spellTableFrame)
        spellTableContent:SetSize(710, math.max(400, (#(GPlaterDB.CastHandling.SpellsToMonitor or {}) + 1) * 24 + 30))
        spellTableFrame:SetScrollChild(spellTableContent)
        contentFrame.spellTableContent = spellTableContent

        local headers = {
            GPlaterL["SPELL_ID"],
            GPlaterL["SPELL_NAME"],
            GPlaterL["SPECIAL_ATTENTION"],
            GPlaterL["TOP_PRIORITY"],
            ""
        }
        local columnWidths = {
            100, -- SPELL_ID
            200, -- SPELL_NAME
            100, -- SPECIAL_ATTENTION
            100, -- TOP_PRIORITY
            60   -- DELETE
        }
        local totalWidth = 0
        for _, width in ipairs(columnWidths) do
            totalWidth = totalWidth + width
        end
        local leftOffset = (710 - totalWidth) / 2

        local function CreateTableHeaders()
            local offset = leftOffset
            for i, header in ipairs(headers) do
                local label = spellTableContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
                label:SetPoint("TOPLEFT", offset, -10)
                label:SetSize(columnWidths[i], 20)
                label:SetText(header)
                offset = offset + columnWidths[i]
            end
        end

        local function UpdateSpellTable()
            if spellTableContent.rows then
                for _, row in ipairs(spellTableContent.rows) do
                    for _, widget in ipairs(row) do
                        widget:Hide()
                        widget:ClearAllPoints()
                    end
                end
            end
            spellTableContent.rows = {}

            GPlaterDB.CastHandling.SpellsToMonitor = GPlaterDB.CastHandling.SpellsToMonitor or {}
            local classSpells, otherSpells = {}, {}
            for i, entry in ipairs(GPlaterDB.CastHandling.SpellsToMonitor) do
                local isClassSpell = InterruptClassMap and InterruptClassMap[entry.spellID] and InterruptClassMap[entry.spellID].class == PLAYER_CLASS
                table.insert(isClassSpell and classSpells or otherSpells, { index = i, entry = entry })
            end

            local sortedSpells = {}
            for _, spell in ipairs(classSpells) do table.insert(sortedSpells, spell) end
            for _, spell in ipairs(otherSpells) do table.insert(sortedSpells, spell) end

            for rowIndex, spell in ipairs(sortedSpells) do
                local i = spell.index
                local entry = spell.entry
                local row = {}
                local offset = leftOffset
                local isClassSpell = InterruptClassMap and InterruptClassMap[entry.spellID] and InterruptClassMap[entry.spellID].class == PLAYER_CLASS

                -- Spell ID
                local idEdit = CreateFrame("EditBox", nil, spellTableContent, "InputBoxTemplate")
                idEdit:SetPoint("TOPLEFT", offset + 5, -30 - (rowIndex * 24))
                idEdit:SetSize(columnWidths[1] - 10, 20)
                idEdit:SetAutoFocus(false)
                idEdit:SetText(tostring(entry.spellID))
                idEdit:SetTextColor(isClassSpell and 1 or 0.5, isClassSpell and 1 or 0.5, isClassSpell and 1 or 0.5)
                idEdit:SetJustifyH("LEFT")
                idEdit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
                idEdit:SetScript("OnEditFocusLost", function(self)
                    local text = self:GetText():trim()
                    local spellID = tonumber(text)
                    if spellID and C_Spell.GetSpellName(spellID) then
                        entry.spellID = spellID
                        local spellName = C_Spell.GetSpellName(spellID) or "Unknown"
                        row[2]:SetText(spellName)
                    else
                        print(string.format("|cFFFF0000GPlater: %s|r", string.format(GPlaterL["INVALID_SPELL_ID"], text)))
                        self:SetText(tostring(entry.spellID))
                    end
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateCastHandlingNameplate(plateFrame, true)
                        end
                    end
                end)
                idEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
                row[1] = idEdit
                offset = offset + columnWidths[1]

                -- Spell Name
                local nameText = spellTableContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                nameText:SetPoint("TOPLEFT", offset + 5, -30 - (rowIndex * 24))
                nameText:SetSize(columnWidths[2] - 10, 20)
                nameText:SetJustifyH("LEFT")
                local spellName = C_Spell.GetSpellName(entry.spellID) or "Unknown"
                nameText:SetText(spellName)
                nameText:SetTextColor(isClassSpell and 1 or 0.5, isClassSpell and 1 or 0.5, isClassSpell and 1 or 0.5)
                row[2] = nameText
                offset = offset + columnWidths[2]

                -- Special Attention
                local specialAttentionCheck = CreateFrame("CheckButton", nil, spellTableContent, "UICheckButtonTemplate")
                specialAttentionCheck:SetPoint("TOPLEFT", offset + (columnWidths[3] - 26) / 2, -30 - (rowIndex * 24))
                specialAttentionCheck:SetSize(26, 26)
                specialAttentionCheck:SetChecked(entry.specialAttention)
                specialAttentionCheck:SetScript("OnClick", function(self)
                    entry.specialAttention = self:GetChecked()
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateCastHandlingNameplate(plateFrame, true)
                        end
                    end
                end)
                row[3] = specialAttentionCheck
                offset = offset + columnWidths[3]

                -- Top Priority
                local topPriorityCheck = CreateFrame("CheckButton", nil, spellTableContent, "UICheckButtonTemplate")
                topPriorityCheck:SetPoint("TOPLEFT", offset + (columnWidths[4] - 26) / 2, -30 - (rowIndex * 24))
                topPriorityCheck:SetSize(26, 26)
                topPriorityCheck:SetChecked(entry.topPriority)
                topPriorityCheck:SetScript("OnClick", function(self)
                    entry.topPriority = self:GetChecked()
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateCastHandlingNameplate(plateFrame, true)
                        end
                    end
                end)
                row[4] = topPriorityCheck
                offset = offset + columnWidths[4]

                -- Delete
                local deleteButton = CreateFrame("Button", nil, spellTableContent, "UIPanelButtonTemplate")
                deleteButton:SetPoint("TOPLEFT", offset + (columnWidths[5] - 50) / 2, -30 - (rowIndex * 24))
                deleteButton:SetSize(columnWidths[5] - 10, 20)
                deleteButton:SetText(GPlaterL["DELETE"])
                deleteButton:SetScript("OnClick", function()
                    table.remove(GPlaterDB.CastHandling.SpellsToMonitor, i)
                    UpdateSpellTable()
                    for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
                        if plateFrame and plateFrame.namePlateUnitToken then
                            UpdateCastHandlingNameplate(plateFrame, true)
                        end
                    end
                end)
                row[5] = deleteButton

                -- Create a backdrop frame for the row
                local rowFrame = CreateFrame("Frame", nil, spellTableContent, "BackdropTemplate")
                rowFrame:SetPoint("TOPLEFT", leftOffset, -30 - (rowIndex * 24))
                rowFrame:SetSize(totalWidth, 24)
                rowFrame:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 8,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                rowFrame:SetBackdropColor(0, 0, 0, 0.5)
                rowFrame:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)

                spellTableContent.rows[rowIndex] = row
            end

            -- Add button in the last row of Spell ID column
            local addButton = spellTableContent.addButton or CreateFrame("Button", nil, spellTableContent, "UIPanelButtonTemplate")
            spellTableContent.addButton = addButton
            addButton:SetPoint("TOPLEFT", leftOffset + 5, -30 - ((#sortedSpells + 1) * 24))
            addButton:SetSize(90, 22)
            addButton:SetText(GPlaterL["ADD_SPELL"])
            addButton:Show()
            addButton:SetScript("OnClick", function()
                table.insert(GPlaterDB.CastHandling.SpellsToMonitor, { spellID = 0, specialAttention = false, topPriority = false })
                UpdateSpellTable()
            end)

            spellTableContent:SetHeight((#GPlaterDB.CastHandling.SpellsToMonitor + 2) * 24 + 30)
        end

        contentFrame.CreateTableHeaders = CreateTableHeaders
        contentFrame.UpdateSpellTable = UpdateSpellTable
        contentFrame:CreateTableHeaders()
        contentFrame:UpdateSpellTable()
    end)

    if not success then
        contentFrame:Hide()
        local errorFrame = CreateFrame("Frame", nil, parent)
        local errorText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errorText:SetPoint("CENTER")
        errorText:SetText(string.format(GPlaterL["MODULE_LOAD_ERROR"], "Cast Handling", errorMsg))
        return errorFrame
    end

    return contentFrame
end

----------------------------------------
-- Settings Panel
----------------------------------------

-- Module content creation function
local function createModuleContent(parent, contentFunc, moduleName)
    if not parent or not contentFunc then
        local errorMsg = not parent and "Parent frame is nil" or "Content function is not defined"
        local errorFrame = CreateFrame("Frame", nil, UIParent)
        local errorText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errorText:SetPoint("CENTER")
        errorText:SetText(string.format(GPlaterL["MODULE_LOAD_ERROR"], moduleName, errorMsg))
        return errorFrame
    end

    local success, result = pcall(contentFunc, parent)
    if success and result and result:IsObjectType("Frame") then
        return result
    else
        local errorMsg = success and "Invalid frame returned" or tostring(result)
        local errorFrame = CreateFrame("Frame", nil, parent)
        local errorText = errorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errorText:SetPoint("CENTER")
        errorText:SetText(string.format(GPlaterL["MODULE_LOAD_ERROR"], moduleName, errorMsg))
        return errorFrame
    end
end

function CreateConfigPanel()
    if not _G["Plater"] then return nil end

    local frame = CreateFrame("Frame", "GPlaterConfigFrame", UIParent, "BackdropTemplate")
    if not frame then return nil end
    frame:SetSize(800, 600)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    tinsert(UISpecialFrames, "GPlaterConfigFrame")

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText(GPlaterL["SETTINGS_PANEL_TITLE"]:format(GPlaterL["ADDON_VERSION"]))

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    -- Tabs
    local tabs = { "Aura Coloring", "Cast Handling", "Friendly Nameplates" }
    local tabButtons = {}
    local tabFrames = {}

    -- Define SelectTab function
    local function SelectTab(tabName)
        if not tabName or not tabFrames[tabName] then tabName = "Aura Coloring" end
        GPlaterDB.lastSelectedTab = tabName
        for name, tFrame in pairs(tabFrames) do
            tFrame:SetShown(name == tabName)
        end
        for name, button in pairs(tabButtons) do
            if name == tabName then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
        end
    end

    -- Create tab buttons
    for i, tabName in ipairs(tabs) do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        local tabText = locale == "zhCN" and L["zhCN"][tabName:upper():gsub(" ", "_") .. "_TAB"] or GPlaterL[tabName:upper():gsub(" ", "_") .. "_TAB"] or tabName
        button:SetText(tabText)
        if button.Text then button.Text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE") end
        button:SetPoint("TOPLEFT", 10 + (i-1)*150, -30)
        button:SetSize(150, 22)
        button:SetScript("OnClick", function() SelectTab(tabName) end)
        tabButtons[tabName] = button
    end

    -- Create content frames
    for _, tabName in ipairs(tabs) do
        local contentFrame = CreateFrame("Frame", nil, frame)
        contentFrame:SetPoint("TOPLEFT", 10, -60)
        contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)
        contentFrame:Hide()
        tabFrames[tabName] = contentFrame
    end

    -- Load module contents
    local contentFuncs = {
        ["Aura Coloring"] = CreateAuraColoringContent,
        ["Cast Handling"] = CreateCastHandlingContent,
        ["Friendly Nameplates"] = CreateFriendlyNameplatesContent
    }
    for tabName, contentFunc in pairs(contentFuncs) do
        local content = createModuleContent(tabFrames[tabName], contentFunc, tabName)
        content:SetPoint("TOPLEFT", 0, 0)
        content:SetPoint("BOTTOMRIGHT", 0, 0)
    end

    -- Select last opened tab or default
    SelectTab(GPlaterDB.lastSelectedTab)
    return frame
end

-- Register slash command
SlashCmdList["GPLATER"] = function()
    if not _G["Plater"] then return end
    if not GPlaterConfigFrame then
        GPlaterConfigFrame = CreateConfigPanel()
        if not GPlaterConfigFrame then return end
    end
    GPlaterConfigFrame:SetShown(not GPlaterConfigFrame:IsShown())
end
SLASH_GPLATER1 = "/gp"

----------------------------------------
-- Initialization and Event Handling
----------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CVAR_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        InitializeDatabase()
        if not GPlaterConfigFrame then
            GPlaterConfigFrame = CreateConfigPanel()
            if GPlaterConfigFrame then GPlaterConfigFrame:Hide() end
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    elseif event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_DISABLED" then
        UpdateFriendlyNameplates()
        UpdateAuraColoring()
        UpdateCastHandling()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if GPlaterDB.Friendly and GPlaterDB.Friendly.updateCV then
            UpdateFriendlyNameplates()
            GPlaterDB.Friendly.updateCV = nil
        end
        ApplyPendingFrameLevels()
        for _, plateFrame in ipairs(Plater.GetAllShownPlates() or {}) do
            if plateFrame and plateFrame.namePlateUnitToken then
                UpdateCastHandlingNameplate(plateFrame, true)
            end
        end
    elseif event == "CVAR_UPDATE" then
        UpdateFriendlyNameplatesSize()
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        UpdateAuraColoring()
        UpdateCastHandling()
    end
end)