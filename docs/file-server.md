# The file server

Downloads (the game client, launcher installers, addons, HD packs, item icons) come from a separate machine, `files.bahamut-xi.com`, so big transfers never compete with the game server. Any static host works: nginx on a VPS with plenty of bandwidth, or object storage (Cloudflare R2, Backblaze B2, S3) behind a CDN. Every new player downloads the full client (~15 GB), so egress cost is what matters most.

## Layout

```
/srv/files/
  launcher/
    BahamutXI-Setup.exe           latest Windows launcher (fixed name; the website links to it)
    BahamutXI.AppImage            latest Linux launcher
    news.json                     launcher news
    client/manifest.json          game client manifest   } from tools/make-manifest.mjs
    client/files/ab/abcdef….gz    game client blobs      } in the launcher repo
    addons.json, addons/*.zip     optional addons and plugins   } from tools/make-catalogs.mjs
    pivot.json,  packs/*.zip      optional HD packs (XIPivot)   }
    proton/GE-Proton11-5.tar.gz   optional: serve GE-Proton yourself (linux.protonUrl)
  icons/
    items/<id>.png                item icons for the website (scripts/import-items.mjs)
```

The paths match `launcher.config.json` in the launcher repo and `FILES_URL` in `/etc/bahamut/web.env`.

## nginx (Ubuntu)

```bash
sudo apt install nginx certbot python3-certbot-nginx
sudo mkdir -p /srv/files && sudo chown $USER /srv/files
```

`/etc/nginx/sites-available/files.conf`:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name files.bahamut-xi.com;
    root /srv/files;

    autoindex off;
    sendfile on;
    tcp_nopush on;

    # Client blobs are content-addressed: once published they never change.
    location /launcher/client/files/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Manifests and catalogs change with every release; always revalidate.
    location ~ \.json$ {
        add_header Cache-Control "no-cache";
    }

    # Item icons are shown on the website.
    location /icons/ {
        expires 30d;
        add_header Access-Control-Allow-Origin "https://bahamut-xi.com";
    }

    # Range requests let the launcher resume interrupted downloads.
    location / {
        try_files $uri =404;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/files.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d files.bahamut-xi.com
```

## Publishing order

Upload blobs before the files that point at them, so players never see a manifest whose files aren't there yet:

1. `client/files/…` then `client/manifest.json`
2. `addons/*.zip`, `packs/*.zip`, then `addons.json`, `pivot.json`
3. A new launcher: `BahamutXI-Setup-<version>.exe` → copy to `BahamutXI-Setup.exe` (same for the AppImage)

`rsync -av --delay-updates` does step 1 safely in one command when run with the blobs first:

```bash
rsync -av publish/files/ files:/srv/files/launcher/client/files/
rsync -av publish/manifest.json files:/srv/files/launcher/client/
```
