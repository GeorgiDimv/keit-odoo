# Odoo 18 + OCA local dev stack. Use `make help` to list targets.

SHELL := /bin/bash
COMPOSE := docker compose

# Load .env if it exists, so $$POSTGRES_USER etc. work in recipes.
ifneq (,$(wildcard ./.env))
  include .env
  export
endif

DB ?= postgres
MODULE ?=

.PHONY: help oca up down restart logs psql shell stats clean update odoo-shell

help:
	@echo "Targets:"
	@echo "  make oca                       - clone/update OCA repos under ./addons"
	@echo "  make up                        - start db + odoo containers"
	@echo "  make down                      - stop containers (keep volumes)"
	@echo "  make restart                   - restart odoo container only"
	@echo "  make logs                      - tail odoo logs (Ctrl-C to exit)"
	@echo "  make psql [DB=test_acc]        - psql into a database"
	@echo "  make shell                     - bash inside odoo container"
	@echo "  make odoo-shell DB=test_acc    - Odoo Python shell against a DB"
	@echo "  make update MODULE=x DB=test_acc - upgrade/install module x"
	@echo "  make stats                     - docker stats snapshot"
	@echo "  make clean                     - DESTRUCTIVE: down + remove volumes"

oca:
	bash ./setup-oca.sh

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart odoo

logs:
	$(COMPOSE) logs -f --tail=200 odoo

psql:
	$(COMPOSE) exec db psql -U $${POSTGRES_USER} -d $(DB)

shell:
	$(COMPOSE) exec odoo bash

odoo-shell:
	@if [ -z "$(DB)" ] || [ "$(DB)" = "postgres" ]; then \
	  echo "set DB=<dbname>, e.g. make odoo-shell DB=test_acc"; exit 1; fi
	$(COMPOSE) exec odoo odoo shell -c /etc/odoo/odoo.conf -d $(DB) --no-http

update:
	@if [ -z "$(MODULE)" ]; then \
	  echo "set MODULE=<name>, e.g. make update MODULE=l10n_bg DB=test_acc"; exit 1; fi
	@if [ -z "$(DB)" ] || [ "$(DB)" = "postgres" ]; then \
	  echo "set DB=<dbname>, e.g. make update MODULE=l10n_bg DB=test_acc"; exit 1; fi
	$(COMPOSE) exec odoo odoo -c /etc/odoo/odoo.conf -d $(DB) -i $(MODULE) -u $(MODULE) --no-http --stop-after-init

stats:
	docker stats --no-stream

clean:
	@read -p "This will remove all containers AND volumes (db data lost). Continue? [y/N] " ans; \
	if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then $(COMPOSE) down -v; else echo "aborted"; fi
