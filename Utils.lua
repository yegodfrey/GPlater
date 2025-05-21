local _G = _G
local addonName, GPlaterNS = ...

local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local Utils = {}
local pattern_single_positive_num = "^[1-9]%d*$"
GPlaterNS.Utils = Utils
Utils.isDebug = false
Utils.chatframe = "1"

function Utils:ParseAndValidateIdString(idString, idTypeConfig)
    local originalIdForLog = tostring(idString)
    local cleanedStr = type(idString) == "string" and idString or ""
    cleanedStr = cleanedStr:gsub("%s+", "")
    cleanedStr = cleanedStr:gsub("，", ",")
    cleanedStr = cleanedStr:gsub("[^%d,]+", "") -- 只保留数字和逗号

    -- 结构预检查
    if cleanedStr == "" then
        if idTypeConfig.allowEmpty then return true, "", nil end
        return false, nil, "ERROR_ID_EMPTY" -- 需要在 Localization.lua 中定义
    end
    if cleanedStr == "," or cleanedStr:match("^,") or cleanedStr:match(",$") or cleanedStr:match(",,") then
        return false, nil, "ERROR_ID_INVALID_STRUCTURE" -- 需要在 Localization.lua 中定义
    end

    local hasComma = string.find(cleanedStr, ",", 1, true)
    local resultValue

    if hasComma then
        if not idTypeConfig.allowCombo then
            return false, nil, "ERROR_ID_COMBO_NOT_ALLOWED" -- 需要在 Localization.lua 中定义
        end
        local parts = {}
        local partCount = 0
        for part in cleanedStr:gmatch("([^,]+)") do
            table.insert(parts, part)
            partCount = partCount + 1
        end

        if partCount < idTypeConfig.minPartsInCombo then
            return false, nil, "ERROR_ID_COMBO_TOO_FEW_PARTS" -- 需要在 Localization.lua 中定义
        end

        local allPartsValid = true
        for _, part_str in ipairs(parts) do
            if not part_str:match(pattern_single_positive_num) then
                allPartsValid = false
                break
            end
        end

        if not allPartsValid then
            return false, nil, "ERROR_ID_COMBO_INVALID_PART" -- 需要在 Localization.lua 中定义
        end
        resultValue = cleanedStr -- 组合ID通常以字符串形式存储
    else -- 单个ID
        if idTypeConfig.allowZero and cleanedStr == "0" then
            resultValue = idTypeConfig.convertSingleToNumber and 0 or "0"
        elseif cleanedStr:match(pattern_single_positive_num) then
            resultValue = idTypeConfig.convertSingleToNumber and tonumber(cleanedStr) or cleanedStr
        else
            return false, nil, "ERROR_ID_SINGLE_INVALID_FORMAT" -- 需要在 Localization.lua 中定义
        end
    end

    GPlaterNS.Utils:Log("ParseAndValidateIdString for %s: input='%s', cleaned='%s', result='%s' (type: %s). Valid.", 3, "utils",
        idTypeConfig.entityName, originalIdForLog, cleanedStr, tostring(resultValue), type(resultValue))
    return true, resultValue, nil
end

function Utils:CalculateIsKnown(skillIdValue) -- skillIdValue 可以是数字0, 或字符串 "0", "123", "123,456"
    local skillIdString = tostring(skillIdValue or "0") -- 确保是字符串，处理nil情况

    if skillIdString == "" or skillIdString == "0" then
        return true -- 空字符串或"0"表示无需特定技能，视为已知
    end

    local pattern_single_positive_num = "^[1-9]%d*$"

    if string.find(skillIdString, ",", 1, true) then -- 组合技能ID
        local allKnown = true
        local hasAtLeastOneValidPart = false
        for partStr in skillIdString:gmatch("([^,]+)") do
            if partStr:match(pattern_single_positive_num) then
                hasAtLeastOneValidPart = true
                if not IsSpellKnown(tonumber(partStr), false) then
                    allKnown = false
                    break -- 一旦有一个未知，整个组合就未知
                end
            else
                -- 如果组合中的某个部分格式不正确，则整个组合视为未知
                GPlaterNS.Utils:Log("CalculateIsKnown: Malformed part '%s' in combo skill ID '%s'. Considered unknown.", 3, "utils", partStr, skillIdString)
                return false
            end
        end
        -- 对于组合ID，必须所有部分都有效且已知，并且至少有一个有效部分
        return allKnown and hasAtLeastOneValidPart
    elseif skillIdString:match(pattern_single_positive_num) then -- 单个技能ID
        return IsSpellKnown(tonumber(skillIdString), false)
    end

    -- 如果 skillIdString 不是 "0", "", 也不是有效的单个正整数或有效的组合格式
    GPlaterNS.Utils:Log("CalculateIsKnown: Malformed single skill ID '%s'. Considered unknown.", 3, "utils", skillIdString)
    return false
