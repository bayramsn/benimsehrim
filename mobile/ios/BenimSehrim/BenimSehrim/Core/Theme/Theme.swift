import SwiftUI

// MARK: - Colors
extension Color {
    // Primary Green
    static let primaryGreen = Color(hex: "006E24")
    static let primaryGreenLight = Color(hex: "78E18E")
    static let primaryGreenDark = Color(hex: "005319")
    
    // Secondary Orange
    static let secondaryOrange = Color(hex: "8C4E00")
    static let secondaryOrangeLight = Color(hex: "FFB74D")
    
    // Tertiary Blue
    static let tertiaryBlue = Color(hex: "005CB9")
    static let tertiaryBlueLight = Color(hex: "99C1FF")
    
    // Status Colors
    static let statusOpen = Color(hex: "4CAF50")
    static let statusClosed = Color(hex: "E53935")
    static let statusBusy = Color(hex: "FF9800")
    
    // Delivery Status
    static let deliveryPending = Color(hex: "9E9E9E")
    static let deliveryPreparing = Color(hex: "2196F3")
    static let deliveryOnWay = Color(hex: "FF9800")
    static let deliveryDelivered = Color(hex: "4CAF50")
    static let deliveryCancelled = Color(hex: "E53935")
}

// MARK: - Typography
extension Font {
    static let displayLarge = Font.system(size: 57, weight: .bold)
    static let displayMedium = Font.system(size: 45, weight: .bold)
    static let displaySmall = Font.system(size: 36, weight: .bold)
    
    static let headlineLarge = Font.system(size: 32, weight: .semibold)
    static let headlineMedium = Font.system(size: 28, weight: .semibold)
    static let headlineSmall = Font.system(size: 24, weight: .semibold)
    
    static let titleLarge = Font.system(size: 22, weight: .medium)
    static let titleMedium = Font.system(size: 16, weight: .medium)
    static let titleSmall = Font.system(size: 14, weight: .medium)
    
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let bodySmall = Font.system(size: 12, weight: .regular)
    
    static let labelLarge = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)
}

// MARK: - Common Shapes
extension RoundedRectangle {
    static let card = RoundedRectangle(cornerRadius: 16)
    static let button = RoundedRectangle(cornerRadius: 12)
    static let chip = RoundedRectangle(cornerRadius: 20)
    static let bottomSheet = RoundedRectangle(cornerRadius: 24)
}
