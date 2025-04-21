-- Skills.lua: Provides utility functions for class and spec detection, and maps for interrupts and harmful auras

-- Get the player's current specialization
function GetPlayerSpec()
    local specIndex = GetSpecialization()
    if not specIndex then
        return nil
    end
    local _, specName = GetSpecializationInfo(specIndex)
    return specName
end

-- Check if a skill is learned by the player
function IsSkillLearned(spellID)
    local spellName = C_Spell.GetSpellName(spellID)
    return spellName ~= nil
end

-- Utility function to check if a value is in a table
function tContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Map of interrupts (including interrupts, stuns, and knockbacks) to class and specialization for WoW 11.1
InterruptClassMap = {
    -- Warrior / 战士
    [6552] = { class = "WARRIOR", spec = nil }, -- Pummel / 拳击
    [107570] = { class = "WARRIOR", spec = nil }, -- Storm Bolt / 风暴之锤 (Talent / 天赋)
    [46968] = { class = "WARRIOR", spec = nil }, -- Shockwave / 震荡波
    [100] = { class = "WARRIOR", spec = nil }, -- Charge / 冲锋 (can stun with talents)
    [5246] = { class = "WARRIOR", spec = nil }, -- Intimidating Shout / 威吓怒吼

    -- Mage / 法师
    [2139] = { class = "MAGE", spec = nil }, -- Counterspell / 法术反制
    [31661] = { class = "MAGE", spec = nil }, -- Dragon's Breath / 龙息术
    [82691] = { class = "MAGE", spec = "FROST" }, -- Ring of Frost / 冰霜之环

    -- Rogue / 潜行者
    [1766] = { class = "ROGUE", spec = nil }, -- Kick / 脚踢
    [2094] = { class = "ROGUE", spec = nil }, -- Blind / 致盲
    [408] = { class = "ROGUE", spec = nil }, -- Kidney Shot / 肾击
    [1833] = { class = "ROGUE", spec = nil }, -- Cheap Shot / 偷袭
    [1776] = { class = "ROGUE", spec = nil }, -- Gouge / 凿击

    -- Priest / 牧师
    [15487] = { class = "PRIEST", spec = "SHADOW" }, -- Silence / 沉默
    [8122] = { class = "PRIEST", spec = nil }, -- Psychic Scream / 心灵尖啸
    [64044] = { class = "PRIEST", spec = "DISCIPLINE" }, -- Psychic Horror / 心灵恐惧 (Talent / 天赋)

    -- Death Knight / 死亡骑士
    [47528] = { class = "DEATHKNIGHT", spec = nil }, -- Mind Freeze / 心灵冰冻
    [49576] = { class = "DEATHKNIGHT", spec = nil }, -- Death Grip / 死亡之握
    [47476] = { class = "DEATHKNIGHT", spec = "FROST" }, -- Strangulate / 绞袭
    [91800] = { class = "DEATHKNIGHT", spec = "UNHOLY" }, -- Gnaw / 啃噬 (Ghoul stun)

    -- Shaman / 萨满
    [57994] = { class = "SHAMAN", spec = nil }, -- Wind Shear / 风剪
    [51514] = { class = "SHAMAN", spec = nil }, -- Hex / 妖术
    [305485] = { class = "SHAMAN", spec = nil }, -- Lightning Lasso / 闪电套索 (PvP Talent / PvP天赋)
    [51490] = { class = "SHAMAN", spec = nil }, -- Thunderstorm / 雷霆风暴

    -- Druid / 德鲁伊
    [106839] = { class = "DRUID", spec = { "FERAL", "GUARDIAN" } }, -- Skull Bash / 迎头痛击
    [78675] = { class = "DRUID", spec = "BALANCE" }, -- Solar Beam / 太阳光束
    [99] = { class = "DRUID", spec = nil }, -- Incapacitating Roar / 夺魂咆哮
    [5211] = { class = "DRUID", spec = nil }, -- Mighty Bash / 蛮力猛击
    [61391] = { class = "DRUID", spec = "BALANCE" }, -- Typhoon / 台风

    -- Paladin / 圣骑士
    [96231] = { class = "PALADIN", spec = nil }, -- Rebuke / 责罚
    [31935] = { class = "PALADIN", spec = "PROTECTION" }, -- Avenger's Shield / 复仇者之盾
    [853] = { class = "PALADIN", spec = nil }, -- Hammer of Justice / 制裁之锤
    [20066] = { class = "PALADIN", spec = nil }, -- Repentance / 忏悔

    -- Monk / 武僧
    [116705] = { class = "MONK", spec = nil }, -- Spear Hand Strike / 切喉手
    [115078] = { class = "MONK", spec = nil }, -- Paralysis / 分筋错骨
    [119381] = { class = "MONK", spec = nil }, -- Leg Sweep / 扫堂腿
    [116844] = { class = "MONK", spec = nil }, -- Ring of Peace / 和平之环

    -- Warlock / 术士
    [19647] = { class = "WARLOCK", spec = nil }, -- Spell Lock / 法术封锁 (Felhunter)
    [89808] = { class = "WARLOCK", spec = nil }, -- Singe Magic / 烧灼魔法 (Imp, interrupt effect)
    [212623] = { class = "WARLOCK", spec = nil }, -- Axe Toss / 飞斧投掷 (Felguard stun, PvP Talent)

    -- Hunter / 猎人
    [147362] = { class = "HUNTER", spec = { "BEASTMASTERY", "MARKSMANSHIP" } }, -- Counter Shot / 反制射击
    [187707] = { class = "HUNTER", spec = "SURVIVAL" }, -- Muzzle / 压制
    [187650] = { class = "HUNTER", spec = nil }, -- Freezing Trap / 冰冻陷阱
    [190925] = { class = "HUNTER", spec = nil }, -- Harpoon / 鱼叉 (knockback effect)

    -- Demon Hunter / 恶魔猎人
    [183752] = { class = "DEMONHUNTER", spec = nil }, -- Disrupt / 打断
    [179057] = { class = "DEMONHUNTER", spec = nil }, -- Chaos Nova / 混乱新星
    [202137] = { class = "DEMONHUNTER", spec = "HAVOC" }, -- Sigil of Silence / 沉默符印
    [217832] = { class = "DEMONHUNTER", spec = nil }, -- Imprison / 禁锢

    -- Evoker / 唤能师
    [351338] = { class = "EVOKER", spec = nil }, -- Quell / 压制
    [368970] = { class = "EVOKER", spec = nil }, -- Tail Swipe / 扫尾 (knockback)
    [357210] = { class = "EVOKER", spec = nil }, -- Deep Breath / 深呼吸 (knockback)
}

