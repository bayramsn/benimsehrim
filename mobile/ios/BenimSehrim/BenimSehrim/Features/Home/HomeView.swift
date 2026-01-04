import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBarView()
                        .padding()
                    
                    // Quick Actions
                    QuickActionsView()
                        .padding(.horizontal)
                    
                    // Categories
                    SectionHeader(title: "Kategoriler")
                    CategoriesScrollView(categories: viewModel.categories)
                    
                    // Campaigns
                    if !viewModel.campaigns.isEmpty {
                        SectionHeader(title: "🔥 Kampanyalar")
                        CampaignsScrollView(campaigns: viewModel.campaigns)
                    }
                    
                    // Popular Stores
                    SectionHeader(title: "Popüler Mağazalar", showAction: true)
                    
                    ForEach(viewModel.stores) { store in
                        NavigationLink(destination: StoreDetailView(storeId: store.id)) {
                            StoreCardView(store: store)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Benim Şehrim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CartView()) {
                        Image(systemName: "cart")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBarView: View {
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            Text("Mağaza veya ürün ara...")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(28)
    }
}

// MARK: - Quick Actions
struct QuickActionsView: View {
    @State private var showWhatToEat = false
    
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: TaxiView()) {
                QuickActionCard(
                    icon: "car.fill",
                    title: "Taksi",
                    subtitle: "Hemen çağır",
                    gradient: [.secondaryOrange, .secondaryOrangeLight]
                )
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: OrdersView()) {
                QuickActionCard(
                    icon: "bag.fill",
                    title: "Siparişler",
                    subtitle: "Takip et",
                    gradient: [.tertiaryBlue, .tertiaryBlueLight]
                )
            }
            .buttonStyle(.plain)
            
            Button(action: { showWhatToEat = true }) {
                QuickActionCard(
                    icon: "fork.knife",
                    title: "Ne Yesem?",
                    subtitle: "Öneri al",
                    gradient: [.pink, .purple]
                )
            }
            .buttonStyle(.plain)
        }
        .alert("Bugün Ne Yesek? 🤔", isPresented: $showWhatToEat) {
             Button("Mağazaya Git") { }
             Button("Kapat", role: .cancel) { }
        } message: {
             Text("Senin için harika bir önerimiz var:\n🔥 Ahi Kasap - Kasap Köfte\nSadece 150₺")
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
            
            Text(title)
                .font(.titleMedium)
                .foregroundColor(.white)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.bodySmall)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: gradient), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var showAction: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.titleMedium)
                .fontWeight(.bold)
            
            Spacer()
            
            if showAction {
                Button("Tümünü Gör") {
                    
                }
                .font(.bodySmall)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Categories
struct CategoriesScrollView: View {
    let categories: [Category]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories) { category in
                    NavigationLink(destination: StoresView(categoryId: category.id)) {
                        CategoryChip(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryChip: View {
    let category: Category
    
    var body: some View {
        VStack(spacing: 4) {
            Text(category.icon ?? "🛒")
                .font(.title)
            
            Text(category.name)
                .font(.labelMedium)
        }
        .padding()
        .background(Color.primaryGreen.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Campaigns
struct CampaignsScrollView: View {
    let campaigns: [Campaign]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(campaigns) { campaign in
                    HomeCampaignCard(campaign: campaign)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct HomeCampaignCard: View {
    let campaign: Campaign
    
    var discountText: String {
        switch campaign.type {
        case "PERCENTAGE":
            return "%\(Int(campaign.value)) İndirim"
        case "FIXED_AMOUNT":
            return "\(Int(campaign.value))₺ İndirim"
        default:
            return "Kampanya"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(campaign.store?.name ?? "")
                    .font(.labelMedium)
                
                Text(discountText)
                    .font(.titleMedium)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Text("🔥")
                .font(.title)
                .padding(8)
                .background(Color.red)
                .clipShape(Circle())
        }
        .padding()
        .frame(width: 280)
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Store Card
struct StoreCardView: View {
    let store: Store
    
    var body: some View {
        HStack(spacing: 12) {
            // Store Image
            AsyncImage(url: URL(string: store.logoUrl ?? "")) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 80, height: 80)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(store.name)
                        .font(.titleMedium)
                        .fontWeight(.semibold)
                    
                    Text(store.isOpen ? "Açık" : "Kapalı")
                        .font(.labelSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(store.isOpen ? Color.statusOpen : Color.statusClosed)
                        .cornerRadius(4)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.secondaryOrange)
                        .font(.caption)
                    
                    Text("\(store.rating, specifier: "%.1f") (\(store.reviewCount))")
                        .font(.bodySmall)
                }
                
                Text("Min. \(Int(store.minOrder))₺ • \(store.deliveryFee > 0 ? "\(Int(store.deliveryFee))₺" : "Ücretsiz") Teslimat")
                    .font(.bodySmall)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // Toggle favorite logic
            }) {
                Image(systemName: store.isFavorite == true ? "heart.fill" : "heart")
                    .foregroundColor(store.isFavorite == true ? .red : .gray)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Home ViewModel
class HomeViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var campaigns: [Campaign] = []
    @Published var stores: [Store] = []
    @Published var isLoading = true
    
    @MainActor
    func loadData() async {
        // Load categories
        do {
            categories = try await NetworkManager.shared.getCategories()
        } catch {
            categories = defaultCategories
        }
        
        // Load stores
        do {
            let response = try await NetworkManager.shared.getStores()
            stores = response.data
        } catch {
            stores = []
        }
        
        isLoading = false
    }
    
    @MainActor
    func refresh() async {
        await loadData()
    }
    
    private var defaultCategories: [Category] {
        [
            Category(id: "1", name: "Kasap", icon: "🥩", sortOrder: 1),
            Category(id: "2", name: "Fırın", icon: "🍞", sortOrder: 2),
            Category(id: "3", name: "Market", icon: "🛒", sortOrder: 3),
            Category(id: "4", name: "Manav", icon: "🥬", sortOrder: 4),
            Category(id: "5", name: "Restoran", icon: "🍽️", sortOrder: 5),
            Category(id: "6", name: "Cafe", icon: "☕", sortOrder: 6)
        ]
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager.shared)
}
