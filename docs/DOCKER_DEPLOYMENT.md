# 🐳 Docker Deployment Guide

## Hızlı Başlangıç

### 1. Geliştirme Ortamı (Sadece Database)

Sadece PostgreSQL ve Redis'i Docker'da çalıştırıp, backend'i local'de geliştirmek için:

```bash
# Makefile ile
make docker-dev

# Veya docker-compose ile
docker-compose -f docker-compose.dev.yml up -d

# Veya script ile
./docker-deploy.sh dev
```

Bu komut şunları başlatır:

- PostgreSQL (port 5432)
- Redis (port 6379)
- Adminer - Database GUI (http://localhost:8080)

Ardından backend'i manuel başlatın:

```bash
cd backend
npm run start:dev
```

### 2. Production Deployment (Tüm Servisler)

Tüm servisleri Docker'da çalıştırmak için:

```bash
# Önce .env dosyasını oluşturun
cp .env.docker .env
# .env dosyasını düzenleyip güvenlik ayarlarını yapın!

# Servisleri başlatın
make docker-up

# Veya
./docker-deploy.sh start

# Veya
docker-compose up -d
```

Bu komut şunları başlatır:

- PostgreSQL
- Redis
- Backend API (http://localhost:3000)
- Admin Panel (http://localhost:5173)

## Kullanılabilir Komutlar

### Makefile Komutları

```bash
make docker-up       # Tüm servisleri başlat
make docker-down     # Servisleri durdur
make docker-dev      # Sadece DB servisleri (geliştirme)
make docker-build    # Image'ları yeniden build et
make docker-restart  # Servisleri yeniden başlat
make docker-logs     # Logları göster
make docker-migrate  # Database migration'ları çalıştır
make docker-seed     # Database'i seed et
make docker-clean    # Volume'ları temizle
```

### Docker Deploy Script

```bash
./docker-deploy.sh start    # Servisleri başlat
./docker-deploy.sh stop     # Servisleri durdur
./docker-deploy.sh restart  # Yeniden başlat
./docker-deploy.sh logs     # Logları göster
./docker-deploy.sh migrate  # Migration çalıştır
./docker-deploy.sh seed     # Database seed et
./docker-deploy.sh dev      # Sadece DB (geliştirme)
```

### Docker Compose Komutları

```bash
# Servisleri başlat
docker-compose up -d

# Servisleri durdur
docker-compose down

# Logları göster
docker-compose logs -f

# Belirli bir servisin loglarını göster
docker-compose logs -f backend

# Servis durumlarını kontrol et
docker-compose ps

# Image'ları yeniden build et
docker-compose build

# Volume'ları da sil
docker-compose down -v
```

## Servis Adresleri

| Servis      | URL                       | Açıklama                  |
| ----------- | ------------------------- | ------------------------- |
| Backend API | http://localhost:3000     | NestJS REST API           |
| API Docs    | http://localhost:3000/api | Swagger Documentation     |
| Admin Panel | http://localhost:5173     | React Admin Dashboard     |
| Adminer     | http://localhost:8080     | Database GUI (sadece dev) |
| PostgreSQL  | localhost:5432            | Database                  |
| Redis       | localhost:6379            | Cache                     |

## Environment Variables

`.env` dosyasını `.env.docker`'dan kopyalayıp düzenleyin:

```bash
cp .env.docker .env
```

Önemli değişkenler:

- `POSTGRES_PASSWORD`: Database şifresi
- `JWT_SECRET`: JWT için güvenli bir secret key
- `SMS_PROVIDER`: SMS sağlayıcı (mock, twilio, netgsm)
- `WHATSAPP_PROVIDER`: WhatsApp sağlayıcı (mock, twilio, meta)

## Database İşlemleri

### Migration Çalıştırma

```bash
# Makefile ile
make docker-migrate

# Veya script ile
./docker-deploy.sh migrate

# Veya manuel
docker-compose exec backend npx prisma migrate deploy
```

### Database Seed

```bash
# Makefile ile
make docker-seed

# Veya script ile
./docker-deploy.sh seed

# Veya manuel
docker-compose exec backend npx prisma db seed
```

### Prisma Studio

```bash
docker-compose exec backend npx prisma studio
```

## Troubleshooting

### Port Çakışması

Eğer portlar kullanımdaysa, `.env` dosyasında portları değiştirin:

```env
POSTGRES_PORT=5433
REDIS_PORT=6380
BACKEND_PORT=3001
ADMIN_PORT=5174
```

### Container'ları Yeniden Başlatma

```bash
docker-compose restart
```

### Logları Kontrol Etme

```bash
# Tüm loglar
docker-compose logs -f

# Sadece backend
docker-compose logs -f backend

# Sadece son 100 satır
docker-compose logs --tail=100 backend
```

### Temiz Başlangıç

```bash
# Tüm container'ları ve volume'ları sil
docker-compose down -v

# Image'ları yeniden build et
docker-compose build --no-cache

# Yeniden başlat
docker-compose up -d
```

### Container İçine Girme

```bash
# Backend container'ına gir
docker-compose exec backend sh

# PostgreSQL'e bağlan
docker-compose exec postgres psql -U benimsehrim -d benimsehrim
```

## Production Deployment

Production'da deploy ederken:

1. **Güvenlik:**

   - `JWT_SECRET` değiştirin
   - `POSTGRES_PASSWORD` güçlü bir şifre yapın
   - CORS ayarlarını production domain'e göre yapın

2. **SSL/TLS:**

   - Nginx veya Traefik ile reverse proxy kullanın
   - Let's Encrypt ile SSL sertifikası alın

3. **Monitoring:**

   - Docker logs'u merkezi bir log sistemine gönderin
   - Health check'leri kontrol edin

4. **Backup:**
   - PostgreSQL volume'unu düzenli yedekleyin
   - Redis persistence ayarlarını yapın

## Docker Compose Dosyaları

- `docker-compose.yml`: Production deployment
- `docker-compose.dev.yml`: Sadece database servisleri (geliştirme)

## Yardım

Daha fazla bilgi için:

```bash
make help
./docker-deploy.sh
```
