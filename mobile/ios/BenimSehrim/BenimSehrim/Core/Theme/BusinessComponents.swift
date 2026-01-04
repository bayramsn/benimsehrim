import SwiftUI

// MARK: - Availability Status Button (Hazırım Butonu)
struct AvailabilityStatusButton: View {
    @ObservedObject var operationsManager = BusinessOperationsManager.shared
    @State private var showStatusPicker = false
    @State private var showBreakPicker = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: { showStatusPicker = true }) {
                HStack(spacing: 12) {
                    Image(systemName: operationsManager.currentUserStatus.icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: operationsManager.currentUserStatus.color))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(operationsManager.currentUserStatus.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if operationsManager.isOnBreak {
                            Text("\(operationsManager.remainingBreakMinutes) dk kaldı")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .confirmationDialog("Durum Seç", isPresented: $showStatusPicker) {
            Button("✅ Hazırım") {
                operationsManager.setAvailabilityStatus(.available)
            }
            Button("⏳ Meşgulüm") {
                operationsManager.setAvailabilityStatus(.busy)
            }
            Button("☕ Mola Al") {
                showBreakPicker = true
            }
            Button("🌙 Çevrimdışı") {
                operationsManager.setAvailabilityStatus(.offline)
            }
            Button("İptal", role: .cancel) {}
        }
        .confirmationDialog("Mola Süresi", isPresented: $showBreakPicker) {
            Button("15 Dakika") {
                operationsManager.startBreak(durationMinutes: 15)
            }
            Button("30 Dakika") {
                operationsManager.startBreak(durationMinutes: 30)
            }
            Button("45 Dakika") {
                operationsManager.startBreak(durationMinutes: 45)
            }
            Button("1 Saat") {
                operationsManager.startBreak(durationMinutes: 60)
            }
            Button("İptal", role: .cancel) {}
        }
    }
}

// MARK: - Traffic Level Badge
struct TrafficLevelBadge: View {
    let trafficLevel: TrafficLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: trafficLevel.color))
                .frame(width: 8, height: 8)
            
            Text(trafficLevel.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: trafficLevel.color))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: trafficLevel.color).opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Traffic Warning Banner
struct TrafficWarningBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Daily Goal Progress View
struct DailyGoalProgressView: View {
    let currentJobs: Int
    let dailyGoal: Int
    
    private var progress: (progress: Double, remaining: Int, message: String) {
        BusinessOperationsManager.shared.calculateDailyGoalProgress(
            currentJobs: currentJobs,
            dailyGoal: dailyGoal
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Günlük Hedef")
                    .font(.headline)
                
                Spacer()
                
                Text("\(currentJobs)/\(dailyGoal)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGreen)
            }
            
            ProgressView(value: progress.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .primaryGreen))
            
            Text(progress.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Crisis Alert Card
struct CrisisAlertCard: View {
    let alert: CrisisAlert
    let onResolve: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: alert.type.icon)
                    .foregroundColor(Color(hex: alert.severity.color))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.type.displayName)
                        .font(.headline)
                    
                    Text(alert.targetName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(timeAgo(from: alert.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(alert.message)
                .font(.body)
                .foregroundColor(.primary)
            
            if !alert.isResolved {
                Button(action: onResolve) {
                    Text("Çözüldü İşaretle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.primaryGreen)
                        .cornerRadius(8)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Çözüldü")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(hex: alert.severity.color).opacity(0.1))
        .cornerRadius(12)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Daily Summary Card
struct DailySummaryCard: View {
    let summary: DailySummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📊 Gün Sonu Özet")
                    .font(.headline)
                
                Spacer()
                
                Text(formatDate(summary.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatItem(title: "Sipariş", value: "\(summary.orderCount)", icon: "bag.fill", color: .blue)
                StatItem(title: "Tamamlanan", value: "\(summary.completedCount)", icon: "checkmark.circle.fill", color: .green)
                StatItem(title: "İptal", value: "\(summary.cancelledCount)", icon: "xmark.circle.fill", color: .red)
            }
            
            Divider()
            
            // Revenue
            HStack {
                VStack(alignment: .leading) {
                    Text("Tahmini Ciro")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f ₺", summary.totalRevenue))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryGreen)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Ort. Sipariş")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f ₺", summary.averageOrderValue))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            // Top Products
            if !summary.topProducts.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("En Çok Satan")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(summary.topProducts.prefix(3)) { product in
                        HStack {
                            Text(product.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(product.quantity) adet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Product Suggestion Card
struct ProductSuggestionCard: View {
    let suggestion: ProductSuggestion
    let onAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: suggestion.type.icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.productName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(suggestion.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onAction) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.primaryGreen)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Quick Reorder Card
struct QuickReorderCard: View {
    let reorder: QuickReorder
    let onReorder: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Vendor logo placeholder
                Circle()
                    .fill(Color.primaryGreen.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(reorder.vendorName.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryGreen)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(reorder.vendorName)
                        .font(.headline)
                    
                    Text(timeAgo(from: reorder.lastOrderDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(String(format: "%.2f ₺", reorder.totalAmount))
                        .font(.headline)
                        .foregroundColor(.primaryGreen)
                    
                    Text("\(reorder.items.count) ürün")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Items preview
            Text(reorder.items.map { $0.name }.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Button(action: onReorder) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Tekrar Sipariş Ver")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.primaryGreen)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Favorite Toggle Button
struct FavoriteToggleButton: View {
    let type: FavoriteType
    let entityId: String
    let entityName: String
    let entityImage: String?
    
    @ObservedObject var favoritesManager = FavoritesManager.shared
    
    private var isFavorite: Bool {
        favoritesManager.isFavorite(type: type, entityId: entityId)
    }
    
    var body: some View {
        Button(action: {
            favoritesManager.toggleFavorite(
                type: type,
                entityId: entityId,
                entityName: entityName,
                entityImage: entityImage
            )
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(isFavorite ? .red : .gray)
                .font(.title2)
        }
    }
}

// MARK: - Personalized Section View (Bugün Sana Özel)
struct PersonalizedSectionView: View {
    let section: PersonalizedSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎯 Bugün Sana Özel")
                .font(.title3)
                .fontWeight(.bold)
            
            // Nearby vendors
            if !section.nearbyVendors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Yakınındaki", systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(section.nearbyVendors) { vendor in
                                MiniVendorCard(vendor: vendor)
                            }
                        }
                    }
                }
            }
            
            // Campaign vendors
            if !section.campaignVendors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Kampanyalı", systemImage: "tag.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(section.campaignVendors) { vendor in
                                MiniVendorCard(vendor: vendor)
                            }
                        }
                    }
                }
            }
            
            // Previous vendors
            if !section.previousVendors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Daha Önce Aldığın", systemImage: "clock.arrow.circlepath")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(section.previousVendors) { vendor in
                                MiniVendorCard(vendor: vendor)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MiniVendorCard: View {
    let vendor: Vendor
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.primaryGreen.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(vendor.name.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryGreen)
                )
            
            Text(vendor.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", vendor.rating))
                    .font(.caption2)
            }
        }
        .frame(width: 80)
    }
}

// Note: Color(hex:) extension is defined in Colors.swift

// MARK: - Previews
#Preview("Availability Button") {
    AvailabilityStatusButton()
        .padding()
}

#Preview("Daily Goal") {
    DailyGoalProgressView(currentJobs: 3, dailyGoal: 5)
        .padding()
}
