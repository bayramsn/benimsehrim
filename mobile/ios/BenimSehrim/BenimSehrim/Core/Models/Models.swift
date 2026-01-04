import Foundation

// MARK: - Auth Models
struct SendOtpRequest: Codable {
    let phone: String
}

struct SendOtpResponse: Codable {
    let success: Bool
    let message: String
    let expiresIn: Int?
    let isNewUser: Bool?
    
    enum CodingKeys: String, CodingKey {
        case success, message
        case expiresIn = "expires_in"
        case isNewUser
    }
}

struct VerifyOtpRequest: Codable {
    let phone: String
    let otp: String
}

struct RegisterRequest: Codable {
    let phone: String
    let name: String
    let email: String?
    let cityId: String
    let districtId: String?
}

struct AuthResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let user: User?
    let isNewUser: Bool?
    let phone: String?
    let message: String?
}

// MARK: - User Models
struct User: Codable, Identifiable {
    let id: String
    let phone: String
    let name: String?
    let email: String?
    let avatarUrl: String?
    let role: String
    let city: City?
    let district: District?
    let balance: Double?
    let createdAt: String?
}

struct Address: Codable, Identifiable {
    let id: String
    let title: String
    let address: String
    let latitude: Double
    let longitude: Double
    let note: String?
    let isDefault: Bool
}

// MARK: - Location Models
struct City: Codable, Identifiable {
    let id: String
    let name: String
    let code: String
    let isActive: Bool
}

struct District: Codable, Identifiable {
    let id: String
    let name: String
    let cityId: String
    let isActive: Bool
}

// MARK: - Store Models
struct Store: Codable, Identifiable {
    let id: String
    let name: String
    let logoUrl: String?
    let bannerUrl: String?
    let rating: Double
    let reviewCount: Int
    let isOpen: Bool
    let distance: Double?
    let deliveryTime: String?
    let minOrder: Double
    let deliveryFee: Double
    let categories: [Category]?
    let isFavorite: Bool?
}

struct StoreDetail: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let logoUrl: String?
    let bannerUrl: String?
    let address: String
    let phone: String?
    let rating: Double
    let reviewCount: Int
    let isOpen: Bool
    let openTime: String
    let closeTime: String
    let paymentTypes: [String]
    let minOrder: Double
    let deliveryFee: Double
    let products: [Product]
    let campaigns: [Campaign]
}

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String?
    let sortOrder: Int?
    let color: String?
    
    init(id: String, name: String, icon: String? = nil, sortOrder: Int? = nil, color: String? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.color = color
    }
}

// MARK: - Product Models
struct Product: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let price: Double
    let stock: Int
    let unit: String?
    let images: [String]
    let isActive: Bool
    let campaigns: [Campaign]?
}

struct Campaign: Codable, Identifiable {
    let id: String
    let type: String
    let value: Double
    let startDate: String
    let endDate: String
    let stockLimit: Int?
    let remainingStock: Int?
    let product: Product?
    let store: Store?
}

// MARK: - Order Models
struct Order: Codable, Identifiable {
    let id: String
    let orderNo: String
    let store: Store
    let status: String
    let total: Double
    let itemCount: Int?
    let createdAt: String
}

struct OrderDetail: Codable, Identifiable {
    let id: String
    let orderNo: String
    let store: Store
    let status: String
    let items: [OrderItem]
    let subtotal: Double
    let discount: Double
    let deliveryFee: Double
    let total: Double
    let address: Address
    let paymentType: String
    let courier: Courier?
    let timeline: [OrderTimeline]
    let chatEnabled: Bool
    let createdAt: String
}

struct OrderItem: Codable, Identifiable {
    let id: String
    let product: Product
    let quantity: Int
    let unitPrice: Double
    let totalPrice: Double
}

struct OrderTimeline: Codable {
    let status: String
    let time: String
    let note: String?
}

struct Courier: Codable, Identifiable {
    let id: String
    let name: String?
    let phone: String?
    let latitude: Double?
    let longitude: Double?
}

// MARK: - Taxi Models
struct FareEstimate: Codable {
    let distance: Double
    let duration: Int
    let estimatedFare: FareRange
    let nearbyDrivers: Int
}

struct FareRange: Codable {
    let min: Double
    let max: Double
}

struct NearbyDriver: Codable, Identifiable {
    let id: String
    let latitude: Double
    let longitude: Double
    let distance: Double?
}

struct Ride: Codable, Identifiable {
    let id: String
    let status: String
    let pickupAddress: String
    let dropAddress: String
    let estimatedFare: FareRange?
    let createdAt: String
}

struct Driver: Codable, Identifiable {
    let id: String
    let name: String?
    let phone: String?
    let photoUrl: String?
    let rating: Double
    let vehicle: Vehicle?
    let latitude: Double?
    let longitude: Double?
}

struct Vehicle: Codable {
    let plate: String
    let model: String?
    let color: String?
}

// MARK: - Chat Models
struct Chat: Codable, Identifiable {
    let id: String
    let type: String
    let isActive: Bool
}

struct Message: Codable, Identifiable {
    let id: String
    let senderId: String
    let senderName: String?
    let content: String
    let isMine: Bool?
    let createdAt: String
}

// MARK: - Review Models
struct Review: Codable, Identifiable {
    let id: String
    let rating: Int
    let comment: String?
    let createdAt: String
}

// MARK: - Notification Models
struct AppNotification: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String
    let isRead: Bool
    let createdAt: String
}

// MARK: - Common Models
struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let meta: PaginationMeta
}

struct PaginationMeta: Codable {
    let total: Int
    let page: Int
    let limit: Int
}

struct ApiError: Codable, Error {
    let statusCode: Int
    let message: String
    let error: String?
}
