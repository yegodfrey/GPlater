local _G = _G
local addonName, GPlaterNS = ...

GPlaterNS.Localization = {} -- 初始化命名空间下的表

local defaultTranslations = {
    CONFIG_TITLE = "GPlater Configuration",
    ADD = "Add",
    NO_AURA_DATA = "No Aura Data",
    DEBUG_CHAT_WINDOW = "Chat Window",
    TAB_AURA_COLORING = "Nameplate Settings",
    FRIENDLY_CLASS_COLORS = "Show Class Colors",
    FORMAT_SETTINGS = "Format Settings",
    FRIENDLY_WIDTH = "Width",
    FRIENDLY_HEIGHT = "Height",
    FRIENDLY_V_SCALE = "Vertical Scale",
    HELP_FRIENDLY_CLASS_COLORS = "Enable class colors for friendly nameplates.",
    HELP_FRIENDLY_WIDTH = "Set the width of friendly nameplates (50-150).",
    HELP_FRIENDLY_HEIGHT = "Set the height of friendly nameplates (-50 to 50).",
    HELP_FRIENDLY_V_SCALE = "Set the vertical scale of friendly nameplates (0.5-2.0).",
    CLICK_THROUGH = "Click Through",
    ONLY_NAMES = "Only Names",
    HIDE_BUFFS = "Hide Buffs",
    HELP_CLICK_THROUGH = "When enabled, friendly nameplates allow clicks to pass through.",
    HELP_ONLY_NAMES = "When enabled, friendly nameplates show only names.",
    HELP_HIDE_BUFFS = "When enabled, hide buffs on friendly nameplates.",
    ENABLE_PVP_AURA = "Enable PvP Aura Coloring",
    AURA_LIST = "Aura List",
    AURA_ID = "Aura ID",
    AURA_MIN_STACKS = "Stacks",
    SKILL_ID = "Skill ID",
    AURA_PLATE = "Health Bar",
    AURA_TEXT = "Text",
    AURA_BORDER = "Border",
    AURA_SCALE = "Scale%",
    AURA_EFFECT = "Effect",
    AURA_EFFECT_NONE = "None",
    AURA_EFFECT_FLASH = "Flash",
    AURA_EFFECT_HIDE = "Hide",
    AURA_EFFECT_TOP = "Top",
    AURA_EFFECT_LOW = "Low",
    AURA_EFFECT_UNIQUE = "Only",
    AURA_CANCEL_30_PERCENT = "Cancel at 30% Duration",
    HELP_ENABLE_PVP_AURA = "When enabled, apply coloring effects to PvP auras.",
    HELP_AURA_ID = "Enter the aura ID.",
    HELP_SKILL_ID = "Enter the skill ID.",
    HELP_AURA_MIN_STACKS = "Set the minimum stacks for the aura to take effect (0 for no restriction).",
    HELP_AURA_PLATE_COLOR = "Set the health bar color triggered by the aura (left-click to choose color, right-click to toggle enable/disable).",
    HELP_AURA_TEXT_COLOR = "Set the name text color triggered by the aura (left-click to choose color, right-click to toggle enable/disable).",
    HELP_AURA_BORDER_COLOR = "Set the border color triggered by the aura (left-click to choose color, right-click to toggle enable/disable).",
    HELP_AURA_SCALE = "Set the nameplate scale triggered by the aura (50%-300%).",
    HELP_AURA_EFFECT = "Select the visual effect triggered by the aura (None, Flash, Hide, Top, Low, Only).",
    HELP_AURA_EFFECT_UNIQUE = "Selecting the Only effect will show only this aura's nameplate, hiding all other nameplates.",
    HELP_AURA_CANCEL_30_PERCENT = "When enabled, cancel aura effects when the aura's duration falls below 30%.",
    ERROR_AURA_INVALID_ID = "Invalid aura ID: %s",
    ERROR_AURA_EXISTS = "Aura ID %s already exists",
    ERROR_CONFIG_SET_FAILED = "Failed to set configuration: %s",
    ERROR_COMBAT_LOCKDOWN = "Cannot modify %s during combat",
    ERROR_UI_NOT_INITIALIZED = "Failed to open configuration panel, UI is not initialized.",
    HELP_RESET_BORDER_COLOR = "Enter the reset border color (format: 0e0e0e, 6-digit hexadecimal).",
    ERROR_INVALID_RESET_BORDER_COLOR = "Invalid reset border color format: %s, expected 6-digit hexadecimal (e.g., 0e0e0e)",
    DEBUG_LABEL = "Debug",
    DEBUG_AURAS_LABEL = "Auras",
    DEBUG_NAMEPLATES_LABEL = "Nameplates",
    DEBUG_EVENTS_LABEL = "Events",
    DEBUG_UI_LABEL = "UI",
    DEBUG_UTILS_LABEL = "Utils",
    DEBUG_AURAS_TOOLTIP = "Show logs related to auras.",
    DEBUG_NAMEPLATES_TOOLTIP = "Show logs related to nameplates.",
    DEBUG_EVENTS_TOOLTIP = "Show logs related to events.",
    DEBUG_UI_TOOLTIP = "Show logs related to UI.",
    DEBUG_UTILS_TOOLTIP = "Show logs related to utility functions.",
    DEBUG_THRESHOLD_LABEL = "Suppression Threshold",
    DEBUG_THRESHOLD_TOOLTIP = "Set how many times a log must repeat before being suppressed.",
    DEBUG_TIMEWINDOW_LABEL = "Time Window (seconds)",
    DEBUG_TIMEWINDOW_TOOLTIP = "Set the time window for detecting repeated logs.",
    DEBUG_ENABLE_TOOLTIP = "Enable debug logging.",
    -- Added error keys for ParseAndValidateIdString
    ERROR_AURA_ID_EMPTY = "Aura ID cannot be empty",
    ERROR_AURA_ID_INVALID_STRUCTURE = "Invalid aura ID structure (e.g., commas misplaced)",
    ERROR_AURA_ID_COMBO_NOT_ALLOWED = "Combination aura IDs not allowed",
    ERROR_AURA_ID_COMBO_TOO_FEW_PARTS = "Combination aura ID requires at least two parts",
    ERROR_AURA_ID_COMBO_INVALID_PART = "Invalid part in combination aura ID",
    ERROR_AURA_ID_SINGLE_INVALID_FORMAT = "Invalid single aura ID format",
    ERROR_SKILL_ID_EMPTY = "Skill ID cannot be empty",
    ERROR_SKILL_ID_INVALID_STRUCTURE = "Invalid skill ID structure",
    ERROR_SKILL_ID_COMBO_NOT_ALLOWED = "Combination skill IDs not allowed",
    ERROR_SKILL_ID_COMBO_TOO_FEW_PARTS = "Combination skill ID requires at least one part",
    ERROR_SKILL_ID_COMBO_INVALID_PART = "Invalid part in combination skill ID",
    ERROR_SKILL_ID_SINGLE_INVALID_FORMAT = "Invalid single skill ID format"
}

