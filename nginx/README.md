# Nginx Configuration — Rythmify VM1

## Overview

This folder contains the Nginx virtual host configuration files for **VM1** (`rythmify-app-vm`, IP `20.196.3.253`).

| File | Domain | Purpose |
|---|---|---|
| `rythmify-back.duckdns.org.conf` | `rythmify-back.duckdns.org` | Backend API + Socket.IO WebSocket proxy, GeoIP2 country injection, Grafana proxy, HTTPS |
| `rythmify.duckdns.org.conf` | `rythmify.duckdns.org` | Frontend static files (React SPA), HTTPS |

---

## Domain Split

### rythmify.duckdns.org — Frontend

Serves the pre-built React SPA from `/var/www/rythmify/`. No backend proxying on this domain. The frontend app calls `https://rythmify-back.duckdns.org/api/v1/...` directly — all API traffic goes to the backend domain.

### rythmify-back.duckdns.org — Backend

Reverse proxy to the Node.js backend container on `localhost:8080` and Grafana on `localhost:3000`. All API, WebSocket, and monitoring traffic enters through this domain.

---

## Location Blocks

### rythmify-back.duckdns.org — HTTPS server (port 443)

| Location | Proxy target | Purpose |
|---|---|---|
| `/health` | `http://localhost:8080` | Liveness probe used by Blackbox exporter — no WebSocket headers |
| `/api/` | `http://localhost:8080` | Explicit REST API path — full header set including WebSocket upgrade (see note) |
| `/grafana/` | `http://localhost:3000/` | Grafana dashboard — proxied internally, not exposed on its own port |
| `/` | `http://localhost:8080` | All API + Socket.IO WebSocket traffic — full header set including X-Country-Code |

**Why the explicit `/api/` block?**

Nginx uses longest-prefix matching. Declaring `/api/` explicitly makes routing intent clear and allows per-path tuning (rate limits, timeouts) in future without touching the catch-all `/` block. WebSocket upgrade headers are kept on `/api/` so Socket.IO clients using a custom path (e.g. `/api/socket.io/`) are not broken.

**Required headers on `/` and `/api/`:**

```nginx
proxy_set_header Upgrade    $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_set_header Host              $host;
proxy_set_header X-Real-IP         $remote_addr;
proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Country-Code    $geoip2_data_country_code;
proxy_cache_bypass $http_upgrade;
```

### rythmify.duckdns.org — HTTPS server (port 443)

| Location | Behaviour | Purpose |
|---|---|---|
| `/` | `try_files $uri $uri/ /index.html` | React SPA fallback — unknown paths serve `index.html` so client-side routing works |

No proxy blocks. No `/nginx_status`. This domain is static-files-only.

---

## GeoIP2

The `geoip2` directive appears at the **http context level** (above all `server {}` blocks) in `rythmify-back.duckdns.org.conf`:

```nginx
geoip2 /var/lib/GeoIP/GeoLite2-Country.mmdb {
    $geoip2_data_country_code country iso_code;
}
```

This resolves the client IP to an ISO 3166-1 alpha-2 country code. The variable is injected as a request header on all proxied backend requests:

```nginx
proxy_set_header X-Country-Code $geoip2_data_country_code;
```

The backend reads it as:

```js
const country = req.headers['x-country-code']; // e.g. "EG", "SA", "US"
```

The value is empty for private or unroutable IPs (`127.0.0.1`, `10.x.x.x`, `172.16.x.x`). The header cannot be spoofed — Nginx overwrites any client-supplied value before forwarding.

**Setup:**

```bash
# Install module and updater
sudo apt install -y libnginx-mod-http-geoip2 geoipupdate

# Configure /etc/GeoIP.conf with your MaxMind account credentials
# Sign up free at https://www.maxmind.com/en/geolite2/signup
AccountID YOUR_ACCOUNT_ID
LicenseKey YOUR_LICENSE_KEY
EditionIDs GeoLite2-Country
DatabaseDirectory /var/lib/GeoIP

# Download the database
sudo geoipupdate

# Verify (expect ~6-7 MB file)
ls -lh /var/lib/GeoIP/GeoLite2-Country.mmdb
```

