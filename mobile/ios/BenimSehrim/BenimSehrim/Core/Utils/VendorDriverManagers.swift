import Foundation
import Combine

// MARK: - Vendor/Esnaf Manager
class VendorManager: ObservableObject {
    static let shared = VendorManager()
    
    @Published var currentVendor: Vendor?
    @Published var products: [Product] = []
    @Published var orders: [OrderDetail] = []
    @Published var dailySummary: DailySummary?
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Vendor Status
    func updateVendorStatus(isOpen: Bool) {
        guard var vendor = currentVendor else { return }
        vendor.isOpen = isOpen
        currentVendor = vendor
        
        // TODO: Sync with backend
    }
    
    func updateAvailabilityStatus(_ status: AvailabilityStatus) {
        guard var vendor = currentVendor else { return }
        vendor.availabilityStatus = status
        currentVendor = vendor
        
        // Also update in operations manager
        BusinessOperationsManager.shared.setAvailabilityStatus(status)
    }
    
    // MARK: - Product Management
    func addProduct(
        name: String,
        description: String?,
        price: Double,
        stock: Int,
        unit: String?,
        images: [String]
    ) -> Product {
        let product = Product(
            id: UUID().uuidString,
            name: name,
            description: description,
            price: price,
            stock: stock,
            unit: unit,
            images: images,
            isActive: true,
            campaigns: nil
        )
        
        products.append(product)
        return product
    }
    
    func updateProduct(
        productId: String,
        name: String? = nil,
        description: String? = nil,
        price: Double? = nil,
        stock: Int? = nil,
        isActive: Bool? = nil
    ) {
        guard let index = products.firstIndex(where: { $0.id == productId }) else { return }
        
        // Create updated product (since Product is immutable struct)
        let old = products[index]
        let updated = Product(
            id: old.id,
            name: name ?? old.name,
            description: description ?? old.description,
            price: price ?? old.price,
            stock: stock ?? old.stock,
            unit: old.unit,
            images: old.images,
            isActive: isActive ?? old.isActive,
            campaigns: old.campaigns
        )
        
        products[index] = updated
    }
    
    func deleteProduct(productId: String) {
        products.removeAll { $0.id == productId }
    }
    
    // MARK: - Stock Management
    func updateStock(productId: String, newStock: Int) {
        updateProduct(productId: productId, stock: newStock)
        
        // Auto-disable if stock is 0
        if newStock == 0 {
            updateProduct(productId: productId, isActive: false)
        }
    }
    
    func decrementStock(productId: String, quantity: Int) {
        guard let product = products.first(where: { $0.id == productId }) else { return }
        let newStock = max(0, product.stock - quantity)
        updateStock(productId: productId, newStock: newStock)
    }
    
    // MARK: - Order Management
    func acceptOrder(orderId: String) {
        updateOrderStatus(orderId: orderId, status: "confirmed")
        NotificationManager.shared.sendOrderNotification(orderId: orderId, status: "confirmed", storeName: currentVendor?.name ?? "")
    }
    
    func rejectOrder(orderId: String, reason: String?) {
        updateOrderStatus(orderId: orderId, status: "cancelled")
        
        // Check for crisis
        let recentRejections = orders.filter { $0.status == "cancelled" }.count
        BusinessOperationsManager.shared.checkForCrisis(
            vendorId: currentVendor?.id ?? "",
            vendorName: currentVendor?.name ?? "",
            cancelCount: recentRejections,
            delayCount: 0,
            rejectCount: recentRejections
        )
    }
    
    func startPreparing(orderId: String) {
        updateOrderStatus(orderId: orderId, status: "preparing")
    }
    
    func markReady(orderId: String) {
        updateOrderStatus(orderId: orderId, status: "ready")
    }
    
    private func updateOrderStatus(orderId: String, status: String) {
        // In real implementation, call API
        // For now, just update locally
        // orders will be refreshed from API
    }
    
    // MARK: - Daily Summary
    func generateDailySummary() {
        dailySummary = BusinessOperationsManager.shared.generateDailySummary(orders: orders)
    }
    
    // MARK: - Auto Close Check
    func checkAutoClose() {
        let recentRejections = orders.filter {
            $0.status == "cancelled" &&
            Calendar.current.isDateInToday(ISO8601DateFormatter().date(from: $0.createdAt) ?? Date())
        }.count
        
        let (shouldClose, reason) = BusinessOperationsManager.shared.shouldAutoClose(
            recentRejections: recentRejections,
            lastActivityTime: Date()
        )
        
        if shouldClose {
            updateVendorStatus(isOpen: false)
            print("Auto-closed: \(reason ?? "")")
        }
    }
}

// MARK: - Driver Manager (Taxi/Courier)
class DriverManager: ObservableObject {
    static let shared = DriverManager()
    
