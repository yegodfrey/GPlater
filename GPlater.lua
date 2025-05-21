local _G = _G
local _, GPlaterNS = ...
_G.GPlaterNS = GPlaterNS
_G.GPlaterDB = _G.GPlaterDB or {}

function GPlaterNS.InitializeCoreModules()
    _G.GPlaterNS = _G.GPlaterNS or {}
    GPlaterNS = _G.GPlaterNS
    GPlaterNS.State.debugLevel = GPlaterNS.State.debugLevel or 4
    
    if GPlaterNS.Utils.LoadLogSettingsFromConfig then
        GPlaterNS.Utils:LoadLogSettingsFromConfig()
    end
end

GPlaterNS.State = {
    Nameplates = setmetatable({}, {__mode = "v"}),
    ActiveAuras = setmetatable({}, {__mode = "v"}),
    PlaterSettings = setmetatable({}, {__mode = "v"}),
    HiddenNameplates = setmetatable({}, {__mode = "v"}),
    auraConfig = {},
    UnitsMarkedAsUniqueByGPlater = setmetatable({}, {__mode = "v"}),
    playerGUID = UnitGUID("player"),
    petGUID = UnitGUID("pet") or "",
    debugLevel = 4
}

local EffectUtils = {}
local NameplateManager = {}
local AuraManager = {}
local EventFrame = CreateFrame("Frame", "GPlaterEventFrame")
local EventManager = { eventFrame = EventFrame }

GPlaterNS.EffectUtils = EffectUtils
GPlaterNS.NameplateManager = NameplateManager
GPlaterNS.AuraManager = AuraManager
GPlaterNS.EventManager = EventManager

EffectUtils.effectHandlers = {
    COLOR = {
        apply = function(frame, cfg, guid)
            if cfg.applyHealthBar then 
                EffectUtils.ColorEffect:Apply(frame, cfg.healthBarColor, "healthBar")
            end
            if cfg.applyNameText then 
                EffectUtils.ColorEffect:Apply(frame, cfg.nameTextColor, "nameText")
            end
            if cfg.applyBorder then 
                EffectUtils.ColorEffect:Apply(frame, cfg.borderColor, "border")
            end
        end,
        reset = function(frame, unitType, guid, auraID)
            GPlaterNS.Utils:Log("effectHandlers.COLOR.reset: auraID=%d for guid=%s", 3, "auras", auraID, tostring(guid))
        end
    },
    SCALE = {
        apply = function(frame, cfg, guid)
            if cfg.applyScale then 
                EffectUtils.ScaleEffect:Apply(frame, guid, cfg.scale)
            end
        end,
        reset = function(frame, _, guid, auraID)
            GPlaterNS.Utils:Log("effectHandlers.SCALE.reset: auraID=%d for guid=%s", 3, "auras", auraID, tostring(guid))
        end
    },
    FLASH = {
        apply = function(frame, cfg, guid)
            if cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_FLASH then 
                EffectUtils.FlashEffect:Apply(frame)
            end
        end,
        reset = function(frame, _, guid, auraID)
            GPlaterNS.Utils:Log("effectHandlers.FLASH.reset: auraID=%d for guid=%s", 3, "auras", auraID, tostring(guid))
        end
    },
    TOP = {
        apply = function(frame, cfg, guid)
            if cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_TOP then 
                EffectUtils.LevelEffect:Apply(frame, GPlaterNS.Constants.EFFECT_TYPE_TOP, guid)
            end
        end,
        reset = function(frame, _, guid, auraID)
            GPlaterNS.Utils:Log("effectHandlers.TOP.reset: auraID=%d for guid=%s", 3, "auras", auraID, tostring(guid))
        end
    },
    LOW = {
        apply = function(frame, cfg, guid)
            if cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_LOW then 
                EffectUtils.LevelEffect:Apply(frame, GPlaterNS.Constants.EFFECT_TYPE_LOW, guid)
            end
        end,
        reset = function(frame, _, guid, auraID)
            GPlaterNS.Utils:Log("effectHandlers.LOW.reset: auraID=%d for guid=%s", 3, "auras", auraID, tostring(guid))
        end
    },
    HIDE = {
        apply = function(frame, cfg, guid, auraData)
            if cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_HIDE then
                EffectUtils.HideEffect:Apply(frame, guid, cfg.auraID, GetTime(), auraData.expirationTime or math.huge)
            end
        end,
        reset = function(frame, _, guid, auraID)
            GPlaterNS.Utils:Log("effectHandlers.HIDE.reset: auraID=%s for guid=%s", 3, "auras", tostring(auraID), tostring(guid))
            EffectUtils.HideEffect:Reset(frame, guid, auraID)
        end
    },
    UNIQUE = {
        apply = function(frame, cfg, guid, auraData)
            if cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_UNIQUE then
                GPlaterNS.State.UnitsMarkedAsUniqueByGPlater[guid] = {
                    auraID = cfg.auraID,
                    applicationTime = GetTime(),
                    sourceFrame = frame
                }
                GPlaterNS.Utils:Log("EffectHandlers.UNIQUE.apply: Registered for aura %d on %s", 2, "auras", cfg.auraID, tostring(guid))
                if not frame:IsForbidden() then frame:Show() end
                GPlaterNS.State.HiddenNameplates[guid] = nil
    
                -- 隐藏没有 UNIQUE 特效的姓名板
                for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
                    if plate.unitFrame and plate.unitFrame.namePlateUnitToken then
                        local otherUnit = plate.unitFrame.namePlateUnitToken
                        local otherGUID = UnitGUID(otherUnit)
                        if otherGUID and otherGUID ~= guid and UnitCanAttack("player", otherUnit) then
                            if not GPlaterNS.State.UnitsMarkedAsUniqueByGPlater[otherGUID] then
                                local otherFrame = plate.unitFrame
                                if not otherFrame:IsForbidden() then
                                    GPlaterNS.State.HiddenNameplates[otherGUID] = GPlaterNS.State.HiddenNameplates[otherGUID] or {}
                                    GPlaterNS.State.HiddenNameplates[otherGUID]["UNIQUE_EFFECT_FROM_" .. guid] = {
                                        effectType = "HIDE_BY_UNIQUE",
                                        sourceGUID = guid,
                                        auraID = cfg.auraID
                                    }
                                    otherFrame:Hide()
                                    GPlaterNS.Utils:Log("EffectHandlers.UNIQUE.apply: Hiding %s due to %s", 3, "auras", tostring(otherGUID), tostring(guid))
                                end
                            end
                        end
                    end
                end
            end
        end,
        reset = function(frame, unitType, guid, auraID)
            if GPlaterNS.State.UnitsMarkedAsUniqueByGPlater[guid] then
                local storedAuraID = GPlaterNS.State.UnitsMarkedAsUniqueByGPlater[guid].auraID
                GPlaterNS.State.UnitsMarkedAsUniqueByGPlater[guid] = nil
                GPlaterNS.Utils:Log("EffectHandlers.UNIQUE.reset: Cleared for guid %s, auraID=%s", 2, "auras", tostring(guid), tostring(auraID or storedAuraID or "nil"))
                for otherGUID, np in pairs(GPlaterNS.State.Nameplates) do
                    if np.frame and not np.frame:IsForbidden() then
                        GPlaterNS.State.HiddenNameplates[otherGUID] = GPlaterNS.State.HiddenNameplates[otherGUID] or {}
                        if GPlaterNS.State.HiddenNameplates[otherGUID]["UNIQUE_EFFECT_FROM_" .. guid] then
                            GPlaterNS.State.HiddenNameplates[otherGUID]["UNIQUE_EFFECT_FROM_" .. guid] = nil
                            if not next(GPlaterNS.State.HiddenNameplates[otherGUID]) then
                                GPlaterNS.State.HiddenNameplates[otherGUID] = nil
                            end
                        end
                        GPlaterNS.NameplateManager:UpdateAndApplyAllEffects(otherGUID)
                    end
                end
            else
                GPlaterNS.Utils:Log("EffectHandlers.UNIQUE.reset: No UNIQUE state for guid %s", 3, "auras", tostring(guid))
            end
            GPlaterNS.NameplateManager:UpdateAndApplyAllEffects(guid)
        end
    }
}

function EffectUtils:ValidateUnitFrame(uF, effectType)
    if not uF or not uF:IsShown() or not uF.namePlateUnitToken or not UnitExists(uF.namePlateUnitToken) then
        GPlaterNS.Utils:Log("ValidateUnitFrame: invalid unit frame, effectType=%s", 4, "auras")
        return false
    end
    return true
end

function EffectUtils:SafeExecute(func, uF, effectType, ...)
    if not self:ValidateUnitFrame(uF, effectType) then 
        GPlaterNS.Utils:Log("SafeExecute: invalid unit frame, effectType=%s", 4, "auras")
        return false 
    end
    local success, result = GPlaterNS.Utils:SafeCall(func, ...)
    return success, result
end

