import Foundation
import Combine

/// Favorites Manager - Handles favorite vendors, drivers, and products
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favoriteVendors: [FavoriteEntity] = []
    @Published var favoriteDrivers: [FavoriteEntity] = []
    @Published var favoriteProducts: [FavoriteEntity] = []
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "user_favorites"
    
    init() {
        loadFavorites()
    }
    
    // MARK: - Add/Remove Favorites
    
    func addFavorite(type: FavoriteType, entityId: String, entityName: String, entityImage: String?) {
        let favorite = FavoriteEntity(
            id: UUID().uuidString,
            userId: AuthManager.shared.currentUser?.id ?? "",
            entityType: type,
            entityId: entityId,
            entityName: entityName,
            entityImage: entityImage,
            createdAt: Date()
        )
        
        switch type {
        case .vendor:
            if !favoriteVendors.contains(where: { $0.entityId == entityId }) {
                favoriteVendors.append(favorite)
            }
        case .driver:
            if !favoriteDrivers.contains(where: { $0.entityId == entityId }) {
                favoriteDrivers.append(favorite)
            }
        case .product:
            if !favoriteProducts.contains(where: { $0.entityId == entityId }) {
                favoriteProducts.append(favorite)
            }
        }
        
        saveFavorites()
    }
    
    func removeFavorite(type: FavoriteType, entityId: String) {
        switch type {
        case .vendor:
            favoriteVendors.removeAll { $0.entityId == entityId }
        case .driver:
            favoriteDrivers.removeAll { $0.entityId == entityId }
        case .product:
            favoriteProducts.removeAll { $0.entityId == entityId }
        }
        
        saveFavorites()
    }
    
    func toggleFavorite(type: FavoriteType, entityId: String, entityName: String, entityImage: String?) {
        if isFavorite(type: type, entityId: entityId) {
            removeFavorite(type: type, entityId: entityId)
        } else {
            addFavorite(type: type, entityId: entityId, entityName: entityName, entityImage: entityImage)
        }
    }
    
    func isFavorite(type: FavoriteType, entityId: String) -> Bool {
        switch type {
        case .vendor:
            return favoriteVendors.contains { $0.entityId == entityId }
        case .driver:
            return favoriteDrivers.contains { $0.entityId == entityId }
        case .product:
            return favoriteProducts.contains { $0.entityId == entityId }
        }
    }
    
    // MARK: - Get Favorites
    
    var allFavorites: [FavoriteEntity] {
        return favoriteVendors + favoriteDrivers + favoriteProducts
    }
    
    var favoriteVendorIds: [String] {
        return favoriteVendors.map { $0.entityId }
    }
    
    var favoriteDriverIds: [String] {
        return favoriteDrivers.map { $0.entityId }
    }
    
    // MARK: - Persistence
    
    private func saveFavorites() {
        let allFavorites = self.allFavorites
        if let data = try? JSONEncoder().encode(allFavorites) {
            userDefaults.set(data, forKey: favoritesKey)
        }
    }
    
    private func loadFavorites() {
        guard let data = userDefaults.data(forKey: favoritesKey),
              let favorites = try? JSONDecoder().decode([FavoriteEntity].self, from: data) else {
            return
        }
        
        favoriteVendors = favorites.filter { $0.entityType == .vendor }
        favoriteDrivers = favorites.filter { $0.entityType == .driver }
        favoriteProducts = favorites.filter { $0.entityType == .product }
    }
    
    func clearAll() {
        favoriteVendors.removeAll()
        favoriteDrivers.removeAll()
        favoriteProducts.removeAll()
        userDefaults.removeObject(forKey: favoritesKey)
    }
}
