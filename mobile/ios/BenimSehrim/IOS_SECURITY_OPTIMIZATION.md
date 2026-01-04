# iOS Security & Optimization Guide

## 🔒 Güvenlik Özellikleri

### 1. SSL Pinning

**Dosya**: `Core/Security/SSLPinningManager.swift`

```swift
// Otomatik SSL pinning
let session = URLSession.createSecureSession()

// Certificate pin'leri güncelleme
// 1. Terminal'de çalıştır:
openssl s_client -connect api.benimsehrim.com:443 | \
openssl x509 -pubkey -noout | \
openssl pkey -pubin -outform der | \
openssl dgst -sha256 -binary | \
base64

// 2. Çıktıyı SSLPinningManager.swift içindeki certificatePins array'ine ekle
```

**Özellikler**:

- ✅ Production domain için SSL pinning
- ✅ Debug modda devre dışı (development kolaylığı)
- ✅ Backup certificate desteği
- ✅ SHA-256 hash validation

### 2. Secure Storage (Keychain)

**Dosya**: `Core/Security/SecureStorageManager.swift`

```swift
// Token kaydetme
SecureStorageManager.shared.authToken = "your_token"

// Token okuma
if let token = SecureStorageManager.shared.authToken {
    print("Token: \(token)")
}

// Session temizleme
SecureStorageManager.shared.clearSession()
```

**Özellikler**:

- ✅ iOS Keychain kullanımı
- ✅ Biometric authentication (Face ID / Touch ID)
- ✅ Güvenli token yönetimi
- ✅ Otomatik şifreleme

### 3. Jailbreak Detection

**Dosya**: `Core/Security/JailbreakDetectionManager.swift`

```swift
// Güvenlik kontrolü
let result = JailbreakDetectionManager.shared.performSecurityCheck()

if !result.isSafe {
    // Uyarı göster veya uygulamayı kapat
    print(result.warningMessage ?? "Güvenlik riski tespit edildi")
}
```

**Kontroller**:

- ✅ Jailbreak dosyaları
- ✅ Cydia ve benzeri uygulamalar
- ✅ Sistem yazma erişimi
- ✅ Fork() kontrolü
- ✅ Debugger tespiti

### 4. Secure Network Manager

**Dosya**: `Core/Network/SecureNetworkManager.swift`

```swift
// GET request
let stores: [Store] = try await SecureNetworkManager.shared.get(
    endpoint: "/stores",
    parameters: ["cityId": "123"]
)

// POST request
let response: AuthResponse = try await SecureNetworkManager.shared.post(
    endpoint: "/auth/login",
    body: loginRequest
)
```

**Özellikler**:

- ✅ SSL pinning entegrasyonu
- ✅ Otomatik token yönetimi
- ✅ Request/Response logging (debug)
- ✅ Error handling
- ✅ Image caching

## ⚡ Performans Optimizasyonları

### 1. Image Optimization

**Dosya**: `Core/Utils/PerformanceOptimization.swift`

```swift
// Optimize edilmiş image loading
OptimizedAsyncImage(
    url: imageUrl,
    placeholder: Image(systemName: "photo")
)
.frame(width: 100, height: 100)
```

**Özellikler**:

- ✅ Automatic caching (NSCache)
- ✅ Memory limit (50 MB)
- ✅ Lazy loading
- ✅ Placeholder support

### 2. List Performance

```swift
List {
    ForEach(items, id: \.id) { item in
        ItemRow(item: item)
            .optimizedForList() // Performance optimization
    }
}
```

### 3. Memory Management

```swift
// ViewModel'de memory warning handling
class MyViewModel: ObservableObject {
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: .memoryWarning,
            object: nil
        )
    }

    @objc private func handleMemoryWarning() {
        // Clear caches, release resources
    }
}
```

### 4. Lazy View Loading

```swift
NavigationLink(destination: LazyView(DetailView())) {
    Text("Go to Detail")
}
```