-- New: Centralized effect application
function EffectUtils:ApplyEffects(frame, guid, effects, unitType)
    GPlaterNS.Utils:Log("EffectUtils:ApplyEffects called for GUID: %s", 3, "nameplates", guid)
    if effects.COLOR.healthBar then
        GPlaterNS.Utils:Log("EFFECTS_ARG: HBColor: %s", 3, "nameplates", effects.COLOR.healthBar)
    end
    if effects.SCALE then
        GPlaterNS.Utils:Log("EFFECTS_ARG: Scale: %s", 3, "nameplates", tostring(effects.SCALE))
    end
    if effects.HIDE then
        GPlaterNS.Utils:Log("EFFECTS_ARG: HIDE: true", 3, "nameplates")
    end
    if not self:ValidateUnitFrame(frame, "effects") then return end
    frame.GPlaterEffects = frame.GPlaterEffects or {}

    -- 如果 HIDE 效果激活，优先应用
    if effects.HIDE then
        self.HideEffect:Apply(frame, guid, effects.sourceAura.hide or "AGGREGATED_HIDE", GetTime(), math.huge)
        frame.GPlaterEffects.hide = true
        GPlaterNS.Utils:Log("ApplyEffects: HIDE is active for %s by aura %s", 3, "auras", tostring(guid), tostring(effects.sourceAura.hide))
        return -- HIDE 优先，跳过其他效果
    elseif frame.GPlaterEffects.hide then
        self.HideEffect:ResetToBase(frame, guid)
        frame.GPlaterEffects.hide = nil
    end

    -- 应用 UNIQUE 效果
    if effects.UNIQUE then
        local uniqueKey = effects.sourceAura.unique
        if uniqueKey and GPlaterNS.State.auraConfig[uniqueKey] then
            local cfgEntry = GPlaterNS.State.auraConfig[uniqueKey]
            local cfg = cfgEntry.config
            if cfg and cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_UNIQUE then
                local auraData = nil
                if cfgEntry.isCombination then
                    for _, reqID in ipairs(cfgEntry.requiredIDs) do
                        if GPlaterNS.State.ActiveAuras[guid] and GPlaterNS.State.ActiveAuras[guid][reqID] then
                            auraData = GPlaterNS.State.ActiveAuras[guid][reqID]
                            break
                        end
                    end
                else
                    local spellID = cfgEntry.requiredIDs[1]
                    auraData = GPlaterNS.State.ActiveAuras[guid] and GPlaterNS.State.ActiveAuras[guid][spellID]
                end
                if auraData then
                    GPlaterNS.Utils:Log("ApplyEffects: Applying UNIQUE effect for GUID %s with key %s", 2, "auras", guid, uniqueKey)
                    self.effectHandlers.UNIQUE.apply(frame, cfg, guid, auraData)
                    frame.GPlaterEffects.unique = true
                    frame.GPlaterEffects.uniqueAuraID = cfg.auraID
                else
                    GPlaterNS.Utils:Log("ApplyEffects: Skipping UNIQUE effect for key %s on GUID %s due to missing auraData", 3, "auras", uniqueKey, guid)
                    frame.GPlaterEffects.unique = false
                    frame.GPlaterEffects.uniqueAuraID = nil
                end
            else
                GPlaterNS.Utils:Log("ApplyEffects: Invalid UNIQUE config for key %s on GUID %s", 4, "auras", uniqueKey, guid)
            end
        else
            GPlaterNS.Utils:Log("ApplyEffects: No UNIQUE config found for key %s on GUID %s", 4, "auras", tostring(uniqueKey), guid)
        end
    elseif frame.GPlaterEffects.unique then
        -- 移除 UNIQUE 效果
        GPlaterNS.Utils:Log("ApplyEffects: Resetting UNIQUE effect for GUID %s with auraID %s", 2, "auras", guid, tostring(frame.GPlaterEffects.uniqueAuraID))
        self.effectHandlers.UNIQUE.reset(frame, unitType, guid, frame.GPlaterEffects.uniqueAuraID)
        frame.GPlaterEffects.unique = nil
        frame.GPlaterEffects.uniqueAuraID = nil
    end

    -- 应用其他效果
    if effects.COLOR.healthBar then
        self.ColorEffect:Apply(frame, effects.COLOR.healthBar, "healthBar")
        frame.GPlaterEffects.healthBar = effects.COLOR.healthBar
    elseif frame.GPlaterEffects.healthBar then
        self.ColorEffect:Reset(frame, "healthBar", unitType, guid)
        frame.GPlaterEffects.healthBar = nil
    end

    if effects.COLOR.nameText then
        self.ColorEffect:Apply(frame, effects.COLOR.nameText, "nameText")
        frame.GPlaterEffects.nameText = effects.COLOR.nameText
    elseif frame.GPlaterEffects.nameText then
        self.ColorEffect:Reset(frame, "nameText", unitType, guid)
        frame.GPlaterEffects.nameText = nil
    end
    if effects.COLOR.border then
        self.ColorEffect:Apply(frame, effects.COLOR.border, "border")
        frame.GPlaterEffects.border = effects.COLOR.border
    elseif frame.GPlaterEffects.border then
        self.ColorEffect:Reset(frame, "border", unitType, guid)
        frame.GPlaterEffects.border = nil
    end

    if effects.SCALE then
        self.ScaleEffect:Apply(frame, guid, effects.SCALE)
        frame.GPlaterEffects.scale = effects.SCALE
    elseif frame.GPlaterEffects.scale then
        self.ScaleEffect:Reset(frame, guid)
        frame.GPlaterEffects.scale = nil
    end

    if effects.FLASH then
        self.FlashEffect:Apply(frame)
        frame.GPlaterEffects.flash = true
    elseif frame.GPlaterEffects.flash then
        self.FlashEffect:Reset(frame)
        frame.GPlaterEffects.flash = nil
    end

    if effects.TOP then
        self.LevelEffect:Apply(frame, GPlaterNS.Constants.EFFECT_TYPE_TOP, guid)
        frame.GPlaterEffects.top = true
        frame.GPlaterEffects.low = false
    elseif effects.LOW then
        self.LevelEffect:Apply(frame, GPlaterNS.Constants.EFFECT_TYPE_LOW, guid)
        frame.GPlaterEffects.low = true
        frame.GPlaterEffects.top = false
    elseif frame.GPlaterEffects.top or frame.GPlaterEffects.low then
        self.LevelEffect:Reset(frame, guid)
        frame.GPlaterEffects.top = false
        frame.GPlaterEffects.low = false
    end

    GPlaterNS.Utils:Log("ApplyEffects: applied effects to guid=%s", 3, "auras", tostring(guid))
end

local nameTextUpdateQueue = {} -- guid -> {frame, r, g, b}
local centralizedNameTextUpdateFrame = CreateFrame("Frame", "GPlater_CentralNameTextUpdate")
centralizedNameTextUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    if not next(nameTextUpdateQueue) then
        self:Hide() -- No need to run if queue is empty
        return
    end
    for guid, data in pairs(nameTextUpdateQueue) do
        local uF = data.frame
        if uF and uF:IsVisible() and uF.healthBar and uF.healthBar.unitName and uF.healthBar.unitName:IsObjectType("FontString") then
            local r, g, b = data.r, data.g, data.b
            uF.healthBar.unitName:SetTextColor(r, g, b, 1)
        else
            -- Frame is no longer valid or visible, remove from queue
            nameTextUpdateQueue[guid] = nil 
        end
    end
end)
centralizedNameTextUpdateFrame:Hide() -- Start hidden

EffectUtils.ColorEffect = EffectUtils.ColorEffect or {}
setmetatable(EffectUtils.ColorEffect, { __index = EffectUtils })

function EffectUtils.ColorEffect:Apply(uF, color, effectType)
    if not color or not effectType then 
        GPlaterNS.Utils:Log("ColorEffect:Apply: missing color or effectType", 4, "auras")
        return false 
    end
    GPlaterNS.Utils:Log("ColorEffect:Apply - uF: %s, Color: %s, Type: %s", 2, "auras", tostring(uF and uF:GetName()), tostring(color), tostring(effectType))
    local r, g, b, a = GPlaterNS.Utils:HexToRGB(color); if not a then a = 1 end
    if not r then GPlaterNS.Utils:Log("ColorEffect:Apply - HexToRGB failed for color %s", 4, "auras", color); return false end

    if not Plater or not Plater.SetNameplateColor or not Plater.SetBorderColor then GPlaterNS.Utils:Log("ColorEffect:Apply - Plater APIs missing", 4, "auras"); return false end

    if effectType == "healthBar" then
        GPlaterNS.Utils:Log("ColorEffect:Apply - Calling Plater.SetNameplateColor for healthBar with r=%s, g=%s, b=%s", 2, "auras", r,g,b)
        return self:SafeExecute(Plater.SetNameplateColor, uF, "healthBar", uF, r, g, b)
    elseif effectType == "nameText" then
        if not (uF.healthBar and uF.healthBar.unitName and uF.healthBar.unitName:IsObjectType("FontString")) then
            GPlaterNS.Utils:Log("ColorEffect:Apply: invalid nameText object for uF %s", 4, "auras", uF:GetName() or "UNKNOWN")
            return false
        end
        GPlaterNS.Utils:Log("ColorEffect:Apply - Setting nameText color for GUID %s with r=%s, g=%s, b=%s, a=%s", 2, "auras", tostring(uF.namePlateUnitToken and UnitGUID(uF.namePlateUnitToken)), r,g,b,a)
        local success = self:SafeExecute(uF.healthBar.unitName.SetTextColor, uF, "nameText_direct", uF.healthBar.unitName, r, g, b, a)
        -- Queueing logic for nameTextUpdateQueue can remain if needed, but direct application is logged above
        if success then
            local guid = UnitGUID(uF.namePlateUnitToken)
            if guid then
                nameTextUpdateQueue[guid] = {frame = uF, r = r, g = g, b = b, a = a} 
                if not centralizedNameTextUpdateFrame:IsShown() and next(nameTextUpdateQueue) then
                    centralizedNameTextUpdateFrame:Show()
                end
            end
        end
        return success
    elseif effectType == "border" then
        GPlaterNS.Utils:Log("ColorEffect:Apply - Calling Plater.SetBorderColor for border with r=%s, g=%s, b=%s", 2, "auras", r,g,b)
        return self:SafeExecute(Plater.SetBorderColor, uF, "border", uF, r, g, b)
    end
    GPlaterNS.Utils:Log("ColorEffect:Apply: unknown effectType %s", 4, "auras", effectType)
    return false
