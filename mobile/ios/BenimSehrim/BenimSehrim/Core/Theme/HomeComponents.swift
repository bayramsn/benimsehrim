import SwiftUI

// MARK: - Service Card

struct ServiceCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    var shadowColor: Color = .primary.opacity(0.3)
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(gradient)
                    .shadow(
                        color: shadowColor,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                VStack(alignment: .leading, spacing: 0) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                }
                .padding(16)
            }
            .frame(width: 140, height: 140)
        }
        .buttonStyle(ScaleButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Category Icon

struct CategoryIcon: View {
    let name: String
    let icon: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(backgroundColor.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(backgroundColor)
                }
                
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textPrimary)
            }
            .frame(width: 80)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Campaign Card

struct CampaignCard: View {
    let title: String
    let description: String
    let discount: String
    let gradient: LinearGradient
    var shadowColor: Color = .primary.opacity(0.3)
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(gradient)
                    .shadow(
                        color: shadowColor,
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(discount)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "gift.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(20)
            }
            .frame(height: 120)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - User Profile Header

struct UserProfileHeader: View {
    let name: String
    let location: String
    let onProfileTap: () -> Void
    let onCartTap: () -> Void
    
    var body: some View {
        HStack {
            // User info
            Button(action: onProfileTap) {
                HStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient.primaryGradient)
                            .frame(width: 48, height: 48)
                        
                        Text(name.prefix(1).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Merhaba, \(name)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.textPrimary)
                            
                            Text("👋")
                                .font(.system(size: 16))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundColor(.textSecondary)
                            
                            Text(location)
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                // Cart button
                Button(action: onCartTap) {
                    ZStack {
                        Circle()
                            .fill(Color.backgroundLight)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "cart")
                            .foregroundColor(.textPrimary)
                    }
                }
                
                // Profile button
                Button(action: onProfileTap) {
                    ZStack {
                        Circle()
                            .fill(Color.backgroundLight)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "person")
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct HomeComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            UserProfileHeader(
                name: "Ssad",
                location: "Kırşehir",
                onProfileTap: {},
                onCartTap: {}
            )
            
            HStack(spacing: 12) {
                ServiceCard(
                    title: "Taksi Çağır",
                    subtitle: "Konumundan en yakın taksi",
                    icon: "car.fill",
                    gradient: LinearGradient(
                        colors: [Color(hex: "D97706"), Color(hex: "B45309")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    action: {}
                )
                
                ServiceCard(
                    title: "Siparişlerim",
                    subtitle: "Aktif sipariş takip et",
                    icon: "list.bullet.rectangle",
                    gradient: LinearGradient(
                        colors: [Color(hex: "3B82F6"), Color(hex: "2563EB")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    action: {}
                )
            }
            .padding(.horizontal)
            
            CampaignCard(
                title: "Ahi Kasap",
                description: "Sipariş ver, anında kazan!",
                discount: "%20 İndirim",
                gradient: LinearGradient(
                    colors: [Color(hex: "F97316"), Color(hex: "EA580C")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                action: {}
            )
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
