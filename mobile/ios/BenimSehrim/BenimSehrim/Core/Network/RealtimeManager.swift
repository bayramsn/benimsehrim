import Foundation
import Combine

// MARK: - Real-time Manager (WebSocket Simulation)
class RealtimeManager: ObservableObject {
    static let shared = RealtimeManager()
    
    @Published var isConnected = false
    @Published var lastOrderUpdate: OrderUpdate?
    @Published var lastRideUpdate: RideUpdate?
    @Published var lastCourierLocation: CourierLocationUpdate?
    @Published var lastDriverLocation: DriverLocationUpdate?
    @Published var lastChatMessage: ChatMessageUpdate?
    
    private var connectionTimer: Timer?
    private var pingTimer: Timer?
    
    init() {
        // Simulate connection
        connect()
    }
    
    // MARK: - Connection Management
    func connect() {
        // Simulate WebSocket connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isConnected = true
            self.startPingTimer()
        }
    }
    
    func disconnect() {
        isConnected = false
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.ping()
        }
    }
    
    private func ping() {
        // Send ping to keep connection alive
        print("WebSocket ping")
    }
    
    // MARK: - Subscribe to Updates
    func subscribeToOrder(orderId: String) {
        // In real implementation, send subscribe message to WebSocket
        print("Subscribed to order: \(orderId)")
    }
    
    func subscribeToRide(rideId: String) {
        print("Subscribed to ride: \(rideId)")
    }
    
    func subscribeToCourier(courierId: String) {
        print("Subscribed to courier: \(courierId)")
    }
    
    func subscribeToDriver(driverId: String) {
        print("Subscribed to driver: \(driverId)")
    }
    
    func subscribeToChat(chatId: String) {
        print("Subscribed to chat: \(chatId)")
    }
    
    // MARK: - Unsubscribe
    func unsubscribeFromOrder(orderId: String) {
        print("Unsubscribed from order: \(orderId)")
    }
    
    func unsubscribeFromRide(rideId: String) {
        print("Unsubscribed from ride: \(rideId)")
    }
    
    func unsubscribeFromCourier(courierId: String) {
        print("Unsubscribed from courier: \(courierId)")
    }
    
    func unsubscribeFromDriver(driverId: String) {
        print("Unsubscribed from driver: \(driverId)")
    }
    
    func unsubscribeFromChat(chatId: String) {
        print("Unsubscribed from chat: \(chatId)")
    }
    
    // MARK: - Simulate Updates (For Testing)
    func simulateOrderUpdate(orderId: String, status: String) {
        let update = OrderUpdate(
            orderId: orderId,
            status: status,
            timestamp: Date(),
            message: getStatusMessage(status)
        )
        lastOrderUpdate = update
        
        // Send notification
        NotificationManager.shared.sendOrderNotification(
            orderId: orderId,
            status: status,
            storeName: "Mağaza"
        )
    }
    
    func simulateRideUpdate(rideId: String, status: String, driverName: String?) {
        let update = RideUpdate(
            rideId: rideId,
            status: status,
            driverName: driverName,
            estimatedArrival: Date().addingTimeInterval(300),
            timestamp: Date()
        )
        lastRideUpdate = update
        
        NotificationManager.shared.sendTaxiNotification(
            rideId: rideId,
            status: status,
            driverName: driverName
        )
    }
    
    func simulateCourierLocation(courierId: String, latitude: Double, longitude: Double) {
        let update = CourierLocationUpdate(
            courierId: courierId,
            latitude: latitude,
            longitude: longitude,
            heading: 0,
            speed: 0,
            timestamp: Date()
        )
        lastCourierLocation = update
    }
    
    func simulateDriverLocation(driverId: String, latitude: Double, longitude: Double) {
        let update = DriverLocationUpdate(
            driverId: driverId,
            latitude: latitude,
            longitude: longitude,
            heading: 0,
            speed: 0,
            timestamp: Date()
        )
        lastDriverLocation = update
    }
    
    func simulateChatMessage(chatId: String, senderId: String, content: String) {
        let update = ChatMessageUpdate(
            chatId: chatId,
            messageId: UUID().uuidString,
            senderId: senderId,
            senderName: "Gönderen",
            content: content,
            timestamp: Date()
        )
        lastChatMessage = update
    }
    
    private func getStatusMessage(_ status: String) -> String {
        switch status {
        case "confirmed": return "Siparişiniz onaylandı"
        case "preparing": return "Siparişiniz hazırlanıyor"
        case "ready": return "Siparişiniz hazır"
        case "delivering": return "Kurye yola çıktı"
        case "delivered": return "Siparişiniz teslim edildi"
        case "cancelled": return "Siparişiniz iptal edildi"
        default: return "Sipariş güncellendi"
        }
    }
}

// MARK: - Realtime Update Models
struct OrderUpdate: Codable {
    let orderId: String
    let status: String
    let timestamp: Date
    let message: String
}

struct RideUpdate: Codable {
    let rideId: String
    let status: String
    let driverName: String?
    let estimatedArrival: Date?
    let timestamp: Date
}

struct CourierLocationUpdate: Codable {
    let courierId: String
    let latitude: Double
    let longitude: Double
    let heading: Double
    let speed: Double
    let timestamp: Date
}

struct DriverLocationUpdate: Codable {
    let driverId: String
    let latitude: Double
    let longitude: Double
    let heading: Double
    let speed: Double
    let timestamp: Date
}

struct ChatMessageUpdate: Codable {
    let chatId: String
    let messageId: String
    let senderId: String
    let senderName: String
    let content: String
    let timestamp: Date
}
