import Foundation
import UIKit
import Combine

/// Network manager with security features
class SecureNetworkManager: ObservableObject {
    static let shared = SecureNetworkManager()
    
    // MARK: - Properties
    
    private let session: URLSession
    private let baseURL: String
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    
    #if DEBUG
    private let isDebug = true
    #else
    private let isDebug = false
    #endif
    
    // MARK: - Initialization
    
    private init() {
        // Use secure session with SSL pinning
        self.session = URLSession.createSecureSession()
        
        // Load base URL from configuration
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
            self.baseURL = url
        } else {
            self.baseURL = isDebug ? "http://localhost:3000/v1" : "https://api.benimsehrim.com/v1"
        }
    }
    
    // MARK: - Request Methods
    
    /// Perform GET request
    func get<T: Decodable>(
        endpoint: String,
        parameters: [String: String]? = nil
    ) async throws -> T {
        var urlComponents = URLComponents(string: baseURL + endpoint)
        
        if let parameters = parameters {
            urlComponents?.queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        // Add headers
        addCommonHeaders(to: &request)
        
        return try await performRequest(request)
    }
    
    /// Perform POST request
    func post<T: Decodable, B: Encodable>(
        endpoint: String,
        body: B
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        // Add headers
        addCommonHeaders(to: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode body
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)
        
        return try await performRequest(request)
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        // Log request in debug mode
        if isDebug {
            print("📡 Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Log response in debug mode
        if isDebug {
            print("📥 Response: \(httpResponse.statusCode)")
        }
        
        // Check status code
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            if isDebug {
                print("❌ Decode error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response data: \(jsonString)")
                }
            }
            throw NetworkError.decodingError(error)
        }
    }
    
    private func addCommonHeaders(to request: inout URLRequest) {
        // Add auth token if available
        if let token = SecureStorageManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add device info
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        request.setValue(UIDevice.current.systemVersion, forHTTPHeaderField: "X-OS-Version")
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        }
        
        // Add request ID for tracking
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
    }
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case noData
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Geçersiz yanıt"
        case .httpError(let statusCode):
            return "HTTP Hatası: \(statusCode)"
        case .decodingError(let error):
            return "Veri çözümleme hatası: \(error.localizedDescription)"
        case .noData:
            return "Veri bulunamadı"
        case .unauthorized:
            return "Yetkisiz erişim"
        }
    }
}

// MARK: - Image Caching

extension SecureNetworkManager {
    /// Load image with caching
    func loadImage(from urlString: String) async throws -> UIImage {
        // Check cache first
        if let cachedImage = ImageCache.shared.get(forKey: urlString) {
            return cachedImage
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw NetworkError.noData
        }
        
        // Cache image
        ImageCache.shared.set(image, forKey: urlString)
        
        return image
    }
}

// MARK: - Image Cache

class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}
