-----------------------------------
-- BAHAMUT XI: NETWORK SETTINGS
-----------------------------------
-- Only the keys Bahamut XI changes. Defaults: settings/default/network.lua.
--
-- The real database password is NOT stored here. The servers read it from
-- the environment (XI_NETWORK_SQL_LOGIN / XI_NETWORK_SQL_PASSWORD), which
-- systemd loads from /etc/bahamut/server.env. See bin/bahamut.
--
-- SQL_LOGIN and SQL_PASSWORD must still be listed below: the server only
-- applies XI_* environment overrides to keys present in this file.
-----------------------------------

xi = xi or {}
xi.settings = xi.settings or {}

xi.settings.network =
{
    SQL_HOST     = '127.0.0.1',
    SQL_PORT     = 3306,
    SQL_DATABASE = 'xidb',
    SQL_LOGIN    = 'bahamut_game', -- overridden by XI_NETWORK_SQL_LOGIN
    SQL_PASSWORD = '',             -- overridden by XI_NETWORK_SQL_PASSWORD

    -- Small read-only JSON API (/api/sessions etc.) used by the website.
    -- Bound to localhost only; nginx does not expose it.
    ENABLE_HTTP = true,
    HTTP_HOST   = '127.0.0.1',
    HTTP_PORT   = 8088,
}
