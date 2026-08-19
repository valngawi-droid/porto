# Portofolio Noval Rizki

Situs portofolio statis untuk **Noval Rizki**, ditujukan untuk domain **siswa.pallrzki.my.id** di VPS `69.33.213.153`.

## Isi

- `index.html` — halaman utama
- `styles.css` — gaya visual
- `nginx.conf` — contoh virtual host Nginx

## Deploy cepat di VPS

```bash
sudo mkdir -p /var/www/porto
sudo cp index.html styles.css /var/www/porto/
sudo cp nginx.conf /etc/nginx/sites-available/siswa.pallrzki.my.id
sudo ln -sf /etc/nginx/sites-available/siswa.pallrzki.my.id /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

Arahkan A record domain `siswa.pallrzki.my.id` ke `69.33.213.153`.
