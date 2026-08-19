# Portofolio Noval Rizki

Situs statis untuk **Noval Rizki**  
Domain: **https://siswa.pallrzki.my.id**  
VPS: **69.33.213.153**

Alur: **GitHub → `git clone` di VPS → `git pull` (manual atau Actions) → Nginx + SSL**.

---

## 1. DNS

| Tipe | Nama | Nilai |
|------|------|--------|
| A | `siswa` | `69.33.213.153` |

Cek: `dig +short siswa.pallrzki.my.id`

---

## 2. Setup sekali di VPS — git clone + SSL

```bash
ssh root@69.33.213.153

export CERTBOT_EMAIL=email-anda@contoh.com
# opsional: BRANCH=main  REPO_URL=https://github.com/valngawi-droid/porto.git
curl -fsSL https://raw.githubusercontent.com/valngawi-droid/porto/main/deploy/setup-vps.sh | bash
```

Atau clone sendiri dulu, lalu jalankan skrip dari dalam repo:

```bash
git clone --branch main https://github.com/valngawi-droid/porto.git /var/www/porto
sudo CERTBOT_EMAIL=email-anda@contoh.com bash /var/www/porto/deploy/setup-vps.sh
```

Yang terjadi:

1. `git clone` repo ke **`/var/www/porto`** (itu juga document root Nginx)
2. Install Nginx + Certbot, pasang HTTPS Let’s Encrypt
3. Blokir akses publik ke `.git` dan `/deploy`
4. Generate kunci SSH untuk GitHub Actions

---

## 3. Update situs (git pull)

Di VPS, kapan saja:

```bash
sudo bash /var/www/porto/deploy/update.sh
# sama dengan:
# git -C /var/www/porto pull --ff-only origin main
# sudo nginx -t && sudo systemctl reload nginx
```

---

## 4. Otomatis dari GitHub (opsional)

Secrets: `VPS_HOST`, `VPS_USER`, `VPS_PORT`, `VPS_SSH_KEY`  
(private key dari `/root/.ssh/github_actions`)

```bash
mkdir -p .github/workflows
cp deploy/github-deploy.yml .github/workflows/deploy.yml
git add .github/workflows/deploy.yml
git commit -m "Enable git-pull deploy"
git push origin main
```

Push ke `main` → Actions SSH → `git pull` di `/var/www/porto`.

---

## File

| Path | Fungsi |
|------|--------|
| `deploy/setup-vps.sh` | Clone + Nginx + SSL |
| `deploy/update.sh` | `git pull` + reload Nginx |
| `deploy/nginx.conf` | HTTPS |
| `deploy/github-deploy.yml` | Template Actions |
