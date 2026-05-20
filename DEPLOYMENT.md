# KEIT Odoo — Production Deployment Runbook

End-to-end steps to deploy this stack on KEIT's VM, hardened, with HTTPS,
self-heal, and backups. Follow top to bottom. Estimated time: ~2–3 hours
(plus data migration, which is separate).

---

## 0. Prerequisites

**From KEIT's side (request these before you start):**
- A Linux VM (Debian/Ubuntu), ≥ 4 GB RAM, ≥ 20 GB disk, Docker + Compose installed
- SSH access for you
- **One DNS A record**: `odoo.keit.bg` → the VM's IP
  (internal DNS + private IP if internal-only; public IP if exposed)
- Decision: internal-only (VPN access) or internet-facing?

**Check on the VM:**
```bash
docker --version && docker compose version
docker info | grep -iE 'total memory|cpus'
df -h /            # ≥ 20 GB free
```

Ensure the Docker daemon survives reboots:
```bash
sudo systemctl enable docker
```

---

## 1. Get the code onto the VM

Ship the repo **without** `_internal/`, `addons/`, and `.env` (the
`.gitignore` already excludes these). Either:

```bash
# Option A: git (if you host the repo)
git clone <your-repo-url> /opt/keit-odoo

# Option B: rsync from your laptop (excludes are honored via .gitignore-style)
rsync -av --exclude='_internal' --exclude='addons' --exclude='.env' \
      ~/odoo/ user@vm:/opt/keit-odoo/
```

`addons/` is intentionally not shipped — it's regenerated on the VM in step 3.

---

## 2. Secrets

```bash
cd /opt/keit-odoo
cp .env.example .env
```

Edit `.env` — replace ALL defaults with strong values:
```
POSTGRES_USER=odoo
POSTGRES_PASSWORD=<openssl rand -hex 24>
POSTGRES_DB=postgres
ODOO_ADMIN_PASSWD=<openssl rand -hex 24>     # master DB-management password
ODOO_PORT=8069
ODOO_LONGPOLLING_PORT=8072
COMPOSE_PROJECT_NAME=keit
```
Generate secrets: `openssl rand -hex 24`

---

## 3. Clone OCA modules

```bash
make oca        # ~10 min, ~400 MB into ./addons/
```

---

## 4. Harden `config/odoo.conf` for production

Edit `config/odoo.conf` and change these for the production DB:

```ini
admin_passwd = <same strong value as ODOO_ADMIN_PASSWD>
list_db = False            ; hide the database manager / DB list
dbfilter = ^keit$          ; serve ONLY the production DB
proxy_mode = True          ; trust X-Forwarded-* from Caddy
db_host = db
db_user = odoo
db_password = <same as POSTGRES_PASSWORD in .env>
```

`list_db = False` + `dbfilter` mean the public can't enumerate or create
databases — important once it's reachable.

---

## 5. Add the Caddy reverse proxy (HTTPS)

```bash
cp Caddyfile.example Caddyfile
# edit Caddyfile: set the real hostname (odoo.keit.bg)
```

Add the Caddy service to the stack. Create `docker-compose.override.yml`:

```yaml
services:
  caddy:
    image: caddy:2
    restart: unless-stopped
    depends_on: [odoo]
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy-data:/data
      - caddy-config:/config
    labels:
      - autoheal=true
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "5" }

  odoo:
    # Stop publishing 8069/8072 to the host — Caddy fronts them now.
    ports: !reset []

volumes:
  caddy-data:
  caddy-config:
```

> Note: if your Compose version doesn't support `!reset`, instead remove
> the `ports:` block from `odoo` in the base file, or leave it bound to
> `127.0.0.1` only: `"127.0.0.1:8069:8069"`.

Now Odoo is reachable only through Caddy on 443 (HTTPS), not directly.

---

## 6. Bring up the stack

```bash
make up
docker compose ps          # all healthy?
docker compose logs -f caddy   # watch the cert get issued
```

Visit `https://odoo.keit.bg` — you should get a valid certificate and the
Odoo login.

---

## 7. Create the production database (clean, no demo data)

Volumes are empty, so there's no DB yet. Create it via **CLI** — this
bypasses the (disabled) web DB manager entirely. No browser needed here.

**A. Create the empty DB (no demo data).** Creates one user: login `admin`.
```bash
docker compose exec odoo odoo -c /etc/odoo/odoo.conf \
  -d keit -i base --without-demo=all --stop-after-init --no-http
```

**B. Set the admin password deterministically** (so you know exactly what it is):
```bash
echo "
admin = env.ref('base.user_admin')
admin.password = 'PUT-A-STRONG-PASSWORD-HERE'
env.cr.commit()
print('admin password set')
" | docker compose exec -T odoo odoo shell -c /etc/odoo/odoo.conf -d keit --no-http
```

**C. Install localization + modules (NO demo data):**
```bash
for m in l10n_bg stock purchase sale_management mrp \
         account_financial_report account_reconcile_oca \
         account_statement_import_camt account_banking_sepa_credit_transfer \
         account_asset_management stock_account_valuation_report \
         stock_quantity_history_location; do
  make update MODULE=$m DB=keit
done
```