    @Published var currentDriver: ExtendedDriver?
    @Published var activeJobs: [DriverJob] = []
    @Published var completedJobs: [DriverJob] = []
    @Published var dailyStats: DriverDailyStats?
    @Published var isOnline = false
    
    // MARK: - Status Management
    func goOnline() {
        isOnline = true
        BusinessOperationsManager.shared.setAvailabilityStatus(.available)
        LocationManager.shared.startUpdatingLocation()
    }
    
    func goOffline() {
        isOnline = false
        BusinessOperationsManager.shared.setAvailabilityStatus(.offline)
        LocationManager.shared.stopUpdatingLocation()
    }
    
    func startBreak(minutes: Int) {
        BusinessOperationsManager.shared.startBreak(durationMinutes: minutes)
    }
    
    func endBreak() {
        BusinessOperationsManager.shared.endBreak()
    }
    
    // MARK: - Job Management
    func acceptJob(jobId: String) {
        guard let index = activeJobs.firstIndex(where: { $0.id == jobId }) else { return }
        activeJobs[index].status = .accepted
        
        // Start tracking
        RealtimeManager.shared.subscribeToOrder(orderId: jobId)
    }
    
    func rejectJob(jobId: String, reason: String?) {
        activeJobs.removeAll { $0.id == jobId }
        
        // Track rejections
        let recentRejections = completedJobs.filter {
            $0.status == .rejected &&
            Calendar.current.isDateInToday($0.createdAt)
        }.count
        
        if recentRejections >= 2 {
            // Warn driver
            print("Warning: Too many rejections")
        }
    }
    
    func startJob(jobId: String) {
        guard let index = activeJobs.firstIndex(where: { $0.id == jobId }) else { return }
        activeJobs[index].status = .inProgress
        activeJobs[index].startedAt = Date()
    }
    
    func completeJob(jobId: String) {
        guard let index = activeJobs.firstIndex(where: { $0.id == jobId }) else { return }
        var job = activeJobs[index]
        job.status = .completed
        job.completedAt = Date()
        
        completedJobs.append(job)
        activeJobs.remove(at: index)
        
        // Update daily stats
        updateDailyStats()
        
        // Add pending rating
        RatingManager.shared.addPendingRating(
            type: job.type == .delivery ? .courier : .taxi,
            targetId: currentDriver?.id ?? "",
            targetName: currentDriver?.name ?? "",
            targetImage: currentDriver?.avatarUrl,
            orderId: job.type == .delivery ? job.id : nil,
            rideId: job.type == .ride ? job.id : nil
        )
    }
    
    // MARK: - Location Updates
    func updateLocation() {
        guard let location = LocationManager.shared.currentLocation,
              let driverId = currentDriver?.id else { return }
        
        RealtimeManager.shared.simulateDriverLocation(
            driverId: driverId,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
    
    // MARK: - Daily Stats
    private func updateDailyStats() {
        let todayJobs = completedJobs.filter { Calendar.current.isDateInToday($0.completedAt ?? $0.createdAt) }
        
        dailyStats = DriverDailyStats(
            date: Date(),
            jobCount: todayJobs.count,
            totalEarnings: todayJobs.reduce(0) { $0 + $1.fare },
            totalDistance: todayJobs.reduce(0) { $0 + $1.distance },
            averageRating: 4.5, // Would come from API
            onlineHours: 8.0 // Would be calculated from actual online time
        )
    }
    
    // MARK: - Daily Goal
    var dailyGoalProgress: (current: Int, goal: Int, progress: Double) {
        let goal = currentDriver?.dailyGoal ?? 10
        let current = completedJobs.filter { Calendar.current.isDateInToday($0.completedAt ?? $0.createdAt) }.count
        let progress = min(1.0, Double(current) / Double(goal))
        return (current, goal, progress)
    }
}

// MARK: - Driver Job Model
struct DriverJob: Codable, Identifiable {
    let id: String
    let type: JobType
    var status: JobStatus
    let pickupAddress: String
    let pickupLatitude: Double
    let pickupLongitude: Double
    let dropoffAddress: String
    let dropoffLatitude: Double
    let dropoffLongitude: Double
    let distance: Double
    let fare: Double
    let customerName: String
    let customerPhone: String
    let notes: String?
    let createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
}

enum JobType: String, Codable {
    case delivery = "delivery"
    case ride = "ride"
}

enum JobStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case inProgress = "in_progress"
    case completed = "completed"
    case rejected = "rejected"
    case cancelled = "cancelled"
}

struct DriverDailyStats: Codable {
    let date: Date
    let jobCount: Int
    let totalEarnings: Double
    let totalDistance: Double
    let averageRating: Double
    let onlineHours: Double
}

// MARK: - Campaign Manager
class CampaignManager: ObservableObject {
    static let shared = CampaignManager()
    
