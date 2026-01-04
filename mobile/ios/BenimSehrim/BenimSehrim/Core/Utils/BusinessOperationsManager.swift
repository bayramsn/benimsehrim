import Foundation
import Combine

/// Business Operations Manager - Handles availability, traffic, alerts, and automation
class BusinessOperationsManager: ObservableObject {
    static let shared = BusinessOperationsManager()
    
    // MARK: - Published Properties
    @Published var currentUserStatus: AvailabilityStatus = .offline
    @Published var breakEndTime: Date?
    @Published var dailySummary: DailySummary?
    @Published var productSuggestions: [ProductSuggestion] = []
    @Published var crisisAlerts: [CrisisAlert] = []
    @Published var quickReorders: [QuickReorder] = []
    @Published var personalizedSection: PersonalizedSection?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // Keys
    private let statusKey = "user_availability_status"
    private let breakEndKey = "break_end_time"
    
    init() {
        loadSavedStatus()
    }
    
    // MARK: - Availability Status (Hazırım Butonu)
    
    /// Set availability status for vendor/driver/taxi
    func setAvailabilityStatus(_ status: AvailabilityStatus) {
        currentUserStatus = status
        userDefaults.set(status.rawValue, forKey: statusKey)
        
        // Clear break time if not on break
        if status != .onBreak {
            breakEndTime = nil
            userDefaults.removeObject(forKey: breakEndKey)
        }
        
        // TODO: Sync with backend
        // NetworkManager.shared.updateAvailabilityStatus(status)
    }
    
    /// Toggle availability (quick toggle for "Hazırım" button)
    func toggleAvailability() {
        switch currentUserStatus {
        case .offline, .onBreak:
            setAvailabilityStatus(.available)
        case .available:
            setAvailabilityStatus(.busy)
        case .busy:
            setAvailabilityStatus(.offline)
        }
    }
    
    /// Start break mode (Dinlenme Modu)
    func startBreak(durationMinutes: Int) {
        let endTime = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        breakEndTime = endTime
        userDefaults.set(endTime, forKey: breakEndKey)
        setAvailabilityStatus(.onBreak)
        
        // Schedule automatic return to available
        scheduleBreakEnd(at: endTime)
    }
    
    /// End break early
    func endBreak() {
        breakEndTime = nil
        userDefaults.removeObject(forKey: breakEndKey)
        setAvailabilityStatus(.available)
    }
    
    /// Check if break is still active
    var isOnBreak: Bool {
        guard let endTime = breakEndTime else { return false }
        return Date() < endTime
    }
    
    /// Remaining break time in minutes
    var remainingBreakMinutes: Int {
        guard let endTime = breakEndTime else { return 0 }
        let remaining = endTime.timeIntervalSinceNow / 60
        return max(0, Int(remaining))
    }
    
    private func scheduleBreakEnd(at date: Date) {
        let timer = Timer(fire: date, interval: 0, repeats: false) { [weak self] _ in
            self?.endBreak()
        }
        RunLoop.main.add(timer, forMode: .common)
    }
    
    private func loadSavedStatus() {
        if let statusString = userDefaults.string(forKey: statusKey),
           let status = AvailabilityStatus(rawValue: statusString) {
            currentUserStatus = status
        }
        
        if let endTime = userDefaults.object(forKey: breakEndKey) as? Date {
            if Date() < endTime {
                breakEndTime = endTime
                currentUserStatus = .onBreak
            } else {
                userDefaults.removeObject(forKey: breakEndKey)
            }
        }
    }
    
    // MARK: - Traffic Level (Yoğunluk Algılama)
    
    /// Calculate traffic level based on recent orders
    func calculateTrafficLevel(recentOrderCount: Int, averageOrderCount: Int) -> TrafficLevel {
        let ratio = Double(recentOrderCount) / max(1, Double(averageOrderCount))
        
        switch ratio {
        case ..<0.5: return .calm
        case 0.5..<1.0: return .normal
        case 1.0..<1.5: return .busy
        default: return .veryBusy
        }
    }
    
    /// Get traffic warning message for user
    func getTrafficWarning(for vendor: Vendor) -> String? {
        return vendor.trafficLevel.warningMessage
    }
    
    // MARK: - Crisis Alerts (Sessiz Kriz Alarmı)
    
    /// Check for crisis conditions and create alerts
    func checkForCrisis(vendorId: String, vendorName: String, cancelCount: Int, delayCount: Int, rejectCount: Int) {
        // Check multiple cancellations (threshold: 3)
        if cancelCount >= 3 {
            createCrisisAlert(
                type: .multipleCancel,
                targetId: vendorId,
                targetName: vendorName,
                targetType: "vendor",
                count: cancelCount,
                threshold: 3
            )
        }
        
        // Check multiple delays (threshold: 2)
        if delayCount >= 2 {
            createCrisisAlert(
                type: .multipleDelay,
                targetId: vendorId,
                targetName: vendorName,
                targetType: "vendor",
                count: delayCount,
                threshold: 2
            )
        }
        
        // Check multiple rejections (threshold: 2)
        if rejectCount >= 2 {
            createCrisisAlert(
                type: .multipleReject,
                targetId: vendorId,
                targetName: vendorName,
                targetType: "vendor",
                count: rejectCount,
                threshold: 2
            )
        }
    }
    
