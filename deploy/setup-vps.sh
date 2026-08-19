#!/usr/bin/env bash
# Jalankan SEKALI di VPS sebagai root:
#   curl -fsSL https://raw.githubusercontent.com/valngawi-droid/porto/main/deploy/setup-vps.sh | bash
# atau setelah git clone:
#   sudo bash deploy/setup-vps.sh
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/valngawi-droid/porto.git}"
BRANCH="${BRANCH:-main}"
DOMAIN="${DOMAIN:-siswa.pallrzki.my.id}"
SITE_ROOT="/var/www/porto"
CERT_ROOT="/var/www/certbot"
APP_DIR="/opt/porto"
EMAIL="${CERTBOT_EMAIL:-admin@${DOMAIN}}"

export DEBIAN_FRONTEND=noninteractive

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Jalankan sebagai root (sudo)." >&2
  exit 1
fi

apt-get update -y
apt-get install -y git nginx certbot python3-certbot-nginx rsync ufw

mkdir -p "$SITE_ROOT" "$CERT_ROOT" "$APP_DIR"

if [[ -d "$APP_DIR/.git" ]]; then
  git -C "$APP_DIR" fetch origin
  git -C "$APP_DIR" checkout "$BRANCH"
  git -C "$APP_DIR" pull --ff-only origin "$BRANCH"
else
  git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
fi

rsync -a --delete \
  --exclude '.git' \
  --exclude '.github' \
  --exclude 'deploy' \
  --exclude 'README.md' \
  "$APP_DIR/" "$SITE_ROOT/"

# Bootstrap HTTP dulu supaya ACME bisa jalan
cp "$APP_DIR/deploy/nginx.bootstrap.conf" /etc/nginx/sites-available/"$DOMAIN"
ln -sfn /etc/nginx/sites-available/"$DOMAIN" /etc/nginx/sites-enabled/"$DOMAIN"
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx

ufw allow OpenSSH || true
ufw allow 'Nginx Full' || true
ufw --force enable || true

if [[ ! -d "/etc/letsencrypt/live/${DOMAIN}" ]]; then
  certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect || {
    echo "Certbot gagal. Cek DNS A ${DOMAIN} -> IP VPS, port 80 terbuka, lalu jalankan ulang." >&2
    exit 1
  }
fi

# Pasang config HTTPS penuh (setelah cert ada)
if [[ -f /etc/letsencrypt/options-ssl-nginx.conf ]]; then
  cp "$APP_DIR/deploy/nginx.conf" /etc/nginx/sites-available/"$DOMAIN"
  nginx -t && systemctl reload nginx
fi

# Timer perpanjang sertifikat (bawaan certbot sudah ada; pastikan aktif)
systemctl enable --now certbot.timer 2>/dev/null || true

# Deploy key hint
if [[ ! -f /root/.ssh/github_deploy ]]; then
  ssh-keygen -t ed25519 -N "" -f /root/.ssh/github_deploy -C "porto-github-actions"
  echo
  echo "===== TAMBAHKAN PRIVATE KEY INI KE GITHUB SECRET: VPS_SSH_KEY ====="
  cat /root/.ssh/github_deploy
  echo "===== TAMBAHKAN PUBLIC KEY INI KE /root/.ssh/authorized_keys (sudah otomatis) ====="
  cat /root/.ssh/github_deploy.pub >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  echo
fi

echo "Selesai. Kunjungi https://${DOMAIN}"
