import SwiftUI

// MARK: - Color Extensions

extension Color {
    // Primary Colors - Modern Gradient
    static let primaryColor = Color(hex: "6366F1") // Indigo
    static let primaryVariant = Color(hex: "4F46E5")
    static let primaryLight = Color(hex: "818CF8")
    static let primaryDark = Color(hex: "3730A3")
    
    // Secondary Colors
    static let secondaryColor = Color(hex: "F59E0B") // Amber
    static let secondaryVariant = Color(hex: "D97706")
    static let secondaryLight = Color(hex: "FBBF24")
    
    // Status Colors
    static let successColor = Color(hex: "10B981") // Emerald
    static let warningColor = Color(hex: "F59E0B") // Amber
    static let errorColor = Color(hex: "EF4444") // Red
    static let infoColor = Color(hex: "3B82F6") // Blue
    
    // Background Colors
    static let backgroundLight = Color(hex: "F9FAFB")
    static let backgroundDark = Color(hex: "111827")
    static let surfaceLight = Color(hex: "FFFFFF")
    static let surfaceDark = Color(hex: "1F2937")
    
    // Text Colors
    static let textPrimary = Color(hex: "111827")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "9CA3AF")
    
    // Border & Divider
    static let borderColor = Color(hex: "E5E7EB")
    static let dividerColor = Color(hex: "F3F4F6")
    
    // Gradient Colors
    static let gradientStart = Color(hex: "6366F1")
    static let gradientEnd = Color(hex: "8B5CF6")
    
    // Status Badge Colors
    static let statusPending = Color(hex: "FBBF24")
    static let statusAccepted = Color(hex: "3B82F6")
    static let statusPreparing = Color(hex: "8B5CF6")
    static let statusReady = Color(hex: "10B981")
    static let statusOnWay = Color(hex: "F59E0B")
    static let statusDelivered = Color(hex: "10B981")
    static let statusCancelled = Color(hex: "EF4444")
    
    // Helper to create color from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Extensions

extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [.gradientStart, .gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
