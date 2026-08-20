#!/usr/bin/env bash
# Auto SSL Let's Encrypt — tanpa email
# Domain tetap: siswa.pallrzki.my.id
#   sudo bash /var/www/porto/deploy/ssl.sh
set -euo pipefail

DOMAIN="siswa.pallrzki.my.id"
SITE_ROOT="/var/www/porto"
WEBROOT="/var/www/certbot"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Jalankan sebagai root (sudo)." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx certbot python3-certbot-nginx

mkdir -p "$WEBROOT" /etc/letsencrypt/renewal-hooks/deploy

# HTTP harus hidup supaya ACME webroot jalan
if [[ -f "$SCRIPT_DIR/nginx.bootstrap.conf" ]]; then
  cp "$SCRIPT_DIR/nginx.bootstrap.conf" /etc/nginx/sites-available/"$DOMAIN"
  ln -sfn /etc/nginx/sites-available/"$DOMAIN" /etc/nginx/sites-enabled/"$DOMAIN"
  rm -f /etc/nginx/sites-enabled/default
fi
nginx -t
systemctl enable --now nginx
systemctl reload nginx

certbot certonly \
  --webroot -w "$WEBROOT" \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  --register-unsafely-without-email \
  --keep-until-expiring \
  --preferred-challenges http

if [[ ! -f /etc/letsencrypt/options-ssl-nginx.conf ]]; then
  curl -fsSL -o /etc/letsencrypt/options-ssl-nginx.conf \
    https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
fi
if [[ ! -f /etc/letsencrypt/ssl-dhparams.pem ]]; then
  openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
fi

cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/sites-available/"$DOMAIN"
nginx -t
systemctl reload nginx

cat >/etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh <<'HOOK'
#!/usr/bin/env bash
systemctl reload nginx
HOOK
chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh

systemctl enable --now certbot.timer 2>/dev/null || true
# fallback cron jika timer tidak ada
if ! systemctl is-enabled certbot.timer >/dev/null 2>&1; then
  echo "0 3 * * * root certbot renew --quiet --deploy-hook 'systemctl reload nginx'" \
    >/etc/cron.d/certbot-renew-siswa
fi

echo "SSL aktif: https://${DOMAIN}"
certbot certificates || true
