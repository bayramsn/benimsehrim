# Firebase Kurulum Rehberi

Bu belge, Benim Şehrim projesi için Firebase kurulumunu açıklar.

## 📋 Gereksinimler

1. Google hesabı
2. Firebase Console erişimi: https://console.firebase.google.com

---

## 1️⃣ Firebase Projesi Oluşturma

1. [Firebase Console](https://console.firebase.google.com) adresine gidin
2. "Add Project" / "Proje Ekle" butonuna tıklayın
3. Proje adı: `benimsehrim` (veya istediğiniz ad)
4. Google Analytics'i etkinleştirin (opsiyonel)
5. "Create Project" / "Proje Oluştur" butonuna tıklayın

---

## 2️⃣ Backend için Service Account

### 2.1 Service Account Oluşturma

1. Firebase Console'da projenizi seçin
2. ⚙️ **Project Settings** > **Service Accounts** sekmesine gidin
3. "Generate new private key" butonuna tıklayın
4. JSON dosyasını indirin

### 2.2 Environment Değişkenlerini Ayarlama

İndirdiğiniz JSON dosyasından şu değerleri alın ve `.env` dosyanıza ekleyin:

```env
# Firebase Console > Project Settings > Service Accounts
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

**⚠️ Önemli:**

- `FIREBASE_PRIVATE_KEY` değerini çift tırnak içinde yazın
- `\n` karakterlerini koruyun

---

## 3️⃣ Android için Firebase

### 3.1 Android Uygulaması Ekleme

1. Firebase Console'da projenizi seçin
2. "Add app" > Android simgesine tıklayın
3. Package name: `com.benimsehrim.app`
4. App nickname: `Benim Şehrim Android`
5. "Register app" butonuna tıklayın

### 3.2 google-services.json

1. `google-services.json` dosyasını indirin
2. Dosyayı şu konuma kopyalayın:
   ```
   mobile/android/app/google-services.json
   ```

### 3.3 Android Gradle Yapılandırması

`mobile/android/build.gradle.kts` dosyasına eklendi (zaten mevcut):

```kotlin
id("com.google.gms.google-services") version "4.4.0" apply false
```

`mobile/android/app/build.gradle.kts` dosyasına eklendi:

```kotlin
id("com.google.gms.google-services")
```

---

## 4️⃣ iOS için Firebase

### 4.1 iOS Uygulaması Ekleme

1. Firebase Console'da projenizi seçin
2. "Add app" > iOS simgesine tıklayın
3. Bundle ID: `com.benimsehrim.app`
4. App nickname: `Benim Şehrim iOS`
5. "Register app" butonuna tıklayın

### 4.2 GoogleService-Info.plist

1. `GoogleService-Info.plist` dosyasını indirin
2. Dosyayı şu konuma kopyalayın:
   ```
   mobile/ios/BenimSehrim/BenimSehrim/GoogleService-Info.plist
   ```

### 4.3 Xcode'da Ekleme

1. Xcode'da projeyi açın
2. `GoogleService-Info.plist` dosyasını projeye sürükleyin
3. "Copy items if needed" seçeneğini işaretleyin
4. Target: "BenimSehrim" seçili olduğundan emin olun

---

## 5️⃣ Cloud Messaging (Push Notifications)

### 5.1 Android'de İzinler

`AndroidManifest.xml` dosyasında zaten mevcut:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 5.2 iOS'ta APNs Yapılandırması

1. Apple Developer hesabınızda APNs sertifikası oluşturun
2. Firebase Console > Project Settings > Cloud Messaging
3. "iOS app configuration" bölümünde
4. APNs Authentication Key'i yükleyin

---

## 6️⃣ Test Etme

### Backend Test

```bash
cd backend
npm run start:dev

# Push notification log'larını kontrol edin
```

### Android Test

1. Fiziksel cihaz veya emülatör'de uygulamayı çalıştırın
2. FCM token konsola yazdırılacak
3. Firebase Console > Cloud Messaging > "Send test message"

### iOS Test

1. Fiziksel cihaz gerekli (simülatör push desteklemez)
2. Uygulamayı cihaza yükleyin
3. Firebase Console'dan test mesajı gönderin

---

## 📊 Notification Kanalları

### Android Kanalları

| Kanal ID              | Açıklama               |
| --------------------- | ---------------------- |
| `benimsehrim_default` | Genel bildirimler      |
| `benimsehrim_orders`  | Sipariş güncellemeleri |
| `benimsehrim_taxi`    | Taksi bildirimleri     |
| `benimsehrim_chat`    | Mesaj bildirimleri     |

### Bildirim Tipleri

| Tip             | Açıklama                   |
| --------------- | -------------------------- |
| `NEW_ORDER`     | Yeni sipariş (esnaf)       |
| `ORDER_STATUS`  | Sipariş durumu değişikliği |
| `NEW_RIDE_CALL` | Yeni taksi çağrısı (şoför) |
| `RIDE_STATUS`   | Yolculuk durumu            |
| `CHAT_MESSAGE`  | Yeni mesaj                 |

---

## 🔧 Sorun Giderme

### "Firebase not initialized" hatası

- `.env` dosyasındaki Firebase değişkenlerini kontrol edin
- `FIREBASE_PRIVATE_KEY` formatını kontrol edin

### Android: Push gelmiyor

- `google-services.json` dosyasının doğru yerde olduğundan emin olun
- Gradle sync yapın
- Emülatörde Google Play Services yüklü olmalı

### iOS: Push gelmiyor

- Fiziksel cihaz kullanın (simülatör desteklemez)
- APNs sertifikasının Firebase'e yüklendiğinden emin olun
- Bundle ID'nin eşleştiğini kontrol edin

---

## 📚 Kaynaklar

- [Firebase Console](https://console.firebase.google.com)
- [Firebase Android SDK](https://firebase.google.com/docs/android/setup)
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
