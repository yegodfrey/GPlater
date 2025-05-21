local _G = _G
local _, GPlaterNS = ...
local L = GPlaterNS.L

GPlaterNS.DefaultAuraSettings = GPlaterNS.DefaultAuraSettings or {
    healthBarColor = GPlaterNS.Constants.DEFAULT_COLOR,
    nameTextColor = GPlaterNS.Constants.DEFAULT_COLOR,
    borderColor = GPlaterNS.Constants.DEFAULT_COLOR,
    scale = 1.0,
    minStacks = 0,
    effect = GPlaterNS.Constants.EFFECT_TYPE_NONE,
    applyHealthBar = true,
    applyNameText = true,
    applyBorder = true,
    applyScale = false,
    cancelAt30Percent = false,
    skillID = "0", -- 确保默认为字符串 "0"
    isKnown = true -- 因为 skillID "0" 表示无需特定技能
}

GPlaterNS.PlaterDefaultColors = GPlaterNS.PlaterDefaultColors or {
    enemyplayer_healthbar = GPlaterNS.Constants.DEFAULT_COLOR,
    attackablenpc_healthbar = "#FFFF00",
    enemyplayer_border = GPlaterNS.Constants.DEFAULT_COLOR,
    attackablenpc_border = "#FFFF00"
}

GPlaterNS.DefaultConfig = {
    FriendlyNameplates = {
        settings = { showClassColors = false, clickThrough = false, onlyNames = false, hideBuffs = false },
        format = { width = 110, height = 25, verticalScale = 1.0 }
    },
    AuraColoring = { settings = { pvpColoring = true, resetBorderColor = GPlaterNS.Constants.DEFAULT_RESET_BORDER_COLOR }, auras = {} },
    Debug = {
        enabled = false,
        chatframe = "1",
        logCategories = {
            auras = true, nameplates = true, events = true, ui = true, utils = true, config = true
        },
        suppressionThreshold = 3,
        suppressionTimeWindow = 5
    }
}

local Config = {}
GPlaterNS.Config = Config

local ConfigConstraints -- Forward declaration

