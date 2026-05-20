# Project context for Claude Code

This file is auto-loaded by Claude Code. It carries the context for
continuing this work on another machine.

## What this is

The Odoo 18 ERP deployment stack for **KEIT Ltd Bulgaria** — a Bulgarian
industrial company. Odoo 18 Community + OCA modules + Bulgarian accounting
localization, covering **Accounting, Inventory, Sales, Purchase,
Manufacturing**. Self-hosted on KEIT's own VM, single-tenant.

## Current status (as of last session)

- Demo was built, presented to KEIT, and **approved** — they want to proceed.
- This repo is the **deployment artifact** (the thing that gets deployed to
  KEIT's VM). It is NOT the demo database — the demo data (fake Festo/Bossard
  records) lived only on the original dev laptop and does not ship.
- Repo pushed to a private personal GitHub: `git@github.com:GeorgiDimv/keit-odoo.git`
- **Next step: deploy to KEIT's internal VM** following `DEPLOYMENT.md`.

## Key decisions already made

- **English UI**, but Bulgarian *accounting* localization (`l10n_bg`,
  `l10n_bg_ledger`) is kept — never uninstall it; VAT/legal compliance
  depends on it. (UI language != accounting localization.)
- **Internal-only deployment** — the VM is not internet-facing.
  - DNS: KEIT's IT adds an internal A record `odoo.keit.bg` → VM private IP
  - HTTPS: Caddy with `tls internal` (self-signed CA; can't use Let's Encrypt
    without public reachability). See `Caddyfile.example`.
- **Docker** deployment (not bare metal). Bare-metal was discussed; Docker
  chosen for reproducibility + easy patching/upgrades. Only fall back to
  bare-metal if KEIT IT policy forbids Docker.
- Production DB is a **clean `keit` database created on the VM** with NO demo
  data (`--without-demo=all`), then real data loaded. Exact commands are in
  `DEPLOYMENT.md` step 7 (verified working).
- Self-heal: healthchecks + `restart: unless-stopped` + `autoheal` watchdog,
  plus an external uptime monitor as the real backstop. See `DEPLOYMENT.md` §11.

## How to deploy (the short version)

1. On the VM: `git clone` this repo, `cp .env.example .env`, set real secrets
2. `make oca` (clones the 16 OCA module repos into `addons/`)
3. Harden `config/odoo.conf` (`list_db=False`, `dbfilter=^keit$`, `proxy_mode=True`)
4. Caddy reverse proxy (copy `Caddyfile.example` → `Caddyfile`, use `tls internal`)
5. `make up`
6. Create the clean `keit` DB + admin via CLI (DEPLOYMENT.md §7)
7. Configure company, create users, load real data

`DEPLOYMENT.md` is the authoritative top-to-bottom runbook. Follow it.

## Access constraint (important)

The original dev machine is a **SAP-managed laptop** where Cisco Umbrella
**blocks AnyDesk** and other remote-access tools, and breaks `gh`/curl for
personal GitHub (corp TLS inspection). Deployment work is being moved to a
**personal machine** to avoid fighting corporate controls. SSH to the VM is
the preferred access method — push KEIT to provide it.

## Hard rules

- **Never commit** `_internal/`, `.env`, or `addons/` (see `.gitignore`).
  `_internal/` (on the original laptop only) holds internal pricing/scoping
  and demo scripts — must never reach the customer or a public place.
- **Never uninstall** `l10n_bg` / `l10n_bg_ledger`.
- Keep the GitHub repo **private**.
- Install OCA modules one at a time; watch logs.
- Don't modify Odoo core; all customization via addon modules.

## Layout

- `docker-compose.yml` — odoo:18 + postgres:16 + autoheal
- `config/odoo.conf` — Odoo server config (harden for prod per DEPLOYMENT.md)
- `setup-oca.sh` — clones the 16 OCA repos into `addons/` (run via `make oca`)
- `Makefile` — all ops (`make help`)
- `Caddyfile.example` — HTTPS reverse proxy template
- `DEPLOYMENT.md` — production deployment runbook (the main doc to follow)
- `guides/` — end-user role guides (admin / inventory / production / accounting)

## Out of scope (separate engagements — disclose to KEIT)

Fiscal device (cash register) integration, payroll, direct NRA submission,
live banking API integrations. File-based CAMT bank import IS included.
