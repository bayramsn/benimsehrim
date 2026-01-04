import Foundation
import Combine

// MARK: - Role Manager
class RoleManager: ObservableObject {
    static let shared = RoleManager()
    
    @Published var currentRole: UserRole = .customer
    @Published var providerProfile: Any? // VendorProfile, TaxiDriverProfile, or CourierProfile
    @Published var pendingRegistration: ProviderRegistrationRequest?
    @Published var hasPermission: [Permission: Bool] = [:]
    
    private let roleKey = "user_role"
    private let providerKey = "provider_profile"
    
    init() {
        loadSavedRole()
    }
    
    // MARK: - Role Check
    func hasRole(_ role: UserRole) -> Bool {
        return currentRole == role
    }
    
    func hasAnyRole(_ roles: [UserRole]) -> Bool {
        return roles.contains(currentRole)
    }
    
    func checkPermission(_ permission: Permission) -> Bool {
        return currentRole.permissions.contains(permission)
    }
    
    var isProvider: Bool {
        return currentRole.isProvider
    }
    
    var isAdmin: Bool {
        return currentRole.isAdmin
    }
    
    var isSuperAdmin: Bool {
        return currentRole == .superAdmin
    }
    
    // MARK: - Role Management
    func setRole(_ role: UserRole) {
        currentRole = role
        UserDefaults.standard.set(role.rawValue, forKey: roleKey)
        updatePermissions()
    }
    
    private func updatePermissions() {
        hasPermission = [:]
        for permission in Permission.allCases {
            hasPermission[permission] = currentRole.permissions.contains(permission)
        }
    }
    
    private func loadSavedRole() {
        if let savedRole = UserDefaults.standard.string(forKey: roleKey),
           let role = UserRole(rawValue: savedRole) {
            currentRole = role
        }
        updatePermissions()
    }
    
    // MARK: - Provider Registration
    func registerAsVendor(
        storeName: String,
        storeCategory: String,
        address: String,
        phone: String,
        documents: [String: String]
    ) -> ProviderRegistrationRequest {
        let request = ProviderRegistrationRequest(
            userId: AuthManager.shared.currentUser?.id ?? "",
            providerType: .vendor,
            fullName: AuthManager.shared.currentUser?.name ?? "",
            phone: phone,
            email: AuthManager.shared.currentUser?.email,
            address: address,
            storeName: storeName,
            storeCategory: storeCategory,
            licenseNumber: nil,
            vehiclePlate: nil,
            vehicleModel: nil,
            documents: documents,
            createdAt: Date(),
            status: .pending,
            reviewedAt: nil,
            reviewedBy: nil,
            rejectionReason: nil
        )
        
        pendingRegistration = request
        saveRegistration(request)
        return request
    }
    
    func registerAsTaxiDriver(
        licenseNumber: String,
        vehiclePlate: String,
        vehicleModel: String,
        phone: String,
        documents: [String: String]
    ) -> ProviderRegistrationRequest {
        let request = ProviderRegistrationRequest(
            userId: AuthManager.shared.currentUser?.id ?? "",
            providerType: .taxiDriver,
            fullName: AuthManager.shared.currentUser?.name ?? "",
            phone: phone,
            email: AuthManager.shared.currentUser?.email,
            address: nil,
            storeName: nil,
            storeCategory: nil,
            licenseNumber: licenseNumber,
            vehiclePlate: vehiclePlate,
            vehicleModel: vehicleModel,
            documents: documents,
            createdAt: Date(),
            status: .pending,
            reviewedAt: nil,
            reviewedBy: nil,
            rejectionReason: nil
        )
        
        pendingRegistration = request
        saveRegistration(request)
        return request
    }
    
    func registerAsCourier(
        vehicleType: VehicleType,
        vehiclePlate: String?,
        phone: String,
        documents: [String: String]
    ) -> ProviderRegistrationRequest {
        let request = ProviderRegistrationRequest(
            userId: AuthManager.shared.currentUser?.id ?? "",
            providerType: .courier,
            fullName: AuthManager.shared.currentUser?.name ?? "",
            phone: phone,
            email: AuthManager.shared.currentUser?.email,
            address: nil,
            storeName: nil,
            storeCategory: nil,
            licenseNumber: nil,
            vehiclePlate: vehiclePlate,
            vehicleModel: nil,
            documents: documents,
            createdAt: Date(),
            status: .pending,
            reviewedAt: nil,
            reviewedBy: nil,
            rejectionReason: nil
        )
        
        pendingRegistration = request
        saveRegistration(request)
        return request
    }
    
    private func saveRegistration(_ request: ProviderRegistrationRequest) {
        if let data = try? JSONEncoder().encode(request) {
            UserDefaults.standard.set(data, forKey: "pending_registration")
        }
    }
    
    func loadPendingRegistration() {
        if let data = UserDefaults.standard.data(forKey: "pending_registration"),
           let request = try? JSONDecoder().decode(ProviderRegistrationRequest.self, from: data) {
            pendingRegistration = request
        }
    }
    
