import Foundation

// MARK: - User Role System
enum UserRole: String, Codable, CaseIterable {
    case customer = "customer"           // Normal kullanıcı
    case vendor = "vendor"               // Esnaf/Dükkan sahibi
    case taxiDriver = "taxi_driver"      // Taksi şoförü
    case courier = "courier"             // Kurye
    case admin = "admin"                 // Admin
    case superAdmin = "super_admin"      // Süper Admin
    
    var displayName: String {
        switch self {
        case .customer: return "Müşteri"
        case .vendor: return "Esnaf"
        case .taxiDriver: return "Taksi Şoförü"
        case .courier: return "Kurye"
        case .admin: return "Admin"
        case .superAdmin: return "Süper Admin"
        }
    }
    
    var icon: String {
        switch self {
        case .customer: return "person.fill"
        case .vendor: return "storefront.fill"
        case .taxiDriver: return "car.fill"
        case .courier: return "shippingbox.fill"
        case .admin: return "person.badge.shield.checkmark.fill"
        case .superAdmin: return "crown.fill"
        }
    }
    
    var color: String {
        switch self {
        case .customer: return "#2196F3"
        case .vendor: return "#4CAF50"
        case .taxiDriver: return "#FFC107"
        case .courier: return "#FF9800"
        case .admin: return "#9C27B0"
        case .superAdmin: return "#F44336"
        }
    }
    
    var permissions: [Permission] {
        switch self {
        case .customer:
            return [.viewStores, .placeOrder, .callTaxi, .callCourier, .chat, .rate]
        case .vendor:
            return [.manageStore, .manageProducts, .manageOrders, .viewStats, .chat, .createCampaign]
        case .taxiDriver:
            return [.acceptRides, .viewEarnings, .chat, .updateLocation]
        case .courier:
            return [.acceptDeliveries, .viewEarnings, .chat, .updateLocation]
        case .admin:
            return [.approveVendors, .approveDrivers, .viewAllStats, .moderateContent, .manageUsers, .viewCrisis]
        case .superAdmin:
            return Permission.allCases // Tüm yetkiler
        }
    }
    
    var isProvider: Bool {
        return self == .vendor || self == .taxiDriver || self == .courier
    }
    
    var isAdmin: Bool {
        return self == .admin || self == .superAdmin
    }
}

// MARK: - Permissions
enum Permission: String, Codable, CaseIterable {
    // Customer
    case viewStores = "view_stores"
    case placeOrder = "place_order"
    case callTaxi = "call_taxi"
    case callCourier = "call_courier"
    case chat = "chat"
    case rate = "rate"
    
    // Vendor
    case manageStore = "manage_store"
    case manageProducts = "manage_products"
    case manageOrders = "manage_orders"
    case viewStats = "view_stats"
    case createCampaign = "create_campaign"
    
    // Driver/Courier
    case acceptRides = "accept_rides"
    case acceptDeliveries = "accept_deliveries"
    case viewEarnings = "view_earnings"
    case updateLocation = "update_location"
    
    // Admin
    case approveVendors = "approve_vendors"
    case approveDrivers = "approve_drivers"
    case viewAllStats = "view_all_stats"
    case moderateContent = "moderate_content"
    case manageUsers = "manage_users"
    case viewCrisis = "view_crisis"
    
    // Super Admin Only
    case manageAdmins = "manage_admins"
    case manageCities = "manage_cities"
    case manageSettings = "manage_settings"
    case viewFinancials = "view_financials"
    case deleteData = "delete_data"
    case systemConfig = "system_config"
}

// MARK: - Provider Profile Models
struct VendorProfile: Codable, Identifiable {
    let id: String
    let userId: String
    var storeName: String
    var storeDescription: String?
    var storeAddress: String
    var storePhone: String
    var storeLogo: String?
    var storeBanner: String?
    var categoryId: String
    var latitude: Double
    var longitude: Double
    var openTime: String
    var closeTime: String
    var minOrderAmount: Double
    var deliveryFee: Double
    var isApproved: Bool
    var isActive: Bool
    var approvedAt: Date?
    var approvedBy: String?
    let createdAt: Date
    
    // Documents
    var taxDocument: String?
    var identityDocument: String?
    var businessLicense: String?
}

struct TaxiDriverProfile: Codable, Identifiable {
    let id: String
    let userId: String
    var fullName: String
    var phone: String
    var avatar: String?
    var licenseNumber: String
    var licenseExpiry: Date
    var vehiclePlate: String
    var vehicleModel: String
    var vehicleColor: String
    var vehicleYear: Int
    var isApproved: Bool
    var isActive: Bool
    var approvedAt: Date?
    var approvedBy: String?
    let createdAt: Date
    
    // Documents
    var driverLicense: String?
    var vehicleRegistration: String?
    var insurance: String?
    var criminalRecord: String?
}

struct CourierProfile: Codable, Identifiable {
    let id: String
    let userId: String
    var fullName: String
    var phone: String
    var avatar: String?
    var vehicleType: VehicleType
    var vehiclePlate: String?
    var isApproved: Bool
    var isActive: Bool
    var approvedAt: Date?
    var approvedBy: String?
    let createdAt: Date
    
    // Documents
    var identityDocument: String?
    var driverLicense: String?
}

// MARK: - Super Admin
struct SuperAdminConfig: Codable {
    static let superAdminPhone = "+905551234567" // Süper admin telefon numarası
    static let superAdminId = "super_admin_001"
    
    var systemSettings: SystemSettings
    var cityConfigs: [CityConfig]
    var adminList: [AdminUser]
}

struct SystemSettings: Codable {
    var appName: String
    var supportEmail: String
    var supportPhone: String
    var defaultCity: String
    var maintenanceMode: Bool
    var minAppVersion: String
    var commissionRate: Double // Platform komisyonu %
    var taxRate: Double // KDV %
}

struct CityConfig: Codable, Identifiable {
    let id: String
    var cityName: String
    var cityCode: String
    var isActive: Bool
    var deliveryFeeBase: Double
    var deliveryFeePerKm: Double
    var taxiFareBase: Double
    var taxiFarePerKm: Double
    var taxiFarePerMinute: Double
    var courierFeeBase: Double
    var courierFeePerKm: Double
    var operatingHoursStart: Int
    var operatingHoursEnd: Int
}

struct AdminUser: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var phone: String
    var email: String?
    var role: UserRole
    var permissions: [Permission]
    var isActive: Bool
    var createdAt: Date
    var createdBy: String // Super admin tarafından oluşturuldu
}

// MARK: - Provider Registration Request
struct ProviderRegistrationRequest: Codable {
    let userId: String
    let providerType: UserRole
    let fullName: String
    let phone: String
    let email: String?
    let address: String?
    
    // Vendor specific
    var storeName: String?
    var storeCategory: String?
    
    // Driver specific
    var licenseNumber: String?
    var vehiclePlate: String?
    var vehicleModel: String?
    
    // Documents
    var documents: [String: String] // document_type: url
    
    let createdAt: Date
    var status: RegistrationStatus
    var reviewedAt: Date?
    var reviewedBy: String?
    var rejectionReason: String?
}

enum RegistrationStatus: String, Codable {
    case pending = "pending"
    case underReview = "under_review"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "Beklemede"
        case .underReview: return "İnceleniyor"
        case .approved: return "Onaylandı"
        case .rejected: return "Reddedildi"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "#FF9800"
        case .underReview: return "#2196F3"
        case .approved: return "#4CAF50"
        case .rejected: return "#F44336"
        }
    }
}
