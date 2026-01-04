import Foundation

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = "http://localhost:3000/v1"
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Generic Request
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            // Token expired - try to refresh
            if await AuthManager.shared.refreshToken() {
                return try await self.request(endpoint: endpoint, method: method, body: body, requiresAuth: requiresAuth)
            } else {
                throw NetworkError.unauthorized
            }
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let error = try? JSONDecoder().decode(ApiError.self, from: data) {
                throw error
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Auth Endpoints
    func sendOtp(phone: String) async throws -> SendOtpResponse {
        return try await request(
            endpoint: "/auth/send-otp",
            method: .post,
            body: SendOtpRequest(phone: phone),
            requiresAuth: false
        )
    }
    
    func verifyOtp(phone: String, otp: String) async throws -> AuthResponse {
        return try await request(
            endpoint: "/auth/verify-otp",
            method: .post,
            body: VerifyOtpRequest(phone: phone, otp: otp),
            requiresAuth: false
        )
    }
    
    func register(phone: String, name: String, email: String?, cityId: String, districtId: String?) async throws -> AuthResponse {
        return try await request(
            endpoint: "/auth/register",
            method: .post,
            body: RegisterRequest(phone: phone, name: name, email: email, cityId: cityId, districtId: districtId),
            requiresAuth: false
        )
    }
    
    // MARK: - Store Endpoints
    func getStores(categoryId: String? = nil, page: Int = 1) async throws -> PaginatedResponse<Store> {
        var endpoint = "/stores?page=\(page)"
        if let categoryId = categoryId {
            endpoint += "&categoryId=\(categoryId)"
        }
        return try await request(endpoint: endpoint)
    }
    
    func getStore(id: String) async throws -> StoreDetail {
        return try await request(endpoint: "/stores/\(id)")
    }
    
    // MARK: - Category Endpoints
    func getCategories() async throws -> [Category] {
        return try await request(endpoint: "/categories")
    }
    
    // MARK: - Order Endpoints
    func getOrders() async throws -> [Order] {
        return try await request(endpoint: "/orders")
    }
    
    func getOrder(id: String) async throws -> OrderDetail {
        return try await request(endpoint: "/orders/\(id)")
    }
    
    // MARK: - Taxi Endpoints
    func getNearbyDrivers(lat: Double, lng: Double) async throws -> [NearbyDriver] {
        return try await request(endpoint: "/taxi/nearby?lat=\(lat)&lng=\(lng)")
    }
    
    func estimateFare(pickupLat: Double, pickupLng: Double, dropLat: Double, dropLng: Double) async throws -> FareEstimate {
        struct EstimateRequest: Codable {
            let pickupLatitude: Double
            let pickupLongitude: Double
            let dropLatitude: Double
            let dropLongitude: Double
        }
        return try await request(
            endpoint: "/taxi/estimate",
            method: .post,
            body: EstimateRequest(
                pickupLatitude: pickupLat,
                pickupLongitude: pickupLng,
                dropLatitude: dropLat,
                dropLongitude: dropLng
            )
        )
    }
    
    func getRides() async throws -> [Ride] {
        return try await request(endpoint: "/taxi/rides")
    }
    
    // MARK: - Cities
    func getCities() async throws -> [City] {
        return try await request(endpoint: "/cities", requiresAuth: false)
    }
    
    func getDistricts(cityId: String) async throws -> [District] {
        return try await request(endpoint: "/cities/\(cityId)/districts", requiresAuth: false)
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