-- Map of harmful auras (DoTs, debuffs) to class and specialization for WoW 11.1
AuraClassMap = {
    -- Warrior / 战士
    [115804] = { class = "WARRIOR", spec = nil }, -- Mortal Strike / 致死打击
    [208086] = { class = "WARRIOR", spec = nil }, -- Colossus Smash / 巨人打击
    [262115] = { class = "WARRIOR", spec = "ARMS" }, -- Deep Wounds / 深伤
    [1715] = { class = "WARRIOR", spec = nil }, -- Hamstring / 断筋
    [772] = { class = "WARRIOR", spec = nil }, -- Rend / 撕裂

    -- Mage / 法师
    [12654] = { class = "MAGE", spec = "FIRE" }, -- Ignite / 点燃
    [228354] = { class = "MAGE", spec = "FROST" }, -- Flurry / 冰风暴 (slow debuff)
    [155158] = { class = "MAGE", spec = "FROST" }, -- Frostbolt / 寒冰箭 (slow)
    [122] = { class = "MAGE", spec = nil }, -- Frost Nova / 冰霜新星
    [118] = { class = "MAGE", spec = nil }, -- Polymorph / 变形术

    -- Rogue / 潜行者
    [703] = { class = "ROGUE", spec = nil }, -- Garrote / 绞喉
    [1943] = { class = "ROGUE", spec = nil }, -- Rupture / 割裂
    [79140] = { class = "ROGUE", spec = "SUBTLETY" }, -- Vendetta / 宿敌
    [121411] = { class = "ROGUE", spec = "OUTLAW" }, -- Crimson Tempest / 猩红风暴
    [185311] = { class = "ROGUE", spec = nil }, -- Deadly Poison / 致命毒药

    -- Priest / 牧师
    [589] = { class = "PRIEST", spec = nil }, -- Shadow Word: Pain / 暗言术：痛
    [34914] = { class = "PRIEST", spec = "SHADOW" }, -- Vampiric Touch / 吸血鬼之触
    [2944] = { class = "PRIEST", spec = "SHADOW" }, -- Devouring Plague / 吞噬瘟疫
    [204213] = { class = "PRIEST", spec = "DISCIPLINE" }, -- Purge the Wicked / 涤罪邪恶
    [214621] = { class = "PRIEST", spec = "HOLY" }, -- Schism / 分裂

    -- Death Knight / 死亡骑士
    [55078] = { class = "DEATHKNIGHT", spec = "BLOOD" }, -- Blood Plague / 血之瘟疫
    [55095] = { class = "DEATHKNIGHT", spec = "FROST" }, -- Frost Fever / 冰霜疫病
    [191587] = { class = "DEATHKNIGHT", spec = "UNHOLY" }, -- Virulent Plague / 恶毒瘟疫
    [49998] = { class = "DEATHKNIGHT", spec = nil }, -- Death and Decay / 死亡凋零
    [56222] = { class = "DEATHKNIGHT", spec = nil }, -- Dark Command / 黑暗命令

    -- Shaman / 萨满
    [188389] = { class = "SHAMAN", spec = nil }, -- Flame Shock / 烈焰震击
    [196840] = { class = "SHAMAN", spec = "ELEMENTAL" }, -- Frost Shock / 冰霜震击
    [192087] = { class = "SHAMAN", spec = "ENHANCEMENT" }, -- Lashing Flames / 烈焰鞭笞
    [305485] = { class = "SHAMAN", spec = nil }, -- Lightning Lasso / 闪电套索 (PvP Talent / PvP天赋)

    -- Druid / 德鲁伊
    [155722] = { class = "DRUID", spec = "FERAL" }, -- Rake / 斜掠
    [1079] = { class = "DRUID", spec = "FERAL" }, -- Rip / 撕裂
    [164815] = { class = "DRUID", spec = "BALANCE" }, -- Sunfire / 炎阳术
    [164812] = { class = "DRUID", spec = "BALANCE" }, -- Moonfire / 月火术
    [339] = { class = "DRUID", spec = nil }, -- Entangling Roots / 纠缠根须
    [102359] = { class = "DRUID", spec = nil }, -- Mass Entanglement / 群体缠绕

    -- Paladin / 圣骑士
    [204242] = { class = "PALADIN", spec = "HOLY" }, -- Consecration / 奉献
    [197277] = { class = "PALADIN", spec = "RETRIBUTION" }, -- Judgment / 审判 (debuff effect)
    [343527] = { class = "PALADIN", spec = "PROTECTION" }, -- Final Reckoning / 最终清算

    -- Monk / 武僧
    [115804] = { class = "MONK", spec = nil }, -- Mortal Wounds / 致命伤势 (from Rising Sun Kick)
    [116095] = { class = "MONK", spec = nil }, -- Disable / 残废
    [123586] = { class = "MONK", spec = "WINDWALKER" }, -- Flying Serpent Kick / 飞蛇踢 (slow)
    [324382] = { class = "MONK", spec = "MISTWEAVER" }, -- Essence Font / 精华之泉 (debuff effect)

    -- Warlock / 术士
    [980] = { class = "WARLOCK", spec = nil }, -- Agony / 痛楚
    [172] = { class = "WARLOCK", spec = nil }, -- Corruption / 腐蚀
    [30108] = { class = "WARLOCK", spec = nil }, -- Unstable Affliction / 痛苦无常
    [348] = { class = "WARLOCK", spec = nil }, -- Immolate / 献祭
    [445474] = { class = "WARLOCK", spec = nil }, -- Immolate / 献祭
    [146739] = { class = "WARLOCK", spec = nil }, -- Corruption (modern ID) / 腐蚀
    [316099] = { class = "WARLOCK", spec = nil }, -- Unstable Affliction (modern ID) / 痛苦无常
    [278350] = { class = "WARLOCK", spec = "DEMONOLOGY" }, -- Vile Taint / 邪恶污染

    -- Hunter / 猎人
    [257284] = { class = "HUNTER", spec = nil }, -- Hunter's Mark / 猎人印记
    [131894] = { class = "HUNTER", spec = nil }, -- A Murder of Crows / 群鸦蔽日
    [3355] = { class = "HUNTER", spec = nil }, -- Freezing Trap / 冰冻陷阱
    [259491] = { class = "HUNTER", spec = "SURVIVAL" }, -- Serpent Sting / 毒蛇钉刺

    -- Demon Hunter / 恶魔猎人
    [204598] = { class = "DEMONHUNTER", spec = "HAVOC" }, -- Sigil of Flame / 烈焰符印
    [207685] = { class = "DEMONHUNTER", spec = "VENGEANCE" }, -- Sigil of Misery / 痛苦符印
    [258860] = { class = "DEMONHUNTER", spec = "HAVOC" }, -- Dark Slash / 黑暗切割
    [268178] = { class = "DEMONHUNTER", spec = nil }, -- Void Reaver / 虚空掠夺者

    -- Evoker / 唤能师
    [360806] = { class = "EVOKER", spec = nil }, -- Sleep Walk / 梦游
    [355689] = { class = "EVOKER", spec = "DEVASTATION" }, -- Landslide / 山崩
    [370553] = { class = "EVOKER", spec = "PRESERVATION" }, -- Dream Breath / 梦境吐息 (debuff effect)
    [356995] = { class = "EVOKER", spec = nil }, -- Disintegrate / 瓦解
}