local function validateAuraEntryProperties(i, a) -- i is index, a is the aura entry table
    GPlaterNS.Utils:Log("ConfigConstraint: Aura #%d, Validating entry. AuraID: [%s], SkillID: [%s]", 3, "config", i, tostring(a.auraID), tostring(a.skillID))

    if type(a) ~= "table" then
        GPlaterNS.Utils:Log("ConfigConstraint: Aura entry #%d is not a table itself.", 4, "config", i)
        return false, string.format("Aura entry #%d is not a table", i)
    end
    if a.auraID == nil then
        GPlaterNS.Utils:Log("ConfigConstraint: Aura #%d, auraID is nil.", 4, "config", i)
        return false, string.format("Aura #%d has a nil auraID.", i)
    end
    if a.skillID == nil then
         GPlaterNS.Utils:Log("ConfigConstraint: Aura #%d, skillID is nil. Defaulting to '0'.", 3, "config", i)
         a.skillID = "0"
    end

    -- Aura ID validation using Utils function - ensure input is string
    local auraIdConfig = {
        entityName = "Aura ID (ConstraintCheck)",
        allowCombo = true, minPartsInCombo = 2,
        allowZero = false, allowEmpty = false, convertSingleToNumber = true,
        errorKeyEmpty = "ERROR_AURA_ID_EMPTY", errorKeyStructure = "ERROR_AURA_ID_INVALID_STRUCTURE",
        errorKeyComboNotAllowed = "ERROR_AURA_ID_COMBO_NOT_ALLOWED", errorKeyComboTooFewParts = "ERROR_AURA_ID_COMBO_TOO_FEW_PARTS",
        errorKeyComboInvalidPart = "ERROR_AURA_ID_COMBO_INVALID_PART", errorKeySingleInvalidFormat = "ERROR_AURA_ID_SINGLE_INVALID_FORMAT"
    }
    -- Convert a.auraID to string before passing to the utility
    local isValidAuraID, _, auraIdErrorMsgOrKey = GPlaterNS.Utils:ParseAndValidateIdString(tostring(a.auraID), auraIdConfig)
    if not isValidAuraID then
        local errMsg = (type(auraIdErrorMsgOrKey) == "string" and L(auraIdErrorMsgOrKey, "Default error for aura ID: %s", tostring(a.auraID))) or
                       string.format("Aura #%d has an invalid auraID: [%s].", i, tostring(a.auraID))
        GPlaterNS.Utils:Log("ConfigConstraint: Aura #%d, AuraID validation failed. Input was [%s]. Message: %s", 4, "config", i, tostring(a.auraID), errMsg)
        return false, errMsg
    end

    -- Skill ID validation using Utils function - ensure input is string
    local skillIdConfig = {
        entityName = "Skill ID (ConstraintCheck)",
        allowCombo = true, minPartsInCombo = 1,
        allowZero = true, allowEmpty = true, convertSingleToNumber = false,
        errorKeyEmpty = "ERROR_SKILL_ID_EMPTY", errorKeyStructure = "ERROR_SKILL_ID_INVALID_STRUCTURE",
        errorKeyComboNotAllowed = "ERROR_SKILL_ID_COMBO_NOT_ALLOWED", errorKeyComboTooFewParts = "ERROR_SKILL_ID_COMBO_TOO_FEW_PARTS",
        errorKeyComboInvalidPart = "ERROR_SKILL_ID_COMBO_INVALID_PART", errorKeySingleInvalidFormat = "ERROR_SKILL_ID_SINGLE_INVALID_FORMAT"
    }
    -- Convert a.skillID to string before passing to the utility
    local isValidSkillID, _, skillIdErrorMsgOrKey = GPlaterNS.Utils:ParseAndValidateIdString(tostring(a.skillID), skillIdConfig)
    if not isValidSkillID then
        local errMsg = (type(skillIdErrorMsgOrKey) == "string" and L(skillIdErrorMsgOrKey, "Default error for skill ID: %s", tostring(a.skillID))) or
                       string.format("Aura #%d has an invalid skillID: [%s].", i, tostring(a.skillID))
        GPlaterNS.Utils:Log("ConfigConstraint: Aura #%d, SkillID validation failed. Input was [%s]. Message: %s", 4, "config", i, tostring(a.skillID), errMsg)
        return false, errMsg
    end

    -- The rest of the property validations (types, ranges, patterns)
    if type(a.isKnown) ~= "boolean" then return false, string.format("Aura #%d: Invalid isKnown state (type: %s)", i, type(a.isKnown)) end
    if not (type(a.healthBarColor) == "string" and a.healthBarColor:match("^#?%x%x%x%x%x%x$")) then return false, string.format("Aura #%d: Invalid healthBarColor [%s]", i, tostring(a.healthBarColor)) end
    if not (type(a.nameTextColor) == "string" and a.nameTextColor:match("^#?%x%x%x%x%x%x$")) then return false, string.format("Aura #%d: Invalid nameTextColor [%s]", i, tostring(a.nameTextColor)) end
    if not (type(a.borderColor) == "string" and a.borderColor:match("^#?%x%x%x%x%x%x$")) then return false, string.format("Aura #%d: Invalid borderColor [%s]", i, tostring(a.borderColor)) end
    if not (type(a.minStacks) == "number" and a.minStacks >= 0) then return false, string.format("Aura #%d: Invalid minStacks [%s]", i, tostring(a.minStacks)) end
    local validEffects = { GPlaterNS.Constants.EFFECT_TYPE_NONE, GPlaterNS.Constants.EFFECT_TYPE_FLASH, GPlaterNS.Constants.EFFECT_TYPE_HIDE, GPlaterNS.Constants.EFFECT_TYPE_TOP, GPlaterNS.Constants.EFFECT_TYPE_LOW, GPlaterNS.Constants.EFFECT_TYPE_UNIQUE }
    if not (type(a.effect) == "string" and GPlaterNS.Utils:tContains(validEffects, a.effect)) then return false, string.format("Aura #%d: Invalid effect type [%s]", i, tostring(a.effect)) end
    if type(a.applyHealthBar) ~= "boolean" then return false, string.format("Aura #%d: Invalid applyHealthBar state (type: %s)", i, type(a.applyHealthBar)) end
    if type(a.applyNameText) ~= "boolean" then return false, string.format("Aura #%d: Invalid applyNameText state (type: %s)", i, type(a.applyNameText)) end
    if type(a.applyBorder) ~= "boolean" then return false, string.format("Aura #%d: Invalid applyBorder state (type: %s)", i, type(a.applyBorder)) end
    if not (type(a.scale) == "number" and a.scale >= 0.5 and a.scale <= 3.0) then return false, string.format("Aura #%d: Invalid scale [%s]", i, tostring(a.scale)) end
    if type(a.applyScale) ~= "boolean" then return false, string.format("Aura #%d: Invalid applyScale state (type: %s)", i, type(a.applyScale)) end
    if type(a.cancelAt30Percent) ~= "boolean" then return false, string.format("Aura #%d: Invalid cancelAt30Percent state (type: %s)", i, type(a.cancelAt30Percent)) end

    GPlaterNS.Utils:Log("ConfigConstraint: Aura #%d (AuraID: %s) passed all validations.", 3, "config", i, tostring(a.auraID))
    return true
end

