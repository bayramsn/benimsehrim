import SwiftUI
import AppClip

@main
struct BenimSehrimClipApp: App {
    @StateObject private var clipViewModel = ClipViewModel()
    
    var body: some Scene {
        WindowGroup {
            ClipContentView()
                .environmentObject(clipViewModel)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    clipViewModel.handleInvocation(activity: activity)
                }
        }
    }
}

struct ClipContentView: View {
    @EnvironmentObject var viewModel: ClipViewModel
    
    var body: some View {
        NavigationStack {
            switch viewModel.state {
            case .loading:
                LoadingView()
                
            case .store(let store):
                StoreClipView(store: store)
                
            case .order(let orderId):
                OrderTrackingClipView(orderId: orderId)
                
            case .taxi:
                TaxiClipView()
                
            case .error(let message):
                ErrorView(message: message)
                
            case .welcomePrompt:
                WelcomePromptView()
            }
        }
    }
}

// MARK: - Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Yükleniyor...")
                .foregroundColor(.secondary)
        }
    }
}

struct StoreClipView: View {
    let store: ClipStore
    @State private var cartItems: [CartItem] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Store Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", store.rating))
                        Text("•")
                        Text(store.category)
                            .foregroundColor(.secondary)
                    }
                    
                    if store.isOpen {
                        Label("Açık", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Kapalı", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                
                // Products
                Text("Ürünler")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 12) {
                    ForEach(store.products) { product in
                        ProductRowView(product: product) {
                            addToCart(product)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .overlay(alignment: .bottom) {
            if !cartItems.isEmpty {
                CartSummaryView(items: cartItems, store: store)
            }
        }
        .navigationTitle(store.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addToCart(_ product: ClipProduct) {
        if let index = cartItems.firstIndex(where: { $0.productId == product.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(productId: product.id, name: product.name, price: product.price, quantity: 1))
        }
    }
}

struct ProductRowView: View {
    let product: ClipProduct
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .fontWeight(.medium)
                Text("\(Int(product.price))₺")
                    .foregroundColor(.green)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CartSummaryView: View {
    let items: [CartItem]
    let store: ClipStore
    
    var total: Double {
        items.reduce(0) { $0 + $1.price * Double($1.quantity) }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(items.count) ürün")
                        .foregroundColor(.secondary)
                    Text("\(Int(total))₺")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Button(action: checkout) {
                    Text("Sipariş Ver")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            
            // Full app prompt
            HStack {
                Text("Daha fazlası için uygulamayı indirin!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Link("İndir", destination: URL(string: "https://apps.apple.com/app/benimsehrim/id123456789")!)
                    .font(.caption.bold())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func checkout() {
        // Handle checkout in App Clip
    }
}

struct TaxiClipView: View {
    @State private var pickupAddress = ""
    @State private var dropAddress = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🚕")
                .font(.system(size: 60))
            
            Text("Taksi Çağır")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                TextField("Neredesiniz?", text: $pickupAddress)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                TextField("Nereye gideceksiniz?", text: $dropAddress)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }
            
            Button(action: requestTaxi) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "car.fill")
                        Text("Taksi Çağır")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .fontWeight(.bold)
                .cornerRadius(12)
            }
            .disabled(pickupAddress.isEmpty || dropAddress.isEmpty)
            .padding(.horizontal)
            
            Spacer()
            
            Text("Tam deneyim için uygulamayı indirin")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    private func requestTaxi() {
        isLoading = true
        // Handle taxi request
    }
}

struct OrderTrackingClipView: View {
    let orderId: String
    @State private var order: ClipOrder?
    
    var body: some View {
        VStack(spacing: 20) {
            if let order = order {
                VStack(spacing: 16) {
                    Text(order.storeName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Status
                    StatusBadge(status: order.status)
                    
                    // Progress
                    OrderProgressView(status: order.status)
                    
                    Divider()
                    
                    // Items
                    ForEach(order.items, id: \.name) { item in
                        HStack {
                            Text("\(item.quantity)x \(item.name)")
                            Spacer()
                            Text("\(Int(item.price))₺")
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Toplam")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(Int(order.total))₺")
                            .fontWeight(.bold)
                    }
                }
                .padding()
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Sipariş #\(orderId.prefix(8))")
        .task {
            await loadOrder()
        }
    }
    
    private func loadOrder() async {
        // Load order from API
        order = ClipOrder(
            id: orderId,
            storeName: "Demo Mağaza",
            status: "PREPARING",
            items: [ClipOrderItem(name: "Ürün 1", quantity: 2, price: 50)],
            total: 100
        )
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        let (color, text, icon) = statusInfo
        
        Label(text, systemImage: icon)
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(20)
    }
    
    var statusInfo: (Color, String, String) {
        switch status {
        case "PENDING": return (.orange, "Bekliyor", "clock")
        case "ACCEPTED": return (.blue, "Onaylandı", "checkmark")
        case "PREPARING": return (.purple, "Hazırlanıyor", "flame")
        case "READY": return (.teal, "Hazır", "bag")
        case "ON_WAY": return (.indigo, "Yolda", "car")
        case "DELIVERED": return (.green, "Teslim Edildi", "checkmark.circle")
        default: return (.gray, status, "questionmark")
        }
    }
}

struct OrderProgressView: View {
    let status: String
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(["PENDING", "ACCEPTED", "PREPARING", "READY", "ON_WAY", "DELIVERED"], id: \.self) { step in
                Circle()
                    .fill(isCompleted(step) ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                if step != "DELIVERED" {
                    Rectangle()
                        .fill(isCompleted(step) ? Color.green : Color.gray.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
        .padding(.vertical)
    }
    
    private func isCompleted(_ step: String) -> Bool {
        let steps = ["PENDING", "ACCEPTED", "PREPARING", "READY", "ON_WAY", "DELIVERED"]
        guard let currentIndex = steps.firstIndex(of: status),
              let stepIndex = steps.firstIndex(of: step) else { return false }
        return stepIndex <= currentIndex
    }
}

struct WelcomePromptView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("🏙️")
                .font(.system(size: 80))
            
            Text("Benim Şehrim")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Şehrin Cebinde")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "bag", text: "Yerel mağazalardan alışveriş")
                FeatureRow(icon: "car", text: "Taksi çağırma")
                FeatureRow(icon: "shippingbox", text: "Kurye hizmeti")
            }
            .padding(.vertical)
            
            Link(destination: URL(string: "https://apps.apple.com/app/benimsehrim/id123456789")!) {
                Text("Uygulamayı İndir")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
        }
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - ViewModel

class ClipViewModel: ObservableObject {
    @Published var state: ClipState = .loading
    
    enum ClipState {
        case loading
        case store(ClipStore)
        case order(String)
        case taxi
        case error(String)
        case welcomePrompt
    }
    
    func handleInvocation(activity: NSUserActivity) {
        guard let url = activity.webpageURL else {
            state = .welcomePrompt
            return
        }
        
        let path = url.pathComponents
        
        if path.contains("stores"), let storeId = path.last {
            loadStore(id: storeId)
        } else if path.contains("orders"), let orderId = path.last {
            state = .order(orderId)
        } else if path.contains("taxi") {
            state = .taxi
        } else {
            state = .welcomePrompt
        }
    }
    
    private func loadStore(id: String) {
        // Load store from API
        Task {
            // Demo data
            let store = ClipStore(
                id: id,
                name: "Demo Mağaza",
                rating: 4.5,
                category: "Market",
                isOpen: true,
                products: [
                    ClipProduct(id: "1", name: "Ürün 1", price: 25),
                    ClipProduct(id: "2", name: "Ürün 2", price: 35),
                    ClipProduct(id: "3", name: "Ürün 3", price: 45),
                ]
            )
            
            await MainActor.run {
                self.state = .store(store)
            }
        }
    }
}

// MARK: - Models

struct ClipStore: Identifiable {
    let id: String
    let name: String
    let rating: Double
    let category: String
    let isOpen: Bool
    let products: [ClipProduct]
}

struct ClipProduct: Identifiable {
    let id: String
    let name: String
    let price: Double
}

struct CartItem: Identifiable {
    let id = UUID()
    let productId: String
    let name: String
    let price: Double
    var quantity: Int
}

struct ClipOrder {
    let id: String
    let storeName: String
    let status: String
    let items: [ClipOrderItem]
    let total: Double
}

struct ClipOrderItem {
    let name: String
    let quantity: Int
    let price: Double
}
