import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshTokenKey = "refreshToken"
        static let userId = "userId"
        static let userName = "userName"
        static let userPhone = "userPhone"
        static let userRole = "userRole"
    }
    
    var accessToken: String? {
        get { defaults.string(forKey: Keys.accessToken) }
        set { defaults.set(newValue, forKey: Keys.accessToken) }
    }
    
    private var refreshTokenValue: String? {
        get { defaults.string(forKey: Keys.refreshTokenKey) }
        set { defaults.set(newValue, forKey: Keys.refreshTokenKey) }
    }
    
    var userName: String? {
        get { defaults.string(forKey: Keys.userName) }
        set { defaults.set(newValue, forKey: Keys.userName) }
    }
    
    var userPhone: String? {
        get { defaults.string(forKey: Keys.userPhone) }
        set { defaults.set(newValue, forKey: Keys.userPhone) }
    }
    
    init() {
        isLoggedIn = accessToken != nil
    }
    
    func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshTokenValue = refreshToken
        DispatchQueue.main.async {
            self.isLoggedIn = true
        }
    }
    
    func saveUser(_ user: User) {
        defaults.set(user.id, forKey: Keys.userId)
        defaults.set(user.name, forKey: Keys.userName)
        defaults.set(user.phone, forKey: Keys.userPhone)
        defaults.set(user.role, forKey: Keys.userRole)
        
        DispatchQueue.main.async {
            self.currentUser = user
        }
    }
    
    func logout() {
        accessToken = nil
        refreshTokenValue = nil
        defaults.removeObject(forKey: Keys.userId)
        defaults.removeObject(forKey: Keys.userName)
        defaults.removeObject(forKey: Keys.userPhone)
        defaults.removeObject(forKey: Keys.userRole)
        
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.currentUser = nil
        }
    }
    
    func refreshToken() async -> Bool {
        guard let refreshToken = refreshTokenValue else { return false }
        
        do {
            struct RefreshRequest: Codable {
                let refreshToken: String
            }
            
            let response: AuthResponse = try await NetworkManager.shared.request(
                endpoint: "/auth/refresh",
                method: .post,
                body: RefreshRequest(refreshToken: refreshToken),
                requiresAuth: false
            )
            
            if let newAccessToken = response.accessToken,
               let newRefreshToken = response.refreshToken {
                saveTokens(accessToken: newAccessToken, refreshToken: newRefreshToken)
                return true
            }
            return false
        } catch {
            logout()
            return false
        }
    }
}