    private func createCrisisAlert(type: CrisisType, targetId: String, targetName: String, targetType: String, count: Int, threshold: Int) {
        let alert = CrisisAlert(
            id: UUID().uuidString,
            type: type,
            targetId: targetId,
            targetName: targetName,
            targetType: targetType,
            count: count,
            threshold: threshold,
            message: "\(targetName) - \(type.displayName): \(count) adet (Limit: \(threshold))",
            severity: count >= threshold * 2 ? .critical : .high,
            createdAt: Date(),
            isResolved: false,
            resolvedAt: nil,
            resolvedBy: nil,
            adminNote: nil
        )
        
        // Check if similar alert already exists
        if !crisisAlerts.contains(where: { $0.targetId == targetId && $0.type == type && !$0.isResolved }) {
            crisisAlerts.insert(alert, at: 0)
            
            // TODO: Send notification to admin
            // NotificationManager.shared.sendAdminAlert(alert)
        }
    }
    
    /// Resolve a crisis alert
    func resolveCrisisAlert(alertId: String, adminId: String, note: String?) {
        if let index = crisisAlerts.firstIndex(where: { $0.id == alertId }) {
            crisisAlerts[index].isResolved = true
            crisisAlerts[index].resolvedAt = Date()
            crisisAlerts[index].resolvedBy = adminId
            crisisAlerts[index].adminNote = note
        }
    }
    
    // MARK: - Daily Summary (Gün Sonu Özet)
    
    /// Generate daily summary for vendor
    func generateDailySummary(orders: [OrderDetail]) -> DailySummary {
        let today = Calendar.current.startOfDay(for: Date())
        let todayOrders = orders.filter { order in
            guard let date = ISO8601DateFormatter().date(from: order.createdAt) else { return false }
            return Calendar.current.isDate(date, inSameDayAs: today)
        }
        
        let completedOrders = todayOrders.filter { $0.status == "delivered" }
        let cancelledOrders = todayOrders.filter { $0.status == "cancelled" }
        
        let totalRevenue = completedOrders.reduce(0) { $0 + $1.total }
        let averageOrderValue = completedOrders.isEmpty ? 0 : totalRevenue / Double(completedOrders.count)
        
        // Calculate top products
        var productCounts: [String: (name: String, count: Int, revenue: Double)] = [:]
        for order in completedOrders {
            for item in order.items {
                let current = productCounts[item.id] ?? (name: item.product.name, count: 0, revenue: 0)
                productCounts[item.id] = (
                    name: item.product.name,
                    count: current.count + item.quantity,
                    revenue: current.revenue + item.totalPrice
                )
            }
        }
        
        let topProducts = productCounts.map { (id, data) in
            TopProduct(id: id, name: data.name, quantity: data.count, revenue: data.revenue)
        }.sorted { $0.quantity > $1.quantity }.prefix(5)
        
        // Calculate peak hours
        var hourCounts: [Int: Int] = [:]
        for order in todayOrders {
            if let date = ISO8601DateFormatter().date(from: order.createdAt) {
                let hour = Calendar.current.component(.hour, from: date)
                hourCounts[hour, default: 0] += 1
            }
        }
        let peakHours = hourCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        
        return DailySummary(
            date: today,
            orderCount: todayOrders.count,
            completedCount: completedOrders.count,
            cancelledCount: cancelledOrders.count,
            totalRevenue: totalRevenue,
            averageOrderValue: averageOrderValue,
            topProducts: Array(topProducts),
            peakHours: peakHours,
            newCustomers: 0, // TODO: Calculate from user data
            repeatCustomers: 0
        )
    }
    
    // MARK: - Product Suggestions (Ürün Önerisi)
    
    /// Generate product suggestions based on rules
    func generateProductSuggestions(products: [Product], salesData: [String: Int]) -> [ProductSuggestion] {
        var suggestions: [ProductSuggestion] = []
        
        for product in products {
            let salesCount = salesData[product.id] ?? 0
            
            // No sales in 7 days
            if salesCount == 0 {
                suggestions.append(ProductSuggestion(
                    id: UUID().uuidString,
                    productId: product.id,
                    productName: product.name,
                    type: .noSales,
                    message: "Bu ürün 7 gündür satılmadı. Kampanya düşünebilirsiniz.",
                    createdAt: Date()
                ))
            }
            
            // Low stock
            let stock = product.stock
            if stock <= 5 && stock > 0 {
                suggestions.append(ProductSuggestion(
                    id: UUID().uuidString,
                    productId: product.id,
                    productName: product.name,
                    type: .lowStock,
                    message: "Stok azalıyor (\(stock) adet kaldı).",
                    createdAt: Date()
                ))
            }
            
            // Campaign eligible (products with low sales but good margin)
            if salesCount < 5 && product.price > 50 {
                suggestions.append(ProductSuggestion(
                    id: UUID().uuidString,
                    productId: product.id,
                    productName: product.name,
                    type: .campaignEligible,
                    message: "Bu ürün için indirim kampanyası açabilirsiniz.",
                    createdAt: Date()
                ))
            }
        }
        
        return suggestions
    }
    
