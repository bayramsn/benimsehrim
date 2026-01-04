import Foundation
import CoreLocation

// MARK: - Availability Status (Hazırım Butonu)
enum AvailabilityStatus: String, Codable, CaseIterable {
    case available = "available"      // Hazırım / Müsaitim
    case busy = "busy"                // Meşgulüm
    case offline = "offline"          // Çevrimdışı
    case onBreak = "on_break"         // Molada
    
    var displayName: String {
        switch self {
        case .available: return "Hazırım"
        case .busy: return "Meşgulüm"
        case .offline: return "Çevrimdışı"
        case .onBreak: return "Molada"
        }
    }
    
    var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .busy: return "clock.fill"
        case .offline: return "moon.fill"
        case .onBreak: return "cup.and.saucer.fill"
        }
    }
    
    var color: String {
        switch self {
        case .available: return "#4CAF50"
        case .busy: return "#FF9800"
        case .offline: return "#9E9E9E"
        case .onBreak: return "#2196F3"
        }
    }
}

// MARK: - Traffic/Yoğunluk Status
enum TrafficLevel: String, Codable {
    case calm = "calm"           // Sakin
    case normal = "normal"       // Normal
    case busy = "busy"           // Yoğun
    case veryBusy = "very_busy"  // Çok Yoğun
    
    var displayName: String {
        switch self {
        case .calm: return "Sakin"
        case .normal: return "Normal"
        case .busy: return "Yoğun"
        case .veryBusy: return "Çok Yoğun"
        }
    }
    
    var warningMessage: String? {
        switch self {
        case .busy: return "Bu işletme şu an yoğun, teslimat gecikmesi olabilir."
        case .veryBusy: return "Bu işletme çok yoğun, 30+ dakika gecikme olabilir."
        default: return nil
        }
    }
    
    var color: String {
        switch self {
        case .calm: return "#4CAF50"
        case .normal: return "#2196F3"
        case .busy: return "#FF9800"
        case .veryBusy: return "#F44336"
        }
    }
}

// MARK: - Vendor/Esnaf Model
struct Vendor: Codable, Identifiable {
    let id: String
    let name: String
    let phone: String
    let email: String?
    let logoUrl: String?
    let bannerUrl: String?
    let categoryId: String
    let address: String
    let latitude: Double
    let longitude: Double
    var isOpen: Bool
    var availabilityStatus: AvailabilityStatus
    var trafficLevel: TrafficLevel
    let rating: Double
    let reviewCount: Int
    let minOrderAmount: Double
    let deliveryFee: Double
    let deliveryTimeMin: Int
    let deliveryTimeMax: Int
    var isFavorite: Bool
    let createdAt: String
    
    // Daily stats
    var todayOrderCount: Int?
    var todayRevenue: Double?
    var todayTopProduct: String?
    
    // Performance score (hidden)
    var performanceScore: Int?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Extended Driver (Taksi/Kurye) Model with Business Features
struct ExtendedDriver: Codable, Identifiable {
    let id: String
    let name: String
    let phone: String
    let avatarUrl: String?
    let vehicleType: VehicleType
    let vehiclePlate: String?
    let driverType: DriverType
    var availabilityStatus: AvailabilityStatus
    var currentLocation: LocationPoint?
    let rating: Double
    let reviewCount: Int
    var isFavorite: Bool
    let createdAt: String
    
    // Daily stats
    var todayJobCount: Int?
    var dailyGoal: Int?
    
    // Break/Rest mode
    var breakEndTime: Date?
    
    // Performance score (hidden)
    var performanceScore: Int?
}

struct LocationPoint: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum VehicleType: String, Codable {
    case car = "car"
    case motorcycle = "motorcycle"
    case bicycle = "bicycle"
    case walking = "walking"
    
    var displayName: String {
        switch self {
        case .car: return "Otomobil"
        case .motorcycle: return "Motosiklet"
        case .bicycle: return "Bisiklet"
        case .walking: return "Yaya"
        }
    }
    
