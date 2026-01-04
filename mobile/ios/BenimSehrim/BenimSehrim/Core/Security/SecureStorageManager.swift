import Foundation
import LocalAuthentication

/// Secure storage manager using Keychain
class SecureStorageManager {
    static let shared = SecureStorageManager()
    
    private init() {}
    
    // MARK: - Keychain Service Name
    
    private let serviceName = "com.benimsehrim.app"
    
    // MARK: - Public Methods
    
    /// Save data to Keychain
    func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        // Delete existing item
        delete(key: key)
        
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Add to Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve data from Keychain
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Delete data from Keychain
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Clear all Keychain data
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Biometric Authentication
    
    /// Check if biometric authentication is available
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Authenticate with biometrics
    func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error)
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}

// MARK: - Convenience Keys

extension SecureStorageManager {
    enum Keys {
        static let authToken = "auth_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
        static let userPhone = "user_phone"
        static let deviceId = "device_id"
    }
    
    // MARK: - Token Management
    
    var authToken: String? {
        get { get(key: Keys.authToken) }
        set {
            if let value = newValue {
                _ = save(key: Keys.authToken, value: value)
            } else {
                _ = delete(key: Keys.authToken)
            }
        }
    }
    
    var refreshToken: String? {
        get { get(key: Keys.refreshToken) }
        set {
            if let value = newValue {
                _ = save(key: Keys.refreshToken, value: value)
            } else {
                _ = delete(key: Keys.refreshToken)
            }
        }
    }
    
    var userId: String? {
        get { get(key: Keys.userId) }
        set {
            if let value = newValue {
                _ = save(key: Keys.userId, value: value)
            } else {
                _ = delete(key: Keys.userId)
            }
        }
    }
    
    // MARK: - Session Management
    
    func clearSession() {
        authToken = nil
        refreshToken = nil
        userId = nil
    }
    
    var isAuthenticated: Bool {
        return authToken != nil
    }
}
