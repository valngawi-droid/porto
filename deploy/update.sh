#!/usr/bin/env bash
# Di VPS: sudo bash /var/www/porto/deploy/update.sh
set -euo pipefail
SITE_ROOT="${SITE_ROOT:-/var/www/porto}"
BRANCH="${BRANCH:-main}"

git -C "$SITE_ROOT" fetch origin
git -C "$SITE_ROOT" checkout "$BRANCH"
git -C "$SITE_ROOT" pull --ff-only origin "$BRANCH"
cp "$SITE_ROOT/deploy/porto-chat.service" /etc/systemd/system/porto-chat.service
systemctl daemon-reload
systemctl restart porto-chat
nginx -t && systemctl reload nginx
echo "Updated $(git -C "$SITE_ROOT" rev-parse --short HEAD)"
