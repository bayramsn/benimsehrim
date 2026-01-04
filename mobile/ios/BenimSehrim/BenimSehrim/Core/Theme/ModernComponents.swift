import SwiftUI

// MARK: - Modern Button Styles

struct GradientButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let isEnabled: Bool
    var shadowColor: Color
    
    init(gradient: LinearGradient = .primaryGradient, isEnabled: Bool = true, shadowColor: Color = .primary.opacity(0.3)) {
        self.gradient = gradient
        self.isEnabled = isEnabled
        self.shadowColor = shadowColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if isEnabled {
                        gradient
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
            )
            .cornerRadius(16)
            .shadow(
                color: isEnabled ? shadowColor : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Modern Card

struct ModernCard<Content: View>: View {
    let content: Content
    let elevation: CGFloat
    
    init(elevation: CGFloat = 2, @ViewBuilder content: () -> Content) {
        self.elevation = elevation
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(Color.surfaceLight)
            .cornerRadius(20)
            .shadow(
                color: Color.black.opacity(0.08),
                radius: elevation * 2,
                x: 0,
                y: elevation
            )
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: String
    
    private var statusInfo: (color: Color, text: String) {
        switch status.uppercased() {
        case "PENDING":
            return (.statusPending, "Bekliyor")
        case "ACCEPTED":
            return (.statusAccepted, "Onaylandı")
        case "PREPARING":
            return (.statusPreparing, "Hazırlanıyor")
        case "READY":
            return (.statusReady, "Hazır")
        case "ON_WAY", "DELIVERING":
            return (.statusOnWay, "Yolda")
        case "DELIVERED":
            return (.statusDelivered, "Teslim Edildi")
        case "CANCELLED":
            return (.statusCancelled, "İptal")
        default:
            return (.gray, status)
        }
    }
    
    var body: some View {
        Text(statusInfo.text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(statusInfo.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusInfo.color.opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - Shimmer Effect

struct ShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.borderColor,
                            Color.dividerColor,
                            Color.borderColor
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(70))
                        .offset(x: isAnimating ? geometry.size.width * 2 : -geometry.size.width * 2)
                )
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let title: String
    let description: String
    let icon: Image
    let actionText: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        description: String,
        icon: Image,
        actionText: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.actionText = actionText
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.primaryColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.primaryColor)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionText = actionText, let action = action {
                Button(action: action) {
                    Text(actionText)
                }
                .buttonStyle(GradientButtonStyle())
                .frame(width: 200)
            }
        }
        .padding(32)
    }
}

// MARK: - Rating Stars

struct RatingStars: View {
    let rating: Double
    let starSize: CGFloat
    
    init(rating: Double, starSize: CGFloat = 16) {
        self.rating = rating
        self.starSize = starSize
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: starIcon(for: index))
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
                    .foregroundColor(.warningColor)
            }
            
            Text(String(format: "%.1f", rating))
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
                .padding(.leading, 4)
        }
    }
    
    private func starIcon(for index: Int) -> String {
        if Double(index) < rating.rounded(.down) {
            return "star.fill"
        } else if Double(index) < rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - Loading Button

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(title)
            }
        }
        .buttonStyle(GradientButtonStyle(isEnabled: !isLoading))
        .disabled(isLoading)
    }
}

// MARK: - Gradient Text

struct GradientText: View {
    let text: String
    let gradient: LinearGradient
    let font: Font
    
    init(_ text: String, gradient: LinearGradient = .primaryGradient, font: Font = .title) {
        self.text = text
        self.gradient = gradient
        self.font = font
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }
}
