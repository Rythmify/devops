# Nginx Configuration — Rythmify VM1

## Overview

This folder contains the Nginx virtual host configuration files for **VM1** (`rythmify-app-vm`, IP `20.196.3.253`). These files are not loaded automatically — they must be deployed to the server manually (see [Deployment](#deployment)).

| File | Domain | Purpose |
|---|---|---|
| `rythmify-back.duckdns.org.conf` | `rythmify-back.duckdns.org` | Backend API + Socket.IO proxy, GeoIP2 country injection, HTTPS, Grafana proxy, Nginx stub_status |
| `rythmify.duckdns.org.conf` | `rythmify.duckdns.org` | Frontend Vite dev server proxy, HTTPS |

The backend config contains three server blocks:
- **HTTP → HTTPS redirect** on port 80
- **HTTPS backend** on port 443 — proxies `/health`, `/grafana/`, and all API + WebSocket traffic to `localhost:8080` / `localhost:3000`
- **stub_status** on `172.17.0.1:8081` — scraped by `nginx_exporter` inside Docker

The `geoip2` directive (above all `server {}` blocks, in the `http {}` context) resolves every client IP to a country code and injects it as `X-Country-Code` on all proxied requests to the backend.

---

## Prerequisites

Install the following packages on VM1:

```bash
# Nginx + GeoIP2 dynamic module
sudo apt update
sudo apt install -y nginx libnginx-mod-http-geoip2

# MaxMind GeoIP database updater
sudo apt install -y geoipupdate

# Certbot for SSL certificate issuance and renewal
sudo apt install -y certbot python3-certbot-nginx
```

`libnginx-mod-http-geoip2` drops a module config file into `/etc/nginx/modules-enabled/` that loads the GeoIP2 module automatically — no manual `load_module` directive is needed in `nginx.conf`.

---

## GeoIP Setup

The backend config resolves client IPs using MaxMind's free **GeoLite2-Country** database. A free MaxMind account is required.

**1. Create a MaxMind account**

Sign up at https://www.maxmind.com/en/geolite2/signup and generate a License Key under **My Account → Manage License Keys**.

**2. Configure `/etc/GeoIP.conf`**

```ini
AccountID YOUR_ACCOUNT_ID
LicenseKey YOUR_LICENSE_KEY
EditionIDs GeoLite2-Country
DatabaseDirectory /var/lib/GeoIP
```

Replace `YOUR_ACCOUNT_ID` and `YOUR_LICENSE_KEY` with your actual values.

**3. Download the database**

```bash
sudo geoipupdate
```

**4. Verify the file exists**

```bash
ls -lh /var/lib/GeoIP/GeoLite2-Country.mmdb
```

Expected: a file of approximately 6–7 MB. If the file is missing, Nginx will fail to start with an error such as:

```
geoip2: unable to open database "/var/lib/GeoIP/GeoLite2-Country.mmdb"
```

---

## Deployment

**1. Copy configs to `sites-available`**

```bash
sudo cp rythmify-back.duckdns.org.conf /etc/nginx/sites-available/
sudo cp rythmify.duckdns.org.conf      /etc/nginx/sites-available/
```

**2. Enable the sites**

```bash
sudo ln -s /etc/nginx/sites-available/rythmify-back.duckdns.org.conf \
           /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/rythmify.duckdns.org.conf \
           /etc/nginx/sites-enabled/
```

Disable the default Nginx site if it is enabled (it conflicts with the new configs):

```bash
sudo rm -f /etc/nginx/sites-enabled/default
```

**3. Test the configuration**

```bash
sudo nginx -t
```

Both lines must read `syntax is ok` and `test is successful`. Fix any reported errors before continuing.

**4. Reload Nginx**

```bash
sudo systemctl reload nginx
```

---

## X-Country-Code Header

Nginx resolves each request's client IP against the **MaxMind GeoLite2-Country** database using the `ngx_http_geoip2` module. The `geoip2` block at the top of `rythmify-back.duckdns.org.conf` declares the variable:

```nginx
geoip2 /var/lib/GeoIP/GeoLite2-Country.mmdb {
    $geoip2_data_country_code country iso_code;
}
```

That variable is then injected as a request header before the request is forwarded to the backend:

```nginx
proxy_set_header X-Country-Code $geoip2_data_country_code;
```

The backend reads it as:

```js
const country = req.headers['x-country-code']; // e.g. "EG", "SA", "US"
```

The value is an **ISO 3166-1 alpha-2** two-letter code. Examples: `EG` (Egypt), `SA` (Saudi Arabia), `US` (United States), `GB` (United Kingdom). The variable resolves to an empty string for private or unroutable IP addresses (e.g. `127.0.0.1`, `10.x.x.x`, `172.16.x.x`).

Because the header is set by Nginx at the proxy layer, it **cannot be spoofed** by clients — any `X-Country-Code` value sent in the original request is overwritten by Nginx before it reaches the backend.

---

## Grafana Proxy

Grafana runs inside Docker on port `3000`. It is not exposed publicly. Instead, the backend server block proxies `/grafana/` to `http://localhost:3000/`:

```nginx
location /grafana/ {
    proxy_pass http://localhost:3000/;
    proxy_http_version 1.1;
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Access Grafana at: **https://rythmify-back.duckdns.org/grafana/**

No SSH tunnel or port forwarding is needed.

---

## Nginx stub_status

`nginx_exporter` (in `docker-compose.monitoring.yml`) scrapes Nginx connection metrics from a dedicated `stub_status` endpoint. The endpoint is defined in `rythmify-back.duckdns.org.conf` as a server block bound to the Docker bridge host IP:

```nginx
server {
    listen 172.17.0.1:8081;
    server_name _;

    location /nginx_status {
        stub_status;
        allow 127.0.0.1;
        allow 172.16.0.0/12;
        deny  all;
    }

    location / {
        return 444;
    }
}
```

`172.17.0.1` is the Docker bridge host IP — it is reachable from Docker containers but not from the public internet or from the VM loopback. `nginx_exporter` in the monitoring compose stack is configured to scrape `http://172.17.0.1:8081/nginx_status`.

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

SSL certificates are managed by **Certbot** and must **not** be committed to this repository.

The configs reference certificates at:

```
/etc/letsencrypt/live/rythmify.duckdns.org/fullchain.pem
/etc/letsencrypt/live/rythmify.duckdns.org/privkey.pem
```

The certificate covers both `rythmify.duckdns.org` and `rythmify-back.duckdns.org` as Subject Alternative Names. Issue it with:

```bash
sudo certbot certonly --nginx \
  -d rythmify.duckdns.org \
  -d rythmify-back.duckdns.org
```

Certbot installs a systemd timer (`certbot.timer`) for automatic renewal. Verify it is active:

```bash
sudo systemctl status certbot.timer
```

The files `options-ssl-nginx.conf` and `ssl-dhparams.pem` referenced in both configs are created automatically by Certbot when the first certificate is issued.

---

## Updating the GeoIP Database

MaxMind releases updated GeoLite2-Country databases approximately twice per month. To refresh the local copy manually:

```bash
sudo geoipupdate
sudo systemctl reload nginx
```

To automate this, create a cron job at `/etc/cron.d/geoipupdate`:

```cron
# Refresh MaxMind GeoLite2-Country on the 1st and 15th of each month at 03:00
0 3 1,15 * * root /usr/bin/geoipupdate && systemctl reload nginx
```
