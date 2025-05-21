local _G = _G
local GPlaterNS = _G.GPlaterNS or {}
GPlaterNS.UI = GPlaterNS.UI or {}

local L = GPlaterNS.L
local Utils = GPlaterNS.Utils
local UI = GPlaterNS.Constants.UI

GPlaterNS.UI.panelFrame = nil
GPlaterNS.UI.auraRowFrames = {}
local isInitialized = false

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "GPlater" then
        C_Timer.After(0.1, function()
            if GPlaterNS.Config then
                isInitialized = true
                GPlaterNS.UI.RegisterSlashCommand()
            else
                Utils:Log("initFrame:OnEvent: Config module missing", 4, "ui")
            end
        end)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

local function SetupTooltip(frame, tooltipText)
    if not tooltipText or not frame then 
        Utils:Log("SetupTooltip: invalid inputs", 4, "ui")
        return 
    end
    if frame:IsObjectType("FontString") then
        local parent = frame:GetParent()
        if parent and parent.SetScript then
            parent:SetScript("OnEnter", function(sF)
                GameTooltip:SetOwner(sF, "ANCHOR_TOP")
                GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            parent:SetScript("OnLeave", function() 
                GameTooltip:Hide()
            end)
        end
    elseif frame.SetScript then
        frame:SetScript("OnEnter", function(sF)
            GameTooltip:SetOwner(sF, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function() 
            GameTooltip:Hide()
        end)
    else
        Utils:Log("SetupTooltip: frame does not support scripts", 4, "ui")
        return
    end
end

local function CreateAuraControl(parent, colDef, auraItem, controlType, scripts, template)
    local frame = CreateFrame(controlType, nil, parent, template)
    frame:SetSize(colDef.width, UI.AURA_CONTROL_DEFAULT_HEIGHT)
    frame.controlType = controlType
    frame.auraItemRef = auraItem
    if colDef.settings and colDef.settings.tooltip then
        SetupTooltip(frame, colDef.settings.tooltip)
    end
    for event, handler in pairs(scripts or {}) do
        frame:SetScript(event, handler)
    end
    return frame
end

local function CreateEditBox(parent, colDef, auraItem, onValueChanged)
    local scripts = {
        OnEnterPressed = function(self)
            local v = self:GetText():match("^%s*(.-)%s*$")
            if colDef.settings.validate and not colDef.settings.validate(v) then
                self:SetText(tostring(colDef.settings.get(auraItem) or ""))
                Utils:Log("CreateEditBox: invalid value '%s' for %s", 4, "ui", v, colDef.title)
                return
            end
            if not onValueChanged(auraItem, v, self) then
                self:SetText(tostring(colDef.settings.get(auraItem) or ""))
                Utils:Log("CreateEditBox: onValueChanged failed for %s", 4, "ui", colDef.title)
            end
            self:ClearFocus()
        end,
        OnEscapePressed = function(self)
            self:SetText(tostring(colDef.settings.get(auraItem) or ""))
            self:ClearFocus()
        end,
    }
    local eb = CreateAuraControl(parent, colDef, auraItem, "EditBox", scripts, "InputBoxTemplate")
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontHighlight")
    if colDef.settings.isNumeric then 
        eb:SetNumeric(true)
    end
    eb:SetText(tostring(colDef.settings.get(auraItem) or ""))
    eb:SetTextColor(1, 1, 1, 1)
    eb:SetAlpha(1)
    eb:SetTextInsets(3, 3, 3, 3)
    return eb
end

local function CreateColorButton(parent, colDef, auraItem, onColorChanged, onApplyToggle)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(UI.AURA_COLORBUTTON_WIDTH, UI.AURA_COLORBUTTON_HEIGHT)
    button.controlType = "ColorButton"
    button.normalTexture = button:CreateTexture(nil, "BACKGROUND")
    button.normalTexture:SetAllPoints()
    button.normalTexture:SetColorTexture(0.2, 0.2, 0.2)
    button.colorTexture = button:CreateTexture(nil, "OVERLAY")
    button.colorTexture:SetAllPoints()
    button.colorTexture:SetDrawLayer("OVERLAY", 1)
    button.disabledIcon = button:CreateTexture(nil, "OVERLAY")
    button.disabledIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    button.disabledIcon:SetPoint("CENTER")
    button.disabledIcon:SetDrawLayer("OVERLAY", 7)
    button.disabledIcon:SetAlpha(1)
    button.lastToggleTime = 0

    local defaultHex = (GPlaterNS.DefaultAuraSettings or {}).healthBarColor or GPlaterNS.Constants.DEFAULT_COLOR
    button.currentHex = colDef.settings.get(auraItem) or defaultHex
    local r, g, b = Utils:HexToRGB(button.currentHex)
    if button.colorTexture and r and g and b then
        button.colorTexture:SetColorTexture(r, g, b)
    else
        Utils:Log("CreateColorButton: invalid color %s", 4, "ui", button.currentHex)
    end

    -- Set initial visibility based on apply state
    local isApplied = colDef.settings.getApply(auraItem)
    button.colorTexture:SetShown(isApplied)
    button.disabledIcon:SetShown(not isApplied)

    if colDef.settings.tooltip then
        SetupTooltip(button, colDef.settings.tooltip)
    end

    button:SetScript("OnClick", function(self)
        local cHxC = colDef.settings.get(auraItem) or defaultHex
        local cRval, cGval, cBVal = Utils:HexToRGB(cHxC)
        if not cRval then
            cRval, cGval, cBVal = 1, 0, 0
            Utils:Log("CreateColorButton: invalid color %s", 4, "ui", cHxC)
        end
        button.hCOPO = cHxC
        ColorPickerFrame:SetupColorPickerAndShow({
            r = cRval, g = cGval, b = cBVal, opacity = 1, hasOpacity = false,
            swatchFunc = function()
                local sRval, sGval, sBval = ColorPickerFrame:GetColorRGB()
                local fH = string.format("#%02X%02X%02X", math.floor(sRval * 255 + 0.5), math.floor(sGval * 255 + 0.5), math.floor(sBval * 255 + 0.5))
                button.currentHex = fH
                if button.colorTexture then
                    button.colorTexture:SetColorTexture(sRval, sGval, sBval)
                end
                onColorChanged(auraItem, fH)
                -- Ensure colorTexture is shown and disabledIcon is hidden after color change
                button.colorTexture:Show()
                button.disabledIcon:Hide()
            end,
            cancelFunc = function()
                local rRval, rGval, rBval = Utils:HexToRGB(button.hCOPO)
                button.currentHex = button.hCOPO
                if button.colorTexture and rRval and rGval and rBval then
                    button.colorTexture:SetColorTexture(rRval, rGval, rBval)
                end
                -- Restore visibility based on apply state
                local currentApplyState = colDef.settings.getApply(auraItem)
                button.colorTexture:SetShown(currentApplyState)
                button.disabledIcon:SetShown(not currentApplyState)
            end,
            opacityFunc = function() end,
        })
    end)
    button:SetScript("OnMouseDown", function(self, bN)
        if bN == "RightButton" then
            local currentTime = GetTime()
            if currentTime - self.lastToggleTime < 0.5 then
                return
            end
            self.lastToggleTime = currentTime
            local cAS = colDef.settings.getApply(auraItem)
            onApplyToggle(auraItem, not cAS)
            -- Update visibility based on new apply state
            local newApplyState = not cAS
            button.colorTexture:SetShown(newApplyState)
            button.disabledIcon:SetShown(not newApplyState)
            GPlaterNS.UI.UpdateAuraRowControlsByAuraID(auraItem.auraID)
        end
    end)
    return button
end

local function CreateCheckButton(parent, colDef, auraItem, onToggle)
    local scripts = {
        OnClick = function(self)
            onToggle(auraItem, self:GetChecked())
        end,
    }
    local cB = CreateAuraControl(parent, colDef, auraItem, "CheckButton", scripts, "UICheckButtonTemplate")
    cB:SetChecked(colDef.settings.get(auraItem))
    return cB
end

local function CreateDropdown(parent, colDef, auraItem, onSelectionChanged)
    local dd = CreateAuraControl(parent, colDef, auraItem, "Frame", nil, "UIDropDownMenuTemplate")
    local function OnClick(sDI)
        UIDropDownMenu_SetSelectedValue(dd, sDI.value)
        onSelectionChanged(auraItem, sDI.value)
    end
    local function Init(sDD)
        local i = UIDropDownMenu_CreateInfo()
        for _, iD in ipairs(colDef.settings.items) do
            i.text = iD.text
            i.value = iD.value
            i.func = OnClick
            i.checked = (iD.value == (colDef.settings.get(auraItem) or colDef.settings.default))
            if iD.tooltip then
                i.tooltipText = iD.tooltip
                i.tooltipOnButton = true
            end
            UIDropDownMenu_AddButton(i)
        end
    end
    dd.initializeFunc = Init
    UIDropDownMenu_Initialize(dd, Init)
    UIDropDownMenu_SetWidth(dd, colDef.width)
    UIDropDownMenu_SetSelectedValue(dd, colDef.settings.get(auraItem) or colDef.settings.default)
    return dd
end

local function GetAuraTableColumns()
    local DAS = GPlaterNS.DefaultAuraSettings or {}
    local columns = {
        { title = "", width = UI.AURA_COLUMN_1_WIDTH, x = UI.AURA_COLUMN_1_X, type = "Delete", settings = {} },
        { title = L("AURA_ID", "AuraID"), width = UI.AURA_COLUMN_2_WIDTH, x = UI.AURA_COLUMN_2_X, type = "FontString", settings = {
            -- Inside GetAuraTableColumns, for "AURA_ID" column:
            get = function(a)
                local displayId = tostring(a.auraID)
                if type(a.auraID) == "number" then
                    local spellInfo = C_Spell.GetSpellInfo(a.auraID)
                    local name = spellInfo and spellInfo.name
                    return name and (displayId .. " " .. name) or displayId
                else -- It's a comma-separated string
                    return displayId -- Display the "123,456" string directly
                end
            end,
        } },
        { title = L("SKILL_ID", "SkillID"), width = UI.AURA_COLUMN_3_WIDTH, x = UI.AURA_COLUMN_3_X, type = "EditBox", settings = {
            get = function(a) 
                return tostring(a.skillID or 0)
            end,
            validate = function(v) 
                return GPlaterNS.Config:ValidateAuraProperty("skillID", v)
            end,
            tooltip = L("HELP_SKILL_ID", "Enter the skill ID or comma-separated skill IDs. All must be known for the effect to be active (0 for none)."),
            isSkillID = true,
        } },
        { title = L("AURA_MIN_STACKS", "MinStk"), width = UI.AURA_COLUMN_4_WIDTH, x = UI.AURA_COLUMN_4_X, type = "EditBox", settings = {
            get = function(a) 
                local result = tostring(a.minStacks or 0)
                return result 
            end,
            validate = function(v) 
                local success = GPlaterNS.Config:ValidateAuraProperty("minStacks", tonumber(v))
                return success
            end,
            tooltip = L("HELP_AURA_MIN_STACKS", "Set the minimum stacks for the aura to take effect (0 for no restriction)."), isNumeric = true,
        } },
        { title = L("AURA_PLATE", "Plate"), width = UI.AURA_COLUMN_5_WIDTH, x = UI.AURA_COLUMN_5_X, type = "ColorButton", settings = {
            get = function(a) 
                local result = a.healthBarColor or DAS.healthBarColor
                return result 
            end,
            getApply = function(a)
                local result = a.applyHealthBar
                return result 
            end,
            tooltip = L("HELP_AURA_PLATE_COLOR", "Set the health bar color triggered by the aura (left-click to choose color, right-click to toggle enable/disable)."),
        } },
        { title = L("AURA_TEXT", "Text"), width = UI.AURA_COLUMN_6_WIDTH, x = UI.AURA_COLUMN_6_X, type = "ColorButton", settings = {
            get = function(a) 
                local result = a.nameTextColor or DAS.nameTextColor
                return result 
            end,
            getApply = function(a) 
                local result = a.applyNameText
                return result 
            end,
            tooltip = L("HELP_AURA_TEXT_COLOR", "Set the name text color triggered by the aura (left-click to choose color, right-click to toggle enable/disable)."),
        } },
        { title = L("AURA_BORDER", "Border"), width = UI.AURA_COLUMN_7_WIDTH, x = UI.AURA_COLUMN_7_X, type = "ColorButton", settings = {
            get = function(a) 
                local result = a.borderColor or DAS.borderColor
                return result 
            end,
            getApply = function(a) 
                local result = a.applyBorder
                return result 
            end,
            tooltip = L("HELP_AURA_BORDER_COLOR", "Set the border color triggered by the aura (left-click to choose color, right-click to toggle enable/disable)."),
        } },
        { title = L("AURA_SCALE", "Scale"), width = UI.AURA_COLUMN_8_WIDTH, x = UI.AURA_COLUMN_8_X, type = "EditBox", settings = {
            get = function(a) 
                local result = tostring(math.floor((a.scale or DAS.scale) * 100 + 0.5))
                return result 
            end,
            validate = function(v) 
                local success = GPlaterNS.Config:ValidateAuraProperty("scale", tonumber(v) / 100)
                return success
            end,
            tooltip = L("HELP_AURA_SCALE", "Set the nameplate scale triggered by the aura (50%-300%)."), isNumeric = true, isAuraScale = true,
        } },
        { title = L("AURA_EFFECT", "Effect"), width = UI.AURA_COLUMN_9_WIDTH, x = UI.AURA_COLUMN_9_X, type = "Dropdown", settings = {
            items = {
                { text = L("AURA_EFFECT_NONE", "None"), value = GPlaterNS.Constants.EFFECT_TYPE_NONE },
                { text = L("AURA_EFFECT_FLASH", "Flash"), value = GPlaterNS.Constants.EFFECT_TYPE_FLASH },
                { text = L("AURA_EFFECT_HIDE", "Hide"), value = GPlaterNS.Constants.EFFECT_TYPE_HIDE },
                { text = L("AURA_EFFECT_TOP", "Top"), value = GPlaterNS.Constants.EFFECT_TYPE_TOP },
                { text = L("AURA_EFFECT_LOW", "Low"), value = GPlaterNS.Constants.EFFECT_TYPE_LOW },
                { text = L("AURA_EFFECT_UNIQUE", "Unique"), value = GPlaterNS.Constants.EFFECT_TYPE_UNIQUE, tooltip = L("HELP_AURA_EFFECT_UNIQUE", "Selecting the Only effect will show only this aura's nameplate, hiding all other nameplates.") },
            },
            get = function(a) 
                local result = a.effect or GPlaterNS.Constants.EFFECT_TYPE_NONE
                return result 
            end,
            default = GPlaterNS.Constants.EFFECT_TYPE_NONE,
            tooltip = L("HELP_AURA_EFFECT", "Select the visual effect triggered by the aura (None, Flash, Hide, Top, Low, Only)."),
        } },
        { title = L("AURA_CANCEL_30_PERCENT", "Cancel30%"), width = UI.AURA_COLUMN_10_WIDTH, x = UI.AURA_COLUMN_10_X, type = "CheckButton", settings = {
            get = function(a) 
                local result = a.cancelAt30Percent or false
                return result 
            end,
            tooltip = L("HELP_AURA_CANCEL_30_PERCENT", "When enabled, cancel aura effects when the aura's duration falls below 30%."),
        } },
    }
    return columns
end

function SaveAuraConfig(auraItemToSave, changedField, newValue)
    local specID = GPlaterNS.Config:GetCurrentSpecID()
    if not specID then
        Utils:Log("SaveAuraConfig: no specID", 4, "ui")
        return false
    end
    local aurasFromConfig = GPlaterNS.Config:Get({"AuraColoring", "auras"}, {})
    local updatedAurasList = {}
    local foundAndUpdated = false

    for _, existingAura in ipairs(aurasFromConfig) do
        if existingAura.auraID == auraItemToSave.auraID then
            -- 修复错误 5：创建完整副本并同步所有字段
            local updatedAura = Utils:MergeTables({}, auraItemToSave)
            table.insert(updatedAurasList, updatedAura)
            foundAndUpdated = true
        else
            table.insert(updatedAurasList, Utils:MergeTables({}, existingAura))
        end
    end

    if not foundAndUpdated then
        table.insert(updatedAurasList, Utils:MergeTables({}, auraItemToSave))
    end

    -- 修复错误 5：同步 skillID 和 isKnown
    if changedField == L("SKILL_ID", "SkillID") then
        auraItemToSave.skillID = newValue
        auraItemToSave.isKnown = Utils:CalculateIsKnown(auraItemToSave.skillID)
        Utils:Log("SaveAuraConfig: SkillID changed for AuraID %s to [%s]. Calculated isKnown for auraItemToSave: %s", 2, "ui", tostring(auraItemToSave.auraID), tostring(auraItemToSave.skillID), tostring(auraItemToSave.isKnown))
        for _, itemInList in ipairs(updatedAurasList) do
            if itemInList.auraID == auraItemToSave.auraID then
                itemInList.skillID = auraItemToSave.skillID
                itemInList.isKnown = auraItemToSave.isKnown
                break
            end
        end
    end

    local success = GPlaterNS.Config:Set({"AuraColoring", "auras"}, updatedAurasList)

    if success then
        Utils:Log("SaveAuraConfig: Config:Set successful for auras. Changed field: %s", 2, "ui", changedField)
        GPlaterNS.UI.UpdateAuraRowControlsByAuraID(auraItemToSave.auraID)
    else
        Utils:Log("SaveAuraConfig: failed to save auras via Config:Set. Field: %s, Value: %s", 4, "ui", changedField, tostring(newValue))
    end
    return success
end

function GPlaterNS.UI.ConfigureAuraRowControls(parentScrollChild, auraItem, yOffset, existingRowFrame)
    if not auraItem or not auraItem.auraID or not parentScrollChild:IsObjectType("Frame") then
        Utils:Log("ConfigureAuraRowControls: invalid inputs", 4, "ui")
        return nil
    end
    local rFKey = "GPlaterAuraRow_" .. tostring(auraItem.auraID)
    local rF = existingRowFrame or CreateFrame("Frame", rFKey, parentScrollChild)
    rF:SetPoint("TOPLEFT", 0, yOffset)
    rF:SetSize(UI.AURA_ROW_WIDTH, UI.AURA_ROW_HEIGHT)
    rF.auraID = auraItem.auraID
    rF.controls = rF.controls or {}
    local cols = GetAuraTableColumns()
    local rowFrameActualWidth = rF:GetWidth()
    local isKnown = auraItem.isKnown or false
    local isCombinationAura = tostring(auraItem.auraID):find(",", 1, true) ~= nil

    local baseTextColorR, baseTextColorG, baseTextColorB
    local baseAlpha
    if isKnown then
        baseTextColorR, baseTextColorG, baseTextColorB = 1, 1, 1
        baseAlpha = 1
    else
        baseTextColorR, baseTextColorG, baseTextColorB = 0.5, 0.5, 0.5
        baseAlpha = 0.7
    end

    for idx, cD in ipairs(cols) do
        local ctrl = nil
        for _, existingCtrl in ipairs(rF.controls) do
            if existingCtrl.colDef.title == cD.title and existingCtrl.colDef.type == cD.type then
                ctrl = existingCtrl.widget
                break
            end
        end

        if cD.type == "Delete" then
            if not ctrl then
                ctrl = CreateFrame("Button", nil, rF, "UIPanelButtonTemplate")
                ctrl:SetSize(UI.AURA_DELETE_BUTTON_WIDTH, UI.AURA_DELETE_BUTTON_HEIGHT)
                ctrl:SetText("X")
                ctrl:SetScript("OnClick", function()
                    GPlaterNS.UI.RemoveAuraRow(auraItem.auraID)
                end)
            end
        elseif cD.type == "FontString" then
            if not ctrl then
                ctrl = rF:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                if cD.settings.tooltip then
                    SetupTooltip(ctrl, cD.settings.tooltip)
                end
            end
            ctrl:SetText(tostring(cD.settings.get(auraItem) or ""))
            ctrl:SetJustifyH("CENTER")
            ctrl:SetJustifyV("MIDDLE")
            ctrl:SetTextColor(baseTextColorR, baseTextColorG, baseTextColorB)
            ctrl:SetAlpha(baseAlpha)
        elseif cD.type == "EditBox" then
            if cD.title == L("AURA_MIN_STACKS", "MinStk") and isCombinationAura then
                if not ctrl or ctrl:IsObjectType("EditBox") then
                    if ctrl then
                        ctrl:Hide()
                    end
                    ctrl = rF:CreateTexture(nil, "OVERLAY")
                    ctrl:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                    ctrl:SetSize(UI.AURA_CONTROL_DEFAULT_HEIGHT, UI.AURA_CONTROL_DEFAULT_HEIGHT)
                    ctrl:SetAlpha(baseAlpha)
                end
            elseif not ctrl then
                ctrl = CreateEditBox(rF, cD, auraItem, function(itm, val_str)
                    local fN = cD.title
                    local valueToSave = val_str
                    if fN == L("AURA_SCALE", "Scale") then
                        local nV = tonumber(val_str)
                        local actualScaleValue = nV / 100
                        itm.scale = actualScaleValue
                        itm.applyScale = (nV ~= 100)
                        valueToSave = actualScaleValue
                    elseif fN == L("SKILL_ID", "SkillID") then
                        itm.skillID = val_str
                        valueToSave = val_str
                    elseif fN == L("AURA_MIN_STACKS", "MinStk") then
                        local nV = tonumber(val_str) or 0
                        itm.minStacks = nV
                        valueToSave = nV
                    end
                    return SaveAuraConfig(itm, fN, valueToSave)
                end)
            end
            if cD.title ~= L("AURA_MIN_STACKS", "MinStk") then
                ctrl:SetText(tostring(cD.settings.get(auraItem) or ""))
                ctrl:SetTextColor(baseTextColorR, baseTextColorG, baseTextColorB)
                ctrl:SetAlpha(baseAlpha)
                ctrl:SetEnabled(cD.title ~= L("AURA_ID", "AuraID"))
            end
        elseif cD.type == "ColorButton" then
            if not ctrl then
                ctrl = CreateColorButton(rF, cD, auraItem, function(itm, hV)
                    local fN = cD.title
                    if fN == L("AURA_PLATE", "Plate") then
                        itm.healthBarColor = hV
                    elseif fN == L("AURA_TEXT", "Text") then
                        itm.nameTextColor = hV
                    elseif fN == L("AURA_BORDER", "Border") then
                        itm.borderColor = hV
                    end
                    SaveAuraConfig(itm, fN, hV)
                end, function(itm, aS)
                    local fN = cD.title
                    if fN == L("AURA_PLATE", "Plate") then
                        itm.applyHealthBar = aS
                    elseif fN == L("AURA_TEXT", "Text") then
                        itm.applyNameText = aS
                    elseif fN == L("AURA_BORDER", "Border") then
                        itm.applyBorder = aS
                    end
                    SaveAuraConfig(itm, fN .. "_apply", aS)
                end)
            end
            local newHexValue = cD.settings.get(auraItem)
            ctrl.currentHex = newHexValue
            if ctrl.colorTexture then
                local r, g, b = Utils:HexToRGB(newHexValue)
                ctrl.colorTexture:SetColorTexture(r or 1, g or 0, b or 0)
            end
            if ctrl.disabledIcon then
                ctrl.colorTexture:SetShown(cD.settings.getApply(auraItem))
                ctrl.disabledIcon:SetShown(not cD.settings.getApply(auraItem))
            end
        elseif cD.type == "Dropdown" then
            if not ctrl then
                ctrl = CreateDropdown(rF, cD, auraItem, function(itm, val)
                    itm.effect = val
                    SaveAuraConfig(itm, "effect", val)
                end)
            end
            UIDropDownMenu_SetSelectedValue(ctrl, cD.settings.get(auraItem) or cD.settings.default)
            UIDropDownMenu_Initialize(ctrl, ctrl.initializeFunc)
            ctrl:SetAlpha(baseAlpha)
            if ctrl.Text then
                ctrl.Text:SetAlpha(isKnown and 1 or 0.5)
            end
        elseif cD.type == "CheckButton" then
            if cD.title == L("AURA_CANCEL_30_PERCENT", "Cancel30%") and isCombinationAura then
                if not ctrl or ctrl:IsObjectType("CheckButton") then
                    if ctrl then
                        ctrl:Hide()
                    end
                    ctrl = rF:CreateTexture(nil, "OVERLAY")
                    ctrl:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                    ctrl:SetSize(UI.AURA_CHECKBUTTON_WIDTH, UI.AURA_CHECKBUTTON_HEIGHT)
                    ctrl:SetAlpha(baseAlpha)
                end
            elseif not ctrl then
                ctrl = CreateCheckButton(rF, cD, auraItem, function(itm, val)
                    itm.cancelAt30Percent = val
                    SaveAuraConfig(itm, "cancelAt30Percent", val)
                end)
                ctrl:SetSize(UI.AURA_CHECKBUTTON_WIDTH, UI.AURA_CHECKBUTTON_HEIGHT)
            end
            if cD.title ~= L("AURA_CANCEL_30_PERCENT", "Cancel30%") or not isCombinationAura then
                ctrl:SetChecked(cD.settings.get(auraItem))
                ctrl:SetAlpha(baseAlpha)
                if ctrl.Text then
                    ctrl.Text:SetAlpha(baseAlpha)
                end
            end
        end

        if ctrl then
            local actualControlWidth = ctrl:GetWidth() or cD.width
            local columnCellStartX = cD.x
            local columnCellEndX = idx < #cols and cols[idx + 1].x or rowFrameActualWidth
            local columnCellWidth = columnCellEndX - columnCellStartX
            local offsetX = columnCellWidth > actualControlWidth and (columnCellWidth - actualControlWidth) / 2 or 0
            ctrl:ClearAllPoints()
            ctrl:SetPoint("LEFT", columnCellStartX + offsetX, 0)

            local foundInControls = false
            for _, c in ipairs(rF.controls) do
                if c.widget == ctrl then
                    foundInControls = true
                    break
                end
            end
            if not foundInControls then
                table.insert(rF.controls, { widget = ctrl, colDef = cD })
            end
            ctrl:Show()
        end
    end
    GPlaterNS.UI.auraRowFrames[tostring(auraItem.auraID)] = rF
    rF:Show()
    return rF
end

function GPlaterNS.UI.CreateAuraRowControls(parentScrollChild, auraItem, yOffset)
    return GPlaterNS.UI.ConfigureAuraRowControls(parentScrollChild, auraItem, yOffset, nil)
end

function GPlaterNS.UI.UpdateAuraRowControls(rowFrame, auraItem)
    if not rowFrame or not auraItem then
        Utils:Log("UpdateAuraRowControls: invalid inputs", 4, "ui")
        return
    end
    GPlaterNS.UI.ConfigureAuraRowControls(rowFrame:GetParent(), auraItem, rowFrame:GetTop() - rowFrame:GetParent():GetTop(), rowFrame)
end

function GPlaterNS.UI.UpdateAuraRowControlsByAuraID(auraID)
    local rowFrame = GPlaterNS.UI.auraRowFrames[tostring(auraID)]
    if not rowFrame then 
        Utils:Log("UpdateAuraRowControlsByAuraID: no row frame for auraID=%d", 4, "ui", auraID)
        return 
    end
    local auras = GPlaterNS.Config:Get({"AuraColoring", "auras"}, {})
    local auraItem = nil
    for _, a in ipairs(auras) do
        if a.auraID == auraID then
            auraItem = a
            break
        end
    end
    if auraItem then
        GPlaterNS.UI.UpdateAuraRowControls(rowFrame, auraItem)
    else
        Utils:Log("UpdateAuraRowControlsByAuraID: no aura item for auraID=%d", 4, "ui", auraID)
    end
end

function GPlaterNS.UI.RemoveAuraRow(auraIDToRemove)
    local specID = GPlaterNS.Config:GetCurrentSpecID()
    if not specID then
        Utils:Log("RemoveAuraRow: no specID", 4, "ui")
        return
    end
    local auras = GPlaterNS.Config:Get({"AuraColoring", "auras"}, {})
    local newAuras = {}
    local auraWasInConfig = false
    for _, aura in ipairs(auras) do
        if aura.auraID == auraIDToRemove then
            auraWasInConfig = true
        else
            table.insert(newAuras, aura)
        end
    end
    local configSaveSuccess = false
    if auraWasInConfig then
        configSaveSuccess = GPlaterNS.Config:Set({"AuraColoring", "auras"}, newAuras)
    else
        configSaveSuccess = true
    end
    if configSaveSuccess then
        local rowFrameKey = tostring(auraIDToRemove)
        local rowFrame = GPlaterNS.UI.auraRowFrames[rowFrameKey]
        if rowFrame then
            rowFrame:Hide()
            for i = #rowFrame.controls, 1, -1 do
                local controlData = rowFrame.controls[i]
                if controlData and controlData.widget then
                    local widget = controlData.widget
                    if widget:IsObjectType("Frame") and widget.SetParent then
                        widget:SetParent(nil)
                    end
                    if widget.Release then
                        widget:Release()
                    end
                    rowFrame.controls[i] = nil
                end
            end
            rowFrame:ClearAllPoints()
            rowFrame:SetParent(nil)
            GPlaterNS.UI.auraRowFrames[rowFrameKey] = nil
            GPlaterNS.UI.LayoutAuraRows()
        end
    else
        Utils:Log("RemoveAuraRow: failed to save config", 4, "ui")
    end
end

local function sortAuraItemsByTypeAndID(a, b)
    local idA_raw = a.auraID
    local idB_raw = b.auraID
    local typeA = type(idA_raw)
    local typeB = type(idB_raw)

    if typeA == typeB then
        -- If types are the same, compare directly
        -- (numbers numerically, strings lexicographically)
        return idA_raw < idB_raw
    else
        -- If types differ, prioritize numbers before strings
        return typeA == "number"
    end
end

local function manageNoDataText(scrollChild, itemCount, noDataMessage)
    if not scrollChild then return end

    if itemCount == 0 then
        if not scrollChild.noDataText then
            scrollChild.noDataText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight") --
            scrollChild.noDataText:SetPoint("CENTER") --
        end
        scrollChild.noDataText:SetText(noDataMessage) --
        scrollChild.noDataText:Show() --
    else
        if scrollChild.noDataText then
            scrollChild.noDataText:Hide() --
        end
    end
end

function GPlaterNS.UI.LayoutAuraRows()
    local content = GPlaterNS.UI.panelFrame and GPlaterNS.UI.panelFrame.content
    if not content or not content.auraScrollChild then
        Utils:Log("LayoutAuraRows: no content or scroll child", 4, "ui")
        return
    end
    local specID = GPlaterNS.Config:GetCurrentSpecID()
    if not specID then
        Utils:Log("LayoutAuraRows: no specID", 4, "ui")
        return
    end
    local items = GPlaterNS.Config:Get({"AuraColoring", "auras"}, {})
    table.sort(items, sortAuraItemsByTypeAndID)
    local yOffset = 0
    local rowHeight = UI.AURA_ROW_LAYOUT_HEIGHT
    manageNoDataText(content.auraScrollChild, #items, L("NO_AURA_DATA", "No Aura Data"))
    for idx, auraItem in ipairs(items) do
        local rowFrameKey = tostring(auraItem.auraID)
        local rowFrame = GPlaterNS.UI.auraRowFrames[rowFrameKey]
        if rowFrame then
            rowFrame:ClearAllPoints()
            rowFrame:SetPoint("TOPLEFT", 0, -yOffset)
            GPlaterNS.UI.UpdateAuraRowControls(rowFrame, auraItem)
            rowFrame:Show()
            yOffset = yOffset + rowHeight
        end
    end
    content.auraScrollChild:SetHeight(math.max(yOffset, UI.AURA_SCROLLCHILD_HEIGHT))
end

function GPlaterNS.UI.UpdateAuraTable(content)
    if not content or not content.auraScrollChild then
        Utils:Log("UpdateAuraTable: no content or scroll child", 4, "ui")
        return
    end
    local specID = GPlaterNS.Config:GetCurrentSpecID()
    if not specID then
        Utils:Log("UpdateAuraTable: no specID", 4, "ui")
        return
    end
    local items = GPlaterNS.Config:Get({"AuraColoring", "auras"}, {})
    table.sort(items, sortAuraItemsByTypeAndID)
    local currentAuraIDsInUI = {}
    for idKey, _ in pairs(GPlaterNS.UI.auraRowFrames) do 
        currentAuraIDsInUI[idKey] = true 
    end
    local configAuraIDs = {}
    local yOffset = 0
    for idx, auraItem in ipairs(items) do
        local rowFrameKey = tostring(auraItem.auraID)
        configAuraIDs[rowFrameKey] = true
        local rowFrame = GPlaterNS.UI.auraRowFrames[rowFrameKey]
        GPlaterNS.UI.ConfigureAuraRowControls(content.auraScrollChild, auraItem, -yOffset, rowFrame)
        yOffset = yOffset + UI.AURA_ROW_LAYOUT_HEIGHT
    end
    for idKeyInUI, _ in pairs(currentAuraIDsInUI) do
        if not configAuraIDs[idKeyInUI] then
            GPlaterNS.UI.RemoveAuraRow(tonumber(idKeyInUI))
        end
    end
    GPlaterNS.UI.LayoutAuraRows()
    manageNoDataText(content.auraScrollChild, #items, L("NO_AURA_DATA", "No Aura Data"))
    if content.auraListFrame then 
        content.auraListFrame:Show()
    end
end

function GPlaterNS.UI.SetupAuraHeader(headerFrame)
    local columns = GetAuraTableColumns()
    local headerFrameActualWidth = headerFrame:GetWidth()
    for idx, colDef in ipairs(columns) do
        if colDef.type ~= "Delete" and colDef.title and colDef.title ~= "" then
            local text = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetText(colDef.title)
            text:SetTextColor(1, 1, 1)
            if colDef.settings and colDef.settings.tooltip then
                SetupTooltip(text, colDef.settings.tooltip)
            end
            local columnCellStartX = colDef.x
            local columnCellEndX = idx < #columns and columns[idx + 1].x or headerFrameActualWidth
            local columnCellWidth = columnCellEndX - columnCellStartX
            if columnCellWidth > 0 then
                text:SetWidth(columnCellWidth)
                text:SetJustifyH("CENTER")
                text:SetJustifyV("MIDDLE")
                text:SetPoint("TOPLEFT", columnCellStartX, 0)
            else
                text:SetPoint("LEFT", colDef.x + 5, 0)
            end
        end
    end
end

function GPlaterNS.UI.CreateConfigControl(parent, type, opt)
    local D = {x=0, y=0, w=100, h=20, label="", path={}, def=nil, tip="", cvar=nil, cvarInvert=false}
    opt = Utils:MergeTables(D, opt or {})
    local f
    if type == "CheckButton" then
        f = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        f:SetSize(opt.w, opt.h)
        local t = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        t:SetPoint("LEFT", f, "RIGHT", UI.DEBUG_CHECKBOX_TEXT_OFFSET_X, 0)
        t:SetText(opt.label)
        f.labelText = t
        f:SetChecked(GPlaterNS.Config:Get(opt.path, opt.def))
        f:SetScript("OnClick", function(s)
            GPlaterNS.Config:SafeConfigChange(s, opt.label, opt.cvar, opt.path, s:GetChecked(), opt.cvarInvert)
            if opt.path[1] == "Debug" and opt.path[2] == "enabled" then
                GPlaterNS.UI.UpdateDebugControlsVisibility(parent)
            end
        end)
        -- 验证大小
        local actualW, actualH = f:GetSize()
        if actualW ~= opt.w or actualH ~= opt.h then
            Utils:Log("CreateConfigControl: CheckButton %s size mismatch, set w=%d, h=%d, actual w=%d, h=%d", 3, "ui", opt.label, opt.w, opt.h, actualW, actualH)
            f:SetSize(opt.w, opt.h) -- 再次尝试设置
        end
    elseif type == "Dropdown" then
        f = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
        UIDropDownMenu_SetWidth(f, opt.w)
        if opt.label and opt.label ~= "" then
            local t = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            t:SetPoint("RIGHT", f, "LEFT", -5, 0)
            t:SetPoint("TOP", f, "TOP", 0, 0)
            t:SetText(opt.label)
            SetupTooltip(t, opt.tip)
        end
        local cur = GPlaterNS.Config:Get(opt.path, opt.def)
        local function OnChange(s) 
            UIDropDownMenu_SetSelectedValue(f, s.value)
            GPlaterNS.Config:SafeConfigChange(f, opt.label or "Dropdown", nil, opt.path, s.value)
        end
        local function Init(s)
            local i = UIDropDownMenu_CreateInfo()
            for _, item in ipairs(opt.items()) do
                i.text = item.text
                i.value = item.value
                i.func = OnChange
                i.checked = (item.value == cur)
                UIDropDownMenu_AddButton(i)
            end
        end
        UIDropDownMenu_Initialize(f, Init)
        UIDropDownMenu_SetSelectedValue(f, cur)
    elseif type == "EditBox" then
        local t = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOPLEFT", opt.x, opt.y)
        t:SetText(opt.label)
        f = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        f:SetPoint("LEFT", t, "RIGHT", 10, 0)
        f:SetSize(opt.w, opt.h)
        f:SetAutoFocus(false)
        f:SetFontObject("GameFontHighlight")
        f:SetText(tostring(GPlaterNS.Config:Get(opt.path, opt.def) or opt.def))
        f:SetScript("OnEnterPressed", function(s)
            local val = opt.isNumeric and tonumber(s:GetText()) or s:GetText()
            if opt.isNumeric and not val then
                s:SetText(tostring(GPlaterNS.Config:Get(opt.path, opt.def) or opt.def))
                s:ClearFocus()
                Utils:Log("CreateConfigControl: invalid numeric value for %s", 4, "ui", opt.label)
                return
            end
            local success = GPlaterNS.Config:SafeConfigChange(s, opt.label, nil, opt.path, val)
            if not success then
                s:SetText(tostring(GPlaterNS.Config:Get(opt.path, opt.def) or opt.def))
                Utils:Log("CreateConfigControl: EditBox config change failed for %s", 4, "ui", opt.label)
            end
            s:ClearFocus()
        end)
        f:SetScript("OnEscapePressed", function(s)
            s:SetText(tostring(GPlaterNS.Config:Get(opt.path, opt.def) or opt.def))
            s:ClearFocus()
        end)
        SetupTooltip(t, opt.tip)
    elseif type == "Slider" then
        f = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
        f:SetWidth(opt.w)
        f:SetMinMaxValues(opt.min, opt.max)
        f:SetValueStep(opt.step)
        f.Low:SetText(tostring(opt.min))
        f.High:SetText(tostring(opt.max))
        f.Text:SetText(opt.label)
        f:SetValue(GPlaterNS.Config:Get(opt.path, opt.def) or opt.def)
        f.valueText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        f.valueText:SetPoint("TOP", f, "BOTTOM", 0, -5)
        f.valueText:SetText(tostring(f:GetValue()))
        f:SetScript("OnValueChanged", function(s, val)
            val = math.floor((val / opt.step) + 0.5) * opt.step
            s:SetValue(val)
            if GPlaterNS.Config:SafeConfigChange(s, opt.label, nil, opt.path, val) then
                s.valueText:SetText(tostring(val))
            else
                Utils:Log("CreateConfigControl: Slider config change failed for %s", 4, "ui", opt.label)
            end
        end)
    else
        Utils:Log("CreateConfigControl: unsupported type %s for %s", 4, "ui", type, opt.label)
        return nil
    end
    f:SetPoint("TOPLEFT", opt.x, opt.y)
    SetupTooltip(f, opt.tip)
    f:Show()
    return f
end

function GPlaterNS.UI.UpdateDebugControlsVisibility(content)
    if not content or not content.debugControls then
        Utils:Log("UpdateDebugControlsVisibility: no content or debugControls", 4, "ui")
        return
    end
    local isDebugEnabled = GPlaterNS.Config:Get({"Debug", "enabled"}, false)
    for i, control in ipairs(content.debugControls) do
        if (control:IsObjectType("Frame") or control:IsObjectType("FontString")) and i ~= 1 then
            if isDebugEnabled then
                control:Show()
            else
                control:Hide()
            end
        end
    end
end

function GPlaterNS.UI.CreateConfigPanel()
    local frame = CreateFrame("Frame", "GPlaterConfigPanel_Main", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(UI.CONFIG_PANEL_WIDTH, UI.CONFIG_PANEL_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:SetToplevel(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(frame:GetFrameLevel() + 100)
    frame:EnableKeyboard(true)
    tinsert(UISpecialFrames, frame:GetName())
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", UI.CONFIG_PANEL_TITLE_X, UI.CONFIG_PANEL_TITLE_Y)
    frame.title:SetText(L("CONFIG_TITLE", "GPlater Configuration"))
    frame.content = CreateFrame("Frame", "GPlaterConfigPanelContent", frame)
    frame.content:SetPoint("TOPLEFT", UI.CONFIG_PANEL_CONTENT_TOPLEFT_X, UI.CONFIG_PANEL_CONTENT_TOPLEFT_Y)
    frame.content:SetPoint("BOTTOMRIGHT", UI.CONFIG_PANEL_CONTENT_BOTTOMRIGHT_X, UI.CONFIG_PANEL_CONTENT_BOTTOMRIGHT_Y)
    GPlaterNS.UI.CreateSettingsTabStructure(frame.content)
    frame:SetScript("OnShow", function(selfFrame)
        if selfFrame.content then
            GPlaterNS.UI.UpdateAuraTable(selfFrame.content)
            GPlaterNS.UI.UpdateDebugControlsVisibility(selfFrame.content)
        end
        if PlaySound then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
    end)
    return frame
end

function GPlaterNS.UI.CreateSettingsTabStructure(content)
    content.debugControls = {}

    local debugModeCheckbox = GPlaterNS.UI.CreateConfigControl(content, "CheckButton", {
        x = UI.DEBUG_CHECKBOX_X,
        y = UI.DEBUG_MODE_CHECKBOX_Y,
        label = L("DEBUG_LABEL", "Debug"),
        path = {"Debug", "enabled"},
        tip = L("DEBUG_ENABLE_TOOLTIP", "Enable debug logging."),
        w = UI.DEBUG_CHECKBOX_WIDTH,
        h = UI.DEBUG_CHECKBOX_HEIGHT
    })
    debugModeCheckbox:Show()
    table.insert(content.debugControls, debugModeCheckbox)
  
    local chatFrameDropdown = GPlaterNS.UI.CreateConfigControl(content, "Dropdown", {
        x = UI.DEBUG_CHAT_DROPDOWN_X,
        y = UI.DEBUG_MODE_CHECKBOX_Y,
        label = "",
        path = {"Debug", "chatframe"},
        def = "1",
        tip = L("DEBUG_CHAT_WINDOW", "Chat Window"),
        w = UI.DEBUG_DROPDOWN_WIDTH,
        items = function()
            local chatItems = {}
            for i = 1, 5 do
                local cf = _G["ChatFrame" .. i]
                local chatWindowName = "Frame " .. i
                if cf then
                    local localizedName = (_G.CHAT_FRAME_NAME_GETTERS and _G.CHAT_FRAME_NAME_GETTERS[i] and _G.CHAT_FRAME_NAME_GETTERS[i](GetLocale())) or cf.name
                    if localizedName and localizedName ~= "" then chatWindowName = localizedName end
                end
                table.insert(chatItems, { text = chatWindowName, value = tostring(i) })
            end
            if #chatItems == 0 then 
                table.insert(chatItems, { text = "Frame 1", value = "1" })
            end
            return chatItems
        end
    })
    table.insert(content.debugControls, chatFrameDropdown)
  
    local categories = {
        {key = "auras", label = L("DEBUG_AURAS_LABEL", "Auras"), x = UI.DEBUG_CATEGORY_AURAS_X, tip = L("DEBUG_AURAS_TOOLTIP", "Show logs related to auras.")},
        {key = "nameplates", label = L("DEBUG_NAMEPLATES_LABEL", "Nameplates"), x = UI.DEBUG_CATEGORY_NAMEPLATES_X, tip = L("DEBUG_NAMEPLATES_TOOLTIP", "Show logs related to nameplates.")},
        {key = "events", label = L("DEBUG_EVENTS_LABEL", "Events"), x = UI.DEBUG_CATEGORY_EVENTS_X, tip = L("DEBUG_EVENTS_TOOLTIP", "Show logs related to events.")},
        {key = "ui", label = L("DEBUG_UI_LABEL", "UI"), x = UI.DEBUG_CATEGORY_UI_X, tip = L("DEBUG_UI_TOOLTIP", "Show logs related to UI.")},
        {key = "utils", label = L("DEBUG_UTILS_LABEL", "Utils"), x = UI.DEBUG_CATEGORY_UTILS_X, tip = L("DEBUG_UTILS_TOOLTIP", "Show logs related to utility functions.")}
    }
  
    for _, category in ipairs(categories) do
        local categoryCheckbox = GPlaterNS.UI.CreateConfigControl(content, "CheckButton", {
            x = category.x,
            y = UI.DEBUG_MODE_CHECKBOX_Y,
            label = category.label,
            path = {"Debug", "logCategories", category.key},
            tip = category.tip,
            w = UI.DEBUG_CHECKBOX_WIDTH,
            h = UI.DEBUG_CHECKBOX_HEIGHT
        })
        table.insert(content.debugControls, categoryCheckbox)
    end
  
    local thresholdSlider = GPlaterNS.UI.CreateConfigControl(content, "Slider", {
        x = UI.DEBUG_THRESHOLD_SLIDER_X,
        y = UI.DEBUG_MODE_CHECKBOX_Y,
        label = L("DEBUG_THRESHOLD_LABEL", "Suppression Threshold"),
        path = {"Debug", "suppressionThreshold"},
        def = 3,
        tip = L("DEBUG_THRESHOLD_TOOLTIP", "Set how many times a log must repeat before being suppressed."),
        w = 100,
        min = 1,
        max = 10,
        step = 1
    })
    table.insert(content.debugControls, thresholdSlider)
  
    local timeWindowSlider = GPlaterNS.UI.CreateConfigControl(content, "Slider", {
        x = UI.DEBUG_TIMEWINDOW_SLIDER_X,
        y = UI.DEBUG_MODE_CHECKBOX_Y,
        label = L("DEBUG_TIMEWINDOW_LABEL", "Time Window (seconds)"),
        path = {"Debug", "suppressionTimeWindow"},
        def = 5,
        tip = L("DEBUG_TIMEWINDOW_TOOLTIP", "Set the time window for detecting repeated logs."),
        w = 100,
        min = 1,
        max = 30,
        step = 1
    })
    table.insert(content.debugControls, timeWindowSlider)

    local friendlyTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    friendlyTitle:SetPoint("TOPLEFT", UI.FRIENDLY_TITLE_X, UI.FRIENDLY_TITLE_Y)
    friendlyTitle:SetText(L("TAB_AURA_COLORING", "Nameplate Settings"))
    friendlyTitle:SetTextColor(1, 0.82, 0)
    local friendlyClassColorsCheckbox = GPlaterNS.UI.CreateConfigControl(content, "CheckButton", {
        x = UI.FRIENDLY_CLASS_COLORS_CHECKBOX_X,
        y = UI.FRIENDLY_CLASS_COLORS_CHECKBOX_Y,
        label = L("FRIENDLY_CLASS_COLORS", "Show Class Colors"),
        path = {"FriendlyNameplates", "settings", "showClassColors"},
        cvar = "ShowClassColorInFriendlyNameplate",
        tip = L("HELP_FRIENDLY_CLASS_COLORS", "Enable class colors for friendly nameplates."),
        w = UI.FRIENDLY_CHECKBOX_WIDTH,
        h = UI.FRIENDLY_CHECKBOX_HEIGHT
    })
    local clickThroughCheckbox = GPlaterNS.UI.CreateConfigControl(content, "CheckButton", {
        x = UI.FRIENDLY_CLICK_THROUGH_CHECKBOX_X,
        y = UI.FRIENDLY_CLICK_THROUGH_CHECKBOX_Y,
        label = L("CLICK_THROUGH", "Click Through"),
        path = {"FriendlyNameplates", "settings", "clickThrough"},
        cvar = "nameplateFriendlyClickThrough",
        tip = L("HELP_CLICK_THROUGH", "When enabled, friendly nameplates allow clicks to pass through."),
        w = UI.FRIENDLY_CHECKBOX_WIDTH,
        h = UI.FRIENDLY_CHECKBOX_HEIGHT
    })
    local onlyNamesCheckbox = GPlaterNS.UI.CreateConfigControl(content, "CheckButton", {
        x = UI.FRIENDLY_ONLY_NAMES_CHECKBOX_X,
        y = UI.FRIENDLY_ONLY_NAMES_CHECKBOX_Y,
        label = L("ONLY_NAMES", "Only Names"),
        path = {"FriendlyNameplates", "settings", "onlyNames"},
        cvar = "nameplateShowOnlyNames",
        tip = L("HELP_ONLY_NAMES", "When enabled, friendly nameplates show only names."),
        w = UI.FRIENDLY_CHECKBOX_WIDTH,
        h = UI.FRIENDLY_CHECKBOX_HEIGHT
    })
    local hideBuffsCheckbox = GPlaterNS.UI.CreateConfigControl(content, "CheckButton", {
        x = UI.FRIENDLY_HIDE_BUFFS_CHECKBOX_X,
        y = UI.FRIENDLY_HIDE_BUFFS_CHECKBOX_Y,
        label = L("HIDE_BUFFS", "Hide Buffs"),
        path = {"FriendlyNameplates", "settings", "hideBuffs"},
        cvar = "nameplateShowFriendlyBuffs",
        cvarInvert = true,
        tip = L("HELP_HIDE_BUFFS", "When enabled, hide buffs on friendly nameplates."),
        w = UI.FRIENDLY_CHECKBOX_WIDTH,
        h = UI.FRIENDLY_CHECKBOX_HEIGHT
    })
    local widthSlider = GPlaterNS.UI.CreateConfigControl(content, "Slider", {
        x = UI.FRIENDLY_WIDTH_SLIDER_X,
        y = UI.FRIENDLY_WIDTH_SLIDER_Y,
        label = L("FRIENDLY_WIDTH", "Width"),
        path = {"FriendlyNameplates", "format", "width"},
        min = 50, max = 150, step = 1, def = 110,
        tip = L("HELP_FRIENDLY_WIDTH", "Set the width of friendly nameplates (50-150)."),
        w = UI.FRIENDLY_SLIDER_WIDTH,
        h = UI.FRIENDLY_SLIDER_HEIGHT
    })
    local heightSlider = GPlaterNS.UI.CreateConfigControl(content, "Slider", {
        x = UI.FRIENDLY_HEIGHT_SLIDER_X,
        y = UI.FRIENDLY_HEIGHT_SLIDER_Y,
        label = L("FRIENDLY_HEIGHT", "Height"),
        path = {"FriendlyNameplates", "format", "height"},
        min = -50, max = 50, step = 1, def = 25,
        tip = L("HELP_FRIENDLY_HEIGHT", "Set the height of friendly nameplates (-50 to 50)."),
        w = UI.FRIENDLY_SLIDER_WIDTH,
        h = UI.FRIENDLY_SLIDER_HEIGHT
    })
    local vScaleSlider = GPlaterNS.UI.CreateConfigControl(content, "Slider", {
        x = UI.FRIENDLY_VSCALE_SLIDER_X,
        y = UI.FRIENDLY_VSCALE_SLIDER_Y,
        label = L("FRIENDLY_V_SCALE", "Vertical Scale"),
        path = {"FriendlyNameplates", "format", "verticalScale"},
        min = 0.5, max = 2.0, step = 0.1, def = 1.0,
        tip = L("HELP_FRIENDLY_V_SCALE", "Set the vertical scale of friendly nameplates (0.5-2.0)."),
        w = UI.FRIENDLY_SLIDER_WIDTH,
        h = UI.FRIENDLY_SLIDER_HEIGHT
    })
    local auraTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    auraTitle:SetPoint("TOPLEFT", UI.AURA_TITLE_X, UI.AURA_TITLE_Y)
    auraTitle:SetText(L("AURA_LIST", "Aura List"))
    auraTitle:SetTextColor(1, 0.82, 0)
    content.auraTitleFrame = auraTitle

    local addAuraEb = CreateFrame("EditBox", "GPlaterAddAuraDirectEditBox", content, "InputBoxTemplate")
    addAuraEb:SetSize(UI.AURA_ADDAURA_EDITBOX_WIDTH, UI.AURA_ADDAURA_EDITBOX_HEIGHT)
    addAuraEb:SetAutoFocus(false)
    addAuraEb:SetFontObject("GameFontHighlight")
    addAuraEb:SetPoint("LEFT", content.auraTitleFrame, "RIGHT", UI.AURA_ADDAURA_EDITBOX_X, UI.AURA_ADDAURA_EDITBOX_Y)
    SetupTooltip(addAuraEb, L("HELP_AURA_ID", "Enter the aura ID."))

    local addAuraBtn = CreateFrame("Button", "GPlaterAddAuraDirectButton", content, "UIPanelButtonTemplate")
    addAuraBtn:SetPoint("LEFT", addAuraEb, "RIGHT", UI.AURA_ADDAURA_BUTTON_X, UI.AURA_ADDAURA_BUTTON_Y)
    addAuraBtn:SetSize(UI.AURA_ADDAURA_BUTTON_WIDTH, UI.AURA_ADDAURA_BUTTON_HEIGHT)
    addAuraBtn:SetText(L("ADD", "Add"))

-- Simplified addAuraOnClickCallback
local function addAuraOnClickCallback(editBoxFrame)
    Utils:Log("addAuraOnClickCallback triggered", 1, "ui") --
    local originalInput = editBoxFrame:GetText()

    local auraIdConfig = {
        entityName = L("AURA_ID", "Aura ID"),
        allowCombo = true,
        minPartsInCombo = 2,
        allowZero = false,
        allowEmpty = false,
        convertSingleToNumber = true, -- Aura IDs are numbers if single, string if combo
        -- Define error keys if your util returns keys for localization
        errorKeyEmpty = "ERROR_AURA_ID_EMPTY", -- Example key
        errorKeyStructure = "ERROR_AURA_ID_INVALID_STRUCTURE", -- Example key
        errorKeyComboNotAllowed = "ERROR_AURA_ID_COMBO_NOT_ALLOWED", -- Example key
        errorKeyComboTooFewParts = "ERROR_AURA_ID_COMBO_TOO_FEW_PARTS", -- Example key
        errorKeyComboInvalidPart = "ERROR_AURA_ID_COMBO_INVALID_PART", -- Example key
        errorKeySingleInvalidFormat = "ERROR_AURA_ID_SINGLE_INVALID_FORMAT" -- Example key
    }

    local isValid, idToStore, errorMsgOrKey = Utils:ParseAndValidateIdString(originalInput, auraIdConfig)

    if not isValid then
        local errorMessage = type(errorMsgOrKey) == "string" and L(errorMsgOrKey, "Invalid Aura ID format (default from AddAura): %s", originalInput) or L("ERROR_AURA_INVALID_ID", "Invalid Aura ID format: %s", originalInput)
        Utils:Log(errorMessage, 4, "ui")
        editBoxFrame:SetText("")
        return
    end

    Utils:Log("addAuraOnClickCallback: idToStore = %s (type: %s) after ParseAndValidateIdString", 3, "ui", tostring(idToStore), type(idToStore)) --

    local specID = GPlaterNS.Config:GetCurrentSpecID()
    if not specID then
        Utils:Log("addAuraOnClickCallback: no specID found", 4, "ui") --
        return
    end

    local aurasTable = GPlaterNS.Config:Get({"AuraColoring", "auras"}, {})
    for _, existingAura in ipairs(aurasTable) do
        if tostring(existingAura.auraID) == tostring(idToStore) then
            Utils:Log(L("ERROR_AURA_EXISTS", "Aura ID %s already exists", tostring(idToStore)), 4, "ui") --
            return
        end
    end

    local nA = Utils:MergeTables({}, GPlaterNS.DefaultAuraSettings or {})
    nA.auraID = idToStore
    nA.skillID = "0" -- Default skillID
    -- Use the new utility function to determine isKnown for the default skillID "0"
    nA.isKnown = Utils:CalculateIsKnown(nA.skillID) -- This should be true for "0"
    Utils:Log("addAuraOnClickCallback: Prepared new aura. AuraID: %s, SkillID: %s, Calculated isKnown: %s", 3, "ui", tostring(nA.auraID), nA.skillID, tostring(nA.isKnown)) --

    local newAurasList = {}
    for _, existingAura in ipairs(aurasTable) do
        table.insert(newAurasList, existingAura)
    end
    table.insert(newAurasList, nA)

    if GPlaterNS.Config:Set({"AuraColoring", "auras"}, newAurasList) then
        editBoxFrame:SetText("")
        if GPlaterNS.UI and GPlaterNS.UI.panelFrame and GPlaterNS.UI.panelFrame.content then
            GPlaterNS.UI.UpdateAuraTable(GPlaterNS.UI.panelFrame.content)
        end
    else
        Utils:Log(L("ERROR_CONFIG_SET_FAILED", "Failed to save configuration, could not add aura %s.", tostring(idToStore)), 4, "ui") --
        editBoxFrame:SetText("")
    end
end
    local function handleAddAura()
        addAuraOnClickCallback(addAuraEb)
        addAuraEb:ClearFocus()
    end

    addAuraBtn:SetScript("OnClick", handleAddAura)
    addAuraEb:SetScript("OnEnterPressed", handleAddAura)
    local pvpAuraCheckbox = GPlaterNS.UI.CreateConfigControl(content, "CheckButton", {
        x = UI.AURA_PVPAURA_CHECKBOX_X,
        y = UI.AURA_PVPAURA_CHECKBOX_Y,
        label = L("ENABLE_PVP_AURA", "Enable PvP Aura Coloring"),
        path = {"AuraColoring", "settings", "pvpColoring"},
        tip = L("HELP_ENABLE_PVP_AURA", "When enabled, apply coloring effects to PvP auras."),
        w = UI.AURA_PVPAURA_CHECKBOX_WIDTH,
        h = UI.AURA_PVPAURA_CHECKBOX_HEIGHT
    })
    pvpAuraCheckbox:ClearAllPoints()
    pvpAuraCheckbox:SetPoint("LEFT", addAuraBtn, "RIGHT", UI.AURA_PVPAURA_CHECKBOX_X, UI.AURA_PVPAURA_CHECKBOX_Y)
    local resetBorderColorEb = CreateFrame("EditBox", "GPlaterResetBorderColorEditBox", content, "InputBoxTemplate")
    resetBorderColorEb:SetSize(UI.AURA_RESETBORDERCOLOR_EDITBOX_WIDTH, UI.AURA_RESETBORDERCOLOR_EDITBOX_HEIGHT)
    resetBorderColorEb:SetAutoFocus(false)
    resetBorderColorEb:SetFontObject("GameFontHighlight")
    resetBorderColorEb:SetPoint("LEFT", pvpAuraCheckbox, "RIGHT", UI.AURA_RESETBORDERCOLOR_EDITBOX_X, UI.AURA_RESETBORDERCOLOR_EDITBOX_Y)
    local defaultResetColor = GPlaterNS.Constants.DEFAULT_RESET_BORDER_COLOR
    resetBorderColorEb:SetText(GPlaterNS.Config:Get({"AuraColoring", "settings", "resetBorderColor"}, defaultResetColor))
    SetupTooltip(resetBorderColorEb, L("HELP_RESET_BORDER_COLOR", "Enter the reset border color (format: 0e0e0e, 6-digit hexadecimal)."))
    local resetBorderColorBtn = CreateFrame("Button", "GPlaterResetBorderColorButton", content, "UIPanelButtonTemplate")
    resetBorderColorBtn:SetPoint("LEFT", resetBorderColorEb, "RIGHT", UI.AURA_RESETBORDERCOLOR_BUTTON_X, UI.AURA_RESETBORDERCOLOR_BUTTON_Y)
    resetBorderColorBtn:SetSize(UI.AURA_RESETBORDERCOLOR_BUTTON_WIDTH, UI.AURA_RESETBORDERCOLOR_BUTTON_HEIGHT)
    resetBorderColorBtn:SetText(L("ADD", "Add"))
    local function applyResetBorderColor(editBoxFrame)
        local textVal = editBoxFrame:GetText():match("^%s*(.-)%s*$") or ""
        if textVal == "" then
            textVal = defaultResetColor
        end
        if not textVal:match("^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then
            Utils:Log(L("ERROR_INVALID_RESET_BORDER_COLOR", "Invalid reset border color format: %s, expected 6-digit hexadecimal (e.g., 0e0e0e)", textVal), 4, "ui")
            editBoxFrame:SetText(GPlaterNS.Config:Get({"AuraColoring", "settings", "resetBorderColor"}, defaultResetColor))
            return
        end
        local success = GPlaterNS.Config:Set({"AuraColoring", "settings", "resetBorderColor"}, textVal:lower())
        if success then
            editBoxFrame:SetText(textVal:lower())
        else
            editBoxFrame:SetText(GPlaterNS.Config:Get({"AuraColoring", "settings", "resetBorderColor"}, defaultResetColor))
            Utils:Log("applyResetBorderColor: failed to set color", 4, "ui")
        end
        editBoxFrame:ClearFocus()
    end
    resetBorderColorBtn:SetScript("OnClick", function()
        applyResetBorderColor(resetBorderColorEb)
    end)
    resetBorderColorEb:SetScript("OnEnterPressed", function()
        applyResetBorderColor(resetBorderColorEb)
    end)
    resetBorderColorEb:SetScript("OnEscapePressed", function(self)
        self:SetText(GPlaterNS.Config:Get({"AuraColoring", "settings", "resetBorderColor"}, defaultResetColor))
        self:ClearFocus()
    end)
    local aLF = CreateFrame("Frame", nil, content, "BackdropTemplate")
    aLF:SetPoint("TOPLEFT", UI.AURA_LISTFRAME_TOPLEFT_X, UI.AURA_LISTFRAME_TOPLEFT_Y)
    aLF:SetPoint("BOTTOMRIGHT", UI.AURA_LISTFRAME_BOTTOMRIGHT_X, UI.AURA_LISTFRAME_BOTTOMRIGHT_Y)
    aLF:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    aLF:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    content.auraListFrame = aLF
    local aH = CreateFrame("Frame", nil, aLF)
    aH:SetSize(UI.AURA_HEADER_WIDTH, UI.AURA_HEADER_HEIGHT)
    aH:SetPoint("TOPLEFT", UI.AURA_HEADER_X, UI.AURA_HEADER_Y)
    local hBG = aH:CreateTexture(nil, "BACKGROUND")
    hBG:SetAllPoints()
    hBG:SetColorTexture(0.15, 0.15, 0.15, 0.8)
    GPlaterNS.UI.SetupAuraHeader(aH)
    content.auraHeader = aH
    local aS = CreateFrame("ScrollFrame", nil, aLF, "UIPanelScrollFrameTemplate")
    aS:SetPoint("TOPLEFT", UI.AURA_SCROLL_TOPLEFT_X, UI.AURA_SCROLL_TOPLEFT_Y)
    aS:SetPoint("BOTTOMRIGHT", UI.AURA_SCROLL_BOTTOMRIGHT_X, UI.AURA_SCROLL_BOTTOMRIGHT_Y)
    content.auraScroll = aS
    local aSC = CreateFrame("Frame", nil, aS)
    aSC:SetSize(UI.AURA_SCROLLCHILD_WIDTH, UI.AURA_SCROLLCHILD_HEIGHT)
    aS:SetScrollChild(aSC)
    content.auraScrollChild = aSC
end

function GPlaterNS.UI.Open()
    if not isInitialized then
        Utils:Log("Open: UI not initialized", 4, "ui")
        return
    end
    if not GPlaterNS.UI.panelFrame then
        GPlaterNS.UI.panelFrame = GPlaterNS.UI.CreateConfigPanel()
        if GPlaterNS.UI.panelFrame then
            GPlaterNS.UI.panelFrame:Show()
            if GPlaterNS.UI.panelFrame.content then
                GPlaterNS.UI.UpdateAuraTable(GPlaterNS.UI.panelFrame.content)
            end
        else
            Utils:Log("Open: failed to create panel", 4, "ui")
            return
        end
    else
        if GPlaterNS.UI.panelFrame:IsShown() then
            GPlaterNS.UI.panelFrame:Hide()
        else
            GPlaterNS.UI.panelFrame:Show()
            if GPlaterNS.UI.panelFrame.content then
                GPlaterNS.UI.UpdateAuraTable(GPlaterNS.UI.panelFrame.content)
            end
        end
    end
end

function GPlaterNS.UI.RegisterSlashCommand()
    local slashCommandName = "GP"
    local slashCommandActual = "/gp"
    _G["SLASH_" .. slashCommandName .. "1"] = slashCommandActual
    SlashCmdList[slashCommandName] = function(msg)
        if msg and msg:match("^%d+$") then
            local level = tonumber(msg)
            if level >= 0 and level <= 4 then
                if level == 0 then
                    Utils:Log("SlashCmd: Debug logging DISABLED.", 2, "ui")
                    GPlaterNS.Utils.isDebug = false
                    GPlaterNS.State.debugLevel = 4
                    if GPlaterNS.Config and GPlaterNS.Config.Set then
                        GPlaterNS.Config:Set({"Debug", "enabled"}, false)
                    end
                    Utils:Log( "调试日志已关闭。")
                else
                    GPlaterNS.Utils.isDebug = true
                    GPlaterNS.State.debugLevel = level
                    if GPlaterNS.Config and GPlaterNS.Config.Set then
                        GPlaterNS.Config:Set({"Debug", "enabled"}, true)
                    end
                    Utils:Log("SlashCmd: Debug level set to %d. Debug logging ENABLED.", 2, "ui", level)
                end
                if GPlaterNS.UI and GPlaterNS.UI.panelFrame and GPlaterNS.UI.panelFrame.content then
                    local debugCheckbox = GPlaterNS.UI.panelFrame.content.debugControls and GPlaterNS.UI.panelFrame.content.debugControls[1]
                    if debugCheckbox and debugCheckbox.SetChecked then
                        debugCheckbox:SetChecked(GPlaterNS.Utils.isDebug)
                    end
                    GPlaterNS.UI.UpdateDebugControlsVisibility(GPlaterNS.UI.panelFrame.content)
                end
            else
                Utils:Log("SlashCmd: invalid debug level %s. Use 0 to disable, or 1-4 to set level.", 4, "ui", msg)
            end
        else
            if GPlaterNS.UI and GPlaterNS.UI.Open then
                GPlaterNS.UI.Open()
            else
                Utils:Log("SlashCmd: UI.Open missing", 4, "ui")
            end
        end
    end
end