ConfigConstraints = {
    ["FriendlyNameplates.settings.showClassColors"] = { type = "boolean" },
    ["FriendlyNameplates.settings.clickThrough"] = { type = "boolean" },
    ["FriendlyNameplates.settings.onlyNames"] = { type = "boolean" },
    ["FriendlyNameplates.settings.hideBuffs"] = { type = "boolean" },
    ["FriendlyNameplates.format.width"] = { type = "number", min = 50, max = 150 },
    ["FriendlyNameplates.format.height"] = { type = "number", min = -50, max = 50 },
    ["FriendlyNameplates.format.verticalScale"] = { type = "number", min = 0.5, max = 2.0 },
    ["AuraColoring.settings.pvpColoring"] = { type = "boolean" },
    ["AuraColoring.settings.resetBorderColor"] = { type = "string", validator = function(v) return v:match("^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") end },
    ["Debug.enabled"] = { type = "boolean" },
    ["Debug.chatframe"] = { type = "string" },
    ["AuraColoring.auras"] = {
        type = "table",
        validator = function(auras)
            GPlaterNS.Utils:Log("ConfigConstraint Validator for AuraColoring.auras: Validating auras. Count: %s", 2, "config", tostring(auras and #auras or "nil or not a table"))
            if type(auras) ~= "table" then
                GPlaterNS.Utils:Log("ConfigConstraint: Auras is not a table (type: %s).", 4, "config", type(auras))
                return false, "Auras must be a table"
            end
            for i, a_entry in ipairs(auras) do
                local isValidEntry, errMsg = validateAuraEntryProperties(i, a_entry)
                if not isValidEntry then
                    GPlaterNS.Utils:Log("ConfigConstraint: Aura #%d FAILED validation. Error: %s", 4, "config", i, errMsg)
                    return false, errMsg
                end
            end
            GPlaterNS.Utils:Log("ConfigConstraint Validator for AuraColoring.auras: All %s auras passed validation.", 2, "config", tostring(#auras))
            return true
        end
    }
}

function Config.getNestedTable(tbl, path, default)
    if not path or type(path) ~= "string" or path == "" then
        GPlaterNS.Utils:Log("getNestedTable: invalid path", 4, "utils")
        return default
    end
    local current = tbl
    for key in path:gmatch("[^%.]+") do
        if type(current) ~= "table" then return default end
        current = current[key]
        if not current then return default end
    end
    return current ~= nil and current or default
end

local function setNestedTable(tbl, path, value)
    local current = tbl
    local keys = {}
    for key in path:gmatch("[^%.]+") do table.insert(keys, key) end
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then current[key] = {} end
        current = current[key]
    end
    if #keys > 0 then current[keys[#keys]] = value
    else GPlaterNS.Utils:Log("setNestedTable: Error - empty path provided.", 4, "utils") end
end

function Config:GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex or specIndex == 0 then GPlaterNS.Utils:Log("GetCurrentSpecID: No active specialization or specIndex is 0.", 3, "config"); return nil end
    local specID = GetSpecializationInfo(specIndex)
    return specID
end


-- Modified tryInitialize to be a method of Config
function Config:tryInitialize()
    local config_self = self
    GPlaterNS.Utils:Log("Config:tryInitialize called.", 2, "config")

    local maxRetryTime = 10
    local startTime = GetTime()

    local function attemptInit()
        if GetTime() - startTime >= maxRetryTime then
            GPlaterNS.Utils:Log("Config:tryInitialize: Timeout waiting for specID. Running UpdateAuraIDSet with current state.", 3, "config")
            config_self:UpdateAuraIDSet()
            GPlaterNS.Utils.isDebug = config_self:Get({"Debug", "enabled"}, false)
            GPlaterNS.Utils.chatframe = config_self:Get({"Debug", "chatframe"}, "1")
            if GPlaterNS.Utils.LoadLogSettingsFromConfig then GPlaterNS.Utils:LoadLogSettingsFromConfig() end
            GPlaterNS.Utils:Log("Config:tryInitialize: set debug=%s, chatframe=%s after timeout", 2, "config", tostring(GPlaterNS.Utils.isDebug), tostring(GPlaterNS.Utils.chatframe))
            return
        end

        local specID = config_self:GetCurrentSpecID()
        if not specID then
            GPlaterNS.Utils:Log("Config:tryInitialize: Waiting for specID...", 3, "config")
            C_Timer.After(0.5, attemptInit)
            return
        end
        GPlaterNS.Utils:Log("Config:tryInitialize: Got specID: %s", 2, "config", tostring(specID))

        local aurasPath = "AuraColoring.auras." .. specID
        local aurasFromDB = Config.getNestedTable(_G.GPlaterDB.config, aurasPath, {})
        local cleanedAuras = {}
        local DAS = GPlaterNS.DefaultAuraSettings

        GPlaterNS.Utils:Log("Config:tryInitialize: Cleaning %d auras from DB for spec %s", 2, "config", #aurasFromDB, specID)
        for idx, aura_entry in ipairs(aurasFromDB) do
            GPlaterNS.Utils:Log("Config:tryInitialize: Processing DB aura #%d, Original AuraID from DB: [%s] (type: %s)", 3, "config", idx, tostring(aura_entry and aura_entry.auraID), type(aura_entry and aura_entry.auraID))
            if aura_entry and type(aura_entry) == "table" then
                local auraIdConfig_TryInit = {
                    entityName = "DB Aura ID", allowCombo = true, minPartsInCombo = 2,
                    allowZero = false, allowEmpty = false, convertSingleToNumber = true
                }
                -- Ensure aura_entry.auraID is passed as a string
                local isValidAuraID, parsedAuraIDFromFile, auraIdError = GPlaterNS.Utils:ParseAndValidateIdString(tostring(aura_entry.auraID), auraIdConfig_TryInit)

                if isValidAuraID then
                    local cleaned_aura_entry = {}
                    for k_default, v_default in pairs(DAS) do
                        cleaned_aura_entry[k_default] = aura_entry[k_default]
                        if cleaned_aura_entry[k_default] == nil then
                            cleaned_aura_entry[k_default] = v_default
                        end
                    end
                    cleaned_aura_entry.auraID = parsedAuraIDFromFile

                    local skillIdConfig_TryInit = {
                        entityName = "DB Skill ID", allowCombo = true, minPartsInCombo = 1,
                        allowZero = true, allowEmpty = true, convertSingleToNumber = false
                    }
                    -- Ensure cleaned_aura_entry.skillID is passed as a string
                    local isValidSkillID, parsedSkillIDFromFile, skillIdError = GPlaterNS.Utils:ParseAndValidateIdString(tostring(cleaned_aura_entry.skillID), skillIdConfig_TryInit)

                    if isValidSkillID then
                        cleaned_aura_entry.skillID = parsedSkillIDFromFile
                    else
                        GPlaterNS.Utils:Log("Config:tryInitialize: Correcting malformed/invalid SkillID [%s] from DB to '0'. Error: %s", 3, "config", tostring(cleaned_aura_entry.skillID), tostring(skillIdError))
                        cleaned_aura_entry.skillID = "0"
                    end
                    
                    cleaned_aura_entry.isKnown = GPlaterNS.Utils:CalculateIsKnown(cleaned_aura_entry.skillID)
                    if type(cleaned_aura_entry.isKnown) ~= "boolean" then cleaned_aura_entry.isKnown = false end

                    table.insert(cleanedAuras, cleaned_aura_entry)
                    GPlaterNS.Utils:Log("Config:tryInitialize: Added cleaned aura: ID=[%s], SkillID=[%s], isKnown=%s", 3, "config", tostring(cleaned_aura_entry.auraID), cleaned_aura_entry.skillID, tostring(cleaned_aura_entry.isKnown))
                else
                    GPlaterNS.Utils:Log("Config:tryInitialize: Skipped DB aura with invalid ID format/type. Original ID from DB: [%s]. Error: %s", 3, "config", tostring(aura_entry.auraID), tostring(auraIdError))
                end
            else
                GPlaterNS.Utils:Log("Config:tryInitialize: Skipped non-table/nil DB aura entry #%d.", 3, "config", idx)
            end
        end
        setNestedTable(_G.GPlaterDB.config, aurasPath, cleanedAuras)
        GPlaterNS.Utils:Log("Config:tryInitialize: Saved %d cleaned auras to DB for spec %s", 2, "config", #cleanedAuras, specID)

        config_self:UpdateAuraIDSet()
        GPlaterNS.Utils.isDebug = config_self:Get({"Debug", "enabled"}, false)
        GPlaterNS.Utils.chatframe = config_self:Get({"Debug", "chatframe"}, "1")
        if GPlaterNS.Utils.LoadLogSettingsFromConfig then GPlaterNS.Utils:LoadLogSettingsFromConfig() end
        GPlaterNS.Utils:Log("Config:tryInitialize: debug=%s, chatframe=%s after spec init", 2, "config", tostring(GPlaterNS.Utils.isDebug), tostring(GPlaterNS.Utils.chatframe))
    end
    
    attemptInit()
end

function Config:InitializeConfig()
    GPlaterNS.Utils:LogFunctionEntry("InitializeConfig", 1, "config") -- [Config.lua]
    _G.GPlaterDB = _G.GPlaterDB or {} -- [Config.lua]
    if type(_G.GPlaterDB.config) ~= "table" then _G.GPlaterDB.config = {}; GPlaterNS.Utils:Log("InitializeConfig: created GPlaterDB.config", 2, "config") end -- [Config.lua]
    
    -- This call will now work if Utils:DeepMerge is correctly defined in Utils.lua
    GPlaterNS.Utils:DeepMerge(GPlaterNS.DefaultConfig, _G.GPlaterDB.config) -- [Config.lua]
    
    GPlaterNS.Utils:Log("InitializeConfig: merged default config", 2, "config") -- [Config.lua]
    self:tryInitialize() -- Call as a method -- [Config.lua]
    GPlaterNS.Utils:Log("InitializeConfig: completed", 2, "config") -- [Config.lua]
end


function Config:Get(path, default)
    if not path or #path == 0 then return _G.GPlaterDB.config or default end
    local specID = self:GetCurrentSpecID()
    local v = _G.GPlaterDB.config
    for i, k in ipairs(path) do
        if k == "auras" and path[i-1] == "AuraColoring" and specID then
            return v[k] and v[k][tostring(specID)] or default
        end
        if type(v) ~= "table" then return default end
        v = v[k]
    end
    return v ~= nil and v or default
end

function Config:Set(path, value)
    GPlaterNS.Utils:LogFunctionEntry("Set", 1, "config", table.concat(path or {}, "."), "value=" .. tostring(value)) --
    if not path or #path == 0 then
        if type(value) == "table" then _G.GPlaterDB.config = value; self:NotifyConfigChange({}, value); return true end
        return false
    end
    local specID = self:GetCurrentSpecID()
    local isValid, errorMsg = self:Validate(path, value)
    if not isValid then GPlaterNS.Utils:Log("Set : validation failed for path '%s': %s", 4, "config", table.concat(path, "."), errorMsg); return false end --

    local targetPath = table.concat(path, ".")
    if path[1] == "AuraColoring" and path[2] == "auras" then
        if not specID then GPlaterNS.Utils:Log("Set : no specID for AuraColoring.auras", 4, "config"); return false end --
        targetPath = "AuraColoring.auras." .. specID
    end
    setNestedTable(_G.GPlaterDB.config, targetPath, value)
    GPlaterNS.Utils:Log("Set : successfully set path %s", 2, "config", targetPath) --
    self:NotifyConfigChange(path, value)

    if path[1] == "AuraColoring" and path[2] == "auras" and specID then
        if type(value) == "table" then -- 'value' is the new list of auras
            -- local pattern_single_positive_num = "^[1-9]%d*$" -- No longer needed here
            for i, aura_entry in ipairs(value) do -- Iterate through the list being set
                if type(aura_entry) == "table" then
                    -- Use the utility function to calculate isKnown
                    aura_entry.isKnown = GPlaterNS.Utils:CalculateIsKnown(aura_entry.skillID)
                    GPlaterNS.Utils:Log("Set  (AuraColoring.auras): updated isKnown for auraID '%s' to %s (skillID: [%s])", 3, "config", tostring(aura_entry.auraID), tostring(aura_entry.isKnown), tostring(aura_entry.skillID)) --
                end
            end
            -- The 'value' table now has updated isKnown fields and is what's stored by setNestedTable.
        end
        self:UpdateAuraIDSet()
        GPlaterNS.Utils:Log("Set : updated auraIDSet after modifying AuraColoring.auras", 2, "config") --
    end
    return true
end

function Config:Validate(path, value)
    GPlaterNS.Utils:Log("Config:Validate called for path: %s", 3, "config", table.concat(path or {}, "."))
    if not path or #path == 0 then return true end -- No path, no validation needed here
    local configKey = table.concat(path, ".")
    local constraint = ConfigConstraints[configKey]
    if not constraint then
        GPlaterNS.Utils:Log("Config:Validate: No constraint found for key '%s'. Validation passed by default.", 3, "config", configKey)
        return true
    end

    -- Type check first
    if type(value) ~= constraint.type then
        GPlaterNS.Utils:Log("Config:Validate: Type mismatch for key '%s'. Expected '%s', got '%s'.", 4, "config", configKey, constraint.type, type(value))
        return false, string.format("Expected %s, got %s for %s", constraint.type, type(value), configKey)
    end

    -- Further constraints based on type
    if constraint.type == "number" then
        if constraint.min and value < constraint.min then return false, string.format("Value %s below min %s for %s", value, constraint.min, configKey) end
        if constraint.max and value > constraint.max then return false, string.format("Value %s above max %s for %s", value, constraint.max, configKey) end
    elseif constraint.type == "string" then
        if constraint.validator then -- Custom validator for string (e.g., resetBorderColor)
            local vSuccess, vResult = GPlaterNS.Utils:SafeCall(constraint.validator, value)
            if not vSuccess or not vResult then -- Check pcall success AND validator result
                return false, (type(vResult) == "string" and vResult or "Invalid string format for " .. configKey)
            end
        end
    elseif constraint.type == "table" then
        if constraint.validator then -- Custom validator for table (e.g., AuraColoring.auras)
            local pcall_success, validator_success, validator_err_msg = GPlaterNS.Utils:SafeCall(constraint.validator, value)
            if not pcall_success then -- The validator function itself had a Lua error
                GPlaterNS.Utils:Log("Config:Validate: Validator pcall FAILED for key '%s'. Error: %s", 4, "config", configKey, tostring(validator_success))
                return false, tostring(validator_success or "Validator pcall failed for " .. configKey)
            end
            -- pcall_success is true, now check the actual return value of the validator function
            if not validator_success then
                GPlaterNS.Utils:Log("Config:Validate: Validator function returned FALSE for key '%s'. Message: %s", 4, "config", configKey, tostring(validator_err_msg))
                return false, tostring(validator_err_msg or "Table validation failed by validator function for " .. configKey)
            end
        end
    end
    GPlaterNS.Utils:Log("Config:Validate: Validation PASSED for key '%s'.", 2, "config", configKey)
    return true
end

function Config:ValidateAuraProperty(propertyName, originalValue)
    GPlaterNS.Utils:Log("ValidateAuraProperty called for: [%s], value: [%s] (type: %s)", 3, "config", propertyName, tostring(originalValue), type(originalValue))
    local constraints_map = {
        minStacks = { type = "number", min = 0 },
        scale = { type = "number", min = 0.5, max = 3.0 },
        healthBarColor = { type = "string", pattern = "^#?%x%x%x%x%x%x$" },
        nameTextColor = { type = "string", pattern = "^#?%x%x%x%x%x%x$" },
        borderColor = { type = "string", pattern = "^#?%x%x%x%x%x%x$" },
        effect = { type = "string", enum = { GPlaterNS.Constants.EFFECT_TYPE_NONE, GPlaterNS.Constants.EFFECT_TYPE_FLASH, GPlaterNS.Constants.EFFECT_TYPE_HIDE, GPlaterNS.Constants.EFFECT_TYPE_TOP, GPlaterNS.Constants.EFFECT_TYPE_LOW, GPlaterNS.Constants.EFFECT_TYPE_UNIQUE } },
        applyHealthBar = { type = "boolean" }, applyNameText = { type = "boolean" }, applyBorder = { type = "boolean" }, applyScale = { type = "boolean" },
        cancelAt30Percent = { type = "boolean" }, isKnown = { type = "boolean" }
    }

    if propertyName == "auraID" then
        local auraIdConfig_ValidateProp = {
            entityName = "Aura ID (PropValidate)", allowCombo = true, minPartsInCombo = 2,
            allowZero = false, allowEmpty = false, convertSingleToNumber = true
        }
        local isValid, _, errMsg = GPlaterNS.Utils:ParseAndValidateIdString(tostring(originalValue), auraIdConfig_ValidateProp)
        if not isValid then GPlaterNS.Utils:Log("ValidateAuraProperty: AuraID invalid. %s", 4, "config", errMsg); return false, errMsg end
        return true
    elseif propertyName == "skillID" then
        local skillIdConfig_ValidateProp = {
            entityName = "Skill ID (PropValidate)", allowCombo = true, minPartsInCombo = 1,
            allowZero = true, allowEmpty = true, convertSingleToNumber = false
        }
        local isValid, _, errMsg = GPlaterNS.Utils:ParseAndValidateIdString(tostring(originalValue), skillIdConfig_ValidateProp)
        if not isValid then GPlaterNS.Utils:Log("ValidateAuraProperty: SkillID invalid. %s", 4, "config", errMsg); return false, errMsg end
        return true
    end

    local constraint = constraints_map[propertyName]
    if not constraint then GPlaterNS.Utils:Log("ValidateAuraProperty: No constraint for %s", 3, "config", propertyName); return true end

    local value_for_type_check = originalValue
    if type(value_for_type_check) ~= constraint.type then GPlaterNS.Utils:Log("ValidateAuraProperty: Type mismatch for %s. Expected %s, got %s (value: %s)", 4, "config", propertyName, constraint.type, type(value_for_type_check), tostring(value_for_type_check)); return false, "Type mismatch" end

    if constraint.type == "number" then
        if constraint.min and value_for_type_check < constraint.min then GPlaterNS.Utils:Log("ValidateAuraProperty: Value %s for %s < min %s", 4, "config", tostring(value_for_type_check), propertyName, tostring(constraint.min)); return false, "Min fail" end
        if constraint.max and value_for_type_check > constraint.max then GPlaterNS.Utils:Log("ValidateAuraProperty: Value %s for %s > max %s", 4, "config", tostring(value_for_type_check), propertyName, tostring(constraint.max)); return false, "Max fail" end
    elseif constraint.type == "string" then
        if constraint.pattern and not tostring(value_for_type_check):match(constraint.pattern) then GPlaterNS.Utils:Log("ValidateAuraProperty: Pattern fail for %s value '%s' against '%s'", 4, "config", propertyName, tostring(value_for_type_check), constraint.pattern); return false, "Pattern fail" end
        if constraint.enum and not GPlaterNS.Utils:tContains(constraint.enum, value_for_type_check) then GPlaterNS.Utils:Log("ValidateAuraProperty: Enum fail for %s value '%s'", 4, "config", propertyName, tostring(value_for_type_check)); return false, "Enum fail" end
    end
    GPlaterNS.Utils:Log("ValidateAuraProperty: OK for %s value '%s'", 3, "config", propertyName, tostring(originalValue))
    return true
end

function Config:UpdateFriendlyNameplatesConfig()
    if InCombatLockdown() then GPlaterNS.Utils:Log(L("ERROR_COMBAT_LOCKDOWN", "Cannot modify %s during combat", "Friendly Nameplates"), 4, "ui"); return end
    local cfg = Config.getNestedTable(_G.GPlaterDB.config, "FriendlyNameplates", GPlaterNS.DefaultConfig.FriendlyNameplates)
    if not cfg or not cfg.settings or not cfg.format then GPlaterNS.Utils:Log("UpdateFriendlyNameplatesConfig: invalid config", 4, "config"); return end
    
    local getCVarFunc, setCVarFunc
    if C_CVar and C_CVar.GetValue and C_CVar.SetCVar then getCVarFunc = C_CVar.GetValue; setCVarFunc = C_CVar.SetCVar
    elseif _G.GetCVar and _G.SetCVar then getCVarFunc = _G.GetCVar; setCVarFunc = _G.SetCVar
    else GPlaterNS.Utils:Log("UpdateFriendlyNameplatesConfig: CVar functions not available!", 4, "config"); return end

    local settings = {
        { cvar = "nameplateShowFriends", value = "1" }, { cvar = "ShowClassColorInFriendlyNameplate", value = cfg.settings.showClassColors and "1" or "0" },
        { cvar = "nameplateShowOnlyNames", value = cfg.settings.onlyNames and "1" or "0" }, { cvar = "nameplateShowFriendlyBuffs", value = cfg.settings.hideBuffs and "0" or "1" },
        { cvar = "NamePlateVerticalScale", value = tostring(cfg.format.verticalScale) },
    }
    for _, s_entry in ipairs(settings) do if tostring(getCVarFunc(s_entry.cvar)) ~= s_entry.value then setCVarFunc(s_entry.cvar, s_entry.value) end end
    if C_NamePlate and C_NamePlate.SetNamePlateFriendlyClickThrough then C_NamePlate.SetNamePlateFriendlyClickThrough(cfg.settings.clickThrough) end
    if C_NamePlate and C_NamePlate.SetNamePlateFriendlySize then C_NamePlate.SetNamePlateFriendlySize(cfg.format.width, cfg.format.height) end
    GPlaterNS.Utils:Log("UpdateFriendlyNameplatesConfig: completed", 2, "config")
end

function Config:NotifyConfigChange(keys, value)
    local path = table.concat(keys, ".")
    if path:match("^FriendlyNameplates") then self:UpdateFriendlyNameplatesConfig()
    elseif path == "Debug.enabled" then GPlaterNS.Utils.isDebug = value
    elseif path == "Debug.chatframe" then GPlaterNS.Utils.chatframe = value
    elseif path == "Debug.suppressionThreshold" or path == "Debug.suppressionTimeWindow" then
        if GPlaterNS.Utils.LoadLogSettingsFromConfig then GPlaterNS.Utils:LoadLogSettingsFromConfig() end
    end
end

function Config:UpdateAuraIDSet()
    GPlaterNS.State.auraSpellIDMap = {}
    for key, configEntry in pairs(GPlaterNS.State.auraConfig) do
        if configEntry.isCombination then
            for _, reqId in ipairs(configEntry.requiredIDs) do
                GPlaterNS.State.auraSpellIDMap[reqId] = key
            end
        else
            GPlaterNS.State.auraSpellIDMap[tonumber(key)] = key
        end
    end
    GPlaterNS.Utils:LogFunctionEntry("UpdateAuraIDSet", 1, "config")
    GPlaterNS.State.auraConfig = {}
    local specID = self:GetCurrentSpecID()
    local configuredAuras = specID and Config.getNestedTable(_G.GPlaterDB.config, "AuraColoring.auras." .. specID, {}) or {}
    GPlaterNS.Utils:Log("UpdateAuraIDSet: specID=%s, loaded %d configuredAuras", 2, "config", tostring(specID), #configuredAuras)
    local pattern_single_positive_num = "^[1-9]%d*$"

    for i, aura_entry_config in ipairs(configuredAuras) do
        GPlaterNS.Utils:Log("UpdateAuraIDSet: Processing DB aura #%d, ID: [%s], SkillID: [%s], isKnown from DB: %s", 3, "config", i, tostring(aura_entry_config.auraID), tostring(aura_entry_config.skillID), tostring(aura_entry_config.isKnown))
        -- 修复错误 4：始终将 auraID 转换为字符串
        local currentAuraID = tostring(aura_entry_config.auraID)
        local isCombinationAura = false
        local requiredIndividualAuraIDs = {}
        local isValidAuraIDForProcessing = false

        if string.find(currentAuraID, ",", 1, true) then
            isCombinationAura = true
            local numParts = 0
            for idStr in currentAuraID:gmatch("([^,]+)") do
                if idStr:match(pattern_single_positive_num) then
                    table.insert(requiredIndividualAuraIDs, tonumber(idStr))
                    numParts = numParts + 1
                else
                    isValidAuraIDForProcessing = false
                    GPlaterNS.Utils:Log("UpdateAuraIDSet: Malformed part [%s] in combo auraID '%s'", 3, "config", idStr, currentAuraID)
                    break
                end
            end
            if numParts >= 2 then
                isValidAuraIDForProcessing = true
            else
                GPlaterNS.Utils:Log("UpdateAuraIDSet: Combo auraID '%s' needs >= 2 parts, got %d", 3, "config", currentAuraID, numParts)
                isValidAuraIDForProcessing = false
            end
        else
            local numID = tonumber(currentAuraID)
            if numID and numID > 0 then
                table.insert(requiredIndividualAuraIDs, numID)
                isValidAuraIDForProcessing = true
            else
                GPlaterNS.Utils:Log("UpdateAuraIDSet: Invalid auraID value: [%s]", 3, "config", currentAuraID)
            end
        end

        if isValidAuraIDForProcessing then
            local isKnownBySkill = type(aura_entry_config.isKnown) == "boolean" and aura_entry_config.isKnown or false 
            local effectConfigCopy = {}
            for k, v in pairs(aura_entry_config) do effectConfigCopy[k] = v end
            effectConfigCopy.isKnown = isKnownBySkill
            if isCombinationAura then effectConfigCopy.minStacks = 0; effectConfigCopy.cancelAt30Percent = false end

            GPlaterNS.State.auraConfig[currentAuraID] = {
                config = effectConfigCopy,
                effects = { HIDE = effectConfigCopy.effect == GPlaterNS.Constants.EFFECT_TYPE_HIDE, UNIQUE = effectConfigCopy.effect == GPlaterNS.Constants.EFFECT_TYPE_UNIQUE, COLOR = effectConfigCopy.applyHealthBar or effectConfigCopy.applyNameText or effectConfigCopy.applyBorder, SCALE = effectConfigCopy.applyScale, FLASH = effectConfigCopy.effect == GPlaterNS.Constants.EFFECT_TYPE_FLASH, TOP = effectConfigCopy.effect == GPlaterNS.Constants.EFFECT_TYPE_TOP, LOW = effectConfigCopy.effect == GPlaterNS.Constants.EFFECT_TYPE_LOW },
                isCombination = isCombinationAura, requiredIDs = requiredIndividualAuraIDs
            }
            GPlaterNS.Utils:Log("UpdateAuraIDSet: Added/Updated active config for '%s' (isCombination: %s, isKnown: %s)", 2, "config", tostring(currentAuraID), tostring(isCombinationAura), tostring(isKnownBySkill))
        end
    end
    GPlaterNS.Utils:Log("UpdateAuraIDSet: completed, GPlaterNS.State.auraConfig size=%d", 2, "config", GPlaterNS.Utils:TableSize(GPlaterNS.State.auraConfig))
end

function Config:RecheckAuraKnowledgeAndUpdateSet()
    GPlaterNS.Utils:LogFunctionEntry("RecheckAuraKnowledgeAndUpdateSet", 1, "config") --
    local specID = self:GetCurrentSpecID()
    if not specID then GPlaterNS.Utils:Log("RecheckAuraKnowledgeAndUpdateSet : no specID", 4, "config"); return end --
    local aurasPath = "AuraColoring.auras." .. specID
    local aurasInDB = Config.getNestedTable(_G.GPlaterDB.config, aurasPath, {}) --
    if type(aurasInDB) ~= "table" then GPlaterNS.Utils:Log("RecheckAuraKnowledgeAndUpdateSet : aurasInDB is not a table!", 4, "config"); return end --
    
    local knowledgeChangedInDB = false
    -- local pattern_single_positive_num = "^[1-9]%d*$" -- No longer needed here

    GPlaterNS.Utils:Log("RecheckAuraKnowledgeAndUpdateSet : Checking %d auras in DB for spec %s", 2, "config", #aurasInDB, specID) --
    for i, aura_entry in ipairs(aurasInDB) do
        if type(aura_entry) == "table" then
            local oldIsKnown = aura_entry.isKnown
            
            -- Use the utility function to calculate currentIsKnown
            local currentIsKnown = GPlaterNS.Utils:CalculateIsKnown(aura_entry.skillID)

            if oldIsKnown ~= currentIsKnown then
                aura_entry.isKnown = currentIsKnown
                knowledgeChangedInDB = true
                GPlaterNS.Utils:Log("RecheckAuraKnowledgeAndUpdateSet : isKnown in DB changed for auraID [%s] to %s (skillID: %s)", 2, "config", tostring(aura_entry.auraID), tostring(currentIsKnown), tostring(aura_entry.skillID)) --
            end
        end
    end

    if knowledgeChangedInDB then
        GPlaterNS.Utils:Log("RecheckAuraKnowledgeAndUpdateSet : Knowledge changed in DB, saving.", 2, "config") --
        setNestedTable(_G.GPlaterDB.config, aurasPath, aurasInDB) --
    end
    
    self:UpdateAuraIDSet() -- Always update GPlaterNS.State.auraConfig from GPlaterDB

    if GPlaterNS.UI and GPlaterNS.UI.panelFrame and GPlaterNS.UI.panelFrame.content and GPlaterNS.UI.panelFrame:IsShown() then
        GPlaterNS.UI.UpdateAuraTable(GPlaterNS.UI.panelFrame.content)
        GPlaterNS.Utils:Log("RecheckAuraKnowledgeAndUpdateSet : updated UI table as panel is shown.", 2, "config") --
    end
    GPlaterNS.Utils:Log("RecheckAuraKnowledgeAndUpdateSet : completed. DB knowledge changed: %s", 2, "config", tostring(knowledgeChangedInDB)) --
end

function Config:SafeConfigChange(frame, label, cvar, path, value, cvarInvert, callback)
    GPlaterNS.Utils:LogFunctionEntry("SafeConfigChange", 1, "config", table.concat(path, "."), "value=" .. tostring(value))
    local success = self:Set(path, value)
    if success then
        if cvar then C_CVar.SetCVar(cvar, value and not cvarInvert and "1" or "0"); GPlaterNS.Utils:Log("SafeConfigChange: set cvar %s=%s", 2, "config", tostring(cvar), value and not cvarInvert and "1" or "0") end
        if callback then GPlaterNS.Utils:SafeCall(callback, frame, value) end
    else
        GPlaterNS.Utils:Log("SafeConfigChange: Set failed for [%s]. Reverting UI.", 4, "config", label or table.concat(path, "."))
        local oldValueToRevert = self:Get(path) -- Get the value that's actually in the config (might be default)
        if frame and frame.IsObjectType then
            if frame:IsObjectType("CheckButton") and frame.SetChecked then frame:SetChecked(oldValueToRevert)
            elseif frame:IsObjectType("Slider") and frame.SetValue and frame.valueText then if type(oldValueToRevert) ~= "nil" then frame:SetValue(oldValueToRevert); frame.valueText:SetText(tostring(oldValueToRevert)) end
            elseif frame:IsObjectType("EditBox") and frame.SetText then if type(oldValueToRevert) ~= "nil" then frame:SetText(tostring(oldValueToRevert)) end
            end
        end
    end
    GPlaterNS.Utils:Log("SafeConfigChange for [%s] result: %s", 2, "config", label or table.concat(path, "."), tostring(success))
    return success
end