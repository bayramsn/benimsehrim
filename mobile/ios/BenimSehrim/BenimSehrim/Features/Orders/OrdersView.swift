import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.orders.isEmpty {
                VStack(spacing: 16) {
                    Text("📦")
                        .font(.system(size: 60))
                    Text("Henüz sipariş yok")
                        .font(.titleMedium)
                    Text("Mağazalardan sipariş verdikten sonra burada görünecek")
                        .font(.bodyMedium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.orders) { order in
                            NavigationLink(destination: OrderDetailView(orderId: order.id)) {
                                OrderCardView(order: order)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Siparişlerim")
        .task {
            await viewModel.loadOrders()
        }
    }
}

struct OrderCardView: View {
    let order: Order
    
    var statusColor: Color {
        switch order.status {
        case "PENDING": return .deliveryPending
        case "ACCEPTED", "PREPARING": return .deliveryPreparing
        case "ON_WAY": return .deliveryOnWay
        case "DELIVERED": return .deliveryDelivered
        case "CANCELLED": return .deliveryCancelled
        default: return .deliveryPending
        }
    }
    
    var statusText: String {
        switch order.status {
        case "PENDING": return "Bekliyor"
        case "ACCEPTED": return "Onaylandı"
        case "PREPARING": return "Hazırlanıyor"
        case "ON_WAY": return "Yolda"
        case "DELIVERED": return "Teslim Edildi"
        case "CANCELLED": return "İptal"
        default: return order.status
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(order.store.name)
                    .font(.titleMedium)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(statusText)
                    .font(.labelMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(8)
            }
            
            HStack {
                Text("Sipariş No: \(order.orderNo)")
                    .font(.bodySmall)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(order.total))₺")
                    .font(.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGreen)
            }
            
            Text(String(order.createdAt.prefix(10)))
                .font(.bodySmall)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct OrderDetailView: View {
    let orderId: String
    @State private var showChat = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📦")
                .font(.system(size: 60))
            Text("Sipariş: \(orderId)")
            Text("Sipariş detayları yükleniyor...")
                .foregroundColor(.secondary)
            
            Button(action: { showChat = true }) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("Kurye ile Konuş")
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .sheet(isPresented: $showChat) {
                ChatView(chatId: "mock_chat_id")
            }
        }
        .navigationTitle("Sipariş Detayı")
    }
}

class OrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = true
    
    @MainActor
    func loadOrders() async {
        do {
            orders = try await NetworkManager.shared.getOrders()
        } catch {
            orders = []
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        OrdersView()
    }
}
