import Foundation
import Combine

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotificationItem] = []
    @Published var unreadCount: Int = 0
    @Published var notificationSettings: NotificationSettings = NotificationSettings()
    
    private let notificationsKey = "app_notifications"
    private let settingsKey = "notification_settings"
    
    init() {
        loadData()
        updateUnreadCount()
    }
    
    // MARK: - Add Notification
    func addNotification(
        type: NotificationType,
        title: String,
        body: String,
        data: [String: String]? = nil
    ) {
        let notification = AppNotificationItem(
            id: UUID().uuidString,
            type: type,
            title: title,
            body: body,
            data: data,
            isRead: false,
            createdAt: Date()
        )
        
        notifications.insert(notification, at: 0)
        
        // Keep only last 100 notifications
        if notifications.count > 100 {
            notifications = Array(notifications.prefix(100))
        }
        
        saveData()
        updateUnreadCount()
    }
    
    // MARK: - Mark as Read
    func markAsRead(_ notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            saveData()
            updateUnreadCount()
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        saveData()
        updateUnreadCount()
    }
    
    // MARK: - Delete
    func deleteNotification(_ notificationId: String) {
        notifications.removeAll { $0.id == notificationId }
        saveData()
        updateUnreadCount()
    }
    
    func clearAll() {
        notifications.removeAll()
        saveData()
        updateUnreadCount()
    }
    
    // MARK: - Settings
    func updateSettings(_ settings: NotificationSettings) {
        notificationSettings = settings
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    func shouldNotify(for type: NotificationType) -> Bool {
        switch type {
        case .order: return notificationSettings.orderUpdates
        case .promotion: return notificationSettings.promotions
        case .taxi: return notificationSettings.taxiUpdates
        case .courier: return notificationSettings.courierUpdates
        case .chat: return notificationSettings.chatMessages
        case .system: return true
        }
    }
    
    // MARK: - Helpers
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Persistence
    private func saveData() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: notificationsKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: notificationsKey),
           let saved = try? JSONDecoder().decode([AppNotificationItem].self, from: data) {
            notifications = saved
        }
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let saved = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            notificationSettings = saved
        }
    }
    
    // MARK: - Send Order Notification
    func sendOrderNotification(orderId: String, status: String, storeName: String) {
        let (title, body) = getOrderNotificationContent(status: status, storeName: storeName)
        addNotification(type: .order, title: title, body: body, data: ["orderId": orderId])
    }
    
    private func getOrderNotificationContent(status: String, storeName: String) -> (String, String) {
        switch status {
        case "confirmed":
            return ("Sipariş Onaylandı ✅", "\(storeName) siparişinizi onayladı ve hazırlamaya başladı.")
        case "preparing":
            return ("Hazırlanıyor 👨‍🍳", "\(storeName) siparişinizi hazırlıyor.")
        case "ready":
            return ("Hazır 📦", "Siparişiniz hazır, kurye yola çıkacak.")
        case "delivering":
            return ("Yolda 🚴", "Kurye siparişinizi teslim etmek için yola çıktı.")
        case "delivered":
            return ("Teslim Edildi 🎉", "Siparişiniz teslim edildi. Afiyet olsun!")
        case "cancelled":
            return ("İptal Edildi ❌", "Siparişiniz iptal edildi.")
        default:
            return ("Sipariş Güncellendi", "Siparişinizde güncelleme var.")
        }
    }
    
    // MARK: - Send Taxi Notification
    func sendTaxiNotification(rideId: String, status: String, driverName: String?) {
        let (title, body) = getTaxiNotificationContent(status: status, driverName: driverName)
        addNotification(type: .taxi, title: title, body: body, data: ["rideId": rideId])
    }
    
    private func getTaxiNotificationContent(status: String, driverName: String?) -> (String, String) {
        let driver = driverName ?? "Şoför"
        switch status {
        case "accepted":
            return ("Şoför Bulundu 🚕", "\(driver) çağrınızı kabul etti ve yola çıktı.")
        case "arrived":
            return ("Şoför Geldi 📍", "\(driver) sizi bekliyor.")
        case "started":
            return ("Yolculuk Başladı 🛣️", "İyi yolculuklar!")
        case "completed":
            return ("Yolculuk Bitti ✅", "Yolculuğunuz tamamlandı. Puanlayabilirsiniz.")
        case "cancelled":
            return ("Çağrı İptal ❌", "Taksi çağrınız iptal edildi.")
        default:
            return ("Taksi Güncelleme", "Taksi çağrınızda güncelleme var.")
        }
    }
}

// MARK: - Notification Models
struct AppNotificationItem: Codable, Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let data: [String: String]?
    var isRead: Bool
    let createdAt: Date
}

enum NotificationType: String, Codable {
    case order = "order"
    case promotion = "promotion"
    case taxi = "taxi"
    case courier = "courier"
    case chat = "chat"
    case system = "system"
    
    var icon: String {
        switch self {
        case .order: return "bag.fill"
        case .promotion: return "tag.fill"
        case .taxi: return "car.fill"
        case .courier: return "shippingbox.fill"
        case .chat: return "message.fill"
        case .system: return "bell.fill"
        }
    }
    
    var color: String {
        switch self {
        case .order: return "#4CAF50"
        case .promotion: return "#FF9800"
        case .taxi: return "#FFC107"
        case .courier: return "#2196F3"
        case .chat: return "#9C27B0"
        case .system: return "#607D8B"
        }
    }
}

struct NotificationSettings: Codable {
    var orderUpdates: Bool = true
    var promotions: Bool = true
    var taxiUpdates: Bool = true
    var courierUpdates: Bool = true
    var chatMessages: Bool = true
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
}