    // MARK: - Quick Reorder (Tekrar Sipariş)
    
    /// Get quick reorder options from past orders
    func getQuickReorderOptions(orders: [OrderDetail]) -> [QuickReorder] {
        // Get unique vendor orders
        var vendorOrders: [String: OrderDetail] = [:]
        for order in orders.sorted(by: { $0.createdAt > $1.createdAt }) {
            if vendorOrders[order.store.id] == nil {
                vendorOrders[order.store.id] = order
            }
        }
        
        return vendorOrders.values.compactMap { order -> QuickReorder? in
            guard let date = ISO8601DateFormatter().date(from: order.createdAt) else { return nil }
            
            return QuickReorder(
                id: order.id,
                orderId: order.id,
                vendorId: order.store.id,
                vendorName: order.store.name,
                vendorLogo: order.store.logoUrl,
                items: order.items.map { item in
                    ReorderItem(
                        id: item.id,
                        productId: item.product.id,
                        name: item.product.name,
                        quantity: item.quantity,
                        price: item.unitPrice
                    )
                },
                totalAmount: order.total,
                lastOrderDate: date
            )
        }.sorted { $0.lastOrderDate > $1.lastOrderDate }
    }
    
    // MARK: - Usage Score (Kullanım Skoru)
    
    /// Calculate usage score for vendor/driver
    func calculateUsageScore(
        activityDays: Int,
        totalOrders: Int,
        cancelledOrders: Int,
        delayedOrders: Int,
        avgResponseTime: TimeInterval
    ) -> UsageScore {
        // Activity score (based on active days in last 30 days)
        let activityScore = min(100, (activityDays * 100) / 30)
        
        // Reliability score (based on completion rate)
        let completionRate = totalOrders > 0 ? Double(totalOrders - cancelledOrders) / Double(totalOrders) : 1.0
        let reliabilityScore = Int(completionRate * 100)
        
        // Response score (based on average response time)
        let responseScore: Int
        switch avgResponseTime {
        case ..<60: responseScore = 100
        case 60..<180: responseScore = 80
        case 180..<300: responseScore = 60
        case 300..<600: responseScore = 40
        default: responseScore = 20
        }
        
        // Overall score (weighted average)
        let overallScore = (activityScore * 30 + reliabilityScore * 40 + responseScore * 30) / 100
        
        return UsageScore(
            entityId: "",
            entityType: "",
            activityScore: activityScore,
            reliabilityScore: reliabilityScore,
            responseScore: responseScore,
            overallScore: overallScore,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Auto Close (Otomatik Kapatma)
    
    /// Check if vendor should be auto-closed
    func shouldAutoClose(recentRejections: Int, lastActivityTime: Date?) -> (shouldClose: Bool, reason: String?) {
        // 3 consecutive rejections
        if recentRejections >= 3 {
            return (true, "3 sipariş art arda reddedildi")
        }
        
        // No activity for 30 minutes
        if let lastActivity = lastActivityTime {
            let minutesSinceActivity = Date().timeIntervalSince(lastActivity) / 60
            if minutesSinceActivity > 30 {
                return (true, "30 dakikadır aktivite yok")
            }
        }
        
        return (false, nil)
    }
    
    // MARK: - Daily Goal (Günlük Hedef)
    
    /// Calculate daily goal progress
    func calculateDailyGoalProgress(currentJobs: Int, dailyGoal: Int) -> (progress: Double, remaining: Int, message: String) {
        let progress = min(1.0, Double(currentJobs) / Double(dailyGoal))
        let remaining = max(0, dailyGoal - currentJobs)
        
        let message: String
        if remaining == 0 {
            message = "🎉 Günlük hedefe ulaştın!"
        } else if remaining == 1 {
            message = "1 iş daha alırsan gün tamam!"
        } else {
            message = "\(remaining) iş daha alırsan gün tamam"
        }
        
        return (progress, remaining, message)
    }
}

// MARK: - Order Status Type
enum OrderStatusType: String {
    case pending = "pending"
    case confirmed = "confirmed"
    case preparing = "preparing"
    case ready = "ready"
    case delivering = "delivering"
    case delivered = "delivered"
    case cancelled = "cancelled"
}
