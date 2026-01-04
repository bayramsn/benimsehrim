import SwiftUI

struct StoresView: View {
    var categoryId: String? = nil
    
    @StateObject private var viewModel = StoresViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.stores.isEmpty {
                VStack(spacing: 16) {
                    Text("🏪")
                        .font(.system(size: 60))
                    Text("Henüz mağaza bulunamadı")
                        .font(.titleMedium)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.stores) { store in
                            NavigationLink(destination: StoreDetailView(storeId: store.id)) {
                                StoreCardView(store: store)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Mağazalar")
        .task {
            await viewModel.loadStores(categoryId: categoryId)
        }
    }
}

class StoresViewModel: ObservableObject {
    @Published var stores: [Store] = []
    @Published var isLoading = true
    
    @MainActor
    func loadStores(categoryId: String?) async {
        // Test mode - use mock Kırşehir stores
        #if DEBUG
        let isTestMode = true
        #else
        let isTestMode = false
        #endif
        
        if isTestMode {
            // Kırşehir'deki gerçek market ve mağazalar
            stores = [
                // Süpermarketler
                Store(
                    id: "1",
                    name: "Yunus Marketler Zinciri",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.0,
                    reviewCount: 849,
                    isOpen: true,
                    distance: 0.5,
                    deliveryTime: "20-30 dk",
                    minOrder: 50,
                    deliveryFee: 9.99,
                    categories: [Category(id: "market", name: "Market", icon: "cart.fill", color: "#4CAF50")],
                    isFavorite: false
                ),
                Store(
                    id: "2",
                    name: "MM Migros",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.0,
                    reviewCount: 1114,
                    isOpen: true,
                    distance: 0.8,
                    deliveryTime: "25-35 dk",
                    minOrder: 75,
                    deliveryFee: 12.99,
                    categories: [Category(id: "market", name: "Market", icon: "cart.fill", color: "#FF6F00")],
                    isFavorite: true
                ),
                Store(
                    id: "3",
                    name: "BİM",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.2,
                    reviewCount: 567,
                    isOpen: true,
                    distance: 0.3,
                    deliveryTime: "15-25 dk",
                    minOrder: 30,
                    deliveryFee: 7.99,
                    categories: [Category(id: "market", name: "Market", icon: "cart.fill", color: "#E31E24")],
                    isFavorite: false
                ),
                Store(
                    id: "4",
                    name: "A101",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.1,
                    reviewCount: 723,
                    isOpen: true,
                    distance: 0.4,
                    deliveryTime: "15-25 dk",
                    minOrder: 30,
                    deliveryFee: 7.99,
                    categories: [Category(id: "market", name: "Market", icon: "cart.fill", color: "#00529B")],
                    isFavorite: false
                ),
                Store(
                    id: "5",
                    name: "ŞOK Market",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.0,
                    reviewCount: 445,
                    isOpen: true,
                    distance: 0.6,
                    deliveryTime: "20-30 dk",
                    minOrder: 35,
                    deliveryFee: 8.99,
                    categories: [Category(id: "market", name: "Market", icon: "cart.fill", color: "#FFCC00")],
                    isFavorite: false
                ),
                Store(
                    id: "6",
                    name: "Çaykara Gross Market",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.1,
                    reviewCount: 200,
                    isOpen: true,
                    distance: 1.2,
                    deliveryTime: "30-45 dk",
                    minOrder: 100,
                    deliveryFee: 14.99,
                    categories: [Category(id: "market", name: "Toptan Market", icon: "shippingbox.fill", color: "#795548")],
                    isFavorite: false
                ),
                Store(
                    id: "7",
                    name: "Altıparmak Gross Market",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.3,
                    reviewCount: 312,
                    isOpen: true,
                    distance: 0.9,
                    deliveryTime: "25-40 dk",
                    minOrder: 80,
                    deliveryFee: 12.99,
                    categories: [Category(id: "market", name: "Toptan Market", icon: "shippingbox.fill", color: "#607D8B")],
                    isFavorite: false
                ),
                Store(
                    id: "8",
                    name: "Halk Gross Market",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.2,
                    reviewCount: 189,
                    isOpen: true,
                    distance: 1.5,
                    deliveryTime: "30-45 dk",
                    minOrder: 100,
                    deliveryFee: 14.99,
                    categories: [Category(id: "market", name: "Toptan Market", icon: "shippingbox.fill", color: "#3F51B5")],
                    isFavorite: false
                ),
                Store(
                    id: "9",
                    name: "Beğendik Market",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.0,
                    reviewCount: 156,
                    isOpen: true,
                    distance: 1.0,
                    deliveryTime: "25-35 dk",
                    minOrder: 60,
                    deliveryFee: 10.99,
                    categories: [Category(id: "market", name: "Market", icon: "cart.fill", color: "#9C27B0")],
                    isFavorite: false
                ),
                Store(
                    id: "10",
                    name: "Turka Center",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.4,
                    reviewCount: 234,
                    isOpen: true,
                    distance: 0.7,
                    deliveryTime: "20-30 dk",
                    minOrder: 50,
                    deliveryFee: 9.99,
                    categories: [Category(id: "market", name: "Market", icon: "cart.fill", color: "#009688")],
                    isFavorite: true
                ),
                // Restoranlar ve Yemek
                Store(
                    id: "11",
                    name: "Kırşehir Kebapçısı",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.5,
                    reviewCount: 523,
                    isOpen: true,
                    distance: 0.8,
                    deliveryTime: "25-40 dk",
                    minOrder: 80,
                    deliveryFee: 15.99,
                    categories: [Category(id: "restaurant", name: "Restoran", icon: "fork.knife", color: "#F44336")],
                    isFavorite: true
                ),
                Store(
                    id: "12",
                    name: "Çullama Evi",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.6,
                    reviewCount: 312,
                    isOpen: true,
                    distance: 1.1,
                    deliveryTime: "30-45 dk",
                    minOrder: 100,
                    deliveryFee: 19.99,
                    categories: [Category(id: "restaurant", name: "Yöresel Yemek", icon: "fork.knife", color: "#FF5722")],
                    isFavorite: false
                ),
                Store(
                    id: "13",
                    name: "Burger King",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.1,
                    reviewCount: 678,
                    isOpen: true,
                    distance: 0.5,
                    deliveryTime: "20-30 dk",
                    minOrder: 60,
                    deliveryFee: 12.99,
                    categories: [Category(id: "fastfood", name: "Fast Food", icon: "flame.fill", color: "#D32F2F")],
                    isFavorite: false
                ),
                Store(
                    id: "14",
                    name: "Domino's Pizza",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.2,
                    reviewCount: 445,
                    isOpen: true,
                    distance: 0.6,
                    deliveryTime: "25-35 dk",
                    minOrder: 70,
                    deliveryFee: 9.99,
                    categories: [Category(id: "pizza", name: "Pizza", icon: "circle.grid.2x2.fill", color: "#1565C0")],
                    isFavorite: false
                ),
                // Fırın ve Pastane
                Store(
                    id: "15",
                    name: "Kırşehir Halk Ekmek",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.3,
                    reviewCount: 289,
                    isOpen: true,
                    distance: 0.4,
                    deliveryTime: "15-25 dk",
                    minOrder: 20,
                    deliveryFee: 5.99,
                    categories: [Category(id: "bakery", name: "Fırın", icon: "birthday.cake.fill", color: "#8D6E63")],
                    isFavorite: false
                ),
                Store(
                    id: "16",
                    name: "Simit Sarayı",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.0,
                    reviewCount: 367,
                    isOpen: true,
                    distance: 0.5,
                    deliveryTime: "15-25 dk",
                    minOrder: 30,
                    deliveryFee: 7.99,
                    categories: [Category(id: "bakery", name: "Fırın", icon: "birthday.cake.fill", color: "#FFA000")],
                    isFavorite: false
                ),
                // Kasap ve Et Ürünleri
                Store(
                    id: "17",
                    name: "Kırşehir Et Pazarı",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.4,
                    reviewCount: 198,
                    isOpen: true,
                    distance: 0.9,
                    deliveryTime: "30-45 dk",
                    minOrder: 150,
                    deliveryFee: 19.99,
                    categories: [Category(id: "butcher", name: "Kasap", icon: "hare.fill", color: "#B71C1C")],
                    isFavorite: false
                ),
                // Elektronik
                Store(
                    id: "18",
                    name: "Teknosa",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.0,
                    reviewCount: 234,
                    isOpen: true,
                    distance: 1.3,
                    deliveryTime: "45-60 dk",
                    minOrder: 200,
                    deliveryFee: 29.99,
                    categories: [Category(id: "electronics", name: "Elektronik", icon: "desktopcomputer", color: "#37474F")],
                    isFavorite: false
                ),
                // Eczane
                Store(
                    id: "19",
                    name: "Merkez Eczanesi",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.7,
                    reviewCount: 156,
                    isOpen: true,
                    distance: 0.3,
                    deliveryTime: "15-25 dk",
                    minOrder: 0,
                    deliveryFee: 9.99,
                    categories: [Category(id: "pharmacy", name: "Eczane", icon: "cross.fill", color: "#4CAF50")],
                    isFavorite: false
                ),
                // Çiçekçi
                Store(
                    id: "20",
                    name: "Kırşehir Çiçekçilik",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.5,
                    reviewCount: 89,
                    isOpen: true,
                    distance: 0.7,
                    deliveryTime: "30-45 dk",
                    minOrder: 100,
                    deliveryFee: 14.99,
                    categories: [Category(id: "florist", name: "Çiçekçi", icon: "leaf.fill", color: "#E91E63")],
                    isFavorite: false
                ),
                // Kırtasiye
                Store(
                    id: "21",
                    name: "Kırşehir Kırtasiye",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.2,
                    reviewCount: 123,
                    isOpen: true,
                    distance: 0.5,
                    deliveryTime: "20-30 dk",
                    minOrder: 30,
                    deliveryFee: 7.99,
                    categories: [Category(id: "stationery", name: "Kırtasiye", icon: "pencil.and.ruler.fill", color: "#673AB7")],
                    isFavorite: false
                ),
                // Pet Shop
                Store(
                    id: "22",
                    name: "Pati Dostları Pet Shop",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.6,
                    reviewCount: 78,
                    isOpen: true,
                    distance: 1.0,
                    deliveryTime: "30-45 dk",
                    minOrder: 50,
                    deliveryFee: 12.99,
                    categories: [Category(id: "petshop", name: "Pet Shop", icon: "pawprint.fill", color: "#FF9800")],
                    isFavorite: false
                ),
                // Su Teslimatı
                Store(
                    id: "23",
                    name: "Erikli Su Bayii",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.3,
                    reviewCount: 234,
                    isOpen: true,
                    distance: 1.5,
                    deliveryTime: "45-60 dk",
                    minOrder: 0,
                    deliveryFee: 0,
                    categories: [Category(id: "water", name: "Su", icon: "drop.fill", color: "#2196F3")],
                    isFavorite: false
                ),
                Store(
                    id: "24",
                    name: "Hayat Su Bayii",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.1,
                    reviewCount: 189,
                    isOpen: true,
                    distance: 1.2,
                    deliveryTime: "40-55 dk",
                    minOrder: 0,
                    deliveryFee: 0,
                    categories: [Category(id: "water", name: "Su", icon: "drop.fill", color: "#03A9F4")],
                    isFavorite: false
                ),
                // Tatlıcı
                Store(
                    id: "25",
                    name: "Kırşehir Tatlıcısı",
                    logoUrl: nil,
                    bannerUrl: nil,
                    rating: 4.7,
                    reviewCount: 312,
                    isOpen: true,
                    distance: 0.6,
                    deliveryTime: "25-35 dk",
                    minOrder: 50,
                    deliveryFee: 9.99,
                    categories: [Category(id: "dessert", name: "Tatlı", icon: "birthday.cake.fill", color: "#E91E63")],
                    isFavorite: true
                )
            ]
            
            // Filter by category if specified
            if let categoryId = categoryId {
                stores = stores.filter { store in
                    store.categories?.contains { $0.id == categoryId } ?? false
                }
            }
            
            isLoading = false
            return
        }
        
        do {
            let response = try await NetworkManager.shared.getStores(categoryId: categoryId)
            stores = response.data
        } catch {
            stores = []
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        StoresView()
    }
}
