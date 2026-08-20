# Portofolio Noval Rizki

- Domain: **siswa.pallrzki.my.id**
- VPS: **69.33.213.153**
- Metode: **git clone** + **Certbot SSL tanpa email**

---

## Step by step (ikuti urutan ini)

### Step 1 — Arahkan DNS

Di panel domain `pallrzki.my.id` buat:

| Tipe | Nama / host | Nilai |
|------|-------------|--------|
| A | `siswa` | `69.33.213.153` |

Tunggu 1–15 menit. Cek dari laptop:

```bash
dig +short siswa.pallrzki.my.id
```

Harus keluar: `69.33.213.153`

---

### Step 2 — Masuk ke VPS

```bash
ssh root@69.33.213.153
```

---

### Step 3 — Install git (kalau belum)

```bash
apt-get update -y
apt-get install -y git
```

---

### Step 4 — Git clone repo ke folder web

Branch kerja saat ini: `arena/01a01c6e-porto`  
(setelah di-merge, ganti `main`)

```bash
rm -rf /var/www/porto
git clone --branch arena/01a01c6e-porto \
  https://github.com/valngawi-droid/porto.git \
  /var/www/porto
```

Cek file:

```bash
ls /var/www/porto
# index.html  styles.css  app.js  deploy
```

---

### Step 5 — Pasang Nginx + auto SSL (tanpa email)

Satu perintah:

```bash
bash /var/www/porto/deploy/ssl.sh
```

Itu akan:

1. Install `nginx` + `certbot`
2. Serve situs di port 80
3. Ambil sertifikat Let’s Encrypt untuk **siswa.pallrzki.my.id** tanpa email
4. Aktifkan HTTPS dan redirect HTTP → HTTPS
5. Nyalakan perpanjangan otomatis (`certbot.timer`)

Kalau ingin clone + SSL sekaligus dari nol:

```bash
curl -fsSL https://raw.githubusercontent.com/valngawi-droid/porto/arena/01a01c6e-porto/deploy/setup-vps.sh | bash
```

---

### Step 6 — Cek hasil

Di VPS:

```bash
certbot certificates
systemctl status nginx --no-pager
systemctl status certbot.timer --no-pager
```

Di browser buka:

**https://siswa.pallrzki.my.id**

---

### Step 7 — Update situs berikutnya (git pull)

Setiap ada perubahan di GitHub:

```bash
ssh root@69.33.213.153
bash /var/www/porto/deploy/update.sh
```

Sama dengan:

```bash
git -C /var/www/porto pull --ff-only
nginx -t && systemctl reload nginx
```

---

### Step 8 (opsional) — Auto deploy dari GitHub

1. Di VPS, kalau setup-vps sudah dijalankan, private key ada di `/root/.ssh/github_actions`
2. GitHub → **Settings → Secrets and variables → Actions**:

| Secret | Isi |
|--------|-----|
| `VPS_HOST` | `69.33.213.153` |
| `VPS_USER` | `root` |
| `VPS_PORT` | `22` |
| `VPS_SSH_KEY` | isi file `/root/.ssh/github_actions` |

3. Di laptop / GitHub:

```bash
mkdir -p .github/workflows
cp deploy/github-deploy.yml .github/workflows/deploy.yml
git add .github/workflows/deploy.yml
git commit -m "Enable git-pull deploy"
git push
```

Push berikutnya ke branch yang di-clone di VPS → server `git pull` sendiri.

---

## File skrip

| File | Step |
|------|------|
| `deploy/ssl.sh` | Step 5 — Certbot no email, domain `siswa.pallrzki.my.id` |
| `deploy/setup-vps.sh` | Step 4+5 sekaligus |
| `deploy/update.sh` | Step 7 — git pull |
| `deploy/nginx.conf` | Config HTTPS |
| `deploy/nginx.bootstrap.conf` | Config HTTP sebelum sertifikat |
