import Foundation
import Combine

// MARK: - Rating/Review Manager
class RatingManager: ObservableObject {
    static let shared = RatingManager()
    
    @Published var pendingRatings: [PendingRating] = []
    @Published var userReviews: [UserReview] = []
    
    private let pendingKey = "pending_ratings"
    private let reviewsKey = "user_reviews"
    
    init() {
        loadData()
    }
    
    // MARK: - Submit Rating
    func submitRating(
        type: RatingType,
        targetId: String,
        targetName: String,
        orderId: String? = nil,
        rideId: String? = nil,
        rating: Int,
        comment: String?,
        tags: [String] = []
    ) -> UserReview {
        let review = UserReview(
            id: UUID().uuidString,
            userId: AuthManager.shared.currentUser?.id ?? "",
            type: type,
            targetId: targetId,
            targetName: targetName,
            orderId: orderId,
            rideId: rideId,
            rating: rating,
            comment: comment,
            tags: tags,
            isApproved: false, // Needs moderation
            createdAt: Date()
        )
        
        userReviews.insert(review, at: 0)
        
        // Remove from pending if exists
        pendingRatings.removeAll { $0.targetId == targetId && $0.type == type }
        
        saveData()
        
        // TODO: Sync with backend
        // NetworkManager.shared.submitReview(review)
        
        return review
    }
    
    // MARK: - Add Pending Rating
    func addPendingRating(
        type: RatingType,
        targetId: String,
        targetName: String,
        targetImage: String?,
        orderId: String? = nil,
        rideId: String? = nil
    ) {
        // Check if already exists
        guard !pendingRatings.contains(where: { $0.targetId == targetId && $0.type == type }) else { return }
        
        let pending = PendingRating(
            id: UUID().uuidString,
            type: type,
            targetId: targetId,
            targetName: targetName,
            targetImage: targetImage,
            orderId: orderId,
            rideId: rideId,
            createdAt: Date()
        )
        
        pendingRatings.append(pending)
        saveData()
    }
    
    // MARK: - Skip Rating
    func skipRating(pendingId: String) {
        pendingRatings.removeAll { $0.id == pendingId }
        saveData()
    }
    
    // MARK: - Get Average Rating
    func getAverageRating(for targetId: String, type: RatingType) -> Double {
        let reviews = userReviews.filter { $0.targetId == targetId && $0.type == type && $0.isApproved }
        guard !reviews.isEmpty else { return 0 }
        
        let total = reviews.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(reviews.count)
    }
    
    // MARK: - Persistence
    private func saveData() {
        if let pendingData = try? JSONEncoder().encode(pendingRatings) {
            UserDefaults.standard.set(pendingData, forKey: pendingKey)
        }
        if let reviewsData = try? JSONEncoder().encode(userReviews) {
            UserDefaults.standard.set(reviewsData, forKey: reviewsKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: pendingKey),
           let saved = try? JSONDecoder().decode([PendingRating].self, from: data) {
            pendingRatings = saved
        }
        if let data = UserDefaults.standard.data(forKey: reviewsKey),
           let saved = try? JSONDecoder().decode([UserReview].self, from: data) {
            userReviews = saved
        }
    }
}

// MARK: - Rating Models
struct PendingRating: Codable, Identifiable {
    let id: String
    let type: RatingType
    let targetId: String
    let targetName: String
    let targetImage: String?
    let orderId: String?
    let rideId: String?
    let createdAt: Date
}

struct UserReview: Codable, Identifiable {
    let id: String
    let userId: String
    let type: RatingType
    let targetId: String
    let targetName: String
    let orderId: String?
    let rideId: String?
    let rating: Int
    let comment: String?
    let tags: [String]
    var isApproved: Bool
    let createdAt: Date
}

enum RatingType: String, Codable {
    case vendor = "vendor"
    case courier = "courier"
    case taxi = "taxi"
    case product = "product"
    
    var displayName: String {
        switch self {
        case .vendor: return "Mağaza"
        case .courier: return "Kurye"
        case .taxi: return "Taksi"
        case .product: return "Ürün"
        }
    }
}

// MARK: - Rating Tags
struct RatingTags {
    static let positive = [
        "Hızlı teslimat",
        "Kaliteli ürün",
        "Güler yüzlü",
        "Temiz paket",
        "Doğru sipariş",
        "İyi iletişim"
    ]
    
    static let negative = [
        "Geç teslimat",
        "Eksik ürün",
        "Soğuk yemek",
        "Hasarlı paket",
        "Yanlış sipariş",
        "Kötü davranış"
    ]
    
    static func tagsFor(rating: Int) -> [String] {
        return rating >= 4 ? positive : negative
    }
}