**D. Confirm `list_db = False` and `dbfilter = ^keit$` in `odoo.conf`, then:**
```bash
make restart
```

---

## 8. Configure the company + users

Browse to `https://odoo.keit.bg` — it goes straight to the `keit` login
(no DB picker, thanks to `dbfilter`). Log in as **`admin`** / the password
from step 7B.

1. Settings → Companies → set KEIT name, **VAT number**, address, logo,
   bank account / IBAN, currency EUR
2. Settings → Users & Companies → Users → **New** for each real person:
   - Email, Name, **Language = English**
   - Access Rights tab → assign role (role matrix in `guides/ADMIN_GUIDE.md`)
3. Keep the `admin` account as a break-glass superuser (or rename it), but
   give real people their own named accounts — never share `admin`

---

## 9. Load real KEIT data

Separate phase — import customers, vendors, products, opening balances
from their current system (CSV import or scripted). Out of scope for this
runbook; see the migration plan.

---

## 10. Backups (CRITICAL — do before go-live)

Create `/opt/keit-odoo/backup.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
cd /opt/keit-odoo
STAMP=$(date +%F_%H%M)
DEST=/var/backups/odoo
mkdir -p "$DEST"

# Database
docker compose exec -T db pg_dump -U odoo -Fc keit > "$DEST/keit-$STAMP.dump"

# Filestore (attachments, generated PDFs)
docker run --rm -v keit_odoo-data:/data -v "$DEST":/backup alpine \
  tar czf "/backup/filestore-$STAMP.tgz" -C /data .

# Retain 14 days
find "$DEST" -type f -mtime +14 -delete

# Off-VM copy (configure rclone to KEIT's storage / S3 / OneDrive)
# rclone copy "$DEST" keit-remote:odoo-backups/
```
```bash
chmod +x backup.sh
# Daily at 02:30
(crontab -l 2>/dev/null; echo "30 2 * * * /opt/keit-odoo/backup.sh") | crontab -
```

**Test a restore monthly** (on a scratch VM/DB):
```bash
docker compose exec -T db createdb -U odoo keit_restore_test
docker compose exec -T db pg_restore -U odoo -d keit_restore_test < keit-<stamp>.dump
```
An untested backup is not a backup.

---

## 11. Self-heal — how the layers work

| Layer | Mechanism | Recovers from |
|---|---|---|
| systemd | `systemctl enable docker` | VM reboot (daemon + all containers come back) |
| Docker restart policy | `restart: unless-stopped` (all services) | container crash, OOM-kill |
| autoheal | watches `autoheal=true` labels | container running but **unhealthy** (hung process) |
| **external monitor** | uptime check on `/web/health` from off-VM | VM dead, daemon wedged, disk full |

If the **autoheal** container itself dies, Docker restarts it
(`restart: unless-stopped`); and even if it stayed down, core crash/reboot
recovery still works via the Docker restart policy. autoheal is a bonus
layer, not a single point of failure.

**The non-negotiable backstop** is the external monitor — no in-VM
watchdog can recover the VM being down. Set up one of:
- UptimeRobot / Healthchecks.io (free) hitting `https://odoo.keit.bg/web/health`
- or KEIT's own monitoring

Alert target: email/SMS to whoever is on call.

---

## 12. Firewall

```bash
# Allow only what's needed
sudo ufw allow 443/tcp     # HTTPS (Caddy)
sudo ufw allow 80/tcp      # HTTP (Caddy redirect + ACME)
sudo ufw allow 22/tcp      # SSH (restrict source IP if possible)
sudo ufw enable
```
PostgreSQL (5432) is **not** published to the host — keep it that way.
Odoo's 8069/8072 are only reachable via Caddy after step 5.

If internet-facing, add: 2FA on admin accounts (Settings → Users), and
consider Cloudflare Tunnel or a VPN instead of direct exposure.

---

## 13. Upgrades & maintenance

- **Odoo patch / minor update:** `docker compose pull odoo && make up`
  (test on a copy of the DB first)
- **OCA module updates:** `make oca && make restart`
- **OS / Docker:** standard `apt upgrade` + reboot (containers auto-return)
- Watch logs: `make logs`; watch disk: `df -h`

---

## Go-live checklist

- [ ] DNS A record live, HTTPS cert valid on `odoo.keit.bg`
- [ ] `.env` has strong secrets (no defaults)
- [ ] `odoo.conf`: `list_db=False`, `dbfilter=^keit$`, `proxy_mode=True`, strong `admin_passwd`
- [ ] `keit` DB created clean (no demo data), modules installed
- [ ] Company configured (VAT, logo, bank, IBAN)
- [ ] Real users created, initial passwords changed, English language
- [ ] Real data loaded + verified
- [ ] `systemctl enable docker` done
- [ ] Backup cron running + one restore tested
- [ ] External uptime monitor on `/web/health` with alerting
- [ ] Firewall enabled, Postgres not exposed
- [ ] Invoice PDF reviewed for Bulgarian legal compliance