end

function EffectUtils.ColorEffect:Reset(uF, effectType, unitTypeIfForPlaterDefaults, unitID_guid) -- unitID_guid 现在是 GUID
    if not self:ValidateUnitFrame(uF, effectType .. "_reset") then -- 确保 ValidateUnitFrame 适用
        GPlaterNS.Utils:Log("ColorEffect:Reset: invalid unit frame for %s, effectType=%s", 4, "auras", tostring(unitID_guid), effectType)
        -- 即使 uF 无效，如果 unitID_guid 存在，也尝试从队列中移除
        if effectType == "nameText" and unitID_guid then
            nameTextUpdateQueue[unitID_guid] = nil
            if not next(nameTextUpdateQueue) and centralizedNameTextUpdateFrame:IsShown() then
                centralizedNameTextUpdateFrame:Hide()
                GPlaterNS.Utils:Log("ColorEffect:Reset nameText (uF invalid) - Queue empty, hiding centralized frame for GUID: %s", 3, "ui", unitID_guid)
            end
        end
        return false 
    end

    if effectType == "healthBar" then
        if Plater and Plater.RefreshNameplateColor then
            local success = self:SafeExecute(Plater.RefreshNameplateColor, uF, "healthBar_reset", uF)
            return success
        end
        GPlaterNS.Utils:Log("ColorEffect:Reset: Plater.RefreshNameplateColor missing", 4, "auras")
        return false
    elseif effectType == "border" then
        if Plater and Plater.SetBorderColor then
            local resetColorHex = GPlaterNS.Config:Get({"AuraColoring", "settings", "resetBorderColor"}, GPlaterNS.Constants.DEFAULT_RESET_BORDER_COLOR)
            local r, g, b = GPlaterNS.Utils:HexToRGB("#" .. resetColorHex) -- 假设 HexToRGB 不需要 '#'
            if r then -- 确保 HexToRGB 成功返回
                local success = self:SafeExecute(Plater.SetBorderColor, uF, "border_reset", uF, r, g, b)
                return success
            end
            GPlaterNS.Utils:Log("ColorEffect:Reset: invalid reset color %s", 4, "auras", resetColorHex)
        end
        GPlaterNS.Utils:Log("ColorEffect:Reset: Plater.SetBorderColor missing", 4, "auras")
        return false
    elseif effectType == "nameText" then
        if unitID_guid then 
            nameTextUpdateQueue[unitID_guid] = nil
            -- 如果队列为空，隐藏 centralizedNameTextUpdateFrame 以停止其 OnUpdate
            if not next(nameTextUpdateQueue) and centralizedNameTextUpdateFrame:IsShown() then
                centralizedNameTextUpdateFrame:Hide()
                GPlaterNS.Utils:Log("ColorEffect:Reset nameText - Queue empty, hiding centralized frame for GUID: %s", 3, "ui", unitID_guid)
            end
        end
        -- 总是尝试重置文本颜色到默认值，即使它不在队列中（可能被其他插件修改）
        if uF.healthBar and uF.healthBar.unitName and uF.healthBar.unitName:IsObjectType("FontString") then
            self:SafeExecute(uF.healthBar.unitName.SetTextColor, uF, "nameText_reset_direct", uF.healthBar.unitName, 1, 1, 1, 1) -- 默认白色，完全不透明
        end
        return true
    end
    GPlaterNS.Utils:Log("ColorEffect:Reset: unknown effectType %s", 4, "auras", effectType)
    return false
end

EffectUtils.ScaleEffect = EffectUtils.ScaleEffect or {}
setmetatable(EffectUtils.ScaleEffect, { __index = EffectUtils })

function EffectUtils.ScaleEffect:Apply(uF, id, scale)
    if not self:ValidateUnitFrame(uF, "scale") or not id or not scale then 
        GPlaterNS.Utils:Log("ScaleEffect:Apply: invalid inputs", 4, "auras")
        return false 
    end
    local settings = GPlaterNS.State.PlaterSettings[id] or { baseScale = 1.0 }
    local success = self:SafeExecute(uF.SetScale, uF, "scale", uF, settings.baseScale * scale)
    return success
end

function EffectUtils.ScaleEffect:Reset(uF, id)
    if not self:ValidateUnitFrame(uF, "scale") or not id then 
        GPlaterNS.Utils:Log("ScaleEffect:Reset: invalid inputs", 4, "auras")
        return false 
    end
    local settings = GPlaterNS.State.PlaterSettings[id] or { baseScale = 1.0 }
    local success = self:SafeExecute(uF.SetScale, uF, "scale", uF, settings.baseScale)
    return success
end

EffectUtils.FlashEffect = EffectUtils.FlashEffect or {}
setmetatable(EffectUtils.FlashEffect, { __index = EffectUtils })

function EffectUtils.FlashEffect:Apply(uF)
    if not self:ValidateUnitFrame(uF, "flash") then 
        GPlaterNS.Utils:Log("FlashEffect:Apply: invalid unit frame", 4, "auras")
        return false
    end
    if Plater and Plater.FlashNameplateBody then
        local success = self:SafeExecute(Plater.FlashNameplateBody, uF, "flash_body_plater_api", uF, nil, 0.5)
        return success
    end
        GPlaterNS.Utils:Log("FlashEffect:Apply: Plater.FlashNameplateBody missing", 4, "auras")
    return false
end

function EffectUtils.FlashEffect:Reset(uF)
    if uF.flashEffect and uF.flashEffect.Stop then
        self:SafeExecute(uF.flashEffect.Stop, uF, "flash_stop_custom_anim", uF.flashEffect)
        uF.flashEffect = nil
    end
    return true
end

EffectUtils.LevelEffect = EffectUtils.LevelEffect or {}
setmetatable(EffectUtils.LevelEffect, { __index = EffectUtils })

function EffectUtils.LevelEffect:Apply(uF, effect, id)
    if not self:ValidateUnitFrame(uF, "level") or not effect or not id then 
        GPlaterNS.Utils:Log("LevelEffect:Apply: invalid inputs", 4, "auras")
        return false 
    end
    local strata = effect == GPlaterNS.Constants.EFFECT_TYPE_TOP and "DIALOG" or "BACKGROUND"
    local success = self:SafeExecute(uF.SetFrameStrata, uF, "level_strata", uF, strata)
    return success
end

function EffectUtils.LevelEffect:Reset(uF, id)
    if not self:ValidateUnitFrame(uF, "level") or not id then 
        GPlaterNS.Utils:Log("LevelEffect:Reset: invalid inputs", 4, "auras")
        return false 
    end
    local settings = GPlaterNS.State.PlaterSettings[id] or { baseStrata = "MEDIUM" }
    local success = self:SafeExecute(uF.SetFrameStrata, uF, "level_strata_reset", uF, settings.baseStrata)
    return success
end

EffectUtils.HideEffect = EffectUtils.HideEffect or {}
setmetatable(EffectUtils.HideEffect, { __index = EffectUtils })

function EffectUtils.HideEffect:Apply(uF, id, auraID, applicationTime, expirationTime)
    if not uF or not uF:IsObjectType("Frame") then 
        GPlaterNS.Utils:Log("HideEffect:Apply: invalid frame", 4, "auras")
        return false 
    end
    GPlaterNS.State.HiddenNameplates[id] = GPlaterNS.State.HiddenNameplates[id] or {}
    GPlaterNS.State.HiddenNameplates[id][auraID] = {
        effectType = GPlaterNS.Constants.EFFECT_TYPE_HIDE,
        auraID = auraID,
        applicationTime = applicationTime or GetTime(),
        expirationTime = expirationTime or math.huge
    }
    if not uF:IsForbidden() then
        uF:Hide()
    end
    return true
end

function EffectUtils.HideEffect:Reset(uF, id, auraID)
    if not uF or not uF:IsObjectType("Frame") then
        if id and GPlaterNS.State.HiddenNameplates[id] and GPlaterNS.State.HiddenNameplates[id][auraID] then
            GPlaterNS.State.HiddenNameplates[id][auraID] = nil
            if not next(GPlaterNS.State.HiddenNameplates[id]) then 
                GPlaterNS.State.HiddenNameplates[id] = nil
            end
        end
        GPlaterNS.Utils:Log("HideEffect:Reset: invalid frame", 4, "auras")
        return false
    end
    if GPlaterNS.State.HiddenNameplates[id] and GPlaterNS.State.HiddenNameplates[id][auraID] then
        local effectType = GPlaterNS.State.HiddenNameplates[id][auraID].effectType
        if effectType == GPlaterNS.Constants.EFFECT_TYPE_HIDE or effectType == GPlaterNS.Constants.EFFECT_TYPE_HIDE_BY_UNIQUE then
            local hasOtherHideEffects = false
            for otherAuraID, effectData in pairs(GPlaterNS.State.HiddenNameplates[id] or {}) do
                if otherAuraID ~= auraID and (effectData.effectType == GPlaterNS.Constants.EFFECT_TYPE_HIDE or effectData.effectType == GPlaterNS.Constants.EFFECT_TYPE_HIDE_BY_UNIQUE) then
                    hasOtherHideEffects = true
                    break
                end
            end
            if not hasOtherHideEffects and not uF:IsForbidden() then
                uF:Show()
            end
            GPlaterNS.State.HiddenNameplates[id][auraID] = nil
            if not next(GPlaterNS.State.HiddenNameplates[id]) then 
                GPlaterNS.State.HiddenNameplates[id] = nil
            end
        end
    end
    return true
