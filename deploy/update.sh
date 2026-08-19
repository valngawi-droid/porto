#!/usr/bin/env bash
# Di VPS: sudo bash /var/www/porto/deploy/update.sh
set -euo pipefail
SITE_ROOT="${SITE_ROOT:-/var/www/porto}"
BRANCH="${BRANCH:-main}"

git -C "$SITE_ROOT" fetch origin
git -C "$SITE_ROOT" checkout "$BRANCH"
git -C "$SITE_ROOT" pull --ff-only origin "$BRANCH"
nginx -t && systemctl reload nginx
echo "Updated $(git -C "$SITE_ROOT" rev-parse --short HEAD)"
