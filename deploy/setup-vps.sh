#!/usr/bin/env bash
# Jalankan SEKALI di VPS sebagai root (metode git clone):
#   curl -fsSL https://raw.githubusercontent.com/valngawi-droid/porto/main/deploy/setup-vps.sh | bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/valngawi-droid/porto.git}"
BRANCH="${BRANCH:-main}"
DOMAIN="${DOMAIN:-siswa.pallrzki.my.id}"
SITE_ROOT="/var/www/porto"
CERT_ROOT="/var/www/certbot"

export DEBIAN_FRONTEND=noninteractive

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Jalankan sebagai root (sudo)." >&2
  exit 1
fi

apt-get update -y
apt-get install -y git nginx certbot python3-certbot-nginx ufw

mkdir -p "$CERT_ROOT"

if [[ -d "$SITE_ROOT/.git" ]]; then
  git -C "$SITE_ROOT" remote set-url origin "$REPO_URL"
  git -C "$SITE_ROOT" fetch origin
  git -C "$SITE_ROOT" checkout "$BRANCH"
  git -C "$SITE_ROOT" pull --ff-only origin "$BRANCH"
else
  rm -rf "$SITE_ROOT"
  git clone --branch "$BRANCH" "$REPO_URL" "$SITE_ROOT"
fi

# Nginx root = hasil git clone
cp "$SITE_ROOT/deploy/nginx.bootstrap.conf" /etc/nginx/sites-available/"$DOMAIN"
ln -sfn /etc/nginx/sites-available/"$DOMAIN" /etc/nginx/sites-enabled/"$DOMAIN"
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx

ufw allow OpenSSH || true
ufw allow 'Nginx Full' || true
ufw --force enable || true

bash "$SITE_ROOT/deploy/ssl.sh"

cp "$SITE_ROOT/deploy/porto-chat.service" /etc/systemd/system/porto-chat.service
systemctl daemon-reload
systemctl enable --now porto-chat
systemctl restart porto-chat

if [[ ! -f /root/.ssh/github_actions ]]; then
  ssh-keygen -t ed25519 -N "" -f /root/.ssh/github_actions -C "porto-github-actions"
  cat /root/.ssh/github_actions.pub >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  echo
  echo "===== PRIVATE KEY → GitHub Secret VPS_SSH_KEY ====="
  cat /root/.ssh/github_actions
  echo "===================================================="
fi

echo
echo "Clone: $SITE_ROOT  (branch $BRANCH)"
echo "Update manual: git -C $SITE_ROOT pull --ff-only"
echo "Selesai. Kunjungi https://${DOMAIN}"