end

function EffectUtils.HideEffect:ResetToBase(uF, id)
    if not id then
        GPlaterNS.Utils:Log("HideEffect:ResetToBase: nil id", 4, "auras")
        return false
    end

    -- 清除 GPlater 直接施加的 HIDE 状态
    if GPlaterNS.State.HiddenNameplates[id] then
        for auraID, effectData in pairs(GPlaterNS.State.HiddenNameplates[id]) do
            if effectData.effectType == GPlaterNS.Constants.EFFECT_TYPE_HIDE then
                GPlaterNS.State.HiddenNameplates[id][auraID] = nil
            end
        end
        if not next(GPlaterNS.State.HiddenNameplates[id]) then
            GPlaterNS.State.HiddenNameplates[id] = nil
        end
    end

    -- 仅当 HiddenNameplates[id] 为空且框架有效时显示姓名板
    local success = false
    if not GPlaterNS.State.HiddenNameplates[id] and uF and uF:IsObjectType("Frame") and not uF:IsForbidden() then
        uF:Show()
        success = true
    end

    GPlaterNS.Utils:Log("HideEffect:ResetToBase: Reset visibility for guid=%s, shown=%s", 3, "auras", tostring(id), tostring(success))
    return success
end

function NameplateManager:ValidateNameplate(np)
    if not np or not np.unit or not np.frame or not np.frame.unitFrame then
        return false
    end
    if not UnitExists(np.unit) or not np.frame:IsShown() then
        return false
    end
    return true
end

-- 在 GPlater.lua 文件中
function NameplateManager:GetNameplate(guid)
    if not guid then
        return nil
    end
    GPlaterNS.Utils:Log("GetNameplate: Attempting to get nameplate for GUID: %s", 3, "nameplates", guid)

    local np = GPlaterNS.State.Nameplates[guid]
    if np then
        GPlaterNS.Utils:Log("GetNameplate: Found cached entry for GUID %s. Validating...", 3, "nameplates", guid)
        if self:ValidateNameplate(np) then
            return np
        else
        end
    else
    end

    -- 如果缓存无效或不存在，则尝试清理并重新注册
    self:CleanupNameplateInfo(guid) -- 清理可能存在的旧的、无效的状态
    local unitToken = UnitTokenFromGUID(guid)
    GPlaterNS.Utils:Log("GetNameplate: UnitTokenFromGUID for %s is [%s]", 3, "nameplates", guid, tostring(unitToken))

    if unitToken and UnitExists(unitToken) then
        GPlaterNS.Utils:Log("GetNameplate: UnitToken [%s] exists for GUID %s. Calling RegisterUnit.", 3, "nameplates", unitToken, guid)
        self:RegisterUnit(guid, unitToken) -- RegisterUnit 内部有自己的日志
        np = GPlaterNS.State.Nameplates[guid] -- 重新获取（可能已被RegisterUnit填充）
        if np and self:ValidateNameplate(np) then
            GPlaterNS.Utils:Log("GetNameplate: Successfully registered and validated nameplate for GUID %s.", 2, "nameplates", guid)
            return np
        else
            GPlaterNS.Utils:Log("GetNameplate: FAILED to validate nameplate for GUID %s after registration attempt.", 4, "nameplates", guid)
        end
    else
        GPlaterNS.Utils:Log("GetNameplate: No valid unitToken or unit does not exist for GUID %s (UnitToken: [%s], UnitExists: %s).", 4, "nameplates", guid, tostring(unitToken), tostring(unitToken and UnitExists(unitToken)))
    end
    GPlaterNS.Utils:Log("GetNameplate: Returning NIL for GUID %s.", 4, "nameplates", guid)
    return nil
end

function NameplateManager:RegisterUnit(guid, unit)
    if not guid or not unit or not UnitExists(unit) or UnitGUID(unit) ~= guid then 
        GPlaterNS.Utils:Log("RegisterUnit: invalid inputs", 4, "nameplates")
        return 
    end
    local np = GPlaterNS.State.Nameplates[guid] or {}
    np.unit = unit
    np.frame = C_NamePlate.GetNamePlateForUnit(unit)
    if not np.frame or not np.frame.unitFrame then 
        GPlaterNS.Utils:Log("RegisterUnit: no valid frame for guid=%s", 4, "nameplates", tostring(guid))
        return 
    end
    np.name = UnitName(unit) or "?"
    np.type = UnitIsPlayer(unit) and "enemyplayer" or "attackablenpc"
    np.timestamp = GetTime()
    GPlaterNS.State.Nameplates[guid] = np
    GPlaterNS.State.PlaterSettings[guid] = GPlaterNS.State.PlaterSettings[guid] or {
        baseScale = np.frame.unitFrame:GetScale() or 1,
        baseStrata = np.frame.unitFrame:GetFrameStrata() or "MEDIUM"
    }
end

function NameplateManager:CleanupNameplateInfo(id)
    if not id then
        return
    end
    local np = GPlaterNS.State.Nameplates[id]
    if np and np.frame and np.frame.unitFrame then
        local resetEffects = {
            COLOR = { healthBar = nil, nameText = nil, border = nil },
            SCALE = nil, FLASH = false, HIDE = false, TOP = false, LOW = false, UNIQUE = false,
            sourceAura = {}
        }
        GPlaterNS.EffectUtils:ApplyEffects(np.frame.unitFrame, id, resetEffects, np.type)
        if np.frame.unitFrame.GPlaterNameTextUpdate then
            np.frame.unitFrame.GPlaterNameTextUpdate:SetScript("OnUpdate", nil)
            np.frame.unitFrame.GPlaterNameTextUpdate.unitFrameRef = nil
            np.frame.unitFrame.GPlaterNameTextUpdate:Hide()
            np.frame.unitFrame.GPlaterNameTextUpdate = nil
            np.frame.unitFrame.GPlaterNameTextColor = nil
        end
        if np.frame.unitFrame.GPlaterFlashTimer then
            np.frame.unitFrame.GPlaterFlashTimer = nil
        end
        if np.frame.unitFrame.GPlaterEffects then
            np.frame.unitFrame.GPlaterEffects = {}
        end
    end
    if GPlaterNS.State.UnitsMarkedAsUniqueByGPlater[id] then
        local uniqueAuraID = GPlaterNS.State.UnitsMarkedAsUniqueByGPlater[id].auraID
        GPlaterNS.EffectUtils.effectHandlers.UNIQUE.reset(
            np and np.frame and np.frame.unitFrame,
            np and np.type,
            id,
            uniqueAuraID
        )
    end
    GPlaterNS.State.ActiveAuras[id] = nil
    GPlaterNS.State.PlaterSettings[id] = nil
    GPlaterNS.State.HiddenNameplates[id] = nil
    GPlaterNS.State.UnitsMarkedAsUniqueByGPlater[id] = nil
    GPlaterNS.State.Nameplates[id] = nil
    if GPlaterNS.State.EffectCache then
        GPlaterNS.State.EffectCache[id] = nil
    end
end

function NameplateManager:CleanupInvalidData()
    for guid, np in pairs(GPlaterNS.State.Nameplates) do
        if not self:ValidateNameplate(np) then
            self:CleanupNameplateInfo(guid)
        elseif np.frame and np.frame.GPlaterEffects then
            local hasActiveEffects = false
            for spellID, _ in pairs(GPlaterNS.State.ActiveAuras[guid] or {}) do
                if GPlaterNS.State.auraConfig[spellID] then
                    hasActiveEffects = true
                    break
                end
            end
            if not hasActiveEffects then
                np.frame.GPlaterEffects = {}
            end
        end
    end
end

