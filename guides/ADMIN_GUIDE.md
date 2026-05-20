# KEIT Odoo — Administrator Guide

Audience: whoever administers the system day-to-day. Assumes the stack
is already running. UI is in English.

## Logging in

- URL: `http://localhost:8069` (will be `https://odoo.keit.bg` once deployed)
- Admin login: `omurtagjelev@gmail.com` (rename to a KEIT account before go-live)

## Switching / managing companies

- Top-right shows the active company.
- KEIT Ltd Bulgaria is the production company. "BG Company" is leftover
  demo data — archive it: **Settings → Companies → BG Company → Action → Archive**.
- To work across companies, tick multiple in the top-right switcher.

## Users & access rights

**Create a user:** Settings → Users & Companies → Users → New
- Set Email, Name
- **Access Rights tab** controls what they can do:
  - Accounting: Billing / Accountant / Adviser (increasing power)
  - Inventory: User / Administrator
  - Manufacturing: User / Administrator
  - Sales / Purchase: User: Own Documents / All Documents / Administrator
- Set their **Default Company** and allowed companies
- Set **Language = English**

**Suggested roles for KEIT:**
| Role | Accounting | Inventory | Manufacturing | Sales | Purchase |
|---|---|---|---|---|---|
| Accountant | Accountant | — | — | — | Bills |
| Warehouse | — | User | User | — | Receive |
| Production | — | User | Administrator | — | — |
| Sales | Billing | — | — | All Docs | — |
| Manager | Adviser | Admin | Admin | Admin | Admin |

## Company configuration

Settings → Companies → KEIT Ltd Bulgaria:
- **VAT number**, address, phone, email, website
- **Logo** (top-left of every document)
- **Bank Accounts** tab — add KEIT's IBAN(s) for invoice footers + SEPA
- Currency: EUR

## Installing / removing modules

- Apps menu → search → Activate (install) / dropdown → Uninstall
- **Never uninstall `l10n_bg` or `l10n_bg_ledger`** — they hold the BG
  chart of accounts and VAT compliance.
- Install OCA / extra modules one at a time, watch for errors.

## Backups (CRITICAL — set this up before go-live)

Current local stack stores everything in two Docker volumes
(`pgdata`, `odoo-data`). On the production VM:
- Daily `pg_dump` of the database
- Daily tar of the filestore (`/var/lib/odoo`)
- Copy both off the VM (another host / cloud bucket)
- **Test a restore monthly** — an untested backup is not a backup

(Detailed deploy + backup steps live in the production deployment plan.)

## Common operations (local stack via Makefile)

```
make up          # start
make down        # stop
make restart     # restart odoo only
make logs        # tail logs
make psql DB=test_acc      # SQL console
make stats       # RAM/CPU
```

## When something breaks

1. `make logs` — read the last ERROR/Traceback
2. `make restart` — fixes most transient issues
3. Check disk space (`df -h`) — Odoo halts when the DB volume fills
4. Don't `make clean` unless you intend to wipe everything (it deletes volumes)