`libnginx-mod-http-geoip2` auto-loads the module via `/etc/nginx/modules-enabled/` — no manual `load_module` directive is needed in `nginx.conf`.

---

## Nginx stub_status (Internal — 172.17.0.1:8081)

`nginx_exporter` in `docker-compose.monitoring.yml` scrapes Nginx connection metrics from a dedicated internal endpoint defined in `rythmify-back.duckdns.org.conf`:

```nginx
server {
    listen 172.17.0.1:8081;
    server_name _;

    location /nginx_status {
        stub_status;
        allow all;
    }

    location / {
        return 444;
    }
}
```

`172.17.0.1` is the Docker bridge host IP — reachable from Docker containers but not from the public internet. `allow all` is safe because the listen address already limits access to bridge-network traffic. `nginx_exporter` is configured to scrape `http://172.17.0.1:8081/nginx_status`.

Verify from the VM:

```bash
curl -s http://172.17.0.1:8081/nginx_status
```

Expected output:

```
Active connections: 3
server accepts handled requests
 12 12 24
Reading: 0 Writing: 1 Waiting: 2
```

---

## SSL

Certificates are managed by **Certbot** and must **not** be committed to this repository.

Both configs reference:

```
/etc/letsencrypt/live/rythmify.duckdns.org/fullchain.pem
/etc/letsencrypt/live/rythmify.duckdns.org/privkey.pem
```

The certificate covers both domains as Subject Alternative Names:

```bash
sudo certbot certonly --nginx \
  -d rythmify.duckdns.org \
  -d rythmify-back.duckdns.org
```

Certbot installs a systemd timer for automatic renewal. Verify it is active:

```bash
sudo systemctl status certbot.timer
```

`options-ssl-nginx.conf` and `ssl-dhparams.pem` (referenced in both configs) are created automatically by Certbot on first issuance.

---

## Prerequisites

```bash
sudo apt update
sudo apt install -y nginx libnginx-mod-http-geoip2 geoipupdate certbot python3-certbot-nginx
```

---

## Deployment

**1. Copy configs to `sites-available`**

```bash
sudo cp nginx/rythmify-back.duckdns.org.conf /etc/nginx/sites-available/
sudo cp nginx/rythmify.duckdns.org.conf      /etc/nginx/sites-available/
```

**2. Enable the sites**

```bash
sudo ln -sf /etc/nginx/sites-available/rythmify-back.duckdns.org.conf \
            /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/rythmify.duckdns.org.conf \
            /etc/nginx/sites-enabled/

# Disable the default site if still enabled
sudo rm -f /etc/nginx/sites-enabled/default
```

**3. Create the frontend static directory**

```bash
sudo mkdir -p /var/www/rythmify
sudo chown -R www-data:www-data /var/www/rythmify
```

**4. Test**

```bash
sudo nginx -t
```

Both lines must read `syntax is ok` and `test is successful`.

**5. Reload**

```bash
sudo systemctl reload nginx
```

**Applying updates from the repo:**

```bash
cd ~/devops && git pull
sudo cp nginx/rythmify-back.duckdns.org.conf /etc/nginx/sites-available/
sudo cp nginx/rythmify.duckdns.org.conf      /etc/nginx/sites-available/
sudo nginx -t && sudo systemctl reload nginx
```

---

## Updating the GeoIP Database

MaxMind releases updated databases approximately twice per month:

```bash
sudo geoipupdate
sudo systemctl reload nginx
```

Automate with a cron job at `/etc/cron.d/geoipupdate`:

```cron
0 3 1,15 * * root /usr/bin/geoipupdate && systemctl reload nginx
```
