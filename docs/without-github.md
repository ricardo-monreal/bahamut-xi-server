# Running Bahamut XI without GitHub

Everything Bahamut XI needs can live on your own machines. The file server keeps a Git mirror of every repository and the release files the launcher downloads; the game server and your build PC are told to use it; and all builds run locally instead of on GitHub Actions. Do the "download now" steps while GitHub is still reachable: after that, nothing depends on it.

## What used GitHub

| Where | What it fetched | Without GitHub |
| --- | --- | --- |
| Game server install and `bahamut update` | Phoenix, its submodules (navmeshes), the website, Era-DATs | Git mirror + `GIT_MIRROR` |
| Game server build | About 15 C++ libraries (CPM: fmt, spdlog, asio, …) and CPM itself | Git mirror, plus a permanent cache in `/opt/bahamut/cache/cpm` |
| Client build (Windows) | Ashita, Era-DATs, xiloader and its libraries | Git mirror |
| Launcher and xiloader releases | GitHub Actions | Local builds (below) |
| Launcher builds | Electron, NSIS, winCodeSign, AppImage tools | Downloaded once, then cached |
| Players' Linux launchers | GE-Proton, umu-launcher, winetricks | Hosted on the file server (`linux.*Url`) |

Not GitHub, still internet: Ubuntu/Debian packages, the npm registry, PyPI (Phoenix's Python tools), and Valve's Steam Linux Runtime that umu downloads on a player's first Play.

## 1. Git mirror on the file server

```bash
sudo apt install -y git fcgiwrap
sudo systemctl enable --now fcgiwrap
sudo mkdir -p /srv/git && sudo chown moises:moises /srv/git

git clone https://github.com/ricardo-monreal/bahamut-xi-server ~/bahamut-xi-server
~/bahamut-xi-server/tools/git-mirror.sh
```

The first run copies about 40 repositories (several GB: LandSandBoat's navmeshes are the largest) into `/srv/git/github.com/<owner>/<repo>.git`. The list is `/srv/git/mirrors.txt`; the script also follows every mirror's submodules and the libraries its CMake files download, so new ones are picked up when Phoenix changes.

Serve it with Git's smart HTTP protocol (needed for the shallow and partial clones the builds use). Add this inside the `server { … }` block of `/etc/nginx/sites-available/files.conf`:

```nginx
    # Git mirror, read-only (tools/git-mirror.sh). Pushes go over SSH.
    location ~ ^/git(/.*)$ {
        client_max_body_size 0;
        fastcgi_pass unix:/run/fcgiwrap.socket;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /usr/lib/git-core/git-http-backend;
        fastcgi_param GIT_PROJECT_ROOT /srv/git;
        fastcgi_param GIT_HTTP_EXPORT_ALL "";
        fastcgi_param PATH_INFO $1;
        # The repositories belong to moises; git-http-backend runs as www-data.
        fastcgi_param GIT_CONFIG_COUNT 1;
        fastcgi_param GIT_CONFIG_KEY_0 safe.directory;
        fastcgi_param GIT_CONFIG_VALUE_0 *;
    }
```

```bash
sudo nginx -t && sudo systemctl reload nginx
git ls-remote http://10.2.5.170/git/github.com/phoenixffxi/Phoenix | head -1
```

Keep it current with a nightly job (`crontab -e`):

```
30 3 * * * /home/moises/bahamut-xi-server/tools/git-mirror.sh >> /home/moises/git-mirror.log 2>&1
```

## 2. Point the game server at the mirror

In `/etc/bahamut/bahamut.conf`:

```bash
GIT_MIRROR="http://10.2.5.170/git"
```

The next `sudo bahamut update` or `sudo bahamut web-update` adds one system-wide Git setting that sends every `https://github.com/…` URL to the mirror: Phoenix, its submodules, the website and the libraries the build downloads. Nothing else changes, and clearing `GIT_MIRROR` removes it again. Check it with:

```bash
git config --system --get-regexp insteadof
git ls-remote --get-url https://github.com/phoenixffxi/Phoenix
```

Build libraries are also kept in `/opt/bahamut/cache/cpm` from the next build on, so rebuilds work even without the mirror.

## 3. Your PCs: read from the mirror, push to it

On the Windows build PC (and any machine you develop on):

```powershell
git config --global url."http://10.2.5.170/git/github.com/".insteadOf "https://github.com/"
git config --global url."moises@10.2.5.170:/srv/git/github.com/".pushInsteadOf "https://github.com/"
```

Repositories keep their GitHub-style addresses, but fetches come from the mirror and pushes go to it over SSH. When you stop pushing to GitHub, mark your own repositories in `/srv/git/mirrors.txt` so the nightly job stops overwriting them from GitHub:

```
ricardo-monreal/bahamut-xi-server local
ricardo-monreal/bahamut-xi-web local
ricardo-monreal/bahamut-xi-launcher local
```

Do the same for Phoenix if you start carrying your own Phoenix changes.

## 4. Build releases locally

### xiloader (Windows)

Install Visual Studio 2022 Build Tools with "Desktop development with C++", plus CMake, then:

```powershell
git clone https://github.com/phoenixffxi/xiloader C:\xiloader
cd C:\xiloader
git checkout 806d1c79a3eef254572b56e069ba0ddd291b3ecf
$env:CPM_SOURCE_CACHE = "C:\bahamut-cache\cpm"
cmake -S . -B build -A Win32 -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
copy xiloader.exe C:\bahamut-xi-launcher\vendor\
```

The exe is written to the source folder, not `build\`.

### Launcher, Windows installer

```powershell
cd C:\bahamut-xi-launcher
git pull
npm.cmd ci
npm.cmd run dist
```

The installer is `dist\BahamutXI-Setup-<version>.exe`. The first build downloads Electron, NSIS and winCodeSign; they are kept in `%LOCALAPPDATA%\electron\Cache` and `%LOCALAPPDATA%\electron-builder\Cache`. Copy those two folders to the file server (`/srv/files/build-cache/windows/`) and back onto any new build PC to build offline.

### Launcher, Linux AppImage

On any Ubuntu machine with Node.js 22 (the game server works):

```bash
git clone https://github.com/ricardo-monreal/bahamut-xi-launcher ~/bahamut-xi-launcher
cd ~/bahamut-xi-launcher
npm ci
npm run dist:linux
```

The AppImage is `dist/BahamutXI-<version>-x86_64.AppImage`. Its build tools are cached in `~/.cache/electron` and `~/.cache/electron-builder`; keep a copy of those too.

### Publish

1. Bump `version` in `package.json`, commit, and tag it: `git tag v1.0.3 && git push origin main v1.0.3` (goes to the mirror).
2. Copy the two files to the file server under the fixed names, exactly as with GitHub releases:

```powershell
scp .\dist\BahamutXI-Setup-1.0.3.exe moises@10.2.5.170:/srv/files/launcher/BahamutXI-Setup.exe
scp moises@<linux build box>:bahamut-xi-launcher/dist/BahamutXI-1.0.3-x86_64.AppImage .
scp .\BahamutXI-1.0.3-x86_64.AppImage moises@10.2.5.170:/srv/files/launcher/BahamutXI.AppImage
```

Keep the versioned files too (`/srv/files/launcher/releases/`) so older launchers stay available.

## 5. Players' Linux runtime

Download these once, on any PC, and put them in `/srv/files/launcher/runtime/` on the file server:

| File | From |
| --- | --- |
| The GE-Proton11-5 `.tar.gz` (x86_64) and its `.sha512sum` | github.com/GloriousEggroll/proton-ge-custom/releases/tag/GE-Proton11-5 |
| The umu-launcher zipapp `.tar` | github.com/Open-Wine-Components/umu-launcher/releases (latest) |
| `winetricks` | raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks |

Then set the addresses in the launcher's `launcher.config.json`, build and publish a new launcher:

```json
"linux": {
  "protonVersion": "GE-Proton11-5",
  "protonUrl": "http://10.2.5.170/launcher/runtime/<the GE-Proton file>.tar.gz",
  "umuUrl": "http://10.2.5.170/launcher/runtime/<the umu zipapp file>.tar",
  "winetricksUrl": "http://10.2.5.170/launcher/runtime/winetricks"
}
```

## 6. Check it

Block GitHub for a moment (on the router, or `127.0.0.1 github.com` in the game server's `/etc/hosts`), then run `sudo bahamut update`, build the launcher on each PC, and do a first Play on a fresh Linux install. Anything that still reaches GitHub fails loudly; remove the block afterwards.
