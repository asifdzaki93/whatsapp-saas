# Dokumentasi Instalasi Server Whaticket

## **1. Persiapan Server**

Pastikan Anda memiliki server dengan **Ubuntu 20.04 atau lebih baru**.

### **1.1 Update dan Install Paket Dasar**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl nano git unzip -y
```

### **1.2 Install Node.js dan NPM**

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt install -y nodejs
```

Cek versi:

```bash
node -v
npm -v
```

---

## **2. Instalasi Database PostgreSQL**

### **2.1 Install PostgreSQL**

```bash
sudo apt install postgresql postgresql-contrib -y
```

### **2.2 Konfigurasi Database**

Masuk ke PostgreSQL:

```bash
sudo -u postgres psql
```

Buat database untuk Whaticket:

```sql
CREATE DATABASE whaticket;
CREATE USER postgres WITH ENCRYPTED PASSWORD 'postgres';
ALTER ROLE postgres SET client_encoding TO 'utf8';
ALTER ROLE postgres SET default_transaction_isolation TO 'read committed';
ALTER ROLE postgres SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE whaticket TO postgres;
\q
```

---

## **3. Instalasi Redis**

```bash
sudo apt install redis -y
sudo systemctl enable redis --now
```

Cek apakah Redis berjalan:

```bash
redis-cli ping
```

Jika hasilnya `PONG`, Redis sudah aktif.

---

## **4. Instalasi Whaticket**

### **4.1 Clone Repository**

```bash
git clone https://github.com/canove/whaticket.git
cd whaticket
```

### **4.2 Konfigurasi Backend**

```bash
cd backend
cp .env.example .env
nano .env
```

Ubah konfigurasi:

```env
NODE_ENV=production
BACKEND_URL=https://api.example.com
FRONTEND_URL=https://app.example.com
DB_DIALECT=postgres
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASS=postgres
DB_NAME=whaticket
REDIS_URI=redis://127.0.0.1:6379
PORT=9003
```

Simpan lalu install dependensi:

```bash
npm install
```

Jalankan migrasi database:

```bash
npm run build
npm run sequelize db:migrate
```

Jalankan backend:

```bash
npm start
```

### **4.3 Konfigurasi Frontend**

```bash
cd ../frontend
cp .env.example .env
nano .env
```

Ubah konfigurasi:

```env
REACT_APP_BACKEND_URL=https://api.example.com
```

Install dependensi:

```bash
npm install
```

Build frontend:

```bash
npm run build
```

---

## **5. Instalasi Nginx dan SSL**

### **5.1 Install Nginx**

```bash
sudo apt install nginx -y
sudo systemctl enable nginx --now
```

### **5.2 Konfigurasi Nginx**

Buat file konfigurasi untuk backend:

```bash
sudo nano /etc/nginx/sites-available/api.example.com
```

Tambahkan:

```nginx
server {
    listen 80;
    server_name api.example.com;
    location / {
        proxy_pass http://localhost:9003;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Simpan dan aktifkan konfigurasi:

```bash
sudo ln -s /etc/nginx/sites-available/api.example.com /etc/nginx/sites-enabled/
```

Buat file konfigurasi untuk frontend:

```bash
sudo nano /etc/nginx/sites-available/app.example.com
```

Tambahkan:

```nginx
server {
    listen 80;
    server_name app.example.com;
    root /path/to/whaticket/frontend/build;
    index index.html;
    location / {
        try_files $uri /index.html;
    }
}
```

Simpan dan aktifkan konfigurasi:

```bash
sudo ln -s /etc/nginx/sites-available/app.example.com /etc/nginx/sites-enabled/
```

Restart Nginx:

```bash
sudo nginx -t
sudo systemctl restart nginx
```

### **5.3 Install SSL Let's Encrypt**

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d api.example.com -d app.example.com
```

Ikuti instruksi dan pilih redirect otomatis.

---

## **6. Menjalankan Whaticket sebagai Service**

Buat service systemd untuk backend:

```bash
sudo nano /etc/systemd/system/whaticket-backend.service
```

Tambahkan:

```ini
[Unit]
Description=Whaticket Backend
After=network.target

[Service]
User=root
WorkingDirectory=/root/whaticket/backend
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
```

Jalankan:

```bash
sudo systemctl enable whaticket-backend --now
```

Buat service systemd untuk frontend:

```bash
sudo nano /etc/systemd/system/whaticket-frontend.service
```

Tambahkan:

```ini
[Unit]
Description=Whaticket Frontend
After=network.target

[Service]
User=root
WorkingDirectory=/root/whaticket/frontend
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
```

Jalankan:

```bash
sudo systemctl enable whaticket-frontend --now
```

---

## **7. Testing dan Akses Whaticket**

Cek status layanan:

```bash
sudo systemctl status whaticket-backend
sudo systemctl status whaticket-frontend
```

Jika berjalan, buka browser dan akses:

```
https://api.example.com  (Backend API)
https://app.example.com  (Frontend Web)
```

---

## **8. Troubleshooting**

-   Cek log backend:
    ```bash
    journalctl -u whaticket-backend -f
    ```
-   Cek log frontend:
    ```bash
    journalctl -u whaticket-frontend -f
    ```
-   Jika Nginx bermasalah:
    ```bash
    sudo nginx -t
    sudo systemctl restart nginx
    ```
-   Jika SSL tidak bekerja:
    ```bash
    sudo certbot renew --dry-run
    ```

---

Sekarang Whaticket sudah siap digunakan! 🚀
