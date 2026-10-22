-----------------------------------
-- BAHAMUT XI: NETWORK SETTINGS
-----------------------------------
-- Only the keys Bahamut XI changes. Defaults: settings/default/network.lua.
--
-- The database login is NOT stored here. The servers read it from the
-- environment (XI_NETWORK_SQL_LOGIN / XI_NETWORK_SQL_PASSWORD), which
-- systemd loads from /etc/bahamut/server.env. See bin/bahamut.
-----------------------------------

xi = xi or {}
xi.settings = xi.settings or {}

xi.settings.network =
{
    SQL_HOST     = '127.0.0.1',
    SQL_PORT     = 3306,
    SQL_DATABASE = 'xidb',

    -- Small read-only JSON API (/api/sessions etc.) used by the website.
    -- Bound to localhost only; nginx does not expose it.
    ENABLE_HTTP = true,
    HTTP_HOST   = '127.0.0.1',
    HTTP_PORT   = 8088,
}
