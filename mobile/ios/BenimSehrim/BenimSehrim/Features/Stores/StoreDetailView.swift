import SwiftUI

struct StoreDetailView: View {
    let storeId: String
    
    @StateObject private var viewModel = StoreDetailViewModel()
    @ObservedObject var cartManager = CartManager.shared
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.primaryGreen)
            } else if let store = viewModel.store {
                ScrollView {
                    VStack(spacing: 0) {
                        // Banner
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(url: URL(string: store.bannerUrl ?? "")) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.primaryGreen.opacity(0.3)
                            }
                            .frame(height: 180)
                            .clipped()
                            
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.name)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.secondaryOrange)
                                    Text("\(store.rating, specifier: "%.1f") (\(store.reviewCount) değerlendirme)")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            .padding()
                            
                            // Status badge
                            VStack {
                                HStack {
                                    Spacer()
                                    Text(store.isOpen ? "Açık" : "Kapalı")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(store.isOpen ? Color.statusOpen : Color.statusClosed)
                                        .clipShape(Capsule())
                                }
                                Spacer()
                            }
                            .padding()
                        }
                        
                        // Info Row
                        HStack {
                            InfoChip(icon: "clock", text: "\(store.openTime) - \(store.closeTime)")
                            Spacer()
                            InfoChip(icon: "shippingbox", text: store.deliveryFee > 0 ? "\(Int(store.deliveryFee))₺" : "Ücretsiz")
                            Spacer()
                            InfoChip(icon: "bag", text: "Min. \(Int(store.minOrder))₺")
                        }
                        .padding()
                        
                        Divider()
                        
                        // Products
                        LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                            Section {
                                ForEach(store.products) { product in
                                    ProductCardView(
                                        product: product,
                                        cartQuantity: cartManager.items[product] ?? 0,
                                        onAdd: { cartManager.addToCart(product) },
                                        onRemove: { cartManager.removeFromCart(product) }
                                    )
                                    Divider()
                                }
                            } header: {
                                Text("Ürünler")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(.ultraThinMaterial)
                            }
                        }
                    }
                }
            } else {
                 VStack {
                     Text("Mağaza bulunamadı")
                         .foregroundColor(.secondary)
                     Button("Tekrar Dene") {
                         Task { await viewModel.loadStore(id: storeId) }
                     }
                 }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if cartManager.itemCount > 0 {
                NavigationLink(destination: CartView()) {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("Sepete Git (\(Int(cartManager.total))₺)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
        }
        .task {
            await viewModel.loadStore(id: storeId)
        }
    }
}

struct InfoChip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.primaryGreen)
            Text(text)
                .font(.caption)
        }
    }
}

struct ProductCardView: View {
    let product: Product
    let cartQuantity: Int
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product.images.first ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 80, height: 80)
            .cornerRadius(12)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let description = product.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 0)
                
                Text("\(Int(product.price))₺")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGreen)
            }
            
            Spacer()
            
            if cartQuantity == 0 {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .padding(8)
                        .background(Color.primaryGreen.opacity(0.1))
                        .foregroundColor(.primaryGreen)
                        .clipShape(Circle())
                }
            } else {
                HStack(spacing: 12) {
                    Button(action: onRemove) {
                        Image(systemName: "minus")
                            .font(.caption)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .clipShape(Circle())
                    }
                    
                    Text("\(cartQuantity)")
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(minWidth: 20)
                    
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .padding(8)
                            .background(Color.primaryGreen.opacity(0.1))
                            .foregroundColor(.primaryGreen)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

class StoreDetailViewModel: ObservableObject {
    @Published var store: StoreDetail?
    @Published var isLoading = true
    
    @MainActor
    func loadStore(id: String) async {
        isLoading = true
        do {
            // Attempt to fetch from Backend
            // Uncomment line below if NetworkManager implements getStore
            // let fetchedStore = try await NetworkManager.shared.getStore(id: id)
            // self.store = fetchedStore
            
            // Simulating network failure to show functionality
            throw ApiError(statusCode: 500, message: "Mock Fallback", error: nil)
            
        } catch {
            // Fallback to Mock Data
            let mockProducts = [
                Product(id: "1", name: "Dana Kıyma", description: "%100 Dana eti, yerli üretim.", price: 350, stock: 50, unit: "kg", images: [], isActive: true, campaigns: nil),
                Product(id: "2", name: "Kuzu Pirzola", description: "Taze kuzu pirzola.", price: 450, stock: 30, unit: "kg", images: [], isActive: true, campaigns: nil),
                Product(id: "3", name: "Kasap Köfte", description: "Özel baharatlı kasap köfte.", price: 300, stock: 100, unit: "kg", images: [], isActive: true, campaigns: nil)

            ]
            
            self.store = StoreDetail(id: id, name: "Ahi Kasap", description: "En taze et ve et ürünleri.", logoUrl: nil, bannerUrl: nil, address: "Terme Cad. No:5, Kırşehir", phone: "0386 213 00 00", rating: 4.8, reviewCount: 120, isOpen: true, openTime: "09:00", closeTime: "22:00", paymentTypes: ["Cash", "Credit Card"], minOrder: 100, deliveryFee: 0, products: mockProducts, campaigns: [])
        }
        self.isLoading = false
    }
}
