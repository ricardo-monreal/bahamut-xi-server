-----------------------------------
-- BAHAMUT XI: MAIN SETTINGS
-----------------------------------
-- Only the keys Bahamut XI changes live here. Everything else comes from
-- settings/default/main.lua in the Phoenix fork (LandSandBoat fills in any
-- key that is missing from this file).
--
-- Era: Level 75 cap, before Wings of the Goddess (late 2007), the same era
-- the Phoenix Era-DATs and the era modules in modules/init.txt target.
-----------------------------------

xi = xi or {}
xi.settings = xi.settings or {}

xi.settings.main =
{
    SERVER_NAME = 'Bahamut',

    SERVER_MESSAGE =
        'Welcome to Bahamut XI!\n' ..
        'News, rules and your characters: https://bahamut-xi.com',

    -- Lock content to the enabled expansions (uses the content_tag columns).
    RESTRICT_CONTENT = 1,

    -- Expansions: the original game, Zilart, Promathia and Aht Urhgan.
    -- Era-DATs expects WotG, Abyssea and Voidwatch to be off.
    ENABLE_ROTZ      = 1,
    ENABLE_COP       = 1,
    ENABLE_TOAU      = 1,
    ENABLE_WOTG      = 0,
    ENABLE_ACP       = 0,
    ENABLE_AMK       = 0,
    ENABLE_ASA       = 0,
    ENABLE_ABYSSEA   = 0,
    ENABLE_SOA       = 0,
    ENABLE_ROV       = 0,
    ENABLE_TVR       = 0,
    ENABLE_VOIDWATCH = 0,

    -- Later-era systems.
    ENABLE_MOG_HOUSE_2F   = 0,
    ENABLE_MOG_GARDEN     = 0,
    ENABLE_FIELD_MANUALS  = 0,
    ENABLE_GROUNDS_TOMES  = 0,
    ENABLE_SURVIVAL_GUIDE = 0,
    ENABLE_DAILY_TALLY    = 0,
    ENABLE_ROE            = 0,
    ENABLE_ROE_TIMED      = 0,
    ENABLE_MAGIAN_TRIALS  = 0,
    ENABLE_VOIDWALKER     = 0,
    ENABLE_MONSTROSITY    = 0,
    ENABLE_TRUST_CASTING  = 0,
    ENABLE_TRUST_QUESTS   = 0,
    HOMEPOINT_TELEPORT    = 0,

    -- Level 75 cap, unlocked through Maat's Limit Break quests as in era.
    INITIAL_LEVEL_CAP = 50,
    MAX_LEVEL         = 75,

    -- Retail-era rates.
    EXP_RATE  = 1.000,
    START_GIL = 10,
    ALL_MAPS  = 0,
}
