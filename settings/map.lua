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
}
