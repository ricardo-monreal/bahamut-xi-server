# Bahamut XI — server

Everything needed to run the **Bahamut XI** Final Fantasy XI private server and its website on one Ubuntu 26.04 machine.

Bahamut XI runs the [Phoenix](https://github.com/phoenixffxi/Phoenix) fork of [LandSandBoat](https://github.com/LandSandBoat/server): a Level 75 era server with Phoenix's era-accuracy modules, the Phoenix launch-token login and the client-side [Era-DATs](https://github.com/phoenixffxi/Era-DATs) (shipped by the launcher). This repository holds only what Bahamut XI changes on top of Phoenix, plus the scripts that install and run it:

| Path | What it is |
| --- | --- |
| `settings/*.lua` | Bahamut XI's setting overrides (era, level cap, chat audit for the website, …). Copied into the Phoenix tree's `settings/` folder; anything not listed keeps Phoenix's default. |
| `bin/bahamut` | Install, update, build, start/stop, backups, GM levels. |
| `systemd/` | One service per game server, grouped by `bahamut-game.target`, plus the website and a nightly backup timer. |
| `nginx/` | Reverse proxy for the website (HTTPS added by certbot). |
| `config/bahamut.conf.example` | Domain, install folder, pinned Phoenix commit, file server URL. |
| `docs/` | File server layout, launcher builds, operations notes. |

The Phoenix source is not copied into this repository. `bahamut install` clones it into `/opt/bahamut/server` at the commit pinned in `PHOENIX_REF`, so moving to a newer Phoenix release is a one-line change followed by `bahamut update`. If you would rather keep a full GitHub fork (to carry your own C++ or Lua changes), fork `phoenixffxi/Phoenix`, set `PHOENIX_REPO` to your fork and `PHOENIX_REF` to your branch or commit; nothing else changes.

## What runs where

```
                      Internet
                         │
      ┌──────────────────┼──────────────────────────┐
      │ 80/443           │ 54001 54002 54230 54231   │ files.bahamut-xi.com
      ▼                  ▼ 51220                     ▼ (separate file server)
   nginx ──► website   xi_connect xi_search          launcher patches, addons,
   (Next.js, :3000)    xi_map xi_world xi_profile    Pivot HD packs, Era-DATs
      │                  │
      └────── MariaDB ───┘  (localhost only)
          xidb (game)  bahamut_web (website)
```

The website and the game share the `xidb` database: website accounts *are* game accounts, and the launcher signs in through the website, which mints a single-use Phoenix **launch token** for xiloader (no password is handed to the game client).

## Install

You need a fresh Ubuntu 26.04 server (4 CPU cores and 8 GB RAM is comfortable for building), a domain whose `A` record (and `www`) points at it, and SSH access with sudo.

```bash
sudo git clone https://github.com/ricardo-monreal/bahamut-xi-server /opt/bahamut-xi-server
cd /opt/bahamut-xi-server

# First run creates /etc/bahamut/bahamut.conf and stops.
sudo bin/bahamut install
sudo nano /etc/bahamut/bahamut.conf     # set BAHAMUT_DOMAIN, BAHAMUT_ACME_EMAIL, BAHAMUT_FILES_URL

# Second run does everything else (packages, MariaDB, build, database, services,
# firewall, nginx + HTTPS, website). The first build takes 20-40 minutes.
sudo bin/bahamut install
```

`install` is safe to run again; each step skips what is already done. When it finishes:

1. Open `https://<your domain>/register` and create your account.
2. Log in with the launcher and create a character.
3. Give it GM rights: `sudo bahamut gm <your account> 5`.

Secrets are generated during install and live only on the server:

- `/etc/bahamut/server.env`: game database login, read by the servers through LandSandBoat's `XI_NETWORK_SQL_*` environment overrides.
- `/etc/bahamut/web.env`: website database login, session secret, optional SMTP settings for password-reset e-mails.

## Day to day

```bash
bahamut status                      # services and players online
bahamut logs map                    # follow a server's log (world, connect, search, map, profile, web)
sudo bahamut restart game           # or web, or all
sudo bahamut backup                 # also runs every night at 04:30; keeps 14 days in /opt/bahamut/backups
```

### Changing settings

Edit `settings/*.lua` in this repository (commit it so it isn't lost), then:

```bash
sudo bahamut apply && sudo bahamut restart game
```

Any key from Phoenix's `settings/default/*.lua` can be added to the matching file here.

### Updating Phoenix

1. Check the Phoenix commits since `PHOENIX_REF` and pick the new commit.
2. Set `PHOENIX_REF` in `/etc/bahamut/bahamut.conf` (and in `config/bahamut.conf.example` here, for the record).
3. `sudo bahamut update`: it backs up both databases, rebuilds, applies new SQL and migrations, and restarts the game.

If Phoenix's client version changes (`CLIENT_VER` in `settings/default/login.lua`), publish a matching client patch on the file server first; see the launcher repository.

### Updating the website

```bash
sudo bahamut web-update
```

## Ports

| Port | Protocol | Used by |
| --- | --- | --- |
| 80, 443 | TCP | Website (nginx) |
| 54231 | TCP | Login (auth): launcher and xiloader |
| 54230 | TCP | Login (data) |
| 54001 | TCP | Login (view) |
| 54230 | UDP | Map server (gameplay) |
| 54002 | TCP | Search (`/sea`, auction house lists) |
| 51220 | TCP | Profile server |
| 3306, 8088, 3000 | TCP | MariaDB, world HTTP API, website: **localhost only** |

`bahamut install` opens exactly these with `ufw` (plus SSH). If the machine is behind a router or cloud firewall, forward/open the same ports there.

## Era

Bahamut XI matches the content of the Phoenix Era-DATs: the original game, Rise of the Zilart, Chains of Promathia and Treasures of Aht Urhgan, Level 75 cap unlocked through Maat's quests, and the later systems (Records of Eminence, Trusts, Field/Grounds manuals, home point teleports, Mog Garden, …) turned off. See `settings/main.lua`.

## License

The scripts and settings in this repository are released under the GNU GPL v3, the same license as LandSandBoat and Phoenix.
