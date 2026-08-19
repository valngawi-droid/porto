# Portofolio Noval Rizki

Situs statis untuk **Noval Rizki**  
Domain: **https://siswa.pallrzki.my.id**  
VPS: **69.33.213.153**

Alur: **GitHub → GitHub Actions (rsync) → Nginx di VPS → SSL Let’s Encrypt**.

---

## 1. DNS

Di penyedia domain `pallrzki.my.id`, buat record:

| Tipe | Nama | Nilai |
|------|------|--------|
| A | `siswa` | `69.33.213.153` |

Tunggu sampai `dig +short siswa.pallrzki.my.id` mengembalikan IP itu.

---

## 2. Setup sekali di VPS (SSL + Nginx + kunci deploy)

SSH ke VPS, lalu:

```bash
ssh root@69.33.213.153
# atau user sudo Anda

export CERTBOT_EMAIL=email-anda@contoh.com
curl -fsSL https://raw.githubusercontent.com/valngawi-droid/porto/main/deploy/setup-vps.sh | bash
```

Kalau repo belum di `main`, clone dulu branch kerja lalu:

```bash
sudo CERTBOT_EMAIL=email-anda@contoh.com bash deploy/setup-vps.sh
```

Skrip ini akan:

1. Install `git`, `nginx`, `certbot`, `rsync`, `ufw`
2. Clone repo ke `/opt/porto` dan salin file ke `/var/www/porto`
3. Pasang Nginx HTTP, lalu **Certbot** untuk HTTPS
4. Redirect HTTP → HTTPS
5. Generate kunci SSH deploy dan menaruh public key di `authorized_keys`

Setelah selesai, buka **https://siswa.pallrzki.my.id**.

---

## 3. Hubungkan GitHub → VPS

Di GitHub: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Isi |
|--------|-----|
| `VPS_HOST` | `69.33.213.153` |
| `VPS_USER` | `root` (atau user deploy) |
| `VPS_PORT` | `22` (opsional) |
| `VPS_SSH_KEY` | **private key** yang dicetak skrip (`/root/.ssh/github_deploy`) |

Workflow: `.github/workflows/deploy.yml`  
Setiap **push ke `main`** akan `rsync` file statis ke `/var/www/porto/` lalu reload Nginx.

---

## 4. Rilis berikutnya

```bash
git add -A
git commit -m "Update portfolio"
git push origin main
```

Cek tab **Actions** di GitHub sampai job hijau. Situs langsung terbarui.

---

## 5. File penting

| Path | Fungsi |
|------|--------|
| `index.html` `styles.css` `app.js` | Situs |
| `deploy/setup-vps.sh` | Bootstrap VPS + SSL |
| `deploy/nginx.bootstrap.conf` | Nginx sebelum sertifikat |
| `deploy/nginx.conf` | Nginx HTTPS |
| `.github/workflows/deploy.yml` | CI/CD |

Sertifikat diperpanjang otomatis oleh `certbot.timer`.
