# 🚩 Feature Flag Sistemi

## Amaç

MVP aşamasında tüm özellikler ücretsiz. İleride SaaS modeline geçişte feature flag'ler ile ücretli özellikleri kontrollü açabiliriz.

## Flag Kategorileri

### 1. Esnaf Özellikleri

```typescript
const VENDOR_FLAGS = {
  // MVP: Hepsi ücretsiz
  UNLIMITED_PRODUCTS: true, // İleride: Max 20 ürün/50 ürün paketleri
  UNLIMITED_CAMPAIGNS: true, // İleride: Max 3 kampanya/sınırsız paket
  PRIORITY_LISTING: false, // İleride: Öne çıkarılma paketi
  ANALYTICS_ADVANCED: false, // İleride: Detaylı analitik paketi
  MULTI_BRANCH: false, // İleride: Çoklu şube yönetimi
  CUSTOM_BRANDING: false, // İleride: Özel marka tasarımı
  API_ACCESS: false, // İleride: API entegrasyonu
  BULK_IMPORT: false, // İleride: Toplu ürün yükleme
};
```

### 2. Taksi Özellikleri

```typescript
const TAXI_FLAGS = {
  // MVP: Hepsi ücretsiz
  BASIC_DISPATCH: true, // Temel çağrı sistemi
  DAILY_STATS: true, // Günlük istatistikler
  ADVANCED_ANALYTICS: false, // İleride: Detaylı raporlar
  PRIORITY_CALLS: false, // İleride: Öncelikli çağrı alma
  FLEET_MANAGEMENT: false, // İleride: Filo yönetimi
};
```

### 3. Kurye Özellikleri

```typescript
const COURIER_FLAGS = {
  // MVP: Hepsi ücretsiz
  BASIC_DELIVERY: true, // Temel teslimat
  ROUTE_OPTIMIZATION: false, // İleride: Rota optimizasyonu
  BATCH_DELIVERY: false, // İleride: Toplu teslimat
};
```

### 4. Platform Özellikleri

```typescript
const PLATFORM_FLAGS = {
  // MVP: Tümü açık
  COMMISSION_FREE: true, // Komisyon yok
  FREE_SMS: true, // Ücretsiz SMS
  FREE_WHATSAPP: true, // Ücretsiz WhatsApp

  // İleride aktif olacak
  COMMISSION_ENABLED: false, // %X komisyon
  PREMIUM_SUPPORT: false, // 7/24 destek
  WHITE_LABEL: false, // Beyaz etiket çözüm
};
```

---

## Database Yapısı

### feature_flags tablosu

```sql
CREATE TABLE feature_flags (
  id UUID PRIMARY KEY,
  key VARCHAR(100) UNIQUE NOT NULL,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  default_value BOOLEAN DEFAULT false,
  is_premium BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Örnek veriler
INSERT INTO feature_flags (key, name, default_value, is_premium) VALUES
('UNLIMITED_PRODUCTS', 'Sınırsız Ürün', true, false),
('UNLIMITED_CAMPAIGNS', 'Sınırsız Kampanya', true, false),
('PRIORITY_LISTING', 'Öne Çıkarma', false, true),
('ADVANCED_ANALYTICS', 'Gelişmiş Analitik', false, true);
```

### user_features tablosu

```sql
CREATE TABLE user_features (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  flag_key VARCHAR(100) REFERENCES feature_flags(key),
  enabled BOOLEAN DEFAULT false,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, flag_key)
);
```

### subscription_plans tablosu (Hazır ama pasif)

```sql
CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(50) UNIQUE NOT NULL,
  price DECIMAL(10,2) DEFAULT 0,
  billing_period VARCHAR(20),  -- monthly, yearly
  features JSONB,              -- İçerdiği flag'ler
  is_active BOOLEAN DEFAULT false,  -- MVP'de false
  created_at TIMESTAMP DEFAULT NOW()
);

-- Hazır ama pasif planlar
INSERT INTO subscription_plans (name, slug, price, is_active, features) VALUES
('Ücretsiz', 'free', 0, true, '["UNLIMITED_PRODUCTS", "UNLIMITED_CAMPAIGNS"]'),
('Başlangıç', 'starter', 299, false, '["PRIORITY_LISTING"]'),
('Profesyonel', 'pro', 599, false, '["PRIORITY_LISTING", "ADVANCED_ANALYTICS"]'),
('Kurumsal', 'enterprise', 0, false, '["ALL_FEATURES"]');
```

---

## Backend Service

```typescript
// feature-flag.service.ts
@Injectable()
export class FeatureFlagService {
  async isEnabled(userId: string, flagKey: string): Promise<boolean> {
    // 1. Kullanıcıya özel flag kontrolü
    const userFeature = await this.userFeatureRepo.findOne({
      where: { userId, flagKey },
    });

    if (userFeature) {
      // Süre kontrolü
      if (userFeature.expiresAt && userFeature.expiresAt < new Date()) {
        return false;
      }
      return userFeature.enabled;
    }

    // 2. Global flag kontrolü
    const flag = await this.flagRepo.findOne({ where: { key: flagKey } });
    return flag?.defaultValue ?? false;
  }

  async getUserFeatures(userId: string): Promise<Record<string, boolean>> {
    const allFlags = await this.flagRepo.find();
    const userFeatures = await this.userFeatureRepo.find({ where: { userId } });

    const result: Record<string, boolean> = {};

    for (const flag of allFlags) {
      const userFeature = userFeatures.find((f) => f.flagKey === flag.key);
      result[flag.key] = userFeature?.enabled ?? flag.defaultValue;
    }

    return result;
  }
}
```

---

## Kullanım Örnekleri

### Controller'da

```typescript
@Post('products')
async createProduct(@Body() dto: CreateProductDto, @User() user: AuthUser) {
  // Ürün limiti kontrolü
  const canAddUnlimited = await this.featureFlag.isEnabled(
    user.id,
    'UNLIMITED_PRODUCTS'
  );

  if (!canAddUnlimited) {
    const productCount = await this.productRepo.count({
      where: { storeId: user.storeId }
    });
    if (productCount >= 20) {
      throw new ForbiddenException('Ürün limitine ulaştınız. Premium pakete geçin.');
    }
  }

  return this.productService.create(dto);
}
```

### Mobil Tarafta

```kotlin
// Android
class FeatureManager @Inject constructor(
    private val api: ApiService,
    private val cache: FeatureCache
) {
    suspend fun isEnabled(flag: String): Boolean {
        return cache.get(flag) ?: api.checkFeature(flag).also {
            cache.set(flag, it)
        }
    }
}

// Kullanım
if (featureManager.isEnabled("PRIORITY_LISTING")) {
    showPriorityOptions()
}
```

---

## MVP → SaaS Geçiş Planı

### Aşama 1: MVP (Şu an)

- Tüm özellikler ücretsiz
- Kullanıcı tabanı oluştur
- Alışkanlık yarat

### Aşama 2: Soft Launch

- Premium özellikleri tanıt (ama zorunlu tutma)
- "Yakında" etiketiyle göster
- İlgi ölç

### Aşama 3: Freemium

- Temel özellikler ücretsiz kalır
- Premium özellikler ücretli
- Mevcut kullanıcılara grace period

### Aşama 4: Full SaaS

- Komisyon sistemi aktif
- Plan bazlı fiyatlandırma
- Enterprise çözümler
