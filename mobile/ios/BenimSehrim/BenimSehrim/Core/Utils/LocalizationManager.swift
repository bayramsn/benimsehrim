import Foundation

// MARK: - Localization Manager (Çoklu Dil Desteği)
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language = .turkish
    
    private let languageKey = "app_language"
    
    init() {
        loadSavedLanguage()
    }
    
    enum Language: String, CaseIterable {
        case turkish = "tr"
        case english = "en"
        case arabic = "ar"
        case kurdish = "ku"
        
        var displayName: String {
            switch self {
            case .turkish: return "Türkçe"
            case .english: return "English"
            case .arabic: return "العربية"
            case .kurdish: return "Kurdî"
            }
        }
        
        var flag: String {
            switch self {
            case .turkish: return "🇹🇷"
            case .english: return "🇬🇧"
            case .arabic: return "🇸🇦"
            case .kurdish: return "🇮🇶"
            }
        }
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        
        // Update app locale
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
    }
    
    private func loadSavedLanguage() {
        if let saved = UserDefaults.standard.string(forKey: languageKey),
           let language = Language(rawValue: saved) {
            currentLanguage = language
        }
    }
    
    // MARK: - Localized Strings
    func localized(_ key: String) -> String {
        return LocalizedStrings.get(key, language: currentLanguage)
    }
}

// MARK: - Localized Strings Dictionary
struct LocalizedStrings {
    static func get(_ key: String, language: LocalizationManager.Language) -> String {
        let strings = allStrings[language.rawValue] ?? allStrings["tr"]!
        return strings[key] ?? key
    }
    
