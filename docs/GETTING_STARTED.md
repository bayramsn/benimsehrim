# 🚀 Benim Şehrim - Başlangıç Kılavuzu

## Hızlı Başlangıç

### 1. Gereksinimler

- Node.js 18+
- PostgreSQL 14+
- Redis 6+
- npm veya yarn

### 2. Backend Kurulumu

```bash
cd backend

# Bağımlılıkları yükle
npm install

# Environment dosyasını oluştur
cp .env.example .env.development

# .env.development dosyasını düzenle:
# - DATABASE_URL
# - REDIS_HOST/PORT
# - JWT_SECRET

# Prisma client oluştur
npm run prisma:generate

# Database migration
npm run prisma:migrate

# Seed data yükle
npm run prisma:seed

# Development server başlat
npm run start:dev
```

### 3. API Testi

Swagger UI: http://localhost:3000/api/docs

### 4. Demo Kullanıcılar

| Rol     | Telefon       | OTP (Dev) |
| ------- | ------------- | --------- |
| Admin   | +905001234567 | 123456    |
| Esnaf   | +905001234568 | 123456    |
| Şoför   | +905001234569 | 123456    |
| Kurye   | +905001234570 | 123456    |
| Müşteri | +905001234571 | 123456    |

---

## 📁 Proje Yapısı

```
benimsehrim/
├── README.md                           # Proje özeti
├── docs/                               # Dokümantasyon
│   ├── architecture/
│   │   ├── SYSTEM_ARCHITECTURE.md      # Sistem mimarisi
│   │   └── FEATURE_FLAGS.md            # Feature flag sistemi
│   ├── api/
│   │   ├── AUTH_API.md                 # Auth API
│   │   ├── VENDOR_ORDER_API.md         # Vendor/Order API
│   │   └── TAXI_COURIER_API.md         # Taxi/Courier API
│   ├── database/
│   │   └── SCHEMA.md                   # Database şeması
│   └── screens/
│       └── MOBILE_SCREENS.md           # Mobil ekran wireframes
│
└── backend/                            # NestJS Backend
    ├── package.json
    ├── tsconfig.json
    ├── nest-cli.json
    ├── .env.example
    ├── prisma/
    │   ├── schema.prisma               # Database modelleri
    │   └── seed.ts                     # Demo veriler
    └── src/
        ├── main.ts                     # Entry point
        ├── app.module.ts               # Root module
        ├── common/
        │   ├── prisma/                 # Prisma service
        │   ├── redis/                  # Redis service
        │   ├── guards/                 # Auth guards
        │   └── decorators/             # Custom decorators
        ├── gateways/
        │   └── events.gateway.ts       # WebSocket gateway
        └── modules/
            ├── auth/                   # Kimlik doğrulama
            ├── users/                  # Kullanıcı yönetimi
            ├── stores/                 # Mağaza yönetimi
            ├── products/               # Ürün yönetimi
            ├── campaigns/              # Kampanya yönetimi
            ├── orders/                 # Sipariş yönetimi
            ├── taxi/                   # Taksi modülü
            ├── courier/                # Kurye modülü
            ├── chat/                   # Mesajlaşma
            ├── reviews/                # Puanlama
            ├── support/                # Destek
            ├── notifications/          # Bildirimler
            ├── feature-flags/          # Feature flags
            └── admin/                  # Admin panel
```

---

## ✅ Tamamlanan Özellikler

### Backend

- [x] Clean Architecture yapısı
- [x] JWT authentication (OTP ile)
- [x] Role-based access control
- [x] Feature flag sistemi (Freemium hazır)
- [x] Prisma ORM + PostgreSQL
- [x] Redis cache + Pub/Sub
- [x] WebSocket realtime
- [x] Swagger API docs

### Modüller

- [x] Auth (OTP, JWT, Refresh token)
- [x] Users (Profil, Adresler)
- [x] Stores (CRUD, Onay sistemi)
- [x] Products (Min 2 fotoğraf, Stok)
- [x] Campaigns (Tüm türler, Ücretsiz)
- [x] Orders (Sipariş akışı, Timeline)
- [x] Taxi (Çağrı, Konum takibi)
- [x] Courier (Görev, Teslimat)
- [x] Chat (Sipariş bazlı, Filtreli)
- [x] Reviews (Admin onaylı)
- [x] Support (Ticket sistemi)
- [x] Notifications (Push, SMS, WhatsApp)
- [x] Admin (Dashboard, Onay, Stats)

### Operasyon Otomasyonları

- [x] Sipariş bildirimi: Push → SMS (60s) → WhatsApp (120s) → İptal (180s)
- [x] Taksi çağrısı: 30s timeout → Başka şoför
- [x] Kurye görevi: 20s timeout → Başka kurye
- [x] Stok 0 → Ürün pasif
- [x] 7 gün satılmayan ürün uyarısı
- [x] Günlük sipariş yoksa uyarı

---

## 🔜 Sonraki Adımlar

### 1. Mobil Uygulamalar

- Android (Kotlin + Jetpack Compose)
- iOS (Swift + SwiftUI)

### 2. Admin Panel

- React + TypeScript
- Dashboard
- Moderasyon araçları

### 3. Entegrasyonlar

- Twilio/NetGSM SMS
- Firebase Push
- WhatsApp Business API
- Google Maps/Mapbox

### 4. Deploy

- Docker containers
- Kubernetes
- CI/CD pipeline

---

## 📞 İletişim

Sorularınız için: [proje email/slack]

---

**Benim Şehrim** - Türkiye'nin Yerel Süper Uygulaması 🇹🇷