function NameplateManager:UpdateAndApplyAllEffects(guid)
    GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: Processing GUID %s", 2, "nameplates", tostring(guid))
    local np = self:GetNameplate(guid)
    if not np then
        GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: No valid nameplate for GUID %s", 3, "nameplates", tostring(guid))
        return
    end

    local frame = np.frame.unitFrame
    local unitType = np.type
    local activeUnitAuras = GPlaterNS.State.ActiveAuras[guid] or {}

    if not GPlaterNS.State.EffectCache then GPlaterNS.State.EffectCache = {} end
    local cacheKey = guid
    
    local auraHashParts = {}
    for spellID, auraData in pairs(activeUnitAuras) do
        table.insert(auraHashParts, spellID .. ":" .. (auraData.applications or 1))
    end
    table.sort(auraHashParts) -- 确保哈希顺序一致
    local auraHash = table.concat(auraHashParts, ";")
    GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: GUID %s - Current Aura Hash: %s", 3, "nameplates", guid, auraHash)

    local cache = GPlaterNS.State.EffectCache[cacheKey]
    if cache and cache.hash == auraHash and not cache.auraListChanged then
        GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: Using cached effects for GUID %s", 3, "nameplates", guid)
        GPlaterNS.EffectUtils:ApplyEffects(frame, guid, cache.effects, unitType)
        return
    end
    
    if cache then
        GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: Cache miss for GUID %s. Old Hash: %s, AuraListChanged: %s", 2, "nameplates", guid, tostring(cache.hash), tostring(cache.auraListChanged))
    else
        GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: No cache for GUID %s. Computing new effects.", 2, "nameplates", guid)
    end

    local newSortedAuras = {} -- 使用这个新的表来构建
    for key_auraID_str, auraConfigEntry in pairs(GPlaterNS.State.auraConfig) do
        local cfg = auraConfigEntry.config
        if cfg.isKnown then
            GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: Processing rule for key [%s] because cfg.isKnown is true.", 3, "nameplates", key_auraID_str) 
            local isActuallyActive = false
            local effectiveTimestamp = 0
            local durationForSortEntry = 0
            local stacksForSortEntry = 1
            local representativeAuraData = nil

            if auraConfigEntry.isCombination then
                local allRequiredPresent = true
                local latestTimestampForCombination = 0
                if #auraConfigEntry.requiredIDs == 0 then allRequiredPresent = false end -- 安全检查

                for _, reqID in ipairs(auraConfigEntry.requiredIDs) do
                    if not (activeUnitAuras[reqID] and activeUnitAuras[reqID].spellId == reqID) then
                        allRequiredPresent = false
                        break
                    end
                    if activeUnitAuras[reqID].timestamp > latestTimestampForCombination then
                        latestTimestampForCombination = activeUnitAuras[reqID].timestamp
                    end
                end

                if allRequiredPresent then
                    isActuallyActive = true
                    effectiveTimestamp = latestTimestampForCombination
                
                local shortestOriginalDuration = math.huge
                for _, reqID in ipairs(auraConfigEntry.requiredIDs) do
                    if activeUnitAuras[reqID] then
                        shortestOriginalDuration = math.min(shortestOriginalDuration, activeUnitAuras[reqID].duration or 0)
                    else 
                        shortestOriginalDuration = 0 
                        GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: ERROR - Missing activeUnitAuras data for reqID %s in active combo %s", 4, "nameplates", tostring(reqID), key_auraID_str)
                        break
                    end
                end
                durationForSortEntry = (shortestOriginalDuration == math.huge) and 0 or shortestOriginalDuration
                stacksForSortEntry = 1 -- 层数对组合光环无效 (或始终为1)
                -- 代表性光环数据，如果需要，可以取组合中的第一个
                if #auraConfigEntry.requiredIDs > 0 and activeUnitAuras[auraConfigEntry.requiredIDs[1]] then
                    representativeAuraData = activeUnitAuras[auraConfigEntry.requiredIDs[1]]
                end
            end
        else -- 非组合光环 (单个光环规则)
                local singleAuraID = auraConfigEntry.requiredIDs[1]
                if activeUnitAuras[singleAuraID] and activeUnitAuras[singleAuraID].spellId == singleAuraID then
                    isActuallyActive = true
                    effectiveTimestamp = activeUnitAuras[singleAuraID].timestamp
                    durationForSortEntry = activeUnitAuras[singleAuraID].duration or 0
                    stacksForSortEntry = activeUnitAuras[singleAuraID].applications or 1
                    representativeAuraData = activeUnitAuras[singleAuraID]
                    
                    if cfg.minStacks > 0 and stacksForSortEntry < cfg.minStacks then
                        isActuallyActive = false
                    end

                    if isActuallyActive and cfg.cancelAt30Percent then
                         if representativeAuraData and representativeAuraData.effectiveExpirationTime and 
                            representativeAuraData.effectiveExpirationTime ~= math.huge and 
                            representativeAuraData.effectiveExpirationTime <= GetTime() then
                            GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: Aura effect for %s (key: %s) cancelled due to 30%% rule.", 3, "nameplates", guid, tostring(key_auraID_str))
                            isActuallyActive = false 
                        end
                    end
                end
            end
            if isActuallyActive then
                table.insert(newSortedAuras, {
                    spellID_or_key = key_auraID_str,
                    config = cfg,
                    applicationTime = effectiveTimestamp,
                    duration = durationForSortEntry,
                    stacks = stacksForSortEntry,
                    auraData = representativeAuraData -- Store representative data if needed for specific effects
                })
            end
        end
    end
    
    table.sort(newSortedAuras, function(a, b)
        if a.applicationTime ~= b.applicationTime then
            return a.applicationTime > b.applicationTime 
        else
            local aConfigEntry = GPlaterNS.State.auraConfig[a.spellID_or_key]
            local bConfigEntry = GPlaterNS.State.auraConfig[b.spellID_or_key]
            
            local aNumRequired = aConfigEntry and #aConfigEntry.requiredIDs or 0
            local bNumRequired = bConfigEntry and #bConfigEntry.requiredIDs or 0
            
            if aNumRequired ~= bNumRequired then
                return aNumRequired > bNumRequired 
            else
                return tostring(a.spellID_or_key) < tostring(b.spellID_or_key)
            end
        end
    end)
    
    GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: GUID %s - Sorted %d active effect rules", 2, "nameplates", guid, #newSortedAuras)
    for i, sa_entry in ipairs(newSortedAuras) do
        GPlaterNS.Utils:Log("  SortedRule[%d]: key=%s, effectType=%s, stacks=%d, isKnown=%s, applyHB=%s, HBColor=%s, applyScale=%s, Scale=%s", 3, "nameplates", 
            i, sa_entry.spellID_or_key, 
            tostring(sa_entry.config.effect), 
            sa_entry.stacks, 
            tostring(sa_entry.config.isKnown),
            tostring(sa_entry.config.applyHealthBar),
            tostring(sa_entry.config.healthBarColor),
            tostring(sa_entry.config.applyScale),
            tostring(sa_entry.config.scale)
        )
    end

    -- 初始化最终效果表 (仅一次)
    local finalEffects = {
        COLOR = { healthBar = nil, nameText = nil, border = nil },
        SCALE = nil, FLASH = false, HIDE = false, TOP = false, LOW = false, UNIQUE = false,
        sourceAura = { healthBar = nil, nameText = nil, border = nil, scale = nil, flash = nil, hide = nil, top = nil, low = nil, unique = nil }
    }
    
    -- 效果聚合：第一遍处理 UNIQUE 效果 (使用 newSortedAuras)
    local hasActiveUniqueOnThisUnit = false
    local uniqueSourceKey = nil
    for _, auraEntry in ipairs(newSortedAuras) do
        local cfg = auraEntry.config
        -- minStacks 检查在这里仍然适用，因为 cfg.minStacks 对组合已被设为0
        if (cfg.minStacks == 0 or auraEntry.stacks >= cfg.minStacks) then 
            if cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_UNIQUE then
                hasActiveUniqueOnThisUnit = true
                finalEffects.UNIQUE = true
                finalEffects.sourceAura.unique = auraEntry.spellID_or_key
                uniqueSourceKey = auraEntry.spellID_or_key
                GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: GUID %s - HAS_UNIQUE_EFFECT from key %s", 2, "nameplates", guid, auraEntry.spellID_or_key)
                break 
            end
        end
    end

    -- 效果聚合：第二遍处理其他效果 (使用 newSortedAuras)
    for _, auraEntry in ipairs(newSortedAuras) do
        local key = auraEntry.spellID_or_key
        local cfg = auraEntry.config
        local stacks = auraEntry.stacks 

        if (cfg.minStacks == 0 or stacks >= cfg.minStacks) then -- cfg.minStacks 对于组合已经是0
             if (hasActiveUniqueOnThisUnit and key == uniqueSourceKey) or not hasActiveUniqueOnThisUnit then
                GPlaterNS.Utils:Log("  Aggregating: key=%s, stacks=%d, minStacks=%d, effectType=%s -> Qualified", 3, "nameplates", key, stacks, cfg.minStacks, cfg.effect)
                
                if cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_HIDE then
                    if not hasActiveUniqueOnThisUnit and not finalEffects.HIDE then -- 只有当没有 UNIQUE 且 HIDE 未被更高优先级设置时
                        finalEffects.HIDE = true
                        finalEffects.sourceAura.hide = key
                    end
                end
                if cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_TOP then
                    if not finalEffects.TOP then -- 允许较低优先级的 LOW 被覆盖
                        finalEffects.TOP = true
                        finalEffects.LOW = false 
                        finalEffects.sourceAura.top = key
                        finalEffects.sourceAura.low = nil
                    end
                elseif cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_LOW then
                    if not finalEffects.TOP and not finalEffects.LOW then -- TOP 优先于 LOW
                        finalEffects.LOW = true
                        finalEffects.sourceAura.low = key
                    end
                end
                if cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_FLASH then
                    if not finalEffects.FLASH then
                        finalEffects.FLASH = true
                        finalEffects.sourceAura.flash = key
                    end
                end

                if cfg.applyScale and finalEffects.SCALE == nil then
                    finalEffects.SCALE = cfg.scale
                    finalEffects.sourceAura.scale = key
                end
                if cfg.applyHealthBar and finalEffects.COLOR.healthBar == nil then
                    finalEffects.COLOR.healthBar = cfg.healthBarColor
                    finalEffects.sourceAura.healthBar = key
                end
                if cfg.applyNameText and finalEffects.COLOR.nameText == nil then
                    finalEffects.COLOR.nameText = cfg.nameTextColor
                    finalEffects.sourceAura.nameText = key
                end
                if cfg.applyBorder and finalEffects.COLOR.border == nil then
                    finalEffects.COLOR.border = cfg.borderColor
                    finalEffects.sourceAura.border = key
                end
            else
                 GPlaterNS.Utils:Log("    -> Skipped due to UNIQUE conflict (key %s)", 3, "nameplates", key)
            end
        else
             GPlaterNS.Utils:Log("    -> Skipped due to minStacks not met (key %s, stacks %d < %d)", 3, "nameplates", key, stacks, cfg.minStacks)
        end
    end

    -- 处理外部 UNIQUE 效果（当此单位没有自己的 UNIQUE 时）
    if not hasActiveUniqueOnThisUnit then
        for otherUniqueGuid, uniqueData in pairs(GPlaterNS.State.UnitsMarkedAsUniqueByGPlater) do
            if otherUniqueGuid ~= guid then -- 如果其他单位标记为 UNIQUE
                finalEffects.HIDE = true
                finalEffects.sourceAura.hide = "EXTERNAL_UNIQUE_" .. otherUniqueGuid
                GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: GUID %s - SET HIDE due to EXTERNAL_UNIQUE from %s", 2, "nameplates", guid, otherUniqueGuid)
                break 
            end
        end
    end

    -- 如果是 HIDE（且非自身 UNIQUE 效果导致），清除其他视觉效果
    if finalEffects.HIDE and not hasActiveUniqueOnThisUnit then
        GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: GUID %s - IS_HIDE (non-self-unique). Clearing visual effects.", 2, "nameplates", guid)
        finalEffects.COLOR = { healthBar = nil, nameText = nil, border = nil }
        finalEffects.SCALE = nil
        finalEffects.FLASH = false
        finalEffects.TOP = false
        finalEffects.LOW = false
        -- HIDE 和 UNIQUE 的 sourceAura 已经设置，不需要清除
    end

    -- 如果自身有 UNIQUE，强制不隐藏（覆盖其他规则可能导致的 HIDE）
    if hasActiveUniqueOnThisUnit and finalEffects.HIDE then
        GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: GUID %s - HAS_UNIQUE, overriding HIDE to false.", 2, "nameplates", guid)
        finalEffects.HIDE = false
        finalEffects.sourceAura.hide = nil -- 清除可能由其他规则设置的 HIDE 源
    end

    -- 重置所有效果到基础状态，然后再应用最终聚合的效果
    -- 这确保了从任何先前状态的干净过渡
    GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: GUID %s - Resetting all effects to base states before applying final.", 2, "nameplates", guid)
    GPlaterNS.EffectUtils.ColorEffect:Reset(frame, "healthBar", unitType, guid)
    GPlaterNS.EffectUtils.ColorEffect:Reset(frame, "nameText", unitType, guid) -- guid for nameTextUpdateQueue
    GPlaterNS.EffectUtils.ColorEffect:Reset(frame, "border", unitType, guid)
    GPlaterNS.EffectUtils.ScaleEffect:Reset(frame, guid)
    GPlaterNS.EffectUtils.LevelEffect:Reset(frame, guid)
    GPlaterNS.EffectUtils.FlashEffect:Reset(frame) 
    GPlaterNS.EffectUtils.HideEffect:ResetToBase(frame, guid) -- 这个会处理 Show() 如果没有任何隐藏原因

    -- 应用最终聚合的效果
    GPlaterNS.State.EffectCache[cacheKey] = {
        hash = auraHash,
        effects = finalEffects,
        auraListChanged = false 
    }
    -- 增强 finalEffects 的日志输出
    local fe_log = "FinalEffects -> HIDE:" .. tostring(finalEffects.HIDE) ..
                 " UNIQUE:" .. tostring(finalEffects.UNIQUE) ..
                 " SCALE:" .. tostring(finalEffects.SCALE or "nil") ..
                 " HBColor:" .. tostring(finalEffects.COLOR.healthBar or "nil") ..
                 " NameColor:" .. tostring(finalEffects.COLOR.nameText or "nil") ..
                 " BorderColor:" .. tostring(finalEffects.COLOR.border or "nil") ..
                 " FLASH:" .. tostring(finalEffects.FLASH) ..
                 " TOP:" .. tostring(finalEffects.TOP) ..
                 " LOW:" .. tostring(finalEffects.LOW)
    GPlaterNS.Utils:Log("UpdateAndApplyAllEffects: Applying final aggregated effects for GUID %s: %s", 1, "nameplates", guid, fe_log)
    
    GPlaterNS.EffectUtils:ApplyEffects(frame, guid, finalEffects, unitType)
