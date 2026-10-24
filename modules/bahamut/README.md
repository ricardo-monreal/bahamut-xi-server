# Bahamut XI modules

Your own server changes, kept apart from Phoenix so `bahamut update` never overwrites them.
`sudo bahamut apply` copies this folder to `/opt/bahamut/server/modules/bahamut` and adds one
line, `bahamut`, to the end of Phoenix's `modules/init.txt`, so everything here loads after
Phoenix's own modules.

| Kind | Put it in | After a change |
| --- | --- | --- |
| Lua (scripts, overrides) | `lua/*.lua` | `sudo bahamut apply && sudo bahamut restart game` |
| C++ | `cpp/*.cpp` | `sudo bahamut apply && sudo bahamut build && sudo bahamut restart game` |
| SQL | `sql/*.sql` | `sudo bahamut apply && sudo bahamut db-update && sudo bahamut restart game` |

A Lua module overrides a function from Phoenix's `scripts/` and calls `super(...)` to keep the
original behaviour. `lua/welcome.lua` is a small working example; `lua/solo_trusts.lua`
(5 trusts, allowed everywhere, starter party on login) is a larger one with options at the top.
`lua/trust_shop.lua` adds the Trust Liaison NPC in Lower Jeuno: 35 more trusts in tiers that open
at job level 20, 30, 40, 50, 60, 70 and 75, bought with conquest points through menus. Phoenix's own modules
(`/opt/bahamut/server/modules/custom`, `phoenix`, `era`) are good references.

Plain rates and switches (EXP rate, trusts, level cap...) are settings, not modules: change them
in `settings/main.lua` (or `map.lua`, `login.lua`) in this repo, then `sudo bahamut apply &&
sudo bahamut restart game`.
