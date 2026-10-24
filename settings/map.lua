-----------------------------------
-- BAHAMUT XI: MAP SETTINGS
-----------------------------------
-- Only the keys Bahamut XI changes. Defaults: settings/default/map.lua.
-----------------------------------

xi = xi or {}
xi.settings = xi.settings or {}

xi.settings.map =
{
    -- The website's Yells page reads /yell and /shout lines from audit_chat.
    -- Tells, party and linkshell chat stay private and are not recorded.
    AUDIT_CHAT  = true,
    AUDIT_YELL  = true,
    AUDIT_SHOUT = true,

    -- Player-to-player transfers, for GM investigations.
    AUDIT_PLAYER_TRADES = true,
    AUDIT_PLAYER_BAZAAR = true,
    AUDIT_PLAYER_DBOX   = true,
    AUDIT_PLAYER_VENDOR = true,

    -- Double EXP from kills (also capacity points). Keep main.lua's EXP_RATE the same.
    EXP_RATE = 2.0,

    -- Double the chance a synthesis raises crafting skill: 60% -> 100% below skill 50,
    -- 25% -> 50% from 50 up (halved when the synth breaks, as normal).
    CRAFT_CHANCE_MULTIPLIER = 2.0,
}