    // MARK: - Super Admin Check
    func isSuperAdminPhone(_ phone: String) -> Bool {
        return phone == SuperAdminConfig.superAdminPhone
    }
    
    func checkAndSetSuperAdmin() {
        if let user = AuthManager.shared.currentUser,
           isSuperAdminPhone(user.phone) {
            setRole(.superAdmin)
        }
    }
}

// MARK: - Super Admin Manager
class SuperAdminManager: ObservableObject {
    static let shared = SuperAdminManager()
    
    @Published var systemSettings: SystemSettings?
    @Published var cityConfigs: [CityConfig] = []
    @Published var adminUsers: [AdminUser] = []
    @Published var allRegistrationRequests: [ProviderRegistrationRequest] = []
    
    init() {
        loadDefaultSettings()
    }
    
    // MARK: - Access Control
    var canAccess: Bool {
        return RoleManager.shared.isSuperAdmin
    }
    
    // MARK: - System Settings
    func updateSystemSettings(_ settings: SystemSettings) {
        guard canAccess else { return }
        systemSettings = settings
        saveSettings()
    }
    
    private func loadDefaultSettings() {
        systemSettings = SystemSettings(
            appName: "Benim Şehrim",
            supportEmail: "destek@benimsehrim.com",
            supportPhone: "+908501234567",
            defaultCity: "kirsehir",
            maintenanceMode: false,
            minAppVersion: "1.0.0",
            commissionRate: 10.0, // %10 komisyon
            taxRate: 18.0 // %18 KDV
        )
        
        cityConfigs = [
            CityConfig(
                id: "kirsehir",
                cityName: "Kırşehir",
                cityCode: "40",
                isActive: true,
                deliveryFeeBase: 10.0,
                deliveryFeePerKm: 3.0,
                taxiFareBase: 20.0,
                taxiFarePerKm: 15.0,
                taxiFarePerMinute: 1.0,
                courierFeeBase: 15.0,
                courierFeePerKm: 5.0,
                operatingHoursStart: 7,
                operatingHoursEnd: 23
            )
        ]
    }
    
    private func saveSettings() {
        // Save to UserDefaults or backend
    }
    
    // MARK: - Admin Management
    func createAdmin(name: String, phone: String, email: String?, permissions: [Permission]) -> AdminUser {
        guard canAccess else { fatalError("Unauthorized") }
        
        let admin = AdminUser(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            name: name,
            phone: phone,
            email: email,
            role: .admin,
            permissions: permissions,
            isActive: true,
            createdAt: Date(),
            createdBy: AuthManager.shared.currentUser?.id ?? ""
        )
        
        adminUsers.append(admin)
        return admin
    }
    
    func updateAdminPermissions(adminId: String, permissions: [Permission]) {
        guard canAccess else { return }
        
        if let index = adminUsers.firstIndex(where: { $0.id == adminId }) {
            adminUsers[index].permissions = permissions
        }
    }
    
    func deactivateAdmin(adminId: String) {
        guard canAccess else { return }
        
        if let index = adminUsers.firstIndex(where: { $0.id == adminId }) {
            adminUsers[index].isActive = false
        }
    }
    
    func activateAdmin(adminId: String) {
        guard canAccess else { return }
        
        if let index = adminUsers.firstIndex(where: { $0.id == adminId }) {
            adminUsers[index].isActive = true
        }
    }
    
    // MARK: - City Management
    func addCity(_ config: CityConfig) {
        guard canAccess else { return }
        cityConfigs.append(config)
    }
    
    func updateCity(_ config: CityConfig) {
        guard canAccess else { return }
        
        if let index = cityConfigs.firstIndex(where: { $0.id == config.id }) {
            cityConfigs[index] = config
        }
    }
    
    func toggleCityActive(cityId: String) {
        guard canAccess else { return }
        
        if let index = cityConfigs.firstIndex(where: { $0.id == cityId }) {
            cityConfigs[index].isActive.toggle()
        }
    }
    
    // MARK: - Registration Approval
    func approveRegistration(requestId: String) {
        guard RoleManager.shared.isAdmin else { return }
        
        // Find and update request
        // Set user role based on provider type
        // Create provider profile
    }
    
    func rejectRegistration(requestId: String, reason: String) {
        guard RoleManager.shared.isAdmin else { return }
        
        // Find and update request
    }
    
    // MARK: - Statistics
    var totalVendors: Int {
        return allRegistrationRequests.filter { $0.providerType == .vendor && $0.status == .approved }.count
    }
    
    var totalDrivers: Int {
        return allRegistrationRequests.filter { $0.providerType == .taxiDriver && $0.status == .approved }.count
    }
    
    var totalCouriers: Int {
        return allRegistrationRequests.filter { $0.providerType == .courier && $0.status == .approved }.count
    }
    
    var pendingRequests: Int {
        return allRegistrationRequests.filter { $0.status == .pending }.count
    }
}