    static let allStrings: [String: [String: String]] = [
        "tr": [
            // General
            "app_name": "Benim Şehrim",
            "ok": "Tamam",
            "cancel": "İptal",
            "save": "Kaydet",
            "delete": "Sil",
            "edit": "Düzenle",
            "loading": "Yükleniyor...",
            "error": "Hata",
            "success": "Başarılı",
            "retry": "Tekrar Dene",
            "close": "Kapat",
            "back": "Geri",
            "next": "İleri",
            "done": "Bitti",
            "search": "Ara",
            "filter": "Filtrele",
            "sort": "Sırala",
            "all": "Tümü",
            "none": "Hiçbiri",
            "yes": "Evet",
            "no": "Hayır",
            
            // Auth
            "login": "Giriş Yap",
            "register": "Kayıt Ol",
            "logout": "Çıkış Yap",
            "phone_number": "Telefon Numarası",
            "enter_otp": "Doğrulama Kodu",
            "otp_sent": "Kod gönderildi",
            "verify": "Doğrula",
            "name": "Ad Soyad",
            "email": "E-posta",
            "city": "Şehir",
            "district": "İlçe",
            
            // Home
            "home": "Ana Sayfa",
            "categories": "Kategoriler",
            "nearby": "Yakınındaki",
            "popular": "Popüler",
            "campaigns": "Kampanyalar",
            "favorites": "Favoriler",
            "orders": "Siparişler",
            "profile": "Profil",
            "wallet": "Cüzdan",
            
            // Store
            "stores": "Mağazalar",
            "store_detail": "Mağaza Detayı",
            "products": "Ürünler",
            "add_to_cart": "Sepete Ekle",
            "view_cart": "Sepeti Gör",
            "min_order": "Min. Sipariş",
            "delivery_fee": "Teslimat Ücreti",
            "delivery_time": "Teslimat Süresi",
            "open": "Açık",
            "closed": "Kapalı",
            "busy": "Yoğun",
            
            // Cart
            "cart": "Sepet",
            "empty_cart": "Sepet Boş",
            "checkout": "Sipariş Ver",
            "subtotal": "Ara Toplam",
            "total": "Toplam",
            "apply_coupon": "Kupon Uygula",
            "coupon_code": "Kupon Kodu",
            
            // Order
            "order_placed": "Sipariş Alındı",
            "order_confirmed": "Sipariş Onaylandı",
            "preparing": "Hazırlanıyor",
            "on_the_way": "Yolda",
            "delivered": "Teslim Edildi",
            "cancelled": "İptal Edildi",
            "track_order": "Siparişi Takip Et",
            "order_history": "Sipariş Geçmişi",
            "reorder": "Tekrar Sipariş Ver",
            
            // Taxi
            "taxi": "Taksi",
            "call_taxi": "Taksi Çağır",
            "pickup_location": "Nereden?",
            "dropoff_location": "Nereye?",
            "estimated_fare": "Tahmini Ücret",
            "find_driver": "Şoför Bul",
            "driver_coming": "Şoför Yolda",
            "trip_started": "Yolculuk Başladı",
            "trip_ended": "Yolculuk Bitti",
            
            // Courier
            "courier": "Kurye",
            "call_courier": "Kurye Çağır",
            "package_details": "Paket Detayları",
            "pickup_address": "Alınacak Adres",
            "delivery_address": "Teslim Adresi",
            
            // Chat
            "chat": "Mesajlar",
            "send_message": "Mesaj Gönder",
            "type_message": "Mesaj yaz...",
            
            // Rating
            "rate_order": "Siparişi Puanla",
            "rate_driver": "Şoförü Puanla",
            "rate_courier": "Kuryeyi Puanla",
            "add_comment": "Yorum Ekle",
            "submit_review": "Gönder",
            
            // Support
            "support": "Destek",
            "help": "Yardım",
            "report_problem": "Sorun Bildir",
            "faq": "Sık Sorulan Sorular",
            "contact_us": "Bize Ulaşın",
            
            // Settings
            "settings": "Ayarlar",
            "notifications": "Bildirimler",
            "language": "Dil",
            "privacy": "Gizlilik",
            "terms": "Kullanım Koşulları",
            "about": "Hakkında",
            "version": "Versiyon"
        ],
        
        "en": [
            // General
            "app_name": "My City",
            "ok": "OK",
            "cancel": "Cancel",
            "save": "Save",
            "delete": "Delete",
            "edit": "Edit",
            "loading": "Loading...",
            "error": "Error",
            "success": "Success",
            "retry": "Retry",
            "close": "Close",
            "back": "Back",
            "next": "Next",
            "done": "Done",
            "search": "Search",
            "filter": "Filter",
            "sort": "Sort",
            "all": "All",
            "none": "None",
            "yes": "Yes",
            "no": "No",
            
            // Auth
            "login": "Login",
            "register": "Register",
            "logout": "Logout",
            "phone_number": "Phone Number",
            "enter_otp": "Enter OTP",
            "otp_sent": "Code sent",
            "verify": "Verify",
            "name": "Full Name",
            "email": "Email",
            "city": "City",
            "district": "District",
            
            // Home
            "home": "Home",
            "categories": "Categories",
            "nearby": "Nearby",
            "popular": "Popular",
            "campaigns": "Campaigns",
            "favorites": "Favorites",
            "orders": "Orders",
            "profile": "Profile",
            "wallet": "Wallet",
            
            // Store
            "stores": "Stores",
            "store_detail": "Store Detail",
            "products": "Products",
            "add_to_cart": "Add to Cart",
            "view_cart": "View Cart",
            "min_order": "Min. Order",
            "delivery_fee": "Delivery Fee",
            "delivery_time": "Delivery Time",
            "open": "Open",
            "closed": "Closed",
            "busy": "Busy",
            
            // Cart
            "cart": "Cart",
            "empty_cart": "Cart is Empty",
            "checkout": "Checkout",
            "subtotal": "Subtotal",
            "total": "Total",
            "apply_coupon": "Apply Coupon",
            "coupon_code": "Coupon Code",
            
            // Order
            "order_placed": "Order Placed",
            "order_confirmed": "Order Confirmed",
            "preparing": "Preparing",
            "on_the_way": "On The Way",
            "delivered": "Delivered",
            "cancelled": "Cancelled",
            "track_order": "Track Order",
            "order_history": "Order History",
            "reorder": "Reorder",
            
            // Taxi
            "taxi": "Taxi",
            "call_taxi": "Call Taxi",
            "pickup_location": "Pickup Location",
            "dropoff_location": "Dropoff Location",
            "estimated_fare": "Estimated Fare",
            "find_driver": "Find Driver",
            "driver_coming": "Driver Coming",
            "trip_started": "Trip Started",
            "trip_ended": "Trip Ended",
            
            // Courier
            "courier": "Courier",
            "call_courier": "Call Courier",
            "package_details": "Package Details",
            "pickup_address": "Pickup Address",
            "delivery_address": "Delivery Address",
            
            // Chat
            "chat": "Messages",
            "send_message": "Send Message",
            "type_message": "Type a message...",
            
            // Rating
            "rate_order": "Rate Order",
            "rate_driver": "Rate Driver",
            "rate_courier": "Rate Courier",
            "add_comment": "Add Comment",
            "submit_review": "Submit",
            
            // Support
            "support": "Support",
            "help": "Help",
            "report_problem": "Report Problem",
            "faq": "FAQ",
            "contact_us": "Contact Us",
            
            // Settings
            "settings": "Settings",
            "notifications": "Notifications",
            "language": "Language",
            "privacy": "Privacy",
            "terms": "Terms of Service",
            "about": "About",
            "version": "Version"
        ],
        
        "ar": [
            "app_name": "مدينتي",
            "ok": "موافق",
            "cancel": "إلغاء",
            "save": "حفظ",
            "loading": "جار التحميل...",
            "home": "الرئيسية",
            "orders": "الطلبات",
            "profile": "الملف الشخصي",
            "cart": "السلة",
            "search": "بحث"
        ],
        
        "ku": [
            "app_name": "Bajarê Min",
            "ok": "Baş e",
            "cancel": "Betal bike",
            "save": "Tomar bike",
            "loading": "Tê barkirin...",
            "home": "Destpêk",
            "orders": "Siparîş",
            "profile": "Profîl",
            "cart": "Sele",
            "search": "Lêgerîn"
        ]
    ]
}
