import Foundation
import Combine

// MARK: - Admin Manager
class AdminManager: ObservableObject {
    static let shared = AdminManager()
    
    @Published var pendingVendors: [Vendor] = []
    @Published var pendingDrivers: [ExtendedDriver] = []
    @Published var crisisAlerts: [CrisisAlert] = []
    @Published var fieldNotes: [FieldNote] = []
    @Published var operationStats: OperationStats?
    
    // MARK: - Vendor Approval
    func approveVendor(vendorId: String) {
        pendingVendors.removeAll { $0.id == vendorId }
        // TODO: Call API to approve
    }
    
    func rejectVendor(vendorId: String, reason: String) {
        pendingVendors.removeAll { $0.id == vendorId }
        // TODO: Call API to reject
    }
    
    // MARK: - Driver Approval
    func approveDriver(driverId: String) {
        pendingDrivers.removeAll { $0.id == driverId }
    }
    
    func rejectDriver(driverId: String, reason: String) {
        pendingDrivers.removeAll { $0.id == driverId }
    }
    
    // MARK: - Crisis Management
    func resolveCrisis(alertId: String, note: String?) {
        BusinessOperationsManager.shared.resolveCrisisAlert(
            alertId: alertId,
            adminId: AuthManager.shared.currentUser?.id ?? "",
            note: note
        )
    }
    
    // MARK: - Field Notes (CRM Mini)
    func addFieldNote(
        targetId: String,
        targetType: String,
        targetName: String,
        note: String,
        noteType: NoteType
    ) {
        let fieldNote = FieldNote(
            id: UUID().uuidString,
            targetId: targetId,
            targetType: targetType,
            targetName: targetName,
            note: note,
            noteType: noteType,
            createdBy: AuthManager.shared.currentUser?.id ?? "",
            createdAt: Date()
        )
        
        fieldNotes.insert(fieldNote, at: 0)
        saveFieldNotes()
    }
    
    func getFieldNotes(for targetId: String) -> [FieldNote] {
        return fieldNotes.filter { $0.targetId == targetId }
    }
    
    private func saveFieldNotes() {
        if let data = try? JSONEncoder().encode(fieldNotes) {
            UserDefaults.standard.set(data, forKey: "admin_field_notes")
        }
    }
    
    // MARK: - User Management
    func suspendUser(userId: String, reason: String, duration: TimeInterval?) {
        // TODO: Call API
    }
    
    func unsuspendUser(userId: String) {
        // TODO: Call API
    }
    
    // MARK: - Campaign Moderation
    func approveCampaign(campaignId: String) {
        // TODO: Call API
    }
    
    func rejectCampaign(campaignId: String, reason: String) {
        // TODO: Call API
    }
    
    // MARK: - Review Moderation
    func approveReview(reviewId: String) {
        // TODO: Call API
    }
    
    func rejectReview(reviewId: String, reason: String) {
        // TODO: Call API
    }
    
    // MARK: - Chat Moderation
    func flagChat(chatId: String, reason: String) {
        // TODO: Call API
    }
    
    func closeChat(chatId: String) {
        // TODO: Call API
    }
    
    // MARK: - City Management
    func activateCity(cityId: String) {
        // TODO: Call API
    }
    
    func deactivateCity(cityId: String) {
        // TODO: Call API
    }
    
    func createCityFromTemplate(template: CityTemplate, cityName: String, cityCode: String) {
        // TODO: Create new city using template settings
    }
    
    // MARK: - Operation Stats
    func loadOperationStats() {
        // TODO: Call API
        // Mock data for now
        operationStats = OperationStats(
            date: Date(),
            totalOrders: 150,
            completedOrders: 140,
            cancelledOrders: 10,
            totalRevenue: 25000,
            totalRides: 45,
            completedRides: 42,
            cancelledRides: 3,
            activeVendors: 25,
            activeDrivers: 15,
            newUsers: 12,
            averageRating: 4.5
        )
    }
}

struct OperationStats: Codable {
    let date: Date
    let totalOrders: Int
    let completedOrders: Int
    let cancelledOrders: Int
    let totalRevenue: Double
    let totalRides: Int
    let completedRides: Int
    let cancelledRides: Int
    let activeVendors: Int
    let activeDrivers: Int
    let newUsers: Int
    let averageRating: Double
    
    var orderCompletionRate: Double {
        guard totalOrders > 0 else { return 0 }
        return Double(completedOrders) / Double(totalOrders) * 100
    }
    
    var rideCompletionRate: Double {
        guard totalRides > 0 else { return 0 }
        return Double(completedRides) / Double(totalRides) * 100
    }
}

// MARK: - Spam/Profanity Filter
class ContentFilterManager {
    static let shared = ContentFilterManager()
    
    private let bannedWords = [
        // Add inappropriate words here
        "spam", "küfür1", "küfür2"
    ]
    
    private let maxMessageLength = 500
    private let minMessageLength = 1
    
    func filterContent(_ content: String) -> (isValid: Bool, filteredContent: String, reason: String?) {
        // Check length
        if content.count < minMessageLength {
            return (false, content, "Mesaj çok kısa")
        }
        
        if content.count > maxMessageLength {
            return (false, content, "Mesaj çok uzun (max \(maxMessageLength) karakter)")
        }
        
        // Check for banned words
        var filtered = content
        for word in bannedWords {
            if content.lowercased().contains(word.lowercased()) {
                filtered = filtered.replacingOccurrences(of: word, with: String(repeating: "*", count: word.count), options: .caseInsensitive)
            }
        }
        
        let hasBannedContent = filtered != content
        
        return (true, filtered, hasBannedContent ? "İçerik filtrelendi" : nil)
    }
    
