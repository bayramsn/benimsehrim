# 🚕 Benim Şehrim Sürücü

Taksi ve Kurye Sürücü Uygulaması

## 📱 Özellikler

- 🟢 Çevrimiçi/Çevrimdışı durumu
- 🚕 Taksi modu - Yolcu taşıma
- 📦 Kurye modu - Teslimat
- 🗺️ OpenStreetMap harita (ÜCRETSİZ)
- 📍 Gerçek zamanlı konum takibi
- 💰 Kazanç takibi
- 🔔 Push bildirimleri

## 🛠️ Teknolojiler

- Kotlin
- Jetpack Compose
- Hilt (Dependency Injection)
- OSMDroid (Harita)
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
├── java/com/benimsehrim/driver/
│   ├── MainActivity.kt
│   ├── DriverApp.kt
│   ├── feature/
│   │   ├── auth/LoginScreen.kt
│   │   ├── home/DriverHomeScreen.kt
│   │   ├── earnings/EarningsScreen.kt
│   │   └── navigation/NavigationScreen.kt
│   ├── navigation/DriverNavigation.kt
│   ├── service/LocationTrackingService.kt
│   └── ui/theme/Theme.kt
└── res/
    └── values/
        ├── strings.xml
        ├── colors.xml
        └── themes.xml
```

## 🔑 Demo Giriş

OTP kodu: **123456** (her zaman geçerli)