    var icon: String {
        switch self {
        case .car: return "car.fill"
        case .motorcycle: return "bicycle"
        case .bicycle: return "bicycle"
        case .walking: return "figure.walk"
        }
    }
}

enum DriverType: String, Codable {
    case taxi = "taxi"
    case courier = "courier"
    case both = "both"
    
    var displayName: String {
        switch self {
        case .taxi: return "Taksi"
        case .courier: return "Kurye"
        case .both: return "Taksi & Kurye"
        }
    }
}

// MARK: - Crisis Alert (Sessiz Kriz Alarmı)
struct CrisisAlert: Codable, Identifiable {
    let id: String
    let type: CrisisType
    let targetId: String
    let targetName: String
    let targetType: String // vendor, driver
    let count: Int
    let threshold: Int
    let message: String
    let severity: AlertSeverity
    let createdAt: Date
    var isResolved: Bool
    var resolvedAt: Date?
    var resolvedBy: String?
    var adminNote: String?
}

enum CrisisType: String, Codable {
    case multipleCancel = "multiple_cancel"       // Çoklu iptal
    case multipleDelay = "multiple_delay"         // Çoklu gecikme
    case multipleReject = "multiple_reject"       // Çoklu red
    case lowRating = "low_rating"                 // Düşük puan
    case customerComplaint = "customer_complaint" // Müşteri şikayeti
    
    var displayName: String {
        switch self {
        case .multipleCancel: return "Çoklu İptal"
        case .multipleDelay: return "Çoklu Gecikme"
        case .multipleReject: return "Çoklu Red"
        case .lowRating: return "Düşük Puan"
        case .customerComplaint: return "Müşteri Şikayeti"
        }
    }
    
    var icon: String {
        switch self {
        case .multipleCancel: return "xmark.circle.fill"
        case .multipleDelay: return "clock.badge.exclamationmark.fill"
        case .multipleReject: return "hand.raised.fill"
        case .lowRating: return "star.slash.fill"
        case .customerComplaint: return "exclamationmark.bubble.fill"
        }
    }
}

enum AlertSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var color: String {
        switch self {
        case .low: return "#4CAF50"
        case .medium: return "#FF9800"
        case .high: return "#F44336"
        case .critical: return "#9C27B0"
        }
    }
}

// MARK: - Daily Summary (Gün Sonu Özet)
struct DailySummary: Codable {
    let date: Date
    let orderCount: Int
    let completedCount: Int
    let cancelledCount: Int
    let totalRevenue: Double
    let averageOrderValue: Double
    let topProducts: [TopProduct]
    let peakHours: [Int]
    let newCustomers: Int
    let repeatCustomers: Int
}

struct TopProduct: Codable, Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let revenue: Double
}

// MARK: - Product Suggestion (Ürün Önerisi)
struct ProductSuggestion: Codable, Identifiable {
    let id: String
    let productId: String
    let productName: String
    let type: SuggestionType
    let message: String
    let createdAt: Date
}

enum SuggestionType: String, Codable {
    case noSales = "no_sales"           // Satılmayan ürün
    case lowStock = "low_stock"         // Düşük stok
    case campaignEligible = "campaign"  // Kampanyaya uygun
    case priceOptimization = "price"    // Fiyat optimizasyonu
    
    var displayName: String {
        switch self {
        case .noSales: return "Satış Yok"
        case .lowStock: return "Düşük Stok"
        case .campaignEligible: return "Kampanya Önerisi"
        case .priceOptimization: return "Fiyat Önerisi"
        }
    }
    
    var icon: String {
        switch self {
        case .noSales: return "chart.line.downtrend.xyaxis"
        case .lowStock: return "exclamationmark.triangle.fill"
        case .campaignEligible: return "tag.fill"
        case .priceOptimization: return "turkishlirasign.circle.fill"
        }
    }
}