    @Published var campaigns: [VendorCampaign] = []
    
    // MARK: - Create Campaign
    func createCampaign(
        productId: String?,
        type: CampaignType,
        value: Double,
        startDate: Date,
        endDate: Date,
        stockLimit: Int?
    ) -> VendorCampaign {
        let campaign = VendorCampaign(
            id: UUID().uuidString,
            vendorId: VendorManager.shared.currentVendor?.id ?? "",
            productId: productId,
            type: type,
            value: value,
            startDate: startDate,
            endDate: endDate,
            stockLimit: stockLimit,
            usedStock: 0,
            isActive: true,
            createdAt: Date()
        )
        
        campaigns.append(campaign)
        return campaign
    }
    
    // MARK: - Campaign Types
    func createPercentageDiscount(productId: String, percentage: Double, startDate: Date, endDate: Date) -> VendorCampaign {
        return createCampaign(productId: productId, type: .percentage, value: percentage, startDate: startDate, endDate: endDate, stockLimit: nil)
    }
    
    func createFixedDiscount(productId: String, amount: Double, startDate: Date, endDate: Date) -> VendorCampaign {
        return createCampaign(productId: productId, type: .fixed, value: amount, startDate: startDate, endDate: endDate, stockLimit: nil)
    }
    
    func createBuyXGetY(productId: String, buyCount: Int, getCount: Int, startDate: Date, endDate: Date) -> VendorCampaign {
        // value = buyCount * 100 + getCount (e.g., 201 = buy 2 get 1)
        let value = Double(buyCount * 100 + getCount)
        return createCampaign(productId: productId, type: .buyXGetY, value: value, startDate: startDate, endDate: endDate, stockLimit: nil)
    }
    
    func createHappyHour(productId: String?, percentage: Double, startHour: Int, endHour: Int) -> VendorCampaign {
        // Create campaign for today's happy hour
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        startComponents.hour = startHour
        var endComponents = startComponents
        endComponents.hour = endHour
        
        let startDate = calendar.date(from: startComponents) ?? Date()
        let endDate = calendar.date(from: endComponents) ?? Date()
        
        return createCampaign(productId: productId, type: .happyHour, value: percentage, startDate: startDate, endDate: endDate, stockLimit: nil)
    }
    
    // MARK: - End Campaign
    func endCampaign(campaignId: String) {
        if let index = campaigns.firstIndex(where: { $0.id == campaignId }) {
            campaigns[index].isActive = false
        }
    }
    
    // MARK: - Check Active Campaigns
    var activeCampaigns: [VendorCampaign] {
        let now = Date()
        return campaigns.filter { $0.isActive && $0.startDate <= now && $0.endDate >= now }
    }
    
    // MARK: - Calculate Discount
    func calculateDiscount(for productId: String, originalPrice: Double, quantity: Int) -> Double {
        guard let campaign = activeCampaigns.first(where: { $0.productId == productId }) else {
            return 0
        }
        
        switch campaign.type {
        case .percentage:
            return originalPrice * Double(quantity) * (campaign.value / 100)
        case .fixed:
            return campaign.value * Double(quantity)
        case .buyXGetY:
            let buyCount = Int(campaign.value / 100)
            let getCount = Int(campaign.value) % 100
            let freeItems = (quantity / (buyCount + getCount)) * getCount
            return originalPrice * Double(freeItems)
        case .happyHour:
            return originalPrice * Double(quantity) * (campaign.value / 100)
        }
    }
}

struct VendorCampaign: Codable, Identifiable {
    let id: String
    let vendorId: String
    let productId: String?
    let type: CampaignType
    let value: Double
    let startDate: Date
    let endDate: Date
    let stockLimit: Int?
    var usedStock: Int
    var isActive: Bool
    let createdAt: Date
    
    var remainingStock: Int? {
        guard let limit = stockLimit else { return nil }
        return max(0, limit - usedStock)
    }
    
    var isExpired: Bool {
        return Date() > endDate
    }
    
    var timeRemaining: TimeInterval {
        return endDate.timeIntervalSince(Date())
    }
}

enum CampaignType: String, Codable {
    case percentage = "percentage"   // %20 indirim
    case fixed = "fixed"             // 10₺ indirim
    case buyXGetY = "buy_x_get_y"    // 2 al 1 öde
    case happyHour = "happy_hour"    // Saat bazlı
    
    var displayName: String {
        switch self {
        case .percentage: return "Yüzde İndirim"
        case .fixed: return "Sabit İndirim"
        case .buyXGetY: return "X Al Y Öde"
        case .happyHour: return "Happy Hour"
        }
    }
}
