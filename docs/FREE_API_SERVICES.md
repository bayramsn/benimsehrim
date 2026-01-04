# 🆓 Tamamen Ücretsiz API Servisleri

Bu projede **hiçbir ücretli servis kullanılmamaktadır**. Tüm servisler ya tamamen ücretsiz ya da yerel olarak çalışmaktadır.

## 📊 Servis Özeti

| Kategori            | Servis                       | Maliyet | Not                           |
| ------------------- | ---------------------------- | ------- | ----------------------------- |
| 🗺️ Harita (Backend) | Nominatim (OSM)              | **$0**  | Sınırsız (fair use)           |
| 🗺️ Rota             | OpenRouteService / Haversine | **$0**  | 2000/gün veya offline         |
| 🗺️ Harita (Android) | OSMDroid                     | **$0**  | OpenStreetMap tiles           |
| 🗺️ Harita (iOS)     | MapKit                       | **$0**  | Apple Maps, ücretsiz          |
| 🗺️ Harita (Web)     | Leaflet.js                   | **$0**  | OSM tiles                     |
| 📧 Email            | Mock / Console Log           | **$0**  | Gerçek email için SMTP        |
| 📱 SMS              | Mock / Demo Mode             | **$0**  | OTP: 123456 her zaman geçerli |
| 📂 Depolama         | Local Filesystem             | **$0**  | ./uploads klasörü             |
| 🔍 Arama            | PostgreSQL Queries           | **$0**  | Full-text search              |
| 🗃️ Veritabanı       | PostgreSQL (Docker)          | **$0**  | Yerel Docker                  |
| ⚡ Cache            | Redis (Docker)               | **$0**  | Yerel Docker                  |
| 🔔 Push             | Firebase (opsiyonel)         | **$0**  | Sınırsız, ücretsiz            |

**Toplam Aylık Maliyet: $0**

---

## 🗺️ Harita Servisleri (100% Ücretsiz)

### Backend: Nominatim + OpenRouteService

```env
# .env - API key olmadan da çalışır
OPENROUTESERVICE_API_KEY=  # Boş bırakabilirsiniz
```

**Otomatik Fallback:**

1. OpenRouteService API key varsa → ORS kullanır
2. Yoksa → Haversine formülü (offline, %100 güvenilir)
3. Geocoding → Her zaman Nominatim (ücretsiz)

### Android: OSMDroid

```kotlin
// build.gradle.kts
implementation("org.osmdroid:osmdroid-android:6.1.18")

// Kullanım - API key GEREKMEZ!
mapView.setTileSource(TileSourceFactory.MAPNIK)
```

### iOS: MapKit (Apple Maps)

```swift
import MapKit

// API key GEREKMEZ!
Map(coordinateRegion: $region)
```

### Web: Leaflet.js

```html
<link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css" />
<script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>

<script>
  // API key GEREKMEZ!
  const map = L.map("map").setView([39.8468, 34.0288], 13);
  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png").addTo(map);
</script>
```

---

## 📧 Email (Demo Mode)

Geliştirme aşamasında email'ler console'a yazdırılır:

```env
EMAIL_PROVIDER=mock
```

**Üretim için ücretsiz seçenekler:**

- Kendi SMTP sunucunuz
- Gmail SMTP (günde 500 email)
- Mailtrap (test için)

---

## 📱 SMS (Demo Mode)

```env
SMS_PROVIDER=mock
DEMO_MODE=true
```

**Demo modda:**

- OTP kodu `123456` her zaman geçerlidir
- SMS gönderilmez, log'a yazılır

---

## 📂 Dosya Depolama (Local)

```env
STORAGE_PROVIDER=local
UPLOAD_PATH=./uploads
```

Dosyalar sunucuda `./uploads` klasörüne kaydedilir.

---

## 🔍 Arama (PostgreSQL)

Elasticsearch/Meilisearch kullanılmaz. PostgreSQL'in built-in full-text search özelliği kullanılır:

```typescript
// Otomatik fallback database search'e
const results = await searchService.searchStores({ query: "kasap" });
```

---

## 🚀 Projeyi Çalıştırma (Tamamen Ücretsiz)

```bash
# 1. Docker ile veritabanlarını başlat
docker-compose up -d postgres redis

# 2. Backend'i başlat
cd backend
npm install
cp .env.development .env
npx prisma generate
npx prisma migrate dev
npm run start:dev

# 3. API'yi test et
curl http://localhost:3000/docs
```

---

## ⚠️ Önemli Notlar

1. **OpenStreetMap Attribution:** OSM haritası kullanırken attribution göstermek zorunludur
2. **Nominatim Rate Limit:** Saniyede 1 istek kuralına uyun
3. **Demo Mode:** Üretimde `DEMO_MODE=false` yapın ve gerçek SMS servisi konfigüre edin

---

## 🔄 Ücretli Servislere Geçiş (Opsiyonel)

İlerleyen aşamalarda ihtiyaç duyulursa:

| Kategori | Ücretsiz   | Ücretli Alternatif          |
| -------- | ---------- | --------------------------- |
| Email    | Mock       | Resend (3k/ay ücretsiz)     |
| SMS      | Mock       | NetGSM, Twilio              |
| Harita   | OSM        | Google Maps ($200/ay kredi) |
| Depolama | Local      | Cloudinary (25GB ücretsiz)  |
| Arama    | PostgreSQL | Meilisearch, Algolia        |

Geçiş yapmak için sadece `.env` dosyasını güncelleyin - kod değişikliği gerekmez.