// MARK: - Favorite Entity
struct FavoriteEntity: Codable, Identifiable {
    let id: String
    let userId: String
    let entityType: FavoriteType
    let entityId: String
    let entityName: String
    let entityImage: String?
    let createdAt: Date
}

enum FavoriteType: String, Codable {
    case vendor = "vendor"
    case driver = "driver"
    case product = "product"
    
    var displayName: String {
        switch self {
        case .vendor: return "Esnaf"
        case .driver: return "Şoför/Kurye"
        case .product: return "Ürün"
        }
    }
}

// MARK: - Quick Reorder (Tekrar Sipariş)
struct QuickReorder: Codable, Identifiable {
    let id: String
    let orderId: String
    let vendorId: String
    let vendorName: String
    let vendorLogo: String?
    let items: [ReorderItem]
    let totalAmount: Double
    let lastOrderDate: Date
}

struct ReorderItem: Codable, Identifiable {
    let id: String
    let productId: String
    let name: String
    let quantity: Int
    let price: Double
}

// MARK: - Personalized Section (Bugün Sana Özel)
struct PersonalizedSection: Codable {
    let nearbyVendors: [Vendor]
    let campaignVendors: [Vendor]
    let previousVendors: [Vendor]
    let recommendedProducts: [Product]
}

// MARK: - Usage Score (Kullanım Skoru)
struct UsageScore: Codable {
    let entityId: String
    let entityType: String
    let activityScore: Int      // 0-100
    let reliabilityScore: Int   // 0-100
    let responseScore: Int      // 0-100
    let overallScore: Int       // 0-100
    let lastUpdated: Date
    
    var isRestricted: Bool {
        overallScore < 30
    }
    
    var isWarning: Bool {
        overallScore < 50
    }
}

// MARK: - City Template (Şehir Şablonu)
struct CityTemplate: Codable, Identifiable {
    let id: String
    let name: String
    let categories: [Category]
    let defaultSettings: CitySettings
    let createdAt: Date
}

struct CitySettings: Codable {
    let deliveryFeeBase: Double
    let deliveryFeePerKm: Double
    let taxiFareBase: Double
    let taxiFarePerKm: Double
    let courierFeeBase: Double
    let minimumOrderAmount: Double
    let operatingHoursStart: Int
    let operatingHoursEnd: Int
}

// MARK: - Field Note (Saha Notu - CRM Mini)
struct FieldNote: Codable, Identifiable {
    let id: String
    let targetId: String
    let targetType: String
    let targetName: String
    let note: String
    let noteType: NoteType
    let createdBy: String
    let createdAt: Date
}

enum NoteType: String, Codable {
    case general = "general"
    case warning = "warning"
    case positive = "positive"
    case followUp = "follow_up"
    
    var color: String {
        switch self {
        case .general: return "#607D8B"
        case .warning: return "#F44336"
        case .positive: return "#4CAF50"
        case .followUp: return "#2196F3"
        }
    }
}

// MARK: - Premium Features (İleride Ücretli)
struct PremiumFeature: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double?
    let isActive: Bool
    let featureType: PremiumFeatureType
}

enum PremiumFeatureType: String, Codable {
    case featuredSlot = "featured_slot"       // Öne çıkarma slotu
    case homepageShowcase = "homepage"        // Ana sayfa vitrini
    case detailedReports = "reports"          // Detaylı raporlar
    case smsCampaign = "sms_campaign"         // SMS kampanya
    case extraCampaigns = "extra_campaigns"   // Ek kampanya limiti
    
    var displayName: String {
        switch self {
        case .featuredSlot: return "Öne Çıkarma"
        case .homepageShowcase: return "Ana Sayfa Vitrini"
        case .detailedReports: return "Detaylı Raporlar"
        case .smsCampaign: return "SMS Kampanya"
        case .extraCampaigns: return "Ek Kampanya"
        }
    }
}