end

local expirationQueue = {} -- { guid, spellID, expirationTime }

function AuraManager:UpdateAuraState(id, sID, data)
    if not self then
        if GPlaterNS and GPlaterNS.Utils and GPlaterNS.Utils.Log then
            GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): CRITICAL ERROR - 'self' is nil!", 4, "auras")
        end
        return false
    end
    GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): 'self' is valid (type: %s). Function CALLED for GUID %s, spellID %d.", 1, "auras", type(self), tostring(id), sID)


    if not id or not sID or not data then 
        GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): ERROR - invalid inputs (id:%s, sID:%s, data:%s)", 4, "auras", tostring(id), tostring(sID), tostring(data))
        return false 
    end
    local existing = GPlaterNS.State.ActiveAuras[id] and GPlaterNS.State.ActiveAuras[id][sID]
    GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): 'existing' variable is: %s", 1, "auras", tostring(existing))

    GPlaterNS.State.ActiveAuras[id] = GPlaterNS.State.ActiveAuras[id] or {}
    GPlaterNS.State.ActiveAuras[id][sID] = data 
    GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): ActiveAuras updated.", 1, "auras")

    -- expirationQueue logic (保持不变)
    for i = #expirationQueue, 1, -1 do
        local entry = expirationQueue[i]
        if entry.guid == id and entry.spellID == sID then
            table.remove(expirationQueue, i)
        end
    end
    if data.effectiveExpirationTime and data.effectiveExpirationTime ~= math.huge then
        table.insert(expirationQueue, { guid = id, spellID = sID, expirationTime = data.effectiveExpirationTime })
        table.sort(expirationQueue, function(a, b) return a.expirationTime < b.expirationTime end)
    end

    -- EffectCache logic (保持不变)
    if GPlaterNS.State.EffectCache and GPlaterNS.State.EffectCache[id] then
        if not existing or (existing.applications ~= (data.applications or 1)) then
            GPlaterNS.State.EffectCache[id].auraListChanged = true
        end
    end
    
    local applicationsInData = data.applications or 1
    local applicationsInExisting = existing and existing.applications
    local condition_NotExisting = not existing
    local condition_AppsChanged = existing and (applicationsInExisting ~= applicationsInData)

    GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): Before 'Condition B'. not existing: %s. existing.apps: %s. data.apps: %s. appsChanged: %s", 1, "auras", 
        tostring(condition_NotExisting), 
        tostring(applicationsInExisting), 
        tostring(applicationsInData),
        tostring(condition_AppsChanged)
    )

    if condition_NotExisting or condition_AppsChanged then -- Condition B
        GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): Condition B is TRUE. Proceeding.", 1, "auras")
        local np = GPlaterNS.NameplateManager:GetNameplate(id) 
        GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): GetNameplate returned: %s", 1, "auras", tostring(np))
        if np and np.frame and np.frame.unitFrame then
            GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): Nameplate object is VALID.", 1, "auras")
            local sID_string_key = tostring(sID) 
            local cfgEntry = GPlaterNS.State.auraConfig[sID_string_key]
            local cfg = cfgEntry and cfgEntry.config 
            GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): Looked up cfgEntry for key '%s', found: %s. Cfg found: %s", 1, "auras", sID_string_key, tostring(cfgEntry ~= nil), tostring(cfg ~= nil))

            if cfgEntry and cfgEntry.config and cfgEntry.config.effect == GPlaterNS.Constants.EFFECT_TYPE_UNIQUE then
                GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): Applying UNIQUE effect for sID [%s]", 1, "auras", tostring(sID))
                GPlaterNS.EffectUtils.effectHandlers.UNIQUE.apply(np.frame.unitFrame, np.type, id, sID_string_key)
            end
            GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): >>> About to call UpdateAndApplyAllEffects for GUID %s, spellID %d", 1, "auras", id, sID)
            GPlaterNS.NameplateManager:UpdateAndApplyAllEffects(id) 
            GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): <<< Successfully called UpdateAndApplyAllEffects for GUID %s, spellID %d.", 1, "auras", id, sID)
        else
            GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): No valid nameplate object (np is nil or frame invalid) for GUID %s.", 4, "auras", id)
        end
    else
        GPlaterNS.Utils:Log("UpdateAuraState (ULTRA DEBUG): Condition B is FALSE. Aura %s for GUID %s existed and applications (%s) did not change from (%s), or initial data issue. No immediate effect update triggered.", 1, "auras", 
            tostring(sID), 
            tostring(id), 
            tostring(applicationsInData), 
            tostring(applicationsInExisting)
        )
    end

    return existing and (existing.applications ~= (data.applications or 1) or existing.expirationTime ~= (data.expirationTime or math.huge))