    func isSpam(_ content: String, previousMessages: [String], timeInterval: TimeInterval) -> Bool {
        // Check for repeated messages
        let recentSameMessages = previousMessages.filter { $0 == content }.count
        if recentSameMessages >= 3 {
            return true
        }
        
        // Check for too many messages in short time
        if previousMessages.count >= 10 && timeInterval < 60 {
            return true
        }
        
        return false
    }
}

// MARK: - Automation Manager
class AutomationManager: ObservableObject {
    static let shared = AutomationManager()
    
    @Published var automationRules: [AutomationRule] = []
    
    init() {
        loadDefaultRules()
    }
    
    private func loadDefaultRules() {
        automationRules = [
            AutomationRule(
                id: "1",
                name: "Sipariş Zaman Aşımı",
                description: "5 dakika içinde kabul edilmeyen siparişler otomatik iptal edilir",
                trigger: .orderTimeout,
                action: .cancelOrder,
                isActive: true,
                parameters: ["timeout_minutes": "5"]
            ),
            AutomationRule(
                id: "2",
                name: "Alternatif Esnaf Yönlendirme",
                description: "Sipariş reddedildiğinde en yakın esnafa yönlendirilir",
                trigger: .orderRejected,
                action: .redirectToAlternative,
                isActive: true,
                parameters: ["max_distance_km": "5"]
            ),
            AutomationRule(
                id: "3",
                name: "Çağrı Zaman Aşımı",
                description: "2 dakika içinde kabul edilmeyen taksi çağrıları başka şoföre gönderilir",
                trigger: .rideTimeout,
                action: .redirectRide,
                isActive: true,
                parameters: ["timeout_minutes": "2"]
            ),
            AutomationRule(
                id: "4",
                name: "Konum Kapalı Offline",
                description: "Konum servisi kapatıldığında şoför otomatik offline yapılır",
                trigger: .locationDisabled,
                action: .setOffline,
                isActive: true,
                parameters: [:]
            ),
            AutomationRule(
                id: "5",
                name: "Gecikme Bildirimi",
                description: "Tahmini süreden 10 dakika geçince kullanıcıya bildirim gönderilir",
                trigger: .deliveryDelayed,
                action: .sendNotification,
                isActive: true,
                parameters: ["delay_minutes": "10"]
            ),
            AutomationRule(
                id: "6",
                name: "Düşük Performans Kısıtlama",
                description: "Kullanım skoru 30 altına düşen kullanıcılar kısıtlanır",
                trigger: .lowScore,
                action: .restrictUser,
                isActive: true,
                parameters: ["threshold_score": "30"]
            ),
            AutomationRule(
                id: "7",
                name: "Çoklu Bildirim Zinciri",
                description: "Sipariş için 3 aşamalı bildirim gönderilir",
                trigger: .newOrder,
                action: .sendNotificationChain,
                isActive: true,
                parameters: ["intervals_seconds": "0,30,60"]
            )
        ]
    }
    
    // MARK: - Execute Rules
    func executeRule(_ ruleId: String, context: [String: Any]) {
        guard let rule = automationRules.first(where: { $0.id == ruleId && $0.isActive }) else { return }
        
        switch rule.action {
        case .cancelOrder:
            if let orderId = context["orderId"] as? String {
                // Cancel order
                print("Auto-cancelling order: \(orderId)")
            }
            
        case .redirectToAlternative:
            if let orderId = context["orderId"] as? String {
                // Find alternative vendor
                print("Redirecting order: \(orderId)")
            }
            
        case .redirectRide:
            if let rideId = context["rideId"] as? String {
                // Find alternative driver
                print("Redirecting ride: \(rideId)")
            }
            
        case .setOffline:
            if let driverId = context["driverId"] as? String {
                // Set driver offline
                print("Setting driver offline: \(driverId)")
            }
            
        case .sendNotification:
            if let userId = context["userId"] as? String,
               let message = context["message"] as? String {
                NotificationManager.shared.addNotification(
                    type: .system,
                    title: "Bildirim",
                    body: message,
                    data: ["userId": userId]
                )
            }
            
        case .restrictUser:
            if let userId = context["userId"] as? String {
                // Restrict user
                print("Restricting user: \(userId)")
            }
            
        case .sendNotificationChain:
            // Send multiple notifications at intervals
            break
        }
    }
    
    // MARK: - Toggle Rule
    func toggleRule(_ ruleId: String) {
        if let index = automationRules.firstIndex(where: { $0.id == ruleId }) {
            automationRules[index].isActive.toggle()
        }
    }
}

struct AutomationRule: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let trigger: AutomationTrigger
    let action: AutomationAction
    var isActive: Bool
    let parameters: [String: String]
}

enum AutomationTrigger: String, Codable {
    case orderTimeout = "order_timeout"
    case orderRejected = "order_rejected"
    case rideTimeout = "ride_timeout"
    case locationDisabled = "location_disabled"
    case deliveryDelayed = "delivery_delayed"
    case lowScore = "low_score"
    case newOrder = "new_order"
}

enum AutomationAction: String, Codable {
    case cancelOrder = "cancel_order"
    case redirectToAlternative = "redirect_alternative"
    case redirectRide = "redirect_ride"
    case setOffline = "set_offline"
    case sendNotification = "send_notification"
    case restrictUser = "restrict_user"
    case sendNotificationChain = "send_notification_chain"
}