local localeTranslations = {
    zhCN = {
        CONFIG_TITLE = "GPlater 配置",
        ADD = "确定",
        NO_AURA_DATA = "无光环数据",
        DEBUG_CHAT_WINDOW = "聊天窗口",
        TAB_AURA_COLORING = "姓名板设置",
        FRIENDLY_CLASS_COLORS = "职业颜色",
        FORMAT_SETTINGS = "格式设置",
        FRIENDLY_WIDTH = "宽度",
        FRIENDLY_HEIGHT = "高度",
        FRIENDLY_V_SCALE = "垂直缩放",
        HELP_FRIENDLY_CLASS_COLORS = "为友方姓名板启用职业颜色。",
        HELP_FRIENDLY_WIDTH = "设置友方姓名板的宽度（50-150）。",
        HELP_FRIENDLY_HEIGHT = "设置友方姓名板的高度（-50至50）。",
        HELP_FRIENDLY_V_SCALE = "设置友方姓名板的垂直缩放比例（0.5-2.0）。",
        CLICK_THROUGH = "点击穿透",
        ONLY_NAMES = "仅名字",
        HIDE_BUFFS = "隐藏增益",
        HELP_CLICK_THROUGH = "启用后，友方姓名板将允许点击穿透。",
        HELP_ONLY_NAMES = "启用后，友方姓名板仅显示名称。",
        HELP_HIDE_BUFFS = "启用后，隐藏友方姓名板上的增益效果。",
        ENABLE_PVP_AURA = "启用 PvP 光环染色",
        AURA_LIST = "光环列表",
        AURA_ID = "光环 ID",
        AURA_MIN_STACKS = "层数",
        SKILL_ID = "技能 ID",
        AURA_PLATE = "血条",
        AURA_TEXT = "文字",
        AURA_BORDER = "边框",
        AURA_SCALE = "缩放%",
        AURA_EFFECT = "效果",
        AURA_EFFECT_NONE = "无",
        AURA_EFFECT_FLASH = "闪烁",
        AURA_EFFECT_HIDE = "隐藏",
        AURA_EFFECT_TOP = "置顶",
        AURA_EFFECT_LOW = "降层",
        AURA_EFFECT_UNIQUE = "唯一",
        AURA_CANCEL_30_PERCENT = "30%取消",
        HELP_ENABLE_PVP_AURA = "启用后，对 PvP 光环应用染色效果。",
        HELP_AURA_ID = "输入光环的 ID。",
        HELP_SKILL_ID = "输入技能的 ID。",
        HELP_AURA_MIN_STACKS = "设置光环生效的最小层数 (0 表示无限制)。",
        HELP_AURA_PLATE_COLOR = "设置光环触发的血条颜色 (左键选色，右键切换启用/禁用)。",
        HELP_AURA_TEXT_COLOR = "设置光环触发的名称文字颜色 (左键选色，右键切换启用/禁用)。",
        HELP_AURA_BORDER_COLOR = "设置光环触发的边框颜色 (左键选色，右键切换启用/禁用)。",
        HELP_AURA_SCALE = "设置光环触发的姓名板缩放比例 (50%-300%)。",
        HELP_AURA_EFFECT = "选择光环触发的视觉效果 (无、闪烁、隐藏、置顶、降层、唯一)。",
        HELP_AURA_EFFECT_UNIQUE = "选择唯一效果将仅显示此光环的姓名板，隐藏其他所有姓名板。",
        HELP_AURA_CANCEL_30_PERCENT = "启用后，当光环剩余时间低于 30% 时取消光环效果。",
        ERROR_AURA_INVALID_ID = "无效的光环 ID：%s",
        ERROR_AURA_EXISTS = "光环 ID %s 已存在",
        ERROR_CONFIG_SET_FAILED = "无法设置配置：%s",
        ERROR_COMBAT_LOCKDOWN = "无法在战斗中修改 %s",
        ERROR_UI_NOT_INITIALIZED = "无法打开配置面板，UI 未初始化",
        HELP_RESET_BORDER_COLOR = "输入边框重置颜色（可从Plater复制，格式：0e0e0e，6位十六进制）。",
        ERROR_INVALID_RESET_BORDER_COLOR = "无效的边框重置颜色格式：%s，应为6位十六进制（如0e0e0e）",
        DEBUG_LABEL = "调试",
        DEBUG_AURAS_LABEL = "光环",
        DEBUG_NAMEPLATES_LABEL = "姓名板",
        DEBUG_EVENTS_LABEL = "事件",
        DEBUG_UI_LABEL = "界面",
        DEBUG_UTILS_LABEL = "工具",
        DEBUG_AURAS_TOOLTIP = "显示与光环相关的日志。",
        DEBUG_NAMEPLATES_TOOLTIP = "显示与姓名板相关的日志。",
        DEBUG_EVENTS_TOOLTIP = "显示与事件处理相关的日志。",
        DEBUG_UI_TOOLTIP = "显示与用户界面相关的日志。",
        DEBUG_UTILS_TOOLTIP = "显示与工具函数相关的日志。",
        DEBUG_THRESHOLD_LABEL = "重复阈值",
        DEBUG_THRESHOLD_TOOLTIP = "设置日志重复多少次后开始抑制。",
        DEBUG_TIMEWINDOW_LABEL = "时间窗口（秒）",
        DEBUG_TIMEWINDOW_TOOLTIP = "设置检测重复日志的时间窗口。",
        DEBUG_ENABLE_TOOLTIP = "启用调试日志。",
        -- Added error keys for ParseAndValidateIdString (zhCN)
        ERROR_AURA_ID_EMPTY = "光环 ID 不能为空",
        ERROR_AURA_ID_INVALID_STRUCTURE = "无效的光环 ID 结构（例如，逗号位置错误）",
        ERROR_AURA_ID_COMBO_NOT_ALLOWED = "不支持组合光环 ID",
        ERROR_AURA_ID_COMBO_TOO_FEW_PARTS = "组合光环 ID 至少需要两个部分",
        ERROR_AURA_ID_COMBO_INVALID_PART = "组合光环 ID 中包含无效部分",
        ERROR_AURA_ID_SINGLE_INVALID_FORMAT = "单个光环 ID 格式无效",
        ERROR_SKILL_ID_EMPTY = "技能 ID 不能为空",
        ERROR_SKILL_ID_INVALID_STRUCTURE = "无效的技能 ID 结构",
        ERROR_SKILL_ID_COMBO_NOT_ALLOWED = "不支持组合技能 ID",
        ERROR_SKILL_ID_COMBO_TOO_FEW_PARTS = "组合技能 ID 至少需要一个部分",
        ERROR_SKILL_ID_COMBO_INVALID_PART = "组合技能 ID 中包含无效部分",
        ERROR_SKILL_ID_SINGLE_INVALID_FORMAT = "单个技能 ID 格式无效"
    }
}