## 📱 App Configuration

### Info.plist Ayarları

```xml
<!-- API Base URL -->
<key>API_BASE_URL</key>
<string>https://api.benimsehrim.com/v1</string>

<!-- App Transport Security -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>

<!-- Privacy Permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Teslimat adresi için konum bilginize ihtiyacımız var</string>

<key>NSCameraUsageDescription</key>
<string>Profil fotoğrafı için kamera erişimi gerekli</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Profil fotoğrafı seçmek için galeri erişimi gerekli</string>

<key>NSFaceIDUsageDescription</key>
<string>Güvenli giriş için Face ID kullanılacak</string>
```

## 🚀 Build Configuration

### Debug vs Release

**Debug**:

- SSL Pinning: Disabled
- Jailbreak Detection: Disabled
- Logging: Enabled
- API URL: http://localhost:3000/v1

**Release**:

- SSL Pinning: Enabled
- Jailbreak Detection: Enabled
- Logging: Disabled
- API URL: https://api.benimsehrim.com/v1

### Build Settings

```swift
// Compiler Optimization Level
// Debug: -Onone
// Release: -O -whole-module-optimization

// Swift Compilation Mode
// Debug: Incremental
// Release: Whole Module

// Strip Debug Symbols
// Release: Yes

// Enable Bitcode
// Release: Yes
```

## 📊 Performance Metrics

### Hedef Değerler

```
✅ App Launch: < 2 saniye
✅ Screen Transition: < 300ms
✅ Image Load: < 500ms
✅ API Response: < 1 saniye
✅ Memory Usage: < 150 MB
```

### Monitoring

```swift
// Performance monitoring
import os.signpost

let log = OSLog(subsystem: "com.benimsehrim.app", category: "Performance")

os_signpost(.begin, log: log, name: "Load Data")
// ... operation
os_signpost(.end, log: log, name: "Load Data")
```

## 🔐 Security Checklist

- [ ] SSL Pinning aktif (production)
- [ ] Certificate pins güncellendi
- [ ] Keychain kullanımı
- [ ] Jailbreak detection aktif
- [ ] Biometric authentication
- [ ] Secure network manager
- [ ] Debug logging kapalı (release)
- [ ] API keys güvenli
- [ ] Info.plist permissions

## ⚡ Performance Checklist

- [ ] Image caching aktif
- [ ] Lazy loading kullanımı
- [ ] Memory warning handling
- [ ] List optimization
- [ ] Network caching
- [ ] Compiler optimization (release)
- [ ] Bitcode enabled
- [ ] App thinning

## 📝 Testing

### Security Testing

```bash
# SSL Pinning test
# 1. Charles Proxy ile MITM attack dene
# 2. Uygulama bağlantıyı reddetmeli

# Jailbreak test
# 1. Jailbroken cihazda test et
# 2. Uyarı gösterilmeli
```

### Performance Testing

```bash
# Instruments ile profiling
# 1. Time Profiler
# 2. Allocations
# 3. Leaks
# 4. Network
```

## 🚨 Production Deployment

### Pre-deployment Checklist

1. **Certificates**

   - [ ] SSL certificate pins güncellendi
   - [ ] Apple Developer certificate geçerli
   - [ ] Push notification certificate aktif

2. **Configuration**

   - [ ] API URL production'a çevrildi
   - [ ] Debug logging kapalı
   - [ ] Jailbreak detection aktif
   - [ ] SSL pinning aktif

3. **Testing**

   - [ ] Security testing tamamlandı
   - [ ] Performance testing tamamlandı
   - [ ] Real device testing
   - [ ] TestFlight beta testing

4. **App Store**
   - [ ] Privacy policy hazır
   - [ ] Terms of service hazır
   - [ ] KVKK compliance
   - [ ] Screenshots hazır
   - [ ] App description hazır

## 📞 Support

**Security Issues**: security@benimsehrim.com  
**Technical Support**: support@benimsehrim.com
