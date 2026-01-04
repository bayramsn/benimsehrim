# Benim Şehrim - iOS Uygulaması

## 📱 Geliştirme Ortamı

### Gereksinimler

- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+
- macOS Sonoma

### Kurulum

1. **Projeyi aç:**

   ```
   Xcode -> Open -> mobile/ios/BenimSehrim
   ```

2. **Backend URL'i güncelle:**
   `NetworkManager.swift` dosyasında:

   - Simulator: `http://localhost:3000/v1`
   - Fiziksel cihaz: `http://YOUR_IP:3000/v1`

3. **Çalıştır:**
   ```
   Product -> Run (⌘R)
   ```

---

## 📁 Proje Yapısı

```
BenimSehrim/
├── BenimSehrimApp.swift      # Entry point
├── ContentView.swift          # Main navigation
├── Core/
│   ├── Auth/
│   │   └── AuthManager.swift
│   ├── Models/
│   │   └── Models.swift       # All data models
│   ├── Network/
│   │   └── NetworkManager.swift
│   └── Theme/
│       └── Theme.swift
└── Features/
    ├── Auth/
    │   ├── LoginView.swift
    │   ├── OtpView.swift
    │   └── RegisterView.swift
    ├── Home/
    │   └── HomeView.swift
    ├── Stores/
    │   ├── StoresView.swift
    │   └── StoreDetailView.swift
    ├── Taxi/
    │   └── TaxiView.swift
    ├── Orders/
    │   └── OrdersView.swift
    ├── Cart/
    │   └── CartView.swift
    └── Profile/
        └── ProfileView.swift
```

---

## ✅ Özellikler

- [x] SwiftUI + iOS 16+
- [x] MVVM Architecture
- [x] Async/Await networking
- [x] MapKit integration
- [x] Dark/Light mode support
- [x] Custom theme with colors

### Ekranlar

- [x] Login (OTP)
- [x] Register
- [x] Home
- [x] Stores list
- [x] Store detail + products
- [x] Taxi with map
- [x] Orders
- [x] Profile

---

## 🚀 Sonraki Adımlar

1. Push notifications (APNs)
2. Core Data for offline
3. Location services
4. Widget support
5. App Clips