end

-- 请找到并完整替换 AuraManager:RemoveAuraState 函数
function AuraManager:RemoveAuraState(id, sID)
    GPlaterNS.Utils:Log("RemoveAuraState: Called for GUID %s, spellID %d", 3, "auras", tostring(id), tostring(sID))
    if GPlaterNS.State.ActiveAuras[id] and GPlaterNS.State.ActiveAuras[id][sID] then
        GPlaterNS.State.ActiveAuras[id][sID] = nil
        if not next(GPlaterNS.State.ActiveAuras[id]) then 
            GPlaterNS.State.ActiveAuras[id] = nil
        end

        for i = #expirationQueue, 1, -1 do
            local entry = expirationQueue[i]
            if entry.guid == id and entry.spellID == sID then
                table.remove(expirationQueue, i)
                GPlaterNS.Utils:Log("RemoveAuraState: Removed queue entry for GUID %s, spellID %d", 3, "auras", id, sID)
            end
        end

        if GPlaterNS.State.EffectCache and GPlaterNS.State.EffectCache[id] then
            GPlaterNS.State.EffectCache[id].auraListChanged = true
            GPlaterNS.Utils:Log("RemoveAuraState: Marked auraListChanged for GUID %s due to aura %d removal", 3, "auras", id, sID)
        end

        local np = GPlaterNS.NameplateManager:GetNameplate(id)
        if np and np.frame and np.frame.unitFrame then
            local sID_string_key = tostring(sID) -- *** 使用字符串键 ***
            local cfgEntry = GPlaterNS.State.auraConfig[sID_string_key]
            local cfg = cfgEntry and cfgEntry.config
            GPlaterNS.Utils:Log("RemoveAuraState: Looked up cfgEntry for sID [%s] (using key: '%s'), found: %s. Cfg found: %s", 3, "auras", tostring(sID), sID_string_key, tostring(cfgEntry ~= nil), tostring(cfg ~= nil))

            if cfgEntry and cfgEntry.config and cfgEntry.config.effect == GPlaterNS.Constants.EFFECT_TYPE_UNIQUE then -- 使用 cfgEntry.config
                GPlaterNS.Utils:Log("RemoveAuraState: Resetting UNIQUE effect for sID [%s]", 3, "auras", tostring(sID))
                GPlaterNS.EffectUtils.effectHandlers.UNIQUE.reset(np.frame.unitFrame, np.type, id, cfgEntry.config.auraID)
            end
            GPlaterNS.Utils:Log("RemoveAuraState: About to call UpdateAndApplyAllEffects for GUID %s, spellID %d", 2, "auras", id, sID)
            GPlaterNS.NameplateManager:UpdateAndApplyAllEffects(id)
            GPlaterNS.Utils:Log("RemoveAuraState: Successfully called UpdateAndApplyAllEffects for GUID %s, spellID %d. Effect update triggered.", 2, "auras", id, sID)
        else
            GPlaterNS.Utils:Log("RemoveAuraState: No valid nameplate object for GUID %s when trying to trigger effect update for spellID %d (np is nil or frame invalid).", 4, "auras", id, sID)
        end
    else
        GPlaterNS.Utils:Log("RemoveAuraState: Aura %s not active on GUID %s. No removal action taken.", 3, "auras", tostring(sID), tostring(id))
    end
end

function EventManager:HandleCombatLog(ts, sub, sIDsrc, dID, spID, duration, amt, relevantAuraKey)
    GPlaterNS.Utils:Log("HandleCombatLog: 子事件: %s, 光环ID: %s, 目标GUID: %s, 相关键: %s", 2, "events", tostring(sub), tostring(spID), tostring(dID), tostring(relevantAuraKey))

    local nI = NameplateManager:GetNameplate(dID)
    if not nI then
        GPlaterNS.Utils:Log("HandleCombatLog: 无有效姓名板，目标GUID=%s", 3, "events", tostring(dID))
        return
    end

    local uFrame = nI.frame.unitFrame
    local uType = nI.type
    local pvpColoringEnabled = GPlaterNS.Config:Get({"AuraColoring", "settings", "pvpColoring"}, true)
    
    if not pvpColoringEnabled and uType == "enemyplayer" then
        if GPlaterNS.State.ActiveAuras[dID] and GPlaterNS.State.ActiveAuras[dID][spID] then
            if not GPlaterNS.AuraManager then
                GPlaterNS.Utils:Log("HandleCombatLog: 严重错误 - GPlaterNS.AuraManager 为空!", 4, "events")
                return
            end
            if type(GPlaterNS.AuraManager.RemoveAuraState) ~= "function" then
                GPlaterNS.Utils:Log("HandleCombatLog: 严重错误 - GPlaterNS.AuraManager.RemoveAuraState 不是函数!", 4, "events")
                return
            end
            GPlaterNS.AuraManager:RemoveAuraState(dID, spID)
        end
        GPlaterNS.Utils:Log("HandleCombatLog: 敌对玩家禁用 PvP 着色", 3, "events")
        return
    end

    if not relevantAuraKey then
        GPlaterNS.Utils:Log("HandleCombatLog: 无相关光环键，spID: %s", 4, "events", tostring(spID))
        return 
    end

    local cfgEntryForEffects = GPlaterNS.State.auraConfig[relevantAuraKey]
    if not cfgEntryForEffects or not cfgEntryForEffects.config then
        GPlaterNS.Utils:Log("HandleCombatLog: 无法获取 cfgEntryForEffects，键: %s", 4, "events", tostring(relevantAuraKey))
        return
    end
    local cfg = cfgEntryForEffects.config

    if sub == "SPELL_AURA_REMOVED" then
        local wasUnique = cfg.effect == GPlaterNS.Constants.EFFECT_TYPE_UNIQUE
        GPlaterNS.AuraManager:RemoveAuraState(dID, spID)
        if wasUnique then
            GPlaterNS.EffectUtils.effectHandlers.UNIQUE.reset(uFrame, uType, dID, relevantAuraKey)
        end
        GPlaterNS.Utils:Log("HandleCombatLog: 光环 %d (键: %s) 从 %s 移除", 2, "events", spID, tostring(relevantAuraKey), tostring(dID))
    else
        if sub == "SPELL_AURA_APPLIED_DOSE" and cfg.minStacks == 0 and not cfgEntryForEffects.isCombination then 
            return 
        end

        local aGD = { 
            spellId = spID,
            applications = amt or 1,
            timestamp = ts,
            duration = 0,
        }

        if sub == "SPELL_AURA_APPLIED" or sub == "SPELL_AURA_REFRESH" then
            local unit = UnitTokenFromGUID(dID)
            local auraDuration, auraExpirationTime = 0, 0
            if unit then
                for i = 1, 40 do
                    local uAuraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
                    if uAuraData and uAuraData.spellId == spID and (uAuraData.sourceGUID == GPlaterNS.State.playerGUID or uAuraData.sourceGUID == GPlaterNS.State.petGUID) then
                        auraDuration = uAuraData.duration or 0
                        auraExpirationTime = uAuraData.expirationTime or 0
                        break
                    end
                end
            else
                GPlaterNS.Utils:Log("HandleCombatLog: 目标GUID %s 无单位标识，无法获取光环持续时间", 3, "events", tostring(dID))
            end

            aGD.duration = auraDuration
            aGD.expirationTime = auraExpirationTime > 0 and auraExpirationTime or math.huge
            if cfg.cancelAt30Percent and not cfgEntryForEffects.isCombination then
                if auraDuration > 0 and auraExpirationTime > 0 then
                    aGD.actualMaxDuration = auraDuration
                    aGD.effectiveExpirationTime = auraExpirationTime - (auraDuration * 0.7)
                else
                    aGD.actualMaxDuration = auraDuration
                    aGD.effectiveExpirationTime = aGD.expirationTime
                end
            else
                aGD.actualMaxDuration = auraDuration
                aGD.effectiveExpirationTime = aGD.expirationTime
            end
        elseif sub == "SPELL_AURA_APPLIED_DOSE" then
            local existingAura = GPlaterNS.State.ActiveAuras[dID] and GPlaterNS.State.ActiveAuras[dID][spID]
            if existingAura then
                aGD.duration = existingAura.duration
                aGD.expirationTime = existingAura.expirationTime
                aGD.effectiveExpirationTime = existingAura.effectiveExpirationTime
                aGD.actualMaxDuration = existingAura.actualMaxDuration
            else
                local unit = UnitTokenFromGUID(dID)
                local auraDuration, auraExpirationTime = 0, 0
                if unit then
                    for i = 1, 40 do
                        local uAuraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
                        if uAuraData and uAuraData.spellId == spID and (uAuraData.sourceGUID == GPlaterNS.State.playerGUID or uAuraData.sourceGUID == GPlaterNS.State.petGUID) then
                            auraDuration = uAuraData.duration or 0
                            auraExpirationTime = uAuraData.expirationTime or 0
                            break
                        end
                    end
                end
                aGD.duration = auraDuration
                aGD.expirationTime = auraExpirationTime > 0 and auraExpirationTime or math.huge
                aGD.effectiveExpirationTime = aGD.expirationTime
                aGD.actualMaxDuration = aGD.duration
            end
        end
        
        if not GPlaterNS.AuraManager then
            GPlaterNS.Utils:Log("HandleCombatLog: 严重错误 - GPlaterNS.AuraManager 为空!", 4, "events")
            return
        end
        if type(GPlaterNS.AuraManager.UpdateAuraState) ~= "function" then
            GPlaterNS.Utils:Log("HandleCombatLog: 严重错误 - GPlaterNS.AuraManager.UpdateAuraState 不是函数!", 4, "events")
            return
        end
        if GPlaterNS.AuraManager:UpdateAuraState(dID, spID, aGD) then
            GPlaterNS.Utils:Log("HandleCombatLog: 光环 %d (键: %s) 在 %s 上应用/刷新/层数变更。层数: %d", 2, "events", spID, tostring(relevantAuraKey), tostring(dID), aGD.applications)
        else
            GPlaterNS.Utils:Log("HandleCombatLog: 光环 %d (键: %s) 在 %s 上的状态更新未触发变化。层数: %d", 3, "events", spID, tostring(relevantAuraKey), tostring(dID), aGD.applications)
        end
    end
