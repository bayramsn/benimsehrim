# 🏙️ Benim Şehrim

Şehrin Cebinde - Yerel süper uygulama platformu

[![Backend Build](https://img.shields.io/badge/Backend-✓%20Build%20Passed-green)]()
[![Admin Build](https://img.shields.io/badge/Admin-✓%20Build%20Passed-green)]()
[![License](https://img.shields.io/badge/License-Private-blue)]()

## 📱 Proje Hakkında

**Benim Şehrim**, şehirlerdeki yerel işletmeler, taksi servisleri ve kurye hizmetlerini tek bir platformda birleştiren modern bir süper uygulamadır. İlk olarak Kırşehir'de başlayıp Türkiye geneline yayılmayı hedeflemektedir.

### 🎯 Temel Özellikler

- 🛍️ **Yerel Alışveriş**: Kasaplar, manavlar, fırınlar ve diğer yerel mağazalardan sipariş
- 🚕 **Taksi**: Uber benzeri taksi çağırma sistemi
- 📦 **Kurye**: Yerel teslimat ve gönderi hizmeti
- 💬 **Canlı Sohbet**: Sipariş ve yolculuk sırasında anlık iletişim
- ⭐ **Değerlendirmeler**: Mağaza, şoför ve kuryeler için yorum sistemi
- 🎮 **Oyunlaştırma**: Puan, rozet ve seviye sistemi

## 🏗️ Proje Yapısı

```
benimsehrim/
├── backend/           # NestJS API Sunucusu
│   ├── src/
│   │   ├── common/    # Ortak modüller (Prisma, Redis, Email, Maps, SMS)
│   │   └── modules/   # İş modülleri (Auth, Orders, Taxi, Stores, vb.)
│   └── prisma/        # Veritabanı şeması
│
├── admin/             # React Admin Paneli
│   └── src/
│       ├── components/
│       └── pages/
│
├── mobile/            # Mobil Uygulamalar
│   ├── android/           # Müşteri Android (Kotlin/Compose)
│   ├── ios/               # Müşteri iOS (Swift/SwiftUI)
│   ├── vendor-android/    # Esnaf Android
│   └── driver-android/    # Şoför/Kurye Android
│
├── landing/           # Tanıtım Sayfası (HTML)
│
└── docs/              # Dokümantasyon
    ├── api/           # API dokümantasyonu
    ├── architecture/  # Mimari dokümantasyonu
    └── database/      # Veritabanı dokümantasyonu
```

## 🚀 Hızlı Başlangıç

### Gereksinimler

- Node.js 18+
- Docker & Docker Compose
- PostgreSQL 15+ (veya Docker)
- Redis (veya Docker)

### Kurulum

```bash
# 1. Repo'yu klonla
git clone <repo-url>
cd benimsehrim

# 2. Docker ile veritabanlarını başlat
docker-compose up -d

# 3. Backend'i kur ve başlat
cd backend
npm install
cp .env.development .env
npx prisma generate
npx prisma migrate dev
npm run start:dev

# 4. Admin paneli başlat (yeni terminal)
cd admin
npm install
npm run dev
```

### Erişim

- **Backend API**: http://localhost:3000
- **Swagger Docs**: http://localhost:3000/api
- **Admin Panel**: http://localhost:5173

## 🐳 Docker Deployment

### Geliştirme (Sadece Database)

Sadece PostgreSQL ve Redis'i Docker'da çalıştırıp, backend'i local'de geliştirmek için:

```bash
# Makefile ile
make docker-dev

# Veya docker-compose ile
docker-compose -f docker-compose.dev.yml up -d
```

Bu komut şunları başlatır:

- PostgreSQL (port 5432)
- Redis (port 6379)
- Adminer - Database GUI (http://localhost:8080)

### Production (Tüm Servisler)

Tüm servisleri Docker'da çalıştırmak için:

```bash
# 1. Environment dosyasını oluştur
cp .env.docker .env
# .env dosyasını düzenleyip güvenlik ayarlarını yap!

# 2. Servisleri başlat
make docker-up
# Veya: ./docker-deploy.sh start
# Veya: docker-compose up -d

# 3. Database migration ve seed
make docker-migrate
make docker-seed
```

**Detaylı bilgi için:** [docs/DOCKER_DEPLOYMENT.md](docs/DOCKER_DEPLOYMENT.md)

## 🆓 100% Ücretsiz Servisler

Bu proje **tamamen ücretsiz** servisler kullanır:

| Servis      | Provider                | Limit    |
| ----------- | ----------------------- | -------- |
| 🗺️ Harita   | OpenStreetMap/Nominatim | Sınırsız |
| 🗺️ Rota     | OpenRouteService        | 2000/gün |
| 📧 Email    | Mock (console log)      | -        |
| 📱 SMS      | Mock (demo mode)        | -        |
| 📂 Depolama | Local filesystem        | -        |
| 🔍 Arama    | PostgreSQL              | -        |

**Detaylar için:** [docs/FREE_API_SERVICES.md](docs/FREE_API_SERVICES.md)

## 📝 Environment Değişkenleri

```env
# Minimum çalışır yapılandırma
DATABASE_URL=postgresql://user:pass@localhost:5432/benimsehrim
REDIS_HOST=localhost
JWT_SECRET=your-secret-key
DEMO_MODE=true  # OTP 123456 her zaman geçerli
```

## 🧪 Test

```bash
# Backend testleri
cd backend
npm test

# E2E testleri
npm run test:e2e
```

## 📱 Mobil Geliştirme

### Android (Müşteri, Esnaf, Şoför)

```bash
cd mobile/android  # veya vendor-android, driver-android
./gradlew assembleDebug
```

### iOS (Müşteri)

```bash
cd mobile/ios/BenimSehrim
xcodebuild -workspace BenimSehrim.xcworkspace -scheme BenimSehrim
```

## 🛠️ Teknolojiler

### Backend

- **Framework**: NestJS (TypeScript)
- **Database**: PostgreSQL + Prisma ORM
- **Cache**: Redis
- **Auth**: JWT + OTP

### Frontend

- **Admin**: React + Vite + TailwindCSS
- **Android**: Kotlin + Jetpack Compose
- **iOS**: Swift + SwiftUI

### Harita

- **Backend**: Nominatim + OpenRouteService
- **Android**: OSMDroid (OpenStreetMap)
- **iOS**: MapKit (Apple Maps)
- **Web**: Leaflet.js

## 📂 Dokümantasyon

- [Sistem Mimarisi](docs/architecture/SYSTEM_ARCHITECTURE.md)
- [Veritabanı Şeması](docs/database/SCHEMA.md)
- [Auth API](docs/api/AUTH_API.md)
- [Ücretsiz Servisler](docs/FREE_API_SERVICES.md)
- [Ücretsiz Harita Kılavuzu](docs/FREE_MAPS_GUIDE.md)

## 📊 Proje Durumu

| Bileşen         | Durum         | Build     |
| --------------- | ------------- | --------- |
| Backend API     | ✅ Tamamlandı | ✅ Passed |
| Admin Panel     | ✅ Tamamlandı | ✅ Passed |
| Android Müşteri | ✅ Tamamlandı | 📱 Ready  |
| iOS Müşteri     | ✅ Tamamlandı | 📱 Ready  |
| Vendor Android  | ✅ Tamamlandı | 📱 Ready  |
| Driver Android  | ✅ Tamamlandı | 📱 Ready  |
| Landing Page    | ✅ Tamamlandı | ✅ Passed |

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'i push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

Bu proje özel lisanslıdır. İzinsiz kullanım yasaktır.

---

**Benim Şehrim** - Şehrin Cebinde 🏙️
