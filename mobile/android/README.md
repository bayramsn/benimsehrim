# Benim Şehrim - Android Uygulaması

## 📱 Geliştirme Ortamı

### Gereksinimler

- Android Studio Hedgehog (2023.1.1) veya üzeri
- JDK 17
- Android SDK 34
- Kotlin 1.9+

### Kurulum

1. **Projeyi aç:**

   ```
   Android Studio -> Open -> mobile/android klasörünü seç
   ```

2. **Gradle sync:**
   Android Studio otomatik olarak yapacak.

3. **google-services.json:**
   Firebase Console'dan indirip `app/` klasörüne koy.

4. **local.properties:**

   ```properties
   MAPS_API_KEY=your_google_maps_api_key
   ```

5. **Backend URL:**
   `app/build.gradle.kts` dosyasında:
   - Emülatör için: `http://10.0.2.2:3000/v1/`
   - Fiziksel cihaz için: `http://YOUR_IP:3000/v1/`

### Çalıştırma

```
Android Studio -> Run 'app'
```

---

## 📁 Proje Yapısı

```
app/src/main/java/com/benimsehrim/app/
├── BenimSehrimApp.kt          # Hilt Application
├── MainActivity.kt             # Single Activity
├── core/
│   ├── auth/                   # Auth state
│   ├── data/                   # TokenManager
│   ├── di/                     # Hilt modules
│   ├── firebase/               # FCM Service
│   ├── model/                  # Data classes
│   └── network/                # Retrofit API
├── feature/
│   ├── auth/                   # Login, OTP, Register
│   ├── home/                   # Ana sayfa
│   ├── stores/                 # Mağaza listesi/detay
│   ├── cart/                   # Sepet
│   ├── orders/                 # Siparişler
│   ├── taxi/                   # Taksi çağırma
│   ├── profile/                # Profil
│   └── chat/                   # Mesajlaşma
├── navigation/                 # Navigation graph
└── ui/theme/                   # Material 3 theme
```

---

## 🎨 Özellikler

### Tamamlanan

- [x] Jetpack Compose UI
- [x] Material 3 Design
- [x] Hilt Dependency Injection
- [x] Retrofit + OkHttp networking
- [x] JWT token management
- [x] Navigation Compose
- [x] Google Maps integration
- [x] Firebase Push Notifications
- [x] Dark/Light theme

### Ekranlar

- [x] Login (OTP)
- [x] Register
- [x] Home (Kategoriler, kampanyalar, mağazalar)
- [x] Mağaza listesi
- [x] Mağaza detay + ürünler
- [x] Taksi çağırma (harita)
- [x] Siparişlerim
- [x] Profil
- [x] Chat (placeholder)

---

## 🚀 Sonraki Adımlar

1. **Sepet yönetimi** - Global cart state
2. **Sipariş oluşturma** - Checkout flow
3. **Gerçek zamanlı takip** - WebSocket
4. **Yorum & puanlama**
5. **Adres seçimi** - Google Places
6. **Animasyonlar** - Lottie

---

## 📝 Notlar

### Demo Modu

Backend olmadan test için mock data kullanılabilir.

### Proguard

Release build için `proguard-rules.pro` düzenlenmeli.

### Signing

Release için keystore oluşturulmalı.
