import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Request notification permission
        requestNotificationPermission()
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // MARK: - Notification Permission
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Remote Notifications
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Device Token: \(token)")
        
        // Send token to backend
        Task {
            await sendTokenToBackend(token: token)
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    private func sendTokenToBackend(token: String) async {
        // In a real app, send this to your backend
        guard let _ = AuthManager.shared.accessToken else { return }
        
        // Api call to register push token
        // await NetworkManager.shared.registerPushToken(token: token, platform: "ios")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification action based on type
        if let type = userInfo["type"] as? String {
            handleNotificationAction(type: type, data: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleNotificationAction(type: String, data: [AnyHashable: Any]) {
        // Navigate based on notification type
        switch type {
        case "NEW_ORDER", "ORDER_STATUS":
            if let orderId = data["orderId"] as? String {
                // Navigate to order detail
                NotificationCenter.default.post(
                    name: Notification.Name("NavigateToOrder"),
                    object: nil,
                    userInfo: ["orderId": orderId]
                )
            }
        case "NEW_RIDE_CALL", "RIDE_STATUS":
            if let rideId = data["rideId"] as? String {
                // Navigate to ride detail
                NotificationCenter.default.post(
                    name: Notification.Name("NavigateToRide"),
                    object: nil,
                    userInfo: ["rideId": rideId]
                )
            }
        case "CHAT_MESSAGE":
            if let chatId = data["chatId"] as? String {
                // Navigate to chat
                NotificationCenter.default.post(
                    name: Notification.Name("NavigateToChat"),
                    object: nil,
                    userInfo: ["chatId": chatId]
                )
            }
        default:
            break
        }
    }
}