end


function Utils:DeepMerge(source, target) -- Changed to be a method of Utils
    if type(source) ~= "table" or type(target) ~= "table" then return end
    for key, value in pairs(source) do
        if type(value) == "table" and value ~= nil then
            if type(target[key]) ~= "table" or target[key] == nil then target[key] = {} end
            self:DeepMerge(value, target[key]) -- Recursive call using self
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

local LOG_PREFIX = "[GPlater] "
local LOG_HISTORY_MAX = 100 -- Maximum number of log entries to store
local LOG_REPEAT_THRESHOLD = 3 -- Repeat threshold for suppression
local LOG_REPEAT_TIME_WINDOW = 5 -- Time window for repeat detection (seconds)

-- Circular buffer for log history
local logBuffer = {} -- Array to store log entries: {key, count, time}
local logKeyToIndex = {} -- Maps logKey (level_message) to buffer index
local nextIndex = 1 -- Next index to write in buffer (1-based)

-- Initialize buffer
for i = 1, LOG_HISTORY_MAX do
    logBuffer[i] = {key = nil, count = 0, time = 0}
end

-- Check if a log message is repeated within the time window
local function isRepeatedLog(message, level)
    local currentTime = GetTime()
    local logKey = level .. "_" .. message

    local bufferIndex = logKeyToIndex[logKey]
    if bufferIndex then
        local entry = logBuffer[bufferIndex]
        if entry.key == logKey and (currentTime - entry.time) <= LOG_REPEAT_TIME_WINDOW then
            entry.count = entry.count + 1
            entry.time = currentTime
            if entry.count >= LOG_REPEAT_THRESHOLD then
                return true, (entry.count == LOG_REPEAT_THRESHOLD) and LOG_REPEAT_THRESHOLD or 0
            end
            return false, 0
        end
        logKeyToIndex[logKey] = nil
    end

    local oldKey = logBuffer[nextIndex].key
    if oldKey then
        logKeyToIndex[oldKey] = nil
    end

    logBuffer[nextIndex] = {key = logKey, count = 1, time = currentTime}
    logKeyToIndex[logKey] = nextIndex

    nextIndex = nextIndex + 1
    if nextIndex > LOG_HISTORY_MAX then
        nextIndex = 1
    end

    return false, 0
end

function Utils:Log(message, level, category, ...)
    if not self.isDebug or not GPlaterNS.State.debugLevel or level > GPlaterNS.State.debugLevel then return end

    -- Check log category
    local config = GPlaterNS.Config
    if category and config and config.Get then
        local categoryEnabled = config:Get({"Debug", "logCategories", category}, true)
        if not categoryEnabled then return end
    end

    local chatFrameName = "ChatFrame" .. (self.chatframe or "1")
    local chat = _G[chatFrameName] or DEFAULT_CHAT_FRAME

    -- Format message
    local formattedMessage = message
    if select("#", ...) > 0 then
        local success, result = pcall(string.format, message, ...)
        formattedMessage = success and result or string.format("%s (format error: %s)", message, tostring(result))
    end

    -- Check for repeated log
    local isRepeated, repeatCount = isRepeatedLog(formattedMessage, level)
    if isRepeated then
        if repeatCount > 0 then
            chat:AddMessage(LOG_PREFIX .. formattedMessage .. " (repeated " .. repeatCount .. " times, further logs suppressed)")
        end
        return
    end

    -- Add level prefix
    local levelPrefix = ""
    if level == 1 then
        levelPrefix = "[Entry] "
    elseif level == 2 then
        levelPrefix = "[Info] "
    elseif level == 3 then
        levelPrefix = "[Detail] "
    elseif level == 4 then
        levelPrefix = "[Error] "
    end

    -- Add category prefix
    local categoryPrefix = ""
    if category then
        categoryPrefix = "[" .. category .. "] "
    end

    chat:AddMessage(LOG_PREFIX .. levelPrefix .. categoryPrefix .. formattedMessage)