end

function EventManager:HandleNamePlateUnitAdded(unit)
    if not unit or not UnitExists(unit) or not UnitCanAttack("player", unit) then
        return
    end
    local guid = UnitGUID(unit)
    if not guid then 
        GPlaterNS.Utils:Log("HandleNamePlateUnitAdded: no guid", 4, "events")
        return 
    end
    NameplateManager:RegisterUnit(guid, unit)
end

function EventManager:HandleNamePlateUnitRemoved(unit)
    if not unit or not UnitExists(unit) then 
        return 
    end
    local id = UnitGUID(unit)
    if not id then 
        GPlaterNS.Utils:Log("HandleNamePlateUnitRemoved: no guid", 4, "events")
        return 
    end
    NameplateManager:CleanupNameplateInfo(id)
end

function EventManager:HandleSpecChange()
    GPlaterNS.Config:RecheckAuraKnowledgeAndUpdateSet()
end

function EventManager:CheckAuraExpiration()
    local currentTime = GetTime()
    local guidsToUpdate = {}

    -- 处理所有已过期的光环
    while #expirationQueue > 0 and expirationQueue[1].expirationTime <= currentTime do
        local entry = table.remove(expirationQueue, 1)
        local guid, spellID = entry.guid, entry.spellID
        if GPlaterNS.State.ActiveAuras[guid] and GPlaterNS.State.ActiveAuras[guid][spellID] then
            GPlaterNS.AuraManager:RemoveAuraState(guid, spellID)
            guidsToUpdate[guid] = GPlaterNS.State.auraConfig[spellID] and GPlaterNS.State.auraConfig[spellID].config.effect == GPlaterNS.Constants.EFFECT_TYPE_UNIQUE and spellID or nil
            GPlaterNS.Utils:Log("CheckAuraExpiration: Aura %d expired for GUID %s", 2, "events", spellID, tostring(guid))
        end
    end

    -- 更新受影响单位的效果
    for guid, uniqueSpellID in pairs(guidsToUpdate) do
        local np = GPlaterNS.NameplateManager:GetNameplate(guid)
        if np and np.frame and np.frame.unitFrame then
            if uniqueSpellID then
                GPlaterNS.EffectUtils.effectHandlers.UNIQUE.reset(np.frame.unitFrame, np.type, guid, uniqueSpellID)
            end
            GPlaterNS.NameplateManager:UpdateAndApplyAllEffects(guid)
            GPlaterNS.Utils:Log("CheckAuraExpiration: Triggered effect update for GUID %s, uniqueSpellID %s", 2, "events", guid, tostring(uniqueSpellID))
        else
            GPlaterNS.Utils:Log("CheckAuraExpiration: No valid nameplate for GUID %s", 3, "events", guid)
        end
    end
end

local tickers = {}

local function InitializeTimers()
    tickers.main = C_Timer.NewTicker(0.5, function()
    for guid, np in pairs(GPlaterNS.State.Nameplates) do
        if np.frame and np.frame.GPlaterFlashTimer then
            if GetTime() < np.frame.GPlaterFlashTimer then -- 检查是否仍在5秒持续时间内
                local uF = np.frame.unitFrame
                if uF and uF:IsShown() and uF.namePlateUnitToken and UnitExists(uF.namePlateUnitToken) then
                    -- GPlaterNS.Utils:Log("Timer: Re-flashing %s", 3, "auras", guid)
                    pcall(Plater.FlashNameplateBody, uF, nil, 0.5) -- 假设 Plater.FlashNameplateBody 的第三个参数是动画片段时长
                else
                    np.frame.GPlaterFlashTimer = nil -- 无效框架，停止闪烁
                end
            else
                np.frame.GPlaterFlashTimer = nil -- 超过5秒，停止闪烁
                GPlaterNS.Utils:Log("Timer: Flash duration ended for %s", 3, "auras", guid)
            end
        end
    end
        EventManager:CheckAuraExpiration()
    end)
end

local function CleanupTimers()
    for name, ticker in pairs(tickers) do
        if ticker then
            ticker:Cancel()
            tickers[name] = nil
        end
    end
end

EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
EventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
EventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
EventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
EventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
EventFrame:RegisterEvent("PLAYER_LOGOUT")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "GPlater" then
        GPlaterNS.InitializeCoreModules()
        GPlaterNS.Config:InitializeConfig()
        C_Timer.After(1, InitializeTimers)
    elseif event == "PLAYER_LOGOUT" then
        CleanupTimers()
    elseif event == "PLAYER_ENTERING_WORLD" then
        CleanupTimers()
        C_Timer.After(1, InitializeTimers)
        C_Timer.After(10, function() GPlaterNS.Config:UpdateFriendlyNameplatesConfig() end)
        C_Timer.After(1.5, function()
            if GPlaterNS.State.PlaterSettings then
                for guid, npSettings in pairs(GPlaterNS.State.PlaterSettings) do
                    local np = GPlaterNS.NameplateManager:GetNameplate(guid)
                    if np and np.frame and np.frame.unitFrame and np.frame.unitFrame:IsVisible() then
                        local currentUnitFrame = np.frame.unitFrame
                        local newBaseScale = currentUnitFrame:GetScale() or 1
                        if npSettings.baseScale ~= newBaseScale then
                            npSettings.baseScale = newBaseScale
                        end
                    end
                end
            end
        end)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local ts, sub, _, sIDsrc, _, _, _, dID, _, _, _, spID, _, _, auraType, amt = CombatLogGetCurrentEventInfo()
        
        -- 早期退出无关子事件
        if not ({
            SPELL_AURA_APPLIED = 1,
            SPELL_AURA_REFRESH = 1,
            SPELL_AURA_APPLIED_DOSE = 1,
            SPELL_AURA_REMOVED = 1
        })[sub] then
            return
        end
        GPlaterNS.Utils:Log("CLEU: 子事件 %s, 光环ID: %s, 来源GUID: %s, 目标GUID: %s", 3, "events", sub, tostring(spID), tostring(sIDsrc), tostring(dID))
    
        -- 检查来源和目标 GUID（快速检查）
        if sIDsrc ~= GPlaterNS.State.playerGUID and sIDsrc ~= GPlaterNS.State.petGUID then
            return
        end
        if dID == GPlaterNS.State.playerGUID then
            return
        end
    
        -- 检查光环是否在 auraConfig 中相关
        local isRelevantAura = false
        local relevantAuraKey = nil
        if GPlaterNS.State.auraConfig then
            local spIDStr = tostring(spID)
            if GPlaterNS.State.auraConfig[spIDStr] then
                isRelevantAura = true
                relevantAuraKey = spIDStr
                GPlaterNS.Utils:Log("CLEU 过滤: 光环ID %s 作为直接键找到", 2, "events", spIDStr)
            else
                for key, configEntry in pairs(GPlaterNS.State.auraConfig) do
                    if configEntry.isCombination and configEntry.requiredIDs then
                        for _, reqId in ipairs(configEntry.requiredIDs) do
                            if reqId == spID then
                                isRelevantAura = true
                                relevantAuraKey = key
                                GPlaterNS.Utils:Log("CLEU 过滤: 光环ID %s 在组合键 %s 中找到", 2, "events", spIDStr, key)
                                break
                            end
                        end
                    end
                    if isRelevantAura then break end
                end
            end
        else
            GPlaterNS.Utils:Log("CLEU 过滤: auraConfig 对于光环ID %s 缺失", 4, "events", tostring(spID))
            return
        end
    
        if not isRelevantAura then
            GPlaterNS.Utils:Log("CLEU 过滤: 光环ID %s 无关", 3, "events", tostring(spID))
            return
        end
    
        -- 验证姓名板存在
        local nI = NameplateManager:GetNameplate(dID)
        if not nI then
            GPlaterNS.Utils:Log("CLEU 过滤: 目标GUID %s 无姓名板", 3, "events", tostring(dID))
            return
        end

        -- 处理事件
        GPlaterNS.Utils:Log("CLEU: 处理光环ID %s (键: %s) 在目标GUID %s 上的事件", 1, "events", tostring(spID), tostring(relevantAuraKey), tostring(dID))
        EventManager:HandleCombatLog(ts, sub, sIDsrc, dID, spID, nil, amt, relevantAuraKey)
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        EventManager:HandleNamePlateUnitAdded(...)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        EventManager:HandleNamePlateUnitRemoved(...)
    elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        EventManager:HandleSpecChange()
    end
end)