-- Function to initialize the GPlaterNS.Localization table
local function InitializeLocalizationTable()
    local currentLocale = GetLocale()
    local activeTranslations = localeTranslations[currentLocale] or defaultTranslations

    for key, value in pairs(defaultTranslations) do
        GPlaterNS.Localization[key] = activeTranslations[key] or value
    end
end

-- Call initialization once when the script is loaded
if GPlaterNS.Utils and GPlaterNS.Utils.Log then
    InitializeLocalizationTable()
else
    local C_Timer = _G.C_Timer
    if C_Timer and C_Timer.After then
        C_Timer.After(0.01, function()
            if GPlaterNS.Utils and GPlaterNS.Utils.Log then
                InitializeLocalizationTable()
            else
                local tempTranslations = localeTranslations[GetLocale()] or defaultTranslations
                for k, v_default in pairs(defaultTranslations) do
                    GPlaterNS.Localization[k] = tempTranslations[k] or v_default
                end
            end
        end)
    else
        local tempTranslations = localeTranslations[GetLocale()] or defaultTranslations
        for k, v_default in pairs(defaultTranslations) do
            GPlaterNS.Localization[k] = tempTranslations[k] or v_default
        end
    end
end

function GPlaterNS.L(key, defaultText, ...)
    local value = GPlaterNS.Localization[key]
    if not value then
        if GPlaterNS.Utils and GPlaterNS.Utils.isDebug and GPlaterNS.Config and GPlaterNS.Config:Get({"Debug", "logCategories", "utils"}, false) then
            GPlaterNS.Utils:Log("L: Key '%s' not found in localization. Using default or key.", 3, "utils", tostring(key))
        end
        value = defaultText or key
    end
    local argCount = select("#", ...)
    if argCount > 0 then
        local success, formattedValue = pcall(string.format, tostring(value), ...)
        if success then
            return formattedValue
        else
            if GPlaterNS.Utils and GPlaterNS.Utils.isDebug and GPlaterNS.Config and GPlaterNS.Config:Get({"Debug", "logCategories", "utils"}, false) then
                GPlaterNS.Utils:Log("L: Error formatting key '%s' (value: '%s'). Error: %s", 4, "utils", tostring(key), tostring(value), tostring(formattedValue))
            end
            return value
        end
    end
    return value
end