end

function Utils:LogFunctionEntry(functionName, level, ...)
    local args = {...}
    local formattedArgs = {}
    for i, arg in ipairs(args) do
        formattedArgs[i] = tostring(arg)
    end
    self:Log("%s: %s", level, "utils", functionName, table.concat(formattedArgs, ", "))
end

-- Clear log history
function Utils:ClearLogHistory()
    for i = 1, LOG_HISTORY_MAX do
        local oldKey = logBuffer[i].key
        if oldKey then
            logKeyToIndex[oldKey] = nil
        end
        logBuffer[i] = {key = nil, count = 0, time = 0}
    end
    nextIndex = 1
    self:Log("Log history cleared", 2, "utils")
end

-- Set log suppression parameters
function Utils:SetLogSuppressionParams(threshold, timeWindow)
    if threshold and threshold > 0 then
        LOG_REPEAT_THRESHOLD = threshold
    end

    if timeWindow and timeWindow > 0 then
        LOG_REPEAT_TIME_WINDOW = timeWindow
    end

    self:Log("Log suppression parameters updated: threshold=%d, time window=%d seconds", 2, "utils", LOG_REPEAT_THRESHOLD, LOG_REPEAT_TIME_WINDOW)
end

-- Load log settings from config
function Utils:LoadLogSettingsFromConfig()
    local config = GPlaterNS.Config
    if not config or not config.Get then return end

    -- Load suppression parameters
    local threshold = config:Get({"Debug", "suppressionThreshold"}, 3)
    local timeWindow = config:Get({"Debug", "suppressionTimeWindow"}, 5)
    self:SetLogSuppressionParams(threshold, timeWindow)

    self:Log("Loaded log settings from config", 2, "utils")
end

local colorCache = {}
function Utils:HexToRGB(hex)
    if not hex then 
        GPlaterNS.Utils:Log("HexToRGB: nil hex", 4)
        return 1, 1, 1 
    end
    if colorCache[hex] then 
        return unpack(colorCache[hex]) 
    end
    if type(hex) ~= "string" or not hex:match("^#?%x%x%x%x%x%x$") then
        GPlaterNS.Utils:Log("HexToRGB: invalid hex format %s", 4, tostring(hex))
        return 1, 1, 1
    end
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    colorCache[hex] = {r, g, b}
    return r, g, b
end

function Utils:SafeCall(func, ...)
    if not func then
        GPlaterNS.Utils:Log("SafeCall: nil function", 4)
        return false, "nil function"
    end
    local success, res1, res2, res3, res4 = xpcall(func, function(err)
        GPlaterNS.Utils:Log("SafeCall error: %s", 4, tostring(err))
        return err
    end, ...)
    return success, res1, res2, res3, res4
end

function Utils:tContains(tbl, element)
    if type(tbl) ~= "table" then 
        GPlaterNS.Utils:Log("tContains: tbl not a table", 4)
        return false 
    end
    for _, value in pairs(tbl) do
        if value == element then 
            return true 
        end
    end
    return false
end

function Utils:TableSize(t)
    if type(t) ~= "table" then 
        GPlaterNS.Utils:Log("TableSize: not a table", 4)
        return 0 
    end
    local count = 0
    for _ in pairs(t) do 
        count = count + 1 
    end
    return count
end

function Utils:MergeTables(defaults, overrides)
    local result = {}
    for k, v in pairs(defaults) do
        result[k] = v
    end
    for k, v in pairs(overrides) do
        result[k] = v
    end
    return result
end