# 🏪 Benim Şehrim Esnaf

Esnaf ve Mağaza Yönetim Uygulaması

## 📱 Özellikler

- 📊 Dashboard - Özet istatistikler
- 📦 Sipariş yönetimi
- 🍔 Ürün/Menü yönetimi
- 🎯 Kampanya oluşturma
- ⚙️ Mağaza ayarları
- 🔔 Push bildirimleri (yeni sipariş)

## 🛠️ Teknolojiler

- Kotlin
- Jetpack Compose
- Hilt (Dependency Injection)
- Retrofit (API)
- Firebase Messaging

## 🚀 Kurulum

```bash
# Gradle Sync
./gradlew sync

# Debug Build
./gradlew assembleDebug

# APK Install
adb install app/build/outputs/apk/debug/app-debug.apk
```

## 📂 Proje Yapısı

```
app/src/main/
├── java/com/benimsehrim/vendor/
│   ├── MainActivity.kt
│   ├── VendorApp.kt
│   ├── feature/
│   │   ├── auth/LoginScreen.kt
│   │   ├── dashboard/DashboardScreen.kt
│   │   ├── orders/OrdersScreen.kt
│   │   ├── products/ProductsScreen.kt
│   │   ├── campaigns/CampaignsScreen.kt
│   │   └── settings/SettingsScreen.kt
│   ├── navigation/Navigation.kt
│   └── ui/theme/Theme.kt
└── res/
    └── values/
        ├── strings.xml
        ├── colors.xml
        └── themes.xml
```

## 🔑 Demo Giriş

OTP kodu: **123456** (her zaman geçerli)
