#!/usr/bin/env bash
# Clone (or refresh) OCA repos at branch 18.0 into ./addons/.
# Idempotent: re-running fetches updates, doesn't reclone.
# Failures are logged to setup-oca.failures.log; script exits non-zero if any.

set -u  # not -e — we handle per-repo failure ourselves

BRANCH="${OCA_BRANCH:-18.0}"
ADDONS_DIR="$(cd "$(dirname "$0")" && pwd)/addons"
FAILLOG="$(cd "$(dirname "$0")" && pwd)/setup-oca.failures.log"
mkdir -p "$ADDONS_DIR"
: > "$FAILLOG"

# Repos scoped to: Accounting + Inventory + Sales + Purchase + plumbing.
# Browse-only repos (sale-workflow, purchase-workflow) are cloned so the user
# can inspect modules; the user installs nothing in bulk.
REPOS=(
  account-financial-reporting
  account-reconcile
  account-financial-tools
  account-payment
  bank-statement-import
  bank-payment
  reporting-engine
  stock-logistics-reporting
  stock-logistics-warehouse
  sale-workflow
  purchase-workflow
  l10n-bulgaria
  queue
  server-tools
  server-ux
  web
)

ok=0
fail=0
total=${#REPOS[@]}
i=0

for repo in "${REPOS[@]}"; do
  i=$((i+1))
  dest="$ADDONS_DIR/$repo"
  printf "[%2d/%d] %s ... " "$i" "$total" "$repo"

  if [ -d "$dest/.git" ]; then
    if git -C "$dest" fetch --depth 1 origin "$BRANCH" >/dev/null 2>&1 \
       && git -C "$dest" reset --hard "origin/$BRANCH" >/dev/null 2>&1; then
      echo "updated"
      ok=$((ok+1))
    else
      echo "FETCH FAILED"
      echo "$repo: fetch/reset failed on branch $BRANCH" >> "$FAILLOG"
      fail=$((fail+1))
    fi
  else
    if git clone --depth 1 -b "$BRANCH" \
         "https://github.com/OCA/$repo.git" "$dest" >/dev/null 2>&1; then
      echo "cloned"
      ok=$((ok+1))
    else
      echo "CLONE FAILED (branch $BRANCH may not exist)"
      echo "$repo: clone failed (branch $BRANCH)" >> "$FAILLOG"
      fail=$((fail+1))
    fi
  fi
done

echo
echo "================================================================"
echo "OCA setup: $ok ok, $fail failed (out of $total)"
mod_count=$(find "$ADDONS_DIR" -maxdepth 3 -name __manifest__.py 2>/dev/null | wc -l | tr -d ' ')
echo "Module manifests under ./addons: $mod_count"
if [ "$fail" -gt 0 ]; then
  echo "Failures logged to: $FAILLOG"
  cat "$FAILLOG"
  exit 1
fi
exit 0
